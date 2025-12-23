-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT - ADDITIONAL FEATURES v1.4
-- SUGGESTED ENHANCEMENTS (Beyond Original Requirements)
-- =====================================================================
-- 
-- These tables provide additional functionality that enhances the core
-- syllabus module with advanced analytics, gamification, collaboration,
-- and AI-assisted features.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================================
-- SECTION 1: LEARNING PATHWAYS & ADAPTIVE CURRICULUM
-- =========================================================================

-- Custom learning paths for personalized education
CREATE TABLE IF NOT EXISTS `slb_learning_pathways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `pathway_type` ENUM('REMEDIAL','ENRICHMENT','STANDARD','ACCELERATED','SPECIAL_NEEDS') NOT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `target_performance_category_id` INT UNSIGNED DEFAULT NULL, -- Target student level
  `estimated_duration_days` INT UNSIGNED DEFAULT NULL,
  `is_ai_generated` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pathway_uuid` (`uuid`),
  KEY `idx_pathway_type` (`pathway_type`),
  KEY `idx_pathway_class_subject` (`class_id`, `subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Nodes within a learning pathway
CREATE TABLE IF NOT EXISTS `slb_learning_pathway_nodes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `pathway_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` SMALLINT UNSIGNED NOT NULL,
  `node_type` ENUM('TOPIC','QUIZ','STUDY_MATERIAL','ASSESSMENT','CHECKPOINT') NOT NULL,
  `reference_id` BIGINT UNSIGNED NOT NULL,  -- ID of topic/quiz/material based on type
  `is_mandatory` TINYINT(1) DEFAULT 1,
  `pass_criteria` JSON DEFAULT NULL,        -- {"min_score": 60, "max_attempts": 3}
  `estimated_minutes` INT UNSIGNED DEFAULT NULL,
  `unlock_condition` JSON DEFAULT NULL,     -- Conditions to unlock this node
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pathnode_pathway_ordinal` (`pathway_id`, `ordinal`),
  CONSTRAINT `fk_pathnode_pathway` FOREIGN KEY (`pathway_id`) REFERENCES `slb_learning_pathways` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student progress through learning pathways
CREATE TABLE IF NOT EXISTS `sch_student_pathway_progress` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `pathway_id` BIGINT UNSIGNED NOT NULL,
  `current_node_id` BIGINT UNSIGNED DEFAULT NULL,
  `status` ENUM('NOT_STARTED','IN_PROGRESS','PAUSED','COMPLETED','ABANDONED') DEFAULT 'NOT_STARTED',
  `started_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `total_time_spent_minutes` INT UNSIGNED DEFAULT 0,
  `nodes_completed` INT UNSIGNED DEFAULT 0,
  `overall_score` DECIMAL(5,2) DEFAULT NULL,
  `assigned_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_stpathprog_student_pathway` (`student_id`, `pathway_id`),
  CONSTRAINT `fk_stpathprog_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stpathprog_pathway` FOREIGN KEY (`pathway_id`) REFERENCES `slb_learning_pathways` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 2: GAMIFICATION & STUDENT ENGAGEMENT
-- =========================================================================

-- Achievement/Badge definitions
CREATE TABLE IF NOT EXISTS `sch_achievements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `badge_icon_url` VARCHAR(500) DEFAULT NULL,
  `category` ENUM('ACADEMIC','CONSISTENCY','IMPROVEMENT','SPEED','PARTICIPATION','SPECIAL') NOT NULL,
  `criteria` JSON NOT NULL,                 -- {"type": "score", "threshold": 90, "subject_id": 1}
  `points` INT UNSIGNED DEFAULT 0,
  `rarity` ENUM('COMMON','UNCOMMON','RARE','EPIC','LEGENDARY') DEFAULT 'COMMON',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_achievement_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student achievements earned
CREATE TABLE IF NOT EXISTS `sch_student_achievements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `achievement_id` BIGINT UNSIGNED NOT NULL,
  `earned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `context` JSON DEFAULT NULL,              -- What triggered this achievement
  `notified` TINYINT(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_stachieve_student_achievement` (`student_id`, `achievement_id`),
  CONSTRAINT `fk_stachieve_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stachieve_achievement` FOREIGN KEY (`achievement_id`) REFERENCES `sch_achievements` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Leaderboard snapshots (daily/weekly/monthly)
CREATE TABLE IF NOT EXISTS `sch_leaderboard_snapshots` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `snapshot_date` DATE NOT NULL,
  `period_type` ENUM('DAILY','WEEKLY','MONTHLY','TERM','YEARLY') NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `leaderboard_data` JSON NOT NULL,         -- [{student_id, rank, score, change}]
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_leaderboard_date_class` (`snapshot_date`, `class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student streaks (consecutive days of activity)
CREATE TABLE IF NOT EXISTS `sch_student_streaks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `streak_type` ENUM('LOGIN','QUIZ','STUDY','PRACTICE') NOT NULL,
  `current_streak` INT UNSIGNED DEFAULT 0,
  `longest_streak` INT UNSIGNED DEFAULT 0,
  `last_activity_date` DATE DEFAULT NULL,
  `streak_start_date` DATE DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ststreak_student_type` (`student_id`, `streak_type`),
  CONSTRAINT `fk_ststreak_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 3: PEER LEARNING & COLLABORATION
-- =========================================================================

-- Study groups
CREATE TABLE IF NOT EXISTS `sch_study_groups` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,    -- Teacher or Student
  `max_members` TINYINT UNSIGNED DEFAULT 10,
  `is_public` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_studygrp_class` (`class_id`, `section_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Study group members
CREATE TABLE IF NOT EXISTS `sch_study_group_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('LEADER','MEMBER') DEFAULT 'MEMBER',
  `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grpmember_group_student` (`group_id`, `student_id`),
  CONSTRAINT `fk_grpmember_group` FOREIGN KEY (`group_id`) REFERENCES `sch_study_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_grpmember_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Peer tutoring requests and matches
CREATE TABLE IF NOT EXISTS `sch_peer_tutoring` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requester_student_id` BIGINT UNSIGNED NOT NULL,
  `tutor_student_id` BIGINT UNSIGNED DEFAULT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `request_type` ENUM('HELP_NEEDED','CAN_HELP') NOT NULL,
  `status` ENUM('OPEN','MATCHED','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT 'OPEN',
  `description` VARCHAR(500) DEFAULT NULL,
  `matched_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `rating` TINYINT UNSIGNED DEFAULT NULL,   -- 1-5 rating
  `feedback` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_peertut_topic` (`topic_id`),
  KEY `idx_peertut_status` (`status`),
  CONSTRAINT `fk_peertut_requester` FOREIGN KEY (`requester_student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_peertut_tutor` FOREIGN KEY (`tutor_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_peertut_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 4: AI-ASSISTED QUESTION GENERATION
-- =========================================================================

-- AI question generation requests
CREATE TABLE IF NOT EXISTS `sch_ai_question_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requested_by` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `question_type_id` INT UNSIGNED NOT NULL,
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,
  `bloom_id` INT UNSIGNED DEFAULT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 5,
  `additional_instructions` TEXT DEFAULT NULL,
  `status` ENUM('PENDING','PROCESSING','COMPLETED','FAILED','REVIEW') DEFAULT 'PENDING',
  `ai_model_used` VARCHAR(50) DEFAULT NULL,
  `processing_started_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `error_message` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_aiqr_status` (`status`),
  KEY `idx_aiqr_topic` (`topic_id`),
  CONSTRAINT `fk_aiqr_user` FOREIGN KEY (`requested_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_aiqr_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI-generated questions pending review
CREATE TABLE IF NOT EXISTS `sch_ai_generated_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_id` BIGINT UNSIGNED NOT NULL,
  `question_data` JSON NOT NULL,            -- Full question structure
  `review_status` ENUM('PENDING','APPROVED','REJECTED','MODIFIED') DEFAULT 'PENDING',
  `reviewed_by` BIGINT UNSIGNED DEFAULT NULL,
  `reviewed_at` TIMESTAMP NULL DEFAULT NULL,
  `approved_question_id` BIGINT UNSIGNED DEFAULT NULL, -- If approved, link to sch_questions
  `rejection_reason` VARCHAR(255) DEFAULT NULL,
  `quality_score` DECIMAL(5,2) DEFAULT NULL, -- AI confidence score
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_aigenq_request` (`request_id`),
  KEY `idx_aigenq_status` (`review_status`),
  CONSTRAINT `fk_aigenq_request` FOREIGN KEY (`request_id`) REFERENCES `sch_ai_question_requests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 5: PARENT ENGAGEMENT & NOTIFICATIONS
-- =========================================================================

-- Parent notification preferences
CREATE TABLE IF NOT EXISTS `sch_parent_notification_prefs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED NOT NULL,     -- FK to sys_users (parent)
  `student_id` BIGINT UNSIGNED NOT NULL,
  `notify_quiz_assigned` TINYINT(1) DEFAULT 1,
  `notify_quiz_completed` TINYINT(1) DEFAULT 1,
  `notify_low_score` TINYINT(1) DEFAULT 1,
  `low_score_threshold` TINYINT UNSIGNED DEFAULT 40,
  `notify_weekly_summary` TINYINT(1) DEFAULT 1,
  `notify_missed_quiz` TINYINT(1) DEFAULT 1,
  `notify_achievement` TINYINT(1) DEFAULT 1,
  `preferred_channel` ENUM('EMAIL','SMS','PUSH','WHATSAPP') DEFAULT 'EMAIL',
  `quiet_hours_start` TIME DEFAULT NULL,
  `quiet_hours_end` TIME DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pnp_parent_student` (`parent_id`, `student_id`),
  CONSTRAINT `fk_pnp_parent` FOREIGN KEY (`parent_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pnp_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Parent activity log (what parents viewed)
CREATE TABLE IF NOT EXISTS `sch_parent_activity_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `activity_type` ENUM('VIEW_DASHBOARD','VIEW_REPORT','VIEW_QUIZ','VIEW_RECOMMENDATION','ACKNOWLEDGE_ALERT') NOT NULL,
  `reference_type` VARCHAR(50) DEFAULT NULL,
  `reference_id` BIGINT UNSIGNED DEFAULT NULL,
  `activity_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `device_info` JSON DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pal_parent_student` (`parent_id`, `student_id`),
  KEY `idx_pal_timestamp` (`activity_timestamp`),
  CONSTRAINT `fk_pal_parent` FOREIGN KEY (`parent_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pal_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 6: ASSESSMENT TEMPLATES & BLUEPRINTS
-- =========================================================================

-- Reusable assessment templates
CREATE TABLE IF NOT EXISTS `sch_assessment_templates` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `template_type` ENUM('QUIZ','ASSESSMENT','EXAM','HOMEWORK') NOT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `blueprint` JSON NOT NULL,                -- Structure definition
  -- Example: {"sections": [{"name": "Part A", "question_count": 10, "marks_each": 1, "complexity": "EASY"}]}
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `is_public` TINYINT(1) DEFAULT 0,         -- Shareable with other teachers
  `usage_count` INT UNSIGNED DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asstemp_type` (`template_type`),
  KEY `idx_asstemp_class_subject` (`class_id`, `subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Question paper blueprints (for board exam style papers)
CREATE TABLE IF NOT EXISTS `sch_question_paper_blueprints` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `board_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to glb_boards
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `academic_year` YEAR DEFAULT NULL,
  `paper_pattern` JSON NOT NULL,
  -- {"sections": [{"name": "Part A", "marks": 20, "complexity_distribution": {"EASY": 60, "MEDIUM": 30, "HARD": 10}}]}
  `total_marks` DECIMAL(7,2) NOT NULL,
  `duration_minutes` INT UNSIGNED NOT NULL,
  `is_board_pattern` TINYINT(1) DEFAULT 0,
  `source` VARCHAR(100) DEFAULT NULL,       -- e.g., "CBSE 2024", "Custom"
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_qpb_class_subject` (`class_id`, `subject_id`),
  CONSTRAINT `fk_qpb_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpb_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 7: QUESTION QUALITY & FEEDBACK
-- =========================================================================

-- Question feedback from students/teachers
CREATE TABLE IF NOT EXISTS `sch_question_feedback` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `user_type` ENUM('STUDENT','TEACHER') NOT NULL,
  `feedback_type` ENUM('DIFFICULTY','CLARITY','ERROR','SUGGESTION','APPRECIATION') NOT NULL,
  `rating` TINYINT UNSIGNED DEFAULT NULL,   -- 1-5
  `comment` VARCHAR(500) DEFAULT NULL,
  `is_resolved` TINYINT(1) DEFAULT 0,
  `resolved_by` BIGINT UNSIGNED DEFAULT NULL,
  `resolution_notes` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_qfb_question` (`question_id`),
  KEY `idx_qfb_type` (`feedback_type`),
  CONSTRAINT `fk_qfb_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qfb_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Question usage statistics
CREATE TABLE IF NOT EXISTS `sch_question_usage_stats` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `year_month` CHAR(7) NOT NULL,            -- YYYY-MM
  `times_used` INT UNSIGNED DEFAULT 0,
  `times_answered_correctly` INT UNSIGNED DEFAULT 0,
  `times_answered_incorrectly` INT UNSIGNED DEFAULT 0,
  `times_skipped` INT UNSIGNED DEFAULT 0,
  `avg_time_seconds` INT UNSIGNED DEFAULT NULL,
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qus_question_month` (`question_id`, `year_month`),
  CONSTRAINT `fk_qus_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 8: EXAM SCHEDULING & CALENDAR
-- =========================================================================

-- Academic calendar events (exams, holidays, etc.)
CREATE TABLE IF NOT EXISTS `sch_academic_calendar` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `event_type` ENUM('EXAM','QUIZ_WEEK','REVISION','HOLIDAY','PTM','ACTIVITY','OTHER') NOT NULL,
  `title` VARCHAR(150) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `class_ids` JSON DEFAULT NULL,            -- Applicable classes (NULL = all)
  `subject_ids` JSON DEFAULT NULL,          -- Applicable subjects (NULL = all)
  `is_school_wide` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_acal_dates` (`start_date`, `end_date`),
  KEY `idx_acal_type` (`event_type`),
  CONSTRAINT `fk_acal_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Exam seat allocation
CREATE TABLE IF NOT EXISTS `sch_exam_seat_allocation` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms
  `seat_number` VARCHAR(20) DEFAULT NULL,
  `row_number` TINYINT UNSIGNED DEFAULT NULL,
  `allocated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `allocated_by` BIGINT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_examseat_exam_student` (`exam_id`, `student_id`),
  UNIQUE KEY `uq_examseat_exam_room_seat` (`exam_id`, `room_id`, `seat_number`),
  CONSTRAINT `fk_examseat_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_examseat_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_examseat_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 9: ADVANCED ANALYTICS & PREDICTIONS
-- =========================================================================

-- Predicted performance scores
CREATE TABLE IF NOT EXISTS `sch_performance_predictions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `prediction_type` ENUM('TERM_END','ANNUAL','BOARD','TOPIC') NOT NULL,
  `reference_id` BIGINT UNSIGNED DEFAULT NULL, -- Topic ID if type=TOPIC
  `predicted_score` DECIMAL(5,2) NOT NULL,
  `confidence_level` DECIMAL(5,2) DEFAULT NULL, -- 0-100
  `prediction_factors` JSON DEFAULT NULL,   -- Contributing factors
  `prediction_date` DATE NOT NULL,
  `actual_score` DECIMAL(5,2) DEFAULT NULL, -- Filled after actual exam
  `accuracy` DECIMAL(5,2) DEFAULT NULL,     -- How accurate was prediction
  `model_version` VARCHAR(20) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_perfpred_student_subject` (`student_id`, `subject_id`),
  KEY `idx_perfpred_date` (`prediction_date`),
  CONSTRAINT `fk_perfpred_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_perfpred_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- At-risk student alerts
CREATE TABLE IF NOT EXISTS `sch_at_risk_alerts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `alert_type` ENUM('FAILING','DECLINING','DISENGAGED','ATTENDANCE','BEHAVIOR') NOT NULL,
  `severity` ENUM('LOW','MEDIUM','HIGH','CRITICAL') NOT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `alert_message` VARCHAR(500) NOT NULL,
  `supporting_data` JSON DEFAULT NULL,
  `status` ENUM('ACTIVE','ACKNOWLEDGED','RESOLVED','ESCALATED') DEFAULT 'ACTIVE',
  `generated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `acknowledged_by` BIGINT UNSIGNED DEFAULT NULL,
  `acknowledged_at` TIMESTAMP NULL DEFAULT NULL,
  `resolved_at` TIMESTAMP NULL DEFAULT NULL,
  `resolution_notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_atrisk_student` (`student_id`),
  KEY `idx_atrisk_severity` (`severity`),
  KEY `idx_atrisk_status` (`status`),
  CONSTRAINT `fk_atrisk_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 10: COMPARATIVE ANALYTICS (Cross-School)
-- =========================================================================

-- School comparison data (anonymized)
CREATE TABLE IF NOT EXISTS `sch_school_benchmark_data` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `year_month` CHAR(7) NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `school_avg_score` DECIMAL(5,2) DEFAULT NULL,
  `city_avg_score` DECIMAL(5,2) DEFAULT NULL,
  `state_avg_score` DECIMAL(5,2) DEFAULT NULL,
  `national_avg_score` DECIMAL(5,2) DEFAULT NULL,
  `school_percentile` DECIMAL(5,2) DEFAULT NULL,
  `sample_size_school` INT UNSIGNED DEFAULT NULL,
  `sample_size_city` INT UNSIGNED DEFAULT NULL,
  `sample_size_state` INT UNSIGNED DEFAULT NULL,
  `sample_size_national` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_benchmark_month_class_subj_topic` (`year_month`, `class_id`, `subject_id`, `topic_id`),
  KEY `idx_benchmark_class_subject` (`class_id`, `subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- END OF ADDITIONAL FEATURES v1.4
-- =====================================================================
--
-- TOTAL NEW TABLES: 24
--
-- SECTION 1: Learning Pathways (3 tables)
-- SECTION 2: Gamification (4 tables)
-- SECTION 3: Peer Learning (3 tables)
-- SECTION 4: AI Question Generation (2 tables)
-- SECTION 5: Parent Engagement (2 tables)
-- SECTION 6: Assessment Templates (2 tables)
-- SECTION 7: Question Quality (2 tables)
-- SECTION 8: Exam Scheduling (2 tables)
-- SECTION 9: Advanced Analytics (2 tables)
-- SECTION 10: Comparative Analytics (1 table)
--
-- These features can be implemented in phases:
-- Phase 1: Assessment Templates, Question Quality
-- Phase 2: Parent Engagement, Exam Scheduling
-- Phase 3: Gamification, Learning Pathways
-- Phase 4: AI Features, Advanced Analytics
-- Phase 5: Peer Learning, Comparative Analytics
-- =====================================================================
