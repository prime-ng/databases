

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

