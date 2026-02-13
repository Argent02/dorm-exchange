import { Router } from "express";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";

const router = Router();

// All user routes require authentication
router.use(requireAuth, requireUser);

/**
 * GET /users/me
 * Returns the current user's profile with their listings.
 */
router.get("/me", async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      include: {
        listings: {
          where: { status: { not: "deleted" } },
          orderBy: { createdAt: "desc" },
        },
        _count: {
          select: {
            sellExchanges: { where: { status: "completed" } },
            buyExchanges: { where: { status: "completed" } },
            locationReviews: true,
          },
        },
      },
    });

    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    res.json({ user });
  } catch (error) {
    console.error("Get current user error:", error);
    res.status(500).json({ error: "Failed to fetch user profile" });
  }
});

/**
 * GET /users/:id
 * Returns a public profile for any user by ID.
 */
router.get("/:id", async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id },
      select: {
        id: true,
        name: true,
        email: true,
        joinDate: true,
        isVerified: true,
        listings: {
          where: { status: "active" },
          orderBy: { createdAt: "desc" },
        },
        _count: {
          select: {
            sellExchanges: { where: { status: "completed" } },
            buyExchanges: { where: { status: "completed" } },
          },
        },
      },
    });

    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    res.json({ user });
  } catch (error) {
    console.error("Get user error:", error);
    res.status(500).json({ error: "Failed to fetch user" });
  }
});

export default router;
