import { Router } from "express";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";

const router = Router();

/**
 * POST /auth/login
 * Validates the Firebase token, upserts the user in the database,
 * and returns the user record. Called by the Flutter app after Firebase sign-in.
 */
router.post("/login", requireAuth, async (req, res) => {
  try {
    const user = await prisma.user.upsert({
      where: { firebaseUid: req.firebaseUid! },
      update: {
        // Update email in case it changed on Firebase side
        email: req.firebaseEmail!,
      },
      create: {
        firebaseUid: req.firebaseUid!,
        email: req.firebaseEmail!,
      },
    });

    res.json({ user });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ error: "Failed to log in" });
  }
});

/**
 * GET /auth/me
 * Returns the current authenticated user's full profile with their listings.
 */
router.get("/me", requireAuth, requireUser, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      include: {
        listings: {
          where: { status: { not: "deleted" } },
          orderBy: { createdAt: "desc" },
        },
      },
    });

    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    res.json({ user });
  } catch (error) {
    console.error("Get me error:", error);
    res.status(500).json({ error: "Failed to fetch user" });
  }
});

export default router;
