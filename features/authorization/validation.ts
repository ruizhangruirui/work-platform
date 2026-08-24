// Input validation helpers for workbench API actions.
// Pure functions (no Cloudflare / DB imports) so they can be unit tested with node:test.

export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const SHARE_ACCESS_LEVELS = ["Collaborator", "Viewer"] as const;
export type ShareAccessLevel = (typeof SHARE_ACCESS_LEVELS)[number];

export function isShareAccessLevel(value: unknown): value is ShareAccessLevel {
  return typeof value === "string" && (SHARE_ACCESS_LEVELS as readonly string[]).includes(value);
}

export type SaveUserInput = {
  name: string;
  email: string;
  title: string | null;
  status: "Active" | "Inactive";
};

export type SaveUserError = "invalid_name" | "invalid_email";

/**
 * Normalize and validate the saveUser payload. Returns either the error code
 * or a sanitized input (trimmed, lowercased email, enum-safe status).
 */
export function parseSaveUserInput(body: Record<string, unknown>): { error: SaveUserError } | { input: SaveUserInput } {
  const name = typeof body.name === "string" ? body.name.trim() : "";
  if (!name || name.length > 120) return { error: "invalid_name" };
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  if (!EMAIL_RE.test(email) || email.length > 254) return { error: "invalid_email" };
  const title = typeof body.title === "string" && body.title.trim() ? body.title.trim() : null;
  const status = body.status === "Inactive" ? "Inactive" : "Active";
  return { input: { name, email, title, status } };
}

export function isUniqueConstraintError(error: unknown): boolean {
  return String((error as { message?: unknown })?.message ?? error).includes("UNIQUE constraint failed");
}
