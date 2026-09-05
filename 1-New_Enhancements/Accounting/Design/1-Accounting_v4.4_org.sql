-- =========================================================================================================
-- PRIME-AI — ACCOUNTING MODULE DDL
-- Prefix    : acc_
-- Version   : 4.4
-- Supersedes: Accounting_DDL_v4.3.sql
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
--      8  Balances: opening, ledger-period, fund, period close
--      9  Banking: reconciliation, statements, matches, cheques
--     10  Recurring vouchers
--     11  Fixed assets and depreciation
--     12  Expense claims
--     13  Budgets
--     14  School-specific: concessions, donations, grants
--     15  TDS
--     16  Cross-module integration
--     17  Tally export
--     18  Control: audit, exceptions, assertions
--     19  Views
--     20  Seed data
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
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vns` (`voucher_type_id`,`financial_year_id`,`period_id`),
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
