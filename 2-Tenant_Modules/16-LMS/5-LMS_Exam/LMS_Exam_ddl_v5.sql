-- =========================================================================
-- LMS EXAM MODULE v2.0
-- Purpose: Unified Online/Offline Exam Management with Multi-Set Papers
-- Created: 2026-01-30
-- =========================================================================

-- =========================================================================
-- 1. CONFIGURATION & MASTERS
-- =========================================================================
Screen Exam Master (Tab -1 Exam Types)

-- Exam Types (e.g., Unit Test, Half Yearly, Annual)
-- If not present in Common Masters, this table defines the category of exams.
CREATE TABLE IF NOT EXISTS `lms_exam_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
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

Screen Exam Master (Tab -2 Exam Status Events)
CREATE TABLE IF NOT EXISTS `lms_exam_status_events` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,  -- (e.g. 'DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `event_type` ENUM('EXAM','PAPER','RESULT','ATTEMPT') NOT NULL DEFAULT 'EXAM',
  `action_logic` JSON NOT NULL,         -- e.g., '{"logic": "assign_exam_actions"}'
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_status_event_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- Exam - ('DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
-- Paper - ('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')
-- Result - ('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')
-- Attempt - ('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')

Screen Exam Master (Tab -3 Student Groups)
-- Student Groups for Exam Purposes
-- Allows creating ad-hoc groups (e.g., "Class 9 Adv Math") derived from classes/sections
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_student_groups` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,             -- FK to lms_exams.id
  `class_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_classes.id
  `section_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_sections.id
  `code` VARCHAR(20) NOT NULL,                   -- e.g. "9th-A_SET-A"
  `name` VARCHAR(100) NOT NULL,                   -- e.g. "Class 9th-A, Group SET-A"
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_esg_code` (`exam_id`, `class_id`, `section_id`, `code`),
  CONSTRAINT `fk_esg_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_esg_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_esg_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

Screen Exam Master (Tab -4 Student Group Members)
-- Members of the Ad-hoc Group
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_student_group_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_students / sys_users
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_esgm_member` (`group_id`, `student_id`),
  CONSTRAINT `fk_esgm_group` FOREIGN KEY (`group_id`) REFERENCES `lms_exam_student_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_esgm_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SCREEN Name - EXAM Creation (Tab -1 Exam)
-- =========================================================================
-- 2. EXAM DEFINITION HIERARCHY
-- =========================================================================

-- LEVEL 1: EXAM (The Event)
-- This table is used to define the exam event and its basic details. 
-- Represents the overarching event, e.g., "Annual Examination 2025-26"
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exams` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL, -- FK to glb_academic_sessions.id
  `class_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_classes.id
  `exam_type_id` INT UNSIGNED NOT NULL,        -- FK to lms_exam_types.id (e.g. 'UT-1','UT-2','UT-3','UT-4','HY-EXAM','ANNUAL-EXAM')
  `code` VARCHAR(50) NOT NULL,                    -- e.g. 'EXAM_2025_ANNUAL'
  `title` VARCHAR(150) NOT NULL,                  -- e.g. 'Annual Examination 2025'
  `description` TEXT DEFAULT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `grading_schema_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to slb_grade_division_master (Default schema for the exam Grading / Division)
  `status_id` INT UNSIGNED NOT NULL DEFAULT 0,    -- FK to lms_exam_status_events.id (Status of the exam) 'DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
  `created_by` BIGINT UNSIGNED DEFAULT NULL,         -- FK to sys_users.id
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_uuid` (`uuid`),
  UNIQUE KEY `uq_exam_code` (`code`),
  UNIQUE KEY `uq_exam_session_class_type` (`academic_session_id`, `class_id`, `exam_type_id`),
  CONSTRAINT `fk_exam_session` FOREIGN KEY (`academic_session_id`) REFERENCES `glb_academic_sessions` (`id`),
  CONSTRAINT `fk_exam_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `lms_exam_types` (`id`),
  CONSTRAINT `fk_exam_grading` FOREIGN KEY (`grading_schema_id`) REFERENCES `slb_grade_division_master` (`id`),
  CONSTRAINT `fk_exam_status` FOREIGN KEY (`status_id`) REFERENCES `lms_exam_status_events` (`id`),
  CONSTRAINT `fk_exam_creator` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SCREEN Name - EXAM Creation (Tab -2 Exam Papers)
-- LEVEL 2: EXAM PAPERS (The Subject Specific Entity)
-- This table is used to define the exam paper and its basic details. 
-- Represents a specific paper for a specific mode, e.g., "Class 9 - Math - Online"
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_papers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,             -- FK to lms_exams.id
  `class_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_classes.id
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_subjects.id
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
  -- Audit
  `status_id` INT UNSIGNED NOT NULL DEFAULT 0,    -- FK to lms_exam_status_events.id (Status of the exam) 'DRAFT','PUBLISHED','CONCLUDED','ARCHIVED')
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_paper_code` (`exam_id`, `paper_code`),
  CONSTRAINT `fk_paper_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_paper_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_paper_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
  CONSTRAINT `fk_paper_status` FOREIGN KEY (`status_id`) REFERENCES `lms_exam_status_events` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SCREEN Name - EXAM Creation (Tab -3 Exam Paper Sets)
-- LEVEL 3: PAPER SETS (The Variants)
-- Represents variants of the paper, e.g., "Set A", "Set B" OR 'Set 1', 'Set 2'
-- --------------------------------------------------------------------------------------
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

SCREEN Name - EXAM Creation (Tab -4 Add Question to Paper Sets)
-- LEVEL 4: SET QUESTIONS (The Content)
-- Links questions from Question Bank to a specific Set
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_paper_set_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `paper_set_id` BIGINT UNSIGNED NOT NULL,        -- FK to lms_exam_paper_sets.id
  `question_id` BIGINT UNSIGNED NOT NULL,         -- FK to qns_questions_bank.id
  `section_name` VARCHAR(50) DEFAULT 'Section A', -- Logical grouping within paper to showcase MCQ, Long Answer, Short Answer etc.
  `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,      -- Sequence order
  `override_marks` DECIMAL(5,2) NOT NULL,         -- Override marks from Question Bank
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,     -- Negative marks (if any)
  `is_compulsory` TINYINT(1) NOT NULL DEFAULT 1,  -- Attempting Question is Compulsory or Optional 
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,       -- Active or Inactive
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_set_question` (`paper_set_id`, `question_id`),
  CONSTRAINT `fk_sq_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------
SCREEN Name - EXAM Creation (Tab -5 Student Allocations)
-- Allocations: Mapping Papers/Sets to Students/Groups
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_allocations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_paper_id` BIGINT UNSIGNED NOT NULL,       -- Which paper
  `paper_set_id` BIGINT UNSIGNED NOT NULL,        -- Which set (Specific variant)
  -- Target definition
  `allocation_type` ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') NOT NULL,
  `class_id` BIGINT UNSIGNED NOT NULL,        -- FK to sch_classes.id (Class is must)
  `section_id` BIGINT UNSIGNED NULL,          -- FK to sch_sections.id (Section is optional)
  `exam_group_id` BIGINT UNSIGNED NULL,       -- FK to lms_exam_student_groups.id (Exam Group is optional)
  `student_id` BIGINT UNSIGNED NULL,          -- FK to sch_students / sys_users (Student is optional)
  -- Scheduling Overrides
  `scheduled_date` DATE DEFAULT NULL,         -- If different from paper default
  `scheduled_start_time` TIME NOT NULL,
  `scheduled_end_time` TIME NOT NULL,
  `location` VARCHAR(100) DEFAULT NULL,       -- relevant for Offline
  -- Status
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_alloc_target` (`allocation_type`, `class_id`, `section_id`, `exam_group_id`, `student_id`),
  CONSTRAINT `fk_alloc_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_alloc_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`),
  CONSTRAINT `fk_alloc_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_alloc_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
  CONSTRAINT `fk_alloc_exam_group` FOREIGN KEY (`exam_group_id`) REFERENCES `lms_exam_student_groups` (`id`),
  CONSTRAINT `fk_alloc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- Flow & Conditions
-- =========================================================================




-- Schools may have 2 type of Exam - Online & Offline for different Assessment type (Unit Test, Term Test, Half Yearly Exam, Annual Exam, etc)
-- Multipal papers for different Subject for every class+section will be conducted.
-- School may use both Method (Online & Offline) for the same Exam for different Class/Section or for different Subject.
-- There will be some conditions which will be applicable to both Online & Offline Exam, which we should keep separate.
-- There will be some conditions which will be applicable to Online Exam only, which we should keep separate.
-- I feel chanses are extremly low to have any condition which will be applicable to Offline Exam only and to both, but if there is any we should keep that also separate. 
-- Different Subject for a Particuler Class/Section may have different Method of Exam (Online or Offline or Both)
-- Every Subject for a Particuler Class/Section may have multipal sets of papers for Online & Offline Method of Exam
-- Different set of exam papers set may have different questions
-- we may divide students of every class,section into different groups for exam purpose.
-- School may decide to create different exam paper for different group of students or for every student for the same Subject for same exam
-- Different group of students will be assigned different set of papers for the same Subject for same exam
-- Every exam may have MCQ & Descriptive type Questions.
-- Descriptive type Questions will be evaluated by Teacher & later can be evaluated by AI to suggest improvement or to help teacher in evaluation.
-- MCQ Questions for both type of Exam (Online & Offline) will be evaluated by System
-- For Offline Exams Questions & Answers will be uploaded in Excel/PDF format or will be entereed manually into system
-- For Offline exam Answer key & Teacher's Marks will be uploaded in Excel format or will be entereed manually into system
-- All Descriptive type questions Marks whcih will be evaluated by teacher will be uploaded in Excel format or entered manually into system.
-- Answeres for all Descriptive type questions in Online Exams will be uploaded in Excel/PDF format or entered manually into system
-- Grading & Division will be calculated by system by using pre-defined config table
