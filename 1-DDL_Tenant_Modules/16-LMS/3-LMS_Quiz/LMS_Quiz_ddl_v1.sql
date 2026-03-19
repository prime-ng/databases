-- =========================================================================
-- 1. CONFIGURATION & LOOKUP TABLES
-- =========================================================================

-- -------------------------------------------------------------------------------------------------------
-- Screen File name - LMS Master      Tab-1 (Name - Difficulty Distribution Configs)
-- -------------------------------------------------------------------------------------------------------

-- Difficulty Distribution Config Header
-- This will be used to Balance Difficulty Level of Quiz / Quest / Exam. 
-- This will define how many questions from different Complexity levels are required for a particular difficulty level.
CREATE TABLE IF NOT EXISTS `lms_difficulty_distribution_configs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,              -- e.g. 'STD_QUIZ_EASY', STD_QUIZ_Medium, STD_QUIZ_Hard, 'EXAM_BALANCED'
  `name` VARCHAR(100) NOT NULL,             -- e.g. 'Standard Quiz Easy'
  `description` VARCHAR(255) DEFAULT NULL,
  `usage_type_id` INT UNSIGNED NOT NULL, -- FK to qns_question_usage_type (e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM','UT_TEST')
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_diff_config_code` (`code`),
  CONSTRAINT `fk_diff_config_usage_type` FOREIGN KEY (`usage_type_id`) REFERENCES `qns_question_usage_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Difficulty Distribution Rules (Child Table of (lms_difficulty_distribution_configs)
CREATE TABLE IF NOT EXISTS `lms_difficulty_distribution_details` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `difficulty_config_id` INT UNSIGNED NOT NULL,     -- FK to lms_difficulty_distribution_configs.id
  `question_type_id` INT UNSIGNED NOT NULL,         -- FK to slb_question_types.id (e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER')
  `complexity_level_id` INT UNSIGNED NOT NULL,      -- FK to slb_complexity_level.id (e.g. 'EASY','MEDIUM','DIFFICULT')
  `min_percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Min % of total questions (e.g. 20.00)
  `max_percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Max % of total questions (e.g. 40.00)
  `marks_per_question` DECIMAL(5,2) DEFAULT NULL,     -- Optional override for marks (e.g. 1.00)
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_diff_det_config` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_diff_det_qtype` FOREIGN KEY (`question_type_id`) REFERENCES `slb_question_types` (`id`),
  CONSTRAINT `fk_diff_det_comp` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Screen File name - LMS Master      Tab-2 (Name - Quiz Types)
-- -------------------------------------------------------------------------------------------------------
-- Quiz Type (Assessment Type)
CREATE TABLE IF NOT EXISTS `lms_assessment_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,              -- (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
  `name` VARCHAR(100) NOT NULL,             -- (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
  `assessment_usage_type_id` INT UNSIGNED NOT NULL, -- FK to qns_question_usage_type.id (e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM','UT_TEST')
  `description` VARCHAR(255) DEFAULT NULL,  -- 
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_quiz_type_code` (`code`)
  CONSTRAINT `fk_quiz_type_usage_type` FOREIGN KEY (`assessment_usage_type_id`) REFERENCES `qns_question_usage_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =========================================================================
-- 2. QUIZ MODULE
-- =========================================================================

-- -------------------------------------------------------------------------------------------------------
-- Screen File name - Quiz Management      Tab-1 (Name - Quiz Creation)
-- -------------------------------------------------------------------------------------------------------
-- Main Quiz Master Table
CREATE TABLE IF NOT EXISTS `lms_quizzes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,                       -- Unique Identifier
  `quiz_code` VARCHAR(50) NOT NULL,                 -- Human readable code (e.g. 'QUIZ_7TH_SCI_EASY', 'QUIZ_7TH_SCI_BALANCED', 'QUIZ_7TH_SCI_DIFFICULT')
  `title` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `instructions` TEXT DEFAULT NULL,                 -- Supports HTML/Markdown/JSON/Latex
  `quiz_type_id` INT UNSIGNED NOT NULL,          -- FK to lms_assessment_types.id (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
  `scope_topic_id` INT UNSIGNED DEFAULT NULL,    -- FK to slb_topics.id (Primary Scope) (if selected topic is Sub-Topic then all the Mini-Topic/Micro-Topic comes under it will be included)
  `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT',    -- DRAFT, PUBLISHED, ARCHIVED
  -- Settings
  `duration_minutes` TINYINT UNSIGNED DEFAULT NULL,     -- NULL = Unlimited
  `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,
  `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 33.00,
  `allow_multiple_attempts` TINYINT(1) NOT NULL DEFAULT 0,
  `max_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `negative_marks` DECIMAL(4,2) NOT NULL DEFAULT 0.00, -- e.g. 0.25  (If Negative Marking Factor is zero then no negative marks will be given)
  `is_randomized` TINYINT(1) NOT NULL DEFAULT 0,    -- Randomize Question Order
  `question_marks_shown` TINYINT(1) NOT NULL DEFAULT 0, -- Show Question Marks (If this will be 1 then Question Marks will be shown when attempt to the quiz)
  `show_result_immediately` TINYINT(1) NOT NULL DEFAULT 0,  -- Show Result Immediately (Student will get the result immediately after submitting the quiz)
  `auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0,  -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
  `timer_enforced` TINYINT(1) NOT NULL DEFAULT 1,  -- Enforce Timer (If Timer is enforced then timer will be shown)
  `show_correct_answer` TINYINT(1) NOT NULL DEFAULT 0, -- Show Correct Answer (If this will be 1 then Correct Answer will be shown when attempt to the quiz)
  `show_explanation` TINYINT(1) NOT NULL DEFAULT 0, -- Show Explanation (If this will be 1 then Explanation will be shown when attempt to the quiz)
  -- Difficulty & Generation
  `difficulty_config_id` INT UNSIGNED DEFAULT NULL, -- FK to lms_difficulty_distribution_configs
  `ignore_difficulty_config` TINYINT(1) NOT NULL DEFAULT 0, -- Ignore Difficulty Config (If this will be 1 then difficulty_config_id will be ignored)
  `is_system_generated` TINYINT(1) NOT NULL DEFAULT 0, -- System Generated (If this will be 1 then quiz will be generated by system)
  -- Audit
  `created_by` INT UNSIGNED DEFAULT NULL,        -- FK to sys_users.id (Teacher/Admin), Null if created by System
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_quiz_uuid` (`uuid`),
  UNIQUE KEY `uq_quiz_code` (`quiz_code`),
  KEY `idx_quiz_topic` (`scope_topic_id`),
  KEY `idx_quiz_status` (`status`),
  CONSTRAINT `fk_quiz_type` FOREIGN KEY (`quiz_type_id`) REFERENCES `lms_assessment_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_diff_config` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_topic` FOREIGN KEY (`scope_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Parameter in Setting ""
-- -------------------------------------------------------------------------------------------------------
-- Screen File name - Quiz Management      Tab-2 (Name - Add Questions to Quiz)
-- -------------------------------------------------------------------------------------------------------
-- Quiz Questions (Junction)
CREATE TABLE IF NOT EXISTS `lms_quiz_questions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quiz_id` INT UNSIGNED NOT NULL,               -- FK to lms_quizzes.id
  `question_id` INT UNSIGNED NOT NULL,           -- FK to qns_questions_bank.id
  `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,        -- Sequence Order
  `marks_override` DECIMAL(5,2) DEFAULT NULL,       -- If different from question default marks
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_quiz_ques` (`quiz_id`, `question_id`),
  CONSTRAINT `fk_qq_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Screen File name - Quiz Management      Tab-3 (Name - Assign Quiz to Students)
-- -------------------------------------------------------------------------------------------------------
-- Quiz Allocation (Assignment)
CREATE TABLE IF NOT EXISTS `lms_quiz_allocations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quiz_id` INT UNSIGNED NOT NULL,
  `allocation_type` ENUM('CLASS','SECTION','GROUP','STUDENT') NOT NULL,
  `target_table_name` VARCHAR(60) NOT NULL,        -- Name of the target table (e.g. 'sch_classes', 'sch_sections', 'sch_entity_groups', 'std_students')
  `target_id` INT UNSIGNED NOT NULL,             -- ID of Class, Section, Group, or Student (e.g. sch_classes.id, sch_sections.id, sch_entity_groups.id, std_students.id)
  `assigned_by` INT UNSIGNED DEFAULT NULL,       -- FK to sys_users.id (Who assigned the quest). Null if assigned by System
  -- Timing
  `published_at` DATETIME DEFAULT NULL,             -- Visible from
  `due_date` DATETIME DEFAULT NULL,                 -- Due by
  `cut_off_date` DATETIME DEFAULT NULL,             -- No submissions after
  `is_auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0, -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
  `result_publish_date` DATETIME DEFAULT NULL,      -- Results visible from
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quiz_alloc_target` (`allocation_type`, `target_id`),
  CONSTRAINT `fk_qa_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qa_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- Foriegn Key Constraints for target_id needs to be maintained at Application Level as the target table names are dynamic.
-- `is_auto_publish_result` in this table will overwrite `auto_publish_result` in `lms_quizzes` table to have different auto publish result settings for different allocations.

