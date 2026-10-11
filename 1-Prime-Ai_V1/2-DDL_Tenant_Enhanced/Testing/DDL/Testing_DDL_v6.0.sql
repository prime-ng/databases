-- ============================================================================
-- Prime-AI Testing Automation App — Database Schema
-- Project: prime_ai_testing (standalone Laravel app)
-- Version: v6
-- MySQL 8 Compatible | Single-tenant internal tool DB
-- Based on: testing_ddl_v4.sql + testing_requirement_v2.md
-- Created: 2026-06-14
--
-- Notes:
--  - This schema lives in its own database (e.g. `prime_ai_testing`), independent of global_db / prime_db / tenant_db.
--  - Table prefix: `tst_`.
--  - Conventions followed: InnoDB, utf8mb4, soft deletes (`deleted_at`), `is_active`,
--    `created_at`/`updated_at`, `created_by` FK to `tst_users`, `_json` suffix for JSON
--    columns, FK naming `{entity}_id`.
--
-- v5 CHANGES vs v4:
--  1. BUGFIX: `tst_modules` referenced a `created_by` column in
--     `fk_tst_modules_createdBy` that did not exist in v4 — column added.
--  2. BUGFIX: `tst_schedules.fk_tst_schedules_lastRun` had `ON DELETE SET NUL`
--     (typo) — corrected to `ON DELETE SET NULL`.
--  3. `tst_users` gains a `role` column (Admin/Tester/Developer/QA_Lead) to support
--     FR-8/FR-9 assignment pick-lists (testing_requirement_v2.md §16 Q3).
--  4. `tst_test_runs.trigger_type` ENUM gains `'Auto_Retest'` (FR-10).
--  5. `tst_test_run_results` gains nullable `bug_id` FK -> `tst_bugs` (added via
--     ALTER at the end of the file to avoid a forward reference).
--  6. NEW tables (FR-8 to FR-11):
--       tst_test_case_requirements, tst_bugs, tst_bug_status_history,
--       tst_retest_cycles, tst_bug_retest_cycles_jnt, tst_app_settings
--  7. `vw_test_case_catalog` rewritten with LEFT JOINs + COALESCE so Tabs that
--     attach directly to a Main Menu (no Sub Menu, `tst_tabs.sub_menu_id IS NULL`)
--     are no longer silently excluded from the catalog.
--  8. NEW views: vw_open_bugs, vw_test_case_requirements_backlog
-- ============================================================================


-- ----------------------------------------------------------------------------
-- SECTION 0: USERS (lightweight — for executed_by / created_by / assignment)
-- ----------------------------------------------------------------------------

-- Minimal local user table for this internal tool. Not synced with Prime-AI's
-- sys_users — just enough to attribute Sync runs, Test runs, Annotations, and
-- (v2) Test Case Requirement / Bug assignment.
CREATE TABLE IF NOT EXISTS `tst_users` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code`          VARCHAR(5) NOT NULL,              -- 'admin', 'brij', 'shail', 'samer', 'tarun', 'Gaurv'. This will be used as login user & Uniq Identifier.
  `name`          VARCHAR(50) NOT NULL,
  `email`         VARCHAR(100) NOT NULL,
  `password`      VARCHAR(512) NOT NULL,             -- Hashed Password
  `role`          ENUM('Admin','Architect','QA_Lead','Tester','Developer','Reviewer') NULL DEFAULT 'Tester', -- v5: used to filter assignment pick-lists for FR-8 (Tester) / FR-9 (Developer)
  `is_superuser`  TINYINT(1) NOT NULL DEFAULT 0,
  `is_system`     TINYINT(1) NOT NULL DEFAULT 0,     -- If true, this user is a system user and Can not be deleted.
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_users_email` (`email`),
  UNIQUE KEY `uq_tst_users_code` (`code`),
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
  `code`          VARCHAR(3) NOT NULL,            -- Folder name, e.g. 'slb', 'lib', 'sch'
  `name`          VARCHAR(60) NOT NULL,           -- Folder name, e.g. 'Syllabus', 'Library', 'School Setup'
  `description`   VARCHAR(255) NULL,              -- Display name, e.g. 'Syllabus Management', 'Library Management', 'School Setup'
  `folder_name`   VARCHAR(60) NULL,               -- Folder name, e.g. 'Syllabus', 'Library', 'SchoolSetup'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `version`       SMALLINT UNSIGNED DEFAULT 0,
  `created_by`    INT UNSIGNED NULL,              -- v5 bugfix: column was missing although fk_tst_modules_createdBy referenced it
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_modules_code` (`code`),
  INDEX `idx_tst_modules_active` (`is_active`),
  CONSTRAINT `fk_tst_modules_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.2: Categories (top-level Menu grouping - Category, e.g. "School Setup", "LMS")
CREATE TABLE IF NOT EXISTS `tst_categories` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_id`     INT UNSIGNED NOT NULL,           -- FK to tst_modules
  `name`          VARCHAR(120) NOT NULL,           -- e.g. 'School Setup'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_categories_module` (`module_id`),
  INDEX `idx_tst_categories_active` (`is_active`),
  UNIQUE KEY `uq_tst_categories_module_name` (`module_id`, `name`),
  CONSTRAINT `fk_tst_categories_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.3: Main Menus comes under Category (e.g. "Syllabus Mgmt.")
CREATE TABLE IF NOT EXISTS `tst_main_menus` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_id`     INT UNSIGNED NOT NULL,           -- FK to tst_modules
  `category_id`   INT UNSIGNED NOT NULL,           -- FK to tst_categories
  `name`          VARCHAR(120) NOT NULL,
  `route_url`     VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_mainMenus_category` (`category_id`),
  INDEX `idx_tst_mainMenus_active` (`is_active`),
  UNIQUE KEY `uq_tst_mainMenus_category_name` (`category_id`, `name`),
  CONSTRAINT `fk_tst_mainMenus_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_mainMenus_category` FOREIGN KEY (`category_id`) REFERENCES `tst_categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.4: Sub Menus comes under Main Menu (= one Screen/View + URL, e.g. "Syllabus Master"). In Some Cases, we may not have Sub-Menus.
CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_id`     INT UNSIGNED NOT NULL,           -- FK to tst_modules
  `main_menu_id`  INT UNSIGNED NOT NULL,           -- FK to tst_main_menus
  `name`          VARCHAR(120) NOT NULL,
  `route_url`     VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_subMenus_mainMenu` (`main_menu_id`),
  INDEX `idx_tst_subMenus_active` (`is_active`),
  UNIQUE KEY `uq_tst_subMenus_mainMenu_name` (`main_menu_id`, `name`),
  CONSTRAINT `fk_tst_subMenus_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_subMenus_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.5: Tabs (one Tab = one feature folder under tests/Browser/Modules/{Module}/{Feature})
-- A Tab attaches either to a Sub Menu (sub_menu_id set) or directly to a Main Menu. Also in some cases, we may not have multipal Tabs under Main/Sub-Menus. 
-- and we may have only a single screen. in Such cases, we will capture the screen in the Tab table.
-- (sub_menu_id NULL) — see testing_requirement_v2.md §0.1 / §13.3 "Screen" definition.
CREATE TABLE IF NOT EXISTS `tst_tabs` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_id`     INT UNSIGNED NOT NULL,           -- FK to tst_modules
  `main_menu_id`  INT UNSIGNED NOT NULL,           -- FK to tst_main_menus
  `sub_menu_id`   INT UNSIGNED NULL,               -- FK to tst_sub_menus (nullable — see header note)
  `name`          VARCHAR(120) NOT NULL,           -- e.g. 'Lessons', 'Topic Types'
  `route_url`     VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `folder_path`   VARCHAR(500) NULL,               -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_excluded`   TINYINT(1) NOT NULL DEFAULT 0,   -- manually marked "out of scope" (excluded from catalog/UI but not deleted)
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_tabs_subMenu` (`sub_menu_id`),
  INDEX `idx_tst_tabs_mainMenu` (`main_menu_id`),
  INDEX `idx_tst_tabs_active` (`is_active`),
  UNIQUE KEY `uq_tst_tabs_subMenu_name` (`sub_menu_id`, `name`),
  CONSTRAINT `fk_tst_tabs_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_subMenu` FOREIGN KEY (`sub_menu_id`) REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 2: TEST CASE CATALOG
-- ----------------------------------------------------------------------------

-- Tab-2.1: One row per discoverable test case = one test_* method (or one
-- "Not Automated" entry derived from a requirements.md with no matching test file).
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `user_id`               INT UNSIGNED NOT NULL,             -- FK to tst_users.id
  `user_code`             VARCHAR(5) NOT NULL,               -- FK to tst_users.code
  `tab_id`                INT UNSIGNED NOT NULL,             -- FK to tst_tabs.id
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
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`, `user_id`),
  INDEX `idx_tst_testCases_tab` (`tab_id`),
  INDEX `idx_tst_testCases_module` (`module_id`),
  INDEX `idx_tst_testCases_active` (`is_active`),
  INDEX `idx_tst_testCases_status` (`automation_status`),
  UNIQUE KEY `uq_tst_testCases_identity` (`file_path`(255), `class_name`, `method_name`),
  CONSTRAINT `fk_tst_testCases_tab` FOREIGN KEY (`tab_id`) REFERENCES `tst_tabs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SECTION 3: TEST EXECUTION & HISTORY
-- ----------------------------------------------------------------------------

-- Tab-3.1: One row per "Run" click (a batch execution of one or more test cases)
CREATE TABLE IF NOT EXISTS `tst_test_runs` (
  `id`                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_id`            VARCHAR(64) NOT NULL,           -- e.g. '20260612_143000_a1b2c3' format is YYYYMMDD_HHMMSS_(6 Digits Random Number)
  `executed_by`       INT UNSIGNED NULL,              -- FK tst_users; nullable for scheduled/system/auto-retest runs
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
  `created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tst_testRuns_runId` (`run_id`),
  INDEX `idx_tst_testRuns_executedBy` (`executed_by`),
  INDEX `idx_tst_testRuns_status` (`status`),
  INDEX `idx_tst_testRuns_startedAt` (`started_at`),
  CONSTRAINT `fk_tst_testRuns_executedBy` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-3.2: One row per test case within a run
-- v5: `bug_id` is added via ALTER TABLE at the end of this file (forward
-- reference to `tst_bugs`, which itself references this table).
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_id`                INT UNSIGNED NOT NULL,          -- FK tst_test_runs.id
  `test_case_id`          INT UNSIGNED NULL,              -- FK tst_test_cases.id (nullable: keep history if case later removed)
  `bug_id`                INT UNSIGNED NULL,              -- FK tst_bugs.id
  `display_name`          VARCHAR(255) NOT NULL,          -- snapshot of test name at run time
  `status`                ENUM('Passed','Failed','Skipped','Error') NOT NULL,
  `duration_seconds`      DECIMAL(10,2) NULL,
  `assertions`            INT UNSIGNED NOT NULL DEFAULT 0,  -- snapshot of assertions at run time
  `error_message`         TEXT NULL,
  `error_trace`           LONGTEXT NULL,
  `screenshot_path`       VARCHAR(500) NULL,              -- failure screenshot, relative to storage/app/test-runs/{run_id}/screenshots/
  `console_log_path`      VARCHAR(500) NULL,
  `source_html_path`      VARCHAR(500) NULL,
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_tst_testRunResults_run` (`run_id`),
  INDEX `idx_tst_testRunResults_testCase` (`test_case_id`),
  INDEX `idx_tst_testRunResults_status` (`status`),
  INDEX `idx_tst_testRunResults_bug` (`bug_id`),
  CONSTRAINT `fk_tst_testRunResults_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testRunResults_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_testRunResults_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL
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
  `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_tst_caseSummary_lastStatus` (`last_status`),
  INDEX `idx_tst_caseSummary_flaky` (`is_flaky`),
  CONSTRAINT `fk_tst_caseSummary_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_caseSummary_lastRunResult` FOREIGN KEY (`last_run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL
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
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`     TIMESTAMP NULL,
  INDEX `idx_tst_runAnnotations_run` (`run_id`),
  INDEX `idx_tst_runAnnotations_runResult` (`run_result_id`),
  CONSTRAINT `fk_tst_runAnnotations_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_runAnnotations_runResult` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE
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
  `created_by`           INT UNSIGNED NULL,
  `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_tst_syncLogs_status` (`status`),
  INDEX `idx_tst_syncLogs_startedAt` (`started_at`),
  CONSTRAINT `fk_tst_syncLogs_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-4.3: Scheduled run definitions (Phase 2 — included now for forward compatibility, unused in Phase 1 UI)
CREATE TABLE IF NOT EXISTS `tst_schedules` (
  `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`             VARCHAR(150) NOT NULL,
  `scope_json`       JSON NOT NULL,               -- same shape as tst_test_runs.scope_json
  `cron_expression`  VARCHAR(100) NOT NULL,       --
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `last_run_id`      INT UNSIGNED NULL,           -- FK tst_test_runs.id of most recent scheduled run
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_schedules_name` (`name`),
  INDEX `idx_tst_schedules_active` (`is_active`),
  CONSTRAINT `fk_tst_schedules_lastRun` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL -- v5 bugfix: was 'SET NUL'
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
  `tab_id`                INT UNSIGNED NULL,                -- FK tst_tabs — existing Tab to extend, NULL if a brand-new Tab/feature is proposed
  `proposed_tab_name`     VARCHAR(120) NULL,                -- e.g. 'Bulk Attendance Import' — used when tab_id is NULL
  `proposed_folder_path`  VARCHAR(500) NULL,                -- proposed tests/Browser/Modules/... path for the new Tab, used by FR-6 wizard
  `title`                 VARCHAR(255) NOT NULL,            -- short summary of the enhancement that needs coverage
  `description`           TEXT NULL,                        -- what changed / what needs to be tested
  `priority`              ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `target_release`        VARCHAR(60) NULL,                 -- free text, e.g. '2026.07 Release'
  `requested_by`          INT UNSIGNED NULL,                -- FK tst_users — who raised the requirement
  `assigned_to`           INT UNSIGNED NULL,                -- FK tst_users (role='Tester') — who will write the test case
  `status`                ENUM('Pending','In_Progress','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
  `target_test_case_id`   INT UNSIGNED NULL,                -- FK tst_test_cases — set once the new test case exists in the catalog
  `completed_by`          INT UNSIGNED NULL,                -- FK tst_users
  `completed_at`          DATETIME NULL,
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
  CONSTRAINT `fk_tst_caseReq_tab`        FOREIGN KEY (`tab_id`)       REFERENCES `tst_tabs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_requestedBy` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`id`),
  CONSTRAINT `fk_tst_caseReq_assignedTo`  FOREIGN KEY (`assigned_to`)  REFERENCES `tst_users`(`id`),
  CONSTRAINT `fk_tst_caseReq_targetTestCase` FOREIGN KEY (`target_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_completedBy` FOREIGN KEY (`completed_by`) REFERENCES `tst_users`(`id`)
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
  `tab_id`          INT UNSIGNED NOT NULL,          -- FK tst_tabs — denormalized
  `main_menu_id`    INT UNSIGNED NOT NULL,          -- FK tst_main_menus — denormalized "Screen" scope (used when sub_menu_id IS NULL)
  `sub_menu_id`     INT UNSIGNED NULL,              -- FK tst_sub_menus — denormalized "Screen" scope for FR-10 retest
  `requirement_id`  INT UNSIGNED NULL,              -- FK tst_test_case_requirements — optional traceability to the enhancement that introduced this feature
  `title`           VARCHAR(255) NOT NULL,
  `description`     TEXT NULL,                      -- defaults to error_message/error_trace snapshot, editable by QA
  `severity`        ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `status`          ENUM('Open','Assigned','In_Progress','Fixed','Retesting','Reopened','Closed','Escalated','Wont_Fix') NOT NULL DEFAULT 'Open',
  `assigned_to`     INT UNSIGNED NULL,              -- FK tst_users (role='Developer')
  `assigned_by`     INT UNSIGNED NULL,              -- FK tst_users (typically role='QA_Lead')
  `assigned_at`     DATETIME NULL,
  `fixed_by`        INT UNSIGNED NULL,              -- FK tst_users
  `fixed_at`        DATETIME NULL,
  `fix_notes`       TEXT NULL,
  `reopen_count`    SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- incremented each time FR-10's retest loop bounces this bug back
  `closed_by`       INT UNSIGNED NULL,              -- FK tst_users; NULL when system-closed by a passing retest cycle
  `closed_at`       DATETIME NULL,
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`      TIMESTAMP NULL,
  INDEX `idx_tst_bugs_status` (`status`),
  INDEX `idx_tst_bugs_severity` (`severity`),
  INDEX `idx_tst_bugs_testCase` (`test_case_id`),
  INDEX `idx_tst_bugs_assignedTo` (`assigned_to`),
  INDEX `idx_tst_bugs_subMenu` (`sub_menu_id`),
  INDEX `idx_tst_bugs_mainMenu` (`main_menu_id`),
  CONSTRAINT `fk_tst_bugs_runResult`  FOREIGN KEY (`run_result_id`)  REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_bugs_testCase`   FOREIGN KEY (`test_case_id`)   REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_tab`        FOREIGN KEY (`tab_id`)         REFERENCES `tst_tabs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_mainMenu`   FOREIGN KEY (`main_menu_id`)   REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_subMenu`    FOREIGN KEY (`sub_menu_id`)    REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_requirement` FOREIGN KEY (`requirement_id`) REFERENCES `tst_test_case_requirements`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_bugs_assignedTo` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`id`),
  CONSTRAINT `fk_tst_bugs_assignedBy` FOREIGN KEY (`assigned_by`) REFERENCES `tst_users`(`id`),
  CONSTRAINT `fk_tst_bugs_fixedBy`    FOREIGN KEY (`fixed_by`)    REFERENCES `tst_users`(`id`),
  CONSTRAINT `fk_tst_bugs_closedBy`   FOREIGN KEY (`closed_by`)   REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-6.2: Audit trail of every bug status transition (FR-12)
CREATE TABLE IF NOT EXISTS `tst_bug_status_history` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `bug_id`        INT UNSIGNED NOT NULL,           -- FK tst_bugs
  `from_status`   VARCHAR(20) NULL,                -- previous status, NULL on initial creation
  `to_status`     VARCHAR(20) NOT NULL,            -- new status
  `changed_by`    INT UNSIGNED NULL,               -- FK tst_users; NULL for system-driven transitions (e.g. auto Reopen)
  `note`          TEXT NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_tst_bugHistory_bug` (`bug_id`),
  CONSTRAINT `fk_tst_bugHistory_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugHistory_changedBy` FOREIGN KEY (`changed_by`) REFERENCES `tst_users`(`id`)
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
  `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_tst_retestCycles_subMenu` (`sub_menu_id`),
  INDEX `idx_tst_retestCycles_mainMenu` (`main_menu_id`),
  INDEX `idx_tst_retestCycles_status` (`status`),
  CONSTRAINT `fk_tst_retestCycles_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_subMenu`  FOREIGN KEY (`sub_menu_id`)  REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_bug`      FOREIGN KEY (`triggered_by_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_run`      FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-7.2: Many-to-many — which open bugs were covered by a given retest cycle,
-- and the per-bug outcome (FR-10 step 5).
CREATE TABLE IF NOT EXISTS `tst_bug_retest_cycles_jnt` (
  `bug_id`           INT UNSIGNED NOT NULL,         -- FK tst_bugs
  `retest_cycle_id`  INT UNSIGNED NOT NULL,         -- FK tst_retest_cycles
  `outcome`          ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bug_id`, `retest_cycle_id`),
  INDEX `idx_tst_bugRetest_cycle` (`retest_cycle_id`),
  CONSTRAINT `fk_tst_bugRetest_bug`   FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugRetest_cycle` FOREIGN KEY (`retest_cycle_id`) REFERENCES `tst_retest_cycles`(`id`) ON DELETE CASCADE
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
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tst_appSettings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed default settings referenced in testing_requirement_v2.md §13.4
INSERT INTO `tst_app_settings` (`key`, `value`, `value_type`, `description`) VALUES
  ('max_auto_retest_attempts', '5', 'integer', 'FR-10 safety valve: after this many reopen cycles for the same bug, status moves to Escalated instead of auto-retesting again.'),
  ('auto_retest_enabled', 'true', 'boolean', 'Global kill-switch: if false, marking a bug Fixed does not auto-trigger the FR-10 retest cycle (manual re-test only).'),
  ('auto_bug_creation_enabled', 'true', 'boolean', 'If false, failing test_run_results do not auto-create tst_bugs rows; QA must raise bugs manually.'),
  ('bug_fix_sla_hours', '48', 'integer', 'Used by dashboards (FR-12) to flag bugs that have been Assigned/In_Progress longer than this many hours.'),
  ('bug_screenshot_path', '/Users/bkwork/Herd/prime_testing/tests/Screenshots', 'string', 'Path for storing screenshots of Failed TestCases.')
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);


-- ----------------------------------------------------------------------------
-- SECTION 9: CONVENIENCE VIEWS
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
  JOIN `tst_tabs` t            ON t.id = tc.tab_id
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
  LEFT JOIN `tst_users` u ON u.id = r.executed_by;

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
  JOIN `tst_tabs` t          ON t.id = b.tab_id
  JOIN `tst_main_menus` mm   ON mm.id = b.main_menu_id
  LEFT JOIN `tst_sub_menus` sm ON sm.id = b.sub_menu_id
  JOIN `tst_modules` m       ON m.id = tc.module_id
  LEFT JOIN `tst_users` au   ON au.id = b.assigned_to
  LEFT JOIN `tst_users` ab   ON ab.id = b.assigned_by
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
  LEFT JOIN `tst_tabs` t        ON t.id = r.tab_id
  LEFT JOIN `tst_users` ru      ON ru.id = r.requested_by
  LEFT JOIN `tst_users` au      ON au.id = r.assigned_to
  WHERE r.deleted_at IS NULL;
