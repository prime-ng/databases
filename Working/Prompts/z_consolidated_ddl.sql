-- This is etmporary file to consolidate all DDL scripts for easier management.

-- ----------------------------------------------------------------------------------------------------------------
-- prime_db.sql
-- ----------------------------------------------------------------------------------------------------------------
-- This script initializes the database schema for the application.
-- Prefix Abbreviation Detail used for Tables Name to distinguish them
-- -------------------------------------------------------------------
-- sys - System Configuration
-- glb - Global Masters
-- tim - Timetable Module
-- sch - School Setup
-- std - Student Management
-- slb - Syllabus & Curriculum Management
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

CREATE VIEW glb_languages AS SELECT * FROM global_master.glb_languages;
CREATE VIEW glb_menus AS SELECT * FROM global_master.glb_menus;
CREATE VIEW glb_modules AS SELECT * FROM global_master.glb_modules;
CREATE VIEW glb_menu_model_jnt AS SELECT * FROM global_master.glb_menu_model_jnt;
CREATE VIEW glb_translations AS SELECT * FROM global_master.glb_translations;

-- System Tables
-- ------------------------------------------------------------

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

CREATE TABLE IF NOT EXISTS `sys_activity_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `subject_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `event` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `properties` json DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sys_activity_logs_subject_type_subject_id_index` (`subject_type`,`subject_id`),
  KEY `sys_activity_logs_user_id_foreign` (`user_id`),
  KEY `sys_activity_logs_created_at_user_id_index` (`created_at`,`user_id`),
  CONSTRAINT `sys_activity_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tenant Creation
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prm_tenant_groups` (
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

CREATE TABLE IF NOT EXISTS `prm_tenant` (
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

CREATE TABLE IF NOT EXISTS `prm_tenant_domains` (
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
  `billing_cycle_id` SMALLINT NOT NULL,           -- Default billing Cycle (This need to be json Type)
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

-- This Table will have entries for the plan validity date range within the current Academic Session (1st April to 31st March)
CREATE TABLE IF NOT EXISTS `prm_tenant_plan_billing_schedule` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_plan_id` BIGINT UNSIGNED NOT NULL,
    `tenant_id` BIGINT UNSIGNED NOT NULL,
    `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,
    `schedule_billing_date` DATE NOT NULL,
    `billing_start_date` DATE NOT NULL,
    `billing_end_date` DATE NOT NULL,
    `bill_generated` TINYINT(1) NOT NULL DEFAULT `0`,
    `generated_invoice_id` BIGINT UNSIGNED DEFAULT NULL,  -- Fk to bil_tenant_invoices
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_tenantPlanBillSched_planId` FOREIGN KEY (`tenant_plan_id`) REFERENCES `prm_tenant_plan_jnt`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tenantPlanBillSched_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `prm_tenant`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tenantPlanBillSched_cycle` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tenantPlanBillSched_invId` FOREIGN KEY (`generated_invoice_id`) REFERENCES `bil_tenant_invoices`(`id`) ON DELETE RESTRICT
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

CREATE TABLE IF NOT EXISTS `bil_tenant_email_schedules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `invoice_id` bigint unsigned NOT NULL,
  `schedule_time` timestamp NOT NULL,
  `status` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==========================================================================================================
-- global_db.sql 
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `glb_countries` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
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
  UNIQUE KEY `uq_countries_shortName` (`short_name`),
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_states` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `country_id` bigint unsigned NOT NULL,    -- fk
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
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `state_id` bigint unsigned NOT NULL,    -- fk
  `name` varchar(50) NOT NULL,
  `short_name` varchar(10) NOT NULL,
  `global_code` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_district_stateId_name` (`state_id`,`name`),
  CONSTRAINT `chk_districts_stateId` FOREIGN KEY (`state_id`) REFERENCES `glb_states` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=290 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_cities` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `district_id` bigint unsigned NOT NULL,    -- fk
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
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
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
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_academicBoard_name` (`name`),
  UNIQUE KEY `uq_academicBoard_shortName` (`short_name`),
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_languages` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(10) NOT NULL,                  -- ISO code: en, hi, fr, ar
  `name` VARCHAR(50) NOT NULL,                  -- English, Hindi, French...
  `native_name` VARCHAR(50) DEFAULT NULL,       -- "हिन्दी", "Français"
  `direction` ENUM('LTR','RTL') DEFAULT 'LTR',  -- Left to Rght / Right to Left
  `is_active` TINYINT(1) DEFAULT 1,
  UNIQUE KEY `uq_languages_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_menus` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT NULL,     -- FK to self
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
  CONSTRAINT `fk_module_parentId` FOREIGN KEY (`parent_id`) REFERENCES `glb_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT chk_isSubModule_parentId CHECK ((is_sub_module = 1 AND parent_id IS NOT NULL) OR (is_sub_module = 0 AND parent_id IS NULL))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_menu_model_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `menu_id` bigint unsigned NOT NULL,
  `module_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_menuModel_menuId` FOREIGN KEY (`menu_id`) REFERENCES `glb_menus` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_menuModel_moduleId` FOREIGN KEY (`module_id`) REFERENCES `glb_modules` (`id`)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- For MultiLingual Support
-- ------------------------------------------------------------------
-- Old_Table - Need to be verified
-- CREATE TABLE IF NOT EXISTS `sys_masters_translations` (
--   `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--   `model_type` VARCHAR(190) NOT NULL,   -- Laravel morph type (e.g., 'App\\Models\\Menu')
--   `model_id` BIGINT UNSIGNED NOT NULL,  -- The actual record ID in that model
--   `language_code` VARCHAR(10) NOT NULL, -- e.g., 'en', 'hi', 'fr'
--   `field_name` VARCHAR(100) NOT NULL,   -- e.g., 'name', 'description', 'title'
--   `translated_value` TEXT NOT NULL,     -- the actual translation
--   UNIQUE KEY `uq_mastersTrans_modelType_modelId_lang_field` (`model_type`, `model_id`, `language_code`, `field_name`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `translatable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `translatable_id` bigint unsigned NOT NULL,
  `language_id` bigint unsigned NOT NULL,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_translatable_language_key` (`translatable_type`,`translatable_id`,`language_id`,`key`),
  KEY `sys_translations_translatable_type_translatable_id_index` (`translatable_type`,`translatable_id`),
  KEY `sys_translations_language_id_foreign` (`language_id`),
  CONSTRAINT `sys_translations_language_id_foreign` FOREIGN KEY (`language_id`) REFERENCES `sys_languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------------
-- tenant_db.sql 
-- ----------------------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------
-- Create Views after creating global_master database and it's tables
-- --------------------------------------------------------------------------------------------

CREATE VIEW glb_countries  AS SELECT * FROM global_master.glb_countries;
CREATE VIEW glb_states     AS SELECT * FROM global_master.glb_states;
CREATE VIEW glb_districts  AS SELECT * FROM global_master.glb_districts;
CREATE VIEW glb_cities     AS SELECT * FROM global_master.glb_cities;
CREATE VIEW glb_academic_sessions  AS SELECT * FROM global_master.glb_districts;
CREATE VIEW glb_boards     AS SELECT * FROM global_master.glb_cities;

CREATE VIEW glb_languages AS SELECT * FROM global_master.glb_languages;
CREATE VIEW glb_menus AS SELECT * FROM global_master.glb_menus;
CREATE VIEW glb_modules AS SELECT * FROM global_master.glb_modules;
CREATE VIEW glb_menu_model_jnt AS SELECT * FROM global_master.glb_menu_model_jnt;
CREATE VIEW glb_translations AS SELECT * FROM global_master.glb_translations;


-- ------------------------------------------------------------
-- System Tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sys_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(20) NOT NULL,  -- This will be used for dropdown
  `name` varchar(100) NOT NULL,
  `guard_name` varchar(255) NOT NULL,  -- used by Laravel routing
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
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
  UNIQUE KEY `uq_roles_name_guardName` (`name`,`guard_name`),
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
  `prefered_language` bigint unsigned NOT NULL,    -- fk to glb_languages
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_empCode` (`emp_code`),
  UNIQUE KEY `uq_users_shortName` (`short_name`),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_mobileNo` (`mobile_no`),
  UNIQUE KEY `uq_single_super_admin` (`super_admin_flag`),
  CONSTRAINT `fk_users_language` FOREIGN KEY (`prefered_language`) REFERENCES `glb_languages` (`id`) ON DELETE CASCADE
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
  UNIQUE KEY `uq_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_dropdown_table` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ordinal` tinyint unsigned NOT NULL,
  `key` varchar(150) NOT NULL,
  `value` varchar(100) NOT NULL,
  `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownTable_ordinal_key` (`ordinal`,`key`)
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


-- -----------------------------------------------------------------------------------------------
-- Read only Organization Table in tenant_db, it will be replica of prg_tenent table of prime_db
-- this eliminate requirement to connect to prime_db for getting org. info.
-- -----------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_organizations` (
  `id` bigint unsigned NOT NULL,        -- it will have same id as it is in 'prm_tenant'
  `group_code` varchar(20) NOT NULL,
  `group_short_name` varchar(50) NOT NULL,
  `group_name` varchar(150) NOT NULL,
  `code` varchar(20) NOT NULL,
  `short_name` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `udise_code` varchar(30) DEFAULT NULL,
  `affiliation_no` varchar(60) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `website_url` varchar(150) DEFAULT NULL,
  `address_1` varchar(200) DEFAULT NULL,
  `address_2` varchar(200) DEFAULT NULL,
  `area` varchar(100) DEFAULT NULL,
  `city_id` bigint unsigned NOT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `phone_1` varchar(20) DEFAULT NULL,
  `phone_2` varchar(20) DEFAULT NULL,
  `whatsapp_number` varchar(20) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `locale` varchar(16) DEFAULT 'en_IN',
  `currency` varchar(8) DEFAULT 'INR',
  `established_date` date DEFAULT NULL,  -- School Established Date
  `flg_single_record` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chk_org_singleRecord` (`flg_single_record`),
  CONSTRAINT fk_organizations_cityId FOREIGN KEY (city_id) REFERENCES glb_cities (id) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `academic_sessions_id` bigint unsigned NOT NULL,  -- Added New
  `short_name` varchar(10) NOT NULL,
  `name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `current_flag` tinyint(1) GENERATED ALWAYS AS ((case when (`is_current` = 1) then '1' else NULL end)) STORED,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgAcademicSession_shortName` (`short_name`),
  UNIQUE KEY `uq_orgAcademicSession_currentFlag` (`current_flag`),
  CONSTRAINT `fk_orgAcademicSession_sessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `glb_academic_sessions` (`id`) ON DELETE CASCADE  -- Added New
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_board_organization_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `academic_sessions_id` bigint unsigned NOT NULL,
  `board_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_boardOrg_boardId` FOREIGN KEY (`board_id`) REFERENCES `glb_boards` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_boardOrg_academicSessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_classes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class 10'
  `short_name` varchar(10) DEFAULT NULL,      -- e.g. 'G1' or '10A'
  `ordinal` tinyint DEFAULT NULL,        -- This is signed tinyint to have (-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12)
  `code` CHAR(3) NOT NULL,         -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classes_shortName` (`short_name`),
  UNIQUE KEY `uq_classes_code` (`code`),
  UNIQUE KEY `uq_classes_name` (`name`),
  UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_sections` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,            -- e.g. 'A', 'B'
  `ordinal` tinyint unsigned DEFAULT 1,   -- will have sequence order for Sections
  `code` CHAR(1) NOT NULL,         -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sections_name` (`name`),
  UNIQUE KEY `uq_sections_code` (`code`),
  UNIQUE KEY `uq_sections_ordinal` (`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `class_id` int unsigned NOT NULL,     -- fk
  `section_id` int unsigned NOT NULL,   -- fk
  `class_secton_code` char(5) NOT NULL,       -- Combination of class Code + section Code i.e. '8th_A', '10h_B'  
  `capacity` tinyint unsigned DEFAULT NULL,        -- Targeted / Planned Quantity of stundets in Each Sections of every class.
  `total_student` tinyint unsigned DEFAULT NULL,   -- Actual Number of Student in the Class+Section
  `class_teacher_id` bigint unsigned NOT NULL,     -- fk
  `assistance_class_teacher_id` bigint unsigned NOT NULL,  -- fk  
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
  UNIQUE KEY `uq_lassSection_code` (`class_secton_code`),
  CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_sclassTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_AssClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=300 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
CREATE TABLE IF NOT EXISTS `sch_subject_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
  `name` varchar(50) NOT NULL,
  `code` char(3) NOT NULL,         -- 'MAJ','MIN','OPT','ACT','SPO'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjectTypes_shortName` (`short_name`),
  UNIQUE KEY `uq_subjectTypes_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_study_formats` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,         -- e.g., 'LAC','LAB','ACT','ART' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studyFormats_shortName` (`short_name`),
  UNIQUE KEY `uq_studyFormats_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_subjects` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,         -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjects_shortName` (`short_name`),
  UNIQUE KEY `uq_subjects_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
-- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
-- Removed 'short_name' as we can use `sub_stdformat_code`
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `subject_id` bigint unsigned NOT NULL,            -- FK
  `study_format_id` int unsigned NOT NULL,          -- FK
  `name` varchar(50) NOT NULL,
  `subj_stdformat_code` CHAR(7) NOT NULL,         -- Will be combination of (Subject.codee+'-'+StudyFormat.code) e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
  UNIQUE KEY `uq_subStudyFormat_subStdformatCode` (`sub_stdformat_code`),
  CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- There will be a Variable in 'sys_settings' table named 'SubjectGroup_Used_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_class_subj_types_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,                  -- FK
  `subject_Study_format_id` bigint unsigned NOT NULL,   -- FK
  `class_id` int NOT NULL,                              -- FK
  `section_id` int NULL,                                -- FK (Section can be null if Group will be used for all sectons)
  `subject_type_id` int unsigned NOT NULL,              -- FK
  `rooms_type_id` bigint unsigned NOT NULL,             -- FK
  `name` varchar(50) NOT NULL,                          -- 10th-A Science Lacture Major
  `clas_subj_stdformat_Subjtyp_code` CHAR(17) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','7th_A_SAN_OPT' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStdFmtClsSubjTyp_subStdFmt_cls_Sec_SubTyp` (`subject_Study_format_id`,`class_id`,`section_id`,`subject_type_id`),
  UNIQUE KEY `uq_subStdFmtClsSubjTyp_subStdformatCode` (`clas_subj_stdformat_Subjtyp_code`),
  CONSTRAINT `fk_subStdFmtClsSubjTyp_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Added rooms_type_id field & FK for it.


-- Table 'sch_subject_groups' will be used to assign all subjects to the students
-- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
-- Every Group will eb avalaible accross sections for a particuler class
CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_id` int NOT NULL,                        -- FK
  `section_id` int NULL,                          -- FK (Section can be null if Group will be used for all sectons)
  `short_name` varchar(30) NOT NULL,              -- 7th Science, 7th Commerce, 7th-A Science etc.
  `name` varchar(100) NOT NULL,                   -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjectGroups_shortName` (`short_name`),
  UNIQUE KEY `uq_subjectGroups_name` (`class_id`,`name`),
  CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE NULL
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `subject_group_id` bigint unsigned NOT NULL,                  -- FK
  `subj_stdformat_class_subjtypes_id` bigint unsigned NOT NULL, -- FK
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjGrpSubj_subjGrpId_subjStdFmtClsSubTyp` (`subject_group_id`,`subj_stdformat_class_subjtypes_id`),
  CONSTRAINT `fk_subjGrpSubj_subjectGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subjGrpSubj_subjStdFmtClsSubTyp` FOREIGN KEY (`subj_stdformat_class_subjtypes_id`) REFERENCES `sch_subject_study_format_class_subj_types_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` CHAR(7) NOT NULL,                       -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT'
  `short_name` varchar(30) NOT NULL,             -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
  `name` varchar(100) NOT NULL,
  `required_resources` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roomType_code` (`code`),
  UNIQUE KEY `uq_roomType_shortName` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_buildings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` char(2) NOT NULL,                      -- 2 digits code (10,11,12) 
  `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
  `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_buildings_code` (`code`),
  UNIQUE KEY `uq_buildings_name` (`short_name`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
CREATE TABLE IF NOT EXISTS `sch_rooms` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `building_id` int unsigned NOT NULL,   -- FK
  `room_type_id` int NOT NULL,           -- FK
  `code` CHAR(7) NOT NULL,               -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
  `short_name` varchar(30) NOT NULL,     -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
  `name` varchar(50) NOT NULL,
  `capacity` int unsigned DEFAULT NULL,
  `max_limit` int unsigned DEFAULT NULL,
  `resource_tags` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rooms_code` (`code`),
  UNIQUE KEY `uq_rooms_shortName` (`short_name`),
  CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_teachers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `joining_date` DATE NOT NULL,
  `total_experience_years` DECIMAL(4,1) DEFAULT NULL,       -- Total teaching experience
  `highest_qualification` VARCHAR(100) DEFAULT NULL,        -- e.g. M.Sc., Ph.D.
  `specialization` VARCHAR(150) DEFAULT NULL,               -- e.g. Mathematics, Physics
  `last_institution` VARCHAR(200) DEFAULT NULL,             -- e.g. DPS Delhi
  `awards` TEXT DEFAULT NULL,                               -- brief summary
  `skills` TEXT DEFAULT NULL,                               -- general skills list (comma/JSON)
  `qualifications_json` JSON DEFAULT NULL,   -- Array of {degree, specialization, university, year, grade}
  `certifications_json` JSON DEFAULT NULL,   -- Array of {name, issued_by, issue_date, expiry_date, verified}
  `experiences_json` JSON DEFAULT NULL,      -- Array of {institution, role, from_date, to_date, subject, remarks}
  `notes` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
  KEY `teachers_user_id_foreign` (`user_id`),
  CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_teachers_profile` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `teacher_id` BIGINT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `study_format_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `priority` ENUM('PRIMARY','SECONDARY') NOT NULL DEFAULT 'PRIMARY',
  `proficiency` INT UNSIGNED DEFAULT NULL,          -- 1–10 rating or %
  `special_skill_area` VARCHAR(100) DEFAULT NULL,   -- e.g. Robotics, AI, Debate
  `certified_for_lab` TINYINT(1) DEFAULT 0,         -- allowed to conduct practicals
  `assignment_meta` JSON DEFAULT NULL,              -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
  `notes` TEXT NULL,
  `effective_from` DATE DEFAULT NULL,
  `effective_to` DATE DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT '1',
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_teachersProfile_teacher` (`teacher_id`,`subject_id`,`study_format_id`),
  CONSTRAINT `fk_teachersProfile_teacherId` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Student Module
-- ==================================================================================

CREATE TABLE IF NOT EXISTS `std_students` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` bigint unsigned NOT NULL,          -- FK to sch_user
  `parent_id` bigint unsigned NOT NULL,        -- FK to sch_user
  `aadhar_id` VARCHAR(20) NOT NULL,            -- always permanent identity
  `apaar_id` VARCHAR(100) NOT NULL,            -- 12 digits numeric i.e. 9876 5432 1098
  `birth_cert_no` VARCHAR(50) NULL,
  `health_id` VARCHAR(50) NULL,                -- like ABHA number in India
  `smart_card_id` VARCHAR(100) NULL,           -- RFID Card Number / Smart Card Number
  `first_name` VARCHAR(100) NOT NULL,
  `middle_name` VARCHAR(100) DEFAULT NULL,
  `last_name` VARCHAR(100) DEFAULT NULL,
  `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL, DEFAULT 'Male',
  `dob` DATE NOT NULL,
  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') NOT NULL,
  `photo` VARCHAR(255) DEFAULT NULL,
  `current_status_id` int NOT NULL,    -- FK to `gl_dropdown_table`
  `note` varchar(200) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_aadharId` (`aadhar_id`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `std_student_detail` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `student_id` int DEFAULT NULL,         -- FK to 'std_students'
  `mobile` varchar(20) DEFAULT NULL,     -- Student Mobile
  `email` varchar(100) DEFAULT NULL,     -- Student Mail ID
  `current_address` text,
  `permanent_address` text,
  `city_id` varchar(100) DEFAULT NULL,   -- FK to 'glb_city'
  `pin` varchar(10) DEFAULT NULL,
  `religion` varchar(50) DEFAULT NULL,   -- FK to `gl_dropdown_table`
  `cast` varchar(50) DEFAULT NULL,       -- FK to `gl_dropdown_table`
  `right_to_edu` tinyint(1) NOT NULL DEFAULT '0',
  `bank_account_no` varchar(100) DEFAULT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `ifsc_code` varchar(100) DEFAULT NULL,
  `upi_id` varchar(100) DEFAULT NULL,
  `fee_depositor_pan_number` varchar(10) DEFAULT NULL,    -- or tax benefit
  `father_name` varchar(50) DEFAULT NULL,
  `father_phone` varchar(10) DEFAULT NULL,
  `father_occupation` varchar(20) DEFAULT NULL,
  `father_email` varchar(100) DEFAULT NULL,
  `father_pic` varchar(200) NOT NULL,
  `mother_name` varchar(50) DEFAULT NULL,
  `mother_phone` varchar(10) DEFAULT NULL,
  `mother_occupation` varchar(20) DEFAULT NULL,
  `mother_email` varchar(100) DEFAULT NULL,
  `mother_pic` varchar(200) NOT NULL,
  `guardian_is` ENUM('Father','Mother','Other') NOT NULL, DEFAULT 'Father',
  `guardian_name` varchar(50) DEFAULT NULL,
  `guardian_relation` varchar(100) DEFAULT NULL,
  `guardian_relationship_proof_id` varchar(50) DEFAULT NULL,  -- for non-biological guardians
  `guardian_phone` varchar(10) DEFAULT NULL,
  `guardian_occupation` varchar(20) NOT NULL,
  `guardian_address` text,
  `guardian_email` varchar(100) DEFAULT NULL,
  `guardian_pic` varchar(200) NOT NULL,
  `previous_school_detail` text,
  `height` varchar(100) NOT NULL,
  `weight` varchar(100) NOT NULL,
  `measurement_date` date DEFAULT NULL,
  `additional_info` json DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_studentDetail_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentDetail_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `zst_student_sessions_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,            -- FK
  `admission_no` VARCHAR(50) NOT NULL,
  `roll_no` INT DEFAULT NULL,
  `admission_date` DATE DEFAULT NULL,
  `registration_no` VARCHAR(50) DEFAULT NULL,
  `default_mobile` ENUM('Father','Mother','Guardian','All') NOT NULL, DEFAULT 'Mother',
  `default_email` ENUM('Father','Mother','Guardian','All') NOT NULL, DEFAULT 'Mother',
  `academic_sessions_id` bigint unsigned NOT NULL,  -- FK - sch_org_academic_sessions_jnt
  `class_section_id` INT UNSIGNED NOT NULL,         -- FK (Instead of selecting Class & Section, we will be using Class+Section)
  `subject_group_id` BIGINT UNSIGNED NOT NULL,      -- FK - sch_subject_groups
  `session_status_id` BIGINT UNSIGNED DEFAULT NULL, -- FK - gl_dropdown_table
  `is_current` TINYINT(1) DEFAULT 1,  -- Only one session can be current at a time for one student
  `current_flag` bigint GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
  `leaving_date` DATE DEFAULT NULL,
  `reason_quit` int NULL,                       -- FK to `gl_dropdown_table`
  `dis_note` text NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`)
  CONSTRAINT `fk_studentSessions_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_academicSession` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_subjGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_sessionStatusId` FOREIGN KEY (`session_status_id`) REFERENCES `gl_dropdown_table` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_reasonQuit` FOREIGN KEY (`reason_quit`) REFERENCES `gl_dropdown_table` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ===============================================================================================================


CREATE TABLE IF NOT EXISTS `tim_teacher_constraint` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  `max_periods_per_week` INT UNSIGNED DEFAULT NULL,
  `max_periods_per_day` INT UNSIGNED DEFAULT NULL,
  `max_days_per_week` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tim_class_sub_group` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `subject_id` BIGINT UNSIGNED NOT NULL,       -- Math, Sci
  `study_format_id` int unsigned NOT NULL,     -- Lecture, Lab
  `class_section_id` int unsigned NOT NULL,
  `short_name` varchar(20) DEFAULT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `total_students` INT UNSIGNED DEFAULT NULL,
  `is_shared_across_classes` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_sub_comb_group_subj_name` (`subject_id`,`group_name`),
  CONSTRAINT `fk_sub_comb_group_subj` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_comb_group_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_period_definitions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(1) NOT NULL,         -- e.g., '1','2','3' and so on (This will be used for Timetable)
  `short_name` VARCHAR(10) NOT NULL,  -- e.g., "Period-1 / P-1,P2"
  `name` VARCHAR(50) NOT NULL,        -- e.g., "Lunch Break, Prayer, Class"
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `is_break` TINYINT(1) DEFAULT 0,
  `sort_order` TINYINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===============================================================================================
-- Module Wise Table
-- ===============================================================================================


-- ------------------------------------------------------------------------------------------------
-- bil_billing_ddl.sql
-- ------------------------------------------------------------------------------------------------
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


-- =====================================================================
-- SYLLABUS MANAGEMENT MODULE - ENHANCED VERSION
-- =====================================================================

CREATE TABLE IF NOT EXISTS `slb_lessons` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,                -- e.g. 'Lesson 1' or 'Chapter 10'
  `code` varchar(7) DEFAULT NULL,             -- e.g. '9th_SCI', '8TH_MAT' (Auto Generate on the basis of Class & Subject Code)
  `class_id` BIGINT UNSIGNED NOT NULL,        -- FK to sch_classes 
  `subject_id` bigint unsigned NOT NULL,      -- FK to sch_subjects  
  `ordinal` tinyint DEFAULT NULL,             -- Sequence order for lessons in a subject for a class 
  `description` text DEFAULT NULL,
  `duration` int unsigned NULL,               -- No of Periods required to complete this lesson
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lesson_class_Subject_name` (`class_id`,'subject_id','name'),
  UNIQUE KEY `uq_lesson_class_Subject_ordinal` (`class_id`,'subject_id',`ordinal`),
  CONSTRAINT `fk_lesson_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lesson_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `slb_topics` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to self (NULL for root topics, set to parent topic_id for sub-topics)
  `lesson_id` INT UNSIGNED NOT NULL,          -- FK -> sch_lessons.id
  `class_id` INT UNSIGNED NOT NULL,           -- FK -> sch_classes.id (redundant for fast queries)
  `subject_id` BIGINT UNSIGNED NOT NULL,      -- FK -> sch_subjects.id (redundant)
  `name` VARCHAR(150) NOT NULL,
  `short_name` VARCHAR(50) DEFAULT NULL,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,   -- order within parent topic or lesson
  `level` TINYINT UNSIGNED NOT NULL DEFAULT 0, -- 0=root topic, 1=sub-topic, 2+=deeper levels (if needed)
  `description` TEXT DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL, -- approximate teaching time
  `learning_objectives` JSON DEFAULT NULL,    -- Array of learning objectives for this topic
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_topic_lesson_parent_name` (`lesson_id`,`parent_id`,`name`),
  KEY `idx_topic_parent_id` (`parent_id`),
  KEY `idx_topic_lesson_id` (`lesson_id`),
  KEY `idx_topic_level` (`level`),
  CONSTRAINT `fk_topic_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `slb_lessons` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_topic_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `slb_competencies` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,   -- FK to sch_classes.id
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `description` TEXT DEFAULT NULL,
  `parent_competency_id` BIGINT UNSIGNED DEFAULT NULL,  -- hierarchical competencies
  `competency_type` VARCHAR(20) NOT NULL,  --FK - Fom Dropdown table  e.g., 'KNOWLEDGE','SKILL','ATTITUDE'
  `nep_alignment` VARCHAR(100) DEFAULT NULL,  -- Reference to NEP 2020 framework
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_comp_code` (`code`,`class_id`,`subject_id`),
  KEY `idx_comp_parent` (`parent_competency_id`),
  CONSTRAINT `fk_comp_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comp_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comp_parent` FOREIGN KEY (`parent_competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Link topics to competencies
CREATE TABLE IF NOT EXISTS `slb_topic_competency_jnt` (
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`topic_id`,`competency_id`),
  CONSTRAINT `fk_tc_topic` FOREIGN KEY (`topic_id`) REFERENCES `slb_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tc_competency` FOREIGN KEY (`competency_id`) REFERENCES `slb_competencies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUESTION TAXONOMIES (NEP / BLOOM etc.) - REFERENCE DATA
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
  `has_options` TINYINT(1) NOT NULL DEFAULT 0,
  `auto_gradable` TINYINT(1) NOT NULL DEFAULT 1, -- Can this type be auto-graded (Can System Marked Automatically?)?
  `description` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtype_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUESTION BANK & QUESTION MANAGEMENT
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_questions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `external_ref` VARCHAR(100) DEFAULT NULL,   -- for mapping to external banks
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,    -- FK -> sch_topics.id (can be root topic or sub-topic depending on level)
  `competency_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sch_competencies.id
  `lesson_id` INT UNSIGNED DEFAULT NULL,      -- optional denormalized FK
  `class_id` INT UNSIGNED DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,  -- sch_users.id or teachers.id
  `question_type_id` INT UNSIGNED NOT NULL,   -- gl_question_types.id
  `stem` TEXT NOT NULL,                       -- full question text (may include placeholders)
  `answer_explanation` TEXT DEFAULT NULL,     -- teacher explanation
  `reference_material` TEXT DEFAULT NULL,     -- e.g., book section, web link
  `marks` DECIMAL(5,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(5,2) DEFAULT 0.00,
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,  -- slb_complexity_level.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,       -- slb_bloom_taxonomy.id
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
  `ques_type_specificity_id` INT UNSIGNED DEFAULT NULL, -- slb_ques_type_specificity.id
  `estimated_time_seconds` INT UNSIGNED DEFAULT NULL, -- avg time to answer
  `tags` JSON DEFAULT NULL,                   -- array of tag strings or ids
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_public` TINYINT(1) NOT NULL DEFAULT 0,  -- share between tenants? keep default 0
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ques_topic` (`topic_id`),
  KEY `idx_ques_competency` (`competency_id`),
  KEY `idx_ques_class_subject` (`class_id`,`subject_id`),
  KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`),
  KEY `idx_ques_active` (`is_active`),
  CONSTRAINT `fk_ques_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_competency` FOREIGN KEY (`competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_type` FOREIGN KEY (`question_type_id`) REFERENCES `gl_question_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ques_complexity` FOREIGN KEY (`complexity_level_id`) REFERENCES `slb_complexity_level` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_bloom` FOREIGN KEY (`bloom_id`) REFERENCES `slb_bloom_taxonomy` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_cog` FOREIGN KEY (`cognitive_skill_id`) REFERENCES `slb_cognitive_skill` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ques_timeSpec` FOREIGN KEY (`ques_type_specificity_id`) REFERENCES `slb_ques_type_specificity` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_question_options` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `option_text` TEXT NOT NULL,
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
  `feedback` TEXT DEFAULT NULL,               -- specific feedback for this option
  `image_url` VARCHAR(255) DEFAULT NULL,      -- if option has an image
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_opt_question` (`question_id`),
  CONSTRAINT `fk_opt_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_question_media` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `media_id` BIGINT UNSIGNED NOT NULL,        -- link to sys_media.id
  `purpose` VARCHAR(50) DEFAULT 'ATTACHMENT', -- e.g., 'IMAGE','AUDIO','VIDEO','ATTACHMENT'
  `ordinal` SMALLINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_qmedia_question` (`question_id`),
  CONSTRAINT `fk_qmedia_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qmedia_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_question_tags` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qtag_short` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_question_tag_jnt` (
  `question_id` BIGINT UNSIGNED NOT NULL,
  `tag_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_id`,`tag_id`),
  CONSTRAINT `fk_qtag_q` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qtag_tag` FOREIGN KEY (`tag_id`) REFERENCES `sch_question_tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUESTION VERSIONING & HISTORY
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT UNSIGNED NOT NULL,
  `version` INT UNSIGNED NOT NULL,
  `data` JSON NOT NULL,                       -- full snapshot of question (stem, options, metadata)
  `change_reason` VARCHAR(255) DEFAULT NULL,  -- why was this version created?
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_qver_q_v` (`question_id`,`version`),
  CONSTRAINT `fk_qver_q` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUESTION POOLS & ADAPTIVE SELECTION
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_pools` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `complexity_filter` JSON DEFAULT NULL,      -- ["EASY","MEDIUM","DIFFICULT"]
  `bloom_filter` JSON DEFAULT NULL,           -- ["REMEMBER","UNDERSTAND","APPLY"]
  `cognitive_filter` JSON DEFAULT NULL,       -- Filter by cognitive skills
  `ques_type_specificity_filter` JSON DEFAULT NULL, -- e.g., ["IN_CLASS","HOMEWORK"]
  `min_questions` INT UNSIGNED DEFAULT NULL,  -- Minimum pool size
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_qpool_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpool_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_question_pool_questions` (
  `question_pool_id` BIGINT UNSIGNED NOT NULL,
  `question_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`question_pool_id`,`question_id`),
  CONSTRAINT `fk_qpq_pool` FOREIGN KEY (`question_pool_id`) REFERENCES `sch_question_pools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qpq_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUIZZES, ASSESSMENTS & EXAMS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_quizzes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `lesson_id` INT UNSIGNED DEFAULT NULL,
  `quiz_type` ENUM('PRACTICE','DIAGNOSTIC','REINFORCEMENT') DEFAULT 'PRACTICE',
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_answers_immediately` TINYINT(1) DEFAULT 1,
  `allow_review_before_submit` TINYINT(1) DEFAULT 1,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quiz_subject_class` (`subject_id`,`class_id`),
  CONSTRAINT `fk_quiz_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_quiz_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `sch_lessons` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_assessments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` ENUM('FORMATIVE','SUMMATIVE','TERM','DIAGNOSTIC') NOT NULL DEFAULT 'FORMATIVE',
  `description` TEXT DEFAULT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_org_academic_sessions_jnt
  `start_datetime` DATETIME DEFAULT NULL,
  `end_datetime` DATETIME DEFAULT NULL,
  `duration_minutes` INT UNSIGNED DEFAULT NULL,
  `total_marks` DECIMAL(7,2) DEFAULT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `negative_marking_enabled` TINYINT(1) DEFAULT 0,
  `show_answers_after_exam` TINYINT(1) DEFAULT 0,
  `show_answers_on_date` DATE DEFAULT NULL,
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `allow_review_before_submit` TINYINT(1) DEFAULT 1,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_assess_subject_class` (`subject_id`,`class_id`),
  KEY `idx_assess_type` (`type`),
  CONSTRAINT `fk_assess_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_assess_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_assess_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_exams` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `short_name` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `exam_type` ENUM('UNIT','MIDTERM','FINAL','BOARD','COMPETITIVE','MOCK') NOT NULL,
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL,
  `academic_session_id` BIGINT UNSIGNED DEFAULT NULL,
  `scheduled_date` DATE NOT NULL,
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `duration_minutes` INT UNSIGNED NOT NULL,
  `total_marks` DECIMAL(7,2) NOT NULL,
  `passing_marks` DECIMAL(7,2) DEFAULT NULL,
  `negative_marking_enabled` TINYINT(1) DEFAULT 0,
  `show_answers_after_exam` TINYINT(1) DEFAULT 0,
  `show_answers_on_date` DATE DEFAULT NULL,
  `shuffle_questions` TINYINT(1) DEFAULT 0,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `allow_review_before_submit` TINYINT(1) DEFAULT 0,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_exam_date_class` (`scheduled_date`,`class_id`),
  KEY `idx_exam_type` (`exam_type`),
  CONSTRAINT `fk_exam_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exam_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exam_academic_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- ASSESSMENT SECTIONS (for multi-part exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_sections` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,   -- FK to sch_assessments or sch_exams
  `section_name` VARCHAR(100) NOT NULL,       -- e.g., "Part A: Reading", "Part B: Writing"
  `ordinal` TINYINT UNSIGNED NOT NULL,
  `description` TEXT DEFAULT NULL,
  `section_marks` DECIMAL(7,2) DEFAULT NULL, -- total marks for this section
  `instructions` TEXT DEFAULT NULL,           -- special instructions for this section
  `shuffle_questions` TINYINT(1) DEFAULT 0,   -- randomize question order per student
  PRIMARY KEY (`id`),
  KEY `idx_section_assessment` (`assessment_id`),
  CONSTRAINT `fk_section_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- ASSESSMENT ITEMS (Questions in Quizzes/Assessments/Exams)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,   -- FK to sch_assessments
  `section_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_assessment_sections (for multi-part exams)
  `question_id` BIGINT UNSIGNED NOT NULL,
  `marks` DECIMAL(6,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(6,2) DEFAULT 0.00,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_answer_explanation` TINYINT(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_ai_assessment` (`assessment_id`),
  KEY `idx_ai_section` (`section_id`),
  CONSTRAINT `fk_ai_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_section` FOREIGN KEY (`section_id`) REFERENCES `sch_assessment_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_exam_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,         -- FK to sch_exams
  `section_id` BIGINT UNSIGNED DEFAULT NULL,  -- Can be extended to support exam sections
  `question_id` BIGINT UNSIGNED NOT NULL,
  `marks` DECIMAL(6,2) DEFAULT 1.00,
  `negative_marks` DECIMAL(6,2) DEFAULT 0.00,
  `ordinal` SMALLINT UNSIGNED DEFAULT NULL,
  `shuffle_options` TINYINT(1) DEFAULT 0,
  `show_answer_explanation` TINYINT(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_ei_exam` (`exam_id`),
  CONSTRAINT `fk_ei_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ei_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_quiz_assessment_map` (
  `quiz_id` BIGINT UNSIGNED NOT NULL,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`quiz_id`,`assessment_id`),
  CONSTRAINT `fk_qam_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `sch_quizzes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_qam_assess` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- ASSESSMENT ASSIGNMENT & RULES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_assessment_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `assigned_to_type` ENUM('CLASS_SECTION','STUDENT','SUBJECT_GROUP','TEACHER') NOT NULL,
  `assigned_to_id` BIGINT UNSIGNED NOT NULL,  -- id of class_section / student / subject_group / teacher
  `available_from` DATETIME DEFAULT NULL,
  `available_to` DATETIME DEFAULT NULL,
  `max_attempts` INT UNSIGNED DEFAULT 1,
  `is_visible` TINYINT(1) DEFAULT 1,
  `created_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_asg_assessment` (`assessment_id`),
  KEY `idx_asg_visibility` (`is_visible`,`available_from`,`available_to`),
  CONSTRAINT `fk_asg_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_assessment_assignment_rules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `rule_type` ENUM('ATTENDANCE_MIN','SCORE_MIN','TIME_WINDOW','DEVICE_TYPE','IP_RESTRICTED','PREREQUISITE_COMPLETION') NOT NULL,
  `rule_value` JSON NOT NULL,                 -- e.g., {"min_attendance": 75}, {"allowed_ips": ["192.168.1.0/24"]}
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_aar_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- STUDENT ATTEMPTS & RESPONSES (GRADING)
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,      -- IPv4 or IPv6
  `user_agent` VARCHAR(255) DEFAULT NULL,     -- Browser info for audit
  `started_at` DATETIME DEFAULT NULL,
  `submitted_at` DATETIME DEFAULT NULL,
  `status` ENUM('IN_PROGRESS','SUBMITTED','GRADED','CANCELLED') NOT NULL DEFAULT 'IN_PROGRESS',
  `total_marks_obtained` DECIMAL(8,2) DEFAULT 0.00,
  `percentage_score` DECIMAL(5,2) DEFAULT 0.00,
  `evaluated_by` BIGINT UNSIGNED DEFAULT NULL,
  `evaluated_at` DATETIME DEFAULT NULL,
  `attempt_number` INT UNSIGNED DEFAULT 1,
  `time_taken_seconds` INT UNSIGNED DEFAULT NULL,
  `total_questions_attempted` INT UNSIGNED DEFAULT 0,
  `total_questions_correct` INT UNSIGNED DEFAULT 0,
  `notes` TEXT DEFAULT NULL,                  -- evaluator notes
  PRIMARY KEY (`id`),
  KEY `idx_att_assessment_student` (`assessment_id`,`student_id`),
  KEY `idx_att_student_status` (`student_id`,`status`),
  KEY `idx_att_submitted` (`submitted_at`),
  CONSTRAINT `fk_att_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `sch_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_attempt_answers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `attempt_id` BIGINT UNSIGNED NOT NULL,
  `assessment_item_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sch_assessment_items.id
  `question_id` BIGINT UNSIGNED NOT NULL,
  `selected_option_ids` JSON DEFAULT NULL,    -- for MCQ multi-select: array of option ids
  `answer_text` TEXT DEFAULT NULL,            -- for short/long answers, code, numeric answers etc.
  `marks_awarded` DECIMAL(7,2) DEFAULT 0.00,
  `is_correct` TINYINT(1) DEFAULT NULL,
  `grader_note` TEXT DEFAULT NULL,
  `answered_at` DATETIME DEFAULT NULL,
  `time_taken_seconds` INT UNSIGNED DEFAULT NULL,
  `review_count` TINYINT UNSIGNED DEFAULT 0,  -- how many times reviewed before submission
  PRIMARY KEY (`id`),
  KEY `idx_aa_attempt` (`attempt_id`),
  KEY `idx_aa_question` (`question_id`),
  CONSTRAINT `fk_aa_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `sch_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_aa_item` FOREIGN KEY (`assessment_item_id`) REFERENCES `sch_assessment_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_aa_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- STUDENT LEARNING OUTCOMES & COMPETENCY TRACKING
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_student_learning_outcomes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `competency_id` BIGINT UNSIGNED NOT NULL,
  `topic_id` BIGINT UNSIGNED NOT NULL,
  `class_id` INT UNSIGNED NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `bloom_level` VARCHAR(50) DEFAULT NULL,     -- from questions attempted
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `correct_attempts` INT UNSIGNED DEFAULT 0,
  `last_attempt_date` DATE DEFAULT NULL,
  `mastery_status` ENUM('NOT_STARTED','IN_PROGRESS','PROFICIENT','MASTERED') DEFAULT 'NOT_STARTED',
  `progress_percentage` DECIMAL(5,2) DEFAULT 0,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slo_student_competency_topic` (`student_id`,`competency_id`,`topic_id`),
  KEY `idx_slo_student` (`student_id`),
  KEY `idx_slo_mastery` (`mastery_status`),
  CONSTRAINT `fk_slo_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_competency` FOREIGN KEY (`competency_id`) REFERENCES `sch_competencies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_topic` FOREIGN KEY (`topic_id`) REFERENCES `sch_topics` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_slo_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- QUESTION & EXAM ANALYTICS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_analytics` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `total_attempts` INT UNSIGNED DEFAULT 0,
  `correct_attempts` INT UNSIGNED DEFAULT 0,
  `avg_time_seconds` INT UNSIGNED DEFAULT NULL,
  `discrimination_index` DECIMAL(4,3) DEFAULT NULL,  -- (correct top 27% - correct bottom 27%) / group_size
  `difficulty_index` DECIMAL(4,3) DEFAULT NULL,      -- total_correct / total_attempts
  `discrimination_status` VARCHAR(20) DEFAULT NULL,   -- 'GOOD','FAIR','POOR'
  `last_used` DATE DEFAULT NULL,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_qa_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_exam_analytics` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `exam_id` BIGINT UNSIGNED NOT NULL,
  `total_students_assigned` INT UNSIGNED DEFAULT 0,
  `total_students_attempted` INT UNSIGNED DEFAULT 0,
  `avg_score_percent` DECIMAL(5,2) DEFAULT NULL,
  `highest_score` DECIMAL(8,2) DEFAULT NULL,
  `lowest_score` DECIMAL(8,2) DEFAULT NULL,
  `pass_count` INT UNSIGNED DEFAULT 0,
  `fail_count` INT UNSIGNED DEFAULT 0,
  `pass_percentage` DECIMAL(5,2) DEFAULT NULL,
  `standard_deviation` DECIMAL(8,2) DEFAULT NULL,
  `question_difficulty_avg` DECIMAL(4,3) DEFAULT NULL,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ea_exam` FOREIGN KEY (`exam_id`) REFERENCES `sch_exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- AUDIT & CHANGE LOG
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `table_name` VARCHAR(50) NOT NULL,
  `record_id` BIGINT UNSIGNED NOT NULL,
  `action` ENUM('CREATE','UPDATE','DELETE','PUBLISH','GRADE','SUBMIT') NOT NULL,
  `changed_by` BIGINT UNSIGNED DEFAULT NULL,
  `old_values` JSON DEFAULT NULL,
  `new_values` JSON DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_table_record` (`table_name`,`record_id`),
  KEY `idx_audit_action` (`action`),
  KEY `idx_audit_timestamp` (`timestamp`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- MATERIALIZED VIEW FOR FAST QUERIES
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `sch_question_index` (
  `question_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `class_id` INT UNSIGNED DEFAULT NULL,           -- sch_classes.id
  `subject_id` BIGINT UNSIGNED DEFAULT NULL,      -- sch_subjects.id
  `lesson_id` INT UNSIGNED DEFAULT NULL,          -- denormalized for faster filtering
  `topic_id` BIGINT UNSIGNED DEFAULT NULL,        -- sch_topics.id
  `competency_id` BIGINT UNSIGNED DEFAULT NULL,   -- sch_competencies.id
  `complexity_level_id` INT UNSIGNED DEFAULT NULL,      -- slb_complexity_level.id
  `bloom_id` INT UNSIGNED DEFAULT NULL,           -- slb_bloom_taxonomy.id
  `cognitive_skill_id` INT UNSIGNED DEFAULT NULL, -- slb_cognitive_skill.id
  `question_type_id` INT UNSIGNED DEFAULT NULL,   -- gl_question_types.id
  `marks` DECIMAL(5,2) DEFAULT NULL,              -- marks allocated
  `negative_marks` DECIMAL(5,2) DEFAULT NULL,     -- negative marks
  `estimated_time_seconds` INT UNSIGNED DEFAULT NULL,  -- estimated time to answer
  `tags` JSON DEFAULT NULL,                       -- array of tag strings or ids
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_qi_class_subject` (`class_id`,`subject_id`),
  KEY `idx_qi_complexity` (`complexity_level_id`),
  KEY `idx_qi_bloom` (`bloom_id`),
  CONSTRAINT `fk_qi_question` FOREIGN KEY (`question_id`) REFERENCES `sch_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- ======================================================================================
-- TRANSPORT MODULE
-- ======================================================================================

-- -------------------------------------------------------------------------
-- VEHICLE, DRIVER, HELPER, SHIFT
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,
    `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
    `model` VARCHAR(50),                            -- Vehicle model
    `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
    `vehicle_type` VARCHAR(20) NOT NULL,            -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type` VARCHAR(20) NOT NULL,               -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
    `ownership_type` VARCHAR(20) NOT NULL,          -- fk to sys_dropdown_table ('Owned','Leased','Rented')
    `fitness_valid_upto` DATE,                      -- Fitness certificate expiry date
    `insurance_valid_upto` DATE,                    -- Insurance expiry date
    `pollution_valid_upto` DATE,                    -- Pollution certificate expiry date
    `gps_device_id` VARCHAR(50),                    -- Installed GPS device identifier
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,         -- e.g., 'Aadhaar','Passport','DriverLicense'
    `id_no` VARCHAR(100) DEFAULT NULL,          -- Govt issued ID number
    `role` VARCHAR(20) NOT NULL,                -- fk to sys_role ('Driver','Helper','Conductor')
    `license_no` VARCHAR(50) DEFAULT NULL,      -- Driver's license number
    `license_valid_upto` DATE DEFAULT NULL,                 -- License expiry date
    `assigned_vehicle_id` BIGINT UNSIGNED DEFAULT NULL,     -- fk to tpt_vehicle
    `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,    -- Total driving experience in months
    `address` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_shift` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `effective_from` DATE NOT NULL,     --  Shift validity period
    `effective_to` DATE NOT NULL,       --  Shift validity period
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_shift_code` (`code`),
    UNIQUE KEY `uq_shift_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- ROUTES & STOPS with SRID=4326
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_route` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` BIGINT UNSIGNED NOT NULL,        -- fk to tpt_shift
    `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,     -- WGS84 route path
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_route_code` (`code`),
    UNIQUE KEY `uq_route_name` (`name`),
    SPATIAL INDEX `sp_idx_route_geometry` (`route_geometry`),
    CONSTRAINT `fk_route_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,      -- WGS84 latitude
    `longitude` DECIMAL(10,7) DEFAULT NULL,     -- WGS84 longitude
    `location` POINT NOT NULL SRID 4326,        -- WGS84 spatial point
    `total_distance` DECIMAL(7,2) DEFAULT NULL, -- Distance from route start in KM
    `estimated_time` INT DEFAULT NULL,          -- Estimated time from route start in minutes
    `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickup_code` (`code`),
    UNIQUE KEY `uq_pickup_name` (`name`),
    SPATIAL INDEX `sp_idx_pickup_location` (`location`),
    CONSTRAINT `fk_pickupPoint_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `pickup_point_id` BIGINT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickupPointRoute_shift_pickupPoint` (`shift_id`,`pickup_point_id`,`route_id`),
    KEY `idx_pprj_route_ordinal` (`route_id`, `ordinal`),
    CONSTRAINT `fk_pickupPointRoute_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pickupPointRoute_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pickupPointRoute_pickupPointId` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- ROUTE SCHEDULE & DRIVER ASSIGNMENT
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_routeVehicle_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_vehicleId` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_driverId` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_helperId` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Prevent overlapping assignments for same vehicle/driver on same shift+route should be enforced at app or via triggers
CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scheduled_date` DATE NOT NULL,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `driver_id` BIGINT UNSIGNED DEFAULT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sched_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- TRIPS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_trip` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,
    `pickup_route_id` BIGINT UNSIGNED DEFAULT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `trip_type` ENUM('Morning','Afternoon','Evening','Custom') DEFAULT 'Morning',
    `start_time` DATETIME DEFAULT NULL,
    `end_time` DATETIME DEFAULT NULL,
    `status` ENUM('Scheduled','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_trip_route_sched` (`route_id`, `trip_date`),
    KEY `idx_trip_vehicle` (`vehicle_id`),
    CONSTRAINT `fk_trip_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- LIVE TRIP STATUS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_live_trip` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `current_stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `eta` DATETIME DEFAULT NULL,
    `reached_flag` TINYINT(1) NOT NULL DEFAULT 0,
    `emergency_flag` TINYINT(1) DEFAULT 0,
    `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_live_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_live_current_stop` FOREIGN KEY (`current_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- DRIVER ATTENDANCE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_out_time` DATETIME DEFAULT NULL,
    `geo_lat` DECIMAL(10,7) DEFAULT NULL,       -- Location of check-in
    `geo_lng` DECIMAL(10,7) DEFAULT NULL,       -- Location of check-in
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,    -- 1=App, 0=Manual
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_da_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- STUDENT ALLOCATION
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_student_allocation_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `pickup_stop_id` BIGINT UNSIGNED NOT NULL,
    `drop_stop_id` BIGINT UNSIGNED NOT NULL,
    `fare` DECIMAL(10,2) NOT NULL,
    `effective_from` DATE NOT NULL,
    `active_status` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sa_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- TRANSPORT FEE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_fee_master` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `session_id` BIGINT UNSIGNED NOT NULL,
    `month` TINYINT NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_fee_collection` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_allocation_id` BIGINT UNSIGNED NOT NULL,
    `fee_master_id` BIGINT UNSIGNED NOT NULL,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_date` DATE NOT NULL,
    `payment_mode` ENUM('Cash','UPI','Card','Bank','Cheque') NOT NULL,
    `status` ENUM('Paid','Partial','Pending') NOT NULL DEFAULT 'Paid',
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_fc_allocation` FOREIGN KEY (`student_allocation_id`) REFERENCES `tpt_student_allocation_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fc_master` FOREIGN KEY (`fee_master_id`) REFERENCES `tpt_fee_master`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- ML / FEATURE STORE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `ml_models` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(200) NOT NULL,
    `version` VARCHAR(50) NOT NULL,
    `model_type` VARCHAR(50) DEFAULT NULL,
    `artifact_uri` VARCHAR(1024) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `metrics` JSON DEFAULT NULL,
    `status` ENUM('TRAINED','DEPLOYED','DEPRECATED') DEFAULT 'TRAINED',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ml_model_name_version` (`name`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ml_model_features` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` BIGINT UNSIGNED NOT NULL,
    `feature_name` VARCHAR(200) NOT NULL,
    `feature_type` VARCHAR(50) DEFAULT NULL,
    `transformation` JSON DEFAULT NULL,
    CONSTRAINT `fk_mmf_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_feature_store` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `feature_date` DATE NOT NULL,
    `route_id` BIGINT UNSIGNED DEFAULT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `feature_vector` JSON NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_feature_date_route` (`feature_date`, `route_id`),
    CONSTRAINT `fk_fs_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fs_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_model_recommendations` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` BIGINT UNSIGNED NOT NULL,
    `model_version` VARCHAR(50) DEFAULT NULL,
    `run_id` VARCHAR(100) DEFAULT NULL,
    `generated_for_date` DATE DEFAULT NULL,
    `route_id` BIGINT UNSIGNED DEFAULT NULL,
    `recommended_path` LINESTRING SRID 4326 DEFAULT NULL,
    `predicted_time_minutes` INT DEFAULT NULL,
    `predicted_distance_km` DECIMAL(7,2) DEFAULT NULL,
    `confidence` DECIMAL(5,4) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    SPATIAL INDEX `sp_idx_recommended_path` (`recommended_path`),
    CONSTRAINT `fk_mr_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mr_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_recommendation_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `recommendation_id` BIGINT UNSIGNED NOT NULL,
    `applied_at` DATETIME DEFAULT NULL,
    `applied_by` BIGINT UNSIGNED DEFAULT NULL,
    `outcome` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_rh_recommendation` FOREIGN KEY (`recommendation_id`) REFERENCES `tpt_model_recommendations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- STUDENT BOARD/ALIGHT EVENTS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_student_event_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED DEFAULT NULL,
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
    `stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `event_type` ENUM('BOARD','ALIGHT') NOT NULL,
    `recorded_at` DATETIME NOT NULL,
    `device_id` VARCHAR(200) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sel_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sel_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- TRIP INCIDENTS & ALERTS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `incident_type` VARCHAR(100) NOT NULL,
    `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `recorded_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- GPS LOGS - CRITICAL TELEMETRY TABLE
-- Heavy table: Composite index on (trip_id, log_time) and (vehicle_id, log_time)
-- Spatial index on location (SRID 4326). NO PARTITION by request (add later via ALTER).
-- Recommended: stream to object storage (S3), curate time-window data here.
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `log_time` DATETIME NOT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `location` POINT NOT NULL SRID 4326,
    `speed` DECIMAL(6,2) DEFAULT NULL,
    `ignition_status` TINYINT(1) DEFAULT NULL,
    `deviation_flag` TINYINT(1) DEFAULT 0,
    `raw_payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_gps_trip_time` (`trip_id`, `log_time`),
    KEY `idx_gps_vehicle_time` (`vehicle_id`, `log_time`),
    SPATIAL INDEX `sp_idx_gps_location` (`location`),
    CONSTRAINT `fk_gps_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_gps_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCTION NOTE: Partition this table by month or week after deployment
-- Example (run only after data is in place):
-- ALTER TABLE tpt_gps_trip_log PARTITION BY RANGE (YEAR(log_time)*100 + MONTH(log_time))
-- (PARTITION p202401 VALUES LESS THAN (202402),
--  PARTITION p202402 VALUES LESS THAN (202403),
--  PARTITION p_future VALUES LESS THAN MAXVALUE);

CREATE TABLE IF NOT EXISTS `tpt_gps_alerts` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `alert_type` ENUM('Overspeed','Idle','RouteDeviation','GeofenceBreach') NOT NULL,
    `log_time` DATETIME NOT NULL,
    `message` VARCHAR(512) NOT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_gps_alerts_vehicle` (`vehicle_id`, `log_time`),
    CONSTRAINT `fk_gps_alert_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- FUEL & MAINTENANCE
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `fuel_type` ENUM('Diesel','Petrol','CNG','Electric') NOT NULL,
    `odometer_reading` BIGINT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `maintenance_type` VARCHAR(120) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `workshop_details` VARCHAR(512) DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vm_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- NOTIFICATIONS & LOGS
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_notification_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
    `trip_id` BIGINT UNSIGNED DEFAULT NULL,
    `stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `notification_type` ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') DEFAULT NULL,
    `sent_time` DATETIME DEFAULT NULL,
    `status` ENUM('Sent','Failed') NOT NULL DEFAULT 'Sent',
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_nl_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------------------------------
-- AUDIT & MIGRATION TRACKING
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tpt_audit_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity` VARCHAR(128) NOT NULL,
    `entity_id` BIGINT UNSIGNED DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `performed_by` VARCHAR(128) DEFAULT NULL,
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_data_migration_jobs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `job_key` VARCHAR(128) NOT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Pending','Running','Completed','Failed') NOT NULL DEFAULT 'Pending',
    `started_at` DATETIME DEFAULT NULL,
    `finished_at` DATETIME DEFAULT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- END OF SCRIPT
-- =======================================================================  
