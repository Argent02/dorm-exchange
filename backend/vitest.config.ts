import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
    pool: "forks",
    env: {
      // Matches the "@school.edu" fixture emails used throughout
      // src/__tests__/api.integration.test.ts.
      ALLOWED_EMAIL_DOMAINS: "school.edu",
    },
  },
});
