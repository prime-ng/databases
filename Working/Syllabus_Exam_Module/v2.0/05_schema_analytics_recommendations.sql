-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 2.0
-- FILE 5: ANALYTICS, RECOMMENDATIONS & LEARNING OUTCOMES
-- =====================================================================

-- -------------------------------------------------------------------------
-- SECTION 1: STUDENT TOPIC MASTERY (Per-topic performance)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `anl_student_topic_mastery` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  
  -- Attempt statistics
  `total_questions_seen` INT UNSIGNED DEFAULT 0,
  `total_questions_attempted` INT UNSIGNED DEFAULT 0,
  `total_correct` INT UNSIGNED DEFAULT 0,
  `total_partial` INT UNSIGNED DEFAULT 0,
  `total_incorrect` INT UNSIGNED DEFAULT 0,
  
  -- Scoring
  `total_marks_possible` DECIMAL(10,2) DEFAULT 0.00,
  `total_marks_obtained` DECIMAL(10,2) DEFAULT 0.00,
  `avg_score_percent` DECIMAL(5,2) DEFAULT 0.00,
  
  -- Time analysis
  `total_time_spent_seconds` INT UNSIGNED DEFAULT 0,
  `avg_time_per_question_seconds` INT UNSIGNED DEFAULT NULL,
  `time_efficiency_score` DECIMAL(5,2) DEFAULT NULL,  -- Compared to estimated time
  
  -- Bloom level breakdown
  `bloom_remember_score` DECIMAL(5,2) DEFAULT NULL,
  `bloom_understand_score` DECIMAL(5,2) DEFAULT NULL,
  `bloom_apply_score` DECIMAL(5,2) DEFAULT NULL,
  `bloom_analyze_score` DECIMAL(5,2) DEFAULT NULL,
  `bloom_evaluate_score` DECIMAL(5,2) DEFAULT NULL,
  `bloom_create_score` DECIMAL(5,2) DEFAULT NULL,
  
  -- Complexity breakdown
  `easy_accuracy` DECIMAL(5,2) DEFAULT NULL,
  `medium_accuracy` DECIMAL(5,2) DEFAULT NULL,
  `hard_accuracy` DECIMAL(5,2) DEFAULT NULL,
  `challenge_accuracy` DECIMAL(5,2) DEFAULT NULL,
  
  -- Mastery indicators
  `mastery_level` ENUM('NOT_STARTED', 'BEGINNER', 'DEVELOPING', 'PROFICIENT', 'MASTERED') DEFAULT 'NOT_STARTED',
  `mastery_score` DECIMAL(5,2) DEFAULT 0.00,      -- 0-100 composite score
  `confidence_level` ENUM('LOW', 'MEDIUM', 'HIGH') DEFAULT NULL,
  `trend` ENUM('IMPROVING', 'STABLE', 'DECLINING', 'INSUFFICIENT_DATA') DEFAULT 'INSUFFICIENT_DATA',
  
  -- Gap analysis
  `is_weak_topic` TINYINT(1) DEFAULT 0,
  `needs_attention` TINYINT(1) DEFAULT 0,
  `weak_reason` JSON DEFAULT NULL,                -- Reasons for weakness
  
  -- Last activity
  `first_attempt_date` DATE DEFAULT NULL,
  `last_attempt_date` DATE DEFAULT NULL,
  `attempt_count` INT UNSIGNED DEFAULT 0,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_topic_session` (`tenant_id`, `student_id`, `topic_id`, `academic_session_id`),
  KEY `idx_mastery_student` (`student_id`),
  KEY `idx_mastery_topic` (`topic_id`),
  KEY `idx_mastery_weak` (`is_weak_topic`),
  KEY `idx_mastery_level` (`mastery_level`),
  KEY `idx_mastery_class_subject` (`class_id`, `subject_id`),
  CONSTRAINT `fk_mastery_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mastery_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 2: STUDENT COMPETENCY TRACKING
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `anl_student_competency_progress` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  
  -- Progress metrics
  `progress_percent` DECIMAL(5,2) DEFAULT 0.00,
  `proficiency_level` ENUM('NOVICE', 'BEGINNER', 'COMPETENT', 'PROFICIENT', 'EXPERT') DEFAULT 'NOVICE',
  `assessment_count` INT UNSIGNED DEFAULT 0,
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  
  -- Trend
  `trend` ENUM('IMPROVING', 'STABLE', 'DECLINING') DEFAULT NULL,
  `trend_data` JSON DEFAULT NULL,                 -- Last 5 scores for trend
  
  `last_assessed_date` DATE DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_competency` (`tenant_id`, `student_id`, `competency_id`, `academic_session_id`),
  KEY `idx_competency_progress_student` (`student_id`),
  KEY `idx_competency_progress_comp` (`competency_id`),
  CONSTRAINT `fk_cp_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cp_competency` FOREIGN KEY (`competency_id`) REFERENCES `syl_competencies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 3: PREREQUISITE GAP ANALYSIS
-- -------------------------------------------------------------------------
-- Tracks gaps in foundational topics that affect current performance

CREATE TABLE IF NOT EXISTS `anl_prerequisite_gaps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `current_topic_id` BIGINT UNSIGNED NOT NULL,    -- Topic student is struggling with
  `prerequisite_topic_id` BIGINT UNSIGNED NOT NULL, -- The missing foundation
  `prerequisite_class_id` INT UNSIGNED DEFAULT NULL, -- Class where prerequisite was taught
  
  -- Analysis
  `gap_severity` ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
  `gap_score` DECIMAL(5,2) NOT NULL,              -- 0-100 (higher = bigger gap)
  `correlation_strength` DECIMAL(4,2) DEFAULT NULL, -- How strongly prerequisite affects current
  
  -- Evidence
  `current_topic_accuracy` DECIMAL(5,2) DEFAULT NULL,
  `prerequisite_accuracy` DECIMAL(5,2) DEFAULT NULL,
  `pattern_description` TEXT DEFAULT NULL,        -- Explanation of the gap
  
  -- Status
  `is_addressed` TINYINT(1) DEFAULT 0,
  `addressed_at` DATETIME DEFAULT NULL,
  `remediation_provided` TINYINT(1) DEFAULT 0,
  
  `identified_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_prereq_gap` (`tenant_id`, `student_id`, `current_topic_id`, `prerequisite_topic_id`),
  KEY `idx_gap_student` (`student_id`),
  KEY `idx_gap_current_topic` (`current_topic_id`),
  KEY `idx_gap_prereq_topic` (`prerequisite_topic_id`),
  KEY `idx_gap_severity` (`gap_severity`),
  CONSTRAINT `fk_gap_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_gap_current` FOREIGN KEY (`current_topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_gap_prereq` FOREIGN KEY (`prerequisite_topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 4: STUDENT RECOMMENDATIONS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `anl_student_recommendations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `recommendation_type` ENUM(
    'FOCUS_TOPIC',            -- Focus on specific topic
    'PREREQUISITE_REVIEW',    -- Review prerequisite from previous class
    'PRACTICE_BLOOM_LEVEL',   -- Practice specific Bloom level
    'COMPLEXITY_ADJUSTMENT',  -- Try easier/harder questions
    'TIME_MANAGEMENT',        -- Time-related advice
    'LEARNING_RESOURCE',      -- Video/text resource
    'PRACTICE_SET',           -- Recommended practice questions
    'TEACHER_CONSULTATION',   -- Meet teacher
    'PEER_LEARNING',          -- Study group suggestion
    'GENERAL'                 -- General advice
  ) NOT NULL,
  
  -- Target
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `competency_id` BIGINT UNSIGNED DEFAULT NULL,
  
  -- Content
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `priority` ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT') NOT NULL DEFAULT 'MEDIUM',
  `action_items` JSON DEFAULT NULL,               -- Specific action steps
  
  -- Resources
  `resource_type` ENUM('TEXT', 'VIDEO', 'PRACTICE', 'EXTERNAL_LINK', 'DOCUMENT') DEFAULT NULL,
  `resource_url` VARCHAR(500) DEFAULT NULL,
  `resource_title` VARCHAR(255) DEFAULT NULL,
  `resource_duration_minutes` INT UNSIGNED DEFAULT NULL,
  
  -- Context
  `based_on_assessment_id` BIGINT UNSIGNED DEFAULT NULL,
  `trigger_reason` VARCHAR(500) DEFAULT NULL,
  
  -- Status
  `status` ENUM('PENDING', 'VIEWED', 'IN_PROGRESS', 'COMPLETED', 'DISMISSED') DEFAULT 'PENDING',
  `viewed_at` DATETIME DEFAULT NULL,
  `completed_at` DATETIME DEFAULT NULL,
  `feedback` TEXT DEFAULT NULL,
  `helpful_rating` TINYINT UNSIGNED DEFAULT NULL, -- 1-5 rating
  
  -- Validity
  `valid_from` DATETIME NOT NULL,
  `valid_until` DATETIME DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_rec_student` (`student_id`),
  KEY `idx_rec_type` (`recommendation_type`),
  KEY `idx_rec_priority` (`priority`),
  KEY `idx_rec_status` (`status`),
  KEY `idx_rec_topic` (`topic_id`),
  CONSTRAINT `fk_rec_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rec_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rec_competency` FOREIGN KEY (`competency_id`) REFERENCES `syl_competencies` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 5: TEACHER RECOMMENDATIONS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `anl_teacher_recommendations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  `class_section_id` INT UNSIGNED DEFAULT NULL,
  
  `recommendation_type` ENUM(
    'TOPIC_RETEACH',          -- Topic needs re-teaching
    'PACE_ADJUSTMENT',        -- Speed up or slow down
    'DIFFICULTY_MIX',         -- Adjust question difficulty
    'STUDENT_ATTENTION',      -- Specific students need help
    'ASSESSMENT_INSIGHT',     -- Assessment-related insight
    'RESOURCE_SUGGESTION',    -- Teaching material
    'INTERVENTION_NEEDED',    -- Group intervention
    'GENERAL'
  ) NOT NULL,
  
  -- Scope
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `student_ids` JSON DEFAULT NULL,                -- Array of student IDs if applicable
  
  -- Content
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `priority` ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT') NOT NULL DEFAULT 'MEDIUM',
  `supporting_data` JSON DEFAULT NULL,            -- Charts, stats that support recommendation
  
  -- Status
  `status` ENUM('PENDING', 'VIEWED', 'ACKNOWLEDGED', 'ACTIONED', 'DISMISSED') DEFAULT 'PENDING',
  `teacher_response` TEXT DEFAULT NULL,
  `actioned_at` DATETIME DEFAULT NULL,
  
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_trec_teacher` (`teacher_id`),
  KEY `idx_trec_section` (`class_section_id`),
  KEY `idx_trec_type` (`recommendation_type`),
  KEY `idx_trec_status` (`status`),
  CONSTRAINT `fk_trec_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_trec_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_trec_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 6: LEARNING RESOURCES LIBRARY
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `anl_learning_resources` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `uuid` CHAR(36) NOT NULL,
  
  -- Classification
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `competency_id` BIGINT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  
  -- Resource details
  `resource_type` ENUM('VIDEO', 'TEXT', 'PDF', 'INTERACTIVE', 'SIMULATION', 'AUDIO', 'EXTERNAL_LINK') NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `url` VARCHAR(500) NOT NULL,
  `thumbnail_url` VARCHAR(500) DEFAULT NULL,
  
  -- Metadata
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `difficulty_level` ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED') DEFAULT NULL,
  `language` VARCHAR(10) DEFAULT 'en',
  `source` VARCHAR(100) DEFAULT NULL,             -- NCERT, Khan Academy, etc.
  `tags` JSON DEFAULT NULL,
  
  -- Quality metrics
  `avg_rating` DECIMAL(3,2) DEFAULT NULL,
  `view_count` INT UNSIGNED DEFAULT 0,
  `completion_rate` DECIMAL(5,2) DEFAULT NULL,
  `helpfulness_score` DECIMAL(5,2) DEFAULT NULL,
  
  `is_active` TINYINT(1) DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_resource_uuid` (`uuid`),
  KEY `idx_resource_topic` (`topic_id`),
  KEY `idx_resource_subject` (`subject_id`),
  KEY `idx_resource_type` (`resource_type`),
  CONSTRAINT `fk_resource_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_resource_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 7: RESOURCE CONSUMPTION TRACKING
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `anl_resource_consumption` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `resource_id` BIGINT UNSIGNED NOT NULL,
  `recommendation_id` BIGINT UNSIGNED DEFAULT NULL,
  
  `started_at` DATETIME DEFAULT NULL,
  `completed_at` DATETIME DEFAULT NULL,
  `time_spent_seconds` INT UNSIGNED DEFAULT 0,
  `completion_percent` DECIMAL(5,2) DEFAULT 0.00,
  `rating` TINYINT UNSIGNED DEFAULT NULL,         -- 1-5
  `feedback` TEXT DEFAULT NULL,
  `was_helpful` TINYINT(1) DEFAULT NULL,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_consumption` (`student_id`, `resource_id`),
  KEY `idx_consumption_student` (`student_id`),
  KEY `idx_consumption_resource` (`resource_id`),
  CONSTRAINT `fk_consumption_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_consumption_resource` FOREIGN KEY (`resource_id`) REFERENCES `anl_learning_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- END OF FILE 5: ANALYTICS & RECOMMENDATIONS
-- =====================================================================
