# INV — Inventory Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **INV (Inventory)** module using `INV_Inventory_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `INV_FeatureSpec.md` — Feature Specification
2. `INV_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `INV_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** Inventory — Complete stock and procurement management for Indian K-12 schools.
Tables: `inv_*` (28 tables across masters, vendor linkage, procurement, stock movements, assets).

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = INV
MODULE            = Inventory
MODULE_DIR        = Modules/Inventory/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = L                              # Inventory & Assets in RBS v4.0
DB_TABLE_PREFIX   = inv_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/22-Inventory/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/INV_Inventory_Requirement.md

FEATURE_FILE      = INV_FeatureSpec.md
DDL_FILE_NAME     = INV_DDL_v1.sql
DEV_PLAN_FILE     = INV_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — INV (INVENTORY) MODULE

### What This Module Does

The Inventory module provides a **complete stock and procurement management system** for Indian K-12 schools on the Prime-AI SaaS platform. It covers the full lifecycle from item master setup and vendor-linked rate contracts through a structured procurement workflow (Indent → Quotation → PO → GRN → Stock Entry), departmental stock issue and consumption tracking, fixed asset register with maintenance scheduling, and automated reorder alerts — all integrated with the Accounting module via event-driven voucher posting.

**L1 — Item & Category Master:**
- Stock group hierarchy (self-referencing tree, 10 seeded groups)
- Stock item catalog with SKU, batch/expiry tracking, valuation method, reorder levels
- Unit of Measure master with conversion rules (Box → Pcs, Kg → g, etc.)
- Godown (storage location) management with sub-godown hierarchy

**L2 — Stock Management:**
- `inv_stock_entries`: immutable central journal of all stock movements (inward/outward/transfer/adjustment)
- `inv_stock_balances`: denormalized running balance (V2 addition) — row-level locked, rebuilt via Artisan command
- Stock adjustments with approval workflow and physical count audit

**L3 — Purchase Orders:**
- Purchase Requisition (PR): Draft → Submitted → Approved → Converted; CSV bulk import
- Purchase Order (PO): from PR or direct; approval threshold enforcement; partial GRN tracking
- Goods Receipt Note (GRN): QC workflow; `GrnAccepted` event fires stock entry + accounting voucher

**L4 — Vendor Linkage:**
- Item-vendor assignment with preferred vendor, vendor SKU, last purchase tracking
- Rate contracts with validity, per-item agreed rates, auto-apply on PO, expiry alerts

**L5 — Asset Tracking:**
- Asset register: auto-created per unit on GRN acceptance for `item_type='asset'` items
- Asset movements, condition tracking, disposal workflow
- Maintenance scheduling with AMC support and overdue alerts

**L6 — Procurement Workflow & Quotations:**
- Request for Quotation (RFQ) to multiple vendors; side-by-side comparison matrix
- Convert selected quotation lines to PO with pre-filled rates

**Stock Issue & Reorder:**
- Issue Request → Approval → Stock Issue → Acknowledgment + Stock Journal Voucher
- Direct issue for authorised store keepers
- Reorder threshold monitoring with optional auto-PR generation

### Architecture Decisions
- **Single Laravel module** (`Modules\Inventory`) — all 6 sub-modules in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `inventory/` | Route name prefix: `inventory.`
- Accounting integration: event-driven via `GrnAccepted` / `StockIssued` / `StockTransferred` / `StockAdjusted` / `AssetDisposed` events — Accounting module owns the listener and writes to `acc_*` tables; Inventory never writes to `acc_*` directly
- Vendor data: references `vnd_vendors` (Vendor module); no vendor master duplication
- Library books tracked in `lib_*`; transport fuel/parts tracked in `tpt_*` — NOT in Inventory

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 18 (from file list in req spec Section 15) |
| Models | 28 |
| Services | 7 |
| FormRequests | 13 |
| Policies | 13 |
| inv_* tables | 28 (req Section 1 says 21 — actual count from Section 5 data model is 28; use 28) |
| Blade views (estimated) | ~65 |
| Seeders | 4 + 1 runner |

### Complete Table Inventory

**Masters (6 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `inv_stock_groups` | Category master | Self-ref hierarchy; UNIQUE `(code)` |
| 2 | `inv_units_of_measure` | UOM master | `is_system` flag |
| 3 | `inv_uom_conversions` | UOM conversion rules | UNIQUE `(from_uom_id, to_uom_id)` |
| 4 | `inv_stock_items` | Item catalog | UNIQUE `(sku)`; FK → acc_* + inv_* |
| 5 | `inv_godowns` | Storage locations | Self-ref; FK → sch_employees |
| 6 | `inv_asset_categories` | Asset category master | UNIQUE `(code)` |

**Stock Ledger (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 7 | `inv_stock_balances` | Denormalized running balance | UNIQUE `(stock_item_id, godown_id)` |
| 8 | `inv_stock_entries` | Immutable movement journal | Index `(stock_item_id, godown_id, created_at)` |

**Vendor Linkage (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 9 | `inv_item_vendor_jnt` | Item-vendor mapping | UNIQUE `(item_id, vendor_id)` |
| 10 | `inv_rate_contracts` | Vendor rate contracts | UNIQUE `(contract_number)` |
| 11 | `inv_rate_contract_items_jnt` | Contract line items | UNIQUE `(rate_contract_id, item_id)` |

**Procurement (8 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 12 | `inv_purchase_requisitions` | PR header | UNIQUE `(pr_number)` |
| 13 | `inv_purchase_requisition_items` | PR line items | CASCADE DELETE from PR |
| 14 | `inv_quotations` | RFQ/quotation header | UNIQUE `(rfq_number)` |
| 15 | `inv_quotation_items` | Quotation line items | CASCADE DELETE from quotation |
| 16 | `inv_purchase_orders` | PO header | UNIQUE `(po_number)` |
| 17 | `inv_purchase_order_items` | PO line items | CASCADE DELETE from PO |
| 18 | `inv_goods_receipt_notes` | GRN header | UNIQUE `(grn_number)` |
| 19 | `inv_grn_items` | GRN line items | CASCADE DELETE from GRN |

**Stock Issue (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 20 | `inv_issue_requests` | Issue request header | UNIQUE `(request_number)` |
| 21 | `inv_issue_request_items` | Issue request line items | CASCADE DELETE |
| 22 | `inv_stock_issues` | Stock issue execution | UNIQUE `(issue_number)` |
| 23 | `inv_stock_issue_items` | Issue execution line items | CASCADE DELETE |

**Stock Adjustment (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 24 | `inv_stock_adjustments` | Physical count audit header | UNIQUE `(adjustment_number)` |
| 25 | `inv_stock_adjustment_items` | Audit line items with variance | `variance_qty` GENERATED ALWAYS AS `(physical_qty - system_qty)` STORED |

**Asset Tracking (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 26 | `inv_assets` | Fixed asset register | UNIQUE `(asset_tag)` |
| 27 | `inv_asset_movements` | Asset transfer history | — |
| 28 | `inv_asset_maintenance` | Maintenance log | — |

**Existing Tables REUSED (Inventory reads from; never modifies schema):**
| Table | Source | Inventory Usage |
|---|---|---|
| `vnd_vendors` | Vendor (VND) | PO vendor, Rate contracts, GRN vendor, Quotations |
| `sch_employees` | SchoolSetup (SCH) | Godown in-charge, Asset assigned employee |
| `sch_department` | SchoolSetup (SCH) | PR department, Issue request department |
| `acc_vouchers` | Accounting (ACC) | Mandatory FK on stock entries; set on GRN/Issue |
| `acc_ledgers` | Accounting (ACC) | Item purchase/sales ledger; party ledger on entries |
| `acc_tax_rates` | Accounting (ACC) | GST rate on items and PO lines |
| `acc_fixed_assets` | Accounting (ACC) | Asset depreciation linkage |
| `sys_users` | System | All `created_by`, `approved_by`, `requested_by`, etc. |
| `sys_activity_logs` | System | Audit trail (write-only) |
| `ntf_notifications` | Notification | Reorder alerts, rate contract expiry, maintenance overdue |

### Cross-Module Integration (Accounting Vouchers on Stock Events)
```
On GrnAccepted:
  Dr  Stock-in-Hand A/c (item purchase_ledger_id)   ₹Total
  Cr  Vendor Creditor A/c (party_ledger_id)          ₹Total
  → inv_stock_entries (inward) created + inv_stock_balances updated

On StockIssued:
  Dr  Dept Consumption A/c (expense_ledger_id)       ₹Total
  Cr  Stock-in-Hand A/c (stock_ledger_id)            ₹Total
  → inv_stock_entries (outward) created + inv_stock_balances deducted

On StockTransferred (godown-to-godown):
  Dr  Destination Stock A/c                          ₹Total
  Cr  Source Stock A/c                               ₹Total
  → inv_stock_entries (transfer_in + transfer_out pair) created

On StockAdjusted (surplus):
  Dr  Stock-in-Hand A/c                              ₹Variance value
  Cr  Stock Surplus A/c                              ₹Variance value

Note: Inventory fires the event. Accounting module owns the listener and writes to acc_*.
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — INV v2 requirement (15 FRs, Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: vnd_vendors, sch_employees, sch_department, sys_users, acc_vouchers, acc_ledgers, acc_tax_rates, acc_fixed_assets (use exact column names in spec)

### Phase 1 Task — Generate `INV_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope sub-modules (L1–L6 + Stock Issue + Reorder — verbatim from req v2 Section 2.3)
- Out-of-scope items (library books `lib_*`, transport consumables `tpt_*`, depreciation computation delegated to Accounting)
- Module scale table (controller / model / service / FormRequest / policy / table counts)

#### Section 2 — Entity Inventory (All 28 Tables)
For each `inv_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Masters** (inv_stock_groups, inv_units_of_measure, inv_uom_conversions, inv_stock_items, inv_godowns, inv_asset_categories)
- **Stock Ledger** (inv_stock_balances, inv_stock_entries)
- **Vendor Linkage** (inv_item_vendor_jnt, inv_rate_contracts, inv_rate_contract_items_jnt)
- **Procurement** (inv_purchase_requisitions, inv_purchase_requisition_items, inv_quotations, inv_quotation_items, inv_purchase_orders, inv_purchase_order_items, inv_goods_receipt_notes, inv_grn_items)
- **Stock Issue** (inv_issue_requests, inv_issue_request_items, inv_stock_issues, inv_stock_issue_items)
- **Stock Adjustment** (inv_stock_adjustments, inv_stock_adjustment_items)
- **Asset Tracking** (inv_assets, inv_asset_movements, inv_asset_maintenance)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 28 tables grouped by layer (inv_* vs cross-module reads from acc_*/vnd_*/sch_*/sys_*).
Use `→` for FK direction (child → parent).

Critical cross-module FKs to highlight:
- `inv_stock_entries.voucher_id → acc_vouchers.id` (mandatory — no orphan movements)
- `inv_stock_items.tax_rate_id → acc_tax_rates.id` + `purchase_ledger_id → acc_ledgers.id`
- `inv_assets.acc_fixed_asset_id → acc_fixed_assets.id` (nullable — synced from Accounting)
- `inv_purchase_requisitions.department_id → sch_department.id` (note: `sch_department` singular)
- `inv_item_vendor_jnt.vendor_id → vnd_vendors.id`

#### Section 4 — Business Rules (18 rules)
For each rule, state:
- Rule ID (BR-INV-001 to BR-INV-018)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event`

Critical rules to emphasise:
- BR-INV-001: Every `inv_stock_entries` row MUST have `voucher_id` — no orphan movements
- BR-INV-003: Negative stock is not permitted — service layer guard before any outward entry
- BR-INV-006: GRN `accepted_qty + rejected_qty = received_qty` — form validation + service check
- BR-INV-007: GRN `received_qty` cannot exceed `(PO ordered_qty − already received across all GRNs)`
- BR-INV-008: Batch-tracked items use FIFO batch selection on outward — oldest batch first
- BR-INV-014: `inv_stock_entries` immutable once posted — no UPDATE/DELETE; corrections via new adjustment entries only
- BR-INV-015: No `tenant_id` column — isolation at DB level via stancl/tenancy

#### Section 5 — Workflow State Machines (4 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, balance updates)

FSMs to document:
1. **Procurement Workflow** — PR FSM: `draft→submitted→approved/rejected→converted/cancelled`
   + optional RFQ/Quotation step + PO FSM: `draft→sent→partial→received→closed/cancelled`
   + GRN FSM: `draft→inspected→accepted/partial/rejected`
   On GRN accepted: `GrnAccepted` event, stock entry + balance update, vendor rate update, asset record creation for asset items, reorder check
2. **Stock Issue Workflow** — `submitted→approved/rejected→issued/partial` (Issue Request)
   On stock issue: `StockIssued` event, outward stock entry, balance deduction, reorder check, pending acknowledgment
3. **Asset Lifecycle** — Created on GRN acceptance; `good/fair/poor/under_repair` condition tracking; transfer → `inv_asset_movements`; dispose → `AssetDisposed` event
4. **Stock Adjustment** — `draft→submitted→approved/rejected→posted`
   On posted: variance entry (surplus=inward, deficit=outward) created in `inv_stock_entries`, balance updated

#### Section 6 — Functional Requirements Summary (15 FRs)
For each FR-INV-001 to FR-INV-015:
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by sub-module (L1, L2, L3, L4, L5, L6, Issue+Reorder per req v2 Sections 4.1–4.7).

#### Section 7 — Permission Matrix
| Permission String | Admin | Store Mgr | Principal | Accountant | HOD |
|---|---|---|---|---|---|

Derive permissions from req v2 Section 3 (Actor-Use Case Matrix). Include:
- `inventory.stock-group.*` (CRUD for masters)
- `inventory.stock-item.*`
- `inventory.godown.*`
- `inventory.purchase-requisition.*`
- `inventory.purchase-order.*`
- `inventory.grn.*`
- `inventory.stock-issue.direct` (bypass issue request)
- `inventory.stock-adjustment.*`
- `inventory.asset.*`
- `inventory.rate-contract.*`
- `inventory.reports.view`
Which Policy class enforces each permission (13 policies from req v2 Section 15)

#### Section 8 — Service Architecture (7 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\Inventory\app\Services
Depends on:  [other services it calls]
Fires:       [events it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **StockLedgerService** — post inward/outward/transfer/adjustment entries; enforce immutability; row-lock balance update; negative stock guard; `inventory:recalculate-balances` command support
2. **StockValuationService** — FIFO batch selection (oldest batch first); Weighted Average Cost recalculation on inward; Last Purchase Cost update from GRN; issue cost determination per item's valuation method
3. **GrnPostingService** — accept GRN: stock entry + balance + voucher event + vendor rate update + asset record creation; partial acceptance logic; PO `received_qty` auto-update
4. **PurchaseOrderService** — PR→PO conversion with rate-contract pre-fill; PO approval threshold check; PO status auto-transition (partial/received/closed); PR→RFQ→PO flow; direct PO creation
5. **StockIssueService** — execute issue request (deduct balance, create outward entry, fire `StockIssued`); direct issue bypass; partial issue; reorder check post-deduction
6. **ReorderAlertService** — compare `inv_stock_balances.current_qty` against `inv_stock_items.reorder_level` after every outward entry; dispatch `ReorderThresholdReached` event; auto-PR creation when `auto_reorder_pr=true`; `inventory:check-reorder-levels` Artisan support
7. **InventoryReportService** — stock balance, stock valuation, stock ledger, consumption, purchase register, pending PO, GRN register, reorder alerts, fast/slow movers, expiry alerts, godown-wise stock, asset register reports; CSV/PDF export; fputcsv for CSV; DomPDF for PDF; chunking for large exports

#### Section 9 — Integration Contracts (8 events)
For each event:
| Event | Fired By (service + when) | Listener Module | Payload | Action |
|---|---|---|---|---|
- `GrnAccepted` → Accounting → Creates Purchase Voucher (Dr Stock-in-Hand, Cr Vendor Creditor)
- `StockIssued` → Accounting → Creates Stock Journal (Dr Dept Consumption, Cr Stock-in-Hand)
- `StockTransferred` → Accounting → Creates Stock Journal (Dr Destination, Cr Source)
- `StockAdjusted` → Accounting → Creates Journal Entry (Dr/Cr Stock-in-Hand)
- `AssetDisposed` → Accounting → Write-off residual value in acc_fixed_assets
- `ReorderThresholdReached` → Notification (NTF) → Alert to store manager
- `RateContractExpiringSoon` → Notification (NTF) → Alert 30 days before `valid_to`
- `MaintenanceOverdue` → Notification (NTF) → Alert when maintenance scheduled date passes

Document payload structure for `GrnAccepted` and `StockIssued` as shown in req v2 Section 11.3.

#### Section 10 — Non-Functional Requirements
From req v2 Sections 10.1–10.6.
For each NFR, add an "Implementation Note" column explaining HOW it will be met in code:
- Stock balance query (single item, all godowns): < 500ms — `inv_stock_balances` indexed on `(stock_item_id, godown_id)` + eager load
- Report generation (12 months): < 10 seconds — `chunk(500)` + indexed `created_at`
- GRN acceptance transaction: DB transaction wraps stock entry + balance + event dispatch
- `inv_stock_balances` concurrency: `lockForUpdate()` row-level lock prevents race conditions
- `inv_stock_entries` immutability: application-level guard in StockLedgerService + no UPDATE route exposed
- Reorder alert: async queued job (`ReorderAlertJob`, 3 retries, 60s delay) — does not block response
- Barcode/QR labels: batched, max 200 per request; `milon/barcode` or `chillerlan/php-qrcode`

#### Section 11 — Test Plan Outline
From req v2 Sections 12.1–12.3:

**Feature Tests (Pest) — 13 test files:**
| File | Key Scenarios |
|---|---|
(List all 13 files from req v2 Section 12.1 with count and scenarios)

**Unit Tests (PHPUnit) — 5 test files:**
| File | Key Scenarios |
|---|---|
(List all 5 files from req v2 Section 12.2)

**Policy Tests:**
- `InventoryPolicyTest` — Store manager can create GRN, HOD own-dept only, Accountant cannot create PO

**Test Data:**
- Required seeders for test database
- Required factories: StockItemFactory, PurchaseRequisitionFactory, PurchaseOrderFactory, GrnFactory, StockIssueFactory
- Mock strategy: `Event::fake()` for integration tests (GrnAccepted, StockIssued); `Queue::fake()` for ReorderAlertJob; `Bus::fake()` for dispatch tests; `acc_vouchers` — use factory or mock VoucherServiceInterface

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `INV_FeatureSpec.md` | `{OUTPUT_DIR}/INV_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 28 inv_* tables appear in Section 2 entity inventory (note: req Section 1.1 says 21, actual Section 5 count is 28 — use 28)
- [ ] All 15 FRs (INV-001 to INV-015) appear in Section 6
- [ ] All 18 business rules (BR-INV-001 to BR-INV-018) in Section 4 with enforcement point
- [ ] All 4 FSMs documented with ASCII state diagram and side effects
- [ ] All 7 services listed with key method signatures in Section 8
- [ ] All 8 integration events documented with payload in Section 9
- [ ] `inv_stock_entries.voucher_id → acc_vouchers.id` noted as mandatory (no orphan entries)
- [ ] `inv_assets.acc_fixed_asset_id → acc_fixed_assets.id` noted as nullable, synced from Accounting
- [ ] `sch_department` (singular) verified as correct table name for department FK
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] `inv_stock_balances` concurrency note: `lockForUpdate()` in StockLedgerService
- [ ] `inv_stock_adjustment_items.variance_qty` noted as GENERATED ALWAYS AS computed column
- [ ] BR-INV-008 (FIFO batch selection) explicitly documented in StockValuationService
- [ ] BR-INV-014 (immutable stock entries) enforcement point: service_layer
- [ ] Permission matrix covers Admin / Store Mgr / Principal / Accountant / HOD roles
- [ ] All cross-module column names verified against tenant_db_v2.sql (use EXACT names from DDL)

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/INV_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/INV_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 28 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`INV_DDL_v1.sql`)

Generate CREATE TABLE statements for all 28 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `inv_` for all tables — no exceptions
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (e.g. `inv_item_vendor_jnt`, `inv_rate_contract_items_jnt`)
5. JSON columns: suffix `_json` (e.g. `layout_json` if needed)
6. Boolean flag columns: prefix `is_` or `has_`
7. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_inv_{tableshort}_{column}` (e.g. `fk_inv_sitm_stock_group_id`)
12. **Do NOT recreate vnd_*, sch_*, acc_*, sys_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `inv_stock_adjustment_items.variance_qty`: use `DECIMAL(15,3) GENERATED ALWAYS AS (physical_qty - system_qty) STORED COMMENT 'Positive = surplus, negative = deficit'`

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No inv_* dependencies (may reference sys_*/sch_*/acc_* only):
  `inv_units_of_measure` (no deps),
  `inv_asset_categories` (no deps)

Layer 2 — Depends on Layer 1 only:
  `inv_stock_groups` (self-ref + → inv_units_of_measure),
  `inv_uom_conversions` (→ inv_units_of_measure)

Layer 3 — Depends on Layer 2 + cross-module:
  `inv_stock_items` (→ inv_stock_groups + inv_units_of_measure + acc_tax_rates + acc_ledgers),
  `inv_godowns` (self-ref + → sch_employees)

Layer 4 — Depends on Layer 3:
  `inv_stock_balances` (→ inv_stock_items + inv_godowns) [UNIQUE: stock_item_id, godown_id],
  `inv_item_vendor_jnt` (→ inv_stock_items + vnd_vendors),
  `inv_rate_contracts` (→ vnd_vendors),
  `inv_purchase_requisitions` (→ sys_users + sch_department),
  `inv_stock_adjustments` (→ inv_godowns + sys_users)

Layer 5 — Depends on Layer 4:
  `inv_rate_contract_items_jnt` (→ inv_rate_contracts CASCADE DELETE + inv_stock_items),
  `inv_purchase_requisition_items` (→ inv_purchase_requisitions CASCADE DELETE + inv_stock_items + inv_units_of_measure),
  `inv_quotations` (→ inv_purchase_requisitions nullable + vnd_vendors),
  `inv_issue_requests` (→ sys_users + sch_department),
  `inv_stock_adjustments` (already in Layer 4 — move here if dependency conflicts)

Layer 6 — Depends on Layer 5:
  `inv_quotation_items` (→ inv_quotations CASCADE DELETE + inv_stock_items),
  `inv_purchase_orders` (→ vnd_vendors + inv_purchase_requisitions nullable + inv_quotations nullable + sys_users),
  `inv_issue_request_items` (→ inv_issue_requests CASCADE DELETE + inv_stock_items + inv_units_of_measure),
  `inv_stock_adjustment_items` (→ inv_stock_adjustments CASCADE DELETE + inv_stock_items)

Layer 7 — Depends on Layer 6:
  `inv_purchase_order_items` (→ inv_purchase_orders CASCADE DELETE + inv_stock_items + acc_tax_rates),
  `inv_goods_receipt_notes` (→ inv_purchase_orders + vnd_vendors + inv_godowns + sys_users + acc_vouchers nullable)

Layer 8 — Depends on Layer 7:
  `inv_grn_items` (→ inv_goods_receipt_notes CASCADE DELETE + inv_purchase_order_items + inv_stock_items),
  `inv_stock_issues` (→ inv_issue_requests nullable + inv_godowns + sys_users + sch_employees nullable + sch_department + acc_vouchers nullable),
  `inv_stock_entries` (→ inv_stock_items + inv_godowns + acc_vouchers + acc_ledgers nullable + inv_godowns nullable for destination)

Layer 9 — Depends on Layer 8:
  `inv_stock_issue_items` (→ inv_stock_issues CASCADE DELETE + inv_stock_items),
  `inv_assets` (→ inv_asset_categories + inv_stock_items + inv_grn_items nullable + inv_godowns nullable + sch_employees nullable + acc_fixed_assets nullable)

Layer 10 — Depends on Layer 9:
  `inv_asset_movements` (→ inv_assets + inv_godowns nullable × 2 + sch_employees nullable × 2 + sys_users),
  `inv_asset_maintenance` (→ inv_assets + vnd_vendors nullable)

**Critical unique constraints to include:**
```sql
-- inv_units_of_measure: no unique needed beyond PK (symbol is not unique per req)

-- inv_stock_groups
UNIQUE KEY uq_inv_sg_code (code)      -- allows NULL duplicates

-- inv_uom_conversions
UNIQUE KEY uq_inv_uom_conv (from_uom_id, to_uom_id)

-- inv_stock_items
UNIQUE KEY uq_inv_si_sku (sku)        -- nullable, allows multiple NULLs

-- inv_godowns
UNIQUE KEY uq_inv_gdn_code (code)     -- nullable

-- inv_asset_categories
UNIQUE KEY uq_inv_ac_code (code)      -- nullable

-- inv_stock_balances
UNIQUE KEY uq_inv_sb_item_godown (stock_item_id, godown_id)

-- inv_item_vendor_jnt
UNIQUE KEY uq_inv_ivj_item_vendor (item_id, vendor_id)

-- inv_rate_contracts
UNIQUE KEY uq_inv_rc_contract_number (contract_number)  -- nullable

-- inv_rate_contract_items_jnt
UNIQUE KEY uq_inv_rcij_contract_item (rate_contract_id, item_id)

-- inv_purchase_requisitions
UNIQUE KEY uq_inv_pr_number (pr_number)

-- inv_quotations
UNIQUE KEY uq_inv_quot_rfq_number (rfq_number)

-- inv_purchase_orders
UNIQUE KEY uq_inv_po_number (po_number)

-- inv_goods_receipt_notes
UNIQUE KEY uq_inv_grn_number (grn_number)

-- inv_issue_requests
UNIQUE KEY uq_inv_ir_number (request_number)

-- inv_stock_issues
UNIQUE KEY uq_inv_si_issue_number (issue_number)

-- inv_stock_adjustments
UNIQUE KEY uq_inv_sadj_number (adjustment_number)

-- inv_assets
UNIQUE KEY uq_inv_asset_tag (asset_tag)
```

**ENUM values (exact, to match application code):**
```
inv_stock_items.item_type:                 'consumable','asset'
inv_stock_items.valuation_method:          'fifo','weighted_average','last_purchase'
inv_stock_entries.entry_type:             'inward','outward','transfer_in','transfer_out','adjustment'
inv_rate_contracts.status:                'draft','active','expired','cancelled'
inv_purchase_requisitions.priority:       'low','normal','high','urgent'
inv_purchase_requisitions.status:         'draft','submitted','approved','rejected','converted','cancelled'
inv_quotations.status:                    'draft','sent','received','expired','converted'
inv_purchase_orders.status:               'draft','sent','partial','received','cancelled','closed'
inv_goods_receipt_notes.status:           'draft','inspected','accepted','partial','rejected'
inv_goods_receipt_notes.qc_status:        'pending','passed','failed','partial'
inv_issue_requests.status:                'submitted','approved','issued','partial','rejected'
inv_stock_adjustments.status:             'draft','submitted','approved','rejected','posted'
inv_assets.condition:                     'good','fair','poor','under_repair','disposed'
inv_asset_maintenance.maintenance_type:   'preventive','corrective','amc','calibration'
inv_asset_maintenance.status:             'scheduled','completed','overdue'
```

**Critical columns to get right:**
- `inv_stock_entries.voucher_id`: `BIGINT UNSIGNED NOT NULL` — mandatory, no orphan entries
- `inv_goods_receipt_notes.voucher_id`: `BIGINT UNSIGNED NULL` — set only on acceptance
- `inv_stock_issues.voucher_id`: `BIGINT UNSIGNED NULL` — set only on issue execution
- `inv_assets.acc_fixed_asset_id`: `BIGINT UNSIGNED NULL` — nullable, synced from Accounting
- `inv_stock_adjustment_items.variance_qty`: GENERATED ALWAYS (do NOT allow INSERT/UPDATE on this column)
- `inv_purchase_order_items.received_qty`: `DECIMAL(15,3) DEFAULT 0` — auto-updated by GrnPostingService
- `inv_issue_request_items.issued_qty`: `DECIMAL(15,3) DEFAULT 0` — auto-updated as issued

**File header comment to include:**
```sql
-- =============================================================================
-- INV — Inventory Module DDL
-- Module: Inventory (Modules\Inventory)
-- Table Prefix: inv_* (28 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: INV_Inventory_Requirement.md v2
-- Sub-Modules: L1 Masters, L2 Stock Ledger, L3 Procurement, L4 Vendor,
--              L5 Assets, L6 Quotations, Stock Issue, Reorder
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`INV_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_inv_tables.php`.
- `up()`: creates all 28 tables in Layer 1 → Layer 10 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 10 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, decimal with `->decimal(15, 3)` or `->decimal(15, 2)`, generated column with `->storedAs()`
- All FK constraints added in `up()` using `$table->foreign()`
- Use `->storedAs('physical_qty - system_qty')` for `variance_qty` column

### Phase 2C Task — Generate Seeders (4 seeders + 1 runner)

Namespace: `Modules\Inventory\Database\Seeders`

**1. `InvStockGroupSeeder.php`** — 10 seeded groups (`is_system=1`):
```
Stationery         | code: STAT | default_uom: Pcs
Lab Equipment      | code: LAB  | default_uom: Nos
Sports Equipment   | code: SPRT | default_uom: Nos
Furniture          | code: FURN | default_uom: Nos
Cleaning Supplies  | code: CLNG | default_uom: Ltrs
IT Equipment       | code: IT   | default_uom: Nos
Books & Journals   | code: BOOK | default_uom: Nos
Electrical Items   | code: ELEC | default_uom: Nos
Uniforms & Textiles| code: UNIF | default_uom: Metres
Miscellaneous      | code: MISC | default_uom: Nos
```
Note: `default_uom_id` — resolve UOM IDs from `inv_units_of_measure` seeded in InvUomSeeder; run UOM seeder first.

**2. `InvUomSeeder.php`** — 10 seeded UOMs (`is_system=1`):
```
Pieces    | Pcs  | decimal_places=0
Kilograms | Kg   | decimal_places=2
Litres    | Ltr  | decimal_places=2
Box       | Box  | decimal_places=0
Ream      | Ream | decimal_places=0
Set       | Set  | decimal_places=0
Pair      | Pair | decimal_places=0
Bottles   | Btl  | decimal_places=0
Metres    | Mtr  | decimal_places=2
Numbers   | Nos  | decimal_places=0
```

**3. `InvGodownSeeder.php`** — 5 seeded godowns (`is_system=1`):
```
Main Store    | code: MAIN  | parent_id: NULL
Lab Store     | code: LAB   | parent_id: NULL
Sports Room   | code: SPRT  | parent_id: NULL
IT Room       | code: IT    | parent_id: NULL
Library Store | code: LIB   | parent_id: NULL
```

**4. `InvAssetCategorySeeder.php`** — 5 default asset categories:
```
IT Equipment      | code: IT-ASSET | depreciation_rate: 40.00 | useful_life_years: 5
Furniture         | code: FURN-AST | depreciation_rate: 10.00 | useful_life_years: 10
Lab Equipment     | code: LAB-ASST | depreciation_rate: 15.00 | useful_life_years: 7
Electrical/AC     | code: ELEC-AST | depreciation_rate: 15.00 | useful_life_years: 7
Sports Equipment  | code: SPRT-AST | depreciation_rate: 20.00 | useful_life_years: 5
```
Depreciation rates per Income Tax Act Schedule II (WDV method).

**5. `InvSeederRunner.php`** (Master seeder, calls all in order):
```php
$this->call([
    InvUomSeeder::class,        // no dependencies
    InvStockGroupSeeder::class, // depends on InvUomSeeder (for default_uom_id)
    InvGodownSeeder::class,     // no dependencies
    InvAssetCategorySeeder::class, // no dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `INV_DDL_v1.sql` | `{OUTPUT_DIR}/INV_DDL_v1.sql` |
| `INV_Migration.php` | `{OUTPUT_DIR}/INV_Migration.php` |
| `INV_TableSummary.md` | `{OUTPUT_DIR}/INV_TableSummary.md` |
| `Seeders/InvUomSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/InvStockGroupSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/InvGodownSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/InvAssetCategorySeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/InvSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 28 inv_* tables exist in DDL (10 in layers 1–3 masters + 2 stock ledger + 3 vendor + 8 procurement + 4 issue + 2 adjustment + 3 asset = 32? — recount: 6 masters + 2 stock ledger + 3 vendor + 8 procurement + 4 issue + 2 adjustment + 3 asset = 28 ✓)
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on ALL 28 tables
- [ ] `inv_stock_entries.voucher_id` is `BIGINT UNSIGNED NOT NULL` (mandatory, not nullable)
- [ ] `inv_goods_receipt_notes.voucher_id` is nullable (set on acceptance only)
- [ ] `inv_assets.acc_fixed_asset_id` is nullable
- [ ] `inv_stock_adjustment_items.variance_qty` is GENERATED ALWAYS AS STORED — NOT a regular column
- [ ] `inv_purchase_order_items.received_qty` defaults to 0 (auto-updated, not user-entered)
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] `inv_stock_groups.parent_id` is a self-referencing nullable FK
- [ ] `inv_godowns.parent_id` is a self-referencing nullable FK
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_inv_` convention throughout
- [ ] InvUomSeeder has all 10 UOMs with correct symbol and decimal_places
- [ ] InvStockGroupSeeder has all 10 groups with `is_system=1`
- [ ] InvGodownSeeder has all 5 godowns with `is_system=1`
- [ ] InvAssetCategorySeeder has depreciation rates per Income Tax Act
- [ ] `InvSeederRunner.php` calls all 4 seeders in dependency order (UOM before StockGroup)
- [ ] `INV_TableSummary.md` has one-line description for all 28 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `INV_DDL_v1.sql` + Migration + 5 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/INV_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 12 (tests), Section 14 (implementation sequence), Section 15 (file list)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `INV_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 6 (routes). For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (18 total, from req v2 Section 15 file list):
1. `InvDashboardController` — index (dashboard KPIs)
2. `StockGroupController` — index, store, show, update, destroy, toggleStatus
3. `UomController` — index, store, show, update, destroy + indexConversions, storeConversion, updateConversion, destroyConversion
4. `StockItemController` — index, store, show, update, destroy, toggleStatus, printLabels
5. `GodownController` — index, store, show, update, destroy
6. `AssetCategoryController` — index, store, show, update, destroy
7. `ItemVendorController` — index, store, update, destroy
8. `RateContractController` — index, store, show, update, destroy, activate + items, storeItem, updateItem, destroyItem
9. `PurchaseRequisitionController` — index, store, show, update, destroy, submit, approve, reject, import
10. `QuotationController` — index, store, show, update, destroy, compare, convertToPO
11. `PurchaseOrderController` — index, store, show, update, destroy, sendToVendor, approve, cancel, convertFromPR
12. `GrnController` — index, store, show, update, destroy, inspect, accept, reject
13. `IssueRequestController` — index, store, show, update, destroy, approve, reject
14. `StockIssueController` — index, store, show, acknowledge, printSlip
15. `StockEntryController` — index, show (read-only; no create/update/delete routes)
16. `StockAdjustmentController` — index, store, show, update, submit, approve, reject
17. `AssetController` — index, show, update, transfer, dispose, maintenanceIndex, storeMaintenance, printTag
18. `InvReportController` — stockBalance, stockValuation, stockLedger, consumption, purchaseRegister, pendingPO, grnRegister, reorderAlerts, fastSlowMovers, expiryAlerts, assetRegister, export (type-based)

#### Section 2 — Service Inventory (7 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events fired
- Other services called (dependency graph)

Include the GRN acceptance sequence as inline pseudocode in `GrnPostingService`:
```
acceptGrn(GoodsReceiptNote $grn): void
  Step 1: Validate all items: accepted_qty + rejected_qty == received_qty (BR-INV-006)
  Step 2: Validate cumulative received_qty <= PO ordered_qty per item (BR-INV-007)
  Step 3: DB transaction begins
  Step 4: For each accepted GRN item:
            StockLedgerService::postInward(item, qty, rate, batch, expiry, godown)
            → creates inv_stock_entries (inward)
            → updates inv_stock_balances (lockForUpdate)
            → if item.item_type == 'asset': create inv_assets records (one per unit)
  Step 5: Update inv_purchase_order_items.received_qty (auto-transitions PO status)
  Step 6: Update inv_item_vendor_jnt: last_purchase_rate + last_purchase_date
  Step 7: GRN status → 'accepted' (or 'partial' if any items rejected)
  Step 8: DB transaction commits
  Step 9: Fire GrnAccepted event (Accounting creates Purchase Voucher)
  Step 10: ReorderAlertService::checkAfterInward() — no alert on inward (stock increased)
```

Include the stock issue execution sequence as inline pseudocode in `StockIssueService`:
```
executeIssue(IssueRequest $request, array $issueItems): StockIssue
  Step 1: Check inv_stock_balances.current_qty >= requested_qty per item (BR-INV-003)
  Step 2: Determine issue cost per item via StockValuationService
  Step 3: DB transaction begins
  Step 4: Create inv_stock_issues header
  Step 5: For each item:
            Create inv_stock_issue_items
            StockLedgerService::postOutward(item, qty, cost, batch, godown)
            → creates inv_stock_entries (outward)
            → updates inv_stock_balances (lockForUpdate, deduct)
  Step 6: IssueRequest status → 'issued' (or 'partial' if partial)
  Step 7: DB transaction commits
  Step 8: Fire StockIssued event (Accounting creates Stock Journal)
  Step 9: ReorderAlertService::checkAfterOutward(items) — dispatches ReorderAlertJob if below threshold
```

#### Section 3 — FormRequest Inventory (13 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

Group by controller. 13 total (from req v2 Section 15 Requests/ folder):
- `StoreStockGroupRequest` — name required, parent_id exists in inv_stock_groups if provided
- `StoreUomRequest` — name required, symbol required, decimal_places 0–4
- `StoreUomConversionRequest` — from_uom_id != to_uom_id, conversion_factor > 0, effective_from before effective_to
- `StoreStockItemRequest` — name required, sku unique if provided, stock_group_id exists, valuation_method valid enum
- `StoreGodownRequest` — name required, code unique if provided, parent_id different from self
- `StorePurchaseRequisitionRequest` — required_date >= today, at least 1 line item, each qty > 0
- `StoreQuotationRequest` — vendor_id exists in vnd_vendors, validity_date required if status sent, at least 1 item
- `StorePurchaseOrderRequest` — vendor_id exists, order_date required, at least 1 line item, unit_price > 0
- `StoreGrnRequest` — po_id exists and is 'sent' or 'partial', at least 1 line item, accepted_qty + rejected_qty == received_qty per item (BR-INV-006)
- `StoreIssueRequestRequest` — department_id exists in sch_department, required_date required, at least 1 item with qty > 0
- `StoreStockIssueRequest` — godown_id exists, at least 1 item, stock availability check
- `StoreRateContractRequest` — vendor_id exists, valid_from before valid_to, at least 1 item with agreed_rate > 0
- `StoreStockAdjustmentRequest` — adjustment_date required, godown_id exists, at least 1 item with physical_qty >= 0

#### Section 4 — Blade View Inventory (~65 views)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and screen counts (from req v2 Section 7 SCR-INV-01 to SCR-INV-40):
- Dashboard: 1 view
- Masters (Stock Groups, UOM, Items, Godowns, Asset Categories): ~10 views
- Vendor Linkage (Item-Vendor, Rate Contracts): ~6 views
- Procurement (PR, Quotation, PO, GRN): ~16 views
- Stock Issue (Issue Requests, Stock Issues, Issue Slip PDF): ~8 views
- Stock Ledger & Balance: ~4 views
- Stock Adjustments: ~4 views
- Assets (Register, Detail, Transfer, Tag, Maintenance): ~8 views
- Reports (12 report views): ~8 views (including export)
- Shared partials: ~5 partials (pagination, export buttons, modals)

For key screens document:
- Route name, view file path, key UI components (modals, tables, AJAX calls)
- Quotation comparison matrix — side-by-side vendor quote table, lowest rate highlighted with JS
- GRN form — inline validation of accepted+rejected=received per row using Alpine.js
- Stock balance dashboard widget — AJAX polling for low-stock items count
- PR CSV import — preview validation table before final import (Livewire or AJAX)

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by section (6.1–6.6). Count total routes at the end (target ~65).
Middleware on all routes: `['auth', 'tenant', 'EnsureTenantHasModule:Inventory']`

#### Section 6 — Implementation Phases (7 phases per req v2 Section 14.6)

For each phase, provide a detailed sprint plan:

**Phase 1 — Masters** (no cross-module deps beyond sys_*):
FRs: INV-001, INV-002, INV-003, INV-004
Files to create:
- Controllers: InvDashboardController, StockGroupController, UomController, StockItemController, GodownController, AssetCategoryController
- Services: StockValuationService (item valuation method assignment only)
- Models: StockGroup, UnitOfMeasure, UomConversion, StockItem, Godown, AssetCategory
- FormRequests: StoreStockGroupRequest, StoreUomRequest, StoreUomConversionRequest, StoreStockItemRequest, StoreGodownRequest
- Seeders: InvUomSeeder, InvStockGroupSeeder, InvGodownSeeder, InvAssetCategorySeeder
- Views: ~10 master views
- Tests: StockGroupTest, StockItemTest, UomConversionTest, GodownTest

**Phase 2 — Vendor Linkage** (requires VND module: vnd_vendors):
FRs: INV-010 (partial)
Files to create:
- Controllers: ItemVendorController, RateContractController
- Models: ItemVendor, RateContract, RateContractItem
- FormRequests: StoreRateContractRequest
- Views: ~6 vendor linkage views
- Events: RateContractExpiringSoon
- Artisan: `inventory:expire-rate-contracts`
- Tests: RateContractTest

**Phase 3 — Procurement** (requires SCH: sch_department; no ACC yet):
FRs: INV-007, INV-008, INV-013 (RFQ)
Files to create:
- Controllers: PurchaseRequisitionController, QuotationController, PurchaseOrderController
- Services: PurchaseOrderService
- Models: PurchaseRequisition, PurchaseRequisitionItem, Quotation, QuotationItem, PurchaseOrder, PurchaseOrderItem
- FormRequests: StorePurchaseRequisitionRequest, StoreQuotationRequest, StorePurchaseOrderRequest
- Views: ~16 procurement views (PR list/form/show/import, Quotation list/compare, PO list/form/show, GRN list/form/show)
- Tests: PurchaseRequisitionTest, QuotationTest, PurchaseOrderTest

**Phase 4 — GRN & Stock Entry** (requires ACC: VoucherServiceInterface, acc_vouchers):
FRs: INV-005, INV-005a, INV-009
Files to create:
- Controllers: GrnController, StockEntryController
- Services: StockLedgerService, GrnPostingService (fires GrnAccepted)
- Models: GoodsReceiptNote, GrnItem, StockEntry, StockBalance
- FormRequests: StoreGrnRequest
- Events: GrnAccepted
- Artisan: `inventory:recalculate-balances`
- Views: ~6 GRN + stock ledger views
- Tests: GrnTest, StockLedgerServiceTest, GrnPostingServiceTest, StockBalanceTest

**Phase 5 — Issue Workflow**:
FRs: INV-014, INV-015 (partial — reorder)
Files to create:
- Controllers: IssueRequestController, StockIssueController
- Services: StockIssueService, ReorderAlertService (fires ReorderThresholdReached)
- Jobs: ReorderAlertJob
- Models: IssueRequest, IssueRequestItem, StockIssue, StockIssueItem
- FormRequests: StoreIssueRequestRequest, StoreStockIssueRequest
- Events: StockIssued, ReorderThresholdReached
- Artisan: `inventory:check-reorder-levels`
- Views: ~8 issue views + issue slip DomPDF
- Tests: StockIssueTest, ReorderAlertTest, ReorderAlertServiceTest

**Phase 6 — Assets**:
FRs: INV-011, INV-012
Files to create:
- Controllers: AssetController
- Models: Asset, AssetMovement, AssetMaintenance
- Events: AssetDisposed, MaintenanceOverdue
- Artisan: `inventory:maintenance-overdue`
- Views: ~8 asset views (register, detail, transfer, tag DomPDF, maintenance)
- Tests: AssetTest

**Phase 7 — Adjustments & Reports**:
FRs: INV-006, INV-015 (reports + labels)
Files to create:
- Controllers: StockAdjustmentController, InvReportController
- Services: InventoryReportService (complete — all 12 reports)
- Models: StockAdjustment, StockAdjustmentItem
- FormRequests: StoreStockAdjustmentRequest
- Events: StockAdjusted
- Views: ~8 adjustment + 8 report views; barcode/QR label view
- Tests: StockAdjustmentTest, StockValuationServiceTest

#### Section 7 — Seeder Execution Order

```
php artisan module:seed Inventory --class=InvSeederRunner
  ↓ InvUomSeeder              (no dependencies)
  ↓ InvStockGroupSeeder       (depends on InvUomSeeder — uses default_uom_id from UOM records)
  ↓ InvGodownSeeder           (no dependencies)
  ↓ InvAssetCategorySeeder    (no dependencies)
```

For test runs: use `InvUomSeeder` + `InvStockGroupSeeder` as minimum required seeders.
For Phase 6 tests: add `InvAssetCategorySeeder`.
For Phase 3+ tests: add `InvGodownSeeder`.

Artisan scheduled commands (register in `routes/console.php`):
```
inventory:expire-rate-contracts    → daily midnight
inventory:check-reorder-levels     → daily morning (or triggered per stock entry)
inventory:maintenance-overdue      → daily morning
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// Accounting VoucherServiceInterface: mock with Event::fake() — Inventory fires events, not calls
// Event::fake() in GRN + Stock Issue + Adjustment tests
// Queue::fake() in reorder alert and ReorderAlertJob tests
// Bus::fake() for Artisan command tests
```

**Minimum Test Coverage Targets:**
- GRN FSM: all state transitions + BR-INV-006 (qty validation) + BR-INV-007 (cumulative check)
- BR-INV-003 (negative stock prevention): explicitly tested in StockIssueTest
- BR-INV-008 (FIFO batch selection): StockValuationServiceTest — oldest batch used first
- BR-INV-014 (immutable stock entries): StockLedgerServiceTest — attempt to update posted entry fails
- Reorder alert: fires when below threshold; does NOT fire when above; auto-PR when flag enabled
- Asset creation on GRN: one inv_assets row per unit of accepted asset item
- Stock balance concurrency: concurrent writes with row-lock test

**Feature Test File Summary (from req v2 Section 12.1):**
List all 13 test files with file path, test count, and key scenarios.

**Unit Test File Summary (from req v2 Section 12.2):**
List all 5 unit test files with file path, test count, and scenarios.

**Factory Requirements:**
```
StockItemFactory        — generates item with valuation_method, reorder_level, item_type
PurchaseRequisitionFactory — generates pr_number (PR-YYYY-NNN), status=draft, items
PurchaseOrderFactory    — generates po_number (PO-YYYY-NNN), vendor_id from vnd_vendors
GrnFactory              — generates grn_number (GRN-YYYY-NNN), linked po_id, status=draft
StockIssueFactory       — generates issue_number (SI-YYYY-NNN), godown_id
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `INV_Dev_Plan.md` | `{OUTPUT_DIR}/INV_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 18 controllers listed with all methods
- [ ] All 7 services listed with at minimum 3 key method signatures each
- [ ] GrnPostingService pseudocode present (10-step acceptance sequence)
- [ ] StockIssueService pseudocode present (9-step execution sequence)
- [ ] All 13 FormRequests listed with their key validation rules
- [ ] All 15 FRs (INV-001 to INV-015) appear in at least one implementation phase
- [ ] All 7 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented with dependency note (UOM before StockGroup)
- [ ] All 4 Artisan commands listed with schedule
- [ ] Route list consolidated with middleware and FR reference (~65 routes total)
- [ ] View count per sub-module totals approximately 65
- [ ] Test strategy includes Event::fake() for GrnAccepted/StockIssued
- [ ] BR-INV-003 (negative stock) test explicitly referenced
- [ ] BR-INV-014 (immutable entries) test explicitly referenced
- [ ] `inv_stock_entries` has NO update/delete routes in route list
- [ ] ReorderAlertJob documented with 3 retries + 60s delay

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `INV_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/INV_FeatureSpec.md`
2. `{OUTPUT_DIR}/INV_DDL_v1.sql` + Migration + 5 Seeders
3. `{OUTPUT_DIR}/INV_Dev_Plan.md`
Development lifecycle for INV (Inventory) module is ready to begin."

---

## QUICK REFERENCE — INV Module Tables vs Controllers vs Services

| Domain | inv_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Masters | inv_stock_groups, inv_units_of_measure, inv_uom_conversions, inv_stock_items, inv_godowns | StockGroupController, UomController, StockItemController, GodownController | StockValuationService (method assignment) |
| Asset Categories | inv_asset_categories | AssetCategoryController | — |
| Stock Ledger | inv_stock_entries, inv_stock_balances | StockEntryController | StockLedgerService, StockValuationService |
| Vendor Linkage | inv_item_vendor_jnt, inv_rate_contracts, inv_rate_contract_items_jnt | ItemVendorController, RateContractController | — (direct in controller) |
| Procurement | inv_purchase_requisitions + items, inv_quotations + items, inv_purchase_orders + items | PurchaseRequisitionController, QuotationController, PurchaseOrderController | PurchaseOrderService |
| GRN | inv_goods_receipt_notes, inv_grn_items | GrnController | GrnPostingService |
| Stock Issue | inv_issue_requests + items, inv_stock_issues + items | IssueRequestController, StockIssueController | StockIssueService, ReorderAlertService |
| Adjustments | inv_stock_adjustments, inv_stock_adjustment_items | StockAdjustmentController | StockLedgerService |
| Assets | inv_assets, inv_asset_movements, inv_asset_maintenance | AssetController | — (direct in controller + event) |
| Reports | (reads all inv_* tables) | InvReportController | InventoryReportService |
| Dashboard | (aggregates) | InvDashboardController | — (direct queries) |
