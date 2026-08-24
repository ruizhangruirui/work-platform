CREATE TABLE `audit_logs` (
	`id` text PRIMARY KEY NOT NULL,
	`actor_id` text NOT NULL,
	`entity_type` text NOT NULL,
	`entity_id` text NOT NULL,
	`action` text NOT NULL,
	`field` text,
	`previous_value` text,
	`new_value` text,
	`metadata` text,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `audit_entity_idx` ON `audit_logs` (`entity_type`,`entity_id`);--> statement-breakpoint
CREATE TABLE `cases` (
	`id` text PRIMARY KEY NOT NULL,
	`person_id` text NOT NULL,
	`case_type` text NOT NULL,
	`employment_type` text,
	`start_date` text,
	`end_date` text,
	`workload` integer,
	`contract_type` text,
	`role` text,
	`location` text,
	`owner_id` text NOT NULL,
	`status` text NOT NULL,
	`priority` text DEFAULT 'Medium' NOT NULL,
	`notes` text,
	`archived_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `cases_person_idx` ON `cases` (`person_id`);--> statement-breakpoint
CREATE INDEX `cases_owner_status_idx` ON `cases` (`owner_id`,`status`);--> statement-breakpoint
CREATE TABLE `case_checklist_items` (
	`id` text PRIMARY KEY NOT NULL,
	`case_id` text NOT NULL,
	`section` text NOT NULL,
	`title` text NOT NULL,
	`status` text NOT NULL,
	`owner_id` text,
	`due_date` text,
	`completed_date` text,
	`completed_by` text,
	`sort_order` integer NOT NULL,
	`task_id` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `checklist_case_idx` ON `case_checklist_items` (`case_id`);--> statement-breakpoint
CREATE TABLE `communications` (
	`id` text PRIMARY KEY NOT NULL,
	`case_id` text NOT NULL,
	`person_id` text NOT NULL,
	`template_version_id` text,
	`subject` text NOT NULL,
	`status` text NOT NULL,
	`prepared_by` text NOT NULL,
	`prepared_at` text,
	`sent_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `communications_case_idx` ON `communications` (`case_id`);--> statement-breakpoint
CREATE TABLE `email_drafts` (
	`id` text PRIMARY KEY NOT NULL,
	`communication_id` text,
	`case_id` text NOT NULL,
	`person_id` text NOT NULL,
	`template_version_id` text NOT NULL,
	`recipients` text NOT NULL,
	`variables` text NOT NULL,
	`generated_subject` text NOT NULL,
	`generated_html` text NOT NULL,
	`status` text NOT NULL,
	`created_by` text NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `email_templates` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`category` text NOT NULL,
	`description` text,
	`owner_id` text NOT NULL,
	`language` text DEFAULT 'en' NOT NULL,
	`tags` text,
	`status` text NOT NULL,
	`published_version` integer,
	`archived_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `excel_imports` (
	`id` text PRIMARY KEY NOT NULL,
	`case_type` text NOT NULL,
	`filename` text NOT NULL,
	`sheet_name` text,
	`mapping` text NOT NULL,
	`summary` text NOT NULL,
	`status` text NOT NULL,
	`imported_by` text NOT NULL,
	`created_at` text NOT NULL,
	`completed_at` text
);
--> statement-breakpoint
CREATE TABLE `files` (
	`id` text PRIMARY KEY NOT NULL,
	`entity_type` text NOT NULL,
	`entity_id` text NOT NULL,
	`category` text NOT NULL,
	`filename` text NOT NULL,
	`storage_key` text NOT NULL,
	`content_type` text,
	`size` integer NOT NULL,
	`uploaded_by` text NOT NULL,
	`archived_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `files_entity_idx` ON `files` (`entity_type`,`entity_id`);--> statement-breakpoint
CREATE TABLE `labs` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`status` text DEFAULT 'Active' NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `persons` (
	`id` text PRIMARY KEY NOT NULL,
	`first_name` text NOT NULL,
	`last_name` text NOT NULL,
	`full_name` text NOT NULL,
	`email` text,
	`employee_id` text,
	`phone` text,
	`lab_id` text,
	`team_id` text,
	`manager_id` text,
	`archived_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `persons_team_idx` ON `persons` (`team_id`);--> statement-breakpoint
CREATE INDEX `persons_name_idx` ON `persons` (`full_name`);--> statement-breakpoint
CREATE TABLE `roles` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`permissions` text NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `roles_name_unique` ON `roles` (`name`);--> statement-breakpoint
CREATE TABLE `tasks` (
	`id` text PRIMARY KEY NOT NULL,
	`case_id` text NOT NULL,
	`checklist_item_id` text,
	`title` text NOT NULL,
	`task_type` text DEFAULT 'General' NOT NULL,
	`template_id` text,
	`owner_id` text NOT NULL,
	`due_date` text,
	`priority` text NOT NULL,
	`status` text NOT NULL,
	`completed_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `tasks_owner_status_idx` ON `tasks` (`owner_id`,`status`);--> statement-breakpoint
CREATE TABLE `teams` (
	`id` text PRIMARY KEY NOT NULL,
	`lab_id` text NOT NULL,
	`name` text NOT NULL,
	`status` text DEFAULT 'Active' NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `teams_lab_idx` ON `teams` (`lab_id`);--> statement-breakpoint
CREATE TABLE `template_variables` (
	`id` text PRIMARY KEY NOT NULL,
	`version_id` text NOT NULL,
	`key` text NOT NULL,
	`label` text NOT NULL,
	`type` text NOT NULL,
	`required` integer NOT NULL,
	`default_value` text,
	`source` text NOT NULL,
	`source_field` text,
	`editable_by_sender` integer NOT NULL,
	`placeholder` text,
	`options` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `variables_version_idx` ON `template_variables` (`version_id`);--> statement-breakpoint
CREATE TABLE `email_template_versions` (
	`id` text PRIMARY KEY NOT NULL,
	`template_id` text NOT NULL,
	`version` integer NOT NULL,
	`status` text NOT NULL,
	`subject` text NOT NULL,
	`body_html` text NOT NULL,
	`recipient_rules` text NOT NULL,
	`change_summary` text,
	`created_by` text NOT NULL,
	`published_at` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `template_version_unique` ON `email_template_versions` (`template_id`,`version`);--> statement-breakpoint
CREATE TABLE `user_scopes` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`scope_type` text NOT NULL,
	`scope_id` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `scope_user_idx` ON `user_scopes` (`user_id`);--> statement-breakpoint
CREATE TABLE `users` (
	`id` text PRIMARY KEY NOT NULL,
	`email` text NOT NULL,
	`name` text NOT NULL,
	`title` text,
	`phone` text,
	`signature_html` text,
	`role_id` text NOT NULL,
	`status` text DEFAULT 'Active' NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
CREATE INDEX `users_role_idx` ON `users` (`role_id`);