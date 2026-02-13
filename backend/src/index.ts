import "dotenv/config";
import express from "express";
import cors from "cors";

import authRoutes from "./routes/auth.js";
import listingsRoutes from "./routes/listings.js";
import usersRoutes from "./routes/users.js";

const app = express();
const PORT = parseInt(process.env.PORT || "3000", 10);

// ─── Middleware ───────────────────────────────────────────

app.use(cors());
app.use(express.json());

// ─── Routes ──────────────────────────────────────────────

app.use("/auth", authRoutes);
app.use("/listings", listingsRoutes);
app.use("/users", usersRoutes);

// ─── Health Check ────────────────────────────────────────

app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ─── Start Server ────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`DormExchange API running on http://localhost:${PORT}`);
});

export default app;
