-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 2.0
-- FILE 3: ASSESSMENT ENGINE (Quizzes, Assessments, Exams)
-- =====================================================================

-- -------------------------------------------------------------------------
-- SECTION 1: UNIFIED ASSESSMENT TABLE
-- -------------------------------------------------------------------------
-- Single table for all assessment types with type discriminator
-- This simplifies assignment and attempt tracking

CREATE TABLE IF NOT EXISTS `asm_assessments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `uuid` CHAR(36) NOT NULL,
  
  -- Classification
  `assessment_type` ENUM('QUIZ', 'ASSESSMENT', 'EXAM') NOT NULL,
  `sub_type` ENUM(
    'PRACTICE', 'DIAGNOSTIC', 'REINFORCEMENT',     -- Quiz sub-types
    'FORMATIVE', 'SUMMATIVE', 'TERM', 'PERIODIC',  -- Assessment sub-types
    'UNIT', 'MIDTERM', 'FINAL', 'BOARD', 'MOCK'    -- Exam sub-types
  ) NOT NULL,
  `mode` ENUM('ONLINE', 'OFFLINE', 'HYBRID') NOT NULL DEFAULT 'ONLINE',
  
  -- Basic info
  `code` VARCHAR(30) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `short_name` VARCHAR(50) DEFAULT NULL,
  `description` TEXT DEFAULT NULL,
  `instructions` TEXT DEFAULT NULL,
  
  -- Academic context
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `lesson_id` BIGINT UNSIGNED DEFAULT NULL,       -- If assessment is lesson-specific
  
  -- Scheduling
  `scheduled_date` DATE DEFAULT NULL,
  `start_datetime` DATETIME DEFAULT NULL,
  `end_datetime` DATETIME DEFAULT NULL,
  `duration_minutes` INT UNSIGNED NOT NULL,
  `buffer_minutes` INT UNSIGNED DEFAULT 0,        -- Extra time for late start
  
  -- Scoring
  `total_marks` DECIMAL(7,2) NOT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `passing_percent` DECIMAL(5,2) DEFAULT NULL,
  `negative_marking_enabled` TINYINT(1) DEFAULT 0,
  `negative_marking_percent` DECIMAL(5,2) DEFAULT NULL,
  
  -- Question distribution (NEP 2020 Blueprint)
  `blueprint` JSON DEFAULT NULL,                  -- Bloom level distribution, complexity mix
  
  -- Settings
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_question_palette` TINYINT(1) DEFAULT 1,
  `allow_navigation` TINYINT(1) DEFAULT 1,
  `allow_review_before_submit` TINYINT(1) DEFAULT 1,
  `allow_skip` TINYINT(1) DEFAULT 1,
  `show_timer` TINYINT(1) DEFAULT 1,
  `auto_submit_on_timeout` TINYINT(1) DEFAULT 1,
  
  -- Result display
  `show_result_immediately` TINYINT(1) DEFAULT 0,
  `show_answers_after` ENUM('IMMEDIATE', 'AFTER_DEADLINE', 'AFTER_GRADING', 'NEVER') DEFAULT 'AFTER_GRADING',
  `show_correct_answers` TINYINT(1) DEFAULT 0,
  `show_explanation` TINYINT(1) DEFAULT 0,
  `show_peer_comparison` TINYINT(1) DEFAULT 0,
  
  -- Attempt settings
  `max_attempts` INT UNSIGNED DEFAULT 1,
  `cooldown_hours` INT UNSIGNED DEFAULT 0,        -- Time between attempts
  `grade_method` ENUM('HIGHEST', 'LATEST', 'AVERAGE', 'FIRST') DEFAULT 'HIGHEST',
  
  -- Proctoring (for online exams)
  `proctoring_enabled` TINYINT(1) DEFAULT 0,
  `webcam_required` TINYINT(1) DEFAULT 0,
  `full_screen_required` TINYINT(1) DEFAULT 0,
  `copy_paste_disabled` TINYINT(1) DEFAULT 1,
  
  -- Status
  `status` ENUM('DRAFT', 'READY', 'PUBLISHED', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `published_at` TIMESTAMP NULL DEFAULT NULL,
  
  -- Audit
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `updated_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_assessment_uuid` (`uuid`),
  UNIQUE KEY `uq_assessment_code` (`tenant_id`, `code`),
  KEY `idx_assessment_tenant` (`tenant_id`),
  KEY `idx_assessment_type` (`assessment_type`, `sub_type`),
  KEY `idx_assessment_class_subject` (`class_id`, `subject_id`),
  KEY `idx_assessment_status` (`status`),
  KEY `idx_assessment_date` (`scheduled_date`),
  CONSTRAINT `fk_assessment_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_assessment_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_assessment_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_assessment_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `syl_lessons` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 2: ASSESSMENT SECTIONS (For multi-part assessments)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_assessment_sections` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` TINYINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `instructions` TEXT DEFAULT NULL,
  `section_marks` DECIMAL(7,2) DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,   -- Section-specific time limit
  `question_count` INT UNSIGNED DEFAULT NULL,
  `mandatory_count` INT UNSIGNED DEFAULT NULL,    -- Min questions to attempt
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_section_ordinal` (`assessment_id`, `ordinal`),
  KEY `idx_section_assessment` (`assessment_id`),
  CONSTRAINT `fk_section_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 3: ASSESSMENT ITEMS (Questions in Assessment)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_assessment_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `section_id` BIGINT UNSIGNED DEFAULT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` SMALLINT UNSIGNED NOT NULL,
  `marks` DECIMAL(6,2) NOT NULL,
  `negative_marks` DECIMAL(6,2) DEFAULT 0.00,
  `is_mandatory` TINYINT(1) DEFAULT 1,
  `shuffle_options` TINYINT(1) DEFAULT NULL,      -- Override assessment setting
  `show_explanation` TINYINT(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_item_ordinal` (`assessment_id`, `section_id`, `ordinal`),
  KEY `idx_item_assessment` (`assessment_id`),
  KEY `idx_item_question` (`question_id`),
  CONSTRAINT `fk_item_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_section` FOREIGN KEY (`section_id`) REFERENCES `asm_assessment_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 4: TOPIC-QUIZ LINKING (Auto-assignment trigger)
-- -------------------------------------------------------------------------
-- Links quizzes to topics so that when teacher marks topic complete,
-- the linked quiz is automatically assigned to students

CREATE TABLE IF NOT EXISTS `asm_topic_assessment_link` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `trigger_on` ENUM('TOPIC_COMPLETE', 'MANUAL', 'SCHEDULED') NOT NULL DEFAULT 'TOPIC_COMPLETE',
  `delay_hours` INT UNSIGNED DEFAULT 0,           -- Delay after trigger
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_assessment` (`tenant_id`, `topic_id`, `assessment_id`),
  KEY `idx_tal_topic` (`topic_id`),
  KEY `idx_tal_assessment` (`assessment_id`),
  CONSTRAINT `fk_tal_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tal_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 5: ASSESSMENT ASSIGNMENTS (To Sections/Students)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  
  -- Assignment target (polymorphic)
  `assigned_to_type` ENUM('SECTION', 'STUDENT', 'SUBJECT_GROUP', 'CUSTOM_GROUP') NOT NULL,
  `assigned_to_id` BIGINT UNSIGNED NOT NULL,
  
  -- Availability window
  `available_from` DATETIME NOT NULL,
  `available_to` DATETIME NOT NULL,
  
  -- Override settings
  `max_attempts` INT UNSIGNED DEFAULT NULL,
  `extra_time_minutes` INT UNSIGNED DEFAULT 0,    -- Accommodation for special needs
  `extra_time_percent` DECIMAL(5,2) DEFAULT 0,
  
  -- Trigger info
  `trigger_type` ENUM('MANUAL', 'TOPIC_COMPLETE', 'SCHEDULED', 'PREREQUISITE') NOT NULL DEFAULT 'MANUAL',
  `triggered_by_topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `trigger_timestamp` TIMESTAMP NULL DEFAULT NULL,
  
  `is_visible` TINYINT(1) DEFAULT 1,
  `notification_sent` TINYINT(1) DEFAULT 0,
  `notification_sent_at` TIMESTAMP NULL DEFAULT NULL,
  
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_assign_assessment` (`assessment_id`),
  KEY `idx_assign_target` (`assigned_to_type`, `assigned_to_id`),
  KEY `idx_assign_availability` (`available_from`, `available_to`),
  KEY `idx_assign_trigger` (`triggered_by_topic_id`),
  CONSTRAINT `fk_assign_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_assign_trigger_topic` FOREIGN KEY (`triggered_by_topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 6: TOPIC TEACHING STATUS (Teacher Progress Tracking)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_topic_teaching_status` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `class_section_id` INT UNSIGNED NOT NULL,       -- FK to sch_class_section_jnt
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  
  -- Status tracking
  `status` ENUM('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'REVISION') NOT NULL DEFAULT 'NOT_STARTED',
  `completion_percent` DECIMAL(5,2) DEFAULT 0.00,
  
  -- Dates
  `planned_start_date` DATE DEFAULT NULL,
  `actual_start_date` DATE DEFAULT NULL,
  `planned_end_date` DATE DEFAULT NULL,
  `actual_end_date` DATE DEFAULT NULL,
  
  -- Teaching details
  `periods_planned` SMALLINT UNSIGNED DEFAULT NULL,
  `periods_taken` SMALLINT UNSIGNED DEFAULT 0,
  `notes` TEXT DEFAULT NULL,
  
  -- Completion trigger
  `marked_complete_at` TIMESTAMP NULL DEFAULT NULL,
  `marked_complete_by` BIGINT UNSIGNED DEFAULT NULL,
  `auto_assign_triggered` TINYINT(1) DEFAULT 0,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teaching_status` (`tenant_id`, `academic_session_id`, `topic_id`, `class_section_id`),
  KEY `idx_teaching_topic` (`topic_id`),
  KEY `idx_teaching_section` (`class_section_id`),
  KEY `idx_teaching_teacher` (`teacher_id`),
  KEY `idx_teaching_status` (`status`),
  CONSTRAINT `fk_teaching_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teaching_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teaching_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 7: ASSESSMENT ELIGIBILITY RULES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_eligibility_rules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `rule_type` ENUM(
    'ATTENDANCE_MIN',           -- Min attendance %
    'PREV_SCORE_MIN',           -- Min score in previous assessment
    'PREREQUISITE_COMPLETE',    -- Must complete prerequisite assessment
    'TOPIC_COMPLETE',           -- Topic must be marked complete
    'TIME_WINDOW',              -- Only during specific hours
    'DEVICE_TYPE',              -- Allowed devices
    'IP_RESTRICTED',            -- Allowed IP ranges
    'ACCOMMODATION'             -- Special needs accommodation
  ) NOT NULL,
  `rule_config` JSON NOT NULL,                    -- Rule-specific configuration
  `error_message` VARCHAR(255) DEFAULT NULL,
  `is_blocking` TINYINT(1) DEFAULT 1,             -- Block if not met
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rule_assessment` (`assessment_id`),
  CONSTRAINT `fk_rule_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- END OF FILE 3: ASSESSMENT ENGINE
-- =====================================================================
