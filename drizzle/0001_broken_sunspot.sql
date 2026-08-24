CREATE TABLE `case_members` (
	`id` text PRIMARY KEY NOT NULL,
	`case_id` text NOT NULL,
	`user_id` text NOT NULL,
	`access_level` text NOT NULL,
	`created_by` text NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL,
	`revoked_at` text
);
--> statement-breakpoint
CREATE INDEX `case_members_case_idx` ON `case_members` (`case_id`);--> statement-breakpoint
CREATE INDEX `case_members_user_idx` ON `case_members` (`user_id`);--> statement-breakpoint
CREATE UNIQUE INDEX `case_members_case_user_unique` ON `case_members` (`case_id`,`user_id`);
--> statement-breakpoint
INSERT OR IGNORE INTO roles(id,name,permissions,created_at,updated_at) VALUES
('role_admin','Admin','["view_all","edit_all","manage_users","share","assign","audit"]','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),
('role_operator','Operator','["create_case","edit_owned","edit_shared","complete_task","assign"]','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),
('role_manager','Manager','["view_scoped","complete_assigned"]','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),
('role_viewer','Viewer','["view_permitted","complete_assigned"]','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO users(id,email,name,title,role_id,status,created_at,updated_at) VALUES
('user_rui','zhangruisomebody@outlook.com','Rui Zhang','People Operations','role_admin','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),
('user_anna','anna.meier@example.com','Anna Meier','People Operations Specialist','role_operator','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),
('user_todor','todor.petrov@example.com','Todor Petrov','IT Support','role_viewer','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),
('user_john','john.smith@example.com','John Smith','Network Manager','role_manager','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO labs(id,name,status,created_at,updated_at) VALUES('lab_vnl','VNL','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO teams(id,lab_id,name,status,created_at,updated_at) VALUES('team_network','lab_vnl','Network','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('team_ai','lab_vnl','AI Systems','Active','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO user_scopes(id,user_id,scope_type,scope_id,created_at,updated_at) VALUES('scope_rui','user_rui','All Organization',NULL,'2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('scope_anna','user_anna','Assigned Cases',NULL,'2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('scope_todor','user_todor','Assigned Cases',NULL,'2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('scope_john','user_john','Team','team_network','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO persons(id,first_name,last_name,full_name,email,employee_id,phone,lab_id,team_id,manager_id,created_at,updated_at) VALUES('person_michael','Michael','Smith','Michael Smith','michael.smith@example.com',NULL,'+41 79 555 14 08','lab_vnl','team_network','user_john','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('person_sofia','Sofia','Rossi','Sofia Rossi','sofia.rossi@example.com',NULL,NULL,'lab_vnl','team_ai','user_john','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO cases(id,person_id,case_type,employment_type,start_date,workload,contract_type,role,location,owner_id,status,priority,notes,created_at,updated_at) VALUES('case_michael','person_michael','Onboarding','Employee','2026-09-15',100,'Permanent','Senior Research Engineer','Zurich','user_rui','Preparing','High','Relocation support required','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('case_sofia','person_sofia','Onboarding','Intern','2026-10-01',100,'Fixed term','Research Intern','Zurich','user_anna','Waiting','Medium',NULL,'2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO case_members(id,case_id,user_id,access_level,created_by,created_at,updated_at) VALUES('member_anna','case_michael','user_anna','Collaborator','user_rui','2026-08-24T09:00:00Z','2026-08-24T09:00:00Z'),('member_todor','case_michael','user_todor','Viewer','user_rui','2026-08-24T09:00:00Z','2026-08-24T09:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO tasks(id,case_id,checklist_item_id,title,task_type,owner_id,due_date,priority,status,created_at,updated_at) VALUES('task_contract','case_michael','check_contract','Contract signed','General','user_rui','2026-08-28','High','Open','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('task_welcome','case_michael','check_welcome','Send welcome email','Email','user_anna','2026-08-26','High','Open','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('task_it','case_michael','check_it','Confirm IT account','General','user_todor','2026-09-10','Medium','Open','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('task_laptop','case_michael','check_laptop','Laptop','General','user_todor','2026-09-10','Medium','Waiting','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO case_checklist_items(id,case_id,section,title,status,owner_id,due_date,sort_order,task_id,created_at,updated_at) VALUES('check_contract','case_michael','PRE-ONBOARDING','Contract signed','Open','user_rui','2026-08-28',1,'task_contract','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('check_welcome','case_michael','COMMUNICATION','Welcome email','Open','user_anna','2026-08-26',1,'task_welcome','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('check_it','case_michael','PRE-ONBOARDING','IT account','Open','user_todor','2026-09-10',2,'task_it','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z'),('check_laptop','case_michael','PRE-ONBOARDING','Laptop','Waiting','user_todor','2026-09-10',3,'task_laptop','2026-08-24T08:00:00Z','2026-08-24T08:00:00Z');
--> statement-breakpoint
INSERT OR IGNORE INTO audit_logs(id,actor_id,entity_type,entity_id,action,field,previous_value,new_value,metadata,created_at) VALUES('audit_seed','user_rui','case','case_michael','case created','status',NULL,'Preparing','{"caseId":"case_michael"}','2026-08-24T08:00:00Z');
