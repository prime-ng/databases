-- =========================================================================================================
-- Prime-AI Testing Automation App — Enhanced Database Schema
-- Project  : prime_testing
-- Version  : v6.6 (Created on the basis of 6.5 by ChatGpt)
-- MySQL    : 6.5
-- Purpose  : Local execution + multi-machine central aggregation + regression/integration intelligence
-- =========================================================================================================
--
-- DESIGN PRINCIPLES
    -- 1. NO UUID columns.
    -- 2. Catalog identity is business-code based so the same catalog can exist on every developer machine.
    -- 3. Transaction PKs are local/central BIGINT AUTO_INCREMENT values.
    -- 4. Distributed uniqueness is handled at the RUN level by (machine_id, source_run_id).
    -- 5. Child execution rows reference the central/local run_id, so UUID propagation is eliminated.
    -- 6. Test cases are NOT owned by the executor. A test case is a shared catalog object.
    -- 7. test_case_code is unique within a screen: (ts_code, test_case_code).
    -- 8. Git commit information is retained so failures can be correlated with merges/enhancements.
    -- 9. Module and test-case dependencies are first-class data for impact/regression selection.
    -- 10. Bugs are independent tracked entities and may occur in many test results.
    -- 11. Central import never needs to preserve local AUTO_INCREMENT PK values.
--
-- IMPORTANT IMPORT RULE
    -- Local:
    --     tst_test_runs.id = local AUTO_INCREMENT
    --     tst_test_runs.source_run_id = same local id
    --     tst_test_runs.machine_id = registered local machine
    --
    -- Central import:
    --     central tst_test_runs.id = NEW central AUTO_INCREMENT
    --     source_run_id = original local run id
    --     machine_id = original source machine
    --     UNIQUE(machine_id, source_run_id) prevents duplicate run import.
--
-- This same source-identity pattern is used for bugs, requirements, exports,
-- discovery logs and audit logs where independent transaction identity is required.
-- =========================================================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- SECTION 0: APPLICATION SETTINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_app_settings` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `key`           VARCHAR(100) NOT NULL,
    `value`         VARCHAR(1000) NOT NULL,
    `value_type`    ENUM('STRING','INTEGER','BOOLEAN','DATE','TIME','DATETIME','JSON') NOT NULL DEFAULT 'STRING',
    `description`   VARCHAR(500) NULL,
    `is_system`     TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_app_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tst_app_settings`
(`ordinal`,`key`,`value`,`value_type`,`description`,`is_system`)
VALUES
(1,'max_auto_retest_attempts','5','INTEGER','Maximum automatic retest cycles before escalation.',1),
(2,'auto_retest_enabled','true','BOOLEAN','Global switch for automatic bug retest.',1),
(3,'auto_bug_creation_enabled','true','BOOLEAN','Create a bug from a qualifying failed result automatically.',1),
(4,'bug_fix_sla_hours','48','INTEGER','Hours after assignment/fix workflow before stale-bug alert.',1),
(5,'central_mode','false','BOOLEAN','True when this database is the central aggregation database.',1),
(6,'allow_multi_machine_import','true','BOOLEAN','Allow execution data from registered machines to be imported.',1),
(7,'default_regression_days','30','INTEGER','Default look-back period for regression analysis.',1)
ON DUPLICATE KEY UPDATE
    `value` = VALUES(`value`),
    `value_type` = VALUES(`value_type`),
    `description` = VALUES(`description`);

-- ============================================================================
-- SECTION 1: USERS AND MACHINE REGISTRATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_users` (
    `code`          VARCHAR(10) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `email`         VARCHAR(150) NOT NULL,
    `password`      VARCHAR(512) NOT NULL,
    `role`          ENUM('Admin','Architect','QA_Lead','Tester','Developer','Reviewer') NOT NULL DEFAULT 'Tester',
    `is_superuser`  TINYINT(1) NOT NULL DEFAULT 0,
    `is_system`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NULL,
    `updated_by`    VARCHAR(10) NULL,
    `deleted_by`    VARCHAR(10) NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    UNIQUE KEY `uq_tst_users_email` (`email`),
    INDEX `idx_tst_users_active` (`is_active`),
    INDEX `idx_tst_users_role` (`role`),
    CONSTRAINT `fk_tst_users_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_users_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_users_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tst_users`
(`code`,`name`,`email`,`password`,`role`,`is_superuser`,`is_system`,`is_active`,`created_by`,`updated_by`)
VALUES
('super','Super User','super@prime-testing.local','$2y$12$placeholder_super_hash','Admin',1,1,1,'super','super'),
('admin','Administrator','admin@prime-testing.local','$2y$12$placeholder_admin_hash','Admin',0,1,1,'super','super'),
('sys','System','system@prime-testing.local','$2y$12$placeholder_sys_hash','Admin',0,1,1,'super','super'),
('brijesh','Brijesh','brij@prime-testing.local','$2y$12$placeholder_brij_hash','Admin',0,0,1,'super','super'),
('tarun','Tarun','tarun@prime-testing.local','$2y$12$placeholder_tarun_hash','Developer',0,0,1,'super','super'),
('shailesh','Shailesh','shail@prime-testing.local','$2y$12$placeholder_shail_hash','Developer',0,0,1,'super','super'),
('sameer','Sameer','samer@prime-testing.local','$2y$12$placeholder_samer_hash','Tester',0,0,1,'super','super'),
('gaurav','Gaurav','gaurv@prime-testing.local','$2y$12$placeholder_gaurav_hash','Developer',0,0,1,'super','super')
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `email` = VALUES(`email`),
    `role` = VALUES(`role`),
    `is_active` = VALUES(`is_active`);

-- One registered row per physical/logical application installation.
-- IMPORTANT: machine_id must be assigned/registered centrally (or provisioned once) and then persisted in the local application configuration. 
-- Do NOT allow every independent local database to auto-create its own machine_id, otherwise all machines could become machine_id=1. 
-- The AUTO_INCREMENT is primarily for the central registry; local DBs should receive their assigned id during registration.
CREATE TABLE IF NOT EXISTS `tst_machines` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_code`      VARCHAR(30) NOT NULL,  -- This should be unique and can be used to identify the machine. (e.g., M001, M002, etc.)
    `machine_name`      VARCHAR(150) NOT NULL, -- Machine name is given by the user during the registration of the machine.
    `machine_model`     VARCHAR(150) NULL,     -- Machine model. (e.g., Dell XPS 13, MacBook Pro, etc.)
    `os_name`           VARCHAR(80) NULL,      -- OS name of the machine. (e.g., Windows, Linux, macOS)
    `os_version`        VARCHAR(120) NULL,     -- OS version of the machine. (e.g., Windows 10, Ubuntu 20.04, macOS Big Sur)
    `architecture`      VARCHAR(30) NULL,      -- Architecture of the machine. (e.g., x86, x64, ARM)
    `hostname`          VARCHAR(150) NULL,     -- Hostname of the machine. (e.g., DESKTOP-1234567)
    `hardware_serial`   VARCHAR(150) NULL,     -- Hardware serial number of the machine. (e.g., ABC-1234567890)
    `is_central`        TINYINT(1) NOT NULL DEFAULT 0, -- This flag is set to 1 if the machine is a central database. Otherwise, it is set to 0.
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `last_seen_at`      DATETIME NULL,                 -- Last seen at datetime.
    `registered_by`     VARCHAR(10) NOT NULL,          -- User code of the user who registered the machine.
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_machines_code` (`machine_code`),
    UNIQUE KEY `uq_tst_machines_fingerprint` (`machine_fingerprint`),
    INDEX `idx_tst_machines_active` (`is_active`),
    INDEX `idx_tst_machines_hostname` (`hostname`),
    CONSTRAINT `fk_tst_machines_registered_by` FOREIGN KEY (`registered_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 2: TEST CASE MASTERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_test_case_types` (
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_tc_types_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_types_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_types_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_testing_methods` (
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_testing_methods_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_testing_methods_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_testing_methods_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_testing_technologies` (
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_testing_technologies_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_testing_technologies_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_testing_technologies_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_testing_layers` (
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_testing_layers_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_testing_layers_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_testing_layers_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_test_case_statuses` (
    `code` VARCHAR(30) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_tc_status_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_status_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_status_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tst_test_case_types` (`code`,`name`,`ordinal`,`created_by`,`updated_by`)
VALUES
('Standard','Standard',1,'super','super'),
('Unit','Unit',2,'super','super'),
('Validation','Validation',3,'super','super'),
('Feature','Feature',4,'super','super'),
('Business_Condition','Business Condition',5,'super','super')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `tst_testing_methods` (`code`,`name`,`ordinal`,`created_by`,`updated_by`)
VALUES
('Manual','Manual',1,'super','super'),
('Automated','Automated',2,'super','super'),
('Hybrid','Hybrid',3,'super','super')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `tst_testing_technologies` (`code`,`name`,`ordinal`,`created_by`,`updated_by`)
VALUES
('Dusk','Dusk',1,'super','super'),
('Laravel-Unit','Laravel Unit',2,'super','super'),
('Native','Native',3,'super','super')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `tst_testing_layers` (`code`,`name`,`ordinal`,`created_by`,`updated_by`)
VALUES
('GUI','GUI',1,'super','super'),
('API','API',2,'super','super'),
('Unit','Unit',3,'super','super'),
('Integration','Integration',4,'super','super'),
('Performance','Performance',5,'super','super'),
('Security','Security',6,'super','super'),
('Accessibility','Accessibility',7,'super','super'),
('Other','Other',8,'super','super')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `tst_test_case_statuses` (`code`,`name`,`ordinal`,`created_by`,`updated_by`)
VALUES
('Pending','Pending',1,'super','super'),
('In_Progress','In Progress',2,'super','super'),
('Not_Run','Not Run',3,'super','super'),
('Completed','Completed',4,'super','super'),
('Error','Error',5,'super','super'),
('Hold','Hold',6,'super','super'),
('Not_Required','Not Required',7,'super','super')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- ============================================================================
-- SECTION 3: APPLICATION CATALOG
-- Module -> Category -> Main Menu -> Sub Menu -> Tab/Screen -> Test Case
-- Business codes are the stable cross-machine identity.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_modules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code` VARCHAR(10) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(500) NULL,
    `folder_name` VARCHAR(120) NULL,
    `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `version` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_modules_code` (`module_code`),
    INDEX `idx_tst_modules_active` (`is_active`),
    CONSTRAINT `fk_tst_modules_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_modules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_modules_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_categories` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code` VARCHAR(10) NOT NULL,
    `cat_code` VARCHAR(10) NOT NULL,
    `name` VARCHAR(120) NOT NULL,
    `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_categories_cat_code` (`cat_code`),
    UNIQUE KEY `uq_tst_categories_module_name` (`module_code`,`name`),
    INDEX `idx_tst_categories_module` (`module_code`),
    CONSTRAINT `fk_tst_categories_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_categories_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_categories_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_categories_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_main_menus` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code` VARCHAR(10) NOT NULL,
    `cat_code` VARCHAR(10) NOT NULL,
    `mm_code` VARCHAR(12) NOT NULL,
    `name` VARCHAR(120) NOT NULL,
    `route_url` VARCHAR(500) NULL,
    `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_main_menus_code` (`mm_code`),
    INDEX `idx_tst_main_menus_module_category` (`module_code`,`cat_code`),
    CONSTRAINT `fk_tst_main_menus_category` FOREIGN KEY (`cat_code`) REFERENCES `tst_categories`(`cat_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_main_menus_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_main_menus_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_main_menus_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_main_menus_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code` VARCHAR(10) NOT NULL,
    `cat_code` VARCHAR(10) NOT NULL,
    `mm_code` VARCHAR(12) NOT NULL,
    `sm_code` VARCHAR(15) NOT NULL,
    `name` VARCHAR(120) NOT NULL,
    `route_url` VARCHAR(500) NULL,
    `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_sub_menus_code` (`sm_code`),
    INDEX `idx_tst_sub_menus_parent` (`module_code`,`cat_code`,`mm_code`),
    CONSTRAINT `fk_tst_sub_menus_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_sub_menus_category` FOREIGN KEY (`cat_code`) REFERENCES `tst_categories`(`cat_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_sub_menus_main_menu` FOREIGN KEY (`mm_code`) REFERENCES `tst_main_menus`(`mm_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_sub_menus_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_sub_menus_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_sub_menus_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_tabs_screens` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code` VARCHAR(10) NOT NULL,
    `cat_code` VARCHAR(10) NOT NULL,
    `mm_code` VARCHAR(12) NOT NULL,
    `sm_code` VARCHAR(15) NULL,
    `ts_code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `route_url` VARCHAR(500) NULL,
    `folder_path` VARCHAR(500) NULL,
    `is_excluded` TINYINT(1) NOT NULL DEFAULT 0,
    `dev_status` ENUM('Pending','Under-Development','In-Review','Ready-For-Testing','Testing-InProgress','Testing-Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
    `tc_creation_status` ENUM('Pending','In-Progress','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tabs_screens_code` (`ts_code`),
    INDEX `idx_tst_tabs_screens_module` (`module_code`),
    INDEX `idx_tst_tabs_screens_parent` (`module_code`,`cat_code`,`mm_code`,`sm_code`),
    INDEX `idx_tst_tabs_screens_active` (`is_active`,`is_excluded`),
    CONSTRAINT `fk_tst_tabs_screens_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tabs_screens_category` FOREIGN KEY (`cat_code`) REFERENCES `tst_categories`(`cat_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tabs_screens_main_menu` FOREIGN KEY (`mm_code`) REFERENCES `tst_main_menus`(`mm_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tabs_screens_sub_menu` FOREIGN KEY (`sm_code`) REFERENCES `tst_sub_menus`(`sm_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tabs_screens_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tabs_screens_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tabs_screens_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Shared catalog test case. user_code is intentionally NOT part of identity.
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,
    `file_path` VARCHAR(500) NULL,
    `namespace` VARCHAR(255) NULL,
    `class_name` VARCHAR(150) NOT NULL DEFAULT '',
    `method_name` VARCHAR(150) NOT NULL DEFAULT '',
    `display_name` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `test_case_type_code` VARCHAR(30) NOT NULL,
    `test_method_code` VARCHAR(30) NOT NULL,
    `test_technology_code` VARCHAR(30) NOT NULL,
    `test_layer_code` VARCHAR(30) NOT NULL,
    `status_code` VARCHAR(30) NOT NULL DEFAULT 'Pending',
    `requirements_md_path` VARCHAR(500) NULL,
    `definition_hash` CHAR(64) NULL,
    `version_no` INT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_cases_screen_code` (`ts_code`,`test_case_code`),
    INDEX `idx_tst_test_cases_screen` (`ts_code`),
    INDEX `idx_tst_test_cases_status` (`status_code`,`is_active`),
    INDEX `idx_tst_test_cases_method` (`test_method_code`,`test_layer_code`),
    INDEX `idx_tst_test_cases_definition_hash` (`definition_hash`),
    CONSTRAINT `fk_tst_test_cases_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_test_cases_type` FOREIGN KEY (`test_case_type_code`) REFERENCES `tst_test_case_types`(`code`),
    CONSTRAINT `fk_tst_test_cases_method` FOREIGN KEY (`test_method_code`) REFERENCES `tst_testing_methods`(`code`),
    CONSTRAINT `fk_tst_test_cases_technology` FOREIGN KEY (`test_technology_code`) REFERENCES `tst_testing_technologies`(`code`),
    CONSTRAINT `fk_tst_test_cases_layer` FOREIGN KEY (`test_layer_code`) REFERENCES `tst_testing_layers`(`code`),
    CONSTRAINT `fk_tst_test_cases_status` FOREIGN KEY (`status_code`) REFERENCES `tst_test_case_statuses`(`code`),
    CONSTRAINT `fk_tst_test_cases_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_cases_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_cases_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_test_case_versions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,
    `version_no` INT UNSIGNED NOT NULL,
    `definition_hash` CHAR(64) NULL,
    `file_path` VARCHAR(500) NULL,
    `class_name` VARCHAR(150) NULL,
    `method_name` VARCHAR(150) NULL,
    `display_name` VARCHAR(255) NULL,
    `description` TEXT NULL,
    `captured_from_commit_hash` CHAR(64) NULL,
    `captured_by` VARCHAR(10) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tc_versions` (`ts_code`,`test_case_code`,`version_no`),
    INDEX `idx_tst_tc_versions_hash` (`definition_hash`),
    CONSTRAINT `fk_tst_tc_versions_case` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tc_versions_captured_by` FOREIGN KEY (`captured_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 4: DEPENDENCY / IMPACT MODEL
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_module_dependencies` (
    `module_code` VARCHAR(10) NOT NULL,
    `depends_on_module_code` VARCHAR(10) NOT NULL,
    `dependency_type` ENUM('Functional','Data','Shared_Component','API','Integration','Navigation','Other') NOT NULL DEFAULT 'Functional',
    `impact_weight` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`module_code`,`depends_on_module_code`),
    CONSTRAINT `chk_tst_module_dep_not_self` CHECK (`module_code` <> `depends_on_module_code`),
    CONSTRAINT `fk_tst_module_dep_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_module_dep_parent` FOREIGN KEY (`depends_on_module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_module_dep_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_module_dep_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_test_case_dependencies` (
    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,
    `depends_on_ts_code` VARCHAR(20) NOT NULL,
    `depends_on_test_case_code` SMALLINT UNSIGNED NOT NULL,
    `dependency_type` ENUM('Functional','Data','Navigation','API','Integration','Shared_Component','Regression','Other') NOT NULL DEFAULT 'Functional',
    `impact_weight` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`ts_code`,`test_case_code`,`depends_on_ts_code`,`depends_on_test_case_code`),
    CONSTRAINT `chk_tst_tc_dep_not_self` CHECK (
        NOT (`ts_code` = `depends_on_ts_code` AND `test_case_code` = `depends_on_test_case_code`)
    ),
    CONSTRAINT `fk_tst_tc_dep_case` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_dep_parent` FOREIGN KEY (`depends_on_ts_code`,`depends_on_test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_dep_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_dep_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reusable suites such as Smoke, Critical Regression, Integration, Full Regression.
CREATE TABLE IF NOT EXISTS `tst_test_suites` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `suite_code` VARCHAR(40) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `suite_type` ENUM('Smoke','Regression','Integration','Critical','Full','Bug_Retest','Custom') NOT NULL DEFAULT 'Custom',
    `description` TEXT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_suites_code` (`suite_code`),
    CONSTRAINT `fk_tst_test_suites_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_suites_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_suites_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_test_suite_items` (
    `suite_id` INT UNSIGNED NOT NULL,
    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,
    `priority` ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`suite_id`,`ts_code`,`test_case_code`),
    CONSTRAINT `fk_tst_suite_items_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_suite_items_case` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 5: GIT / CHANGE CONTEXT
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_git_commits` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `repository_code` VARCHAR(100) NOT NULL,
    `commit_hash` CHAR(64) NOT NULL,
    `branch_name` VARCHAR(200) NULL,
    `parent_commit_hash` CHAR(64) NULL,
    `merge_commit_hash` CHAR(64) NULL,
    `author_user_code` VARCHAR(10) NULL,
    `author_name` VARCHAR(150) NULL,
    `commit_message` TEXT NULL,
    `is_merge_commit` TINYINT(1) NOT NULL DEFAULT 0,
    `committed_at` DATETIME NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_git_commits_repo_hash` (`repository_code`,`commit_hash`),
    INDEX `idx_tst_git_commits_branch` (`branch_name`),
    INDEX `idx_tst_git_commits_committed_at` (`committed_at`),
    CONSTRAINT `fk_tst_git_commits_author` FOREIGN KEY (`author_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_git_commit_files` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `commit_id` BIGINT UNSIGNED NOT NULL,
    `file_path` VARCHAR(1000) NOT NULL,
    `old_file_path` VARCHAR(1000) NULL,
    `change_type` ENUM('Added','Modified','Deleted','Renamed','Copied','Unknown') NOT NULL DEFAULT 'Modified',
    `module_code` VARCHAR(10) NULL,
    `ts_code` VARCHAR(20) NULL,
    `test_case_code` SMALLINT UNSIGNED NULL,
    `impact_level` ENUM('Low','Medium','High','Critical','Unknown') NOT NULL DEFAULT 'Unknown',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_git_commit_files` (`commit_id`,`file_path`),
    INDEX `idx_tst_git_commit_files_module` (`module_code`),
    INDEX `idx_tst_git_commit_files_screen` (`ts_code`),
    INDEX `idx_tst_git_commit_files_test` (`ts_code`,`test_case_code`),
    CONSTRAINT `fk_tst_git_commit_files_commit` FOREIGN KEY (`commit_id`) REFERENCES `tst_git_commits`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_git_commit_files_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_git_commit_files_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_git_commit_files_test` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 6: TEST EXECUTION
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_test_runs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Distributed source identity. On a local DB source_run_id normally equals id.
    `machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_run_id` BIGINT UNSIGNED NOT NULL,

    -- Attribution: initiator may be a developer while executor may be sys/automation.
    `initiated_by` VARCHAR(10) NULL,
    `executed_by` VARCHAR(10) NULL,

    `trigger_type` ENUM(
        'Manual',
        'Scheduled',
        'Rerun',
        'Auto_Retest',
        'Bug_Retest',
        'Enhancement',
        'Integration',
        'Regression',
        'Git_Merge',
        'Release'
    ) NOT NULL DEFAULT 'Manual',

    `suite_code` VARCHAR(40) NULL,
    `run_name` VARCHAR(200) NULL,
    `reason` VARCHAR(500) NULL,

    -- Git snapshot at execution time.
    `repository_code` VARCHAR(100) NULL,
    `branch_name` VARCHAR(200) NULL,
    `commit_hash` CHAR(64) NULL,
    `merge_commit_hash` CHAR(64) NULL,
    `base_commit_hash` CHAR(64) NULL,

    `parent_run_id` BIGINT UNSIGNED NULL,

    `command` VARCHAR(2000) NULL,
    `status` ENUM('Queued','Running','Completed','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
    `started_at` DATETIME NULL,
    `finished_at` DATETIME NULL,
    `duration_seconds` DECIMAL(12,3) NULL,
    `exit_code` SMALLINT NULL,

    `total_tc_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `passed_tc_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `failed_tc_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `error_tc_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `skipped_tc_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,

    `total_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `passed_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `failed_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,

    `raw_output_path` VARCHAR(1000) NULL,
    `environment_json` JSON NULL,

    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_runs_source` (`machine_id`,`source_run_id`),
    INDEX `idx_tst_test_runs_machine_date` (`machine_id`,`started_at`),
    INDEX `idx_tst_test_runs_executor_date` (`executed_by`,`started_at`),
    INDEX `idx_tst_test_runs_trigger_status` (`trigger_type`,`status`),
    INDEX `idx_tst_test_runs_commit` (`repository_code`,`commit_hash`),
    INDEX `idx_tst_test_runs_parent` (`parent_run_id`),
    INDEX `idx_tst_test_runs_suite` (`suite_code`),

    CONSTRAINT `fk_tst_test_runs_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_test_runs_initiated_by` FOREIGN KEY (`initiated_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_executed_by` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_parent` FOREIGN KEY (`parent_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_runs_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_runs_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Explains why a run was selected / triggered.
CREATE TABLE IF NOT EXISTS `tst_test_run_scopes` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id` BIGINT UNSIGNED NOT NULL,
    `scope_type` ENUM('Module','Screen','TestCase','Bug','Requirement','Commit','Suite','FullSuite') NOT NULL,
    `module_code` VARCHAR(10) NULL,
    `ts_code` VARCHAR(20) NULL,
    `test_case_code` SMALLINT UNSIGNED NULL,
    `bug_id` BIGINT UNSIGNED NULL,
    `requirement_id` BIGINT UNSIGNED NULL,
    `repository_code` VARCHAR(100) NULL,
    `commit_hash` CHAR(64) NULL,
    `suite_code` VARCHAR(40) NULL,
    `description` VARCHAR(500) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_run_scopes_run` (`run_id`),
    INDEX `idx_tst_run_scopes_module` (`module_code`),
    INDEX `idx_tst_run_scopes_screen` (`ts_code`),
    INDEX `idx_tst_run_scopes_test` (`ts_code`,`test_case_code`),
    INDEX `idx_tst_run_scopes_bug` (`bug_id`),
    CONSTRAINT `fk_tst_run_scopes_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_run_scopes_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_scopes_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_scopes_test` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One selected test case per run. Selection reason makes impact analysis explainable.
CREATE TABLE IF NOT EXISTS `tst_test_run_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id` BIGINT UNSIGNED NOT NULL,
    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,
    `selection_reason` ENUM(
        'Manual',
        'Suite',
        'Direct_Change',
        'Dependency',
        'Bug_Retest',
        'Critical',
        'Regression',
        'Full_Regression',
        'Other'
    ) NOT NULL DEFAULT 'Manual',
    `selection_source` VARCHAR(255) NULL,
    `sequence_no` INT UNSIGNED NOT NULL DEFAULT 1,

    -- Snapshot protects history when catalog metadata changes later.
    `test_case_version_no` INT UNSIGNED NULL,
    `display_name_snapshot` VARCHAR(255) NOT NULL,
    `file_path_snapshot` VARCHAR(500) NULL,

    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_run_items_run_case` (`run_id`,`ts_code`,`test_case_code`),
    INDEX `idx_tst_test_run_items_case` (`ts_code`,`test_case_code`),
    INDEX `idx_tst_test_run_items_reason` (`selection_reason`),
    CONSTRAINT `fk_tst_test_run_items_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_test_run_items_case` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_test_run_items_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_run_items_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_run_items_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One or more attempts may exist for one selected test case.
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id` BIGINT UNSIGNED NOT NULL,
    `run_item_id` BIGINT UNSIGNED NOT NULL,
    `attempt_no` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_final_attempt` TINYINT(1) NOT NULL DEFAULT 1,

    `status` ENUM('Passed','Failed','Skipped','Error') NOT NULL,
    `duration_seconds` DECIMAL(12,3) NULL,
    `assertions` INT UNSIGNED NOT NULL DEFAULT 0,

    `display_name_snapshot` VARCHAR(255) NOT NULL,
    `error_message` TEXT NULL,
    `error_trace` MEDIUMTEXT NULL,

    -- Application-generated normalized hash of failure details.
    -- Useful for grouping repeated failures without UUIDs.
    `failure_fingerprint` CHAR(64) NULL,

    `screenshot_path` VARCHAR(1000) NULL,
    `console_log_path` VARCHAR(1000) NULL,
    `source_html_path` VARCHAR(1000) NULL,
    `result_json` JSON NULL,

    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_run_results_attempt` (`run_item_id`,`attempt_no`),
    INDEX `idx_tst_test_run_results_run_status` (`run_id`,`status`),
    INDEX `idx_tst_test_run_results_case_status` (`status`),
    INDEX `idx_tst_test_run_results_failure_fingerprint` (`failure_fingerprint`),
    CONSTRAINT `fk_tst_test_run_results_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_test_run_results_item` FOREIGN KEY (`run_item_id`) REFERENCES `tst_test_run_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_test_run_results_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_run_results_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_run_results_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Global rolling summary. Deliberately NOT per developer:
-- the objective is to understand the health of the shared application/test.
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,

    `last_run_id` BIGINT UNSIGNED NULL,
    `last_run_result_id` BIGINT UNSIGNED NULL,
    `last_status` ENUM('Passed','Failed','Skipped','Error') NULL,
    `last_run_at` DATETIME NULL,

    `consecutive_failures` INT UNSIGNED NOT NULL DEFAULT 0,
    `consecutive_passes` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_runs` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_passed` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_failed` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_error` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_skipped` BIGINT UNSIGNED NOT NULL DEFAULT 0,

    `pass_rate_30d` DECIMAL(5,2) NULL,
    `avg_duration_seconds` DECIMAL(12,3) NULL,
    `is_flaky` TINYINT(1) NOT NULL DEFAULT 0,
    `flaky_reason` VARCHAR(255) NULL,

    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_case_summary_case` (`ts_code`,`test_case_code`),
    INDEX `idx_tst_case_summary_status` (`last_status`),
    INDEX `idx_tst_case_summary_flaky` (`is_flaky`),
    INDEX `idx_tst_case_summary_last_run` (`last_run_at`),
    CONSTRAINT `fk_tst_case_summary_case` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_case_summary_last_run` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_case_summary_last_result` FOREIGN KEY (`last_run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 7: NOTES, DISCOVERY, SCHEDULES
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_run_annotations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id` BIGINT UNSIGNED NOT NULL,
    `run_result_id` BIGINT UNSIGNED NULL,
    `user_code` VARCHAR(10) NOT NULL,
    `comment` VARCHAR(500) NOT NULL,
    `note` TEXT NULL,
    `is_known_issue` TINYINT(1) NOT NULL DEFAULT 0,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_run_annotations_run` (`run_id`),
    INDEX `idx_tst_run_annotations_result` (`run_result_id`),
    INDEX `idx_tst_run_annotations_known` (`is_known_issue`),
    CONSTRAINT `fk_tst_run_annotations_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_run_annotations_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_run_annotations_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_run_annotations_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_run_annotations_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_run_annotations_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_discovery_sync_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_sync_id` BIGINT UNSIGNED NOT NULL,
    `user_code` VARCHAR(10) NOT NULL,
    `sync_mode` ENUM('Discover','Import') NOT NULL DEFAULT 'Discover',
    `import_format` ENUM('CSV','Excel','JSON','Other') NULL,
    `folder_path` VARCHAR(1000) NULL,
    `file_name` VARCHAR(500) NULL,
    `file_path` VARCHAR(1000) NULL,
    `started_at` DATETIME NOT NULL,
    `finished_at` DATETIME NULL,
    `status` ENUM('Running','Success','Failed') NOT NULL DEFAULT 'Running',
    `modules_found` INT UNSIGNED NOT NULL DEFAULT 0,
    `tabs_found` INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_added` INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_updated` INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_removed` INT UNSIGNED NOT NULL DEFAULT 0,
    `details_json` JSON NULL,
    `error_message` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_discovery_sync_source` (`machine_id`,`source_sync_id`),
    INDEX `idx_tst_discovery_sync_status` (`status`,`started_at`),
    CONSTRAINT `fk_tst_discovery_sync_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_discovery_sync_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_schedules` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,
    `suite_code` VARCHAR(40) NULL,
    `scope_json` JSON NULL,
    `cron_expression` VARCHAR(100) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `last_run_id` BIGINT UNSIGNED NULL,
    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_schedules_name` (`name`),
    INDEX `idx_tst_schedules_active` (`is_active`),
    CONSTRAINT `fk_tst_schedules_last_run` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_schedules_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_schedules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_schedules_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 8: TEST CASE REQUIREMENTS / BACKLOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_test_case_requirements` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_requirement_id` BIGINT UNSIGNED NOT NULL,
    `user_code` VARCHAR(10) NOT NULL,

    `module_code` VARCHAR(10) NOT NULL,
    `ts_code` VARCHAR(20) NULL,
    `proposed_tab_name` VARCHAR(150) NULL,
    `proposed_folder_path` VARCHAR(1000) NULL,

    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `priority` ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `target_release` VARCHAR(100) NULL,

    `requested_by` VARCHAR(10) NULL,
    `assigned_to` VARCHAR(10) NULL,
    `status` ENUM('Pending','In_Progress','Completed','Cancelled','Hold') NOT NULL DEFAULT 'Pending',

    `target_ts_code` VARCHAR(20) NULL,
    `target_test_case_code` SMALLINT UNSIGNED NULL,

    `completed_by` VARCHAR(10) NULL,
    `completed_at` DATETIME NULL,

    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_requirements_source` (`machine_id`,`source_requirement_id`),
    INDEX `idx_tst_requirements_module` (`module_code`),
    INDEX `idx_tst_requirements_status_priority` (`status`,`priority`),
    INDEX `idx_tst_requirements_assigned` (`assigned_to`),
    CONSTRAINT `fk_tst_requirements_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_requirements_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_requirements_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_requirements_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_requirements_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_requirements_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_requirements_target_case` FOREIGN KEY (`target_ts_code`,`target_test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_requirements_completed_by` FOREIGN KEY (`completed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 9: BUG TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_bugs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `origin_machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_bug_id` BIGINT UNSIGNED NOT NULL,

    `discovered_by` VARCHAR(10) NULL,
    `first_detected_run_id` BIGINT UNSIGNED NULL,
    `first_detected_result_id` BIGINT UNSIGNED NULL,

    `ts_code` VARCHAR(20) NOT NULL,
    `test_case_code` SMALLINT UNSIGNED NOT NULL,

    `requirement_id` BIGINT UNSIGNED NULL,

    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `severity` ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `status` ENUM('Open','Assigned','In_Progress','Fixed','Retesting','Reopened','Closed','Escalated','Wont_Fix') NOT NULL DEFAULT 'Open',

    `assigned_to` VARCHAR(10) NULL,
    `assigned_by` VARCHAR(10) NULL,
    `assigned_at` DATETIME NULL,

    `fixed_by` VARCHAR(10) NULL,
    `fixed_at` DATETIME NULL,
    `fixed_commit_hash` CHAR(64) NULL,
    `fix_notes` TEXT NULL,

    `reopen_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,

    `duplicate_of_bug_id` BIGINT UNSIGNED NULL,

    `closed_by` VARCHAR(10) NULL,
    `closed_at` DATETIME NULL,

    `created_by` VARCHAR(10) NOT NULL,
    `updated_by` VARCHAR(10) NOT NULL,
    `deleted_by` VARCHAR(10) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_bugs_source` (`origin_machine_id`,`source_bug_id`),
    INDEX `idx_tst_bugs_status_severity` (`status`,`severity`),
    INDEX `idx_tst_bugs_case` (`ts_code`,`test_case_code`),
    INDEX `idx_tst_bugs_assigned` (`assigned_to`,`status`),
    INDEX `idx_tst_bugs_first_run` (`first_detected_run_id`),
    INDEX `idx_tst_bugs_fixed_commit` (`fixed_commit_hash`),

    CONSTRAINT `fk_tst_bugs_origin_machine` FOREIGN KEY (`origin_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_bugs_discovered_by` FOREIGN KEY (`discovered_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_first_run` FOREIGN KEY (`first_detected_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_first_result` FOREIGN KEY (`first_detected_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_case` FOREIGN KEY (`ts_code`,`test_case_code`)
        REFERENCES `tst_test_cases`(`ts_code`,`test_case_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_bugs_requirement` FOREIGN KEY (`requirement_id`) REFERENCES `tst_test_case_requirements`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_fixed_by` FOREIGN KEY (`fixed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_duplicate_of` FOREIGN KEY (`duplicate_of_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_bugs_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_bugs_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A bug can be observed by many failed/retest results across many runs.
CREATE TABLE IF NOT EXISTS `tst_bug_occurrences` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id` BIGINT UNSIGNED NOT NULL,
    `run_result_id` BIGINT UNSIGNED NOT NULL,
    `occurrence_type` ENUM('First_Detected','Regression','Reproduced','Retest_Failed','Retest_Passed','Other') NOT NULL DEFAULT 'Reproduced',
    `note` VARCHAR(500) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_bug_occurrences_bug_result` (`bug_id`,`run_result_id`),
    INDEX `idx_tst_bug_occurrences_result` (`run_result_id`),
    CONSTRAINT `fk_tst_bug_occurrences_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_occurrences_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_bug_status_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id` BIGINT UNSIGNED NOT NULL,
    `from_status` VARCHAR(30) NULL,
    `to_status` VARCHAR(30) NOT NULL,
    `changed_by` VARCHAR(10) NULL,
    `note` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_bug_status_history_bug_date` (`bug_id`,`created_at`),
    CONSTRAINT `fk_tst_bug_status_history_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_status_history_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 10: AUTOMATED BUG RETEST / REGRESSION LOOP
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_retest_cycles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id` BIGINT UNSIGNED NOT NULL,
    `cycle_number` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `triggered_by` VARCHAR(10) NULL,
    `triggered_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `run_id` BIGINT UNSIGNED NULL,
    `status` ENUM('Pending','Passed','Failed','Cancelled') NOT NULL DEFAULT 'Pending',
    `scope_json` JSON NULL,
    `completed_at` DATETIME NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_retest_cycles_bug_number` (`bug_id`,`cycle_number`),
    INDEX `idx_tst_retest_cycles_status` (`status`),
    INDEX `idx_tst_retest_cycles_run` (`run_id`),
    CONSTRAINT `fk_tst_retest_cycles_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_retest_cycles_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_retest_cycles_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A retest run can cover more than one bug.
CREATE TABLE IF NOT EXISTS `tst_retest_cycle_bugs` (
    `retest_cycle_id` BIGINT UNSIGNED NOT NULL,
    `bug_id` BIGINT UNSIGNED NOT NULL,
    `outcome` ENUM('Pending','Passed','Failed','Not_Covered') NOT NULL DEFAULT 'Pending',
    `note` VARCHAR(500) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`retest_cycle_id`,`bug_id`),
    CONSTRAINT `fk_tst_retest_cycle_bugs_cycle` FOREIGN KEY (`retest_cycle_id`) REFERENCES `tst_retest_cycles`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_retest_cycle_bugs_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 11: DATA EXPORT / IMPORT
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_data_exports` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_export_id` BIGINT UNSIGNED NOT NULL,
    `user_code` VARCHAR(10) NOT NULL,
    `export_name` VARCHAR(200) NOT NULL,
    `export_type` ENUM('Full','Incremental','Selected') NOT NULL DEFAULT 'Incremental',
    `date_from` DATETIME NULL,
    `date_to` DATETIME NULL,
    `modules_json` JSON NULL,
    `file_path` VARCHAR(1000) NULL,
    `file_sha256` CHAR(64) NULL,
    `status` ENUM('Pending','In_Progress','Completed','Failed') NOT NULL DEFAULT 'Pending',
    `record_counts_json` JSON NULL,
    `error_message` TEXT NULL,
    `exported_at` DATETIME NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_data_exports_source` (`machine_id`,`source_export_id`),
    INDEX `idx_tst_data_exports_status` (`status`),
    INDEX `idx_tst_data_exports_date` (`exported_at`),
    CONSTRAINT `fk_tst_data_exports_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_data_exports_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_data_imports` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `source_machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_export_id` BIGINT UNSIGNED NOT NULL,
    `imported_by` VARCHAR(10) NOT NULL,
    `file_name` VARCHAR(500) NULL,
    `file_sha256` CHAR(64) NULL,
    `status` ENUM('Pending','In_Progress','Completed','Partial','Failed') NOT NULL DEFAULT 'Pending',
    `started_at` DATETIME NULL,
    `finished_at` DATETIME NULL,
    `record_counts_json` JSON NULL,
    `error_message` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_data_imports_source_export` (`source_machine_id`,`source_export_id`),
    INDEX `idx_tst_data_imports_status` (`status`),
    INDEX `idx_tst_data_imports_started` (`started_at`),
    CONSTRAINT `fk_tst_data_imports_machine` FOREIGN KEY (`source_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_data_imports_user` FOREIGN KEY (`imported_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 12: SYSTEM AUDIT LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_audit_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_audit_id` BIGINT UNSIGNED NOT NULL,
    `user_code` VARCHAR(10) NULL,
    `table_name` VARCHAR(100) NOT NULL,
    `record_id` BIGINT UNSIGNED NULL,
    `record_key` VARCHAR(255) NULL,
    `operation` ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    `old_values_json` JSON NULL,
    `new_values_json` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` VARCHAR(1000) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_audit_logs_source` (`machine_id`,`source_audit_id`),
    INDEX `idx_tst_audit_logs_table_record` (`table_name`,`record_id`),
    INDEX `idx_tst_audit_logs_user_date` (`user_code`,`created_at`),
    INDEX `idx_tst_audit_logs_operation_date` (`operation`,`created_at`),
    CONSTRAINT `fk_tst_audit_logs_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_audit_logs_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 13: CONVENIENCE / ANALYSIS VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW `vw_test_case_catalog` AS
SELECT
    tc.id AS test_case_id,
    m.module_code,
    m.name AS module_name,
    c.cat_code,
    c.name AS category_name,
    mm.mm_code,
    mm.name AS main_menu_name,
    sm.sm_code,
    sm.name AS sub_menu_name,
    t.ts_code,
    t.name AS screen_name,
    t.route_url,
    tc.test_case_code,
    tc.display_name AS test_case_name,
    tc.test_case_type_code,
    tc.test_method_code,
    tc.test_technology_code,
    tc.test_layer_code,
    tc.status_code,
    tc.version_no,
    tc.is_active,
    cs.last_status,
    cs.last_run_at,
    cs.pass_rate_30d,
    cs.is_flaky,
    cs.consecutive_failures
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
JOIN tst_modules m ON m.module_code = t.module_code
JOIN tst_categories c ON c.cat_code = t.cat_code
JOIN tst_main_menus mm ON mm.mm_code = t.mm_code
LEFT JOIN tst_sub_menus sm ON sm.sm_code = t.sm_code
LEFT JOIN tst_test_case_runs_summary cs
    ON cs.ts_code = tc.ts_code
   AND cs.test_case_code = tc.test_case_code;

CREATE OR REPLACE VIEW `vw_test_run_history` AS
SELECT
    r.id AS run_id,
    r.machine_id,
    m.machine_code,
    m.machine_name,
    r.source_run_id,
    r.initiated_by,
    iu.name AS initiated_by_name,
    r.executed_by,
    eu.name AS executed_by_name,
    r.trigger_type,
    r.suite_code,
    r.run_name,
    r.reason,
    r.repository_code,
    r.branch_name,
    r.commit_hash,
    r.merge_commit_hash,
    r.status,
    r.started_at,
    r.finished_at,
    r.duration_seconds,
    r.total_tc_count,
    r.passed_tc_count,
    r.failed_tc_count,
    r.error_tc_count,
    r.skipped_tc_count
FROM tst_test_runs r
JOIN tst_machines m ON m.id = r.machine_id
LEFT JOIN tst_users iu ON iu.code = r.initiated_by
LEFT JOIN tst_users eu ON eu.code = r.executed_by;

CREATE OR REPLACE VIEW `vw_regression_candidates` AS
SELECT
    cs.ts_code,
    cs.test_case_code,
    tc.display_name,
    t.module_code,
    m.name AS module_name,
    t.name AS screen_name,
    cs.last_status,
    cs.last_run_at,
    cs.total_passed,
    cs.total_failed,
    cs.consecutive_failures,
    cs.pass_rate_30d,
    cs.is_flaky
FROM tst_test_case_runs_summary cs
JOIN tst_test_cases tc
  ON tc.ts_code = cs.ts_code
 AND tc.test_case_code = cs.test_case_code
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
JOIN tst_modules m ON m.module_code = t.module_code
WHERE cs.last_status IN ('Failed','Error')
  AND cs.total_passed > 0
  AND cs.consecutive_failures > 0;

CREATE OR REPLACE VIEW `vw_flaky_tests` AS
SELECT
    cs.ts_code,
    cs.test_case_code,
    tc.display_name,
    t.module_code,
    m.name AS module_name,
    t.name AS screen_name,
    cs.pass_rate_30d,
    cs.is_flaky,
    cs.flaky_reason,
    cs.total_runs,
    cs.total_passed,
    cs.total_failed,
    cs.last_status,
    cs.last_run_at
FROM tst_test_case_runs_summary cs
JOIN tst_test_cases tc
  ON tc.ts_code = cs.ts_code
 AND tc.test_case_code = cs.test_case_code
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
JOIN tst_modules m ON m.module_code = t.module_code
WHERE cs.is_flaky = 1;

CREATE OR REPLACE VIEW `vw_open_bugs` AS
SELECT
    b.id AS bug_id,
    b.origin_machine_id,
    b.source_bug_id,
    b.ts_code,
    b.test_case_code,
    tc.display_name AS test_case_name,
    t.module_code,
    m.name AS module_name,
    t.name AS screen_name,
    b.title,
    b.severity,
    b.status,
    b.assigned_to,
    au.name AS assigned_to_name,
    b.reopen_count,
    b.fixed_at,
    b.fixed_commit_hash,
    COUNT(DISTINCT bo.id) AS occurrence_count,
    b.created_at,
    b.updated_at
FROM tst_bugs b
JOIN tst_test_cases tc
  ON tc.ts_code = b.ts_code
 AND tc.test_case_code = b.test_case_code
JOIN tst_tabs_screens t ON t.ts_code = b.ts_code
JOIN tst_modules m ON m.module_code = t.module_code
LEFT JOIN tst_users au ON au.code = b.assigned_to
LEFT JOIN tst_bug_occurrences bo ON bo.bug_id = b.id
WHERE b.deleted_at IS NULL
  AND b.status NOT IN ('Closed','Wont_Fix')
GROUP BY
    b.id,b.origin_machine_id,b.source_bug_id,b.ts_code,b.test_case_code,
    tc.display_name,t.module_code,m.name,t.name,b.title,b.severity,b.status,
    b.assigned_to,au.name,b.reopen_count,b.fixed_at,b.fixed_commit_hash,
    b.created_at,b.updated_at;

CREATE OR REPLACE VIEW `vw_module_quality_summary` AS
SELECT
    t.module_code,
    m.name AS module_name,
    COUNT(DISTINCT tc.id) AS test_case_count,
    COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN tc.id END) AS last_passed,
    COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN tc.id END) AS last_failed,
    COUNT(DISTINCT CASE WHEN cs.is_flaky = 1 THEN tc.id END) AS flaky_tests,
    COUNT(DISTINCT CASE WHEN b.status NOT IN ('Closed','Wont_Fix') THEN b.id END) AS open_bugs
FROM tst_tabs_screens t
JOIN tst_modules m ON m.module_code = t.module_code
JOIN tst_test_cases tc ON tc.ts_code = t.ts_code
LEFT JOIN tst_test_case_runs_summary cs
  ON cs.ts_code = tc.ts_code
 AND cs.test_case_code = tc.test_case_code
LEFT JOIN tst_bugs b
  ON b.ts_code = tc.ts_code
 AND b.test_case_code = tc.test_case_code
 AND b.deleted_at IS NULL
GROUP BY t.module_code,m.name;

CREATE OR REPLACE VIEW `vw_developer_activity_summary` AS
SELECT
    u.code AS user_code,
    u.name AS user_name,
    u.role,
    COALESCE(r.total_runs,0) AS total_runs,
    COALESCE(r.total_tests_executed,0) AS total_tests_executed,
    COALESCE(r.total_passed,0) AS total_passed,
    COALESCE(r.total_failed,0) AS total_failed,
    COALESCE(b.bugs_raised,0) AS bugs_raised,
    COALESCE(b.bugs_assigned,0) AS bugs_assigned,
    COALESCE(b.bugs_fixed,0) AS bugs_fixed,
    GREATEST(
        COALESCE(r.last_run_at,'1970-01-01'),
        COALESCE(b.last_bug_at,'1970-01-01')
    ) AS last_activity_at
FROM tst_users u
LEFT JOIN (
    SELECT
        initiated_by AS user_code,
        COUNT(*) AS total_runs,
        COALESCE(SUM(total_tc_count),0) AS total_tests_executed,
        COALESCE(SUM(passed_tc_count),0) AS total_passed,
        COALESCE(SUM(failed_tc_count),0) AS total_failed,
        MAX(finished_at) AS last_run_at
    FROM tst_test_runs
    WHERE initiated_by IS NOT NULL
    GROUP BY initiated_by
) r ON r.user_code = u.code
LEFT JOIN (
    SELECT
        u2.code AS user_code,
        COALESCE(br.bugs_raised,0) AS bugs_raised,
        COALESCE(ba.bugs_assigned,0) AS bugs_assigned,
        COALESCE(bf.bugs_fixed,0) AS bugs_fixed,
        GREATEST(
            COALESCE(br.last_bug_raised_at,'1970-01-01'),
            COALESCE(ba.last_bug_assigned_at,'1970-01-01'),
            COALESCE(bf.last_bug_fixed_at,'1970-01-01')
        ) AS last_bug_at
    FROM tst_users u2
    LEFT JOIN (
        SELECT created_by AS user_code, COUNT(*) AS bugs_raised, MAX(created_at) AS last_bug_raised_at
        FROM tst_bugs
        WHERE deleted_at IS NULL AND created_by IS NOT NULL
        GROUP BY created_by
    ) br ON br.user_code = u2.code
    LEFT JOIN (
        SELECT assigned_to AS user_code, COUNT(*) AS bugs_assigned, MAX(assigned_at) AS last_bug_assigned_at
        FROM tst_bugs
        WHERE deleted_at IS NULL AND assigned_to IS NOT NULL
        GROUP BY assigned_to
    ) ba ON ba.user_code = u2.code
    LEFT JOIN (
        SELECT fixed_by AS user_code, COUNT(*) AS bugs_fixed, MAX(fixed_at) AS last_bug_fixed_at
        FROM tst_bugs
        WHERE deleted_at IS NULL AND fixed_by IS NOT NULL
        GROUP BY fixed_by
    ) bf ON bf.user_code = u2.code
) b ON b.user_code = u.code
WHERE u.is_active = 1
  AND u.is_system = 0;

-- Which tests were selected because they were directly changed vs impacted dependencies.
CREATE OR REPLACE VIEW `vw_run_test_selection_analysis` AS
SELECT
    ri.run_id,
    r.trigger_type,
    r.commit_hash,
    r.merge_commit_hash,
    r.started_at,
    ri.ts_code,
    ri.test_case_code,
    ri.selection_reason,
    ri.selection_source,
    tc.display_name
FROM tst_test_run_items ri
JOIN tst_test_runs r ON r.id = ri.run_id
JOIN tst_test_cases tc
  ON tc.ts_code = ri.ts_code
 AND tc.test_case_code = ri.test_case_code;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================================================================
-- END OF ENHANCED SCHEMA v8.0
-- =========================================================================================================
