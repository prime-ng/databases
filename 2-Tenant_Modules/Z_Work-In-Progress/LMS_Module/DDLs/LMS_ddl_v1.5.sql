-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 1.4
-- =====================================================================
-- Hierarchy: Class → Subject → Lesson → Topic → Sub-topic → Mini Topic 
--            → Sub-Mini Topic → Micro Topic → Sub-Micro Topic (Unlimited)
-- -------------------------------------------------------------------------
-- TABLE PREFIX:  
  -- slb - Syllabus & Curriculum Management
  -- exm - Exam Management
  -- quz - Quiz & Assessment Management
  -- qns - Questiona Creation & Management
  -- beh - Behaviour Management
  -- rec - Recommendations Module
-- -------------------------------------------------------------------------
-- NEW IN v1.4 / 1.5:
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
-- -------------------------------------------------------------------------

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;




-- =========================================================================
-- RECOMMENDATION MODULE (Performance Based Recommendations)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `rec_recommendation_materials` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `material_type` ENUM('TEXT','VIDEO','PDF','AUDIO','QUIZ','ASSIGNMENT','LINK') NOT NULL,
  `content` LONGTEXT DEFAULT NULL,      -- HTML / text (for TEXT)
  `media_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_media_store
  `external_url` VARCHAR(500) DEFAULT NULL, -- External URL (for LINK)
  `subject_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_subjects
  `class_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_classes
  `topic_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_topics
  `difficulty_level` ENUM('EASY','MEDIUM','HARD') DEFAULT 'MEDIUM',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  KEY `idx_material_scope` (`class_id`, `subject_id`, `topic_id`),
  KEY `idx_material_type` (`material_type`),
  KEY `idx_material_active` (`is_active`),
  CONSTRAINT `fk_rmat_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rmat_subject` FOREIGN KEY (`subject_id`) REFERENCES `qns_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rmat_class` FOREIGN KEY (`class_id`) REFERENCES `qns_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rmat_topic` FOREIGN KEY (`topic_id`) REFERENCES `qns_topics` (`id`) ON DELETE SET NULL 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `rec_recommendation_rules` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `school_id` INT UNSIGNED DEFAULT NULL, 
  -- NULL = System default rule
  `performance_category_id` INT UNSIGNED NOT NULL, -- FK to slb_performance_categories
  `subject_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_subjects
  `class_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_classes
  `topic_id` INT UNSIGNED DEFAULT NULL, -- FK to qns_topics
  `recommendation_goal` ENUM('REVISION','PRACTICE','REMEDIAL','ADVANCED','ENRICHMENT') NOT NULL,
  `material_type` ENUM('TEXT','VIDEO','PDF','QUIZ','ASSIGNMENT') NOT NULL,
  `max_items` SMALLINT UNSIGNED DEFAULT 5,
  `priority` SMALLINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP DEFAULT NULL,
  CONSTRAINT `fk_rule_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_rule_subject` FOREIGN KEY (`subject_id`) REFERENCES `qns_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rule_class` FOREIGN KEY (`class_id`) REFERENCES `qns_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rule_topic` FOREIGN KEY (`topic_id`) REFERENCES `qns_topics` (`id`) ON DELETE SET NULL
  KEY `idx_rule_scope` (`school_id`, `class_id`, `subject_id`, `topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rec_student_recommendations` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL, -- FK to users
  `school_id` INT UNSIGNED NOT NULL, -- FK to schools
  `performance_category_id` INT UNSIGNED NOT NULL, -- FK to slb_performance_categories
  `recommendation_rule_id` INT UNSIGNED NOT NULL, -- FK to rec_recommendation_rules
  `material_id` INT UNSIGNED NOT NULL, -- FK to rec_recommendation_materials
  `recommended_for` ENUM('DAILY','WEEKLY','MONTHLY','EXAM_PREP') DEFAULT 'WEEKLY',
  `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED') DEFAULT 'PENDING',
  `relevance_score` DECIMAL(5,2) DEFAULT NULL, -- for future AI ranking
  `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `consumed_at` TIMESTAMP NULL,
  UNIQUE KEY `uq_student_material` (`student_id`, `material_id`),
  KEY `idx_student_status` (`student_id`, `status`),
  KEY `idx_student_school` (`school_id`, `student_id`),
  CONSTRAINT `fk_stud_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_stud_rule` FOREIGN KEY (`recommendation_rule_id`) REFERENCES `rec_recommendation_rules`(`id`),
  CONSTRAINT `fk_stud_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials`(`id`),
  CONSTRAINT `fk_stud_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_stud_school` FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rec_student_performance_snapshot` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `school_id` INT UNSIGNED NOT NULL,
  `performance_category_id` INT UNSIGNED NOT NULL,
  `recommendation_rule_id` INT UNSIGNED NOT NULL,
  `material_id` INT UNSIGNED NOT NULL,
  `recommended_for` ENUM('DAILY','WEEKLY','MONTHLY','EXAM_PREP') DEFAULT 'WEEKLY',
  `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED') DEFAULT 'PENDING',
  `relevance_score` DECIMAL(5,2) DEFAULT NULL, -- for future AI ranking
  `generated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `consumed_at` TIMESTAMP NULL,
  UNIQUE KEY `uq_student_material` (`student_id`, `material_id`),
  KEY `idx_student_status` (`student_id`, `status`),
  KEY `idx_student_school` (`school_id`, `student_id`),
  CONSTRAINT `fk_stud_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_stud_rule` FOREIGN KEY (`recommendation_rule_id`) REFERENCES `rec_recommendation_rules`(`id`),
  CONSTRAINT `fk_stud_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials`(`id`),
  CONSTRAINT `fk_stud_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_stud_school` FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rec_student_performance_snapshot` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `school_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED DEFAULT NULL,
  `percentage` DECIMAL(5,2) NOT NULL,
  `performance_category_id` INT UNSIGNED NOT NULL,
  `assessment_type` ENUM('QUIZ','TEST','EXAM','TERM','OVERALL') NOT NULL,
  `captured_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `consumed_at` TIMESTAMP NULL,
  KEY `idx_student_perf` (`student_id`, `captured_at`),
  KEY `idx_student_school` (`school_id`, `student_id`),
  CONSTRAINT `fk_stud_perf_cat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories`(`id`),
  CONSTRAINT `fk_stud_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_stud_school` FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`),
  CONSTRAINT `fk_stud_class` FOREIGN KEY (`class_id`) REFERENCES `qns_classes`(`id`),
  CONSTRAINT `fk_stud_subject` FOREIGN KEY (`subject_id`) REFERENCES `qns_subjects`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- =========================================================================
-- QUIZ MODULE 
-- =========================================================================

-- -------------------------------------------------------------------------
-- QUESTION POOLS & ADAPTIVE SELECTION
-- -------------------------------------------------------------------------
-- This table is used to create question pools for adaptive selection
CREATE TABLE IF NOT EXISTS `qns_question_pools` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `complexity_filter` JSON DEFAULT NULL,      -- ["EASY","MEDIUM","DIFFICULT"]
  `bloom_filter` JSON DEFAULT NULL,           -- ["REMEMBER","UNDERSTAND","APPLY"]
  `cognitive_filter` JSON DEFAULT NULL,       -- Filter by cognitive skills
  `ques_type_specificity_filter` JSON DEFAULT NULL, -- e.g., ["IN_CLASS","HOMEWORK"]
  `min_questions` INT UNSIGNED DEFAULT NULL,  -- Minimum pool size
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_qpool_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpool_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qns_question_pool_questions_jnt` (
  `question_pool_id` INT UNSIGNED NOT NULL,
  `question_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_pool_id`,`question_id`),
  CONSTRAINT `fk_qpq_pool` FOREIGN KEY (`question_pool_id`) REFERENCES `qns_question_pools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpq_question` FOREIGN KEY (`question_id`) REFERENCES `qns_questions_bank` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- -------------------------------------------------------------------------
-- QUIZ MODULE (Quizzes, Assessments & Exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_quizzes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` INT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `lesson_id` INT UNSIGNED DEFAULT NULL,
  `quiz_type` ENUM('PRACTICE','DIAGNOSTIC','REINFORCEMENT') DEFAULT 'PRACTICE',
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_answers_immediately` TINYINT(1) DEFAULT 1,
  `allow_review_before_submit` TINYINT(1) DEFAULT 1,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `auto_assign_on_topic_completion` TINYINT(1) DEFAULT 0,
  `objective_only` TINYINT(1) DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quiz_subject_class` (`subject_id`,`class_id`),
  CONSTRAINT `fk_quiz_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_assessments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` ENUM('FORMATIVE','SUMMATIVE','TERM','DIAGNOSTIC') NOT NULL DEFAULT 'FORMATIVE',
  `description` TEXT DEFAULT NULL,
  `subject_id` INT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `academic_session_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_org_academic_sessions_jnt
  `start_datetime` DATETIME DEFAULT NULL,
  `end_datetime` DATETIME DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `negative_marking_enabled` TINYINT(1) DEFAULT 0,
  `show_answers_after_exam` TINYINT(1) DEFAULT 0,
  `show_answers_on_date` DATE DEFAULT NULL,
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `allow_review_before_submit` TINYINT(1) DEFAULT 1,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `can_attempt_at_home` TINYINT(1) DEFAULT 1,
  `requires_proctoring` TINYINT(1) DEFAULT 0,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_assess_subject_class` (`subject_id`,`class_id`),
  KEY `idx_assess_type` (`type`),
  CONSTRAINT `fk_assess_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_assess_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_assess_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_exams` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `exam_type` ENUM('UNIT','MIDTERM','FINAL','BOARD','COMPETITIVE','MOCK') NOT NULL,
  `subject_id` INT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `academic_session_id` INT UNSIGNED DEFAULT NULL,
  `scheduled_date` DATE NOT NULL,
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `duration_minutes` INT UNSIGNED NOT NULL,
  `total_marks` DECIMAL(7,2) NOT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `negative_marking_enabled` TINYINT(1) DEFAULT 0,
  `show_answers_after_exam` TINYINT(1) DEFAULT 0,
  `show_answers_on_date` DATE DEFAULT NULL,
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `allow_review_before_submit` TINYINT(1) DEFAULT 0,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `exam_mode` ENUM('ONLINE','OFFLINE','HYBRID') DEFAULT 'ONLINE',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_exam_date_class` (`scheduled_date`,`class_id`),
  KEY `idx_exam_type` (`exam_type`),
  CONSTRAINT `fk_exam_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exam_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exam_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- ASSESSMENT SECTIONS (for multi-part exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_sections` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` INT UNSIGNED NOT NULL,   -- FK to sch_assessments or sch_exams
  `section_name` VARCHAR(100) NOT NULL,       -- e.g., "Part A: Reading", "Part B: Writing"
  `ordinal` TINYINT UNSIGNED NOT NULL,
  `description` TEXT DEFAULT NULL,
  `section_marks` DECIMAL(7,2) DEFAULT NULL, -- total marks for this section
  `instructions` TEXT DEFAULT NULL,           -- special instructions for this section
  `shuffle_questions` TINYINT(1) DEFAULT 0,   -- randomize question order per student
  PRIMARY KEY (`id`),
  KEY `idx_section_assessment` (`assessment_id`),
  CONSTRAINT `fk_section_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- ASSESSMENT ITEMS (Questions in Quizzes/Assessments/Exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` INT UNSIGNED NOT NULL,   -- FK to sch_assessments
  `section_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_assessment_sections (for multi-part exams)
  `question_id` INT UNSIGNED NOT NULL,
  `marks` DECIMAL(6,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(6,2) DEFAULT 0.00,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_answer_explanation` TINYINT(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_ai_assessment` (`assessment_id`),
  KEY `idx_ai_section` (`section_id`),
  CONSTRAINT `fk_ai_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_section` FOREIGN KEY (`section_id`) REFERENCES `sch_assessment_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_exam_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,         -- FK to sch_exams
  `section_id` INT UNSIGNED DEFAULT NULL,  -- Can be extended to support exam sections
  `question_id` INT UNSIGNED NOT NULL,
  `marks` DECIMAL(6,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(6,2) DEFAULT 0.00,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_answer_explanation` TINYINT(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_ei_exam` (`exam_id`),
  CONSTRAINT `fk_ei_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ei_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_quiz_assessment_map` (
  `quiz_id` INT UNSIGNED NOT NULL,
  `assessment_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`quiz_id`,`assessment_id`),
  CONSTRAINT `fk_qam_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qam_assess` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- ASSESSMENT ASSIGNMENT & RULES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_assignments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` INT UNSIGNED NOT NULL,
  `assigned_to_type` ENUM('CLASS_SECTION','STUDENT','SUBJECT_GROUP','TEACHER') NOT NULL,
  `assigned_to_id` INT UNSIGNED NOT NULL,  -- id of class_section / student / subject_group / teacher
  `available_from` DATETIME DEFAULT NULL,
  `available_to` DATETIME DEFAULT NULL,
  `max_attempts` INT UNSIGNED DEFAULT 1,
  `is_visible` TINYINT(1) DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_asg_assessment` (`assessment_id`),
  KEY `idx_asg_visibility` (`is_visible`,`available_from`,`available_to`),
  CONSTRAINT `fk_asg_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_assessment_assignment_rules` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` INT UNSIGNED NOT NULL,
  `rule_type` ENUM('ATTENDANCE_MIN','SCORE_MIN','TIME_WINDOW','DEVICE_TYPE','IP_RESTRICTED','PREREQUISITE_COMPLETION') NOT NULL,
  `rule_value` JSON NOT NULL,                 -- e.g., {"min_attendance": 75}, {"allowed_ips": ["192.168.1.0/24"]}
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_aar_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- QUIZ MODULE 
-- =========================================================================

-- -------------------------------------------------------------------------
-- STUDENT ATTEMPTS & RESPONSES (GRADING)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_attempts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,      -- IPv4 or IPv6
  `user_agent` VARCHAR(255) DEFAULT NULL,     -- Browser info for audit
  `started_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `status` ENUM('IN_PROGRESS','SUBMITTED','GRADED','CANCELLED') NOT NULL DEFAULT 'IN_PROGRESS',
  `total_marks_obtained` DECIMAL(8,2) DEFAULT 0.00,
  `percentage_score` DECIMAL(5,2) DEFAULT 0.00,
  `evaluated_by` INT UNSIGNED DEFAULT NULL,
  `evaluated_at` DATETIME DEFAULT NULL,
  `attempt_number` INT UNSIGNED DEFAULT 1,
  `time_taken_seconds` INT UNSIGNED DEFAULT NULL,
  `total_questions_attempted` INT UNSIGNED DEFAULT 0,
  `total_questions_correct` INT UNSIGNED DEFAULT 0,
  `notes` TEXT DEFAULT NULL,                  -- evaluator notes
  `confidence_level` DECIMAL(5,2) DEFAULT NULL,
  `performance_category_id` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),  
  KEY `idx_att_assessment_student` (`assessment_id`,`student_id`),
  KEY `idx_att_student_status` (`student_id`,`status`),
  KEY `idx_att_submitted` (`submitted_at`),
  KEY `idx_att_perfcat` (`performance_category_id`),
  CONSTRAINT `fk_att_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_attempt_answers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` INT UNSIGNED NOT NULL,
  `assessment_item_id` INT UNSIGNED DEFAULT NULL, -- FK to sch_assessment_items.id
  `question_id` INT UNSIGNED NOT NULL,
  `selected_option_ids` JSON DEFAULT NULL,    -- for MCQ multi-select: array of option ids
  `answer_text` TEXT DEFAULT NULL,            -- for short/long answers, code, numeric answers etc.
  `marks_awarded` DECIMAL(7,2) DEFAULT 0.00,
  `is_correct` TINYINT(1) DEFAULT NULL,
  `grader_note` TEXT DEFAULT NULL,
  `answered_at` DATETIME DEFAULT NULL,
  `time_taken_seconds` INT UNSIGNED DEFAULT NULL,
  `review_count` TINYINT UNSIGNED DEFAULT 0,  -- how many times reviewed before submission
  PRIMARY KEY (`id`),
  KEY `idx_aa_attempt` (`attempt_id`),
  KEY `idx_aa_question` (`question_id`),
  CONSTRAINT `fk_aa_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `sch_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_aa_item` FOREIGN KEY (`assessment_item_id`) REFERENCES `sch_assessment_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_aa_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- STUDENT LEARNING OUTCOMES & COMPETENCY TRACKING
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_student_learning_outcomes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `competency_id` INT UNSIGNED NOT NULL,
  `topic_id` INT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `bloom_level` VARCHAR(50) DEFAULT NULL,     -- from questions attempted
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `correct_attempts` INT UNSIGNED DEFAULT 0,
  `last_attempt_date` DATE DEFAULT NULL,
  `mastery_status` ENUM('NOT_STARTED','IN_PROGRESS','PROFICIENT','MASTERED') DEFAULT 'NOT_STARTED',
  `progress_percentage` DECIMAL(5,2) DEFAULT 0,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slo_student_competency_topic` (`student_id`,`competency_id`,`topic_id`),
  KEY `idx_slo_student` (`student_id`),
  KEY `idx_slo_mastery` (`mastery_status`),
  CONSTRAINT `fk_slo_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_competency` FOREIGN KEY (`competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- QUESTION & EXAM ANALYTICS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_analytics` (
  `question_id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `correct_attempts` INT UNSIGNED DEFAULT 0,
  `avg_time_seconds` INT UNSIGNED DEFAULT NULL,
  `discrimination_index` DECIMAL(4,3) DEFAULT NULL,  -- (correct top 27% - correct bottom 27%) / group_size
  `difficulty_index` DECIMAL(4,3) DEFAULT NULL,      -- total_correct / total_attempts
  `discrimination_status` VARCHAR(20) DEFAULT NULL,   -- 'GOOD','FAIR','POOR'
  `last_used` DATE DEFAULT NULL,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_qa_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_exam_analytics` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` INT UNSIGNED NOT NULL,
  `total_students_assigned` INT UNSIGNED DEFAULT 0,
  `total_students_attempted` INT UNSIGNED DEFAULT 0,
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `highest_score` DECIMAL(8,2) DEFAULT NULL,
  `lowest_score` DECIMAL(8,2) DEFAULT NULL,
  `pass_count` INT UNSIGNED DEFAULT 0,
  `fail_count` INT UNSIGNED DEFAULT 0,
  `pass_percentage` DECIMAL(5,2) DEFAULT NULL,
  `standard_deviation` DECIMAL(8,2) DEFAULT NULL,
  `question_difficulty_avg` DECIMAL(4,3) DEFAULT NULL,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ea_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- AUDIT & CHANGE LOG
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_audit_log` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `table_name` VARCHAR(50) NOT NULL,
  `record_id` INT UNSIGNED NOT NULL,
  `action` ENUM('CREATE','UPDATE','DELETE','PUBLISH','GRADE','SUBMIT') NOT NULL,
  `changed_by` INT UNSIGNED DEFAULT NULL,
  `old_values` JSON DEFAULT NULL,
  `new_values` JSON DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_table_record` (`table_name`,`record_id`),
  KEY `idx_audit_action` (`action`),
  KEY `idx_audit_timestamp` (`timestamp`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- MATERIALIZED VIEW FOR FAST QUERIES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_index` (
  `question_id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `class_id` INT UNSIGNED DEFAULT NULL,                       -- sch_classes.id
  `subject_id` INT UNSIGNED DEFAULT NULL,                  -- sch_subjects.id
  `lesson_id` INT UNSIGNED DEFAULT NULL,                      -- denormalized for faster filtering
  `topic_id` INT UNSIGNED DEFAULT NULL,                    -- sch_topics.id
  `competency_id` INT UNSIGNED DEFAULT NULL,               -- sch_competencies.id
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,            -- slb_complexity_level.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,                       -- slb_bloom_taxonomy.id
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL,             -- slb_cognitive_skill.id
  `question_type_id` INT UNSIGNED DEFAULT NULL,               -- gl_question_types.id
  `marks` DECIMAL(5,2) DEFAULT NULL,                          -- marks allocated
  `negative_marks` DECIMAL(5,2) DEFAULT NULL,                 -- negative marks
  `average_time_to_answer_seconds` INT UNSIGNED DEFAULT NULL, -- estimated time to answer
  `tags` JSON DEFAULT NULL,                                   -- array of tag strings or ids
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_qi_class_subject` (`class_id`,`subject_id`),
  KEY `idx_qi_complexity` (`complexity_level_id`),
  KEY `idx_qi_bloom` (`bloom_id`),
  CONSTRAINT `fk_qi_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;







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
  `taught_by_teacher_id` INT UNSIGNED DEFAULT NULL,
  `planned_periods` SMALLINT UNSIGNED DEFAULT NULL,  -- Number of periods planned for this topic
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
-- INDEXES FOR REPORTING QUERIES
-- =========================================================================

-- Composite indexes for common analytics queries
CREATE INDEX `idx_topics_class_subject_level` ON `slb_topics` (`class_id`, `subject_id`, `level`);
CREATE INDEX `idx_questions_class_subject_topic` ON `sch_questions` (`class_id`, `subject_id`, `topic_id`);
CREATE INDEX `idx_attempts_date_class` ON `sch_attempts` (`submitted_at`, `assessment_id`);


SET FOREIGN_KEY_CHECKS = 1;

-- For QUESTION MERGE (Will be used in future)
-- -------------------------------------------
-- Table - slb_school_question_map
-- CREATE TABLE slb_school_question_map (
--   tenant_id INT UNSIGNED NOT NULL,
--   question_id INT UNSIGNED NOT NULL,
--   is_customized TINYINT(1) DEFAULT 0,
--   is_enabled TINYINT(1) DEFAULT 1,

--   PRIMARY KEY (tenant_id, question_id),
--   FOREIGN KEY (question_id) REFERENCES slb_questions(id)
-- );


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
--
-- IDEA TO BE CREATED
-- -------------------
-- 1. I need to Capture Different Types of Recommendation as per the Performance of the Student
-- 2. Will Capture Student Behaviour while attempting Questions Like -
--    a. Student Confidence & Hesitation
--    b. Student Weak Areas & Strong Areas
--    c. Student Learning Behavior, Style, Speed, Pattern, Habit
--    d. Student Learning Capability, Potential


-------------------------------------------------------------------------------
-- Variables for sys_settings table
-------------------------------------------------------------------------------
-- 1. Question can be re-use in Quiz, Assessment, Exam, etc.
-- 2. Manytimes Question need knowledge of multiple Topics to answer. So, Question Marks wil be distributed among linked Topics on the basis of Weightage. 
--    e.g. if a Question is linked to 3 Topics with weightage 20%, 30%, 50% then QuestionMarks will be distributed as 20%, 30%, 50%.
-- 3. 
