import { Router } from "express";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth, requireUser);

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
    res.status(500).json({ error: "Failed to load notifications" });
  }
});

/**
 * PATCH /notifications/:id/read
 * Mark a notification as read.
 */
router.patch("/:id/read", async (req, res) => {
  try {
    const notif = await prisma.notification.updateMany({
      where: { id: req.params.id, userId: req.user!.id },
      data: { isRead: true },
    });

    if (notif.count === 0) {
      res.status(404).json({ error: "Notification not found" });
      return;
    }

    res.json({ read: true });
  } catch (error) {
    console.error("Mark read error:", error);
    res.status(500).json({ error: "Failed to update notification" });
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
    res.status(500).json({ error: "Failed to update notifications" });
  }
});

export default router;
