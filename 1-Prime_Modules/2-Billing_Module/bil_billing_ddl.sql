-- ----------------------------------------------------------------------------------------------------------------
-- Tenant Invoicing
-- ----------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `bil_tenant_invoices` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` BIGINT UNSIGNED NOT NULL,               -- old name 'org_id'
  `tenant_plan_id` BIGINT UNSIGNED NOT NULL,          -- old Name 'organization_plan_id'
  `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,      -- FK
  `invoice_no` VARCHAR(50) NOT NULL,                  -- Should be Auto-Generated
  `invoice_date` DATE NOT NULL,                       -- Invoice Date will always be Next Day to billing_end_date
  `billing_start_date` DATE NOT NULL,
  `billing_end_date` DATE NOT NULL,
  `min_billing_qty` int unsigned NOT NULL DEFAULT 1,    -- No of Lincenses (if Student count < Min_Qty then min_qty will be charged))
  `total_user_qty` int unsigned NOT NULL DEFAULT 1,     -- Number of licenses used by Org in the billing period
  `plan_rate` decimal(12,2) NOT NULL,                     -- applicable plan rate as per school aggrement
  `billing_qty` int unsigned NOT NULL DEFAULT 1,        -- Billing Qty. will be either `min_billing_qty` or `total_license_qty`, whcihcever is higher)
  `sub_total` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `discount_percent` decimal(5,2) NOT NULL DEFAULT 0.00,  -- discount in percentage per billing cycle
  `discount_amount` decimal(12,2) NOT NULL DEFAULT 0.00,  -- discount as a fixed amount per billing cycle
  `discount_remark` varchar(50) NULL,
  `extra_charges` decimal(12,2) NOT NULL DEFAULT 0.00, 
  `charges_remark` varchar(50) NULL,
  `tax1_percent` decimal(5,2) NOT NULL DEFAULT 0.00,
  `tax1_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax1_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax2_percent` decimal(5,2) NOT NULL DEFAULT 0.00,      -- 
  `tax2_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax2_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax3_percent` decimal(5,2) NOT NULL DEFAULT 0.00,      -- 
  `tax3_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax3_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax4_percent` decimal(5,2) NOT NULL DEFAULT 0.00,      -- 
  `tax4_remark` varchar(50) NULL,                           -- Acomodate different type of taxes - GST, IGST, CGST & other Taxes)
  `tax4_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total_tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00, 
  `net_payable_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- 
  `paid_amount` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING',        -- Will use Dropdown Table to populate (Tenant_Invoice_Status)
  `credit_days`  SMALLINT UNSIGNED NOT NULL,              -- This will be used to calculat Due Date
  `payment_due_date` DATE NOT NULL,                       -- Bill Date + credit_days
  `is_recurring` TINYINT(1) NOT NULL DEFAULT 1,
  `auto_renew` TINYINT(1) NOT NULL DEFAULT 1,
  `remarks` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tenantInvoices_invoiceNo` (`invoice_no`),
  CONSTRAINT `fk_tenantInvoices_tenantId` FOREIGN KEY (`tenant_id`) REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tenantInvoices_PlanId` FOREIGN KEY (`tenant_plan_id`) REFERENCES `prm_tenant_plan_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tenantInvoices_cycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_modules_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_invoice_id` BIGINT UNSIGNED NOT NULL,   -- fk to (bil_tenant_invoices)
  `module_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK
  UNIQUE KEY `uq_tenantInvModule_orgInvId_moduleId` (`tenant_invoicing_id`, `module_id`),
  CONSTRAINT `fk_tenantInvModule_invoicingId` FOREIGN KEY (`tenant_invoice_id`) REFERENCES `bil_tenant_invoice` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tenantInvModule_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_payments` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_invoice_id` BIGINT UNSIGNED NOT NULL,    -- fk to (bil_tenant_invoices)
  `payment_date` DATE NOT NULL,
  `transaction_id` VARCHAR(100) DEFAULT NULL,
  `mode` VARCHAR(20) NOT NULL DEFAULT 'ONLINE',      -- use dropdown table ('ONLINE','BANK_TRANSFER','CASH','CHEQUE')
  `mode_other` VARCHAR(20) DEFAULT NULL,
  `amount_paid` DECIMAL(14,2) NOT NULL,
  `consolidated_amount` DECIMAL(14,2) NULL,      -- If Consolidated Payment then only this will be stored else Null.
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `payment_status` NOT NULL VARCHAR(20) DEFAULT 'SUCCESS',  -- use dropdown table ('INITIATED','SUCCESS','FAILED')
  `gateway_response` JSON DEFAULT NULL,
  `payment_reconciled` tinyint(1) NOT NULL DEFAULT '0',
  `remarks` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_tenantInvPayment_tenantInvId` FOREIGN KEY (`tenant_invoicing_id`) REFERENCES `bil_tenant_invoicing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note - Below table will have multiple records for every billing. 1 Record for every action.
CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_audit_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tenant_invoicing_id` BIGINT UNSIGNED NOT NULL,        -- fk to (bil_tenant_invoices)
  `action_date` TIMESTAMP not NULL,
  `action_type` VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- use dropdown table ('Not Billed','Bill Generated','Overdue','Notice Sent','Fully Paid')
  `performed_by` BIGINT UNSIGNED DEFAULT NULL,           -- which user perform the ation
  `event_info` JSON DEFAULT NULL,
  `notes` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_audit_billing` FOREIGN KEY (`tenant_invoicing_id`) REFERENCES `bil_tenant_invoicing` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- ----------------------------------------------------------------------------------------------------------
-- Support Tables
-- ----------------------------------------------------------------------------------------------------------


-- Plan & Module
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prm_billing_cycles` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `short_name` VARCHAR(50) NOT NULL,  -- 'MONTHLY','QUARTERLY','YEARLY','ONE_TIME'
  `name` VARCHAR(50) NOT NULL,
  `months_count` TINYINT UNSIGNED NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `is_recurring` TINYINT(1) NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY `uq_billingCycles_code` (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_modules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint unsigned DEFAULT NULL,    -- fk to self
  `name` varchar(50) NOT NULL,
  `version` tinyint NOT NULL DEFAULT '1',
  `is_sub_module` tinyint(1) NOT NULL DEFAULT '0',    -- kept for CONSTRAINT `chk_isSubModule_parentId`
  `description` varchar(500) DEFAULT NULL,
  `is_core` tinyint(1) NOT NULL DEFAULT '0',
  `default_visible` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_view` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_add` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_edit` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_delete` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_export` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_import` tinyint(1) NOT NULL DEFAULT '1',
  `available_perm_print` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_module_parentId_name_version` (`parent_id`,`name`,`version`),
  CONSTRAINT `fk_module_parentId` FOREIGN KEY (`parent_id`) REFERENCES `sys_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT chk_isSubModule_parentId CHECK ((is_sub_module = 1 AND parent_id IS NOT NULL) OR (is_sub_module = 0 AND parent_id IS NULL))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `prm_plans` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(20) NOT NULL,
  `version` int unsigned NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `billing_cycle_id` SMALLINT NOT NULL,           -- Default billing Cycle
  `price_monthly` decimal(12,2) DEFAULT NULL,     -- For Same Plan we may charge different for Monthly payment/Quaterly/Yearly
  `price_quarterly` decimal(12,2) DEFAULT NULL,   -- For Same Plan we may charge different for Monthly payment/Quaterly/Yearly
  `price_yearly` decimal(12,2) DEFAULT NULL,      -- For Same Plan we may charge different for Monthly payment/Quaterly/Yearly
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `trial_days` int unsigned NOT NULL DEFAULT '0', -- Allowed Trial Days
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plans_planCode_version` (`plan_code`,`version`),
  CONSTRAINT `fk_plans_billingCycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles` (`id`) ON DELETE RESTRICT,
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `prm_module_plan_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` bigint unsigned NOT NULL,
  `module_id` bigint unsigned NOT NULL,
  `is_active` tinyint(1) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_modulePlan_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_modulePlan_planId` FOREIGN KEY (`plan_id`) REFERENCES `prm_plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tenant Subscription
-- ----------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prm_tenant_plan_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint unsigned NOT NULL,             -- old name 'org_id'
  `plan_id` bigint unsigned NOT NULL,
  `is_subscribed` tinyint(1) NOT NULL DEFAULT '1',
  `is_trial` tinyint(1) NOT NULL DEFAULT '0',
  `auto_renew` tinyint(1) NOT NULL DEFAULT '1',
  `automatic_billing` tinyint(1) NOT NULL DEFAULT '1',
  `status` varchar(20) NOT NULL DEFAULT 'ACTIVE',  -- Need to be created in dorpdown Table ('ACTIVE','SUSPENDED','CANCELED','EXPIRED')
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `current_flag` int GENERATED ALWAYS AS ((case when (`is_subscribed` = 1) then `org_id` else NULL end)) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenantPlan_currentFlag_planId` (`current_flag`,`plan_id`),
  CONSTRAINT `fk_tenantPlan_orgId` FOREIGN KEY (`tenant_id`) REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tenantPlan_planId` FOREIGN KEY (`plan_id`) REFERENCES `prm_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `prm_tenant_plan_rates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tenant_plan_id` bigint unsigned NOT NULL,         -- Old name 'organization_plan_id'
  `start_date` date DEFAULT NULL,                    -- Plan Start Date
  `end_date` date DEFAULT NULL,                      -- Plan End Date
  `billing_cycle_id` SMALLINT UNSIGNED NOT NULL,
  `billing_cycle_day` tinyint NOT NULL DEFAULT '1',  -- This will be day of billing every month for this Org.
  `monthly_rate` decimal(12,2) NOT NULL,
  `rate_per_cycle` decimal(12,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `min_billing_qty` int unsigned NOT NULL DEFAULT '1',  -- Edited Name (Lencenses (if Student count < Min_Qty then min_qty will be charged))
  `discount_percent` decimal(5,2) NOT NULL DEFAULT '0.00',  -- discount in percentage per billing cycle
  `discount_amount` decimal(12,2) NOT NULL DEFAULT '0.00',  -- discount as a fixed amount per billing cycle
  `discount_remark` varchar(50) NULL,                       -- Added New
  `extra_charges` decimal(12,2) NOT NULL DEFAULT '0.00',    -- Added New
  `charges_remark` varchar(50) NULL,                        -- Added New
  `tax1_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax1_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `tax2_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax2_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `tax3_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax3_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `tax4_percent` decimal(5,2) NOT NULL DEFAULT '0.00',      -- Edited
  `tax4_remark` varchar(50) NULL,                           -- Added New (to acomodate different type of taxes - GST, IGST, CGST etc.)
  `credit_days` SMALLINT UNSIGNED NOT NULL,                 -- Number of day to calculate 'next_billing_date'
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenantPlanRates_PlanId_stDate_endDate` (`tenant_plan_id`,`start_date`,`end_date`),
  CONSTRAINT `fk_tenantPlanRates_billingCycleId` FOREIGN KEY (`billing_cycle_id`) REFERENCES `prm_billing_cycles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tenantPlanRates_orgPlanId` FOREIGN KEY (`organization_plan_id`) REFERENCES `prm_tenant_plan_jnt` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- old name 'sch_module_organization_plan_jnt'
CREATE TABLE IF NOT EXISTS `prm_tenant_plan_module_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `module_id` bigint unsigned NOT NULL,
  `tenant_plan_id` bigint unsigned NOT NULL,     -- old name 'organization_plan_id'
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_moduleTenantPlan_moduleId` FOREIGN KEY (`module_id`) REFERENCES `sys_modules` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_moduleTenantPlan_tenantPlanId` FOREIGN KEY (`tenant_plan_id`) REFERENCES `prm_tenant_plan_jnt` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- This Table will have entries for the plan validity date range within the current Academic Session (1st April to 31st March).
CREATE TABLE prm_tenant_plan_billing_schedule (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_plan_id BIGINT UNSIGNED NOT NULL,
    tenant_id BIGINT UNSIGNED NOT NULL,
    billing_cycle_id SMALLINT UNSIGNED NOT NULL,
    schedule_billing_date DATE NOT NULL,
    billing_start_date DATE NOT NULL,
    billing_end_date DATE NOT NULL,
    bill_generated TINYINT(1) NOT NULL DEFAULT 0,
    generated_invoice_id BIGINT UNSIGNED DEFAULT NULL,  -- Fk to bil_tenant_invoices
    is_active tinyint(1) NOT NULL DEFAULT '1',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tenantPlanBillSched_planId FOREIGN KEY (tenant_plan_id) REFERENCES prm_tenant_plan_jnt(id) ON DELETE CASCADE,
    CONSTRAINT fk_tenantPlanBillSched_tenant FOREIGN KEY (tenant_id) REFERENCES prm_tenant(id) ON DELETE CASCADE,
    CONSTRAINT fk_tenantPlanBillSched_cycle FOREIGN KEY (billing_cycle_id) REFERENCES prm_billing_cycles(id) ON DELETE RESTRICT,
    CONSTRAINT fk_tenantPlanBillSched_invId FOREIGN KEY (generated_invoice_id) REFERENCES bil_tenant_invoices(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------
-- Chnage Log
-- --------------------------------------------------------------------------------------------
-- Add New Field  - Table(bil_tenant_invoicing_payments)    - Field(consolidated_amount)
-- Change Filed   - Table(bil_tenant_invoicing_audit_logs)  - Field(notes) (Make it Varchar(500) from text)
-- Add New Field  - Table(bil_tenant_invoicing_audit_logs)  - Field(event_info)
-- Change Filed   - Table(bil_tenant_invoicing_audit_logs)  - Field(action_date) Change Date -> timestamp
