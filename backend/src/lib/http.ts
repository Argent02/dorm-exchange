import type { Response } from "express";

type ErrorCode =
  | "bad_request"
  | "unauthorized"
  | "forbidden"
  | "not_found"
  | "conflict"
  | "validation_failed"
  | "internal_error"
  | "listing_owner_mismatch"
  | "invalid_school_email";

/**
 * Sends a standardized API error response while preserving legacy `error` string.
 */
export function sendError(
  res: Response,
  status: number,
  message: string,
  code: ErrorCode
) {
  return res.status(status).json({
    error: message,
    code,
  });
}

