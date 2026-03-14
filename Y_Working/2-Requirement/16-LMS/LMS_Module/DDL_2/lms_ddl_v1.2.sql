-- /********************************************************************
--  PRIMEGURUKUL – SCHOOL ERP
--  LMS MODULE – INDUSTRIALIZED DATABASE DDL (v1.2)
--  Platform: MySQL 8.x | Framework: Laravel 11.x
--  Architecture: Multi-Tenant | Soft Deletes | Audit Ready
-- ********************************************************************/

SET sql_mode = 'STRICT_ALL_TABLES';

-- ==============================================================================================================
-- 1. CONFIGURATION & LOOKUPS (System Dropdowns)
-- ==============================================================================================================

-- We will use `sys_dropdown_needs` and `sys_dropdown_table` for:
--  - Question Types (MCQ, TRUE_FALSE, MATCH_FOLLOWING, DESCRIPTIVE, FILL_BLANKS)
--  - Difficulty Levels (EASY, MEDIUM, HARD, EXPERT)
--  - Bloom's Taxonomy (REMEMBER, UNDERSTAND, APPLY, ANALYZE, EVALUATE, CREATE)
--  - Cognitive Skills (KNOWLEDGE, COMPREHENSION, APPLICATION, ANALYSIS)
--  - Content Formats (TEXT, VIDEO, PDF, AUDIO, IMAGE)
--  - Assessment Types (HOMEWORK, QUIZ, QUEST, EXAM_ONLINE, EXAM_OFFLINE)
--  - Review Status (DRAFT, IN_REVIEW, APPROVED, REJECTED, ARCHIVED)
--  - Submission Status (PENDING, SUBMITTED, GRADED, LATE, MISSED)

-- (See End of File for Seed INSERT Statements for these Dropdowns)


-- ==============================================================================================================
-- 2. QUESTION BANK SUBSYSTEM
-- ==============================================================================================================

-- 2.1 The Core Question Table
CREATE TABLE IF NOT EXISTS `lms_question_bank` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `start_academic_session_id` INT UNSIGNED DEFAULT NULL, -- Optional: If question is tied to a specific year curriculum
    `class_id` INT UNSIGNED NOT NULL,                     -- FK to sch_classes
    `subject_id` INT UNSIGNED NOT NULL,                -- FK to sch_subjects
    -- Topic Hierarchy (Nullable as questions might be generic to a subject, but recommended)
    `topic_id` INT UNSIGNED DEFAULT NULL,              -- FK to syllabus_topics (from Syllabus Module)
    `sub_topic_id` INT UNSIGNED DEFAULT NULL,          
    
    -- Metadata / Properties
    `question_type_id` INT UNSIGNED NOT NULL,          -- FK to sys_dropdown_table (MCQ, Text, etc.)
    `difficulty_level_id` INT UNSIGNED DEFAULT NULL,   -- FK to sys_dropdown_table
    `blooms_taxonomy_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table
    `cognitive_skill_id` INT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table
    
    -- Content
    `question_stem` LONGTEXT NOT NULL,                    -- The actual question text (supports HTML/Markdown/LaTeX)
    `question_media_id` INT UNSIGNED DEFAULT NULL,     -- FK to sys_media (if image/diagram is part of question)
    `model_answer` LONGTEXT DEFAULT NULL,                 -- For descriptive questions or reference
    `default_marks` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
    `time_limit_seconds` INT UNSIGNED DEFAULT NULL,       -- Recommended time to solve
    
    -- Source & Usage
    `source_reference` VARCHAR(255) DEFAULT NULL,         -- e.g., "NCERT Math Book Pg 45"
    `is_global` TINYINT(1) NOT NULL DEFAULT 0,            -- 0=School Specific, 1=PrimeGurukul Global Library
    `status_id` INT UNSIGNED NOT NULL,                 -- FK to sys_dropdown_table (Draft, Approved)
    
    -- Stats Attributes (Updated via Jobs)
    `stat_difficulty_index` DECIMAL(5,2) DEFAULT NULL,    -- 0.00 to 1.00
    `stat_discrimination_index` DECIMAL(5,2) DEFAULT NULL,
    `stat_total_attempts` INT UNSIGNED DEFAULT 0,
    `stat_avg_time_taken` INT UNSIGNED DEFAULT NULL,

    -- Common Fields
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,            -- FK to sys_users (Author)
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    INDEX `idx_qbank_class_subject` (`class_id`, `subject_id`),
    INDEX `idx_qbank_topic` (`topic_id`),
    INDEX `idx_qbank_type` (`question_type_id`),
    CONSTRAINT `fk_qbank_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qbank_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qbank_qType` FOREIGN KEY (`question_type_id`) REFERENCES `sys_dropdown_table` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.2 Options for Objective Questions (MCQ, Checkbox, etc.)
CREATE TABLE IF NOT EXISTS `lms_question_options` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_id` INT UNSIGNED NOT NULL,
    `option_text` LONGTEXT NOT NULL,                      -- HTML/Text/Markdown
    `option_media_id` INT UNSIGNED DEFAULT NULL,       -- FK to sys_media
    `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
    `explanation` TEXT DEFAULT NULL,                      -- Why this option is correct/incorrect
    `ordinal` TINYINT UNSIGNED NOT NULL DEFAULT 0,        -- Display order
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    INDEX `idx_qopt_question` (`question_id`),
    CONSTRAINT `fk_qopt_question` FOREIGN KEY (`question_id`) REFERENCES `lms_question_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.3 Review Log for Questions (Workflow)
CREATE TABLE IF NOT EXISTS `lms_question_reviews` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_id` INT UNSIGNED NOT NULL,
    `reviewer_id` INT UNSIGNED NOT NULL,               -- FK to sys_users
    `status_id` INT UNSIGNED NOT NULL,                 -- FK to sys_dropdown_table (Approved, Rejected)
    `comments` TEXT DEFAULT NULL,
    `reviewed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_qreview_question` FOREIGN KEY (`question_id`) REFERENCES `lms_question_bank` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qreview_user` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 3. ASSESSMENT MASTER (Homework, Quiz, Quest, Exam)
-- ==============================================================================================================

-- Unified Master Table or Separated? 
-- Decision: Separated tables for Homework vs Quiz/Exam because they have very different properties.
-- However, we share concepts like "Target Audience".

-- 3.1 Homework Master
CREATE TABLE IF NOT EXISTS `lms_homework` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `academic_session_id` INT UNSIGNED NOT NULL,       -- FK to glb_academic_sessions (Context)
    `title` VARCHAR(255) NOT NULL,
    `description` LONGTEXT DEFAULT NULL,
    
    -- Targeting
    `class_id` INT UNSIGNED NOT NULL,                     -- FK
    `section_id` INT UNSIGNED DEFAULT NULL,               -- Nullable (if assigned to entire class)
    `subject_id` INT UNSIGNED NOT NULL,                -- FK
    `topic_id` INT UNSIGNED DEFAULT NULL,              -- FK (Trigger source)
    
    -- Configuration
    `submission_format_id` INT UNSIGNED NOT NULL,      -- FK to sys_dropdown_table (Text, File, Hybrid)
    `is_gradable` TINYINT(1) NOT NULL DEFAULT 1,
    `max_marks` DECIMAL(5,2) DEFAULT NULL,
    `due_date` DATETIME DEFAULT NULL,
    `auto_publish_on` DATETIME DEFAULT NULL,              -- Scheduler
    `difficulty_tag_id` INT UNSIGNED DEFAULT NULL,     -- FK to sys_dropdown_table
    
    -- Status
    `status_id` INT UNSIGNED NOT NULL,                 -- Published, Draft, Closed
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED NOT NULL,
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    INDEX `idx_hw_target` (`class_id`, `section_id`, `subject_id`),
    CONSTRAINT `fk_hw_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_hw_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_hw_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2 Quiz / Quest / Exam Master (The "Test" Engine)
CREATE TABLE IF NOT EXISTS `lms_assessments` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assessment_category_id` INT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (QUIZ, QUEST, EXAM, OLYMPIAD)
    
    `title` VARCHAR(255) NOT NULL,
    `instructions` LONGTEXT DEFAULT NULL,
    
    -- Targeting
    `class_id` INT UNSIGNED NOT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    
    -- Configuration
    `mode_id` INT UNSIGNED NOT NULL,                   -- FK to sys_dropdown_table (ONLINE, OFFLINE, HYBRID)
    `duration_minutes` INT UNSIGNED DEFAULT NULL,         -- NULL = No limit
    `total_marks` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `passing_percentage` DECIMAL(5,2) DEFAULT 33.00,
    `max_attempts_allowed` TINYINT UNSIGNED DEFAULT 1,
    `allow_back_navigation` TINYINT(1) DEFAULT 1,
    `show_result_immediately` TINYINT(1) DEFAULT 0,
    
    -- Scheduling
    `valid_from` DATETIME DEFAULT NULL,
    `valid_to` DATETIME DEFAULT NULL,
    `result_publish_date` DATETIME DEFAULT NULL,
    
    -- Advanced
    `shuffle_questions` TINYINT(1) DEFAULT 0,
    `shuffle_options` TINYINT(1) DEFAULT 0,
    `camera_proctoring_required` TINYINT(1) DEFAULT 0,
    
    `status_id` INT UNSIGNED NOT NULL,                 -- Draft, Published
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED NOT NULL,
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    INDEX `idx_assess_lookup` (`class_id`, `subject_id`, `assessment_category_id`),
    CONSTRAINT `fk_assess_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_assess_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3 Assessment Question Mapping (Which questions are in which test)
CREATE TABLE IF NOT EXISTS `lms_assessment_questions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assessment_id` INT UNSIGNED NOT NULL,
    `question_id` INT UNSIGNED NOT NULL,
    `section_name` VARCHAR(100) DEFAULT 'Section A',    -- Grouping within exam
    `custom_marks` DECIMAL(5,2) DEFAULT NULL,           -- Override default marks if needed
    `ordinal` INT UNSIGNED NOT NULL DEFAULT 0,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_assess_q` (`assessment_id`, `question_id`),
    CONSTRAINT `fk_aq_assess` FOREIGN KEY (`assessment_id`) REFERENCES `lms_assessments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_aq_question` FOREIGN KEY (`question_id`) REFERENCES `lms_question_bank` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 4. STUDENT EXECUTION & ATTEMPTS
-- ==============================================================================================================

-- 4.1 Student Homework Submission
CREATE TABLE IF NOT EXISTS `lms_homework_submissions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `homework_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,                -- FK to sys_users (Role: Student)
    
    `submitted_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `text_content` LONGTEXT DEFAULT NULL,
    `attachment_media_id` INT UNSIGNED DEFAULT NULL,   -- FK to sys_media
    
    `teacher_feedback` TEXT DEFAULT NULL,
    `marks_obtained` DECIMAL(5,2) DEFAULT NULL,
    `submission_status_id` INT UNSIGNED NOT NULL,      -- Submitted, Graded, Resubmit Asked
    
    `is_late_submission` TINYINT(1) DEFAULT 0,
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hw_sub_student` (`homework_id`, `student_id`),
    CONSTRAINT `fk_hws_hw` FOREIGN KEY (`homework_id`) REFERENCES `lms_homework` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hws_student` FOREIGN KEY (`student_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4.2 Assessment Attempt Header (The "Session")
CREATE TABLE IF NOT EXISTS `lms_student_attempts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assessment_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    
    `attempt_number` TINYINT UNSIGNED DEFAULT 1,
    `started_at` DATETIME NOT NULL,
    `finished_at` DATETIME DEFAULT NULL,
    `duration_seconds` INT UNSIGNED DEFAULT 0,
    
    `total_score` DECIMAL(6,2) DEFAULT 0.00,
    `percentage` DECIMAL(5,2) DEFAULT 0.00,
    `is_passed` TINYINT(1) DEFAULT 0,
    `attempt_status_id` INT UNSIGNED NOT NULL,         -- In Progress, Completed, Abandoned, Time Up
    
    -- Analytics Summary
    `correct_count` INT UNSIGNED DEFAULT 0,
    `incorrect_count` INT UNSIGNED DEFAULT 0,
    `unattempted_count` INT UNSIGNED DEFAULT 0,
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_att_assess` FOREIGN KEY (`assessment_id`) REFERENCES `lms_assessments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 4.3 Question-Level Response Log (Granular Data)
CREATE TABLE IF NOT EXISTS `lms_attempt_answers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attempt_id` INT UNSIGNED NOT NULL,
    `question_id` INT UNSIGNED NOT NULL,
    
    `selected_option_id` INT UNSIGNED DEFAULT NULL,    -- For MCQ
    `text_answer` LONGTEXT DEFAULT NULL,                  -- For Descriptive/Fill Blanks
    
    `is_marked_for_review` TINYINT(1) DEFAULT 0,          -- Flagged by student
    `time_spent_seconds` INT UNSIGNED DEFAULT 0,
    `change_count` TINYINT UNSIGNED DEFAULT 0,            -- How many times answer changed
    
    `is_correct` TINYINT(1) DEFAULT NULL,                 -- 1=Correct, 0=Wrong, NULL=Not Evaluated yet
    `marks_awarded` DECIMAL(5,2) DEFAULT 0.00,
    `manual_correction_by` INT UNSIGNED DEFAULT NULL,  -- Teacher ID if manually corrected
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_att_ans` (`attempt_id`, `question_id`),
    CONSTRAINT `fk_aa_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `lms_student_attempts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_aa_question` FOREIGN KEY (`question_id`) REFERENCES `lms_question_bank` (`id`),
    CONSTRAINT `fk_aa_opt` FOREIGN KEY (`selected_option_id`) REFERENCES `lms_question_options` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 5. PERFORMANCE & ANALYTICS
-- ==============================================================================================================

-- 5.1 Performance Categories (Topper, Average, Remedial)
CREATE TABLE IF NOT EXISTS `lms_performance_bands` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `band_name` VARCHAR(50) NOT NULL,                     -- e.g. "Distinction", "Needs Improvement"
    `min_percentage` DECIMAL(5,2) NOT NULL,
    `max_percentage` DECIMAL(5,2) NOT NULL,
    `color_code` VARCHAR(10) DEFAULT '#000000',
    `recommendation_text` TEXT DEFAULT NULL,              -- Auto-generated advice
    
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================================================
-- 6. SEED DATA (System Dropdown Needs)
-- ==============================================================================================================

-- We must register our needs in sys_dropdown_needs so the system knows these lookups exist.
-- Assuming 'sys' module tables exist.

INSERT INTO `sys_dropdown_needs` (`db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `field_name`, `is_system`, `compulsory`) VALUES
('Tenant', 'lms_question_bank', 'question_type_id', 'LMS', 'Question Bank', 'Question Type', 1, 1),
('Tenant', 'lms_question_bank', 'difficulty_level_id', 'LMS', 'Question Bank', 'Difficulty Level', 1, 1),
('Tenant', 'lms_question_bank', 'blooms_taxonomy_id', 'LMS', 'Question Bank', 'Blooms Taxonomy', 1, 1),
('Tenant', 'lms_question_bank', 'cognitive_skill_id', 'LMS', 'Question Bank', 'Cognitive Skill', 1, 1),
('Tenant', 'lms_assessments', 'assessment_category_id', 'LMS', 'Assessments', 'Assessment Category', 1, 1),
('Tenant', 'lms_assessments', 'mode_id', 'LMS', 'Assessments', 'Assessment Mode', 1, 1),
('Tenant', 'lms_homework', 'submission_format_id', 'LMS', 'Homework', 'Submission Format', 1, 1);

-- ==============================================================================================================
-- 7. SEED DATA (Dropdown Values)
-- ==============================================================================================================

-- Inserting values for Question Types
-- We use a stored procedure or block to find the ID, but for DDL simplicity we assume IDs based on insertion order or use subqueries.
-- Here we demonstrate the data that MUST be present.

-- Question Types
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'MCQ', 'Multiple Choice', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'question_type_id'
UNION ALL SELECT id, 2, 'MRQ', 'Multiple Response', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'question_type_id'
UNION ALL SELECT id, 3, 'TRUE_FALSE', 'True/False', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'question_type_id'
UNION ALL SELECT id, 4, 'FILL_BLANKS', 'Fill in the Blanks', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'question_type_id'
UNION ALL SELECT id, 5, 'DESCRIPTIVE', 'Descriptive', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'question_type_id';

-- Difficulty Levels
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'EASY', 'Easy', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'difficulty_level_id'
UNION ALL SELECT id, 2, 'MEDIUM', 'Medium', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'difficulty_level_id'
UNION ALL SELECT id, 3, 'HARD', 'Hard', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'difficulty_level_id'
UNION ALL SELECT id, 4, 'EXPERT', 'Expert', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'difficulty_level_id';

-- Assessment Categories
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'HOMEWORK', 'Homework', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'assessment_category_id'
UNION ALL SELECT id, 2, 'QUIZ', 'Quiz', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'assessment_category_id'
UNION ALL SELECT id, 3, 'QUEST', 'Quest', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'assessment_category_id'
UNION ALL SELECT id, 4, 'EXAM', 'Exam', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'assessment_category_id';

-- Assessment Modes
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'ONLINE', 'Online', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'mode_id'
UNION ALL SELECT id, 2, 'OFFLINE', 'Offline', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'mode_id'
UNION ALL SELECT id, 3, 'HYBRID', 'Hybrid', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'mode_id';

-- Blooms Taxonomy
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'REMEMBER', 'Remember', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'blooms_taxonomy_id'
UNION ALL SELECT id, 2, 'UNDERSTAND', 'Understand', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'blooms_taxonomy_id'
UNION ALL SELECT id, 3, 'APPLY', 'Apply', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'blooms_taxonomy_id'
UNION ALL SELECT id, 4, 'ANALYZE', 'Analyze', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'blooms_taxonomy_id'
UNION ALL SELECT id, 5, 'EVALUATE', 'Evaluate', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'blooms_taxonomy_id'
UNION ALL SELECT id, 6, 'CREATE', 'Create', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'blooms_taxonomy_id';

-- Cognitive Skills
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'KNOWLEDGE', 'Knowledge', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'cognitive_skill_id'
UNION ALL SELECT id, 2, 'COMPREHENSION', 'Comprehension', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'cognitive_skill_id'
UNION ALL SELECT id, 3, 'APPLICATION', 'Application', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'cognitive_skill_id'
UNION ALL SELECT id, 4, 'ANALYSIS', 'Analysis', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'cognitive_skill_id'
UNION ALL SELECT id, 5, 'SYNTHESIS', 'Synthesis', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'cognitive_skill_id'
UNION ALL SELECT id, 6, 'EVALUATION', 'Evaluation', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'cognitive_skill_id';

-- Submission Formats
INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`, `is_active`)
SELECT id, 1, 'TEXT', 'Text Entry', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_format_id'
UNION ALL SELECT id, 2, 'FILE', 'File Upload', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_format_id'
UNION ALL SELECT id, 3, 'HYBRID', 'Text & File', 'String', 1 FROM `sys_dropdown_needs` WHERE `column_name` = 'submission_format_id';

