# Financial Year — Business Requirements

## What This Screen Does

The Financial Year screen manages the accounting periods used across all Accounting features. Each financial year defines a start and end date range. The screen supports locking/unlocking individual years to prevent data entry in closed periods, and a full CRUD lifecycle with soft-delete.

## When This Screen Is Used

- **At the start of a new accounting period** when creating the new financial year.
- **At year-end close** when locking the completed year after final reconciliation.
- **When reopening a locked year** for adjustments or corrections.
- **When configuring default financial year** for the tenant to auto-select in transaction screens.

## Key Fields

- **Year Name** (string 50) — Display label (e.g., "FY 2025–2026")
- **Start Date** (date) — Beginning of the fiscal period
- **End Date** (date) — Calculated as `start_date + 1 year - 1 day` on create, manually editable on update
- **Is Active** (boolean) — Whether this FY is the active/default selection
- **Is Locked** (boolean) — When locked, transactions cannot be posted to this period
- **Created By** (FK → sys_users, nullable)

## Business Rules

**End Date Auto-Calculation:**
When creating a new financial year, the `end_date` is automatically computed as `start_date + 1 year - 1 day` using `Carbon::parse($startDate)->addYear()->subDay()`. On update, the user can manually set the end_date.

**Single Active Year:**
Only one financial year can be active at a time. When a new FY is set as active, the previous active FY is deactivated.

**Lock Protection:**
A locked financial year cannot be deleted (`$financialYear->is_locked` check in `destroy()`). Voucher posting must reject if the voucher date falls in a locked FY.

**Voucher Number Reset:**
When a new financial year is created, voucher number sequences should reset per year (voucher type numbering restarts from the beginning for the new FY).

**Delete Guard:**
A financial year cannot be deleted if it has existing voucher records.

**Soft Delete:**
Uses SoftDeletes. Trash view, restore, and forceDelete routes available.

**Status Toggle:**
Ajax endpoint `toggleStatus()` flips `is_active`.

## Workflow

1. User navigates to Accounting → Setup Masters → Financial Year.
2. Table displays: Year Name, Start/End Dates, Is Active badge, Is Locked badge, Actions.
3. User can create, edit, view, toggle active status, toggle lock status, soft-delete with restore/forceDelete.
4. Creating a new FY auto-calculates end_date. User can override on edit.
5. Locked FY shows warning badge. Unlock to allow transactions.

## Requirements

- MUST display at `/financial-year?tab=financial-year` as paginated table
- MUST authorize via `tenant.accounting.financial-year.*` policy gates
- MUST auto-calculate end_date as `start_date + 1 year - 1 day` on create
- MUST allow manual end_date override on update
- MUST enforce single active FY at any time
- MUST prevent creating a year with duplicate year_name
- MUST prevent deleting a locked financial year
- MUST prevent deleting a financial year with existing vouchers
- MUST support lock/unlock via Ajax toggle
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
