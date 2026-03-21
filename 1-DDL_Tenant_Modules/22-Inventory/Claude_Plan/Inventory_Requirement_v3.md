# Inventory Module — Detailed Requirement Document v3

**Module:** Inventory & Stock Management | **Laravel Module:** `Modules/Inventory/` | **Prefix:** `inv_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/inventory/*` | **RBS Module:** L — Inventory & Stock Management (50 sub-tasks)
**Date:** 2026-03-19 | **Version:** 3.0

**Changes from v2:** Verified ALL tables against `0-DDL_Masters/tenant_db_v2.sql`. Fixed table name singulars (`sch_department`, `sch_designation`). Confirmed no `sch_teachers` table exists (use `sch_employees.is_teacher=1`). No functional changes to inventory tables — all 19 `inv_` tables confirmed as genuinely new.

---

## 1. Module Overview & Purpose

*(Same as v2 — no changes)*

The Inventory module is a **separate Laravel module** (`Modules/Inventory/`) that manages **school stock and procurement**. It connects to the **Accounting module** via `VoucherServiceInterface` to post purchase vouchers and stock journal entries.

---

## 2. Scope & Boundaries

*(Same as v2 — no changes)*

---

## 3. RBS Mapping (Module L — 50 Sub-Tasks)

*(Same as v2 — all 50 sub-tasks mapped to `inv_` prefixed tables. No changes needed.)*

---

## 4. Entity List — VERIFIED against `tenant_db_v2.sql`

### Existing Tables REUSED (verified as present in DDL)

| Table | Line # in DDL | Used For | Changes Needed |
|-------|--------------|----------|----------------|
| `sch_employees` | 955 | Godown in-charge, issued-to | None from Inventory |
| `sch_department` | 476 | PR/issue department (**SINGULAR** — not `sch_departments`) | None |
| `vnd_vendors` | 1810 | Supplier reference for PO/GRN | None |
| `sys_users` | 87 | created_by, approved_by, requested_by | None |

> **Note:** `sch_teachers` does NOT exist as a separate table. Use `sch_employees` where `is_teacher = 1`. No inventory table references teachers directly.

### Cross-Module References (from Accounting — verified)

| Table | Line # in old DDL | Notes |
|-------|-------------------|-------|
| `acc_tax_rates` | 9897 | Exists in old DDL. Will be in new voucher-based DDL too. |
| `acc_vouchers` | N/A (new) | New voucher-based table — replaces old `acc_journal_entries` |
| `acc_ledgers` | 9650 | Exists in old DDL. Will be restructured in new DDL. |
| `acc_fixed_assets` | 10189 | Exists. For asset-type items. |

### New Tables — ALL 19 `inv_` tables (verified as NOT existing anywhere in DDL)

#### 4.1 inv_stock_groups
*(Same as v2)*

#### 4.2 inv_units_of_measure
*(Same as v2)*

#### 4.3 inv_uom_conversions
*(Same as v2)*

#### 4.4 inv_stock_items
*(Same as v2 — FKs reference `inv_stock_groups`, `inv_units_of_measure`, `acc_tax_rates`, `acc_ledgers`)*

#### 4.5 inv_godowns
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Main Store", "Lab Store" |
| code | VARCHAR(20) NULL | Location code |
| parent_id | BIGINT UNSIGNED NULL | Self-referencing (sub-godowns) |
| address | VARCHAR(500) NULL | Physical location |
| in_charge_employee_id | BIGINT UNSIGNED NULL FK | FK → **`sch_employees`** (store keeper) |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |

#### 4.6-4.19 (All other inv_ tables)
*(Same as v2 — with these FK corrections:)*
- `inv_purchase_requisitions.department_id` → FK to **`sch_department`** (SINGULAR)
- `inv_issue_requests.department_id` → FK to **`sch_department`** (SINGULAR)
- `inv_stock_issues.department_id` → FK to **`sch_department`** (SINGULAR)
- `inv_stock_issues.issued_to_employee_id` → FK to **`sch_employees`**

---

## 5-12. Remaining Sections

*(Same as v2 — Procurement Flow, Business Rules, Integration Points, Reports, Seed Data, Roles & Permissions, Controllers & Services, Dependencies, Table Summary — with these FK name corrections:)*

### Corrected Dependencies Table

| This Module Needs | From Module | Correct Table Name |
|-------------------|------------|-------------------|
| Voucher Posting | Accounting | `VoucherServiceInterface`, `acc_vouchers` (new) |
| Tax Rates | Accounting | `acc_tax_rates` |
| Ledgers | Accounting | `acc_ledgers` (restructured in new DDL) |
| Fixed Assets | Accounting | `acc_fixed_assets` |
| Vendors | Vendor | `vnd_vendors` |
| Employees | SchoolSetup | `sch_employees` |
| Departments | SchoolSetup | **`sch_department`** (SINGULAR) |
| Users | System | `sys_users` |

### Table Summary (unchanged)

| Category | Count | Tables |
|----------|-------|--------|
| Stock Masters | 5 | inv_stock_groups, inv_units_of_measure, inv_uom_conversions, inv_stock_items, inv_godowns |
| Stock Movement | 1 | inv_stock_entries |
| Vendor Linkage | 3 | inv_item_vendor_jnt, inv_rate_contracts, inv_rate_contract_items_jnt |
| Procurement | 4 | inv_purchase_requisitions, inv_purchase_requisition_items, inv_purchase_orders, inv_purchase_order_items |
| Goods Receipt | 2 | inv_goods_receipt_notes, inv_grn_items |
| Stock Issue | 4 | inv_issue_requests, inv_issue_request_items, inv_stock_issues, inv_stock_issue_items |
| **Total** | **19** | All `inv_` prefix — all verified as genuinely new |

### Duplication Check: CLEAN
- No `inv_` table duplicates any existing table in `tenant_db_v2.sql`
- No `inv_` table duplicates any proposed `acc_` or `prl_` table
- `vnd_vendors`, `vnd_items` in Vendor module handle vendor master — Inventory only references via FK
