-- =====================================================================
-- SYLLABUS & EXAM MANAGEMENT MODULE - ENHANCED VERSION 2.0
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
-- SECTION 1: ACADEMIC STRUCTURE - LESSONS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `syl_lessons` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,           -- Multi-tenant isolation
  `uuid` CHAR(36) NOT NULL,                       -- Unique identifier for analytics tracking
  `academic_session_id` BIGINT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt
  `class_id` INT UNSIGNED NOT NULL,               -- FK to sch_classes
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- FK to sch_subjects
  `code` VARCHAR(20) NOT NULL,                    -- e.g., '9TH_SCI_L01' (Auto-generated)
  `name` VARCHAR(150) NOT NULL,                   -- e.g., 'Chapter 1: Matter in Our Surroundings'
  `short_name` VARCHAR(50) DEFAULT NULL,          -- e.g., 'Matter Around Us'
  `ordinal` SMALLINT UNSIGNED NOT NULL,           -- Sequence order within subject
  `description` TEXT DEFAULT NULL,
  `learning_objectives` JSON DEFAULT NULL,        -- Array of learning objectives
  `prerequisites` JSON DEFAULT NULL,              -- Array of prerequisite lesson IDs
  `estimated_periods` SMALLINT UNSIGNED DEFAULT NULL,  -- No. of periods to complete
  `weightage_percent` DECIMAL(5,2) DEFAULT NULL,  -- Weightage in final exam (e.g., 8.5%)
  `nep_alignment` VARCHAR(100) DEFAULT NULL,      -- NEP 2020 reference code
  `resources_json` JSON DEFAULT NULL,             -- [{type, url, title}]
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `updated_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_uuid` (`uuid`),
  UNIQUE KEY `uq_lesson_tenant_class_subject_name` (`tenant_id`, `academic_session_id`, `class_id`, `subject_id`, `name`),
  UNIQUE KEY `uq_lesson_code` (`tenant_id`, `code`),
  KEY `idx_lesson_tenant` (`tenant_id`),
  KEY `idx_lesson_class_subject` (`class_id`, `subject_id`),
  KEY `idx_lesson_ordinal` (`ordinal`),
  CONSTRAINT `fk_lesson_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_lesson_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lesson_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 2: HIERARCHICAL TOPICS WITH MATERIALIZED PATH
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
--        4=Micro Topic, 5=Sub-Micro Topic, 6+=Ultra levels
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `syl_topics` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `uuid` CHAR(36) NOT NULL,                       -- Unique analytics identifier
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,       -- FK to self (NULL for root topics)
  `lesson_id` BIGINT UNSIGNED NOT NULL,           -- FK to syl_lessons
  `class_id` INT UNSIGNED NOT NULL,               -- Denormalized for fast queries
  `subject_id` BIGINT UNSIGNED NOT NULL,          -- Denormalized for fast queries
  
  -- Materialized Path columns
  `path` VARCHAR(500) NOT NULL,                   -- e.g., '/1/5/23/' (ancestor path)
  `path_names` VARCHAR(2000) DEFAULT NULL,        -- e.g., 'Algebra > Linear Equations > Solving Methods'
  `level` TINYINT UNSIGNED NOT NULL DEFAULT 0,    -- Depth in hierarchy (0=root)
  `level_name` VARCHAR(50) NOT NULL,              -- 'Topic', 'Sub-topic', 'Mini Topic', etc.
  
  -- Core topic information
  `code` VARCHAR(30) NOT NULL,                    -- e.g., '9TH_SCI_L01_T01_ST02'
  `name` VARCHAR(200) NOT NULL,
  `short_name` VARCHAR(50) DEFAULT NULL,
  `ordinal` SMALLINT UNSIGNED NOT NULL,           -- Order within parent
  `description` TEXT DEFAULT NULL,
  
  -- Teaching metadata
  `duration_minutes` INT UNSIGNED DEFAULT NULL,   -- Estimated teaching time
  `learning_objectives` JSON DEFAULT NULL,        -- Array of objectives
  `keywords` JSON DEFAULT NULL,                   -- Search keywords array
  `prerequisite_topic_ids` JSON DEFAULT NULL,     -- Dependency tracking
  
  -- Analytics identifiers
  `analytics_code` VARCHAR(50) NOT NULL,          -- Unique code for tracking
  
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `updated_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_uuid` (`uuid`),
  UNIQUE KEY `uq_topic_analytics_code` (`tenant_id`, `analytics_code`),
  UNIQUE KEY `uq_topic_code` (`tenant_id`, `code`),
  UNIQUE KEY `uq_topic_parent_ordinal` (`tenant_id`, `lesson_id`, `parent_id`, `ordinal`),
  KEY `idx_topic_tenant` (`tenant_id`),
  KEY `idx_topic_parent` (`parent_id`),
  KEY `idx_topic_lesson` (`lesson_id`),
  KEY `idx_topic_path` (`path`(255)),
  KEY `idx_topic_level` (`level`),
  KEY `idx_topic_class_subject` (`class_id`, `subject_id`),
  CONSTRAINT `fk_topic_parent` FOREIGN KEY (`parent_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `syl_lessons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 3: TOPIC LEVEL DEFINITIONS (Reference Table)
-- -------------------------------------------------------------------------
-- Multi-tenant isolation to define topic levels for each tenant. Main use of the table is to define topic levels for each tenant.
CREATE TABLE IF NOT EXISTS `syl_topic_levels` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `level` TINYINT UNSIGNED NOT NULL,
  `code` VARCHAR(20) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `color_code` VARCHAR(7) DEFAULT NULL,
  `icon` VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_level` (`level`),
  UNIQUE KEY `uq_topic_level_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed data for topic levels
INSERT INTO `syl_topic_levels` (`level`, `code`, `name`, `description`, `color_code`) VALUES
(0, 'TOPIC', 'Topic', 'Main topic under a lesson', '#1E40AF'),
(1, 'SUB_TOPIC', 'Sub-topic', 'First level subdivision', '#3B82F6'),
(2, 'MINI_TOPIC', 'Mini Topic', 'Second level subdivision', '#60A5FA'),
(3, 'SUB_MINI_TOPIC', 'Sub-Mini Topic', 'Third level subdivision', '#93C5FD'),
(4, 'MICRO_TOPIC', 'Micro Topic', 'Fourth level subdivision', '#BFDBFE'),
(5, 'SUB_MICRO_TOPIC', 'Sub-Micro Topic', 'Fifth level subdivision', '#DBEAFE'),
(6, 'NANO_TOPIC', 'Nano Topic', 'Sixth level subdivision', '#EFF6FF'),
(7, 'ULTRA_TOPIC', 'Ultra Topic', 'Seventh+ level subdivision', '#F8FAFC');


-- -------------------------------------------------------------------------
-- SECTION 4: COMPETENCY FRAMEWORK (NEP 2020 Alignment)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `syl_competencies` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `uuid` CHAR(36) NOT NULL,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `competency_type` ENUM('KNOWLEDGE', 'SKILL', 'ATTITUDE', 'VALUE', 'DISPOSITION') NOT NULL,
  `domain` ENUM('COGNITIVE', 'AFFECTIVE', 'PSYCHOMOTOR') NOT NULL DEFAULT 'COGNITIVE',
  `nep_framework_ref` VARCHAR(100) DEFAULT NULL,
  `ncf_alignment` VARCHAR(100) DEFAULT NULL,
  `learning_outcome_code` VARCHAR(50) DEFAULT NULL,
  `path` VARCHAR(500) DEFAULT '/',
  `level` TINYINT UNSIGNED DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_competency_uuid` (`uuid`),
  UNIQUE KEY `uq_competency_code` (`tenant_id`, `code`),
  KEY `idx_competency_tenant` (`tenant_id`),
  KEY `idx_competency_parent` (`parent_id`),
  KEY `idx_competency_type` (`competency_type`),
  CONSTRAINT `fk_competency_parent` FOREIGN KEY (`parent_id`) REFERENCES `syl_competencies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_competency_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_competency_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 5: TOPIC-COMPETENCY JUNCTION
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `syl_topic_competency_jnt` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  `weightage` DECIMAL(5,2) DEFAULT NULL,
  `is_primary` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_competency` (`tenant_id`, `topic_id`, `competency_id`),
  CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `syl_competencies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- SECTION 6: TOPIC PREREQUISITES & DEPENDENCIES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `syl_topic_prerequisites` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `prerequisite_topic_id` BIGINT UNSIGNED NOT NULL,
  `prerequisite_class_id` INT UNSIGNED DEFAULT NULL,
  `strength` ENUM('MANDATORY', 'RECOMMENDED', 'OPTIONAL') NOT NULL DEFAULT 'RECOMMENDED',
  `description` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_prereq` (`tenant_id`, `topic_id`, `prerequisite_topic_id`),
  CONSTRAINT `fk_prereq_topic` FOREIGN KEY (`topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_prereq_prereq_topic` FOREIGN KEY (`prerequisite_topic_id`) REFERENCES `syl_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- END OF FILE 1: CORE HIERARCHY STRUCTURE
-- =====================================================================
