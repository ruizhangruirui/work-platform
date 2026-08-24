import type { AppUser } from "./policy";

/**
 * Builds the SQL WHERE fragment that pushes case visibility down to the
 * database, mirroring getCaseAccessLevel() in policy.ts:
 * a non-admin sees a case when they own it, are an active member, or the
 * person's lab/team matches one of the user's scopes.
 *
 * Admins and users with the "All Organization" scope get an empty clause
 * (no extra filtering). "Assigned Cases" scopes add nothing because those
 * cases are already covered by ownership/membership.
 *
 * The JS-side getCaseAccessLevel() filter is still applied afterwards as
 * defense in depth and to compute the per-case accessLevel for the response.
 */
export function caseVisibilityWhere(user: Pick<AppUser, "id" | "role" | "scopes">): { clause: string; values: unknown[] } {
  if (user.role === "Admin") return { clause: "", values: [] };
  const conditions: string[] = ["c.owner_id = ?", "cm.user_id IS NOT NULL"];
  const values: unknown[] = [user.id];
  for (const scope of user.scopes || []) {
    if (scope.scopeType === "All Organization") return { clause: "", values: [] };
    if (scope.scopeType === "Lab" && scope.scopeId) {
      conditions.push("p.lab_id = ?");
      values.push(scope.scopeId);
    }
    if (scope.scopeType === "Team" && scope.scopeId) {
      conditions.push("p.team_id = ?");
      values.push(scope.scopeId);
    }
  }
  return { clause: `AND (${conditions.join(" OR ")})`, values };
}
