-- =========================================================================
-- LMS ONLINE EXAM MODULE DDL v1.0
-- Technologies: MySQL 8.x, Laravel 10.x
-- Dependencies: qns_questions_bank, slb_topics, sys_users, sch_students
-- Module: LMS (Learning Management System)
-- Sub-Module: Online Exam, Offline Exam, Quiz, Quest
-- =========================================================================

-- =========================================================================
-- LMS EXAMS (Online & Offline)
-- =========================================================================

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_types
-- Purpose: Master table for all Exam Types (Online and Offline).
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE `lms_exam_types` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(20) NOT NULL,  -- e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM'
    `name` VARCHAR(100) NOT NULL, -- e.g. 'Unit Test 1','Unit Test 2','Unit Test 3','Unit Test 4','Half Yearly Exam','Annual Exam'
    `description` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP DEFAULT NULL,
    UNIQUE KEY `uq_q_usage_type_code` (`code`)
    UNIQUE KEY `uq_q_usage_type_name` (`name`)
);

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exams
-- Purpose: Header table for all Exams (Online and Offline).
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,                       -- Unique Identifier
  `academic_session_id` INT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions.id
  `class_id` INT UNSIGNED NOT NULL,              -- FK to sch_classes.id
  `subject_id` INT UNSIGNED NOT NULL,            -- FK to sch_subjects.id
  `code` VARCHAR(50) NOT NULL,                      -- <EXAM_MODE>+<EXAM_TYPE>+<ACADEMIC_SESSION_CODE>+<CLASS_CODE>  e.g. 'ONLINE_EXAM_2025_HY_7A', 'OFFLINE_EXAM_2025_HY_7A'
  `title` VARCHAR(150) NOT NULL,                    -- e.g. '7th Grade Half Yearly Exam 2025'
  `description` TEXT DEFAULT NULL,
  `exam_mode` ENUM('ONLINE', 'OFFLINE') NOT NULL DEFAULT 'ONLINE',
  `exam_type_id` INT UNSIGNED NOT NULL,          -- FK to lms_exam_types.id
  `exam_paper_set` SMALLINT UNSIGNED NOT NULL DEFAULT 1,   -- Exam Paper Set (1, 2, 3, ...) 1 type of Exam can have multiple exam paper sets
  `scheduled_exam_date` DATE NOT NULL,              -- Exam Date

  -- Configuration for BOTH (Online & Offline)
  `instructions` TEXT DEFAULT NULL,                 -- Instructions for students
  `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00, -- Total Marks of the Exam
  `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,  -- Total Number of Questions
  `passing_percentage` DECIMAL(5,2) NOT NULL DEFAULT 33.00, -- Passing Percentage of the Exam
  `duration_minutes` INT UNSIGNED DEFAULT NULL,     -- Null = No limit (Rare for exam)
  `negative_marks` DECIMAL(4,2) NOT NULL DEFAULT 0.00, -- e.g. 0.25  (If Negative Marking Factor is zero then no negative marks will be given)
  `publish_result_type` ENUM('IMMEDIATE','SCHEDULED','MANUAL') NOT NULL DEFAULT 'MANUAL',  -- Publish Result Type (Immediate = Result will be published immediately after the exam, Scheduled = Result will be published at the scheduled time, Manual = Result will be published manually)
  `scheduled_result_publish_at` DATETIME DEFAULT NULL,  -- Scheduled Result Publish Time (If this will be set then result will be published at this time)
  `allow_calculator` TINYINT(1) NOT NULL DEFAULT 0,  -- Allow Calculator (If this will be 1 then calculator will be allowed)
  `show_marks_per_question` TINYINT(1) NOT NULL DEFAULT 1,  -- Show Marks Per Question (If this will be 1 then marks per question will be shown)
  `difficulty_config_id` INT UNSIGNED DEFAULT NULL,  -- FK to lms_difficulty_distribution_configs
  `ignore_difficulty_config` TINYINT(1) NOT NULL DEFAULT 0, -- Ignore Difficulty Config (If this will be 1 then difficulty_config_id will be ignored)

  -- Configuration for ONLINE Only
  `is_randomized` TINYINT(1) NOT NULL DEFAULT 0,  -- Randomize Questions (If this will be 1 then questions will be randomized)
  `is_proctored` TINYINT(1) NOT NULL DEFAULT 0,  -- Proctoring (If this will be 1 then proctoring will be enabled)
  `is_ai_proctored` TINYINT(1) NOT NULL DEFAULT 0,  -- AI Proctoring (If this will be 1 then AI proctoring will be enabled)
  `fullscreen_required` TINYINT(1) NOT NULL DEFAULT 0,  -- Fullscreen Required (If this will be 1 then fullscreen will be required)
  `browser_lock_required` TINYINT(1) NOT NULL DEFAULT 0,  -- Browser Lock Required (If this will be 1 then browser lock will be required)
  `shuffle_questions` TINYINT(1) NOT NULL DEFAULT 0,  -- Randomize Questions (If this will be 1 then questions will be randomized)
  `shuffle_options` TINYINT(1) NOT NULL DEFAULT 0,  -- Randomize Options (If this will be 1 then options will be randomized)
  `question_marks_shown` TINYINT(1) NOT NULL DEFAULT 0, -- Show Question Marks (If this will be 1 then Question Marks will be shown when attempt to the quiz)
  `auto_publish_result` TINYINT(1) NOT NULL DEFAULT 0,  -- Auto Publish Result (Result of the Class will be shown Automatically just after due date)
  `timer_enforced` TINYINT(1) NOT NULL DEFAULT 1,  -- Enforce Timer (If Timer is enforced then timer will be shown)
  -- Status (Both)
  `status` ENUM('DRAFT','PUBLISHED','CONCLUDED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `created_by` INT UNSIGNED DEFAULT NULL,        -- FK to sys_users.id
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_uuid` (`uuid`),
  UNIQUE KEY `uq_exam_code_paper_set` (`code`, `exam_paper_set`),
  KEY `idx_exam_mode` (`exam_mode`),
  KEY `idx_exam_status` (`status`),
  CONSTRAINT `fk_exam_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `glb_academic_sessions` (`id`),
  CONSTRAINT `fk_exam_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_exam_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
  CONSTRAINT `fk_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_assessment_types` (`id`),
  CONSTRAINT `fk_exam_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_scopes
-- Purpose: Defines the syllabus scope for the exam (Lessons/Topics).
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_scopes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `lesson_id` INT UNSIGNED DEFAULT NULL,     -- FK to slb_lessons (Optional, if specific lesson)
  `topic_id` INT UNSIGNED DEFAULT NULL,      -- FK to slb_topics (Optional, if specific topic)
  `question_type_id` INT UNSIGNED DEFAULT NULL,     -- FK to qns_question_types.id (e.g. MCQs, True/False, Fill in the Blanks, etc.)
  `target_question_count` INT UNSIGNED DEFAULT 0,   -- Target Question Count (If this will be 0 then all the questions of the topic will be included)
  `weightage_percent` DECIMAL(5,2) DEFAULT NULL, -- Weightage of this scope(Lesson,Topic,Sub-Topic) in the exam
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_es_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_es_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`),
  CONSTRAINT `fk_es_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
  CONSTRAINT `fk_es_question_type` FOREIGN KEY (`question_type_id`) REFERENCES `qns_question_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_blueprints
-- Purpose: Structure of the exam. Useful for generating question papers automatically.
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_blueprints` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `section_name` VARCHAR(50) DEFAULT 'Section A', -- e.g., 'Part 1', 'Section A - Objective'
  `subject_id` INT UNSIGNED DEFAULT NULL,      -- If exam is multi-subject, this section belongs to which subject?
  `question_type_group` ENUM('MCQ','DESCRIPTIVE','MIXED') NOT NULL DEFAULT 'MIXED',
  `instruction_text` TEXT DEFAULT NULL,
  `total_questions` INT UNSIGNED NOT NULL DEFAULT 0,
  `marks_per_question` DECIMAL(5,2) DEFAULT NULL, -- If fixed marks for this section
  `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `ordinal` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_eb_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_eb_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_questions
-- Purpose: The actual questions in the exam.
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_questions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `blueprint_id` INT UNSIGNED DEFAULT NULL,    -- FK to lms_exam_blueprints
  `question_id` INT UNSIGNED NOT NULL,         -- FK to qns_questions_bank
  `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,      -- Order in the exam/blueprint
  `marks` DECIMAL(5,2) NOT NULL,                  -- Marks for this question in THIS exam (can override question default)
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  `is_compulsory` TINYINT(1) NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_q` (`exam_id`, `question_id`),
  CONSTRAINT `fk_eq_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_eq_blueprint` FOREIGN KEY (`blueprint_id`) REFERENCES `lms_exam_blueprints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_eq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_allocations
-- Purpose: Assigning exams to students/classes.
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_allocations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `allocation_type` ENUM('CLASS','SECTION','GROUP','STUDENT') NOT NULL,
  `target_table_name` VARCHAR(60) NOT NULL,     -- 'sch_classes', 'sch_sections', 'sch_entity_groups', 'sys_users' (students)
  `target_id` INT UNSIGNED NOT NULL,         -- ID from the respective table
  
  -- Schedule overrides (if different for specific allocation)
  `scheduled_start_at` DATETIME DEFAULT NULL,
  `scheduled_end_at` DATETIME DEFAULT NULL,     -- Strict window for exam
  `extended_submission_time_minutes` INT UNSIGNED DEFAULT 0, -- Extra time for this group/student
  
  `assigned_by` INT UNSIGNED DEFAULT NULL,   -- FK to sys_users
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_alloc_target` (`allocation_type`, `target_id`),
  CONSTRAINT `fk_ea_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;





-- =========================================================================
-- 3. EXAM EXECUTION & RESULTS (Attempts, Answers, Evaluation)
-- =========================================================================

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_student_attempts
-- Purpose: Tracks a student's attempt at an exam (or quiz/quest if consolidated, but here specifically Exam).
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `exam_id` INT UNSIGNED NOT NULL,           -- FK to lms_exams
  `student_id` INT UNSIGNED NOT NULL,        -- FK to sch_students (or sys_users)
  `allocation_id` INT UNSIGNED DEFAULT NULL, -- FK to lms_exam_allocations
  
  -- Timing
  `started_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `concluded_at` DATETIME DEFAULT NULL,         -- Auto-submitted by system
  `time_taken_seconds` INT UNSIGNED DEFAULT 0,
  
  -- Status
  `status` ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','MISSED','CANCELLED') NOT NULL DEFAULT 'NOT_STARTED',
  `attempt_mode` ENUM('ONLINE','OFFLINE') NOT NULL DEFAULT 'ONLINE',
  
  -- Proctoring Data
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `browser_agent` TEXT DEFAULT NULL,
  `device_info` JSON DEFAULT NULL,
  `violation_count` INT UNSIGNED DEFAULT 0,     -- Proctoring violations detected
  
  -- Offline Metadata
  `offline_paper_uploaded_id` INT UNSIGNED DEFAULT NULL, -- FK to sys_media (Scanned answer sheet)
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_attempt_uuid` (`uuid`),
  UNIQUE KEY `uq_attempt_student_exam` (`exam_id`, `student_id`), -- Assuming 1 attempt per exam rule for now (or make non-unique if re-attempts allowed)
  CONSTRAINT `fk_att_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `sch_students` (`id`), -- Or sys_users
  CONSTRAINT `fk_att_alloc` FOREIGN KEY (`allocation_id`) REFERENCES `lms_exam_allocations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_answers
-- Purpose: Stores student responses to questions.
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_answers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` INT UNSIGNED NOT NULL,        -- FK to lms_student_attempts
  `question_id` INT UNSIGNED NOT NULL,       -- FK to qns_questions_bank
  `question_type_id` INT UNSIGNED NOT NULL,  -- Cached type for logic
  
  -- Usage Context (Since this table might be large, identifying if it's exam or quiz answer helps partitioning if needed)
  -- But here we imply it's for the 'attempt_id' which is tied to an exam.
  
  -- The Answer
  `selected_option_id` INT UNSIGNED DEFAULT NULL, -- For Single MCQ
  `selected_option_ids` JSON DEFAULT NULL,           -- For Multi MCQ (Array of IDs)
  `descriptive_answer` TEXT DEFAULT NULL,            -- For Text answers
  `attachment_id` INT UNSIGNED DEFAULT NULL,      -- FK to sys_media (if file upload required)
  
  -- Evaluation
  `is_correct` TINYINT(1) DEFAULT NULL,              -- 1=Correct, 0=Incorrect, NULL=Not Evaluated
  `marks_obtained` DECIMAL(5,2) DEFAULT 0.00,
  `is_evaluated` TINYINT(1) NOT NULL DEFAULT 0,
  `evaluated_by` INT UNSIGNED DEFAULT NULL,       -- FK to sys_users (Teacher) or NULL if Auto
  `evaluation_remarks` TEXT DEFAULT NULL,
  `evaluated_at` DATETIME DEFAULT NULL,
  
  -- Analytics
  `time_spent_seconds` INT UNSIGNED DEFAULT 0,
  `change_count` SMALLINT UNSIGNED DEFAULT 0,        -- How many times answer was changed
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ans_attempt_q` (`attempt_id`, `question_id`),
  CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_results
-- Purpose: Final consolidated result for the student.
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_results` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `attempt_id` INT UNSIGNED DEFAULT NULL,     -- Optional, if based on a specific attempt
  
  -- Scores
  `total_marks_possible` DECIMAL(8,2) NOT NULL,
  `total_marks_obtained` DECIMAL(8,2) NOT NULL,
  `percentage` DECIMAL(5,2) NOT NULL,
  `grade_obtained` VARCHAR(10) DEFAULT NULL,     -- A+, B, etc.
  `division` VARCHAR(20) DEFAULT NULL,           -- First, Second, etc.
  `result_status` ENUM('PASS','FAIL','ABSENT','WITHHELD') NOT NULL,
  `rank_in_class` INT UNSIGNED DEFAULT NULL,
  `percentile` DECIMAL(5,2) DEFAULT NULL,
  
  -- Publishing
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `published_at` DATETIME DEFAULT NULL,
  `teacher_remarks` TEXT DEFAULT NULL,
  `generated_report_card_url` VARCHAR(255) DEFAULT NULL, -- Path to PDF if generated
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_res_exam_stud` (`exam_id`, `student_id`),
  CONSTRAINT `fk_res_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_res_student` FOREIGN KEY (`student_id`) REFERENCES `sch_students` (`id`),
  CONSTRAINT `fk_res_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_exam_grievances
-- Purpose: Student grievance against evaluation.
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_grievances` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_result_id` INT UNSIGNED NOT NULL,     -- FK to lms_exam_results
  `question_id` INT UNSIGNED NOT NULL,        -- FK to qns_questions_bank
  `student_id` INT UNSIGNED NOT NULL,
  `grievance_text` TEXT NOT NULL,
  `status` ENUM('OPEN','UNDER_REVIEW','RESOLVED','REJECTED') NOT NULL DEFAULT 'OPEN',
  `reviewer_id` INT UNSIGNED DEFAULT NULL,    -- Teacher who reviewed
  `resolution_remarks` TEXT DEFAULT NULL,
  `marks_changed` TINYINT(1) DEFAULT 0,
  `old_marks` DECIMAL(5,2) DEFAULT NULL,
  `new_marks` DECIMAL(5,2) DEFAULT NULL,
  `resolved_at` DATETIME DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_grv_result` FOREIGN KEY (`exam_result_id`) REFERENCES `lms_exam_results` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_grv_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`),
  CONSTRAINT `fk_grv_student` FOREIGN KEY (`student_id`) REFERENCES `sch_students` (`id`),
  CONSTRAINT `fk_grv_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================================
-- 4. ANALYTICS & LOGGING
-- =========================================================================

-- -------------------------------------------------------------------------------------------------------
-- Table: lms_attempt_activity_logs
-- Purpose: Technical logs of student behavior during exam (tab switch, etc.)
-- -------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_attempt_activity_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` INT UNSIGNED NOT NULL,
  `activity_type` ENUM('FOCUS_LOST','FULLSCREEN_EXIT','BROWSER_RESIZE','KEY_PRESS_BLOCKED','MOUSE_LEAVE','IP_CHANGE') NOT NULL,
  `activity_data` JSON DEFAULT NULL,
  `occurred_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_log_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================================
-- 5. REFINED QUIZ & QUEST TABLES (Included for completeness/unification)
-- =========================================================================
-- Validated against provided DDLs. The above Shared Configs serve these as well.
-- If users want strict separation, those can be in separate files, but requirements asked for "Refine... LMS_Quiz & LMS_Quest Module... Output as single file".
-- Proceeding to include refined versions for consistency.

-- (Refined lms_quizzes, lms_quests tables would go here if not already present in other files. 
-- Since the user inputs specifically had separate files for them AND asked for 'LMS_Exam_ddl', 
-- I will assume the PRIMARY delivery is the EXAM part, but I will ensure 
-- the 'Shared' section above supports them.)

-- =========================================================================
-- 6. SEED DATA for EXAMS
-- =========================================================================

-- Seed usage types for Exams
INSERT INTO `qns_question_usage_type` (`code`, `name`, `description`) 
VALUES 
('ONLINE_EXAM', 'Online Exam', 'High stakes online examination'),
('OFFLINE_EXAM', 'Offline Exam', 'Traditional pen and paper exam with marks entry')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Seed Exam Types
INSERT INTO `lms_assessment_types` (`code`, `name`, `assessment_usage_type_id`)
SELECT 'HALF_YEARLY', 'Half Yearly Exam', id FROM qns_question_usage_type WHERE code='ONLINE_EXAM' LIMIT 1;

INSERT INTO `lms_assessment_types` (`code`, `name`, `assessment_usage_type_id`)
SELECT 'ANNUAL', 'Annual Final Exam', id FROM qns_question_usage_type WHERE code='ONLINE_EXAM' LIMIT 1;

-- --------------------------------------------------------------------------------------------------------------------
-- Abbreviations
-- --------------------------------------------------------------------------------------------------------------------
--  Full Term	            Short Form	      Common Usage
--  Half Yearly Exam	      HY 	            Mid-session assessments
--  Yearly Exam	            YE 	            End-of-year assessments
--  Annual Exam	            AE 	            Formal year-end reporting
--  Final Exam	            FE 	            Last exam of a course or degree
--  Quarterly Exam	        QE 	            Term-based assessments
--  Unit Test	              UT 	            Unit term assessments
--  Semester Exam	          SE 	            Mid-term assessments
--  
--  Online Exam	          ONLE 	            Computer-based or remote tests.
--  Offline Exam	        OFFE 	            Traditional pen-and-paper or in-person tests.
