import express from "express";
import cors from "cors";

import authRoutes from "./routes/auth.js";
import conversationsRoutes from "./routes/conversations.js";
import exchangesRoutes from "./routes/exchanges.js";
import listingsRoutes from "./routes/listings.js";
import savedRoutes from "./routes/saved.js";
import notificationsRoutes from "./routes/notifications.js";
import usersRoutes from "./routes/users.js";

/**
 * Builds the Express application (routes + middleware). Does not call listen().
 */
export function createApp(): express.Application {
  const app = express();
  const corsOrigin = process.env.CORS_ORIGIN;

  app.disable("x-powered-by");

  app.use(
    cors({
      origin: corsOrigin
        ? corsOrigin.split(",").map((o) => o.trim()).filter(Boolean)
        : true,
    })
  );
  app.use(express.json({ limit: "1mb" }));
  app.use((_req, res, next) => {
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("X-Frame-Options", "DENY");
    next();
  });

  app.use("/auth", authRoutes);
  app.use("/conversations", conversationsRoutes);
  app.use("/exchanges", exchangesRoutes);
  app.use("/listings", listingsRoutes);
  app.use("/saved", savedRoutes);
  app.use("/notifications", notificationsRoutes);
  app.use("/users", usersRoutes);

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  return app;
}
