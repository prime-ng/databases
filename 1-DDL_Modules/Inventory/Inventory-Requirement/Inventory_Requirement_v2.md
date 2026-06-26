# Inventory Module — Detailed Requirement Document v2

**Module:** Inventory & Stock Management | **Laravel Module:** `Modules/Inventory/` | **Prefix:** `inv_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/inventory/*` | **RBS Module:** L — Inventory & Stock Management (50 sub-tasks)
**Date:** 2026-03-19 | **Version:** 2.0

**Changes from v1:** Separate module (not inside Accounting), ALL inventory tables now use `inv_` prefix (not `acc_`), no tenant_id, cross-module references to Accounting (`acc_vouchers`, `acc_tax_rates`, `acc_ledgers`) via FK

---

## 1. Module Overview & Purpose

The Inventory module is a **separate Laravel module** (`Modules/Inventory/`) that manages **school stock and procurement** — from stationery and lab supplies to sports equipment and furniture. It connects to the **Accounting module** via `VoucherServiceInterface` to post purchase vouchers and stock journal entries.

**Core Principle:** Inventory is an **independent module** with its own controllers, models, routes, and views. It consumes the Accounting module's voucher engine — it does NOT own the voucher tables. ALL inventory tables use the `inv_` prefix.

**Indian School Inventory Context:**
- Schools procure consumables (stationery, chalk, cleaning supplies) and assets (computers, furniture, lab equipment)
- Department-wise allocation: Science Lab, Computer Lab, Sports, Library, Administration
- Vendors supply items under rate contracts or one-time purchases
- Stock valuation methods: FIFO, Weighted Average, Last Purchase Cost
- Physical stock audit required annually
- Government-aided schools must maintain stock registers as per regulations
- Storage locations (Godowns): Main Store, Lab Store, Sports Room, Library Store

**Relationship to Other Modules:**
- **Accounting:** Stock movements create Stock Journal / Purchase vouchers via `VoucherServiceInterface`
- **Vendor:** Vendor linkage for item procurement (existing `vnd_vendors`)
- **Accounting Fixed Assets:** Asset-type items link to `acc_fixed_assets` for depreciation
- **SchoolSetup:** Godown in-charge FK → `sch_employees`, department FK → `sch_departments`

**Multi-Tenancy:**
- Dedicated database per tenant — NO `tenant_id` column in any table
- Stock groups and UOMs seeded during tenant provisioning

---

## 2. Scope & Boundaries

### In Scope
- Stock groups (hierarchical categories) — prefix `inv_`
- Units of measurement (UOM) with conversion rules — prefix `inv_`
- Stock items (item master with reorder levels, batch/expiry tracking) — prefix `inv_`
- Godowns / storage locations — prefix `inv_`
- Stock entries (inward/outward/transfer/adjustment) — prefix `inv_`
- Procurement workflow (Purchase Requisition → Purchase Order → GRN) — prefix `inv_`
- Stock issue to departments — prefix `inv_`
- Vendor-item linkage and rate contracts — prefix `inv_`
- Reorder alerts and auto-PR generation
- Stock reports (balance, valuation, consumption, movement)
- Asset vs consumable distinction
- Integration with Accounting voucher engine

### Out of Scope (Handled by Other Modules)
- Vendor master, agreements, vendor rating → **Vendor module** (`vnd_*`)
- Fixed asset register, depreciation → **Accounting module** (`acc_fixed_assets`, `acc_depreciation_entries`)
- Library book inventory → **Library module** (`lib_*`)
- Vehicle parts/fuel → **Transport module** (`tpt_*`)
- Voucher engine (double-entry bookkeeping) → **Accounting** (`acc_vouchers`, `acc_voucher_items`)

---

## 3. RBS Mapping (Module L — 50 Sub-Tasks)

### L1 — Item Master & Categorization (10 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L1.1.1.1 | Define main category and code | `inv_stock_groups.name`, `code` | New |
| ST.L1.1.1.2 | Set parent category | `inv_stock_groups.parent_id` (self-ref) | New |
| ST.L1.1.1.3 | Assign default UOM and tax rules | `inv_stock_groups.default_uom_id` | New |
| ST.L1.1.2.1 | Reorder hierarchy | `inv_stock_groups.sequence` | New |
| ST.L1.1.2.2 | Deactivate category with audit log | `is_active` + activityLog() | New |
| ST.L1.2.1.1 | Enter item name & SKU | `inv_stock_items.name`, `sku` | New |
| ST.L1.2.1.2 | Assign category & UOM | `inv_stock_items.stock_group_id`, `uom_id` | New |
| ST.L1.2.1.3 | Define min/max stock levels | `inv_stock_items.reorder_level`, `reorder_qty`, `min_stock`, `max_stock` | New |
| ST.L1.2.2.1 | Set brand/model | `inv_stock_items.brand`, `model` | New |
| ST.L1.2.2.2 | Enable batch/expiry tracking | `inv_stock_items.has_batch_tracking`, `has_expiry_tracking` | New |

### L2 — Units of Measurement (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L2.1.1.1 | Define UOM name | `inv_units_of_measure.name`, `symbol` | New |
| ST.L2.1.1.2 | Set decimal precision | `inv_units_of_measure.decimal_places` | New |
| ST.L2.2.1.1 | Create conversion factors (BOX → PCS) | `inv_uom_conversions.from_uom_id`, `to_uom_id`, `factor` | New |
| ST.L2.2.1.2 | Set effective dates | `inv_uom_conversions.effective_from`, `effective_to` | New |

### L3 — Vendor & Supplier Linkage (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L3.1.1.1 | Select preferred vendor | `inv_item_vendor_jnt.vendor_id`, `is_preferred` | New |
| ST.L3.1.1.2 | Store last purchase rate | `inv_item_vendor_jnt.last_purchase_rate` | New |
| ST.L3.2.1.1 | Set validity dates | `inv_rate_contracts.valid_from`, `valid_to` | New |
| ST.L3.2.1.2 | Assign item-wise fixed rates | `inv_rate_contract_items_jnt.agreed_rate` | New |

### L4 — Purchase Requisition (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L4.1.1.1 | Select items and quantities | `inv_purchase_requisition_items` | New |
| ST.L4.1.1.2 | Enter required date | `inv_purchase_requisitions.required_date` | New |
| ST.L4.1.2.1 | Upload CSV | Bulk import service | New |
| ST.L4.1.2.2 | Validate PR entries | FormRequest validation | New |

### L5 — Purchase Order (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L5.1.1.1 | Select approved PR lines | `inv_purchase_orders.pr_id` FK | New |
| ST.L5.1.1.2 | Assign supplier & pricing | `inv_purchase_orders.vendor_id`, item pricing | New |
| ST.L5.2.1.1 | Edit quantities | `inv_purchase_order_items.ordered_qty` update | New |
| ST.L5.2.1.2 | Record revision history | Activity log on PO changes | New |

### L6 — Goods Receipt Note (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L6.1.1.1 | Verify items received | `inv_grn_items.received_qty` vs `ordered_qty` | New |
| ST.L6.1.1.2 | Record batch/expiry | `inv_grn_items.batch_number`, `expiry_date` | New |
| ST.L6.2.1.1 | Record pass/fail | `inv_goods_receipt_notes.qc_status` | New |
| ST.L6.2.1.2 | Add QC notes | `inv_goods_receipt_notes.qc_notes` | New |

### L7 — Stock Ledger & Movement (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L7.1.1.1 | Update stock ledger | `inv_stock_entries` (type='inward') + StockLedgerService | New |
| ST.L7.1.1.2 | Record supplier details | `inv_stock_entries.party_ledger_id` (vendor ledger in Accounting) | New |
| ST.L7.2.1.1 | Generate issue slip | Stock entry type='outward' + PDF | New |
| ST.L7.2.1.2 | Record acknowledgment | `inv_stock_issues.acknowledged_by`, `acknowledged_at` | New |

### L8 — Stock Issue / Consumption (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L8.1.1.1 | Select items | `inv_issue_request_items.item_id` | New |
| ST.L8.1.1.2 | Set required quantity | `inv_issue_request_items.requested_qty` | New |
| ST.L8.2.1.1 | Update consumed quantity | StockLedgerService.issueStock() | New |
| ST.L8.2.1.2 | Track per department | `inv_stock_issues.department_id` + cost center in Accounting | New |

### L9 — Reorder Automation (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L9.1.1.1 | Trigger alert when below threshold | ReorderAlertService (compare balance vs reorder_level) | New |
| ST.L9.1.1.2 | Notify store manager | Notification module integration | New |
| ST.L9.2.1.1 | Auto-calc reorder qty | `inv_stock_items.reorder_qty` | New |
| ST.L9.2.1.2 | Assign preferred vendor | `inv_item_vendor_jnt.is_preferred` | New |

### L10 — Asset vs Consumable Handling (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L10.1.1.1 | Assign asset tag | `inv_stock_items.item_type` = 'asset' → link to `acc_fixed_assets` | New |
| ST.L10.1.1.2 | Record warranty info | `inv_stock_items.warranty_months` | New |
| ST.L10.2.1.1 | Record asset movement | Stock entry type='transfer' between godowns | New |
| ST.L10.2.1.2 | Generate transfer slip | Transfer entry PDF | New |

### L11 — Inventory Reports & Analytics (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.L11.1.1.1 | View item-wise stock | InventoryReportService.itemWiseBalance() | New |
| ST.L11.1.1.2 | Export stock data | CSV/Excel export | New |
| ST.L11.2.1.1 | Identify fast-moving items | Consumption analytics (last 3/6/12 months) | New |
| ST.L11.2.1.2 | Predict reorder needs | ReorderAlertService.getAlerts() | New |

---

## 4. Entity List (Tables & Columns)

> **ALL inventory tables use `inv_` prefix.** Cross-references to Accounting tables (`acc_vouchers`, `acc_tax_rates`, `acc_ledgers`, `acc_fixed_assets`) are via FK only.

### 4.1 inv_stock_groups
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | Group name (e.g., "Stationery", "Lab Equipment") |
| code | VARCHAR(20) NULL | Unique group code |
| alias | VARCHAR(100) NULL | Alternative name |
| parent_id | BIGINT UNSIGNED NULL | Self-referencing hierarchy |
| default_uom_id | BIGINT UNSIGNED NULL FK | FK → inv_units_of_measure |
| sequence | INT | Display order |
| is_system | TINYINT(1) | Cannot delete seeded groups |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.2 inv_units_of_measure
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(50) | e.g., "Pieces", "Kilograms" |
| symbol | VARCHAR(10) | e.g., "Pcs", "Kg" |
| decimal_places | TINYINT | Precision (0 for Pcs, 2 for Kg) |
| is_system | TINYINT(1) | Cannot delete seeded records |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.3 inv_uom_conversions
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| from_uom_id | BIGINT UNSIGNED FK | FK → inv_units_of_measure |
| to_uom_id | BIGINT UNSIGNED FK | FK → inv_units_of_measure |
| conversion_factor | DECIMAL(15,6) | 1 from_uom = X to_uom |
| effective_from | DATE NULL | Valid from |
| effective_to | DATE NULL | Valid until |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.4 inv_stock_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(150) | Item name |
| sku | VARCHAR(50) NULL UNIQUE | Stock Keeping Unit |
| alias | VARCHAR(150) NULL | Alternative name |
| stock_group_id | BIGINT UNSIGNED FK | FK → inv_stock_groups |
| uom_id | BIGINT UNSIGNED FK | FK → inv_units_of_measure |
| item_type | ENUM('consumable','asset') | Consumable vs capital item |
| opening_balance_qty | DECIMAL(15,3) | Opening stock quantity |
| opening_balance_rate | DECIMAL(15,2) | Opening rate per unit |
| opening_balance_value | DECIMAL(15,2) | Total opening value |
| valuation_method | ENUM('fifo','weighted_average','last_purchase') | Stock valuation |
| reorder_level | DECIMAL(15,3) NULL | Alert when stock falls below |
| reorder_qty | DECIMAL(15,3) NULL | Quantity to reorder |
| min_stock | DECIMAL(15,3) NULL | Minimum stock level |
| max_stock | DECIMAL(15,3) NULL | Maximum stock level |
| has_batch_tracking | TINYINT(1) | Track batch numbers |
| has_expiry_tracking | TINYINT(1) | Track expiry dates |
| hsn_sac_code | VARCHAR(20) NULL | HSN/SAC code for GST |
| brand | VARCHAR(100) NULL | Brand name |
| model | VARCHAR(100) NULL | Model number |
| warranty_months | INT NULL | Warranty period |
| tax_rate_id | BIGINT UNSIGNED NULL FK | FK → **acc_tax_rates** (from Accounting module) |
| purchase_ledger_id | BIGINT UNSIGNED NULL FK | FK → **acc_ledgers** (Purchase A/c in Accounting) |
| sales_ledger_id | BIGINT UNSIGNED NULL FK | FK → **acc_ledgers** (Sales A/c in Accounting) |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.5 inv_godowns
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Main Store", "Lab Store" |
| code | VARCHAR(20) NULL | Location code |
| parent_id | BIGINT UNSIGNED NULL | Self-referencing (sub-godowns) |
| address | VARCHAR(500) NULL | Physical location |
| in_charge_employee_id | BIGINT UNSIGNED NULL FK | FK → **sch_employees** (store keeper) |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.6 inv_stock_entries
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| stock_item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| godown_id | BIGINT UNSIGNED FK | FK → inv_godowns |
| voucher_id | BIGINT UNSIGNED FK | FK → **acc_vouchers** (ALWAYS linked to Accounting) |
| entry_type | ENUM('inward','outward','transfer_in','transfer_out','adjustment') | Movement type |
| quantity | DECIMAL(15,3) | Quantity moved |
| rate | DECIMAL(15,2) | Rate per unit |
| amount | DECIMAL(15,2) | Total value (qty x rate) |
| batch_number | VARCHAR(50) NULL | Batch tracking |
| expiry_date | DATE NULL | Expiry tracking |
| destination_godown_id | BIGINT UNSIGNED NULL FK | For transfers: target godown |
| party_ledger_id | BIGINT UNSIGNED NULL FK | FK → **acc_ledgers** (vendor/dept ledger in Accounting) |
| narration | VARCHAR(500) NULL | Notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.7 inv_item_vendor_jnt
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| vendor_id | BIGINT UNSIGNED FK | FK → **vnd_vendors** (from Vendor module) |
| vendor_sku | VARCHAR(50) NULL | Vendor's item code |
| last_purchase_rate | DECIMAL(15,2) NULL | Last price paid |
| last_purchase_date | DATE NULL | Last purchase date |
| lead_time_days | INT NULL | Delivery lead time |
| is_preferred | TINYINT(1) | Preferred vendor for this item |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.8 inv_rate_contracts
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| vendor_id | BIGINT UNSIGNED FK | FK → **vnd_vendors** |
| contract_number | VARCHAR(50) NULL | Reference number |
| valid_from | DATE | Contract start |
| valid_to | DATE | Contract end |
| status | ENUM('draft','active','expired','cancelled') | Contract status |
| remarks | TEXT NULL | Notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.9 inv_rate_contract_items_jnt
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| rate_contract_id | BIGINT UNSIGNED FK | FK → inv_rate_contracts (CASCADE) |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| agreed_rate | DECIMAL(15,2) | Contracted price |
| min_qty | DECIMAL(15,3) NULL | Minimum order |
| max_qty | DECIMAL(15,3) NULL | Maximum order |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.10 inv_purchase_requisitions
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| pr_number | VARCHAR(50) UNIQUE | Auto-generated PR number |
| requested_by | BIGINT UNSIGNED FK | FK → sys_users |
| department_id | BIGINT UNSIGNED NULL FK | FK → **sch_departments** |
| required_date | DATE | Items needed by |
| priority | ENUM('low','normal','high','urgent') | Priority level |
| status | ENUM('draft','submitted','approved','rejected','converted','cancelled') | Workflow |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| approved_at | TIMESTAMP NULL | Approval time |
| remarks | TEXT NULL | Notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.11 inv_purchase_requisition_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| pr_id | BIGINT UNSIGNED FK | FK → inv_purchase_requisitions (CASCADE) |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| qty | DECIMAL(15,3) | Requested quantity |
| uom_id | BIGINT UNSIGNED FK | FK → inv_units_of_measure |
| estimated_rate | DECIMAL(15,2) NULL | Estimated unit cost |
| remarks | VARCHAR(255) NULL | Item-specific notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.12 inv_purchase_orders
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| po_number | VARCHAR(50) UNIQUE | Auto-generated PO number |
| vendor_id | BIGINT UNSIGNED FK | FK → **vnd_vendors** |
| pr_id | BIGINT UNSIGNED NULL FK | FK → inv_purchase_requisitions (if from PR) |
| order_date | DATE | PO date |
| expected_delivery_date | DATE NULL | Expected delivery |
| status | ENUM('draft','sent','partial','received','cancelled','closed') | Lifecycle |
| total_amount | DECIMAL(15,2) | Pre-tax total |
| tax_amount | DECIMAL(15,2) | Total tax |
| discount_amount | DECIMAL(15,2) NULL | Total discount |
| net_amount | DECIMAL(15,2) | Final payable |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → **acc_vouchers** (Purchase Voucher in Accounting) |
| terms_and_conditions | TEXT NULL | PO terms |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.13 inv_purchase_order_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| po_id | BIGINT UNSIGNED FK | FK → inv_purchase_orders (CASCADE) |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| ordered_qty | DECIMAL(15,3) | Ordered quantity |
| received_qty | DECIMAL(15,3) DEFAULT 0 | Received so far (updated on GRN) |
| unit_price | DECIMAL(15,2) | Unit cost |
| tax_rate_id | BIGINT UNSIGNED NULL FK | FK → **acc_tax_rates** |
| discount_percent | DECIMAL(5,2) NULL | Discount % |
| total_amount | DECIMAL(15,2) | Line total |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.14 inv_goods_receipt_notes
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| grn_number | VARCHAR(50) UNIQUE | Auto-generated GRN number |
| po_id | BIGINT UNSIGNED FK | FK → inv_purchase_orders |
| vendor_id | BIGINT UNSIGNED FK | FK → **vnd_vendors** |
| receipt_date | DATE | Date received |
| godown_id | BIGINT UNSIGNED FK | FK → inv_godowns |
| status | ENUM('draft','inspected','accepted','partial','rejected') | QC workflow |
| qc_status | ENUM('pending','passed','failed','partial') | Quality check |
| qc_notes | TEXT NULL | QC remarks |
| received_by | BIGINT UNSIGNED FK | FK → sys_users |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → **acc_vouchers** (Purchase Voucher on accept) |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.15 inv_grn_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| grn_id | BIGINT UNSIGNED FK | FK → inv_goods_receipt_notes (CASCADE) |
| po_item_id | BIGINT UNSIGNED FK | FK → inv_purchase_order_items |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| received_qty | DECIMAL(15,3) | Quantity received |
| accepted_qty | DECIMAL(15,3) | Accepted after QC |
| rejected_qty | DECIMAL(15,3) DEFAULT 0 | Rejected after QC |
| unit_cost | DECIMAL(15,2) | Actual unit cost |
| batch_number | VARCHAR(50) NULL | Batch tracking |
| expiry_date | DATE NULL | Expiry tracking |
| qc_remarks | VARCHAR(255) NULL | Per-item QC notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.16 inv_issue_requests
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| request_number | VARCHAR(50) UNIQUE | Auto-generated |
| requested_by | BIGINT UNSIGNED FK | FK → sys_users |
| department_id | BIGINT UNSIGNED FK | FK → **sch_departments** |
| required_date | DATE | Items needed by |
| status | ENUM('submitted','approved','issued','partial','rejected') | Workflow |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| remarks | TEXT NULL | Notes |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.17 inv_issue_request_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| issue_request_id | BIGINT UNSIGNED FK | FK → inv_issue_requests (CASCADE) |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| requested_qty | DECIMAL(15,3) | Requested |
| issued_qty | DECIMAL(15,3) DEFAULT 0 | Actually issued |
| uom_id | BIGINT UNSIGNED FK | FK → inv_units_of_measure |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.18 inv_stock_issues
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| issue_number | VARCHAR(50) UNIQUE | Auto-generated |
| issue_request_id | BIGINT UNSIGNED NULL FK | FK → inv_issue_requests |
| godown_id | BIGINT UNSIGNED FK | FK → inv_godowns |
| issued_by | BIGINT UNSIGNED FK | FK → sys_users |
| issued_to_employee_id | BIGINT UNSIGNED NULL FK | FK → **sch_employees** |
| department_id | BIGINT UNSIGNED FK | FK → **sch_departments** |
| issue_date | DATE | Issue date |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → **acc_vouchers** (Stock Journal in Accounting) |
| acknowledged_by | BIGINT UNSIGNED NULL | Receiver's confirmation |
| acknowledged_at | TIMESTAMP NULL | Acknowledgment time |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

### 4.19 inv_stock_issue_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| stock_issue_id | BIGINT UNSIGNED FK | FK → inv_stock_issues (CASCADE) |
| item_id | BIGINT UNSIGNED FK | FK → inv_stock_items |
| qty | DECIMAL(15,3) | Issued quantity |
| unit_cost | DECIMAL(15,2) | Cost per unit (from valuation) |
| batch_number | VARCHAR(50) NULL | Batch |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

---

## 5. Procurement Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Purchase    │     │  Purchase   │     │   Goods     │     │   Stock     │
│ Requisition  │────>│   Order     │────>│  Receipt    │────>│   Entry     │
│   (PR)       │     │   (PO)      │     │  Note (GRN) │     │ (Inward)    │
│              │     │             │     │             │     │             │
│ Draft        │     │ Draft       │     │ Draft       │     │ Creates     │
│ →Submitted   │     │ →Sent       │     │ →Inspected  │     │ Purchase    │
│ →Approved    │     │ →Partial    │     │ →Accepted   │     │ Voucher     │
│ →Converted   │     │ →Received   │     │             │     │ (Accounting)│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Issue      │     │   Stock     │     │   Stock     │
│  Request     │────>│   Issue     │────>│   Entry     │
│              │     │             │     │ (Outward)   │
│ Submitted    │     │ Creates     │     │             │
│ →Approved    │     │ issue slip  │     │ Creates     │
│ →Issued      │     │ + ack.      │     │ Stock Jrnl  │
│              │     │             │     │ (Accounting)│
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 6. Business Rules

1. **Stock Entry ↔ Voucher Linkage:** Every `inv_stock_entries` record MUST have a `voucher_id` pointing to `acc_vouchers`. No orphan stock movements.
2. **Stock Valuation:** Configurable per item — FIFO, Weighted Average, or Last Purchase Cost.
3. **Reorder Alert:** When current_stock <= reorder_level, trigger alert. Auto-generate PR if configured.
4. **GRN QC Gate:** Stock is NOT added to ledger until GRN status = 'accepted'.
5. **PO ↔ GRN Matching:** `received_qty` on PO items updated when GRN is accepted. PO auto-closes when all items fully received.
6. **PR → PO Conversion:** Approved PR lines can be converted to PO. PR status changes to 'converted'.
7. **Issue Request Approval:** Items cannot be issued without approved request (except direct issue by Store Keeper).
8. **Negative Stock Prevention:** Stock issue rejected if available quantity < requested quantity.
9. **Batch/Expiry FIFO:** When batch tracking enabled, outward entries use oldest batch first.
10. **Asset Items:** Items with `item_type = 'asset'` should also create `acc_fixed_assets` entry (in Accounting) on GRN acceptance.
11. **No tenant_id:** Dedicated database per tenant — data isolation at DB level.
12. **Cross-module FKs:** `acc_vouchers`, `acc_tax_rates`, `acc_ledgers` are owned by Accounting module. Inventory references them via FK, never modifies them directly.

---

## 7. Integration Points

| Direction | Source | Target | Mechanism |
|-----------|--------|--------|-----------|
| GRN → Accounting | GRN Accepted | Purchase Voucher (Dr Stock-in-Hand, Cr Vendor Creditor) | `VoucherServiceInterface` |
| Issue → Accounting | Stock Issued | Stock Journal (Dr Dept Consumption, Cr Stock-in-Hand) | `VoucherServiceInterface` |
| Transfer → Accounting | Stock Transfer | Stock Journal (Dr Dest Godown, Cr Source Godown) | `VoucherServiceInterface` |
| Adjustment → Accounting | Stock Adjustment | Journal (Dr/Cr Stock-in-Hand, Cr/Dr Stock Adjustment A/c) | `VoucherServiceInterface` |
| Inventory → Vendor | Purchase Order | References `vnd_vendors` for supplier | FK reference |
| Inventory → Fixed Assets | Asset-type GRN | Creates `acc_fixed_assets` entry (in Accounting) | Service call |
| Inventory → SchoolSetup | Godown in-charge | References `sch_employees` | FK reference |
| Inventory → SchoolSetup | Issue department | References `sch_departments` | FK reference |
| Reorder → Notification | Below reorder_level | Alert to store manager | Notification event |

---

## 8. Reports

| Report | Description | Parameters |
|--------|-------------|------------|
| Stock Balance | Current stock per item per godown | Godown, Group, Date |
| Stock Valuation | Total value of inventory (by valuation method) | As on date |
| Stock Ledger | Movement history for an item | Item, Date range |
| Consumption Report | Department-wise consumption | Department, Date range |
| Purchase Register | All purchases (PO-wise) | Vendor, Date range |
| Pending PO Report | Outstanding PO items not yet received | Vendor, Status |
| GRN Register | All goods receipts | Date range |
| Reorder Alert Report | Items below reorder level | Current |
| Fast-Moving Items | Top-N consumed items | Period (3/6/12 months) |
| Slow-Moving Items | Items with no movement in period | Period |
| Expiry Alert | Items expiring within N days | Days threshold |
| Godown-wise Stock | Stock by storage location | Godown |

---

## 9. Seed Data

### Stock Groups (10 records)
| Name | Parent | Type |
|------|--------|------|
| Stationery | — | Consumable |
| Lab Equipment | — | Asset |
| Sports Equipment | — | Mixed |
| Furniture | — | Asset |
| Cleaning Supplies | — | Consumable |
| IT Equipment | — | Asset |
| Books & Journals | — | Consumable |
| Electrical Items | — | Mixed |
| Uniforms & Textiles | — | Consumable |
| Miscellaneous | — | Consumable |

### Units of Measure (10 records)
Pieces (Pcs, 0), Kilograms (Kg, 2), Litres (Ltr, 2), Box (Box, 0), Ream (Ream, 0), Set (Set, 0), Pair (Pair, 0), Bottles (Btl, 0), Metres (Mtr, 2), Numbers (Nos, 0)

### Godowns (5 records)
Main Store, Lab Store, Sports Room, Library Store, IT Room

---

## 10. User Roles & Permissions

| Role | Permissions |
|------|------------|
| School Admin | Full inventory access |
| Store Keeper | Item master, stock entries, GRN, issue, reports |
| Department Head | Issue requests for own department |
| Accountant | View stock reports, valuations (read-only) |

**Permission strings:**
```
inventory.stock-group.viewAny/create/update/delete
inventory.stock-item.viewAny/create/update/delete
inventory.uom.viewAny/create/update/delete
inventory.godown.viewAny/create/update/delete
inventory.purchase-requisition.viewAny/create/approve
inventory.purchase-order.viewAny/create/approve
inventory.grn.viewAny/create/accept/reject
inventory.stock-issue.viewAny/create
inventory.issue-request.viewAny/create/approve
inventory.rate-contract.viewAny/create/update
inventory.stock-entry.viewAny/create
inventory.report.view
```

---

## 11. Controllers & Services Summary

### Controllers (14)
StockGroupController, UomController, StockItemController, GodownController, StockEntryController, ItemVendorController, RateContractController, PurchaseRequisitionController, PurchaseOrderController, GrnController, IssueRequestController, StockIssueController, InvReportController, InvDashboardController

### Services (6)
StockLedgerService (post movements → VoucherServiceInterface), PurchaseOrderService (PR→PO conversion), GrnPostingService (GRN accept → stock + Accounting voucher), ReorderAlertService (check thresholds, auto-PR), StockValuationService (FIFO/WA/LP calculation), InventoryReportService (all reports + analytics)

### FormRequests (~12)
Store/Update for: StockGroup, UOM, StockItem, Godown, PurchaseRequisition, PurchaseOrder, GRN, IssueRequest, StockIssue, RateContract, StockEntry

---

## 12. Dependencies

| This Module Needs | From Module | Entities |
|-------------------|------------|----------|
| Voucher Posting | Accounting | `VoucherServiceInterface`, `acc_vouchers` |
| Tax Rates | Accounting | `acc_tax_rates` (FK on items and PO lines) |
| Ledgers | Accounting | `acc_ledgers` (purchase/sales ledger, vendor/dept ledger) |
| Fixed Assets | Accounting | `acc_fixed_assets` (for asset-type items) |
| Vendors | Vendor | `vnd_vendors` (supplier reference) |
| Employees | SchoolSetup | `sch_employees` (godown in-charge, issued-to) |
| Departments | SchoolSetup | `sch_departments` (PR/issue department) |
| Users | System | `sys_users` (created_by, approved_by, requested_by) |

---

## 13. Table Summary

| Category | Count | Tables |
|----------|-------|--------|
| Stock Masters | 5 | inv_stock_groups, inv_units_of_measure, inv_uom_conversions, inv_stock_items, inv_godowns |
| Stock Movement | 1 | inv_stock_entries |
| Vendor Linkage | 3 | inv_item_vendor_jnt, inv_rate_contracts, inv_rate_contract_items_jnt |
| Procurement | 4 | inv_purchase_requisitions, inv_purchase_requisition_items, inv_purchase_orders, inv_purchase_order_items |
| Goods Receipt | 2 | inv_goods_receipt_notes, inv_grn_items |
| Stock Issue | 4 | inv_issue_requests, inv_issue_request_items, inv_stock_issues, inv_stock_issue_items |
| **Total** | **19** | All `inv_` prefix |
