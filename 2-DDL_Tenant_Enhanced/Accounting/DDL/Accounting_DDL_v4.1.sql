-- ============================================================================
-- ACCOUNTING MODULE DDL — acc_ prefix
-- Version: 4.1 — 2026-08-30
-- Tally-Prime inspired voucher-based double-entry system
-- Replaces old 31-table journal-based acc_* schema (unused draft)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Reference Tables from Global Database
-- ----------------------------------------------------------------------------


-- Table `acc_voucher_modules` moved to 'global_db' as `glb_app_modules`
-- ---------------------------------------------------------------------

-- This table belongs to global_db. Here it is placed only for reference purpose.
-- This table will capture Modules detail of entire application, which will be used in application development.
-- Screens of this table will not be available for Tenant to modify. This will be completely managed by Super Admin.
CREATE TABLE IF NOT EXISTS `glb_app_modules` (
	`key`           VARCHAR(10) NOT NULL,  -- Can not be changed by User (Tenant) e.g. 'ACC','TPT',...
	`ordinal`       SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- display order in menu
	`code`          VARCHAR(30) NOT NULL,  -- 'ACCOUNTING', 'TRANSPORT', 'HOSTEL', 'LIBRARY', 'STUDENT_FEE' etc.
	`name`          VARCHAR(100) NOT NULL, -- 'Accounting', 'Transport', 'Hostel & Boarding', 'Library', 'Student Fee', etc.
	`module_prefix` VARCHAR(5) NULL, -- Source Module Tables Prefix (`tpt_`, `lib_`, etc.)
	`is_system`     TINYINT(1) NOT NULL DEFAULT 0, -- 1 = For System use, can not be deleted/edited.
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1,
	`created_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`    TIMESTAMP NULL,
	PRIMARY KEY (`key`),
	UNIQUE KEY `uq_sys_module_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Data Seeder:
	-- Key | Ordinal | Code 				| Name											| Module_Prefix | Is_System | Is_Active
	---------------------------------------------------------------------------------------------------------------------------
	-- ACC | 1 		  | ACCOUNTING			| Accounting									| acc_ 			 | 1         | 1
	-- ACC | 2 		  | TRANSPORT			| Transport										| tpt_ 			 | 0         | 1
	-- ACC | 3 		  | HOSTEL				| Hostel & Boarding							| hst_ 			 | 0         | 1
	-- 


-- This table belongs to global_db. Here it is placed only for reference purpose.
-- This table is to store the global Settings detail for all the Modules. This will be used in application development.
-- Screens of this table will not be available for Tenant to modify. This will be completely managed by Super Admin.
  CREATE TABLE IF NOT EXISTS `glb_app_config` (
    `id`                MEDIUMINT unsigned NOT NULL AUTO_INCREMENT,
    `module_id`         VARCHAR(10) NOT NULL,         -- FK to glb_app_modules.key
    `key`               varchar(150) NOT NULL,        -- Can not changed by user (He can edit other fields only but not KEY)
    `key_name`          varchar(255) NOT NULL,        -- Can be Changed by user
    `ordinal`           SMALLINT UNSIGNED NOT NULL DEFAULT '1',
    `value`             varchar(512) NOT NULL,        -- Can be Changed by user
    `value_type`        ENUM('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'TIME', 'DATETIME', 'JSON') NOT NULL,
    `description`       varchar(255) NOT NULL,
    `additional_info`   JSON DEFAULT NULL,
    `tenant_can_modify` tinyint(1) NOT NULL DEFAULT '0',    -- Tenant can modify only if 1
    `mandatory`         tinyint(1) NOT NULL DEFAULT '1',    -- Is it mandatory to set this value
    `used_by_app`       tinyint(1) NOT NULL DEFAULT '1',    -- Is it used by app
    `is_active`         tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at`        timestamp NULL DEFAULT NULL,
    `created_at`        timestamp NULL DEFAULT NULL,
    `updated_at`        timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_settings_ordinal` (`ordinal`),
    UNIQUE KEY `uq_settings_key` (`key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Data Seeder:
	-- Model | Key 								| Key	Name															| Type		| Value
	-----------------------------------------------------------------------------------------------------------------------------------------------------
	-- ACC   | COST_CENTRE_APPLICABLE		| Cost centres are applicable									| Boolean 	| True / False
	--       | IS_INTEREST_ON					| Activate Interest Calculation								| Boolean 	| True / False
	--       | CREDIT_DAYS_CHK_ON				| Check for credit days during voucher entry				| Boolean 	| True / False
	-- 

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Section 1 : ACCOUNTING MASTERS
-- ----------------------------------------------------------------------------

-- This is a Generic master to capture dynamic status codes across modules
CREATE TABLE IF NOT EXISTS `acc_accounting_status_masters` (
	`id`            MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`status_type`   ENUM('Voucher Status', 'Bank Reconciliation Status', 'Expence Claim Status', 'Tally Export Status', 'Cross-Module Data Processing Status') NOT NULL,
	`code`          VARCHAR(20)     NOT NULL,  -- e.g. 'available', 'occupied', 'maintenance'
	`name`          VARCHAR(100)    NOT NULL,  -- e.g. 'Available', 'Occupied', 'Under Maintenance'
	`is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
	`created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
	`updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`    TIMESTAMP       NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_accounting_status_code` (`status_type`, `code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Data seed :
	--   Status Type                    				Code
	-- --------------------------------------   ---------------------------------------------------------------
	-- `Voucher Status`                         - 'Draft', 'Posted', 'Approved', 'Cancelled', 'Auto_Approved'
	-- `Bank Reconciliation Status`             - 'Pending', 'In Progress', 'Completed', 'Not Required'
	-- `Expence Claim Status`                   - 'Draft', 'Submitted', 'Approved', 'Rejected', 'Paid'
	-- `Tally Export Status`                    - 'Success','Failed','Partial','Cancelled'
	-- 'Cross-Module Data Processing Status'    - 'Pending','Processed','Failed','Skipped'

-- This table will capture Category detail for all the Modules. Voucher entry in accounting Module from other Modules will use these Categories.
CREATE TABLE IF NOT EXISTS `acc_voucher_category` (
	`id`                        MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`voucher_module_id`         MEDIUMINT UNSIGNED NOT NULL, -- FK → tco_app_modules
	`code`                      VARCHAR(30) NOT NULL, -- 'TRANSPORT_FINE', 'TRANSPORT_DAMAGE_FINE', 'HOSTEL_FEE', 'HOSTEL_DAMAGE_FINE', 'LIBRARY_FINE'
	`name`                      VARCHAR(100) NOT NULL, -- 'Transport Fine', 'Hostel Fee'
	`event_detail`					 VARCHAR(100) NOT NULL, -- Event details for which voucher category will be used e.g. Library Late Fine Forfeiture, Hostel Fee Forfeiture
	`module_table_name`         VARCHAR(60) NULL, -- Source Module Table name (`tpt_student_fine_detail`, `lib_fines`, etc.)
	`is_system`                 TINYINT(1) DEFAULT 1, -- 1 = For System use, can not be deleted/edited.
	`is_active`                 TINYINT(1) DEFAULT 1,
	`created_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`                TIMESTAMP NULL,
	UNIQUE KEY `uq_acc_vc_code` (`code`),
	CONSTRAINT `fk_vc_module` FOREIGN KEY (`voucher_module_id`) REFERENCES `tco_app_modules`(`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_vc_debit_ledger` FOREIGN KEY (`debit_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_vc_credit_ledger` FOREIGN KEY (`credit_ledger_id`) REFERENCES `acc_ledgers`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition :
	-- Dropdown for `module_table_name` will show all the tables start with module_prefix (e.g., `tpt_`, `lib_`, etc.), metioned in `tco_app_modules.module_prefix`
	-- Example : `tpt_student_fine_detail`, `lib_fines`, etc.


-- This table will capture Master data of Voucher Types.
CREATE TABLE IF NOT EXISTS `acc_voucher_types` (
	`id`                  MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`                VARCHAR(80) NOT NULL COMMENT 'e.g., Payment Voucher',
	`code`                VARCHAR(20) NOT NULL COMMENT 'PAYMENT, RECEIPT, CONTRA, JOURNAL, MEMO, SALES, PURCHASE, CREDIT NOTE, DEBIT NOTE etc.',
	`voucher_category_id` MEDIUMINT UNSIGNED NOT NULL,  -- FK → acc_voucher_category e.g. Accounting, Inventory, Payroll, Order
	`prefix`              VARCHAR(5) NULL COMMENT 'Voucher number prefix e.g., PAY-, RCV-',
	`auto_numbering`      TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Auto-increment enabled',
	`last_number`         INT NOT NULL DEFAULT 0 COMMENT 'Current voucher counter',
	`is_system`           TINYINT(1) NOT NULL DEFAULT 0, -- 1 = For System use, can not be deleted.
	`is_active`           TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag.
	`created_at`          TIMESTAMP NULL DEFAULT NULL,
	`updated_at`          TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`          TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_vt_code` (`code`),
	UNIQUE KEY `uq_acc_vt_name` (`name`),
	UNIQUE KEY `uq_acc_vt_prefix` (`prefix`),
	INDEX `idx_acc_vt_category` (`voucher_category_id`),
	CONSTRAINT `fk_vt_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
	-- If `is_system` = 1, then that voucher type cannot be deleted.
	-- `is_system` = 1 will be only for voucher types - PAYMENT, RECEIPT, CONTRA, JOURNAL, MEMO, SALES, PURCHASE, CREDIT NOTE, DEBIT NOTE
	-- `prefix` should be unique for each voucher type.
	-- Admin can change `last_number`, if it has been set wrongly on a higher number and voucher are not there for the previous numbers i.e., 
	--    set last_number = 100, whereas there is no voucher from 51 - 100.


-- This is the table where the Master data of Tax Types will be created.
CREATE TABLE IF NOT EXISTS `acc_tax_types` (
	`id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`code`          VARCHAR(10) NOT NULL, -- 'e.g., CGST,SGST,IGST,CESS',
	`name`          VARCHAR(100) NOT NULL, -- 'e.g., CGST 9%',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_tax_type_code` (`code`),
	UNIQUE KEY `uq_acc_tax_type_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This is the table where the Master data of Tax Rates will be created.
CREATE TABLE IF NOT EXISTS `acc_tax_rates` (
	`id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`          VARCHAR(100) NOT NULL, -- 'e.g., CGST 9%',
	`rate`          DECIMAL(5,2) NOT NULL, -- Tax rate percentage',
	`tax_type_id`   SMALLINT UNSIGNED NOT NULL, -- FK → acc_tax_types
	`hsn_sac_code`  VARCHAR(20) NULL, -- HSN/SAC code',
	`is_interstate` TINYINT(1) NOT NULL DEFAULT 0, -- Interstate supply flag',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_tax_rate_name` (`name`),
	INDEX `idx_acc_tax_rate_type` (`tax_type_id`,`name`),
	CONSTRAINT `fk_tax_rate_type` FOREIGN KEY (`tax_type_id`) REFERENCES `acc_tax_types`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This is the table where the Master data of Financial Years will be created. This is required to maintain the continuity of the accounting records.
CREATE TABLE IF NOT EXISTS `acc_financial_years` (
	`id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`          VARCHAR(50) NOT NULL COMMENT 'e.g., 2025-26',
	`start_date`    DATE NOT NULL COMMENT 'Financial year start (April 1)',
	`end_date`      DATE NOT NULL COMMENT 'Financial year end (March 31)',
	`is_locked`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Prevents edits when locked',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_fy_name` (`name`),
	INDEX `idx_acc_fy_active` (`is_active`),
	INDEX `idx_acc_fy_dates` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition :
	-- Difference between `start_date` & `end_date` is 365 days
	-- When `is_locked` = 1, no changes can be made to the Financial Year
	-- When `is_active` = 1, the Financial Year is active, When `is_active` = 0, the Financial Year is inactive
	-- `is_locked` will be 0 and `is_active` will be 1 by default


-- ----------------------------------------------------------------------------
-- Section 2 : GROUPS & LEDGER ACCOUNTS
-- ----------------------------------------------------------------------------

-- This table will capture Master data of Groups under which Ledgers will be created. Account Groups (Tally's 28 predefined + custom)
CREATE TABLE IF NOT EXISTS `acc_account_groups` (
	`id`                    MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`code`                  VARCHAR(30) NOT NULL, -- Unique group code e.g., A01, L02
	`name`                  VARCHAR(100) NOT NULL, -- Group name
	`alias`                 VARCHAR(100) NULL, -- Alternative display name
	`parent_id`             MEDIUMINT UNSIGNED NULL, -- Self-referencing for hierarchy
	`nature`                ENUM('Asset','Liability','Equity','Income','Expense') NOT NULL, -- Account nature
	`affects_gross_profit`  TINYINT(1) NOT NULL DEFAULT 0, -- 1 = Direct vs Indirect classification
	`is_system`             TINYINT(1) NOT NULL DEFAULT 0, -- 1 = For System use, can not be deleted/edited.
	`is_subledger`          TINYINT(1) NOT NULL DEFAULT 0, -- 1 = Behave as sub-ledger
	`ordinal`               SMALLINT NOT NULL DEFAULT 0, -- Display order in reports.
	`is_active`             TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag.
	`created_at`            TIMESTAMP NULL DEFAULT NULL,
	`updated_at`            TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`            TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_ag_code` (`code`),
	UNIQUE KEY `uq_acc_ag_name` (`name`),
	UNIQUE KEY `uq_acc_ag_alias` (`alias`),
	INDEX `idx_acc_ag_parent` (`parent_id`,`name`,`is_active`),
	INDEX `idx_acc_ag_nature` (`nature`,`parent_id`,`name`,`is_active`),
	INDEX `idx_acc_ag_system` (`is_system`,`is_active`),
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


-- This is the table where the Master data of Ledgers will be created.
CREATE TABLE IF NOT EXISTS `acc_ledgers` (
	`id`                        MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`code`                      VARCHAR(30) NULL, -- Unique ledger code
	`name`                      VARCHAR(150) NOT NULL, -- Ledger name
	`alias`                     VARCHAR(150) NULL, -- Alternative name
	`account_group_id`          MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_account_groups
	`opening_balance`           DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Opening balance amount
	`opening_balance_type`      ENUM('Dr','Cr') NULL, -- Debit or Credit opening
	`closing_balance`           DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Closing balance amount
	`closing_balance_type`      ENUM('Dr','Cr') NULL, -- Debit or Credit closing
	`is_bank_account`           TINYINT(1) NOT NULL DEFAULT 0, -- Bank account flag,
	`bank_name`                 VARCHAR(100) NULL, -- Bank name if bank account
	`bank_account_number`       VARCHAR(50) NULL, -- Bank account number
	`ifsc_code`                 VARCHAR(30) NULL, -- Bank IFSC code
	`is_cash_account`           TINYINT(1) NOT NULL DEFAULT 0, -- Cash account flag
	`allow_reconciliation`      TINYINT(1) NOT NULL DEFAULT 0, -- Enable bank reconciliation
	`is_system`                 TINYINT(1) NOT NULL DEFAULT 0, -- P&L A/c, Cash A/c etc. — cannot delete
	`student_id`                INT UNSIGNED NULL, -- FK → std_students (auto-ledger for student debtors)
	`employee_id`               INT UNSIGNED NULL, -- FK → sch_employees (auto-ledger for salary payable)
	`vendor_id`                 INT UNSIGNED NULL, -- FK → vnd_vendors (auto-ledger for vendor creditors)
   `gst_registration_type`     ENUM('Regular','Composition','Unregistered','SEZ','Consumer') NULL, -- To calculate and claim Input Tax Credit (ITC). See detail in (Businessh_Conditions.md)
	`gstin`                     VARCHAR(20) NULL, -- GST number
	`pan`                       VARCHAR(15) NULL, -- PAN number
	`address`                   VARCHAR(255) NULL, -- Ledger address
	`is_active`                 TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag
	`created_at`                TIMESTAMP NULL DEFAULT NULL,
	`updated_at`                TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`                TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_ledger_code` (`code`),
	UNIQUE KEY `uq_acc_ledger_name` (`name`),
	UNIQUE KEY `uq_acc_ledger_alias` (`alias`),
	INDEX `idx_acc_ledger_group` (`account_group_id`),
	INDEX `idx_acc_ledger_student` (`student_id`),
	INDEX `idx_acc_ledger_employee` (`employee_id`),
	INDEX `idx_acc_ledger_vendor` (`vendor_id`),
	INDEX `idx_acc_ledger_bank` (`is_bank_account`),
	INDEX `idx_acc_ledger_active` (`is_active`),
	CONSTRAINT `fk_acc_ledger_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_ledger_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_ledger_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees`(`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_ledger_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
	-- If `is_system` = 1, then that ledger cannot be deleted. This is for critical ledgers like Cash Account, Profit & Loss Account, etc. that are essential for system integrity.


-- This is the table where the Master data of Cost Centers (Department/Wing/Activity) will be created.
CREATE TABLE IF NOT EXISTS `acc_cost_centers` (
	`id`            MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`code`          VARCHAR(20) NULL, -- Cost center code
	`name`          VARCHAR(100) NOT NULL, -- 'e.g., Primary Wing, Transport'
	`parent_id`     MEDIUMINT UNSIGNED NULL, -- Self-referencing hierarchy
	`category`      VARCHAR(50) NULL, -- Department, Activity, Project
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_cc_code` (`code`),
	UNIQUE KEY `uq_acc_cc_name` (`name`),
	INDEX `idx_acc_cc_parent` (`parent_id`),
	CONSTRAINT `fk_acc_cc_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 

-- ----------------------------------------------------------------------------
-- Section 3 : TRANSACTIONS
-- ----------------------------------------------------------------------------
-- Section 3.1 : VOUCHER TRANSACTIONS
-- ----------------------------------------------------------------------------

-- This is the table where the details of every transaction is recorded as a voucher.
CREATE TABLE IF NOT EXISTS `acc_vouchers` (
	`id`                 INT	UNSIGNED NOT NULL AUTO_INCREMENT,
	`voucher_prefix`     VARCHAR(5) NULL, -- Snapshot of prefix from voucher type (acc_voucher_types) for historical reference',
	`voucher_number`     INT UNSIGNED NOT NULL, -- Auto-generated sequential number per voucher type and FY',
	`voucher_type_id`    MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_voucher_types',
	`financial_year_id`  SMALLINT UNSIGNED NOT NULL, -- FK → acc_financial_years',
	`voucher_date`       DATE NOT NULL, -- Transaction date',
	`reference_number`   VARCHAR(100) NULL, -- Cheque no, receipt no, etc.',
	`reference_date`     DATE NULL, -- Cheque date, etc.',
	`narration`          TEXT NULL, -- Transaction description',
	`total_amount`       DECIMAL(15,2) NOT NULL, -- Total voucher amount',
	`is_post_dated`      TINYINT(1) NOT NULL DEFAULT 0, -- Post-dated cheque flag',
	`is_optional`        TINYINT(1) NOT NULL DEFAULT 0, -- Memorandum voucher',
	`is_cancelled`       TINYINT(1) NOT NULL DEFAULT 0, -- Cancelled flag',
	`cancelled_reason`   TEXT NULL, -- Cancellation reason',
	`source_module_id`   MEDIUMINT UNSIGNED NULL, -- FK to `tco_app_modules` e.g. 1 - Fees, 2 - Library, 3 - Transport
	`source_category_id` MEDIUMINT UNSIGNED NULL, -- FK to `acc_voucher_category`
	`source_type`        VARCHAR(100) NULL, -- Polymorphic model: PayrollRun, FeeTransaction, GRN, etc.', -- Check, whether required or Not
	`source_id`          INT UNSIGNED NULL, -- Polymorphic source ID', -- Check, whether required or Not
	`status`             MEDIUMINT UNSIGNED NOT NULL, -- Voucher Status', -- FK to `acc_accounting_status_masters`
	`entered_by`         INT UNSIGNED NULL, -- FK → sys_users',
	`approved_by`        INT UNSIGNED NULL, -- FK → sys_users (approver)',
	`created_at`         TIMESTAMP NULL DEFAULT NULL,
	`updated_at`         TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`         TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_voucher_number_fy` (`financial_year_id`, `voucher_prefix`, `voucher_number`),
	INDEX `idx_acc_voucher_type` (`voucher_type_id`),
	INDEX `idx_acc_voucher_fy` (`financial_year_id`),
	INDEX `idx_acc_voucher_date` (`voucher_date`),
	INDEX `idx_acc_voucher_status` (`status`),
	INDEX `idx_acc_voucher_source` (`source_module`, `source_type`, `source_id`),
	INDEX `idx_acc_voucher_cost` (`cost_center_id`),
	INDEX `idx_acc_voucher_composite` (`date`, `financial_year_id`, `status`),
	CONSTRAINT `fk_acc_voucher_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_voucher_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_voucher_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_acc_voucher_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_voucher_entered_by` FOREIGN KEY (`entered_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_voucher_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- If `is_optional` = 1, then that transaction should be consider in financial reports but should not be posted to ledgers until explicitly approved and marked as non-optional. 
-- This allows creating draft vouchers for future transactions or estimates without affecting current financials.


-- This is the table where the line items of every voucher is recorded.
CREATE TABLE IF NOT EXISTS `acc_voucher_items` (
	`id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`voucher_id`        INT UNSIGNED NOT NULL, -- FK → acc_vouchers',
	`ledger_id`         MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_ledgers',
	`type`              ENUM('Dr','Cr') NOT NULL, -- Dr-Debit or Cr-Credit entry',
	`amount`            DECIMAL(15,2) NOT NULL, -- Line item amount',
	`narration`         VARCHAR(500) NULL, -- Per-ledger narration',
	`reference_number`  VARCHAR(100) NULL, -- Against invoice/bill reference',
	`reference_date`    DATE NULL, -- Against invoice/bill reference'
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


CREATE TABLE IF NOT EXISTS `acc_voucher_item_cost_centers` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `voucher_item_id`       INT UNSIGNED NOT NULL,
   `cost_center_id`        MEDIUMINT UNSIGNED NOT NULL,
   `amount`                DECIMAL(15,2) NOT NULL,
   `percentage`            DECIMAL(7,4) NULL,
   `narration`             VARCHAR(500) NULL,
   `created_at`            TIMESTAMP NULL DEFAULT NULL,
   `updated_at`            TIMESTAMP NULL DEFAULT NULL,
   `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_vic_voucher_item` (`voucher_item_id`),
   INDEX `idx_vic_cost_center` (`cost_center_id`),
   UNIQUE KEY `uq_vic_item_cost` (`voucher_item_id`, `cost_center_id`),
   CONSTRAINT `fk_vic_voucher_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items` (`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_vic_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
-- If COST_CENTRE_REQUIRED in Table `glb_app_config` = 1 (True) Then only we will capturee Cost Center Detail else `acc_voucher_item_cost_centers` will be blank.
-- I would use RESTRICT rather than SET NULL on cost_center_id. Once a Cost Centre has actually been used in an accounting transaction, I would generally not allow that Cost Centre to be deleted.
-- Cascade is fine here, because we don’t allow the parent acc_voucher_items row to be deleted unless it has been “Cancelled” first.
-- 
-- Payment Voucher Example PAY-125
-- Teaching Salary       Dr    ₹100,000
-- HDFC Bank             Cr    ₹100,000

-- Then acc_voucher_items would contain:
-- |  id | voucher_id |       ledger_id | type |  amount |
-- | --: | ---------- | --------------- | ---- | ------- |
-- | 501 |        125 | Teaching Salary | Dr   | 100,000 |
-- | 502 |        125 |       HDFC Bank | Cr   | 100,000 |

-- Then acc_voucher_item_cost_centers:
-- | id | voucher_item_id | cost_center_id | amount |
-- | -: | --------------- | -------------- | ------ |
-- |  1 |             501 |        Primary | 60,000 |
-- |  2 |             501 |      Secondary | 40,000 |




-- This is the table where the Master data of Budgets will be created.
CREATE TABLE IF NOT EXISTS `acc_budgets` (
	`id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`financial_year_id` SMALLINT UNSIGNED NOT NULL, -- FK → acc_financial_years',
	`cost_center_id`    MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_cost_centers',
	`ledger_id`         MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_ledgers',
	`budgeted_amount`   DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Allocated budget amount',
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


-- ----------------------------------------------------------------------------
-- Section 3.2 : BANK RECONCILIATION
-- ----------------------------------------------------------------------------

-- This is the table where the Master data of Bank Reconciliations will be created.
CREATE TABLE IF NOT EXISTS `acc_bank_reconciliations` (
	`id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`ledger_id`           INT UNSIGNED NOT NULL,         -- FK → acc_ledgers (bank account)
	`statement_date`      DATE NOT NULL,                 -- Bank statement date
	`closing_balance`     DECIMAL(15,2) NOT NULL,        -- Closing balance per bank statement
	-- `statement_path`   VARCHAR(255) NULL,             -- Uploaded statement file path (Deleted to use Media Component)
   `statement_file_name` VARCHAR(100) DEFAULT NULL,     -- file name to show in UI
   `media_id`            INT UNSIGNED DEFAULT NULL,     -- FK to sys_media.id
	`can_be_import`       TINYINT(1) NOT NULL DEFAULT 0, -- Whether data can be imported from bank statement file
	`status`              MEDIUMINT UNSIGNED NOT NULL,   -- Reconciliation status -- FK to `acc_accounting_status_masters`
	`created_at`          TIMESTAMP NULL DEFAULT NULL,
	`updated_at`          TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`          TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_br_ledger` (`ledger_id`),
	INDEX `idx_acc_br_date` (`statement_date`),
	CONSTRAINT `fk_acc_br_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_br_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_br_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- This table will capture mapping of Bank Statement to get import into acc_bank_statement_entries
CREATE TABLE IF NOT EXISTS `acc_bank_statement_mapping` (
   `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `reconciliation_id`         BIGINT UNSIGNED NOT NULL, -- FK → acc_bank_reconciliations`,
	`has_column_header`         TINYINT(1) NOT NULL DEFAULT 0, -- Whether data can be imported from bank statement file`,
	`row_no_for_header`         TINYINT UNSIGNED NULL, -- Row number for header`,
	`import_data_from_row_no`   SMALLINT UNSIGNED NULL, -- Row number for importing data`,
	`import_data_to_row_no`     SMALLINT UNSIGNED NULL, -- Row number for importing data`,
	`tran_date_column_no`       TINYINT UNSIGNED NULL, -- Column number for date`,
	`description_column_no`     TINYINT UNSIGNED NULL, -- Column number for description`,
	`reference_column_no`       TINYINT UNSIGNED NULL, -- Column number for reference`,
	`saperate_col_for_dr_cr`    TINYINT(1) NOT NULL DEFAULT 0, -- Whether data has saperate column for Dr/Cr`,
	`debit_column_no`           TINYINT UNSIGNED NULL, -- Column number for debit`,
	`credit_column_no`          TINYINT UNSIGNED NULL, -- Column number for credit`,
	`amount_column_no`          TINYINT UNSIGNED NULL, -- Column number for amount`,	
	`amount_type_dr_cr_col_no`  TINYINT UNSIGNED NULL, -- Column number for amount type Dr/Cr`,
	`balance_column_no`         TINYINT UNSIGNED NULL, -- Column number for balance`,
   `statement_date`            DATE NOT NULL, -- Bank statement date`,
   `created_at`                TIMESTAMP NULL DEFAULT NULL,
   `updated_at`                TIMESTAMP NULL DEFAULT NULL,
   `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_acc_bsm_recon` (`reconciliation_id`),
   CONSTRAINT `fk_acc_bsm_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This table will store the transaction details of bank statement.
CREATE TABLE IF NOT EXISTS `acc_bank_statement_entries` (
   `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `reconciliation_id`         BIGINT UNSIGNED NOT NULL, -- FK → acc_bank_reconciliations',
   `transaction_date`          DATE NOT NULL, -- Bank transaction date',
   `description`               VARCHAR(500) NULL, -- Transaction description from bank
   `reference`                 VARCHAR(255) NULL, -- Bank reference number
   `debit`                     DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Debit amount (withdrawal)
   `credit`                    DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Credit amount (deposit)
   `balance`                   DECIMAL(15,2) NULL, -- Running balance per statement
	`entry_type`                ENUM('Mannual','Imported') NOT NULL, -- Whether Data entered Mannually or Imported from Bank Statement File.
   `is_matched`                TINYINT(1) NOT NULL DEFAULT 0, -- Whether matched to a voucher item
   `matched_voucher_item_id`   INT UNSIGNED NULL, -- FK → acc_voucher_items (matched entry)
   `reconciler_remarks`        VARCHAR(500) NULL, -- Remark from the person who reconciled (if any)
   `matched_at`                TIMESTAMP NULL, -- Reconciliation date, When the match was made
   `matched_by`                INT UNSIGNED NULL, -- FK → sys_users (who matched)
   `created_at`                TIMESTAMP NULL DEFAULT NULL,
   `updated_at`                TIMESTAMP NULL DEFAULT NULL,
   `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_acc_bse_recon` (`reconciliation_id`),
   INDEX `idx_acc_bse_matched` (`is_matched`),
   INDEX `idx_acc_bse_vi` (`matched_voucher_item_id`),
   INDEX `idx_acc_bse_date` (`transaction_date`),
   INDEX `idx_acc_bse_recon_matched` (`reconciliation_id`, `is_matched`),
   CONSTRAINT `fk_acc_bse_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `acc_bank_reconciliations` (`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_acc_bse_vi` FOREIGN KEY (`matched_voucher_item_id`) REFERENCES `acc_voucher_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
	-- When school make payment to vendor/supplier or receive payment from customer it will be recorded in acc_vouchers table.
	-- When bank statement is uploaded it should show the same transaction as well.
	-- System should automatically fetch the data from the statement uploaded in `acc_bank_reconciliations` table and add entries into `acc_bank_statement_entries` table.
	-- user can match these entries against the relevant voucher entries in `acc_voucher_items`.
	-- After reconciliation, the `matched_voucher_item_id`, `matched_at`, and `matched_by` fields should be populated.


-- ----------------------------------------------------------------------------
-- Section 3.3 : RECURRING VOUCHER TEMPLATES
-- ----------------------------------------------------------------------------

-- This is the table where the Master data of Recurring Templates will be created.
CREATE TABLE IF NOT EXISTS `acc_recurring_templates` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`name`              VARCHAR(150) NOT NULL, -- Template name
	`voucher_type_id`   TINYINT UNSIGNED NOT NULL, -- FK → acc_voucher_types
	`frequency`         ENUM('Daily','Weekly','Monthly','Quarterly','Yearly','Custom') NOT NULL, -- Recurrence frequency
	`start_date`        DATE NOT NULL, -- Start posting from
	`end_date`          DATE NULL, -- Stop posting after (NULL = indefinite)
	`day_of_month`      TINYINT NULL, -- Day to post for monthly / Weekly frequency
	`custom_frequency`  VARCHAR(50) NULL, -- Custom frequency (e.g., 'Every 3 days')
	`total_frequency`   SMALLINT NULL, -- Number of times the voucher will be posted (NULL = indefinite)
	`narration`         TEXT NULL, -- Default narration for generated vouchers
	`total_amount`      DECIMAL(15,2) NOT NULL, -- Template total (must balance Dr=Cr)
	`last_posted_date`  DATE NULL, -- Last auto-post date
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag
	`created_at`        TIMESTAMP NULL DEFAULT NULL,
	`updated_at`        TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_rt_type` (`voucher_type_id`),
	CONSTRAINT `fk_acc_rt_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `chk_acc_rt_total_amount` CHECK ((`end_date` IS NULL AND `total_frequency` IS NOT NULL) OR (`end_date` IS NOT NULL AND `total_frequency` IS NULL AND `end_date` >= `start_date`)) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
	-- [ BACKGROUND SERVICE ] will run on daily basis (based on the `frequency`, `day_of_month`, etc.) and will check if any recurring template is due for posting.
	-- If any recurring template is due for posting, then it will create a voucher for that template and will post it to ledgers.
	-- Custom frequency example: If `frequency` = 'Custom' and `custom_frequency` = 'Every 3 days', then the voucher will be posted every 3 days.
	-- Weekly Frequency: If `frequency` = 'Weekly', then the voucher will be posted every week on the same day of the week as `start_date`.
	-- Monthly Frequency: If `frequency` = 'Monthly', then the voucher will be posted every month on the same day of the month as `start_date`.
	-- Quarterly Frequency: If `frequency` = 'Quarterly', then the voucher will be posted every quarter on the same day of the month as `start_date`.
	-- Yearly Frequency: If `frequency` = 'Yearly', then the voucher will be posted every year on the same day of the month as `start_date`.

	-- Example 1: If `start_date` = '2024-01-15' and `frequency` = 'Daily', then the voucher will be posted on 2024-01-15, 2024-01-16, 2024-01-17, and so on till `total_frequency` number of vouchers are posted OR `end_date` is reached.
	-- Example 2: If `start_date` = '2024-01-15' and `frequency` = 'Monthly', then the voucher will be posted on 2024-01-15, 2024-02-15, 2024-03-15, and so on till `total_frequency` number of vouchers are posted OR `end_date` is reached.
	-- Example 3: If `start_date` = '2024-01-15' and `frequency` = 'Weekly', then the voucher will be posted on 2024-01-15, 2024-01-22, 2024-01-29, and so on till `total_frequency` number of vouchers are posted OR `end_date` is reached.
	-- Example 4: If `start_date` = '2024-01-15' and `frequency` = 'Quarterly', then the voucher will be posted on 2024-01-15, 2024-04-15, 2024-07-15, and so on till `total_frequency` number of vouchers are posted OR `end_date` is reached.
	-- Example 5: If `start_date` = '2024-01-15' and `frequency` = 'Yearly', then the voucher will be posted on 2024-01-15, 2025-01-15, 2026-01-15, and so on till `total_frequency` number of vouchers are posted OR `end_date` is reached.
	-- Example 6: If `start_date` = '2024-01-15' and `frequency` = 'Custom' and `custom_frequency` = '3 days', then the voucher will be posted on 2024-01-15, 2024-01-18, 2024-01-21, and so on till `total_frequency` number of vouchers are posted OR `end_date` is reached.


-- This is the table where the line items of every recurring template is recorded.
CREATE TABLE IF NOT EXISTS `acc_recurring_template_lines` (
	`id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`recurring_template_id` BIGINT UNSIGNED NOT NULL, -- FK → acc_recurring_templates
	`ledger_id`             INT UNSIGNED NOT NULL, -- FK → acc_ledgers
	`type`                  ENUM('Dr','Cr') NOT NULL, -- Dr-Debit or Cr-Credit
	`amount`                DECIMAL(15,2) NOT NULL, -- Line amount
	`narration`             VARCHAR(500) NULL, -- Per-line narration
	`cost_center_id`        MEDIUMINT UNSIGNED NULL, -- FK → acc_cost_centers
	`bill_reference`        VARCHAR(100) NULL, -- Against invoice/bill reference
	`is_active`             TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag
	`created_at`            TIMESTAMP NULL DEFAULT NULL,
	`updated_at`            TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`            TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_rtl_template` (`recurring_template_id`),
	INDEX `idx_acc_rtl_ledger` (`ledger_id`),
	INDEX `idx_acc_rtl_cost` (`cost_center_id`),
	CONSTRAINT `fk_acc_rtl_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates` (`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_acc_rtl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_rtl_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- This table will capture the log of recurring trasactions posted.
CREATE TABLE IF NOT EXISTS `acc_recurring_transaction_log` (
	`id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`recurring_template_id` BIGINT UNSIGNED NOT NULL, -- FK → acc_recurring_templates
	`voucher_id`            INT UNSIGNED NOT NULL, -- FK → acc_vouchers
	`voucher_date`          DATE NOT NULL, -- Voucher date
	`voucher_type_id`       INT UNSIGNED NOT NULL, -- FK → acc_voucher_types
	`narration`             VARCHAR(500) NULL, -- Voucher narration
	`total_amount`          DECIMAL(15,2) NOT NULL, -- Voucher total (must balance Dr=Cr)
	`is_posted`             TINYINT(1) NOT NULL DEFAULT 1, -- Whether posted to ledgers
	`posted_at`             TIMESTAMP NULL DEFAULT NULL, -- When posted
	`posted_by`             INT UNSIGNED NULL, -- FK → sys_users (who posted)
	`created_at`            TIMESTAMP NULL DEFAULT NULL,
	`updated_at`            TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`            TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_rtl_template` (`recurring_template_id`),
	INDEX `idx_acc_rtl_voucher` (`voucher_id`),
	INDEX `idx_acc_rtl_voucher_type` (`voucher_type_id`),
	CONSTRAINT `fk_acc_rtl_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates` (`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_acc_rtl_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_acc_rtl_voucher_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Section 4 : ASSETS & EXPENSES
-- ----------------------------------------------------------------------------
-- Section 4.1: FIXED ASSETS
-- ----------------------------------------------------------------------------

-- This is the table where the Master data of Asset Categories will be created.
CREATE TABLE IF NOT EXISTS `acc_asset_categories` (
   `id`                    MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `code`                  VARCHAR(20) NOT NULL, -- Category code'
   `name`                  VARCHAR(100) NOT NULL, -- Category name e.g., Furniture'
   `depreciation_method`   ENUM('SLM','WDV') NOT NULL, -- Straight Line / Written Down Value'
   `depreciation_rate`     DECIMAL(5,2) NOT NULL, -- Annual depreciation rate %'
   `useful_life_years`     INT NULL, -- Useful life in years'
   `is_active`             TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag'
   `created_at`            TIMESTAMP NULL DEFAULT NULL,
   `updated_at`            TIMESTAMP NULL DEFAULT NULL,
   `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_acc_assetcat_code` (`code`, `deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This is the table where the Master data of Fixed Assets will be created.
CREATE TABLE IF NOT EXISTS `acc_fixed_assets` (
   `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
   `name`                      VARCHAR(150) NOT NULL, -- Asset name',
   `asset_code`                VARCHAR(50) NOT NULL, -- Asset identification code',
   `asset_category_id`         MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_asset_categories',
   `purchase_date`             DATE NOT NULL, -- Date of purchase',
   `purchase_cost`             DECIMAL(15,2) NOT NULL, -- Original purchase cost',
   `salvage_value`             DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Estimated residual value',
   `current_value`             DECIMAL(15,2) NOT NULL, -- Current book value',
   `accumulated_depreciation`  DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Total depreciation to date',
   `location`                  VARCHAR(100) NULL, -- Physical location of asset',
   `vendor_id`                 INT UNSIGNED NULL, -- FK → vnd_vendors (supplier)',
   `voucher_id`                BIGINT UNSIGNED NULL, -- FK → acc_vouchers (purchase voucher)',
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


-- This is the table where the Master data of Depreciation Entries will be created.
-- When Depreciation is run, for each asset, one entry is created in this table.
CREATE TABLE IF NOT EXISTS `acc_depreciation_entries` (
   `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `fixed_asset_id`        BIGINT UNSIGNED NOT NULL, -- FK → acc_fixed_assets'
   `financial_year_id`     TINYINT UNSIGNED NOT NULL, -- FK → acc_financial_years'
   `depreciation_date`     DATE NOT NULL, -- Date of depreciation entry'
   `depreciation_amount`   DECIMAL(15,2) NOT NULL, -- Depreciation amount for this period'
   `voucher_id`            BIGINT UNSIGNED NULL, -- FK → acc_vouchers (depreciation journal)'
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
-- Conditions :
	-- 1. Formula for {Accumulated Depreciation} = {Purchase Cost} - {Salvage Value} / {Useful Life} (Years) x {Current Age} (Years)
	-- 2. Formula for Current Value = {Purchase Cost} - {Accumulated Depreciation}
	-- Example :
	-- If you buy equipment for ₹1,00,000 with a salvage value of ₹20,000 and a useful life of 5 years :
	-- 	- Annual Depreciation: (1,00,000 - 20,000) / 5 = 16,000 per year
	-- 	- At Year 3 Accumulated Depreciation: 16,000 x 3 = 48,000
	-- 	- At Year 3 Current Value: 1,00,000 - 48,000 = 52,000


-- ----------------------------------------------------------------------------
-- Section 4.2 : EXPENSE CLAIMS
-- ----------------------------------------------------------------------------

-- This is the table where the Master data of Expense Claims will be created.
CREATE TABLE IF NOT EXISTS `acc_expense_claims` (
   `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `claim_number`   VARCHAR(50) NOT NULL,         -- Auto-generated claim number
   `employee_id`    INT UNSIGNED NOT NULL,        -- FK → sch_employees (existing table)
   `claim_date`     DATE NOT NULL,                -- Date of claim submission
   `narration`      VARCHAR(500) NULL,            -- Claim narration
   `total_amount`   DECIMAL(15,2) NOT NULL,       -- Total claim amount
   `status`         MEDIUMINT UNSIGNED NOT NULL,  -- Claim workflow status (FK to `acc_accounting_status_masters`)
   `approved_by`    INT UNSIGNED NULL,            -- FK → sys_users
   `approved_at`    TIMESTAMP NULL,               -- Approval timestamp
   `voucher_id`     BIGINT UNSIGNED NULL,         -- FK → acc_vouchers (payment voucher on approval)
   `created_at`     TIMESTAMP NULL DEFAULT NULL,
   `updated_at`     TIMESTAMP NULL DEFAULT NULL,
   `deleted_at`     TIMESTAMP NULL DEFAULT NULL,
   PRIMARY KEY (`id`),
   UNIQUE KEY `uq_acc_ec_number` (`claim_number`, `deleted_at`),
   INDEX `idx_acc_ec_employee` (`employee_id`),
   INDEX `idx_acc_ec_status` (`status`),
   INDEX `idx_acc_ec_voucher` (`voucher_id`),
   CONSTRAINT `fk_acc_ec_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_acc_ec_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_acc_ec_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This is the table where the line items of every expense claim is recorded.
CREATE TABLE IF NOT EXISTS `acc_expense_claim_lines` (
   `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `expense_claim_id`  BIGINT UNSIGNED NOT NULL,   -- FK → acc_expense_claims
   `expense_date`      DATE NOT NULL,              -- Date of expense
   `reference_number`  VARCHAR(50) NULL,         	-- Reference number for the expense (e.g. bill number)
   `ledger_id`         INT UNSIGNED NOT NULL,      -- FK → acc_ledgers (expense category)
   `cost_center_id`    MEDIUMINT UNSIGNED NULL,    -- FK → acc_cost_centers (header-level)
   `description`       VARCHAR(255) NOT NULL,      -- Expense description
   `amount`            DECIMAL(15,2) NOT NULL,     -- Expense amount
   `tax_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Tax on expense
	`total_amount`      DECIMAL(15,2) NOT NULL DEFAULT 0.00, -- Total amount (amount + tax_amount)
   -- `receipt_path`   VARCHAR(255) NULL,          -- Uploaded receipt file path (Deleted to use Media Component)
   `receipt_file_name` VARCHAR(100) DEFAULT NULL,  -- file name to show in UI
   `media_id`          INT UNSIGNED DEFAULT NULL,  -- FK to sys_media.id
   `created_at`        TIMESTAMP NULL DEFAULT NULL,
   `updated_at`        TIMESTAMP NULL DEFAULT NULL,
   `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
   PRIMARY KEY (`id`),
   INDEX `idx_acc_ecl_claim` (`expense_claim_id`),
   INDEX `idx_acc_ecl_ledger` (`ledger_id`),
   CONSTRAINT `fk_acc_ecl_claim` FOREIGN KEY (`expense_claim_id`) REFERENCES `acc_expense_claims` (`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_acc_ecl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_ecl_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
-- When above Expence claim will make entry in Voucher table then acc_vouchers.source_type will be 'Expense Claim' and acc_vouchers.source_id will be acc_expense_claims.id
-- Voucher lines will be created in `acc_voucher` & `acc_voucher_items` table as per below Instructions:
-- 	1. acc_voucher_items.type will be 'Dr'
-- 	2. acc_voucher_items.ledger_id will be acc_expense_claims_lines.ledger_id
-- 	3. acc_voucher_items.amount will be acc_expense_claims_lines.total_amount
-- 	4. acc_voucher_items.description will be acc_expense_claims_lines.description

	`acc_voucher.voucher_prefix` = "PAY-"
	`acc_voucher.voucher_number` = last_number+1 (This Number should be increased only when Voucher is in POSTED state)
	`acc_voucher.voucher_type_id` = voucher type id for "PAY" in Table acc_voucher_types
	`acc_voucher.financial_year_id` = Active Financial year id 
	`acc_voucher.voucher_date` = `acc_expense_claims.claim_date`
	`acc_voucher.reference_number` = NULL
	`acc_voucher.reference_date` = `acc_expense_claim_lines.expense_date`
	`acc_voucher.narration` = `acc_expense_claims.narration`
	`acc_voucher.total_amount` = `acc_expense_claims.total_amount`
	`acc_voucher.is_post_dated` = 0
	`acc_voucher.is_optional` = 0        
	`acc_voucher.is_cancelled` = 0       
	`acc_voucher.cancelled_reason` = NULL   
	`acc_voucher.cost_center_id` =  `acc_expense_claims.cost_center_id`
	`acc_voucher.source_module_id` = `acc_expense_claims.source_module_id`
	`acc_voucher.source_category_id` 
	`acc_voucher.source_type`        
	`acc_voucher.source_id`          
	`acc_voucher.status`             


	`acc_voucher_items.voucher_id` will be new voucher id
	`acc_voucher_items.ledger_id` will be acc_expense_claims_lines.ledger_id
	`acc_voucher_items.type` = 'Dr'
	`acc_voucher_items.amount` = acc_expense_claims_lines.total_amount
	`acc_voucher_items.narration` = acc_expense_claims_lines.description
	`acc_voucher_items.bill_reference` = acc_expense_claims_lines.reference_number
	`acc_voucher_items.reference_date` =    DATE NULL, -- Against invoice/bill reference'

-- 5. acc_voucher_items.cost_center_id will be acc_expense_claims.cost_center_id
-- 6. acc_voucher_items.employee_id will be acc_expense_claims.employee_id
-- 7. acc_voucher_items.expense_date will be acc_expense_claims_lines.expense_date
-- 8. acc_voucher_items.tax_amount will be acc_expense_claims_lines.tax_amount
-- 9. acc_voucher_items.total_amount will be acc_expense_claims_lines.total_amount
-- 10. acc_voucher_items.receipt_file_name will be acc_expense_claims_lines.receipt_file_name
-- 11. acc_voucher_items.media_id will be acc_expense_claims_lines.media_id


-- ============================================================================
-- Section 7: TALLY INTEGRATION
-- ============================================================================

-- This is the table where the Master data of Tally Export Logs will be created.
CREATE TABLE IF NOT EXISTS `acc_tally_export_logs` (
	`id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`export_type`   ENUM('Ledgers','Vouchers','Inventory') NOT NULL, -- What was exported',
	`export_date`   DATETIME NOT NULL,             -- When export was run',
	`file_name`     VARCHAR(255) NOT NULL,         -- Generated file name',
	`exported_by`   INT UNSIGNED NOT NULL,         -- FK → sys_users',
	`start_date`    DATE NULL	,                   -- Export date range start',
	`end_date`      DATE NULL,                     -- Export date range end',
	`record_count`  INT NULL,                      -- Number of records exported',
	`status`        MEDIUMINT UNSIGNED NOT NULL,   -- Tally Export Status', -- FK to `acc_accounting_status_masters`
	`error_log`     TEXT NULL,                     -- Error details if failed',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_tel_type` (`export_type`),
	INDEX `idx_acc_tel_date` (`export_date`),
	INDEX `idx_acc_tel_by` (`exported_by`),
	CONSTRAINT `fk_acc_tel_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This is the table where the Master data of Tally Ledger Mappings will be created.
-- This table is used to map the ledgers of our application to the ledgers of Tally.
CREATE TABLE IF NOT EXISTS `acc_tally_ledger_mappings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`         INT UNSIGNED NOT NULL, -- FK → acc_ledgers (our application ledger)',
    `tally_ledger_name` VARCHAR(200) NOT NULL, -- Exact Tally ledger name for export/import',
    `tally_group_name`  VARCHAR(200) NULL, -- Tally parent group name',
    `tally_alias`       VARCHAR(200) NULL, -- Tally alias if any',
    `mapping_type`      ENUM('auto','manual') NOT NULL DEFAULT 'auto', -- Auto=seeded, manual=user-configured',
    `sync_direction`    ENUM('export_only','import_only','bidirectional') NOT NULL DEFAULT 'export_only', -- Sync direction',
    `last_synced_at`    TIMESTAMP NULL, -- Last successful sync timestamp',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_tlm_ledger` (`ledger_id`, `deleted_at`),
    CONSTRAINT `fk_acc_tlm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ============================================================================
-- Section 8: GENERIC CROSS-MODULE EVENT LEDGER ENTRIES
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


-- This is the table where the Master data of Ledger Mappings (Cross-module) will be created.
CREATE TABLE IF NOT EXISTS `acc_ledger_mappings` (
	`id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`ledger_id`     MEDIUMINT UNSIGNED NOT NULL, -- FK → acc_ledgers',
	`source_module` ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll') NOT NULL, -- Source module',
	`source_type`   VARCHAR(100) NULL, -- e.g., FeeHead, PayHead, Route, Stoppage',
	`source_id`     BIGINT UNSIGNED NOT NULL, -- Source entity ID',
	`description`   VARCHAR(255) NULL, -- Human-readable mapping description',
	`is_active`     TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
	`created_at`    TIMESTAMP NULL DEFAULT NULL,
	`updated_at`    TIMESTAMP NULL DEFAULT NULL,
	`deleted_at`    TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_acc_lm_combo` (`ledger_id`, `source_module`, `source_type`, `source_id`),
	INDEX `idx_acc_lm_source` (`source_module`, `source_type`, `source_id`),
	CONSTRAINT `fk_acc_lm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This is the table where the Master data of Module Events will be created.
CREATE TABLE IF NOT EXISTS `acc_module_events` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_code`   VARCHAR(30) NOT NULL, -- Module identifier in UPPER_SNAKE_CASE: LIBRARY, TRANSPORT, HR, INVENTORY, FEES, etc.',
    `event_code`    VARCHAR(60) NOT NULL, -- Unique event code within the module: LIB_LATE_RETURN_FINE, TPT_NEW_REGISTRATION, etc.',
    `event_name`    VARCHAR(150) NOT NULL, -- Human-readable event name shown in UI and logs',
    `description`   TEXT NULL, -- Detailed description of what business action triggers this event',
    `source_model`  VARCHAR(100) NOT NULL, -- Source DB table that owns the triggering record. e.g., lib_fines, tpt_student_route_allocation_jnt, lib_members',
    `is_system`     TINYINT(1) NOT NULL DEFAULT 1, -- 1 = seeded by system (protected from deletion), 0 = custom event added by school',
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag — inactive events are ignored by the processing engine',
    `created_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_acc_me_code`    (`module_code`, `event_code`, `deleted_at`), -- One event_code per module (soft-delete aware)',
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

-- This is the table where the Master data of Event Voucher Configs will be created.
CREATE TABLE IF NOT EXISTS `acc_event_voucher_configs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_event_id`   BIGINT UNSIGNED NOT NULL, -- FK → acc_module_events',
    `voucher_type_id`   TINYINT UNSIGNED NOT NULL, -- FK → acc_voucher_types. Typically RECEIPT for income, JOURNAL for internal transfers',
    `cost_center_id`    BIGINT UNSIGNED NULL, -- FK → acc_cost_centers (optional default cost center for vouchers from this event)',
    `is_auto_post`      TINYINT(1) NOT NULL DEFAULT 0, -- 1 = immediately post to ledgers; 0 = create as draft (status=draft in acc_vouchers)',
    `requires_approval` TINYINT(1) NOT NULL DEFAULT 0, -- 1 = set voucher status to draft and route to approver; overrides is_auto_post if both = 1',
    `narration_template` VARCHAR(500) NULL, -- Voucher narration with placeholders: {student_name}, {amount}, {date}, {event_name}, {reference_no}, {module_ref}',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_acc_evc_event`       (`module_event_id`, `deleted_at`), -- One active config per event',
    INDEX `idx_acc_evc_voucher_type`     (`voucher_type_id`),
    INDEX `idx_acc_evc_cost_center`      (`cost_center_id`),
    INDEX `idx_acc_evc_active`           (`is_active`),
    CONSTRAINT `fk_acc_evc_event` FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_vtype` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_evc_cc` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-event voucher creation config: voucher type, posting mode, narration template';
-- Conditions :
-- if `is_auto_post` =1 and `requires_approval`=0 then voucher will be created as 'Auto_Post'
-- if `is_auto_post` =1 and `requires_approval`=1 then voucher will be created as 'Auto_Approved'
-- if `is_auto_post` =0 and `requires_approval`=1 then voucher will be created as 'Draft'
-- if `is_auto_post` =0 and `requires_approval`=0 then voucher will be created as 'Draft'


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
--     Line 1: entry_type=Dr,  ledger_resolver=student_ledger,  → Student Debtor A/c
--     Line 2: entry_type=Cr, ledger_resolver=fixed, ledger_id=<Library Fine Income Ledger>
-- ============================================================================

-- This is the table where the Master data of Event Voucher Line Templates will be created.
CREATE TABLE IF NOT EXISTS `acc_event_voucher_line_templates` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `event_voucher_config_id`   BIGINT UNSIGNED NOT NULL, -- FK → acc_event_voucher_configs',
    `sequence`                  TINYINT UNSIGNED NOT NULL DEFAULT 1, -- Line order within the voucher (1-based). Determines display order in voucher.',
    `entry_type`                ENUM('Dr','Cr') NOT NULL, -- Dr-Debit or Cr-Credit side of the double-entry line',
    -- ── Ledger Resolution ──────────────────────────────────────────────────
    `ledger_resolver`           ENUM('fixed','student_ledger','vendor_ledger','employee_ledger') NOT NULL DEFAULT 'fixed', -- Strategy to resolve which ledger to post this line against at runtime',
    `ledger_id`                 INT UNSIGNED NULL, -- FK → acc_ledgers. Required when ledger_resolver = fixed. NULL for dynamic resolvers.',
    -- ── Amount Resolution ──────────────────────────────────────────────────
    `amount_resolver`           ENUM('from_source','fixed_amount','from_payload') NOT NULL DEFAULT 'from_source', -- Strategy to resolve the line amount at runtime',
    `source_amount_field`       VARCHAR(100) NULL, -- Column name in source model to read amount from. e.g., amount, fine_amount, fare, paid_amount. Used when amount_resolver = from_source.',
    `fixed_amount`              DECIMAL(15,2) NULL, -- Hard-coded amount used when amount_resolver = fixed_amount',
    `narration`                 VARCHAR(500) NULL, -- Per-line narration. Can use same placeholders as narration_template. Overrides header narration for this line.',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
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

-- This is the table where the Log data of Event Processing will be created.
CREATE TABLE IF NOT EXISTS `acc_event_processing_log` (
	`id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`module_event_id`   BIGINT UNSIGNED NOT NULL, -- FK → acc_module_events',
	`source_model`      VARCHAR(100) NOT NULL, -- Source table name (denormalized from event for fast querying without join)',
	`source_id`         BIGINT UNSIGNED NOT NULL, -- Primary key of the triggering source record (e.g., lib_fines.id, tpt_student_route_allocation_jnt.id)',
	`payload_json`      JSON NULL, -- Snapshot of critical fields from the source record at event time. Preserves audit integrity.',
	`voucher_id`        BIGINT UNSIGNED NULL, -- FK → acc_vouchers. Set after successful processing. NULL if failed or skipped.',
	`status`            MEDIUMINT UNSIGNED NOT NULL, -- FK to `acc_accounting_status_masters` - Pending=queued, Processed=voucher created, Failed=error, Skipped=no config or duplicate guard',
	`error_message`     TEXT NULL, -- Error detail when status = failed. Includes stack trace or validation message.',
	`retry_count`       TINYINT UNSIGNED NOT NULL DEFAULT 0, -- Number of automated retry attempts. Used by job scheduler to cap retries.',
	`processed_at`      TIMESTAMP NULL, -- Timestamp when the event was successfully processed (voucher created)',
	`is_active`         TINYINT(1) NOT NULL DEFAULT 1, -- Soft active flag',
	`created_by`        INT UNSIGNED NULL, -- FK → sys_users. The user whose action triggered the event, or system user if automated.',
	`created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	`updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at`        TIMESTAMP NULL DEFAULT NULL,
	PRIMARY KEY (`id`),
	INDEX `idx_acc_epl_event`       (`module_event_id`),
	INDEX `idx_acc_epl_source`      (`source_model`, `source_id`), -- Lookup: has this source record already been processed?',
	INDEX `idx_acc_epl_voucher`     (`voucher_id`),
	INDEX `idx_acc_epl_status`      (`status`),
	INDEX `idx_acc_epl_pending`     (`status`, `retry_count`), -- Job queue index: find pending/failed events to retry',
	CONSTRAINT `fk_acc_epl_event` FOREIGN KEY (`module_event_id`) REFERENCES `acc_module_events` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_epl_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_acc_epl_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`) ON DELETE RESTRICT,
	CONSTRAINT `fk_acc_epl_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit trail of all cross-module events received and their voucher processing outcome';


-- ======================================================================================================================================================
-- Change Log
-- ======================================================================================================================================================
-- Add New Tables : `acc_accounting_status_masters`, `tco_app_modules`, `acc_voucher_category`
-- Change Table: `acc_account_groups` Field (`nature` ENUM('Asset','Liability','Equity','Income','Expense') NOT NULL,)
-- Change Table : `acc_ledgers` Field (   `gst_registration_type`     ENUM('Regular','Composition','Unregistered','SEZ','Consumer') NULL,)
-- Table : `acc_voucher_types`; Remove - `category` ENUM('Accounting','Inventory','Payroll','Order') NOT NULL COMMENT 'Domain category',
-- Table : `acc_voucher_types`; Add - `voucher_category_id`  TINYINT UNSIGNED NOT NULL,
-- Table : `acc_voucher_types`; Add - CONSTRAINT `fk_vt_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT
-- Table `acc_vouchers`; Remove - `category` ENUM('Accounting','Inventory','Payroll','Order') NOT NULL COMMENT 'Domain category',
-- Table `acc_vouchers`; Add - `voucher_category_id`  TINYINT UNSIGNED NOT NULL,
-- Table `acc_vouchers`; Add - CONSTRAINT `fk_voucher_category` FOREIGN KEY (`voucher_category_id`) REFERENCES `acc_voucher_category`(`id`) ON DELETE RESTRICT
	






-- Change Tbale: acc_event_processing_log
-- 1. Add `status` column to `acc_event_processing_log`


