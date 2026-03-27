import { Router } from "express";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";
import { sendError } from "../lib/http.js";

const router = Router();
router.use(requireAuth, requireUser);

/**
 * GET /exchanges
 * Returns the current user's exchanges, split into bought and sold.
 * Also includes sold/taken listings that do not have an Exchange record.
 */
router.get("/", async (req, res) => {
  try {
    const userId = req.user!.id;

    const [bought, soldExchanges] = await Promise.all([
      prisma.exchange.findMany({
        where: { buyerId: userId },
        include: {
          listing: {
            select: { id: true, title: true, imageUrl: true, isFree: true, price: true, status: true },
          },
          seller: { select: { id: true, name: true, email: true } },
          buyer: { select: { id: true, name: true, email: true } },
        },
        orderBy: { createdAt: "desc" },
      }),
      prisma.exchange.findMany({
        where: { sellerId: userId },
        include: {
          listing: {
            select: { id: true, title: true, imageUrl: true, isFree: true, price: true, status: true },
          },
          seller: { select: { id: true, name: true, email: true } },
          buyer: { select: { id: true, name: true, email: true } },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    const exchangeListingIds = new Set(soldExchanges.map((e) => e.listingId));
    const soldListings = await prisma.listing.findMany({
      where: {
        createdBy: userId,
        status: { in: ["sold", "taken"] },
        id: { notIn: [...exchangeListingIds] },
      },
      select: { id: true, title: true, imageUrl: true, isFree: true, price: true, status: true, updatedAt: true },
      orderBy: { updatedAt: "desc" },
    });

    res.json({ bought, sold: soldExchanges, soldListings });
  } catch (error) {
    console.error("Get exchanges error:", error);
    sendError(res, 500, "Failed to load exchanges", "internal_error");
  }
});

export default router;
