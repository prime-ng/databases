# Leave Policy — Business Requirements

## What This Screen Does

The Leave Policy screen lets the school configure global leave rules that apply to all employees. It is a single-record configuration panel — there is exactly one active policy at any time. The policy controls backdated application windows, advance notice requirements, approval hierarchy depth (one or two levels), and the number of optional holidays an employee may elect per year.

## When This Screen Is Used

- **Initial setup** when the school begins using the HR module for the first time
- **Policy revision** when the school changes its leave rules (e.g., switching from 1-level to 2-level approval, or adjusting the backdated window)
- **Academic year rollover** when confirming whether the existing policy carries forward or needs adjustment

## Default Data Load

The screen loads via `GET /leave-policy` (`hr-staff.leave-policy.show`) handled by `LeaveController::policy()` at lines 27–35. The controller gates the request with `hrs.leave_type.manage`. It queries `LeavePolicy::active()->globalDefault()->first()` — the single active policy with `academic_year_id = NULL`. It also loads `OrganizationAcademicSession` options for the academic year dropdown. The policy is rendered on the Leave Management tabbed page under the `?tab=leave-policy` tab.

## Key Fields at a Glance

**Backdated Application Window** — `max_backdated_days` defines how many days into the past an employee may apply for leave (default 3). A value of 0 disables backdated applications entirely.

**Advance Notice** — `min_advance_days` sets how many days before the leave start date an application must be submitted (default 0).

**Approval Levels** — `approval_levels` determines whether a leave application needs one approval (HOD only, value 1) or two (HOD + Principal, value 2). This is checked at runtime by `LeaveApprovalService`.

**Optional Holiday Count** — `optional_holiday_count` defines how many optional holidays (e.g., festival of choice) each employee may elect per year (default 2).

**Academic Year Scope** — When `academic_year_id` is NULL, the policy acts as the global default for all years. When set, it overrides for a specific academic year.

## Business Rules and Conditions

**Single Active Policy** — The system enforces one active global default policy via the `globalDefault()` scope (`academic_year_id IS NULL`). There is no uniqueness constraint at the DB level; the application layer retrieves the first matching record via `first()`.

**Policy Creation on First Save** — When no policy exists and the first update is submitted, the system creates a new policy record with `created_by` set to the current authenticated user and `academic_year_id` set to the current academic session.

**Idempotent Updates** — Subsequent policy updates always modify the existing global default record; they never create duplicates.

**Approval Levels Govern FSM** — The `approval_levels` value (1 or 2) directly controls the leave application state machine. A value of 1 bypasses Level 2 approval; a value of 2 requires sequential HOD then Principal approval.

## Workflow Steps

1. The HR Manager navigates to Leave Management > Leave Policy tab
2. The form pre-fills with the current active policy values (or defaults if no policy exists yet)
3. The HR Manager adjusts `max_backdated_days`, `min_advance_days`, `approval_levels`, and `optional_holiday_count`
4. The form is submitted via `PUT /leave-policy`
5. The system validates via `UpdateLeavePolicyRequest` and updates the existing policy or creates a new one
6. A success flash message "Leave policy updated successfully." is shown

## Example Scenario

The school principal decides that all future leave applications must be submitted at least 2 days in advance. The HR Manager navigates to the Leave Policy tab, changes `min_advance_days` from 0 to 2, and saves. The next day, when an employee tries to apply for leave starting tomorrow, the system rejects the application with "Backdated leave exceeds allowed window" (or the advance-days validation catches it depending on the date comparison logic).

## Related Screens

- **Leave Types** — Defines the per-leave-type parameters (days per year, carry-forward, gender restriction) that the policy complements
- **Leave Applications** — Consumes the policy's `approval_levels` to determine the approval FSM depth

## Requirements

- `LeaveController::policy()` (line 27) returns the view with the single active global default policy
- `LeaveController::updatePolicy()` (line 40) handles `PUT /leave-policy` gated by `hrs.leave_type.manage`
- `UpdateLeavePolicyRequest` validates: `max_backdated_days` (required|integer|min:0|max:30), `min_advance_days` (required|integer|min:0|max:30), `approval_levels` (required|integer|in:1,2), `optional_holiday_count` (required|integer|min:0|max:10), `is_active` (required|boolean)
- `prepareForValidation()` in the request casts `is_active` to boolean
- On update, `updated_by` is set to `auth()->id()`; on create, `created_by` is also set
- Newly created policies get `academic_year_id` from the current academic session
- An activity log entry "Leave policy updated." is recorded on every update
- The controller redirects to `hr-staff.menu.leaveManagement?tab=leave-policy` with a success flash message
- The model uses `SoftDeletes` and has `$casts` for integer/boolean fields
- The route name is `hr-staff.leave-policy.show` (GET) and `hr-staff.leave-policy.update` (PUT)

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.leave_type.manage` | `policy()`, `updatePolicy()` | HR Manager role |
| No policy class | — | Authorization done via Gate check directly in controller |

## How This Screen Works — Logic Flow

**Page Load:** `LeaveController::policy()` performs `Gate::authorize('hrs.leave_type.manage')`, then queries `LeavePolicy::active()->globalDefault()->first()` and loads academic year options. Returns `hrstaff::leave.policy` view.

**Update:** `LeaveController::updatePolicy()` validates through `UpdateLeavePolicyRequest`. If a global default policy exists, it updates the record with `updated_by`. Otherwise it creates a new policy with `academic_year_id` from the current academic session, plus `created_by` and `updated_by`. An activity log entry is recorded. The user is redirected with a success flash message.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `academic_year_id` | `nullable\|exists:sch_org_academic_sessions_jnt,id` | — (default Laravel) |
| `max_backdated_days` | `required\|integer\|min:0\|max:30` | — |
| `min_advance_days` | `required\|integer\|min:0\|max:30` | — |
| `approval_levels` | `required\|integer\|in:1,2` | — |
| `optional_holiday_count` | `required\|integer\|min:0\|max:10` | — |
| `is_active` | `required\|boolean` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Validation failure | Standard Laravel validation error per field | Validation rule |
| Success (update) | "Leave policy updated successfully." | Flash success |
| Success (create) | "Leave policy updated successfully." | Flash success |

## Success Scenarios

**SC-001 — Update existing policy** — HR Manager changes `max_backdated_days` from 3 to 5 and `approval_levels` from 2 to 1. The system updates the existing global policy record and redirects with "Leave policy updated successfully."

**SC-002 — First-time policy creation** — No policy exists. HR Manager fills all fields and saves. The system creates a new `hrs_leave_policies` record with `academic_year_id` from the current session and redirects with the same success message.

## Failure Scenarios

**FC-001 — Invalid approval levels** — HR Manager enters `approval_levels` as 3. The request validation fails with "The selected approval levels is invalid."

**FC-002 — Negative backdated days** — HR Manager enters `max_backdated_days` as -1. Validation fails because `min:0` is enforced.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `OrganizationAcademicSession` | FK parent | `academic_year_id` → `sch_org_academic_sessions_jnt.id` (SET NULL at DB level, though app always sets it) |
| `LeaveApplication` | Consumer | `LeaveApprovalService` reads `approval_levels` from policy |
| `LeaveService::applyLeave()` | Consumer | Reads `max_backdated_days` from policy for backdate validation |
| Activity Log | Service | `activityLog()` called on every update |

**Table:** `hrs_leave_policies`

| Column | Type | Details |
|--------|------|---------|
| `id` | BIGINT UNSIGNED | PK, Auto Increment |
| `academic_year_id` | SMALLINT UNSIGNED | NULL, FK → `sch_org_academic_sessions_jnt.id`; NULL = global default |
| `max_backdated_days` | TINYINT UNSIGNED | NOT NULL, DEFAULT 3 |
| `min_advance_days` | TINYINT UNSIGNED | NOT NULL, DEFAULT 0 |
| `approval_levels` | TINYINT UNSIGNED | NOT NULL, DEFAULT 2 |
| `optional_holiday_count` | TINYINT UNSIGNED | NOT NULL, DEFAULT 2 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `updated_by` | BIGINT UNSIGNED | NOT NULL, → `sys_users.id` |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| Key `fk_hrs_lvpol_ayid` | INDEX | (`academic_year_id`) → FK `sch_org_academic_sessions_jnt`(`id`) |
