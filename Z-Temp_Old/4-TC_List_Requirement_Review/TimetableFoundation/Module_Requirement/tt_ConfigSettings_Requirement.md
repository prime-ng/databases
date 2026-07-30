# Timetable Configuration — Business Requirements

## What This Screen Does

Timetable Configuration is the central key-value settings store for the entire Timetable Foundation module. It provides an inline-editable list of configuration keys that control global scheduler behaviour — such as the maximum number of periods per day, the minimum and maximum weekly periods a teacher can be assigned, and default school open days. Each key has a defined value type (STRING, NUMBER, BOOLEAN, DATE, TIME, DATETIME, or JSON), and only keys marked as tenant-modifiable can be edited by school users; system-managed keys are display-only.

The screen also hosts the **Priority Configuration** subsystem, which computes seven index scores (teacher scarcity, weekly load ratio, rigidity, resource scarcity, etc.) for each active Requirement Consolidation. These scores are used by the Smart Timetable solver to determine the order in which activities are placed into time slots. A dedicated "Recalculate" action recomputes all priority scores from the current Requirement Consolidation data.

---

## When This Screen Is Used

- **Initial school setup** — the Timetable Manager or School Admin sets global scheduler parameters (periods per day, break counts, teacher load limits) before any timetable data is entered.
- **Annual reconfiguration** — at the start of a new academic session, the Timetable Manager reviews and adjusts config values to match the current school year's schedule.
- **Policy change** — when the school changes bell times, adds a lunch break, or adjusts teacher workload limits, the appropriate config key is updated via inline edit.
- **Solver tuning** — the Priority Configuration is recalculated whenever Requirement Consolidation data changes (new subjects added, student counts updated, teacher availability adjusted) to ensure the solver works with current scores.
- **Audit and review** — the Principal or Academic Coordinator views the configuration page read-only to verify current settings before timetable generation.

---

## Default Data Load

The screen loads under the route `timetable-foundation.menu.timetableConfiguration` with the tab parameter `tab=tt-config`. The `TimetableFoundationController::timetableConfiguration()` method (lines 111–165) runs two queries for this tab:

1. **Config grid** — `Config::query()` filtered by optional `cfg_search` (searches `key_name`, `value`, `description`) and `cfg_status` (is_active filter), ordered by `ordinal`. Records are loaded via `->get()` (not paginated — all records render on one page).
2. **Academic Terms** — loaded into the same view for the adjacent "Academic Terms" tab, along with the `allAcademicSessions` dropdown for the session filter.

The grid columns display: Order, Key, Key Name, Value, Type, Mandatory, Tenant Modifiable, Status (active toggle), and Action buttons (View, Edit, Delete). The status toggle uses an AJAX endpoint (`POST /config/{config}/toggle-status`).

The Priority Configuration tab loads separately under `timetable-foundation.menu.timetableRequirement` with `tab=priority-config` (handled by `TimetableFoundationController::timetableRequirement()`), which queries `tt_priority_configs` rows with their associated Requirement Consolidation relationships.

---

## Key Fields at a Glance

**Identity and Tracking**

- **Key** — The machine-readable identifier for the setting (e.g., `max_weekly_periods_can_be_allocated_to_teacher`). This value is system-set at seed time and cannot be changed after creation.
- **Key Name** — The human-readable label displayed in the grid (e.g., "Maximum No of Periods that can be allocated to Teacher per week"). Editable by the user.
- **Description** — A free-text explanation of what the configuration key controls and how it affects timetable generation.
- **Value** — The current setting value. Displayed in the grid and editable inline. The format and validation depend on the Value Type.

**Access Control**

- **Tenant Can Modify** — A boolean flag (Yes/No badge) that controls whether the school user is allowed to edit this key's value. Keys with "No" are system-managed and displayed in read-only text with no edit control.
- **Mandatory** — Indicates whether this configuration key is required for the timetable module to function correctly. Mandatory keys are badged "Required" in warning colour; optional keys show "Optional" in grey.

**Status**

- **Is Active** — A toggle badge that switches the record between Active and Inactive. Inactive config keys are ignored by the system at runtime. The `Config::get()` helper only returns values for active records.
- **Used By App** — Indicates whether the setting is consumed by the application logic (as opposed to being purely informational). Badged "Yes" in primary colour or "No" in grey.

---

## Business Rules and Conditions

**System-Managed Keys Are Read-Only.** Any configuration record where `tenant_can_modify` is set to `false` (or `0`) must not present an inline edit control to non-super-admin users. The backend enforces this implicitly — the UI simply omits the edit affordance, and the `ConfigRequest` rules do not allow the `key` field to be changed on update. Super-admin users can still edit any field through the dedicated edit form.

**Key Immutability on Update.** Once a configuration key is created, its `key` column cannot be changed. The update form does not include a `key` field, and the `ConfigRequest` validation for PUT/PATCH requests omits the `key` rule entirely. If the system needs a different identifier, the record must be soft-deleted and re-created.

**Priority Config Recalculation is All-or-Nothing.** The `PriorityConfigService::recalculate()` method processes every active Requirement Consolidation in a single database transaction. If any individual record fails, the entire recalculation is rolled back and an error message is returned. The method computes seven index scores for each consolidation:

- **Total students** — sourced from `requirement_consolidation.student_count`.
- **Teacher scarcity index** — the number of eligible teachers; lower values indicate higher scarcity.
- **Weekly load ratio** — required weekly periods divided by total weekly periods available.
- **Average teacher availability ratio** — the mean proficiency percentage from teacher availability records matching the consolidation's class-section-subject-study-format combination.
- **Rigidity score** — if preferred periods are declared, the ratio of preferred slots to total slots; fewer slots mean higher rigidity.
- **Resource scarcity** — 1 divided by the number of available rooms of the required type.
- **Subject difficulty index** — currently defaulted to 1.00 (no difficulty field available yet).

**Value Type Coercion.** When a config value is saved, the controller coerces the raw input to match the declared `value_type`:
- `BOOLEAN` — converted to `true`/`false` from any of the accepted truthy/falsy string representations.
- `JSON` — decoded from a JSON string into an array/object; invalid JSON is rejected with a validation error.
- `NUMBER` — cast to a numeric value (integer or float) using `$value + 0`.

---

## Workflow Steps

**Edit a Config Value (Inline)**

1. The Timetable Manager opens the Timetable Configuration page and navigates to the "Timetable Config" tab.
2. The system loads all config records ordered by ordinal, displaying them in a table with columns: Order, Key, Key Name, Value, Type, Mandatory, Tenant Modifiable, Status, and Action buttons.
3. The Timetable Manager locates the key to edit (e.g., "Maximum No of Periods that can be allocated to Teacher per week") and clicks the **Edit** (pencil) button.
4. The edit form loads with the current values pre-filled. The `Key` field is absent (immutable).
5. The Timetable Manager updates the value (e.g., changes `max_weekly_periods_can_be_allocated_to_teacher` from "8" to "10"), modifies any other field, and submits.
6. The `ConfigRequest` validates the input — type-aware validation runs: NUMBER fields check `numeric`, BOOLEAN fields check `in:true,false,0,1`, JSON fields validate `json`, etc.
7. The controller coerces the value to the correct PHP type, calls `Config::update()`, logs the activity with before/after values, and redirects back to the configuration page with a success flash message.
8. The updated value is immediately reflected in the grid on the next page load.

**Recalculate Priority Config**

1. The Timetable Manager navigates to the Timetable Requirement page and opens the "Priority Config" tab.
2. The system displays existing priority config records with their computed scores.
3. The Timetable Manager clicks the **Recalculate** button.
4. The `PriorityConfigController::recalculate()` method delegates to `PriorityConfigService::recalculate()`, which iterates over all active Requirement Consolidations, computes the seven index scores for each, and upserts one row per consolidation into `tt_priority_configs`.
5. On success, a flash message reports the count of processed records: "Priority scores recalculated for N requirements."
6. On failure, an error flash message describes the failure reason.

---

## Example Scenario

**School admin updates maximum periods per day and recalculates priority scores.**

Ms. Sharma, the School Admin at Sunshine Academy, notices that the current maximum of 8 periods per day is insufficient for Class 10, which needs 9 periods to accommodate additional Mathematics and Science practical sessions. She navigates to Timetable Configuration, finds the key `total_number_of_period_per_day` (Tenant Modifiable = Yes), clicks Edit, changes the value from "8" to "9", and saves. The system validates that the value is numeric, coerces it to integer `9`, updates the record, and logs the change.

Later, after the Academic Coordinator updates student counts in several Requirement Consolidations, Ms. Sharma navigates to the Priority Config tab under Timetable Requirement and clicks **Recalculate**. The system processes all 34 active Requirement Consolidations, recomputes each of the seven scores, and reports "Priority scores recalculated for 34 requirements." The solver now uses updated scores for the next timetable generation run.

---

## Related Screens

- **Pre-Requisites Setup** — read-only dashboard confirming that Buildings, Rooms, Teacher Profiles, Classes, Sections, and Subjects exist before configuration begins.
- **Academic Terms** — the second tab on the Timetable Configuration page; manages term date ranges with overlap validation.
- **Timetable Requirement** — houses the Priority Config tab where `tt_priority_configs` scores are displayed and recalculated.
- **Requirement Consolidation** — the parent data source for Priority Config; student counts and subject-study-format combinations feed the score computation.

---

## Requirements

- `ConfigController` (290 lines) handles all CRUD operations for the `tt_configs` table, plus `toggleStatus`, `trashed`, `restore`, and `forceDelete` endpoints.
- `ConfigController::index()` redirects to `timetable-foundation.menu.timetableConfiguration` (the index grid is rendered inline via `TimetableFoundationController::timetableConfiguration()`).
- `ConfigController::create()` (lines 23–38) returns the create view with a `$valueTypes` array of 7 types (STRING, NUMBER, BOOLEAN, DATE, TIME, DATETIME, JSON); gated by `timetable-foundation.config.create`.
- `ConfigController::store()` (lines 43–100) validates via `ConfigRequest`, auto-generates `key` from `key_name` using `Str::snake(Str::lower(...))` if `key` is empty, checks for duplicate keys, coerces value by type (BOOLEAN→bool, JSON→decode, NUMBER→numeric), decodes `additional_info` if JSON string, creates record, logs activity, and redirects with `flash('created.tt-config')`.
- `ConfigController::update()` (lines 138–192) — can NOT change the `key` field; only the value, key_name, description, and boolean flags are mutable. Coerces value using the existing record's `value_type`. Logs detailed changes (before/after per attribute).
- `ConfigController::destroy()` (lines 197–212) — sets `is_active = false`, then calls `$config->delete()` (soft delete). Logs "Trashed" activity.
- `ConfigController::toggleStatus()` (lines 259–289) — AJAX endpoint validates `is_active` required|boolean, flips the flag, saves, and returns JSON `{success, is_active, message}`. Gated by `timetable-foundation.config.update`.
- `ConfigController::trashed()` (lines 217–222) — `Config::onlyTrashed()->orderBy('deleted_at', 'desc')->paginate(10)`; gated by `timetable-foundation.config.restore`.
- `ConfigController::restore($id)` (lines 224–238) — `Config::onlyTrashed()->findOrFail($id)`, calls `restore()`, logs activity, redirects to trash view.
- `ConfigController::forceDelete($id)` (lines 240–254) — `Config::withTrashed()->findOrFail($id)`, calls `forceDelete()`, logs "Deleted" activity.
- Routes registered in `web.php` lines 61–67: `Route::resource('config', ConfigController::class)`, plus custom `config.trashed`, `config.restore`, `config.forceDelete`, `config.toggleStatus`.
- `ConfigRequest` (183 lines) enforces type-aware validation via `getValueValidationRule()` — NUMBER→`required|numeric`, BOOLEAN→`required|in:true,false,0,1`, JSON→`required|json`, STRING→`required|string`, DATE→`required|date`, TIME→`required|date_format:H:i`, DATETIME→`required|date`.
- `ConfigRequest::prepareForValidation()` normalises boolean checkboxes (has → true), auto-generates `key` from `key_name` on create, encodes array `additional_info` to JSON, and coerces value per type (BOOLEAN→bool, JSON→decode, NUMBER→float).
- `ConfigRequest::withValidator()` adds an `after` validation hook that runs supplementary type checks (e.g., `strtotime()` for DATE, regex for TIME, JSON decode for JSON) and validates `additional_info` JSON format.
- `Config::get(string $key, mixed $default)` — static helper that returns the active config value cast to the correct PHP type; NUMBER→int, BOOLEAN→`filter_var()`, JSON→`json_decode()`.
- `PriorityConfigController` (37 lines) has one public method `recalculate()`, gated by `timetable-foundation.viewAny`.
- `PriorityConfigService::recalculate()` (173 lines) iterates active `RequirementConsolidation` records, computes 7 index scores, and upserts into `tt_priority_configs` inside a DB transaction. Returns count of processed rows.
- Route `POST priority-config/recalculate` delegates to `PriorityConfigController::recalculate()`.
- Activity logging via `activityLog()` helper on all state-changing operations (create, update, destroy, restore, forceDelete, toggleStatus).
- `TimetableConfigPolicy` defines 7 methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` — each checks the corresponding `timetable-foundation.config.*` permission.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `timetable-foundation.config.viewAny` | `index`, `timetableConfiguration` (via controller) | Required to view the configuration tab |
| `timetable-foundation.config.view` | `show` | View a single config record detail |
| `timetable-foundation.config.create` | `create`, `store` | Create new config keys (typically super-admin only) |
| `timetable-foundation.config.update` | `edit`, `update`, `toggleStatus` | Edit config values and toggle active status |
| `timetable-foundation.config.delete` | `destroy` | Soft-delete a config record |
| `timetable-foundation.config.restore` | `trashed`, `restore` | View trash and restore soft-deleted records |
| `timetable-foundation.config.forceDelete` | `forceDelete` | Permanently delete a record |
| `timetable-foundation.viewAny` | `timetableConfiguration`, `recalculate` | Required to view the menu page |

**Policy class:** `Modules\TimetableFoundation\Policies\TimetableConfigPolicy` — registered for `Modules\TimetableFoundation\Models\Config`.

---

## Logic Flow

**Page Load (Timetable Config Tab)**

1. User navigates to `timetable-foundation.menu.timetableConfiguration` with `?tab=tt-config`.
2. `TimetableFoundationController::timetableConfiguration()` gates on `timetable-foundation.viewAny`.
3. The method queries `Config::query()` with optional `cfg_search` (key_name, value, description LIKE) and `cfg_status` (is_active filter), ordered by `ordinal`, executed with `->get()`.
4. The view renders the tab pane (`_list.blade.php`) with the `$configs` collection. Each row shows Key, Key Name, Value, Type, Mandatory, Tenant Modifiable, an AJAX status toggle, and action buttons (View, Edit, Delete).
5. The tab also loads `$academicTerms` and `$allAcademicSessions` for the Academic Terms tab sharing the same page.

**Create/Edit (Config Record)**

1. User clicks **Add** (super-admin only, gated by `@can(auth()->user()->is_super_admin)` on the config/index view) or **Edit** on a row.
2. Create form: fields include ordinal, key (auto-generated from key_name if empty), key_name, value, value_type (dropdown of 7 types), description, additional_info, tenant_can_modify, mandatory, used_by_app, is_active.
3. Edit form: same fields minus `key` (not editable) and `value_type` (immutable after creation).
4. On submission, `ConfigRequest` validates input:
   - CREATE: `key` is `required|unique:tt_configs,key`, `value_type` is `required|in:STRING,NUMBER,...`, value validated per type.
   - UPDATE: `key` and `value_type` not in rules; value validated per existing record's `value_type`.
5. `prepareForValidation()` normalises boolean checkboxes to booleans, auto-generates `key` from `key_name` on create, encodes `additional_info` arrays to JSON, coerces value per type.
6. `store()` additionally checks for duplicate `key` (secondary check beyond the unique rule), coerces value in controller (BOOLEAN→bool, JSON→decode, NUMBER→numeric), decodes `additional_info` JSON, creates record, logs activity, redirects with success.
7. `update()` coerces value using the existing record's `value_type`, logs detailed before/after changes.

**Delete (Soft Delete)**

1. User clicks **Delete** (super-admin only; gated by `@if(auth()->check() && auth()->user()->is_super_admin == 1)`).
2. SweetAlert2 confirmation dialog: "Move to Trash?" with "Yes, move to trash!" / "Cancel" buttons.
3. On confirmation, `ConfigController::destroy()` sets `is_active = false`, calls `$config->delete()` (soft delete), logs "Trashed" activity, redirects with `flash('trashed.tt-config')`.

**Restore / Force Delete (Trash View)**

1. User navigates to `timetable-foundation.config.trashed` — lists soft-deleted records paginated at 10 per page.
2. Click **Restore** → `ConfigController::restore($id)` calls `$config->restore()`, logs activity.
3. Click **Force Delete** → `ConfigController::forceDelete($id)` calls `$config->forceDelete()`, logs "Deleted" activity.

**Priority Config Recalculate**

1. User navigates to Timetable Requirement page, Priority Config tab (`?tab=priority-config`).
2. User clicks **Recalculate** button → `POST priority-config/recalculate`.
3. `PriorityConfigController::recalculate()` calls `PriorityConfigService::recalculate()`.
4. Service method: compute total weekly periods (active school days × periods per day from default PeriodSet), room counts by type, teacher availability averages by class-section-subject-format.
5. For each active `RequirementConsolidation`, compute 7 index scores and `updateOrInsert` into `tt_priority_configs` within a DB transaction.
6. Redirect back with success/error flash message.

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|---|---|---|
| `ordinal` | `required|integer|min:1` | — |
| `key` (create only) | `required|string|max:100|unique:tt_configs,key` | "This configuration key already exists." |
| `key_name` | `nullable|string|max:255` | — |
| `value_type` (create only) | `required|in:STRING,NUMBER,BOOLEAN,DATE,TIME,DATETIME,JSON` | "Please select a valid value type." |
| `value` (NUMBER) | `required|numeric` | "Please enter a valid number." |
| `value` (BOOLEAN) | `required|in:true,false,0,1,true,false` | "Please select either true or false." |
| `value` (JSON) | `required|json` | "Please enter valid JSON format." |
| `value` (STRING) | `required|string` | — |
| `value` (DATE) | `required|date` | "Please enter a valid date." |
| `value` (TIME) | `required|date_format:H:i` | "Please enter a valid time format (HH:MM)." |
| `value` (DATETIME) | `required|date` | "Please enter a valid date and time." |
| `description` | `nullable|string` | — |
| `additional_info` | `nullable|string` | "Invalid JSON format." (via `withValidator`) |
| `tenant_can_modify` | `boolean` | — |
| `mandatory` | `boolean` | — |
| `used_by_app` | `boolean` | — |
| `is_active` | `boolean` | — |
| **Duplicate key (controller check)** | `Config::where('key', $data['key'])->exists()` | "This key already exists. Please choose a different key." |
| **Invalid JSON in additional_info (controller)** | `json_decode()` try-catch | "Invalid JSON format in Additional Info." |
| **NUMBER after-validation** | `after` hook: `is_numeric($value)` | "Please enter a valid number." |
| **BOOLEAN after-validation** | `after` hook: `in_array($value, [...])` | "Boolean must be true or false." |
| **JSON after-validation** | `after` hook: `json_decode()` check | "Invalid JSON format." |
| **DATE after-validation** | `after` hook: `strtotime($value)` | "Please enter a valid date." |
| **TIME after-validation** | `after` hook: `preg_match('/^HH:MM$/')` | "Please enter a valid time (HH:MM)." |
| **DATETIME after-validation** | `after` hook: `strtotime($value)` | "Please enter a valid date and time." |
| **additional_info JSON (after-validation)** | `after` hook: `json_decode()` | "Invalid JSON format." |
| **toggleStatus validation** | `is_active` `required|boolean` (inline in controller) | — (returns JSON error on failure) |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Duplicate config key on create | "This key already exists. Please choose a different key." | Controller check (validation error) |
| Key uniqueness violation | "This configuration key already exists." | Validation rule (`key.unique`) |
| Invalid value type selected | "Please select a valid value type." | Validation rule (`value_type.in`) |
| Non-numeric value for NUMBER type | "Please enter a valid number." | Validation rule (`value.numeric`) |
| Invalid JSON string for JSON type | "Please enter valid JSON format." | Validation rule (`value.json`) |
| Invalid date for DATE/DATETIME | "Please enter a valid date." | Validation rule (`value.date`) |
| Invalid time format for TIME | "Please enter a valid time format (HH:MM)." | Validation rule (`value.date_format`) |
| Invalid boolean value for BOOLEAN | "Please select either true or false." | Validation rule (`value.in`) |
| Invalid JSON in additional_info (during store) | "Invalid JSON format in Additional Info." | Controller check (500 redirect) |
| Generic JSON format failure (during validation) | "Invalid JSON format." | Validation (`withValidator` after hook) |
| Boolean must be true or false | "Boolean must be true or false." | Validation (`withValidator` after hook) |
| Invalid date (strtotime check) | "Please enter a valid date." | Validation (`withValidator` after hook) |
| Invalid time format (regex check) | "Please enter a valid time (HH:MM)." | Validation (`withValidator` after hook) |
| Invalid date/time (strtotime check) | "Please enter a valid date and time." | Validation (`withValidator` after hook) |
| Config created successfully | `flash('created.tt-config')` | Success flash (redirect) |
| Config updated successfully | `flash('updated.tt-config')` | Success flash (redirect) |
| Config trashed successfully | `flash('trashed.tt-config')` | Success flash (redirect) |
| Config restored successfully | `flash('restored.tt-config')` | Success flash (redirect) |
| Config permanently deleted | `flash('force_deleted.tt-config')` | Success flash (redirect) |
| Status toggle success | `flash('status_updated.tt-config')` | JSON success response |
| Status toggle failure | `flash('status_switch_failed.tt-config')` | JSON error response |
| Priority recalculation success | "Priority scores recalculated for N requirements." | Success flash (redirect) |
| Priority recalculation failure | "Recalculation failed: \<reason\>" | Error flash (redirect) |

---

## Success Scenarios

**SC-001 — Admin updates a tenant-modifiable config value.** The School Admin changes `max_weekly_periods_can_be_allocated_to_teacher` from "8" to "10". The `ConfigRequest` validates the input is numeric, the controller coerces the value to integer `10`, updates the record, logs the change with before/after values, and redirects to the config page with a success message. The grid now displays "10" in the Value column.

**SC-002 — Priority scores recalculated successfully.** The Timetable Manager clicks **Recalculate** on the Priority Config tab with 25 active Requirement Consolidations. `PriorityConfigService::recalculate()` processes each consolidation in a transaction, computes all seven scores, and upserts 25 rows into `tt_priority_configs`. The page reloads with "Priority scores recalculated for 25 requirements." The solver now uses updated scores.

**SC-003 — Admin creates a new config key.** A super-admin clicks **Add**, fills in ordinal "15", key_name "Maximum Teachers per Subject", value_type "NUMBER", value "3", and submits. The system auto-generates key `maximum_teachers_per_subject`, validates no duplicate exists, coerces value to integer `3`, creates the record, logs "Timetable configuration was created.", and redirects with a success flash. The new row appears at the bottom of the config grid.

---

## Failure Scenarios

**FC-001 — Duplicate key rejected on create.** A super-admin attempts to create a config with key `total_number_of_period_per_day` which already exists. The `unique:tt_configs,key` validation triggers "This configuration key already exists." If the unique rule is bypassed, the controller's explicit `Config::where('key', ...)->exists()` check catches it and returns "This key already exists. Please choose a different key." with `withInput()`.

**FC-002 — Invalid value type on inline edit.** A user changes the value of a NUMBER-type config key to the string "high". The `ConfigRequest` rule `required|numeric` fails, producing "Please enter a valid number." If that is bypassed, the `withValidator()` after hook runs `is_numeric($value)`, which also fails, adding "Please enter a valid number." to the error bag. The form re-displays with the error message.

**FC-003 — Priority recalculation fails due to database error.** During recalculation, a database constraint violation occurs (e.g., a missing Requirement Consolidation parent record). The DB transaction rolls back, the exception is caught by `PriorityConfigController::recalculate()`, and the page redirects with "Recalculation failed: SQLSTATE[23000] ..." The `tt_priority_configs` table remains unchanged.

---

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `tt_requirement_consolidations` | FK parent (Priority Config) | `tt_priority_configs.requirement_consolidation_id` references `tt_requirement_consolidations.id` |
| `sch_rooms` | Read (Priority Config Service) | `PriorityConfigService::roomCountByType()` queries `sch_rooms` for resource scarcity computation |
| `tt_teacher_availabilities` | Read (Priority Config Service) | `PriorityConfigService::avgTeacherAvailabilityByRc()` computes average proficiency via JOIN |
| `tt_period_sets` | Read (Priority Config Service) | `PriorityConfigService::totalWeeklyPeriods()` reads active period set's `total_periods` |
| `tt_school_days` | Read (Priority Config Service) | `PriorityConfigService::totalWeeklyPeriods()` counts active school days |
| `activityLog()` helper | Service | All state changes in `ConfigController` call `activityLog()` to record audit trail |
| `PriorityConfigService` | Internal service | Used by `PriorityConfigController::recalculate()` and `TimetableFoundationController::generateStep()` (step 6) |

**Table:** `tt_configs`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `ordinal` | INT UNSIGNED | Display order; UNIQUE KEY `uq_settings_ordinal` |
| `key` | VARCHAR(150) | Machine identifier; UNIQUE KEY `uq_settings_key`; immutable after creation |
| `key_name` | VARCHAR(150) | Human-readable label |
| `value` | VARCHAR(512) | Current setting value (stored as string; cast at runtime per value_type) |
| `value_type` | ENUM('STRING','NUMBER','BOOLEAN','DATE','TIME','DATETIME','JSON') | Declares the data type for validation and runtime casting |
| `description` | VARCHAR(255) | Explanation of the config key's purpose |
| `additional_info` | JSON | Nullable; stores supplementary metadata as JSON |
| `tenant_can_modify` | TINYINT(1) | Default `0`; whether school users can edit this key |
| `mandatory` | TINYINT(1) | Default `1`; whether this key is required for operation |
| `used_by_app` | TINYINT(1) | Default `1`; whether the application logic consumes this key |
| `is_active` | TINYINT(1) | Default `1`; runtime toggle |
| `deleted_at` | TIMESTAMP NULL | Soft deletes |
| `created_at` | TIMESTAMP NULL | Creation timestamp |
| `updated_at` | TIMESTAMP NULL | Last update timestamp |
| **Indexes** | | PRIMARY KEY (`id`); UNIQUE KEY on (`ordinal`); UNIQUE KEY on (`key`) |

**Table:** `tt_priority_configs`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `requirement_consolidation_id` | INT UNSIGNED | FK to `tt_requirement_consolidations.id`; NOT NULL |
| `tot_students` | INT UNSIGNED | Nullable; total students from RequirementConsolidation |
| `teacher_scarcity_index` | DECIMAL(7,2) UNSIGNED | Default `1`; count of eligible teachers (lower = scarcer) |
| `weekly_load_ratio` | DECIMAL(7,2) UNSIGNED | Default `1`; required periods / total weekly periods |
| `average_teacher_availability_ratio` | DECIMAL(7,2) UNSIGNED | Default `1`; mean proficiency % from teacher availabilities |
| `rigidity_score` | DECIMAL(7,2) UNSIGNED | Default `1`; preferred slots / total slots |
| `resource_scarcity` | DECIMAL(7,2) UNSIGNED | Default `1`; 1 / available rooms of required type |
| `subject_difficulty_index` | DECIMAL(7,2) UNSIGNED | Default `1`; placeholder (no difficulty field available yet) |
| `is_active` | TINYINT(1) | Default `1`; runtime toggle |
| `created_by` | INT UNSIGNED | Nullable; `auth()->id()` set during recalculation |
| `deleted_at` | TIMESTAMP NULL | Soft deletes (model trait) |
| `created_at` | TIMESTAMP | Populated on upsert |
| `updated_at` | TIMESTAMP | Populated on upsert |
| **Indexes** | | PRIMARY KEY (`id`) |
