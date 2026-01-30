-- =========================================================================
-- LMS EXAM MODULE v2.0
-- Purpose: Unified Online/Offline Exam Management with Multi-Set Papers
-- Created: 2026-01-30
-- =========================================================================

-- =========================================================================
-- 1. CONFIGURATION & MASTERS
-- =========================================================================

-- Exam Types (e.g., Unit Test, Half Yearly, Annual)
-- If not present in Common Masters, this table defines the category of exams.
CREATE TABLE IF NOT EXISTS `lms_exam_types` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,              -- e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM'
  `name` VARCHAR(100) NOT NULL,             -- e.g. 'Unit Test 1','Unit Test 2','Unit Test 3','Unit Test 4','Half Yearly Exam','Annual Exam'
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -- Grading Schemas
-- -- Defines how marks are converted to grades (e.g., CBSE 9-point scale)
-- CREATE TABLE IF NOT EXISTS `lms_grading_schemas` (
--   `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
--   `code` VARCHAR(50) NOT NULL,              -- e.g. 'CBSE_SEC_2025', 'ICSE_PRI_2025'
--   `name` VARCHAR(100) NOT NULL,             -- e.g. 'CBSE Secondary Grading 2025'
--   `description` VARCHAR(255) DEFAULT NULL,
--   `is_active` TINYINT(1) NOT NULL DEFAULT 1,
--   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
--   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `uq_grade_schema_code` (`code`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CREATE TABLE IF NOT EXISTS `lms_grading_ranges` (
--   `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
--   `grading_schema_id` BIGINT UNSIGNED NOT NULL,
--   `grade_name` VARCHAR(10) NOT NULL,        -- e.g. 'A1', 'B2'
--   `min_percentage` DECIMAL(5,2) NOT NULL,   -- e.g. 91.00
--   `max_percentage` DECIMAL(5,2) NOT NULL,   -- e.g. 100.00
--   `grade_point` DECIMAL(4,2) DEFAULT NULL,  -- e.g. 10.0
--   `description` VARCHAR(100) DEFAULT NULL,  -- e.g. 'Outstanding'
--   PRIMARY KEY (`id`),
--   CONSTRAINT `fk_gr_schema` FOREIGN KEY (`grading_schema_id`) REFERENCES `lms_grading_schemas` (`id`) ON DELETE CASCADE
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- slb_grade_division_master

-- =========================================================================
-- 2. EXAM DEFINITION HIERARCHY
-- =========================================================================

-- LEVEL 1: EXAM (The Event)
-- Represents the overarching event, e.g., "Annual Examination 2025-26"
CREATE TABLE IF NOT EXISTS `lms_exams` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL, -- FK to glb_academic_sessions
  `exam_type_id` BIGINT UNSIGNED NOT NULL,        -- FK to lms_exam_types (e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM')
  `code` VARCHAR(50) NOT NULL,                    -- e.g. 'EXAM_2025_ANNUAL'
  `title` VARCHAR(150) NOT NULL,                  -- e.g. 'Annual Examination 2025'
  `description` TEXT DEFAULT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `grading_schema_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to slb_grade_division_master (Default schema for the exam Grading / Division)
  `status` ENUM('DRAFT','PUBLISHED','CONCLUDED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_uuid` (`uuid`),
  UNIQUE KEY `uq_exam_code` (`code`),
  CONSTRAINT `fk_exam_session` FOREIGN KEY (`academic_session_id`) REFERENCES `glb_academic_sessions` (`id`),
  CONSTRAINT `fk_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_exam_types` (`id`),
  CONSTRAINT `fk_exam_grading` FOREIGN KEY (`grading_schema_id`) REFERENCES `slb_grade_division_master` (`id`),
  CONSTRAINT `fk_exam_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- LEVEL 2: EXAM PAPERS (The Subject Specific Entity)
-- Represents a specific paper for a specific mode, e.g., "Class 9 - Math - Online"
CREATE TABLE IF NOT EXISTS `lms_exam_papers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,             -- FK to lms_exams
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_subjects
  `paper_code` VARCHAR(50) NOT NULL,              -- e.g. 'UT-1_2025_ANNUAL_MTH_ON'
  `title` VARCHAR(150) NOT NULL,                  -- e.g. 'Unit Test 1 - 2025-26 - Mathematics - Online'
  `mode` ENUM('ONLINE', 'OFFLINE') NOT NULL,
  `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `passing_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,   -- Relevant for Online, Guide for Offline
  `instructions` TEXT DEFAULT NULL,
  
  -- Online Specific Config
  `is_proctored` TINYINT(1) NOT NULL DEFAULT 0,
  `is_ai_proctored` TINYINT(1) NOT NULL DEFAULT 0,
  `fullscreen_required` TINYINT(1) NOT NULL DEFAULT 0,
  `browser_lock_required` TINYINT(1) NOT NULL DEFAULT 0,
  `shuffle_questions` TINYINT(1) NOT NULL DEFAULT 0,
  `show_result_type` ENUM('IMMEDIATE','SCHEDULED','MANUAL') NOT NULL DEFAULT 'MANUAL',
  `scheduled_result_at` DATETIME DEFAULT NULL,
  
  -- Offline Specific Config
  `offline_entry_mode` ENUM('BULK_TOTAL','QUESTION_WISE') DEFAULT 'BULK_TOTAL', -- How marks will be entered
  
  `status` ENUM('DRAFT','READY','SCHEDULED','COMPLETED') NOT NULL DEFAULT 'DRAFT',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_paper_code` (`exam_id`, `paper_code`),
  CONSTRAINT `fk_paper_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_paper_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- LEVEL 3: PAPER SETS (The Variants)
-- Represents variants of the paper, e.g., "Set A", "Set B" OR 'Set 1', 'Set 2'
CREATE TABLE IF NOT EXISTS `lms_exam_paper_sets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_paper_id` BIGINT UNSIGNED NOT NULL,       -- FK to lms_exam_papers.id
  `set_code` VARCHAR(20) NOT NULL,                -- e.g. 'SET_A', 'SET_B' OR 'SET_1', 'SET_2'
  `set_name` VARCHAR(50) NOT NULL,                -- e.g. 'Paper Set A' OR 'Paper Set 1'
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_paper_set` (`exam_paper_id`, `set_code`),
  CONSTRAINT `fk_set_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- LEVEL 4: SET QUESTIONS (The Content)
-- Links questions from Question Bank to a specific Set
CREATE TABLE IF NOT EXISTS `lms_paper_set_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `paper_set_id` BIGINT UNSIGNED NOT NULL,        -- FK to lms_exam_paper_sets
  `question_id` BIGINT UNSIGNED NOT NULL,         -- FK to qns_questions_bank
  `section_name` VARCHAR(50) DEFAULT 'Section A', -- Logical grouping within paper to showcase MCQ, Long Answer, Short Answer etc.
  `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,      -- Sequence order
  `marks` DECIMAL(5,2) NOT NULL,                  -- Override marks from Question Bank
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  `is_compulsory` TINYINT(1) NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1, 
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_set_question` (`paper_set_id`, `question_id`),
  CONSTRAINT `fk_sq_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 3. ALLOCATION & GROUPING
-- =========================================================================

-- Student Groups for Exam Purposes
-- Allows creating ad-hoc groups (e.g., "Class 9 Adv Math") derived from classes/sections
CREATE TABLE IF NOT EXISTS `lms_exam_student_groups` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,             -- Scope of the group
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_esg_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Members of the Ad-hoc Group
CREATE TABLE IF NOT EXISTS `lms_exam_student_group_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_students / sys_users
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_esgm_member` (`group_id`, `student_id`),
  CONSTRAINT `fk_esgm_group` FOREIGN KEY (`group_id`) REFERENCES `lms_exam_student_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_esgm_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Allocations: Mapping Papers/Sets to Students/Groups
CREATE TABLE IF NOT EXISTS `lms_exam_allocations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_paper_id` BIGINT UNSIGNED NOT NULL,       -- Which paper
  `paper_set_id` BIGINT UNSIGNED NOT NULL,        -- Which set (Specific variant)
  
  -- Target definition
  `allocation_type` ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') NOT NULL,
  `target_id` BIGINT UNSIGNED NOT NULL,           -- ID of Class, Section, ExamGroup, or Student
  
  -- Scheduling Overrides
  `scheduled_date` DATE DEFAULT NULL,             -- If different from paper default
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `location` VARCHAR(100) DEFAULT NULL,           -- relevant for Offline
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_alloc_target` (`allocation_type`, `target_id`),
  CONSTRAINT `fk_alloc_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_alloc_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 4. EXECUTION (Online & Offline)
-- =========================================================================

-- Student Attempt / Exam Record
CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `exam_paper_id` BIGINT UNSIGNED NOT NULL,
  `paper_set_id` BIGINT UNSIGNED NOT NULL,        -- The actual set assigned/taken
  `allocation_id` BIGINT UNSIGNED DEFAULT NULL,   -- Link to allocation rule
  `student_id` BIGINT UNSIGNED NOT NULL,
  
  -- Timing
  `started_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `time_taken_seconds` INT UNSIGNED DEFAULT 0,
  
  -- Status
  `status` ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','ABSENT','CANCELLED') NOT NULL DEFAULT 'NOT_STARTED',
  `attempt_mode` ENUM('ONLINE', 'OFFLINE') NOT NULL,
  
  -- Offline Metadata
  `answer_sheet_number` VARCHAR(50) DEFAULT NULL, -- Physical sheet ID
  `is_present_offline` TINYINT(1) DEFAULT 1,      -- For attendance
  
  -- Online Metadata
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `device_info` JSON DEFAULT NULL,
  `violation_count` INT UNSIGNED DEFAULT 0,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_attempt_uuid` (`uuid`),
  UNIQUE KEY `uq_attempt_student_paper` (`exam_paper_id`, `student_id`),
  CONSTRAINT `fk_att_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`),
  CONSTRAINT `fk_att_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`),
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
  CONSTRAINT `fk_att_alloc` FOREIGN KEY (`allocation_id`) REFERENCES `lms_exam_allocations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student Answers (Granular Data)
-- Used for Online Exams AND Offline Exams (if doing question-wise entry)
CREATE TABLE IF NOT EXISTS `lms_attempt_answers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  
  -- The Response
  `selected_option_id` BIGINT UNSIGNED DEFAULT NULL, -- For MCQ
  `descriptive_answer` TEXT DEFAULT NULL,            -- For Online Descriptive
  `attachment_id` BIGINT UNSIGNED DEFAULT NULL,      -- Uploaded file
  
  -- Evaluation
  `marks_obtained` DECIMAL(5,2) DEFAULT 0.00,
  `is_correct` TINYINT(1) DEFAULT NULL,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `evaluated_by` BIGINT UNSIGNED DEFAULT NULL,       -- Teacher ID / NULL for System
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ans_attempt_q` (`attempt_id`, `question_id`),
  CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- 5. RESULTS & GRADING
-- =========================================================================

-- Bulk Marks Entry (For Offline Exams only - Skipping Granular Answers)
CREATE TABLE IF NOT EXISTS `lms_exam_marks_entry` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,          -- FK to lms_student_attempts
  `total_marks_obtained` DECIMAL(8,2) NOT NULL,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `entered_by` BIGINT UNSIGNED NOT NULL,          -- Teacher
  `entered_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_marks_entry_attempt` (`attempt_id`),
  CONSTRAINT `fk_me_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_me_enterer` FOREIGN KEY (`entered_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Final Consolidated Result
CREATE TABLE IF NOT EXISTS `lms_exam_results` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,             -- FK to lms_exams
  `student_id` BIGINT UNSIGNED NOT NULL,
  
  -- Aggregated Scores
  `total_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `max_marks` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  
  -- Grade & Status
  `grade` VARCHAR(10) DEFAULT NULL,               -- Derived from Grading Schema
  `result_status` ENUM('PASS','FAIL','WITHHELD','ABSENT') NOT NULL DEFAULT 'PASS',
  
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `published_at` DATETIME DEFAULT NULL,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_result_exam_stud` (`exam_id`, `student_id`),
  CONSTRAINT `fk_res_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_res_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Grievances / Re-eval Requests
CREATE TABLE IF NOT EXISTS `lms_exam_grievances` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_result_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED DEFAULT NULL,     -- Optional (Null if general grievance)
  `grievance_type` ENUM('MARKING_ERROR','QUESTION_ERROR','OUT_OF_SYLLABUS','OTHER') NOT NULL,
  `description` TEXT NOT NULL,
  `status` ENUM('OPEN','IN_PROGRESS','RESOLVED','REJECTED') NOT NULL DEFAULT 'OPEN',
  `resolution_remarks` TEXT DEFAULT NULL,
  `resolved_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_grv_result` FOREIGN KEY (`exam_result_id`) REFERENCES `lms_exam_results` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_grv_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
