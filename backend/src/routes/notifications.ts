import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { sendError } from "../lib/http.js";

const router = Router();
router.use(requireAuth, requireUser);
const idParamSchema = z.object({ id: z.string().uuid() });

/**
 * GET /notifications
 * Returns the current user's notifications, newest first.
 */
router.get("/", async (req, res) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user!.id },
      orderBy: { createdAt: "desc" },
      take: 100,
    });

    res.json({ notifications });
  } catch (error) {
    console.error("Get notifications error:", error);
    sendError(res, 500, "Failed to load notifications", "internal_error");
  }
});

/**
 * PATCH /notifications/:id/read
 * Mark a notification as read.
 */
router.patch("/:id/read", async (req, res) => {
  try {
    const parsedParams = idParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid notification id", "bad_request");
      return;
    }
    const notif = await prisma.notification.updateMany({
      where: { id: parsedParams.data.id, userId: req.user!.id },
      data: { isRead: true },
    });

    if (notif.count === 0) {
      sendError(res, 404, "Notification not found", "not_found");
      return;
    }

    res.json({ read: true });
  } catch (error) {
    console.error("Mark read error:", error);
    sendError(res, 500, "Failed to update notification", "internal_error");
  }
});

/**
 * POST /notifications/read-all
 * Mark all notifications as read.
 */
router.post("/read-all", async (req, res) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user!.id, isRead: false },
      data: { isRead: true },
    });

    res.json({ read: true });
  } catch (error) {
    console.error("Mark all read error:", error);
    sendError(res, 500, "Failed to update notifications", "internal_error");
  }
});

export default router;
