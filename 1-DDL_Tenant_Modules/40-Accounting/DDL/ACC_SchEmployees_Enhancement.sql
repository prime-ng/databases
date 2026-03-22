-- ============================================================================
-- sch_employees Enhancement for Accounting/Payroll Integration
-- ALTER TABLE — adds 14 payroll columns to existing sch_employees
-- Date: 2026-03-21
-- ============================================================================
-- IMPORTANT: Use Schema::hasColumn() guard in Laravel migration
-- Some columns may already exist in the table
-- ============================================================================

-- Add is_active if missing (not in original DDL)
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft active flag'
    AFTER `notes`;

-- Add created_by if missing (not in original DDL)
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `created_by` BIGINT UNSIGNED NULL COMMENT 'FK → sys_users'
    AFTER `is_active`;

-- Staff category for payroll grouping (maps to sch_categories)
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `staff_category_id` INT UNSIGNED NULL COMMENT 'FK → sch_categories (staff group for leave config & payroll)'
    AFTER `created_by`;

-- Accounting ledger link (auto-created salary payable ledger)
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `ledger_id` BIGINT UNSIGNED NULL COMMENT 'FK → acc_ledgers (salary payable auto-ledger)'
    AFTER `staff_category_id`;

-- Payroll salary structure assignment
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `salary_structure_id` BIGINT UNSIGNED NULL COMMENT 'FK → prl_salary_structures'
    AFTER `ledger_id`;

-- Bank details for salary disbursement
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `bank_name` VARCHAR(100) NULL COMMENT 'Salary disbursement bank'
    AFTER `salary_structure_id`;

ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `bank_account_number` VARCHAR(50) NULL COMMENT 'Bank account number'
    AFTER `bank_name`;

ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `bank_ifsc` VARCHAR(20) NULL COMMENT 'Bank IFSC code'
    AFTER `bank_account_number`;

-- Statutory identification numbers
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `pf_number` VARCHAR(30) NULL COMMENT 'PF account number'
    AFTER `bank_ifsc`;

ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `esi_number` VARCHAR(30) NULL COMMENT 'ESI number'
    AFTER `pf_number`;

ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `uan` VARCHAR(20) NULL COMMENT 'Universal Account Number'
    AFTER `esi_number`;

ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `pan` VARCHAR(15) NULL COMMENT 'PAN card number'
    AFTER `uan`;

-- CTC and leaving date
ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `ctc_monthly` DECIMAL(15,2) NULL COMMENT 'Monthly CTC amount'
    AFTER `pan`;

ALTER TABLE `sch_employees` ADD COLUMN IF NOT EXISTS
    `date_of_leaving` DATE NULL COMMENT 'Relieving/exit date'
    AFTER `ctc_monthly`;

-- Add indexes for new FK columns
CREATE INDEX IF NOT EXISTS `idx_sch_emp_category` ON `sch_employees` (`staff_category_id`);
CREATE INDEX IF NOT EXISTS `idx_sch_emp_ledger` ON `sch_employees` (`ledger_id`);
CREATE INDEX IF NOT EXISTS `idx_sch_emp_salary_structure` ON `sch_employees` (`salary_structure_id`);
