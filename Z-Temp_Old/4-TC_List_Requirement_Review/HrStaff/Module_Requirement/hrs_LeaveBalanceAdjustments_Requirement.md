# Leave Balance Adjustments — Business Requirements

## What This Screen Does

The Leave Balance Adjustments screen allows HR Managers to manually add or deduct leave days from an employee's balance. Unlike the bulk initialisation process (which sets all balances at once for a new academic year), this is a targeted CRUD feature for correcting or adjusting individual employee balances. Each adjustment creates an audit trail recording the reason, the adjusted-by employee, and the number of days changed.

## When This Screen Is Used

- **Balance correction** when an employee was incorrectly allocated too few or too many days
- **Ad-hoc grant** when an employee needs extra leave days beyond their standard allocation (e.g., special circumstances)
- **Leave recovery** when leave days need to be clawed back due to policy violation or error
- **Audit investigation** when tracing the history of changes to a specific employee's balance

## Default Data Load

The screen is listed under HR Masters tab `?tab=leave-balance-adjustments`. The `LeaveBalanceAdjustmentController::index()` (line 23) redirects to `hr-staff.menu.hrMasters?tab=leave-balance-adjustments`. The menu controller `HrMenuController::hrMasters()` loads all adjustments via `LeaveBalanceAdjustment::with(['leaveBalance.employee', 'leaveBalance.leaveType', 'adjustedByEmployee'])` ordered by `created_at` desc. On the HR Masters page, a search field filters adjustments by the employee name (via `leaveBalance.employee.user.name`). There is no pagination on the menu page — all records are loaded.

## Key Fields at a Glance

**Employee** — The employee whose leave balance is being adjusted, accessed through the `leaveBalance.employee` relationship chain.

**Leave Type** — The type of leave being adjusted, accessed through `leaveBalance.leaveType`.

**Current Balance** — Shows the employee's current `allocated_days`, `carry_forward_days`, `used_days`, and `available_days` for the selected leave balance record.

**Adjustment Days** — `adjustment_days` is the number of days to add (positive) or deduct (negative). The value directly modifies `allocated_days` on the `LeaveBalance` record via `adjustBalance()` in `LeaveService`.

**Reason** — A mandatory text explanation for the adjustment. This is audited in the `hrs_leave_balance_adjustments` table.

**Adjusted By** — The HR Manager who performed the adjustment, recorded as the `adjusted_by` FK to `sch_employees.id`.

## Business Rules and Conditions

**Direct Allocation Modification** — When an adjustment is created through `LeaveService::adjustBalance()`, the `allocated_days` on the balance record is updated by adding `adjustment_days`. The result is floored at zero (`max(0, ...)`).

**Positive Adds Days, Negative Deducts** — A positive `adjustment_days` increases the employee's available days; a negative value decreases them.

**Adjustment Causes Side Effect** — Creating an adjustment record via `LeaveBalanceAdjustmentController::store()` does NOT call `LeaveService::adjustBalance()`. It simply inserts a row in `hrs_leave_balance_adjustments`. The balance adjustment on `allocated_days` must be done separately through the `adjustBalance()` service method (which the standalone CRUD controller's `store()` does not invoke).

## Workflow Steps

1. The HR Manager navigates to HR Masters > Leave Balance Adjustments tab
2. The grid lists all existing adjustments with employee name, leave type, days, reason, and adjusted-by
3. The HR Manager clicks "Add Adjustment" to open a modal or inline form
4. The HR Manager selects the employee and leave type (which auto-selects a balance record), enters the adjustment days (positive or negative), provides a reason, and selects who is performing the adjustment
5. The form validates and saves a new `LeaveBalanceAdjustment` record
6. The grid refreshes showing the new adjustment at the top

## Example Scenario

Employee Rahul Sharma (Employee ID 42) was allocated 12 Casual Leave days due to a data entry error — he should have 15. The HR Manager opens the Leave Balance Adjustments tab, clicks "Add Adjustment", selects Rahul's Casual Leave balance record, enters `+3` adjustment days, provides the reason "Corrected allocation error per HR approval #1234", selects the HR Manager as the adjuster, and saves. The adjustment record appears in the grid.

## Related Screens

- **Leave Balances** — The parent balance record that adjustments reference; available through the `leaveBalance` relationship
- **Leave Types** — Defines the leave type configuration referenced by the balance

## Requirements

- `LeaveBalanceAdjustmentController` is a full CRUD resource registered via `Route::resource('leave-balance-adjustments', LeaveBalanceAdjustmentController::class)->except(['create'])`
- Custom routes: `toggle-status` (POST), `trashed` (GET), `restore` (GET), `force-delete` (DELETE)
- `index()` redirects to `hr-staff.menu.hrMasters?tab=leave-balance-adjustments`
- `store()` gates with `hrs.leave_type.manage`, validates via `StoreLeaveBalanceAdjustmentRequest`, sets `created_by` and `updated_by` to `auth()->id()`
- `StoreLeaveBalanceAdjustmentRequest` validates: `leave_balance_id` (required|exists), `adjustment_days` (required|numeric), `reason` (nullable|string|max:500), `adjusted_by` (required|exists), `is_active` (required|boolean)
- `prepareForValidation()` casts `is_active` to boolean with default true
- `show()` loads with `leaveBalance.employee`, `leaveBalance.leaveType`, `adjustedByEmployee`
- `edit()` loads the adjustment with leave balance data plus all active `LeaveBalance` and `Employee` records for form dropdowns
- `update()` uses the same `StoreLeaveBalanceAdjustmentRequest` and merges `updated_by`
- `toggleStatus()` toggles `is_active` and returns JSON `{success, is_active, message}`
- `destroy()` sets `is_active = false`, soft-deletes, logs activity
- `trashed()` lists soft-deleted records at 15 per page
- `restore()` undoes soft-delete and sets `is_active = true`
- `forceDelete()` permanently deletes
- Activity logged for Created, Updated, Trashed, Restored, and Deleted actions
- Model has `SoftDeletes`, `$casts` for `adjustment_days` (decimal:1) and `is_active` (boolean)
- Menu controller loads adjustments with employee+leaveType+adjustedBy relationships, ordered by `created_at` desc, with search on employee user name

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.leave_type.manage` | `store()`, `show()`, `edit()`, `update()`, `toggleStatus()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()` | Full CRUD access |

## How This Screen Works — Logic Flow

**Page Load:** `HrMenuController::hrMasters()` loads all adjustments with eager-loaded relationships, ordered by `created_at` desc. The search filter queries `leaveBalance.employee.user.name LIKE %search%`. All records are loaded (no pagination on menu page).

**Create:** `LeaveBalanceAdjustmentController::store()` validates via `StoreLeaveBalanceAdjustmentRequest`, creates the record with `created_by` and `updated_by`, logs activity, and redirects with success message.

**Edit/Update:** `edit()` loads the adjustment plus the full lists of `LeaveBalance` and `Employee` for dropdown options. `update()` re-validates and updates the record with `updated_by`.

**Toggle Status:** `toggleStatus()` flips `is_active` and returns a JSON response.

**Soft Delete:** `destroy()` sets `is_active = false`, soft-deletes, logs activity, redirects with success.

**Trash/Restore/Force Delete:** Follows the standard pattern used across all HrStaff CRUD controllers.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `leave_balance_id` | `required\|exists:hrs_leave_balances,id` | — |
| `adjustment_days` | `required\|numeric` | — |
| `reason` | `nullable\|string\|max:500` | — |
| `adjusted_by` | `required\|exists:sch_employees,id` | — |
| `is_active` | `required\|boolean` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Validation failure | Standard Laravel validation errors | Validation rule |
| Success (create) | "Leave balance adjustment created successfully." | Flash success |
| Success (update) | "Leave balance adjustment updated successfully." | Flash success |
| Success (toggle) | JSON: `{success: true, is_active: true/false, message: "Status updated successfully."}` | JSON response |
| Success (delete) | "Leave balance adjustment removed successfully." | Flash success |
| Success (restore) | "Leave balance adjustment restored successfully." | Flash success |
| Success (force-delete) | "Leave balance adjustment permanently deleted." | Flash success |
| Not found | 404 via implicit model binding or `findOrFail` | HTTP 404 |

## Success Scenarios

**SC-001 — Create adjustment** — HR Manager adds +3 days to employee's Casual Leave balance with reason "Manual correction per approval." The system creates the adjustment record and redirects with success.

**SC-002 — Toggle status** — HR Manager toggles an adjustment record to inactive. The system flips `is_active` and returns JSON success.

**SC-003 — View adjustment detail** — HR Manager clicks an adjustment row. The show page displays the employee, leave type, days, reason, adjusted-by, and timestamps.

## Failure Scenarios

**FC-001 — Invalid leave balance** — HR Manager selects a non-existent `leave_balance_id`. Validation fails with "The selected leave balance is invalid."

**FC-002 — Non-numeric adjustment** — HR Manager enters text for adjustment days. Validation fails because `numeric` rule is enforced.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `LeaveBalance` | FK parent | `leave_balance_id` → `hrs_leave_balances.id` (RESTRICT) |
| `Employee` | FK parent | `adjusted_by` → `sch_employees.id` (RESTRICT) |
| `LeaveService::adjustBalance()` | Service | Reads/writes `hrs_leave_balances.allocated_days` and creates adjustment record |

**Table:** `hrs_leave_balance_adjustments`

| Column | Type | Details |
|--------|------|---------|
| `id` | BIGINT UNSIGNED | PK, Auto Increment |
| `leave_balance_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_balances.id` (RESTRICT) |
| `adjustment_days` | DECIMAL(5,1) | NOT NULL; Positive = add, Negative = deduct |
| `reason` | TEXT | NOT NULL |
| `adjusted_by` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (RESTRICT) |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `updated_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL (Soft delete) |
