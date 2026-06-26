# Inventory Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** INV  |  **Module Path:** `📐 Proposed: Modules/Inventory/`
**Module Type:** Tenant  |  **Database:** `📐 Proposed: tenant_db`
**Table Prefix:** `inv_*`  |  **Processing Mode:** RBS_ONLY
**RBS Reference:** L (Inventory & Assets)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/INV_Inventory_Requirement.md`
**Gap Analysis:** N/A (Greenfield module)
**Generation Batch:** 8/10

> All features are **❌ Not Started**. All proposed items are marked **📐**.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Actors](#3-stakeholders--actors)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API & Route Specification](#6-api--route-specification)
7. [UI Screen Inventory](#7-ui-screen-inventory)
8. [Business Rules](#8-business-rules)
9. [Workflow & State Machines](#9-workflow--state-machines)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Cross-Module Dependencies](#11-cross-module-dependencies)
12. [Test Case Reference](#12-test-case-reference)
13. [Glossary](#13-glossary)
14. [Additional Suggestions](#14-additional-suggestions)
15. [Appendices — Proposed File List](#15-appendices--proposed-file-list)
16. [V1 → V2 Delta Summary](#16-v1--v2-delta-summary)

---

## 1. Executive Summary

### 1.1 Module Statistics

| Metric | Count |
|---|---|
| Sub-Modules | 6 (L1 Item Master, L2 Stock Mgmt, L3 Purchase Orders, L4 Vendor Ref, L5 Asset Tracking, L6 Procurement Workflow) |
| Functional Requirements | 15 (FR-INV-001 to FR-INV-015) |
| Proposed DB Tables | 21 `inv_*` tables |
| Proposed Controllers | 14 |
| Proposed Services | 7 |
| Proposed Models | 21 |
| Proposed FormRequests | 13 |
| Proposed Policies | 13 |
| Proposed Blade Views | ~65 |
| Proposed Seeders | 3 |
| Business Rules | 18 (BR-INV-001 to BR-INV-018) |
| Implementation Status | ❌ 0% — Greenfield |

### 1.2 Implementation Prerequisites

Before development begins, the following dependencies must be in place:

| # | Prerequisite | Owner Module | Blocker For |
|---|---|---|---|
| P1 | `VoucherServiceInterface` implemented | Accounting (ACC) | GRN acceptance, Stock Issue posting |
| P2 | `acc_vouchers`, `acc_ledgers`, `acc_tax_rates` tables exist in DDL | Accounting (ACC) | inv_* FK migrations |
| P3 | `vnd_vendors` table exists and populated | Vendor (VND) | PO creation, Rate Contracts |
| P4 | `sch_department` (singular) table exists | SchoolSetup (SCH) | PR creation, Issue Requests |
| P5 | `sch_employees` table exists | SchoolSetup (SCH) | Godown in-charge assignment |
| P6 | Notification module event bus active | NTF | Reorder alert delivery |

### 1.3 RBS Coverage

All 50 RBS sub-tasks under Module L are addressed in this document. RBS Priority: P4 (Medium-Low), Complexity: Medium.

---

## 2. Module Overview

### 2.1 Purpose

The Inventory module provides a complete stock and procurement management system for Indian K-12 schools on the Prime-AI SaaS platform. It covers the full lifecycle from item master setup and vendor-linked rate contracts through a structured procurement workflow (Indent → Quotation → PO → GRN → Stock Entry), departmental stock issue and consumption tracking, and automated reorder alerts — all integrated with the Accounting module via event-driven voucher posting.

### 2.2 Architecture

- **Module Namespace:** `Modules\Inventory`
- **Route File:** `routes/tenant.php` under `inventory/` prefix
- **DB Isolation:** No `tenant_id` columns; database-per-tenant via `stancl/tenancy v3.9`
- **Accounting Integration:** Event-driven via `GrnAccepted` / `StockIssued` events → `VoucherServiceInterface` (Decision D21)
- **Asset Tracking:** L5 Asset sub-module tracks fixed assets; full depreciation delegated to Accounting (`acc_fixed_assets`)
- **Vendor Data:** References `vnd_vendors` (Vendor module); no vendor master duplication

### 2.3 Key Features

| Feature Area | Description |
|---|---|
| Item & Category Master | Hierarchical stock groups, item catalog with batch/expiry, opening balances |
| Units of Measurement | UOM master with conversion rules (Box → Pcs, etc.) |
| Godown Management | Multi-location storage with sub-godown hierarchy |
| Procurement Workflow | PR → Quotation → PO → GRN → Stock Entry with full approval workflow |
| Rate Contracts | Vendor-wise item rate contracts with validity and expiry alerts |
| Stock Issue | Issue Request → Approval → Stock Issue → Acknowledgment + Stock Journal |
| Asset Tracking | Asset register, warranty tracking, condition monitoring, transfer slips |
| Reorder Automation | Threshold-triggered alerts and optional auto-PR generation |
| Stock Valuation | FIFO, Weighted Average, Last Purchase Cost per item |
| Reports & Analytics | 12 reports with CSV/PDF export; barcode/QR label printing |

---

## 3. Stakeholders & Actors

| Actor | Role Description | Key Permissions |
|---|---|---|
| **School Admin** | Full access to all inventory functions; configures module settings | All CRUD, all approvals, all reports |
| **Inventory / Store Manager** | Day-to-day operations: GRN, stock issues, item master; primary module user | Full operational access; can approve issue requests |
| **Principal** | Strategic oversight: budget tracking, reorder alerts, analytics dashboard | Read-only dashboard + reports |
| **Accountant** | Views stock valuation reports; monitors accounting integrations | Read-only: reports, stock entries, PO values |
| **Department Head (HOD)** | Submits purchase requisitions and issue requests for own department | Create/submit PR and Issue Requests; view own dept reports |
| **IT Admin / Super Admin** | Tenant setup, seeder execution, module enabling | System-level only |

### 3.1 Actor-Use Case Matrix

| Use Case | Admin | Store Mgr | Principal | Accountant | HOD |
|---|---|---|---|---|---|
| Manage Item Master | Full | Full | View | View | View |
| Approve PR | Yes | Yes | No | No | Own dept |
| Create / Approve PO | Yes | Yes | No | No | No |
| Process GRN | Yes | Yes | No | No | No |
| Approve Issue Request | Yes | Yes | No | No | Own dept |
| Execute Stock Issue | Yes | Yes | No | No | No |
| View Stock Reports | Yes | Yes | Yes (summary) | Yes | Own dept |
| Manage Rate Contracts | Yes | Yes | No | View | No |

---

## 4. Functional Requirements

> All items below are **❌ Not Started** and **📐 Proposed**.

### 4.1 L1 — Item & Category Master

#### FR-INV-001: Stock Group (Category) Management 📐

Stock groups form a hierarchical tree of item categories, seeded during tenant creation and extensible by the school.

- 📐 **Create Stock Group**: Name (required, max 100 chars), unique code (optional, max 20), alias, parent group (optional, multi-level hierarchy), default UOM (FK → `inv_units_of_measure`), display sequence, `is_system` flag (seeded groups cannot be deleted)
- 📐 **Hierarchy**: Self-referencing `parent_id`; unlimited depth; `sequence` column for display order
- 📐 **Deactivate with Audit**: `is_active` soft-disable; recorded in `sys_activity_logs`
- 📐 **Seeded Groups (10)**: Stationery, Lab Equipment, Sports Equipment, Furniture, Cleaning Supplies, IT Equipment, Books & Journals, Electrical Items, Uniforms & Textiles, Miscellaneous

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L1.1.1.1 | Define main category and code | 📐 Not Started |
| ST.L1.1.1.2 | Set parent category | 📐 Not Started |
| ST.L1.1.1.3 | Assign default UOM | 📐 Not Started |
| ST.L1.1.2.1 | Reorder hierarchy (sequence) | 📐 Not Started |
| ST.L1.1.2.2 | Deactivate with audit log | 📐 Not Started |

#### FR-INV-002: Stock Item Master 📐

The item catalog defines every procurable and issuable item in the school.

- 📐 **Create Item**: Name (required, max 150), SKU (unique, optional), alias, stock group (required FK), UOM (required FK), item type (consumable / asset)
- 📐 **Stock Level Config**: Reorder level, reorder qty, min stock, max stock — `DECIMAL(15,3)`
- 📐 **Attributes**: Brand, model, HSN/SAC code (GST), warranty months (for assets)
- 📐 **Batch/Expiry Tracking**: Per-item toggle for batch number and expiry date tracking
- 📐 **Valuation Method**: FIFO, Weighted Average, or Last Purchase Cost — configurable per item
- 📐 **Opening Balance**: Opening qty, rate, and total value for tenant onboarding
- 📐 **Accounting Linkage**: `purchase_ledger_id`, `sales_ledger_id` (FK → `acc_ledgers`), `tax_rate_id` (FK → `acc_tax_rates`)
- 📐 **Asset Integration**: `item_type = 'asset'` triggers `acc_fixed_assets` creation on GRN acceptance
- 📐 **Auto-Reorder PR**: Optional per-item toggle; if enabled, auto-creates Draft PR when stock hits reorder level

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L1.2.1.1 | Enter item name & SKU | 📐 Not Started |
| ST.L1.2.1.2 | Assign category & UOM | 📐 Not Started |
| ST.L1.2.1.3 | Define min/max stock levels | 📐 Not Started |
| ST.L1.2.2.1 | Set brand/model/HSN | 📐 Not Started |
| ST.L1.2.2.2 | Enable batch/expiry tracking | 📐 Not Started |

#### FR-INV-003: UOM Master & Conversion Rules 📐

- 📐 **Create UOM**: Name (max 50), symbol (max 10), decimal places (0–4), `is_system` flag
- 📐 **Seeded UOMs (10)**: Pieces (Pcs, 0), Kilograms (Kg, 2), Litres (Ltr, 2), Box (Box, 0), Ream (Ream, 0), Set (Set, 0), Pair (Pair, 0), Bottles (Btl, 0), Metres (Mtr, 2), Numbers (Nos, 0)
- 📐 **Conversion Rules**: Define factor between two UOMs (e.g., 1 Box = 10 Pcs); bidirectional by dividing factor; optional effective dates
- 📐 **Apply at Issue Time**: When item purchased in Box and issued in Pcs, conversion applied automatically

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L2.1.1.1 | Define UOM name & symbol | 📐 Not Started |
| ST.L2.1.1.2 | Set decimal precision | 📐 Not Started |
| ST.L2.2.1.1 | Create conversion factors | 📐 Not Started |
| ST.L2.2.1.2 | Set effective dates on conversion | 📐 Not Started |

#### FR-INV-004: Godown (Storage Location) Management 📐

- 📐 **Create Godown**: Name (max 100), code (unique, max 20), parent godown (sub-godown hierarchy), address, in-charge employee (FK → `sch_employees`), `is_system` flag
- 📐 **Seeded Godowns (5)**: Main Store, Lab Store, Sports Room, IT Room, Library Store
- 📐 **Godown-wise Stock View**: Real-time stock balance per item per godown
- 📐 **Stock Transfer**: Move items between godowns; creates transfer_in and transfer_out entries + Stock Journal voucher

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L1.3.1.1 | Define godown name & code | 📐 Not Started |
| ST.L1.3.1.2 | Assign in-charge employee | 📐 Not Started |
| ST.L1.3.2.1 | Record transfer between godowns | 📐 Not Started |

### 4.2 L2 — Stock Management

#### FR-INV-005: Stock Entry Ledger 📐

`inv_stock_entries` is the immutable central journal of all stock movements.

- 📐 **Entry Types**: `inward` (GRN), `outward` (issue), `transfer_in`, `transfer_out`, `adjustment`
- 📐 **Mandatory Voucher Link**: Every entry MUST reference `acc_vouchers` — no orphan movements
- 📐 **Batch/Expiry Carried Through**: Batch number and expiry date flow from GRN through to issue
- 📐 **Immutability**: Posted entries are never UPDATE/DELETEd; corrections via new adjustment entries only
- 📐 **Running Balance**: Denormalized `inv_stock_balances` table updated on every entry (see FR-INV-005a)
- 📐 **Issue Slip PDF**: Outward entries generate printable issue slip via DomPDF with acknowledgment field

#### FR-INV-005a: Stock Balance Ledger (Denormalized) 📐

New in V2 — replaces expensive SUM queries at scale.

- 📐 **Table**: `inv_stock_balances` — one row per `(stock_item_id, godown_id)` storing `current_qty` and `current_value`
- 📐 **Update Trigger**: Updated atomically within the same DB transaction as each `inv_stock_entries` insert
- 📐 **Concurrency**: Row-level lock (`lockForUpdate()`) on balance row during stock entry creation prevents race conditions
- 📐 **Rebuild Command**: Artisan command `inventory:recalculate-balances` for reconciliation after data corrections

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L7.1.1.1 | Update stock ledger on inward | 📐 Not Started |
| ST.L7.2.1.1 | Update stock ledger on outward | 📐 Not Started |
| ST.L7.2.1.2 | Generate issue slip | 📐 Not Started |

#### FR-INV-006: Stock Adjustment & Physical Count 📐

New in V2 — addresses gap identified in V1 Section 14.2.

- 📐 **Physical Stock Audit**: Dedicated `inv_stock_adjustments` (header) and `inv_stock_adjustment_items` (detail) tables
- 📐 **Workflow**: Create Adjustment → Enter counted quantities → System computes variance (counted - system balance) → Submitted → Approved → Adjustment stock entry posted
- 📐 **Approval Required**: Adjustments above configurable threshold (by value) require Principal/Admin approval
- 📐 **Write-Off Entry**: Negative variance creates outward adjustment entry; positive creates inward adjustment entry
- 📐 **Annual Audit Report**: Print formatted physical count sheet (PDF) for government stock register compliance

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L9.3.1.1 | Record physical count per item | 📐 Not Started |
| ST.L9.3.1.2 | Compute variance | 📐 Not Started |
| ST.L9.3.1.3 | Post adjustment entry on approval | 📐 Not Started |

### 4.3 L3 — Purchase Orders

#### FR-INV-007: Purchase Requisition (PR) Workflow 📐

- 📐 **Create PR**: Auto-generated PR number (PR-YYYY-NNNN), department, requested by, required date, priority (low/normal/high/urgent)
- 📐 **PR Line Items**: Multiple items; each line: item, qty, UOM, estimated rate, remarks
- 📐 **Status FSM**: Draft → Submitted → Approved / Rejected → Converted (to PO) / Cancelled
- 📐 **Approval Action**: Designated approver approves or rejects with reason
- 📐 **Bulk CSV Import**: Upload CSV `[item_code, quantity, estimated_rate, remarks]`; pre-import validation report before final import
- 📐 **Partial Conversion**: Individual PR line items can be converted to PO; remaining lines stay in Approved state

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L4.1.1.1 | Select items and quantities | 📐 Not Started |
| ST.L4.1.1.2 | Enter required date and priority | 📐 Not Started |
| ST.L4.1.2.1 | Upload CSV bulk import | 📐 Not Started |
| ST.L4.1.2.2 | Validate and preview before import | 📐 Not Started |

#### FR-INV-008: Purchase Order (PO) Management 📐

- 📐 **Convert PR to PO**: Select approved PR lines; pre-fill vendor (preferred vendor) and pricing (active rate contract if available)
- 📐 **Direct PO**: Emergency/unplanned purchase without PR
- 📐 **PO Details**: Auto-generated PO number (PO-YYYY-NNNN), vendor, PO date, expected delivery date, terms & conditions
- 📐 **PO Line Items**: Item, ordered qty, unit price, tax rate (CGST+SGST or IGST), discount %, total — auto-calculated
- 📐 **Approval Threshold**: POs above configurable amount require Admin/Principal approval (BR-L-002)
- 📐 **Status FSM**: Draft → Sent → Partial → Received → Closed / Cancelled
- 📐 **Received Qty Tracking**: `received_qty` on each PO item auto-updated on GRN acceptance

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L5.1.1.1 | Select approved PR lines | 📐 Not Started |
| ST.L5.1.1.2 | Assign vendor & pricing | 📐 Not Started |
| ST.L5.2.1.1 | Edit quantities pre-send | 📐 Not Started |
| ST.L5.2.1.2 | Record revision history | 📐 Not Started |

#### FR-INV-009: Goods Receipt Note (GRN) 📐

- 📐 **Create GRN**: Auto-generated GRN number (GRN-YYYY-NNNN), linked PO, vendor, receipt date, receiving godown
- 📐 **GRN Line Items**: Per PO line — received qty, accepted qty, rejected qty, actual unit cost, batch number, expiry date, per-item QC remarks
- 📐 **QC Process**: GRN-level `qc_status` (pending → passed/failed/partial); QC notes field
- 📐 **Status FSM**: Draft → Inspected → Accepted / Partial / Rejected
- 📐 **Accept Action**: Fires `GrnAccepted` event → Accounting creates Purchase Voucher; stock entry posted; PO `received_qty` updated
- 📐 **Partial GRN**: Partial acceptance moves PO to 'partial'; subsequent GRNs against same PO allowed until PO auto-closes
- 📐 **GRN Quantity Constraint**: `accepted_qty + rejected_qty = received_qty`; `received_qty ≤ (PO ordered_qty - already received)`

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L6.1.1.1 | Verify items received against PO | 📐 Not Started |
| ST.L6.1.1.2 | Record batch/expiry details | 📐 Not Started |
| ST.L6.2.1.1 | Record QC pass/fail per item | 📐 Not Started |
| ST.L6.2.1.2 | Add GRN-level QC notes | 📐 Not Started |

### 4.4 L4 — Vendor Linkage (Reference Only)

#### FR-INV-010: Item-Vendor Linkage & Rate Contracts 📐

The Vendor module owns `vnd_vendors`. Inventory only adds linkage and pricing data.

- 📐 **Item-Vendor Assignment**: Multiple vendors per item; one marked preferred; vendor SKU for cross-reference; lead time in days
- 📐 **Last Purchase Tracking**: `last_purchase_rate` and `last_purchase_date` auto-updated on GRN acceptance
- 📐 **Rate Contracts**: Vendor-level contract (number, validity dates, status: draft/active/expired/cancelled)
- 📐 **Rate Contract Line Items**: Per-item agreed rate, min/max order qty
- 📐 **Expiry Alert**: Notify store manager 30 days before active rate contract expires
- 📐 **Auto-Apply on PO**: Active rate contract pricing auto-populated when converting PR to PO

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L3.1.1.1 | Assign preferred vendor to item | 📐 Not Started |
| ST.L3.1.1.2 | Track last purchase rate on GRN | 📐 Not Started |
| ST.L3.2.1.1 | Set contract validity dates | 📐 Not Started |
| ST.L3.2.1.2 | Assign item-wise fixed rates | 📐 Not Started |

### 4.5 L5 — Asset Tracking

#### FR-INV-011: Fixed Asset Register 📐

New in V2 — expands V1 Asset section with dedicated asset tracking tables.

- 📐 **Asset Categories**: `inv_asset_categories` table — category name, code, depreciation rate (%), WDV method, useful life years
- 📐 **Asset Register**: `inv_assets` table — asset tag (auto-generated), linked GRN item, asset category, purchase date, purchase cost, current book value, location (godown), assigned employee, condition (Good/Fair/Poor/Under Repair/Disposed), warranty expiry
- 📐 **Asset Creation on GRN**: When `item_type = 'asset'` GRN is accepted, `inv_assets` record auto-created for each accepted unit (accepted_qty integer units → one row per unit)
- 📐 **Depreciation Tracking**: Annual depreciation computed by Accounting module on `acc_fixed_assets`; `inv_assets` stores current book value synced from Accounting
- 📐 **Asset Transfer**: Move asset between locations/employees; records transfer with date and reason in `inv_asset_movements`
- 📐 **Disposal**: Mark asset as Disposed; fires event to Accounting to write off residual value

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L10.1.1.1 | Assign asset tag on GRN acceptance | 📐 Not Started |
| ST.L10.1.1.2 | Record warranty info | 📐 Not Started |
| ST.L10.2.1.1 | Record asset movement/transfer | 📐 Not Started |
| ST.L10.2.1.2 | Generate transfer slip PDF | 📐 Not Started |

#### FR-INV-012: Asset Maintenance Scheduling 📐

New in V2 — maps to RBS L5 maintenance sub-tasks.

- 📐 **Maintenance Schedule**: Per-asset or per-category recurring maintenance schedule (frequency: weekly/monthly/quarterly/annual)
- 📐 **Maintenance Log**: `inv_asset_maintenance` — records each maintenance event (date, type, cost, vendor, notes, next due date)
- 📐 **AMC Tracking**: Annual Maintenance Contract linked to vendor (`vnd_vendors`); cost and validity dates
- 📐 **Overdue Alert**: Notify store manager when maintenance is overdue (scheduled date passed without completion)

### 4.6 L6 — Procurement Workflow & Quotations

#### FR-INV-013: Quotation Comparison 📐

New in V2 — adds L6 quotation sub-workflow between PR and PO.

- 📐 **Request for Quotation (RFQ)**: From approved PR, generate RFQ to multiple vendors; record vendor responses
- 📐 **Quotation Header**: `inv_quotations` — RFQ number, source PR, validity date, status (draft/sent/received/expired)
- 📐 **Quotation Items**: Per vendor per item — quoted rate, lead time, remarks
- 📐 **Comparison Matrix**: Side-by-side comparison of vendor quotes for each item; lowest rate highlighted
- 📐 **Convert to PO**: Selected quotation lines converted to PO with pre-filled rates

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L6.3.1.1 | Create RFQ from approved PR | 📐 Not Started |
| ST.L6.3.1.2 | Record vendor quote responses | 📐 Not Started |
| ST.L6.3.1.3 | Compare quotations | 📐 Not Started |
| ST.L6.3.1.4 | Convert selected quote to PO | 📐 Not Started |

### 4.7 Stock Issue & Reorder

#### FR-INV-014: Stock Issue Workflow 📐

- 📐 **Issue Request**: Department staff submit request (items, qtys, required date); auto-number (IR-YYYY-NNNN)
- 📐 **Approval**: Store Keeper or HOD approves/rejects with reason
- 📐 **Stock Issue Execution**: Store Keeper confirms issue → deducts from godown balance → creates outward stock entry → fires `StockIssued` event → Accounting creates Stock Journal Voucher
- 📐 **Direct Issue**: Authorized Store Keeper can issue without formal request
- 📐 **Partial Issue**: Issue partial qty when full amount unavailable; request stays 'partial' until fully issued
- 📐 **Acknowledgment**: Receiver acknowledges receipt (acknowledged_by, acknowledged_at); mandatory for asset items

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L8.1.1.1 | Create issue request | 📐 Not Started |
| ST.L8.1.1.2 | Set required quantity | 📐 Not Started |
| ST.L8.2.1.1 | Execute issue and update ledger | 📐 Not Started |
| ST.L8.2.1.2 | Track consumption per department | 📐 Not Started |

#### FR-INV-015: Reorder Automation, Reports & Labels 📐

- 📐 **Reorder Alert**: `ReorderAlertService` compares `inv_stock_balances.current_qty` against `inv_stock_items.reorder_level` after every outward entry; dispatches notification event
- 📐 **Auto-PR**: Optional per-item setting; if enabled, auto-creates Draft PR for `reorder_qty` from preferred vendor
- 📐 **Barcode/QR Labels**: Print labels (item name, SKU, UOM, godown, batch); bulk print; A4 24-up/40-up templates; QR encodes `item_id|sku|godown_id`
- 📐 **Reports (12)**: Stock Balance, Stock Valuation, Stock Ledger, Consumption, Purchase Register, Pending PO, GRN Register, Reorder Alert, Fast/Slow Movers, Expiry Alerts, Godown-wise Stock, Asset Register — CSV/PDF export

| RBS Sub-Task | Description | Status |
|---|---|---|
| ST.L9.1.1.1 | Trigger alert below threshold | 📐 Not Started |
| ST.L9.1.1.2 | Notify store manager | 📐 Not Started |
| ST.L9.2.1.1 | Auto-calculate reorder qty | 📐 Not Started |
| ST.L11.1.1.1 | Export stock reports (CSV/PDF) | 📐 Not Started |
| ST.L11.2.1.1 | Identify fast/slow movers | 📐 Not Started |

---

## 5. Data Model

All 21 tables use prefix `inv_*`. Standard audit columns on every table: `id BIGINT UNSIGNED PK AUTO_INCREMENT`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK → sys_users`, `created_at TIMESTAMP`, `updated_at TIMESTAMP`, `deleted_at TIMESTAMP NULL`.

### 5.1 inv_stock_groups 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| name | VARCHAR(100) | NOT NULL | Group name |
| code | VARCHAR(20) | NULL UNIQUE | Short group code |
| alias | VARCHAR(100) | NULL | Alternative name |
| parent_id | BIGINT UNSIGNED | NULL FK → inv_stock_groups | Self-referencing hierarchy |
| default_uom_id | BIGINT UNSIGNED | NULL FK → inv_units_of_measure | Default UOM |
| sequence | INT | DEFAULT 0 | Display order |
| is_system | TINYINT(1) | DEFAULT 0 | Seeded — cannot delete |
| + standard audit cols | | | |

### 5.2 inv_units_of_measure 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| name | VARCHAR(50) | NOT NULL | e.g., "Pieces" |
| symbol | VARCHAR(10) | NOT NULL | e.g., "Pcs" |
| decimal_places | TINYINT | DEFAULT 0 | Precision (0 for Pcs, 2 for Kg) |
| is_system | TINYINT(1) | DEFAULT 0 | Seeded — cannot delete |
| + standard audit cols | | | |

### 5.3 inv_uom_conversions 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| from_uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Source UOM |
| to_uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | Target UOM |
| conversion_factor | DECIMAL(15,6) | NOT NULL | 1 from_uom = X to_uom |
| effective_from | DATE | NULL | |
| effective_to | DATE | NULL | |
| + standard audit cols | | | |

**Unique:** `(from_uom_id, to_uom_id)`

### 5.4 inv_stock_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| name | VARCHAR(150) | NOT NULL | |
| sku | VARCHAR(50) | NULL UNIQUE | Stock keeping unit |
| alias | VARCHAR(150) | NULL | |
| stock_group_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_groups | |
| uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | |
| item_type | ENUM('consumable','asset') | DEFAULT 'consumable' | |
| opening_balance_qty | DECIMAL(15,3) | DEFAULT 0 | |
| opening_balance_rate | DECIMAL(15,2) | DEFAULT 0 | |
| opening_balance_value | DECIMAL(15,2) | DEFAULT 0 | |
| valuation_method | ENUM('fifo','weighted_average','last_purchase') | DEFAULT 'weighted_average' | |
| reorder_level | DECIMAL(15,3) | NULL | Alert threshold |
| reorder_qty | DECIMAL(15,3) | NULL | Auto-reorder quantity |
| min_stock | DECIMAL(15,3) | NULL | |
| max_stock | DECIMAL(15,3) | NULL | |
| auto_reorder_pr | TINYINT(1) | DEFAULT 0 | Auto-create PR on reorder |
| has_batch_tracking | TINYINT(1) | DEFAULT 0 | |
| has_expiry_tracking | TINYINT(1) | DEFAULT 0 | |
| hsn_sac_code | VARCHAR(20) | NULL | GST code |
| brand | VARCHAR(100) | NULL | |
| model | VARCHAR(100) | NULL | |
| warranty_months | INT | NULL | For assets |
| tax_rate_id | BIGINT UNSIGNED | NULL FK → acc_tax_rates | GST rate |
| purchase_ledger_id | BIGINT UNSIGNED | NULL FK → acc_ledgers | |
| sales_ledger_id | BIGINT UNSIGNED | NULL FK → acc_ledgers | |
| + standard audit cols | | | |

### 5.5 inv_godowns 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| name | VARCHAR(100) | NOT NULL | e.g., "Main Store" |
| code | VARCHAR(20) | NULL UNIQUE | |
| parent_id | BIGINT UNSIGNED | NULL FK → inv_godowns | Sub-godown |
| address | VARCHAR(500) | NULL | |
| in_charge_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | |
| is_system | TINYINT(1) | DEFAULT 0 | |
| + standard audit cols | | | |

### 5.6 inv_stock_balances 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| stock_item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | |
| current_qty | DECIMAL(15,3) | DEFAULT 0 | Running balance |
| current_value | DECIMAL(15,2) | DEFAULT 0 | Running valuation |
| last_entry_at | TIMESTAMP | NULL | Last movement timestamp |
| + standard audit cols | | | |

**Unique:** `(stock_item_id, godown_id)`

### 5.7 inv_stock_entries 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| stock_item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | Source/destination |
| voucher_id | BIGINT UNSIGNED | NOT NULL FK → acc_vouchers | Mandatory link |
| entry_type | ENUM('inward','outward','transfer_in','transfer_out','adjustment') | NOT NULL | |
| quantity | DECIMAL(15,3) | NOT NULL | |
| rate | DECIMAL(15,2) | NOT NULL | Valuation rate |
| amount | DECIMAL(15,2) | NOT NULL | qty × rate |
| batch_number | VARCHAR(50) | NULL | |
| expiry_date | DATE | NULL | |
| destination_godown_id | BIGINT UNSIGNED | NULL FK → inv_godowns | Transfers only |
| party_ledger_id | BIGINT UNSIGNED | NULL FK → acc_ledgers | Vendor/dept ledger |
| narration | VARCHAR(500) | NULL | |
| + standard audit cols | | | |

**Indexes:** `(stock_item_id, godown_id, created_at)`, `(entry_type, created_at)`

### 5.8 inv_item_vendor_jnt 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | |
| vendor_sku | VARCHAR(50) | NULL | Vendor's own item code |
| last_purchase_rate | DECIMAL(15,2) | NULL | Auto-updated on GRN |
| last_purchase_date | DATE | NULL | |
| lead_time_days | INT | NULL | Delivery lead time |
| is_preferred | TINYINT(1) | DEFAULT 0 | |
| + standard audit cols | | | |

**Unique:** `(item_id, vendor_id)`

### 5.9 inv_rate_contracts 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | |
| contract_number | VARCHAR(50) | NULL UNIQUE | |
| valid_from | DATE | NOT NULL | |
| valid_to | DATE | NOT NULL | |
| status | ENUM('draft','active','expired','cancelled') | DEFAULT 'draft' | |
| remarks | TEXT | NULL | |
| + standard audit cols | | | |

### 5.10 inv_rate_contract_items_jnt 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| rate_contract_id | BIGINT UNSIGNED | NOT NULL FK → inv_rate_contracts CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| agreed_rate | DECIMAL(15,2) | NOT NULL | Fixed price per unit |
| min_qty | DECIMAL(15,3) | NULL | |
| max_qty | DECIMAL(15,3) | NULL | |
| + standard audit cols | | | |

**Unique:** `(rate_contract_id, item_id)`

### 5.11 inv_purchase_requisitions 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| pr_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., PR-2026-001 |
| requested_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | |
| department_id | BIGINT UNSIGNED | NULL FK → sch_department | Singular table name |
| required_date | DATE | NOT NULL | |
| priority | ENUM('low','normal','high','urgent') | DEFAULT 'normal' | |
| status | ENUM('draft','submitted','approved','rejected','converted','cancelled') | DEFAULT 'draft' | |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | |
| approved_at | TIMESTAMP | NULL | |
| remarks | TEXT | NULL | |
| + standard audit cols | | | |

### 5.12 inv_purchase_requisition_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| pr_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_requisitions CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| qty | DECIMAL(15,3) | NOT NULL | |
| uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | |
| estimated_rate | DECIMAL(15,2) | NULL | |
| remarks | VARCHAR(255) | NULL | |
| + standard audit cols | | | |

### 5.13 inv_quotations 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| rfq_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., RFQ-2026-001 |
| pr_id | BIGINT UNSIGNED | NULL FK → inv_purchase_requisitions | Source PR |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | |
| validity_date | DATE | NULL | Quote valid until |
| status | ENUM('draft','sent','received','expired','converted') | DEFAULT 'draft' | |
| notes | TEXT | NULL | |
| + standard audit cols | | | |

### 5.14 inv_quotation_items 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| quotation_id | BIGINT UNSIGNED | NOT NULL FK → inv_quotations CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| quoted_rate | DECIMAL(15,2) | NOT NULL | |
| lead_time_days | INT | NULL | |
| remarks | VARCHAR(255) | NULL | |
| + standard audit cols | | | |

### 5.15 inv_purchase_orders 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| po_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., PO-2026-001 |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | |
| pr_id | BIGINT UNSIGNED | NULL FK → inv_purchase_requisitions | Source PR |
| quotation_id | BIGINT UNSIGNED | NULL FK → inv_quotations | Source quotation (V2 addition) |
| order_date | DATE | NOT NULL | |
| expected_delivery_date | DATE | NULL | |
| status | ENUM('draft','sent','partial','received','cancelled','closed') | DEFAULT 'draft' | |
| total_amount | DECIMAL(15,2) | DEFAULT 0 | Pre-tax |
| tax_amount | DECIMAL(15,2) | DEFAULT 0 | |
| discount_amount | DECIMAL(15,2) | DEFAULT 0 | |
| net_amount | DECIMAL(15,2) | DEFAULT 0 | Final payable |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | |
| approval_threshold_amount | DECIMAL(15,2) | NULL | Captured at time of PO |
| terms_and_conditions | TEXT | NULL | |
| + standard audit cols | | | |

### 5.16 inv_purchase_order_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| po_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_orders CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| ordered_qty | DECIMAL(15,3) | NOT NULL | |
| received_qty | DECIMAL(15,3) | DEFAULT 0 | Auto-updated on GRN |
| unit_price | DECIMAL(15,2) | NOT NULL | |
| tax_rate_id | BIGINT UNSIGNED | NULL FK → acc_tax_rates | |
| discount_percent | DECIMAL(5,2) | DEFAULT 0 | |
| total_amount | DECIMAL(15,2) | NOT NULL | Line total |
| + standard audit cols | | | |

### 5.17 inv_goods_receipt_notes 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| grn_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., GRN-2026-001 |
| po_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_orders | |
| vendor_id | BIGINT UNSIGNED | NOT NULL FK → vnd_vendors | |
| receipt_date | DATE | NOT NULL | |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | Receiving location |
| status | ENUM('draft','inspected','accepted','partial','rejected') | DEFAULT 'draft' | |
| qc_status | ENUM('pending','passed','failed','partial') | DEFAULT 'pending' | |
| qc_notes | TEXT | NULL | |
| received_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | |
| voucher_id | BIGINT UNSIGNED | NULL FK → acc_vouchers | Set on acceptance |
| + standard audit cols | | | |

### 5.18 inv_grn_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| grn_id | BIGINT UNSIGNED | NOT NULL FK → inv_goods_receipt_notes CASCADE DELETE | |
| po_item_id | BIGINT UNSIGNED | NOT NULL FK → inv_purchase_order_items | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| received_qty | DECIMAL(15,3) | NOT NULL | |
| accepted_qty | DECIMAL(15,3) | NOT NULL | |
| rejected_qty | DECIMAL(15,3) | DEFAULT 0 | |
| unit_cost | DECIMAL(15,2) | NOT NULL | Actual cost |
| batch_number | VARCHAR(50) | NULL | |
| expiry_date | DATE | NULL | |
| qc_remarks | VARCHAR(255) | NULL | |
| + standard audit cols | | | |

### 5.19 inv_issue_requests 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| request_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., IR-2026-001 |
| requested_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | |
| department_id | BIGINT UNSIGNED | NOT NULL FK → sch_department | Singular |
| required_date | DATE | NOT NULL | |
| status | ENUM('submitted','approved','issued','partial','rejected') | DEFAULT 'submitted' | |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | |
| remarks | TEXT | NULL | |
| + standard audit cols | | | |

### 5.20 inv_issue_request_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| issue_request_id | BIGINT UNSIGNED | NOT NULL FK → inv_issue_requests CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| requested_qty | DECIMAL(15,3) | NOT NULL | |
| issued_qty | DECIMAL(15,3) | DEFAULT 0 | Updated as issued |
| uom_id | BIGINT UNSIGNED | NOT NULL FK → inv_units_of_measure | |
| + standard audit cols | | | |

### 5.21 inv_stock_issues 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| issue_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., SI-2026-001 |
| issue_request_id | BIGINT UNSIGNED | NULL FK → inv_issue_requests | From request (nullable for direct) |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | Source godown |
| issued_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Store Keeper |
| issued_to_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | Receiving employee |
| department_id | BIGINT UNSIGNED | NOT NULL FK → sch_department | |
| issue_date | DATE | NOT NULL | |
| voucher_id | BIGINT UNSIGNED | NULL FK → acc_vouchers | Stock Journal |
| acknowledged_by | BIGINT UNSIGNED | NULL FK → sys_users | |
| acknowledged_at | TIMESTAMP | NULL | |
| + standard audit cols | | | |

### 5.22 inv_stock_issue_items 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| stock_issue_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_issues CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| qty | DECIMAL(15,3) | NOT NULL | |
| unit_cost | DECIMAL(15,2) | NOT NULL | Valuation cost |
| batch_number | VARCHAR(50) | NULL | |
| + standard audit cols | | | |

### 5.23 inv_stock_adjustments 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| adjustment_number | VARCHAR(50) | NOT NULL UNIQUE | e.g., ADJ-2026-001 |
| adjustment_date | DATE | NOT NULL | |
| godown_id | BIGINT UNSIGNED | NOT NULL FK → inv_godowns | |
| reason | VARCHAR(500) | NULL | |
| status | ENUM('draft','submitted','approved','rejected','posted') | DEFAULT 'draft' | |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | |
| approved_at | TIMESTAMP | NULL | |
| + standard audit cols | | | |

### 5.24 inv_stock_adjustment_items 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| adjustment_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_adjustments CASCADE DELETE | |
| item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | |
| system_qty | DECIMAL(15,3) | NOT NULL | Balance per system at time of audit |
| physical_qty | DECIMAL(15,3) | NOT NULL | Physically counted |
| variance_qty | DECIMAL(15,3) | GENERATED ALWAYS AS (physical_qty - system_qty) STORED | Positive = surplus |
| unit_cost | DECIMAL(15,2) | NOT NULL | Valuation rate |
| + standard audit cols | | | |

### 5.25 inv_asset_categories 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| name | VARCHAR(100) | NOT NULL | e.g., "IT Equipment" |
| code | VARCHAR(20) | NULL UNIQUE | |
| depreciation_rate | DECIMAL(5,2) | NULL | % per annum WDV method |
| useful_life_years | INT | NULL | Income Tax Act basis |
| + standard audit cols | | | |

### 5.26 inv_assets 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| asset_tag | VARCHAR(50) | NOT NULL UNIQUE | Auto-generated e.g., ASSET-2026-001 |
| asset_category_id | BIGINT UNSIGNED | NOT NULL FK → inv_asset_categories | |
| stock_item_id | BIGINT UNSIGNED | NOT NULL FK → inv_stock_items | Parent item |
| grn_item_id | BIGINT UNSIGNED | NULL FK → inv_grn_items | Source GRN item |
| purchase_date | DATE | NULL | |
| purchase_cost | DECIMAL(15,2) | NULL | |
| current_book_value | DECIMAL(15,2) | NULL | Synced from Accounting |
| acc_fixed_asset_id | BIGINT UNSIGNED | NULL FK → acc_fixed_assets | Accounting record |
| godown_id | BIGINT UNSIGNED | NULL FK → inv_godowns | Current location |
| assigned_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | |
| condition | ENUM('good','fair','poor','under_repair','disposed') | DEFAULT 'good' | |
| warranty_expiry_date | DATE | NULL | |
| + standard audit cols | | | |

### 5.27 inv_asset_movements 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| asset_id | BIGINT UNSIGNED | NOT NULL FK → inv_assets | |
| movement_date | DATE | NOT NULL | |
| from_godown_id | BIGINT UNSIGNED | NULL FK → inv_godowns | |
| to_godown_id | BIGINT UNSIGNED | NULL FK → inv_godowns | |
| from_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | |
| to_employee_id | BIGINT UNSIGNED | NULL FK → sch_employees | |
| reason | VARCHAR(500) | NULL | |
| moved_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | |
| + standard audit cols | | | |

### 5.28 inv_asset_maintenance 📐 (New in V2)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | |
| asset_id | BIGINT UNSIGNED | NOT NULL FK → inv_assets | |
| maintenance_date | DATE | NOT NULL | |
| maintenance_type | ENUM('preventive','corrective','amc','calibration') | NOT NULL | |
| vendor_id | BIGINT UNSIGNED | NULL FK → vnd_vendors | AMC vendor |
| cost | DECIMAL(15,2) | NULL | |
| notes | TEXT | NULL | |
| next_due_date | DATE | NULL | |
| status | ENUM('scheduled','completed','overdue') | DEFAULT 'scheduled' | |
| + standard audit cols | | | |

### 5.29 Cross-Module FK Dependencies

| FK Column | References | Module Owner |
|---|---|---|
| `acc_vouchers.id` | `inv_stock_entries.voucher_id`, `inv_stock_issues.voucher_id`, `inv_purchase_orders.voucher_id`, `inv_goods_receipt_notes.voucher_id` | Accounting |
| `acc_tax_rates.id` | `inv_stock_items.tax_rate_id`, `inv_purchase_order_items.tax_rate_id` | Accounting |
| `acc_ledgers.id` | `inv_stock_items.purchase_ledger_id`, `inv_stock_items.sales_ledger_id`, `inv_stock_entries.party_ledger_id` | Accounting |
| `acc_fixed_assets.id` | `inv_assets.acc_fixed_asset_id` | Accounting |
| `vnd_vendors.id` | `inv_item_vendor_jnt.vendor_id`, `inv_rate_contracts.vendor_id`, `inv_purchase_orders.vendor_id`, `inv_goods_receipt_notes.vendor_id`, `inv_quotations.vendor_id`, `inv_asset_maintenance.vendor_id` | Vendor |
| `sch_employees.id` | `inv_godowns.in_charge_employee_id`, `inv_stock_issues.issued_to_employee_id`, `inv_assets.assigned_employee_id` | SchoolSetup |
| `sch_department.id` | `inv_purchase_requisitions.department_id`, `inv_issue_requests.department_id`, `inv_stock_issues.department_id` | SchoolSetup |
| `sys_users.id` | All `created_by`, `approved_by`, `requested_by`, `issued_by`, `received_by`, `moved_by` | System |

---

## 6. API & Route Specification

All routes registered in `routes/tenant.php` under `inventory/` prefix with `auth` and tenant middleware. Route name prefix: `inventory.*`.

### 6.1 Master Setup Routes 📐

| Route Pattern | Method(s) | Controller | Action(s) |
|---|---|---|---|
| `inventory/stock-groups` | GET, POST | StockGroupController | index, store |
| `inventory/stock-groups/{id}` | GET, PUT, DELETE | StockGroupController | show, update, destroy |
| `inventory/stock-groups/{id}/toggle-status` | POST | StockGroupController | toggleStatus |
| `inventory/uom` | GET, POST | UomController | index, store |
| `inventory/uom/{id}` | GET, PUT, DELETE | UomController | show, update, destroy |
| `inventory/uom-conversions` | GET, POST | UomController | indexConversions, storeConversion |
| `inventory/uom-conversions/{id}` | PUT, DELETE | UomController | updateConversion, destroyConversion |
| `inventory/stock-items` | GET, POST | StockItemController | index, store |
| `inventory/stock-items/{id}` | GET, PUT, DELETE | StockItemController | show, update, destroy |
| `inventory/stock-items/{id}/toggle-status` | POST | StockItemController | toggleStatus |
| `inventory/stock-items/{id}/labels` | GET | StockItemController | printLabels |
| `inventory/godowns` | GET, POST | GodownController | index, store |
| `inventory/godowns/{id}` | GET, PUT, DELETE | GodownController | show, update, destroy |
| `inventory/asset-categories` | GET, POST | AssetCategoryController | index, store |
| `inventory/asset-categories/{id}` | GET, PUT, DELETE | AssetCategoryController | show, update, destroy |

### 6.2 Vendor Linkage Routes 📐

| Route Pattern | Method(s) | Controller | Action(s) |
|---|---|---|---|
| `inventory/item-vendors` | GET, POST | ItemVendorController | index, store |
| `inventory/item-vendors/{id}` | PUT, DELETE | ItemVendorController | update, destroy |
| `inventory/rate-contracts` | GET, POST | RateContractController | index, store |
| `inventory/rate-contracts/{id}` | GET, PUT, DELETE | RateContractController | show, update, destroy |
| `inventory/rate-contracts/{id}/activate` | POST | RateContractController | activate |
| `inventory/rate-contracts/{id}/items` | GET, POST | RateContractController | items, storeItem |
| `inventory/rate-contracts/{id}/items/{item}` | PUT, DELETE | RateContractController | updateItem, destroyItem |

### 6.3 Procurement Routes 📐

| Route Pattern | Method(s) | Controller | Action(s) |
|---|---|---|---|
| `inventory/purchase-requisitions` | GET, POST | PurchaseRequisitionController | index, store |
| `inventory/purchase-requisitions/{id}` | GET, PUT, DELETE | PurchaseRequisitionController | show, update, destroy |
| `inventory/purchase-requisitions/{id}/submit` | POST | PurchaseRequisitionController | submit |
| `inventory/purchase-requisitions/{id}/approve` | POST | PurchaseRequisitionController | approve |
| `inventory/purchase-requisitions/{id}/reject` | POST | PurchaseRequisitionController | reject |
| `inventory/purchase-requisitions/import` | POST | PurchaseRequisitionController | import |
| `inventory/quotations` | GET, POST | QuotationController | index, store |
| `inventory/quotations/{id}` | GET, PUT, DELETE | QuotationController | show, update, destroy |
| `inventory/quotations/compare` | GET | QuotationController | compare |
| `inventory/quotations/{id}/convert-to-po` | POST | QuotationController | convertToPO |
| `inventory/purchase-orders` | GET, POST | PurchaseOrderController | index, store |
| `inventory/purchase-orders/{id}` | GET, PUT, DELETE | PurchaseOrderController | show, update, destroy |
| `inventory/purchase-orders/{id}/send` | POST | PurchaseOrderController | sendToVendor |
| `inventory/purchase-orders/{id}/approve` | POST | PurchaseOrderController | approve |
| `inventory/purchase-orders/{id}/cancel` | POST | PurchaseOrderController | cancel |
| `inventory/purchase-orders/convert-pr/{pr}` | POST | PurchaseOrderController | convertFromPR |
| `inventory/grn` | GET, POST | GrnController | index, store |
| `inventory/grn/{id}` | GET, PUT, DELETE | GrnController | show, update, destroy |
| `inventory/grn/{id}/inspect` | POST | GrnController | inspect |
| `inventory/grn/{id}/accept` | POST | GrnController | accept |
| `inventory/grn/{id}/reject` | POST | GrnController | reject |

### 6.4 Stock Issue Routes 📐

| Route Pattern | Method(s) | Controller | Action(s) |
|---|---|---|---|
| `inventory/issue-requests` | GET, POST | IssueRequestController | index, store |
| `inventory/issue-requests/{id}` | GET, PUT, DELETE | IssueRequestController | show, update, destroy |
| `inventory/issue-requests/{id}/approve` | POST | IssueRequestController | approve |
| `inventory/issue-requests/{id}/reject` | POST | IssueRequestController | reject |
| `inventory/stock-issues` | GET, POST | StockIssueController | index, store |
| `inventory/stock-issues/{id}` | GET | StockIssueController | show |
| `inventory/stock-issues/{id}/acknowledge` | POST | StockIssueController | acknowledge |
| `inventory/stock-issues/{id}/print` | GET | StockIssueController | printSlip |
| `inventory/stock-entries` | GET | StockEntryController | index |
| `inventory/stock-entries/{id}` | GET | StockEntryController | show |

### 6.5 Asset Routes 📐

| Route Pattern | Method(s) | Controller | Action(s) |
|---|---|---|---|
| `inventory/assets` | GET | AssetController | index |
| `inventory/assets/{id}` | GET, PUT | AssetController | show, update |
| `inventory/assets/{id}/transfer` | POST | AssetController | transfer |
| `inventory/assets/{id}/dispose` | POST | AssetController | dispose |
| `inventory/assets/{id}/maintenance` | GET, POST | AssetController | maintenanceIndex, storeMaintenance |
| `inventory/assets/{id}/print-tag` | GET | AssetController | printTag |

### 6.6 Adjustment & Report Routes 📐

| Route Pattern | Method(s) | Controller | Action(s) |
|---|---|---|---|
| `inventory/stock-adjustments` | GET, POST | StockAdjustmentController | index, store |
| `inventory/stock-adjustments/{id}` | GET, PUT | StockAdjustmentController | show, update |
| `inventory/stock-adjustments/{id}/submit` | POST | StockAdjustmentController | submit |
| `inventory/stock-adjustments/{id}/approve` | POST | StockAdjustmentController | approve |
| `inventory/stock-adjustments/{id}/reject` | POST | StockAdjustmentController | reject |
| `inventory/dashboard` | GET | InvDashboardController | index |
| `inventory/reports/stock-balance` | GET | InvReportController | stockBalance |
| `inventory/reports/stock-valuation` | GET | InvReportController | stockValuation |
| `inventory/reports/stock-ledger` | GET | InvReportController | stockLedger |
| `inventory/reports/consumption` | GET | InvReportController | consumption |
| `inventory/reports/purchase-register` | GET | InvReportController | purchaseRegister |
| `inventory/reports/pending-po` | GET | InvReportController | pendingPO |
| `inventory/reports/grn-register` | GET | InvReportController | grnRegister |
| `inventory/reports/reorder-alerts` | GET | InvReportController | reorderAlerts |
| `inventory/reports/fast-slow-movers` | GET | InvReportController | fastSlowMovers |
| `inventory/reports/expiry-alerts` | GET | InvReportController | expiryAlerts |
| `inventory/reports/asset-register` | GET | InvReportController | assetRegister |
| `inventory/reports/{type}/export` | GET | InvReportController | export |

**Total proposed routes: ~65**

---

## 7. UI Screen Inventory

All screens are Blade views using the platform's standard layout. Naming follows `resources/views/inventory/` namespace.

| Screen ID | Screen Name | View File | Controller Method |
|---|---|---|---|
| SCR-INV-01 | Inventory Dashboard | `inventory/dashboard.blade.php` | InvDashboardController@index |
| SCR-INV-02 | Stock Groups List | `inventory/masters/stock-groups/index.blade.php` | StockGroupController@index |
| SCR-INV-03 | Stock Groups Form | `inventory/masters/stock-groups/form.blade.php` | StockGroupController@create/edit |
| SCR-INV-04 | UOM List | `inventory/masters/uom/index.blade.php` | UomController@index |
| SCR-INV-05 | UOM Conversion List | `inventory/masters/uom/conversions.blade.php` | UomController@indexConversions |
| SCR-INV-06 | Stock Items List | `inventory/masters/items/index.blade.php` | StockItemController@index |
| SCR-INV-07 | Stock Item Form | `inventory/masters/items/form.blade.php` | StockItemController@create/edit |
| SCR-INV-08 | Stock Item Label Print | `inventory/masters/items/labels.blade.php` | StockItemController@printLabels |
| SCR-INV-09 | Godown List | `inventory/masters/godowns/index.blade.php` | GodownController@index |
| SCR-INV-10 | Item-Vendor Linkage | `inventory/vendor/item-vendors.blade.php` | ItemVendorController@index |
| SCR-INV-11 | Rate Contracts List | `inventory/vendor/rate-contracts/index.blade.php` | RateContractController@index |
| SCR-INV-12 | Rate Contract Form | `inventory/vendor/rate-contracts/form.blade.php` | RateContractController@show |
| SCR-INV-13 | PR List | `inventory/procurement/pr/index.blade.php` | PurchaseRequisitionController@index |
| SCR-INV-14 | PR Form | `inventory/procurement/pr/form.blade.php` | PurchaseRequisitionController@create/edit |
| SCR-INV-15 | PR Detail / Approval | `inventory/procurement/pr/show.blade.php` | PurchaseRequisitionController@show |
| SCR-INV-16 | PR CSV Import | `inventory/procurement/pr/import.blade.php` | PurchaseRequisitionController@import |
| SCR-INV-17 | Quotation List | `inventory/procurement/quotations/index.blade.php` | QuotationController@index |
| SCR-INV-18 | Quotation Comparison | `inventory/procurement/quotations/compare.blade.php` | QuotationController@compare |
| SCR-INV-19 | PO List | `inventory/procurement/po/index.blade.php` | PurchaseOrderController@index |
| SCR-INV-20 | PO Form | `inventory/procurement/po/form.blade.php` | PurchaseOrderController@create/edit |
| SCR-INV-21 | PO Detail | `inventory/procurement/po/show.blade.php` | PurchaseOrderController@show |
| SCR-INV-22 | GRN List | `inventory/procurement/grn/index.blade.php` | GrnController@index |
| SCR-INV-23 | GRN Form | `inventory/procurement/grn/form.blade.php` | GrnController@create/edit |
| SCR-INV-24 | GRN Detail / QC | `inventory/procurement/grn/show.blade.php` | GrnController@show |
| SCR-INV-25 | Issue Request List | `inventory/issue/requests/index.blade.php` | IssueRequestController@index |
| SCR-INV-26 | Issue Request Form | `inventory/issue/requests/form.blade.php` | IssueRequestController@create |
| SCR-INV-27 | Issue Request Approval | `inventory/issue/requests/show.blade.php` | IssueRequestController@show |
| SCR-INV-28 | Stock Issue List | `inventory/issue/issues/index.blade.php` | StockIssueController@index |
| SCR-INV-29 | Stock Issue Form | `inventory/issue/issues/form.blade.php` | StockIssueController@create |
| SCR-INV-30 | Issue Slip PDF | `inventory/issue/issues/slip.blade.php` (DomPDF) | StockIssueController@printSlip |
| SCR-INV-31 | Stock Ledger View | `inventory/stock/ledger.blade.php` | StockEntryController@index |
| SCR-INV-32 | Stock Balance View | `inventory/stock/balance.blade.php` | InvReportController@stockBalance |
| SCR-INV-33 | Stock Adjustment List | `inventory/stock/adjustments/index.blade.php` | StockAdjustmentController@index |
| SCR-INV-34 | Stock Adjustment Form | `inventory/stock/adjustments/form.blade.php` | StockAdjustmentController@create |
| SCR-INV-35 | Asset Register | `inventory/assets/index.blade.php` | AssetController@index |
| SCR-INV-36 | Asset Detail | `inventory/assets/show.blade.php` | AssetController@show |
| SCR-INV-37 | Asset Transfer Form | `inventory/assets/transfer.blade.php` | AssetController@transfer |
| SCR-INV-38 | Asset Tag Print | `inventory/assets/tag.blade.php` (DomPDF) | AssetController@printTag |
| SCR-INV-39 | Maintenance Schedule | `inventory/assets/maintenance.blade.php` | AssetController@maintenanceIndex |
| SCR-INV-40 | Inventory Dashboard Reports | `inventory/reports/*.blade.php` (12 views) | InvReportController |

**Total screens: ~65 Blade views**

---

## 8. Business Rules

| Rule ID | Rule Description | Source |
|---|---|---|
| BR-INV-001 | Every `inv_stock_entries` record MUST have a non-null `voucher_id` — no orphan stock movements allowed | V1 |
| BR-INV-002 | Stock is NOT updated in `inv_stock_balances` until GRN status transitions to 'accepted' | V1 |
| BR-INV-003 | Negative stock is not permitted — outward/issue entry is rejected with a user-facing error if `current_qty < requested_qty` | V1 / BR-L-001 |
| BR-INV-004 | Converted PR lines cannot be edited — PRs with status 'converted' are read-only | V1 |
| BR-INV-005 | PO auto-transitions to 'received' when all line items have `received_qty >= ordered_qty` | V1 |
| BR-INV-006 | GRN `accepted_qty + rejected_qty` MUST equal `received_qty` — enforced at validation layer | V1 / BR-L-003 |
| BR-INV-007 | GRN `received_qty` per item cannot exceed `(PO ordered_qty - already received qty)` across all prior GRNs | V1 / BR-L-003 |
| BR-INV-008 | When batch tracking is enabled on an item, outward entries must use FIFO batch selection (oldest batch number first) | V1 |
| BR-INV-009 | Stock valuation method (FIFO / Weighted Average / Last Purchase Cost) is configured per item; issue cost calculated using item's method | V1 |
| BR-INV-010 | Stock issue requires an approved issue request unless issuer has `inventory.stock-issue.direct` permission | V1 |
| BR-INV-011 | Reorder alert fires when `current_qty <= reorder_level` after every outward stock entry; dispatched as async queued job | V1 |
| BR-INV-012 | Asset-type items trigger `inv_assets` and `acc_fixed_assets` record creation on GRN acceptance (one record per unit, quantity must be integer) | V1 |
| BR-INV-013 | Active rate contract pricing auto-populates PO item unit price; expired contracts are ignored | V1 |
| BR-INV-014 | Stock entries are immutable once posted — corrections via new adjustment entries only; no UPDATE/DELETE on posted entries | V1 |
| BR-INV-015 | No `tenant_id` column on any `inv_*` table — data isolation is at DB level via stancl/tenancy | V1 |
| BR-INV-016 | POs above the school-configurable approval threshold amount require explicit approval action before 'sent' status | V2 / BR-L-002 |
| BR-INV-017 | Stock adjustments above configurable value threshold require Principal/Admin approval before posting | V2 |
| BR-INV-018 | Asset depreciation is calculated annually per Income Tax Act rates using WDV method; computation delegated to Accounting module | V2 / BR-L-004 |

---

## 9. Workflow & State Machines

### 9.1 Procurement Workflow FSM

Complete procurement lifecycle from need identification to stock entry:

```
[Need Identified]
      |
      v
[PR: Draft] --submit()--> [PR: Submitted] --approve()--> [PR: Approved]
                                               |
                                           reject()
                                               |
                                               v
                                         [PR: Rejected]

[PR: Approved] --convertToPO()--> [PR: Converted]
      |
      v (optional quotation step)
[RFQ: Draft] --send()--> [RFQ: Sent] --receiveQuotes()--> [RFQ: Received]
      |
  compare & select
      |
      v
[PO: Draft] --approve()--> [PO: Approved] --sendToVendor()--> [PO: Sent]
      |
  cancel()
      |
      v
[PO: Cancelled]

[PO: Sent] --partialGRN()--> [PO: Partial] --finalGRN()--> [PO: Received] --close()--> [PO: Closed]

[GRN: Draft] --inspect()--> [GRN: Inspected] --accept()--> [GRN: Accepted]
                                                   |            |
                                               reject()    partialAccept()
                                                   |            |
                                                   v            v
                                            [GRN: Rejected] [GRN: Partial]

[GRN: Accepted] --fires--> GrnAccepted event
      |
      +---> inv_stock_entries (inward) created
      +---> inv_stock_balances updated
      +---> Accounting: Purchase Voucher created (via VoucherServiceInterface)
      +---> inv_item_vendor_jnt: last_purchase_rate updated
      +---> [if asset item]: inv_assets + acc_fixed_assets created
      +---> [if balance <= reorder_level]: ReorderAlertJob dispatched
```

### 9.2 Stock Issue Workflow FSM

```
[Issue Request: Submitted] --approve()--> [Issue Request: Approved]
                                 |
                             reject()
                                 |
                                 v
                          [Issue Request: Rejected]

[Issue Request: Approved] --executeIssue()--> [Issue Request: Issued]
                                  |
                          partialIssue()
                                  |
                                  v
                          [Issue Request: Partial] --completeIssue()--> [Issue Request: Issued]

[Stock Issue created] --fires--> StockIssued event
      |
      +---> inv_stock_entries (outward) created
      +---> inv_stock_balances updated (deducted)
      +---> Accounting: Stock Journal Voucher created
      +---> [if balance <= reorder_level]: ReorderAlertJob dispatched
      +---> [pending acknowledgment]

[Stock Issue] --acknowledge()--> [acknowledged_by set, acknowledged_at set]
```

### 9.3 Asset Lifecycle FSM

```
[GRN Accepted for asset item]
      |
      v
[Asset: Good] <-- created automatically per unit
      |
      +--transfer()--> [location/employee updated, inv_asset_movements recorded]
      |
      +--conditionUpdate()--> [Good | Fair | Poor | Under Repair]
      |
      +--maintenance()--> [inv_asset_maintenance record created]
      |
      +--dispose()--> [Asset: Disposed]
                           |
                           v
                    [acc_fixed_assets: write-off event fired to Accounting]
```

### 9.4 Stock Adjustment Workflow FSM

```
[Adjustment: Draft] --submit()--> [Adjustment: Submitted]
                                        |
                                    approve()
                                        |
                                        v
                               [Adjustment: Approved]
                                        |
                                    post()
                                        |
                                        v
                               [Adjustment: Posted]
                                        |
                     +------------------+------------------+
                     |                                     |
               (variance > 0)                       (variance < 0)
               Surplus: inward entry                Deficit: outward entry
               inv_stock_entries                    inv_stock_entries
               (adjustment type)                    (adjustment type)
```

### 9.5 Reorder Alert Sequence

```
StockIssueService::executeIssue()
    |
    +---> inv_stock_balances.current_qty updated
    |
    +---> if (current_qty <= reorder_level):
              dispatch(new ReorderAlertJob($item))
                    |
                    +---> Notify store manager via NTF module
                    |
                    +---> if (auto_reorder_pr == true):
                              PurchaseRequisitionService::createAutoReorderPR($item)
                                    |
                                    +---> inv_purchase_requisitions (status: draft)
                                    +---> inv_purchase_requisition_items (preferred vendor rate)
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Requirement | Target |
|---|---|
| Stock balance query (single item, all godowns) | < 500ms |
| Stock balance query (all items, single godown) | < 2 seconds for up to 5,000 items |
| Report generation (12 months of data) | < 10 seconds |
| GRN acceptance transaction (entry + balance + voucher) | < 3 seconds |
| Reorder alert check | Async (queued job); does not block GRN/Issue response |
| Dashboard KPI widgets | < 2 seconds with eager-loaded aggregates |

### 10.2 Reliability

- 📐 GRN acceptance wraps stock entry creation, balance update, voucher posting, and vendor rate update in a single DB transaction — all succeed or all rollback
- 📐 Stock issue wraps stock entry, balance deduction, and voucher posting in a single DB transaction
- 📐 Stock adjustments posted atomically; variance entry and balance update in same transaction
- 📐 `ReorderAlertJob` uses Laravel retry mechanism (3 attempts, 60s delay) for notification delivery failures

### 10.3 Data Integrity

- 📐 No `tenant_id` column — tenant isolation at DB level
- 📐 `inv_stock_balances` row-level lock (`lockForUpdate()`) prevents race conditions on concurrent stock movements
- 📐 `inv_stock_entries` is append-only — no UPDATE/DELETE after insert; application-level and DB-level protection
- 📐 Soft deletes (`deleted_at`) on all tables; no physical deletion of inventory records
- 📐 `inv_stock_balances` can be rebuilt from scratch via `inventory:recalculate-balances` Artisan command

### 10.4 Security & Authorization

- 📐 All routes protected by `auth` middleware; tenant context enforced by stancl/tenancy
- 📐 Gate-based permission checks using `sys_permissions` table (see Section 3)
- 📐 Every stock movement logged in `sys_activity_logs` with user, timestamp, and payload
- 📐 PO approval threshold enforced server-side (not just UI); direct database writes checked in service layer

### 10.5 Scalability

- 📐 `inv_stock_entries`: Index on `(stock_item_id, godown_id, created_at)` and `(entry_type, created_at)`
- 📐 `inv_stock_balances`: Index on `(stock_item_id, godown_id)` for O(1) balance lookups
- 📐 `inv_assets`: Index on `(stock_item_id)`, `(asset_tag)`, `(condition)` for register queries
- 📐 Report queries use chunking (`chunk(500)`) for large exports to avoid memory exhaustion
- 📐 Barcode/QR label generation batched with a configurable per-request limit (default: 200 labels)

### 10.6 Compliance

- 📐 GST: HSN/SAC codes on items; CGST+SGST (intrastate) or IGST (interstate) captured on PO items
- 📐 Stock Register: PDF export of stock balance in government-prescribed format for government-aided schools
- 📐 Fixed Asset Register: Depreciation per Income Tax Act rates (WDV method) via Accounting module
- 📐 Audit Trail: All approvals, stock movements, and adjustments logged with user and timestamp

---

## 11. Cross-Module Dependencies

### 11.1 Inbound Dependencies (Inventory reads from)

| Module | Table(s) Referenced | Purpose |
|---|---|---|
| Vendor (VND) | `vnd_vendors` | PO vendor selection, Rate contracts, GRN vendor |
| SchoolSetup (SCH) | `sch_department` (singular) | PR department, Issue request department |
| SchoolSetup (SCH) | `sch_employees` | Godown in-charge, Asset assigned employee |
| Accounting (ACC) | `acc_ledgers` | Purchase ledger, sales ledger, party ledger on entries |
| Accounting (ACC) | `acc_tax_rates` | GST rate on items and PO lines |
| Accounting (ACC) | `acc_vouchers` | Mandatory FK on every stock entry |
| Accounting (ACC) | `acc_fixed_assets` | Asset linkage via `inv_assets.acc_fixed_asset_id` |
| System (SYS) | `sys_users`, `sys_permissions` | User references, RBAC |

### 11.2 Outbound Events (Inventory fires, others listen)

| Event | Fired When | Consumer Module | Action Taken |
|---|---|---|---|
| `GrnAccepted` | GRN status → 'accepted' | Accounting (ACC) | Creates Purchase Voucher (Dr Stock-in-Hand A/c, Cr Vendor Creditor A/c) |
| `StockIssued` | Stock issue confirmed | Accounting (ACC) | Creates Stock Journal (Dr Dept Consumption A/c, Cr Stock-in-Hand A/c) |
| `StockTransferred` | Stock transfer between godowns | Accounting (ACC) | Creates Stock Journal (Dr Destination, Cr Source) |
| `StockAdjusted` | Adjustment approved + posted | Accounting (ACC) | Creates Journal Entry (Dr/Cr Stock-in-Hand A/c) |
| `AssetDisposed` | Asset marked 'disposed' | Accounting (ACC) | Write-off residual value in acc_fixed_assets |
| `ReorderThresholdReached` | Balance <= reorder_level | Notification (NTF) | Alert notification to store manager |
| `RateContractExpiringSoon` | 30 days before expiry | Notification (NTF) | Alert to store manager |
| `MaintenanceOverdue` | Maintenance scheduled date passed | Notification (NTF) | Alert to store manager |

### 11.3 Accounting Integration Detail (Decision D21)

Per D21, Inventory fires domain events and Accounting subscribes via event listeners:

```php
// Event payload for GrnAccepted
class GrnAccepted {
    public int $grn_id;
    public int $vendor_id;
    public int $godown_id;
    public array $items; // [{item_id, qty, rate, amount, batch_number}]
    public float $total_amount;
    public int $purchase_ledger_id;
    public int $party_ledger_id; // Vendor creditor
    public string $narration;
}

// Event payload for StockIssued
class StockIssued {
    public int $stock_issue_id;
    public int $department_id;
    public int $godown_id;
    public array $items; // [{item_id, qty, rate, amount}]
    public float $total_amount;
    public int $stock_ledger_id;   // Stock-in-hand account
    public int $expense_ledger_id; // Dept consumption account
    public string $narration;
}
```

### 11.4 Module Independence

- Inventory does NOT call Accounting service methods directly — it fires events; Accounting subscribes
- `VoucherServiceInterface` is owned by Accounting; Inventory references the interface only
- Library module books are NOT tracked in Inventory (`lib_*` owns book stock)
- Transport fuel/parts are NOT tracked in Inventory (`tpt_*` owns vehicle consumables)

---

## 12. Test Case Reference

### 12.1 Proposed Feature Tests 📐

| Test Class | Key Scenarios |
|---|---|
| `StockGroupTest` | Create group, create child group, deactivate with audit log, prevent delete of `is_system` group |
| `StockItemTest` | Create consumable, create asset, set reorder levels, toggle batch/expiry tracking, valuation method assignment |
| `UomConversionTest` | Create conversion rule, bidirectional calculation, effective date validation |
| `GodownTest` | Create godown, sub-godown hierarchy, assign in-charge employee |
| `PurchaseRequisitionTest` | Create PR, submit PR, approve PR, reject PR, CSV import valid, CSV import with validation errors |
| `QuotationTest` | Create RFQ from PR, record vendor quotes, comparison matrix rendering, convert to PO |
| `PurchaseOrderTest` | Create PO, convert PR to PO, approval threshold enforcement, PO status lifecycle, partial GRN, auto-close on full receipt |
| `GrnTest` | Create GRN, QC pass, QC partial reject, accept GRN triggers stock entry and voucher event, reject GRN, partial GRN flow |
| `StockIssueTest` | Create issue request, approve, direct issue without request, negative stock prevention, partial issue, acknowledgment |
| `StockAdjustmentTest` | Create adjustment, submit, approve, post creates correct entries for surplus and deficit variance |
| `AssetTest` | Asset created on GRN acceptance, asset tag auto-generated, transfer records movement, dispose fires event |
| `ReorderAlertTest` | Stock drops below threshold, alert job dispatched, auto-PR created when enabled |
| `RateContractTest` | Create contract, activate, item-wise rates applied on PO creation, expiry alert at 30 days |

### 12.2 Proposed Unit Tests 📐

| Test Class | Scenarios |
|---|---|
| `StockLedgerServiceTest` | Post inward entry, post outward entry, prevent negative stock (throws exception), balance update atomicity |
| `StockValuationServiceTest` | FIFO batch selection (oldest first), weighted average recalculation on inward, last purchase cost update |
| `GrnPostingServiceTest` | Voucher event fired on acceptance, `received_qty` updated on PO items, asset records created for asset items, vendor `last_purchase_rate` updated |
| `ReorderAlertServiceTest` | Alert fired when below threshold, not fired when above threshold, auto-PR only when flag enabled |
| `StockBalanceTest` | Concurrent writes — row lock prevents race condition, recalculate command restores correct balances |

### 12.3 Proposed Policy Tests 📐

| Test | Scenario |
|---|---|
| `InventoryPolicyTest` | Store manager can create GRN, HOD can only see own department issues, Accountant cannot create PO, Principal cannot approve GRN |

---

## 13. Glossary

| Term | Definition |
|---|---|
| **GRN** | Goods Receipt Note — document recording physical receipt of goods against a PO |
| **PO** | Purchase Order — formal procurement document sent to vendor with agreed quantities and prices |
| **PR** | Purchase Requisition — internal request for purchase, submitted by a department |
| **RFQ** | Request for Quotation — document sent to multiple vendors to obtain price quotes |
| **Godown** | Storage location / warehouse / storeroom within the school premises |
| **UOM** | Unit of Measure (e.g., Pcs, Kg, Box) |
| **FIFO** | First In, First Out — stock valuation and issue method; oldest stock issued first |
| **WAC** | Weighted Average Cost — stock valuation method recalculated on each inward entry |
| **WDV** | Written Down Value — depreciation method per Income Tax Act; asset value decreases by fixed % each year |
| **HSN** | Harmonized System Nomenclature — 6-8 digit code for goods classification under Indian GST |
| **SAC** | Services Accounting Code — equivalent of HSN for services under GST |
| **CGST / SGST** | Central GST + State GST applicable on intrastate (within same state) purchases |
| **IGST** | Integrated GST applicable on interstate purchases |
| **Rate Contract** | Annual agreement with a vendor fixing prices for specified items over a contract period |
| **Asset Tag** | Unique identifier assigned to each physical unit of an asset item for tracking |
| **AMC** | Annual Maintenance Contract — service agreement with vendor for asset upkeep |
| **Reorder Level** | Stock quantity threshold below which a reorder alert is triggered |
| **Reorder Quantity** | Quantity to procure when reorder level is hit |
| **Stock Journal** | Accounting voucher recording internal stock movement (issue/transfer/adjustment) with no cash flow |
| **inv_stock_balances** | Denormalized table maintaining running stock quantity and value per item per godown |
| **D21** | Project decision: Inventory fires `GrnAccepted`/`StockIssued` events; Accounting creates vouchers via `VoucherServiceInterface` |

---

## 14. Additional Suggestions

### 14.1 Denormalized Balance Table is Critical

The V1 design had no `inv_stock_balances` table, relying on expensive `SUM(quantity)` queries across `inv_stock_entries`. At 5,000+ items with 2 years of movement data, this becomes a performance bottleneck. The V2 `inv_stock_balances` table (Section 5.6) addresses this with atomic updates and row-level locking.

### 14.2 Stock Adjustment Tables Are Essential for Compliance

Government-aided schools are required to submit physical stock audit reports annually. The V1 design noted this as a gap. V2 adds `inv_stock_adjustments` and `inv_stock_adjustment_items` tables (Section 5.23–5.24) with a structured approval workflow.

### 14.3 Quotation Module Unlocks Real Procurement Value

The V1 document went directly from PR to PO. The V2 addition of `inv_quotations` and the comparison matrix (Section 4.6 / Section 5.13–5.14) enables schools to document competitive bidding — important for procurement governance and audit trails.

### 14.4 Full Asset Sub-Module in V2

V1 mentioned asset tracking briefly but had no dedicated tables. V2 introduces `inv_asset_categories`, `inv_assets`, `inv_asset_movements`, and `inv_asset_maintenance` (Sections 5.25–5.28), creating a complete fixed asset register with maintenance scheduling and disposal workflow.

### 14.5 Barcode/QR Label Library

Use `milon/barcode` (PHP) or `chillerlan/php-qrcode` for QR code generation. Labels rendered as DomPDF templates with A4 multi-up layouts. Recommend evaluating both packages for Indian GST label compliance requirements.

### 14.6 Implementation Sequence Recommendation

Build in this order to respect FK dependencies:

1. **Phase 1 — Masters** (no cross-module deps): `inv_stock_groups`, `inv_units_of_measure`, `inv_uom_conversions`, `inv_stock_items`, `inv_godowns`, `inv_asset_categories`, seeders
2. **Phase 2 — Vendor Linkage** (requires VND): `inv_item_vendor_jnt`, `inv_rate_contracts`, `inv_rate_contract_items_jnt`
3. **Phase 3 — Procurement** (requires SCH): `inv_purchase_requisitions` + items, `inv_quotations` + items, `inv_purchase_orders` + items
4. **Phase 4 — GRN & Stock Entry** (requires ACC VoucherServiceInterface): `inv_goods_receipt_notes`, `inv_grn_items`, `inv_stock_entries`, `inv_stock_balances`, `GrnPostingService`, asset record creation
5. **Phase 5 — Issue Workflow**: `inv_issue_requests` + items, `inv_stock_issues` + items, `StockIssueService`, `ReorderAlertService`
6. **Phase 6 — Assets**: `inv_assets`, `inv_asset_movements`, `inv_asset_maintenance`, `AssetController`
7. **Phase 7 — Adjustments & Reports**: `inv_stock_adjustments` + items, `InventoryReportService`, `InvReportController`, barcode labels

### 14.7 Artisan Commands to Build

| Command | Purpose |
|---|---|
| `inventory:recalculate-balances` | Rebuild `inv_stock_balances` from `inv_stock_entries` |
| `inventory:check-reorder-levels` | Run reorder check on all items (for scheduled job or manual trigger) |
| `inventory:expire-rate-contracts` | Auto-transition rate contracts past `valid_to` date to 'expired' status |
| `inventory:maintenance-overdue` | Check asset maintenance schedules and dispatch overdue notifications |

### 14.8 Scheduler Integration

Register these commands in `app/Console/Kernel.php` or `routes/console.php`:
- `inventory:expire-rate-contracts` — daily at midnight
- `inventory:check-reorder-levels` — daily morning run (or triggered per entry, not scheduled)
- `inventory:maintenance-overdue` — daily morning run

---

## 15. Appendices — Proposed File List

### 15.1 Module Directory Structure 📐

```
Modules/Inventory/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── InvDashboardController.php
│   │   │   ├── StockGroupController.php
│   │   │   ├── UomController.php
│   │   │   ├── StockItemController.php
│   │   │   ├── GodownController.php
│   │   │   ├── ItemVendorController.php
│   │   │   ├── RateContractController.php
│   │   │   ├── PurchaseRequisitionController.php
│   │   │   ├── QuotationController.php
│   │   │   ├── PurchaseOrderController.php
│   │   │   ├── GrnController.php
│   │   │   ├── IssueRequestController.php
│   │   │   ├── StockIssueController.php
│   │   │   ├── StockEntryController.php
│   │   │   ├── StockAdjustmentController.php
│   │   │   ├── AssetController.php
│   │   │   ├── AssetCategoryController.php
│   │   │   └── InvReportController.php
│   │   ├── Requests/
│   │   │   ├── StoreStockGroupRequest.php
│   │   │   ├── StoreUomRequest.php
│   │   │   ├── StoreUomConversionRequest.php
│   │   │   ├── StoreStockItemRequest.php
│   │   │   ├── StoreGodownRequest.php
│   │   │   ├── StorePurchaseRequisitionRequest.php
│   │   │   ├── StoreQuotationRequest.php
│   │   │   ├── StorePurchaseOrderRequest.php
│   │   │   ├── StoreGrnRequest.php
│   │   │   ├── StoreIssueRequestRequest.php
│   │   │   ├── StoreStockIssueRequest.php
│   │   │   ├── StoreRateContractRequest.php
│   │   │   └── StoreStockAdjustmentRequest.php
│   │   └── Policies/
│   │       ├── StockGroupPolicy.php
│   │       ├── StockItemPolicy.php
│   │       ├── UomPolicy.php
│   │       ├── GodownPolicy.php
│   │       ├── PurchaseRequisitionPolicy.php
│   │       ├── QuotationPolicy.php
│   │       ├── PurchaseOrderPolicy.php
│   │       ├── GrnPolicy.php
│   │       ├── IssueRequestPolicy.php
│   │       ├── StockIssuePolicy.php
│   │       ├── RateContractPolicy.php
│   │       ├── StockAdjustmentPolicy.php
│   │       └── AssetPolicy.php
│   ├── Models/
│   │   ├── StockGroup.php
│   │   ├── UnitOfMeasure.php
│   │   ├── UomConversion.php
│   │   ├── StockItem.php
│   │   ├── Godown.php
│   │   ├── StockBalance.php
│   │   ├── StockEntry.php
│   │   ├── ItemVendor.php
│   │   ├── RateContract.php
│   │   ├── RateContractItem.php
│   │   ├── PurchaseRequisition.php
│   │   ├── PurchaseRequisitionItem.php
│   │   ├── Quotation.php
│   │   ├── QuotationItem.php
│   │   ├── PurchaseOrder.php
│   │   ├── PurchaseOrderItem.php
│   │   ├── GoodsReceiptNote.php
│   │   ├── GrnItem.php
│   │   ├── IssueRequest.php
│   │   ├── IssueRequestItem.php
│   │   ├── StockIssue.php
│   │   ├── StockIssueItem.php
│   │   ├── StockAdjustment.php
│   │   ├── StockAdjustmentItem.php
│   │   ├── AssetCategory.php
│   │   ├── Asset.php
│   │   ├── AssetMovement.php
│   │   └── AssetMaintenance.php
│   ├── Services/
│   │   ├── StockLedgerService.php
│   │   ├── StockValuationService.php
│   │   ├── GrnPostingService.php
│   │   ├── PurchaseOrderService.php
│   │   ├── ReorderAlertService.php
│   │   └── InventoryReportService.php
│   ├── Events/
│   │   ├── GrnAccepted.php
│   │   ├── StockIssued.php
│   │   ├── StockTransferred.php
│   │   ├── StockAdjusted.php
│   │   ├── AssetDisposed.php
│   │   ├── ReorderThresholdReached.php
│   │   ├── RateContractExpiringSoon.php
│   │   └── MaintenanceOverdue.php
│   └── Console/Commands/
│       ├── RecalculateBalancesCommand.php
│       ├── CheckReorderLevelsCommand.php
│       ├── ExpireRateContractsCommand.php
│       └── MaintenanceOverdueCommand.php
├── database/
│   ├── migrations/
│   │   ├── create_inv_stock_groups_table.php
│   │   ├── create_inv_units_of_measure_table.php
│   │   ├── create_inv_uom_conversions_table.php
│   │   ├── create_inv_stock_items_table.php
│   │   ├── create_inv_godowns_table.php
│   │   ├── create_inv_stock_balances_table.php
│   │   ├── create_inv_stock_entries_table.php
│   │   ├── create_inv_item_vendor_jnt_table.php
│   │   ├── create_inv_rate_contracts_table.php
│   │   ├── create_inv_rate_contract_items_jnt_table.php
│   │   ├── create_inv_purchase_requisitions_table.php
│   │   ├── create_inv_purchase_requisition_items_table.php
│   │   ├── create_inv_quotations_table.php
│   │   ├── create_inv_quotation_items_table.php
│   │   ├── create_inv_purchase_orders_table.php
│   │   ├── create_inv_purchase_order_items_table.php
│   │   ├── create_inv_goods_receipt_notes_table.php
│   │   ├── create_inv_grn_items_table.php
│   │   ├── create_inv_issue_requests_table.php
│   │   ├── create_inv_issue_request_items_table.php
│   │   ├── create_inv_stock_issues_table.php
│   │   ├── create_inv_stock_issue_items_table.php
│   │   ├── create_inv_stock_adjustments_table.php
│   │   ├── create_inv_stock_adjustment_items_table.php
│   │   ├── create_inv_asset_categories_table.php
│   │   ├── create_inv_assets_table.php
│   │   ├── create_inv_asset_movements_table.php
│   │   └── create_inv_asset_maintenance_table.php
│   └── seeders/
│       ├── InvStockGroupSeeder.php   (10 default groups)
│       ├── InvUomSeeder.php           (10 standard UOMs)
│       └── InvGodownSeeder.php        (5 default godowns)
└── resources/views/inventory/
    └── [~65 blade templates per Section 7]
```

### 15.2 RBAC Permission Strings 📐

```
inventory.stock-group.viewAny      inventory.stock-group.create
inventory.stock-group.update       inventory.stock-group.delete
inventory.stock-item.viewAny       inventory.stock-item.create
inventory.stock-item.update        inventory.stock-item.delete
inventory.uom.viewAny              inventory.uom.create
inventory.uom.update               inventory.godown.viewAny
inventory.godown.create            inventory.godown.update
inventory.rate-contract.viewAny    inventory.rate-contract.create
inventory.rate-contract.update     inventory.purchase-requisition.viewAny
inventory.purchase-requisition.create  inventory.purchase-requisition.approve
inventory.quotation.viewAny        inventory.quotation.create
inventory.purchase-order.viewAny   inventory.purchase-order.create
inventory.purchase-order.approve   inventory.grn.viewAny
inventory.grn.create               inventory.grn.accept
inventory.grn.reject               inventory.issue-request.viewAny
inventory.issue-request.create     inventory.issue-request.approve
inventory.stock-issue.viewAny      inventory.stock-issue.create
inventory.stock-issue.direct       inventory.stock-entry.viewAny
inventory.stock-adjustment.viewAny inventory.stock-adjustment.create
inventory.stock-adjustment.approve inventory.asset.viewAny
inventory.asset.update             inventory.asset.transfer
inventory.asset.dispose            inventory.report.view
```

---

## 16. V1 → V2 Delta Summary

| Category | V1 (2026-03-25) | V2 Changes | Impact |
|---|---|---|---|
| **Tables** | 19 tables | +9 new tables = **28 tables** total | Schema expansion |
| `inv_stock_balances` | Not in V1 — computed by SUM | Added: denormalized balance with row-lock | Performance critical |
| `inv_stock_adjustments` + items | Identified as gap in V1 §14.2 | Added: 2 tables + full workflow | Compliance required |
| `inv_quotations` + items | Not in V1 | Added: 2 tables + comparison screen | L6 RFQ coverage |
| `inv_asset_categories` | Not in V1 | Added | L5 asset classification |
| `inv_assets` | Mentioned briefly in V1 FR | Added dedicated table + auto-creation on GRN | L5 full asset register |
| `inv_asset_movements` | Not in V1 | Added: movement history per asset | L5 tracking |
| `inv_asset_maintenance` | Not in V1 | Added: maintenance log + scheduling | L5 maintenance |
| **PO schema** | `pr_id` FK only | Added `quotation_id` FK + `approval_threshold_amount` | L6 quotation flow |
| **Functional Requirements** | 15 FRs (FR-INV-001 to FR-INV-015) | 15 FRs retained; FR-INV-005a, FR-INV-006, FR-INV-011, FR-INV-012, FR-INV-013 expanded significantly | Greenfield additions |
| **Sub-module L5 (Assets)** | 1 paragraph in V1 §4.10 | Full sub-module: 2 FRs, 4 tables, AssetController, 5 routes, 5 screens | New coverage |
| **Sub-module L6 (Quotations)** | Not present in V1 | FR-INV-013 + Quotation tables, controller, routes, screen | New coverage |
| **Business Rules** | 15 rules | +3 rules (BR-INV-016 PO approval threshold, BR-INV-017 adjustment approval, BR-INV-018 WDV depreciation) = **18 rules** | BR-L-002 and BR-L-004 compliance |
| **Controllers** | 14 | +4 (AssetController, AssetCategoryController, QuotationController, StockAdjustmentController) = **18 controllers** | New sub-modules |
| **Services** | 6 | +1 (AssetService implied by maintenance/disposal logic) = **7 services** | |
| **Artisan Commands** | None specified | 4 commands added | Operational tooling |
| **Events** | 2 (GrnAccepted, StockIssued) | +6 events = **8 events** | Full event coverage |
| **State Machine documentation** | Not in V1 | 5 FSMs added (Procurement, Issue, Asset, Adjustment, Reorder) | Developer clarity |
| **Sections** | 15 sections | 16 sections (standard V2 template) | Template compliance |
| **Out of Scope unchanged** | Library, Transport, Mess, Vendor master, external procurement | No change | |

### 16.1 Key Design Decisions Made in V2

1. **Denormalized balances** — `inv_stock_balances` replaces SUM queries for all balance lookups
2. **Separate stock adjustment tables** — addresses V1-identified gap; required for government audit compliance
3. **Full asset sub-module** — `inv_assets`, `inv_asset_movements`, `inv_asset_maintenance` add complete L5 coverage
4. **Quotation comparison workflow** — `inv_quotations` adds the RFQ step missing from V1's PR → PO shortcut
5. **Event-driven accounting integration** — 8 domain events documented with full payload contracts
6. **`sch_department` singular** — confirmed from V1 DDL note; all FKs use singular form throughout

---

*Document Version 2.0 | Generated 2026-03-26 | RBS_ONLY Mode | All features ❌ Not Started | Generation Batch 8/10*


