-- ========================================================================================================
-- RECOMMENDATION MODULE (rec) - v1.2
-- ========================================================================================================
-- Purpose: 
--   1. Capture content/materials for recommendations (Text, Video, PDF, etc.)
--   2. Define Rules for Auto-Recommendations based on Student Performance (e.g. Poor in Math -> suggest Remedial Video)
--   3. Track Student Assignments and Consumption of Recommendations
--   4. Analytics & Feedback loop
-- 
-- Dependencies:
--   - sys_users (Students)
--   - sch_classes, sch_subjects
--   - slb_topics (Syllabus)
--   - slb_performance_categories (Performance Levels)
--   - qns_media_store (External Module - assumed existing, or use sys_media)
-- ========================================================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ========================================================================================================
-- SECTION 1: RECOMMENDATION TABLES
-- ========================================================================================================

-- ========================================================================================================
-- SCREEN - (Recommendation Masters)
-- ========================================================================================================

-- TAB-1 : Recommendation Materials

-- table for "trigger_event" ENUM values
CREATE TABLE IF NOT EXISTS `rec_trigger_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_name` VARCHAR(50) NOT NULL,  -- ON_ASSESSMENT_RESULT, ON_TOPIC_COMPLETION, ON_ATTENDANCE_LOW, MANUAL_RUN, SCHEDULED_WEEKLY
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recTriggerEvent_name` (`event_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

-- TAB-2 : Recommendation Rules

-- table for "recommendation_mode" ENUM values
CREATE TABLE IF NOT EXISTS `rec_recommendation_modes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `mode_name` VARCHAR(50) NOT NULL,  -- SPECIFIC_MATERIAL, SPECIFIC_BUNDLE, DYNAMIC_BY_TOPIC, DYNAMIC_BY_COMPETENCY
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recRecommendationMode_name` (`mode_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

-- TAB-3 : Recommendation Rules

-- table for "dynamic_material_type" ENUM values
CREATE TABLE IF NOT EXISTS `rec_dynamic_material_types` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_name` VARCHAR(50) NOT NULL,  -- ANY_BEST_FIT, VIDEO, QUIZ, PDF
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recDynamicMaterialType_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

-- TAB-4 : Recommendation Rules

-- table for "dynamic_purpose" ENUM values
CREATE TABLE IF NOT EXISTS `rec_dynamic_purposes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `purpose_name` VARCHAR(50) NOT NULL,  -- REMEDIAL, ENRICHMENT, PRACTICE
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recDynamicPurpose_name` (`purpose_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

-- TAB-5 : Recommendation Rules

-- table for "assessment_type" ENUM values
CREATE TABLE IF NOT EXISTS `rec_assessment_types` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_name` VARCHAR(50) NOT NULL,  -- ALL, QUIZ, WEEKLY_TEST, TERM_EXAM, FINAL_EXAM
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recAssessmentType_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 


-- ========================================================================================================
-- SCREEN - 2 : Tab-1 (Recommendation Materials)
-- ========================================================================================================

-- 1. Master table for Recommendation Materials (Content Bank)
CREATE TABLE IF NOT EXISTS `rec_recommendation_materials` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  -- Content Classification
  `material_type` BIGINT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'TEXT','VIDEO','PDF','AUDIO','QUIZ','ASSIGNMENT','LINK','INTERACTIVE')
  `purpose` BIGINT UNSIGNED DEFAULT NULL,          -- fk to sys_dropdown_table (e.g. 'REVISION','PRACTICE','REMEDIAL','ADVANCED','ENRICHMENT','CONCEPT_BUILDING') NOT NULL DEFAULT 'PRACTICE',
  `complexity_level` BIGINT UNSIGNED DEFAULT NULL,  -- fk to slb_complexity_level
  -- Content Source
  `content_source` BIGINT UNSIGNED DEFAULT NULL,    -- fk to sys_dropdown_table (e.g. 'INTERNAL_EDITOR','UPLOADED_FILE','EXTERNAL_LINK','LMS_MODULE','QUESTION_BANK')
  `content_text` LONGTEXT DEFAULT NULL,           -- HTML content for 'TEXT' type or Internal Notes
  `file_url` VARCHAR(500) DEFAULT NULL,           -- Direct URL for 'UPLOADED_FILE' or 'PDF' or 'VIDEO'
  `external_url` VARCHAR(500) DEFAULT NULL,       -- YouTube link, Khan Academy link etc.
  `media_id` BIGINT UNSIGNED DEFAULT NULL,        -- fk to qns_media_store (for stored Media)
  -- Academic Mapping
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sch_subjects
  `class_id` INT UNSIGNED DEFAULT NULL,           -- FK to sch_classes (Target Class)
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,        -- FK to slb_topics
  `competency_code` VARCHAR(50) DEFAULT NULL,     -- Optional link to Competency Framework
  -- Metadata
  `duration_seconds` INT UNSIGNED DEFAULT NULL,   -- Est. time to consume
  `language_code` VARCHAR(10) DEFAULT 'en',       -- e.g. 'en', 'hi'
  `tags` JSON DEFAULT NULL,                       -- Search tags
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_recMat_school` (`school_id`),
  KEY `idx_recMat_type` (`material_type`),
  KEY `idx_recMat_scope` (`class_id`, `subject_id`, `topic_id`),
  CONSTRAINT `fk_recMat_school` FOREIGN KEY (`school_id`) REFERENCES `sch_organizations` (`id`),
  CONSTRAINT `fk_recMat_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_recMat_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
  CONSTRAINT `fk_recMat_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`),
  CONSTRAINT `fk_recMat_content_source` FOREIGN KEY (`content_source`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_recMat_material_type` FOREIGN KEY (`material_type`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_recMat_purpose` FOREIGN KEY (`purpose`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_recMat_complexity_level` FOREIGN KEY (`complexity_level`) REFERENCES `slb_complexity_level` (`id`),
  CONSTRAINT `fk_recMat_media` FOREIGN KEY (`media_id`) REFERENCES `qns_media_store` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================================================================================
-- SCREEN - 2  : Tab-2 (Recommendation Bundles)
-- ========================================================================================================

-- 1. Recommendation Bundles/Collections (e.g. "Week 1 Revision Kit")
--    Allows grouping multiple materials into one recommendation
CREATE TABLE IF NOT EXISTS `rec_material_bundles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_recBundle_school` (`school_id`),
  CONSTRAINT `fk_recBundle_school` FOREIGN KEY (`school_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Junction between Bundle and Materials
CREATE TABLE IF NOT EXISTS `rec_bundle_materials_jnt` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `bundle_id` BIGINT UNSIGNED NOT NULL,
  `material_id` BIGINT UNSIGNED NOT NULL,
  `sequence_order` INT UNSIGNED DEFAULT 1,
  `is_mandatory` TINYINT(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recBundleMat_rel` (`bundle_id`, `material_id`),
  CONSTRAINT `fk_recBundleMat_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `rec_material_bundles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recBundleMat_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================================================================================
-- SCREEN - 2  : Tab-3 (Recommendation Rules)
-- ========================================================================================================

-- 1. Recommendation Rules Engine
--    Defines logics: WHEN (Trigger) + WHO (Performance) -> WHAT (Recommendation)
CREATE TABLE IF NOT EXISTS `rec_recommendation_rules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Rule Definition
  `name` VARCHAR(150) NOT NULL,                   -- e.g. "Math Remedial for Poor Performers in Algebra"
  `is_automated` TINYINT(1) DEFAULT 1,            -- 1=Run by System Job, 0=Manual Helper Rule
  -- TRIGGERS (When to Apply)
  `trigger_event` BIGINT UNSIGNED NOT NULL,  -- FK to rec_trigger_events
  -- CONDITIONS (The "Switch")
  -- Narrowing Scope
  `class_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_classes
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_subjects
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to slb_topics
  -- Performance Criteria
  `performance_category_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to slb_performance_categories (The bucket, e.g. POOR)
  `min_score_pct` DECIMAL(5,2) DEFAULT NULL,      -- Specific override e.g. < 40%
  `max_score_pct` DECIMAL(5,2) DEFAULT NULL,      -- Specific override e.g. > 90%
  -- Assessment Type Filter (Only apply if the result came from this type of exam)
  `assessment_type` BIGINT UNSIGNED DEFAULT NULL,  -- FK to rec_assessment_types
  -- ACTION (What to Recommend)
  `recommendation_mode_id` BIGINT UNSIGNED NOT NULL,  -- FK to rec_recommendation_modes
  `target_material_id` BIGINT UNSIGNED DEFAULT NULL,  -- KF TO rec_recommendation_materials
  `target_bundle_id` BIGINT UNSIGNED DEFAULT NULL,    -- KF TO rec_recommendation_bundles
  `dynamic_material_type_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_material_types
  `dynamic_purpose_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to rec_dynamic_purposes
  `priority` INT UNSIGNED DEFAULT 10,                 -- Higher priority rules override or appear first
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_recRule_trigger` (`trigger_event`),
  CONSTRAINT `fk_recRule_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_perfCat` FOREIGN KEY (`performance_category_id`) REFERENCES `slb_performance_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_targetMat` FOREIGN KEY (`target_material_id`) REFERENCES `rec_recommendation_materials` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_targetBun` FOREIGN KEY (`target_bundle_id`) REFERENCES `rec_material_bundles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_trigger` FOREIGN KEY (`trigger_event_id`) REFERENCES `rec_trigger_events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recRule_recMode` FOREIGN KEY (`recommendation_mode_id`) REFERENCES `rec_recommendation_modes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recRule_dynMatType` FOREIGN KEY (`dynamic_material_type_id`) REFERENCES `rec_dynamic_material_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_dynPurpose` FOREIGN KEY (`dynamic_purpose_id`) REFERENCES `rec_dynamic_purposes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recRule_assessmentType` FOREIGN KEY (`assessment_type_id`) REFERENCES `rec_assessment_types` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================================================================================
-- SCREEN - 2  : Tab-4 (Student Recommendations)
-- ========================================================================================================

-- 1. Student Recommendations (The Resulting Assignments)
--    Refined from v1.1 `rec_student_recommendations`
CREATE TABLE IF NOT EXISTS `rec_student_recommendations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,                       -- Unique ID for public access/tracking
  `student_id` BIGINT UNSIGNED NOT NULL,          -- FK to std_students (or users depending on arch. std_students preferred)
  -- Source of Recommendation
  `rule_id` BIGINT UNSIGNED DEFAULT NULL,         -- fk to rec_recommendation_rules. Which rule generated this?
  `triggered_by_result_id` BIGINT UNSIGNED DEFAULT NULL, -- Optional: Link to the Exam Result ID in Exam Module
  `manual_assigned_by` BIGINT UNSIGNED DEFAULT NULL,     -- If manually assigned by Teacher
  -- The Content
  `material_id` BIGINT UNSIGNED DEFAULT NULL,
  `bundle_id` BIGINT UNSIGNED DEFAULT NULL,
  -- Context
  `recommendation_reason` VARCHAR(255) DEFAULT NULL, -- e.g. "Scored Low in Algebra Quiz"
  `priority` ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'MEDIUM',
  `due_date` DATE DEFAULT NULL,
  -- Status Tracking
  `status` ENUM('PENDING','VIEWED','IN_PROGRESS','COMPLETED','SKIPPED','EXPIRED') DEFAULT 'PENDING',
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `first_viewed_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  -- Outcomes
  `score_achieved` DECIMAL(5,2) DEFAULT NULL,     -- If the recommendation was a Quiz/Practice
  `student_rating` TINYINT UNSIGNED DEFAULT NULL, -- 1-5 Stars
  `student_feedback` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recStudRec_uuid` (`uuid`),
  KEY `idx_recStud_student` (`student_id`, `status`),
  CONSTRAINT `fk_recStud_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recStud_rule` FOREIGN KEY (`rule_id`) REFERENCES `rec_recommendation_rules` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recStud_material` FOREIGN KEY (`material_id`) REFERENCES `rec_recommendation_materials` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recStud_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `rec_material_bundles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recStud_teacher` FOREIGN KEY (`manual_assigned_by`) REFERENCES `sch_teachers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- ========================================================================================================
-- SECTION 2: ENHANCEMENTS IN EXISTING TABLES (SEED DATA ETC)
-- ========================================================================================================

-- Insert Dropdown Configurations into sys_dropdown_needs
-- Checking first if tables exist to prevent errors in partial execution environments, 
-- but strictly this is a DDL file. We use INSERT IGNORE.

INSERT IGNORE INTO `sys_dropdown_needs` 
(`db_type`, `table_name`, `column_name`, `menu_category`, `main_menu`, `sub_menu`, `field_name`, `is_system`, `compulsory`) 
VALUES 
('Tenant', 'rec_recommendation_materials', 'material_type', 'LMS', 'Recommendations', 'Material Library', 'Material Type', 1, 1),
('Tenant', 'rec_recommendation_materials', 'purpose', 'LMS', 'Recommendations', 'Material Library', 'Purpose', 1, 1),
('Tenant', 'rec_recommendation_materials', 'complexity_level', 'LMS', 'Recommendations', 'Material Library', 'Complexity', 1, 1),
('Tenant', 'rec_recommendation_rules', 'trigger_event', 'LMS', 'Recommendations', 'Rules Engine', 'Trigger Event', 1, 1);

-- Default Seed for Material Types (if we were using a lookup table, but we used ENUM. 
-- However, if sys_dropdown_table is used for UI drivers, we populate it)
-- Note: schema uses ENUMs for strictness, but UI might need dynamic lists. 
-- For this "Production Ready" DDL, we stick to ENUMs in tables but definitions in dropdowns helpful.

-- ========================================================================================================
-- END OF FILE
-- ========================================================================================================
