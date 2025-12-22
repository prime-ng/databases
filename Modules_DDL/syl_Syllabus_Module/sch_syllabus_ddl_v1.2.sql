-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 1.2
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
-- SECTION 1: CORE SYLLABUS STRUCTURE
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
-- SECTION 2: HIERARCHICAL TOPICS & SUB-TOPICS (via parent_id)
-- -------------------------------------------------------------------------
-- 
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
-- SECTION 3: COMPETENCY FRAMEWORK (NEP 2020 ALIGNMENT)
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
-- SECTION 4: QUESTION TAXONOMIES (NEP / BLOOM etc.) - REFERENCE DATA
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


