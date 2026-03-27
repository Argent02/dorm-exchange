import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { sendError } from "../lib/http.js";

const router = Router();
router.use(requireAuth, requireUser);
const listingIdParamSchema = z.object({ listingId: z.string().uuid() });

/** Convert Prisma listing to plain JSON-serializable object (handles Decimal, Date). */
function listingToJson(l: {
  id: string;
  title: string;
  description: string | null;
  imageUrl: string | null;
  price: unknown;
  isFree: boolean;
  category: string | null;
  status: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
  creator: { id: string; name: string | null; email: string } | null;
}) {
  const priceVal = l.price != null && typeof (l.price as { toString?: () => string }).toString === "function"
    ? parseFloat((l.price as { toString: () => string }).toString())
    : l.price != null && typeof l.price === "number"
      ? l.price
      : null;
  const price = priceVal != null && !Number.isNaN(priceVal) ? priceVal : null;
  return {
    id: l.id,
    title: l.title,
    description: l.description,
    imageUrl: l.imageUrl,
    price,
    isFree: l.isFree,
    category: l.category,
    status: l.status,
    createdBy: l.createdBy,
    createdAt: l.createdAt.toISOString(),
    updatedAt: l.updatedAt.toISOString(),
    creator: l.creator,
    isSaved: true,
  };
}

/**
 * GET /saved
 * Returns the current user's saved listings.
 */
router.get("/", async (req, res) => {
  try {
    const userId = req.user!.id;

    const saved = await prisma.savedListing.findMany({
      where: { userId },
      include: {
        listing: {
          include: {
            creator: { select: { id: true, name: true, email: true } },
          },
        },
      },
      orderBy: { savedAt: "desc" },
    });

    res.json({ listings: saved.map((s) => listingToJson(s.listing)) });
  } catch (error: unknown) {
    console.error("Get saved error:", error);
    const errStr = String(error);
    const message =
      errStr.includes("saved_listings") || errStr.includes("does not exist") || errStr.includes("P1014")
        ? "Saved listings table not found. Run: npx prisma migrate deploy"
        : "Failed to load saved listings";
    sendError(res, 500, message, "internal_error");
  }
});

/**
 * POST /saved/:listingId
 * Save a listing.
 */
router.post("/:listingId", async (req, res) => {
  try {
    const userId = req.user!.id;
    const parsedParams = listingIdParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid listing id", "bad_request");
      return;
    }
    const { listingId } = parsedParams.data;

    const listing = await prisma.listing.findUnique({
      where: { id: listingId },
      select: { id: true, status: true },
    });
    if (!listing || listing.status === "deleted") {
      sendError(res, 404, "Listing not found", "not_found");
      return;
    }

    await prisma.savedListing.upsert({
      where: {
        userId_listingId: { userId, listingId },
      },
      create: { userId, listingId },
      update: { savedAt: new Date() },
    });

    res.status(201).json({ saved: true });
  } catch (error) {
    console.error("Save listing error:", error);
    sendError(res, 500, "Failed to save listing", "internal_error");
  }
});

/**
 * DELETE /saved/:listingId
 * Unsave a listing.
 */
router.delete("/:listingId", async (req, res) => {
  try {
    const userId = req.user!.id;
    const parsedParams = listingIdParamSchema.safeParse(req.params);
    if (!parsedParams.success) {
      sendError(res, 400, "Invalid listing id", "bad_request");
      return;
    }
    const { listingId } = parsedParams.data;

    await prisma.savedListing.deleteMany({
      where: { userId, listingId },
    });

    res.json({ saved: false });
  } catch (error) {
    console.error("Unsave listing error:", error);
    sendError(res, 500, "Failed to unsave listing", "internal_error");
  }
});

export default router;
