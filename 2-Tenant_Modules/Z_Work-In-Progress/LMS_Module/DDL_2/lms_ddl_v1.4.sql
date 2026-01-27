-- /********************************************************************
--  PRIMEGURUKUL – SCHOOL ERP
--  LMS MODULE – INDUSTRIALIZED DATABASE DDL (v1.3)
--  Platform: MySQL 8.x | Framework: Laravel 11.x
--  Architecture: Multi-Tenant | Soft Deletes | Audit Ready
--  
--  INTEGRATION NOTE:
--  This DDL integrates with "Question_Bank_ddl_v1.1.sql".
--  It DOES NOT recreate `qns_questions_bank` but references it.
-- ********************************************************************/

SET sql_mode = 'STRICT_ALL_TABLES';

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
    `submission_text` LONGTEXT DEFAULT NULL,              -- Student Submission Text
    `attachment_media_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sys_media (Handwritten scan)
    -- Evaluation
    `status_id` BIGINT UNSIGNED NOT NULL,                 -- FK to sys_dropdown_table (SUBMITTED, CHECKED, REJECTED)    
    `marks_obtained` DECIMAL(5,2) DEFAULT NULL,          -- Obtained Marks
    `teacher_feedback` TEXT DEFAULT NULL,                 -- Teacher Feedback
    `graded_by` BIGINT UNSIGNED DEFAULT NULL,             -- Graded By
    `graded_at` DATETIME DEFAULT NULL,                    -- Graded At
    `is_late` TINYINT(1) DEFAULT 0,                      -- Is Late
    -- Metadata
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hw_sub` (`homework_id`, `student_id`),
    CONSTRAINT `fk_hws_hw` FOREIGN KEY (`homework_id`) REFERENCES `lms_homework` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 3. UNIFIED ASSESSMENT ENGINE (Modules 3, 4, 5, 6)
-- Covers: Quiz, Quest, Online Exam, Offline Exam
-- ==============================================================================================================

CREATE TABLE IF NOT EXISTS `lms_assessments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` BIGINT UNSIGNED NOT NULL,
    -- Type Definition
    `category_id` BIGINT UNSIGNED NOT NULL,               -- FK to sys_dropdown_table (QUIZ, QUEST, EXAM, OLYMPIAD)
    `mode_id` BIGINT UNSIGNED NOT NULL,                   -- FK to sys_dropdown_table (ONLINE, OFFLINE, HYBRID)
    `title` VARCHAR(255) NOT NULL,
    `instructions` LONGTEXT DEFAULT NULL,                 -- Instructions   
    -- Audience
    `class_id` INT UNSIGNED NOT NULL,
    `subject_id` BIGINT UNSIGNED NOT NULL,
    `entity_group_id` BIGINT UNSIGNED DEFAULT NULL,       -- For specific group targeting
    -- Constraints
    `total_marks` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 33.00,
    `time_limit_minutes` INT UNSIGNED DEFAULT NULL,       -- NULL = No Limit
    `allowed_attempts` TINYINT UNSIGNED DEFAULT 1,
    -- Scheduling
    `start_datetime` DATETIME DEFAULT NULL,               -- Window Start
    `end_datetime` DATETIME DEFAULT NULL,                 -- Window End
    `result_publish_datetime` DATETIME DEFAULT NULL,      -- Scheduled Result
    -- Quest Specific (Rubrics)
    `use_rubrics` TINYINT(1) DEFAULT 0,                   -- If 1, use lms_assessment_rubrics
    -- Exam Specific (Security)
    `is_proctored` TINYINT(1) DEFAULT 0,
    `fullscreen_required` TINYINT(1) DEFAULT 0,
    `browser_lock_required` TINYINT(1) DEFAULT 0,
    -- Offline Exam Specific
    `offline_paper_media_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_media (The PDF of key paper)
    `status_id` BIGINT UNSIGNED NOT NULL,                 -- FK (DRAFT, SCHEDULED, LIVE, COMPLETED)
    `is_active` TINYINT(1) DEFAULT 1,
    `created_by` BIGINT UNSIGNED NOT NULL,
    `updated_by` BIGINT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_assess_lookup` (`class_id`, `subject_id`, `category_id`),
    CONSTRAINT `fk_assess_cls` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_assess_sub` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.1 Mapping Questions to Assessments (From Question Bank)
CREATE TABLE IF NOT EXISTS `lms_assessment_questions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assessment_id` BIGINT UNSIGNED NOT NULL,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,          -- FK to qns_questions_bank (Existing Module)
    `section_name` VARCHAR(100) DEFAULT 'Section A',    -- Grouping
    `display_order` INT UNSIGNED NOT NULL DEFAULT 0,
    `marks_override` DECIMAL(5,2) DEFAULT NULL,           -- If different from QB default
    `negative_marks_override` DECIMAL(5,2) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_assess_q` (`assessment_id`, `question_bank_id`),
    CONSTRAINT `fk_aq_assess` FOREIGN KEY (`assessment_id`) REFERENCES `lms_assessments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_aq_qb` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2 Rubrics for Subjective Evaluation (Quest/Descriptive)
CREATE TABLE IF NOT EXISTS `lms_assessment_rubrics` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assessment_id` BIGINT UNSIGNED NOT NULL,
    `criteria_title` VARCHAR(255) NOT NULL,               -- e.g. "Clarity of Thought"
    `max_points` DECIMAL(5,2) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `ordinal` TINYINT UNSIGNED DEFAULT 1,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_rubric_assess` FOREIGN KEY (`assessment_id`) REFERENCES `lms_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 4. EXECUTION & ATTEMPTS (Modules 3, 4, 5, 6, 7, 8)
-- ==============================================================================================================

CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assessment_id` BIGINT UNSIGNED NOT NULL,
    `student_id` BIGINT UNSIGNED NOT NULL,
    `attempt_number` TINYINT UNSIGNED DEFAULT 1,
    `started_at` DATETIME NOT NULL,
    `finished_at` DATETIME DEFAULT NULL,
    `duration_seconds` INT UNSIGNED DEFAULT 0,
    `status_id` BIGINT UNSIGNED NOT NULL,                 -- FK (IN_PROGRESS, SUBMITTED, EVALUATED, DISQUALIFIED)
    -- Scoring
    `total_score_obtained` DECIMAL(6,2) DEFAULT 0.00,
    `percentage` DECIMAL(5,2) DEFAULT 0.00,
    `grade_obtained` VARCHAR(5) DEFAULT NULL,
    `is_passed` TINYINT(1) DEFAULT 0,
    -- Security Logs
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `browser_agent` TEXT DEFAULT NULL,
    `tab_switch_count` INT UNSIGNED DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_atm_assess` FOREIGN KEY (`assessment_id`) REFERENCES `lms_assessments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_atm_stu` FOREIGN KEY (`student_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_attempt_responses` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` BIGINT UNSIGNED NOT NULL,
    `question_bank_id` BIGINT UNSIGNED NOT NULL,          -- FK to qns_questions_bank
    -- User Input
    `selected_option_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to qns_question_options (MCQ)
    `text_answer` LONGTEXT DEFAULT NULL,                  -- Descriptive
    `attachment_media_id` BIGINT UNSIGNED DEFAULT NULL,   -- File Upload
    -- Evaluation
    `is_correct` TINYINT(1) DEFAULT NULL,                 -- Auto-eval or Teacher-eval
    `marks_awarded` DECIMAL(5,2) DEFAULT 0.00,
    `evaluator_remarks` TEXT DEFAULT NULL,                -- Teacher Feedback on specific answer
    -- Telemetry
    `time_spent_seconds` INT UNSIGNED DEFAULT 0,
    `revised_count` TINYINT UNSIGNED DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_atm_resp` (`attempt_id`, `question_bank_id`),
    CONSTRAINT `fk_ar_atm` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ar_qb` FOREIGN KEY (`question_bank_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 5. ANALYTICS, NEP & INSIGHTS (Modules 10, 11, 13)
-- ==============================================================================================================

-- 5.1 Student Competency Mastery (NEP)
CREATE TABLE IF NOT EXISTS `lms_student_competency_mastery` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT UNSIGNED NOT NULL,
    `competency_id` BIGINT UNSIGNED NOT NULL,             -- FK to slb_competencies (from Syllabus Module)
    `current_score_avg` DECIMAL(5,2) NOT NULL,            -- Running average
    `mastery_level_id` BIGINT UNSIGNED NOT NULL,          -- FK (NOVICE, COMPETENT, EXPERT)
    `last_assessed_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_comp_mast` (`student_id`, `competency_id`),
    CONSTRAINT `fk_scm_stu` FOREIGN KEY (`student_id`) REFERENCES `sys_users` (`id`)
    -- CONSTRAINT `fk_scm_comp` ... (linked to syllabus module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.2 AI Insights & Predictions
CREATE TABLE IF NOT EXISTS `lms_ai_insights` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT UNSIGNED NOT NULL,
    `insight_type_id` BIGINT UNSIGNED NOT NULL,           -- FK (RISK_ALERT, CAREER_SUGGESTION, LEARNING_GAP)
    `insight_data` JSON NOT NULL,                         -- { "risk_probability": 0.85, "weak_topics": [1,2,5] }
    `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_dismissed` TINYINT(1) DEFAULT 0,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_ai_stu` FOREIGN KEY (`student_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 6. CONTENT GOVERNANCE & TEMPLATES (Modules 12, 14)
-- ==============================================================================================================

CREATE TABLE IF NOT EXISTS `lms_report_templates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `template_name` VARCHAR(100) NOT NULL,                -- e.g. "CBSE Term 1 Report Card"
    `template_code` VARCHAR(50) NOT NULL UNIQUE,
    `structure_json` JSON NOT NULL,                       -- Layout configuration
    `is_default` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 7. SEED DATA (System Dropdowns)
-- ==============================================================================================================

-- We verify needs existence first
INSERT INTO `sys_dropdown_needs` (`db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `field_name`, `is_system`, `compulsory`) VALUES
('Tenant', 'lms_assessments', 'category_id', 'LMS', 'Assessments', 'Assessment Category', 1, 1),
('Tenant', 'lms_assessments', 'mode_id', 'LMS', 'Assessments', 'Assessment Mode', 1, 1),
('Tenant', 'lms_homework', 'submission_type_id', 'LMS', 'Homework', 'Submission Type', 1, 1),
('Tenant', 'lms_ai_insights', 'insight_type_id', 'LMS', 'Analytics', 'Insight Type', 1, 1)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- 7.1 Assessment Categories
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'QUIZ', 'Quiz', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'category_id'
UNION ALL SELECT id, 2, 'QUEST', 'Quest (Learning)', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'category_id'
UNION ALL SELECT id, 3, 'EXAM', 'Examination', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'category_id'
UNION ALL SELECT id, 4, 'OLYMPIAD', 'Olympiad', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'category_id';

-- 7.2 Assessment Modes
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'ONLINE', 'Online', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'mode_id'
UNION ALL SELECT id, 2, 'OFFLINE', 'Offline (Paper)', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'mode_id'
UNION ALL SELECT id, 3, 'HYBRID', 'Hybrid', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'mode_id';

-- 7.3 Submission Types
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'TEXT', 'Text Entry', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_type_id'
UNION ALL SELECT id, 2, 'FILE', 'File Upload', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_type_id'
UNION ALL SELECT id, 3, 'HYBRID', 'Hybrid (Text+File)', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_type_id'
UNION ALL SELECT id, 4, 'OFFLINE', 'Offline Submission', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_type_id';

-- 7.4 Insight Types
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'RISK_ALERT', 'At-Risk Alert', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'insight_type_id'
UNION ALL SELECT id, 2, 'CAREER_SUGGESTION', 'Career Path Suggestion', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'insight_type_id'
UNION ALL SELECT id, 3, 'LEARNING_GAP', 'Learning Gap Identified', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'insight_type_id';

