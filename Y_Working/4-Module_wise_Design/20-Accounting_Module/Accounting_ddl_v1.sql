-- =====================================================
-- MASTER DDL SCRIPT: SCHOOL ERP - ACCOUNTING & FEE MODULE
-- Database: MySQL 8.x
-- Engine: InnoDB
-- Character Set: utf8mb4
-- =====================================================

-- =====================================================
-- PART 1: ACCOUNTING CORE STRUCTURES
-- =====================================================

-- 1.1 Account Groups (Hierarchical Chart of Accounts)
CREATE TABLE `account_groups` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `code` varchar(20) NOT NULL,
    `parent_id` bigint UNSIGNED DEFAULT NULL,
    `group_type` enum('Assets','Liabilities','Income','Expense') NOT NULL,
    `nature` enum('Debit','Credit') NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `account_groups_code_unique` (`code`),
    KEY `account_groups_parent_id_foreign` (`parent_id`),
    CONSTRAINT `account_groups_parent_id_foreign` 
        FOREIGN KEY (`parent_id`) REFERENCES `account_groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.2 Ledgers (Individual Accounts)
CREATE TABLE `ledgers` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(150) NOT NULL,
    `code` varchar(20) NOT NULL,
    `account_group_id` bigint UNSIGNED NOT NULL,
    `opening_balance` decimal(15,2) NOT NULL DEFAULT '0.00',
    `balance_type` enum('Debit','Credit') NOT NULL,
    `as_of_date` date NOT NULL,
    `allow_reconciliation` tinyint(1) NOT NULL DEFAULT '0',
    `has_gst` tinyint(1) NOT NULL DEFAULT '0',
    `gst_number` varchar(50) DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ledgers_code_unique` (`code`),
    KEY `ledgers_account_group_id_foreign` (`account_group_id`),
    CONSTRAINT `ledgers_account_group_id_foreign` 
        FOREIGN KEY (`account_group_id`) REFERENCES `account_groups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.3 Ledger Mappings (Links to other modules)
CREATE TABLE `ledger_mappings` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id` bigint UNSIGNED NOT NULL,
    `source_module` enum('Fees','Library','Transport','HR','Vendor') NOT NULL,
    `source_id` bigint UNSIGNED NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `ledger_mappings_ledger_source_unique` (`ledger_id`, `source_module`, `source_id`),
    KEY `ledger_mappings_source_index` (`source_module`, `source_id`),
    CONSTRAINT `ledger_mappings_ledger_id_foreign` 
        FOREIGN KEY (`ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.4 Fiscal Years
CREATE TABLE `fiscal_years` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `start_date` date NOT NULL,
    `end_date` date NOT NULL,
    `is_closed` tinyint(1) NOT NULL DEFAULT '0',
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fiscal_years_name_unique` (`name`),
    KEY `fiscal_years_dates_index` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.5 Journal Entries (Master)
CREATE TABLE `journal_entries` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `entry_number` varchar(50) NOT NULL,
    `entry_date` date NOT NULL,
    `fiscal_year_id` bigint UNSIGNED NOT NULL,
    `reference` varchar(100) DEFAULT NULL,
    `entry_type` enum('Manual','Sales','Purchase','Receipt','Payment','Contra','Journal') NOT NULL,
    `narration` text,
    `total_debit` decimal(15,2) NOT NULL DEFAULT '0.00',
    `total_credit` decimal(15,2) NOT NULL DEFAULT '0.00',
    `approval_status` enum('Draft','Pending','Approved','Rejected') NOT NULL DEFAULT 'Draft',
    `approved_by` bigint UNSIGNED DEFAULT NULL,
    `approved_at` timestamp NULL DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `journal_entries_entry_number_unique` (`entry_number`),
    KEY `journal_entries_fiscal_year_id_foreign` (`fiscal_year_id`),
    KEY `journal_entries_approval_status_index` (`approval_status`),
    KEY `journal_entries_entry_date_index` (`entry_date`),
    CONSTRAINT `journal_entries_fiscal_year_id_foreign` 
        FOREIGN KEY (`fiscal_year_id`) REFERENCES `fiscal_years` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.6 Journal Entry Lines (Details)
CREATE TABLE `journal_entry_lines` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `journal_entry_id` bigint UNSIGNED NOT NULL,
    `ledger_id` bigint UNSIGNED NOT NULL,
    `debit` decimal(15,2) NOT NULL DEFAULT '0.00',
    `credit` decimal(15,2) NOT NULL DEFAULT '0.00',
    `narration` text,
    `reconciliation_date` date DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `journal_entry_lines_journal_entry_id_foreign` (`journal_entry_id`),
    KEY `journal_entry_lines_ledger_id_foreign` (`ledger_id`),
    CONSTRAINT `journal_entry_lines_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`) ON DELETE CASCADE,
    CONSTRAINT `journal_entry_lines_ledger_id_foreign` 
        FOREIGN KEY (`ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.7 Recurring Journal Templates
CREATE TABLE `recurring_journal_templates` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(150) NOT NULL,
    `start_date` date NOT NULL,
    `end_date` date DEFAULT NULL,
    `frequency` enum('Daily','Weekly','Monthly','Quarterly','Yearly') NOT NULL,
    `day_of_month` tinyint DEFAULT NULL,
    `narration` text,
    `total_debit` decimal(15,2) NOT NULL,
    `total_credit` decimal(15,2) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.8 Recurring Journal Template Lines
CREATE TABLE `recurring_journal_template_lines` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `recurring_journal_template_id` bigint UNSIGNED NOT NULL,
    `ledger_id` bigint UNSIGNED NOT NULL,
    `debit` decimal(15,2) NOT NULL DEFAULT '0.00',
    `credit` decimal(15,2) NOT NULL DEFAULT '0.00',
    `narration` text,
    PRIMARY KEY (`id`),
    KEY `recurring_template_lines_template_id_foreign` (`recurring_journal_template_id`),
    KEY `recurring_template_lines_ledger_id_foreign` (`ledger_id`),
    CONSTRAINT `recurring_template_lines_template_id_foreign` 
        FOREIGN KEY (`recurring_journal_template_id`) REFERENCES `recurring_journal_templates` (`id`) ON DELETE CASCADE,
    CONSTRAINT `recurring_template_lines_ledger_id_foreign` 
        FOREIGN KEY (`ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 2: FEE MANAGEMENT MODULE
-- =====================================================

-- 2.1 Fee Heads (Master)
CREATE TABLE `fee_heads` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `code` varchar(20) NOT NULL,
    `description` text,
    `is_refundable` tinyint(1) NOT NULL DEFAULT '0',
    `is_optional` tinyint(1) NOT NULL DEFAULT '0',
    `income_ledger_id` bigint UNSIGNED NOT NULL,
    `tax_rate_id` bigint UNSIGNED DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fee_heads_code_unique` (`code`),
    KEY `fee_heads_income_ledger_id_foreign` (`income_ledger_id`),
    CONSTRAINT `fee_heads_income_ledger_id_foreign` 
        FOREIGN KEY (`income_ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.2 Fee Structures (Templates)
CREATE TABLE `fee_structures` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(150) NOT NULL,
    `code` varchar(20) NOT NULL,
    `academic_session_id` bigint UNSIGNED NOT NULL,
    `class_id` bigint UNSIGNED NOT NULL,
    `student_category_id` bigint UNSIGNED DEFAULT NULL,
    `valid_from` date NOT NULL,
    `valid_to` date DEFAULT NULL,
    `total_amount` decimal(15,2) NOT NULL DEFAULT '0.00',
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fee_structures_code_unique` (`code`),
    KEY `fee_structures_academic_session_id_foreign` (`academic_session_id`),
    KEY `fee_structures_class_id_foreign` (`class_id`),
    KEY `fee_structures_category_id_foreign` (`student_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.3 Fee Structure Lines
CREATE TABLE `fee_structure_lines` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `fee_structure_id` bigint UNSIGNED NOT NULL,
    `fee_head_id` bigint UNSIGNED NOT NULL,
    `amount` decimal(15,2) NOT NULL,
    `due_date` date NOT NULL,
    `is_optional` tinyint(1) NOT NULL DEFAULT '0',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fee_structure_lines_unique` (`fee_structure_id`, `fee_head_id`),
    KEY `fee_structure_lines_fee_head_id_foreign` (`fee_head_id`),
    CONSTRAINT `fee_structure_lines_fee_structure_id_foreign` 
        FOREIGN KEY (`fee_structure_id`) REFERENCES `fee_structures` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fee_structure_lines_fee_head_id_foreign` 
        FOREIGN KEY (`fee_head_id`) REFERENCES `fee_heads` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.4 Discount/Scholarship Types
CREATE TABLE `discount_types` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `code` varchar(20) NOT NULL,
    `type` enum('Fixed','Percentage') NOT NULL,
    `value` decimal(10,2) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `discount_types_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.5 Student Fee Concessions
CREATE TABLE `student_fee_concessions` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `student_id` bigint UNSIGNED NOT NULL,
    `fee_structure_line_id` bigint UNSIGNED NOT NULL,
    `discount_type_id` bigint UNSIGNED NOT NULL,
    `amount` decimal(15,2) NOT NULL,
    `reason` text,
    `approved_by` bigint UNSIGNED NOT NULL,
    `approved_at` timestamp NOT NULL,
    `valid_from` date NOT NULL,
    `valid_to` date DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `student_concessions_student_id_foreign` (`student_id`),
    KEY `student_concessions_line_id_foreign` (`fee_structure_line_id`),
    KEY `student_concessions_discount_id_foreign` (`discount_type_id`),
    CONSTRAINT `student_concessions_discount_id_foreign` 
        FOREIGN KEY (`discount_type_id`) REFERENCES `discount_types` (`id`),
    CONSTRAINT `student_concessions_line_id_foreign` 
        FOREIGN KEY (`fee_structure_line_id`) REFERENCES `fee_structure_lines` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 3: INVOICES & TRANSACTIONS
-- =====================================================

-- 3.1 Tax Rates
CREATE TABLE `tax_rates` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `rate` decimal(5,2) NOT NULL,
    `type` enum('CGST','SGST','IGST','Cess') NOT NULL,
    `is_interstate` tinyint(1) NOT NULL DEFAULT '0',
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2 Sales Invoices (Student Fees)
CREATE TABLE `sales_invoices` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_number` varchar(50) NOT NULL,
    `student_id` bigint UNSIGNED NOT NULL,
    `academic_session_id` bigint UNSIGNED NOT NULL,
    `invoice_date` date NOT NULL,
    `due_date` date NOT NULL,
    `total_amount` decimal(15,2) NOT NULL,
    `discount_amount` decimal(15,2) NOT NULL DEFAULT '0.00',
    `taxable_amount` decimal(15,2) NOT NULL DEFAULT '0.00',
    `total_tax` decimal(15,2) NOT NULL DEFAULT '0.00',
    `net_payable` decimal(15,2) NOT NULL,
    `status` enum('Draft','Posted','Partially Paid','Paid','Cancelled') NOT NULL,
    `journal_entry_id` bigint UNSIGNED DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `sales_invoices_invoice_number_unique` (`invoice_number`),
    KEY `sales_invoices_student_id_foreign` (`student_id`),
    KEY `sales_invoices_academic_session_id_foreign` (`academic_session_id`),
    KEY `sales_invoices_journal_entry_id_foreign` (`journal_entry_id`),
    KEY `sales_invoices_status_index` (`status`),
    CONSTRAINT `sales_invoices_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3 Purchase Invoices (Vendor Bills)
CREATE TABLE `purchase_invoices` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_number` varchar(50) NOT NULL,
    `vendor_id` bigint UNSIGNED NOT NULL,
    `invoice_date` date NOT NULL,
    `due_date` date NOT NULL,
    `total_amount` decimal(15,2) NOT NULL,
    `taxable_amount` decimal(15,2) NOT NULL DEFAULT '0.00',
    `total_tax` decimal(15,2) NOT NULL DEFAULT '0.00',
    `net_payable` decimal(15,2) NOT NULL,
    `status` enum('Draft','Posted','Partially Paid','Paid','Cancelled') NOT NULL,
    `journal_entry_id` bigint UNSIGNED DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_invoices_invoice_number_unique` (`invoice_number`),
    KEY `purchase_invoices_vendor_id_foreign` (`vendor_id`),
    KEY `purchase_invoices_journal_entry_id_foreign` (`journal_entry_id`),
    CONSTRAINT `purchase_invoices_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4 Invoice Tax Lines
CREATE TABLE `invoice_tax_lines` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `source_invoice_type` enum('Sales','Purchase') NOT NULL,
    `source_invoice_id` bigint UNSIGNED NOT NULL,
    `tax_rate_id` bigint UNSIGNED NOT NULL,
    `tax_amount` decimal(15,2) NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `invoice_tax_lines_source_index` (`source_invoice_type`, `source_invoice_id`),
    KEY `invoice_tax_lines_tax_rate_id_foreign` (`tax_rate_id`),
    CONSTRAINT `invoice_tax_lines_tax_rate_id_foreign` 
        FOREIGN KEY (`tax_rate_id`) REFERENCES `tax_rates` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.5 Invoice Items/Lines
CREATE TABLE `invoice_lines` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `source_invoice_type` enum('Sales','Purchase') NOT NULL,
    `source_invoice_id` bigint UNSIGNED NOT NULL,
    `fee_head_id` bigint UNSIGNED DEFAULT NULL,
    `description` varchar(255) NOT NULL,
    `quantity` int NOT NULL DEFAULT '1',
    `unit_price` decimal(15,2) NOT NULL,
    `discount_percent` decimal(5,2) DEFAULT '0.00',
    `discount_amount` decimal(15,2) DEFAULT '0.00',
    `taxable_amount` decimal(15,2) NOT NULL,
    `total_amount` decimal(15,2) NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `invoice_lines_source_index` (`source_invoice_type`, `source_invoice_id`),
    KEY `invoice_lines_fee_head_id_foreign` (`fee_head_id`),
    CONSTRAINT `invoice_lines_fee_head_id_foreign` 
        FOREIGN KEY (`fee_head_id`) REFERENCES `fee_heads` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.6 Payment Transactions (Gateway Logs)
CREATE TABLE `payment_transactions` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `student_id` bigint UNSIGNED NOT NULL,
    `invoice_id` bigint UNSIGNED NOT NULL,
    `transaction_id` varchar(100) NOT NULL,
    `gateway` varchar(50) NOT NULL,
    `gateway_reference_id` varchar(100) DEFAULT NULL,
    `amount` decimal(15,2) NOT NULL,
    `payment_mode` enum('Online','Cash','Cheque','DD') NOT NULL,
    `status` enum('Initiated','Success','Failed','Refunded') NOT NULL,
    `request_payload` json DEFAULT NULL,
    `response_payload` json DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `payment_transactions_transaction_id_unique` (`transaction_id`),
    KEY `payment_transactions_student_id_foreign` (`student_id`),
    KEY `payment_transactions_invoice_id_foreign` (`invoice_id`),
    CONSTRAINT `payment_transactions_invoice_id_foreign` 
        FOREIGN KEY (`invoice_id`) REFERENCES `sales_invoices` (`id`),
    CONSTRAINT `payment_transactions_student_id_foreign` 
        FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.7 Receipts
CREATE TABLE `receipts` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `receipt_number` varchar(50) NOT NULL,
    `journal_entry_id` bigint UNSIGNED NOT NULL,
    `student_id` bigint UNSIGNED NOT NULL,
    `receipt_date` date NOT NULL,
    `amount` decimal(15,2) NOT NULL,
    `payment_mode` enum('Cash','Cheque','DD','Online') NOT NULL,
    `reference_number` varchar(50) DEFAULT NULL,
    `bank_name` varchar(100) DEFAULT NULL,
    `remarks` text,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `receipts_receipt_number_unique` (`receipt_number`),
    KEY `receipts_journal_entry_id_foreign` (`journal_entry_id`),
    KEY `receipts_student_id_foreign` (`student_id`),
    CONSTRAINT `receipts_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`),
    CONSTRAINT `receipts_student_id_foreign` 
        FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 4: BUDGETING & COST CENTERS
-- =====================================================

-- 4.1 Cost Centers
CREATE TABLE `cost_centers` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `code` varchar(20) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `cost_centers_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4.2 Budgets
CREATE TABLE `budgets` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `fiscal_year_id` bigint UNSIGNED NOT NULL,
    `cost_center_id` bigint UNSIGNED NOT NULL,
    `ledger_id` bigint UNSIGNED NOT NULL,
    `amount` decimal(15,2) NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `budgets_unique` (`fiscal_year_id`, `cost_center_id`, `ledger_id`),
    KEY `budgets_cost_center_id_foreign` (`cost_center_id`),
    KEY `budgets_ledger_id_foreign` (`ledger_id`),
    CONSTRAINT `budgets_cost_center_id_foreign` 
        FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`),
    CONSTRAINT `budgets_ledger_id_foreign` 
        FOREIGN KEY (`ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 5: EXPENSE CLAIM MANAGEMENT
-- =====================================================

-- 5.1 Expense Claims
CREATE TABLE `expense_claims` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `claim_number` varchar(50) NOT NULL,
    `employee_id` bigint UNSIGNED NOT NULL,
    `claim_date` date NOT NULL,
    `total_amount` decimal(15,2) NOT NULL,
    `status` enum('Draft','Submitted','Approved','Rejected','Paid') NOT NULL,
    `approved_by` bigint UNSIGNED DEFAULT NULL,
    `approved_at` timestamp NULL DEFAULT NULL,
    `journal_entry_id` bigint UNSIGNED DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `expense_claims_claim_number_unique` (`claim_number`),
    KEY `expense_claims_employee_id_foreign` (`employee_id`),
    KEY `expense_claims_journal_entry_id_foreign` (`journal_entry_id`),
    CONSTRAINT `expense_claims_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.2 Expense Claim Lines
CREATE TABLE `expense_claim_lines` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `expense_claim_id` bigint UNSIGNED NOT NULL,
    `expense_date` date NOT NULL,
    `ledger_id` bigint UNSIGNED NOT NULL,
    `description` varchar(255) NOT NULL,
    `amount` decimal(15,2) NOT NULL,
    `tax_amount` decimal(15,2) DEFAULT '0.00',
    `receipt_path` varchar(255) DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `expense_claim_lines_claim_id_foreign` (`expense_claim_id`),
    KEY `expense_claim_lines_ledger_id_foreign` (`ledger_id`),
    CONSTRAINT `expense_claim_lines_claim_id_foreign` 
        FOREIGN KEY (`expense_claim_id`) REFERENCES `expense_claims` (`id`) ON DELETE CASCADE,
    CONSTRAINT `expense_claim_lines_ledger_id_foreign` 
        FOREIGN KEY (`ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 6: BANK RECONCILIATION
-- =====================================================

-- 6.1 Bank Reconciliation Statements
CREATE TABLE `bank_reconciliations` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `ledger_id` bigint UNSIGNED NOT NULL,
    `statement_date` date NOT NULL,
    `closing_balance` decimal(15,2) NOT NULL,
    `statement_path` varchar(255) DEFAULT NULL,
    `status` enum('In Progress','Completed') NOT NULL DEFAULT 'In Progress',
    `created_by` bigint UNSIGNED NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `bank_reconciliations_ledger_id_foreign` (`ledger_id`),
    CONSTRAINT `bank_reconciliations_ledger_id_foreign` 
        FOREIGN KEY (`ledger_id`) REFERENCES `ledgers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6.2 Bank Transaction Matches
CREATE TABLE `reconciliation_matches` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `bank_reconciliation_id` bigint UNSIGNED NOT NULL,
    `journal_entry_line_id` bigint UNSIGNED NOT NULL,
    `matched_date` date NOT NULL,
    `matched_by` bigint UNSIGNED NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `reconciliation_matches_unique` (`bank_reconciliation_id`, `journal_entry_line_id`),
    KEY `reconciliation_matches_line_id_foreign` (`journal_entry_line_id`),
    CONSTRAINT `reconciliation_matches_bank_reconciliation_id_foreign` 
        FOREIGN KEY (`bank_reconciliation_id`) REFERENCES `bank_reconciliations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `reconciliation_matches_line_id_foreign` 
        FOREIGN KEY (`journal_entry_line_id`) REFERENCES `journal_entry_lines` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 7: FIXED ASSETS MANAGEMENT
-- =====================================================

-- 7.1 Asset Categories
CREATE TABLE `asset_categories` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `code` varchar(20) NOT NULL,
    `depreciation_method` enum('SLM','WDV') NOT NULL,
    `depreciation_rate` decimal(5,2) NOT NULL,
    `useful_life_years` int DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `asset_categories_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7.2 Fixed Assets
CREATE TABLE `fixed_assets` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(150) NOT NULL,
    `asset_code` varchar(50) NOT NULL,
    `asset_category_id` bigint UNSIGNED NOT NULL,
    `purchase_date` date NOT NULL,
    `purchase_cost` decimal(15,2) NOT NULL,
    `salvage_value` decimal(15,2) DEFAULT '0.00',
    `current_value` decimal(15,2) NOT NULL,
    `accumulated_depreciation` decimal(15,2) NOT NULL DEFAULT '0.00',
    `location` varchar(100) DEFAULT NULL,
    `vendor_id` bigint UNSIGNED DEFAULT NULL,
    `journal_entry_id` bigint UNSIGNED DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fixed_assets_asset_code_unique` (`asset_code`),
    KEY `fixed_assets_asset_category_id_foreign` (`asset_category_id`),
    KEY `fixed_assets_vendor_id_foreign` (`vendor_id`),
    KEY `fixed_assets_journal_entry_id_foreign` (`journal_entry_id`),
    CONSTRAINT `fixed_assets_asset_category_id_foreign` 
        FOREIGN KEY (`asset_category_id`) REFERENCES `asset_categories` (`id`),
    CONSTRAINT `fixed_assets_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7.3 Depreciation Entries
CREATE TABLE `depreciation_entries` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `fixed_asset_id` bigint UNSIGNED NOT NULL,
    `fiscal_year_id` bigint UNSIGNED NOT NULL,
    `depreciation_date` date NOT NULL,
    `depreciation_amount` decimal(15,2) NOT NULL,
    `journal_entry_id` bigint UNSIGNED DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `depreciation_entries_asset_id_foreign` (`fixed_asset_id`),
    KEY `depreciation_entries_fiscal_year_id_foreign` (`fiscal_year_id`),
    KEY `depreciation_entries_journal_entry_id_foreign` (`journal_entry_id`),
    CONSTRAINT `depreciation_entries_asset_id_foreign` 
        FOREIGN KEY (`fixed_asset_id`) REFERENCES `fixed_assets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `depreciation_entries_fiscal_year_id_foreign` 
        FOREIGN KEY (`fiscal_year_id`) REFERENCES `fiscal_years` (`id`),
    CONSTRAINT `depreciation_entries_journal_entry_id_foreign` 
        FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PART 8: DATA EXPORT (TALLY)
-- =====================================================

-- 8.1 Tally Export Logs
CREATE TABLE `tally_export_logs` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `export_type` enum('Ledgers','Journal_Vouchers','Inventory') NOT NULL,
    `export_date` datetime NOT NULL,
    `file_name` varchar(255) NOT NULL,
    `exported_by` bigint UNSIGNED NOT NULL,
    `start_date` date DEFAULT NULL,
    `end_date` date DEFAULT NULL,
    `status` enum('Success','Failed','Partial') NOT NULL,
    `error_log` text,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `tally_export_logs_exported_by_foreign` (`exported_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Additional indexes for better query performance
CREATE INDEX idx_journal_entries_composite ON journal_entries(entry_date, fiscal_year_id, approval_status);
CREATE INDEX idx_journal_lines_ledger_date ON journal_entry_lines(ledger_id, created_at);
CREATE INDEX idx_sales_invoices_student_status ON sales_invoices(student_id, status);
CREATE INDEX idx_sales_invoices_due_date ON sales_invoices(due_date) WHERE status IN ('Posted', 'Partially Paid');
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status, created_at);
CREATE INDEX idx_receipts_date ON receipts(receipt_date);

-- =====================================================
-- SAMPLE SEED DATA (Reference Only)
-- =====================================================

-- Sample Account Groups
INSERT INTO `account_groups` (`name`, `code`, `parent_id`, `group_type`, `nature`) VALUES
('Assets', 'A01', NULL, 'Assets', 'Debit'),
('Liabilities', 'L01', NULL, 'Liabilities', 'Credit'),
('Income', 'I01', NULL, 'Income', 'Credit'),
('Expenses', 'E01', NULL, 'Expense', 'Debit');

-- Assuming first 4 IDs are taken, insert children
INSERT INTO `account_groups` (`name`, `code`, `parent_id`, `group_type`, `nature`) VALUES
('Current Assets', 'A02', 1, 'Assets', 'Debit'),
('Fixed Assets', 'A03', 1, 'Assets', 'Debit'),
('Bank Accounts', 'A04', 5, 'Assets', 'Debit'),
('Cash in Hand', 'A05', 5, 'Assets', 'Debit'),
('Current Liabilities', 'L02', 2, 'Liabilities', 'Credit'),
('Direct Income', 'I02', 3, 'Income', 'Credit'),
('Indirect Income', 'I03', 3, 'Income', 'Credit'),
('Direct Expenses', 'E02', 4, 'Expense', 'Debit'),
('Indirect Expenses', 'E03', 4, 'Expense', 'Debit');

-- Sample Tax Rates
INSERT INTO `tax_rates` (`name`, `rate`, `type`, `is_interstate`) VALUES
('CGST 9%', 9.00, 'CGST', 0),
('SGST 9%', 9.00, 'SGST', 0),
('IGST 18%', 18.00, 'IGST', 1),
('CGST 2.5%', 2.50, 'CGST', 0),
('SGST 2.5%', 2.50, 'SGST', 0);

-- Sample Cost Centers
INSERT INTO `cost_centers` (`name`, `code`) VALUES
('Academics - Science', 'CC-SCI'),
('Academics - Arts', 'CC-ART'),
('Sports Department', 'CC-SPT'),
('Administration', 'CC-ADM'),
('IT Infrastructure', 'CC-IT');

-- Sample Fiscal Year
INSERT INTO `fiscal_years` (`name`, `start_date`, `end_date`, `is_closed`) VALUES
('2024-2025', '2024-04-01', '2025-03-31', 0),
('2023-2024', '2023-04-01', '2024-03-31', 1);

