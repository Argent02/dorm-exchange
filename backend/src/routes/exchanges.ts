import { Router } from "express";
import prisma from "../lib/prisma.js";
import { requireAuth, requireUser } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth, requireUser);

/**
 * GET /exchanges
 * Returns the current user's exchanges, split into bought and sold.
 */
router.get("/", async (req, res) => {
  try {
    const userId = req.user!.id;

    const [bought, sold] = await Promise.all([
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

    res.json({ bought, sold });
  } catch (error) {
    console.error("Get exchanges error:", error);
    res.status(500).json({ error: "Failed to load exchanges" });
  }
});

export default router;
