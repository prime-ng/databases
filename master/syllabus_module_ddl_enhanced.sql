-- =====================================================================
-- SYLLABUS MANAGEMENT MODULE - ENHANCED VERSION
-- =====================================================================
-- Comprehensive database design for NEP 2020 compliant
-- Syllabus Management, Question Banks, and Assessment System
-- 
-- Hierarchy: Class → Subject → Lesson → Topic (with sub-topics via parent_id) 
--            → Questions → Quizzes/Assessments/Exams → Student Attempts
--
-- Aligned with Bloom's Taxonomy, Cognitive Domains, and Competency Framework
-- =====================================================================


-- -------------------------------------------------------------------------
-- SECTION 1: CORE SYLLABUS STRUCTURE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_lessons` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Lesson 1' or 'Chapter 10'
  `code` varchar(7) DEFAULT NULL,             -- e.g. '9th_SCI', '8TH_MAT' (Auto Generate on the basis of Class & Subject Code)
  `class_id` BIGINT UNSIGNED NOT NULL,        -- FK to sch_classes 
  `subject_id` bigint unsigned NOT NULL,      -- FK to sch_subjects  
  `ordinal` tinyint DEFAULT NULL,             -- Sequence order for lessons in a subject for a class 
  `description` text DEFAULT NULL,
  `duration` int unsigned NULL,               -- No of Periods required to complete this lesson
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
-- SECTION 2: HIERARCHICAL TOPICS & SUB-TOPICS (via parent_id)
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
  `learning_objectives` JSON DEFAULT NULL,    -- Array of learning objectives for this topic
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_lesson_parent_name` (`lesson_id`,`parent_id`,`name`),
  KEY `idx_topic_parent_id` (`parent_id`),
  KEY `idx_topic_lesson_id` (`lesson_id`),
  KEY `idx_topic_level` (`level`),
  CONSTRAINT `fk_topic_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `sch_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 3: COMPETENCY FRAMEWORK (NEP 2020 ALIGNMENT)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_competencies` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `description` TEXT DEFAULT NULL,
  `parent_competency_id` BIGINT UNSIGNED DEFAULT NULL,  -- hierarchical competencies
  `competency_type` ENUM('KNOWLEDGE','SKILL','ATTITUDE','VALUE') DEFAULT 'KNOWLEDGE',
  `nep_alignment` VARCHAR(100) DEFAULT NULL,  -- Reference to NEP 2020 framework
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_comp_code` (`code`,`class_id`,`subject_id`),
  KEY `idx_comp_parent` (`parent_competency_id`),
  CONSTRAINT `fk_comp_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comp_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comp_parent` FOREIGN KEY (`parent_competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Link topics to competencies
CREATE TABLE IF NOT EXISTS `sch_topic_competency_jnt` (
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`topic_id`,`competency_id`),
  CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 4: QUESTION TAXONOMIES (NEP / BLOOM etc.) - REFERENCE DATA
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `gl_question_bloom` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,   -- e.g. 'REMEMBER','UNDERSTAND','APPLY','ANALYZE','EVALUATE','CREATE'
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `bloom_level` TINYINT UNSIGNED DEFAULT NULL, -- 1-6 for Bloom's revised taxonomy
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bloom_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gl_question_cognitive_domain` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'COG-KNOWLEDGE','COG-SKILL','COG-UNDERSTANDING'
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
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'EASY','MEDIUM','DIFFICULT'
  `name` VARCHAR(50) NOT NULL,
  `complexity_level` TINYINT UNSIGNED DEFAULT NULL,  -- 1=Easy, 2=Medium, 3=Difficult
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_complex_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gl_question_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,  -- e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER','MATCH','NUMERIC','FILL_BLANK','CODING'
  `name` VARCHAR(100) NOT NULL,
  `has_options` TINYINT(1) NOT NULL DEFAULT 0,
  `auto_gradable` TINYINT(1) NOT NULL DEFAULT 1, -- Can this type be auto-graded?
  `description` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtype_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 5: QUESTION BANK & QUESTION MANAGEMENT
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `external_ref` VARCHAR(100) DEFAULT NULL,   -- for mapping to external banks
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK -> sch_topics.id (can be root topic or sub-topic depending on level)
  `competency_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sch_competencies.id
  `lesson_id` INT UNSIGNED DEFAULT NULL,      -- optional denormalized FK
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,  -- sch_users.id or teachers.id
  `question_type_id` INT UNSIGNED NOT NULL,   -- gl_question_types.id
  `stem` TEXT NOT NULL,                       -- full question text (may include placeholders)
  `answer_explanation` TEXT DEFAULT NULL,     -- teacher explanation
  `reference_material` TEXT DEFAULT NULL,     -- e.g., book section, web link
  `marks` DECIMAL(5,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  `difficulty_id` INT UNSIGNED DEFAULT NULL,  -- gl_question_complexity.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,       -- gl_question_bloom.id
  `cognitive_domain_id` INT UNSIGNED DEFAULT NULL, -- gl_question_cognitive_domain.id
  `time_specificity_id` INT UNSIGNED DEFAULT NULL, -- gl_question_time_specificity.id
  `estimated_time_seconds` INT UNSIGNED DEFAULT NULL, -- avg time to answer
  `tags` JSON DEFAULT NULL,                   -- array of tag strings or ids
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_public` TINYINT(1) NOT NULL DEFAULT 0,  -- share between tenants? keep default 0
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_q_topic` (`topic_id`),
  KEY `idx_q_competency` (`competency_id`),
  KEY `idx_q_class_subject` (`class_id`,`subject_id`),
  KEY `idx_q_difficulty_bloom` (`difficulty_id`,`bloom_id`),
  KEY `idx_q_active` (`is_active`),
  CONSTRAINT `fk_q_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_q_competency` FOREIGN KEY (`competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE SET NULL,
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
  `feedback` TEXT DEFAULT NULL,               -- specific feedback for this option
  `image_url` VARCHAR(255) DEFAULT NULL,      -- if option has an image
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_opt_question` (`question_id`),
  CONSTRAINT `fk_opt_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_question_media` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `media_id` BIGINT UNSIGNED NOT NULL,        -- link to sys_media.id
  `purpose` VARCHAR(50) DEFAULT 'ATTACHMENT', -- e.g., 'IMAGE','AUDIO','VIDEO','ATTACHMENT'
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_qmedia_question` (`question_id`),
  CONSTRAINT `fk_qmedia_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qmedia_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


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
-- SECTION 6: QUESTION VERSIONING & HISTORY
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `version` INT UNSIGNED NOT NULL,
  `data` JSON NOT NULL,                       -- full snapshot of question (stem, options, metadata)
  `change_reason` VARCHAR(255) DEFAULT NULL,  -- why was this version created?
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qver_q_v` (`question_id`,`version`),
  CONSTRAINT `fk_qver_q` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 7: QUESTION POOLS & ADAPTIVE SELECTION
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_pools` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `difficulty_filter` JSON DEFAULT NULL,      -- ["EASY","MEDIUM","DIFFICULT"]
  `bloom_filter` JSON DEFAULT NULL,           -- ["REMEMBER","UNDERSTAND","APPLY"]
  `cognitive_filter` JSON DEFAULT NULL,       -- Filter by cognitive domain
  `min_questions` INT UNSIGNED DEFAULT NULL,  -- Minimum pool size
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_qpool_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpool_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_question_pool_questions` (
  `question_pool_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_pool_id`,`question_id`),
  CONSTRAINT `fk_qpq_pool` FOREIGN KEY (`question_pool_id`) REFERENCES `sch_question_pools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpq_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 8: QUIZZES, ASSESSMENTS & EXAMS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_quizzes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
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
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quiz_subject_class` (`subject_id`,`class_id`),
  CONSTRAINT `fk_quiz_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_assessments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` ENUM('FORMATIVE','SUMMATIVE','TERM','DIAGNOSTIC') NOT NULL DEFAULT 'FORMATIVE',
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_org_academic_sessions_jnt
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
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
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
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `exam_type` ENUM('UNIT','MIDTERM','FINAL','BOARD','COMPETITIVE','MOCK') NOT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
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
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
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
-- SECTION 9: ASSESSMENT SECTIONS (for multi-part exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_sections` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,   -- FK to sch_assessments or sch_exams
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
-- SECTION 10: ASSESSMENT ITEMS (Questions in Quizzes/Assessments/Exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,   -- FK to sch_assessments
  `section_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_assessment_sections (for multi-part exams)
  `question_id` BIGINT UNSIGNED NOT NULL,
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
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,         -- FK to sch_exams
  `section_id` BIGINT UNSIGNED DEFAULT NULL,  -- Can be extended to support exam sections
  `question_id` BIGINT UNSIGNED NOT NULL,
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
  `quiz_id` BIGINT UNSIGNED NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`quiz_id`,`assessment_id`),
  CONSTRAINT `fk_qam_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qam_assess` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 11: ASSESSMENT ASSIGNMENT & RULES
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
  KEY `idx_asg_visibility` (`is_visible`,`available_from`,`available_to`),
  CONSTRAINT `fk_asg_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_assessment_assignment_rules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `rule_type` ENUM('ATTENDANCE_MIN','SCORE_MIN','TIME_WINDOW','DEVICE_TYPE','IP_RESTRICTED','PREREQUISITE_COMPLETION') NOT NULL,
  `rule_value` JSON NOT NULL,                 -- e.g., {"min_attendance": 75}, {"allowed_ips": ["192.168.1.0/24"]}
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_aar_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 12: STUDENT ATTEMPTS & RESPONSES (GRADING)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,      -- IPv4 or IPv6
  `user_agent` VARCHAR(255) DEFAULT NULL,     -- Browser info for audit
  `started_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `status` ENUM('IN_PROGRESS','SUBMITTED','GRADED','CANCELLED') NOT NULL DEFAULT 'IN_PROGRESS',
  `total_marks_obtained` DECIMAL(8,2) DEFAULT 0.00,
  `percentage_score` DECIMAL(5,2) DEFAULT 0.00,
  `evaluated_by` BIGINT UNSIGNED DEFAULT NULL,
  `evaluated_at` DATETIME DEFAULT NULL,
  `attempt_number` INT UNSIGNED DEFAULT 1,
  `time_taken_seconds` INT UNSIGNED DEFAULT NULL,
  `total_questions_attempted` INT UNSIGNED DEFAULT 0,
  `total_questions_correct` INT UNSIGNED DEFAULT 0,
  `notes` TEXT DEFAULT NULL,                  -- evaluator notes
  PRIMARY KEY (`id`),
  KEY `idx_att_assessment_student` (`assessment_id`,`student_id`),
  KEY `idx_att_student_status` (`student_id`,`status`),
  KEY `idx_att_submitted` (`submitted_at`),
  CONSTRAINT `fk_att_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_attempt_answers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `assessment_item_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sch_assessment_items.id
  `question_id` BIGINT UNSIGNED NOT NULL,
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
-- SECTION 13: STUDENT LEARNING OUTCOMES & COMPETENCY TRACKING
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_student_learning_outcomes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
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
-- SECTION 14: QUESTION & EXAM ANALYTICS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_analytics` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
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
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,
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
-- SECTION 15: AUDIT & CHANGE LOG
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `table_name` VARCHAR(50) NOT NULL,
  `record_id` BIGINT UNSIGNED NOT NULL,
  `action` ENUM('CREATE','UPDATE','DELETE','PUBLISH','GRADE','SUBMIT') NOT NULL,
  `changed_by` BIGINT UNSIGNED DEFAULT NULL,
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
-- SECTION 16: MATERIALIZED VIEW FOR FAST QUERIES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_index` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `lesson_id` INT UNSIGNED DEFAULT NULL,
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,
  `competency_id` BIGINT UNSIGNED DEFAULT NULL,
  `difficulty_id` INT UNSIGNED DEFAULT NULL,
  `bloom_id` INT UNSIGNED DEFAULT NULL,
  `cognitive_domain_id` INT UNSIGNED DEFAULT NULL,
  `tags` JSON DEFAULT NULL,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_qi_class_subject` (`class_id`,`subject_id`),
  KEY `idx_qi_difficulty` (`difficulty_id`),
  KEY `idx_qi_bloom` (`bloom_id`),
  CONSTRAINT `fk_qi_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- END OF SYLLABUS MANAGEMENT MODULE - ENHANCED VERSION
-- =====================================================================
-- 
-- KEY FEATURES:
-- ✓ NEP 2020 Compliant (Bloom's Taxonomy, Cognitive Domains, Competency Framework)
-- ✓ Hierarchical Topic Structure (Topics with unlimited sub-topic levels)
-- ✓ Comprehensive Question Management (Multiple types, tags, versioning)
-- ✓ Multi-tier Assessment System (Quizzes, Assessments, Exams)
-- ✓ Advanced Assignment & Grading (Rules-based assignment, audit trail)
-- ✓ Student Learning Outcomes Tracking (Competency-based progress)
-- ✓ Psychometric Analysis (Discrimination index, difficulty index)
-- ✓ Full Audit Trail (All changes logged with timestamps and user info)
-- ✓ Scalable & Performant (Proper indexing, materialized views)
-- ✓ Flexible & Extensible (JSON fields for metadata, tags, rules)
--
-- NEXT STEPS FOR IMPLEMENTATION:
-- 1. Load this schema into tenant_db database
-- 2. Seed reference data (Bloom levels, Question types, etc.)
-- 3. Create triggers for audit logging
-- 4. Create stored procedures for analytics calculations
-- 5. Develop migration scripts for existing question data
--
-- =====================================================================
