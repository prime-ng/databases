-- -----------------------------------------------
-- HPC_Tables.sql  (Old Application)
-- -----------------------------------------------
-- File: migrations/20250929_create_hpc_tables.sql
-- Purpose: Create tables to support Holistic Report Card templates and reports (Prep, Foundation, Middle, Secondary)
-- Engine: InnoDB / MySQL 8
-- -----------------------------------------------

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `hpc_templates` (
  `id`          INT AUTO_INCREMENT PRIMARY KEY,
  `org_id`      INT UNSIGNED NULL,
  `code`        VARCHAR(50) NOT NULL,
  `version`     INT UNSIGNED NOT NULL DEFAULT 1,
  `title`       VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `applicable_to_grade` JSON NULL,     -- (BV1,BV2,BV3) or (Nur,LKG,UKG) and (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_templates_code_version` (`code`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_template_parts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `template_id` INT UNSIGNED NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `title` VARCHAR(255) NULL,
  `sub_title` VARCHAR(255) NULL,   -- new
  `description` TEXT NULL,
  `help_file` VARCHAR(255) NULL,  -- Can be a url of the how to fill for that page only
  `display_order` INT DEFAULT 0,
  `page_no` INT UNSIGNED NOT NULL DEFAULT 1, -- new
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT `fk_templateParts_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
  UNIQUE KEY `ux_parts_template_code` (`template_id`,`code`),
  UNIQUE KEY `ux_parts_template_page` (`template_id`,`page_no`),
  KEY `idx_parts_pageNo` (`page_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_template_sections` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `template_id` INT UNSIGNED NOT NULL,
  `part_id` INT UNSIGNED NOT NULL,
  `code` VARCHAR(50) NOT NULL,  -- new
  `title` VARCHAR(255) NULL,
  `sub_title` VARCHAR(255) NULL,  -- new
  `description` TEXT NULL,
  `display_order` TINYINT UNSIGNED DEFAULT 1,
  `section_type` ENUM('KeyValue','Table','Text','Image') DEFAULT 'KeyValue',
  `need_input` TINYINT(1) DEFAULT 1,
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT `fk_templateSections_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`),
  UNIQUE KEY `ux_sections_part_code` (`part_id`,`code`),
  UNIQUE KEY `ux_sections_part_order` (`part_id`,`display_order`),
  KEY `idx_sections_order` (`display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_template_rubrics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `template_id` INT UNSIGNED NOT NULL,
  `part_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED NULL,
  `code` VARCHAR(50) NULL,     -- change
  `title` VARCHAR(255) NOT NULL,
  `sub_title` VARCHAR(255) NULL,  -- new
  `description` TEXT NULL,
  `input_required` TINYINT(1) DEFAULT 1,  -- new
  `input_type` ENUM('descriptor','numeric','grade','text','boolean','image','json') DEFAULT 'descriptor',  -- change
  `output_type` ENUM('descriptor','numeric','grade','text','boolean','image','json') DEFAULT 'descriptor',  -- New
--  input_output_same TINYINT(1) NOT NULL DEFAULT 1,
  `mandatory` TINYINT(1) DEFAULT 0,
  `display_order` INT UNSIGNED DEFAULT 0,
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `default_scale` JSON NULL,    -- Stores the descriptor or grade labels for dropdown Example JSON - ["Excellent", "Proficient", "Developing", "Needs Support"]
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT `fk_templateRubrics_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
  CONSTRAINT `fk_templateRubrics_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`),
  CONSTRAINT `fk_templateRubrics_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`),
  UNIQUE KEY `ux_templateRubrics_section_order` (`section_id`,`display_order`),
  KEY `idx_rubrics_template` (`template_id`),
  KEY `idx_rubrics_part` (`part_id`),
  KEY `idx_rubrics_section` (`section_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `hpc_rubric_levels` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `rubric_id` INT UNSIGNED NOT NULL,
  `input_type` ENUM('descriptor','grade') DEFAULT 'descriptor',
  `level_value` INT UNSIGNED NOT NULL,     -- Numeric mapping (e.g., 4 = Excellent, 3 = Good, 2 = Developing, 1 = Needs Support)
  `label` VARCHAR(100) NOT NULL,  -- Text label (e.g., Excellent, Consistently, A,B)
  `weight` DECIMAL(8,3) NULL,     -- Useful when need to add weightage which need fractional value. For example, we may map Outstanding to weight 4.5
  `description` TEXT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT `fk_rubricLevels_rubricId` FOREIGN KEY (`rubric_id`) REFERENCES `hpc_template_rubrics`(`id`),
  UNIQUE KEY `ux_levels_rubric_value` (`rubric_id`,`level_value`),
  KEY `idx_levels_rubric` (`rubric_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ================================================================================================


CREATE TABLE IF NOT EXISTS `hpc_reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,  -- Auto Generate
  `student_id` INT UNSIGNED NOT NULL,            -- Fk to students.id
  `template_id` INT UNSIGNED NOT NULL,           -- Fk to hpc_templates.id
  `session_id` INT UNSIGNED  NOT NULL,        -- Fk to sessions.id
  `term_id` INT UNSIGNED NOT NULL,
  `prepared_by` INT UNSIGNED NULL,    -- Fk to staff.id
  `report_date` DATE NOT NULL,          -- Report Generation Date
  `status` ENUM('draft','final','archived') DEFAULT 'draft',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT `fk_reports_student` FOREIGN KEY (`student_id`) REFERENCES `students`(`id`),
  CONSTRAINT `fk_reports_template` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
  CONSTRAINT `fk_reports_session` FOREIGN KEY (`session_id`) REFERENCES `sch_setting`(`id`),
  CONSTRAINT `fk_reports_term` FOREIGN KEY (`term_id`) REFERENCES `cbse_terms`(`id`),
  UNIQUE KEY `ux_reports_student_session_term` (`student_id`,`session_id`,`term_id`),
  KEY `idx_reports_template` (`template_id`),
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_report_items` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `report_id` INT UNSIGNED NOT NULL,
  `rubric_id` INT UNSIGNED NOT NULL,
  `rubric_level_id` INT UNSIGNED NULL,
  `in_numeric_value` DECIMAL(10,3) NULL,  -- to capture numeric type value
  `in_text_value` VARCHAR(255) NULL,              -- to capture text type
  `in_boolean_value` TINYINT(1) NULL,     -- to capture boolean type
  `in_label` VARCHAR(100) NULL,     -- to capture categorical Value (descriptor & grade)
  `in_image_path` VARCHAR(255) NULL,
  `in_table` JSON NULL,
  `in_remark` TEXT NULL,
  `out_numeric_value` DECIMAL(10,3) NULL,  -- to capture numeric type value
  `out_text_value` VARCHAR(255) NULL,              -- to capture text type
  `out_boolean_value` TINYINT(1) NULL,     -- to capture boolean type
  `out_label` VARCHAR(100) NULL,     -- to capture categorical Value (descriptor & grade)
  `out_image_path` VARCHAR(255) NULL,
  `filename` VARCHAR(100) NULL,
  `filepath` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT `fk_reportItems_reportId` FOREIGN KEY (`report_id`) REFERENCES `hpc_reports`(`id`),
  CONSTRAINT `fk_reportItems_rubricId` FOREIGN KEY (`rubric_id`) REFERENCES `hpc_template_rubrics`(`id`),
  CONSTRAINT `fk_reportItems_rubricLevelId` FOREIGN KEY (`rubric_level_id`) REFERENCES `hpc_rubric_levels`(`id`),
  KEY `idx_items_reportRubricLevel` (`report_id`,`rubric_id`,`rubric_level_id`),
  KEY `idx_items_rubric` (`rubric_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


SET FOREIGN_KEY_CHECKS = 1;


