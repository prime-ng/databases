# Leave Applications — Business Requirements

## What This Screen Does

The Leave Applications screen handles the full lifecycle of employee leave requests. Employees submit applications; HODs (Level 1) and Principals (Level 2) approve, reject, or return them for clarification. The system enforces a 6-state finite state machine: `pending → pending_l2 → approved/rejected/cancelled/returned`. Balance deduction happens only at final approval. A 7-step validation chain in the business layer checks balance, overlap, backdating, gender eligibility, service duration, medical certificate requirements, and consecutive-day limits before any application is created.

## When This Screen Is Used

- **Employee leave request** when an employee needs time off and submits an application
- **Approval workflow** when a HOD or Principal reviews pending applications
- **Leave cancellation** when an employee needs to cancel an approved leave before it starts
- **Clarification request** when an approver returns the application for additional information
- **Balance tracking** when checking how approved leave affects remaining entitlement

## Default Data Load

The screen loads as part of the Leave Management tabbed page (`?tab=leave-applications`). `HrMenuController::leaveManagement()` loads applications via `LeaveApplication::with(['employee', 'leaveType'])` ordered by `created_at` desc, paginated at 20 per page using `applications_page`. The standalone `LeaveApplicationController::index()` (line 29) gates with `hrs.leave.apply`, loads with employee/leaveType/academicYear relations, filters by `is_active`, orders by `created_at` desc, paginates at 25 per page — and if the user has no approver permissions, filters only their own applications.

## Key Fields at a Glance

**Employee** — The applicant's identity, loaded from `sch_employees` via the `employee` relationship.

**Leave Type** — The type of leave (Casual, Earned, Sick, Maternity, Paternity, Comp-off, LWP), loaded via `leaveType`.

**Date Range** — `from_date` and `to_date` define the inclusive leave period. These are validated for `after_or_equal:from_date`.

**Days Count** — `days_count` is computed by `LeaveService::calculateDays()`, which excludes Sundays and holidays scoped by the leave type's `applicable_to` category.

**Half Day** — When `half_day = true`, the system sets `days_count` to 0.5 and optionally records which session (`first` or `second`).

**Reason** — The employee's explanation for the leave, validated for minimum 10 characters and maximum 1000.

**Status** — The FSM status: `pending` (initial), `pending_l2` (Level 1 approved, awaiting Level 2), `approved`, `rejected`, `cancelled`, or `returned`.

**Current Approver Level** — Tracks which level of approval is next: 1 for HOD, 2 for Principal.

## Business Rules and Conditions

**7-Step Validation Chain in `LeaveService::applyLeave()`** (lines 158–270):

1. **Leave Type Resolution** — The leave type must exist (`findOrFail`)
2. **Days Calculation** — `calculateDays()` computes working days excluding Sundays and holidays
3. **Balance Check** — For non-LWP leave types, the employee must have sufficient `available_days`. No balance check is performed for LWP (Loss of Pay / leave without pay)
4. **Backdated Window Check** — If the from_date is in the past, it must fall within the policy's `max_backdated_days` window
5. **Overlap Check** — No existing application in `pending`, `pending_l2`, or `approved` status may overlap with the requested date range
6. **Gender Restriction** — If the leave type has a gender restriction (`male` or `female`), the employee's gender must match
7. **Minimum Service Months** — If the leave type requires minimum service months, the employee's joining date must be at least that many months before the leave start date
8. **Medical Certificate** — If the leave type requires a medical certificate and the days exceed the threshold, a `media_id` must be provided
9. **Max Consecutive Days** — The total days must not exceed the leave type's `max_consecutive_days` limit

**FSM States and Transitions:**

- `pending` → `pending_l2`: Level 1 (HOD) approves; only if `approval_levels = 2`
- `pending` → `approved`: Level 1 (HOD) approves; when `approval_levels = 1` (single-level)
- `pending` → `rejected`: Level 1 or Level 2 rejects
- `pending` → `returned`: Level 1 or Level 2 returns for clarification
- `pending` → `cancelled`: Employee cancels before any approval action
- `pending_l2` → `approved`: Level 2 (Principal) approves; balance deducted via `deductBalance()`
- `pending_l2` → `rejected`: Level 2 rejects
- `pending_l2` → `returned`: Level 2 returns for clarification; resets `current_approver_level` to 1
- `pending_l2` → `cancelled`: Employee cancels (same rule as pending)
- `approved` → `cancelled`: Employee cancels only if `from_date > today`; balance is restored
- `returned` → `pending`: Not implemented in the current code (employee must submit a new application)

**Balance Deduction** — Only on final approval (when `current_approver_level >= approval_levels`). The `deductBalance()` private method uses `lockForUpdate()` on the `LeaveBalance` record and increments `used_days`.

**Approval Level Enforcement** — `LeaveApplicationController::authorizeApproval()` checks the application's `current_approver_level` and gates accordingly: Level 1 requires `hrs.leave.approve_l1`; Level 2 requires `hrs.leave.approve_l2`.

**Cancel Rules** — Approved leave can be cancelled only if `from_date > today`. Pending and pending_l2 leave can always be cancelled. Rejected or returned leave cannot be cancelled (the status check fails).

**Own-Application Filter** — In `LeaveApplicationController::index()`, if the user lacks both `hrs.leave.approve_l1` and `hrs.leave.approve_l2`, only their own applications are shown.

## Workflow Steps

1. An employee with leave balance navigates to Leave Management > Leave Applications
2. The employee fills in the leave type, dates, reason, and optionally marks half-day with session, attaches a medical document
3. The employee submits the application
4. The 7-step validation chain runs inside `LeaveService::applyLeave()`
5. On success, the application is created with status `pending` and `current_approver_level = 1`
6. The HOD sees the application in their approval queue and can approve, reject, or return it
7. If approved and `approval_levels = 2`, the status advances to `pending_l2`; the Principal sees it in their queue
8. The Principal approves (final), rejects, or returns the application
9. On final approval, the leave balance is deducted

## Example Scenario

Employee Ananya Gupta (female, 24 months service) applies for 3 days of Sick Leave (Mon-Wed). The system: (1) resolves the leave type (SL, `requires_medical_cert = true`, `threshold = 3`); (2) calculates 3 days (no holidays that week); (3) checks her SL balance (available 10 ≥ 3); (4) checks backdating (not backdated); (5) no overlap; (6) gender restriction is all; (7) service months ≥ 0; (8) medical cert required for 3+ days — she uploaded a certificate; (9) max consecutive (NULL = no limit). The application is created as `pending`. HOD approves → `pending_l2`. Principal approves → `approved`, balance used_days increases by 3.

## Related Screens

- **Leave Balances** — Shows available days per leave type; consumed when leave is approved
- **Leave Policy** — Defines `approval_levels` (1 or 2) that controls FSM depth
- **Leave Types** — Defines per-type rules (carry-forward, gender, medical cert, etc.)
- **Leave Balance Adjustments** — Manual corrections to balance when needed

## Requirements

- `LeaveApplicationController::index()` (line 29) gates with `hrs.leave.apply`, loads applications with relations, filters by `is_active`, paginates 25, applies own-application filter for non-approvers
- `LeaveApplicationController::store()` (line 53) gates with `hrs.leave.apply`, requires employee linked to user, delegates to `LeaveService::applyLeave()`, catches `DomainException` and returns with error flash
- `LeaveApplicationController::show()` (line 81) uses `authorizeView()` helper with 4 conditions: own application, or `hrs.leave.approve_l1`, or `hrs.leave.approve_l2`, or `hrs.employment.manage`
- `LeaveApplicationController::approve()` (line 93) gates via `authorizeApproval()` which checks current level, validates via `ApproveLeaveRequest`, delegates to `LeaveApprovalService::approve()`
- `LeaveApplicationController::reject()` (line 118) same gate pattern, delegates to `LeaveApprovalService::reject()`
- `LeaveApplicationController::cancel()` (line 142) checks employee ownership, delegates to `LeaveService::cancelLeave()`
- `ApproveLeaveRequest` validates: `remarks` (required|string|min:5|max:500); `RejectLeaveRequest` same
- `StoreLeaveApplicationRequest` validates: `leave_type_id` (required|exists), `academic_year_id` (required|exists), `from_date` (required|date), `to_date` (required|date|after_or_equal:from_date), `half_day` (sometimes|boolean), `half_day_session` (nullable|required_if:half_day,true|in:first,second), `reason` (required|string|min:10|max:1000), `media_id` (nullable|exists:sys_media,id)
- `LeaveService::applyLeave()` runs in DB transaction, performs 7-step validation, creates `LeaveApplication`
- `LeaveService::cancelLeave()` runs in DB transaction, restores balance for approved leave (if not yet started)
- `LeaveApprovalService::approve()` runs in DB transaction, writes `LeaveApproval` record, advances FSM or approves final, deducts balance on final approval, fires `LeaveApproved` event
- `LeaveApprovalService::reject()` runs in DB transaction, writes `LeaveApproval` record, sets status to `rejected`, fires `LeaveRejected` event
- `LeaveApprovalService::returnForClarification()` exists in code (but no route in web.php) — sets status to `returned`, resets `current_approver_level` to 1
- `LeaveApproval` model records: `application_id`, `approver_id`, `level`, `action` (approve|reject|return_for_clarification), `remarks`, `actioned_at`
- `LeaveApplication` model has `SoftDeletes`, `$casts` for dates/decimals/integers/booleans, scopes `active()`, `pending()`, `approved()`
- Routes: `hr-staff.applications.index` (GET), `hr-staff.applications.store` (POST), `hr-staff.applications.show` (GET), `hr-staff.applications.approve` (POST), `hr-staff.applications.reject` (POST), `hr-staff.applications.cancel` (POST)
- `LeaveApplicationPolicy` has `viewAny`, `view`, `create`, `approve`, `cancel` methods
- Activity logged for Created, Approved, Rejected, and Cancelled actions

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.leave.apply` | `index()`, `store()` | Employees can apply and view their own |
| `hrs.leave.approve_l1` | `approve()`, `reject()` (when level=1) | HOD role |
| `hrs.leave.approve_l2` | `approve()`, `reject()` (when level=2) | Principal role |
| `hrs.employment.manage` | `show()` | Can view any application |
| `LeaveApplicationPolicy` | All methods | Policy class: `LeaveApplicationPolicy` |

## How This Screen Works — Logic Flow

**Page Load:** `HrMenuController::leaveManagement()` loads applications with employee+leaveType, ordered by `created_at` desc, paginated 20. The `LeaveApplicationController::index()` separately loads applications at 25 per page, filtering by own-employee if user lacks approver permissions.

**Create (Submit):** `LeaveApplicationController::store()` validates via `StoreLeaveApplicationRequest`, requires authenticated user to have an employee record, calls `LeaveService::applyLeave()` inside a try-catch for `DomainException`. The service runs the 7-step validation chain inside a DB transaction. On success, the application is created with `status = pending`, `current_approver_level = 1`, `is_active = true`. Activity logged. Redirects with success flash.

**Approve (L1/L2):** `authorizeApproval()` reads `current_approver_level` from the application model. L1 requires `hrs.leave.approve_l1`; L2 requires `hrs.leave.approve_l2`. `LeaveApprovalService::approve()` writes a `LeaveApproval` record with action `approve`. If `current_approver_level < approval_levels` (from policy), status advances to `pending_l2` and level increments. If final approval, status = `approved`, balance deducted via `deductBalance()`, `LeaveApproved` event fired.

**Reject:** `authorizeApproval()` same gate logic. `LeaveApprovalService::reject()` writes a `LeaveApproval` record with action `reject`, sets status = `rejected`, fires `LeaveRejected` event.

**Cancel:** Employee must be the application owner. `LeaveService::cancelLeave()` checks status: if `approved`, requires `from_date > today` and restores balance by decrementing `used_days`; if `pending` or `pending_l2`, status changes to `cancelled` directly.

## Validate Before Save

**StoreLeaveApplicationRequest:**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `leave_type_id` | `required\|exists:hrs_leave_types,id` | — |
| `academic_year_id` | `required\|exists:sch_org_academic_sessions_jnt,id` | — |
| `from_date` | `required\|date` | — |
| `to_date` | `required\|date\|after_or_equal:from_date` | — |
| `half_day` | `sometimes\|boolean` | — |
| `half_day_session` | `nullable\|required_if:half_day,true\|in:first,second` | — |
| `reason` | `required\|string\|min:10\|max:1000` | — |
| `media_id` | `nullable\|exists:sys_media,id` | — |

**ApproveLeaveRequest / RejectLeaveRequest:**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `remarks` | `required\|string\|min:5\|max:500` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Insufficient balance | "Insufficient leave balance. Available: {n}, Requested: {n}" | `DomainException` |
| No balance found | "No leave balance found for this employee and leave type. Please initialize leave balances first." | `DomainException` |
| Backdate exceeds policy | "Backdated leave exceeds allowed window of {n} days." | `DomainException` |
| Overlap detected | "Leave dates overlap with an existing application." | `DomainException` |
| Gender restriction | "This leave type is not applicable for your gender." | `DomainException` |
| Minimum service not met | "This leave type requires {n} months of service; you have {n}." | `DomainException` |
| No joining date | "Employee joining date is not recorded." | `DomainException` |
| Medical cert required | "Medical certificate is required for {leave_type} exceeding {n} day(s)." | `DomainException` |
| Max consecutive days | "Exceeds maximum consecutive days of {n}." | `DomainException` |
| No employee record | "No employee record linked to your account." | 403 abort |
| Cannot approve status | "Cannot approve a leave with status: {status}" | `DomainException` |
| Cannot reject status | "Cannot reject a leave with status: {status}" | `DomainException` |
| Cannot cancel status | "Cannot cancel a leave with status: {status}" | `DomainException` |
| Cannot cancel started approved | "Cannot cancel approved leave that has already started." | `DomainException` |
| Cannot cancel own (not owner) | "You can only cancel your own applications." | 403 abort |
| Invalid approver level | "Invalid approver level." | 403 abort |
| Success (submit) | "Leave application submitted successfully." | Flash success |
| Success (approve) | "Leave application approved." | Flash success |
| Success (reject) | "Leave application rejected." | Flash success |
| Success (cancel) | "Leave application cancelled." | Flash success |

## Success Scenarios

**SC-001 — Submit leave application** — Employee submits SL for 2 days with reason "Fever". System validates and creates record with status `pending`. Flash: "Leave application submitted successfully."

**SC-002 — Two-level approval flow** — HOD approves pending application (status → `pending_l2`). Principal approves (status → `approved`); balance `used_days` increments.

**SC-003 — Single-level approval** — Policy has `approval_levels = 1`. HOD approves pending application directly (status → `approved`); balance deducted.

**SC-004 — Cancel pending leave** — Employee cancels own pending application. Status → `cancelled`. No balance impact (balance never deducted for non-approved).

**SC-005 — Cancel approved leave (future)** — Employee cancels approved leave starting next week. Status → `cancelled`, balance `used_days` decremented.

**SC-006 — Reject at L2** — HOD approves (→ pending_l2). Principal rejects. Status → `rejected`. No balance impact.

## Failure Scenarios

**FC-001 — Insufficient balance** — Employee has 2 available days but applies for 5. `DomainException`: "Insufficient leave balance. Available: 2, Requested: 5"

**FC-002 — Overlapping leave** — Employee already has approved leave for March 15-20, applies for March 18-22. `DomainException`: "Leave dates overlap with an existing application."

**FC-003 — Backdated too far** — Policy allows 3 backdated days. Employee applies for leave 10 days ago. `DomainException`: "Backdated leave exceeds allowed window of 3 days."

**FC-004 — Cancel already started approved leave** — Employee's approved leave started yesterday, tries to cancel. `DomainException`: "Cannot cancel approved leave that has already started."

**FC-005 — Non-owner cancel** — Employee A tries to cancel Employee B's application. 403: "You can only cancel your own applications."

**FC-006 — Approve rejected leave** — Approver tries to approve a rejected application. `DomainException`: "Cannot approve a leave with status: rejected"

**FC-007 — Gender mismatch** — Male employee tries to apply for Maternity Leave (gender_restriction = female). `DomainException`: "This leave type is not applicable for your gender."

**FC-008 — Service months not met** — Employee with 3 months service tries to apply for Earned Leave (requires 6 months). `DomainException`: "This leave type requires 6 months of service; you have 3."

**FC-009 — Medical certificate missing** — Employee applies for 5 days SL without uploading a medical certificate. `DomainException`: "Medical certificate is required for Sick Leave exceeding 3 day(s)."

**FC-010 — Exceeds consecutive days** — Leave type max_consecutive_days = 5, employee applies for 7. `DomainException`: "Exceeds maximum consecutive days of 5."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `LeaveType` | FK parent | `leave_type_id` → `hrs_leave_types.id` (RESTRICT) |
| `Employee` | FK parent | `employee_id` → `sch_employees.id` (CASCADE) |
| `OrganizationAcademicSession` | FK parent | `academic_year_id` → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `sys_media` | FK parent | `media_id` → `sys_media.id` (RESTRICT) |
| `LeaveBalance` | FK parent (logical) | Read by `applyLeave()` for balance check; written by `deductBalance()` on final approval |
| `LeavePolicy` | FK parent (logical) | Read by `applyLeave()` for backdated window; read by `approve()` for approval_levels |
| `LeaveApproval` | Child table | HasMany from `LeaveApplication`; FK `hrs_leave_approvals.application_id` (CASCADE) |
| `HolidayService` | Service | Used by `LeaveService::calculateDays()` |
| `LeaveService` | Service | `applyLeave()`, `cancelLeave()`, `calculateDays()` |
| `LeaveApprovalService` | Service | `approve()`, `reject()`, `returnForClarification()` |
| Events | `LeaveApproved`, `LeaveRejected` | Fired on final approval / rejection |

**Table:** `hrs_leave_applications`

| Column | Type | Details |
|--------|------|---------|
| `id` | BIGINT UNSIGNED | PK, Auto Increment |
| `employee_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (CASCADE) |
| `leave_type_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_types.id` (RESTRICT) |
| `academic_year_id` | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` (RESTRICT) |
| `from_date` | DATE | NOT NULL |
| `to_date` | DATE | NOT NULL |
| `half_day` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `half_day_session` | ENUM('first','second') | NULL |
| `days_count` | DECIMAL(5,1) | NOT NULL |
| `reason` | TEXT | NOT NULL |
| `media_id` | INT UNSIGNED | NULL, FK → `sys_media.id` |
| `status` | ENUM('pending','pending_l2','approved','rejected','cancelled','returned') | NOT NULL, DEFAULT 'pending' |
| `current_approver_level` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `updated_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| KEY `idx_hrs_lapp_status` | INDEX | (`status`) |

**Table:** `hrs_leave_approvals`

| Column | Type | Details |
|--------|------|---------|
| `id` | BIGINT UNSIGNED | PK, Auto Increment |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK → `hrs_leave_applications.id` (CASCADE) |
| `approver_id` | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` (RESTRICT) |
| `level` | TINYINT UNSIGNED | NOT NULL |
| `action` | ENUM('approve','reject','return_for_clarification') | NOT NULL |
| `remarks` | TEXT | NOT NULL |
| `actioned_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | BIGINT UNSIGNED | NOT NULL |
| `updated_by` | BIGINT UNSIGNED | NOT NULL |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL (Soft delete) |
