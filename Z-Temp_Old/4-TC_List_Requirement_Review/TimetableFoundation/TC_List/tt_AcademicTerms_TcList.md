# tt_AcademicTerms_TcList

## Module: TimetableFoundation → Timetable Configuration → Academic Terms

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Configuration |
| Feature | Academic Terms |
| URL(s) | `GET` `/timetable-foundation/academic-term` (index — redirects to menu), `GET` `/timetable-foundation/academic-term/create` (create form), `POST` `/timetable-foundation/academic-term` (store), `GET` `/timetable-foundation/academic-term/{academic_term}` (show), `GET` `/timetable-foundation/academic-term/{academic_term}/edit` (edit form), `PUT` `/timetable-foundation/academic-term/{academic_term}` (update), `DELETE` `/timetable-foundation/academic-term/{academic_term}` (destroy), `GET` `/timetable-foundation/academic-term/trash/view` (trashed list), `GET` `/timetable-foundation/academic-term/{id}/restore` (restore), `DELETE` `/timetable-foundation/academic-term/{id}/force-delete` (forceDelete), `POST` `/timetable-foundation/academic-term/{academic_term}/toggle-status` (toggleStatus), `GET` `/timetable-foundation/timetable-configuration` (menu — tab page rendering the academic terms list) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\AcademicTermController` |
| Model(s) | `Modules\TimetableFoundation\Models\AcademicTerm` (table: `sch_academic_term`) |
| Validation (Create) | `Modules\TimetableFoundation\Http\Requests\AcademicTermRequest` |
| Validation (Update) | `Modules\TimetableFoundation\Http\Requests\AcademicTermRequest` |
| Policy | `Modules\TimetableFoundation\Policies\AcademicTermPolicy` |
| Permissions | `timetable-foundation.academic-term.viewAny`, `timetable-foundation.academic-term.view`, `timetable-foundation.academic-term.create`, `timetable-foundation.academic-term.update`, `timetable-foundation.academic-term.delete`, `timetable-foundation.academic-term.restore`, `timetable-foundation.academic-term.forceDelete` |
| Pagination | Main list: no pagination (`->get()` fetches all). Trash view: 10 records per page via `paginate(10)` |
| Soft Deletes | Yes (`SoftDeletes` trait on model) |
| Data Source | Table created in `School_Setup` module; editable in `TimetableFoundation` |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled`, `Current Toggled` |

---

## 2. Pre-conditions

- Required permissions: `timetable-foundation.academic-term.viewAny`, `timetable-foundation.academic-term.view`, `timetable-foundation.academic-term.create`, `timetable-foundation.academic-term.update`, `timetable-foundation.academic-term.delete`, `timetable-foundation.academic-term.restore`, `timetable-foundation.academic-term.forceDelete`
- Required seed data: At least one active `OrganizationAcademicSession` record in `sch_org_academic_sessions_jnt` (FK parent)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For `is_current` uniqueness tests: At least 2 academic terms under the same academic session
- For filter tests: At least 2 academic sessions with terms assigned to each

---

## 3. Default Data Load

When the Timetable Configuration page loads via `TimetableFoundationController@timetableConfiguration()` (`GET /timetable-foundation/timetable-configuration`), the Academic Terms tab data is fetched alongside other tab data and passed to the shared view.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Academic Sessions | `timetableConfiguration()` | `OrganizationAcademicSession::orderBy('start_date', 'desc')->get(['id', 'name'])` | None | None |
| Academic Terms Grid | `timetableConfiguration()` | `AcademicTerm::with('academicSession')->orderBy('term_name')` | `at_search` (term_name LIKE), `at_session_id` (academic_session_id =), `at_status` (is_active =, default `'1'`) | None (all records) |
| Trashed Terms Grid | `trashed()` | `AcademicTerm::onlyTrashed()->with('academicSession')->orderBy('deleted_at', 'desc')` | None | 10/page |

> **Data Source:** The `sch_academic_term` table is created in the School_Setup module but its records are managed (Create/Edit/Delete/Restore) through TimetableFoundation. The `OrganizationAcademicSession` parent records originate from School_Setup.

---

## 4. Test Data Strategy

- **Unique identifier:** Use `now()->format('YmdHis')` as a suffix for term_code and term_name to avoid collisions (e.g., `TERM_20260718123456`)
- **Date ranges:** Use a consistent academic session, e.g., `2026-04-01` to `2027-03-31`. Term dates must fall within this range.
- **Pre-test cleanup:** Delete created academic terms by code/name prefix before and after tests to avoid unique constraint violations.
- **Pagination overflow for trash:** Create 11+ soft-deleted terms to verify `paginate(10)` limit on the trash view (10 per page, page 2 shows remaining records).
- **Cross-module data:** Ensure at least one `OrganizationAcademicSession` exists with `is_active=1` before creating academic terms.
- **Day-of-week mapping:** `term_week_start_day` uses integer 1=Monday through 7=Sunday.

---

## 5. Business Conditions

### 5.1 Database Schema — `sch_academic_term`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | academic_session_id | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt(id)` |
| BC-DB-03 | academic_year_start_date | DATE | NOT NULL |
| BC-DB-04 | academic_year_end_date | DATE | NOT NULL |
| BC-DB-05 | total_terms_in_academic_session | TINYINT UNSIGNED | NOT NULL |
| BC-DB-06 | term_ordinal | TINYINT UNSIGNED | NOT NULL |
| BC-DB-07 | term_code | VARCHAR(20) | NOT NULL |
| BC-DB-08 | term_name | VARCHAR(100) | NOT NULL |
| BC-DB-09 | term_start_date | DATE | NOT NULL |
| BC-DB-10 | term_end_date | DATE | NOT NULL |
| BC-DB-11 | term_total_teaching_days | TINYINT UNSIGNED | DEFAULT 5 |
| BC-DB-12 | term_total_exam_days | TINYINT UNSIGNED | DEFAULT 2 |
| BC-DB-13 | term_week_start_day | TINYINT UNSIGNED | NOT NULL |
| BC-DB-14 | term_total_periods_per_day | TINYINT UNSIGNED | NOT NULL |
| BC-DB-15 | term_total_teaching_periods_per_day | TINYINT UNSIGNED | NOT NULL |
| BC-DB-16 | term_min_resting_periods_per_day | TINYINT UNSIGNED | NOT NULL |
| BC-DB-17 | term_max_resting_periods_per_day | TINYINT UNSIGNED | NOT NULL |
| BC-DB-18 | term_travel_minutes_between_classes | TINYINT UNSIGNED | NOT NULL |
| BC-DB-19 | is_current | BOOLEAN | DEFAULT FALSE |
| BC-DB-20 | current_flag | TINYINT(1) | GENERATED ALWAYS AS (CASE WHEN is_current=1 THEN 1 ELSE NULL END) STORED |
| BC-DB-21 | settings_json | JSON | DEFAULT NULL |
| BC-DB-22 | is_active | BOOLEAN | DEFAULT TRUE |
| BC-DB-23 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-24 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-25 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-26 | **UNIQUE KEY** | — | `uq_AcademicTerm_currentFlag` on (`current_flag`) |
| BC-DB-27 | **UNIQUE KEY** | — | `uq_AcademicTerm_session_code` on (`academic_session_id`, `term_code`) |
| BC-DB-28 | **INDEX** | — | `idx_AcademicTerm_dates` on (`term_start_date`, `term_end_date`) |
| BC-DB-29 | **INDEX** | — | `idx_AcademicTerm_current` on (`is_current`) |

### 5.2 Validation Rules — `AcademicTermRequest` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | academic_session_id | required, exists:sch_org_academic_sessions_jnt,id | "The selected academic session is invalid." |
| BC-VAL-02 | academic_year_start_date | required, date | — |
| BC-VAL-03 | academic_year_end_date | required, date, after_or_equal:academic_year_start_date | — |
| BC-VAL-04 | total_terms_in_academic_session | required, integer, min:1, max:12 | — |
| BC-VAL-05 | term_ordinal | required, integer, min:1, max:12 + custom unique per session | "Term ordinal already exists for this academic session." |
| BC-VAL-06 | term_code | required, string, max:20 + custom unique per session | "Term code already exists for this academic session." |
| BC-VAL-07 | term_name | required, string, max:100 | — |
| BC-VAL-08 | term_start_date | required, date + custom ≥ academic_year_start_date | "Term start date cannot be before academic year start date." |
| BC-VAL-09 | term_end_date | required, date, after_or_equal:term_start_date + custom ≤ academic_year_end_date | "Term end date cannot be after academic year end date." |
| BC-VAL-10 | term_total_teaching_days | required, integer, min:1, max:7 | — |
| BC-VAL-11 | term_total_exam_days | required, integer, min:0, max:7 | — |
| BC-VAL-12 | term_week_start_day | required, integer, min:1, max:7 | — |
| BC-VAL-13 | term_total_periods_per_day | required, integer, min:1, max:20 | — |
| BC-VAL-14 | term_total_teaching_periods_per_day | required, integer, min:1, max:20 + custom ≤ term_total_periods_per_day | "Teaching periods cannot exceed total periods per day." |
| BC-VAL-15 | term_min_resting_periods_per_day | required, integer, min:0, max:10 | — |
| BC-VAL-16 | term_max_resting_periods_per_day | required, integer, min:0, max:10, gte:term_min_resting_periods_per_day | — |
| BC-VAL-17 | term_travel_minutes_between_classes | required, integer, min:0, max:60 | — |
| BC-VAL-18 | is_current | boolean | — |
| BC-VAL-19 | settings_json | nullable, json | — |
| BC-VAL-20 | is_active | boolean | — |

### 5.3 Validation Rules — `AcademicTermRequest` (Update)

All Create rules apply (BC-VAL-01 to BC-VAL-20). The custom unique validators for `term_ordinal` and `term_code` ignore the current record's ID:

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | term_ordinal (update) | required, integer, min:1, max:12 + custom unique per session ignoring own ID | "Term ordinal already exists for this academic session." |
| BC-VAL-U02 | term_code (update) | required, string, max:20 + custom unique per session ignoring own ID | "Term code already exists for this academic session." |

### 5.4 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | `timetable-foundation.academic-term.viewAny` | `index()` | Without → 403 Forbidden |
| BC-AUTH-02 | `timetable-foundation.academic-term.view` | `show()` | Without → 403 Forbidden |
| BC-AUTH-03 | `timetable-foundation.academic-term.create` | `create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-04 | `timetable-foundation.academic-term.update` | `edit()`, `update()`, `toggleStatus()`, `toggleCurrent()` | Without → 403 Forbidden |
| BC-AUTH-05 | `timetable-foundation.academic-term.delete` | `destroy()` | Without → 403 Forbidden |
| BC-AUTH-06 | `timetable-foundation.academic-term.restore` | `trashed()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-07 | `timetable-foundation.academic-term.forceDelete` | `forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-08 | Guest access | All routes | Redirect to `/login` |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Academic Terms tab loads via `timetableConfiguration()` at `GET /timetable-foundation/timetable-configuration?tab=academic-terms` | Academic Terms list is rendered with all active (`is_active=1` by default) records; session filter dropdown, search input, and status filter present |
| BC-BIZ-02 | Filter by `at_session_id` | Terms grid filtered to show only terms belonging to the selected academic session |
| BC-BIZ-03 | Search by `at_search` (term_name) | Terms grid filtered to show only terms whose `term_name` contains the search string (LIKE match) |
| BC-BIZ-04 | Filter by `at_status` (is_active) | Terms grid filtered to show active (1) or inactive (0); default is active (1) |
| BC-BIZ-05 | Create with `is_current=true` | Only ONE term per academic session can be `is_current=true`. Controller sets all other terms in same session to `is_current=false` before saving the new current term. |
| BC-BIZ-06 | Create — Max resting periods auto-correction | If `term_max_resting_periods_per_day < term_min_resting_periods_per_day`, max is set equal to min (controller-level correction). |
| BC-BIZ-07 | Update — Setting another term as current | Controller sets all other terms in the same academic session (except current term) to `is_current=false` when the edited term becomes current. |
| BC-BIZ-08 | Update — Max resting periods auto-correction | Same as BC-BIZ-06 during update. |
| BC-BIZ-09 | Soft delete sets `is_active=false`, `is_current=false` | `destroy()` sets both `is_active` and `is_current` to `false` before calling `$academic_term->delete()`. |
| BC-BIZ-10 | Restore does not restore `is_active`/`is_current` | `restore()` only nullifies `deleted_at`; `is_active` and `is_current` remain as they were at delete time (both false). |
| BC-BIZ-11 | forceDelete permanently removes record | `forceDelete()` removes the record from DB irreversibly; no restore possible. |
| BC-BIZ-12 | Toggle status via AJAX | `toggleStatus()` accepts `is_active` (boolean), saves, returns JSON `{success, is_active, message}`. |
| BC-BIZ-13 | Term dates constrained by session dates | `term_start_date` must be ≥ `academic_year_start_date`; `term_end_date` must be ≤ `academic_year_end_date`. |
| BC-BIZ-14 | Term ordinal uniqueness per session | Each `term_ordinal` must be unique within an academic session. |
| BC-BIZ-15 | Term code uniqueness per session | Each `term_code` must be unique within an academic session. |
| BC-BIZ-16 | `prepareForValidation()` normalizes checkboxes | `is_current` and `is_active` become `true`/`false` based on checkbox presence in request. |
| BC-BIZ-17 | `prepareForValidation()` encodes settings JSON | If `settings_json` is an array, it is JSON-encoded before validation. |
| BC-BIZ-18 | Empty state — no academic terms exist | Table shows "No records found" in a single row across all columns. |
| BC-BIZ-19 | Empty state — no trashed terms | Trash view shows "No trashed academic terms found". |
| BC-BIZ-20 | Screen loads via `TimetableFoundationController@timetableConfiguration()` at `GET /timetable-foundation/timetable-configuration` with `tab=academic-terms` | Navigating to the URL with appropriate permissions loads the Timetable Configuration page; the Academic Terms tab pane is rendered and populated with data. |
| BC-BIZ-21 | `current_flag` is a STORED GENERATED column | The column auto-computes: `1` when `is_current=1`, otherwise `NULL`. It must never be written via Eloquent (omitted from `$fillable`). Unique constraint `uq_AcademicTerm_currentFlag` enforces only one non-NULL row globally. |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | `sch_org_academic_sessions_jnt(id)` | RESTRICT (default — no ON DELETE specified in DDL) |

> **Note:** Multiple tables across modules reference `sch_academic_term.id` as FK: `tt_class_timetable_type_jnt`, `tt_sub_activities`, `tt_class_group_requirements`, `tt_activity`, `caf_daily_menu`, `caf_special_plans`, `ptm_events`, `ba_periods`, `hst_hostel_allotments`, `reports`, etc. These use various ON DELETE actions (RESTRICT, SET NULL). Delete from this feature is soft-delete only; `forceDelete` may be blocked by active FK references at the DB level.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Academic Terms Tab Loads With All UI Elements | Tab pane loads with session filter dropdown (default "All Sessions"), search input (placeholder "Search by term name..."), status filter (default "Active"), reset button, table with columns (#, Name, Code, Session, Start, End, Status, Action), and Create button | — | — | ⬜ |
| TC-P02 | Filter Terms By Academic Session | Select a specific session from dropdown; page reloads; grid shows only terms belonging to that session | — | — | ⬜ |
| TC-P03 | Search Terms By Name | Type a term name fragment and submit; grid shows only terms whose name contains the search string | — | — | ⬜ |
| TC-P04 | Filter Terms By Status (Active/Inactive/All) | Select "Inactive" from status filter; grid shows only inactive terms. Select "All Status"; grid shows all terms regardless of status | — | — | ⬜ |
| TC-P05 | Reset Filters Button Clears All Filters | Click reset button; all filters cleared; grid shows default (all active terms) | — | — | ⬜ |
| TC-P06 | Create Term With Required Fields Only | Fill academic_session_id, total_terms=2, term_ordinal=1, term_code="TERM1", term_name="Term 1", start/end dates, teaching_days=5, exam_days=2, week_start_day=1, total_periods=8, teaching_periods=6, min_resting=0, max_resting=2, travel_minutes=5. Submit. Term created successfully with `is_active=true`, `is_current=false`, redirect to timetable configuration page with success message | — | — | ⬜ |
| TC-P07 | Create Term With All Optional Fields | Same as TC-P06 + `is_current=true`, `settings_json={"key":"value"}`. Term created with `is_current=true` (all other terms in same session set to `is_current=false`), settings saved as JSON | — | — | ⬜ |
| TC-P08 | Create Term With `is_active=false` | Set active toggle to OFF. Term created with `is_active=false`; term excluded from dropdowns and active-only queries | — | — | ⬜ |
| TC-P09 | Create Term With Max Resting Periods Auto-Correction | Set `term_min_resting_periods_per_day=3`, `term_max_resting_periods_per_day=1`. Controller auto-corrects max to 3 (equal to min). Record saved with both values = 3 | — | — | ⬜ |
| TC-P10 | View Term Details Page | Click View action; show page loads with all fields displayed: name, code, session name, academic year range, term period, ordinal, week start day, teaching days, exam days, periods counts, resting range, travel minutes, current/active badges, timestamps, settings JSON (if present) | — | — | ⬜ |
| TC-P11 | Edit Term Loads Pre-Filled Data | Click Edit action; edit form loads with existing values for all fields pre-filled | — | — | ⬜ |
| TC-P12 | Update Term Name And Code | Change `term_name` and `term_code`; submit update. Term updated; redirect to configuration with success message | — | — | ⬜ |
| TC-P13 | Update Term To Make It Current | Toggle `is_current=ON` on a non-current term. Term becomes current; all other terms in same session become non-current | — | — | ⬜ |
| TC-P14 | Update All Term Fields | Modify every field of an existing term; all field values updated correctly in DB | — | — | ⬜ |
| TC-P15 | Toggle Status Active → Inactive | Click status toggle on an active term; AJAX POST to `toggle-status`. Term becomes inactive; JSON response `{success: true, is_active: false}` | — | — | ⬜ |
| TC-P16 | Toggle Status Inactive → Active | Click status toggle on an inactive term. Term becomes active; JSON response `{success: true, is_active: true}` | — | — | ⬜ |
| TC-P17 | Soft Delete Term | Click Delete on an active term. Term's `is_active` set to false, `is_current` set to false, `deleted_at` set. Record appears in trash view. Redirect to configuration with success message | — | — | ⬜ |
| TC-P18 | View Trashed Terms List | Navigate to trash view; all soft-deleted terms listed with term name, session, dates, ordinal, deleted_at timestamp, and Restore/Force Delete action buttons | — | — | ⬜ |
| TC-P19 | Restore Soft-Deleted Term | Click Restore on a trashed term. `deleted_at` nullified; term restored. Redirect to trash view with success message. Term reappears in main list (with `is_active=false`, `is_current=false`) | — | — | ⬜ |
| TC-P20 | Force Delete Term | Click Force Delete on a trashed term. Term permanently removed from DB. Redirect to trash view with success message | — | — | ⬜ |
| TC-P21 | Trash View Pagination | Create 11+ soft-deleted terms; trash view shows 10 per page; page 2 shows remaining records | — | — | ⬜ |
| TC-P22 | Full Lifecycle: Create → View → Edit → Toggle Status → Soft Delete → Restore → Force Delete | Each step in sequence succeeds; data transitions correctly at each stage | — | — | ⬜ |
| TC-P23 | Empty State — No Terms Exist | When no academic terms exist, list table shows "No records found" | — | — | ⬜ |
| TC-P24 | Empty State — No Trashed Terms | When no trashed terms exist, trash view shows "No trashed academic terms found" | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `academic_session_id` | Validation error: "The academic session field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing `term_name` | Validation error: "The term name field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `term_code` | Validation error: "The term code field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `term_start_date` | Validation error: "The term start date field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `term_end_date` | Validation error: "The term end date field is required." | — | — | ⬜ |
| TC-N06 | Invalid — `term_end_date` Before `term_start_date` | Validation error: "The term end date must be a date after or equal to term start date." | — | — | ⬜ |
| TC-N07 | Invalid — `term_start_date` Before `academic_year_start_date` | Validation error: "Term start date cannot be before academic year start date." | — | — | ⬜ |
| TC-N08 | Invalid — `term_end_date` After `academic_year_end_date` | Validation error: "Term end date cannot be after academic year end date." | — | — | ⬜ |
| TC-N09 | Invalid — `academic_year_end_date` Before `academic_year_start_date` | Validation error: "The academic year end date must be a date after or equal to academic year start date." | — | — | ⬜ |
| TC-N10 | Invalid — Total Terms < 1 | Validation error: `total_terms_in_academic_session` min:1 | — | — | ⬜ |
| TC-N11 | Invalid — Total Terms > 12 | Validation error: `total_terms_in_academic_session` max:12 | — | — | ⬜ |
| TC-N12 | Invalid — Term Ordinal Duplicate Within Session | Provide a `term_ordinal` that already exists in the same session. Validation error: "Term ordinal already exists for this academic session." | — | — | ⬜ |
| TC-N13 | Invalid — Term Code Duplicate Within Session | Provide a `term_code` that already exists in the same session. Validation error: "Term code already exists for this academic session." | — | — | ⬜ |
| TC-N14 | Invalid — Teaching Periods > Total Periods Per Day | Set `term_total_teaching_periods_per_day` > `term_total_periods_per_day`. Validation error: "Teaching periods cannot exceed total periods per day." | — | — | ⬜ |
| TC-N15 | Invalid — Max Resting Periods < Min Resting Periods | Set `term_max_resting_periods_per_day` < `term_min_resting_periods_per_day`. Validation rule `gte` catches this. Error: validation of gte rule | — | — | ⬜ |
| TC-N16 | Invalid — Non-Existent `academic_session_id` | Validation error: "The selected academic session is invalid." | — | — | ⬜ |
| TC-N17 | Invalid — `term_code` Exceeds 20 Characters | Validation error on `term_code` max:20 | — | — | ⬜ |
| TC-N18 | Invalid — `term_name` Exceeds 100 Characters | Validation error on `term_name` max:100 | — | — | ⬜ |
| TC-N19 | Invalid — `settings_json` Is Not Valid JSON | Enter non-JSON text. Validation error: "The settings JSON must be a valid JSON string." | — | — | ⬜ |
| TC-N20 | Permission 403 — No `timetable-foundation.academic-term.viewAny` | User without viewAny permission → 403 Forbidden on accessing the tab page | — | — | ⬜ |
| TC-N21 | Permission 403 — No `timetable-foundation.academic-term.create` | User without create permission → 403 Forbidden on create form (`GET`) and store (`POST`) | — | — | ⬜ |
| TC-N22 | Permission 403 — No `timetable-foundation.academic-term.update` | User without update permission → 403 Forbidden on edit form, update, and toggleStatus | — | — | ⬜ |
| TC-N23 | Permission 403 — No `timetable-foundation.academic-term.delete` | User without delete permission → 403 Forbidden on destroy | — | — | ⬜ |
| TC-N24 | Permission 403 — No `timetable-foundation.academic-term.restore` | User without restore permission → 403 Forbidden on trashed list and restore action | — | — | ⬜ |
| TC-N25 | Permission 403 — No `timetable-foundation.academic-term.forceDelete` | User without forceDelete permission → 403 Forbidden on forceDelete | — | — | ⬜ |
| TC-N26 | Guest Access Redirect | Unauthenticated user accessing any academic-term route → redirected to `/login` | — | — | ⬜ |
| TC-N27 | View Non-Existent Term (404) | `GET /timetable-foundation/academic-term/99999` → 404 Not Found via implicit model binding | — | — | ⬜ |
| TC-N28 | Edit Non-Existent Term (404) | `GET /timetable-foundation/academic-term/99999/edit` → 404 Not Found | — | — | ⬜ |
| TC-N29 | Update Non-Existent Term (404) | `PUT /timetable-foundation/academic-term/99999` → 404 Not Found | — | — | ⬜ |
| TC-N30 | Delete Non-Existent Term (404) | `DELETE /timetable-foundation/academic-term/99999` → 404 Not Found | — | — | ⬜ |
| TC-N31 | Restore Non-Existent Term (404) | `GET /timetable-foundation/academic-term/99999/restore` → 404 Not Found via `findOrFail` | — | — | ⬜ |
| TC-N32 | Force Delete Non-Existent Term (404) | `DELETE /timetable-foundation/academic-term/99999/force-delete` → 404 Not Found via `findOrFail` | — | — | ⬜ |
| TC-N33 | Toggle Status On Non-Existent Term (404) | `POST /timetable-foundation/academic-term/99999/toggle-status` → 404 Not Found via implicit model binding | — | — | ⬜ |
| TC-N34 | XSS Injection In `term_name` | Store term with `<script>alert('xss')</script>` as name; Blades `{{ }}` escapes output; no script execution in list/show views | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Current Term → All Other Terms In Same Session Set To Non-Current | Creating a term with `is_current=true` when another current term exists in the same session automatically sets the existing term to `is_current=false` | — | — | ⬜ |
| TC-D02 | A | Update Term To Current → Previous Current Term Becomes Non-Current | Updating a term to `is_current=true` unsets `is_current` for all other terms in the same session | — | — | ⬜ |
| TC-D03 | A | DB Enforced — Only One Current Term Globally Via `uq_AcademicTerm_currentFlag` | Direct DB insert of a second term with `is_current=1` fails with integrity constraint violation because `current_flag` generated column must be unique (non-NULL only once) | — | — | ⬜ |
| TC-D04 | B | Controller Auto-Corrects Max Resting Periods On Create | When `term_max_resting_periods_per_day` < `term_min_resting_periods_per_day`, max is set equal to min before create | — | — | ⬜ |
| TC-D05 | B | Controller Auto-Corrects Max Resting Periods On Update | Same auto-correction applies during update | — | — | ⬜ |
| TC-D06 | C | Term Dates Constrained Within Session Dates | `term_start_date` cannot be before `academic_year_start_date`; `term_end_date` cannot be after `academic_year_end_date` — validated in request | — | — | ⬜ |
| TC-D07 | D | Term Ordinal Unique Per Session (Controller) | Creating a term with duplicate ordinal in same session rejected with custom validation error | — | — | ⬜ |
| TC-D08 | D | Term Ordinal Unique Per Session (Update Ignores Own ID) | Updating a term without changing its ordinal passes validation (own ordinal excluded from uniqueness check) | — | — | ⬜ |
| TC-D09 | E | Term Code Unique Per Session (Controller) | Creating a term with duplicate code in same session rejected with custom validation error | — | — | ⬜ |
| TC-D10 | E | Term Code Unique Per Session — Same Code Allowed In Different Session | Two terms in different sessions can share the same `term_code` | — | — | ⬜ |
| TC-D11 | F | Delete Academic Session Referenced By Term (RESTRICT) | Deleting an `OrganizationAcademicSession` that has associated academic terms fails at DB level (FK RESTRICT) | — | — | ⬜ |
| TC-D12 | G | Soft Delete Sets `is_active=false` and `is_current=false` | `destroy()` sets both flags to false before soft-deleting; after delete, record has `is_active=0`, `is_current=0`, `deleted_at` timestamp | — | — | ⬜ |
| TC-D13 | G | Restore Does Not Restore `is_active` Or `is_current` | After restore, `is_active` and `is_current` remain `0`; `deleted_at` becomes NULL | — | — | ⬜ |
| TC-D14 | H | Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD Operations | `activityLog('Stored')` after create; `activityLog('Updated')` after update; `activityLog('Trashed')` after destroy; `activityLog('Restored')` after restore; `activityLog('Deleted')` after forceDelete; `activityLog('Toggled')` after toggleStatus; each entry contains performed_by, message, and context data | — | — | ⬜ |
| TC-D15 | I | Unit \| P1 \| AcademicTerm model — `$casts` — Boolean/Date/Array Casting | `is_active`, `is_current` stored as TINYINT but accessed as boolean; `academic_year_start_date`, `academic_year_end_date`, `term_start_date`, `term_end_date` cast to date; `settings_json` cast to array | — | — | ⬜ |
| TC-D16 | J | Unit \| P1 \| AcademicTerm model — `$fillable` Matches DDL Columns | `$fillable` array contains all 18 writable columns; `current_flag` intentionally omitted (generated column must not be written) | — | — | ⬜ |
| TC-D17 | K | Unit \| P1 \| AcademicTerm model — SoftDeletes Trait | `delete()` sets `deleted_at`; `restore()` nullifies `deleted_at`; `withTrashed()` includes soft-deleted; `onlyTrashed()` filters to deleted only | — | — | ⬜ |
| TC-D18 | L | Unit \| P1 \| AcademicTerm model — belongsTo AcademicSession Relationship | `$term->academicSession` returns correct `OrganizationAcademicSession` model; `$term->academicSession()->associate($session)` sets `academic_session_id`; eager loading `AcademicTerm::with('academicSession')` loads parent in 1 query | — | — | ⬜ |
| TC-D19 | M | Integration \| P1 \| Controller — `findOrFail` — edit/update/show/destroy/restore/forceDelete/toggleStatus with Valid and Invalid IDs | Valid ID loads model successfully; Invalid (non-existent) ID throws `ModelNotFoundException` → HTTP 404 for all seven methods | — | — | ⬜ |
| TC-D20 | N | Integration \| P1 \| Controller — `Gate::authorize()` — Authorization Before All Methods | `Gate::authorize('timetable-foundation.academic-term.*')` called before every controller action; without appropriate permission → 403 Forbidden | — | — | ⬜ |
| TC-D21 | O | Unit \| P1 \| AcademicTermRequest — `prepareForValidation()` Bool Normalization | `is_current` and `is_active` become `true` when checkbox value is present in request, `false` when absent; `settings_json` auto-encoded from array to JSON string | — | — | ⬜ |
| TC-D22 | P | Unit \| P1 \| AcademicTermPolicy — All Policy Gates Defined | Policy defines 7 gates: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`; each delegates to matching permission string; policy registered via `Gate::policy()` in service provider | — | — | ⬜ |
| TC-D23 | Q | Integration \| P1 \| Routes — Resource + Custom Routes Registered | Resource routes: index(GET), create(GET), store(POST), show(GET), edit(GET), update(PUT/PATCH), destroy(DELETE); Custom routes: trashed(GET), restore(GET), forceDelete(DELETE), toggleStatus(POST); each maps to correct controller method | — | — | ⬜ |
| TC-D24 | R | Integration \| P1 \| Controller — `toggleStatus()` Returns JSON | AJAX POST returns JSON `{success: true/false, is_active: bool, message: string}`; on failure, `success: false` and appropriate error message | — | — | ⬜ |
| TC-D25 | S | Integration \| P1 \| Controller — `store()` DB Transaction — Rollback On Exception | If any exception occurs during `store()`, DB transaction is rolled back; no partial data persists; user redirected back with error message | — | — | ⬜ |
| TC-D26 | S | Integration \| P1 \| Controller — `update()` DB Transaction — Rollback On Exception | Same transaction rollback behavior on `update()` | — | — | ⬜ |
| TC-D27 | T | Index Redirects To Timetable Configuration Page | `GET /timetable-foundation/academic-term` redirects to `GET /timetable-foundation/timetable-configuration` (HTTP 302) | — | — | ⬜ |
| TC-D28 | U | Unit \| P1 \| AcademicTerm model — `scopeActive()` and `scopeCurrent()` | `AcademicTerm::active()` applies `where('is_active', true)`; `AcademicTerm::current()` applies `where('is_current', true)`; both return correct filtered collections | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns (mass-assignment protection) | `$fillable` array contains exactly the 18 writable columns from `sch_academic_term`; `current_flag`, `id`, `created_at`, `updated_at`, `deleted_at` are NOT fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/decimals/dates | `is_active` → boolean, `is_current` → boolean, `academic_year_start_date`/`end_date` → date, `term_start_date`/`end_date` → date, `settings_json` → array, `current_flag` → integer | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `use SoftDeletes;` in model; `deleted_at` column exists in table; `delete()` sets `deleted_at`; `restore()` nullifies `deleted_at`; `forceDelete()` permanently removes | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined (belongsTo per FK) | `academicSession()` → `belongsTo(OrganizationAcademicSession::class)`; `scopeActive()` and `scopeCurrent()` defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | `store()`, `update()`, `destroy()`, `toggleCurrent()` use try-catch blocks; on exception → rollback + redirect back with error message / JSON error response | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `store()`, `update()`, `destroy()`, `toggleCurrent()` use `DB::beginTransaction()` + `DB::commit()`/`DB::rollBack()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Every controller method calls `Gate::authorize()` with its respective permission string before logic; `getSessionDates()` is auth-exempt (AJAX helper) | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called in `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()` with appropriate event name and context data | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` and `is_current=false` before `delete()`; `restore()` does NOT set `is_active=true` (remains false after restore) | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | `toggleStatus()` receives `is_active` from request, sets `$academic_term->is_active = $newStatus`, saves; returns JSON with new is_active value | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashed()` uses `onlyTrashed()->paginate(10)`; `restore($id)` uses `onlyTrashed()->findOrFail($id)->restore()`; `forceDelete($id)` uses `withTrashed()->findOrFail($id)->forceDelete()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — redirect/JSON response after create/update/delete | `store()`/`update()`/`destroy()` → `redirect()->route('timetable-foundation.menu.timetableConfiguration')->with('success', flash(...))`; `toggleStatus()` → `response()->json([...])`; `restore()`/`forceDelete()` → `redirect()->route('timetable-foundation.academic-term.trashed')` | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — validation rules cover all fields; unique rules ignore current ID on update | All 17 required/optional fields validated; `term_code` and `term_ordinal` custom unique validations exclude current ID on update via `$academicTerm` parameter | — | — | ◌ |
| TC-CR14 | CR | P1 | Request — `prepareForValidation()` normalizations | `is_current`/`is_active` merged as boolean from checkbox presence; `settings_json` encoded from array to string if needed | — | — | ◌ |
| TC-CR15 | CR | P1 | Policy — all required methods defined; permission strings match route/gate names | Policy defines `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`; each maps to `timetable-foundation.academic-term.{action}` | — | — | ◌ |
| TC-CR16 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | Resource route for `academic-term`; custom routes for `trashed`, `restore`, `forceDelete`, `toggleStatus`; implicit model binding on `{academic_term}` throws 404 automatically | — | — | ◌ |
| TC-CR17 | CR | P1 | View — Blade `@can` directives on tab/action buttons | `_list.blade.php` uses status switch component and action buttons (View, Edit); create form and edit form available via separate views; all guarded by permissions | — | — | ◌ |
| TC-CR18 | CR | P1 | View — `isset()`/null-safe checks for relationship variables | `$term->academicSession->name ?? '--'` pattern used in `_list.blade.php`; null-safe access for dates via `$term->term_start_date?->format(...)` pattern used | — | — | ◌ |
| TC-CR19 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` and renders correct hierarchy | Each view (create, edit, show, trash) defines its own breadcrumb via `x-backend.components.breadcrum` component with title and links | — | — | ◌ |
| TC-CR20 | CR | P1 | Database — unique indexes match request validation rules | `uq_AcademicTerm_session_code` on `(academic_session_id, term_code)` matches custom validation "term code already exists for this academic session"; `uq_AcademicTerm_currentFlag` on `current_flag` enforces single current term constraint | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns (Mass-Assignment Protection)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AcademicTerm.php` model | Model found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains exactly: `academic_session_id`, `academic_year_start_date`, `academic_year_end_date`, `total_terms_in_academic_session`, `term_ordinal`, `term_code`, `term_name`, `term_start_date`, `term_end_date`, `term_total_teaching_days`, `term_total_exam_days`, `term_week_start_day`, `term_total_periods_per_day`, `term_total_teaching_periods_per_day`, `term_min_resting_periods_per_day`, `term_max_resting_periods_per_day`, `term_travel_minutes_between_classes`, `is_current`, `settings_json`, `is_active` |
| 3 | Verify `current_flag` is NOT in `$fillable` | `current_flag` is intentionally omitted (generated column must never be written) |
| 4 | Verify no DDL column is missing from `$fillable` | All writable columns from DDL are present |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Decimals/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` property in model | `is_active` → boolean, `is_current` → boolean, `settings_json` → array, `current_flag` → integer |
| 2 | Verify date casts | `academic_year_start_date` → date, `academic_year_end_date` → date, `term_start_date` → date, `term_end_date` → date |
| 3 | Create a term and fetch it | All cast fields return correct PHP types (bool/array/Carbon) |

#### TC-CR03: Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model for `use SoftDeletes` | `use Illuminate\Database\Eloquent\SoftDeletes;` present |
| 2 | Verify `deleted_at` column exists in DDL | `deleted_at` column is nullable TIMESTAMP |
| 3 | Soft delete a record | `deleted_at` set to current timestamp; record excluded from normal queries |
| 4 | Call `withTrashed()` | Record appears in results |
| 5 | Call `onlyTrashed()` | Only soft-deleted records appear |
| 6 | Restore the record | `deleted_at` set to NULL; record visible in normal queries |

#### TC-CR04: Model — Relationships Defined (belongsTo Per FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `academicSession()` relationship | Returns `belongsTo(OrganizationAcademicSession::class, 'academic_session_id')` |
| 2 | Inspect scope methods | `scopeActive()` applies `where('is_active', true)`; `scopeCurrent()` applies `where('is_current', true)` |

#### TC-CR05: Controller — Try-Catch Exception Handling on All Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AcademicTermController.php` | Controller found |
| 2 | Inspect `store()` method | Try-catch block wraps all logic; catch block calls `DB::rollBack()` and returns redirect back with error message |
| 3 | Inspect `update()` method | Same try-catch pattern as store |
| 4 | Inspect `destroy()` method | Try-catch wraps set flags + delete + activity log; catch rolls back |
| 5 | Inspect `toggleCurrent()` method | Try-catch wraps transaction; catch returns JSON error response |
| 6 | Verify `restore()` and `forceDelete()` | `restore()` has no try-catch (single statement); `forceDelete()` has no try-catch (single statement) |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | `DB::beginTransaction()` before processing; `DB::commit()` after success; `DB::rollBack()` on exception |
| 2 | Inspect `update()` | Same transaction pattern |
| 3 | Inspect `destroy()` | Same transaction pattern |
| 4 | Inspect `toggleCurrent()` | Same transaction pattern |
| 5 | Inspect `restore()` | No transaction (single operation) |
| 6 | Inspect `forceDelete()` | No transaction (single operation) |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` | `Gate::authorize('timetable-foundation.academic-term.viewAny')` |
| 2 | Inspect `create()` | `Gate::authorize('timetable-foundation.academic-term.create')` |
| 3 | Inspect `store()` | `Gate::authorize('timetable-foundation.academic-term.create')` |
| 4 | Inspect `show()` | `Gate::authorize('timetable-foundation.academic-term.view')` |
| 5 | Inspect `edit()` | `Gate::authorize('timetable-foundation.academic-term.update')` |
| 6 | Inspect `update()` | `Gate::authorize('timetable-foundation.academic-term.update')` |
| 7 | Inspect `destroy()` | `Gate::authorize('timetable-foundation.academic-term.delete')` |
| 8 | Inspect `trashed()` | `Gate::authorize('timetable-foundation.academic-term.restore')` |
| 9 | Inspect `restore()` | `Gate::authorize('timetable-foundation.academic-term.restore')` |
| 10 | Inspect `forceDelete()` | `Gate::authorize('timetable-foundation.academic-term.forceDelete')` |
| 11 | Inspect `toggleStatus()` | `Gate::authorize('timetable-foundation.academic-term.update')` |
| 12 | Inspect `toggleCurrent()` | `Gate::authorize('timetable-foundation.academic-term.update')` |
| 13 | Verify `getSessionDates()` | No gate (auth-exempt AJAX helper) |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | `activityLog($academicTerm, 'Stored', [...])` with message, academic_session, term, performed_by |
| 2 | Inspect `update()` | `activityLog($academicTerm, 'Updated', [...])` with changes array |
| 3 | Inspect `destroy()` | `activityLog($academicTerm, 'Trashed', [...])` |
| 4 | Inspect `restore()` | `activityLog($academicTerm, 'Restored', [...])` |
| 5 | Inspect `forceDelete()` | `activityLog($academicTerm, 'Deleted', [...])` |
| 6 | Inspect `toggleStatus()` | `activityLog($academicTerm, 'Toggled', [...])` with status |
| 7 | Inspect `toggleCurrent()` | `activityLog($academicTerm, 'Current Toggled', [...])` |

#### TC-CR09: Controller — `is_active=false` Before Soft Delete; Restore Does Not Set Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `$academic_term->update(['is_active' => false, 'is_current' => false])` called BEFORE `$academic_term->delete()` |
| 2 | Verify `restore()` does not set `is_active=true` | `restore()` only calls `$academicTerm->restore()`; no update to `is_active` |
| 3 | Create term, delete it, restore it | Term restored with `is_active=0`, `is_current=0` |

#### TC-CR10: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` | Receives `is_active` from request; sets `$academic_term->is_active = $newStatus`; calls `$academic_term->save()` |
| 2 | Verify response | `response()->json(['success' => true, 'is_active' => $academic_term->is_active, 'message' => flash('status_updated.academic-term')])` |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashed()` | `AcademicTerm::onlyTrashed()->with('academicSession')->orderBy('deleted_at', 'desc')->paginate(10)` |
| 2 | Inspect `restore($id)` | `AcademicTerm::onlyTrashed()->findOrFail($id)->restore()` |
| 3 | Inspect `forceDelete($id)` | `AcademicTerm::withTrashed()->findOrFail($id)->forceDelete()` |

#### TC-CR12: Controller — Redirect/JSON Response After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` success | `redirect()->route('timetable-foundation.menu.timetableConfiguration')->with('success', flash('created.academic-term'))` |
| 2 | Inspect `update()` success | `redirect()->route('timetable-foundation.menu.timetableConfiguration')->with('success', flash('updated.academic-term'))` |
| 3 | Inspect `destroy()` success | `redirect()->route('timetable-foundation.menu.timetableConfiguration')->with('success', flash('trashed.academic-term'))` |
| 4 | Inspect `restore()` success | `redirect()->route('timetable-foundation.academic-term.trashed')->with('success', flash('restored.academic-term'))` |
| 5 | Inspect `forceDelete()` success | `redirect()->route('timetable-foundation.academic-term.trashed')->with('success', flash('force_deleted.academic-term'))` |
| 6 | Inspect `toggleStatus()` response | JSON with `success`, `is_active`, `message` |

#### TC-CR13: Request — Validation Rules Cover All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AcademicTermRequest.php` | Request found |
| 2 | Inspect `rules()` method | All fields from DDL are validated (academic_session_id, academic_year_start_date, academic_year_end_date, total_terms, term_ordinal, term_code, term_name, term_start_date, term_end_date, teaching_days, exam_days, week_start_day, total_periods, teaching_periods, min_resting, max_resting, travel_minutes, is_current, settings_json, is_active) |
| 3 | Verify unique rules ignore current ID on update | `$academicTerm` retrieved from route and used to exclude own ID in custom unique checks for `term_code` and `term_ordinal` |

#### TC-CR14: Request — `prepareForValidation()` Normalizations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `prepareForValidation()` | Merges `is_current` and `is_active` as boolean `true` when checkbox present in request |
| 2 | Verify settings_json encoding | If `settings_json` is an array, it is merged back as `json_encode($this->settings_json)` |

#### TC-CR15: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `AcademicTermPolicy.php` | Policy found |
| 2 | Inspect each method | `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()` all defined; each returns `$user->can('timetable-foundation.academic-term.{action}')` |

#### TC-CR16: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | Route group found |
| 2 | Verify resource route | `Route::resource('academic-term', AcademicTermController::class)` |
| 3 | Verify custom routes | `trash/view` (GET), `{id}/restore` (GET), `{id}/force-delete` (DELETE), `{academic_term}/toggle-status` (POST) |
| 4 | Verify implicit model binding | Route parameter `{academic_term}` triggers ModelNotFoundException for invalid IDs |

#### TC-CR17: View — Blade `@can` Directives on Tab/Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `_list.blade.php` | Status switch and action buttons (View, Edit) rendered for each row |
| 2 | Inspect `create.blade.php` | Create form with all fields; CSRF token present |
| 3 | Inspect `edit.blade.php` | Edit form pre-filled with existing values |
| 4 | Inspect `show.blade.php` | Details table with all field values displayed |

#### TC-CR18: View — `isset()`/Null-Safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `_list.blade.php` | `$term->academicSession->name ?? '--'` pattern used for session name |
| 2 | Inspect date format expressions | `$term->term_start_date?->format('d M Y') ?? '--'` null-safe date formatting |
| 3 | Inspect `show.blade.php` | `$academic_term->academicSession` checked with `@if` before accessing name |

#### TC-CR19: Breadcrumb — Route Registered in Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `create.blade.php` | `x-backend.components.breadcrum` with title "Create Academic Term" |
| 2 | Inspect `edit.blade.php` | Breadcrumb title "Edit Academic Term" |
| 3 | Inspect `show.blade.php` | Breadcrumb title "Academic Term Details" |
| 4 | Inspect `trash.blade.php` | Breadcrumb title "Academic Terms" |

#### TC-CR20: Database — Unique Indexes Match Request Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `uq_AcademicTerm_session_code` in DDL | UNIQUE KEY on `(academic_session_id, term_code)` matches custom validation "Term code already exists for this academic session." |
| 2 | Verify `uq_AcademicTerm_currentFlag` in DDL | UNIQUE KEY on `current_flag` (generated column: 1 when is_current=1 else NULL) enforces at most one current term globally |

---

### 7.1 Positive TC Steps

#### TC-P01: Academic Terms Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Timetable Foundation → Timetable Configuration or directly to `GET /timetable-foundation/timetable-configuration?tab=academic-terms` | Page loads with tabs: "Timetable Config", "Academic Terms" |
| 3 | Click "Academic Terms" tab | Tab pane visible with `id="academic-terms-pane"` |
| 4 | Check session filter dropdown | Dropdown with label "All Sessions" present with list of academic sessions |
| 5 | Check search input | Input field with placeholder "Search by term name..." present |
| 6 | Check status filter dropdown | Dropdown with options "All Status", "Active" (default), "Inactive" |
| 7 | Check reset button | Button with rotate-left icon present |
| 8 | Check table headers | Columns: #, Name, Code, Session, Start, End, Status, Action |
| 9 | Check no records message | If no terms exist, "No records found" displayed |

---

#### TC-P02: Filter Terms By Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A under Session 2026-27, Term B under Session 2025-26 | Two terms in different sessions |
| 2 | Select "2026-27" from session filter dropdown and submit | Page reloads with `?at_session_id={2026-27_id}&tab=academic-terms` |
| 3 | Verify grid shows only Term A | Term B not visible |
| 4 | Select "All Sessions" | Both terms visible |

---

#### TC-P03: Search Terms By Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create terms: "Summer Term", "Winter Term", "Spring Term" | 3 terms exist |
| 2 | Type "Summer" in search box and submit | Page reloads with `?at_search=Summer&tab=academic-terms` |
| 3 | Verify grid shows only "Summer Term" | Other terms not visible |
| 4 | Clear search (reset button) | All 3 terms visible again |

---

#### TC-P04: Filter Terms By Status (Active/Inactive/All)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create one active term and one inactive term | Two terms with different status |
| 2 | Select "Active" from status filter (default) | Only active term shown |
| 3 | Select "Inactive" from status filter | Only inactive term shown |
| 4 | Select "All Status" | Both terms shown |

---

#### TC-P05: Reset Filters Button Clears All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply session filter, search term, and status filter | Filters applied |
| 2 | Click reset button (rotate-left icon) | Navigates to `?tab=academic-terms` without filter params |
| 3 | Verify grid shows all active terms | Filters cleared |

---

#### TC-P06: Create Term With Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Academic Term create form: `GET /timetable-foundation/academic-term/create` | Create form loads with session dropdown, fields |
| 2 | Select academic session "2026-27" | Session selected; session dates auto-populate in right panel |
| 3 | Enter `total_terms_in_academic_session=2` | Field filled |
| 4 | Enter `term_ordinal=1` | Field filled |
| 5 | Enter `term_code="TERM1"` | Field filled |
| 6 | Enter `term_name="Term 1"` | Field filled |
| 7 | Enter `term_start_date="2026-04-01"` and `term_end_date="2026-09-30"` | Dates filled (within session range) |
| 8 | Enter `term_total_teaching_days=5` | Field filled |
| 9 | Enter `term_total_exam_days=2` | Field filled |
| 10 | Select `term_week_start_day=1 (Monday)` | Dropdown selected |
| 11 | Enter `term_total_periods_per_day=8` | Field filled |
| 12 | Enter `term_total_teaching_periods_per_day=6` | Field filled |
| 13 | Enter `term_min_resting_periods_per_day=0` | Field filled |
| 14 | Enter `term_max_resting_periods_per_day=2` | Field filled |
| 15 | Enter `term_travel_minutes_between_classes=5` | Field filled |
| 16 | Leave `is_current` toggle OFF, `is_active` toggle ON (default) | Checkboxes set |
| 17 | Click "Create Term" button | POST to `/timetable-foundation/academic-term` |
| 18 | Verify redirect | Redirected to `GET /timetable-foundation/timetable-configuration` with success flash message |
| 19 | Verify DB record | `SELECT * FROM sch_academic_term WHERE term_code='TERM1'` exists with `is_active=1`, `is_current=0` |

---

#### TC-P07: Create Term With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill all required fields (same as TC-P06) | Fields filled |
| 3 | Toggle `is_current` switch ON | Checkbox set to 1 |
| 4 | Enter valid JSON in settings field: `{"grading_scale":"A-F"}` | JSON filled |
| 5 | Click "Create Term" | Term created with `is_current=1` |
| 6 | Verify no other term in same session is current | All other terms in same session have `is_current=0` |
| 7 | Verify settings_json stored | DB record shows `{"grading_scale":"A-F"}` |

---

#### TC-P08: Create Term With `is_active=false`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill all required fields | Fields filled |
| 3 | Toggle `is_active` switch OFF | Hidden input value = 0 |

| 4 | Click "Create Term" | Term created with `is_active=0` |
| 5 | Verify term not shown in default active-only list | Default filter `at_status=1` hides this term |

---

#### TC-P09: Create Term With Max Resting Periods Auto-Correction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill required fields and set `term_min_resting_periods_per_day=3` | Min resting = 3 |
| 3 | Set `term_max_resting_periods_per_day=1` | Max resting = 1 (less than min) |
| 4 | Click "Create Term" | Controller corrects max to 3 |
| 5 | Verify DB: `term_max_resting_periods_per_day=3` | Auto-corrected to equal min |

---

#### TC-P10: View Term Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a term with all fields | Term exists |
| 2 | Navigate to show page: `GET /timetable-foundation/academic-term/{id}` | Show page loads |
| 3 | Verify fields displayed | Term Name, Term Code (badge), Academic Session (badge), Academic Year range, Term Period range, Term Ordinal ("1 of 2"), Week Start Day (e.g., "Monday"), Teaching Days, Exam Days, Total Periods/Day, Teaching Periods/Day, Resting Periods Range, Travel Minutes, Current Term badge, Status badge, Created At, Updated At |
| 4 | If term has settings_json | Additional Settings section with formatted JSON |

---

#### TC-P11: Edit Term Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a term with known values | Term exists |
| 2 | Navigate to edit form: `GET /timetable-foundation/academic-term/{id}/edit` | Edit form loads |
| 3 | Verify all fields pre-filled with existing values | Session, total terms, ordinal, code, name, dates, week day, teaching/exam days, periods, resting periods, travel, is_current, is_active, settings all match DB |

---

#### TC-P12: Update Term Name And Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit an existing term | Edit form loaded |
| 2 | Change `term_code` from "TERM1" to "TERM1_UPD" and `term_name` from "Term 1" to "Updated Term 1" | Fields updated |
| 3 | Click "Update Term" | PUT to `/timetable-foundation/academic-term/{id}` |
| 4 | Verify redirect | Redirected to config page with success message |
| 5 | Verify DB update | `term_code='TERM1_UPD'`, `term_name='Updated Term 1'` |

---

#### TC-P13: Update Term To Make It Current

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A (is_current=1) and Term B (is_current=0) in same session | Two terms exist |
| 2 | Edit Term B, toggle `is_current` ON | Checkbox set |
| 3 | Click "Update Term" | Update succeeds |
| 4 | Verify Term A now has `is_current=0` | Controller unsets previous current |
| 5 | Verify Term B now has `is_current=1` | Term B is now the current term |

---

#### TC-P14: Update All Term Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit an existing term | Edit form loaded |
| 2 | Change every field to a new valid value | All fields modified |
| 3 | Click "Update Term" | Term updated |
| 4 | Verify all fields updated in DB | Every column matches the new values |

---

#### TC-P15: Toggle Status Active → Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an active term exists | Term with `is_active=1` |
| 2 | Click the status toggle switch for that term | AJAX POST to `/timetable-foundation/academic-term/{id}/toggle-status` with `is_active=0` |
| 3 | Verify JSON response | `{success: true, is_active: false, message: "..."}` |
| 4 | Verify UI updates | Toggle switch reflects inactive state |
| 5 | Verify DB | `is_active=0` in database |

---

#### TC-P16: Toggle Status Inactive → Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an inactive term exists | Term with `is_active=0` |
| 2 | Click the status toggle switch for that term | AJAX POST with `is_active=1` |
| 3 | Verify JSON response | `{success: true, is_active: true, message: "..."}` |
| 4 | Verify UI updates | Toggle switch reflects active state |
| 5 | Verify DB | `is_active=1` in database |

---

#### TC-P17: Soft Delete Term

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an active term exists | Term with `is_active=1` |
| 2 | Click Delete action for that term | DELETE to `/timetable-foundation/academic-term/{id}` |
| 3 | Verify redirect | Redirected to config page with success flash "trashed academic term" |
| 4 | Verify DB: `is_active=0`, `is_current=0`, `deleted_at` set | Term soft-deleted |
| 5 | Verify term hidden from main list | Default filter shows only active terms |

---

#### TC-P18: View Trashed Terms List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete at least one term | Term in trash |
| 2 | Navigate to trash view: `GET /timetable-foundation/academic-term/trash/view` | Trash page loads |
| 3 | Verify columns | Term (name + code), Academic Session, Dates (start → end), Ordinal, Deleted At, Action |
| 4 | Verify trashed term visible | Term appears in list with deleted_at timestamp |
| 5 | Verify action buttons | Restore and Force Delete buttons present |

---

#### TC-P19: Restore Soft-Deleted Term

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trashed terms listed |
| 2 | Click Restore for a trashed term | GET to `/timetable-foundation/academic-term/{id}/restore` |
| 3 | Verify redirect | Redirected back to trash view with success flash |
| 4 | Verify DB: `deleted_at=NULL` | Term restored |
| 5 | Verify `is_active=0`, `is_current=0` still | Restore does not reactivate |

---

#### TC-P20: Force Delete Term

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trashed terms listed |
| 2 | Click Force Delete for a trashed term | DELETE to `/timetable-foundation/academic-term/{id}/force-delete` |
| 3 | Verify redirect | Redirected to trash view with success flash |
| 4 | Verify DB record permanently removed | `SELECT * FROM sch_academic_term WHERE id={id}` returns empty (including withTrashed) |

---

#### TC-P21: Trash View Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 11 terms | 11 terms in trash |
| 2 | Navigate to trash view | Page 1 shows 10 terms |
| 3 | Navigate to page 2 | Remaining 1 term shown |
| 4 | Verify pagination links | Page numbers visible and clickable |

---

#### TC-P22: Full Lifecycle: Create → View → Edit → Toggle Status → Soft Delete → Restore → Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new term (TC-P06) | Term created |
| 2 | View term details (TC-P10) | Details shown |
| 3 | Edit term name and code (TC-P12) | Updated |
| 4 | Toggle status inactive (TC-P15) | Status changed |
| 5 | Soft delete (TC-P17) | Term trashed |
| 6 | View in trash (TC-P18) | Term in trash list |
| 7 | Restore (TC-P19) | Term restored, but inactive |
| 8 | Force delete (TC-P20) | Term permanently removed |

---

#### TC-P23: Empty State — No Terms Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no academic terms exist | No records |
| 2 | Load Timetable Configuration → Academic Terms tab | Table shows "No records found" across all columns |

---

#### TC-P24: Empty State — No Trashed Terms

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no trashed terms exist | No trashed records |
| 2 | Navigate to trash view: `GET /timetable-foundation/academic-term/trash/view` | Page shows "No trashed academic terms found" |

---

### 7.2 Negative TC Steps

#### TC-N01: Required — Missing `academic_session_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Leave `academic_session_id` unselected (empty) | No session selected |
| 3 | Fill all other required fields | Other fields filled |
| 4 | Click "Create Term" | Form submits |
| 5 | Verify validation error | "The academic session field is required." |

---

#### TC-N02: Required — Missing `term_name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Leave `term_name` empty | Name field blank |
| 3 | Fill all other required fields | Other fields filled |
| 4 | Click "Create Term" | Validation error: "The term name field is required." |

---

#### TC-N03: Required — Missing `term_code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Leave `term_code` empty | Code field blank |
| 3 | Fill all other required fields | Other fields filled |
| 4 | Click "Create Term" | Validation error: "The term code field is required." |

---

#### TC-N04: Required — Missing `term_start_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Leave `term_start_date` empty | Start date blank |
| 3 | Fill all other required fields | Other fields filled |
| 4 | Click "Create Term" | Validation error: "The term start date field is required." |

---

#### TC-N05: Required — Missing `term_end_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Leave `term_end_date` empty | End date blank |
| 3 | Fill all other required fields | Other fields filled |
| 4 | Click "Create Term" | Validation error: "The term end date field is required." |

---

#### TC-N06: Invalid — `term_end_date` Before `term_start_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `term_start_date=2026-09-01`, `term_end_date=2026-08-01` | End date before start date |
| 3 | Click "Create Term" | Validation error: "The term end date must be a date after or equal to term start date." |

---

#### TC-N07: Invalid — `term_start_date` Before `academic_year_start_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form with session 2026-27 (Apr 2026 – Mar 2027) | Session dates loaded |
| 2 | Set `term_start_date=2026-01-15` (before Apr 2026) | Start date outside session |
| 3 | Click "Create Term" | Validation error: "Term start date cannot be before academic year start date." |

---

#### TC-N08: Invalid — `term_end_date` After `academic_year_end_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form with session 2026-27 (Apr 2026 – Mar 2027) | Session dates loaded |
| 2 | Set `term_end_date=2027-05-01` (after Mar 2027) | End date outside session |
| 3 | Click "Create Term" | Validation error: "Term end date cannot be after academic year end date." |

---

#### TC-N09: Invalid — `academic_year_end_date` Before `academic_year_start_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `academic_year_start_date=2026-09-01`, `academic_year_end_date=2026-04-01` | End date before start (these fields are auto-populated from session; manually override via browser dev tools) |
| 3 | Click "Create Term" | Validation error: "The academic year end date must be a date after or equal to academic year start date." |

---

#### TC-N10: Invalid — Total Terms < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `total_terms_in_academic_session=0` | Below minimum |
| 3 | Click "Create Term" | Validation error: `total_terms_in_academic_session` must be at least 1 |

---

#### TC-N11: Invalid — Total Terms > 12

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `total_terms_in_academic_session=13` | Above maximum |
| 3 | Click "Create Term" | Validation error: `total_terms_in_academic_session` must not exceed 12 |

---

#### TC-N12: Invalid — Term Ordinal Duplicate Within Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `term_ordinal=1` in Session 2026-27 | Term exists |
| 2 | Open create form for another term in same session | Form loads |
| 3 | Set `term_ordinal=1` (duplicate) | Same ordinal |
| 4 | Click "Create Term" | Validation error: "Term ordinal already exists for this academic session." |

---

#### TC-N13: Invalid — Term Code Duplicate Within Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `term_code="TERM1"` in Session 2026-27 | Term exists |
| 2 | Open create form for another term in same session | Form loads |
| 3 | Set `term_code="TERM1"` (duplicate) | Same code |
| 4 | Click "Create Term" | Validation error: "Term code already exists for this academic session." |

---

#### TC-N14: Invalid — Teaching Periods > Total Periods Per Day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `term_total_periods_per_day=8`, `term_total_teaching_periods_per_day=10` | Teaching exceeds total |
| 3 | Click "Create Term" | Validation error: "Teaching periods cannot exceed total periods per day." |

---

#### TC-N15: Invalid — Max Resting Periods < Min Resting Periods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `term_min_resting_periods_per_day=3`, `term_max_resting_periods_per_day=1` | Max < Min |
| 3 | Click "Create Term" | Validation error on `gte:term_min_resting_periods_per_day` rule |

---

#### TC-N16: Invalid — Non-Existent `academic_session_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set `academic_session_id` to a non-existent ID (999) via browser dev tools | Invalid FK |
| 3 | Click "Create Term" | Validation error: "The selected academic session is invalid." |

---

#### TC-N17: Invalid — `term_code` Exceeds 20 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter `term_code="ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"` (31 chars) | Exceeds max:20 |
| 3 | Click "Create Term" | Validation error on `term_code` max:20 |

---

#### TC-N18: Invalid — `term_name` Exceeds 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter `term_name` string of 101+ characters | Exceeds max:100 |
| 3 | Click "Create Term" | Validation error on `term_name` max:100 |

---

#### TC-N19: Invalid — `settings_json` Is Not Valid JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter `settings_json="not-valid-json"` | Invalid JSON string |
| 3 | Click "Create Term" | Validation error: "The settings JSON must be a valid JSON string." |

---

#### TC-N20: Permission 403 — No `timetable-foundation.academic-term.viewAny`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `timetable-foundation.academic-term.viewAny` | User authenticated |
| 2 | Navigate to any academic-term route | 403 Forbidden |

---

#### TC-N21: Permission 403 — No `timetable-foundation.academic-term.create`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `timetable-foundation.academic-term.create` | User authenticated |
| 2 | Navigate to `GET /timetable-foundation/academic-term/create` | 403 Forbidden |
| 3 | POST to `/timetable-foundation/academic-term` with valid data | 403 Forbidden |

---

#### TC-N22: Permission 403 — No `timetable-foundation.academic-term.update`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `timetable-foundation.academic-term.update` | User authenticated |
| 2 | Navigate to edit form | 403 Forbidden |
| 3 | PUT to update endpoint | 403 Forbidden |
| 4 | POST to toggle-status | 403 Forbidden |

---

#### TC-N23: Permission 403 — No `timetable-foundation.academic-term.delete`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `timetable-foundation.academic-term.delete` | User authenticated |
| 2 | DELETE to `/timetable-foundation/academic-term/{id}` | 403 Forbidden |

---

#### TC-N24: Permission 403 — No `timetable-foundation.academic-term.restore`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `timetable-foundation.academic-term.restore` | User authenticated |
| 2 | Navigate to trash view | 403 Forbidden |
| 3 | GET to restore endpoint | 403 Forbidden |

---

#### TC-N25: Permission 403 — No `timetable-foundation.academic-term.forceDelete`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `timetable-foundation.academic-term.forceDelete` | User authenticated |
| 2 | DELETE to force-delete endpoint | 403 Forbidden |

---

#### TC-N26: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (unauthenticated) | Guest session |
| 2 | Try accessing any academic-term route (index, create, show, edit, etc.) | Redirected to `/login` |

---

#### TC-N27 to TC-N33: Non-Existent IDs (404)

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N27 | `GET /timetable-foundation/academic-term/99999` | 404 Not Found |
| TC-N28 | `GET /timetable-foundation/academic-term/99999/edit` | 404 Not Found |
| TC-N29 | `PUT /timetable-foundation/academic-term/99999` with valid data | 404 Not Found |
| TC-N30 | `DELETE /timetable-foundation/academic-term/99999` | 404 Not Found |
| TC-N31 | `GET /timetable-foundation/academic-term/99999/restore` | 404 Not Found |
| TC-N32 | `DELETE /timetable-foundation/academic-term/99999/force-delete` | 404 Not Found |
| TC-N33 | `POST /timetable-foundation/academic-term/99999/toggle-status` | 404 Not Found |

---

#### TC-N34: XSS Injection In `term_name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create term with `term_name=<script>alert('xss')</script>` | Term created with literal script tag |
| 2 | Navigate to Academic Terms tab list | Term name rendered as escaped text `<script>alert('xss')</script>` — no script execution |
| 3 | View term details page | Escaped output, no XSS |

---

### 7.3 Dependency TC Steps

#### TC-D01: Create Current Term → All Other Terms In Same Session Set To Non-Current

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `is_current=1` in Session 2026-27 | Term A created as current |
| 2 | Create Term B with `is_current=1` in Session 2026-27 | Controller unsets Term A's `is_current` before saving Term B |
| 3 | Verify Term A: `is_current=0`, Term B: `is_current=1` | Only Term B is current |

---

#### TC-D02: Update Term To Current → Previous Current Term Becomes Non-Current

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A (`is_current=1`) and Term B (`is_current=0`) in same session | Two terms |
| 2 | Edit Term B, set `is_current=1` | Update submits |
| 3 | Verify Term A: `is_current=0` (excluded by `id != $academic_term->id`) | Only Term B is current |

---

#### TC-D03: DB Enforced — Only One Current Term Via `uq_AcademicTerm_currentFlag`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Execute direct SQL: `UPDATE sch_academic_term SET is_current=1 WHERE id={id}` where another record already has `is_current=1` | Integrity constraint violation on `uq_AcademicTerm_currentFlag` because `current_flag` generated column creates duplicate non-NULL value |

---

#### TC-D04: Controller Auto-Corrects Max Resting Periods On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create term with `min_resting=3`, `max_resting=1` | Controller sets max = 3 before create |
| 2 | Verify DB: `term_max_resting_periods_per_day=3` | Auto-corrected |

---

#### TC-D05: Controller Auto-Corrects Max Resting Periods On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit term; set `min_resting=4`, `max_resting=2` | Controller sets max = 4 before update |
| 2 | Verify DB: `term_max_resting_periods_per_day=4` | Auto-corrected |

---

#### TC-D06: Term Dates Constrained Within Session Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create term with `term_start_date` before `academic_year_start_date` | Validation error |
| 2 | Create term with `term_end_date` after `academic_year_end_date` | Validation error |
| 3 | Create term with both dates within session range | Success |

---

#### TC-D07: Term Ordinal Unique Per Session (Controller)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `term_ordinal=1`, session 2026-27 | Success |
| 2 | Create Term B with `term_ordinal=1`, same session | Validation error: "Term ordinal already exists for this academic session." |

---

#### TC-D08: Term Ordinal Unique Per Session (Update Ignores Own ID)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `term_ordinal=1` | Term A exists |
| 2 | Edit Term A, keep `term_ordinal=1`, change other fields | Update succeeds (own ordinal excluded from uniqueness check) |

---

#### TC-D09: Term Code Unique Per Session (Controller)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `term_code="TERM1"`, session 2026-27 | Success |
| 2 | Create Term B with `term_code="TERM1"`, same session | Validation error: "Term code already exists for this academic session." |

---

#### TC-D10: Term Code Unique Per Session — Same Code Allowed In Different Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Term A with `term_code="TERM1"` in Session 2026-27 | Success |
| 2 | Create Term B with `term_code="TERM1"` in Session 2025-26 | Success (different session) |

---

#### TC-D11: Delete Academic Session Referenced By Term (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an academic session that has academic terms | Terms exist for session |
| 2 | Attempt to delete that session from School Setup module | DB FK constraint violation (RESTRICT) — deletion blocked |

---

#### TC-D12: Soft Delete Sets `is_active=false` and `is_current=false`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create term with `is_active=1`, `is_current=1` | Term active and current |
| 2 | Delete term | `destroy()` sets both to false |
| 3 | Query `onlyTrashed()`: `is_active=0`, `is_current=0` | Both flags false |

---

#### TC-D13: Restore Does Not Restore `is_active` Or `is_current`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a soft-deleted term | `restore()` only nullifies `deleted_at` |
| 2 | Verify `is_active=0`, `is_current=0` | Flags remain false after restore |

---

#### TC-D14: Activity Logged After CRUD Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a term | Activity log entry with event 'Stored' |
| 2 | Update the term | Activity log entry with event 'Updated' and changes array |
| 3 | Toggle status | Activity log entry with event 'Toggled' |
| 4 | Delete the term | Activity log entry with event 'Trashed' |
| 5 | Restore the term | Activity log entry with event 'Restored' |
| 6 | Force delete the term | Activity log entry with event 'Deleted' |

---

#### TC-D15: AcademicTerm Model `$casts` Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch a term from DB | `is_active` returns boolean (true/false), `is_current` returns boolean |
| 2 | Check date fields | `term_start_date`, `term_end_date`, `academic_year_start_date`, `academic_year_end_date` return Carbon instances |
| 3 | Check settings_json | Returns array (decoded from JSON) |

---

#### TC-D16: AcademicTerm Model `$fillable` Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | List `$fillable` columns from model | 18 columns listed |
| 2 | Verify `current_flag` NOT in fillable | Generated column — must not be mass-assigned |

---

#### TC-D17: SoftDeletes Trait Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a term | `deleted_at` set |
| 2 | Query normally | Term not in results |
| 3 | Query with `withTrashed()` | Term in results |
| 4 | Query with `onlyTrashed()` | Term in results |
| 5 | Restore | `deleted_at` nullified |

---

#### TC-D18: belongsTo AcademicSession Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch a term with `->load('academicSession')` | `$term->academicSession` returns `OrganizationAcademicSession` model |
| 2 | Eager load via `AcademicTerm::with('academicSession')->get()` | Relationship loaded in 1+1 queries |

---

#### TC-D19: Controller `findOrFail` — Valid and Invalid IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access show/edit/update/destroy with valid ID | Model loaded successfully |
| 2 | Access show/edit/update/destroy with invalid ID (99999) | `ModelNotFoundException` → HTTP 404 |

---

#### TC-D20: Controller `Gate::authorize()` On All Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove permissions from test user | User lacks permissions |
| 2 | Access any academic-term endpoint | 403 Forbidden |

---

#### TC-D21: `prepareForValidation()` Bool Normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without `is_current` checkbox | `is_current` merged as `false` |
| 2 | Submit create form with `is_current` checkbox checked | `is_current` merged as `true` |
| 3 | Submit `settings_json` as array | Encoded to JSON string before validation |

---

#### TC-D22: AcademicTermPolicy Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect policy class | 7 methods defined: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Verify each returns correct permission check | Each returns `$user->can('timetable-foundation.academic-term.{action}')` |

---

#### TC-D23: Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list | grep academic-term` | All 11 routes listed: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus |
| 2 | Verify each maps to correct controller method | Route-controller mapping correct |

---

#### TC-D24: `toggleStatus()` JSON Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send valid AJAX POST to toggle-status | Response: `{success: true, is_active: true/false, message: "..."}` |
| 2 | Send invalid `is_active` value (non-boolean) | Validation error: "The is active field must be true or false." |

---

#### TC-D25: `store()` DB Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate DB failure during store (e.g., disconnect DB mid-request) | Transaction rolled back; no partial data in DB |
| 2 | Verify no record created | `SELECT` returns no new record |

---

#### TC-D26: `update()` DB Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate DB failure during update | Transaction rolled back; original data preserved |

---

#### TC-D27: Index Redirects To Timetable Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/academic-term` | 302 redirect to `GET /timetable-foundation/timetable-configuration` |

---

#### TC-D28: `scopeActive()` and `scopeCurrent()` Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active term and inactive term | Two terms |
| 2 | `AcademicTerm::active()->get()` | Only active term returned |
| 3 | Create current and non-current terms | Two terms |
| 4 | `AcademicTerm::current()->get()` | Only current term returned |
