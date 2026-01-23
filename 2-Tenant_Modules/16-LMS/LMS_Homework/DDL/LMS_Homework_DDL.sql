-- ==============================================================================================================
-- 1. LMS CONFIGURATION & RULE ENGINE (Module 9)
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


-- ==============================================================================================================
-- 2. HOMEWORK & ASSIGNMENTS (Module 1)
-- ==============================================================================================================

CREATE TABLE IF NOT EXISTS `lms_homework` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` BIGINT UNSIGNED NOT NULL,       -- FK to sch_academic_sessions.id
    `class_id` INT UNSIGNED NOT NULL,                     -- FK to sch_classes.id
    `section_id` INT UNSIGNED DEFAULT NULL,               -- FK to sch_sections.id (Null = All Sections)
    `subject_id` BIGINT UNSIGNED NOT NULL,                -- FK to sch_subjects.id
    -- Content Alignment
    `topic_id` BIGINT UNSIGNED DEFAULT NULL,              -- FK to slb_topics.id (Null = All Topics) It can be anything like Topic/Sub-Topic/Mini-Topic/Micro-Topic etc.
    `title` VARCHAR(255) NOT NULL,
    `description` LONGTEXT NOT NULL,                      -- Supports HTML/Markdown
    `submission_type_id` BIGINT UNSIGNED NOT NULL,        -- FK to sys_dropdown_table.id (TEXT, FILE, HYBRID, OFFLINE_CHECK)
    -- Settings
    `is_gradable` TINYINT(1) NOT NULL DEFAULT 1,          -- 1 = Gradable, 0 = Not Gradable
    `max_marks` DECIMAL(5,2) DEFAULT NULL,                -- Maximum Marks
    `passing_marks` DECIMAL(5,2) DEFAULT NULL,            -- Passing Marks
    `difficulty_level_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to slb_complexity_level.id (EASY, MEDIUM, HARD)
    -- Scheduling
    `assign_date` DATETIME NOT NULL,
    `due_date` DATETIME NOT NULL,
    `allow_late_submission` TINYINT(1) DEFAULT 0,         -- 1 = Allow Late Submission, 0 = Not Allow Late Submission
    `auto_publish_score` TINYINT(1) DEFAULT 0,            -- 1 = Auto Publish Score, 0 = Not Auto Publish Score
    -- Auto-Release Logic
    `release_condition_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown.id (IMMEDIATE, ON_TOPIC_COMPLETE)    
    `status_id` BIGINT UNSIGNED NOT NULL,                 -- FK to sys_dropdown.id (DRAFT, PUBLISHED, ARCHIVED)
    `is_active` TINYINT(1) DEFAULT 1,
    `created_by` BIGINT UNSIGNED NOT NULL,
    `updated_by` BIGINT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,    
    PRIMARY KEY (`id`),
    INDEX `idx_hw_class_sub` (`class_id`, `subject_id`),
    CONSTRAINT `fk_hw_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_hw_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_hw_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
    CONSTRAINT `fk_hw_sub_topic` FOREIGN KEY (`sub_topic_id`) REFERENCES `slb_sub_topics` (`id`),
    CONSTRAINT `fk_hw_submission_type` FOREIGN KEY (`submission_type_id`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_hw_difficulty_level` FOREIGN KEY (`difficulty_level_id`) REFERENCES `slb_complexity_level` (`id`),
    CONSTRAINT `fk_hw_release_condition` FOREIGN KEY (`release_condition_id`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_hw_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table` (`id`),
    CONSTRAINT `fk_hw_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_hw_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
-- If `allow_late_submission` = 0, then Student can not submit Homework online after `due_date`. He need to submit directly to the Teacher. OR teacher can allow to submit after due_date.
-- If `allow_late_submission` = 1, then Student can submit Homework online after `due_date` also



-- Create Data seed
INSERT INTO  lms_homework (academic_session_id, class_id, section_id, subject_id, topic_id, title, description, submission_type_id, is_gradable, max_marks, passing_marks, difficulty_level_id, assign_date, due_date, allow_late_submission, auto_publish_score, release_condition_id, status_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) VALUES 
(1, 1, NULL, 1, NULL, 'Homework 1', 'Description of Homework 1', 1, 1, 100, 50, 1, '2023-01-01 00:00:00', '2023-01-01 23:59:59', 0, 1, 1, 1, 1, 1, 1, NOW(), NOW(), NULL),
(1, 1, NULL, 1, NULL, 'Homework 2', 'Description of Homework 2', 1, 1, 100, 50, 1, '2023-01-01 00:00:00', '2023-01-01 23:59:59', 0, 1, 1, 1, 1, 1, 1, NOW(), NOW(), NULL);




-- 2.1 Homework Submissions
CREATE TABLE IF NOT EXISTS `lms_homework_submissions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `homework_id` BIGINT UNSIGNED NOT NULL,
    `student_id` BIGINT UNSIGNED NOT NULL,                -- FK to sys_users (Student)
    
    `submitted_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `submission_text` LONGTEXT DEFAULT NULL,
    `attachment_media_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sys_media (Handwritten scan)
    
    -- Evaluation
    `status_id` BIGINT UNSIGNED NOT NULL,                 -- FK to sys_dropdown_table (SUBMITTED, CHECKED, REJECTED)
    `marks_obtained` DECIMAL(5,2) DEFAULT NULL,
    `teacher_feedback` TEXT DEFAULT NULL,
    `graded_by` BIGINT UNSIGNED DEFAULT NULL,
    `graded_at` DATETIME DEFAULT NULL,
    
    `is_late` TINYINT(1) DEFAULT 0,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hw_sub` (`homework_id`, `student_id`),
    CONSTRAINT `fk_hws_hw` FOREIGN KEY (`homework_id`) REFERENCES `lms_homework` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


