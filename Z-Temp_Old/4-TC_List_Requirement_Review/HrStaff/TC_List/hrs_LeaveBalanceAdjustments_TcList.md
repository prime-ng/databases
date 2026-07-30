# hrs_LeaveBalanceAdjustments_TcList

## Module: HrStaff → HR Masters → Leave Balance Adjustments

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | HrStaff / HR Masters / Leave Balance Adjustments |
| URL(s) | `GET /leave-balance-adjustments` (`hr-staff.leave-balance-adjustments.index`), `POST /leave-balance-adjustments` (`hr-staff.leave-balance-adjustments.store`), `GET /leave-balance-adjustments/{adjustment}` (`hr-staff.leave-balance-adjustments.show`), `GET /leave-balance-adjustments/{adjustment}/edit` (`hr-staff.leave-balance-adjustments.edit`), `PUT /leave-balance-adjustments/{adjustment}` (`hr-staff.leave-balance-adjustments.update`), `DELETE /leave-balance-adjustments/{adjustment}` (`hr-staff.leave-balance-adjustments.destroy`), `POST /leave-balance-adjustments/{adjustment}/toggle-status` (`hr-staff.leave-balance-adjustments.toggle-status`), `GET /leave-balance-adjustments/trash/view` (`hr-staff.leave-balance-adjustments.trashed`), `GET /leave-balance-adjustments/{id}/restore` (`hr-staff.leave-balance-adjustments.restore`), `DELETE /leave-balance-adjustments/{id}/force-delete` (`hr-staff.leave-balance-adjustments.forceDelete`) |
| Controller | `Modules\HrStaff\Http\Controllers\LeaveBalanceAdjustmentController` (all methods) |
| Model(s) | `Modules\HrStaff\Models\LeaveBalanceAdjustment` (table: `hrs_leave_balance_adjustments`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreLeaveBalanceAdjustmentRequest` |
| Policy | None — direct `Gate::authorize('hrs.leave_type.manage')` in controller |
| Permissions | `hrs.leave_type.manage`, `hrs.leave_balance_adjustment.manage` (in request) |
| Pagination | 15 per page on trashed view; no pagination on main menu listing |
| Soft Deletes | Yes — `SoftDeletes` trait on model |
| Read-Only | No — full CRUD |

## 2. Pre-conditions

- User must be logged in with `hrs.leave_type.manage` permission
- Leave balance records must exist in `hrs_leave_balances` (employees, leave types, academic years)
- Employees must exist in `sch_employees` (for the `adjusted_by` field)
- Dusk env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

## 3. Default Data Load

The `index()` method redirects to `hr-staff.menu.hrMasters?tab=leave-balance-adjustments`. The menu controller loads all adjustments with `leaveBalance.employee`, `leaveBalance.leaveType`, and `adjustedByEmployee` relationships, ordered by `created_at` desc, with search on employee user name.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Adjustments grid | `HrMenuController::hrMasters()` | `LeaveBalanceAdjustment::with([leaveBalance.employee, leaveBalance.leaveType, adjustedByEmployee])->orderByDesc('created_at')` | search (employee name) | None |
| Leave Balances (form) | `LeaveBalanceAdjustmentController::edit()` | `LeaveBalance::active()->with([employee.user, leaveType])->orderBy('id')` | is_active | None |
| Employees (form) | `LeaveBalanceAdjustmentController::edit()` | `Employee::active()->orderBy('first_name')` | is_active | None |

## 4. Test Data Strategy

- Create 2 leave balance records (different employees and leave types) as targets for adjustments
- Use adjustment_days values: +5 (add), -2 (deduct), +1.5 (decimal), -0.5 (fractional)
- Pre-test cleanup: truncate `hrs_leave_balance_adjustments`
- For pagination, force-delete records so trash view can test 15/page limit

## 5. Business Conditions

### 5.1 Database Schema — `hrs_leave_balance_adjustments`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | `leave_balance_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_balances.id` (RESTRICT) |
| BC-DB-03 | `adjustment_days` | DECIMAL(5,1) | NOT NULL |
| BC-DB-04 | `reason` | TEXT | NOT NULL |
| BC-DB-05 | `adjusted_by` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (RESTRICT) |
| BC-DB-06 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-07 | `created_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | `updated_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-09 | `created_at` | TIMESTAMP | NULL |
| BC-DB-10 | `updated_at` | TIMESTAMP | NULL |
| BC-DB-11 | `deleted_at` | TIMESTAMP | NULL (Soft delete) |

### 5.2 Validation Rules — `StoreLeaveBalanceAdjustmentRequest` (Create / Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `leave_balance_id` | `required\|exists:hrs_leave_balances,id` | — |
| BC-VAL-02 | `adjustment_days` | `required\|numeric` | — |
| BC-VAL-03 | `reason` | `nullable\|string\|max:500` | — |
| BC-VAL-04 | `adjusted_by` | `required\|exists:sch_employees,id` | — |
| BC-VAL-05 | `is_active` | `required\|boolean` | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `hrs.leave_type.manage` | All CRUD operations allowed |
| BC-AUTH-02 | `hrs.leave_balance_adjustment.manage` | Form request authorize allows |
| BC-AUTH-03 | No permission | Any endpoint → 403 |
| BC-AUTH-04 | Guest | Redirect to `/login` |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default page load (tab) | Grid lists all adjustments with employee, leave type, days, reason, adjusted by |
| BC-BIZ-02 | Create adjustment with positive days | Record created; grid shows new entry at top |
| BC-BIZ-03 | Create adjustment with negative days | Record created with negative value |
| BC-BIZ-04 | Create adjustment with decimal days | Record created with fractional value (e.g., 1.5) |
| BC-BIZ-05 | Search by employee name | Grid filtered to matching employees |
| BC-BIZ-06 | View adjustment detail | Shows employee, leave type, days, reason, adjusted by, timestamps |
| BC-BIZ-07 | Edit adjustment | Form pre-filled; update saves changes |
| BC-BIZ-08 | Toggle status active/inactive | `is_active` flipped; JSON response returned |
| BC-BIZ-09 | Soft-delete adjustment | `is_active=false`; record moved to trash |
| BC-BIZ-10 | View trash | Soft-deleted records listed at 15/page |
| BC-BIZ-11 | Restore from trash | Record restored with `is_active=true` |
| BC-BIZ-12 | Force-delete from trash | Record permanently removed |
| BC-BIZ-13 | Empty state (no adjustments) | Grid shows no records |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `leave_balance_id` | `hrs_leave_balances` | RESTRICT |
| BC-REF-02 | `adjusted_by` | `sch_employees` | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Leave Balance Adjustments tab | Grid lists all adjustments with correct columns | — | — | ⬜ |
| TC-P02 | Create adjustment (+5 days) | Record created; flash success | — | — | ⬜ |
| TC-P03 | Create adjustment (-2 days, deduction) | Record created with negative value | — | — | ⬜ |
| TC-P04 | Create adjustment with decimal (1.5 days) | Record created with fractional value | — | — | ⬜ |
| TC-P05 | Search for employee name | Grid filtered to matching employees | — | — | ⬜ |
| TC-P06 | View adjustment detail | Show page with all fields displayed | — | — | ⬜ |
| TC-P07 | Edit adjustment and update | Changes saved; flash success | — | — | ⬜ |
| TC-P08 | Toggle status to inactive | JSON success; is_active=false | — | — | ⬜ |
| TC-P09 | Toggle status back to active | JSON success; is_active=true | — | — | ⬜ |
| TC-P10 | Soft-delete adjustment | is_active=false; removed from main grid | — | — | ⬜ |
| TC-P11 | View trash list | Soft-deleted records listed | — | — | ⬜ |
| TC-P12 | Restore from trash | Record back in main grid with is_active=true | — | — | ⬜ |
| TC-P13 | Force-delete from trash | Record permanently deleted | — | — | ⬜ |
| TC-P14 | Empty state (no adjustments) | Grid shows empty/no records message | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create with invalid `leave_balance_id` | Validation error | — | — | ⬜ |
| TC-N02 | Create with non-numeric `adjustment_days` | Validation error | — | — | ⬜ |
| TC-N03 | Create without `adjusted_by` | Validation error | — | — | ⬜ |
| TC-N04 | Create with missing `leave_balance_id` | Validation error | — | — | ⬜ |
| TC-N05 | Create with reason > 500 chars | Validation error | — | — | ⬜ |
| TC-N06 | Access page without `hrs.leave_type.manage` | 403 Forbidden | — | — | ⬜ |
| TC-N07 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N08 | View non-existent adjustment | 404 Not Found | — | — | ⬜ |
| TC-N09 | Update non-existent adjustment | 404 Not Found | — | — | ⬜ |
| TC-N10 | Delete already-deleted adjustment | 404 Not Found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Model `$fillable` matches DDL columns | All columns in fillable array | — | — | ⬜ |
| TC-D02 | A | Model `$casts` — decimal/boolean | `adjustment_days` decimal:1; `is_active` boolean | — | — | ⬜ |
| TC-D03 | A | Model uses `SoftDeletes` | Trait present; DDL has `deleted_at` | — | — | ⬜ |
| TC-D04 | A | Model relationships | `leaveBalance()` belongsTo; `adjustedByEmployee()` belongsTo | — | — | ⬜ |
| TC-D05 | B | FK RESTRICT — cannot delete leave balance with adjustments | Deleting `hrs_leave_balances` record referenced by adjustment fails | — | — | ⬜ |
| TC-D06 | C | Controller gate on every method | All public methods call `Gate::authorize('hrs.leave_type.manage')` | — | — | ⬜ |
| TC-D07 | C | Activity logged on create/update/delete | `activityLog()` called for each state change | — | — | ⬜ |
| TC-D08 | C | ToggleStatus returns JSON | JSON response with `success`, `is_active`, `message` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model `$fillable` matches DDL columns | Mass-assignment protection covers all columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` | Decimal and boolean casts correctly defined | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` | Trait present; DDL has `deleted_at` column | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships | `leaveBalance()` and `adjustedByEmployee()` defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `Gate::authorize()` on every method | All 9 public methods have gate check | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called in store, update, toggleStatus, destroy, restore, forceDelete | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `is_active=false` before soft delete | `destroy()` sets `is_active=false` then `delete()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — restore sets `is_active=true` | `restore()` calls `update(['is_active' => true])` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — JSON success after toggleStatus | Returns `response()->json([...])` | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — validation rules cover all fields | `StoreLeaveBalanceAdjustmentRequest` has rules for all 5 fields | — | — | ◌ |
| TC-CR11 | CR | P1 | Policy — authorization | Direct Gate check in controller (no policy class needed) | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — resource + custom routes | Resource registered; toggle-status, trash, restore, force-delete custom routes exist | — | — | ◌ |
| TC-CR13 | CR | P1 | View — Blade `@can` directives | Tab/action buttons guarded by `@can('hrs.leave_type.manage')` | — | — | ◌ |
| TC-CR14 | CR | P1 | View — null-safe checks for relationships | `isset($adjustment->leaveBalance)` checks before rendering | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01 through TC-CR14: Code Review
| TC ID | Action | Expected Result |
|-------|--------|-----------------|
| TC-CR01 | Open `LeaveBalanceAdjustment.php` — `$fillable` | Verify `$fillable` matches DDL columns |
| TC-CR02 | Open `LeaveBalanceAdjustment.php` — `$casts` | Verify decimal and boolean casts correctly defined |
| TC-CR03 | Open `LeaveBalanceAdjustment.php` — traits | Verify `SoftDeletes` trait present; DDL has `deleted_at` column |
| TC-CR04 | Open `LeaveBalanceAdjustment.php` — relationships | Verify `leaveBalance()` and `adjustedByEmployee()` defined |
| TC-CR05 | Open `LeaveBalanceAdjustmentController.php` — gates | Verify all 9 methods have `Gate::authorize('hrs.leave_type.manage')` |
| TC-CR06 | Open `LeaveBalanceAdjustmentController.php` — activity | Verify `activityLog()` called in store, update, toggleStatus, destroy, restore, forceDelete |
| TC-CR07 | Open `LeaveBalanceAdjustmentController.php` — delete pattern | Verify `destroy()` sets `is_active=false` before `delete()` |
| TC-CR08 | Open `LeaveBalanceAdjustmentController.php` — restore pattern | Verify `restore()` calls `update(['is_active' => true])` after restore |
| TC-CR09 | Open `LeaveBalanceAdjustmentController.php` — toggleStatus | Verify returns `response()->json([success, is_active, message])` |
| TC-CR10 | Open `StoreLeaveBalanceAdjustmentRequest.php` | Verify rules: leave_balance_id (required|exists), adjustment_days (required|numeric), reason (required|string|min:10|max:500), adjusted_by (required|exists) |
| TC-CR11 | Check authorization | Verify direct Gate check in controller (no separate policy class) |
| TC-CR12 | Open `routes/web.php` | Verify resource registered; toggle-status, trash, restore, force-delete custom routes exist |
| TC-CR13 | Open resource views | Verify `@can('hrs.leave_type.manage')` on tab/action buttons |
| TC-CR14 | Open resource views — null-safe | Verify `isset($adjustment->leaveBalance)` checks before rendering |

### 7.1 Positive TC Steps

#### TC-P01: Load Leave Balance Adjustments tab
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `hrs.leave_type.manage` | — |
| 2 | Navigate to HR Masters > Leave Balance Adjustments tab | Grid displays with columns: Employee, Leave Type, Days, Reason, Adjusted By, Status |

#### TC-P02: Create adjustment (+5 days)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Adjustment" | Form/modal opens |
| 2 | Select leave balance (employee + leave type), enter +5 for days | — |
| 3 | Enter reason "Manual allocation correction" | — |
| 4 | Select adjusted_by (HR Manager) | — |
| 5 | Submit | Flash: "Leave balance adjustment created successfully." |
| 6 | Verify grid shows new entry with +5 days | — |

#### TC-P03: Create adjustment (-2 days)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P02 steps with -2 days | Record created with negative value shown in grid |

#### TC-P04: Create adjustment with decimal (1.5)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create adjustment with 1.5 days | Record created with fractional value displayed correctly |

#### TC-P05: Search by employee name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter employee name in search box | Grid filtered to matching employees only |

#### TC-P06: View adjustment detail
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click on an adjustment row / View button | Show page displays all fields including employee, leave type, days, reason, adjusted by, created_at, updated_at |

#### TC-P07: Edit adjustment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Edit on an adjustment | Form pre-filled with current values |
| 2 | Change days to +10 and reason to "Updated correction" | — |
| 3 | Submit | Flash success; grid shows updated values |

#### TC-P08: Toggle status to inactive
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click toggle-status on an active adjustment | JSON: `{success: true, is_active: false, message: "Status updated successfully."}` |

#### TC-P09: Toggle status back to active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click toggle-status on inactive adjustment | JSON: `{success: true, is_active: true}` |

#### TC-P10: Soft-delete adjustment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Delete on an adjustment | Flash: "Leave balance adjustment removed successfully." |
| 2 | Verify adjustment no longer in main grid | — |

#### TC-P11: View trash list
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | List shows soft-deleted adjustments at 15 per page |

#### TC-P12: Restore from trash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Restore on a trashed adjustment | Flash: "Leave balance adjustment restored successfully." |
| 2 | Return to main tab | Record visible again with is_active=true |

#### TC-P13: Force-delete from trash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash page, click Force Delete | Flash: "Leave balance adjustment permanently deleted." |
| 2 | Verify record no longer in trash or main list | — |

#### TC-P14: Full lifecycle — create → edit → toggle → soft-delete → restore
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an adjustment with +5 days and reason "Test lifecycle" | Success flash |
| 2 | Edit the adjustment, change days to +8 | Update succeeds |
| 3 | Toggle status to inactive | JSON success |
| 4 | Toggle status back to active | JSON success |
| 5 | Soft-delete the adjustment | Removed from grid, flash success |
| 6 | Navigate to trash, restore the adjustment | Record back with is_active=true |

### 7.2 Negative TC Steps

#### TC-N01: Invalid leave_balance_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create adjustment with `leave_balance_id = 99999` | Validation error: "The selected leave balance is invalid." |

#### TC-N02: Non-numeric adjustment_days
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter "abc" for adjustment_days | Validation error: "The adjustment days must be a number." |

#### TC-N03: Empty leave_balance_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit form without selecting leave balance | Validation error: "The leave balance id field is required." |

#### TC-N04: Missing reason
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields except reason | Validation error: "The reason field is required." |

#### TC-N05: Reason too short
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter reason "OK" (2 chars < min:10) | Validation error: "The reason must be at least 10 characters." |

#### TC-N06: Access without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `hrs.leave_type.manage` | — |
| 2 | Navigate to HR Masters tab | Leave Balance Adjustments tab not visible or 403 |

#### TC-N07: Entry of adjustment_days with more than 1 decimal
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter adjustment_days as 1.567 | Validation error or value truncated to 1 decimal |

#### TC-N08: View non-existent adjustment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /leave-balance-adjustments/99999` | 404 Not Found |

#### TC-N09: Zero adjustment_days
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create adjustment with adjustment_days = 0 | Validation error or system rejects zero adjustment |

#### TC-N10: Guest user access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to any leave-balance-adjustments route | Redirect to /login |

### 7.3 Dependency TC Steps

#### TC-D01: Model `$fillable` matches DDL columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalanceAdjustment.php` | Verify `$fillable` contains `leave_balance_id`, `adjustment_days`, `reason`, `adjusted_by`, `is_active`, `created_by`, `updated_by` |

#### TC-D02: Model `$casts` — decimal/boolean
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalanceAdjustment.php` | Verify `$casts`: `adjustment_days` → `decimal:1`, `is_active` → `boolean` |

#### TC-D03: Model uses `SoftDeletes`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalanceAdjustment.php` | Confirm `use SoftDeletes;` |
| 2 | DDL `hrs_leave_balance_adjustments` | `deleted_at` column exists |

#### TC-D04: Model relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalanceAdjustment.php` | Confirm `leaveBalance()` belongsTo; `adjustedByEmployee()` belongsTo |

#### TC-D05: FK RESTRICT — cannot delete leave balance with adjustments
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Try to delete the `hrs_leave_balances` record referenced by an adjustment | DB foreign key constraint error |

#### TC-D08: ToggleStatus returns JSON
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` method response | Returns `response()->json([...])` |

#### TC-D06: Controller gate on every method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalanceAdjustmentController.php` | Confirm `Gate::authorize('hrs.leave_type.manage')` on `store()`, `show()`, `edit()`, `update()`, `toggleStatus()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()` |

#### TC-D07: Activity logged on create/update/delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalanceAdjustmentController.php` | Confirm `activityLog()` called in `store()`, `update()`, `toggleStatus()`, `destroy()`, `restore()`, `forceDelete()` |
