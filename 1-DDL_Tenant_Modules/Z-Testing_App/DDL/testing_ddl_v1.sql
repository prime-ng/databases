-- =====================================================
-- Prime-AI Testing Automation App — Database Schema
-- Project: prime_ai_testing (standalone Laravel app)
-- Version: v1
-- MySQL 8 Compatible | Single-tenant internal tool DB
-- Based on: testing_requirement.md + preliminary
--           2-New_Primedb/pgdatabase/1-Master_DDLs/test_runner_db.sql
-- Created: 2026-06-12
--
-- Notes:
--  - This schema lives in its own database (e.g. `prime_ai_testing`),
--    independent of global_db / prime_db / tenant_db.
--  - Table prefix: `tst_` (confirmed unused in the Prime-AI prefix registry).
--  - Conventions followed: InnoDB, utf8mb4, soft deletes (`deleted_at`),
--    `is_active`, `created_at`/`updated_at`, `created_by` FK to `tst_users`,
--    `_json` suffix for JSON columns, FK naming `{entity}_id`.
-- =====================================================


-- ----------------------------------------------------------------------------
-- SECTION 0: USERS (lightweight — for executed_by / created_by attribution)
-- ----------------------------------------------------------------------------

-- Minimal local user table for this internal tool. Not synced with Prime-AI's
-- sys_users — just enough to attribute Sync runs, Test runs, and Annotations.
CREATE TABLE IF NOT EXISTS `tst_users` (
  `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`        VARCHAR(100) NOT NULL,
  `email`       VARCHAR(150) NOT NULL,
  `password`    VARCHAR(255) NOT NULL,             -- Hashed Password
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_users_email` (`email`),
  INDEX `idx_tst_users_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 1: HIERARCHY CATALOG
-- Module -> Category -> Main Menu -> Sub Menu -> Tab -> Test Case
-- ----------------------------------------------------------------------------

-- Tab-1.1: Modules discovered from /Users/bkwork/Herd/prime_ai/Modules/*
CREATE TABLE IF NOT EXISTS `tst_modules` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code`          VARCHAR(60) NOT NULL,            -- Folder name, e.g. 'Syllabus', 'Library'
  `name`          VARCHAR(120) NOT NULL,           -- Display name, e.g. 'Syllabus Management'
  `description`   VARCHAR(255) NULL,
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_modules_code` (`code`),
  INDEX `idx_tst_modules_active` (`is_active`),
  CONSTRAINT `fk_tst_modules_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.2: Categories (top-level RBS grouping, e.g. "School Setup", "LMS")
CREATE TABLE IF NOT EXISTS `tst_categories` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `module_id`     INT UNSIGNED NOT NULL,
  `name`          VARCHAR(120) NOT NULL,           -- e.g. 'School Setup'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_categories_module` (`module_id`),
  INDEX `idx_tst_categories_active` (`is_active`),
  UNIQUE KEY `uq_tst_categories_module_name` (`module_id`, `name`),
  CONSTRAINT `fk_tst_categories_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_categories_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.3: Main Menus (e.g. "Syllabus Mgmt.")
CREATE TABLE IF NOT EXISTS `tst_main_menus` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `category_id`   INT UNSIGNED NOT NULL,
  `name`          VARCHAR(120) NOT NULL,
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_mainMenus_category` (`category_id`),
  INDEX `idx_tst_mainMenus_active` (`is_active`),
  UNIQUE KEY `uq_tst_mainMenus_category_name` (`category_id`, `name`),
  CONSTRAINT `fk_tst_mainMenus_category` FOREIGN KEY (`category_id`) REFERENCES `tst_categories`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_mainMenus_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.4: Sub Menus (= one Screen/View + URL, e.g. "Syllabus Master")
CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `main_menu_id`  INT UNSIGNED NOT NULL,
  `name`          VARCHAR(120) NOT NULL,
  `route_url`     VARCHAR(500) NULL,               -- e.g. '/syllabus/lesson'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_subMenus_mainMenu` (`main_menu_id`),
  INDEX `idx_tst_subMenus_active` (`is_active`),
  UNIQUE KEY `uq_tst_subMenus_mainMenu_name` (`main_menu_id`, `name`),
  CONSTRAINT `fk_tst_subMenus_mainMenu` FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_subMenus_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-1.5: Tabs (one Tab = one feature folder under tests/Browser/Modules/{Module}/{Feature})
CREATE TABLE IF NOT EXISTS `tst_tabs` (
  `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `sub_menu_id`   INT UNSIGNED NOT NULL,
  `name`          VARCHAR(120) NOT NULL,           -- e.g. 'Lessons', 'Topic Types'
  `folder_path`   VARCHAR(500) NULL,               -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson'
  `sort_order`    SMALLINT UNSIGNED DEFAULT 1,
  `is_excluded`   TINYINT(1) NOT NULL DEFAULT 0,   -- manually marked "out of scope" (FR-4.3)
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP NULL,
  INDEX `idx_tst_tabs_subMenu` (`sub_menu_id`),
  INDEX `idx_tst_tabs_active` (`is_active`),
  UNIQUE KEY `uq_tst_tabs_subMenu_name` (`sub_menu_id`, `name`),
  CONSTRAINT `fk_tst_tabs_subMenu` FOREIGN KEY (`sub_menu_id`) REFERENCES `tst_sub_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 2: TEST CASE CATALOG
-- ----------------------------------------------------------------------------

-- Tab-2.1: One row per discoverable test case = one test_* method (or one
-- "Not Automated" entry derived from a requirements.md with no matching test file).
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `tab_id`                INT UNSIGNED NOT NULL,
  `module_id`             INT UNSIGNED NOT NULL,         -- denormalized for fast module-level filtering
  `file_path`             VARCHAR(500) NOT NULL,         -- relative to LARAVEL_REPO, e.g. 'tests/Browser/Modules/Syllabus/Lesson/LessonPlanningTest.php'
  `namespace`              VARCHAR(255) NULL,             -- e.g. 'Tests\Browser\Modules\Syllabus\Lesson'
  `class_name`            VARCHAR(150) NOT NULL DEFAULT '',  -- e.g. 'LessonPlanningTest'
  `method_name`           VARCHAR(150) NOT NULL DEFAULT '',  -- e.g. 'test_updating_lesson_planning_dates'; '' for not-automated entries
  `display_name`          VARCHAR(255) NOT NULL,         -- humanized name shown in UI
  `description`           TEXT NULL,                     -- docblock summary / notes
  `test_type`             ENUM('dusk','feature','unit','not_automated') NOT NULL DEFAULT 'dusk',
  `automation_status`     ENUM('automated','draft','not_automated') NOT NULL DEFAULT 'automated',
  `requirements_md_path`  VARCHAR(500) NULL,             -- relative path to requirements.md, if any
  `sort_order`            SMALLINT UNSIGNED DEFAULT 1,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,  -- set to 0 by Sync if no longer found on disk
  `created_by`            INT UNSIGNED NULL,
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP NULL,
  INDEX `idx_tst_testCases_tab` (`tab_id`),
  INDEX `idx_tst_testCases_module` (`module_id`),
  INDEX `idx_tst_testCases_active` (`is_active`),
  INDEX `idx_tst_testCases_status` (`automation_status`),
  UNIQUE KEY `uq_tst_testCases_identity` (`file_path`, `class_name`, `method_name`),
  CONSTRAINT `fk_tst_testCases_tab` FOREIGN KEY (`tab_id`) REFERENCES `tst_tabs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_module` FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-2.2: Tags (e.g. @smoke, @regression, @critical-path) — FR-7
CREATE TABLE IF NOT EXISTS `tst_tags` (
  `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`        VARCHAR(60) NOT NULL,
  `color`       VARCHAR(20) NULL,                 -- e.g. '#FF0000' for UI chips
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_tags_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-2.3: Test Case <-> Tag junction
CREATE TABLE IF NOT EXISTS `tst_test_case_tags_jnt` (
  `test_case_id` INT UNSIGNED NOT NULL,
  `tag_id`       INT UNSIGNED NOT NULL,
  `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`test_case_id`, `tag_id`),
  CONSTRAINT `fk_tst_testCaseTags_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCaseTags_tag` FOREIGN KEY (`tag_id`) REFERENCES `tst_tags`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 3: TEST EXECUTION & HISTORY
-- ----------------------------------------------------------------------------

-- Tab-3.1: One row per "Run" click (a batch execution of one or more test cases)
CREATE TABLE IF NOT EXISTS `tst_test_runs` (
  `id`                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_id`            VARCHAR(64) NOT NULL,           -- e.g. '20260612_143000_a1b2c3'
  `executed_by`       INT UNSIGNED NULL,              -- FK tst_users; nullable for scheduled/system runs
  `trigger_type`      ENUM('manual','scheduled','rerun') NOT NULL DEFAULT 'manual',
  `scope_json`        JSON NULL,                      -- selected module/tab/test_case ids + resolved file list
  `command`           VARCHAR(1000) NULL,             -- exact artisan dusk command executed
  `status`            ENUM('queued','running','completed','failed','cancelled') NOT NULL DEFAULT 'queued',
  `started_at`        DATETIME NULL,
  `finished_at`       DATETIME NULL,
  `duration_seconds`  DECIMAL(10,2) NULL,
  `exit_code`         SMALLINT NULL,
  `total`             INT UNSIGNED NOT NULL DEFAULT 0,
  `passed`            INT UNSIGNED NOT NULL DEFAULT 0,
  `failed`            INT UNSIGNED NOT NULL DEFAULT 0,
  `skipped`           INT UNSIGNED NOT NULL DEFAULT 0,
  `assertions`        INT UNSIGNED NOT NULL DEFAULT 0,
  `raw_output_path`   VARCHAR(500) NULL,              -- relative path under storage/app/test-runs/{run_id}/
  `environment_json`  JSON NULL,                      -- PHP/Chrome versions, APP_ENV, etc.
  `created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tst_testRuns_runId` (`run_id`),
  INDEX `idx_tst_testRuns_executedBy` (`executed_by`),
  INDEX `idx_tst_testRuns_status` (`status`),
  INDEX `idx_tst_testRuns_startedAt` (`started_at`),
  CONSTRAINT `fk_tst_testRuns_executedBy` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-3.2: One row per test case within a run
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
  `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `run_id`                INT UNSIGNED NOT NULL,          -- FK tst_test_runs.id
  `test_case_id`          INT UNSIGNED NULL,              -- FK tst_test_cases.id (nullable: keep history if case later removed)
  `display_name`          VARCHAR(255) NOT NULL,          -- snapshot of test name at run time
  `status`                ENUM('passed','failed','skipped','error') NOT NULL,
  `duration_seconds`      DECIMAL(10,2) NULL,
  `assertions`            INT UNSIGNED NOT NULL DEFAULT 0,
  `error_message`         TEXT NULL,
  `error_trace`           LONGTEXT NULL,
  `screenshot_path`       VARCHAR(500) NULL,              -- failure screenshot, relative to storage/app/test-runs/{run_id}/screenshots/
  `console_log_path`      VARCHAR(500) NULL,
  `source_html_path`      VARCHAR(500) NULL,
  `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_tst_testRunResults_run` (`run_id`),
  INDEX `idx_tst_testRunResults_testCase` (`test_case_id`),
  INDEX `idx_tst_testRunResults_status` (`status`),
  CONSTRAINT `fk_tst_testRunResults_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testRunResults_testCase` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tab-3.3: Rolling per-test-case statistics for fast dashboard queries (FR-5)
-- Maintained by the Reporting/Analytics Service after each run.
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
  `test_case_id`         INT UNSIGNED PRIMARY KEY,
  `last_run_result_id`   INT UNSIGNED NULL,
  `last_status`          ENUM('passed','failed','skipped','error') NULL,
  `last_run_at`          DATETIME NULL,
  `consecutive_failures` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `total_runs`           INT UNSIGNED NOT NULL DEFAULT 0,
  `total_passed`         INT UNSIGNED NOT NULL DEFAULT 0,
  `total_failed`         INT UNSIGNED NOT NULL DEFAULT 0,
  `total_skipped`        INT UNSIGNED NOT NULL DEFAULT 0,
  `pass_rate_30d`        DECIMAL(5,2) NULL,             -- percentage, 0.00 - 100.00
  `avg_duration_seconds` DECIMAL(10,2) NULL,
  `is_flaky`             TINYINT(1) NOT NULL DEFAULT 0, -- status changed across consecutive runs w/o code change
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
  `created_by`     INT UNSIGNED NULL,
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`     TIMESTAMP NULL,
  INDEX `idx_tst_runAnnotations_run` (`run_id`),
  INDEX `idx_tst_runAnnotations_runResult` (`run_result_id`),
  CONSTRAINT `fk_tst_runAnnotations_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_runAnnotations_runResult` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_runAnnotations_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
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
  `cron_expression`  VARCHAR(100) NOT NULL,       -- e.g. '0 2 * * *'
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `last_run_id`      INT UNSIGNED NULL,           -- FK tst_test_runs.id of most recent scheduled run
  `created_by`       INT UNSIGNED NULL,
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_schedules_name` (`name`),
  INDEX `idx_tst_schedules_active` (`is_active`),
  CONSTRAINT `fk_tst_schedules_lastRun` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_schedules_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- SECTION 5: CONVENIENCE VIEWS
-- ----------------------------------------------------------------------------

-- Full catalog view: flattens the hierarchy + latest run status for the UI tree (FR-1)
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
  sm.route_url                AS route_url,
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
JOIN `tst_tabs` t       ON t.id = tc.tab_id
JOIN `tst_sub_menus` sm ON sm.id = t.sub_menu_id
JOIN `tst_main_menus` mm ON mm.id = sm.main_menu_id
JOIN `tst_categories` c  ON c.id = mm.category_id
JOIN `tst_modules` m     ON m.id = tc.module_id
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
