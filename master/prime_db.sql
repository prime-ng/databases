-- Prefix Abbreviation Detail used for Tables Name to distinguish them
-- -------------------------------------------------------------------
-- sys - System Configuration
-- glb - Global Masters
-- tim - Timetable Module
-- sch - School Setup
-- std - Student Management
-- exm - Exam Management
-- quz - Quiz & Assessment Management
-- qns - Questiona Creation & Management
-- beh - Behaviour Management
-- tpt - Transport Module
-- lib - Library Module
-- fnt - FrontDesk Module
-- fin - Finance Mgmt
-- hos - Hostel Mgmt
-- mes - Mess Management
-- bil - Billing & plans

-- Below is a Postfix Abbreviation to identify Join Tables
-- ------------------------------------------------------------
-- jnt - Join Table (Junction Table)

-- prm - only for the table required to be in prime_db

-- Important Note
-- 1 - We will have 3 Layers of Databases 1-prime_db database 2-global_masters database 3-org specific databases (one for every Tenant)
-- 2 - App will be developed in such way that same app will work as 2 identical instance 1-PrimeGurukul 2-Schools
-- 2 - Tables which we need in PG but we may need them in tenant databases also. Those tables will have prefix "sys", 
--     so that app can work seamlesly for PrimeGurukul instance and for Tenant instance both.


-- --------------------------------------------------------------------------------------------
-- Create Views after creating global_master database and it's tables
-- --------------------------------------------------------------------------------------------

CREATE VIEW glb_countries AS SELECT * FROM global_master.glb_countries;
CREATE VIEW glb_states    AS SELECT * FROM global_master.glb_states;
CREATE VIEW glb_districts AS SELECT * FROM global_master.glb_districts;
CREATE VIEW glb_cities    AS SELECT * FROM global_master.glb_cities;


-- System Tables
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_languages` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(10) NOT NULL,                  -- ISO code: en, hi, fr, ar
  `name` VARCHAR(50) NOT NULL,                  -- English, Hindi, French...
  `native_name` VARCHAR(50) DEFAULT NULL,       -- "हिन्दी", "Français"
  `direction` ENUM('LTR','RTL') DEFAULT 'LTR',  -- Left to Rght / Right to Left
  `is_active` TINYINT(1) DEFAULT 1,
  UNIQUE KEY `uq_languages_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_menus` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT NULL,     -- FK
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
  CONSTRAINT `fk_menus_parentId` FOREIGN KEY (`parent_id`) REFERENCES `prm_menus` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_is_category_parentId` CHECK ((((`is_category` = 1) and (`parent_id` is NULL)) or (`is_category` = 0)))
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(20) NOT NULL,  -- This will be used for dropdown
  `name` varchar(100) NOT NULL,
  `guard_name` varchar(255) NOT NULL,  -- used by Laravel routing
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,  -- we dont have is_active, why?
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permissions_shortName_guardName` (`short_name`,`guard_name`),
  UNIQUE KEY `uq_permissions_name_guardName` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=176 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `short_name` VARCHAR(20) NOT NULL,
  `description` VARCHAR(255) NULL,
  `guard_name` varchar(255) NOT NULL,
  `is_system`  TINYINT(1) NOT NULL DEFAULT 0, -- if true, role belongs to PG
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_name_guardName` (`name`,`guard_name`)
  UNIQUE KEY `uq_roles_name_guardName` (`short_name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_role_has_permissions_jnt` (
  `permission_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `idx_roleHasPermissions_roleId` (`role_id`),
  CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_model_has_permissions_jnt` (
  `permission_id` bigint unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,
  `model_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_odelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `sys_permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_model_has_roles_jnt` (
  `role_id` bigint unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,
  `model_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_modules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT NULL,    -- fk to self
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
  CONSTRAINT `fk_module_parentId` FOREIGN KEY (`parent_id`) REFERENCES `sys_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT chk_isSubModule_parentId CHECK ((is_sub_module = 1 AND parent_id IS NOT NULL) OR (is_sub_module = 0 AND parent_id IS NULL))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_menu_model_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `menu_id` bigint unsigned NOT NULL,
  `module_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_menuModel_menuId` FOREIGN KEY (`menu_id`) REFERENCES `sys_menus` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_menuModel_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `emp_code` VARCHAR(20) NOT NULL,
  `short_name` varchar(30) NOT NULL,   -- This Field will be used for showing Dropdown of Users i.e. Teachers, Students, Parents
  `name` varchar(100) NOT NULL,        -- Full Name (First Name, Middle Name, Last Name)
  `email` varchar(150) NOT NULL,
  `mobile_no` varchar(32) DEFAULT NULL,
  `phone_no` varchar(32) DEFAULT NULL,
  `two_factor_auth_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `mobile_verified_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `password` varchar(255) COLLATE utf8mb4_unicode_bin NOT NULL,
  `is_super_admin` tinyint(1) NOT NULL DEFAULT '0',
  `last_login_at` datetime DEFAULT NULL,
  `super_admin_flag` tinyint GENERATED ALWAYS AS ((case when (`is_super_admin` = 1) then 1 else NULL end)) STORED,
  `remember_token` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_empCode` (`emp_code`),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_mobileNo` (`mobile_no`),
  UNIQUE KEY `uq_single_super_admin` (`super_admin_flag`),
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* Optional triggers to prevent deleting/demoting super admin (you already used triggers for sessions) */
DELIMITER $$
CREATE TRIGGER trg_users_prevent_delete_super BEFORE DELETE ON users
FOR EACH ROW
BEGIN
  IF OLD.is_super_admin = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Super Admin cannot be deleted';
  END IF;
END$$

CREATE TRIGGER trg_users_prevent_update_super BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
  IF OLD.is_super_admin = 1 AND NEW.is_super_admin = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Super Admin cannot be demoted';
  END IF;
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS `sys_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(255) NULL,    -- Here we will describe the use of the variable
  `key` varchar(100) NOT NULL,        -- This will be the Key to connect Value with it
  `value` varchar(255) DEFAULT NULL,          -- Actual stored setting value. Could be string, JSON, or serialized data depending on type
  `type` varchar(50) DEFAULT NULL,    -- e.g. 'string','json','int','boolean', 'date' etc.
  `is_public` tinyint(1) NOT NULL DEFAULT 0,  -- Flag — 1 means this setting can be safely exposed to the frontend (e.g. school logo, theme color), 0 means internal/backend-only (e.g. API keys).
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_settings_key` (`key`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ordinal` tinyint unsigned NOT NULL,
  `key` varchar(50) NOT NULL,
  `value` varchar(100) NOT NULL,
  `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownTable_org_ordinal_key` (`ordinal`,`key`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_media` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `model_type` varchar(255) NOT NULL,
  `model_id` bigint unsigned NOT NULL,
  `uuid` char(36) DEFAULT NULL,
  `collection_name` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `mime_type` varchar(255) DEFAULT NULL,
  `disk` varchar(255) NOT NULL,
  `conversions_disk` varchar(255) DEFAULT NULL,
  `size` bigint unsigned NOT NULL,
  `manipulations` json NOT NULL,
  `custom_properties` json NOT NULL,
  `generated_conversions` json NOT NULL,
  `responsive_images` json NOT NULL,
  `order_column` int unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_media_uuid` (`uuid`),
  KEY `idx_media_modelType_modelId` (`model_type`,`model_id`),
  KEY `idx_media_orderColumn` (`order_column`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- For MultiLingual Support
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sys_masters_translations` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `model_type` VARCHAR(190) NOT NULL,   -- Laravel morph type (e.g., 'App\\Models\\Menu')
  `model_id` BIGINT UNSIGNED NOT NULL,  -- The actual record ID in that model
  `language_code` VARCHAR(10) NOT NULL, -- e.g., 'en', 'hi', 'fr'
  `field_name` VARCHAR(100) NOT NULL,   -- e.g., 'name', 'description', 'title'
  `translated_value` TEXT NOT NULL,     -- the actual translation
  UNIQUE KEY `uq_mastersTrans_modelType_modelId_lang_field` (`model_type`, `model_id`, `language_code`, `field_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tenant Creation
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS prm_tenant_groups (
  id bigint unsigned NOT NULL AUTO_INCREMENT,
  code VARCHAR(20) NOT NULL,
  short_name varchar(50) NOT NULL,
  name varchar(150) NOT NULL,
  address_1 varchar(200) DEFAULT NULL,
  address_2 varchar(200) DEFAULT NULL,
  city_id bigint unsigned NOT NULL,
  pincode varchar(10) DEFAULT NULL,
  website_url varchar(150) DEFAULT NULL,
  email varchar(100) DEFAULT NULL,
  is_active tinyint(1) NOT NULL DEFAULT 1,
  deleted_at timestamp NULL DEFAULT NULL,
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tenantGroups_shortName (short_name),
  CONSTRAINT fk_tenantGroups_cityId FOREIGN KEY (city_id) REFERENCES glb_cities (id) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS prm_tenant (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_group_id bigint unsigned NOT NULL,
  code VARCHAR(20) NOT NULL,
  short_name varchar(50) NOT NULL,
  name varchar(150) NOT NULL,
  udise_code varchar(30) DEFAULT NULL,
  affiliation_no varchar(60) DEFAULT NULL,
  email varchar(100) DEFAULT NULL,
  website_url varchar(150) DEFAULT NULL,
  address_1 varchar(200) DEFAULT NULL,
  address_2 varchar(200) DEFAULT NULL,
  area varchar(100) DEFAULT NULL,
  city_id bigint unsigned NOT NULL,
  pincode varchar(10) DEFAULT NULL,
  phone_1 varchar(20) DEFAULT NULL,
  phone_2 varchar(20) DEFAULT NULL,
  whatsapp_number varchar(20) DEFAULT NULL,
  longitude decimal(10,7) DEFAULT NULL,
  latitude decimal(10,7) DEFAULT NULL,
  locale varchar(16) DEFAULT 'en_IN',
  currency varchar(8) DEFAULT 'INR',
  established_date date DEFAULT NULL,
  is_active tinyint(1) NOT NULL DEFAULT 1,
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  deleted_at timestamp NULL DEFAULT NULL,
  UNIQUE KEY uq_org (org_id),
  CONSTRAINT fk_tenantGroups_cityId FOREIGN KEY (city_id) REFERENCES glb_cities (id) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS prm_tenant_domains (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT NOT NULL,
  domain VARCHAR(255) NOT NULL,
  db_name VARCHAR(100) NOT NULL,
  db_host VARCHAR(200) NOT NULL,
  db_port VARCHAR(10) NOT NULL DEFAULT '3306',
  db_username VARCHAR(100) NOT NULL,
  db_password VARCHAR(255) NOT NULL,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  updated_at timestamp NULL DEFAULT NULL,
  deleted_at timestamp NULL DEFAULT NULL,
  CONSTRAINT fk_tenantDomains_tenantId FOREIGN KEY (tenant_id) REFERENCES prm_tenant (id) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Plan & Module
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prm_billing_cycles` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `short_name` VARCHAR(50) NOT NULL,  -- 'MONTHLY','QUARTERLY','YEARLY','ONE_TIME'
  `name` VARCHAR(50) NOT NULL,
  `months_count` TINYINT UNSIGNED NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_recurring` TINYINT(1) NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY `uq_billingCycles_code` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `prm_plans` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(20) NOT NULL,
  `version` int unsigned NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `billing_cycle_id` SMALLINT NOT NULL,           -- Default billing Cycle
  `price_monthly` decimal(12,2) DEFAULT NULL,     -- For Same Plan we may charge different for Monthly payment/Quaterly/Yearly
  `price_quarterly` decimal(12,2) DEFAULT NULL,   -- For Same Plan we may charge different for Monthly payment/Quaterly/Yearly
  `price_yearly` decimal(12,2) DEFAULT NULL,      -- For Same Plan we may charge different for Monthly payment/Quaterly/Yearly
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `trial_days` int unsigned NOT NULL DEFAULT '0', -- Allowed Trial Days
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plans_planCode_version` (`plan_code`,`version`),
  CONSTRAINT `fk_plans_billingCycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `prm_module_plan_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` bigint unsigned NOT NULL,
  `module_id` bigint unsigned NOT NULL,
  `is_active` tinyint(1) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_modulePlan_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_modulePlan_planId` FOREIGN KEY (`plan_id`) REFERENCES `prm_plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tenant Subscription
-- ------------------------------------------------------------
-- old name 'prm_organization_plan_jnt'
CREATE TABLE IF NOT EXISTS `prm_tenant_plan_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint unsigned NOT NULL,             -- old name 'org_id'
  `plan_id` bigint unsigned NOT NULL,
  `is_subscribed` tinyint(1) NOT NULL DEFAULT '1',
  `is_trial` tinyint(1) NOT NULL DEFAULT '0',
  `auto_renew` tinyint(1) NOT NULL DEFAULT '1',
  `automatic_billing` tinyint(1) NOT NULL DEFAULT '1',
  `status` varchar(20) NOT NULL DEFAULT 'ACTIVE',  -- Need to be created in dorpdown Table ('ACTIVE','SUSPENDED','CANCELED','EXPIRED')
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `current_flag` int GENERATED ALWAYS AS ((case when (`is_subscribed` = 1) then `org_id` else NULL end)) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenantPlan_currentFlag_planId` (`current_flag`,`plan_id`),
  CONSTRAINT `fk_tenantPlan_orgId` FOREIGN KEY (`tenant_id`) REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tenantPlan_planId` FOREIGN KEY (`plan_id`) REFERENCES `prm_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `prm_tenant_plan_rates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tenant_plan_id` bigint unsigned NOT NULL,         -- Old name 'organization_plan_id'
  `start_date` date DEFAULT NULL,                    -- Plan Start Date
  `end_date` date DEFAULT NULL,                      -- Plan End Date
  `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,
  `billing_cycle_day` tinyint NOT NULL DEFAULT '1',  -- This will be day of billing every month for this Org.
  `monthly_rate` decimal(12,2) NOT NULL,
  `rate_per_cycle` decimal(12,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `min_billing_qty` int unsigned NOT NULL DEFAULT '1',  -- Edited Name (Lencenses (if Student count < Min_Qty then min_qty will be charged))
  `discount_percent` decimal(5,2) NOT NULL DEFAULT '0.00',  -- discount in percentage per billing cycle
  `discount_amount` decimal(12,2) NOT NULL DEFAULT '0.00',  -- discount as a fixed amount per billing cycle
  `discount_remark` varchar(50) NULL,                       -- Added New
  `extra_charges` decimal(12,2) NOT NULL DEFAULT '0.00',    -- Added New
  `charges_remark` varchar(50) NULL,                        -- Added New
  `tax1_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax1_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `tax2_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax2_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `tax3_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax3_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `tax4_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax4_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `credit_days` SMALLINT UNSIGNED NOT NULL,                 -- Number of day to calculate 'next_billing_date'
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenantPlanRates_PlanId_stDate_endDate` (`tenant_plan_id`,`start_date`,`end_date`),
  CONSTRAINT `fk_tenantPlanRates_billingCycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tenantPlanRates_orgPlanId` FOREIGN KEY (`organization_plan_id`) REFERENCES `prm_tenant_plan_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- old name 'sch_module_organization_plan_jnt'
CREATE TABLE IF NOT EXISTS `prm_tenant_plan_module_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `module_id` bigint unsigned NOT NULL,
  `tenant_plan_id` bigint unsigned NOT NULL,     -- old name 'organization_plan_id'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_moduleTenantPlan_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_moduleTenantPlan_tenantPlanId` FOREIGN KEY (`tenant_plan_id`) REFERENCES `prm_tenant_plan_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- This Table will have entries for the plan validity date range within the current Academic Session (1st April to 31st March).
CREATE TABLE prm_tenant_plan_billing_schedule (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_plan_id BIGINT UNSIGNED NOT NULL,
    tenant_id BIGINT UNSIGNED NOT NULL,
    billing_cycle_id SMALLINT UNSIGNED NOT NULL,
    schedule_billing_date DATE NOT NULL,
    billing_start_date DATE NOT NULL,
    billing_end_date DATE NOT NULL,
    bill_generated TINYINT(1) NOT NULL DEFAULT 0,
    generated_invoice_id BIGINT UNSIGNED DEFAULT NULL,  -- Fk to bil_tenant_invoices
    is_active tinyint(1) NOT NULL DEFAULT '1',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tenantPlanBillSched_planId FOREIGN KEY (tenant_plan_id) REFERENCES prm_tenant_plan_jnt(id) ON DELETE CASCADE,
    CONSTRAINT fk_tenantPlanBillSched_tenant FOREIGN KEY (tenant_id) REFERENCES prm_tenant(id) ON DELETE CASCADE,
    CONSTRAINT fk_tenantPlanBillSched_cycle FOREIGN KEY (billing_cycle_id) REFERENCES prm_billing_cycles(id) ON DELETE RESTRICT,
    CONSTRAINT fk_tenantPlanBillSched_invId FOREIGN KEY (generated_invoice_id) REFERENCES bil_tenant_invoices(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tenant Invoicing
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `bil_tenant_invoices` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` BIGINT UNSIGNED NOT NULL,               -- old name 'org_id'
  `tenant_plan_id` BIGINT UNSIGNED NOT NULL,          -- old Name 'organization_plan_id'
  `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,      -- FK
  `invoice_no` VARCHAR(50) NOT NULL,                  -- Should be Auto-Generated
  `invoice_date` DATE NOT NULL,                       -- Invoice Date will always be Next Day to billing_end_date
  `billing_start_date` DATE NOT NULL,
  `billing_end_date` DATE NOT NULL,
  `min_billing_qty` int unsigned NOT NULL DEFAULT '1',    -- No of Lincenses (if Student count < Min_Qty then min_qty will be charged))
  `total_user_qty` int unsigned NOT NULL DEFAULT '1',     -- Number of licenses used by Org in the billing period
  `plan_rate` decimal(12,2) NOT NULL,                     -- applicable plan rate as per school aggrement
  `billing_qty` int unsigned NOT NULL DEFAULT '1',        -- Billing Qty. will be either `min_billing_qty` or `total_license_qty`, whcihcever is higher)
  `sub_total` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `discount_percent` decimal(5,2) NOT NULL DEFAULT '0.00',  -- discount in percentage per billing cycle
  `discount_amount` decimal(12,2) NOT NULL DEFAULT '0.00',  -- discount as a fixed amount per billing cycle
  `discount_remark` varchar(50) NULL,
  `extra_charges` decimal(12,2) NOT NULL DEFAULT '0.00', 
  `charges_remark` varchar(50) NULL,
  `tax1_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `tax1_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax1_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax2_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- 
  `tax2_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax2_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax3_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- 
  `tax3_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax3_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax4_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- 
  `tax4_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax4_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total_tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00, 
  `net_payable_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- 
  `paid_amount` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING',        -- Will use Dropdown Table to populate (Tenant_Invoice_Status)
  `credit_days`  SMALLINT UNSIGNED NOT NULL,              -- This will be used to calculat Due Date
  `payment_due_date` DATE NOT NULL,                       -- Bill Date + credit_days
  `is_recurring` TINYINT(1) NOT NULL DEFAULT 1,
  `auto_renew` TINYINT(1) NOT NULL DEFAULT 1,
  `remarks` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tenantInvoices_invoiceNo` (`invoice_no`),
  CONSTRAINT `fk_tenantInvoices_tenantId` FOREIGN KEY (`tenant_id`) REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tenantInvoices_PlanId` FOREIGN KEY (`tenant_plan_id`) REFERENCES `prm_tenant_plan_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tenantInvoices_cycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_modules_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_invoice_id` BIGINT UNSIGNED NOT NULL,   -- fk to (bil_tenant_invoices)
  `module_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK
  UNIQUE KEY `uq_tenantInvModule_orgInvId_moduleId` (`tenant_invoicing_id`, `module_id`),
  CONSTRAINT `fk_tenantInvModule_invoicingId` FOREIGN KEY (`tenant_invoice_id`) REFERENCES `bil_tenant_invoice` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tenantInvModule_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_payments` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_invoice_id` BIGINT UNSIGNED NOT NULL,    -- fk to (bil_tenant_invoices)
  `payment_date` DATE NOT NULL,
  `transaction_id` VARCHAR(100) DEFAULT NULL,
  `mode` VARCHAR(20) NOT NULL DEFAULT 'ONLINE',      -- use dropdown table ('ONLINE','BANK_TRANSFER','CASH','CHEQUE')
  `mode_other` VARCHAR(20) DEFAULT NULL,
  `amount_paid` DECIMAL(14,2) NOT NULL,
  `consolidated_amount` DECIMAL(14,2) NULL,      -- If Consolidated Payment then only this will be stored else Null.
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `payment_status` NOT NULL VARCHAR(20) DEFAULT 'SUCCESS',  -- use dropdown table ('INITIATED','SUCCESS','FAILED')
  `gateway_response` JSON DEFAULT NULL,
  `payment_reconciled` tinyint(1) NOT NULL DEFAULT '0',
  `remarks` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_tenantInvPayment_tenantInvId` FOREIGN KEY (`tenant_invoicing_id`) REFERENCES `bil_tenant_invoicing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note - Below table will have multiple records for every billing. 1 Record for every action.
CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_audit_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_invoicing_id` BIGINT UNSIGNED NOT NULL,        -- fk to (bil_tenant_invoices)
  `action_date` TIMESTAMP not NULL,
  `action_type` VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- use dropdown table ('Not Billed','Bill Generated','Overdue','Notice Sent','Fully Paid')
  `performed_by` BIGINT UNSIGNED DEFAULT NULL,           -- which user perform the ation
  `event_info` JSON DEFAULT NULL,
  `notes` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_audit_billing` FOREIGN KEY (`tenant_invoicing_id`) REFERENCES `bil_tenant_invoicing` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------------------------------------
-- Change Log
-- ----------------------------------------------------------------------------------------------------------
-- Add New Field  - Table(bil_tenant_invoicing_payments)    - Field(consolidated_amount)
-- Change Filed   - Table(bil_tenant_invoicing_audit_logs)  - Field(notes) (Make it Varchar(500) from text)
-- Add New Field  - Table(bil_tenant_invoicing_audit_logs)  - Field(event_info)
-- Change Filed   - Table(bil_tenant_invoicing_audit_logs)  - Field(action_date) Change Date -> timestamp
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--

