# Performance Categories — Business Requirements

## What This Screen Does

The Performance Categories screen is the intelligent engine driving automated remedial actions in the system. While traditional software just prints grades on a report card, this screen maps specific percentage ranges to qualitative labels and binds them to automated AI Triggers. 

When a student's performance falls into one of these percentage bands, this screen dictates exactly what the system should do next—whether to escalate an alert to a parent, push extra practice material, or mandate an automated re-test.

---

## When This Screen Is Used

- System Setup configured by the academic heads to define what numerically constitutes a Good or Poor score
- Workflow Automation when configuring the system's reaction to test results
- Adaptive Testing when defining rules for the auto-assignment of remedial homework to struggling students

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Identity and Academic Meaning**
A Short Code and Display Name act as a unique identifier and the text displayed on screen. A Performance Rank captures the hierarchical rank of the performance band, used for sorting and color-coding logic on dashboards. The Score Band defines the exact numerical minimum and maximum percentage range, such as 33.00% to 45.99%.

**Automation Settings**
An AI Severity dropdown determines the urgency of the notification sent to teachers or parents, with options like Low, Medium, High, or Critical. An AI Default Action dropdown defines the system's automated response, with options like Accelerate, Progress, Practice, Remediate, or Escalate. An Auto-Retest Required Toggle allows the system to bypass the teacher and automatically query the Question Bank to build and assign a remedial test on the failed topic.

**Application Scope**
A Display Order and Color Code determines how reports are visually rendered, such as Red for Poor or Green for Topper. A Scope Rule determines if this specific performance rule applies to the whole School or just a specific Class. A System Lock Toggle prevents schools from breaking core logic if the percentages are locked by the educational board.

---

## Business Rules and Conditions

**Non-Overlapping Validations**
The system must ensure that percentage ranges do not overlap. Before saving a new category, the system must check all existing active categories within the same scope. It must reject the input if the new range overlaps with an existing one, preventing a student from falling into two different performance categories simultaneously.

**Scope Precedence**
Schools often have different definitions of success for different age groups. If a global rule states that a Topper is 90-100%, but a Class-specific rule states that for Grade 1 a Topper is 95-100%, the system logic must always apply the most specific scope over the broader rule.

---

## Workflow Steps

**Adding a New Performance Category**
The Academic Director opens Performance Categories and clicks Add Category. They enter the Name as "Critical Intervention Required" and provide a Short Code. They define the Range with a minimum of 0.00% and a maximum of 32.99%. They set the AI Severity to Critical and the AI Default Action to Escalate. They enable the Auto-Retest Required toggle and set the Scope to apply School-wide. Upon saving, the system validates that the range does not overlap with existing bands and saves it successfully.

---

## Example Scenario

A Class 9 student completes an online Quiz on Thermodynamics and scores 28%. 

The Assessment Engine calculates the score and checks the Performance Categories table. It finds that 28% falls into the Critical Intervention Required band. 

Because the Severity is set to Critical, the system instantly triggers an alert on the teacher's mobile app. Because the Action is set to Escalate, an automated email is drafted and sent to the parents. Because the Auto-Retest toggle is enabled, the system silently accesses the Question Bank, pulls 10 new easy questions on Thermodynamics, packages them into a Remedial Quiz, and pushes it to the student's portal with a deadline of 48 hours. All of this happens without any human intervention.

---

## Related Screens

- **Grade Divisions Master** — A similar concept, but strictly used for official report card printing rather than automated actions
- **Syllabus Reports** — Uses the color codes defined here to render the progress trackers on the dashboard

---

## Requirements

- This screen loads exclusively via the Syllabus Master tab view at GET /syllabus/master (route: syllabus.master.index). The individual controller index route is internal and not directly accessible.
- The system MUST authorize access via `Gate::authorize()` using the `tenant.performance-category.viewAny` permission.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`withTrashed()->findOrFail`), destroy (soft-delete: sets `is_active = false` then calls `delete()`), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via FormRequest:
  - `code`: required, string, max:20, unique on `slb_performance_categories` (scoped by `scope`)
  - `name`: required, string, max:100
  - `description`: nullable, string, max:255
  - `level`: required, integer, min:1, max:255
  - `min_percentage`: required, numeric, min:0, max:100
  - `max_percentage`: required, numeric, min:0, max:100, gt:min_percentage
  - `ai_severity`: nullable, in:LOW,MEDIUM,HIGH,CRITICAL (default LOW)
  - `ai_default_action`: required, in:ACCELERATE,PROGRESS,PRACTICE,REMEDIATE,ESCALATE
  - `display_order`: nullable, integer, min:1, max:65535 (default 1)
  - `color_code`: nullable, string, max:10
  - `icon_code`: nullable, string, max:50
  - `scope`: required, in:SCHOOL,CLASS
  - `class_id`: nullable, required_if:scope,CLASS
  - `is_system_defined`: nullable, boolean
  - `auto_retest_required`: nullable, boolean
- The system MUST perform a custom after-validation check: overlapping percentage range detection for active records within the same scope.
- The system MUST protect system-defined records (`is_system_defined = true`) from being modified, deleted, or having their status toggled.
- The system MUST apply `prepareForValidation()` to uppercase `code` via `strtoupper()` and cast boolean fields.
- The system MUST paginate results at 10 per page.
- The system MUST log activities for: Stored, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to route `syllabus.master.index` with tab `performance_categories` after any CRUD operation.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.performance-category.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus (system-defined records are read-only) |
| Academic Director | `tenant.performance-category.viewAny` + `.view` | Read-only (view, show) |
| HOD | `tenant.performance-category.viewAny` + `.view` + `.create` + `.update` | Create and Edit (cannot delete/toggle; system-defined records read-only) |
| Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the aggregate Syllabus master page; the Performance Categories tab triggers the `index()` controller.
2. The screen loads as a tab within the Syllabus Master tab view. Then `Gate::authorize()` checks the user's permission.
3. The system fetches all Performance Category records (including soft-deleted) paginated at 10 per page.
4. The user clicks "Add New" to open the creation form with fields: Code, Name, Level, Min/Max Percentage, AI Severity, AI Default Action, Scope (School/Class), Class (if scope=CLASS), Display Order, Color Code, Icon Code, Auto Retest Required, and Status.
5. The system pre-processes the input via `prepareForValidation()` — uppercasing the code and casting boolean fields.
6. On submit, the FormRequest validates all rules including: code uniqueness scoped by scope, max_percentage > min_percentage, class_id required when scope=CLASS, valid enum values, numeric ranges, and an after-validation hook checks for overlapping percentage ranges with existing active records in the same scope.
7. If valid, the record is saved and an activity log entry "Stored" is created. The system redirects to the Performance Categories tab.
8. Existing records can be edited. System-defined records (`is_system_defined = true`) display a lock icon; the update controller checks the guard and redirects with an error if modification is attempted.
9. Deleting a record triggers soft delete: `is_active` is set to `false`, then `delete()` is called. System-defined records are protected from deletion and toggleStatus.
10. The "Trashed" view shows soft-deleted records for restoration or force-deletion (system-defined records are also protected from forceDelete).
11. The `toggleStatus()` action flips `is_active` and returns a JSON response `{success, is_active, message}`. System-defined records return HTTP 403 with an error message.
12. The `show()` view uses `withTrashed()->findOrFail($id)` to display both active and trashed records.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "Performance category code is required."
2. **Code Uniqueness (Scoped)** — `code` must be unique in `slb_performance_categories` within the same `scope`. Error: "This performance category code already exists for the selected scope."
3. **Code Uppercase** — `code` is automatically uppercased via `strtoupper()` in `prepareForValidation()`.
4. **Name Required** — `name` field must not be empty.
5. **Name Max Length** — `name` must not exceed 100 characters.
6. **Level Required** — `level` must be an integer between 1 and 255.
7. **Min Percentage** — `min_percentage` is required, numeric, between 0 and 100.
8. **Max Percentage** — `max_percentage` is required, numeric, between 0 and 100.
9. **Max > Min** — `max_percentage` must be greater than `min_percentage`. Error: "Maximum percentage must be greater than minimum percentage."
10. **AI Severity** — Must be one of: LOW, MEDIUM, HIGH, CRITICAL (nullable, defaults to LOW).
11. **AI Default Action** — Required and must be one of: ACCELERATE, PROGRESS, PRACTICE, REMEDIATE, ESCALATE.
12. **Scope** — Required and must be SCHOOL or CLASS.
13. **Class Required If Scope CLASS** — When scope=CLASS, `class_id` must be provided. Error: "Class is required when scope is CLASS."
14. **Display Order** — Nullable integer between 1 and 65535 (defaults to 1).
15. **Range Overlap (Custom After-Validation)** — The system checks that the new (min_percentage, max_percentage) range does not overlap with any existing active record in the same scope. Error: "The percentage range overlaps with an existing active performance category."
16. **Is System Defined Guard** — If `is_system_defined` is true, the record is protected from edit, delete, forceDelete, and toggleStatus.
17. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "Performance category code is required." | 500 |
| Duplicate code in same scope | "This performance category code already exists for the selected scope." | 500 |
| Max <= Min | "Maximum percentage must be greater than minimum percentage." | 500 |
| Scope is CLASS without class_id | "Class is required when scope is CLASS." | 500 |
| Range overlap with existing active record | "The percentage range overlaps with an existing active performance category." | 500 |
| Edit system-defined record | "System-defined question types cannot be modified." | 403 |
| Delete system-defined record | "System-defined question types cannot be deleted." | 403 |
| Toggle status on system-defined record | "System-defined question types status cannot be changed." | 403 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |


---

## Success Scenarios

**SC-001: Creating a New Performance Category**
1. Admin navigates to the Syllabus master page → Performance Categories tab → clicks "Add New".
2. Enters Code: "CRITICAL", Name: "Critical Intervention Required", Level: 1, Min: 0.00, Max: 32.99, AI Severity: CRITICAL, AI Default Action: ESCALATE, Scope: SCHOOL, Status: Active.
3. System uppercases code, validates no range overlap, saves the record.
4. Activity log records "Stored". The new category is active; any student scoring below 33% will trigger the configured escalation workflow.

**SC-002: Deactivating a Performance Category**
1. Admin finds an existing active non-system category and clicks the toggle status button.
2. System sends a POST request to the `toggleStatus` endpoint.
3. System flips `is_active`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
4. The category no longer triggers automated actions. Historical data is preserved for reports.

**SC-003: Adding a Class-Scoped Performance Category**
1. Admin creates a category with Scope: CLASS, selects "Grade 1-A", enters Min: 95.00, Max: 100.00.
2. System validates `class_id` is present, checks no overlapping range within the CLASS scope for that class, saves.
3. When evaluating Grade 1-A students, the class-specific rule takes precedence over the school-wide rule.

---

## Failure Scenarios

**FC-001: Range Overlap Rejected**
1. Admin attempts to create a category with range 30%–50% when "Needs Improvement" (33%–45%) already exists in the same scope.
2. System after-validation fails with error: "The percentage range overlaps with an existing active performance category."
3. Record is not saved. Admin must adjust the range to avoid overlap.

**FC-002: Editing a System-Defined Record**
1. Admin attempts to modify a system-defined performance category.
2. The `update()` controller checks `$performanceCategory->is_system_defined` and redirects with error: "System-defined question types cannot be modified."
3. Admin can only view the record; changes require software provider intervention.

**FC-003: Missing Class ID When Scope is CLASS**
1. Admin creates a category with Scope: CLASS but leaves Class field empty.
2. Validation fails with error: "Class is required when scope is CLASS."
3. Record is not saved. Admin must select a class.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `slb_performance_categories` | `id`, `code` VARCHAR(20), `name` VARCHAR(100), `level` TINYINT, `min_percentage` DECIMAL(5,2), `max_percentage` DECIMAL(5,2), `ai_severity` ENUM(LOW,MEDIUM,HIGH,CRITICAL), `ai_default_action` ENUM(ACCELERATE,PROGRESS,PRACTICE,REMEDIATE,ESCALATE), `display_order` SMALLINT, `color_code` VARCHAR(10), `icon_code` VARCHAR(50), `scope` ENUM(SCHOOL,CLASS), `class_id` BIGINT FK, `is_system_defined` TINYINT(1), `auto_retest_required` TINYINT(1), `is_active` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `slb_classes` | FK `class_id` REFERENCES for scope=CLASS records |
| Module Dependency | Syllabus Module | Core module where this master data is configured via `syllabus.master.index` route |
| Module Dependency | Assessment Module | Evaluates student scores against category ranges and triggers AI actions |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.performance-category.*` permissions |
