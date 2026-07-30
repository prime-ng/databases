# Leave Balances — Business Requirements

## What This Screen Does

The Leave Balances screen displays each employee's leave balance as a matrix of employees (rows) versus leave types (columns). It shows allocated days, carry-forward days, used days, and available days for each combination. An HR Manager can initialize balances for an academic year, optionally carrying forward unused leave from the prior year, and can reset balances when needed.

## When This Screen Is Used

- **Academic year start** when the HR Manager initialises leave balances for all active employees
- **Mid-year monitoring** when checking how many leave days an employee has used or has remaining
- **Carry-forward calculation** at year-end to confirm how many days transfer to the next year
- **Reset scenario** if initialisation produced incorrect data and needs to be re-done

## Default Data Load

The screen loads via `GET /leave-balances` (`hr-staff.balances.index`) handled by `LeaveController::balances()` at lines 90–105, gated by `hrs.leave.balance.view`. It queries `LeaveBalance::with(['employee', 'leaveType'])->active()` filtered by the current academic year, ordered by `employee_id`, paginated at 50 per page. The academic year dropdown and the full list of academic sessions also load. On the Leave Management tabbed page, the tab parameter is `?tab=leave-balances`. The menu controller (`HrMenuController::leaveManagement()`) additionally loads grouped balances at 60 per page with a `balances_page` pagination parameter and supports `search` and `balance_year` filters.

## Key Fields at a Glance

**Employee** — The employee's full name and identity, loaded from the `sch_employees` table via the `employee` relationship.

**Leave Type** — The type of leave (e.g., Casual Leave, Earned Leave, Sick Leave), loaded via the `leaveType` relationship from `hrs_leave_types`.

**Allocated Days** — `allocated_days` is the number of leave days the employee is entitled to for this leave type in the current year, initialised from `leave_type.days_per_year`.

**Carry-Forward Days** — `carry_forward_days` are days brought over from the prior academic year, capped at the leave type's `carry_forward_days` limit.

**Used Days** — `used_days` tracks the number of days consumed via approved leave applications.

**Available Days** — A computed accessor (`available_days`) equals `allocated_days + carry_forward_days - used_days`. This is the number of days the employee can still apply for.

**LOP Days** — `lop_days` tracks Loss of Pay days accrued during the academic year.

## Business Rules and Conditions

**Idempotent Initialisation** — Calling initialise multiple times for the same academic year without the reset flag is blocked if any leave applications or adjustments exist for that year. If no activity exists, it updates only `allocated_days` and `carry_forward_days`, preserving `used_days` and `lop_days`.

**Carry-Forward Capping** — Carry-forward days are computed as `min(max(prior_remaining, 0), leave_type.carry_forward_days)`. The remaining days from the prior year are `prior_allocated + prior_carry_forward - prior_used`. This effectively caps carry-forward at the leave type's configured maximum.

**Reset Behaviour** — Setting `reset=true` force-deletes (`forceDelete`) all existing balance records for the academic year and creates fresh ones. This is audited in the activity log with "LeaveBalanceReset" context.

**Balance Not Created for Inactive Employees** — Only employees with `is_active = true` in `sch_employees` receive balance records.

**One Row Per Employee per Leave Type per Year** — The unique key `uq_hrs_leave_bal` on `(employee_id, leave_type_id, academic_year_id)` prevents duplicate entries.

## Workflow Steps

1. The HR Manager opens Leave Management > Leave Balances tab
2. The grid shows all employees with their balance columns per leave type, grouped by employee
3. The HR Manager selects an academic year from the filter to view balances for a different year
4. To initialise balances, the HR Manager clicks "Initialize Balances", selects the target year, optionally selects a prior year for carry-forward, and optionally checks the reset box
5. The system creates or updates balance records for every employee-leave-type combination
6. A success flash message shows the count of records processed

## Example Scenario

The school starts the 2025-26 academic year. The HR Manager opens the Leave Balances tab and clicks "Initialize Balances". They select "2025-26" as the target year and "2024-25" as the prior year for carry-forward. The system creates 7 balance records per employee (one per active leave type), computing carry-forward from the prior year's remaining days. The flash message reads "196 leave balance records initialized."

## Related Screens

- **Leave Policy** — Defines approval levels and global leave rules that complement balance tracking
- **Leave Balance Adjustments** — Manual adjustments to individual employee balances (HR Managers only), listed under HR Masters
- **Leave Applications** — When approved, decrements the employee's balance via `used_days`

## Requirements

- `LeaveController::balances()` (line 90) gates with `hrs.leave.balance.view`, loads active balances filtered by current academic year, paginates at 50; renders `hrstaff::leave.balances`
- `LeaveController::initializeBalances()` (line 66) gates with `hrs.employment.manage`, validates via `InitializeLeaveBalancesRequest`, delegates to `LeaveService::initializeBalances()`
- `InitializeLeaveBalancesRequest` validates: `academic_year_id` (required|exists), `prior_academic_year_id` (nullable|exists), `reset` (sometimes|boolean)
- `prepareForValidation()` casts `reset` to boolean with default false
- `LeaveService::initializeBalances()` runs in a DB transaction; on `reset=true`, force-deletes existing records with an audit log; then iterates all active employees × active leave types, computing carry-forward from prior year
- `LeaveService::initializeBalances()` returns the count of balance records processed
- Activity log is recorded with type `Initialized` or `Reset` and includes the academic year ID and record count
- The `balances()` method supports `search` on employee name and `balance_year` filter for academic year
- `LeaveController::trashedBalances()` (line 110) and `restoreBalance()` (line 125) handle soft-delete flow
- `LeaveBalance` model has `SoftDeletes`, `$casts` for decimal fields, and an `available_days` accessor
- Route names: `hr-staff.balances.index` (GET), `hr-staff.balances.initialize` (POST), `hr-staff.balances.trashed` (GET), `hr-staff.balances.restore` (GET)
- On the menu page, balances are paginated at 60 per page using `balances_page` parameter
- `LeaveBalancePolicy` has `viewAny`, `manage`, and `initialize` methods

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.leave.balance.view` | `balances()`, `trashedBalances()`, `restoreBalance()` | View balances, trash, and restore |
| `hrs.employment.manage` | `initializeBalances()` | Initialise and reset balances |
| `LeaveBalancePolicy` | All balance methods | Policy class: `LeaveBalancePolicy` |

## How This Screen Works — Logic Flow

**Page Load (standalone route):** `LeaveController::balances()` gates with `hrs.leave.balance.view`, loads active balances for the current academic year with employee and leave type relations, paginates at 50, returns the balances view.

**Page Load (menu page):** `HrMenuController::leaveManagement()` loads balances with employee+leaveType relations, optionally filtered by `balance_year` and `search` (employee name). Results are paginated at 60 per page with `balances_page` parameter. Results are grouped by `employee_id` for the matrix display.

**Initialize:** `LeaveController::initializeBalances()` validates via `InitializeLeaveBalancesRequest`, calls `LeaveService::initializeBalances()`. The service runs in a transaction: if `reset=true`, force-deletes existing records and logs the action. For each active employee × active leave type, it computes carry-forward from the prior year balance (if provided and the leave type supports carry-forward). Uses `firstOrNew` to find or create the balance record, preserving `used_days` and `lop_days` on non-reset re-initialization.

**Carry-Forward Formula:** `remaining = prior_allocated + prior_carry_forward - prior_used`; `carryForward = min(max(remaining, 0), type.carry_forward_days)`.

**Trash/Restore:** Standard soft-delete pattern via `LeaveController::trashedBalances()` and `restoreBalance()`. Restore sets `is_active = true`.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `academic_year_id` | `required\|exists:sch_org_academic_sessions_jnt,id` | — |
| `prior_academic_year_id` | `nullable\|exists:sch_org_academic_sessions_jnt,id` | — |
| `reset` | `sometimes\|boolean` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Validation failure | Standard Laravel validation errors | Validation rule |
| Re-initialisation blocked (has activity) | "Cannot re-initialize leave balances for a year that already has leave applications or adjustments. Use reset if required." | `DomainException` (caught by Laravel's exception handler, may surface as 500) |
| Success (initialize) | "{count} leave balance records initialized." | Flash success |
| Success (reset) | "{count} leave balance records reset." | Flash success |
| Success (restore) | "Leave balance restored successfully." | Flash success |
| Not found (trashed) | 404 via `findOrFail` | HTTP 404 |

## Success Scenarios

**SC-001 — Initialize balances for new year** — HR Manager selects academic year 2025-26 with prior year 2024-25. The system creates records for all 50 active employees × 6 active leave types = 300 records. Carry-forward is computed for leave types with `carry_forward_days > 0`. Flash: "300 leave balance records initialized."

**SC-002 — View balances with year filter** — HR Manager changes the year filter to 2024-25. The grid reloads showing balances for that academic year only.

## Failure Scenarios

**FC-001 — Re-initialize with existing activity** — HR Manager tries to initialize 2025-26 again, but employees have already submitted leave applications for that year. The system throws a `DomainException` with message about existing activity.

**FC-002 — Invalid academic year** — HR Manager selects an academic year ID that does not exist. Validation fails with "The selected academic year is invalid."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `OrganizationAcademicSession` | FK parent | `academic_year_id` → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `Employee` | FK parent | `employee_id` → `sch_employees.id` (CASCADE) |
| `LeaveType` | FK parent | `leave_type_id` → `hrs_leave_types.id` (RESTRICT) |
| `LeaveApplication` | Child consumer | Balance check in `LeaveService::applyLeave()` reads `available_days` |
| `LeaveBalanceAdjustment` | Child table | `adjustments()` hasMany; FK `hrs_leave_balance_adjustments.leave_balance_id` |
| `LeaveService` | Service | `initializeBalances()`, `adjustBalance()`, `applyLeave()` read/write balances |

**Table:** `hrs_leave_balances`

| Column | Type | Details |
|--------|------|---------|
| `id` | BIGINT UNSIGNED | PK, Auto Increment |
| `employee_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (CASCADE) |
| `leave_type_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_types.id` (RESTRICT) |
| `academic_year_id` | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `allocated_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| `carry_forward_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| `used_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| `lop_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `updated_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| UNIQUE KEY `uq_hrs_leave_bal` | (`employee_id`, `leave_type_id`, `academic_year_id`) | Prevents duplicate balance records |
