# hrs_LeaveBalances_TcList

## Module: HrStaff → Leave Management → Leave Balances

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | HrStaff / Leave Management / Leave Balances |
| URL(s) | `GET /leave-balances` (`hr-staff.balances.index`), `POST /leave-balances/initialize` (`hr-staff.balances.initialize`), `GET /leave-balances/trash/view` (`hr-staff.balances.trashed`), `GET /leave-balances/{id}/restore` (`hr-staff.balances.restore`) |
| Controller | `Modules\HrStaff\Http\Controllers\LeaveController::balances()` lines 90–105, `initializeBalances()` lines 66–85, `trashedBalances()` lines 110–120, `restoreBalance()` lines 125–135 |
| Model(s) | `Modules\HrStaff\Models\LeaveBalance` (table: `hrs_leave_balances`) |
| Validation (Initialize) | `Modules\HrStaff\Http\Requests\InitializeLeaveBalancesRequest` |
| Policy | `Modules\HrStaff\Policies\LeaveBalancePolicy` |
| Permissions | `hrs.leave.balance.view`, `hrs.employment.manage` |
| Pagination | 50 per page (standalone), 60 per page with `balances_page` param (menu page) |
| Soft Deletes | Yes — `SoftDeletes` trait on model |

## 2. Pre-conditions

- User must be logged in with `hrs.leave.balance.view` (view) or `hrs.employment.manage` (initialize)
- Academic sessions must exist in `sch_org_academic_sessions_jnt` with at least one current session
- Active employees must exist in `sch_employees`
- Active leave types must exist in `hrs_leave_types`
- Dusk env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

## 3. Default Data Load

`LeaveController::balances()` gates with `hrs.leave.balance.view`, loads active balances for the current academic year with employee and leave type relations, ordered by `employee_id`, paginated at 50. Academic years also load for the filter dropdown. On the menu page, the menu controller loads balances filtered by `balance_year` and `search`, paginated at 60 with `balances_page`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Balances grid | `LeaveController::balances()` | `LeaveBalance::with([employee, leaveType])->active()->when(currentSession, ...)` | academic_year_id, is_active | 50/page |
| Menu page balances | `HrMenuController::leaveManagement()` | Same + `search` (employee name) + `balance_year` | search, balance_year, is_active | 60/page (`balances_page`) |
| Academic years | Both | `OrganizationAcademicSession::orderByDesc('start_date')->get()` | None | None |

## 4. Test Data Strategy

- Create 3 employees and 3 active leave types (CL, EL, SL) in test DB
- Create academic sessions for 2024-25 (prior) and 2025-26 (current)
- Run initialize to generate base balance data
- For carry-forward tests, manually set prior year's used_days to specific values
- For pagination test, create enough employees to exceed 50 or 60 per page limit

## 5. Business Conditions

### 5.1 Database Schema — `hrs_leave_balances`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | `employee_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (CASCADE) |
| BC-DB-03 | `leave_type_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_types.id` (RESTRICT) |
| BC-DB-04 | `academic_year_id` | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| BC-DB-05 | `allocated_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| BC-DB-06 | `carry_forward_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| BC-DB-07 | `used_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| BC-DB-08 | `lop_days` | DECIMAL(5,1) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-10 | `created_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-11 | `updated_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-12 | `created_at` | TIMESTAMP | NULL |
| BC-DB-13 | `updated_at` | TIMESTAMP | NULL |
| BC-DB-14 | `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| BC-DB-15 | UNIQUE KEY `uq_hrs_leave_bal` | (`employee_id`, `leave_type_id`, `academic_year_id`) | Prevents duplicates |

### 5.2 Validation Rules — `InitializeLeaveBalancesRequest`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `academic_year_id` | `required\|exists:sch_org_academic_sessions_jnt,id` | — |
| BC-VAL-02 | `prior_academic_year_id` | `nullable\|exists:sch_org_academic_sessions_jnt,id` | — |
| BC-VAL-03 | `reset` | `sometimes\|boolean` | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `hrs.leave.balance.view` | View balances allowed |
| BC-AUTH-02 | `hrs.employment.manage` | Initialize balances allowed |
| BC-AUTH-03 | No `hrs.leave.balance.view` | `GET /leave-balances` → 403 |
| BC-AUTH-04 | No `hrs.employment.manage` | `POST /leave-balances/initialize` → 403 |
| BC-AUTH-05 | Guest | Redirect to `/login` |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default page load | Grid shows all employees × leave types for current academic year |
| BC-BIZ-02 | Initialize balances for new year | Balance records created for all active employees × active leave types |
| BC-BIZ-03 | Initialize with carry-forward | `carry_forward_days` computed from prior year's remaining days, capped at `leave_type.carry_forward_days` |
| BC-BIZ-04 | Initialize with `reset=true` | Existing balances force-deleted; fresh records created; activity logged |
| BC-BIZ-05 | Re-initialize without reset, no activity | Existing records updated with new `allocated_days` and `carry_forward_days`; `used_days` and `lop_days` preserved |
| BC-BIZ-06 | Re-initialize without reset, with activity | `DomainException`: "Cannot re-initialize leave balances for a year that already has leave applications or adjustments." |
| BC-BIZ-07 | Filter by academic year | Grid reloads showing balances for selected year |
| BC-BIZ-08 | Search by employee name | Grid filtered to matching employees |
| BC-BIZ-09 | Empty state (no balances exist) | Empty grid with no records |
| BC-BIZ-10 | Balance `available_days` computed correctly | `available_days = allocated_days + carry_forward_days - used_days` |
| BC-BIZ-11 | Trashed balances view | Soft-deleted balances listed at 30 per page |
| BC-BIZ-12 | Restore trashed balance | Balance restored with `is_active = true`; success flash |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `employee_id` | `sch_employees` | CASCADE |
| BC-REF-02 | `leave_type_id` | `hrs_leave_types` | RESTRICT |
| BC-REF-03 | `academic_year_id` | `sch_org_academic_sessions_jnt` | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Leave Balances page | Grid displays employees × leave types with allocated, carry-forward, used, available columns | — | — | ⬜ |
| TC-P02 | Filter balances by academic year | Grid reloads showing balances for selected year | — | — | ⬜ |
| TC-P03 | Search by employee name | Grid filtered to employees matching search term | — | — | ⬜ |
| TC-P04 | Initialize balances for new year | Success flash with record count; all employees have balance rows | — | — | ⬜ |
| TC-P05 | Initialize with carry-forward from prior year | `carry_forward_days` populated correctly from prior remaining | — | — | ⬜ |
| TC-P06 | Initialize with `reset=true` | Existing balances force-deleted; fresh records created | — | — | ⬜ |
| TC-P07 | Re-initialize (idempotent, no activity) | Existing balances updated; used_days preserved | — | — | ⬜ |
| TC-P08 | View trashed balances | List of soft-deleted balances shown at 30 per page | — | — | ⬜ |
| TC-P09 | Restore a trashed balance | Balance restored; `is_active = true`; success flash | — | — | ⬜ |
| TC-P10 | Verify `available_days` computation | For a record with allocated=15, carry=2, used=3, available=14 | — | — | ⬜ |
| TC-P11 | Pagination on balances page | Records split across pages (50/page standalone, 60/page menu) | — | — | ⬜ |
| TC-P12 | Initialize LWP leave type (no balance check) | LWP type gets balance row with `allocated_days = 0` | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Initialize with non-existent `academic_year_id` | Validation error | — | — | ⬜ |
| TC-N02 | Initialize with non-existent `prior_academic_year_id` | Validation error | — | — | ⬜ |
| TC-N03 | Re-initialize with existing leave applications (no reset) | `DomainException` about existing activity | — | — | ⬜ |
| TC-N04 | Re-initialize with existing adjustments (no reset) | Same `DomainException` | — | — | ⬜ |
| TC-N05 | Access page without `hrs.leave.balance.view` | 403 Forbidden | — | — | ⬜ |
| TC-N06 | Initialize without `hrs.employment.manage` | 403 Forbidden | — | — | ⬜ |
| TC-N07 | Guest access to page | Redirect to /login | — | — | ⬜ |
| TC-N08 | Search with non-matching name | Empty grid | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Model `$fillable` matches DDL columns | All non-PK, non-timestamp columns in fillable | — | — | ⬜ |
| TC-D02 | A | Model `$casts` — decimal fields | `allocated_days`, `carry_forward_days`, `used_days`, `lop_days` cast as decimal:1 | — | — | ⬜ |
| TC-D03 | A | Model uses `SoftDeletes` | Trait present; `deleted_at` column in DDL | — | — | ⬜ |
| TC-D04 | A | Model relationships | `employee()`, `leaveType()`, `academicYear()` belongTo; `adjustments()` hasMany | — | — | ⬜ |
| TC-D05 | A | `available_days` accessor | Returns `allocated + carry_forward - used` | — | — | ⬜ |
| TC-D06 | B | FK CASCADE — deleting employee cascades to balances | Deleting `sch_employees` record cascades to `hrs_leave_balances` | — | — | ⬜ |
| TC-D07 | B | FK RESTRICT — cannot delete leave type with balances | Deleting `hrs_leave_types` record referenced by balance fails | — | — | ⬜ |
| TC-D08 | C | Controller gate on `balances()` | `Gate::authorize('hrs.leave.balance.view')` called | — | — | ⬜ |
| TC-D09 | C | Controller gate on `initializeBalances()` | `Gate::authorize('hrs.employment.manage')` called | — | — | ⬜ |
| TC-D10 | C | Activity logged on initialize | `activityLog()` called with Initialized/Reset type | — | — | ⬜ |
| TC-D11 | C | Activity logged on reset | "LeaveBalanceReset" activity with deleted_count | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model `$fillable` matches DDL columns | Mass-assignment protection covers all editable columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` — decimals/boolean | `$casts` array correctly defines types | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` trait | Trait present; `deleted_at` column exists | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships | All 4 relationships defined correctly | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `Gate::authorize()` on every method | `balances()`, `initializeBalances()`, `trashedBalances()`, `restoreBalance()` all gated | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `initializeBalances()` runs inside `DB::transaction()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — activity logged | `activityLog()` called in `initializeBalances()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — `is_active=false` before soft delete | `restoreBalance()` sets `is_active = true` after restore | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — JSON/flash after action | Flash messages on success | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — validation rules | `InitializeLeaveBalancesRequest` covers all fields with correct rules | — | — | ◌ |
| TC-CR11 | CR | P1 | Policy — all required methods | `viewAny`, `manage`, `initialize` defined in `LeaveBalancePolicy` | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — resource + custom routes | All 4 routes registered with correct names | — | — | ◌ |
| TC-CR13 | CR | P1 | View — Blade `@can` directives | Balance tab visible only with proper permission | — | — | ◌ |
| TC-CR14 | CR | P1 | View — null-safe checks for relationships | Balance view checks for `$balance->employee` before rendering | — | — | ◌ |
| TC-CR15 | CR | P1 | Database — unique indexes match validation rules | `uq_hrs_leave_bal` enforces (employee, leave_type, academic_year) uniqueness | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01 through TC-CR15: Code Review
| TC ID | Action | Expected Result |
|-------|--------|-----------------|
| TC-CR01 | Open `LeaveBalance.php` — `$fillable` | Verify `$fillable` matches all DDL columns |
| TC-CR02 | Open `LeaveBalance.php` — `$casts` | Verify decimal and boolean casts correctly defined |
| TC-CR03 | Open `LeaveBalance.php` — traits | Verify `SoftDeletes` trait present; DDL has `deleted_at` column |
| TC-CR04 | Open `LeaveBalance.php` — relationships | Verify `employee()`, `leaveType()`, `academicYear()`, `adjustments()` defined |
| TC-CR05 | Open `LeaveController.php` — gates | Verify `balances()`, `initializeBalances()`, `trashedBalances()`, `restoreBalance()` all have `Gate::authorize()` |
| TC-CR06 | Open `LeaveController.php` — transactions | Verify `initializeBalances()` runs inside `DB::transaction()` |
| TC-CR07 | Open `LeaveController.php` — activity | Verify `activityLog()` called in `initializeBalances()` |
| TC-CR08 | Open `LeaveController.php` — restore pattern | Verify `restoreBalance()` sets `is_active = true` after restore |
| TC-CR09 | Open `LeaveController.php` — flash messages | Verify flash messages on success redirects |
| TC-CR10 | Open `InitializeLeaveBalancesRequest.php` | Verify rules: academic_year_id (required|exists), prior_year_id (nullable|exists), reset (sometimes|boolean) |
| TC-CR11 | Open `LeaveBalancePolicy.php` | Verify `viewAny()`, `manage()`, `initialize()` methods defined |
| TC-CR12 | Open `routes/web.php` | Verify 4 routes: leave-balances (GET), leave-balances/initialize (POST), leave-balances/trash/view (GET), leave-balances/{id}/restore (GET) |
| TC-CR13 | Open views — `@can` directives | Verify Balance tab visibility guarded by permission check |
| TC-CR14 | Open views — null-safe | Verify `isset($balance->employee)` checks before rendering |
| TC-CR15 | Check DDL — `hrs_leave_balances` | Verify UNIQUE KEY `uq_hrs_leave_bal` on (employee_id, leave_type_id, academic_year_id) matches validation |

### 7.1 Positive TC Steps

#### TC-P01: Load Leave Balances page (standalone)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `hrs.leave.balance.view` | — |
| 2 | Navigate to `GET /leave-balances` | Grid displays with columns: Employee, Leave Type, Allocated, Carry-Forward, Used, Available, LOP |
| 3 | Verify year filter dropdown is present | Academic year filter loaded |

#### TC-P02: Filter by academic year
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On balances page, select a different academic year from filter | — |
| 2 | Page reloads with balances for selected year only | — |

#### TC-P03: Search by employee name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On menu page Leave Balances tab, enter employee name in search | — |
| 2 | Grid filtered to matching employees | — |

#### TC-P04: Initialize balances for new year
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `hrs.employment.manage` | — |
| 2 | Navigate to Leave Management > Leave Balances tab | — |
| 3 | Click "Initialize Balances" | — |
| 4 | Select target academic year (2025-26), leave prior year empty | — |
| 5 | Submit | Flash: "{n} leave balance records initialized." |
| 6 | Verify DB: `hrs_leave_balances` has rows for each employee × leave type | — |

#### TC-P05: Initialize with carry-forward
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure prior year (2024-25) has balances with known remaining days | — |
| 2 | Initialize for 2025-26 with prior_academic_year_id = 2024-25 | — |
| 3 | Verify `carry_forward_days` = min(prior_remaining, leave_type.carry_forward_days) | — |

#### TC-P06: Initialize with reset
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Initialize for a year that already has balances | — |
| 2 | Check "Reset existing balances" | — |
| 3 | Submit | Flash: "{n} leave balance records reset." |
| 4 | Verify old balances force-deleted; new records created | — |

#### TC-P07: Re-initialize idempotent (no reset, no activity)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually change some `used_days` values | — |
| 2 | Re-initialize same year without reset | — |
| 3 | Verify `allocated_days` and `carry_forward_days` updated but `used_days` preserved | — |

#### TC-P08: View trashed balances
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a balance record | — |
| 2 | Navigate to `GET /leave-balances/trash/view` | List shows soft-deleted balance(s) |

#### TC-P09: Restore a trashed balance
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash page, click Restore for a record | Flash: "Leave balance restored successfully." |
| 2 | Verify record back in main list with `is_active = true` | — |

#### TC-P10: Verify `available_days` computation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create balance: allocated=15, carry_forward=2, used=3 | — |
| 2 | Load balances page | available_days column shows 14 |

#### TC-P11: Pagination
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure >50 balance records exist | — |
| 2 | Load balances page | Page 1 shows 50 records; page controls available |

#### TC-P12: Initialize LWP leave type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure LWP leave type exists with `days_per_year = 0` | — |
| 2 | Initialize balances | LWP balance row created with `allocated_days = 0` |

### 7.2 Negative TC Steps

#### TC-N01: Initialize with non-existent `academic_year_id`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open initialize form | — |
| 2 | Set `academic_year_id` to 99999 | — |
| 3 | Submit | Validation error |

#### TC-N02: Initialize with non-existent `prior_academic_year_id`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `prior_academic_year_id` to 99999 | — |
| 2 | Submit | Validation error |

#### TC-N03: Re-initialize with existing leave applications
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a leave application for the target year | — |
| 2 | Initialize same year without reset | DomainException error page |

#### TC-N04: Initialize with reset=false but existing adjustments
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a balance adjustment for the target year | — |
| 2 | Initialize same year without reset | DomainException: "Cannot re-initialize leave balances for a year that already has leave applications or adjustments." |

#### TC-N05: Access without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `hrs.leave.balance.view` | — |
| 2 | Navigate to `GET /leave-balances` | 403 Forbidden |

#### TC-N06: Guest user access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /leave-balances` | Redirect to /login |

#### TC-N07: Initialize with reset=true but no existing balances
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no balances exist for the target year | — |
| 2 | Initialize with reset=true | Reset is idempotent — creates fresh balances without error |

#### TC-N08: Search with no match
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter search term "nonexistentemployee" | — |
| 2 | Grid shows no records | — |

### 7.3 Dependency TC Steps

#### TC-D01: Model `$fillable` matches DDL columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalance.php` | Verify `$fillable` contains all editable columns from DDL |

#### TC-D02: Model `$casts` — decimal fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalance.php` | Verify `$casts`: `allocated_days`, `carry_forward_days`, `used_days`, `lop_days` cast to `decimal:1`; `is_active` cast to `boolean` |

#### TC-D03: Model uses `SoftDeletes`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalance.php` | Confirm `use SoftDeletes;` |
| 2 | DDL: `hrs_leave_balances` | `deleted_at` column exists as TIMESTAMP NULL |

#### TC-D04: Model relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalance.php` | Confirm `employee()`, `leaveType()`, `academicYear()` belongTo; `adjustments()` hasMany |

#### TC-D05: `available_days` accessor
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveBalance.php` | `getAvailableDaysAttribute()` returns `allocated_days + carry_forward_days - used_days` |
| 2 | Create balance with allocated=15, carry=2, used=3 | `available_days` returns 14.0 |

#### TC-D06: FK CASCADE on employee delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note a balance record's `employee_id` | — |
| 2 | Delete the `sch_employees` record with that ID | — |
| 3 | Verify `hrs_leave_balances` rows for that employee are also deleted | — |

#### TC-D07: FK RESTRICT on leave type delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Try to delete an `hrs_leave_types` record referenced by a balance | DB error: foreign key constraint violation |

#### TC-D08: Controller gate on `balances()`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` line 92 | Confirm `Gate::authorize('hrs.leave.balance.view')` |

#### TC-D09: Controller gate on `initializeBalances()`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` line 68 | Confirm `Gate::authorize('hrs.employment.manage')` |

#### TC-D10: Activity logged on initialize
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` line 78 | Confirm `activityLog()` called with type `Initialized` |
| 2 | Initialize balances | Activity log entry recorded |

#### TC-D11: Activity logged on reset
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveService.php` line 63 | Confirm "LeaveBalanceReset" activity with `deleted_count` |
