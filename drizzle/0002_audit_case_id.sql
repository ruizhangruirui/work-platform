ALTER TABLE `audit_logs` ADD `case_id` text;--> statement-breakpoint
CREATE INDEX `audit_case_idx` ON `audit_logs` (`case_id`,`created_at`);--> statement-breakpoint
-- Backfill case_id for existing rows: case-entity rows use entity_id,
-- other rows (checklist/task audits) carry the case id in metadata.
UPDATE `audit_logs` SET `case_id` = `entity_id` WHERE `entity_type` = 'case' AND `case_id` IS NULL;--> statement-breakpoint
UPDATE `audit_logs` SET `case_id` = json_extract(`metadata`, '$.caseId') WHERE `case_id` IS NULL AND `metadata` IS NOT NULL AND json_extract(`metadata`, '$.caseId') IS NOT NULL;
