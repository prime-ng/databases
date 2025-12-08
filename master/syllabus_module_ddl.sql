
-- -------------------------------------------------------------------------
-- Syllabus Module
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_lessons` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Lesson 1' or 'Class 10'
  `code` varchar(7) DEFAULT NULL,             -- e.g. '9th_SCI', '8TH_MAT' (Auto Generate on the basis of Class & Subject Code)
  `class_id` BIGINT UNSIGNED NOT NULL,        -- FK to sch_classes 
  `subject_id` bigint unsigned NOT NULL,      -- FK to sch_subjects  
  `ordinal` tinyint DEFAULT NULL,        -- This is signed tinyint to have (1,2,3,4,5....10) lessons in a subject for a class 
  `description` text DEFAULT NULL,
  `duration` int unsigned NULL,    -- No of Periods required to complete this lesson
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_class_Subject_name` (`class_id`,'subject_id','name'),
  UNIQUE KEY `uq_lesson_class_Subject_ordinal` (`class_id`,'subject_id',`ordinal`),
  CONSTRAINT `fk_lesson_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lesson_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- Syllabus: Topics & Sub-Topics (Consolidated with parent_id hierarchy)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_topics` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to self (NULL for root topics, set to parent topic_id for sub-topics)
  `lesson_id` INT UNSIGNED NOT NULL,          -- FK -> sch_lessons.id
  `class_id` INT UNSIGNED NOT NULL,           -- FK -> sch_classes.id (redundant for fast queries)
  `subject_id` BIGINT UNSIGNED NOT NULL,      -- FK -> sch_subjects.id (redundant)
  `name` VARCHAR(255) NOT NULL,
  `short_name` VARCHAR(50) DEFAULT NULL,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `level` TINYINT UNSIGNED NOT NULL DEFAULT 0, -- 0=root topic, 1=sub-topic, 2+=deeper levels (if needed)
  `description` TEXT DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL, -- approximate teaching time
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_lesson_parent_name` (`lesson_id`,`parent_id`,`name`),
  KEY `idx_topic_parent_id` (`parent_id`),
  KEY `idx_topic_lesson_id` (`lesson_id`),
  CONSTRAINT `fk_topic_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `sch_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- Question taxonomies (NEP / Bloom etc.) - seedable lookup tables
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `gl_question_bloom` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,   -- e.g. 'REMEMBER','UNDERSTAND','APPLY','ANALYZE','EVALUATE','CREATE'
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bloom_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gl_question_cognitive_domain` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'COG-KNOWLEDGE','COG-SKILL'
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cog_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gl_question_time_specificity` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'IN_CLASS','HOMEWORK','SUMMATIVE','FORMATIVE'
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_timeSpec_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gl_question_complexity` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'LOW','MEDIUM','HIGH'
  `name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_complex_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gl_question_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,  -- e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER','MATCH','NUMERIC','FILL_BLANK','CODING'
  `name` VARCHAR(100) NOT NULL,
  `has_options` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtype_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- Questions & supporting tables
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `external_ref` VARCHAR(100) DEFAULT NULL, -- for mapping to external banks
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK -> sch_topics.id (can be root topic or sub-topic depending on level)
  `lesson_id` INT UNSIGNED DEFAULT NULL,     -- optional denormalized FK
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `created_by` BIGINT UNSIGNED DEFAULT NULL, -- sch_users.id or teachers.id
  `question_type_id` INT UNSIGNED NOT NULL,  -- gl_question_types.id
  `stem` TEXT NOT NULL,                      -- full question text (may include placeholders)
  `answer_explanation` TEXT DEFAULT NULL,    -- teacher explanation
  `marks` DECIMAL(5,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  `difficulty_id` INT UNSIGNED DEFAULT NULL, -- gl_question_complexity.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,      -- gl_question_bloom.id
  `cognitive_domain_id` INT UNSIGNED DEFAULT NULL, -- gl_question_cognitive_domain.id
  `time_specificity_id` INT UNSIGNED DEFAULT NULL, -- gl_question_time_specificity.id
  `tags` JSON DEFAULT NULL,                  -- array of tag strings or ids
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_public` TINYINT(1) NOT NULL DEFAULT 0, -- share between tenants? keep default 0
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_q_topic` (`topic_id`),
  KEY `idx_q_class_subject` (`class_id`,`subject_id`),
  CONSTRAINT `fk_q_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_type` FOREIGN KEY (`question_type_id`) REFERENCES `gl_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_q_difficulty` FOREIGN KEY (`difficulty_id`) REFERENCES `gl_question_complexity` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `gl_question_bloom` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_cog` FOREIGN KEY (`cognitive_domain_id`) REFERENCES `gl_question_cognitive_domain` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_timeSpec` FOREIGN KEY (`time_specificity_id`) REFERENCES `gl_question_time_specificity` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_question_options` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `option_text` TEXT NOT NULL,
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
  `feedback` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_opt_question` (`question_id`),
  CONSTRAINT `fk_opt_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_question_media` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `media_id` BIGINT UNSIGNED NOT NULL,  -- link to sys_media.id (you already have sys_media)
  `purpose` VARCHAR(50) DEFAULT 'ATTACHMENT', -- e.g., 'IMAGE','AUDIO','ATTACHMENT'
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_qmedia_question` (`question_id`),
  CONSTRAINT `fk_qmedia_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qmedia_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Optional: tags table (free-form) and join table (for filtering)
CREATE TABLE IF NOT EXISTS `sch_question_tags` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtag_short` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_question_tag_jnt` (
  `question_id` BIGINT UNSIGNED NOT NULL,
  `tag_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_id`,`tag_id`),
  CONSTRAINT `fk_qtag_q` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qtag_tag` FOREIGN KEY (`tag_id`) REFERENCES `sch_question_tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- Question versioning/history (simple approach)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_question_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `version` INT UNSIGNED NOT NULL,
  `data` JSON NOT NULL,                -- full snapshot of question (stem, options, metadata)
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qver_q_v` (`question_id`,`version`),
  CONSTRAINT `fk_qver_q` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- Quizzes / Assessments / Exams
-- One items table to be shared by quizzes and assessments
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_quizzes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `lesson_id` INT UNSIGNED DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_quiz_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_assessments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` ENUM('FORMATIVE','SUMMATIVE','TERM','EXAM') NOT NULL DEFAULT 'FORMATIVE',
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `start_datetime` DATETIME DEFAULT NULL,
  `end_datetime` DATETIME DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_assess_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_assess_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_assessment_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,  -- can link to quiz.id or assessment.id (use assessment for both)
  `question_id` BIGINT UNSIGNED NOT NULL,
  `marks` DECIMAL(6,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(6,2) DEFAULT 0.00,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_ai_assessment` (`assessment_id`),
  CONSTRAINT `fk_ai_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- If you want quizzes and assessments separate but share items, you can create a small mapping:
CREATE TABLE IF NOT EXISTS `sch_quiz_assessment_map` (
  `quiz_id` BIGINT UNSIGNED NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`quiz_id`,`assessment_id`),
  CONSTRAINT `fk_qam_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qam_assess` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- Assignments (who gets the quiz/assessment)
-- You can assign to class_section, subject_group, individual students or teachers
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_assessment_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `assigned_to_type` ENUM('CLASS_SECTION','STUDENT','SUBJECT_GROUP','TEACHER') NOT NULL,
  `assigned_to_id` BIGINT UNSIGNED NOT NULL,  -- id of class_section / student / subject_group / teacher
  `available_from` DATETIME DEFAULT NULL,
  `available_to` DATETIME DEFAULT NULL,
  `max_attempts` INT UNSIGNED DEFAULT 1,
  `is_visible` TINYINT(1) DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_asg_assessment` (`assessment_id`),
  CONSTRAINT `fk_asg_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- If you prefer normalized assignment columns, we can add class_section_id / student_id columns instead of assigned_to_type; above keeps flexibility.


-- -------------------------------------------------------------------------
-- Student Attempts & Answers (grading)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `started_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `status` ENUM('IN_PROGRESS','SUBMITTED','GRADED','CANCELLED') NOT NULL DEFAULT 'IN_PROGRESS',
  `total_marks_obtained` DECIMAL(8,2) DEFAULT 0.00,
  `evaluated_by` BIGINT UNSIGNED DEFAULT NULL,
  `evaluated_at` DATETIME DEFAULT NULL,
  `attempt_number` INT UNSIGNED DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_att_assessment_student` (`assessment_id`,`student_id`),
  CONSTRAINT `fk_att_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_attempt_answers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `assessment_item_id` BIGINT UNSIGNED DEFAULT NULL, -- fk to sch_assessment_items.id
  `question_id` BIGINT UNSIGNED NOT NULL,
  `selected_option_ids` JSON DEFAULT NULL,   -- for MCQ multi-select: array of option ids
  `answer_text` TEXT DEFAULT NULL,            -- for short/long answers, code, numeric answers etc.
  `marks_awarded` DECIMAL(7,2) DEFAULT 0.00,
  `is_correct` TINYINT(1) DEFAULT NULL,
  `grader_note` TEXT DEFAULT NULL,
  `answered_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_aa_attempt` (`attempt_id`),
  CONSTRAINT `fk_aa_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `sch_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_aa_item` FOREIGN KEY (`assessment_item_id`) REFERENCES `sch_assessment_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_aa_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- Convenience: materialized mapping to quickly find questions by class/subject/lesson
-- (Optional: populate via triggers or nightly job)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sch_question_index` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `lesson_id` INT UNSIGNED DEFAULT NULL,
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `sub_topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `difficulty_id` INT UNSIGNED DEFAULT NULL,
  `bloom_id` INT UNSIGNED DEFAULT NULL,
  `tags` JSON DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;
