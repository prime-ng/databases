

-- =========================================================================
-- STUDENT ATTEMPTS & RESULTS (Quiz, Quest, Online / Offline Exams)
-- =========================================================================


-- --------------------------------------------------------------------------------------
-- Student Attempts (Unified for Quiz & Quest)
-- --------------------------------------------------------------------------------------
-- Student Attempts
CREATE TABLE IF NOT EXISTS `lms_quiz_quest_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,            -- FK to sch_students.id
  `assessment_type` ENUM('QUIZ','QUEST') NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,         -- FK to lms_quizzes.id or lms_quests.id
  `allocation_id` BIGINT UNSIGNED DEFAULT NULL,     -- FK to lms_quiz_allocations.id or lms_quest_allocations.id
  `attempt_number` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` DATETIME DEFAULT NULL,
  `status` ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','TIMEOUT','ABANDONED','CANCELLED','REASSIGNED') NOT NULL DEFAULT 'NOT_STARTED',
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
-- Condition:
-- attemp_number will increase by 1 on every attempt


-- Attempt Answers
CREATE TABLE IF NOT EXISTS `lms_quiz_quest_attempt_answers` (
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
  CONSTRAINT `fk_ans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_quiz_quest_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ans_option` FOREIGN KEY (`selected_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- Student Attempts & Exam Record (Online & Offline Exams)
-- --------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,
  `exam_paper_id` BIGINT UNSIGNED NOT NULL,       -- FK to lms_exam_papers.id
  `paper_set_id` BIGINT UNSIGNED NOT NULL,        -- FK to lms_exam_paper_sets.id (The actual set assigned/taken)
  `allocation_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to lms_exam_allocations.id (Link to allocation rule)
  `student_id` BIGINT UNSIGNED NOT NULL,          -- FK to std_students.id (The student who took the exam)
  -- Timing
  `actual_started_time` DATETIME DEFAULT NULL,    -- Actual Exam Start Time
  `actual_end_time` DATETIME DEFAULT NULL,        -- Actual Exam End Time (The time when student submitted the exam)
  `actual_time_taken_seconds` INT UNSIGNED DEFAULT 0,
  -- Status
  `status_id` INT UNSIGNED NOT NULL DEFAULT 0,    -- FK to lms_exam_status_events.id (Status of the exam) 'NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED')
  `attempt_mode` ENUM('ONLINE', 'OFFLINE') NOT NULL,
  -- Offline Metadata
  `answer_sheet_number` VARCHAR(50) DEFAULT NULL, -- Physical sheet ID
  `is_present_offline` TINYINT(1) DEFAULT 1,      -- For attendance
  -- Online Metadata
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `device_info` JSON DEFAULT NULL,
  `violation_count` INT UNSIGNED DEFAULT 0,
  -- Audit
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_attempt_uuid` (`uuid`),
  UNIQUE KEY `uq_attempt_student_paper` (`exam_paper_id`, `student_id`),
  CONSTRAINT `fk_att_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`),
  CONSTRAINT `fk_att_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`),
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
  CONSTRAINT `fk_att_alloc` FOREIGN KEY (`allocation_id`) REFERENCES `lms_exam_allocations` (`id`),
  CONSTRAINT `fk_att_status` FOREIGN KEY (`status_id`) REFERENCES `lms_exam_status_events` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student Answers (Granular Data)
-- Used for Online Exams AND Offline Exams (if doing question-wise entry)
-- --------------------------------------------------------------------------------------
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
-- --------------------------------------------------------------------------------------
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
-- --------------------------------------------------------------------------------------
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
-- --------------------------------------------------------------------------------------
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
