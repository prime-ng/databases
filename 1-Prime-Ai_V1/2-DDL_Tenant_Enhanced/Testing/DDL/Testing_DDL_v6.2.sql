-- ============================================================================
-- Prime-AI Testing Automation App — Database Schema
-- Version: v6.2 Based on: testing_ddl_v6.1 | Created: 2026-09-01
-- ----------------------------------------------------------------------------
-- Notes: 
-- Implemented created_by, updated_by, deleted_by in Every Table. 
-- Creted New Mapping Table to update Module, Tabs/Screens Codes.

-- ============================================================================
-- MODULE TYPE
-- T_ : TENANT MODULE
-- P_ : PRIME MODULE
-- G_ : GLOBAL MODULE
-- S_ : STUNDET/PARENT MODULE
-- M_ : MOBILE APP MODULE

-- ----------------------------------------------------------------------------
-- SECTION 0: USERS (lightweight — for executed_by / created_by / assignment)
-- ----------------------------------------------------------------------------

-- Minimal local user table for this internal tool. Not synced with Prime-AI's
-- sys_users — just enough to attribute Sync runs, Test runs, Annotations, and
-- (v2) Test Case Requirement / Bug assignment.
CREATE TABLE IF NOT EXISTS `tst_users` (
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


-- ----------------------------------------------------------------------------
-- SECTION 1: HIERARCHY CATALOG
-- Module -> Category -> Main Menu -> [Sub Menu] -> Tab -> Test Case
-- ----------------------------------------------------------------------------

-- Tab-1.1: Modules discovered from /Users/bkwork/Herd/prime_ai/Modules/*
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

-- Tab-1.2: Categories (top-level RBS grouping, e.g. "School Setup", "LMS")
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

-- Tab-1.3: Main Menus (e.g. "Syllabus Mgmt.")
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

-- Tab-1.4: Sub Menus (= one Screen/View + URL, e.g. "Syllabus Master")
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
-- A Tab attaches either to a Sub Menu (sub_menu_id set) or directly to a Main Menu
-- (sub_menu_id NULL) — see testing_requirement_v2.md §0.1 / §13.3 "Screen" definition.
CREATE TABLE IF NOT EXISTS `tst_tabs_screens` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_code`   VARCHAR(5) NOT NULL,            -- FK to tst_modules.module_code e.g. SLB
  `cat_code`      VARCHAR(3) NOT NULL,            -- FK to tst_categories.cat_code e.g. T01
  `mm_code`       VARCHAR(5) NOT NULL,            -- FK to tst_main_menus.main_menu_code e.g. T0104, T0105 etc.
  `sm_code`       VARCHAR(7) NOT NULL,            -- Sub Menu Code e.g. T010401, T010402, T010501 etc.
  `ts_code`       VARCHAR(11) NOT NULL,            -- Tab/Screen Code e.g. T0104010100, T0104010200, T0105010100 etc.
  `name`          VARCHAR(120) NOT NULL,           -- e.g. 'Lessons', 'Topic Types'
  `route_url`     VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `folder_path`   VARCHAR(500) NULL,               -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_excluded`   TINYINT(1) NOT NULL DEFAULT 0,   -- manually marked "out of scope" (excluded from catalog/UI but not deleted)
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
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


-- ----------------------------------------------------------------------------
-- SECTION 2: TEST CASE CATALOG
-- ----------------------------------------------------------------------------

-- Tab-2.1: One row per discoverable test case = one test_* method (or one
-- "Not Automated" entry derived from a requirements.md with no matching test file).
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `user_code`             VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `tab_id`                INT UNSIGNED NOT NULL,             -- FK to tst_tabs_screens
  `module_id`             INT UNSIGNED NOT NULL,             -- FK to tst_modules, denormalized for fast module-level filtering
  `file_path`             VARCHAR(500) NOT NULL,             -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson/LessonPlanningTest.php'
  `namespace`             VARCHAR(255) NULL,                 -- e.g. 'Tests\Browser\Modules\Syllabus\Lesson'
  `class_name`            VARCHAR(150) NOT NULL DEFAULT '',  -- e.g. 'LessonPlanningTest'
  `method_name`           VARCHAR(150) NOT NULL DEFAULT '',  -- e.g. 'test_updating_lesson_planning_dates'; '' for not-automated entries
  `display_name`          VARCHAR(255) NOT NULL,             -- humanized name shown in UI
  `description`           TEXT NULL,                         -- docblock summary / notes
  `test_type`             ENUM('Dusk','Feature','Unit','Validation','Business_Condition') NOT NULL DEFAULT 'Dusk',
  `automation_status`     ENUM('Automated','Draft','Not_Automated') NOT NULL DEFAULT 'Automated',
  `requirements_md_path`  VARCHAR(500) NULL,                 -- relative path to requirements.md, if any
  `sort_order`            SMALLINT UNSIGNED DEFAULT 1,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,     -- set to 0 by Sync if no longer found on disk
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_testCases_tab` (`tab_id`),
  INDEX `idx_tst_testCases_module` (`module_id`),
  INDEX `idx_tst_testCases_active` (`is_active`),
  INDEX `idx_tst_testCases_status` (`automation_status`),
  UNIQUE KEY `uq_tst_testCases_identity` (`file_path`, `class_name`, `method_name`),
  CONSTRAINT `fk_tst_testCases_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_tab` FOREIGN KEY (`tab_id`) REFERENCES `tst_tabs_screens`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SECTION 3: TEST EXECUTION & HISTORY
-- ----------------------------------------------------------------------------

-- Tab-3.1: One row per "Run" click (a batch execution of one or more test cases)
CREATE TABLE IF NOT EXISTS `tst_test_runs` (
  `id`                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_uuid`          BINARY(16) NOT NULL,            -- UUID (16 bytes) in binary format
  `executed_by`       VARCHAR(10) NULL,               -- FK tst_users.code; nullable for scheduled/system/auto-retest runs
  `trigger_type`      ENUM('Manual','Scheduled','Rerun','Auto_Retest') NOT NULL DEFAULT 'Manual', -- v5: 'Auto_Retest' added for FR-10
  `scope_json`        JSON NULL,                      -- selected module/tab/test_case ids + resolved file list
  `command`           VARCHAR(1000) NULL,             -- exact artisan dusk command executed
  `status`            ENUM('Queued','Running','Completed','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
  `started_at`        DATETIME NULL,
  `finished_at`       DATETIME NULL,
  `duration_seconds`  DECIMAL(10,2) NULL,
  `exit_code`         SMALLINT NULL,
  `total`             INT UNSIGNED NOT NULL DEFAULT 0,
  `passed`            INT UNSIGNED NOT NULL DEFAULT 0,
  `failed`            INT UNSIGNED NOT NULL DEFAULT 0,
  `skipped`           INT UNSIGNED NOT NULL DEFAULT 0,
  `assertions`        INT UNSIGNED NOT NULL DEFAULT 0,  -- total assertions across all test cases e.g. 100
  `raw_output_path`   VARCHAR(500) NULL,                -- relative path under storage/app/test-runs/{run_id}/
  `environment_json`  JSON NULL,                        -- PHP/Chrome versions, APP_ENV, etc.
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_testRuns_runuuid` (`run_uuid`),
  INDEX `idx_tst_testRuns_executedBy` (`executed_by`),
  INDEX `idx_tst_testRuns_status` (`status`),
  INDEX `idx_tst_testRuns_startedAt` (`started_at`),
  CONSTRAINT `fk_tst_testRuns_executedBy` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRuns_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRuns_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRuns_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-3.2: One row per test case within a run
-- v5: `bug_id` is added via ALTER TABLE at the end of this file (forward
-- reference to `tst_bugs`, which itself references this table).
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_uuid`              BINARY(16) NOT NULL,          -- FK tst_test_runs.id
  `executed_by`           VARCHAR(10) NULL,               -- FK tst_users.code; nullable for scheduled/system/auto-retest runs
  `test_case_id`          INT UNSIGNED NULL,              -- FK tst_test_cases.id (nullable: keep history if case later removed)
  `bug_id`                INT UNSIGNED NULL,
  `display_name`          VARCHAR(255) NOT NULL,          -- snapshot of test name at run time
  `status`                ENUM('Passed','Failed','Skipped','Error') NOT NULL,
  `duration_seconds`      DECIMAL(10,2) NULL,
  `assertions`            INT UNSIGNED NOT NULL DEFAULT 0,  -- snapshot of assertions at run time
  `error_message`         TEXT NULL,
  `error_trace`           LONGTEXT NULL,
  `screenshot_path`       VARCHAR(500) NULL,              -- failure screenshot, relative to storage/app/test-runs/{run_id}/screenshots/
  `console_log_path`      VARCHAR(500) NULL,
  `source_html_path`      VARCHAR(500) NULL,
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_testRunResults_run` (`run_id`),
  INDEX `idx_tst_testRunResults_testCase` (`test_case_id`),
  INDEX `idx_tst_testRunResults_status` (`status`),
  INDEX `idx_tst_testRunResults_bug` (`bug_id`),
  CONSTRAINT `fk_tst_testRunResults_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testRunResults_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_testRunResults_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_testRunResults_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunResults_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunResults_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-3.3: Rolling per-test-case statistics for fast dashboard queries (FR-5)
-- Maintained by the Reporting/Analytics Service after each run.
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
  `test_case_id`         INT UNSIGNED PRIMARY KEY,
  `last_run_result_id`   INT UNSIGNED NULL,    -- FK tst_test_run_results.id
  `last_status`          ENUM('Passed','Failed','Skipped','Error') NULL,
  `last_run_at`          DATETIME NULL,
  `consecutive_failures` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `total_runs`           INT UNSIGNED NOT NULL DEFAULT 0,
  `total_passed`         INT UNSIGNED NOT NULL DEFAULT 0,
  `total_failed`         INT UNSIGNED NOT NULL DEFAULT 0,
  `total_skipped`        INT UNSIGNED NOT NULL DEFAULT 0,
  `pass_rate_30d`        DECIMAL(5,2) NULL,             -- percentage, 0.00 - 100.00
  `avg_duration_seconds` DECIMAL(10,2) NULL,
  `is_flaky`             TINYINT(1) NOT NULL DEFAULT 0, -- status changed across consecutive runs w/o code change (A flaky test can pass and fail on separate runs without any changes to the underlying code)
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_caseSummary_lastStatus` (`last_status`),
  INDEX `idx_tst_caseSummary_flaky` (`is_flaky`),
  CONSTRAINT `fk_tst_caseSummary_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_caseSummary_lastRunResult` FOREIGN KEY (`last_run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseSummary_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseSummary_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseSummary_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 4: ANNOTATIONS, SYNC LOG, SCHEDULES
-- ----------------------------------------------------------------------------

-- Tab-4.1: User notes on a run or a specific result (e.g. "known issue, ticket #123") — FR-7
CREATE TABLE IF NOT EXISTS `tst_run_annotations` (
  `id`             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_id`         INT UNSIGNED NULL,             -- FK tst_test_runs.id (note about whole run)
  `run_result_id`  INT UNSIGNED NULL,             -- FK tst_test_run_results.id (note about one result)
  `note`           TEXT NOT NULL,
  `is_known_issue` TINYINT(1) NOT NULL DEFAULT 0, -- excludes from flaky-test alerts when set
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_runAnnotations_run` (`run_id`),
  INDEX `idx_tst_runAnnotations_runResult` (`run_result_id`),
  CONSTRAINT `fk_tst_runAnnotations_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_runAnnotations_runResult` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_runAnnotations_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-4.2: History of discovery/sync runs (what changed each time the catalog was scanned)
CREATE TABLE IF NOT EXISTS `tst_sync_logs` (
  `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `started_at`          DATETIME NOT NULL,
  `finished_at`         DATETIME NULL,
  `status`              ENUM('running','success','failed') NOT NULL DEFAULT 'running',
  `modules_found`       INT UNSIGNED NOT NULL DEFAULT 0,
  `tabs_found`          INT UNSIGNED NOT NULL DEFAULT 0,
  `test_cases_added`    INT UNSIGNED NOT NULL DEFAULT 0,
  `test_cases_updated`  INT UNSIGNED NOT NULL DEFAULT 0,
  `test_cases_removed`  INT UNSIGNED NOT NULL DEFAULT 0,
  `details_json`        JSON NULL,               -- list of added/removed file paths etc.
  `error_message`       TEXT NULL,
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_syncLogs_status` (`status`),
  INDEX `idx_tst_syncLogs_startedAt` (`started_at`),
  CONSTRAINT `fk_tst_syncLogs_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_syncLogs_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_syncLogs_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-4.3: Scheduled run definitions (Phase 2 — included now for forward compatibility, unused in Phase 1 UI)
CREATE TABLE IF NOT EXISTS `tst_schedules` (
  `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`             VARCHAR(150) NOT NULL,
  `scope_json`       JSON NOT NULL,               -- same shape as tst_test_runs.scope_json
  `cron_expression`  VARCHAR(100) NOT NULL,       -- e.g. '0 2 * * *'
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `last_run_id`      INT UNSIGNED NULL,           -- FK tst_test_runs.id of most recent scheduled run
  `created_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,                  -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_schedules_name` (`name`),
  INDEX `idx_tst_schedules_active` (`is_active`),
  CONSTRAINT `fk_tst_schedules_lastRun` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_schedules_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_schedules_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_schedules_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 5 (NEW v5): TEST CASE REQUIREMENTS BACKLOG — FR-8
-- ----------------------------------------------------------------------------

-- Tab-5.1: Backlog of new/updated test cases needed as Prime-AI is enhanced.
CREATE TABLE IF NOT EXISTS `tst_test_case_requirements` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_id`             INT UNSIGNED NOT NULL,            -- FK tst_modules — which module the enhancement belongs to
  `main_menu_id`          INT UNSIGNED NULL,                -- FK tst_main_menus — target screen group, if known
  `sub_menu_id`           INT UNSIGNED NULL,                -- FK tst_sub_menus — target screen, if known
  `tab_id`                INT UNSIGNED NULL,                -- FK tst_tabs_screens — existing Tab to extend, NULL if a brand-new Tab/feature is proposed
  `proposed_tab_name`     VARCHAR(120) NULL,                -- e.g. 'Bulk Attendance Import' — used when tab_id is NULL
  `proposed_folder_path`  VARCHAR(500) NULL,                -- proposed tests/Browser/Modules/... path for the new Tab, used by FR-6 wizard
  `title`                 VARCHAR(255) NOT NULL,            -- short summary of the enhancement that needs coverage
  `description`           TEXT NULL,                        -- what changed / what needs to be tested
  `priority`              ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `target_release`        VARCHAR(60) NULL,                 -- free text, e.g. '2026.07 Release'
  `requested_by`          VARCHAR(10) NOT NULL,             -- FK tst_users.code — who raised the requirement
  `assigned_to`           VARCHAR(10) NOT NULL,             -- FK tst_users.code (role='Tester') — who will write the test case
  `status`                ENUM('Pending','In_Progress','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
  `target_test_case_id`   INT UNSIGNED NULL,                -- FK tst_test_cases — set once the new test case exists in the catalog
  `completed_by`          VARCHAR(10) NOT NULL,             -- FK tst_users.code
  `completed_at`          DATETIME NULL,
  `created_by`            VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `updated_by`            VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `deleted_by`            VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL,
  INDEX `idx_tst_caseReq_module` (`module_id`),
  INDEX `idx_tst_caseReq_status` (`status`),
  INDEX `idx_tst_caseReq_priority` (`priority`),
  INDEX `idx_tst_caseReq_assignedTo` (`assigned_to`),
  CONSTRAINT `fk_tst_caseReq_module`     FOREIGN KEY (`module_id`)    REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_caseReq_mainMenu`   FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_subMenu`    FOREIGN KEY (`sub_menu_id`)  REFERENCES `tst_sub_menus`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_tab`        FOREIGN KEY (`tab_id`)       REFERENCES `tst_tabs_screens`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_requestedBy` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_assignedTo`  FOREIGN KEY (`assigned_to`)  REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_targetTestCase` FOREIGN KEY (`target_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_completedBy` FOREIGN KEY (`completed_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 6 (NEW v5): BUG TRACKING & DEVELOPER ASSIGNMENT — FR-9
-- ----------------------------------------------------------------------------

-- Tab-6.1: One row per tracked bug. Auto-created from a failing
-- tst_test_run_results row, or raised manually by QA.
CREATE TABLE IF NOT EXISTS `tst_bugs` (
  `id`              INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_result_id`   INT UNSIGNED NULL,              -- FK tst_test_run_results — the originating failure (nullable for manually-raised bugs)
  `test_case_id`    INT UNSIGNED NOT NULL,          -- FK tst_test_cases
  `tab_id`          INT UNSIGNED NOT NULL,          -- FK tst_tabs_screens — denormalized
  `main_menu_id`    INT UNSIGNED NOT NULL,          -- FK tst_main_menus — denormalized "Screen" scope (used when sub_menu_id IS NULL)
  `sub_menu_id`     INT UNSIGNED NULL,              -- FK tst_sub_menus — denormalized "Screen" scope for FR-10 retest
  `requirement_id`  INT UNSIGNED NULL,              -- FK tst_test_case_requirements — optional traceability to the enhancement that introduced this feature
  `title`           VARCHAR(255) NOT NULL,
  `description`     TEXT NULL,                      -- defaults to error_message/error_trace snapshot, editable by QA
  `severity`        ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `status`          ENUM('Open','Assigned','In_Progress','Fixed','Retesting','Reopened','Closed','Escalated','Wont_Fix') NOT NULL DEFAULT 'Open',
  `assigned_to`     VARCHAR(10) NOT NULL,           -- FK tst_users.code (role='Developer')
  `assigned_by`     VARCHAR(10) NOT NULL,           -- FK tst_users.code (typically role='QA_Lead')
  `assigned_at`     DATETIME NULL,
  `fixed_by`        VARCHAR(10) NOT NULL,           -- FK tst_users.code
  `fixed_at`        DATETIME NULL,
  `fix_notes`       TEXT NULL,
  `reopen_count`    SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- incremented each time FR-10's retest loop bounces this bug back
  `closed_by`       VARCHAR(10) NOT NULL,           -- FK tst_users.code; NULL when system-closed by a passing retest cycle
  `closed_at`       DATETIME NULL,
  `created_by`      VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `updated_by`      VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `deleted_by`      VARCHAR(10) NOT NULL,             -- FK to tst_users.code
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_bugs_status` (`status`),
  INDEX `idx_tst_bugs_severity` (`severity`),
  INDEX `idx_tst_bugs_testCase` (`test_case_id`),
  INDEX `idx_tst_bugs_assignedTo` (`assigned_to`),
  INDEX `idx_tst_bugs_subMenu` (`sub_menu_id`),
  INDEX `idx_tst_bugs_mainMenu` (`main_menu_id`),
  CONSTRAINT `fk_tst_bugs_runResult`  FOREIGN KEY (`run_result_id`)  REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_bugs_testCase`   FOREIGN KEY (`test_case_id`)   REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_tab`        FOREIGN KEY (`tab_id`)         REFERENCES `tst_tabs_screens`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_mainMenu`   FOREIGN KEY (`main_menu_id`)   REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_subMenu`    FOREIGN KEY (`sub_menu_id`)    REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_requirement` FOREIGN KEY (`requirement_id`) REFERENCES `tst_test_case_requirements`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_bugs_assignedTo` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_assignedBy` FOREIGN KEY (`assigned_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_fixedBy`    FOREIGN KEY (`fixed_by`)    REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_closedBy`   FOREIGN KEY (`closed_by`)   REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-6.2: Audit trail of every bug status transition (FR-12)
CREATE TABLE IF NOT EXISTS `tst_bug_status_history` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `bug_id`        INT UNSIGNED NOT NULL,           -- FK tst_bugs
  `from_status`   VARCHAR(20) NULL,                -- previous status, NULL on initial creation
  `to_status`     VARCHAR(20) NOT NULL,            -- new status
  `changed_by`    VARCHAR(10) NOT NULL,           -- FK tst_users.code; NULL for system-driven transitions (e.g. auto Reopen)
  `note`          TEXT NULL,
  `created_by`    VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_tst_bugHistory_bug` (`bug_id`),
  CONSTRAINT `fk_tst_bugHistory_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugHistory_changedBy` FOREIGN KEY (`changed_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugHistory_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 7 (NEW v5): AUTOMATED BUG-FIX VERIFICATION LOOP — FR-10
-- ----------------------------------------------------------------------------

-- Tab-7.1: One row per auto-retest cycle triggered for a Screen (Sub Menu, or
-- Main Menu when the Tab has no Sub Menu) after a bug is marked 'Fixed'.
CREATE TABLE IF NOT EXISTS `tst_retest_cycles` (
  `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `main_menu_id`        INT UNSIGNED NOT NULL,      -- FK tst_main_menus — Screen scope when sub_menu_id IS NULL
  `sub_menu_id`         INT UNSIGNED NULL,          -- FK tst_sub_menus — Screen scope, if applicable
  `triggered_by_bug_id` INT UNSIGNED NOT NULL,      -- FK tst_bugs — the bug whose 'Fixed' status started this cycle
  `cycle_number`        SMALLINT UNSIGNED NOT NULL DEFAULT 1, -- 1, 2, 3... per Screen+bug chain (FR-10 step 6)
  `run_id`              INT UNSIGNED NULL,          -- FK tst_test_runs (trigger_type='Auto_Retest') — the scoped re-run
  `status`              ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending', -- 'Passed' only if ALL test cases in the Screen's scope passed
  `created_by`          VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `updated_by`          VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `deleted_by`          VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`          TIMESTAMP NULL,
  INDEX `idx_tst_retestCycles_subMenu` (`sub_menu_id`),
  INDEX `idx_tst_retestCycles_mainMenu` (`main_menu_id`),
  INDEX `idx_tst_retestCycles_status` (`status`),
  CONSTRAINT `fk_tst_retestCycles_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_subMenu`  FOREIGN KEY (`sub_menu_id`)  REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_bug`      FOREIGN KEY (`triggered_by_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_run`      FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_retestCycles_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_retestCycles_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_retestCycles_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-7.2: Many-to-many — which open bugs were covered by a given retest cycle,
-- and the per-bug outcome (FR-10 step 5).
CREATE TABLE IF NOT EXISTS `tst_bug_retest_cycles_jnt` (
  `bug_id`           INT UNSIGNED NOT NULL,         -- FK tst_bugs
  `retest_cycle_id`  INT UNSIGNED NOT NULL,         -- FK tst_retest_cycles
  `outcome`          ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `created_by`       VARCHAR(10) NOT NULL,          -- FK to tst_users.code
  `updated_by`       VARCHAR(10) NOT NULL,          -- FK to tst_users.code
  `deleted_by`       VARCHAR(10) NOT NULL,          -- FK to tst_users.code
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  PRIMARY KEY (`bug_id`, `retest_cycle_id`),
  INDEX `idx_tst_bugRetest_cycle` (`retest_cycle_id`),
  CONSTRAINT `fk_tst_bugRetest_bug`   FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugRetest_cycle` FOREIGN KEY (`retest_cycle_id`) REFERENCES `tst_retest_cycles`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugRetest_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugRetest_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugRetest_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 8 (NEW v5): APP SETTINGS — FR-11
-- ----------------------------------------------------------------------------

-- Tab-8.1: Generic key/value configuration store.
CREATE TABLE IF NOT EXISTS `tst_app_settings` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `key`           VARCHAR(100) NOT NULL,
  `value`         VARCHAR(500) NOT NULL,
  `value_type`    ENUM('string','integer','boolean','json') NOT NULL DEFAULT 'string',
  `description`   VARCHAR(255) NULL,
  `created_by`    VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `updated_by`    VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `deleted_by`    VARCHAR(10) NOT NULL,           -- FK to tst_users.code
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_appSettings_key` (`key`),
  CONSTRAINT `fk_tst_appSettings_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_appSettings_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_appSettings_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed default settings referenced in testing_requirement_v2.md §13.4
INSERT INTO `tst_app_settings` (`key`, `value`, `value_type`, `description`) VALUES
  ('max_auto_retest_attempts', '5', 'integer', 'FR-10 safety valve: after this many reopen cycles for the same bug, status moves to Escalated instead of auto-retesting again.'),
  ('auto_retest_enabled', 'true', 'boolean', 'Global kill-switch: if false, marking a bug Fixed does not auto-trigger the FR-10 retest cycle (manual re-test only).'),
  ('auto_bug_creation_enabled', 'true', 'boolean', 'If false, failing test_run_results do not auto-create tst_bugs rows; QA must raise bugs manually.'),
  ('bug_fix_sla_hours', '48', 'integer', 'Used by dashboards (FR-12) to flag bugs that have been Assigned/In_Progress longer than this many hours.')
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);



-- ----------------------------------------------------------------------------
-- SECTION 10: CONVENIENCE VIEWS
-- ----------------------------------------------------------------------------

-- Full catalog view: flattens the hierarchy + latest run status for the UI tree (FR-1)
-- v5: rewritten with LEFT JOINs + COALESCE so Tabs attached directly to a Main
-- Menu (sub_menu_id IS NULL) are no longer excluded from the catalog.
CREATE OR REPLACE VIEW `vw_test_case_catalog` AS
SELECT
  tc.id                       AS test_case_id,
  m.id                        AS module_id,
  m.name                      AS module_name,
  c.id                        AS category_id,
  c.name                      AS category_name,
  mm.id                       AS main_menu_id,
  mm.name                     AS main_menu_name,
  sm.id                       AS sub_menu_id,
  sm.name                     AS sub_menu_name,
  COALESCE(sm.route_url, mm.route_url) AS route_url,
  t.id                        AS tab_id,
  t.name                      AS tab_name,
  tc.display_name             AS test_case_name,
  tc.test_type,
  tc.automation_status,
  tc.file_path,
  tc.method_name,
  cs.last_status,
  cs.last_run_at,
  cs.pass_rate_30d,
  cs.is_flaky,
  tc.is_active
FROM `tst_test_cases` tc
JOIN `tst_tabs_screens` t            ON t.id = tc.tab_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = t.sub_menu_id
JOIN `tst_main_menus` mm     ON mm.id = COALESCE(sm.main_menu_id, t.main_menu_id)
JOIN `tst_categories` c      ON c.id = mm.category_id
JOIN `tst_modules` m         ON m.id = tc.module_id
LEFT JOIN `tst_test_case_runs_summary` cs ON cs.test_case_id = tc.id;

-- Run history view: one row per run with executor name resolved
CREATE OR REPLACE VIEW `vw_test_run_history` AS
SELECT
  r.id,
  r.run_id,
  u.name        AS executed_by_name,
  r.trigger_type,
  r.status,
  r.started_at,
  r.finished_at,
  r.duration_seconds,
  r.total,
  r.passed,
  r.failed,
  r.skipped,
  r.assertions
FROM `tst_test_runs` r
LEFT JOIN `tst_users` u ON u.code = r.executed_by;

-- Tab-10.1 (NEW v5): Open bugs with catalog context + assignee name — feeds the
-- "My Bugs" / "Unassigned Bugs" dashboards (FR-9, FR-12)
CREATE OR REPLACE VIEW `vw_open_bugs` AS
SELECT
  b.id              AS bug_id,
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
JOIN `tst_test_cases` tc   ON tc.id = b.test_case_id
JOIN `tst_tabs_screens` t          ON t.id = b.tab_id
JOIN `tst_main_menus` mm   ON mm.id = b.main_menu_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = b.sub_menu_id
JOIN `tst_modules` m       ON m.id = tc.module_id
LEFT JOIN `tst_users` au   ON au.code = b.assigned_to
LEFT JOIN `tst_users` ab   ON ab.code = b.assigned_by
WHERE b.status NOT IN ('Closed','Wont_Fix')
  AND b.deleted_at IS NULL;

-- Tab-10.2 (NEW v5): Test Case Requirements backlog with catalog context (FR-8, FR-12)
CREATE OR REPLACE VIEW `vw_test_case_requirements_backlog` AS
SELECT
  r.id              AS requirement_id,
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
JOIN `tst_modules` m          ON m.id = r.module_id
LEFT JOIN `tst_main_menus` mm ON mm.id = r.main_menu_id
LEFT JOIN `tst_sub_menus` sm  ON sm.id = r.sub_menu_id
LEFT JOIN `tst_tabs_screens` t        ON t.id = r.tab_id
LEFT JOIN `tst_users` ru      ON ru.code = r.requested_by
LEFT JOIN `tst_users` au      ON au.code = r.assigned_to
WHERE r.deleted_at IS NULL;
