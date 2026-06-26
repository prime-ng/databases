# INV — Inventory Module Feature Specification
**Version:** 1.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (BA + DB Architect)
**Based on:** INV_Inventory_Requirement.md v2  |  **Status:** Phase 1 Output (Ready for Review)

---

## Table of Contents

1. [Module Identity & Scope](#1-module-identity--scope)
2. [Entity Inventory — All 28 Tables](#2-entity-inventory--all-28-tables)
3. [Entity Relationship Diagram](#3-entity-relationship-diagram)
4. [Business Rules](#4-business-rules)
5. [Workflow State Machines](#5-workflow-state-machines)
6. [Functional Requirements Summary](#6-functional-requirements-summary)
7. [Permission Matrix](#7-permission-matrix)
8. [Service Architecture](#8-service-architecture)
9. [Integration Contracts](#9-integration-contracts)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Test Plan Outline](#11-test-plan-outline)

---

## 1. Module Identity & Scope

| Attribute | Value |
|---|---|
| **Module Code** | INV |
| **Module Name** | Inventory |
| **Namespace** | `Modules\Inventory` |
| **Module Type** | Tenant (per-school) |
| **Database** | `tenant_db` — one DB per school, no `tenant_id` columns |
| **Table Prefix** | `inv_*` |
| **Route Prefix** | `inventory/` |
| **Route Name Prefix** | `inventory.` |
| **RBS Code** | L (Inventory & Assets, RBS v4.0) |
| **Implementation Status** | ❌ 0% — Greenfield |

### 1.1 In-Scope Sub-Modules

| Code | Sub-Module | Description |
|---|---|---|
| L1 | Item & Category Master | Stock groups, item catalog, UOM, godowns, opening balances |
| L2 | Stock Management | Stock entry ledger, denormalized balance, running valuation |
| L3 | Purchase Orders | PR → Quotation → PO → GRN full procurement workflow |
| L4 | Vendor Linkage | Item-vendor assignment, rate contracts, last purchase tracking |
| L5 | Asset Tracking | Asset register, movements, maintenance scheduling, disposal |
| L6 | Procurement Workflow & Quotations | RFQ to multiple vendors, comparison matrix, convert to PO |
| — | Stock Issue | Issue Request → Approval → Issue → Acknowledgment |
| — | Reorder Automation | Threshold alerts, auto-PR, barcode/QR labels, 12 reports |

### 1.2 Out-of-Scope

- Library books — tracked in `lib_*` (Library module owns book stock)
- Transport fuel and vehicle parts — tracked in `tpt_*` (Transport module)
- Depreciation computation — delegated to Accounting module (`acc_fixed_assets`)
- Vendor master CRUD — owned by Vendor module (`vnd_vendors`)

### 1.3 Module Scale

| Artifact | Count | Source |
|---|---|---|
| Controllers | 18 | Section 15 file list (overrides Section 1.1 which says 14) |
| Models | 28 | One per table |
| Services | 7 | See Section 8 |
| FormRequests | 13 | Per req spec Section 1.1 |
| Policies | 13 | Per req spec Section 1.1 |
| `inv_*` Tables | **28** | Section 5 actual count (overrides Section 1.1 which says 21) |
| Blade Views | ~65 | Per UI screen inventory |
| Seeders | 4 + 1 runner | InvUomSeeder, InvStockGroupSeeder, InvGodownSeeder, InvAssetCategorySeeder |

> **Note:** Section 1.1 says 21 tables but the actual data model (Section 5) defines 28. V2 added 7 new tables: `inv_stock_balances`, `inv_stock_adjustments`, `inv_stock_adjustment_items`, `inv_asset_categories`, `inv_assets`, `inv_asset_movements`, `inv_asset_maintenance`. Use 28.

---

## 2. Entity Inventory — All 28 Tables

> **Standard Audit Columns on ALL tables:**
> `id BIGINT UNSIGNED PK AUTO_INCREMENT`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NOT NULL` (→ sys_users), `updated_by BIGINT UNSIGNED NOT NULL` (→ sys_users), `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL`
>
> **FK Type Note (verified against tenant_db_v2.sql):**
> - `vnd_vendors.id`, `sch_employees.id`, `sch_department.id` use `INT UNSIGNED` — FKs referencing these MUST use `INT UNSIGNED`
> - `acc_ledgers.id`, `acc_tax_rates.id`, `acc_fixed_assets.id` use `BIGINT UNSIGNED`
> - `acc_vouchers` table NOT yet in tenant_db_v2.sql — it is an Accounting module dependency (Decision D21); FK defined but migration must run after Accounting DDL is applied

---

### MASTERS (6 Tables)

#### 2.1 `inv_stock_groups`
*Hierarchical stock category tree. Self-referencing. Seeded with 10 system groups.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| name | VARCHAR(100) | No | — | NOT NULL | Stock group display name |
| code | VARCHAR(20) | Yes | NULL | UNIQUE | Short group code (optional) |
| alias | VARCHAR(100) | Yes | NULL | — | Alternative name |
| parent_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_stock_groups | Self-referencing hierarchy |
| default_uom_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_units_of_measure | Default UOM for items |
| sequence | INT | No | 0 | — | Display order |
| is_system | TINYINT(1) | No | 0 | — | 1 = seeded, cannot delete |
| *+ standard audit cols* | | | | | |

**Unique:** `code`
**Indexes:** `parent_id`, `default_uom_id`, `is_active`

---

#### 2.2 `inv_units_of_measure`
*UOM master. Seeded with 10 system UOMs. Used across items, PR, PO, GRN, issues.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| name | VARCHAR(50) | No | — | NOT NULL | e.g., "Pieces" |
| symbol | VARCHAR(10) | No | — | NOT NULL | e.g., "Pcs" |
| decimal_places | TINYINT | No | 0 | — | 0–4 precision |
| is_system | TINYINT(1) | No | 0 | — | 1 = seeded, cannot delete |
| *+ standard audit cols* | | | | | |

**Indexes:** `is_active`

---

#### 2.3 `inv_uom_conversions`
*Defines conversion factors between UOM pairs. Bidirectional (1 Box = 10 Pcs; reverse = 1 Pcs = 0.1 Box).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| from_uom_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_units_of_measure | Source UOM |
| to_uom_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_units_of_measure | Target UOM |
| conversion_factor | DECIMAL(15,6) | No | — | NOT NULL | 1 from_uom = X to_uom |
| effective_from | DATE | Yes | NULL | — | Optional validity start |
| effective_to | DATE | Yes | NULL | — | Optional validity end |
| *+ standard audit cols* | | | | | |

**Unique:** `(from_uom_id, to_uom_id)`
**Indexes:** `from_uom_id`, `to_uom_id`

---

#### 2.4 `inv_stock_items`
*Item catalog. Every procurable/issuable item. Accounting ledger and tax rate linkage for GST.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| name | VARCHAR(150) | No | — | NOT NULL | Item name |
| sku | VARCHAR(50) | Yes | NULL | UNIQUE | Stock keeping unit code |
| alias | VARCHAR(150) | Yes | NULL | — | Alternative name |
| stock_group_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_groups | Category |
| uom_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_units_of_measure | Primary UOM |
| item_type | ENUM('consumable','asset') | No | 'consumable' | — | Asset type triggers acc_fixed_assets on GRN |
| opening_balance_qty | DECIMAL(15,3) | No | 0 | — | Tenant onboarding |
| opening_balance_rate | DECIMAL(15,2) | No | 0 | — | |
| opening_balance_value | DECIMAL(15,2) | No | 0 | — | |
| valuation_method | ENUM('fifo','weighted_average','last_purchase') | No | 'weighted_average' | — | Per-item stock valuation method |
| reorder_level | DECIMAL(15,3) | Yes | NULL | — | Alert threshold qty |
| reorder_qty | DECIMAL(15,3) | Yes | NULL | — | Auto-reorder quantity |
| min_stock | DECIMAL(15,3) | Yes | NULL | — | Minimum stock level |
| max_stock | DECIMAL(15,3) | Yes | NULL | — | Maximum stock level |
| auto_reorder_pr | TINYINT(1) | No | 0 | — | Auto-create PR on reorder |
| has_batch_tracking | TINYINT(1) | No | 0 | — | Enable batch number tracking |
| has_expiry_tracking | TINYINT(1) | No | 0 | — | Enable expiry date tracking |
| hsn_sac_code | VARCHAR(20) | Yes | NULL | — | GST classification code |
| brand | VARCHAR(100) | Yes | NULL | — | Brand name |
| model | VARCHAR(100) | Yes | NULL | — | Model number |
| warranty_months | INT | Yes | NULL | — | Warranty duration (for assets) |
| tax_rate_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_tax_rates | GST rate |
| purchase_ledger_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_ledgers | Stock-in-hand ledger |
| sales_ledger_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_ledgers | Sales/issue ledger |
| *+ standard audit cols* | | | | | |

**Unique:** `sku` (nullable, allows multiple NULLs)
**Indexes:** `stock_group_id`, `uom_id`, `tax_rate_id`, `purchase_ledger_id`, `sales_ledger_id`, `item_type`, `is_active`

---

#### 2.5 `inv_godowns`
*Storage locations (warehouses/storerooms). Self-referencing hierarchy. Seeded with 5 system godowns.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| name | VARCHAR(100) | No | — | NOT NULL | e.g., "Main Store" |
| code | VARCHAR(20) | Yes | NULL | UNIQUE | Short code |
| parent_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_godowns | Sub-godown parent |
| address | VARCHAR(500) | Yes | NULL | — | Physical address |
| in_charge_employee_id | INT UNSIGNED | Yes | NULL | FK → sch_employees | **INT UNSIGNED** to match sch_employees.id |
| is_system | TINYINT(1) | No | 0 | — | 1 = seeded, cannot delete |
| *+ standard audit cols* | | | | | |

**Unique:** `code` (nullable)
**Indexes:** `parent_id`, `in_charge_employee_id`, `is_active`

---

#### 2.6 `inv_asset_categories`
*Asset category master with depreciation rates per Income Tax Act (WDV method).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| name | VARCHAR(100) | No | — | NOT NULL | e.g., "IT Equipment" |
| code | VARCHAR(20) | Yes | NULL | UNIQUE | Short code |
| depreciation_rate | DECIMAL(5,2) | Yes | NULL | — | % per annum WDV |
| useful_life_years | INT | Yes | NULL | — | Income Tax Act basis |
| *+ standard audit cols* | | | | | |

**Unique:** `code` (nullable)
**Indexes:** `is_active`

---

### STOCK LEDGER (2 Tables)

#### 2.7 `inv_stock_balances`
*Denormalized running balance — one row per (item, godown). Updated atomically with every stock entry. Replaces expensive SUM queries at scale.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| stock_item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| godown_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_godowns | |
| current_qty | DECIMAL(15,3) | No | 0 | — | Running stock quantity |
| current_value | DECIMAL(15,2) | No | 0 | — | Running stock valuation |
| last_entry_at | TIMESTAMP | Yes | NULL | — | Timestamp of last movement |
| *+ standard audit cols* | | | | | |

**Unique:** `(stock_item_id, godown_id)`
**Indexes:** `(stock_item_id, godown_id)` — composite for O(1) balance lookup, `is_active`
**Concurrency:** `lockForUpdate()` row-level lock in StockLedgerService prevents race conditions

---

#### 2.8 `inv_stock_entries`
*Immutable central journal of all stock movements. Append-only — never UPDATE/DELETE after insert.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| stock_item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| godown_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_godowns | Source/destination godown |
| voucher_id | BIGINT UNSIGNED | No | — | **NOT NULL** FK → acc_vouchers | Mandatory — no orphan entries |
| entry_type | ENUM('inward','outward','transfer_in','transfer_out','adjustment') | No | — | NOT NULL | Movement type |
| quantity | DECIMAL(15,3) | No | — | NOT NULL | Movement quantity |
| rate | DECIMAL(15,2) | No | — | NOT NULL | Valuation rate per unit |
| amount | DECIMAL(15,2) | No | — | NOT NULL | quantity × rate |
| batch_number | VARCHAR(50) | Yes | NULL | — | Batch tracking (FIFO) |
| expiry_date | DATE | Yes | NULL | — | Batch expiry |
| destination_godown_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_godowns | Transfers only |
| party_ledger_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_ledgers | Vendor/dept ledger |
| narration | VARCHAR(500) | Yes | NULL | — | Movement description |
| *+ standard audit cols* | | | | | |

**Indexes:** `(stock_item_id, godown_id, created_at)`, `(entry_type, created_at)`, `voucher_id`, `destination_godown_id`, `party_ledger_id`
**⚠ CRITICAL:** `voucher_id` is `NOT NULL` — acc_vouchers dependency must be satisfied before any stock entry can be created

---

### VENDOR LINKAGE (3 Tables)

#### 2.9 `inv_item_vendor_jnt`
*Item-to-vendor assignment. Multiple vendors per item; one preferred.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| vendor_id | INT UNSIGNED | No | — | NOT NULL FK → vnd_vendors | **INT UNSIGNED** to match vnd_vendors.id |
| vendor_sku | VARCHAR(50) | Yes | NULL | — | Vendor's item code |
| last_purchase_rate | DECIMAL(15,2) | Yes | NULL | — | Auto-updated on GRN |
| last_purchase_date | DATE | Yes | NULL | — | Auto-updated on GRN |
| lead_time_days | INT | Yes | NULL | — | Delivery lead time |
| is_preferred | TINYINT(1) | No | 0 | — | 1 = preferred vendor |
| *+ standard audit cols* | | | | | |

**Unique:** `(item_id, vendor_id)`
**Indexes:** `item_id`, `vendor_id`, `is_active`

---

#### 2.10 `inv_rate_contracts`
*Vendor-level rate contracts with validity periods and expiry alerts (30 days before expiry).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| vendor_id | INT UNSIGNED | No | — | NOT NULL FK → vnd_vendors | **INT UNSIGNED** |
| contract_number | VARCHAR(50) | Yes | NULL | UNIQUE | e.g., "RC-2026-001" |
| valid_from | DATE | No | — | NOT NULL | Contract start date |
| valid_to | DATE | No | — | NOT NULL | Contract end date |
| status | ENUM('draft','active','expired','cancelled') | No | 'draft' | — | |
| remarks | TEXT | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `contract_number` (nullable)
**Indexes:** `vendor_id`, `status`, `valid_to`, `is_active`

---

#### 2.11 `inv_rate_contract_items_jnt`
*Per-item agreed rates within a rate contract.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| rate_contract_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_rate_contracts ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| agreed_rate | DECIMAL(15,2) | No | — | NOT NULL | Fixed price per unit |
| min_qty | DECIMAL(15,3) | Yes | NULL | — | Minimum order quantity |
| max_qty | DECIMAL(15,3) | Yes | NULL | — | Maximum order quantity |
| *+ standard audit cols* | | | | | |

**Unique:** `(rate_contract_id, item_id)`
**Indexes:** `rate_contract_id`, `item_id`

---

### PROCUREMENT (8 Tables)

#### 2.12 `inv_purchase_requisitions`
*PR header. Auto-generated PR number. Department-based request with approval workflow.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| pr_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "PR-2026-001" |
| requested_by | BIGINT UNSIGNED | No | — | NOT NULL FK → sys_users | |
| department_id | INT UNSIGNED | Yes | NULL | FK → sch_department | **INT UNSIGNED** (singular table) |
| required_date | DATE | No | — | NOT NULL | |
| priority | ENUM('low','normal','high','urgent') | No | 'normal' | — | |
| status | ENUM('draft','submitted','approved','rejected','converted','cancelled') | No | 'draft' | — | |
| approved_by | BIGINT UNSIGNED | Yes | NULL | FK → sys_users | |
| approved_at | TIMESTAMP | Yes | NULL | — | |
| remarks | TEXT | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `pr_number`
**Indexes:** `requested_by`, `department_id`, `status`, `approved_by`, `is_active`

---

#### 2.13 `inv_purchase_requisition_items`
*PR line items. Cascade delete when PR is deleted.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| pr_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_purchase_requisitions ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| qty | DECIMAL(15,3) | No | — | NOT NULL | Requested quantity |
| uom_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_units_of_measure | |
| estimated_rate | DECIMAL(15,2) | Yes | NULL | — | |
| remarks | VARCHAR(255) | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Indexes:** `pr_id`, `item_id`, `uom_id`

---

#### 2.14 `inv_quotations`
*RFQ/Quotation header. One quotation per vendor per PR. V2 addition.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| rfq_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "RFQ-2026-001" |
| pr_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_purchase_requisitions | Source PR |
| vendor_id | INT UNSIGNED | No | — | NOT NULL FK → vnd_vendors | **INT UNSIGNED** |
| validity_date | DATE | Yes | NULL | — | Quote valid until |
| status | ENUM('draft','sent','received','expired','converted') | No | 'draft' | — | |
| notes | TEXT | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `rfq_number`
**Indexes:** `pr_id`, `vendor_id`, `status`, `is_active`

---

#### 2.15 `inv_quotation_items`
*Quotation line items. Cascade delete when quotation is deleted.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| quotation_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_quotations ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| quoted_rate | DECIMAL(15,2) | No | — | NOT NULL | Vendor's quoted price |
| lead_time_days | INT | Yes | NULL | — | |
| remarks | VARCHAR(255) | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Indexes:** `quotation_id`, `item_id`

---

#### 2.16 `inv_purchase_orders`
*PO header. Can originate from PR or direct. Approval threshold enforcement.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| po_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "PO-2026-001" |
| vendor_id | INT UNSIGNED | No | — | NOT NULL FK → vnd_vendors | **INT UNSIGNED** |
| pr_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_purchase_requisitions | Source PR (nullable = direct PO) |
| quotation_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_quotations | Source quotation (nullable) |
| order_date | DATE | No | — | NOT NULL | |
| expected_delivery_date | DATE | Yes | NULL | — | |
| status | ENUM('draft','sent','partial','received','cancelled','closed') | No | 'draft' | — | |
| total_amount | DECIMAL(15,2) | No | 0 | — | Pre-tax total |
| tax_amount | DECIMAL(15,2) | No | 0 | — | GST total |
| discount_amount | DECIMAL(15,2) | No | 0 | — | Total discount |
| net_amount | DECIMAL(15,2) | No | 0 | — | Final payable amount |
| approved_by | BIGINT UNSIGNED | Yes | NULL | FK → sys_users | |
| approval_threshold_amount | DECIMAL(15,2) | Yes | NULL | — | Captured at PO creation |
| terms_and_conditions | TEXT | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `po_number`
**Indexes:** `vendor_id`, `pr_id`, `quotation_id`, `status`, `approved_by`, `is_active`

---

#### 2.17 `inv_purchase_order_items`
*PO line items. `received_qty` auto-updated by GrnPostingService on each GRN acceptance.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| po_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_purchase_orders ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| ordered_qty | DECIMAL(15,3) | No | — | NOT NULL | |
| received_qty | DECIMAL(15,3) | No | 0 | — | Auto-updated on GRN; NOT user-entered |
| unit_price | DECIMAL(15,2) | No | — | NOT NULL | |
| tax_rate_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_tax_rates | GST rate |
| discount_percent | DECIMAL(5,2) | No | 0 | — | |
| total_amount | DECIMAL(15,2) | No | — | NOT NULL | Line total after tax |
| *+ standard audit cols* | | | | | |

**Indexes:** `po_id`, `item_id`, `tax_rate_id`

---

#### 2.18 `inv_goods_receipt_notes`
*GRN header. `voucher_id` is NULL until GRN accepted; set by GrnPostingService via Accounting event.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| grn_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "GRN-2026-001" |
| po_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_purchase_orders | |
| vendor_id | INT UNSIGNED | No | — | NOT NULL FK → vnd_vendors | **INT UNSIGNED** |
| receipt_date | DATE | No | — | NOT NULL | |
| godown_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_godowns | Receiving location |
| status | ENUM('draft','inspected','accepted','partial','rejected') | No | 'draft' | — | |
| qc_status | ENUM('pending','passed','failed','partial') | No | 'pending' | — | |
| qc_notes | TEXT | Yes | NULL | — | QC inspector notes |
| received_by | BIGINT UNSIGNED | No | — | NOT NULL FK → sys_users | |
| voucher_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_vouchers | **NULL** until GRN accepted |
| *+ standard audit cols* | | | | | |

**Unique:** `grn_number`
**Indexes:** `po_id`, `vendor_id`, `godown_id`, `status`, `received_by`, `voucher_id`, `is_active`

---

#### 2.19 `inv_grn_items`
*GRN line items. QC quantities per line: accepted_qty + rejected_qty = received_qty.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| grn_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_goods_receipt_notes ON DELETE CASCADE | |
| po_item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_purchase_order_items | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| received_qty | DECIMAL(15,3) | No | — | NOT NULL | Total received |
| accepted_qty | DECIMAL(15,3) | No | — | NOT NULL | QC passed |
| rejected_qty | DECIMAL(15,3) | No | 0 | — | QC failed |
| unit_cost | DECIMAL(15,2) | No | — | NOT NULL | Actual cost per unit |
| batch_number | VARCHAR(50) | Yes | NULL | — | For batch-tracked items |
| expiry_date | DATE | Yes | NULL | — | Batch expiry |
| qc_remarks | VARCHAR(255) | Yes | NULL | — | Per-line QC notes |
| *+ standard audit cols* | | | | | |

**Indexes:** `grn_id`, `po_item_id`, `item_id`

---

### STOCK ISSUE (4 Tables)

#### 2.20 `inv_issue_requests`
*Issue request header. Submitted by department staff; approved by store manager or HOD.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| request_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "IR-2026-001" |
| requested_by | BIGINT UNSIGNED | No | — | NOT NULL FK → sys_users | |
| department_id | INT UNSIGNED | No | — | NOT NULL FK → sch_department | **INT UNSIGNED** (singular) |
| required_date | DATE | No | — | NOT NULL | |
| status | ENUM('submitted','approved','issued','partial','rejected') | No | 'submitted' | — | |
| approved_by | BIGINT UNSIGNED | Yes | NULL | FK → sys_users | |
| remarks | TEXT | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `request_number`
**Indexes:** `requested_by`, `department_id`, `status`, `approved_by`, `is_active`

---

#### 2.21 `inv_issue_request_items`
*Issue request line items. `issued_qty` auto-updated as stock is issued (partial support).*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| issue_request_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_issue_requests ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| requested_qty | DECIMAL(15,3) | No | — | NOT NULL | |
| issued_qty | DECIMAL(15,3) | No | 0 | — | Updated as issued; NOT user-entered |
| uom_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_units_of_measure | |
| *+ standard audit cols* | | | | | |

**Indexes:** `issue_request_id`, `item_id`, `uom_id`

---

#### 2.22 `inv_stock_issues`
*Stock issue execution. `voucher_id` set after Accounting creates Stock Journal. Supports direct issue.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| issue_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "SI-2026-001" |
| issue_request_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_issue_requests | NULL for direct issue |
| godown_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_godowns | Source godown |
| issued_by | BIGINT UNSIGNED | No | — | NOT NULL FK → sys_users | Store Keeper |
| issued_to_employee_id | INT UNSIGNED | Yes | NULL | FK → sch_employees | **INT UNSIGNED** |
| department_id | INT UNSIGNED | No | — | NOT NULL FK → sch_department | **INT UNSIGNED** |
| issue_date | DATE | No | — | NOT NULL | |
| voucher_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_vouchers | NULL until Stock Journal created |
| acknowledged_by | BIGINT UNSIGNED | Yes | NULL | FK → sys_users | |
| acknowledged_at | TIMESTAMP | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `issue_number`
**Indexes:** `issue_request_id`, `godown_id`, `issued_by`, `issued_to_employee_id`, `department_id`, `voucher_id`, `is_active`

---

#### 2.23 `inv_stock_issue_items`
*Stock issue execution line items. Unit cost determined by StockValuationService.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| stock_issue_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_issues ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| qty | DECIMAL(15,3) | No | — | NOT NULL | Issued quantity |
| unit_cost | DECIMAL(15,2) | No | — | NOT NULL | Valuation cost (from StockValuationService) |
| batch_number | VARCHAR(50) | Yes | NULL | — | FIFO batch number |
| *+ standard audit cols* | | | | | |

**Indexes:** `stock_issue_id`, `item_id`

---

### STOCK ADJUSTMENT (2 Tables)

#### 2.24 `inv_stock_adjustments`
*Physical count audit header. Approval required above configurable value threshold. V2 addition.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| adjustment_number | VARCHAR(50) | No | — | NOT NULL UNIQUE | e.g., "ADJ-2026-001" |
| adjustment_date | DATE | No | — | NOT NULL | |
| godown_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_godowns | |
| reason | VARCHAR(500) | Yes | NULL | — | Adjustment reason |
| status | ENUM('draft','submitted','approved','rejected','posted') | No | 'draft' | — | |
| approved_by | BIGINT UNSIGNED | Yes | NULL | FK → sys_users | |
| approved_at | TIMESTAMP | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `adjustment_number`
**Indexes:** `godown_id`, `status`, `approved_by`, `is_active`

---

#### 2.25 `inv_stock_adjustment_items`
*Audit line items. `variance_qty` is a GENERATED ALWAYS AS STORED column — never INSERT/UPDATE this column.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| adjustment_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_adjustments ON DELETE CASCADE | |
| item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | |
| system_qty | DECIMAL(15,3) | No | — | NOT NULL | System balance at time of audit |
| physical_qty | DECIMAL(15,3) | No | — | NOT NULL | Physically counted qty |
| variance_qty | DECIMAL(15,3) | No | GENERATED | `GENERATED ALWAYS AS (physical_qty - system_qty) STORED` | Positive = surplus, negative = deficit |
| unit_cost | DECIMAL(15,2) | No | — | NOT NULL | Valuation rate |
| *+ standard audit cols* | | | | | |

**Indexes:** `adjustment_id`, `item_id`

---

### ASSET TRACKING (3 Tables)

#### 2.26 `inv_assets`
*Fixed asset register. One record per physical unit. Auto-created on GRN acceptance for asset items.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| asset_tag | VARCHAR(50) | No | — | NOT NULL UNIQUE | Auto-generated, e.g., "ASSET-2026-001" |
| asset_category_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_asset_categories | |
| stock_item_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_stock_items | Parent item |
| grn_item_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_grn_items | Source GRN item |
| purchase_date | DATE | Yes | NULL | — | |
| purchase_cost | DECIMAL(15,2) | Yes | NULL | — | |
| current_book_value | DECIMAL(15,2) | Yes | NULL | — | Synced from acc_fixed_assets |
| acc_fixed_asset_id | BIGINT UNSIGNED | Yes | NULL | FK → acc_fixed_assets | **Nullable** — synced from Accounting |
| godown_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_godowns | Current storage location |
| assigned_employee_id | INT UNSIGNED | Yes | NULL | FK → sch_employees | **INT UNSIGNED** |
| condition | ENUM('good','fair','poor','under_repair','disposed') | No | 'good' | — | Current condition |
| warranty_expiry_date | DATE | Yes | NULL | — | |
| *+ standard audit cols* | | | | | |

**Unique:** `asset_tag`
**Indexes:** `asset_category_id`, `stock_item_id`, `grn_item_id`, `acc_fixed_asset_id`, `godown_id`, `assigned_employee_id`, `condition`, `is_active`

---

#### 2.27 `inv_asset_movements`
*Asset transfer history. Records every change of location or assigned employee.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| asset_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_assets | |
| movement_date | DATE | No | — | NOT NULL | |
| from_godown_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_godowns | Previous location |
| to_godown_id | BIGINT UNSIGNED | Yes | NULL | FK → inv_godowns | New location |
| from_employee_id | INT UNSIGNED | Yes | NULL | FK → sch_employees | **INT UNSIGNED** |
| to_employee_id | INT UNSIGNED | Yes | NULL | FK → sch_employees | **INT UNSIGNED** |
| reason | VARCHAR(500) | Yes | NULL | — | Transfer reason |
| moved_by | BIGINT UNSIGNED | No | — | NOT NULL FK → sys_users | |
| *+ standard audit cols* | | | | | |

**Indexes:** `asset_id`, `from_godown_id`, `to_godown_id`, `from_employee_id`, `to_employee_id`, `moved_by`, `movement_date`

---

#### 2.28 `inv_asset_maintenance`
*Maintenance log per asset. AMC tracking. Overdue alert when scheduled date passes.*

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| asset_id | BIGINT UNSIGNED | No | — | NOT NULL FK → inv_assets | |
| maintenance_date | DATE | No | — | NOT NULL | Actual/scheduled date |
| maintenance_type | ENUM('preventive','corrective','amc','calibration') | No | — | NOT NULL | |
| vendor_id | INT UNSIGNED | Yes | NULL | FK → vnd_vendors | **INT UNSIGNED** — AMC vendor |
| cost | DECIMAL(15,2) | Yes | NULL | — | Maintenance cost |
| notes | TEXT | Yes | NULL | — | |
| next_due_date | DATE | Yes | NULL | — | Next scheduled maintenance |
| status | ENUM('scheduled','completed','overdue') | No | 'scheduled' | — | |
| *+ standard audit cols* | | | | | |

**Indexes:** `asset_id`, `vendor_id`, `status`, `next_due_date`, `maintenance_date`

---

## 3. Entity Relationship Diagram

```
═══════════════════════════════════════════════════════════════════════════
INV — Inventory Module ERD (Text-Based)
═══════════════════════════════════════════════════════════════════════════

CROSS-MODULE DEPENDENCIES (Inventory reads; never modifies schema)
─────────────────────────────────────────────────────────────────
vnd_vendors (VND module)          — id INT UNSIGNED
sch_employees (SCH module)        — id INT UNSIGNED
sch_department (SCH module, singular) — id INT UNSIGNED
acc_vouchers (ACC module)         — id BIGINT UNSIGNED [NOT yet in DDL — D21 dependency]
acc_ledgers (ACC module)          — id BIGINT UNSIGNED
acc_tax_rates (ACC module)        — id BIGINT UNSIGNED
acc_fixed_assets (ACC module)     — id BIGINT UNSIGNED
sys_users (SYS)                   — id referenced via created_by/approved_by etc.

MASTERS LAYER
─────────────────────────────────────────────────────────────────
inv_units_of_measure                        (no inv_* deps)
inv_asset_categories                         (no inv_* deps)
    │
inv_stock_groups ──────────────────────────→ inv_units_of_measure (default_uom_id)
    └─(self-ref)──→ inv_stock_groups (parent_id)
inv_uom_conversions ───────────────────────→ inv_units_of_measure (from_uom_id, to_uom_id)

ITEMS & GODOWNS
─────────────────────────────────────────────────────────────────
inv_stock_items ────────────────────────────→ inv_stock_groups
                ────────────────────────────→ inv_units_of_measure
                ─── [cross-module] ─────────→ acc_tax_rates
                ─── [cross-module] ─────────→ acc_ledgers (purchase_ledger_id)
                ─── [cross-module] ─────────→ acc_ledgers (sales_ledger_id)

inv_godowns ────────────────────────────────→ inv_godowns (parent_id, self-ref)
            ─── [cross-module] ─────────────→ sch_employees (in_charge_employee_id)

STOCK LEDGER
─────────────────────────────────────────────────────────────────
inv_stock_balances ─────────────────────────→ inv_stock_items
                   ─────────────────────────→ inv_godowns
    ↑ (updated atomically on every inv_stock_entries insert)

inv_stock_entries ──────────────────────────→ inv_stock_items
                  ──────────────────────────→ inv_godowns (godown_id + destination_godown_id)
                  ─── [cross-module] ─────────→ acc_vouchers (voucher_id — MANDATORY NOT NULL)
                  ─── [cross-module] ─────────→ acc_ledgers (party_ledger_id)

VENDOR LINKAGE
─────────────────────────────────────────────────────────────────
inv_item_vendor_jnt ────────────────────────→ inv_stock_items
                    ─── [cross-module] ──────→ vnd_vendors

inv_rate_contracts ─── [cross-module] ──────→ vnd_vendors
inv_rate_contract_items_jnt ────────────────→ inv_rate_contracts (CASCADE DELETE)
                            ────────────────→ inv_stock_items

PROCUREMENT
─────────────────────────────────────────────────────────────────
inv_purchase_requisitions ─── [cross-module] → sys_users (requested_by, approved_by)
                          ─── [cross-module] → sch_department

inv_purchase_requisition_items ─────────────→ inv_purchase_requisitions (CASCADE DELETE)
                               ─────────────→ inv_stock_items
                               ─────────────→ inv_units_of_measure

inv_quotations ─────────────────────────────→ inv_purchase_requisitions (nullable)
               ─── [cross-module] ──────────→ vnd_vendors
inv_quotation_items ────────────────────────→ inv_quotations (CASCADE DELETE)
                    ────────────────────────→ inv_stock_items

inv_purchase_orders ────────────────────────→ inv_purchase_requisitions (nullable)
                    ────────────────────────→ inv_quotations (nullable)
                    ─── [cross-module] ──────→ vnd_vendors
                    ─── [cross-module] ──────→ sys_users (approved_by)
inv_purchase_order_items ───────────────────→ inv_purchase_orders (CASCADE DELETE)
                         ───────────────────→ inv_stock_items
                         ─── [cross-module] →  acc_tax_rates

inv_goods_receipt_notes ────────────────────→ inv_purchase_orders
                        ────────────────────→ inv_godowns
                        ─── [cross-module] ──→ vnd_vendors
                        ─── [cross-module] ──→ sys_users (received_by)
                        ─── [cross-module] ──→ acc_vouchers (NULL until accepted)
inv_grn_items ──────────────────────────────→ inv_goods_receipt_notes (CASCADE DELETE)
              ──────────────────────────────→ inv_purchase_order_items
              ──────────────────────────────→ inv_stock_items

STOCK ISSUE
─────────────────────────────────────────────────────────────────
inv_issue_requests ─── [cross-module] ──────→ sys_users
                   ─── [cross-module] ──────→ sch_department
inv_issue_request_items ────────────────────→ inv_issue_requests (CASCADE DELETE)
                        ────────────────────→ inv_stock_items
                        ────────────────────→ inv_units_of_measure

inv_stock_issues ───────────────────────────→ inv_issue_requests (nullable — direct issue)
                 ───────────────────────────→ inv_godowns
                 ─── [cross-module] ─────────→ sys_users (issued_by, acknowledged_by)
                 ─── [cross-module] ─────────→ sch_employees (issued_to_employee_id)
                 ─── [cross-module] ─────────→ sch_department
                 ─── [cross-module] ─────────→ acc_vouchers (NULL until Stock Journal)
inv_stock_issue_items ──────────────────────→ inv_stock_issues (CASCADE DELETE)
                      ──────────────────────→ inv_stock_items

STOCK ADJUSTMENT
─────────────────────────────────────────────────────────────────
inv_stock_adjustments ──────────────────────→ inv_godowns
                      ─── [cross-module] ────→ sys_users (approved_by)
inv_stock_adjustment_items ─────────────────→ inv_stock_adjustments (CASCADE DELETE)
                           ─────────────────→ inv_stock_items
                           [variance_qty = GENERATED ALWAYS AS (physical_qty - system_qty) STORED]

ASSET TRACKING
─────────────────────────────────────────────────────────────────
inv_assets ─────────────────────────────────→ inv_asset_categories
           ─────────────────────────────────→ inv_stock_items
           ─────────────────────────────────→ inv_grn_items (nullable — source)
           ─────────────────────────────────→ inv_godowns (nullable)
           ─── [cross-module] ──────────────→ sch_employees (assigned_employee_id)
           ─── [cross-module] ──────────────→ acc_fixed_assets (nullable — synced)

inv_asset_movements ────────────────────────→ inv_assets
                    ────────────────────────→ inv_godowns (from + to, nullable)
                    ─── [cross-module] ──────→ sch_employees (from + to employee, nullable)
                    ─── [cross-module] ──────→ sys_users (moved_by)

inv_asset_maintenance ──────────────────────→ inv_assets
                      ─── [cross-module] ────→ vnd_vendors (nullable — AMC vendor)
```

---

## 4. Business Rules

| Rule ID | Rule Description | Table/Column | Enforcement Point |
|---|---|---|---|
| **BR-INV-001** | Every `inv_stock_entries` record MUST have a non-null `voucher_id` — no orphan stock movements allowed | `inv_stock_entries.voucher_id` NOT NULL | `db_constraint` + `service_layer` |
| **BR-INV-002** | Stock is NOT updated in `inv_stock_balances` until GRN status transitions to 'accepted' | `inv_stock_balances` | `service_layer` (GrnPostingService) |
| **BR-INV-003** | Negative stock is not permitted — outward/issue entry rejected with user-facing error if `current_qty < requested_qty` | `inv_stock_balances.current_qty` | `service_layer` (StockLedgerService guard before any outward entry) |
| **BR-INV-004** | Converted PR lines cannot be edited — PRs with status 'converted' are read-only | `inv_purchase_requisitions.status = 'converted'` | `service_layer` + `form_validation` |
| **BR-INV-005** | PO auto-transitions to 'received' when all `inv_purchase_order_items.received_qty >= ordered_qty` | `inv_purchase_orders.status` | `service_layer` (GrnPostingService post-update check) |
| **BR-INV-006** | GRN `accepted_qty + rejected_qty` MUST equal `received_qty` — per line item | `inv_grn_items` | `form_validation` + `service_layer` |
| **BR-INV-007** | GRN `received_qty` per item cannot exceed `(PO ordered_qty − already received across all prior GRNs)` | `inv_grn_items.received_qty` vs `inv_purchase_order_items.received_qty` | `service_layer` (GrnPostingService pre-acceptance check) |
| **BR-INV-008** | When batch tracking enabled, outward entries use FIFO batch selection — oldest batch_number first | `inv_stock_entries.batch_number` | `service_layer` (StockValuationService FIFO selection) |
| **BR-INV-009** | Stock valuation method (FIFO / WAC / LPC) is configured per item; issue cost calculated per item's method | `inv_stock_items.valuation_method` | `service_layer` (StockValuationService) |
| **BR-INV-010** | Stock issue requires approved issue request unless issuer has `inventory.stock-issue.direct` permission | `inv_stock_issues.issue_request_id` | `service_layer` + `policy` |
| **BR-INV-011** | Reorder alert fires when `current_qty <= reorder_level` after every outward entry; dispatched as async queued job | `inv_stock_balances.current_qty` vs `inv_stock_items.reorder_level` | `service_layer` (ReorderAlertService post-deduction) |
| **BR-INV-012** | Asset-type GRN acceptance creates one `inv_assets` record per accepted unit (accepted_qty must be integer); fires acc_fixed_assets creation | `inv_stock_items.item_type = 'asset'` | `service_layer` (GrnPostingService) + `model_event` |
| **BR-INV-013** | Active rate contract pricing auto-populates PO item unit price; expired contracts ignored | `inv_rate_contracts.status = 'active'` | `service_layer` (PurchaseOrderService) |
| **BR-INV-014** | `inv_stock_entries` are immutable once posted — corrections only via new adjustment entries; no UPDATE/DELETE on posted entries | `inv_stock_entries` | `service_layer` (StockLedgerService guard) — no UPDATE route exposed |
| **BR-INV-015** | No `tenant_id` column on any `inv_*` table — isolation at DB level via stancl/tenancy v3.9 | All `inv_*` tables | `db_constraint` (column simply does not exist) |
| **BR-INV-016** | POs above configurable approval threshold require explicit approval before 'sent' status | `inv_purchase_orders.net_amount` vs school threshold setting | `service_layer` (PurchaseOrderService) + `form_validation` |
| **BR-INV-017** | Stock adjustments above configurable value threshold require Principal/Admin approval before posting | `inv_stock_adjustments` total value | `service_layer` + `policy` |
| **BR-INV-018** | Asset depreciation computed annually per Income Tax Act WDV rates; computation delegated to Accounting module | `inv_assets.current_book_value` | `service_layer` (Accounting module owns; Inventory syncs value) |

---

## 5. Workflow State Machines

### 5.1 Procurement Workflow FSM

```
PURCHASE REQUISITION (PR)
─────────────────────────────────────────────────────────────────
[Draft] ──submit()──→ [Submitted] ──approve()──→ [Approved]
                          │                          │
                      reject()                   reject()
                          │                          │
                          └──────────→ [Rejected] ←──┘

[Approved] ──convertToPO()──→ [Converted]
[Any State] ──cancel()──→ [Cancelled]

Pre-conditions for submit(): PR has at least 1 line item
Pre-conditions for approve(): approver has inventory.purchase-requisition.approve permission
Side effects on convert(): PR status → 'converted'; PR lines become read-only (BR-INV-004)

REQUEST FOR QUOTATION (optional RFQ step)
─────────────────────────────────────────────────────────────────
[Draft] ──send()──→ [Sent] ──receiveQuotes()──→ [Received]
                                                     │
                                               compare & select
                                                     │
                                             convertToPO()──→ [Converted]
[Any State] ──expire()──→ [Expired]

PURCHASE ORDER (PO)
─────────────────────────────────────────────────────────────────
[Draft] ──approve()*──→ [Approved] ──sendToVendor()──→ [Sent]
                                                          │
[Sent] ──partialGRN()──→ [Partial] ──finalGRN()──→ [Received] ──close()──→ [Closed]
[Any active state] ──cancel()──→ [Cancelled]

*approve() required only if net_amount >= approval_threshold (BR-INV-016)
Pre-conditions for sendToVendor(): PO in approved state OR net_amount < threshold
Side effects on auto-received: triggered by GrnPostingService when all received_qty >= ordered_qty (BR-INV-005)

GOODS RECEIPT NOTE (GRN)
─────────────────────────────────────────────────────────────────
[Draft] ──inspect()──→ [Inspected] ──accept()──→ [Accepted]
                           │             │
                       reject()     partialAccept()
                           │             │
                      [Rejected]    [Partial]

On accept():
  Pre-conditions:
    - accepted_qty + rejected_qty == received_qty per line (BR-INV-006)
    - received_qty <= (PO ordered_qty - already received) per line (BR-INV-007)
  Side effects (all in single DB transaction):
    1. Fire GrnAccepted event → Accounting creates Purchase Voucher
    2. inv_stock_entries (entry_type='inward') created for each accepted_qty line
    3. inv_stock_balances updated (lockForUpdate() row-level lock)
    4. inv_item_vendor_jnt: last_purchase_rate + last_purchase_date updated
    5. If item_type='asset': inv_assets records created (1 per unit, per accepted_qty int units)
    6. PO inv_purchase_order_items.received_qty incremented
    7. PO status auto-transitioned if fully received (BR-INV-005)
    8. ReorderAlertJob dispatched if current_qty <= reorder_level (BR-INV-011)
```

---

### 5.2 Stock Issue Workflow FSM

```
ISSUE REQUEST
─────────────────────────────────────────────────────────────────
[Submitted] ──approve()──→ [Approved] ──executeIssue()──→ [Issued]
     │                          │
  reject()                partialIssue()
     │                          │
[Rejected]              [Partial] ──completeIssue()──→ [Issued]

STOCK ISSUE EXECUTION
─────────────────────────────────────────────────────────────────
[Issue Request: Approved] ──StockIssueService::executeIssue()──→ [Stock Issue Created]

Pre-conditions:
  - Requires approved Issue Request OR issuer has inventory.stock-issue.direct permission (BR-INV-010)
  - current_qty >= requested_qty in source godown (BR-INV-003)

Side effects (single DB transaction):
  1. Fire StockIssued event → Accounting creates Stock Journal Voucher
  2. inv_stock_entries (entry_type='outward') created
  3. inv_stock_balances current_qty deducted (lockForUpdate())
  4. inv_issue_request_items.issued_qty updated
  5. Issue Request status auto-updated (partial or issued)
  6. ReorderAlertJob dispatched if current_qty <= reorder_level

ACKNOWLEDGMENT
─────────────────────────────────────────────────────────────────
[Stock Issue] ──acknowledge()──→ acknowledged_by set, acknowledged_at set
  (mandatory for asset items per BR-INV-012)
```

---

### 5.3 Asset Lifecycle FSM

```
ASSET CREATION (triggered by GRN acceptance)
─────────────────────────────────────────────────────────────────
[GRN Accepted for item_type='asset'] ──GrnPostingService──→ [inv_assets: condition='good']
  (one record per integer unit of accepted_qty)

CONDITION TRACKING
─────────────────────────────────────────────────────────────────
[good] ←──conditionUpdate()──→ [fair] ←──conditionUpdate()──→ [poor]
                                                    ↓
                                             [under_repair]
                                                    ↓
                                          conditionUpdate()──→ [good/fair/poor]

TRANSFER
─────────────────────────────────────────────────────────────────
[Any condition] ──transfer()──→ [Same condition, new location/employee]
  Side effects: inv_asset_movements record created; inv_assets.godown_id + assigned_employee_id updated

MAINTENANCE
─────────────────────────────────────────────────────────────────
[Any condition] ──maintenance()──→ inv_asset_maintenance record created
  status: scheduled → completed (on completion); overdue (when next_due_date passes without completion)
  Alerts: MaintenanceOverdue event dispatched when next_due_date passes

DISPOSAL
─────────────────────────────────────────────────────────────────
[Any condition] ──dispose()──→ [disposed]
  Side effects:
    1. inv_assets.condition = 'disposed'
    2. AssetDisposed event fired → Accounting writes off residual value in acc_fixed_assets
```

---

### 5.4 Stock Adjustment FSM

```
STOCK ADJUSTMENT
─────────────────────────────────────────────────────────────────
[Draft] ──submit()──→ [Submitted] ──approve()*──→ [Approved] ──post()──→ [Posted]
                          │
                      reject()
                          │
                      [Rejected]

*approve() required when total adjustment value >= configurable threshold (BR-INV-017)

On post() (single DB transaction):
  For each inv_stock_adjustment_items line (variance_qty GENERATED ALWAYS):
    If variance_qty > 0 (surplus):
      inv_stock_entries (entry_type='adjustment', inward) created
      inv_stock_balances current_qty incremented
    If variance_qty < 0 (deficit):
      inv_stock_entries (entry_type='adjustment', outward) created
      inv_stock_balances current_qty decremented
  StockAdjusted event fired → Accounting creates Journal Entry

  Pre-conditions:
    - All inv_stock_adjustment_items have physical_qty entered
    - For deficit lines: deficit quantity must not exceed current_qty (BR-INV-003)
```

---

## 6. Functional Requirements Summary

| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|
| FR-INV-001 | Stock Group Management | L1 | `inv_stock_groups` | Name required; code unique if set; is_system groups cannot delete | — | None |
| FR-INV-002 | Stock Item Master | L1 | `inv_stock_items`, `inv_stock_groups`, `inv_units_of_measure` | SKU unique if set; stock_group_id required; valuation_method valid ENUM | BR-INV-009 | FR-INV-001, FR-INV-003, ACC ledgers, ACC tax_rates |
| FR-INV-003 | UOM Master & Conversion | L1 | `inv_units_of_measure`, `inv_uom_conversions` | Symbol required; (from_uom_id, to_uom_id) unique; conversion_factor > 0 | — | None |
| FR-INV-004 | Godown Management | L1 | `inv_godowns`, `sch_employees` | Code unique if set; in_charge_employee_id valid sch_employees | — | SCH module |
| FR-INV-005 | Stock Entry Ledger | L2 | `inv_stock_entries`, `inv_stock_balances` | voucher_id NOT NULL; entry_type valid; negative stock prevention | BR-INV-001, BR-INV-003, BR-INV-008, BR-INV-014 | ACC Vouchers (D21) |
| FR-INV-005a | Denormalized Balance | L2 | `inv_stock_balances` | Atomic update; row-level lock; recalculate command | BR-INV-003 | FR-INV-005 |
| FR-INV-006 | Stock Adjustment | L2 | `inv_stock_adjustments`, `inv_stock_adjustment_items` | All physical_qty entered before submit; variance GENERATED ALWAYS; approval threshold | BR-INV-017, BR-INV-014 | ACC VoucherServiceInterface |
| FR-INV-007 | Purchase Requisition | L3 | `inv_purchase_requisitions`, `inv_purchase_requisition_items` | pr_number auto-generated; department_id valid; at least 1 item | BR-INV-004 | SCH sch_department |
| FR-INV-008 | Purchase Order | L3 | `inv_purchase_orders`, `inv_purchase_order_items` | po_number auto-generated; approval threshold check; vendor active | BR-INV-005, BR-INV-013, BR-INV-016 | VND vnd_vendors, FR-INV-007 |
| FR-INV-009 | Goods Receipt Note | L3 | `inv_goods_receipt_notes`, `inv_grn_items` | accepted+rejected=received per line; received <= PO balance | BR-INV-002, BR-INV-006, BR-INV-007, BR-INV-012 | FR-INV-008, ACC VoucherServiceInterface |
| FR-INV-010 | Vendor Linkage & Rate Contracts | L4 | `inv_item_vendor_jnt`, `inv_rate_contracts`, `inv_rate_contract_items_jnt` | (item_id, vendor_id) unique; (rate_contract_id, item_id) unique; valid_to >= valid_from | BR-INV-013 | VND vnd_vendors |
| FR-INV-011 | Fixed Asset Register | L5 | `inv_assets`, `inv_asset_categories`, `inv_asset_movements` | asset_tag unique; one record per unit; acc_fixed_asset_id nullable | BR-INV-012, BR-INV-018 | FR-INV-009 (GRN acceptance) |
| FR-INV-012 | Asset Maintenance | L5 | `inv_asset_maintenance` | maintenance_date required; next_due_date for recurring | — | FR-INV-011 |
| FR-INV-013 | Quotation Comparison | L6 | `inv_quotations`, `inv_quotation_items` | rfq_number auto-generated; vendor_id required; comparison matrix | — | VND vnd_vendors, FR-INV-007 |
| FR-INV-014 | Stock Issue Workflow | Issue | `inv_issue_requests`, `inv_issue_request_items`, `inv_stock_issues`, `inv_stock_issue_items` | Requires approved request or direct permission; negative stock prevention | BR-INV-003, BR-INV-008, BR-INV-010 | FR-INV-005, ACC VoucherServiceInterface |
| FR-INV-015 | Reorder Automation & Reports | Reorder | `inv_stock_balances`, `inv_stock_items`, 12 report queries | reorder_level threshold check after every outward entry; async job | BR-INV-011 | FR-INV-014 |

---

## 7. Permission Matrix

| Permission String | Admin | Store Mgr | Principal | Accountant | HOD | Policy Class |
|---|---|---|---|---|---|---|
| `inventory.stock-group.viewAny` | ✓ | ✓ | ✓ | ✓ | ✓ | StockGroupPolicy |
| `inventory.stock-group.create` | ✓ | ✓ | ✗ | ✗ | ✗ | StockGroupPolicy |
| `inventory.stock-group.update` | ✓ | ✓ | ✗ | ✗ | ✗ | StockGroupPolicy |
| `inventory.stock-group.delete` | ✓ | ✗ | ✗ | ✗ | ✗ | StockGroupPolicy |
| `inventory.stock-item.viewAny` | ✓ | ✓ | ✓ | ✓ | ✓ | StockItemPolicy |
| `inventory.stock-item.create` | ✓ | ✓ | ✗ | ✗ | ✗ | StockItemPolicy |
| `inventory.stock-item.update` | ✓ | ✓ | ✗ | ✗ | ✗ | StockItemPolicy |
| `inventory.stock-item.delete` | ✓ | ✗ | ✗ | ✗ | ✗ | StockItemPolicy |
| `inventory.godown.viewAny` | ✓ | ✓ | ✓ | ✓ | ✓ | GodownPolicy |
| `inventory.godown.create` | ✓ | ✓ | ✗ | ✗ | ✗ | GodownPolicy |
| `inventory.godown.update` | ✓ | ✓ | ✗ | ✗ | ✗ | GodownPolicy |
| `inventory.purchase-requisition.create` | ✓ | ✓ | ✗ | ✗ | ✓ (own dept) | PurchaseRequisitionPolicy |
| `inventory.purchase-requisition.approve` | ✓ | ✓ | ✗ | ✗ | ✓ (own dept) | PurchaseRequisitionPolicy |
| `inventory.purchase-order.create` | ✓ | ✓ | ✗ | ✗ | ✗ | PurchaseOrderPolicy |
| `inventory.purchase-order.approve` | ✓ | ✓ | ✗ | ✗ | ✗ | PurchaseOrderPolicy |
| `inventory.grn.create` | ✓ | ✓ | ✗ | ✗ | ✗ | GrnPolicy |
| `inventory.grn.accept` | ✓ | ✓ | ✗ | ✗ | ✗ | GrnPolicy |
| `inventory.stock-issue.direct` | ✓ | ✓ | ✗ | ✗ | ✗ | StockIssuePolicy |
| `inventory.stock-issue.create` | ✓ | ✓ | ✗ | ✗ | ✗ | StockIssuePolicy |
| `inventory.issue-request.create` | ✓ | ✓ | ✗ | ✗ | ✓ (own dept) | IssueRequestPolicy |
| `inventory.issue-request.approve` | ✓ | ✓ | ✗ | ✗ | ✓ (own dept) | IssueRequestPolicy |
| `inventory.stock-adjustment.create` | ✓ | ✓ | ✗ | ✗ | ✗ | StockAdjustmentPolicy |
| `inventory.stock-adjustment.approve` | ✓ | ✗ | ✓ | ✗ | ✗ | StockAdjustmentPolicy |
| `inventory.asset.viewAny` | ✓ | ✓ | ✓ | ✓ | ✓ (own dept) | AssetPolicy |
| `inventory.asset.update` | ✓ | ✓ | ✗ | ✗ | ✗ | AssetPolicy |
| `inventory.asset.dispose` | ✓ | ✗ | ✗ | ✗ | ✗ | AssetPolicy |
| `inventory.rate-contract.create` | ✓ | ✓ | ✗ | ✓ (view) | ✗ | RateContractPolicy |
| `inventory.rate-contract.activate` | ✓ | ✓ | ✗ | ✗ | ✗ | RateContractPolicy |
| `inventory.reports.view` | ✓ | ✓ | ✓ (summary) | ✓ | ✓ (own dept) | ReportPolicy |
| `inventory.reports.export` | ✓ | ✓ | ✓ | ✓ | ✗ | ReportPolicy |

> **HOD constraint:** HOD access to purchase-requisition, issue-request, and reports is scoped to their own `department_id`. PurchaseRequisitionPolicy and IssueRequestPolicy enforce `$model->department_id === auth()->user()->department_id`.

---

## 8. Service Architecture

### 8.1 StockLedgerService
```
Service:     StockLedgerService
File:        Modules/Inventory/app/Services/StockLedgerService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  StockValuationService
Fires:       (no events — fires come from calling services)

Key Methods:
  postEntry(array $data): InvStockEntry
    └── Validates non-negative balance (BR-INV-003), validates voucher_id present (BR-INV-001),
        inserts inv_stock_entries, updates inv_stock_balances with lockForUpdate(),
        checks immutability guard (BR-INV-014)

  updateBalance(int $itemId, int $godownId, float $qtyDelta, float $valueDelta): void
    └── lockForUpdate() on inv_stock_balances row, upserts if not exists, atomically updates

  recalculateBalances(int $itemId = null): void
    └── Support for inventory:recalculate-balances Artisan command; rebuilds from inv_stock_entries
```

### 8.2 StockValuationService
```
Service:     StockValuationService
File:        Modules/Inventory/app/Services/StockValuationService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  StockLedgerService

Key Methods:
  getIssueRate(InvStockItem $item, float $qty, int $godownId): float
    └── Dispatches to FIFO/WAC/LPC method per item.valuation_method (BR-INV-009)

  selectFifoBatch(int $itemId, int $godownId, float $qty): array
    └── Orders inv_stock_entries by batch_number (oldest first), selects batches to fill qty (BR-INV-008)

  recalculateWeightedAverage(int $itemId, float $inwardQty, float $inwardRate): float
    └── (currentBalance.current_value + inwardQty * inwardRate) / (currentBalance.current_qty + inwardQty)

  updateLastPurchaseCost(int $itemId, int $vendorId, float $rate, string $date): void
    └── Updates inv_item_vendor_jnt.last_purchase_rate + last_purchase_date
```

### 8.3 GrnPostingService
```
Service:     GrnPostingService
File:        Modules/Inventory/app/Services/GrnPostingService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  StockLedgerService, StockValuationService
Fires:       GrnAccepted

Key Methods:
  acceptGrn(InvGoodsReceiptNote $grn): void
    └── DB::transaction():
          1. Validate accepted+rejected=received per line (BR-INV-006)
          2. Validate received <= PO balance per line (BR-INV-007)
          3. Create inv_stock_entries (inward) per accepted line
          4. updateBalance() per line
          5. Update PO item received_qty
          6. Auto-transition PO status if complete (BR-INV-005)
          7. Update inv_item_vendor_jnt last_purchase_rate + last_purchase_date
          8. If item_type='asset': createAssetRecords()
          9. Update GRN voucher_id (set after Accounting responds via event)
          10. fire(new GrnAccepted($grn))

  createAssetRecords(InvGrnItem $grnItem): void
    └── Creates ceil(accepted_qty) inv_assets records with auto-generated asset_tag (BR-INV-012)
```

### 8.4 PurchaseOrderService
```
Service:     PurchaseOrderService
File:        Modules/Inventory/app/Services/PurchaseOrderService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  (none)
Fires:       (none)

Key Methods:
  convertFromPR(InvPurchaseRequisition $pr, array $data): InvPurchaseOrder
    └── Validates PR status = 'approved'; pre-fills vendor from preferred vendor;
        pre-fills rates from active rate contract if exists (BR-INV-013); marks PR as 'converted'

  enforceApprovalThreshold(InvPurchaseOrder $po): void
    └── Checks school setting for approval_threshold; requires approve() before sendToVendor() (BR-INV-016)

  autoTransitionStatus(InvPurchaseOrder $po): void
    └── Called by GrnPostingService; checks all items received_qty >= ordered_qty; transitions to 'received'
```

### 8.5 StockIssueService
```
Service:     StockIssueService
File:        Modules/Inventory/app/Services/StockIssueService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  StockLedgerService, StockValuationService, ReorderAlertService
Fires:       StockIssued

Key Methods:
  executeIssue(InvIssueRequest $request, array $data): InvStockIssue
    └── Validates permission: approved request OR has direct permission (BR-INV-010)
        DB::transaction():
          1. Negative stock check per item per godown (BR-INV-003)
          2. StockValuationService::getIssueRate() per item
          3. Create inv_stock_issues + inv_stock_issue_items
          4. StockLedgerService::postEntry(outward) per item
          5. Update inv_issue_request_items.issued_qty
          6. Update issue request status
          7. fire(new StockIssued($issue))
          8. ReorderAlertService::checkAndDispatch() per item

  directIssue(array $data): InvStockIssue
    └── Bypasses issue request; requires inventory.stock-issue.direct permission
```

### 8.6 ReorderAlertService
```
Service:     ReorderAlertService
File:        Modules/Inventory/app/Services/ReorderAlertService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  (none — dispatches jobs)
Fires:       ReorderThresholdReached (via ReorderAlertJob)

Key Methods:
  checkAndDispatch(int $itemId, int $godownId): void
    └── Reads inv_stock_balances.current_qty vs inv_stock_items.reorder_level;
        dispatches ReorderAlertJob if current_qty <= reorder_level (BR-INV-011);
        job: 3 retries, 60s delay (async — does not block response)

  checkReorderLevelsAll(): void
    └── Support for inventory:check-reorder-levels Artisan command; chunks through all items

  createAutoReorderPR(InvStockItem $item): InvPurchaseRequisition
    └── Called by ReorderAlertJob if item.auto_reorder_pr = true;
        creates Draft PR + line item from preferred vendor at last_purchase_rate
```

### 8.7 InventoryReportService
```
Service:     InventoryReportService
File:        Modules/Inventory/app/Services/InventoryReportService.php
Namespace:   Modules\Inventory\app\Services
Depends on:  (none)
Fires:       (none)

Key Methods:
  stockBalance(array $filters): Collection
  stockValuation(array $filters): Collection
  stockLedger(int $itemId, array $filters): Collection
  consumption(array $filters): Collection
  purchaseRegister(array $filters): Collection
  pendingPO(array $filters): Collection
  grnRegister(array $filters): Collection
  reorderAlerts(): Collection
  fastSlowMovers(array $filters): Collection
  expiryAlerts(int $daysAhead = 30): Collection
  assetRegister(array $filters): Collection
  godownwiseStock(int $godownId): Collection
    └── All methods: chunk(500) for exports; < 10s target (BR-NFR performance)

  export(string $type, array $filters, string $format): StreamedResponse
    └── CSV: fputcsv() via php://temp; PDF: DomPDF template
```

---

## 9. Integration Contracts

| Event | Fired By | When | Consumer Module | Payload | Action |
|---|---|---|---|---|---|
| `GrnAccepted` | GrnPostingService | GRN status → 'accepted' | Accounting (ACC) | `{grn_id, vendor_id, godown_id, items:[{item_id, qty, rate, amount, batch_number}], total_amount, purchase_ledger_id, party_ledger_id, narration}` | Creates Purchase Voucher (Dr Stock-in-Hand A/c, Cr Vendor Creditor A/c); sets inv_goods_receipt_notes.voucher_id |
| `StockIssued` | StockIssueService | Stock issue execution confirmed | Accounting (ACC) | `{stock_issue_id, department_id, godown_id, items:[{item_id, qty, rate, amount}], total_amount, stock_ledger_id, expense_ledger_id, narration}` | Creates Stock Journal (Dr Dept Consumption A/c, Cr Stock-in-Hand A/c); sets inv_stock_issues.voucher_id |
| `StockTransferred` | StockIssueService | Godown-to-godown transfer | Accounting (ACC) | `{from_godown_id, to_godown_id, items, total_value}` | Creates Stock Journal (Dr Destination Stock A/c, Cr Source Stock A/c) |
| `StockAdjusted` | StockLedgerService | Adjustment approved + posted | Accounting (ACC) | `{adjustment_id, items:[{item_id, variance_qty, unit_cost, variance_value}], net_surplus, net_deficit}` | Creates Journal Entry (Dr/Cr Stock-in-Hand A/c) |
| `AssetDisposed` | AssetController | Asset marked 'disposed' | Accounting (ACC) | `{asset_id, acc_fixed_asset_id, disposal_date, book_value}` | Write-off residual value in acc_fixed_assets |
| `ReorderThresholdReached` | ReorderAlertJob | Balance <= reorder_level | Notification (NTF) | `{item_id, item_name, current_qty, reorder_level, godown_id}` | Alert notification dispatched to store manager role |
| `RateContractExpiringSoon` | Scheduled Command | 30 days before valid_to | Notification (NTF) | `{contract_id, vendor_id, valid_to, items_count}` | Alert to store manager |
| `MaintenanceOverdue` | Scheduled Command | next_due_date passed without completion | Notification (NTF) | `{asset_id, asset_tag, maintenance_type, next_due_date, days_overdue}` | Alert to store manager |

### 9.1 GrnAccepted Payload Detail
```php
class GrnAccepted {
    public function __construct(
        public int    $grn_id,
        public int    $vendor_id,
        public int    $godown_id,
        public array  $items,           // [{item_id, qty, rate, amount, batch_number}]
        public float  $total_amount,
        public int    $purchase_ledger_id,
        public int    $party_ledger_id, // Vendor creditor ledger
        public string $narration,
    ) {}
}
```

### 9.2 StockIssued Payload Detail
```php
class StockIssued {
    public function __construct(
        public int    $stock_issue_id,
        public int    $department_id,
        public int    $godown_id,
        public array  $items,           // [{item_id, qty, rate, amount}]
        public float  $total_amount,
        public int    $stock_ledger_id,   // Stock-in-hand account
        public int    $expense_ledger_id, // Dept consumption account
        public string $narration,
    ) {}
}
```

---

## 10. Non-Functional Requirements

| NFR ID | Category | Requirement | Target | Implementation Note |
|---|---|---|---|---|
| NFR-INV-001 | Performance | Stock balance query — single item, all godowns | < 500ms | `inv_stock_balances` UNIQUE on `(stock_item_id, godown_id)` → O(1) lookup; eager load godown names |
| NFR-INV-002 | Performance | Stock balance — all items, single godown | < 2s (5,000 items) | Index on `godown_id` + `is_active`; paginate index views |
| NFR-INV-003 | Performance | Report generation — 12 months data | < 10s | `chunk(500)` in InventoryReportService; indexed `created_at` on all entry tables |
| NFR-INV-004 | Performance | GRN acceptance transaction | < 3s | DB::transaction() wraps all 8 side-effect operations; async: ReorderAlertJob dispatched after commit |
| NFR-INV-005 | Performance | Dashboard KPI widgets | < 2s | Aggregate queries use inv_stock_balances (denormalized); no SUM across inv_stock_entries for balance |
| NFR-INV-006 | Reliability | GRN acceptance atomicity | All-or-nothing | DB::transaction() wraps stock entry + balance + event dispatch + PO update; rollback on any failure |
| NFR-INV-007 | Reliability | Stock issue atomicity | All-or-nothing | DB::transaction() wraps stock entry + balance deduction + voucher event |
| NFR-INV-008 | Reliability | Adjustment posting atomicity | All-or-nothing | DB::transaction() wraps all variance entries + balance updates |
| NFR-INV-009 | Reliability | Reorder alert delivery | 3 retries | `ReorderAlertJob`: `$tries = 3`, `$backoff = 60` (seconds); does not block GRN/Issue response |
| NFR-INV-010 | Data Integrity | No tenant_id column | Schema level | Column does not exist on any `inv_*` table (BR-INV-015) |
| NFR-INV-011 | Data Integrity | inv_stock_balances concurrency | Race-free | `lockForUpdate()` in StockLedgerService::updateBalance() — row-level exclusive lock |
| NFR-INV-012 | Data Integrity | inv_stock_entries immutability | Application + DB | No UPDATE/DELETE route exposed; StockLedgerService guard on all writes (BR-INV-014) |
| NFR-INV-013 | Data Integrity | Soft deletes on all tables | All inv_* | `deleted_at` column on all 28 tables; use `SoftDeletes` trait in all models |
| NFR-INV-014 | Data Integrity | Balance rebuild command | Recovery | `inventory:recalculate-balances` Artisan command; rebuilds from scratch from inv_stock_entries |
| NFR-INV-015 | Security | All routes protected | Auth + Tenant | `auth` middleware + stancl/tenancy bootstrappers; 13 Policies for fine-grained authorization |
| NFR-INV-016 | Security | Stock movement audit | Every movement | `sys_activity_logs` write on every approval, stock entry, and adjustment |
| NFR-INV-017 | Security | PO threshold server-side | No UI bypass | Threshold check enforced in PurchaseOrderService, not just in UI |
| NFR-INV-018 | Scalability | Large exports — memory | chunk(500) | InventoryReportService uses `chunk(500)` for all large queries; no memory exhaustion |
| NFR-INV-019 | Scalability | Label generation batching | Max 200/request | Barcode/QR label generation limited; uses `milon/barcode` or `chillerlan/php-qrcode` |
| NFR-INV-020 | Compliance | GST on PO items | CGST+SGST/IGST | `acc_tax_rates.type` ENUM('CGST','SGST','IGST','Cess'); HSN/SAC on inv_stock_items |
| NFR-INV-021 | Compliance | Government stock register | PDF export | InventoryReportService::stockBalance() → DomPDF government-format template |
| NFR-INV-022 | Compliance | Fixed asset depreciation | WDV method | Income Tax Act rates stored in inv_asset_categories.depreciation_rate; Accounting owns computation |

---

## 11. Test Plan Outline

### 11.1 Feature Tests (Pest) — 13 Files

| File | Key Scenarios | Count |
|---|---|---|
| `StockGroupTest` | Create group, create child group (hierarchy), deactivate with audit log, prevent delete of is_system group, code uniqueness | 5 |
| `StockItemTest` | Create consumable, create asset, set reorder levels, toggle batch/expiry, valuation method assignment, SKU uniqueness | 6 |
| `UomConversionTest` | Create UOM, create conversion rule, bidirectional calculation, effective date validation, duplicate pair rejected | 5 |
| `GodownTest` | Create godown, sub-godown hierarchy (parent_id), assign in-charge employee, code uniqueness | 4 |
| `PurchaseRequisitionTest` | Create PR, submit PR, approve PR, reject PR, CSV import valid file, CSV import with row errors — preview report | 6 |
| `QuotationTest` | Create RFQ from PR, record vendor quotes, comparison matrix rendering, convert selected quote to PO | 4 |
| `PurchaseOrderTest` | Create PO from PR, direct PO, approval threshold enforcement, PO status lifecycle, partial GRN received_qty update, auto-close on full receipt | 6 |
| `GrnTest` | Create GRN, QC pass, QC partial reject, accept GRN → stock entry created + GrnAccepted event fired, reject GRN, partial GRN → PO status partial | 6 |
| `StockIssueTest` | Create issue request, approve, execute issue, direct issue without request (with permission), negative stock prevention, partial issue, acknowledgment | 7 |
| `StockAdjustmentTest` | Create adjustment, submit, approve, post → surplus creates inward entry, deficit creates outward entry, StockAdjusted event fired | 5 |
| `AssetTest` | Asset auto-created on GRN acceptance for asset item, asset_tag auto-generated, transfer records inv_asset_movements, dispose fires AssetDisposed event | 4 |
| `ReorderAlertTest` | Stock drops below threshold → ReorderAlertJob dispatched, above threshold → no job, auto-PR created when auto_reorder_pr = true | 3 |
| `RateContractTest` | Create contract, activate, item rates auto-apply on PO creation, expired contract not applied, expiry alert dispatched at 30 days | 4 |

### 11.2 Unit Tests (PHPUnit) — 5 Files

| File | Key Scenarios | Count |
|---|---|---|
| `StockLedgerServiceTest` | Post inward entry → balance increments, post outward entry → balance decrements, negative stock throws exception, balance lockForUpdate prevents race | 4 |
| `StockValuationServiceTest` | FIFO batch selection — oldest batch first, FIFO across multiple batches, weighted average recalculation on inward, last purchase cost update on GRN | 4 |
| `GrnPostingServiceTest` | GrnAccepted event fired on acceptance, PO received_qty updated per item, asset records created for asset items (one per unit), vendor last_purchase_rate updated | 4 |
| `ReorderAlertServiceTest` | Alert dispatched when below threshold, no dispatch when above threshold, auto-PR only when auto_reorder_pr = true, no duplicate jobs | 4 |
| `StockBalanceTest` | Concurrent writes — row lock prevents race condition (two parallel updates same item), recalculate-balances command restores correct qty from entries | 2 |

### 11.3 Policy Tests

| Test | Scenario |
|---|---|
| `InventoryPolicyTest` | Store manager can create GRN ✓, HOD can only access own department requests ✓, Accountant cannot create PO ✗, Principal cannot approve GRN ✗, Admin can dispose asset ✓ |

### 11.4 Test Data Requirements

**Seeders required in test DB:**
- `InvUomSeeder` (10 UOMs)
- `InvStockGroupSeeder` (10 groups)
- `InvGodownSeeder` (5 godowns)
- `InvAssetCategorySeeder` (5 categories)

**Factories needed:**
- `StockItemFactory` (consumable + asset variants)
- `PurchaseRequisitionFactory` (with line items)
- `PurchaseOrderFactory` (with PO items)
- `GrnFactory` (draft GRN with GRN items)
- `StockIssueFactory` (with issue items)

**Mock strategy:**
- `Event::fake()` — GrnAccepted, StockIssued, StockTransferred, StockAdjusted, AssetDisposed
- `Queue::fake()` — ReorderAlertJob
- `Bus::fake()` — for dispatch assertion
- `acc_vouchers` mock — use factory or implement `VoucherServiceInterface` stub that returns a fake voucher_id; do NOT hit real Accounting module in unit tests

---

## Quality Gate — Phase 1

- [x] All 28 inv_* tables appear in Section 2 (6 masters + 2 stock ledger + 3 vendor + 8 procurement + 4 issue + 2 adjustment + 3 asset = 28)
- [x] All 15 FRs (FR-INV-001 to FR-INV-015) in Section 6
- [x] All 18 business rules (BR-INV-001 to BR-INV-018) in Section 4 with enforcement point
- [x] All 4 FSMs documented with ASCII state diagram and side effects
- [x] All 7 services listed with key method signatures in Section 8
- [x] All 8 integration events documented with payload in Section 9
- [x] `inv_stock_entries.voucher_id → acc_vouchers.id` noted as mandatory NOT NULL (no orphan entries)
- [x] `inv_assets.acc_fixed_asset_id → acc_fixed_assets.id` noted as nullable, synced from Accounting
- [x] `sch_department` (singular) verified as correct table name for department FK
- [x] **No `tenant_id` column** mentioned on any table definition
- [x] `inv_stock_balances` concurrency note: `lockForUpdate()` in StockLedgerService
- [x] `inv_stock_adjustment_items.variance_qty` noted as GENERATED ALWAYS AS computed column
- [x] BR-INV-008 (FIFO batch selection) documented in StockValuationService
- [x] BR-INV-014 (immutable stock entries) enforcement point: service_layer
- [x] Permission matrix covers Admin / Store Mgr / Principal / Accountant / HOD roles
- [x] FK type mismatch noted: sch_* and vnd_* use INT UNSIGNED; acc_* use BIGINT UNSIGNED
- [x] acc_vouchers NOT in current tenant_db_v2.sql — flagged as Accounting dependency (D21)

---

*Generated by Claude Code (Business Analyst + DB Architect) | Phase 1 of 3 | 2026-03-26*
