# PT Slabs — Business Requirements

## What This Screen Does

The PT Slabs screen allows the school to configure state-wise Profession Tax slabs. Profession Tax is a statutory deduction that varies by Indian state and is computed based on the employee's gross monthly salary. Each slab defines a salary range and the corresponding monthly PT amount. The system uses these slabs during payroll computation to determine the correct PT deduction for each employee based on their state of employment and gross monthly pay.

---

## When This Screen Is Used

- Payroll Configuration when setting up PT deduction rules for the states where the school operates
- Employee Onboarding when an employee's state code determines which PT slab applies
- Monthly Payroll Computation when the system looks up the PT amount for each employee based on gross pay and state code
- Compliance Updates when state governments revise PT slab ranges or amounts

## Default Data Load

The screen is loaded via `HrMenuController@hrMasters()` at route `GET /hr-masters` with tab parameter `tab=pt-slabs`. The controller loads PT slabs from `PtSlab::orderBy('state_code')->orderBy('min_salary')`, filtered by search (state_code) when the active tab is `pt-slabs`.

`PtSlabController@index()` at `GET /pt-slabs` redirects to the tabbed page. The primary standalone view is `PtSlabController@trashed()` for managing soft-deleted records.

---

## Key Fields at a Glance

**State Identification**
The State Code is a 2-letter ISO code such as HP (Himachal Pradesh), KA (Karnataka), or MH (Maharashtra). The system uppercases it automatically on input.

**Salary Range**
The Minimum Salary and Maximum Salary define the monthly gross salary bracket for this slab. The slab applies when an employee's gross monthly salary falls within this inclusive range. The maximum salary can be set to an arbitrarily high value (e.g., 999999999.00) for the top-most open-ended slab.

**PT Amount**
The PT Amount is the fixed monthly Profession Tax deduction in INR for employees whose gross salary falls within this slab's range.

---

## Business Rules and Conditions

**State Code Uniqueness Per Salary Range**
The combination of `state_code` and `min_salary` must be unique. This prevents overlapping slab definitions for the same state where the lower bound matches.

**Max Salary Greater Than Min Salary**
The system enforces that max_salary must be strictly greater than min_salary via the `gt:min_salary` validation rule.

**Automatic State Code Uppercasing**
The `prepareForValidation()` method in `StorePtSlabRequest` automatically converts the state code to uppercase using `strtoupper()`. The database stores the normalized uppercase value.

**Slab Overlap (Business)**
While the system does not enforce non-overlapping ranges at the database level, the unique constraint on `(state_code, min_salary)` prevents duplicate lower bounds. Schools are expected to define contiguous, non-overlapping slabs for each state.

---

## Workflow Steps

**Creating a PT Slab**
The HR Manager navigates to HR Masters → PT Slabs, clicks Add, enters state code "KA" (for Karnataka), minimum salary 0, maximum salary 15000, PT amount 0 (below threshold), and saves. They then add another slab for the same state: min 15001, max 999999999.00, PT amount 200. The system uppercases the state code and creates both slabs.

**Editing a PT Slab**
The HR Manager edits a slab to increase the PT amount following a government notification. The system updates the amount and logs the change.

---

## Example Scenario

A school in Maharashtra has three PT slabs: Gross ≤ ₹10,000 → ₹0, ₹10,001–₹25,000 → ₹110, ₹25,001+ → ₹200. When processing payroll for an employee with gross ₹32,000, the system looks up the Maharashtra PT slabs, finds the third slab where ₹32,000 falls within ₹25,001–₹999,999,999, and deducts ₹200. If the employee is in Karnataka, the system uses KA slabs instead.

---

## Related Screens

- **Salary Assignment** — Employee's state determines which PT slab applies
- **Payroll Runs** — PT deductions are computed using these slabs
- **Compliance Records** — PT compliance type stores the employee's state code

---

## Requirements

- Controller `PtSlabController`: `index()` redirects to tabbed page; `store()` creates with validated + `created_by`/`updated_by`; `show()` displays single; `edit()` loads edit form; `update()` updates with validated + `updated_by`; `toggleStatus()` flips `is_active` via JSON; `destroy()` sets `is_active=false` before soft-delete; `trashed()` lists soft-deleted ordered by state_code; `restore()` restores and sets `is_active=true`; `forceDelete()` permanently deletes
- Gate: `Gate::authorize('hrs.compliance.manage')` on all methods
- Route resource: `pt-slabs` with `except(['create'])`, plus custom `toggle-status`, `trashed`, `restore`, `force-delete`
- Validation `StorePtSlabRequest`: `state_code` required, string, size:2, uppercase, unique on `hrs_pt_slabs.state_code` scoped to `min_salary` (composite unique), ignoring current ID and null `deleted_at`; `min_salary` required, numeric, min:0; `max_salary` required, numeric, gt:min_salary; `pt_amount` required, numeric, min:0; `is_active` required, boolean
- `prepareForValidation()`: uppercases `state_code` via `strtoupper()`, casts `is_active` boolean (default true)
- Model `PtSlab`: SoftDeletes, table `hrs_pt_slabs`, `$fillable` = 6 fields, `$casts` = `min_salary` decimal:2, `max_salary` decimal:2, `pt_amount` decimal:2, `is_active` boolean; no relationships; scopes: `active()`
- No delete dependency checks (PT slabs can be deleted freely — no FK consumers block)
- Activity logged via `activityLog()` on all state-changing operations
- No dedicated policy class; authorization via Gate in controller

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `hrs.compliance.manage` | All PtSlabController methods | Single gate for all operations |

## Logic Flow

1. **Page Load** — `HrMenuController@hrMasters()` loads tabbed view. Search by state_code.
2. **Create** — `store()` validates via `StorePtSlabRequest`. `prepareForValidation()` uppercases state code and casts booleans. Unique check scoped to `(state_code, min_salary)`. Redirect to tab.
3. **Edit/Update** — `update()` merges `updated_by`. State code uniqueness rechecked ignoring current ID.
4. **Status Toggle** — AJAX flip of `is_active`.
5. **Delete** — No guards. Sets `is_active=false`, soft-deletes.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `state_code` | required, string, size:2, uppercase, unique:hrs_pt_slabs,state_code + min_salary scope | — |
| `min_salary` | required, numeric, min:0 | — |
| `max_salary` | required, numeric, gt:min_salary | — |
| `pt_amount` | required, numeric, min:0 | — |
| `is_active` | required, boolean | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate state_code+min_salary | "The state code has already been taken." | Validation (unique) |
| Max salary not greater than min | "The max salary field must be greater than min salary." | Validation (gt) |
| State code not uppercase | "The state code must be uppercase." | Validation (uppercase) |
| State code wrong length | "The state code must be 2 characters." | Validation (size) |

## Success Scenarios

**SC-001 — Creating a PT Slab**
HR Manager creates slab for KA with min 0, max 10000, PT amount 0. System uppercases "ka" to "KA", creates record, logs Created activity.

**SC-002 — Updating PT Amount**
HR Manager increases PT amount after government revision. Update succeeds.

**SC-003 — Toggling Slab Inactive**
HR Manager disables a slab via AJAX. JSON success response.

## Failure Scenarios

**FC-001 — Duplicate State Code and Min Salary**
User enters MH with min_salary 15000 when a slab for MH at min_salary 15000 already exists. Validation error: "The state code has already been taken."

**FC-002 — Max Salary Less Than Min Salary**
User enters min 20000 and max 15000. Validation error on max_salary.

**FC-003 — Lowercase State Code Submitted Without Uppercasing**
User enters "mh". The request uppercases it to "MH" in `prepareForValidation()`, bypassing the uppercase validation rule.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sch_employees_profile` | Consumer | Employee state code used to select applicable slab |
| `pay_payroll_run_details` | Consumer | PT amount looked up during payroll computation |
| `hrs_compliance_records` | Consumer | Stores employee state code for PT compliance |
| Activity Log | Consumer | `activityLog()` on CRUD |

**Table:** `hrs_pt_slabs`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| state_code | VARCHAR(5) | NOT NULL |
| min_salary | DECIMAL(10,2) | NOT NULL |
| max_salary | DECIMAL(10,2) | NOT NULL |
| pt_amount | DECIMAL(8,2) | NOT NULL |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |
