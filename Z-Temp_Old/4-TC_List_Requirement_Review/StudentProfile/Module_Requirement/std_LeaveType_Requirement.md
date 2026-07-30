# std_LeaveType — Business Requirements

## What This Screen Does

The Leave Type Master screen configures the types of leaves that students can apply for within the Student Leave module. It establishes the leave categories (e.g., Sick Leave, Casual Leave, Emergency Leave) along with their rules — maximum days per application, yearly caps, document requirements, half-day allowance, and advance notice requirements.

This configuration is the foundational building block for all student leave management. Without this setup, students cannot submit leave applications, and the system cannot enforce leave policies or track absenteeism.

---

## When This Screen Is Used

- **System Initialization** configured once during the initial setup of the student profile module to define the standard leave types offered by the institution.
- **Policy Customization** when an administrator wants to modify leave rules such as increasing the maximum days per application, toggling document requirements, or adjusting yearly caps.
- **Leave Application Configuration** when establishing the available leave categories that students will see in the leave application dropdown.

## Default Data Load

This screen is displayed within the Student Leave tab group. When the user navigates to Student Profile → Student Leave, the `StudentLeaveController@index()` loads the page with the `tab=leave-type` query parameter, and the `StudentLeaveTypeController@index()` redirects to that route. The leave type listing appears inside the designated tab panel, paginated according to the module's standard listing configuration.

---

---

## Key Fields at a Glance

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as `SICK` or `CASUAL`, which is referenced throughout the leave application workflow. The Display Name provides the human-readable name shown on leave application forms, like 'Sick Leave' or 'Casual Leave'. A Detailed Description clarifies the purpose and scope of the leave type.

**Leave Limitations**
Max Days Per Application sets the upper boundary for a single leave request (e.g., 15 days). Max Days Per Year enforces an annual cumulative cap (e.g., 30 days) to prevent excessive absenteeism across the academic year.

**Operational Rules**
Requires Document toggles whether a supporting document (medical certificate, letter) must be uploaded during leave application. Allow Half Day permits or restricts half-day leave requests. Advance Notice Days specifies the minimum number of days before the leave start date by which the application must be submitted.

**State Management**
A Status Toggle acts as an active or inactive switch. If deactivated, the leave type disappears from leave application dropdowns across the system and cannot be selected by students.

---

## Business Rules and Conditions

**Code Uniqueness and Reusability**
Each leave type must have a unique code to ensure data integrity during leave application processing. However, soft-deleted codes can be reused — the uniqueness check ignores records where `deleted_at` is not null. This allows a leave type to be deleted and later re-created with the same code after cleanup.

**Cascading Deactivation**
If a leave type is set to inactive, students cannot apply for new leaves of that type. However, existing approved or pending leave applications referencing the inactive type remain intact and are not affected. Historical data integrity is preserved.

**Soft-Delete Dependency Protection**
A leave type that has been referenced by existing leave applications cannot be force-deleted. The system blocks permanent removal to preserve referential integrity. Soft-delete remains allowed at all times.

**Default Value Enforcement**
The system automatically applies sensible defaults via `prepareForValidation()` when fields are not submitted: `max_days_per_application` defaults to 30, `max_days_per_year` defaults to 0 (unlimited), `advance_notice_days` defaults to 0 (no notice required), `requires_document` defaults to `false`, `allow_half_day` defaults to `true`, and `is_active` defaults to `true`.

---

## Workflow Steps

**Creating a New Leave Type**
This is typically a one-time setup performed by System Administrators or HODs. The Academic Administrator reviews the existing leave policies and navigates to the Leave Type tab. They click "Add New" to open the creation form. They enter the code as "EMERGENCY", name as "Emergency Leave", description as "Leave granted for unforeseen personal emergencies", set max days per application to 3, max days per year to 10, require a document, disallow half-day, require 1 day advance notice, and set the status to active. They submit the form. The system validates the input, saves the record, logs the activity, and redirects to the leave type listing where the new type appears.

---

## Example Scenario

A school's academic year is about to begin, and the administration needs to configure leave policies in the system before students start applying.

The administrator first creates a "Sick Leave" type with `SICK` as the code, a 15-day max per application, a 30-day yearly cap, document requirement enabled, half-day allowed, and no advance notice. Next, they create "Casual Leave" with `CASUAL` as the code, a 3-day max per application, a 10-day yearly cap, no document requirement, half-day allowed, and 2 days advance notice.

Throughout the year, when a student falls ill and applies for 5 days of Sick Leave, the system checks against the configured `max_days_per_application` (15) and `max_days_per_year` (30). Since the student has only used 12 days so far this year, 5 more days are within the limit. The application also enforces the document upload requirement.

At year-end, the administrator reviews the leave type usage, soft-deletes an unused "Maternity Leave" type (keeping its history intact), and force-deletes a test type that was never used.

---

## Related Screens

- **Student Leave Application** — The consumer screen where students apply for leave using the leave types defined here
- **Student Leave Report** — The analytics screen that reports leave consumption per student per leave type

---

## Requirements

- The system MUST serve the Index as a redirect to `student-profile.student-leave.index?tab=leave-type` (route: `student-leave-types.index`).
- The system MUST authorize access via `Gate::authorize()` using the appropriate `tenant.leave-type.*` permissions for each operation.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`findOrFail`), destroy (soft-delete), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via `StudentLeaveTypeRequest` FormRequest:
  - `code`: required, string, max:30, unique on `std_leave_types` (ignoring soft-deleted, ignoring self on update)
  - `name`: required, string, max:100
  - `description`: nullable, string, max:255
  - `max_days_per_application`: required, integer, min:0, max:255
  - `max_days_per_year`: required, integer, min:0, max:65535
  - `requires_document`: nullable, boolean
  - `allow_half_day`: nullable, boolean
  - `advance_notice_days`: required, integer, min:0, max:255
  - `is_active`: required, boolean
- The system MUST apply `prepareForValidation()` to set defaults: `max_days_per_application` (30), `max_days_per_year` (0), `advance_notice_days` (0), `requires_document` (false), `allow_half_day` (true), `is_active` (true).
- The system MUST log activities for: Created, Updated, Deleted, Restored, Force Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to `student-leave.index?tab=leave-type` after any CRUD operation with a success flash message.
- The system MUST block force-delete when the leave type is referenced by existing leave applications.
- The system MUST cast `requires_document`, `allow_half_day`, and `is_active` as boolean, and `max_days_per_application`, `max_days_per_year`, `advance_notice_days` as integer.
- The system MUST ignore `created_by` from request body — it is always set to the authenticated user's ID.
- The system MUST return JSON response on `toggleStatus()` with `{success, is_active, message}`.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.leave-type.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus |
| Academic Administrator | `tenant.leave-type.create` + `.view` + `.update` | Create, Edit, View (cannot delete or toggle status) |
| HOD | `tenant.leave-type.viewAny` + `.view` | Read-only (view, show) |
| Student / Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the Student Profile section → Student Leave page. The Index action of `StudentLeaveTypeController` redirects the user to the leave tab: `student-leave.index?tab=leave-type`.
2. `Gate::authorize()` checks the user's permission based on the operation being performed.
3. The system fetches all active Leave Type records (paginated) listed within the leave type tab panel.
4. The user clicks "Add New" to open the creation form. They fill in the required fields and submit.
5. On submit, the FormRequest pre-processes the input via `prepareForValidation()` — setting defaults for any omitted optional fields.
6. The FormRequest validates: code (required, unique, max:30), name (required, max:100), description (nullable, max:255), max_days_per_application (required, 0–255), max_days_per_year (required, 0–65535), requires_document (boolean), allow_half_day (boolean), advance_notice_days (required, 0–255), is_active (required, boolean).
7. If valid, `LeaveService::createLeaveType()` saves the record with `created_by` set to the authenticated user. Activity log records "Created". The system redirects to the leave type tab with a success flash.
8. Existing records can be edited via the edit form; updates go through the same validation (code uniqueness ignores the current record's ID).
9. Deleting a record triggers soft delete — `is_active` is set to `false`, then `delete()` is called. The record remains in the database with `deleted_at` populated.
10. The "Trash" view shows soft-deleted records. From there, the user can restore (which sets `deleted_at` to `null`) or force-delete (permanently removes the record; blocked if leave applications reference it).
11. The `toggleStatus()` action flips `is_active` and returns a JSON response `{success, is_active, message}`.
12. The `show()` view uses `findOrFail($id)` to display the leave type details.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "The code field is required."
2. **Code String** — `code` must be a valid string. Error: "The code must be a string."
3. **Code Max Length** — `code` must not exceed 30 characters. Error: "The code must not exceed 30 characters."
4. **Code Uniqueness** — `code` must be unique in `std_leave_types` table (ignoring soft-deleted records, ignoring the current record on update). Error: "The code has already been taken."
5. **Name Required** — `name` field must not be empty. Error: "The name field is required."
6. **Name String** — `name` must be a valid string. Error: "The name must be a string."
7. **Name Max Length** — `name` must not exceed 100 characters. Error: "The name must not exceed 100 characters."
8. **Description String** — `description` must be a valid string if provided. Error: "The description must be a string."
9. **Description Max Length** — `description` must not exceed 255 characters. Error: "The description must not exceed 255 characters."
10. **Max Days Per Application Required** — `max_days_per_application` must not be empty. Error: "The max days per application field is required."
11. **Max Days Per Application Integer** — `max_days_per_application` must be an integer. Error: "The max days per application must be an integer."
12. **Max Days Per Application Range** — `max_days_per_application` must be between 0 and 255. Error: "The max days per application must be between 0 and 255."
13. **Max Days Per Year Required** — `max_days_per_year` must not be empty. Error: "The max days per year field is required."
14. **Max Days Per Year Integer** — `max_days_per_year` must be an integer. Error: "The max days per year must be an integer."
15. **Max Days Per Year Range** — `max_days_per_year` must be between 0 and 65535. Error: "The max days per year must be between 0 and 65535."
16. **Requires Document Boolean** — `requires_document` is cast to boolean automatically. Defaults to `false`.
17. **Allow Half Day Boolean** — `allow_half_day` is cast to boolean automatically. Defaults to `true`.
18. **Advance Notice Days Required** — `advance_notice_days` must not be empty. Error: "The advance notice days field is required."
19. **Advance Notice Days Integer** — `advance_notice_days` must be an integer. Error: "The advance notice days must be an integer."
20. **Advance Notice Days Range** — `advance_notice_days` must be between 0 and 255. Error: "The advance notice days must be between 0 and 255."
21. **Is Active Required** — `is_active` must not be empty. Error: "The is active field is required."
22. **Is Active Boolean** — `is_active` must be a boolean. Error: "The is active field must be true or false."
23. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "The code field is required." | 422 |
| Code exceeds 30 characters | "The code must not exceed 30 characters." | 422 |
| Duplicate code (already exists, not soft-deleted) | "The code has already been taken." | 422 |
| Name is empty | "The name field is required." | 422 |
| Name exceeds 100 characters | "The name must not exceed 100 characters." | 422 |
| Description exceeds 255 characters | "The description must not exceed 255 characters." | 422 |
| Max days per application is empty | "The max days per application field is required." | 422 |
| Max days per application is negative or > 255 | "The max days per application must be between 0 and 255." | 422 |
| Max days per year is negative or > 65535 | "The max days per year must be between 0 and 65535." | 422 |
| Max days per year exceeds 65535 | "The max days per year must be between 0 and 65535." | 422 |
| Advance notice days is negative or > 255 | "The advance notice days must be between 0 and 255." | 422 |
| Is active is not boolean | "The is active field must be true or false." | 422 |
| Invalid id (show/edit/update/destroy/restore) | "No query results for model [LeaveType]." | 404 |
| Force-delete on non-trashed record | "No query results for model [LeaveType]." | 404 |
| Force-delete while referenced by leave applications | Database constraint violation (foreign key check) | 409 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |

---

## Success Scenarios

**SC-001: Creating a New Leave Type**
1. Admin navigates to Student Profile → Student Leave → Leave Type tab → clicks "Add New".
2. Enters Code: "SICK", Name: "Sick Leave", Description: "Leave for medical reasons", Max Days Per Application: 15, Max Days Per Year: 30, Requires Document: Yes, Allow Half Day: Yes, Advance Notice Days: 0, Status: Active.
3. System validates all rules, defaults applied for any omitted fields, saves the record with `created_by` set to the authenticated user.
4. Activity log records "Created". System redirects to the leave type tab with success message and the new record displayed.

**SC-002: Toggling a Leave Type Status**
1. Admin finds an existing active leave type and clicks the toggle status button.
2. System sends a POST request to the `toggleStatus` endpoint.
3. System flips `is_active` from `true` to `false`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
4. The leave type is hidden from active dropdowns in leave applications. Existing applications remain unaffected.

**SC-003: Restoring a Soft-Deleted Leave Type**
1. Admin navigates to the "Trash" view and clicks "Restore" on a deleted record.
2. System sets `deleted_at` to `null`.
3. Activity log records "Restored". The record reappears in the active list with its original settings preserved.

**SC-004: Reusing a Soft-Deleted Code**
1. Admin soft-deletes a leave type with code "TEMP".
2. Later, admin creates a new leave type with code "TEMP".
3. System uniqueness check ignores soft-deleted records — validation passes.
4. New record is created successfully with the previously used code.

---

## Failure Scenarios

**FC-001: Duplicate Code Rejected**
1. Admin attempts to create a new leave type with code "SICK" when a record with the same code already exists (and is not soft-deleted).
2. System validation fails with error: "The code has already been taken."
3. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Max Days Per Application Out of Range**
1. Admin enters Max Days Per Application as "300" (exceeds the maximum of 255).
2. System validation fails with error: "The max days per application must be between 0 and 255."
3. Record is not saved. Admin must correct the value to a valid range.

**FC-003: Force Delete Blocked Due to Existing References**
1. Admin attempts to force-delete a leave type that has been used in existing leave applications.
2. System detects the referential constraint and blocks the operation.
3. Error is returned preventing permanent deletion. Admin can only soft-delete the record.

**FC-004: Unauthorized Access Attempt**
1. A Teacher (who lacks `tenant.leave-type.*` permissions) directly navigates to the leave type management URL.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

**FC-005: Invalid ID on Show/Edit/Update/Destroy**
1. Admin attempts to view or edit a leave type with a non-existent ID.
2. `findOrFail()` throws a `ModelNotFoundException`.
3. System returns HTTP 404.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `std_leave_types` | `id`, `code` VARCHAR(30) UNIQUE, `name` VARCHAR(100), `description` VARCHAR(255), `max_days_per_application` TINYINT UNSIGNED, `max_days_per_year` SMALLINT UNSIGNED, `requires_document` TINYINT(1), `allow_half_day` TINYINT(1), `advance_notice_days` TINYINT UNSIGNED, `is_active` TINYINT(1), `created_by` BIGINT UNSIGNED, `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `std_leave_applications` (leave_applications relationship via LeaveType model — hasMany) | FK references `std_leave_types.id`; blocks force-delete when referenced |
| Related Model | `User` (created_by relationship — belongsTo) | `std_leave_types.created_by` REFERENCES `users.id` |
| Module Dependency | StudentProfile Module | Core module where this master data is configured via `/student-profile/student-leave-types` routes |
| Module Dependency | Student Leave Module | Consumes leave types for student leave application forms and approval workflows |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.leave-type.*` permissions |
