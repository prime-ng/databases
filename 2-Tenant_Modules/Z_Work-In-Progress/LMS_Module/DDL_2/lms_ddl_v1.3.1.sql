
/********************************************************************
 PRIMEGURUKUL – SCHOOL ERP
 LMS MODULE – CONSOLIDATED DATABASE DDL
 MySQL 8.x | Laravel Ready | Enterprise Grade
********************************************************************/

SET sql_mode = 'STRICT_ALL_TABLES';

-- ================= PHASE A1: SHARED MASTERS =================

CREATE TABLE lms_content_format_master (
    content_format_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    format_code VARCHAR(30) NOT NULL UNIQUE,  -- TEXT, HTML, MARKDOWN, LATEX, JSON
    format_name VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT UNSIGNED,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO lms_content_format_master (format_code, format_name) VALUES
('TEXT','Plain Text'),
('HTML','HTML'),
('MARKDOWN','Markdown'),
('LATEX','LaTeX'),
('JSON','JSON');

CREATE TABLE lms_assessment_type_master (
    assessment_type_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    assessment_code VARCHAR(30) NOT NULL UNIQUE, -- HOMEWORK, QUIZ, QUEST, EXAM
    assessment_name VARCHAR(50) NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO lms_assessment_type_master (assessment_code, assessment_name) VALUES
('HOMEWORK','Homework'),
('QUIZ','Quiz'),
('QUEST','Quest'),
('EXAM','Exam');

-- ================= PHASE A2: HOMEWORK =================

CREATE TABLE lms_homework_master (
    homework_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    subject_id BIGINT UNSIGNED NOT NULL,
    homework_title VARCHAR(255) NOT NULL,
    homework_description LONGTEXT,
    content_format_id SMALLINT UNSIGNED NOT NULL,
    has_marks TINYINT(1) NOT NULL DEFAULT 0,
    max_marks DECIMAL(6,2),
    auto_release_on_topic_completion TINYINT(1) NOT NULL DEFAULT 1,
    homework_status_id SMALLINT UNSIGNED NOT NULL,
    due_date DATETIME NULL,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT UNSIGNED,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE lms_homework_topic_map (
    homework_topic_map_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    homework_id BIGINT UNSIGNED NOT NULL,
    topic_id BIGINT UNSIGNED NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_hw_topic (homework_id, topic_id)
);

CREATE TABLE lms_homework_submission (
    homework_submission_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    homework_id BIGINT UNSIGNED NOT NULL,
    student_id BIGINT UNSIGNED NOT NULL,
    submission_text LONGTEXT,
    attachment_path VARCHAR(500),
    submitted_at DATETIME,
    is_late TINYINT(1) DEFAULT 0,
    marks_awarded DECIMAL(6,2),
    review_status_id SMALLINT UNSIGNED NOT NULL,
    teacher_remark TEXT,
    reviewed_by BIGINT UNSIGNED,
    reviewed_at DATETIME,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_hw_student (homework_id, student_id)
);

-- ================= PHASE A3: QUESTION BANK EXTENSIONS =================

CREATE TABLE qns_question_review_log (
    review_log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id BIGINT UNSIGNED NOT NULL,
    reviewer_id BIGINT UNSIGNED NOT NULL,
    review_status_id SMALLINT UNSIGNED NOT NULL,
    review_comment TEXT,
    reviewed_at DATETIME NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0
);

CREATE TABLE qns_question_statistics (
    question_id BIGINT UNSIGNED PRIMARY KEY,
    difficulty_index DECIMAL(5,2),
    discrimination_index DECIMAL(5,2),
    guessing_factor DECIMAL(5,2),
    avg_time_seconds INT,
    min_time_seconds INT,
    max_time_seconds INT,
    total_attempts INT DEFAULT 0,
    last_calculated_at DATETIME
);

-- ================= PHASE A4: QUIZ =================

CREATE TABLE lms_quiz_master (
    quiz_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    subject_id BIGINT UNSIGNED NOT NULL,
    quiz_title VARCHAR(255) NOT NULL,
    instructions LONGTEXT,
    time_limit_minutes INT,
    allowed_attempts INT,
    passing_percentage DECIMAL(5,2),
    negative_marking_enabled TINYINT(1) DEFAULT 0,
    random_question_order TINYINT(1) DEFAULT 1,
    show_question_marks TINYINT(1) DEFAULT 1,
    quiz_status_id SMALLINT UNSIGNED NOT NULL,
    ordinal INT NOT NULL,
    scheduled_at DATETIME,
    publish_result_at DATETIME,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lms_quiz_question_map (
    quiz_question_map_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quiz_id BIGINT UNSIGNED NOT NULL,
    question_id BIGINT UNSIGNED NOT NULL,
    display_order INT,
    UNIQUE KEY uq_quiz_question (quiz_id, question_id)
);

-- ================= PHASE A5: QUEST =================

CREATE TABLE lms_quest_master (
    quest_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quest_title VARCHAR(255) NOT NULL,
    class_id BIGINT UNSIGNED NOT NULL,
    subject_id BIGINT UNSIGNED NOT NULL,
    time_limit_minutes INT,
    publish_result_at DATETIME,
    quest_status_id SMALLINT UNSIGNED NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lms_quest_question_map (
    quest_question_map_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quest_id BIGINT UNSIGNED NOT NULL,
    question_id BIGINT UNSIGNED NOT NULL,
    UNIQUE KEY uq_quest_question (quest_id, question_id)
);

-- ================= PHASE A6: EXAM =================

CREATE TABLE lms_exam_master (
    exam_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_name VARCHAR(255) NOT NULL,
    class_id BIGINT UNSIGNED NOT NULL,
    subject_id BIGINT UNSIGNED NOT NULL,
    time_limit_minutes INT,
    scheduled_at DATETIME,
    publish_result_at DATETIME,
    exam_status_id SMALLINT UNSIGNED NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lms_exam_question_map (
    exam_question_map_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_id BIGINT UNSIGNED NOT NULL,
    question_id BIGINT UNSIGNED NOT NULL,
    UNIQUE KEY uq_exam_question (exam_id, question_id)
);

-- ================= PHASE A7: ATTEMPTS =================

CREATE TABLE lms_student_attempt_master (
    attempt_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT UNSIGNED NOT NULL,
    assessment_type_id SMALLINT UNSIGNED NOT NULL,
    assessment_id BIGINT UNSIGNED NOT NULL,
    started_at DATETIME,
    completed_at DATETIME,
    score DECIMAL(6,2),
    performance_category_id SMALLINT UNSIGNED,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0
);

CREATE TABLE lms_attempt_question_behavior (
    behavior_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attempt_id BIGINT UNSIGNED NOT NULL,
    question_id BIGINT UNSIGNED NOT NULL,
    time_spent_seconds INT,
    answer_change_count INT,
    revisited TINYINT(1)
);

-- ================= PHASE A8: PERFORMANCE =================

CREATE TABLE slb_performance_category_master (
    performance_category_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_code VARCHAR(50) UNIQUE,
    category_name VARCHAR(100),
    min_percentage DECIMAL(5,2),
    max_percentage DECIMAL(5,2),
    auto_retest_required TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0
);

CREATE TABLE lms_rule_engine (
    rule_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trigger_event_code VARCHAR(50),
    condition_expression TEXT,
    action_code VARCHAR(50),
    is_active TINYINT(1) DEFAULT 1,
    is_deleted TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ==============================================================================================================
-- What This SQL File Contains
-- ✔ Phase A1 – Shared Masters
--   - Content format master
--   - Assessment type master
--   - Seed data (INSERTs)

-- ✔ Phase A2 – Homework & Assignment
--   - Homework master
--   - Homework ↔ topic mapping
--   - Student submissions & review lifecycle

-- ✔ Phase A3 – Question Bank Extensions
--   - Review & approval audit
--   - Psychometric & AI statistics

-- ✔ Phase A4 – Quiz Engine
--   - Quiz master
--   - Quiz ↔ question mapping

-- ✔ Phase A5 – Learning Quest
--   - Quest master
--   - Quest ↔ question mapping

-- ✔ Phase A6 – Online Exam
--   - Exam master
--   - Exam ↔ question mapping

-- ✔ Phase A7 – Student Attempt & Telemetry
--   - Attempt master
--   - Question-level behavioral telemetry

-- ✔ Phase A8 – Performance & Rule Engine
--   - Performance categories
--   - Rule engine config