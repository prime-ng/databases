-- ============================================================================
-- Prime-AI Testing Automation App — Database Schema
-- Project  : prime_testing (standalone Laravel app, separate from prime_ai)
-- Version  : v7
-- MySQL 8 Compatible | Single-tenant internal tool DB
-- Based on : Testing_DDL_v6.sql + testing_requirement_v3.md
-- Created  : 2026-06-21
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
--     tst_tabs, tst_test_cases, tst_schedules, tst_app_settings
--
--   TRANSACTION (composite PK (id, user_code) — per-developer data, merged centrally):
--     tst_test_runs, tst_test_run_results, tst_test_case_runs_summary,
--     tst_run_annotations, tst_sync_logs, tst_test_case_requirements,
--     tst_bugs, tst_bug_status_history, tst_retest_cycles,
--     tst_bug_retest_cycles_jnt, tst_audit_logs, tst_data_exports
-- ============================================================================


-- ============================================================================
-- SECTION 0: USERS
-- Lightweight local user table — not synced with prime_ai sys_users.
-- PK is `code` VARCHAR(5) (e.g. 'brij', 'tarun', 'sys').
-- This is a CATALOG table — same across all developer machines.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_users` (
  `code`          VARCHAR(5)   NOT NULL,
  `name`          VARCHAR(50)  NOT NULL,
  `email`         VARCHAR(100) NOT NULL,
  `password`      VARCHAR(512) NOT NULL,                       -- Bcrypt hashed
  `role`          ENUM('Admin','Architect','QA_Lead','Tester','Developer','Reviewer')
                  NULL DEFAULT 'Tester',
  `is_superuser`  TINYINT(1)   NOT NULL DEFAULT 0,
  `is_system`     TINYINT(1)   NOT NULL DEFAULT 0,             -- system users cannot be deleted
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP    NULL,
  PRIMARY KEY (`code`),
  UNIQUE KEY `uq_tst_users_email`  (`email`),
  INDEX  `idx_tst_users_active`    (`is_active`),
  INDEX  `idx_tst_users_role`      (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed: system user for Auto_Retest and scheduled run attribution
INSERT INTO `tst_users` (`code`, `name`, `email`, `password`, `role`, `is_superuser`, `is_system`, `is_active`)
VALUES
  ('sys',   'System',         'system@prime-testing.local',  '$2y$12$placeholder_sys_hash',   'Admin',     0, 1, 1),
  ('brij',  'Brijesh',        'brij@prime-testing.local',    '$2y$12$placeholder_brij_hash',  'Admin',     1, 0, 1),
  ('tarun', 'Tarun',          'tarun@prime-testing.local',   '$2y$12$placeholder_tarun_hash', 'Developer', 0, 0, 1),
  ('shail', 'Shailesh',       'shail@prime-testing.local',   '$2y$12$placeholder_shail_hash', 'Developer', 0, 0, 1),
  ('samer', 'Sameer',         'samer@prime-testing.local',   '$2y$12$placeholder_samer_hash', 'Tester',    0, 0, 1),
  ('gaurv', 'Gaurav',         'gaurv@prime-testing.local',   '$2y$12$placeholder_gaurv_hash', 'Tester',    0, 0, 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);


-- ============================================================================
-- SECTION 1: HIERARCHY CATALOG
-- Module → Category → Main Menu → [Sub Menu (optional)] → Tab → Test Case
-- All CATALOG tables: simple INT PK, same data across all developer machines.
-- ============================================================================

-- 1.1: Modules discovered from /Users/bkwork/Herd/prime_ai/Modules/*
CREATE TABLE IF NOT EXISTS `tst_modules` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(3)    NOT NULL,              -- e.g. 'slb', 'lib', 'sch'
  `name`          VARCHAR(60)   NOT NULL,              -- e.g. 'Syllabus', 'Library'
  `description`   VARCHAR(255)  NULL,
  `folder_name`   VARCHAR(60)   NULL,                  -- prime_ai Modules/ folder name
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `version`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `created_by`    VARCHAR(5)    NULL,                  -- v7 FIXED: was INT UNSIGNED → tst_users(id) which does not exist
  `is_active`     TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_modules_code`   (`code`),
  INDEX  `idx_tst_modules_active`    (`is_active`),
  CONSTRAINT `fk_tst_modules_createdBy`
    FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.2: Categories (top-level RBS grouping, e.g. 'School Setup', 'LMS')
CREATE TABLE IF NOT EXISTS `tst_categories` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `module_id`     INT UNSIGNED  NOT NULL,
  `name`          VARCHAR(120)  NOT NULL,
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active`     TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_categories_moduleName`  (`module_id`, `name`),
  INDEX  `idx_tst_categories_module`         (`module_id`),
  INDEX  `idx_tst_categories_active`         (`is_active`),
  CONSTRAINT `fk_tst_categories_module`
    FOREIGN KEY (`module_id`) REFERENCES `tst_modules`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.3: Main Menus (e.g. 'Syllabus Mgmt.')
CREATE TABLE IF NOT EXISTS `tst_main_menus` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `module_id`     INT UNSIGNED  NOT NULL,
  `category_id`   INT UNSIGNED  NOT NULL,
  `name`          VARCHAR(120)  NOT NULL,
  `route_url`     VARCHAR(500)  NULL,
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active`     TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_mainMenus_categoryName`  (`category_id`, `name`),
  INDEX  `idx_tst_mainMenus_category`         (`category_id`),
  INDEX  `idx_tst_mainMenus_active`           (`is_active`),
  CONSTRAINT `fk_tst_mainMenus_module`
    FOREIGN KEY (`module_id`)   REFERENCES `tst_modules`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_tst_mainMenus_category`
    FOREIGN KEY (`category_id`) REFERENCES `tst_categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.4: Sub Menus (one View/Screen, e.g. 'Syllabus Master')
CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `module_id`     INT UNSIGNED  NOT NULL,
  `main_menu_id`  INT UNSIGNED  NOT NULL,
  `name`          VARCHAR(120)  NOT NULL,
  `route_url`     VARCHAR(500)  NULL,
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active`     TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_subMenus_mainMenuName`  (`main_menu_id`, `name`),
  INDEX  `idx_tst_subMenus_mainMenu`         (`main_menu_id`),
  INDEX  `idx_tst_subMenus_active`           (`is_active`),
  CONSTRAINT `fk_tst_subMenus_module`
    FOREIGN KEY (`module_id`)    REFERENCES `tst_modules`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_tst_subMenus_mainMenu`
    FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.5: Tabs (one feature folder = one Tab)
-- A Tab attaches either to a Sub Menu OR directly to a Main Menu (sub_menu_id nullable).
-- See requirement_v3.md §0.1 — "Screen" definition for FR-10 retest scope.
CREATE TABLE IF NOT EXISTS `tst_tabs` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `module_id`     INT UNSIGNED  NOT NULL,
  `main_menu_id`  INT UNSIGNED  NOT NULL,
  `sub_menu_id`   INT UNSIGNED  NULL,                 -- NULL when Tab attaches directly to Main Menu
  `name`          VARCHAR(120)  NOT NULL,             -- e.g. 'Lessons', 'Topic Types'
  `route_url`     VARCHAR(500)  NULL,
  `folder_path`   VARCHAR(500)  NULL,                 -- relative: tests/Browser/Modules/Syllabus/Lesson
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_excluded`   TINYINT(1)    NOT NULL DEFAULT 0,   -- manually out-of-scope (excluded from UI, not deleted)
  `is_active`     TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`    TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_tabs_subMenuName`   (`sub_menu_id`, `name`),
  INDEX  `idx_tst_tabs_mainMenu`         (`main_menu_id`),
  INDEX  `idx_tst_tabs_subMenu`          (`sub_menu_id`),
  INDEX  `idx_tst_tabs_active`           (`is_active`),
  CONSTRAINT `fk_tst_tabs_module`
    FOREIGN KEY (`module_id`)   REFERENCES `tst_modules`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_mainMenu`
    FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_tabs_subMenu`
    FOREIGN KEY (`sub_menu_id`)  REFERENCES `tst_sub_menus`(`id`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 2: TEST CASE CATALOG
-- CATALOG table — simple INT PK. Same rows across all developer machines
-- (synced from the shared prime_ai codebase).
-- ============================================================================

-- One row per discoverable test method (or 'Not_Automated' entry from requirements.md)
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
  `id`                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`             VARCHAR(5)    NOT NULL,             -- v7 FIXED: FK constraint was missing in v6
  `tab_id`                INT UNSIGNED  NOT NULL,
  `module_id`             INT UNSIGNED  NOT NULL,             -- denormalized for fast module-level filtering
  `file_path`             VARCHAR(500)  NOT NULL,             -- relative: tests/Browser/Modules/Syllabus/Lesson/LessonTest.php
  `namespace`             VARCHAR(255)  NULL,
  `class_name`            VARCHAR(150)  NOT NULL DEFAULT '',
  `method_name`           VARCHAR(150)  NOT NULL DEFAULT '',  -- '' for Not_Automated entries
  `display_name`          VARCHAR(255)  NOT NULL,
  `description`           TEXT          NULL,
  `test_type`             ENUM('Dusk','Feature','Unit','Validation','Business_Condition')
                          NOT NULL DEFAULT 'Dusk',
  `automation_status`     ENUM('Automated','Draft','Not_Automated')
                          NOT NULL DEFAULT 'Automated',
  `requirements_md_path`  VARCHAR(500)  NULL,
  `sort_order`            SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active`             TINYINT(1)    NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_testCases_identity`  (`file_path`(255), `class_name`, `method_name`),
  INDEX  `idx_tst_testCases_tab`          (`tab_id`),
  INDEX  `idx_tst_testCases_module`       (`module_id`),
  INDEX  `idx_tst_testCases_active`       (`is_active`),
  INDEX  `idx_tst_testCases_status`       (`automation_status`),
  INDEX  `idx_tst_testCases_userCode`     (`user_code`),
  CONSTRAINT `fk_tst_testCases_userCode`
    FOREIGN KEY (`user_code`)  REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testCases_tab`
    FOREIGN KEY (`tab_id`)     REFERENCES `tst_tabs`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testCases_module`
    FOREIGN KEY (`module_id`)  REFERENCES `tst_modules`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 3: TEST EXECUTION & HISTORY
-- TRANSACTION tables — composite PK (id, user_code).
-- FK chains propagate user_code so parent/child rows share the same developer context.
-- ============================================================================

-- 3.1: One row per "Run" click — batch execution of one or more test cases.
-- user_code = developer who clicked Run (or 'sys' for Auto_Retest / Scheduled).
-- v7: executed_by merged into user_code (same semantics, now part of composite PK).
CREATE TABLE IF NOT EXISTS `tst_test_runs` (
  `id`                INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`         VARCHAR(5)    NOT NULL,                  -- developer running tests
  `run_id`            VARCHAR(64)   NOT NULL,                  -- '20260612_143000_a1b2c3' — business key, globally unique
  `trigger_type`      ENUM('Manual','Scheduled','Rerun','Auto_Retest')
                      NOT NULL DEFAULT 'Manual',
  `scope_json`        JSON          NULL,                      -- selected module/tab/test_case ids + resolved file list
  `command`           VARCHAR(1000) NULL,                      -- exact artisan dusk command executed
  `status`            ENUM('Queued','Running','Completed','Failed','Cancelled')
                      NOT NULL DEFAULT 'Queued',
  `started_at`        DATETIME      NULL,
  `finished_at`       DATETIME      NULL,
  `duration_seconds`  DECIMAL(10,2) NULL,
  `exit_code`         SMALLINT      NULL,
  `total`             INT UNSIGNED  NOT NULL DEFAULT 0,
  `passed`            INT UNSIGNED  NOT NULL DEFAULT 0,
  `failed`            INT UNSIGNED  NOT NULL DEFAULT 0,
  `skipped`           INT UNSIGNED  NOT NULL DEFAULT 0,
  `assertions`        INT UNSIGNED  NOT NULL DEFAULT 0,
  `raw_output_path`   VARCHAR(500)  NULL,
  `hostname`          VARCHAR(150)  NULL,                      -- v7 NEW: developer machine hostname
  `environment_json`  JSON          NULL,                      -- PHP/Laravel/Chrome versions, OS, APP_ENV, DB seed state
  `created_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  UNIQUE KEY `uq_tst_testRuns_runId`       (`run_id`),
  INDEX  `idx_tst_testRuns_userCode`       (`user_code`),
  INDEX  `idx_tst_testRuns_status`         (`status`),
  INDEX  `idx_tst_testRuns_startedAt`      (`started_at`),
  CONSTRAINT `fk_tst_testRuns_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2: One row per test case within a run.
-- bug_id + bug_user_code added via ALTER at end of file (forward reference to tst_bugs).
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
  `id`                INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`         VARCHAR(5)    NOT NULL,
  `run_id`            INT UNSIGNED  NOT NULL,                  -- FK → tst_test_runs(id, user_code) via composite
  `test_case_id`      INT UNSIGNED  NULL,                      -- nullable: keep history if test case is later removed
  `display_name`      VARCHAR(255)  NOT NULL,                  -- snapshot of name at run time
  `status`            ENUM('Passed','Failed','Skipped','Error') NOT NULL,
  `duration_seconds`  DECIMAL(10,2) NULL,
  `assertions`        INT UNSIGNED  NOT NULL DEFAULT 0,
  `error_message`     TEXT          NULL,
  `error_trace`       LONGTEXT      NULL,
  `screenshot_path`   VARCHAR(500)  NULL,
  `console_log_path`  VARCHAR(500)  NULL,
  `source_html_path`  VARCHAR(500)  NULL,
  `created_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_testRunResults_run`       (`run_id`, `user_code`),
  INDEX  `idx_tst_testRunResults_testCase`  (`test_case_id`),
  INDEX  `idx_tst_testRunResults_status`    (`status`),
  INDEX  `idx_tst_testRunResults_userCode`  (`user_code`),
  CONSTRAINT `fk_tst_testRunResults_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_testRunResults_run`
    FOREIGN KEY (`run_id`, `user_code`) REFERENCES `tst_test_runs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_testRunResults_testCase`
    FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3: Rolling per-test-case statistics for fast dashboard queries (FR-5).
-- v7: PK is now (test_case_id, user_code) — one row per developer per test case.
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
  `test_case_id`          INT UNSIGNED  NOT NULL,
  `user_code`             VARCHAR(5)    NOT NULL,
  `last_run_result_id`    INT UNSIGNED  NULL,
  `last_status`           ENUM('Passed','Failed','Skipped','Error') NULL,
  `last_run_at`           DATETIME      NULL,
  `consecutive_failures`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `total_runs`            INT UNSIGNED  NOT NULL DEFAULT 0,
  `total_passed`          INT UNSIGNED  NOT NULL DEFAULT 0,
  `total_failed`          INT UNSIGNED  NOT NULL DEFAULT 0,
  `total_skipped`         INT UNSIGNED  NOT NULL DEFAULT 0,
  `pass_rate_30d`         DECIMAL(5,2)  NULL,                  -- 0.00–100.00
  `avg_duration_seconds`  DECIMAL(10,2) NULL,
  `is_flaky`              TINYINT(1)    NOT NULL DEFAULT 0,    -- status toggled across consecutive runs without code change
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`test_case_id`, `user_code`),
  INDEX  `idx_tst_caseSummary_lastStatus`  (`last_status`),
  INDEX  `idx_tst_caseSummary_flaky`       (`is_flaky`),
  INDEX  `idx_tst_caseSummary_userCode`    (`user_code`),
  CONSTRAINT `fk_tst_caseSummary_testCase`
    FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_caseSummary_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseSummary_lastRunResult`
    FOREIGN KEY (`last_run_result_id`, `user_code`)
    REFERENCES `tst_test_run_results`(`id`, `user_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 4: ANNOTATIONS, SYNC LOG, SCHEDULES
-- ============================================================================

-- 4.1: User notes on a run or a specific result (FR-7).
-- v7: user_code in PK = the annotator (merged from created_by).
CREATE TABLE IF NOT EXISTS `tst_run_annotations` (
  `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`      VARCHAR(5)    NOT NULL,               -- the annotator
  `run_id`         INT UNSIGNED  NULL,                   -- FK → tst_test_runs(id, user_code) — note on whole run
  `run_result_id`  INT UNSIGNED  NULL,                   -- FK → tst_test_run_results(id, user_code) — note on one result
  `note`           TEXT          NOT NULL,
  `is_known_issue` TINYINT(1)    NOT NULL DEFAULT 0,     -- excludes from flaky-test alerts
  `created_at`     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`     TIMESTAMP     NULL,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_runAnnotations_run`        (`run_id`, `user_code`),
  INDEX  `idx_tst_runAnnotations_runResult`  (`run_result_id`, `user_code`),
  CONSTRAINT `fk_tst_runAnnotations_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_runAnnotations_run`
    FOREIGN KEY (`run_id`, `user_code`) REFERENCES `tst_test_runs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_runAnnotations_runResult`
    FOREIGN KEY (`run_result_id`, `user_code`) REFERENCES `tst_test_run_results`(`id`, `user_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4.2: History of catalog discovery/sync runs.
-- v7: user_code in PK = sync executor (merged from created_by).
CREATE TABLE IF NOT EXISTS `tst_sync_logs` (
  `id`                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`             VARCHAR(5)    NOT NULL,         -- who triggered the sync
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
  INDEX  `idx_tst_syncLogs_status`     (`status`),
  INDEX  `idx_tst_syncLogs_startedAt`  (`started_at`),
  INDEX  `idx_tst_syncLogs_userCode`   (`user_code`),
  CONSTRAINT `fk_tst_syncLogs_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4.3: Scheduled run definitions — CATALOG table, simple PK.
-- v7: last_run_id changed to VARCHAR(64) referencing tst_test_runs.run_id (UNIQUE KEY)
-- instead of the INT PK, to avoid a composite FK from a catalog table.
CREATE TABLE IF NOT EXISTS `tst_schedules` (
  `id`               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(150)  NOT NULL,
  `scope_json`       JSON          NOT NULL,
  `cron_expression`  VARCHAR(100)  NOT NULL,
  `is_active`        TINYINT(1)    NOT NULL DEFAULT 1,
  `last_run_id`      VARCHAR(64)   NULL,                  -- v7: references tst_test_runs.run_id (unique business key)
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_schedules_name`   (`name`),
  INDEX  `idx_tst_schedules_active`    (`is_active`),
  CONSTRAINT `fk_tst_schedules_lastRun`
    FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`run_id`) ON DELETE SET NULL
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
  `status`                ENUM('Pending','In_Progress','Completed','Cancelled')
                          NOT NULL DEFAULT 'Pending',
  `target_test_case_id`   INT UNSIGNED  NULL,             -- set once test case exists in catalog
  `completed_by`          VARCHAR(5)    NULL,             -- v7 FIXED: was INT UNSIGNED → tst_users(id)
  `completed_at`          DATETIME      NULL,
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP     NULL,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_caseReq_module`      (`module_id`),
  INDEX  `idx_tst_caseReq_status`      (`status`),
  INDEX  `idx_tst_caseReq_priority`    (`priority`),
  INDEX  `idx_tst_caseReq_assignedTo`  (`assigned_to`),
  INDEX  `idx_tst_caseReq_userCode`    (`user_code`),
  CONSTRAINT `fk_tst_caseReq_userCode`
    FOREIGN KEY (`user_code`)     REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_module`
    FOREIGN KEY (`module_id`)     REFERENCES `tst_modules`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_tst_caseReq_mainMenu`
    FOREIGN KEY (`main_menu_id`)  REFERENCES `tst_main_menus`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_subMenu`
    FOREIGN KEY (`sub_menu_id`)   REFERENCES `tst_sub_menus`(`id`)  ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_tab`
    FOREIGN KEY (`tab_id`)        REFERENCES `tst_tabs`(`id`)       ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_requestedBy`
    FOREIGN KEY (`requested_by`)  REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_assignedTo`
    FOREIGN KEY (`assigned_to`)   REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_caseReq_targetTestCase`
    FOREIGN KEY (`target_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_caseReq_completedBy`
    FOREIGN KEY (`completed_by`)  REFERENCES `tst_users`(`code`)
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
  `status`                ENUM('Open','Assigned','In_Progress','Fixed','Retesting',
                               'Reopened','Closed','Escalated','Wont_Fix')
                          NOT NULL DEFAULT 'Open',
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
  CONSTRAINT `fk_tst_bugs_userCode`
    FOREIGN KEY (`user_code`)     REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_runResult`
    FOREIGN KEY (`run_result_id`, `user_code`)
    REFERENCES `tst_test_run_results`(`id`, `user_code`) ON DELETE SET NULL,
  CONSTRAINT `fk_tst_bugs_testCase`
    FOREIGN KEY (`test_case_id`)  REFERENCES `tst_test_cases`(`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_tab`
    FOREIGN KEY (`tab_id`)        REFERENCES `tst_tabs`(`id`)         ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_mainMenu`
    FOREIGN KEY (`main_menu_id`)  REFERENCES `tst_main_menus`(`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_subMenu`
    FOREIGN KEY (`sub_menu_id`)   REFERENCES `tst_sub_menus`(`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugs_requirementUserCode`
    FOREIGN KEY (`requirement_user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_assignedTo`
    FOREIGN KEY (`assigned_to`)   REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_assignedBy`
    FOREIGN KEY (`assigned_by`)   REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_fixedBy`
    FOREIGN KEY (`fixed_by`)      REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugs_closedBy`
    FOREIGN KEY (`closed_by`)     REFERENCES `tst_users`(`code`)
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
  INDEX  `idx_tst_bugHistory_bug`       (`bug_id`, `user_code`),
  INDEX  `idx_tst_bugHistory_userCode`  (`user_code`),
  CONSTRAINT `fk_tst_bugHistory_userCode`
    FOREIGN KEY (`user_code`)  REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugHistory_bug`
    FOREIGN KEY (`bug_id`, `user_code`) REFERENCES `tst_bugs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugHistory_changedBy`
    FOREIGN KEY (`changed_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 7: AUTOMATED BUG-FIX VERIFICATION LOOP (FR-10)
-- TRANSACTION tables — composite PK (id, user_code).
-- ============================================================================

-- 7.1: One row per auto-retest cycle triggered for a Screen after a bug is marked 'Fixed'.
CREATE TABLE IF NOT EXISTS `tst_retest_cycles` (
  `id`                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_code`             VARCHAR(5)    NOT NULL,
  `main_menu_id`          INT UNSIGNED  NOT NULL,        -- Screen scope when sub_menu_id IS NULL
  `sub_menu_id`           INT UNSIGNED  NULL,            -- Screen scope when Tab has a Sub Menu
  `triggered_by_bug_id`   INT UNSIGNED  NOT NULL,        -- the bug whose 'Fixed' status started this cycle
  `cycle_number`          SMALLINT UNSIGNED NOT NULL DEFAULT 1, -- 1,2,3... per Screen+bug chain
  `run_id`                INT UNSIGNED  NULL,            -- the scoped Auto_Retest run
  `status`                ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_retestCycles_subMenu`   (`sub_menu_id`),
  INDEX  `idx_tst_retestCycles_mainMenu`  (`main_menu_id`),
  INDEX  `idx_tst_retestCycles_status`    (`status`),
  INDEX  `idx_tst_retestCycles_userCode`  (`user_code`),
  CONSTRAINT `fk_tst_retestCycles_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_retestCycles_mainMenu`
    FOREIGN KEY (`main_menu_id`) REFERENCES `tst_main_menus`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_subMenu`
    FOREIGN KEY (`sub_menu_id`)  REFERENCES `tst_sub_menus`(`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_bug`
    FOREIGN KEY (`triggered_by_bug_id`, `user_code`)
    REFERENCES `tst_bugs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_retestCycles_run`
    FOREIGN KEY (`run_id`, `user_code`)
    REFERENCES `tst_test_runs`(`id`, `user_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7.2: Many-to-many — which open bugs were covered by a given retest cycle and per-bug outcome.
CREATE TABLE IF NOT EXISTS `tst_bug_retest_cycles_jnt` (
  `bug_id`           INT UNSIGNED  NOT NULL,
  `user_code`        VARCHAR(5)    NOT NULL,
  `retest_cycle_id`  INT UNSIGNED  NOT NULL,
  `outcome`          ENUM('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bug_id`, `user_code`, `retest_cycle_id`),
  INDEX  `idx_tst_bugRetest_cycle`     (`retest_cycle_id`, `user_code`),
  INDEX  `idx_tst_bugRetest_userCode`  (`user_code`),
  CONSTRAINT `fk_tst_bugRetest_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
  CONSTRAINT `fk_tst_bugRetest_bug`
    FOREIGN KEY (`bug_id`, `user_code`)
    REFERENCES `tst_bugs`(`id`, `user_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_tst_bugRetest_cycle`
    FOREIGN KEY (`retest_cycle_id`, `user_code`)
    REFERENCES `tst_retest_cycles`(`id`, `user_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 8: APP SETTINGS (FR-11)
-- Generic key/value configuration — CATALOG table, simple PK, no user_code.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `tst_app_settings` (
  `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `key`           VARCHAR(100)  NOT NULL,
  `value`         VARCHAR(500)  NOT NULL,
  `value_type`    ENUM('string','integer','boolean','json') NOT NULL DEFAULT 'string',
  `description`   VARCHAR(255)  NULL,
  `created_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tst_appSettings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed default settings
INSERT INTO `tst_app_settings` (`key`, `value`, `value_type`, `description`) VALUES
  ('max_auto_retest_attempts', '5',     'integer', 'FR-10 safety valve: after this many reopen cycles for the same bug, status → Escalated.'),
  ('auto_retest_enabled',      'true',  'boolean', 'Global kill-switch: false = marking a bug Fixed does NOT auto-trigger the FR-10 retest.'),
  ('auto_bug_creation_enabled','true',  'boolean', 'false = failing run_results do not auto-create tst_bugs rows; QA must raise manually.'),
  ('bug_fix_sla_hours',        '48',    'integer', 'Dashboard alert threshold: bugs in Assigned/In_Progress longer than this are flagged stale.'),
  ('allow_multi_user_import',  'true',  'boolean', 'v7: If true, data from multiple user_codes can be imported into this DB (central mode).'),
  ('central_mode',             'false', 'boolean', 'v7: true = this is the central aggregation DB; false = developer local DB.')
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);


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
  CONSTRAINT `fk_tst_auditLogs_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
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
  `status`              ENUM('Pending','In_Progress','Completed','Failed')
                        NOT NULL DEFAULT 'Pending',
  `record_counts_json`  JSON          NULL,               -- e.g. {"tst_test_runs": 42, "tst_bugs": 15}
  `error_message`       TEXT          NULL,
  `exported_at`         DATETIME      NULL,
  `created_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`, `user_code`),
  INDEX  `idx_tst_dataExports_status`      (`status`),
  INDEX  `idx_tst_dataExports_userCode`    (`user_code`),
  INDEX  `idx_tst_dataExports_exportedAt`  (`exported_at`),
  CONSTRAINT `fk_tst_dataExports_userCode`
    FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 11: FORWARD-REFERENCE — tst_test_run_results.(bug_id, bug_user_code)
-- Added via ALTER to avoid a circular forward reference:
--   tst_bugs references tst_test_run_results (Section 6)
--   tst_test_run_results references tst_bugs (this section)
-- v7: composite FK (bug_id, bug_user_code) → tst_bugs(id, user_code).
-- ============================================================================

ALTER TABLE `tst_test_run_results`
  ADD COLUMN `bug_id`        INT UNSIGNED NULL AFTER `test_case_id`,
  ADD COLUMN `bug_user_code` VARCHAR(5)   NULL AFTER `bug_id`,
  ADD INDEX  `idx_tst_testRunResults_bug` (`bug_id`, `bug_user_code`),
  ADD CONSTRAINT `fk_tst_testRunResults_bug`
    FOREIGN KEY (`bug_id`, `bug_user_code`)
    REFERENCES `tst_bugs`(`id`, `user_code`)
    ON DELETE SET NULL;


-- ============================================================================
-- SECTION 12: CONVENIENCE VIEWS
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
JOIN  `tst_tabs`        t   ON t.id   = tc.tab_id
LEFT JOIN `tst_sub_menus` sm ON sm.id = t.sub_menu_id
JOIN  `tst_main_menus`  mm  ON mm.id  = COALESCE(sm.main_menu_id, t.main_menu_id)
JOIN  `tst_categories`  c   ON c.id   = mm.category_id
JOIN  `tst_modules`     m   ON m.id   = tc.module_id
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
  GREATEST(
    COALESCE(MAX(r.finished_at), '1970-01-01'),
    COALESCE(MAX(b_raised.created_at), '1970-01-01')
  )                                             AS last_activity_at
FROM `tst_users` u
LEFT JOIN `tst_test_runs` r
  ON r.user_code = u.code
LEFT JOIN `tst_bugs` b_raised
  ON b_raised.user_code = u.code
LEFT JOIN `tst_bugs` b_assigned
  ON b_assigned.assigned_to = u.code
LEFT JOIN `tst_bugs` b_fixed
  ON b_fixed.fixed_by = u.code
WHERE u.is_active = 1
  AND u.is_system = 0
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
GROUP BY
  m.name, mm.name, sm.name, t.name, tc.display_name, b.user_code
ORDER BY avg_reopen_count DESC, max_reopen_count DESC;

-- ============================================================================
-- END OF SCHEMA — prime_testing database v7
-- ============================================================================
