-- =========================================================================
-- STUDENT ATTEMPTS & RESULTS — COMPLETE DDL
-- =========================================================================
-- File    : StudentAttempt_ddl_v3.sql
-- Database: tenant_db
-- Prefix  : lms_
-- Module  : StudentPortal — StudentAttempt Functionality
-- Scope   : Quiz Attempts · Quest Attempts · Exam Attempts (Online/Offline)
--           Results · Grievances · Activity Logs · Session Checkpoints
-- Version : v3 — Updated from v2
--           v2 Fixes: deduplicated tables, missing standard columns, FK refs,
--                     added quiz/quest result table, checkpoint/resume support,
--                     extended proctoring events, consistent index strategy
--           v3 Changes: replaced polymorphic assessment_id/allocation_id on
--                     lms_quiz_quest_attempts with explicit quiz_id, quest_id,
--                     quiz_allocation_id, quest_allocation_id + CHECK constraints;
--                     fixed G-06: replaced broken UNIQUE(assessment_id) with two
--                     separate UNIQUEs uq_qqat_student_quiz_attempt /
--                     uq_qqat_student_quest_attempt; fixed idx_qqat_assessment /
--                     idx_qqat_allocation index refs; fixed ConSTRAINT typo
-- Date    : 2026-04-02
-- =========================================================================

-- =========================================================================
-- DEPENDENCIES (Tables in other modules referenced by FK)
-- =========================================================================
-- std_students          → Modules/StudentProfile   (lms_ tables → student_id)
-- sys_users             → SystemConfig             (evaluated_by, entered_by, created_by)
-- sys_media             → SystemConfig             (attachment_id, offline_paper_uploaded_id)
-- qns_questions_bank    → Modules/QuestionBank     (question_id)
-- qns_question_options  → Modules/QuestionBank     (selected_option_id)
-- lms_quizzes           → Modules/LmsQuiz          (quiz_id)
-- lms_quests            → Modules/LmsQuests        (quest_id)
-- lms_quiz_allocations  → Modules/LmsQuiz          (quiz_allocation_id)
-- lms_quest_allocations → Modules/LmsQuests        (quest_allocation_id)
-- lms_exams             → Modules/LmsExam          (exam_id)
-- lms_exam_papers       → Modules/LmsExam          (exam_paper_id)
-- lms_exam_paper_sets   → Modules/LmsExam          (paper_set_id)
-- lms_exam_allocations  → Modules/LmsExam          (allocation_id)
-- =========================================================================


-- =========================================================================
-- SECTION 1: QUIZ & QUEST ATTEMPTS (Unified)
-- =========================================================================
-- LmsQuiz (lms_quizzes) and LmsQuests (lms_quests) share identical attempt
-- architecture. A single unified table avoids duplication and simplifies
-- the StudentPortal "My Learning" aggregation queries.
-- assessment_type discriminates between the two.
-- =========================================================================


-- -------------------------------------------------------------------------
-- Table: lms_quiz_quest_attempts
-- Purpose: One row per student attempt at a Quiz or Quest.
--          attempt_number increments per (student + assessment_type + assessment_id).
--          A student may have multiple attempts if allow_multiple_attempts=true.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_quiz_quest_attempts` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Subject
  `student_id`            INT UNSIGNED NOT NULL,                -- FK → std_students.id
  `assessment_type`       ENUM('QUIZ','QUEST') NOT NULL,
  `quiz_id`               INT UNSIGNED DEFAULT NULL,            -- FK → lms_quizzes.id (nullable when assessment_type=QUEST)
  `quest_id`              INT UNSIGNED DEFAULT NULL,            -- FK → lms_quests.id (nullable when assessment_type=QUIZ)
  `quiz_allocation_id`    INT UNSIGNED DEFAULT NULL,            -- FK → lms_quiz_allocations.id (nullable, only for quizzes)
  `quest_allocation_id`   INT UNSIGNED DEFAULT NULL,            -- FK → lms_quest_allocations.id (nullable, only for quests)
  -- Attempt Tracking
  `attempt_number`        TINYINT UNSIGNED NOT NULL DEFAULT 1,  -- Increments per student+assessment
  -- Timing
  `started_at`            DATETIME DEFAULT NULL,
  `submitted_at`          DATETIME DEFAULT NULL,
  `auto_submitted_at`     DATETIME DEFAULT NULL,                -- System auto-submit on timeout
  `time_taken_seconds`    INT UNSIGNED NOT NULL DEFAULT 0,
  -- Status
  `status`                ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','TIMEOUT','ABANDONED','CANCELLED','REASSIGNED') NOT NULL DEFAULT 'NOT_STARTED',
  -- Scoring (populated on evaluation)
  `score_obtained`        DECIMAL(8,2) DEFAULT NULL,            -- Cached total score obtained (sum of question marks_obtained)
  `max_score`             DECIMAL(8,2) DEFAULT NULL,            -- Cached total possible score for the assessment (sum of question max marks)
  `percentage`            DECIMAL(5,2) DEFAULT NULL,            -- Derived from score_obtained / max_score
  `is_passed`             TINYINT(1) DEFAULT NULL,              -- NULL until evaluated
  `teacher_feedback`      TEXT DEFAULT NULL,                    -- Optional feedback from teacher after evaluation
  -- Device / Proctoring (online attempts)
  `ip_address`            VARCHAR(45) DEFAULT NULL,             -- IPv6 compatible
  `browser_agent`         TEXT DEFAULT NULL,                    -- User agent string for browser/device
  `device_info`           JSON DEFAULT NULL,                    -- Structured device info: {device_type, os, browser}
  `violation_count`       INT UNSIGNED NOT NULL DEFAULT 0,      -- Count of proctoring violations (focus loss, tab switch, etc.)
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- G-06 FIX: v3 replaced polymorphic assessment_id with quiz_id/quest_id.
  -- MySQL UNIQUE with NULL values: NULLs are not considered equal, so quest rows
  -- (quiz_id=NULL) are automatically excluded from the quiz UNIQUE constraint and vice versa.
  -- Two separate UNIQUE keys correctly enforce uniqueness per assessment type.
  UNIQUE KEY `uq_qqat_student_quiz_attempt`  (`student_id`, `quiz_id`,  `attempt_number`),
  UNIQUE KEY `uq_qqat_student_quest_attempt` (`student_id`, `quest_id`, `attempt_number`),
  KEY `idx_qqat_student`              (`student_id`),
  KEY `idx_qqat_quiz`                 (`assessment_type`, `quiz_id`),
  KEY `idx_qqat_quest`                (`assessment_type`, `quest_id`),
  KEY `idx_qqat_quiz_alloc`           (`quiz_allocation_id`),
  KEY `idx_qqat_quest_alloc`          (`quest_allocation_id`),
  KEY `idx_qqat_status`               (`status`),
  KEY `idx_qqat_is_active`            (`is_active`),
  CONSTRAINT `fk_qqat_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_qqat_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_qqat_quest` FOREIGN KEY (`quest_id`) REFERENCES `lms_quests` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_qqat_quiz_alloc` FOREIGN KEY (`quiz_allocation_id`) REFERENCES `lms_quiz_allocations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_qqat_quest_alloc` FOREIGN KEY (`quest_allocation_id`) REFERENCES `lms_quest_allocations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_qqat_assessment_type` CHECK ((assessment_type = 'QUIZ' AND quiz_id IS NOT NULL AND quest_id IS NULL) OR (assessment_type = 'QUEST' AND quest_id IS NOT NULL AND quiz_id IS NULL)),
  CONSTRAINT `chk_qqat_allocation` CHECK ((assessment_type = 'QUIZ' AND quiz_allocation_id IS NOT NULL AND quest_allocation_id IS NULL) OR (assessment_type = 'QUEST' AND quest_allocation_id IS NOT NULL AND quiz_allocation_id IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One row per student attempt at a Quiz or Quest. attempt_number increments per student+assessment pair.';


-- -------------------------------------------------------------------------
-- Table: lms_quiz_quest_attempt_answers
-- Purpose: Per-question response for a quiz or quest attempt.
--          Supports all question types: Single-MCQ, Multi-MCQ, Descriptive,
--          Fill-in-the-blank, and File-upload.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_quiz_quest_attempt_answers` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id`            INT UNSIGNED NOT NULL,
  `question_id`           INT UNSIGNED NOT NULL,
  `question_type_id`      INT UNSIGNED DEFAULT NULL,            -- Cached from qns_question_types (avoids JOIN on eval)
  -- The Response
  `selected_option_id`    INT UNSIGNED DEFAULT NULL,            -- Single-MCQ → qns_question_options.id
  `selected_option_ids`   JSON DEFAULT NULL,                    -- Multi-MCQ  → array of option IDs
  `answer_text`           TEXT DEFAULT NULL,                    -- Descriptive / Fill-in-the-blank
  `attachment_id`         INT UNSIGNED DEFAULT NULL,            -- File-upload response → sys_media.id
  -- Evaluation
  `marks_obtained`        DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `max_marks`             DECIMAL(5,2) DEFAULT NULL,            -- Cached from quiz/quest question config
  `is_correct`            TINYINT(1) DEFAULT NULL,              -- NULL=pending, 0=wrong, 1=correct
  `is_evaluated`          TINYINT(1) NOT NULL DEFAULT 0,        -- Flag to indicate if this answer has been evaluated (auto or manual)
  `evaluated_by`          INT UNSIGNED DEFAULT NULL,            -- sys_users.id (teacher) | NULL for auto-eval
  `evaluation_remarks`    VARCHAR(255) DEFAULT NULL,
  `evaluated_at`          DATETIME DEFAULT NULL,
  -- Telemetry
  `time_spent_seconds`    INT UNSIGNED NOT NULL DEFAULT 0,      -- Time spent on this question (for online attempts)
  `change_count`          SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Times answer was changed
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qqans_attempt_question`  (`attempt_id`, `question_id`),
  KEY `idx_qqans_attempt`                 (`attempt_id`),
  KEY `idx_qqans_question`                (`question_id`),
  KEY `idx_qqans_is_evaluated`            (`is_evaluated`),
  CONSTRAINT `fk_qqans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_quiz_quest_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qqans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_qqans_option` FOREIGN KEY (`selected_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_qqans_evaluator` FOREIGN KEY (`evaluated_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-question responses for a quiz or quest attempt. Supports Single-MCQ, Multi-MCQ, Descriptive, and File-upload types.';


-- -------------------------------------------------------------------------
-- Table: lms_quiz_quest_results
-- Purpose: Final computed/published result for a quiz or quest attempt.
--          Created after all answers are evaluated (auto + manual).
--          One row per attempt. Drives the StudentPortal "My Results" view.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_quiz_quest_results` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id`            INT UNSIGNED NOT NULL,
  `student_id`            INT UNSIGNED NOT NULL,
  `assessment_type`       ENUM('QUIZ','QUEST') NOT NULL,
  `assessment_id`         INT UNSIGNED NOT NULL,                  -- Polymorphic (redundant cache for fast query)
  -- Scores
  `total_marks_obtained`  DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `max_marks`             DECIMAL(8,2) NOT NULL DEFAULT 0.00,     -- Cached from quiz/quest config (sum of question max marks)
  `percentage`            DECIMAL(5,2) NOT NULL DEFAULT 0.00,     -- Derived from total_marks_obtained / max_marks
  `grade_obtained`        VARCHAR(10) DEFAULT NULL,               -- Derived from grading schema
  `is_passed`             TINYINT(1) NOT NULL DEFAULT 0,          -- Derived from percentage and passing criteria
  `rank_in_class`         INT UNSIGNED DEFAULT NULL,              -- Rank among peers who took the same assessment (optional, can be computed asynchronously)
  `percentile`            DECIMAL(5,2) DEFAULT NULL,              -- Percentile rank among peers (optional, can be computed asynchronously)
  -- Publishing
  `is_published`          TINYINT(1) NOT NULL DEFAULT 0,          -- Flag to indicate if result is published and visible to student
  `published_at`          DATETIME DEFAULT NULL,                  -- Timestamp when result was published  
  `teacher_remarks`       TEXT DEFAULT NULL,                      -- Optional remarks from teacher after evaluation (can be shown in StudentPortal)
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qqres_attempt`       (`attempt_id`),
  KEY `idx_qqres_student`             (`student_id`),
  KEY `idx_qqres_assessment`          (`assessment_type`, `assessment_id`),
  KEY `idx_qqres_is_published`        (`is_published`),
  KEY `idx_qqres_is_active`           (`is_active`),
  CONSTRAINT `fk_qqres_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_quiz_quest_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qqres_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Final computed/published result for a quiz or quest attempt. Created after all answers are evaluated.';


-- =========================================================================
-- SECTION 2: EXAM ATTEMPTS (Online & Offline)
-- =========================================================================
-- Covers LmsExam: lms_exams → lms_exam_papers → lms_exam_paper_sets
-- Supports both ONLINE (auto-graded) and OFFLINE (bulk entry / question-wise)
-- =========================================================================


-- -------------------------------------------------------------------------
-- Table: lms_exam_attempts
-- Purpose: One row per student attempt at an exam paper (ONLINE or OFFLINE).
--          Business Rule: One attempt per paper per student (UNIQUE constraint).
--          Paper_set_id captures the specific randomized set the student received.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_attempts` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Exam Context
  `exam_paper_id`               INT UNSIGNED NOT NULL,            -- FK → lms_exam_papers.id
  `paper_set_id`                INT UNSIGNED NOT NULL,            -- FK → lms_exam_paper_sets.id
  `allocation_id`               INT UNSIGNED DEFAULT NULL,        -- FK → lms_exam_allocations.id
  `student_id`                  INT UNSIGNED NOT NULL,            -- FK → std_students.id
  -- Mode
  `attempt_mode`                ENUM('ONLINE','OFFLINE') NOT NULL DEFAULT 'ONLINE',
  -- Timing
  `actual_started_time`         DATETIME DEFAULT NULL,            -- When student actually started (can differ from scheduled start for offline)
  `actual_end_time`             DATETIME DEFAULT NULL,            -- When student actually ended (can differ from scheduled end for offline)
  `actual_time_taken_seconds`   INT UNSIGNED NOT NULL DEFAULT 0,  -- Derived from actual_end_time - actual_started_time
  -- Status
  `status`                      ENUM('NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED') NOT NULL DEFAULT 'NOT_STARTED',
  -- Offline Metadata
  `is_present_offline`          TINYINT(1) NOT NULL DEFAULT 1,  -- Attendance flag for offline
  `answer_sheet_number`         VARCHAR(50) DEFAULT NULL,       -- Physical sheet reference
  `offline_paper_uploaded_id`   INT UNSIGNED DEFAULT NULL,      -- FK → sys_media (scanned sheet)
  -- Online Proctoring
  `ip_address`                  VARCHAR(45) DEFAULT NULL,
  `browser_agent`               TEXT DEFAULT NULL,
  `device_info`                 JSON DEFAULT NULL,
  `violation_count`             INT UNSIGNED NOT NULL DEFAULT 0,
  -- Standard Columns
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                  INT UNSIGNED DEFAULT NULL,
  `created_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exatt_paper_student`   (`exam_paper_id`, `student_id`),
  KEY `idx_exatt_student`               (`student_id`),
  KEY `idx_exatt_paper`                 (`exam_paper_id`),
  KEY `idx_exatt_set`                   (`paper_set_id`),
  KEY `idx_exatt_allocation`            (`allocation_id`),
  KEY `idx_exatt_status`                (`status`),
  KEY `idx_exatt_is_active`             (`is_active`),
  CONSTRAINT `fk_exatt_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exatt_set` FOREIGN KEY (`paper_set_id`) REFERENCES `lms_exam_paper_sets` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exatt_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exatt_allocation` FOREIGN KEY (`allocation_id`) REFERENCES `lms_exam_allocations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One row per student exam attempt. Covers ONLINE and OFFLINE modes. UNIQUE on paper+student enforces one attempt per paper per student.';


-- -------------------------------------------------------------------------
-- Table: lms_exam_attempt_answers
-- Purpose: Per-question responses for an exam attempt.
--          Used for: ONLINE exams (auto-saved as student answers).
--                    OFFLINE exams with offline_entry_mode = QUESTION_WISE.
--          NOT used when offline_entry_mode = BULK_TOTAL (use lms_exam_marks_entry).
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_attempt_answers` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id`            INT UNSIGNED NOT NULL,
  `question_id`           INT UNSIGNED NOT NULL,
  `question_type_id`      INT UNSIGNED DEFAULT NULL,            -- Cached type for evaluation logic
  -- The Response
  `selected_option_id`    INT UNSIGNED DEFAULT NULL,            -- Single-MCQ
  `selected_option_ids`   JSON DEFAULT NULL,                    -- Multi-MCQ (array of option IDs)
  `descriptive_answer`    TEXT DEFAULT NULL,                    -- Text-based answers
  `attachment_id`         INT UNSIGNED DEFAULT NULL,            -- File-upload → sys_media.id
  -- Evaluation
  `marks_obtained`        DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `max_marks`             DECIMAL(5,2) DEFAULT NULL,            -- Cached from lms_paper_set_questions
  `is_correct`            TINYINT(1) DEFAULT NULL,              -- NULL=pending, 0=wrong, 1=correct
  `is_evaluated`          TINYINT(1) NOT NULL DEFAULT 0,        -- Flag to indicate if this answer has been evaluated (auto or manual)
  `evaluated_by`          INT UNSIGNED DEFAULT NULL,            -- Teacher | NULL for auto
  `evaluation_remarks`    TEXT DEFAULT NULL,                    -- Optional remarks from evaluator (can be shown in StudentPortal) 
  `evaluated_at`          DATETIME DEFAULT NULL,          
  -- Telemetry (online only)
  `time_spent_seconds`    INT UNSIGNED NOT NULL DEFAULT 0,      -- Time spent on this question (for online attempts)
  `change_count`          SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Times answer was changed
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exans_attempt_question` (`attempt_id`, `question_id`),
  KEY `idx_exans_attempt`               (`attempt_id`),
  KEY `idx_exans_question`              (`question_id`),
  KEY `idx_exans_is_evaluated`          (`is_evaluated`),
  CONSTRAINT `fk_exans_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_exam_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_exans_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exans_option` FOREIGN KEY (`selected_option_id`) REFERENCES `qns_question_options` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exans_evaluator` FOREIGN KEY (`evaluated_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-question responses for an exam attempt. Used for ONLINE exams and OFFLINE exams with QUESTION_WISE entry mode.';


-- -------------------------------------------------------------------------
-- Table: lms_exam_marks_entry
-- Purpose: Bulk total marks entry for OFFLINE exams in BULK_TOTAL mode.
--          Teacher enters total marks obtained without per-question breakdown.
--          One row per attempt (UNIQUE).
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_marks_entry` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id`            INT UNSIGNED NOT NULL,                -- FK → lms_exam_attempts.id (only for OFFLINE attempts with BULK_TOTAL mode)
  `total_marks_obtained`  DECIMAL(8,2) NOT NULL DEFAULT 0.00,   -- Total marks obtained entered by teacher
  `remarks`               VARCHAR(255) DEFAULT NULL,            -- Optional remarks from teacher during marks entry (can be shown in StudentPortal)
  `entered_by`            INT UNSIGNED NOT NULL,                -- FK → sys_users.id (teacher)
  `entered_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exme_attempt`          (`attempt_id`),
  KEY `idx_exme_entered_by`             (`entered_by`),
  KEY `idx_exme_is_active`              (`is_active`),
  CONSTRAINT `fk_exme_attempt`
    FOREIGN KEY (`attempt_id`) REFERENCES `lms_exam_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_exme_enterer` FOREIGN KEY (`entered_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bulk total marks entry for offline exams in BULK_TOTAL mode. One row per attempt.';


-- -------------------------------------------------------------------------
-- Table: lms_exam_results
-- Purpose: Final consolidated exam result per student per exam paper.
--          Created/updated after evaluation + optional manual review.
--          Drives StudentPortal "My Results" and HPC (Progress Card) integration.
--          exam_paper_id used in UNIQUE (one result per paper per student).
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_results` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id`               INT UNSIGNED NOT NULL,                -- FK → lms_exams.id (denormalized for fast query)
  `exam_paper_id`         INT UNSIGNED NOT NULL,                -- FK → lms_exam_papers.id
  `student_id`            INT UNSIGNED NOT NULL,                -- FK → std_students.id
  `attempt_id`            INT UNSIGNED DEFAULT NULL,            -- FK → lms_exam_attempts.id (nullable for absent)
  -- Scores
  `total_marks_possible`  DECIMAL(8,2) NOT NULL DEFAULT 0.00,   -- Cached total possible marks for the paper (from lms_exam_paper_sets)
  `total_marks_obtained`  DECIMAL(8,2) NOT NULL DEFAULT 0.00,   -- Total marks obtained (from lms_exam_attempt_answers or lms_exam_marks_entry)
  `percentage`            DECIMAL(5,2) NOT NULL DEFAULT 0.00,   -- Derived from total_marks_obtained / total_marks_possible
  `grade_obtained`        VARCHAR(10) DEFAULT NULL,             -- A+, B, etc. from grading schema
  `division`              VARCHAR(20) DEFAULT NULL,             -- First, Second, Pass, Fail
  `result_status`         ENUM('PASS','FAIL','ABSENT','WITHHELD') NOT NULL DEFAULT 'PASS',  -- Overall result status
  `rank_in_class`         INT UNSIGNED DEFAULT NULL,            -- Rank among peers who took the same paper (optional, can be computed asynchronously)
  `percentile`            DECIMAL(5,2) DEFAULT NULL,            -- Percentile rank among peers (optional, can be computed asynchronously) 
  -- Publishing
  `is_published`          TINYINT(1) NOT NULL DEFAULT 0,
  `published_at`          DATETIME DEFAULT NULL,
  `teacher_remarks`       TEXT DEFAULT NULL,
  `report_card_path`      VARCHAR(500) DEFAULT NULL,            -- Path to generated PDF (DomPDF)
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exres_paper_student`   (`exam_paper_id`, `student_id`),
  KEY `idx_exres_exam`                  (`exam_id`),
  KEY `idx_exres_student`               (`student_id`),
  KEY `idx_exres_attempt`               (`attempt_id`),
  KEY `idx_exres_is_published`          (`is_published`),
  KEY `idx_exres_result_status`         (`result_status`),
  KEY `idx_exres_is_active`             (`is_active`),
  CONSTRAINT `fk_exres_exam` FOREIGN KEY (`exam_id`) REFERENCES `lms_exams` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exres_paper` FOREIGN KEY (`exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exres_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exres_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_exam_attempts` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Final consolidated exam result per student per paper. Drives StudentPortal results view and HPC integration.';


-- -------------------------------------------------------------------------
-- Table: lms_exam_grievances
-- Purpose: Student grievances / re-evaluation requests on published exam results.
--          Can target a specific question (question_id) or the overall result (NULL).
--          Marks may be revised; old/new marks captured for audit.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_exam_grievances` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_result_id`        INT UNSIGNED NOT NULL,                -- FK → lms_exam_results.id
  `student_id`            INT UNSIGNED NOT NULL,                -- FK → std_students.id (redundant cache)
  `question_id`           INT UNSIGNED DEFAULT NULL,            -- FK → qns_questions_bank.id | NULL = general
  `grievance_type`        ENUM('MARKING_ERROR','QUESTION_ERROR','OUT_OF_SYLLABUS','OTHER') NOT NULL DEFAULT 'OTHER',
  `grievance_text`        TEXT NOT NULL,
  -- Review Workflow
  `status`                ENUM('OPEN','UNDER_REVIEW','RESOLVED','REJECTED') NOT NULL DEFAULT 'OPEN',
  `reviewer_id`           INT UNSIGNED DEFAULT NULL,            -- FK → sys_users.id (teacher/admin)
  `resolution_remarks`    TEXT DEFAULT NULL,            -- Remarks from reviewer after resolution (can be shown in StudentPortal) 
  `resolved_at`           DATETIME DEFAULT NULL,        -- Timestamp when grievance was resolved
  -- Mark Revision (if marks changed after re-evaluation)   
  `marks_changed`         TINYINT(1) NOT NULL DEFAULT 0,
  `old_marks`             DECIMAL(5,2) DEFAULT NULL,
  `new_marks`             DECIMAL(5,2) DEFAULT NULL,
  -- Standard Columns
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_exgrv_result`                (`exam_result_id`),
  KEY `idx_exgrv_student`               (`student_id`),
  KEY `idx_exgrv_status`                (`status`),
  KEY `idx_exgrv_reviewer`              (`reviewer_id`),
  KEY `idx_exgrv_is_active`             (`is_active`),
  CONSTRAINT `fk_exgrv_result` FOREIGN KEY (`exam_result_id`) REFERENCES `lms_exam_results` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_exgrv_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_exgrv_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exgrv_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Student grievances or re-evaluation requests on published exam results. Supports question-level or overall result targeting.';


-- =========================================================================
-- SECTION 3: CROSS-TYPE TRACKING (Quiz, Quest, Exam)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `attemp_activity_event_types` (
  `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`        VARCHAR(50) NOT NULL,   -- Unique code for the event type (e.g., 'FOCUS_LOST', 'TAB_SWITCH')
  `name`        VARCHAR(100) NOT NULL,  -- 'FOCUS_LOST','FULLSCREEN_EXIT','BROWSER_RESIZE','KEY_PRESS_BLOCKED','MOUSE_LEAVE','IP_CHANGE','TAB_SWITCH','COPY_PASTE_DETECTED','CONTEXT_MENU_OPENED','DEVTOOLS_DETECTED','WINDOW_BLUR','NETWORK_DISCONNECT'
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
  UNIQUE KEY `uq_event_code` (`code`),
  KEY `idx_event_name` (`name`),
  KEY `idx_event_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Master table for attempt activity event types. Defines the types of behavioral events that can be logged during quiz, quest, and exam attempts.';

-- -------------------------------------------------------------------------
-- Table: lms_attempt_activity_logs
-- Purpose: Append-only behavioral event log for proctoring and telemetry.
--          Covers all attempt types: QUIZ, QUEST, EXAM.
--          attempt_id is polymorphic — points to the correct attempt table
--          based on attempt_type.
-- Design:  No soft-delete (logs are immutable audit records).
--          No deleted_at or created_by (system-generated events).
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_attempt_activity_logs` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Polymorphic reference
  `attempt_type`    ENUM('QUIZ','QUEST','EXAM') NOT NULL,
  `attempt_id`      INT UNSIGNED NOT NULL,
  -- Event
  `event_type`      INT UNSIGNED NOT NULL,          -- FK → attemp_activity_event_types.id
  `event_data`      JSON DEFAULT NULL,              -- Extra context: IP, key codes, etc.
  `occurred_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Minimal standard columns (no soft delete — immutable audit log)
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_aal_attempt`                 (`attempt_type`, `attempt_id`),
  KEY `idx_aal_event_type`              (`event_type`),
  KEY `idx_aal_occurred_at`             (`occurred_at`)
  -- Note: No FK on attempt_id — polymorphic reference to 3 different tables
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Append-only proctoring and behavioral event log for all attempt types (QUIZ/QUEST/EXAM). Polymorphic on attempt_id.';


-- -------------------------------------------------------------------------
-- Table: lms_attempt_checkpoints
-- Purpose: Save-state for in-progress attempts to support session resumption. 
--          Allows a student to resume a quiz/quest/exam after browser crash, accidental tab close, or network disconnect.
-- Design:  UPSERT pattern — one row per active attempt (UNIQUE on attempt_type+id).
--          Overwritten on each auto-save tick. checkpoint_data holds full answer state snapshot for restore.
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lms_attempt_checkpoints` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Polymorphic reference
  `attempt_type`            ENUM('QUIZ','QUEST','EXAM') NOT NULL,
  `attempt_id`              INT UNSIGNED NOT NULL,
  -- Current Position
  `current_question_idx`    SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- 0-based index in question list
  `last_question_id`        INT UNSIGNED DEFAULT NULL,             -- FK → qns_questions_bank.id (last viewed)
  -- State Snapshot
  `answered_question_ids`   JSON DEFAULT NULL,                    -- Array of question IDs already answered
  `flagged_question_ids`    JSON DEFAULT NULL,                    -- Array of question IDs flagged for review
  `checkpoint_data`         JSON DEFAULT NULL,                    -- Full answer state: {question_id: response}
  -- Timing
  `saved_at`                DATETIME NOT NULL,
  -- Standard Columns (no soft delete — checkpoints are ephemeral)
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_chk_attempt`           (`attempt_type`, `attempt_id`),
  KEY `idx_chk_attempt`                 (`attempt_type`, `attempt_id`)
  -- Note: No FK on attempt_id — polymorphic (quiz/quest/exam attempt tables)
  -- Note: Rows should be deleted once attempt is submitted (application responsibility)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Save-state for in-progress attempts. Enables session resumption after crash or disconnect. UPSERT pattern — one row per active attempt.';


-- =========================================================================
-- END OF FILE
-- =========================================================================
-- TABLE SUMMARY
-- =========================================================================
-- #  | Table Name                        | Purpose
-- ---|-----------------------------------|---------------------------------
-- 1  | lms_quiz_quest_attempts           | Quiz & Quest main attempt record
-- 2  | lms_quiz_quest_attempt_answers    | Per-question responses (Quiz/Quest)
-- 3  | lms_quiz_quest_results            | Final result record (Quiz/Quest)
-- 4  | lms_exam_attempts                 | Exam main attempt record
-- 5  | lms_exam_attempt_answers          | Per-question responses (Exam)
-- 6  | lms_exam_marks_entry              | Bulk total marks (Offline exams)
-- 7  | lms_exam_results                  | Final consolidated exam result
-- 8  | lms_exam_grievances               | Re-evaluation requests
-- 9  | attemp_activity_event_types       | Master list of behavioral event types for logging
-- 10 | lms_attempt_activity_logs         | Proctoring/behavioral event log
-- 11 | lms_attempt_checkpoints           | Session save-state for resume
-- =========================================================================
-- KEY DESIGN DECISIONS vs v1
-- =========================================================================
-- 1.  DEDUPLICATION: v1 had duplicate CREATE TABLE for lms_student_attempts,
--     lms_exam_results, lms_exam_grievances. All deduplicated in v2.
-- 2.  RENAMED: lms_student_attempts → lms_exam_attempts (clarity).
-- 3.  NEW: lms_quiz_quest_results — v1 had no result table for quiz/quest.
-- 4.  NEW: lms_attempt_checkpoints — resume support not in v1.
-- 5.  EXTENDED: lms_attempt_activity_logs covers QUIZ/QUEST in addition to EXAM.
-- 6.  STANDARD COLUMNS: All tables have is_active, created_by, created_at,
--     updated_at. Activity logs and checkpoints omit deleted_at (immutable/ephemeral).
-- 7.  MULTI-MCQ: selected_option_ids (JSON) added to both answer tables.
-- 8.  PROCTORING: browser_agent, violation_count, device_info added to attempts.
-- 9.  EXAM RESULT: exam_paper_id added to lms_exam_results (v1 only had exam_id).
--     UNIQUE changed to (exam_paper_id, student_id) — one result per paper per student.
-- 10. FK STRATEGY: ON DELETE RESTRICT for core entities (student, exam, question).
--     ON DELETE CASCADE for child rows (answers → attempt).
--     ON DELETE SET NULL for optional refs (allocation, evaluator).
-- =========================================================================
