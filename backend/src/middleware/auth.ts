import type { Request, Response, NextFunction } from "express";
import { firebaseAuth } from "../lib/firebase.js";
import prisma from "../lib/prisma.js";
import type { User } from "../generated/prisma/client.js";

// Extend Express Request to include authenticated user
declare global {
  namespace Express {
    interface Request {
      firebaseUid?: string;
      firebaseEmail?: string;
      user?: User;
    }
  }
}

/**
 * Middleware that validates a Firebase ID token from the Authorization header.
 * On success, attaches firebaseUid and firebaseEmail to req.
 * Does NOT query the database — use requireUser after this if you need req.user.
 */
export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing or malformed Authorization header" });
    return;
  }

  const token = authHeader.split("Bearer ")[1];

  try {
    const decoded = await firebaseAuth.verifyIdToken(token);
    req.firebaseUid = decoded.uid;
    req.firebaseEmail = decoded.email;
    next();
  } catch (error) {
    res.status(401).json({ error: "Invalid or expired token" });
    return;
  }
}

/**
 * Middleware that loads the full User record from the database.
 * Must be used AFTER requireAuth.
 * Creates the user record if this is their first request (upsert).
 */
export async function requireUser(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  if (!req.firebaseUid || !req.firebaseEmail) {
    res.status(401).json({ error: "Authentication required" });
    return;
  }

  try {
    const user = await prisma.user.upsert({
      where: { firebaseUid: req.firebaseUid },
      update: {},
      create: {
        firebaseUid: req.firebaseUid,
        email: req.firebaseEmail,
      },
    });

    req.user = user;
    next();
  } catch (error) {
    console.error("Error loading user:", error);
    res.status(500).json({ error: "Internal server error" });
    return;
  }
}
