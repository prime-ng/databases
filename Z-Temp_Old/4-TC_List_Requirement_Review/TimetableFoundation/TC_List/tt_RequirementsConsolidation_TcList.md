# tt_RequirementsConsolidation_TcList

## Module: TimetableFoundation → Timetable Requirement → Requirement Consolidation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Requirement |
| Feature | Requirement Consolidation |
| URL(s) | `GET /timetable-foundation/timetable-requirement?tab=requirement-consolidations` (main screen via `TimetableFoundationController@timetableRequirement`) |
| | `GET /timetable-foundation/requirement-consolidation` (index redirect) |
| | `GET /timetable-foundation/requirement-consolidation/create` (create form) |
| | `POST /timetable-foundation/requirement-consolidation` (store) |
| | `GET /timetable-foundation/requirement-consolidation/{id}` (show) |
| | `GET /timetable-foundation/requirement-consolidation/{id}/edit` (edit form) |
| | `PUT /timetable-foundation/requirement-consolidation/{id}` (update) |
| | `DELETE /timetable-foundation/requirement-consolidation/{id}` (destroy) |
| | `POST /timetable-foundation/requirement-consolidation/generate-requirements/generate` (generateRequirements) |
| | `POST /timetable-foundation/requirement-consolidation/{rc}/toggle-status` (toggleStatus) |
| | `POST /timetable-foundation/requirement-consolidation/ajax/inline-update/{id}` (ajaxInlineUpdate) |
| | `POST /timetable-foundation/class-subject-requirement/update` (updateRequirement) |
| | `POST /timetable-foundation/class-subject-requirement/update-periods` (updatePeriods) |
| | `GET /timetable-foundation/requirement-consolidations/stats` (getRequirementsStats) |
| | `GET /timetable-foundation/requirement-consolidation/trash/view` (trashed) |
| | `GET /timetable-foundation/requirement-consolidation/{id}/restore` (restore) |
| | `DELETE /timetable-foundation/requirement-consolidation/{id}/force-delete` (forceDelete) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\RequirementConsolidationController` (1219 lines); main grid loaded by `TimetableFoundationController@timetableRequirement` (line 412-431) |
| Model(s) | `Modules\TimetableFoundation\Models\RequirementConsolidation` (table: `tt_requirement_consolidations`) |
| Validation (Create) | Inline in `RequirementConsolidationController@store()` — no dedicated Form Request class |
| Validation (Update) | Inline in `RequirementConsolidationController@update()` — no dedicated Form Request class |
| Policy | `Modules\TimetableFoundation\Policies\RequirementConsolidationPolicy` |
| Permissions | `timetable-foundation.requirement-consolidation.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | All records loaded via `->get()`; grouped in-memory by class+section; no DB-level pagination |
| Soft Deletes | Yes (`SoftDeletes` trait on Model) |
| Read-Only | No — inline editing, generate, create, update, delete all available |

---

## 2. Pre-conditions

- Required permissions: `timetable-foundation.requirement-consolidation.viewAny`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`
- Required seed data:
  - At least one active `AcademicTerm` (from `sch_academic_term`)
  - At least one active `TimetableType` (from `tt_timetable_types`)
  - At least one active `ClassSubjectGroup` record with `sch_class_groups_jnt` parent
  - At least one active `ClassSubjectSubgroup` record with `sch_class_groups_jnt` parent
  - Related entities: `SchoolClass`, `Section`, `Subject`, `StudyFormat`, `SubjectType`, `SubjectStudyFormat`, `Room`, `RoomType`
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For Generate Requirements tests: Pre-existing active `ClassSubjectGroup` and `ClassSubjectSubgroup` records with valid foreign key references
- For inline editing tests: At least one existing `tt_requirement_consolidations` record
- For soft-delete tests: At least one existing record that can be deleted and restored

---

## 3. Default Data Load

The screen loads via `TimetableFoundationController@timetableRequirement()` (`GET /timetable-foundation/timetable-requirement?tab=requirement-consolidations`). All requirement consolidation records are loaded with eager-loaded relationships and then filtered/grouped in-memory.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Academic Terms | `timetableRequirement()` | `AcademicTerm::orderByDesc('is_current')->orderBy('term_start_date')->get()` | None | None |
| Shared: Timetable Types | `timetableRequirement()` | `TimetableType::where('is_active', true)->orderBy('ordinal')->get()` | `is_active=1` | None |
| Shared: Filter Classes | `timetableRequirement()` | Pre-loaded from SchoolSetup | `is_active` | None |
| Shared: Filter Sections | `timetableRequirement()` | Pre-loaded from SchoolSetup | `is_active` | None |
| Shared: Filter Subjects | `timetableRequirement()` | Pre-loaded from SchoolSetup | `is_active` | None |
| Requirement Consolidation Grid | `timetableRequirement()` | `RequirementConsolidation::with('academicTerm','timetableType','class','section','subject','studyFormat','subjectType','subjectStudyFormat','requiredRoomType','requiredRoom')->get()` | `rc_class_id`, `rc_section_id`, `rc_subject_id`, `rc_compulsory` | None (all records returned, grouped by class+section) |

> **Data Source:** Requirement Consolidation records originate from the `generateRequirements()` process, which reads `ClassSubjectGroup` (compulsory) and `ClassSubjectSubgroup` (optional) records and creates one consolidation row per subject-study-format combination.

---

## 4. Test Data Strategy

- **Generate test data**: Use the "Generate Requirements" form on the screen by selecting an Academic Term and Timetable Type. Alternatively, insert records directly into `tt_requirement_consolidations` with proper FK references.
- **Group vs Subgroup XOR**: Ensure test data covers both `class_requirement_group_id` populated (with `class_requirement_subgroup_id = NULL`) and `class_requirement_subgroup_id` populated (with `class_requirement_group_id = NULL`), as enforced by the `chk_cgr_target` CHECK constraint.
- **Compulsory/Optional split**: Create records with `is_compulsory = 1` (group-sourced) and `is_compulsory = 0` (subgroup-sourced) to test the inner tab split.
- **Unique combination**: The UNIQUE KEY is `(academic_term_id, timetable_type_id, class_requirement_group_id, class_requirement_subgroup_id)`. Since group/subgroup are XOR, this effectively means one consolidation per (term, type, group) or (term, type, subgroup).
- **Pre-test cleanup**: Delete created records by ID after tests to avoid unique key collisions.
- **Cross-module data requirements**: Need `ClassSubjectGroup`, `ClassSubjectSubgroup`, and their parent `sch_class_groups_jnt` records with scheduling columns populated (e.g., `required_weekly_periods`, `min_weekly_periods`, `max_weekly_periods`, `priority_score`, etc.) to test data inheritance during generation.
- **Room requirement data**: Create `RoomType` and `Room` records to test `compulsory_specific_room_type`, `required_room_type_id`, and `required_room_id` fields.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_requirement_consolidations`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | academic_term_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_academic_term.id` ON DELETE SET NULL |
| BC-DB-03 | timetable_type_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_timetable_types.id` ON DELETE SET NULL |
| BC-DB-04 | class_requirement_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt.id` ON DELETE CASCADE |
| BC-DB-05 | class_requirement_subgroup_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups.id` ON DELETE CASCADE |
| BC-DB-06 | class_id | INT UNSIGNED | NOT NULL |
| BC-DB-07 | section_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-08 | subject_id | INT UNSIGNED | NOT NULL |
| BC-DB-09 | study_format_id | INT UNSIGNED | NOT NULL |
| BC-DB-10 | subject_type_id | INT UNSIGNED | NOT NULL |
| BC-DB-11 | subject_study_format_id | INT UNSIGNED | NOT NULL |
| BC-DB-12 | class_house_room_id | INT UNSIGNED | NOT NULL |
| BC-DB-13 | student_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-14 | eligible_teacher_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-15 | is_compulsory | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-16 | required_weekly_periods | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-17 | min_periods_required_per_week | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-18 | max_periods_required_per_week | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-19 | min_periods_required_per_day | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-20 | max_periods_required_per_day | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-21 | min_gap_between_periods | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-22 | required_consecutive_periods | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-23 | min_required_consecutive_periods | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-24 | allow_consecutive_periods | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-25 | max_consecutive_periods | TINYINT UNSIGNED | DEFAULT 2 |
| BC-DB-26 | class_priority_score | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-27 | preferred_periods_json | JSON | DEFAULT NULL |
| BC-DB-28 | avoid_periods_json | JSON | DEFAULT NULL |
| BC-DB-29 | spread_evenly | TINYINT(1) | DEFAULT 1 |
| BC-DB-30 | is_shared_across_sections | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-31 | is_shared_across_classes | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-32 | compulsory_specific_room_type | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-33 | required_room_type_id | INT UNSIGNED | NOT NULL |
| BC-DB-34 | required_room_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-35 | is_active | TINYINT(1) UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-36 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-37 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-38 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-39 | UNIQUE KEY | `(academic_term_id, timetable_type_id, class_requirement_group_id, class_requirement_subgroup_id)` | Unique combination |
| BC-DB-40 | CHECK | `chk_cgr_target` | XOR: group_id IS NOT NULL AND subgroup_id IS NULL, OR vice versa |

### 5.2 Validation Rules — `store()` (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | class_group_id | nullable, integer, exists:tt_class_groups_jnt,id | — |
| BC-VAL-02 | class_subgroup_id | nullable, integer, exists:tt_class_requirement_subgroups,id | — |
| BC-VAL-03 | academic_session_id | nullable, integer, exists:global_master_mysql.glb_academic_sessions,id | — |
| BC-VAL-04 | weekly_periods | required, integer, min:1 | — |
| BC-VAL-05 | min_periods_per_week | nullable, integer, min:0 | — |
| BC-VAL-06 | max_periods_per_week | nullable, integer, min:0 | — |
| BC-VAL-07 | min_per_day | nullable, integer, min:0 | — |
| BC-VAL-08 | max_per_day | nullable, integer, min:0 | — |
| BC-VAL-09 | min_gap_periods | nullable, integer, min:0 | — |
| BC-VAL-10 | allow_consecutive | nullable, boolean | — |
| BC-VAL-11 | max_consecutive | nullable, integer, min:1 | — |
| BC-VAL-12 | preferred_periods_json | nullable, json | — |
| BC-VAL-13 | avoid_periods_json | nullable, json | — |
| BC-VAL-14 | priority | nullable, integer, min:1, max:100 | — |
| BC-VAL-15 | is_active | nullable (converted to boolean) | — |
| BC-VAL-16 | **XOR check (controller)** | Must pass exactly one of class_group_id or class_subgroup_id | "Select either a class group or a class subgroup (not both)." |
| BC-VAL-17 | **Weekly min ≤ max (controller)** | min_periods_required_per_week ≤ max_periods_required_per_week | "Minimum weekly periods cannot exceed maximum." |
| BC-VAL-18 | **Daily min ≤ max (controller)** | min_periods_required_per_day ≤ max_periods_required_per_day | "Minimum daily periods cannot exceed maximum." |
| BC-VAL-19 | **Duplicate check (controller)** | No existing record with same (class_group_id, class_subgroup_id, academic_session_id) | "A requirement for this target and academic session already exists." |
| BC-VAL-20 | **Consecutive logic (controller)** | If allow_consecutive is false, max_consecutive is forced to 1 | — |

### 5.3 Validation Rules — `update()` (Update via edit form)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | class_id | nullable, integer | — |
| BC-VAL-U02 | section_id | nullable, integer | — |
| BC-VAL-U03 | subject_id | nullable, integer | — |
| BC-VAL-U04 | study_format_id | nullable, integer | — |
| BC-VAL-U05 | subject_type_id | nullable, integer | — |
| BC-VAL-U06 | subject_study_format_id | nullable, integer | — |
| BC-VAL-U07 | class_house_room_id | nullable, integer | — |
| BC-VAL-U08 | academic_term_id | nullable, integer | — |
| BC-VAL-U09 | timetable_type_id | nullable, integer | — |
| BC-VAL-U10 | student_count | nullable, integer, min:0 | — |
| BC-VAL-U11 | eligible_teacher_count | nullable, integer, min:0 | — |
| BC-VAL-U12 | is_compulsory | nullable, boolean | — |
| BC-VAL-U13 | required_weekly_periods | nullable, integer, min:0 | — |
| BC-VAL-U14 | min_periods_required_per_week | nullable, integer, min:0 | — |
| BC-VAL-U15 | max_periods_required_per_week | nullable, integer, min:0 | — |
| BC-VAL-U16 | min_periods_required_per_day | nullable, integer, min:0 | — |
| BC-VAL-U17 | max_periods_required_per_day | nullable, integer, min:0 | — |
| BC-VAL-U18 | min_gap_between_periods | nullable, integer, min:0 | — |
| BC-VAL-U19 | allow_consecutive_periods | nullable, boolean | — |
| BC-VAL-U20 | max_consecutive_periods | nullable, integer, min:1 | — |
| BC-VAL-U21 | required_consecutive_periods | nullable, integer, min:0 | — |
| BC-VAL-U22 | min_required_consecutive_periods | nullable, integer, min:0 | — |
| BC-VAL-U23 | class_priority_score | nullable, integer, min:0, max:100 | — |
| BC-VAL-U24 | preferred_periods_json | nullable, string (JSON decoded in controller) | — |
| BC-VAL-U25 | avoid_periods_json | nullable, string (JSON decoded in controller) | — |
| BC-VAL-U26 | spread_evenly | nullable, boolean | — |
| BC-VAL-U27 | shared_scope | nullable, in:none,section,class | — |
| BC-VAL-U28 | compulsory_specific_room_type | nullable, boolean | — |
| BC-VAL-U29 | required_room_type_id | nullable, integer | — |
| BC-VAL-U30 | required_room_id | nullable, integer | — |
| BC-VAL-U31 | is_active | nullable, boolean | — |
| BC-VAL-U32 | **JSON decode** | preferred_periods_json / avoid_periods_json strings decoded to arrays | — |
| BC-VAL-U33 | **shared_scope conversion** | 'none' → both false, 'section' → is_shared_across_sections=true, 'class' → is_shared_across_classes=true | — |
| BC-VAL-U34 | **Non-nullable safeguard** | required_room_type_id/required_room_id not unset when null is submitted | — |

### 5.4 Validation Rules — `ajaxInlineUpdate()`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-A01 | field | string, must be in editable whitelist | "Field not editable." (422) |
| BC-VAL-A02 | value | cast to boolean for boolean fields, int for others | — |

Editable whitelist: `required_weekly_periods`, `min_periods_required_per_week`, `max_periods_required_per_week`, `min_periods_required_per_day`, `max_periods_required_per_day`, `min_gap_between_periods`, `allow_consecutive_periods`, `max_consecutive_periods`, `class_priority_score`, `spread_evenly`, `is_compulsory`, `is_shared_across_sections`, `is_shared_across_classes`, `compulsory_specific_room_type`, `student_count`, `eligible_teacher_count`, `is_active`.

### 5.5 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | timetable-foundation.requirement-consolidation.viewAny | index() | Without → 403 |
| BC-AUTH-02 | timetable-foundation.requirement-consolidation.view | show() | Without → 403 |
| BC-AUTH-03 | timetable-foundation.requirement-consolidation.create | create(), store() | Without → 403 |
| BC-AUTH-04 | timetable-foundation.requirement-consolidation.update | edit(), update(), toggleStatus(), updatePeriods(), updateRequirement(), ajaxInlineUpdate() | Without → 403 |
| BC-AUTH-05 | timetable-foundation.requirement-consolidation.delete | destroy() | Without → 403 |
| BC-AUTH-06 | timetable-foundation.requirement-consolidation.restore | trashedClassGroupRequirement(), restore() | Without → 403 |
| BC-AUTH-07 | timetable-foundation.requirement-consolidation.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | timetable-foundation.requirement-consolidation.generate | generateRequirements() | Without → 403 |
| BC-AUTH-09 | Guest access (no session) | Any method | Redirect to /login |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `?tab=requirement-consolidations` | Requirement Consolidation tab pane is active; Compulsory tab is default active inner tab |
| BC-BIZ-02 | Generate Requirements with valid term + type | All existing consolidations truncated; new records upserted from ClassSubjectGroups + ClassSubjectSubgroups |
| BC-BIZ-03 | Generate with no active groups or subgroups | Warning message: "No active class groups or subgroups found to generate requirements." |
| BC-BIZ-04 | Generate from ClassSubjectGroup | Record created with `class_requirement_group_id` set, `class_requirement_subgroup_id = NULL`, `is_compulsory = true` |
| BC-BIZ-05 | Generate from ClassSubjectSubgroup | Record created with `class_requirement_subgroup_id` set, `class_requirement_group_id = NULL`, `is_compulsory` inherited from parent |
| BC-BIZ-06 | Record sourcing from group | Group fields inherited: subject info, room info, period rules, priority from parent `schClassGroup` |
| BC-BIZ-07 | Record sourcing from subgroup | Subgroup fields inherited: subject info, room info, period rules, priority from parent `schClassGroup`, plus sharing flags from subgroup |
| BC-BIZ-08 | Inline edit numeric field | On blur with changed value → POST to ajaxInlineUpdate → field updated in DB → success flash on input |
| BC-BIZ-09 | Inline edit boolean field (checkbox) | On change → POST to ajaxInlineUpdate → value cast to boolean → DB updated |
| BC-BIZ-10 | Inline edit invalid field | Field not in whitelist → 422 "Field not editable." |
| BC-BIZ-11 | toggleStatus with is_active=true | Record is_active set to true; JSON response with success |
| BC-BIZ-12 | toggleStatus with is_active=false | Record is_active set to false; JSON response with success |
| BC-BIZ-13 | destroy (soft delete) | Record `is_active` set to false, then soft-deleted (`deleted_at` set) |
| BC-BIZ-14 | restore from trash | Record restored; `is_active` set to true |
| BC-BIZ-15 | forceDelete from trash | Record permanently removed from DB |
| BC-BIZ-16 | Filter by rc_class_id | Grid shows only records matching the selected class |
| BC-BIZ-17 | Filter by rc_section_id | Grid shows only records matching the selected section |
| BC-BIZ-18 | Filter by rc_subject_id | Grid shows only records matching the selected subject |
| BC-BIZ-19 | Filter by rc_compulsory=1 | Grid shows only compulsory records |
| BC-BIZ-20 | Filter by rc_compulsory=0 | Grid shows only optional records |
| BC-BIZ-21 | Compulsory tab display | Only records with `is_compulsory = true` shown; grouped by class-section with accordion |
| BC-BIZ-22 | Optional tab display | Only records with `is_compulsory = false` shown; grouped by class-section with accordion |
| BC-BIZ-23 | Accordion expand/collapse | Clicking class-section header expands/collapses subject rows; siblings collapse when one opens |
| BC-BIZ-24 | Empty state (no data) | "No compulsory requirements found." / "No optional requirements found." with inbox icon |
| BC-BIZ-25 | Export Excel | Downloads Excel file with current requirement consolidation data |
| BC-BIZ-26 | Total badge | Shows total count of all consolidation records |
| BC-BIZ-27 | Compulsory badge | Shows count of compulsory records |
| BC-BIZ-28 | Optional badge | Shows count of optional records |
| BC-BIZ-29 | Class-section header shows sum | Displays `required_weekly_periods` sum for the class-section as "N wk periods" |
| BC-BIZ-30 | updateRequirement AJAX | Updates `required_weekly_periods`, `class_priority_score`, shared scope flags, `is_active` in one call |
| BC-BIZ-31 | updateRequirement shared_scope validation | Only one shared scope can be enabled at a time (mutual exclusivity) |
| BC-BIZ-32 | updatePeriods AJAX | Updates `preferred_periods_json` or `avoid_periods_json` based on `type` parameter |
| BC-BIZ-33 | Activity log on destroy | Log entry created with event 'Trashed' and message about deactivation |
| BC-BIZ-34 | Activity log on forceDelete | Log entry created with event 'Deleted' |
| BC-BIZ-35 | Activity log on restore | Log entry created with event 'Restored' |
| BC-BIZ-36 | Activity log on toggleStatus | Log entry created with event 'Toggled' and is_active status |
| BC-BIZ-37 | Inline save visual feedback | Input briefly shows green border (class `rc-saved`) for 1.5s after successful save |
| BC-BIZ-38 | Accordion chevron rotation | Chevron rotates -90deg when collapsed, 0deg when expanded |
| BC-BIZ-39 | Screen loads via TimetableFoundationController@timetableRequirement at GET /timetable-foundation/timetable-requirement with tab=requirement-consolidations | Navigating to the URL with appropriate permissions loads all shared dropdowns and the consolidation grid |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_term_id | sch_academic_term (id) | SET NULL |
| BC-REF-02 | timetable_type_id | tt_timetable_types (id) | SET NULL |
| BC-REF-03 | class_requirement_group_id | sch_class_groups_jnt (id) | CASCADE |
| BC-REF-04 | class_requirement_subgroup_id | tt_class_requirement_subgroups (id) | CASCADE |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Requirement Consolidation Tab Loads With All UI Elements | Tab loads with Generate Requirements form (term + type selects), Compulsory/Optional inner tabs, Export Excel button, Total/Compulsory/Optional badges, filter dropdowns (Class, Section, Subject, Comp/Opt), and accordion table | — | — | ⬜ |
| TC-P02 | Generate Requirements Creates Records From Class Subject Groups | After selecting term + type and clicking Generate, system: truncates existing records, processes all active ClassSubjectGroups, creates consolidation records with `class_requirement_group_id` set; displays success message with group/subgroup counts | — | — | ⬜ |
| TC-P03 | Generate Requirements Creates Records From Class Subject Subgroups | After generation, optional records appear under Optional tab with `class_requirement_subgroup_id` set, `is_compulsory` inherited from parent | — | — | ⬜ |
| TC-P04 | Generate Requirements Shows Warning When No Active Data | When no active ClassSubjectGroup or ClassSubjectSubgroup exists, generation shows warning: "No active class groups or subgroups found to generate requirements." | — | — | ⬜ |
| TC-P05 | Generate Requirements Confirmation Dialog | Clicking Generate triggers JavaScript confirmation: "This will replace ALL existing requirement consolidations. Continue?" | — | — | ⬜ |
| TC-P06 | Compulsory Tab Shows Only Compulsory Records | After generation, Compulsory tab displays only records where `is_compulsory = true`, grouped by class-section | — | — | ⬜ |
| TC-P07 | Optional Tab Shows Only Optional Records | Optional tab displays only records where `is_compulsory = false`, grouped by class-section | — | — | ⬜ |
| TC-P08 | Accordion Expand/Collapse Per Class-Section | Clicking class-section header row expands/collapses its subject rows; sibling groups collapse when a new one opens | — | — | ⬜ |
| TC-P09 | Inline Edit Required Weekly Periods | Changing value in "Wk Req" input and pressing Enter or tabbing away → value saved via AJAX → input briefly shows green border | — | — | ⬜ |
| TC-P10 | Inline Edit Min Periods Per Week | Changing Min/Wk value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P11 | Inline Edit Max Periods Per Week | Changing Max/Wk value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P12 | Inline Edit Min Periods Per Day | Changing Min/Day value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P13 | Inline Edit Max Periods Per Day | Changing Max/Day value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P14 | Inline Edit Min Gap Between Periods | Changing Gap value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P15 | Inline Toggle Allow Consecutive Periods (Checkbox) | Toggling Consec. checkbox → saved via AJAX → value cast to boolean → green flash on parent | — | — | ⬜ |
| TC-P16 | Inline Edit Max Consecutive Periods | Changing Max Con. value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P17 | Inline Edit Priority Score | Changing Priority value → saved via AJAX → green flash confirmation | — | — | ⬜ |
| TC-P18 | Inline Toggle Spread Evenly (Checkbox) | Toggling Spread checkbox → saved via AJAX → green flash on parent | — | — | ⬜ |
| TC-P19 | Inline Toggle Active Status (Checkbox) | Toggling Active checkbox → saved via AJAX → green flash on parent; record deactivated/activated accordingly | — | — | ⬜ |
| TC-P20 | Filter By Class | Selecting a class from the Class filter dropdown and submitting → grid shows only records for that class | — | — | ⬜ |
| TC-P21 | Filter By Section | Selecting a section from Section filter → grid shows only records for that section | — | — | ⬜ |
| TC-P22 | Filter By Subject | Selecting a subject from Subject filter → grid shows only records for that subject | — | — | ⬜ |
| TC-P23 | Filter By Compulsory Status (All/Compulsory/Optional) | Selecting "Compulsory" → grid shows only compulsory records; selecting "Optional" → only optional records | — | — | ⬜ |
| TC-P24 | Reset Filters | Clicking reset (rotate-left icon) → all filters cleared → all records displayed | — | — | ⬜ |
| TC-P25 | Export Excel | Clicking Export Excel → Excel file downloaded with all requirement consolidation data | — | — | ⬜ |
| TC-P26 | Badge Counts Update Correctly | Total badge = sum of Compulsory + Optional badge counts; counts reflect filtered results | — | — | ⬜ |
| TC-P27 | Class-Section Header Shows Total Weekly Periods | Each accordion header displays sum of `required_weekly_periods` for that class-section as "N wk periods" | — | — | ⬜ |
| TC-P28 | Toggle Status Via Dedicated Endpoint | POST to toggle-status with is_active=true/false → record status updated → JSON success response | — | — | ⬜ |
| TC-P29 | Delete (Soft) Requirement Consolidation | Clicking delete → record `is_active` set to false → soft-deleted → redirected with success flash | — | — | ⬜ |
| TC-P30 | View Trashed Records | Navigating to trash view → only soft-deleted records shown ordered by `deleted_at` DESC | — | — | ⬜ |
| TC-P31 | Restore From Trash | Clicking restore on a trashed record → record restored → `is_active` set to true → redirected with success flash | — | — | ⬜ |
| TC-P32 | Force Delete From Trash | Clicking force delete → record permanently removed → redirected with success flash | — | — | ⬜ |
| TC-P33 | Update Requirement Via AJAX (updateRequirement) | POST with id, required_weekly_periods, class_priority_score, shared_scope → all specified fields updated → JSON success | — | — | ⬜ |
| TC-P34 | Update Periods Via AJAX (updatePeriods) | POST with id, type=preferred, periods array → preferred_periods_json updated; POST with type=avoid → avoid_periods_json updated | — | — | ⬜ |
| TC-P35 | Full Lifecycle: Generate → Inline Edit → Toggle Status → Soft Delete → Restore | Complete workflow: generate records → edit a field inline → toggle active status → soft delete → view trash → restore → verify record is active again | — | — | ⬜ |
| TC-P36 | Generate With Same Term+Type After Changes | Re-generating with same term+type replaces all records (truncate + re-create) with current ClassSubjectGroup/Subgroup data | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Generate Without Academic Term | Form validation rejects; "Please select an academic term." | — | — | ⬜ |
| TC-N02 | Generate Without Timetable Type | Form validation rejects; "Please select a timetable type." | — | — | ⬜ |
| TC-N03 | Generate With Invalid Academic Term | Validation rejects; "Selected academic term is invalid." | — | — | ⬜ |
| TC-N04 | Generate With Invalid Timetable Type | Validation rejects; "Selected timetable type is invalid." | — | — | ⬜ |
| TC-N05 | Inline Edit With Non-Editable Field | POST with field not in whitelist → 422 "Field not editable." | — | — | ⬜ |
| TC-N06 | Inline Edit With Invalid Value Type | Sending string for integer field → value cast to int (0) or fails validation | — | — | ⬜ |
| TC-N07 | Create With Both Group And Subgroup | Submitting both class_group_id and class_subgroup_id → error "Select either a class group or a class subgroup (not both)." | — | — | ⬜ |
| TC-N08 | Create With Neither Group Nor Subgroup | Submitting without either → error "Select either a class group or a class subgroup (not both)." | — | — | ⬜ |
| TC-N09 | Create Duplicate Combination | Creating with same (class_group_id/subgroup_id, academic_session_id) → error "A requirement for this target and academic session already exists." | — | — | ⬜ |
| TC-N10 | Create With Min > Max Weekly Periods | Submitting min_periods_per_week > max_periods_per_week → error "Minimum weekly periods cannot exceed maximum." | — | — | ⬜ |
| TC-N11 | Create With Min > Max Daily Periods | Submitting min_per_day > max_per_day → error "Minimum daily periods cannot exceed maximum." | — | — | ⬜ |
| TC-N12 | View Without ViewAny Permission | User lacking `viewAny` → 403 | — | — | ⬜ |
| TC-N13 | Create Without Create Permission | User lacking `create` → 403 | — | — | ⬜ |
| TC-N14 | Update Without Update Permission | User lacking `update` → 403 | — | — | ⬜ |
| TC-N15 | Delete Without Delete Permission | User lacking `delete` → 403 | — | — | ⬜ |
| TC-N16 | Restore Without Restore Permission | User lacking `restore` → 403 | — | — | ⬜ |
| TC-N17 | Force Delete Without ForceDelete Permission | User lacking `forceDelete` → 403 | — | — | ⬜ |
| TC-N18 | Guest Attempts To Access Screen | Unauthenticated user → redirected to /login | — | — | ⬜ |
| TC-N19 | Delete Non-Existent Record | DELETE on invalid ID → 404 | — | — | ⬜ |
| TC-N20 | Generate Requirements With Truncate Error | If truncate fails (FK constraint), process halts with error message | — | — | ⬜ |
| TC-N21 | updateRequirement With Both Shared Scopes | Setting both is_shared_across_sections and is_shared_across_classes = true → 422 "Only one shared scope can be enabled at a time." | — | — | ⬜ |
| TC-N22 | Force Delete Non-Existent Record | DELETE force-delete on invalid ID → 404 | — | — | ⬜ |
| TC-N23 | Restore Non-Existent Record | GET restore on invalid ID → 404 | — | — | ⬜ |
| TC-N24 | UpdateRequirement With Invalid Priority | Sending priority > 100 → validation fails | — | — | ⬜ |
| TC-N25 | updatePeriods With Invalid Type | POST with type=invalid → validation fails | — | — | ⬜ |
| TC-N26 | Store With Weekly Periods = 0 | Sending weekly_periods = 0 → validation fails (min:1) | — | — | ⬜ |
| TC-N27 | Store With Negative Period Values | Sending negative values for period fields → validation fails (min:0) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Delete sch_class_groups_jnt record referenced by class_requirement_group_id | ON DELETE CASCADE → all related tt_requirement_consolidations records are deleted | — | — | ⬜ |
| TC-D02 | A | Delete tt_class_requirement_subgroups record referenced by class_requirement_subgroup_id | ON DELETE CASCADE → all related tt_requirement_consolidations records are deleted | — | — | ⬜ |
| TC-D03 | B | Delete sch_academic_term record referenced by academic_term_id | ON DELETE SET NULL → academic_term_id in requirement consolidations set to NULL | — | — | ⬜ |
| TC-D04 | B | Delete tt_timetable_types record referenced by timetable_type_id | ON DELETE SET NULL → timetable_type_id in requirement consolidations set to NULL | — | — | ⬜ |
| TC-D05 | C | UNIQUE constraint on (academic_term_id, timetable_type_id, class_requirement_group_id, class_requirement_subgroup_id) | INSERTing a duplicate combination → DB-level integrity violation error | — | — | ⬜ |
| TC-D06 | C | CHECK constraint chk_cgr_target — both group and subgroup NULL | INSERT with both NULL → constraint violation error | — | — | ⬜ |
| TC-D07 | C | CHECK constraint chk_cgr_target — both group and subgroup populated | INSERT with both non-NULL → constraint violation error | — | — | ⬜ |
| TC-D08 | D | Model $casts — boolean fields | `is_compulsory`, `allow_consecutive_periods`, `spread_evenly`, `is_shared_across_sections`, `is_shared_across_classes`, `compulsory_specific_room_type`, `is_active` all cast to boolean | — | — | ⬜ |
| TC-D09 | D | Model $casts — integer fields | All integer/tinyint fields cast to integer | — | — | ⬜ |
| TC-D10 | D | Model $casts — JSON fields | `preferred_periods_json`, `avoid_periods_json` cast to array | — | — | ⬜ |
| TC-D11 | E | Eloquent relationships — belongsTo academicTerm | `$rc->academicTerm` returns related AcademicTerm model or null | — | — | ⬜ |
| TC-D12 | E | Eloquent relationships — belongsTo timetableType | `$rc->timetableType` returns related TimetableType model or null | — | — | ⬜ |
| TC-D13 | E | Eloquent relationships — belongsTo class | `$rc->class` returns related SchoolClass model | — | — | ⬜ |
| TC-D14 | E | Eloquent relationships — belongsTo section | `$rc->section` returns related Section model or null | — | — | ⬜ |
| TC-D15 | E | Eloquent relationships — belongsTo subject | `$rc->subject` returns related Subject model | — | — | ⬜ |
| TC-D16 | E | Eloquent relationships — belongsTo classRequirementGroup | `$rc->classRequirementGroup` returns related SchClassGroupsJnt or null | — | — | ⬜ |
| TC-D17 | E | Eloquent relationships — belongsTo classRequirementSubgroup | `$rc->classRequirementSubgroup` returns related ClassRequirementSubgroup or null | — | — | ⬜ |
| TC-D18 | F | Controller findOrFail → 404 | Accessing show/edit/update/destroy with non-existent ID → ModelNotFoundException → 404 | — | — | ⬜ |
| TC-D19 | F | Policy gates on every controller method | Each controller method calls `Gate::authorize()` before execution | — | — | ⬜ |
| TC-D20 | G | Activity logging on all state changes | destroy, forceDelete, restore, toggleStatus all log activity with appropriate event type | — | — | ⬜ |
| TC-D21 | H | Route registration — resource routes | Route::resource registers all 7 resourceful methods for requirement-consolidation | — | — | ⬜ |
| TC-D22 | H | Route registration — custom routes | All custom routes (generate, toggle, trash, restore, forceDelete, inline-update, stats, update-periods, update-requirement) registered and accessible | — | — | ⬜ |
| TC-D23 | I | Scope `active()` | `RequirementConsolidation::active()` returns only records with `is_active = true` | — | — | ⬜ |
| TC-D24 | I | Scope `forTerm()` | `RequirementConsolidation::forTerm($id)` filters by academic_term_id | — | — | ⬜ |
| TC-D25 | I | Scope `forTimetableType()` | `RequirementConsolidation::forTimetableType($id)` filters by timetable_type_id | — | — | ⬜ |
| TC-D26 | J | SoftDeletes — `onlyTrashed()` scope | Trashed records appear only in `onlyTrashed()` query, not in normal queries | — | — | ⬜ |
| TC-D27 | J | Generate truncate bypasses soft delete | `generateRequirements()` uses `truncate()` which performs hard delete regardless of SoftDeletes | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable matches DDL columns | All 30+ columns in DDL are present in `$fillable` array; no extra columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts for booleans/integers/decimals/dates | Boolean fields, integer fields, JSON arrays, and datetime fields correctly cast | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `use SoftDeletes;` present, `deleted_at` column cast to datetime/null | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined (belongsTo per FK) | All belongsTo relationships defined: academicTerm, timetableType, class, section, subject, studyFormat, subjectType, subjectStudyFormat, classHouseRoom, requiredRoomType, requiredRoom, classRequirementGroup, classRequirementSubgroup | — | — | ◌ |
| TC-CR05 | CR | P2 | Controller — try-catch exception handling on write methods | `update()`, `updateRequirement()`, `updatePeriods()`, `generateRequirements()` have try-catch blocks; `store()`/`destroy()` do not | — | — | ◌ |
| TC-CR06 | CR | P2 | Controller — DB transactions on multi-step writes | `generateRequirements()` uses `DB::transaction()` for upsert operations | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Every public method calls `Gate::authorize()` with appropriate permission | — | — | ◌ |
| TC-CR08 | CR | P2 | Controller — activity logged on all state changes | `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` all call `activityLog()` | — | — | ◌ |
| TC-CR09 | CR | P2 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()` sets `is_active=false` before `delete()`; `restore()` sets `is_active=true` after `restore()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | `toggleStatus()` sets `is_active` from request value and saves | — | — | ◌ |
| TC-CR11 | CR | P2 | Controller — trash/restore/forceDelete flow (`onlyTrashed()`, `forceDelete()`) | `trashedClassGroupRequirement()` uses `onlyTrashed()`; `forceDelete()` uses `withTrashed()->findOrFail()` then `forceDelete()`; `restore()` uses `onlyTrashed()->findOrFail()` then `restore()` | — | — | ◌ |
| TC-CR12 | CR | P2 | Controller — JSON success response after create/update/delete (or flash messages) | Write operations redirect with flash messages; AJAX endpoints return JSON with `success: true/false` | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — validation rules cover all fields; cross-field checks | `store()` validates every input field; controller adds XOR check, min≤max checks, duplicate check | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all required methods defined; permission strings match route/gate names | Policy has viewAny, view, create, update, delete, restore, forceDelete; permission strings match `timetable-foundation.requirement-consolidation.*` | — | — | ◌ |
| TC-CR15 | CR | P2 | Routes — resource + custom routes registered; model binding 404s | Resource routes for RequirementConsolidation; custom routes for toggle, restore, forceDelete, generate, inline-update, stats, update-periods, update-requirement; implicit model binding on toggleStatus route parameter | — | — | ◌ |
| TC-CR16 | CR | P2 | View — Blade `@can` directives on tab/action buttons | Generate form guarded by `@can` check via `Route::has()`; Export button visible; inline editing enabled on all editable columns | — | — | ◌ |
| TC-CR17 | CR | P2 | View — `isset()`/null-safe checks for relationship variables | All relationship accesses in view use optional/null-safe patterns (`$rc->class?->name`, `$rc->studyFormat?->name`) | — | — | ◌ |
| TC-CR18 | CR | P3 | Breadcrumb — route registered in `config/breadcrumb.php` | Breadcrumb renders correct hierarchy for the screen | — | — | ◌ |
| TC-CR19 | CR | P2 | Database — unique indexes match request validation rules | UNIQUE KEY `uq_cgr_group_session` on (academic_term_id, timetable_type_id, class_requirement_group_id, class_requirement_subgroup_id) matches duplicate check in `store()` | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

#### TC-CR01: Model — $fillable Matches DDL Columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/TimetableFoundation/Models/RequirementConsolidation.php` | File exists |
| 2 | Compare `$fillable` array against DDL columns in `tt_requirement_consolidations` | Every DDL column is present in `$fillable`; no columns missing or extra |

#### TC-CR02: Model — $casts For Booleans/Integers/Decimals/Dates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the Model file | File exists |
| 2 | Verify `$casts` array includes `is_compulsory => boolean`, `allow_consecutive_periods => boolean`, `spread_evenly => boolean`, `is_shared_across_sections => boolean`, `is_shared_across_classes => boolean`, `compulsory_specific_room_type => boolean`, `is_active => boolean` | All boolean fields cast |
| 3 | Verify `$casts` includes `preferred_periods_json => array`, `avoid_periods_json => array` | JSON fields cast to array |
| 4 | Verify integer fields all cast to `integer` | All numeric fields have appropriate type casts |

#### TC-CR03: Model — SoftDeletes Trait
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the Model file | `use SoftDeletes;` present |
| 2 | Check `$casts` for `deleted_at` | `deleted_at => datetime` in casts |

#### TC-CR04: Model — Relationships Defined
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the Model file | All belongsTo relationships defined: academicTerm, timetableType, class, section, subject, studyFormat, subjectType, subjectStudyFormat, classHouseRoom, requiredRoomType, requiredRoom, classRequirementGroup, classRequirementSubgroup, classSubjectGroup, classSubjectSubgroup |

#### TC-CR05: Controller — Try-Catch Exception Handling
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the Controller file | `update()` has try-catch (lines 403-407) |
| 2 | Check `updateRequirement()` | Has try-catch (lines 832-837) |
| 3 | Check `updatePeriods()` | Has try-catch (lines 774-779) |
| 4 | Check `generateRequirements()` | Has try-catch (lines 963-972) |

#### TC-CR06: Controller — DB Transactions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Controller, inspect `generateRequirements()` | `DB::transaction()` wraps the processClassSubjectGroups + processClassSubjectSubgroups calls (line 935) |

#### TC-CR07: Controller — Gate::authorize() On Every Method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Controller and scan every public method | Each method calls `Gate::authorize('timetable-foundation.requirement-consolidation.<permission>')` before any logic |
| 2 | Verify methods: index, create, store, show, edit, update, destroy, trashedClassGroupRequirement, forceDelete, restore, toggleStatus, updatePeriods, updateRequirement, ajaxInlineUpdate, generateRequirements | All have Gate calls |

#### TC-CR08: Controller — Activity Logged On State Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Controller and search for `activityLog(` | Called in `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` |

#### TC-CR09: Controller — is_active Before Soft Delete / Restore Reactivates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `destroy()` method | Sets `$requirement->is_active = false` before `$requirement->delete()` (lines 635-638) |
| 2 | Check `restore()` method | Sets `$requirement->is_active = true` after `$requirement->restore()` (lines 696-697) |

#### TC-CR10: Controller — toggleStatus Flips is_active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `toggleStatus()` method | Sets `$classGroupRequirement->is_active = $request->boolean('is_active')` from request value (line 720) |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `trashedClassGroupRequirement()` | Uses `RequirementConsolidation::onlyTrashed()->orderByDesc('deleted_at')->paginate(10)` (lines 657-659) |
| 2 | Check `forceDelete()` | Uses `RequirementConsolidation::withTrashed()->findOrFail($id)` then `forceDelete()` (lines 670-672) |
| 3 | Check `restore()` | Uses `RequirementConsolidation::onlyTrashed()->findOrFail($id)` then `restore()` (line 691-693) |

#### TC-CR12: Controller — JSON/Flash Responses
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check write methods for flash messages | `store()`, `update()`, `destroy()`, `trashedClassGroupRequirement()`, `forceDelete()`, `restore()`, `generateRequirements()` all redirect with `->with('success', flash(...))` |
| 2 | Check AJAX methods for JSON responses | `toggleStatus()`, `updatePeriods()`, `updateRequirement()`, `ajaxInlineUpdate()` return `response()->json([...])` |

#### TC-CR13: Request — Validation Rules
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` validation rules array | All fields validated with appropriate rules (required, nullable, integer, min, max, boolean, json, exists) |
| 2 | Review controller-level checks | XOR group/subgroup check, weekly min≤max, daily min≤max, consecutive logic, duplicate check — all present |

#### TC-CR14: Policy — Methods And Permissions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Policy file | Methods defined: viewAny, view, create, update, delete, restore, forceDelete |
| 2 | Verify permission strings | All use `timetable-foundation.requirement-consolidation.*` pattern matching route names |

#### TC-CR15: Routes — Resource + Custom Registration
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open routes/web.php | `Route::resource('requirement-consolidation', ...)` present (line 252) |
| 2 | Verify custom routes | trash, restore, forceDelete, toggleStatus, generateRequirements, getRequirementsStats, updateRequirement, updatePeriods, ajaxInlineUpdate — all registered (lines 253-261) |

#### TC-CR16: View — Blade @can Directives
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `_list.blade.php` | Generate form visible based on `Route::has()` check (line 81); Export button always visible (line 24) |
| 2 | Check `_row.blade.php` | All inline inputs and checkboxes rendered without permission checks (all users with access can edit inline) |

#### TC-CR17: View — Null-Safe Checks
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `_row.blade.php` | Uses `$rc->subject?->name ?? '-'`, `$rc->studyFormat?->name ?? '-'` — null-safe operators present |
| 2 | Inspect `_list.blade.php` | Uses `$first->class?->name ?? 'Class ' . $first->class_id`, `$first->section?->name` — optional/null-safe |

#### TC-CR18: Breadcrumb Configuration
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `config/breadcrumb.php` in TimetableFoundation module | Route `timetable-foundation.menu.timetableRequirement` registered with correct breadcrumb hierarchy |

#### TC-CR19: Database — Unique Index Matches Validation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify UNIQUE KEY in DDL | `uq_cgr_group_session` on (`academic_term_id`, `timetable_type_id`, `class_requirement_group_id`, `class_requirement_subgroup_id`) exists |
| 2 | Verify duplicate check in `store()` | Controller checks for existing record with same (class_group_id, class_subgroup_id, academic_session_id) before insert (lines 229-240) |

---

### 7.1 Positive TC Steps

#### TC-P01: Requirement Consolidation Tab Loads With All UI Elements
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin user with all permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/timetable-requirement?tab=requirement-consolidations` | Page loads successfully |
| 3 | Verify the Requirement Consolidation tab pane is visible and active | Tab content displayed with id `requirement-consolidations-pane` has class `show active` |
| 4 | Verify Generate Requirements form is present | Form with Academic Term select, Timetable Type select, and "Generate Requirements" button visible |
| 5 | Verify filter dropdowns | Class, Section, Subject, Compulsory/Optional filter dropdowns visible |
| 6 | Verify badge counts | Total, Compulsory, Optional badges visible with counts |
| 7 | Verify Export Excel button | Button with "Export Excel" text visible |
| 8 | Verify inner tab pills | Compulsory and Optional nav-pill tabs visible |
| 9 | Verify accordion table | Table with headers: #, Subject, Format, Wk Req, Min/Wk, Max/Wk, Min/Day, Max/Day, Gap, Consec., Max Con., Priority, Spread, Active |

#### TC-P02: Generate Requirements Creates Records From Class Subject Groups
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 3 active ClassSubjectGroup records exist in DB with valid FK references | Records present |
| 2 | Navigate to Requirement Consolidation tab | Tab loads |
| 3 | Select an Academic Term from the dropdown | Term selected |
| 4 | Select a Timetable Type from the dropdown | Type selected |
| 5 | Click "Generate Requirements" | Confirmation dialog appears |
| 6 | Click OK on confirmation | Form submits |
| 7 | Wait for page reload | Page reloads |
| 8 | Verify success message | Flash message: "Requirements generated successfully: 3 groups, 0 subgroups (Total: 3)" |
| 9 | Verify Compulsory tab shows 3 records | Badge shows 3; accordion groups visible |
| 10 | Verify each record has `class_requirement_group_id` populated | View source or DB — group_id set, subgroup_id null |
| 11 | Verify each record has `is_compulsory = true` | All records in compulsory tab |

#### TC-P03: Generate Requirements Creates Records From Class Subject Subgroups
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 2 active ClassSubjectSubgroup records exist with `is_compulsory = false` | Records present |
| 2 | Generate requirements as in TC-P02 | Generation completes |
| 3 | Click the "Optional" tab | Optional tab shows; badge count = 2 |
| 4 | Verify each optional record has `class_requirement_subgroup_id` set | subgroup_id populated, group_id null |

#### TC-P04: Generate Requirements Shows Warning When No Active Data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Deactivate all ClassSubjectGroup and ClassSubjectSubgroup records | No active source data |
| 2 | Navigate to tab and click Generate with valid term + type | Confirmation → submit |
| 3 | Verify warning message | "No active class groups or subgroups found to generate requirements." |

#### TC-P05: Generate Requirements Confirmation Dialog
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Generate Requirements" without selecting term/type | HTML5 validation prevents submission |
| 2 | Select term and type, then click Generate | JavaScript confirmation dialog appears: "This will replace ALL existing requirement consolidations. Continue?" |
| 3 | Click "Cancel" | Form does not submit; no generation occurs |

#### TC-P06: Compulsory Tab Shows Only Compulsory Records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate with mixed compulsory and optional data | Data generated |
| 2 | Click the "Compulsory" tab | All visible records have `is_compulsory = true` |
| 3 | Count records | Matches badge count for Compulsory |

#### TC-P07: Optional Tab Shows Only Optional Records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click the "Optional" tab | All visible records have `is_compulsory = false` |
| 2 | Count records | Matches badge count for Optional |

#### TC-P08: Accordion Expand/Collapse Per Class-Section
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify first class-section header is expanded by default | Chevron points down; subject rows visible |
| 2 | Click on a different class-section header | Previously open group collapses; new group expands |
| 3 | Click the same header again | Group collapses; subject rows hidden |

#### TC-P09: Inline Edit Required Weekly Periods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a "Wk Req" input in the table | Input with class `rc-inline-num` and `data-field="required_weekly_periods"` |
| 2 | Note the current value | Value displayed |
| 3 | Change the value from e.g., 5 to 8 | Input value updated |
| 4 | Press Tab or click elsewhere | AJAX POST to `/requirement-consolidation/ajax/inline-update/{id}` |
| 5 | Verify green flash effect | Input briefly shows green border (`rc-saved` class added, removed after ~1.5s) |
| 6 | Reload the page | Value persists as 8 |

#### TC-P10 through TC-P14: Inline Edit Min/Max Weekly/Daily/Gap Fields
| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P10 | Locate Min/Wk input with `data-field="min_periods_required_per_week"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |
| TC-P11 | Locate Max/Wk input with `data-field="max_periods_required_per_week"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |
| TC-P12 | Locate Min/Day input with `data-field="min_periods_required_per_day"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |
| TC-P13 | Locate Max/Day input with `data-field="max_periods_required_per_day"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |
| TC-P14 | Locate Gap input with `data-field="min_gap_between_periods"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |

#### TC-P15: Inline Toggle Allow Consecutive Periods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a "Consec." checkbox in the table | Checkbox with class `rc-inline` and `data-field="allow_consecutive_periods"` |
| 2 | Toggle the checkbox from unchecked to checked | Checkbox becomes checked |
| 3 | Verify green flash effect | Parent element shows `rc-saved` class |
| 4 | Reload page | Checkbox remains checked |

#### TC-P16 through TC-P19: Edit Max Consecutive, Priority, Spread, Active
| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P16 | Locate Max Con. input with `data-field="max_consecutive_periods"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |
| TC-P17 | Locate Priority input with `data-field="class_priority_score"`, change value | Press Enter or tab away | AJAX POST saves value; green flash confirmation |
| TC-P18 | Locate Spread checkbox with `data-field="spread_evenly"`, toggle it | Checkbox changes state | AJAX POST saves boolean value; green flash on parent |
| TC-P19 | Locate Active checkbox with `data-field="is_active"`, toggle it | Checkbox changes state | AJAX POST saves boolean value; green flash on parent |

#### TC-P20: Filter By Class
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific class from the "Class" filter dropdown | Dropdown value set |
| 2 | Click the search (magnifying glass) button | Form submits with `rc_class_id` parameter |
| 3 | Verify grid shows only records matching the selected class | All visible records have matching `class_id` |

#### TC-P21: Filter By Section
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific section from the "Section" filter dropdown | Dropdown value set |
| 2 | Click search button | Form submits with `rc_section_id` parameter |
| 3 | Verify grid shows only matching records | All records have matching `section_id` |

#### TC-P22: Filter By Subject
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific subject from the "Subject" filter dropdown | Dropdown value set |
| 2 | Click search button | Form submits with `rc_subject_id` parameter |
| 3 | Verify grid shows only matching records | All records have matching `subject_id` |

#### TC-P23: Filter By Compulsory Status
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Compulsory" from the Comp/Opt filter | `rc_compulsory=1` |
| 2 | Click search | Only compulsory records shown |
| 3 | Select "Optional" from the filter | `rc_compulsory=0` |
| 4 | Click search | Only optional records shown |

#### TC-P24: Reset Filters
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class and subject filters | Grid filtered |
| 2 | Click the "Reset" button (rotate-left icon) | Page reloads with no filter parameters; all records displayed |

#### TC-P25: Export Excel
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Export Excel" button | Excel file downloaded with `.xlsx` extension |
| 2 | Open the downloaded file | Columns match the grid columns; data matches currently displayed records |

#### TC-P26: Badge Counts Update Correctly
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note Total, Compulsory, Optional badge counts | Numbers shown |
| 2 | Sum Compulsory + Optional | Equals Total count |

#### TC-P27: Class-Section Header Shows Total Weekly Periods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Expand a class-section accordion | Header shows "N wk periods" badge |
| 2 | Sum the `required_weekly_periods` values of all subject rows | Sum matches the badge number |

#### TC-P28: Toggle Status Via Dedicated Endpoint
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/requirement-consolidation/{id}/toggle-status` with `is_active=false` | Response JSON: `{"success":true,"is_active":false,"message":"...status_updated..."}` |
| 2 | Verify DB | `is_active` = 0 for the record |
| 3 | Send POST with `is_active=true` | Response JSON: success with `is_active=true` |

#### TC-P29: Delete (Soft) Requirement Consolidation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/requirement-consolidation/{id}` | Record deactivated and soft-deleted |
| 2 | Verify redirect | Redirected to `timetable-foundation.menu.timetablePreparation?tab=requirement-consolidation` with success flash |
| 3 | Query DB with `withTrashed()` | Record has `is_active = 0` and `deleted_at` timestamp |

#### TC-P30: View Trashed Records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /requirement-consolidation/trash/view` | Trash page loads with soft-deleted records |
| 2 | Verify ordering | Records ordered by `deleted_at` DESC |

#### TC-P31: Restore From Trash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash page, click "Restore" for a trashed record | Record restored |
| 2 | Verify DB | `deleted_at = NULL`, `is_active = true` |
| 3 | Verify redirect | Redirected with success flash |

#### TC-P32: Force Delete From Trash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash page, click "Force Delete" for a trashed record | Record permanently removed |
| 2 | Verify DB | Record no longer exists even with `withTrashed()` |
| 3 | Verify redirect | Redirected with success flash |

#### TC-P33: Update Requirement Via AJAX (updateRequirement)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/class-subject-requirement/update` with `{id: 1, required_weekly_periods: 10, class_priority_score: 75, shared_scope: "class"}` | JSON: `{"success":true,"message":"Requirement updated successfully","data":{...}}` |
| 2 | Verify DB | `required_weekly_periods = 10`, `class_priority_score = 75`, `is_shared_across_classes = true`, `is_shared_across_sections = false` |

#### TC-P34: Update Periods Via AJAX (updatePeriods)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/class-subject-requirement/update-periods` with `{id: 1, type: "preferred", periods: [1,3,5]}` | JSON: `{"success":true,"message":"Preferred periods updated successfully"}` |
| 2 | Verify DB | `preferred_periods_json` = `[1,3,5]` |
| 3 | Send POST with `type: "avoid", periods: [2,4]` | JSON: success; DB: `avoid_periods_json` = `[2,4]` |

#### TC-P35: Full Lifecycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate requirements as in TC-P02 | Records created |
| 2 | Inline edit a "Wk Req" field | Value saved via AJAX |
| 3 | Toggle "Active" checkbox to uncheck | Record deactivated |
| 4 | Navigate to tab and verify record is still visible but unchecked | Checkbox unchecked |
| 5 | Soft-delete the record via DELETE endpoint | Record moved to trash |
| 6 | Navigate to trash view | Record visible in trash |
| 7 | Restore the record | Record restored; active checkbox re-checked |

#### TC-P36: Generate With Same Term+Type After Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate requirements with Term A, Type A | N records created |
| 2 | Modify the source ClassSubjectGroup data (change periods) | Source data changed |
| 3 | Generate again with same Term A, Type A | Old records truncated; new records created with updated source data |

---

### 7.2 Negative TC Steps

#### TC-N01: Generate Without Academic Term
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave Academic Term dropdown unselected | Value empty |
| 2 | Select a Timetable Type | Value selected |
| 3 | Click Generate | HTML5 validation prevents submit or server returns error "Please select an academic term." |

#### TC-N02: Generate Without Timetable Type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select an Academic Term | Value selected |
| 2 | Leave Timetable Type unselected | Empty |
| 3 | Click Generate | Error: "Please select a timetable type." |

#### TC-N03: Generate With Invalid Academic Term
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Use browser tools to set `academic_term_id` to 99999 | Non-existent ID |
| 2 | Select valid Timetable Type | Value set |
| 3 | Submit form | Error: "Selected academic term is invalid." |

#### TC-N04: Generate With Invalid Timetable Type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select valid Academic Term | Value set |
| 2 | Set `timetable_type_id` to 99999 | Non-existent ID |
| 3 | Submit form | Error: "Selected timetable type is invalid." |

#### TC-N05: Inline Edit With Non-Editable Field
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/requirement-consolidation/ajax/inline-update/{id}` with `field: "academic_term_id", value: 5` | 422 response: "Field not editable." |

#### TC-N06: Inline Edit With Invalid Value Type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with `field: "required_weekly_periods", value: "abc"` | Value cast to 0; or server returns error |

#### TC-N07: Create With Both Group And Subgroup
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/requirement-consolidation` with both `class_group_id=1` and `class_subgroup_id=2` | Error: "Select either a class group or a class subgroup (not both)." |

#### TC-N08: Create With Neither Group Nor Subgroup
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/requirement-consolidation` with neither `class_group_id` nor `class_subgroup_id` | Error: "Select either a class group or a class subgroup (not both)." |

#### TC-N09: Create Duplicate Combination
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a record with specific (class_group_id, class_subgroup_id, academic_session_id) | Created successfully |
| 2 | Create another record with same combination | Error: "A requirement for this target and academic session already exists." |

#### TC-N10: Create With Min > Max Weekly Periods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `min_periods_per_week = 10, max_periods_per_week = 5` | Min > Max |
| 2 | Submit | Error: "Minimum weekly periods cannot exceed maximum." |

#### TC-N11: Create With Min > Max Daily Periods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `min_per_day = 8, max_per_day = 3` | Min > Max |
| 2 | Submit | Error: "Minimum daily periods cannot exceed maximum." |

#### TC-N12 through TC-N17: Permission Tests
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `viewAny` permission | 403 on index |
| 2 | Login as user without `create` permission | 403 on store/create |
| 3 | Login as user without `update` permission | 403 on edit/update/toggleStatus/updatePeriods/updateRequirement/ajaxInlineUpdate |
| 4 | Login as user without `delete` permission | 403 on destroy |
| 5 | Login as user without `restore` permission | 403 on restore/trashed |
| 6 | Login as user without `forceDelete` permission | 403 on forceDelete |

#### TC-N18: Guest Access Redirect
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | Session ended |
| 2 | Navigate to `/timetable-foundation/timetable-requirement?tab=requirement-consolidations` | Redirected to `/login` |

#### TC-N19: Delete Non-Existent Record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/requirement-consolidation/99999` | 404 error |

#### TC-N20: Generate Requirements With Truncate Error
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate FK constraint that prevents truncate (e.g., add a cross-table FK reference) | Not easily testable in UI |
| 2 | Covered by: Verify `generateRequirements()` disables FK checks before truncate with `SET FOREIGN_KEY_CHECKS=0` | Code review confirms FK check bypass |

#### TC-N21: updateRequirement With Both Shared Scopes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/class-subject-requirement/update` with `{id: 1, is_shared_across_sections: true, is_shared_across_classes: true}` | 422: "Only one shared scope can be enabled at a time." |

#### TC-N22: Force Delete Non-Existent Record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/requirement-consolidation/99999/force-delete` | 404 |

#### TC-N23: Restore Non-Existent Record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/requirement-consolidation/99999/restore` | 404 |

#### TC-N24: UpdateRequirement With Invalid Priority
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `class_priority_score: 150` | Validation fails (max:100) |

#### TC-N25: updatePeriods With Invalid Type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `type: "invalid"` | Validation fails (in:preferred,avoid) |

#### TC-N26: Store With Weekly Periods = 0
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `weekly_periods: 0` | Validation fails (min:1) |

#### TC-N27: Store With Negative Period Values
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with `weekly_periods: -5` | Validation fails (min:1) |

---

### 7.3 Dependency TC Steps

#### TC-D01: Cascade Delete — sch_class_groups_jnt Parent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a requirement consolidation with `class_requirement_group_id` referencing a valid `sch_class_groups_jnt` record | Record created |
| 2 | Note the record ID | Record exists |
| 3 | Delete the referenced `sch_class_groups_jnt` record | Cascade deletes the requirement consolidation |
| 4 | Verify requirement consolidation no longer exists | `find($id)` returns null |

#### TC-D02: Cascade Delete — tt_class_requirement_subgroups Parent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a requirement consolidation with `class_requirement_subgroup_id` referencing a valid subgroup | Record created |
| 2 | Delete the referenced subgroup | Cascade deletes the requirement consolidation |
| 3 | Verify record deleted | `find($id)` returns null |

#### TC-D03: SET NULL — sch_academic_term Parent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a requirement consolidation with a valid `academic_term_id` | Record with term_id set |
| 2 | Delete the referenced academic term | `academic_term_id` set to NULL |
| 3 | Verify the requirement consolidation still exists | `find($id)->academic_term_id` is null |

#### TC-D04: SET NULL — tt_timetable_types Parent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a requirement consolidation with a valid `timetable_type_id` | Record with type_id set |
| 2 | Delete the referenced timetable type | `timetable_type_id` set to NULL |
| 3 | Verify record still exists | `find($id)->timetable_type_id` is null |

#### TC-D05: UNIQUE Constraint Violation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a record with (term=X, type=Y, group=1, subgroup=NULL) | Success |
| 2 | Insert another record with same (term=X, type=Y, group=1, subgroup=NULL) | SQL integrity constraint violation |

#### TC-D06: CHECK Constraint — Both NULL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert record with both `class_requirement_group_id = NULL` and `class_requirement_subgroup_id = NULL` | CHECK constraint violation error |

#### TC-D07: CHECK Constraint — Both Populated
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert record with both `class_requirement_group_id = 1` and `class_requirement_subgroup_id = 1` | CHECK constraint violation error |

#### TC-D08: Model $casts — Boolean Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RequirementConsolidation.php` model | File exists |
| 2 | Check `$casts` array for `is_compulsory`, `allow_consecutive_periods`, `spread_evenly`, `is_shared_across_sections`, `is_shared_across_classes`, `compulsory_specific_room_type`, `is_active` | All cast as `boolean` |

#### TC-D09: Model $casts — Integer Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model `$casts` array | All tinyint/int fields cast as `integer` |

#### TC-D10: Model $casts — JSON Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model `$casts` array | `preferred_periods_json` and `avoid_periods_json` cast as `array` |

#### TC-D11: Eloquent Relationship — academicTerm
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In `tinker`, execute `$rc = RequirementConsolidation::with('academicTerm')->first()` | Returns record |
| 2 | Access `$rc->academicTerm` | Returns `AcademicTerm` model or null |

#### TC-D12: Eloquent Relationship — timetableType
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$rc->timetableType` | Returns `TimetableType` model or null |

#### TC-D13: Eloquent Relationship — class
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$rc->class` | Returns `SchoolClass` model |

#### TC-D14: Eloquent Relationship — section
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$rc->section` | Returns `Section` model or null |

#### TC-D15: Eloquent Relationship — subject
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$rc->subject` | Returns `Subject` model |

#### TC-D16: Eloquent Relationship — classRequirementGroup
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | For a group-sourced record, access `$rc->classRequirementGroup` | Returns `SchClassGroupsJnt` model |
| 2 | For a subgroup-sourced record, access `$rc->classRequirementGroup` | Returns null |

#### TC-D17: Eloquent Relationship — classRequirementSubgroup
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | For a subgroup-sourced record, access `$rc->classRequirementSubgroup` | Returns `ClassRequirementSubgroup` model |
| 2 | For a group-sourced record, access `$rc->classRequirementSubgroup` | Returns null |

#### TC-D18: Controller FindOrFail 404
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/requirement-consolidation/99999` | 404 response |
| 2 | Send GET to `/requirement-consolidation/99999/edit` | 404 response |
| 3 | Send PUT to `/requirement-consolidation/99999` | 404 response |

#### TC-D19: Policy Gates On Every Method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller: each public method's first line after docblock | Calls `Gate::authorize('timetable-foundation.requirement-consolidation.<perm>')` |

#### TC-D20: Activity Logging On State Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `activityLog(` calls | Present in `destroy()`, `forceDelete()`, `restore()`, `toggleStatus()` |
| 2 | Verify each call has appropriate event type | destroy → 'Trashed', forceDelete → 'Deleted', restore → 'Restored', toggleStatus → 'Toggled' |

#### TC-D21: Route Registration — Resource Routes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | `Route::resource('requirement-consolidation', RequirementConsolidationController::class)` present (line 252) |
| 2 | Run `php artisan route:list | grep requirement-consolidation` | All 7 resourceful routes listed: index, create, store, show, edit, update, destroy |

#### TC-D22: Route Registration — Custom Routes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list | grep requirement-consolidation` | Custom routes present: trashed, restore, forceDelete, toggleStatus, generateRequirements, getRequirementsStats, updateRequirement, updatePeriods, ajaxInlineUpdate |
| 2 | Verify route names match `timetable-foundation.requirement-consolidation.*` pattern | All names correctly prefixed |

#### TC-D23: Scope active()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In `tinker`, execute `RequirementConsolidation::active()->toSql()` | Query includes `WHERE is_active = 1` |

#### TC-D24: Scope forTerm()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In `tinker`, execute `RequirementConsolidation::forTerm(1)->toSql()` | Query includes `WHERE academic_term_id = 1` |

#### TC-D25: Scope forTimetableType()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In `tinker`, execute `RequirementConsolidation::forTimetableType(1)->toSql()` | Query includes `WHERE timetable_type_id = 1` |

#### TC-D26: SoftDeletes — onlyTrashed Scope
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a requirement consolidation record | `deleted_at` timestamp set |
| 2 | Query `RequirementConsolidation::all()` | Record not included |
| 3 | Query `RequirementConsolidation::onlyTrashed()->get()` | Record included |

#### TC-D27: Generate Truncate Bypasses Soft Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete some records (they have `deleted_at` set) | Records in trash |
| 2 | Run generateRequirements() | All records (including soft-deleted) permanently removed via truncate |
| 3 | Query `withTrashed()` | No records found (all truncated) |
