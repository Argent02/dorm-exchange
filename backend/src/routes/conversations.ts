import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { sendError } from "../lib/http.js";

const router = Router();
router.use(requireAuth, requireUser);

const createConversationSchema = z.object({
  listingId: z.string().uuid().optional(),
  ownerId: z.string().uuid(), // the listing owner (person being messaged)
});

const sendMessageSchema = z.object({
  content: z.string().min(1).max(5000),
});
const idParamSchema = z.object({ id: z.string().uuid() });

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
    sendError(res, 500, "Failed to load conversations", "internal_error");
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
      sendError(res, 400, parsed.error.message, "validation_failed");
      return;
    }

    const { listingId, ownerId } = parsed.data;
    const initiatorId = req.user!.id;

    if (ownerId === initiatorId) {
      sendError(res, 400, "Cannot message yourself", "bad_request");
      return;
    }

    if (listingId) {
      const listing = await prisma.listing.findUnique({
        where: { id: listingId },
        select: { id: true, createdBy: true, status: true },
      });
      if (!listing || listing.status === "deleted") {
        sendError(res, 404, "Listing not found", "not_found");
        return;
      }
      if (listing.createdBy !== ownerId) {
        sendError(
          res,
          400,
          "ownerId does not match the listing seller",
          "listing_owner_mismatch"
        );
        return;
      }
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
    sendError(res, 500, "Failed to start conversation", "internal_error");
  }
});

/**
 * GET /conversations/:id
 * Get a conversation by ID (must be participant).
 */
router.get("/:id", async (req, res) => {
  try {
    const parsedParams = idParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid conversation id", "bad_request");
      return;
    }
    const { id } = parsedParams.data;
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
      sendError(res, 404, "Conversation not found", "not_found");
      return;
    }

    res.json({ conversation });
  } catch (error) {
    console.error("Get conversation error:", error);
    sendError(res, 500, "Failed to load conversation", "internal_error");
  }
});

/**
 * GET /conversations/:id/messages
 * Get messages in a conversation.
 */
router.get("/:id/messages", async (req, res) => {
  try {
    const parsedParams = idParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid conversation id", "bad_request");
      return;
    }
    const { id } = parsedParams.data;
    const userId = req.user!.id;

    const conversation = await prisma.conversation.findFirst({
      where: {
        id,
        OR: [{ initiatorId: userId }, { ownerId: userId }],
      },
    });

    if (!conversation) {
      sendError(res, 404, "Conversation not found", "not_found");
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
    sendError(res, 500, "Failed to load messages", "internal_error");
  }
});

/**
 * POST /conversations/:id/messages
 * Send a message in a conversation.
 */
router.post("/:id/messages", async (req, res) => {
  try {
    const parsedParams = idParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid conversation id", "bad_request");
      return;
    }
    const { id } = parsedParams.data;
    const userId = req.user!.id;

    const parsed = sendMessageSchema.safeParse(req.body);
    if (!parsed.success) {
      sendError(res, 400, parsed.error.message, "validation_failed");
      return;
    }

    const conversation = await prisma.conversation.findFirst({
      where: {
        id,
        OR: [{ initiatorId: userId }, { ownerId: userId }],
      },
    });

    if (!conversation) {
      sendError(res, 404, "Conversation not found", "not_found");
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
    sendError(res, 500, "Failed to send message", "internal_error");
  }
});

export default router;
