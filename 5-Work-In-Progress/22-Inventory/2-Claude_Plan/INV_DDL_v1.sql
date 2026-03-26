-- =============================================================================
-- INV — Inventory Module DDL
-- Module: Inventory (Modules\Inventory)
-- Table Prefix: inv_* (28 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-26
-- Based on: INV_Inventory_Requirement.md v2
-- Sub-Modules: L1 Masters, L2 Stock Ledger, L3 Procurement, L4 Vendor,
--              L5 Assets, L6 Quotations, Stock Issue, Reorder
-- =============================================================================
--
-- FK TYPE NOTES (verified against tenant_db_v2.sql):
--   sch_department.id  = INT UNSIGNED → department_id FKs = INT UNSIGNED
--   sch_employees.id   = INT UNSIGNED → employee FKs   = INT UNSIGNED
--   vnd_vendors.id     = INT UNSIGNED → vendor_id FKs  = INT UNSIGNED
--   acc_ledgers.id     = BIGINT UNSIGNED
--   acc_tax_rates.id   = BIGINT UNSIGNED
--   acc_fixed_assets.id = BIGINT UNSIGNED
--   acc_vouchers       = NOT yet in tenant_db_v2.sql (D21 dependency) —
--                        FK columns defined as BIGINT UNSIGNED; CONSTRAINT
--                        commented out — UNCOMMENT after Accounting DDL applied
--   sys_users refs     = BIGINT UNSIGNED (per project audit column convention)
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================================
-- LAYER 1 — No inv_* dependencies
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_units_of_measure` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`           VARCHAR(50)      NOT NULL                COMMENT 'UOM full name e.g. Pieces',
    `symbol`         VARCHAR(10)      NOT NULL                COMMENT 'Short symbol e.g. Pcs',
    `decimal_places` TINYINT          NOT NULL DEFAULT 0      COMMENT 'Decimal precision 0-4; 0=Pcs, 2=Kg',
    `is_system`      TINYINT(1)       NOT NULL DEFAULT 0      COMMENT '1=seeded system UOM, cannot delete',
    -- Standard audit columns
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
    `created_by`     BIGINT UNSIGNED  NOT NULL                COMMENT 'sys_users.id',
    `updated_by`     BIGINT UNSIGNED  NOT NULL                COMMENT 'sys_users.id',
    `created_at`     TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Record creation time',
    `updated_at`     TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Last update time',
    `deleted_at`     TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_uom_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Unit of Measure master — seeded with 10 system UOMs';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_asset_categories` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`              VARCHAR(100)     NOT NULL                COMMENT 'Category name e.g. IT Equipment',
    `code`              VARCHAR(20)      NULL DEFAULT NULL        COMMENT 'Short code e.g. IT-ASSET',
    `depreciation_rate` DECIMAL(5,2)     NULL DEFAULT NULL        COMMENT 'Annual WDV depreciation % per Income Tax Act',
    `useful_life_years` INT              NULL DEFAULT NULL        COMMENT 'Expected useful life per Income Tax Act',
    -- Standard audit columns
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
    `created_by`        BIGINT UNSIGNED  NOT NULL                COMMENT 'sys_users.id',
    `updated_by`        BIGINT UNSIGNED  NOT NULL                COMMENT 'sys_users.id',
    `created_at`        TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Record creation time',
    `updated_at`        TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Last update time',
    `deleted_at`        TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_ac_code` (`code`),
    KEY `idx_inv_acat_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Asset category master with depreciation rates per Income Tax Act WDV method';

-- =============================================================================
-- LAYER 2 — Depends on Layer 1 only
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_stock_groups` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`           VARCHAR(100)     NOT NULL                COMMENT 'Stock group display name',
    `code`           VARCHAR(20)      NULL DEFAULT NULL        COMMENT 'Optional short group code',
    `alias`          VARCHAR(100)     NULL DEFAULT NULL        COMMENT 'Alternative name',
    `parent_id`      BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Self-referencing parent for hierarchy',
    `default_uom_id` BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Default UOM for items in this group — inv_units_of_measure.id',
    `sequence`       INT              NOT NULL DEFAULT 0       COMMENT 'Display order',
    `is_system`      TINYINT(1)       NOT NULL DEFAULT 0       COMMENT '1=seeded group, cannot delete',
    -- Standard audit columns
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`     BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`     BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_sg_code` (`code`),
    KEY `idx_inv_sg_parent_id`      (`parent_id`),
    KEY `idx_inv_sg_default_uom_id` (`default_uom_id`),
    KEY `idx_inv_sg_is_active`      (`is_active`),
    CONSTRAINT `fk_inv_sg_parent_id`      FOREIGN KEY (`parent_id`)      REFERENCES `inv_stock_groups`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_inv_sg_default_uom_id` FOREIGN KEY (`default_uom_id`) REFERENCES `inv_units_of_measure` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Hierarchical stock category tree; seeded with 10 system groups';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_uom_conversions` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `from_uom_id`       BIGINT UNSIGNED  NOT NULL                COMMENT 'Source UOM — inv_units_of_measure.id',
    `to_uom_id`         BIGINT UNSIGNED  NOT NULL                COMMENT 'Target UOM — inv_units_of_measure.id',
    `conversion_factor` DECIMAL(15,6)    NOT NULL                COMMENT '1 from_uom = X to_uom',
    `effective_from`    DATE             NULL DEFAULT NULL        COMMENT 'Conversion valid from (optional)',
    `effective_to`      DATE             NULL DEFAULT NULL        COMMENT 'Conversion valid until (optional)',
    -- Standard audit columns
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`        BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`        BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`        TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`        TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`        TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_uom_conv` (`from_uom_id`, `to_uom_id`),
    KEY `idx_inv_uom_conv_from` (`from_uom_id`),
    KEY `idx_inv_uom_conv_to`   (`to_uom_id`),
    CONSTRAINT `fk_inv_uom_conv_from_uom_id` FOREIGN KEY (`from_uom_id`) REFERENCES `inv_units_of_measure` (`id`),
    CONSTRAINT `fk_inv_uom_conv_to_uom_id`   FOREIGN KEY (`to_uom_id`)   REFERENCES `inv_units_of_measure` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='UOM conversion rules; bidirectional — 1 Box=10 Pcs implies 1 Pcs=0.1 Box';

-- =============================================================================
-- LAYER 3 — Depends on Layer 2 + cross-module
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_stock_items` (
    `id`                    BIGINT UNSIGNED                              NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`                  VARCHAR(150)                                 NOT NULL                COMMENT 'Item name',
    `sku`                   VARCHAR(50)                                  NULL DEFAULT NULL        COMMENT 'Stock Keeping Unit code; unique when set',
    `alias`                 VARCHAR(150)                                 NULL DEFAULT NULL        COMMENT 'Alternative name',
    `stock_group_id`        BIGINT UNSIGNED                              NOT NULL                COMMENT 'Category — inv_stock_groups.id',
    `uom_id`                BIGINT UNSIGNED                              NOT NULL                COMMENT 'Primary UOM — inv_units_of_measure.id',
    `item_type`             ENUM('consumable','asset')                   NOT NULL DEFAULT 'consumable' COMMENT 'consumable=regular stock; asset=triggers fixed asset on GRN',
    `opening_balance_qty`   DECIMAL(15,3)                               NOT NULL DEFAULT 0      COMMENT 'Opening stock quantity for tenant onboarding',
    `opening_balance_rate`  DECIMAL(15,2)                               NOT NULL DEFAULT 0      COMMENT 'Opening stock rate per unit',
    `opening_balance_value` DECIMAL(15,2)                               NOT NULL DEFAULT 0      COMMENT 'Opening stock total value',
    `valuation_method`      ENUM('fifo','weighted_average','last_purchase') NOT NULL DEFAULT 'weighted_average' COMMENT 'Per-item stock valuation method',
    `reorder_level`         DECIMAL(15,3)                               NULL DEFAULT NULL        COMMENT 'Alert threshold qty — trigger ReorderAlertJob',
    `reorder_qty`           DECIMAL(15,3)                               NULL DEFAULT NULL        COMMENT 'Quantity to reorder when threshold hit',
    `min_stock`             DECIMAL(15,3)                               NULL DEFAULT NULL        COMMENT 'Minimum stock level',
    `max_stock`             DECIMAL(15,3)                               NULL DEFAULT NULL        COMMENT 'Maximum stock level',
    `auto_reorder_pr`       TINYINT(1)                                  NOT NULL DEFAULT 0       COMMENT '1=auto-create draft PR when reorder level hit',
    `has_batch_tracking`    TINYINT(1)                                  NOT NULL DEFAULT 0       COMMENT '1=enable batch number tracking for this item',
    `has_expiry_tracking`   TINYINT(1)                                  NOT NULL DEFAULT 0       COMMENT '1=enable expiry date tracking for this item',
    `hsn_sac_code`          VARCHAR(20)                                 NULL DEFAULT NULL        COMMENT 'GST classification code (HSN for goods, SAC for services)',
    `brand`                 VARCHAR(100)                                NULL DEFAULT NULL        COMMENT 'Brand name',
    `model`                 VARCHAR(100)                                NULL DEFAULT NULL        COMMENT 'Model number',
    `warranty_months`       INT                                         NULL DEFAULT NULL        COMMENT 'Warranty period in months (for assets)',
    `tax_rate_id`           BIGINT UNSIGNED                             NULL DEFAULT NULL        COMMENT 'GST rate — acc_tax_rates.id',
    `purchase_ledger_id`    BIGINT UNSIGNED                             NULL DEFAULT NULL        COMMENT 'Stock-in-hand accounting ledger — acc_ledgers.id',
    `sales_ledger_id`       BIGINT UNSIGNED                             NULL DEFAULT NULL        COMMENT 'Sales/issue accounting ledger — acc_ledgers.id',
    -- Standard audit columns
    `is_active`             TINYINT(1)                                  NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`            BIGINT UNSIGNED                             NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`            BIGINT UNSIGNED                             NOT NULL                 COMMENT 'sys_users.id',
    `created_at`            TIMESTAMP                                   NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`            TIMESTAMP                                   NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`            TIMESTAMP                                   NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_si_sku` (`sku`),
    KEY `idx_inv_sitm_stock_group_id`     (`stock_group_id`),
    KEY `idx_inv_sitm_uom_id`             (`uom_id`),
    KEY `idx_inv_sitm_item_type`          (`item_type`),
    KEY `idx_inv_sitm_tax_rate_id`        (`tax_rate_id`),
    KEY `idx_inv_sitm_purchase_ledger_id` (`purchase_ledger_id`),
    KEY `idx_inv_sitm_sales_ledger_id`    (`sales_ledger_id`),
    KEY `idx_inv_sitm_is_active`          (`is_active`),
    CONSTRAINT `fk_inv_sitm_stock_group_id` FOREIGN KEY (`stock_group_id`) REFERENCES `inv_stock_groups`    (`id`),
    CONSTRAINT `fk_inv_sitm_uom_id`         FOREIGN KEY (`uom_id`)         REFERENCES `inv_units_of_measure` (`id`)
    -- NOTE: acc_tax_rates, acc_ledgers FKs — UNCOMMENT after Accounting DDL applied:
    -- CONSTRAINT `fk_inv_sitm_tax_rate_id`        FOREIGN KEY (`tax_rate_id`)        REFERENCES `acc_tax_rates` (`id`) ON DELETE SET NULL,
    -- CONSTRAINT `fk_inv_sitm_purchase_ledger_id`  FOREIGN KEY (`purchase_ledger_id`) REFERENCES `acc_ledgers`   (`id`) ON DELETE SET NULL,
    -- CONSTRAINT `fk_inv_sitm_sales_ledger_id`     FOREIGN KEY (`sales_ledger_id`)    REFERENCES `acc_ledgers`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Item catalog — every procurable and issuable item with valuation method and accounting linkage';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_godowns` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`                    VARCHAR(100)     NOT NULL                COMMENT 'Godown name e.g. Main Store',
    `code`                    VARCHAR(20)      NULL DEFAULT NULL        COMMENT 'Short code e.g. MAIN',
    `parent_id`               BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Parent godown for sub-godown hierarchy — inv_godowns.id',
    `address`                 VARCHAR(500)     NULL DEFAULT NULL        COMMENT 'Physical address of storage location',
    `in_charge_employee_id`   INT UNSIGNED     NULL DEFAULT NULL        COMMENT 'Godown in-charge — sch_employees.id (INT UNSIGNED to match sch_employees)',
    `is_system`               TINYINT(1)       NOT NULL DEFAULT 0       COMMENT '1=seeded godown, cannot delete',
    -- Standard audit columns
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`              BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`              BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`              TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`              TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`              TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_gdn_code` (`code`),
    KEY `idx_inv_gdn_parent_id`            (`parent_id`),
    KEY `idx_inv_gdn_in_charge_employee_id` (`in_charge_employee_id`),
    KEY `idx_inv_gdn_is_active`            (`is_active`),
    CONSTRAINT `fk_inv_gdn_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `inv_godowns` (`id`) ON DELETE SET NULL
    -- NOTE: sch_employees FK — UNCOMMENT when SchoolSetup module is in place:
    -- CONSTRAINT `fk_inv_gdn_in_charge_employee_id` FOREIGN KEY (`in_charge_employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Storage locations; self-referencing hierarchy; seeded with 5 system godowns';

-- =============================================================================
-- LAYER 4 — Depends on Layer 3 + cross-module
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_stock_balances` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `stock_item_id`  BIGINT UNSIGNED  NOT NULL                COMMENT 'Item — inv_stock_items.id',
    `godown_id`      BIGINT UNSIGNED  NOT NULL                COMMENT 'Storage location — inv_godowns.id',
    `current_qty`    DECIMAL(15,3)    NOT NULL DEFAULT 0      COMMENT 'Running stock quantity — updated atomically with lockForUpdate()',
    `current_value`  DECIMAL(15,2)    NOT NULL DEFAULT 0      COMMENT 'Running stock valuation (qty × rate)',
    `last_entry_at`  TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Timestamp of last stock movement for this item+godown',
    -- Standard audit columns
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`     BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`     BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_sb_item_godown` (`stock_item_id`, `godown_id`),
    KEY `idx_inv_sbal_godown_id`  (`godown_id`),
    KEY `idx_inv_sbal_is_active`  (`is_active`),
    CONSTRAINT `fk_inv_sbal_stock_item_id` FOREIGN KEY (`stock_item_id`) REFERENCES `inv_stock_items` (`id`),
    CONSTRAINT `fk_inv_sbal_godown_id`     FOREIGN KEY (`godown_id`)     REFERENCES `inv_godowns`    (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Denormalized running balance per item per godown; replaces expensive SUM queries; lockForUpdate() on concurrent writes';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_item_vendor_jnt` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `item_id`             BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `vendor_id`           INT UNSIGNED     NOT NULL                COMMENT 'Vendor — vnd_vendors.id (INT UNSIGNED to match vnd_vendors)',
    `vendor_sku`          VARCHAR(50)      NULL DEFAULT NULL        COMMENT 'Vendor''s own item code for cross-reference',
    `last_purchase_rate`  DECIMAL(15,2)    NULL DEFAULT NULL        COMMENT 'Auto-updated on GRN acceptance',
    `last_purchase_date`  DATE             NULL DEFAULT NULL        COMMENT 'Date of last purchase from this vendor',
    `lead_time_days`      INT              NULL DEFAULT NULL        COMMENT 'Vendor delivery lead time in days',
    `is_preferred`        TINYINT(1)       NOT NULL DEFAULT 0       COMMENT '1=preferred vendor for this item',
    -- Standard audit columns
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`          BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`          BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`          TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`          TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`          TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_ivj_item_vendor` (`item_id`, `vendor_id`),
    KEY `idx_inv_ivj_item_id`   (`item_id`),
    KEY `idx_inv_ivj_vendor_id` (`vendor_id`),
    KEY `idx_inv_ivj_is_active` (`is_active`),
    CONSTRAINT `fk_inv_ivj_item_id` FOREIGN KEY (`item_id`) REFERENCES `inv_stock_items` (`id`)
    -- CONSTRAINT `fk_inv_ivj_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Item-to-vendor assignment; multiple vendors per item; one preferred per item';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_rate_contracts` (
    `id`              BIGINT UNSIGNED                             NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `vendor_id`       INT UNSIGNED                               NOT NULL                COMMENT 'Vendor — vnd_vendors.id (INT UNSIGNED)',
    `contract_number` VARCHAR(50)                                NULL DEFAULT NULL        COMMENT 'Rate contract reference number e.g. RC-2026-001',
    `valid_from`      DATE                                       NOT NULL                COMMENT 'Contract start date',
    `valid_to`        DATE                                       NOT NULL                COMMENT 'Contract end date; expiry alert 30 days before',
    `status`          ENUM('draft','active','expired','cancelled') NOT NULL DEFAULT 'draft' COMMENT 'draft=new; active=in effect; expired=past valid_to; cancelled=terminated',
    `remarks`         TEXT                                       NULL DEFAULT NULL        COMMENT 'Additional notes',
    -- Standard audit columns
    `is_active`       TINYINT(1)                                 NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`      BIGINT UNSIGNED                            NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`      BIGINT UNSIGNED                            NOT NULL                 COMMENT 'sys_users.id',
    `created_at`      TIMESTAMP                                  NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`      TIMESTAMP                                  NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`      TIMESTAMP                                  NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_rc_contract_number` (`contract_number`),
    KEY `idx_inv_rc_vendor_id`  (`vendor_id`),
    KEY `idx_inv_rc_status`     (`status`),
    KEY `idx_inv_rc_valid_to`   (`valid_to`),
    KEY `idx_inv_rc_is_active`  (`is_active`)
    -- CONSTRAINT `fk_inv_rc_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Vendor rate contracts with validity periods; expiry alert at 30 days before valid_to';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_purchase_requisitions` (
    `id`            BIGINT UNSIGNED                                           NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `pr_number`     VARCHAR(50)                                               NOT NULL                COMMENT 'Auto-generated PR number e.g. PR-2026-001',
    `requested_by`  BIGINT UNSIGNED                                           NOT NULL                COMMENT 'Requester — sys_users.id',
    `department_id` INT UNSIGNED                                              NULL DEFAULT NULL        COMMENT 'Department — sch_department.id (INT UNSIGNED to match sch_department)',
    `required_date` DATE                                                      NOT NULL                COMMENT 'Requested delivery date',
    `priority`      ENUM('low','normal','high','urgent')                      NOT NULL DEFAULT 'normal' COMMENT 'Procurement priority level',
    `status`        ENUM('draft','submitted','approved','rejected','converted','cancelled') NOT NULL DEFAULT 'draft' COMMENT 'PR lifecycle status',
    `approved_by`   BIGINT UNSIGNED                                           NULL DEFAULT NULL        COMMENT 'Approver — sys_users.id',
    `approved_at`   TIMESTAMP                                                 NULL DEFAULT NULL        COMMENT 'Approval timestamp',
    `remarks`       TEXT                                                      NULL DEFAULT NULL        COMMENT 'Notes or rejection reason',
    -- Standard audit columns
    `is_active`     TINYINT(1)                                                NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`    BIGINT UNSIGNED                                           NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`    BIGINT UNSIGNED                                           NOT NULL                 COMMENT 'sys_users.id',
    `created_at`    TIMESTAMP                                                 NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`    TIMESTAMP                                                 NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`    TIMESTAMP                                                 NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_pr_number` (`pr_number`),
    KEY `idx_inv_pr_requested_by`  (`requested_by`),
    KEY `idx_inv_pr_department_id` (`department_id`),
    KEY `idx_inv_pr_status`        (`status`),
    KEY `idx_inv_pr_approved_by`   (`approved_by`),
    KEY `idx_inv_pr_is_active`     (`is_active`)
    -- CONSTRAINT `fk_inv_pr_department_id` FOREIGN KEY (`department_id`) REFERENCES `sch_department` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Purchase Requisition header; Draft→Submitted→Approved→Converted/Cancelled lifecycle';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_stock_adjustments` (
    `id`                BIGINT UNSIGNED                                     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `adjustment_number` VARCHAR(50)                                         NOT NULL                COMMENT 'Auto-generated reference e.g. ADJ-2026-001',
    `adjustment_date`   DATE                                                NOT NULL                COMMENT 'Physical count audit date',
    `godown_id`         BIGINT UNSIGNED                                     NOT NULL                COMMENT 'Godown being audited — inv_godowns.id',
    `reason`            VARCHAR(500)                                        NULL DEFAULT NULL        COMMENT 'Reason for adjustment',
    `status`            ENUM('draft','submitted','approved','rejected','posted') NOT NULL DEFAULT 'draft' COMMENT 'Adjustment workflow status',
    `approved_by`       BIGINT UNSIGNED                                     NULL DEFAULT NULL        COMMENT 'Approver — sys_users.id',
    `approved_at`       TIMESTAMP                                           NULL DEFAULT NULL        COMMENT 'Approval timestamp',
    -- Standard audit columns
    `is_active`         TINYINT(1)                                          NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`        BIGINT UNSIGNED                                     NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`        BIGINT UNSIGNED                                     NOT NULL                 COMMENT 'sys_users.id',
    `created_at`        TIMESTAMP                                           NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`        TIMESTAMP                                           NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`        TIMESTAMP                                           NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_sadj_number` (`adjustment_number`),
    KEY `idx_inv_sadj_godown_id`   (`godown_id`),
    KEY `idx_inv_sadj_status`      (`status`),
    KEY `idx_inv_sadj_approved_by` (`approved_by`),
    KEY `idx_inv_sadj_is_active`   (`is_active`),
    CONSTRAINT `fk_inv_sadj_godown_id` FOREIGN KEY (`godown_id`) REFERENCES `inv_godowns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Physical stock audit header; approval required above configurable value threshold (BR-INV-017)';

-- =============================================================================
-- LAYER 5 — Depends on Layer 4
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_rate_contract_items_jnt` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `rate_contract_id` BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent rate contract — inv_rate_contracts.id',
    `item_id`          BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `agreed_rate`      DECIMAL(15,2)    NOT NULL                COMMENT 'Fixed price per unit for this item in this contract',
    `min_qty`          DECIMAL(15,3)    NULL DEFAULT NULL        COMMENT 'Minimum order quantity',
    `max_qty`          DECIMAL(15,3)    NULL DEFAULT NULL        COMMENT 'Maximum order quantity',
    -- Standard audit columns
    `is_active`        TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`       BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`       BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`       TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`       TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`       TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_rcij_contract_item` (`rate_contract_id`, `item_id`),
    KEY `idx_inv_rcij_rate_contract_id` (`rate_contract_id`),
    KEY `idx_inv_rcij_item_id`          (`item_id`),
    CONSTRAINT `fk_inv_rcij_rate_contract_id` FOREIGN KEY (`rate_contract_id`) REFERENCES `inv_rate_contracts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_rcij_item_id`          FOREIGN KEY (`item_id`)          REFERENCES `inv_stock_items`    (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Rate contract line items — per-item agreed rates within a vendor contract';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_purchase_requisition_items` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `pr_id`                BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent PR — inv_purchase_requisitions.id',
    `item_id`              BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `qty`                  DECIMAL(15,3)    NOT NULL                COMMENT 'Requested quantity',
    `uom_id`               BIGINT UNSIGNED  NOT NULL                COMMENT 'Unit of measure — inv_units_of_measure.id',
    `estimated_rate`       DECIMAL(15,2)    NULL DEFAULT NULL        COMMENT 'Estimated unit price',
    `remarks`              VARCHAR(255)     NULL DEFAULT NULL        COMMENT 'Line-level notes',
    -- Standard audit columns
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`           BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`           BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`           TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`           TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`           TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_pri_pr_id`    (`pr_id`),
    KEY `idx_inv_pri_item_id`  (`item_id`),
    KEY `idx_inv_pri_uom_id`   (`uom_id`),
    CONSTRAINT `fk_inv_pri_pr_id`   FOREIGN KEY (`pr_id`)   REFERENCES `inv_purchase_requisitions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_pri_item_id` FOREIGN KEY (`item_id`) REFERENCES `inv_stock_items`           (`id`),
    CONSTRAINT `fk_inv_pri_uom_id`  FOREIGN KEY (`uom_id`)  REFERENCES `inv_units_of_measure`      (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='PR line items; cascade deleted with parent PR';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_quotations` (
    `id`            BIGINT UNSIGNED                              NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `rfq_number`    VARCHAR(50)                                  NOT NULL                COMMENT 'Auto-generated RFQ number e.g. RFQ-2026-001',
    `pr_id`         BIGINT UNSIGNED                              NULL DEFAULT NULL        COMMENT 'Source PR — inv_purchase_requisitions.id (nullable=RFQ without PR)',
    `vendor_id`     INT UNSIGNED                                 NOT NULL                COMMENT 'Quoting vendor — vnd_vendors.id (INT UNSIGNED)',
    `validity_date` DATE                                         NULL DEFAULT NULL        COMMENT 'Quote validity date',
    `status`        ENUM('draft','sent','received','expired','converted') NOT NULL DEFAULT 'draft' COMMENT 'RFQ lifecycle status',
    `notes`         TEXT                                         NULL DEFAULT NULL        COMMENT 'RFQ notes',
    -- Standard audit columns
    `is_active`     TINYINT(1)                                   NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`    BIGINT UNSIGNED                              NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`    BIGINT UNSIGNED                              NOT NULL                 COMMENT 'sys_users.id',
    `created_at`    TIMESTAMP                                    NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`    TIMESTAMP                                    NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`    TIMESTAMP                                    NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_quot_rfq_number` (`rfq_number`),
    KEY `idx_inv_quot_pr_id`      (`pr_id`),
    KEY `idx_inv_quot_vendor_id`  (`vendor_id`),
    KEY `idx_inv_quot_status`     (`status`),
    KEY `idx_inv_quot_is_active`  (`is_active`),
    CONSTRAINT `fk_inv_quot_pr_id` FOREIGN KEY (`pr_id`) REFERENCES `inv_purchase_requisitions` (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_quot_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='RFQ/Quotation header — one per vendor per PR; comparison matrix shows side-by-side rates';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_issue_requests` (
    `id`             BIGINT UNSIGNED                                        NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `request_number` VARCHAR(50)                                            NOT NULL                COMMENT 'Auto-generated number e.g. IR-2026-001',
    `requested_by`   BIGINT UNSIGNED                                        NOT NULL                COMMENT 'Requester — sys_users.id',
    `department_id`  INT UNSIGNED                                           NOT NULL                COMMENT 'Requesting department — sch_department.id (INT UNSIGNED)',
    `required_date`  DATE                                                   NOT NULL                COMMENT 'Required delivery date',
    `status`         ENUM('submitted','approved','issued','partial','rejected') NOT NULL DEFAULT 'submitted' COMMENT 'Issue request lifecycle status',
    `approved_by`    BIGINT UNSIGNED                                        NULL DEFAULT NULL        COMMENT 'Approver — sys_users.id',
    `remarks`        TEXT                                                   NULL DEFAULT NULL        COMMENT 'Notes or rejection reason',
    -- Standard audit columns
    `is_active`      TINYINT(1)                                             NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`     BIGINT UNSIGNED                                        NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`     BIGINT UNSIGNED                                        NOT NULL                 COMMENT 'sys_users.id',
    `created_at`     TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`     TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`     TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_ir_number` (`request_number`),
    KEY `idx_inv_ir_requested_by`  (`requested_by`),
    KEY `idx_inv_ir_department_id` (`department_id`),
    KEY `idx_inv_ir_status`        (`status`),
    KEY `idx_inv_ir_approved_by`   (`approved_by`),
    KEY `idx_inv_ir_is_active`     (`is_active`)
    -- CONSTRAINT `fk_inv_ir_department_id` FOREIGN KEY (`department_id`) REFERENCES `sch_department` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Stock issue request header; Submitted→Approved→Issued/Partial lifecycle';

-- =============================================================================
-- LAYER 6 — Depends on Layer 5
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_quotation_items` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `quotation_id`  BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent quotation — inv_quotations.id',
    `item_id`       BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `quoted_rate`   DECIMAL(15,2)    NOT NULL                COMMENT 'Vendor quoted price per unit',
    `lead_time_days` INT             NULL DEFAULT NULL        COMMENT 'Vendor lead time for this item',
    `remarks`       VARCHAR(255)     NULL DEFAULT NULL        COMMENT 'Line-level notes',
    -- Standard audit columns
    `is_active`     TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`    BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`    BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`    TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`    TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`    TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_qi_quotation_id` (`quotation_id`),
    KEY `idx_inv_qi_item_id`      (`item_id`),
    CONSTRAINT `fk_inv_qi_quotation_id` FOREIGN KEY (`quotation_id`) REFERENCES `inv_quotations`  (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_qi_item_id`      FOREIGN KEY (`item_id`)      REFERENCES `inv_stock_items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Quotation line items; cascade deleted with parent quotation';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_purchase_orders` (
    `id`                         BIGINT UNSIGNED                                        NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `po_number`                  VARCHAR(50)                                            NOT NULL                COMMENT 'Auto-generated PO number e.g. PO-2026-001',
    `vendor_id`                  INT UNSIGNED                                           NOT NULL                COMMENT 'Supplier — vnd_vendors.id (INT UNSIGNED)',
    `pr_id`                      BIGINT UNSIGNED                                        NULL DEFAULT NULL        COMMENT 'Source PR — inv_purchase_requisitions.id (NULL=direct PO)',
    `quotation_id`               BIGINT UNSIGNED                                        NULL DEFAULT NULL        COMMENT 'Source quotation — inv_quotations.id (NULL=no quotation step)',
    `order_date`                 DATE                                                   NOT NULL                COMMENT 'PO issue date',
    `expected_delivery_date`     DATE                                                   NULL DEFAULT NULL        COMMENT 'Expected goods delivery date',
    `status`                     ENUM('draft','sent','partial','received','cancelled','closed') NOT NULL DEFAULT 'draft' COMMENT 'PO lifecycle status',
    `total_amount`               DECIMAL(15,2)                                          NOT NULL DEFAULT 0       COMMENT 'Pre-tax subtotal',
    `tax_amount`                 DECIMAL(15,2)                                          NOT NULL DEFAULT 0       COMMENT 'GST total (CGST+SGST or IGST)',
    `discount_amount`            DECIMAL(15,2)                                          NOT NULL DEFAULT 0       COMMENT 'Total discount',
    `net_amount`                 DECIMAL(15,2)                                          NOT NULL DEFAULT 0       COMMENT 'Final payable amount',
    `approved_by`                BIGINT UNSIGNED                                        NULL DEFAULT NULL        COMMENT 'Approver — sys_users.id',
    `approval_threshold_amount`  DECIMAL(15,2)                                          NULL DEFAULT NULL        COMMENT 'School threshold captured at time of PO; compare against net_amount for BR-INV-016',
    `terms_and_conditions`       TEXT                                                   NULL DEFAULT NULL        COMMENT 'PO terms',
    -- Standard audit columns
    `is_active`                  TINYINT(1)                                             NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`                 BIGINT UNSIGNED                                        NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`                 BIGINT UNSIGNED                                        NOT NULL                 COMMENT 'sys_users.id',
    `created_at`                 TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`                 TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`                 TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_po_number` (`po_number`),
    KEY `idx_inv_po_vendor_id`    (`vendor_id`),
    KEY `idx_inv_po_pr_id`        (`pr_id`),
    KEY `idx_inv_po_quotation_id` (`quotation_id`),
    KEY `idx_inv_po_status`       (`status`),
    KEY `idx_inv_po_approved_by`  (`approved_by`),
    KEY `idx_inv_po_is_active`    (`is_active`),
    CONSTRAINT `fk_inv_po_pr_id`        FOREIGN KEY (`pr_id`)        REFERENCES `inv_purchase_requisitions` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_inv_po_quotation_id` FOREIGN KEY (`quotation_id`) REFERENCES `inv_quotations`            (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_po_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Purchase Order header; approval threshold enforcement per BR-INV-016; auto-closes when all items received';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_issue_request_items` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `issue_request_id` BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent issue request — inv_issue_requests.id',
    `item_id`          BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `requested_qty`    DECIMAL(15,3)    NOT NULL                COMMENT 'Requested quantity',
    `issued_qty`       DECIMAL(15,3)    NOT NULL DEFAULT 0      COMMENT 'Quantity issued so far; auto-updated by StockIssueService',
    `uom_id`           BIGINT UNSIGNED  NOT NULL                COMMENT 'Unit of measure — inv_units_of_measure.id',
    -- Standard audit columns
    `is_active`        TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`       BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`       BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`       TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`       TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`       TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_iri_issue_request_id` (`issue_request_id`),
    KEY `idx_inv_iri_item_id`          (`item_id`),
    KEY `idx_inv_iri_uom_id`           (`uom_id`),
    CONSTRAINT `fk_inv_iri_issue_request_id` FOREIGN KEY (`issue_request_id`) REFERENCES `inv_issue_requests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_iri_item_id`          FOREIGN KEY (`item_id`)          REFERENCES `inv_stock_items`    (`id`),
    CONSTRAINT `fk_inv_iri_uom_id`           FOREIGN KEY (`uom_id`)           REFERENCES `inv_units_of_measure` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Issue request line items; issued_qty auto-updated on partial/full execution';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_stock_adjustment_items` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `adjustment_id` BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent adjustment — inv_stock_adjustments.id',
    `item_id`       BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `system_qty`    DECIMAL(15,3)    NOT NULL                COMMENT 'System balance per inv_stock_balances at time of audit',
    `physical_qty`  DECIMAL(15,3)    NOT NULL                COMMENT 'Physically counted quantity',
    `variance_qty`  DECIMAL(15,3)    GENERATED ALWAYS AS (`physical_qty` - `system_qty`) STORED COMMENT 'Positive=surplus (inward entry), negative=deficit (outward entry); DO NOT INSERT/UPDATE',
    `unit_cost`     DECIMAL(15,2)    NOT NULL                COMMENT 'Valuation rate per unit at time of adjustment',
    -- Standard audit columns
    `is_active`     TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`    BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`    BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`    TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`    TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`    TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_sadji_adjustment_id` (`adjustment_id`),
    KEY `idx_inv_sadji_item_id`       (`item_id`),
    CONSTRAINT `fk_inv_sadji_adjustment_id` FOREIGN KEY (`adjustment_id`) REFERENCES `inv_stock_adjustments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_sadji_item_id`       FOREIGN KEY (`item_id`)       REFERENCES `inv_stock_items`       (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Stock adjustment line items; variance_qty is GENERATED ALWAYS (physical_qty - system_qty); never INSERT/UPDATE variance_qty';

-- =============================================================================
-- LAYER 7 — Depends on Layer 6
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_purchase_order_items` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `po_id`           BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent PO — inv_purchase_orders.id',
    `item_id`         BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `ordered_qty`     DECIMAL(15,3)    NOT NULL                COMMENT 'Ordered quantity',
    `received_qty`    DECIMAL(15,3)    NOT NULL DEFAULT 0      COMMENT 'Total received across all GRNs; auto-updated by GrnPostingService',
    `unit_price`      DECIMAL(15,2)    NOT NULL                COMMENT 'Agreed unit price',
    `tax_rate_id`     BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'GST rate — acc_tax_rates.id',
    `discount_percent` DECIMAL(5,2)   NOT NULL DEFAULT 0       COMMENT 'Line-level discount percentage',
    `total_amount`    DECIMAL(15,2)    NOT NULL                COMMENT 'Line total after tax and discount',
    -- Standard audit columns
    `is_active`       TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`      BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`      BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`      TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`      TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`      TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_poi_po_id`       (`po_id`),
    KEY `idx_inv_poi_item_id`     (`item_id`),
    KEY `idx_inv_poi_tax_rate_id` (`tax_rate_id`),
    CONSTRAINT `fk_inv_poi_po_id`   FOREIGN KEY (`po_id`)   REFERENCES `inv_purchase_orders` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_poi_item_id` FOREIGN KEY (`item_id`) REFERENCES `inv_stock_items`     (`id`)
    -- CONSTRAINT `fk_inv_poi_tax_rate_id` FOREIGN KEY (`tax_rate_id`) REFERENCES `acc_tax_rates` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='PO line items; received_qty auto-updated by GrnPostingService on GRN acceptance; triggers PO status auto-transition';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_goods_receipt_notes` (
    `id`           BIGINT UNSIGNED                                        NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `grn_number`   VARCHAR(50)                                            NOT NULL                COMMENT 'Auto-generated GRN number e.g. GRN-2026-001',
    `po_id`        BIGINT UNSIGNED                                        NOT NULL                COMMENT 'Source PO — inv_purchase_orders.id',
    `vendor_id`    INT UNSIGNED                                           NOT NULL                COMMENT 'Vendor — vnd_vendors.id (INT UNSIGNED)',
    `receipt_date` DATE                                                   NOT NULL                COMMENT 'Physical receipt date',
    `godown_id`    BIGINT UNSIGNED                                        NOT NULL                COMMENT 'Receiving godown — inv_godowns.id',
    `status`       ENUM('draft','inspected','accepted','partial','rejected') NOT NULL DEFAULT 'draft' COMMENT 'GRN lifecycle status',
    `qc_status`    ENUM('pending','passed','failed','partial')            NOT NULL DEFAULT 'pending' COMMENT 'QC inspection result',
    `qc_notes`     TEXT                                                   NULL DEFAULT NULL        COMMENT 'QC inspector notes',
    `received_by`  BIGINT UNSIGNED                                        NOT NULL                COMMENT 'Receiving employee — sys_users.id',
    `voucher_id`   BIGINT UNSIGNED                                        NULL DEFAULT NULL        COMMENT 'Accounting voucher — acc_vouchers.id; NULL until GRN accepted (D21)',
    -- Standard audit columns
    `is_active`    TINYINT(1)                                             NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`   BIGINT UNSIGNED                                        NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`   BIGINT UNSIGNED                                        NOT NULL                 COMMENT 'sys_users.id',
    `created_at`   TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`   TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`   TIMESTAMP                                              NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_grn_number` (`grn_number`),
    KEY `idx_inv_grn_po_id`      (`po_id`),
    KEY `idx_inv_grn_vendor_id`  (`vendor_id`),
    KEY `idx_inv_grn_godown_id`  (`godown_id`),
    KEY `idx_inv_grn_status`     (`status`),
    KEY `idx_inv_grn_received_by` (`received_by`),
    KEY `idx_inv_grn_voucher_id` (`voucher_id`),
    KEY `idx_inv_grn_is_active`  (`is_active`),
    CONSTRAINT `fk_inv_grn_po_id`     FOREIGN KEY (`po_id`)     REFERENCES `inv_purchase_orders` (`id`),
    CONSTRAINT `fk_inv_grn_godown_id` FOREIGN KEY (`godown_id`) REFERENCES `inv_godowns`         (`id`)
    -- CONSTRAINT `fk_inv_grn_vendor_id`  FOREIGN KEY (`vendor_id`)  REFERENCES `vnd_vendors`   (`id`)
    -- CONSTRAINT `fk_inv_grn_voucher_id` FOREIGN KEY (`voucher_id`) REFERENCES `acc_vouchers`  (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='GRN header; voucher_id set to NULL until GRN accepted and Accounting creates Purchase Voucher via GrnAccepted event';

-- =============================================================================
-- LAYER 8 — Depends on Layer 7
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_grn_items` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `grn_id`         BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent GRN — inv_goods_receipt_notes.id',
    `po_item_id`     BIGINT UNSIGNED  NOT NULL                COMMENT 'Source PO line — inv_purchase_order_items.id',
    `item_id`        BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `received_qty`   DECIMAL(15,3)    NOT NULL                COMMENT 'Total received quantity',
    `accepted_qty`   DECIMAL(15,3)    NOT NULL                COMMENT 'QC passed quantity; accepted_qty + rejected_qty = received_qty (BR-INV-006)',
    `rejected_qty`   DECIMAL(15,3)    NOT NULL DEFAULT 0      COMMENT 'QC failed quantity',
    `unit_cost`      DECIMAL(15,2)    NOT NULL                COMMENT 'Actual cost per unit from vendor invoice',
    `batch_number`   VARCHAR(50)      NULL DEFAULT NULL        COMMENT 'Batch number for batch-tracked items',
    `expiry_date`    DATE             NULL DEFAULT NULL        COMMENT 'Batch expiry date',
    `qc_remarks`     VARCHAR(255)     NULL DEFAULT NULL        COMMENT 'Per-line QC notes',
    -- Standard audit columns
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`     BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`     BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`     TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_grni_grn_id`     (`grn_id`),
    KEY `idx_inv_grni_po_item_id` (`po_item_id`),
    KEY `idx_inv_grni_item_id`    (`item_id`),
    CONSTRAINT `fk_inv_grni_grn_id`     FOREIGN KEY (`grn_id`)     REFERENCES `inv_goods_receipt_notes`  (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_grni_po_item_id` FOREIGN KEY (`po_item_id`) REFERENCES `inv_purchase_order_items` (`id`),
    CONSTRAINT `fk_inv_grni_item_id`    FOREIGN KEY (`item_id`)    REFERENCES `inv_stock_items`           (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='GRN line items; accepted_qty + rejected_qty must equal received_qty per line (BR-INV-006)';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_stock_issues` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `issue_number`            VARCHAR(50)      NOT NULL                COMMENT 'Auto-generated issue number e.g. SI-2026-001',
    `issue_request_id`        BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Source issue request — inv_issue_requests.id; NULL for direct issue',
    `godown_id`               BIGINT UNSIGNED  NOT NULL                COMMENT 'Source godown — inv_godowns.id',
    `issued_by`               BIGINT UNSIGNED  NOT NULL                COMMENT 'Store Keeper executing issue — sys_users.id',
    `issued_to_employee_id`   INT UNSIGNED     NULL DEFAULT NULL        COMMENT 'Receiving employee — sch_employees.id (INT UNSIGNED)',
    `department_id`           INT UNSIGNED     NOT NULL                COMMENT 'Receiving department — sch_department.id (INT UNSIGNED)',
    `issue_date`              DATE             NOT NULL                COMMENT 'Date of issue',
    `voucher_id`              BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Stock Journal voucher — acc_vouchers.id; NULL until Accounting processes StockIssued event',
    `acknowledged_by`         BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Receiver who acknowledged — sys_users.id',
    `acknowledged_at`         TIMESTAMP        NULL DEFAULT NULL        COMMENT 'Acknowledgment timestamp; mandatory for asset items',
    -- Standard audit columns
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`              BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`              BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`              TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`              TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`              TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_si_issue_number` (`issue_number`),
    KEY `idx_inv_si_issue_request_id`      (`issue_request_id`),
    KEY `idx_inv_si_godown_id`             (`godown_id`),
    KEY `idx_inv_si_issued_by`             (`issued_by`),
    KEY `idx_inv_si_issued_to_employee_id` (`issued_to_employee_id`),
    KEY `idx_inv_si_department_id`         (`department_id`),
    KEY `idx_inv_si_voucher_id`            (`voucher_id`),
    KEY `idx_inv_si_is_active`             (`is_active`),
    CONSTRAINT `fk_inv_si_issue_request_id` FOREIGN KEY (`issue_request_id`) REFERENCES `inv_issue_requests` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_inv_si_godown_id`        FOREIGN KEY (`godown_id`)         REFERENCES `inv_godowns`        (`id`)
    -- CONSTRAINT `fk_inv_si_issued_to_employee_id` FOREIGN KEY (`issued_to_employee_id`) REFERENCES `sch_employees`  (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_si_department_id`          FOREIGN KEY (`department_id`)         REFERENCES `sch_department` (`id`)
    -- CONSTRAINT `fk_inv_si_voucher_id`             FOREIGN KEY (`voucher_id`)            REFERENCES `acc_vouchers`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Stock issue execution; voucher_id set after Accounting creates Stock Journal via StockIssued event';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_stock_entries` (
    `id`                   BIGINT UNSIGNED                                                    NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `stock_item_id`        BIGINT UNSIGNED                                                    NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `godown_id`            BIGINT UNSIGNED                                                    NOT NULL                COMMENT 'Source or destination godown — inv_godowns.id',
    `voucher_id`           BIGINT UNSIGNED                                                    NOT NULL                COMMENT 'MANDATORY accounting voucher — acc_vouchers.id; no orphan entries (BR-INV-001)',
    `entry_type`           ENUM('inward','outward','transfer_in','transfer_out','adjustment') NOT NULL                COMMENT 'inward=GRN; outward=issue; transfer_in/out=godown transfer; adjustment=physical audit',
    `quantity`             DECIMAL(15,3)                                                      NOT NULL                COMMENT 'Movement quantity',
    `rate`                 DECIMAL(15,2)                                                      NOT NULL                COMMENT 'Valuation rate per unit',
    `amount`               DECIMAL(15,2)                                                      NOT NULL                COMMENT 'quantity × rate',
    `batch_number`         VARCHAR(50)                                                        NULL DEFAULT NULL        COMMENT 'Batch number (flows from GRN through to issue for FIFO)',
    `expiry_date`          DATE                                                               NULL DEFAULT NULL        COMMENT 'Batch expiry date',
    `destination_godown_id` BIGINT UNSIGNED                                                   NULL DEFAULT NULL        COMMENT 'Transfer destination — inv_godowns.id; only for transfer entries',
    `party_ledger_id`      BIGINT UNSIGNED                                                    NULL DEFAULT NULL        COMMENT 'Vendor/department ledger — acc_ledgers.id',
    `narration`            VARCHAR(500)                                                       NULL DEFAULT NULL        COMMENT 'Movement description',
    -- Standard audit columns
    `is_active`            TINYINT(1)                                                         NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`           BIGINT UNSIGNED                                                    NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`           BIGINT UNSIGNED                                                    NOT NULL                 COMMENT 'sys_users.id',
    `created_at`           TIMESTAMP                                                          NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`           TIMESTAMP                                                          NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`           TIMESTAMP                                                          NULL DEFAULT NULL         COMMENT 'Soft delete — ONLY via StockLedgerService guard; never direct (BR-INV-014)',
    PRIMARY KEY (`id`),
    KEY `idx_inv_sent_item_godown_date`    (`stock_item_id`, `godown_id`, `created_at`),
    KEY `idx_inv_sent_entry_type_date`     (`entry_type`, `created_at`),
    KEY `idx_inv_sent_voucher_id`          (`voucher_id`),
    KEY `idx_inv_sent_destination_godown`  (`destination_godown_id`),
    KEY `idx_inv_sent_party_ledger_id`     (`party_ledger_id`),
    CONSTRAINT `fk_inv_sent_stock_item_id`        FOREIGN KEY (`stock_item_id`)        REFERENCES `inv_stock_items` (`id`),
    CONSTRAINT `fk_inv_sent_godown_id`            FOREIGN KEY (`godown_id`)            REFERENCES `inv_godowns`     (`id`),
    CONSTRAINT `fk_inv_sent_destination_godown_id` FOREIGN KEY (`destination_godown_id`) REFERENCES `inv_godowns`   (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_sent_voucher_id`      FOREIGN KEY (`voucher_id`)      REFERENCES `acc_vouchers` (`id`) [UNCOMMENT after Accounting DDL applied — this is a NOT NULL FK]
    -- CONSTRAINT `fk_inv_sent_party_ledger_id` FOREIGN KEY (`party_ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IMMUTABLE stock movement journal; append-only; never UPDATE/DELETE after insert (BR-INV-014); voucher_id MANDATORY (BR-INV-001)';

-- =============================================================================
-- LAYER 9 — Depends on Layer 8
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_stock_issue_items` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `stock_issue_id`  BIGINT UNSIGNED  NOT NULL                COMMENT 'Parent stock issue — inv_stock_issues.id',
    `item_id`         BIGINT UNSIGNED  NOT NULL                COMMENT 'Stock item — inv_stock_items.id',
    `qty`             DECIMAL(15,3)    NOT NULL                COMMENT 'Issued quantity',
    `unit_cost`       DECIMAL(15,2)    NOT NULL                COMMENT 'Valuation cost per unit (from StockValuationService)',
    `batch_number`    VARCHAR(50)      NULL DEFAULT NULL        COMMENT 'FIFO batch number for batch-tracked items',
    -- Standard audit columns
    `is_active`       TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`      BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`      BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`      TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`      TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`      TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_sii_stock_issue_id` (`stock_issue_id`),
    KEY `idx_inv_sii_item_id`        (`item_id`),
    CONSTRAINT `fk_inv_sii_stock_issue_id` FOREIGN KEY (`stock_issue_id`) REFERENCES `inv_stock_issues` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_sii_item_id`        FOREIGN KEY (`item_id`)        REFERENCES `inv_stock_items`  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Stock issue execution line items; unit_cost from StockValuationService per item valuation method';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_assets` (
    `id`                    BIGINT UNSIGNED                               NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `asset_tag`             VARCHAR(50)                                   NOT NULL                COMMENT 'Auto-generated unique tag e.g. ASSET-2026-001',
    `asset_category_id`     BIGINT UNSIGNED                               NOT NULL                COMMENT 'Asset category — inv_asset_categories.id',
    `stock_item_id`         BIGINT UNSIGNED                               NOT NULL                COMMENT 'Parent item — inv_stock_items.id',
    `grn_item_id`           BIGINT UNSIGNED                               NULL DEFAULT NULL        COMMENT 'Source GRN item — inv_grn_items.id; NULL if not from GRN',
    `purchase_date`         DATE                                          NULL DEFAULT NULL        COMMENT 'Purchase date from GRN',
    `purchase_cost`         DECIMAL(15,2)                                 NULL DEFAULT NULL        COMMENT 'Purchase cost per unit',
    `current_book_value`    DECIMAL(15,2)                                 NULL DEFAULT NULL        COMMENT 'Current depreciated value — synced from acc_fixed_assets',
    `acc_fixed_asset_id`    BIGINT UNSIGNED                               NULL DEFAULT NULL        COMMENT 'Accounting fixed asset record — acc_fixed_assets.id; nullable, synced after Accounting creates it',
    `godown_id`             BIGINT UNSIGNED                               NULL DEFAULT NULL        COMMENT 'Current storage location — inv_godowns.id',
    `assigned_employee_id`  INT UNSIGNED                                  NULL DEFAULT NULL        COMMENT 'Currently assigned employee — sch_employees.id (INT UNSIGNED)',
    `condition`             ENUM('good','fair','poor','under_repair','disposed') NOT NULL DEFAULT 'good' COMMENT 'Current condition; disposed=after AssetDisposed event',
    `warranty_expiry_date`  DATE                                          NULL DEFAULT NULL        COMMENT 'Warranty expiry date',
    -- Standard audit columns
    `is_active`             TINYINT(1)                                    NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`            BIGINT UNSIGNED                               NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`            BIGINT UNSIGNED                               NOT NULL                 COMMENT 'sys_users.id',
    `created_at`            TIMESTAMP                                     NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`            TIMESTAMP                                     NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`            TIMESTAMP                                     NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_inv_asset_tag` (`asset_tag`),
    KEY `idx_inv_ast_asset_category_id`    (`asset_category_id`),
    KEY `idx_inv_ast_stock_item_id`        (`stock_item_id`),
    KEY `idx_inv_ast_grn_item_id`          (`grn_item_id`),
    KEY `idx_inv_ast_acc_fixed_asset_id`   (`acc_fixed_asset_id`),
    KEY `idx_inv_ast_godown_id`            (`godown_id`),
    KEY `idx_inv_ast_assigned_employee_id` (`assigned_employee_id`),
    KEY `idx_inv_ast_condition`            (`condition`),
    KEY `idx_inv_ast_is_active`            (`is_active`),
    CONSTRAINT `fk_inv_ast_asset_category_id` FOREIGN KEY (`asset_category_id`) REFERENCES `inv_asset_categories` (`id`),
    CONSTRAINT `fk_inv_ast_stock_item_id`      FOREIGN KEY (`stock_item_id`)     REFERENCES `inv_stock_items`      (`id`),
    CONSTRAINT `fk_inv_ast_grn_item_id`        FOREIGN KEY (`grn_item_id`)       REFERENCES `inv_grn_items`        (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_inv_ast_godown_id`          FOREIGN KEY (`godown_id`)         REFERENCES `inv_godowns`          (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_ast_acc_fixed_asset_id`   FOREIGN KEY (`acc_fixed_asset_id`)   REFERENCES `acc_fixed_assets` (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_ast_assigned_employee_id` FOREIGN KEY (`assigned_employee_id`) REFERENCES `sch_employees`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fixed asset register; one record per physical unit; auto-created on GRN acceptance for item_type=asset (BR-INV-012)';

-- =============================================================================
-- LAYER 10 — Depends on Layer 9
-- =============================================================================

CREATE TABLE IF NOT EXISTS `inv_asset_movements` (
    `id`                 BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `asset_id`           BIGINT UNSIGNED  NOT NULL                COMMENT 'Asset being transferred — inv_assets.id',
    `movement_date`      DATE             NOT NULL                COMMENT 'Date of transfer',
    `from_godown_id`     BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'Previous storage location — inv_godowns.id',
    `to_godown_id`       BIGINT UNSIGNED  NULL DEFAULT NULL        COMMENT 'New storage location — inv_godowns.id',
    `from_employee_id`   INT UNSIGNED     NULL DEFAULT NULL        COMMENT 'Previous assignee — sch_employees.id (INT UNSIGNED)',
    `to_employee_id`     INT UNSIGNED     NULL DEFAULT NULL        COMMENT 'New assignee — sch_employees.id (INT UNSIGNED)',
    `reason`             VARCHAR(500)     NULL DEFAULT NULL        COMMENT 'Transfer reason',
    `moved_by`           BIGINT UNSIGNED  NOT NULL                COMMENT 'User who executed transfer — sys_users.id',
    -- Standard audit columns
    `is_active`          TINYINT(1)       NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`         BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`         BIGINT UNSIGNED  NOT NULL                 COMMENT 'sys_users.id',
    `created_at`         TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`         TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`         TIMESTAMP        NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_amov_asset_id`          (`asset_id`),
    KEY `idx_inv_amov_from_godown_id`    (`from_godown_id`),
    KEY `idx_inv_amov_to_godown_id`      (`to_godown_id`),
    KEY `idx_inv_amov_from_employee_id`  (`from_employee_id`),
    KEY `idx_inv_amov_to_employee_id`    (`to_employee_id`),
    KEY `idx_inv_amov_moved_by`          (`moved_by`),
    KEY `idx_inv_amov_movement_date`     (`movement_date`),
    CONSTRAINT `fk_inv_amov_asset_id`       FOREIGN KEY (`asset_id`)       REFERENCES `inv_assets`  (`id`),
    CONSTRAINT `fk_inv_amov_from_godown_id` FOREIGN KEY (`from_godown_id`) REFERENCES `inv_godowns` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_inv_amov_to_godown_id`   FOREIGN KEY (`to_godown_id`)   REFERENCES `inv_godowns` (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_amov_from_employee_id` FOREIGN KEY (`from_employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE SET NULL
    -- CONSTRAINT `fk_inv_amov_to_employee_id`   FOREIGN KEY (`to_employee_id`)   REFERENCES `sch_employees` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Asset transfer history — every change of location or assigned employee is recorded here';

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `inv_asset_maintenance` (
    `id`               BIGINT UNSIGNED                                    NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `asset_id`         BIGINT UNSIGNED                                    NOT NULL                COMMENT 'Asset being maintained — inv_assets.id',
    `maintenance_date` DATE                                               NOT NULL                COMMENT 'Scheduled or actual maintenance date',
    `maintenance_type` ENUM('preventive','corrective','amc','calibration') NOT NULL               COMMENT 'preventive=scheduled; corrective=breakdown; amc=annual contract; calibration=measurement',
    `vendor_id`        INT UNSIGNED                                       NULL DEFAULT NULL        COMMENT 'AMC/service vendor — vnd_vendors.id (INT UNSIGNED)',
    `cost`             DECIMAL(15,2)                                      NULL DEFAULT NULL        COMMENT 'Maintenance cost',
    `notes`            TEXT                                               NULL DEFAULT NULL        COMMENT 'Maintenance notes',
    `next_due_date`    DATE                                               NULL DEFAULT NULL        COMMENT 'Next scheduled maintenance date; overdue alert fired when this passes',
    `status`           ENUM('scheduled','completed','overdue')            NOT NULL DEFAULT 'scheduled' COMMENT 'scheduled=upcoming; completed=done; overdue=past next_due_date without completion',
    -- Standard audit columns
    `is_active`        TINYINT(1)                                         NOT NULL DEFAULT 1       COMMENT 'Soft enable/disable',
    `created_by`       BIGINT UNSIGNED                                    NOT NULL                 COMMENT 'sys_users.id',
    `updated_by`       BIGINT UNSIGNED                                    NOT NULL                 COMMENT 'sys_users.id',
    `created_at`       TIMESTAMP                                          NULL DEFAULT NULL         COMMENT 'Record creation time',
    `updated_at`       TIMESTAMP                                          NULL DEFAULT NULL         COMMENT 'Last update time',
    `deleted_at`       TIMESTAMP                                          NULL DEFAULT NULL         COMMENT 'Soft delete timestamp',
    PRIMARY KEY (`id`),
    KEY `idx_inv_amnt_asset_id`      (`asset_id`),
    KEY `idx_inv_amnt_vendor_id`     (`vendor_id`),
    KEY `idx_inv_amnt_status`        (`status`),
    KEY `idx_inv_amnt_next_due_date` (`next_due_date`),
    KEY `idx_inv_amnt_maint_date`    (`maintenance_date`),
    CONSTRAINT `fk_inv_amnt_asset_id` FOREIGN KEY (`asset_id`) REFERENCES `inv_assets` (`id`)
    -- CONSTRAINT `fk_inv_amnt_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Asset maintenance log; overdue alert via inventory:maintenance-overdue Artisan command when next_due_date passes';

-- =============================================================================
SET FOREIGN_KEY_CHECKS = 1;
-- =============================================================================
-- END OF INV DDL — 28 tables created
-- Table count: 2 (L1) + 2 (L2) + 2 (L3) + 5 (L4) + 4 (L5) + 4 (L6) + 2 (L7) + 3 (L8) + 2 (L9) + 2 (L10) = 28 ✓
-- =============================================================================
