-- ========================================================================================================
-- Student Fee Management Module DDL v3.0
-- ========================================================================================================
-- Author: Brijesh
-- Date: 2026-02-23
-- Module: Fee Management (fee)
-- Upgrade: v2 -> v4 (Bug fixes, requirement gaps, 3 new tables, seed data rewrite)
--
-- Description:
--   Comprehensive schema for Student Fee Management including:
--   - Fee Structure & Configuration (fee_head_master, fee_group_master, fee_structure_master)
--   - Fee Assignment (fee_student_assignments, fee_student_concessions)
--   - Fee Collection (fee_transactions, fee_transaction_details)
--   - Fine Management (fee_fine_rules, fee_fine_transactions)
--   - Scholarship Management (fee_scholarships, fee_scholarship_applications)
--   - Payment Gateway Integration (fee_payment_gateway_logs)
--   - Receipts & Invoices (fee_receipts, fee_invoices)
--   - Refund Management (fee_refunds) [NEW in v3]
--   - Cheque/DD Lifecycle (fee_cheque_clearance) [NEW in v3]
--   - Defaulter Analytics (fee_defaulter_history) [NEW in v3]
--
--
-- Dependencies:
--   - std_students (Student Core)
--   - std_guardians (Fee Payers)
--   - sch_org_academic_sessions_jnt (Academic Sessions) -- PK is SMALLINT UNSIGNED
--   - sch_classes (Class Setup)
--   - sys_users (Cashiers/Approvers)
--   - sys_dropdown_table (Lookups)
-- ========================================================================================================

-- --------------------------------------------------------------------------------------------------------
-- Table 1: fee_head_master
-- Purpose: Core fee components (Tuition, Transport, Hostel, etc.)
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_head_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(30) NOT NULL,                        -- Unique code (TUIT, TRAN, HOST, LIB, SPRT, EXAM, ACTV, LAB, DEV, OTH)
    `name` VARCHAR(100) NOT NULL,                       -- Display name (Tuition, Transport, Hostel, etc.)
    `description` VARCHAR(255) NULL,
    `head_type_id` INT UNSIGNED NOT NULL,               -- FK to sys_dropdown_table (fee_head_master.head_type_id)
    `frequency` ENUM('One-time', 'Monthly', 'Quarterly', 'Half-Yearly', 'Yearly') NOT NULL DEFAULT 'Monthly',
    `is_refundable` TINYINT(1) NOT NULL DEFAULT 0,
    `tax_applicable` TINYINT(1) NOT NULL DEFAULT 0,
    `tax_percentage` DECIMAL(5,2) DEFAULT 0.00,
    `account_head_code` VARCHAR(50) NULL COMMENT 'ERP Accounting Integration',
    `display_order` INT NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE INDEX `uq_fee_head_code` (`code`),
    INDEX `idx_fee_head_type` (`head_type_id`),
    INDEX `idx_fee_head_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 2: fee_group_master
-- Purpose: Logical grouping of fee heads (e.g., "Academic Package")
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_group_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `is_mandatory` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Student must take this group',
    `display_order` INT NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_fee_group_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 3: fee_group_heads_jnt
-- Purpose: Maps fee heads to groups with optional/mandatory flag per head
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_group_heads_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `group_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NOT NULL,
    `is_optional` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Student can opt out',
    `default_amount` DECIMAL(10,2) NULL COMMENT 'Default amount if fixed',
    `display_order` INT NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_fee_group_head` (`group_id`, `head_id`),
    CONSTRAINT `fk_fgh_group` FOREIGN KEY (`group_id`) REFERENCES `fee_group_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fgh_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 4: fee_structure_master
-- Purpose: Defines fee structure for class + academic session + category
-- [BUG-FIX] academic_session_id changed from INT to SMALLINT UNSIGNED
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_structure_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL COMMENT 'FK to sch_org_academic_sessions_jnt',
    `class_id` INT UNSIGNED NOT NULL COMMENT 'FK to sch_classes',
    `student_category_id` INT UNSIGNED NULL COMMENT 'FK to sys_dropdown_table (General/OBC/SC/ST)',
    `board_type` VARCHAR(50) NULL COMMENT 'CBSE/ICSE/State',
    `code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique code for the fee structure',
    `name` VARCHAR(100) NOT NULL COMMENT 'Name of the fee structure',
    `effective_from` DATE NOT NULL,
    `effective_to` DATE NULL,
    `total_fee_amount` DECIMAL(12,2) NULL COMMENT 'Pre-calculated sum',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_fee_structure_session_class` (`academic_session_id`, `class_id`),
    INDEX `idx_fee_structure_active` (`is_active`),
    CONSTRAINT `fk_fs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fs_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fs_category` FOREIGN KEY (`student_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 5: fee_structure_details
-- Purpose: Line items of fee structure (head-wise amounts)
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_structure_details` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `fee_structure_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NOT NULL,
    `group_id` INT UNSIGNED NULL COMMENT 'NULL if direct head assignment',
    `amount` DECIMAL(10,2) NOT NULL,
    `is_optional` TINYINT(1) NOT NULL DEFAULT 1,
    `tax_included` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_fee_structure_head` (`fee_structure_id`, `head_id`),
    CONSTRAINT `fk_fsd_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structure_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsd_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsd_group` FOREIGN KEY (`group_id`) REFERENCES `fee_group_master` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 6: fee_installments
-- Purpose: Defines installment schedules for fee structures
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_installments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `fee_structure_id` INT UNSIGNED NOT NULL,
    `installment_no` INT NOT NULL,
    `installment_name` VARCHAR(100) NOT NULL,
    `due_date` DATE NOT NULL,
    `percentage_due` DECIMAL(5,2) NOT NULL COMMENT 'Percentage of total fee',
    `amount_due` DECIMAL(10,2) NULL COMMENT 'Calculated amount',
    `grace_days` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_fee_installment_structure_no` (`fee_structure_id`, `installment_no`),
    CONSTRAINT `fk_fi_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structure_master` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 7: fee_fine_rules
-- Purpose: Defines late payment fine rules (tiered structure)
-- [ENHANCE] Added fine_calculation_mode (PerDay vs FlatPerTier)
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_fine_rules` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_name` VARCHAR(100) NOT NULL,
    `applicable_on` ENUM('Fee Structure', 'Installment', 'Head') NOT NULL DEFAULT 'Installment',
    `applicable_id` INT UNSIGNED NOT NULL COMMENT 'ID based on applicable_on',
    `fine_type` ENUM('Percentage', 'Fixed', 'Percentage+Capped') NOT NULL,
    `fine_value` DECIMAL(10,2) NOT NULL,
    `fine_calculation_mode` ENUM('PerDay', 'FlatPerTier') NOT NULL DEFAULT 'PerDay' COMMENT 'PerDay: fine_value x days. FlatPerTier: fine_value once for the tier',
    `max_fine_amount` DECIMAL(10,2) NULL COMMENT 'For Percentage+Capped',
    `grace_period_days` INT NOT NULL DEFAULT 0,
    `recurring` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Apply fine every day/week',
    `recurring_interval_days` INT NULL,
    `max_fine_installments` INT NULL COMMENT 'Max times fine can be applied',
    `applicable_from_day` INT NOT NULL DEFAULT 1,
    `applicable_to_day` INT NULL,
    `action_on_expiry` ENUM('None', 'Mark Defaulter', 'Remove Name', 'Suspend') NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_fine_applicable` (`applicable_on`, `applicable_id`),
    INDEX `idx_fine_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 8: fee_concession_types
-- Purpose: Types of concessions/discounts
-- [ENHANCE] Renamed concession_code->code, concession_name->name
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_concession_types` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `concession_category_id` INT UNSIGNED NOT NULL COMMENT 'FK to sys_dropdown_table (Sibling, Merit, Staff, Financial Aid, Sports, Alumni, Other)',
    `discount_type` ENUM('Percentage', 'Fixed Amount') NOT NULL,
    `discount_value` DECIMAL(10,2) NOT NULL,
    `applicable_on` ENUM('Total Fee', 'Specific Heads', 'Specific Groups') NOT NULL,
    `max_cap_amount` DECIMAL(10,2) NULL,
    `requires_approval` TINYINT(1) NOT NULL DEFAULT 1,
    `approval_level_role_id` INT NULL COMMENT 'FK to sys_roles (e.g. ClassTeacher, Principal, Management)',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_concession_category` (`concession_category_id`),
    CONSTRAINT `fk_concession_category` FOREIGN KEY (`concession_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 9: fee_concession_applicable_heads
-- Purpose: Maps concessions to specific heads or groups (mutually exclusive per row)
-- [ENHANCE] Added 'group_id' to support group-level concessions
-- [ENHANCE] Added CHECK constraint 'chk_cah_head_or_group' to ensure only one of head_id or group_id is set for each record
-- [BUG-FIX] Changed head_id and group_id from NOT NULL to NULL (CHECK requires one NULL)
-- [ENHANCE] Added uq_concession_group unique index for group path
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_concession_applicable_heads` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `concession_type_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NULL COMMENT 'FK to fee_head_master (when applicable_on = Specific Heads)',
    `group_id` INT UNSIGNED NULL COMMENT 'FK to fee_group_master (when applicable_on = Specific Groups)',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_concession_head` (`concession_type_id`, `head_id`),
    UNIQUE INDEX `uq_concession_group` (`concession_type_id`, `group_id`),
    CONSTRAINT `fk_cah_concession` FOREIGN KEY (`concession_type_id`) REFERENCES `fee_concession_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cah_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cah_group` FOREIGN KEY (`group_id`) REFERENCES `fee_group_master` (`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_cah_head_or_group` CHECK ((`head_id` IS NOT NULL AND `group_id` IS NULL) OR (`head_id` IS NULL AND `group_id` IS NOT NULL))    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 10: fee_student_assignments
-- Purpose: Fee structure assigned to individual students for an academic session
-- [BUG-FIX] academic_session_id changed from INT to SMALLINT UNSIGNED
-- [ENHANCE] Added proration columns (join_in_mid-year, fee_start_date, proration_percentage)
-- [ENHANCE] Added class_id & section_id for quick access (denormalization) to avoid joins during fee calculation and invoice generation
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_student_assignments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `class_id` INT UNSIGNED NOT NULL,   -- FK to sch_classes for quick access (denormalization)
    `section_id` INT UNSIGNED NULL,     -- FK to sch_sections for quick access (denormalization)
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `fee_structure_id` INT UNSIGNED NOT NULL,
    `total_fee_amount` DECIMAL(12,2) NOT NULL,
    `opted_heads` JSON NULL COMMENT 'Selected optional heads',
    `opted_groups` JSON NULL COMMENT 'Selected optional groups',
    `assignment_date` DATE NOT NULL,
    `join_in_mid-year` TINYINT(1) NOT NULL DEFAULT 0,
    `fee_start_date` DATE NULL COMMENT 'Actual fee start date for mid-year joins',
    `proration_percentage` DECIMAL(5,2) NULL COMMENT 'Percentage of total fee applicable',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE INDEX `uq_fee_student_session` (`student_id`, `academic_session_id`),
    INDEX `idx_fee_assignment_active` (`is_active`),
    CONSTRAINT `fk_fsa_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsa_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsa_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsa_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsa_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structure_master` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 11: fee_student_concessions
-- Purpose: Concessions applied to specific students
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_student_concessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_assignment_id` INT UNSIGNED NOT NULL,
    `concession_type_id` INT UNSIGNED NOT NULL,
    `approved_by` INT UNSIGNED NULL COMMENT 'FK to sys_users',
    `approved_at` TIMESTAMP NULL,
    `approval_status` ENUM('Pending', 'Approved', 'Rejected') NOT NULL DEFAULT 'Pending',
    `rejection_reason` TEXT NULL,
    `discount_amount` DECIMAL(10,2) NOT NULL,
    `remarks` TEXT NULL,
    `created_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_concession_status` (`approval_status`),
    CONSTRAINT `fk_fsc_assignment` FOREIGN KEY (`student_assignment_id`) REFERENCES `fee_student_assignments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsc_concession` FOREIGN KEY (`concession_type_id`) REFERENCES `fee_concession_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fsc_approver` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 12: fee_invoices
-- Purpose: Generated invoices for students (installment based)
-- [ENHANCE] Added tax_amount column
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_invoices` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `invoice_no` VARCHAR(50) NOT NULL UNIQUE,
    `student_assignment_id` INT UNSIGNED NOT NULL,
    `installment_id` INT UNSIGNED NULL COMMENT 'NULL for one-time payments',
    `invoice_date` DATE NOT NULL,
    `due_date` DATE NOT NULL,
    `base_amount` DECIMAL(12,2) NOT NULL,
    `concession_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `fine_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_amount` DECIMAL(12,2) NOT NULL,
    `paid_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `balance_amount` DECIMAL(12,2) GENERATED ALWAYS AS (`total_amount` - `paid_amount`) STORED,
    `status` ENUM('Draft', 'Published', 'Partially Paid', 'Paid', 'Overdue', 'Cancelled') NOT NULL DEFAULT 'Draft',
    `invoice_pdf_path` VARCHAR(255) NULL,
    `generated_by` INT UNSIGNED NOT NULL,
    `cancelled_by` INT UNSIGNED NULL,
    `cancellation_reason` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_invoice_status` (`status`),
    INDEX `idx_invoice_due_date` (`due_date`),
    INDEX `idx_invoice_student` (`student_assignment_id`),
    CONSTRAINT `fk_finv_assignment` FOREIGN KEY (`student_assignment_id`) REFERENCES `fee_student_assignments` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_finv_installment` FOREIGN KEY (`installment_id`) REFERENCES `fee_installments` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_finv_generator` FOREIGN KEY (`generated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 13: fee_transactions
-- Purpose: Master record of each payment transaction
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_no` VARCHAR(50) NOT NULL UNIQUE,
    `student_id` INT UNSIGNED NOT NULL,
    `invoice_id` INT UNSIGNED NOT NULL,
    `guardian_id` INT UNSIGNED NULL COMMENT 'Who paid the fee',
    `payment_date` DATETIME NOT NULL,
    `payment_mode` ENUM('Cash', 'Cheque', 'DD', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Wallet') NOT NULL,
    `payment_reference` VARCHAR(100) NULL COMMENT 'Cheque/DD/Transaction ID',
    `bank_name` VARCHAR(100) NULL,
    `cheque_date` DATE NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `fine_adjusted` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `concession_adjusted` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `status` ENUM('Success', 'Pending', 'Failed', 'Refunded') NOT NULL DEFAULT 'Pending',
    `collected_by` INT UNSIGNED NOT NULL,  -- FK to sys_users ('Cashier/User ID')
    `remarks` TEXT NULL,
    `receipt_generated` TINYINT(1) NOT NULL DEFAULT 0,
    `receipt_id` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_transaction_student` (`student_id`),
    INDEX `idx_transaction_date` (`payment_date`),
    INDEX `idx_transaction_status` (`status`),
    INDEX `idx_transaction_mode` (`payment_mode`),
    CONSTRAINT `fk_ft_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ft_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `fee_invoices` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ft_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ft_collector` FOREIGN KEY (`collected_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 14: fee_transaction_details
-- Purpose: Split of transaction across fee heads
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_transaction_details` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NOT NULL,
    `head_id` INT UNSIGNED NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `concession_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_trans_detail` (`transaction_id`, `head_id`),
    CONSTRAINT `fk_ftd_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ftd_head` FOREIGN KEY (`head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 15: fee_receipts
-- Purpose: Official receipts generated after payment
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_receipts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `receipt_no` VARCHAR(50) NOT NULL UNIQUE,
    `transaction_id` INT UNSIGNED NOT NULL UNIQUE,
    `receipt_date` DATETIME NOT NULL,
    `receipt_pdf_path` VARCHAR(255) NULL,
    `receipt_format` ENUM('Standard', 'Detailed', 'Tax Invoice') NOT NULL DEFAULT 'Standard',
    `sent_to_parent` TINYINT(1) NOT NULL DEFAULT 0,
    `sent_via` ENUM('Email', 'SMS', 'WhatsApp', 'Print') NULL,
    `sent_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_receipt_date` (`receipt_date`),
    CONSTRAINT `fk_fr_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 16: fee_fine_transactions
-- Purpose: Tracks fines applied to students
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_fine_transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `invoice_id` INT UNSIGNED NOT NULL,
    `fine_rule_id` INT UNSIGNED NOT NULL,
    `fine_date` DATE NOT NULL,
    `days_late` INT NOT NULL,
    `fine_amount` DECIMAL(10,2) NOT NULL,
    `waived` TINYINT(1) NOT NULL DEFAULT 0,
    `waived_amount` DECIMAL(10,2) NULL COMMENT 'Partial waiver amount (NULL = full waiver if waived=1)',
    `waived_by` INT UNSIGNED NULL,
    `waiver_reason` TEXT NULL,
    `waived_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_fine_student` (`student_id`),
    INDEX `idx_fine_date` (`fine_date`),
    INDEX `idx_fine_waived` (`waived`),
    CONSTRAINT `fk_fft_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fft_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `fee_invoices` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fft_rule` FOREIGN KEY (`fine_rule_id`) REFERENCES `fee_fine_rules` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fft_waiver` FOREIGN KEY (`waived_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 17: fee_payment_gateway_logs
-- Purpose: Logs all online payment gateway transactions
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_payment_gateway_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NULL,
    `gateway_name` ENUM('Razorpay', 'Paytm', 'CCAvenue', 'BillDesk', 'Other') NOT NULL,
    `gateway_transaction_id` VARCHAR(100) NULL,
    `order_id` VARCHAR(100) NULL,
    `payment_id` VARCHAR(100) NULL,
    `request_payload` JSON NULL,
    `response_payload` JSON NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `status` VARCHAR(50) NOT NULL,
    `error_message` TEXT NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_gateway_trans` (`gateway_transaction_id`),
    INDEX `idx_gateway_order` (`order_id`),
    INDEX `idx_gateway_status` (`status`),
    CONSTRAINT `fk_fpgl_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 18: fee_scholarships
-- Purpose: Scholarship/fund definitions
-- [ENHANCE] Renamed scholarship_code->code, scholarship_name->name
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_scholarships` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `fund_source` VARCHAR(100) NOT NULL COMMENT 'Government/Trust/Corporate',
    `sponsor_name` VARCHAR(100) NULL,
    `total_fund_amount` DECIMAL(15,2) NULL,
    `available_fund` DECIMAL(15,2) NULL,
    `eligibility_criteria` JSON NOT NULL COMMENT 'Academic/Financial/Category criteria',
    `application_start_date` DATE NULL,
    `application_end_date` DATE NULL,
    `max_amount_per_student` DECIMAL(10,2) NULL,
    `requires_renewal` TINYINT(1) NOT NULL DEFAULT 0,
    `renewal_criteria` JSON NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_scholarship_active` (`is_active`),
    INDEX `idx_scholarship_dates` (`application_start_date`, `application_end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 19: fee_scholarship_applications
-- Purpose: Student applications for scholarships
-- [ENHANCE] Added academic_session_id; UNIQUE changed to (scholarship_id, student_id, academic_session_id)
-- [ENHANCE] Added fk_fschapp_session
-- [ENHANCE] Renamed FK from fk_fsa_student to fk_fschapp_scholarship & fk_fsa_student to fk_fschapp_student
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_scholarship_applications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scholarship_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL COMMENT 'FK to sch_org_academic_sessions_jnt',
    `application_date` DATE NOT NULL,
    `application_data` JSON NOT NULL COMMENT 'Student responses to criteria',
    `documents_submitted` JSON NULL,
    `current_stage` INT NOT NULL DEFAULT 1,
    `status` ENUM('Draft', 'Submitted', 'Under Review', 'Approved', 'Rejected', 'Waitlisted') NOT NULL DEFAULT 'Draft',
    `review_committee` JSON NULL COMMENT 'Committee members IDs',
    `approved_amount` DECIMAL(10,2) NULL,
    `disbursed` TINYINT(1) NOT NULL DEFAULT 0,
    `disbursed_date` DATE NULL,
    `remarks` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE INDEX `uq_scholarship_student_session` (`scholarship_id`, `student_id`, `academic_session_id`),
    INDEX `idx_sch_app_status` (`status`),
    CONSTRAINT `fk_fschapp_scholarship` FOREIGN KEY (`scholarship_id`) REFERENCES `fee_scholarships` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fschapp_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fschapp_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 20: fee_scholarship_approval_history
-- Purpose: Tracks approval workflow for scholarships
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_scholarship_approval_history` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `application_id` INT UNSIGNED NOT NULL,
    `stage` INT NOT NULL,
    `action_by` INT UNSIGNED NOT NULL,
    `action` ENUM('Submit', 'Approve', 'Reject', 'Request Info', 'Waitlist') NOT NULL,
    `comments` TEXT NULL,
    `action_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_fsah_application` FOREIGN KEY (`application_id`) REFERENCES `fee_scholarship_applications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_fsah_action_by` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 21: fee_name_removal_log
-- Purpose: Logs when student names are removed due to non-payment
-- [BUG-FIX] academic_session_id changed from INT to SMALLINT UNSIGNED
-- [ENHANCE] Added re_admission_fee_head_id, removed_by, re_admitted_by
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_name_removal_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `removal_date` DATE NOT NULL,
    `removal_reason` TEXT NOT NULL,
    `total_due_at_removal` DECIMAL(12,2) NOT NULL,
    `days_overdue` INT NOT NULL,
    `triggered_by_rule_id` INT UNSIGNED NULL,
    `removed_by` INT UNSIGNED NULL COMMENT 'FK to sys_users - who processed the removal',
    `re_admission_date` DATE NULL,
    `re_admission_fee_paid` DECIMAL(12,2) NULL,
    `re_admission_fee_head_id` INT UNSIGNED NULL COMMENT 'FK to fee_head_master for re-admission fee',
    `re_admission_transaction_id` INT UNSIGNED NULL,
    `re_admitted_by` INT UNSIGNED NULL COMMENT 'FK to sys_users - who processed re-admission',
    `re_activated_date` DATE NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_removal_student` (`student_id`),
    INDEX `idx_removal_date` (`removal_date`),
    CONSTRAINT `fk_frl_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_frl_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_frl_rule` FOREIGN KEY (`triggered_by_rule_id`) REFERENCES `fee_fine_rules` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_frl_removed_by` FOREIGN KEY (`removed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_frl_readmission_head` FOREIGN KEY (`re_admission_fee_head_id`) REFERENCES `fee_head_master` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_frl_readmitted_by` FOREIGN KEY (`re_admitted_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ========================================================================================================
-- NEW TABLES (v3)
-- ========================================================================================================


-- --------------------------------------------------------------------------------------------------------
-- Table 22: fee_refunds [NEW in v3]
-- Purpose: Tracks refund details when payments are reversed or students withdraw
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_refunds` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `refund_no` VARCHAR(50) NOT NULL UNIQUE,
    `original_transaction_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `refund_date` DATE NOT NULL,
    `refund_amount` DECIMAL(12,2) NOT NULL,
    `refund_mode` ENUM('Cash', 'Cheque', 'Bank Transfer', 'Original Mode') NOT NULL,
    `refund_reference` VARCHAR(100) NULL COMMENT 'Cheque/NEFT reference for refund',
    `refund_reason` TEXT NOT NULL,
    `approved_by` INT UNSIGNED NULL COMMENT 'FK to sys_users',
    `approved_at` TIMESTAMP NULL,
    `status` ENUM('Pending', 'Approved', 'Processed', 'Rejected') NOT NULL DEFAULT 'Pending',
    `rejection_reason` TEXT NULL,
    `processed_by` INT UNSIGNED NULL COMMENT 'FK to sys_users',
    `processed_at` TIMESTAMP NULL,
    `created_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_refund_student` (`student_id`),
    INDEX `idx_refund_status` (`status`),
    INDEX `idx_refund_date` (`refund_date`),
    CONSTRAINT `fk_fref_transaction` FOREIGN KEY (`original_transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fref_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fref_approver` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fref_processor` FOREIGN KEY (`processed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 23: fee_cheque_clearance [NEW in v3]
-- Purpose: Tracks cheque/DD lifecycle (deposit -> clearance/bounce)
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_payment_reconciliation` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT UNSIGNED NOT NULL UNIQUE,
    `cheque_no` VARCHAR(50) NOT NULL,
    `bank_name` VARCHAR(100) NOT NULL,  -- reconciliation
    `cheque_date` DATE NOT NULL,
    `deposit_date` DATE NULL,
    `clearance_date` DATE NULL,
    `bounce_date` DATE NULL,
    `bounce_reason` VARCHAR(255) NULL,
    `bounce_charge` DECIMAL(10,2) NULL,
    `resubmit_date` DATE NULL,
    `status` ENUM('Pending Deposit', 'Deposited', 'Cleared', 'Bounced', 'Resubmitted') NOT NULL DEFAULT 'Pending Deposit',
    `remarks` TEXT NULL,
    `updated_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_cheque_status` (`status`),
    INDEX `idx_cheque_date` (`cheque_date`),
    CONSTRAINT `fk_fcc_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `fee_transactions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- Table 24: fee_defaulter_history [NEW in v3]
-- Purpose: Per-student-per-session summary for defaulter pattern analysis and AI prediction
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fee_defaulter_history` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `total_fine_count` INT NOT NULL DEFAULT 0,
    `total_fine_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_waived_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `max_days_late` INT NOT NULL DEFAULT 0,
    `avg_days_late` DECIMAL(5,1) NULL,
    `missed_installments` INT NOT NULL DEFAULT 0,
    `name_removed` TINYINT(1) NOT NULL DEFAULT 0,
    `re_admitted` TINYINT(1) NOT NULL DEFAULT 0,
    `defaulter_score` DECIMAL(5,2) NULL COMMENT 'Computed risk score (0-100) for AI analytics',
    `last_computed_at` TIMESTAMP NULL COMMENT 'When the summary was last recalculated',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX `uq_defaulter_student_session` (`student_id`, `academic_session_id`),
    INDEX `idx_defaulter_score` (`defaulter_score`),
    CONSTRAINT `fk_fdh_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fdh_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ========================================================================================================
-- Sample Seed Data for sys_dropdown_table
-- Key format: table_name.column_name (as per sys_dropdown_table convention)
-- ========================================================================================================

-- Fee Head Types (ordinals 1-10, used by fee_head_master.head_type_id)
INSERT INTO `sys_dropdown_table` (`ordinal`, `key`, `value`, `type`, `is_active`) VALUES
(1,  'fee_head_master.head_type_id', 'Tuition Fee',     'String', 1),
(2,  'fee_head_master.head_type_id', 'Transport Fee',   'String', 1),
(3,  'fee_head_master.head_type_id', 'Hostel Fee',      'String', 1),
(4,  'fee_head_master.head_type_id', 'Library Fee',     'String', 1),
(5,  'fee_head_master.head_type_id', 'Sports Fee',      'String', 1),
(6,  'fee_head_master.head_type_id', 'Examination Fee', 'String', 1),
(7,  'fee_head_master.head_type_id', 'Laboratory Fee',  'String', 1),
(8,  'fee_head_master.head_type_id', 'Activity Fee',    'String', 1),
(9,  'fee_head_master.head_type_id', 'Development Fee', 'String', 1),
(10, 'fee_head_master.head_type_id', 'Other Fee',       'String', 1);

-- Concession Categories (ordinals 1-7, used by fee_concession_types.concession_category_id)
INSERT INTO `sys_dropdown_table` (`ordinal`, `key`, `value`, `type`, `is_active`) VALUES
(1, 'fee_concession_types.concession_category_id', 'Sibling Concession',    'String', 1),
(2, 'fee_concession_types.concession_category_id', 'Merit Scholarship',     'String', 1),
(3, 'fee_concession_types.concession_category_id', 'Staff Ward Concession', 'String', 1),
(4, 'fee_concession_types.concession_category_id', 'Financial Aid',         'String', 1),
(5, 'fee_concession_types.concession_category_id', 'Sports Quota',          'String', 1),
(6, 'fee_concession_types.concession_category_id', 'Alumni Concession',     'String', 1),
(7, 'fee_concession_types.concession_category_id', 'Other',                 'String', 1);

-- NOTE: The following seed data uses placeholder IDs for head_type_id and concession_category_id.
-- In production, you must first INSERT into sys_dropdown_table, capture the auto-generated IDs,
-- and then use those IDs in the fee table INSERTs.
-- Below, we assume sys_dropdown_table IDs for fee_head_type start sequentially.

-- Sample Fee Heads
-- IMPORTANT: Adjust head_type_id values to match actual sys_dropdown_table IDs in your environment
INSERT INTO `fee_head_master` (`code`, `name`, `head_type_id`, `frequency`, `is_refundable`, `tax_applicable`, `tax_percentage`, `display_order`, `is_active`) VALUES
('TUIT', 'Tuition Fee',      1, 'Monthly',     0, 1, 18.00, 1, 1),
('TRAN', 'Transport Fee',    2, 'Monthly',     0, 1, 18.00, 2, 1),
('HOST', 'Hostel Fee',       3, 'Monthly',     0, 1, 18.00, 3, 1),
('LIBR', 'Library Fee',      4, 'Yearly',      0, 0,  0.00, 4, 1),
('SPRT', 'Sports Fee',       5, 'Yearly',      0, 0,  0.00, 5, 1),
('EXAM', 'Examination Fee',  6, 'Half-Yearly', 0, 0,  0.00, 6, 1),
('LAB',  'Science Lab Fee',  7, 'Yearly',      0, 0,  0.00, 7, 1),
('DEVL', 'Development Fund', 9, 'One-time',    0, 0,  0.00, 8, 1);

-- Sample Fee Groups
INSERT INTO `fee_group_master` (`code`, `name`, `description`, `is_mandatory`, `display_order`, `is_active`) VALUES
('ACADEMIC',  'Academic Package',  'Tuition + Library + Exam + Lab', 1, 1, 1),
('TRANSPORT', 'Transport Package', 'Transport Fee (Optional)',       0, 2, 1),
('HOSTEL',    'Hostel Package',    'Hostel + Mess Charges',          0, 3, 1),
('ACTIVITY',  'Activity Package',  'Sports + Cultural Activities',   0, 4, 1);

-- Map Heads to Groups
INSERT INTO `fee_group_heads_jnt` (`group_id`, `head_id`, `is_optional`, `display_order`) VALUES
(1, 1, 0, 1),  -- Academic -> Tuition (Mandatory)
(1, 4, 0, 2),  -- Academic -> Library (Mandatory)
(1, 6, 0, 3),  -- Academic -> Exam (Mandatory)
(1, 7, 0, 4),  -- Academic -> Lab (Mandatory)
(2, 2, 0, 1),  -- Transport -> Transport (Mandatory in group)
(3, 3, 0, 1),  -- Hostel -> Hostel (Mandatory in group)
(4, 5, 1, 1);  -- Activity -> Sports (Optional)

-- Sample Fine Rules (Tiered as per requirement, using PerDay mode)
INSERT INTO `fee_fine_rules` (`rule_name`, `applicable_on`, `applicable_id`, `fine_type`, `fine_value`, `fine_calculation_mode`, `max_fine_amount`, `grace_period_days`, `applicable_from_day`, `applicable_to_day`, `action_on_expiry`, `is_active`) VALUES
('Late Fee Tier 1', 'Installment', 1, 'Fixed',              25.00, 'PerDay',      250.00, 0,  1, 10, NULL,             1),
('Late Fee Tier 2', 'Installment', 1, 'Fixed',              50.00, 'PerDay',     1000.00, 0, 11, 30, NULL,             1),
('Late Fee Tier 3', 'Installment', 1, 'Fixed',             100.00, 'PerDay',     3000.00, 0, 31, 60, 'Mark Defaulter', 1),
('Name Removal',    'Installment', 1, 'Percentage+Capped',   0.00, 'FlatPerTier',   0.00, 0, 61, 61, 'Remove Name',    1);

-- Sample Concession Types
-- IMPORTANT: Adjust concession_category_id values to match actual sys_dropdown_table IDs
INSERT INTO `fee_concession_types` (`code`, `name`, `concession_category_id`, `discount_type`, `discount_value`, `applicable_on`, `requires_approval`, `approval_level_role_id`, `is_active`) VALUES
('SIB10',   'Sibling Concession',    1, 'Percentage',   10.00,   'Total Fee', 1, NULL, 1),
('MERIT25', 'Merit Scholarship 25%', 2, 'Percentage',   25.00,   'Total Fee', 1, NULL, 1),
('STAFF50', 'Staff Ward 50%',        3, 'Percentage',   50.00,   'Total Fee', 1, NULL, 1),
('FIN_AID', 'Financial Aid Fixed',   4, 'Fixed Amount', 5000.00, 'Total Fee', 1, NULL, 1);


-- ========================================================================================================
-- End of Fee Module DDL v3.0
-- ========================================================================================================
