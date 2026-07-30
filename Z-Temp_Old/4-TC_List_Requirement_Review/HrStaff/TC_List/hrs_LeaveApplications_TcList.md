# hrs_LeaveApplications_TcList

## Module: HrStaff → Leave Management → Leave Applications

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | HrStaff / Leave Management / Leave Applications |
| URL(s) | `GET /leave-applications` (`hr-staff.applications.index`), `POST /leave-applications` (`hr-staff.applications.store`), `GET /leave-applications/{application}` (`hr-staff.applications.show`), `POST /leave-applications/{application}/approve` (`hr-staff.applications.approve`), `POST /leave-applications/{application}/reject` (`hr-staff.applications.reject`), `POST /leave-applications/{application}/cancel` (`hr-staff.applications.cancel`) |
| Controller | `Modules\HrStaff\Http\Controllers\LeaveApplicationController` (all methods), `Modules\HrStaff\Services\LeaveService::applyLeave()` lines 156–271, `LeaveService::cancelLeave()` lines 278–312, `Modules\HrStaff\Services\LeaveApprovalService::approve()` lines 22–70, `reject()` lines 76–105 |
| Model(s) | `Modules\HrStaff\Models\LeaveApplication` (table: `hrs_leave_applications`), `Modules\HrStaff\Models\LeaveApproval` (table: `hrs_leave_approvals`) |
| Validation (Create) | `Modules\HrStaff\Http\Requests\StoreLeaveApplicationRequest` |
| Validation (Approve/Reject) | `Modules\HrStaff\Http\Requests\ApproveLeaveRequest`, `RejectLeaveRequest` |
| Policy | `Modules\HrStaff\Policies\LeaveApplicationPolicy` |
| Permissions | `hrs.leave.apply`, `hrs.leave.approve_l1`, `hrs.leave.approve_l2`, `hrs.employment.manage` |
| Pagination | 25 per page (standalone `index()`), 20 per page with `applications_page` (menu page) |
| Soft Deletes | Yes — `SoftDeletes` trait on `LeaveApplication` model |
| Read-Only | No — create, approve, reject, cancel operations |

## 2. Pre-conditions

- User must be logged in with at least `hrs.leave.apply` to submit
- Employee record must be linked to the authenticated user (for employee_id)
- Active leave types must exist in `hrs_leave_types`
- Active academic sessions must exist in `sch_org_academic_sessions_jnt`
- Leave balances must be initialised for the target academic year (except LWP)
- For approval: approver must have `hrs.leave.approve_l1` or `hrs.leave.approve_l2` depending on `current_approver_level`
- Dusk env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

## 3. Default Data Load

`LeaveApplicationController::index()` gates with `hrs.leave.apply`, loads active applications with employee/leaveType/academicYear relations, orders by `created_at` desc, paginated at 25. Non-approver users see only their own applications. On the menu page, applications load at 20 per page with `applications_page` parameter.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Applications grid | `LeaveApplicationController::index()` | `LeaveApplication::with([employee, leaveType, academicYear])->active()->orderByDesc('created_at')` | is_active, employee_id (own only if non-approver) | 25/page |
| Menu page applications | `HrMenuController::leaveManagement()` | `LeaveApplication::with([employee, leaveType])->orderByDesc('created_at')` | is_active | 20/page (`applications_page`) |

## 4. Test Data Strategy

- Create 3 test employees: Employee A (applicant), Employee B (HOD/Level 1 approver), Employee C (Principal/Level 2 approver)
- Create active leave types: CL (Casual Leave, 15 days/year, carry_forward=5), SL (Sick Leave, 12 days/year, requires_medical_cert=true, threshold=3), ML (Maternity Leave, gender_restriction=female), EL (Earned Leave, min_service_months=6), LWP (no balance check)
- Initialize leave balances for the current academic year
- Set policy `approval_levels = 2` for two-level tests, `= 1` for single-level tests
- Use consistent dates: avoid holidays and Sundays
- Create at least 26 applications to test pagination

## 5. Business Conditions

### 5.1 Database Schema — `hrs_leave_applications`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | `employee_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (CASCADE) |
| BC-DB-03 | `leave_type_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_types.id` (RESTRICT) |
| BC-DB-04 | `academic_year_id` | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| BC-DB-05 | `from_date` | DATE | NOT NULL |
| BC-DB-06 | `to_date` | DATE | NOT NULL |
| BC-DB-07 | `half_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-08 | `half_day_session` | ENUM('first','second') | NULL |
| BC-DB-09 | `days_count` | DECIMAL(5,1) | NOT NULL (computed) |
| BC-DB-10 | `reason` | TEXT | NOT NULL |
| BC-DB-11 | `media_id` | INT UNSIGNED | NULL, FK → `sys_media.id` |
| BC-DB-12 | `status` | ENUM('pending','pending_l2','approved','rejected','cancelled','returned') | NOT NULL, DEFAULT 'pending' |
| BC-DB-13 | `current_approver_level` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-14 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-15 | `created_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-16 | `updated_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-17 | `created_at` | TIMESTAMP | NULL |
| BC-DB-18 | `updated_at` | TIMESTAMP | NULL |
| BC-DB-19 | `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| BC-DB-20 | KEY `idx_hrs_lapp_status` | INDEX | (`status`) |

### 5.2 Database Schema — `hrs_leave_approvals`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-21 | `id` | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-22 | `application_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_applications.id` (CASCADE) |
| BC-DB-23 | `approver_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (RESTRICT) |
| BC-DB-24 | `level` | TINYINT UNSIGNED | NOT NULL |
| BC-DB-25 | `action` | ENUM('approve','reject','return_for_clarification') | NOT NULL |
| BC-DB-26 | `remarks` | TEXT | NOT NULL |
| BC-DB-27 | `actioned_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-28 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-29 | `created_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-30 | `updated_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-31 | `created_at` | TIMESTAMP | NULL |
| BC-DB-32 | `updated_at` | TIMESTAMP | NULL |
| BC-DB-33 | `deleted_at` | TIMESTAMP | NULL (Soft delete) |

### 5.3 Validation Rules — `StoreLeaveApplicationRequest`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `leave_type_id` | `required\|exists:hrs_leave_types,id` | — |
| BC-VAL-02 | `academic_year_id` | `required\|exists:sch_org_academic_sessions_jnt,id` | — |
| BC-VAL-03 | `from_date` | `required\|date` | — |
| BC-VAL-04 | `to_date` | `required\|date\|after_or_equal:from_date` | — |
| BC-VAL-05 | `half_day` | `sometimes\|boolean` | — |
| BC-VAL-06 | `half_day_session` | `nullable\|required_if:half_day,true\|in:first,second` | — |
| BC-VAL-07 | `reason` | `required\|string\|min:10\|max:1000` | — |
| BC-VAL-08 | `media_id` | `nullable\|exists:sys_media,id` | — |

### 5.4 Validation Rules — `ApproveLeaveRequest` / `RejectLeaveRequest`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-09 | `remarks` | `required\|string\|min:5\|max:500` | — |

### 5.5 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `hrs.leave.apply` | Submit application, view own list |
| BC-AUTH-02 | `hrs.leave.approve_l1` | Approve/reject L1 pending applications |
| BC-AUTH-03 | `hrs.leave.approve_l2` | Approve/reject L2 pending applications |
| BC-AUTH-04 | `hrs.employment.manage` | View any application (show) |
| BC-AUTH-05 | No `hrs.leave.apply` + approver | 403 on submit/index |
| BC-AUTH-06 | No `hrs.leave.approve_l1` when level=1 | 403 on approve/reject |
| BC-AUTH-07 | No `hrs.leave.approve_l2` when level=2 | 403 on approve/reject |
| BC-AUTH-08 | Guest | Redirect to `/login` |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default page load (employee non-approver) | Shows only own applications |
| BC-BIZ-02 | Default page load (approver) | Shows all applications |
| BC-BIZ-03 | Submit valid leave application | Created with status=pending, current_approver_level=1 |
| BC-BIZ-04 | Submit half-day leave | days_count = 0.5; half_day=true |
| BC-BIZ-05 | Submit with half_day_session=first | half_day_session saved as 'first' |
| BC-BIZ-06 | Submit LWP leave | Created without balance check |
| BC-BIZ-07 | L1 approve (2-level policy) | Status → pending_l2; level → 2 |
| BC-BIZ-08 | L1 approve (1-level policy) | Status → approved; balance deducted |
| BC-BIZ-09 | L2 approve (final) | Status → approved; balance deducted; LeaveApproved event |
| BC-BIZ-10 | L1 reject | Status → rejected; LeaveRejected event |
| BC-BIZ-11 | L2 reject | Status → rejected |
| BC-BIZ-12 | Cancel pending application | Status → cancelled; no balance impact |
| BC-BIZ-13 | Cancel pending_l2 application | Status → cancelled |
| BC-BIZ-14 | Cancel approved (future start) | Status → cancelled; balance restored |
| BC-BIZ-15 | Cancel approved (already started) | DomainException: cannot cancel |
| BC-BIZ-16 | View application with approval history | Show page includes approvals with approver name, action, remarks |
| BC-BIZ-17 | Insufficient balance | DomainException: "Insufficient leave balance" |
| BC-BIZ-18 | No balance initialized | DomainException: "No leave balance found" |
| BC-BIZ-19 | Overlapping dates | DomainException: overlap detected |
| BC-BIZ-20 | Backdated exceeds policy | DomainException: window exceeded |
| BC-BIZ-21 | Gender restriction mismatch | DomainException: not applicable |
| BC-BIZ-22 | Minimum service months not met | DomainException: requires X months |
| BC-BIZ-23 | Medical certificate required but missing | DomainException: medical cert required |
| BC-BIZ-24 | Exceeds max consecutive days | DomainException: exceeds limit |
| BC-BIZ-25 | No employee linked to user | 403: "No employee record linked" |
| BC-BIZ-26 | Days computed excluding Sundays | days_count excludes Sundays |
| BC-BIZ-27 | Days computed excluding holidays | days_count excludes holidays (scoped by applicable_to) |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `employee_id` | `sch_employees` | CASCADE |
| BC-REF-02 | `leave_type_id` | `hrs_leave_types` | RESTRICT |
| BC-REF-03 | `academic_year_id` | `sch_org_academic_sessions_jnt` | RESTRICT |
| BC-REF-04 | `media_id` | `sys_media` | RESTRICT |
| BC-REF-05 | `application_id` (approvals) | `hrs_leave_applications` | CASCADE |
| BC-REF-06 | `approver_id` (approvals) | `sch_employees` | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Leave Applications page (employee) | Shows only own applications, paginated at 25 | — | — | ⬜ |
| TC-P02 | Load Leave Applications page (approver) | Shows all applications | — | — | ⬜ |
| TC-P03 | Submit valid full-day leave application | Created with status=pending; flash success | — | — | ⬜ |
| TC-P04 | Submit half-day leave (first session) | days_count=0.5; half_day=true; half_day_session=first | — | — | ⬜ |
| TC-P05 | Submit half-day leave (second session) | half_day_session=second | — | — | ⬜ |
| TC-P06 | Submit LWP leave (no balance check) | Created successfully | — | — | ⬜ |
| TC-P07 | L1 approve (2-level policy, pending→pending_l2) | Status changes to pending_l2; LeaveApproval record created | — | — | ⬜ |
| TC-P08 | L1 approve (1-level policy, pending→approved) | Status changes to approved; balance deducted | — | — | ⬜ |
| TC-P09 | L2 approve (pending_l2→approved, final) | Status changes to approved; balance deducted; LeaveApproved event | — | — | ⬜ |
| TC-P10 | L1 reject pending application | Status → rejected; LeaveRejected event | — | — | ⬜ |
| TC-P11 | L2 reject pending_l2 application | Status → rejected | — | — | ⬜ |
| TC-P12 | Cancel own pending application | Status → cancelled | — | — | ⬜ |
| TC-P13 | Cancel own pending_l2 application | Status → cancelled | — | — | ⬜ |
| TC-P14 | Cancel approved leave (future start) | Status → cancelled; balance restored | — | — | ⬜ |
| TC-P15 | View application detail | Shows employee, leave type, dates, reason, status, approval history | — | — | ⬜ |
| TC-P16 | Submit with media attachment (medical cert) | media_id saved; application created | — | — | ⬜ |
| TC-P17 | Days count excludes Sundays | 3-day Mon-Wed application without holidays → days_count=3 | — | — | ⬜ |
| TC-P18 | Days count excludes holidays | 3-day application with one holiday → days_count=2 | — | — | ⬜ |
| TC-P19 | Full lifecycle: submit→L1 approve→L2 approve | Complete approval flow; balance deducted at final step | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Submit with insufficient balance | DomainException: "Insufficient leave balance" | — | — | ⬜ |
| TC-N02 | Submit with no balance initialized | DomainException: "No leave balance found" | — | — | ⬜ |
| TC-N03 | Submit with overlapping dates | DomainException: overlap | — | — | ⬜ |
| TC-N04 | Submit backdated beyond policy limit | DomainException: window exceeded | — | — | ⬜ |
| TC-N05 | Submit with gender-restricted leave (wrong gender) | DomainException: not applicable for gender | — | — | ⬜ |
| TC-N06 | Submit EL before 6 months service | DomainException: requires X months | — | — | ⬜ |
| TC-N07 | Submit SL >3 days without medical cert | DomainException: medical certificate required | — | — | ⬜ |
| TC-N08 | Submit exceeding max_consecutive_days | DomainException: exceeds limit | — | — | ⬜ |
| TC-N09 | Submit with `to_date` before `from_date` | Validation error: after_or_equal | — | — | ⬜ |
| TC-N10 | Submit with reason < 10 characters | Validation error: min:10 | — | — | ⬜ |
| TC-N11 | Submit with reason > 1000 characters | Validation error: max:1000 | — | — | ⬜ |
| TC-N12 | Submit without leave_type_id | Validation error | — | — | ⬜ |
| TC-N13 | Submit with non-existent leave_type_id | Validation error: exists | — | — | ⬜ |
| TC-N14 | Approve without remarks | Validation error: remarks required | — | — | ⬜ |
| TC-N15 | Approve with remarks < 5 characters | Validation error: min:5 | — | — | ⬜ |
| TC-N16 | Approve rejected application | DomainException: cannot approve | — | — | ⬜ |
| TC-N17 | Approve cancelled application | DomainException: cannot approve | — | — | ⬜ |
| TC-N18 | Reject approved application | DomainException: cannot reject | — | — | ⬜ |
| TC-N19 | Cancel already started approved leave | DomainException: cannot cancel | — | — | ⬜ |
| TC-N20 | Cancel other employee's application | 403: only cancel own | — | — | ⬜ |
| TC-N21 | Cancel already cancelled application | DomainException: cannot cancel | — | — | ⬜ |
| TC-N22 | L2 approve when level=1 (wrong level) | L1 lacks L2 permission → 403 | — | — | ⬜ |
| TC-N23 | No employee linked to user | 403 | — | — | ⬜ |
| TC-N24 | Access index without permission | 403 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Application model `$fillable` matches DDL | All columns in fillable | — | — | ⬜ |
| TC-D02 | A | Application model `$casts` | dates/decimals/integers/boolean cast correctly | — | — | ⬜ |
| TC-D03 | A | Application model `SoftDeletes` | Trait present; DDL has `deleted_at` | — | — | ⬜ |
| TC-D04 | A | Application model relationships | employee(), leaveType(), academicYear(), media(), approvals() | — | — | ⬜ |
| TC-D05 | A | Approval model `$fillable`/`$casts` | All columns covered | — | — | ⬜ |
| TC-D06 | A | Approval model relationships | application(), approver() | — | — | ⬜ |
| TC-D07 | B | FK CASCADE — deleting employee cascades to applications | Employee delete removes their leave applications | — | — | ⬜ |
| TC-D08 | B | FK CASCADE — deleting application cascades to approvals | Application delete removes approval records | — | — | ⬜ |
| TC-D09 | B | FK RESTRICT — cannot delete leave type with applications | Leave type with applications cannot be deleted | — | — | ⬜ |
| TC-D10 | B | FK RESTRICT — cannot delete media with attached applications | Media record with applications cannot be deleted | — | — | ⬜ |
| TC-D11 | C | Controller gate on every method | `Gate::authorize()` or `authorizeView()`/`authorizeApproval()` on all 6 methods | — | — | ⬜ |
| TC-D12 | C | Activity logged on submit | `activityLog()` called with type, from, to, days | — | — | ⬜ |
| TC-D13 | C | Activity logged on approve | `activityLog()` with level info | — | — | ⬜ |
| TC-D14 | C | Activity logged on reject | `activityLog()` called | — | — | ⬜ |
| TC-D15 | C | Activity logged on cancel | `activityLog()` called | — | — | ⬜ |
| TC-D16 | C | `LeaveService::applyLeave()` in DB transaction | Multi-step validation within transaction | — | — | ⬜ |
| TC-D17 | C | `LeaveApprovalService::approve()` in DB transaction | Approval + balance deduction within transaction | — | — | ⬜ |
| TC-D18 | C | `LeaveService::cancelLeave()` in DB transaction | Status change + balance restore within transaction | — | — | ⬜ |
| TC-D19 | C | `LeaveService::calculateDays()` uses HolidayService | Sundays and holidays excluded from days_count | — | — | ⬜ |
| TC-D20 | C | Policy methods match gate checks | `LeaveApplicationPolicy` has viewAny, view, create, approve, cancel | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Application model `$fillable` matches DDL columns | Mass-assignment protection covers all columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Application model `$casts` — dates/decimals/integers/booleans | Correct cast types for all cast fields | — | — | ◌ |
| TC-CR03 | CR | P1 | Application model — `SoftDeletes` | Trait present; DDL has `deleted_at` column | — | — | ◌ |
| TC-CR04 | CR | P1 | Application model — all 5 relationships defined | employee, leaveType, academicYear, media, approvals | — | — | ◌ |
| TC-CR05 | CR | P1 | Approval model — fillable, casts, relationships | Matches DDL | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — `Gate::authorize()` or helpers on every method | All 6 public methods gated | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — DB transactions on multi-step writes | applyLeave, approve, reject, cancel all use DB::transaction | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | Created, Approved, Rejected, Cancelled logged | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — exception handling for DomainException | `store()`, `approve()`, `reject()`, `cancel()` catch DomainException and flash error | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — validation rules cover all fields | `StoreLeaveApplicationRequest` has 8 rules; `ApproveLeaveRequest`/`RejectLeaveRequest` have 1 rule | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — `prepareForValidation()` normalizations | `half_day` boolean cast in StoreLeaveApplicationRequest | — | — | ◌ |
| TC-CR12 | CR | P1 | Policy — all required methods defined | `viewAny`, `view`, `create`, `approve`, `cancel` in LeaveApplicationPolicy | — | — | ◌ |
| TC-CR13 | CR | P1 | Routes — all 6 routes registered | index, store, show, approve, reject, cancel with correct names | — | — | ◌ |
| TC-CR14 | CR | P1 | View — Blade `@can` directives | Tab/approve/reject buttons guarded by permission checks | — | — | ◌ |
| TC-CR15 | CR | P1 | View — null-safe checks for relationship variables | `isset($application->employee)` before rendering | — | — | ◌ |
| TC-CR16 | CR | P1 | Events — `LeaveApproved` and `LeaveRejected` fired | `event(new LeaveApproved/LeaveRejected(...))` called at final states | — | — | ◌ |
| TC-CR17 | CR | P1 | Database — unique indexes | No unique constraints on applications (multiple OK); index on `status` | — | — | ◌ |
| TC-CR18 | CR | P1 | Breadcrumb — route registered | `hr-staff.menu.leaveManagement?tab=leave-applications` in breadcrumb config | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01 through TC-CR18: Code Review
| TC ID | Action | Expected Result |
|-------|--------|-----------------|
| TC-CR01 | Open `LeaveApplication.php` | Verify `$fillable` includes all 13 DDL columns for mass-assignment protection |
| TC-CR02 | Open `LeaveApplication.php` — `$casts` | Verify `from_date`/`to_date` → date, `half_day` → boolean, `days_count` → decimal:1, `created_by` → integer |
| TC-CR03 | Open `LeaveApplication.php` — traits | Verify `SoftDeletes` trait present; DDL has `deleted_at` column |
| TC-CR04 | Open `LeaveApplication.php` — relationships | Verify `employee()`, `leaveType()`, `academicYear()`, `media()`, `approvals()` defined |
| TC-CR05 | Open `LeaveApproval.php` | Verify `$fillable`, `$casts`, `SoftDeletes`, relationships match DDL |
| TC-CR06 | Open `LeaveApplicationController.php` | Verify all 6 methods have `Gate::authorize()` or `authorizeView()`/`authorizeApproval()` |
| TC-CR07 | Open `LeaveApplicationController.php` — transactions | Verify `store()` calls `LeaveService::applyLeave()` in DB transaction; approve/reject/cancel use DB transactions |
| TC-CR08 | Open `LeaveApplicationController.php` — activity | Verify activity logged on Created, Approved, Rejected, Cancelled |
| TC-CR09 | Open `LeaveApplicationController.php` — exception handling | Verify `try-catch (DomainException)` in store, approve, reject, cancel — flashes error message |
| TC-CR10 | Open `StoreLeaveApplicationRequest.php`, `ApproveLeaveRequest.php`, `RejectLeaveRequest.php` | Verify rules cover all fields; check `prepareForValidation()` normalises half_day to boolean |
| TC-CR11 | Open `StoreLeaveApplicationRequest.php` — `prepareForValidation()` | Verify `half_day` boolean cast from checkbox input |
| TC-CR12 | Open `LeaveApplicationPolicy.php` | Verify `viewAny()`, `view()`, `create()`, `approve()`, `cancel()` methods defined |
| TC-CR13 | Open `routes/web.php` | Verify all 6 routes: index, store, show, approve, reject, cancel with correct names |
| TC-CR14 | Open `resources/views/leave_application/*.blade.php` | Verify `@can('hrs.leave.approve_l1')`/`@can('hrs.leave.approve_l2')` on approve buttons |
| TC-CR15 | Open `resources/views/leave_application/show.blade.php` | Verify `isset($application->employee)` null-safe checks before rendering |
| TC-CR16 | Open `Events/LeaveApproved.php` and `LeaveRejected.php` | Verify events fired on final approval and rejection |
| TC-CR17 | Check DDL — `hrs_leave_applications` indexes | Verify indexes on employee_id, leave_type_id, academic_year_id, media_id, status — no unique constraints (multiple applications same type allowed) |
| TC-CR18 | Check `config/breadcrumb.php` | Verify `hr-staff.menu.leaveManagement?tab=leave-applications` route registered with correct hierarchy |

### 7.1 Positive TC Steps

#### TC-P01: Load Leave Applications page (employee, non-approver)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as Employee A (no approver permissions) | — |
| 2 | Navigate to Leave Management > Leave Applications tab | Grid shows only Employee A's own applications, paginated at 25 |

#### TC-P02: Load Leave Applications page (approver)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as Employee B (has `hrs.leave.approve_l1`) | — |
| 2 | Navigate to Leave Applications tab | Grid shows all employees' applications |

#### TC-P03: Submit valid full-day leave application
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as Employee A (sufficient CL balance) | — |
| 2 | Fill form: Leave Type = CL, From = 2025-08-11 (Mon), To = 2025-08-13 (Wed) | — |
| 3 | Enter reason "Attending family function" (>10 chars) | — |
| 4 | Submit | Flash: "Leave application submitted successfully." |
| 5 | Verify DB: status=pending, current_approver_level=1, days_count=3 | — |

#### TC-P04: Submit half-day leave (first session)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit new application with half_day=true, half_day_session=first | days_count=0.5; half_day=1; half_day_session='first' |

#### TC-P05: Submit half-day leave (second session)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with half_day=true, half_day_session=second | half_day_session='second' |

#### TC-P06: Submit LWP leave (no balance check)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit application with Leave Type = LWP (code=LWP) | Created successfully even without LWP balance |

#### TC-P07: L1 approve (2-level, pending→pending_l2)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure policy approval_levels=2 | — |
| 2 | Employee A submits CL application | status=pending |
| 3 | Employee B (HOD, `hrs.leave.approve_l1`) approves with remarks "Approved" | status=pending_l2, current_approver_level=2 |
| 4 | Verify LeaveApproval record with action='approve', level=1 | — |

#### TC-P08: L1 approve (1-level, pending→approved)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set policy approval_levels=1 | — |
| 2 | Employee A submits application | status=pending |
| 3 | Employee B approves | status=approved; balance used_days incremented |

#### TC-P09: L2 approve (pending_l2→approved, final)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Application is in pending_l2 status | — |
| 2 | Employee C (Principal, `hrs.leave.approve_l2`) approves with remarks "Approved at principal level" | status=approved |
| 3 | Verify LeaveApproval with action='approve', level=2 | — |
| 4 | Verify balance used_days incremented by days_count | — |

#### TC-P10: L1 reject pending application
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee A submits new application | status=pending |
| 2 | Employee B rejects with remarks "Not eligible" | status=rejected; LeaveApproval record created |

#### TC-P12: Cancel own pending application
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee A submits application | status=pending |
| 2 | Employee A clicks Cancel | status=cancelled; no balance impact |

#### TC-P14: Cancel approved leave (future)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create approved application with future from_date (next month) | — |
| 2 | Employee A cancels | status=cancelled; balance used_days decremented |

#### TC-P15: View application detail
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click on an application row | Show page: employee name, leave type, dates, days_count, reason, status, approval history (if any) |

#### TC-P17: Days count excludes Sundays
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit application: From = Thursday, To = next Wednesday (includes 1 Sunday) | days_count = 6 (7 calendar days minus 1 Sunday) |

#### TC-P11, TC-P13, TC-P16, TC-P18: Additional positive scenarios (compact)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P11 | L2 reject pending_l2 application | Employee C (L2) rejects with remarks "Not approved" | status → rejected; LeaveApproval record created |
| TC-P13 | Cancel own pending_l2 application | Employee A cancels the application | status → cancelled |
| TC-P16 | Submit with media attachment | Upload medical cert and apply for SL >3 days | media_id saved; application created |
| TC-P18 | Days count excludes holidays | Submit 3-day application with a holiday in range | days_count = 2 (3 minus 1 holiday) |

#### TC-P19: Full lifecycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee A submits CL (2 days) | status=pending, level=1 |
| 2 | HOD approves | status=pending_l2, level=2 |
| 3 | Principal approves | status=approved; balance CL used_days +2 |

### 7.2 Negative TC Steps

#### TC-N01: Insufficient balance
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Employee A has 0 CL available days | — |
| 2 | Submit CL application for 1 day | DomainException: "Insufficient leave balance. Available: 0, Requested: 1" |

#### TC-N03: Overlapping dates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee A has approved leave Aug 11-13 | — |
| 2 | Submit another application Aug 10-12 | DomainException: "Leave dates overlap with an existing application." |

#### TC-N05: Gender restriction mismatch
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Male employee applies for Maternity Leave (gender_restriction=female) | DomainException: "This leave type is not applicable for your gender." |

#### TC-N07: Medical certificate missing
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee A applies for SL for 5 days without media_id | DomainException: "Medical certificate is required for Sick Leave exceeding 3 day(s)." |

#### TC-N19: Cancel already started approved leave
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approved application with from_date = yesterday | — |
| 2 | Applicant tries to cancel | DomainException: "Cannot cancel approved leave that has already started." |

#### TC-N20: Cancel other employee's application
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee B (different employee) tries to cancel Employee A's application | 403: "You can only cancel your own applications." |

#### Additional negative scenarios — validation and business rule failures (compact table)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N02 | No balance initialized for employee | Submit any non-LWP leave | DomainException: "No leave balance found" |
| TC-N04 | Submit with from_date 10 days ago (policy max_backdated=3) | Click submit | DomainException: backdated window exceeded |
| TC-N06 | Employee with 3 months service applies for EL (min_service=6) | Click submit | DomainException: requires 6 months |
| TC-N08 | Leave type max_consecutive_days=5, apply for 7 days | Click submit | DomainException: exceeds limit |
| TC-N09 | Set from_date=2025-08-15, to_date=2025-08-10 | Click submit | Validation error: to_date must be after from_date |
| TC-N10 | Enter reason "Short" (4 chars) | Click submit | Validation error: min:10 |
| TC-N11 | Enter 1001-character reason | Click submit | Validation error: max:1000 |
| TC-N12 | Submit without leave_type_id | Click submit | Validation error |
| TC-N13 | Submit with leave_type_id=99999 | Click submit | Validation error: exists |
| TC-N14 | Approve with empty remarks | Click approve | Validation error: remarks required |
| TC-N15 | Approve with remarks "OK" (2 chars) | Click approve | Validation error: min:5 |
| TC-N16 | Approve a rejected application | Click approve | DomainException: cannot approve |
| TC-N17 | Approve a cancelled application | Click approve | DomainException: cannot approve |
| TC-N18 | Reject an approved application | Click reject | DomainException: cannot reject |
| TC-N21 | Cancel an already cancelled application | Click cancel | DomainException: cannot cancel |
| TC-N23 | User without employee record submits leave | Click submit | 403: "No employee record linked" |
| TC-N24 | Access index without `hrs.leave.apply` | Navigate to applications | 403 Forbidden |

#### TC-N22: L2 approve when user only has L1
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Application is at level=2 (pending_l2) | — |
| 2 | Employee B (only `hrs.leave.approve_l1`) tries to approve | 403 Forbidden |

### 7.3 Dependency TC Steps

#### TC-D01 through TC-D06, TC-D09 through TC-D18, TC-D20: Model, FK, controller, service, and policy dependency checks (compact table)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-D01 | Open `LeaveApplication.php` | Check `$fillable` | All DDL columns present |
| TC-D02 | Open `LeaveApplication.php` | Check `$casts` | dates/decimals/integers/boolean cast correctly |
| TC-D03 | Open `LeaveApplication.php` | Check `SoftDeletes` trait | Trait present; DDL has `deleted_at` |
| TC-D04 | Open `LeaveApplication.php` | Check relationships | `employee()`, `leaveType()`, `academicYear()`, `media()`, `approvals()` |
| TC-D05 | Open `LeaveApproval.php` | Check `$fillable`/`$casts` | All columns covered |
| TC-D06 | Open `LeaveApproval.php` | Check relationships | `application()`, `approver()` |
| TC-D09 | Try to delete leave type with applications | Execute DB delete | FK RESTRICT error |
| TC-D10 | Try to delete sys_media record with attached applications | Execute DB delete | FK RESTRICT error |
| TC-D11 | Open `LeaveApplicationController.php` | Check all 6 methods | Gates on index, store; authorizeView on show; authorizeApproval on approve/reject; ownership on cancel |
| TC-D12 | Open `LeaveApplicationController.php` `store()` | Check `activityLog()` | Called with Created type, type, from, to, days |
| TC-D13 | Open `LeaveApplicationController.php` `approve()` | Check `activityLog()` | Called with Approved type, level |
| TC-D14 | Open `LeaveApplicationController.php` `reject()` | Check `activityLog()` | Called with Rejected type |
| TC-D15 | Open `LeaveApplicationController.php` `cancel()` | Check `activityLog()` | Called with Cancelled type |
| TC-D16 | Open `LeaveService.php` `applyLeave()` | Check `DB::transaction()` | Multi-step validation within DB transaction |
| TC-D17 | Open `LeaveApprovalService.php` `approve()` | Check `DB::transaction()` | Approval + balance deduction within transaction |
| TC-D18 | Open `LeaveService.php` `cancelLeave()` | Check `DB::transaction()` | Status change + balance restore within transaction |
| TC-D20 | Open `LeaveApplicationPolicy.php` | Check methods | `viewAny`, `view`, `create`, `approve`, `cancel` defined |

#### TC-D07: FK CASCADE on employee delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete employee who has leave applications | Applications for that employee cascade-deleted |

#### TC-D08: FK CASCADE on application delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an application that has approvals | Approval records also cascade-deleted |

#### TC-D19: `calculateDays()` uses HolidayService
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit application over a date range that includes a holiday | days_count excludes the holiday date |
