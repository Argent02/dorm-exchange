import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { sendError } from "../lib/http.js";

const router = Router();
const updateMeSchema = z.object({
  name: z.string().trim().min(1).max(100).optional(),
  avatarUrl: z.string().url().nullable().optional(),
  phone: z.string().trim().max(20).nullable().optional(),
  dorm: z.string().trim().max(100).nullable().optional(),
});

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
    sendError(res, 500, "Failed to log in", "internal_error");
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
      sendError(res, 404, "User not found", "not_found");
      return;
    }

    res.json({ user });
  } catch (error) {
    console.error("Get me error:", error);
    sendError(res, 500, "Failed to fetch user", "internal_error");
  }
});

/**
 * PATCH /auth/me
 * Updates the current user's profile. Supports: name.
 */
router.patch("/me", requireAuth, requireUser, async (req, res) => {
  try {
    const parsed = updateMeSchema.safeParse(req.body);
    if (!parsed.success) {
      sendError(res, 400, parsed.error.message, "validation_failed");
      return;
    }
    const body = parsed.data;
    const updates: { name?: string; avatarUrl?: string | null; phone?: string | null; dorm?: string | null } = {};
    if (typeof body.name === "string" && body.name.length > 0) {
      updates.name = body.name;
    }
    if (body.avatarUrl !== undefined) {
      updates.avatarUrl = typeof body.avatarUrl === "string" ? body.avatarUrl : null;
    }
    if (body.phone !== undefined) {
      updates.phone = typeof body.phone === "string" ? body.phone.trim().slice(0, 20) || null : null;
    }
    if (body.dorm !== undefined) {
      updates.dorm = typeof body.dorm === "string" ? body.dorm.trim().slice(0, 100) || null : null;
    }

    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: updates,
    });

    res.json({ user });
  } catch (error) {
    console.error("Update me error:", error);
    sendError(res, 500, "Failed to update profile", "internal_error");
  }
});

export default router;
