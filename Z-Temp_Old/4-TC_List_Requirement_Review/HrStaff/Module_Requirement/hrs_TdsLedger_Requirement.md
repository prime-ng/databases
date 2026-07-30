# TDS Ledger — Business Requirements

## What This Screen Does

The TDS Ledger maintains a monthly cumulative record of tax deducted at source (TDS) from employee salaries. It stores per-employee, per-month, per-financial-year entries tracking gross pay, TDS deducted, and year-to-date (YTD) running totals. The ledger is automatically populated by the payroll computation engine when payroll runs are computed, but also supports manual CRUD operations for corrections and adjustments.

The ledger serves as the authoritative data source for Form 16 generation and provides the YTD context needed by the TDS computation engine to project annual income and compute correct monthly TDS amounts.

## When This Screen Is Used

- **Payroll computation** (automated) when the payroll engine records monthly TDS and updates YTD totals for each employee after computing a payroll run
- **TDS correction** when HR needs to manually create, edit, or delete a TDS ledger entry for an employee for a specific month
- **TDS audit** when reviewing cumulative TDS deductions for an employee across a financial year
- **Form 16 preparation** when the Form 16 generator reads the ledger to populate annual TDS data

## Default Data Load

The `TdsLedgerController@index` method redirects to the HR Masters tabbed page with the `tds-ledgers` tab active, reached via route `hr-staff.menu.hrMasters?tab=tds-ledgers`. The actual listing of TDS ledger entries is rendered by the HR Masters menu view, which typically queries all active TDS ledger records with employee eager-loading, paginated.

Individual entry views (`show`, `edit`) are accessed via the resource routes and load the specific `TdsLedger` record with its employee relationship.

## Key Fields at a Glance

**Identity and Period**
- `employee_id` — the employee this TDS record belongs to
- `financial_year` — the financial year in `YYYY-YY` format (e.g. `2025-26`)
- `month` — month number (1–12) within the financial year

**Financial Values**
- `gross_pay` — gross salary for this specific month
- `tds_deducted` — TDS deducted for this specific month
- `ytd_gross` — cumulative gross salary from April onwards (YTD)
- `ytd_tds` — cumulative TDS deducted from April onwards (YTD)

## Business Rules and Conditions

**Auto-Population During Payroll Computation** — When `PayrollComputationService::computeEmployee()` runs, it calls `TdsComputationService::recordTdsLedger()` which upserts the ledger entry for the employee+month+FY, computing YTD totals from the prior month's entry.

**Unique Per Employee Per Month Per FY** — The `uq_pay_tds` unique constraint on `(employee_id, financial_year, month)` ensures exactly one entry per employee per month per FY. The `updateOrCreate` logic in `recordTdsLedger()` keeps this idempotent.

**YTD Rollup** — When recording a new month's entry, the system finds the prior month's YTD totals and adds the current month's values to derive new YTD totals. This ensures a continuous cumulative chain.

**Manual CRUD for Corrections** — The full resource controller (`index`, `show`, `store`, `edit`, `update`, `destroy`, `trashed`, `restore`, `forceDelete`, `toggleStatus`) allows HR to manually create, edit, soft-delete, restore, and permanently delete entries. Manual entries bypass the YTD rollup logic (user must provide YTD values directly).

## Workflow Steps

**Auto-Recording During Payroll** — When a payroll run is computed, for each employee, the computation service computes the monthly TDS via `TdsComputationService::computeMonthlyTds()`, then calls `recordTdsLedger()` which queries the prior month's entry for that employee+FY, adds current gross/TDS to prior YTD totals, and upserts the entry.

**Manual Entry Creation** — HR navigates to HR Masters → TDS Ledger, clicks "Create New Entry." They select the employee, financial year, month, enter gross pay, TDS deducted, YTD gross, YTD TDS, and submit. The system validates the unique constraint on (employee, FY, month) and creates the record.

**Editing an Entry** — HR edits an existing entry to correct any field. The unique constraint ignores the current record ID so the same employee+FY+month combination is allowed.

**Soft Deletion** — Deleting an entry sets `deleted_at` and sets `is_active = false`. Trashed entries can be restored from the trash view.

## Example Scenario

During January 2026 payroll computation for Green Valley School, the TDS engine processes employee Priya. Her prior YTD (April–December) shows gross of ₹3,42,000 and TDS of ₹12,800. Her January gross is ₹28,500. The system computes monthly TDS as ₹1,600, records January's entry with gross ₹28,500, TDS ₹1,600, YTD gross ₹3,70,500, and YTD TDS ₹14,400. Later, HR discovers a data entry error and manually corrects January's TDS from ₹1,600 to ₹1,700 via the edit screen.

## Related Screens

- **Form 16** — reads TDS ledger data as the source for annual tax certificate generation
- **Payroll Runs** — payroll computation triggers automatic TDS ledger recording
- **Compliance Records (TDS)** — holds the employee's tax regime selection (old/new) and deduction declarations used by the TDS computation engine
- **Payslips** — display the monthly TDS deducted, sourced from the same computation run

## Requirements

- `TdsLedgerController@index(Request)` — redirects to HR Masters tabbed page with `tab=tds-ledgers`
- `TdsLedgerController@store(StoreTdsLedgerRequest)` — creates a new TDS ledger entry; gates on `hrs.compliance.manage`; logs "TDS ledger entry created." activity
- `TdsLedgerController@show(TdsLedger)` — displays a single entry with employee; gates on `hrs.compliance.manage`
- `TdsLedgerController@edit(TdsLedger)` — shows edit form with employee dropdown; gates on `hrs.compliance.manage`
- `TdsLedgerController@update(StoreTdsLedgerRequest, TdsLedger)` — updates an entry; gates on `hrs.compliance.manage`; logs activity
- `TdsLedgerController@destroy(TdsLedger)` — soft-deletes (sets `is_active=false`, calls `delete()`); gates on `hrs.compliance.manage`; logs activity
- `TdsLedgerController@restore($id)` — restores a trashed entry; gates on `hrs.compliance.manage`; sets `is_active=true`
- `TdsLedgerController@forceDelete($id)` — permanently deletes; gates on `hrs.compliance.manage`
- `TdsLedgerController@trashed()` — lists soft-deleted entries; gates on `hrs.compliance.manage`
- `TdsLedgerController@toggleStatus(TdsLedger)` — AJAX toggle for `is_active`; gates on `hrs.compliance.manage`
- `StoreTdsLedgerRequest` — validates `employee_id` (required, exists on `sch_employees`, unique with financial_year+month ignoring current ID), `financial_year` (required, regex `YYYY-YY`), `month` (required, integer, 1-12), `gross_pay` (required, numeric, min:0), `tds_deducted` (required, numeric, min:0), `ytd_gross` (required, numeric, min:0), `ytd_tds` (required, numeric, min:0), `is_active` (required, boolean, auto-set in `prepareForValidation()`)
- `TdsComputationService::recordTdsLedger()` — upserts ledger entry with auto-computed YTD totals during payroll computation
- `TdsComputationService::computeMonthlyTds()` — reads YTD totals from ledger to project annual income and compute monthly TDS
- Model uses `SoftDeletes`, `$casts` for month (integer), gross_pay/tds_deducted/ytd_gross/ytd_tds (decimal:2), is_active (boolean)
- Relationships: `employee()` (BelongsTo Employee)
- Scopes: `active()`, `forFinancialYear($fy)`

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.compliance.manage` | All CRUD methods (store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, index) | Full access to TDS ledger management |
| Policy | No dedicated policy — uses Gate::authorize() directly in controller | All methods use same permission |

## Logic Flow

**Page Load (index)** — User accesses HR Masters tabbed page. The `tab=tds-ledgers` parameter triggers the TDS ledger listing within the tab view.

**Store (manual)** — User fills `StoreTdsLedgerRequest`. Validation checks existence of employee, financial year format, month range, financial amounts, and unique combination of (employee, FY, month). The system creates the record and redirects back to the tabbed listing with success flash.

**Auto-Record (computation)** — `TdsComputationService::recordTdsLedger()` queries the prior month's entry for the same employee+FY to get prior YTD values, adds current month's gross/TDS to prior YTD, and upserts via `updateOrCreate` on the unique key.

**Update** — Same request validation. The unique rule ignores the current ID so the same employee+FY+month is permitted. Activity is logged.

**Delete** — Sets `is_active=false`, then calls `delete()` for soft deletion. Redirects to the listing. Trashed entry can be restored via `restore()` which sets `is_active=true`.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `employee_id` | required, exists:sch_employees,id, unique:pay_tds_ledger,employee_id+financial_year+month except current ID | The Employee field is required. |
| `financial_year` | required, string, regex:/^\d{4}-\d{2}$/ | The Financial Year must be in YYYY-YY format. |
| `month` | required, integer, min:1, max:12 | Month must be between 1 and 12. |
| `gross_pay` | required, numeric, min:0 | Gross Pay must be a number and at least 0. |
| `tds_deducted` | required, numeric, min:0 | TDS Deducted must be a number and at least 0. |
| `ytd_gross` | required, numeric, min:0 | YTD Gross must be a number and at least 0. |
| `ytd_tds` | required, numeric, min:0 | YTD TDS must be a number and at least 0. |
| `is_active` | required, boolean | Automatically set via `prepareForValidation()` |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate employee+FY+month entry | "The Employee has already been taken." (unique validation) | Validation rule |
| Invalid financial year format | Route not matched or validation error | Validation / 404 |
| Missing permission | HTTP 403 | Gate |

## Success Scenarios

**SC-001 — TDS Ledger Entry Created Manually** — HR creates an entry for employee Priya, FY 2025-26, month 1 (April), gross ₹28,500, TDS ₹800, YTD gross ₹28,500, YTD TDS ₹800. Entry created. Flash: "TDS ledger entry created successfully."

**SC-002 — TDS Ledger Entry Updated** — HR corrects an entry's TDS amount from ₹1,600 to ₹1,700. Flash: "TDS ledger entry updated successfully."

**SC-003 — TDS Ledger Entry Soft-Deleted** — HR deletes an erroneous entry. Record soft-deleted, `is_active=false`. Flash: "TDS ledger entry removed successfully."

**SC-004 — TDS Ledger Entry Restored** — HR restores a trashed entry. `deleted_at=null`, `is_active=true`. Flash: "TDS ledger entry restored successfully."

## Failure Scenarios

**FC-001 — Duplicate Employee+FY+Month** — HR tries to create a second entry for the same employee in the same month and FY. Validation error: "The Employee has already been taken."

**FC-002 — Invalid Financial Year Format** — HR enters `2025` instead of `2025-26`. Validation error.

**FC-003 — Month Out of Range** — HR enters `13` for month. Validation error: "Month must be between 1 and 12."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_employees` | FK parent | `pay_tds_ledger.employee_id` → `sch_employees.id` (RESTRICT) |
| `TdsComputationService` | Service | Reads and writes ledger entries during payroll computation |
| `Form16Service` | Consumer | Reads ledger for Form 16 PDF generation |
| `PayrollComputationService` | Consumer | Reads ledger for YTD context during TDS computation |

**Table: `pay_tds_ledger`**

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| financial_year | VARCHAR(7) | NOT NULL, YYYY-YY format |
| month | TINYINT UNSIGNED | NOT NULL, 1–12 |
| gross_pay | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| tds_deducted | DECIMAL(10,2) | NOT NULL, DEFAULT 0 |
| ytd_gross | DECIMAL(14,2) | NOT NULL, DEFAULT 0 |
| ytd_tds | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
| UNIQUE KEY | `uq_pay_tds` | (`employee_id`, `financial_year`, `month`) |
