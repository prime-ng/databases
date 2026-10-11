-- =========================================================================================================
-- Prime-AI Testing Application — Database Schema
-- =========================================================================================================
-- Project       : prime_testing
-- File          : testing_DDL_v7.2.sql
-- Version       : 7.2
-- Date          : 2026-09-08
-- Supersedes    : testing_DDL_v7.1.sql  (owner revision of v7.0)
-- Table prefix  : tst_*   (58 tables — 44 in Phase 1, 14 in Phase 2)
-- MySQL         : 8.0.16 or later   (CHECK constraints are only ENFORCED from 8.0.16)
-- Engine        : InnoDB / utf8mb4 / utf8mb4_unicode_ci
--
-- Governed by   : TestingApp_BRD_v3.md    (business requirement  — decides WHAT, and in which phase)
-- Designed in   : Solution_Design_v3.md   (solution design       — decides HOW)
-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
-- THIS FILE IS IN TWO PARTS
-- ---------------------------------------------------------------------------------------------------------
--     PHASE 1 — RECORD AND DIAGNOSE      Sections  1 .. 14      44 tables
--         A tester can plan, author, review, schedule, execute and evidence a test on their own machine;
--         a lead can read what happened, drive a bug to verified closure, and consolidate every machine's
--         evidence into one place.
--
--     PHASE 2 — CORRELATE AND SELECT     Sections 20 .. 31      14 tables
--         The application can say WHICH tests a change requires, because it knows what changed in Git,
--         which files map to which screens, what depends on what, and which tests are in which suite.
--
--     Phase 1 runs on its own. Stop after Section 14 and you have a complete, installable system.
--     See "THE PHASE RULE" below for how that is guaranteed.
--
-- ---------------------------------------------------------------------------------------------------------
-- THE CODING SYSTEM  —  the single most important thing in this schema
-- ---------------------------------------------------------------------------------------------------------
--     v7.0 used a surrogate integer as the relational key and carried a business code alongside for
--     recognition on import. v7.1 replaced that with a SELF-DESCRIBING COMPOSITE CODE. v7.2 completes
--     that change across every table.
--
--         user_code        VARCHAR(3)     D02                     role letter + 2 digits
--         machine_number   ENUM('A'..'Z') A
--         machine_code     VARCHAR(4)     D02A                    GENERATED  user_code || machine_number
--
--         module_code      VARCHAR(5)     SLB
--         cat_code         VARCHAR(3)     T01
--         mm_code          VARCHAR(5)     T0104                   contains cat_code as a prefix
--         sm_code          VARCHAR(7)     T010401                 contains mm_code  as a prefix
--         ts_code          VARCHAR(11)    T0104010200             contains sm_code  as a prefix
--
--         tcr_code         VARCHAR(21)    D02A_T0104010200_0001   GENERATED
--                                         machine_code || '_' || ts_code || '_' || LPAD(tc_list_number,4,'0')
--         test_case_code   VARCHAR(21)    D02A_T0104010200_001    GENERATED
--                                         machine_code || '_' || ts_code || '_' || LPAD(tc_seq_number,3,'0')
--
--     TWO PROPERTIES DO ALL THE WORK
--
--       1. THE CATALOG CODES ARE POSITIONALLY NESTED.
--          T0104010200 IS a screen under T010401, under T0104, under T01. The hierarchy is readable from
--          the code, and is ALSO enforced by composite foreign keys, so the two can never disagree.
--
--       2. THE TEST CASE CODE EMBEDS THE AUTHORING MACHINE.
--          Two people authoring the same test on the same screen produce
--              D02A_T0104010200_001   and   T01A_T0104010200_001
--          Different codes. Both valid. Neither wrong. COLLISION IS STRUCTURALLY IMPOSSIBLE, with no
--          central number allocator and no UUID.
--
--     WHAT THIS REMOVES
--          - the id-to-code translation layer at every import boundary  (codes are identical everywhere)
--          - tst_source_test_cases and its entire reconciliation path   (see "REMOVED TABLES" below)
--          - tst_code_allocations                                       (the machine segment allocates)
--          - ambiguity in a log line: D02A_T0104010200_001 resolves without a database lookup
--
--     WHAT IT COSTS, HONESTLY
--          21 bytes per index entry instead of 4. On the 6,000,000-row results table that is roughly
--          100 MB of index, against artefacts occupying tens of gigabytes. At this scale the trade is
--          clearly worth it. At a hundred times this scale it would not be — BRD OPEN-05 records that.
--
-- ---------------------------------------------------------------------------------------------------------
-- WHAT MySQL FORCES ON US  —  read this before changing any foreign key in this file
-- ---------------------------------------------------------------------------------------------------------
--     These are not preferences. The generated-column design makes them mandatory.
--
--       MC-1  A foreign key CANNOT reference a VIRTUAL generated column.
--             -> machine_code, tcr_code and test_case_code are all declared STORED.
--
--       MC-2  A foreign key ON A BASE COLUMN of a stored generated column cannot use CASCADE, SET NULL
--             or SET DEFAULT for ON UPDATE or ON DELETE.
--             -> tst_test_cases.machine_code, tst_test_cases.ts_code and tst_machines.owner_user_code
--                are ON DELETE RESTRICT. They cannot be anything else. Do not "tidy" them.
--
--       MC-3  Following MC-2, ON UPDATE CASCADE is IMPOSSIBLE on any code that feeds a generated column.
--             -> THERE IS NO MECHANISM BY WHICH A RENAME COULD PROPAGATE.
--                This is why "a business code is permanent" (BRD R-17) is a rule and not a guideline:
--                the database will not let anyone break it, including a data-fix script at 2am.
--                The correct operation is always: deactivate, create new, record the relationship.
--
--       MC-4  A generated column's expression must be deterministic.
--             -> The codes are pure CONCAT and LPAD. No NOW(), no session state.
--
--       MC-5  The referenced side of a foreign key must be a UNIQUE index.
--             -> uq_tst_machines_code, uq_tst_tcRequired_code, uq_tst_testCases_tcCode.
--
--       MC-6  Both sides of a string foreign key must share a character set and collation, and differing
--             VARCHAR lengths are ACCEPTED BY MySQL — which is worse than being rejected, because the
--             constraint is created, the index is unusable for the intended lookups, and a value can be
--             silently truncated on insert into the narrower side.
--             -> EVERY declaration of a given code in this file has an IDENTICAL width. See corrections
--                9 to 12 below for what v7.1 looked like before this was fixed.
--
-- ---------------------------------------------------------------------------------------------------------
-- THE PHASE RULE  (Solution_Design_v3 SD-01, SD-02)
-- ---------------------------------------------------------------------------------------------------------
--     A PHASE-1 TABLE NEVER CARRIES A FOREIGN KEY TO A PHASE-2 TABLE.
--
--     Five Phase-1 tables hold columns that will later point at Phase-2 entities:
--         tst_test_runs        . suite_id, suite_version_no, impact_analysis_id
--         tst_test_run_scopes  . suite_id, change_request_id
--         tst_bugs             . change_request_id
--
--     THE COLUMNS ARE DECLARED IN PHASE 1 AND LEFT NULL.
--     THE FOREIGN KEYS ARE ADDED BY SECTION 30, IN PHASE 2.
--
--     The reason is operational. By the time Phase 2 ships, tst_test_run_results holds millions of rows.
--     ADD COLUMN is cheap; ADD CONSTRAINT requires an index build and a metadata lock. Declaring the
--     column now turns a Phase-2 upgrade into a constraint addition rather than a table rewrite.
--
--     Phase 2 therefore contains CREATE TABLE, ALTER TABLE ... ADD CONSTRAINT, CREATE OR REPLACE VIEW
--     and INSERT. It contains no ADD COLUMN, no MODIFY COLUMN and no DROP.
--
-- ---------------------------------------------------------------------------------------------------------
-- TABLES REMOVED SINCE v7.0  (owner decisions, plus two that the coding system made redundant)
-- ---------------------------------------------------------------------------------------------------------
--     tst_roles, tst_permissions, tst_role_permissions, tst_user_roles
--         Removed by the owner (BRD D-25). Four tables of matrix administration for a team where
--         everyone does everything. A single `role` enum on tst_users replaces them, plus an ownership
--         check in the policy layer. Revisit above ~15 users or on the first external contractor.
--
--     tst_releases
--         Removed by the owner (BRD D-26). The unit of release here is the TEST CASE, not a named
--         delivery, and tst_test_case_review carries the readiness score, the technical review and the
--         sign-off. "Release" survives only as a descriptive run-trigger label with no entity behind it.
--
--     tst_code_allocations
--         Removed. Its job was to hand out unique test-case numbers across machines. The machine segment
--         of the code now does that, without a central service that has to be reachable.
--
--     tst_source_test_cases                              <-- the owner asked: "is this table required?"
--         REMOVED. It is not, and this is the largest simplification in v7.2.
--
--         WHAT IT SOLVED. Under v7.0 a test case's identity was screen + sequence. Two machines authoring
--         independently would BOTH mint T0104010200/001. Importing one into the other would either
--         collide or silently merge two different tests. This table held the incoming one in quarantine
--         until a human decided whether it was the same test.
--
--         WHY THE PROBLEM IS GONE. The codes are now D02A_T0104010200_001 and T01A_T0104010200_001.
--         Both import cleanly into tst_test_cases. Neither is ambiguous, so neither needs quarantine.
--
--         WHAT REPLACES THE JUDGEMENT. The judgement was never about IDENTITY — it was about
--         EQUIVALENCE, which is a different question, and it belongs in tst_duplicate_test_case
--         (Proposed_Equivalent / Confirmed_Equivalent / Confirmed_Different / Duplicate_Of / Variant_Of /
--         Supersedes), insert-only, so the decision history survives.
--
--         NET EFFECT: one table removed, plus source_test_case_id and a CHECK constraint removed from
--         tst_test_run_items, plus an entire reconciliation path removed from the import service.
--
--     tst_schema_version                                 <-- the owner wrote: "I feel this is not required"
--         REMOVED, and the owner is right. Three mechanisms already record this fact:
--             1. Laravel's own `migrations` table holds the applied history;
--             2. tst_app_settings holds the current version as the key 'schema_version';
--             3. tst_data_exports.schema_version travels in every bundle and is what the importer
--                actually compares against.
--         Two mechanisms recording the same fact will eventually disagree, and the one that disagrees
--         is always the one nobody is watching.
--
--     tst_tags, tst_test_case_tags, tst_test_case_types, tst_test_case_statuses,
--     tst_testing_layers, tst_testing_methods, tst_testing_technologies, tst_master_registry
--         Removed by the owner. Each was a lookup table with a handful of fixed rows; they are now
--         ENUMs on tst_test_cases. A join to read "Dusk" is not worth a table.
--
--     tst_test_case_links, tst_test_case_versions
--         Renamed by the owner to tst_duplicate_test_case and tst_test_case_versions_history, which
--         say what they hold.
--
-- ---------------------------------------------------------------------------------------------------------
-- TABLES ADDED SINCE v7.0
-- ---------------------------------------------------------------------------------------------------------
--     tst_tc_required_list        [P1] The TcList as a TABLE, not a markdown file. Coverage needs a
--                                      denominator: "Fees is about half tested" is not a number;
--                                      "214 required, 168 released" is.
--     tst_test_case_review        [P1] Review, readiness score, technical review, sign-off. Replaces
--                                      tst_releases.
--     tst_test_case_versions_history [P1] Immutable snapshot of a superseded definition.
--     tst_duplicate_test_case     [P1] The equivalence judgement, insert-only.
--     tst_schedule_targets        [P1] NEW IN v7.2. "Schedule execution on different machines for
--                                      different modules/screens/test cases" cannot be expressed by one
--                                      machine_id column on the schedule.
--
-- ---------------------------------------------------------------------------------------------------------
-- CORRECTIONS TO v7.1  —  8 of these prevent the script from executing
-- ---------------------------------------------------------------------------------------------------------
--      1. tst_app_settings declared INDEX (group_name, ordinal); group_name does not exist.  FATAL
--         -> group_name added. It was a good idea, just an undeclared one.
--      2. tst_users declared foreign keys on created_by / updated_by / deleted_by. None of the three
--         columns is declared.                                                              FATAL
--         -> Declared, nullable, self-referencing (the bootstrap row needs NULL).
--      3. tst_users declared INDEX (primary_role_code); the column does not exist.           FATAL
--         -> Indexed on `role`.
--      4. tst_tc_required_list declared UNIQUE KEY (tc_list_code); the column is tcr_code.   FATAL
--      5. tst_test_case_versions_history declared FOREIGN KEY (test_case_id); the column is
--         test_case_code.                                                                    FATAL
--      6. tst_test_runs declared a generated test_case_code built from `machine_code`, which the table
--         does not declare (it has run_machine_code).                                        FATAL
--         -> Removed. A RUN IS AN EVENT COVERING MANY TEST CASES; giving it one test-case code is a
--            category error. The per-case link lives in tst_test_run_items.test_case_code.
--      7. The deferred block added foreign keys to tst_releases and tst_roles, both removed.  FATAL
--      8. tst_source_test_cases and tst_schema_version were declared at the END of the file, after the
--         tables that reference them.                                                        FATAL
--         -> Both removed entirely; see above.
--      9. test_case_code was VARCHAR(21) on the parent and VARCHAR(20) on every child.
--     10. user_code and every *_by column: VARCHAR(3) in some tables, VARCHAR(10) in others.
--     11. ts_code: VARCHAR(11) in some tables, VARCHAR(20) in others.
--     12. module_code: VARCHAR(5) in some tables, VARCHAR(10) in others.
--         -> 9 to 12 are all broken foreign keys. See MC-6. Every code now has ONE width.
--     13. tst_tc_required_list had no foreign key on machine_code and none on its audit columns.
--     14. tst_bugs.module_code VARCHAR(10) against a VARCHAR(5) parent.
--     15. Every view joined tst_test_cases on tc.id. Under the new model the joining key is
--         test_case_code, and a view joining on id returns NOTHING after consolidation, because a
--         central id does not match a local one.  -> All views rewritten.
--     16. tst_test_case_review.version_no carries no foreign key. INTENTIONAL — see the note on that
--         table. Recorded here so nobody "fixes" it.
--
-- ---------------------------------------------------------------------------------------------------------
-- SECTIONS
-- ---------------------------------------------------------------------------------------------------------
--     PHASE 1
--        1  Platform: application settings, environment profiles
--        2  Identity: users, machines
--        3  Catalog: module -> category -> main menu -> sub menu -> tab/screen
--        4  Authoring: TcList, test cases, steps, review, version history, duplicates
--        5  Execution: runs, scopes, items, results, steps, artefacts, signatures, summary
--        6  Scheduling: schedules, targets
--        7  Comments and discovery
--        8  Defects: known issues, bugs, occurrences, history, comments, links, retests
--        9  Export, import, record map, conflicts
--       10  AI analyses and recommendations
--       11  Notifications and audit
--       12  Phase-1 deferred constraints
--       13  Phase-1 views
--       14  Phase-1 seed data
--
--     PHASE 2
--       20  Change requests and the test-case work backlog
--       21  Dependencies
--       22  Application path mapping
--       23  Test suites
--       24  Git ingestion
--       25  Impact analysis
--       30  Phase-2 deferred constraints  (this is where the Phase-1 columns get their foreign keys)
--       31  Phase-2 views
-- =========================================================================================================

SET NAMES utf8mb4;
SET SESSION sql_require_primary_key = 0;
SET FOREIGN_KEY_CHECKS = 0;


-- #########################################################################################################
-- #                                                                                                       #
-- #                        P H A S E   1   —   R E C O R D   A N D   D I A G N O S E                      #
-- #                                                                                                       #
-- #########################################################################################################


-- =========================================================================================================
-- SECTION 1 — PLATFORM: APPLICATION SETTINGS AND ENVIRONMENT PROFILES                              [P1]
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_app_settings  —  Application Configuration                                                    [P1]
-- ---------------------------------------------------------------------------------------------------------
-- Typed key/value configuration, so a setting's meaning is discoverable without reading code.
--
-- THE THREE FLAGS ARE THE WHOLE DESIGN:
--   is_system      shipped with the application; a user may not delete it
--   is_local_only  NEVER travels in a catalog bundle. Paths, machine specifics and credentials stay on
--                  the machine they describe. Exporting a local path to another machine is how you get
--                  an installation that reads evidence from a directory that does not exist there.
--   is_editable    a user may change the value. 0 means changing it is a code change.
--
-- v7.2: `group_name` declared. v7.1 indexed it without declaring it, which made CREATE TABLE fail.
-- v7.2: 'schema_version' is seeded here, replacing the tst_schema_version table (BRD D-27).
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_app_settings` (
   `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `group_name`     VARCHAR(50)  NOT NULL DEFAULT 'General',  -- v7.2: declared; v7.1 indexed it undeclared
   `ordinal`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `key`            VARCHAR(100) NOT NULL,
   `value`          VARCHAR(1000) NOT NULL,
   `value_type`     ENUM('STRING','INTEGER','DECIMAL','BOOLEAN','DATE','TIME','DATETIME','JSON') NOT NULL DEFAULT 'STRING',
   `description`    VARCHAR(500) NULL,
   `is_system`      TINYINT(1) NOT NULL DEFAULT 0,
   `is_local_only`  TINYINT(1) NOT NULL DEFAULT 0,
   `is_editable`    TINYINT(1) NOT NULL DEFAULT 1,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`     TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_appSettings_key` (`key`),
   INDEX `idx_tst_appSettings_group` (`group_name`,`ordinal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Typed application configuration. is_local_only never leaves this machine.';
-- Import / Export:
--   1. Maintained by the SuperAdmin only; distributed to other machines by seeder.
--   2. The seeder omits every row where is_local_only = 1.
--   3. A local user may change the value only where is_editable = 1.


-- ---------------------------------------------------------------------------------------------------------
-- tst_environment_profiles  —  Machine Environment Profile                                          [P1]
-- ---------------------------------------------------------------------------------------------------------
-- An environment is identified by a REPEATABLE FINGERPRINT over its material attributes, not by free text.
--
-- WHY THIS MATTERS MORE THAN IT SOUNDS.
--   "It fails on my machine" is the single most expensive sentence in testing. This table turns it into
--   "it fails on Windows with Chrome 141 and passes on Chrome 140", which is a fixable statement. A
--   result that cannot be compared to another result IN THE SAME ENVIRONMENT is not evidence of a
--   regression (BRD BR-ENV-04).
--
-- NEVER EXPORTED OR IMPORTED (Solution_Design_v3 SD-15). A fingerprint recomputes identically on any
-- machine, so importing profiles would only create duplicates that differ by id.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_environment_profiles` (
   `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `env_fingerprint`   CHAR(64) NOT NULL     COMMENT 'sha256 over the normalised material attributes below',
   `env_name`          VARCHAR(150) NULL     COMMENT 'A friendly label, assigned once the profile is recognised',
   `env_type`          ENUM('Local','CI','Staging','Production_Like','Other') NOT NULL DEFAULT 'Local',
   `os_name`           VARCHAR(80)  NULL     COMMENT 'Windows 10, Ubuntu 24.04, macOS Ventura',
   `os_version`        VARCHAR(120) NULL,
   `php_version`       VARCHAR(30)  NULL     COMMENT '8.2.4',
   `laravel_version`   VARCHAR(30)  NULL     COMMENT '10.35.5',
   `database_engine`   VARCHAR(50)  NULL     COMMENT 'MySQL, MariaDB',
   `database_version`  VARCHAR(50)  NULL     COMMENT '8.0.38',
   `browser_name`      VARCHAR(50)  NULL     COMMENT 'Chrome, Firefox, Safari, Edge',
   `browser_version`   VARCHAR(50)  NULL     COMMENT '141',
   `driver_version`    VARCHAR(50)  NULL     COMMENT 'ChromeDriver 141.0.5524.12',
   `app_env`           ENUM('Local','Testing','Staging') NULL,
   `app_version`       VARCHAR(30)  NULL,
   `config_profile`    VARCHAR(100) NULL,
   `attributes_json`   JSON NULL             COMMENT 'Anything else captured, outside the fingerprint',
   `first_seen_at`     DATETIME NULL,
   `last_seen_at`      DATETIME NULL,
   `run_count`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
   `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_env_fingerprint` (`env_fingerprint`),
   INDEX `idx_tst_env_type`    (`env_type`),
   INDEX `idx_tst_env_browser` (`browser_name`,`browser_version`),
   INDEX `idx_tst_env_os`      (`os_name`,`os_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Environment identified by fingerprint. Never exported or imported (SD-15).';


-- =========================================================================================================
-- SECTION 2 — IDENTITY: USERS AND MACHINES                                                          [P1]
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_users  —  User Profile Management                                                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- THE USER CODE IS THE PRIMARY KEY, and it appears in every created_by / updated_by / deleted_by column,
-- inside every machine code, and therefore inside every test case code.
--
--     Format: role letter + two digits
--             A01  Architect     Q01  QA Lead     T01  Tester
--             D02  Developer     R01  Reviewer    S01  System
--
-- NO ROLES OR PERMISSIONS TABLES (BRD D-25). The `role` enum plus an ownership check in the policy layer
-- replaces four tables of matrix administration for a team where everyone does everything.
--
-- A USER CODE IS NEVER REISSUED TO A DIFFERENT PERSON. It is embedded in every test case that person
-- authored, and MC-3 means it cannot be renamed. A user is deactivated, never deleted.
--
-- v7.2: created_by / updated_by / deleted_by DECLARED. v7.1 had foreign keys on all three and declared
--       none of them, which made CREATE TABLE fail. They are nullable because the very first row has
--       nobody to attribute itself to.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_users` (
   `code`           VARCHAR(3)   NOT NULL   COMMENT 'Role letter + 2 digits, e.g. D02. THE primary key',
   `name`           VARCHAR(100) NOT NULL,
   `email`          VARCHAR(150) NOT NULL,
   `password`       VARCHAR(512) NOT NULL,
   `role`           ENUM('Architect','QA_Lead','Tester','Developer','Reviewer','System') NOT NULL DEFAULT 'Tester',
   `is_superuser`   TINYINT(1) NOT NULL DEFAULT 0,
   `is_system`      TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'Scheduler, importer, retest engine — so automation is attributable',
   `is_active`      TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`     VARCHAR(3) NULL,  -- v7.2: declared. Nullable for the bootstrap row
   `updated_by`     VARCHAR(3) NULL,  -- v7.2: declared
   `deleted_by`     VARCHAR(3) NULL,  -- v7.2: declared
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`     TIMESTAMP NULL,
   PRIMARY KEY (`code`),
   UNIQUE KEY `uq_tst_users_email` (`email`),
   INDEX `idx_tst_users_active` (`is_active`),
   INDEX `idx_tst_users_role`   (`role`),      -- v7.2: was on the undeclared primary_role_code
   CONSTRAINT `fk_tst_users_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_users_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_users_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Users. The code is the primary key and is embedded in every machine and test case code.';
-- Import / Export:
--   1. Created centrally by the SuperAdmin; distributed to other machines by seeder.
--   2. A local user may change only their own password.


-- ---------------------------------------------------------------------------------------------------------
-- tst_machines  —  Machine Profile for every user                                                   [P1]
-- ---------------------------------------------------------------------------------------------------------
-- machine_code = owner_user_code || machine_number.  D02A is Tarun's first machine, D02B his second.
-- Four characters that identify AN INSTALLATION AND ITS OWNER in one token.
--
-- WHY THE MACHINE PROFILE EARNS ITS PLACE (BRD BR-MACH-07):
--   It is what separates "the application is broken" from "your machine is different". A failure on
--   D02A that passes on T01A with a different browser version is an ENVIRONMENT FINDING, not a defect,
--   and without this table nobody can tell the two apart.
--
-- MC-2 APPLIES HERE. owner_user_code is a base column of the generated machine_code, so its foreign key
--   is ON DELETE RESTRICT and CANNOT be anything else. A machine is retired, never deleted, and a
--   machine is never reassigned to another user — D02A means "Tarun's first machine" permanently.
--
-- ID ASSIGNMENT: ids are issued CENTRALLY and inserted EXPLICITLY on the local machine. Never let a
--   local database auto-increment its own machine id, or every machine becomes id 1 and all consolidated
--   evidence collides.  id = 1 is the central installation; local machines start at 10.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_machines` (
   `id`                  SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT  COMMENT 'Issued centrally; inserted explicitly',
   `owner_user_code`     VARCHAR(3) NOT NULL   COMMENT 'FK tst_users.code — base column of machine_code, so RESTRICT only',
   `machine_number`      ENUM('A','B','C','D','E','F','G','H','I','J','K','L','M',
                              'N','O','P','Q','R','S','T','U','V','W','X','Y','Z') NOT NULL,
   `machine_code`        VARCHAR(4) GENERATED ALWAYS AS (CONCAT(`owner_user_code`,`machine_number`)) STORED
                                             COMMENT 'D02A. STORED because MC-1 forbids a FK to a virtual column',
   -- ---- The 11 fields a local user may edit. Everything else is administrator-controlled -----------------
   `machine_name`        VARCHAR(150) NOT NULL,
   `machine_model`       VARCHAR(150) NULL,
   `os_name`             VARCHAR(80)  NULL,
   `os_version`          VARCHAR(120) NULL,
   `architecture`        VARCHAR(30)  NULL,
   `hostname`            VARCHAR(150) NULL,
   `hardware_serial`     VARCHAR(150) NULL,
   `app_version`         VARCHAR(20)  NULL,
   `schema_version`      VARCHAR(20)  NULL,
   `prime_ai_repo_path`  VARCHAR(1000) NULL   COMMENT 'Where the Prime-AI source lives on this machine',
   `evidence_root_path`  VARCHAR(1000) NULL   COMMENT 'Where test evidence is stored on this machine',
   -- ---- Administrator-controlled ------------------------------------------------------------------------
   `machine_fingerprint` CHAR(64) NULL        COMMENT 'sha256(hostname + os + serial + install path), re-checked at boot',
   `is_central`          TINYINT(1) NOT NULL DEFAULT 0,
   `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
   `registration_status` ENUM('Registered','Pending','Suspended','Retired') NOT NULL DEFAULT 'Registered',
   `first_seen_at`       DATETIME NULL,
   `last_seen_at`        DATETIME NULL,
   `retired_at`          DATETIME NULL,
   `registered_by`       VARCHAR(3) NOT NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`          TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_machines_code`  (`machine_code`),   -- MC-5: parent key of every machine_code FK
   UNIQUE KEY `uq_tst_machines_owner` (`owner_user_code`,`machine_number`),
   INDEX `idx_tst_machines_active`   (`is_active`,`registration_status`),
   INDEX `idx_tst_machines_hostname` (`hostname`),
   CONSTRAINT `fk_tst_machines_owner`        FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_machines_registeredBy` FOREIGN KEY (`registered_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registered installations. machine_code = owner + letter. Ids issued centrally.';
-- Import / Export:
--   1. All rows are created centrally by the SuperAdmin; distributed by seeder.
--   2. A local user may edit only the 11 profile fields marked above.
--   3. A retired machine_code is NEVER reissued — a reused code silently merges two machines' evidence,
--      which is why the importer classifies a duplicate business code as BLOCKING (BRD D-31).


-- =========================================================================================================
-- SECTION 3 — CATALOG: MODULE -> CATEGORY -> MAIN MENU -> SUB MENU -> TAB/SCREEN                    [P1]
-- =========================================================================================================
--     PARENTAGE IS ENFORCED TWICE, ON PURPOSE:
--
--       1. BY PREFIX.  mm_code begins with cat_code; sm_code begins with mm_code; ts_code begins with
--          sm_code where one exists. Validated by CatalogService on write. Human-readable.
--
--       2. BY COMPOSITE FOREIGN KEY.  tst_main_menus(module_code, cat_code) references
--          tst_categories(module_code, cat_code). Machine-enforced.
--
--     Neither alone is sufficient. A prefix can be typed wrong; a composite key would happily accept
--     T0104 under T02 as long as both rows agreed. v6.7 referenced cat_code ALONE, which allowed a main
--     menu to belong to a category in a different module and silently corrupted the hierarchy.
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_modules` (
   `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `module_code`     VARCHAR(5)  NOT NULL   COMMENT 'SLB, SCH, FIN, EXM ...',
   `name`            VARCHAR(60) NOT NULL,
   `description`     VARCHAR(500) NULL,
   `folder_name`     VARCHAR(120) NULL      COMMENT 'e.g. Modules/Fees in the Prime-AI tree',
   `owner_user_code` VARCHAR(3)  NULL,
   `criticality`     ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `sort_order`      SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `version`         INT UNSIGNED NOT NULL DEFAULT 0,
   `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`      VARCHAR(3) NOT NULL,
   `updated_by`      VARCHAR(3) NOT NULL,
   `deleted_by`      VARCHAR(3) NULL,
   `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`      TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_modules_code` (`module_code`),
   INDEX `idx_tst_modules_active`      (`is_active`),
   INDEX `idx_tst_modules_criticality` (`criticality`),
   CONSTRAINT `fk_tst_modules_owner`     FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_modules_createdBy` FOREIGN KEY (`created_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_modules_updatedBy` FOREIGN KEY (`updated_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_modules_deletedBy` FOREIGN KEY (`deleted_by`)      REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Top-level Prime-AI functional areas. Centrally governed.';


CREATE TABLE IF NOT EXISTS `tst_categories` (
   `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `module_code`  VARCHAR(5) NOT NULL,
   `cat_code`     VARCHAR(3) NOT NULL   COMMENT 'T01, T02 ... the ROOT of every code beneath it',
   `name`         VARCHAR(60) NOT NULL,
   `description`  VARCHAR(500) NULL,
   `sort_order`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`   VARCHAR(3) NOT NULL,
   `updated_by`   VARCHAR(3) NOT NULL,
   `deleted_by`   VARCHAR(3) NULL,
   `created_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`   TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_categories_code`       (`cat_code`),
   UNIQUE KEY `uq_tst_categories_moduleCat`  (`module_code`,`cat_code`),  -- parent key of the composite FK below
   UNIQUE KEY `uq_tst_categories_moduleName` (`module_code`,`name`),
   CONSTRAINT `fk_tst_categories_module`    FOREIGN KEY (`module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_categories_createdBy` FOREIGN KEY (`created_by`)  REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_categories_updatedBy` FOREIGN KEY (`updated_by`)  REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_categories_deletedBy` FOREIGN KEY (`deleted_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Groupings within a module. cat_code is the prefix of every code below it.';


CREATE TABLE IF NOT EXISTS `tst_main_menus` (
   `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `module_code`  VARCHAR(5) NOT NULL,
   `cat_code`     VARCHAR(3) NOT NULL,
   `mm_code`      VARCHAR(5) NOT NULL   COMMENT 'T0104 — cat_code + 2. Prefix-nested by construction',
   `name`         VARCHAR(60) NOT NULL,
   `route_url`    VARCHAR(500) NULL,
   `sort_order`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`   VARCHAR(3) NOT NULL,
   `updated_by`   VARCHAR(3) NOT NULL,
   `deleted_by`   VARCHAR(3) NULL,
   `created_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`   TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_mainMenus_code`   (`mm_code`),
   UNIQUE KEY `uq_tst_mainMenus_parent` (`module_code`,`cat_code`,`mm_code`),  -- parent key for children
   CONSTRAINT `fk_tst_mainMenus_category`  FOREIGN KEY (`module_code`,`cat_code`)
                                           REFERENCES `tst_categories`(`module_code`,`cat_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_mainMenus_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_mainMenus_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_mainMenus_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Main menus. Composite FK stops a menu belonging to a category in another module.';


CREATE TABLE IF NOT EXISTS `tst_sub_menus` (
   `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `module_code`  VARCHAR(5) NOT NULL,
   `cat_code`     VARCHAR(3) NOT NULL,
   `mm_code`      VARCHAR(5) NOT NULL,
   `sm_code`      VARCHAR(7) NOT NULL   COMMENT 'T010401 — mm_code + 2',
   `name`         VARCHAR(60) NOT NULL,
   `route_url`    VARCHAR(500) NULL,
   `sort_order`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`   VARCHAR(3) NOT NULL,
   `updated_by`   VARCHAR(3) NOT NULL,
   `deleted_by`   VARCHAR(3) NULL,
   `created_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`   TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_subMenus_code`   (`sm_code`),
   UNIQUE KEY `uq_tst_subMenus_parent` (`module_code`,`cat_code`,`mm_code`,`sm_code`),
   CONSTRAINT `fk_tst_subMenus_mainMenu`  FOREIGN KEY (`module_code`,`cat_code`,`mm_code`)
                                          REFERENCES `tst_main_menus`(`module_code`,`cat_code`,`mm_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_subMenus_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_subMenus_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_subMenus_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Optional navigation level between main menu and screen.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_tabs_screens  —  the smallest addressable, testable surface of Prime-AI                       [P1]
-- ---------------------------------------------------------------------------------------------------------
-- ts_code (11 chars) is the anchor of the whole system: it is the middle segment of every test case code.
--
-- THE FIVE STATUS COLUMNS ARE THE PROJECT-MANAGEMENT VIEW OF TESTING. Together they let a QA Lead list
-- every screen whose development is complete and whose required test-case list has not been written:
--     requir_doc_status -> tc_list_status -> dev_status -> tc_creation_status -> test_run_status
--
-- sm_code IS NULLABLE. MySQL treats a composite foreign key containing a NULL as satisfied, so a screen
-- may hang directly off a main menu. The main-menu parentage is therefore a separate 3-column composite.
--
-- A SCREEN IS EXCLUDED, NEVER DELETED (BRD BR-CAT-06): is_excluded takes it out of the coverage
-- denominator, and the reason and the person who decided are recorded. Deleting it would make every
-- historical result that referenced it unreadable.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_tabs_screens` (
   `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `module_code`         VARCHAR(5)  NOT NULL,
   `cat_code`            VARCHAR(3)  NOT NULL,
   `mm_code`             VARCHAR(5)  NOT NULL,
   `sm_code`             VARCHAR(7)  NULL      COMMENT 'Nullable — a screen may hang off a main menu',
   `ts_code`             VARCHAR(11) NOT NULL  COMMENT 'T0104010200 — the anchor of every test_case_code',
   `name`                VARCHAR(100) NOT NULL,
   `description`         VARCHAR(1000) NULL,
   `route_url`           VARCHAR(500) NULL,
   `folder_path`         VARCHAR(500) NULL     COMMENT 'Source folder; used by path resolution in Phase 2',
   `criticality`         ENUM('View Only','View & Filter','Basic','Low','Medium','High','Critical','Duplicate')
                           NOT NULL DEFAULT 'Basic',
   `owner_user_code`     VARCHAR(3) NULL,
   -- ---- The authoring pipeline, one status per stage ----------------------------------------------------
   `requir_doc_md_path`  VARCHAR(1000) NULL,
   `requir_doc_status`   ENUM('Pending','In-Progress','In-Review','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
   `tc_list_md_path`     VARCHAR(1000) NULL,
   `tc_list_status`      ENUM('Pending','In-Progress','In-Review','Approved','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
   `dev_status`          ENUM('Pending','Under-Development','In-Review','Ready-For-Testing','Testing-InProgress','Testing-Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
   `tc_creation_status`  ENUM('Pending','In-Progress','Completed','Error','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
   `test_run_status`     ENUM('Not-Run','Partially-Run','Fully-Run','Failing','Blocked') NOT NULL DEFAULT 'Not-Run',
   -- ---- Exclusion from testing scope --------------------------------------------------------------------
   `is_excluded`         TINYINT(1) NOT NULL DEFAULT 0,
   `exclusion_reason`    VARCHAR(500) NULL,
   `excluded_by`         VARCHAR(3) NULL,
   `excluded_at`         DATETIME NULL,
   -- ---- Provenance --------------------------------------------------------------------------------------
   `finding_method`      ENUM('Manual','Discovery','Automated') NOT NULL DEFAULT 'Manual',
   `is_reviewed`         TINYINT(1) NOT NULL DEFAULT 1,
   `review_date`         DATETIME NULL,
   `reviewed_by`         VARCHAR(3) NULL,
   `review_comments`     VARCHAR(1000) NULL,
   `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`          VARCHAR(3) NOT NULL,
   `updated_by`          VARCHAR(3) NOT NULL,
   `deleted_by`          VARCHAR(3) NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`          TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_tabsScreens_code` (`ts_code`),   -- MC-5: parent key of every ts_code FK
   INDEX `idx_tst_tabsScreens_module`      (`module_code`),
   INDEX `idx_tst_tabsScreens_parent`      (`module_code`,`cat_code`,`mm_code`,`sm_code`),
   INDEX `idx_tst_tabsScreens_active`      (`is_active`,`is_excluded`),
   INDEX `idx_tst_tabsScreens_criticality` (`criticality`),
   INDEX `idx_tst_tabsScreens_pipeline`    (`dev_status`,`tc_list_status`,`tc_creation_status`),
   FULLTEXT KEY `ft_tst_tabsScreens_name`  (`name`,`description`),
   CONSTRAINT `fk_tst_tabsScreens_mainMenu`   FOREIGN KEY (`module_code`,`cat_code`,`mm_code`)
                                              REFERENCES `tst_main_menus`(`module_code`,`cat_code`,`mm_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tabsScreens_subMenu`    FOREIGN KEY (`sm_code`)         REFERENCES `tst_sub_menus`(`sm_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tabsScreens_owner`      FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tabsScreens_excludedBy` FOREIGN KEY (`excluded_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tabsScreens_reviewedBy` FOREIGN KEY (`reviewed_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tabsScreens_createdBy`  FOREIGN KEY (`created_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tabsScreens_updatedBy`  FOREIGN KEY (`updated_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tabsScreens_deletedBy`  FOREIGN KEY (`deleted_by`)      REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Screens. ts_code anchors every test case code. Excluded, never deleted.';


-- =========================================================================================================
-- SECTION 4 — AUTHORING: TcLIST, TEST CASES, STEPS, REVIEW, VERSIONS, DUPLICATES                    [P1]
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_tc_required_list  —  the TcList                                                               [P1]
-- ---------------------------------------------------------------------------------------------------------
-- WHY THIS IS A TABLE AND NOT A MARKDOWN FILE.
--   Coverage needs a DENOMINATOR. "Fees is about half tested" is not a number. "Fees has 214 required
--   cases, 168 released, 31 in progress, 15 not started" is. A file cannot be counted, filtered,
--   assigned, or joined to the test cases that satisfy it.
--
--   Coverage of a screen  =  released test cases  /  required entries not marked Not-Required.
--
-- tcr_code = machine_code || '_' || ts_code || '_' || LPAD(tc_list_number, 4, '0')
--
--   NOTE, and it is worth knowing: the list number is padded to FOUR digits here while tc_seq_number in
--   tst_test_cases is padded to THREE. Both columns are VARCHAR(21) and both work, but the same
--   conceptual position renders as 0001 and 001, which is a trap for a human comparing the two codes
--   for one test case. Implemented as specified (BRD D-29); flagged as BRD OPEN-01.
--
-- v7.2 corrections: the UNIQUE KEY named tc_list_code, a column that does not exist (FATAL); no foreign
--   key on machine_code; no foreign keys on the audit columns.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_tc_required_list` (
   `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `user_code`           VARCHAR(3)  NOT NULL   COMMENT 'Who planned it',
   `machine_code`        VARCHAR(4)  NOT NULL   COMMENT 'FK tst_machines.machine_code — base column of tcr_code',
   `ts_code`             VARCHAR(11) NOT NULL   COMMENT 'FK tst_tabs_screens.ts_code — base column of tcr_code',
   `tc_list_number`      SMALLINT UNSIGNED NOT NULL  COMMENT 'Sequence within the screen for that machine',
   `tcr_code`            VARCHAR(21) GENERATED ALWAYS AS
                           (CONCAT(`machine_code`,'_',`ts_code`,'_',LPAD(`tc_list_number`, 4, '0'))) STORED
                           COMMENT 'D02A_T0104010200_0001',
   `text_requir_detail`  VARCHAR(1000) NULL   COMMENT 'What this test must verify, in business language',
   `requir_steps_detail` TEXT NULL            COMMENT 'The required steps, before any code exists',
   `tc_creation_status`  ENUM('Planned','Pending','In-Progress','Ready','In_Review','Released','Error',
                              'Cancelled','Rolled_Back','Hold','Not-Required') NOT NULL DEFAULT 'Planned',
   `not_required_reason` VARCHAR(500) NULL    COMMENT 'Mandatory when status = Not-Required; excludes it from the denominator',
   `created_by`          VARCHAR(3) NOT NULL,
   `updated_by`          VARCHAR(3) NOT NULL,
   `deleted_by`          VARCHAR(3) NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`          TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_tcRequired_code`   (`tcr_code`),   -- v7.2: was (tc_list_code), an undeclared column
   UNIQUE KEY `uq_tst_tcRequired_seq`    (`machine_code`,`ts_code`,`tc_list_number`),
   INDEX `idx_tst_tcRequired_user`   (`user_code`),
   INDEX `idx_tst_tcRequired_screen` (`ts_code`,`tc_creation_status`),
   INDEX `idx_tst_tcRequired_status` (`tc_creation_status`),
   CONSTRAINT `chk_tst_tcRequired_notReq` CHECK (`tc_creation_status` <> 'Not-Required' OR `not_required_reason` IS NOT NULL),
   -- MC-2: machine_code and ts_code feed the generated tcr_code, so these MUST be RESTRICT.
   CONSTRAINT `fk_tst_tcRequired_machine`   FOREIGN KEY (`machine_code`) REFERENCES `tst_machines`(`machine_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcRequired_screen`    FOREIGN KEY (`ts_code`)      REFERENCES `tst_tabs_screens`(`ts_code`)  ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcRequired_user`      FOREIGN KEY (`user_code`)    REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcRequired_createdBy` FOREIGN KEY (`created_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcRequired_updatedBy` FOREIGN KEY (`updated_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcRequired_deletedBy` FOREIGN KEY (`deleted_by`)   REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='The required test-case list. This is the DENOMINATOR of every coverage figure.';
-- Import / Export: normal evidence-direction export and import.


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_cases  —  the test case                                                                  [P1]
-- ---------------------------------------------------------------------------------------------------------
-- test_case_code = machine_code || '_' || ts_code || '_' || LPAD(tc_seq_number, 3, '0')
--                  D02A_T0104010200_001
--
-- THIS COLUMN IS THE PARENT KEY OF THE ENTIRE SYSTEM. Steps, reviews, version history, duplicate links,
-- run items, results, bugs, dependencies, suite membership and path mappings all reference it.
--
-- THE CODE IS GENERATED, NEVER TYPED. tc_seq_number is allocated by CodeFactory under
-- SELECT ... FOR UPDATE on the screen row; uq_tst_testCases_tcCode is the backstop if a race is lost.
-- SEQUENCES ARE NEVER REUSED, even after a soft delete — reusing 001 attaches an old code to a new test.
--
-- MC-2 APPLIES TO machine_code AND ts_code. Both feed the generated column, so both foreign keys are
-- ON DELETE RESTRICT and cannot be anything else. This is also what makes BRD BR-TC-08 unbreakable:
-- A TEST CASE CANNOT BE MOVED TO ANOTHER SCREEN, because its code names its screen. Testing a different
-- screen is a different test case, created against that screen's TcList.
--
-- definition_hash drives two things: versioning (when it changes, the previous definition is snapshotted)
-- and duplicate detection (two cases with the same hash are the same test, authored twice).
--
-- v7.2 correction: children declared test_case_code as VARCHAR(20) while this declares VARCHAR(21).
--   MySQL accepts that and then cannot use the index properly — see MC-6. Now VARCHAR(21) everywhere.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_cases` (
   `id`                     INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `tcr_code`               VARCHAR(21) NULL      COMMENT 'FK tst_tc_required_list.tcr_code — the planned entry this satisfies',
   `user_code`              VARCHAR(3)  NOT NULL  COMMENT 'Author',
   `machine_code`           VARCHAR(4)  NOT NULL  COMMENT 'Base column of test_case_code — RESTRICT only (MC-2)',
   `ts_code`                VARCHAR(11) NOT NULL  COMMENT 'Base column of test_case_code — RESTRICT only (MC-2)',
   `tc_seq_number`          SMALLINT UNSIGNED NOT NULL COMMENT 'Allocated by CodeFactory; never reused',
   `test_case_code`         VARCHAR(21) GENERATED ALWAYS AS
                              (CONCAT(`machine_code`,'_',`ts_code`,'_',LPAD(`tc_seq_number`, 3, '0'))) STORED
                              COMMENT 'D02A_T0104010200_001 — the parent key of the whole system',
   `version_no`             TINYINT UNSIGNED NOT NULL DEFAULT 1,
   -- ---- Automation coordinates. NULL for a purely manual test case --------------------------------------
   `file_path`              VARCHAR(500) NULL     COMMENT 'tests/Browser/LoginPageTest.php',
   `namespace`              VARCHAR(255) NULL,
   `class_name`             VARCHAR(150) NULL,
   `method_name`            VARCHAR(150) NULL,
   -- ---- Definition --------------------------------------------------------------------------------------
   `display_name`           VARCHAR(255) NOT NULL,
   `description`            TEXT NULL,
   `preconditions`          TEXT NULL             COMMENT 'What must be true before execution',
   `test_data_note`         TEXT NULL             COMMENT 'What data state the test needs',
   `test_case_type_code`    ENUM('Standard','Unit','Validation','Feature','Business_Condition') NULL,
   `test_method_code`       ENUM('Manual','Automated','Hybrid') NULL,
   `test_technology_code`   ENUM('Dusk','Laravel-Unit','Native') NULL,
   `test_layer_code`        ENUM('GUI','API','Unit','Integration','Performance','Security','Accessibility','Other') NULL,
   `criticality`            ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `expected_duration_sec`  DECIMAL(10,2) NULL,
   `definition_hash`        CHAR(64) NULL         COMMENT 'sha256 over the normalised definition incl. ordered steps',
   -- ---- Lifecycle ---------------------------------------------------------------------------------------
   `creation_status_code`   ENUM('Pending','In-Progress','Ready-For-Review','In-Review','Released',
                                 'Cancelled','Rolled-Back','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
   `test_execution_status`  ENUM('Not-Run','Partially-Run','Fully-Run','Failing','Blocked') NOT NULL DEFAULT 'Not-Run',
   `is_orphaned`            TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'Implementation gone from source. NEVER deleted',
   `orphaned_at`            DATETIME NULL,
   `last_seen_in_source_at` DATETIME NULL,
   `cloned_from_code`       VARCHAR(21) NULL      COMMENT 'v7.2: was cloned_from_id — now the code',
   `is_active`              TINYINT(1) NOT NULL DEFAULT 1  COMMENT '0 = retired',
   `retired_at`             DATETIME NULL,
   `retired_by`             VARCHAR(3) NULL,
   `retired_reason`         VARCHAR(500) NULL,
   `created_by`             VARCHAR(3) NOT NULL,
   `updated_by`             VARCHAR(3) NOT NULL,
   `deleted_by`             VARCHAR(3) NULL,
   `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`             TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_testCases_tcCode` (`test_case_code`),   -- MC-5: the parent key of everything
   UNIQUE KEY `uq_tst_testCases_seq`    (`machine_code`,`ts_code`,`tc_seq_number`),
   INDEX `idx_tst_testCases_screen`      (`ts_code`,`is_active`),
   INDEX `idx_tst_testCases_status`      (`creation_status_code`,`is_active`),
   INDEX `idx_tst_testCases_criticality` (`criticality`,`is_active`),
   INDEX `idx_tst_testCases_hash`        (`definition_hash`),
   INDEX `idx_tst_testCases_tcr`         (`tcr_code`),
   INDEX `idx_tst_testCases_orphan`      (`is_orphaned`,`is_active`),
   CONSTRAINT `chk_tst_testCases_retired` CHECK (`is_active` = 1 OR `retired_reason` IS NOT NULL),
   -- MC-2: machine_code and ts_code feed test_case_code. RESTRICT is the only legal action.
   CONSTRAINT `fk_tst_testCases_machine`   FOREIGN KEY (`machine_code`) REFERENCES `tst_machines`(`machine_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testCases_screen`    FOREIGN KEY (`ts_code`)      REFERENCES `tst_tabs_screens`(`ts_code`)  ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testCases_tcr`       FOREIGN KEY (`tcr_code`)     REFERENCES `tst_tc_required_list`(`tcr_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testCases_user`      FOREIGN KEY (`user_code`)    REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testCases_retiredBy` FOREIGN KEY (`retired_by`)   REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_testCases_createdBy` FOREIGN KEY (`created_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testCases_updatedBy` FOREIGN KEY (`updated_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testCases_deletedBy` FOREIGN KEY (`deleted_by`)   REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='The test case. test_case_code is generated, globally unique, and permanent.';
-- Import / Export: normal evidence-direction export and import.
--   Under the new coding system a test case authored on another machine imports cleanly alongside this
--   machine's own — the codes differ. Whether the two are THE SAME TEST is a separate judgement,
--   recorded in tst_duplicate_test_case, never decided automatically.


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_case_steps  —  ordered steps for manual and hybrid execution                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- HOLDS ONLY THE CURRENT VERSION. Historical steps live in tst_test_case_versions_history.steps_json.
--
-- This is a deliberate denormalisation (Solution_Design_v3 SD-09). A manual tester executing a historical
-- run must see the steps AS THEY WERE, but keeping every version here would force the grid query to
-- filter on version on every load, on the table that is read most often during manual testing.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_case_steps` (
   `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `test_case_code`   VARCHAR(21) NOT NULL,      -- v7.2: was VARCHAR(20) against a VARCHAR(21) parent
   `step_no`          SMALLINT UNSIGNED NOT NULL,
   `action`           TEXT NOT NULL              COMMENT 'What the tester does',
   `expected_result`  TEXT NOT NULL              COMMENT 'What must happen',
   `test_data_note`   VARCHAR(1000) NULL,
   `is_optional`      TINYINT(1) NOT NULL DEFAULT 0,
   `created_by`       VARCHAR(3) NOT NULL,
   `updated_by`       VARCHAR(3) NOT NULL,
   `deleted_by`       VARCHAR(3) NULL,
   `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`       TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_tcSteps` (`test_case_code`,`step_no`),
   CONSTRAINT `chk_tst_tcSteps_no` CHECK (`step_no` >= 1),
   CONSTRAINT `fk_tst_tcSteps_case`      FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_tcSteps_createdBy` FOREIGN KEY (`created_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcSteps_updatedBy` FOREIGN KEY (`updated_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcSteps_deletedBy` FOREIGN KEY (`deleted_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Current-version steps only. History lives in the version snapshot (SD-09).';


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_case_review  —  review, readiness and sign-off                                           [P1]
-- ---------------------------------------------------------------------------------------------------------
-- REPLACES tst_releases (BRD D-26). The unit of release here is the TEST CASE, not a named delivery.
--
-- REVIEWER AND APPROVER ARE SEPARATE COLUMNS, and that is the point. Recording them in one field makes
-- "who signed this off?" unanswerable in exactly the case that matters: when someone reviewed their own
-- work. reviewed_by and signed_off_by may be the same person, and the record shows that they were.
--
-- version_no CARRIES NO FOREIGN KEY, AND THAT IS INTENTIONAL (Solution_Design_v3 SD-10).
--   It records the version as it stood at review time. A foreign key to tst_test_case_versions_history
--   would make reviewing version 1 impossible, because that table only holds SUPERSEDED definitions —
--   version 1's row does not exist until version 2 is written. Do not "fix" this.
--
-- A REVIEW IS RETAINED AS ISSUED (BRD BR-REV-07). ReviewService has no update path for readiness_score
--   or readiness_assessment once status = 'Completed'. Later data never retrospectively improves an
--   assessment that was made on what was known at the time.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_case_review` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `test_case_code`        VARCHAR(21) NOT NULL,
   `version_no`            TINYINT UNSIGNED NOT NULL DEFAULT 1  COMMENT 'No FK — intentional, see SD-10',
   `machine_code`          VARCHAR(4)  NOT NULL,
   `review_date`           DATETIME NOT NULL   COMMENT 'The business date of the review',
   `status`                ENUM('Pending','In-Progress','Completed','Released','Error','Cancelled',
                                'Rolled-Back','Hold','Not-Required') NOT NULL DEFAULT 'Pending',
   `released_at`           DATETIME NULL,
   -- ---- Readiness: metrics, completion checks, bug-free status, score -----------------------------------
   `readiness_score`       DECIMAL(5,2) NULL,
   `readiness_assessment`  TEXT NULL,
   -- ---- Technical review: step correctness, script logic, assertions, quality, suggestions --------------
   `review_note`           VARCHAR(1000) NULL,
   `reviewed_by`           VARCHAR(3) NULL,
   `reviewed_at`           DATETIME NULL,
   -- ---- Sign-off: authorisation, risk acceptance, release clearance -------------------------------------
   `sign_off_note`         TEXT NULL,
   `signed_off_by`         VARCHAR(3) NULL,
   `signed_off_at`         DATETIME NULL,
   -- ---- Two specific risk flags -------------------------------------------------------------------------
   `bug_in_testcase`       TINYINT(1) NOT NULL DEFAULT 0,
   `known_issues_in_scope` TINYINT(1) NOT NULL DEFAULT 0,
   `created_by`            VARCHAR(3) NOT NULL,
   `updated_by`            VARCHAR(3) NOT NULL,
   `deleted_by`            VARCHAR(3) NULL,
   `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`            TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_tcReview_entry`  (`test_case_code`,`version_no`,`machine_code`,`review_date`),
   INDEX `idx_tst_tcReview_status`     (`review_date`,`status`,`machine_code`),
   INDEX `idx_tst_tcReview_case`       (`test_case_code`,`version_no`),
   INDEX `idx_tst_tcReview_reviewer`   (`reviewed_by`),
   INDEX `idx_tst_tcReview_signer`     (`signed_off_by`),
   CONSTRAINT `chk_tst_tcReview_score` CHECK (`readiness_score` IS NULL OR (`readiness_score` BETWEEN 0 AND 100)),
   CONSTRAINT `fk_tst_tcReview_case`      FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReview_machine`   FOREIGN KEY (`machine_code`)   REFERENCES `tst_machines`(`machine_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReview_reviewer`  FOREIGN KEY (`reviewed_by`)    REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReview_signer`    FOREIGN KEY (`signed_off_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReview_createdBy` FOREIGN KEY (`created_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReview_updatedBy` FOREIGN KEY (`updated_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReview_deletedBy` FOREIGN KEY (`deleted_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Review, readiness score and sign-off. Replaces the Release entity (D-26).';


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_case_versions_history  —  immutable snapshot of a SUPERSEDED definition                  [P1]
-- ---------------------------------------------------------------------------------------------------------
-- Written when definition_hash changes, so a historical result can still be rendered as the test case
-- stood when it ran. steps_json holds the ordered steps as they then were.
--
-- v7.2 correction: the foreign key named test_case_id, a column this table does not declare (FATAL).
--   It now references test_case_code, which is what the table actually carries.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_case_versions_history` (
   `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `test_case_code`            VARCHAR(21) NOT NULL,
   `version_no`                TINYINT UNSIGNED NOT NULL,
   `definition_hash`           CHAR(64) NULL,
   `file_path`                 VARCHAR(500) NULL,
   `class_name`                VARCHAR(150) NULL,
   `method_name`               VARCHAR(150) NULL,
   `display_name`              VARCHAR(255) NULL,
   `description`               TEXT NULL,
   `preconditions`             TEXT NULL,
   `steps_json`                JSON NULL      COMMENT 'The ordered steps as they were at this version',
   `test_case_type_code`       VARCHAR(30) NULL,
   `test_method_code`          VARCHAR(30) NULL,
   `test_technology_code`      VARCHAR(30) NULL,
   `test_layer_code`           VARCHAR(30) NULL,
   `criticality`               ENUM('Low','Medium','High','Critical') NULL,
   `change_summary`            VARCHAR(1000) NULL,
   `captured_from_commit_hash` VARCHAR(40) NULL   COMMENT 'A Git SHA-1 is 40 hex chars, not 64',
   `captured_by`               VARCHAR(3) NOT NULL,
   `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_tcVersions` (`test_case_code`,`version_no`),
   INDEX `idx_tst_tcVersions_hash` (`definition_hash`),
   -- v7.2: was FOREIGN KEY (test_case_id) REFERENCES tst_test_cases(id) — an undeclared column.
   CONSTRAINT `fk_tst_tcVersions_case`       FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_tcVersions_capturedBy` FOREIGN KEY (`captured_by`)    REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='IMMUTABLE snapshots of superseded definitions. Insert-only.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_duplicate_test_case  —  the equivalence judgement                                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- THIS TABLE IS WHAT REPLACED tst_source_test_cases.
--
--   Under v7.0 two machines could both mint T0104010200/001, so an incoming test case had to be held in
--   quarantine until a human decided whether it was the same test. That was a question about IDENTITY,
--   and the coding system answers it: D02A_… and T01A_… are different codes, both import cleanly.
--
--   What remains is a question about EQUIVALENCE — "are these two tests verifying the same thing?" —
--   which is a matter of judgement and belongs here.
--
-- INSERT-ONLY. A reversal writes a NEW row and stamps superseded_at on the old one, so the decision
-- history survives (BRD BR-DUP-04). 'Confirmed_Different' is as valuable as 'Confirmed_Equivalent':
-- without it, the system re-proposes the same rejected match forever.
--
-- A CONFIRMED DUPLICATE IS NOT DELETED. Both test cases keep their evidence; reporting counts the primary.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_duplicate_test_case` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `test_case_code`        VARCHAR(21) NOT NULL,
   `linked_test_case_code` VARCHAR(21) NOT NULL,
   `link_type`             ENUM('Proposed_Equivalent','Confirmed_Equivalent','Confirmed_Different',
                                'Duplicate_Of','Variant_Of','Supersedes') NOT NULL DEFAULT 'Proposed_Equivalent',
   `score`                 DECIMAL(4,3) NULL   COMMENT '0.000-1.000, how strongly they match',
   `evidence_json`         JSON NULL           COMMENT 'Why the application proposed it',
   `proposed_by`           VARCHAR(3) NULL     COMMENT 'A person, or the system user',
   `decided_by`            VARCHAR(3) NULL     COMMENT 'QA Lead or Architect — never automatic',
   `decided_at`            DATETIME NULL,
   `note`                  VARCHAR(1000) NULL,
   `superseded_at`         DATETIME NULL       COMMENT 'Set when a later row reverses this decision',
   `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_tcDup_case`   (`test_case_code`,`link_type`),
   INDEX `idx_tst_tcDup_linked` (`linked_test_case_code`),
   INDEX `idx_tst_tcDup_open`   (`link_type`,`superseded_at`),
   CONSTRAINT `chk_tst_tcDup_notSelf` CHECK (`test_case_code` <> `linked_test_case_code`),
   CONSTRAINT `chk_tst_tcDup_score`   CHECK (`score` IS NULL OR (`score` BETWEEN 0 AND 1)),
   CONSTRAINT `fk_tst_tcDup_case`       FOREIGN KEY (`test_case_code`)        REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_tcDup_linked`     FOREIGN KEY (`linked_test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_tcDup_proposedBy` FOREIGN KEY (`proposed_by`)           REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcDup_decidedBy`  FOREIGN KEY (`decided_by`)            REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Equivalence judgements between test cases. Insert-only; reversals supersede.';


-- =========================================================================================================
-- SECTION 5 — EXECUTION                                                                             [P1]
-- =========================================================================================================
--     tst_test_runs                one execution EVENT
--       tst_test_run_scopes        why the run exists
--       tst_test_run_items         which test cases were selected, and why each one
--         tst_test_run_results     one row per ATTEMPT — insert-only, the source of ALL statistics
--           tst_test_run_result_steps    per-step outcomes for manual execution
--           tst_run_result_artifacts     evidence
--     tst_failure_signatures       distinct normalised failures
--     tst_test_case_runs_summary   DERIVED roll-up, never authoritative
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_runs  —  one execution event                                                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- A RUN IS AN EVENT COVERING MANY TEST CASES.
--
--   v7.1 gave this table a GENERATED test_case_code built from machine_code, ts_code and tc_seq_number.
--   That is a category error — and the generated column referenced `machine_code`, which the table does
--   not declare (it has run_machine_code), so the script would not execute at all. REMOVED in v7.2.
--   The per-test-case link belongs in tst_test_run_items.test_case_code, where it is one row per case.
--
-- WHAT A RUN ACTUALLY NEEDS:
--   machine_id + source_run_id   distributed identity. On a local database source_run_id equals id;
--                                on central, id is re-issued and the pair is preserved, which is what
--                                makes a repeated import a no-op.
--   run_machine_code             which machine executed it, as a readable code that consolidates
--   run_user_code                whose machine it was
--   initiated_by / executed_by   attribution. A scheduled run is initiated by a person and executed by
--                                the system user; recording only one of them loses the distinction.
--
-- CODE VERSION UNDER TEST (BRD BR-EXEC-03). repository_code, branch_name, commit_hash and
--   working_tree_dirty are PLAIN COLUMNS in Phase 1 with no foreign key. The Git tables arrive in
--   Phase 2 and the FK is added then (Section 30) — see THE PHASE RULE.
--   A result without a commit hash cannot be interpreted historically, so these are recorded from day 1
--   even though nothing validates them yet.
--
-- suite_id, suite_version_no, impact_analysis_id: Phase-2 columns, declared now, NULL until Phase 2.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_runs` (
   `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`             SMALLINT UNSIGNED NOT NULL,
   `source_run_id`          BIGINT UNSIGNED NOT NULL   COMMENT 'Equals id locally; preserved on central',
   `run_machine_code`       VARCHAR(4) NOT NULL        COMMENT 'Which machine executed this run',
   `run_user_code`          VARCHAR(3) NOT NULL        COMMENT 'Whose machine it is',
   `entry_type`             ENUM('Local','Imported') NOT NULL DEFAULT 'Local',
   `initiated_by`           VARCHAR(3) NULL,
   `executed_by`            VARCHAR(3) NULL            COMMENT 'The system user for a scheduled run',
   `trigger_type`           ENUM('Manual','Scheduled','Rerun','Auto_Retest','Bug_Retest','Impact_Selected',
                                 'Enhancement','Integration','Regression','Git_Merge','Release','CI')
                              NOT NULL DEFAULT 'Manual',
   -- ---- Phase-2 columns: declared now, foreign keys added in Section 30 ---------------------------------
   `suite_id`               INT UNSIGNED NULL          COMMENT '[P2] FK added in Section 30',
   `suite_version_no`       INT UNSIGNED NULL          COMMENT '[P2] The composition actually executed',
   `impact_analysis_id`     BIGINT UNSIGNED NULL       COMMENT '[P2] FK added in Section 30',
   -- ------------------------------------------------------------------------------------------------------
   `schedule_id`            INT UNSIGNED NULL          COMMENT '[P1] FK added in Section 12 (schedules come later in this file)',
   `parent_run_id`          BIGINT UNSIGNED NULL       COMMENT 'For a rerun or retest of an earlier run',
   `run_name`               VARCHAR(200) NULL,
   `reason`                 VARCHAR(500) NULL,
   -- ---- The code version under test ---------------------------------------------------------------------
   `repository_code`        VARCHAR(100) NULL,
   `branch_name`            VARCHAR(200) NULL,
   `commit_hash`            VARCHAR(40) NULL           COMMENT 'A Git SHA-1 is 40 hex characters',
   `merge_commit_hash`      VARCHAR(40) NULL,
   `base_commit_hash`       VARCHAR(40) NULL,
   `working_tree_dirty`     TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'Uncommitted changes were present',
   -- ---- Environment -------------------------------------------------------------------------------------
   `environment_profile_id` INT UNSIGNED NULL,
   `environment_json`       JSON NULL                  COMMENT 'The raw capture the fingerprint came from',
   `command`                VARCHAR(2000) NULL,
   -- ---- Lifecycle ---------------------------------------------------------------------------------------
   `status`                 ENUM('Queued','Running','Completed','Failed','Cancelled','Interrupted','Timed_Out')
                              NOT NULL DEFAULT 'Queued',
   `queued_at`              DATETIME NULL,
   `started_at`             DATETIME NULL,
   `finished_at`            DATETIME NULL,
   `duration_seconds`       DECIMAL(12,3) NULL,
   `exit_code`              SMALLINT NULL,
   -- Interruption detection. A watchdog moves any Running run whose heartbeat has stopped to Interrupted,
   -- retaining every result already recorded. Without this, a machine that loses power leaves a run
   -- permanently Running and every in-progress count is wrong forever.
   `heartbeat_at`           DATETIME NULL,
   `lock_token`             CHAR(36) NULL,
   `cancelled_by`           VARCHAR(3) NULL,
   `cancelled_at`           DATETIME NULL,
   `cancel_reason`          VARCHAR(500) NULL,
   -- ---- Roll-ups over FINAL attempts only. RECOMPUTED from results, never incremented ad hoc -------------
   `total_tc_count`         MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `passed_tc_count`        MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `failed_tc_count`        MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `error_tc_count`         MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `skipped_tc_count`       MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `blocked_tc_count`       MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `not_executed_tc_count`  MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
   `total_assertion_count`  INT UNSIGNED NOT NULL DEFAULT 0,
   `passed_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,
   `failed_assertion_count` INT UNSIGNED NOT NULL DEFAULT 0,
   `raw_output_path`        VARCHAR(1000) NULL,
   `created_by`             VARCHAR(3) NOT NULL,
   `updated_by`             VARCHAR(3) NOT NULL,
   `deleted_by`             VARCHAR(3) NULL,
   `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`             TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_testRuns_source` (`machine_id`,`source_run_id`),   -- idempotent re-import
   INDEX `idx_tst_testRuns_machineDate`  (`machine_id`,`started_at`),
   INDEX `idx_tst_testRuns_machineCode`  (`run_machine_code`,`started_at`),
   INDEX `idx_tst_testRuns_executor`     (`executed_by`,`started_at`),
   INDEX `idx_tst_testRuns_initiator`    (`initiated_by`,`started_at`),
   INDEX `idx_tst_testRuns_trigger`      (`trigger_type`,`status`),
   INDEX `idx_tst_testRuns_commit`       (`repository_code`,`commit_hash`),
   INDEX `idx_tst_testRuns_parent`       (`parent_run_id`),
   INDEX `idx_tst_testRuns_suite`        (`suite_id`),
   INDEX `idx_tst_testRuns_env`          (`environment_profile_id`),
   INDEX `idx_tst_testRuns_impact`       (`impact_analysis_id`),
   INDEX `idx_tst_testRuns_schedule`     (`schedule_id`),
   INDEX `idx_tst_testRuns_watchdog`     (`status`,`heartbeat_at`),
   CONSTRAINT `fk_tst_testRuns_machine`     FOREIGN KEY (`machine_id`)             REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testRuns_machineCode` FOREIGN KEY (`run_machine_code`)       REFERENCES `tst_machines`(`machine_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testRuns_userCode`    FOREIGN KEY (`run_user_code`)          REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testRuns_initiatedBy` FOREIGN KEY (`initiated_by`)           REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_testRuns_executedBy`  FOREIGN KEY (`executed_by`)            REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_testRuns_cancelledBy` FOREIGN KEY (`cancelled_by`)           REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_testRuns_env`         FOREIGN KEY (`environment_profile_id`) REFERENCES `tst_environment_profiles`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_testRuns_parent`      FOREIGN KEY (`parent_run_id`)          REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_testRuns_createdBy`   FOREIGN KEY (`created_by`)             REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testRuns_updatedBy`   FOREIGN KEY (`updated_by`)             REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_testRuns_deletedBy`   FOREIGN KEY (`deleted_by`)             REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One execution event. NOT one test case — v7.1 modelled it as one (fatal defect 6).';


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_run_scopes  —  what the run was asked to cover                                           [P1]
-- ---------------------------------------------------------------------------------------------------------
-- One run may have several scope rows: "the Fees module, plus these three screens, plus bug 412".
-- The 'Suite' and 'Change_Request' scope types are unreachable until Phase 2.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_run_scopes` (
   `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `run_id`             BIGINT UNSIGNED NOT NULL,
   `scope_type`         ENUM('Module','Screen','TestCase','Suite','Bug','Change_Request','Commit',
                             'Impact_Analysis','Release','Full') NOT NULL,
   `module_code`        VARCHAR(5)  NULL,
   `ts_code`            VARCHAR(11) NULL,
   `test_case_code`     VARCHAR(21) NULL,
   `bug_id`             BIGINT UNSIGNED NULL   COMMENT '[P1] FK added in Section 12 (bugs come later)',
   `suite_id`           INT UNSIGNED NULL      COMMENT '[P2] FK added in Section 30',
   `change_request_id`  BIGINT UNSIGNED NULL   COMMENT '[P2] FK added in Section 30',
   `repository_code`    VARCHAR(100) NULL,
   `commit_hash`        VARCHAR(40) NULL,
   `description`        VARCHAR(500) NULL,
   `created_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_runScopes_run`    (`run_id`),
   INDEX `idx_tst_runScopes_module` (`module_code`),
   INDEX `idx_tst_runScopes_screen` (`ts_code`),
   INDEX `idx_tst_runScopes_case`   (`test_case_code`),
   INDEX `idx_tst_runScopes_bug`    (`bug_id`),
   CONSTRAINT `fk_tst_runScopes_run`    FOREIGN KEY (`run_id`)         REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_runScopes_module` FOREIGN KEY (`module_code`)    REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_runScopes_screen` FOREIGN KEY (`ts_code`)        REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_runScopes_case`   FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Why the run exists. Suite and Change_Request scopes activate in Phase 2.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_run_items  —  one test case in one run, and WHY it was selected                          [P1]
-- ---------------------------------------------------------------------------------------------------------
-- selection_reason IS THE POINT OF THIS TABLE. A month later, "why did we run these 40 tests?" is
-- answerable from the data. This is what makes Phase-2 impact analysis explainable after the fact.
-- In Phase 1 the reachable values are Manual, Bug_Retest, Critical, Regression, Schedule and Open_Bug.
--
-- THE SNAPSHOT COLUMNS matter more than they look. display_name_snapshot, file_path_snapshot,
-- criticality_snapshot and test_case_version_no are captured AT SELECTION TIME, so a run from six months
-- ago renders as the test case then stood. Without them, renaming a test case silently rewrites history.
--
-- v7.2: source_test_case_id and the CHECK constraint that exactly one of two case references be present
--   are REMOVED, along with tst_source_test_cases itself. A test case authored on another machine now
--   simply has a different code and lives in tst_test_cases like any other.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_run_items` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `run_id`                BIGINT UNSIGNED NOT NULL,
   `test_case_code`        VARCHAR(21) NOT NULL,
   `selection_reason`      ENUM('Manual','Suite','Direct_Change','Dependency','Bug_Retest','Critical',
                                'Regression','Full_Regression','Historical_Correlation','Open_Bug',
                                'Schedule','Other') NOT NULL DEFAULT 'Manual',
   `selection_source`      VARCHAR(255) NULL   COMMENT 'The commit, rule or analysis that put it here',
   `selection_confidence`  DECIMAL(4,3) NULL,
   `sequence_no`           INT UNSIGNED NOT NULL DEFAULT 1,
   -- ---- Snapshots taken at selection time ---------------------------------------------------------------
   `test_case_version_no`  INT UNSIGNED NULL,
   `display_name_snapshot` VARCHAR(255) NOT NULL,
   `file_path_snapshot`    VARCHAR(500) NULL,
   `criticality_snapshot`  ENUM('Low','Medium','High','Critical') NULL,
   -- ---- Set when the item never ran because a blocking dependency failed [P2 semantics] ------------------
   `blocked_by_item_id`    BIGINT UNSIGNED NULL,
   `blocked_reason`        VARCHAR(500) NULL,
   `attempt_count`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
   `final_status`          ENUM('Passed','Failed','Error','Skipped','Blocked','Not_Executed') NULL,
   `created_by`            VARCHAR(3) NOT NULL,
   `updated_by`            VARCHAR(3) NOT NULL,
   `deleted_by`            VARCHAR(3) NULL,
   `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`            TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_runItems_runCase` (`run_id`,`test_case_code`),
   INDEX `idx_tst_runItems_caseDate`  (`test_case_code`,`created_at`),
   INDEX `idx_tst_runItems_reason`    (`selection_reason`),
   INDEX `idx_tst_runItems_final`     (`final_status`),
   INDEX `idx_tst_runItems_blockedBy` (`blocked_by_item_id`),
   CONSTRAINT `fk_tst_runItems_run`       FOREIGN KEY (`run_id`)             REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_runItems_case`      FOREIGN KEY (`test_case_code`)     REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_runItems_blockedBy` FOREIGN KEY (`blocked_by_item_id`) REFERENCES `tst_test_run_items`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_runItems_createdBy` FOREIGN KEY (`created_by`)         REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_runItems_updatedBy` FOREIGN KEY (`updated_by`)         REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_runItems_deletedBy` FOREIGN KEY (`deleted_by`)         REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One test case in one run, with the reason it was selected and a snapshot of how it looked.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_run_results  —  ONE ROW PER ATTEMPT. INSERT-ONLY.                                        [P1]
-- ---------------------------------------------------------------------------------------------------------
-- THIS TABLE IS THE SINGLE SOURCE OF TRUTH FROM WHICH EVERY STATISTIC IN THE SYSTEM IS DERIVED.
--
-- NOTHING IN THE APPLICATION MAY EVER UPDATE A STATUS HERE. A re-execution is a NEW row with
-- attempt_no + 1. ExecutionService is the only writer, and it has no update path.
--
-- SIX STATUSES, AND THE TWO THAT v6.7 LACKED MATTER MOST:
--   Blocked       did not run because a prerequisite failed. RECORDING THIS AS FAILED INFLATES DEFECT
--                 COUNTS and sends someone to investigate a test that never executed.
--   Not_Executed  selected but never reached — the run was interrupted or cancelled.
--
-- triage_state (BRD R-06): A FAILURE IS NOT AUTOMATICALLY A BUG. It may be a new bug, a known bug, a
-- flaky test, an environment problem, a data problem, a defect in the test itself, or expected.
--
-- test_case_code is DENORMALISED here on purpose: every history query starts from a test case, and this
-- avoids a join to run_items across millions of rows. Maintained by ExecutionService only.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_run_results` (
   `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `run_id`                 BIGINT UNSIGNED NOT NULL,
   `run_item_id`            BIGINT UNSIGNED NOT NULL,
   `test_case_code`         VARCHAR(21) NULL   COMMENT 'Denormalised from the run item for query performance',
   `machine_id`             SMALLINT UNSIGNED NOT NULL,
   `run_machine_code`       VARCHAR(4) NULL    COMMENT 'Denormalised; readable in exports and logs',
   `environment_profile_id` INT UNSIGNED NULL,
   `attempt_no`             SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `is_final_attempt`       TINYINT(1) NOT NULL DEFAULT 1,
   `status`                 ENUM('Passed','Failed','Error','Skipped','Blocked','Not_Executed') NOT NULL,
   `executed_by`            VARCHAR(3) NULL,
   `started_at`             DATETIME NULL,
   `finished_at`            DATETIME NULL,
   `duration_seconds`       DECIMAL(12,3) NULL,
   `assertions`             INT UNSIGNED NOT NULL DEFAULT 0,
   `display_name_snapshot`  VARCHAR(255) NOT NULL,
   -- ---- Failure detail ----------------------------------------------------------------------------------
   `error_message`          TEXT NULL,
   `error_trace`            MEDIUMTEXT NULL,
   `exception_class`        VARCHAR(255) NULL,
   `failure_fingerprint`    CHAR(64) NULL      COMMENT 'Normalised: no timestamps, ids, addresses or absolute paths',
   `failure_signature_id`   BIGINT UNSIGNED NULL  COMMENT 'FK added in Section 12 (signatures come later)',
   -- ---- Triage ------------------------------------------------------------------------------------------
   `triage_state`           ENUM('Untriaged','New_Bug','Existing_Bug','Known_Issue','Flaky','Environment',
                                 'Test_Defect','Data_Issue','Expected') NOT NULL DEFAULT 'Untriaged',
   `triaged_by`             VARCHAR(3) NULL,
   `triaged_at`             DATETIME NULL,
   `triage_note`            VARCHAR(1000) NULL,
   `result_json`            JSON NULL          COMMENT 'Raw adapter payload',
   `consistency_note`       VARCHAR(1000) NULL COMMENT 'Explains a result inconsistent with its steps',
   `created_by`             VARCHAR(3) NOT NULL,
   `updated_by`             VARCHAR(3) NOT NULL,
   `deleted_by`             VARCHAR(3) NULL,
   `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`             TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_results_attempt` (`run_item_id`,`attempt_no`),
   INDEX `idx_tst_results_runStatus`   (`run_id`,`status`),
   INDEX `idx_tst_results_caseDate`    (`test_case_code`,`created_at`),
   INDEX `idx_tst_results_caseFinal`   (`test_case_code`,`is_final_attempt`,`status`,`created_at`),
   INDEX `idx_tst_results_fingerprint` (`failure_fingerprint`),
   INDEX `idx_tst_results_signature`   (`failure_signature_id`),
   INDEX `idx_tst_results_triage`      (`triage_state`,`created_at`),
   INDEX `idx_tst_results_machineDate` (`machine_id`,`created_at`),
   INDEX `idx_tst_results_env`         (`environment_profile_id`,`status`),
   CONSTRAINT `fk_tst_results_run`        FOREIGN KEY (`run_id`)                 REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_results_item`       FOREIGN KEY (`run_item_id`)            REFERENCES `tst_test_run_items`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_results_case`       FOREIGN KEY (`test_case_code`)         REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_results_machine`    FOREIGN KEY (`machine_id`)             REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_results_env`        FOREIGN KEY (`environment_profile_id`) REFERENCES `tst_environment_profiles`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_results_executedBy` FOREIGN KEY (`executed_by`)            REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_results_triagedBy`  FOREIGN KEY (`triaged_by`)             REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_results_createdBy`  FOREIGN KEY (`created_by`)             REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_results_updatedBy`  FOREIGN KEY (`updated_by`)             REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_results_deletedBy`  FOREIGN KEY (`deleted_by`)             REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One row per ATTEMPT. Insert-only. The source of every statistic in the system.';


CREATE TABLE IF NOT EXISTS `tst_test_run_result_steps` (
   `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `run_result_id`     BIGINT UNSIGNED NOT NULL,
   `step_no`           SMALLINT UNSIGNED NOT NULL,
   `action_snapshot`   TEXT NOT NULL   COMMENT 'The step AS IT WAS when executed',
   `expected_snapshot` TEXT NOT NULL,
   `status`            ENUM('Passed','Failed','Blocked','Skipped','Not_Executed') NOT NULL,
   `actual_result`     TEXT NULL,
   `note`              VARCHAR(1000) NULL,
   `duration_seconds`  DECIMAL(10,2) NULL,
   `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_resultSteps` (`run_result_id`,`step_no`),
   INDEX `idx_tst_resultSteps_status` (`status`),
   CONSTRAINT `fk_tst_resultSteps_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-step outcomes for manual execution. Steps are snapshotted, not referenced.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_run_result_artifacts  —  evidence                                                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- v6.7 had three fixed path columns, which left video, HAR files and per-step screenshots nowhere to go
-- and no way to express that an artefact had been purged.
--
-- is_available = 0 MEANS THE FILE WAS PURGED BY RETENTION. The row stays. The result then shows
-- "evidence expired" rather than appearing never to have had any — which are different facts, and the
-- difference matters when someone is deciding whether a year-old conclusion can be re-examined.
--
-- file_sha256 lets identical artefacts be stored once and referenced many times.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_run_result_artifacts` (
   `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `run_result_id`  BIGINT UNSIGNED NOT NULL,
   `step_no`        SMALLINT UNSIGNED NULL   COMMENT 'When the artefact belongs to one manual step',
   `artifact_type`  ENUM('Screenshot','Console_Log','Page_Source','Video','Network_Log','Raw_Output',
                         'Trace','Attachment','Other') NOT NULL,
   `file_path`      VARCHAR(1000) NOT NULL,
   `file_sha256`    CHAR(64) NULL   COMMENT 'Identical artefacts stored once, referenced many times',
   `bytes`          BIGINT UNSIGNED NULL,
   `mime_type`      VARCHAR(100) NULL,
   `caption`        VARCHAR(500) NULL,
   `is_available`   TINYINT(1) NOT NULL DEFAULT 1  COMMENT '0 = purged by retention. The row REMAINS',
   `expires_at`     DATETIME NULL,
   `purged_at`      DATETIME NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_artifacts_result` (`run_result_id`,`artifact_type`),
   INDEX `idx_tst_artifacts_hash`   (`file_sha256`),
   INDEX `idx_tst_artifacts_expiry` (`is_available`,`expires_at`),
   CONSTRAINT `fk_tst_artifacts_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Evidence. A purged artefact stays as a row with is_available = 0.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_failure_signatures  —  one row per DISTINCT normalised failure                                [P1]
-- ---------------------------------------------------------------------------------------------------------
-- THIS IS WHAT TURNS FORTY FAILURES INTO ONE PROBLEM.
--
-- Without grouping, triage volume scales with test count rather than defect count, and the team stops
-- triaging — which is how a real defect ends up buried under thirty-nine duplicates of itself.
--
-- Once a signature is triaged to a bug or a known issue, later matching failures are attributed
-- automatically and never re-triaged.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_failure_signatures` (
   `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `fingerprint`         CHAR(64) NOT NULL,
   `exception_class`     VARCHAR(255) NULL,
   `normalised_message`  VARCHAR(1000) NULL,
   `top_frames`          VARCHAR(1000) NULL   COMMENT 'Top application frames; vendor frames removed',
   `sample_result_id`    BIGINT UNSIGNED NULL COMMENT 'FK added in Section 12',
   `first_seen_at`       DATETIME NULL,
   `last_seen_at`        DATETIME NULL,
   `occurrence_count`    BIGINT UNSIGNED NOT NULL DEFAULT 0,
   `distinct_test_cases` INT UNSIGNED NOT NULL DEFAULT 0,
   `distinct_machines`   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
   `bug_id`              BIGINT UNSIGNED NULL COMMENT 'FK added in Section 12',
   `known_issue_id`      BIGINT UNSIGNED NULL COMMENT 'FK added in Section 12',
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_failureSig` (`fingerprint`),
   INDEX `idx_tst_failureSig_bug`      (`bug_id`),
   INDEX `idx_tst_failureSig_known`    (`known_issue_id`),
   INDEX `idx_tst_failureSig_lastSeen` (`last_seen_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Distinct normalised failures. Turns forty failures into one problem.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_test_case_runs_summary  —  DERIVED. Never a source of truth.                                  [P1]
-- ---------------------------------------------------------------------------------------------------------
-- EVERY COLUMN HERE MUST BE REPRODUCIBLE FROM tst_test_run_results ALONE.
-- `php artisan tst:rebuild-analytics` does exactly that, and a nightly job compares the incremental
-- values against a full rebuild and REPORTS DIVERGENCE rather than silently correcting it (BRD R-13).
--
-- last_rebuilt_at and rebuild_source exist so a summary can always be shown to be current with the
-- evidence. A dashboard number whose provenance is unknown is a rumour.
--
-- FLAKINESS: the candidate is computed; CONFIRMATION IS A HUMAN DECISION (flaky_confirmed_by).
--   flaky_evidence_json retains the outcome series, the environment and the change check, so the
--   conclusion can be re-argued a year later. A confirmed flaky test is excluded from regression
--   alerting but NEVER from execution — excluding it destroys the evidence needed to fix it.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_test_case_runs_summary` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `test_case_code`        VARCHAR(21) NOT NULL,
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
   -- ---- Flakiness ---------------------------------------------------------------------------------------
   `flaky_score`           DECIMAL(4,3) NULL,
   `is_flaky_candidate`    TINYINT(1) NOT NULL DEFAULT 0,
   `is_flaky_confirmed`    TINYINT(1) NOT NULL DEFAULT 0,
   `flaky_reason`          VARCHAR(500) NULL,
   `flaky_evidence_json`   JSON NULL,
   `flaky_confirmed_by`    VARCHAR(3) NULL,
   `flaky_confirmed_at`    DATETIME NULL,
   -- ---- Derived indicators ------------------------------------------------------------------------------
   `confidence_score`      DECIMAL(5,2) NULL   COMMENT 'How much to trust this green tick',
   `confidence_json`       JSON NULL           COMMENT 'The inputs, so the score is explainable',
   `health_status`         ENUM('Healthy','Unstable','Frequently_Failing','Obsolete','Blocked',
                                'Insufficient_History','Under_Investigation','Orphaned')
                             NOT NULL DEFAULT 'Insufficient_History',
   `open_bug_count`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
   -- ---- Rebuild provenance ------------------------------------------------------------------------------
   `last_rebuilt_at`       DATETIME NULL,
   `rebuild_source`        ENUM('Incremental','Full_Rebuild') NOT NULL DEFAULT 'Incremental',
   `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_caseSummary_case` (`test_case_code`),
   INDEX `idx_tst_caseSummary_status`     (`last_status`),
   INDEX `idx_tst_caseSummary_flaky`      (`is_flaky_confirmed`,`is_flaky_candidate`),
   INDEX `idx_tst_caseSummary_health`     (`health_status`),
   INDEX `idx_tst_caseSummary_lastRun`    (`last_run_at`),
   INDEX `idx_tst_caseSummary_confidence` (`confidence_score`),
   CONSTRAINT `fk_tst_caseSummary_case`       FOREIGN KEY (`test_case_code`)     REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_caseSummary_lastRun`    FOREIGN KEY (`last_run_id`)        REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_caseSummary_lastResult` FOREIGN KEY (`last_run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_caseSummary_flakyBy`    FOREIGN KEY (`flaky_confirmed_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='DERIVED roll-up. Rebuildable from results alone, and checked nightly (R-13).';


-- =========================================================================================================
-- SECTION 6 — SCHEDULING                                                                            [P1]
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_schedules  —  when to run                                                                     [P1]
-- ---------------------------------------------------------------------------------------------------------
-- A SCHEDULE THAT DID NOT FIRE IS RECORDED AS MISSED, not silently skipped. Silence and success look
-- identical otherwise, and the first time anyone notices is when a release goes out untested.
--
-- suite_id is a Phase-2 column: in Phase 1 a schedule's content comes from tst_schedule_targets.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_schedules` (
   `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `name`              VARCHAR(150) NOT NULL,
   `description`       VARCHAR(500) NULL,
   `owner_user_code`   VARCHAR(3) NOT NULL   COMMENT 'Answerable when it fails or is missed',
   `suite_id`          INT UNSIGNED NULL     COMMENT '[P2] FK added in Section 30',
   `cron_expression`   VARCHAR(100) NOT NULL,
   `timezone`          VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
   `catch_up_policy`   ENUM('Skip','Run_Once','Run_All') NOT NULL DEFAULT 'Skip',
   `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
   `is_suspended`      TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'Distinct from deactivated — a temporary hold',
   `suspended_reason`  VARCHAR(500) NULL,
   `next_run_at`       DATETIME NULL,
   `last_run_id`       BIGINT UNSIGNED NULL,
   `last_run_at`       DATETIME NULL,
   `last_status`       ENUM('Success','Failed','Missed','Cancelled') NULL,
   `missed_count`      INT UNSIGNED NOT NULL DEFAULT 0,
   `created_by`        VARCHAR(3) NOT NULL,
   `updated_by`        VARCHAR(3) NOT NULL,
   `deleted_by`        VARCHAR(3) NULL,
   `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`        TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_schedules_name` (`name`),
   INDEX `idx_tst_schedules_active` (`is_active`,`is_suspended`,`next_run_at`),
   CONSTRAINT `chk_tst_schedules_susp` CHECK (`is_suspended` = 0 OR `suspended_reason` IS NOT NULL),
   CONSTRAINT `fk_tst_schedules_owner`     FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_schedules_lastRun`   FOREIGN KEY (`last_run_id`)     REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_schedules_createdBy` FOREIGN KEY (`created_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_schedules_updatedBy` FOREIGN KEY (`updated_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_schedules_deletedBy` FOREIGN KEY (`deleted_by`)      REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Scheduled execution. A schedule that did not fire is recorded as MISSED.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_schedule_targets  —  what to run, and ON WHICH MACHINE                        [NEW IN v7.2]  [P1]
-- ---------------------------------------------------------------------------------------------------------
-- BRD REQ-SCHED-01 asks for scheduled execution "on different machines for different modules, screens
-- or test cases". ONE machine_id column on the schedule cannot express that.
--
-- One schedule may therefore run Fees on D02A and Examination on T01A as a single nightly job.
--
-- ScheduleDispatchJob runs every minute on EVERY machine, selects the targets whose machine_code matches
-- the local machine and whose schedule is due, and creates one run per target group. A machine that is
-- switched off simply produces a missed count on its own targets — it does not block the others.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_schedule_targets` (
   `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `schedule_id`     INT UNSIGNED NOT NULL,
   `target_type`     ENUM('Module','Screen','TestCase') NOT NULL,
   `module_code`     VARCHAR(5)  NULL,
   `ts_code`         VARCHAR(11) NULL,
   `test_case_code`  VARCHAR(21) NULL,
   `machine_code`    VARCHAR(4)  NOT NULL   COMMENT 'WHICH MACHINE executes this target',
   `sequence_no`     INT UNSIGNED NOT NULL DEFAULT 1,
   `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`      VARCHAR(3) NOT NULL,
   `updated_by`      VARCHAR(3) NOT NULL,
   `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`      TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_schedTargets_dispatch` (`machine_code`,`schedule_id`,`is_active`),
   INDEX `idx_tst_schedTargets_schedule` (`schedule_id`,`target_type`),
   -- Exactly one target reference must match the declared target_type.
   CONSTRAINT `chk_tst_schedTargets_ref` CHECK (
        (`target_type` = 'Module'   AND `module_code` IS NOT NULL AND `ts_code` IS NULL AND `test_case_code` IS NULL)
     OR (`target_type` = 'Screen'   AND `ts_code` IS NOT NULL AND `test_case_code` IS NULL)
     OR (`target_type` = 'TestCase' AND `test_case_code` IS NOT NULL)),
   CONSTRAINT `fk_tst_schedTargets_schedule`  FOREIGN KEY (`schedule_id`)    REFERENCES `tst_schedules`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_schedTargets_machine`   FOREIGN KEY (`machine_code`)   REFERENCES `tst_machines`(`machine_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_schedTargets_module`    FOREIGN KEY (`module_code`)    REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_schedTargets_screen`    FOREIGN KEY (`ts_code`)        REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_schedTargets_case`      FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_schedTargets_createdBy` FOREIGN KEY (`created_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_schedTargets_updatedBy` FOREIGN KEY (`updated_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='NEW in v7.2. What a schedule runs, and on which machine.';


-- =========================================================================================================
-- SECTION 7 — COMMENTS AND DISCOVERY                                                                [P1]
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_run_annotations  —  Comments Management                                                       [P1]
-- ---------------------------------------------------------------------------------------------------------
-- Where a reviewer or a developer records what they concluded about a run or one specific result.
-- These are evidence: they consolidate with the run they belong to, and they may attribute a failure
-- to a known issue.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_run_annotations` (
   `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `run_id`          BIGINT UNSIGNED NOT NULL,
   `run_result_id`   BIGINT UNSIGNED NULL   COMMENT 'NULL when the note is about the run as a whole',
   `user_code`       VARCHAR(3) NOT NULL,
   `annotation_type` ENUM('Comment','Review','Investigation','Attribution','Decision') NOT NULL DEFAULT 'Comment',
   `comment`         VARCHAR(500) NOT NULL,
   `note`            TEXT NULL,
   `known_issue_id`  BIGINT UNSIGNED NULL   COMMENT 'FK added in Section 12',
   `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`      TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_annotations_run`    (`run_id`),
   INDEX `idx_tst_annotations_result` (`run_result_id`),
   INDEX `idx_tst_annotations_user`   (`user_code`,`created_at`),
   CONSTRAINT `fk_tst_annotations_run`    FOREIGN KEY (`run_id`)        REFERENCES `tst_test_runs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_annotations_result` FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_annotations_user`   FOREIGN KEY (`user_code`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reviewer and developer comments on runs and results. Consolidate as evidence.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_discovery_sync_logs  —  Discovery                                                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- Scans the Prime-AI source tree and reconciles what it finds against the catalog:
--   new test cases found · missing modules and screens (code with no catalog entry) ·
--   orphaned test cases (catalog entries whose implementation has gone) · status synchronisation.
--
-- DISCOVERY NEVER DELETES AND NEVER WRITES CATALOG DATA. It proposes; items wait for review.
-- Otherwise a refactor that moves a directory silently retires two hundred test cases overnight.
--
-- A rescan of an unchanged tree changes nothing (idempotent).
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_discovery_sync_logs` (
   `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`           SMALLINT UNSIGNED NOT NULL,
   `source_sync_id`       BIGINT UNSIGNED NOT NULL,
   `user_code`            VARCHAR(3) NOT NULL,
   `sync_mode`            ENUM('Discover','Import','Catalog_Bundle') NOT NULL DEFAULT 'Discover',
   `import_format`        ENUM('CSV','Excel','JSON','NDJSON','Other') NULL,
   `repository_code`      VARCHAR(100) NULL,
   `commit_hash`          VARCHAR(40) NULL   COMMENT 'The code version that was scanned',
   `folder_path`          VARCHAR(1000) NULL,
   `file_name`            VARCHAR(500) NULL,
   `file_path`            VARCHAR(1000) NULL,
   `started_at`           DATETIME NOT NULL,
   `finished_at`          DATETIME NULL,
   `duration_seconds`     DECIMAL(10,2) NULL,
   `status`               ENUM('Running','Success','Partial','Failed') NOT NULL DEFAULT 'Running',
   `modules_found`        INT UNSIGNED NOT NULL DEFAULT 0,
   `screens_found`        INT UNSIGNED NOT NULL DEFAULT 0,
   `missing_modules`      INT UNSIGNED NOT NULL DEFAULT 0  COMMENT 'Code with no catalog entry',
   `missing_screens`      INT UNSIGNED NOT NULL DEFAULT 0,
   `test_cases_found`     INT UNSIGNED NOT NULL DEFAULT 0,
   `test_cases_added`     INT UNSIGNED NOT NULL DEFAULT 0,
   `test_cases_updated`   INT UNSIGNED NOT NULL DEFAULT 0,
   `test_cases_orphaned`  INT UNSIGNED NOT NULL DEFAULT 0,
   `test_cases_unchanged` INT UNSIGNED NOT NULL DEFAULT 0,
   `items_pending_review` INT UNSIGNED NOT NULL DEFAULT 0  COMMENT 'Proposals awaiting a human',
   `details_json`         JSON NULL,
   `error_message`        TEXT NULL,
   `created_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_discovery_source` (`machine_id`,`source_sync_id`),
   INDEX `idx_tst_discovery_status` (`status`,`started_at`),
   CONSTRAINT `fk_tst_discovery_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_discovery_user`    FOREIGN KEY (`user_code`)  REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Discovery runs. Discovery proposes; it never writes catalog data or deletes.';


-- =========================================================================================================
-- SECTION 8 — DEFECTS                                                                               [P1]
-- =========================================================================================================
--     THREE DISTINCT CONCEPTS that earlier versions partly conflated:
--
--       Known Issue   an accepted, documented problem whose recurrence is EXPECTED
--       Bug           ONE problem in Prime-AI
--       Occurrence    ONE observation of that problem in ONE result   (one bug -> many occurrences)
--
--     Conflating bug and occurrence inflates defect counts and makes triage duplicate itself.
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_known_issues` (
   `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `issue_code`          VARCHAR(40) NOT NULL,
   `title`               VARCHAR(255) NOT NULL,
   `description`         TEXT NULL,
   `rationale`           TEXT NULL   COMMENT 'WHY it is accepted rather than fixed. Without this, nobody can re-judge it',
   `category`            ENUM('Product_Limitation','Environment','Third_Party','Test_Data','Deferred_Defect',
                              'Infrastructure','Other') NOT NULL DEFAULT 'Deferred_Defect',
   `module_code`         VARCHAR(5)  NULL,
   `ts_code`             VARCHAR(11) NULL,
   `failure_fingerprint` CHAR(64) NULL   COMMENT 'Auto-attributes matching failures, so they are not re-triaged',
   `owner_user_code`     VARCHAR(3) NOT NULL,
   `status`              ENUM('Active','Expired','Promoted_To_Bug','Resolved','Withdrawn') NOT NULL DEFAULT 'Active',
   `review_due_at`       DATE NULL   COMMENT 'On expiry it reverts to normal defect treatment and notifies the owner',
   `expired_at`          DATETIME NULL,
   `promoted_bug_id`     BIGINT UNSIGNED NULL   COMMENT 'FK added in Section 12',
   `occurrence_count`    BIGINT UNSIGNED NOT NULL DEFAULT 0,
   `first_seen_at`       DATETIME NULL,
   `last_seen_at`        DATETIME NULL,
   `created_by`          VARCHAR(3) NOT NULL,
   `updated_by`          VARCHAR(3) NOT NULL,
   `deleted_by`          VARCHAR(3) NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`          TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_knownIssues_code` (`issue_code`),
   INDEX `idx_tst_knownIssues_status`      (`status`,`review_due_at`),
   INDEX `idx_tst_knownIssues_fingerprint` (`failure_fingerprint`),
   INDEX `idx_tst_knownIssues_area`        (`module_code`,`ts_code`),
   CONSTRAINT `fk_tst_knownIssues_module`    FOREIGN KEY (`module_code`)     REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_knownIssues_screen`    FOREIGN KEY (`ts_code`)         REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_knownIssues_owner`     FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_knownIssues_createdBy` FOREIGN KEY (`created_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_knownIssues_updatedBy` FOREIGN KEY (`updated_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_knownIssues_deletedBy` FOREIGN KEY (`deleted_by`)      REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Accepted problems whose recurrence is expected. review_due_at forces a re-judgement.';


CREATE TABLE IF NOT EXISTS `tst_known_issue_results` (
   `known_issue_id` BIGINT UNSIGNED NOT NULL,
   `run_result_id`  BIGINT UNSIGNED NOT NULL,
   `attributed_by`  VARCHAR(3) NULL   COMMENT 'NULL when attributed automatically by fingerprint',
   `note`           VARCHAR(500) NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`known_issue_id`,`run_result_id`),
   INDEX `idx_tst_kiResults_result` (`run_result_id`),
   CONSTRAINT `fk_tst_kiResults_issue`  FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_kiResults_result` FOREIGN KEY (`run_result_id`)  REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_kiResults_by`     FOREIGN KEY (`attributed_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Every recurrence of a known issue stays recorded and countable.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_bugs  —  ONE problem in Prime-AI                                                              [P1]
-- ---------------------------------------------------------------------------------------------------------
-- FIXED DOES NOT EQUAL VERIFIED (BRD R-08). verified_result_id must point at a PASSING retest result.
-- A bug may be closed without one only through verification_override, which requires a reason and is
-- reportable — so the exception is visible rather than indistinguishable from a real verification.
--
-- release_id is REMOVED in v7.2: the Release entity is gone (BRD D-26).
-- change_request_id is a Phase-2 column, declared now, FK added in Section 30.
-- module_code is VARCHAR(5) here — v7.1 declared VARCHAR(10) against a VARCHAR(5) parent.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_bugs` (
   `id`                           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `origin_machine_id`            SMALLINT UNSIGNED NOT NULL,
   `source_bug_id`                BIGINT UNSIGNED NOT NULL,
   `bug_code`                     VARCHAR(30) NULL   COMMENT 'Display code, e.g. BUG-000412',
   `discovered_by`                VARCHAR(3) NULL,
   `first_detected_run_id`        BIGINT UNSIGNED NULL,
   `first_detected_result_id`     BIGINT UNSIGNED NULL,
   `module_code`                  VARCHAR(5)  NOT NULL,   -- v7.2: was VARCHAR(10) against a VARCHAR(5) parent
   `ts_code`                      VARCHAR(11) NULL,
   `test_case_code`               VARCHAR(21) NULL,
   `change_request_id`            BIGINT UNSIGNED NULL    COMMENT '[P2] FK added in Section 30',
   `failure_signature_id`         BIGINT UNSIGNED NULL    COMMENT 'FK added in Section 12',
   `title`                        VARCHAR(255) NOT NULL,
   `description`                  TEXT NULL,
   `steps_to_reproduce`           TEXT NULL,
   `expected_behaviour`           TEXT NULL,
   `actual_behaviour`             TEXT NULL,
   `severity`                     ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `priority`                     ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `status`                       ENUM('Open','Assigned','In_Progress','Fixed','Retesting','Reopened',
                                       'Closed','Escalated','Wont_Fix','Duplicate') NOT NULL DEFAULT 'Open',
   `resolution`                   ENUM('Fixed','Not_A_Defect','Duplicate','Cannot_Reproduce','Wont_Fix',
                                       'Known_Issue','Test_Defect','Environment') NULL,
   `root_cause_category`          ENUM('Logic','Validation','Data','Tenancy','Permission','Integration','UI',
                                       'Performance','Configuration','Environment','Test_Defect','Other') NULL,
   `root_cause_note`              TEXT NULL,
   `environment_profile_id`       INT UNSIGNED NULL,
   `observed_commit_hash`         VARCHAR(40) NULL,
   -- ---- Assignment and SLA ------------------------------------------------------------------------------
   `assigned_to`                  VARCHAR(3) NULL,
   `assigned_by`                  VARCHAR(3) NULL,
   `assigned_at`                  DATETIME NULL,
   `sla_due_at`                   DATETIME NULL,
   `sla_breached`                 TINYINT(1) NOT NULL DEFAULT 0   COMMENT 'Recorded, not merely alerted',
   -- ---- Fix and verification ----------------------------------------------------------------------------
   `fixed_by`                     VARCHAR(3) NULL,
   `fixed_at`                     DATETIME NULL,
   `fixed_commit_hash`            VARCHAR(40) NULL,
   `fix_notes`                    TEXT NULL,
   `verified_by`                  VARCHAR(3) NULL,
   `verified_at`                  DATETIME NULL,
   `verified_result_id`           BIGINT UNSIGNED NULL   COMMENT 'Must be a PASSING retest result',
   `verification_override`        TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'Closed without a passing retest',
   `verification_override_reason` VARCHAR(1000) NULL,
   `reopen_count`                 SMALLINT UNSIGNED NOT NULL DEFAULT 0,
   `occurrence_count`             INT UNSIGNED NOT NULL DEFAULT 0,
   `retest_attempt_count`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
   `escalated_at`                 DATETIME NULL,
   `escalation_reason`            VARCHAR(500) NULL,
   `duplicate_of_bug_id`          BIGINT UNSIGNED NULL,
   `known_issue_id`               BIGINT UNSIGNED NULL,
   `closed_by`                    VARCHAR(3) NULL,
   `closed_at`                    DATETIME NULL,
   `created_by`                   VARCHAR(3) NOT NULL,
   `updated_by`                   VARCHAR(3) NOT NULL,
   `deleted_by`                   VARCHAR(3) NULL,
   `created_at`                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`                   TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_bugs_source` (`origin_machine_id`,`source_bug_id`),
   UNIQUE KEY `uq_tst_bugs_code`   (`bug_code`),
   INDEX `idx_tst_bugs_status`     (`status`,`severity`),
   INDEX `idx_tst_bugs_assigned`   (`assigned_to`,`status`),
   INDEX `idx_tst_bugs_case`       (`test_case_code`),
   INDEX `idx_tst_bugs_area`       (`module_code`,`ts_code`),
   INDEX `idx_tst_bugs_sla`        (`sla_due_at`,`sla_breached`),
   INDEX `idx_tst_bugs_signature`  (`failure_signature_id`),
   INDEX `idx_tst_bugs_duplicate`  (`duplicate_of_bug_id`),
   CONSTRAINT `chk_tst_bugs_override` CHECK (`verification_override` = 0 OR `verification_override_reason` IS NOT NULL),
   CONSTRAINT `fk_tst_bugs_machine`     FOREIGN KEY (`origin_machine_id`)      REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_bugs_module`      FOREIGN KEY (`module_code`)            REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_bugs_screen`      FOREIGN KEY (`ts_code`)                REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_case`        FOREIGN KEY (`test_case_code`)         REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_env`         FOREIGN KEY (`environment_profile_id`) REFERENCES `tst_environment_profiles`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_firstRun`    FOREIGN KEY (`first_detected_run_id`)  REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_firstResult` FOREIGN KEY (`first_detected_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_verified`    FOREIGN KEY (`verified_result_id`)     REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_duplicate`   FOREIGN KEY (`duplicate_of_bug_id`)    REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_knownIssue`  FOREIGN KEY (`known_issue_id`)         REFERENCES `tst_known_issues`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_discoveredBy` FOREIGN KEY (`discovered_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_assignedTo`  FOREIGN KEY (`assigned_to`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_assignedBy`  FOREIGN KEY (`assigned_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_fixedBy`     FOREIGN KEY (`fixed_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_verifiedBy`  FOREIGN KEY (`verified_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_closedBy`    FOREIGN KEY (`closed_by`)    REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugs_createdBy`   FOREIGN KEY (`created_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_bugs_updatedBy`   FOREIGN KEY (`updated_by`)   REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_bugs_deletedBy`   FOREIGN KEY (`deleted_by`)   REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ONE problem in Prime-AI. Fixed does not equal verified (R-08).';


CREATE TABLE IF NOT EXISTS `tst_bug_occurrences` (
   `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `bug_id`          BIGINT UNSIGNED NOT NULL,
   `run_result_id`   BIGINT UNSIGNED NOT NULL,
   `occurrence_type` ENUM('First_Detected','Reproduced','Regression','Retest_Failed','Retest_Passed','Other')
                       NOT NULL DEFAULT 'Reproduced',
   `matched_by`      ENUM('Manual','Fingerprint','AI_Proposal') NOT NULL DEFAULT 'Manual',
   `confirmed_by`    VARCHAR(3) NULL,
   `note`            VARCHAR(500) NULL,
   `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_bugOcc` (`bug_id`,`run_result_id`),
   INDEX `idx_tst_bugOcc_result` (`run_result_id`),
   CONSTRAINT `fk_tst_bugOcc_bug`         FOREIGN KEY (`bug_id`)        REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_bugOcc_result`      FOREIGN KEY (`run_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_bugOcc_confirmedBy` FOREIGN KEY (`confirmed_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One observation of one bug in one result. NOT the same concept as the bug.';


CREATE TABLE IF NOT EXISTS `tst_bug_status_history` (
   `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `bug_id`           BIGINT UNSIGNED NOT NULL,
   `from_status`      VARCHAR(30) NULL,
   `to_status`        VARCHAR(30) NOT NULL,
   `from_assignee`    VARCHAR(3) NULL,
   `to_assignee`      VARCHAR(3) NULL,
   `changed_by`       VARCHAR(3) NULL   COMMENT 'The system user for an automatic transition',
   `is_system_action` TINYINT(1) NOT NULL DEFAULT 0,
   `note`             TEXT NULL,
   `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_bugHistory_bug` (`bug_id`,`created_at`),
   CONSTRAINT `fk_tst_bugHistory_bug`       FOREIGN KEY (`bug_id`)        REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_bugHistory_changedBy` FOREIGN KEY (`changed_by`)    REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugHistory_fromUser`  FOREIGN KEY (`from_assignee`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugHistory_toUser`    FOREIGN KEY (`to_assignee`)   REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Every bug status transition. Insert-only.';


CREATE TABLE IF NOT EXISTS `tst_bug_comments` (
   `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `bug_id`      BIGINT UNSIGNED NOT NULL,
   `user_code`   VARCHAR(3) NOT NULL,
   `comment`     TEXT NOT NULL,
   `is_internal` TINYINT(1) NOT NULL DEFAULT 0,
   `created_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`  TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_bugComments_bug` (`bug_id`,`created_at`),
   CONSTRAINT `fk_tst_bugComments_bug`  FOREIGN KEY (`bug_id`)    REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_bugComments_user` FOREIGN KEY (`user_code`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Discussion on a bug.';


CREATE TABLE IF NOT EXISTS `tst_bug_links` (
   `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `bug_id`        BIGINT UNSIGNED NOT NULL,
   `linked_bug_id` BIGINT UNSIGNED NOT NULL,
   `link_type`     ENUM('Proposed_Duplicate','Duplicate_Of','Related','Blocks','Blocked_By',
                        'Caused_By','Causes','Regression_Of') NOT NULL,
   `score`         DECIMAL(4,3) NULL,
   `evidence_json` JSON NULL,
   `proposed_by`   VARCHAR(3) NULL,
   `decided_by`    VARCHAR(3) NULL,
   `decided_at`    DATETIME NULL,
   `note`          VARCHAR(500) NULL,
   `superseded_at` DATETIME NULL   COMMENT 'Insert-only: a reversal supersedes rather than deletes',
   `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_bugLinks_bug`    (`bug_id`,`link_type`),
   INDEX `idx_tst_bugLinks_linked` (`linked_bug_id`),
   INDEX `idx_tst_bugLinks_open`   (`link_type`,`superseded_at`),
   CONSTRAINT `chk_tst_bugLinks_notSelf` CHECK (`bug_id` <> `linked_bug_id`),
   CONSTRAINT `fk_tst_bugLinks_bug`        FOREIGN KEY (`bug_id`)        REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_bugLinks_linked`     FOREIGN KEY (`linked_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_bugLinks_proposedBy` FOREIGN KEY (`proposed_by`)   REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_bugLinks_decidedBy`  FOREIGN KEY (`decided_by`)    REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Relationships between bugs. Insert-only; reversals supersede.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_retest_cycles  —  verifying a fix                                                             [P1]
-- ---------------------------------------------------------------------------------------------------------
-- THE RETEST NEVER OVERWRITES THE ORIGINAL FAILURE (BRD R-09). It is a new run producing new results;
-- the evidence of what went wrong survives, which is the only way a reopened bug can be argued about.
--
-- Cycles are numbered per bug and bounded by max_auto_retest_attempts, after which the bug ESCALATES
-- rather than looping. Automation with no bound is how a broken fix generates four hundred runs
-- overnight (BRD R-14).
--
-- The 'Screen_Plus_Dependencies' scope policy is selectable in Phase 1 but its dependency limb only
-- resolves once tst_test_case_dependencies exists in Phase 2; until then it behaves as 'Screen'.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_retest_cycles` (
   `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `bug_id`         BIGINT UNSIGNED NOT NULL,
   `cycle_number`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `trigger_source` ENUM('Auto_On_Fixed','Manual','Scheduled','Release_Gate') NOT NULL DEFAULT 'Auto_On_Fixed',
   `triggered_by`   VARCHAR(3) NULL,
   `triggered_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `run_id`         BIGINT UNSIGNED NULL,
   `scope_policy`   ENUM('Test_Only','Screen','Screen_Plus_Dependencies','Module','Regression_Suite')
                      NOT NULL DEFAULT 'Screen',
   `scope_json`     JSON NULL,
   `status`         ENUM('Pending','Running','Passed','Failed','Not_Covered','Cancelled') NOT NULL DEFAULT 'Pending',
   `completed_at`   DATETIME NULL,
   `note`           VARCHAR(1000) NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_retestCycles` (`bug_id`,`cycle_number`),
   INDEX `idx_tst_retestCycles_status` (`status`,`triggered_at`),
   CONSTRAINT `fk_tst_retestCycles_bug`         FOREIGN KEY (`bug_id`)       REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_retestCycles_run`         FOREIGN KEY (`run_id`)       REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_retestCycles_triggeredBy` FOREIGN KEY (`triggered_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One managed attempt to verify a fix. Bounded, so automation cannot loop.';


CREATE TABLE IF NOT EXISTS `tst_retest_cycle_bugs` (
   `retest_cycle_id`     BIGINT UNSIGNED NOT NULL,
   `bug_id`              BIGINT UNSIGNED NOT NULL,
   `outcome`             ENUM('Pending','Passed','Failed','Not_Covered','Blocked') NOT NULL DEFAULT 'Pending',
   `verifying_result_id` BIGINT UNSIGNED NULL,
   `note`                VARCHAR(500) NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`retest_cycle_id`,`bug_id`),
   INDEX `idx_tst_retestBugs_bug` (`bug_id`),
   CONSTRAINT `fk_tst_retestBugs_cycle`  FOREIGN KEY (`retest_cycle_id`)     REFERENCES `tst_retest_cycles`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_retestBugs_bug`    FOREIGN KEY (`bug_id`)              REFERENCES `tst_bugs`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_retestBugs_result` FOREIGN KEY (`verifying_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One retest cycle may verify several bugs.';


-- =========================================================================================================
-- SECTION 9 — EXPORT, IMPORT, RECORD MAP AND CONFLICTS                                              [P1]
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_data_exports` (
   `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`          SMALLINT UNSIGNED NOT NULL,
   `source_export_id`    BIGINT UNSIGNED NOT NULL,
   `user_code`           VARCHAR(3) NOT NULL,
   `export_name`         VARCHAR(200) NOT NULL,
   `export_type`         ENUM('Full','Incremental','Selected','Catalog_Bundle') NOT NULL DEFAULT 'Incremental',
   `direction`           ENUM('Evidence_Out','Catalog_Out') NOT NULL DEFAULT 'Evidence_Out',
   `date_from`           DATETIME NULL,
   `date_to`             DATETIME NULL,
   `modules_json`        JSON NULL,
   `app_version`         VARCHAR(20) NOT NULL,
   `schema_version`      VARCHAR(20) NOT NULL   COMMENT 'Read from tst_app_settings; the importer compares it',
   `file_path`           VARCHAR(1000) NULL,
   `file_bytes`          BIGINT UNSIGNED NULL,
   `manifest_json`       JSON NULL   COMMENT 'Counts, per-file checksums, period, source identity',
   `record_counts_json`  JSON NULL,
   `artifact_count`      INT UNSIGNED NOT NULL DEFAULT 0,
   `includes_artifacts`  TINYINT(1) NOT NULL DEFAULT 1,
   `status`              ENUM('Pending','In_Progress','Completed','Failed') NOT NULL DEFAULT 'Pending',
   `error_message`       TEXT NULL,
   `exported_at`         DATETIME NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_exports_source` (`machine_id`,`source_export_id`),
   INDEX `idx_tst_exports_status` (`status`,`created_at`),
   CONSTRAINT `fk_tst_exports_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_exports_user`    FOREIGN KEY (`user_code`)  REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Export bundles. direction says whether this is catalog out or evidence in.';


CREATE TABLE IF NOT EXISTS `tst_data_imports` (
   `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `source_machine_id`      SMALLINT UNSIGNED NOT NULL,
   `source_export_id`       BIGINT UNSIGNED NOT NULL,
   `imported_by`            VARCHAR(3) NOT NULL,
   `file_name`              VARCHAR(500) NULL,
   `source_app_version`     VARCHAR(20) NULL,
   `source_schema_version`  VARCHAR(20) NULL,
   `version_decision`       ENUM('Same_Version','Migrated_On_Read','Rejected_Incompatible') NULL,
   `version_decision_note`  VARCHAR(500) NULL,
   `status`                 ENUM('Received','Validating','Applying','Completed','Partial','Rejected','Reversed')
                              NOT NULL DEFAULT 'Received',
   `started_at`             DATETIME NULL,
   `finished_at`            DATETIME NULL,
   `records_created`        INT UNSIGNED NOT NULL DEFAULT 0,
   `records_matched`        INT UNSIGNED NOT NULL DEFAULT 0  COMMENT 'Already present; skipped. This is idempotency working',
   `records_rejected`       INT UNSIGNED NOT NULL DEFAULT 0,
   `conflict_count`         INT UNSIGNED NOT NULL DEFAULT 0,
   `open_conflict_count`    INT UNSIGNED NOT NULL DEFAULT 0,
   `record_counts_json`     JSON NULL,
   `manifest_json`          JSON NULL,
   `error_message`          TEXT NULL,
   `reversed_by`            VARCHAR(3) NULL,
   `reversed_at`            DATETIME NULL,
   `reversal_reason`        VARCHAR(500) NULL,
   `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_imports_sourceExport` (`source_machine_id`,`source_export_id`),
   INDEX `idx_tst_imports_status` (`status`,`created_at`),
   CONSTRAINT `chk_tst_imports_reversal` CHECK (`status` <> 'Reversed' OR `reversal_reason` IS NOT NULL),
   CONSTRAINT `fk_tst_imports_machine`    FOREIGN KEY (`source_machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_imports_by`         FOREIGN KEY (`imported_by`)       REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_imports_reversedBy` FOREIGN KEY (`reversed_by`)       REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Import runs. Idempotent by design; reversible via the record map.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_import_record_map  —  what makes an import reversible                                         [P1]
-- ---------------------------------------------------------------------------------------------------------
-- Every record an import created or matched, with its source identity and the local id it was given.
-- Without this table an import cannot be withdrawn, and a bad merge becomes permanent (BRD R-11).
--
-- source_code carries the BUSINESS CODE for catalog and test-case entities. Under the new coding system
-- most resolutions are now by code rather than by id, which is why source_id is nullable.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_import_record_map` (
   `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `import_id`         BIGINT UNSIGNED NOT NULL,
   `entity_type`       VARCHAR(64) NOT NULL   COMMENT 'e.g. tst_test_runs',
   `source_machine_id` SMALLINT UNSIGNED NOT NULL,
   `source_id`         BIGINT UNSIGNED NULL   COMMENT 'The local id it had on the source machine',
   `source_code`       VARCHAR(120) NULL      COMMENT 'Or its business code — now the usual case',
   `local_id`          BIGINT UNSIGNED NULL,
   `local_code`        VARCHAR(120) NULL,
   `action`            ENUM('Created','Matched','Updated','Skipped') NOT NULL,
   `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_importMap` (`entity_type`,`source_machine_id`,`source_id`,`source_code`),
   INDEX `idx_tst_importMap_import` (`import_id`),
   INDEX `idx_tst_importMap_local`  (`entity_type`,`local_id`),
   CONSTRAINT `fk_tst_importMap_import` FOREIGN KEY (`import_id`) REFERENCES `tst_data_imports`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Every record an import touched. This is what makes an import reversible.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_import_conflicts  —  queued, never resolved by a coin toss                                    [P1]
-- ---------------------------------------------------------------------------------------------------------
-- BOTH VERSIONS ARE RETAINED IN FULL. Nothing is discarded, because the resolution is a judgement and
-- the person making it needs to see what they are choosing between.
--
-- 'Duplicate_Business_Code' MEANS SOMETHING NEW IN v7.2 (BRD D-31).
--   Under v7.0 two machines minting the same test-case number was ROUTINE, and the whole source/canonical
--   layer existed to absorb it. Under the new coding system it can only mean A MACHINE CODE WAS REUSED —
--   two installations registered as D02A. That silently merges two machines' evidence, so it is
--   classified BLOCKING and surfaced as an operational alert, not a data-quality note.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_import_conflicts` (
   `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `import_id`        BIGINT UNSIGNED NOT NULL,
   `conflict_type`    ENUM('Missing_Catalog_Reference','Definition_Divergence','Machine_Metadata_Mismatch',
                           'Duplicate_Business_Code','Version_Incompatible','Referential_Gap','Other') NOT NULL,
   `entity_type`      VARCHAR(64) NOT NULL,
   `source_identity`  VARCHAR(255) NULL   COMMENT 'How the record identified itself in the bundle',
   `local_record_id`  BIGINT UNSIGNED NULL,
   `local_record_code` VARCHAR(120) NULL,
   `severity`         ENUM('Blocking','Warning') NOT NULL DEFAULT 'Blocking',
   `description`      VARCHAR(1000) NOT NULL,
   `incoming_json`    JSON NULL   COMMENT 'Retained in full; nothing is discarded',
   `existing_json`    JSON NULL,
   `status`           ENUM('Open','Resolved_Keep_Existing','Resolved_Accept_Incoming','Resolved_Manual','Ignored')
                        NOT NULL DEFAULT 'Open',
   `resolved_by`      VARCHAR(3) NULL,
   `resolved_at`      DATETIME NULL,
   `resolution_note`  VARCHAR(1000) NULL,
   `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_conflicts_import` (`import_id`,`status`),
   INDEX `idx_tst_conflicts_type`   (`conflict_type`,`severity`),
   CONSTRAINT `fk_tst_conflicts_import`     FOREIGN KEY (`import_id`)   REFERENCES `tst_data_imports`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_conflicts_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Import conflicts. Queued for a person; both versions retained in full.';


-- =========================================================================================================
-- SECTION 10 — AI ANALYSES AND RECOMMENDATIONS                                                      [P1]
-- =========================================================================================================
--     AI ASSISTS; IT DOES NOT DECIDE (BRD R-12). Nothing here mutates record data. Every output is a
--     proposal with evidence, a confidence score and a review state, and a named person accepts or
--     rejects it.
--
--     The `outcome` column on a recommendation is the part people skip and shouldn't: recording whether
--     an accepted recommendation turned out to be CORRECT is what makes the AI's usefulness measurable
--     rather than assumed (KPI K-10).
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_ai_analyses` (
   `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`         SMALLINT UNSIGNED NOT NULL,
   `source_analysis_id` BIGINT UNSIGNED NOT NULL,
   `analysis_type`      ENUM('Duplicate_Test_Case','Duplicate_Bug','Failure_Cluster','Flaky_Assessment',
                             'Regression_Assessment','Failure_Reason','Consecutive_Failure_Diagnosis',
                             'Impact_Proposal','Coverage_Gap','Recommendation') NOT NULL,
   `scope_description`  VARCHAR(500) NULL,
   `scope_json`         JSON NULL,
   `provider`           VARCHAR(50) NULL,
   `model`              VARCHAR(100) NULL,
   `prompt_version`     VARCHAR(30) NULL   COMMENT 'So a conclusion can be reproduced or explained',
   `input_tokens`       INT UNSIGNED NULL,
   `output_tokens`      INT UNSIGNED NULL,
   `duration_ms`        INT UNSIGNED NULL,
   `status`             ENUM('Queued','Running','Completed','Failed') NOT NULL DEFAULT 'Queued',
   `error_message`      TEXT NULL,
   `requested_by`       VARCHAR(3) NOT NULL,
   `created_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_aiAnalyses_source` (`machine_id`,`source_analysis_id`),
   INDEX `idx_tst_aiAnalyses_type` (`analysis_type`,`status`),
   CONSTRAINT `fk_tst_aiAnalyses_machine`     FOREIGN KEY (`machine_id`)   REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_aiAnalyses_requestedBy` FOREIGN KEY (`requested_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='AI analysis runs, with full provenance so a conclusion can be reproduced.';


CREATE TABLE IF NOT EXISTS `tst_ai_recommendations` (
   `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `analysis_id`         BIGINT UNSIGNED NOT NULL,
   `recommendation_type` ENUM('Link_Test_Cases','Link_Bugs','Attribute_To_Bug','Attribute_To_Known_Issue',
                              'Mark_Flaky','Mark_Regression','Create_Test_Case','Retire_Test_Case',
                              'Select_For_Run','Investigate','Other') NOT NULL,
   `target_entity_type`  VARCHAR(64) NULL,
   `target_entity_id`    BIGINT UNSIGNED NULL,
   `target_entity_code`  VARCHAR(120) NULL   COMMENT 'v7.2: code-addressable targets, e.g. a test_case_code',
   `related_entity_id`   BIGINT UNSIGNED NULL,
   `related_entity_code` VARCHAR(120) NULL,
   `title`               VARCHAR(255) NOT NULL,
   `recommendation`      TEXT NOT NULL,
   `confidence`          DECIMAL(4,3) NOT NULL DEFAULT 0.500,
   `evidence_json`       JSON NULL   COMMENT 'The recorded facts relied upon. A recommendation without this is an opinion',
   `review_state`        ENUM('Proposed','Accepted','Rejected','Superseded','Expired') NOT NULL DEFAULT 'Proposed',
   `reviewed_by`         VARCHAR(3) NULL,
   `reviewed_at`         DATETIME NULL,
   `review_note`         VARCHAR(1000) NULL,
   `outcome`             ENUM('Correct','Incorrect','Partially_Correct','Unknown') NOT NULL DEFAULT 'Unknown',
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   INDEX `idx_tst_aiRec_analysis` (`analysis_id`),
   INDEX `idx_tst_aiRec_state`    (`review_state`,`confidence`),
   INDEX `idx_tst_aiRec_target`   (`target_entity_type`,`target_entity_code`),
   CONSTRAINT `chk_tst_aiRec_confidence` CHECK (`confidence` BETWEEN 0 AND 1),
   CONSTRAINT `fk_tst_aiRec_analysis`   FOREIGN KEY (`analysis_id`)  REFERENCES `tst_ai_analyses`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_aiRec_reviewedBy` FOREIGN KEY (`reviewed_by`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Proposals with evidence, confidence and a review state. AI never mutates record data.';


-- =========================================================================================================
-- SECTION 11 — NOTIFICATIONS AND AUDIT                                                              [P1]
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- tst_notifications                                                                                 [P1]
-- ---------------------------------------------------------------------------------------------------------
-- DEDUPLICATED BY KEY, with an occurrence count and first/last event times. Forty identical failures
-- produce ONE notification that says forty. A system that sends forty is a system people mute.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_notifications` (
   `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `recipient_code`   VARCHAR(3) NOT NULL,
   `event_type`       ENUM('Critical_Test_Failure','New_Critical_Bug','Bug_Assigned','Bug_Ready_For_Retest',
                           'Retest_Failed','SLA_Breach','Schedule_Missed','Import_Conflict',
                           'Known_Issue_Expired','Discovery_Anomaly','Export_Ready','Review_Requested',
                           'Regression_Detected','Other') NOT NULL,
   `severity`         ENUM('Info','Warning','Critical') NOT NULL DEFAULT 'Info',
   `entity_type`      VARCHAR(64) NULL,
   `entity_id`        BIGINT UNSIGNED NULL,
   `entity_code`      VARCHAR(120) NULL   COMMENT 'v7.2: for code-addressed entities',
   `title`            VARCHAR(255) NOT NULL,
   `body`             TEXT NULL,
   `action_url`       VARCHAR(500) NULL,
   `dedupe_key`       VARCHAR(191) NOT NULL,
   `occurrence_count` INT UNSIGNED NOT NULL DEFAULT 1,
   `first_event_at`   DATETIME NOT NULL,
   `last_event_at`    DATETIME NOT NULL,
   `channel`          ENUM('In_App','Email','Digest') NOT NULL DEFAULT 'In_App',
   `delivered_at`     DATETIME NULL,
   `read_at`          DATETIME NULL,
   `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_notifications_dedupe` (`recipient_code`,`dedupe_key`),
   INDEX `idx_tst_notifications_unread` (`recipient_code`,`read_at`,`created_at`),
   INDEX `idx_tst_notifications_event`  (`event_type`,`severity`),
   CONSTRAINT `fk_tst_notifications_recipient` FOREIGN KEY (`recipient_code`) REFERENCES `tst_users`(`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Deduplicated notifications. Forty failures produce one notification saying forty.';


-- ---------------------------------------------------------------------------------------------------------
-- tst_audit_logs                                                                                    [P1]
-- ---------------------------------------------------------------------------------------------------------
-- INSERT-ONLY. record_key carries the business code for code-keyed tables, which is now most of them —
-- an audit row saying "tst_test_cases id 41207 changed" is unreadable on a different machine, whereas
-- "D02A_T0104010200_001" is readable everywhere.
--
-- is_system_action distinguishes automation from a person, so "who did this?" never answers "the system"
-- when it means "the retest engine, on behalf of a rule someone configured".
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tst_audit_logs` (
   `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`       SMALLINT UNSIGNED NOT NULL,
   `source_audit_id`  BIGINT UNSIGNED NOT NULL,
   `user_code`        VARCHAR(3) NULL,
   `is_system_action` TINYINT(1) NOT NULL DEFAULT 0,
   `table_name`       VARCHAR(100) NOT NULL,
   `record_id`        BIGINT UNSIGNED NULL,
   `record_key`       VARCHAR(255) NULL   COMMENT 'The business code, for code-keyed tables',
   `operation`        ENUM('INSERT','UPDATE','DELETE','RESTORE','PURGE','LOGIN','PERMISSION_DENIED',
                           'EXPORT','IMPORT') NOT NULL,
   `old_values_json`  JSON NULL,
   `new_values_json`  JSON NULL,
   `context`          VARCHAR(255) NULL   COMMENT 'The service or command responsible',
   `ip_address`       VARCHAR(45) NULL,
   `user_agent`       VARCHAR(1000) NULL,
   `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_audit_source` (`machine_id`,`source_audit_id`),
   INDEX `idx_tst_audit_table`  (`table_name`,`record_key`),
   INDEX `idx_tst_audit_record` (`table_name`,`record_id`),
   INDEX `idx_tst_audit_user`   (`user_code`,`created_at`),
   INDEX `idx_tst_audit_when`   (`created_at`),
   CONSTRAINT `fk_tst_audit_machine` FOREIGN KEY (`machine_id`) REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_audit_user`    FOREIGN KEY (`user_code`)  REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='INSERT-ONLY audit. record_key carries the business code, readable on any machine.';


-- =========================================================================================================
-- SECTION 12 — PHASE-1 DEFERRED CONSTRAINTS                                                         [P1]
-- =========================================================================================================
--     Foreign keys whose target table is created later in Phase 1. Each is guarded by an
--     information_schema lookup and executed through PREPARE, because MySQL has no
--     ADD CONSTRAINT IF NOT EXISTS and this whole script must stay re-runnable.
--
--     No DELIMITER directive is used, so the script also runs through tools that do not support one.
--
--     v7.2: the v7.1 block also added foreign keys to tst_releases and tst_roles, both of which had
--     been removed. Those statements are gone.
-- =========================================================================================================

-- A run may belong to a schedule (tst_schedules is created after tst_test_runs).
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_testRuns_schedule already present'' AS skipped',
      'ALTER TABLE `tst_test_runs` ADD CONSTRAINT `fk_tst_testRuns_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `tst_schedules`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_test_runs' AND constraint_name = 'fk_tst_testRuns_schedule');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A run scope may name a bug.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_runScopes_bug already present'' AS skipped',
      'ALTER TABLE `tst_test_run_scopes` ADD CONSTRAINT `fk_tst_runScopes_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_test_run_scopes' AND constraint_name = 'fk_tst_runScopes_bug');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A failed result belongs to a failure-signature group.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_results_signature already present'' AS skipped',
      'ALTER TABLE `tst_test_run_results` ADD CONSTRAINT `fk_tst_results_signature` FOREIGN KEY (`failure_signature_id`) REFERENCES `tst_failure_signatures`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_test_run_results' AND constraint_name = 'fk_tst_results_signature');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A signature carries a sample result and, once triaged, its bug or known issue.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_failureSig_sample already present'' AS skipped',
      'ALTER TABLE `tst_failure_signatures` ADD CONSTRAINT `fk_tst_failureSig_sample` FOREIGN KEY (`sample_result_id`) REFERENCES `tst_test_run_results`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_failureSig_bug` FOREIGN KEY (`bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_failureSig_known` FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_failure_signatures' AND constraint_name = 'fk_tst_failureSig_sample');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A bug may carry a failure signature.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_bugs_signature already present'' AS skipped',
      'ALTER TABLE `tst_bugs` ADD CONSTRAINT `fk_tst_bugs_signature` FOREIGN KEY (`failure_signature_id`) REFERENCES `tst_failure_signatures`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_bugs' AND constraint_name = 'fk_tst_bugs_signature');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A known issue may be promoted to a bug, retaining its occurrence history.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_knownIssues_promotedBug already present'' AS skipped',
      'ALTER TABLE `tst_known_issues` ADD CONSTRAINT `fk_tst_knownIssues_promotedBug` FOREIGN KEY (`promoted_bug_id`) REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_known_issues' AND constraint_name = 'fk_tst_knownIssues_promotedBug');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A note may attribute a failure to a known issue.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_annotations_knownIssue already present'' AS skipped',
      'ALTER TABLE `tst_run_annotations` ADD CONSTRAINT `fk_tst_annotations_knownIssue` FOREIGN KEY (`known_issue_id`) REFERENCES `tst_known_issues`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_run_annotations' AND constraint_name = 'fk_tst_annotations_knownIssue');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;


-- =========================================================================================================
-- SECTION 13 — PHASE-1 VIEWS                                                                        [P1]
-- =========================================================================================================
--     Every view derives from RECORDED RESULTS, never from a current-status column alone.
--     Views for dashboards read the summary table; views for investigation read the results table and
--     are always used with a filter.
--
--     v7.2: EVERY VIEW IS REWRITTEN TO JOIN ON CODES. v7.1's views all joined tst_test_cases on tc.id,
--     which returns NOTHING after consolidation, because a central id does not match a local one.
-- =========================================================================================================


-- The catalog with its full hierarchy, TcList position and current health. The main list screen reads this.
CREATE OR REPLACE VIEW `vw_test_case_catalog` AS
SELECT
    tc.test_case_code,
    tc.tcr_code,
    m.module_code,
    m.name                       AS module_name,
    c.cat_code,
    c.name                       AS category_name,
    mm.mm_code,
    mm.name                      AS main_menu_name,
    sm.sm_code,
    sm.name                      AS sub_menu_name,
    ts.ts_code,
    ts.name                      AS screen_name,
    ts.criticality               AS screen_criticality,
    ts.is_excluded               AS screen_excluded,
    tc.machine_code,
    tc.user_code                 AS author_code,
    tc.display_name,
    tc.version_no,
    tc.test_method_code,
    tc.test_technology_code,
    tc.criticality,
    tc.creation_status_code,
    tc.is_orphaned,
    tc.is_active,
    cs.last_status,
    cs.last_run_at,
    cs.pass_rate_30d,
    cs.consecutive_failures,
    cs.is_flaky_confirmed,
    cs.health_status,
    cs.confidence_score,
    cs.open_bug_count
FROM `tst_test_cases` tc
JOIN `tst_tabs_screens` ts ON ts.ts_code = tc.ts_code
JOIN `tst_modules`      m  ON m.module_code = ts.module_code
JOIN `tst_categories`   c  ON c.module_code = ts.module_code AND c.cat_code = ts.cat_code
JOIN `tst_main_menus`   mm ON mm.module_code = ts.module_code AND mm.cat_code = ts.cat_code AND mm.mm_code = ts.mm_code
LEFT JOIN `tst_sub_menus` sm ON sm.sm_code = ts.sm_code
LEFT JOIN `tst_test_case_runs_summary` cs ON cs.test_case_code = tc.test_case_code
WHERE tc.deleted_at IS NULL;


-- NEW IN v7.2. Coverage with a real denominator: required vs written vs reviewed vs released.
-- This is the view that answers "how tested is Fees, actually?".
CREATE OR REPLACE VIEW `vw_tc_list_coverage` AS
SELECT
    ts.module_code,
    ts.ts_code,
    ts.name                                                              AS screen_name,
    ts.criticality,
    ts.tc_list_status,
    ts.dev_status,
    COUNT(DISTINCT CASE WHEN r.tc_creation_status <> 'Not-Required'
                        THEN r.tcr_code END)                             AS required_count,
    COUNT(DISTINCT CASE WHEN r.tc_creation_status = 'Not-Required'
                        THEN r.tcr_code END)                             AS not_required_count,
    COUNT(DISTINCT tc.test_case_code)                                    AS written_count,
    COUNT(DISTINCT CASE WHEN tc.creation_status_code = 'Released'
                        THEN tc.test_case_code END)                      AS released_count,
    COUNT(DISTINCT CASE WHEN rv.status = 'Released'
                        THEN rv.test_case_code END)                      AS signed_off_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN tc.creation_status_code = 'Released' THEN tc.test_case_code END)
        / NULLIF(COUNT(DISTINCT CASE WHEN r.tc_creation_status <> 'Not-Required' THEN r.tcr_code END), 0)
        * 100, 2)                                                        AS coverage_percent
FROM `tst_tabs_screens` ts
LEFT JOIN `tst_tc_required_list` r  ON r.ts_code = ts.ts_code AND r.deleted_at IS NULL
LEFT JOIN `tst_test_cases`       tc ON tc.tcr_code = r.tcr_code AND tc.deleted_at IS NULL
LEFT JOIN `tst_test_case_review` rv ON rv.test_case_code = tc.test_case_code AND rv.status = 'Released'
WHERE ts.is_active = 1 AND ts.is_excluded = 0
GROUP BY ts.module_code, ts.ts_code, ts.name, ts.criticality, ts.tc_list_status, ts.dev_status;


-- NEW IN v7.2. Review and sign-off state per test case, with reviewer and approver kept distinct.
CREATE OR REPLACE VIEW `vw_review_status` AS
SELECT
    tc.test_case_code,
    tc.ts_code,
    tc.display_name,
    tc.version_no                AS current_version,
    rv.version_no                AS reviewed_version,
    rv.review_date,
    rv.status                    AS review_status,
    rv.readiness_score,
    rv.reviewed_by,
    rv.reviewed_at,
    rv.signed_off_by,
    rv.signed_off_at,
    rv.bug_in_testcase,
    rv.known_issues_in_scope,
    CASE
      WHEN rv.id IS NULL                        THEN 'Never_Reviewed'
      WHEN rv.version_no < tc.version_no        THEN 'Review_Stale'
      WHEN rv.signed_off_by IS NULL             THEN 'Awaiting_Sign_Off'
      WHEN rv.reviewed_by = rv.signed_off_by    THEN 'Self_Signed_Off'
      ELSE 'Signed_Off'
    END                          AS review_state
FROM `tst_test_cases` tc
LEFT JOIN `tst_test_case_review` rv
       ON rv.test_case_code = tc.test_case_code
      AND rv.id = (SELECT MAX(r2.id) FROM `tst_test_case_review` r2
                    WHERE r2.test_case_code = tc.test_case_code)
WHERE tc.deleted_at IS NULL AND tc.is_active = 1;


-- Every attempt for a test case, with run, machine and environment context.
CREATE OR REPLACE VIEW `vw_test_case_history` AS
SELECT
    r.test_case_code,
    tc.display_name,
    tc.ts_code,
    r.id                         AS result_id,
    r.run_id,
    r.attempt_no,
    r.is_final_attempt,
    r.status,
    r.duration_seconds,
    r.error_message,
    r.failure_fingerprint,
    r.triage_state,
    r.machine_id,
    r.run_machine_code,
    r.environment_profile_id,
    ep.env_name,
    ep.browser_name,
    ep.browser_version,
    ep.os_name,
    run.trigger_type,
    run.commit_hash,
    run.branch_name,
    ri.selection_reason,
    ri.test_case_version_no,
    r.created_at
FROM `tst_test_run_results` r
JOIN `tst_test_run_items` ri ON ri.id = r.run_item_id
JOIN `tst_test_runs`      run ON run.id = r.run_id
LEFT JOIN `tst_test_cases` tc ON tc.test_case_code = r.test_case_code
LEFT JOIN `tst_environment_profiles` ep ON ep.id = r.environment_profile_id;


-- Run-level history with roll-ups and who ran it.
CREATE OR REPLACE VIEW `vw_test_run_history` AS
SELECT
    run.id                       AS run_id,
    run.machine_id,
    run.run_machine_code,
    run.run_user_code,
    run.run_name,
    run.trigger_type,
    run.status,
    run.started_at,
    run.finished_at,
    run.duration_seconds,
    run.commit_hash,
    run.branch_name,
    run.working_tree_dirty,
    ep.env_name,
    run.total_tc_count,
    run.passed_tc_count,
    run.failed_tc_count,
    run.error_tc_count,
    run.skipped_tc_count,
    run.blocked_tc_count,
    run.not_executed_tc_count,
    ROUND(run.passed_tc_count / NULLIF(run.total_tc_count,0) * 100, 2) AS pass_rate,
    run.initiated_by,
    run.executed_by,
    sch.name                     AS schedule_name
FROM `tst_test_runs` run
LEFT JOIN `tst_environment_profiles` ep ON ep.id = run.environment_profile_id
LEFT JOIN `tst_schedules` sch ON sch.id = run.schedule_id
WHERE run.deleted_at IS NULL;


-- Flaky candidates and confirmations, with the evidence retained.
CREATE OR REPLACE VIEW `vw_flaky_tests` AS
SELECT
    cs.test_case_code,
    tc.display_name,
    tc.ts_code,
    ts.module_code,
    cs.flaky_score,
    cs.is_flaky_candidate,
    cs.is_flaky_confirmed,
    cs.flaky_reason,
    cs.flaky_evidence_json,
    cs.flaky_confirmed_by,
    cs.flaky_confirmed_at,
    cs.total_runs,
    cs.pass_rate_30d,
    cs.distinct_environments,
    cs.last_status,
    cs.last_run_at
FROM `tst_test_case_runs_summary` cs
JOIN `tst_test_cases`   tc ON tc.test_case_code = cs.test_case_code
JOIN `tst_tabs_screens` ts ON ts.ts_code = tc.ts_code
WHERE cs.is_flaky_candidate = 1 OR cs.is_flaky_confirmed = 1;


-- Currently failing, previously passing, not confirmed flaky.
CREATE OR REPLACE VIEW `vw_regression_candidates` AS
SELECT
    cs.test_case_code,
    tc.display_name,
    tc.ts_code,
    ts.module_code,
    tc.criticality,
    cs.last_status,
    cs.last_run_at,
    cs.last_passed_at,
    cs.consecutive_failures,
    cs.pass_rate_30d,
    cs.health_status,
    DATEDIFF(NOW(), cs.last_passed_at) AS days_since_last_pass
FROM `tst_test_case_runs_summary` cs
JOIN `tst_test_cases`   tc ON tc.test_case_code = cs.test_case_code
JOIN `tst_tabs_screens` ts ON ts.ts_code = tc.ts_code
WHERE cs.last_status IN ('Failed','Error')
  AND cs.last_passed_at IS NOT NULL
  AND cs.last_passed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND cs.is_flaky_confirmed = 0
  AND tc.is_active = 1;


-- Open defects with age, SLA state and occurrence count.
CREATE OR REPLACE VIEW `vw_open_bugs` AS
SELECT
    b.id                         AS bug_id,
    b.bug_code,
    b.title,
    b.module_code,
    b.ts_code,
    b.test_case_code,
    tc.display_name              AS test_case_name,
    b.severity,
    b.priority,
    b.status,
    b.assigned_to,
    b.assigned_at,
    b.sla_due_at,
    b.sla_breached,
    b.occurrence_count,
    b.reopen_count,
    b.retest_attempt_count,
    b.discovered_by,
    b.created_at,
    DATEDIFF(NOW(), b.created_at) AS age_days,
    ep.env_name
FROM `tst_bugs` b
LEFT JOIN `tst_test_cases` tc ON tc.test_case_code = b.test_case_code
LEFT JOIN `tst_environment_profiles` ep ON ep.id = b.environment_profile_id
WHERE b.status NOT IN ('Closed','Wont_Fix','Duplicate')
  AND b.deleted_at IS NULL;


-- Time in each status, per bug, from the recorded transitions.
CREATE OR REPLACE VIEW `vw_bug_lifecycle` AS
SELECT
    b.id                         AS bug_id,
    b.bug_code,
    b.title,
    b.severity,
    b.status                     AS current_status,
    b.created_at                 AS opened_at,
    b.assigned_at,
    b.fixed_at,
    b.verified_at,
    b.closed_at,
    b.verification_override,
    TIMESTAMPDIFF(HOUR, b.created_at, b.assigned_at) AS hours_to_assign,
    TIMESTAMPDIFF(HOUR, b.assigned_at, b.fixed_at)   AS hours_to_fix,
    TIMESTAMPDIFF(HOUR, b.fixed_at,    b.verified_at) AS hours_to_verify,
    TIMESTAMPDIFF(HOUR, b.created_at,  b.closed_at)  AS hours_total,
    (SELECT COUNT(*) FROM `tst_bug_status_history` h WHERE h.bug_id = b.id) AS transition_count
FROM `tst_bugs` b
WHERE b.deleted_at IS NULL;


-- Screen-level coverage and health.
CREATE OR REPLACE VIEW `vw_screen_coverage` AS
SELECT
    ts.module_code,
    ts.ts_code,
    ts.name                      AS screen_name,
    ts.criticality,
    ts.is_excluded,
    ts.dev_status,
    ts.test_run_status,
    COUNT(DISTINCT tc.test_case_code)                                            AS total_tests,
    COUNT(DISTINCT CASE WHEN tc.is_active = 1 THEN tc.test_case_code END)        AS active_tests,
    COUNT(DISTINCT CASE WHEN tc.is_orphaned = 1 THEN tc.test_case_code END)      AS orphaned_tests,
    SUM(CASE WHEN cs.last_status = 'Passed' THEN 1 ELSE 0 END)                   AS passing,
    SUM(CASE WHEN cs.last_status IN ('Failed','Error') THEN 1 ELSE 0 END)        AS failing,
    SUM(CASE WHEN cs.test_case_code IS NULL THEN 1 ELSE 0 END)                   AS never_executed,
    CASE
      WHEN COUNT(tc.test_case_code) = 0 THEN 'No Tests'
      WHEN SUM(CASE WHEN cs.test_case_code IS NULL THEN 1 ELSE 0 END) = COUNT(tc.test_case_code) THEN 'Never Executed'
      WHEN SUM(CASE WHEN cs.last_status IN ('Failed','Error') THEN 1 ELSE 0 END) > 0 THEN 'Failing'
      ELSE 'Healthy'
    END                          AS coverage_state
FROM `tst_tabs_screens` ts
LEFT JOIN `tst_test_cases` tc ON tc.ts_code = ts.ts_code AND tc.deleted_at IS NULL
LEFT JOIN `tst_test_case_runs_summary` cs ON cs.test_case_code = tc.test_case_code
WHERE ts.is_active = 1
GROUP BY ts.module_code, ts.ts_code, ts.name, ts.criticality, ts.is_excluded, ts.dev_status, ts.test_run_status;


-- Module roll-up.
CREATE OR REPLACE VIEW `vw_module_quality_summary` AS
SELECT
    m.module_code,
    m.name                       AS module_name,
    m.criticality,
    COUNT(DISTINCT ts.ts_code)                                                        AS screen_count,
    COUNT(DISTINCT CASE WHEN ts.is_excluded = 1 THEN ts.ts_code END)                  AS excluded_screens,
    COUNT(DISTINCT tc.test_case_code)                                                 AS test_count,
    COUNT(DISTINCT CASE WHEN cs.test_case_code IS NULL THEN tc.test_case_code END)    AS never_executed,
    COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN tc.test_case_code END)    AS passing,
    COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN tc.test_case_code END) AS failing,
    COUNT(DISTINCT CASE WHEN cs.is_flaky_confirmed = 1 THEN tc.test_case_code END)    AS flaky,
    ROUND(AVG(cs.pass_rate_30d), 2)                                                   AS avg_pass_rate_30d,
    (SELECT COUNT(*) FROM `tst_bugs` b
      WHERE b.module_code = m.module_code
        AND b.status NOT IN ('Closed','Wont_Fix','Duplicate'))                        AS open_bugs
FROM `tst_modules` m
LEFT JOIN `tst_tabs_screens` ts ON ts.module_code = m.module_code AND ts.is_active = 1
LEFT JOIN `tst_test_cases`   tc ON tc.ts_code = ts.ts_code AND tc.deleted_at IS NULL
LEFT JOIN `tst_test_case_runs_summary` cs ON cs.test_case_code = tc.test_case_code
WHERE m.is_active = 1
GROUP BY m.module_code, m.name, m.criticality;


-- THE ENVIRONMENT-DIFFERENCE DETECTOR: the same test, on different machines.
-- This is the view that answers "is the application broken, or is your machine different?".
CREATE OR REPLACE VIEW `vw_machine_comparison` AS
SELECT
    r.test_case_code,
    tc.display_name,
    r.run_machine_code,
    mc.machine_name,
    mc.owner_user_code,
    COUNT(*)                                                          AS attempts,
    SUM(CASE WHEN r.status = 'Passed' THEN 1 ELSE 0 END)              AS passed,
    SUM(CASE WHEN r.status IN ('Failed','Error') THEN 1 ELSE 0 END)   AS failed,
    ROUND(SUM(CASE WHEN r.status = 'Passed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pass_rate,
    MAX(r.created_at)                                                 AS last_run_at
FROM `tst_test_run_results` r
JOIN `tst_test_cases` tc ON tc.test_case_code = r.test_case_code
LEFT JOIN `tst_machines` mc ON mc.machine_code = r.run_machine_code
WHERE r.is_final_attempt = 1
GROUP BY r.test_case_code, tc.display_name, r.run_machine_code, mc.machine_name, mc.owner_user_code;


-- Pass rate by environment profile — "it fails only on Chrome 141".
CREATE OR REPLACE VIEW `vw_environment_impact` AS
SELECT
    ep.id                        AS environment_profile_id,
    ep.env_name,
    ep.env_type,
    ep.os_name,
    ep.browser_name,
    ep.browser_version,
    ep.php_version,
    ep.database_version,
    COUNT(*)                                                          AS attempts,
    SUM(CASE WHEN r.status = 'Passed' THEN 1 ELSE 0 END)              AS passed,
    SUM(CASE WHEN r.status IN ('Failed','Error') THEN 1 ELSE 0 END)   AS failed,
    ROUND(SUM(CASE WHEN r.status = 'Passed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pass_rate,
    COUNT(DISTINCT r.test_case_code)                                  AS distinct_tests
FROM `tst_test_run_results` r
JOIN `tst_environment_profiles` ep ON ep.id = r.environment_profile_id
WHERE r.is_final_attempt = 1
GROUP BY ep.id, ep.env_name, ep.env_type, ep.os_name, ep.browser_name, ep.browser_version,
         ep.php_version, ep.database_version;


-- Recurrence counts per known issue, and whether its review is overdue.
CREATE OR REPLACE VIEW `vw_known_issue_occurrences` AS
SELECT
    ki.id                        AS known_issue_id,
    ki.issue_code,
    ki.title,
    ki.category,
    ki.module_code,
    ki.ts_code,
    ki.status,
    ki.owner_user_code,
    ki.review_due_at,
    CASE WHEN ki.review_due_at IS NOT NULL AND ki.review_due_at < CURDATE()
         THEN 1 ELSE 0 END       AS review_overdue,
    COUNT(kir.run_result_id)     AS occurrence_count,
    MIN(r.created_at)            AS first_occurrence,
    MAX(r.created_at)            AS last_occurrence,
    COUNT(DISTINCT r.test_case_code) AS distinct_test_cases
FROM `tst_known_issues` ki
LEFT JOIN `tst_known_issue_results` kir ON kir.known_issue_id = ki.id
LEFT JOIN `tst_test_run_results`    r   ON r.id = kir.run_result_id
GROUP BY ki.id, ki.issue_code, ki.title, ki.category, ki.module_code, ki.ts_code,
         ki.status, ki.owner_user_code, ki.review_due_at;


-- Screens with no released test case, weighted by criticality. The backlog nobody wants to look at.
CREATE OR REPLACE VIEW `vw_testing_debt` AS
SELECT
    ts.module_code,
    ts.ts_code,
    ts.name                      AS screen_name,
    ts.criticality,
    ts.dev_status,
    ts.tc_list_status,
    ts.tc_creation_status,
    COUNT(DISTINCT r.tcr_code)   AS required_count,
    COUNT(DISTINCT tc.test_case_code) AS written_count,
    COUNT(DISTINCT CASE WHEN tc.creation_status_code = 'Released' THEN tc.test_case_code END) AS released_count,
    CASE ts.criticality
      WHEN 'Critical' THEN 5 WHEN 'High' THEN 4 WHEN 'Medium' THEN 3
      WHEN 'Low' THEN 2 ELSE 1
    END                          AS debt_weight,
    CASE
      WHEN COUNT(DISTINCT r.tcr_code) = 0 THEN 'No_TcList'
      WHEN COUNT(DISTINCT tc.test_case_code) = 0 THEN 'TcList_Only'
      WHEN COUNT(DISTINCT CASE WHEN tc.creation_status_code = 'Released' THEN tc.test_case_code END) = 0 THEN 'Written_Not_Released'
      ELSE 'Partially_Covered'
    END                          AS debt_type
FROM `tst_tabs_screens` ts
LEFT JOIN `tst_tc_required_list` r  ON r.ts_code = ts.ts_code AND r.deleted_at IS NULL
LEFT JOIN `tst_test_cases`       tc ON tc.ts_code = ts.ts_code AND tc.deleted_at IS NULL
WHERE ts.is_active = 1 AND ts.is_excluded = 0
GROUP BY ts.module_code, ts.ts_code, ts.name, ts.criticality, ts.dev_status,
         ts.tc_list_status, ts.tc_creation_status
HAVING released_count = 0;


-- Authorship and execution per user.
CREATE OR REPLACE VIEW `vw_developer_activity_summary` AS
SELECT
    u.code                       AS user_code,
    u.name                       AS user_name,
    u.role,
    (SELECT COUNT(*) FROM `tst_test_cases` tc WHERE tc.user_code = u.code AND tc.deleted_at IS NULL)        AS test_cases_authored,
    (SELECT COUNT(*) FROM `tst_tc_required_list` r WHERE r.user_code = u.code AND r.deleted_at IS NULL)     AS tclist_entries_written,
    (SELECT COUNT(*) FROM `tst_test_case_review` rv WHERE rv.reviewed_by = u.code)                          AS reviews_performed,
    (SELECT COUNT(*) FROM `tst_test_case_review` rv WHERE rv.signed_off_by = u.code)                        AS sign_offs_given,
    (SELECT COUNT(*) FROM `tst_test_runs` run WHERE run.executed_by = u.code AND run.deleted_at IS NULL)    AS runs_executed,
    (SELECT COUNT(*) FROM `tst_bugs` b WHERE b.discovered_by = u.code AND b.deleted_at IS NULL)             AS bugs_raised,
    (SELECT COUNT(*) FROM `tst_bugs` b WHERE b.assigned_to = u.code
                                         AND b.status NOT IN ('Closed','Wont_Fix','Duplicate'))             AS open_bugs_assigned,
    (SELECT COUNT(*) FROM `tst_bugs` b WHERE b.fixed_by = u.code)                                           AS bugs_fixed,
    (SELECT COUNT(*) FROM `tst_machines` mc WHERE mc.owner_user_code = u.code AND mc.is_active = 1)         AS machines_owned
FROM `tst_users` u
WHERE u.is_active = 1;


-- Import outcomes and open conflicts.
CREATE OR REPLACE VIEW `vw_import_status` AS
SELECT
    i.id                         AS import_id,
    i.source_machine_id,
    mc.machine_code              AS source_machine_code,
    i.source_export_id,
    i.imported_by,
    i.status,
    i.version_decision,
    i.started_at,
    i.finished_at,
    i.records_created,
    i.records_matched,
    i.records_rejected,
    i.conflict_count,
    i.open_conflict_count,
    (SELECT COUNT(*) FROM `tst_import_conflicts` cf
      WHERE cf.import_id = i.id AND cf.status = 'Open' AND cf.severity = 'Blocking') AS blocking_conflicts,
    i.reversed_at,
    i.reversal_reason
FROM `tst_data_imports` i
LEFT JOIN `tst_machines` mc ON mc.id = i.source_machine_id;


-- =========================================================================================================
-- SECTION 14 — PHASE-1 SEED DATA                                                                    [P1]
-- =========================================================================================================
--     Seeded in dependency order: users -> machines -> settings.
--     Every statement is idempotent (ON DUPLICATE KEY UPDATE), so the whole script is re-runnable.
--
--     v7.2 corrections to the v7.1 seeds:
--       - v7.1 seeded created_by = 'S1', a user code that is never created. Every FK failed.
--         All seeds now use 'S01'.
--       - The users seed relied on a self-referencing FK that only worked with checks disabled.
--         The bootstrap row is inserted with NULL and updated afterwards.
-- =========================================================================================================

-- ---------------------------------------------------------------------------------------------------------
-- 14.1  Users.  The bootstrap row S01 is inserted with created_by NULL and back-filled below.
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_users` (`code`,`name`,`email`,`password`,`role`,`is_superuser`,`is_system`,`is_active`,`created_by`,`updated_by`)
VALUES
   ('S01','Super User','super@prime-testing.local','$2y$12$placeholder_super_hash','System',    1, 1, 1, NULL,  NULL)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

UPDATE `tst_users` SET `created_by` = 'S01', `updated_by` = 'S01' WHERE `code` = 'S01' AND `created_by` IS NULL;

INSERT INTO `tst_users` (`code`,`name`,`email`,`password`,`role`,`is_superuser`,`is_system`,`is_active`,`created_by`,`updated_by`)
VALUES
   ('S02','System','system@prime-testing.local','$2y$12$placeholder_sys_hash','System',        0, 1, 1, 'S01','S01'),
   ('A01','Brijesh','brijesh@prime-testing.local','$2y$12$placeholder_brij_hash','Architect',  0, 0, 1, 'S01','S01'),
   ('D02','Tarun','tarun@prime-testing.local','$2y$12$placeholder_tarun_hash','Developer',     0, 0, 1, 'S01','S01'),
   ('D03','Shailesh','shailesh@prime-testing.local','$2y$12$placeholder_shail_hash','Developer',0,0, 1, 'S01','S01'),
   ('T01','Sameer','sameer@prime-testing.local','$2y$12$placeholder_samer_hash','Tester',      0, 0, 1, 'S01','S01'),
   ('T02','Gaurav','gaurav@prime-testing.local','$2y$12$placeholder_gaurav_hash','Tester',     0, 0, 1, 'S01','S01')
ON DUPLICATE KEY UPDATE
   `name`      = VALUES(`name`),
   `email`     = VALUES(`email`),
   `role`      = VALUES(`role`),
   `is_active` = VALUES(`is_active`);

-- ---------------------------------------------------------------------------------------------------------
-- 14.2  Machines.  IDS ARE INSERTED EXPLICITLY. id 1 is the central installation; locals start at 10.
--       machine_code is GENERATED — never insert it, and never reissue a retired one.
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_machines`
   (`id`,`owner_user_code`,`machine_number`,`machine_name`,`is_central`,`is_active`,`registration_status`,`registered_by`)
VALUES
   ( 1,'A01','A','Central Consolidation Server', 1, 1, 'Registered','S01'),   -- machine_code A01A
   (10,'A01','B','Brijesh Workstation',          0, 1, 'Registered','S01'),   -- machine_code A01B
   (11,'D02','A','Tarun Workstation',            0, 1, 'Registered','S01'),   -- machine_code D02A
   (12,'D03','A','Shailesh Workstation',         0, 1, 'Registered','S01'),   -- machine_code D03A
   (13,'T01','A','Sameer Workstation',           0, 1, 'Registered','S01'),   -- machine_code T01A
   (14,'T02','A','Gaurav Workstation',           0, 1, 'Registered','S01')    -- machine_code T02A
ON DUPLICATE KEY UPDATE
   `machine_name`        = VALUES(`machine_name`),
   `registration_status` = VALUES(`registration_status`);

-- ---------------------------------------------------------------------------------------------------------
-- 14.3  Application settings.
--       is_local_only = 1 rows NEVER travel in a catalog bundle: a local path exported to another
--       machine produces an installation pointing at a directory that does not exist there.
-- ---------------------------------------------------------------------------------------------------------
INSERT INTO `tst_app_settings`
   (`group_name`,`ordinal`,`key`,`value`,`value_type`,`description`,`is_system`,`is_local_only`,`is_editable`)
VALUES
   ('Platform',  1,'schema_version','7.2.0','STRING','Schema version of this database. Replaces the tst_schema_version table (D-27).',1,0,0),
   ('Platform',  2,'app_version','1.0.0','STRING','Application version installed here.',1,0,0),
   ('Platform',  3,'central_mode','false','BOOLEAN','True when this database is the central aggregation database.',1,1,1),
   ('Retest',   10,'max_auto_retest_attempts','5','INTEGER','Maximum automatic retest cycles before a bug escalates. Automation must be bounded (R-14).',1,0,1),
   ('Retest',   11,'auto_retest_enabled','true','BOOLEAN','Global switch for automatic retest when a bug is marked Fixed.',1,0,1),
   ('Defects',  20,'auto_bug_creation_enabled','true','BOOLEAN','Create a bug from a qualifying failed result automatically.',1,0,1),
   ('Defects',  21,'bug_fix_sla_hours','48','INTEGER','Hours after assignment before a stale-bug alert.',1,0,1),
   ('Analysis', 30,'default_regression_days','30','INTEGER','Look-back window for the regression definition (BRD BR-REG-01).',1,0,1),
   ('Analysis', 31,'flaky_window_size','10','INTEGER','Executions examined for outcome alternation (BRD BR-FLAKY-01).',1,0,1),
   ('Analysis', 32,'flaky_min_alternations','2','INTEGER','Alternations within the window that make a candidate.',1,0,1),
   ('Execution',40,'run_heartbeat_timeout_seconds','300','INTEGER','A Running run with no heartbeat for this long is moved to Interrupted.',1,0,1),
   ('Sync',     50,'allow_multi_machine_import','true','BOOLEAN','Allow execution data from registered machines to be imported.',1,0,1),
   ('Sync',     51,'accepted_prior_schema_minor','1','INTEGER','How many prior minor schema versions an import may carry (BC-11).',1,0,1),
   ('Retention',60,'artifact_retention_days','180','INTEGER','After this an artefact is marked unavailable. The ROW is retained.',1,0,1),
   ('Retention',61,'audit_retention_days','1095','INTEGER','Three years. Expiry is an explicit administrative action, never a silent purge.',1,0,1),
   ('Retention',62,'import_bundle_retention_days','90','INTEGER','How long an applied bundle file is kept.',1,0,1),
   ('Paths',    70,'prime_ai_repo_path','','STRING','Local path to the Prime-AI source tree.',1,1,1),
   ('Paths',    71,'evidence_root_path','','STRING','Local path to the evidence store.',1,1,1)
ON DUPLICATE KEY UPDATE
   `value`       = VALUES(`value`),
   `description` = VALUES(`description`);


-- #########################################################################################################
-- #                                                                                                       #
-- #        E N D   O F   P H A S E   1                                                                    #
-- #                                                                                                       #
-- #        Stop here and you have a complete, installable system: 44 tables, 17 views, seeded.            #
-- #        A tester can plan, author, review, schedule, execute and evidence a test; a lead can read       #
-- #        it, drive a bug to verified closure, and consolidate every machine's evidence.                  #
-- #                                                                                                       #
-- #########################################################################################################



-- #########################################################################################################
-- #                                                                                                       #
-- #                      P H A S E   2   —   C O R R E L A T E   A N D   S E L E C T                      #
-- #                                                                                                       #
-- #    Everything needed to answer: GIVEN THIS CHANGE, WHICH TESTS DOES IT REQUIRE?                       #
-- #                                                                                                       #
-- #    Phase 2 ADDS. It contains CREATE TABLE, ADD CONSTRAINT, CREATE VIEW and INSERT.                    #
-- #    It contains NO ADD COLUMN, NO MODIFY COLUMN and NO DROP — see THE PHASE RULE in the header.        #
-- #                                                                                                       #
-- #########################################################################################################

SET FOREIGN_KEY_CHECKS = 0;


-- =========================================================================================================
-- SECTION 20 — CHANGE REQUESTS AND THE TEST-CASE WORK BACKLOG                                       [P2]
-- =========================================================================================================
--     TWO DIFFERENT THINGS, DELIBERATELY KEPT APART:
--
--       tst_app_requirements        a CHANGE REQUEST — a statement about PRIME-AI.
--                                   "Fees must support part payment."
--       tst_test_case_requirements  a WORK REQUEST  — a statement about THE TEST SUITE.
--                                   "Write a test for part payment."
--
--     Conflating them makes coverage uncountable, because a backlog item about writing a test would be
--     counted as a requirement that needs covering.
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_app_requirements` (
   `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `req_code`            VARCHAR(40) NOT NULL   COMMENT 'Stable business code, e.g. FIN-REQ-014',
   `module_code`         VARCHAR(5)  NOT NULL,
   `ts_code`             VARCHAR(11) NULL       COMMENT 'When the change is screen-specific',
   `title`               VARCHAR(255) NOT NULL,
   `description`         TEXT NULL,
   `acceptance_criteria` TEXT NULL,
   `source_document`     VARCHAR(1000) NULL     COMMENT 'The FRD or BRD it came from',
   `criticality`         ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `status`              ENUM('Draft','Approved','Implemented','Changed','Retired') NOT NULL DEFAULT 'Draft',
   `version_no`          INT UNSIGNED NOT NULL DEFAULT 1,
   `owner_user_code`     VARCHAR(3) NULL,
   `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`          VARCHAR(3) NOT NULL,
   `updated_by`          VARCHAR(3) NOT NULL,
   `deleted_by`          VARCHAR(3) NULL,
   `created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`          TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_appReq_code` (`req_code`),
   INDEX `idx_tst_appReq_module`      (`module_code`,`status`),
   INDEX `idx_tst_appReq_screen`      (`ts_code`),
   INDEX `idx_tst_appReq_criticality` (`criticality`),
   FULLTEXT KEY `ft_tst_appReq_text`  (`title`,`description`),
   CONSTRAINT `fk_tst_appReq_module`    FOREIGN KEY (`module_code`)     REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_appReq_screen`    FOREIGN KEY (`ts_code`)         REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_appReq_owner`     FOREIGN KEY (`owner_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_appReq_createdBy` FOREIGN KEY (`created_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_appReq_updatedBy` FOREIGN KEY (`updated_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_appReq_deletedBy` FOREIGN KEY (`deleted_by`)      REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Change requests — statements about Prime-AI, not about the test suite.';


-- Coverage in BOTH directions: which tests cover this change, and which changes this test covers.
-- v7.2: keyed on test_case_code, not test_case_id.
CREATE TABLE IF NOT EXISTS `tst_app_requirement_test_cases` (
   `requirement_id` BIGINT UNSIGNED NOT NULL,
   `test_case_code` VARCHAR(21) NOT NULL,
   `coverage_type`  ENUM('Full','Partial','Negative','Boundary','Integration') NOT NULL DEFAULT 'Full',
   `mapped_by`      VARCHAR(3) NOT NULL,
   `note`           VARCHAR(500) NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`requirement_id`,`test_case_code`),
   INDEX `idx_tst_reqTc_case` (`test_case_code`),
   CONSTRAINT `fk_tst_reqTc_req`  FOREIGN KEY (`requirement_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_reqTc_case` FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_reqTc_by`   FOREIGN KEY (`mapped_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Change request <-> test coverage, in both directions.';


-- The TEST-CASE WORK BACKLOG. "Create a test for X", "automate Y", "retire Z".
-- Carries a distributed identity because it can be raised independently on any machine.
CREATE TABLE IF NOT EXISTS `tst_test_case_requirements` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`            SMALLINT UNSIGNED NOT NULL,
   `source_requirement_id` BIGINT UNSIGNED NOT NULL,
   `raised_by_user_code`   VARCHAR(3) NOT NULL,
   `request_type`          ENUM('Create','Modify','Automate','Retire','Investigate') NOT NULL DEFAULT 'Create',
   `module_code`           VARCHAR(5)  NOT NULL,
   `ts_code`               VARCHAR(11) NULL,
   `proposed_tab_name`     VARCHAR(150) NULL,
   `proposed_folder_path`  VARCHAR(1000) NULL,
   `title`                 VARCHAR(255) NOT NULL,
   `description`           TEXT NULL,
   `priority`              ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `origin_type`           ENUM('Person','Change_Request','Coverage_Gap','Bug','Discovery','AI') NOT NULL DEFAULT 'Person',
   `origin_requirement_id` BIGINT UNSIGNED NULL,
   `requested_by`          VARCHAR(3) NULL,
   `assigned_to`           VARCHAR(3) NULL,
   `assigned_at`           DATETIME NULL,
   `status`                ENUM('Pending','In_Progress','Completed','Cancelled','Hold') NOT NULL DEFAULT 'Pending',
   `target_test_case_code` VARCHAR(21) NULL   COMMENT 'v7.2: the test case this request produced, by code',
   `completed_by`          VARCHAR(3) NULL,
   `completed_at`          DATETIME NULL,
   `completion_note`       VARCHAR(1000) NULL,
   `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`            TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_tcReq_source` (`machine_id`,`source_requirement_id`),
   INDEX `idx_tst_tcReq_module`   (`module_code`),
   INDEX `idx_tst_tcReq_status`   (`status`,`priority`),
   INDEX `idx_tst_tcReq_assigned` (`assigned_to`,`status`),
   INDEX `idx_tst_tcReq_target`   (`target_test_case_code`),
   CONSTRAINT `fk_tst_tcReq_machine`     FOREIGN KEY (`machine_id`)             REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReq_raisedBy`    FOREIGN KEY (`raised_by_user_code`)    REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReq_module`      FOREIGN KEY (`module_code`)            REFERENCES `tst_modules`(`module_code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcReq_screen`      FOREIGN KEY (`ts_code`)                REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReq_originReq`   FOREIGN KEY (`origin_requirement_id`)  REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReq_target`      FOREIGN KEY (`target_test_case_code`)  REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReq_requestedBy` FOREIGN KEY (`requested_by`)           REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReq_assignedTo`  FOREIGN KEY (`assigned_to`)            REFERENCES `tst_users`(`code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_tcReq_completedBy` FOREIGN KEY (`completed_by`)           REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] The test-case work backlog. NOT the same as a change request.';


-- =========================================================================================================
-- SECTION 21 — DEPENDENCIES                                                                         [P2]
-- =========================================================================================================
--     This is what turns "what changed?" into "what else might it have broken?".
--
--     impact_weight DECAYS WITH DEPTH in the traversal: a second-order dependency is weaker evidence
--     than a first-order one, and treating them equally is how an impact analysis ends up proposing
--     the entire test suite.
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_module_dependencies` (
   `module_code`            VARCHAR(5) NOT NULL,
   `depends_on_module_code` VARCHAR(5) NOT NULL,
   `dependency_type`        ENUM('Functional','Data','Shared_Component','API','Integration','Navigation','Other')
                              NOT NULL DEFAULT 'Functional',
   `impact_weight`          TINYINT UNSIGNED NOT NULL DEFAULT 5   COMMENT '1 (weak) .. 10 (strong); decays with depth',
   `note`                   VARCHAR(500) NULL,
   `is_active`              TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`             VARCHAR(3) NOT NULL,
   `updated_by`             VARCHAR(3) NOT NULL,
   `deleted_by`             VARCHAR(3) NULL,
   `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`             TIMESTAMP NULL,
   PRIMARY KEY (`module_code`,`depends_on_module_code`),
   INDEX `idx_tst_moduleDep_parent` (`depends_on_module_code`),
   CONSTRAINT `chk_tst_moduleDep_notSelf` CHECK (`module_code` <> `depends_on_module_code`),
   CONSTRAINT `chk_tst_moduleDep_weight`  CHECK (`impact_weight` BETWEEN 1 AND 10),
   CONSTRAINT `fk_tst_moduleDep_module`    FOREIGN KEY (`module_code`)            REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_moduleDep_parent`    FOREIGN KEY (`depends_on_module_code`) REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_moduleDep_createdBy` FOREIGN KEY (`created_by`)             REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_moduleDep_updatedBy` FOREIGN KEY (`updated_by`)             REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_moduleDep_deletedBy` FOREIGN KEY (`deleted_by`)             REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Module-to-module dependencies with a weight that decays with depth.';


-- is_blocking REACHES BACK INTO PHASE 1: if the parent fails, the dependent test is recorded BLOCKED,
-- not FAILED. That is why Blocked exists as a result status from Phase 1 — the status has to be there
-- before the mechanism that produces it.
CREATE TABLE IF NOT EXISTS `tst_test_case_dependencies` (
   `test_case_code`            VARCHAR(21) NOT NULL,
   `depends_on_test_case_code` VARCHAR(21) NOT NULL,
   `dependency_type`           ENUM('Prerequisite','Functional','Data','Navigation','API','Integration',
                                    'Shared_Component','Regression','Other') NOT NULL DEFAULT 'Functional',
   `is_blocking`               TINYINT(1) NOT NULL DEFAULT 0
                                 COMMENT 'Parent fails -> this test is BLOCKED, not FAILED',
   `impact_weight`             TINYINT UNSIGNED NOT NULL DEFAULT 5,
   `note`                      VARCHAR(500) NULL,
   `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`                VARCHAR(3) NOT NULL,
   `updated_by`                VARCHAR(3) NOT NULL,
   `deleted_by`                VARCHAR(3) NULL,
   `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`                TIMESTAMP NULL,
   PRIMARY KEY (`test_case_code`,`depends_on_test_case_code`),
   INDEX `idx_tst_tcDep_parent`   (`depends_on_test_case_code`),
   INDEX `idx_tst_tcDep_blocking` (`is_blocking`),
   CONSTRAINT `chk_tst_tcDep_notSelf` CHECK (`test_case_code` <> `depends_on_test_case_code`),
   CONSTRAINT `chk_tst_tcDep_weight`  CHECK (`impact_weight` BETWEEN 1 AND 10),
   CONSTRAINT `fk_tst_tcDep_case`      FOREIGN KEY (`test_case_code`)            REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_tcDep_parent`    FOREIGN KEY (`depends_on_test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_tcDep_createdBy` FOREIGN KEY (`created_by`)                REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcDep_updatedBy` FOREIGN KEY (`updated_by`)                REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_tcDep_deletedBy` FOREIGN KEY (`deleted_by`)                REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Test-case dependencies. is_blocking changes a Failed into a Blocked.';


-- =========================================================================================================
-- SECTION 22 — APPLICATION PATH MAPPING                                                             [P2]
-- =========================================================================================================
--     How a changed source path resolves to a module, a screen or a test case. Without this, impact
--     analysis requires somebody to hand-map thousands of files.
--
--     THE 'Ignore' TARGET TYPE MATTERS: vendor, build and lock-file changes must be excluded, or every
--     composer update looks like a change to the entire application.
--
--     A PATH NO RULE MATCHED IS AN UNRESOLVED FILE, and tst_impact_analyses counts them. An analysis
--     that silently ignored 40% of a change is WORSE than no analysis, because it looks complete.
-- =========================================================================================================
CREATE TABLE IF NOT EXISTS `tst_path_mappings` (
   `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `pattern`        VARCHAR(500) NOT NULL   COMMENT 'Glob, e.g. Modules/Fees/**',
   `target_type`    ENUM('Module','Screen','TestCase','Ignore') NOT NULL DEFAULT 'Module',
   `module_code`    VARCHAR(5)  NULL,
   `ts_code`        VARCHAR(11) NULL,
   `test_case_code` VARCHAR(21) NULL,
   `confidence`     DECIMAL(4,3) NOT NULL DEFAULT 0.800  COMMENT 'How strongly a match implies impact',
   `priority`       SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Lower wins; most specific first',
   `note`           VARCHAR(500) NULL,
   `is_active`      TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`     VARCHAR(3) NOT NULL,
   `updated_by`     VARCHAR(3) NOT NULL,
   `deleted_by`     VARCHAR(3) NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`     TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_pathMappings_pattern` (`pattern`),
   INDEX `idx_tst_pathMappings_priority` (`is_active`,`priority`),
   CONSTRAINT `chk_tst_pathMap_confidence` CHECK (`confidence` BETWEEN 0 AND 1),
   CONSTRAINT `fk_tst_pathMap_module`    FOREIGN KEY (`module_code`)    REFERENCES `tst_modules`(`module_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_pathMap_screen`    FOREIGN KEY (`ts_code`)        REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_pathMap_case`      FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_pathMap_createdBy` FOREIGN KEY (`created_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_pathMap_updatedBy` FOREIGN KEY (`updated_by`)     REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_pathMap_deletedBy` FOREIGN KEY (`deleted_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Source path -> module / screen / test case. Unmatched paths are a reported blind spot.';


-- =========================================================================================================
-- SECTION 23 — TEST SUITES                                                                          [P2]
-- =========================================================================================================
--     SUITE MEMBERSHIP IS VERSIONED, and a run records THE VERSION IT EXECUTED. Without that, a
--     historical run cannot be reproduced: "the regression suite" today is not the set it was in March.
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_test_suites` (
   `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `suite_code`    VARCHAR(40) NOT NULL,
   `name`          VARCHAR(150) NOT NULL,
   `suite_type`    ENUM('Smoke','Regression','Integration','Critical','Full','Bug_Retest','Release','Custom')
                     NOT NULL DEFAULT 'Custom',
   `description`   TEXT NULL,
   `is_rule_based` TINYINT(1) NOT NULL DEFAULT 0,
   `rule_json`     JSON NULL   COMMENT 'e.g. {"module":["FIN"],"criticality":["Critical","High"]}',
   `version_no`    INT UNSIGNED NOT NULL DEFAULT 1,
   `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`    VARCHAR(3) NOT NULL,
   `updated_by`    VARCHAR(3) NOT NULL,
   `deleted_by`    VARCHAR(3) NULL,
   `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`    TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_suites_code` (`suite_code`),
   INDEX `idx_tst_suites_type` (`suite_type`,`is_active`),
   CONSTRAINT `fk_tst_suites_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_suites_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_suites_deletedBy` FOREIGN KEY (`deleted_by`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Named, reusable collections of test cases. Explicit or rule-based.';


CREATE TABLE IF NOT EXISTS `tst_test_suite_items` (
   `suite_id`       INT UNSIGNED NOT NULL,
   `test_case_code` VARCHAR(21) NOT NULL,
   `priority`       ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
   `sequence_no`    INT UNSIGNED NOT NULL DEFAULT 1,
   `added_by`       VARCHAR(3) NOT NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`suite_id`,`test_case_code`),
   INDEX `idx_tst_suiteItems_case` (`test_case_code`),
   CONSTRAINT `fk_tst_suiteItems_suite` FOREIGN KEY (`suite_id`)       REFERENCES `tst_test_suites`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_suiteItems_case`  FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_suiteItems_by`    FOREIGN KEY (`added_by`)       REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Explicit suite membership, by test_case_code.';


CREATE TABLE IF NOT EXISTS `tst_test_suite_versions` (
   `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `suite_id`       INT UNSIGNED NOT NULL,
   `version_no`     INT UNSIGNED NOT NULL,
   `member_count`   INT UNSIGNED NOT NULL DEFAULT 0,
   `members_json`   JSON NOT NULL   COMMENT 'Resolved membership: ["D02A_T0104010200_001", ...]',
   `change_summary` VARCHAR(1000) NULL,
   `captured_by`    VARCHAR(3) NOT NULL,
   `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_suiteVersions` (`suite_id`,`version_no`),
   CONSTRAINT `fk_tst_suiteVersions_suite` FOREIGN KEY (`suite_id`)    REFERENCES `tst_test_suites`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_suiteVersions_by`    FOREIGN KEY (`captured_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Frozen suite membership per version, so a historical run is reproducible.';


-- =========================================================================================================
-- SECTION 24 — GIT INGESTION ENGINE                                                                 [P2]
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_git_repositories` (
   `repository_code`      VARCHAR(100) NOT NULL,
   `name`                 VARCHAR(150) NOT NULL,
   `local_path`           VARCHAR(1000) NULL,
   `remote_url`           VARCHAR(500) NULL,
   `default_branch`       VARCHAR(200) NULL DEFAULT 'main',
   `last_ingested_commit` VARCHAR(40) NULL   COMMENT 'Ingestion is incremental from here',
   `last_ingested_at`     DATETIME NULL,
   `is_active`            TINYINT(1) NOT NULL DEFAULT 1,
   `created_by`           VARCHAR(3) NOT NULL,
   `created_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`repository_code`),
   CONSTRAINT `fk_tst_gitRepos_createdBy` FOREIGN KEY (`created_by`) REFERENCES `tst_users`(`code`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Registered Git repositories.';


-- commit_hash IS VARCHAR(40), NOT CHAR(64). A Git SHA-1 is 40 hex characters; CHAR(64) pads it, and a
-- hash read from `git log` then never compares equal to a stored one. This was defect 11 in v6.7.
CREATE TABLE IF NOT EXISTS `tst_git_commits` (
   `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `repository_code`    VARCHAR(100) NOT NULL,
   `commit_hash`        VARCHAR(40) NOT NULL,
   `short_hash`         VARCHAR(12) NULL,
   `branch_name`        VARCHAR(200) NULL,
   `parent_commit_hash` VARCHAR(40) NULL,
   `merge_commit_hash`  VARCHAR(40) NULL,
   `author_user_code`   VARCHAR(3) NULL   COMMENT 'Resolved to a Testing Application user where possible',
   `author_name`        VARCHAR(150) NULL,
   `author_email`       VARCHAR(200) NULL,
   `commit_message`     TEXT NULL,
   `is_merge_commit`    TINYINT(1) NOT NULL DEFAULT 0,
   `files_changed`      INT UNSIGNED NOT NULL DEFAULT 0,
   `lines_added`        INT UNSIGNED NOT NULL DEFAULT 0,
   `lines_removed`      INT UNSIGNED NOT NULL DEFAULT 0,
   `committed_at`       DATETIME NULL,
   `ingested_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_gitCommits_repoHash` (`repository_code`,`commit_hash`),
   INDEX `idx_tst_gitCommits_date`   (`committed_at`),
   INDEX `idx_tst_gitCommits_author` (`author_user_code`),
   INDEX `idx_tst_gitCommits_branch` (`branch_name`),
   CONSTRAINT `fk_tst_gitCommits_repo`   FOREIGN KEY (`repository_code`)  REFERENCES `tst_git_repositories`(`repository_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_gitCommits_author` FOREIGN KEY (`author_user_code`) REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Ingested commits. Author resolved to a user code so "who changed" and "who tested" share a vocabulary.';


-- resolution_source records HOW a file was mapped. A high Module_Convention share means the explicit
-- path-mapping rules are thin, which is actionable; without it, nobody knows why the mapping is weak.
CREATE TABLE IF NOT EXISTS `tst_git_commit_files` (
   `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `commit_id`         BIGINT UNSIGNED NOT NULL,
   `file_path`         VARCHAR(1000) NOT NULL,
   `old_file_path`     VARCHAR(1000) NULL,
   `change_type`       ENUM('Added','Modified','Deleted','Renamed','Copied','Unknown') NOT NULL DEFAULT 'Modified',
   `lines_added`       INT UNSIGNED NOT NULL DEFAULT 0,
   `lines_removed`     INT UNSIGNED NOT NULL DEFAULT 0,
   `module_code`       VARCHAR(5)  NULL,
   `ts_code`           VARCHAR(11) NULL,
   `test_case_code`    VARCHAR(21) NULL,
   `resolution_source` ENUM('Test_File','Screen_Path','Path_Mapping','Module_Convention','Manual','Unresolved')
                         NOT NULL DEFAULT 'Unresolved',
   `path_mapping_id`   INT UNSIGNED NULL,
   `impact_level`      ENUM('Low','Medium','High','Critical','Unknown') NOT NULL DEFAULT 'Unknown',
   `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_gitFiles` (`commit_id`,`file_path`(500)),
   INDEX `idx_tst_gitFiles_module`     (`module_code`),
   INDEX `idx_tst_gitFiles_screen`     (`ts_code`),
   INDEX `idx_tst_gitFiles_case`       (`test_case_code`),
   INDEX `idx_tst_gitFiles_resolution` (`resolution_source`),
   CONSTRAINT `fk_tst_gitFiles_commit`  FOREIGN KEY (`commit_id`)       REFERENCES `tst_git_commits`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_gitFiles_module`  FOREIGN KEY (`module_code`)     REFERENCES `tst_modules`(`module_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_gitFiles_screen`  FOREIGN KEY (`ts_code`)         REFERENCES `tst_tabs_screens`(`ts_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_gitFiles_case`    FOREIGN KEY (`test_case_code`)  REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_gitFiles_mapping` FOREIGN KEY (`path_mapping_id`) REFERENCES `tst_path_mappings`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] Changed files with their resolved target AND how the resolution was reached.';


-- =========================================================================================================
-- SECTION 25 — IMPACT ANALYSIS                                                                      [P2]
-- =========================================================================================================
--     An impact analysis is a NAMED, RETAINED, REVIEWABLE PROPOSAL, not a transient list.
--     A PERSON APPROVES BEFORE ANYTHING RUNS.
-- =========================================================================================================


CREATE TABLE IF NOT EXISTS `tst_impact_analyses` (
   `id`                         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `machine_id`                 SMALLINT UNSIGNED NOT NULL,
   `source_analysis_id`         BIGINT UNSIGNED NOT NULL,
   `analysis_name`              VARCHAR(200) NOT NULL,
   `source_type`                ENUM('Commit_Range','Single_Commit','Bug_Fix','Manual','Change_Request') NOT NULL,
   `repository_code`            VARCHAR(100) NULL,
   `from_commit_hash`           VARCHAR(40) NULL,
   `to_commit_hash`             VARCHAR(40) NULL,
   `bug_id`                     BIGINT UNSIGNED NULL,
   `change_request_id`          BIGINT UNSIGNED NULL,
   `requested_by`               VARCHAR(3) NOT NULL,
   `status`                     ENUM('Draft','Proposed','Approved','Rejected','Executed','Superseded')
                                  NOT NULL DEFAULT 'Draft',
   `approved_by`                VARCHAR(3) NULL,
   `approved_at`                DATETIME NULL,
   `executed_run_id`            BIGINT UNSIGNED NULL,
   `changed_file_count`         INT UNSIGNED NOT NULL DEFAULT 0,
   `unresolved_file_count`      INT UNSIGNED NOT NULL DEFAULT 0
                                  COMMENT 'PATHS NO RULE MATCHED. This is the analysis stating its own blind spot',
   `affected_module_count`      INT UNSIGNED NOT NULL DEFAULT 0,
   `affected_screen_count`      INT UNSIGNED NOT NULL DEFAULT 0,
   `proposed_test_count`        INT UNSIGNED NOT NULL DEFAULT 0,
   `included_test_count`        INT UNSIGNED NOT NULL DEFAULT 0,
   `excluded_test_count`        INT UNSIGNED NOT NULL DEFAULT 0,
   -- Measured AFTER the fact: this is how the selection's usefulness becomes measurable (KPI K-11)
   -- rather than assumed.
   `defects_found_in_scope`     INT UNSIGNED NOT NULL DEFAULT 0,
   `defects_found_out_of_scope` INT UNSIGNED NOT NULL DEFAULT 0,
   `parameters_json`            JSON NULL   COMMENT 'The algorithm settings used, so the result is reproducible',
   `summary`                    TEXT NULL,
   `created_at`                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at`                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at`                 TIMESTAMP NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_impact_source` (`machine_id`,`source_analysis_id`),
   INDEX `idx_tst_impact_status` (`status`,`created_at`),
   INDEX `idx_tst_impact_commit` (`repository_code`,`to_commit_hash`),
   INDEX `idx_tst_impact_bug`    (`bug_id`),
   CONSTRAINT `fk_tst_impact_machine`     FOREIGN KEY (`machine_id`)        REFERENCES `tst_machines`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_impact_bug`         FOREIGN KEY (`bug_id`)            REFERENCES `tst_bugs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_impact_changeReq`   FOREIGN KEY (`change_request_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_impact_run`         FOREIGN KEY (`executed_run_id`)   REFERENCES `tst_test_runs`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tst_impact_requestedBy` FOREIGN KEY (`requested_by`)      REFERENCES `tst_users`(`code`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tst_impact_approvedBy`  FOREIGN KEY (`approved_by`)       REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] A reviewable proposal. unresolved_file_count is the analysis stating its blind spot.';


-- EXCLUDED ITEMS ARE RETAINED WITH THEIR REASON. A proposal that shows only what it included is not
-- reviewable — the interesting question is always what it decided to leave out, and why.
CREATE TABLE IF NOT EXISTS `tst_impact_analysis_items` (
   `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `analysis_id`      BIGINT UNSIGNED NOT NULL,
   `test_case_code`   VARCHAR(21) NOT NULL,
   `reason`           ENUM('Direct_Change','Dependency','Historical_Correlation','Open_Bug','Critical',
                           'Regression_Policy','Manual_Addition','Flaky_Excluded','Retired_Excluded',
                           'Orphaned_Excluded','Screen_Excluded','Manual_Removal') NOT NULL,
   `is_included`      TINYINT(1) NOT NULL DEFAULT 1,
   `confidence`       DECIMAL(4,3) NOT NULL DEFAULT 0.500,
   `dependency_depth` TINYINT UNSIGNED NOT NULL DEFAULT 0   COMMENT 'Confidence decays with this',
   `evidence_json`    JSON NULL   COMMENT 'The changed files, commits and prior failures relied upon',
   `decided_by`       VARCHAR(3) NULL   COMMENT 'Set when a person overrode the algorithm',
   `decided_at`       DATETIME NULL,
   `decision_note`    VARCHAR(500) NULL,
   `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_tst_impactItems` (`analysis_id`,`test_case_code`),
   INDEX `idx_tst_impactItems_case`   (`test_case_code`),
   INDEX `idx_tst_impactItems_reason` (`analysis_id`,`is_included`,`reason`),
   CONSTRAINT `chk_tst_impactItems_conf` CHECK (`confidence` BETWEEN 0 AND 1),
   CONSTRAINT `fk_tst_impactItems_analysis`  FOREIGN KEY (`analysis_id`)    REFERENCES `tst_impact_analyses`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_impactItems_case`      FOREIGN KEY (`test_case_code`) REFERENCES `tst_test_cases`(`test_case_code`) ON DELETE CASCADE,
   CONSTRAINT `fk_tst_impactItems_decidedBy` FOREIGN KEY (`decided_by`)     REFERENCES `tst_users`(`code`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='[P2] One proposed test case with its reason, confidence and evidence. Exclusions retained.';


-- =========================================================================================================
-- SECTION 30 — PHASE-2 DEFERRED CONSTRAINTS                                                         [P2]
-- =========================================================================================================
--     THIS IS THE WHOLE POINT OF THE PHASE RULE.
--
--     The five columns below were DECLARED in Phase 1 and left null. Their foreign keys are added HERE,
--     once the Phase-2 tables exist. Phase 2 therefore adds constraints to Phase-1 tables — it never
--     adds, modifies or drops a Phase-1 COLUMN.
--
--     By the time this runs, tst_test_runs holds hundreds of thousands of rows and
--     tst_test_run_results holds millions. ADD CONSTRAINT is an index build and a metadata lock; ADD
--     COLUMN on those tables would have been a rewrite. That difference is the reason for the rule.
--
--     Every statement is guarded, so this section is re-runnable and can be applied to a database that
--     already has some of these constraints.
-- =========================================================================================================

-- A run may have been produced by a suite, and by a specific version of that suite's membership.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_testRuns_suite already present'' AS skipped',
      'ALTER TABLE `tst_test_runs` ADD CONSTRAINT `fk_tst_testRuns_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_test_runs' AND constraint_name = 'fk_tst_testRuns_suite');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A run may have been selected by an impact analysis.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_testRuns_impact already present'' AS skipped',
      'ALTER TABLE `tst_test_runs` ADD CONSTRAINT `fk_tst_testRuns_impact` FOREIGN KEY (`impact_analysis_id`) REFERENCES `tst_impact_analyses`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_test_runs' AND constraint_name = 'fk_tst_testRuns_impact');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A run scope may name a suite or a change request.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_runScopes_suite already present'' AS skipped',
      'ALTER TABLE `tst_test_run_scopes` ADD CONSTRAINT `fk_tst_runScopes_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE SET NULL, ADD CONSTRAINT `fk_tst_runScopes_changeReq` FOREIGN KEY (`change_request_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_test_run_scopes' AND constraint_name = 'fk_tst_runScopes_suite');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A schedule may run a suite.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_schedules_suite already present'' AS skipped',
      'ALTER TABLE `tst_schedules` ADD CONSTRAINT `fk_tst_schedules_suite` FOREIGN KEY (`suite_id`) REFERENCES `tst_test_suites`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_schedules' AND constraint_name = 'fk_tst_schedules_suite');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A bug may relate to a change request.
SET @sql := (
   SELECT IF(COUNT(*) > 0,
      'SELECT ''fk_tst_bugs_changeReq already present'' AS skipped',
      'ALTER TABLE `tst_bugs` ADD CONSTRAINT `fk_tst_bugs_changeReq` FOREIGN KEY (`change_request_id`) REFERENCES `tst_app_requirements`(`id`) ON DELETE SET NULL')
   FROM information_schema.table_constraints
   WHERE table_schema = DATABASE() AND table_name = 'tst_bugs' AND constraint_name = 'fk_tst_bugs_changeReq');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;


-- =========================================================================================================
-- SECTION 31 — PHASE-2 VIEWS                                                                        [P2]
-- =========================================================================================================


-- Which tests cover which change request, and whether they are currently passing.
CREATE OR REPLACE VIEW `vw_change_request_coverage` AS
SELECT
    ar.id                        AS requirement_id,
    ar.req_code,
    ar.title,
    ar.module_code,
    ar.ts_code,
    ar.criticality,
    ar.status,
    COUNT(DISTINCT rtc.test_case_code)                                              AS mapped_test_count,
    COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN rtc.test_case_code END) AS passing_test_count,
    COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN rtc.test_case_code END) AS failing_test_count,
    COUNT(DISTINCT CASE WHEN cs.test_case_code IS NULL THEN rtc.test_case_code END) AS never_executed_count,
    CASE
      WHEN COUNT(rtc.test_case_code) = 0 THEN 'Uncovered'
      WHEN COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN rtc.test_case_code END) > 0 THEN 'Failing'
      WHEN COUNT(DISTINCT CASE WHEN cs.test_case_code IS NULL THEN rtc.test_case_code END) > 0 THEN 'Partially_Verified'
      ELSE 'Verified'
    END                          AS coverage_state
FROM `tst_app_requirements` ar
LEFT JOIN `tst_app_requirement_test_cases` rtc ON rtc.requirement_id = ar.id
LEFT JOIN `tst_test_case_runs_summary`     cs  ON cs.test_case_code = rtc.test_case_code
WHERE ar.is_active = 1
GROUP BY ar.id, ar.req_code, ar.title, ar.module_code, ar.ts_code, ar.criticality, ar.status;


-- Which selection reasons actually find defects. This is how test selection stops being a guess.
CREATE OR REPLACE VIEW `vw_run_test_selection_analysis` AS
SELECT
    ri.selection_reason,
    COUNT(*)                                                             AS selected_count,
    SUM(CASE WHEN ri.final_status = 'Passed' THEN 1 ELSE 0 END)          AS passed_count,
    SUM(CASE WHEN ri.final_status IN ('Failed','Error') THEN 1 ELSE 0 END) AS failed_count,
    ROUND(SUM(CASE WHEN ri.final_status IN ('Failed','Error') THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*),0) * 100, 2)                                 AS defect_find_rate,
    AVG(ri.selection_confidence)                                         AS avg_confidence
FROM `tst_test_run_items` ri
WHERE ri.final_status IS NOT NULL
GROUP BY ri.selection_reason;


-- Did the tests we selected actually catch the defects, or did they escape?
CREATE OR REPLACE VIEW `vw_impact_analysis_effectiveness` AS
SELECT
    ia.id                        AS analysis_id,
    ia.analysis_name,
    ia.source_type,
    ia.status,
    ia.from_commit_hash,
    ia.to_commit_hash,
    ia.changed_file_count,
    ia.unresolved_file_count,
    ROUND(ia.unresolved_file_count / NULLIF(ia.changed_file_count,0) * 100, 2) AS unresolved_percent,
    ia.proposed_test_count,
    ia.included_test_count,
    ia.excluded_test_count,
    ia.defects_found_in_scope,
    ia.defects_found_out_of_scope,
    ROUND(ia.defects_found_in_scope
          / NULLIF(ia.defects_found_in_scope + ia.defects_found_out_of_scope, 0) * 100, 2) AS hit_rate_percent,
    ia.requested_by,
    ia.approved_by,
    ia.approved_at,
    ia.executed_run_id
FROM `tst_impact_analyses` ia
WHERE ia.deleted_at IS NULL;


-- Current and versioned suite membership.
CREATE OR REPLACE VIEW `vw_suite_composition` AS
SELECT
    s.id                         AS suite_id,
    s.suite_code,
    s.name                       AS suite_name,
    s.suite_type,
    s.is_rule_based,
    s.version_no                 AS current_version,
    COUNT(DISTINCT si.test_case_code) AS explicit_member_count,
    COUNT(DISTINCT CASE WHEN cs.last_status = 'Passed' THEN si.test_case_code END)            AS passing,
    COUNT(DISTINCT CASE WHEN cs.last_status IN ('Failed','Error') THEN si.test_case_code END) AS failing,
    COUNT(DISTINCT CASE WHEN cs.is_flaky_confirmed = 1 THEN si.test_case_code END)            AS flaky,
    (SELECT COUNT(*) FROM `tst_test_suite_versions` sv WHERE sv.suite_id = s.id)              AS version_count
FROM `tst_test_suites` s
LEFT JOIN `tst_test_suite_items` si ON si.suite_id = s.id
LEFT JOIN `tst_test_case_runs_summary` cs ON cs.test_case_code = si.test_case_code
WHERE s.is_active = 1
GROUP BY s.id, s.suite_code, s.name, s.suite_type, s.is_rule_based, s.version_no;


-- =========================================================================================================
-- SECTION 32 — PHASE-2 SEED DATA                                                                    [P2]
-- =========================================================================================================
-- Path mappings that resolve the standard Laravel / Prime-AI tree. Priority is lowest-wins, so the
-- most specific rule is evaluated first. The Ignore rules matter as much as the resolving ones: without
-- them, every composer update reads as a change to the whole application.
-- =========================================================================================================
INSERT INTO `tst_path_mappings` (`pattern`,`target_type`,`confidence`,`priority`,`note`,`created_by`,`updated_by`)
VALUES
   ('tests/Browser/**',              'TestCase','0.950', 10,'A Dusk test file maps to the test case it implements','S01','S01'),
   ('Modules/*/app/Http/Controllers/**','Module','0.900', 20,'Controller — direct behaviour change','S01','S01'),
   ('Modules/*/app/Models/**',       'Module',  '0.850', 25,'Model — data behaviour change','S01','S01'),
   ('Modules/*/app/Services/**',     'Module',  '0.900', 22,'Service — business logic change','S01','S01'),
   ('Modules/*/routes/**',           'Module',  '0.800', 30,'Route change — navigation and access','S01','S01'),
   ('Modules/*/resources/views/**',  'Module',  '0.750', 35,'View — UI change','S01','S01'),
   ('Modules/*/database/migrations/**','Module', '0.950', 15,'Migration — schema change, high impact','S01','S01'),
   ('Modules/*/config/**',           'Module',  '0.700', 40,'Configuration change','S01','S01'),
   ('app/**',                        'Module',  '0.600', 60,'Shared application code — broad impact','S01','S01'),
   ('config/**',                     'Module',  '0.600', 65,'Global configuration','S01','S01'),
   ('vendor/**',                     'Ignore',  '1.000',  1,'Third-party code','S01','S01'),
   ('node_modules/**',               'Ignore',  '1.000',  2,'Front-end dependencies','S01','S01'),
   ('storage/**',                    'Ignore',  '1.000',  3,'Runtime storage','S01','S01'),
   ('public/build/**',               'Ignore',  '1.000',  4,'Build output','S01','S01'),
   ('*.lock',                        'Ignore',  '1.000',  5,'Lock files','S01','S01'),
   ('*.md',                          'Ignore',  '0.900',  6,'Documentation','S01','S01')
ON DUPLICATE KEY UPDATE
   `confidence` = VALUES(`confidence`),
   `priority`   = VALUES(`priority`),
   `note`       = VALUES(`note`);


-- =========================================================================================================
-- QUICK REFERENCE — how the coding system flows through the schema
-- =========================================================================================================
--
--  IDENTITY
--     tst_users        code  D02                    role letter + 2 digits
--          |
--     tst_machines     machine_code  D02A           GENERATED: user_code || machine_number
--          |
--  CATALOG (centrally governed, prefix-nested, composite-FK enforced)
--     tst_modules      module_code   SLB
--     tst_categories   cat_code      T01
--     tst_main_menus   mm_code       T0104          contains cat_code
--     tst_sub_menus    sm_code       T010401        contains mm_code
--     tst_tabs_screens ts_code       T0104010200    contains sm_code
--          |
--  AUTHORING (evidence direction — travels with the machine that made it)
--     tst_tc_required_list  tcr_code        D02A_T0104010200_0001    the PLAN
--          |
--     tst_test_cases        test_case_code  D02A_T0104010200_001     the TEST
--          |                                ^^^^ ^^^^^^^^^^^ ^^^
--          |                                machine  screen   seq
--          +-- tst_test_case_steps                 (current version only)
--          +-- tst_test_case_versions_history      (superseded definitions, immutable)
--          +-- tst_test_case_review                (readiness + technical review + sign-off)
--          +-- tst_duplicate_test_case             (equivalence judgements, insert-only)
--          |
--  EXECUTION
--     tst_test_runs  ──▶ tst_test_run_items (test_case_code + WHY selected)
--                              |
--                              ▼
--                        tst_test_run_results   ONE ROW PER ATTEMPT, INSERT-ONLY
--                              +-- tst_test_run_result_steps
--                              +-- tst_run_result_artifacts
--                              |
--                        tst_failure_signatures  (forty failures -> one problem)
--                              |
--                        tst_test_case_runs_summary   DERIVED, rebuildable, checked nightly
--          |
--  DEFECTS
--     tst_bugs  ──▶ tst_bug_occurrences ──▶ tst_retest_cycles ──▶ verified_result_id
--                                                                 (FIXED ≠ VERIFIED)
--          |
--  PHASE 2
--     tst_git_commit_files ──(tst_path_mappings)──▶ module / screen / test_case_code
--                          ──(tst_test_case_dependencies)──▶ dependent test cases
--                          ──▶ tst_impact_analyses ──▶ tst_impact_analysis_items
--                                                       (INCLUDED and EXCLUDED, both with reasons)
--
-- =========================================================================================================
-- TABLE COUNT — 58
-- =========================================================================================================
--   PHASE 1 — 44 tables
--     Platform      (2): tst_app_settings, tst_environment_profiles
--     Identity      (2): tst_users, tst_machines
--     Catalog       (5): tst_modules, tst_categories, tst_main_menus, tst_sub_menus, tst_tabs_screens
--     Authoring     (6): tst_tc_required_list, tst_test_cases, tst_test_case_steps,
--                        tst_test_case_review, tst_test_case_versions_history, tst_duplicate_test_case
--     Execution     (8): tst_test_runs, tst_test_run_scopes, tst_test_run_items, tst_test_run_results,
--                        tst_test_run_result_steps, tst_run_result_artifacts, tst_failure_signatures,
--                        tst_test_case_runs_summary
--     Scheduling    (2): tst_schedules, tst_schedule_targets
--     Comments/Disc (2): tst_run_annotations, tst_discovery_sync_logs
--     Defects       (9): tst_known_issues, tst_known_issue_results, tst_bugs, tst_bug_occurrences,
--                        tst_bug_status_history, tst_bug_comments, tst_bug_links, tst_retest_cycles,
--                        tst_retest_cycle_bugs
--     Sync          (4): tst_data_exports, tst_data_imports, tst_import_record_map, tst_import_conflicts
--     AI            (2): tst_ai_analyses, tst_ai_recommendations
--     Ops           (2): tst_notifications, tst_audit_logs
--
--   PHASE 2 — 14 tables
--     Change req    (3): tst_app_requirements, tst_app_requirement_test_cases, tst_test_case_requirements
--     Dependencies  (2): tst_module_dependencies, tst_test_case_dependencies
--     Path mapping  (1): tst_path_mappings
--     Suites        (3): tst_test_suites, tst_test_suite_items, tst_test_suite_versions
--     Git           (3): tst_git_repositories, tst_git_commits, tst_git_commit_files
--     Impact        (2): tst_impact_analyses, tst_impact_analysis_items
--
--   VIEWS — 21    Phase 1: 17    Phase 2: 4
--
--   REMOVED SINCE v7.0 — 16 tables
--     tst_roles, tst_permissions, tst_role_permissions, tst_user_roles   (owner: small team)
--     tst_releases                                                       (owner: covered by review)
--     tst_code_allocations                                               (the machine segment allocates)
--     tst_source_test_cases                                              (the coding system made it redundant)
--     tst_schema_version                                                 (one app_settings row + Laravel migrations)
--     tst_tags, tst_test_case_tags, tst_test_case_types, tst_test_case_statuses,
--     tst_testing_layers, tst_testing_methods, tst_testing_technologies,
--     tst_master_registry                                                (owner: ENUMs instead of lookups)
-- =========================================================================================================
-- END OF testing_DDL_v7.2.sql
-- =========================================================================================================
