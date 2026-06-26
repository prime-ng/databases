# Leave Applications & Approvals — Requirements

## What It Does
End-to-end leave application workflow: submission, 2-level approval/rejection, cancellation. Validates balance sufficiency, consecutive day limits, backdated/advance notice rules, overlapping leaves, and half-day sessions. Supports medical certificate attachment via Spatie Media Library. Fires LeaveApproved/LeaveRejected events on final action.

Features:
- 2-level approval state machine (pending → pending_l2 → approved)
- Half-day with session selection (first half / second half)
- Medical certificate upload with threshold-based requirement
- Balance validation at submission time
- Overlapping leave detection
- Consecutive leave detection across applications
- LeaveApproved / LeaveRejected events on final actions
- Soft-delete with status tracking

## Database Fields

**hrs_leave_applications**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. |
| `leave_type_id` | BIGINT UNSIGNED FK → `hrs_leave_types` | Required. |
| `academic_year_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `from_date` | DATE | Required. Leave start date. |
| `to_date` | DATE | Required. Leave end date. Must be after or equal to from_date. |
| `half_day` | BOOLEAN | Default false. Whether this is a half-day leave. |
| `half_day_session` | ENUM | `first`, `second`. Required when half_day = true. Which half of the day. |
| `days_count` | DECIMAL(4,1) | Computed. Total leave days including half-day fraction (0.5 for half-day). |
| `reason` | TEXT | Required. Min 10 chars, max 1000 chars. |
| `media_id` | BIGINT UNSIGNED FK → `sys_media` | Nullable. Medical certificate or supporting document. |
| `status` | ENUM | `pending`, `pending_l2`, `approved`, `rejected`, `cancelled`, `returned`. |
| `current_approver_level` | INTEGER | 1 or 2. Tracks which level needs to act next. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_leave_approvals**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `application_id` | BIGINT UNSIGNED FK → `hrs_leave_applications` | Required. CASCADE on delete. |
| `approver_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. The employee who acted. |
| `level` | INTEGER | 1 or 2. Which approval level this action belongs to. |
| `action` | ENUM | `approve`, `reject`, `return_for_clarification`. |
| `remarks` | VARCHAR(255) | Required for reject/return. Optional for approve. |
| `actioned_at` | DATETIME | When the action was taken. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Days Count Calculation**
- Computed by `LeaveService::calculateDays()`: counts calendar days from from_date to to_date
- Sundays are excluded (configurable via holiday calendar)
- School holidays listed in holiday calendar are also excluded
- Half-day: counts as 0.5 days
- Full day: counts as 1.0 days

**Leave Application Validation Chain**
1. **Balance Check**: `available_days >= days_count` for the requested leave type
2. **Overlap Check**: No existing approved/pending application overlaps the date range for the same employee
3. **Consecutive Limit Check**: If leave type has `max_consecutive_days`, `days_count` must not exceed it
4. **Backdated Check**: `from_date` must not be more than `policy.max_backdated_days` in the past
5. **Advance Notice Check**: Application must be submitted at least `policy.min_advance_days` before `from_date`
6. **Medical Certificate Check**: Required if `leave_type.requires_medical_cert` and threshold exceeded
7. **Gender Restriction Check**: Employee's gender must match `leave_type.gender_restriction`
8. **Service Months Check**: Employee must have served at least `leave_type.min_service_months`
9. **Leave Type Applicability**: Employee category (teaching/non-teaching) must match `leave_type.applicable_to`

**Approval State Machine**
```
                         ┌──────────────────┐
                         │     pending       │  (Level 1 pending)
                         └────────┬─────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    ▼             ▼             ▼
            ┌──────────┐  ┌──────────┐  ┌──────────┐
            │ rejected │  │ returned │  │pending_l2│  (if 2-level)
            └──────────┘  └──────────┘  └────┬─────┘
                                              │
                                    ┌─────────┼─────────┐
                                    │         │         │
                                    ▼         ▼         ▼
                            ┌──────────┐ ┌──────────┐ ┌──────────┐
                            │approved  │ │ rejected │ │ returned │
                            └──────────┘ └──────────┘ └──────────┘
```

- **Level 1 (Direct Manager)**: `pending` → approve (`pending_l2` or `approved`), reject (`rejected`), or return (`returned`)
- **Level 2 (Higher Authority)**: `pending_l2` → approve (`approved`), reject (`rejected`), or return (`returned`)
- **Return**: Application goes back to employee for clarification. Employee can resubmit (status returns to `pending` or `pending_l2` depending on policy).

**Balance Deduction Timing**
- For single-level approval: balance deducted when level 1 approves → `approved`
- For two-level approval: balance deducted when level 2 approves → `approved`
- On rejection: no balance impact
- On cancellation: balance restored (used_days -= days_count)
- On return: no balance impact (was never deducted)

**Cancellation Rules**
- Employee can cancel their own application only if status is `pending` or `pending_l2`
- Once approved, cancellation requires HR admin action
- Cancellation restores the leave balance

**Events Fired**
- `LeaveApproved`: fired when status changes to `approved` (on final approval)
- `LeaveRejected`: fired when status changes to `rejected`

**Medical Certificate Handling**
- If `leave_type.requires_medical_cert = true` and `days_count > medical_cert_threshold_days`: certificate is mandatory
- File upload via `media_id` FK to `sys_media`
- Without the upload, the form submission is rejected at validation

## CRUD Operations

**List Leave Applications**
- Tabbed interface: My Applications, Pending Approvals, All Applications
- Filters: status, date range, leave type, employee
- Columns: employee, leave type, dates, days, status, approval progress

**Create Leave Application**
- Leave type dropdown only shows types where employee is eligible
- Date range picker with day count auto-calculation
- Half-day toggle shows session selector (first/second half)
- Medical certificate upload shown conditionally
- On success: redirect to application list

**Show Leave Application**
- Full detail view with approval timeline
- Shows: employee info, leave type, date range, duration, reason, attached documents
- Approval history: who acted, what action, when, remarks

**Approve Leave**
- If 2-level and level 1 approves: status → `pending_l2`, level incremented
- If 1-level or level 2 approves: status → `approved`, balance deducted
- `LeaveApproved` event fired on final approval

**Reject Leave**
- Status → `rejected`
- `LeaveRejected` event fired

**Cancel Leave**
- Only allowed if status is `pending` or `pending_l2`
- Status → `cancelled`
- If balance was already deducted (shouldn't happen for pending), it's restored

## Permissions

| Operation | Permission Key |
|---|---|
| View all applications | `hrs.leave.apply` |
| Create own application | `hrs.leave.apply` |
| Approve level 1 | `hrs.leave.approve_l1` |
| Approve level 2 | `hrs.leave.approve_l2` |
| Cancel own pending application | Always allowed |
