-- Global DB
-- ---------

CREATE TABLE IF NOT EXISTS `glb_countries` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `short_name` varchar(10) NOT NULL,
  `global_code` varchar(10) DEFAULT NULL,
  `currency_code` varchar(8) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_country_name` (`name`),
  UNIQUE KEY `uq_countries_shortName` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_states` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `country_id` INT unsigned NOT NULL,    -- fk
  `name` varchar(50) NOT NULL,
  `short_name` varchar(10) NOT NULL,
  `global_code` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_state_countryId_name` (`country_id`,`name`),
  CONSTRAINT `fk_state_countryId` FOREIGN KEY (`country_id`) REFERENCES `glb_countries` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_districts` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `state_id` INT unsigned NOT NULL,    -- fk
  `name` varchar(50) NOT NULL,
  `short_name` varchar(10) NOT NULL,
  `global_code` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_district_stateId_name` (`state_id`,`name`),
  CONSTRAINT `fk_districts_stateId` FOREIGN KEY (`state_id`) REFERENCES `glb_states` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=290 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_cities` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `district_id` INT unsigned NOT NULL,    -- fk
  `name` varchar(100) NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `global_code` varchar(20) DEFAULT NULL,
  `default_timezone` varchar(64) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_cities_districtId` FOREIGN KEY (`district_id`) REFERENCES `glb_districts` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_academic_sessions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '1',
  `current_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_current` = 1) then `1` else NULL end)) STORED,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_acadSessions_shortName` (`short_name`),
  UNIQUE KEY `uq_acadSession_currentFlag` (`current_flag`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_boards` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_academicBoard_name` (`name`),
  UNIQUE KEY `uq_academicBoard_shortName` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_languages` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(10) NOT NULL,                  -- ISO code: en, hi, fr, ar
  `name` VARCHAR(50) NOT NULL,                  -- English, Hindi, French...
  `native_name` VARCHAR(50) DEFAULT NULL,       -- "हिन्दी", "Français"
  `direction` ENUM('LTR','RTL') DEFAULT 'LTR',  -- Left to Rght / Right to Left
  `is_active` TINYINT(1) DEFAULT 1,
  UNIQUE KEY `uq_languages_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_menus` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` INT unsigned DEFAULT NULL,     -- FK to self
  `is_category` tinyint(1) NOT NULL DEFAULT '0',
  `code` varchar(60) NOT NULL,
  `slug` VARCHAR(150) NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `icon` varchar(150) DEFAULT NULL,
  `route` varchar(255) DEFAULT NULL,
  `sort_order` int unsigned NOT NULL,
  `visible_by_default` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_menus_code` (`code`),
  CONSTRAINT `fk_menus_parentId` FOREIGN KEY (`parent_id`) REFERENCES `glb_menus` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_is_category_parentId` CHECK ((((`is_category` = 1) and (`parent_id` is NULL)) or (`is_category` = 0)))
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_modules` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` INT unsigned DEFAULT NULL,    -- fk to self
  `name` varchar(50) NOT NULL,
  `version` tinyint NOT NULL DEFAULT '1',
  `is_sub_module` tinyint(1) NOT NULL DEFAULT '0',    -- kept for CONSTRAINT `chk_isSubModule_parentId`
  `description` varchar(500) DEFAULT NULL,
  `is_core` tinyint(1) NOT NULL DEFAULT '0',
  `default_visible` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_view` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_add` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_edit` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_delete` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_export` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_import` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_print` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_module_parentId_name_version` (`parent_id`,`name`,`version`),
  CONSTRAINT `fk_module_parentId` FOREIGN KEY (`parent_id`) REFERENCES `glb_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT chk_isSubModule_parentId CHECK ((is_sub_module = 1 AND parent_id IS NOT NULL) OR (is_sub_module = 0 AND parent_id IS NULL))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_menu_model_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `menu_id` INT unsigned NOT NULL,
  `module_id` INT unsigned NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_menuModel_menuId` FOREIGN KEY (`menu_id`) REFERENCES `glb_menus` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_menuModel_moduleId` FOREIGN KEY (`module_id`) REFERENCES `glb_modules` (`id`)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- For MultiLingual Support
-- ------------------------------------------------------------------
-- Old_Table - Need to be verified
-- CREATE TABLE IF NOT EXISTS `sys_masters_translations` (
--   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--   `model_type` VARCHAR(190) NOT NULL,   -- Laravel morph type (e.g., 'App\\Models\\Menu')
--   `model_id` INT UNSIGNED NOT NULL,  -- The actual record ID in that model
--   `language_code` VARCHAR(10) NOT NULL, -- e.g., 'en', 'hi', 'fr'
--   `field_name` VARCHAR(100) NOT NULL,   -- e.g., 'name', 'description', 'title'
--   `translated_value` TEXT NOT NULL,     -- the actual translation
--   UNIQUE KEY `uq_mastersTrans_modelType_modelId_lang_field` (`model_type`, `model_id`, `language_code`, `field_name`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_translations` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `translatable_type` varchar(255) NOT NULL,
  `translatable_id` INT unsigned NOT NULL,
  `language_id` INT unsigned NOT NULL,
  `key` varchar(255) NOT NULL,
  `value` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_translatable_language_key` (`translatable_type`,`translatable_id`,`language_id`,`key`),
  KEY `sys_translations_translatable_type_translatable_id_index` (`translatable_type`,`translatable_id`),
  KEY `sys_translations_language_id_foreign` (`language_id`),
  CONSTRAINT `sys_translations_language_id_foreign` FOREIGN KEY (`language_id`) REFERENCES `glb_languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

