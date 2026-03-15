
-- Global Master
-- -------------

-- All type of Menu (Category, Main Menu, Sub-Menu) will be in single Table
CREATE TABLE IF NOT EXISTS `glb_menus` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` INT unsigned DEFAULT NULL,     -- FK
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
  CONSTRAINT `chk_is_category_parentId` CHECK ((((`is_category` = 1) and (`parent_id` is null)) or (`is_category` = 0)))
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- Removed Fields - default_timezone
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
  UNIQUE KEY `uq_countries_name` (`name`),
  KEY `idx_country_active` (`is_active`)
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
  CONSTRAINT `chk_districts_stateId` FOREIGN KEY (`state_id`) REFERENCES `glb_states` (`id`) ON DELETE RESTRICT
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



CREATE TABLE IF NOT EXISTS `glb_permissions` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
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

CREATE TABLE IF NOT EXISTS `glb_roles` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `short_name` VARCHAR(20) NOT NULL,  -- This will be used for dropdown
  `description` VARCHAR(255) NULL,
  `guard_name` varchar(255) NOT NULL,
  `is_system`  TINYINT(1) NOT NULL DEFAULT 0, -- if true, role belongs to PG for system-management
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_name_guardName` (`name`,`guard_name`)
  UNIQUE KEY `uq_roles_name_guardName` (`short_name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_role_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `role_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`role_id`),
  KEY `idx_roleHasPermissions_roleId` (`role_id`),
  CONSTRAINT `fk_roleHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `glb_permissions` (`id`) ON DELETE CASCADE,  -- ON DELETE RESTRICT
  CONSTRAINT `fk_roleHasPermissions_roleId` FOREIGN KEY (`role_id`) REFERENCES `glb_roles` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_model_has_permissions_jnt` (
  `permission_id` INT unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,  -- Edited Width from 255 to 190
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  KEY `idx_modelHasPermissions_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_odelHasPermissions_permissionId` FOREIGN KEY (`permission_id`) REFERENCES `glb_permissions` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_model_has_roles_jnt` (
  `role_id` INT unsigned NOT NULL,
  `model_type` varchar(190) NOT NULL,  -- Edited Width from 255 to 190
  `model_id` INT unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  KEY `idx_modelHasRoles_modelId_modelType` (`model_id`,`model_type`),
  CONSTRAINT `fk_modelHasRoles_roleId` FOREIGN KEY (`role_id`) REFERENCES `glb_roles` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_academic_sessions` (
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
  UNIQUE KEY `uq_board_name` (`name`),
  UNIQUE KEY `uq_board_shortName` (`short_name`),
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_billing_cycles` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `short_name` VARCHAR(50) NOT NULL,  -- 'MONTHLY','QUARTERLY','YEARLY','ONE_TIME'
  `name` VARCHAR(50) NOT NULL,
  `months_count` TINYINT UNSIGNED NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY `uq_billingCycles_code` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Updated CONSTRAINT chk_isSubModule_parentId. Old one was in-correct
-- -------------------------------------------------------------------
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

CREATE TABLE IF NOT EXISTS `glb_plans` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(20) NOT NULL,
  `version` int unsigned NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL,
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
  UNIQUE KEY `uq_plans_planCode_version` (`plan_code`,`version`),
  CONSTRAINT `fk_plans_billingCycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `glb_billing_cycles` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_module_plan_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` INT unsigned NOT NULL,
  `module_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) unsigned NOT NULL,  -- Added Newly
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_modulePlan_moduleId` FOREIGN KEY (`module_id`) REFERENCES `glb_modules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_modulePlan_planId` FOREIGN KEY (`plan_id`) REFERENCES `glb_plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `sch_org_groups` (
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
  UNIQUE KEY `uq_orgGroups_shortName` (`short_name`),
  CONSTRAINT `fk_orgGroups_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_organizations` (
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
  CONSTRAINT `fk_organizations_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_organizations_orgGroupId` FOREIGN KEY (`org_group_id`) REFERENCES `sch_org_groups` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_organization_details` (
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
  UNIQUE KEY `uq_orgDetail_orgId` (`org_id`),
  CONSTRAINT `fk_orgDetail_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_org_academic_sessions_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `academic_sessions_id` INT unsigned NOT NULL,  -- Added New
  `short_name` varchar(10) NOT NULL,
  `name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `org_id` else NULL end)) STORED,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgAcademicSession_orgId_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_orgAcademicSession_currentFlag` (`current_flag`),
  CONSTRAINT `fk_orgAcademicSession_sessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `glb_academic_sessions` (`id`) ON DELETE CASCADE,  -- Added New
  CONSTRAINT `fk_orgAcademicSession_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE  -- ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_board_organization_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `org_academic_sessions_id` INT unsigned NOT NULL,  -- Added New
  `board_id` INT unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_boardOrg_boardId` FOREIGN KEY (`board_id`) REFERENCES `glb_boards` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_boardOrg_academicSessionId` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,  -- Added New
  CONSTRAINT `fk_boardOrg_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_org_role_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT UNSIGNED NOT NULL,    -- which school owns this role
  `role_id` INT UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgRole_orgId_roleId` (`org_id`,`role_id`),
  CONSTRAINT `fk_orgRole_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_organization_plan_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `plan_id` INT unsigned NOT NULL,
  `is_subscribed` tinyint(1) NOT NULL DEFAULT '1',
  `is_trial` tinyint(1) NOT NULL DEFAULT '0',
  `auto_renew` tinyint(1) NOT NULL DEFAULT '1',
  `status` enum('ACTIVE','SUSPENDED','CANCELED','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `current_flag` int GENERATED ALWAYS AS ((case when (`is_subscribed` = 1) then `org_id` else NULL end)) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgPlan_currentFlag_planId` (`current_flag`,`plan_id`),
  CONSTRAINT `fk_orgPlan_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_orgPlan_planId` FOREIGN KEY (`plan_id`) REFERENCES `glb_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_organization_plan_rates` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `organization_plan_id` INT unsigned NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
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
  `credit_days`  SMALLINT UNSIGNED NOT NULL,  -- Added new
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgPlanRates_orgPlanId_startDate_endDate` (`organization_plan_id`,`start_date`,`end_date`),
  CONSTRAINT `fk_orgPlanRates_billingCycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `glb_billing_cycles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_orgPlanRates_orgPlanId` FOREIGN KEY (`organization_plan_id`) REFERENCES `sch_organization_plan_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notes - 'module_organization_plan' may have only 1 record for each 'sch_organization_plan_jnt'
CREATE TABLE IF NOT EXISTS `sch_module_organization_plan_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `module_id` INT unsigned NOT NULL,
  `organization_plan_id` INT unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_moduleOrgPlan_moduleId` FOREIGN KEY (`module_id`) REFERENCES `glb_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_moduleOrgPlan_organizationPlanId` FOREIGN KEY (`organization_plan_id`) REFERENCES `sch_organization_plan_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_classes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class 10'
  `short_name` varchar(10) DEFAULT NULL,      -- e.g. 'G1' or '10A'
  `ordinal` tinyint DEFAULT NULL,        -- This is signed tinyint to have (-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12)
  `code` CHAR(3) NOT NULL,         -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classes_orgId_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_classes_orgId_code` (`org_id`, `code`),
  UNIQUE KEY `uq_classes_orgId_name` (`org_id`,`name`),
  UNIQUE KEY `uq_classes_orgId_ordinal` (`org_id`,`ordinal`),
  CONSTRAINT `fk_classes_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_sections` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `name` varchar(20) NOT NULL,            -- e.g. 'A', 'B'
  `ordinal` tinyint unsigned DEFAULT 1,   -- will have sequence order for Sections
  `code` CHAR(1) NOT NULL,         -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sections_orgId_name` (`org_id`,`name`),
  UNIQUE KEY `uq_sections_orgId_code` (`org_id`, `code`),
  UNIQUE KEY `uq_sections_orgId_ordinal` (`org_id`,`ordinal`),
  CONSTRAINT `fk_sections_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,    -- fk
  `class_id` int unsigned NOT NULL,     -- fk
  `section_id` int unsigned NOT NULL,   -- fk
  `class_secton_code` char(5) NOT NULL,       -- Combination of class Code + section Code i.e. '8th_A', '10h_B'  
  `capacity` tinyint unsigned DEFAULT NULL,        -- Targeted / Planned Quantity of stundets in Each Sections of every class.
  `total_student` tinyint unsigned DEFAULT NULL,   -- Actual Number of Student in the Class+Section
  `class_teacher_id` INT unsigned NOT NULL,     -- fk
  `assistance_class_teacher_id` INT unsigned NOT NULL,  -- fk  
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classSection_orgId_classId_sectionId` (`org_id`,`class_id`,`section_id`),
  UNIQUE KEY `uq_lassSection_orgId_code` (`org_id`,`class_secton_code`),
  CONSTRAINT `fk_classSection_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_classSection_sclassTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_classSection_AssClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sch_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=300 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_org_invoicing` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_id` INT UNSIGNED NOT NULL,                -- fk
  `invoice_no` VARCHAR(50) NOT NULL,     -- Should be Auto-Generated
  `invoice_date` DATE NOT NULL,          -- Invoice Date will always be Next Day to billing_end_date
  `billing_start_date` DATE NOT NULL,
  `billing_end_date` DATE NOT NULL,
  `min_billing_qty` int unsigned NOT NULL DEFAULT '1',    -- No of Lincenses (if Student count < Min_Qty then min_qty will be charged))
  `total_user_qty` int unsigned NOT NULL DEFAULT '1',     -- Number of licenses used by Org in the billing period
  `invoice_amount` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `paid_amount` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `status` ENUM('PENDING','PARTIAL','PAID','OVERDUE','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `credit_days`  SMALLINT UNSIGNED NOT NULL,  -- This will be used to calculat Due Date
  `payment_due_date` DATE NOT NULL,           -- Bill Date + credit_days
  `is_recurring` TINYINT(1) NOT NULL DEFAULT 1,
  `auto_renew` TINYINT(1) NOT NULL DEFAULT 1,
  `remarks` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_orgInvoicing_invoiceNo` (`invoice_no`),
  CONSTRAINT `fk_orgInvoicing_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note - If an Organization has subscription for multipal plans then 'bil_invoicing_items' will have multipal record
-- (1 records for every subscription for every billing) but 'bil_organization_invoicing' will have single entry / month
CREATE TABLE IF NOT EXISTS `bil_org_invoicing_items` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_invoicing_id` INT UNSIGNED NOT NULL,      -- FK
  `organization_plan_id` INT UNSIGNED NOT NULL,  -- FK 
  `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,    -- FK
  `plan_rate` decimal(12,2) NOT NULL,               -- applicable plan rate as per school aggrement
  `billing_qty` int unsigned NOT NULL DEFAULT '1',  -- Billing Qty. will be either `min_billing_qty` or `total_license_qty`, whcihcever is higher)
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
  `net_payable_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,   -- 
  CONSTRAINT `fk_orgInvoicingItems_orgInvoicingId` FOREIGN KEY (`org_invoicing_id`) REFERENCES `bil_org_invoicing` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_orgInvoicingItems_orgPlanId` FOREIGN KEY (`organization_plan_id`) REFERENCES `sch_organization_plan_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orgInvoicingItems_cycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `glb_billing_cycles` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_org_invoicing_modules_jnt` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_invoicing_id` INT UNSIGNED NOT NULL,   -- FK
  `module_id` INT UNSIGNED DEFAULT NULL,      -- FK
  UNIQUE KEY `uq_orgInvoicingModule_orgInvoicingId_moduleId` (`org_invoicing_id`, `module_id`),
  CONSTRAINT `fk_orgInvoicingModule_invoicingId` FOREIGN KEY (`org_invoicing_id`) REFERENCES `bil_org_invoicing` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orgInvoicingModule_moduleId` FOREIGN KEY (`module_id`) REFERENCES `glb_modules` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_org_invoicing_payments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_invoicing_id` INT UNSIGNED NOT NULL,    -- fk
  `payment_date` DATE NOT NULL,
  `transaction_id` VARCHAR(100) DEFAULT NULL,
  `mode` ENUM('ONLINE','BANK_TRANSFER','CASH','CHEQUE','UPI','OTHERS') DEFAULT 'ONLINE',
  `mode_other` VARCHAR(20) DEFAULT NULL,
  `amount_paid` DECIMAL(14,2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `payment_status` ENUM('INITIATED','SUCCESS','FAILED','REFUNDED') DEFAULT 'SUCCESS',
  `gateway_response` JSON DEFAULT NULL,
  `payment_reconciled` tinyint(1) NOT NULL DEFAULT '0',
  `remarks` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_orgInvocingPayment_orgInvoicingId` FOREIGN KEY (`org_invoicing_id`) REFERENCES `bil_org_invoicing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note - Below table 
CREATE TABLE IF NOT EXISTS `bil_org_invoicing_audit_logs` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_invoicing_id` INT UNSIGNED NOT NULL,
  `action_type` ENUM('PENDING','GENERATED','RENEWED','PAID','REMINDER_SENT','OVERDUE_NOTICE','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `performed_by` INT UNSIGNED DEFAULT NULL,  -- which user perform the ation
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_audit_billing` FOREIGN KEY (`billing_id`) REFERENCES `billings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
CREATE TABLE IF NOT EXISTS `sch_subject_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
  `name` varchar(50) NOT NULL,
  `code` char(3) NOT NULL,         -- 'MAJ','MIN','OPT','ACT','SPO'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjectTypes_orgId_shortName` (`org_id`, `short_name`),
  UNIQUE KEY `uq_subjectTypes_orgId_code` (`org_id`, `code`),
  CONSTRAINT `fk_subjectTypes_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_study_formats` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,  -- Lacture, Lab
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,         -- e.g., 'LAC','LAB','ACT','ART' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studyFormats_orgId_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_studyFormats_orgId_code` (`org_id`, `code`),
  CONSTRAINT `fk_studyFormats_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_subjects` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `short_name` varchar(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `code` CHAR(3) NOT NULL,         -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjects_orgId_shortName` (`org_id`, `short_name`),
  UNIQUE KEY `uq_subjects_orgId_code` (`org_id`, `code`),
  CONSTRAINT `fk_subjects_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
-- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
-- Removed 'short_name' as we can use `sub_stdformat_code`
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,                -- FK
  `subject_id` INT unsigned NOT NULL,            -- FK
  `study_format_id` int unsigned NOT NULL,          -- FK
  `name` varchar(50) NOT NULL,
  `subj_stdformat_code` CHAR(7) NOT NULL,         -- Will be combination of (Subject.codee+'-'+StudyFormat.code) e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStudyFormat_orgId_subjectId_stFormat` (`org_id`,`subject_id`,`study_format_id`),
  UNIQUE KEY `uq_subStudyFormat_orgId_subStdformatCode` (`org_id`,`sub_stdformat_code`),
  CONSTRAINT `fk_subStudyFormat_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
CREATE TABLE IF NOT EXISTS `sch_subject_study_format_class_subj_types_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,                    -- FK
  `subject_Study_format_id` INT unsigned NOT NULL,   -- FK
  `class_id` int NOT NULL,                              -- FK
  `section_id` int NULL,                                -- FK (Section can be null if Group will be used for all sectons)
  `subject_type_id` int unsigned NOT NULL,              -- FK
  `rooms_type_id` INT unsigned NOT NULL,             -- FK
  `name` varchar(50) NOT NULL,                          -- 10th-A Science Lacture Major
  `clas_subj_stdformat_Subjtyp_code` CHAR(17) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','7th_A_SAN_OPT' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subStdFmtClsSubjTyp_orgId_subStdFmt_cls_Sec_SubTyp` (`org_id`,`subject_Study_format_id`,`class_id`,`section_id`,`subject_type_id`),
  UNIQUE KEY `uq_subStdFmtClsSubjTyp_orgId_subStdformatCode` (`org_id`,`clas_subj_stdformat_Subjtyp_code`),
  CONSTRAINT `fk_subStdFmtClsSubjTyp_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_subStdFmtClsSubjTyp_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subStdFmtClsSubjTyp_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_subStdFmtClsSubjTyp_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Added rooms_type_id field & FK for it.


-- Table 'sch_subject_groups' will be used to assign all subjects to the students
-- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
-- if above variable is True then section_id will be Nul in below table and
-- Every Group will eb avalaible accross sections for a particuler class
CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,              -- FK
  `class_id` int NOT NULL,                        -- FK
  `section_id` int NULL,                          -- FK (Section can be null if Group will be used for all sectons)
  `short_name` varchar(30) NOT NULL,              -- 7th Science, 7th Commerce, 7th-A Science etc.
  `name` varchar(100) NOT NULL,                   -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjectGroups_orgId_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_subjectGroups_orgId_name` (`org_id`,`class_id`,`name`),
  CONSTRAINT `fk_subGroups_org_id` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE NULL,
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `subject_group_id` INT unsigned NOT NULL,                  -- FK
  `subj_stdformat_class_subjtypes_id` INT unsigned NOT NULL, -- FK
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subjGrpSubj_subjGrpId_subjStdFmtClsSubTyp` (`subject_group_id`,`subj_stdformat_class_subjtypes_id`),
  CONSTRAINT `fk_subjGrpSubj_subjectGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
  CONSTRAINT `fk_subjGrpSubj_subjStdFmtClsSubTyp` FOREIGN KEY (`subj_stdformat_class_subjtypes_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===============================================================================================================
-- All above was incorporated in 'Enhanced_tables_v1.1.sql'
-- ===============================================================================================================

CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,             -- FK
  `code` CHAR(7) NOT NULL,                       -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT'
  `short_name` varchar(30) NOT NULL,             -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
  `name` varchar(100) NOT NULL,
  `required_resources` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roomType_orgId_code` (`org_id`,`code`),
  UNIQUE KEY `uq_roomType_orgId_shortName` (`org_id`,`short_name`),
  CONSTRAINT `fk_roomType_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_buildings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,            -- FK
  `code` char(2) NOT NULL,                      -- 2 digits code (10,11,12) 
  `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
  `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_buildings_code` (`org_id`,`code`),
  UNIQUE KEY `uq_buildings_name` (`org_id`,`short_name`),
  CONSTRAINT `fk_buildings_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
CREATE TABLE IF NOT EXISTS `sch_rooms` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,     -- FK
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
  UNIQUE KEY `uq_rooms_orgId_code` (`org_id`,`code`),
  UNIQUE KEY `uq_rooms_orgId_shortName` (`org_id`,`short_name`),
  CONSTRAINT `fk_rooms_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- For Login user can use one option from (short_name,email,mobile_no)
CREATE TABLE IF NOT EXISTS `sch_users` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
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
  UNIQUE KEY `uq_users_orgId_empCode` (`org_id`,`emp_code`),
  UNIQUE KEY `uq_users_orgId_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_users_orgId_email` (`org_id`,`email`),
  UNIQUE KEY `uq_users_orgId_mobileNo` (`org_id`,`mobile_no`),
  UNIQUE KEY `uq_single_super_admin` (`super_admin_flag`),
  CONSTRAINT `fk_users_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_teachers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,              -- FK
  `user_id` INT UNSIGNED NOT NULL,
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
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `org_id` INT UNSIGNED NOT NULL,
  `teacher_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,
  `study_format_id` INT UNSIGNED NOT NULL,
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
  UNIQUE KEY `uq_teachersProfile_orgId_teacher` (`org_id`,`teacher_id`,`subject_id`,`study_format_id`),
  CONSTRAINT `fk_teachersProfile_orgId` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_teacherId` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teachersProfile_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===============================================================================================================
-- Checked till Here

CREATE TABLE IF NOT EXISTS `sch_media` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `model_type` varchar(255) NOT NULL,
  `model_id` INT unsigned NOT NULL,
  `uuid` char(36) DEFAULT NULL,
  `collection_name` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `mime_type` varchar(255) DEFAULT NULL,
  `disk` varchar(255) NOT NULL,
  `conversions_disk` varchar(255) DEFAULT NULL,
  `size` INT unsigned NOT NULL,
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

-- Purpose: Centralized storage for organization-level configuration values as a key-value pair.
CREATE TABLE IF NOT EXISTS `sch_settings` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `description` text NULL,    -- Here we will describe the use of the variable
  `key` varchar(100) NOT NULL,        -- This will be the Key to connect Value with it
  `value` varchar(100) DEFAULT NULL,          -- Actual stored setting value. Could be string, JSON, or serialized data depending on type
  `type` varchar(50) DEFAULT NULL,    -- e.g. 'string','json','int','boolean', 'date' etc.
  `is_public` tinyint(1) NOT NULL DEFAULT 0,  -- Flag — 1 means this setting can be safely exposed to the frontend (e.g. school logo, theme color), 0 means internal/backend-only (e.g. API keys).
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_settings_orgId_key` (`org_id`,`key`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `glb_languages` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(10) NOT NULL,                  -- ISO code: en, hi, fr, ar
  `name` VARCHAR(50) NOT NULL,                  -- English, Hindi, French...
  `native_name` VARCHAR(50) DEFAULT NULL,       -- "हिन्दी", "Français"
  `direction` ENUM('LTR','RTL') DEFAULT 'LTR',  -- Left to Rght / Right to Left
  `is_active` TINYINT(1) DEFAULT 1,
  UNIQUE KEY `uq_languages_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_dropdown_table` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `ordinal` tinyint unsigned NOT NULL,
  `key` varchar(50) NOT NULL,    -- student_cast
  `value` varchar(100) NOT NULL,
  `type` ENUM('String','Integer','Decimal', 'Date', 'Datetime', 'Time', 'Boolean') NOT NULL DEFAULT 'String',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dropdownTable_org_ordinal_key` (`org_id`,`ordinal`,`key`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ===============================================================================================================
-- Timetable Module

-- We will create Group accros classes who can be taught in a single group like 'Dance' can be taught in a single group from class 6-10th,
-- but we need to have a separate group for junior classes for same subject 'Dance'

-- subject_group is grouping of Subject+Study Format+Class+Section+Subject Type.
-- It answer whether 'Science' 'Lacture' for 7th-A is Major or Minor.
-- This will also be used to assign Subjects to the Students as a Combo.
CREATE TABLE IF NOT EXISTS `subject_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,                     -- FK
  `subject_study_format_id` INT unsigned NOT NULL,    -- FK
  `class_section_id` json NOT NULL,                      -- FK
  `subject_type_id` int unsigned NOT NULL,               -- FK
  `short_name` varchar(30) NOT NULL,         -- 7th Science, 7th Commerce, 7th-A Science etc.
  `name` varchar(100) NOT NULL,
  `class_group_code` VARCHAR(7) NOT NULL,   -- e.g., '7th_A_SCI_LAC','7th_A_SCI_LAB','7th_A_SST_LAC','7th_A_ENG_LAC' (This will be used for Timetable)
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subGroups_orgId_shortName` (`org_id`,`short_name`),
  UNIQUE KEY `uq_subGroups_orgId_classGroupCode` (`org_id`,`class_group_code`),
  CONSTRAINT `fk_subGroups_subject_format_id` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subGroups_class_section_id` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subGroups_org_id` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tim_teacher_constraint` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,

  `max_periods_per_week` INT UNSIGNED DEFAULT NULL,
  `max_periods_per_day` INT UNSIGNED DEFAULT NULL,
  `max_days_per_week` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- Combination of (class, section, subject, study_format). This will help to combine classes for Optioal Subjects
-- It will answer - which all classes can be combined for a particuler Subject + StudyFormat
CREATE TABLE IF NOT EXISTS `sch_class_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `org_id` INT unsigned NOT NULL,
  `class_section_id` int unsigned NOT NULL,  -- FK
  `subject_id` INT unsigned NOT NULL,     -- FK
  `study_format_id` int unsigned NOT NULL,
  `short_name` varchar(20) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `preferred_weekly_frequency` tinyint unsigned DEFAULT NULL,  -- need to removed from here. this need to be set at Subject+class level
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cls_grps_org_section_sub_studyformat` (`org_id`,`class_section_id`,`subject_id`,`study_format_id`),
  CONSTRAINT `fk_cls_grps_org_id` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cls_grps_class_section_id` FOREIGN KEY (`class_section_id`) REFERENCES `class_section` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cls_grps_subject_id` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cls_grps_study_format_id` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=501 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tim_subject_combination_group` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_id` INT UNSIGNED NOT NULL,
  `subject_id` INT UNSIGNED NOT NULL,       -- Math, Sci
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
  UNIQUE KEY `uq_sub_comb_group_org_subj_name` (`org_id`,`subject_id`,`group_name`),
  CONSTRAINT `fk_sub_comb_group_org` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_comb_group_subj` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_comb_group_study_format` FOREIGN KEY (`study_format_id`) REFERENCES `study_formats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Relationships:
-- One Subject → Many Combination Groups
-- One Combination Group → Many Classes




















-- ===========================================
-- Temp Tables  - Check required or Not
-- ===========================================

CREATE TABLE IF NOT EXISTS `sch_period_definitions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `org_id` INT UNSIGNED NOT NULL,
  `code` VARCHAR(1) NOT NULL,         -- e.g., '1','2','3' and so on (This will be used for Timetable)
  `short_name` VARCHAR(10) NOT NULL,  -- e.g., "Period-1 / P-1,P2"
  `name` VARCHAR(50) NOT NULL,        -- e.g., "Lunch Break, Prayer, Class"
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `is_break` TINYINT(1) DEFAULT 0,
  `sort_order` TINYINT UNSIGNED DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;






-- ==================================================================================
-- For MultiLingual Support
-- ==================================================================================

CREATE TABLE IF NOT EXISTS `glb_menu_translations` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `menu_id` INT UNSIGNED NOT NULL,
  `language_id` INT UNSIGNED NOT NULL,
  `translated_title` VARCHAR(150) NOT NULL,
  `translated_description` VARCHAR(255) DEFAULT NULL,
  UNIQUE KEY `uq_menu_lang` (`menu_id`,`language_id`),
  CONSTRAINT `fk_menu_translation_menuId` FOREIGN KEY (`menu_id`) REFERENCES `glb_menus` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_menu_translation_langId` FOREIGN KEY (`language_id`) REFERENCES `glb_languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `glb_masters_translations` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `model_type` VARCHAR(190) NOT NULL,   -- Laravel morph type (e.g., 'App\\Models\\Menu')
  `model_id` INT UNSIGNED NOT NULL,  -- The actual record ID in that model
  `language_code` VARCHAR(10) NOT NULL, -- e.g., 'en', 'hi', 'fr'
  `field_name` VARCHAR(100) NOT NULL,   -- e.g., 'name', 'description', 'title'
  `translated_value` TEXT NOT NULL,     -- the actual translation
  UNIQUE KEY `uq_mastersTrans_modelType_modelId_lang_field` (`model_type`, `model_id`, `language_code`, `field_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Data Example for Table (gl_dropdown_table)
-- ==============================================================================================
-- Key                                  Value                                   type
-- -----------------------------------  --------------------------------------  -----------------
-- student_status                       In-active                               string
-- student_status                       In-active                               string
-- student_status                       Suspended                               string
-- student_status                       Transfered                              string
-- student_religion                     Hindu                                   string
-- student_religion                     Muslim                                  string
-- student_religion                     Sikh                                    string
-- student_religion                     Christian                               string




-- Abbreviation Detail used for Tables Name to distinguish them
-- ------------------------------------------------------------

-- sys - System Tables
-- jnt - Join Table (Junction Table)
-- glb - Global Table
-- olt - Org (School) Level Table
-- tim - Timetable Module
-- sch - School Setup
-- std - Student Management
-- tpt - Transport Module
-- lib - Library Module
-- fnt - FrontDesk Module
-- fin - Finance Mgmt
-- hos - Hostel Mgmt
-- bil - Billing & plans






-- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
-- CREATE TABLE IF NOT EXISTS `sch_subject_study_format_subj_type_jnt` (
--   `id` INT unsigned NOT NULL AUTO_INCREMENT,
--   `org_id` INT unsigned NOT NULL,                -- FK
--   `subject_id` INT unsigned NOT NULL,            -- FK
--   `study_format_id` int unsigned NOT NULL,          -- FK
--   `short_name` varchar(20) NOT NULL,
--   `name` varchar(50) NOT NULL,
--   `subject_type_id` int unsigned NOT NULL,          -- FK
--   `is_active` tinyint(1) NOT NULL DEFAULT '1',
--   `deleted_at` timestamp NULL DEFAULT NULL,
--   `created_at` timestamp NULL DEFAULT NULL,
--   `updated_at` timestamp NULL DEFAULT NULL,
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `uq_subStudyFormatSubjtype_orgId_subjectId_stFormat` (`org_id`,`subject_id`,`study_format_id`),
--   CONSTRAINT `fk_sub_format_org_id` FOREIGN KEY (`org_id`) REFERENCES `sch_organizations` (`id`) ON DELETE CASCADE,
--   CONSTRAINT `fk_sub_format_subject_id` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
--   CONSTRAINT `fk_sub_format_subject_format_id` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE
--   CONSTRAINT `fk_subjects_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
-- ) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




