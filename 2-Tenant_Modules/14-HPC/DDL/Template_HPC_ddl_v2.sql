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
  `code`        VARCHAR(50) NOT NULL,
  `version`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `title`       VARCHAR(255) NOT NULL,
  `description` VARCHAR(512) NULL,
  `applicable_to_grade` JSON NULL,     -- (BV1,BV2,BV3) or (Nur,LKG,UKG) and (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_templates_code_version` (`code`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- tab 2 --
CREATE TABLE IF NOT EXISTS `hpc_template_parts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `template_id` INT UNSIGNED NOT NULL,  -- FK to hpc_templates
  `code` VARCHAR(50) NOT NULL,
  `description` VARCHAR(512) NULL,
  `help_file` VARCHAR(255) NULL,  -- Can be a url of the how to fill for that page only
  `display_order` TINYINT UNSIGNED DEFAULT 1,
  `page_no` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- new
  `display_page_number` TINYINT(1) DEFAULT 1,
  `has_items` TINYINT(1) DEFAULT 1,  -- New
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_parts_template_code` (`template_id`,`code`),
  UNIQUE KEY `ux_parts_template_page` (`template_id`,`page_no`),
  KEY `idx_parts_pageNo` (`page_no`),
  CONSTRAINT `fk_templateParts_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_template_parts_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `part_id` INT UNSIGNED NOT NULL,        -- FK to hpc_template_parts
  `ordinal` TINYINT UNSIGNED DEFAULT 1,
  `html_object_name` VARCHAR(50) NOT NULL,  -- Name of the object in HTML.
  `level_display` VARCHAR(150) NOT NULL,  -- What will be the Level on the Screen
  `level_print` VARCHAR(150) NOT NULL,    -- What will be the Level on the Print
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_templatePartsItems_partId_ordinal` (`part_id`,`ordinal`),
  CONSTRAINT `fk_templatePartsItems_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- tab 3 --
CREATE TABLE IF NOT EXISTS `hpc_template_sections` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `template_id` INT UNSIGNED NOT NULL,      -- FK to hpc_templates
  `part_id` INT UNSIGNED NOT NULL,      -- FK to hpc_template_parts
  `code` VARCHAR(50) NOT NULL,
  `description` VARCHAR(512) NULL,
  `display_order` TINYINT UNSIGNED DEFAULT 1,
  `has_items` TINYINT(1) DEFAULT 1,  -- New
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_sections_part_code` (`part_id`,`code`),
  UNIQUE KEY `ux_sections_part_order` (`part_id`,`display_order`),
  KEY `idx_sections_order` (`display_order`),
  CONSTRAINT `fk_templateSections_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`),
  CONSTRAINT `fk_templateSections_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_template_section_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `section_id` INT UNSIGNED NOT NULL,     -- FK to hpc_template_sections
  `html_object_name` VARCHAR(50) NOT NULL,  -- Name of the object in HTML.
  `ordinal` TINYINT UNSIGNED DEFAULT 1,
  `level_display` VARCHAR(150) NOT NULL,
  `level_print` VARCHAR(150) NOT NULL,
  `section_type` ENUM('Text','Image','Table') DEFAULT 'Text',
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_templateSectionItems_sectionId_ordinal` (`section_id`,`ordinal`),
  CONSTRAINT `fk_templateSectionItems_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpc_template_section_table` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `section_id` INT UNSIGNED NOT NULL,
  `section_item_id` INT UNSIGNED NOT NULL,
  `html_object_name` VARCHAR(50) NOT NULL,  -- Name of the object in HTML.
  `row_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `column_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `value` VARCHAR(255) NOT NULL,
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_sectionTable_section_row_column` (`section_id`,`row_id`,`column_id`),
  CONSTRAINT `fk_sectionTable_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`),
  CONSTRAINT `fk_sectionTable_sectionItemId` FOREIGN KEY (`section_item_id`) REFERENCES `hpc_template_section_items`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- tab 4 --
CREATE TABLE IF NOT EXISTS `hpc_template_rubrics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `template_id` INT UNSIGNED NOT NULL,  -- FK to hpc_templates
  `part_id` INT UNSIGNED NOT NULL,  -- FK to hpc_template_parts
  `section_id` INT UNSIGNED NULL,  -- FK to hpc_template_sections
  `display_order` SMALLINT UNSIGNED DEFAULT 0,
  `code` VARCHAR(50) NULL,
  `description` VARCHAR(512) NULL,
  `input_required` TINYINT(1) DEFAULT 1,  -- new
  `input_type` ENUM('KeyValue','Descriptor','Numeric','Grade','Text','Boolean','Image','Json') DEFAULT 'Descriptor',  -- change
  `output_type` ENUM('KeyValue','Descriptor','Numeric','Grade','Text','Boolean','Image','Json') DEFAULT 'Descriptor',  -- New
  `has_items` TINYINT(1) DEFAULT 1,  -- New
  `mandatory` TINYINT(1) DEFAULT 0,
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_templateRubrics_section_order` (`section_id`,`display_order`),
  KEY `idx_rubrics_template` (`template_id`, `part_id`, `section_id`, `display_order`),
  CONSTRAINT `fk_templateRubrics_templateId` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates`(`id`),
  CONSTRAINT `fk_templateRubrics_partId` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts`(`id`),
  CONSTRAINT `fk_templateRubrics_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
-- If input_type = Descriptor OR input_type = Grade, then we need to have rubric_items
-- If input_type != output_type, then we need to have rubric_items


CREATE TABLE IF NOT EXISTS `hpc_template_rubric_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `rubric_id` INT UNSIGNED NOT NULL,
  `html_object_name` VARCHAR(50) NOT NULL,                     -- Name of the object in HTML.
  `input_level` VARCHAR(100) NOT NULL,                         -- Input level (e.g., Excellent, Good, Developing, Needs Support)
  `output_level` VARCHAR(100) NOT NULL,                        -- Output level (e.g., Excellent, Good, Developing, Needs Support)
  `input_level_numeric` INT UNSIGNED NULL,                     -- Numeric mapping (e.g., 4 = Excellent, 3 = Good, 2 = Developing, 1 = Needs Support)
  `output_level_numeric` INT UNSIGNED NULL,                    -- Numeric mapping (e.g., 4 = Excellent, 3 = Good, 2 = Developing, 1 = Needs Support)
  `display_input_label` TINYINT(1) NOT NULL DEFAULT 0,         -- Default we will display input_level but if this is 1 then we will display input_level_value
  `print_output_label` TINYINT(1) NOT NULL DEFAULT 0,          -- Default we will display input_level but if this is 1 then we will display input_level_value
  `weight` DECIMAL(8,3) NULL,                                  -- Useful to add weightage. For example, we may map Outstanding to weight 4.5
  `description` VARCHAR(255) NULL,
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
  `academic_session_id` INT UNSIGNED  NOT NULL,        -- Fk to sch_academic_sessions.id
  `term_id` INT UNSIGNED NOT NULL,      -- Fk to sch_academic_term.id
  `student_id` INT UNSIGNED NOT NULL,            -- Fk to students.id
  `template_id` INT UNSIGNED NOT NULL,           -- Fk to hpc_templates.id

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

CREATE TABLE IF NOT EXISTS `hpc_report_table` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `report_id` INT UNSIGNED NOT NULL,
  `section_id` INT UNSIGNED NOT NULL,
  `row_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `column_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `value` VARCHAR(255) NOT NULL,
  `visible` TINYINT(1) DEFAULT 1,
  `print` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `ux_reportTable_report_section_row_column` (`report_id`,`section_id`,`row_id`,`column_id`),
  CONSTRAINT `fk_reportTable_reportId` FOREIGN KEY (`report_id`) REFERENCES `hpc_reports`(`id`),
  CONSTRAINT `fk_reportTable_sectionId` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;


