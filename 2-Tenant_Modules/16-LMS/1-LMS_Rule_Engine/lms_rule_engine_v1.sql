-- ==============================================================================================================
-- LMS Sub-Module - 1
-- LMS CONFIGURATION & RULE ENGINE
-- ==============================================================================================================

-- we need to create a table for trigger events
CREATE TABLE IF NOT EXISTS `lms_trigger_event` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`code` VARCHAR(50) NOT NULL UNIQUE,   -- e.g., 'ON_HOMEWORK_SUBMISSION', 'ON_HOMEWORK_OVERDUE', 'ON_QUIZ_COMPLETION'
	`name` VARCHAR(100) NOT NULL,         -- e.g., 'On Homework Submission', 'On Homework Overdue', 'On Quiz Completion'
	`description` TEXT DEFAULT NULL,
	`event_logic` JSON NOT NULL,          -- e.g., '{"event": "updated", "logic": "AUTO_ASSIGN_QUIZ"}'
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT NULL,
	`updated_at` TIMESTAMP NULL DEFAULT NULL,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lms_trigger_event (code, name, description, event_logic, is_active, created_at, updated_at, deleted_at) VALUES
('ON_HOMEWORK_SUBMISSION','On Homework Submission', 'On Homework Submission', '{"event": "updated", "logic": "assign_lesson_plan"}', 1, NOW(), NOW(), NULL),
('ON_HOMEWORK_OVERDUE','On Homework Overdue', 'On Homework Overdue', '{"event": "updated", "logic": "notify_parent"}', 1, NOW(), NOW(), NULL),
('ON_QUIZ_COMPLETION','On Quiz Completion', 'On Quiz Completion', '{"event": "updated", "logic": "assign_lesson_plan"}', 1, NOW(), NOW(), NULL);

-- This table will be used to define the actions that can be triggered by the rule engine
CREATE TABLE IF NOT EXISTS `lms_action_type` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`code` VARCHAR(50) NOT NULL UNIQUE,   -- e.g., 'AUTO_ASSIGN_QUIZ', 'AUTO_ASSIGN_REMEDIAL', 'NOTIFY_PARENT'
	`name` VARCHAR(100) NOT NULL,         -- e.g., 'Auto Assign Remedial', 'Notify Parent'
	`description` TEXT DEFAULT NULL,
	`action_logic` JSON NOT NULL,         -- e.g., '{"logic": "assign_lesson_plan"}'
	`required_parameters` JSON DEFAULT NULL, -- e.g., '{"student_id": "required", "lesson_plan_id": "required"}'
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP NULL DEFAULT NULL,
	`updated_at` TIMESTAMP NULL DEFAULT NULL,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lms_action_type (code, name, description, action_logic, is_active, created_at, updated_at, deleted_at) VALUES
('AUTO_ASSIGN_REMEDIAL','Auto Assign Remedial', 'Auto Assign Remedial', '{"logic": "assign_lesson_plan"}', 1, NOW(), NOW(), NULL),
('NOTIFY_PARENT','Notify Parent', 'Notify Parent', '{"logic": "notify_parent"}', 1, NOW(), NOW(), NULL);

-- This table will be used to define the rules that can be triggered by the rule engine
CREATE TABLE IF NOT EXISTS `lms_rule_engine_config` (
	`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`rule_code` VARCHAR(50) NOT NULL UNIQUE,       -- e.g., 'RETEST_POLICY_A', 'GRADING_STD_10'
	`rule_name` VARCHAR(100) NOT NULL,
	`description` TEXT DEFAULT NULL,
	`trigger_event_id` BIGINT UNSIGNED NOT NULL,   -- FK to lms_trigger_event.id (ON_HOMEWORK_SUBMISSION, ON_HOMEWORK_OVERDUE, ON_QUIZ_COMPLETION)
	`applicable_class_group_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sch_class_groups_jnt.id (Target Audience)
	`logic_config` JSON NOT NULL,                  -- The logic payload { "min_score": 33, "attempts": 2 }
	`action_type_id` BIGINT UNSIGNED NOT NULL,     -- FK to lms_action_type.id (AUTO_ASSIGN_REMEDIAL, NOTIFY_PARENT)
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,     -- 1 = Active, 0 = Inactive
	`created_at` TIMESTAMP NULL DEFAULT NULL,
	`updated_at` TIMESTAMP NULL DEFAULT NULL,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	CONSTRAINT `fk_lms_rule_engine_config_trigger_event_id` FOREIGN KEY (`trigger_event_id`) REFERENCES `sys_dropdown` (`id`),
	CONSTRAINT `fk_lms_rule_engine_config_applicable_class_group_id` FOREIGN KEY (`applicable_class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`),
	CONSTRAINT `fk_lms_rule_engine_config_action_type_id` FOREIGN KEY (`action_type_id`) REFERENCES `lms_action_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lms_rule_engine_config (rule_code, rule_name, description, trigger_event_id, applicable_class_group_id, logic_config, action_type_id, is_active, created_at, updated_at, deleted_at) VALUES
('QUIZ','Quiz', 'Quiz', 1, 1, '{"min_score": 33, "attempts": 2}', 1, 1, NOW(), NOW(), NULL),
('QUEST','Quest', 'Quest', 1, 1, '{"min_score": 33, "attempts": 2}', 1, 1, NOW(), NOW(), NULL),
('ONLINE_EXAM','Online Exam', 'Online Exam', 1, 1, '{"min_score": 33, "attempts": 2}', 1, 1, NOW(), NOW(), NULL),
('OFFLINE_EXAM','Offline Exam', 'Offline Exam', 1, 1, '{"min_score": 33, "attempts": 2}', 1, 1, NOW(), NOW(), NULL),
('UT_TEST','Unit Test', 'Unit Test', 1, 1, '{"min_score": 33, "attempts": 2}', 1, 1, NOW(), NOW(), NULL);
