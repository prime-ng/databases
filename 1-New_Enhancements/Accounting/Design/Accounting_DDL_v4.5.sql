-- =========================================================================================================
-- PRIME-AI — ACCOUNTING MODULE DDL
-- Prefix    : acc_
-- Version   : 4.5
-- Supersedes: Accounting_DDL_v4.4.sql  (which was truncated mid-file, after acc_bill_allocations)
-- MySQL     : 8.0.16 or later   (CHECK constraints are enforced from 8.0.16)
-- Scope     : TENANT database only. No acc_* table ever exists in prime_db / global_master.
-- Governed by  : Accounting_BRD_v2.md      (business requirement)
-- Designed in  : Solution_Design_v1.md     (solution design)
-- Screens      : ScreenDesign_v2.1.md      (voucher entry)
-- =========================================================================================================
--
-- WHAT THIS SCHEMA IS
--     Tally-style double-entry bookkeeping for a school: voucher header + Dr/Cr lines, with everything
--     else derived from those lines. It is the financial record of a trust or society that collects fees,
--     receives restricted grants and donations, pays salaries and vendors, and must satisfy a statutory
--     auditor.
--
-- ---------------------------------------------------------------------------------------------------------
-- THE FOUR RULES THIS SCHEMA EXISTS TO ENFORCE   (BRD §58)
-- ---------------------------------------------------------------------------------------------------------
--     R-01  Debits equal credits, in every posted voucher, always.
--     R-02  Only POSTED transactions count. Draft, provisional and post-dated affect nothing.
--     R-03  Posted is immutable. Correct by reversal, never by edit.
--     R-05  Balances are DERIVED from acc_voucher_items, never independently asserted.
--
--     Rule R-05 is why acc_ledgers.closing_balance has been REMOVED in this version. A stored balance with
--     no maintenance rule is a number that will eventually disagree with the transactions behind it, and
--     nothing will notice. Balances now live in acc_ledger_period_balances, which is a cache with an
--     explicit owner (PostingService), a rebuild command (acc:rebuild-balances) and a nightly assertion
--     that the rebuild changes nothing.
--
-- ---------------------------------------------------------------------------------------------------------
-- TYPE DISCIPLINE  —  one width per concept, everywhere
-- ---------------------------------------------------------------------------------------------------------
--     v4.3 joined columns of different integer widths across 12 foreign keys. InnoDB rejects every one of
--     them. In v4.4 a concept has exactly one width wherever it appears:
--
--       SMALLINT UNSIGNED   config and small reference sets   voucher types, financial years, periods,
--                                                             tax types, currencies, campuses, categories
--       INT UNSIGNED        masters                           account groups, ledgers, cost centres, funds
--       BIGINT UNSIGNED     transactions and logs             vouchers, items, allocations, bill refs, audit
--       INT UNSIGNED        external tenant tables            sys_users, sys_media, std_students,
--                                                             sch_employees, vnd_vendors, sys_dropdown_table
--
-- ---------------------------------------------------------------------------------------------------------
-- SOFT-DELETE UNIQUENESS
-- ---------------------------------------------------------------------------------------------------------
--     v4.3 used UNIQUE(code, deleted_at) in six tables to make a unique key soft-delete aware. It does not
--     work: MySQL treats NULLs as distinct, so any number of LIVE rows may share the same code.
--
--     v4.4 uses a stored generated column:
--         del_marker  =  0                        while the row is live
--                     =  UNIX_TIMESTAMP(deleted_at)  once it is deleted
--         UNIQUE (code, del_marker)
--     One live row per code; deleted rows keep their history. (Two rows soft-deleted in the same second
--     with the same code would collide — which is the correct outcome, not a defect.)
--
-- ---------------------------------------------------------------------------------------------------------
-- DEFECTS CORRECTED FROM v4.3   (Solution_Design_v1 §17.1. Items 1-9 stop the script from executing.)
-- ---------------------------------------------------------------------------------------------------------
--      1. acc_voucher_category declared FKs on debit_ledger_id / credit_ledger_id — columns that do not
--         exist.                                                              -> CREATE TABLE failed.
--      2. acc_voucher_category referenced tco_app_modules, a table that does not exist. The module
--         registry is glb_app_modules, keyed VARCHAR(10), and lives in the GLOBAL database.
--                                                                             -> module_key, no cross-db FK.
--      3. acc_cost_centers: `ON DELETE SET NUL`.                              -> syntax error; SET NULL.
--      4. acc_vouchers indexed source_module, cost_center_id and date — none of the three declared. They
--         exist in the DEPLOYED table; the column list was edited and the index list was not.
--                                                                             -> lists now agree.
--      5. acc_voucher_items: index and FK on an undeclared cost_center_id.    -> moved to the child table.
--      6. acc_fixed_assets: index and FK on voucher_id, which was commented out. -> declared.
--      7. ~45 lines of raw, uncommented assignment text after acc_expense_claim_lines.
--                                                                             -> moved into comments.
--      8. fk_acc_rtl_template / idx_acc_rtl_template declared in two tables. FK names are unique per
--         schema in MySQL.                                                    -> distinct names.
--      9. 12 foreign keys joined mismatched integer widths.                   -> see TYPE DISCIPLINE.
--     10. UNIQUE(code, deleted_at) permitted unlimited live duplicates.       -> see SOFT-DELETE.
--     11. One generic status table FK'd from every entity, so a voucher's status could point at an
--         expense-claim status.                                               -> typed ENUMs.
--     12. acc_ledgers.closing_balance stored with no maintenance rule.        -> derived (R-05).
--     13. acc_voucher_types.last_number — a lost update under concurrency.    -> locked sequence table.
--     14. bill_reference VARCHAR(100) made BRD §17 unimplementable.           -> references + allocations.
--     15. No currency anywhere.                                               -> currency + rates.
--     16. Comment claimed optional vouchers appear in financial reports. That contradicts BRD BR-PROV-01.
--                                                                             -> corrected.
--     17. is_cancelled flag beside status — two sources of truth for one state. -> single status.
--     18. No accounting period entity, so monthly close was impossible.       -> periods + snapshots.
--     19. No audit table at all. The module was unauditable.                  -> acc_audit_logs.
--     20. Header said 4.2 in the file named 4.3, and the text had drifted from the deployed schema.
--
-- ---------------------------------------------------------------------------------------------------------
-- EXTERNAL TABLES REFERENCED   (all in the same tenant database, all INT UNSIGNED primary keys)
-- ---------------------------------------------------------------------------------------------------------
--     sys_users · sys_media · sys_dropdown_table · std_students · sch_employees · vnd_vendors
--
--     glb_app_modules lives in the GLOBAL database and is keyed VARCHAR(10). A cross-database foreign key
--     would break tenant portability, so module_key is stored as a plain, indexed VARCHAR(10) and its
--     integrity is enforced by the application.
--
-- ---------------------------------------------------------------------------------------------------------
-- SECTIONS
-- ---------------------------------------------------------------------------------------------------------
--      1  Organisation: campuses, currencies, financial years, accounting periods
--      2  Chart of accounts: groups, ledgers
--      3  Dimensions: cost categories, cost centres, funds
--      4  Voucher configuration: categories, types, numbering, approval policy
--      5  Tax configuration
--      6  Transactions: vouchers, items, dimensions, tax, bank, references, approvals
--      7  Bill-wise: references and allocations
--      8  Balances: ledger-period buckets, closing snapshots, opening balances, fund and bill caches,
--                   period-close checklist
--      9  Banking: cheque registers and lifecycle, reconciliation, statement import, matches
--     10  Recurring vouchers
--     11  Fixed assets, depreciation and disposal
--     12  Expense claims
--     13  Budgets, interest and credit control
--     14  School-specific: concessions, donations and 80G, grants
--     15  TDS: certificates, deductions, challans
--     16  Cross-module integration: events, configs, processing log, reconciliation
--     17  Tally export
--     18  Control: audit, exceptions, assertions, settings
--     19  Views
--     20  Seed data
--
-- ---------------------------------------------------------------------------------------------------------
-- WHAT 4.5 IS
-- ---------------------------------------------------------------------------------------------------------
--     4.4 was written to this plan but was cut off part-way through, ending after acc_bill_allocations.
--     Sections 1-7 below are that work, carried forward unchanged. Sections 8-20 are new in 4.5 and
--     complete the plan. Nothing in Sections 1-7 has been re-opened, so a reader who has already reviewed
--     4.4 need only read from SECTION 8 onward.
--
--     Sections 8-20 apply the same four rules. In particular they refuse, three more times, to store a
--     number that has no maintenance rule (R-05):
--
--       * acc_fixed_assets keeps NO current_value or accumulated_depreciation. v4.3 stored both with
--         nothing to keep them true. Net block is derived from purchase cost less posted depreciation
--         less disposal, and vw_fixed_asset_register is the one place that arithmetic lives (BRD BR-FA-07).
--       * acc_bank_statement_entries keeps NO matched_voucher_item_id. The match is a row in
--         acc_bank_reconciliation_matches, which can be proposed, confirmed, rejected and undone —
--         none of which a single nullable column can express (BRD BR-BRS-03, BR-BRS-05).
--       * Bill outstanding, fund utilisation and ledger balances are caches with a named owner, a rebuild
--         command and a nightly assertion that the rebuild changes nothing.
--
--     Every cache table in Section 8 carries the same three columns for that purpose:
--         last_voucher_item_id · last_rebuilt_at · is_stale
--
--     ONE CARRIED-FORWARD KEY WAS ALSO CORRECTED. acc_voucher_number_sequences (Section 4) declared
--     UNIQUE (voucher_type_id, financial_year_id, period_id) with period_id NULL for every type that
--     does not restart monthly. MySQL treats NULLs as distinct, so that key permitted two sequence rows
--     for the same type and year — and two vouchers taking the same number, which is the exact defect
--     the sequence table was introduced to fix. It now uses a generated period_marker.
--
--     The same NULL-safe marker pattern is applied throughout Sections 8-20 wherever a unique key spans
--     a nullable column: acc_ledger_period_balances, acc_opening_balances, acc_fund_balances,
--     acc_budget_lines, acc_event_voucher_configs, acc_ledger_mappings, acc_settings and
--     acc_interest_computations.
-- =========================================================================================================

SET NAMES utf8mb4;
SET SESSION sql_require_primary_key = 0;
SET FOREIGN_KEY_CHECKS = 0;


-- =========================================================================================================
-- SECTION 1: ORGANISATION, CURRENCY AND TIME
-- =========================================================================================================

-- A school may run several campuses under one legal entity. Multi-campus reporting is Phase 4, but the
-- dimension is carried from Phase 1: adding a dimension to posted history later is far more expensive
-- than carrying a mostly-constant column now (Solution_Design_v1 OD-02).
CREATE TABLE IF NOT EXISTS `acc_campuses` (
    `id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`          VARCHAR(20) NOT NULL,
    `name`          VARCHAR(150) NOT NULL,
    `address`       VARCHAR(500) NULL,
    `is_primary`    TINYINT(1) NOT NULL DEFAULT 0,      -- exactly one campus is primary
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`    INT UNSIGNED NULL,
    `updated_by`    INT UNSIGNED NULL,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    `del_marker`    BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_campus_code` (`code`,`del_marker`),
    INDEX `idx_acc_campus_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Physical campuses of one legal entity. A reporting dimension, not a separate set of books.';


CREATE TABLE IF NOT EXISTS `acc_currencies` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              CHAR(3) NOT NULL,               -- ISO 4217: INR, USD, GBP
    `name`              VARCHAR(60) NOT NULL,
    `symbol`            VARCHAR(10) NOT NULL,
    `decimal_places`    TINYINT UNSIGNED NOT NULL DEFAULT 2,
    `is_base`           TINYINT(1) NOT NULL DEFAULT 0,  -- exactly one base currency. INR for Prime-AI.
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_currency_code` (`code`),
    INDEX `idx_acc_currency_base` (`is_base`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- The rate USED on a transaction is copied onto the voucher and never read back from here, so that a
-- later rate change cannot alter a recorded transaction (BRD BR-FX-02, BR-FX-05).
CREATE TABLE IF NOT EXISTS `acc_exchange_rates` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `currency_id`       SMALLINT UNSIGNED NOT NULL,
    `rate_date`         DATE NOT NULL,
    `rate_to_base`      DECIMAL(18,8) NOT NULL,         -- 1 unit of currency = rate_to_base units of base
    `rate_type`         ENUM('Standard','Selling','Buying','Custom') NOT NULL DEFAULT 'Standard',
    `source`            VARCHAR(100) NULL,
    `created_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fx_rate` (`currency_id`,`rate_date`,`rate_type`),
    INDEX `idx_acc_fx_date` (`rate_date`),
    CONSTRAINT `chk_acc_fx_positive` CHECK (`rate_to_base` > 0),
    CONSTRAINT `fk_acc_fx_currency` FOREIGN KEY (`currency_id`) REFERENCES `acc_currencies`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 1 April to 31 March in India. Fixed, not user-choosable.
CREATE TABLE IF NOT EXISTS `acc_financial_years` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(20) NOT NULL,           -- '2026-27'
    `start_date`        DATE NOT NULL,
    `end_date`          DATE NOT NULL,
    -- Current: the year new vouchers default into. Exactly one at a time.
    -- Open: may still receive vouchers. More than one year may be open, to permit prior-year adjustment
    -- before finalisation (BRD BR-PERIOD-03).
    `is_current`        TINYINT(1) NOT NULL DEFAULT 0,
    `status`            ENUM('Open','Soft_Closed','Hard_Closed') NOT NULL DEFAULT 'Open',
    `closed_at`         DATETIME NULL,
    `closed_by`         INT UNSIGNED NULL,
    `carry_forward_at`  DATETIME NULL,                  -- when opening balances were generated for the next year
    `carry_forward_by`  INT UNSIGNED NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fy_name` (`name`),
    UNIQUE KEY `uq_acc_fy_start` (`start_date`),
    INDEX `idx_acc_fy_dates` (`start_date`,`end_date`),
    INDEX `idx_acc_fy_current` (`is_current`),
    INDEX `idx_acc_fy_status` (`status`),
    -- v4.3 commented that the difference is 365 days. It is 366 in a leap year. The real rule is simply
    -- that the year ends after it starts; the 12-month span is enforced by the application.
    CONSTRAINT `chk_acc_fy_dates` CHECK (`end_date` > `start_date`),
    CONSTRAINT `fk_acc_fy_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_fy_cf_by` FOREIGN KEY (`carry_forward_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Twelve monthly periods per financial year, each independently closable. Entirely absent from v4.3,
-- which made monthly close impossible and left BRD §9 unimplementable.
--
-- Open        : normal entry
-- Soft_Closed : routine entry blocked; adjustments permitted with acc.period.adjust
-- Hard_Closed : nothing changes, ever, without an authorised reopening
CREATE TABLE IF NOT EXISTS `acc_accounting_periods` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `financial_year_id` SMALLINT UNSIGNED NOT NULL,
    `period_no`         TINYINT UNSIGNED NOT NULL,      -- 1..12, 1 = April
    `name`              VARCHAR(30) NOT NULL,           -- 'Apr 2026'
    `start_date`        DATE NOT NULL,
    `end_date`          DATE NOT NULL,
    `status`            ENUM('Open','Soft_Closed','Hard_Closed') NOT NULL DEFAULT 'Open',
    `closed_at`         DATETIME NULL,
    `closed_by`         INT UNSIGNED NULL,
    `reopened_at`       DATETIME NULL,
    `reopened_by`       INT UNSIGNED NULL,
    `reopen_reason`     VARCHAR(500) NULL,
    `reopen_count`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_period_fy_no` (`financial_year_id`,`period_no`),
    UNIQUE KEY `uq_acc_period_start` (`start_date`),
    INDEX `idx_acc_period_dates` (`start_date`,`end_date`),
    INDEX `idx_acc_period_status` (`status`),
    CONSTRAINT `chk_acc_period_no` CHECK (`period_no` BETWEEN 1 AND 12),
    CONSTRAINT `chk_acc_period_dates` CHECK (`end_date` >= `start_date`),
    CONSTRAINT `fk_acc_period_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_period_closed_by` FOREIGN KEY (`closed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_period_reopened_by` FOREIGN KEY (`reopened_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 2: CHART OF ACCOUNTS
-- =========================================================================================================

-- The classification tree. `nature` decides which statement a ledger appears in and may never change once
-- posted transactions exist beneath it (BRD BR-GROUP-01) — enforced by the application, because MySQL
-- cannot express "no descendant has transactions" in a CHECK.
CREATE TABLE IF NOT EXISTS `acc_account_groups` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(30) NOT NULL,
    `name`                  VARCHAR(120) NOT NULL,
    `alias`                 VARCHAR(120) NULL,
    `parent_id`             INT UNSIGNED NULL,
    `nature`                ENUM('Asset','Liability','Equity','Income','Expense') NOT NULL,
    -- A school's Income & Expenditure separates direct (academic) from indirect (administrative).
    `affects_gross_profit`  TINYINT(1) NOT NULL DEFAULT 0,
    -- Materialised path, e.g. '/1/14/57/'. Makes "every ledger under this group" one indexed LIKE
    -- instead of a recursive CTE on every statement run.
    `path`                  VARCHAR(500) NULL,
    `depth`                 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_system`             TINYINT(1) NOT NULL DEFAULT 0,  -- may not be deleted or have its nature changed
    `is_subledger`          TINYINT(1) NOT NULL DEFAULT 0,  -- party control account: Sundry Debtors, Sundry Creditors
    `ordinal`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ag_code` (`code`,`del_marker`),
    UNIQUE KEY `uq_acc_ag_name` (`name`,`del_marker`),
    INDEX `idx_acc_ag_parent` (`parent_id`,`ordinal`),
    INDEX `idx_acc_ag_nature` (`nature`,`is_active`),
    INDEX `idx_acc_ag_path` (`path`(191)),
    INDEX `idx_acc_ag_system` (`is_system`,`is_active`),
    CONSTRAINT `chk_acc_ag_not_self` CHECK (`parent_id` IS NULL OR `parent_id` <> `id`),
    CONSTRAINT `fk_acc_ag_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_account_groups`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ag_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ag_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Chart of accounts hierarchy. nature drives statement placement and is immutable once used.';


-- An individual account head.
--
-- NOTE ON BALANCES. v4.3 carried opening_balance, closing_balance and their Dr/Cr types on this row, with
-- nothing stating when they change. They are gone. A ledger's balance is:
--        opening (acc_opening_balances)  +  Σ posted lines (acc_voucher_items)
-- served through acc_ledger_period_balances, which is a maintained cache with a rebuild command and a
-- nightly assertion that rebuilding changes nothing. See BRD BR-LEDGER-02 and R-05.
CREATE TABLE IF NOT EXISTS `acc_ledgers` (
    `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                      VARCHAR(30) NULL,
    `name`                      VARCHAR(150) NOT NULL,
    `alias`                     VARCHAR(150) NULL,
    `account_group_id`          INT UNSIGNED NOT NULL,
    `campus_id`                 SMALLINT UNSIGNED NULL,     -- NULL = shared across campuses
    `currency_id`               SMALLINT UNSIGNED NULL,     -- NULL = base currency

    -- ── Behavioural traits (BRD BR-LEDGER-04) ───────────────────────────────────────────────────────────
    `ledger_type`               ENUM('General','Cash','Bank','Party','Tax','Fund','Suspense','Rounding','Control')
                                NOT NULL DEFAULT 'General',
    `party_type`                ENUM('Student','Parent','Vendor','Employee','Donor','Grantor','Other') NULL,
    `is_bill_wise`              TINYINT(1) NOT NULL DEFAULT 0,  -- outstanding tracked per bill reference
    `is_cost_centre_applicable` TINYINT(1) NOT NULL DEFAULT 0,
    `is_fund_applicable`        TINYINT(1) NOT NULL DEFAULT 0,
    `allow_reconciliation`      TINYINT(1) NOT NULL DEFAULT 0,
    `is_interest_applicable`    TINYINT(1) NOT NULL DEFAULT 0,
    `is_tds_applicable`         TINYINT(1) NOT NULL DEFAULT 0,
    `tds_section`               VARCHAR(20) NULL,               -- '194C', '194J', '192'

    -- ── Party links. Exactly one master per party ledger (BRD BR-LEDGER-05). ────────────────────────────
    `student_id`                INT UNSIGNED NULL,
    `employee_id`               INT UNSIGNED NULL,
    `vendor_id`                 INT UNSIGNED NULL,

    -- ── Bank identification (BRD BR-LEDGER-06) ──────────────────────────────────────────────────────────
    `bank_name`                 VARCHAR(120) NULL,
    `bank_branch`               VARCHAR(120) NULL,
    `bank_account_number`       VARCHAR(50) NULL,
    `bank_account_type`         ENUM('Savings','Current','OD','CC','FD','Other') NULL,
    `ifsc_code`                 VARCHAR(20) NULL,
    `swift_code`                VARCHAR(20) NULL,
    `micr_code`                 VARCHAR(20) NULL,

    -- ── Party commercial terms ──────────────────────────────────────────────────────────────────────────
    `credit_limit`              DECIMAL(15,2) NULL,
    `credit_days`               SMALLINT UNSIGNED NULL,
    `credit_limit_action`       ENUM('None','Warn','Approve','Block') NOT NULL DEFAULT 'Warn',

    -- ── Statutory ───────────────────────────────────────────────────────────────────────────────────────
    `gst_registration_type`     ENUM('Regular','Composition','Unregistered','SEZ','Consumer','Overseas') NULL,
    `gstin`                     VARCHAR(20) NULL,
    `pan`                       VARCHAR(15) NULL,
    `tan`                       VARCHAR(15) NULL,
    `state_code`                VARCHAR(5) NULL,                -- drives place of supply
    `address`                   VARCHAR(500) NULL,
    `contact_person`            VARCHAR(120) NULL,
    `phone`                     VARCHAR(30) NULL,
    `email`                     VARCHAR(150) NULL,

    `is_system`                 TINYINT(1) NOT NULL DEFAULT 0,  -- Cash, Suspense, Rounding, control accounts
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `notes`                     VARCHAR(1000) NULL,
    `created_by`                INT UNSIGNED NULL,
    `updated_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ledger_name` (`name`,`del_marker`),
    UNIQUE KEY `uq_acc_ledger_code` (`code`,`del_marker`),
    -- One ledger per party master (BRD BR-LEDGER-05).
    UNIQUE KEY `uq_acc_ledger_student` (`student_id`,`del_marker`),
    UNIQUE KEY `uq_acc_ledger_employee` (`employee_id`,`del_marker`),
    UNIQUE KEY `uq_acc_ledger_vendor` (`vendor_id`,`del_marker`),
    INDEX `idx_acc_ledger_group` (`account_group_id`,`is_active`),
    INDEX `idx_acc_ledger_type` (`ledger_type`,`is_active`),
    INDEX `idx_acc_ledger_party` (`party_type`,`is_active`),
    INDEX `idx_acc_ledger_campus` (`campus_id`),
    INDEX `idx_acc_ledger_billwise` (`is_bill_wise`,`is_active`),
    INDEX `idx_acc_ledger_recon` (`allow_reconciliation`,`is_active`),
    INDEX `idx_acc_ledger_gstin` (`gstin`),
    INDEX `idx_acc_ledger_pan` (`pan`),
    -- Ledger picker: prefix search over active ledgers.
    INDEX `idx_acc_ledger_search` (`is_active`,`name`),

    CONSTRAINT `fk_acc_ledger_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ledger_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ledger_currency` FOREIGN KEY (`currency_id`) REFERENCES `acc_currencies`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ledger_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ledger_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ledger_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ledger_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ledger_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Account heads. Balances are DERIVED (acc_ledger_period_balances), never stored here.';


-- =========================================================================================================
-- SECTION 3: DIMENSIONS
--
--     Three orthogonal axes. They answer different questions and must never be collapsed into one another:
--         Cost Centre  — WHERE did the money go?      Primary Wing, Science Dept, Annual Day
--         Fund         — WHOSE money was it?          Corpus, CSR Grant 2026, Building Fund
--         Campus       — WHICH unit?                  Main Campus, North Campus
--
--     A ₹50,000 lab purchase is cost centre 'Science', fund 'CSR Grant 2026', campus 'Main' — all three at
--     once. Collapsing them makes restricted-fund reporting impossible (BRD BR-FUND-06).
-- =========================================================================================================

-- Independent analysis axes. The same expense may be analysed by Wing AND by Department simultaneously;
-- each category's allocation must total the line amount independently (BRD BR-CC-04).
CREATE TABLE IF NOT EXISTS `acc_cost_categories` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              VARCHAR(20) NOT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `description`       VARCHAR(500) NULL,
    `is_mandatory`      TINYINT(1) NOT NULL DEFAULT 0,  -- allocation in this category is required
    `allow_multiple`    TINYINT(1) NOT NULL DEFAULT 1,  -- may a line split across centres in this category
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_cc_cat_code` (`code`,`del_marker`),
    UNIQUE KEY `uq_acc_cc_cat_name` (`name`,`del_marker`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `acc_cost_centers` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `cost_category_id`  SMALLINT UNSIGNED NOT NULL,
    `code`              VARCHAR(20) NOT NULL,
    `name`              VARCHAR(120) NOT NULL,
    `parent_id`         INT UNSIGNED NULL,
    `campus_id`         SMALLINT UNSIGNED NULL,
    `path`              VARCHAR(500) NULL,
    `depth`             TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `incharge_user_id`  INT UNSIGNED NULL,
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        INT UNSIGNED NULL,
    `updated_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_cc_code` (`code`,`del_marker`),
    UNIQUE KEY `uq_acc_cc_cat_name` (`cost_category_id`,`name`,`del_marker`),
    INDEX `idx_acc_cc_parent` (`parent_id`),
    INDEX `idx_acc_cc_category` (`cost_category_id`,`is_active`),
    INDEX `idx_acc_cc_campus` (`campus_id`),
    INDEX `idx_acc_cc_path` (`path`(191)),
    CONSTRAINT `chk_acc_cc_not_self` CHECK (`parent_id` IS NULL OR `parent_id` <> `id`),
    CONSTRAINT `fk_acc_cc_category` FOREIGN KEY (`cost_category_id`) REFERENCES `acc_cost_categories`(`id`) ON DELETE RESTRICT,
    -- v4.3 had `ON DELETE SET NUL` here — a syntax error that stopped the whole file parsing.
    CONSTRAINT `fk_acc_cc_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_cc_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_cc_incharge` FOREIGN KEY (`incharge_user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_cc_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_cc_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- A pool of money whose use is restricted by its donor, grantor or the trust deed.
-- A school trust must be able to show what it did with restricted money. Absent from v4.3 entirely.
CREATE TABLE IF NOT EXISTS `acc_funds` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(30) NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    -- Unrestricted : general purpose
    -- Restricted   : donor/grantor specified a purpose
    -- Corpus       : permanently restricted; never income of a period (BRD BR-FUND-05)
    -- Designated   : management earmarked; internally reversible
    `fund_type`             ENUM('Unrestricted','Restricted','Corpus','Designated') NOT NULL DEFAULT 'Unrestricted',
    `restriction_purpose`   VARCHAR(1000) NULL,
    `grantor_ledger_id`     INT UNSIGNED NULL,          -- the donor or grantor party
    `fund_ledger_id`        INT UNSIGNED NULL,          -- the balance-sheet ledger carrying the fund
    `sanctioned_amount`     DECIMAL(15,2) NULL,
    `utilisation_from`      DATE NULL,
    `utilisation_to`        DATE NULL,
    -- Overspend policy for a restricted fund (BRD BR-FUND-03).
    `overspend_action`      ENUM('Block','Approve','Warn') NOT NULL DEFAULT 'Block',
    `status`                ENUM('Active','Fully_Utilised','Suspended','Closed') NOT NULL DEFAULT 'Active',
    `campus_id`             SMALLINT UNSIGNED NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `notes`                 VARCHAR(1000) NULL,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fund_code` (`code`,`del_marker`),
    UNIQUE KEY `uq_acc_fund_name` (`name`,`del_marker`),
    INDEX `idx_acc_fund_type` (`fund_type`,`status`),
    INDEX `idx_acc_fund_ledger` (`fund_ledger_id`),
    INDEX `idx_acc_fund_grantor` (`grantor_ledger_id`),
    INDEX `idx_acc_fund_campus` (`campus_id`),
    CONSTRAINT `chk_acc_fund_dates` CHECK (`utilisation_to` IS NULL OR `utilisation_from` IS NULL OR `utilisation_to` >= `utilisation_from`),
    CONSTRAINT `fk_acc_fund_grantor` FOREIGN KEY (`grantor_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fund_ledger` FOREIGN KEY (`fund_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fund_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fund_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_fund_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Restricted and unrestricted funds. A fund says whose money it was; a cost centre says where it went.';


-- =========================================================================================================
-- SECTION 4: VOUCHER CONFIGURATION
-- =========================================================================================================

-- Groups voucher types by the business area that produces them. v4.3 declared foreign keys here on
-- debit_ledger_id and credit_ledger_id — columns that were never declared, so CREATE TABLE failed — and
-- referenced tco_app_modules, a table that does not exist.
--
-- The module registry is glb_app_modules, keyed VARCHAR(10), and it lives in the GLOBAL database. A
-- cross-database foreign key would break tenant portability, so module_key is a plain indexed column
-- whose integrity the application enforces.
CREATE TABLE IF NOT EXISTS `acc_voucher_category` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_key`        VARCHAR(10) NOT NULL,           -- glb_app_modules.key: 'ACC','FEE','LIB','TPT','HST','PAY'
    `code`              VARCHAR(40) NOT NULL,           -- 'ACCOUNTING','FEE_COLLECTION','LIBRARY_FINE'
    `name`              VARCHAR(120) NOT NULL,
    `event_detail`      VARCHAR(255) NULL,              -- what business event this category represents
    `module_table_name` VARCHAR(64) NULL,               -- source table, e.g. 'lib_fines', 'fee_transactions'
    `is_system`         TINYINT(1) NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vcat_code` (`code`,`del_marker`),
    INDEX `idx_acc_vcat_module` (`module_key`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- A voucher type's rules are DATA, so that adding one needs no code (Solution_Design_v1 §4.4).
-- The `last_number` counter that lived here in v4.3 is gone: it was a lost update waiting to happen.
-- Numbering is now allocated from acc_voucher_number_sequences under a row lock.
CREATE TABLE IF NOT EXISTS `acc_voucher_types` (
    `id`                        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                      VARCHAR(20) NOT NULL,   -- PAYMENT, RECEIPT, CONTRA, JOURNAL, SALES, ...
    `name`                      VARCHAR(80) NOT NULL,
    `school_label`              VARCHAR(80) NULL,       -- what the UI calls it: 'Fee Demand', 'Fee Collection'
    `voucher_category_id`       SMALLINT UNSIGNED NOT NULL,
    `base_type`                 ENUM('Payment','Receipt','Contra','Journal','Sales','Purchase',
                                     'Credit_Note','Debit_Note','Memorandum') NOT NULL,

    -- ── Numbering policy (BRD §15) ──────────────────────────────────────────────────────────────────────
    `prefix`                    VARCHAR(10) NULL,
    `suffix`                    VARCHAR(10) NULL,
    `number_width`              TINYINT UNSIGNED NOT NULL DEFAULT 4,     -- PAY-0042
    `numbering_method`          ENUM('Auto','Manual','Auto_Override') NOT NULL DEFAULT 'Auto',
    `restart_policy`            ENUM('Financial_Year','Never','Monthly') NOT NULL DEFAULT 'Financial_Year',

    -- ── Posting rules, enforced by PostingService (Solution_Design_v1 §4.4) ─────────────────────────────
    `requires_party`            TINYINT(1) NOT NULL DEFAULT 0,
    `creates_bill_reference`    TINYINT(1) NOT NULL DEFAULT 0,
    `requires_narration`        TINYINT(1) NOT NULL DEFAULT 0,
    `requires_evidence`         TINYINT(1) NOT NULL DEFAULT 0,
    `requires_bank_details`     TINYINT(1) NOT NULL DEFAULT 0,
    `allow_zero_value`          TINYINT(1) NOT NULL DEFAULT 0,
    `allow_post_dated`          TINYINT(1) NOT NULL DEFAULT 0,
    -- CSV of acc_ledgers.ledger_type values. Empty = unrestricted.
    -- e.g. Contra: allowed 'Cash,Bank'; Journal: forbidden 'Cash,Bank'.
    `allowed_ledger_types`      VARCHAR(200) NULL,
    `forbidden_ledger_types`    VARCHAR(200) NULL,
    `affects_books`             TINYINT(1) NOT NULL DEFAULT 1,  -- 0 for Memorandum: never posts (BR-PROV-01)

    -- ── UI defaults (ScreenDesign VE-S5) ────────────────────────────────────────────────────────────────
    `default_entry_mode`        ENUM('Single','Double') NOT NULL DEFAULT 'Double',
    `default_ledger_id`         INT UNSIGNED NULL,

    `is_system`                 TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `ordinal`                   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `created_by`                INT UNSIGNED NULL,
    `updated_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vt_code` (`code`,`del_marker`),
    UNIQUE KEY `uq_acc_vt_name` (`name`,`del_marker`),
    UNIQUE KEY `uq_acc_vt_prefix` (`prefix`,`del_marker`),
    INDEX `idx_acc_vt_category` (`voucher_category_id`),
    INDEX `idx_acc_vt_base` (`base_type`,`is_active`),
    CONSTRAINT `fk_acc_vt_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vt_default_ledger` FOREIGN KEY (`default_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_vt_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_vt_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Voucher numbering under concurrency (Solution_Design_v1 §4.6).
--
-- v4.3 incremented acc_voucher_types.last_number. Two users posting at the same instant both read n and
-- both write n+1: one voucher number is lost and the series is corrupt. BRD BR-VNO-04 forbids it.
--
-- Here the row is locked FOR UPDATE inside the posting transaction, held for microseconds at the very end.
-- The UNIQUE key on acc_vouchers(financial_year_id, voucher_type_id, voucher_number) is the backstop:
-- even if the application is wrong, the database refuses the duplicate.
CREATE TABLE IF NOT EXISTS `acc_voucher_number_sequences` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_type_id`   SMALLINT UNSIGNED NOT NULL,
    `financial_year_id` SMALLINT UNSIGNED NOT NULL,
    `period_id`         SMALLINT UNSIGNED NULL,         -- set only when restart_policy = 'Monthly'
    `next_number`       INT UNSIGNED NOT NULL DEFAULT 1,
    `last_issued_at`    DATETIME NULL,
    -- period_id is NULL unless restart_policy = 'Monthly', and MySQL treats NULLs as distinct — so the
    -- key below would have permitted TWO sequence rows for the same type and year, and two vouchers
    -- taking the same number. The marker is the same fix v4.4 applied to soft-delete keys.
    `period_marker`     SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`period_id`,0)) STORED,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vns` (`voucher_type_id`,`financial_year_id`,`period_marker`),
    CONSTRAINT `chk_acc_vns_next` CHECK (`next_number` >= 1),
    CONSTRAINT `fk_acc_vns_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vns_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vns_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- When does a voucher need approval, and from whom (BRD §28). Configuration, not code.
CREATE TABLE IF NOT EXISTS `acc_approval_policies` (
    `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(120) NOT NULL,
    `voucher_type_id`       SMALLINT UNSIGNED NULL,     -- NULL = every type
    `campus_id`             SMALLINT UNSIGNED NULL,
    `min_amount`            DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `max_amount`            DECIMAL(15,2) NULL,         -- NULL = no ceiling
    `ledger_group_id`       INT UNSIGNED NULL,          -- applies only to vouchers touching this group
    `approval_level`        TINYINT UNSIGNED NOT NULL DEFAULT 1,     -- multi-level: 1, then 2, then 3
    `approver_role_slug`    VARCHAR(60) NOT NULL,
    -- BRD BR-APPR-04: a user may not approve their own voucher.
    `forbid_self_approval`  TINYINT(1) NOT NULL DEFAULT 1,
    `allow_override`        TINYINT(1) NOT NULL DEFAULT 0,
    `escalate_after_hours`  SMALLINT UNSIGNED NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ap_type` (`voucher_type_id`,`is_active`),
    INDEX `idx_acc_ap_amount` (`min_amount`,`max_amount`),
    CONSTRAINT `chk_acc_ap_amount` CHECK (`max_amount` IS NULL OR `max_amount` >= `min_amount`),
    CONSTRAINT `fk_acc_ap_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ap_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ap_group` FOREIGN KEY (`ledger_group_id`) REFERENCES `acc_account_groups`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ap_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 5: TAX CONFIGURATION
--     Effective-dated. The rate USED is copied onto acc_voucher_item_taxes at posting, so a later rate
--     change can never rewrite a recorded transaction (BRD BR-TAX-01).
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_tax_types` (
    `id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`          VARCHAR(15) NOT NULL,               -- CGST, SGST, IGST, CESS, TDS, TCS
    `name`          VARCHAR(100) NOT NULL,
    `tax_family`    ENUM('GST','TDS','TCS','Other') NOT NULL DEFAULT 'GST',
    `is_input`      TINYINT(1) NOT NULL DEFAULT 0,      -- input credit vs output liability
    `ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    `del_marker`    BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tt_code` (`code`,`del_marker`),
    INDEX `idx_acc_tt_family` (`tax_family`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `acc_tax_rates` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tax_type_id`       SMALLINT UNSIGNED NOT NULL,
    `name`              VARCHAR(100) NOT NULL,          -- 'CGST 9%'
    `rate`              DECIMAL(9,4) NOT NULL,
    `hsn_sac_code`      VARCHAR(20) NULL,
    `is_interstate`     TINYINT(1) NOT NULL DEFAULT 0,
    `tax_ledger_id`     INT UNSIGNED NULL,              -- where this tax posts
    `effective_from`    DATE NOT NULL,
    `effective_to`      DATE NULL,                      -- NULL = still in force
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_tr_type_eff` (`tax_type_id`,`effective_from`,`effective_to`),
    INDEX `idx_acc_tr_hsn` (`hsn_sac_code`),
    INDEX `idx_acc_tr_ledger` (`tax_ledger_id`),
    CONSTRAINT `chk_acc_tr_rate` CHECK (`rate` >= 0),
    CONSTRAINT `chk_acc_tr_eff` CHECK (`effective_to` IS NULL OR `effective_to` >= `effective_from`),
    CONSTRAINT `fk_acc_tr_type` FOREIGN KEY (`tax_type_id`) REFERENCES `acc_tax_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tr_ledger` FOREIGN KEY (`tax_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tr_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- WHEN a tax applies: nature of payment, party type, threshold, section. Read by TaxEngine at posting.
CREATE TABLE IF NOT EXISTS `acc_tax_rules` (
    `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(30) NOT NULL,       -- 'TDS_194C_COMPANY'
    `name`                  VARCHAR(150) NOT NULL,
    `tax_type_id`           SMALLINT UNSIGNED NOT NULL,
    `tax_rate_id`           SMALLINT UNSIGNED NULL,
    `section_code`          VARCHAR(20) NULL,           -- '194C', '194J', '192'
    `nature_of_payment`     VARCHAR(150) NULL,
    `applies_to_party_type` ENUM('Any','Student','Parent','Vendor','Employee','Donor','Grantor','Other') NOT NULL DEFAULT 'Any',
    `applies_to_group_id`   INT UNSIGNED NULL,
    -- Thresholds. Single = per transaction; annual = cumulative for the payee for the year.
    `single_txn_threshold`  DECIMAL(15,2) NULL,
    `annual_threshold`      DECIMAL(15,2) NULL,
    `rate_without_pan`      DECIMAL(9,4) NULL,          -- higher rate where PAN is not furnished
    `deduct_on`             ENUM('Credit','Payment','Earlier_Of_Both') NOT NULL DEFAULT 'Earlier_Of_Both',
    `rounding`              ENUM('None','Nearest_Rupee','Up_Rupee','Down_Rupee') NOT NULL DEFAULT 'Nearest_Rupee',
    `priority`              SMALLINT UNSIGNED NOT NULL DEFAULT 100,  -- lower wins; most specific first
    `effective_from`        DATE NOT NULL,
    `effective_to`          DATE NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_txr_code` (`code`,`del_marker`),
    INDEX `idx_acc_txr_resolve` (`tax_type_id`,`is_active`,`priority`,`effective_from`),
    INDEX `idx_acc_txr_section` (`section_code`),
    CONSTRAINT `chk_acc_txr_eff` CHECK (`effective_to` IS NULL OR `effective_to` >= `effective_from`),
    CONSTRAINT `fk_acc_txr_type` FOREIGN KEY (`tax_type_id`) REFERENCES `acc_tax_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_txr_rate` FOREIGN KEY (`tax_rate_id`) REFERENCES `acc_tax_rates`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_txr_group` FOREIGN KEY (`applies_to_group_id`) REFERENCES `acc_account_groups`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_txr_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 6: TRANSACTIONS
--
--     acc_vouchers        header  — one accounting transaction
--       acc_voucher_items lines   — Dr/Cr postings. THIS TABLE IS THE LEDGER.
--                                   Every balance, statement, outstanding and tax figure in the entire
--                                   module derives from it, and is rebuildable from it.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_vouchers` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- ── Identity ────────────────────────────────────────────────────────────────────────────────────────
    `voucher_type_id`       SMALLINT UNSIGNED NOT NULL,
    `voucher_prefix`        VARCHAR(10) NULL,           -- snapshot at posting; the type may be reconfigured later
    `voucher_number`        INT UNSIGNED NULL,          -- NULL until POSTED (BRD BR-VNO-02)
    `voucher_display_no`    VARCHAR(40) NULL,           -- 'PAY-0042', materialised for search and print
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NULL,     -- resolved from voucher_date at posting
    `voucher_date`          DATE NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,

    -- ── Amounts. Base currency is the reporting currency; txn currency is what actually moved. ──────────
    `total_amount`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,   -- Σ Dr = Σ Cr, in base currency
    `currency_id`           SMALLINT UNSIGNED NULL,
    `exchange_rate`         DECIMAL(18,8) NOT NULL DEFAULT 1.00000000,
    `total_amount_txn_ccy`  DECIMAL(15,2) NULL,

    -- ── Status. ONE source of truth for the voucher's state. v4.3 carried is_cancelled as a separate
    --    flag beside status, which allowed the two to disagree about the same fact.
    --    Only 'Posted' affects the books (BRD R-02).
    `status`                ENUM('Draft','Pending_Approval','Rejected','Posted','Cancelled','Reversed')
                            NOT NULL DEFAULT 'Draft',

    -- ── Nature flags ────────────────────────────────────────────────────────────────────────────────────
    -- is_provisional: a memorandum voucher. Appears in NO financial statement, ever (BRD BR-PROV-01).
    -- v4.3's comment said the opposite; it was wrong and contradicted the BRD it was built from.
    `is_provisional`        TINYINT(1) NOT NULL DEFAULT 0,
    `is_post_dated`         TINYINT(1) NOT NULL DEFAULT 0,
    `effective_date`        DATE NULL,                  -- when a post-dated voucher becomes effective
    `is_opening`            TINYINT(1) NOT NULL DEFAULT 0,   -- opening-balance voucher
    `is_closing`            TINYINT(1) NOT NULL DEFAULT 0,   -- year-end closing journal
    `is_system_generated`   TINYINT(1) NOT NULL DEFAULT 0,
    `applicable_upto`       DATE NULL,                  -- reversing journal auto-reverses after this date

    -- ── Business context ────────────────────────────────────────────────────────────────────────────────
    `party_ledger_id`       INT UNSIGNED NULL,          -- the counterparty, where there is one
    `narration`             TEXT NULL,
    `reference_number`      VARCHAR(100) NULL,          -- external document number (vendor bill no., etc.)
    `reference_date`        DATE NULL,
    `due_date`              DATE NULL,                  -- on Sales/Purchase invoices

    -- ── Origin (BRD BR-INT-03) ──────────────────────────────────────────────────────────────────────────
    `source_module_key`     VARCHAR(10) NULL,           -- glb_app_modules.key
    `source_category_id`    SMALLINT UNSIGNED NULL,
    `source_model`          VARCHAR(100) NULL,          -- source table name
    `source_id`             BIGINT UNSIGNED NULL,
    `source_event_uid`      VARCHAR(100) NULL,          -- idempotency key from the source

    -- ── Lifecycle ───────────────────────────────────────────────────────────────────────────────────────
    `entered_by`            INT UNSIGNED NULL,
    `submitted_at`          DATETIME NULL,
    `submitted_by`          INT UNSIGNED NULL,
    `approved_at`           DATETIME NULL,
    `approved_by`           INT UNSIGNED NULL,
    `posted_at`             DATETIME NULL,
    `posted_by`             INT UNSIGNED NULL,
    `cancelled_at`          DATETIME NULL,
    `cancelled_by`          INT UNSIGNED NULL,
    `cancelled_reason`      VARCHAR(1000) NULL,
    `rejected_reason`       VARCHAR(1000) NULL,

    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    -- The numbering backstop. Even if NumberingService is wrong, the database refuses a duplicate.
    -- voucher_number is NULL on drafts, and MySQL treats NULLs as distinct, so drafts do not collide.
    UNIQUE KEY `uq_acc_v_number` (`financial_year_id`,`voucher_type_id`,`voucher_number`),
    -- Cross-module idempotency: one source event produces at most one voucher (BRD BR-INT-02).
    UNIQUE KEY `uq_acc_v_source_event` (`source_model`,`source_id`,`source_event_uid`),
    INDEX `idx_acc_v_date_status` (`voucher_date`,`status`),
    INDEX `idx_acc_v_fy_period` (`financial_year_id`,`period_id`,`status`),
    INDEX `idx_acc_v_type_date` (`voucher_type_id`,`voucher_date`),
    INDEX `idx_acc_v_status_date` (`status`,`voucher_date`),
    INDEX `idx_acc_v_party` (`party_ledger_id`,`voucher_date`),
    INDEX `idx_acc_v_source` (`source_module_key`,`source_model`,`source_id`),
    INDEX `idx_acc_v_campus` (`campus_id`,`voucher_date`),
    INDEX `idx_acc_v_display_no` (`voucher_display_no`),
    INDEX `idx_acc_v_reference` (`reference_number`),
    INDEX `idx_acc_v_due` (`due_date`),
    INDEX `idx_acc_v_postdated` (`is_post_dated`,`effective_date`),
    INDEX `idx_acc_v_provisional` (`is_provisional`,`status`),
    INDEX `idx_acc_v_entered_by` (`entered_by`,`created_at`),

    CONSTRAINT `chk_acc_v_total` CHECK (`total_amount` >= 0),
    CONSTRAINT `chk_acc_v_rate` CHECK (`exchange_rate` > 0),
    -- A posted voucher must carry a number; a draft must not (BRD BR-VNO-02).
    CONSTRAINT `chk_acc_v_number_posted` CHECK (
        (`status` IN ('Posted','Cancelled','Reversed') AND `voucher_number` IS NOT NULL)
     OR (`status` IN ('Draft','Pending_Approval','Rejected') AND `voucher_number` IS NULL)
    ),
    CONSTRAINT `chk_acc_v_cancel_reason` CHECK (`status` <> 'Cancelled' OR `cancelled_reason` IS NOT NULL),

    CONSTRAINT `fk_acc_v_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_v_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_v_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_v_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_v_currency` FOREIGN KEY (`currency_id`) REFERENCES `acc_currencies`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_v_party` FOREIGN KEY (`party_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_v_source_cat` FOREIGN KEY (`source_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_entered_by` FOREIGN KEY (`entered_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_submitted_by` FOREIGN KEY (`submitted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_v_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Voucher header. Only status=Posted affects the books.';


-- THE LEDGER. Every figure the module reports is derived from these rows.
-- Written only by PostingService, and never updated once its voucher is posted (BRD R-03).
CREATE TABLE IF NOT EXISTS `acc_voucher_items` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`            BIGINT UNSIGNED NOT NULL,
    `ledger_id`             INT UNSIGNED NOT NULL,
    `sequence_no`           SMALLINT UNSIGNED NOT NULL DEFAULT 1,   -- grid order; without it, order on reopen
                                                                    -- depends on id (ScreenDesign §16.2 #7)
    `entry_type`            ENUM('Dr','Cr') NOT NULL,
    `amount`                DECIMAL(15,2) NOT NULL,                 -- base currency; always positive
    `amount_txn_ccy`        DECIMAL(15,2) NULL,

    -- ── Denormalised from the header, for query performance. Maintained ONLY by PostingService, and never
    --    independently editable. These turn every ledger and statement query into a single-table scan.
    `voucher_date`          DATE NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `voucher_status`        ENUM('Draft','Pending_Approval','Rejected','Posted','Cancelled','Reversed')
                            NOT NULL DEFAULT 'Draft',

    `narration`             VARCHAR(500) NULL,
    -- Bank reconciliation state of this line (BRD BR-BRS-01).
    `is_reconciled`         TINYINT(1) NOT NULL DEFAULT 0,
    `reconciled_at`         DATETIME NULL,
    `bank_value_date`       DATE NULL,                  -- the bank's own date, set at reconciliation

    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vi_sequence` (`voucher_id`,`sequence_no`),
    -- The balance-aggregation path: ledger + status + date, covering amount and side.
    INDEX `idx_acc_vi_ledger_balance` (`ledger_id`,`voucher_status`,`voucher_date`,`entry_type`,`amount`),
    INDEX `idx_acc_vi_ledger_period` (`ledger_id`,`period_id`,`voucher_status`),
    INDEX `idx_acc_vi_voucher` (`voucher_id`),
    INDEX `idx_acc_vi_fy` (`financial_year_id`,`voucher_status`),
    INDEX `idx_acc_vi_recon` (`ledger_id`,`is_reconciled`,`voucher_date`),
    INDEX `idx_acc_vi_campus` (`campus_id`,`period_id`),
    CONSTRAINT `chk_acc_vi_amount` CHECK (`amount` >= 0),
    CONSTRAINT `fk_acc_vi_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vi_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vi_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vi_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vi_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='THE LEDGER. The only source of accounting truth. Written by PostingService alone.';


-- Cost-centre allocation. v4.3 put a single cost_center_id on the line (and then indexed a column it had
-- not declared). A line must be splittable across centres (ScreenDesign §12.2, BRD BR-CC-02).
CREATE TABLE IF NOT EXISTS `acc_voucher_item_cost_centers` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_item_id`   BIGINT UNSIGNED NOT NULL,
    `cost_center_id`    INT UNSIGNED NOT NULL,
    `cost_category_id`  SMALLINT UNSIGNED NOT NULL,     -- denormalised: allocation totals are checked per category
    `amount`            DECIMAL(15,2) NOT NULL,
    `percentage`        DECIMAL(9,4) NULL,
    `narration`         VARCHAR(500) NULL,
    `is_auto_allocated` TINYINT(1) NOT NULL DEFAULT 0,  -- filled by a predefined rule (BRD BR-CC-06)
    `overridden_by`     INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vicc` (`voucher_item_id`,`cost_center_id`),
    INDEX `idx_acc_vicc_cc` (`cost_center_id`),
    INDEX `idx_acc_vicc_category` (`cost_category_id`,`cost_center_id`),
    CONSTRAINT `chk_acc_vicc_amount` CHECK (`amount` >= 0),
    CONSTRAINT `fk_acc_vicc_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE CASCADE,
    -- RESTRICT, not SET NULL: once a cost centre has been used in a posted transaction it must not vanish.
    CONSTRAINT `fk_acc_vicc_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vicc_category` FOREIGN KEY (`cost_category_id`) REFERENCES `acc_cost_categories`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vicc_overridden_by` FOREIGN KEY (`overridden_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Fund allocation — the second, independent dimension. Answers "whose money was this?"
CREATE TABLE IF NOT EXISTS `acc_voucher_item_funds` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_item_id`   BIGINT UNSIGNED NOT NULL,
    `fund_id`           INT UNSIGNED NOT NULL,
    `amount`            DECIMAL(15,2) NOT NULL,
    `percentage`        DECIMAL(9,4) NULL,
    -- Addition   : money coming into the fund
    -- Utilisation: money spent from it
    -- Transfer   : movement between funds, always in balanced pairs
    `allocation_type`   ENUM('Addition','Utilisation','Transfer_In','Transfer_Out') NOT NULL DEFAULT 'Utilisation',
    `narration`         VARCHAR(500) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vif` (`voucher_item_id`,`fund_id`,`allocation_type`),
    INDEX `idx_acc_vif_fund` (`fund_id`,`allocation_type`),
    CONSTRAINT `chk_acc_vif_amount` CHECK (`amount` >= 0),
    CONSTRAINT `fk_acc_vif_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vif_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- The tax actually applied, with the rate and rule that produced it, frozen at posting.
-- This is what makes BRD BR-TAX-01 real: a later rate change cannot rewrite history, because history
-- does not read the rate table.
CREATE TABLE IF NOT EXISTS `acc_voucher_item_taxes` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_item_id`   BIGINT UNSIGNED NOT NULL,       -- the taxable line
    `tax_line_item_id`  BIGINT UNSIGNED NULL,           -- the voucher line where the tax itself posted
    `tax_type_id`       SMALLINT UNSIGNED NOT NULL,
    `tax_rate_id`       SMALLINT UNSIGNED NULL,
    `tax_rule_id`       SMALLINT UNSIGNED NULL,
    `taxable_amount`    DECIMAL(15,2) NOT NULL,
    `rate_applied`      DECIMAL(9,4) NOT NULL,          -- frozen. Never read back from acc_tax_rates.
    `tax_amount`        DECIMAL(15,2) NOT NULL,
    `is_reverse_charge` TINYINT(1) NOT NULL DEFAULT 0,
    `is_input_credit`   TINYINT(1) NOT NULL DEFAULT 0,
    `is_credit_eligible` TINYINT(1) NOT NULL DEFAULT 1, -- ineligible credit is expensed, not claimed
    `hsn_sac_code`      VARCHAR(20) NULL,
    `place_of_supply`   VARCHAR(5) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_vit_item` (`voucher_item_id`),
    INDEX `idx_acc_vit_type` (`tax_type_id`),
    INDEX `idx_acc_vit_rule` (`tax_rule_id`),
    INDEX `idx_acc_vit_tax_line` (`tax_line_item_id`),
    CONSTRAINT `chk_acc_vit_amounts` CHECK (`taxable_amount` >= 0 AND `tax_amount` >= 0 AND `rate_applied` >= 0),
    CONSTRAINT `fk_acc_vit_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vit_tax_line` FOREIGN KEY (`tax_line_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_vit_type` FOREIGN KEY (`tax_type_id`) REFERENCES `acc_tax_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vit_rate` FOREIGN KEY (`tax_rate_id`) REFERENCES `acc_tax_rates`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vit_rule` FOREIGN KEY (`tax_rule_id`) REFERENCES `acc_tax_rules`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Bank instrument detail. v4.3 squeezed this into reference_number/reference_date, which cannot support
-- cheque tracking, reconciliation matching or printing (ScreenDesign §12.4, §16.2 #3).
CREATE TABLE IF NOT EXISTS `acc_voucher_bank_details` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`            BIGINT UNSIGNED NOT NULL,
    `bank_ledger_id`        INT UNSIGNED NOT NULL,
    `transaction_type`      ENUM('Cheque','DD','NEFT','RTGS','IMPS','UPI','Card','Cash','ECS','Other') NOT NULL,
    `instrument_no`         VARCHAR(50) NULL,           -- mandatory for Cheque and DD
    `instrument_date`       DATE NULL,                  -- a future date auto-sets is_post_dated
    `bank_value_date`       DATE NULL,                  -- set at reconciliation, never at entry
    `favouring_name`        VARCHAR(200) NULL,
    `counterparty_bank`     VARCHAR(150) NULL,
    `counterparty_account`  VARCHAR(50) NULL,
    `counterparty_ifsc`     VARCHAR(20) NULL,
    `utr_number`            VARCHAR(50) NULL,           -- for NEFT/RTGS/IMPS
    `cheque_leaf_id`        BIGINT UNSIGNED NULL,
    `is_printed`            TINYINT(1) NOT NULL DEFAULT 0,
    `printed_at`            DATETIME NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_vbd_voucher` (`voucher_id`),
    INDEX `idx_acc_vbd_ledger` (`bank_ledger_id`,`instrument_date`),
    INDEX `idx_acc_vbd_instrument` (`instrument_no`),
    INDEX `idx_acc_vbd_utr` (`utr_number`),
    INDEX `idx_acc_vbd_leaf` (`cheque_leaf_id`),
    CONSTRAINT `fk_acc_vbd_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vbd_ledger` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Voucher-to-voucher links: which invoice a credit note adjusts, which voucher a reversal negates.
-- v4.3 encoded this as free text in bill_reference (ScreenDesign §16.2 #5).
CREATE TABLE IF NOT EXISTS `acc_voucher_references` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`        BIGINT UNSIGNED NOT NULL,       -- the adjusting / reversing voucher
    `against_voucher_id` BIGINT UNSIGNED NOT NULL,      -- the original
    `reference_type`    ENUM('Adjusts','Reverses','Corrects','Settles','Relates_To','Replaces') NOT NULL,
    `amount`            DECIMAL(15,2) NULL,
    `note`              VARCHAR(500) NULL,
    `created_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vref` (`voucher_id`,`against_voucher_id`,`reference_type`),
    INDEX `idx_acc_vref_against` (`against_voucher_id`),
    CONSTRAINT `chk_acc_vref_not_self` CHECK (`voucher_id` <> `against_voucher_id`),
    CONSTRAINT `fk_acc_vref_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vref_against` FOREIGN KEY (`against_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vref_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Approval history. Append-only: a re-submission adds a row, it never overwrites one (BRD BR-APPR-03).
CREATE TABLE IF NOT EXISTS `acc_voucher_approvals` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`        BIGINT UNSIGNED NOT NULL,
    `approval_level`    TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `policy_id`         SMALLINT UNSIGNED NULL,
    `action`            ENUM('Submitted','Approved','Rejected','Escalated','Overridden','Withdrawn') NOT NULL,
    `actioned_by`       INT UNSIGNED NULL,
    `actioned_at`       DATETIME NOT NULL,
    `is_self_approval`  TINYINT(1) NOT NULL DEFAULT 0,  -- flagged for the SoD report even when permitted
    `note`              VARCHAR(1000) NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_vap_voucher` (`voucher_id`,`approval_level`),
    INDEX `idx_acc_vap_by` (`actioned_by`,`actioned_at`),
    INDEX `idx_acc_vap_action` (`action`,`actioned_at`),
    INDEX `idx_acc_vap_self` (`is_self_approval`),
    CONSTRAINT `fk_acc_vap_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vap_policy` FOREIGN KEY (`policy_id`) REFERENCES `acc_approval_policies`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_vap_by` FOREIGN KEY (`actioned_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Supporting evidence (BRD §31).
CREATE TABLE IF NOT EXISTS `acc_voucher_attachments` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`        BIGINT UNSIGNED NOT NULL,
    `media_id`          INT UNSIGNED NOT NULL,
    `file_name`         VARCHAR(255) NULL,
    `document_type`     ENUM('Invoice','Bill','Receipt','Contract','Sanction','Bank_Advice','Challan','Other')
                        NOT NULL DEFAULT 'Other',
    `note`              VARCHAR(500) NULL,
    `uploaded_by`       INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_vatt_voucher` (`voucher_id`),
    INDEX `idx_acc_vatt_media` (`media_id`),
    CONSTRAINT `fk_acc_vatt_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_vatt_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_vatt_by` FOREIGN KEY (`uploaded_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 7: BILL-WISE ACCOUNTING
--
--     BRD §17 states nine rules of bill-wise behaviour. v4.3 offered acc_voucher_items.bill_reference
--     VARCHAR(100) — a text field. The ScreenDesign already documented the workaround: "allocating across
--     N bills writes N voucher_items rows", which corrupts the ledger line structure to carry allocation
--     data and still cannot express partial settlement over time.
--
--     Here a bill reference is an obligation, and an allocation is a settlement of it.
--         outstanding = original_amount − Σ allocations        (DERIVED, per BRD BR-BILL-06)
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_bill_references` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`             INT UNSIGNED NOT NULL,      -- the party who owes or is owed
    `reference_no`          VARCHAR(100) NOT NULL,      -- 'FEE/T2/00412', a vendor bill number
    `reference_date`        DATE NOT NULL,
    `due_date`              DATE NULL,
    `bill_type`             ENUM('Sales','Purchase','Advance','On_Account','Opening','Adjustment') NOT NULL,
    `original_amount`       DECIMAL(15,2) NOT NULL,
    `currency_id`           SMALLINT UNSIGNED NULL,
    `exchange_rate`         DECIMAL(18,8) NOT NULL DEFAULT 1.00000000,

    -- Origin: the voucher line that created this obligation.
    `source_voucher_id`     BIGINT UNSIGNED NULL,
    `source_voucher_item_id` BIGINT UNSIGNED NULL,

    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `fund_id`               INT UNSIGNED NULL,
    `cost_center_id`        INT UNSIGNED NULL,

    `status`                ENUM('Open','Partially_Settled','Settled','Written_Off','Disputed','Cancelled')
                            NOT NULL DEFAULT 'Open',
    `is_disputed`           TINYINT(1) NOT NULL DEFAULT 0,
    `dispute_note`          VARCHAR(500) NULL,
    `written_off_amount`    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `written_off_voucher_id` BIGINT UNSIGNED NULL,

    `narration`             VARCHAR(500) NULL,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    -- One reference number per party per year. This is also what stops a vendor bill being entered twice
    -- (BRD BR-DUP-04).
    UNIQUE KEY `uq_acc_billref` (`ledger_id`,`reference_no`,`financial_year_id`,`del_marker`),
    -- The ageing path: open bills for a party, oldest due first.
    INDEX `idx_acc_billref_ageing` (`ledger_id`,`status`,`due_date`),
    INDEX `idx_acc_billref_due` (`due_date`,`status`),
    INDEX `idx_acc_billref_type` (`bill_type`,`status`),
    INDEX `idx_acc_billref_source` (`source_voucher_id`),
    INDEX `idx_acc_billref_fy` (`financial_year_id`,`status`),
    INDEX `idx_acc_billref_fund` (`fund_id`),
    INDEX `idx_acc_billref_no` (`reference_no`),

    CONSTRAINT `chk_acc_billref_amount` CHECK (`original_amount` >= 0),
    CONSTRAINT `chk_acc_billref_wo` CHECK (`written_off_amount` >= 0 AND `written_off_amount` <= `original_amount`),
    CONSTRAINT `fk_acc_billref_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_voucher` FOREIGN KEY (`source_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_item` FOREIGN KEY (`source_voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_wo_voucher` FOREIGN KEY (`written_off_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_currency` FOREIGN KEY (`currency_id`) REFERENCES `acc_currencies`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billref_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_billref_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='A tracked obligation within a party ledger. Outstanding is derived from acc_bill_allocations.';


-- One settlement of one obligation. Many-to-many: one payment settles many bills, one bill is settled by
-- many payments (BRD BR-BILL-05).
CREATE TABLE IF NOT EXISTS `acc_bill_allocations` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bill_reference_id`     BIGINT UNSIGNED NOT NULL,
    `voucher_item_id`       BIGINT UNSIGNED NOT NULL,
    `voucher_id`            BIGINT UNSIGNED NOT NULL,   -- denormalised: cancellation releases by voucher
    `allocation_type`       ENUM('Against_Reference','New_Reference','Advance','On_Account','Write_Off','Adjustment')
                            NOT NULL DEFAULT 'Against_Reference',
    `amount`                DECIMAL(15,2) NOT NULL,
    `allocation_date`       DATE NOT NULL,
    `note`                  VARCHAR(500) NULL,
    `allocated_by`          INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_billalloc` (`bill_reference_id`,`voucher_item_id`),
    INDEX `idx_acc_billalloc_item` (`voucher_item_id`),
    INDEX `idx_acc_billalloc_voucher` (`voucher_id`),
    INDEX `idx_acc_billalloc_date` (`allocation_date`),
    INDEX `idx_acc_billalloc_ref_amt` (`bill_reference_id`,`amount`),
    CONSTRAINT `chk_acc_billalloc_amount` CHECK (`amount` > 0),
    CONSTRAINT `fk_acc_billalloc_ref` FOREIGN KEY (`bill_reference_id`) REFERENCES `acc_bill_references`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_billalloc_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_billalloc_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_billalloc_by` FOREIGN KEY (`allocated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 8: BALANCES, CLOSING SNAPSHOTS AND PERIOD CLOSE
--
--     Rule R-05: balances are DERIVED from acc_voucher_items, never independently asserted. But a Trial
--     Balance cannot scan six million lines on every run, so the derivation is CACHED — and a cache is
--     only honest if it has three things, all of which the v4.3 closing_balance lacked:
--
--         an owner        PostingService, and nothing else, writes these tables
--         a rebuild       php artisan acc:rebuild-balances  recomputes them from acc_voucher_items alone
--         an assertion    a nightly job rebuilds into a scratch table and asserts the result is identical
--
--     That third one is the whole point (Solution_Design_v1 §5.4). A cache nobody checks is just a number
--     that used to be right.
--
--     Sizing: one row per ledger per period. 2,000 ledgers x 12 periods x 10 years = 240,000 rows, against
--     the 1.5M-6M voucher lines they summarise (Solution_Design_v1 §14.1).
-- =========================================================================================================

-- The balance cache. Every Trial Balance, Balance Sheet and Income & Expenditure figure is an aggregate
-- of these rows; no statement scans acc_voucher_items.
--
-- DIMENSION SLICES. The row where cost_center_id, fund_id and campus_id are ALL NULL is the ledger's
-- total for the period — that is the row statements read. Rows with a dimension set are additional,
-- narrower slices for cost-centre and fund reporting. They are NOT summed with the total row; doing so
-- would double count. Phase 1 maintains only the total rows (Solution_Design_v1 OD-04).
CREATE TABLE IF NOT EXISTS `acc_ledger_period_balances` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`             INT UNSIGNED NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NOT NULL,

    -- NULL on all three = the ledger total for the period. See the note above.
    `cost_center_id`        INT UNSIGNED NULL,
    `fund_id`               INT UNSIGNED NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,

    -- Opening = the prior period's closing. For period 1 it is the year's opening balance.
    `opening_debit`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `opening_credit`        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    -- Movement within the period. Σ of posted acc_voucher_items for this ledger and period.
    `period_debit`          DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `period_credit`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    -- Closing = opening + period. Stored so a statement is a scan, not an arithmetic pass.
    `closing_debit`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `closing_credit`        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `transaction_count`     INT UNSIGNED NOT NULL DEFAULT 0,

    -- ── Cache provenance. Present on every cache table in this schema. ──────────────────────────────────
    `last_voucher_item_id`  BIGINT UNSIGNED NULL,       -- the newest line folded in; makes drift diagnosable
    `last_rebuilt_at`       DATETIME NULL,
    `is_stale`              TINYINT(1) NOT NULL DEFAULT 0,  -- set by a failed assertion; cleared by rebuild

    -- NULL-SAFE UNIQUENESS. MySQL treats NULLs as DISTINCT in a unique key, so a key spanning a
    -- nullable column enforces nothing on the rows where that column is NULL — the same defect as
    -- v4.3's UNIQUE(code, deleted_at). These generated columns collapse NULL to 0 so the key means
    -- what it says.
    `cc_marker`             INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`cost_center_id`,0)) STORED,
    `fund_marker`           INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`fund_id`,0))         STORED,
    `campus_marker`         SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0))       STORED,

    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    -- One bucket per ledger, per period, per dimension slice. The uniqueness is what makes the
    -- incremental UPDATE in PostingService safe: it can never create a second bucket for the same key.
    UNIQUE KEY `uq_acc_lpb` (`ledger_id`,`period_id`,`cc_marker`,`fund_marker`,`campus_marker`),
    -- The Trial Balance path: one indexed scan of a period's rows.
    INDEX `idx_acc_lpb_period` (`period_id`,`ledger_id`),
    INDEX `idx_acc_lpb_fy` (`financial_year_id`,`period_id`),
    INDEX `idx_acc_lpb_ledger_fy` (`ledger_id`,`financial_year_id`,`period_id`),
    INDEX `idx_acc_lpb_cc` (`cost_center_id`,`period_id`),
    INDEX `idx_acc_lpb_fund` (`fund_id`,`period_id`),
    INDEX `idx_acc_lpb_campus` (`campus_id`,`period_id`),
    INDEX `idx_acc_lpb_stale` (`is_stale`),

    CONSTRAINT `chk_acc_lpb_signs` CHECK (
        `opening_debit` >= 0 AND `opening_credit` >= 0 AND
        `period_debit`  >= 0 AND `period_credit`  >= 0 AND
        `closing_debit` >= 0 AND `closing_credit` >= 0
    ),
    CONSTRAINT `fk_acc_lpb_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_lpb_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_lpb_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_lpb_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_lpb_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_lpb_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='DERIVED balance cache. Owner: PostingService. Rebuild: acc:rebuild-balances. Asserted nightly.';


-- The frozen figures of a closed period. Written once, at close, and never updated.
--
-- This is what makes BRD AC-CLOSE-03 achievable — "a closed period's Trial Balance is byte-identical
-- whenever it is re-run". A closed period is not served from the cache above, because the cache is a
-- live object and a live object can change. It is served from here, where nothing can.
CREATE TABLE IF NOT EXISTS `acc_period_closing_balances` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `period_id`             SMALLINT UNSIGNED NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `ledger_id`             INT UNSIGNED NOT NULL,
    -- Denormalised classification, frozen as it stood at close. If a ledger is later regrouped, the
    -- closed period's statements must not silently reclassify themselves.
    `account_group_id`      INT UNSIGNED NOT NULL,
    `group_nature`          ENUM('Asset','Liability','Equity','Income','Expense') NOT NULL,
    `opening_debit`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `opening_credit`        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `period_debit`          DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `period_credit`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `closing_debit`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `closing_credit`        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `transaction_count`     INT UNSIGNED NOT NULL DEFAULT 0,
    -- The high-water mark of the ledger at the instant of close. If a voucher is later force-posted into
    -- the period under acc.period.adjust, the snapshot and the live cache diverge — and this column is
    -- what lets the exception report say so, by name (BRD BR-EXC-02).
    `max_voucher_item_id`   BIGINT UNSIGNED NULL,
    `snapshot_version`      SMALLINT UNSIGNED NOT NULL DEFAULT 1,   -- incremented on an authorised re-close
    `frozen_at`             DATETIME NOT NULL,
    `frozen_by`             INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_pcb` (`period_id`,`ledger_id`,`snapshot_version`),
    INDEX `idx_acc_pcb_period` (`period_id`,`group_nature`),
    INDEX `idx_acc_pcb_ledger` (`ledger_id`,`financial_year_id`),
    INDEX `idx_acc_pcb_fy` (`financial_year_id`,`period_id`),
    CONSTRAINT `fk_acc_pcb_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_pcb_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_pcb_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_pcb_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_pcb_by` FOREIGN KEY (`frozen_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Immutable close snapshot. Serves closed-period statements so they are reproducible by construction.';


-- Opening balances: the books as they stood before the first voucher of the year.
--
-- Two sources, and the difference matters (BRD BR-OPEN-01, BR-CLOSE-07):
--     Migration   — keyed in at go-live from the previous system. source_closing_balance_id is NULL.
--     Carry_Forward — generated by year-end close. source_closing_balance_id names the exact closing row
--                   it came from, which is what makes carry-forward traceable rather than merely correct.
--
-- Party opening balances are entered bill-wise: this row carries the control total, and the bills are
-- rows in acc_bill_references with bill_type = 'Opening', so day-one ageing is right (BR-OPEN-03).
CREATE TABLE IF NOT EXISTS `acc_opening_balances` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`                 INT UNSIGNED NOT NULL,
    `financial_year_id`         SMALLINT UNSIGNED NOT NULL,
    `campus_id`                 SMALLINT UNSIGNED NULL,
    `fund_id`                   INT UNSIGNED NULL,
    `entry_type`                ENUM('Dr','Cr') NOT NULL,
    `amount`                    DECIMAL(18,2) NOT NULL,
    `currency_id`               SMALLINT UNSIGNED NULL,
    `exchange_rate`             DECIMAL(18,8) NOT NULL DEFAULT 1.00000000,
    `amount_txn_ccy`            DECIMAL(18,2) NULL,

    `source`                    ENUM('Migration','Carry_Forward','Correction') NOT NULL DEFAULT 'Migration',
    `source_closing_balance_id` BIGINT UNSIGNED NULL,   -- the acc_period_closing_balances row this came from
    -- The opening voucher. Opening balances are posted as a real, balanced voucher marked is_opening,
    -- so that they appear in the ledger like everything else rather than as a special case nothing audits.
    `voucher_id`                BIGINT UNSIGNED NULL,

    -- Draft while the set is being keyed; Finalised once Σ Dr = Σ Cr for the year (BR-OPEN-02).
    -- An unbalanced set may be saved. It may not be finalised.
    `status`                    ENUM('Draft','Finalised','Superseded') NOT NULL DEFAULT 'Draft',
    `finalised_at`              DATETIME NULL,
    `finalised_by`              INT UNSIGNED NULL,
    -- BR-OPEN-04: after finalisation, change is by authorised correction, which supersedes rather than edits.
    `superseded_by_id`          BIGINT UNSIGNED NULL,
    `correction_reason`         VARCHAR(500) NULL,

    `notes`                     VARCHAR(500) NULL,
    `created_by`                INT UNSIGNED NULL,
    `updated_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    `campus_marker`             SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0)) STORED,
    `fund_marker`               INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`fund_id`,0))   STORED,

    PRIMARY KEY (`id`),
    -- One LIVE opening balance per ledger per year per dimension. A superseded row keeps its history,
    -- because it is soft-deleted rather than replaced in place. The markers make the key NULL-safe.
    UNIQUE KEY `uq_acc_ob` (`ledger_id`,`financial_year_id`,`campus_marker`,`fund_marker`,`del_marker`),
    INDEX `idx_acc_ob_fy_status` (`financial_year_id`,`status`),
    INDEX `idx_acc_ob_ledger` (`ledger_id`,`financial_year_id`),
    INDEX `idx_acc_ob_source` (`source`,`financial_year_id`),
    INDEX `idx_acc_ob_voucher` (`voucher_id`),
    INDEX `idx_acc_ob_from` (`source_closing_balance_id`),
    CONSTRAINT `chk_acc_ob_amount` CHECK (`amount` >= 0),
    CONSTRAINT `chk_acc_ob_rate` CHECK (`exchange_rate` > 0),
    CONSTRAINT `chk_acc_ob_correction` CHECK (`source` <> 'Correction' OR `correction_reason` IS NOT NULL),
    CONSTRAINT `fk_acc_ob_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ob_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ob_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ob_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ob_currency` FOREIGN KEY (`currency_id`) REFERENCES `acc_currencies`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ob_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ob_from` FOREIGN KEY (`source_closing_balance_id`) REFERENCES `acc_period_closing_balances`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ob_superseded` FOREIGN KEY (`superseded_by_id`) REFERENCES `acc_opening_balances`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ob_finalised_by` FOREIGN KEY (`finalised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ob_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ob_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Year opening balances. Carry-forward rows name the closing balance they came from (BR-CLOSE-07).';


-- Fund utilisation cache. BRD BR-FUND-04 requires, for any fund and any period:
--       opening + additions - utilisation = closing
-- and AC-FUND-01 requires that identity to hold. Storing all four is only safe because the same
-- owner/rebuild/assert discipline applies: this table is rebuilt from acc_voucher_item_funds alone.
CREATE TABLE IF NOT EXISTS `acc_fund_balances` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fund_id`               INT UNSIGNED NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `opening_balance`       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `additions`             DECIMAL(18,2) NOT NULL DEFAULT 0.00,    -- receipts into the fund
    `utilisation`           DECIMAL(18,2) NOT NULL DEFAULT 0.00,    -- spend from the fund
    `transfers_in`          DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `transfers_out`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `closing_balance`       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    -- Sanctioned less closing, for the overspend guard at posting (BR-FUND-03, V-15).
    `available_balance`     DECIMAL(18,2) NULL,
    `last_voucher_item_id`  BIGINT UNSIGNED NULL,
    `last_rebuilt_at`       DATETIME NULL,
    `is_stale`              TINYINT(1) NOT NULL DEFAULT 0,
    `campus_marker`         SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0)) STORED,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fb` (`fund_id`,`period_id`,`campus_marker`),
    INDEX `idx_acc_fb_fy` (`financial_year_id`,`period_id`),
    INDEX `idx_acc_fb_fund` (`fund_id`,`financial_year_id`),
    INDEX `idx_acc_fb_stale` (`is_stale`),
    CONSTRAINT `fk_acc_fb_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_fb_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_fb_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_fb_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Fund utilisation cache. Asserted: opening + additions - utilisation = closing (AC-FUND-01).';


-- Bill outstanding cache (Solution_Design_v1 §6.2).
--
-- outstanding = original_amount - Σ acc_bill_allocations, and that subtraction is cheap for one bill and
-- expensive for an ageing report over 40,000 open student demands. This table is that subtraction, kept
-- current by the same owner and rebuilt by the same command.
--
-- It is a CACHE. acc_bill_references and acc_bill_allocations remain the truth. If the two disagree, the
-- assertion in Solution_Design_v1 §5.5 fires and names the bill.
CREATE TABLE IF NOT EXISTS `acc_bill_reference_balances` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bill_reference_id`     BIGINT UNSIGNED NOT NULL,
    `ledger_id`             INT UNSIGNED NOT NULL,      -- denormalised: party ageing never joins
    `original_amount`       DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `allocated_amount`      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `written_off_amount`    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `outstanding_amount`    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `due_date`              DATE NULL,
    `days_overdue`          INT NOT NULL DEFAULT 0,     -- recomputed nightly; negative = not yet due
    `age_bucket`            VARCHAR(20) NULL,           -- '0-30', '31-60', ... buckets are configurable
    `last_allocation_id`    BIGINT UNSIGNED NULL,
    `last_rebuilt_at`       DATETIME NULL,
    `is_stale`              TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_brb` (`bill_reference_id`),
    -- The ageing report path: a party's open bills, oldest first, without touching the allocation table.
    INDEX `idx_acc_brb_ageing` (`ledger_id`,`outstanding_amount`,`due_date`),
    INDEX `idx_acc_brb_bucket` (`age_bucket`,`ledger_id`),
    INDEX `idx_acc_brb_overdue` (`days_overdue`),
    INDEX `idx_acc_brb_stale` (`is_stale`),
    CONSTRAINT `chk_acc_brb_outstanding` CHECK (`outstanding_amount` >= 0),
    CONSTRAINT `fk_acc_brb_ref` FOREIGN KEY (`bill_reference_id`) REFERENCES `acc_bill_references`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_brb_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bill outstanding cache. Truth is acc_bill_references less acc_bill_allocations.';


-- The close checklist as data, not a wiki page (BRD BR-CLOSE-01, Enhancement E-03).
--
-- One row per item per period. `is_blocking` is the column that turns a checklist into a control:
-- ClosingService refuses to close while any blocking item is not Passed or Waived, and names the ones
-- that failed (AC-CLOSE-01).
CREATE TABLE IF NOT EXISTS `acc_period_close_checklist` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `period_id`         SMALLINT UNSIGNED NOT NULL,
    `financial_year_id` SMALLINT UNSIGNED NOT NULL,
    `item_code`         VARCHAR(50) NOT NULL,       -- 'ALL_POSTED', 'BANK_RECONCILED', 'SUSPENSE_ZERO'
    `item_name`         VARCHAR(200) NOT NULL,
    `item_group`        ENUM('Transactions','Reconciliation','Compliance','Review') NOT NULL DEFAULT 'Transactions',
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    -- Blocking items stop the close. Non-blocking items warn and are recorded as warned.
    `is_blocking`       TINYINT(1) NOT NULL DEFAULT 1,
    -- Automatic items are evaluated by a named check in ClosingService; Manual items are ticked by a person.
    `check_type`        ENUM('Automatic','Manual') NOT NULL DEFAULT 'Automatic',
    `checker_key`       VARCHAR(100) NULL,          -- the service check this item runs
    `status`            ENUM('Pending','Passed','Failed','Waived','Not_Applicable') NOT NULL DEFAULT 'Pending',
    `owner_user_id`     INT UNSIGNED NULL,
    -- What the check actually found, so a Failed item explains itself instead of merely failing.
    `result_value`      DECIMAL(18,2) NULL,
    `result_count`      INT UNSIGNED NULL,
    `result_detail`     TEXT NULL,                  -- JSON: the offending record ids (BR-EXC-02)
    `evidence_media_id` INT UNSIGNED NULL,
    -- A waiver is an authorised decision to close anyway. It is recorded with who and why, always.
    `waived_by`         INT UNSIGNED NULL,
    `waived_at`         DATETIME NULL,
    `waive_reason`      VARCHAR(1000) NULL,
    `checked_at`        DATETIME NULL,
    `checked_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_pcc` (`period_id`,`item_code`),
    INDEX `idx_acc_pcc_period_status` (`period_id`,`status`,`is_blocking`),
    INDEX `idx_acc_pcc_owner` (`owner_user_id`,`status`),
    INDEX `idx_acc_pcc_fy` (`financial_year_id`,`period_id`),
    CONSTRAINT `chk_acc_pcc_waiver` CHECK (`status` <> 'Waived' OR (`waived_by` IS NOT NULL AND `waive_reason` IS NOT NULL)),
    CONSTRAINT `fk_acc_pcc_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_pcc_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_pcc_owner` FOREIGN KEY (`owner_user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_pcc_media` FOREIGN KEY (`evidence_media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_pcc_waived_by` FOREIGN KEY (`waived_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_pcc_checked_by` FOREIGN KEY (`checked_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Period close checklist. A blocking item that is not Passed or Waived refuses the close.';


-- =========================================================================================================
-- SECTION 9: BANKING — CHEQUES AND RECONCILIATION
--
--     v4.3 had three tables here and no cheque lifecycle at all, which left BRD §20 (six rules)
--     unimplementable. It also matched a statement row to a voucher line with one nullable column,
--     acc_bank_statement_entries.matched_voucher_item_id. That column cannot express any of:
--
--         a PROPOSED match with a confidence, awaiting a person   (BR-BRS-03)
--         a match a person REJECTED, and why
--         a confirmed match later UNDONE, with the undo recorded  (BR-BRS-05)
--         one statement row explained by two voucher lines
--
--     So the match became a row of its own. The statement entry keeps only a maintained match_status,
--     for the "show me what is still unmatched" query.
--
--     The import staging rule (BR-BRS-02): rows in acc_bank_statement_entries affect NO balance. They are
--     what the bank says. Only a CONFIRMED match sets acc_voucher_items.is_reconciled.
-- =========================================================================================================

-- Cheque-book stock, so a missing leaf is detectable (BRD BR-CHEQUE-05).
CREATE TABLE IF NOT EXISTS `acc_cheque_registers` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bank_ledger_id`    INT UNSIGNED NOT NULL,
    `book_number`       VARCHAR(50) NOT NULL,
    `leaf_prefix`       VARCHAR(10) NULL,
    `start_leaf_no`     BIGINT UNSIGNED NOT NULL,
    `end_leaf_no`       BIGINT UNSIGNED NOT NULL,
    `total_leaves`      SMALLINT UNSIGNED NOT NULL,
    `received_date`     DATE NULL,
    `status`            ENUM('Active','Exhausted','Cancelled','Lost') NOT NULL DEFAULT 'Active',
    `notes`             VARCHAR(500) NULL,
    `created_by`        INT UNSIGNED NULL,
    `updated_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_chqreg` (`bank_ledger_id`,`book_number`,`del_marker`),
    INDEX `idx_acc_chqreg_status` (`bank_ledger_id`,`status`),
    CONSTRAINT `chk_acc_chqreg_range` CHECK (`end_leaf_no` >= `start_leaf_no`),
    CONSTRAINT `fk_acc_chqreg_ledger` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_chqreg_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_chqreg_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One row per physical leaf. Its state is what makes "which cheques are unaccounted for?" a query.
CREATE TABLE IF NOT EXISTS `acc_cheque_leaves` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `cheque_register_id`    BIGINT UNSIGNED NOT NULL,
    `bank_ledger_id`        INT UNSIGNED NOT NULL,      -- denormalised: leaf lookup never joins the register
    `leaf_no`               BIGINT UNSIGNED NOT NULL,
    `status`                ENUM('Unused','Issued','Cancelled','Spoiled','Lost') NOT NULL DEFAULT 'Unused',
    `voucher_id`            BIGINT UNSIGNED NULL,       -- set when the leaf is used
    `issued_date`           DATE NULL,
    `cancelled_reason`      VARCHAR(500) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- One leaf number per bank account. This is the duplicate-cheque guard.
    UNIQUE KEY `uq_acc_chqleaf` (`bank_ledger_id`,`leaf_no`),
    INDEX `idx_acc_chqleaf_register` (`cheque_register_id`,`status`),
    INDEX `idx_acc_chqleaf_voucher` (`voucher_id`),
    INDEX `idx_acc_chqleaf_status` (`status`,`bank_ledger_id`),
    CONSTRAINT `fk_acc_chqleaf_register` FOREIGN KEY (`cheque_register_id`) REFERENCES `acc_cheque_registers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_chqleaf_ledger` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_chqleaf_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Cheque leaf stock. acc_voucher_bank_details.cheque_leaf_id points here (application-enforced).';


-- The cheque lifecycle (BRD BR-CHEQUE-01): Issued -> Presented -> Cleared, with Bounced, Stopped,
-- Cancelled and Stale as terminal or exceptional states.
--
-- APPEND-ONLY. A status change inserts a row; it never updates one. The current state of a cheque is its
-- newest row. This is deliberate: a bounced-then-represented-then-cleared cheque has a history that a
-- single mutable status column throws away, and BR-CHEQUE-06 requires the history to survive.
--
-- A bounce (BR-CHEQUE-04) records three things, which is why three voucher columns exist here:
--     reversal_voucher_id      the settlement being undone — which restores the bill outstanding
--     charge_voucher_id        the bank's charge, as its own expense, never netted into the reversal
--     replacement_voucher_id   the fresh instrument, where one is issued
CREATE TABLE IF NOT EXISTS `acc_cheque_transactions` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`                BIGINT UNSIGNED NOT NULL,
    `voucher_bank_detail_id`    BIGINT UNSIGNED NULL,
    `bank_ledger_id`            INT UNSIGNED NOT NULL,
    `party_ledger_id`           INT UNSIGNED NULL,
    -- BR-CHEQUE-02: issued and received cheques are separately reportable.
    `direction`                 ENUM('Issued','Received') NOT NULL,
    `cheque_leaf_id`            BIGINT UNSIGNED NULL,   -- only for Issued
    `instrument_no`             VARCHAR(50) NOT NULL,
    `instrument_date`           DATE NOT NULL,
    `amount`                    DECIMAL(15,2) NOT NULL,
    `favouring_name`            VARCHAR(200) NULL,
    `counterparty_bank`         VARCHAR(150) NULL,

    `status`                    ENUM('Issued','Presented','Cleared','Bounced','Stopped','Cancelled','Stale')
                                NOT NULL DEFAULT 'Issued',
    `status_date`               DATE NOT NULL,
    `status_note`               VARCHAR(500) NULL,
    -- BR-CHEQUE-03: a post-dated cheque affects no bank balance until its date.
    `is_post_dated`             TINYINT(1) NOT NULL DEFAULT 0,
    -- Three months from instrument_date by default. AC-CHEQUE-02 reports on this.
    `stale_on`                  DATE NULL,

    `bounce_reason`             VARCHAR(255) NULL,
    `bounce_charge_amount`      DECIMAL(15,2) NULL,
    `reversal_voucher_id`       BIGINT UNSIGNED NULL,
    `charge_voucher_id`         BIGINT UNSIGNED NULL,
    `replacement_voucher_id`    BIGINT UNSIGNED NULL,

    `actioned_by`               INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    -- One row per state per cheque per voucher. Re-recording the same state is a no-op, not a duplicate.
    UNIQUE KEY `uq_acc_chqtxn_state` (`voucher_id`,`instrument_no`,`status`,`status_date`),
    INDEX `idx_acc_chqtxn_current` (`bank_ledger_id`,`status`,`instrument_date`),
    INDEX `idx_acc_chqtxn_instrument` (`instrument_no`,`instrument_date`),
    INDEX `idx_acc_chqtxn_voucher` (`voucher_id`),
    INDEX `idx_acc_chqtxn_party` (`party_ledger_id`,`status`),
    INDEX `idx_acc_chqtxn_stale` (`stale_on`,`status`),
    INDEX `idx_acc_chqtxn_leaf` (`cheque_leaf_id`),
    INDEX `idx_acc_chqtxn_direction` (`direction`,`status`),
    CONSTRAINT `chk_acc_chqtxn_amount` CHECK (`amount` > 0),
    CONSTRAINT `chk_acc_chqtxn_bounce` CHECK (`status` <> 'Bounced' OR `bounce_reason` IS NOT NULL),
    CONSTRAINT `fk_acc_chqtxn_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_chqtxn_bankdetail` FOREIGN KEY (`voucher_bank_detail_id`) REFERENCES `acc_voucher_bank_details`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_chqtxn_bank` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_chqtxn_party` FOREIGN KEY (`party_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_chqtxn_leaf` FOREIGN KEY (`cheque_leaf_id`) REFERENCES `acc_cheque_leaves`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_chqtxn_reversal` FOREIGN KEY (`reversal_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_chqtxn_charge` FOREIGN KEY (`charge_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_chqtxn_replacement` FOREIGN KEY (`replacement_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_chqtxn_by` FOREIGN KEY (`actioned_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Append-only cheque status history. The current state is the newest row (BR-CHEQUE-06).';


-- One reconciliation of one bank account to one statement.
--
-- BR-BRS-06 requires the statement to show, at all times: balance per books, add/less unpresented and
-- uncredited items, balance per bank — and the last must equal the bank's own figure. Those five numbers
-- are columns here so the reconciliation can be reopened months later and still show what was reconciled
-- to what.
CREATE TABLE IF NOT EXISTS `acc_bank_reconciliations` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bank_ledger_id`            INT UNSIGNED NOT NULL,
    `financial_year_id`         SMALLINT UNSIGNED NOT NULL,
    `period_id`                 SMALLINT UNSIGNED NULL,
    `statement_from_date`       DATE NULL,
    `statement_date`            DATE NOT NULL,          -- the statement's closing date

    -- ── The reconciliation statement itself (BR-BRS-06) ─────────────────────────────────────────────────
    `balance_as_per_books`      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `unpresented_amount`        DECIMAL(18,2) NOT NULL DEFAULT 0.00,  -- issued, not yet debited by the bank
    `uncredited_amount`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,  -- deposited, not yet credited
    `other_adjustments`         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `balance_as_per_bank`       DECIMAL(18,2) NOT NULL DEFAULT 0.00,  -- computed
    `statement_closing_balance` DECIMAL(18,2) NOT NULL,               -- what the bank actually says
    -- Must be zero to complete. A non-zero difference is itemised, never absorbed (BR-BRS-04, AC-BRS-01).
    `difference`                DECIMAL(18,2) NOT NULL DEFAULT 0.00,

    -- ── Import ──────────────────────────────────────────────────────────────────────────────────────────
    `statement_file_name`       VARCHAR(255) NULL,
    `media_id`                  INT UNSIGNED NULL,
    `can_be_import`             TINYINT(1) NOT NULL DEFAULT 0,
    `imported_row_count`        INT UNSIGNED NOT NULL DEFAULT 0,
    -- Off by default. Auto-confirmation is opt-in per school (BR-BRS-03, Solution_Design_v1 OD-08).
    `auto_confirm_exact`        TINYINT(1) NOT NULL DEFAULT 0,
    `match_tolerance_days`      TINYINT UNSIGNED NOT NULL DEFAULT 3,

    `status`                    ENUM('Draft','In_Progress','Completed','Reopened','Abandoned')
                                NOT NULL DEFAULT 'Draft',
    `completed_at`              DATETIME NULL,
    `completed_by`              INT UNSIGNED NULL,
    `reopened_at`               DATETIME NULL,
    `reopened_by`               INT UNSIGNED NULL,
    `reopen_reason`             VARCHAR(500) NULL,
    `notes`                     VARCHAR(1000) NULL,

    `created_by`                INT UNSIGNED NULL,
    `updated_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    -- One live reconciliation per bank account per statement date.
    UNIQUE KEY `uq_acc_br` (`bank_ledger_id`,`statement_date`,`del_marker`),
    INDEX `idx_acc_br_ledger_status` (`bank_ledger_id`,`status`,`statement_date`),
    INDEX `idx_acc_br_period` (`period_id`,`status`),
    INDEX `idx_acc_br_fy` (`financial_year_id`,`statement_date`),
    CONSTRAINT `chk_acc_br_dates` CHECK (`statement_from_date` IS NULL OR `statement_date` >= `statement_from_date`),
    -- A completed reconciliation has no unexplained difference. This is the control, in the schema.
    CONSTRAINT `chk_acc_br_complete` CHECK (`status` <> 'Completed' OR `difference` = 0),
    CONSTRAINT `fk_acc_br_ledger` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_br_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_br_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_br_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_br_completed_by` FOREIGN KEY (`completed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_br_reopened_by` FOREIGN KEY (`reopened_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_br_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_br_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bank reconciliation. Cannot complete while difference <> 0 (BR-BRS-04).';


-- How to read this bank's statement file. Every bank exports a different shape; this is that shape as
-- configuration, so supporting a new bank needs no code. Carried forward from v4.3, retyped.
CREATE TABLE IF NOT EXISTS `acc_bank_statement_mapping` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Reusable per bank account, not per reconciliation: the format does not change month to month.
    -- reconciliation_id is kept nullable for a one-off override of a single import.
    `bank_ledger_id`            INT UNSIGNED NOT NULL,
    `reconciliation_id`         BIGINT UNSIGNED NULL,
    `name`                      VARCHAR(120) NULL,          -- 'HDFC current account CSV'
    `file_format`               ENUM('CSV','XLS','XLSX','MT940','OFX','Other') NOT NULL DEFAULT 'CSV',
    `has_column_header`         TINYINT(1) NOT NULL DEFAULT 0,
    `row_no_for_header`         TINYINT UNSIGNED NULL,
    `import_data_from_row_no`   SMALLINT UNSIGNED NULL,
    `import_data_to_row_no`     SMALLINT UNSIGNED NULL,
    `date_format`               VARCHAR(30) NULL DEFAULT 'd/m/Y',
    `tran_date_column_no`       TINYINT UNSIGNED NULL,
    `value_date_column_no`      TINYINT UNSIGNED NULL,
    `description_column_no`     TINYINT UNSIGNED NULL,
    `reference_column_no`       TINYINT UNSIGNED NULL,
    -- Some banks give separate Dr and Cr columns; others give one amount plus a Dr/Cr indicator.
    `separate_col_for_dr_cr`    TINYINT(1) NOT NULL DEFAULT 0,
    `debit_column_no`           TINYINT UNSIGNED NULL,
    `credit_column_no`          TINYINT UNSIGNED NULL,
    `amount_column_no`          TINYINT UNSIGNED NULL,
    `amount_type_dr_cr_col_no`  TINYINT UNSIGNED NULL,
    `balance_column_no`         TINYINT UNSIGNED NULL,
    `is_default`                TINYINT(1) NOT NULL DEFAULT 1,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_bsm_ledger` (`bank_ledger_id`,`is_active`),
    INDEX `idx_acc_bsm_recon` (`reconciliation_id`),
    CONSTRAINT `fk_acc_bsm_ledger` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bsm_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bsm_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- What the bank says. STAGING DATA: these rows affect no balance, ever (BRD BR-BRS-02).
--
-- IMPORT IDEMPOTENCY (BR-BRS-07, AC-BRS-02). row_hash is a hash of the raw source row — date, description,
-- reference, debit, credit, balance — and UNIQUE (reconciliation_id, row_hash) is what makes re-importing
-- the same file add nothing. A bank statement genuinely can contain two identical rows on one day; when it
-- does, row_occurrence distinguishes them, so a real duplicate is kept and an import duplicate is not.
CREATE TABLE IF NOT EXISTS `acc_bank_statement_entries` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reconciliation_id`     BIGINT UNSIGNED NOT NULL,
    `bank_ledger_id`        INT UNSIGNED NOT NULL,
    `transaction_date`      DATE NOT NULL,
    `value_date`            DATE NULL,
    `description`           VARCHAR(500) NULL,
    `reference`             VARCHAR(255) NULL,
    -- Parsed out of the narration by the importer, and worth 0.20 of the match score.
    `instrument_no`         VARCHAR(50) NULL,
    `debit`                 DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `credit`                DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `balance`               DECIMAL(18,2) NULL,
    `entry_type`            ENUM('Manual','Imported') NOT NULL DEFAULT 'Imported',
    `source_row_no`         INT UNSIGNED NULL,
    `row_hash`              CHAR(64) NOT NULL,          -- SHA-256 of the raw source row
    `row_occurrence`        TINYINT UNSIGNED NOT NULL DEFAULT 1,

    -- DERIVED from acc_bank_reconciliation_matches, maintained by ReconciliationService. It exists only
    -- so "what is still unmatched?" is an index scan. The matches are the truth.
    `match_status`          ENUM('Unmatched','Proposed','Matched','Excluded') NOT NULL DEFAULT 'Unmatched',
    `matched_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    -- An entry a person has decided is not ours — a bank error, another account's row.
    `exclude_reason`        VARCHAR(500) NULL,
    `reconciler_remarks`    VARCHAR(500) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_bse_hash` (`reconciliation_id`,`row_hash`,`row_occurrence`),
    INDEX `idx_acc_bse_recon_status` (`reconciliation_id`,`match_status`),
    INDEX `idx_acc_bse_date` (`bank_ledger_id`,`transaction_date`),
    -- The matching probe: same bank, same amount, near date.
    INDEX `idx_acc_bse_match_probe` (`bank_ledger_id`,`transaction_date`,`debit`,`credit`),
    INDEX `idx_acc_bse_instrument` (`instrument_no`),
    CONSTRAINT `chk_acc_bse_amounts` CHECK (`debit` >= 0 AND `credit` >= 0 AND (`debit` = 0 OR `credit` = 0)),
    CONSTRAINT `chk_acc_bse_exclude` CHECK (`match_status` <> 'Excluded' OR `exclude_reason` IS NOT NULL),
    CONSTRAINT `fk_acc_bse_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bse_ledger` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bank statement staging. Affects no balance. Re-import is a no-op (BR-BRS-07).';


-- One statement row explained by one voucher line.
--
-- The scoring the ReconciliationService applies (Solution_Design_v1 §11.3):
--     0.40  exact amount and side
--     0.25  date within the tolerance window (default +/- 3 days)
--     0.20  instrument number appears in the narration
--     0.10  party name similarity
--     0.05  a previously confirmed match for the same counterparty pattern
--   >= 0.90  propose, pre-selected     0.60-0.89  propose     < 0.60  leave unmatched
--
-- The workflow the schema enforces: Proposed -> Confirmed by a person -> (optionally) Undone.
-- ONLY a Confirmed row sets acc_voucher_items.is_reconciled. A machine never finishes a reconciliation
-- on its own unless the school has turned on auto_confirm_exact (BR-BRS-03).
CREATE TABLE IF NOT EXISTS `acc_bank_reconciliation_matches` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reconciliation_id`     BIGINT UNSIGNED NOT NULL,
    `statement_entry_id`    BIGINT UNSIGNED NOT NULL,
    `voucher_item_id`       BIGINT UNSIGNED NOT NULL,
    `voucher_id`            BIGINT UNSIGNED NOT NULL,   -- denormalised: cancellation releases by voucher
    `amount`                DECIMAL(15,2) NOT NULL,
    `match_method`          ENUM('Auto_Exact','Auto_Scored','Learned','Manual') NOT NULL DEFAULT 'Manual',
    `confidence`            DECIMAL(5,4) NULL,          -- 0.0000 to 1.0000
    `score_breakdown`       JSON NULL,                  -- which components contributed, for explainability
    `status`                ENUM('Proposed','Confirmed','Rejected','Undone') NOT NULL DEFAULT 'Proposed',
    `bank_value_date`       DATE NULL,                  -- copied to acc_voucher_items on confirmation
    `confirmed_at`          DATETIME NULL,
    `confirmed_by`          INT UNSIGNED NULL,
    `rejected_reason`       VARCHAR(500) NULL,
    -- BR-BRS-05: an undo is recorded, not erased.
    `undone_at`             DATETIME NULL,
    `undone_by`             INT UNSIGNED NULL,
    `undo_reason`           VARCHAR(500) NULL,
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_brm` (`statement_entry_id`,`voucher_item_id`),
    INDEX `idx_acc_brm_recon_status` (`reconciliation_id`,`status`),
    INDEX `idx_acc_brm_item` (`voucher_item_id`,`status`),
    INDEX `idx_acc_brm_voucher` (`voucher_id`),
    INDEX `idx_acc_brm_entry` (`statement_entry_id`,`status`),
    INDEX `idx_acc_brm_confidence` (`confidence`,`status`),
    CONSTRAINT `chk_acc_brm_amount` CHECK (`amount` > 0),
    CONSTRAINT `chk_acc_brm_confidence` CHECK (`confidence` IS NULL OR (`confidence` >= 0 AND `confidence` <= 1)),
    CONSTRAINT `chk_acc_brm_confirmed` CHECK (`status` <> 'Confirmed' OR `confirmed_by` IS NOT NULL),
    CONSTRAINT `chk_acc_brm_undone` CHECK (`status` <> 'Undone' OR `undo_reason` IS NOT NULL),
    CONSTRAINT `fk_acc_brm_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_brm_entry` FOREIGN KEY (`statement_entry_id`) REFERENCES `acc_bank_statement_entries`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_brm_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_brm_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_brm_confirmed_by` FOREIGN KEY (`confirmed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_brm_undone_by` FOREIGN KEY (`undone_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_brm_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Proposed and confirmed statement-to-ledger matches. Only Confirmed reconciles a line.';


-- =========================================================================================================
-- SECTION 10: RECURRING VOUCHERS
--
--     BRD BR-RECUR-01: a recurring definition is a TEMPLATE, never a posted transaction. BR-RECUR-03: a
--     change to the template never alters vouchers already generated — which is why the generated voucher
--     is a normal acc_vouchers row, complete in itself, and not a pointer back to the template.
--
--     AC-RECUR-01 is the interesting one: "a monthly rent template generates exactly twelve vouchers in a
--     year, none duplicated even if the job runs twice in a day." That is not a job-scheduling problem, it
--     is a uniqueness problem, and it is solved below by UNIQUE (template, scheduled_date) on the run log —
--     including for runs that FAILED, so a failure is a recorded outcome rather than an invitation to try
--     again and post twice.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_recurring_templates` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(150) NOT NULL,
    `code`                  VARCHAR(30) NULL,
    `voucher_type_id`       SMALLINT UNSIGNED NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `party_ledger_id`       INT UNSIGNED NULL,

    -- ── Schedule ────────────────────────────────────────────────────────────────────────────────────────
    `frequency`             ENUM('Daily','Weekly','Monthly','Quarterly','Half_Yearly','Yearly','Custom') NOT NULL,
    `interval_days`         SMALLINT UNSIGNED NULL,     -- only for 'Custom': every N days
    `day_of_month_week`     TINYINT UNSIGNED NULL,      -- 1-31 for Monthly/Quarterly/Yearly; 1-7 for Weekly
    -- A month-end template asks for the 31st and gets 28 in February. This says what to do about it.
    `month_end_policy`      ENUM('Same_Day','Last_Day_Of_Month','Skip') NOT NULL DEFAULT 'Same_Day',
    `start_date`            DATE NOT NULL,
    -- BR-RECUR-05: a template has an end condition and stops. Exactly one of the two is set.
    `end_date`              DATE NULL,
    `occurrence_limit`      SMALLINT UNSIGNED NULL,
    `occurrences_generated` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `last_generated_date`   DATE NULL,
    `next_due_date`         DATE NULL,                  -- the scheduler's index; recomputed after each run

    -- ── Posting behaviour ───────────────────────────────────────────────────────────────────────────────
    -- BR-RECUR-02: generated vouchers are DRAFTS unless explicitly configured otherwise, and auto-posting
    -- requires the acc.recurring.autopost permission, checked when this flag is set — not when it is used.
    `auto_post`             TINYINT(1) NOT NULL DEFAULT 0,
    `requires_approval`     TINYINT(1) NOT NULL DEFAULT 0,
    `narration`             TEXT NULL,
    `total_amount`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,  -- must equal Σ Dr and Σ Cr of the lines
    `status`                ENUM('Active','Paused','Completed','Cancelled') NOT NULL DEFAULT 'Active',
    `paused_reason`         VARCHAR(500) NULL,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_rt_name` (`name`,`del_marker`),
    UNIQUE KEY `uq_acc_rt_code` (`code`,`del_marker`),
    -- The scheduler's only query: which templates are due today?
    INDEX `idx_acc_rt_due` (`status`,`next_due_date`),
    INDEX `idx_acc_rt_type` (`voucher_type_id`),
    INDEX `idx_acc_rt_party` (`party_ledger_id`),
    CONSTRAINT `chk_acc_rt_end` CHECK (
        (`end_date` IS NOT NULL AND `occurrence_limit` IS NULL AND `end_date` >= `start_date`)
     OR (`end_date` IS NULL AND `occurrence_limit` IS NOT NULL)
    ),
    CONSTRAINT `chk_acc_rt_custom` CHECK (`frequency` <> 'Custom' OR `interval_days` IS NOT NULL),
    CONSTRAINT `fk_acc_rt_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_rt_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_rt_party` FOREIGN KEY (`party_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_rt_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_rt_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Recurring voucher definitions. A template, never a transaction (BR-RECUR-01).';


CREATE TABLE IF NOT EXISTS `acc_recurring_template_lines` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `recurring_template_id` BIGINT UNSIGNED NOT NULL,
    `sequence_no`           SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `ledger_id`             INT UNSIGNED NOT NULL,
    `entry_type`            ENUM('Dr','Cr') NOT NULL,
    `amount`                DECIMAL(15,2) NOT NULL,
    `narration`             VARCHAR(500) NULL,
    -- Default dimensions for the generated line. The generated voucher gets real allocation rows in
    -- acc_voucher_item_cost_centers / acc_voucher_item_funds; these are only what the template proposes.
    `cost_center_id`        INT UNSIGNED NULL,
    `cost_category_id`      SMALLINT UNSIGNED NULL,
    `fund_id`               INT UNSIGNED NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_rtl_sequence` (`recurring_template_id`,`sequence_no`),
    INDEX `idx_acc_rtl_template` (`recurring_template_id`),
    INDEX `idx_acc_rtl_ledger` (`ledger_id`),
    INDEX `idx_acc_rtl_cc` (`cost_center_id`),
    INDEX `idx_acc_rtl_fund` (`fund_id`),
    CONSTRAINT `chk_acc_rtl_amount` CHECK (`amount` >= 0),
    CONSTRAINT `fk_acc_rtl_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_rtl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_rtl_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_rtl_cat` FOREIGN KEY (`cost_category_id`) REFERENCES `acc_cost_categories`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_rtl_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Every generation attempt, including the ones that failed (BRD BR-RECUR-04).
--
-- v4.3 named this table's foreign key fk_acc_rtl_template and its index idx_acc_rtl_template — the same
-- names already used by acc_recurring_template_lines. Constraint names are unique per SCHEMA in MySQL, so
-- the second table simply failed to create. Both are renamed here (Solution_Design_v1 §17.1 #8).
CREATE TABLE IF NOT EXISTS `acc_recurring_transaction_log` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `recurring_template_id` BIGINT UNSIGNED NOT NULL,
    `scheduled_date`        DATE NOT NULL,              -- the occurrence this run is FOR, not when it ran
    `occurrence_no`         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `run_at`                DATETIME NOT NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,       -- NULL when the run failed or was skipped
    `voucher_date`          DATE NULL,
    `total_amount`          DECIMAL(15,2) NULL,
    `outcome`               ENUM('Generated','Posted','Skipped','Failed') NOT NULL,
    `skip_reason`           VARCHAR(255) NULL,          -- period closed, template paused, limit reached
    `error_message`         TEXT NULL,
    `posted_at`             DATETIME NULL,
    `posted_by`             INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- The duplicate guard behind AC-RECUR-01. Running the scheduler twice in one day inserts nothing the
    -- second time, whatever the first run's outcome was.
    UNIQUE KEY `uq_acc_rtlog_occurrence` (`recurring_template_id`,`scheduled_date`),
    INDEX `idx_acc_rtlog_template` (`recurring_template_id`,`outcome`),
    INDEX `idx_acc_rtlog_voucher` (`voucher_id`),
    INDEX `idx_acc_rtlog_outcome` (`outcome`,`run_at`),
    CONSTRAINT `fk_acc_rtlog_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_rtlog_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_rtlog_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Recurring generation log. UNIQUE(template, scheduled_date) is the no-double-post guard.';


-- =========================================================================================================
-- SECTION 11: FIXED ASSETS, DEPRECIATION AND DISPOSAL
--
--     WHAT IS NOT HERE. v4.3's acc_fixed_assets stored current_value and accumulated_depreciation as
--     columns, with nothing stating when they change — the same defect as acc_ledgers.closing_balance,
--     and with the same consequence: the asset register and the asset ledgers drift apart, and BRD
--     BR-FA-07 ("the register must reconcile to the asset ledgers") quietly becomes false.
--
--     They are gone. Net block is:
--         purchase_cost  -  Σ acc_depreciation_entries.depreciation_amount  -  disposal
--     computed in vw_fixed_asset_register, which is the single place that arithmetic exists, and asserted
--     against the asset ledger balances nightly (AC-FA-01).
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_asset_categories` (
    `id`                        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                      VARCHAR(20) NOT NULL,
    `name`                      VARCHAR(100) NOT NULL,
    `parent_id`                 SMALLINT UNSIGNED NULL,
    `depreciation_method`       ENUM('SLM','WDV','None') NOT NULL DEFAULT 'SLM',
    `depreciation_rate`         DECIMAL(9,4) NOT NULL DEFAULT 0.0000,   -- annual %
    `useful_life_years`         SMALLINT UNSIGNED NULL,
    -- The three ledgers every asset in this category posts to. Without them, depreciation cannot be
    -- posted as an accounting transaction, and BR-FA-03 requires that it is.
    `asset_ledger_id`           INT UNSIGNED NULL,      -- the balance-sheet asset head
    `accum_dep_ledger_id`       INT UNSIGNED NULL,      -- accumulated depreciation (contra-asset)
    `depreciation_expense_ledger_id` INT UNSIGNED NULL, -- the I&E charge
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    -- v4.3 used UNIQUE(code, deleted_at) here, which permits unlimited LIVE duplicates because MySQL
    -- treats NULLs as distinct. Fixed by the generated del_marker (Solution_Design_v1 §17.1 #10).
    UNIQUE KEY `uq_acc_assetcat_code` (`code`,`del_marker`),
    INDEX `idx_acc_assetcat_parent` (`parent_id`),
    INDEX `idx_acc_assetcat_ledger` (`asset_ledger_id`),
    CONSTRAINT `chk_acc_assetcat_rate` CHECK (`depreciation_rate` >= 0 AND `depreciation_rate` <= 100),
    CONSTRAINT `fk_acc_assetcat_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_asset_categories`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_assetcat_asset_led` FOREIGN KEY (`asset_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_assetcat_accum_led` FOREIGN KEY (`accum_dep_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_assetcat_exp_led` FOREIGN KEY (`depreciation_expense_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_assetcat_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `acc_fixed_assets` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `asset_code`                VARCHAR(50) NOT NULL,
    `name`                      VARCHAR(150) NOT NULL,
    `description`               VARCHAR(500) NULL,
    `asset_category_id`         SMALLINT UNSIGNED NOT NULL,
    `parent_asset_id`           BIGINT UNSIGNED NULL,   -- a capital improvement to an existing asset

    `purchase_date`             DATE NOT NULL,
    `put_to_use_date`           DATE NULL,              -- when depreciation starts, which is not always
                                                        -- the purchase date
    `purchase_cost`             DECIMAL(15,2) NOT NULL,
    `salvage_value`             DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    -- Per-asset override of the category's policy, where an asset genuinely differs.
    `depreciation_method`       ENUM('SLM','WDV','None') NULL,
    `depreciation_rate`         DECIMAL(9,4) NULL,
    `useful_life_years`         SMALLINT UNSIGNED NULL,

    -- BR-FA-01: location and custodian. BR-FA-06: the fund it was bought from.
    `location`                  VARCHAR(150) NULL,
    `custodian_user_id`         INT UNSIGNED NULL,
    `campus_id`                 SMALLINT UNSIGNED NULL,
    `cost_center_id`            INT UNSIGNED NULL,
    `fund_id`                   INT UNSIGNED NULL,
    `vendor_id`                 INT UNSIGNED NULL,

    -- BR-FA-02: acquisition traceable to its purchase voucher. v4.3 declared an index and a foreign key
    -- on this column while the column itself was commented out, so the table would not create.
    `voucher_id`                BIGINT UNSIGNED NULL,
    `invoice_no`                VARCHAR(100) NULL,
    `serial_no`                 VARCHAR(100) NULL,
    `warranty_upto`             DATE NULL,
    `insurance_policy_no`       VARCHAR(100) NULL,
    `insured_upto`              DATE NULL,

    `status`                    ENUM('Active','Disposed','Written_Off','Held_For_Sale','Lost')
                                NOT NULL DEFAULT 'Active',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `notes`                     VARCHAR(1000) NULL,
    `created_by`                INT UNSIGNED NULL,
    `updated_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fa_code` (`asset_code`,`del_marker`),
    INDEX `idx_acc_fa_category_status` (`asset_category_id`,`status`),
    INDEX `idx_acc_fa_voucher` (`voucher_id`),
    INDEX `idx_acc_fa_vendor` (`vendor_id`),
    INDEX `idx_acc_fa_fund` (`fund_id`),
    INDEX `idx_acc_fa_cc` (`cost_center_id`),
    INDEX `idx_acc_fa_campus` (`campus_id`,`status`),
    INDEX `idx_acc_fa_custodian` (`custodian_user_id`),
    INDEX `idx_acc_fa_purchase` (`purchase_date`),
    INDEX `idx_acc_fa_parent` (`parent_asset_id`),
    CONSTRAINT `chk_acc_fa_cost` CHECK (`purchase_cost` >= 0 AND `salvage_value` >= 0 AND `salvage_value` <= `purchase_cost`),
    CONSTRAINT `chk_acc_fa_use_date` CHECK (`put_to_use_date` IS NULL OR `put_to_use_date` >= `purchase_date`),
    CONSTRAINT `fk_acc_fa_category` FOREIGN KEY (`asset_category_id`) REFERENCES `acc_asset_categories`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_parent` FOREIGN KEY (`parent_asset_id`) REFERENCES `acc_fixed_assets`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_fa_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_custodian` FOREIGN KEY (`custodian_user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_fa_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_fa_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Asset register. Net block is DERIVED, not stored — see vw_fixed_asset_register.';


-- One depreciation charge, for one asset, for one period.
--
-- BR-FA-04: depreciation is never posted twice for the same asset and period. That is not a job flag or a
-- careful operator; it is UNIQUE (fixed_asset_id, period_id) below, so a re-run posts nothing (AC-FA-02).
CREATE TABLE IF NOT EXISTS `acc_depreciation_entries` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fixed_asset_id`            BIGINT UNSIGNED NOT NULL,
    `financial_year_id`         SMALLINT UNSIGNED NOT NULL,
    `period_id`                 SMALLINT UNSIGNED NOT NULL,
    `depreciation_date`         DATE NOT NULL,
    -- The computation, kept so any figure can be explained without re-deriving it from a policy that
    -- may since have changed.
    `method`                    ENUM('SLM','WDV') NOT NULL,
    `rate_applied`              DECIMAL(9,4) NOT NULL,
    `opening_wdv`               DECIMAL(15,2) NOT NULL,
    `depreciation_amount`       DECIMAL(15,2) NOT NULL,
    `closing_wdv`               DECIMAL(15,2) NOT NULL,
    `days_in_use`               SMALLINT UNSIGNED NULL, -- pro-rata in the year of purchase or disposal
    `voucher_id`                BIGINT UNSIGNED NULL,   -- the depreciation journal. BR-FA-03.
    `is_posted`                 TINYINT(1) NOT NULL DEFAULT 0,
    `computed_by`               INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_de_asset_period` (`fixed_asset_id`,`period_id`),
    INDEX `idx_acc_de_fy` (`financial_year_id`,`is_posted`),
    INDEX `idx_acc_de_voucher` (`voucher_id`),
    INDEX `idx_acc_de_asset` (`fixed_asset_id`,`depreciation_date`),
    CONSTRAINT `chk_acc_de_amount` CHECK (`depreciation_amount` >= 0),
    CONSTRAINT `fk_acc_de_asset` FOREIGN KEY (`fixed_asset_id`) REFERENCES `acc_fixed_assets`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_de_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_de_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_de_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_de_by` FOREIGN KEY (`computed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Depreciation charges. UNIQUE(asset, period) makes a re-run a no-op (BR-FA-04).';


-- BR-FA-05: disposal records proceeds, computes gain or loss, and preserves the asset's history.
-- The asset row is NOT deleted; its status becomes Disposed and this row says what happened.
CREATE TABLE IF NOT EXISTS `acc_asset_disposals` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fixed_asset_id`            BIGINT UNSIGNED NOT NULL,
    `disposal_date`             DATE NOT NULL,
    `disposal_type`             ENUM('Sale','Scrap','Donation','Loss','Transfer') NOT NULL,
    `buyer_ledger_id`           INT UNSIGNED NULL,
    `sale_proceeds`             DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `disposal_cost`             DECIMAL(15,2) NOT NULL DEFAULT 0.00,    -- removal, brokerage
    -- The three figures the gain or loss is made of, frozen at disposal.
    `cost_at_disposal`          DECIMAL(15,2) NOT NULL,
    `accumulated_depreciation`  DECIMAL(15,2) NOT NULL,
    `net_book_value`            DECIMAL(15,2) NOT NULL,
    `gain_loss_amount`          DECIMAL(15,2) NOT NULL,     -- proceeds - costs - NBV; negative = loss
    `voucher_id`                BIGINT UNSIGNED NULL,       -- the disposal journal
    `approved_by`               INT UNSIGNED NULL,
    `approved_at`               DATETIME NULL,
    `reason`                    VARCHAR(1000) NULL,
    `created_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ad_asset` (`fixed_asset_id`),        -- an asset is disposed once
    INDEX `idx_acc_ad_date` (`disposal_date`,`disposal_type`),
    INDEX `idx_acc_ad_voucher` (`voucher_id`),
    INDEX `idx_acc_ad_buyer` (`buyer_ledger_id`),
    CONSTRAINT `fk_acc_ad_asset` FOREIGN KEY (`fixed_asset_id`) REFERENCES `acc_fixed_assets`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ad_buyer` FOREIGN KEY (`buyer_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ad_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ad_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ad_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 12: EXPENSE CLAIMS
--
--     BR-EXP-02: a claim posts to the books ONLY on approval. An unapproved claim therefore appears in no
--     expenditure figure (AC-EXP-01) — which follows automatically here, because an unapproved claim has
--     no voucher, and expenditure is derived from vouchers.
--
--     v4.3 ended this section with roughly 45 lines of raw, uncommented assignment text describing the
--     posting map, which is a syntax error the moment MySQL reaches it (Solution_Design_v1 §17.1 #7).
--     That map is genuinely useful, so it is preserved below — as comments.
--
--     THE POSTING MAP, on approval:
--         voucher            type PAYMENT (or JOURNAL where payment is deferred)
--                            voucher_date        = acc_expense_claims.approved_at::date
--                            narration           = acc_expense_claims.narration
--                            total_amount        = acc_expense_claims.total_amount
--                            party_ledger_id     = the employee's ledger
--                            source_model        = 'acc_expense_claims'
--                            source_id           = acc_expense_claims.id
--                            source_event_uid    = 'claim-approved'      <- idempotency
--         Dr lines           one per claim line: ledger_id and amount from acc_expense_claim_lines
--         Cr line            one: the employee's ledger, for the claim total
--         cost centres       acc_voucher_item_cost_centers, from each line's cost_center_id
--         voucher_number     allocated by NumberingService at POSTING, never before  (BR-VNO-02)
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_expense_claims` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `claim_number`          VARCHAR(50) NOT NULL,
    `employee_id`           INT UNSIGNED NOT NULL,
    `employee_ledger_id`    INT UNSIGNED NULL,          -- resolved at submission; the Cr side of the posting
    `claim_date`            DATE NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `narration`             VARCHAR(500) NULL,
    `total_amount`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `approved_amount`       DECIMAL(15,2) NULL,         -- an approver may pass less than was claimed
    `advance_adjusted`      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `payable_amount`        DECIMAL(15,2) NULL,

    -- v4.3 pointed this at the generic acc_accounting_status_masters, which meant a claim's status could
    -- be a voucher status or a Tally-export status and nothing would object (§17.1 #11). Typed now.
    `status`                ENUM('Draft','Submitted','Pending_Approval','Approved','Rejected','Paid','Cancelled')
                            NOT NULL DEFAULT 'Draft',
    `submitted_at`          DATETIME NULL,
    `approved_by`           INT UNSIGNED NULL,
    `approved_at`           DATETIME NULL,
    `rejected_reason`       VARCHAR(1000) NULL,
    -- BR-EXP-02 / BR-EXP-05: the accounting voucher, and the payment that settled it, each traceable.
    `voucher_id`            BIGINT UNSIGNED NULL,
    `payment_voucher_id`    BIGINT UNSIGNED NULL,
    `paid_at`               DATETIME NULL,

    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ec_number` (`claim_number`,`del_marker`),
    INDEX `idx_acc_ec_employee_status` (`employee_id`,`status`),
    INDEX `idx_acc_ec_status_date` (`status`,`claim_date`),
    INDEX `idx_acc_ec_voucher` (`voucher_id`),
    INDEX `idx_acc_ec_payment` (`payment_voucher_id`),
    INDEX `idx_acc_ec_fy` (`financial_year_id`,`status`),
    INDEX `idx_acc_ec_approver` (`approved_by`,`approved_at`),
    CONSTRAINT `chk_acc_ec_amount` CHECK (`total_amount` >= 0),
    -- BR-EXP-04: a claimant may not approve their own claim. The employee-to-user link lives outside
    -- accounting, so ClaimService enforces the identity; this guarantees an approver was recorded at all.
    CONSTRAINT `chk_acc_ec_approved` CHECK (`status` <> 'Approved' OR `approved_by` IS NOT NULL),
    CONSTRAINT `chk_acc_ec_rejected` CHECK (`status` <> 'Rejected' OR `rejected_reason` IS NOT NULL),
    CONSTRAINT `fk_acc_ec_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ec_emp_ledger` FOREIGN KEY (`employee_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ec_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ec_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ec_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ec_payment` FOREIGN KEY (`payment_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ec_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ec_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ec_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- BR-EXP-03: claim lines carry their own expense head, cost centre and evidence.
CREATE TABLE IF NOT EXISTS `acc_expense_claim_lines` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `expense_claim_id`      BIGINT UNSIGNED NOT NULL,
    `sequence_no`           SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `expense_date`          DATE NOT NULL,
    `reference_number`      VARCHAR(50) NULL,
    `ledger_id`             INT UNSIGNED NOT NULL,      -- the expense head
    `cost_center_id`        INT UNSIGNED NULL,
    `cost_category_id`      SMALLINT UNSIGNED NULL,
    `fund_id`               INT UNSIGNED NULL,
    `description`           VARCHAR(255) NOT NULL,
    `amount`                DECIMAL(15,2) NOT NULL,
    `tax_amount`            DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `total_amount`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `approved_amount`       DECIMAL(15,2) NULL,
    `line_status`           ENUM('Claimed','Approved','Reduced','Rejected') NOT NULL DEFAULT 'Claimed',
    `reject_reason`         VARCHAR(500) NULL,
    `receipt_file_name`     VARCHAR(255) NULL,
    `media_id`              INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ecl_sequence` (`expense_claim_id`,`sequence_no`),
    INDEX `idx_acc_ecl_claim` (`expense_claim_id`),
    INDEX `idx_acc_ecl_ledger` (`ledger_id`),
    INDEX `idx_acc_ecl_cc` (`cost_center_id`),
    INDEX `idx_acc_ecl_fund` (`fund_id`),
    INDEX `idx_acc_ecl_date` (`expense_date`),
    CONSTRAINT `chk_acc_ecl_amount` CHECK (`amount` >= 0 AND `tax_amount` >= 0),
    CONSTRAINT `fk_acc_ecl_claim` FOREIGN KEY (`expense_claim_id`) REFERENCES `acc_expense_claims`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ecl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ecl_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ecl_cat` FOREIGN KEY (`cost_category_id`) REFERENCES `acc_cost_categories`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ecl_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ecl_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 13: BUDGETS, INTEREST AND CREDIT CONTROL
--
--     v4.3's acc_budgets was one flat table keyed (financial_year, cost_center, ledger), which cannot
--     express any of BRD §34: several coexisting budgets (original / revised / forecast, BR-BUD-02),
--     budgets by group or fund or campus (BR-BUD-01), per-period phasing, or traceable revision
--     (BR-BUD-04). It is split here into a header and its lines.
--
--     BR-BUD-03 — "actuals are never affected by budgets" — is why nothing in this section is referenced
--     by anything in Section 6. A budget is a comparison, not an input.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_budgets` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(30) NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    -- BR-BUD-02: several budgets coexist, and each is identified.
    `budget_type`           ENUM('Original','Revised','Forecast','Scenario') NOT NULL DEFAULT 'Original',
    `version`               SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    -- BR-BUD-04: a revision names what it revised. Nothing is edited in place.
    `supersedes_budget_id`  INT UNSIGNED NULL,
    `revision_reason`       VARCHAR(1000) NULL,
    -- BR-BUD-06: exceeding a budget may warn or block, by configuration.
    `breach_action`         ENUM('None','Warn','Approve','Block') NOT NULL DEFAULT 'Warn',
    `breach_tolerance_pct`  DECIMAL(9,4) NOT NULL DEFAULT 0.0000,
    `status`                ENUM('Draft','Approved','Active','Superseded','Closed') NOT NULL DEFAULT 'Draft',
    `approved_by`           INT UNSIGNED NULL,
    `approved_at`           DATETIME NULL,
    `notes`                 VARCHAR(1000) NULL,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_budget_code` (`code`,`version`,`del_marker`),
    INDEX `idx_acc_budget_fy_status` (`financial_year_id`,`status`),
    INDEX `idx_acc_budget_type` (`budget_type`,`financial_year_id`),
    INDEX `idx_acc_budget_supersedes` (`supersedes_budget_id`),
    INDEX `idx_acc_budget_campus` (`campus_id`),
    CONSTRAINT `fk_acc_budget_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_budget_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_budget_supersedes` FOREIGN KEY (`supersedes_budget_id`) REFERENCES `acc_budgets`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_budget_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_budget_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_budget_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One budgeted amount, for one thing, for one period.
--
-- The "one thing" is any of: a ledger, an account group, a cost centre, a fund, a campus, or a combination
-- of them (BR-BUD-01). Rather than six tables or six nullable-and-mutually-exclusive columns, all six are
-- nullable dimensions and the unique key covers the whole tuple — the same shape as the balance buckets in
-- Section 8, and it compares to them directly.
CREATE TABLE IF NOT EXISTS `acc_budget_lines` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `budget_id`             INT UNSIGNED NOT NULL,
    `ledger_id`             INT UNSIGNED NULL,
    `account_group_id`      INT UNSIGNED NULL,          -- budget at group level, allocated down in reporting
    `cost_center_id`        INT UNSIGNED NULL,
    `fund_id`               INT UNSIGNED NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    -- NULL period = the annual figure. A per-period row is the monthly phasing of it.
    `period_id`             SMALLINT UNSIGNED NULL,
    `budgeted_amount`       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `notes`                 VARCHAR(500) NULL,
    -- NULL-SAFE UNIQUENESS. MySQL treats NULLs as DISTINCT in a unique key, so a key spanning a
    -- nullable column enforces nothing on the rows where that column is NULL — the same defect as
    -- v4.3's UNIQUE(code, deleted_at). These generated columns collapse NULL to 0 so the key means
    -- what it says.
    `ledger_marker`         INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`ledger_id`,0))        STORED,
    `group_marker`          INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`account_group_id`,0)) STORED,
    `cc_marker`             INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`cost_center_id`,0))   STORED,
    `fund_marker`           INT UNSIGNED      GENERATED ALWAYS AS (IFNULL(`fund_id`,0))          STORED,
    `campus_marker`         SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0))        STORED,
    `period_marker`         SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`period_id`,0))        STORED,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_bl` (`budget_id`,`ledger_marker`,`group_marker`,`cc_marker`,`fund_marker`,`campus_marker`,`period_marker`),
    INDEX `idx_acc_bl_budget` (`budget_id`),
    INDEX `idx_acc_bl_ledger` (`ledger_id`,`period_id`),
    INDEX `idx_acc_bl_group` (`account_group_id`,`period_id`),
    INDEX `idx_acc_bl_cc` (`cost_center_id`,`period_id`),
    INDEX `idx_acc_bl_fund` (`fund_id`,`period_id`),
    -- At least one dimension must be set; a budget line against nothing budgets nothing.
    CONSTRAINT `chk_acc_bl_dimension` CHECK (
        `ledger_id` IS NOT NULL OR `account_group_id` IS NOT NULL OR
        `cost_center_id` IS NOT NULL OR `fund_id` IS NOT NULL
    ),
    CONSTRAINT `fk_acc_bl_budget` FOREIGN KEY (`budget_id`) REFERENCES `acc_budgets`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bl_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bl_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bl_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bl_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bl_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Interest rules (BRD §37). Phase 4, but the shape is settled now because interest computed against a
-- rule that has since been edited is not explainable, and BR-INT-03 requires that it is.
CREATE TABLE IF NOT EXISTS `acc_interest_rules` (
    `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(30) NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    `ledger_id`             INT UNSIGNED NULL,          -- NULL = applies to a party type instead
    `applies_to_party_type` ENUM('Any','Student','Parent','Vendor','Employee','Donor','Grantor','Other')
                            NOT NULL DEFAULT 'Any',
    `rate_percent`          DECIMAL(9,4) NOT NULL,
    `basis`                 ENUM('Simple','Compound') NOT NULL DEFAULT 'Simple',
    `compounding`           ENUM('None','Monthly','Quarterly','Half_Yearly','Yearly') NOT NULL DEFAULT 'None',
    `day_count`             ENUM('Actual_365','Actual_360','30_360','Actual_Actual') NOT NULL DEFAULT 'Actual_365',
    `calculate_from`        ENUM('Due_Date','Bill_Date','Transaction_Date') NOT NULL DEFAULT 'Due_Date',
    `grace_days`            SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `minimum_amount`        DECIMAL(15,2) NULL,         -- below this, do not charge
    `interest_ledger_id`    INT UNSIGNED NULL,          -- where the interest posts
    `effective_from`        DATE NOT NULL,
    `effective_to`          DATE NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ir_code` (`code`,`del_marker`),
    INDEX `idx_acc_ir_ledger` (`ledger_id`,`is_active`),
    INDEX `idx_acc_ir_effective` (`effective_from`,`effective_to`),
    CONSTRAINT `chk_acc_ir_rate` CHECK (`rate_percent` >= 0),
    CONSTRAINT `chk_acc_ir_eff` CHECK (`effective_to` IS NULL OR `effective_to` >= `effective_from`),
    CONSTRAINT `fk_acc_ir_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ir_int_ledger` FOREIGN KEY (`interest_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ir_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One interest computation, kept with every input that produced it.
-- BR-INT-02: calculated interest is a PROPOSAL until posted as a voucher — hence the status column, and
-- hence a nullable voucher_id. AC-INT-01: any interest figure can be expanded to show its computation,
-- which is what principal / rate / days / basis, all stored, actually are.
CREATE TABLE IF NOT EXISTS `acc_interest_computations` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `interest_rule_id`      SMALLINT UNSIGNED NOT NULL,
    `ledger_id`             INT UNSIGNED NOT NULL,
    `bill_reference_id`     BIGINT UNSIGNED NULL,
    `computed_upto`         DATE NOT NULL,
    `principal_amount`      DECIMAL(15,2) NOT NULL,
    `rate_applied`          DECIMAL(9,4) NOT NULL,
    `from_date`             DATE NOT NULL,
    `to_date`               DATE NOT NULL,
    `days`                  INT UNSIGNED NOT NULL,
    `day_count_basis`       ENUM('Actual_365','Actual_360','30_360','Actual_Actual') NOT NULL,
    `interest_amount`       DECIMAL(15,2) NOT NULL,
    `status`                ENUM('Proposed','Accepted','Waived','Posted','Cancelled') NOT NULL DEFAULT 'Proposed',
    `waive_reason`          VARCHAR(500) NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,
    `computed_by`           INT UNSIGNED NULL,
    `bill_marker`           BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`bill_reference_id`,0)) STORED,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- One computation per bill (or per ledger) per run date. Re-running the calculation replaces nothing
    -- and duplicates nothing. bill_marker keeps that true for a ledger-level computation, where
    -- bill_reference_id is NULL.
    UNIQUE KEY `uq_acc_ic_run` (`ledger_id`,`bill_marker`,`computed_upto`,`interest_rule_id`),
    INDEX `idx_acc_ic_status` (`status`,`computed_upto`),
    INDEX `idx_acc_ic_ledger` (`ledger_id`,`status`),
    INDEX `idx_acc_ic_bill` (`bill_reference_id`),
    INDEX `idx_acc_ic_voucher` (`voucher_id`),
    CONSTRAINT `chk_acc_ic_amounts` CHECK (`principal_amount` >= 0 AND `interest_amount` >= 0),
    CONSTRAINT `chk_acc_ic_dates` CHECK (`to_date` >= `from_date`),
    CONSTRAINT `chk_acc_ic_waive` CHECK (`status` <> 'Waived' OR `waive_reason` IS NOT NULL),
    CONSTRAINT `fk_acc_ic_rule` FOREIGN KEY (`interest_rule_id`) REFERENCES `acc_interest_rules`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_ic_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ic_bill` FOREIGN KEY (`bill_reference_id`) REFERENCES `acc_bill_references`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ic_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_ic_by` FOREIGN KEY (`computed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Interest proposals with their full computation. Not a ledger entry until posted (BR-INT-02).';


-- BR-CRED-04: every credit-limit override is recorded with approver and reason. AC-CRED-01: a breach
-- cannot proceed silently under any setting — so the override is a row, created before the voucher posts.
CREATE TABLE IF NOT EXISTS `acc_credit_limit_overrides` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`             INT UNSIGNED NOT NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,
    `credit_limit`          DECIMAL(15,2) NULL,         -- the limit as it stood
    `current_exposure`      DECIMAL(15,2) NOT NULL,     -- outstanding bills at the moment of the check
    `attempted_amount`      DECIMAL(15,2) NOT NULL,
    `excess_amount`         DECIMAL(15,2) NOT NULL,
    `action_taken`          ENUM('Warned','Approved','Blocked') NOT NULL,
    `approved_by`           INT UNSIGNED NULL,
    `approved_at`           DATETIME NULL,
    `reason`                VARCHAR(1000) NULL,
    `requested_by`          INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_clo_ledger` (`ledger_id`,`created_at`),
    INDEX `idx_acc_clo_voucher` (`voucher_id`),
    INDEX `idx_acc_clo_action` (`action_taken`,`created_at`),
    CONSTRAINT `chk_acc_clo_approved` CHECK (`action_taken` <> 'Approved' OR (`approved_by` IS NOT NULL AND `reason` IS NOT NULL)),
    CONSTRAINT `fk_acc_clo_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_clo_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_clo_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_clo_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 14: SCHOOL-SPECIFIC — CONCESSIONS, DONATIONS, GRANTS
--
--     These three are what make this an accounting system for a SCHOOL TRUST rather than a generic ledger,
--     and none of them existed in v4.3.
--
--     The principle common to all three (BRD BR-CONC-01, BR-DON-01, BR-GRANT-01): the school must be able
--     to state the gross figure, the adjustment, and the net figure separately. A concession that quietly
--     reduces a demand leaves no way to answer "what did concessions cost us this year?" — which is,
--     per the BRD, usually the second-largest item in a school's accounts and the least controlled.
-- =========================================================================================================

-- A concession is recorded EXPLICITLY. It never reduces the gross demand silently (BR-CONC-01).
--
-- BR-CONC-04 distinguishes two cases, and the schema keeps both:
--     granted BEFORE the demand  -> the demand is raised net, and gross_amount records what it would
--                                   have been. Nothing is lost.
--     granted AFTER the demand   -> a credit note against the receivable, and voucher_id points at it.
--
-- BR-CONC-06: a write-off is NOT a concession. A write-off lives on acc_bill_references
-- (written_off_amount / written_off_voucher_id) and never appears here.
CREATE TABLE IF NOT EXISTS `acc_concessions` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `concession_no`         VARCHAR(50) NOT NULL,
    `student_id`            INT UNSIGNED NULL,
    `student_ledger_id`     INT UNSIGNED NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `concession_date`       DATE NOT NULL,

    -- BR-CONC-03: type, authoriser and sanction reference, on every concession.
    `concession_type`       ENUM('Scholarship','Sibling','Staff_Ward','Merit','Hardship','Management',
                                 'RTE','Alumni','Sports','Other') NOT NULL,
    `sanction_reference`    VARCHAR(100) NULL,
    `authorised_by`         INT UNSIGNED NULL,
    `authorised_at`         DATETIME NULL,

    -- BR-CONC-02: gross, concession and net separately reportable.
    `gross_amount`          DECIMAL(15,2) NOT NULL,
    `concession_amount`     DECIMAL(15,2) NOT NULL,
    `net_amount`            DECIMAL(15,2) NOT NULL,
    `concession_percent`    DECIMAL(9,4) NULL,

    `timing`                ENUM('Before_Demand','After_Demand') NOT NULL DEFAULT 'Before_Demand',
    `bill_reference_id`     BIGINT UNSIGNED NULL,   -- the demand it relates to
    `voucher_id`            BIGINT UNSIGNED NULL,   -- the credit note, where timing = After_Demand
    `concession_ledger_id`  INT UNSIGNED NULL,      -- the expense/contra-income head it posts to

    `source_module_key`     VARCHAR(10) NULL,       -- 'FEE' where the Fees module raised it
    `source_model`          VARCHAR(100) NULL,
    `source_id`             BIGINT UNSIGNED NULL,

    `status`                ENUM('Draft','Approved','Posted','Cancelled') NOT NULL DEFAULT 'Draft',
    `cancelled_reason`      VARCHAR(500) NULL,
    `remarks`               VARCHAR(1000) NULL,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_conc_no` (`concession_no`,`del_marker`),
    -- One concession per source record. Replaying a Fees event grants nothing twice.
    UNIQUE KEY `uq_acc_conc_source` (`source_model`,`source_id`,`del_marker`),
    -- AC-CONC-02: by type and by authoriser, for the year.
    INDEX `idx_acc_conc_type_fy` (`concession_type`,`financial_year_id`),
    INDEX `idx_acc_conc_authoriser` (`authorised_by`,`financial_year_id`),
    INDEX `idx_acc_conc_student` (`student_ledger_id`,`financial_year_id`),
    INDEX `idx_acc_conc_bill` (`bill_reference_id`),
    INDEX `idx_acc_conc_voucher` (`voucher_id`),
    INDEX `idx_acc_conc_date` (`concession_date`,`status`),
    CONSTRAINT `chk_acc_conc_amounts` CHECK (
        `gross_amount` >= 0 AND `concession_amount` >= 0 AND
        `concession_amount` <= `gross_amount` AND
        `net_amount` = `gross_amount` - `concession_amount`
    ),
    CONSTRAINT `fk_acc_conc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_ledger` FOREIGN KEY (`student_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_conc_ledger` FOREIGN KEY (`concession_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_bill` FOREIGN KEY (`bill_reference_id`) REFERENCES `acc_bill_references`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_conc_authorised_by` FOREIGN KEY (`authorised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_conc_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_conc_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Explicit concessions. Gross, concession and net are all recorded (BR-CONC-02). Not write-offs.';


-- Donations, with the 80G receipt series (BRD §48).
--
-- BR-DON-02 requires the 80G series to be UNIQUE, GAPLESS and SEQUENTIAL per financial year. Uniqueness
-- is the key below. Gaplessness is not something a schema can assert — a gap is an ABSENCE — so it is
-- checked by the numbering-gap watch (Enhancement E-06) and reported, and the number is allocated under
-- the same row lock as voucher numbers (acc_voucher_number_sequences) rather than by MAX()+1.
CREATE TABLE IF NOT EXISTS `acc_donations` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `receipt_no`            VARCHAR(50) NOT NULL,       -- the 80G receipt number
    `receipt_sequence`      INT UNSIGNED NULL,          -- the numeric part; what the gap watch reads
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `donation_date`         DATE NOT NULL,

    -- BR-DON-03: anonymous donations are identified as such, because they are taxed differently.
    `is_anonymous`          TINYINT(1) NOT NULL DEFAULT 0,
    `donor_ledger_id`       INT UNSIGNED NULL,          -- NULL only when anonymous
    `donor_name`            VARCHAR(200) NULL,
    `donor_pan`             VARCHAR(15) NULL,
    `donor_address`         VARCHAR(500) NULL,
    `donor_email`           VARCHAR(150) NULL,
    `donor_phone`           VARCHAR(30) NULL,

    -- BR-DON-01: corpus or general. A corpus receipt is never income of the period (BR-FUND-05).
    `donation_nature`       ENUM('Corpus','General','Restricted') NOT NULL DEFAULT 'General',
    `fund_id`               INT UNSIGNED NULL,
    `purpose`               VARCHAR(500) NULL,
    `amount`                DECIMAL(15,2) NOT NULL,
    `mode`                  ENUM('Cash','Cheque','DD','NEFT','RTGS','UPI','Card','In_Kind','Other') NOT NULL,
    `instrument_no`         VARCHAR(50) NULL,

    -- BR-DON-04: donations in kind are recorded at valuation, WITH the basis of valuation.
    `is_in_kind`            TINYINT(1) NOT NULL DEFAULT 0,
    `in_kind_description`   VARCHAR(500) NULL,
    `valuation_basis`       VARCHAR(500) NULL,
    `valued_by`             VARCHAR(200) NULL,

    `is_80g_eligible`       TINYINT(1) NOT NULL DEFAULT 1,
    `certificate_issued_at` DATETIME NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,       -- AC-DON-01: every receipt traces to a posted voucher
    `status`                ENUM('Draft','Posted','Cancelled') NOT NULL DEFAULT 'Draft',
    `cancelled_reason`      VARCHAR(500) NULL,
    `remarks`               VARCHAR(1000) NULL,
    `created_by`            INT UNSIGNED NULL,
    `updated_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    -- A cancelled receipt KEEPS its number. Reusing it would create the gap it was meant to prevent.
    UNIQUE KEY `uq_acc_don_receipt` (`financial_year_id`,`receipt_no`),
    UNIQUE KEY `uq_acc_don_sequence` (`financial_year_id`,`receipt_sequence`),
    INDEX `idx_acc_don_donor` (`donor_ledger_id`,`financial_year_id`),
    INDEX `idx_acc_don_date` (`donation_date`,`status`),
    INDEX `idx_acc_don_nature` (`donation_nature`,`financial_year_id`),
    INDEX `idx_acc_don_fund` (`fund_id`),
    INDEX `idx_acc_don_voucher` (`voucher_id`),
    INDEX `idx_acc_don_pan` (`donor_pan`),
    INDEX `idx_acc_don_80g` (`is_80g_eligible`,`financial_year_id`),
    CONSTRAINT `chk_acc_don_amount` CHECK (`amount` > 0),
    CONSTRAINT `chk_acc_don_donor` CHECK (`is_anonymous` = 1 OR `donor_ledger_id` IS NOT NULL OR `donor_name` IS NOT NULL),
    CONSTRAINT `chk_acc_don_in_kind` CHECK (`is_in_kind` = 0 OR `valuation_basis` IS NOT NULL),
    CONSTRAINT `fk_acc_don_donor` FOREIGN KEY (`donor_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_don_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_don_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_don_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_don_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_don_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_don_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_don_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Donations and the 80G receipt series. A cancelled receipt keeps its number (BR-DON-02).';


-- Grants (BRD §49). A grant is a fund with conditions and a deadline attached.
--
-- Utilisation is NOT a column here. It is derived from acc_voucher_item_funds against the grant's fund_id,
-- via acc_fund_balances — the same path, and the same rebuild guarantee, as every other fund. That is what
-- makes the utilisation certificate (BR-GRANT-05, Enhancement E-10) a query over posted vouchers rather
-- than a manually maintained number that has to be believed.
CREATE TABLE IF NOT EXISTS `acc_grants` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `grant_code`                VARCHAR(30) NOT NULL,
    `name`                      VARCHAR(200) NOT NULL,
    `grantor_ledger_id`         INT UNSIGNED NULL,
    `grantor_name`              VARCHAR(200) NOT NULL,
    `grantor_type`              ENUM('Government','CSR','Trust','Foundation','Individual','International','Other')
                                NOT NULL DEFAULT 'Other',
    -- The fund this grant's money lives in. Everything about utilisation flows through it.
    `fund_id`                   INT UNSIGNED NOT NULL,

    `sanction_reference`        VARCHAR(100) NULL,
    `sanction_date`             DATE NULL,
    `sanctioned_amount`         DECIMAL(15,2) NOT NULL,
    -- BR-GRANT-02: a grant receivable is recognised on sanction where the policy is accrual.
    `recognition_basis`         ENUM('On_Sanction','On_Receipt') NOT NULL DEFAULT 'On_Receipt',
    `receivable_voucher_id`     BIGINT UNSIGNED NULL,

    `purpose`                   VARCHAR(1000) NULL,
    `conditions`                TEXT NULL,
    `utilisation_from`          DATE NULL,
    `utilisation_to`            DATE NULL,
    -- BR-GRANT-04: unutilised grant at period end is a LIABILITY, not income. This names the head.
    `unutilised_liability_ledger_id` INT UNSIGNED NULL,
    `refundable_if_unutilised`  TINYINT(1) NOT NULL DEFAULT 1,

    `utilisation_cert_due_on`   DATE NULL,
    `utilisation_cert_filed_on` DATE NULL,
    `utilisation_cert_media_id` INT UNSIGNED NULL,

    `campus_id`                 SMALLINT UNSIGNED NULL,
    `cost_center_id`            INT UNSIGNED NULL,
    `status`                    ENUM('Sanctioned','Active','Fully_Utilised','Closed','Cancelled','Lapsed')
                                NOT NULL DEFAULT 'Sanctioned',
    `notes`                     VARCHAR(1000) NULL,
    `created_by`                INT UNSIGNED NULL,
    `updated_by`                INT UNSIGNED NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    `del_marker`                BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_grant_code` (`grant_code`,`del_marker`),
    INDEX `idx_acc_grant_fund` (`fund_id`),
    INDEX `idx_acc_grant_grantor` (`grantor_ledger_id`),
    INDEX `idx_acc_grant_status` (`status`,`utilisation_to`),
    INDEX `idx_acc_grant_cert_due` (`utilisation_cert_due_on`,`utilisation_cert_filed_on`),
    INDEX `idx_acc_grant_campus` (`campus_id`),
    CONSTRAINT `chk_acc_grant_amount` CHECK (`sanctioned_amount` >= 0),
    CONSTRAINT `chk_acc_grant_period` CHECK (`utilisation_to` IS NULL OR `utilisation_from` IS NULL OR `utilisation_to` >= `utilisation_from`),
    CONSTRAINT `fk_acc_grant_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_grant_grantor` FOREIGN KEY (`grantor_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_grant_liab_ledger` FOREIGN KEY (`unutilised_liability_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_grant_voucher` FOREIGN KEY (`receivable_voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_grant_media` FOREIGN KEY (`utilisation_cert_media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_grant_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_grant_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_grant_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_grant_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Grants. Utilisation is derived through the grant fund, never stored here (AC-GRANT-01).';


-- =========================================================================================================
-- SECTION 15: TDS — CERTIFICATES, DEDUCTIONS, CHALLANS
--
--     BRD §46. The rate is resolved from acc_tax_rules (Section 5) at posting; this section records what
--     was actually deducted, from whom, under which section, and which challan paid it over.
--
--     BR-TDS-06 asks for deduction-to-challan reconciliation. That is a many-to-many — one challan pays
--     many deductions, and a deduction can in principle be split across challans — so it needs the
--     allocation table below, exactly as bill-wise settlement did in Section 7.
--
--     The resolution sequence (Solution_Design_v1 §9.3):
--         1  Is the ledger TDS-applicable, and under which section?
--         2  Does the payee hold a valid lower/nil certificate covering this date and amount?
--         3  Has the annual threshold for this payee and section been crossed?
--         4  Rate = certificate rate, else section rate, else the higher rate for a missing PAN
--         5  Lines: Dr Expense (gross) · Cr Party (net) · Cr TDS Payable (tds)
-- =========================================================================================================

-- A lower- or nil-deduction certificate under s.197. Its LIMIT is consumed as it is used, which is why
-- consumed_amount is here: a certificate for 10 lakh at 1% stops applying at 10 lakh, and nothing else
-- in the system knows that.
CREATE TABLE IF NOT EXISTS `acc_tds_certificates` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `party_ledger_id`       INT UNSIGNED NOT NULL,
    `certificate_no`        VARCHAR(50) NOT NULL,
    `certificate_type`      ENUM('Lower_Deduction','Nil_Deduction','Self_Declaration_15G','Self_Declaration_15H')
                            NOT NULL DEFAULT 'Lower_Deduction',
    `section_code`          VARCHAR(20) NOT NULL,       -- '194C', '194J', '194I'
    `pan`                   VARCHAR(15) NULL,
    `certified_rate`        DECIMAL(9,4) NOT NULL DEFAULT 0.0000,
    `valid_from`            DATE NOT NULL,
    `valid_to`              DATE NOT NULL,
    `limit_amount`          DECIMAL(15,2) NULL,         -- NULL = no ceiling
    `consumed_amount`       DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `media_id`              INT UNSIGNED NULL,          -- the certificate itself
    `status`                ENUM('Active','Exhausted','Expired','Revoked') NOT NULL DEFAULT 'Active',
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tdscert` (`party_ledger_id`,`certificate_no`,`section_code`,`del_marker`),
    -- The lookup at posting time: this party, this section, valid on this date.
    INDEX `idx_acc_tdscert_lookup` (`party_ledger_id`,`section_code`,`valid_from`,`valid_to`,`status`),
    INDEX `idx_acc_tdscert_pan` (`pan`),
    CONSTRAINT `chk_acc_tdscert_dates` CHECK (`valid_to` >= `valid_from`),
    CONSTRAINT `chk_acc_tdscert_consumed` CHECK (`consumed_amount` >= 0 AND (`limit_amount` IS NULL OR `consumed_amount` <= `limit_amount`)),
    CONSTRAINT `fk_acc_tdscert_party` FOREIGN KEY (`party_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdscert_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_tdscert_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One deduction, against one voucher line. Everything needed for Form 26Q is a column here, because a
-- return assembled from a report that was assembled from a ledger is a return nobody can check.
CREATE TABLE IF NOT EXISTS `acc_tds_deductions` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`                BIGINT UNSIGNED NOT NULL,
    `voucher_item_id`           BIGINT UNSIGNED NOT NULL,   -- the party line the deduction was made from
    `party_ledger_id`           INT UNSIGNED NOT NULL,
    `financial_year_id`         SMALLINT UNSIGNED NOT NULL,
    `period_id`                 SMALLINT UNSIGNED NULL,
    `quarter`                   TINYINT UNSIGNED NOT NULL,  -- 1..4, for 26Q
    `deduction_date`            DATE NOT NULL,

    `section_code`              VARCHAR(20) NOT NULL,
    `nature_of_payment`         VARCHAR(150) NULL,
    `tax_rule_id`               SMALLINT UNSIGNED NULL,
    `tds_certificate_id`        BIGINT UNSIGNED NULL,       -- when a lower/nil certificate applied
    `pan`                       VARCHAR(15) NULL,
    -- BR-TDS: no PAN means the higher rate, and the return must show why.
    `is_higher_rate_no_pan`     TINYINT(1) NOT NULL DEFAULT 0,

    `gross_amount`              DECIMAL(15,2) NOT NULL,
    `taxable_amount`            DECIMAL(15,2) NOT NULL,
    `rate_applied`              DECIMAL(9,4) NOT NULL,
    `tds_amount`                DECIMAL(15,2) NOT NULL,
    `net_paid_amount`           DECIMAL(15,2) NOT NULL,
    -- The running total that decided whether the threshold was crossed. Stored so the decision is
    -- explainable months later, when the running total has moved on.
    `cumulative_at_deduction`   DECIMAL(15,2) NULL,
    `deduct_on`                 ENUM('Credit','Payment') NOT NULL DEFAULT 'Credit',

    `tds_ledger_id`             INT UNSIGNED NULL,          -- the TDS Payable head it credited
    `status`                    ENUM('Deducted','Partly_Paid','Paid','Reversed') NOT NULL DEFAULT 'Deducted',
    `paid_amount`               DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `certificate_issued_no`     VARCHAR(50) NULL,           -- Form 16A number issued to the payee
    `certificate_issued_at`     DATETIME NULL,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    -- One deduction per line per section. A voucher line cannot be deducted from twice under 194C.
    UNIQUE KEY `uq_acc_tdsded` (`voucher_item_id`,`section_code`),
    -- BR-TDS-06 and the threshold check: this payee, this section, this year.
    INDEX `idx_acc_tdsded_party_section` (`party_ledger_id`,`section_code`,`financial_year_id`),
    INDEX `idx_acc_tdsded_quarter` (`financial_year_id`,`quarter`,`section_code`),
    INDEX `idx_acc_tdsded_status` (`status`,`deduction_date`),
    INDEX `idx_acc_tdsded_voucher` (`voucher_id`),
    INDEX `idx_acc_tdsded_cert` (`tds_certificate_id`),
    INDEX `idx_acc_tdsded_pan` (`pan`),
    CONSTRAINT `chk_acc_tdsded_quarter` CHECK (`quarter` BETWEEN 1 AND 4),
    CONSTRAINT `chk_acc_tdsded_amounts` CHECK (
        `gross_amount` >= 0 AND `taxable_amount` >= 0 AND `tds_amount` >= 0 AND
        `paid_amount` >= 0 AND `paid_amount` <= `tds_amount`
    ),
    CONSTRAINT `fk_acc_tdsded_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_tdsded_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_tdsded_party` FOREIGN KEY (`party_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdsded_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdsded_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdsded_rule` FOREIGN KEY (`tax_rule_id`) REFERENCES `acc_tax_rules`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdsded_cert` FOREIGN KEY (`tds_certificate_id`) REFERENCES `acc_tds_certificates`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdsded_ledger` FOREIGN KEY (`tds_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='One TDS deduction per voucher line per section, with every input to the computation.';


-- The challan. What was actually paid over to the government, and when.
CREATE TABLE IF NOT EXISTS `acc_tds_payments` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `quarter`               TINYINT UNSIGNED NOT NULL,
    `section_code`          VARCHAR(20) NULL,           -- NULL = a challan covering several sections
    `challan_no`            VARCHAR(50) NOT NULL,       -- CIN
    `bsr_code`              VARCHAR(20) NULL,
    `challan_date`          DATE NOT NULL,
    `deposit_date`          DATE NOT NULL,
    `tax_amount`            DECIMAL(15,2) NOT NULL,
    `surcharge`             DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `cess`                  DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `interest`              DECIMAL(15,2) NOT NULL DEFAULT 0.00,   -- late deposit
    `late_fee`              DECIMAL(15,2) NOT NULL DEFAULT 0.00,   -- s.234E
    `total_amount`          DECIMAL(15,2) NOT NULL,
    -- DERIVED from acc_tds_payment_allocations; kept so an unallocated challan is an index scan.
    `allocated_amount`      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `bank_ledger_id`        INT UNSIGNED NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,       -- the payment voucher
    `return_filed_on`       DATE NULL,
    `return_acknowledgement` VARCHAR(50) NULL,
    `media_id`              INT UNSIGNED NULL,          -- the challan receipt
    `status`                ENUM('Draft','Paid','Allocated','Filed','Cancelled') NOT NULL DEFAULT 'Draft',
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tdspay_challan` (`challan_no`,`challan_date`,`del_marker`),
    INDEX `idx_acc_tdspay_fy_quarter` (`financial_year_id`,`quarter`,`status`),
    INDEX `idx_acc_tdspay_voucher` (`voucher_id`),
    INDEX `idx_acc_tdspay_deposit` (`deposit_date`),
    CONSTRAINT `chk_acc_tdspay_quarter` CHECK (`quarter` BETWEEN 1 AND 4),
    CONSTRAINT `chk_acc_tdspay_amounts` CHECK (`total_amount` >= 0 AND `allocated_amount` >= 0 AND `allocated_amount` <= `total_amount`),
    CONSTRAINT `fk_acc_tdspay_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdspay_bank` FOREIGN KEY (`bank_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdspay_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_tdspay_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_tdspay_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Which challan paid which deduction. BR-TDS-06 becomes a join instead of a spreadsheet.
CREATE TABLE IF NOT EXISTS `acc_tds_payment_allocations` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tds_payment_id`        BIGINT UNSIGNED NOT NULL,
    `tds_deduction_id`      BIGINT UNSIGNED NOT NULL,
    `amount`                DECIMAL(15,2) NOT NULL,
    `allocated_by`          INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tdsalloc` (`tds_payment_id`,`tds_deduction_id`),
    INDEX `idx_acc_tdsalloc_deduction` (`tds_deduction_id`),
    CONSTRAINT `chk_acc_tdsalloc_amount` CHECK (`amount` > 0),
    CONSTRAINT `fk_acc_tdsalloc_payment` FOREIGN KEY (`tds_payment_id`) REFERENCES `acc_tds_payments`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_tdsalloc_deduction` FOREIGN KEY (`tds_deduction_id`) REFERENCES `acc_tds_deductions`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_tdsalloc_by` FOREIGN KEY (`allocated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 16: CROSS-MODULE INTEGRATION
--
--     THE CONTRACT (Solution_Design_v1 §10.1): other modules NEVER write accounting tables. They emit
--     events. The engine converts them into vouchers, or reports that it did not.
--
--         Module event ──► acc_event_processing_log (Pending)
--                                │
--                     resolve acc_module_events → acc_event_voucher_configs
--                                │                        │
--                          not configured?           configured
--                                ▼                        ▼
--                            Skipped                 build lines from
--                          (reported)          acc_event_voucher_line_templates
--                                                         │
--                                                    PostingService::post()
--                                                         │
--                              Processed  ·  Failed (retry ≤ N, then escalate)  ·  Skipped
--
--     IDEMPOTENCY (BR-INT-02). v4.3's log explicitly had no uniqueness, on the reasoning that "the same
--     source record can legitimately fire the same event multiple times". That is true, and it is also
--     why replaying a day of events silently double-posted the whole day. Both are satisfied by
--     source_event_uid: the source names WHICH firing this is, so a genuine second firing carries a new
--     uid and posts, and a replay carries the old uid and does not.
--
--     NOTHING IS DROPPED (BR-INT-04). An event with no configuration is Skipped and REPORTED with its age
--     and count — never discarded, and never guessed at.
-- =========================================================================================================

-- Which accounting ledger a module's entity maps to. 'Library fine income' -> ledger 412, and so on.
CREATE TABLE IF NOT EXISTS `acc_ledger_mappings` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`         INT UNSIGNED NOT NULL,
    `module_key`        VARCHAR(10) NOT NULL,       -- glb_app_modules.key. v4.3 hard-coded an ENUM of
                                                    -- seven modules here, so an eighth module needed a
                                                    -- schema change.
    `source_type`       VARCHAR(100) NULL,          -- 'FeeHead', 'PayHead', 'Route', 'Stoppage'
    `source_id`         BIGINT UNSIGNED NULL,       -- NULL = a default for the whole source_type
    `campus_id`         SMALLINT UNSIGNED NULL,
    `description`       VARCHAR(255) NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        INT UNSIGNED NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    `source_type_marker` VARCHAR(100) GENERATED ALWAYS AS (IFNULL(`source_type`,'')) STORED,
    `source_id_marker`  BIGINT UNSIGNED   GENERATED ALWAYS AS (IFNULL(`source_id`,0)) STORED,
    `campus_marker`     SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_lm_combo` (`module_key`,`source_type_marker`,`source_id_marker`,`campus_marker`,`del_marker`),
    INDEX `idx_acc_lm_source` (`module_key`,`source_type`,`source_id`),
    INDEX `idx_acc_lm_ledger` (`ledger_id`,`is_active`),
    CONSTRAINT `fk_acc_lm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_lm_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_lm_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- The registry of business events that can produce a voucher. Adding a module needs a row, not a release.
CREATE TABLE IF NOT EXISTS `acc_module_events` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_key`        VARCHAR(10) NOT NULL,       -- glb_app_modules.key: 'FEE','LIB','TPT','HST','PAY'
    `event_code`        VARCHAR(60) NOT NULL,       -- 'LIB_LATE_RETURN_FINE', 'FEE_DEMAND_RAISED'
    `event_name`        VARCHAR(150) NOT NULL,
    `description`       TEXT NULL,
    `source_model`      VARCHAR(100) NOT NULL,      -- the table that owns the triggering record
    `is_system`         TINYINT(1) NOT NULL DEFAULT 1,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_me_code` (`module_key`,`event_code`,`del_marker`),
    INDEX `idx_acc_me_module` (`module_key`,`is_active`),
    INDEX `idx_acc_me_source_model` (`source_model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registry of cross-module events that may produce a voucher.';


-- HOW an event becomes a voucher. Opt-in: an unconfigured event creates nothing, and says so.
CREATE TABLE IF NOT EXISTS `acc_event_voucher_configs` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_event_id`       BIGINT UNSIGNED NOT NULL,
    `voucher_type_id`       SMALLINT UNSIGNED NOT NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `cost_center_id`        INT UNSIGNED NULL,
    `fund_id`               INT UNSIGNED NULL,
    -- The two flags and what they mean together:
    --     auto_post 1, requires_approval 0  -> posted immediately
    --     auto_post 1, requires_approval 1  -> Pending_Approval; posts on approval
    --     auto_post 0, any                  -> Draft
    -- requires_approval always wins over auto_post. A machine does not approve its own work.
    `is_auto_post`          TINYINT(1) NOT NULL DEFAULT 0,
    `requires_approval`     TINYINT(1) NOT NULL DEFAULT 0,
    `narration_template`    VARCHAR(500) NULL,      -- {student_name} {amount} {date} {reference_no}
    `max_amount`            DECIMAL(15,2) NULL,     -- above this, never auto-post whatever the flags say
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    `campus_marker`         SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0)) STORED,
    PRIMARY KEY (`id`),
    -- One live config per event per campus. campus_marker makes the school-wide row (campus_id NULL)
    -- singular, which a plain nullable column would not.
    UNIQUE KEY `uq_acc_evc_event` (`module_event_id`,`campus_marker`,`del_marker`),
    INDEX `idx_acc_evc_type` (`voucher_type_id`),
    INDEX `idx_acc_evc_active` (`is_active`,`module_event_id`),
    CONSTRAINT `fk_acc_evc_event` FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_vtype` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_evc_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_evc_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_evc_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- The Dr/Cr lines the event produces.
--
--     ledger_resolver   fixed            -> use ledger_id
--                       student_ledger   -> acc_ledgers WHERE student_id  = source.student_id
--                       vendor_ledger    -> acc_ledgers WHERE vendor_id   = source.vendor_id
--                       employee_ledger  -> acc_ledgers WHERE employee_id = source.employee_id
--                       mapped_ledger    -> acc_ledger_mappings for this module and source_type
--     amount_resolver   from_source      -> read source_amount_field from the source record
--                       fixed_amount     -> use fixed_amount
--                       from_payload     -> read 'amount' from the event payload
--                       balancing        -> whatever makes the voucher balance
--
--     A library fine receipt, for instance:
--         line 1  Dr  student_ledger
--         line 2  Cr  fixed, ledger_id = Library Fine Income
CREATE TABLE IF NOT EXISTS `acc_event_voucher_line_templates` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_voucher_config_id`   BIGINT UNSIGNED NOT NULL,
    `sequence_no`               SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `entry_type`                ENUM('Dr','Cr') NOT NULL,
    `ledger_resolver`           ENUM('fixed','student_ledger','vendor_ledger','employee_ledger','mapped_ledger')
                                NOT NULL DEFAULT 'fixed',
    `ledger_id`                 INT UNSIGNED NULL,          -- required when ledger_resolver = 'fixed'
    `ledger_mapping_type`       VARCHAR(100) NULL,          -- the source_type for 'mapped_ledger'
    `amount_resolver`           ENUM('from_source','fixed_amount','from_payload','balancing')
                                NOT NULL DEFAULT 'from_source',
    `source_amount_field`       VARCHAR(100) NULL,
    `fixed_amount`              DECIMAL(15,2) NULL,
    `cost_center_id`            INT UNSIGNED NULL,
    `fund_id`                   INT UNSIGNED NULL,
    -- Where the line should create or settle a bill reference (a fee demand, a vendor bill).
    `bill_action`               ENUM('None','New_Reference','Against_Reference','Advance','On_Account')
                                NOT NULL DEFAULT 'None',
    `narration`                 VARCHAR(500) NULL,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_evlt_sequence` (`event_voucher_config_id`,`sequence_no`),
    INDEX `idx_acc_evlt_config` (`event_voucher_config_id`,`is_active`),
    INDEX `idx_acc_evlt_ledger` (`ledger_id`),
    CONSTRAINT `chk_acc_evlt_fixed_ledger` CHECK (`ledger_resolver` <> 'fixed' OR `ledger_id` IS NOT NULL),
    CONSTRAINT `chk_acc_evlt_fixed_amount` CHECK (`amount_resolver` <> 'fixed_amount' OR `fixed_amount` IS NOT NULL),
    CONSTRAINT `chk_acc_evlt_from_source` CHECK (`amount_resolver` <> 'from_source' OR `source_amount_field` IS NOT NULL),
    CONSTRAINT `fk_acc_evlt_config` FOREIGN KEY (`event_voucher_config_id`) REFERENCES `acc_event_voucher_configs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_evlt_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evlt_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_evlt_fund` FOREIGN KEY (`fund_id`) REFERENCES `acc_funds`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Every event the engine received, and what became of it.
CREATE TABLE IF NOT EXISTS `acc_event_processing_log` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_event_id`       BIGINT UNSIGNED NOT NULL,
    `module_key`            VARCHAR(10) NOT NULL,
    `source_model`          VARCHAR(100) NOT NULL,
    `source_id`             BIGINT UNSIGNED NOT NULL,
    -- The idempotency key the SOURCE supplies. See the section header: this is what distinguishes a
    -- genuine second firing from a replay of the first.
    `source_event_uid`      VARCHAR(100) NOT NULL,
    -- A snapshot of the source record as it stood. If the source row later changes, the audit still shows
    -- what the voucher was actually built from.
    `payload_json`          JSON NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,
    `status`                ENUM('Pending','Processing','Processed','Failed','Skipped','Escalated')
                            NOT NULL DEFAULT 'Pending',
    `skip_reason`           ENUM('No_Config','Inactive_Event','Duplicate','Zero_Amount','Period_Closed','Other') NULL,
    `error_message`         TEXT NULL,
    `retry_count`           TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `next_retry_at`         DATETIME NULL,
    `escalated_at`          DATETIME NULL,
    `escalated_to`          INT UNSIGNED NULL,
    `received_at`           DATETIME NOT NULL,
    `processed_at`          DATETIME NULL,
    `created_by`            INT UNSIGNED NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- BR-INT-02. Replaying a day of events produces nothing new.
    UNIQUE KEY `uq_acc_epl_idempotency` (`module_event_id`,`source_model`,`source_id`,`source_event_uid`),
    -- The worker's queue: what is pending or due for retry?
    INDEX `idx_acc_epl_queue` (`status`,`next_retry_at`,`retry_count`),
    INDEX `idx_acc_epl_source` (`source_model`,`source_id`),
    INDEX `idx_acc_epl_event` (`module_event_id`,`status`),
    INDEX `idx_acc_epl_voucher` (`voucher_id`),
    -- BR-INT-04: unconfigured events are reported with count and AGE.
    INDEX `idx_acc_epl_skipped` (`skip_reason`,`received_at`),
    INDEX `idx_acc_epl_module` (`module_key`,`status`,`received_at`),
    CONSTRAINT `fk_acc_epl_event` FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_epl_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_epl_escalated_to` FOREIGN KEY (`escalated_to`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_epl_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Every cross-module event and its outcome. Nothing is dropped (BR-INT-04).';


-- THE CONTROL THAT CATCHES EVERYTHING ELSE (Solution_Design_v1 §10.3).
--
-- If the Fees module says Rs 42,00,000 was collected in August and Accounting says Rs 41,85,000, the
-- difference is itemised to the receipt THAT NIGHT — not at audit. Run nightly per module per period.
CREATE TABLE IF NOT EXISTS `acc_module_reconciliation` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_key`            VARCHAR(10) NOT NULL,
    `financial_year_id`     SMALLINT UNSIGNED NOT NULL,
    `period_id`             SMALLINT UNSIGNED NOT NULL,
    `reconciliation_date`   DATE NOT NULL,
    `metric`                VARCHAR(60) NOT NULL,       -- 'FEE_COLLECTED', 'FEE_DEMAND', 'PAYROLL_COST'
    `source_total`          DECIMAL(18,2) NOT NULL DEFAULT 0.00,    -- what the module says
    `posted_total`          DECIMAL(18,2) NOT NULL DEFAULT 0.00,    -- what Accounting says
    `difference`            DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `source_count`          INT UNSIGNED NOT NULL DEFAULT 0,
    `posted_count`          INT UNSIGNED NOT NULL DEFAULT 0,
    `unposted_count`        INT UNSIGNED NOT NULL DEFAULT 0,
    `failed_count`          INT UNSIGNED NOT NULL DEFAULT 0,
    -- The itemisation. JSON, because the shape differs per module, and because a difference that cannot
    -- name its records is not a finding, it is a rumour.
    `difference_detail`     JSON NULL,
    `status`                ENUM('Matched','Difference','Investigating','Explained','Failed') NOT NULL DEFAULT 'Matched',
    `explanation`           VARCHAR(1000) NULL,
    `reviewed_by`           INT UNSIGNED NULL,
    `reviewed_at`           DATETIME NULL,
    `run_at`                DATETIME NOT NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_modrec` (`module_key`,`period_id`,`metric`,`reconciliation_date`),
    INDEX `idx_acc_modrec_status` (`status`,`reconciliation_date`),
    INDEX `idx_acc_modrec_period` (`period_id`,`module_key`),
    INDEX `idx_acc_modrec_fy` (`financial_year_id`,`module_key`),
    CONSTRAINT `fk_acc_modrec_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_modrec_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_modrec_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Nightly module-to-Accounting reconciliation. The control that catches everything else.';


-- =========================================================================================================
-- SECTION 17: TALLY EXPORT
--     Export only, masters and vouchers, XML (Solution_Design_v1 OD-15). Phase 4.
-- =========================================================================================================

CREATE TABLE IF NOT EXISTS `acc_tally_export_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `export_type`       ENUM('Ledgers','Groups','Vouchers','Cost_Centres','All') NOT NULL,
    `export_format`     ENUM('XML','CSV','Excel') NOT NULL DEFAULT 'XML',
    `financial_year_id` SMALLINT UNSIGNED NULL,
    `start_date`        DATE NULL,
    `end_date`          DATE NULL,
    `file_name`         VARCHAR(255) NOT NULL,
    `media_id`          INT UNSIGNED NULL,
    `record_count`      INT UNSIGNED NULL,
    `status`            ENUM('Queued','Running','Completed','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
    `error_log`         TEXT NULL,
    `exported_by`       INT UNSIGNED NULL,
    `started_at`        DATETIME NULL,
    `completed_at`      DATETIME NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_tel_type_status` (`export_type`,`status`),
    INDEX `idx_acc_tel_date` (`created_at`),
    INDEX `idx_acc_tel_by` (`exported_by`),
    CONSTRAINT `fk_acc_tel_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_tel_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_tel_by` FOREIGN KEY (`exported_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `acc_tally_ledger_mappings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`         INT UNSIGNED NOT NULL,
    `tally_ledger_name` VARCHAR(200) NOT NULL,
    `tally_group_name`  VARCHAR(200) NULL,
    `tally_alias`       VARCHAR(200) NULL,
    `mapping_type`      ENUM('Auto','Manual') NOT NULL DEFAULT 'Auto',
    `sync_direction`    ENUM('Export_Only','Import_Only','Bidirectional') NOT NULL DEFAULT 'Export_Only',
    `last_synced_at`    DATETIME NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    `del_marker`        BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tlm_ledger` (`ledger_id`,`del_marker`),
    -- Tally identifies a ledger by NAME. Two of ours mapping to one of theirs would merge two accounts.
    UNIQUE KEY `uq_acc_tlm_tally_name` (`tally_ledger_name`,`del_marker`),
    CONSTRAINT `fk_acc_tlm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 18: CONTROL — AUDIT, EXCEPTIONS, ASSERTIONS, SETTINGS
--
--     v4.3 had NO audit table. BRD §30 states six rules of audit trail, and without a table not one of
--     them was implementable — which means the module, as designed in v4.3, could not be audited at all.
-- =========================================================================================================

-- APPEND-ONLY. There is no UPDATE path and no DELETE path to this table anywhere in the application, and
-- BR-AUD-03 / AC-AUD-02 require that no role, including Super Admin, can reach one.
--
-- A schema cannot enforce that on its own; MySQL has no append-only table type. It is enforced by GRANT:
-- the application's database user holds INSERT and SELECT on acc_audit_logs and NOT UPDATE or DELETE.
-- Run this once per tenant, as the DBA — it is the other half of this table's design:
--
--     REVOKE UPDATE, DELETE ON <tenant_db>.acc_audit_logs FROM '<app_user>'@'%';
--     GRANT  INSERT, SELECT  ON <tenant_db>.acc_audit_logs TO   '<app_user>'@'%';
--
-- BR-AUD-04 — a person is distinguishable from a system process — is the actor_type column. It is not
-- inferable from a NULL user_id, because a NULL user_id also means "the user was deleted".
CREATE TABLE IF NOT EXISTS `acc_audit_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `entity_type`       VARCHAR(64) NOT NULL,       -- table name: 'acc_vouchers', 'acc_ledgers'
    `entity_id`         BIGINT UNSIGNED NOT NULL,
    -- The voucher this event concerns, whatever the entity was. Lets AC-AUD-01 — the full history of a
    -- voucher, including its allocations, approvals and attachments — be ONE indexed query.
    `voucher_id`        BIGINT UNSIGNED NULL,
    `action`            ENUM('Created','Updated','Deleted','Restored','Submitted','Approved','Rejected',
                             'Posted','Cancelled','Reversed','Reconciled','Unreconciled','Closed',
                             'Reopened','Allocated','Deallocated','Written_Off','Exported','Imported',
                             'Viewed_Sensitive','Permission_Overridden','Rebuilt') NOT NULL,
    -- BR-AUD-01: before-value and after-value. JSON of the changed attributes only, not the whole row —
    -- a full-row snapshot of every update would dominate the tenant's storage within a year.
    `old_values`        JSON NULL,
    `new_values`        JSON NULL,
    `changed_fields`    VARCHAR(1000) NULL,         -- CSV, for filtering without parsing the JSON
    `reason`            VARCHAR(1000) NULL,         -- required for cancel, reverse, reopen, waive, override

    `actor_type`        ENUM('User','System','Job','Integration','Migration') NOT NULL DEFAULT 'User',
    `user_id`           INT UNSIGNED NULL,
    `user_name`         VARCHAR(150) NULL,          -- denormalised: the audit must read correctly even
                                                    -- after the user record is gone
    `impersonated_by`   INT UNSIGNED NULL,
    `ip_address`        VARCHAR(45) NULL,           -- 45 = IPv6
    `user_agent`        VARCHAR(255) NULL,
    `request_id`        VARCHAR(64) NULL,           -- correlates every row written by one request
    `module_key`        VARCHAR(10) NULL,
    `financial_year_id` SMALLINT UNSIGNED NULL,
    `period_id`         SMALLINT UNSIGNED NULL,
    `occurred_at`       DATETIME(3) NOT NULL,       -- millisecond precision: ordering within a transaction
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    -- BR-AUD-06: the complete history of any record, in one action.
    INDEX `idx_acc_audit_entity` (`entity_type`,`entity_id`,`occurred_at`),
    INDEX `idx_acc_audit_voucher` (`voucher_id`,`occurred_at`),
    INDEX `idx_acc_audit_user` (`user_id`,`occurred_at`),
    INDEX `idx_acc_audit_action` (`action`,`occurred_at`),
    INDEX `idx_acc_audit_when` (`occurred_at`),
    INDEX `idx_acc_audit_request` (`request_id`),
    INDEX `idx_acc_audit_period` (`period_id`,`occurred_at`),
    -- No foreign key to sys_users. BR-AUD-05 retains audit for at least eight years, and a foreign key
    -- would make deleting a long-departed user either impossible or destructive of the audit trail.
    -- user_id is a plain indexed column; user_name carries the readable identity.
    CONSTRAINT `fk_acc_audit_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='APPEND-ONLY audit trail. The app DB user must hold no UPDATE or DELETE grant here (BR-AUD-03).';


-- What the exception rules ARE. Thresholds are configuration, per BR-EXC-01, so tuning one is a data
-- change rather than a release.
CREATE TABLE IF NOT EXISTS `acc_exception_rules` (
    `id`                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(50) NOT NULL,   -- 'NEGATIVE_CASH', 'AGED_SUSPENSE', 'STALE_CHEQUE'
    `name`                  VARCHAR(200) NOT NULL,
    `category`              ENUM('Balance','Ageing','Reconciliation','Approval','Compliance','Data_Quality',
                                 'Fraud_Risk','Budget','Numbering') NOT NULL,
    `severity`              ENUM('Info','Warning','High','Critical') NOT NULL DEFAULT 'Warning',
    `checker_key`           VARCHAR(100) NOT NULL,  -- the ExceptionService check that produces it
    `threshold_amount`      DECIMAL(15,2) NULL,
    `threshold_days`        SMALLINT UNSIGNED NULL,
    `threshold_percent`     DECIMAL(9,4) NULL,
    -- BR-EXC-04: a blocking exception prevents period close.
    `blocks_period_close`   TINYINT(1) NOT NULL DEFAULT 0,
    `allow_acknowledge`     TINYINT(1) NOT NULL DEFAULT 1,
    `acknowledge_valid_days` SMALLINT UNSIGNED NULL, -- BR-EXC-03: an acknowledgement EXPIRES
    `notify_role_slug`      VARCHAR(60) NULL,
    `run_frequency`         ENUM('Realtime','Hourly','Daily','Weekly','On_Close') NOT NULL DEFAULT 'Daily',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    `del_marker`            BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(UNIX_TIMESTAMP(`deleted_at`),0)) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_excrule_code` (`code`,`del_marker`),
    INDEX `idx_acc_excrule_active` (`is_active`,`run_frequency`),
    INDEX `idx_acc_excrule_blocking` (`blocks_period_close`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- One detected exception, NAMING THE RECORD (BR-EXC-02). An exception that reports a count without
-- naming its records cannot be acted on, and will not be.
CREATE TABLE IF NOT EXISTS `acc_exceptions` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exception_rule_id`     SMALLINT UNSIGNED NOT NULL,
    `rule_code`             VARCHAR(50) NOT NULL,   -- denormalised: the dashboard never joins
    `severity`              ENUM('Info','Warning','High','Critical') NOT NULL DEFAULT 'Warning',
    -- The offending record, by type and id. This is the drill-down target.
    `entity_type`           VARCHAR(64) NOT NULL,
    `entity_id`             BIGINT UNSIGNED NOT NULL,
    `entity_label`          VARCHAR(255) NULL,      -- 'PAY-0042', 'Sundry Debtors', 'Ravi Kumar'
    `ledger_id`             INT UNSIGNED NULL,
    `voucher_id`            BIGINT UNSIGNED NULL,
    `financial_year_id`     SMALLINT UNSIGNED NULL,
    `period_id`             SMALLINT UNSIGNED NULL,
    `campus_id`             SMALLINT UNSIGNED NULL,
    `amount`                DECIMAL(18,2) NULL,
    `age_days`              INT NULL,
    `detail`                JSON NULL,
    `message`               VARCHAR(1000) NOT NULL,
    `status`                ENUM('Open','Acknowledged','Resolved','Suppressed','Recurred') NOT NULL DEFAULT 'Open',
    `first_detected_at`     DATETIME NOT NULL,
    `last_detected_at`      DATETIME NOT NULL,
    `detection_count`       INT UNSIGNED NOT NULL DEFAULT 1,
    -- BR-EXC-03: acknowledged with a reason, recorded, and EXPIRING. An acknowledgement that never
    -- expires is a way of never fixing anything.
    `acknowledged_by`       INT UNSIGNED NULL,
    `acknowledged_at`       DATETIME NULL,
    `acknowledge_reason`    VARCHAR(1000) NULL,
    `acknowledge_expires_at` DATETIME NULL,
    `resolved_by`           INT UNSIGNED NULL,
    `resolved_at`           DATETIME NULL,
    `resolution_note`       VARCHAR(1000) NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- One open exception per rule per record. Re-detection increments detection_count and moves
    -- last_detected_at; it does not fill the dashboard with the same finding a hundred times.
    UNIQUE KEY `uq_acc_exc_open` (`exception_rule_id`,`entity_type`,`entity_id`),
    INDEX `idx_acc_exc_status` (`status`,`severity`,`last_detected_at`),
    INDEX `idx_acc_exc_rule` (`rule_code`,`status`),
    INDEX `idx_acc_exc_period` (`period_id`,`status`),
    INDEX `idx_acc_exc_ledger` (`ledger_id`,`status`),
    INDEX `idx_acc_exc_voucher` (`voucher_id`),
    INDEX `idx_acc_exc_ack_expiry` (`acknowledge_expires_at`,`status`),
    CONSTRAINT `chk_acc_exc_ack` CHECK (`status` <> 'Acknowledged' OR (`acknowledged_by` IS NOT NULL AND `acknowledge_reason` IS NOT NULL)),
    CONSTRAINT `fk_acc_exc_rule` FOREIGN KEY (`exception_rule_id`) REFERENCES `acc_exception_rules`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_exc_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_exc_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_exc_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_exc_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_exc_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_exc_ack_by` FOREIGN KEY (`acknowledged_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_exc_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Detected exceptions, each naming its record (BR-EXC-02). Blocking ones refuse period close.';


-- The continuous Trial Balance assertion (BRD Enhancement E-01 — "the highest value-to-effort item in
-- this list"). Every run of every assertion, pass or fail, is a row here.
--
-- The assertions (Solution_Design_v1 §5.5):
--     VOUCHER_BALANCED        every posted voucher: Σ Dr = Σ Cr
--     TRIAL_BALANCE           Σ Dr = Σ Cr for every period
--     LEDGER_BUCKET           bucket closing = Σ lines + opening, per ledger
--     PARTY_BILLWISE          party ledger balance = Σ its open bill outstandings
--     BALANCE_SHEET           the Balance Sheet balances at every period end
--     BILL_OVERALLOCATION     allocated ≤ original, per bill
--     FUND_IDENTITY           opening + additions − utilisation = closing, per fund
--     NUMBER_SERIES           gapless per type per year
--     ASSET_REGISTER          register net block = asset ledger balances
--     REBUILD_IDENTITY        rebuilding acc_ledger_period_balances changes nothing  <- §5.4
--
-- A failure names the offending record and raises an exception. It does not write a log line and move on.
CREATE TABLE IF NOT EXISTS `acc_assertion_results` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `assertion_code`        VARCHAR(50) NOT NULL,
    `assertion_name`        VARCHAR(200) NOT NULL,
    `scope`                 ENUM('Global','Financial_Year','Period','Ledger','Fund','Party','Asset','Voucher')
                            NOT NULL DEFAULT 'Global',
    `financial_year_id`     SMALLINT UNSIGNED NULL,
    `period_id`             SMALLINT UNSIGNED NULL,
    `result`                ENUM('Pass','Fail','Error','Skipped') NOT NULL,
    `checked_count`         INT UNSIGNED NOT NULL DEFAULT 0,
    `failure_count`         INT UNSIGNED NOT NULL DEFAULT 0,
    -- The two figures that should have been equal, and what they actually were.
    `expected_value`        DECIMAL(18,2) NULL,
    `actual_value`          DECIMAL(18,2) NULL,
    `variance`              DECIMAL(18,2) NULL,
    -- The offending records, by name. This is what separates an assertion from an alarm.
    `failure_detail`        JSON NULL,
    `exception_id`          BIGINT UNSIGNED NULL,   -- the exception raised, where it failed
    `duration_ms`           INT UNSIGNED NULL,
    `run_at`                DATETIME NOT NULL,
    `created_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_assert_code_run` (`assertion_code`,`run_at`),
    INDEX `idx_acc_assert_result` (`result`,`run_at`),
    INDEX `idx_acc_assert_period` (`period_id`,`assertion_code`,`run_at`),
    INDEX `idx_acc_assert_fy` (`financial_year_id`,`run_at`),
    CONSTRAINT `fk_acc_assert_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_assert_period` FOREIGN KEY (`period_id`) REFERENCES `acc_accounting_periods`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_assert_exception` FOREIGN KEY (`exception_id`) REFERENCES `acc_exceptions`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Every assertion run, pass or fail. A failure names the record (Enhancement E-01).';


-- Module configuration. The BRD says "configurable" thirty-one times; this is where those settings live,
-- so that a school's rounding tolerance or ageing buckets are a row rather than a deployment.
--
-- Typed, not a bare key/value blob: a tolerance stored as the string '1' and compared numerically is a
-- defect waiting for the first school that enters '1.00'.
CREATE TABLE IF NOT EXISTS `acc_settings` (
    `id`                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `setting_key`       VARCHAR(80) NOT NULL,
    `setting_group`     ENUM('Posting','Numbering','Period','Bill_Wise','Bank','Tax','Fund','Budget',
                             'Approval','Reporting','Integration','Security') NOT NULL,
    `value_type`        ENUM('String','Integer','Decimal','Boolean','Date','Json') NOT NULL,
    `value_string`      VARCHAR(500) NULL,
    `value_integer`     BIGINT NULL,
    `value_decimal`     DECIMAL(18,4) NULL,
    `value_boolean`     TINYINT(1) NULL,
    `value_date`        DATE NULL,
    `value_json`        JSON NULL,
    `default_value`     VARCHAR(500) NULL,
    `description`       VARCHAR(500) NULL,
    -- A setting a school may change, versus one the platform fixes.
    `is_school_editable` TINYINT(1) NOT NULL DEFAULT 1,
    -- Changing this setting requires a second person to confirm (BRD Enhancement E-05).
    `requires_four_eyes` TINYINT(1) NOT NULL DEFAULT 0,
    `campus_id`         SMALLINT UNSIGNED NULL,     -- NULL = applies school-wide
    `updated_by`        INT UNSIGNED NULL,
    `campus_marker`     SMALLINT UNSIGNED GENERATED ALWAYS AS (IFNULL(`campus_id`,0)) STORED,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- campus_marker, not campus_id: the school-wide row must be singular, and re-running the seed
    -- below must insert nothing the second time.
    UNIQUE KEY `uq_acc_setting` (`setting_key`,`campus_marker`),
    INDEX `idx_acc_setting_group` (`setting_group`),
    CONSTRAINT `fk_acc_setting_campus` FOREIGN KEY (`campus_id`) REFERENCES `acc_campuses`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_setting_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================================================
-- SECTION 19: VIEWS
--
--     The twenty-two views of Solution_Design_v1 §12.2.
--
--     Two rules govern every one of them, and they are the reason the views exist at all rather than the
--     same SQL being retyped in twenty controllers:
--
--     1.  STATEMENTS READ BUCKETS, REGISTERS READ LINES. Anything that aggregates — Trial Balance,
--         Balance Sheet, Income & Expenditure, cost centre, fund — reads acc_ledger_period_balances
--         (~240k rows). Anything that lists — Day Book, ledger statement, registers — reads
--         acc_voucher_items (1.5M-6M rows) and is ALWAYS date-filtered by the caller.
--
--     2.  ONLY POSTED COUNTS (BRD R-02). Every view that touches transactions filters
--         voucher_status = 'Posted' and is_provisional = 0. A provisional voucher appears in no financial
--         statement, ever (BR-PROV-01) — v4.3's comment claimed the opposite.
--
--     Closed-period statements are NOT served by these views. They are served from
--     acc_period_closing_balances, so they are reproducible by construction (AC-CLOSE-03).
-- =========================================================================================================

-- Ledger balance for a financial year: opening, movement, closing. The dimension-NULL rows only —
-- summing the dimension slices as well would double count.
CREATE OR REPLACE VIEW `vw_ledger_balances` AS
SELECT
    l.id                                            AS ledger_id,
    l.code                                          AS ledger_code,
    l.name                                          AS ledger_name,
    l.ledger_type,
    l.party_type,
    l.is_bill_wise,
    g.id                                            AS account_group_id,
    g.name                                          AS group_name,
    g.nature,
    g.path                                          AS group_path,
    b.financial_year_id,
    MAX(CASE WHEN p.period_no = 1 THEN b.opening_debit  ELSE 0 END) AS opening_debit,
    MAX(CASE WHEN p.period_no = 1 THEN b.opening_credit ELSE 0 END) AS opening_credit,
    SUM(b.period_debit)                             AS total_debit,
    SUM(b.period_credit)                            AS total_credit,
    SUM(b.transaction_count)                        AS transaction_count,
    -- Closing is the LAST period's closing, not a sum of closings.
    SUM(b.period_debit)  - SUM(b.period_credit)
      + MAX(CASE WHEN p.period_no = 1 THEN b.opening_debit - b.opening_credit ELSE 0 END) AS net_balance,
    MAX(b.last_rebuilt_at)                          AS last_rebuilt_at,
    MAX(b.is_stale)                                 AS is_stale
FROM `acc_ledger_period_balances` b
JOIN `acc_ledgers`          l ON l.id = b.ledger_id
JOIN `acc_account_groups`   g ON g.id = l.account_group_id
JOIN `acc_accounting_periods` p ON p.id = b.period_id
WHERE b.cost_center_id IS NULL AND b.fund_id IS NULL AND b.campus_id IS NULL
GROUP BY l.id, l.code, l.name, l.ledger_type, l.party_type, l.is_bill_wise,
         g.id, g.name, g.nature, g.path, b.financial_year_id;


-- Trial Balance, one row per ledger per period. Σ debit_balance must equal Σ credit_balance — asserted
-- hourly, not hoped for (Solution_Design_v1 §5.5).
CREATE OR REPLACE VIEW `vw_trial_balance` AS
SELECT
    b.financial_year_id,
    b.period_id,
    p.period_no,
    p.name                                          AS period_name,
    p.start_date                                    AS period_start,
    p.end_date                                      AS period_end,
    p.status                                        AS period_status,
    l.id                                            AS ledger_id,
    l.code                                          AS ledger_code,
    l.name                                          AS ledger_name,
    g.id                                            AS account_group_id,
    g.name                                          AS group_name,
    g.nature,
    g.path                                          AS group_path,
    g.affects_gross_profit,
    b.opening_debit,
    b.opening_credit,
    b.period_debit,
    b.period_credit,
    b.closing_debit,
    b.closing_credit,
    -- A ledger shows on one side only. Netting here is what makes Σ Dr = Σ Cr meaningful.
    GREATEST(b.closing_debit  - b.closing_credit, 0) AS debit_balance,
    GREATEST(b.closing_credit - b.closing_debit, 0) AS credit_balance,
    b.transaction_count
FROM `acc_ledger_period_balances` b
JOIN `acc_ledgers`          l ON l.id = b.ledger_id
JOIN `acc_account_groups`   g ON g.id = l.account_group_id
JOIN `acc_accounting_periods` p ON p.id = b.period_id
WHERE b.cost_center_id IS NULL AND b.fund_id IS NULL AND b.campus_id IS NULL
  AND l.deleted_at IS NULL;


-- Balance Sheet: the three permanent natures. Assets on one side, Liabilities and Equity on the other.
CREATE OR REPLACE VIEW `vw_balance_sheet` AS
SELECT
    financial_year_id, period_id, period_no, period_name, period_end,
    nature,
    CASE nature WHEN 'Asset' THEN 'Assets' ELSE 'Liabilities and Funds' END AS bs_side,
    account_group_id, group_name, group_path,
    ledger_id, ledger_code, ledger_name,
    debit_balance, credit_balance,
    -- Assets are naturally debit, Liabilities and Equity naturally credit. Presented positive either way.
    CASE WHEN nature = 'Asset' THEN debit_balance - credit_balance
         ELSE credit_balance - debit_balance END    AS balance_amount
FROM `vw_trial_balance`
WHERE nature IN ('Asset','Liability','Equity');


-- Income & Expenditure — the school's Profit & Loss. Surplus = Income − Expenditure.
CREATE OR REPLACE VIEW `vw_income_expenditure` AS
SELECT
    financial_year_id, period_id, period_no, period_name, period_end,
    nature,
    affects_gross_profit,
    CASE WHEN affects_gross_profit = 1 THEN 'Direct' ELSE 'Indirect' END AS ie_section,
    account_group_id, group_name, group_path,
    ledger_id, ledger_code, ledger_name,
    period_debit, period_credit,
    CASE WHEN nature = 'Income' THEN period_credit - period_debit
         ELSE period_debit - period_credit END      AS amount
FROM `vw_trial_balance`
WHERE nature IN ('Income','Expense');


-- The Day Book: every posted line, in date and voucher order. ALWAYS query this with a date range.
CREATE OR REPLACE VIEW `vw_day_book` AS
SELECT
    vi.id                                           AS voucher_item_id,
    v.id                                            AS voucher_id,
    v.voucher_date,
    v.voucher_display_no,
    v.voucher_number,
    vt.code                                         AS voucher_type_code,
    vt.name                                         AS voucher_type_name,
    vt.school_label,
    v.financial_year_id,
    v.period_id,
    v.campus_id,
    vi.sequence_no,
    vi.ledger_id,
    l.code                                          AS ledger_code,
    l.name                                          AS ledger_name,
    g.nature,
    vi.entry_type,
    CASE WHEN vi.entry_type = 'Dr' THEN vi.amount ELSE 0 END AS debit_amount,
    CASE WHEN vi.entry_type = 'Cr' THEN vi.amount ELSE 0 END AS credit_amount,
    vi.amount,
    v.total_amount                                  AS voucher_total,
    COALESCE(vi.narration, v.narration)             AS narration,
    v.reference_number,
    v.party_ledger_id,
    pl.name                                         AS party_name,
    v.source_module_key,
    v.posted_at,
    v.posted_by
FROM `acc_voucher_items` vi
JOIN `acc_vouchers`         v  ON v.id  = vi.voucher_id
JOIN `acc_voucher_types`    vt ON vt.id = v.voucher_type_id
JOIN `acc_ledgers`          l  ON l.id  = vi.ledger_id
JOIN `acc_account_groups`   g  ON g.id  = l.account_group_id
LEFT JOIN `acc_ledgers`     pl ON pl.id = v.party_ledger_id
WHERE vi.voucher_status = 'Posted'
  AND v.is_provisional = 0
  AND vi.deleted_at IS NULL;


-- A ledger statement: the lines of one ledger, with the contra ledger named, so a row reads
-- "To Fee Income" rather than merely showing an amount. Query with ledger_id and a date range.
CREATE OR REPLACE VIEW `vw_ledger_statement` AS
SELECT
    vi.id                                           AS voucher_item_id,
    vi.ledger_id,
    l.name                                          AS ledger_name,
    vi.voucher_date,
    vi.financial_year_id,
    vi.period_id,
    v.id                                            AS voucher_id,
    v.voucher_display_no,
    vt.code                                         AS voucher_type_code,
    vt.school_label,
    vi.entry_type,
    CASE WHEN vi.entry_type = 'Dr' THEN vi.amount ELSE 0 END AS debit_amount,
    CASE WHEN vi.entry_type = 'Cr' THEN vi.amount ELSE 0 END AS credit_amount,
    COALESCE(vi.narration, v.narration)             AS narration,
    v.reference_number,
    -- The other side of a simple two-line voucher. NULL where the voucher has more than two lines,
    -- which the UI renders as 'As per details'.
    (SELECT MIN(o.ledger_id) FROM `acc_voucher_items` o
      WHERE o.voucher_id = vi.voucher_id AND o.id <> vi.id AND o.deleted_at IS NULL
      HAVING COUNT(*) = 1)                          AS contra_ledger_id,
    vi.is_reconciled,
    vi.bank_value_date
FROM `acc_voucher_items` vi
JOIN `acc_vouchers`      v  ON v.id  = vi.voucher_id
JOIN `acc_voucher_types` vt ON vt.id = v.voucher_type_id
JOIN `acc_ledgers`       l  ON l.id  = vi.ledger_id
WHERE vi.voucher_status = 'Posted'
  AND v.is_provisional = 0
  AND vi.deleted_at IS NULL;


-- What each party owes or is owed, bill by bill. Reads the cache; the assertion keeps it honest.
CREATE OR REPLACE VIEW `vw_party_outstanding` AS
SELECT
    br.id                                           AS bill_reference_id,
    br.ledger_id,
    l.code                                          AS ledger_code,
    l.name                                          AS party_name,
    l.party_type,
    l.credit_limit,
    l.credit_days,
    br.reference_no,
    br.reference_date,
    br.due_date,
    br.bill_type,
    br.status                                       AS bill_status,
    br.is_disputed,
    br.financial_year_id,
    br.campus_id,
    br.fund_id,
    COALESCE(bb.original_amount,    br.original_amount)    AS original_amount,
    COALESCE(bb.allocated_amount,   0)                     AS allocated_amount,
    COALESCE(bb.written_off_amount, br.written_off_amount) AS written_off_amount,
    COALESCE(bb.outstanding_amount,
             br.original_amount - br.written_off_amount)   AS outstanding_amount,
    COALESCE(bb.days_overdue, DATEDIFF(CURDATE(), br.due_date)) AS days_overdue,
    bb.age_bucket,
    br.source_voucher_id
FROM `acc_bill_references` br
JOIN `acc_ledgers` l ON l.id = br.ledger_id
LEFT JOIN `acc_bill_reference_balances` bb ON bb.bill_reference_id = br.id
WHERE br.deleted_at IS NULL
  AND br.status NOT IN ('Settled','Cancelled');


-- Receivable ageing. Buckets are the default 30/60/90/180; BR-AR-02 makes them configurable, and the
-- configured edges live in acc_settings, which is what the reporting service reads. AC-AR-01: the total
-- here must equal the Sundry Debtors control balance — asserted.
CREATE OR REPLACE VIEW `vw_receivable_ageing` AS
SELECT
    ledger_id, ledger_code, party_name, party_type,
    bill_reference_id, reference_no, reference_date, due_date,
    outstanding_amount, days_overdue, is_disputed, campus_id, financial_year_id,
    CASE
        WHEN days_overdue <= 0   THEN 'Not_Due'
        WHEN days_overdue <= 30  THEN '01_30'
        WHEN days_overdue <= 60  THEN '31_60'
        WHEN days_overdue <= 90  THEN '61_90'
        WHEN days_overdue <= 180 THEN '91_180'
        ELSE                          'Over_180'
    END                                             AS ageing_bucket
FROM `vw_party_outstanding`
WHERE bill_type IN ('Sales','Opening','Adjustment')
  AND outstanding_amount > 0;


CREATE OR REPLACE VIEW `vw_payable_ageing` AS
SELECT
    ledger_id, ledger_code, party_name, party_type,
    bill_reference_id, reference_no, reference_date, due_date,
    outstanding_amount, days_overdue, is_disputed, campus_id, financial_year_id,
    CASE
        WHEN days_overdue <= 0   THEN 'Not_Due'
        WHEN days_overdue <= 30  THEN '01_30'
        WHEN days_overdue <= 60  THEN '31_60'
        WHEN days_overdue <= 90  THEN '61_90'
        WHEN days_overdue <= 180 THEN '91_180'
        ELSE                          'Over_180'
    END                                             AS ageing_bucket
FROM `vw_party_outstanding`
WHERE bill_type IN ('Purchase','Opening','Adjustment')
  AND outstanding_amount > 0;


-- Bill against its settlements. This is the drill-down behind "what has this student paid for?"
-- (BRD BR-FEE-04, AC-AR-02) and the evidence behind the party-vs-bill assertion.
CREATE OR REPLACE VIEW `vw_bill_reconciliation` AS
SELECT
    br.id                                           AS bill_reference_id,
    br.ledger_id,
    l.name                                          AS party_name,
    br.reference_no,
    br.reference_date,
    br.due_date,
    br.bill_type,
    br.original_amount,
    br.written_off_amount,
    br.status                                       AS bill_status,
    ba.id                                           AS allocation_id,
    ba.allocation_type,
    ba.amount                                       AS allocated_amount,
    ba.allocation_date,
    ba.voucher_id                                   AS settling_voucher_id,
    sv.voucher_display_no                           AS settling_voucher_no,
    svt.code                                        AS settling_voucher_type,
    br.source_voucher_id,
    ov.voucher_display_no                           AS originating_voucher_no
FROM `acc_bill_references` br
JOIN `acc_ledgers` l ON l.id = br.ledger_id
LEFT JOIN `acc_bill_allocations` ba ON ba.bill_reference_id = br.id
LEFT JOIN `acc_vouchers`      sv  ON sv.id  = ba.voucher_id
LEFT JOIN `acc_voucher_types` svt ON svt.id = sv.voucher_type_id
LEFT JOIN `acc_vouchers`      ov  ON ov.id  = br.source_voucher_id
WHERE br.deleted_at IS NULL;


-- Cost-centre analysis. Read from the allocation table, not from the balance buckets: Phase 1 maintains
-- only the ledger-total buckets (Solution_Design_v1 OD-04), so the dimension detail lives here.
CREATE OR REPLACE VIEW `vw_cost_center_summary` AS
SELECT
    cc.id                                           AS cost_center_id,
    cc.code                                         AS cost_center_code,
    cc.name                                         AS cost_center_name,
    cc.path                                         AS cost_center_path,
    ccat.id                                         AS cost_category_id,
    ccat.name                                       AS cost_category_name,
    vi.financial_year_id,
    vi.period_id,
    vi.campus_id,
    l.id                                            AS ledger_id,
    l.name                                          AS ledger_name,
    g.nature,
    SUM(CASE WHEN vi.entry_type = 'Dr' THEN vicc.amount ELSE 0 END) AS debit_amount,
    SUM(CASE WHEN vi.entry_type = 'Cr' THEN vicc.amount ELSE 0 END) AS credit_amount,
    SUM(CASE WHEN g.nature = 'Expense' THEN
             CASE WHEN vi.entry_type = 'Dr' THEN vicc.amount ELSE -vicc.amount END
         ELSE 0 END)                                AS expense_amount,
    COUNT(DISTINCT vi.voucher_id)                   AS voucher_count
FROM `acc_voucher_item_cost_centers` vicc
JOIN `acc_voucher_items`    vi   ON vi.id   = vicc.voucher_item_id
JOIN `acc_cost_centers`     cc   ON cc.id   = vicc.cost_center_id
JOIN `acc_cost_categories`  ccat ON ccat.id = vicc.cost_category_id
JOIN `acc_ledgers`          l    ON l.id    = vi.ledger_id
JOIN `acc_account_groups`   g    ON g.id    = l.account_group_id
WHERE vi.voucher_status = 'Posted' AND vi.deleted_at IS NULL
GROUP BY cc.id, cc.code, cc.name, cc.path, ccat.id, ccat.name,
         vi.financial_year_id, vi.period_id, vi.campus_id, l.id, l.name, g.nature;


-- Fund utilisation. AC-FUND-01: opening + additions − utilisation = closing, and that identity is
-- asserted nightly rather than assumed by the reader.
CREATE OR REPLACE VIEW `vw_fund_utilisation` AS
SELECT
    f.id                                            AS fund_id,
    f.code                                          AS fund_code,
    f.name                                          AS fund_name,
    f.fund_type,
    f.restriction_purpose,
    f.sanctioned_amount,
    f.utilisation_from,
    f.utilisation_to,
    f.overspend_action,
    f.status                                        AS fund_status,
    gl.name                                         AS grantor_name,
    fb.financial_year_id,
    fb.period_id,
    p.name                                          AS period_name,
    fb.campus_id,
    fb.opening_balance,
    fb.additions,
    fb.utilisation,
    fb.transfers_in,
    fb.transfers_out,
    fb.closing_balance,
    fb.available_balance,
    -- The identity BR-FUND-04 states. Nonzero here means the cache has drifted and the assertion failed.
    (fb.opening_balance + fb.additions + fb.transfers_in
       - fb.utilisation - fb.transfers_out - fb.closing_balance) AS identity_variance,
    CASE WHEN f.sanctioned_amount IS NULL OR f.sanctioned_amount = 0 THEN NULL
         ELSE ROUND(100 * fb.utilisation / f.sanctioned_amount, 2) END AS utilised_percent,
    fb.is_stale
FROM `acc_fund_balances` fb
JOIN `acc_funds` f ON f.id = fb.fund_id
LEFT JOIN `acc_ledgers` gl ON gl.id = f.grantor_ledger_id
JOIN `acc_accounting_periods` p ON p.id = fb.period_id
WHERE f.deleted_at IS NULL;


-- Where every bank account stands: reconciled to when, with what left unexplained.
-- This is the bank row of the Reconciliation Cockpit (BRD Enhancement E-02).
CREATE OR REPLACE VIEW `vw_bank_reconciliation_status` AS
SELECT
    br.id                                           AS reconciliation_id,
    br.bank_ledger_id,
    l.name                                          AS bank_ledger_name,
    l.bank_name,
    l.bank_account_number,
    br.financial_year_id,
    br.period_id,
    br.statement_from_date,
    br.statement_date,
    br.balance_as_per_books,
    br.unpresented_amount,
    br.uncredited_amount,
    br.other_adjustments,
    br.balance_as_per_bank,
    br.statement_closing_balance,
    br.difference,
    br.status,
    br.completed_at,
    br.imported_row_count,
    DATEDIFF(CURDATE(), br.statement_date)          AS days_since_statement,
    COUNT(DISTINCT bse.id)                          AS statement_rows,
    SUM(CASE WHEN bse.match_status = 'Unmatched' THEN 1 ELSE 0 END) AS unmatched_rows,
    SUM(CASE WHEN bse.match_status = 'Proposed'  THEN 1 ELSE 0 END) AS proposed_rows,
    SUM(CASE WHEN bse.match_status = 'Matched'   THEN 1 ELSE 0 END) AS matched_rows
FROM `acc_bank_reconciliations` br
JOIN `acc_ledgers` l ON l.id = br.bank_ledger_id
LEFT JOIN `acc_bank_statement_entries` bse ON bse.reconciliation_id = br.id
WHERE br.deleted_at IS NULL
GROUP BY br.id, br.bank_ledger_id, l.name, l.bank_name, l.bank_account_number,
         br.financial_year_id, br.period_id, br.statement_from_date, br.statement_date,
         br.balance_as_per_books, br.unpresented_amount, br.uncredited_amount,
         br.other_adjustments, br.balance_as_per_bank, br.statement_closing_balance,
         br.difference, br.status, br.completed_at, br.imported_row_count;


-- The CURRENT state of every cheque. acc_cheque_transactions is append-only, so "current" is the newest
-- row per cheque — which is what the ROW_NUMBER() filter selects. AC-CHEQUE-02 reads is_stale from here.
CREATE OR REPLACE VIEW `vw_cheque_register` AS
SELECT
    ct.id                                           AS cheque_transaction_id,
    ct.voucher_id,
    v.voucher_display_no,
    v.voucher_date,
    ct.bank_ledger_id,
    bl.name                                         AS bank_ledger_name,
    ct.party_ledger_id,
    pl.name                                         AS party_name,
    ct.direction,
    ct.instrument_no,
    ct.instrument_date,
    ct.amount,
    ct.favouring_name,
    ct.status                                       AS current_status,
    ct.status_date,
    ct.is_post_dated,
    ct.stale_on,
    ct.bounce_reason,
    ct.bounce_charge_amount,
    ct.reversal_voucher_id,
    ct.charge_voucher_id,
    ct.replacement_voucher_id,
    cl.leaf_no,
    -- BR-CHEQUE-01 'Stale': uncleared beyond the stale date. Three months by default.
    CASE WHEN ct.status IN ('Issued','Presented')
          AND ct.stale_on IS NOT NULL AND ct.stale_on < CURDATE()
         THEN 1 ELSE 0 END                          AS is_stale,
    DATEDIFF(CURDATE(), ct.instrument_date)         AS age_days
FROM (
    SELECT t.*, ROW_NUMBER() OVER (
               PARTITION BY t.voucher_id, t.instrument_no
               ORDER BY t.status_date DESC, t.id DESC) AS state_rank
    FROM `acc_cheque_transactions` t
) ct
JOIN `acc_vouchers` v  ON v.id  = ct.voucher_id
JOIN `acc_ledgers`  bl ON bl.id = ct.bank_ledger_id
LEFT JOIN `acc_ledgers`       pl ON pl.id = ct.party_ledger_id
LEFT JOIN `acc_cheque_leaves` cl ON cl.id = ct.cheque_leaf_id
WHERE ct.state_rank = 1;


-- Budget versus actual. BR-BUD-03: actuals are never affected by budgets — the actual side here comes
-- from the same balance buckets every statement reads, with the budget joined alongside, never into it.
CREATE OR REPLACE VIEW `vw_budget_variance` AS
SELECT
    bd.id                                           AS budget_id,
    bd.code                                         AS budget_code,
    bd.name                                         AS budget_name,
    bd.budget_type,
    bd.version,
    bd.status                                       AS budget_status,
    bd.breach_action,
    bd.breach_tolerance_pct,
    bl.id                                           AS budget_line_id,
    bd.financial_year_id,
    bl.period_id,
    bl.ledger_id,
    l.name                                          AS ledger_name,
    bl.account_group_id,
    bl.cost_center_id,
    bl.fund_id,
    bl.campus_id,
    g.nature,
    bl.budgeted_amount,
    -- Expense is Dr-positive, Income is Cr-positive. Comparing an income budget to a debit total would
    -- report every school as catastrophically under budget.
    COALESCE(SUM(CASE WHEN g.nature = 'Income'
                      THEN lpb.period_credit - lpb.period_debit
                      ELSE lpb.period_debit  - lpb.period_credit END), 0) AS actual_amount,
    bl.budgeted_amount
      - COALESCE(SUM(CASE WHEN g.nature = 'Income'
                          THEN lpb.period_credit - lpb.period_debit
                          ELSE lpb.period_debit  - lpb.period_credit END), 0) AS variance_amount,
    CASE WHEN bl.budgeted_amount = 0 THEN NULL
         ELSE ROUND(100 *
              COALESCE(SUM(CASE WHEN g.nature = 'Income'
                                THEN lpb.period_credit - lpb.period_debit
                                ELSE lpb.period_debit  - lpb.period_credit END), 0)
              / bl.budgeted_amount, 2) END          AS utilised_percent
FROM `acc_budget_lines` bl
JOIN `acc_budgets` bd ON bd.id = bl.budget_id
LEFT JOIN `acc_ledgers`        l ON l.id = bl.ledger_id
LEFT JOIN `acc_account_groups` g ON g.id = COALESCE(bl.account_group_id, l.account_group_id)
LEFT JOIN `acc_ledger_period_balances` lpb
       ON lpb.ledger_id         = bl.ledger_id
      AND lpb.financial_year_id = bd.financial_year_id
      AND (bl.period_id IS NULL OR lpb.period_id = bl.period_id)
      AND lpb.cost_center_id IS NULL AND lpb.fund_id IS NULL AND lpb.campus_id IS NULL
WHERE bd.deleted_at IS NULL AND bd.status IN ('Approved','Active')
GROUP BY bd.id, bd.code, bd.name, bd.budget_type, bd.version, bd.status,
         bd.breach_action, bd.breach_tolerance_pct, bl.id, bd.financial_year_id, bl.period_id,
         bl.ledger_id, l.name, bl.account_group_id, bl.cost_center_id, bl.fund_id, bl.campus_id,
         g.nature, bl.budgeted_amount;


-- TDS: what was deducted, what was paid over, and what is still owed. BR-TDS-06 as one query.
CREATE OR REPLACE VIEW `vw_tds_summary` AS
SELECT
    td.id                                           AS tds_deduction_id,
    td.financial_year_id,
    td.quarter,
    td.period_id,
    td.deduction_date,
    td.section_code,
    td.nature_of_payment,
    td.party_ledger_id,
    l.name                                          AS party_name,
    l.pan                                           AS party_pan,
    td.pan                                          AS deduction_pan,
    td.is_higher_rate_no_pan,
    td.tds_certificate_id,
    td.gross_amount,
    td.taxable_amount,
    td.rate_applied,
    td.tds_amount,
    td.net_paid_amount,
    td.paid_amount,
    td.tds_amount - td.paid_amount                  AS unpaid_amount,
    td.status,
    td.certificate_issued_no,
    td.voucher_id,
    v.voucher_display_no,
    -- The challans that paid it. GROUP_CONCAT because a deduction may be split across challans.
    GROUP_CONCAT(DISTINCT tp.challan_no ORDER BY tp.challan_no SEPARATOR ', ') AS challan_numbers,
    MAX(tp.deposit_date)                            AS last_deposit_date
FROM `acc_tds_deductions` td
JOIN `acc_ledgers`  l ON l.id = td.party_ledger_id
JOIN `acc_vouchers` v ON v.id = td.voucher_id
LEFT JOIN `acc_tds_payment_allocations` tpa ON tpa.tds_deduction_id = td.id
LEFT JOIN `acc_tds_payments`            tp  ON tp.id = tpa.tds_payment_id
GROUP BY td.id, td.financial_year_id, td.quarter, td.period_id, td.deduction_date,
         td.section_code, td.nature_of_payment, td.party_ledger_id, l.name, l.pan,
         td.pan, td.is_higher_rate_no_pan, td.tds_certificate_id, td.gross_amount,
         td.taxable_amount, td.rate_applied, td.tds_amount, td.net_paid_amount,
         td.paid_amount, td.status, td.certificate_issued_no, td.voucher_id, v.voucher_display_no;


-- GST and other tax applied, at the rate frozen on the transaction (BR-TAX-01). Return data is composed
-- from here and must reconcile to the tax ledger movement — asserted, not assumed.
CREATE OR REPLACE VIEW `vw_tax_summary` AS
SELECT
    vit.id                                          AS voucher_item_tax_id,
    v.id                                            AS voucher_id,
    v.voucher_display_no,
    v.voucher_date,
    v.financial_year_id,
    v.period_id,
    vt.code                                         AS voucher_type_code,
    v.party_ledger_id,
    pl.name                                         AS party_name,
    pl.gstin                                        AS party_gstin,
    pl.state_code                                   AS party_state,
    tt.code                                         AS tax_type_code,
    tt.tax_family,
    tt.is_input,
    vit.tax_rate_id,
    vit.tax_rule_id,
    vit.taxable_amount,
    vit.rate_applied,
    vit.tax_amount,
    vit.is_reverse_charge,
    vit.is_input_credit,
    vit.is_credit_eligible,
    -- Ineligible input credit is expensed, not claimed (Solution_Design_v1 §9.4).
    CASE WHEN vit.is_input_credit = 1 AND vit.is_credit_eligible = 1
         THEN vit.tax_amount ELSE 0 END             AS claimable_credit,
    vit.hsn_sac_code,
    vit.place_of_supply,
    vi.ledger_id                                    AS taxable_ledger_id,
    l.name                                          AS taxable_ledger_name
FROM `acc_voucher_item_taxes` vit
JOIN `acc_voucher_items` vi ON vi.id = vit.voucher_item_id
JOIN `acc_vouchers`      v  ON v.id  = vi.voucher_id
JOIN `acc_voucher_types` vt ON vt.id = v.voucher_type_id
JOIN `acc_tax_types`     tt ON tt.id = vit.tax_type_id
JOIN `acc_ledgers`       l  ON l.id  = vi.ledger_id
LEFT JOIN `acc_ledgers`  pl ON pl.id = v.party_ledger_id
WHERE vi.voucher_status = 'Posted' AND v.is_provisional = 0;


-- The asset register, with net block DERIVED. Σ net_block here must equal the asset ledger balances
-- (BR-FA-07, AC-FA-01) — which is the assertion that would have caught v4.3's stored current_value
-- drifting away from the books.
CREATE OR REPLACE VIEW `vw_fixed_asset_register` AS
SELECT
    fa.id                                           AS fixed_asset_id,
    fa.asset_code,
    fa.name                                         AS asset_name,
    fa.asset_category_id,
    ac.name                                         AS category_name,
    COALESCE(fa.depreciation_method, ac.depreciation_method) AS depreciation_method,
    COALESCE(fa.depreciation_rate,   ac.depreciation_rate)   AS depreciation_rate,
    COALESCE(fa.useful_life_years,   ac.useful_life_years)   AS useful_life_years,
    fa.purchase_date,
    fa.put_to_use_date,
    fa.purchase_cost,
    fa.salvage_value,
    fa.location,
    fa.custodian_user_id,
    fa.campus_id,
    fa.cost_center_id,
    fa.fund_id,
    f.name                                          AS fund_name,
    fa.vendor_id,
    fa.voucher_id                                   AS purchase_voucher_id,
    pv.voucher_display_no                           AS purchase_voucher_no,
    fa.status,
    COALESCE(dep.accumulated_depreciation, 0)       AS accumulated_depreciation,
    COALESCE(dep.depreciation_entry_count, 0)       AS depreciation_entry_count,
    dep.last_depreciation_date,
    ad.disposal_date,
    ad.disposal_type,
    ad.sale_proceeds,
    ad.gain_loss_amount,
    -- NET BLOCK. Derived, in exactly one place in the system.
    CASE WHEN ad.id IS NOT NULL THEN 0
         ELSE fa.purchase_cost - COALESCE(dep.accumulated_depreciation, 0) END AS net_block,
    ac.asset_ledger_id,
    ac.accum_dep_ledger_id,
    ac.depreciation_expense_ledger_id
FROM `acc_fixed_assets` fa
JOIN `acc_asset_categories` ac ON ac.id = fa.asset_category_id
LEFT JOIN `acc_funds`    f  ON f.id  = fa.fund_id
LEFT JOIN `acc_vouchers` pv ON pv.id = fa.voucher_id
LEFT JOIN `acc_asset_disposals` ad ON ad.fixed_asset_id = fa.id
LEFT JOIN (
    SELECT `fixed_asset_id`,
           SUM(`depreciation_amount`) AS accumulated_depreciation,
           COUNT(*)                   AS depreciation_entry_count,
           MAX(`depreciation_date`)   AS last_depreciation_date
    FROM `acc_depreciation_entries`
    WHERE `is_posted` = 1
    GROUP BY `fixed_asset_id`
) dep ON dep.fixed_asset_id = fa.id
WHERE fa.deleted_at IS NULL;


-- BR-AUD-06 / AC-AUD-01: the complete history of a voucher — who did what, when — in one query.
CREATE OR REPLACE VIEW `vw_voucher_audit_trail` AS
SELECT
    al.id                                           AS audit_id,
    al.voucher_id,
    v.voucher_display_no,
    v.voucher_date,
    v.status                                        AS current_voucher_status,
    vt.code                                         AS voucher_type_code,
    al.entity_type,
    al.entity_id,
    al.action,
    al.changed_fields,
    al.old_values,
    al.new_values,
    al.reason,
    al.actor_type,
    al.user_id,
    al.user_name,
    al.impersonated_by,
    al.ip_address,
    al.request_id,
    al.occurred_at
FROM `acc_audit_logs` al
LEFT JOIN `acc_vouchers`      v  ON v.id  = al.voucher_id
LEFT JOIN `acc_voucher_types` vt ON vt.id = v.voucher_type_id
WHERE al.voucher_id IS NOT NULL
   OR al.entity_type IN ('acc_vouchers','acc_voucher_items','acc_bill_allocations','acc_voucher_approvals');


-- The exception dashboard (AC-EXC-01): count and value of every open exception, drillable to records.
CREATE OR REPLACE VIEW `vw_accounting_exceptions` AS
SELECT
    e.id                                            AS exception_id,
    e.rule_code,
    r.name                                          AS rule_name,
    r.category,
    e.severity,
    r.blocks_period_close,
    e.entity_type,
    e.entity_id,
    e.entity_label,
    e.ledger_id,
    l.name                                          AS ledger_name,
    e.voucher_id,
    v.voucher_display_no,
    e.financial_year_id,
    e.period_id,
    e.campus_id,
    e.amount,
    e.age_days,
    e.message,
    e.detail,
    e.status,
    e.first_detected_at,
    e.last_detected_at,
    e.detection_count,
    e.acknowledged_by,
    e.acknowledge_expires_at,
    -- An acknowledgement that has run out puts the exception back on the dashboard (BR-EXC-03).
    CASE WHEN e.status = 'Acknowledged'
          AND e.acknowledge_expires_at IS NOT NULL
          AND e.acknowledge_expires_at < NOW()
         THEN 1 ELSE 0 END                          AS acknowledgement_expired
FROM `acc_exceptions` e
JOIN `acc_exception_rules` r ON r.id = e.exception_rule_id
LEFT JOIN `acc_ledgers`  l ON l.id = e.ledger_id
LEFT JOIN `acc_vouchers` v ON v.id = e.voucher_id
WHERE e.status NOT IN ('Resolved','Suppressed');


-- The Reconciliation Cockpit's module rows (Enhancement E-02): every module against the books.
CREATE OR REPLACE VIEW `vw_module_reconciliation` AS
SELECT
    mr.id                                           AS reconciliation_id,
    mr.module_key,
    mr.financial_year_id,
    mr.period_id,
    p.name                                          AS period_name,
    p.status                                        AS period_status,
    mr.reconciliation_date,
    mr.metric,
    mr.source_total,
    mr.posted_total,
    mr.difference,
    mr.source_count,
    mr.posted_count,
    mr.unposted_count,
    mr.failed_count,
    mr.status,
    mr.explanation,
    mr.difference_detail,
    mr.reviewed_by,
    mr.reviewed_at,
    mr.run_at,
    DATEDIFF(CURDATE(), mr.reconciliation_date)     AS age_days,
    CASE WHEN mr.source_total = 0 THEN NULL
         ELSE ROUND(100 * ABS(mr.difference) / mr.source_total, 4) END AS difference_percent
FROM `acc_module_reconciliation` mr
JOIN `acc_accounting_periods` p ON p.id = mr.period_id;


-- The Period Close Cockpit (Enhancement E-03): can this period close, and if not, what is stopping it.
CREATE OR REPLACE VIEW `vw_period_close_status` AS
SELECT
    p.id                                            AS period_id,
    p.financial_year_id,
    fy.name                                         AS financial_year_name,
    p.period_no,
    p.name                                          AS period_name,
    p.start_date,
    p.end_date,
    p.status                                        AS period_status,
    p.closed_at,
    p.closed_by,
    p.reopen_count,
    COUNT(c.id)                                     AS checklist_total,
    SUM(CASE WHEN c.status = 'Passed'  THEN 1 ELSE 0 END) AS items_passed,
    SUM(CASE WHEN c.status = 'Failed'  THEN 1 ELSE 0 END) AS items_failed,
    SUM(CASE WHEN c.status = 'Pending' THEN 1 ELSE 0 END) AS items_pending,
    SUM(CASE WHEN c.status = 'Waived'  THEN 1 ELSE 0 END) AS items_waived,
    -- The one number that matters: blocking items not yet Passed or Waived.
    SUM(CASE WHEN c.is_blocking = 1
              AND c.status NOT IN ('Passed','Waived','Not_Applicable')
             THEN 1 ELSE 0 END)                     AS blocking_items_open,
    CASE WHEN SUM(CASE WHEN c.is_blocking = 1
                        AND c.status NOT IN ('Passed','Waived','Not_Applicable')
                       THEN 1 ELSE 0 END) = 0
         THEN 1 ELSE 0 END                          AS can_close
FROM `acc_accounting_periods` p
JOIN `acc_financial_years` fy ON fy.id = p.financial_year_id
LEFT JOIN `acc_period_close_checklist` c ON c.period_id = p.id
GROUP BY p.id, p.financial_year_id, fy.name, p.period_no, p.name,
         p.start_date, p.end_date, p.status, p.closed_at, p.closed_by, p.reopen_count;


-- =========================================================================================================
-- SECTION 20: SEED DATA
--
--     Enough for a school to open its books on day one: a base currency, a campus, the chart of accounts,
--     voucher types, tax types, the system ledgers, exception rules and the module settings.
--
--     IDEMPOTENT. Every statement is INSERT IGNORE against a unique key, so running this file twice
--     inserts nothing the second time and changes nothing that a school has since edited. That property
--     is why the NULL-safe keys above matter here and not only in theory: INSERT IGNORE deduplicates
--     against a unique key, and a key that permits duplicates deduplicates nothing.
--
--     Parent rows are resolved with INSERT ... SELECT against the same table, which MySQL permits, so the
--     hierarchy seeds without knowing any auto-increment id in advance.
--
--     What is NOT seeded: financial years and accounting periods (they depend on the school's go-live
--     year, and PeriodService generates the twelve periods), and party ledgers (they follow the students,
--     staff and vendors).
-- =========================================================================================================

-- ── Currency (BRD §39). INR is the base; a school with foreign donors adds more. ─────────────────────────
INSERT IGNORE INTO `acc_currencies` (`code`,`name`,`symbol`,`decimal_places`,`is_base`,`is_active`) VALUES
    ('INR','Indian Rupee','₹',2,1,1),
    ('USD','US Dollar','$',2,0,0),
    ('GBP','Pound Sterling','£',2,0,0),
    ('EUR','Euro','€',2,0,0);

-- ── Campus. One primary campus; multi-campus is Phase 4 but the dimension exists from day one (OD-02). ──
INSERT IGNORE INTO `acc_campuses` (`code`,`name`,`is_primary`,`is_active`) VALUES
    ('MAIN','Main Campus',1,1);

-- ── Cost categories: the independent analysis axes (BRD BR-CC-04). ──────────────────────────────────────
INSERT IGNORE INTO `acc_cost_categories` (`code`,`name`,`description`,`is_mandatory`,`allow_multiple`,`ordinal`) VALUES
    ('WING',      'Wing',       'Primary, Middle, Senior — the academic division',       0,1,10),
    ('DEPARTMENT','Department', 'Science, Sports, Library, Administration',              0,1,20),
    ('ACTIVITY',  'Activity',   'Annual Day, Sports Meet, Excursion — event costing',    0,1,30),
    ('PROJECT',   'Project',    'Capital and grant-funded projects',                     0,1,40);

-- ── Chart of accounts: primary groups. `nature` decides the statement and never changes once used. ──────
INSERT IGNORE INTO `acc_account_groups` (`code`,`name`,`parent_id`,`nature`,`affects_gross_profit`,`depth`,`is_system`,`is_subledger`,`ordinal`) VALUES
    ('CA',       'Current Assets',            NULL,'Asset',    0,0,1,0,10),
    ('FA',       'Fixed Assets',              NULL,'Asset',    0,0,1,0,20),
    ('INVEST',   'Investments',               NULL,'Asset',    0,0,1,0,30),
    ('CL',       'Current Liabilities',       NULL,'Liability',0,0,1,0,40),
    ('LOANL',    'Loans (Liability)',         NULL,'Liability',0,0,1,0,50),
    ('FUNDS',    'Corpus and Funds',          NULL,'Equity',   0,0,1,0,60),
    ('INCDIR',   'Direct Income',             NULL,'Income',   1,0,1,0,70),
    ('INCIND',   'Indirect Income',           NULL,'Income',   0,0,1,0,80),
    ('EXPDIR',   'Direct Expenses',           NULL,'Expense',  1,0,1,0,90),
    ('EXPIND',   'Indirect Expenses',         NULL,'Expense',  0,0,1,0,100);

-- ── Sub-groups. is_subledger marks a party CONTROL account: its balance must equal the sum of the
--    bill outstandings beneath it, which is one of the standing assertions (Solution_Design_v1 §5.5). ────
INSERT IGNORE INTO `acc_account_groups` (`code`,`name`,`parent_id`,`nature`,`affects_gross_profit`,`depth`,`is_system`,`is_subledger`,`ordinal`)
SELECT x.code, x.name, p.id, x.nature, x.agp, 1, 1, x.sub, x.ordinal
FROM (
    SELECT 'BANK'      AS code,'Bank Accounts'                  AS name,'CA'     AS parent,'Asset'     AS nature,0 AS agp,0 AS sub,11 AS ordinal UNION ALL
    SELECT 'CASH',     'Cash-in-Hand',                          'CA',    'Asset',    0,0,12 UNION ALL
    SELECT 'DEBTORS',  'Sundry Debtors',                        'CA',    'Asset',    0,1,13 UNION ALL
    SELECT 'FEERECV',  'Fee Receivable',                        'CA',    'Asset',    0,1,14 UNION ALL
    SELECT 'ADVASSET', 'Loans and Advances (Asset)',            'CA',    'Asset',    0,1,15 UNION ALL
    SELECT 'DEPOSITS', 'Deposits (Asset)',                      'CA',    'Asset',    0,0,16 UNION ALL
    SELECT 'GRANTRECV','Grants Receivable',                     'CA',    'Asset',    0,0,17 UNION ALL
    SELECT 'SUSPENSE', 'Suspense Account',                      'CA',    'Asset',    0,0,18 UNION ALL
    SELECT 'FAGROSS',  'Fixed Assets (Gross Block)',            'FA',    'Asset',    0,0,21 UNION ALL
    SELECT 'FADEP',    'Accumulated Depreciation',              'FA',    'Asset',    0,0,22 UNION ALL
    SELECT 'CREDITORS','Sundry Creditors',                      'CL',    'Liability',0,1,41 UNION ALL
    SELECT 'DUTIES',   'Duties and Taxes',                      'CL',    'Liability',0,0,42 UNION ALL
    SELECT 'PROVISION','Provisions',                            'CL',    'Liability',0,0,43 UNION ALL
    SELECT 'FEEADV',   'Fees Received in Advance',              'CL',    'Liability',0,0,44 UNION ALL
    SELECT 'GRANTUNU', 'Unutilised Grants',                     'CL',    'Liability',0,0,45 UNION ALL
    SELECT 'STAFFPAY', 'Salaries and Staff Dues Payable',       'CL',    'Liability',0,1,46 UNION ALL
    SELECT 'CORPUS',   'Corpus Fund',                           'FUNDS', 'Equity',   0,0,61 UNION ALL
    SELECT 'RESTFUND', 'Restricted Funds',                      'FUNDS', 'Equity',   0,0,62 UNION ALL
    SELECT 'DESIGFUND','Designated Funds',                      'FUNDS', 'Equity',   0,0,63 UNION ALL
    SELECT 'GENFUND',  'General Fund (Accumulated Surplus)',    'FUNDS', 'Equity',   0,0,64 UNION ALL
    SELECT 'FEEINC',   'Fee Income',                            'INCDIR','Income',   1,0,71 UNION ALL
    SELECT 'DONINC',   'Donations',                             'INCIND','Income',   0,0,81 UNION ALL
    SELECT 'GRANTINC', 'Grant Income',                          'INCIND','Income',   0,0,82 UNION ALL
    SELECT 'OTHERINC', 'Other Income',                          'INCIND','Income',   0,0,83 UNION ALL
    SELECT 'ACADEXP',  'Academic Expenses',                     'EXPDIR','Expense',  1,0,91 UNION ALL
    SELECT 'SALEXP',   'Salaries and Staff Costs',              'EXPIND','Expense',  0,0,101 UNION ALL
    SELECT 'ADMEXP',   'Administrative Expenses',               'EXPIND','Expense',  0,0,102 UNION ALL
    SELECT 'ESTEXP',   'Establishment and Maintenance',         'EXPIND','Expense',  0,0,103 UNION ALL
    SELECT 'DEPEXP',   'Depreciation',                          'EXPIND','Expense',  0,0,104 UNION ALL
    SELECT 'FINEXP',   'Finance Charges',                       'EXPIND','Expense',  0,0,105 UNION ALL
    SELECT 'CONCEXP',  'Concessions and Scholarships',          'EXPIND','Expense',  0,0,106 UNION ALL
    SELECT 'WOEXP',    'Bad Debts and Write-Offs',              'EXPIND','Expense',  0,0,107 UNION ALL
    SELECT 'ROUNDEXP', 'Rounding Off',                          'EXPIND','Expense',  0,0,108
) x
JOIN `acc_account_groups` p ON p.code = x.parent AND p.deleted_at IS NULL;

-- The materialised `path` and `depth` columns are filled by `php artisan acc:rebuild-group-paths`,
-- because a path is built from auto-increment ids that do not exist until these rows are inserted.

-- ── System ledgers. is_system = 1: they may not be deleted, and the posting engine expects them by code.
--    Rounding Off exists so BR-ROUND-02 has somewhere to post; Suspense so BR-SUSP-01 does. ─────────────
INSERT IGNORE INTO `acc_ledgers` (`code`,`name`,`account_group_id`,`ledger_type`,`is_system`,`is_active`,`allow_reconciliation`,`is_bill_wise`)
SELECT x.code, x.name, g.id, x.ledger_type, 1, 1, x.recon, 0
FROM (
    SELECT 'CASH-MAIN'  AS code,'Cash in Hand'              AS name,'CASH'     AS grp,'Cash'     AS ledger_type,0 AS recon UNION ALL
    SELECT 'PETTYCASH', 'Petty Cash',                        'CASH',    'Cash',    0 UNION ALL
    SELECT 'SUSPENSE',  'Suspense',                          'SUSPENSE','Suspense',0 UNION ALL
    SELECT 'ROUNDOFF',  'Rounding Off',                      'ROUNDEXP','Rounding',0 UNION ALL
    SELECT 'CORPUSFUND','Corpus Fund',                       'CORPUS',  'Fund',    0 UNION ALL
    SELECT 'GENFUND',   'General Fund',                      'GENFUND', 'Fund',    0 UNION ALL
    SELECT 'TDSPAY',    'TDS Payable',                       'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'CGSTIN',    'Input CGST',                        'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'SGSTIN',    'Input SGST',                        'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'IGSTIN',    'Input IGST',                        'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'CGSTOUT',   'Output CGST',                       'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'SGSTOUT',   'Output SGST',                       'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'IGSTOUT',   'Output IGST',                       'DUTIES',  'Tax',     0 UNION ALL
    SELECT 'FEEINCOME', 'Fee Income',                        'FEEINC',  'General', 0 UNION ALL
    SELECT 'FEEADVANCE','Fees Received in Advance',          'FEEADV',  'General', 0 UNION ALL
    SELECT 'CONCESSION','Fee Concessions and Scholarships',  'CONCEXP', 'General', 0 UNION ALL
    SELECT 'BADDEBTS',  'Bad Debts Written Off',             'WOEXP',   'General', 0 UNION ALL
    SELECT 'DEPRECIATE','Depreciation',                      'DEPEXP',  'General', 0 UNION ALL
    SELECT 'BANKCHRG',  'Bank Charges',                      'FINEXP',  'General', 0 UNION ALL
    SELECT 'DONATION',  'Donations Received',                'DONINC',  'General', 0 UNION ALL
    SELECT 'GRANTINC',  'Grant Income',                      'GRANTINC','General', 0
) x
JOIN `acc_account_groups` g ON g.code = x.grp AND g.deleted_at IS NULL;

-- ── Voucher categories: which business area produces a voucher type. module_key is glb_app_modules.key,
--    which lives in the GLOBAL database — hence no foreign key (§17.1 #2). ────────────────────────────────
INSERT IGNORE INTO `acc_voucher_category` (`module_key`,`code`,`name`,`event_detail`,`module_table_name`) VALUES
    ('ACC','ACCOUNTING',     'Accounting',        'Vouchers entered directly in Accounting', NULL),
    ('FEE','FEE_COLLECTION', 'Fee Collection',    'Fee demands, receipts and concessions',   'fee_transactions'),
    ('LIB','LIBRARY',        'Library',           'Library fines and charges',               'lib_fines'),
    ('TPT','TRANSPORT',      'Transport',         'Transport fees and charges',              'tpt_student_route_allocation_jnt'),
    ('HST','HOSTEL',         'Hostel',            'Hostel fees and charges',                 'hst_allocations'),
    ('PAY','PAYROLL',        'Payroll',           'Salary, statutory deductions and payouts','pay_payroll_runs'),
    ('VND','VENDOR',         'Vendor',            'Purchase bills and vendor payments',      'vnd_bills'),
    ('ACC','ASSET',          'Fixed Assets',      'Asset purchase, depreciation and disposal','acc_fixed_assets'),
    ('ACC','EXPENSE_CLAIM',  'Expense Claims',    'Staff reimbursement claims',              'acc_expense_claims');

-- ── The nine voucher types. Their RULES are data, so adding a school-specific type needs no code. ───────
INSERT IGNORE INTO `acc_voucher_types`
    (`code`,`name`,`school_label`,`voucher_category_id`,`base_type`,`prefix`,`number_width`,
     `numbering_method`,`restart_policy`,`requires_party`,`creates_bill_reference`,`requires_narration`,
     `requires_evidence`,`requires_bank_details`,`allow_zero_value`,`allow_post_dated`,
     `allowed_ledger_types`,`forbidden_ledger_types`,`affects_books`,`default_entry_mode`,`is_system`,`ordinal`)
SELECT x.code, x.name, x.school_label, c.id, x.base_type, x.prefix, 5,
       'Auto','Financial_Year', x.req_party, x.creates_bill, x.req_narration,
       x.req_evidence, x.req_bank, 0, x.post_dated,
       x.allowed, x.forbidden, x.affects, x.entry_mode, 1, x.ordinal
FROM (
    SELECT 'PAYMENT'    AS code,'Payment'     AS name,'Payment'          AS school_label,'ACCOUNTING' AS cat,'Payment'     AS base_type,'PAY' AS prefix,0 AS req_party,0 AS creates_bill,1 AS req_narration,0 AS req_evidence,1 AS req_bank,1 AS post_dated,'' AS allowed,'' AS forbidden,1 AS affects,'Double' AS entry_mode,10 AS ordinal UNION ALL
    SELECT 'RECEIPT',    'Receipt',      'Receipt',          'ACCOUNTING','Receipt',    'RCP',0,0,1,0,1,1,'','',1,'Double',20 UNION ALL
    -- Contra moves money between the school's own cash and bank accounts and nothing else.
    SELECT 'CONTRA',     'Contra',       'Cash / Bank Transfer','ACCOUNTING','Contra',  'CTR',0,0,1,0,0,0,'Cash,Bank','',1,'Double',30 UNION ALL
    -- A journal that touches cash or bank would bypass the payment and receipt controls entirely.
    SELECT 'JOURNAL',    'Journal',      'Journal Entry',    'ACCOUNTING','Journal',    'JRN',0,0,1,0,0,0,'','Cash,Bank',1,'Double',40 UNION ALL
    SELECT 'SALES',      'Sales',        'Fee Demand',       'FEE_COLLECTION','Sales',  'DMD',1,1,0,0,0,0,'','',1,'Double',50 UNION ALL
    SELECT 'PURCHASE',   'Purchase',     'Vendor Bill',      'VENDOR','Purchase',       'PUR',1,1,0,1,0,0,'','',1,'Double',60 UNION ALL
    SELECT 'CREDIT_NOTE','Credit Note',  'Credit Note',      'ACCOUNTING','Credit_Note','CRN',1,0,1,0,0,0,'','',1,'Double',70 UNION ALL
    SELECT 'DEBIT_NOTE', 'Debit Note',   'Debit Note',       'ACCOUNTING','Debit_Note', 'DBN',1,0,1,0,0,0,'','',1,'Double',80 UNION ALL
    -- affects_books = 0. A memorandum voucher appears in NO financial statement, ever (BR-PROV-01).
    SELECT 'MEMORANDUM', 'Memorandum',   'Memo (not posted)','ACCOUNTING','Memorandum', 'MEM',0,0,1,0,0,0,'','',0,'Double',90
) x
JOIN `acc_voucher_category` c ON c.code = x.cat AND c.deleted_at IS NULL;

-- ── Tax types (BRD §45: GST and TDS only; VAT, CST, Service Tax and Excise are dead regimes). ───────────
INSERT IGNORE INTO `acc_tax_types` (`code`,`name`,`tax_family`,`is_input`,`ordinal`,`is_active`) VALUES
    ('CGST','Central GST','GST',0,10,1),
    ('SGST','State GST',  'GST',0,20,1),
    ('IGST','Integrated GST','GST',0,30,1),
    ('CESS','GST Cess',   'GST',0,40,0),
    ('TDS', 'Tax Deducted at Source','TDS',0,50,1),
    ('TCS', 'Tax Collected at Source','TCS',0,60,0);

-- ── Asset categories, with the Companies Act useful lives a school will recognise. ──────────────────────
INSERT IGNORE INTO `acc_asset_categories` (`code`,`name`,`depreciation_method`,`depreciation_rate`,`useful_life_years`,`is_active`) VALUES
    ('LAND',     'Land',                        'None', 0.0000,NULL,1),
    ('BUILDING', 'Buildings',                   'SLM',  3.1700,  30,1),
    ('FURNITURE','Furniture and Fixtures',      'SLM',  9.5000,  10,1),
    ('COMPUTER', 'Computers and IT Equipment',  'SLM', 31.6700,   3,1),
    ('LABEQUIP', 'Laboratory Equipment',        'SLM', 11.8800,   8,1),
    ('VEHICLE',  'Vehicles (School Buses)',     'SLM', 11.8800,   8,1),
    ('BOOKS',    'Library Books',               'SLM', 33.3300,   3,1),
    ('SPORTS',   'Sports Equipment',            'SLM', 19.0000,   5,1),
    ('ELECTRIC', 'Electrical Installations',    'SLM', 09.5000,  10,1);

-- ── Exception rules (BRD §53). Thresholds are configuration; tune one without a release. ───────────────
INSERT IGNORE INTO `acc_exception_rules`
    (`code`,`name`,`category`,`severity`,`checker_key`,`threshold_amount`,`threshold_days`,
     `blocks_period_close`,`allow_acknowledge`,`acknowledge_valid_days`,`run_frequency`,`is_active`) VALUES
    ('NEGATIVE_CASH',      'Cash ledger with a negative balance',            'Balance',      'Critical','cash.negative',        NULL,NULL,1,0,NULL, 'Realtime',1),
    ('NEGATIVE_BALANCE',   'Unexpected negative ledger balance',             'Balance',      'High',    'ledger.negative',      NULL,NULL,0,1,  30, 'Daily',   1),
    ('AGED_SUSPENSE',      'Suspense items older than 30 days',              'Balance',      'High',    'suspense.aged',        NULL,  30,1,1,  15, 'Daily',   1),
    ('SUSPENSE_NONZERO',   'Non-zero suspense balance at period end',        'Balance',      'Critical','suspense.nonzero',     NULL,NULL,1,1,   7, 'On_Close',1),
    ('OVERDUE_RECEIVABLE', 'Receivables overdue beyond 90 days',             'Ageing',       'Warning', 'receivable.overdue',   NULL,  90,0,1,  30, 'Daily',   1),
    ('OVERDUE_PAYABLE',    'Payables overdue beyond 60 days',                'Ageing',       'Warning', 'payable.overdue',      NULL,  60,0,1,  30, 'Daily',   1),
    ('UNALLOCATED_ONACC',  'On Account balances not allocated',              'Ageing',       'Warning', 'billwise.onaccount',   NULL,  30,0,1,  30, 'Daily',   1),
    ('UNADJUSTED_ADVANCE', 'Advances unadjusted beyond 90 days',             'Ageing',       'Warning', 'advance.unadjusted',   NULL,  90,0,1,  30, 'Weekly',  1),
    ('UNRECONCILED_BANK',  'Bank items unreconciled beyond 30 days',         'Reconciliation','High',   'bank.unreconciled',    NULL,  30,1,1,  15, 'Daily',   1),
    ('BANK_RECON_STALE',   'Bank account not reconciled this period',        'Reconciliation','High',   'bank.notreconciled',   NULL,NULL,1,1,  15, 'On_Close',1),
    ('MODULE_DIFFERENCE',  'Module total differs from posted total',         'Reconciliation','Critical','module.difference',   NULL,NULL,1,1,   7, 'Daily',   1),
    ('STALE_CHEQUE',       'Cheque uncleared beyond 90 days',                'Reconciliation','Warning','cheque.stale',         NULL,  90,0,1,  30, 'Daily',   1),
    ('UNPOSTED_DRAFTS',    'Draft vouchers in the period',                   'Approval',     'High',    'voucher.drafts',       NULL,NULL,1,0,NULL, 'On_Close',1),
    ('PENDING_APPROVALS',  'Vouchers awaiting approval',                     'Approval',     'High',    'voucher.pending',      NULL,NULL,1,0,NULL, 'On_Close',1),
    ('SELF_APPROVAL',      'A voucher approved by the person who raised it', 'Fraud_Risk',   'Critical','approval.self',        NULL,NULL,0,1,  30, 'Daily',   1),
    ('FREQUENT_CANCEL',    'Repeated cancellations by one user',             'Fraud_Risk',   'High',    'voucher.cancelrate',   NULL,  30,0,1,  30, 'Weekly',  1),
    ('UNUSUAL_JOURNAL',    'Large or unusual journal entry',                 'Fraud_Risk',   'High',    'journal.unusual',  100000.00,NULL,0,1,  30, 'Daily',   1),
    ('MISSING_EVIDENCE',   'Voucher above the threshold with no attachment', 'Data_Quality', 'Warning', 'voucher.noevidence',10000.00,NULL,0,1,  30, 'Daily',   1),
    ('DUPLICATE_CANDIDATE','Possible duplicate voucher',                     'Data_Quality', 'High',    'voucher.duplicate',    NULL,NULL,0,1,  15, 'Realtime',1),
    ('MISSING_TAX_DETAIL', 'Taxable transaction with no tax detail',         'Compliance',   'Warning', 'tax.missing',          NULL,NULL,0,1,  30, 'Daily',   1),
    ('TDS_NOT_DEPOSITED',  'TDS deducted and not deposited',                 'Compliance',   'Critical','tds.undeposited',      NULL,   7,1,0,NULL, 'Daily',   1),
    ('BUDGET_BREACH',      'Actual exceeds budget',                          'Budget',       'Warning', 'budget.breach',        NULL,NULL,0,1,  30, 'Daily',   1),
    ('FUND_OVERSPEND',     'Restricted fund spent beyond its balance',       'Budget',       'Critical','fund.overspend',       NULL,NULL,1,0,NULL, 'Realtime',1),
    ('GRANT_CERT_DUE',     'Grant utilisation certificate falling due',      'Compliance',   'Warning', 'grant.certdue',        NULL,  30,0,1,  15, 'Weekly',  1),
    ('NUMBER_GAP',         'Gap in a voucher number series',                 'Numbering',    'Critical','numbering.gap',        NULL,NULL,1,1,   7, 'Daily',   1),
    ('RECEIPT_80G_GAP',    'Gap in the 80G receipt series',                  'Numbering',    'Critical','numbering.gap80g',     NULL,NULL,1,1,   7, 'Daily',   1),
    ('BALANCE_STALE',      'Balance cache marked stale by an assertion',     'Balance',      'Critical','balance.stale',        NULL,NULL,1,0,NULL, 'Hourly',  1);

-- ── Module settings. The BRD says "configurable" throughout; these are the defaults it recommends,
--    with the Solution Design's open decisions (OD-05, OD-07, OD-08, OD-11) resolved as recommended. ────
INSERT IGNORE INTO `acc_settings`
    (`setting_key`,`setting_group`,`value_type`,`value_string`,`value_integer`,`value_decimal`,`value_boolean`,`value_json`,`default_value`,`description`,`is_school_editable`,`requires_four_eyes`) VALUES
    ('posting.rounding_tolerance',       'Posting',    'Decimal',NULL,NULL,1.0000,NULL,NULL,'1.00',  'Maximum rounding difference a voucher may absorb (BR-ROUND-03, OD-11)',1,0),
    ('posting.backdate_days',            'Posting',    'Integer',NULL,7,NULL,NULL,NULL,'7',          'Days a voucher may be back-dated without elevated permission (OD-05)',1,0),
    ('posting.negative_cash_action',     'Posting',    'String','Block',NULL,NULL,NULL,NULL,'Block', 'Block or Warn when cash would go negative (OD-07)',1,1),
    ('posting.allow_future_dated',       'Posting',    'Boolean',NULL,NULL,NULL,0,NULL,'false',      'Allow a voucher dated after today',1,0),
    ('period.soft_close_adjust_permission','Period',   'String','acc.period.adjust',NULL,NULL,NULL,NULL,'acc.period.adjust','Permission required to post into a soft-closed period',0,0),
    ('period.close_requires_all_blocking','Period',    'Boolean',NULL,NULL,NULL,1,NULL,'true',       'Refuse close while any blocking checklist item is open (BR-CLOSE-02)',0,1),
    ('billwise.ageing_basis',            'Bill_Wise',  'String','Due_Date',NULL,NULL,NULL,NULL,'Due_Date','Age from the due date or the bill date (BR-AR-02)',1,0),
    ('billwise.ageing_buckets',          'Bill_Wise',  'Json',NULL,NULL,NULL,NULL,CAST('[30,60,90,180]' AS JSON),'[30,60,90,180]','Ageing bucket edges in days (BR-AR-02)',1,0),
    ('billwise.onaccount_tolerance',     'Bill_Wise',  'Decimal',NULL,NULL,10000.0000,NULL,NULL,'10000.00','Unallocated On Account tolerated at period close',1,0),
    ('bank.match_tolerance_days',        'Bank',       'Integer',NULL,3,NULL,NULL,NULL,'3',          'Date window for a proposed statement match (Solution_Design §11.3)',1,0),
    ('bank.auto_confirm_exact',          'Bank',       'Boolean',NULL,NULL,NULL,0,NULL,'false',      'Auto-confirm exact amount+instrument matches. Off by default (OD-08)',1,1),
    ('bank.cheque_stale_days',           'Bank',       'Integer',NULL,90,NULL,NULL,NULL,'90',        'Days after which an uncleared cheque is stale (AC-CHEQUE-02)',1,0),
    ('numbering.restart_policy',         'Numbering',  'String','Financial_Year',NULL,NULL,NULL,NULL,'Financial_Year','Default series restart policy for new voucher types',1,0),
    ('numbering.gap_watch_enabled',      'Numbering',  'Boolean',NULL,NULL,NULL,1,NULL,'true',       'Continuous numbering gap detection (Enhancement E-06)',1,0),
    ('fund.overspend_default_action',    'Fund',       'String','Block',NULL,NULL,NULL,NULL,'Block',  'Default action when a restricted fund would be overspent (BR-FUND-03)',1,1),
    ('tax.gst_enabled',                  'Tax',        'Boolean',NULL,NULL,NULL,0,NULL,'false',      'GST applies to this school. Assume not, per OD-14',1,1),
    ('tax.tds_enabled',                  'Tax',        'Boolean',NULL,NULL,NULL,1,NULL,'true',       'TDS applies (BRD §46)',1,1),
    ('approval.payment_threshold',       'Approval',   'Decimal',NULL,NULL,50000.0000,NULL,NULL,'50000.00','Payments above this need approval (OD-06)',1,1),
    ('approval.journal_threshold',       'Approval',   'Decimal',NULL,NULL,25000.0000,NULL,NULL,'25000.00','Journals above this need approval (OD-06)',1,1),
    ('approval.forbid_self',             'Approval',   'Boolean',NULL,NULL,NULL,1,NULL,'true',       'A user may not approve their own voucher (BR-APPR-04)',0,1),
    ('reporting.fee_recognition_basis',  'Reporting',  'String','Accrual',NULL,NULL,NULL,NULL,'Accrual','Fee income on demand (accrual) or on receipt (cash) — OD-01, BR-FEE-02',1,1),
    ('reporting.depreciation_frequency', 'Reporting',  'String','Annual',NULL,NULL,NULL,NULL,'Annual','Annual at year end, or Monthly (OD-13)',1,0),
    ('reporting.student_ledger_scope',   'Reporting',  'String','Per_Student',NULL,NULL,NULL,NULL,'Per_Student','A ledger per student, with a family roll-up view (OD-09)',0,0),
    ('integration.max_retry',            'Integration','Integer',NULL,5,NULL,NULL,NULL,'5',          'Retries before an event is escalated to a person (BR-INT-04)',1,0),
    ('integration.reconcile_nightly',    'Integration','Boolean',NULL,NULL,NULL,1,NULL,'true',       'Nightly module-to-Accounting reconciliation (BR-INT-06)',0,0),
    ('security.mask_bank_details',       'Security',   'Boolean',NULL,NULL,NULL,1,NULL,'true',       'Mask bank account numbers by default and log every view',0,1),
    ('security.four_eyes_on_bank_change','Security',   'Boolean',NULL,NULL,NULL,1,NULL,'true',       'Bank account and IFSC changes need a second person (Enhancement E-05)',0,1);

-- ── Cross-module events. A school opts in per event by adding a config; an event with no config creates
--    nothing and is reported, never silently dropped (BR-INT-04). ─────────────────────────────────────────
INSERT IGNORE INTO `acc_module_events` (`module_key`,`event_code`,`event_name`,`description`,`source_model`,`is_system`,`is_active`) VALUES
    ('FEE','FEE_DEMAND_RAISED',    'Fee demand raised',        'A fee demand is generated for a student. Creates a receivable bill reference (BR-FEE-01).','fee_demands',1,1),
    ('FEE','FEE_COLLECTED',        'Fee collected',            'A fee receipt is recorded. Allocates against open demands (BR-FEE-04).','fee_transactions',1,1),
    ('FEE','FEE_CONCESSION',       'Fee concession granted',   'A concession is sanctioned. Recorded explicitly, never netted silently (BR-CONC-01).','fee_concessions',1,1),
    ('FEE','FEE_DEMAND_CANCELLED', 'Fee demand cancelled',     'A demand is withdrawn. Reverses the receivable; refused if settled (BR-FEE-05).','fee_demands',1,1),
    ('FEE','FEE_REFUND',           'Fee refunded',             'A fee refund is issued to a parent.','fee_refunds',1,1),
    ('LIB','LIB_FINE_LEVIED',      'Library fine levied',      'A late-return or damage fine is raised against a member.','lib_fines',1,1),
    ('LIB','LIB_FINE_COLLECTED',   'Library fine collected',   'A library fine is paid.','lib_fine_payments',1,1),
    ('TPT','TPT_FEE_DEMAND',       'Transport fee demand',     'A transport fee is raised for a route allocation.','tpt_student_route_allocation_jnt',1,1),
    ('TPT','TPT_FEE_COLLECTED',    'Transport fee collected',  'A transport fee is received.','tpt_fee_transactions',1,1),
    ('HST','HST_FEE_DEMAND',       'Hostel fee demand',        'A hostel fee is raised for an allocation.','hst_allocations',1,1),
    ('HST','HST_FEE_COLLECTED',    'Hostel fee collected',     'A hostel fee is received.','hst_fee_transactions',1,1),
    ('PAY','PAY_SALARY_POSTED',    'Payroll posted',           'A payroll run is finalised. Posts gross, deductions and net payable.','pay_payroll_runs',1,1),
    ('PAY','PAY_SALARY_PAID',      'Salary paid',              'Salaries are disbursed against the payable.','pay_disbursements',1,1),
    ('PAY','PAY_STATUTORY_PAID',   'Statutory dues paid',      'PF, ESI or TDS on salary is deposited.','pay_statutory_payments',1,1),
    ('VND','VND_BILL_BOOKED',      'Vendor bill booked',       'A purchase bill is recorded. Creates a payable bill reference.','vnd_bills',1,1),
    ('VND','VND_PAYMENT_MADE',     'Vendor payment made',      'A vendor is paid. Allocates against open bills.','vnd_payments',1,1),
    ('VND','VND_BILL_CANCELLED',   'Vendor bill cancelled',    'A purchase bill is withdrawn.','vnd_bills',1,1);


-- =========================================================================================================
-- END OF SCHEMA
-- =========================================================================================================

SET FOREIGN_KEY_CHECKS = 1;


-- =========================================================================================================
-- CHANGE LOG
-- ---------------------------------------------------------------------------------------------------------
-- 4.5   Completes the v4.4 plan. Sections 1-7 carried forward unchanged; Sections 8-20 written.
--
--       New in Sections 8-20 (47 tables, 22 views; 75 tables in the module overall):
--         Balances     acc_ledger_period_balances · acc_period_closing_balances · acc_opening_balances
--                      acc_fund_balances · acc_bill_reference_balances · acc_period_close_checklist
--         Banking      acc_cheque_registers · acc_cheque_leaves · acc_cheque_transactions
--                      acc_bank_reconciliations · acc_bank_statement_mapping · acc_bank_statement_entries
--                      acc_bank_reconciliation_matches
--         Recurring    acc_recurring_templates · acc_recurring_template_lines
--                      acc_recurring_transaction_log
--         Assets       acc_asset_categories · acc_fixed_assets · acc_depreciation_entries
--                      acc_asset_disposals
--         Claims       acc_expense_claims · acc_expense_claim_lines
--         Budgets      acc_budgets · acc_budget_lines · acc_interest_rules · acc_interest_computations
--                      acc_credit_limit_overrides
--         School       acc_concessions · acc_donations · acc_grants
--         TDS          acc_tds_certificates · acc_tds_deductions · acc_tds_payments
--                      acc_tds_payment_allocations
--         Integration  acc_ledger_mappings · acc_module_events · acc_event_voucher_configs
--                      acc_event_voucher_line_templates · acc_event_processing_log
--                      acc_module_reconciliation
--         Tally        acc_tally_export_logs · acc_tally_ledger_mappings
--         Control      acc_audit_logs · acc_exception_rules · acc_exceptions · acc_assertion_results
--                      acc_settings
--
--       Defects corrected in this half of the file, beyond those v4.4 listed:
--         a. acc_fixed_assets stored current_value and accumulated_depreciation with no maintenance
--            rule — the acc_ledgers.closing_balance defect again. Derived (vw_fixed_asset_register).
--         b. acc_bank_statement_entries matched a statement row with one nullable column, which cannot
--            express propose / confirm / reject / undo. Replaced by acc_bank_reconciliation_matches.
--         c. acc_recurring_transaction_log reused fk_acc_rtl_template and idx_acc_rtl_template from
--            acc_recurring_template_lines. Constraint names are unique per schema; renamed.
--         d. acc_recurring_transaction_log had no uniqueness, so running the scheduler twice in one day
--            posted twice. UNIQUE (template, scheduled_date).
--         e. acc_event_processing_log deliberately had no idempotency key, so replaying a day of events
--            re-posted the day. UNIQUE (event, source_model, source_id, source_event_uid).
--         f. ~45 lines of raw non-comment text after acc_expense_claim_lines — a syntax error. The
--            posting map it described is preserved as comments in the Section 12 header.
--         g. acc_asset_categories, acc_fixed_assets, acc_expense_claims and acc_tally_ledger_mappings
--            used UNIQUE(code, deleted_at), which permits unlimited LIVE duplicates. del_marker.
--         h. acc_ledger_mappings hard-coded a seven-value ENUM of module names, so an eighth module
--            needed a schema change. module_key VARCHAR(10), as everywhere else.
--         i. Generic acc_accounting_status_masters foreign keys on bank reconciliations, expense claims,
--            Tally exports and the event log — a claim's status could be a voucher status. Typed ENUMs.
--         j. acc_voucher_number_sequences (carried forward) had UNIQUE(type, year, period_id) with
--            period_id NULL for non-monthly types, which MySQL does not enforce. period_marker.
--         k. Nine further unique keys spanning nullable columns made NULL-safe with generated markers.
--
--       Deliberately NOT included, per Solution_Design_v1 §17.3: triggers, stored procedures, inventory
--       tables, dead tax regimes, physical partitioning.
--
-- 4.4   Sections 1-7. Corrected the twenty v4.3 defects listed in the file header; introduced periods,
--       bill-wise accounting, funds, currency, numbering sequences and typed statuses.
-- 4.3   Prior version. Did not execute: nine defects prevented the script from running.
-- ---------------------------------------------------------------------------------------------------------
-- AFTER RUNNING THIS FILE
--   1. php artisan acc:rebuild-group-paths      fill acc_account_groups.path and depth
--   2. Create the financial year; PeriodService generates its twelve accounting periods
--   3. Enter opening balances, then finalise them (they must balance — BR-OPEN-02)
--   4. php artisan acc:rebuild-balances         build acc_ledger_period_balances
--   5. php artisan acc:assert --all             every assertion must pass before go-live
--   6. As DBA, per tenant:
--        REVOKE UPDATE, DELETE ON <tenant_db>.acc_audit_logs FROM '<app_user>'@'%';
--      The audit trail is append-only by GRANT, because no MySQL table type enforces it (BR-AUD-03).
-- =========================================================================================================
