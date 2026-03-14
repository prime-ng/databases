-- Enhanced_table
-- -------------

-- All type of Menu (Category, Main Menu, Sub-Menu) will be in single Table
CREATE TABLE IF NOT EXISTS `gt_menus` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` INT unsigned DEFAULT NULL,
  `is_category` tinyint(1) NOT NULL DEFAULT '0',
  `code` varchar(60) NOT NULL,
  `slug` VARCHAR(150) NOT NULL,    -- New Field
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
  CONSTRAINT `fk_menus_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `menus` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_is_category_parent_id` CHECK ((((`is_category` = 1) and (`parent_id` is null)) or (`is_category` = 0)))
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Removed Fields - default_timezone
CREATE TABLE IF NOT EXISTS `countries` (
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
  UNIQUE KEY `countries_name_unique` (`name`),
  KEY `idx_country_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Removed Fields - default_timezone
CREATE TABLE IF NOT EXISTS `states` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `country_id` INT unsigned NOT NULL,
  `name` varchar(50) NOT NULL,
  `short_name` varchar(10) NOT NULL,
  `global_code` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_state_country_name` (`country_id`,`name`),
  KEY `idx_state_short_name` (`short_name`),
  KEY `idx_state_active` (`is_active`),
  CONSTRAINT `states_country_id_foreign` FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Removed Fields - default_timezone
CREATE TABLE IF NOT EXISTS `districts` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `state_id` INT unsigned NOT NULL,
  `name` varchar(50) NOT NULL,
  `short_name` varchar(10) NOT NULL,
  `global_code` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_district_state_name` (`state_id`,`name`),
  KEY `idx_district_active` (`is_active`),
  CONSTRAINT `districts_state_id_foreign` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=290 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cities` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `district_id` INT unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `global_code` varchar(20) DEFAULT NULL,
  `default_timezone` varchar(64) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cities_district_id_foreign` (`district_id`),
  KEY `idx_city_active` (`is_active`),
  CONSTRAINT `cities_district_id_foreign` FOREIGN KEY (`district_id`) REFERENCES `districts` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `permissions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(20) NOT NULL,  -- This will be used for dropdown
  `name` varchar(100) NOT NULL,
  `guard_name` varchar(255) NOT NULL,  -- used by Laravel routing
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,  -- we dont have is_active, why?
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permissions_name_guard_name_unique` (`short_name`,`guard_name`),
  UNIQUE KEY `permissions_name_guard_name_unique` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=176 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Note - is_system - will not be Orgization specific, it can work accros org but within the limitations of permission. Will be used for PG CRM Team.
CREATE TABLE IF NOT EXISTS `roles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `short_name` VARCHAR(20) NOT NULL,  -- This will be used for dropdown
  `description` VARCHAR(255) NULL,
  `guard_name` varchar(255) NOT NULL,
  `is_system`  TINYINT(1) NOT NULL DEFAULT 0, -- if true, role is system-managed 
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roles_name_guard_name_unique` (`org_id`,`name`,`guard_name`)
  UNIQUE KEY `roles_name_guard_name_unique` (`org_id`,`short_name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cn_org_role` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT UNSIGNED NOT NULL,    -- which school owns this role
  `role_id` INT UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_role_org_id_role_id` (`org_id`,`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `role_has_permissions` (
  `permission_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `role_has_permissions_role_id_foreign` (`role_id`),
  CONSTRAINT `role_has_permissions_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,  -- ON DELETE RESTRICT
  CONSTRAINT `role_has_permissions_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `model_has_permissions` (
  `permission_id` INT unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,  -- Edited Width from 255 to 190
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `model_has_permissions_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `model_has_permissions_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `model_has_roles` (
  `role_id` INT unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,  -- Edited Width from 255 to 190
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `model_has_roles_model_id_model_type_index` (`model_id`,`model_type`),
  CONSTRAINT `model_has_roles_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- acaemic_sessions is for maintain a standard across schools
CREATE TABLE IF NOT EXISTS `academic_sessions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '1',  -- Added New
  `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `1` else NULL end)) STORED,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_acad_sessions_short_name` (`short_name`),
  UNIQUE KEY `uq_Acad_Session_current_flag` (`current_flag`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `boards` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_board_name` (`name`),
  UNIQUE KEY `uq_board_shortName` (`short_name`),
  KEY `idx_board_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `org_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `address_1` varchar(200) DEFAULT NULL,
  `address_2` varchar(200) DEFAULT NULL,
  `city_id` INT unsigned NOT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `website_url` varchar(150) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_groups_short_name` (`short_name`),
  CONSTRAINT `fk_org_groups_city_id` FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `organizations` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_group_id` INT unsigned NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `school_name` varchar(100) NOT NULL,
  `city_id` INT unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_groupid_shortName` (`org_group_id`,`short_name`),
  CONSTRAINT `fk_organizations_city_id` FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_organizations_org_group_id` FOREIGN KEY (`org_group_id`) REFERENCES `org_groups` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `organization_details` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `udise_code` varchar(30) DEFAULT NULL,
  `affiliation_no` varchar(60) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `website_url` varchar(150) DEFAULT NULL,
  `address_1` varchar(200) DEFAULT NULL,
  `address_2` varchar(200) DEFAULT NULL,
  `area` varchar(100) DEFAULT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `phone_1` varchar(20) DEFAULT NULL,
  `phone_2` varchar(20) DEFAULT NULL,
  `whatsapp_number` varchar(20) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `locale` varchar(16) DEFAULT 'en_IN',
  `currency` varchar(8) DEFAULT 'INR',
  `established_date` date DEFAULT NULL,  -- School Established Date
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_groupid_shortName` (`org_group_id`,`short_name`),
  CONSTRAINT `fk_orgDetail_org_id` FOREIGN KEY (`org_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cn_org_academic_sessions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `academic_sessions_id` INT unsigned NOT NULL,  -- Added New
  `short_name` varchar(10) NOT NULL,
  `name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `organization_id` else NULL end)) STORED,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgAcademicSession_orgid_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_orgAcademicSession_current_flag` (`current_flag`),
  CONSTRAINT `fk_orgAcademicSession_session_id` FOREIGN KEY (`academic_sessions_id`) REFERENCES `academic_sessions` (`id`) ON DELETE CASCADE,  -- Added New
  CONSTRAINT `fk_orgAcademicSession_org_id` FOREIGN KEY (`org_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cn_board_organization` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `academic_sessions_id` INT unsigned NOT NULL,  -- Added New
  `board_id` INT unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_board_organization_board_id` FOREIGN KEY (`board_id`) REFERENCES `boards` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_board_organization_session_id` FOREIGN KEY (`academic_sessions_id`) REFERENCES `academic_sessions` (`id`) ON DELETE CASCADE,  -- Added New
  CONSTRAINT `fk_board_organization_organization_id` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `modules` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` INT unsigned DEFAULT NULL,
  `name` varchar(50) NOT NULL,
  `version` tinyint NOT NULL DEFAULT '1',
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
  UNIQUE KEY `uq_module_parent_id_name_version` (`parent_id`,`name`,`version`),
  CONSTRAINT `fk_module_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `modules` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Organization may subscribe multiple plans and can opt different billing_cycles for different plans
CREATE TABLE IF NOT EXISTS `billing_cycles` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) NOT NULL,  -- 'MONTHLY','QUARTERLY','YEARLY','ONE_TIME'
  `name` VARCHAR(50) NOT NULL,
  `months_count` TINYINT UNSIGNED NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY `uq_billing_cycles_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `plans` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `version` int unsigned NOT NULL DEFAULT '0',
  `description` varchar(255) DEFAULT NULL,
  `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,
  `price_monthly` decimal(12,2) DEFAULT NULL,
  `price_yearly` decimal(12,2) DEFAULT NULL,
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `trial_days` int unsigned NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plan_code` (`plan_code`,`version`),
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cn_module_plan` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` INT unsigned NOT NULL,
  `module_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) unsigned NOT NULL,  -- Added Newly
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_module_plan_module_id` FOREIGN KEY (`module_id`) REFERENCES `modules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_module_plan_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Abbreviation Detail used for Tables Name to distinguish them
-- ------------------------------------------------------------

-- sys - System Tables
-- jnt - Join Table (Junction Table)
-- glb - Global Table
-- tim - Timetable Module
-- sch - School Setup
-- std - Student Management
-- tpt  Transport Module
-- lib  Library Module
-- fnt  FrontDesk Module
-- fin  Finance Mgmt
-- hos  Hostel Mgmt

-- CN  Connect Table
-- GT  Global Tables
-- SS  School Setup
-- TT  Timetable Module
-- SM  Student Mgmt
-- AE  Assessment & Exam
-- TM  Transport Module
-- LM  Library Module
-- FD  FrontDesk Module
-- FM  Finance Mgmt
-- HM  Hostel Mgmt

