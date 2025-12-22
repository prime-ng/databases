-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 2.0
-- FILE 4: STUDENT ATTEMPTS & BEHAVIORAL TRACKING
-- =====================================================================

-- -------------------------------------------------------------------------
-- SECTION 1: STUDENT ATTEMPTS (Main attempt record)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_student_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `uuid` CHAR(36) NOT NULL,
  
  -- References
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `assignment_id` BIGINT UNSIGNED DEFAULT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `attempt_number` INT UNSIGNED NOT NULL DEFAULT 1,
  
  -- Session tracking
  `session_id` VARCHAR(64) DEFAULT NULL,          -- Browser session
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(500) DEFAULT NULL,
  `device_type` ENUM('DESKTOP', 'LAPTOP', 'TABLET', 'MOBILE', 'UNKNOWN') DEFAULT 'UNKNOWN',
  `browser` VARCHAR(50) DEFAULT NULL,
  `os` VARCHAR(50) DEFAULT NULL,
  `screen_resolution` VARCHAR(20) DEFAULT NULL,
  
  -- Timing
  `started_at` DATETIME NOT NULL,
  `last_activity_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `auto_submitted` TINYINT(1) DEFAULT 0,          -- System auto-submit on timeout
  
  -- Time tracking
  `time_allowed_seconds` INT UNSIGNED NOT NULL,
  `time_taken_seconds` INT UNSIGNED DEFAULT NULL,
  `time_active_seconds` INT UNSIGNED DEFAULT NULL, -- Actual active time (excluding idle)
  `pause_count` INT UNSIGNED DEFAULT 0,
  `total_pause_seconds` INT UNSIGNED DEFAULT 0,
  
  -- Navigation tracking
  `total_questions` INT UNSIGNED NOT NULL,
  `questions_attempted` INT UNSIGNED DEFAULT 0,
  `questions_skipped` INT UNSIGNED DEFAULT 0,
  `questions_marked_review` INT UNSIGNED DEFAULT 0,
  `questions_revisited` INT UNSIGNED DEFAULT 0,
  
  -- Scoring
  `status` ENUM('NOT_STARTED', 'IN_PROGRESS', 'SUBMITTED', 'GRADING', 'GRADED', 'CANCELLED', 'EXPIRED') NOT NULL DEFAULT 'IN_PROGRESS',
  `total_marks_possible` DECIMAL(8,2) NOT NULL,
  `marks_obtained` DECIMAL(8,2) DEFAULT 0.00,
  `marks_auto_graded` DECIMAL(8,2) DEFAULT 0.00,
  `marks_manual_graded` DECIMAL(8,2) DEFAULT 0.00,
  `negative_marks_applied` DECIMAL(8,2) DEFAULT 0.00,
  `final_score` DECIMAL(8,2) DEFAULT 0.00,
  `percentage_score` DECIMAL(5,2) DEFAULT 0.00,
  `grade` VARCHAR(5) DEFAULT NULL,
  `rank` INT UNSIGNED DEFAULT NULL,
  `percentile` DECIMAL(5,2) DEFAULT NULL,
  
  -- Pass/Fail
  `is_passed` TINYINT(1) DEFAULT NULL,
  `passing_marks` DECIMAL(8,2) DEFAULT NULL,
  
  -- Grading
  `grading_status` ENUM('PENDING', 'PARTIAL', 'COMPLETE') DEFAULT 'PENDING',
  `graded_by` BIGINT UNSIGNED DEFAULT NULL,
  `graded_at` DATETIME DEFAULT NULL,
  `grader_notes` TEXT DEFAULT NULL,
  
  -- Behavioral flags
  `integrity_score` DECIMAL(5,2) DEFAULT 100.00,  -- % integrity based on behavior
  `violation_count` INT UNSIGNED DEFAULT 0,
  `is_flagged` TINYINT(1) DEFAULT 0,
  `flag_reason` VARCHAR(255) DEFAULT NULL,
  
  -- Confidence metrics (calculated)
  `avg_confidence_score` DECIMAL(5,2) DEFAULT NULL,
  `time_efficiency_score` DECIMAL(5,2) DEFAULT NULL,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_attempt_uuid` (`uuid`),
  UNIQUE KEY `uq_student_attempt` (`assessment_id`, `student_id`, `attempt_number`),
  KEY `idx_attempt_tenant` (`tenant_id`),
  KEY `idx_attempt_student` (`student_id`),
  KEY `idx_attempt_status` (`status`),
  KEY `idx_attempt_submitted` (`submitted_at`),
  KEY `idx_attempt_assessment_status` (`assessment_id`, `status`),
  CONSTRAINT `fk_attempt_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `asm_assessments` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_attempt_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `asm_assignments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_attempt_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_attempt_grader` FOREIGN KEY (`graded_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 2: STUDENT RESPONSES (Per-question responses)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_student_responses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `assessment_item_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  
  -- Response data
  `response_type` ENUM('OPTION', 'TEXT', 'NUMERIC', 'FILE', 'MULTIPLE', 'MATCH') NOT NULL,
  `selected_option_ids` JSON DEFAULT NULL,        -- For MCQ: [1,3,4]
  `answer_text` TEXT DEFAULT NULL,                -- For subjective/numeric
  `answer_numeric` DECIMAL(20,6) DEFAULT NULL,    -- For pure numeric
  `answer_file_path` VARCHAR(500) DEFAULT NULL,   -- For file upload
  `match_pairs` JSON DEFAULT NULL,                -- For match type: {"A":"1","B":"3"}
  
  -- Timing
  `first_viewed_at` DATETIME DEFAULT NULL,
  `first_answered_at` DATETIME DEFAULT NULL,
  `last_modified_at` DATETIME DEFAULT NULL,
  `time_spent_seconds` INT UNSIGNED DEFAULT 0,
  `time_to_first_answer_seconds` INT UNSIGNED DEFAULT NULL,
  
  -- Navigation behavior
  `view_count` INT UNSIGNED DEFAULT 1,
  `answer_change_count` INT UNSIGNED DEFAULT 0,
  `marked_for_review` TINYINT(1) DEFAULT 0,
  `was_skipped` TINYINT(1) DEFAULT 0,
  `visited_after_answer` TINYINT(1) DEFAULT 0,
  
  -- Grading
  `is_correct` TINYINT(1) DEFAULT NULL,
  `is_partially_correct` TINYINT(1) DEFAULT 0,
  `correctness_percent` DECIMAL(5,2) DEFAULT NULL,
  `marks_possible` DECIMAL(6,2) NOT NULL,
  `marks_awarded` DECIMAL(6,2) DEFAULT 0.00,
  `negative_marks_applied` DECIMAL(6,2) DEFAULT 0.00,
  `auto_graded` TINYINT(1) DEFAULT 0,
  `manual_graded` TINYINT(1) DEFAULT 0,
  `grader_feedback` TEXT DEFAULT NULL,
  
  -- Confidence metrics
  `time_ratio` DECIMAL(5,2) DEFAULT NULL,         -- time_spent / estimated_time
  `hesitation_score` DECIMAL(5,2) DEFAULT NULL,   -- Based on answer changes
  `confidence_indicator` ENUM('HIGH', 'MEDIUM', 'LOW', 'GUESS') DEFAULT NULL,
  
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_response_attempt_item` (`attempt_id`, `assessment_item_id`),
  KEY `idx_response_attempt` (`attempt_id`),
  KEY `idx_response_question` (`question_id`),
  KEY `idx_response_correct` (`is_correct`),
  CONSTRAINT `fk_response_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `asm_student_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_response_item` FOREIGN KEY (`assessment_item_id`) REFERENCES `asm_assessment_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_response_question` FOREIGN KEY (`question_id`) REFERENCES `qb_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 3: RESPONSE HISTORY (Answer change tracking)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_response_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `response_id` BIGINT UNSIGNED NOT NULL,
  `change_number` INT UNSIGNED NOT NULL,
  `previous_response` JSON DEFAULT NULL,          -- Previous answer state
  `new_response` JSON NOT NULL,                   -- New answer state
  `changed_at` DATETIME NOT NULL,
  `time_since_start_seconds` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_history_response` (`response_id`),
  CONSTRAINT `fk_history_response` FOREIGN KEY (`response_id`) REFERENCES `asm_student_responses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 4: BEHAVIORAL EVENTS LOG
-- -------------------------------------------------------------------------
-- Captures all behavioral data for analytics and proctoring

CREATE TABLE IF NOT EXISTS `asm_behavioral_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `event_type` ENUM(
    -- Navigation events
    'QUESTION_VIEW', 'QUESTION_ANSWER', 'QUESTION_SKIP', 'QUESTION_MARK_REVIEW',
    'QUESTION_REVISIT', 'ANSWER_CHANGE', 'SECTION_CHANGE',
    -- Time events
    'PAUSE', 'RESUME', 'IDLE_DETECTED', 'TIME_WARNING',
    -- Window events
    'FOCUS_LOST', 'FOCUS_GAINED', 'TAB_SWITCH', 'WINDOW_BLUR',
    'FULLSCREEN_EXIT', 'FULLSCREEN_ENTER',
    -- Proctoring events
    'FACE_NOT_DETECTED', 'MULTIPLE_FACES', 'AUDIO_DETECTED',
    'SCREEN_SHARE_STARTED', 'SCREEN_SHARE_STOPPED',
    -- Violation events
    'COPY_ATTEMPT', 'PASTE_ATTEMPT', 'RIGHT_CLICK', 'KEYBOARD_SHORTCUT',
    'PRINT_ATTEMPT', 'SCREENSHOT_ATTEMPT',
    -- System events
    'CONNECTION_LOST', 'CONNECTION_RESTORED', 'AUTO_SAVE', 'SUBMIT',
    'AUTO_SUBMIT', 'ERROR'
  ) NOT NULL,
  `event_timestamp` DATETIME(3) NOT NULL,         -- Millisecond precision
  `event_data` JSON DEFAULT NULL,                 -- Event-specific data
  `question_id` BIGINT UNSIGNED DEFAULT NULL,
  `severity` ENUM('INFO', 'WARNING', 'CRITICAL') DEFAULT 'INFO',
  `client_timestamp` DATETIME(3) DEFAULT NULL,    -- Client-side timestamp
  PRIMARY KEY (`id`),
  KEY `idx_event_attempt` (`attempt_id`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_event_timestamp` (`event_timestamp`),
  KEY `idx_event_severity` (`severity`),
  CONSTRAINT `fk_event_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `asm_student_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 5: INTEGRITY VIOLATIONS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_integrity_violations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `violation_type` ENUM(
    'TAB_SWITCH', 'WINDOW_BLUR', 'COPY_PASTE', 'RIGHT_CLICK',
    'FULLSCREEN_EXIT', 'MULTIPLE_FACES', 'FACE_NOT_VISIBLE',
    'AUDIO_DETECTED', 'DEVICE_CHANGE', 'IP_CHANGE',
    'SUSPICIOUS_TIMING', 'ANSWER_PATTERN', 'OTHER'
  ) NOT NULL,
  `severity` ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
  `penalty_points` DECIMAL(5,2) DEFAULT 0.00,
  `description` VARCHAR(500) DEFAULT NULL,
  `evidence` JSON DEFAULT NULL,                   -- Screenshot URL, audio clip, etc.
  `reviewed` TINYINT(1) DEFAULT 0,
  `reviewed_by` BIGINT UNSIGNED DEFAULT NULL,
  `reviewed_at` DATETIME DEFAULT NULL,
  `action_taken` VARCHAR(255) DEFAULT NULL,
  `occurred_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_violation_attempt` (`attempt_id`),
  KEY `idx_violation_type` (`violation_type`),
  KEY `idx_violation_severity` (`severity`),
  CONSTRAINT `fk_violation_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `asm_student_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 6: SESSION SNAPSHOTS (Periodic state capture)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `asm_session_snapshots` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `snapshot_at` DATETIME NOT NULL,
  `elapsed_seconds` INT UNSIGNED NOT NULL,
  `questions_answered` INT UNSIGNED DEFAULT 0,
  `current_question_id` BIGINT UNSIGNED DEFAULT NULL,
  `response_state` JSON NOT NULL,                 -- All current responses
  `navigation_state` JSON DEFAULT NULL,           -- Current position, visited list
  `is_recovery_point` TINYINT(1) DEFAULT 0,       -- For session recovery
  PRIMARY KEY (`id`),
  KEY `idx_snapshot_attempt` (`attempt_id`),
  KEY `idx_snapshot_recovery` (`attempt_id`, `is_recovery_point`),
  CONSTRAINT `fk_snapshot_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `asm_student_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- END OF FILE 4: STUDENT ATTEMPTS & BEHAVIORAL TRACKING
-- =====================================================================
