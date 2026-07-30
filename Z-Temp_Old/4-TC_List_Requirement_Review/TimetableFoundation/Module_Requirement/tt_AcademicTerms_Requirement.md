# Academic Terms — Business Requirements

## What This Screen Does

Academic Terms divide an academic session into smaller, manageable scheduling periods — for example, Term 1, Term 2, Term 3, or Quarter 1 through Quarter 4. Each term defines its own date range, weekly teaching pattern, period grid dimensions, and resting-period constraints. Every timetable, activity, and availability record in the system is scoped to a specific academic term, making terms the fundamental time-bucket for all scheduling operations.

The screen lives under the Timetable Configuration page (Page 2 of the Timetable Foundation workflow) and provides full CRUD — Create, Read, Update, soft Delete, Restore, and Force Delete — plus status toggling and the ability to mark a term as the current active term. It also exposes a read-only AJAX endpoint that returns session dates when the user selects an academic session during term creation or editing.

## When This Screen Is Used

- **Setting up a new academic year** — At the start of an academic session, a Timetable Manager or School Admin defines the terms (e.g., Term 1, Term 2) that the session is divided into, specifying exact start/end dates, period counts, and rest constraints.
- **Switching to a new term mid-year** — When one term ends and the next begins, the administrator marks the new term as "current" (and optionally deactivates the previous one), which affects which term's data is shown by default across timetable screens.
- **Adjusting term parameters mid-stream** — If the school schedule changes (e.g., the number of teaching days per week or the bell-timing grid), the administrator edits the affected term's configuration to keep it aligned with the actual school calendar.
- **Deactivating or cleaning up old terms** — When terms are no longer needed (e.g., a past term from a prior session), the administrator soft-deletes or permanently removes them.

## Default Data Load

The `AcademicTermController@index` method is called when the user navigates to the Academic Terms tab. Because `index()` contains only a `Gate::authorize` call followed by a redirect, the actual data load happens inside `TimetableFoundationController@timetableConfiguration` (route `timetable-foundation.menu.timetableConfiguration`), which renders the full multi-tab page with `tab=academic-terms` as the active tab.

AcademicTerm records are loaded via `AcademicTerm::query()` with eager-loaded `academicSession` relationship, filtered by:

| Filter | Input name | Default |
|--------|------------|---------|
| Session ID | `at_session_id` | None (all sessions) |
| Search (term name) | `at_search` | None |
| Status (is_active) | `at_status` | `1` (active only) |

Results are ordered by `term_name` in ascending order and rendered as a table with columns: #, Name, Code, Session, Start, End, Status (toggle), Action (View, Edit). The page also loads an `$allAcademicSessions` collection from `OrganizationAcademicSession` for the session filter dropdown.

The standalone `academic-term.index` route loads its own data separately via `AcademicTerm::with('academicSession')` with its own filter controls (term_name, term_code, academic_session_id, is_current, is_active) and **paginates** the result (default page size per Laravel pagination).

## Key Fields at a Glance

**Identity and Origin**

These fields define what the term is called, how it relates to its parent academic session, and its position in the term sequence.

- **Academic Session** — The parent session (e.g., "Academic Year 2025–26") this term belongs to. Every term is scoped to exactly one session.
- **Term Code** — A short unique identifier within the session, such as "Q1", "SUMMER", or "TERM1". Used as a concise reference in dropdowns and reports.
- **Term Name** — The human-readable display name, e.g., "Summer Term" or "Quarter 1".
- **Term Ordinal** — The numeric order of the term within the session (1, 2, 3, …). Determines the sequence in list views.
- **Total Terms in Academic Session** — A informational count of how many terms exist in the parent session (e.g., 2 for a semester system, 4 for a quarter system).

**Date Boundaries**

These fields control when the term starts and ends, and must fall within the parent session's date range.

- **Academic Year Start / End Date** — Read-only fields auto-populated from the selected session. They define the outer bounds for the term's own start and end dates.
- **Term Start Date** — The calendar date on which the term begins.
- **Term End Date** — The calendar date on which the term concludes.

**Weekly Schedule Configuration**

These fields describe the school's weekly pattern during the term and are consumed by the timetable solver to determine available slots.

- **Total Teaching Days per Week** — How many days in a week are teaching days (e.g., 5 for Monday–Friday, 6 for Monday–Saturday). Default 5.
- **Total Exam Days per Term** — How many days in the term are reserved for exams (default 2). This is a planning figure, not a calendar — the actual Working Day Calendar tracks exact dates.
- **Week Start Day** — Which day of the week is considered the first day (1=Monday through 7=Sunday). Default 1.
- **Total Periods per Day** — The total number of periods in a school day, including teaching periods, breaks, lunch, recess, and assembly (e.g., 8). Default 8.
- **Teaching Periods per Day** — How many of the total periods are actual teaching periods (excluding breaks, lunch, etc.). Default 6.

**Rest and Transition Constraints**

These fields govern the solver's rules about teacher movement between classes.

- **Minimum Resting Periods per Day** — The smallest number of free (non-teaching) periods a teacher should have in a day (default 0).
- **Maximum Resting Periods per Day** — The largest number of free periods a teacher may have in a day (default 2). The system enforces `max >= min` both in the form and through a controller-side adjustment.
- **Travel Minutes Between Classes** — The time in minutes a teacher needs to move between classrooms or buildings (default 5). Used by the solver to prevent back-to-back assignments in distant rooms.

**Status Flags**

- **Current Term** — A boolean flag indicating which term is the active/current one. Only one term per session may be current at a time, enforced by a database generated column (`current_flag`) with a unique index.
- **Active Status** — Whether the term is enabled and available for use in schedules, activities, and dropdowns. The default is active. When a term is deactivated, it is hidden from selection lists.
- **Settings JSON** — An optional free-form JSON field for storing additional configuration key-value pairs specific to the term (default `{}`).

---

## Business Rules and Conditions

**Session Scoping** — Every academic term must belong to exactly one `OrganizationAcademicSession`. The term's start and end dates must fall within the parent session's academic_year_start_date and academic_year_end_date range. The system enforces this through form validation rules that compare `term_start_date` against `academic_year_start_date` and `term_end_date` against `academic_year_end_date`.

**Unique Term Code per Session** — Within the same academic session, each term must have a unique `term_code` (e.g., "Q1", "Q2"). Duplicate codes are rejected by a custom validation closure. This is reinforced by the database unique key `uq_AcademicTerm_session_code` on `(academic_session_id, term_code)`.

**Unique Term Ordinal per Session** — Within the same session, each term must have a unique `term_ordinal`. The ordinal identifies the term's position in the sequence (1st, 2nd, 3rd …) and duplicates are rejected by a custom validation closure.

**Single Current Term per Session** — At most one term per academic session may be flagged as `is_current = true`. However, the current_flag is a `GENERATED STORED` column that produces a non-null value only when `is_current = 1` and NULL otherwise. A unique index `uq_AcademicTerm_currentFlag` on `current_flag` enforces this at the database level. At the application level, before setting a term as current, the controller explicitly sets `is_current = false` on any other term in the same session that was previously current.

**Teaching Periods Cannot Exceed Total Periods** — The value of `term_total_teaching_periods_per_day` must be less than or equal to `term_total_periods_per_day`. The frontend enforces this via JavaScript (auto-correcting the value with a user alert), and a custom validation closure (`$value > $totalPeriods`) rejects submissions that violate this rule.

**Maximum Resting Periods Must Be at Least Minimum** — The system requires `term_max_resting_periods_per_day >= term_min_resting_periods_per_day`. The validation rule `gte:term_min_resting_periods_per_day` enforces this, and the controller adds a safety adjustment that sets `max = min` if `max < min`.

**Soft Delete with Deactivation Cascade** — When a term is deleted, the controller sets both `is_active = false` and `is_current = false` before calling the model's `delete()` method (SoftDeletes). This ensures the deleted term is immediately excluded from active use.

**Date Overlap Not Enforced (Known Gap)** — The system does not currently validate that term date ranges within the same session are non-overlapping. This check has been identified as a requirement but is not yet implemented in the controller or request logic.

---

## Workflow Steps

**Creating a New Academic Term**

1. The Timetable Manager navigates to Timetable Foundation → Timetable Configuration → Academic Terms tab and clicks the Create button.
2. The system loads the `create` form with a dropdown of all active academic sessions (ordered by start date descending) and a dropdown of week days (Monday–Sunday).
3. The user selects an academic session. JavaScript immediately populates two read-only date fields (Academic Year Start Date, Academic Year End Date) from data attributes on the selected option and auto-fills the term start/end date fields with the session's start/end dates as defaults.
4. The user enters the term code (e.g., "Q1"), term name (e.g., "Quarter 1"), term ordinal (e.g., 1), and total terms in session (e.g., 4).
5. The user adjusts the term start and end dates if needed, ensuring they stay within the session range (enforced by min/max attributes on the date inputs).
6. The user configures the weekly schedule: teaching days per week (1–7), exam days (0–7), total periods per day (1–20), teaching periods per day (1–20, auto-limited to ≤ total periods).
7. The user sets the week start day, min resting periods (0–10), max resting periods (0–10, auto-corrected to ≥ min), and travel minutes (0–60).
8. The user optionally enters JSON settings and toggles the "Current Term" and "Active" switches.
9. The user clicks "Create Term". The `AcademicTermRequest` validates all fields, the `store()` method wraps the operation in a database transaction, clears any previously current term in the same session (if setting as current), creates the record, logs an activity entry, and redirects back to the Timetable Configuration page with a success flash message.

**Editing an Existing Term**

1. From the Academic Terms list, the user clicks the Edit icon on any row.
2. The `edit` method loads the form pre-populated with the term's current values. Session dates are shown as read-only fields.
3. The user modifies any field (except the session dates, which are read-only).
4. Clicking "Update Term" triggers `AcademicTermRequest` validation, the `update()` method runs within a database transaction, logs changes with old/new values in the activity log, and redirects with a success flash message.

**Viewing a Term**

1. The user clicks the View (eye) icon on any row.
2. The `show` method loads the term with its academic session relationship and renders a read-only detail page. Week-start day is displayed as the day name (Monday, Tuesday, etc.) rather than a numeric code.

**Deleting a Term (Soft Delete)**

1. The user clicks Delete on a term row (the `destroy` route).
2. The controller sets `is_active = false` and `is_current = false` on the model, then calls `$academic_term->delete()` (SoftDeletes).
3. The record is soft-deleted (timestamp written to `deleted_at`) and is no longer shown in the main list.
4. An activity log entry records the trashing.

---

## Example Scenario

Green Valley School runs on a semester system with two terms per academic year. At the start of the 2025–26 session (1 April 2025 – 31 March 2026), the Timetable Manager, Ms. Sharma, creates two terms:

**Term 1 — "Summer Semester" (April–September):**
- Code: `SEM1`, Ordinal: `1`, Total Terms: `2`
- Term dates: 1 April 2025 – 30 September 2025
- Teaching days per week: `5` (Monday–Friday), Exam days per term: `2`
- Total periods per day: `8`, Teaching periods per day: `6`
- Week starts Monday, minimum rest periods: `0`, maximum: `2`, travel time: `5` minutes
- Marked as both Active and Current

**Term 2 — "Winter Semester" (October–March):**
- Code: `SEM2`, Ordinal: `2`, Total Terms: `2`
- Term dates: 1 October 2025 – 31 March 2026
- Same period grid configuration as Term 1
- Marked as Active but NOT Current

Ms. Sharma creates Term 1 first (it becomes the current term). When she creates Term 2, the system allows both to exist. When Term 1 ends in September, she navigates to Term 2's edit screen, toggles "Current Term" on, and saves. The controller automatically clears the current flag on Term 1 and sets it on Term 2.

Later, if the school decides to add an extra 10-minute break between periods, Ms. Sharma edits Term 2's settings to increase max resting periods from `2` to `3` and adjusts the travel minutes accordingly.

---

## Related Screens

- **Timetable Configuration (Config Tab)** — The sibling tab on the same Timetable Configuration page where system-level key-value settings are managed.
- **Generation Strategy Tab** — The third tab on the Timetable Configuration page (visible only when SmartTimetable module is loaded), where the solver algorithm is configured.
- **Pre-Requisites Setup** — The first page of Timetable Foundation, a read-only dashboard that shows whether SchoolSetup data (classes, sections, rooms, teachers) exists before terms can be meaningfully configured.
- **Working Day Calendar** — Consumes term dates to initialise the working-day calendar for each term; inverse updates to the calendar should theoretically update term counters (BR-TTF-015, currently not implemented).
- **Activity Management** — Activities are scoped to an academic term; changing a term's configuration may require regenerating activities.

---

## Requirements

- The `AcademicTermController` (391 lines, `Modules/TimetableFoundation/Http/Controllers/`) implements the following public methods: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashed()`, `restore()`, `forceDelete()`, `toggleStatus()`, `toggleCurrent()`, and `getSessionDates()`. Each write method (store/update/destroy/restore/forceDelete/toggleStatus/toggleCurrent) logs an activity record via the `activityLog()` helper.
- The `index()` method authorises via `Gate::authorize('timetable-foundation.academic-term.viewAny')` and immediately redirects to `timetable-foundation.menu.timetableConfiguration`. The Academic Terms list is actually rendered by `TimetableFoundationController@timetableConfiguration` when the `tab=academic-terms` parameter is present.
- The `create()` and `edit()` methods share the same data-loading pattern: they fetch `OrganizationAcademicSession::where('is_active', '1')->orderBy('start_date', 'desc')->get()` for the session dropdown and a `$weekDays` array mapping integers 1–7 to day names.
- The `store()` and `update()` methods both receive `AcademicTermRequest`, run inside a `DB::beginTransaction()/commit()` block with try-catch for rollback, normalise checkbox fields (`is_current`, `is_active`), enforce `max_resting >= min_resting` by silently adjusting `term_max_resting_periods_per_day` if needed, and clear the current flag on sibling terms when setting `is_current = true`.
- The `store()` method clears current on all terms in the same session: `AcademicTerm::where('academic_session_id', $data['academic_session_id'])->where('is_current', true)->update(['is_current' => false])`.
- The `update()` method clears current on sibling terms only when the new `is_current` is true and the current term `$academic_term->is_current` was previously false: `where('id', '!=', $academic_term->id)`.
- The `destroy()` method performs a soft delete: it sets `is_active = false`, `is_current = false`, then calls `$academic_term->delete()`. This requires the SoftDeletes trait on the model.
- The `trashed()` method loads `AcademicTerm::onlyTrashed()->with('academicSession')->orderBy('deleted_at', 'desc')->paginate(10)` and renders the trash view.
- The `restore($id)` method uses `AcademicTerm::onlyTrashed()->findOrFail($id)`, calls `restore()`, and redirects to the trashed list. It does **not** reinstate `is_active` or `is_current`.
- The `forceDelete($id)` method uses `AcademicTerm::withTrashed()->findOrFail($id)`, calls `forceDelete()`, and redirects to the trashed list.
- The `toggleStatus()` method validates a single `is_active` boolean via `$request->validate([...])`, saves the new status, and returns a JSON response with `success`, `is_active`, and `message` fields. It enforces the `timetable-foundation.academic-term.update` gate.
- The `toggleCurrent()` method (defined but **not registered as a route**) would toggle `is_current` under a DB transaction with sibling-term clearing logic, returning JSON. The gate `timetable-foundation.academic-term.update` is enforced.
- The `getSessionDates($sessionId)` method is an AJAX helper (no gate — exempt from authorisation) that returns a JSON object with `academic_year_start_date` and `academic_year_end_date` formatted as `Y-m-d`.
- The `AcademicTermRequest` (`Modules/TimetableFoundation/Http/Requests/`, 176 lines) sets `authorize() = true` (gate is enforced in the controller). Its `prepareForValidation()` merges `is_current` (default `false`) and `is_active` (default `false`) as booleans and encodes `settings_json` from array to string if needed. Validation rules cover all fillable columns with strict type, range, and cross-field checks, including custom closures for ordinal uniqueness, code uniqueness, date-within-session bounds, and teaching-periods-within-total-periods bounds.
- The `AcademicTerm` model (`Modules/TimetableFoundation/Models/`, 81 lines) uses `SoftDeletes`, maps to the `sch_academic_term` table, declares `$fillable` for all columns except `current_flag` (a generated STORED column), casts `is_current` and `is_active` as booleans, `settings_json` as array, and date fields as dates. It defines `belongsTo(OrganizationAcademicSession::class, 'academic_session_id')` and scopes `scopeActive()` and `scopeCurrent()`.
- The `AcademicTermPolicy` (`Modules/TimetableFoundation/Policies/`, 44 lines) defines six methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, and `forceDelete`. Each delegates to the corresponding `timetable-foundation.academic-term.*` permission string.
- Routes are registered in `routes/web.php` (lines 69–75): a `Route::resource('academic-term', AcademicTermController::class)` plus three custom routes: `academic-term/trash/view` (GET), `academic-term/{id}/restore` (GET), `academic-term/{id}/force-delete` (DELETE), and `academic-term/{academic_term}/toggle-status` (POST). The route prefix and name prefix `timetable-foundation.` are applied by the RouteServiceProvider.
- The `toggleCurrent()` and `getSessionDates()` controller methods have **no routes** registered in `web.php` — `getSessionDates` is explicitly exempted in unit tests as a "method without route", and `toggleCurrent` has no route either (known gap).
- The `current_flag` column is a `GENERATED ALWAYS AS ((case when (is_current = 1) then '1' else NULL end)) STORED` database column. It is NOT in `$fillable` and must never be written by the application. The unique index `uq_AcademicTerm_currentFlag` on this column enforces the single-current-term rule at the database level.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.academic-term.viewAny` | `index()` | Required to view the Academic Terms tab |
| `timetable-foundation.academic-term.view` | `show()` | Required to view a single term's details |
| `timetable-foundation.academic-term.create` | `create()`, `store()` | Required to show the create form and persist a new term |
| `timetable-foundation.academic-term.update` | `edit()`, `update()`, `toggleStatus()`, `toggleCurrent()` | Required to edit a term, toggle its active status, or toggle its current flag |
| `timetable-foundation.academic-term.delete` | `destroy()` | Required to soft-delete a term |
| `timetable-foundation.academic-term.restore` | `trashed()`, `restore()` | Required to view trashed terms and restore them |
| `timetable-foundation.academic-term.forceDelete` | `forceDelete()` | Required to permanently delete a term |

**Policy:** `Modules\TimetableFoundation\Policies\AcademicTermPolicy` — each method checks the corresponding `timetable-foundation.academic-term.*` permission. The request itself (`AcademicTermRequest`) returns `authorize() = true`, delegating all access control to the controller's `Gate::authorize()` calls.

---

## Logic Flow

**1. Page Load (List View)**

1. The user navigates to Timetable Foundation → Timetable Configuration (or directly to the `academic-term` index route).
2. `TimetableFoundationController@timetableConfiguration()` runs (gated by `timetable-foundation.viewAny`).
3. It queries `AcademicTerm::with('academicSession')`, applies filters (`at_search` on term_name, `at_session_id` on academic_session_id, `at_status` on is_active — defaulting to active only because the `applyStatus` helper passes `'1'` as default), and orders by `term_name`.
4. The same controller also loads `$allAcademicSessions` from `OrganizationAcademicSession` (ordered by start_date descending, columns `id`, `name`) for the session filter.
5. The view renders the multi-tab page with the Academic Terms pane showing the search bar and the filtered table. Each row shows Name, Code, Session, Start/End dates, a Status toggle (`x-backend.table.status-switch`), and View/Edit action buttons.

**2. Create (Form → Submit)**

1. The user clicks a Create button (navigating to `timetable-foundation.academic-term.create`).
2. `create()` gates on `timetable-foundation.academic-term.create`, loads active academic sessions and week-day map, renders `school-academic-term.create` view.
3. User fills the form. JavaScript on the page auto-populates session dates when a session is selected, clamps term dates to session range via `min`/`max` attributes, auto-corrects `teaching_periods <= total_periods` and `max_resting >= min_resting`.
4. User clicks "Create Term". POST goes to `timetable-foundation.academic-term.store`.
5. `AcademicTermRequest` validates:
   - `prepareForValidation()` normalises `is_current`/`is_active` to booleans, encodes `settings_json` if array.
   - All field rules run (see Validate Before Save table).
   - Custom closures check: term_ordinal unique within session, term_code unique within session, term_start_date >= session start, term_end_date <= session end, teaching_periods <= total_periods.
6. If validation fails, the form is re-displayed with validation errors.
7. `store()` gates on `timetable-foundation.academic-term.create`, begins a transaction.
8. Converts checkbox fields from `$request->has()` explicitly.
9. Adjusts `term_max_resting_periods_per_day` to equal `term_min_resting_periods_per_day` if smaller.
10. If `is_current` is true, clears the `is_current` flag on all other terms in the same session.
11. Calls `AcademicTerm::create($data)`.
12. Logs activity via `activityLog($academicTerm, 'Stored', ...)` with the session name, term name, and performing user.
13. Commits the transaction. Redirects to `timetable-foundation.menu.timetableConfiguration` with a success flash message.
14. On exception, rolls back and redirects back with the error message.

**3. Edit/Update**

1. User clicks Edit on a row → `edit()` gates on `timetable-foundation.academic-term.update`, loads academic sessions and week-day map, renders `school-academic-term.edit` with the existing term data.
2. User modifies fields and clicks "Update Term". PUT goes to `timetable-foundation.academic-term.update`.
3. `AcademicTermRequest` validates (same rules as create; closures use `$academicTerm` to exclude current ID from uniqueness checks).
4. `update()` gates on `timetable-foundation.academic-term.update`, begins a transaction.
5. Stores original values via `$academic_term->getOriginal()`.
6. Same checkbox normalisation and resting-period adjustment as store.
7. Clears sibling `is_current` only if `$data['is_current']` is true AND the current record was NOT previously current (`!$academic_term->is_current`).
8. Calls `$academic_term->update($data)`.
9. Builds a `$changedAttributes` array with old/new values for each changed field (excluding `updated_at`).
10. Logs activity with the changes map.
11. Commits, redirects to Timetable Configuration with success flash.

**4. Display/Show**

1. User clicks View (eye) icon → `show()` gates on `timetable-foundation.academic-term.view`.
2. Loads the `academicSession` relationship.
3. Renders `school-academic-term.show` with the term data and the week-day name map.

**5. Status Toggle (AJAX)**

1. User clicks the status toggle switch on a list row.
2. POST goes to `timetable-foundation.academic-term.toggle-status`.
3. `toggleStatus()` gates on `timetable-foundation.academic-term.update`, validates `is_active` as required|boolean.
4. Sets `$academic_term->is_active` to the new value, saves.
5. Logs activity (status changed to Active/Inactive).
6. Returns JSON `{ success: true, is_active: <bool>, message: ... }` on success, or `{ success: false, ... }` on failure.

**6. Soft Delete**

1. User triggers delete → `destroy()` gates on `timetable-foundation.academic-term.delete`.
2. Begins a transaction.
3. Sets `is_active = false`, `is_current = false`.
4. Calls `$academic_term->delete()` which writes `deleted_at` (SoftDeletes).
5. Logs activity as "Trashed".
6. Commits, redirects to Timetable Configuration with success flash.

**7. Restore**

1. User navigates to the Trash view → `trashed()` gates on `timetable-foundation.academic-term.restore`, loads `onlyTrashed()` records paginated at 10 per page.
2. User clicks Restore → `restore($id)` gates on the same permission, calls `onlyTrashed()->findOrFail($id)`, then `$academicTerm->restore()`.
3. Activity logged. Redirects back to trash list with success flash.
4. **Note:** `is_active` and `is_current` are NOT reinstated on restore.

**8. Force Delete**

1. From the Trash view, user triggers force delete → `forceDelete($id)` gates on `timetable-foundation.academic-term.forceDelete`.
2. Calls `withTrashed()->findOrFail($id)`, then `$academicTerm->forceDelete()`.
3. Activity logged. Redirects back to trash list.

---

## Validate Before Save

All validation is performed by `Modules\TimetableFoundation\Http\Requests\AcademicTermRequest`. The `prepareForValidation()` method runs first:

| Preparation | Action |
|-------------|--------|
| `is_current` | Merged as `true` if present in request, `false` otherwise |
| `is_active` | Merged as `true` if present in request, `false` otherwise |
| `settings_json` | If sent as an array, JSON-encoded before validation |

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `academic_session_id` | `required`, `exists:sch_org_academic_sessions_jnt,id` | The academic session field is required. / The selected academic session is invalid. |
| `academic_year_start_date` | `required`, `date` | The academic year start date field is required. / The academic year start date is not a valid date. |
| `academic_year_end_date` | `required`, `date`, `after_or_equal:academic_year_start_date` | The academic year end date field is required. / The academic year end date must be a date after or equal to academic year start date. |
| `total_terms_in_academic_session` | `required`, `integer`, `min:1`, `max:12` | The total terms field is required. / … must be an integer / … at least 1 / … may not be greater than 12. |
| `term_ordinal` | `required`, `integer`, `min:1`, `max:12`, unique custom closure | Term ordinal already exists for this academic session. |
| `term_code` | `required`, `string`, `max:20`, unique custom closure | Term code already exists for this academic session. |
| `term_name` | `required`, `string`, `max:100` | The term name field is required. / … may not be greater than 100 characters. |
| `term_start_date` | `required`, `date`, custom session-bounds closure | Term start date cannot be before academic year start date. |
| `term_end_date` | `required`, `date`, `after_or_equal:term_start_date`, custom session-bounds closure | Term end date cannot be after academic year end date. |
| `term_total_teaching_days` | `required`, `integer`, `min:1`, `max:7` | The total teaching days field is required. / … must be an integer / … at least 1 / … may not be greater than 7. |
| `term_total_exam_days` | `required`, `integer`, `min:0`, `max:7` | The total exam days field is required. / … must be an integer / … at least 0 / … may not be greater than 7. |
| `term_week_start_day` | `required`, `integer`, `min:1`, `max:7` | The week start day field is required. / … must be an integer / … at least 1 / … may not be greater than 7. |
| `term_total_periods_per_day` | `required`, `integer`, `min:1`, `max:20` | The total periods per day field is required. / … must be an integer / … at least 1 / … may not be greater than 20. |
| `term_total_teaching_periods_per_day` | `required`, `integer`, `min:1`, `max:20`, custom teaching ≤ total closure | Teaching periods cannot exceed total periods per day. |
| `term_min_resting_periods_per_day` | `required`, `integer`, `min:0`, `max:10` | The min resting periods field is required. / … must be an integer / … at least 0 / … may not be greater than 10. |
| `term_max_resting_periods_per_day` | `required`, `integer`, `min:0`, `max:10`, `gte:term_min_resting_periods_per_day` | The max resting periods field is required. / … must be an integer / … at least 0 / … may not be greater than 10. / The max resting periods must be greater than or equal to min resting periods. |
| `term_travel_minutes_between_classes` | `required`, `integer`, `min:0`, `max:60` | The travel minutes field is required. / … must be an integer / … at least 0 / … may not be greater than 60. |
| `is_current` | `boolean` | The current term field must be true or false. |
| `settings_json` | `nullable`, `json` | The settings JSON must be a valid JSON string. |
| `is_active` | `boolean` | The status field must be true or false. |

**Controller-level checks (not in FormRequest):**

| Check | Location | Action |
|-------|----------|--------|
| `max_resting < min_resting` | `store()` / `update()` lines 67–69 / 167–169 | Silently sets `max = min` |
| Sibling current-term clearing | `store()` lines 73–77 / `update()` lines 174–179 | `where('is_current', true)->update(['is_current' => false])` (and `where('id', '!=', ...)` on update) |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing required field (e.g., term_name) | "The term name field is required." | Validation rule |
| Invalid integer (e.g., term_ordinal = "abc") | "The term ordinal must be an integer." | Validation rule |
| Out of range (e.g., term_ordinal = 13) | "The term ordinal may not be greater than 12." | Validation rule |
| Duplicate term_code within session | "Term code already exists for this academic session." | Validation rule (custom closure) |
| Duplicate term_ordinal within session | "Term ordinal already exists for this academic session." | Validation rule (custom closure) |
| term_start_date before session start | "Term start date cannot be before academic year start date." | Validation rule (custom closure) |
| term_end_date after session end | "Term end date cannot be after academic year end date." | Validation rule (custom closure) |
| teaching_periods > total_periods | "Teaching periods cannot exceed total periods per day." | Validation rule (custom closure) |
| max_resting < min_resting (validation) | "The max resting periods must be greater than or equal to min resting periods." | Validation rule (`gte` rule) |
| Generic database/exception on create | "Failed to create academic term: <exception message>" | Controller check (500 JSON) — displayed as flash error on redirect |
| Generic database/exception on update | "Failed to update academic term: <exception message>" | Controller check (500 JSON) — displayed as flash error on redirect |
| Generic database/exception on delete | "Failed to delete academic term: <exception message>" | Controller check (500 JSON) — displayed as flash error on redirect |
| toggleStatus validation failure | Standard Laravel validation error for "is_active" | Validation rule (AJAX JSON — 422) |
| toggleStatus save failure | JSON `{ success: false, is_active: ..., message: "Status switch failed." }` | Controller check (AJAX JSON — 200 with error flag) |
| toggleCurrent exception | JSON `{ success: false, is_current: ..., message: "Failed to update current status: ..." }` | Controller check (AJAX JSON — 200 with error flag) |
| Success — created | Flash message from `flash('created.academic-term')` | Success flash |
| Success — updated | Flash message from `flash('updated.academic-term')` | Success flash |
| Success — trashed/deleted | Flash message from `flash('trashed.academic-term')` | Success flash |
| Success — restored | Flash message from `flash('restored.academic-term')` | Success flash |
| Success — force deleted | Flash message from `flash('force_deleted.academic-term')` | Success flash |
| Success — status toggled | JSON `{ success: true, is_active: ..., message: flash('status_updated.academic-term') }` | AJAX success response |
| Success — current toggled | JSON `{ success: true, is_current: ..., message: flash('current_status_updated.academic-term') }` | AJAX success response |

---

## Success Scenarios

**SC-001 — Create a New Term for a New Academic Session**
Green Valley School sets up the 2025–26 session. Ms. Sharma creates "Term 1" with code "TERM1", ordinal 1, dates 01-Apr-2025 to 30-Sep-2025 (within the session range), 5 teaching days/week, 8 total periods/day, 6 teaching periods/day, Monday start, 0 min rest, 2 max rest, 5 min travel. She marks it as Current and Active. The system validates successfully, clears any existing current term (none exists), creates the record, logs "Stored" activity, and redirects with "Academic term created successfully."

**SC-002 — Mark a Different Term as Current**
Ms. Sharma creates "Term 2" (not current). Later, she edits Term 2 and toggles "Current Term" on. The `update()` method detects `is_current` changed from false to true, clears the `is_current` flag on Term 1, sets it on Term 2, logs the changes (old Term 1 current=false, Term 2 current=true), and redirects with success.

**SC-003 — Toggle a Term's Active Status via AJAX**
On the Academic Terms list, Ms. Sharma clicks the status switch for Term 2 to deactivate it. The `toggleStatus()` method receives `is_active=0`, validates, sets `is_active=false`, saves, logs "Toggled" with status "Inactive", and returns `{ success: true, is_active: false, message: "Status updated." }`. The UI updates the badge to "Inactive" without a page reload.

**SC-004 — Soft Delete and Restore a Term**
Ms. Sharma deletes Term 2 (past term). The `destroy()` method sets `is_active=false`, `is_current=false`, soft-deletes, and redirects. She then goes to Trash, clicks Restore. The `restore()` method restores the record. The term reappears in the main list with its previous Name, Code, and dates, but `is_active` and `is_current` remain `false`, so she must edit it to reactivate.

---

## Failure Scenarios

**FC-001 — Duplicate Term Code within Same Session**
Ms. Sharma tries to create a second term with code "TERM1" in session 2025–26. The `term_code` custom closure detects an existing record with the same `(academic_session_id, term_code)` combination and returns: "Term code already exists for this academic session." The form is re-displayed with the error highlighted.

**FC-002 — Term Start Date Before Session Start**
Ms. Sharma enters term_start_date = "15-Mar-2025" for a session that starts on "01-Apr-2025". The `term_start_date` custom closure compares the value against `academic_year_start_date` and returns: "Term start date cannot be before academic year start date."

**FC-003 — Teaching Periods Exceed Total Periods**
Ms. Sharma sets Total Periods/Day to 6 and Teaching Periods/Day to 8. The frontend auto-corrects to 6 and shows an alert. If she bypasses the frontend (e.g., curl), the validation closure returns: "Teaching periods cannot exceed total periods per day."

**FC-004 — Database Error During Creation**
If a database constraint (e.g., duplicate entry from a race condition) or server error occurs during `store()`, the catch block rolls back the transaction and redirects with: "Failed to create academic term: <SQL message>".

**FC-005 — Unauthorised Access to Create**
A user without `timetable-foundation.academic-term.create` permission attempts to access the create form. `Gate::authorize()` throws an `AuthorizationException`, resulting in a 403 HTTP response.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_org_academic_sessions_jnt` | FK parent (RESTRICT) | `academic_session_id` FK references `sch_org_academic_sessions_jnt(id)`. A term cannot exist without a parent session; the FK uses ON DELETE RESTRICT — a session with terms cannot be deleted. |
| `tt_activities` | Child (FK cross-reference) | `tt_activities.academic_term_id` references `sch_academic_term(id)` via `fk_activity_session` (ON DELETE RESTRICT). This blocks deleting a term that has activities. |
| `tt_timetables` | Child (FK) | `tt_timetables.academic_term_id` references `sch_academic_term(id)` — no explicit ON DELETE action in DDL, defaults to RESTRICT. |
| `tt_requirement_consolidations` | Child (FK) | `tt_requirement_consolidations.academic_term_id` references `sch_academic_term(id)`. |
| `tt_class_timetable_types_jnt` | Child (FK) | `class_timetable_types_jnt.academic_term_id` references `sch_academic_term(id)` via `fk_cttj_term`. |
| `tt_sub_activities` | Child (FK) | `tt_sub_activities.academic_term_id` references `sch_academic_term(id)` via `fk_sa_academic_term`. |
| `tt_requirement_groups` | Child (FK) | `tt_class_requirement_groups.academic_term_id` — SET NULL on delete. |
| HPC / Hst / PTM / Cafeteria / BehaviouralAssess modules | Cross-module consumers | Multiple modules reference `sch_academic_term` for term scoping (HST: 6 FKs, PTM: FK, CAF: 2 FKs, BA: SET NULL FK, HPC: FK). Deletion of terms referenced by these modules is blocked by FK RESTRICT or silently nullified by SET NULL. |
| `Modules\SchoolSetup\Models\OrganizationAcademicSession` | Service dependency | Used in `create()` and `edit()` to populate the session dropdown. Also used in `timetableConfiguration()` for the session filter. |
| `activityLog()` helper | Service dependency | Called on every state-changing action (store, update, destroy, restore, forceDelete, toggleStatus, toggleCurrent) to record audit entries. |

**Table:** `sch_academic_term`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL. FK → `sch_org_academic_sessions_jnt(id)` (ON DELETE RESTRICT) |
| `academic_year_start_date` | DATE | NOT NULL. Copied from session for convenience |
| `academic_year_end_date` | DATE | NOT NULL. Copied from session for convenience |
| `total_terms_in_academic_session` | TINYINT UNSIGNED | NOT NULL. e.g., 2, 3, 4 |
| `term_ordinal` | TINYINT UNSIGNED | NOT NULL. e.g., 1, 2, 3 |
| `term_code` | VARCHAR(20) | NOT NULL. e.g., 'SUMMER', 'WINTER', 'Q1' |
| `term_name` | VARCHAR(100) | NOT NULL. e.g., 'Summer Term', 'Quarter 1' |
| `term_start_date` | DATE | NOT NULL. Term start |
| `term_end_date` | DATE | NOT NULL. Term end |
| `term_total_teaching_days` | TINYINT UNSIGNED | DEFAULT 5. Teaching days per week |
| `term_total_exam_days` | TINYINT UNSIGNED | DEFAULT 2. Exam days in term |
| `term_week_start_day` | TINYINT UNSIGNED | NOT NULL. 1=Monday … 7=Sunday |
| `term_total_periods_per_day` | TINYINT UNSIGNED | NOT NULL. Includes all period types |
| `term_total_teaching_periods_per_day` | TINYINT UNSIGNED | NOT NULL. Teaching slots only |
| `term_min_resting_periods_per_day` | TINYINT UNSIGNED | NOT NULL. Min free periods |
| `term_max_resting_periods_per_day` | TINYINT UNSIGNED | NOT NULL. Max free periods |
| `term_travel_minutes_between_classes` | TINYINT UNSIGNED | NOT NULL. Minutes |
| `is_current` | BOOLEAN | DEFAULT FALSE |
| `current_flag` | TINYINT(1) | GENERATED ALWAYS AS (CASE WHEN (`is_current` = 1) THEN '1' ELSE NULL END) STORED. Unique index enforces single-current-term |
| `settings_json` | JSON | NULLABLE |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULLABLE. From SoftDeletes trait |

**Unique Keys:**
- `uq_AcademicTerm_currentFlag` — on `current_flag` (generated column; ensures at most one row has `is_current = 1`)
- `uq_AcademicTerm_session_code` — on `(academic_session_id, term_code)` (ensures unique term code per session)

**Indexes:**
- `idx_AcademicTerm_dates` — on `(term_start_date, term_end_date)`
- `idx_AcademicTerm_current` — on `(is_current)`
