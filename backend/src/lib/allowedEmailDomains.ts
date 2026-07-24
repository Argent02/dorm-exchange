/**
 * Server-side enforcement of the student-email-domain policy.
 *
 * Reads `ALLOWED_EMAIL_DOMAINS` (comma-separated, e.g. "niu.edu,otherschool.edu")
 * on every check so the allowlist can be changed via env var without a code change.
 * This mirrors the existing `CORS_ORIGIN` comma-separated pattern used elsewhere
 * in this backend for consistency.
 */
function getAllowedDomains(): string[] {
  const raw = process.env.ALLOWED_EMAIL_DOMAINS ?? "";
  return raw
    .split(",")
    .map((domain) => domain.trim().toLowerCase())
    .filter(Boolean);
}

/**
 * Returns true if the given email's domain (the part after "@") is on the
 * configured allowlist. Fails closed: missing/malformed email or an empty
 * allowlist always returns false.
 */
export function isAllowedEmailDomain(email: string | undefined | null): boolean {
  if (!email) return false;

  const atIndex = email.lastIndexOf("@");
  if (atIndex === -1 || atIndex === email.length - 1) return false;

  const domain = email.slice(atIndex + 1).toLowerCase();
  const allowed = getAllowedDomains();

  return allowed.length > 0 && allowed.includes(domain);
}
