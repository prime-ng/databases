# Inventory Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Greenfield RBS-Only)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** INV | **Module Path:** `Modules/Inventory/`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `inv_*`
**Processing Mode:** RBS_ONLY — Greenfield (No code, no DDL exists)
**RBS Reference:** Module L — Inventory & Stock Management (50 sub-tasks, lines 3016–3146)
**Source v4:** `1-DDL_Tenant_Modules/65-Inventory_/Claude_Plan/Inventory_Requirement_v4.md`

> All features are **❌ Not Started**. All proposed items are marked **📐**.

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Database Schema](#6-database-schema)
7. [API and Routes](#7-api-and-routes)
8. [Business Rules](#8-business-rules)
9. [Authorization and RBAC](#9-authorization-and-rbac)
10. [Service Layer Architecture](#10-service-layer-architecture)
11. [Integration Points](#11-integration-points)
12. [Test Coverage](#12-test-coverage)
13. [Implementation Status](#13-implementation-status)
14. [Known Issues and Technical Debt](#14-known-issues-and-technical-debt)
15. [Development Priorities and Recommendations](#15-development-priorities-and-recommendations)

---

## 1. Module Overview

The Inventory module is a comprehensive school stock and procurement management system for Indian K-12 schools operating on the Prime-AI SaaS ERP platform. It manages the complete lifecycle of school assets and consumables — from item master setup and purchase requisition to goods receipt, stock issue to departments, and accounting integration.

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Inventory & Stock Management |
| Module Code | INV |
| nwidart Module Namespace | `Modules\Inventory` |
| Module Path | `Modules/Inventory/` |
| Route Prefix | `inventory/` |
| Route Name Prefix | `inventory.` |
| DB Table Prefix | `inv_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |
| Status | 📐 Greenfield — Not Started |

### 1.2 Module Scale (Proposed)

| Metric | Count |
|---|---|
| Controllers | 📐 14 |
| Models | 📐 19 |
| Services | 📐 6 |
| FormRequests | 📐 12 |
| Policies | 📐 12 |
| DDL Tables | 📐 19 (`inv_*` prefix) |
| Views | 📐 ~60 Blade templates |
| Seeders | 📐 3 (StockGroups, UnitsOfMeasure, Godowns) |

---

## 2. Business Context

### 2.1 Business Purpose

Indian schools procure and consume a wide variety of materials — from stationery and cleaning supplies to laboratory equipment, furniture, and IT hardware. Without a structured system, schools face:

1. **Uncontrolled Stock Loss**: Items disappear without records of who took them or why.
2. **Procurement Inefficiency**: Purchases are duplicated or missed because no one knows current stock levels.
3. **No Valuation Visibility**: Administration cannot report on the total monetary value of inventory held.
4. **Regulatory Compliance Failure**: Government-aided schools must maintain stock registers as per state and central government regulations.
5. **Budget Overruns**: Departments over-requisition because there is no department-wise consumption tracking.
6. **Vendor Management Gap**: Rate contracts and preferred vendor pricing are lost in paper-based systems.

The Inventory module solves these problems by providing a complete electronic stock management workflow — from purchase requisition through goods receipt and departmental stock issue — with full accounting integration via the VoucherServiceInterface.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| School Admin | Full inventory access, approval workflows |
| Store Keeper | Item master, GRN, stock entries, issues, reports |
| Department Head | Submit issue requests for own department |
| Accountant | View stock reports, valuations (read-only) |
| Principal | Dashboard, analytics, reorder alerts |

### 2.3 Indian School Context

- **Item categories**: Stationery (chalk, paper, pens), Lab Equipment (microscopes, chemicals), Sports Equipment (balls, nets, mats), Furniture (desks, chairs, almirahs), Cleaning Supplies (detergent, mops), IT Equipment (computers, projectors, printers), Uniforms & Textiles, Books & Journals
- **Storage Locations (Godowns)**: Main Store, Lab Store, Sports Room, Library Store, IT Room
- **Departments**: Science Lab, Computer Lab, Sports, Library, Administration, each with own consumption budgets
- **Valuation Methods**: FIFO, Weighted Average, Last Purchase Cost — school choice per item
- **Physical Stock Audit**: Annual requirement; system vs physical count discrepancy must be recorded
- **Government-Aided Schools**: Must maintain stock registers in prescribed formats (printed PDF export required)
- **GST Compliance**: HSN/SAC codes on items, tax rate capture on purchase orders
- **Rate Contracts**: Annual contracts with suppliers at fixed rates reduce ad-hoc procurement costs

---

## 3. Scope and Boundaries

### 3.1 In-Scope Features

- Stock group (category) management — hierarchical with parent-child support
- Units of measurement (UOM) with decimal precision and conversion rules
- Stock item master — consumables and assets, with batch/expiry tracking, reorder levels
- Godown (storage location) management with sub-godown hierarchy
- Complete procurement workflow: Purchase Requisition (PR) → Purchase Order (PO) → Goods Receipt Note (GRN) → Stock Entry
- Quality check process on GRN acceptance
- Stock issue workflow: Issue Request → Stock Issue → Stock Entry (outward)
- Vendor-item linkage with preferred vendor and last purchase rate tracking
- Rate contract management with item-wise fixed rates and validity dates
- Stock transfer between godowns
- Stock adjustment (physical count reconciliation, write-off)
- Reorder alert automation with configurable thresholds
- Auto-generation of Purchase Requisitions when stock falls below reorder level
- Barcode/QR label printing for items
- Asset vs consumable distinction with warranty tracking
- Stock valuation: FIFO, Weighted Average, Last Purchase Cost
- Full accounting integration via `VoucherServiceInterface`
- Reports: Stock Balance, Stock Ledger, Consumption, Purchase Register, GRN Register, Reorder Alerts, Fast/Slow movers, Expiry alerts
- CSV/Excel export for all reports
- Seeded stock groups, UOMs, and godowns on tenant provisioning

### 3.2 Out of Scope

- Vendor master, vendor agreements, vendor rating — handled by **Vendor module** (`vnd_*`)
- Fixed asset register, depreciation tracking — handled by **Accounting module** (`acc_fixed_assets`)
- Library book inventory — handled by **Library module** (`lib_*`)
- Vehicle parts, fuel, maintenance — handled by **Transport module** (`tpt_*`)
- Voucher engine (double-entry bookkeeping) — owned by **Accounting module** (`acc_vouchers`)
- Online procurement (external e-procurement portal integration)
- Vendor payment processing
- Mess/cafeteria food inventory (handled separately by Mess Management module)

---

## 4. Functional Requirements

### 4.1 L1 — Item Master & Categorization

**RBS Ref:** F.L1.1 — Item Categories, F.L1.2 — Item Master

#### FR-INV-001: Stock Group (Category) Management 📐

Stock groups form a hierarchical tree of item categories seeded during tenant creation and extendable by the school.

- 📐 **Create Stock Group**: Name (required, max 100 chars), unique code (optional, max 20 chars), alias, parent group (optional — supports multi-level hierarchy), default UOM (FK to `inv_units_of_measure`), display sequence, is_system flag (seeded groups cannot be deleted)
- 📐 **Hierarchy Management**: Parent-child relationships support unlimited nesting; display order via `sequence` column
- 📐 **Deactivate with Audit Log**: `is_active` soft-disable; activity log recorded via `sys_activity_logs`
- 📐 **Seeded Groups (10)**: Stationery, Lab Equipment, Sports Equipment, Furniture, Cleaning Supplies, IT Equipment, Books & Journals, Electrical Items, Uniforms & Textiles, Miscellaneous

| RBS Sub-Task | Status |
|---|---|
| ST.L1.1.1.1 — Define main category and code | 📐 Not Started |
| ST.L1.1.1.2 — Set parent category | 📐 Not Started |
| ST.L1.1.1.3 — Assign default UOM | 📐 Not Started |
| ST.L1.1.2.1 — Reorder hierarchy | 📐 Not Started |
| ST.L1.1.2.2 — Deactivate with audit log | 📐 Not Started |

#### FR-INV-002: Stock Item Master 📐

The item master catalog defines every procurable and issuable item in the school.

- 📐 **Create Item**: Name (required, max 150 chars), SKU (unique, optional), alias, stock group (required FK), UOM (required FK), item type (consumable / asset)
- 📐 **Stock Levels**: Reorder level, reorder quantity, minimum stock, maximum stock — all decimal(15,3)
- 📐 **Attributes**: Brand, model, HSN/SAC code for GST, warranty months (for assets)
- 📐 **Batch/Expiry Tracking**: Per-item toggle for batch number tracking and expiry date tracking
- 📐 **Valuation Method**: Configurable per item — FIFO, Weighted Average, or Last Purchase Cost
- 📐 **Opening Balance**: Opening stock quantity, rate, and total value for tenant onboarding
- 📐 **Accounting Linkage**: purchase_ledger_id (FK → acc_ledgers), sales_ledger_id (FK → acc_ledgers), tax_rate_id (FK → acc_tax_rates)
- 📐 **Asset Items**: item_type = 'asset' triggers creation of `acc_fixed_assets` entry in Accounting on GRN acceptance

| RBS Sub-Task | Status |
|---|---|
| ST.L1.2.1.1 — Enter item name & SKU | 📐 Not Started |
| ST.L1.2.1.2 — Assign category & UOM | 📐 Not Started |
| ST.L1.2.1.3 — Define min/max stock levels | 📐 Not Started |
| ST.L1.2.2.1 — Set brand/model | 📐 Not Started |
| ST.L1.2.2.2 — Enable batch/expiry tracking | 📐 Not Started |

### 4.2 L2 — Units of Measurement (UOM)

**RBS Ref:** F.L2.1 — UOM Master, F.L2.2 — Conversion Rules

#### FR-INV-003: UOM Master 📐

- 📐 **Create UOM**: Name (required, max 50 chars), symbol (required, max 10 chars), decimal places (0–4 precision)
- 📐 **is_system Flag**: Seeded UOMs cannot be deleted
- 📐 **Seeded UOMs (10)**: Pieces (Pcs, 0), Kilograms (Kg, 2), Litres (Ltr, 2), Box (Box, 0), Ream (Ream, 0), Set (Set, 0), Pair (Pair, 0), Bottles (Btl, 0), Metres (Mtr, 2), Numbers (Nos, 0)

#### FR-INV-004: UOM Conversion Rules 📐

- 📐 **Conversion Factor**: Define factor between two UOMs (e.g., 1 Box = 10 Pcs; factor = 10.000000)
- 📐 **Effective Dates**: Optional valid-from and valid-to dates for seasonal or contract-specific conversions
- 📐 **Bidirectional Use**: Conversion can be applied in both directions by dividing the factor

| RBS Sub-Task | Status |
|---|---|
| ST.L2.1.1.1 — Define UOM name | 📐 Not Started |
| ST.L2.1.1.2 — Set decimal precision | 📐 Not Started |
| ST.L2.2.1.1 — Create conversion factors (BOX → PCS) | 📐 Not Started |
| ST.L2.2.1.2 — Set effective dates | 📐 Not Started |

### 4.3 L3 — Vendor & Supplier Linkage

**RBS Ref:** F.L3.1 — Vendor Assignment, F.L3.2 — Rate Contracts

#### FR-INV-005: Item-Vendor Linkage 📐

- 📐 **Assign Vendor to Item**: Multiple vendors can supply the same item; one marked as preferred
- 📐 **Track Last Purchase**: Auto-updated on GRN acceptance: last purchase rate and date
- 📐 **Vendor SKU**: Store vendor's own item code for cross-reference on PO generation
- 📐 **Lead Time**: Delivery lead time in days — used for reorder date calculation

#### FR-INV-006: Rate Contracts 📐

- 📐 **Create Rate Contract**: Vendor-level contract with contract number, validity dates, status workflow (draft → active → expired/cancelled)
- 📐 **Item-wise Fixed Rates**: Line items on contract defining agreed rate, minimum and maximum order quantities per item
- 📐 **Contract Expiry Alert**: Notify store manager when active rate contract is within 30 days of expiry

| RBS Sub-Task | Status |
|---|---|
| ST.L3.1.1.1 — Select preferred vendor | 📐 Not Started |
| ST.L3.1.1.2 — Store last purchase rate | 📐 Not Started |
| ST.L3.2.1.1 — Set validity dates | 📐 Not Started |
| ST.L3.2.1.2 — Assign item-wise fixed rates | 📐 Not Started |

### 4.4 L4 — Purchase Requisition (PR)

**RBS Ref:** F.L4.1 — PR Creation

#### FR-INV-007: Purchase Requisition Workflow 📐

- 📐 **Create PR**: Auto-generated PR number, department (FK → sch_department), requested by (FK → sys_users), required date, priority (low/normal/high/urgent)
- 📐 **PR Line Items**: Multiple items per PR; each line has: item, quantity, UOM, estimated rate, remarks
- 📐 **Status Workflow**: Draft → Submitted → Approved/Rejected → Converted (to PO) / Cancelled
- 📐 **Approval Action**: Designated approver can approve or reject PR; rejected PRs require rejection reason
- 📐 **Bulk CSV Import**: Upload CSV with columns [item_code, quantity, estimated_rate, remarks]; validate and create PR items in bulk
- 📐 **Bulk Validation**: Pre-import validation report showing invalid rows with error descriptions before final import

| RBS Sub-Task | Status |
|---|---|
| ST.L4.1.1.1 — Select items and quantities | 📐 Not Started |
| ST.L4.1.1.2 — Enter required date | 📐 Not Started |
| ST.L4.1.2.1 — Upload CSV | 📐 Not Started |
| ST.L4.1.2.2 — Validate PR entries | 📐 Not Started |

### 4.5 L5 — Purchase Order (PO)

**RBS Ref:** F.L5.1 — PO Creation, F.L5.2 — PO Lifecycle

#### FR-INV-008: Purchase Order Management 📐

- 📐 **Convert PR to PO**: Select approved PR lines; system pre-fills vendor (from preferred vendor linkage) and pricing (from active rate contract if available)
- 📐 **Direct PO Creation**: PO without PR for emergency/unplanned purchases
- 📐 **PO Details**: Auto-generated PO number, vendor (required), PO date, expected delivery date, terms and conditions
- 📐 **PO Line Items**: Item, ordered quantity, unit price, tax rate, discount percent, total amount; totals auto-calculated
- 📐 **Status Workflow**: Draft → Sent (to vendor) → Partial (some items received) → Received (fully received) → Closed / Cancelled
- 📐 **Revision History**: Activity log on every PO modification; version-stamped remarks
- 📐 **Received Quantity Tracking**: `received_qty` on each PO item updated automatically when GRN is accepted

| RBS Sub-Task | Status |
|---|---|
| ST.L5.1.1.1 — Select approved PR lines | 📐 Not Started |
| ST.L5.1.1.2 — Assign supplier & pricing | 📐 Not Started |
| ST.L5.2.1.1 — Edit quantities | 📐 Not Started |
| ST.L5.2.1.2 — Record revision history | 📐 Not Started |

### 4.6 L6 — Goods Receipt Note (GRN)

**RBS Ref:** F.L6.1 — GRN Processing, F.L6.2 — Quality Check

#### FR-INV-009: Goods Receipt Note (GRN) 📐

- 📐 **Create GRN**: Auto-generated GRN number, linked PO (required), vendor, receipt date, receiving godown
- 📐 **GRN Line Items**: Per PO line — received quantity, accepted quantity, rejected quantity, actual unit cost, batch number (if batch-tracked), expiry date (if expiry-tracked), per-item QC remarks
- 📐 **QC Process**: GRN-level QC status (pending → passed/failed/partial); QC notes field
- 📐 **Status Workflow**: Draft → Inspected → Accepted/Partial/Rejected
- 📐 **GRN Accept Action**: Triggers stock entry (inward) + accounting Purchase Voucher via VoucherServiceInterface
- 📐 **Partial GRN**: GRN can be partially accepted; PO status moves to 'partial'; subsequent GRNs can be created against same PO
- 📐 **PO Close Detection**: When cumulative received_qty equals ordered_qty for all PO items, PO auto-transitions to 'received'

| RBS Sub-Task | Status |
|---|---|
| ST.L6.1.1.1 — Verify items received | 📐 Not Started |
| ST.L6.1.1.2 — Record batch/expiry | 📐 Not Started |
| ST.L6.2.1.1 — Record pass/fail | 📐 Not Started |
| ST.L6.2.1.2 — Add QC notes | 📐 Not Started |

### 4.7 L7 — Stock Ledger & Movement

**RBS Ref:** F.L7.1 — Stock Inward, F.L7.2 — Stock Outward

#### FR-INV-010: Stock Entry Ledger 📐

The `inv_stock_entries` table is the central journal of all stock movements — every entry has a corresponding accounting voucher.

- 📐 **Entry Types**: inward (GRN acceptance), outward (issue), transfer_in, transfer_out, adjustment
- 📐 **Mandatory Voucher Link**: Every stock entry MUST reference an `acc_vouchers` record — no orphan movements
- 📐 **Batch/Expiry on Movement**: Batch number and expiry date carried through from GRN to issue entries
- 📐 **Party Ledger**: Supplier ledger on inward, department cost-center ledger on outward, via `acc_ledgers`
- 📐 **Issue Slip PDF**: Outward entries generate a printable issue slip (DomPDF); includes acknowledgment signature field
- 📐 **Acknowledgment Capture**: Receiver can acknowledge issue (acknowledged_by, acknowledged_at)

| RBS Sub-Task | Status |
|---|---|
| ST.L7.1.1.1 — Update stock ledger | 📐 Not Started |
| ST.L7.1.1.2 — Record supplier details | 📐 Not Started |
| ST.L7.2.1.1 — Generate issue slip | 📐 Not Started |
| ST.L7.2.1.2 — Record acknowledgment | 📐 Not Started |

### 4.8 L8 — Stock Issue / Consumption

**RBS Ref:** F.L8.1 — Issue Request, F.L8.2 — Consumption Tracking

#### FR-INV-011: Stock Issue Workflow 📐

- 📐 **Issue Request Creation**: Department staff submit issue request with required items, quantities, and required date
- 📐 **Approval Workflow**: Store Keeper or HOD approves issue requests; rejected requests require reason
- 📐 **Stock Issue Execution**: On approval, Store Keeper confirms issue; system deducts from godown stock balance; creates outward stock entry + Stock Journal voucher in Accounting
- 📐 **Direct Issue**: Store Keeper can issue directly without formal request (bypasses approval for authorized users)
- 📐 **Partial Issue**: Issue partial quantities if full amount unavailable; request remains 'partial' until fully issued
- 📐 **Department Consumption Tracking**: Each issue linked to department for consumption analytics

| RBS Sub-Task | Status |
|---|---|
| ST.L8.1.1.1 — Select items | 📐 Not Started |
| ST.L8.1.1.2 — Set required quantity | 📐 Not Started |
| ST.L8.2.1.1 — Update consumed quantity | 📐 Not Started |
| ST.L8.2.1.2 — Track per department | 📐 Not Started |

### 4.9 L9 — Reorder Automation

**RBS Ref:** F.L9.1 — Alerts, F.L9.2 — Auto-PR

#### FR-INV-012: Reorder Alert and Auto-PR 📐

- 📐 **Threshold Monitoring**: ReorderAlertService compares current_stock_balance against `inv_stock_items.reorder_level` after every stock outward entry
- 📐 **Alert Notification**: When balance <= reorder_level, a notification is dispatched to the store manager via Notification module
- 📐 **Auto-PR Generation**: Optional setting per item — if enabled, system auto-creates a Draft PR for `reorder_qty` units from preferred vendor
- 📐 **Reorder Alert Report**: Dashboard widget and dedicated report listing all items currently below reorder level with current balance, reorder level, and reorder quantity

| RBS Sub-Task | Status |
|---|---|
| ST.L9.1.1.1 — Trigger alert when below threshold | 📐 Not Started |
| ST.L9.1.1.2 — Notify store manager | 📐 Not Started |
| ST.L9.2.1.1 — Auto-calc reorder qty | 📐 Not Started |
| ST.L9.2.1.2 — Assign preferred vendor | 📐 Not Started |

### 4.10 L10 — Asset vs Consumable Handling

**RBS Ref:** F.L10.1 — Asset Management, F.L10.2 — Asset Tracking

#### FR-INV-013: Asset Management 📐

- 📐 **Asset Item Flag**: Items with `item_type = 'asset'` are tracked individually; each unit receives an asset tag
- 📐 **Warranty Tracking**: `warranty_months` field on item; system can alert when warranty is expiring
- 📐 **Fixed Asset Integration**: On GRN acceptance for asset-type items, a record is created in `acc_fixed_assets` (Accounting module) for depreciation management
- 📐 **Asset Movement Register**: Transfer entries (transfer_in/transfer_out) between godowns generate a printable transfer slip
- 📐 **Asset Condition**: Optional condition field on stock entry for assets (Good, Fair, Poor, Under Repair, Disposed)

| RBS Sub-Task | Status |
|---|---|
| ST.L10.1.1.1 — Assign asset tag | 📐 Not Started |
| ST.L10.1.1.2 — Record warranty info | 📐 Not Started |
| ST.L10.2.1.1 — Record asset movement | 📐 Not Started |
| ST.L10.2.1.2 — Generate transfer slip | 📐 Not Started |

### 4.11 L11 — Inventory Reports & Analytics

**RBS Ref:** F.L11.1 — Reports, F.L11.2 — Analytics

#### FR-INV-014: Inventory Reports 📐

| Report Name | Description | Filters | Export |
|---|---|---|---|
| Stock Balance | Current stock per item per godown | Godown, Group, As-On-Date | CSV, PDF |
| Stock Valuation | Total value of all inventory by valuation method | As-On-Date, Group | CSV, PDF |
| Stock Ledger | Complete movement history for an item | Item, Date Range | CSV, PDF |
| Consumption Report | Department-wise consumption summary | Department, Date Range | CSV, PDF |
| Purchase Register | All PO-wise purchase transactions | Vendor, Date Range, Status | CSV |
| Pending PO Report | Outstanding PO items not yet received | Vendor, Status | CSV |
| GRN Register | All goods receipts | Date Range | CSV |
| Reorder Alert Report | Items currently below reorder level | Current | CSV, PDF |
| Fast-Moving Items | Top-N consumed items in period | Period (3/6/12 months), N | CSV |
| Slow-Moving Items | Items with no movement in period | Period (3/6/12 months) | CSV |
| Expiry Alert Report | Items expiring within N days | N Days Threshold | CSV, PDF |
| Godown-wise Stock | Stock by storage location | Godown | CSV, PDF |

#### FR-INV-015: Barcode/QR Label Printing 📐

- 📐 **Item Label Generation**: Print barcode/QR labels for items containing: item name, SKU, UOM, godown, batch number
- 📐 **Bulk Print**: Print labels for multiple items in a single print job
- 📐 **Standard Label Sizes**: A4 sheet templates (24-per-sheet, 40-per-sheet) and single label formats
- 📐 **QR Content**: Encodes item_id, sku, godown_id for scanner-based lookup

| RBS Sub-Task | Status |
|---|---|
| ST.L11.1.1.1 — View item-wise stock | 📐 Not Started |
| ST.L11.1.1.2 — Export stock data | 📐 Not Started |
| ST.L11.2.1.1 — Identify fast-moving items | 📐 Not Started |
| ST.L11.2.1.2 — Predict reorder needs | 📐 Not Started |

---

## 5. Non-Functional Requirements

### 5.1 Performance
- 📐 Stock balance queries must respond within 2 seconds for up to 5,000 active items per tenant
- 📐 Report generation for 12 months of data must complete within 10 seconds
- 📐 Reorder alert check (triggered after each outward entry) must be asynchronous — dispatched as a queued job

### 5.2 Reliability
- 📐 GRN acceptance, stock entry creation, and accounting voucher posting must be wrapped in a database transaction — all succeed or all rollback
- 📐 Negative stock prevention: any outward or issue entry that would cause balance to go negative must be rejected with a clear error message

### 5.3 Data Integrity
- 📐 No `tenant_id` column on any `inv_*` table — data isolation is at the database level
- 📐 All stock entries are immutable once posted — corrections are made via adjustment entries, not updates
- 📐 Soft delete with `deleted_at` on all tables; data is never physically deleted

### 5.4 Scalability
- 📐 `inv_stock_entries` table is the hottest table — index on `(stock_item_id, godown_id, created_at)` and `(entry_type, created_at)` required for report performance

### 5.5 Security
- 📐 All routes protected by `auth` middleware under tenant context
- 📐 Gate-based permission checks (see Section 9) on every controller action
- 📐 Inventory action log via `sys_activity_logs` for every stock movement

---

## 6. Database Schema

All 19 tables use the `inv_*` prefix. All tables include standard audit columns: `id` (BIGINT UNSIGNED PK), `is_active` (TINYINT(1) DEFAULT 1), `created_by` (BIGINT UNSIGNED NULL FK → sys_users), `created_at`, `updated_at`, `deleted_at`.

### 6.1 inv_stock_groups 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| name | VARCHAR(100) | NOT NULL | Group name (e.g., "Stationery", "Lab Equipment") |
| code | VARCHAR(20) | NULL, UNIQUE | Short group code |
| alias | VARCHAR(100) | NULL | Alternative name |
| parent_id | BIGINT UNSIGNED | NULL FK → inv_stock_groups | Self-referencing hierarchy |
| default_uom_id | BIGINT UNSIGNED | NULL FK → inv_units_of_measure | Default UOM for items in this group |
| sequence | INT | DEFAULT 0 | Display order |
| is_system | TINYINT(1) | DEFAULT 0 | Seeded groups cannot be deleted |
| + standard audit columns | | | |

### 6.2 inv_units_of_measure 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| name | VARCHAR(50) | NOT NULL | e.g., "Pieces", "Kilograms" |
| symbol | VARCHAR(10) | NOT NULL | e.g., "Pcs", "Kg" |
| decimal_places | TINYINT | DEFAULT 0 | Precision (0 for Pcs, 2 for Kg) |
| is_system | TINYINT(1) | DEFAULT 0 | Seeded records cannot be deleted |
| + standard audit columns | | | |

### 6.3 inv_uom_conversions 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| from_uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Source UOM |
| to_uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Target UOM |
| conversion_factor | DECIMAL(15,6) | NOT NULL | 1 from_uom = X to_uom |
| effective_from | DATE | NULL | Valid from date |
| effective_to | DATE | NULL | Valid until date |
| + standard audit columns | | | |

### 6.4 inv_stock_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| name | VARCHAR(150) | NOT NULL | Item name |
| sku | VARCHAR(50) | NULL, UNIQUE | Stock Keeping Unit code |
| alias | VARCHAR(150) | NULL | Alternative name |
| stock_group_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_groups | Item category |
| uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Default unit |
| item_type | ENUM('consumable','asset') | DEFAULT 'consumable' | Drives accounting treatment |
| opening_balance_qty | DECIMAL(15,3) | DEFAULT 0 | Opening stock quantity |
| opening_balance_rate | DECIMAL(15,2) | DEFAULT 0 | Opening rate per unit |
| opening_balance_value | DECIMAL(15,2) | DEFAULT 0 | Total opening value |
| valuation_method | ENUM('fifo','weighted_average','last_purchase') | DEFAULT 'weighted_average' | Stock valuation |
| reorder_level | DECIMAL(15,3) | NULL | Alert threshold |
| reorder_qty | DECIMAL(15,3) | NULL | Quantity to auto-reorder |
| min_stock | DECIMAL(15,3) | NULL | Minimum stock level |
| max_stock | DECIMAL(15,3) | NULL | Maximum stock level |
| has_batch_tracking | TINYINT(1) | DEFAULT 0 | Enable batch number tracking |
| has_expiry_tracking | TINYINT(1) | DEFAULT 0 | Enable expiry date tracking |
| hsn_sac_code | VARCHAR(20) | NULL | GST HSN/SAC code |
| brand | VARCHAR(100) | NULL | Brand name |
| model | VARCHAR(100) | NULL | Model number |
| warranty_months | INT | NULL | Warranty period in months |
| tax_rate_id | BIGINT UNSIGNED | NULL FK → acc_tax_rates | GST rate (from Accounting) |
| purchase_ledger_id | BIGINT UNSIGNED | NULL FK → acc_ledgers | Purchase account (from Accounting) |
| sales_ledger_id | BIGINT UNSIGNED | NULL FK → acc_ledgers | Sales account (from Accounting) |
| + standard audit columns | | | |

### 6.5 inv_godowns 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| name | VARCHAR(100) | NOT NULL | e.g., "Main Store", "Lab Store" |
| code | VARCHAR(20) | NULL, UNIQUE | Location code |
| parent_id | BIGINT UNSIGNED | NULL FK → inv_godowns | Sub-godown hierarchy |
| address | VARCHAR(500) | NULL | Physical location description |
| in_charge_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | Store keeper / in-charge |
| is_system | TINYINT(1) | DEFAULT 0 | Seeded godowns cannot be deleted |
| + standard audit columns | | | |

### 6.6 inv_stock_entries 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| stock_item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | Source/destination godown |
| voucher_id | BIGINT UNSIGNED | NOT NULL FK → acc_vouchers | Mandatory accounting voucher link |
| entry_type | ENUM('inward','outward','transfer_in','transfer_out','adjustment') | NOT NULL | Movement type |
| quantity | DECIMAL(15,3) | NOT NULL | Quantity moved |
| rate | DECIMAL(15,2) | NOT NULL | Rate per unit (valuation) |
| amount | DECIMAL(15,2) | NOT NULL | Total value (qty × rate) |
| batch_number | VARCHAR(50) | NULL | Batch for batch-tracked items |
| expiry_date | DATE | NULL | Expiry for expiry-tracked items |
| destination_godown_id | BIGINT UNSIGNED | NULL FK → inv_godowns | Target godown (for transfers) |
| party_ledger_id | BIGINT UNSIGNED | NULL FK → acc_ledgers | Vendor/dept ledger (Accounting) |
| narration | VARCHAR(500) | NULL | Entry notes |
| + standard audit columns | | | |

### 6.7 inv_item_vendor_jnt 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | Vendor |
| vendor_sku | VARCHAR(50) | NULL | Vendor's own item code |
| last_purchase_rate | DECIMAL(15,2) | NULL | Last price paid (auto-updated on GRN) |
| last_purchase_date | DATE | NULL | Date of last purchase (auto-updated on GRN) |
| lead_time_days | INT | NULL | Typical delivery lead time in days |
| is_preferred | TINYINT(1) | DEFAULT 0 | Preferred vendor for this item |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (item_id, vendor_id)`

### 6.8 inv_rate_contracts 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | Vendor |
| contract_number | VARCHAR(50) | NULL, UNIQUE | Contract reference number |
| valid_from | DATE | NOT NULL | Contract start date |
| valid_to | DATE | NOT NULL | Contract end date |
| status | ENUM('draft','active','expired','cancelled') | DEFAULT 'draft' | Contract status |
| remarks | TEXT | NULL | Additional notes |
| + standard audit columns | | | |

### 6.9 inv_rate_contract_items_jnt 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| rate_contract_id | BIGINT UNSIGNED | NOT NULL FK → inv_rate_contracts (CASCADE DELETE) | Parent contract |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| agreed_rate | DECIMAL(15,2) | NOT NULL | Fixed contracted price per unit |
| min_qty | DECIMAL(15,3) | NULL | Minimum order quantity |
| max_qty | DECIMAL(15,3) | NULL | Maximum order quantity |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (rate_contract_id, item_id)`

### 6.10 inv_purchase_requisitions 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| pr_number | VARCHAR(50) | NOT NULL, UNIQUE | Auto-generated PR number (e.g., PR-2025-001) |
| requested_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Requester |
| department_id | BIGINT UNSIGNED | NULL FK → sch_department | Requesting department (SINGULAR table name) |
| required_date | DATE | NOT NULL | Items needed by |
| priority | ENUM('low','normal','high','urgent') | DEFAULT 'normal' | Priority level |
| status | ENUM('draft','submitted','approved','rejected','converted','cancelled') | DEFAULT 'draft' | Workflow status |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Approver |
| approved_at | TIMESTAMP | NULL | Approval timestamp |
| remarks | TEXT | NULL | Notes |
| + standard audit columns | | | |

### 6.11 inv_purchase_requisition_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| pr_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_requisitions (CASCADE DELETE) | Parent PR |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| qty | DECIMAL(15,3) | NOT NULL | Requested quantity |
| uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Unit of measurement |
| estimated_rate | DECIMAL(15,2) | NULL | Estimated unit cost |
| remarks | VARCHAR(255) | NULL | Item-level notes |
| + standard audit columns | | | |

### 6.12 inv_purchase_orders 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| po_number | VARCHAR(50) | NOT NULL, UNIQUE | Auto-generated PO number (e.g., PO-2025-001) |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | Vendor |
| pr_id | BIGINT UNSIGNED | NULL FK → inv_purchase_requisitions | Source PR (if converted) |
| order_date | DATE | NOT NULL | PO date |
| expected_delivery_date | DATE | NULL | Expected delivery date |
| status | ENUM('draft','sent','partial','received','cancelled','closed') | DEFAULT 'draft' | PO lifecycle |
| total_amount | DECIMAL(15,2) | DEFAULT 0 | Pre-tax total |
| tax_amount | DECIMAL(15,2) | DEFAULT 0 | Total tax |
| discount_amount | DECIMAL(15,2) | NULL | Total discount |
| net_amount | DECIMAL(15,2) | DEFAULT 0 | Final payable amount |
| voucher_id | BIGINT UNSIGNED | NULL FK → acc_vouchers | Purchase voucher (Accounting) |
| terms_and_conditions | TEXT | NULL | PO terms |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Approver |
| + standard audit columns | | | |

### 6.13 inv_purchase_order_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| po_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_orders (CASCADE DELETE) | Parent PO |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| ordered_qty | DECIMAL(15,3) | NOT NULL | Ordered quantity |
| received_qty | DECIMAL(15,3) | DEFAULT 0 | Received so far (updated on GRN acceptance) |
| unit_price | DECIMAL(15,2) | NOT NULL | Unit cost |
| tax_rate_id | BIGINT UNSIGNED | NULL FK → acc_tax_rates | GST rate |
| discount_percent | DECIMAL(5,2) | NULL | Discount percentage |
| total_amount | DECIMAL(15,2) | NOT NULL | Line total (after tax, before discount) |
| + standard audit columns | | | |

### 6.14 inv_goods_receipt_notes 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| grn_number | VARCHAR(50) | NOT NULL, UNIQUE | Auto-generated GRN number (e.g., GRN-2025-001) |
| po_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_orders | Source PO |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | Vendor |
| receipt_date | DATE | NOT NULL | Date goods received |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | Receiving godown |
| status | ENUM('draft','inspected','accepted','partial','rejected') | DEFAULT 'draft' | GRN status |
| qc_status | ENUM('pending','passed','failed','partial') | DEFAULT 'pending' | Quality check result |
| qc_notes | TEXT | NULL | QC remarks |
| received_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Store Keeper who received |
| voucher_id | BIGINT UNSIGNED | NULL FK → acc_vouchers | Purchase voucher (created on acceptance) |
| + standard audit columns | | | |

### 6.15 inv_grn_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| grn_id | BIGINT UNSIGNED | NOT NULL FK → inv_goods_receipt_notes (CASCADE DELETE) | Parent GRN |
| po_item_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_order_items | Source PO item |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| received_qty | DECIMAL(15,3) | NOT NULL | Quantity physically received |
| accepted_qty | DECIMAL(15,3) | NOT NULL | Quantity accepted after QC |
| rejected_qty | DECIMAL(15,3) | DEFAULT 0 | Quantity rejected in QC |
| unit_cost | DECIMAL(15,2) | NOT NULL | Actual unit cost |
| batch_number | VARCHAR(50) | NULL | Batch number (if batch-tracked) |
| expiry_date | DATE | NULL | Expiry date (if expiry-tracked) |
| qc_remarks | VARCHAR(255) | NULL | Per-item QC notes |
| + standard audit columns | | | |

### 6.16 inv_issue_requests 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| request_number | VARCHAR(50) | NOT NULL, UNIQUE | Auto-generated request number |
| requested_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Requester |
| department_id | BIGINT UNSIGNED | NOT NULL FK → sch_department | Requesting department (SINGULAR) |
| required_date | DATE | NOT NULL | Items needed by |
| status | ENUM('submitted','approved','issued','partial','rejected') | DEFAULT 'submitted' | Workflow status |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Approver |
| remarks | TEXT | NULL | Notes |
| + standard audit columns | | | |

### 6.17 inv_issue_request_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| issue_request_id | BIGINT UNSIGNED | NOT NULL FK → inv_issue_requests (CASCADE DELETE) | Parent request |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| requested_qty | DECIMAL(15,3) | NOT NULL | Requested quantity |
| issued_qty | DECIMAL(15,3) | DEFAULT 0 | Quantity actually issued |
| uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Unit |
| + standard audit columns | | | |

### 6.18 inv_stock_issues 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| issue_number | VARCHAR(50) | NOT NULL, UNIQUE | Auto-generated issue number |
| issue_request_id | BIGINT UNSIGNED | NULL FK → inv_issue_requests | Source request (if from request) |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | Source godown |
| issued_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Store Keeper |
| issued_to_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | Receiving employee |
| department_id | BIGINT UNSIGNED | NOT NULL FK → sch_department | Receiving department (SINGULAR) |
| issue_date | DATE | NOT NULL | Issue date |
| voucher_id | BIGINT UNSIGNED | NULL FK → acc_vouchers | Stock Journal (Accounting) |
| acknowledged_by | BIGINT UNSIGNED | NULL | Receiver confirmation user |
| acknowledged_at | TIMESTAMP | NULL | Acknowledgment timestamp |
| + standard audit columns | | | |

### 6.19 inv_stock_issue_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| stock_issue_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_issues (CASCADE DELETE) | Parent issue |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Item |
| qty | DECIMAL(15,3) | NOT NULL | Issued quantity |
| unit_cost | DECIMAL(15,2) | NOT NULL | Cost per unit (from stock valuation) |
| batch_number | VARCHAR(50) | NULL | Batch number (if batch-tracked) |
| + standard audit columns | | | |

### 6.20 Cross-Module FK Dependencies

| FK Column | References | Module Owner |
|---|---|---|
| `acc_vouchers.id` | `inv_stock_entries.voucher_id`, `inv_stock_issues.voucher_id`, `inv_purchase_orders.voucher_id`, `inv_goods_receipt_notes.voucher_id` | Accounting |
| `acc_tax_rates.id` | `inv_stock_items.tax_rate_id`, `inv_purchase_order_items.tax_rate_id` | Accounting |
| `acc_ledgers.id` | `inv_stock_items.purchase_ledger_id`, `inv_stock_items.sales_ledger_id`, `inv_stock_entries.party_ledger_id` | Accounting |
| `acc_fixed_assets.id` | Created by GrnPostingService for asset-type items | Accounting |
| `vnd_vendors.id` | `inv_item_vendor_jnt.vendor_id`, `inv_rate_contracts.vendor_id`, `inv_purchase_orders.vendor_id`, `inv_goods_receipt_notes.vendor_id` | Vendor |
| `sch_employees.id` | `inv_godowns.in_charge_employee_id`, `inv_stock_issues.issued_to_employee_id` | SchoolSetup |
| `sch_department.id` | `inv_purchase_requisitions.department_id`, `inv_issue_requests.department_id`, `inv_stock_issues.department_id` | SchoolSetup |
| `sys_users.id` | All `created_by`, `approved_by`, `requested_by`, `issued_by` columns | System |

---

## 7. API and Routes

All routes registered in `routes/tenant.php` under the `inventory/` prefix with `auth` + tenant middleware.

### 7.1 Master Setup Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `inventory/stock-groups` | GET/POST | StockGroupController | index, store |
| `inventory/stock-groups/{id}` | GET/PUT/DELETE | StockGroupController | show, update, destroy |
| `inventory/stock-groups/{id}/toggle-status` | POST | StockGroupController | toggleStatus |
| `inventory/uom` | GET/POST | UomController | index, store |
| `inventory/uom/{id}` | GET/PUT/DELETE | UomController | show, update, destroy |
| `inventory/uom-conversions` | GET/POST | UomController | indexConversions, storeConversion |
| `inventory/stock-items` | GET/POST | StockItemController | index, store |
| `inventory/stock-items/{id}` | GET/PUT/DELETE | StockItemController | show, update, destroy |
| `inventory/stock-items/{id}/toggle-status` | POST | StockItemController | toggleStatus |
| `inventory/godowns` | GET/POST | GodownController | index, store |
| `inventory/godowns/{id}` | GET/PUT/DELETE | GodownController | show, update, destroy |

### 7.2 Vendor Linkage Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `inventory/item-vendors` | GET/POST | ItemVendorController | index, store |
| `inventory/item-vendors/{id}` | PUT/DELETE | ItemVendorController | update, destroy |
| `inventory/rate-contracts` | GET/POST | RateContractController | index, store |
| `inventory/rate-contracts/{id}` | GET/PUT/DELETE | RateContractController | show, update, destroy |
| `inventory/rate-contracts/{id}/items` | GET/POST | RateContractController | items, storeItem |

### 7.3 Procurement Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `inventory/purchase-requisitions` | GET/POST | PurchaseRequisitionController | index, store |
| `inventory/purchase-requisitions/{id}` | GET/PUT/DELETE | PurchaseRequisitionController | show, update, destroy |
| `inventory/purchase-requisitions/{id}/submit` | POST | PurchaseRequisitionController | submit |
| `inventory/purchase-requisitions/{id}/approve` | POST | PurchaseRequisitionController | approve |
| `inventory/purchase-requisitions/{id}/reject` | POST | PurchaseRequisitionController | reject |
| `inventory/purchase-requisitions/import` | POST | PurchaseRequisitionController | import |
| `inventory/purchase-orders` | GET/POST | PurchaseOrderController | index, store |
| `inventory/purchase-orders/{id}` | GET/PUT/DELETE | PurchaseOrderController | show, update, destroy |
| `inventory/purchase-orders/{id}/send` | POST | PurchaseOrderController | sendToVendor |
| `inventory/purchase-orders/{id}/cancel` | POST | PurchaseOrderController | cancel |
| `inventory/purchase-orders/convert-pr/{pr}` | POST | PurchaseOrderController | convertFromPR |
| `inventory/grn` | GET/POST | GrnController | index, store |
| `inventory/grn/{id}` | GET/PUT/DELETE | GrnController | show, update, destroy |
| `inventory/grn/{id}/accept` | POST | GrnController | accept |
| `inventory/grn/{id}/reject` | POST | GrnController | reject |

### 7.4 Stock Issue Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `inventory/issue-requests` | GET/POST | IssueRequestController | index, store |
| `inventory/issue-requests/{id}` | GET/PUT/DELETE | IssueRequestController | show, update, destroy |
| `inventory/issue-requests/{id}/approve` | POST | IssueRequestController | approve |
| `inventory/issue-requests/{id}/reject` | POST | IssueRequestController | reject |
| `inventory/stock-issues` | GET/POST | StockIssueController | index, store |
| `inventory/stock-issues/{id}` | GET | StockIssueController | show |
| `inventory/stock-issues/{id}/acknowledge` | POST | StockIssueController | acknowledge |
| `inventory/stock-issues/{id}/print` | GET | StockIssueController | printSlip |
| `inventory/stock-entries` | GET/POST | StockEntryController | index, store |
| `inventory/stock-entries/{id}` | GET | StockEntryController | show |

### 7.5 Reports and Dashboard Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `inventory/dashboard` | GET | InvDashboardController | index |
| `inventory/reports/stock-balance` | GET | InvReportController | stockBalance |
| `inventory/reports/stock-valuation` | GET | InvReportController | stockValuation |
| `inventory/reports/stock-ledger` | GET | InvReportController | stockLedger |
| `inventory/reports/consumption` | GET | InvReportController | consumption |
| `inventory/reports/purchase-register` | GET | InvReportController | purchaseRegister |
| `inventory/reports/grn-register` | GET | InvReportController | grnRegister |
| `inventory/reports/reorder-alerts` | GET | InvReportController | reorderAlerts |
| `inventory/reports/fast-slow-movers` | GET | InvReportController | fastSlowMovers |
| `inventory/reports/expiry-alerts` | GET | InvReportController | expiryAlerts |
| `inventory/reports/{type}/export` | GET | InvReportController | export |

---

## 8. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-INV-001 | Every `inv_stock_entries` record MUST have a `voucher_id` — no orphan stock movements |
| BR-INV-002 | Stock is NOT added to ledger until GRN status transitions to 'accepted' |
| BR-INV-003 | Negative stock is not permitted — outward/issue entry rejected if current_balance < requested_qty |
| BR-INV-004 | Approved PR lines converted to PO change PR status to 'converted' — no further edits to converted PRs |
| BR-INV-005 | PO auto-transitions to 'received' when all line items have received_qty >= ordered_qty |
| BR-INV-006 | When batch tracking is enabled, outward entries must use FIFO batch selection (oldest batch first) |
| BR-INV-007 | Stock valuation is configurable per item (FIFO / Weighted Average / Last Purchase Cost); issuing cost uses item's configured method |
| BR-INV-008 | Stock issue requires an approved issue request — Store Keeper may bypass for direct issues with adequate permission |
| BR-INV-009 | Reorder alert triggers when current_balance <= reorder_level; fires after each outward stock entry |
| BR-INV-010 | Asset-type items (item_type = 'asset') trigger acc_fixed_assets record creation on GRN acceptance |
| BR-INV-011 | Rate contract with status 'active' takes priority in PO item pricing; expired contracts are ignored |
| BR-INV-012 | GRN accepted_qty + rejected_qty must equal received_qty |
| BR-INV-013 | Stock adjustments require approval before being posted; adjustment stock entry created on approval |
| BR-INV-014 | No `tenant_id` column anywhere — data isolation is at DB level |
| BR-INV-015 | Stock entries are immutable once posted — corrections via new adjustment entry only |

---

## 9. Authorization and RBAC

### 9.1 Permission Strings

```
inventory.stock-group.viewAny
inventory.stock-group.create
inventory.stock-group.update
inventory.stock-group.delete
inventory.stock-item.viewAny
inventory.stock-item.create
inventory.stock-item.update
inventory.stock-item.delete
inventory.uom.viewAny
inventory.uom.create
inventory.uom.update
inventory.godown.viewAny
inventory.godown.create
inventory.godown.update
inventory.purchase-requisition.viewAny
inventory.purchase-requisition.create
inventory.purchase-requisition.approve
inventory.purchase-order.viewAny
inventory.purchase-order.create
inventory.purchase-order.approve
inventory.grn.viewAny
inventory.grn.create
inventory.grn.accept
inventory.grn.reject
inventory.issue-request.viewAny
inventory.issue-request.create
inventory.issue-request.approve
inventory.stock-issue.viewAny
inventory.stock-issue.create
inventory.rate-contract.viewAny
inventory.rate-contract.create
inventory.rate-contract.update
inventory.stock-entry.viewAny
inventory.stock-entry.create
inventory.report.view
```

### 9.2 Role-Permission Matrix

| Permission Area | School Admin | Store Keeper | Department Head | Accountant |
|---|---|---|---|---|
| Stock Group / UOM / Godown | Full | CRUD | View | View |
| Stock Item Master | Full | CRUD | View | View |
| Purchase Requisition | Full | Create, View | Create own dept | View |
| Purchase Order | Full | Full | View | View |
| GRN | Full | Full | View | View |
| Issue Request | Full | Approve | Create own dept | View |
| Stock Issue | Full | Full | View own dept | View |
| Rate Contract | Full | View | View | View |
| Reports | Full | Full | Own dept | Full (read-only) |

---

## 10. Service Layer Architecture

### 10.1 Proposed Services 📐

| Service | Responsibility |
|---|---|
| 📐 `StockLedgerService` | Post stock entries to `inv_stock_entries`; call `VoucherServiceInterface` to create Accounting voucher; update running balance |
| 📐 `PurchaseOrderService` | PR-to-PO conversion logic; PO totals calculation; PO status lifecycle management |
| 📐 `GrnPostingService` | GRN acceptance: create inward stock entry, call StockLedgerService, update PO received_qty, create acc_fixed_assets for asset items, update last_purchase_rate on inv_item_vendor_jnt |
| 📐 `ReorderAlertService` | After each outward entry: check balance vs reorder_level; dispatch Notification event; optionally auto-create Draft PR |
| 📐 `StockValuationService` | Calculate issue cost based on item's configured valuation method (FIFO / Weighted Average / Last Purchase Cost) |
| 📐 `InventoryReportService` | Generate all report datasets; calculate stock balance, valuation, consumption analytics, fast/slow movers, expiry alerts |

### 10.2 Proposed Controllers 📐

| Controller | Screens Managed |
|---|---|
| 📐 `InvDashboardController` | Dashboard with KPIs, reorder alerts widget, recent movements |
| 📐 `StockGroupController` | Stock group CRUD + hierarchy |
| 📐 `UomController` | UOM CRUD + conversion rules |
| 📐 `StockItemController` | Item master CRUD + barcode label print |
| 📐 `GodownController` | Godown CRUD + sub-godown hierarchy |
| 📐 `StockEntryController` | View stock ledger entries (read-only; entries created by services) |
| 📐 `ItemVendorController` | Item-vendor linkage CRUD |
| 📐 `RateContractController` | Rate contract + line items CRUD |
| 📐 `PurchaseRequisitionController` | PR CRUD + submit/approve/reject + CSV import |
| 📐 `PurchaseOrderController` | PO CRUD + status actions + PR conversion |
| 📐 `GrnController` | GRN CRUD + QC actions + accept/reject |
| 📐 `IssueRequestController` | Issue request CRUD + approve/reject |
| 📐 `StockIssueController` | Stock issue creation + acknowledge + print slip |
| 📐 `InvReportController` | All reports + exports |

### 10.3 Proposed FormRequests 📐

`StoreStockGroupRequest`, `StoreUomRequest`, `StoreUomConversionRequest`, `StoreStockItemRequest`, `StoreGodownRequest`, `StorePurchaseRequisitionRequest`, `StorePurchaseOrderRequest`, `StoreGrnRequest`, `StoreIssueRequestRequest`, `StoreStockIssueRequest`, `StoreRateContractRequest`, `StoreStockEntryRequest`

---

## 11. Integration Points

| Direction | Source Event | Target | Mechanism |
|---|---|---|---|
| 📐 GRN → Accounting | GRN Accepted | Purchase Voucher (Dr Stock-in-Hand A/c, Cr Vendor Creditor A/c) | `VoucherServiceInterface::postPurchase()` |
| 📐 Issue → Accounting | Stock Issued | Stock Journal (Dr Dept Consumption A/c, Cr Stock-in-Hand A/c) | `VoucherServiceInterface::postStockJournal()` |
| 📐 Transfer → Accounting | Stock Transfer | Stock Journal (Dr Destination Godown, Cr Source Godown) | `VoucherServiceInterface::postStockJournal()` |
| 📐 Adjustment → Accounting | Stock Adjustment Approved | Journal Entry (Dr/Cr Stock-in-Hand, Cr/Dr Stock Adjustment A/c) | `VoucherServiceInterface::postAdjustmentJournal()` |
| 📐 Asset GRN → Accounting | Asset-type GRN Accepted | Creates `acc_fixed_assets` record for depreciation | `GrnPostingService` → Accounting service call |
| 📐 Inventory → Vendor | PO Creation | References `vnd_vendors` for supplier | FK reference |
| 📐 Inventory → SchoolSetup | Godown in-charge | References `sch_employees` | FK reference |
| 📐 Inventory → SchoolSetup | Department on PR/Issue | References `sch_department` (SINGULAR) | FK reference |
| 📐 Reorder → Notification | Balance <= reorder_level | Alert notification to store manager | `event(new ReorderThresholdReached($item))` |

### 11.1 Accounting Events (D21)

Per the project accounting integration spec:
- `GrnAccepted` event fired on GRN acceptance → Accounting subscribes and creates Purchase Journal Voucher
- `StockIssued` event fired on stock issue confirmation → Accounting subscribes and creates Stock Journal Voucher
- Event data payload includes: item_id, godown_id, qty, rate, amount, party_ledger_id, voucher_type, narration

---

## 12. Test Coverage

### 12.1 Proposed Feature Tests 📐

| Test Class | Test Scenarios |
|---|---|
| 📐 `StockGroupTest` | Create group, create child group, deactivate with audit log, prevent delete of system group |
| 📐 `StockItemTest` | Create consumable, create asset, set reorder levels, toggle batch tracking |
| 📐 `PurchaseRequisitionTest` | Create PR, submit PR, approve PR, reject PR, CSV import with validation errors |
| 📐 `PurchaseOrderTest` | Create PO, convert PR to PO, PO status progression, partial receipt, auto-close on full receipt |
| 📐 `GrnTest` | Create GRN, QC pass, QC partial, accept GRN → stock entry created, voucher created, reject GRN |
| 📐 `StockIssueTest` | Create issue request, approve, create issue, negative stock prevention, acknowledge |
| 📐 `ReorderAlertTest` | Stock drops below threshold, alert notification dispatched, auto-PR created |
| 📐 `StockValuationTest` | FIFO valuation correct, Weighted Average recalculation, Last Purchase Cost |

### 12.2 Proposed Unit Tests 📐

| Test Class | Scenarios |
|---|---|
| 📐 `StockLedgerServiceTest` | Post inward entry, post outward entry, prevent negative stock |
| 📐 `StockValuationServiceTest` | FIFO batch selection, weighted average calculation |
| 📐 `GrnPostingServiceTest` | Voucher created on accept, PO received_qty updated, fixed asset entry created for asset items |

---

## 13. Implementation Status

| Component | Status |
|---|---|
| Module Directory Structure | ❌ Not Started |
| Database Migrations | ❌ Not Started |
| Eloquent Models (19) | ❌ Not Started |
| Controllers (14) | ❌ Not Started |
| Services (6) | ❌ Not Started |
| FormRequests (12) | ❌ Not Started |
| Blade Views (~60) | ❌ Not Started |
| Seeders (3) | ❌ Not Started |
| Routes (tenant.php) | ❌ Not Started |
| Policies (12) | ❌ Not Started |
| Feature Tests | ❌ Not Started |
| Unit Tests | ❌ Not Started |
| Accounting Integration Events | ❌ Not Started |
| Notification Integration | ❌ Not Started |
| PDF Report Generation (DomPDF) | ❌ Not Started |
| Barcode/QR Label Printing | ❌ Not Started |

---

## 14. Known Issues and Technical Debt

### 14.1 Pre-Development Clarifications Required

1. **Accounting Module Dependency**: The `VoucherServiceInterface` and its concrete implementation must be built before GRN acceptance and stock issue posting can be tested. Inventory must be developed in coordination with, or after, the Accounting module.
2. **acc_tax_rates Table**: The `acc_tax_rates` table referenced by `inv_stock_items.tax_rate_id` must exist in the schema before Inventory migrations run.
3. **sch_department vs sch_departments**: Table name is definitively `sch_department` (SINGULAR) per verified DDL. All FK references must use this exact singular form.
4. **Stock Balance Computation**: There is no dedicated `inv_stock_balances` denormalized table in the v4 design. Current balance is computed by summing `inv_stock_entries.quantity` per (stock_item_id, godown_id). A denormalized balance table may be required for performance at scale.
5. **UOM on Issue vs Purchase**: Items may be purchased in Box (10 Pcs) but issued in Pcs. UOM conversion rules need to be applied at issue time using `inv_uom_conversions`.

### 14.2 Design Gaps to Resolve

- **Stock Transfer Document**: A dedicated `inv_stock_transfers` table may be preferable over using `inv_stock_entries` with `entry_type = 'transfer_in/out'` for better document tracking
- **Stock Adjustment Detail**: Physical count audit workflow requires a dedicated `inv_stock_adjustments` header table with item-wise discrepancy details — not currently in the 19-table v4 design; should be added in DDL
- **Barcode Printing Service**: No service design specified for barcode/QR generation — a third-party package (e.g., `milon/barcode`) will be required

---

## 15. Development Priorities and Recommendations

### 15.1 Development Sequence

Build in this order to respect FK dependencies:

1. **Phase 1 — Masters** (no cross-module dependencies): `inv_stock_groups`, `inv_units_of_measure`, `inv_uom_conversions`, `inv_stock_items`, `inv_godowns`, seeders
2. **Phase 2 — Vendor Linkage**: `inv_item_vendor_jnt`, `inv_rate_contracts`, `inv_rate_contract_items_jnt` (requires `vnd_vendors`)
3. **Phase 3 — Procurement Workflow**: `inv_purchase_requisitions` + items, `inv_purchase_orders` + items (requires `sch_department`)
4. **Phase 4 — GRN & Stock Entry** (requires Accounting `VoucherServiceInterface`): `inv_goods_receipt_notes`, `inv_grn_items`, `inv_stock_entries` + GrnPostingService
5. **Phase 5 — Issue Workflow**: `inv_issue_requests` + items, `inv_stock_issues` + items + StockIssueController
6. **Phase 6 — Automation & Reports**: ReorderAlertService, InventoryReportService, InvReportController

### 15.2 Key Recommendations

- **Add `inv_stock_adjustments` and `inv_stock_adjustment_items` tables** to the 19-table design — physical count reconciliation is a stated requirement but has no dedicated table
- **Consider denormalized `inv_stock_balances` table** updated on every stock entry — avoids expensive SUM queries on a potentially large `inv_stock_entries` table
- **Implement stock entry as an immutable ledger** — never UPDATE or DELETE stock entries; corrections always via new entries with opposite signs
- **Use Laravel Model Observers** for `GrnPostingService` and `ReorderAlertService` to keep controllers thin
- **RBS Source**: Module L — 50 sub-tasks fully mapped to FRs in this document

---

*Document Version 1.0 | Generated 2026-03-25 | RBS_ONLY Mode | All features ❌ Not Started*
