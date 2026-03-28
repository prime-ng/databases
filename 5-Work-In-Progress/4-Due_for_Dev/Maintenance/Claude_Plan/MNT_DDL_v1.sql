-- =============================================================================
-- MNT — Maintenance Management Module DDL
-- Module: Maintenance (Modules\Maintenance)
-- Table Prefix: mnt_* (11 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-27
-- Based on: MNT_Maintenance_Requirement.md v2
-- Sub-Modules: L1 Asset Categories, L2 Asset Register, L3 Depreciation,
--              L4 Tickets, L5 Assignment, L6 SLA/Escalation,
--              L7 Preventive Maintenance, L8 AMC + Work Orders
-- =============================================================================
-- FK rules:
--   BIGINT UNSIGNED  → sys_* cross-module FKs (sys_users, sys_roles, sys_media)
--   INT UNSIGNED     → mnt_* internal FKs + vnd_* cross-module FKs
-- Exceptions (DDL rule 14):
--   mnt_asset_depreciation : NO is_active, NO updated_by, NO deleted_at
--   mnt_breakdown_history  : NO is_active, NO deleted_at
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ===========================================================================
-- LAYER 1 — No mnt_* dependencies
-- ===========================================================================

CREATE TABLE IF NOT EXISTS `mnt_asset_categories` (
    `id`                      INT UNSIGNED     NOT NULL AUTO_INCREMENT                         COMMENT 'Primary key',
    `name`                    VARCHAR(100)     NOT NULL                                        COMMENT 'Category name e.g. Electrical, Plumbing — unique',
    `code`                    VARCHAR(20)      NULL     DEFAULT NULL                           COMMENT 'Short code e.g. ELEC, PLMB — nullable unique',
    `description`             TEXT             NULL     DEFAULT NULL                           COMMENT 'Optional description of the category scope',
    `default_priority`        ENUM('Low','Medium','High','Critical')
                                               NOT NULL DEFAULT 'Medium'                       COMMENT 'Default ticket priority when no keyword matches; Low|Medium|High|Critical',
    `sla_hours`               SMALLINT UNSIGNED NOT NULL DEFAULT 24                           COMMENT 'Target resolution time in clock hours from ticket creation',
    `auto_assign_role_id`     BIGINT UNSIGNED  NULL     DEFAULT NULL                           COMMENT 'sys_roles.id — role to filter technicians for auto-assignment; NULL = manual only',
    `priority_keywords_json`  JSON             NULL     DEFAULT NULL                           COMMENT 'Keyword-to-priority map: {"High":["leakage"],"Critical":["flood","fire"]}',
    `sla_escalation_json`     JSON             NULL     DEFAULT NULL                           COMMENT 'Multi-level escalation: {"L1":{"after_hours":4,"notify_role":"maintenance-incharge"},"L2":{"after_hours":8,"notify_role":"principal"}}',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1                             COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`              BIGINT UNSIGNED  NOT NULL                                        COMMENT 'sys_users.id — user who created this record',
    `updated_by`              BIGINT UNSIGNED  NOT NULL                                        COMMENT 'sys_users.id — user who last updated this record',
    `created_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Record creation timestamp',
    `updated_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Record last updated timestamp',
    `deleted_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_ac_name` (`name`),
    UNIQUE KEY `uq_mnt_ac_code` (`code`),
    KEY `idx_mnt_ac_role`   (`auto_assign_role_id`),
    KEY `idx_mnt_ac_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Asset category master — defines SLA targets, keyword-priority rules, and escalation config per category';


-- ===========================================================================
-- LAYER 2 — Depends on vnd_vendors (cross-module); placed before mnt_assets
--           to break the mnt_assets ↔ mnt_amc_contracts circular dependency.
--           covered_assets_ids_json avoids a FK back to mnt_assets.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS `mnt_amc_contracts` (
    `id`                      INT UNSIGNED     NOT NULL AUTO_INCREMENT                         COMMENT 'Primary key',
    `contract_number`         VARCHAR(50)      NULL     DEFAULT NULL                           COMMENT 'Contract reference number; nullable unique — may be assigned after creation',
    `contract_title`          VARCHAR(200)     NOT NULL                                        COMMENT 'Short descriptive title of the contract',
    `vendor_id`               INT UNSIGNED     NULL     DEFAULT NULL                           COMMENT 'vnd_vendors.id — linked vendor; NULL when free-text vendor used',
    `vendor_name_text`        VARCHAR(150)     NULL     DEFAULT NULL                           COMMENT 'Free-text vendor name when no vnd_vendors record exists',
    `vendor_contact`          VARCHAR(100)     NULL     DEFAULT NULL                           COMMENT 'Primary contact person at the vendor for this contract',
    `scope_description`       TEXT             NULL     DEFAULT NULL                           COMMENT 'Detailed description of work covered under this AMC',
    `covered_assets_ids_json` JSON             NULL     DEFAULT NULL                           COMMENT 'Array of mnt_assets.id values covered: [1,5,12]',
    `start_date`              DATE             NOT NULL                                        COMMENT 'Contract start date',
    `end_date`                DATE             NOT NULL                                        COMMENT 'Contract end date; expiry alerts triggered relative to this date',
    `contract_value`          DECIMAL(12,2)    NULL     DEFAULT NULL                           COMMENT 'Total contract value in INR',
    `payment_frequency`       ENUM('Monthly','Quarterly','Half_Yearly','Yearly')
                                               NULL     DEFAULT NULL                           COMMENT 'Payment schedule: Monthly|Quarterly|Half_Yearly|Yearly',
    `visit_frequency`         VARCHAR(100)     NULL     DEFAULT NULL                           COMMENT 'Free-text e.g. Monthly — 12 visits/year',
    `status`                  ENUM('Active','Expired','Cancelled','Pending_Renewal')
                                               NOT NULL DEFAULT 'Active'                       COMMENT 'Contract status; auto-set to Expired when end_date < today',
    `renewal_alert_sent_60`   TINYINT(1)       NOT NULL DEFAULT 0                             COMMENT 'Idempotency flag: 1 = 60-day expiry alert already dispatched (BR-MNT-007)',
    `renewal_alert_sent_30`   TINYINT(1)       NOT NULL DEFAULT 0                             COMMENT 'Idempotency flag: 1 = 30-day expiry alert already dispatched (BR-MNT-007)',
    `renewal_alert_sent_7`    TINYINT(1)       NOT NULL DEFAULT 0                             COMMENT 'Idempotency flag: 1 = 7-day expiry alert already dispatched (BR-MNT-007)',
    `document_media_id`       INT UNSIGNED     NULL     DEFAULT NULL                           COMMENT 'sys_media.id — uploaded contract document PDF',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1                             COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`              BIGINT UNSIGNED  NOT NULL                                        COMMENT 'sys_users.id — user who created this record',
    `updated_by`              BIGINT UNSIGNED  NOT NULL                                        COMMENT 'sys_users.id — user who last updated this record',
    `created_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Record creation timestamp',
    `updated_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Record last updated timestamp',
    `deleted_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_amc_contract_number` (`contract_number`),
    KEY `idx_mnt_amc_vendor`      (`vendor_id`),
    KEY `idx_mnt_amc_end_date`    (`end_date`),
    KEY `idx_mnt_amc_status`      (`status`),
    KEY `idx_mnt_amc_document`    (`document_media_id`),
    KEY `idx_mnt_amc_active`      (`is_active`),
    CONSTRAINT `fk_mnt_amc_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Annual Maintenance Contracts with external vendors; renewal_alert_sent_* flags prevent duplicate expiry notifications';


-- ===========================================================================
-- LAYER 3 — Depends on Layer 1 (mnt_asset_categories) + Layer 2 (mnt_amc_contracts) + sys_media
-- ===========================================================================

CREATE TABLE IF NOT EXISTS `mnt_assets` (
    `id`                      INT UNSIGNED     NOT NULL AUTO_INCREMENT                         COMMENT 'Primary key',
    `asset_code`              VARCHAR(30)      NOT NULL                                        COMMENT 'System-generated unique code: MNT-AST-XXXXXX; DB lock-for-update on generation',
    `name`                    VARCHAR(150)     NOT NULL                                        COMMENT 'Descriptive name of the asset',
    `category_id`             INT UNSIGNED     NOT NULL                                        COMMENT 'mnt_asset_categories.id — asset category',
    `location_building`       VARCHAR(100)     NULL     DEFAULT NULL                           COMMENT 'Building name e.g. Main Block, Science Block',
    `location_floor`          VARCHAR(20)      NULL     DEFAULT NULL                           COMMENT 'Floor identifier e.g. Ground Floor, 1st Floor',
    `location_room`           VARCHAR(50)      NULL     DEFAULT NULL                           COMMENT 'Room number or name e.g. Room 204, Lab 3',
    `purchase_date`           DATE             NULL     DEFAULT NULL                           COMMENT 'Date of original asset purchase',
    `purchase_cost`           DECIMAL(12,2)    NULL     DEFAULT NULL                           COMMENT 'Original purchase cost in INR',
    `salvage_value`           DECIMAL(12,2)    NULL     DEFAULT NULL                           COMMENT 'Estimated residual value at end of useful life; used in SLM depreciation',
    `useful_life_years`       TINYINT UNSIGNED NULL     DEFAULT NULL                           COMMENT 'Asset useful life in years; required for SLM depreciation method',
    `depreciation_method`     ENUM('SLM','WDV')
                                               NULL     DEFAULT NULL                           COMMENT 'SLM=Straight Line Method; WDV=Written Down Value; NULL if depreciation not tracked',
    `depreciation_rate`       DECIMAL(5,2)     NULL     DEFAULT NULL                           COMMENT 'Annual depreciation rate as %; required for WDV method',
    `accumulated_depreciation` DECIMAL(12,2)   NOT NULL DEFAULT 0.00                          COMMENT 'Running total of depreciation charged to date; updated by DepreciationService',
    `current_book_value`      DECIMAL(12,2)    NULL     DEFAULT NULL                           COMMENT 'purchase_cost minus accumulated_depreciation; recalculated by DepreciationService',
    `warranty_expiry_date`    DATE             NULL     DEFAULT NULL                           COMMENT 'Date the manufacturer or supplier warranty expires',
    `current_condition`       ENUM('Good','Fair','Poor','Critical','Decommissioned')
                                               NOT NULL DEFAULT 'Good'                         COMMENT 'Physical condition; updated on PM work order completion or manual override',
    `last_pm_date`            DATE             NULL     DEFAULT NULL                           COMMENT 'Date of last completed preventive maintenance work order',
    `next_pm_due_date`        DATE             NULL     DEFAULT NULL                           COMMENT 'Computed next PM due date derived from active pm_schedule.next_due_date',
    `amc_contract_id`         INT UNSIGNED     NULL     DEFAULT NULL                           COMMENT 'mnt_amc_contracts.id — current AMC covering this asset; nullable',
    `total_maintenance_cost`  DECIMAL(12,2)    NOT NULL DEFAULT 0.00                          COMMENT 'Accumulated corrective maintenance cost; recalculated on ticket close + WO completion (BR-MNT-012)',
    `qr_code_media_id`        INT UNSIGNED     NULL     DEFAULT NULL                           COMMENT 'sys_media.id — QR code PNG; auto-generated on first asset save (BR-MNT-015)',
    `photo_media_id`          INT UNSIGNED     NULL     DEFAULT NULL                           COMMENT 'sys_media.id — asset photo',
    `notes`                   TEXT             NULL     DEFAULT NULL                           COMMENT 'General notes or remarks about the asset',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1                             COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`              BIGINT UNSIGNED  NOT NULL                                        COMMENT 'sys_users.id — user who created this record',
    `updated_by`              BIGINT UNSIGNED  NOT NULL                                        COMMENT 'sys_users.id — user who last updated this record',
    `created_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Record creation timestamp',
    `updated_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Record last updated timestamp',
    `deleted_at`              TIMESTAMP        NULL     DEFAULT NULL                           COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_ast_asset_code` (`asset_code`),
    KEY `idx_mnt_ast_category`     (`category_id`),
    KEY `idx_mnt_ast_amc`          (`amc_contract_id`),
    KEY `idx_mnt_ast_qr_media`     (`qr_code_media_id`),
    KEY `idx_mnt_ast_photo_media`  (`photo_media_id`),
    KEY `idx_mnt_ast_condition`    (`current_condition`),
    KEY `idx_mnt_ast_active`       (`is_active`),
    CONSTRAINT `fk_mnt_ast_category_id`     FOREIGN KEY (`category_id`)    REFERENCES `mnt_asset_categories` (`id`),
    CONSTRAINT `fk_mnt_ast_amc_contract_id` FOREIGN KEY (`amc_contract_id`) REFERENCES `mnt_amc_contracts`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='School asset register with depreciation tracking, QR code, and accumulated maintenance cost rollup';


-- ===========================================================================
-- LAYER 4 — Depends on Layer 3 (mnt_assets)
-- ===========================================================================

-- EXCEPTION (DDL rule 14): NO is_active, NO updated_by, NO deleted_at — immutable annual record
CREATE TABLE IF NOT EXISTS `mnt_asset_depreciation` (
    `id`                  INT UNSIGNED    NOT NULL AUTO_INCREMENT                              COMMENT 'Primary key',
    `asset_id`            INT UNSIGNED    NOT NULL                                             COMMENT 'mnt_assets.id — asset being depreciated',
    `financial_year`      VARCHAR(9)      NOT NULL                                             COMMENT 'Financial year in YYYY-YYYY format e.g. 2025-2026',
    `method`              ENUM('SLM','WDV') NOT NULL                                          COMMENT 'Depreciation method used for this year: SLM=Straight Line; WDV=Written Down Value',
    `opening_book_value`  DECIMAL(12,2)   NOT NULL                                             COMMENT 'Book value at start of the financial year',
    `depreciation_rate`   DECIMAL(5,2)    NOT NULL                                             COMMENT 'Rate used: SLM derives (cost-salvage)/life as %; WDV reads from asset.depreciation_rate',
    `annual_charge`       DECIMAL(12,2)   NOT NULL                                             COMMENT 'Depreciation amount for this year; SLM=(cost-salvage)/life; WDV=opening×rate/100',
    `closing_book_value`  DECIMAL(12,2)   NOT NULL                                             COMMENT 'opening_book_value minus annual_charge',
    `posted_to_fac`       TINYINT(1)      NOT NULL DEFAULT 0                                  COMMENT 'FAC integration scaffold: 0=pending posting, 1=journal entry created',
    `fac_journal_id`      INT UNSIGNED    NULL     DEFAULT NULL                                COMMENT 'Future FK to acc_journal_entries.id when FAC module is built',
    `created_by`          BIGINT UNSIGNED NOT NULL                                             COMMENT 'sys_users.id — user who triggered depreciation calculation',
    `created_at`          TIMESTAMP       NULL     DEFAULT NULL                                COMMENT 'Record creation timestamp',
    `updated_at`          TIMESTAMP       NULL     DEFAULT NULL                                COMMENT 'Record last updated timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_adep_asset_year` (`asset_id`, `financial_year`),
    KEY `idx_mnt_adep_asset`  (`asset_id`),
    KEY `idx_mnt_adep_year`   (`financial_year`),
    CONSTRAINT `fk_mnt_adep_asset_id` FOREIGN KEY (`asset_id`) REFERENCES `mnt_assets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Annual depreciation records per asset — immutable; UNIQUE (asset_id, financial_year) prevents double calculation (BR-MNT-016)';


CREATE TABLE IF NOT EXISTS `mnt_pm_schedules` (
    `id`                  INT UNSIGNED    NOT NULL AUTO_INCREMENT                              COMMENT 'Primary key',
    `asset_id`            INT UNSIGNED    NOT NULL                                             COMMENT 'mnt_assets.id — asset this PM schedule applies to',
    `category_id`         INT UNSIGNED    NULL     DEFAULT NULL                                COMMENT 'mnt_asset_categories.id — optional category context for this schedule',
    `title`               VARCHAR(200)    NOT NULL                                             COMMENT 'Schedule title e.g. Monthly AC Filter Cleaning',
    `description`         TEXT            NULL     DEFAULT NULL                                COMMENT 'Detailed description of the maintenance activity',
    `recurrence`          ENUM('Daily','Weekly','Monthly','Quarterly','Yearly')
                                          NOT NULL                                             COMMENT 'Recurrence interval: Daily|Weekly|Monthly|Quarterly|Yearly',
    `recurrence_day`      TINYINT UNSIGNED NULL    DEFAULT NULL                                COMMENT 'Day of week (1-7) for Weekly; day of month (1-31) for Monthly; null for others',
    `checklist_items_json` JSON           NOT NULL                                             COMMENT 'Array of task strings: ["Clean filter","Check pressure"]; minimum 1 item required',
    `start_date`          DATE            NOT NULL                                             COMMENT 'Date from which PM scheduling begins',
    `next_due_date`       DATE            NULL     DEFAULT NULL                                COMMENT 'Next date on which a WO should be generated; advanced after each WO creation',
    `assign_to_role_id`   BIGINT UNSIGNED NULL     DEFAULT NULL                                COMMENT 'sys_roles.id — role used to auto-assign technicians to PM work orders',
    `estimated_hours`     DECIMAL(4,2)    NULL     DEFAULT NULL                                COMMENT 'Estimated hours to complete one PM work order',
    `last_generated_at`   TIMESTAMP       NULL     DEFAULT NULL                                COMMENT 'Timestamp when last PM work order was generated',
    `is_active`           TINYINT(1)      NOT NULL DEFAULT 1                                  COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`          BIGINT UNSIGNED NOT NULL                                             COMMENT 'sys_users.id — user who created this record',
    `updated_by`          BIGINT UNSIGNED NOT NULL                                             COMMENT 'sys_users.id — user who last updated this record',
    `created_at`          TIMESTAMP       NULL     DEFAULT NULL                                COMMENT 'Record creation timestamp',
    `updated_at`          TIMESTAMP       NULL     DEFAULT NULL                                COMMENT 'Record last updated timestamp',
    `deleted_at`          TIMESTAMP       NULL     DEFAULT NULL                                COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    KEY `idx_mnt_pms_asset`    (`asset_id`),
    KEY `idx_mnt_pms_category` (`category_id`),
    KEY `idx_mnt_pms_next_due` (`next_due_date`),
    KEY `idx_mnt_pms_role`     (`assign_to_role_id`),
    KEY `idx_mnt_pms_active`   (`is_active`),
    CONSTRAINT `fk_mnt_pms_asset_id`    FOREIGN KEY (`asset_id`)    REFERENCES `mnt_assets`           (`id`),
    CONSTRAINT `fk_mnt_pms_category_id` FOREIGN KEY (`category_id`) REFERENCES `mnt_asset_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Preventive maintenance schedule definitions with recurrence, checklist items, and next_due_date per asset';


-- ===========================================================================
-- LAYER 5 — Depends on Layer 1 + Layer 3 (mnt_tickets)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS `mnt_tickets` (
    `id`                    INT UNSIGNED    NOT NULL AUTO_INCREMENT                            COMMENT 'Primary key',
    `ticket_number`         VARCHAR(30)     NOT NULL                                           COMMENT 'System-generated: MNT-YYYY-XXXXXXXX; DB lockForUpdate prevents duplicates (BR-MNT-001)',
    `title`                 VARCHAR(200)    NOT NULL                                           COMMENT 'Short descriptive title of the issue',
    `category_id`           INT UNSIGNED    NOT NULL                                           COMMENT 'mnt_asset_categories.id — maintenance category',
    `asset_id`              INT UNSIGNED    NULL     DEFAULT NULL                              COMMENT 'mnt_assets.id — affected asset; nullable for location-only tickets',
    `description`           TEXT            NOT NULL                                           COMMENT 'Detailed problem description; minimum 20 chars enforced at form validation',
    `location_building`     VARCHAR(100)    NOT NULL                                           COMMENT 'Building where issue occurred; required field',
    `location_floor`        VARCHAR(20)     NULL     DEFAULT NULL                              COMMENT 'Floor identifier e.g. 1st Floor',
    `location_room`         VARCHAR(50)     NULL     DEFAULT NULL                              COMMENT 'Room number or name e.g. Room 204',
    `priority`              ENUM('Low','Medium','High','Critical')
                                            NOT NULL                                           COMMENT 'Ticket urgency: Low|Medium|High|Critical; set by keyword scan or manually overridden',
    `priority_source`       ENUM('Auto_Keyword','Auto_Category','Manual_Override')
                                            NOT NULL DEFAULT 'Auto_Category'                   COMMENT 'How priority was set: Auto_Keyword=matched keyword; Auto_Category=default; Manual_Override=admin',
    `status`                ENUM('Open','Accepted','In_Progress','On_Hold','Resolved','Closed','Cancelled')
                                            NOT NULL DEFAULT 'Open'                            COMMENT 'Ticket lifecycle status; FSM transitions enforced; invalid transitions return 422 (BR-MNT-003)',
    `requester_user_id`     BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — staff or student who raised this ticket',
    `assigned_to_user_id`   BIGINT UNSIGNED NULL     DEFAULT NULL                              COMMENT 'sys_users.id — currently assigned technician; NULL if unassigned (BR-MNT-005)',
    `requested_date`        DATE            NOT NULL                                           COMMENT 'Calendar date the ticket was raised',
    `accepted_at`           TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Timestamp when status changed to Accepted',
    `resolved_at`           TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Timestamp when status changed to Resolved',
    `closed_at`             TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Timestamp when status changed to Closed',
    `sla_due_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'SLA deadline = created_at + category.sla_hours (clock hours); set on ticket creation (BR-MNT-002)',
    `is_sla_breached`       TINYINT(1)      NOT NULL DEFAULT 0                                COMMENT '0=within SLA; 1=SLA breached; set by CheckSlaBreachesJob every 30 minutes',
    `escalation_level`      TINYINT UNSIGNED NOT NULL DEFAULT 0                               COMMENT 'SLA escalation stage: 0=none; 1=L1 notified (Maint Incharge); 2=L2 notified (Principal)',
    `resolution_notes`      TEXT            NULL     DEFAULT NULL                              COMMENT 'Required on Resolved transition; minimum 20 chars (BR-MNT-004)',
    `total_hours_logged`    DECIMAL(6,2)    NOT NULL DEFAULT 0.00                             COMMENT 'Accumulated from mnt_ticket_time_logs.hours_spent; updated on each time log entry',
    `total_parts_cost`      DECIMAL(10,2)   NOT NULL DEFAULT 0.00                             COMMENT 'Accumulated from mnt_ticket_time_logs.parts_cost; updated on each time log entry',
    `requester_rating`      TINYINT UNSIGNED NULL    DEFAULT NULL                              COMMENT '1–5 star rating provided by requester after ticket closure',
    `requester_feedback`    TEXT            NULL     DEFAULT NULL                              COMMENT 'Optional free-text feedback from the requester',
    `is_active`             TINYINT(1)      NOT NULL DEFAULT 1                                COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`            BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — user who created this record',
    `updated_by`            BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — user who last updated this record',
    `created_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Record creation timestamp',
    `updated_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Record last updated timestamp',
    `deleted_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_tkt_ticket_number`  (`ticket_number`),
    KEY `idx_mnt_tkt_status_priority`      (`status`, `priority`),
    KEY `idx_mnt_tkt_assigned_status`      (`assigned_to_user_id`, `status`),
    KEY `idx_mnt_tkt_category_status`      (`category_id`, `status`),
    KEY `idx_mnt_tkt_sla_due`              (`sla_due_at`),
    KEY `idx_mnt_tkt_breach_status`        (`is_sla_breached`, `status`),
    KEY `idx_mnt_tkt_asset`                (`asset_id`),
    KEY `idx_mnt_tkt_requester`            (`requester_user_id`),
    KEY `idx_mnt_tkt_active`               (`is_active`),
    CONSTRAINT `fk_mnt_tkt_category_id` FOREIGN KEY (`category_id`) REFERENCES `mnt_asset_categories` (`id`),
    CONSTRAINT `fk_mnt_tkt_asset_id`    FOREIGN KEY (`asset_id`)    REFERENCES `mnt_assets`           (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Corrective maintenance tickets — 7-state FSM, SLA tracking, auto-priority from keywords, escalation levels';


-- ===========================================================================
-- LAYER 6 — Depends on Layer 5 (mnt_tickets children)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS `mnt_ticket_assignments` (
    `id`                    INT UNSIGNED    NOT NULL AUTO_INCREMENT                            COMMENT 'Primary key',
    `ticket_id`             INT UNSIGNED    NOT NULL                                           COMMENT 'mnt_tickets.id — parent ticket',
    `assigned_to_user_id`   BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — technician being assigned',
    `assigned_by_user_id`   BIGINT UNSIGNED NULL     DEFAULT NULL                              COMMENT 'sys_users.id — who made this assignment; NULL for auto-assignments by system',
    `assignment_type`       ENUM('Auto','Manual','Reassigned')
                                            NOT NULL DEFAULT 'Auto'                            COMMENT 'Auto=system auto-assigned; Manual=first manual assignment; Reassigned=subsequent change',
    `is_current`            TINYINT(1)      NOT NULL DEFAULT 1                                COMMENT '1=active assignment for this ticket; 0=superseded; only one record per ticket has is_current=1',
    `assigned_at`           TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP                COMMENT 'Timestamp when this assignment was made',
    `released_at`           TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Timestamp when this assignment was superseded by a reassignment',
    `reassign_reason`       TEXT            NULL     DEFAULT NULL                              COMMENT 'Reason provided by admin or incharge when reassigning to a different technician',
    `is_active`             TINYINT(1)      NOT NULL DEFAULT 1                                COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`            BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — user who created this record',
    `updated_by`            BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — user who last updated this record',
    `created_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Record creation timestamp',
    `updated_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Record last updated timestamp',
    `deleted_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    KEY `idx_mnt_tasn_ticket_current` (`ticket_id`, `is_current`),
    KEY `idx_mnt_tasn_assigned_to`    (`assigned_to_user_id`),
    KEY `idx_mnt_tasn_assigned_by`    (`assigned_by_user_id`),
    CONSTRAINT `fk_mnt_tasn_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `mnt_tickets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Full assignment history per ticket — is_current=1 marks the active assignment; all prior records retained for audit';


CREATE TABLE IF NOT EXISTS `mnt_ticket_time_logs` (
    `id`                INT UNSIGNED    NOT NULL AUTO_INCREMENT                                COMMENT 'Primary key',
    `ticket_id`         INT UNSIGNED    NOT NULL                                               COMMENT 'mnt_tickets.id — ticket this time entry belongs to',
    `logged_by_user_id` BIGINT UNSIGNED NOT NULL                                               COMMENT 'sys_users.id — technician who logged this work session',
    `work_date`         DATE            NOT NULL                                               COMMENT 'Calendar date on which the work was performed',
    `start_time`        TIME            NULL     DEFAULT NULL                                  COMMENT 'Work session start time; optional',
    `end_time`          TIME            NULL     DEFAULT NULL                                  COMMENT 'Work session end time; optional',
    `hours_spent`       DECIMAL(4,2)    NOT NULL                                               COMMENT 'Hours spent in this work session; drives ticket.total_hours_logged',
    `work_description`  TEXT            NULL     DEFAULT NULL                                  COMMENT 'Description of work performed in this session',
    `parts_used`        TEXT            NULL     DEFAULT NULL                                  COMMENT 'Free-text parts description; future FK to inv_items when INV module is built',
    `parts_cost`        DECIMAL(10,2)   NOT NULL DEFAULT 0.00                                 COMMENT 'Cost of parts used in INR; drives ticket.total_parts_cost',
    `is_active`         TINYINT(1)      NOT NULL DEFAULT 1                                    COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`        BIGINT UNSIGNED NOT NULL                                               COMMENT 'sys_users.id — user who created this record',
    `updated_by`        BIGINT UNSIGNED NOT NULL                                               COMMENT 'sys_users.id — user who last updated this record',
    `created_at`        TIMESTAMP       NULL     DEFAULT NULL                                  COMMENT 'Record creation timestamp',
    `updated_at`        TIMESTAMP       NULL     DEFAULT NULL                                  COMMENT 'Record last updated timestamp',
    `deleted_at`        TIMESTAMP       NULL     DEFAULT NULL                                  COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    KEY `idx_mnt_ttl_ticket`     (`ticket_id`),
    KEY `idx_mnt_ttl_logged_by`  (`logged_by_user_id`),
    CONSTRAINT `fk_mnt_ttl_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `mnt_tickets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Time and parts logging per ticket — each row is one technician work session';


-- EXCEPTION (DDL rule 14): NO is_active, NO deleted_at — immutable breakdown event log
CREATE TABLE IF NOT EXISTS `mnt_breakdown_history` (
    `id`              INT UNSIGNED    NOT NULL AUTO_INCREMENT                                  COMMENT 'Primary key',
    `asset_id`        INT UNSIGNED    NOT NULL                                                 COMMENT 'mnt_assets.id — asset that experienced the breakdown',
    `ticket_id`       INT UNSIGNED    NULL     DEFAULT NULL                                    COMMENT 'mnt_tickets.id — source corrective ticket; NULL if manually recorded',
    `breakdown_date`  DATE            NOT NULL                                                 COMMENT 'Date breakdown occurred; = ticket.created_at::date on auto-insert',
    `resolved_date`   DATE            NULL     DEFAULT NULL                                    COMMENT 'Date breakdown was resolved; = ticket.resolved_at::date',
    `downtime_hours`  DECIMAL(6,2)    NULL     DEFAULT NULL                                    COMMENT 'Hours asset was out of service: resolved_at - created_at in hours (BR-MNT-014)',
    `root_cause`      TEXT            NULL     DEFAULT NULL                                    COMMENT 'Optional root cause analysis; may be added post-resolution',
    `cost_incurred`   DECIMAL(10,2)   NOT NULL DEFAULT 0.00                                   COMMENT 'Total parts cost from source ticket at time of auto-insert',
    `created_by`      BIGINT UNSIGNED NOT NULL                                                 COMMENT 'sys_users.id — user or system job that created this record',
    `updated_by`      BIGINT UNSIGNED NOT NULL                                                 COMMENT 'sys_users.id — user who last updated this record',
    `created_at`      TIMESTAMP       NULL     DEFAULT NULL                                    COMMENT 'Record creation timestamp',
    `updated_at`      TIMESTAMP       NULL     DEFAULT NULL                                    COMMENT 'Record last updated timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_mnt_bkd_asset_date` (`asset_id`, `breakdown_date`),
    KEY `idx_mnt_bkd_ticket`     (`ticket_id`),
    CONSTRAINT `fk_mnt_bkd_asset_id`  FOREIGN KEY (`asset_id`)  REFERENCES `mnt_assets`  (`id`),
    CONSTRAINT `fk_mnt_bkd_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `mnt_tickets` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Denormalised breakdown event log per asset — auto-inserted by TicketService on Resolved with asset_id (BR-MNT-014)';


-- ===========================================================================
-- LAYER 7 — Depends on Layers 3, 4, 5 (final layer)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS `mnt_pm_work_orders` (
    `id`                        INT UNSIGNED    NOT NULL AUTO_INCREMENT                        COMMENT 'Primary key',
    `pm_schedule_id`            INT UNSIGNED    NOT NULL                                       COMMENT 'mnt_pm_schedules.id — parent schedule that generated this work order',
    `asset_id`                  INT UNSIGNED    NOT NULL                                       COMMENT 'mnt_assets.id — asset to be serviced; denormalised from pm_schedule for query efficiency',
    `wo_number`                 VARCHAR(30)     NULL     DEFAULT NULL                          COMMENT 'Work order reference: MNT-PM-XXXXXX; auto-generated on creation; nullable unique',
    `due_date`                  DATE            NOT NULL                                       COMMENT 'Date by which PM must be completed; copied from pm_schedule.next_due_date at generation',
    `assigned_to_user_id`       BIGINT UNSIGNED NULL     DEFAULT NULL                          COMMENT 'sys_users.id — technician assigned to complete this work order',
    `status`                    ENUM('Pending','In_Progress','Completed','Overdue','Cancelled')
                                                NOT NULL DEFAULT 'Pending'                     COMMENT 'WO status; Overdue set by MarkOverduePmWorkOrdersJob daily at 07:00 (BR-MNT-013)',
    `checklist_completion_json` JSON            NULL     DEFAULT NULL                          COMMENT 'Per-item completion: [{"item":"Clean filter","done":true,"notes":"Changed filter"}]',
    `completed_at`              TIMESTAMP       NULL     DEFAULT NULL                          COMMENT 'Timestamp when status changed to Completed',
    `hours_spent`               DECIMAL(4,2)    NULL     DEFAULT NULL                          COMMENT 'Total hours technician spent on this work order',
    `is_active`                 TINYINT(1)      NOT NULL DEFAULT 1                            COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`                BIGINT UNSIGNED NOT NULL                                       COMMENT 'sys_users.id — usually system job (GeneratePmWorkOrdersJob)',
    `updated_by`                BIGINT UNSIGNED NOT NULL                                       COMMENT 'sys_users.id — user who last updated this record',
    `created_at`                TIMESTAMP       NULL     DEFAULT NULL                          COMMENT 'Record creation timestamp',
    `updated_at`                TIMESTAMP       NULL     DEFAULT NULL                          COMMENT 'Record last updated timestamp',
    `deleted_at`                TIMESTAMP       NULL     DEFAULT NULL                          COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_pmwo_number`          (`wo_number`),
    KEY `idx_mnt_pmwo_schedule_status`       (`pm_schedule_id`, `status`),
    KEY `idx_mnt_pmwo_asset`                 (`asset_id`),
    KEY `idx_mnt_pmwo_due_date`              (`due_date`),
    KEY `idx_mnt_pmwo_assigned_to`           (`assigned_to_user_id`),
    KEY `idx_mnt_pmwo_status`                (`status`),
    CONSTRAINT `fk_mnt_pmwo_schedule_id` FOREIGN KEY (`pm_schedule_id`) REFERENCES `mnt_pm_schedules` (`id`),
    CONSTRAINT `fk_mnt_pmwo_asset_id`    FOREIGN KEY (`asset_id`)       REFERENCES `mnt_assets`       (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Auto-generated PM work orders by GeneratePmWorkOrdersJob; checklist stored as JSON; BR-MNT-006 prevents duplicates';


CREATE TABLE IF NOT EXISTS `mnt_work_orders` (
    `id`                    INT UNSIGNED    NOT NULL AUTO_INCREMENT                            COMMENT 'Primary key',
    `wo_number`             VARCHAR(30)     NOT NULL                                           COMMENT 'Unique work order number: MNT-WO-XXXXXX; DB lock-for-update on generation',
    `ticket_id`             INT UNSIGNED    NULL     DEFAULT NULL                              COMMENT 'mnt_tickets.id — source corrective ticket that originated this WO; nullable',
    `amc_contract_id`       INT UNSIGNED    NULL     DEFAULT NULL                              COMMENT 'mnt_amc_contracts.id — AMC this WO falls under; nullable',
    `asset_id`              INT UNSIGNED    NULL     DEFAULT NULL                              COMMENT 'mnt_assets.id — asset being serviced; nullable for multi-asset WOs',
    `vendor_id`             INT UNSIGNED    NULL     DEFAULT NULL                              COMMENT 'vnd_vendors.id — vendor executing the work; NULL when free-text vendor used',
    `vendor_name_text`      VARCHAR(150)    NULL     DEFAULT NULL                              COMMENT 'Free-text vendor name when no vnd_vendors record exists',
    `work_description`      TEXT            NOT NULL                                           COMMENT 'Detailed description of work to be performed by the vendor',
    `scheduled_date`        DATE            NULL     DEFAULT NULL                              COMMENT 'Planned date for vendor visit or work commencement',
    `estimated_cost`        DECIMAL(12,2)   NULL     DEFAULT NULL                              COMMENT 'Estimated work cost in INR before work begins',
    `actual_cost`           DECIMAL(12,2)   NULL     DEFAULT NULL                              COMMENT 'Actual cost captured on completion; used for asset.total_maintenance_cost rollup (BR-MNT-012)',
    `purchase_order_number` VARCHAR(50)     NULL     DEFAULT NULL                              COMMENT 'School purchase order number for financial tracking',
    `status`                ENUM('Draft','Issued','In_Progress','Completed','Cancelled')
                                            NOT NULL DEFAULT 'Draft'                           COMMENT 'WO lifecycle: Draft=not sent; Issued=sent to vendor; Completed=work done and cost captured',
    `completed_date`        DATE            NULL     DEFAULT NULL                              COMMENT 'Actual date the vendor completed the work',
    `notes`                 TEXT            NULL     DEFAULT NULL                              COMMENT 'Internal notes about this work order',
    `is_active`             TINYINT(1)      NOT NULL DEFAULT 1                                COMMENT 'Soft enable/disable; 1=active, 0=inactive',
    `created_by`            BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — user who created this record',
    `updated_by`            BIGINT UNSIGNED NOT NULL                                           COMMENT 'sys_users.id — user who last updated this record',
    `created_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Record creation timestamp',
    `updated_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Record last updated timestamp',
    `deleted_at`            TIMESTAMP       NULL     DEFAULT NULL                              COMMENT 'Soft delete timestamp; NULL = not deleted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_mnt_wo_number`   (`wo_number`),
    KEY `idx_mnt_wo_ticket`         (`ticket_id`),
    KEY `idx_mnt_wo_amc`            (`amc_contract_id`),
    KEY `idx_mnt_wo_asset`          (`asset_id`),
    KEY `idx_mnt_wo_vendor`         (`vendor_id`),
    KEY `idx_mnt_wo_status`         (`status`),
    KEY `idx_mnt_wo_active`         (`is_active`),
    CONSTRAINT `fk_mnt_wo_ticket_id`       FOREIGN KEY (`ticket_id`)       REFERENCES `mnt_tickets`       (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_mnt_wo_amc_contract_id` FOREIGN KEY (`amc_contract_id`) REFERENCES `mnt_amc_contracts` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_mnt_wo_asset_id`        FOREIGN KEY (`asset_id`)        REFERENCES `mnt_assets`        (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_mnt_wo_vendor_id`       FOREIGN KEY (`vendor_id`)       REFERENCES `vnd_vendors`       (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='External vendor work orders — DomPDF printable; actual_cost rolled up to asset.total_maintenance_cost on completion (BR-MNT-012)';


SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- END OF MNT DDL — 11 tables created
-- mnt_asset_categories | mnt_amc_contracts | mnt_assets
-- mnt_asset_depreciation | mnt_pm_schedules
-- mnt_tickets
-- mnt_ticket_assignments | mnt_ticket_time_logs | mnt_breakdown_history
-- mnt_pm_work_orders | mnt_work_orders
-- =============================================================================
