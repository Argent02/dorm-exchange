import "dotenv/config";
import { createApp } from "./app.js";

// ─── Validate Required Env Vars ──────────────────────────
const requiredEnvVars = [
  "DATABASE_URL",
  "GOOGLE_APPLICATION_CREDENTIALS",
  "ALLOWED_EMAIL_DOMAINS",
] as const;
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.error(
      `\n✗ Missing required environment variable: ${envVar}\n` +
        `  Copy backend/.env.example to backend/.env and fill in the values.\n`
    );
    process.exit(1);
  }
}

const PORT = parseInt(process.env.PORT || "3000", 10);
const corsOrigin = process.env.CORS_ORIGIN;
const isProduction = process.env.NODE_ENV === "production";

if (isProduction) {
  const trimmed = corsOrigin?.trim() ?? "";
  if (!trimmed) {
    console.error(
      "\n✗ CORS_ORIGIN is required in production (NODE_ENV=production).\n" +
        "  Set CORS_ORIGIN to a comma-separated list of allowed web origins.\n"
    );
    process.exit(1);
  }
}

const app = createApp();

app.listen(PORT, "0.0.0.0", () => {
  console.log(`DormExchange API running on http://0.0.0.0:${PORT}`);
});

export default app;
