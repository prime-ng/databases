# LOP Reconciliation — Business Requirements

## What This Screen Does

The LOP (Loss of Pay) Reconciliation screen lets HR Managers review flagged employee absences and decide whether to confirm them as LOP (which will be deducted from salary in payroll computation) or waive them (ignore the absence). Absences are flagged automatically by the attendance system (when the Attendance module is integrated) or can be recorded manually. The screen shows a table of flagged records with employee name, absent date, and payroll month, along with summary counts of confirmed and waived records.

## When This Screen Is Used

- **Monthly payroll processing** when the HR Manager reviews all unexcused absences before payroll computation
- **Dispute resolution** when an employee contests a recorded absence and the HR Manager decides to waive it
- **Attendance reconciliation** after the attendance data is imported and unmatched absences are flagged

## Default Data Load

The screen loads via `GET /lop-reconciliation` (`hr-staff.lop.index`) handled by `LopController::index()` at lines 24–38, gated by `hrs.lop.confirm`. It queries `LopRecord::with(['employee'])->active()->flagged()` ordered by `absent_date`, paginated at 50 per page. It also loads `confirmedCount` (records with `flag_status = confirmed`) and `waivedCount` (records with `flag_status = waived`). On the Leave Management tabbed page, the tab parameter is `?tab=lop-reconciliation`. The menu controller (`HrMenuController::leaveManagement()`) loads flagged records at 20 per page with `lop_page` pagination parameter.

## Key Fields at a Glance

**Employee** — The absent employee, loaded from `sch_employees` via the `employee` relationship.

**Absent Date** — `absent_date` is the calendar date on which the employee was absent without approved leave.

**Flag Status** — The LOP lifecycle status: `flagged` (initial, pending review), `confirmed` (HR Manager accepted as LOP), or `waived` (HR Manager excused the absence).

**Payroll Month** — `payroll_month` (YYYY-MM format) indicates which payroll run will incorporate this LOP for deduction.

**Confirmed By** — The employee (HR Manager) who confirmed or waived the record, recorded at action time.

**Confirmed At** — Timestamp when the confirmation or waiver action was taken.

## Business Rules and Conditions

**LOP Status FSM** — `flagged` → `confirmed` or `flagged` → `waived`. There is no reverse transition (confirmed → flagged or waived → flagged). Once confirmed, the record is consumed by the payroll computation engine.

**Bulk Action** — The `confirm()` action accepts an array of LOP record IDs (`lop_ids`) and a single `action` value (`confirmed` or `waived`). All selected records must be in `flagged` status (the `update()` query includes `where('flag_status', 'flagged')`).

**Unique Constraint Per Employee Per Date** — The unique key `uq_hrs_lop` on `(employee_id, absent_date)` prevents duplicate LOP records for the same employee and date.

**Optional Payroll Month** — The `payroll_month` field is nullable and is typically set when the LOP record is consumed by payroll computation (`PayrollComputationService`).

## Workflow Steps

1. The HR Manager opens Leave Management > LOP Reconciliation tab
2. The grid shows all `flagged` LOP records with checkboxes for batch selection
3. Summary counts show how many records have been `confirmed` and `waived` to date
4. The HR Manager selects one or more records and chooses "Confirm as LOP" or "Waive"
5. The system updates the selected records' `flag_status`, recording `confirmed_by` (employee ID), `confirmed_at` (timestamp), and `updated_by`
6. The flagged records disappear from the grid (since they no longer match the `flagged` filter)
7. The summary counts update to reflect the new totals

## Example Scenario

April payroll is being processed. The system flagged 12 absences from the attendance module for the month of March. The HR Manager reviews them: 10 are genuine unexcused absences (confirmed as LOP), 2 are disputed by employees (waived). The HR Manager selects the 10 records, clicks "Confirm as LOP". The records' `flag_status` changes to `confirmed`. The flash message reads "10 LOP records confirmed successfully."

## Related Screens

- **Payroll Runs** — Consumes confirmed LOP records during payroll computation for LWP deduction
- **Leave Applications** — Approved leave covers the absence; LOP is only for unexcused absences

## Requirements

- `LopController::index()` (line 24) gates with `hrs.lop.confirm`, loads flagged records with employee relation, paginates at 50; also loads confirmed and waived counts
- `LopController::confirm()` (line 43) gates with `hrs.lop.confirm`, validates via `ConfirmLopRequest`, delegates to `LeaveService::confirmLopRecords()`
- `ConfirmLopRequest` validates: `lop_ids` (required|array|min:1), `lop_ids.*` (required|integer|exists:hrs_lop_records,id), `action` (required|in:confirmed,waived)
- `LeaveService::confirmLopRecords()` validates the action is `confirmed` or `waived`, then updates matching records where `flag_status = flagged` with the new status, `confirmed_by`, `confirmed_at`, and `updated_by`
- `LeaveService::confirmLopRecords()` returns the count of affected rows
- `LeaveService::flagLopRecords()` (line 345) is a bulk upsert method using `updateOrCreate` keyed on `(employee_id, absent_date)`, setting `flag_status = flagged` and optional `payroll_month`
- Activity is logged on confirm/waive with type "LOP Confirmed" or "LOP Waived", recording IDs and count
- On the menu page, flagged records are paginated at 20 per page using `lop_page` parameter
- `LopRecord` model has `SoftDeletes`, `$casts` for `absent_date` (date), `confirmed_at` (datetime), `is_active` (boolean); scopes: `active()`, `flagged()`, `confirmed()`, `forMonth()`
- Routes: `hr-staff.lop.index` (GET), `hr-staff.lop.confirm` (POST)

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.lop.confirm` | `index()`, `confirm()` | HR Manager role |

## How This Screen Works — Logic Flow

**Page Load:** `LopController::index()` gates with `hrs.lop.confirm`, loads `LopRecord::with('employee')->active()->flagged()` ordered by `absent_date`, paginated 50. Also counts `confirmed()` and `where('flag_status', 'waived')` for summary.

**Bulk Confirm/Waive:** `LopController::confirm()` validates via `ConfirmLopRequest`. `LeaveService::confirmLopRecords()` calls `LopRecord::whereIn('id', $lopIds)->where('flag_status', 'flagged')->update([...])`. The update sets `flag_status`, `confirmed_by` (from auth user's employee ID), `confirmed_at` (now), and `updated_by`. Returns count. Activity logged. Redirects to LOP index with success flash.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `lop_ids` | `required\|array\|min:1` | — |
| `lop_ids.*` | `required\|integer\|exists:hrs_lop_records,id` | — |
| `action` | `required\|in:confirmed,waived` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Validation failure | Standard Laravel validation errors | Validation rule |
| Invalid action | "Invalid LOP action: {action}" | `InvalidArgumentException` |
| Success (confirm) | "{count} LOP records confirmed successfully." | Flash success |
| Success (waive) | "{count} LOP records waived successfully." | Flash success |

## Success Scenarios

**SC-001 — Confirm flagged LOP records** — HR Manager selects 5 flagged records and confirms as LOP. System updates 5 records to `confirmed`. Flash: "5 LOP records confirmed successfully."

**SC-002 — Waive flagged LOP records** — HR Manager selects 3 flagged records and waives. System updates to `waived`. Flash: "3 LOP records waived successfully."

**SC-003 — View LOP dashboard** — HR Manager opens the LOP tab. Grid shows all flagged records. Summary counts show 12 confirmed, 8 waived.

## Failure Scenarios

**FC-001 — Empty selection** — HR Manager submits without selecting any records. Validation fails: "The lop ids field is required."

**FC-002 — Invalid action value** — HR Manager submits action as "delete". Validation fails: "The selected action is invalid."

**FC-003 — Attempt to re-confirm** — HR Manager selects records already confirmed. The `where('flag_status', 'flagged')` clause prevents updates; affected count is 0.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `Employee` | FK parent | `employee_id` → `sch_employees.id` (CASCADE); `confirmed_by` → `sch_employees.id` (CASCADE) |
| `PayrollRunDetail` | Consumer | Reads `hrs_lop_records` for LWP computation |
| `LeaveService` | Service | `flagLopRecords()`, `confirmLopRecords()` |

**Table:** `hrs_lop_records`

| Column | Type | Details |
|--------|------|---------|
| `id` | BIGINT UNSIGNED | PK, Auto Increment |
| `employee_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (CASCADE) |
| `absent_date` | DATE | NOT NULL |
| `flag_status` | ENUM('flagged','confirmed','waived') | NOT NULL, DEFAULT 'flagged' |
| `confirmed_by` | INT UNSIGNED | NULL, FK → `sch_employees.id` (CASCADE) |
| `confirmed_at` | TIMESTAMP | NULL |
| `payroll_month` | VARCHAR(7) | NULL, YYYY-MM |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | BIGINT UNSIGNED | NOT NULL |
| `updated_by` | BIGINT UNSIGNED | NOT NULL |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| UNIQUE KEY `uq_hrs_lop` | (`employee_id`, `absent_date`) | |
