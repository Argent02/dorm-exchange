import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { ListingStatus } from "../generated/prisma/client.js";

const router = Router();

// All listing routes require authentication
router.use(requireAuth, requireUser);

// ─── Validation Schemas ──────────────────────────────────

const createListingSchema = z.object({
  title: z.string().min(1, "Title is required").max(255),
  description: z.string().optional(),
  imageUrl: z.string().url().optional(),
  price: z.number().min(0).optional(),
  isFree: z.boolean().default(false),
  category: z.string().max(100).optional(),
}).refine(
  (data) => data.isFree || (data.price !== undefined && data.price > 0),
  { message: "Price is required when item is not free", path: ["price"] }
);

const updateListingSchema = z.object({
  title: z.string().min(1).max(255).optional(),
  description: z.string().optional(),
  imageUrl: z.string().url().optional().nullable(),
  price: z.number().min(0).optional(),
  isFree: z.boolean().optional(),
  category: z.string().max(100).optional(),
});

const updateStatusSchema = z.object({
  status: z.enum(["active", "sold", "taken", "deleted"]),
});

// ─── Routes ──────────────────────────────────────────────

/**
 * GET /listings
 * List all active listings with optional filters.
 * Query params: search, category, isFree, page, limit
 */
router.get("/", async (req, res) => {
  try {
    const {
      search,
      category,
      isFree,
      page = "1",
      limit = "20",
    } = req.query;

    const pageNum = Math.max(1, parseInt(page as string, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit as string, 10) || 20));
    const skip = (pageNum - 1) * limitNum;

    // Build where clause
    const where: any = {
      status: "active" as ListingStatus,
    };

    if (category && typeof category === "string") {
      where.category = category;
    }

    if (isFree === "true") {
      where.isFree = true;
    } else if (isFree === "false") {
      where.isFree = false;
    }

    // Full-text search on title and description
    if (search && typeof search === "string") {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
      ];
    }

    const [listings, total] = await Promise.all([
      prisma.listing.findMany({
        where,
        include: {
          creator: {
            select: { id: true, name: true, email: true, firebaseUid: true },
          },
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limitNum,
      }),
      prisma.listing.count({ where }),
    ]);

    res.json({
      listings,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    console.error("List listings error:", error);
    res.status(500).json({ error: "Failed to fetch listings" });
  }
});

/**
 * GET /listings/:id
 * Get a single listing by ID with creator info.
 */
router.get("/:id", async (req, res) => {
  try {
    const listing = await prisma.listing.findUnique({
      where: { id: req.params.id },
      include: {
        creator: {
          select: { id: true, name: true, email: true, joinDate: true, firebaseUid: true },
        },
      },
    });

    if (!listing || listing.status === "deleted") {
      res.status(404).json({ error: "Listing not found" });
      return;
    }

    res.json({ listing });
  } catch (error) {
    console.error("Get listing error:", error);
    res.status(500).json({ error: "Failed to fetch listing" });
  }
});

/**
 * POST /listings
 * Create a new listing.
 */
router.post("/", async (req, res) => {
  const parsed = createListingSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  try {
    const listing = await prisma.listing.create({
      data: {
        title: parsed.data.title,
        description: parsed.data.description,
        imageUrl: parsed.data.imageUrl,
        price: parsed.data.price,
        isFree: parsed.data.isFree,
        category: parsed.data.category,
        createdBy: req.user!.id,
      },
      include: {
        creator: {
          select: { id: true, name: true, email: true, firebaseUid: true },
        },
      },
    });

    res.status(201).json({ listing });
  } catch (error) {
    console.error("Create listing error:", error);
    res.status(500).json({ error: "Failed to create listing" });
  }
});

/**
 * PUT /listings/:id
 * Update an existing listing. Only the creator can edit.
 */
router.put("/:id", async (req, res) => {
  const parsed = updateListingSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  try {
    // Check ownership
    const existing = await prisma.listing.findUnique({
      where: { id: req.params.id },
    });

    if (!existing || existing.status === "deleted") {
      res.status(404).json({ error: "Listing not found" });
      return;
    }

    if (existing.createdBy !== req.user!.id) {
      res.status(403).json({ error: "You can only edit your own listings" });
      return;
    }

    const listing = await prisma.listing.update({
      where: { id: req.params.id },
      data: parsed.data,
      include: {
        creator: {
          select: { id: true, name: true, email: true, firebaseUid: true },
        },
      },
    });

    res.json({ listing });
  } catch (error) {
    console.error("Update listing error:", error);
    res.status(500).json({ error: "Failed to update listing" });
  }
});

/**
 * PATCH /listings/:id/status
 * Mark a listing as sold/taken/deleted. Only the creator can change status.
 */
router.patch("/:id/status", async (req, res) => {
  const parsed = updateStatusSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  try {
    const existing = await prisma.listing.findUnique({
      where: { id: req.params.id },
    });

    if (!existing || existing.status === "deleted") {
      res.status(404).json({ error: "Listing not found" });
      return;
    }

    if (existing.createdBy !== req.user!.id) {
      res.status(403).json({ error: "You can only update your own listings" });
      return;
    }

    const listing = await prisma.listing.update({
      where: { id: req.params.id },
      data: { status: parsed.data.status as ListingStatus },
    });

    res.json({ listing });
  } catch (error) {
    console.error("Update status error:", error);
    res.status(500).json({ error: "Failed to update listing status" });
  }
});

export default router;
