-- =========================================================================
-- LMS QUIZ & QUEST MODULE DDL v1.0
-- Technologies: MySQL 8.x, Laravel 10.x
-- Dependencies: qns_questions_bank, slb_topics, sys_users, sch_students
-- =========================================================================


-- =========================================================================
-- 3. QUEST MODULE
-- =========================================================================

-- Main Quest Table
CREATE TABLE IF NOT EXISTS `lms_quests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `quest_code` VARCHAR(50) NOT NULL,  -- Auto Generated (e.g. 'QUEST_7TH_SCI_EASY', 'QUEST_7TH_SCI_BALANCED', 'QUEST_7TH_SCI_DIFFICULT')
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `instructions` TEXT DEFAULT NULL,
  `quest_type_id` BIGINT UNSIGNED NOT NULL,          -- FK to lms_assessment_types.id (e.g. 'Challenge', 'Enrichment', 'Practice', 'Revision', 'Re-Test', 'Diagnostic', 'Remedial')
  `scope_topic_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to slb_topics.id (Primary Scope) (if selected topic is Sub-Topic then all the Mini-Topic/Micro-Topic comes under it will be included)
  `quest_type_id` BIGINT UNSIGNED NOT NULL,         -- FK to sys_dropdowns
  `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  -- Settings
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,
  `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 33.00,
  `allow_multiple_attempts` TINYINT(1) NOT NULL DEFAULT 0,
  `max_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `is_randomized` TINYINT(1) NOT NULL DEFAULT 0,
  `difficulty_config_id` BIGINT UNSIGNED DEFAULT NULL,
  `is_system_generated` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_quest_uuid` (`uuid`),
  UNIQUE KEY `uq_quest_code` (`quest_code`),
  CONSTRAINT `fk_quest_diff` FOREIGN KEY (`difficulty_config_id`) REFERENCES `lms_difficulty_distribution_configs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quest_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Quest Scopes (Topics covered)
CREATE TABLE IF NOT EXISTS `lms_quest_scopes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quest_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,              -- FK to slb_topics.id
  `question_type_id` INT UNSIGNED DEFAULT NULL,     -- Optional filter
  `target_question_count` INT UNSIGNED DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_qs_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qs_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Quest Questions (Junction)
CREATE TABLE IF NOT EXISTS `lms_quest_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quest_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,
  `marks_override` DECIMAL(5,2) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_quest_ques` (`quest_id`, `question_id`),
  CONSTRAINT `fk_qst_q_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qst_q_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Quest Allocations
CREATE TABLE IF NOT EXISTS `lms_quest_allocations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quest_id` BIGINT UNSIGNED NOT NULL,
  `allocation_type` ENUM('CLASS','SECTION','GROUP','STUDENT') NOT NULL,
  `target_id` BIGINT UNSIGNED NOT NULL,
  `assigned_by` BIGINT UNSIGNED DEFAULT NULL,
  `published_at` DATETIME DEFAULT NULL,
  `due_date` DATETIME DEFAULT NULL,
  `result_publish_date` DATETIME DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quest_alloc_target` (`allocation_type`, `target_id`),
  CONSTRAINT `fk_qsta_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qsta_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 4. STUDENT ATTEMPTS & RESULTS (Unified for Quiz & Quest)
-- =========================================================================

-- Student Attempts
CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_students.id
  `assessment_type` ENUM('QUIZ','QUEST') NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,         -- ID from lms_quizzes or lms_quests
  `allocation_id` BIGINT UNSIGNED DEFAULT NULL,     -- Optional link to allocation
  `attempt_number` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` DATETIME DEFAULT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, SUBMITTED, TIMEOUT, ABANDONED
  `total_score` DECIMAL(8,2) DEFAULT NULL,
  `percentage` DECIMAL(5,2) DEFAULT NULL,
  `is_passed` TINYINT(1) DEFAULT 0,
  `teacher_feedback` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  KEY `idx_att_student` (`student_id`),
  KEY `idx_att_assessment` (`assessment_type`, `assessment_id`)
  -- Note: Cannot enforce FK on assessment_id alone due to polymorphism
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Attempt Answers
CREATE TABLE IF NOT EXISTS `lms_student_attempt_answers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,           -- FK to qns_questions_bank.id
  `selected_option_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to qns_question_options.id (For MCQ)
  `answer_text` TEXT DEFAULT NULL,                  -- For Descriptive/Fill-in
  `marks_obtained` DECIMAL(5,2) DEFAULT 0.00,
  `is_correct` TINYINT(1) DEFAULT NULL,             -- NULL = Not Graded, 0=Incorrect, 1=Correct
  `time_taken_seconds` INT UNSIGNED DEFAULT 0,      -- Telemetry
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ans_option` FOREIGN KEY (`selected_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 5. SEED DATA
-- =========================================================================

-- Seed Dropdown Needs
INSERT INTO `sys_dropdown_needs` 
(`db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `sub_menu`, `field_name`, `is_system`, `tenant_creation_allowed`) 
VALUES 
('Tenant', 'lms_quizzes', 'quiz_type_id', 'LMS', 'Quiz Management', 'Quiz Setup', 'Quiz Type', 1, 1),
('Tenant', 'lms_quests', 'quest_type_id', 'LMS', 'Quest Management', 'Quest Setup', 'Quest Type', 1, 1);

-- Get IDs for insertion (Assuming standard flow, but using subqueries for safety in script if possible or placeholder)
-- Since we can't use variables easily in a single script without procedure, we assume usage of IDs 1001, 1002 for the example or just Insert Values.
-- Note: In a real migration, we fetch IDs. Here we provide INSERT statements for `sys_dropdown_table`.

-- Quiz Types
SET @need_id_quiz = (SELECT id FROM sys_dropdown_needs WHERE table_name = 'lms_quizzes' AND column_name = 'quiz_type_id' LIMIT 1);
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `is_active`) VALUES
(@need_id_quiz, 1, 'FORMATIVE', 'Formative Assessment', 1),
(@need_id_quiz, 2, 'SUMMATIVE', 'Summative Assessment', 1),
(@need_id_quiz, 3, 'DIAGNOSTIC', 'Diagnostic Assessment', 1),
(@need_id_quiz, 4, 'PRACTICE', 'Practice Quiz', 1);

-- Quest Types
SET @need_id_quest = (SELECT id FROM sys_dropdown_needs WHERE table_name = 'lms_quests' AND column_name = 'quest_type_id' LIMIT 1);
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `is_active`) VALUES
(@need_id_quest, 1, 'LEARNING_PATH', 'Learning Path Quest', 1),
(@need_id_quest, 2, 'PROJECT_BASED', 'Project Based Quest', 1),
(@need_id_quest, 3, 'MASTER_CHALLENGE', 'Mastery Challenge', 1);

-- Sample Difficulty Config
INSERT INTO `lms_difficulty_distribution_configs` (`code`, `name`, `used_for`, `description`) VALUES
('STD_BALANCED_QUIZ', 'Standard Balanced Quiz', 'QUIZ', '30% Easy, 50% Medium, 20% Hard');
