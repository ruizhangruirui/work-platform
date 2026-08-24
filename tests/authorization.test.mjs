import test from "node:test";
import assert from "node:assert/strict";
import { canAssignTask, canCompleteTask, canEditCase, canShareCase, getCaseAccessLevel } from "../features/authorization/policy.ts";

const caseItem={id:"case-1",ownerId:"owner",labId:"lab-a",teamId:"team-a"};
const user=(id,role,scopes=[],status="Active")=>({id,role,scopes,status});

test("owner and admin receive owner-level access",()=>{
  assert.equal(getCaseAccessLevel(user("owner","Operator"),caseItem),"Owner");
  assert.equal(getCaseAccessLevel(user("admin","Admin"),caseItem),"Owner");
});

test("direct sharing grants viewer or collaborator access",()=>{
  assert.equal(getCaseAccessLevel(user("guest","Viewer"),{...caseItem,memberAccess:"Viewer"}),"Viewer");
  const collaborator={...caseItem,memberAccess:"Collaborator"};
  assert.equal(canEditCase(user("guest","Operator"),collaborator),true);
  assert.equal(canShareCase(user("guest","Operator"),collaborator),false);
});

test("lab and team scopes are enforced",()=>{
  assert.equal(getCaseAccessLevel(user("manager","Manager",[{scopeType:"Lab",scopeId:"lab-a"}]),caseItem),"Scoped");
  assert.equal(getCaseAccessLevel(user("manager","Manager",[{scopeType:"Team",scopeId:"other"}]),caseItem),"None");
});

test("inactive and unscoped users cannot access cases",()=>{
  assert.equal(getCaseAccessLevel(user("guest","Viewer",[],"Inactive"),caseItem),"None");
  assert.equal(getCaseAccessLevel(user("guest","Viewer"),caseItem),"None");
});

test("task completion follows assignment and case access",()=>{
  assert.equal(canCompleteTask(user("assignee","Viewer"),"assignee","Viewer"),true);
  assert.equal(canCompleteTask(user("stranger","Viewer"),"assignee","Viewer"),false);
  assert.equal(canCompleteTask(user("collab","Operator"),"assignee","Collaborator"),true);
  assert.equal(canAssignTask(user("collab","Operator"),{...caseItem,memberAccess:"Collaborator"}),true);
});
