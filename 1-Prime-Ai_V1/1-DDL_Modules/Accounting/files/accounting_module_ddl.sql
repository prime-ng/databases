-- ============================================================================
-- SCHOOL ACCOUNTING MODULE — DDL (tenant_db)
-- Prefix: acc_
-- Version: 2.0 — 2026-03-17
-- Inspired by Tally Prime, adapted for Prime-AI multi-tenant architecture
-- Incorporates features from Account_ddl_v1.sql (pgdatabase)
-- ============================================================================
-- 7 Domains:
--   Core Accounting  (10 tables)  — Groups, Ledgers, Vouchers, Cost Centers, Budgets, Tax, Mappings, Recurring
--   Payroll          (8 tables)   — Employees, Pay Heads, Salary, Attendance, Runs
--   Inventory        (5 tables)   — Stock Groups, Items, Godowns, UoM, Entries
--   Banking          (2 tables)   — Reconciliation, Statement Import
--   Fixed Assets     (3 tables)   — Categories, Assets, Depreciation
--   Expense Claims   (2 tables)   — Claims, Claim Lines
--   Data Export      (1 table)    — Tally Export Logs
-- Total: 31 tables
-- ============================================================================

-- ============================================================================
-- DOMAIN 1: CORE ACCOUNTING (7 tables)
-- ============================================================================

-- 1. Financial Year Configuration
CREATE TABLE IF NOT EXISTS `acc_financial_years` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(50) NOT NULL COMMENT 'e.g., 2025-26',
    `start_date`        DATE NOT NULL COMMENT 'Financial year start (April 1)',
    `end_date`          DATE NOT NULL COMMENT 'Financial year end (March 31)',
    `is_locked`         TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Prevents edits when locked',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_fy_active` (`is_active`),
    INDEX `idx_acc_fy_dates` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Account Groups (Tally's 28 predefined groups + custom)
CREATE TABLE IF NOT EXISTS `acc_account_groups` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(100) NOT NULL COMMENT 'Group name',
    `code`                  VARCHAR(20) NOT NULL COMMENT 'Unique group code e.g., A01, L02',
    `alias`                 VARCHAR(100) NULL COMMENT 'Alternative display name',
    `parent_id`             BIGINT UNSIGNED NULL COMMENT 'Self-referencing for hierarchy',
    `nature`                ENUM('asset','liability','income','expense') NOT NULL COMMENT 'Account nature',
    `affects_gross_profit`  TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Direct vs Indirect classification',
    `is_system`             TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'true = seeded, cannot delete',
    `is_subledger`          TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Behaves as sub-ledger',
    `sequence`              INT NOT NULL DEFAULT 0 COMMENT 'Display order in reports',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
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

-- 3. Ledgers (Individual accounts)
CREATE TABLE IF NOT EXISTS `acc_ledgers` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                      VARCHAR(150) NOT NULL COMMENT 'Ledger name',
    `code`                      VARCHAR(20) NULL COMMENT 'Unique ledger code',
    `alias`                     VARCHAR(150) NULL COMMENT 'Alternative name',
    `account_group_id`          BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_account_groups',
    `opening_balance`           DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `opening_balance_type`      ENUM('Dr','Cr') NULL COMMENT 'Debit or Credit opening',
    `is_bank_account`           TINYINT(1) NOT NULL DEFAULT 0,
    `bank_name`                 VARCHAR(100) NULL,
    `bank_account_number`       VARCHAR(50) NULL,
    `ifsc_code`                 VARCHAR(20) NULL,
    `is_cash_account`           TINYINT(1) NOT NULL DEFAULT 0,
    `allow_reconciliation`      TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Enable bank reconciliation for this ledger',
    `is_system`                 TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'P&L A/c, Cash A/c etc.',
    `student_id`                BIGINT UNSIGNED NULL COMMENT 'FK → std_students (auto-ledger)',
    `employee_id`               BIGINT UNSIGNED NULL COMMENT 'FK → acc_employees (auto-ledger)',
    `gst_registration_type`     VARCHAR(30) NULL COMMENT 'Regular, Composition, etc.',
    `gstin`                     VARCHAR(20) NULL,
    `pan`                       VARCHAR(15) NULL,
    `address`                   TEXT NULL,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                BIGINT UNSIGNED NULL,
    `created_at`                TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ledger_group` (`account_group_id`),
    INDEX `idx_acc_ledger_student` (`student_id`),
    INDEX `idx_acc_ledger_employee` (`employee_id`),
    INDEX `idx_acc_ledger_bank` (`is_bank_account`),
    INDEX `idx_acc_ledger_active` (`is_active`),
    CONSTRAINT `fk_acc_ledger_group` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Voucher Types (Payment, Receipt, Contra, Journal, Sales, Purchase, etc.)
CREATE TABLE IF NOT EXISTS `acc_voucher_types` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(80) NOT NULL COMMENT 'e.g., Payment, Receipt, Journal',
    `code`              VARCHAR(20) NOT NULL COMMENT 'PAYMENT, RECEIPT, CONTRA, JOURNAL, SALES, PURCHASE, CREDIT_NOTE, DEBIT_NOTE, STOCK_JOURNAL, PAYROLL',
    `category`          ENUM('accounting','inventory','payroll','order') NOT NULL,
    `prefix`            VARCHAR(20) NULL COMMENT 'Voucher number prefix e.g., PAY-, RCV-',
    `auto_numbering`    TINYINT(1) NOT NULL DEFAULT 1,
    `last_number`       INT NOT NULL DEFAULT 0,
    `is_system`         TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_vt_code` (`code`, `deleted_at`),
    INDEX `idx_acc_vt_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Vouchers (All transactions — the heart of double-entry)
CREATE TABLE IF NOT EXISTS `acc_vouchers` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_number`    VARCHAR(50) NOT NULL COMMENT 'Auto-generated, unique per FY',
    `voucher_type_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_types',
    `financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
    `date`              DATE NOT NULL COMMENT 'Transaction date',
    `reference_number`  VARCHAR(100) NULL COMMENT 'Cheque no, receipt no, etc.',
    `reference_date`    DATE NULL COMMENT 'Cheque date, etc.',
    `narration`         TEXT NULL COMMENT 'Transaction description',
    `total_amount`      DECIMAL(15,2) NOT NULL COMMENT 'Total voucher amount',
    `is_post_dated`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_optional`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Memorandum voucher',
    `is_cancelled`      TINYINT(1) NOT NULL DEFAULT 0,
    `cancelled_reason`  TEXT NULL,
    `cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers',
    `source_type`       VARCHAR(100) NULL COMMENT 'Polymorphic: FeePayment, PayrollRun, etc.',
    `source_id`         BIGINT UNSIGNED NULL COMMENT 'Polymorphic source ID',
    `status`            ENUM('draft','posted','approved','cancelled') NOT NULL DEFAULT 'draft',
    `created_by`        BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `approved_by`       BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_voucher_type` (`voucher_type_id`),
    INDEX `idx_acc_voucher_fy` (`financial_year_id`),
    INDEX `idx_acc_voucher_date` (`date`),
    INDEX `idx_acc_voucher_status` (`status`),
    INDEX `idx_acc_voucher_source` (`source_type`, `source_id`),
    INDEX `idx_acc_voucher_cost` (`cost_center_id`),
    UNIQUE KEY `uq_acc_voucher_number_fy` (`voucher_number`, `financial_year_id`, `deleted_at`),
    CONSTRAINT `fk_acc_voucher_type` FOREIGN KEY (`voucher_type_id`) REFERENCES `acc_voucher_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_voucher_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_voucher_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Voucher Line Items (Dr/Cr entries — double-entry lines)
CREATE TABLE IF NOT EXISTS `acc_voucher_items` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_vouchers',
    `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
    `type`              ENUM('debit','credit') NOT NULL,
    `amount`            DECIMAL(15,2) NOT NULL,
    `narration`         VARCHAR(500) NULL COMMENT 'Per-ledger narration',
    `cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers',
    `bill_reference`    VARCHAR(100) NULL COMMENT 'Against invoice/bill',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
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

-- 7. Cost Centers (Department/Wing/Activity-based tracking)
CREATE TABLE IF NOT EXISTS `acc_cost_centers` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(100) NOT NULL COMMENT 'e.g., Primary Wing, Senior Wing, Transport',
    `code`              VARCHAR(20) NULL COMMENT 'Cost center code e.g., CC-SCI',
    `parent_id`         BIGINT UNSIGNED NULL COMMENT 'Self-referencing hierarchy',
    `category`          VARCHAR(50) NULL COMMENT 'Department, Activity, Project',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_cc_parent` (`parent_id`),
    CONSTRAINT `fk_acc_cc_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Budgets (Budget vs Actual tracking)
CREATE TABLE IF NOT EXISTS `acc_budgets` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
    `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers',
    `cost_center_id`    BIGINT UNSIGNED NULL COMMENT 'FK → acc_cost_centers',
    `budget_amount`     DECIMAL(15,2) NOT NULL COMMENT 'Planned amount',
    `budget_type`       ENUM('on_net_transactions','on_closing_balance') NOT NULL,
    `period`            ENUM('annual','quarterly','monthly') NOT NULL DEFAULT 'annual',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_budget_fy` (`financial_year_id`),
    INDEX `idx_acc_budget_ledger` (`ledger_id`),
    INDEX `idx_acc_budget_cost` (`cost_center_id`),
    CONSTRAINT `fk_acc_budget_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_budget_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_budget_cost` FOREIGN KEY (`cost_center_id`) REFERENCES `acc_cost_centers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- DOMAIN 2: PAYROLL (8 tables)
-- ============================================================================

-- 9. Employee Groups (Teaching, Non-teaching, Admin, Contract)
CREATE TABLE IF NOT EXISTS `acc_employee_groups` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(80) NOT NULL COMMENT 'Teaching, Non-teaching, Admin, etc.',
    `parent_id`         BIGINT UNSIGNED NULL COMMENT 'Self-referencing hierarchy',
    `pf_applicable`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Group-level PF default',
    `esi_applicable`    TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Group-level ESI default',
    `pt_applicable`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Group-level PT default',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_eg_parent` (`parent_id`),
    CONSTRAINT `fk_acc_eg_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_employee_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Employees (Staff master for payroll)
CREATE TABLE IF NOT EXISTS `acc_employees` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_code`         VARCHAR(30) NOT NULL COMMENT 'Unique staff code',
    `name`                  VARCHAR(150) NOT NULL,
    `employee_group_id`     BIGINT UNSIGNED NULL COMMENT 'FK → acc_employee_groups',
    `designation`           VARCHAR(100) NULL,
    `department`            VARCHAR(100) NULL,
    `date_of_birth`         DATE NULL,
    `date_of_joining`       DATE NOT NULL,
    `date_of_leaving`       DATE NULL,
    `gender`                ENUM('male','female','other') NULL,
    `pan`                   VARCHAR(15) NULL,
    `aadhaar`               VARCHAR(20) NULL,
    `bank_account_number`   VARCHAR(30) NULL,
    `bank_name`             VARCHAR(100) NULL,
    `ifsc_code`             VARCHAR(15) NULL,
    `pf_number`             VARCHAR(30) NULL COMMENT 'PF account number',
    `esi_number`            VARCHAR(30) NULL COMMENT 'ESI IP number',
    `uan`                   VARCHAR(20) NULL COMMENT 'Universal Account Number',
    `is_pf_applicable`      TINYINT(1) NOT NULL DEFAULT 1,
    `is_esi_applicable`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_pt_applicable`      TINYINT(1) NOT NULL DEFAULT 1,
    `is_tds_applicable`     TINYINT(1) NOT NULL DEFAULT 0,
    `ledger_id`             BIGINT UNSIGNED NULL COMMENT 'Auto-created salary ledger',
    `teacher_id`            BIGINT UNSIGNED NULL COMMENT 'FK → sch_teachers (link to SchoolSetup)',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_emp_code` (`employee_code`, `deleted_at`),
    INDEX `idx_acc_emp_group` (`employee_group_id`),
    INDEX `idx_acc_emp_ledger` (`ledger_id`),
    INDEX `idx_acc_emp_teacher` (`teacher_id`),
    INDEX `idx_acc_emp_active` (`is_active`),
    CONSTRAINT `fk_acc_emp_group` FOREIGN KEY (`employee_group_id`) REFERENCES `acc_employee_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_acc_emp_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Pay Heads (Earnings/Deductions definitions)
CREATE TABLE IF NOT EXISTS `acc_pay_heads` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(100) NOT NULL COMMENT 'e.g., Basic Salary, HRA, PF Employee',
    `type`                  ENUM('earning','deduction','employer_contribution') NOT NULL,
    `calculation_type`      ENUM('flat_amount','percentage','on_attendance','computed') NOT NULL,
    `computation_formula`   TEXT NULL COMMENT 'JSON formula definition',
    `percentage_of`         VARCHAR(100) NULL COMMENT 'Pay head name it is % of',
    `percentage_value`      DECIMAL(6,2) NULL COMMENT 'e.g., 12.00 for PF 12%',
    `statutory_type`        VARCHAR(50) NULL COMMENT 'pf, esi, pt, tds, nps',
    `affects_net_salary`    TINYINT(1) NOT NULL DEFAULT 1,
    `ledger_id`             BIGINT UNSIGNED NULL COMMENT 'FK → acc_ledgers',
    `sequence`              INT NOT NULL DEFAULT 0 COMMENT 'Display order in payslip',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ph_type` (`type`),
    INDEX `idx_acc_ph_statutory` (`statutory_type`),
    INDEX `idx_acc_ph_ledger` (`ledger_id`),
    CONSTRAINT `fk_acc_ph_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Salary Structures (Templates per employee group)
CREATE TABLE IF NOT EXISTS `acc_salary_structures` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(100) NOT NULL COMMENT 'e.g., Teaching Staff Grade-1',
    `employee_group_id`     BIGINT UNSIGNED NULL COMMENT 'FK → acc_employee_groups',
    `effective_from`        DATE NOT NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ss_group` (`employee_group_id`),
    CONSTRAINT `fk_acc_ss_group` FOREIGN KEY (`employee_group_id`) REFERENCES `acc_employee_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Salary Structure Items (Pay heads within a structure)
CREATE TABLE IF NOT EXISTS `acc_salary_structure_items` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `salary_structure_id`   BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_salary_structures',
    `pay_head_id`           BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_pay_heads',
    `default_amount`        DECIMAL(12,2) NULL COMMENT 'Default value if flat',
    `formula_override`      TEXT NULL COMMENT 'Override formula for this structure',
    `sequence`              INT NOT NULL DEFAULT 0 COMMENT 'Order in payslip',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ssi_structure` (`salary_structure_id`),
    INDEX `idx_acc_ssi_payhead` (`pay_head_id`),
    CONSTRAINT `fk_acc_ssi_structure` FOREIGN KEY (`salary_structure_id`) REFERENCES `acc_salary_structures` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ssi_payhead` FOREIGN KEY (`pay_head_id`) REFERENCES `acc_pay_heads` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. Payroll Runs (Monthly batch processing)
CREATE TABLE IF NOT EXISTS `acc_payroll_runs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `financial_year_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_financial_years',
    `month`             TINYINT UNSIGNED NOT NULL COMMENT '1-12',
    `year`              SMALLINT UNSIGNED NOT NULL COMMENT 'e.g., 2026',
    `run_date`          DATE NOT NULL COMMENT 'Processing date',
    `total_gross`       DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `total_deductions`  DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `total_net`         DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `employee_count`    INT NOT NULL DEFAULT 0,
    `status`            ENUM('draft','processed','posted','paid') NOT NULL DEFAULT 'draft',
    `voucher_id`        BIGINT UNSIGNED NULL COMMENT 'FK → acc_vouchers (posted journal)',
    `processed_by`      BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_pr_month_year` (`month`, `year`, `financial_year_id`, `deleted_at`),
    INDEX `idx_acc_pr_fy` (`financial_year_id`),
    INDEX `idx_acc_pr_status` (`status`),
    INDEX `idx_acc_pr_voucher` (`voucher_id`),
    CONSTRAINT `fk_acc_pr_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_pr_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. Payroll Entries (Per-employee per-pay-head calculated amounts)
CREATE TABLE IF NOT EXISTS `acc_payroll_entries` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `payroll_run_id`    BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_payroll_runs',
    `employee_id`       BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_employees',
    `pay_head_id`       BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_pay_heads',
    `amount`            DECIMAL(12,2) NOT NULL COMMENT 'Calculated amount',
    `pay_head_type`     ENUM('earning','deduction','employer_contribution') NOT NULL,
    `days_worked`       DECIMAL(5,2) NULL COMMENT 'If attendance-based',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_pe_run` (`payroll_run_id`),
    INDEX `idx_acc_pe_employee` (`employee_id`),
    INDEX `idx_acc_pe_payhead` (`pay_head_id`),
    CONSTRAINT `fk_acc_pe_run` FOREIGN KEY (`payroll_run_id`) REFERENCES `acc_payroll_runs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_pe_employee` FOREIGN KEY (`employee_id`) REFERENCES `acc_employees` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_pe_payhead` FOREIGN KEY (`pay_head_id`) REFERENCES `acc_pay_heads` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. Employee Attendance (Monthly attendance for salary calc)
CREATE TABLE IF NOT EXISTS `acc_employee_attendance` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`       BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_employees',
    `month`             TINYINT UNSIGNED NOT NULL COMMENT '1-12',
    `year`              SMALLINT UNSIGNED NOT NULL,
    `total_days`        DECIMAL(5,2) NOT NULL COMMENT 'Working days in month',
    `present_days`      DECIMAL(5,2) NOT NULL,
    `leave_with_pay`    DECIMAL(5,2) NOT NULL DEFAULT 0,
    `leave_without_pay` DECIMAL(5,2) NOT NULL DEFAULT 0,
    `overtime_hours`    DECIMAL(6,2) NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ea_emp_month` (`employee_id`, `month`, `year`, `deleted_at`),
    INDEX `idx_acc_ea_employee` (`employee_id`),
    CONSTRAINT `fk_acc_ea_employee` FOREIGN KEY (`employee_id`) REFERENCES `acc_employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- DOMAIN 3: INVENTORY (5 tables)
-- ============================================================================

-- 17. Stock Groups (Uniforms, Stationery, Lab Supplies, Sports, IT)
CREATE TABLE IF NOT EXISTS `acc_stock_groups` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(100) NOT NULL,
    `parent_id`         BIGINT UNSIGNED NULL COMMENT 'Self-referencing hierarchy',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_sg_parent` (`parent_id`),
    CONSTRAINT `fk_acc_sg_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_stock_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. Units of Measure (Pcs, Kg, Ltr, Box, Ream, Set)
CREATE TABLE IF NOT EXISTS `acc_units_of_measure` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(30) NOT NULL COMMENT 'Pieces, Kilogram, Litre, Box, Ream',
    `symbol`            VARCHAR(10) NOT NULL COMMENT 'Pcs, Kg, Ltr, Box',
    `decimal_places`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. Stock Items (Individual inventory items)
CREATE TABLE IF NOT EXISTS `acc_stock_items` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(200) NOT NULL,
    `code`                  VARCHAR(50) NULL COMMENT 'SKU/item code',
    `stock_group_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_stock_groups',
    `unit_id`               BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_units_of_measure',
    `hsn_sac_code`          VARCHAR(20) NULL COMMENT 'GST HSN/SAC',
    `gst_rate`              DECIMAL(5,2) NULL COMMENT 'GST percentage',
    `purchase_rate`         DECIMAL(12,2) NULL COMMENT 'Standard purchase price',
    `selling_rate`          DECIMAL(12,2) NULL COMMENT 'Standard selling price',
    `reorder_level`         DECIMAL(12,2) NOT NULL DEFAULT 0,
    `minimum_order_qty`     DECIMAL(12,2) NOT NULL DEFAULT 0,
    `valuation_method`      ENUM('fifo','weighted_avg','last_purchase') NOT NULL DEFAULT 'weighted_avg',
    `has_batch`             TINYINT(1) NOT NULL DEFAULT 0,
    `has_expiry`            TINYINT(1) NOT NULL DEFAULT 0,
    `opening_qty`           DECIMAL(12,2) NOT NULL DEFAULT 0,
    `opening_rate`          DECIMAL(12,2) NOT NULL DEFAULT 0,
    `opening_value`         DECIMAL(15,2) NOT NULL DEFAULT 0,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_si_group` (`stock_group_id`),
    INDEX `idx_acc_si_unit` (`unit_id`),
    INDEX `idx_acc_si_code` (`code`),
    INDEX `idx_acc_si_active` (`is_active`),
    CONSTRAINT `fk_acc_si_group` FOREIGN KEY (`stock_group_id`) REFERENCES `acc_stock_groups` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_si_unit` FOREIGN KEY (`unit_id`) REFERENCES `acc_units_of_measure` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 20. Godowns / Storage Locations
CREATE TABLE IF NOT EXISTS `acc_godowns` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(100) NOT NULL COMMENT 'Main Store, Lab Store, Sports Room',
    `parent_id`         BIGINT UNSIGNED NULL COMMENT 'Self-referencing',
    `address`           TEXT NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_godown_parent` (`parent_id`),
    CONSTRAINT `fk_acc_godown_parent` FOREIGN KEY (`parent_id`) REFERENCES `acc_godowns` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 21. Stock Entries (Inward/Outward movements linked to vouchers)
CREATE TABLE IF NOT EXISTS `acc_stock_entries` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_id`            BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_vouchers',
    `stock_item_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_stock_items',
    `godown_id`             BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_godowns',
    `type`                  ENUM('inward','outward') NOT NULL,
    `quantity`              DECIMAL(12,2) NOT NULL,
    `rate`                  DECIMAL(12,2) NOT NULL,
    `amount`                DECIMAL(15,2) NOT NULL,
    `batch_number`          VARCHAR(50) NULL,
    `manufacturing_date`    DATE NULL,
    `expiry_date`           DATE NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_se_voucher` (`voucher_id`),
    INDEX `idx_acc_se_item` (`stock_item_id`),
    INDEX `idx_acc_se_godown` (`godown_id`),
    INDEX `idx_acc_se_type` (`type`),
    CONSTRAINT `fk_acc_se_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_se_item` FOREIGN KEY (`stock_item_id`) REFERENCES `acc_stock_items` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_se_godown` FOREIGN KEY (`godown_id`) REFERENCES `acc_godowns` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- DOMAIN 4: BANKING (2 tables)
-- ============================================================================

-- 22. Bank Reconciliation (Match book entries with bank statement)
CREATE TABLE IF NOT EXISTS `acc_bank_reconciliations` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_item_id`       BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_voucher_items',
    `bank_date`             DATE NULL COMMENT 'Date cleared by bank',
    `instrument_number`     VARCHAR(50) NULL COMMENT 'Cheque/DD/NEFT ref',
    `instrument_date`       DATE NULL,
    `is_reconciled`         TINYINT(1) NOT NULL DEFAULT 0,
    `reconciled_at`         TIMESTAMP NULL,
    `reconciled_by`         BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_br_voucher_item` (`voucher_item_id`),
    INDEX `idx_acc_br_reconciled` (`is_reconciled`),
    CONSTRAINT `fk_acc_br_voucher_item` FOREIGN KEY (`voucher_item_id`) REFERENCES `acc_voucher_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 23. Bank Statement Imports (Imported bank data for matching)
CREATE TABLE IF NOT EXISTS `acc_bank_statement_entries` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`             BIGINT UNSIGNED NOT NULL COMMENT 'FK → acc_ledgers (bank ledger)',
    `transaction_date`      DATE NOT NULL,
    `description`           VARCHAR(500) NULL,
    `reference_number`      VARCHAR(100) NULL,
    `debit_amount`          DECIMAL(15,2) NULL COMMENT 'Withdrawal',
    `credit_amount`         DECIMAL(15,2) NULL COMMENT 'Deposit',
    `running_balance`       DECIMAL(15,2) NULL,
    `is_matched`            TINYINT(1) NOT NULL DEFAULT 0,
    `matched_voucher_item_id` BIGINT UNSIGNED NULL COMMENT 'FK → acc_voucher_items',
    `import_batch`          VARCHAR(50) NULL COMMENT 'Import batch identifier',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_bse_ledger` (`ledger_id`),
    INDEX `idx_acc_bse_date` (`transaction_date`),
    INDEX `idx_acc_bse_matched` (`is_matched`),
    INDEX `idx_acc_bse_matched_vi` (`matched_voucher_item_id`),
    CONSTRAINT `fk_acc_bse_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_bse_matched_vi` FOREIGN KEY (`matched_voucher_item_id`) REFERENCES `acc_voucher_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- DOMAIN 5: FIXED ASSETS (3 tables) — from Account_ddl_v1.sql
-- ============================================================================

-- 24. Asset Categories (Depreciation groups)
CREATE TABLE IF NOT EXISTS `acc_asset_categories` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(100) NOT NULL COMMENT 'e.g., Furniture, Vehicles, IT Equipment',
    `code`                  VARCHAR(20) NOT NULL,
    `depreciation_method`   ENUM('SLM','WDV') NOT NULL COMMENT 'Straight Line / Written Down Value',
    `depreciation_rate`     DECIMAL(5,2) NOT NULL COMMENT 'Annual depreciation rate %',
    `useful_life_years`     INT NULL COMMENT 'Useful life in years',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ac_code` (`code`, `deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 25. Fixed Assets (Individual assets with depreciation tracking)
CREATE TABLE IF NOT EXISTS `acc_fixed_assets` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                      VARCHAR(150) NOT NULL,
    `asset_code`                VARCHAR(50) NOT NULL COMMENT 'Unique asset identifier',
    `asset_category_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_asset_categories',
    `purchase_date`             DATE NOT NULL,
    `purchase_cost`             DECIMAL(15,2) NOT NULL,
    `salvage_value`             DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `current_value`             DECIMAL(15,2) NOT NULL,
    `accumulated_depreciation`  DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `location`                  VARCHAR(100) NULL COMMENT 'Physical location in school',
    `vendor_id`                 BIGINT UNSIGNED NULL COMMENT 'FK to vnd_vendors (cross-module)',
    `voucher_id`                BIGINT UNSIGNED NULL COMMENT 'FK to acc_vouchers (purchase voucher)',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                BIGINT UNSIGNED NULL,
    `created_at`                TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_fa_code` (`asset_code`, `deleted_at`),
    INDEX `idx_acc_fa_category` (`asset_category_id`),
    INDEX `idx_acc_fa_voucher` (`voucher_id`),
    CONSTRAINT `fk_acc_fa_category` FOREIGN KEY (`asset_category_id`) REFERENCES `acc_asset_categories` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_acc_fa_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 26. Depreciation Entries (Annual/periodic depreciation records)
CREATE TABLE IF NOT EXISTS `acc_depreciation_entries` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `fixed_asset_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_fixed_assets',
    `financial_year_id`     BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_financial_years',
    `depreciation_date`     DATE NOT NULL,
    `depreciation_amount`   DECIMAL(15,2) NOT NULL,
    `voucher_id`            BIGINT UNSIGNED NULL COMMENT 'FK to acc_vouchers (journal voucher)',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_de_asset` (`fixed_asset_id`),
    INDEX `idx_acc_de_fy` (`financial_year_id`),
    CONSTRAINT `fk_acc_de_asset` FOREIGN KEY (`fixed_asset_id`) REFERENCES `acc_fixed_assets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_de_fy` FOREIGN KEY (`financial_year_id`) REFERENCES `acc_financial_years` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- DOMAIN 6: EXPENSE CLAIMS (2 tables) — from Account_ddl_v1.sql
-- ============================================================================

-- 27. Expense Claims (Staff reimbursement requests)
CREATE TABLE IF NOT EXISTS `acc_expense_claims` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `claim_number`      VARCHAR(50) NOT NULL,
    `employee_id`       BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_employees',
    `claim_date`        DATE NOT NULL,
    `total_amount`      DECIMAL(15,2) NOT NULL,
    `status`            ENUM('draft','submitted','approved','rejected','paid') NOT NULL DEFAULT 'draft',
    `approved_by`       BIGINT UNSIGNED NULL COMMENT 'FK to sys_users',
    `approved_at`       TIMESTAMP NULL,
    `voucher_id`        BIGINT UNSIGNED NULL COMMENT 'FK to acc_vouchers (payment on approval)',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_ec_number` (`claim_number`, `deleted_at`),
    INDEX `idx_acc_ec_employee` (`employee_id`),
    INDEX `idx_acc_ec_status` (`status`),
    CONSTRAINT `fk_acc_ec_employee` FOREIGN KEY (`employee_id`) REFERENCES `acc_employees` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 28. Expense Claim Lines (Individual expense items)
CREATE TABLE IF NOT EXISTS `acc_expense_claim_lines` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `expense_claim_id`      BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_expense_claims',
    `expense_date`          DATE NOT NULL,
    `ledger_id`             BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_ledgers (expense ledger)',
    `description`           VARCHAR(255) NOT NULL,
    `amount`                DECIMAL(15,2) NOT NULL,
    `tax_amount`            DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `receipt_path`          VARCHAR(255) NULL COMMENT 'Uploaded receipt file path',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`            BIGINT UNSIGNED NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_ecl_claim` (`expense_claim_id`),
    INDEX `idx_acc_ecl_ledger` (`ledger_id`),
    CONSTRAINT `fk_acc_ecl_claim` FOREIGN KEY (`expense_claim_id`) REFERENCES `acc_expense_claims` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_ecl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- DOMAIN 7: SUPPORTING TABLES (4 tables) — from Account_ddl_v1.sql
-- ============================================================================

-- 29. Tax Rates (GST CGST/SGST/IGST rates)
CREATE TABLE IF NOT EXISTS `acc_tax_rates` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(100) NOT NULL COMMENT 'e.g., CGST 9%, SGST 9%',
    `rate`              DECIMAL(5,2) NOT NULL COMMENT 'Tax percentage',
    `type`              ENUM('CGST','SGST','IGST','Cess') NOT NULL,
    `is_interstate`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 30. Ledger Mappings (Cross-module polymorphic linking)
CREATE TABLE IF NOT EXISTS `acc_ledger_mappings` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_ledgers',
    `source_module`     ENUM('StudentFee','Library','Transport','Payroll','Vendor','StudentProfile') NOT NULL,
    `source_id`         BIGINT UNSIGNED NOT NULL COMMENT 'PK in source module table',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_acc_lm_ledger_source` (`ledger_id`, `source_module`, `source_id`),
    INDEX `idx_acc_lm_source` (`source_module`, `source_id`),
    CONSTRAINT `fk_acc_lm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 31. Recurring Journal Templates (Auto-repeating entries)
CREATE TABLE IF NOT EXISTS `acc_recurring_templates` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(150) NOT NULL,
    `frequency`         ENUM('daily','weekly','monthly','quarterly','yearly') NOT NULL,
    `day_of_month`      TINYINT UNSIGNED NULL COMMENT 'Day to auto-generate (1-28)',
    `start_date`        DATE NOT NULL,
    `end_date`          DATE NULL,
    `narration`         TEXT NULL,
    `total_amount`      DECIMAL(15,2) NOT NULL,
    `last_generated_at` DATE NULL COMMENT 'Last date this template generated a voucher',
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 32. Recurring Template Lines (Dr/Cr entries for templates)
CREATE TABLE IF NOT EXISTS `acc_recurring_template_lines` (
    `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `recurring_template_id`     BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_recurring_templates',
    `ledger_id`                 BIGINT UNSIGNED NOT NULL COMMENT 'FK to acc_ledgers',
    `type`                      ENUM('debit','credit') NOT NULL,
    `amount`                    DECIMAL(15,2) NOT NULL,
    `narration`                 VARCHAR(500) NULL,
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                BIGINT UNSIGNED NULL,
    `created_at`                TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_rtl_template` (`recurring_template_id`),
    INDEX `idx_acc_rtl_ledger` (`ledger_id`),
    CONSTRAINT `fk_acc_rtl_template` FOREIGN KEY (`recurring_template_id`) REFERENCES `acc_recurring_templates` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_acc_rtl_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 33. Tally Export Logs (Data export tracking)
CREATE TABLE IF NOT EXISTS `acc_tally_export_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `export_type`       ENUM('ledgers','vouchers','inventory','payroll') NOT NULL,
    `export_date`       DATETIME NOT NULL,
    `file_name`         VARCHAR(255) NOT NULL,
    `start_date`        DATE NULL,
    `end_date`          DATE NULL,
    `record_count`      INT NOT NULL DEFAULT 0,
    `status`            ENUM('success','failed','partial') NOT NULL,
    `error_log`         TEXT NULL,
    `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`        BIGINT UNSIGNED NULL,
    `created_at`        TIMESTAMP NULL DEFAULT NULL,
    `updated_at`        TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`        TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_acc_tel_type` (`export_type`),
    INDEX `idx_acc_tel_date` (`export_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
