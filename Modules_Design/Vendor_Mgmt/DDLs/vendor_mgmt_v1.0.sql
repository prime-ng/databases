-- =======================================================================
-- VENDOR_MANAGEMENT_MODULE v1.0 for MySQL 8.x
-- Database: tenant_db
-- Dependencies: sys_dropdown_table, sys_users, sys_media_table
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VENDOR MANAGEMENT
-- =======================================================================

CREATE TABLE IF NOT EXISTS `vnd_vendor` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_short_name` VARCHAR(50) NOT NULL,
    `vendor_name` VARCHAR(100) NOT NULL,
    `transport_vendor` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,  -- FK to sys_dropdown_table ('Yes','No'). Using this app will decide whether to use 
    `agreement_start_date` DATE NOT NULL,  -- Agreement start date
    `agreement_end_date` DATE NOT NULL,    -- Agreement end date
    `contact_no` VARCHAR(30) NOT NULL,     -- Contact number
    `contact_person` VARCHAR(100) NOT NULL,-- Contact person
    `email` VARCHAR(100) NOT NULL,         -- Email address
    `address` VARCHAR(512) NOT NULL,       -- Address
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vendor_name` (`vendor_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- conditions:
    -- 1. vendor_name must be unique.
    -- 2. If transport_vendor is TRUE then Application will use 'tpt_vendor_vehicle_agreement' table for Rate Details when create Invoice.
    -- 3. If transport_vendor is FALSE then Application will use 'tpt_vendor_vehicle_agreement' table for Rate Details when create Invoice.
    -- 3. agreement_start_date must be less than agreement_end_date.
    -- 4. Agreement file will be stored in sys_media_table.
    -- 5. contact_no must be valid phone number.
    -- 6. email must be valid email address.
    -- 7. address must be valid address.
    -- 8. is_active indicates if vendor is currently active.

CREATE TABLE IF NOT EXISTS `vnd_vendor_agreement` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` BIGINT UNSIGNED NOT NULL,  -- fk to vnd_vendor

    `agreement_type_id` BIGINT UNSIGNED NOT NULL,   -- fk to sys_dropdown_table ('SERVICE','PRODUCT')
    `agreement_ref_no` VARCHAR(50) DEFAULT NULL,    -- Reference number of the physical agreement
    `agreement_start_date` DATE NOT NULL,
    `agreement_end_date` DATE NOT NULL,
    `monthly_billing_date` DATE NOT NULL,  -- Billing date of every month
    `agreement_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (agreement will be uploaded in sys.media table)
-- -- (For Transport Agreement only) ----------------------------------------------------
    `agreement_for_transport` tinyint(1) unsigned not null default 0,  -- 0: Not for Transport, 1: For Transport (agreement will be uploaded in sys.media table)
    `vehicle_id` BIGINT UNSIGNED NOT NULL, -- fk to tpt_vehicle
    `transport_charge_type` ENUM('Fixed','Km_Basis','Hybrid') DEFAULT 'Fixed', -- 'Fixed', 'Km_Basis', 'Hybrid'
    `monthly_fixed_charge` DECIMAL(10, 2) DEFAULT 0.00, -- Applicable if charge_type is Fixed or Hybrid
    `rate_per_km` DECIMAL(10, 2) DEFAULT 0.00,          -- Applicable if charge_type is Km_Basis or Hybrid
    `min_km_guarantee` DECIMAL(10, 2) DEFAULT 0.00,     -- Minimum Km guaranteed per month (if applicable)
-- --------------------------------------------------------------------------------------------------------
-- Agreement for Monthly Charges based Services e.g. Schook Bus, Driver on contract, Doctor on contract, 
-- --------------------------------------------------------------------------------------------------------
    `service_charge_type` ENUM('Monthly','Qty Based','Hybrid') DEFAULT 'Monthly', -- 'Monthly', 'Qty Based', 'Hybrid'
    `fixed_monthly_charge` DECIMAL(10, 2) DEFAULT 0.00, -- Applicable if charge_type is Monthly or Hybrid
    `min_monthly_charge_guarantee` DECIMAL(10, 2) DEFAULT 0.00,     -- Minimum Service guaranteed per month (if applicable)
--  In case of 'service_chrge_type' is 'Hybrid' then 'service_monthly_fixed_charge' will be applicable from here and per service charges will be calculated from 'service_monthly_fixed_charge' + 'min_monthly_service_guarantee'
-- --------------------------------------------------------------------------------------
-- For Product rate will be Item wise Agreement
-- --------------------------------------------------------------------------------------
    `tax1_rate` DECIMAL(5, 2) DEFAULT 0.00,            -- Tax 1 rate. (if applicable)
    `tax2_rate` DECIMAL(5, 2) DEFAULT 0.00,            -- Tax 2 rate. (if applicable)
    `tax3_rate` DECIMAL(5, 2) DEFAULT 0.00,            -- Tax 3 rate. (if applicable)
    `tax4_rate` DECIMAL(5, 2) DEFAULT 0.00,            -- Tax 4 rate. (if applicable)
    `other_charges` DECIMAL(10, 2) DEFAULT 0.00,       -- Other charges. (if applicable)
    `credit_days` INT DEFAULT 0,                        -- Number of days to credit the payment
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_agreement_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `tpt_vendor`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_agreement_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. Defines the price agreement between School and Vendor for a specific vehicle.
    -- 2. Supports Fixed Monthly Charges, Per Km Charges, or a Hybrid model.

-- ------------------------------------------------------------------------------------------------------------------

-- This table will have rate detail per product Or per service
CREATE TABLE IF NOT EXISTS `vnd_vendor_price_detail` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_agreement_id` BIGINT UNSIGNED NOT NULL,  -- fk to vnd_vendor_agreement
    `vehicle_id` BIGINT UNSIGNED NULL, -- fk to tpt_vehicle
    `monthly_billing_date` DATE NOT NULL,  -- Billing date of every month
    `agreement_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (agreement will be uploaded in sys.media table)

    `agreement_type_id` BIGINT UNSIGNED NOT NULL,   -- fk to sys_dropdown_table ('SERVICE','VEHICLE','PRODUCT','SUPPORT','OTHERS')
    `agreement_ref_no` VARCHAR(50) DEFAULT NULL,    -- Reference number of the physical agreement
    `agreement_start_date` DATE NOT NULL,
    `agreement_end_date` DATE NOT NULL,
    `monthly_billing_date` DATE NOT NULL,  -- Billing date of every month
    `agreement_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (agreement will be uploaded in sys.media table)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- VENDOR BILLING (New in v2.0)
-- =======================================================================
CREATE TABLE IF NOT EXISTS `sch_vendor_monthly_bill` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` BIGINT UNSIGNED NOT NULL,  -- fk to tpt_vendor
    `vehicle_id` BIGINT UNSIGNED NOT NULL, -- fk to tpt_vehicle
    `agreement_id` BIGINT UNSIGNED NOT NULL,      -- FK to tpt_vendor_vehicle_agreement
    `billing_month_year` DATE NOT NULL,           -- The first day of the month being billed (e.g., '2025-12-01')
    `opening_odometer` DECIMAL(10, 2) DEFAULT 0.00, -- Opening odometer reading at the start of the billing month
    `closing_odometer` DECIMAL(10, 2) DEFAULT 0.00, -- Closing odometer reading at the end of the billing month
    `total_km_run` DECIMAL(10, 2) DEFAULT 0.00,   -- closing - opening
    `bill_generated_date` DATE NOT NULL,                  -- The date the bill was generated
    `fixed_charge_amount` DECIMAL(12, 2) DEFAULT 0.00,    -- Applicable if charge_type is Fixed or Hybrid
    `variable_charge_amount` DECIMAL(12, 2) DEFAULT 0.00, -- (total_km_run * rate_per_km)
    `other_charges` DECIMAL(10, 2) DEFAULT 0.00,          -- Penalties, bonuses, etc.
    `tax1_amount` DECIMAL(10, 2) DEFAULT 0.00,            -- Tax 1 amount. (if applicable)
    `tax2_amount` DECIMAL(10, 2) DEFAULT 0.00,            -- Tax 2 amount. (if applicable)
    `tax3_amount` DECIMAL(10, 2) DEFAULT 0.00,            -- Tax 3 amount. (if applicable)
    `tax4_amount` DECIMAL(10, 2) DEFAULT 0.00,            -- Tax 4 amount. (if applicable)
    `other_charges_amount` DECIMAL(10, 2) DEFAULT 0.00,   -- Other charges amount. (if applicable)
    `discount_amount` DECIMAL(10, 2) DEFAULT 0.00,        -- Discount amount. (if applicable)
    `penalty_amount` DECIMAL(10, 2) DEFAULT 0.00,         -- Penalty amount. (if applicable)
    `other_deductions_amount` DECIMAL(10, 2) DEFAULT 0.00, -- Other deductions amount. (if applicable)
    `total_bill_amount` DECIMAL(12, 2) NOT NULL,
    `total_paid_amount` DECIMAL(12, 2) DEFAULT 0.00,      -- Total amount paid by the vendor
    `total_outstanding_amount` DECIMAL(12, 2) DEFAULT 0.00, -- Total outstanding amount
    `vendor_invoice_no` VARCHAR(50) DEFAULT NULL,
    `due_date` DATE DEFAULT NULL,       -- This is Payment Due date (will be calcultaed by adding credit_days in monthly_billing_date)
    `remarks` VARCHAR(512) DEFAULT NULL,
    `status` BIGINT UNSIGNED NOT NULL DEFAULT 1,  -- FK to sys_dropdown_table e.g. Generated, Approved, Paid, Partial, Cancelled    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_bill_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `tpt_vendor`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_bill_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_bill_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `tpt_vendor_vehicle_agreement`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_bill_status` FOREIGN KEY (`status`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. Generated monthly based on vehicle usage and agreement terms.
    -- 2. total_km_run can be derived from tpt_vehicle_fuel_log or tpt_daily_vehicle_inspection_log if odometer is tracked there.

CREATE TABLE IF NOT EXISTS `vnd_vendor_bill_due_for_payment` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_bill_id` BIGINT UNSIGNED NOT NULL,           -- FK to tpt_vendor_monthly_bill_log
    `payment_date` DATE NOT NULL,
    `amount_paid` DECIMAL(12, 2) NOT NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'INR',
    `payment_mode` BIGINT UNSIGNED NOT NULL,      -- FK to sys_dropdown_table (Cheque, Bank Transfer, etc.)
    `transaction_reference` VARCHAR(100) DEFAULT NULL, -- Cheque No, Transaction ID
    `payment_status` VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',  -- use dropdown table ('INITIATED','SUCCESS','FAILED')
    `payment_reconciled` tinyint(1) NOT NULL DEFAULT '0',
    `paid_by` BIGINT UNSIGNED DEFAULT NULL,       -- FK to sys_users
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_payment_vendor_bill` FOREIGN KEY (`vendor_bill_id`) REFERENCES `tpt_vendor_monthly_bill`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_payment_paymentMode` FOREIGN KEY (`payment_mode`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_payment_paidBy` FOREIGN KEY (`paid_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- VENDOR PAYMENTS (New in v2.0)
-- =======================================================================
CREATE TABLE IF NOT EXISTS `tsch_vendor_bill_payment` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_bill_id` BIGINT UNSIGNED NOT NULL,           -- FK to tpt_vendor_monthly_bill_log
    `payment_date` DATE NOT NULL,
    `amount_paid` DECIMAL(12, 2) NOT NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'INR',
    `payment_mode` BIGINT UNSIGNED NOT NULL,      -- FK to sys_dropdown_table (Cheque, Bank Transfer, etc.)
    `transaction_reference` VARCHAR(100) DEFAULT NULL, -- Cheque No, Transaction ID
    `payment_status` VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',  -- use dropdown table ('INITIATED','SUCCESS','FAILED')
    `payment_reconciled` tinyint(1) NOT NULL DEFAULT '0',
    `paid_by` BIGINT UNSIGNED DEFAULT NULL,       -- FK to sys_users
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_payment_vendor_bill` FOREIGN KEY (`vendor_bill_id`) REFERENCES `tpt_vendor_monthly_bill`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_payment_paymentMode` FOREIGN KEY (`payment_mode`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_payment_paidBy` FOREIGN KEY (`paid_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sch_vendor_billing_audit_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `vendor_bill_id` BIGINT UNSIGNED NOT NULL,        -- fk to (bil_tenant_invoices)
  `action_date` TIMESTAMP not NULL,
  `action_type` VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- use dropdown table ('Not Billed','Bill Generated','Overdue','Notice Sent','Fully Paid')
  `performed_by` BIGINT UNSIGNED DEFAULT NULL,           -- which user perform the ation
  `event_info` JSON DEFAULT NULL,
  `notes` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_audit_billing` FOREIGN KEY (`vendor_bill_id`) REFERENCES `tpt_vendor_monthly_bill` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


