-- -----------------------------------------------
-- HPC_Shailesh.sql  (Old Application)
-- -----------------------------------------------
-- File: migrations/20250929_create_hpc_tables.sql
-- Purpose: Create tables to support Holistic Report Card templates and reports (Prep, Foundation, Middle, Secondary)
-- Engine: InnoDB / MySQL 8
-- -----------------------------------------------

  CREATE TABLE IF NOT EXISTS `hpc_template_rubrics` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `template_id` bigint unsigned NOT NULL,
  `part_id` bigint unsigned NOT NULL,
  `section_id` bigint unsigned DEFAULT NULL,
  `display_order` smallint unsigned NOT NULL DEFAULT '0',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `input_required` tinyint(1) NOT NULL DEFAULT '1',
  `input_type` enum('KeyValue','Descriptor','Numeric','Grade','Text','Boolean','Image','Json') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Descriptor',
  `output_type` enum('KeyValue','Descriptor','Numeric','Grade','Text','Boolean','Image','Json') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Descriptor',
  `has_items` tinyint(1) NOT NULL DEFAULT '1',
  `mandatory` tinyint(1) NOT NULL DEFAULT '0',
  `visible` tinyint(1) NOT NULL DEFAULT '1',
  `print` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_templateRubrics_section_order` (`section_id`,`display_order`),
  KEY `idx_rubrics_template` (`template_id`),
  KEY `idx_rubrics_part` (`part_id`),
  KEY `idx_rubrics_section` (`section_id`),
  CONSTRAINT `hpc_template_rubrics_part_id_foreign` FOREIGN KEY (`part_id`) REFERENCES `hpc_template_parts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hpc_template_rubrics_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `hpc_template_sections` (`id`) ON DELETE SET NULL,
  CONSTRAINT `hpc_template_rubrics_template_id_foreign` FOREIGN KEY (`template_id`) REFERENCES `hpc_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1010 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 CREATE TABLE `hpc_template_rubric_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rubric_id` bigint unsigned NOT NULL,
  `html_object_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1',
  `input_required` tinyint(1) NOT NULL DEFAULT '1',
  `input_type` enum('Descriptor','Numeric','Grade','Text','Boolean','Image','Json') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Descriptor',
  `output_type` enum('Descriptor','Numeric','Grade','Text','Boolean','Image','Json') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Descriptor',
  `input_dropdown` json DEFAULT NULL,
  `output_dropdown` json DEFAULT NULL,
  `input_level` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `output_level` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `input_level_numeric` int unsigned DEFAULT NULL,
  `output_level_numeric` int unsigned DEFAULT NULL,
  `display_input_label` tinyint(1) NOT NULL DEFAULT '0',
  `print_output_label` tinyint(1) NOT NULL DEFAULT '0',
  `weight` decimal(8,3) DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_levels_rubric_value` (`rubric_id`,`input_level`),
  KEY `idx_levels_rubric` (`rubric_id`),
  CONSTRAINT `hpc_template_rubric_items_rubric_id_foreign` FOREIGN KEY (`rubric_id`) REFERENCES `hpc_template_rubrics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2532 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;