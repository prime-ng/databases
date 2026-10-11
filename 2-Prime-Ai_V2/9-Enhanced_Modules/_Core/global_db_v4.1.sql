-- =====================================================================
-- Global DB (global_db) - VERSION 4.0 (PRODUCTION-GRADE) 
-- Enhanced from global_db_v3.sql
-- Reviewed by Brijesh on 8-Jun-2026
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- TABLE PREFIX: glb_ - Global database
-- =====================================================================

-- Geographical Location Management
-- -----------------------------------------------------------------------------------
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
    UNIQUE KEY `uq_glb_countries_name` (`name`),
    UNIQUE KEY `uq_glb_countries_shortName` (`short_name`),
    UNIQUE KEY `uq_glb_countries_globalCode` (`global_code`)
  ) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `glb_states` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `country_id` INT unsigned NOT NULL,    -- FK to glb_countries
    `name` varchar(50) NOT NULL,
    `short_name` varchar(10) NOT NULL,
    `global_code` varchar(10) DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_glb_states_countryId_name` (`country_id`,`name`),
    UNIQUE KEY `uq_glb_states_shortName` (`short_name`),
    UNIQUE KEY `uq_glb_states_globalCode` (`global_code`),
    CONSTRAINT `fk_glb_states_countryId` FOREIGN KEY (`country_id`) REFERENCES `glb_countries` (`id`) ON DELETE RESTRICT
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
    UNIQUE KEY `uq_glb_districts_stateId_name` (`state_id`,`name`),
    UNIQUE KEY `uq_glb_districts_shortName` (`short_name`),
    UNIQUE KEY `uq_glb_districts_globalCode` (`global_code`),
    CONSTRAINT `fk_glb_districts_stateId` FOREIGN KEY (`state_id`) REFERENCES `glb_states` (`id`) ON DELETE RESTRICT
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
    UNIQUE KEY `uq_glb_cities_districtId_name` (`district_id`,`name`),
    UNIQUE KEY `uq_glb_cities_shortName` (`short_name`),
    UNIQUE KEY `uq_glb_cities_globalCode` (`global_code`),
    CONSTRAINT `fk_glb_cities_districtId` FOREIGN KEY (`district_id`) REFERENCES `glb_districts` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Acedemic Session & Boards Management
-- -----------------------------------------------------------------------------------
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
    UNIQUE KEY `uq_glb_acadSessions_shortName` (`short_name`),
    UNIQUE KEY `uq_glb_acadSession_currentFlag` (`current_flag`)
  ) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- Start Date < End Date
  -- Check at Add/Edit - New Start date & End Date can not overlape with existing Start date & End Date. Trigger to check this.

  CREATE TABLE IF NOT EXISTS `glb_boards` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `short_name` varchar(20) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_glb_academicBoard_name` (`name`),
    UNIQUE KEY `uq_glb_academicBoard_shortName` (`short_name`)
  ) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Menu & Module Management
-- ------------------------------------------------------------------------------------
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
    UNIQUE KEY `uq_glb_menus_code` (`code`),
    CONSTRAINT `fk_glb_menus_parentId` FOREIGN KEY (`parent_id`) REFERENCES `glb_menus` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_glb_menus_is_category_parentId` CHECK ((((`is_category` = 1) and (`parent_id` is NULL)) or (`is_category` = 0)))
  ) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- we should be able able to use Drag & Drop to set Parent Child Relationship.

  CREATE TABLE IF NOT EXISTS `glb_modules` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `parent_id` INT unsigned DEFAULT NULL,    -- fk to self
    `module_key` varchar(10) NOT NULL,        -- fk to `tco_app_modules.key` (e.g. 'GLB', 'ACC', 'TPT', 'LIB', 'FEE')
    `code` varchar(6) NOT NULL,               -- Code will be Unique (3 Letter Module Code + 3 Letter Module Version) e.g. 'GLB001', 'GLB002', 'LIB001', 'LIB002'
    `name` varchar(50) NOT NULL,
    `version` tinyint NOT NULL DEFAULT '1',
    `is_sub_module` tinyint(1) NOT NULL DEFAULT '0',    -- kept for CONSTRAINT `chk_isSubModule_parentId`
    `description` varchar(500) DEFAULT NULL,
    `is_core` tinyint(1) NOT NULL DEFAULT '0',              -- Is this a core module (If Yes, cannot be removed from plans, will be considered as must have module)
    `default_visible` tinyint(1) NOT NULL DEFAULT '1',      -- Whether this module is visible by default
    `available_perm_view` tinyint(1) NOT NULL DEFAULT '1',  -- Whether View permission is available on this module
    `available_perm_add` tinyint(1) NOT NULL DEFAULT '1',   -- Whether Add permission is available on this module
    `available_perm_edit` tinyint(1) NOT NULL DEFAULT '1',  -- Whether Edit permission is available on this module
    `available_perm_delete` tinyint(1) NOT NULL DEFAULT '1',  -- Whether Delete permission is available on this module
    `available_perm_export` tinyint(1) NOT NULL DEFAULT '1',  -- Whether Export permission is available on this module
    `available_perm_import` tinyint(1) NOT NULL DEFAULT '1',  -- Whether Import permission is available on this module
    `available_perm_print` tinyint(1) NOT NULL DEFAULT '1',   -- Whether Print permission is available on this module
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_glb_modules_parentId_name_version` (`parent_id`,`name`,`version`),
    UNIQUE KEY `uq_glb_modules_code_version` (`code`),
    CONSTRAINT `fk_glb_modules_parentId` FOREIGN KEY (`parent_id`) REFERENCES `glb_modules` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_glb_modules_isSubModule_parentId` CHECK ((`is_sub_module` = 1 AND `parent_id` IS NOT NULL) OR (`is_sub_module` = 0 AND `parent_id` IS NULL))
  ) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- we should be able able to use Drag & Drop to set Parent Child Relationship.
  
  CREATE TABLE IF NOT EXISTS `glb_menu_model_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `menu_id` INT unsigned NOT NULL,
    `module_id` INT unsigned NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_glb_menuModel_menuId` FOREIGN KEY (`menu_id`) REFERENCES `glb_menus` (`id`)  ON DELETE RESTRICT,
    CONSTRAINT `fk_glb_menuModel_moduleId` FOREIGN KEY (`module_id`) REFERENCES `glb_modules` (`id`)  ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- For MultiLingual Support
-- ------------------------------------------------------------------------------------
  -- Old_Table - Need to be verified
  -- CREATE TABLE IF NOT EXISTS `sys_masters_translations` (
  --   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  --   `model_type` VARCHAR(190) NOT NULL,   -- Laravel morph type (e.g., 'App\\Models\\Menu')
  --   `model_id` INT UNSIGNED NOT NULL,     -- The actual record ID in that model
  --   `language_code` VARCHAR(10) NOT NULL, -- e.g., 'en', 'hi', 'fr'
  --   `field_name` VARCHAR(100) NOT NULL,   -- e.g., 'name', 'description', 'title'
  --   `translated_value` TEXT NOT NULL,     -- the actual translation
  --   UNIQUE KEY `uq_mastersTrans_modelType_modelId_lang_field` (`model_type`, `model_id`, `language_code`, `field_name`)
  -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `glb_languages` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(10) NOT NULL,                  -- ISO code: en, hi, fr, ar
    `name` VARCHAR(50) NOT NULL,                  -- English, Hindi, French...
    `native_name` VARCHAR(50) DEFAULT NULL,       -- "हिन्दी", "Français"
    `direction` ENUM('LTR','RTL') DEFAULT 'LTR',  -- Left to Rght / Right to Left
    `is_active` TINYINT(1) DEFAULT 1,
    UNIQUE KEY `uq_glb_languages_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    UNIQUE KEY `uq_glb_transType_transId_lang_key` (`translatable_type`,`translatable_id`,`language_id`,`key`),
    KEY `idx_glb_translations_transType_transId` (`translatable_type`,`translatable_id`),
    KEY `idx_glb_translations_langId` (`language_id`),
    CONSTRAINT `fk_glb_langId` FOREIGN KEY (`language_id`) REFERENCES `glb_languages` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- --------------------------------------------------------------------------
-- NEW TABLES
-- --------------------------------------------------------------------------

-- This table will capture Modules detail of entire application, which will be used in application development.
-- Screens of this table will not be available for Tenant to modify. This will be completely managed by Super Admin.
CREATE TABLE IF NOT EXISTS `glb_app_modules` (
	`key`           VARCHAR(10) NOT NULL,  -- Can not be changed by User (Tenant) e.g. 'ACC','TPT',...
	`ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- display order in menu
	`code`          VARCHAR(30) NOT NULL,  -- 'ACCOUNTING', 'TRANSPORT', 'HOSTEL', 'LIBRARY', 'STUDENT_FEE' etc.
	`name`          VARCHAR(100) NOT NULL, -- 'Accounting', 'Transport', 'Hostel & Boarding', 'Library', 'Student Fee', etc.
	`module_prefix` VARCHAR(5) NULL, -- Source Module Tables Prefix (`tpt_`, `lib_`, etc.)
	`is_system`     TINYINT(1) NOT NULL DEFAULT 0, -- 1 = For System use, can not be deleted/edited.
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1,
	`created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`    TIMESTAMP NULL,
	PRIMARY KEY (`key`),
	UNIQUE KEY `uq_sys_module_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Data Seeder:
-- Key | Ordinal | Code 				| Name											| Module_Prefix | Is_System | Is_Active
---------------------------------------------------------------------------------------------------------------------------
-- ACC | 1 		  | ACCOUNTING			| Accounting									| acc_ 			 | 1         | 1
-- ACC | 2 		  | TRANSPORT			| Transport										| tpt_ 			 | 0         | 1
-- ACC | 3 		  | HOSTEL				| Hostel & Boarding							| hst_ 			 | 0         | 1
-- 


-- This table is to store the global Settings detail for all the Modules. This will be used in application development.
-- Screens of this table will not be available for Tenant to modify. This will be completely managed by Super Admin.
  CREATE TABLE IF NOT EXISTS `glb_app_config` (
    `id`                MEDIUMINT unsigned NOT NULL AUTO_INCREMENT,
    `module_id`         VARCHAR(10) NOT NULL,         -- FK to glb_app_modules.key
    `key`               varchar(150) NOT NULL,        -- Can not changed by user (He can edit other fields only but not KEY)
    `key_name`          varchar(255) NOT NULL,        -- Can be Changed by user
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT '1',
    `value`             varchar(512) NOT NULL,        -- Can be Changed by user
    `value_type`        ENUM('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'TIME', 'DATETIME', 'JSON') NOT NULL,
    `description`       varchar(255) NOT NULL,
    `additional_info`   JSON DEFAULT NULL,
    `tenant_can_modify` tinyint(1) NOT NULL DEFAULT '0',    -- Tenant can modify only if 1
    `mandatory`         tinyint(1) NOT NULL DEFAULT '1',    -- Is it mandatory to set this value
    `used_by_app`       tinyint(1) NOT NULL DEFAULT '1',    -- Is it used by app
    `is_active`         tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at`        timestamp NULL DEFAULT NULL,
    `created_at`        timestamp NULL DEFAULT NULL,
    `updated_at`        timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_settings_ordinal` (`ordinal`),
    UNIQUE KEY `uq_settings_key` (`key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Data Seeder:
-- Model | Key 								| Key	Name															                        | Type		  | Value
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- ACC   | COST_CENTRE_APPLICABLE		| Cost centres are applicable									            | Boolean 	| True / False
-- ACC   | IS_INTEREST_ON						| Activate Interest Calculation								            | Boolean 	| True / False
-- ACC   | CREDIT_DAYS_CHK_ON				| Check for credit days during voucher entry	            | Boolean 	| True / False
-- ACC   | COST_CENTRE_REQUIRED			| Cost Centre Required												            | Boolean 	| True / False
-- 

-- ===============================================================================================================================================================
-- CHANGE LOG:
-- ===============================================================================================================================================================
-- Added New Coloumn in Table: glb_modules New Coloumns: (code varchar(6) NOT NULL,) Code will be Unique (Module+Version > XXX+NNN) e.g. 'GLB001', 'GLB002', 'LIB001', 'LIB002'
