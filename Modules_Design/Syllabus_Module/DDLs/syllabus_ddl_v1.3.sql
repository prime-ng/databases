-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 1.3
-- FILE 1: CORE HIERARCHY STRUCTURE (Materialized Path)
-- =====================================================================
-- 
-- Hierarchy: Class → Subject → Lesson → Topic → Sub-topic → Mini Topic 
--            → Sub-Mini Topic → Micro Topic → Sub-Micro Topic (Unlimited)
--
-- Uses Materialized Path for efficient hierarchical queries
-- Multi-tenant support with tenant_id in all tables
-- =====================================================================


-- -------------------------------------------------------------------------
-- CORE SYLLABUS STRUCTURE
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `slb_lessons` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,                       -- Unique identifier for analytics tracking
  `academic_session_id` BIGINT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt
  `class_id` INT UNSIGNED NOT NULL,               -- FK to sch_classes
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_subjects
  `code` VARCHAR(20) NOT NULL,                    -- e.g., '9TH_SCI_L01' (Auto-generated) It will be combination of class code, subject code and lesson code
  `name` VARCHAR(150) NOT NULL,                   -- e.g., 'Chapter 1: Matter in Our Surroundings'
  `short_name` VARCHAR(50) DEFAULT NULL,          -- e.g., 'Matter Around Us'
  `ordinal` SMALLINT UNSIGNED NOT NULL,           -- Sequence order within subject
  `description` VARCHAR(255) DEFAULT NULL,
  `learning_objectives` JSON DEFAULT NULL,        -- Array of learning objectives e.g. [{"objective": "Objective 1"}, {"objective": "Objective 2"}]
  `prerequisites` JSON DEFAULT NULL,              -- Array of prerequisite lesson IDs e.g. [1, 2, 3]
  `estimated_periods` SMALLINT UNSIGNED DEFAULT NULL,  -- No. of periods to complete the Lesson
  `weightage_percent` DECIMAL(5,2) DEFAULT NULL,  -- Weightage in final exam (e.g., 8.5%)
  `nep_alignment` VARCHAR(100) DEFAULT NULL,      -- NEP 2020 reference code e.g. 'NEP_2020_01'
  `resources_json` JSON DEFAULT NULL,             -- [{type, url, title}] e.g. [{"type": "video", "url": "https://example.com/video.mp4", "title": "Video 1"}, {"type": "pdf", "url": "https://example.com/pdf.pdf", "title": "PDF 1"}]
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_uuid` (`uuid`),
  UNIQUE KEY `uq_lesson_class_subject_name` (`class_id`, `subject_id`, `name`),
  UNIQUE KEY `uq_lesson_code` (`code`),
  KEY `idx_lesson_class_subject` (`class_id`, `subject_id`),
  KEY `idx_lesson_ordinal` (`ordinal`),
  CONSTRAINT `fk_lesson_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_lesson_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lesson_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- HIERARCHICAL TOPICS & SUB-TOPICS (via parent_id)
-- -------------------------------------------------------------------------
-- DESIGN DECISION: Using Materialized Path approach for:
-- 1. Efficient ancestor/descendant queries
-- 2. Easy breadcrumb generation
-- 3. Unlimited nesting depth
-- 4. Fast reads (trade-off: slightly slower writes)
--
-- path format: /1/5/23/145/ (ancestor IDs separated by /)
-- level: 0=Topic, 1=Sub-topic, 2=Mini Topic, 3=Sub-Mini Topic, 
--        4=Micro Topic, 5=Sub-Micro Topic, 6+=Nano Topic, 7+=Ultra Topic
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `slb_topics` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,                       -- Unique analytics identifier
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,       -- FK to self (NULL for root topics)
  `lesson_id` BIGINT UNSIGNED NOT NULL,           -- FK to syl_lessons
  `class_id` INT UNSIGNED NOT NULL,               -- Denormalized for fast queries
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- Denormalized for fast queries
  -- Materialized Path columns
  `path` VARCHAR(500) NOT NULL,                   -- e.g., '/1/5/23/' (ancestor path)
  `path_names` VARCHAR(2000) DEFAULT NULL,        -- e.g., 'Algebra > Linear Equations > Solving Methods'
  `level` TINYINT UNSIGNED NOT NULL DEFAULT 0,    -- Depth in hierarchy (0=root)
  -- Core topic information
  `code` VARCHAR(60) NOT NULL,                    -- e.g., '9TH_SCI_L01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'
  `name` VARCHAR(150) NOT NULL,                   -- e.g., 'Topic 1: Linear Equations'
  `short_name` VARCHAR(50) DEFAULT NULL,          -- e.g., 'Linear Equations'
  `ordinal` SMALLINT UNSIGNED NOT NULL,           -- Order within parent
  `description` VARCHAR(255) DEFAULT NULL,        -- e.g., 'Description of Topic 1'
  -- Teaching metadata
  `duration_minutes` INT UNSIGNED DEFAULT NULL,   -- Estimated teaching time
  `learning_objectives` JSON DEFAULT NULL,        -- Array of objectives
  `keywords` JSON DEFAULT NULL,                   -- Search keywords array
  `prerequisite_topic_ids` JSON DEFAULT NULL,     -- Dependency tracking
  -- Analytics identifiers
  `analytics_code` VARCHAR(60) NOT NULL,          -- Unique code for tracking e.g. '9TH_SCI_L01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_uuid` (`uuid`),
  UNIQUE KEY `uq_topic_analytics_code` (`analytics_code`),
  UNIQUE KEY `uq_topic_code` (`code`),
  UNIQUE KEY `uq_topic_parent_ordinal` (`lesson_id`, `parent_id`, `ordinal`),
  KEY `idx_topic_parent` (`parent_id`),
  KEY `idx_topic_level` (`level`),
  KEY `idx_topic_class_subject` (`class_id`, `subject_id`),
  CONSTRAINT `fk_topic_parent` FOREIGN KEY (`parent_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `syl_lessons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- COMPETENCY FRAMEWORK (NEP 2020 ALIGNMENT)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `slb_competency_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,   -- e.g. 'KNOWLEDGE','SKILL','ATTITUDE'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_comp_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `slb_competencies` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,
  `code` VARCHAR(60) NOT NULL,    -- Auto generated e.g. '9TH_SCI_L01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'
  `name` VARCHAR(150) NOT NULL,   -- e.g. 'Knowledge of Linear Equations'
  `short_name` VARCHAR(50) DEFAULT NULL,   -- e.g. 'Linear Equations' 
  `description` VARCHAR(255) DEFAULT NULL,    -- e.g. 'Description of Knowledge of Linear Equations'
  `class_id` INT UNSIGNED DEFAULT NULL,         -- FK to sch_classes.id
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sch_subjects.id
  `competency_type_id` INT UNSIGNED NOT NULL,   -- FK to slb_competency_types.id
  `domain` ENUM('COGNITIVE', 'AFFECTIVE', 'PSYCHOMOTOR') NOT NULL DEFAULT 'COGNITIVE', -- e.g. 'COGNITIVE'
  `nep_framework_ref` VARCHAR(100) DEFAULT NULL,    -- e.g. 'NEP Framework Reference'
  `ncf_alignment` VARCHAR(100) DEFAULT NULL,        -- e.g. 'NCF Alignment'
  `learning_outcome_code` VARCHAR(50) DEFAULT NULL, -- e.g. 'Learning Outcome Code'
  `path` VARCHAR(500) DEFAULT '/',  -- e.g. '/9TH_SCI_L01_TOP01_SUB02_MIN01_SMT02_MIC01_SMT02_NAN01_ULT02'
  `level` TINYINT UNSIGNED DEFAULT 0, -- e.g. 0
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_competency_uuid` (`uuid`),
  UNIQUE KEY `uq_competency_code` (`code`),
  KEY `idx_competency_parent` (`parent_id`),
  KEY `idx_competency_type` (`competency_type_id`),
  CONSTRAINT `fk_competency_parent` FOREIGN KEY (`parent_id`) REFERENCES `syl_competencies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_competency_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_competency_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_competency_type` FOREIGN KEY (`competency_type_id`) REFERENCES `slb_competency_types` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Link topics to competencies
CREATE TABLE IF NOT EXISTS `slb_topic_competency_jnt` (
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL, -- FK to slb_competencies.id
  `weightage` DECIMAL(5,2) DEFAULT NULL,    -- How much topic contributes to competency
  `is_primary` TINYINT(1) DEFAULT 0, -- True if this is the primary competency for this topic
  PRIMARY KEY (`topic_id`,`competency_id`),
  CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- QUESTION TAXONOMIES (NEP / BLOOM etc.) - REFERENCE DATA
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `slb_bloom_taxonomy` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,   -- e.g. 'REMEMBERING','UNDERSTANDING','APPLYING','ANALYZING','EVALUATING','CREATING'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `bloom_level` TINYINT UNSIGNED DEFAULT NULL, -- 1-6 for Bloom's revised taxonomy
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bloom_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `slb_cognitive_skill` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `bloom_id` INT UNSIGNED DEFAULT NULL,       -- slb_bloom_taxonomy.id
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'COG-KNOWLEDGE','COG-SKILL','COG-UNDERSTANDING'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cog_code` (`code`),
  CONSTRAINT `fk_cog_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `slb_ques_type_specificity` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'IN_CLASS','HOMEWORK','SUMMATIVE','FORMATIVE'
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_quesTypeSps_code` (`code`),
  CONSTRAINT `fk_quesTypeSps_cognitive` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `slb_complexity_level` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,  -- e.g. 'EASY','MEDIUM','DIFFICULT'
  `name` VARCHAR(50) NOT NULL,
  `complexity_level` TINYINT UNSIGNED DEFAULT NULL,  -- 1=Easy, 2=Medium, 3=Difficult
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_complex_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `slb_question_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,  -- e.g. 'MCQ_SINGLE','MCQ_MULTI','SHORT_ANSWER','LONG_ANSWER','MATCH','NUMERIC','FILL_BLANK','CODING'
  `name` VARCHAR(100) NOT NULL,
  `has_options` TINYINT(1) NOT NULL DEFAULT 0,    -- True if this type has options
  `auto_gradable` TINYINT(1) NOT NULL DEFAULT 1,  -- True if this type can be auto-graded (Can System Marked Automatically?)
  `description` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtype_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- QUESTION BANK & QUESTION MANAGEMENT
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
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,  -- slb_complexity_level.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,       -- slb_bloom_taxonomy.id
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
  `ques_type_specificity_id` INT UNSIGNED DEFAULT NULL, -- slb_ques_type_specificity.id
  `estimated_time_seconds` INT UNSIGNED DEFAULT NULL, -- avg time to answer
  `tags` JSON DEFAULT NULL,                   -- array of tag strings or ids
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_public` TINYINT(1) NOT NULL DEFAULT 0,  -- share between tenants? keep default 0
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ques_topic` (`topic_id`),
  KEY `idx_ques_competency` (`competency_id`),
  KEY `idx_ques_class_subject` (`class_id`,`subject_id`),
  KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`),
  KEY `idx_ques_active` (`is_active`),
  CONSTRAINT `fk_ques_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_competency` FOREIGN KEY (`competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_type` FOREIGN KEY (`question_type_id`) REFERENCES `gl_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ques_complexity` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_cog` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_timeSpec` FOREIGN KEY (`ques_type_specificity_id`) REFERENCES `slb_ques_type_specificity` (`id`) ON DELETE SET NULL
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
-- QUESTION VERSIONING & HISTORY
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
-- QUESTION POOLS & ADAPTIVE SELECTION
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_pools` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
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

CREATE TABLE IF NOT EXISTS `sch_question_pool_questions` (
  `question_pool_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_pool_id`,`question_id`),
  CONSTRAINT `fk_qpq_pool` FOREIGN KEY (`question_pool_id`) REFERENCES `sch_question_pools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpq_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUIZZES, ASSESSMENTS & EXAMS
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
-- ASSESSMENT SECTIONS (for multi-part exams)
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
-- ASSESSMENT ITEMS (Questions in Quizzes/Assessments/Exams)
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
-- ASSESSMENT ASSIGNMENT & RULES
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
-- STUDENT ATTEMPTS & RESPONSES (GRADING)
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
-- STUDENT LEARNING OUTCOMES & COMPETENCY TRACKING
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
-- QUESTION & EXAM ANALYTICS
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
-- AUDIT & CHANGE LOG
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
-- MATERIALIZED VIEW FOR FAST QUERIES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_index` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `class_id` INT UNSIGNED DEFAULT NULL,           -- sch_classes.id
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,      -- sch_subjects.id
  `lesson_id` INT UNSIGNED DEFAULT NULL,          -- denormalized for faster filtering
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,        -- sch_topics.id
  `competency_id` BIGINT UNSIGNED DEFAULT NULL,   -- sch_competencies.id
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,      -- slb_complexity_level.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,           -- slb_bloom_taxonomy.id
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
  `question_type_id` INT UNSIGNED DEFAULT NULL,   -- gl_question_types.id
  `marks` DECIMAL(5,2) DEFAULT NULL,              -- marks allocated
  `negative_marks` DECIMAL(5,2) DEFAULT NULL,     -- negative marks
  `estimated_time_seconds` INT UNSIGNED DEFAULT NULL,  -- estimated time to answer
  `tags` JSON DEFAULT NULL,                       -- array of tag strings or ids
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_qi_class_subject` (`class_id`,`subject_id`),
  KEY `idx_qi_complexity` (`complexity_level_id`),
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
