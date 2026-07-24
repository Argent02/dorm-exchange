import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";

vi.mock("../lib/firebase.js", () => ({
  firebaseAuth: {
    verifyIdToken: vi.fn(),
  },
}));

vi.mock("../lib/prisma.js", () => {
  const mock = {
    user: {
      upsert: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    listing: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    savedListing: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
    },
    conversation: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    message: {
      findMany: vi.fn(),
      create: vi.fn(),
    },
    exchange: {
      findMany: vi.fn(),
    },
    notification: {
      findMany: vi.fn(),
      updateMany: vi.fn(),
      update: vi.fn(),
    },
  };
  return { default: mock };
});

import { createApp } from "../app.js";
import { firebaseAuth } from "../lib/firebase.js";
import prisma from "../lib/prisma.js";

const UID_INITIATOR = "11111111-1111-4111-8111-111111111111";
const UID_OWNER = "22222222-2222-4222-8222-222222222222";
const LISTING_ID = "33333333-3333-4333-8333-333333333333";
const OTHER_USER = "44444444-4444-4444-8444-444444444444";

describe("API integration (mocked Firebase + Prisma)", () => {
  const app = createApp();
  const verify = firebaseAuth.verifyIdToken as ReturnType<typeof vi.fn>;
  const p = prisma as unknown as {
    user: { upsert: ReturnType<typeof vi.fn>; findUnique: ReturnType<typeof vi.fn>; update: ReturnType<typeof vi.fn> };
    listing: {
      findMany: ReturnType<typeof vi.fn>;
      findUnique: ReturnType<typeof vi.fn>;
      count: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
    };
    savedListing: { findMany: ReturnType<typeof vi.fn>; findUnique: ReturnType<typeof vi.fn> };
    conversation: {
      findMany: ReturnType<typeof vi.fn>;
      findFirst: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
    };
    message: { findMany: ReturnType<typeof vi.fn>; create: ReturnType<typeof vi.fn> };
    exchange: { findMany: ReturnType<typeof vi.fn> };
    notification: { findMany: ReturnType<typeof vi.fn> };
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("GET /health returns ok", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  it("GET /auth/me without Authorization returns 401", async () => {
    const res = await request(app).get("/auth/me");
    expect(res.status).toBe(401);
    expect(res.body.code).toBe("unauthorized");
  });

  it("GET /auth/me with invalid token returns 401", async () => {
    verify.mockRejectedValue(new Error("invalid"));
    const res = await request(app)
      .get("/auth/me")
      .set("Authorization", "Bearer bad");
    expect(res.status).toBe(401);
  });

  it("GET /auth/me with a valid token but a non-allowed email domain returns 403", async () => {
    verify.mockResolvedValue({
      uid: "firebase-outsider",
      email: "someone@gmail.com",
    });
    const res = await request(app)
      .get("/auth/me")
      .set("Authorization", "Bearer good.token");
    expect(res.status).toBe(403);
    expect(res.body.code).toBe("invalid_school_email");
    // The user upsert must never be reached for a rejected domain.
    expect(p.user.upsert).not.toHaveBeenCalled();
  });

  it("GET /auth/me with a valid token but no email claim returns 403", async () => {
    verify.mockResolvedValue({
      uid: "firebase-no-email",
    });
    const res = await request(app)
      .get("/auth/me")
      .set("Authorization", "Bearer good.token");
    expect(res.status).toBe(403);
    expect(res.body.code).toBe("invalid_school_email");
  });

  it("POST /auth/login with valid token returns user", async () => {
    verify.mockResolvedValue({
      uid: "firebase-uid-1",
      email: "student@school.edu",
    });
    p.user.upsert.mockResolvedValue({
      id: UID_INITIATOR,
      firebaseUid: "firebase-uid-1",
      email: "student@school.edu",
      name: null,
      role: "USER",
      isVerified: false,
      reportCount: 0,
      joinDate: new Date(),
    });

    const res = await request(app)
      .post("/auth/login")
      .set("Authorization", "Bearer good.token")
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.user).toBeDefined();
    expect(res.body.user.id).toBe(UID_INITIATOR);
  });

  it("POST /conversations returns listing_owner_mismatch when ownerId does not match listing seller", async () => {
    verify.mockResolvedValue({
      uid: "firebase-initiator",
      email: "a@school.edu",
    });
    p.user.upsert.mockResolvedValue({
      id: UID_INITIATOR,
      firebaseUid: "firebase-initiator",
      email: "a@school.edu",
      name: "A",
      role: "USER",
      isVerified: true,
      reportCount: 0,
      joinDate: new Date(),
    });
    p.listing.findUnique.mockResolvedValue({
      id: LISTING_ID,
      createdBy: OTHER_USER,
      status: "active",
    });

    const res = await request(app)
      .post("/conversations")
      .set("Authorization", "Bearer token")
      .send({
        listingId: LISTING_ID,
        ownerId: UID_OWNER,
      });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("listing_owner_mismatch");
  });

  it("PATCH /listings/:id/status returns 403 when not the creator", async () => {
    verify.mockResolvedValue({
      uid: "firebase-user",
      email: "user@school.edu",
    });
    p.user.upsert.mockResolvedValue({
      id: UID_INITIATOR,
      firebaseUid: "firebase-user",
      email: "user@school.edu",
      name: "U",
      role: "USER",
      isVerified: true,
      reportCount: 0,
      joinDate: new Date(),
    });
    p.listing.findUnique.mockResolvedValue({
      id: LISTING_ID,
      createdBy: OTHER_USER,
      status: "active",
      title: "Desk",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app)
      .patch(`/listings/${LISTING_ID}/status`)
      .set("Authorization", "Bearer token")
      .send({ status: "sold" });

    expect(res.status).toBe(403);
    expect(res.body.code).toBe("forbidden");
  });

  it("GET /exchanges returns bought, sold, soldListings", async () => {
    verify.mockResolvedValue({
      uid: "firebase-u",
      email: "u@school.edu",
    });
    p.user.upsert.mockResolvedValue({
      id: UID_INITIATOR,
      firebaseUid: "firebase-u",
      email: "u@school.edu",
      name: "U",
      role: "USER",
      isVerified: true,
      reportCount: 0,
      joinDate: new Date(),
    });
    p.exchange.findMany.mockResolvedValue([]);
    p.listing.findMany.mockResolvedValue([]);

    const res = await request(app)
      .get("/exchanges")
      .set("Authorization", "Bearer token");

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty("bought");
    expect(res.body).toHaveProperty("sold");
    expect(res.body).toHaveProperty("soldListings");
    expect(Array.isArray(res.body.bought)).toBe(true);
  });
});
