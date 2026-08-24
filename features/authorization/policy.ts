export type RoleName = "Admin" | "Operator" | "Manager" | "Viewer";
export type AccessLevel = "Owner" | "Collaborator" | "Viewer" | "Scoped" | "None";
export type AppUser = { id:string; role:RoleName; status:string; scopes?:Array<{scopeType:string;scopeId:string|null}> };
export type CaseResource = { id:string; ownerId:string; labId?:string|null; teamId?:string|null; memberAccess?:"Collaborator"|"Viewer"|null };

export function getCaseAccessLevel(user:AppUser,item:CaseResource):AccessLevel{
  if(user.status!=="Active")return "None";
  if(user.role==="Admin"||item.ownerId===user.id)return "Owner";
  if(item.memberAccess==="Collaborator")return "Collaborator";
  if(item.memberAccess==="Viewer")return "Viewer";
  for(const scope of user.scopes||[]){if(scope.scopeType==="All Organization")return "Scoped";if(scope.scopeType==="Assigned Cases")continue;if(scope.scopeType==="Lab"&&scope.scopeId===item.labId)return "Scoped";if(scope.scopeType==="Team"&&scope.scopeId===item.teamId)return "Scoped"}
  return "None";
}
export const canViewCase=(u:AppUser,c:CaseResource)=>getCaseAccessLevel(u,c)!=="None";
export const canEditCase=(u:AppUser,c:CaseResource)=>["Owner","Collaborator"].includes(getCaseAccessLevel(u,c));
export const canShareCase=(u:AppUser,c:CaseResource)=>getCaseAccessLevel(u,c)==="Owner";
export const canCompleteTask=(u:AppUser,ownerId:string,caseAccess:AccessLevel)=>u.role==="Admin"||ownerId===u.id||caseAccess==="Owner"||caseAccess==="Collaborator";
export const canAssignTask=(u:AppUser,c:CaseResource)=>["Owner","Collaborator"].includes(getCaseAccessLevel(u,c));
