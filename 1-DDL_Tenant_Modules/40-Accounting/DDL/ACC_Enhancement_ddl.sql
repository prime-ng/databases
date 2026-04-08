-- ============================================================================
-- ACCOUNTING MODULE ENHANCEMENT — Generic Cross-Module Event Ledger Mapping
-- File    : ACC_Enhancement_ddl.sql
-- Version : 1.0 — 2026-04-08
-- Author  : DB Architect
-- ============================================================================
-- PURPOSE:
--   Provides a generic, event-driven mechanism for any module (Library,
--   Transport, HR, Inventory, etc.) to trigger accounting entries in the
--   Accounting module via configurable event → voucher line mapping rules.
--
-- PROBLEM WITH EXISTING acc_ledger_mappings:
--   • Maps ONE ledger to a source entity (no event concept)
--   • No Debit / Credit role definition
--   • No voucher type specified
--   • Cannot handle multiple ledger lines per event
--   • Not event-driven — no trigger definition
--
-- SOLUTION (4 new tables):
--   1. acc_module_events          — Event registry (what can trigger accounting)
--   2. acc_event_voucher_configs  — Per-event: voucher type + posting mode
--   3. acc_event_voucher_line_templates — Per-event Dr/Cr line templates
--   4. acc_event_processing_log   — Audit trail of all events processed
--
-- PRE-REQUISITE: ACC_DDL_v2.sql must already be applied.
-- RULE: DO NOT modify ACC_DDL_v2.sql — this file extends it additively.
--
-- EVENTS SEEDED:
--   Library  → LIB_LATE_RETURN_FINE, LIB_LOST_BOOK_FINE,
--               LIB_DAMAGED_BOOK_FINE, LIB_MEMBERSHIP_FEE
--   Transport → TPT_NEW_REGISTRATION, TPT_PICKUP_CHANGE, TPT_MODE_CHANGE
-- ============================================================================


-- ============================================================================
-- TABLE 1: acc_module_events
-- ============================================================================
-- Central registry of all system events across all modules that can trigger
-- accounting voucher creation. Seeded by the system for known events and
-- extensible by adding new rows for any future module — NO schema change needed.
--
-- How it works:
--   • module_code + event_code uniquely identify the event
--   • source_model tells the code which DB table owns the triggering record
--   • When an event fires, the code looks up this table to find the config
-- ============================================================================

CREATE TABLE IF NOT EXISTS `acc_module_events` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`   VARCHAR(30) NOT NULL COMMENT 'Module identifier in UPPER_SNAKE_CASE: LIBRARY, TRANSPORT, HR, INVENTORY, FEES, etc.',
    `event_code`    VARCHAR(60) NOT NULL COMMENT 'Unique event code within the module: LIB_LATE_RETURN_FINE, TPT_NEW_REGISTRATION, etc.',
    `event_name`    VARCHAR(150) NOT NULL COMMENT 'Human-readable event name shown in UI and logs',
    `description`   TEXT NULL COMMENT 'Detailed description of what business action triggers this event',
    `source_model`  VARCHAR(100) NOT NULL COMMENT 'Source DB table that owns the triggering record. e.g., lib_fines, tpt_student_route_allocation_jnt, lib_members',
    `is_system`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = seeded by system (protected from deletion), 0 = custom event added by school',
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag — inactive events are ignored by the processing engine',
    `created_by`    BIGINT UNSIGNED NULL  COMMENT 'FK → sys_users',
    `created_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_acc_me_code`    (`module_code`, `event_code`, `deleted_at`) COMMENT 'One event_code per module (soft-delete aware)',
    INDEX `idx_acc_me_module`       (`module_code`),
    INDEX `idx_acc_me_active`       (`is_active`),
    INDEX `idx_acc_me_source_model` (`source_model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registry of all cross-module business events that can trigger accounting voucher creation';


-- ============================================================================
-- TABLE 2: acc_event_voucher_configs
-- ============================================================================
-- Defines HOW a voucher should be created when a specific event fires:
--   • Which voucher type (RECEIPT, JOURNAL, PAYMENT, etc.)
--   • Whether to auto-post or create as draft
--   • Whether an approver is required
--   • Narration template with runtime placeholders
--
-- One active config per event (enforced by UNIQUE on module_event_id).
-- If a school does NOT configure an event, no voucher is created — explicit
-- opt-in, not opt-out. This gives schools control over which events they
-- want flowing into their books.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `acc_event_voucher_configs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_event_id`   BIGINT UNSIGNED NOT NULL  COMMENT 'FK → acc_module_events',
    `voucher_type_id`   BIGINT UNSIGNED NOT NULL
                        COMMENT 'FK → acc_voucher_types. Typically RECEIPT for income, JOURNAL for internal transfers',
    `cost_center_id`    BIGINT UNSIGNED NULL
                        COMMENT 'FK → acc_cost_centers (optional default cost center for vouchers from this event)',
    `is_auto_post`      TINYINT(1) NOT NULL DEFAULT 0
                        COMMENT '1 = immediately post to ledgers; 0 = create as draft (status=draft in acc_vouchers)',
    `requires_approval` TINYINT(1) NOT NULL DEFAULT 0
                        COMMENT '1 = set voucher status to draft and route to approver; overrides is_auto_post if both = 1',
    `narration_template` VARCHAR(500) NULL
                        COMMENT 'Voucher narration with placeholders: {student_name}, {amount}, {date}, {event_name}, {reference_no}, {module_ref}',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'Soft active flag',
    `created_by`        BIGINT UNSIGNED NULL  COMMENT 'FK → sys_users',
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_acc_evc_event`       (`module_event_id`, `deleted_at`)
                                         COMMENT 'One active config per event',
    INDEX `idx_acc_evc_voucher_type`     (`voucher_type_id`),
    INDEX `idx_acc_evc_cost_center`      (`cost_center_id`),
    INDEX `idx_acc_evc_active`           (`is_active`),
    CONSTRAINT `fk_acc_evc_event`
        FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_vtype`
        FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_cc`
        FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-event voucher creation config: voucher type, posting mode, narration template';


-- ============================================================================
-- TABLE 3: acc_event_voucher_line_templates
-- ============================================================================
-- Defines the DEBIT and CREDIT lines for the voucher created by an event.
-- One event config can have multiple lines — full multi-line double-entry support.
--
-- LEDGER RESOLUTION STRATEGIES (ledger_resolver):
--   fixed          → Use ledger_id column directly (admin configures ledger once)
--   student_ledger → Resolve at runtime: SELECT id FROM acc_ledgers
--                    WHERE student_id = [source_record.student_id] LIMIT 1
--   vendor_ledger  → SELECT id FROM acc_ledgers WHERE vendor_id = [source.vendor_id]
--   employee_ledger→ SELECT id FROM acc_ledgers WHERE employee_id = [source.employee_id]
--
-- AMOUNT RESOLUTION STRATEGIES (amount_resolver):
--   from_source   → Read value of source_amount_field column from source record
--                   e.g., source_model=lib_fines, source_amount_field=amount
--   fixed_amount  → Always use the value in fixed_amount column
--   from_payload  → Use 'amount' key from the event payload JSON passed by the caller
--
-- DESIGN NOTE:
--   For a standard RECEIPT event (e.g., library fine payment):
--     Line 1: entry_type=debit,  ledger_resolver=student_ledger,  → Student Debtor A/c
--     Line 2: entry_type=credit, ledger_resolver=fixed, ledger_id=<Library Fine Income Ledger>
-- ============================================================================

CREATE TABLE IF NOT EXISTS `acc_event_voucher_line_templates` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_voucher_config_id`   BIGINT UNSIGNED NOT NULL
                                COMMENT 'FK → acc_event_voucher_configs',
    `sequence`                  TINYINT UNSIGNED NOT NULL DEFAULT 1
                                COMMENT 'Line order within the voucher (1-based). Determines display order in voucher.',
    `entry_type`                ENUM('debit','credit') NOT NULL
                                COMMENT 'Debit or Credit side of the double-entry line',

    -- ── Ledger Resolution ──────────────────────────────────────────────────
    `ledger_resolver`           ENUM(
                                    'fixed',            -- Use ledger_id column directly
                                    'student_ledger',   -- Resolve from acc_ledgers WHERE student_id = source.student_id
                                    'vendor_ledger',    -- Resolve from acc_ledgers WHERE vendor_id = source.vendor_id
                                    'employee_ledger'   -- Resolve from acc_ledgers WHERE employee_id = source.employee_id
                                ) NOT NULL DEFAULT 'fixed'
                                COMMENT 'Strategy to resolve which ledger to post this line against at runtime',
    `ledger_id`                 BIGINT UNSIGNED NULL
                                COMMENT 'FK → acc_ledgers. Required when ledger_resolver = fixed. NULL for dynamic resolvers.',

    -- ── Amount Resolution ──────────────────────────────────────────────────
    `amount_resolver`           ENUM(
                                    'from_source',      -- Read source_amount_field column value from the source record
                                    'fixed_amount',     -- Always use fixed_amount value
                                    'from_payload'      -- Use amount from event payload JSON
                                ) NOT NULL DEFAULT 'from_source'
                                COMMENT 'Strategy to resolve the line amount at runtime',
    `source_amount_field`       VARCHAR(100) NULL
                                COMMENT 'Column name in source model to read amount from. e.g., amount, fine_amount, fare, paid_amount. Used when amount_resolver = from_source.',
    `fixed_amount`              DECIMAL(15,2) NULL
                                COMMENT 'Hard-coded amount used when amount_resolver = fixed_amount',

    `narration`                 VARCHAR(500) NULL
                                COMMENT 'Per-line narration. Can use same placeholders as narration_template. Overrides header narration for this line.',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'Soft active flag',
    `created_by`                BIGINT UNSIGNED NULL  COMMENT 'FK → sys_users',
    `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_evlt_config`     (`event_voucher_config_id`),
    INDEX `idx_acc_evlt_ledger`     (`ledger_id`),
    INDEX `idx_acc_evlt_type`       (`entry_type`),
    INDEX `idx_acc_evlt_sequence`   (`event_voucher_config_id`, `sequence`),
    CONSTRAINT `fk_acc_evlt_config`
        FOREIGN KEY (`event_voucher_config_id`) REFERENCES `acc_event_voucher_configs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_evlt_ledger`
        FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Dr/Cr line templates for event-triggered vouchers. Supports fixed and dynamic ledger/amount resolution.';


-- ============================================================================
-- TABLE 4: acc_event_processing_log
-- ============================================================================
-- Audit trail of every cross-module event received by the accounting engine
-- and its processing outcome (processed / failed / skipped).
--
-- KEY DESIGN DECISIONS:
--   • source_model + source_id identifies the originating record uniquely
--   • payload_json snapshots key source data at the time of the event
--     (protects audit integrity if source record changes later)
--   • voucher_id links to the created acc_voucher (NULL if failed/skipped)
--   • status = 'skipped' means the event fired but an identical entry already
--     exists (duplicate guard), or the event had no active config
--   • retry_count tracks automated retry attempts for failed events
--   • No UNIQUE on (module_event_id, source_id) — same source record can
--     legitimately fire the same event multiple times
--     (e.g., a transport allocation changes pickup point twice)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `acc_event_processing_log` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_event_id`   BIGINT UNSIGNED NOT NULL  COMMENT 'FK → acc_module_events',
    `source_model`      VARCHAR(100) NOT NULL
                        COMMENT 'Source table name (denormalized from event for fast querying without join)',
    `source_id`         BIGINT UNSIGNED NOT NULL
                        COMMENT 'Primary key of the triggering source record (e.g., lib_fines.id, tpt_student_route_allocation_jnt.id)',
    `payload_json`      JSON NULL
                        COMMENT 'Snapshot of critical fields from the source record at event time. Preserves audit integrity.',
    `voucher_id`        BIGINT UNSIGNED NULL
                        COMMENT 'FK → acc_vouchers. Set after successful processing. NULL if failed or skipped.',
    `status`            ENUM('pending','processed','failed','skipped') NOT NULL DEFAULT 'pending'
                        COMMENT 'pending=queued, processed=voucher created, failed=error, skipped=no config or duplicate guard',
    `error_message`     TEXT NULL
                        COMMENT 'Error detail when status = failed. Includes stack trace or validation message.',
    `retry_count`       TINYINT UNSIGNED NOT NULL DEFAULT 0
                        COMMENT 'Number of automated retry attempts. Used by job scheduler to cap retries.',
    `processed_at`      TIMESTAMP NULL
                        COMMENT 'Timestamp when the event was successfully processed (voucher created)',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'Soft active flag',
    `created_by`        BIGINT UNSIGNED NULL
                        COMMENT 'FK → sys_users. The user whose action triggered the event, or system user if automated.',
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_epl_event`       (`module_event_id`),
    INDEX `idx_acc_epl_source`      (`source_model`, `source_id`)
                                    COMMENT 'Lookup: has this source record already been processed?',
    INDEX `idx_acc_epl_voucher`     (`voucher_id`),
    INDEX `idx_acc_epl_status`      (`status`),
    INDEX `idx_acc_epl_pending`     (`status`, `retry_count`)
                                    COMMENT 'Job queue index: find pending/failed events to retry',
    CONSTRAINT `fk_acc_epl_event`
        FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_epl_voucher`
        FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail of all cross-module events received and their voucher processing outcome';


-- ============================================================================
-- SEED DATA: System Event Registry
-- ============================================================================
-- Seeds the known events for Library and Transport modules.
-- These are is_system = 1 (protected from deletion).
-- Future modules simply INSERT new rows — NO DDL changes required.
--
-- NOTE: acc_event_voucher_configs and acc_event_voucher_line_templates are
-- NOT seeded here because ledger IDs are school-specific. The school admin
-- must configure these mappings via the Accounting → Event Mapping screen
-- after setting up their Chart of Accounts (acc_ledgers).
--
-- EXAMPLE SETUP for LIB_LATE_RETURN_FINE (for reference):
--   INSERT acc_event_voucher_configs:
--     module_event_id   = <id of LIB_LATE_RETURN_FINE>
--     voucher_type_id   = <id of RECEIPT voucher type>
--     is_auto_post      = 0  (draft for librarian to review)
--     narration_template= 'Library late return fine — {student_name} — {date}'
--
--   INSERT acc_event_voucher_line_templates (line 1 — Debit):
--     entry_type        = 'debit'
--     ledger_resolver   = 'student_ledger'  ← auto-resolves student's A/c Receivable
--     amount_resolver   = 'from_source'
--     source_amount_field = 'amount'
--
--   INSERT acc_event_voucher_line_templates (line 2 — Credit):
--     entry_type        = 'credit'
--     ledger_resolver   = 'fixed'
--     ledger_id         = <id of 'Library Fine Income' ledger>
--     amount_resolver   = 'from_source'
--     source_amount_field = 'amount'
-- ============================================================================

INSERT INTO `acc_module_events`
    (`module_code`, `event_code`, `event_name`, `description`, `source_model`, `is_system`, `is_active`, `created_at`, `updated_at`)
VALUES

    -- ── LIBRARY MODULE ─────────────────────────────────────────────────────

    ('LIBRARY', 'LIB_LATE_RETURN_FINE',
     'Library — Late Return Fine',
     'Student returns a book after the due date. Fine is calculated based on overdue days using lib_fine_slab_config. Triggered when lib_fines record is created with fine_type = Late Return.',
     'lib_fines',
     1, 1, NOW(), NOW()),

    ('LIBRARY', 'LIB_LOST_BOOK_FINE',
     'Library — Lost Book Fine',
     'Student reports a book as lost or fails to return it. Fine amount equals book replacement cost or school-configured cap. Triggered when lib_fines record is created with fine_type = Lost Book.',
     'lib_fines',
     1, 1, NOW(), NOW()),

    ('LIBRARY', 'LIB_DAMAGED_BOOK_FINE',
     'Library — Damaged Book Fine',
     'Returned book assessed as damaged beyond acceptable condition. Fine amount set by librarian or configured slab. Triggered when lib_fines record is created with fine_type = Damaged Book.',
     'lib_fines',
     1, 1, NOW(), NOW()),

    ('LIBRARY', 'LIB_MEMBERSHIP_FEE',
     'Library — Membership Fee',
     'Student or staff registers for a library membership or renews an expired one. Fee amount set in lib_membership_types. Triggered on INSERT or renewal update to lib_members.',
     'lib_members',
     1, 1, NOW(), NOW()),

    -- ── TRANSPORT MODULE ───────────────────────────────────────────────────

    ('TRANSPORT', 'TPT_NEW_REGISTRATION',
     'Transport — New Student Registration',
     'Student registers for school transport for the first time in the academic session. Fee is based on route and pickup/drop point fare from tpt_pickup_points_route_jnt. Triggered on INSERT to tpt_student_route_allocation_jnt.',
     'tpt_student_route_allocation_jnt',
     1, 1, NOW(), NOW()),

    ('TRANSPORT', 'TPT_PICKUP_CHANGE',
     'Transport — Pickup/Drop Point Change',
     'Student changes their designated pickup or drop point. May result in a fare difference (additional charge or credit note). Triggered on UPDATE to tpt_student_route_allocation_jnt where pickup_stop_id or drop_stop_id changes.',
     'tpt_student_route_allocation_jnt',
     1, 1, NOW(), NOW()),

    ('TRANSPORT', 'TPT_MODE_CHANGE',
     'Transport — Mode Change (One-Way ↔ Both-Way)',
     'Student switches transport mode between one-way (pickup only or drop only) and both-way (pickup and drop). Results in fare revision. Triggered on UPDATE to tpt_student_route_allocation_jnt where mode changes.',
     'tpt_student_route_allocation_jnt',
     1, 1, NOW(), NOW());


-- ============================================================================
-- QUICK REFERENCE: How the 4 tables connect (processing flow)
-- ============================================================================
--
--  [Other Module Code]
--       │  fires event with: (module_code, event_code, source_id, payload_json)
--       ▼
--  acc_module_events         ← Is this event known & active?
--       │  module_event_id
--       ▼
--  acc_event_voucher_configs ← What voucher type? Auto-post or draft?
--       │  event_voucher_config_id
--       ▼
--  acc_event_voucher_line_templates ← Which ledgers? Dr or Cr? How to get amount?
--       │  resolve ledger_id (fixed or dynamic)
--       │  resolve amount    (from source record or fixed)
--       ▼
--  acc_vouchers + acc_voucher_items ← Voucher created in accounting core
--       │  voucher_id
--       ▼
--  acc_event_processing_log  ← Log the outcome (processed / failed / skipped)
--
-- ============================================================================
-- END OF ACC_Enhancement_ddl.sql
-- ============================================================================
