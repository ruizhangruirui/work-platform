import test from "node:test";
import assert from "node:assert/strict";
import { isShareAccessLevel, parseSaveUserInput, isUniqueConstraintError } from "../features/authorization/validation.ts";
import { caseVisibilityWhere } from "../features/authorization/visibility.ts";

test("share access level only accepts Collaborator or Viewer", () => {
  assert.equal(isShareAccessLevel("Collaborator"), true);
  assert.equal(isShareAccessLevel("Viewer"), true);
  assert.equal(isShareAccessLevel("Owner"), false);
  assert.equal(isShareAccessLevel("garbage"), false);
  assert.equal(isShareAccessLevel(undefined), false);
  assert.equal(isShareAccessLevel(null), false);
});

test("saveUser input is normalized and validated", () => {
  const ok = parseSaveUserInput({ name: "  Anna Meier ", email: "Anna.Meier@Example.com", title: "", status: "Inactive" });
  assert.deepEqual(ok, { input: { name: "Anna Meier", email: "anna.meier@example.com", title: null, status: "Inactive" } });

  assert.deepEqual(parseSaveUserInput({ name: "", email: "a@b.co" }), { error: "invalid_name" });
  assert.deepEqual(parseSaveUserInput({ name: 42, email: "a@b.co" }), { error: "invalid_name" });
  assert.deepEqual(parseSaveUserInput({ name: "A", email: "not-an-email" }), { error: "invalid_email" });
  assert.deepEqual(parseSaveUserInput({ name: "A", email: {} }), { error: "invalid_email" });

  // Unknown status values fall back to Active instead of being stored verbatim.
  const fallback = parseSaveUserInput({ name: "A", email: "a@b.co", status: "Banned" });
  assert.equal(fallback.input.status, "Active");
});

test("unique constraint detection works for D1 errors", () => {
  assert.equal(isUniqueConstraintError(new Error("D1: UNIQUE constraint failed: users.email")), true);
  assert.equal(isUniqueConstraintError(new Error("some other error")), false);
});

test("case visibility SQL mirrors the access policy", () => {
  // Admins and org-wide scopes: no extra filtering.
  assert.deepEqual(caseVisibilityWhere({ id: "u1", role: "Admin", scopes: [] }), { clause: "", values: [] });
  assert.deepEqual(caseVisibilityWhere({ id: "u1", role: "Viewer", scopes: [{ scopeType: "All Organization", scopeId: null }] }), { clause: "", values: [] });

  // Ownership and membership are always included for non-admins.
  const plain = caseVisibilityWhere({ id: "u1", role: "Viewer", scopes: [] });
  assert.equal(plain.clause, "AND (c.owner_id = ? OR cm.user_id IS NOT NULL)");
  assert.deepEqual(plain.values, ["u1"]);

  // Lab/Team scopes become extra OR conditions; Assigned Cases adds nothing.
  const scoped = caseVisibilityWhere({
    id: "u1",
    role: "Manager",
    scopes: [
      { scopeType: "Lab", scopeId: "lab-a" },
      { scopeType: "Team", scopeId: "team-b" },
      { scopeType: "Assigned Cases", scopeId: null },
    ],
  });
  assert.equal(scoped.clause, "AND (c.owner_id = ? OR cm.user_id IS NOT NULL OR p.lab_id = ? OR p.team_id = ?)");
  assert.deepEqual(scoped.values, ["u1", "lab-a", "team-b"]);
});
