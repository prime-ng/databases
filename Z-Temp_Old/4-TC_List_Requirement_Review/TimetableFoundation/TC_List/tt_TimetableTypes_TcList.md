# tt_TimetableTypes_TcList

## Module: TimetableFoundation → Timetable Masters → Timetable Types & Class Assignments

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Masters |
| Feature | Timetable Types & Class Assignments (two tabs: `timetable-types` and `class-timetable`) |
| URL(s) | `GET` `/timetable-foundation/timetable-masters` (multi-tab page via `timetableMasters()`) — loads both tabs; `GET` `/timetable-foundation/timetable-type` (index — redirects to masters), `GET` `/timetable-foundation/timetable-type/create` (create form), `POST` `/timetable-foundation/timetable-type` (store), `GET` `/timetable-foundation/timetable-type/{timetableType}` (show), `GET` `/timetable-foundation/timetable-type/{timetableType}/edit` (edit form), `PUT` `/timetable-foundation/timetable-type/{timetableType}` (update), `DELETE` `/timetable-foundation/timetable-type/{timetableType}` (destroy), `GET` `/timetable-foundation/timetable-type/trash/view` (trashed list), `GET` `/timetable-foundation/timetable-type/{id}/restore` (restore), `DELETE` `/timetable-foundation/timetable-type/{id}/force-delete` (forceDelete), `POST` `/timetable-foundation/timetable-type/{timetableType}/toggle-status` (toggleStatus); `GET` `/timetable-foundation/class-timetable` (index — redirects), `GET` `/timetable-foundation/class-timetable/create` (create form), `POST` `/timetable-foundation/class-timetable` (store), `GET` `/timetable-foundation/class-timetable/{classTimetableType}` (show), `GET` `/timetable-foundation/class-timetable/{classTimetableType}/edit` (edit), `PUT` `/timetable-foundation/class-timetable/{classTimetableType}` (update), `DELETE` `/timetable-foundation/class-timetable/{classTimetableType}` (destroy), `GET` `/timetable-foundation/class-timetable/trash/view` (trashed), `GET` `/timetable-foundation/class-timetable/{id}/restore` (restore), `DELETE` `/timetable-foundation/class-timetable/{id}/force-delete` (forceDelete), `POST` `/timetable-foundation/class-timetable/{classTimetableType}/toggle-status` (toggleStatus), `GET` `/timetable-foundation/class-timetable/ajax/sections/{classId}` (getSectionsByClass AJAX) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\TimetableTypeController` (542 lines) + `Modules\TimetableFoundation\Http\Controllers\ClassTimetableTypeController` (523 lines); list loaded by `TimetableFoundationController@timetableMasters()` |
| Model(s) | `Modules\TimetableFoundation\Models\TimetableType` (table: `tt_timetable_types`); `Modules\TimetableFoundation\Models\ClassTimetableType` (table: `tt_class_timetable_types_jnt`) |
| Validation (Create) | Inline in `TimetableTypeController@store()` — no separate FormRequest |
| Validation (Update) | Inline in `TimetableTypeController@update()` — no separate FormRequest |
| Policy | `Modules\TimetableFoundation\Policies\TimetableTypePolicy` (6 gates: viewAny, view, create, update, delete, restore, forceDelete); `Modules\TimetableFoundation\Policies\ClassTimetableTypePolicy` (6 gates) |
| Permissions (TT) | `timetable-foundation.timetable-type.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Permissions (CTT) | `timetable-foundation.class-timetable.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | Timetable Types list: no pagination (`->get()`). Class Timetable list: no pagination (loaded as nested relationship of Timetable Types). Trash views: 10 records per page via `->paginate(10)`. |
| Soft Deletes | Yes — both models; `TimetableType` imports `SoftDeletes` trait; `ClassTimetableType` table has `deleted_at` (controller uses `onlyTrashed()`/`restore()`/`forceDelete()`) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` (both controllers) |

---

## 2. Pre-conditions

- Required permissions: `timetable-foundation.*` viewAny + all feature-specific permissions for both `timetable-type.*` and `class-timetable.*` as listed above
- Required seed data: At least one active `SchoolShift`, one active `AcademicTerm`, one active `PeriodSet`, at least 2 active `SchoolClass` records each with at least 2 active `Section` records
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For single-default tests: At least 2 timetable types
- For AJAX section tests: At least 1 class with multiple sections, and existing `ClassTimetableType` records for that class
- For inline assignment tests: At least 1 active academic term and 1 active period set
- For pagination overflow in trash: Create 11+ soft-deleted records

---

## 3. Default Data Load

When the Timetable Masters page loads via `TimetableFoundationController@timetableMasters()` (`GET /timetable-foundation/timetable-masters`), all tab data is fetched and passed to the shared view.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Shifts (filter dropdown) | `timetableMasters()` | `SchoolShift::where('is_active', true)->orderBy('name')->get(['id', 'name'])` | is_active=1 | None |
| Timetable Types Grid | `timetableMasters()` | `TimetableType::with('shift', 'classTimetableTypes.academicTerm', 'classTimetableTypes.periodSet.periods.periodType', 'classTimetableTypes.class.classSections.section', 'classTimetableTypes.section')` | `tt_search` (name/code LIKE), `tt_shift_id` (=), `tt_status` (is_active) | None (all records, ordered by name) |
| Class Timetable Types Grid | `timetableMasters()` | Loaded as nested relationship of `TimetableType` query above — each TT row shows its class assignments inline | Same as TT filters | None |

> **Data Source:** The `tt_timetable_types` and `tt_class_timetable_types_jnt` tables are wholly owned by TimetableFoundation. The parent entities (shifts, classes, sections, academic terms, period sets) originate from other modules.

---

## 4. Test Data Strategy

- **Unique identifier:** Use `now()->format('YmdHis')` as a timestamp suffix for `code` and `name` to avoid unique constraint violations (e.g., `STANDARD_20260718123456`)
- **Date ranges:** Use consistent test dates, e.g., effective range `2026-04-01` to `2027-03-31`. School start/end times: `07:30` – `13:30`.
- **Pre-test cleanup:** Delete created timetable types and class timetable types by code prefix before and after tests to avoid unique constraint (`uq_tttype_code`) violations.
- **Pagination overflow for trash:** Create 11+ soft-deleted timetable types and 11+ soft-deleted class timetable types to verify `paginate(10)` limit.
- **Cross-module data:** Ensure at least one active `SchoolShift`, `AcademicTerm`, `PeriodSet`, `SchoolClass` (with sections) exist in the database before running tests.
- **Overlap gap awareness:** The known gaps (shift time overlap validation, period set overlap validation) are not implemented — tests document the current behavior.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_timetable_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | code | VARCHAR(30) | NOT NULL, UNIQUE (`uq_tttype_code`) |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-05 | shift_id | TINYINT UNSIGNED | DEFAULT NULL, FK → `tt_shifts(id)` |
| BC-DB-06 | effective_from_date | DATE | DEFAULT NULL |
| BC-DB-07 | effective_to_date | DATE | DEFAULT NULL |
| BC-DB-08 | school_start_time | TIME | DEFAULT NULL |
| BC-DB-09 | school_end_time | TIME | DEFAULT NULL |
| BC-DB-10 | has_exam | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-11 | has_teaching | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-12 | ordinal | SMALLINT UNSIGNED | DEFAULT 1 |
| BC-DB-13 | is_default | TINYINT(1) | DEFAULT 0 |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-15 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-16 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-17 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-18 | **UNIQUE KEY** `uq_tttype_code` | — | ON (`code`) |
| BC-DB-19 | **INDEX** `idx_tttype_shift` | — | ON (`shift_id`) |
| BC-DB-20 | **CHECK** `chk_tttype_time` | — | `(school_end_time > school_start_time) AND (effective_from_date <= effective_to_date)` |

### 5.2 Database Schema — `tt_class_timetable_types_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-21 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-22 | academic_term_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_academic_term(id)` |
| BC-DB-23 | timetable_type_id | INT UNSIGNED | NOT NULL, FK → `tt_timetable_types(id)` |
| BC-DB-24 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes(id)` |
| BC-DB-25 | section_id | INT UNSIGNED | NULL (NULL when `applies_to_all_sections=1`), FK → `sch_sections(id)` |
| BC-DB-26 | period_set_id | INT UNSIGNED | NOT NULL, FK → `tt_period_sets(id)` |
| BC-DB-27 | applies_to_all_sections | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-28 | has_teaching | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-29 | has_exam | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-30 | weekly_exam_period_count | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-31 | weekly_teaching_period_count | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-32 | weekly_free_period_count | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-33 | effective_from | DATE | DEFAULT NULL |
| BC-DB-34 | effective_to | DATE | DEFAULT NULL |
| BC-DB-35 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-36 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-37 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-38 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-39 | **INDEX** `idx_cttj_term` | — | ON (`academic_term_id`, `timetable_type_id`, `class_id`, `section_id`) |
| BC-DB-40 | **CHECK** `chk_valid_effective_range` | — | `(effective_from < effective_to)` |
| BC-DB-41 | **CHECK** `chk_cttj_apply_to_all_section` | — | `((section_id IS NULL AND applies_to_all_sections = 1) OR (section_id IS NOT NULL AND applies_to_all_sections = 0))` |



| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:30, regex:/^[A-Z0-9_]+$/i, unique:tt_timetable_types,code | "The code has already been taken." / format invalid |
| BC-VAL-02 | name | required, string, max:100 | "The name field is required." |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | shift_id | nullable, exists:tt_shifts,id | "The selected shift is invalid." |
| BC-VAL-05 | effective_from_date | nullable, date | — |
| BC-VAL-06 | effective_to_date | nullable, date, after_or_equal:effective_from_date | "The effective to date must be a date after or equal to effective from date." |
| BC-VAL-07 | school_start_time | nullable, date_format:H:i | — |
| BC-VAL-08 | school_end_time | nullable, date_format:H:i | — |
| BC-VAL-09 | ordinal | required, integer, min:1 | "The ordinal must be at least 1." |
| BC-VAL-10 | has_teaching | sometimes, boolean | — |
| BC-VAL-11 | has_exam | sometimes, boolean | — |
| BC-VAL-12 | is_default | sometimes, boolean | — |
| BC-VAL-13 | is_active | sometimes (boolean via `$request->boolean()`) | — |
| BC-VAL-14 | classes | nullable, array | — |
| BC-VAL-15 | classes.*.class_id | required_with:classes, integer, exists:sch_classes,id | — |
| BC-VAL-16 | classes.*.section_ids | nullable, array | — |
| BC-VAL-17 | classes.*.section_ids.* | integer, exists:sch_sections,id | — |
| BC-VAL-18 | classes.*.period_set_id | nullable, integer, exists:tt_period_sets,id | — |
| BC-VAL-19 | classes.*.academic_term_id | nullable, integer | — |
| BC-VAL-20 | classes.*.has_teaching | nullable, boolean | — |
| BC-VAL-21 | classes.*.has_exam | nullable, boolean | — |
| BC-VAL-22 | classes.*.weekly_teaching_period_count | nullable, integer, min:0, max:99 | — |
| BC-VAL-23 | classes.*.weekly_exam_period_count | nullable, integer, min:0, max:99 | — |
| BC-VAL-24 | classes.*.weekly_free_period_count | nullable, integer, min:0, max:99 | — |
| BC-VAL-25 | classes.*.effective_from | nullable, date | — |
| BC-VAL-26 | classes.*.effective_to | nullable, date, after_or_equal:classes.*.effective_from | — |
| BC-VAL-27 | classes.*.is_active | nullable, boolean | — |
| BC-VAL-28 | **Controller check (store)** | `school_start_time >= school_end_time` | "School end time must be after start time." |

### 5.3 Validation Rules — `TimetableTypeController@update` (Update)

All Create rules apply with these differences:

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | code | unique:tt_timetable_types,code + ignore current ID via `->ignore($timetableType->id)` | "The code has already been taken." |
| BC-VAL-U02 | school_end_time | nullable, date_format:H:i, **after:school_start_time** | "The school end time must be a date after school start time." |
| BC-VAL-U03 | has_teaching | **required**, boolean | — |
| BC-VAL-U04 | has_exam | **required**, boolean | — |
| BC-VAL-U05 | is_default | **required**, boolean | — |
| BC-VAL-U06 | is_active | **required** (no `sometimes`) | — |

### 5.4 Validation Rules — `ClassTimetableTypeController@store` (Bulk Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-C01 | academic_term_id | required, integer, exists:sch_academic_term,id | — |
| BC-VAL-C02 | timetable_type_id | required, integer, exists:tt_timetable_types,id | — |
| BC-VAL-C03 | class_ids | required, array, min:1 | — |
| BC-VAL-C04 | class_ids.* | integer, exists:sch_classes,id | — |
| BC-VAL-C05 | all_sections | nullable, array | — |
| BC-VAL-C06 | all_sections.* | integer, exists:sch_classes,id | — |
| BC-VAL-C07 | section_ids | nullable, array | — |
| BC-VAL-C08 | section_ids.* | nullable, array | — |
| BC-VAL-C09 | section_ids.*.* | integer, exists:sch_sections,id | — |
| BC-VAL-C10 | period_set_id | nullable, integer, exists:tt_period_sets,id | — |
| BC-VAL-C11 | has_teaching | nullable, boolean | — |
| BC-VAL-C12 | has_exam | nullable, boolean | — |
| BC-VAL-C13 | weekly_exam_period_count | nullable, integer, min:0 | — |
| BC-VAL-C14 | weekly_teaching_period_count | nullable, integer, min:0 | — |
| BC-VAL-C15 | weekly_free_period_count | nullable, integer, min:0 | — |
| BC-VAL-C16 | effective_from | nullable, date | — |
| BC-VAL-C17 | effective_to | nullable, date, after_or_equal:effective_from | — |
| BC-VAL-C18 | is_active | nullable, boolean | — |
| BC-VAL-C19 | **Controller check** | Each class needs sections resolved | "Each selected class needs 'All Sections' checked or at least one section selected." |

### 5.5 Validation Rules — `ClassTimetableTypeController@update` (Single Update)

| BC ID | Field | Rule(s) |
|-------|-------|---------|
| BC-VAL-U01 | academic_term_id | required, integer, exists:sch_academic_term,id |
| BC-VAL-U02 | timetable_type_id | required, integer, exists:tt_timetable_types,id |
| BC-VAL-U03 | class_id | required, integer, exists:sch_classes,id |
| BC-VAL-U04 | section_id | nullable, integer, exists:sch_sections,id |
| BC-VAL-U05 | period_set_id | nullable, integer, exists:tt_period_sets,id |
| BC-VAL-U06 | applies_to_all_sections | nullable, boolean |
| BC-VAL-U07 | has_teaching | nullable, boolean |
| BC-VAL-U08 | has_exam | nullable, boolean |
| BC-VAL-U09 | weekly_exam_period_count | nullable, integer, min:0 |
| BC-VAL-U10 | weekly_teaching_period_count | nullable, integer, min:0 |
| BC-VAL-U11 | weekly_free_period_count | nullable, integer, min:0 |
| BC-VAL-U12 | effective_from | nullable, date |
| BC-VAL-U13 | effective_to | nullable, date, after_or_equal:effective_from |
| BC-VAL-U14 | is_active | nullable, boolean |

### 5.6 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | `timetable-foundation.timetable-type.viewAny` | `index()` | Without → 403 Forbidden |
| BC-AUTH-02 | `timetable-foundation.timetable-type.view` | `show()` | Without → 403 Forbidden |
| BC-AUTH-03 | `timetable-foundation.timetable-type.create` | `create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-04 | `timetable-foundation.timetable-type.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-05 | `timetable-foundation.timetable-type.delete` | `destroy()`, `forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-06 | `timetable-foundation.timetable-type.restore` | `trashedTimetableType()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-07 | `timetable-foundation.class-timetable.viewAny` | `index()`, `getSectionsByClass()` | Without → 403 Forbidden |
| BC-AUTH-08 | `timetable-foundation.class-timetable.view` | `show()` | Without → 403 Forbidden |
| BC-AUTH-09 | `timetable-foundation.class-timetable.create` | `create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-10 | `timetable-foundation.class-timetable.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-11 | `timetable-foundation.class-timetable.delete` | `destroy()` | Without → 403 Forbidden |
| BC-AUTH-12 | `timetable-foundation.class-timetable.restore` | `trashedClassTimetable()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-13 | `timetable-foundation.class-timetable.forceDelete` | `forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-14 | Guest access | All routes | Redirect to `/login` |

### 5.7 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Timetable Types tab loads via `timetableMasters()` at `GET /timetable-foundation/timetable-masters?tab=timetable-types` | Timetable Types list rendered with search bar (`tt_search`), shift filter (`tt_shift_id`), status filter (`tt_status`), table with columns (#, Code, Name, Shift, Start Time, End Time, Ordinal, Default Badge, Status Toggle, Actions). Class assignments shown inline within each TT row. |
| BC-BIZ-02 | Search by `tt_search` (name + code) | Timetable Types filtered to show only records whose `name` or `code` contains the search string |
| BC-BIZ-03 | Filter by `tt_shift_id` | Timetable Types filtered to show only those assigned to the selected shift |
| BC-BIZ-04 | Filter by `tt_status` (is_active) | Timetable Types filtered to show active (1) or inactive (0); no default means all |
| BC-BIZ-05 | Search by `ctt_search` on class-timetable tab | Class Timetable Types filtered by timetable type name/code or class name (search across relationships) |
| BC-BIZ-06 | Filter by `ctt_status` on class-timetable tab | Class Timetable Types filtered by is_active |
| BC-BIZ-07 | Code uppercased on save | `store()` applies `strtoupper($validated['code'])` before creating record |
| BC-BIZ-08 | Single default timetable type | When `is_default=true`, controller sets all other records to `is_default=false`. On create: `TimetableType::where('is_default', true)->update(['is_default' => false])`. On update: excludes current ID. |
| BC-BIZ-09 | School start/end time check on create | Controller manually checks if `school_start_time >= school_end_time` and returns back with error |
| BC-BIZ-10 | School end time validation on update | Validation rule `after:school_start_time` ensures `school_end_time > school_start_time` |
| BC-BIZ-11 | Effective date ordering | `effective_to_date` must be `after_or_equal:effective_from_date` |
| BC-BIZ-12 | Ordinal global scope | Model global scope `ordered` adds `orderBy('ordinal')` to every query (can be removed with `withoutGlobalScope()`) |
| BC-BIZ-13 | Inline class assignment on TT create | `store()` accepts optional `classes` array; creates `ClassTimetableType` records (one per section, or one with `section_id=null` for "All Sections") |
| BC-BIZ-14 | Inline class assignment defaults from parent | When creating inline CTT records, `has_teaching`, `has_exam` inherit from TT if not explicitly set on the class row |
| BC-BIZ-15 | Delete-all-then-recreate on TT update | `update()` deletes all existing `ClassTimetableType` records for this TT, then recreates from submitted `classes` array |
| BC-BIZ-16 | Soft delete deactivates before delete | `destroy()` sets `is_active=false` before calling `delete()` (both controllers) |
| BC-BIZ-17 | Restore reactivates | `restore()` sets `is_active=true` after restoring (both controllers) |
| BC-BIZ-18 | Bulk `updateOrCreate` on CTT store | `ClassTimetableTypeController@store` uses `updateOrCreate()` with composite unique key to prevent duplicates |
| BC-BIZ-19 | Cross-validation: class must have sections | CTT bulk create requires each class to have "All Sections" checked or at least one section selected |
| BC-BIZ-20 | AJAX section exclusion | `getSectionsByClass()` excludes sections already assigned for the selected `(timetable_type_id, class_id)`. Returns empty `[]` if an "All Sections" row exists |
| BC-BIZ-21 | Create form class pre-filtering | `ClassTimetableTypeController@create()` excludes classes where all sections are already assigned (either via "All Sections" or individual rows) |
| BC-BIZ-22 | ToggleStatus returns JSON | `toggleStatus()` validates `is_active`, saves, returns `{success, is_active, message}` with 422 on failure |
| BC-BIZ-23 | Force delete may fail with children | `forceDelete()` does not cascade to child records; FK constraint `fk_cttj_mode` (RESTRICT) may prevent deletion |
| BC-BIZ-24 | Section mutual exclusion (CHECK) | DB enforces: `((section_id IS NULL AND applies_to_all_sections = 1) OR (section_id IS NOT NULL AND applies_to_all_sections = 0))` |
| BC-BIZ-25 | Overlap check — same shift (NOT IMPLEMENTED) | Two active TT records for same shift with overlapping school start/end times are NOT prevented. Known gap. |
| BC-BIZ-26 | Overlap check — period set for same class-section (NOT IMPLEMENTED) | Two CTT records for same `(class_id, section_id)` with overlapping effective ranges are NOT prevented. Known gap. |

### 5.8 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | shift_id (tt_timetable_types) | `tt_shifts(id)` | Not specified (default RESTRICT) |
| BC-REF-02 | timetable_type_id (tt_class_timetable_types_jnt) | `tt_timetable_types(id)` | Not specified (default RESTRICT) |
| BC-REF-03 | academic_term_id (tt_class_timetable_types_jnt) | `sch_academic_term(id)` | Not specified (default RESTRICT) |
| BC-REF-04 | class_id (tt_class_timetable_types_jnt) | `sch_classes(id)` | Not specified (default RESTRICT) |
| BC-REF-05 | section_id (tt_class_timetable_types_jnt) | `sch_sections(id)` | Not specified (default RESTRICT) |
| BC-REF-06 | period_set_id (tt_class_timetable_types_jnt) | `tt_period_sets(id)` | Not specified (default RESTRICT) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Timetable Types Tab Loads With All UI Elements | Tab pane loads with search input (`tt_search`), shift filter dropdown, status filter, table columns (#, Code, Name, Shift, Start/End Time, Ordinal, Default Badge, Status Toggle, Actions), and Create button | — | — | ⬜ |
| TC-P02 | Filter Timetable Types By Name/Code Search | Enter a search term and submit; grid shows only TT records whose name or code contains the search string | — | — | ⬜ |
| TC-P03 | Filter Timetable Types By Shift | Select a shift from the filter dropdown; grid shows only TTs assigned to that shift | — | — | ⬜ |
| TC-P04 | Filter Timetable Types By Status | Select "Inactive" from status filter; grid shows only inactive TTs. Select "All"; all TTs shown | — | — | ⬜ |
| TC-P05 | Create Timetable Type With Required Fields Only | Fill code="STD_TEST", name="Standard Test", ordinal=1. Submit. TT created with `is_active=true`, `has_teaching=true`, `has_exam=false`, `is_default=false`. Redirect to masters with success flash | — | — | ⬜ |
| TC-P06 | Create Timetable Type With All Fields | Fill code="FULL_TEST", name="Full Test", description="Test desc", select a shift, effective_from=2026-04-01, effective_to=2027-03-31, school_start=07:30, school_end=13:30, ordinal=2, has_teaching=ON, has_exam=OFF, is_default=ON, is_active=ON. All values saved correctly. All other TTs have is_default set to false | — | — | ⬜ |
| TC-P07 | Create Timetable Type With `has_exam=true` | Create TT with has_exam=ON, has_teaching=OFF. TT created with `has_exam=1`, `has_teaching=0` | — | — | ⬜ |
| TC-P08 | Create Timetable Type With `is_default=false` | Create TT with is_default=OFF. Existing default TT remains default; is_default not overridden | — | — | ⬜ |
| TC-P09 | Create Timetable Type With Inline Class Assignments (All Sections) | Create TT with code="INLINE_ALL". In the classes section, select a class and check "All Sections". TT created; one `ClassTimetableType` row created with `section_id=null`, `applies_to_all_sections=true` | — | — | ⬜ |
| TC-P10 | Create Timetable Type With Inline Class Assignments (Specific Sections) | Create TT with code="INLINE_SPEC". Select a class and pick 2 specific sections. TT created; 2 `ClassTimetableType` rows created (one per section) with `applies_to_all_sections=false` | — | — | ⬜ |
| TC-P11 | Create Timetable Type With Inline Class Assignments (All Optional Fields) | Assign with period_set, academic_term, has_teaching=ON, has_exam=OFF, weekly_teaching_period_count=40, weekly_exam_period_count=0, weekly_free_period_count=5, effective_from=2026-04-01, effective_to=2026-09-30, is_active=ON. All fields saved correctly | — | — | ⬜ |
| TC-P12 | Create Timetable Type — Code Auto-Uppercased | Enter code="std_test". Saved as "STD_TEST" in DB | — | — | ⬜ |
| TC-P13 | View Timetable Type Details | Click View on a TT row. Show page loads with all fields: code, name, description, shift, effective period, school times, ordinal, teaching/exam flags, default/active badges, timestamps | — | — | ⬜ |
| TC-P14 | Edit Timetable Type Loads Pre-Filled Data | Click Edit on a TT row. Edit form loads with existing values for all fields. Inline class assignments shown grouped by class_id | — | — | ⬜ |
| TC-P15 | Update Timetable Type Name and Code | Change code and name; submit. TT updated; redirect with success flash. New values persist in DB | — | — | ⬜ |
| TC-P16 | Update Timetable Type — Change All Fields | Modify every field (shift, dates, times, flags, ordinal). All values updated correctly in DB | — | — | ⬜ |
| TC-P17 | Update Timetable Type — Change Inline Assignments | Edit a TT with 2 existing inline assignments. Remove one class, add a different class. On update, old assignments soft-deleted, new ones created (delete-all-then-recreate) | — | — | ⬜ |
| TC-P18 | Toggle Timetable Type Status Active → Inactive | Click status toggle on an active TT. AJAX POST to `toggle-status`. TT becomes inactive. JSON response `{success: true, is_active: false}`. UI updates badge | — | — | ⬜ |
| TC-P19 | Toggle Timetable Type Status Inactive → Active | Same as TC-P18 but reversing; TT becomes active; JSON returns `is_active: true` | — | — | ⬜ |
| TC-P20 | Soft Delete Timetable Type | Click Delete on an active TT. `is_active` set to false, record soft-deleted. Redirect to masters with success flash. Record appears in trash view | — | — | ⬜ |
| TC-P21 | View Trashed Timetable Types List | Navigate to trash view; all soft-deleted TTs listed with name, code, shift, deleted_at timestamp, and Restore / Force Delete action buttons | — | — | ⬜ |
| TC-P22 | Restore Soft-Deleted Timetable Type | Click Restore on a trashed TT. `deleted_at` nullified, `is_active=true`. Redirect to trash with success flash. TT reappears in main list | — | — | ⬜ |
| TC-P23 | Force Delete Timetable Type (No Children) | Click Force Delete on a trashed TT that has NO child ClassTimetableType records. TT permanently removed from DB. Redirect to trash with success flash | — | — | ⬜ |
| TC-P24 | Class Timetable Tab — Create Bulk (All Sections) | Navigate to Class Timetable tab → Create. Select academic_term, timetable_type, period_set, select 2 classes and check "All Sections" for both. Submit. 2 CTT rows created with `section_id=null`, `applies_to_all_sections=true`. Activity logged per row. Redirect with success flash | — | — | ⬜ |
| TC-P25 | Class Timetable Tab — Create Bulk (Specific Sections) | Select a class with 3 sections. Check 2 specific sections. Submit. 2 CTT rows created (one per section) with `applies_to_all_sections=false` | — | — | ⬜ |
| TC-P26 | Class Timetable Tab — Create With All Optional Fields | Submit weekly_teaching_period_count=40, weekly_exam_period_count=5, weekly_free_period_count=3, effective_from=2026-04-01, effective_to=2026-09-30, has_teaching=ON, has_exam=OFF, is_active=ON. All values saved correctly | — | — | ⬜ |
| TC-P27 | Class Timetable Tab — `updateOrCreate` Prevents Duplicates | Submit identical bulk form twice. No duplicate CTT rows created (composite key `(academic_term_id, timetable_type_id, class_id, section_id, applies_to_all_sections)` prevents duplicates) | — | — | ⬜ |
| TC-P28 | Class Timetable Tab — Create With Pre-Filtered Classes | When a `timetable_type_id` is selected that already has all sections assigned for a class, that class is hidden from the class selection list | — | — | ⬜ |
| TC-P29 | View Class Timetable Type Details | Click View on a CTT row. Show page loads with all fields: academic_term, timetable_type, class, section, period_set, flags, weekly counts, effective range, status | — | — | ⬜ |
| TC-P30 | Edit Class Timetable Type Loads Pre-Filled Data | Click Edit on a CTT row. Edit form loads with existing values; sections dropdown populated for the assigned class | — | — | ⬜ |
| TC-P31 | Update Class Timetable Type | Change timetable_type, section, period_set, flags, weekly counts, effective dates. Submit. CTT updated; redirect with success flash | — | — | ⬜ |
| TC-P32 | Toggle Class Timetable Type Status | Click status toggle on an active CTT row. AJAX POST returns JSON `{success: true, is_active: false}`. Toggle back returns `is_active: true` | — | — | ⬜ |
| TC-P33 | Soft Delete Class Timetable Type | Click Delete on an active CTT. `is_active` set to false, soft-deleted. Redirect with success flash | — | — | ⬜ |
| TC-P34 | View Trashed Class Timetable Types | Navigate to CTT trash view; soft-deleted rows listed with Restore / Force Delete actions | — | — | ⬜ |
| TC-P35 | Restore Soft-Deleted Class Timetable Type | Click Restore. CTT restored with `is_active=true`. Redirect with success flash | — | — | ⬜ |
| TC-P36 | Force Delete Class Timetable Type | Force Delete a trashed CTT. Record permanently removed. Redirect with success flash | — | — | ⬜ |
| TC-P37 | AJAX — `getSectionsByClass` Returns Unassigned Sections | Select a class with 3 sections where 1 section is already assigned to the chosen TT. AJAX call returns only the 2 unassigned sections as JSON `[{id, name}, ...]` | — | — | ⬜ |
| TC-P38 | AJAX — `getSectionsByClass` Returns Empty When All Sections Covered | Select a class where "All Sections" row exists for the chosen TT. AJAX call returns empty array `[]` | — | — | ⬜ |
| TC-P39 | AJAX — `getSectionsByClass` With Academic Term Filter | Sections already assigned for a specific academic term are excluded; sections assigned to a different term are still returned | — | — | ⬜ |
| TC-P40 | Trash View Pagination (TT) | Create 11+ soft-deleted TT records. Trash view shows 10 per page. Page 2 shows remaining records | — | — | ⬜ |
| TC-P41 | Trash View Pagination (CTT) | Create 11+ soft-deleted CTT records. Trash view shows 10 per page. Page 2 shows remaining records | — | — | ⬜ |
| TC-P42 | Full Lifecycle — Timetable Type: Create → View → Edit → Toggle → Soft Delete → Restore → Force Delete | Each step succeeds; data transitions correctly at each stage | — | — | ⬜ |
| TC-P43 | Full Lifecycle — Class Timetable Type: Create (Bulk) → View → Edit → Toggle → Soft Delete → Restore → Force Delete | Each step succeeds; data transitions correctly at each stage | — | — | ⬜ |
| TC-P44 | Empty State — No Timetable Types Exist | When no TT records exist, list table shows "No records found" | — | — | ⬜ |
| TC-P45 | Empty State — No Trashed Timetable Types | When no trashed TTs, trash view shows empty state | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `ordinal` | Validation error: "The ordinal field is required." | — | — | ⬜ |
| TC-N04 | Invalid — Duplicate `code` | Create two TTs with same code. Second fails: "The code has already been taken." | — | — | ⬜ |
| TC-N05 | Invalid — `code` > 30 Characters | Validation fails on code.max:30 | — | — | ⬜ |
| TC-N06 | Invalid — `code` With Special Characters (Not Regex) | Enter code containing spaces or special chars (e.g., "MY CODE!"). Validation fails on regex: `/^[A-Z0-9_]+$/i` | — | — | ⬜ |
| TC-N07 | Invalid — `name` > 100 Characters | Validation fails on name.max:100 | — | — | ⬜ |
| TC-N08 | Invalid — `ordinal` = 0 or Negative | Validation fails on ordinal.min:1 | — | — | ⬜ |
| TC-N09 | Invalid — `school_end_time` Before `school_start_time` (Create) | Set start=14:00, end=13:00. Controller check returns: "School end time must be after start time." | — | — | ⬜ |
| TC-N10 | Invalid — `school_end_time` Not After `school_start_time` (Update) | Same as N09 on update; validation rule `after:school_start_time` triggers | — | — | ⬜ |
| TC-N11 | Invalid — `effective_to_date` Before `effective_from_date` | Validation error: "The effective to date must be a date after or equal to effective from date." | — | — | ⬜ |
| TC-N12 | Invalid — Non-Existent `shift_id` | Validation error: "The selected shift is invalid." | — | — | ⬜ |
| TC-N13 | Invalid — `school_start_time` Wrong Format | Enter "25:00" or "7:30 PM". Validation fails on date_format:H:i | — | — | ⬜ |
| TC-N14 | Invalid — Non-Existent `classes.*.class_id` | Provide a non-existent class_id in inline assignments. Validation error on exists:sch_classes,id | — | — | ⬜ |
| TC-N15 | Invalid — Non-Existent `classes.*.section_ids.*` | Provide a non-existent section_id. Validation error on exists:sch_sections,id | — | — | ⬜ |
| TC-N16 | Invalid — Bulk CTT Create With No Sections Resolved | Select a class but neither check "All Sections" nor select specific sections. Controller error: "Each selected class needs 'All Sections' checked or at least one section selected." | — | — | ⬜ |
| TC-N17 | Invalid — Bulk CTT Create With `class_ids` Empty | Submit create with empty class_ids array. Validation error on class_ids.min:1 | — | — | ⬜ |
| TC-N18 | Invalid — CTT Update With Non-Existent `academic_term_id` | Update CTT with non-existent academic_term_id. Validation error | — | — | ⬜ |
| TC-N19 | Invalid — CTT Update `effective_to` Before `effective_from` | Validation error: after_or_equal rule on effective_to | — | — | ⬜ |
| TC-N20 | Permission 403 — No `timetable-foundation.timetable-type.viewAny` | User without viewAny → 403 on accessing the TT tab page | — | — | ⬜ |
| TC-N21 | Permission 403 — No `timetable-foundation.timetable-type.create` | User without create → 403 on create form (GET) and store (POST) | — | — | ⬜ |
| TC-N22 | Permission 403 — No `timetable-foundation.timetable-type.update` | User without update → 403 on edit, update, and toggleStatus | — | — | ⬜ |
| TC-N23 | Permission 403 — No `timetable-foundation.timetable-type.delete` | User without delete → 403 on destroy and forceDelete | — | — | ⬜ |
| TC-N24 | Permission 403 — No `timetable-foundation.timetable-type.restore` | User without restore → 403 on trash view and restore action | — | — | ⬜ |
| TC-N25 | Permission 403 — No `timetable-foundation.class-timetable.viewAny` | User without viewAny → 403 on CTT tab and AJAX endpoint | — | — | ⬜ |
| TC-N26 | Permission 403 — No `timetable-foundation.class-timetable.create` | User without create → 403 on CTT create form and store | — | — | ⬜ |
| TC-N27 | Permission 403 — No `timetable-foundation.class-timetable.update` | User without update → 403 on CTT edit, update, toggleStatus | — | — | ⬜ |
| TC-N28 | Permission 403 — No `timetable-foundation.class-timetable.delete` | User without delete → 403 on CTT destroy | — | — | ⬜ |
| TC-N29 | Permission 403 — No `timetable-foundation.class-timetable.restore` | User without restore → 403 on CTT trash and restore | — | — | ⬜ |
| TC-N30 | Permission 403 — No `timetable-foundation.class-timetable.forceDelete` | User without forceDelete → 403 on CTT forceDelete | — | — | ⬜ |
| TC-N31 | Guest Access Redirect | Unauthenticated user accessing any TT or CTT route → redirected to `/login` | — | — | ⬜ |
| TC-N32 | View Non-Existent Timetable Type (404) | `GET /timetable-foundation/timetable-type/99999` → 404 Not Found | — | — | ⬜ |
| TC-N33 | Edit/Update Non-Existent Timetable Type (404) | `GET /timetable-foundation/timetable-type/99999/edit` or `PUT` → 404 | — | — | ⬜ |
| TC-N34 | Delete Non-Existent Timetable Type (404) | `DELETE /timetable-foundation/timetable-type/99999` → 404 | — | — | ⬜ |
| TC-N35 | Restore/Force Delete Non-Existent TT (404) | `GET .../99999/restore` or `DELETE .../99999/force-delete` → 404 via `findOrFail` | — | — | ⬜ |
| TC-N36 | Toggle Status On Non-Existent TT (404) | `POST .../99999/toggle-status` → 404 via implicit model binding | — | — | ⬜ |
| TC-N37 | Force Delete TT With Child CTT Records (FK Restrict) | Force Delete a TT that has existing CTT records. FK constraint `fk_cttj_mode` (RESTRICT) prevents deletion; DB exception thrown | — | — | ⬜ |
| TC-N38 | XSS Injection In TT `name` or `description` | Store record with `<script>alert('xss')</script>`; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N39 | Whitespace-Only `name` | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N40 | Maximum Weekly Period Count > 99 | Set `weekly_teaching_period_count=100`. Validation fails on max:99 | — | — | ⬜ |
| TC-N41 | Negative Weekly Period Count | Set `weekly_exam_period_count=-1`. Validation fails on min:0 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Default TT → All Other TTs Set To Non-Default | Creating a TT with `is_default=true` when another default exists automatically sets the existing default to `is_default=false` | — | — | ⬜ |
| TC-D02 | A | Update TT To Default → Previous Default Becomes Non-Default | Updating a TT to `is_default=true` unsets `is_default` for all other TTs (excluding self) | — | — | ⬜ |
| TC-D03 | B | Code Uppercased On Save | Enter lowercase code `std_test`; DB stores `STD_TEST` | — | — | ⬜ |
| TC-D04 | C | Delete-All-Recreate Strategy On TT Update | Updating a TT with inline assignments deletes all old CTT records and creates new ones from form data | — | — | ⬜ |
| TC-D05 | C | Unsubmitted Inline Assignments Lost On Update | Existing CTT records for a TT that are not resubmitted in the classes array are soft-deleted (delete-all-then-recreate) | — | — | ⬜ |
| TC-D06 | D | Inline CTT Inherits TT Defaults | When creating TT with inline classes and no explicit `has_teaching` on the class row, the TT's default `has_teaching=true` is applied to the CTT | — | — | ⬜ |
| TC-D07 | E | Soft Delete TT Sets `is_active=false` | `destroy()` sets `is_active=false` before `delete()`; after delete, record has `is_active=0`, `deleted_at` set | — | — | ⬜ |
| TC-D08 | E | Restore TT Sets `is_active=true` | After restore, `is_active=true`, `deleted_at=NULL` | — | — | ⬜ |
| TC-D09 | F | `updateOrCreate` Prevents Duplicate CTT Rows | Submitting same bulk CTT form twice does not create duplicate rows — `updateOrCreate` finds existing match by composite key | — | — | ⬜ |
| TC-D10 | G | `getSectionsByClass` Excludes Individually Assigned Sections | When a section is already assigned to the TT+class combo, AJAX does not return it | — | — | ⬜ |
| TC-D11 | G | `getSectionsByClass` Returns Empty For Fully Covered Class | When "All Sections" row exists, AJAX returns `[]` | — | — | ⬜ |
| TC-D12 | H | DB CHECK — Section Mutual Exclusion | Direct DB INSERT with `section_id=1, applies_to_all_sections=1` (should be 0) fails with constraint violation `chk_cttj_apply_to_all_section` | — | — | ⬜ |
| TC-D13 | I | DB CHECK — Effective Date Ordering | Direct DB INSERT with `effective_from=2026-09-01, effective_to=2026-04-01` fails with constraint `chk_valid_effective_range` | — | — | ⬜ |
| TC-D14 | J | DB UNIQUE — `uq_tttype_code` | Direct DB INSERT of duplicate code fails with integrity constraint violation | — | — | ⬜ |
| TC-D15 | K | Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD Operations | `activityLog('Stored')` after create; `activityLog('Updated')` after update; `activityLog('Trashed')` after destroy; `activityLog('Restored')` after restore; `activityLog('Deleted')` after forceDelete; `activityLog('Toggled')` after toggleStatus; each entry contains performed_by, message, and context data | — | — | ⬜ |
| TC-D16 | L | Unit \| P1 \| TimetableType model — `$casts` — Boolean/Date/Time Casting | `is_active`, `has_exam`, `has_teaching`, `is_default` stored as TINYINT but accessed as boolean; `effective_from_date`, `effective_to_date` cast to date; `school_start_time`, `school_end_time` cast to datetime:H:i:s | — | — | ⬜ |
| TC-D17 | M | Unit \| P1 \| TimetableType model — `$fillable` Matches DDL Columns | `$fillable` array contains all 12 writable columns; `id`, `created_at`, `updated_at`, `deleted_at` NOT fillable | — | — | ⬜ |
| TC-D18 | N | Unit \| P1 \| TimetableType model — SoftDeletes Trait | `delete()` sets `deleted_at`; `restore()` nullifies `deleted_at`; `withTrashed()` includes soft-deleted; `onlyTrashed()` filters to deleted only | — | — | ⬜ |
| TC-D19 | O | Unit \| P1 \| TimetableType model — belongsTo Shift Relationship | `$tt->shift` returns correct `SchoolShift` model; `$tt->shift()->associate($shift)` sets `shift_id`; eager loading works | — | — | ⬜ |
| TC-D20 | P | Unit \| P1 \| TimetableType model — hasMany ClassTimetableType Relationship | `$tt->classTimetableTypes` returns all `ClassTimetableType` records where `timetable_type_id` = TT id; returns empty collection when none exist | — | — | ⬜ |
| TC-D21 | Q | Unit \| P1 \| ClassTimetableType model — `$casts` — Boolean/Date/Integer Casting | `applies_to_all_sections`, `has_teaching`, `has_exam`, `is_active` stored as TINYINT but accessed as boolean; `effective_from`, `effective_to` cast to date; weekly count fields cast to integer | — | — | ⬜ |
| TC-D22 | R | Unit \| P1 \| ClassTimetableType model — `$fillable` Matches DDL Columns | `$fillable` contains all writable columns; `id`, `created_at`, `updated_at`, `deleted_at` NOT fillable | — | — | ⬜ |
| TC-D23 | S | Unit \| P1 \| ClassTimetableType model — belongsTo Relationships | `academicTerm()`, `timetableType()`, `periodSet()`, `class()`, `section()` — each returns correct related model; eager loading works | — | — | ⬜ |
| TC-D24 | T | Integration \| P1 \| Controller — `findOrFail` — All Methods With Valid/Invalid IDs | Valid ID loads model; Invalid ID throws `ModelNotFoundException` → HTTP 404 for all methods (show, edit, update, destroy, restore, forceDelete, toggleStatus) on both controllers | — | — | ⬜ |
| TC-D25 | U | Integration \| P1 \| Controller — `Gate::authorize()` — Authorization Before All Methods | Every controller method calls `Gate::authorize()` with its respective permission string before logic executes | — | — | ⬜ |
| TC-D26 | V | Integration \| P1 \| Controller — DB Transaction on store/update | `TimetableTypeController@store` and `update` wrap all writes in `DB::transaction()`. On exception, transaction rolled back. | — | — | ⬜ |
| TC-D27 | W | Integration \| P1 \| Controller — `toggleStatus()` Returns JSON | AJAX POST returns JSON `{success: true/false, is_active: bool, message: string}`; on failure `success: false` and 422 status | — | — | ⬜ |
| TC-D28 | X | Unit \| P1 \| TimetableTypePolicy — All Policy Gates Defined | Policy defines 6 gates: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`; each maps to matching permission string | — | — | ⬜ |
| TC-D29 | Y | Unit \| P1 \| ClassTimetableTypePolicy — All Policy Gates Defined | Policy defines 6 gates matching `timetable-foundation.class-timetable.*` permissions | — | — | ⬜ |
| TC-D30 | Z | Integration \| P1 \| Routes — Resource + Custom Routes Registered (TT) | Resource routes + trash, restore, forceDelete, toggleStatus for timetaable-type; all map to correct controller methods | — | — | ⬜ |
| TC-D31 | AA | Integration \| P1 \| Routes — Resource + Custom Routes + AJAX (CTT) | Resource routes + trash, restore, forceDelete, toggleStatus + `/ajax/sections/{classId}`; all map to correct controller methods | — | — | ⬜ |
| TC-D32 | AB | Integration \| P1 \| TimetableType model — Global Scope `ordered` | All queries automatically ordered by `ordinal` unless `withoutGlobalScope('ordered')` is used | — | — | ⬜ |
| TC-D33 | AC | Integration \| P1 \| TimetableType model — Scope `effectiveOn(date)` | `TimetableType::effectiveOn('2026-06-15')` returns records where `effective_from_date <= '2026-06-15'` and `effective_to_date >= '2026-06-15'` (null means no bound) | — | — | ⬜ |
| TC-D34 | AD | Integration \| P1 \| ClassTimetableType model — Scope `effectiveOn(date)` | Same effective date filtering on CTT | — | — | ⬜ |
| TC-D35 | AE | Cross-Module \| P1 \| Slot Requirement — FK to `class_timetable_type_id` | Deleting a CTT that has `tt_slot_requirements` referencing it may be blocked by FK constraint | — | — | ⬜ |
| TC-D36 | AF | Cross-Module \| P1 \| Timetable — FK to `timetable_type_id` | `tt_timetables.timetable_type_id` references `tt_timetable_types.id` via FK `fk_tt_type` with ON DELETE RESTRICT. Force deleting a TT with timetables is blocked | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns (mass-assignment protection) — TimetableType | `$fillable` contains exactly: code, name, description, shift_id, effective_from_date, effective_to_date, school_start_time, school_end_time, has_exam, has_teaching, ordinal, is_default, is_active | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$fillable` matches DDL columns — ClassTimetableType | `$fillable` contains exactly: academic_term_id, timetable_type_id, class_id, section_id, period_set_id, applies_to_all_sections, has_teaching, has_exam, weekly_exam_period_count, weekly_teaching_period_count, weekly_free_period_count, effective_from, effective_to, is_active | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `$casts` for booleans/integers/dates — TimetableType | `has_exam`, `has_teaching`, `is_default`, `is_active` → boolean; `effective_from_date`/`effective_to_date` → date; `school_start_time`/`school_end_time` → datetime:H:i:s; `shift_id`, `ordinal` → integer | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — `$casts` for booleans/integers/dates — ClassTimetableType | `applies_to_all_sections`, `has_teaching`, `has_exam`, `is_active` → boolean; `effective_from`, `effective_to` → date; weekly count fields → integer | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — SoftDeletes trait correctly implemented — TimetableType | `use SoftDeletes;` present; `delete()` sets `deleted_at`; `restore()` nullifies `deleted_at`; `forceDelete()` permanently removes | — | — | ◌ |
| TC-CR06 | CR | P1 | Model — relationships defined — TimetableType | `shift()` → `belongsTo(SchoolShift::class)`; `classTimetableTypes()` → `hasMany(ClassTimetableType::class)`; `classModeRules()` → `hasMany(ClassModeRule::class)`; `timetables()` → `hasMany(Timetable::class)`; scopes: `active()`, `default()`, `ordered()`, `effectiveOn()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — relationships defined — ClassTimetableType | `academicTerm()` → `belongsTo(AcademicTerm::class)`; `timetableType()` → `belongsTo(TimetableType::class)`; `periodSet()` → `belongsTo(PeriodSet::class)`; `class()` → `belongsTo(SchoolClass::class)`; `section()` → `belongsTo(Section::class)`; scopes: `active()`, `effectiveOn()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — try-catch exception handling on all write methods | Both controllers' `store()`, `update()`, `destroy()` use try-catch or DB transaction with rollback on exception | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — DB transactions on multi-step writes | `TimetableTypeController@store()` and `update()` wrap all writes in `DB::transaction()`; `ClassTimetableTypeController@store()` and `update()` use individual queries without explicit transaction | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `Gate::authorize()` on every method | Every controller method across both controllers calls `Gate::authorize()` with its respective permission string before business logic | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called after create/update/destroy/restore/forceDelete/toggleStatus in both controllers with appropriate event name and context | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` before `delete()`; `restore()` sets `is_active=true` after restoring (both controllers) | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | Both controllers: receives `is_active`, sets field, saves, returns JSON with new value and success flag | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashed*()` uses `onlyTrashed()->paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail($id)->restore()`; `forceDelete()` uses `withTrashed()->findOrFail($id)->forceDelete()` | — | — | ◌ |
| TC-CR15 | CR | P1 | Controller — redirect/JSON response after create/update/delete | `store()`/`update()`/`destroy()` → `redirect()->route(...)->with('success', flash(...))`; `toggleStatus()` → `response()->json([...])`; `restore()`/`forceDelete()` → `redirect()->route('*.trashed')` | — | — | ◌ |
| TC-CR16 | CR | P1 | Request — validation rules cover all fields (TT) | All 13+ fields validated inline in controller; `code` unique excludes current ID on update via `->ignore()` | — | — | ◌ |
| TC-CR17 | CR | P1 | Request — validation rules cover all fields (CTT) | All CTT fields validated; `effective_to` uses `after_or_equal:effective_from` | — | — | ◌ |
| TC-CR18 | CR | P1 | Policy — all required methods defined; permission strings match route/gate names | Both policies define: viewAny, view, create, update, delete, restore, forceDelete; each maps to `timetable-foundation.{feature}.{action}` | — | — | ◌ |
| TC-CR19 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | Resource routes + trash/restore/forceDelete/toggleStatus + AJAX endpoint for CTT; implicit model binding on `{timetableType}` and `{classTimetableType}` | — | — | ◌ |
| TC-CR20 | CR | P1 | View — Blade `@can` directives on tab/action buttons | Views check permissions for create/edit/delete/toggle buttons; tab visibility gated by viewAny permissions | — | — | ◌ |
| TC-CR21 | CR | P1 | View — `isset()`/null-safe checks for relationship variables | `$tt->shift->name ?? '--'` pattern used; null-safe access for optional shift, effective dates, section | — | — | ◌ |
| TC-CR22 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` and renders correct hierarchy | Each view (create, edit, show, trash) defines breadcrumb; hierarchy reflects correct parent screens | — | — | ◌ |
| TC-CR23 | CR | P1 | Database — unique indexes match request validation rules | `uq_tttype_code` on `(code)` matches unique validation; CHECK constraints `chk_tttype_time`, `chk_valid_effective_range`, `chk_cttj_apply_to_all_section` enforced at DB level | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns (Mass-Assignment Protection) — TimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TimetableType.php` model | Model found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains exactly: `code`, `name`, `description`, `shift_id`, `effective_from_date`, `effective_to_date`, `school_start_time`, `school_end_time`, `has_exam`, `has_teaching`, `ordinal`, `is_default`, `is_active` |
| 3 | Verify `id`, `created_at`, `updated_at`, `deleted_at` NOT in fillable | PK and audit columns are guarded from mass assignment |
| 4 | Cross-check with DDL columns | All writable DDL columns present; no extra columns |

#### TC-CR02: Model — `$fillable` Matches DDL Columns — ClassTimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassTimetableType.php` model | Model found |
| 2 | Inspect `$fillable` array | Contains: `academic_term_id`, `timetable_type_id`, `class_id`, `section_id`, `period_set_id`, `applies_to_all_sections`, `has_teaching`, `has_exam`, `weekly_exam_period_count`, `weekly_teaching_period_count`, `weekly_free_period_count`, `effective_from`, `effective_to`, `is_active` |
| 3 | Verify `id`, `created_at`, `updated_at`, `deleted_at` NOT in fillable | Guarded columns excluded |

#### TC-CR03: Model — `$casts` for Booleans/Integers/Dates — TimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` in TimetableType | `has_exam` → boolean, `has_teaching` → boolean, `is_default` → boolean, `is_active` → boolean; `effective_from_date`/`effective_to_date` → date; `school_start_time`/`school_end_time` → datetime:H:i:s; `shift_id`/`ordinal` → integer |
| 2 | Create a TT and fetch it | Cast fields return correct PHP types (bool/Carbon/int) |

#### TC-CR04: Model — `$casts` for Booleans/Integers/Dates — ClassTimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` in ClassTimetableType | `applies_to_all_sections` → boolean, `has_teaching` → boolean, `has_exam` → boolean, `is_active` → boolean; `effective_from`/`effective_to` → date; weekly counts → integer |
| 2 | Create a CTT and fetch it | Cast fields return correct PHP types |

#### TC-CR05: Model — SoftDeletes Trait Correctly Implemented — TimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TimetableType for `use SoftDeletes` | `use Illuminate\Database\Eloquent\SoftDeletes;` present |
| 2 | Verify `deleted_at` column in DDL | `deleted_at` is nullable TIMESTAMP |
| 3 | Soft delete a TT record | `deleted_at` set; record excluded from normal queries |
| 4 | Call `withTrashed()` | Record appears in results |
| 5 | Call `onlyTrashed()` | Only soft-deleted records appear |
| 6 | Restore the record | `deleted_at` set to NULL; record visible in normal queries |

#### TC-CR06: Model — Relationships Defined — TimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `shift()` relationship | `belongsTo(SchoolShift::class, 'shift_id')` |
| 2 | Inspect `classTimetableTypes()` relationship | `hasMany(ClassTimetableType::class, 'timetable_type_id')` |
| 3 | Inspect `classModeRules()` relationship | `hasMany(ClassModeRule::class, 'timetable_type_id')` |
| 4 | Inspect `timetables()` relationship | `hasMany(Timetable::class, 'timetable_type_id')` |
| 5 | Inspect scope methods | `scopeActive()`, `scopeDefault()`, `scopeOrdered()`, `scopeEffectiveOn(date)` defined |

#### TC-CR07: Model — Relationships Defined — ClassTimetableType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `academicTerm()` | `belongsTo(AcademicTerm::class)` |
| 2 | Inspect `timetableType()` | `belongsTo(TimetableType::class)` |
| 3 | Inspect `periodSet()` | `belongsTo(PeriodSet::class)` |
| 4 | Inspect `class()` | `belongsTo(SchoolClass::class, 'class_id')` |
| 5 | Inspect `section()` | `belongsTo(Section::class, 'section_id')` |
| 6 | Inspect scopes | `scopeActive()`, `scopeEffectiveOn(date)` defined |

#### TC-CR08: Controller — Try-Catch Exception Handling on All Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@store()` | `DB::transaction()` wraps all logic; auto rollback on exception |
| 2 | Inspect `TimetableTypeController@update()` | `DB::transaction()` wraps all logic; auto rollback on exception |
| 3 | Inspect `TimetableTypeController@destroy()` | Sets flags, calls delete(), logs activity — no explicit try-catch |
| 4 | Inspect `ClassTimetableTypeController@store()` | Multi-step create with `updateOrCreate` — no explicit transaction |
| 5 | Inspect `ClassTimetableTypeController@update()` | Single `update()` call — no explicit transaction |

#### TC-CR09: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@store()` | `DB::transaction()` wraps TT create + CTT bulk create |
| 2 | Inspect `TimetableTypeController@update()` | `DB::transaction()` wraps TT update + CTT delete-all + recreate |
| 3 | Inspect `ClassTimetableTypeController@store()` | No explicit DB transaction; multiple `updateOrCreate()` calls run individually |

#### TC-CR10: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@index()` | `Gate::authorize('timetable-foundation.timetable-type.viewAny')` |
| 2 | Inspect `create()` | `.create` |
| 3 | Inspect `store()` | `.create` |
| 4 | Inspect `show()` | `.view` |
| 5 | Inspect `edit()` | `.update` |
| 6 | Inspect `update()` | `.update` |
| 7 | Inspect `destroy()` | `.delete` |
| 8 | Inspect `trashedTimetableType()` | `.viewAny` |
| 9 | Inspect `restore()` | `.restore` |
| 10 | Inspect `forceDelete()` | `.delete` |
| 11 | Inspect `toggleStatus()` | `.update` |
| 12 | Repeat for `ClassTimetableTypeController` methods | Each method gates with `timetable-foundation.class-timetable.*` |

#### TC-CR11: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@store()` | `activityLog($timetableType, 'Stored', [...])` with message |
| 2 | Inspect `update()` | `activityLog($timetableType, 'Updated', [...])` |
| 3 | Inspect `destroy()` | `activityLog($timetableType, 'Trashed', [...])` |
| 4 | Inspect `restore()` | `activityLog($timetableType, 'Restored', [...])` |
| 5 | Inspect `forceDelete()` | `activityLog($timetableType, 'Deleted', [...])` |
| 6 | Inspect `toggleStatus()` | `activityLog($timetableType, 'Toggled', [...])` |
| 7 | Repeat for CTT controller | Same pattern using `$classTimetableType` |

#### TC-CR12: Controller — `is_active=false` Before Soft Delete; Restore Sets `is_active=true`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@destroy()` | `$timetableType->is_active = false; $timetableType->save();` called BEFORE `$timetableType->delete()` |
| 2 | Inspect `restore()` | `$timetableType->restore(); $timetableType->is_active = true; $timetableType->save();` |
| 3 | Verify CTT controller | Same pattern in `ClassTimetableTypeController@destroy()` and `restore()` |

#### TC-CR13: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@toggleStatus()` | Receives `is_active`; sets `$timetableType->is_active = $request->boolean('is_active')`; calls `save()` |
| 2 | Verify response | `response()->json(['success' => true, 'is_active' => ..., 'message' => flash(...)])` |
| 3 | Inspect CTT `toggleStatus()` | Same pattern |

#### TC-CR14: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@trashedTimetableType()` | `TimetableType::onlyTrashed()->orderBy('name')->paginate(10)` |
| 2 | Inspect `restore($id)` | `TimetableType::onlyTrashed()->findOrFail($id)->restore()` |
| 3 | Inspect `forceDelete($id)` | `TimetableType::withTrashed()->findOrFail($id)->forceDelete()` |
| 4 | Inspect CTT controller | Same patterns |

#### TC-CR15: Controller — Redirect/JSON Response After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TimetableTypeController@store()` success | `redirect()->route('timetable-foundation.menu.timetableMasters', ['tab' => 'timetable-types'])->with('success', flash('created.timetable_type'))` |
| 2 | Inspect `update()` success | Same redirect with `flash('updated.timetable_type')` |
| 3 | Inspect `destroy()` success | Same redirect with `flash('deleted.timetable_type')` |
| 4 | Inspect `restore()` success | `redirect()->route('timetable-foundation.timetable-type.trashed')->with('success', flash('restored.timetable_type'))` |
| 5 | Inspect `forceDelete()` success | `redirect()->route('timetable-foundation.timetable-type.trashed')->with('success', flash('force_deleted.timetable_type'))` |
| 6 | Inspect `toggleStatus()` | JSON with success, is_active, message |

#### TC-CR16: Request — Validation Rules Cover All Fields (TT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TimetableTypeController` | `store()` and `update()` contain inline `$request->validate([...])` |
| 2 | Verify all fields validated | code, name, description, shift_id, effective_from/to, school_start/end, ordinal, has_teaching, has_exam, is_default, is_active, classes array with nested validation |
| 3 | Verify unique rule ignores current ID on update | `Rule::unique('tt_timetable_types', 'code')->ignore($timetableType->id)` used in `update()` |

#### TC-CR17: Request — Validation Rules Cover All Fields (CTT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassTimetableTypeController@store()` | Inline validation with all CTT fields |
| 2 | Verify cross-field check | Each class must have sections resolved; error returned if missing |

#### TC-CR18: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TimetableTypePolicy.php` | 6 methods: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Open `ClassTimetableTypePolicy.php` | 6 methods matching class-timetable permissions |
| 3 | Verify each method returns `$user->can('permission.string')` | Each maps to correct permission string |

#### TC-CR19: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` for TimetableFoundation | Route groups found |
| 2 | Verify TT resource routes | `Route::resource('timetable-type', TimetableTypeController::class)` |
| 3 | Verify TT custom routes | `/trash/view` (GET), `/{id}/restore` (GET), `/{id}/force-delete` (DELETE), `/{timetableType}/toggle-status` (POST) |
| 4 | Verify CTT resource routes | `Route::resource('class-timetable', ClassTimetableTypeController::class)` |
| 5 | Verify CTT custom + AJAX routes | `/ajax/sections/{classId}` (GET), `/trash/view` (GET), `/{id}/restore` (GET), `/{id}/force-delete` (DELETE), `/{classTimetableType}/toggle-status` (POST) |
| 6 | Verify implicit model binding | Route parameter `{timetableType}` and `{classTimetableType}` trigger ModelNotFoundException for invalid IDs |

#### TC-CR20: View — Blade `@can` Directives on Tab/Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect timetable type views | Create button guarded by `@can('timetable-foundation.timetable-type.create')` |
| 2 | Inspect row action buttons | View, Edit, Delete actions guarded by respective permissions |
| 3 | Inspect CTT views | Same pattern with `class-timetable.*` permissions |
| 4 | Log in as user with limited permissions | Corresponding buttons hidden |

#### TC-CR21: View — `isset()`/Null-Safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect timetable type list view | `$tt->shift->name ?? '--'` pattern for optional shift relationship |
| 2 | Inspect null-safe date formatting | `$tt->effective_from_date?->format('d M Y') ?? '--'` patterns |
| 3 | No undefined index/property errors | View handles null relationships gracefully |

#### TC-CR22: Breadcrumb — Route Registered in Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check breadcrumb config | Create/edit/show/trash views define breadcrumb via `x-backend.components.breadcrum` component |
| 2 | Load each view | Breadcrumb shows correct hierarchy (Timetable Foundation > Timetable Masters > [Feature]) |

#### TC-CR23: Database — Unique Indexes Match Request Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `uq_tttype_code` on `(code)` | Matches unique validation rule on code |
| 2 | Verify `chk_tttype_time` CHECK | `school_end_time > school_start_time` AND `effective_from_date <= effective_to_date` enforced |
| 3 | Verify `chk_valid_effective_range` CHECK | `effective_from < effective_to` on CTT table |
| 4 | Verify `chk_cttj_apply_to_all_section` CHECK | Section mutual exclusion enforced at DB level |

### 7.1 Positive TC Steps

#### TC-P01: Timetable Types Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to Timetable Foundation → Timetable Masters | Page loads with multiple tabs |
| 3 | Click "Timetable Types" tab (or navigate with `?tab=timetable-types`) | Tab pane loads with search input, shift filter, status filter, table, Create button |
| 4 | Check search input | Input with placeholder present |
| 5 | Check shift filter dropdown | Dropdown with active shifts present |
| 6 | Check status filter | Active/Inactive/All options |
| 7 | Check table columns | #, Code, Name, Shift, Start Time, End Time, Ordinal, Default Badge, Status Toggle, Actions columns present |
| 8 | Check Create button | Button present (if create permission) |

---

#### TC-P05: Create Timetable Type With Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Timetable Foundation → Timetable Masters → Timetable Types tab | Page loads |
| 2 | Click "Create" button | Create form loads with all sections (Identity, Relations, Effective Period, Time Configuration, Flags & Ordering, Class Assignments) |
| 3 | Enter code: `STD_TEST` | Field filled |
| 4 | Enter name: `Standard Test` | Field filled |
| 5 | Enter ordinal: `1` | Field filled |
| 6 | Click "Save" | POST to `timetable-type.store` |
| 7 | Check response | Redirected to masters page with success flash |
| 8 | DB check: `SELECT * FROM tt_timetable_types WHERE code='STD_TEST'` | Record exists; `is_active=1`, `has_teaching=1`, `has_exam=0`, `is_default=0` |

---

#### TC-P06: Create Timetable Type With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill code: `FULL_TEST`, name: `Full Test`, description: `Full test description` | Identity filled |
| 3 | Select a shift from dropdown | shift_id set |
| 4 | Set effective_from: `2026-04-01`, effective_to: `2027-03-31` | Dates set |
| 5 | Set school_start_time: `07:30`, school_end_time: `13:30` | Times set |
| 6 | Set ordinal: `2` | Ordinal set |
| 7 | Toggle has_teaching: ON, has_exam: OFF, is_default: ON, is_active: ON | Flags set |
| 8 | Click "Save" | POST to store |
| 9 | DB check: `SELECT * FROM tt_timetable_types WHERE code='FULL_TEST'` | All fields saved correctly; `is_default=1` |
| 10 | DB check: `SELECT is_default FROM tt_timetable_types WHERE is_default=1` | Only this record has `is_default=1` (previous default reset) |

---

#### TC-P09: Create Timetable Type With Inline Class Assignments (All Sections)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill required fields: code=`INLINE_ALL`, name=`Inline All`, ordinal=3 | Required fields set |
| 3 | In the Class Assignments section, select a class from the dropdown | Class selected |
| 4 | Check "All Sections" checkbox | `applies_to_all_sections` will be true |
| 5 | Select a period_set and academic_term | Assignment details set |
| 6 | Click "Save" | TT created |
| 7 | DB check: `SELECT * FROM tt_class_timetable_types_jnt WHERE timetable_type_id = (SELECT id FROM tt_timetable_types WHERE code='INLINE_ALL')` | 1 row created; `section_id=NULL`, `applies_to_all_sections=1` |

---

#### TC-P10: Create Timetable Type With Inline Class Assignments (Specific Sections)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form, fill required fields: code=`INLINE_SPEC`, name=`Inline Specific`, ordinal=4 | Required fields set |
| 2 | Select a class that has 3 sections | Class selected |
| 3 | Check 2 specific section checkboxes (not "All Sections") | 2 sections selected |
| 4 | Click "Save" | TT created |
| 5 | DB check: `SELECT COUNT(*) FROM tt_class_timetable_types_jnt WHERE timetable_type_id = (SELECT id FROM tt_timetable_types WHERE code='INLINE_SPEC')` | 2 rows created; each has `section_id` set, `applies_to_all_sections=0` |

---

#### TC-P13: View Timetable Type Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a TT with all fields | TT exists |
| 2 | Click "View" (eye icon) on that TT row | Show page loads |
| 3 | Check heading | TT name displayed |
| 4 | Check code displayed | Code shown |
| 5 | Check shift, description, effective dates, school times | All displayed |
| 6 | Check ordinal, flags (teaching, exam, default, active) | Flags shown as badges |
| 7 | Check timestamps | created_at/updated_at shown |

---

#### TC-P18: Toggle Timetable Type Status Active → Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a TT with is_active=ON | TT is active |
| 2 | Click the status toggle switch on that row | AJAX POST to `toggle-status` |
| 3 | Check response | JSON `{success: true, is_active: false, message: flash(...)}` |
| 4 | DB check: `SELECT is_active FROM tt_timetable_types WHERE id={id}` | `is_active=0` |
| 5 | Click toggle again | `is_active=1` — toggled back |

---

#### TC-P20: Soft Delete Timetable Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a TT with is_active=ON | TT exists |
| 2 | Click "Delete" on that row | DELETE to `timetable-type.destroy` |
| 3 | DB check: `SELECT is_active, deleted_at FROM tt_timetable_types WHERE id={id}` | `is_active=0`, `deleted_at` set |
| 4 | Verify redirect | Redirected to masters page with success flash |

---

#### TC-P24: Class Timetable Tab — Create Bulk (All Sections)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Timetable Masters → Class Timetable tab | Tab loads |
| 2 | Click "Create" button | CTT create form loads |
| 3 | Select an academic term | Academic term selected |
| 4 | Select a timetable type | TT selected |
| 5 | Select a period set | Period set selected |
| 6 | In the class selection, check 2 classes | 2 classes selected |
| 7 | For each class, check "All Sections" | `applies_to_all_sections` will be true for both |
| 8 | Click "Save" | POST to `class-timetable.store` |
| 9 | Check response | Redirected to masters page with success flash |
| 10 | DB check: `SELECT COUNT(*) FROM tt_class_timetable_types_jnt WHERE timetable_type_id={ttId}` | 2 rows created; both have `section_id=NULL`, `applies_to_all_sections=1` |

---

#### TC-P25: Class Timetable Tab — Create Bulk (Specific Sections)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open CTT create form | Form visible |
| 2 | Select academic term, TT, period set | Shared fields set |
| 3 | Select a class with 3 sections | Class selected |
| 4 | Check 2 specific section checkboxes | 2 sections selected |
| 5 | Select another class with 2 sections, check both sections | 2 more sections selected |
| 6 | Click "Save" | CTTs created |
| 7 | DB check: Total rows = 4 (2+2) | 4 rows created; each has correct section_id, `applies_to_all_sections=0` |

---

#### TC-P37: AJAX — `getSectionsByClass` Returns Unassigned Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a class with 3 sections (A, B, C) | Class exists |
| 2 | Create a CTT assignment for that class + TT, section=A | Section A assigned |
| 3 | Call `GET /class-timetable/ajax/sections/{classId}?timetable_type_id={ttId}` | JSON returns only sections B and C (`[{id: B_id, name: "B"}, {id: C_id, name: "C"}]`) |
| 4 | Verify section A is excluded | Section A not in response |

---

#### TC-P38: AJAX — `getSectionsByClass` Returns Empty When All Sections Covered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a CTT with `applies_to_all_sections=true` for a class+TT | "All Sections" row exists |
| 2 | Call `GET /class-timetable/ajax/sections/{classId}?timetable_type_id={ttId}` | Returns `[]` |

### 7.2 Negative TC Steps

#### TC-N01: Required — Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TT create form | Form visible |
| 2 | Leave code blank | Empty |
| 3 | Fill all other required fields: name, ordinal | Fields filled |
| 4 | Click "Save" | Validation error: "The code field is required." |

---

#### TC-N04: Invalid — Duplicate `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create TT with code `DUP_TEST` | First TT created |
| 2 | Open create form again | Form visible |
| 3 | Enter code `DUP_TEST` for second TT | Duplicate code |
| 4 | Fill other required fields | Fields filled |
| 5 | Click "Save" | Validation error: "The code has already been taken." |

---

#### TC-N09: Invalid — `school_end_time` Before `school_start_time` (Create)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TT create form | Form visible |
| 2 | Fill required fields: code=`TIME_TEST`, name=`Time Test`, ordinal=5 | Required fields set |
| 3 | Set school_start_time=`14:00`, school_end_time=`13:00` | End before start |
| 4 | Click "Save" | Controller check triggers: "School end time must be after start time." |

---

#### TC-N16: Invalid — Bulk CTT Create With No Sections Resolved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open CTT create form | Form visible |
| 2 | Select academic term, TT, period set | Fields set |
| 3 | Select a class — do NOT check "All Sections" and do NOT select any sections | No sections resolved |
| 4 | Click "Save" | Controller check: "Each selected class needs 'All Sections' checked or at least one section selected." |

---

#### TC-N37: Force Delete TT With Child CTT Records (FK Restrict)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a TT with at least one inline CTT assignment | TT + child CTT exist |
| 2 | Soft delete the TT | TT is trashed |
| 3 | Navigate to TT trash view | Trash view shows the TT |
| 4 | Click "Force Delete" on that TT | FK constraint `fk_cttj_mode` (RESTRICT) prevents deletion |
| 5 | Verify error | DB exception thrown (not caught) — user sees SQL error or 500 |

### 7.3 Dependency TC Steps

#### TC-D01: Create Default TT → All Other TTs Set To Non-Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create TT-1 with is_default=ON | TT-1 created as default |
| 2 | DB check: `SELECT is_default FROM tt_timetable_types WHERE id={id1}` | `is_default=1` |
| 3 | Create TT-2 with is_default=ON | TT-2 created |
| 4 | DB check: `SELECT is_default FROM tt_timetable_types WHERE id={id1}` | `is_default=0` (cleared) |
| 5 | DB check: `SELECT is_default FROM tt_timetable_types WHERE id={id2}` | `is_default=1` (new default) |

---

#### TC-D03: Code Uppercased On Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TT create form | Form visible |
| 2 | Enter code: `std_test` | Lowercase code entered |
| 3 | Fill name, ordinal | Required fields |
| 4 | Click "Save" | TT created |
| 5 | DB check: `SELECT code FROM tt_timetable_types WHERE name='...'` | code = `STD_TEST` (uppercased) |

---

#### TC-D07: Soft Delete TT Sets `is_active=false`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create TT with is_active=ON | TT active |
| 2 | DB check: `SELECT is_active, deleted_at FROM tt_timetable_types WHERE id={id}` | `is_active=1`, `deleted_at=NULL` |
| 3 | Click "Delete" on that TT | Soft delete triggered |
| 4 | DB check: Same SELECT | `is_active=0`, `deleted_at` has timestamp |

---

#### TC-D12: DB CHECK — Section Mutual Exclusion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt direct SQL: `INSERT INTO tt_class_timetable_types_jnt (timetable_type_id, class_id, period_set_id, section_id, applies_to_all_sections) VALUES (1, 1, 1, 1, 1)` | Constraint violation: `chk_cttj_apply_to_all_section` — section_id not null with applies_to_all_sections=1 |
| 2 | Attempt: `INSERT INTO ... VALUES (1, 1, 1, NULL, 0)` | Constraint violation: section_id null with applies_to_all_sections=0 |
| 3 | Attempt: `INSERT INTO ... VALUES (1, 1, 1, NULL, 1)` | Succeeds (all sections) |
| 4 | Attempt: `INSERT INTO ... VALUES (1, 1, 1, 1, 0)` | Succeeds (specific section) |

---

#### TC-D15: Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a TT via `store()` | Activity log contains 'Stored' event with TT id, message, user |
| 2 | Update the TT via `update()` | Activity log contains 'Updated' event |
| 3 | Soft delete the TT via `destroy()` | Activity log contains 'Trashed' event |
| 4 | Restore via `restore()` | Activity log contains 'Restored' event |
| 5 | Force delete via `forceDelete()` | Activity log contains 'Deleted' event |
| 6 | Toggle status via `toggleStatus()` | Activity log contains 'Toggled' event with is_active value |

---

#### TC-D24: Integration \| P1 \| Controller — `findOrFail` — All Methods With Valid/Invalid IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `GET .../timetable-type/99999` | 404 Not Found |
| 2 | Call `GET .../timetable-type/99999/edit` | 404 Not Found |
| 3 | Call `PUT .../timetable-type/99999` | 404 Not Found |
| 4 | Call `DELETE .../timetable-type/99999` | 404 Not Found |
| 5 | Call `GET .../timetable-type/99999/restore` | 404 Not Found |
| 6 | Call `DELETE .../timetable-type/99999/force-delete` | 404 Not Found |
| 7 | Call `POST .../timetable-type/99999/toggle-status` | 404 Not Found |
| 8 | Repeat for CTT routes | Same 404 behavior |

---

#### TC-D33: Integration \| P1 \| TimetableType model — Global Scope `ordered`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 TTs with ordinals 3, 1, 2 | TTs exist |
| 2 | Query `TimetableType::get()` | Results ordered by ordinal: 1, 2, 3 |
| 3 | Query `TimetableType::withoutGlobalScope('ordered')->get()` | Results in insertion order (not forced by ordinal) |
