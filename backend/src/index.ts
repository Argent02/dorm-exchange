import "dotenv/config";
import express from "express";
import cors from "cors";

import authRoutes from "./routes/auth.js";
import conversationsRoutes from "./routes/conversations.js";
import exchangesRoutes from "./routes/exchanges.js";
import listingsRoutes from "./routes/listings.js";
import savedRoutes from "./routes/saved.js";
import notificationsRoutes from "./routes/notifications.js";
import usersRoutes from "./routes/users.js";

// ─── Validate Required Env Vars ──────────────────────────
const requiredEnvVars = ["DATABASE_URL", "GOOGLE_APPLICATION_CREDENTIALS"] as const;
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.error(
      `\n✗ Missing required environment variable: ${envVar}\n` +
      `  Copy backend/.env.example to backend/.env and fill in the values.\n`
    );
    process.exit(1);
  }
}

const app = express();
const PORT = parseInt(process.env.PORT || "3000", 10);

// ─── Middleware ───────────────────────────────────────────

app.use(cors());
app.use(express.json());

// ─── Routes ──────────────────────────────────────────────

app.use("/auth", authRoutes);
app.use("/conversations", conversationsRoutes);
app.use("/exchanges", exchangesRoutes);
app.use("/listings", listingsRoutes);
app.use("/saved", savedRoutes);
app.use("/notifications", notificationsRoutes);
app.use("/users", usersRoutes);

// ─── Health Check ────────────────────────────────────────

app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ─── Start Server ────────────────────────────────────────

app.listen(PORT, "0.0.0.0", () => {
  console.log(`DormExchange API running on http://0.0.0.0:${PORT}`);
});

export default app;
