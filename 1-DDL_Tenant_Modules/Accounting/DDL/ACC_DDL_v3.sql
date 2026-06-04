-- ============================================================================
-- ACCOUNTING MODULE DDL — acc_ prefix
-- Version: 1.0 — 2026-03-21
-- Tally-Prime inspired voucher-based double-entry system
-- Replaces old 31-table journal-based acc_* schema (unused draft)
-- ============================================================================
-- ============================================================================
-- Section 0 : NEW TABLES
-- ============================================================================

	CREATE TABLE IF NOT EXISTS `acc_accounting_status_masters` (
		`id`            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
		`status_type`   ENUM(`Voucher Status`, `Bank Reconciliation Status`, `Expence Claim Status`, `Tally Export Status`, 'Cross-Module Data Processing Status' ) NOT NULL,
		`code`          VARCHAR(20)     NOT NULL,  -- e.g. 'available', 'occupied', 'maintenance'
		`name`          VARCHAR(100)    NOT NULL,  -- e.g. 'Available', 'Occupied', 'Under Maintenance'
		`is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
		`created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
		`updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at`    TIMESTAMP       NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_accounting_status_code` (`status_type`, `code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Generic master for dynamic status codes across modules; allows adding new statuses without code changes';

	-- Data seed :
		-- Status Type                    Code
		-- --------------------------------------   ---------------------------------------------------------------
		-- `Voucher Status`                         - 'draft', 'posted', 'approved', 'cancelled'
		-- `Bank Reconciliation Status`             - 'Pending', 'In Progress', 'Completed'
		-- `Expence Claim Status`                   - 'Draft', 'Submitted', 'Approved', 'Rejected', 'Paid'
        -- `Tally Export Status`                    - 'Success','Failed','Partial'
		-- 'Cross-Module Data Processing Status'    - 'Pending','Processed','Failed','Skipped'


-- This table will capture Modules detail which will make Voucher entry in accounting Module.
CREATE TABLE IF NOT EXISTS `acc_voucher_modules` (
	`id`            TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code`          VARCHAR(30) NOT NULL, -- 'TRANSPORT', 'HOSTEL', 'LIBRARY', 'ACCOUNTING'
	`name`          VARCHAR(100) NOT NULL, -- 'Transport', 'Hostel & Boarding'
	`module_prefix` VARCHAR(5) NULL, -- Source Module Tables Prefix (`tpt_`, `lib_`, etc.)
	`icon`          VARCHAR(50) NULL, -- for sidebar/menu rendering
	`is_active`     TINYINT(1) DEFAULT 1,
	`sequence`      TINYINT UNSIGNED DEFAULT 0, -- display order in menu
	`created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`    TIMESTAMP NULL,
	UNIQUE KEY `uq_sys_module_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- This table will capture Category detail for all the Modules. Voucher entry in accounting Module from other Modules will use these Categories.
CREATE TABLE IF NOT EXISTS `acc_voucher_category` (
	`id`                TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`voucher_module_id` TINYINT UNSIGNED NOT NULL, -- FK → sys_modules
	`code`              VARCHAR(30) NOT NULL, -- 'TRANSPORT_FINE', 'TRANSPORT_DAMAGE_FINE', 'HOSTEL_FEE', 'HOSTEL_DAMAGE_FINE', 'LIBRARY_FINE'
	`name`              VARCHAR(100) NOT NULL, -- 'Transport Fine', 'Hostel Fee'
	`module_table_name` VARCHAR(60) NULL, -- Source Module Table name (`tpt_student_fine_detail`, `lib_fines`, etc.)
	`acc_ledger_id`     INT UNSIGNED NULL, -- FK → acc_ledgers.id (What ledger account will be used to make entry in Accounting Module for this category)
	`is_system`         TINYINT(1) DEFAULT 1,
	`is_active`         TINYINT(1) DEFAULT 1,
	`created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_acc_vc_code` (`code`),
	CONSTRAINT `fk_vc_module` FOREIGN KEY (`module_id`) REFERENCES `acc_voucher_modules`(`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_vc_ledger` FOREIGN KEY (`acc_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition :
-- Dropdown for `module_table_name` will show all the tables start with module_prefix (e.g., `tpt_`, `lib_`, etc.), metioned in `acc_voucher_modules.module_prefix`



-- ============================================================================
-- DOMAIN 1: CORE ACCOUNTING (12 tables)
-- ============================================================================

-- 1. Financial Years
CREATE TABLE IF NOT EXISTS `acc_financial_years` (
	`id`            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`          VARCHAR(50) NOT NULL COMMENT 'e.g., 2025-26',
	`start_date`    DATE NOT NULL 'Financial year start (April 1)',
	`end_date`      DATE NOT NULL COMMENT 'Financial year end (March 31)',
	`is_locked`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Prevents edits when locked',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`    INT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_fy_active` (`is_active`),
	INDEX `idx_acc_fy_dates` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Account Groups (Tally's 28 predefined + custom)
CREATE TABLE IF NOT EXISTS `acc_account_groups` (
	`id`                    MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`                  VARCHAR(100) NOT NULL COMMENT 'Group name',
	`code`                  VARCHAR(30) NOT NULL COMMENT 'Unique group code e.g., A01, L02',
	`alias`                 VARCHAR(100) NULL COMMENT 'Alternative display name',
	`parent_id`             MEDIUMINT UNSIGNED NULL COMMENT 'Self-referencing for hierarchy',
	`nature`                ENUM('Asset','Liability','Equity','Income','Expense') NOT NULL COMMENT 'Account nature',
	`affects_gross_profit`  TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Direct vs Indirect classification',
	`is_system`             TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'true = seeded, cannot delete',
	`is_subledger`          TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Behaves as sub-ledger',
	`ordinal`               SMALLINT NOT NULL DEFAULT 0 COMMENT 'Display order in reports',
	`is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`            INT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`            TIMESTAMP NULL DEFAULT NULL,
	`updated_at`            TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`            TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_ag_code` (`code`, `deleted_at`),
	INDEX `idx_acc_ag_parent` (`parent_id`),
	INDEX `idx_acc_ag_nature` (`nature`),
	INDEX `idx_acc_ag_system` (`is_system`),
	CONSTRAINT `fk_acc_ag_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_account_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- If `is_system` = 1, then that ledger cannot be deleted. This is for critical groups like Current Assets, Direct Expenses, etc. that are essential for system integrity.
    --
    -- The 5 Fundamental Account Natures
    -- ---------------------------------
    -- The basic accounting equation is:
    -- Assets = Liabilities + Equity
    -- Equity = Capital + Revenue − Expenses
    -- Nature : What it represents	Examples
    -- --------------------------------------------------------------------------
    -- Asset : What the school owns	Cash, Bank, Fee Receivable, Furniture
    -- Liability : What the school owes	Vendor Payables, Loans, Advance Fees
    -- Equity : Owners' / Trustees' stake	School Capital Fund, Surplus/Deficit A/c
    -- Income : What the school earns	Tuition Fee, Transport Fee, Donations
    -- Expense : What the school spends	Salary, Electricity, Maintenance


-- 3. Ledgers (Individual accounts)
CREATE TABLE IF NOT EXISTS `acc_ledgers` (
	`id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`                      VARCHAR(150) NOT NULL COMMENT 'Ledger name',
	`code`                      VARCHAR(30) NULL COMMENT 'Unique ledger code',
	`alias`                     VARCHAR(150) NULL COMMENT 'Alternative name',
	`account_group_id`          MEDIUMINT UNSIGNED NOT NULL COMMENT 'FK → acc_account_groups',
	`opening_balance`           DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Opening balance amount',
	`opening_balance_type`      ENUM('Dr','Cr') NULL COMMENT 'Debit or Credit opening',
	`is_bank_account`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Bank account flag',
	`bank_name`                 VARCHAR(100) NULL COMMENT 'Bank name if bank account',
	`bank_account_number`       VARCHAR(50) NULL COMMENT 'Bank account number',
	`ifsc_code`                 VARCHAR(30) NULL COMMENT 'Bank IFSC code',
	`is_cash_account`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Cash account flag',
	`allow_reconciliation`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Enable bank reconciliation',
	`is_system`                 TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'P&L A/c, Cash A/c etc. — cannot delete',
	`student_id`                INT UNSIGNED NULL COMMENT 'FK → std_students (auto-ledger for student debtors)',
	`employee_id`               INT UNSIGNED NULL COMMENT 'FK → sch_employees (auto-ledger for salary payable)',
	`vendor_id`                 INT UNSIGNED NULL COMMENT 'FK → vnd_vendors (auto-ledger for vendor creditors)',
	-- `gst_registration_type`     VARCHAR(30) NULL COMMENT 'Regular, Composition, etc.', -- To calculate and claim Input Tax Credit (ITC). See detail in (Businessh_Conditions.md)
   `gst_registration_type`     ENUM('Regular','Composition','Unregistered','SEZ','Consumer') NULL, -- To calculate and claim Input Tax Credit (ITC). See detail in (Businessh_Conditions.md)
	`gstin`                     VARCHAR(20) NULL COMMENT 'GST number',
	`pan`                       VARCHAR(15) NULL COMMENT 'PAN number',
	`address`                   TEXT NULL COMMENT 'Ledger address',
	`is_active`                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`                INT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`                TIMESTAMP NULL DEFAULT NULL,
	`updated_at`                TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`                TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_ledger_group` (`account_group_id`),
	INDEX `idx_acc_ledger_student` (`student_id`),
	INDEX `idx_acc_ledger_employee` (`employee_id`),
	INDEX `idx_acc_ledger_vendor` (`vendor_id`),
	INDEX `idx_acc_ledger_bank` (`is_bank_account`),
	INDEX `idx_acc_ledger_active` (`is_active`),
	CONSTRAINT `fk_acc_ledger_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- If `is_system` = 1, then that ledger cannot be deleted. This is for critical ledgers like Cash Account, Profit & Loss Account, etc. that are essential for system integrity.

-- 4. Voucher Types
CREATE TABLE IF NOT EXISTS `acc_voucher_types` (
	`id`                  TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`                VARCHAR(80) NOT NULL COMMENT 'e.g., Payment Voucher',
	`code`                VARCHAR(20) NOT NULL COMMENT 'PAYMENT, RECEIPT, CONTRA, JOURNAL, etc.',
   -- `category`         ENUM('Accounting','Inventory','Payroll','Order') NOT NULL COMMENT 'Domain category',
	`voucher_category_id` TINYINT UNSIGNED NOT NULL,  -- FK → acc_voucher_category
	`prefix`              VARCHAR(5) NULL COMMENT 'Voucher number prefix e.g., PAY-, RCV-',
	`auto_numbering`.     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Auto-increment enabled',
	`last_number`         INT NOT NULL DEFAULT 0 COMMENT 'Current voucher counter',
	`is_system`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Cannot delete seeded types',
	`is_active`           TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`          INT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`          TIMESTAMP NULL DEFAULT NULL,
	`updated_at`          TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`          TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_vt_code` (`code`, `deleted_at`),
	INDEX `idx_acc_vt_category` (`category`),
	CONSTRAINT `fk_vt_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- If `is_system` = 1, then that voucher type cannot be deleted.

-- 7. Cost Centers (Department/Wing/Activity)
CREATE TABLE IF NOT EXISTS `acc_cost_centers` (
	`id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`          VARCHAR(100) NOT NULL COMMENT 'e.g., Primary Wing, Transport',
	`code`          VARCHAR(20) NULL COMMENT 'Cost center code',
	`parent_id`     BIGINT UNSIGNED NULL COMMENT 'Self-referencing hierarchy',
	`category`      VARCHAR(50) NULL COMMENT 'Department, Activity, Project',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_cc_parent` (`parent_id`),
	CONSTRAINT `fk_acc_cc_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- 5. Vouchers (THE HEART — every transaction is a voucher)
CREATE TABLE IF NOT EXISTS `acc_vouchers` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`voucher_prefix`    VARCHAR(5) NULL COMMENT 'Snapshot of prefix from voucher type for historical reference',
	`voucher_number`    INT UNSIGNED NOT NULL COMMENT 'Auto-generated sequential number per voucher type and FY',
	`voucher_type_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_types',
	`financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
	`date`              DATE NOT NULL COMMENT 'Transaction date',
	`reference_number`  VARCHAR(100) NULL COMMENT 'Cheque no, receipt no, etc.',
	`reference_date`    DATE NULL COMMENT 'Cheque date, etc.',
	`narration`         TEXT NULL COMMENT 'Transaction description',
	`total_amount`      DECIMAL(15,2) NOT NULL COMMENT 'Total voucher amount',
	`is_post_dated`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Post-dated cheque flag',
	`is_optional`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Memorandum voucher',
	`is_cancelled`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Cancelled flag',
	`cancelled_reason`  TEXT NULL COMMENT 'Cancellation reason',
	`cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers (header-level)',
	--`source_module`     ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll','Manual') NULL COMMENT 'Source module for integration',
	`source_module`     BIGINT UNSIGNED NULL COMMENT 'Source module for integration', -- FK to `acc_voucher_modules`
	`source_type`       VARCHAR(100) NULL COMMENT 'Polymorphic model: PayrollRun, FeeTransaction, GRN, etc.',
	`source_id`         BIGINT UNSIGNED NULL COMMENT 'Polymorphic source ID',
	`status`            INT UNSIGNED NOT NULL COMMENT 'Voucher Status', -- FK to `acc_accounting_status_masters`
	`approved_by`       BIGINT UNSIGNED NULL COMMENT 'FK → sys_users (approver)',
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`        TIMESTAMP NULL DEFAULT NULL,
	`updated_at`        TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_voucher_number_fy` (`financial_year_id`, `voucher_prefix`, `voucher_number`),
	INDEX `idx_acc_voucher_type` (`voucher_type_id`),
	INDEX `idx_acc_voucher_fy` (`financial_year_id`),
	INDEX `idx_acc_voucher_date` (`date`),
	INDEX `idx_acc_voucher_status` (`status`),
	INDEX `idx_acc_voucher_source` (`source_module`, `source_type`, `source_id`),
	INDEX `idx_acc_voucher_cost` (`cost_center_id`),
	CONSTRAINT `fk_acc_voucher_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_voucher_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_voucher_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_acc_voucher_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- If `is_optional` = 1, then that transaction should be consider in financial reports but should not be posted to ledgers until explicitly approved and marked as non-optional. 
-- This allows creating draft vouchers for future transactions or estimates without affecting current financials.

-- 6. Voucher Items (Dr/Cr line items)
CREATE TABLE IF NOT EXISTS `acc_voucher_items` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`voucher_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_vouchers',
	`ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
	`type`              ENUM('debit','credit') NOT NULL COMMENT 'Dr or Cr entry',
	`amount`            DECIMAL(15,2) NOT NULL COMMENT 'Line item amount',
	`narration`         VARCHAR(500) NULL COMMENT 'Per-ledger narration',
	`cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers (line-level override)',
	`bill_reference`    VARCHAR(100) NULL COMMENT 'Against invoice/bill reference',
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`        TIMESTAMP NULL DEFAULT NULL,
	`updated_at`        TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_vi_voucher` (`voucher_id`),
	INDEX `idx_acc_vi_ledger` (`ledger_id`),
	INDEX `idx_acc_vi_type` (`type`),
	INDEX `idx_acc_vi_cost` (`cost_center_id`),
	CONSTRAINT `fk_acc_vi_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_acc_vi_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_vi_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- 8. Budgets
CREATE TABLE IF NOT EXISTS `acc_budgets` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
	`cost_center_id`    BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_cost_centers',
	`ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
	`budgeted_amount`   DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Allocated budget amount',
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`        TIMESTAMP NULL DEFAULT NULL,
	`updated_at`        TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_budget` (`financial_year_id`, `cost_center_id`, `ledger_id`),
	INDEX `idx_acc_budget_cc` (`cost_center_id`),
	INDEX `idx_acc_budget_ledger` (`ledger_id`),
	CONSTRAINT `fk_acc_budget_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_budget_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_budget_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Tax Rates
CREATE TABLE IF NOT EXISTS `acc_tax_rates` (
	`id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`          VARCHAR(100) NOT NULL COMMENT 'e.g., CGST 9%',
	`rate`          DECIMAL(5,2) NOT NULL COMMENT 'Tax rate percentage',
	`type`          ENUM('CGST','SGST','IGST','Cess') NOT NULL COMMENT 'Tax type',
	`hsn_sac_code`  VARCHAR(20) NULL COMMENT 'HSN/SAC code',
	`is_interstate` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Interstate supply flag',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_tax_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Ledger Mappings (Cross-module)
CREATE TABLE IF NOT EXISTS `acc_ledger_mappings` (
	`id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`ledger_id`     BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
	`source_module` ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll') NOT NULL COMMENT 'Source module',
	`source_type`   VARCHAR(100) NULL COMMENT 'e.g., FeeHead, PayHead, Route, Stoppage',
	`source_id`     BIGINT UNSIGNED NOT NULL COMMENT 'Source entity ID',
	`description`   VARCHAR(255) NULL COMMENT 'Human-readable mapping description',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_lm_combo` (`ledger_id`, `source_module`, `source_type`, `source_id`),
	INDEX `idx_acc_lm_source` (`source_module`, `source_type`, `source_id`),
	CONSTRAINT `fk_acc_lm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Recurring Templates
CREATE TABLE IF NOT EXISTS `acc_recurring_templates` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`              VARCHAR(150) NOT NULL COMMENT 'Template name',
	`voucher_type_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_types',
	`frequency`         ENUM('Daily','Weekly','Monthly','Quarterly','Yearly') NOT NULL COMMENT 'Recurrence frequency',
	`start_date`        DATE NOT NULL COMMENT 'Start posting from',
	`end_date`          DATE NULL COMMENT 'Stop posting after (NULL = indefinite)',
	`day_of_month`      TINYINT NULL COMMENT 'Day to post for monthly frequency',
	`narration`         TEXT NULL COMMENT 'Default narration for generated vouchers',
	`total_amount`      DECIMAL(15,2) NOT NULL COMMENT 'Template total (must balance Dr=Cr)',
	`last_posted_date`  DATE NULL COMMENT 'Last auto-post date',
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`        TIMESTAMP NULL DEFAULT NULL,
	`updated_at`        TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_rt_type` (`voucher_type_id`),
	CONSTRAINT `fk_acc_rt_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Recurring Template Lines
CREATE TABLE IF NOT EXISTS `acc_recurring_template_lines` (
	`id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`recurring_template_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_recurring_templates',
	`ledger_id`             BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
	`type`                  ENUM('debit','credit') NOT NULL COMMENT 'Dr or Cr',
	`amount`                DECIMAL(15,2) NOT NULL COMMENT 'Line amount',
	`narration`             VARCHAR(500) NULL COMMENT 'Per-line narration',
	`is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`            TIMESTAMP NULL DEFAULT NULL,
	`updated_at`            TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`            TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_rtl_template` (`recurring_template_id`),
	INDEX `idx_acc_rtl_ledger` (`ledger_id`),
	CONSTRAINT `fk_acc_rtl_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates` (`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_acc_rtl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN 2: BANKING (2 tables)
-- ============================================================================

-- 13. Bank Reconciliations
CREATE TABLE IF NOT EXISTS `acc_bank_reconciliations` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (bank account)',
	`statement_date`    DATE NOT NULL COMMENT 'Bank statement date',
	`closing_balance`   DECIMAL(15,2) NOT NULL COMMENT 'Closing balance per bank statement',
	`statement_path`    VARCHAR(255) NULL COMMENT 'Uploaded statement file path',
	`status`            INT UNSIGNED NOT NULL COMMENT 'Reconciliation status', -- FK to `acc_accounting_status_masters`,
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`        TIMESTAMP NULL DEFAULT NULL,
	`updated_at`        TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_br_ledger` (`ledger_id`),
	INDEX `idx_acc_br_date` (`statement_date`),
	CONSTRAINT `fk_acc_br_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_br_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. Bank Statement Entries
CREATE TABLE IF NOT EXISTS `acc_bank_statement_entries` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reconciliation_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_bank_reconciliations',
    `transaction_date`          DATE NOT NULL COMMENT 'Bank transaction date',
    `description`               VARCHAR(500) NULL COMMENT 'Transaction description from bank',
    `reference`                 VARCHAR(255) NULL COMMENT 'Bank reference number',
    `debit`                     DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Debit amount (withdrawal)',
    `credit`                    DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Credit amount (deposit)',
    `balance`                   DECIMAL(15,2) NULL COMMENT 'Running balance per statement',
    `is_matched`                TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether matched to a voucher item',
    `matched_voucher_item_id`   BIGINT UNSIGNED NULL COMMENT 'FK → acc_voucher_items (matched entry)',
    `matched_at`                TIMESTAMP NULL COMMENT 'When the match was made',
    `matched_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users (who matched)',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`                TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_bse_recon` (`reconciliation_id`),
    INDEX `idx_acc_bse_matched` (`is_matched`),
    INDEX `idx_acc_bse_vi` (`matched_voucher_item_id`),
    INDEX `idx_acc_bse_date` (`transaction_date`),
    CONSTRAINT `fk_acc_bse_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bse_vi` FOREIGN KEY (`matched_voucher_item_id`) REFERENCES `acc_voucher_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN 3: FIXED ASSETS (3 tables)
-- ============================================================================

-- 15. Asset Categories
CREATE TABLE IF NOT EXISTS `acc_asset_categories` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(100) NOT NULL COMMENT 'Category name e.g., Furniture',
    `code`                  VARCHAR(20) NOT NULL COMMENT 'Category code',
    `depreciation_method`   ENUM('SLM','WDV') NOT NULL COMMENT 'Straight Line / Written Down Value',
    `depreciation_rate`     DECIMAL(5,2) NOT NULL COMMENT 'Annual depreciation rate %',
    `useful_life_years`     INT NULL COMMENT 'Useful life in years',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_assetcat_code` (`code`, `deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. Fixed Assets
CREATE TABLE IF NOT EXISTS `acc_fixed_assets` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                      VARCHAR(150) NOT NULL COMMENT 'Asset name',
    `asset_code`                VARCHAR(50) NOT NULL COMMENT 'Asset identification code',
    `asset_category_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_asset_categories',
    `purchase_date`             DATE NOT NULL COMMENT 'Date of purchase',
    `purchase_cost`             DECIMAL(15,2) NOT NULL COMMENT 'Original purchase cost',
    `salvage_value`             DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Estimated residual value',
    `current_value`             DECIMAL(15,2) NOT NULL COMMENT 'Current book value',
    `accumulated_depreciation`  DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Total depreciation to date',
    `location`                  VARCHAR(100) NULL COMMENT 'Physical location of asset',
    `vendor_id`                 BIGINT UNSIGNED NULL COMMENT 'FK → vnd_vendors (supplier)',
    `voucher_id`                BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (purchase voucher)',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`                TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fa_code` (`asset_code`, `deleted_at`),
    INDEX `idx_acc_fa_category` (`asset_category_id`),
    INDEX `idx_acc_fa_vendor` (`vendor_id`),
    INDEX `idx_acc_fa_voucher` (`voucher_id`),
    CONSTRAINT `fk_acc_fa_category` FOREIGN KEY (`asset_category_id`) REFERENCES `acc_asset_categories` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. Depreciation Entries
CREATE TABLE IF NOT EXISTS `acc_depreciation_entries` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fixed_asset_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_fixed_assets',
    `financial_year_id`     BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
    `depreciation_date`     DATE NOT NULL COMMENT 'Date of depreciation entry',
    `depreciation_amount`   DECIMAL(15,2) NOT NULL COMMENT 'Depreciation amount for this period',
    `voucher_id`            BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (depreciation journal)',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`            BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_de_asset` (`fixed_asset_id`),
    INDEX `idx_acc_de_fy` (`financial_year_id`),
    INDEX `idx_acc_de_voucher` (`voucher_id`),
    CONSTRAINT `fk_acc_de_asset` FOREIGN KEY (`fixed_asset_id`) REFERENCES `acc_fixed_assets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_de_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_de_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN 4: EXPENSE CLAIMS (2 tables)
-- ============================================================================

-- 18. Expense Claims
CREATE TABLE IF NOT EXISTS `acc_expense_claims` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `claim_number`  VARCHAR(50) NOT NULL COMMENT 'Auto-generated claim number',
    `employee_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → sch_employees (existing table)',
    `claim_date`    DATE NOT NULL COMMENT 'Date of claim submission',
    `total_amount`  DECIMAL(15,2) NOT NULL COMMENT 'Total claim amount',
    -- `status`        ENUM('Draft','Submitted','Approved','Rejected','Paid') NOT NULL DEFAULT 'Draft' COMMENT 'Claim workflow status',
	`status`         INT UNSIGNED NOT NULL COMMENT 'Claim workflow status', -- FK to `acc_accounting_status_masters`
    `approved_by`   BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `approved_at`   TIMESTAMP NULL COMMENT 'Approval timestamp',
    `voucher_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (payment voucher on approval)',
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`    TIMESTAMP NULL DEFAULT NULL,
    `updated_at`    TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ec_number` (`claim_number`, `deleted_at`),
    INDEX `idx_acc_ec_employee` (`employee_id`),
    INDEX `idx_acc_ec_status` (`status`),
    INDEX `idx_acc_ec_voucher` (`voucher_id`),
    CONSTRAINT `fk_acc_ec_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL,
	 CONSTRAINT `fk_acc_ec_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE RESTRICT,
	 CONSTRAINT `fk_acc_ec_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. Expense Claim Lines
CREATE TABLE IF NOT EXISTS `acc_expense_claim_lines` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `expense_claim_id`  BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_expense_claims',
    `expense_date`      DATE NOT NULL COMMENT 'Date of expense',
    `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (expense category)',
    `description`       VARCHAR(255) NOT NULL COMMENT 'Expense description',
    `amount`            DECIMAL(15,2) NOT NULL COMMENT 'Expense amount',
    `tax_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'Tax on expense',
    `receipt_path`      VARCHAR(255) NULL COMMENT 'Uploaded receipt file path',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ecl_claim` (`expense_claim_id`),
    INDEX `idx_acc_ecl_ledger` (`ledger_id`),
    CONSTRAINT `fk_acc_ecl_claim` FOREIGN KEY (`expense_claim_id`) REFERENCES `acc_expense_claims` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ecl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DOMAIN 5: TALLY INTEGRATION (2 tables)
-- ============================================================================

-- 20. Tally Export Logs
CREATE TABLE IF NOT EXISTS `acc_tally_export_logs` (
	`id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`export_type`   ENUM('Ledgers','Vouchers','Inventory') NOT NULL COMMENT 'What was exported',
	`export_date`   DATETIME NOT NULL COMMENT 'When export was run',
	`file_name`     VARCHAR(255) NOT NULL COMMENT 'Generated file name',
	`exported_by`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → sys_users',
	`start_date`    DATE NULL COMMENT 'Export date range start',
	`end_date`      DATE NULL COMMENT 'Export date range end',
	`record_count`  INT NULL COMMENT 'Number of records exported',
   -- `status`        ENUM('Success','Failed','Partial') NOT NULL COMMENT 'Export result',
	`status`         INT UNSIGNED NOT NULL COMMENT 'Tally Export Status', -- FK to `acc_accounting_status_masters`
	`error_log`     TEXT NULL COMMENT 'Error details if failed',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_by`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_tel_type` (`export_type`),
	INDEX `idx_acc_tel_date` (`export_date`),
	INDEX `idx_acc_tel_by` (`exported_by`),
	CONSTRAINT `fk_acc_tel_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 21. Tally Ledger Mappings
CREATE TABLE IF NOT EXISTS `acc_tally_ledger_mappings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (our application ledger)',
    `tally_ledger_name` VARCHAR(200) NOT NULL COMMENT 'Exact Tally ledger name for export/import',
    `tally_group_name`  VARCHAR(200) NULL COMMENT 'Tally parent group name',
    `tally_alias`       VARCHAR(200) NULL COMMENT 'Tally alias if any',
    `mapping_type`      ENUM('auto','manual') NOT NULL DEFAULT 'auto' COMMENT 'Auto=seeded, manual=user-configured',
    `sync_direction`    ENUM('export_only','import_only','bidirectional') NOT NULL DEFAULT 'export_only' COMMENT 'Sync direction',
    `last_synced_at`    TIMESTAMP NULL COMMENT 'Last successful sync timestamp',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
    `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tlm_ledger` (`ledger_id`, `deleted_at`),
    CONSTRAINT `fk_acc_tlm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================
CREATE INDEX idx_acc_voucher_composite ON `acc_vouchers` (`date`, `financial_year_id`, `status`);
CREATE INDEX idx_acc_vi_ledger_date ON `acc_voucher_items` (`ledger_id`, `created_at`);
CREATE INDEX idx_acc_bse_recon_matched ON `acc_bank_statement_entries` (`reconciliation_id`, `is_matched`);



-- ============================================================================
-- ACCOUNTING MODULE ENHANCEMENT — Generic Cross-Module Event Ledger Mapping
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
    `voucher_type_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_types. Typically RECEIPT for income, JOURNAL for internal transfers',
    `cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers (optional default cost center for vouchers from this event)',
    `is_auto_post`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = immediately post to ledgers; 0 = create as draft (status=draft in acc_vouchers)',
    `requires_approval` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = set voucher status to draft and route to approver; overrides is_auto_post if both = 1',
    `narration_template` VARCHAR(500) NULL COMMENT 'Voucher narration with placeholders: {student_name}, {amount}, {date}, {event_name}, {reference_no}, {module_ref}',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'Soft active flag',
    `created_by`        BIGINT UNSIGNED NULL  COMMENT 'FK → sys_users',
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_acc_evc_event`       (`module_event_id`, `deleted_at`) COMMENT 'One active config per event',
    INDEX `idx_acc_evc_voucher_type`     (`voucher_type_id`),
    INDEX `idx_acc_evc_cost_center`      (`cost_center_id`),
    INDEX `idx_acc_evc_active`           (`is_active`),
    CONSTRAINT `fk_acc_evc_event` FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_vtype` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
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
    `event_voucher_config_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_event_voucher_configs',
    `sequence`                  TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Line order within the voucher (1-based). Determines display order in voucher.',
    `entry_type`                ENUM('debit','credit') NOT NULL COMMENT 'Debit or Credit side of the double-entry line',
    -- ── Ledger Resolution ──────────────────────────────────────────────────
    `ledger_resolver`           ENUM('fixed','student_ledger','vendor_ledger','employee_ledger') NOT NULL DEFAULT 'fixed' COMMENT 'Strategy to resolve which ledger to post this line against at runtime',
    `ledger_id`                 BIGINT UNSIGNED NULL COMMENT 'FK → acc_ledgers. Required when ledger_resolver = fixed. NULL for dynamic resolvers.',
    -- ── Amount Resolution ──────────────────────────────────────────────────
    `amount_resolver`           ENUM('from_source','fixed_amount','from_payload') NOT NULL DEFAULT 'from_source' COMMENT 'Strategy to resolve the line amount at runtime',
    `source_amount_field`       VARCHAR(100) NULL COMMENT 'Column name in source model to read amount from. e.g., amount, fine_amount, fare, paid_amount. Used when amount_resolver = from_source.',
    `fixed_amount`              DECIMAL(15,2) NULL COMMENT 'Hard-coded amount used when amount_resolver = fixed_amount',
    `narration`                 VARCHAR(500) NULL COMMENT 'Per-line narration. Can use same placeholders as narration_template. Overrides header narration for this line.',
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
    CONSTRAINT `fk_acc_evlt_config` FOREIGN KEY (`event_voucher_config_id`) REFERENCES `acc_event_voucher_configs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_evlt_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Dr/Cr line templates for event-triggered vouchers. Supports fixed and dynamic ledger/amount resolution.';

-- conditions:
-- Fixed - Use ledger_id column directly
-- student_ledger - Resolve from acc_ledgers WHERE student_id = source.student_id
-- vendor_ledger - Resolve from acc_ledgers WHERE vendor_id = source.vendor_id
-- employee_ledger - Resolve from acc_ledgers WHERE employee_id = source.employee_id
-- ----------
-- for `amount_resolver` 
--  - from_source - Read source_amount_field column value from the source record
--  - fixed_amount - Always use fixed_amount value
--  - from_payload - Use amount from event payload JSON


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
	`source_model`      VARCHAR(100) NOT NULL COMMENT 'Source table name (denormalized from event for fast querying without join)',
	`source_id`         BIGINT UNSIGNED NOT NULL COMMENT 'Primary key of the triggering source record (e.g., lib_fines.id, tpt_student_route_allocation_jnt.id)',
	`payload_json`      JSON NULL COMMENT 'Snapshot of critical fields from the source record at event time. Preserves audit integrity.',
	`voucher_id`        BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers. Set after successful processing. NULL if failed or skipped.',
	-- `status`            ENUM('Pending','Processed','Failed','Skipped') NOT NULL DEFAULT 'Pending' COMMENT 'Pending=queued, Processed=voucher created, Failed=error, Skipped=no config or duplicate guard',
	`status`            INT UNSIGNED NOT NULL COMMENT 'Pending=queued, Processed=voucher created, Failed=error, Skipped=no config or duplicate guard', -- FK to `acc_accounting_status_masters`
	`error_message`     TEXT NULL COMMENT 'Error detail when status = failed. Includes stack trace or validation message.',
	`retry_count`       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of automated retry attempts. Used by job scheduler to cap retries.',
	`processed_at`      TIMESTAMP NULL COMMENT 'Timestamp when the event was successfully processed (voucher created)',
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'Soft active flag',
	`created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users. The user whose action triggered the event, or system user if automated.',
	`created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_epl_event`       (`module_event_id`),
	INDEX `idx_acc_epl_source`      (`source_model`, `source_id`) COMMENT 'Lookup: has this source record already been processed?',
	INDEX `idx_acc_epl_voucher`     (`voucher_id`),
	INDEX `idx_acc_epl_status`      (`status`),
	INDEX `idx_acc_epl_pending`     (`status`, `retry_count`) COMMENT 'Job queue index: find pending/failed events to retry',
	CONSTRAINT `fk_acc_epl_event` FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_epl_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_acc_epl_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail of all cross-module events received and their voucher processing outcome';


-- ======================================================================================================================================================
-- Change Log
-- ======================================================================================================================================================
-- Add New Tables : `acc_accounting_status_masters`, `acc_voucher_modules`, `acc_voucher_category`
-- Chnage Table: `acc_account_groups` Field (`nature` ENUM('Asset','Liability','Equity','Income','Expense') NOT NULL,)
-- Change Table : `acc_ledgers` Field (   `gst_registration_type`     ENUM('Regular','Composition','Unregistered','SEZ','Consumer') NULL,)
-- Tabel : `acc_voucher_types`; Remove - `category` ENUM('Accounting','Inventory','Payroll','Order') NOT NULL COMMENT 'Domain category',
-- Tabel : `acc_voucher_types`; Add - `voucher_category_id`  TINYINT UNSIGNED NOT NULL,
-- Table : `acc_voucher_types`; Add - CONSTRAINT `fk_vt_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT
-- Table `acc_vouchers`; Remove - `category` ENUM('Accounting','Inventory','Payroll','Order') NOT NULL COMMENT 'Domain category',
-- Table `acc_vouchers`; Add - `voucher_category_id`  TINYINT UNSIGNED NOT NULL,
-- Table `acc_vouchers`; Add - CONSTRAINT `fk_voucher_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT
	






-- Change Tbale: acc_event_processing_log
-- 1. Add `status` column to `acc_event_processing_log`