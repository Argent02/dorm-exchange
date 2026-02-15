import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth, requireUser);

const createConversationSchema = z.object({
  listingId: z.string().uuid().optional(),
  ownerId: z.string().uuid(), // the listing owner (person being messaged)
});

const sendMessageSchema = z.object({
  content: z.string().min(1).max(5000),
});

/**
 * GET /conversations
 * List conversations where the current user is initiator or owner.
 */
router.get("/", async (req, res) => {
  try {
    const userId = req.user!.id;
    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [{ initiatorId: userId }, { ownerId: userId }],
      },
      include: {
        listing: { select: { id: true, title: true, imageUrl: true, status: true } },
        initiator: { select: { id: true, name: true, email: true, firebaseUid: true } },
        owner: { select: { id: true, name: true, email: true, firebaseUid: true } },
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
      orderBy: { updatedAt: "desc" },
    });

    res.json({ conversations });
  } catch (error) {
    console.error("List conversations error:", error);
    res.status(500).json({ error: "Failed to load conversations" });
  }
});

/**
 * POST /conversations
 * Start a conversation or return existing one.
 * Body: { listingId?, ownerId }
 */
router.post("/", async (req, res) => {
  try {
    const parsed = createConversationSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: parsed.error.message });
      return;
    }

    const { listingId, ownerId } = parsed.data;
    const initiatorId = req.user!.id;

    if (ownerId === initiatorId) {
      res.status(400).json({ error: "Cannot message yourself" });
      return;
    }

    const existing = await prisma.conversation.findFirst({
      where: {
        initiatorId,
        ownerId,
        listingId: listingId ?? null,
      },
      include: {
        listing: { select: { id: true, title: true, imageUrl: true } },
        initiator: { select: { id: true, name: true, email: true, firebaseUid: true } },
        owner: { select: { id: true, name: true, email: true, firebaseUid: true } },
      },
    });

    if (existing) {
      res.json({ conversation: existing });
      return;
    }

    const conversation = await prisma.conversation.create({
      data: {
        initiatorId,
        ownerId,
        listingId: listingId ?? undefined,
      },
      include: {
        listing: { select: { id: true, title: true, imageUrl: true } },
        initiator: { select: { id: true, name: true, email: true, firebaseUid: true } },
        owner: { select: { id: true, name: true, email: true, firebaseUid: true } },
      },
    });

    res.status(201).json({ conversation });
  } catch (error) {
    console.error("Create conversation error:", error);
    res.status(500).json({ error: "Failed to start conversation" });
  }
});

/**
 * GET /conversations/:id
 * Get a conversation by ID (must be participant).
 */
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const conversation = await prisma.conversation.findFirst({
      where: {
        id,
        OR: [{ initiatorId: userId }, { ownerId: userId }],
      },
      include: {
        listing: { select: { id: true, title: true, imageUrl: true, status: true } },
        initiator: { select: { id: true, name: true, email: true, firebaseUid: true } },
        owner: { select: { id: true, name: true, email: true, firebaseUid: true } },
      },
    });

    if (!conversation) {
      res.status(404).json({ error: "Conversation not found" });
      return;
    }

    res.json({ conversation });
  } catch (error) {
    console.error("Get conversation error:", error);
    res.status(500).json({ error: "Failed to load conversation" });
  }
});

/**
 * GET /conversations/:id/messages
 * Get messages in a conversation.
 */
router.get("/:id/messages", async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const conversation = await prisma.conversation.findFirst({
      where: {
        id,
        OR: [{ initiatorId: userId }, { ownerId: userId }],
      },
    });

    if (!conversation) {
      res.status(404).json({ error: "Conversation not found" });
      return;
    }

    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      include: {
        sender: { select: { id: true, name: true, email: true } },
      },
      orderBy: { createdAt: "asc" },
    });

    res.json({ messages });
  } catch (error) {
    console.error("Get messages error:", error);
    res.status(500).json({ error: "Failed to load messages" });
  }
});

/**
 * POST /conversations/:id/messages
 * Send a message in a conversation.
 */
router.post("/:id/messages", async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const parsed = sendMessageSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: parsed.error.message });
      return;
    }

    const conversation = await prisma.conversation.findFirst({
      where: {
        id,
        OR: [{ initiatorId: userId }, { ownerId: userId }],
      },
    });

    if (!conversation) {
      res.status(404).json({ error: "Conversation not found" });
      return;
    }

    const message = await prisma.message.create({
      data: {
        conversationId: id,
        senderId: userId,
        content: parsed.data.content,
      },
      include: {
        sender: { select: { id: true, name: true, email: true } },
      },
    });

    await prisma.conversation.update({
      where: { id },
      data: { updatedAt: new Date() },
    });

    res.status(201).json({ message });
  } catch (error) {
    console.error("Send message error:", error);
    res.status(500).json({ error: "Failed to send message" });
  }
});

export default router;
