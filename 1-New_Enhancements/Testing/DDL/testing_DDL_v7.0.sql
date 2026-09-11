-- =========================================================================================================
-- Prime-AI Testing Application — Database Schema
-- Project  : prime_testing
-- Version  : v7.0
-- Supersedes: testing_DDL_v6.7.sql
-- MySQL    : 8.0.16 or later  (CHECK constraints are enforced from 8.0.16)
-- Engine   : InnoDB / utf8mb4 / utf8mb4_unicode_ci
-- Governed by : TestingApp_BRD_v2.md      (business requirement)
-- Designed in : Solution_Design_v2.md      (solution design)
-- =========================================================================================================
--
-- WHAT THIS SCHEMA IS FOR
--     Local-first test management on each developer/tester machine, plus one central installation that
--     consolidates evidence from every machine and governs the shared catalog.
--
-- -------------------------------------------------------------------------------------------------------
-- THE IDENTITY MODEL  (Solution_Design_v2 §3 — the single most important rule in this schema)
-- -------------------------------------------------------------------------------------------------------
--     Three identities. Each has exactly one job. None substitutes for another.
--
--     1. SURROGATE KEY        BIGINT/INT AUTO_INCREMENT
--                             Used for every internal relationship and every foreign key.
--                             Meaningless outside one database. Never exported as an identity.
--
--     2. BUSINESS CODE        module_code, cat_code, mm_code, sm_code, ts_code, test_case_code, ...
--                             Stable, human-meaningful, identical on every machine.
--                             UNIQUE on the catalog table it belongs to.
--                             This is what an export bundle carries and what import matches on.
--
--     3. DISTRIBUTED IDENTITY (machine_id, source_<entity>_id)
--                             Applied to transaction records that are generated independently on many
--                             machines: runs, bugs, requirements, exports, discovery logs, audit.
--                             UNIQUE, and it is what makes re-import a no-op.
--
--     v6.7 used the business code as the foreign key in every child table. That is correct for
--     RECOGNITION and wrong for STORAGE: 22 bytes per index entry on the largest tables, awkward
--     relations, and multi-column ON DELETE SET NULL constraints that MySQL handles badly.
--     v7.0 keeps (ts_code, test_case_code) as the UNIQUE business identity of a test case and joins
--     children by tst_test_cases.id. Every guarantee in the BRD is preserved.
--
-- -------------------------------------------------------------------------------------------------------
-- IMPORT RULE
-- -------------------------------------------------------------------------------------------------------
--     Local:    tst_test_runs.id            = local AUTO_INCREMENT
--               tst_test_runs.source_run_id = the same local id
--               tst_test_runs.machine_id    = this machine's registered id
--
--     Central:  tst_test_runs.id            = a NEW central AUTO_INCREMENT
--               source_run_id / machine_id  = preserved from the source
--               UNIQUE(machine_id, source_run_id) makes a repeated import a no-op.
--
--     Catalog references inside a bundle travel as business codes and are resolved to local surrogate
--     ids once, at the import boundary. Every resolution is recorded in tst_import_record_map, which
--     is what makes an import reversible.
--
-- -------------------------------------------------------------------------------------------------------
-- MACHINE IDENTITY  (read this before installing on a second machine)
-- -------------------------------------------------------------------------------------------------------
--     tst_machines.id MUST be assigned centrally and inserted EXPLICITLY on the local machine.
--     Never allow a local database to auto-increment its own machine id, or every machine becomes
--     machine_id = 1 and all consolidated evidence collides.
--         id = 1        reserved for the central installation
--         id >= 10      local machines
--     machine_fingerprint is re-checked at boot. On mismatch the application must refuse to record
--     new runs and raise an administrative alert. Re-imaged hardware is registered as a NEW machine.
--
-- -------------------------------------------------------------------------------------------------------
-- CORRECTIONS TO v6.7  (Solution_Design_v2 §16.1)
-- -------------------------------------------------------------------------------------------------------
--      1. tst_machines declared a UNIQUE KEY on machine_fingerprint, a column that did not exist.
--         -> CREATE TABLE failed. Column now declared.
--      2. tst_users.code was VARCHAR(3) while ~30 tables referenced it as VARCHAR(10).
--         -> Every FK failed. All user-code columns are now VARCHAR(10).
--      3. Master seeds inserted created_by='super', a user code that was never seeded.
--         -> FK violation. Seeds now use 'S1'.
--      4. The users seed relied on a self-referencing FK that only worked with checks disabled.
--         -> The bootstrap row is inserted with NULL and updated afterwards.
--      5. Menus/screens referenced cat_code and mm_code alone, so a menu could belong to a category
--         in a different module. -> Composite UNIQUE keys and composite FKs now prevent it.
--      6. tst_git_commit_files had two overlapping ON DELETE SET NULL FKs on the same ts_code column.
--         -> Replaced by a single test_case_id FK.
--      7. Result status had no Blocked / Not_Executed. -> Added (BRD §9.11).
--      8. Run status had no Interrupted / Timed_Out and there was no heartbeat.
--         -> Added, so BR-EXEC-07 is implementable.
--      9. Evidence was three fixed path columns. -> tst_run_result_artifacts.
--     10. The composite test-case key was propagated into 9 child tables. -> Surrogate FK.
--     11. Summary enums did not match result enums and had no rebuild provenance. -> Aligned.
--     12. Git hashes were declared CHAR(64), but a Git SHA-1 is 40 hex characters. CHAR pads to 64,
--         so a hash read from `git log` never compared equal to a stored one. -> VARCHAR(40).
--     13. The footer said "END OF ENHANCED SCHEMA v8.0" in a file headed v6.7. -> Corrected.
--
-- -------------------------------------------------------------------------------------------------------
-- SECTIONS
-- -------------------------------------------------------------------------------------------------------
--      0  Platform: settings, schema version, master registry
--      1  Identity and access: users, roles, permissions, machines
--      2  Reference masters
--      3  Application catalog: module -> screen -> test case -> steps -> versions
--      4  Test case origin, equivalence and tags
--      5  Requirements and the test-case work backlog
--      6  Dependencies, path mappings and impact analysis
--      7  Suites and schedules
--      8  Git and change context
--      9  Environments
--     10  Execution: runs, items, attempts, steps, artefacts, signatures, summary
--     11  Notes and discovery
--     12  Defects: bugs, occurrences, links, comments, known issues, retests
--     13  Releases
--     14  Export, import, conflicts and record mapping
--     15  AI analyses and recommendations
--     16  Notifications
--     17  Audit
--     18  Views
--     19  Seed data
-- =========================================================================================================

SET NAMES utf8mb4;
SET SESSION sql_require_primary_key = 0;
SET FOREIGN_KEY_CHECKS = 0;


-- =========================================================================================================
-- SECTION 0: PLATFORM
-- =========================================================================================================

-- The schema version this database is at. Written by migrations, read by the export/import validator.
-- An export bundle carries this value; the central importer compares it before applying anything.
CREATE TABLE IF NOT EXISTS `tst_schema_version` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `version`           VARCHAR(20) NOT NULL,               -- semantic, e.g. '7.0.0'
    `applied_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `applied_by`        VARCHAR(10) NULL,
    `notes`             VARCHAR(500) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_schema_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_app_settings` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `group_name`        VARCHAR(50) NOT NULL DEFAULT 'General',
    `key`               VARCHAR(100) NOT NULL,
    `value`             VARCHAR(1000) NOT NULL,
    `value_type`        ENUM('STRING','INTEGER','DECIMAL','BOOLEAN','DATE','TIME','DATETIME','JSON') NOT NULL DEFAULT 'STRING',
    `description`       VARCHAR(500) NULL,
    -- is_system     : shipped with the application; a user may not delete it.
    -- is_local_only : never travels in a catalog bundle (paths, machine specifics).
    -- is_editable   : a user with the Settings permission may change the value.
    `is_system`         TINYINT(1) NOT NULL DEFAULT 0,
    `is_local_only`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_editable`       TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_app_settings_key` (`key`),
    INDEX `idx_tst_app_settings_group` (`group_name`,`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Which master table feeds which UI field. Keeps v6.5's generic-dropdown convenience for the UI while
-- the underlying values stay in dedicated master tables that can carry real foreign keys.
CREATE TABLE IF NOT EXISTS `tst_master_registry` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `target_table`      VARCHAR(64) NOT NULL,               -- e.g. 'tst_test_cases'
    `target_column`     VARCHAR(64) NOT NULL,               -- e.g. 'test_layer_code'
    `master_table`      VARCHAR(64) NOT NULL,               -- e.g. 'tst_testing_layers'
    `label`             VARCHAR(100) NOT NULL,              -- e.g. 'Testing Layer'
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_master_registry` (`target_table`,`target_column`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 1: IDENTITY AND ACCESS
-- =========================================================================================================

-- Users and machines are registered CENTRALLY by one accountable administrator and distributed to every
-- machine in a catalog bundle. The same user_code and machine_code mean the same thing everywhere.
CREATE TABLE IF NOT EXISTS `tst_users` (
    -- Format: first letter of the primary role (A/Q/T/D/R/S) + a number, e.g. 'A1', 'D02', 'T15'.
    -- Declared VARCHAR(10) so that every created_by/updated_by/deleted_by column matches exactly.
    -- InnoDB requires identical string types on both sides of a foreign key. This was defect #2 in v6.7.
    `code`              VARCHAR(10) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `email`             VARCHAR(150) NOT NULL,
    `password`          VARCHAR(512) NOT NULL,
    `primary_role_code` VARCHAR(30) NOT NULL DEFAULT 'Tester',   -- FK -> tst_roles.code
    `is_superuser`      TINYINT(1) NOT NULL DEFAULT 0,
    `is_system`         TINYINT(1) NOT NULL DEFAULT 0,           -- system actor: scheduler, importer, retest engine
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `deactivated_at`    DATETIME NULL,
    `last_login_at`     DATETIME NULL,
    `notify_email`      TINYINT(1) NOT NULL DEFAULT 1,
    `preferences_json`  JSON NULL,
    `created_by`        VARCHAR(10) NULL,
    `updated_by`        VARCHAR(10) NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    UNIQUE KEY `uq_tst_users_email` (`email`),
    INDEX `idx_tst_users_active` (`is_active`),
    INDEX `idx_tst_users_role` (`primary_role_code`),
    CONSTRAINT `fk_tst_users_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_users_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_users_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_roles` (
    `code`              VARCHAR(30) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `description`       VARCHAR(500) NULL,
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_system`         TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_permissions` (
    `code`              VARCHAR(60) NOT NULL,               -- e.g. 'bug.close', 'import.apply'
    `name`              VARCHAR(120) NOT NULL,
    `area`              VARCHAR(40) NOT NULL,               -- Catalog, Execution, Defects, Sync, Admin, ...
    `description`       VARCHAR(500) NULL,
    `is_sensitive`      TINYINT(1) NOT NULL DEFAULT 0,      -- requires re-authentication
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`code`),
    INDEX `idx_tst_permissions_area` (`area`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_role_permissions` (
    `role_code`         VARCHAR(30) NOT NULL,
    `permission_code`   VARCHAR(60) NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`role_code`,`permission_code`),
    CONSTRAINT `fk_tst_role_perms_role` FOREIGN KEY (`role_code`) REFERENCES `tst_roles`(`code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_role_perms_perm` FOREIGN KEY (`permission_code`) REFERENCES `tst_permissions`(`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- A user may hold responsibilities beyond their primary role (BR-USER-07).
CREATE TABLE IF NOT EXISTS `tst_user_roles` (
    `user_code`         VARCHAR(10) NOT NULL,
    `role_code`         VARCHAR(30) NOT NULL,
    `granted_by`        VARCHAR(10) NULL,
    `granted_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_code`,`role_code`),
    CONSTRAINT `fk_tst_user_roles_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_user_roles_role` FOREIGN KEY (`role_code`) REFERENCES `tst_roles`(`code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_user_roles_granted_by` FOREIGN KEY (`granted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One row per registered installation.
-- IMPORTANT: insert the id EXPLICITLY on a local machine, using the id issued centrally. See the header.
CREATE TABLE IF NOT EXISTS `tst_machines` (
    `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_code`          VARCHAR(20) NOT NULL,           -- user_code + '-' + sequence, e.g. 'A1-1', 'D02-2'
    `owner_user_code`       VARCHAR(10) NOT NULL,           -- the person this installation belongs to
    `machine_name`          VARCHAR(150) NOT NULL,
    `machine_model`         VARCHAR(150) NULL,
    `os_name`               VARCHAR(80) NULL,
    `os_version`            VARCHAR(120) NULL,
    `architecture`          VARCHAR(30) NULL,
    `hostname`              VARCHAR(150) NULL,
    `hardware_serial`       VARCHAR(150) NULL,
    -- Declared here. v6.7 indexed this column without declaring it, which made CREATE TABLE fail.
    -- sha256(hostname + os + hardware serial + install path), re-checked at every boot.
    `machine_fingerprint`   CHAR(64) NULL,
    `app_version`           VARCHAR(20) NULL,               -- Testing Application version on this machine
    `schema_version`        VARCHAR(20) NULL,               -- schema version on this machine
    `catalog_version`       VARCHAR(20) NULL,               -- catalog bundle version last applied
    `prime_ai_repo_path`    VARCHAR(1000) NULL,
    `evidence_root_path`    VARCHAR(1000) NULL,
    `is_central`            TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `registration_status`   ENUM('Registered','Pending','Suspended','Retired') NOT NULL DEFAULT 'Registered',
    `first_seen_at`         DATETIME NULL,
    `last_seen_at`          DATETIME NULL,
    `retired_at`            DATETIME NULL,
    `registered_by`         VARCHAR(10) NOT NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_machines_code` (`machine_code`),
    UNIQUE KEY `uq_tst_machines_fingerprint` (`machine_fingerprint`),
    INDEX `idx_tst_machines_active` (`is_active`,`registration_status`),
    INDEX `idx_tst_machines_owner` (`owner_user_code`),
    INDEX `idx_tst_machines_hostname` (`hostname`),
    CONSTRAINT `fk_tst_machines_owner` FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_machines_registered_by` FOREIGN KEY (`registered_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Per-machine, per-screen allocation of test_case_code values, so two machines working offline in
-- Central Catalog mode cannot mint the same test case number (Solution_Design_v2 §4.2).
CREATE TABLE IF NOT EXISTS `tst_code_allocations` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`        SMALLINT UNSIGNED NOT NULL,
    `ts_code`           VARCHAR(20) NOT NULL,
    `block_from`        SMALLINT UNSIGNED NOT NULL,
    `block_to`          SMALLINT UNSIGNED NOT NULL,
    `next_value`        SMALLINT UNSIGNED NOT NULL,
    `allocated_by`      VARCHAR(10) NOT NULL,
    `allocated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `exhausted_at`      DATETIME NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_code_alloc` (`machine_id`,`ts_code`,`block_from`),
    INDEX `idx_tst_code_alloc_screen` (`ts_code`),
    CONSTRAINT `chk_tst_code_alloc_range` CHECK (`block_to` >= `block_from` AND `next_value` >= `block_from`),
    CONSTRAINT `fk_tst_code_alloc_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_code_alloc_by` FOREIGN KEY (`allocated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 2: REFERENCE MASTERS
-- Dedicated tables rather than one generic key-value master, so that real foreign keys can be declared.
-- tst_master_registry (§0) tells the UI which master feeds which field.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_test_case_types` (
    `code`          VARCHAR(30) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `description`   VARCHAR(500) NULL,
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NOT NULL,
    `updated_by`    VARCHAR(10) NOT NULL,
    `deleted_by`    VARCHAR(10) NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_tc_types_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_types_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_types_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_testing_methods` (
    `code`          VARCHAR(30) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `description`   VARCHAR(500) NULL,
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NOT NULL,
    `updated_by`    VARCHAR(10) NOT NULL,
    `deleted_by`    VARCHAR(10) NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_methods_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_methods_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_methods_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_testing_technologies` (
    `code`          VARCHAR(30) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `description`   VARCHAR(500) NULL,
    `adapter_class` VARCHAR(255) NULL,      -- the execution adapter that runs this technology
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NOT NULL,
    `updated_by`    VARCHAR(10) NOT NULL,
    `deleted_by`    VARCHAR(10) NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_tech_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tech_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tech_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tst_testing_layers` (
    `code`          VARCHAR(30) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `description`   VARCHAR(500) NULL,
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NOT NULL,
    `updated_by`    VARCHAR(10) NOT NULL,
    `deleted_by`    VARCHAR(10) NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_layers_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_layers_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_layers_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Lifecycle state of a test case DEFINITION (not of its execution).
CREATE TABLE IF NOT EXISTS `tst_test_case_statuses` (
    `code`          VARCHAR(30) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `description`   VARCHAR(500) NULL,
    `is_selectable` TINYINT(1) NOT NULL DEFAULT 1,  -- may automatic selection pick a test case in this state
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NOT NULL,
    `updated_by`    VARCHAR(10) NOT NULL,
    `deleted_by`    VARCHAR(10) NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`code`),
    CONSTRAINT `fk_tst_tc_status_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_status_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_status_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Free classification, so a test case can carry several labels at once (BR-TC-07).
CREATE TABLE IF NOT EXISTS `tst_tags` (
    `id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`          VARCHAR(40) NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `colour`        VARCHAR(9) NULL,
    `description`   VARCHAR(500) NULL,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    VARCHAR(10) NOT NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tags_code` (`code`),
    CONSTRAINT `fk_tst_tags_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 3: APPLICATION CATALOG
--     Module -> Category -> Main Menu -> Sub Menu (optional) -> Tab/Screen -> Test Case
--
--     Business codes are the stable cross-machine identity of every level, so the same catalog can exist
--     on every machine and be recognised on import. COMPOSITE foreign keys are declared at every level:
--     v6.7 referenced cat_code and mm_code alone, which allowed a main menu to belong to a category in a
--     different module and silently corrupted the hierarchy (defect #5).
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_modules` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`       VARCHAR(10) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `description`       VARCHAR(500) NULL,
    `folder_name`       VARCHAR(120) NULL,          -- e.g. 'Modules/Fees' in the Prime-AI tree
    `owner_user_code`   VARCHAR(10) NULL,
    `criticality`       ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `sort_order`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `version`           INT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_modules_code` (`module_code`),
    INDEX `idx_tst_modules_active` (`is_active`),
    INDEX `idx_tst_modules_criticality` (`criticality`),
    CONSTRAINT `fk_tst_modules_owner` FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_modules_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_modules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_modules_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_categories` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`       VARCHAR(10) NOT NULL,
    `cat_code`          VARCHAR(10) NOT NULL,
    `name`              VARCHAR(120) NOT NULL,
    `description`       VARCHAR(500) NULL,
    `sort_order`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_categories_code` (`cat_code`),
    -- Parent key for the composite FK from tst_main_menus.
    UNIQUE KEY `uq_tst_categories_module_cat` (`module_code`,`cat_code`),
    UNIQUE KEY `uq_tst_categories_module_name` (`module_code`,`name`),
    CONSTRAINT `fk_tst_categories_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_categories_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_categories_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_categories_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_main_menus` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`       VARCHAR(10) NOT NULL,
    `cat_code`          VARCHAR(10) NOT NULL,
    `mm_code`           VARCHAR(12) NOT NULL,
    `name`              VARCHAR(120) NOT NULL,
    `route_url`         VARCHAR(500) NULL,
    `sort_order`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_main_menus_code` (`mm_code`),
    -- Parent key for the composite FKs from tst_sub_menus and tst_tabs_screens.
    UNIQUE KEY `uq_tst_main_menus_path` (`module_code`,`cat_code`,`mm_code`),
    INDEX `idx_tst_main_menus_module_cat` (`module_code`,`cat_code`),
    CONSTRAINT `fk_tst_main_menus_category` FOREIGN KEY (`module_code`,`cat_code`)
        REFERENCES `tst_categories`(`module_code`,`cat_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_main_menus_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_main_menus_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_main_menus_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`       VARCHAR(10) NOT NULL,
    `cat_code`          VARCHAR(10) NOT NULL,
    `mm_code`           VARCHAR(12) NOT NULL,
    `sm_code`           VARCHAR(15) NOT NULL,
    `name`              VARCHAR(120) NOT NULL,
    `route_url`         VARCHAR(500) NULL,
    `sort_order`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_sub_menus_code` (`sm_code`),
    -- Parent key for the composite FK from tst_tabs_screens.
    UNIQUE KEY `uq_tst_sub_menus_path` (`module_code`,`cat_code`,`mm_code`,`sm_code`),
    INDEX `idx_tst_sub_menus_parent` (`module_code`,`cat_code`,`mm_code`),
    CONSTRAINT `fk_tst_sub_menus_main_menu` FOREIGN KEY (`module_code`,`cat_code`,`mm_code`)
        REFERENCES `tst_main_menus`(`module_code`,`cat_code`,`mm_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_sub_menus_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_sub_menus_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_sub_menus_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- A screen is the smallest addressable, testable surface of Prime-AI, and the unit of the authoring
-- pipeline: requirement document -> test specification (TcList) -> implemented test cases -> executed.
CREATE TABLE IF NOT EXISTS `tst_tabs_screens` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`           VARCHAR(10) NOT NULL,
    `cat_code`              VARCHAR(10) NOT NULL,
    `mm_code`               VARCHAR(12) NOT NULL,
    `sm_code`               VARCHAR(15) NULL,           -- optional level (BR-STRUCT-02)
    `ts_code`               VARCHAR(20) NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    `description`           VARCHAR(1000) NULL,
    `route_url`             VARCHAR(500) NULL,
    `folder_path`           VARCHAR(500) NULL,          -- source folder, used by path resolution
    `criticality`           ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `owner_user_code`       VARCHAR(10) NULL,

    -- Authoring pipeline (restored from v6.5 and extended). These make "how far along is module X?"
    -- answerable directly from the catalog.
    `requirements_md_path`  VARCHAR(1000) NULL,
    `requir_doc_status`     ENUM('Pending','In-Progress','In-Review','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
    `tc_list_md_path`       VARCHAR(1000) NULL,
    `tc_list_status`        ENUM('Pending','In-Progress','In-Review','Approved','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
    `dev_status`            ENUM('Pending','Under-Development','In-Review','Ready-For-Testing','Testing-InProgress','Testing-Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
    `tc_creation_status`    ENUM('Pending','In-Progress','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
    `test_run_status`       ENUM('Not-Run','Partially-Run','Fully-Run','Failing','Blocked') NOT NULL DEFAULT 'Not-Run',

    -- Out of testing scope, with a stated reason (BR-STRUCT-05). Never deleted.
    `is_excluded`           TINYINT(1) NOT NULL DEFAULT 0,
    `exclusion_reason`      VARCHAR(500) NULL,
    `excluded_by`           VARCHAR(10) NULL,
    `excluded_at`           DATETIME NULL,

    `is_discovered`         TINYINT(1) NOT NULL DEFAULT 0,  -- came from discovery, not from a person
    `is_confirmed`          TINYINT(1) NOT NULL DEFAULT 1,  -- a person has confirmed it (BR-DISC-01)
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tabs_screens_code` (`ts_code`),
    INDEX `idx_tst_tabs_screens_module` (`module_code`),
    INDEX `idx_tst_tabs_screens_parent` (`module_code`,`cat_code`,`mm_code`,`sm_code`),
    INDEX `idx_tst_tabs_screens_active` (`is_active`,`is_excluded`),
    INDEX `idx_tst_tabs_screens_pipeline` (`module_code`,`dev_status`,`tc_creation_status`),
    INDEX `idx_tst_tabs_screens_criticality` (`criticality`),
    FULLTEXT KEY `ft_tst_tabs_screens_name` (`name`,`description`),

    CONSTRAINT `fk_tst_tabs_screens_main_menu` FOREIGN KEY (`module_code`,`cat_code`,`mm_code`)
        REFERENCES `tst_main_menus`(`module_code`,`cat_code`,`mm_code`) ON DELETE RESTRICT,
    -- sm_code is nullable; MySQL treats a composite FK containing a NULL as satisfied, so screens that
    -- hang directly off a main menu are permitted (BR-STRUCT-02).
    CONSTRAINT `fk_tst_tabs_screens_sub_menu` FOREIGN KEY (`module_code`,`cat_code`,`mm_code`,`sm_code`)
        REFERENCES `tst_sub_menus`(`module_code`,`cat_code`,`mm_code`,`sm_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tabs_screens_owner` FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tabs_screens_excluded_by` FOREIGN KEY (`excluded_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tabs_screens_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tabs_screens_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tabs_screens_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------------------------------------------
-- THE CANONICAL TEST CASE
--     Business identity : UNIQUE (ts_code, test_case_code)   <- what import matches on, what a user sees
--     Storage identity  : id                                 <- what every child table joins by
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ts_code`               VARCHAR(20) NOT NULL,
    `test_case_code`        SMALLINT UNSIGNED NOT NULL,     -- sequence within the screen

    -- Automation coordinates. NULL for a purely manual test case.
    `file_path`             VARCHAR(500) NULL,
    `namespace`             VARCHAR(255) NULL,
    `class_name`            VARCHAR(150) NULL,
    `method_name`           VARCHAR(150) NULL,

    `display_name`          VARCHAR(255) NOT NULL,
    `description`           TEXT NULL,
    `preconditions`         TEXT NULL,                      -- what must be true before execution
    `test_data_note`        TEXT NULL,                      -- what data state the test needs

    `test_case_type_code`   VARCHAR(30) NOT NULL,
    `test_method_code`      VARCHAR(30) NOT NULL,           -- Manual / Automated / Hybrid
    `test_technology_code`  VARCHAR(30) NOT NULL,
    `test_layer_code`       VARCHAR(30) NOT NULL,
    `status_code`           VARCHAR(30) NOT NULL DEFAULT 'Draft',
    `criticality`           ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',

    `expected_duration_sec` DECIMAL(10,2) NULL,
    `requirements_md_path`  VARCHAR(500) NULL,

    -- sha256 over the normalised definition, including ordered steps. Drives versioning and
    -- equivalence detection. See Solution_Design_v2 §4.4.
    `definition_hash`       CHAR(64) NULL,
    `version_no`            INT UNSIGNED NOT NULL DEFAULT 1,

    -- Provenance (BR-TC-03). Retained permanently, including after consolidation.
    `origin_machine_id`     SMALLINT UNSIGNED NULL,
    `origin_user_code`      VARCHAR(10) NULL,
    `is_discovered`         TINYINT(1) NOT NULL DEFAULT 0,
    `is_confirmed`          TINYINT(1) NOT NULL DEFAULT 1,
    -- The implementation has disappeared from the source tree. Never deleted (BR-TC-12, BR-DISC-06).
    `is_orphaned`           TINYINT(1) NOT NULL DEFAULT 0,
    `orphaned_at`           DATETIME NULL,
    `last_seen_in_source_at` DATETIME NULL,
    `cloned_from_id`        INT UNSIGNED NULL,

    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `retired_at`            DATETIME NULL,
    `retired_reason`        VARCHAR(500) NULL,

    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_cases_business` (`ts_code`,`test_case_code`),
    INDEX `idx_tst_test_cases_screen` (`ts_code`,`is_active`),
    INDEX `idx_tst_test_cases_status` (`status_code`,`is_active`),
    INDEX `idx_tst_test_cases_method_layer` (`test_method_code`,`test_layer_code`),
    INDEX `idx_tst_test_cases_criticality` (`criticality`,`is_active`),
    INDEX `idx_tst_test_cases_hash` (`definition_hash`),
    INDEX `idx_tst_test_cases_orphaned` (`is_orphaned`),
    INDEX `idx_tst_test_cases_file` (`file_path`(191)),
    INDEX `idx_tst_test_cases_class_method` (`class_name`,`method_name`),
    FULLTEXT KEY `ft_tst_test_cases_text` (`display_name`,`description`),

    CONSTRAINT `fk_tst_test_cases_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_test_cases_type` FOREIGN KEY (`test_case_type_code`) REFERENCES `tst_test_case_types`(`code`),
    CONSTRAINT `fk_tst_test_cases_method` FOREIGN KEY (`test_method_code`) REFERENCES `tst_testing_methods`(`code`),
    CONSTRAINT `fk_tst_test_cases_technology` FOREIGN KEY (`test_technology_code`) REFERENCES `tst_testing_technologies`(`code`),
    CONSTRAINT `fk_tst_test_cases_layer` FOREIGN KEY (`test_layer_code`) REFERENCES `tst_testing_layers`(`code`),
    CONSTRAINT `fk_tst_test_cases_status` FOREIGN KEY (`status_code`) REFERENCES `tst_test_case_statuses`(`code`),
    CONSTRAINT `fk_tst_test_cases_origin_machine` FOREIGN KEY (`origin_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_cases_origin_user` FOREIGN KEY (`origin_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_cases_cloned_from` FOREIGN KEY (`cloned_from_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_cases_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_cases_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_cases_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Manual and hybrid test cases need steps. v6.7 had none, so a manual tester had nothing to read and
-- nowhere to record what happened per step (BRD §9.5).
CREATE TABLE IF NOT EXISTS `tst_test_case_steps` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_case_id`      INT UNSIGNED NOT NULL,
    `step_no`           SMALLINT UNSIGNED NOT NULL,
    `action`            TEXT NOT NULL,              -- what the tester does
    `expected_result`   TEXT NOT NULL,              -- what must happen
    `test_data_note`    VARCHAR(1000) NULL,
    `is_optional`       TINYINT(1) NOT NULL DEFAULT 0,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tc_steps` (`test_case_id`,`step_no`),
    CONSTRAINT `chk_tst_tc_steps_no` CHECK (`step_no` >= 1),
    CONSTRAINT `fk_tst_tc_steps_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_steps_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_steps_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- An immutable snapshot of a PREVIOUS definition. Written when definition_hash changes, so a historical
-- result can still be rendered as the test case stood when it ran (BR-VERSION-03).
CREATE TABLE IF NOT EXISTS `tst_test_case_versions` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_case_id`              INT UNSIGNED NOT NULL,
    `version_no`                INT UNSIGNED NOT NULL,
    `definition_hash`           CHAR(64) NULL,
    `file_path`                 VARCHAR(500) NULL,
    `class_name`                VARCHAR(150) NULL,
    `method_name`               VARCHAR(150) NULL,
    `display_name`              VARCHAR(255) NULL,
    `description`               TEXT NULL,
    `preconditions`             TEXT NULL,
    `steps_json`                JSON NULL,              -- the ordered steps as they were at this version
    `test_case_type_code`       VARCHAR(30) NULL,
    `test_method_code`          VARCHAR(30) NULL,
    `test_technology_code`      VARCHAR(30) NULL,
    `test_layer_code`           VARCHAR(30) NULL,
    `criticality`               ENUM('Low','Medium','High','Critical') NULL,
    `change_summary`            VARCHAR(1000) NULL,
    `captured_from_commit_hash` VARCHAR(40) NULL,
    `captured_by`               VARCHAR(10) NOT NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tc_versions` (`test_case_id`,`version_no`),
    INDEX `idx_tst_tc_versions_hash` (`definition_hash`),
    CONSTRAINT `fk_tst_tc_versions_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_versions_captured_by` FOREIGN KEY (`captured_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 4: TEST CASE ORIGIN, EQUIVALENCE AND TAGS
--
--     This section resolves the contradiction between BRD §10 (one shared, countable catalog) and
--     BRD §11 (people independently author the same test). v6.7 implemented only the first.
--
--     tst_test_cases        the canonical catalog  -- what coverage is counted against
--     tst_source_test_cases what one machine authored, before the organisation has decided whether it
--                           is the same thing. Never auto-merged (R-03, R-10).
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_source_test_cases` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Distributed identity of an independently authored test case.
    `origin_machine_id`     SMALLINT UNSIGNED NOT NULL,
    `author_user_code`      VARCHAR(10) NOT NULL,
    `ts_code`               VARCHAR(20) NOT NULL,
    `source_test_case_code` SMALLINT UNSIGNED NOT NULL,     -- the number as minted locally

    `display_name`          VARCHAR(255) NOT NULL,
    `description`           TEXT NULL,
    `file_path`             VARCHAR(500) NULL,
    `class_name`            VARCHAR(150) NULL,
    `method_name`           VARCHAR(150) NULL,
    `steps_json`            JSON NULL,
    `definition_hash`       CHAR(64) NULL,

    -- Resolution against the canonical catalog.
    `canonical_test_case_id` INT UNSIGNED NULL,
    `link_status`           ENUM('Unmapped','Proposed_Same','Confirmed_Same','Confirmed_Different','Promoted','Superseded')
                            NOT NULL DEFAULT 'Unmapped',
    `link_score`            DECIMAL(4,3) NULL,              -- 0.000 - 1.000, how strongly they match
    `link_evidence_json`    JSON NULL,                      -- why the application proposed it (BR-AI-03)
    `link_decided_by`       VARCHAR(10) NULL,
    `link_decided_at`       DATETIME NULL,
    `link_decision_note`    VARCHAR(1000) NULL,

    `imported_via_import_id` BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_source_tc_identity` (`origin_machine_id`,`author_user_code`,`ts_code`,`source_test_case_code`),
    INDEX `idx_tst_source_tc_canonical` (`canonical_test_case_id`),
    INDEX `idx_tst_source_tc_status` (`link_status`),
    INDEX `idx_tst_source_tc_hash` (`definition_hash`),
    INDEX `idx_tst_source_tc_screen` (`ts_code`),
    CONSTRAINT `fk_tst_source_tc_machine` FOREIGN KEY (`origin_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_source_tc_author` FOREIGN KEY (`author_user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_source_tc_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_source_tc_canonical` FOREIGN KEY (`canonical_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_source_tc_decided_by` FOREIGN KEY (`link_decided_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Relationships between two CANONICAL test cases: duplicate, equivalent, superseded, variant.
-- Insert-only: a reversal writes a new row and stamps superseded_at on the old one, so the decision
-- history survives (BR-TC-IND-05).
CREATE TABLE IF NOT EXISTS `tst_test_case_links` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_case_id`      INT UNSIGNED NOT NULL,
    `linked_test_case_id` INT UNSIGNED NOT NULL,
    `link_type`         ENUM('Proposed_Equivalent','Confirmed_Equivalent','Confirmed_Different','Duplicate_Of','Variant_Of','Supersedes')
                        NOT NULL DEFAULT 'Proposed_Equivalent',
    `score`             DECIMAL(4,3) NULL,
    `evidence_json`     JSON NULL,
    `proposed_by`       VARCHAR(10) NULL,       -- a person, or the system user for an automatic proposal
    `decided_by`        VARCHAR(10) NULL,
    `decided_at`        DATETIME NULL,
    `note`              VARCHAR(1000) NULL,
    `superseded_at`     DATETIME NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_tc_links_case` (`test_case_id`,`link_type`),
    INDEX `idx_tst_tc_links_linked` (`linked_test_case_id`),
    INDEX `idx_tst_tc_links_open` (`link_type`,`superseded_at`),
    CONSTRAINT `chk_tst_tc_links_not_self` CHECK (`test_case_id` <> `linked_test_case_id`),
    CONSTRAINT `fk_tst_tc_links_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_links_linked` FOREIGN KEY (`linked_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_links_proposed_by` FOREIGN KEY (`proposed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tc_links_decided_by` FOREIGN KEY (`decided_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_test_case_tags` (
    `test_case_id`  INT UNSIGNED NOT NULL,
    `tag_id`        SMALLINT UNSIGNED NOT NULL,
    `tagged_by`     VARCHAR(10) NOT NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`test_case_id`,`tag_id`),
    INDEX `idx_tst_tc_tags_tag` (`tag_id`),
    CONSTRAINT `fk_tst_tc_tags_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_tags_tag` FOREIGN KEY (`tag_id`) REFERENCES `tst_tags`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_tags_by` FOREIGN KEY (`tagged_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 5: REQUIREMENTS AND THE TEST-CASE WORK BACKLOG
--
--     v1 used the word "requirement" for two different things. They are separated permanently here:
--
--     tst_app_requirements          what Prime-AI must DO. Tests are mapped to it to measure coverage.
--     tst_test_case_requirements    what the TEST TEAM must BUILD. A backlog item, not a requirement.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_app_requirements` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `req_code`          VARCHAR(40) NOT NULL,           -- stable business code, e.g. 'FIN-REQ-014'
    `module_code`       VARCHAR(10) NOT NULL,
    `ts_code`           VARCHAR(20) NULL,               -- when the requirement is screen-specific
    `title`             VARCHAR(255) NOT NULL,
    `description`       TEXT NULL,
    `acceptance_criteria` TEXT NULL,
    `source_document`   VARCHAR(1000) NULL,             -- the FRD/BRD it came from
    `criticality`       ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `status`            ENUM('Draft','Approved','Implemented','Changed','Retired') NOT NULL DEFAULT 'Draft',
    `version_no`        INT UNSIGNED NOT NULL DEFAULT 1,
    `owner_user_code`   VARCHAR(10) NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_app_req_code` (`req_code`),
    INDEX `idx_tst_app_req_module` (`module_code`,`status`),
    INDEX `idx_tst_app_req_screen` (`ts_code`),
    INDEX `idx_tst_app_req_criticality` (`criticality`),
    FULLTEXT KEY `ft_tst_app_req_text` (`title`,`description`),
    CONSTRAINT `fk_tst_app_req_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_app_req_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_app_req_owner` FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_app_req_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_app_req_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_app_req_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Requirement <-> test coverage, in both directions (BR-REQ-01 .. 03).
CREATE TABLE IF NOT EXISTS `tst_app_requirement_test_cases` (
    `requirement_id`    BIGINT UNSIGNED NOT NULL,
    `test_case_id`      INT UNSIGNED NOT NULL,
    `coverage_type`     ENUM('Full','Partial','Negative','Boundary','Integration') NOT NULL DEFAULT 'Full',
    `mapped_by`         VARCHAR(10) NOT NULL,
    `note`              VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`requirement_id`,`test_case_id`),
    INDEX `idx_tst_req_tc_case` (`test_case_id`),
    CONSTRAINT `fk_tst_req_tc_req` FOREIGN KEY (`requirement_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_req_tc_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_req_tc_by` FOREIGN KEY (`mapped_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- The TEST-CASE WORK BACKLOG. "Create a test for X", "automate Y", "retire Z".
-- Carries a distributed identity because it can be raised independently on any machine.
CREATE TABLE IF NOT EXISTS `tst_test_case_requirements` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`            SMALLINT UNSIGNED NOT NULL,
    `source_requirement_id` BIGINT UNSIGNED NOT NULL,
    `raised_by_user_code`   VARCHAR(10) NOT NULL,

    `request_type`          ENUM('Create','Modify','Automate','Retire','Investigate') NOT NULL DEFAULT 'Create',
    `module_code`           VARCHAR(10) NOT NULL,
    `ts_code`               VARCHAR(20) NULL,
    `proposed_tab_name`     VARCHAR(150) NULL,
    `proposed_folder_path`  VARCHAR(1000) NULL,

    `title`                 VARCHAR(255) NOT NULL,
    `description`           TEXT NULL,
    `priority`              ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `target_release`        VARCHAR(100) NULL,

    -- Where the request came from (BR-WORK-05).
    `origin_type`           ENUM('Person','Requirement','Coverage_Gap','Bug','Discovery','AI') NOT NULL DEFAULT 'Person',
    `origin_requirement_id` BIGINT UNSIGNED NULL,

    `requested_by`          VARCHAR(10) NULL,
    `assigned_to`           VARCHAR(10) NULL,
    `assigned_at`           DATETIME NULL,
    `status`                ENUM('Pending','In_Progress','Completed','Cancelled','Hold') NOT NULL DEFAULT 'Pending',

    `target_test_case_id`   INT UNSIGNED NULL,      -- the test case this request produced
    `completed_by`          VARCHAR(10) NULL,
    `completed_at`          DATETIME NULL,
    `completion_note`       VARCHAR(1000) NULL,

    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_tc_req_source` (`machine_id`,`source_requirement_id`),
    INDEX `idx_tst_tc_req_module` (`module_code`),
    INDEX `idx_tst_tc_req_status` (`status`,`priority`),
    INDEX `idx_tst_tc_req_assigned` (`assigned_to`,`status`),
    INDEX `idx_tst_tc_req_target` (`target_test_case_id`),
    CONSTRAINT `fk_tst_tc_req_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tc_req_raised_by` FOREIGN KEY (`raised_by_user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_req_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_tc_req_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tc_req_origin_req` FOREIGN KEY (`origin_requirement_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tc_req_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tc_req_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tc_req_target_case` FOREIGN KEY (`target_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_tc_req_completed_by` FOREIGN KEY (`completed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 6: DEPENDENCIES, PATH MAPPINGS AND IMPACT ANALYSIS
--     This is what turns "what changed?" into "what should we run?" (BRD §9.18).
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_module_dependencies` (
    `module_code`               VARCHAR(10) NOT NULL,
    `depends_on_module_code`    VARCHAR(10) NOT NULL,
    `dependency_type`           ENUM('Functional','Data','Shared_Component','API','Integration','Navigation','Other') NOT NULL DEFAULT 'Functional',
    `impact_weight`             TINYINT UNSIGNED NOT NULL DEFAULT 5,   -- 1 (weak) .. 10 (strong); decays with depth
    `note`                      VARCHAR(500) NULL,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                VARCHAR(10) NOT NULL,
    `updated_by`                VARCHAR(10) NOT NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`module_code`,`depends_on_module_code`),
    INDEX `idx_tst_module_dep_parent` (`depends_on_module_code`),
    CONSTRAINT `chk_tst_module_dep_not_self` CHECK (`module_code` <> `depends_on_module_code`),
    CONSTRAINT `chk_tst_module_dep_weight` CHECK (`impact_weight` BETWEEN 1 AND 10),
    CONSTRAINT `fk_tst_module_dep_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_module_dep_parent` FOREIGN KEY (`depends_on_module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_module_dep_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_module_dep_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_test_case_dependencies` (
    `test_case_id`              INT UNSIGNED NOT NULL,
    `depends_on_test_case_id`   INT UNSIGNED NOT NULL,
    `dependency_type`           ENUM('Prerequisite','Functional','Data','Navigation','API','Integration','Shared_Component','Regression','Other') NOT NULL DEFAULT 'Functional',
    -- Prerequisite means: if the parent fails, this test is recorded Blocked, not Failed (BR-DEP-02).
    `is_blocking`               TINYINT(1) NOT NULL DEFAULT 0,
    `impact_weight`             TINYINT UNSIGNED NOT NULL DEFAULT 5,
    `note`                      VARCHAR(500) NULL,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                VARCHAR(10) NOT NULL,
    `updated_by`                VARCHAR(10) NOT NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`test_case_id`,`depends_on_test_case_id`),
    INDEX `idx_tst_tc_dep_parent` (`depends_on_test_case_id`),
    INDEX `idx_tst_tc_dep_blocking` (`is_blocking`),
    CONSTRAINT `chk_tst_tc_dep_not_self` CHECK (`test_case_id` <> `depends_on_test_case_id`),
    CONSTRAINT `chk_tst_tc_dep_weight` CHECK (`impact_weight` BETWEEN 1 AND 10),
    CONSTRAINT `fk_tst_tc_dep_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_dep_parent` FOREIGN KEY (`depends_on_test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_tc_dep_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_tc_dep_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- How a changed source path resolves to a module, a screen or a test case.
-- Without this, impact analysis requires somebody to hand-map thousands of files. v6.7 stored the
-- resolved module and screen on each changed file with no rule for how they got there.
CREATE TABLE IF NOT EXISTS `tst_path_mappings` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `pattern`           VARCHAR(500) NOT NULL,          -- glob, e.g. 'Modules/Fees/**'
    `target_type`       ENUM('Module','Screen','TestCase','Ignore') NOT NULL DEFAULT 'Module',
    `module_code`       VARCHAR(10) NULL,
    `ts_code`           VARCHAR(20) NULL,
    `test_case_id`      INT UNSIGNED NULL,
    `confidence`        DECIMAL(4,3) NOT NULL DEFAULT 0.800,    -- how strongly a match implies impact
    `priority`          SMALLINT UNSIGNED NOT NULL DEFAULT 100, -- lower wins; most specific first
    `note`              VARCHAR(500) NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_path_mappings_pattern` (`pattern`),
    INDEX `idx_tst_path_mappings_priority` (`is_active`,`priority`),
    CONSTRAINT `chk_tst_path_map_confidence` CHECK (`confidence` BETWEEN 0 AND 1),
    CONSTRAINT `fk_tst_path_map_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_path_map_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_path_map_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_path_map_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_path_map_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- An impact analysis is a NAMED, RETAINED, REVIEWABLE proposal, not a transient list (BR-IMPACT-01).
CREATE TABLE IF NOT EXISTS `tst_impact_analyses` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`            SMALLINT UNSIGNED NOT NULL,
    `source_analysis_id`    BIGINT UNSIGNED NOT NULL,
    `analysis_name`         VARCHAR(200) NOT NULL,
    `source_type`           ENUM('Commit_Range','Single_Commit','Bug_Fix','Release','Manual','Requirement_Change') NOT NULL,
    `repository_code`       VARCHAR(100) NULL,
    `from_commit_hash`      VARCHAR(40) NULL,
    `to_commit_hash`        VARCHAR(40) NULL,
    `bug_id`                BIGINT UNSIGNED NULL,       -- FK added in the deferred block (bugs come later)
    `release_id`            BIGINT UNSIGNED NULL,       -- FK added in the deferred block
    `requested_by`          VARCHAR(10) NOT NULL,
    `status`                ENUM('Draft','Proposed','Approved','Rejected','Executed','Superseded') NOT NULL DEFAULT 'Draft',
    `approved_by`           VARCHAR(10) NULL,
    `approved_at`           DATETIME NULL,
    `executed_run_id`       BIGINT UNSIGNED NULL,       -- FK added in the deferred block

    `changed_file_count`    INT UNSIGNED NOT NULL DEFAULT 0,
    `unresolved_file_count` INT UNSIGNED NOT NULL DEFAULT 0,   -- paths no mapping rule matched: a blind spot
    `affected_module_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `affected_screen_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `proposed_test_count`   INT UNSIGNED NOT NULL DEFAULT 0,
    `included_test_count`   INT UNSIGNED NOT NULL DEFAULT 0,
    `excluded_test_count`   INT UNSIGNED NOT NULL DEFAULT 0,

    -- Measured after the fact: defects found inside the proposed scope vs. outside it (KPI K-05).
    `defects_found_in_scope`     INT UNSIGNED NOT NULL DEFAULT 0,
    `defects_found_out_of_scope` INT UNSIGNED NOT NULL DEFAULT 0,

    `parameters_json`       JSON NULL,      -- the algorithm settings used, so the result is reproducible
    `summary`               TEXT NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_impact_source` (`machine_id`,`source_analysis_id`),
    INDEX `idx_tst_impact_status` (`status`,`created_at`),
    INDEX `idx_tst_impact_commit` (`repository_code`,`to_commit_hash`),
    INDEX `idx_tst_impact_bug` (`bug_id`),
    INDEX `idx_tst_impact_release` (`release_id`),
    CONSTRAINT `fk_tst_impact_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_impact_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_impact_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One proposed test case, with the reason and confidence for its inclusion. EXCLUDED items are retained
-- with their reason, so the proposal can state what it deliberately left out (BR-IMPACT-06).
CREATE TABLE IF NOT EXISTS `tst_impact_analysis_items` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `analysis_id`       BIGINT UNSIGNED NOT NULL,
    `test_case_id`      INT UNSIGNED NOT NULL,
    `reason`            ENUM('Direct_Change','Dependency','Historical_Correlation','Open_Bug','Critical','Regression_Policy','Manual_Addition',
                             'Flaky_Excluded','Retired_Excluded','Orphaned_Excluded','Screen_Excluded','Manual_Removal') NOT NULL,
    `is_included`       TINYINT(1) NOT NULL DEFAULT 1,
    `confidence`        DECIMAL(4,3) NOT NULL DEFAULT 0.500,
    `dependency_depth`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `evidence_json`     JSON NULL,          -- the changed files, commits and prior failures relied upon
    `decided_by`        VARCHAR(10) NULL,   -- set when a person overrode the algorithm
    `decided_at`        DATETIME NULL,
    `decision_note`     VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_impact_items` (`analysis_id`,`test_case_id`),
    INDEX `idx_tst_impact_items_case` (`test_case_id`),
    INDEX `idx_tst_impact_items_reason` (`analysis_id`,`is_included`,`reason`),
    CONSTRAINT `chk_tst_impact_items_conf` CHECK (`confidence` BETWEEN 0 AND 1),
    CONSTRAINT `fk_tst_impact_items_analysis` FOREIGN KEY (`analysis_id`) REFERENCES `tst_impact_analyses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_impact_items_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_impact_items_decided_by` FOREIGN KEY (`decided_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 7: SUITES
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_test_suites` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `suite_code`        VARCHAR(40) NOT NULL,
    `name`              VARCHAR(150) NOT NULL,
    `suite_type`        ENUM('Smoke','Regression','Integration','Critical','Full','Bug_Retest','Release','Custom') NOT NULL DEFAULT 'Custom',
    `description`       TEXT NULL,
    -- A suite may be explicit membership, a rule, or both (BR-SUITE-06).
    `is_rule_based`     TINYINT(1) NOT NULL DEFAULT 0,
    `rule_json`         JSON NULL,          -- e.g. {"module":["FIN"],"criticality":["Critical","High"]}
    `version_no`        INT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_suites_code` (`suite_code`),
    INDEX `idx_tst_test_suites_type` (`suite_type`,`is_active`),
    CONSTRAINT `fk_tst_test_suites_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_suites_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_suites_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_test_suite_items` (
    `suite_id`      INT UNSIGNED NOT NULL,
    `test_case_id`  INT UNSIGNED NOT NULL,
    `priority`      ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `sequence_no`   INT UNSIGNED NOT NULL DEFAULT 1,
    `added_by`      VARCHAR(10) NOT NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`suite_id`,`test_case_id`),
    INDEX `idx_tst_suite_items_case` (`test_case_id`),
    CONSTRAINT `fk_tst_suite_items_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_suite_items_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_suite_items_by` FOREIGN KEY (`added_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Composition as it stood when a version was published. A run records the suite version it used, so
-- changing the suite today never alters what a past run is reported to have executed (BR-SUITE-04/05).
CREATE TABLE IF NOT EXISTS `tst_test_suite_versions` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `suite_id`          INT UNSIGNED NOT NULL,
    `version_no`        INT UNSIGNED NOT NULL,
    `member_count`      INT UNSIGNED NOT NULL DEFAULT 0,
    `members_json`      JSON NOT NULL,      -- resolved [{test_case_id, ts_code, test_case_code}, ...]
    `change_summary`    VARCHAR(1000) NULL,
    `captured_by`       VARCHAR(10) NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_suite_versions` (`suite_id`,`version_no`),
    CONSTRAINT `fk_tst_suite_versions_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_suite_versions_by` FOREIGN KEY (`captured_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 8: GIT AND CHANGE CONTEXT
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_git_repositories` (
    `repository_code`       VARCHAR(100) NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    `local_path`            VARCHAR(1000) NULL,
    `remote_url`            VARCHAR(500) NULL,
    `default_branch`        VARCHAR(200) NULL DEFAULT 'main',
    `last_ingested_commit`  VARCHAR(40) NULL,
    `last_ingested_at`      DATETIME NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            VARCHAR(10) NOT NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`repository_code`),
    CONSTRAINT `fk_tst_git_repos_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- VARCHAR(40) rather than CHAR(64): Git SHA-1 hashes are 40 hex characters. v6.7 used CHAR(64), which
-- pads every hash with 24 spaces and breaks equality comparison against a value read from `git log`.
CREATE TABLE IF NOT EXISTS `tst_git_commits` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `repository_code`       VARCHAR(100) NOT NULL,
    `commit_hash`           VARCHAR(40) NOT NULL,
    `short_hash`            VARCHAR(12) NULL,
    `branch_name`           VARCHAR(200) NULL,
    `parent_commit_hash`    VARCHAR(40) NULL,
    `merge_commit_hash`     VARCHAR(40) NULL,
    `author_user_code`      VARCHAR(10) NULL,       -- resolved to a Testing Application user where possible
    `author_name`           VARCHAR(150) NULL,
    `author_email`          VARCHAR(200) NULL,
    `commit_message`        TEXT NULL,
    `is_merge_commit`       TINYINT(1) NOT NULL DEFAULT 0,
    `files_changed`         INT UNSIGNED NOT NULL DEFAULT 0,
    `lines_added`           INT UNSIGNED NOT NULL DEFAULT 0,
    `lines_removed`         INT UNSIGNED NOT NULL DEFAULT 0,
    `committed_at`          DATETIME NULL,
    `ingested_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_git_commits_repo_hash` (`repository_code`,`commit_hash`),
    INDEX `idx_tst_git_commits_branch` (`branch_name`),
    INDEX `idx_tst_git_commits_date` (`committed_at`),
    INDEX `idx_tst_git_commits_author` (`author_user_code`),
    CONSTRAINT `fk_tst_git_commits_repo` FOREIGN KEY (`repository_code`) REFERENCES `tst_git_repositories`(`repository_code`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_git_commits_author` FOREIGN KEY (`author_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One changed file, with its resolution to a module / screen / test case.
-- v6.7 declared two overlapping ON DELETE SET NULL foreign keys on the same ts_code column, which is
-- undefined behaviour. Here a single test_case_id FK carries the precise link and module_code/ts_code
-- are indexed resolution results maintained by the path-mapping service.
CREATE TABLE IF NOT EXISTS `tst_git_commit_files` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `commit_id`         BIGINT UNSIGNED NOT NULL,
    `file_path`         VARCHAR(1000) NOT NULL,
    `old_file_path`     VARCHAR(1000) NULL,
    `change_type`       ENUM('Added','Modified','Deleted','Renamed','Copied','Unknown') NOT NULL DEFAULT 'Modified',
    `lines_added`       INT UNSIGNED NOT NULL DEFAULT 0,
    `lines_removed`     INT UNSIGNED NOT NULL DEFAULT 0,

    -- Resolution results. resolution_source records HOW they were derived, so an unresolved path is
    -- visible as a blind spot in impact analysis rather than silently absent.
    `module_code`       VARCHAR(10) NULL,
    `ts_code`           VARCHAR(20) NULL,
    `test_case_id`      INT UNSIGNED NULL,
    `resolution_source` ENUM('Test_File','Screen_Path','Path_Mapping','Module_Convention','Manual','Unresolved') NOT NULL DEFAULT 'Unresolved',
    `path_mapping_id`   INT UNSIGNED NULL,
    `impact_level`      ENUM('Low','Medium','High','Critical','Unknown') NOT NULL DEFAULT 'Unknown',
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_git_files` (`commit_id`,`file_path`(500)),
    INDEX `idx_tst_git_files_module` (`module_code`),
    INDEX `idx_tst_git_files_screen` (`ts_code`),
    INDEX `idx_tst_git_files_case` (`test_case_id`),
    INDEX `idx_tst_git_files_unresolved` (`resolution_source`),
    INDEX `idx_tst_git_files_path` (`file_path`(191)),
    CONSTRAINT `fk_tst_git_files_commit` FOREIGN KEY (`commit_id`) REFERENCES `tst_git_commits`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_git_files_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_git_files_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_git_files_mapping` FOREIGN KEY (`path_mapping_id`) REFERENCES `tst_path_mappings`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 9: ENVIRONMENTS
--     An environment is identified by a repeatable fingerprint over its material attributes, not by free
--     text. This is what makes "it fails only on Windows with Chrome 141" answerable (BRD §9.21).
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_environment_profiles` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- sha256 over the normalised material attributes below.
    `env_fingerprint`   CHAR(64) NOT NULL,
    `env_name`          VARCHAR(150) NULL,          -- a friendly label, assigned once recognised
    `env_type`          ENUM('Local','CI','Staging','Production_Like','Other') NOT NULL DEFAULT 'Local',
    `os_name`           VARCHAR(80) NULL,
    `os_version`        VARCHAR(120) NULL,
    `php_version`       VARCHAR(30) NULL,
    `laravel_version`   VARCHAR(30) NULL,
    `database_engine`   VARCHAR(50) NULL,
    `database_version`  VARCHAR(50) NULL,
    `browser_name`      VARCHAR(50) NULL,
    `browser_version`   VARCHAR(50) NULL,
    `driver_version`    VARCHAR(50) NULL,
    `app_env`           VARCHAR(30) NULL,           -- local / testing / staging
    `app_version`       VARCHAR(30) NULL,
    `config_profile`    VARCHAR(100) NULL,
    `attributes_json`   JSON NULL,                  -- anything else that was captured
    `first_seen_at`     DATETIME NULL,
    `last_seen_at`      DATETIME NULL,
    `run_count`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_env_fingerprint` (`env_fingerprint`),
    INDEX `idx_tst_env_type` (`env_type`),
    INDEX `idx_tst_env_browser` (`browser_name`,`browser_version`),
    INDEX `idx_tst_env_os` (`os_name`,`os_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 10: EXECUTION
--
--     tst_test_runs             one execution EVENT
--       tst_test_run_scopes     why the run exists
--       tst_test_run_items      which test cases were selected, and why each one
--         tst_test_run_results  one row per ATTEMPT  (never overwritten)
--           tst_test_run_result_steps    per-step outcomes for manual execution
--           tst_run_result_artifacts     evidence
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_test_runs` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Distributed identity. On a local database source_run_id equals id.
    -- On the central database id is re-issued and this pair is preserved, which is what makes a
    -- repeated import a no-op.
    `machine_id`            SMALLINT UNSIGNED NOT NULL,
    `source_run_id`         BIGINT UNSIGNED NOT NULL,

    -- Attribution. The initiator may be a developer while the executor is the system user, for a
    -- scheduled run or an automatic retest (BR-EXEC-02).
    `initiated_by`          VARCHAR(10) NULL,
    `executed_by`           VARCHAR(10) NULL,

    `trigger_type`          ENUM('Manual','Scheduled','Rerun','Auto_Retest','Bug_Retest','Impact_Selected',
                                 'Enhancement','Integration','Regression','Git_Merge','Release','CI') NOT NULL DEFAULT 'Manual',

    `suite_id`              INT UNSIGNED NULL,
    `suite_version_no`      INT UNSIGNED NULL,      -- the composition actually executed (BR-SUITE-05)
    `impact_analysis_id`    BIGINT UNSIGNED NULL,
    `schedule_id`           INT UNSIGNED NULL,      -- FK added in the deferred block
    `release_id`            BIGINT UNSIGNED NULL,   -- FK added in the deferred block
    `parent_run_id`         BIGINT UNSIGNED NULL,   -- for a rerun or a retest of an earlier run

    `run_name`              VARCHAR(200) NULL,
    `reason`                VARCHAR(500) NULL,

    -- Code version under test (BR-EXEC-04). Without this a result cannot be interpreted historically.
    `repository_code`       VARCHAR(100) NULL,
    `branch_name`           VARCHAR(200) NULL,
    `commit_hash`           VARCHAR(40) NULL,
    `merge_commit_hash`     VARCHAR(40) NULL,
    `base_commit_hash`      VARCHAR(40) NULL,
    `working_tree_dirty`    TINYINT(1) NOT NULL DEFAULT 0,  -- uncommitted changes were present

    `environment_profile_id` INT UNSIGNED NULL,
    `environment_json`      JSON NULL,              -- the raw capture the fingerprint was derived from

    `command`               VARCHAR(2000) NULL,
    `status`                ENUM('Queued','Running','Completed','Failed','Cancelled','Interrupted','Timed_Out') NOT NULL DEFAULT 'Queued',
    `queued_at`             DATETIME NULL,
    `started_at`            DATETIME NULL,
    `finished_at`           DATETIME NULL,
    `duration_seconds`      DECIMAL(12,3) NULL,
    `exit_code`             SMALLINT NULL,

    -- Interruption detection (BR-EXEC-07). A watchdog moves any Running run whose heartbeat has stopped
    -- to Interrupted, retaining every result already recorded. v6.7 could not express this at all.
    `heartbeat_at`          DATETIME NULL,
    `lock_token`            CHAR(36) NULL,
    `cancelled_by`          VARCHAR(10) NULL,
    `cancelled_at`          DATETIME NULL,
    `cancel_reason`         VARCHAR(500) NULL,

    -- Roll-ups over FINAL attempts only. Recomputed from results, never incremented ad hoc, so they
    -- cannot drift from the underlying evidence (R-13).
    `total_tc_count`        MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `passed_tc_count`       MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `failed_tc_count`       MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `error_tc_count`        MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `skipped_tc_count`      MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `blocked_tc_count`      MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    `not_executed_tc_count` MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,

    `total_assertion_count`  INT UNSIGNED NOT NULL DEFAULT 0,
    `passed_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `failed_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,

    `raw_output_path`       VARCHAR(1000) NULL,

    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_test_runs_source` (`machine_id`,`source_run_id`),
    INDEX `idx_tst_test_runs_machine_date` (`machine_id`,`started_at`),
    INDEX `idx_tst_test_runs_executor_date` (`executed_by`,`started_at`),
    INDEX `idx_tst_test_runs_initiator_date` (`initiated_by`,`started_at`),
    INDEX `idx_tst_test_runs_trigger_status` (`trigger_type`,`status`),
    INDEX `idx_tst_test_runs_commit` (`repository_code`,`commit_hash`),
    INDEX `idx_tst_test_runs_parent` (`parent_run_id`),
    INDEX `idx_tst_test_runs_suite` (`suite_id`),
    INDEX `idx_tst_test_runs_env` (`environment_profile_id`),
    INDEX `idx_tst_test_runs_impact` (`impact_analysis_id`),
    INDEX `idx_tst_test_runs_release` (`release_id`),
    -- Supports the interruption watchdog.
    INDEX `idx_tst_test_runs_watchdog` (`status`,`heartbeat_at`),

    CONSTRAINT `fk_tst_test_runs_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_test_runs_initiated_by` FOREIGN KEY (`initiated_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_executed_by` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_impact` FOREIGN KEY (`impact_analysis_id`) REFERENCES `tst_impact_analyses`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_env` FOREIGN KEY (`environment_profile_id`) REFERENCES `tst_environment_profiles`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_parent` FOREIGN KEY (`parent_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_test_runs_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_runs_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_test_runs_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- What the run was asked to cover. One run may have several scope rows.
CREATE TABLE IF NOT EXISTS `tst_test_run_scopes` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`            BIGINT UNSIGNED NOT NULL,
    `scope_type`        ENUM('Module','Screen','TestCase','Suite','Bug','Requirement','Commit','Impact_Analysis','Release','Full') NOT NULL,
    `module_code`       VARCHAR(10) NULL,
    `ts_code`           VARCHAR(20) NULL,
    `test_case_id`      INT UNSIGNED NULL,
    `suite_id`          INT UNSIGNED NULL,
    `bug_id`            BIGINT UNSIGNED NULL,       -- FK added in the deferred block
    `requirement_id`    BIGINT UNSIGNED NULL,
    `repository_code`   VARCHAR(100) NULL,
    `commit_hash`       VARCHAR(40) NULL,
    `description`       VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_run_scopes_run` (`run_id`),
    INDEX `idx_tst_run_scopes_module` (`module_code`),
    INDEX `idx_tst_run_scopes_screen` (`ts_code`),
    INDEX `idx_tst_run_scopes_case` (`test_case_id`),
    INDEX `idx_tst_run_scopes_bug` (`bug_id`),
    CONSTRAINT `fk_tst_run_scopes_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_run_scopes_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_scopes_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_scopes_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_scopes_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_scopes_req` FOREIGN KEY (`requirement_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One selected test case within one run, with the reason it was selected. The selection reason is what
-- makes impact analysis explainable after the fact (BR-EXEC-03).
--
-- test_case_id and source_test_case_id: a run item normally names a canonical test case. It may instead
-- name an unmapped source test case, which is how evidence imported from a machine that authored its own
-- test cases is retained without being forced into the canonical catalog (BR-TC-IND-01).
CREATE TABLE IF NOT EXISTS `tst_test_run_items` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`                BIGINT UNSIGNED NOT NULL,
    `test_case_id`          INT UNSIGNED NULL,
    `source_test_case_id`   BIGINT UNSIGNED NULL,

    `selection_reason`      ENUM('Manual','Suite','Direct_Change','Dependency','Bug_Retest','Critical','Regression',
                                 'Full_Regression','Historical_Correlation','Open_Bug','Schedule','Other') NOT NULL DEFAULT 'Manual',
    `selection_source`      VARCHAR(255) NULL,      -- the commit, rule or analysis that put it here
    `selection_confidence`  DECIMAL(4,3) NULL,
    `sequence_no`           INT UNSIGNED NOT NULL DEFAULT 1,

    -- Snapshots taken at selection time, so a historical result renders as the test case stood then.
    `test_case_version_no`  INT UNSIGNED NULL,
    `display_name_snapshot` VARCHAR(255) NOT NULL,
    `file_path_snapshot`    VARCHAR(500) NULL,
    `criticality_snapshot`  ENUM('Low','Medium','High','Critical') NULL,

    -- Set when the item never ran because a blocking dependency failed (BR-DEP-02).
    `blocked_by_item_id`    BIGINT UNSIGNED NULL,
    `blocked_reason`        VARCHAR(500) NULL,

    `attempt_count`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `final_status`          ENUM('Passed','Failed','Error','Skipped','Blocked','Not_Executed') NULL,

    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_run_items_run_case` (`run_id`,`test_case_id`),
    INDEX `idx_tst_run_items_case_date` (`test_case_id`,`created_at`),
    INDEX `idx_tst_run_items_source_case` (`source_test_case_id`),
    INDEX `idx_tst_run_items_reason` (`selection_reason`),
    INDEX `idx_tst_run_items_final` (`final_status`),
    INDEX `idx_tst_run_items_blocked_by` (`blocked_by_item_id`),
    -- Exactly one of the two test-case references must be present.
    CONSTRAINT `chk_tst_run_items_case_ref` CHECK (
        (`test_case_id` IS NOT NULL AND `source_test_case_id` IS NULL)
     OR (`test_case_id` IS NULL AND `source_test_case_id` IS NOT NULL)
    ),
    CONSTRAINT `fk_tst_run_items_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_run_items_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_run_items_source_case` FOREIGN KEY (`source_test_case_id`) REFERENCES `tst_source_test_cases`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_run_items_blocked_by` FOREIGN KEY (`blocked_by_item_id`) REFERENCES `tst_test_run_items`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_run_items_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_run_items_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_run_items_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ONE ROW PER ATTEMPT. Insert-only. Nothing in the application may ever update a status here.
-- This table is the single source of truth from which every statistic in the system is derived.
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`                BIGINT UNSIGNED NOT NULL,
    `run_item_id`           BIGINT UNSIGNED NOT NULL,
    -- Denormalised for query performance: every history query starts from a test case, and this
    -- avoids a join to run_items on tens of millions of rows. Maintained by the execution service only.
    `test_case_id`          INT UNSIGNED NULL,
    `machine_id`            SMALLINT UNSIGNED NOT NULL,
    `environment_profile_id` INT UNSIGNED NULL,

    `attempt_no`            SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_final_attempt`      TINYINT(1) NOT NULL DEFAULT 1,

    -- Blocked and Not_Executed were absent in v6.7, so a blocked test had to be recorded as a failure
    -- and defect counts were inflated (BRD §9.11, BR-RESULT-06).
    `status`                ENUM('Passed','Failed','Error','Skipped','Blocked','Not_Executed') NOT NULL,
    `executed_by`           VARCHAR(10) NULL,
    `started_at`            DATETIME NULL,
    `finished_at`           DATETIME NULL,
    `duration_seconds`      DECIMAL(12,3) NULL,
    `assertions`            INT UNSIGNED NOT NULL DEFAULT 0,

    `display_name_snapshot` VARCHAR(255) NOT NULL,
    `error_message`         TEXT NULL,
    `error_trace`           MEDIUMTEXT NULL,
    `exception_class`       VARCHAR(255) NULL,

    -- Normalised fingerprint of the failure, used to group recurring identical failures across runs,
    -- machines and people. This is the join that makes triage a group decision, not forty decisions.
    `failure_fingerprint`   CHAR(64) NULL,
    `failure_signature_id`  BIGINT UNSIGNED NULL,   -- FK added in the deferred block

    -- Triage outcome for a non-passing result (BRD R-06: a failure is not automatically a bug).
    `triage_state`          ENUM('Untriaged','New_Bug','Existing_Bug','Known_Issue','Flaky','Environment','Test_Defect','Data_Issue','Expected')
                            NOT NULL DEFAULT 'Untriaged',
    `triaged_by`            VARCHAR(10) NULL,
    `triaged_at`            DATETIME NULL,
    `triage_note`           VARCHAR(1000) NULL,

    `result_json`           JSON NULL,              -- raw adapter payload
    `consistency_note`      VARCHAR(1000) NULL,     -- explains a result inconsistent with its steps

    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_results_attempt` (`run_item_id`,`attempt_no`),
    INDEX `idx_tst_results_run_status` (`run_id`,`status`),
    -- The primary history index: "every attempt of this test case, newest first".
    INDEX `idx_tst_results_case_date` (`test_case_id`,`created_at`),
    INDEX `idx_tst_results_case_final` (`test_case_id`,`is_final_attempt`,`status`,`created_at`),
    INDEX `idx_tst_results_fingerprint` (`failure_fingerprint`),
    INDEX `idx_tst_results_signature` (`failure_signature_id`),
    INDEX `idx_tst_results_triage` (`triage_state`,`created_at`),
    INDEX `idx_tst_results_machine_date` (`machine_id`,`created_at`),
    INDEX `idx_tst_results_env` (`environment_profile_id`,`status`),
    CONSTRAINT `chk_tst_results_attempt_no` CHECK (`attempt_no` >= 1),
    CONSTRAINT `fk_tst_results_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_results_item` FOREIGN KEY (`run_item_id`) REFERENCES `tst_test_run_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_results_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_results_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_results_env` FOREIGN KEY (`environment_profile_id`) REFERENCES `tst_environment_profiles`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_results_executed_by` FOREIGN KEY (`executed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_results_triaged_by` FOREIGN KEY (`triaged_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_results_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_results_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_results_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Per-step outcome for a manual or hybrid execution. step_no is stored rather than a FK to the step row,
-- because the step definition may be edited later while this record must not change (BR-STEP-05).
CREATE TABLE IF NOT EXISTS `tst_test_run_result_steps` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_result_id`         BIGINT UNSIGNED NOT NULL,
    `step_no`               SMALLINT UNSIGNED NOT NULL,
    `action_snapshot`       TEXT NOT NULL,
    `expected_snapshot`     TEXT NOT NULL,
    `status`                ENUM('Passed','Failed','Blocked','Skipped','Not_Executed') NOT NULL,
    `actual_result`         TEXT NULL,
    `note`                  VARCHAR(1000) NULL,
    `duration_seconds`      DECIMAL(10,2) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_result_steps` (`run_result_id`,`step_no`),
    INDEX `idx_tst_result_steps_status` (`status`),
    CONSTRAINT `fk_tst_result_steps_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Evidence. v6.7 had three fixed path columns, which left video, HAR files and per-step screenshots
-- nowhere to go and no way to express that an artefact had been purged (BR-EVID-03).
CREATE TABLE IF NOT EXISTS `tst_run_result_artifacts` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_result_id`     BIGINT UNSIGNED NOT NULL,
    `step_no`           SMALLINT UNSIGNED NULL,     -- when the artefact belongs to one manual step
    `artifact_type`     ENUM('Screenshot','Console_Log','Page_Source','Video','Network_Log','Raw_Output','Trace','Attachment','Other') NOT NULL,
    `file_path`         VARCHAR(1000) NOT NULL,
    `file_sha256`       CHAR(64) NULL,              -- identical artefacts are stored once, referenced many times
    `bytes`             BIGINT UNSIGNED NULL,
    `mime_type`         VARCHAR(100) NULL,
    `caption`           VARCHAR(500) NULL,
    -- is_available = 0 means the file was purged by retention. The result then shows "evidence expired"
    -- rather than appearing never to have had any.
    `is_available`      TINYINT(1) NOT NULL DEFAULT 1,
    `expires_at`        DATETIME NULL,
    `purged_at`         DATETIME NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_artifacts_result` (`run_result_id`,`artifact_type`),
    INDEX `idx_tst_artifacts_hash` (`file_sha256`),
    INDEX `idx_tst_artifacts_expiry` (`is_available`,`expires_at`),
    CONSTRAINT `fk_tst_artifacts_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One row per distinct normalised failure. This is what turns "forty failures" into "one problem".
CREATE TABLE IF NOT EXISTS `tst_failure_signatures` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fingerprint`           CHAR(64) NOT NULL,
    `exception_class`       VARCHAR(255) NULL,
    `normalised_message`    VARCHAR(1000) NULL,
    `top_frames`            VARCHAR(1000) NULL,     -- the top application frames, vendor frames removed
    `sample_result_id`      BIGINT UNSIGNED NULL,   -- FK added in the deferred block
    `first_seen_at`         DATETIME NULL,
    `last_seen_at`          DATETIME NULL,
    `occurrence_count`      BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `distinct_test_cases`   INT UNSIGNED NOT NULL DEFAULT 0,
    `distinct_machines`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `bug_id`                BIGINT UNSIGNED NULL,       -- FK added in the deferred block
    `known_issue_id`        BIGINT UNSIGNED NULL,       -- FK added in the deferred block
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_failure_signatures` (`fingerprint`),
    INDEX `idx_tst_failure_sig_bug` (`bug_id`),
    INDEX `idx_tst_failure_sig_known` (`known_issue_id`),
    INDEX `idx_tst_failure_sig_last_seen` (`last_seen_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- DERIVED. A convenience for dashboards, never a source of truth. Every column here must be
-- reproducible from tst_test_run_results alone; `php artisan tst:rebuild-analytics` does exactly that,
-- and a nightly job compares the incremental values against a rebuild (R-13, BR-HISTORY-05).
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_case_id`          INT UNSIGNED NOT NULL,

    `first_run_at`          DATETIME NULL,
    `last_run_id`           BIGINT UNSIGNED NULL,
    `last_run_result_id`    BIGINT UNSIGNED NULL,
    `last_status`           ENUM('Passed','Failed','Error','Skipped','Blocked','Not_Executed') NULL,
    `last_run_at`           DATETIME NULL,
    `last_passed_at`        DATETIME NULL,
    `last_failed_at`        DATETIME NULL,

    `consecutive_failures`  INT UNSIGNED NOT NULL DEFAULT 0,
    `consecutive_passes`    INT UNSIGNED NOT NULL DEFAULT 0,
    `total_runs`            BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_passed`          BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_failed`          BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_error`           BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_skipped`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `total_blocked`         BIGINT UNSIGNED NOT NULL DEFAULT 0,

    `pass_rate_30d`         DECIMAL(5,2) NULL,
    `pass_rate_all`         DECIMAL(5,2) NULL,
    `avg_duration_seconds`  DECIMAL(12,3) NULL,
    `max_duration_seconds`  DECIMAL(12,3) NULL,
    `distinct_machines`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `distinct_environments` SMALLINT UNSIGNED NOT NULL DEFAULT 0,

    -- Flakiness. flaky_evidence_json holds the outcome series, the environment and the change check,
    -- so the conclusion can be re-read and re-argued a year later (BR-FLAKY-04).
    `flaky_score`           DECIMAL(4,3) NULL,
    `is_flaky_candidate`    TINYINT(1) NOT NULL DEFAULT 0,
    `is_flaky_confirmed`    TINYINT(1) NOT NULL DEFAULT 0,
    `flaky_reason`          VARCHAR(500) NULL,
    `flaky_evidence_json`   JSON NULL,
    `flaky_confirmed_by`    VARCHAR(10) NULL,
    `flaky_confirmed_at`    DATETIME NULL,

    -- Derived indicators (Solution_Design_v2 §8.4, §8.5).
    `confidence_score`      DECIMAL(5,2) NULL,
    `confidence_json`       JSON NULL,
    `health_status`         ENUM('Healthy','Unstable','Frequently_Failing','Obsolete','Blocked','Insufficient_History','Under_Investigation','Orphaned')
                            NOT NULL DEFAULT 'Insufficient_History',

    `open_bug_count`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,

    -- Rebuild provenance, so a summary can always be shown to be current with the evidence.
    `last_rebuilt_at`       DATETIME NULL,
    `rebuild_source`        ENUM('Incremental','Full_Rebuild') NOT NULL DEFAULT 'Incremental',
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_case_summary_case` (`test_case_id`),
    INDEX `idx_tst_case_summary_status` (`last_status`),
    INDEX `idx_tst_case_summary_flaky` (`is_flaky_confirmed`,`is_flaky_candidate`),
    INDEX `idx_tst_case_summary_health` (`health_status`),
    INDEX `idx_tst_case_summary_last_run` (`last_run_at`),
    INDEX `idx_tst_case_summary_confidence` (`confidence_score`),
    CONSTRAINT `fk_tst_case_summary_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_case_summary_last_run` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_case_summary_last_result` FOREIGN KEY (`last_run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_case_summary_flaky_by` FOREIGN KEY (`flaky_confirmed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 11: NOTES, DISCOVERY AND SCHEDULES
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_run_annotations` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`            BIGINT UNSIGNED NOT NULL,
    `run_result_id`     BIGINT UNSIGNED NULL,
    `user_code`         VARCHAR(10) NOT NULL,
    `comment`           VARCHAR(500) NOT NULL,
    `note`              TEXT NULL,
    `is_known_issue`    TINYINT(1) NOT NULL DEFAULT 0,
    `known_issue_id`    BIGINT UNSIGNED NULL,       -- FK added in the deferred block
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_annotations_run` (`run_id`),
    INDEX `idx_tst_annotations_result` (`run_result_id`),
    INDEX `idx_tst_annotations_known` (`is_known_issue`),
    CONSTRAINT `fk_tst_annotations_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_annotations_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_annotations_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_annotations_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_annotations_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_annotations_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_discovery_sync_logs` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`            SMALLINT UNSIGNED NOT NULL,
    `source_sync_id`        BIGINT UNSIGNED NOT NULL,
    `user_code`             VARCHAR(10) NOT NULL,
    `sync_mode`             ENUM('Discover','Import','Catalog_Bundle') NOT NULL DEFAULT 'Discover',
    `import_format`         ENUM('CSV','Excel','JSON','NDJSON','Other') NULL,
    `repository_code`       VARCHAR(100) NULL,
    `commit_hash`           VARCHAR(40) NULL,       -- the code version that was scanned
    `folder_path`           VARCHAR(1000) NULL,
    `file_name`             VARCHAR(500) NULL,
    `file_path`             VARCHAR(1000) NULL,
    `started_at`            DATETIME NOT NULL,
    `finished_at`           DATETIME NULL,
    `duration_seconds`      DECIMAL(10,2) NULL,
    `status`                ENUM('Running','Success','Partial','Failed') NOT NULL DEFAULT 'Running',
    `modules_found`         INT UNSIGNED NOT NULL DEFAULT 0,
    `screens_found`         INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_found`      INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_added`      INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_updated`    INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_orphaned`   INT UNSIGNED NOT NULL DEFAULT 0,
    `test_cases_unchanged`  INT UNSIGNED NOT NULL DEFAULT 0,
    `items_pending_review`  INT UNSIGNED NOT NULL DEFAULT 0,
    `details_json`          JSON NULL,
    `error_message`         TEXT NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_discovery_source` (`machine_id`,`source_sync_id`),
    INDEX `idx_tst_discovery_status` (`status`,`started_at`),
    CONSTRAINT `fk_tst_discovery_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_discovery_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_schedules` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(150) NOT NULL,
    `description`       VARCHAR(500) NULL,
    `machine_id`        SMALLINT UNSIGNED NULL,     -- the machine expected to run it
    `owner_user_code`   VARCHAR(10) NOT NULL,       -- who is answerable when it fails or is missed
    `suite_id`          INT UNSIGNED NULL,
    `scope_json`        JSON NULL,
    `cron_expression`   VARCHAR(100) NOT NULL,
    `timezone`          VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
    `catch_up_policy`   ENUM('Skip','Run_Once','Run_All') NOT NULL DEFAULT 'Skip',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `is_suspended`      TINYINT(1) NOT NULL DEFAULT 0,
    `suspended_reason`  VARCHAR(500) NULL,
    `next_run_at`       DATETIME NULL,
    `last_run_id`       BIGINT UNSIGNED NULL,
    `last_run_at`       DATETIME NULL,
    `last_status`       ENUM('Success','Failed','Missed','Cancelled') NULL,
    -- A schedule that did not fire is recorded as missed, not silently skipped (BR-SCHED-05).
    `missed_count`      INT UNSIGNED NOT NULL DEFAULT 0,
    `created_by`        VARCHAR(10) NOT NULL,
    `updated_by`        VARCHAR(10) NOT NULL,
    `deleted_by`        VARCHAR(10) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_schedules_name` (`name`),
    INDEX `idx_tst_schedules_active` (`is_active`,`is_suspended`,`next_run_at`),
    CONSTRAINT `fk_tst_schedules_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_schedules_owner` FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_schedules_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_schedules_last_run` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_schedules_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_schedules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_schedules_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 12: DEFECTS
--     Three distinct concepts that v1 and v6.7 partly conflated:
--       Known Issue  an accepted, documented problem whose recurrence is expected
--       Bug          one problem in Prime-AI
--       Occurrence   one observation of that problem in one result   (one bug -> many occurrences)
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_known_issues` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `issue_code`            VARCHAR(40) NOT NULL,
    `title`                 VARCHAR(255) NOT NULL,
    `description`           TEXT NULL,
    `rationale`             TEXT NULL,              -- why it is accepted rather than fixed
    `category`              ENUM('Product_Limitation','Environment','Third_Party','Test_Data','Deferred_Defect','Infrastructure','Other')
                            NOT NULL DEFAULT 'Deferred_Defect',
    `module_code`           VARCHAR(10) NULL,
    `ts_code`               VARCHAR(20) NULL,
    `failure_fingerprint`   CHAR(64) NULL,          -- auto-attribute matching failures
    `owner_user_code`       VARCHAR(10) NOT NULL,
    `status`                ENUM('Active','Expired','Promoted_To_Bug','Resolved','Withdrawn') NOT NULL DEFAULT 'Active',
    -- An expired known issue reverts to normal defect treatment and notifies its owner (BR-KNOWN-05).
    `review_due_at`         DATE NULL,
    `expired_at`            DATETIME NULL,
    `promoted_bug_id`       BIGINT UNSIGNED NULL,   -- FK added in the deferred block
    `occurrence_count`      BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `first_seen_at`         DATETIME NULL,
    `last_seen_at`          DATETIME NULL,
    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_known_issues_code` (`issue_code`),
    INDEX `idx_tst_known_issues_status` (`status`,`review_due_at`),
    INDEX `idx_tst_known_issues_fingerprint` (`failure_fingerprint`),
    INDEX `idx_tst_known_issues_area` (`module_code`,`ts_code`),
    CONSTRAINT `fk_tst_known_issues_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_known_issues_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_known_issues_owner` FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_known_issues_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_known_issues_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_known_issues_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Every recurrence of a known issue stays recorded and countable (BR-KNOWN-03).
CREATE TABLE IF NOT EXISTS `tst_known_issue_results` (
    `known_issue_id`    BIGINT UNSIGNED NOT NULL,
    `run_result_id`     BIGINT UNSIGNED NOT NULL,
    `attributed_by`     VARCHAR(10) NULL,           -- NULL when attributed automatically by fingerprint
    `note`              VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`known_issue_id`,`run_result_id`),
    INDEX `idx_tst_ki_results_result` (`run_result_id`),
    CONSTRAINT `fk_tst_ki_results_issue` FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_ki_results_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_ki_results_by` FOREIGN KEY (`attributed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_bugs` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Distributed identity: a bug may be raised independently on any machine.
    `origin_machine_id`         SMALLINT UNSIGNED NOT NULL,
    `source_bug_id`             BIGINT UNSIGNED NOT NULL,
    `bug_code`                  VARCHAR(30) NULL,       -- display code, e.g. 'BUG-000412'

    `discovered_by`             VARCHAR(10) NULL,
    `first_detected_run_id`     BIGINT UNSIGNED NULL,
    `first_detected_result_id`  BIGINT UNSIGNED NULL,

    -- Area. test_case_id is nullable: a bug may be raised manually with no originating test (BR-BUG-08).
    `module_code`               VARCHAR(10) NOT NULL,
    `ts_code`                   VARCHAR(20) NULL,
    `test_case_id`              INT UNSIGNED NULL,
    `requirement_id`            BIGINT UNSIGNED NULL,
    `failure_signature_id`      BIGINT UNSIGNED NULL,   -- FK added in the deferred block

    `title`                     VARCHAR(255) NOT NULL,
    `description`               TEXT NULL,
    `steps_to_reproduce`        TEXT NULL,
    `expected_behaviour`        TEXT NULL,
    `actual_behaviour`          TEXT NULL,

    -- Severity is impact; priority is urgency. They are different questions (BR-BUG-06).
    `severity`                  ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `priority`                  ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `status`                    ENUM('Open','Assigned','In_Progress','Fixed','Retesting','Reopened','Closed','Escalated','Wont_Fix','Duplicate')
                                NOT NULL DEFAULT 'Open',
    `resolution`                ENUM('Fixed','Not_A_Defect','Duplicate','Cannot_Reproduce','Wont_Fix','Known_Issue','Test_Defect','Environment') NULL,
    -- Recorded on closure, so that after a hundred bugs the pattern of WHY becomes visible.
    `root_cause_category`       ENUM('Logic','Validation','Data','Tenancy','Permission','Integration','UI','Performance','Configuration','Environment','Test_Defect','Other') NULL,
    `root_cause_note`           TEXT NULL,

    -- Where it was observed.
    `environment_profile_id`    INT UNSIGNED NULL,
    `observed_commit_hash`      VARCHAR(40) NULL,
    `release_id`                BIGINT UNSIGNED NULL,   -- FK added in the deferred block

    `assigned_to`               VARCHAR(10) NULL,
    `assigned_by`               VARCHAR(10) NULL,
    `assigned_at`               DATETIME NULL,
    `sla_due_at`                DATETIME NULL,
    `sla_breached`              TINYINT(1) NOT NULL DEFAULT 0,

    `fixed_by`                  VARCHAR(10) NULL,
    `fixed_at`                  DATETIME NULL,
    `fixed_commit_hash`         VARCHAR(40) NULL,
    `fix_notes`                 TEXT NULL,

    -- Fixed does not equal verified. Only a passing retest sets these (R-08, BR-BUG-05).
    `verified_by`               VARCHAR(10) NULL,
    `verified_at`               DATETIME NULL,
    `verified_result_id`        BIGINT UNSIGNED NULL,
    `verification_override`     TINYINT(1) NOT NULL DEFAULT 0,  -- closed without a passing retest
    `verification_override_reason` VARCHAR(1000) NULL,

    `reopen_count`              SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `occurrence_count`          INT UNSIGNED NOT NULL DEFAULT 0,
    `retest_attempt_count`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `escalated_at`              DATETIME NULL,
    `escalation_reason`         VARCHAR(500) NULL,

    `duplicate_of_bug_id`       BIGINT UNSIGNED NULL,
    `known_issue_id`            BIGINT UNSIGNED NULL,

    `closed_by`                 VARCHAR(10) NULL,
    `closed_at`                 DATETIME NULL,

    `created_by`                VARCHAR(10) NOT NULL,
    `updated_by`                VARCHAR(10) NOT NULL,
    `deleted_by`                VARCHAR(10) NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_bugs_source` (`origin_machine_id`,`source_bug_id`),
    UNIQUE KEY `uq_tst_bugs_code` (`bug_code`),
    INDEX `idx_tst_bugs_status_severity` (`status`,`severity`),
    INDEX `idx_tst_bugs_priority` (`priority`,`status`),
    INDEX `idx_tst_bugs_case` (`test_case_id`),
    INDEX `idx_tst_bugs_area` (`module_code`,`ts_code`),
    INDEX `idx_tst_bugs_assigned` (`assigned_to`,`status`),
    INDEX `idx_tst_bugs_first_run` (`first_detected_run_id`),
    INDEX `idx_tst_bugs_fixed_commit` (`fixed_commit_hash`),
    INDEX `idx_tst_bugs_signature` (`failure_signature_id`),
    INDEX `idx_tst_bugs_sla` (`sla_breached`,`sla_due_at`),
    INDEX `idx_tst_bugs_release` (`release_id`),
    INDEX `idx_tst_bugs_duplicate` (`duplicate_of_bug_id`),
    FULLTEXT KEY `ft_tst_bugs_text` (`title`,`description`),

    CONSTRAINT `fk_tst_bugs_origin_machine` FOREIGN KEY (`origin_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_bugs_discovered_by` FOREIGN KEY (`discovered_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_first_run` FOREIGN KEY (`first_detected_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_first_result` FOREIGN KEY (`first_detected_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_verified_result` FOREIGN KEY (`verified_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_module` FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_bugs_screen` FOREIGN KEY (`ts_code`) REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_case` FOREIGN KEY (`test_case_id`) REFERENCES `tst_test_cases`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_requirement` FOREIGN KEY (`requirement_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_env` FOREIGN KEY (`environment_profile_id`) REFERENCES `tst_environment_profiles`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_fixed_by` FOREIGN KEY (`fixed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_verified_by` FOREIGN KEY (`verified_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_duplicate_of` FOREIGN KEY (`duplicate_of_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_known_issue` FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bugs_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_bugs_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_bugs_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One bug observed in one result. One bug -> many occurrences (R-07).
-- A result may also expose more than one bug, which is why this is a many-to-many junction and not a
-- bug_id column on the result.
CREATE TABLE IF NOT EXISTS `tst_bug_occurrences` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id`            BIGINT UNSIGNED NOT NULL,
    `run_result_id`     BIGINT UNSIGNED NOT NULL,
    `occurrence_type`   ENUM('First_Detected','Reproduced','Regression','Retest_Failed','Retest_Passed','Other') NOT NULL DEFAULT 'Reproduced',
    `matched_by`        ENUM('Manual','Fingerprint','AI_Proposal') NOT NULL DEFAULT 'Manual',
    `confirmed_by`      VARCHAR(10) NULL,
    `note`              VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_bug_occ` (`bug_id`,`run_result_id`),
    INDEX `idx_tst_bug_occ_result` (`run_result_id`),
    INDEX `idx_tst_bug_occ_type` (`occurrence_type`,`created_at`),
    CONSTRAINT `fk_tst_bug_occ_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_occ_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_occ_confirmed_by` FOREIGN KEY (`confirmed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_bug_status_history` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id`            BIGINT UNSIGNED NOT NULL,
    `from_status`       VARCHAR(30) NULL,
    `to_status`         VARCHAR(30) NOT NULL,
    `from_assignee`     VARCHAR(10) NULL,
    `to_assignee`       VARCHAR(10) NULL,
    `changed_by`        VARCHAR(10) NULL,           -- NULL never occurs in practice: the system user is used
    `is_system_action`  TINYINT(1) NOT NULL DEFAULT 0,
    `note`              TEXT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_bug_hist_bug_date` (`bug_id`,`created_at`),
    INDEX `idx_tst_bug_hist_to_status` (`to_status`,`created_at`),
    CONSTRAINT `fk_tst_bug_hist_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_hist_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bug_hist_from_assignee` FOREIGN KEY (`from_assignee`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bug_hist_to_assignee` FOREIGN KEY (`to_assignee`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_bug_comments` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id`        BIGINT UNSIGNED NOT NULL,
    `user_code`     VARCHAR(10) NOT NULL,
    `comment`       TEXT NOT NULL,
    `is_internal`   TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_bug_comments_bug` (`bug_id`,`created_at`),
    CONSTRAINT `fk_tst_bug_comments_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_comments_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Relationships between bugs. Insert-only; a reversal writes a new row and supersedes the old one.
CREATE TABLE IF NOT EXISTS `tst_bug_links` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id`            BIGINT UNSIGNED NOT NULL,
    `linked_bug_id`     BIGINT UNSIGNED NOT NULL,
    `link_type`         ENUM('Proposed_Duplicate','Duplicate_Of','Related','Blocks','Blocked_By','Caused_By','Causes','Regression_Of') NOT NULL,
    `score`             DECIMAL(4,3) NULL,
    `evidence_json`     JSON NULL,
    `proposed_by`       VARCHAR(10) NULL,
    `decided_by`        VARCHAR(10) NULL,
    `decided_at`        DATETIME NULL,
    `note`              VARCHAR(500) NULL,
    `superseded_at`     DATETIME NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_bug_links_bug` (`bug_id`,`link_type`),
    INDEX `idx_tst_bug_links_linked` (`linked_bug_id`),
    INDEX `idx_tst_bug_links_open` (`link_type`,`superseded_at`),
    CONSTRAINT `chk_tst_bug_links_not_self` CHECK (`bug_id` <> `linked_bug_id`),
    CONSTRAINT `fk_tst_bug_links_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_links_linked` FOREIGN KEY (`linked_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_bug_links_proposed_by` FOREIGN KEY (`proposed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_bug_links_decided_by` FOREIGN KEY (`decided_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One managed attempt to verify one or more fixed bugs, including its regression scope.
CREATE TABLE IF NOT EXISTS `tst_retest_cycles` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bug_id`            BIGINT UNSIGNED NOT NULL,       -- the bug that triggered the cycle
    `cycle_number`      SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `trigger_source`    ENUM('Auto_On_Fixed','Manual','Scheduled','Release_Gate') NOT NULL DEFAULT 'Auto_On_Fixed',
    `triggered_by`      VARCHAR(10) NULL,
    `triggered_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `run_id`            BIGINT UNSIGNED NULL,
    `scope_policy`      ENUM('Test_Only','Screen','Screen_Plus_Dependencies','Module','Regression_Suite') NOT NULL DEFAULT 'Screen_Plus_Dependencies',
    `scope_json`        JSON NULL,
    `status`            ENUM('Pending','Running','Passed','Failed','Not_Covered','Cancelled') NOT NULL DEFAULT 'Pending',
    `completed_at`      DATETIME NULL,
    `note`              VARCHAR(1000) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_retest_cycles` (`bug_id`,`cycle_number`),
    INDEX `idx_tst_retest_cycles_status` (`status`),
    INDEX `idx_tst_retest_cycles_run` (`run_id`),
    CONSTRAINT `fk_tst_retest_cycles_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_retest_cycles_triggered_by` FOREIGN KEY (`triggered_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_retest_cycles_run` FOREIGN KEY (`run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One retest run may verify several bugs, each with its own outcome (BR-RETEST-07).
-- Not_Covered means the retest could not exercise this bug at all, which is not a failure (BR-RETEST-08).
CREATE TABLE IF NOT EXISTS `tst_retest_cycle_bugs` (
    `retest_cycle_id`   BIGINT UNSIGNED NOT NULL,
    `bug_id`            BIGINT UNSIGNED NOT NULL,
    `outcome`           ENUM('Pending','Passed','Failed','Not_Covered','Blocked') NOT NULL DEFAULT 'Pending',
    `verifying_result_id` BIGINT UNSIGNED NULL,
    `note`              VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`retest_cycle_id`,`bug_id`),
    INDEX `idx_tst_retest_bugs_bug` (`bug_id`,`outcome`),
    CONSTRAINT `fk_tst_retest_bugs_cycle` FOREIGN KEY (`retest_cycle_id`) REFERENCES `tst_retest_cycles`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_retest_bugs_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_retest_bugs_result` FOREIGN KEY (`verifying_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 13: RELEASES
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_releases` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `release_code`          VARCHAR(40) NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    `description`           TEXT NULL,
    `repository_code`       VARCHAR(100) NULL,
    `from_commit_hash`      VARCHAR(40) NULL,
    `to_commit_hash`        VARCHAR(40) NULL,
    `planned_date`          DATE NULL,
    `released_at`           DATETIME NULL,
    `status`                ENUM('Planned','In_Testing','Ready','Released','Cancelled','Rolled_Back') NOT NULL DEFAULT 'Planned',

    -- The assessment is retained AS ISSUED and is not retrospectively altered by later data (BR-REL-06).
    `readiness_score`       DECIMAL(5,2) NULL,
    `readiness_assessment`  TEXT NULL,
    `readiness_reservations` TEXT NULL,
    `assessed_at`           DATETIME NULL,
    `assessed_by`           VARCHAR(10) NULL,
    `signed_off_by`         VARCHAR(10) NULL,
    `signed_off_at`         DATETIME NULL,
    `sign_off_note`         TEXT NULL,

    `changed_screen_count`  INT UNSIGNED NOT NULL DEFAULT 0,
    `tested_screen_count`   INT UNSIGNED NOT NULL DEFAULT 0,
    `open_critical_bugs`    INT UNSIGNED NOT NULL DEFAULT 0,
    `open_bugs`             INT UNSIGNED NOT NULL DEFAULT 0,
    `known_issues_in_scope` INT UNSIGNED NOT NULL DEFAULT 0,

    `created_by`            VARCHAR(10) NOT NULL,
    `updated_by`            VARCHAR(10) NOT NULL,
    `deleted_by`            VARCHAR(10) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_releases_code` (`release_code`),
    INDEX `idx_tst_releases_status` (`status`,`planned_date`),
    CONSTRAINT `fk_tst_releases_assessed_by` FOREIGN KEY (`assessed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_releases_signed_off_by` FOREIGN KEY (`signed_off_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
    CONSTRAINT `fk_tst_releases_created_by` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_releases_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_releases_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 14: EXPORT, IMPORT, CONFLICTS AND RECORD MAPPING
--     Three independent guards make consolidation safe, so that a single mistake cannot duplicate evidence:
--       1. UNIQUE(source_machine_id, source_export_id) on tst_data_imports   -- a bundle applies once
--       2. UNIQUE(machine_id, source_*_id) on every transaction table        -- a record inserts once
--       3. tst_import_record_map                                             -- reversible, auditable
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_data_exports` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`            SMALLINT UNSIGNED NOT NULL,
    `source_export_id`      BIGINT UNSIGNED NOT NULL,
    `user_code`             VARCHAR(10) NOT NULL,
    `export_name`           VARCHAR(200) NOT NULL,
    `export_type`           ENUM('Full','Incremental','Selected','Catalog_Bundle') NOT NULL DEFAULT 'Incremental',
    `direction`             ENUM('Evidence_Out','Catalog_Out') NOT NULL DEFAULT 'Evidence_Out',
    `date_from`             DATETIME NULL,
    `date_to`               DATETIME NULL,
    `modules_json`          JSON NULL,

    -- An export declares the versions that produced it, so the importer can decide whether it is
    -- supported, needs migration, or must be refused (BR-SYNC-07, BR-SYNC-08).
    `app_version`           VARCHAR(20) NOT NULL,
    `schema_version`        VARCHAR(20) NOT NULL,
    `catalog_version`       VARCHAR(20) NULL,

    `file_path`             VARCHAR(1000) NULL,
    `file_sha256`           CHAR(64) NULL,
    `file_bytes`            BIGINT UNSIGNED NULL,
    `manifest_json`         JSON NULL,              -- counts, per-file checksums, period, source identity
    `record_counts_json`    JSON NULL,
    `artifact_count`        INT UNSIGNED NOT NULL DEFAULT 0,
    `includes_artifacts`    TINYINT(1) NOT NULL DEFAULT 1,

    `status`                ENUM('Pending','In_Progress','Completed','Failed') NOT NULL DEFAULT 'Pending',
    `error_message`         TEXT NULL,
    `exported_at`           DATETIME NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_exports_source` (`machine_id`,`source_export_id`),
    INDEX `idx_tst_exports_status` (`status`,`exported_at`),
    CONSTRAINT `fk_tst_exports_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_exports_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_data_imports` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `source_machine_id`     SMALLINT UNSIGNED NOT NULL,
    `source_export_id`      BIGINT UNSIGNED NOT NULL,
    `imported_by`           VARCHAR(10) NOT NULL,
    `file_name`             VARCHAR(500) NULL,
    `file_sha256`           CHAR(64) NULL,

    `source_app_version`    VARCHAR(20) NULL,
    `source_schema_version` VARCHAR(20) NULL,
    -- The versioning decision, recorded rather than implied (D-21).
    `version_decision`      ENUM('Same_Version','Migrated_On_Read','Rejected_Incompatible') NULL,
    `version_decision_note` VARCHAR(500) NULL,

    `status`                ENUM('Received','Validating','Applying','Completed','Partial','Rejected','Reversed') NOT NULL DEFAULT 'Received',
    `started_at`            DATETIME NULL,
    `finished_at`           DATETIME NULL,
    `records_created`       INT UNSIGNED NOT NULL DEFAULT 0,
    `records_matched`       INT UNSIGNED NOT NULL DEFAULT 0,    -- already present; skipped (idempotency)
    `records_rejected`      INT UNSIGNED NOT NULL DEFAULT 0,
    `conflict_count`        INT UNSIGNED NOT NULL DEFAULT 0,
    `open_conflict_count`   INT UNSIGNED NOT NULL DEFAULT 0,
    `record_counts_json`    JSON NULL,
    `manifest_json`         JSON NULL,
    `error_message`         TEXT NULL,
    `reversed_by`           VARCHAR(10) NULL,
    `reversed_at`           DATETIME NULL,
    `reversal_reason`       VARCHAR(500) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- Guard #1: the same bundle can never be applied twice.
    UNIQUE KEY `uq_tst_imports_source_export` (`source_machine_id`,`source_export_id`),
    INDEX `idx_tst_imports_status` (`status`,`started_at`),
    INDEX `idx_tst_imports_open_conflicts` (`open_conflict_count`),
    CONSTRAINT `fk_tst_imports_machine` FOREIGN KEY (`source_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_imports_user` FOREIGN KEY (`imported_by`) REFERENCES `tst_users`(`code`),
    CONSTRAINT `fk_tst_imports_reversed_by` FOREIGN KEY (`reversed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Guard #3: source identity -> local surrogate id, per entity. Makes an import reversible and makes
-- "where did this record come from?" answerable for every consolidated row (BR-SYNC-11, R-02).
CREATE TABLE IF NOT EXISTS `tst_import_record_map` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `import_id`         BIGINT UNSIGNED NOT NULL,
    `entity_type`       VARCHAR(64) NOT NULL,       -- e.g. 'tst_test_runs'
    `source_machine_id` SMALLINT UNSIGNED NOT NULL,
    `source_id`         BIGINT UNSIGNED NULL,       -- the local id it had on the source machine
    `source_code`       VARCHAR(120) NULL,          -- or its business code, for catalog entities
    `local_id`          BIGINT UNSIGNED NOT NULL,   -- the id it was given here
    `action`            ENUM('Created','Matched','Updated','Skipped') NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_import_map` (`entity_type`,`source_machine_id`,`source_id`,`source_code`),
    INDEX `idx_tst_import_map_import` (`import_id`),
    INDEX `idx_tst_import_map_local` (`entity_type`,`local_id`),
    CONSTRAINT `fk_tst_import_map_import` FOREIGN KEY (`import_id`) REFERENCES `tst_data_imports`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_import_map_machine` FOREIGN KEY (`source_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Conflicts are QUEUED for a decision. They are never resolved by guessing (R-06, BR-SYNC-05).
CREATE TABLE IF NOT EXISTS `tst_import_conflicts` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `import_id`         BIGINT UNSIGNED NOT NULL,
    `conflict_type`     ENUM('Missing_Catalog_Reference','Definition_Divergence','Machine_Metadata_Mismatch',
                             'Duplicate_Business_Code','Version_Incompatible','Referential_Gap','Other') NOT NULL,
    `entity_type`       VARCHAR(64) NOT NULL,
    `source_identity`   VARCHAR(255) NULL,          -- how the record identified itself in the bundle
    `local_record_id`   BIGINT UNSIGNED NULL,       -- the existing record it clashed with, if any
    `severity`          ENUM('Blocking','Warning') NOT NULL DEFAULT 'Blocking',
    `description`       VARCHAR(1000) NOT NULL,
    `incoming_json`     JSON NULL,                  -- retained in full; nothing is discarded
    `existing_json`     JSON NULL,
    `status`            ENUM('Open','Resolved_Keep_Existing','Resolved_Accept_Incoming','Resolved_Manual','Ignored') NOT NULL DEFAULT 'Open',
    `resolved_by`       VARCHAR(10) NULL,
    `resolved_at`       DATETIME NULL,
    `resolution_note`   VARCHAR(1000) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_conflicts_import` (`import_id`,`status`),
    INDEX `idx_tst_conflicts_type` (`conflict_type`,`status`),
    INDEX `idx_tst_conflicts_open` (`status`,`created_at`),
    CONSTRAINT `fk_tst_conflicts_import` FOREIGN KEY (`import_id`) REFERENCES `tst_data_imports`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_conflicts_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 15: AI ANALYSES AND RECOMMENDATIONS
--     AI proposes. It never writes catalog data, never changes a result, never changes a bug status and
--     never merges anything (BR-AI-06, R-12). Every recommendation carries its evidence, its confidence
--     and a review state, and its accuracy is measured against what people subsequently decided.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_ai_analyses` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`        SMALLINT UNSIGNED NOT NULL,
    `source_analysis_id` BIGINT UNSIGNED NOT NULL,
    `analysis_type`     ENUM('Duplicate_Test_Case','Duplicate_Bug','Failure_Cluster','Flaky_Assessment','Regression_Assessment',
                             'Root_Cause_Hypothesis','Impacted_Tests','Coverage_Gap','Test_Draft','Summarisation','Other') NOT NULL,
    `scope_description` VARCHAR(500) NULL,
    `scope_json`        JSON NULL,
    `provider`          VARCHAR(50) NULL,
    `model`             VARCHAR(100) NULL,
    `prompt_version`    VARCHAR(30) NULL,
    `input_tokens`      INT UNSIGNED NULL,
    `output_tokens`     INT UNSIGNED NULL,
    `duration_ms`       INT UNSIGNED NULL,
    `status`            ENUM('Queued','Running','Completed','Failed') NOT NULL DEFAULT 'Queued',
    `error_message`     TEXT NULL,
    `requested_by`      VARCHAR(10) NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_ai_analyses_source` (`machine_id`,`source_analysis_id`),
    INDEX `idx_tst_ai_analyses_type` (`analysis_type`,`created_at`),
    CONSTRAINT `fk_tst_ai_analyses_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_ai_analyses_by` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `tst_ai_recommendations` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `analysis_id`       BIGINT UNSIGNED NOT NULL,
    `recommendation_type` ENUM('Link_Test_Cases','Link_Bugs','Attribute_To_Bug','Attribute_To_Known_Issue','Mark_Flaky',
                               'Mark_Regression','Select_Test','Create_Test','Root_Cause','Coverage_Gap','Other') NOT NULL,
    `target_entity_type` VARCHAR(64) NULL,
    `target_entity_id`  BIGINT UNSIGNED NULL,
    `related_entity_id` BIGINT UNSIGNED NULL,
    `title`             VARCHAR(255) NOT NULL,
    `recommendation`    TEXT NOT NULL,
    `confidence`        DECIMAL(4,3) NOT NULL DEFAULT 0.500,
    -- The reasoning inputs. This is what the explanation panel displays, and it is why the team can
    -- decide whether to trust the proposal (BR-AI-03, AC-AI-01).
    `evidence_json`     JSON NULL,
    `review_state`      ENUM('Proposed','Accepted','Rejected','Superseded','Expired') NOT NULL DEFAULT 'Proposed',
    `reviewed_by`       VARCHAR(10) NULL,
    `reviewed_at`       DATETIME NULL,
    `review_note`       VARCHAR(1000) NULL,
    -- Whether the recommendation turned out to be right, used to measure precision by type (K-12).
    `outcome`           ENUM('Correct','Incorrect','Partially_Correct','Unknown') NOT NULL DEFAULT 'Unknown',
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_tst_ai_recs_analysis` (`analysis_id`),
    INDEX `idx_tst_ai_recs_state` (`review_state`,`created_at`),
    INDEX `idx_tst_ai_recs_type` (`recommendation_type`,`review_state`),
    INDEX `idx_tst_ai_recs_target` (`target_entity_type`,`target_entity_id`),
    CONSTRAINT `chk_tst_ai_recs_confidence` CHECK (`confidence` BETWEEN 0 AND 1),
    CONSTRAINT `fk_tst_ai_recs_analysis` FOREIGN KEY (`analysis_id`) REFERENCES `tst_ai_analyses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tst_ai_recs_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 16: NOTIFICATIONS
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_notifications` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `recipient_code`    VARCHAR(10) NOT NULL,
    `event_type`        ENUM('Critical_Test_Failure','New_Critical_Bug','Bug_Assigned','Bug_Ready_For_Retest','Retest_Failed',
                             'Scheduled_Run_Failed','Scheduled_Run_Missed','Regression_Detected','Import_Conflict',
                             'Known_Issue_Expiring','SLA_Breach','Review_Required','Digest','Other') NOT NULL,
    `severity`          ENUM('Info','Warning','Critical') NOT NULL DEFAULT 'Info',
    `entity_type`       VARCHAR(64) NULL,
    `entity_id`         BIGINT UNSIGNED NULL,
    `title`             VARCHAR(255) NOT NULL,
    `body`              TEXT NULL,
    `action_url`        VARCHAR(500) NULL,
    -- Deduplication: a repeat of the same event for the same recipient inside the configured window
    -- increments occurrence_count instead of creating another row (BR-NOTIFY-02).
    `dedupe_key`        VARCHAR(191) NOT NULL,
    `occurrence_count`  INT UNSIGNED NOT NULL DEFAULT 1,
    `first_event_at`    DATETIME NOT NULL,
    `last_event_at`     DATETIME NOT NULL,
    `channel`           ENUM('In_App','Email','Digest') NOT NULL DEFAULT 'In_App',
    `delivered_at`      DATETIME NULL,
    `read_at`           DATETIME NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_notifications_dedupe` (`recipient_code`,`dedupe_key`),
    INDEX `idx_tst_notifications_unread` (`recipient_code`,`read_at`,`created_at`),
    INDEX `idx_tst_notifications_event` (`event_type`,`created_at`),
    CONSTRAINT `fk_tst_notifications_recipient` FOREIGN KEY (`recipient_code`) REFERENCES `tst_users`(`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 17: AUDIT
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `tst_audit_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `machine_id`        SMALLINT UNSIGNED NOT NULL,
    `source_audit_id`   BIGINT UNSIGNED NOT NULL,
    `user_code`         VARCHAR(10) NULL,
    `is_system_action`  TINYINT(1) NOT NULL DEFAULT 0,      -- BR-AUDIT-03
    `table_name`        VARCHAR(100) NOT NULL,
    `record_id`         BIGINT UNSIGNED NULL,
    `record_key`        VARCHAR(255) NULL,                  -- for code-keyed tables
    `operation`         ENUM('INSERT','UPDATE','DELETE','RESTORE','PURGE','LOGIN','PERMISSION_DENIED','EXPORT','IMPORT') NOT NULL,
    `old_values_json`   JSON NULL,
    `new_values_json`   JSON NULL,
    `context`           VARCHAR(255) NULL,                  -- the service or command responsible
    `ip_address`        VARCHAR(45) NULL,
    `user_agent`        VARCHAR(1000) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tst_audit_source` (`machine_id`,`source_audit_id`),
    INDEX `idx_tst_audit_table_record` (`table_name`,`record_id`),
    INDEX `idx_tst_audit_user_date` (`user_code`,`created_at`),
    INDEX `idx_tst_audit_operation_date` (`operation`,`created_at`),
    INDEX `idx_tst_audit_date` (`created_at`),
    CONSTRAINT `fk_tst_audit_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tst_audit_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 17b: DEFERRED CONSTRAINTS
--     Foreign keys whose target table is created later in this script, plus one index that could not be
--     declared inline. Adding them here keeps every CREATE TABLE statement above readable and
--     independently runnable.
--
--     MySQL has no ADD CONSTRAINT IF NOT EXISTS, so each statement is guarded by an information_schema
--     lookup and executed through PREPARE. That keeps the whole script re-runnable, which matters because
--     every CREATE TABLE above uses IF NOT EXISTS and every seed uses ON DUPLICATE KEY UPDATE.
--     No DELIMITER directive is used, so the script also runs through tools that do not support one.
-- =========================================================================================================

-- A run may belong to a schedule and to a release.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_test_runs_schedule already present'' AS skipped',
        'ALTER TABLE `tst_test_runs` ADD CONSTRAINT `fk_tst_test_runs_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `tst_schedules`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_test_runs_release` FOREIGN KEY (`release_id`) REFERENCES `tst_releases`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_test_runs' AND constraint_name = 'fk_tst_test_runs_schedule'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A run may be scoped to a bug.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_run_scopes_bug already present'' AS skipped',
        'ALTER TABLE `tst_test_run_scopes` ADD CONSTRAINT `fk_tst_run_scopes_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_test_run_scopes' AND constraint_name = 'fk_tst_run_scopes_bug'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A run holds at most one item per source test case, mirroring the canonical rule.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''uq_tst_run_items_run_source_case already present'' AS skipped',
        'ALTER TABLE `tst_test_run_items` ADD UNIQUE KEY `uq_tst_run_items_run_source_case` (`run_id`,`source_test_case_id`)')
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'tst_test_run_items' AND index_name = 'uq_tst_run_items_run_source_case'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A failed result belongs to a failure signature group.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_results_signature already present'' AS skipped',
        'ALTER TABLE `tst_test_run_results` ADD CONSTRAINT `fk_tst_results_signature` FOREIGN KEY (`failure_signature_id`) REFERENCES `tst_failure_signatures`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_test_run_results' AND constraint_name = 'fk_tst_results_signature'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A signature carries a sample result and, once triaged, its bug or known issue.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_failure_sig_sample already present'' AS skipped',
        'ALTER TABLE `tst_failure_signatures` ADD CONSTRAINT `fk_tst_failure_sig_sample` FOREIGN KEY (`sample_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_failure_sig_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_failure_sig_known` FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_failure_signatures' AND constraint_name = 'fk_tst_failure_sig_sample'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A bug may carry a failure signature and a release.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_bugs_signature already present'' AS skipped',
        'ALTER TABLE `tst_bugs` ADD CONSTRAINT `fk_tst_bugs_signature` FOREIGN KEY (`failure_signature_id`) REFERENCES `tst_failure_signatures`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_bugs_release` FOREIGN KEY (`release_id`) REFERENCES `tst_releases`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_bugs' AND constraint_name = 'fk_tst_bugs_signature'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A known issue may be promoted to a bug, retaining its occurrence history.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_known_issues_promoted_bug already present'' AS skipped',
        'ALTER TABLE `tst_known_issues` ADD CONSTRAINT `fk_tst_known_issues_promoted_bug` FOREIGN KEY (`promoted_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_known_issues' AND constraint_name = 'fk_tst_known_issues_promoted_bug'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A note may attribute a failure to a known issue.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_annotations_known_issue already present'' AS skipped',
        'ALTER TABLE `tst_run_annotations` ADD CONSTRAINT `fk_tst_annotations_known_issue` FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_run_annotations' AND constraint_name = 'fk_tst_annotations_known_issue'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- An analysis may originate from a bug or a release, and may name the run that executed it.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_impact_bug already present'' AS skipped',
        'ALTER TABLE `tst_impact_analyses` ADD CONSTRAINT `fk_tst_impact_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_impact_release` FOREIGN KEY (`release_id`) REFERENCES `tst_releases`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_impact_run` FOREIGN KEY (`executed_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_impact_analyses' AND constraint_name = 'fk_tst_impact_bug'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A source test case records the import that brought it here.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_source_tc_import already present'' AS skipped',
        'ALTER TABLE `tst_source_test_cases` ADD CONSTRAINT `fk_tst_source_tc_import` FOREIGN KEY (`imported_via_import_id`) REFERENCES `tst_data_imports`(`id`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_source_test_cases' AND constraint_name = 'fk_tst_source_tc_import'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A user holds a primary role.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_users_primary_role already present'' AS skipped',
        'ALTER TABLE `tst_users` ADD CONSTRAINT `fk_tst_users_primary_role` FOREIGN KEY (`primary_role_code`) REFERENCES `tst_roles`(`code`)')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_users' AND constraint_name = 'fk_tst_users_primary_role'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A schema version records who applied it.
SET @sql := (
    SELECT IF(COUNT(*) > 0,
        'SELECT ''fk_tst_schema_version_by already present'' AS skipped',
        'ALTER TABLE `tst_schema_version` ADD CONSTRAINT `fk_tst_schema_version_by` FOREIGN KEY (`applied_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL')
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'tst_schema_version' AND constraint_name = 'fk_tst_schema_version_by'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- =========================================================================================================
-- SECTION 18: VIEWS
--     Every view derives from RECORDED RESULTS, never from a current-status column alone (BR-RPT-01).
--     Views intended for dashboards read the summary table; views intended for investigation read the
--     results table directly and are always used with a filter.
-- =========================================================================================================

-- The catalog with its full hierarchy and current health. The main list screen reads this.
CREATE OR REPLACE VIEW `vw_test_case_catalog` AS
SELECT
    tc.id                       AS test_case_id,
    m.module_code,
    m.name                      AS module_name,
    c.cat_code,
    c.name                      AS category_name,
    mm.mm_code,
    mm.name                     AS main_menu_name,
    sm.sm_code,
    sm.name                     AS sub_menu_name,
    t.ts_code,
    t.name                      AS screen_name,
    t.route_url,
    t.is_excluded               AS screen_excluded,
    tc.test_case_code,
    tc.display_name             AS test_case_name,
    tc.test_case_type_code,
    tc.test_method_code,
    tc.test_technology_code,
    tc.test_layer_code,
    tc.status_code,
    tc.criticality,
    tc.version_no,
    tc.is_active,
    tc.is_orphaned,
    tc.is_confirmed,
    cs.last_status,
    cs.last_run_at,
    cs.pass_rate_30d,
    cs.confidence_score,
    cs.health_status,
    cs.is_flaky_confirmed,
    cs.consecutive_failures,
    cs.open_bug_count
FROM tst_test_cases tc
JOIN tst_tabs_screens t   ON t.ts_code = tc.ts_code
JOIN tst_modules m        ON m.module_code = t.module_code
JOIN tst_categories c     ON c.module_code = t.module_code AND c.cat_code = t.cat_code
JOIN tst_main_menus mm    ON mm.module_code = t.module_code AND mm.cat_code = t.cat_code AND mm.mm_code = t.mm_code
LEFT JOIN tst_sub_menus sm ON sm.sm_code = t.sm_code
LEFT JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE tc.deleted_at IS NULL;


-- Every attempt of every test case, dated. This is the evidence behind every statistic in the system.
CREATE OR REPLACE VIEW `vw_test_case_history` AS
SELECT
    r.id                        AS result_id,
    r.test_case_id,
    tc.ts_code,
    tc.test_case_code,
    r.display_name_snapshot     AS test_case_name,
    t.module_code,
    r.run_id,
    run.machine_id,
    mac.machine_code,
    run.trigger_type,
    run.commit_hash,
    run.branch_name,
    r.environment_profile_id,
    env.env_name,
    ri.attempt_count,
    r.attempt_no,
    r.is_final_attempt,
    r.status,
    r.duration_seconds,
    r.failure_fingerprint,
    r.triage_state,
    r.executed_by,
    r.created_at                AS executed_at
FROM tst_test_run_results r
JOIN tst_test_run_items ri  ON ri.id = r.run_item_id
JOIN tst_test_runs run      ON run.id = r.run_id
JOIN tst_machines mac       ON mac.id = run.machine_id
LEFT JOIN tst_test_cases tc ON tc.id = r.test_case_id
LEFT JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
LEFT JOIN tst_environment_profiles env ON env.id = r.environment_profile_id
WHERE r.deleted_at IS NULL;


CREATE OR REPLACE VIEW `vw_test_run_history` AS
SELECT
    run.id                      AS run_id,
    run.machine_id,
    mac.machine_code,
    mac.machine_name,
    run.source_run_id,
    run.initiated_by,
    iu.name                     AS initiated_by_name,
    run.executed_by,
    eu.name                     AS executed_by_name,
    run.trigger_type,
    s.suite_code,
    run.suite_version_no,
    run.run_name,
    run.reason,
    run.repository_code,
    run.branch_name,
    run.commit_hash,
    run.merge_commit_hash,
    run.working_tree_dirty,
    env.env_name,
    env.os_name,
    env.browser_name,
    env.browser_version,
    run.status,
    run.queued_at,
    run.started_at,
    run.finished_at,
    run.duration_seconds,
    run.total_tc_count,
    run.passed_tc_count,
    run.failed_tc_count,
    run.error_tc_count,
    run.skipped_tc_count,
    run.blocked_tc_count,
    CASE WHEN run.total_tc_count > 0
         THEN ROUND(run.passed_tc_count * 100.0 / run.total_tc_count, 2)
         ELSE NULL END          AS pass_rate_pct
FROM tst_test_runs run
JOIN tst_machines mac       ON mac.id = run.machine_id
LEFT JOIN tst_users iu      ON iu.code = run.initiated_by
LEFT JOIN tst_users eu      ON eu.code = run.executed_by
LEFT JOIN tst_test_suites s ON s.id = run.suite_id
LEFT JOIN tst_environment_profiles env ON env.id = run.environment_profile_id
WHERE run.deleted_at IS NULL;


-- Why each test case was in each run. Answers "what did we run after that change, and why?"
CREATE OR REPLACE VIEW `vw_run_test_selection_analysis` AS
SELECT
    ri.run_id,
    run.trigger_type,
    run.commit_hash,
    run.merge_commit_hash,
    run.started_at,
    ri.test_case_id,
    tc.ts_code,
    tc.test_case_code,
    ri.display_name_snapshot    AS test_case_name,
    ri.selection_reason,
    ri.selection_source,
    ri.selection_confidence,
    ri.criticality_snapshot,
    ri.final_status,
    ri.blocked_reason
FROM tst_test_run_items ri
JOIN tst_test_runs run      ON run.id = ri.run_id
LEFT JOIN tst_test_cases tc ON tc.id = ri.test_case_id
WHERE ri.deleted_at IS NULL;


-- A test that has passed before and is now failing, excluding confirmed flaky tests.
-- The attributed commits are resolved by the analysis service; this view identifies the candidates.
CREATE OR REPLACE VIEW `vw_regression_candidates` AS
SELECT
    cs.test_case_id,
    tc.ts_code,
    tc.test_case_code,
    tc.display_name,
    tc.criticality,
    t.module_code,
    m.name                      AS module_name,
    t.name                      AS screen_name,
    cs.last_status,
    cs.last_run_at,
    cs.last_passed_at,
    cs.last_failed_at,
    cs.total_passed,
    cs.total_failed,
    cs.consecutive_failures,
    cs.pass_rate_30d,
    cs.confidence_score,
    cs.is_flaky_candidate,
    TIMESTAMPDIFF(DAY, cs.last_passed_at, cs.last_failed_at) AS days_between_pass_and_fail
FROM tst_test_case_runs_summary cs
JOIN tst_test_cases tc      ON tc.id = cs.test_case_id
JOIN tst_tabs_screens t     ON t.ts_code = tc.ts_code
JOIN tst_modules m          ON m.module_code = t.module_code
WHERE cs.last_status IN ('Failed','Error')
  AND cs.total_passed > 0
  AND cs.consecutive_failures > 0
  AND cs.is_flaky_confirmed = 0
  AND tc.deleted_at IS NULL;


CREATE OR REPLACE VIEW `vw_flaky_tests` AS
SELECT
    cs.test_case_id,
    tc.ts_code,
    tc.test_case_code,
    tc.display_name,
    tc.criticality,
    t.module_code,
    m.name                      AS module_name,
    t.name                      AS screen_name,
    cs.flaky_score,
    cs.is_flaky_candidate,
    cs.is_flaky_confirmed,
    cs.flaky_reason,
    cs.flaky_evidence_json,
    cs.flaky_confirmed_by,
    cs.flaky_confirmed_at,
    cs.pass_rate_30d,
    cs.total_runs,
    cs.total_passed,
    cs.total_failed,
    cs.distinct_environments,
    cs.last_status,
    cs.last_run_at
FROM tst_test_case_runs_summary cs
JOIN tst_test_cases tc      ON tc.id = cs.test_case_id
JOIN tst_tabs_screens t     ON t.ts_code = tc.ts_code
JOIN tst_modules m          ON m.module_code = t.module_code
WHERE (cs.is_flaky_confirmed = 1 OR cs.is_flaky_candidate = 1)
  AND tc.deleted_at IS NULL;


CREATE OR REPLACE VIEW `vw_open_bugs` AS
SELECT
    b.id                        AS bug_id,
    b.bug_code,
    b.origin_machine_id,
    b.source_bug_id,
    b.module_code,
    m.name                      AS module_name,
    b.ts_code,
    t.name                      AS screen_name,
    b.test_case_id,
    tc.display_name             AS test_case_name,
    b.title,
    b.severity,
    b.priority,
    b.status,
    b.assigned_to,
    au.name                     AS assigned_to_name,
    b.assigned_at,
    b.sla_due_at,
    b.sla_breached,
    b.reopen_count,
    b.occurrence_count,
    b.retest_attempt_count,
    b.fixed_at,
    b.fixed_commit_hash,
    b.escalated_at,
    b.created_at,
    b.updated_at,
    TIMESTAMPDIFF(DAY, b.created_at, NOW()) AS age_days,
    CASE
        WHEN TIMESTAMPDIFF(DAY, b.created_at, NOW()) <= 3  THEN '0-3 days'
        WHEN TIMESTAMPDIFF(DAY, b.created_at, NOW()) <= 7  THEN '4-7 days'
        WHEN TIMESTAMPDIFF(DAY, b.created_at, NOW()) <= 30 THEN '8-30 days'
        ELSE 'over 30 days'
    END                         AS age_bucket
FROM tst_bugs b
JOIN tst_modules m          ON m.module_code = b.module_code
LEFT JOIN tst_tabs_screens t ON t.ts_code = b.ts_code
LEFT JOIN tst_test_cases tc ON tc.id = b.test_case_id
LEFT JOIN tst_users au      ON au.code = b.assigned_to
WHERE b.deleted_at IS NULL
  AND b.status NOT IN ('Closed','Wont_Fix','Duplicate');


-- Time spent in each state, computed from the transition history rather than from the current status.
CREATE OR REPLACE VIEW `vw_bug_lifecycle` AS
SELECT
    b.id                        AS bug_id,
    b.bug_code,
    b.title,
    b.severity,
    b.status                    AS current_status,
    b.module_code,
    b.created_at                AS raised_at,
    b.assigned_at,
    b.fixed_at,
    b.verified_at,
    b.closed_at,
    b.verification_override,
    b.reopen_count,
    b.root_cause_category,
    TIMESTAMPDIFF(HOUR, b.created_at, b.assigned_at) AS hours_to_assign,
    TIMESTAMPDIFF(HOUR, b.assigned_at, b.fixed_at)   AS hours_to_fix,
    TIMESTAMPDIFF(HOUR, b.fixed_at, b.verified_at)   AS hours_to_verify,
    TIMESTAMPDIFF(HOUR, b.created_at, b.closed_at)   AS hours_total,
    (SELECT COUNT(*) FROM tst_bug_status_history h WHERE h.bug_id = b.id) AS transition_count,
    (SELECT COUNT(*) FROM tst_retest_cycles rc WHERE rc.bug_id = b.id)    AS retest_cycle_count
FROM tst_bugs b
WHERE b.deleted_at IS NULL;


CREATE OR REPLACE VIEW `vw_screen_coverage` AS
SELECT
    t.ts_code,
    t.name                      AS screen_name,
    t.module_code,
    m.name                      AS module_name,
    t.criticality,
    t.dev_status,
    t.requir_doc_status,
    t.tc_list_status,
    t.tc_creation_status,
    t.is_excluded,
    t.exclusion_reason,
    COUNT(tc.id)                                                        AS test_case_count,
    SUM(CASE WHEN tc.test_method_code = 'Automated' THEN 1 ELSE 0 END)  AS automated_count,
    SUM(CASE WHEN tc.test_method_code = 'Manual'    THEN 1 ELSE 0 END)  AS manual_count,
    SUM(CASE WHEN cs.last_status = 'Passed' THEN 1 ELSE 0 END)          AS last_passed,
    SUM(CASE WHEN cs.last_status IN ('Failed','Error') THEN 1 ELSE 0 END) AS last_failed,
    SUM(CASE WHEN cs.test_case_id IS NULL THEN 1 ELSE 0 END)            AS never_executed,
    MAX(cs.last_run_at)                                                 AS last_executed_at,
    CASE
        WHEN t.is_excluded = 1      THEN 'Excluded'
        WHEN COUNT(tc.id) = 0       THEN 'No Coverage'
        WHEN SUM(CASE WHEN cs.test_case_id IS NULL THEN 1 ELSE 0 END) = COUNT(tc.id) THEN 'Never Executed'
        WHEN SUM(CASE WHEN cs.last_status IN ('Failed','Error') THEN 1 ELSE 0 END) > 0 THEN 'Failing'
        ELSE 'Covered'
    END                                                                 AS coverage_state
FROM tst_tabs_screens t
JOIN tst_modules m          ON m.module_code = t.module_code
LEFT JOIN tst_test_cases tc ON tc.ts_code = t.ts_code AND tc.is_active = 1 AND tc.deleted_at IS NULL
LEFT JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE t.deleted_at IS NULL
GROUP BY t.ts_code, t.name, t.module_code, m.name, t.criticality, t.dev_status,
         t.requir_doc_status, t.tc_list_status, t.tc_creation_status, t.is_excluded, t.exclusion_reason;


CREATE OR REPLACE VIEW `vw_module_quality_summary` AS
SELECT
    m.module_code,
    m.name                      AS module_name,
    m.criticality,
    COUNT(DISTINCT t.ts_code)                                               AS screen_count,
    COUNT(DISTINCT CASE WHEN t.is_excluded = 1 THEN t.ts_code END)          AS excluded_screens,
    COUNT(DISTINCT tc.id)                                                   AS test_case_count,
    COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN tc.id END)      AS last_passed,
    COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN tc.id END) AS last_failed,
    COUNT(DISTINCT CASE WHEN cs.test_case_id IS NULL THEN tc.id END)        AS never_executed,
    COUNT(DISTINCT CASE WHEN cs.is_flaky_confirmed = 1 THEN tc.id END)      AS flaky_tests,
    COUNT(DISTINCT CASE WHEN tc.is_orphaned = 1 THEN tc.id END)             AS orphaned_tests,
    ROUND(AVG(cs.pass_rate_30d), 2)                                         AS avg_pass_rate_30d,
    ROUND(AVG(cs.confidence_score), 2)                                      AS avg_confidence,
    MAX(cs.last_run_at)                                                     AS last_executed_at
FROM tst_modules m
LEFT JOIN tst_tabs_screens t ON t.module_code = m.module_code AND t.deleted_at IS NULL
LEFT JOIN tst_test_cases tc  ON tc.ts_code = t.ts_code AND tc.is_active = 1 AND tc.deleted_at IS NULL
LEFT JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE m.deleted_at IS NULL
GROUP BY m.module_code, m.name, m.criticality;


-- Open bugs per module, kept separate from vw_module_quality_summary so that neither join inflates
-- the other's counts.
CREATE OR REPLACE VIEW `vw_module_open_bugs` AS
SELECT
    b.module_code,
    COUNT(*)                                                        AS open_bugs,
    SUM(CASE WHEN b.severity = 'Critical' THEN 1 ELSE 0 END)        AS open_critical,
    SUM(CASE WHEN b.severity = 'High' THEN 1 ELSE 0 END)            AS open_high,
    SUM(CASE WHEN b.sla_breached = 1 THEN 1 ELSE 0 END)             AS sla_breached,
    MAX(b.created_at)                                               AS newest_bug_at
FROM tst_bugs b
WHERE b.deleted_at IS NULL
  AND b.status NOT IN ('Closed','Wont_Fix','Duplicate')
GROUP BY b.module_code;


CREATE OR REPLACE VIEW `vw_requirement_coverage` AS
SELECT
    r.id                        AS requirement_id,
    r.req_code,
    r.module_code,
    r.title,
    r.criticality,
    r.status,
    COUNT(DISTINCT rtc.test_case_id)                                        AS mapped_test_count,
    COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN rtc.test_case_id END)      AS passing_test_count,
    COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN rtc.test_case_id END) AS failing_test_count,
    COUNT(DISTINCT CASE WHEN cs.test_case_id IS NULL THEN rtc.test_case_id END)        AS never_executed_count,
    CASE
        WHEN COUNT(rtc.test_case_id) = 0 THEN 'Uncovered'
        WHEN COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN rtc.test_case_id END) = 0 THEN 'Covered, Never Passed'
        WHEN COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN rtc.test_case_id END) > 0 THEN 'Covered, Failing'
        ELSE 'Covered'
    END                                                                     AS coverage_state
FROM tst_app_requirements r
LEFT JOIN tst_app_requirement_test_cases rtc ON rtc.requirement_id = r.id
LEFT JOIN tst_test_case_runs_summary cs ON cs.test_case_id = rtc.test_case_id
WHERE r.deleted_at IS NULL
GROUP BY r.id, r.req_code, r.module_code, r.title, r.criticality, r.status;


-- The testing debt register: quality erosion made visible and assignable rather than accumulating
-- silently. One row per debt item, categorised (Enhancement E-03).
CREATE OR REPLACE VIEW `vw_testing_debt` AS
SELECT 'Screen_Without_Tests' AS debt_type, t.module_code, t.ts_code,
       NULL AS test_case_id, t.name AS item_name,
       'Screen has no active test cases' AS detail, t.criticality, NULL AS last_activity_at
FROM tst_tabs_screens t
LEFT JOIN tst_test_cases tc ON tc.ts_code = t.ts_code AND tc.is_active = 1 AND tc.deleted_at IS NULL
WHERE t.is_active = 1 AND t.is_excluded = 0 AND t.deleted_at IS NULL
GROUP BY t.module_code, t.ts_code, t.name, t.criticality
HAVING COUNT(tc.id) = 0

UNION ALL
SELECT 'Test_Never_Executed', t.module_code, tc.ts_code, tc.id, tc.display_name,
       'Test case has never been executed', tc.criticality, NULL
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
LEFT JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE tc.is_active = 1 AND tc.deleted_at IS NULL AND cs.test_case_id IS NULL

UNION ALL
SELECT 'Test_Stale', t.module_code, tc.ts_code, tc.id, tc.display_name,
       CONCAT('Not executed since ', DATE(cs.last_run_at)), tc.criticality, cs.last_run_at
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE tc.is_active = 1 AND tc.deleted_at IS NULL
  AND cs.last_run_at < DATE_SUB(NOW(), INTERVAL 90 DAY)

UNION ALL
SELECT 'Test_Orphaned', t.module_code, tc.ts_code, tc.id, tc.display_name,
       'Implementation is no longer present in the source tree', tc.criticality, tc.orphaned_at
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
WHERE tc.is_orphaned = 1 AND tc.deleted_at IS NULL

UNION ALL
SELECT 'Test_Flaky', t.module_code, tc.ts_code, tc.id, tc.display_name,
       COALESCE(cs.flaky_reason,'Confirmed flaky'), tc.criticality, cs.last_run_at
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE cs.is_flaky_confirmed = 1 AND tc.deleted_at IS NULL

UNION ALL
SELECT 'Test_Frequently_Failing', t.module_code, tc.ts_code, tc.id, tc.display_name,
       CONCAT('Pass rate over 30 days: ', COALESCE(cs.pass_rate_30d,0), '%'), tc.criticality, cs.last_run_at
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
JOIN tst_test_case_runs_summary cs ON cs.test_case_id = tc.id
WHERE cs.health_status = 'Frequently_Failing' AND tc.deleted_at IS NULL

UNION ALL
SELECT 'Test_Without_Requirement', t.module_code, tc.ts_code, tc.id, tc.display_name,
       'Test case is not mapped to any application requirement', tc.criticality, NULL
FROM tst_test_cases tc
JOIN tst_tabs_screens t ON t.ts_code = tc.ts_code
LEFT JOIN tst_app_requirement_test_cases rtc ON rtc.test_case_id = tc.id
WHERE tc.is_active = 1 AND tc.deleted_at IS NULL AND rtc.test_case_id IS NULL

UNION ALL
SELECT 'Requirement_Uncovered', r.module_code, r.ts_code, NULL, r.title,
       'Requirement has no mapped test case', r.criticality, NULL
FROM tst_app_requirements r
LEFT JOIN tst_app_requirement_test_cases rtc ON rtc.requirement_id = r.id
WHERE r.is_active = 1 AND r.deleted_at IS NULL AND rtc.requirement_id IS NULL;


-- Workload attribution. Deliberately NOT a performance score: it counts activity, never quality, and it
-- is visible to leads only (BR-CROSS-06).
CREATE OR REPLACE VIEW `vw_developer_activity_summary` AS
SELECT
    u.code                      AS user_code,
    u.name                      AS user_name,
    u.primary_role_code         AS role_code,
    COALESCE(r.total_runs, 0)           AS total_runs,
    COALESCE(r.total_tests_executed, 0) AS total_tests_executed,
    COALESCE(r.total_passed, 0)         AS total_passed,
    COALESCE(r.total_failed, 0)         AS total_failed,
    COALESCE(br.bugs_raised, 0)         AS bugs_raised,
    COALESCE(ba.bugs_assigned, 0)       AS bugs_open_assigned,
    COALESCE(bf.bugs_fixed, 0)          AS bugs_fixed,
    COALESCE(bv.bugs_verified, 0)       AS bugs_verified,
    r.last_run_at
FROM tst_users u
LEFT JOIN (
    SELECT initiated_by AS user_code,
           COUNT(*) AS total_runs,
           COALESCE(SUM(total_tc_count),0)  AS total_tests_executed,
           COALESCE(SUM(passed_tc_count),0) AS total_passed,
           COALESCE(SUM(failed_tc_count),0) AS total_failed,
           MAX(finished_at) AS last_run_at
    FROM tst_test_runs
    WHERE initiated_by IS NOT NULL AND deleted_at IS NULL
    GROUP BY initiated_by
) r ON r.user_code = u.code
LEFT JOIN (
    SELECT created_by AS user_code, COUNT(*) AS bugs_raised
    FROM tst_bugs WHERE deleted_at IS NULL GROUP BY created_by
) br ON br.user_code = u.code
LEFT JOIN (
    SELECT assigned_to AS user_code, COUNT(*) AS bugs_assigned
    FROM tst_bugs
    WHERE deleted_at IS NULL AND assigned_to IS NOT NULL
      AND status NOT IN ('Closed','Wont_Fix','Duplicate')
    GROUP BY assigned_to
) ba ON ba.user_code = u.code
LEFT JOIN (
    SELECT fixed_by AS user_code, COUNT(*) AS bugs_fixed
    FROM tst_bugs WHERE deleted_at IS NULL AND fixed_by IS NOT NULL GROUP BY fixed_by
) bf ON bf.user_code = u.code
LEFT JOIN (
    SELECT verified_by AS user_code, COUNT(*) AS bugs_verified
    FROM tst_bugs WHERE deleted_at IS NULL AND verified_by IS NOT NULL GROUP BY verified_by
) bv ON bv.user_code = u.code
WHERE u.is_active = 1 AND u.is_system = 0;


-- The same test case across machines. This is how a machine-specific problem becomes visible.
CREATE OR REPLACE VIEW `vw_machine_comparison` AS
SELECT
    res.test_case_id,
    tc.ts_code,
    tc.test_case_code,
    tc.display_name,
    res.machine_id,
    mac.machine_code,
    mac.owner_user_code,
    COUNT(*)                                                    AS attempts,
    SUM(CASE WHEN res.status = 'Passed' THEN 1 ELSE 0 END)      AS passed,
    SUM(CASE WHEN res.status IN ('Failed','Error') THEN 1 ELSE 0 END) AS failed,
    ROUND(SUM(CASE WHEN res.status = 'Passed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pass_rate_pct,
    MAX(res.created_at)                                         AS last_executed_at
FROM tst_test_run_results res
JOIN tst_test_cases tc  ON tc.id = res.test_case_id
JOIN tst_machines mac   ON mac.id = res.machine_id
WHERE res.is_final_attempt = 1 AND res.deleted_at IS NULL
GROUP BY res.test_case_id, tc.ts_code, tc.test_case_code, tc.display_name,
         res.machine_id, mac.machine_code, mac.owner_user_code;


CREATE OR REPLACE VIEW `vw_environment_impact` AS
SELECT
    env.id                      AS environment_profile_id,
    env.env_name,
    env.env_type,
    env.os_name,
    env.os_version,
    env.browser_name,
    env.browser_version,
    env.php_version,
    COUNT(*)                                                    AS attempts,
    SUM(CASE WHEN res.status = 'Passed' THEN 1 ELSE 0 END)      AS passed,
    SUM(CASE WHEN res.status IN ('Failed','Error') THEN 1 ELSE 0 END) AS failed,
    ROUND(SUM(CASE WHEN res.status = 'Passed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pass_rate_pct,
    COUNT(DISTINCT res.test_case_id)                            AS distinct_test_cases,
    MAX(res.created_at)                                         AS last_executed_at
FROM tst_test_run_results res
JOIN tst_environment_profiles env ON env.id = res.environment_profile_id
WHERE res.is_final_attempt = 1 AND res.deleted_at IS NULL
GROUP BY env.id, env.env_name, env.env_type, env.os_name, env.os_version,
         env.browser_name, env.browser_version, env.php_version;


CREATE OR REPLACE VIEW `vw_known_issue_occurrences` AS
SELECT
    ki.id                       AS known_issue_id,
    ki.issue_code,
    ki.title,
    ki.category,
    ki.module_code,
    ki.ts_code,
    ki.status,
    ki.owner_user_code,
    ki.review_due_at,
    CASE WHEN ki.review_due_at IS NOT NULL AND ki.review_due_at < CURDATE() THEN 1 ELSE 0 END AS is_overdue_review,
    COUNT(kir.run_result_id)    AS occurrence_count,
    MIN(res.created_at)         AS first_occurrence_at,
    MAX(res.created_at)         AS last_occurrence_at,
    COUNT(DISTINCT res.test_case_id) AS distinct_test_cases
FROM tst_known_issues ki
LEFT JOIN tst_known_issue_results kir ON kir.known_issue_id = ki.id
LEFT JOIN tst_test_run_results res    ON res.id = kir.run_result_id
WHERE ki.deleted_at IS NULL
GROUP BY ki.id, ki.issue_code, ki.title, ki.category, ki.module_code, ki.ts_code,
         ki.status, ki.owner_user_code, ki.review_due_at;


-- KPI K-05: of the defects found, how many were inside the scope the analysis proposed.
CREATE OR REPLACE VIEW `vw_impact_analysis_effectiveness` AS
SELECT
    ia.id                       AS analysis_id,
    ia.analysis_name,
    ia.source_type,
    ia.status,
    ia.from_commit_hash,
    ia.to_commit_hash,
    ia.changed_file_count,
    ia.unresolved_file_count,
    ia.proposed_test_count,
    ia.included_test_count,
    ia.excluded_test_count,
    ia.defects_found_in_scope,
    ia.defects_found_out_of_scope,
    CASE WHEN (ia.defects_found_in_scope + ia.defects_found_out_of_scope) > 0
         THEN ROUND(ia.defects_found_in_scope * 100.0
                    / (ia.defects_found_in_scope + ia.defects_found_out_of_scope), 2)
         ELSE NULL END          AS hit_rate_pct,
    ia.approved_by,
    ia.approved_at,
    ia.executed_run_id,
    ia.created_at
FROM tst_impact_analyses ia
WHERE ia.deleted_at IS NULL;


CREATE OR REPLACE VIEW `vw_release_readiness` AS
SELECT
    rel.id                      AS release_id,
    rel.release_code,
    rel.name,
    rel.status,
    rel.planned_date,
    rel.from_commit_hash,
    rel.to_commit_hash,
    rel.changed_screen_count,
    rel.tested_screen_count,
    CASE WHEN rel.changed_screen_count > 0
         THEN ROUND(rel.tested_screen_count * 100.0 / rel.changed_screen_count, 2)
         ELSE NULL END          AS changed_screen_coverage_pct,
    rel.open_bugs,
    rel.open_critical_bugs,
    rel.known_issues_in_scope,
    rel.readiness_score,
    rel.readiness_assessment,
    rel.readiness_reservations,
    rel.assessed_by,
    rel.assessed_at,
    rel.signed_off_by,
    rel.signed_off_at,
    (SELECT COUNT(*) FROM tst_test_runs r WHERE r.release_id = rel.id AND r.deleted_at IS NULL) AS run_count,
    (SELECT COALESCE(SUM(r.failed_tc_count),0) FROM tst_test_runs r WHERE r.release_id = rel.id AND r.deleted_at IS NULL) AS failed_tests
FROM tst_releases rel
WHERE rel.deleted_at IS NULL;


CREATE OR REPLACE VIEW `vw_import_status` AS
SELECT
    imp.id                      AS import_id,
    imp.source_machine_id,
    mac.machine_code            AS source_machine_code,
    imp.source_export_id,
    imp.imported_by,
    imp.file_name,
    imp.source_schema_version,
    imp.version_decision,
    imp.status,
    imp.started_at,
    imp.finished_at,
    imp.records_created,
    imp.records_matched,
    imp.records_rejected,
    imp.conflict_count,
    imp.open_conflict_count,
    (SELECT COUNT(*) FROM tst_import_conflicts c
      WHERE c.import_id = imp.id AND c.status = 'Open' AND c.severity = 'Blocking') AS blocking_conflicts
FROM tst_data_imports imp
JOIN tst_machines mac ON mac.id = imp.source_machine_id;


-- =========================================================================================================
-- SECTION 19: SEED DATA
--     Order matters: roles -> permissions -> users -> masters -> settings.
--     v6.7's seeds inserted created_by='super', a user code that was never created, so every master
--     seed violated its foreign key the moment checks were enabled (defect #3). All seeds now use 'S1'.
-- =========================================================================================================

-- ---------------------------------------------------------------------------------------------------------
-- 19.1 Roles
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_roles` (`code`,`name`,`description`,`ordinal`,`is_system`) VALUES
('Admin',    'System Administrator', 'Users, machines, settings, retention, import approval', 1, 1),
('Architect','Architect / Dev Lead', 'Catalog, dependencies, path mappings, suites, impact review', 2, 1),
('QA_Lead',  'QA Lead',              'Coverage, triage, bug assignment, approvals, release sign-off', 3, 1),
('Tester',   'Tester',               'Execute tests, record results and evidence, raise bugs, retest', 4, 1),
('Developer','Developer',            'Review and fix assigned bugs, run impacted tests', 5, 1),
('Reviewer', 'Reviewer',             'Review and approve; read-oriented access', 6, 1),
('Analyst',  'Business Analyst',     'Application requirements and coverage traceability', 7, 1),
('Manager',  'Management',           'Dashboards and release assessments; read only', 8, 1),
('System',   'System Process',       'Scheduler, importer, retest engine, discovery', 9, 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `description`=VALUES(`description`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.2 Permissions
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_permissions` (`code`,`name`,`area`,`is_sensitive`) VALUES
('catalog.view',        'View catalog',                     'Catalog',   0),
('catalog.manage',      'Create and edit catalog entries',  'Catalog',   0),
('catalog.exclude',     'Exclude a screen from testing',    'Catalog',   0),
('testcase.view',       'View test cases',                  'Catalog',   0),
('testcase.manage',     'Create and edit test cases',       'Catalog',   0),
('testcase.retire',     'Retire a test case',               'Catalog',   0),
('testcase.link',       'Confirm equivalence or duplicate', 'Catalog',   0),
('discovery.run',       'Run discovery',                    'Catalog',   0),
('discovery.confirm',   'Confirm discovered items',         'Catalog',   0),
('suite.manage',        'Manage test suites',               'Catalog',   0),
('requirement.view',    'View application requirements',    'Catalog',   0),
('requirement.manage',  'Manage application requirements',  'Catalog',   0),
('run.execute',         'Execute test runs',                'Execution', 0),
('run.cancel',          'Cancel a running test run',        'Execution', 0),
('run.view',            'View runs and results',            'Execution', 0),
('result.annotate',     'Add notes to runs and results',    'Execution', 0),
('result.triage',       'Classify a failure',               'Execution', 0),
('bug.view',            'View bugs',                        'Defects',   0),
('bug.create',          'Raise a bug',                      'Defects',   0),
('bug.assign',          'Assign a bug',                     'Defects',   0),
('bug.update',          'Update a bug assigned to you',     'Defects',   0),
('bug.close',           'Close a bug',                      'Defects',   0),
('bug.override_verify', 'Close a bug without a passing retest', 'Defects', 1),
('bug.link',            'Confirm duplicate or related bugs','Defects',   0),
('knownissue.manage',   'Manage known issues',              'Defects',   0),
('retest.trigger',      'Trigger a retest cycle',           'Defects',   0),
('impact.create',       'Create an impact analysis',        'Impact',    0),
('impact.approve',      'Approve an impact analysis',       'Impact',    0),
('dependency.manage',   'Manage dependencies and path mappings','Impact', 0),
('schedule.manage',     'Manage schedules',                 'Execution', 0),
('release.manage',      'Manage releases',                  'Release',   0),
('release.signoff',     'Sign off a release',               'Release',   1),
('export.create',       'Create an export bundle',          'Sync',      0),
('import.apply',        'Apply an import bundle',           'Sync',      1),
('import.resolve',      'Resolve an import conflict',       'Sync',      1),
('import.reverse',      'Reverse an import',                'Sync',      1),
('ai.request',          'Request an AI analysis',           'Insight',   0),
('ai.review',           'Accept or reject a recommendation','Insight',   0),
('report.view',         'View reports and dashboards',      'Reporting', 0),
('report.team',         'View team activity reports',       'Reporting', 0),
('audit.view',          'View the audit log',               'Admin',     0),
('user.manage',         'Manage users and roles',           'Admin',     1),
('machine.manage',      'Register and manage machines',     'Admin',     1),
('settings.manage',     'Change system settings',           'Admin',     1),
('retention.purge',     'Run a retention purge',            'Admin',     1),
('record.purge',        'Permanently delete a record',      'Admin',     1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `area`=VALUES(`area`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.3 Role -> permission matrix
-- ---------------------------------------------------------------------------------------------------------
-- Admin holds everything.
INSERT INTO `tst_role_permissions` (`role_code`,`permission_code`)
SELECT 'Admin', `code` FROM `tst_permissions`
ON DUPLICATE KEY UPDATE `role_code`=VALUES(`role_code`);

-- System process: everything except the sensitive administrative actions and human judgement calls.
INSERT INTO `tst_role_permissions` (`role_code`,`permission_code`)
SELECT 'System', `code` FROM `tst_permissions`
WHERE `code` IN ('run.execute','run.view','result.triage','bug.create','bug.view','retest.trigger',
                 'impact.create','discovery.run','export.create','report.view')
ON DUPLICATE KEY UPDATE `role_code`=VALUES(`role_code`);

INSERT INTO `tst_role_permissions` (`role_code`,`permission_code`) VALUES
('Architect','catalog.view'),('Architect','catalog.manage'),('Architect','catalog.exclude'),
('Architect','testcase.view'),('Architect','testcase.manage'),('Architect','testcase.retire'),('Architect','testcase.link'),
('Architect','discovery.run'),('Architect','discovery.confirm'),('Architect','suite.manage'),
('Architect','requirement.view'),('Architect','run.execute'),('Architect','run.view'),('Architect','run.cancel'),
('Architect','result.annotate'),('Architect','result.triage'),('Architect','bug.view'),('Architect','bug.create'),
('Architect','impact.create'),('Architect','impact.approve'),('Architect','dependency.manage'),
('Architect','release.manage'),('Architect','ai.request'),('Architect','ai.review'),
('Architect','report.view'),('Architect','report.team'),('Architect','audit.view'),('Architect','export.create'),

('QA_Lead','catalog.view'),('QA_Lead','catalog.exclude'),('QA_Lead','testcase.view'),('QA_Lead','testcase.manage'),
('QA_Lead','testcase.retire'),('QA_Lead','testcase.link'),('QA_Lead','discovery.confirm'),('QA_Lead','suite.manage'),
('QA_Lead','requirement.view'),('QA_Lead','run.execute'),('QA_Lead','run.view'),('QA_Lead','run.cancel'),
('QA_Lead','result.annotate'),('QA_Lead','result.triage'),('QA_Lead','bug.view'),('QA_Lead','bug.create'),
('QA_Lead','bug.assign'),('QA_Lead','bug.update'),('QA_Lead','bug.close'),('QA_Lead','bug.link'),
('QA_Lead','knownissue.manage'),('QA_Lead','retest.trigger'),('QA_Lead','impact.create'),('QA_Lead','impact.approve'),
('QA_Lead','schedule.manage'),('QA_Lead','release.manage'),('QA_Lead','release.signoff'),
('QA_Lead','ai.request'),('QA_Lead','ai.review'),('QA_Lead','report.view'),('QA_Lead','report.team'),
('QA_Lead','export.create'),('QA_Lead','import.resolve'),

('Tester','catalog.view'),('Tester','testcase.view'),('Tester','testcase.manage'),
('Tester','run.execute'),('Tester','run.view'),('Tester','run.cancel'),
('Tester','result.annotate'),('Tester','result.triage'),
('Tester','bug.view'),('Tester','bug.create'),('Tester','bug.update'),('Tester','retest.trigger'),
('Tester','requirement.view'),('Tester','report.view'),('Tester','export.create'),('Tester','ai.request'),

('Developer','catalog.view'),('Developer','testcase.view'),
('Developer','run.execute'),('Developer','run.view'),('Developer','run.cancel'),
('Developer','result.annotate'),('Developer','bug.view'),('Developer','bug.update'),('Developer','bug.create'),
('Developer','impact.create'),('Developer','requirement.view'),('Developer','report.view'),
('Developer','export.create'),('Developer','ai.request'),

('Reviewer','catalog.view'),('Reviewer','testcase.view'),('Reviewer','run.view'),('Reviewer','bug.view'),
('Reviewer','requirement.view'),('Reviewer','report.view'),('Reviewer','ai.review'),('Reviewer','audit.view'),

('Analyst','catalog.view'),('Analyst','testcase.view'),('Analyst','requirement.view'),('Analyst','requirement.manage'),
('Analyst','run.view'),('Analyst','bug.view'),('Analyst','report.view'),

('Manager','report.view'),('Manager','report.team'),('Manager','run.view'),('Manager','bug.view'),
('Manager','catalog.view'),('Manager','testcase.view'),('Manager','requirement.view')
ON DUPLICATE KEY UPDATE `role_code`=VALUES(`role_code`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.4 Users
--     The bootstrap row is inserted with created_by NULL and updated afterwards, so the self-referencing
--     foreign key is satisfied without relying on FOREIGN_KEY_CHECKS being disabled (defect #4).
--     REPLACE THE PLACEHOLDER HASHES BEFORE USE.
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_users`
(`code`,`name`,`email`,`password`,`primary_role_code`,`is_superuser`,`is_system`,`is_active`,`created_by`,`updated_by`)
VALUES
('S1','Super User','super@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_SUPER','Admin',1,1,1,NULL,NULL)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `email`=VALUES(`email`);

UPDATE `tst_users` SET `created_by`='S1', `updated_by`='S1' WHERE `code`='S1';

INSERT INTO `tst_users`
(`code`,`name`,`email`,`password`,`primary_role_code`,`is_superuser`,`is_system`,`is_active`,`created_by`,`updated_by`)
VALUES
('S2','System','system@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_SYSTEM','System',   0,1,1,'S1','S1'),
('A1','Brijesh','brijesh@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_BRIJ','Architect', 0,0,1,'S1','S1'),
('D2','Tarun','tarun@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_TARUN','Developer',    0,0,1,'S1','S1'),
('D3','Shailesh','shailesh@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_SHAIL','Developer',0,0,1,'S1','S1'),
('T1','Sameer','sameer@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_SAMER','Tester',     0,0,1,'S1','S1'),
('T2','Gaurav','gaurav@prime-testing.local','$2y$12$REPLACE_THIS_PLACEHOLDER_HASH_GAURAV','Developer', 0,0,1,'S1','S1')
ON DUPLICATE KEY UPDATE
    `name`=VALUES(`name`), `email`=VALUES(`email`),
    `primary_role_code`=VALUES(`primary_role_code`), `is_active`=VALUES(`is_active`);

-- Additional responsibilities beyond the primary role.
INSERT INTO `tst_user_roles` (`user_code`,`role_code`,`granted_by`) VALUES
('A1','QA_Lead','S1'),
('T1','QA_Lead','S1')
ON DUPLICATE KEY UPDATE `granted_by`=VALUES(`granted_by`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.5 Reference masters
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_test_case_types` (`code`,`name`,`ordinal`,`created_by`,`updated_by`) VALUES
('Standard','Standard',1,'S1','S1'),
('Unit','Unit',2,'S1','S1'),
('Validation','Validation',3,'S1','S1'),
('Feature','Feature',4,'S1','S1'),
('Business_Condition','Business Condition',5,'S1','S1'),
('Negative','Negative',6,'S1','S1'),
('Boundary','Boundary',7,'S1','S1'),
('Permission','Permission',8,'S1','S1'),
('Regression','Regression',9,'S1','S1')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `ordinal`=VALUES(`ordinal`);

INSERT INTO `tst_testing_methods` (`code`,`name`,`ordinal`,`created_by`,`updated_by`) VALUES
('Manual','Manual',1,'S1','S1'),
('Automated','Automated',2,'S1','S1'),
('Hybrid','Hybrid',3,'S1','S1')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `tst_testing_technologies` (`code`,`name`,`adapter_class`,`ordinal`,`created_by`,`updated_by`) VALUES
('Dusk','Laravel Dusk','App\\Execution\\Adapters\\DuskAdapter',1,'S1','S1'),
('Pest','Pest','App\\Execution\\Adapters\\PestAdapter',2,'S1','S1'),
('PHPUnit','PHPUnit','App\\Execution\\Adapters\\PhpUnitAdapter',3,'S1','S1'),
('Manual','Manual Execution','App\\Execution\\Adapters\\ManualAdapter',4,'S1','S1'),
('External','External / CI','App\\Execution\\Adapters\\ExternalAdapter',5,'S1','S1'),
('Native','Native / Other',NULL,6,'S1','S1')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `adapter_class`=VALUES(`adapter_class`);

INSERT INTO `tst_testing_layers` (`code`,`name`,`ordinal`,`created_by`,`updated_by`) VALUES
('GUI','GUI',1,'S1','S1'),
('API','API',2,'S1','S1'),
('Unit','Unit',3,'S1','S1'),
('Integration','Integration',4,'S1','S1'),
('Database','Database',5,'S1','S1'),
('Performance','Performance',6,'S1','S1'),
('Security','Security',7,'S1','S1'),
('Tenancy','Tenancy',8,'S1','S1'),
('Accessibility','Accessibility',9,'S1','S1'),
('Other','Other',10,'S1','S1')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 'Draft' must exist: it is the default status_code on tst_test_cases.
-- is_selectable = 0 means automatic selection will not pick a test case in this state (BR-LC-TC-01).
INSERT INTO `tst_test_case_statuses` (`code`,`name`,`is_selectable`,`ordinal`,`created_by`,`updated_by`) VALUES
('Draft','Draft',0,1,'S1','S1'),
('Under_Review','Under Review',0,2,'S1','S1'),
('Active','Active',1,3,'S1','S1'),
('Needs_Update','Needs Update',0,4,'S1','S1'),
('Blocked','Blocked',0,5,'S1','S1'),
('Hold','Hold',0,6,'S1','S1'),
('Retired','Retired',0,7,'S1','S1'),
('Not_Required','Not Required',0,8,'S1','S1')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `is_selectable`=VALUES(`is_selectable`);

INSERT INTO `tst_tags` (`code`,`name`,`description`,`created_by`) VALUES
('smoke','Smoke','Part of the smoke set','S1'),
('critical-path','Critical Path','Covers a business-critical path','S1'),
('slow','Slow','Long-running; consider excluding from quick runs','S1'),
('data-heavy','Data Heavy','Requires substantial test data','S1'),
('tenancy','Tenancy','Verifies multi-tenant isolation','S1'),
('permission','Permission','Verifies role or permission behaviour','S1'),
('needs-review','Needs Review','Flagged for human review','S1')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.6 Which master feeds which UI field
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_master_registry` (`target_table`,`target_column`,`master_table`,`label`) VALUES
('tst_test_cases','test_case_type_code','tst_test_case_types','Test Case Type'),
('tst_test_cases','test_method_code','tst_testing_methods','Testing Method'),
('tst_test_cases','test_technology_code','tst_testing_technologies','Testing Technology'),
('tst_test_cases','test_layer_code','tst_testing_layers','Testing Layer'),
('tst_test_cases','status_code','tst_test_case_statuses','Test Case Status'),
('tst_users','primary_role_code','tst_roles','Role')
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.7 Application settings
--     is_local_only = 1 means the value never travels in a catalog bundle.
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_app_settings`
(`ordinal`,`group_name`,`key`,`value`,`value_type`,`description`,`is_system`,`is_local_only`,`is_editable`)
VALUES
-- Deployment
( 1,'Deployment','central_mode','false','BOOLEAN','True when this database is the central aggregation database.',1,1,1),
( 2,'Deployment','machine_id','0','INTEGER','This installation''s centrally issued machine id. Must be set before any run is recorded.',1,1,0),
( 3,'Deployment','schema_version','7.0.0','STRING','Schema version of this installation. Written by migrations.',1,1,0),
( 4,'Deployment','app_version','1.0.0','STRING','Testing Application version.',1,1,0),
( 5,'Deployment','prime_ai_repo_path','','STRING','Absolute path to the Prime-AI source tree. Read-only access.',1,1,1),
( 6,'Deployment','evidence_root_path','','STRING','Absolute path to the evidence store.',1,1,1),

-- Catalog
(10,'Catalog','test_case_authoring_mode','Central_Catalog','STRING','Central_Catalog or Local_Then_Promote. See BRD D-01.',1,0,1),
(11,'Catalog','test_case_code_block_size','100','INTEGER','Test case numbers allocated to a machine per screen.',1,0,1),
(12,'Catalog','discovery_auto_confirm','false','BOOLEAN','Confirm discovered items automatically. Off by default (BR-DISC-04).',1,0,1),
(13,'Catalog','discovery_protect_edited_names','true','BOOLEAN','Never overwrite a human-edited display name (BR-DISC-02).',1,0,1),

-- Execution
(20,'Execution','max_concurrent_runs_per_machine','1','INTEGER','Browser-based runs interfere with one another; keep at 1 unless isolated.',1,1,1),
(21,'Execution','run_heartbeat_interval_seconds','15','INTEGER','How often a running execution reports that it is alive.',1,1,1),
(22,'Execution','run_heartbeat_timeout_seconds','180','INTEGER','After this, the watchdog marks a run Interrupted (BR-EXEC-07).',1,1,1),
(23,'Execution','max_run_duration_minutes','240','INTEGER','After this, a run is marked Timed_Out.',1,1,1),
(24,'Execution','auto_retry_on_failure','0','INTEGER','In-run automatic retries. 0 disables; each retry is a new attempt, never an overwrite.',1,0,1),

-- Defects
(30,'Defects','auto_bug_creation_enabled','false','BOOLEAN','Off by default. Propose in the triage queue instead: automatic creation produced most of the duplicate-bug problem it was meant to solve (Solution Design OD-05).',1,0,1),
(31,'Defects','auto_retest_enabled','true','BOOLEAN','Trigger a retest cycle when a bug is marked Fixed.',1,0,1),
(32,'Defects','max_auto_retest_attempts','5','INTEGER','Beyond this the bug is escalated, not retried (BR-RETEST-05).',1,0,1),
(33,'Defects','default_retest_scope','Screen_Plus_Dependencies','STRING','Test_Only, Screen, Screen_Plus_Dependencies, Module or Regression_Suite (BRD D-10).',1,0,1),
(34,'Defects','bug_sla_hours_critical','8','INTEGER','SLA from assignment to fix, Critical severity.',1,0,1),
(35,'Defects','bug_sla_hours_high','24','INTEGER','SLA from assignment to fix, High severity.',1,0,1),
(36,'Defects','bug_sla_hours_default','48','INTEGER','SLA from assignment to fix, other severities.',1,0,1),
(37,'Defects','require_retest_before_close','true','BOOLEAN','Fixed -> Closed requires a passing retest, or an authorised override with a reason (R-08).',1,0,1),
(38,'Defects','bug_duplicate_propose_threshold','0.80','DECIMAL','Score at or above which a duplicate is proposed for review.',1,0,1),

-- Analysis
(40,'Analysis','flaky_window_runs','10','INTEGER','Executions examined when assessing flakiness (BRD D-11).',1,0,1),
(41,'Analysis','flaky_min_alternations','2','INTEGER','Outcome alternations within the window to raise a candidate.',1,0,1),
(42,'Analysis','flaky_auto_confirm_days','14','INTEGER','Candidacy persisting this long is auto-confirmed, and recorded as such.',1,0,1),
(43,'Analysis','regression_lookback_days','30','INTEGER','A prior pass within this window makes a failure a regression candidate (BRD D-12).',1,0,1),
(44,'Analysis','stale_test_days','90','INTEGER','Not executed for this long counts as testing debt.',1,0,1),
(45,'Analysis','impact_max_depth','2','INTEGER','Dependency traversal depth for impact analysis.',1,0,1),
(46,'Analysis','impact_min_confidence','0.30','DECIMAL','Proposals below this confidence are excluded by default.',1,0,1),
(47,'Analysis','regression_policy_suite','','STRING','Suite always added to an impact-based run. Empty disables.',1,0,1),
(48,'Analysis','analytics_rebuild_check_enabled','true','BOOLEAN','Nightly comparison of incremental analytics against a full rebuild (R-13).',1,0,1),

-- Sync
(50,'Sync','allow_multi_machine_import','true','BOOLEAN','Accept evidence bundles from registered machines.',1,0,1),
(51,'Sync','import_accept_prior_minor_version','true','BOOLEAN','Migrate one prior minor schema version on read; otherwise refuse (BRD D-21).',1,0,1),
(52,'Sync','import_reversal_window_hours','72','INTEGER','How long a completed import may still be reversed.',1,0,1),
(53,'Sync','export_include_artifacts','true','BOOLEAN','Include evidence files in an export bundle.',1,1,1),
(54,'Sync','export_max_artifact_mb','25','INTEGER','Artefacts larger than this stay local and are referenced, not shipped.',1,1,1),

-- Retention
(60,'Retention','retain_artifacts_days','180','INTEGER','Evidence artefacts. Never purged while linked to an open bug or unclosed release.',1,0,1),
(61,'Retention','retain_raw_output_days','90','INTEGER','Raw execution output.',1,0,1),
(62,'Retention','retain_audit_days','1095','INTEGER','Audit log, three years.',1,0,1),
(63,'Retention','retain_notifications_days','180','INTEGER','Read notifications only.',1,0,1),
(64,'Retention','retain_discovery_logs_days','365','INTEGER','Discovery and sync logs.',1,0,1),
(65,'Retention','purge_requires_preview','true','BOOLEAN','A purge must display counts by class before removing anything (AC-RET-01).',1,0,0),

-- Notifications
(70,'Notifications','notification_dedupe_window_hours','24','INTEGER','Repeat events inside this window increment a count instead of creating a row.',1,0,1),
(71,'Notifications','email_enabled','false','BOOLEAN','Send notifications by email in addition to in-app.',1,1,1),
(72,'Notifications','digest_enabled','true','BOOLEAN','Send the per-role daily digest.',1,0,1),

-- AI
(80,'AI','ai_enabled','false','BOOLEAN','Enable AI-assisted analysis.',1,0,1),
(81,'AI','ai_provider','anthropic','STRING','AI provider.',1,0,1),
(82,'AI','ai_model','claude-opus-5','STRING','Model identifier.',1,0,1),
(83,'AI','ai_max_tokens_per_analysis','16000','INTEGER','Per-analysis token cap.',1,0,1),
(84,'AI','ai_min_confidence_to_propose','0.60','DECIMAL','Recommendations below this are not shown.',1,0,1),
(85,'AI','ai_scrub_tenant_data','true','BOOLEAN','Strip tenant, personal and secret data from every payload (BR-AI-08).',1,0,0),
(86,'AI','ai_demote_below_acceptance_rate','0.50','DECIMAL','A recommendation type below this over 30 reviews becomes advisory only.',1,0,1)
ON DUPLICATE KEY UPDATE
    `value`=VALUES(`value`),
    `value_type`=VALUES(`value_type`),
    `group_name`=VALUES(`group_name`),
    `description`=VALUES(`description`);


-- ---------------------------------------------------------------------------------------------------------
-- 19.8 Schema version
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_schema_version` (`version`,`applied_by`,`notes`) VALUES
('7.0.0','S1','Initial v7.0 schema. Supersedes v6.7: corrects 12 defects, introduces surrogate-key joins with business-code identity, the source/canonical test case model, manual test steps, environment profiles, evidence artefacts, failure signatures, impact analysis, known issues, releases, import conflict handling, AI recommendations and notifications.')
ON DUPLICATE KEY UPDATE `notes`=VALUES(`notes`);


SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================================================================
-- POST-INSTALL CHECKLIST
-- =========================================================================================================
--   1. Replace every $2y$12$REPLACE_THIS_PLACEHOLDER_HASH_* value with a real password hash.
--   2. Set tst_app_settings.machine_id to the id issued centrally for THIS installation, and insert the
--      corresponding tst_machines row WITH AN EXPLICIT id. Never let it auto-increment locally.
--   3. Set prime_ai_repo_path and evidence_root_path.
--   4. Set central_mode = true on the central installation only.
--   5. Register the Prime-AI repository in tst_git_repositories.
--   6. Seed tst_path_mappings from the module folder convention before running the first impact analysis;
--      until then every changed file resolves as Unresolved and impact analysis has no basis to work from.
--   7. Load the catalog: modules, categories, menus, screens. Then run discovery.
--   8. Verify with:
--        SELECT COUNT(*) FROM information_schema.tables
--         WHERE table_schema = DATABASE() AND table_name LIKE 'tst_%';        -- expect 71
--        SELECT COUNT(*) FROM information_schema.views
--         WHERE table_schema = DATABASE() AND table_name LIKE 'vw_%';         -- expect 20
--        SELECT COUNT(*) FROM information_schema.table_constraints
--         WHERE table_schema = DATABASE() AND constraint_type = 'FOREIGN KEY'; -- expect 273
--
-- =========================================================================================================
-- END OF SCHEMA v7.0
-- =========================================================================================================
