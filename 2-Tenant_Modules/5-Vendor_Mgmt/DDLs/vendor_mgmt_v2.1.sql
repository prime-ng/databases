-- =======================================================================
-- VENDOR MANAGEMENT MODULE v2.0
-- Database: tenant_db
-- Dependencies: sys_dropdown_table, sys_users, sys_media_table
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VENDOR MASTER
-- =======================================================================

-- 1-Screen Name - Vendor Master
CREATE TABLE IF NOT EXISTS `vnd_vendors` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_name` VARCHAR(100) NOT NULL,
    `vendor_type_id` INT UNSIGNED NOT NULL,  -- FK to sys_dropdown_table (e.g., 'Transport', 'Canteen', 'Security')
    `contact_person` VARCHAR(100) NOT NULL,
    `contact_number` VARCHAR(30) NOT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `address` VARCHAR(512) DEFAULT NULL,
    `gst_number` VARCHAR(50) DEFAULT NULL,      -- Tax ID 1
    `pan_number` VARCHAR(50) DEFAULT NULL,      -- Tax ID 2 (or generic Tax Reg No)
    `bank_name` VARCHAR(100) DEFAULT NULL,
    `bank_account_no` VARCHAR(50) DEFAULT NULL,
    `bank_ifsc_code` VARCHAR(20) DEFAULT NULL,
    `bank_branch` VARCHAR(100) DEFAULT NULL,
    `upi_id` VARCHAR(100) DEFAULT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, -- Soft delete flag
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vnd_vendors_type` FOREIGN KEY (`vendor_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
    UNIQUE KEY `uq_vnd_vendor_name` (`vendor_name`),
    INDEX `idx_vnd_vendor_type` (`vendor_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- ITEM MASTER (Services & Products)
-- =======================================================================

-- 2-Screen Name - Item Master
CREATE TABLE IF NOT EXISTS `vnd_items` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `item_code` VARCHAR(50) DEFAULT NULL,       -- SKU or Internal Item Code (Can be used for barcode printing)
    `item_name` VARCHAR(100) NOT NULL,
    `item_type` ENUM('SERVICE', 'PRODUCT') NOT NULL,
    `item_nature` ENUM('CONSUMABLE', 'ASSET', 'SERVICE', 'NA') NOT NULL DEFAULT 'NA', -- Inventory Hook
    `category_id` INT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (e.g., 'Stationery', 'Bus Rental', 'Plumbing')
    `unit_id` INT UNSIGNED NOT NULL,         -- FK to sys_dropdown_table (e.g., 'Km', 'Day', 'Month', 'Piece', 'Visit')
    `hsn_sac_code` VARCHAR(20) DEFAULT NULL,    -- For GST/Tax compliance
    `default_price` DECIMAL(12, 2) DEFAULT 0.00,-- Standard buying price
    `reorder_level` DECIMAL(12, 2) DEFAULT 0.00,-- Low stock alert threshold (Inventory Hook)
    `item_photo_uploaded` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `description` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vnd_items_category` FOREIGN KEY (`category_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vnd_items_unit` FOREIGN KEY (`unit_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
    UNIQUE KEY `uq_vnd_items_code` (`item_code`),
    INDEX `idx_vnd_items_type` (`item_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- VENDOR AGREEMENTS (Contracts)
-- =======================================================================

-- 3-Screen Name - Agreement Master
CREATE TABLE IF NOT EXISTS `vnd_agreements` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` INT UNSIGNED NOT NULL,
    `agreement_ref_no` VARCHAR(50) DEFAULT NULL,  -- Physical contract reference
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `status` ENUM('DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED') NOT NULL DEFAULT 'DRAFT',
    `billing_cycle` ENUM('MONTHLY', 'ONE_TIME', 'ON_DEMAND') NOT NULL DEFAULT 'MONTHLY',
    `payment_terms_days` INT UNSIGNED DEFAULT 30, -- Credit period in days
    `remarks` TEXT DEFAULT NULL,
    `agreement_uploaded` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vnd_agreements_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE CASCADE,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- AGREEMENT ITEMS (Line Items & Rates)
-- =======================================================================

-- 3-Screen Name - Agreement Master (Agreement Items). This will be part of above Screen
CREATE TABLE IF NOT EXISTS `vnd_agreement_items_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `agreement_id` INT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    -- Billing Logic
    `billing_model` ENUM('FIXED', 'PER_UNIT', 'HYBRID') NOT NULL DEFAULT 'FIXED', 
    -- FIXED: Flat rate per month/cycle.
    -- PER_UNIT: rate * qty.
    -- HYBRID: Fixed Base + (Rate * Qty) OR Fixed Base + (Rate * (Qty - Min_Qty)).
    `fixed_charge` DECIMAL(12, 2) DEFAULT 0.00,       -- Base charge (e.g. Monthly Rent)
    `unit_rate` DECIMAL(10, 2) DEFAULT 0.00,          -- Variable rate (e.g. Per Km)
    `min_guarantee_qty` DECIMAL(10, 2) DEFAULT 0.00,  -- If usage < min, pay min (logic handled in code)
    `tax1_percent` DECIMAL(5, 2) DEFAULT 0.00,
    `tax2_percent` DECIMAL(5, 2) DEFAULT 0.00,
    `tax3_percent` DECIMAL(5, 2) DEFAULT 0.00,
    `tax4_percent` DECIMAL(5, 2) DEFAULT 0.00,
    -- Context (For hooking to specific assets)
    `related_entity_type` INT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown_table ('Vehicle', 'Asset', 'Service', etc.)
    `related_entity_table` VARCHAR(60) DEFAULT NULL, -- e.g., tpt_vehicle, sch_asset, sch_service, etc.
    `related_entity_id` INT UNSIGNED DEFAULT NULL, -- e.g., vehicle_id, asset_id, service_id, etc.
    `description` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vnd_agr_items_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `vnd_agreements`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vnd_agr_items_item` FOREIGN KEY (`item_id`) REFERENCES `vnd_items`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vnd_agr_items_entity_type` FOREIGN KEY (`related_entity_type`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- conditions: 
-- related_entity_type = (Vehicle, Asset, Service, etc.) will have table name as `additional_info` in `sys_dropdown_table` table.
-- e.g. related_entity_type = 'Vehicle' will have table_name as `tpt_vehicle` in 'additional_info' field of `sys_dropdown_table` table.
-- related_entity_id will be the id of the entity in the related_entity_type table.

--Example
Drop Down - Vehicle 
sys_dropdown_table
Key                                             Value                   Additional_Info(JSON)
vnd_agreement_items_jnt.related_entity_type     Vehicle                 {"table_name": "tpt_vehicle"}
vnd_agreement_items_jnt.related_entity_type     Asset                   {"table_name": "sch_asset"}
vnd_agreement_items_jnt.related_entity_type     Service                 {"table_name": "sch_service"}

-- =======================================================================
-- SERVICE/PRODUCT USAGE LOG (Analytics Hook)
-- =======================================================================
-- This table is used to log the usage of services/products by vendors.
-- 4-Screen Name - Usage Log
CREATE TABLE IF NOT EXISTS `vnd_usage_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` INT UNSIGNED NOT NULL,
    `agreement_item_id` INT UNSIGNED NOT NULL, -- Optional, can map to specific agreement line
    `usage_date` DATE NOT NULL,
    `qty_used` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,  -- Quantity used e.g. Vehicle distance(Km), hours, etc.
    `remarks` VARCHAR(255) DEFAULT NULL,
    `logged_by` INT UNSIGNED DEFAULT NULL, -- FK to sys_users (will be NULL for auto log)
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_vnd_usage_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vnd_usage_agr_item` FOREIGN KEY (`agreement_item_id`) REFERENCES `vnd_agreement_items`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. If 'billing_mode' in `vnd_agreement_items` is 'PER_UNIT'OR 'HYBRID', AND'qty_used'  > 0 then only record will be created. in 'vnd_usage_logs' table.
-- 2. If 'billing_mode' in `vnd_agreement_items` is 'FIXED', OR 'qty_used' is 0 then no record will be created in 'vnd_usage_logs' table.

-- =======================================================================
-- VENDOR INVOICES (Bill)
-- =======================================================================

-- 5-Screen Name - Invoice
CREATE TABLE IF NOT EXISTS `vnd_invoices` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` INT UNSIGNED NOT NULL,
    `agreement_id` INT UNSIGNED DEFAULT NULL, -- Optional, if invoice covers one agreement
    `agreement_item_id` INT UNSIGNED DEFAULT NULL, -- Optional, if invoice covers one agreement item
    `item_description` VARCHAR(255) NOT NULL, -- Snapshot of item name
    `invoice_number` VARCHAR(50) NOT NULL,       -- Vendor's Invoice ID
    `invoice_date` DATE NOT NULL,
    `billing_start_date` DATE DEFAULT NULL,
    `billing_end_date` DATE DEFAULT NULL,
    `fixed_charge_amt` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `unit_charge_amt` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `qty_used` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `unit_rate` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `min_guarantee_qty` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `tax1_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `tax2_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `tax3_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `tax4_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `sub_total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `tax_total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `other_charges` DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Penalties/Bonuses
    `discount_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `net_payable` DECIMAL(12, 2) NOT NULL,
    `amount_paid` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `balance_due` DECIMAL(12, 2) GENERATED ALWAYS AS (net_payable - amount_paid) STORED,
    `due_date` DATE DEFAULT NULL,   --  Payment due date (Invoice date + Credit days)
    `status` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (Approval Pending, Approved, Payment Pending, Paid, Overdue)
    `remarks` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT `fk_vnd_inv_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vnd_inv_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `vnd_agreements`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vnd_inv_agreement_item` FOREIGN KEY (`agreement_item_id`) REFERENCES `vnd_agreement_items`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vnd_inv_status` FOREIGN KEY (`status`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
    UNIQUE KEY `uq_vnd_invoice_no` (`vendor_id`, `invoice_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- VENDOR PAYMENTS
-- =======================================================================

-- 6-Screen Name - Payment
CREATE TABLE IF NOT EXISTS `vnd_payments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` INT UNSIGNED NOT NULL,
    `invoice_id` INT UNSIGNED NOT NULL,
    `payment_date` DATE NOT NULL,
    `amount` DECIMAL(14, 2) NOT NULL,
    `payment_mode` INT UNSIGNED NOT NULL, -- FK sys_dropdown (Cheque, NEFT, Cash)
    `reference_no` VARCHAR(100) DEFAULT NULL, -- Trx ID, Cheque No
    `status` ENUM('INITIATED', 'SUCCESS', 'FAILED') DEFAULT 'SUCCESS',
    `paid_by` INT UNSIGNED DEFAULT NULL, -- FK sys_users
    `reconciled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, -- 0: Not Reconciled, 1: Reconciled
    `reconciled_by` INT UNSIGNED DEFAULT NULL, -- FK sys_users
    `reconciled_at` TIMESTAMP NULL DEFAULT NULL,
    `remarks` TEXT DEFAULT NULL,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vnd_pay_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `vnd_invoices`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vnd_pay_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vnd_pay_mode` FOREIGN KEY (`payment_mode`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vendor Complaints will be handled using common Complaint Module.




-- =======================================================================
-- SEED DATA (System Dropdowns)
-- =======================================================================
-- Note: Assuming sys_dropdown_needs and sys_dropdown_table exist.

-- 10.1 Vendor Types
INSERT INTO `sys_dropdown_needs` 
(`db_type`,`table_name`,`column_name`,`menu_category`,`main_menu`,`sub_menu`,`tab_name`,`field_name`,`is_system`,`tenant_creation_allowed`) 
VALUES 
('Tenant','vnd_vendors','vendor_type_id','Operations','Vendor Mgmt','Vendor Master','Basic Info','Vendor Type',1,1);

SET @need_id_type = LAST_INSERT_ID();

INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`) VALUES
(@need_id_type, 1, 'vnd_vendors.transport', 'Transport', 'String'),
(@need_id_type, 2, 'vnd_vendors.canteen', 'Canteen/Catering', 'String'),
(@need_id_type, 3, 'vnd_vendors.security', 'Security', 'String'),
(@need_id_type, 4, 'vnd_vendors.stationery', 'Stationery', 'String'),
(@need_id_type, 5, 'vnd_vendors.maintenance', 'Maintenance', 'String'),
(@need_id_type, 6, 'vnd_vendors.medical', 'Medical/Doctor', 'String'),
(@need_id_type, 7, 'vnd_vendors.other', 'Other', 'String');

-- 10.2 Item Categories
INSERT INTO `sys_dropdown_needs` 
(`db_type`,`table_name`,`column_name`,`menu_category`,`main_menu`,`sub_menu`,`tab_name`,`field_name`,`is_system`,`tenant_creation_allowed`) 
VALUES 
('Tenant','vnd_items','category_id','Operations','Vendor Mgmt','Item Master','Basic Info','Item Category',1,1);

SET @need_id_cat = LAST_INSERT_ID();

INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`) VALUES
(@need_id_cat, 1, 'vnd_items.cat.bus', 'Bus Rental', 'String'),
(@need_id_cat, 2, 'vnd_items.cat.driver', 'Driver Service', 'String'),
(@need_id_cat, 3, 'vnd_items.cat.food', 'Food/Meal', 'String'),
(@need_id_cat, 4, 'vnd_items.cat.uniform', 'Uniforms', 'String'),
(@need_id_cat, 5, 'vnd_items.cat.books', 'Books', 'String');

-- 10.3 Measurement Units
INSERT INTO `sys_dropdown_needs` 
(`db_type`,`table_name`,`column_name`,`menu_category`,`main_menu`,`sub_menu`,`tab_name`,`field_name`,`is_system`,`tenant_creation_allowed`) 
VALUES 
('Tenant','vnd_items','unit_id','Operations','Vendor Mgmt','Item Master','Rates','Unit',1,0);

SET @need_id_unit = LAST_INSERT_ID();

INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`) VALUES
(@need_id_unit, 1, 'unit.km', 'Kilometer', 'String'),
(@need_id_unit, 2, 'unit.day', 'Day', 'String'),
(@need_id_unit, 3, 'unit.month', 'Month', 'String'),
(@need_id_unit, 4, 'unit.visit', 'Visit', 'String'),
(@need_id_unit, 5, 'unit.hour', 'Hour', 'String'),
(@need_id_unit, 6, 'unit.piece', 'Piece', 'String'),
(@need_id_unit, 7, 'unit.kg', 'Kg', 'String'),
(@need_id_unit, 8, 'unit.trip', 'Trip', 'String');

-- 10.4 Invoice Status
INSERT INTO `sys_dropdown_needs` 
(`db_type`,`table_name`,`column_name`,`menu_category`,`main_menu`,`sub_menu`,`tab_name`,`field_name`,`is_system`,`tenant_creation_allowed`) 
VALUES 
('Tenant','vnd_invoices','status','Operations','Vendor Mgmt','Invoices','Details','Status',1,0);

SET @need_id_status = LAST_INSERT_ID();

INSERT INTO `sys_dropdown_table` (`dropdown_needs_id`, `ordinal`, `key`, `value`, `type`) VALUES
(@need_id_status, 1, 'inv.pending', 'Pending', 'String'),
(@need_id_status, 2, 'inv.approved', 'Approved', 'String'),
(@need_id_status, 3, 'inv.paid', 'Fully Paid', 'String'),
(@need_id_status, 4, 'inv.partial', 'Partially Paid', 'String'),
(@need_id_status, 5, 'inv.cancelled', 'Cancelled', 'String');

SET FOREIGN_KEY_CHECKS = 1;
