-- ===============================================================================================================
-- Prime-AI Testing Automation App — Database Schema
-- Project  : prime_testing (standalone Laravel app, separate from prime_ai)
-- Version  : v7.1
-- MySQL 8 Compatible | Single-tenant internal tool DB
-- Based on : Testing_DDL_v6.sql + testing_requirement_v3.md
-- Created  : 2026-09-02
-- Author   : Enterprise Architect (Claude)
--
-- v7 CHANGES vs v6:
--  BUGFIXES:
--   1. tst_users has NO `id` column (PK is `code VARCHAR(5)`). All "by" columns
--      that were INT UNSIGNED referencing tst_users(id) are fixed to VARCHAR(5)
--      referencing tst_users(code). Affected: tst_modules.created_by,
--      tst_test_cases.user_code (FK constraint was missing), tst_test_runs.executed_by
--      (merged into user_code PK), tst_sync_logs.created_by (merged into user_code PK),
--      tst_test_case_requirements.(requested_by, assigned_to, completed_by),
--      tst_bugs.(assigned_to, assigned_by, fixed_by, closed_by),
--      tst_bug_status_history.changed_by.
--
--  ARCHITECTURAL CHANGES (FR-13/FR-14 — Multi-Developer Distributed Execution):
--   2. All TRANSACTION tables now use a COMPOSITE PRIMARY KEY (id, user_code) to
--      eliminate ID collision when merging data from multiple developer machines
--      into a central DB. Two developers both producing id=1 become (1,'brij') and
--      (1,'tarun') — distinct rows with no conflict.
--   3. FK chains between transaction tables propagate user_code:
--      e.g. FOREIGN KEY (run_id, user_code) REFERENCES tst_test_runs(id, user_code)
--   4. tst_schedules.last_run_id changed from INT (PK ref) to VARCHAR(64) referencing
--      tst_test_runs.run_id (UNIQUE KEY) — avoids composite FK from a catalog table.
--   5. tst_test_run_results: forward-reference ALTER now adds BOTH bug_id AND
--      bug_user_code with composite FK → tst_bugs(id, user_code).
--   6. tst_test_runs.executed_by merged into PK column user_code (same semantics,
--      cleaner; 'sys' user handles Auto_Retest attribution).
--   7. tst_sync_logs.created_by merged into PK column user_code.
--   8. tst_run_annotations.created_by merged into PK column user_code.
--
--  NEW TABLES (FR-16/FR-20):
--   9. tst_audit_logs       — system-wide CRUD audit trail
--  10. tst_data_exports     — export bundle tracking for central import
--
--  NEW COLUMNS:
--  11. tst_test_runs.hostname — developer machine name for environment identification
--
--  NEW VIEWS:
--  12. vw_cross_user_test_comparison  — same test run by multiple developers
--  13. vw_regression_candidates       — tests that passed before but now failing
--  14. vw_developer_activity_summary  — per-developer metrics
--  15. vw_reopen_leaderboard          — fragile screens by reopen count
--
--  NEW SETTINGS SEEDS:
--  16. allow_multi_user_import (boolean) — enable central aggregation mode
--  17. central_mode (boolean)            — marks this DB as central aggregation DB
--
-- TABLE CLASSIFICATION:
--   CATALOG (simple INT PK — shared, synced from prime_ai codebase, same across all machines):
--     tst_users, tst_modules, tst_categories, tst_main_menus, tst_sub_menus,
--     tst_tabs_screens, tst_test_cases, tst_schedules, tst_app_settings
--
--   TRANSACTION (composite PK (id, user_code) — per-developer data, merged centrally):
--     tst_test_runs, tst_test_run_results, tst_test_case_runs_summary,
--     tst_run_annotations, tst_sync_logs, tst_test_case_requirements,
--     tst_bugs, tst_bug_status_history, tst_retest_cycles,
--     tst_bug_retest_cycles_jnt, tst_audit_logs, tst_data_exports
-- ---------------------------------------------------------------------------------------------------------------
-- v7.1 CHANGES vs v7:
-- Notes: 
-- 1. Added created_by, updated_by, deleted_by in Every Table. 
-- 2. Created New Mapping Table to map Module, Tabs/Screens Codes with Actual Names.

-- ---------------------------------------------------------------------------------------------------------------
-- MODULE TYPE
-- T_ : TENANT MODULE
-- P_ : PRIME MODULE
-- G_ : GLOBAL MODULE
-- S_ : STUNDET/PARENT MODULE
-- M_ : MOBILE APP MODULE

-- ===============================================================================================================


-- ============================================================================
-- SECTION 0: TEST-APP CONFIG
-- ============================================================================
-- WARNING : There are some strict restrictions on the Tables in this Section (TEST-APP CONFIG)
--  Table - `tst_app_settings`:
--   1. Data can be Added in this table using Data Seeder only.
--   2. User can not add/delete any record in this table, they can only update the values of the records.
--   3. is_system column is used to identify the system-generated records.
--   4. "Key" column's value can not be changed in any situation, it is directly hardcoded in the application logic.
--   5. New Entry can be created by Developer only and by using Data Seeder only in this table.
--
--  Table - `tst_default_test_values`
--   1. Data can be Added in this table using Data Seeder only.
--   2. User can not add/delete any record in this table, they can update the values for allowed fields only.
--   3. "name" column's value can not be changed in any situation, it is directly hardcoded in the application logic.
--   4. New Entry can be created by Developer only and by using Data Seeder only in this table.
--


-- Tab : Settings
-- This table will store various system-wide settings and configurations (FR-11)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_app_settings` (
    `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `ordinal`       SMALLINT UNSIGNED NOT NULL,
    `key`           VARCHAR(100)  NOT NULL,
    `value`         VARCHAR(500)  NOT NULL,
    `value_type`    ENUM('STRING', 'INTEGER', 'BOOLEAN', 'DATE', 'TIME', 'DATETIME', 'JSON') NOT NULL,
    `description`   VARCHAR(255)  NULL,
    `is_system`     TINYINT(1)    NOT NULL DEFAULT 0,  -- 1 means this setting can not be odified, 0 means internal/backend-only (e.g. API keys).
    `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP     NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_appSettings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Seed default settings
INSERT INTO `tst_app_settings` (`ordinal`, `key`, `value`, `value_type`, `description`, `is_system`, `created_at`, `updated_at`, `deleted_at`) VALUES
  (1,'max_auto_retest_attempts', '5',     'integer', 'FR-10 safety valve: after this many reopen cycles for the same bug, status → Escalated.', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  (2,'auto_retest_enabled',      'true',  'boolean', 'Global kill-switch: false = marking a bug Fixed does NOT auto-trigger the FR-10 retest.', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  (3,'auto_bug_creation_enabled','true',  'boolean', 'false = failing run_results do not auto-create tst_bugs rows; QA must raise manually.', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  (4,'bug_fix_sla_hours',        '48',    'integer', 'Dashboard alert threshold: bugs in Assigned/In_Progress longer than this are flagged stale.', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  (5,'allow_multi_user_import',  'true',  'boolean', 'v7: If true, data from multiple user_codes can be imported into this DB (central mode).', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  (6,'central_mode',             'false', 'boolean', 'v7: true = this is the central aggregation DB; false = developer local DB.', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL)
  ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);


CREATE TABLE IF NOT EXISTS `tst_testing_table_list` (
    `id`            SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(30)  NOT NULL,  -- Short Name of Tables
    `name`          VARCHAR(60)  NOT NULL,  -- Actual Name of Table
    `description`   VARCHAR(255)  NULL,
    `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP     NULL,
    UNIQUE KEY `uq_tst_testingTableList_code` (`code`),
    UNIQUE KEY `uq_tst_testingTableList_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Seeder Data for Testing Table List
INSERT INTO `tst_testing_table_list` (`code`, `name`, `description`, `created_by`, `updated_by`, `deleted_by`, `created_at`, `updated_at`, `deleted_at`)
 VALUES
  ('TestCases', 'tst_test_cases', 'List of Test Cases for all the Screens of every Modules', 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TabsScreens', 'tst_tabs_screens', 'List of Tabs & Screens of every Modules', 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);


CREATE TABLE IF NOT EXISTS `tst_testing_table_field_list` (
    `id`            SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `table_id`      SMALLINT UNSIGNED  NOT NULL, -- FK to tst_testing_table_list.id
    `code`          VARCHAR(30)  NOT NULL,   -- Code for the Field (e.g., TestCaseType, TestMethod, TestTechnology, etc.)
    `name`          VARCHAR(60)  NOT NULL,   -- Actual Field Name in the table (e.g., test_case_type_code, test_method_code, test_technology_code, etc.)
    `description`   VARCHAR(255)  NULL,      -- Description of the field
    `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP     NULL,
    UNIQUE KEY `uq_tst_testingTableFieldList_code` (`table_id`, `code`),
    UNIQUE KEY `uq_tst_testingTableFieldList_name` (`table_code`, `name`),
    CONSTRAINT `fk_tst_testingTableFieldList_table_id` FOREIGN KEY (`table_id`) REFERENCES `tst_testing_table_list`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Seeder Data : tst_testing_table_field_list
INSERT INTO `tst_testing_table_field_list` (`table_code`, `code`, `name`, `description`, `created_at`, `updated_at`, `deleted_at`)
 VALUES
  ('1', 'TestCaseType', 'test_case_type_code', 'Test Case Type Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('1', 'TestMethod', 'test_method_code', 'Test Method Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('1', 'TestTechnology', 'test_technology_code', 'Test Technology Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('1', 'TestLayer', 'test_layer_code', 'Test Layer Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('1', 'TCCreationStatus', 'tc_creation_status', 'Test Case Creation Status Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('2', 'DevStatus', 'dev_status', 'Development Status', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('2', 'TcCreationStatus', 'tc_creation_status', 'Test Case Creation Status', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);


CREATE TABLE IF NOT EXISTS `tst_common_dropdown_master` (
    `id`                SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `table_id`        INT UNSIGNED  NOT NULL, -- FK to tst_testing_table_list.id
    `column_id`       INT UNSIGNED  NOT NULL, -- FK to tst_testing_table_field_list.id
    `display_order`     TINYINT UNSIGNED NOT NULL,  -- Sequence of Display Items in the Dropdown on UI
    `table_column_code` VARCHAR(41)  NOT NULL,  -- Auto Generated by Combining (table_code + column_code) and adding "_" in between (e.g., "TestCases_TestCaseType")
    `code`              VARCHAR(60)  NOT NULL,  -- Code to be used in Dropdown (e.g., Standard, Unit, Validation, Feature, Business_Condition, Manual, Automated, Dusk, Laravel, etc.)
    `name`              VARCHAR(100)  NOT NULL, -- Friendly name of the field (e.g., Standard, Unit, Validation, Feature, Business Condition, Manual, Automated, Dusk, Laravel, etc.)
    `description`       VARCHAR(255)  NULL,     -- Description of the Dropdown Item
    `is_active`         TINYINT(1)    NOT NULL DEFAULT 1,  -- 1 means this Dropdown Item is Active, 0 means In Active
    `created_by`        VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
    `updated_by`        VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
    `deleted_by`        VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
    `created_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP     NULL,
    UNIQUE KEY `uq_tst_commonDropdown_tableColCode` (`table_column_code`,`code`),
    UNIQUE KEY `uq_tst_commonDropdown_tableColumnCode` (`table_name`, `column_name`, `code`),
    UNIQUE KEY `uq_tst_commonDropdown_tableColumnDisplayOrder` (`table_name`, `column_name`, `display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Seeder Data : tst_common_dropdown_master
INSERT INTO `tst_common_dropdown_master` (`table_code`, `column_code`, `display_order`, `table_column_code`, `code`, `name`, `description`, `created_by`, `updated_by`, `deleted_by`, `created_at`, `updated_at`, `deleted_at`)
 VALUES
  ('TestCases','TestCaseType',1, 'TestCases_TestCaseType', 'Standard','-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestCaseType',2, 'TestCases_TestCaseType', 'Unit', 'Unit', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestCaseType',3, 'TestCases_TestCaseType', 'Validation', 'Validation','-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestCaseType',4, 'TestCases_TestCaseType', 'Feature', 'Feature','-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestCaseType',5, 'TestCases_TestCaseType', 'Business_Condition', 'Business Condition','-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestMethod',1, 'TestCases_TestMethod', 'Manual', 'Manual', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestMethod',2, 'TestCases_TestMethod', 'Automated', 'Automated', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestMethod',3, 'TestCases_TestMethod', 'Hybrid', 'Hybrid', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestTechnology',1, 'TestCases_TestTechnology', 'Dusk', 'Dusk', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestTechnology',2, 'TestCases_TestTechnology', 'Laravel-Unit', 'Laravel-Unit', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestTechnology',3, 'TestCases_TestTechnology', 'Native', 'Native', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',1, 'TestCases_TestLayer', 'GUI', 'GUI', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',2, 'TestCases_TestLayer', 'API', 'API', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',3, 'TestCases_TestLayer', 'Unit', 'Unit', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',4, 'TestCases_TestLayer', 'Integration', 'Integration', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',5, 'TestCases_TestLayer', 'Performance', 'Performance', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',6, 'TestCases_TestLayer', 'Security', 'Security', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',7, 'TestCases_TestLayer', 'Accessibility', 'Accessibility', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases','TestLayer',8, 'TestCases_TestLayer', 'Other', 'Other', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',1, 'TestCases_TcCreationStatus', 'Pending', 'Pending', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',2, 'TestCases_TcCreationStatus', 'In-Progress', 'In-Progress', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',3, 'TestCases_TcCreationStatus', 'Completed', 'Completed', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',4, 'TestCases_TcCreationStatus', 'Error', 'Error', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',5, 'TestCases_TcCreationStatus', 'Hold', 'Hold', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',6, 'TestCases_TcCreationStatus', 'Not-Required', 'Not-Required', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',1, 'TestCases_DevStatus', 'Pending', 'Pending', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',2, 'TestCases_DevStatus', 'Under-Development', 'Under-Development', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',3, 'TestCases_DevStatus', 'In-Review', 'In-Review', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',4, 'TestCases_DevStatus', 'Ready-For-Testing', 'Ready-For-Testing', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',5, 'TestCases_DevStatus', 'Testing-InProgress', 'Testing-InProgress', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',6, 'TestCases_DevStatus', 'Testing-Completed', 'Testing-Completed', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',7, 'TestCases_DevStatus', 'Error', 'Error', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',8, 'TestCases_DevStatus', 'Hold', 'Hold', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'DevStatus',9, 'TestCases_DevStatus', 'Not-Required', 'Not-Required', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',1, 'TestCases_TcCreationStatus', 'Pending', 'Pending', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',2, 'TestCases_TcCreationStatus', 'In-Progress', 'In-Progress', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',3, 'TestCases_TcCreationStatus', 'Completed', 'Completed', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',4, 'TestCases_TcCreationStatus', 'Error', 'Error', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',5, 'TestCases_TcCreationStatus', 'Hold', 'Hold', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('TestCases', 'TCCreationStatus',6, 'TestCases_TcCreationStatus', 'Not-Required', 'Not-Required', '-', 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);


-- ============================================================================
-- SECTION 1: MASTERS
-- ============================================================================

-- Tab : Settings
-- This Table will store drop down values for Testing Application
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_common_test_case_master`(
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `master_type`   ENUM('test_case_type','testing_type', 'testing_technology', 'testing_layer', 'status') NOT NULL,
  `code`          VARCHAR(20) NOT NULL,           -- 'Standard','Unit','Validation','Feature','Business_Condition'
  `name`          VARCHAR(100) NULL,
  `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_common_test_case_master_code` (`code`),
  INDEX `idx_tst_common_test_case_master_active` (`is_active`),
  CONSTRAINT `fk_tst_common_test_case_master_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_common_test_case_master_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_common_test_case_master_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seeder for tst_common_test_case_master
INSERT INTO `tst_common_test_case_master` (`master_type`, `code`, `name`, `ordinal`, `is_active`, `created_by`, `updated_by`, `deleted_by`, `created_at`, `updated_at`, `deleted_at`)
  VALUES
  ('test_case_type', 'Standard', 'Standard', 1, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('test_case_type', 'Unit', 'Unit', 2, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('test_case_type', 'Validation', 'Validation', 3, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('test_case_type', 'Feature', 'Feature', 4, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('test_case_type', 'Business_Condition', 'Business Condition', 5, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_type', 'Manual', 'Manual', 1, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_type', 'Automated', 'Automated', 2, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_technology', 'Dusk', 'Dusk', 1, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_technology', 'Laravel-Unit', 'Laravel-Unit', 2, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'GUI', 'GUI', 1, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'API', 'API', 2, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'Unit', 'Unit', 3, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'Integration', 'Integration', 4, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'Performance', 'Performance', 5, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'Security', 'Security', 6, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'Accessibility', 'Accessibility', 7, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('testing_layer', 'Other', 'Other', 8, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('automation_status', 'Manual', 'Manual', 1, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('automation_status', 'Automated', 'Automated', 2, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('automation_status', 'In_Progress', 'In Progress', 3, 1, 'admin', 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);


-- Lightweight local user table — not synced with prime_ai sys_users.
-- PK is `code` VARCHAR(5) (e.g. 'brij', 'tarun', 'sys').
-- This is a CATALOG table — same across all developer machines.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_users` 
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code`          VARCHAR(10) NOT NULL,           -- 'admin', 'brij', 'shail', 'samer', 'tarun', 'Gaurv'. This will be used as login user & Uniq Identifier.
  `name`          VARCHAR(50) NOT NULL,
  `email`         VARCHAR(100) NOT NULL,
  `password`      VARCHAR(512) NOT NULL,          -- Hashed Password
  `role`          ENUM('Admin','Architect','QA_Lead','Tester','Developer','Reviewer') NULL DEFAULT 'Tester',
  `is_superuser`  TINYINT(1) NOT NULL DEFAULT 0,
  `is_system`     TINYINT(1) NOT NULL DEFAULT 0,  -- If true, this user is a system user and Can not be deleted.
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NULL,              -- FK to tst_users.id
  `updated_by`    INT UNSIGNED NULL,              -- FK to tst_users.id
  `deleted_by`    INT UNSIGNED NULL,              -- FK to tst_users.id
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_users_code` (`code`),
  UNIQUE KEY `uq_tst_users_email` (`email`),
  INDEX `idx_tst_users_active` (`is_active`),
  INDEX `idx_tst_users_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed: system user for Auto_Retest and scheduled run attribution
INSERT INTO `tst_users` (`code`, `name`, `email`, `password`, `role`, `is_superuser`, `is_system`, `is_active`, `created_by`, `updated_by`, `deleted_by`, `created_at`, `updated_at`, `deleted_at`)
  VALUES
  ('super', 'Super_User', 'super@prime-testing.local', '$2y$12$placeholder_super_hash', 'Admin', 1, 1, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('admin', 'Administrator', 'admin@prime-testing.local', '$2y$12$placeholder_admin_hash', 'Admin', 0, 1, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('sys', 'System', 'system@prime-testing.local', '$2y$12$placeholder_sys_hash', 'Admin', 0, 1, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('brijesh', 'Brijesh', 'brij@prime-testing.local', '$2y$12$placeholder_brij_hash', 'Admin', 0, 0, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('tarun', 'Tarun', 'tarun@prime-testing.local', '$2y$12$placeholder_tarun_hash', 'Developer', 0, 0, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('shailesh', 'Shailesh', 'shail@prime-testing.local', '$2y$12$placeholder_shail_hash', 'Developer', 0, 0, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('sameer', 'Sameer', 'samer@prime-testing.local', '$2y$12$placeholder_samer_hash', 'Tester', 0, 0, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
  ('gaurav', 'Gaurav', 'gaurv@prime-testing.local', '$2y$12$placeholder_gaurv_hash', 'Developer', 0, 0, 1, 'super', 'super', 'super', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL)
  ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);


-- Module → Category → Main Menu → [Sub Menu (optional)] → Tab → Test Case
-- All CATALOG tables: simple INT PK, same data across all developer machines.
-- ----------------------------------------------------------------------------
-- 1.1: Modules discovered from /prime_ai/Modules/*
CREATE TABLE IF NOT EXISTS `tst_modules` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_code`   VARCHAR(5) NOT NULL,                  -- Folder name, e.g. 'SLB', 'LIB', 'SCH', 'COR', 'BIL'
  `name`          VARCHAR(60) NOT NULL,                 -- Folder name, e.g. 'Syllabus', 'Library', 'School Setup'
  `description`   VARCHAR(255) NULL,                    -- Display name, e.g. 'Syllabus Management', 'Library Management', 'School Setup'
  `folder_name`   VARCHAR(60) NULL,                     -- Folder name, e.g. 'Syllabus', 'Library', 'SchoolSetup'
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `version`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_modules_code` (`module_code`),
  INDEX `idx_tst_modules_active` (`is_active`),
  CONSTRAINT `fk_tst_modules_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_modules_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_modules_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 1.2: Categories (top-level RBS grouping, e.g. 'School Setup', 'LMS')
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_categories` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_code`   VARCHAR(5) NOT NULL,           -- FK to tst_modules.module_code e.g. SLB, SCH
  `cat_code`      VARCHAR(3) NOT NULL,           -- Category Code e.g. T01, T02
  `name`          VARCHAR(120) NOT NULL,           -- e.g. 'School Setup'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_categories_module` (`module_code`),
  INDEX `idx_tst_categories_active` (`is_active`),
  UNIQUE KEY `uq_tst_categories_module_catcode` (`cat_code`),
  UNIQUE KEY `uq_tst_categories_module_name` (`module_code`, `name`),
  CONSTRAINT `fk_tst_categories_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_categories_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_categories_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_categories_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 1.3: Main Menus (e.g. 'Syllabus Mgmt.')
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_main_menus` (
  `id`             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_code`    VARCHAR(5) NOT NULL,            -- FK to tst_modules.module_code e.g. SLB
  `cat_code`       VARCHAR(3) NOT NULL,            -- FK to tst_categories.cat_code e.g. T01
  `mm_code`        VARCHAR(5) NOT NULL,            -- Main Menu Code e.g. T0104, T0105 etc.
  `name`           VARCHAR(120) NOT NULL,
  `route_url`      VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `sort_order`     SMALLINT UNSIGNED DEFAULT 1,
  `is_active`      TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`     VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`     VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`     VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`     TIMESTAMP NULL,
  INDEX `idx_tst_mainMenus_category` (`cat_code`),
  INDEX `idx_tst_mainMenus_active` (`is_active`),
  UNIQUE KEY `uq_tst_mainMenus_category_name` (`mm_code`),
  CONSTRAINT `fk_tst_mainMenus_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_mainMenus_category` FOREIGN KEY (`cat_code`) REFERENCES `tst_categories`(`cat_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_mainMenus_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_mainMenus_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_mainMenus_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 1.4: Sub Menus (one View/Screen, e.g. 'Syllabus Master')
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
  `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_code`      VARCHAR(5) NOT NULL,            -- FK to tst_modules.module_code e.g. SLB
  `cat_code`         VARCHAR(3) NOT NULL,            -- FK to tst_categories.cat_code e.g. T01
  `mm_code`          VARCHAR(5) NOT NULL,            -- FK to tst_main_menus.main_menu_code e.g. T0104, T0105 etc.
  `sm_code`          VARCHAR(7) NOT NULL,            -- Sub Menu Code e.g. T010401, T010402, T010501 etc.
  `name`             VARCHAR(120) NOT NULL,
  `route_url`        VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `sort_order`       SMALLINT UNSIGNED DEFAULT 1,
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`       VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`       VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`       VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  INDEX `idx_tst_tsm_moduleMmSubmenu` (`module_code`, `cat_code`, `mm_code`, `sm_code`),
  INDEX `idx_tst_tsm_active` (`is_active`),
  UNIQUE KEY `uq_tst_tsm_subMenu` (`sm_code`),
  CONSTRAINT `fk_tst_tsm_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tsm_category` FOREIGN KEY (`cat_code`) REFERENCES `tst_categories`(`cat_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tsm_mainMenu` FOREIGN KEY (`mm_code`) REFERENCES `tst_main_menus`(`mm_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tsm_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_tsm_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_tsm_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tab-1.5: Tabs (one Tab = one feature folder under tests/Browser/Modules/{Module}/{Feature})
-- A Tab attaches either to a Sub Menu OR directly to a Main Menu (sub_menu_id nullable).
-- See requirement_v3.md §0.1 — "Screen" definition for FR-10 retest scope.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_tabs_screens` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_code`        VARCHAR(5) NOT NULL,            -- FK to tst_modules.module_code e.g. SLB
  `cat_code`           VARCHAR(3) NOT NULL,            -- FK to tst_categories.cat_code e.g. T01
  `mm_code`            VARCHAR(5) NOT NULL,            -- FK to tst_main_menus.main_menu_code e.g. T0104, T0105 etc.
  `sm_code`            VARCHAR(7) NOT NULL,            -- Sub Menu Code e.g. T010401, T010402, T010501 etc.
  `ts_code`            VARCHAR(11) NOT NULL,            -- Tab/Screen Code e.g. T0104010100, T0104010200, T0105010100 etc.
  `name`               VARCHAR(120) NOT NULL,           -- e.g. 'Lessons', 'Topic Types'
  `route_url`          VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `folder_path`        VARCHAR(500) NULL,               -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson'
  `is_excluded`        TINYINT(1) NOT NULL DEFAULT 0,   -- manually marked "out of scope" (excluded from catalog/UI but not deleted)
  `dev_status`         ENUM('Pending','Under-Development','In-Review','Ready-For-Testing','Testing-InProgress','Testing-Completed', 'Error', 'Hold', 'Not-Required'),
  `tc_creation_status` ENUM('Pending','In-Progress','Completed', 'Error', 'Hold', 'Not-Required'),
  `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`         VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`         VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`         VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`         TIMESTAMP NULL,
  INDEX `idx_tst_tabs_moduleMmSubmenu` (`module_code`, `cat_code`, `mm_code`, `sm_code`, `ts_code`),
  INDEX `idx_tst_tabs_active` (`is_active`),
  UNIQUE KEY `uq_tst_tabs_tabScreen` (`ts_code`),
  CONSTRAINT `fk_tst_tabs_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_category` FOREIGN KEY (`cat_code`) REFERENCES `tst_categories`(`cat_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_mainMenu` FOREIGN KEY (`mm_code`) REFERENCES `tst_main_menus`(`mm_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_subMenu` FOREIGN KEY (`sm_code`) REFERENCES `tst_sub_menus`(`sm_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_tabs_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_tabs_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- Removed `sort_order` filed as shoring can be done on `ts_code`
-- ts_code is a combination of cat_code+mm_code+ss_code+ts_code(last 4 digit) e.g. T0104010100
-- 1st 1 Character is Application Type (T-Tenant, P-Prime, G-Global, S-Student/Parent, M-Mobile App)
-- 2nd-3rd Digits are Category Code (Cat_code)
-- 4th-5th Digits are Main Menu Code (Mm_code)
-- 6th-7th Digits are Sub Menu Code (Sm_code)
-- 8th-9th Digits are Tab Code (Ts_code)
-- 10th-11th Digits are Sub-Tab Code (if there is any). Mostly last 2 Digits are 00.


-- ============================================================================
-- SECTION 2: TEST CASE CREATION
-- ============================================================================


-- CATALOG table — simple INT PK. Same rows across all developer machines
-- (synced from the shared prime_ai codebase).
-- -----------------------------------------------------------------------------
-- One row per discoverable test method (or 'Not_Automated' entry from requirements.md)
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
  `id`                      INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `user_code`               VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `ts_code`                 VARCHAR(11) NOT NULL,             -- FK to tst_tabs_screens (It is a combination of cat_code+mm_code+ss_code+ts_code(last 4 digit))
  `test_case_code`          SMALLINT UNSIGNED NOT NULL,       -- Unique Test Case Code (Incremental Number for User+ts_code)
  `module_code`             VARCHAR(5) NOT NULL,              -- FK to tst_modules, denormalized for fast module-level filtering
  `file_path`               VARCHAR(500) NOT NULL,            -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson/LessonPlanningTest.php'
  `namespace`               VARCHAR(255) NULL,                -- e.g. 'Tests\Browser\Modules\Syllabus\Lesson'
  `class_name`              VARCHAR(150) NOT NULL DEFAULT '', -- e.g. 'LessonPlanningTest'
  `method_name`             VARCHAR(150) NOT NULL DEFAULT '', -- e.g. 'test_updating_lesson_planning_dates'; '' for not-automated entries
  `display_name`            VARCHAR(255) NOT NULL,            -- humanized name shown in UI
  `description`             TEXT NULL,                        -- docblock summary / notes
  `test_case_type_code`     VARCHAR(20) NOT NULL,             -- FK to tst_common_test_case_master.code (e.g. Standard, Validation, UI, API, Security, Performance, Accessibility, Other)
  `test_method_code`        VARCHAR(20) NOT NULL,             -- FK to tst_common_test_case_master.code (e.g. Manual, Automated, Hybrid)
  `test_technology_code`    VARCHAR(20) NOT NULL,             -- FK to tst_common_test_case_master.code (e.g. Laravel, Vue, Native, Laravel-Unit, Dusk, Other)
  `test_layer_code`         VARCHAR(20) NOT NULL,             -- FK to tst_common_test_case_master.code (e.g. GUI, API, Unit, Integration, Performance, Security, Accessibility, Other)
  `tc_creation_status`      VARCHAR(20) NOT NULL,             -- FK to tst_common_test_case_master.code (e.g. Pending, In-Progress, Completed, Error, Hold, Not-Required)
  `requirements_md_path`    VARCHAR(500) NULL,                -- relative path to requirements.md, if any
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,    -- set to 0 by Sync if no longer found on disk
  `created_by`              VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `updated_by`              VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `deleted_by`              VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`              TIMESTAMP NULL,
  INDEX `idx_tst_testCases_tab` (`ts_code`),
  INDEX `idx_tst_testCases_module` (`module_code`),
  INDEX `idx_tst_testCases_active` (`is_active`),
  INDEX `idx_tst_testCases_status` (`status_code`),
  UNIQUE KEY `uq_tst_testCases_userTestCaseCode` (`user_code`, `ts_code`, `test_case_code`),
  CONSTRAINT `fk_tst_testCases_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_tab` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_testCaseType` FOREIGN KEY (`test_case_type_code`) REFERENCES `tst_common_test_case_master`(`code`),
  CONSTRAINT `fk_tst_testCases_testingType` FOREIGN KEY (`testing_type_code`) REFERENCES `tst_common_test_case_master`(`code`),
  CONSTRAINT `fk_tst_testCases_testingTechnology` FOREIGN KEY (`testing_technology_code`) REFERENCES `tst_common_test_case_master`(`code`),
  CONSTRAINT `fk_tst_testCases_testingLayer` FOREIGN KEY (`testing_layer_code`) REFERENCES `tst_common_test_case_master`(`code`),
  CONSTRAINT `fk_tst_testCases_status` FOREIGN KEY (`status_code`) REFERENCES `tst_common_test_case_master`(`code`),
  CONSTRAINT `fk_tst_testCases_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
  -- Removed `sort_order` filed as shoring can be done on `test_case_code`

-- Example Data for reference only:
  -- test_case_type : Standard, Validation, UI, API, Security, Performance, Accessibility, Other
  -- testing_type : Manual, Automated, Hybrid
  -- testing_technology : Laravel, Vue, Native, Laravel-Unit, Dusk, Other
  -- testing_layer : GUI, API, Unit, Integration, Performance, Security, Accessibility, Other
  -- status : Pending, In_Progress, Not_Run, 


-- ============================= Completed till Here only =========================================================

-- ============================================================================
-- SECTION 3: TEST EXECUTION & HISTORY
-- TRANSACTION tables — composite PK (id, user_code).
-- FK chains propagate user_code so parent/child rows share the same developer context.
-- ============================================================================

-- 3.1: One row per "Run" click — batch execution of one or more test cases.
-- user_code = developer who clicked Run (or 'sys' for Auto_Retest / Scheduled).
-- v7: executed_by merged into user_code (same semantics, now part of composite PK).
CREATE TABLE IF NOT EXISTS `tst_test_runs` (
  `id`                     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_uuid`               BINARY(16) NOT NULL,  -- UUID (16 bytes) in binary format (This is unique row identifier for this table)
  `executed_by`            VARCHAR(10) NULL,     -- FK tst_users.code; nullable for scheduled/system/auto-retest runs
  `trigger_type`           ENUM('Manual','Scheduled','Rerun','Auto_Retest') NOT NULL DEFAULT 'Manual',  -- v5: 'Auto_Retest' added for FR-10
  `command`                VARCHAR(1000) NULL,   -- exact artisan dusk command executed
  `status`                 ENUM('Queued','Running','Completed','Failed','Cancelled') NOT NULL DEFAULT 'Queued',  -- v5: 'Failed' added for FR-8
  `started_at`             DATETIME NULL,
  `finished_at`            DATETIME NULL,
  `duration_seconds`       DECIMAL(10,2) NULL,
  `exit_code`              SMALLINT NULL,
  `total_tc_count`         MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
  `passed_tc_count`        MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
  `failed_tc_count`        MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
  `skipped_tc_count`       MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
  `total_assertion_count`  MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,  -- total assertions across all test cases e.g. 100
  `passed_assertion_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,  -- total assertions across all test cases e.g. 100
  `failed_assertion_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,  -- total assertions across all test cases e.g. 100
  `raw_output_path`        VARCHAR(500) NULL,                      -- relative path under storage/app/test-runs/{run_id}/
  `environment_json`       JSON NULL,                              -- PHP/Chrome versions, APP_ENV, etc. 
  `created_by`             VARCHAR(10) NOT NULL,                   -- FK to tst_users.code
  `updated_by`             VARCHAR(10) NOT NULL,                   -- FK to tst_users.code
  `deleted_by`             VARCHAR(10) NOT NULL,                   -- FK to tst_users.code
  `created_at`             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`             TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_testRuns_runuuid` (`run_uuid`),
  INDEX `idx_tst_testRuns_executedBy` (`executed_by`),
  INDEX `idx_tst_testRuns_status` (`status`),
  INDEX `idx_tst_testRuns_startedAt` (`started_at`),
  CONSTRAINT `fk_tst_testRuns_executedBy` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRuns_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRuns_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRuns_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- Removed `scope_json` becuse we will use `tst_test_run_items` table to store the test cases run detail.
-- Assertion - Count of how many checks that test performed to compare the Expected value vs Actual value.
-- Example : 
-- -----------------------------------------------------------------------------------------------------------------------------
-- Column                 What It Stores		                                Example
-- ----------------------  ------------------------------------------------  ---------------------------------------------------
-- display_name            Name of the test		                               "Create Driver Test"
-- status                  Overall result of the test	                       'Passed' or 'Failed'
-- assertions              Count of Expected vs Actual checks performed	     4
-- duration_seconds        Time taken to run all checks	                     0.45
-- error_message           If any check failed, why it failed	               "Failed asserting that 50 matches expected 40"
-- -----------------------------------------------------------------------------------------------------------------------------


-- 3.2: One row per test case selected in a run (links to test_runs + test_cases).
-- If a test case is re-run, a new row is added with the same run_uuid so history is preserved.
CREATE TABLE IF NOT EXISTS `tst_test_run_items` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_item_uuid` BINARY(16) NOT NULL,     -- UUID (16 bytes) in binary format (This is unique row identifier for this table)
  `run_uuid`      BINARY(16) NOT NULL,     -- FK to tst_test_runs.run_uuid (This is `run_uuid` field of `tst_test_runs` table)
  -- Inplace of `tst_test_cases.id`, I am using (Composite Key of `tst_user_tab_test_codes`) `user_code`, `ts_code`, `test_case_code` 
  `user_code`               VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `ts_code`                 VARCHAR(11) NOT NULL,             -- FK to tst_tabs_screens
  `test_case_code`          SMALLINT UNSIGNED NOT NULL,       -- Unique Test Case Code (Incremental Number for User+ts_code)
  --
  `module_code`             VARCHAR(5) NOT NULL,              -- FK to tst_modules, denormalized for fast module-level filtering
  `created_by`    VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_testRunItems_run_ts_testCase` (`run_uuid`, `ts_code`, `test_case_id`),
  INDEX `idx_tst_testRunItems_run` (`run_uuid`),
  INDEX `idx_tst_testRunItems_tab` (`ts_code`),
  INDEX `idx_tst_testRunItems_testCase` (`test_case_id`),
  CONSTRAINT `fk_tst_testRunItems_run` FOREIGN KEY (`run_uuid`) REFERENCES `tst_test_runs`(`run_uuid`),
  CONSTRAINT `fk_tst_userTabTestCode` FOREIGN KEY (`user_code`, `ts_code`, `test_case_code`) REFERENCES `tst_test_cases`(`user_code`, `ts_code`, `test_case_code`),
  CONSTRAINT `fk_tst_testRunItems_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunItems_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunItems_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2: One row per test case within a run.
-- bug_id + bug_user_code added via ALTER at end of file (forward reference to tst_bugs).
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_result_uuid`       BINARY(16) NOT NULL,     -- UUID (16 bytes) in binary format (This is unique row identifier for this table)
  `run_uuid`              BINARY(16) NOT NULL,     -- FK tst_test_runs.run_uuid (This is `run_uuid` field of `tst_test_runs` table)
  `run_item_uuid`         BINARY(16) NOT NULL,     -- FK tst_test_run_items.run_item_uuid (This is `run_item_uuid` field of `tst_test_run_items` table)
  `executed_by`           VARCHAR(10) NULL,        -- FK tst_users.code; nullable for scheduled/system/auto-retest runs
  `bug_id`                INT UNSIGNED NULL,       -- FK tst_bugs.id (nullable: keep history if bug later removed)
  `display_name`          VARCHAR(255) NOT NULL,   -- snapshot of test name at run time
  `status`                ENUM('Passed','Failed','Skipped','Error') NOT NULL,
  `duration_seconds`      DECIMAL(10,2) NULL,
  `assertions`            INT UNSIGNED NOT NULL DEFAULT 0, -- Count of how many checks that test performed to compare the Expected value vs Actual value.
  `error_message`         TEXT NULL,
  `error_trace`           TEXT NULL,
  `screenshot_path`       VARCHAR(500) NULL,       -- failure screenshot, relative to storage/app/test-runs/{run_id}/screenshots/
  `console_log_path`      VARCHAR(500) NULL,
  `source_html_path`      VARCHAR(500) NULL,
  `created_by`            VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `updated_by`            VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `deleted_by`            VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL,
  INDEX `idx_tst_testRunResults_run` (`run_uuid`),
  INDEX `idx_tst_testRunResults_runItem` (`run_item_uuid`),
  INDEX `idx_tst_testRunResults_status` (`status`),
  INDEX `idx_tst_testRunResults_bug` (`bug_id`),
  CONSTRAINT `fk_tst_testRunResults_run` FOREIGN KEY (`run_uuid`) REFERENCES `tst_test_runs`(`run_uuid`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testRunResults_runItem` FOREIGN KEY (`run_item_uuid`) REFERENCES `tst_test_run_items`(`run_item_uuid`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testRunResults_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_testRunResults_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunResults_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunResults_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--   1. `bug_id` and `bug_user_code` are nullable: keep history if bug is later removed.
--   2. `test_case_id` is nullable: keep history if test case is later removed.
--   3. `run_uuid` is nullable: keep history if run is later removed.
--   4. `executed_by` is nullable: keep history if user is later removed.


-- 3.3: Rolling per-test-case statistics for fast dashboard queries (FR-5).
-- This will provide the status of last run for each test case for each user.
-- Dashboard will show by Grouping of (user_code, ts_code, test_case_code)
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  -- Identify Test Case in tst_test_cases table using (user_code, ts_code, test_case_code)
  `user_code`             VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `ts_code`               VARCHAR(11) NOT NULL,             -- FK to tst_tabs_screens
  `test_case_code`        SMALLINT UNSIGNED NOT NULL,       -- Unique Test Case Code (Incremental Number for User+ts_code)  
  -- Mapping with latest test run in tst_test_run_results table using last_run_result_uuid
  `last_run_result_uuid`  BINARY(16) NULL,                  -- FK tst_test_run_results.run_result_uuid
  `executed_by`           VARCHAR(10) NULL,                 -- FK tst_users.code; nullable for scheduled/system/auto-retest runs
  `last_status`           ENUM('Passed','Failed','Skipped','Error') NULL,
  `last_run_at`           DATETIME NULL,
  -- Run Statistics
  `consecutive_failures`  SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- Number of consecutive failures for this test case by this user
  `total_runs`            INT UNSIGNED NOT NULL DEFAULT 0,  -- Total runs for this test case by this user
  `total_passed`          INT UNSIGNED NOT NULL DEFAULT 0,  -- Total passed runs for this test case by this user
  `total_failed`          INT UNSIGNED NOT NULL DEFAULT 0,  -- Total failed runs for this test case by this user
  `total_skipped`         INT UNSIGNED NOT NULL DEFAULT 0,  -- Total skipped runs for this test case by this user
  `pass_rate`             DECIMAL(5,2)  NULL,               -- 0.00–100.00 -- Pass rate of this test case by this user in last 30 days
  `avg_duration_seconds`  DECIMAL(10,2) NULL,               -- Average execution time of this test case by this user
  `is_flaky`              TINYINT(1)    NOT NULL DEFAULT 0, -- A test is considered Flaky if Test Case Status toggles between Passed and Failed across consecutive runs without any Application Code changes.
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX  `idx_tst_caseSummary_lastStatus`  (`last_status`),
  INDEX  `idx_tst_caseSummary_flaky`       (`is_flaky`),
  INDEX  `idx_tst_caseSummary_userCode`    (`user_code`),
  CONSTRAINT `fk_tst_caseSummary_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseSummary_userTsTcCode` FOREIGN KEY (`user_code`, `ts_code`, `test_case_code`) REFERENCES `tst_test_cases`(`user_code`, `ts_code`, `test_case_code`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseSummary_lastRunResult` FOREIGN KEY (`last_run_result_uuid`) REFERENCES `tst_test_run_results`(`run_result_uuid`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseSummary_createdBy` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 4: ANNOTATIONS, SYNC LOG, SCHEDULES
-- ============================================================================

-- 4.1: User notes on a run or a specific result (FR-7).
-- v7: user_code in PK = the annotator (merged from created_by).
CREATE TABLE IF NOT EXISTS `tst_run_annotations` (
  `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`      VARCHAR(5)    NOT NULL,               -- the annotator (Person who written Notes for a specific Result)
  `run_item_uuid`  BINARY(16)    NOT NULL,               -- FK tst_test_run_items.run_item_uuid (This is `run_item_uuid` field of `tst_test_run_items` table)
  `comment`        VARCHAR(255)  NOT NULL,               -- Comment added by user for specific result.
  `note`           TEXT          NULL,                   -- Detailed note added by user for specific result.
  `is_known_issue` TINYINT(1)    NOT NULL DEFAULT 0,     -- excludes from flaky-test alerts
  `created_by`            VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `updated_by`            VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `deleted_by`            VARCHAR(10) NOT NULL,    -- FK to tst_users.code
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_runAnnotations_run_runItem_userCode` (`user_code`,`run_item_uuid`),
  CONSTRAINT `fk_tst_runAnnotations_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_runResult` FOREIGN KEY (`user_code`, `run_item_uuid`) REFERENCES `tst_test_run_items`(`user_code`, `run_item_uuid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 4.2: History of catalog discovery/sync runs.
-- v7: user_code in PK = sync executor (merged from created_by).
-- Capture audit history of All Testing Masters during 3 processes (Discovery / Test Case Execution / Data Import).
CREATE TABLE IF NOT EXISTS `tst_discovery_sync_logs` (
  `id`                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`             VARCHAR(5)    NOT NULL,         -- who triggered the sync
  `sync_mode`             ENUM('Discover','Import') NOT NULL DEFAULT 'Discover',  -- 'Discover' = Discovered from folder path. 'Import' = Imported from file. 
  `import_format`         ENUM('CSV','Excel') NULL,         -- only for import mode
  `folder_path`           VARCHAR(255)  NULL,             -- path to the folder imported
  `file_name`             VARCHAR(255)  NULL,             -- name of the file imported
  `file_path`             VARCHAR(255)  NULL,             -- path to the file imported
  `started_at`            DATETIME      NOT NULL,
  `finished_at`           DATETIME      NULL,
  `status`                ENUM('Running','Success','Failed') NOT NULL DEFAULT 'Running',
  `modules_found`         INT UNSIGNED  NOT NULL DEFAULT 0,
  `tabs_found`            INT UNSIGNED  NOT NULL DEFAULT 0,
  `test_cases_added`      INT UNSIGNED  NOT NULL DEFAULT 0,
  `test_cases_updated`    INT UNSIGNED  NOT NULL DEFAULT 0,
  `test_cases_removed`    INT UNSIGNED  NOT NULL DEFAULT 0,
  `details_json`          JSON          NULL,
  `error_message`         TEXT          NULL,
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_dsl_status`     (`status`),
  INDEX  `idx_tst_dsl_startedAt`  (`started_at`),
  INDEX  `idx_tst_dsl_userCode`   (`user_code`),
  CONSTRAINT `fk_tst_dsl_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
-- Maintains an audit history of Test Catalog Discovery & Data Import operations during 3 processes. 
-- 1. Test Catalog Discovery Process for Module folders, Category, Main Menu, Sub-Menu, Tab/Screen, Test Cases & Test Steps.
-- 2. During Automated Test Case Execution Process ( Execution of test cases from Modules folder)
-- 3. During Data Import Process ( Importing test cases from CSV/Excel files)


-- 4.3: Scheduled run definitions — CATALOG table, simple PK.
-- v7: last_run_id changed to VARCHAR(64) referencing tst_test_runs.run_id (UNIQUE KEY)
-- instead of the INT PK, to avoid a composite FK from a catalog table.
CREATE TABLE IF NOT EXISTS `tst_schedules` (
  `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(150) NOT NULL,
  `scope_json`       JSON NOT NULL,
  `cron_expression`  VARCHAR(100) NOT NULL,
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `last_run_id`      VARCHAR(64) NULL,                  -- v7: references tst_test_runs.run_id (unique business key)
  `created_at`       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP    NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_schedules_name` (`name`),
  INDEX  `idx_tst_schedules_active` (`is_active`),
  CONSTRAINT `fk_tst_schedules_lastRun` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`run_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 5: TEST CASE REQUIREMENTS BACKLOG (FR-8)
-- Backlog of new/updated test cases needed as Prime-AI is enhanced.
-- TRANSACTION table — composite PK (id, user_code).
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_test_case_requirements` (
  `id`                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`             VARCHAR(5)    NOT NULL,         -- developer who created this requirement entry
  `module_id`             INT UNSIGNED  NOT NULL,
  `main_menu_id`          INT UNSIGNED  NULL,
  `sub_menu_id`           INT UNSIGNED  NULL,
  `tab_id`                INT UNSIGNED  NULL,             -- NULL if the tab itself is new/proposed
  `proposed_tab_name`     VARCHAR(120)  NULL,             -- when tab_id is NULL
  `proposed_folder_path`  VARCHAR(500)  NULL,             -- proposed tests/Browser/... path for the new Tab
  `title`                 VARCHAR(255)  NOT NULL,
  `description`           TEXT          NULL,
  `priority`              ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `target_release`        VARCHAR(60)   NULL,             -- e.g. '2026.07 Release'
  `requested_by`          VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED → tst_users(id)
  `assigned_to`           VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED → tst_users(id); role='Tester'
  `status`                ENUM('Pending','In_Progress','Completed','Cancelled','Hold') NOT NULL DEFAULT 'Pending',
  `target_test_case_id`   INT UNSIGNED  NULL,             -- set once test case exists in catalog
  `completed_by`          VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED → tst_users(id)
  `completed_at`          DATETIME      NULL,
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP     NULL,
  PRIMARY KEY (`id`, `user_code`),
  INDEX `idx_tst_caseReq_module` (`module_id`),
  INDEX `idx_tst_caseReq_status` (`status`),
  INDEX `idx_tst_caseReq_priority` (`priority`),
  INDEX `idx_tst_caseReq_assignedTo` (`assigned_to`),
  INDEX `idx_tst_caseReq_userCode` (`user_code`),
  CONSTRAINT `fk_tst_caseReq_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_caseReq_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_subMenu` FOREIGN KEY (`sub_menu_id`) REFERENCES `tst_sub_menus`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_tab` FOREIGN KEY (`tab_id`) REFERENCES `tst_tabs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_requestedBy` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_assignedTo` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_targetTestCase` FOREIGN KEY (`target_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_completedBy` FOREIGN KEY (`completed_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 6: BUG TRACKING & DEVELOPER ASSIGNMENT (FR-9)
-- TRANSACTION tables — composite PK (id, user_code).
-- ============================================================================

-- 6.1: One row per tracked bug. Auto-created from a failing tst_test_run_results row,
-- or raised manually by QA.
CREATE TABLE IF NOT EXISTS `tst_bugs` (
  `id`                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`             VARCHAR(5)    NOT NULL,         -- developer/tester on whose machine bug was discovered
  `run_result_id`         INT UNSIGNED  NULL,             -- originating failure (nullable for manually-raised bugs)
  `test_case_id`          INT UNSIGNED  NOT NULL,
  `tab_id`                INT UNSIGNED  NOT NULL,         -- denormalized for FR-10 Screen scope
  `main_menu_id`          INT UNSIGNED  NOT NULL,         -- denormalized Screen scope (used when sub_menu_id IS NULL)
  `sub_menu_id`           INT UNSIGNED  NULL,             -- denormalized Screen scope for FR-10 retest
  `requirement_id`        INT UNSIGNED  NULL,             -- soft ref — no enforced FK (requirement may have different user_code)
  `requirement_user_code` VARCHAR(5)    NULL,             -- resolves requirement_id → tst_test_case_requirements in app layer
  `title`                 VARCHAR(255)  NOT NULL,
  `description`           TEXT          NULL,             -- defaults to error_message/trace, editable by QA
  `severity`              ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `status`                ENUM('Open','Assigned','In_Progress','Fixed','Retesting','Reopened','Closed','Escalated','Wont_Fix') NOT NULL DEFAULT 'Open',
  `assigned_to`           VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED; role='Developer'
  `assigned_by`           VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED; typically role='QA_Lead'
  `assigned_at`           DATETIME      NULL,
  `fixed_by`              VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED
  `fixed_at`              DATETIME      NULL,
  `fix_notes`             TEXT          NULL,
  `reopen_count`          SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- incremented each time FR-10 retest loop bounces this bug back
  `closed_by`             VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED; NULL when system-closed by passing retest
  `closed_at`             DATETIME      NULL,
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP     NULL,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_bugs_status`       (`status`),
  INDEX  `idx_tst_bugs_severity`     (`severity`),
  INDEX  `idx_tst_bugs_testCase`     (`test_case_id`),
  INDEX  `idx_tst_bugs_assignedTo`   (`assigned_to`),
  INDEX  `idx_tst_bugs_subMenu`      (`sub_menu_id`),
  INDEX  `idx_tst_bugs_mainMenu`     (`main_menu_id`),
  INDEX  `idx_tst_bugs_userCode`     (`user_code`),
  CONSTRAINT `fk_tst_bugs_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_runResult` FOREIGN KEY (`run_result_id`, `user_code`) REFERENCES `tst_test_run_results`(`id`, `user_code`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_bugs_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_tab` FOREIGN KEY (`tab_id`) REFERENCES `tst_tabs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_subMenu` FOREIGN KEY (`sub_menu_id`) REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_requirementUserCode` FOREIGN KEY (`requirement_user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_assignedTo` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_assignedBy` FOREIGN KEY (`assigned_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_fixedBy` FOREIGN KEY (`fixed_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_closedBy` FOREIGN KEY (`closed_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6.2: Audit trail of every bug status transition (FR-12).
CREATE TABLE IF NOT EXISTS `tst_bug_status_history` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`     VARCHAR(5)    NOT NULL,
  `bug_id`        INT UNSIGNED  NOT NULL,
  `from_status`   VARCHAR(20)   NULL,                    -- NULL on initial creation
  `to_status`     VARCHAR(20)   NOT NULL,
  `changed_by`    VARCHAR(5)    NULL,                    -- v7 FIXED: was INT UNSIGNED; NULL for system-driven transitions
  `note`          TEXT          NULL,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX `idx_tst_bugHistory_bug` (`bug_id`, `user_code`),
  INDEX `idx_tst_bugHistory_userCode` (`user_code`),
  CONSTRAINT `fk_tst_bugHistory_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugHistory_bug` FOREIGN KEY (`bug_id`, `user_code`) REFERENCES `tst_bugs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugHistory_changedBy` FOREIGN KEY (`changed_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 7: AUTOMATED BUG-FIX VERIFICATION LOOP (FR-10)
-- TRANSACTION tables — composite PK (id, user_code).
-- ============================================================================

-- 7.1: One row per auto-retest cycle triggered for a Screen after a bug is marked 'Fixed'.
CREATE TABLE IF NOT EXISTS `tst_retest_cycles` (
  `id`                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`           VARCHAR(5)    NOT NULL,
  `main_menu_id`        INT UNSIGNED  NOT NULL,        -- Screen scope when sub_menu_id IS NULL
  `sub_menu_id`         INT UNSIGNED  NULL,            -- Screen scope when Tab has a Sub Menu
  `triggered_by_bug_id` INT UNSIGNED  NOT NULL,        -- the bug whose 'Fixed' status started this cycle
  `cycle_number`        SMALLINT UNSIGNED NOT NULL DEFAULT 1, -- 1,2,3... per Screen+bug chain
  `run_id`              INT UNSIGNED  NULL,            -- the scoped Auto_Retest run
  `status`              ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `created_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_retestCycles_subMenu`   (`sub_menu_id`),
  INDEX  `idx_tst_retestCycles_mainMenu`  (`main_menu_id`),
  INDEX  `idx_tst_retestCycles_status`    (`status`),
  INDEX  `idx_tst_retestCycles_userCode`  (`user_code`),
  CONSTRAINT `fk_tst_retestCycles_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_retestCycles_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_subMenu` FOREIGN KEY (`sub_menu_id`) REFERENCES `tst_sub_menus`(`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_bug` FOREIGN KEY (`triggered_by_bug_id`, `user_code`) REFERENCES `tst_bugs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_run` FOREIGN KEY (`run_id`, `user_code`) REFERENCES `tst_test_runs`(`id`, `user_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7.2: Many-to-many — which open bugs were covered by a given retest cycle and per-bug outcome.
CREATE TABLE IF NOT EXISTS `tst_bug_retest_cycles_jnt` (
  `bug_id`           INT UNSIGNED  NOT NULL,
  `user_code`        VARCHAR(5)    NOT NULL,
  `retest_cycle_id`  INT UNSIGNED  NOT NULL,
  `outcome`          ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bug_id`, `user_code`, `retest_cycle_id`),
  INDEX  `idx_tst_bugRetest_cycle` (`retest_cycle_id`, `user_code`),
  INDEX  `idx_tst_bugRetest_userCode` (`user_code`),
  CONSTRAINT `fk_tst_bugRetest_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugRetest_bug` FOREIGN KEY (`bug_id`, `user_code`) REFERENCES `tst_bugs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugRetest_cycle` FOREIGN KEY (`retest_cycle_id`, `user_code`) REFERENCES `tst_retest_cycles`(`id`, `user_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 9 (NEW v7): SYSTEM-WIDE AUDIT LOG (FR-16)
-- Captures all CRUD operations across critical tables for full accountability.
-- TRANSACTION table — composite PK (id, user_code).
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_audit_logs` (
  `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`       VARCHAR(5)    NOT NULL,               -- who performed the action
  `table_name`      VARCHAR(60)   NOT NULL,               -- e.g. 'tst_bugs', 'tst_test_cases'
  `record_id`       VARCHAR(100)  NOT NULL,               -- stringified PK, e.g. '42' or '42|brij' for composite PKs
  `operation`       ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  `old_values_json` JSON          NULL,                   -- previous state (NULL for INSERT)
  `new_values_json` JSON          NULL,                   -- new state (NULL for DELETE)
  `ip_address`      VARCHAR(45)   NULL,
  `user_agent`      VARCHAR(500)  NULL,
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_auditLogs_tableName`  (`table_name`),
  INDEX  `idx_tst_auditLogs_userCode`   (`user_code`),
  INDEX  `idx_tst_auditLogs_operation`  (`operation`),
  INDEX  `idx_tst_auditLogs_createdAt`  (`created_at`),
  CONSTRAINT `fk_tst_auditLogs_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 10 (NEW v7): DATA EXPORT / IMPORT TRACKING (FR-20)
-- Tracks export bundles generated on developer machines for central import.
-- TRANSACTION table — composite PK (id, user_code).
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_data_exports` (
  `id`                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`           VARCHAR(5)    NOT NULL,           -- developer whose data is being exported
  `export_name`         VARCHAR(150)  NOT NULL,
  `export_type`         ENUM('Full','Incremental') NOT NULL DEFAULT 'Full',
  `date_from`           DATETIME      NULL,               -- filter: export transactions from this date
  `date_to`             DATETIME      NULL,               -- filter: export transactions up to this date
  `modules_json`        JSON          NULL,               -- array of module_ids; NULL = all modules
  `file_path`           VARCHAR(500)  NULL,               -- local path to the generated export file
  `status`              ENUM('Pending','In_Progress','Completed','Failed') NOT NULL DEFAULT 'Pending',
  `record_counts_json`  JSON          NULL,               -- e.g. {"tst_test_runs": 42, "tst_bugs": 15}
  `error_message`       TEXT          NULL,
  `exported_at`         DATETIME      NULL,
  `created_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_dataExports_status` (`status`),
  INDEX  `idx_tst_dataExports_userCode` (`user_code`),
  INDEX  `idx_tst_dataExports_exportedAt` (`exported_at`),
  CONSTRAINT `fk_tst_dataExports_userCode` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;








-- ============================================================================
-- SECTION 11: CONVENIENCE VIEWS
-- ============================================================================

-- Full catalog view: flattens hierarchy + latest run status per developer (FR-1).
-- v7: per-developer summary via LEFT JOIN on (test_case_id, user_code).
CREATE OR REPLACE VIEW `vw_test_case_catalog` AS
SELECT
  tc.id                                     AS test_case_id,
  m.id                                      AS module_id,
  m.name                                    AS module_name,
  c.id                                      AS category_id,
  c.name                                    AS category_name,
  mm.id                                     AS main_menu_id,
  mm.name                                   AS main_menu_name,
  sm.id                                     AS sub_menu_id,
  sm.name                                   AS sub_menu_name,
  COALESCE(sm.route_url, mm.route_url)      AS route_url,
  t.id                                      AS tab_id,
  t.name                                    AS tab_name,
  tc.display_name                           AS test_case_name,
  tc.test_type,
  tc.automation_status,
  tc.file_path,
  tc.method_name,
  cs.user_code,
  cs.last_status,
  cs.last_run_at,
  cs.pass_rate_30d,
  cs.is_flaky,
  tc.is_active
FROM `tst_test_cases` tc
JOIN `tst_tabs` t ON t.id = tc.tab_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = t.sub_menu_id
JOIN `tst_main_menus` mm ON mm.id = COALESCE(sm.main_menu_id, t.main_menu_id)
JOIN `tst_categories` c ON c.id = mm.category_id
JOIN `tst_modules` m ON m.id = tc.module_id
LEFT JOIN `tst_test_case_runs_summary` cs ON cs.test_case_id = tc.id;

-- Run history view: one row per run with executor name resolved.
CREATE OR REPLACE VIEW `vw_test_run_history` AS
SELECT
  r.id,
  r.run_id,
  r.user_code,
  u.name         AS executed_by_name,
  r.trigger_type,
  r.status,
  r.started_at,
  r.finished_at,
  r.duration_seconds,
  r.total,
  r.passed,
  r.failed,
  r.skipped,
  r.assertions,
  r.hostname
FROM `tst_test_runs` r
LEFT JOIN `tst_users` u ON u.code = r.user_code;

-- Open bugs with catalog context + assignee name (FR-9, FR-12).
CREATE OR REPLACE VIEW `vw_open_bugs` AS
SELECT
  b.id              AS bug_id,
  b.user_code,
  b.title,
  b.severity,
  b.status,
  m.name            AS module_name,
  mm.name           AS main_menu_name,
  sm.name           AS sub_menu_name,
  t.name            AS tab_name,
  tc.display_name   AS test_case_name,
  au.name           AS assigned_to_name,
  ab.name           AS assigned_by_name,
  b.assigned_at,
  b.reopen_count,
  b.fixed_at,
  b.created_at
FROM `tst_bugs` b
JOIN  `tst_test_cases` tc  ON tc.id  = b.test_case_id
JOIN  `tst_tabs`       t   ON t.id   = b.tab_id
JOIN  `tst_main_menus` mm  ON mm.id  = b.main_menu_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = b.sub_menu_id
JOIN  `tst_modules`    m   ON m.id   = tc.module_id
LEFT JOIN `tst_users`  au  ON au.code = b.assigned_to
LEFT JOIN `tst_users`  ab  ON ab.code = b.assigned_by
WHERE b.status NOT IN ('Closed','Wont_Fix')
  AND b.deleted_at IS NULL;

-- Test Case Requirements backlog with catalog context (FR-8, FR-12).
CREATE OR REPLACE VIEW `vw_test_case_requirements_backlog` AS
SELECT
  r.id              AS requirement_id,
  r.user_code,
  r.title,
  r.priority,
  r.status,
  r.target_release,
  m.name            AS module_name,
  mm.name           AS main_menu_name,
  sm.name           AS sub_menu_name,
  COALESCE(t.name, r.proposed_tab_name) AS tab_name,
  ru.name           AS requested_by_name,
  au.name           AS assigned_to_name,
  r.target_test_case_id,
  r.completed_at,
  r.created_at
FROM `tst_test_case_requirements` r
JOIN  `tst_modules`    m   ON m.id   = r.module_id
LEFT JOIN `tst_main_menus` mm ON mm.id = r.main_menu_id
LEFT JOIN `tst_sub_menus`  sm ON sm.id = r.sub_menu_id
LEFT JOIN `tst_tabs`       t  ON t.id  = r.tab_id
LEFT JOIN `tst_users`      ru ON ru.code = r.requested_by
LEFT JOIN `tst_users`      au ON au.code = r.assigned_to
WHERE r.deleted_at IS NULL;

-- NEW v7: Cross-user test comparison — same test case run by multiple developers.
-- Use to spot environment-specific failures (test passes for Dev A, fails for Dev B).
CREATE OR REPLACE VIEW `vw_cross_user_test_comparison` AS
SELECT
  cs.test_case_id,
  tc.display_name,
  m.name            AS module_name,
  t.name            AS tab_name,
  cs.user_code,
  u.name            AS developer_name,
  cs.total_runs,
  cs.total_passed   AS passed,
  cs.total_failed   AS failed,
  cs.pass_rate_30d  AS pass_rate,
  cs.is_flaky,
  cs.last_status,
  cs.last_run_at
FROM `tst_test_case_runs_summary` cs
JOIN `tst_test_cases` tc ON tc.id   = cs.test_case_id
JOIN `tst_tabs`       t  ON t.id    = tc.tab_id
JOIN `tst_modules`    m  ON m.id    = tc.module_id
JOIN `tst_users`      u  ON u.code  = cs.user_code
WHERE cs.total_runs > 0;

-- NEW v7: Regression candidates — tests that have passed before but are currently failing.
-- Indicates code regressions introduced by recent changes.
CREATE OR REPLACE VIEW `vw_regression_candidates` AS
SELECT
  cs.test_case_id,
  tc.display_name,
  m.name            AS module_name,
  mm.name           AS main_menu_name,
  sm.name           AS sub_menu_name,
  t.name            AS tab_name,
  cs.user_code,
  u.name            AS developer_name,
  cs.consecutive_failures,
  cs.last_status,
  cs.last_run_at,
  cs.total_passed,
  cs.total_failed
FROM `tst_test_case_runs_summary` cs
JOIN `tst_test_cases` tc ON tc.id     = cs.test_case_id
JOIN `tst_tabs`       t  ON t.id      = tc.tab_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = t.sub_menu_id
JOIN `tst_main_menus` mm ON mm.id     = COALESCE(sm.main_menu_id, t.main_menu_id)
JOIN `tst_modules`    m  ON m.id      = tc.module_id
JOIN `tst_users`      u  ON u.code    = cs.user_code
WHERE cs.last_status IN ('Failed','Error')
  AND cs.total_passed > 0               -- was passing at some point before
  AND cs.consecutive_failures > 0;

-- NEW v7: Developer activity summary — per-developer productivity and quality metrics.
CREATE OR REPLACE VIEW `vw_developer_activity_summary` AS
SELECT
  u.code                                        AS user_code,
  u.name                                        AS user_name,
  u.role,
  COUNT(DISTINCT r.id)                          AS total_runs,
  COALESCE(SUM(r.total), 0)                     AS total_tests_executed,
  COALESCE(SUM(r.passed), 0)                    AS total_passed,
  COALESCE(SUM(r.failed), 0)                    AS total_failed,
  COUNT(DISTINCT b_raised.id)                   AS total_bugs_raised,
  COUNT(DISTINCT b_assigned.id)                 AS total_bugs_assigned,
  COUNT(DISTINCT b_fixed.id)                    AS total_bugs_fixed,
  GREATEST(COALESCE(MAX(r.finished_at), '1970-01-01'), COALESCE(MAX(b_raised.created_at), '1970-01-01')) AS last_activity_at
FROM `tst_users` u
LEFT JOIN `tst_test_runs` r ON r.user_code = u.code
LEFT JOIN `tst_bugs` b_raised ON b_raised.user_code = u.code
LEFT JOIN `tst_bugs` b_assigned ON b_assigned.assigned_to = u.code
LEFT JOIN `tst_bugs` b_fixed ON b_fixed.fixed_by = u.code
WHERE u.is_active = 1 AND u.is_system = 0
GROUP BY u.code, u.name, u.role;

-- NEW v7: Reopen leaderboard — screens and tests with highest bug reopen counts.
-- Proxy for fragile areas of prime_ai or fixes that don't hold.
CREATE OR REPLACE VIEW `vw_reopen_leaderboard` AS
SELECT
  m.name                      AS module_name,
  mm.name                     AS main_menu_name,
  sm.name                     AS sub_menu_name,
  t.name                      AS tab_name,
  tc.display_name             AS test_case_name,
  b.user_code,
  COUNT(b.id)                 AS total_bugs,
  MAX(b.reopen_count)         AS max_reopen_count,
  AVG(b.reopen_count)         AS avg_reopen_count
FROM `tst_bugs` b
JOIN `tst_test_cases` tc ON tc.id   = b.test_case_id
JOIN `tst_tabs`       t  ON t.id    = b.tab_id
JOIN `tst_main_menus` mm ON mm.id   = b.main_menu_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = b.sub_menu_id
JOIN `tst_modules`    m  ON m.id    = tc.module_id
WHERE b.deleted_at IS NULL
GROUP BY m.name, mm.name, sm.name, t.name, tc.display_name, b.user_code
ORDER BY avg_reopen_count DESC, max_reopen_count DESC;

-- ============================================================================
-- END OF SCHEMA — prime_testing database v7
-- ============================================================================
