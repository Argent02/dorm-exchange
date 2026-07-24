import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { sendError } from "../lib/http.js";

const router = Router();

// All user routes require authentication
router.use(requireAuth, requireUser);
const userIdParamSchema = z.object({ id: z.string().uuid() });

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
      sendError(res, 404, "User not found", "not_found");
      return;
    }

    res.json({ user });
  } catch (error) {
    console.error("Get current user error:", error);
    sendError(res, 500, "Failed to fetch user profile", "internal_error");
  }
});

/**
 * GET /users/:id
 * Returns a public profile for any user by ID.
 */
router.get("/:id", async (req, res) => {
  try {
    const parsedParams = userIdParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid user id", "bad_request");
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: parsedParams.data.id },
      select: {
        id: true,
        name: true,
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
      sendError(res, 404, "User not found", "not_found");
      return;
    }

    res.json({ user });
  } catch (error) {
    console.error("Get user error:", error);
    sendError(res, 500, "Failed to fetch user", "internal_error");
  }
});

export default router;
