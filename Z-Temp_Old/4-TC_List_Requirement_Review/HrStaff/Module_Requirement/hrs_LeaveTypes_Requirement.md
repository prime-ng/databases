# Leave Types — Business Requirements

## What This Screen Does

The Leave Types screen allows the school to configure and manage the types of leave available to employees. It defines the rules, entitlements, and eligibility criteria for each leave category such as Casual Leave, Earned Leave, Sick Leave, Maternity Leave, and Loss of Pay. Each leave type carries its own allocation, carry-forward policy, gender restrictions, and documentation requirements.

This screen serves as the foundation for the entire leave management subsystem — leave applications, balance tracking, and loss-of-pay reconciliation all reference the leave types configured here.

---

## When This Screen Is Used

- Academic Year Setup when the HR Manager defines which leave categories are active for the upcoming year
- Policy Configuration when the school decides on carry-forward limits, medical certificate thresholds, or half-day permissions per leave type
- Compliance Management when configuring statutory leaves such as Maternity Leave or Sick Leave with specific documentation rules
- Leave Type Activation/Deactivation when a leave type needs to be temporarily disabled without removing historical data

## Default Data Load

The screen is loaded via `HrMenuController@hrMasters()` at route `GET /hr-masters` with tab parameter `tab=leave-types`. The controller loads all leave types from `LeaveType::orderBy('name')`, filtered by search and status when the active tab is `leave-types`. The HrMenuController returns an unfiltered collection (no pagination) to the tabbed view `hrstaff::pages.hr-masters`.

Separately, `LeaveTypeController@index()` at `GET /leave-types` provides a standalone paginated view with 20 records per page, searchable by `name` or `code`, and filterable by `status` (`is_active`).

---

## Key Fields at a Glance

**Identity and Tracking**
Each leave type is identified by a short alphanumeric code such as CL, EL, or SL. A longer descriptive name provides the human-readable label displayed in dropdowns and leave applications. The code is unique across all leave types and cannot be changed once records reference it.

**Entitlement and Carry-Forward**
The Days Per Year defines how many days of this leave an employee is allocated in an academic year. Loss of Pay and Compensatory Off typically have zero days since they are granted ad-hoc. Carry Forward Days caps how many unused days can be moved to the next year, with zero meaning no carry-forward is allowed.

**Eligibility and Applicability**
The Applicable To setting controls which staff category (All, Teaching, or Non-Teaching) can apply for this leave. Gender Restriction further narrows eligibility to All, Male, or Female — used for Maternity and Paternity Leave. Minimum Service Months enforces a waiting period before an employee becomes eligible, commonly set to six months for Earned Leave.

**Documentation and Usage Rules**
The Requires Medical Cert flag forces the employee to attach a medical certificate when applying. The Medical Cert Threshold Days sets the absence duration beyond which a certificate is mandatory, typically three days for Sick Leave. Half Day Allowed permits half-day leave applications. Max Consecutive Days imposes a ceiling on continuous absence per application, with null meaning no limit.

---

## Business Rules and Conditions

**Unique Code Enforcement**
Every leave type must have a unique code. The system enforces this with a database unique index. On update, the current record's code is excluded from the uniqueness check.

**Zero-Days Leave Types**
Leave types with zero Days Per Year (LWP and CO) cannot be automatically allocated. They are granted manually or assigned via leave policy configuration.

**Gender Restriction to Default**
Gender restriction defaults to All. When set to Male or Female, employees of the opposite gender cannot see or apply for that leave type in their leave application dropdowns.

**Leave Balance Dependency**
A leave type cannot be deleted if there are existing leave balance records referencing it. The system blocks soft-deletion in the controller by checking `leaveBalances()->exists()`.

---

## Workflow Steps

**Creating a New Leave Type**
The HR Manager navigates to the HR Masters tab group and selects Leave Types. They click Add and enter a code (e.g., CL), name (Casual Leave), days per year (12), carry-forward limit (0), applicable staff category (All), set it as paid, and leave medical cert requirements as default. They save the record and the system creates the leave type with the creator and updater set to the current user.

**Editing a Leave Type**
The HR Manager clicks Edit on an existing leave type, adjusts the carry-forward limit from 0 to 5, enables half-day allowed, and saves. The system updates the record and logs the change.

---

## Example Scenario

A school in Himachal Pradesh runs three types of leave: Casual Leave (12 days, no carry-forward, all staff), Earned Leave (30 days with 15 carry-forward, teaching staff only after 6 months service), and Sick Leave (15 days, requires medical certificate for absences over 3 days, all staff). The HR Manager configures all three in the Leave Types screen. Later, a female teacher applies for Maternity Leave; the HR Manager adds a new leave type with code ML, gender restriction set to Female, and 180 days allocation.

---

## Related Screens

- **Leave Balances** — Displays employee-wise allocation and consumption of each leave type
- **Leave Applications** — Employees apply for leave against configured leave types
- **Leave Policy** — School-wide leave rules referencing these leave types

---

## Requirements

- Controller `LeaveTypeController`: `index()` loads paginated grid; `store()` creates with validated + `created_by`/`updated_by`; `show()` displays single; `edit()` loads edit form; `update()` updates with validated + `updated_by`; `toggleStatus()` flips `is_active` via JSON; `destroy()` guards on `leaveBalances()->exists()`, sets `is_active=false` before soft-delete; `trashed()` lists soft-deleted; `restore()` restores and sets `is_active=true`; `forceDelete()` permanently deletes
- Gate: `Gate::authorize('hrs.leave_type.manage')` on all controller methods
- Route resource: `leave-types` with `except(['create'])`, plus custom `toggle-status`, `trashed`, `restore`, `force-delete`
- Validation `StoreLeaveTypeRequest`: `code` required, string, max:10, unique on `hrs_leave_types.code` ignoring current ID and null `deleted_at`; `name` required, max:100; `days_per_year` required, numeric, min:0, max:365; `carry_forward_days` required, integer, min:0, max:255; `applicable_to` required, in:all,teaching,non_teaching; `is_paid` required, boolean; `requires_medical_cert` required, boolean; `medical_cert_threshold_days` required, integer, min:1, max:30; `half_day_allowed` required, boolean; `gender_restriction` required, in:all,male,female; `min_service_months` required, integer, min:0, max:60; `max_consecutive_days` nullable, integer, min:1, max:255; `is_active` required, boolean
- `prepareForValidation()`: casts `is_paid` (default true), `requires_medical_cert` (default false), `half_day_allowed` (default false), `is_active` (default true) to boolean
- Model `LeaveType`: SoftDeletes, `$fillable` = 14 fields including `created_by`/`updated_by`; `$casts` for decimal, integer, boolean types; relationships: `leaveBalances()` HasMany, `leaveApplications()` HasMany; scopes: `active()`
- Delete guard: if `leaveBalances()->exists()`, returns back with error "Cannot delete leave type with existing balance records."
- Activity logged via `activityLog()` on `store()` (Created), `update()` (Updated), `destroy()` (Trashed), `restore()` (Restored), `forceDelete()` (Deleted)
- Policy: `LeaveTypePolicy` using single permission `hrs.leave_type.manage` for all gates (viewAny, view, create, update, delete, restore, forceDelete)

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `hrs.leave_type.manage` | `index()`, `store()`, `show()`, `edit()`, `update()`, `toggleStatus()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()` | Single permission gates all operations |
| Policy: `LeaveTypePolicy` | All gates | Single permission string |

## Logic Flow

1. **Page Load** — `HrMenuController@hrMasters()` loads tabbed view; `LeaveTypeController@index()` accessible standalone at `/leave-types`. Gate `hrs.leave_type.manage` enforced. Search by name/code, filter by status applies within the tab group.
2. **Create** — `store()` receives validated data from `StoreLeaveTypeRequest`; `prepareForValidation()` auto-casts booleans. `created_by` and `updated_by` set to `auth()->id()`. Model created via `LeaveType::create()`. Activity logged as Created. Redirect to `hr-staff.menu.hrMasters` with `tab=leave-types` and success flash.
3. **Edit/Update** — `edit()` loads model via route-model-binding. `update()` receives validated data, merges `updated_by`, calls `$leaveType->update()`. Activity logged as Updated. Redirect with success flash.
4. **Status Toggle** — `toggleStatus()` receives AJAX POST, flips `is_active` via `update()`, returns JSON `{success, is_active, message}`.
5. **Delete** — `destroy()` checks `leaveBalances()->exists()` — if true, returns back with error. Otherwise sets `is_active=false`, sets `updated_by`, calls `$leaveType->delete()` soft-delete. Activity logged as Trashed. Redirect with success flash.
6. **Trash/Restore/ForceDelete** — `trashed()` shows soft-deleted records. `restore()` finds via `onlyTrashed()->findOrFail($id)`, restores, sets `is_active=true`. `forceDelete()` finds via `withTrashed()->findOrFail($id)` and permanently removes.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | required, string, max:10, unique:hrs_leave_types,code | The leave code has already been taken. |
| `name` | required, string, max:100 | — |
| `days_per_year` | required, numeric, min:0, max:365 | — |
| `carry_forward_days` | required, integer, min:0, max:255 | — |
| `applicable_to` | required, in:all,teaching,non_teaching | — |
| `is_paid` | required, boolean | — |
| `requires_medical_cert` | required, boolean | — |
| `medical_cert_threshold_days` | required, integer, min:1, max:30 | — |
| `half_day_allowed` | required, boolean | — |
| `gender_restriction` | required, in:all,male,female | — |
| `min_service_months` | required, integer, min:0, max:60 | — |
| `max_consecutive_days` | nullable, integer, min:1, max:255 | — |
| `is_active` | required, boolean | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate code | "The leave code has already been taken." | Validation (code.unique) |
| Delete with balance records | "Cannot delete leave type with existing balance records." | Controller check (redirect back with error) |
| Missing required fields | "The [field] field is required." | Validation |

## Success Scenarios

**SC-001 — Creating a Paid Leave Type**
HR Manager creates Casual Leave with code CL, 12 days per year, 0 carry-forward, applicable to all, paid. System creates the record, logs Created activity, and redirects with "Leave type created successfully."

**SC-002 — Updating Carry-Forward Limit**
HR Manager edits Earned Leave and increases carry-forward from 10 to 15 days. System updates the record, logs Updated activity, and redirects with "Leave type updated successfully."

**SC-003 — Toggling Leave Type Inactive**
HR Manager toggles a leave type to inactive via AJAX. System flips `is_active` to 0, returns JSON `{success: true, is_active: false, message: "Status updated successfully."}`.

**SC-004 — Soft-Deleting a Leave Type**
HR Manager deletes a leave type with no existing leave balances. System sets `is_active=false`, soft-deletes the record, logs Trashed activity, and redirects with "Leave type removed successfully."

## Failure Scenarios

**FC-001 — Delete Blocked by Leave Balances**
HR Manager tries to delete a leave type that has existing leave balance records. System returns back with error "Cannot delete leave type with existing balance records."

**FC-002 — Duplicate Code on Create**
User enters a code that already exists. Validation error: "The leave code has already been taken."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sch_org_academic_sessions_jnt` | FK Table | Referenced via leave balances |
| `hrs_leave_balances` | Child Table | `leave_type_id` FK → blocks delete if exists |
| `hrs_leave_applications` | Child Table | `leave_type_id` FK |
| `hrs_leave_policies` | Consumer | References leave type configurations |
| Activity Log | Consumer | `activityLog()` on CRUD operations |

**Table:** `hrs_leave_types`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| code | VARCHAR(10) | NOT NULL, UNIQUE (uq_hrs_leave_type_code) |
| name | VARCHAR(100) | NOT NULL |
| days_per_year | DECIMAL(5,1) | NOT NULL DEFAULT 0 |
| carry_forward_days | TINYINT UNSIGNED | NOT NULL DEFAULT 0 |
| applicable_to | ENUM('all','teaching','non_teaching') | NOT NULL DEFAULT 'all' |
| is_paid | TINYINT(1) | NOT NULL DEFAULT 1 |
| requires_medical_cert | TINYINT(1) | NOT NULL DEFAULT 0 |
| medical_cert_threshold_days | TINYINT UNSIGNED | NOT NULL DEFAULT 3 |
| half_day_allowed | TINYINT(1) | NOT NULL DEFAULT 0 |
| gender_restriction | ENUM('all','male','female') | NOT NULL DEFAULT 'all' |
| min_service_months | TINYINT UNSIGNED | NOT NULL DEFAULT 0 |
| max_consecutive_days | TINYINT UNSIGNED | NULL DEFAULT NULL |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |
