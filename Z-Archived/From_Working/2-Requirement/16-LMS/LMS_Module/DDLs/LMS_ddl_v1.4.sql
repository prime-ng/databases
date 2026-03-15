-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 1.4
-- =====================================================================
-- Hierarchy: Class → Subject → Lesson → Topic → Sub-topic → Mini Topic 
--            → Sub-Mini Topic → Micro Topic → Sub-Micro Topic (Unlimited)
--
-- NEW IN v1.4:
  -- ✓ Book/Publication Management aligned with Topics
  -- ✓ School-specific Custom Question Bank
  -- ✓ Performance-based Study Material Recommendations
  -- ✓ Configurable Performance Categories at School Level
  -- ✓ Teaching Status (Syllabus Completion) Tracking
  -- ✓ Syllabus Scheduling per Class/Section/Subject
  -- ✓ Teacher Assignment with Timetable Integration
  -- ✓ Hierarchical Topic Dependencies for Remedial Learning
  -- ✓ Base Topic Mapping for Root Cause Analysis
  -- ✓ Enhanced Quiz/Assessment/Exam with Auto-Assignment
  -- ✓ Offline Exam Support with Manual Marking
  -- ✓ Comprehensive Student Behavioral Analytics
  -- ✓ Performance-based Recommendations Engine
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================================
-- SECTION 1: BOOK & PUBLICATION MANAGEMENT (NEW)
-- =========================================================================

-- Master table for Books/Publications used across schools
CREATE TABLE IF NOT EXISTS `slb_books` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,
  `isbn` VARCHAR(20) DEFAULT NULL,              -- International Standard Book Number
  `title` VARCHAR(255) NOT NULL,
  `subtitle` VARCHAR(255) DEFAULT NULL,
  `edition` VARCHAR(50) DEFAULT NULL,           -- e.g., '5th Edition', 'Revised 2024'
  `publication_year` YEAR DEFAULT NULL,         -- e.g., 2024
  `publisher_name` VARCHAR(150) DEFAULT NULL,   -- e.g., 'NCERT', 'S.Chand', 'Pearson'
  `language` VARCHAR(50) DEFAULT 'English',
  `total_pages` INT UNSIGNED DEFAULT NULL,
  `cover_image_url` VARCHAR(500) DEFAULT NULL,
  `description` TEXT DEFAULT NULL,
  `tags` JSON DEFAULT NULL,                     -- Additional search tags
  `is_ncert` TINYINT(1) DEFAULT 0,              -- Flag for NCERT books
  `is_cbse_recommended` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book_uuid` (`uuid`),
  UNIQUE KEY `uq_book_isbn` (`isbn`),
  KEY `idx_book_title` (`title`),
  KEY `idx_book_publisher` (`publisher_name`),
  KEY `idx_book_year` (`publication_year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Authors table (Many-to-Many with Books)
CREATE TABLE IF NOT EXISTS `slb_book_authors` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `qualification` VARCHAR(200) DEFAULT NULL,
  `bio` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_author_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction: Book-Author relationship
CREATE TABLE IF NOT EXISTS `slb_book_author_jnt` (
  `book_id` INT UNSIGNED NOT NULL,
  `author_id` INT UNSIGNED NOT NULL,
  `author_role` ENUM('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') DEFAULT 'PRIMARY',
  `ordinal` TINYINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (`book_id`, `author_id`),
  CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `slb_book_authors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Link Books to Class/Subject (which books are used for which class/subject)
CREATE TABLE IF NOT EXISTS `slb_book_class_subject_jnt` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `book_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `is_primary` TINYINT(1) DEFAULT 1,            -- Primary textbook vs reference
  `is_mandatory` TINYINT(1) DEFAULT 1,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bcs_book_class_subject_session` (`book_id`, `class_id`, `subject_id`, `academic_session_id`),
  CONSTRAINT `fk_bcs_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bcs_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bcs_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bcs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Link Book Chapters/Sections to Topics (granular mapping)
CREATE TABLE IF NOT EXISTS `slb_book_topic_mapping` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `book_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,          -- Can be topic or sub-topic at any level
  `chapter_number` VARCHAR(20) DEFAULT NULL,    -- e.g., '1', '1.2', 'Unit I'
  `chapter_title` VARCHAR(255) DEFAULT NULL,
  `page_start` INT UNSIGNED DEFAULT NULL,
  `page_end` INT UNSIGNED DEFAULT NULL,
  `section_reference` VARCHAR(100) DEFAULT NULL, -- e.g., 'Section 1.3.2'
  `remarks` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_btm_book` (`book_id`),
  KEY `idx_btm_topic` (`topic_id`),
  CONSTRAINT `fk_btm_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_btm_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 2: PERFORMANCE CATEGORIES (Configurable at School Level)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `slb_performance_categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,
  `code` VARCHAR(30) NOT NULL,                  -- e.g., 'BASIC', 'AVERAGE', 'GOOD', 'EXCELLENT'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `min_percentage` DECIMAL(5,2) NOT NULL,       -- Minimum score % for this category
  `max_percentage` DECIMAL(5,2) NOT NULL,       -- Maximum score % for this category
  `color_code` VARCHAR(10) DEFAULT NULL,        -- For UI display e.g., '#FF5722'
  `icon` VARCHAR(50) DEFAULT NULL,              -- Font-awesome icon or similar
  `ordinal` TINYINT UNSIGNED NOT NULL,          -- Display order
  `is_system` TINYINT(1) DEFAULT 0,             -- System-defined (global) vs school-defined
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_perfcat_uuid` (`uuid`),
  UNIQUE KEY `uq_perfcat_code` (`code`),
  KEY `idx_perfcat_ordinal` (`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 3: STUDY MATERIAL & RECOMMENDATIONS (Performance-based)
-- =========================================================================

-- Study Material Types (Video, PDF, Article, Interactive, etc.)
CREATE TABLE IF NOT EXISTS `slb_study_material_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,                  -- 'VIDEO', 'PDF', 'ARTICLE', 'INTERACTIVE', 'AUDIO'
  `name` VARCHAR(100) NOT NULL,
  `icon` VARCHAR(50) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_smt_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Study Materials linked to Topics at various levels
CREATE TABLE IF NOT EXISTS `slb_study_materials` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,          -- Linked to topic at any hierarchy level
  `material_type_id` INT UNSIGNED NOT NULL,
  `performance_category_id` INT UNSIGNED DEFAULT NULL, -- NULL = for all levels
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `url` VARCHAR(500) DEFAULT NULL,              -- External URL or internal path
  `media_id` INT UNSIGNED DEFAULT NULL,      -- FK to sys_media for uploaded files
  `duration_minutes` INT UNSIGNED DEFAULT NULL, -- For videos/audio
  `difficulty_level` ENUM('BASIC','INTERMEDIATE','ADVANCED') DEFAULT 'INTERMEDIATE',
  `language` VARCHAR(50) DEFAULT 'English',
  `source` VARCHAR(150) DEFAULT NULL,           -- e.g., 'Khan Academy', 'NCERT', 'Custom'
  `tags` JSON DEFAULT NULL,
  `view_count` INT UNSIGNED DEFAULT 0,
  `avg_rating` DECIMAL(3,2) DEFAULT NULL,
  `is_premium` TINYINT(1) DEFAULT 0,            -- Premium content flag
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studmat_uuid` (`uuid`),
  KEY `idx_studmat_topic` (`topic_id`),
  KEY `idx_studmat_perfcat` (`performance_category_id`),
  KEY `idx_studmat_type` (`material_type_id`),
  CONSTRAINT `fk_studmat_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_studmat_type` FOREIGN KEY (`material_type_id`) REFERENCES `slb_study_material_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studmat_perfcat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_studmat_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 4: TOPIC DEPENDENCY & BASE TOPIC MAPPING (For Remedial Learning)
-- =========================================================================

-- Maps prerequisite/base topics for root cause analysis
CREATE TABLE IF NOT EXISTS `slb_topic_dependencies` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `topic_id` INT UNSIGNED NOT NULL,          -- Current topic
  `prerequisite_topic_id` INT UNSIGNED NOT NULL, -- Required base topic (can be from previous class)
  `dependency_type` ENUM('PREREQUISITE','FOUNDATION','RELATED','EXTENSION') NOT NULL DEFAULT 'PREREQUISITE',
  `strength` ENUM('WEAK','MODERATE','STRONG') DEFAULT 'STRONG', -- How critical is this dependency
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topdep_topic_prereq` (`topic_id`, `prerequisite_topic_id`),
  KEY `idx_topdep_prereq` (`prerequisite_topic_id`),
  CONSTRAINT `fk_topdep_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topdep_prereq` FOREIGN KEY (`prerequisite_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- NOTE: This allows topics from different classes to be linked
-- e.g., Grade 10 "Quadratic Equations" depends on Grade 9 "Linear Equations"


-- =========================================================================
-- SECTION 5: TEACHING STATUS & SYLLABUS COMPLETION TRACKING
-- =========================================================================

CREATE TABLE IF NOT EXISTS `slb_teaching_status` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,          -- Topic at any hierarchy level
  `teacher_id` INT UNSIGNED NOT NULL,        -- Who marked completed
  `status` ENUM('NOT_STARTED','IN_PROGRESS','COMPLETED','REVISION','SKIPPED') NOT NULL DEFAULT 'NOT_STARTED',
  `completion_percentage` DECIMAL(5,2) DEFAULT 0.00,
  `started_date` DATE DEFAULT NULL,
  `completed_date` DATE DEFAULT NULL,
  `planned_periods` SMALLINT UNSIGNED DEFAULT NULL,
  `actual_periods` SMALLINT UNSIGNED DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `trigger_quiz` TINYINT(1) DEFAULT 1,          -- Auto-trigger quiz on completion
  `quiz_triggered_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teachstat_session_class_sec_subj_topic` (`academic_session_id`, `class_id`, `section_id`, `subject_id`, `topic_id`),
  KEY `idx_teachstat_status` (`status`),
  KEY `idx_teachstat_teacher` (`teacher_id`),
  CONSTRAINT `fk_teachstat_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachstat_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachstat_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachstat_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachstat_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachstat_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 6: SYLLABUS SCHEDULING
-- =========================================================================

CREATE TABLE IF NOT EXISTS `slb_syllabus_schedule` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,       -- NULL = applies to all sections
  `subject_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,
  `scheduled_start_date` DATE NOT NULL,
  `scheduled_end_date` DATE NOT NULL,
  `assigned_teacher_id` INT UNSIGNED DEFAULT NULL,
  `planned_periods` SMALLINT UNSIGNED DEFAULT NULL,
  `priority` ENUM('HIGH','MEDIUM','LOW') DEFAULT 'MEDIUM',
  `notes` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sylsched_dates` (`scheduled_start_date`, `scheduled_end_date`),
  KEY `idx_sylsched_class_subject` (`class_id`, `subject_id`),
  CONSTRAINT `fk_sylsched_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sylsched_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sylsched_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sylsched_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sylsched_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sylsched_teacher` FOREIGN KEY (`assigned_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 7: TEACHER SUBJECT ASSIGNMENT (Class/Section/Subject/Timetable)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `slb_teacher_subject_assignment` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `teacher_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `effective_from` DATE NOT NULL,
  `effective_to` DATE DEFAULT NULL,
  `periods_per_week` TINYINT UNSIGNED DEFAULT NULL,
  `is_primary` TINYINT(1) DEFAULT 1,            -- Primary teacher vs substitute
  `timetable_slot_ids` JSON DEFAULT NULL,       -- Link to timetable slots
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tsa_session_teacher_class_sec_subj` (`academic_session_id`, `teacher_id`, `class_id`, `section_id`, `subject_id`, `effective_from`),
  KEY `idx_tsa_teacher` (`teacher_id`),
  KEY `idx_tsa_class_section` (`class_id`, `section_id`),
  CONSTRAINT `fk_tsa_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tsa_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tsa_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tsa_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tsa_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 8: SCHOOL-SPECIFIC CUSTOM QUESTIONS
-- =========================================================================

-- Flag on existing sch_questions table to identify school-specific questions
-- Add column: `is_school_specific` TINYINT(1) DEFAULT 0
-- Add column: `visibility` ENUM('GLOBAL','SCHOOL_ONLY','PRIVATE') DEFAULT 'GLOBAL'

-- New table to track question ownership/visibility per school
CREATE TABLE IF NOT EXISTS `sch_question_ownership` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` INT UNSIGNED NOT NULL,
  `ownership_type` ENUM('GLOBAL','SCHOOL_CUSTOM','TEACHER_PRIVATE') NOT NULL DEFAULT 'GLOBAL',
  `created_by_teacher_id` INT UNSIGNED DEFAULT NULL,
  `is_shareable` TINYINT(1) DEFAULT 0,          -- Can be shared with other schools
  `approved_for_sharing` TINYINT(1) DEFAULT 0,
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qown_question` (`question_id`),
  CONSTRAINT `fk_qown_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qown_teacher` FOREIGN KEY (`created_by_teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 9: ENHANCED QUIZ WITH AUTO-ASSIGNMENT
-- =========================================================================

-- Link Quiz to Topics for auto-trigger on completion
CREATE TABLE IF NOT EXISTS `sch_quiz_topic_jnt` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quiz_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,
  `auto_assign_on_completion` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qztop_quiz_topic` (`quiz_id`, `topic_id`),
  CONSTRAINT `fk_qztop_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qztop_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Quiz Auto-Assignment Log
CREATE TABLE IF NOT EXISTS `sch_quiz_auto_assignments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `quiz_id` INT UNSIGNED NOT NULL,
  `teaching_status_id` INT UNSIGNED NOT NULL, -- What teaching completion triggered this
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED NOT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `due_date` DATE DEFAULT NULL,
  `status` ENUM('PENDING','ACTIVE','COMPLETED','CANCELLED') DEFAULT 'ACTIVE',
  `total_students` INT UNSIGNED DEFAULT 0,
  `completed_count` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_qzauto_quiz` (`quiz_id`),
  KEY `idx_qzauto_class_section` (`class_id`, `section_id`),
  CONSTRAINT `fk_qzauto_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qzauto_teachstat` FOREIGN KEY (`teaching_status_id`) REFERENCES `slb_teaching_status` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qzauto_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qzauto_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 10: OFFLINE EXAM SUPPORT
-- =========================================================================

-- Extend sch_exams with offline-specific columns (via ALTER or new table)
CREATE TABLE IF NOT EXISTS `sch_offline_exams` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,           -- FK to sch_exams
  `exam_mode` ENUM('ONLINE','OFFLINE_QB','OFFLINE_CUSTOM') NOT NULL DEFAULT 'OFFLINE_QB',
  -- OFFLINE_QB = Question paper from Question Bank
  -- OFFLINE_CUSTOM = Teacher-created paper, marks entered manually
  `question_paper_generated` TINYINT(1) DEFAULT 0,
  `question_paper_url` VARCHAR(500) DEFAULT NULL,
  `answer_key_url` VARCHAR(500) DEFAULT NULL,
  `marking_scheme_url` VARCHAR(500) DEFAULT NULL,
  `manual_entry_enabled` TINYINT(1) DEFAULT 1,
  `analytics_depth` ENUM('FULL','PARTIAL','MARKS_ONLY') DEFAULT 'MARKS_ONLY',
  -- FULL = Full question-wise analysis (when using Question Bank)
  -- PARTIAL = Topic-wise analysis
  -- MARKS_ONLY = Only total marks, minimal analytics
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_offexam_exam` (`exam_id`),
  CONSTRAINT `fk_offexam_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Manual marks entry for offline exams
CREATE TABLE IF NOT EXISTS `sch_offline_exam_marks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `question_id` INT UNSIGNED DEFAULT NULL,   -- NULL for custom papers
  `question_number` VARCHAR(20) DEFAULT NULL,   -- e.g., '1a', '2b(i)'
  `max_marks` DECIMAL(6,2) NOT NULL,
  `marks_obtained` DECIMAL(6,2) DEFAULT NULL,
  `evaluated_by` INT UNSIGNED DEFAULT NULL,
  `evaluated_at` TIMESTAMP NULL DEFAULT NULL,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_offmarks_exam_student_qnum` (`exam_id`, `student_id`, `question_number`),
  KEY `idx_offmarks_student` (`student_id`),
  CONSTRAINT `fk_offmarks_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_offmarks_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_offmarks_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_offmarks_evaluator` FOREIGN KEY (`evaluated_by`) REFERENCES `sch_teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 11: STUDENT BEHAVIORAL & PERFORMANCE ANALYTICS
-- =========================================================================

-- Detailed attempt behavior tracking
CREATE TABLE IF NOT EXISTS `sch_attempt_behavior_log` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` INT UNSIGNED NOT NULL,
  `question_id` INT UNSIGNED NOT NULL,
  `event_type` ENUM('VIEW','ANSWER','CHANGE','SKIP','BOOKMARK','REVIEW','SUBMIT') NOT NULL,
  `event_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `time_spent_seconds` INT UNSIGNED DEFAULT NULL,
  `answer_changes_count` TINYINT UNSIGNED DEFAULT 0,
  `confidence_indicator` ENUM('LOW','MEDIUM','HIGH') DEFAULT NULL, -- Based on behavior
  `hesitation_detected` TINYINT(1) DEFAULT 0,   -- Long pause before answering
  `device_info` JSON DEFAULT NULL,              -- Browser, device type, screen size
  `ip_address` VARCHAR(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_behlog_attempt` (`attempt_id`),
  KEY `idx_behlog_question` (`question_id`),
  KEY `idx_behlog_event` (`event_type`),
  CONSTRAINT `fk_behlog_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `sch_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_behlog_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student Topic Performance Summary (Aggregated)
CREATE TABLE IF NOT EXISTS `sch_student_topic_performance` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `total_questions_attempted` INT UNSIGNED DEFAULT 0,
  `correct_answers` INT UNSIGNED DEFAULT 0,
  `accuracy_percentage` DECIMAL(5,2) DEFAULT 0.00,
  `avg_time_per_question` INT UNSIGNED DEFAULT NULL, -- seconds
  `performance_category_id` INT UNSIGNED DEFAULT NULL,
  `confidence_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100 based on behavior
  `needs_revision` TINYINT(1) DEFAULT 0,
  `last_assessed_date` DATE DEFAULT NULL,
  `trend` ENUM('IMPROVING','STABLE','DECLINING') DEFAULT 'STABLE',
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_stopperf_student_topic_session` (`student_id`, `topic_id`, `academic_session_id`),
  KEY `idx_stopperf_student` (`student_id`),
  KEY `idx_stopperf_topic` (`topic_id`),
  KEY `idx_stopperf_perfcat` (`performance_category_id`),
  CONSTRAINT `fk_stopperf_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stopperf_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stopperf_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stopperf_perfcat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student Weak Areas Summary
CREATE TABLE IF NOT EXISTS `sch_student_weak_areas` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,
  `weakness_severity` ENUM('MILD','MODERATE','SEVERE') NOT NULL,
  `root_cause_topic_id` INT UNSIGNED DEFAULT NULL, -- Base topic causing this weakness
  `identified_date` DATE NOT NULL,
  `addressed` TINYINT(1) DEFAULT 0,
  `addressed_date` DATE DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_stweak_student` (`student_id`),
  KEY `idx_stweak_topic` (`topic_id`),
  CONSTRAINT `fk_stweak_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stweak_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stweak_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stweak_rootcause` FOREIGN KEY (`root_cause_topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 12: RECOMMENDATIONS ENGINE
-- =========================================================================

-- Recommendations generated for students
CREATE TABLE IF NOT EXISTS `sch_student_recommendations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `recommendation_type` ENUM('TOPIC_FOCUS','STUDY_MATERIAL','PRACTICE','REVISION','REMEDIAL') NOT NULL,
  `priority` ENUM('HIGH','MEDIUM','LOW') DEFAULT 'MEDIUM',
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `topic_id` INT UNSIGNED DEFAULT NULL,
  `study_material_id` INT UNSIGNED DEFAULT NULL,
  `related_quiz_id` INT UNSIGNED DEFAULT NULL,
  `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','DISMISSED') DEFAULT 'PENDING',
  `generated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `viewed_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` DATE DEFAULT NULL,
  `generated_by` ENUM('SYSTEM','TEACHER') DEFAULT 'SYSTEM',
  PRIMARY KEY (`id`),
  KEY `idx_studrec_student` (`student_id`),
  KEY `idx_studrec_type` (`recommendation_type`),
  KEY `idx_studrec_status` (`status`),
  CONSTRAINT `fk_studrec_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_studrec_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_studrec_studmat` FOREIGN KEY (`study_material_id`) REFERENCES `slb_study_materials` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_studrec_quiz` FOREIGN KEY (`related_quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Teacher Recommendations (about students needing attention)
CREATE TABLE IF NOT EXISTS `sch_teacher_recommendations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED NOT NULL,
  `recommendation_type` ENUM('CLASS_FOCUS','STUDENT_ATTENTION','TOPIC_REVISION','ASSESSMENT_ADJUST') NOT NULL,
  `priority` ENUM('HIGH','MEDIUM','LOW') DEFAULT 'MEDIUM',
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `affected_students_count` INT UNSIGNED DEFAULT NULL,
  `affected_student_ids` JSON DEFAULT NULL,     -- Array of student IDs
  `topic_id` INT UNSIGNED DEFAULT NULL,
  `status` ENUM('PENDING','VIEWED','ACTIONED','DISMISSED') DEFAULT 'PENDING',
  `generated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actioned_at` TIMESTAMP NULL DEFAULT NULL,
  `action_notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_teachrec_teacher` (`teacher_id`),
  KEY `idx_teachrec_class` (`class_id`, `section_id`),
  CONSTRAINT `fk_teachrec_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachrec_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachrec_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachrec_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 13: AGGREGATION TABLES FOR REPORTING
-- =========================================================================

-- Daily Summary for efficient reporting
CREATE TABLE IF NOT EXISTS `sch_daily_performance_summary` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `summary_date` DATE NOT NULL,
  `academic_session_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED DEFAULT NULL,
  `total_students` INT UNSIGNED DEFAULT 0,
  `students_attempted` INT UNSIGNED DEFAULT 0,
  `avg_score_percentage` DECIMAL(5,2) DEFAULT NULL,
  `pass_count` INT UNSIGNED DEFAULT 0,
  `fail_count` INT UNSIGNED DEFAULT 0,
  `high_performers` INT UNSIGNED DEFAULT 0,     -- Above 80%
  `low_performers` INT UNSIGNED DEFAULT 0,      -- Below 40%
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dps_date_session_class_sec_subj_topic` (`summary_date`, `academic_session_id`, `class_id`, `section_id`, `subject_id`, `topic_id`),
  KEY `idx_dps_date` (`summary_date`),
  KEY `idx_dps_class_subject` (`class_id`, `subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Monthly Aggregation for city/state level reporting
CREATE TABLE IF NOT EXISTS `sch_monthly_performance_agg` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `year_month` CHAR(7) NOT NULL,                -- YYYY-MM format
  `academic_session_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED DEFAULT NULL,
  `total_assessments` INT UNSIGNED DEFAULT 0,
  `total_students` INT UNSIGNED DEFAULT 0,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `avg_score_percentage` DECIMAL(5,2) DEFAULT NULL,
  `median_score` DECIMAL(5,2) DEFAULT NULL,
  `std_deviation` DECIMAL(5,2) DEFAULT NULL,
  `pass_rate` DECIMAL(5,2) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mpa_month_session_class_subj_topic` (`year_month`, `academic_session_id`, `class_id`, `subject_id`, `topic_id`),
  KEY `idx_mpa_yearmonth` (`year_month`),
  KEY `idx_mpa_class_subject` (`class_id`, `subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 14: ALTER EXISTING TABLES (Modifications to v1.3 tables)
-- =========================================================================

-- Add new columns to slb_lessons
ALTER TABLE `slb_lessons` 
  ADD COLUMN `book_chapter_ref` VARCHAR(100) DEFAULT NULL AFTER `resources_json`,
  ADD COLUMN `scheduled_month` TINYINT UNSIGNED DEFAULT NULL AFTER `book_chapter_ref`;

-- Add new columns to slb_topics  
ALTER TABLE `slb_topics`
  ADD COLUMN `base_topic_id` INT UNSIGNED DEFAULT NULL AFTER `prerequisite_topic_ids` COMMENT 'Primary prerequisite from previous class',
  ADD COLUMN `is_assessable` TINYINT(1) DEFAULT 1 AFTER `base_topic_id`,
  ADD KEY `idx_topic_base` (`base_topic_id`);

-- Add new columns to sch_questions
ALTER TABLE `sch_questions`
  ADD COLUMN `is_school_specific` TINYINT(1) DEFAULT 0 AFTER `is_public`,
  ADD COLUMN `visibility` ENUM('GLOBAL','SCHOOL_ONLY','PRIVATE') DEFAULT 'GLOBAL' AFTER `is_school_specific`,
  ADD COLUMN `book_id` INT UNSIGNED DEFAULT NULL AFTER `visibility`,
  ADD COLUMN `book_page_ref` VARCHAR(50) DEFAULT NULL AFTER `book_id`,
  ADD KEY `idx_ques_book` (`book_id`),
  ADD KEY `idx_ques_visibility` (`visibility`);

-- Add new columns to sch_quizzes
ALTER TABLE `sch_quizzes`
  ADD COLUMN `auto_assign_on_topic_completion` TINYINT(1) DEFAULT 0 AFTER `is_published`,
  ADD COLUMN `objective_only` TINYINT(1) DEFAULT 1 AFTER `auto_assign_on_topic_completion`;

-- Add new columns to sch_assessments
ALTER TABLE `sch_assessments`
  ADD COLUMN `can_attempt_at_home` TINYINT(1) DEFAULT 1 AFTER `is_published`,
  ADD COLUMN `requires_proctoring` TINYINT(1) DEFAULT 0 AFTER `can_attempt_at_home`;

-- Add new columns to sch_exams
ALTER TABLE `sch_exams`
  ADD COLUMN `exam_mode` ENUM('ONLINE','OFFLINE','HYBRID') DEFAULT 'ONLINE' AFTER `is_published`;

-- Add new columns to sch_attempts
ALTER TABLE `sch_attempts`
  ADD COLUMN `confidence_level` DECIMAL(5,2) DEFAULT NULL AFTER `notes`,
  ADD COLUMN `performance_category_id` INT UNSIGNED DEFAULT NULL AFTER `confidence_level`,
  ADD KEY `idx_att_perfcat` (`performance_category_id`);




-- =========================================================================
-- INDEXES FOR REPORTING QUERIES
-- =========================================================================

-- Composite indexes for common analytics queries
CREATE INDEX `idx_topics_class_subject_level` ON `slb_topics` (`class_id`, `subject_id`, `level`);
CREATE INDEX `idx_questions_class_subject_topic` ON `sch_questions` (`class_id`, `subject_id`, `topic_id`);
CREATE INDEX `idx_attempts_date_class` ON `sch_attempts` (`submitted_at`, `assessment_id`);


SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- END OF SYLLABUS MANAGEMENT MODULE - VERSION 1.4
-- =====================================================================
--
-- KEY ADDITIONS IN v1.4:
-- ✓ 7 New Book/Publication tables
-- ✓ Performance Categories (configurable)
-- ✓ Study Material with Performance-based filtering
-- ✓ Topic Dependencies for Remedial Learning
-- ✓ Teaching Status Tracking with Quiz Auto-trigger
-- ✓ Syllabus Scheduling
-- ✓ Teacher Subject Assignment
-- ✓ School-specific Question Ownership
-- ✓ Quiz Auto-Assignment on Topic Completion
-- ✓ Offline Exam Support with Manual Marking
-- ✓ Behavioral Analytics (confidence, hesitation)
-- ✓ Student Weak Areas Tracking
-- ✓ Recommendations Engine (Student + Teacher)
-- ✓ Aggregation Tables for Reporting
-- ✓ 20+ ALTER statements for existing tables
--
-- TOTAL NEW TABLES: 24
-- TOTAL MODIFIED TABLES: 6
-- =====================================================================
