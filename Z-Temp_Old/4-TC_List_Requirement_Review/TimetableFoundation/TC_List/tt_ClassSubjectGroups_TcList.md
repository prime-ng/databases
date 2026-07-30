# tt_ClassSubjectGroups_TcList

## Module: TimetableFoundation → Timetable Requirement → Class Subject Groups & Subgroups

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Requirement |
| Feature | Class Subject Groups & Subgroups (includes Slot Requirements, Requirement Groups, Requirement Subgroups) |
| URL(s) | **Tab Page:** `GET /timetable-foundation/timetable-requirement?tab=class-subject-requirement` (Class Subject Requirement tab), `GET /timetable-foundation/timetable-requirement?tab=slot-requirements` (Slot Requirements tab) |
| | **Class Subject Subgroup Resource:** `GET|POST /timetable-foundation/class-subject-subgroup` (index/store), `GET /timetable-foundation/class-subject-subgroup/create` (create), `GET /timetable-foundation/class-subject-subgroup/{id}` (show), `GET|PUT|PATCH /timetable-foundation/class-subject-subgroup/{id}/edit` (edit/update), `DELETE /timetable-foundation/class-subject-subgroup/{id}` (destroy), `GET /timetable-foundation/class-subject-subgroup/trash/view` (trashed), `GET /timetable-foundation/class-subject-subgroup/{id}/restore` (restore), `DELETE /timetable-foundation/class-subject-subgroup/{id}/force-delete` (forceDelete), `POST /timetable-foundation/class-subject-subgroup/{class_subgroup}/toggle-status` (toggleStatus) |
| | **Class Subject Subgroup AJAX:** `GET /timetable-foundation/class-subject-subgroup/{class}/get/sections` (getSectionsByClass), `GET /timetable-foundation/class-subject-subgroup/list` (listSubgroups), `POST /timetable-foundation/class-subject-subgroup/ajax/toggle-sharing/{id}` (ajaxToggleSharing), `POST /timetable-foundation/class-subject-subgroup/generate` (generateClassSubgroups) |
| | **Slot Requirement Resource:** `GET|POST /timetable-foundation/slot-requirement` (index/store), `GET /timetable-foundation/slot-requirement/create` (create), `GET /timetable-foundation/slot-requirement/{id}` (show), `GET|PUT|PATCH /timetable-foundation/slot-requirement/{id}/edit` (edit/update), `DELETE /timetable-foundation/slot-requirement/{id}` (destroy), `POST /timetable-foundation/slot-requirement/{slot_availability}/toggle-status` (toggleStatus), `POST /timetable-foundation/slot-requirement/generate` (generateSlotRequirement) |
| Controller(s) | `Modules\TimetableFoundation\Http\Controllers\ClassSubjectSubgroupController` (688 lines) — Requirement Groups & Subgroups; `Modules\TimetableFoundation\Http\Controllers\SlotRequirementController` (408 lines) — Slot Requirements; Tab page loaded via `TimetableFoundationController@timetableRequirement()` |
| Model(s) | `Modules\TimetableFoundation\Models\ClassRequirementGroup` (table: `tt_class_requirement_groups`), `Modules\TimetableFoundation\Models\ClassRequirementSubgroup` (table: `tt_class_requirement_subgroups`), `Modules\TimetableFoundation\Models\SlotRequirement` (table: `tt_slot_requirements`) |
| Validation (Create) | ClassSubjectSubgroupController: inline `$request->validate()` in `store()` method; SlotRequirementController: inline `$request->validate()` in `store()` method |
| Validation (Update) | ClassSubjectSubgroupController: inline `$request->validate()` in `update()` method; SlotRequirementController: inline `$request->validate()` in `update()` method |
| Policy(ies) | `Modules\TimetableFoundation\Policies\ClassSubgroupPolicy` (Requirement Groups/Subgroups), `Modules\TimetableFoundation\Policies\SlotRequirementPolicy` (Slot Requirements) |
| Permissions | `timetable-foundation.class-subgroup.{viewAny,view,create,update,delete,restore,forceDelete}`; `timetable-foundation.slot-requirement.{viewAny,view,create,update,delete,restore,forceDelete}` |
| Pagination | Subgroup list via `listSubgroups()`: `20 records/page`; Slot Requirements: no pagination (accessed via tab page `timetableRequirement()`) |
| Soft Deletes | Yes — all 3 models use `SoftDeletes` trait |
| Data Source | Requirement Groups and Subgroups originate from `sch_class_groups_jnt` (SchoolSetup module); Slot Requirements generated from `tt_class_timetable_types_jnt` assignments |
| Activity Log | SlotRequirementController: `Deleted` after destroy, `Toggled` after toggleStatus; ClassSubjectSubgroupController: activity logging pattern not fully implemented in all methods |

---

## 2. Pre-conditions

- Required permissions (full set): `timetable-foundation.class-subgroup.*` and `timetable-foundation.slot-requirement.*` (viewAny/view/create/update/delete/restore/forceDelete for each)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Required seed data: At least one active `OrganizationAcademicSession` and `AcademicTerm` (for scoping)
- For Requirement Groups: At least one active `SchoolClass`, `Section`, `Subject`, `StudyFormat`, `SubjectType`, and `SubjectStudyFormatJnt` record in SchoolSetup
- For Requirement Subgroups: At least one existing Requirement Group record
- For Slot Requirements: At least one active `TimetableType` and `ClassTimetableTypeJnt` record with period set assigned
- For generation tests: At least one `PeriodSet` with `teaching_periods` set and active `SchoolDay` records
- For class-section filters: At least 2 active classes, each with at least 2 active sections
- For sharing toggle tests: At least one Requirement Subgroup record

---

## 3. Default Data Load

When the `timetable-requirement` tab page loads via `TimetableFoundationController@timetableRequirement()` (`GET /timetable-foundation/timetable-requirement`), the tab contains shared dropdowns and data grids for each sub-tab:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Academic Terms | `timetableRequirement()` | `AcademicTerm::active()->orderBy('term_name')` | `is_active` | None |
| Shared: Timetable Types | `timetableRequirement()` | `TimetableType::active()->get()` | `is_active` | None |
| Shared: Classes | `timetableRequirement()` | `SchoolClass::active()->orderBy('name')->get()` | `is_active` | None |
| Shared: Sections | `timetableRequirement()` | `Section::active()->orderBy('name')->get()` | `is_active` | None |
| Requirement Groups Grid | `timetableRequirement()` | `ClassRequirementGroup::with('class','section','subjectStudyFormat')` | `class_id`, `section_id`, `is_active` | None |
| Requirement Subgroups Grid | `listSubgroups()` | `ClassSubgroup::with('classGroup')->orderBy('created_at','desc')` | None | 20/page |
| Slot Requirements Grid | `timetableRequirement()` | `SlotRequirement::with('class','section','timetableType','classTimetableType')` | `academic_term_id`, `timetable_type_id`, `class_id`, `section_id`, `is_active` | None |

> **Data Source:** Requirement Groups/Subgroups originate from `sch_class_groups_jnt` in the SchoolSetup module. Slot Requirements are generated from `tt_class_timetable_types_jnt` assignments. All three tables are managed through TimetableFoundation.

---

## 4. Test Data Strategy

- **Unique identifier:** Append `now()->format('YmdHis')` as a suffix for subgroup codes/names to avoid unique constraint collisions
- **Date ranges:** Use a consistent academic term within the current academic session's date range
- **Pre-test cleanup:** Delete created requirement groups/subgroups and slot requirements by code/ID after each test; use `generateSlotRequirement()`'s destructive regeneration to reset slot data
- **Pagination overflow for subgroups:** Create 21+ subgroups to verify `paginate(20)` limit on `listSubgroups()` (20 per page, page 2 shows remaining records)
- **Cross-module data:** Ensure SchoolSetup has at least one `ClassGroupJnt` with `is_active=true` for subgroup creation; at least one `TimetableType` and `ClassTimetableTypeJnt` for slot requirement generation
- **Slot sum validation:** `weekly_total_slots` should equal `weekly_teaching_slots + weekly_exam_slots + weekly_free_slots` for `isValid()` tests
- **Class-section filter hierarchy:** Class → Section relationship must exist in `sch_class_section_jnt` for AJAX endpoints to return data

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_class_requirement_groups`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | code | CHAR(50) | NOT NULL, UNIQUE `uq_clsReqGroups_code` |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | class_group_id | INT UNSIGNED | NOT NULL, FK → `sch_class_groups(id)` |
| BC-DB-05 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes(id)` ON DELETE RESTRICT |
| BC-DB-06 | section_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_sections(id)` ON DELETE RESTRICT |
| BC-DB-07 | subject_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_subjects(id)` |
| BC-DB-08 | study_format_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_study_formats(id)` |
| BC-DB-09 | subject_type_id | INT UNSIGNED | NOT NULL, FK → `sch_subject_types(id)` ON DELETE RESTRICT |
| BC-DB-10 | subject_study_format_id | INT UNSIGNED | NOT NULL, FK → `sch_subject_study_format_jnt(id)` ON DELETE RESTRICT |
| BC-DB-11 | class_house_room_id | INT UNSIGNED | NOT NULL, FK → `sch_rooms(id)` |
| BC-DB-12 | required_room_type_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms_type(id)` ON DELETE RESTRICT |
| BC-DB-13 | required_room_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms(id)` ON DELETE RESTRICT |
| BC-DB-14 | student_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-15 | eligible_teacher_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-16 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-17 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-18 | created_at | TIMESTAMP | NULL |
| BC-DB-19 | updated_at | TIMESTAMP | NULL |
| BC-DB-20 | **UNIQUE KEY** | — | `uq_clsReqGroups_code` on (`code`) |
| BC-DB-21 | **UNIQUE KEY** | — | `uq_clsReqGroups_class_section_subjectType` on (`class_id`, `section_id`, `subject_study_format_id`) |

### 5.2 Database Schema — `tt_class_requirement_subgroups`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-22 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-23 | code | VARCHAR(50) | NOT NULL, UNIQUE `uq_subgroup_code` |
| BC-DB-24 | name | VARCHAR(100) | NOT NULL |
| BC-DB-25 | class_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt(id)` ON DELETE SET NULL |
| BC-DB-26 | class_id | INT UNSIGNED | NOT NULL |
| BC-DB-27 | section_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-28 | subject_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-29 | study_format_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-30 | subject_type_id | INT UNSIGNED | NOT NULL |
| BC-DB-31 | subject_study_format_id | INT UNSIGNED | NOT NULL |
| BC-DB-32 | class_house_room_id | INT UNSIGNED | NOT NULL |
| BC-DB-33 | student_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-34 | eligible_teacher_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-35 | is_shared_across_sections | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-36 | is_shared_across_classes | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-37 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-38 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-39 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-40 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-41 | **UNIQUE KEY** | — | `uq_subgroup_code` on (`code`) |
| BC-DB-42 | **UNIQUE KEY** | — | `uq_classGroup_subStdFmt_class_section_subjectType` on (`class_id`, `section_id`, `subject_study_format_id`) |

### 5.3 Database Schema — `tt_slot_requirements`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-43 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-44 | academic_term_id | INT UNSIGNED | NOT NULL, FK → `sch_academic_term(id)` |
| BC-DB-45 | timetable_type_id | INT UNSIGNED | NOT NULL, FK → `tt_timetable_types(id)` |
| BC-DB-46 | class_timetable_type_id | INT UNSIGNED | NOT NULL, FK → `tt_class_timetable_types_jnt(id)` |
| BC-DB-47 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes(id)` |
| BC-DB-48 | section_id | INT UNSIGNED | NOT NULL, FK → `sch_sections(id)` |
| BC-DB-49 | class_house_room_id | INT UNSIGNED | NOT NULL, FK → `sch_rooms(id)` |
| BC-DB-50 | weekly_total_slots | TINYINT UNSIGNED | NOT NULL, 1–8 |
| BC-DB-51 | weekly_teaching_slots | TINYINT UNSIGNED | NOT NULL, 1–8 |
| BC-DB-52 | weekly_exam_slots | TINYINT UNSIGNED | NOT NULL, 1–8 |
| BC-DB-53 | weekly_free_slots | TINYINT UNSIGNED | NOT NULL, 1–8 |
| BC-DB-54 | activity_id | INT UNSIGNED | NULL, FK → `tt_activities(id)` |
| BC-DB-55 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-56 | **UNIQUE KEY** | — | `uq_sa_class_section` on (`timetable_type_id`, `class_timetable_type_id`, `class_id`, `section_id`) |

### 5.4 Validation Rules — `ClassSubjectSubgroupController@store()` (Create Subgroup)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | class_group_id | required, exists:sch_class_groups,id | Default Laravel messages |
| BC-VAL-02 | code | required, string, max:50, unique:tt_class_requirement_subgroups,code | Default Laravel messages |
| BC-VAL-03 | name | required, string, max:150 | Default Laravel messages |
| BC-VAL-04 | description | nullable, string, max:255 | Default Laravel messages |
| BC-VAL-05 | subgroup_type | required, in:SUBGROUP_TYPES (enum from ClassSubgroup model) | Default Laravel messages |
| BC-VAL-06 | min_students | nullable, integer, min:1 | Default Laravel messages |
| BC-VAL-07 | max_students | nullable, integer, min:1, gte:min_students | Default Laravel messages |
| BC-VAL-08 | is_shared_across_sections | boolean | Default Laravel messages |
| BC-VAL-09 | is_shared_across_classes | boolean | Default Laravel messages |
| BC-VAL-10 | is_active | boolean | Default Laravel messages |
| BC-VAL-11 | members | required, array, min:1 | Default Laravel messages |
| BC-VAL-12 | members.*.class_id | required, exists:sch_classes,id | Default Laravel messages |
| BC-VAL-13 | members.*.section_id | nullable, exists:sch_sections,id | Default Laravel messages |
| BC-VAL-14 | members.*.is_active | boolean | Default Laravel messages |
| BC-VAL-15 | primary_member | required, integer, min:0 | Default Laravel messages |

### 5.5 Validation Rules — `ClassSubjectSubgroupController@update()` (Update Subgroup)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | name | required, string, max:150 | Default Laravel messages |
| BC-VAL-U02 | description | nullable, string, max:255 | Default Laravel messages |
| BC-VAL-U03 | is_shared_across_sections | boolean | Default Laravel messages |
| BC-VAL-U04 | is_shared_across_classes | boolean | Default Laravel messages |
| BC-VAL-U05 | is_active | boolean | Default Laravel messages |

### 5.6 Validation Rules — `ClassSubjectSubgroupController@ajaxToggleSharing()` (AJAX)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-16 | mode | required, in:none,sections,classes | Default Laravel messages |

### 5.7 Validation Rules — `SlotRequirementController@store()` (Create / UpdateOrCreate)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-17 | timetable_type_id | required, exists:tt_timetable_types,id | Default Laravel messages |
| BC-VAL-18 | class_timetable_type_id | required, exists:tt_class_timetable_types_jnt,id | Default Laravel messages |
| BC-VAL-19 | class_id | required, exists:sch_classes,id | Default Laravel messages |
| BC-VAL-20 | section_id | required, exists:sch_sections,id | Default Laravel messages |
| BC-VAL-21 | weekly_total_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-22 | weekly_teaching_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-23 | weekly_exam_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-24 | weekly_free_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-25 | daily_slots_distribution_json | nullable, array | Default Laravel messages |
| BC-VAL-26 | daily_slots_distribution_json.* | nullable, integer, min:0, max:99 | Default Laravel messages |

### 5.8 Validation Rules — `SlotRequirementController@update()` (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U06 | weekly_total_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-U07 | weekly_teaching_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-U08 | weekly_exam_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-U09 | weekly_free_slots | required, integer, min:0 | Default Laravel messages |
| BC-VAL-U10 | daily_slots_distribution_json | nullable, array | Default Laravel messages |
| BC-VAL-U11 | daily_slots_distribution_json.* | nullable, integer, min:0, max:99 | Default Laravel messages |

### 5.9 Validation Rules — `SlotRequirementController@toggleStatus()` (AJAX)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-27 | is_active | required, boolean | Default Laravel messages |

### 5.10 Validation Rules — `SlotRequirementController@generateSlotRequirement()` (Generation)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-28 | academic_term_id | required, exists:sch_academic_term,id | Default Laravel messages |
| BC-VAL-29 | timetable_type_id | required, exists:tt_timetable_types,id | Default Laravel messages |

### 5.11 Authorization — Class Subject Subgroup

| BC ID | Permission | Controller Methods | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `timetable-foundation.class-subgroup.viewAny` | `index()`, `listSubgroups()`, `getSectionsByClass()`, `getSectionsWithClassGroups()`, `getSubgroupStats()` | Without → 403 Forbidden |
| BC-AUTH-02 | `timetable-foundation.class-subgroup.view` | `show()` | Without → 403 Forbidden |
| BC-AUTH-03 | `timetable-foundation.class-subgroup.create` | `create()`, `store()`, `generateClassSubgroups()` | Without → 403 Forbidden |
| BC-AUTH-04 | `timetable-foundation.class-subgroup.update` | `edit()`, `update()`, `ajaxToggleSharing()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-05 | `timetable-foundation.class-subgroup.delete` | `destroy()` | Without → 403 Forbidden |
| BC-AUTH-06 | `timetable-foundation.class-subgroup.restore` | `trashed()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-07 | `timetable-foundation.class-subgroup.forceDelete` | `forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-08 | `timetable-foundation.slot-requirement.viewAny` | `index()` | Without → 403 Forbidden |
| BC-AUTH-09 | `timetable-foundation.slot-requirement.view` | `show()` | Without → 403 Forbidden |
| BC-AUTH-10 | `timetable-foundation.slot-requirement.create` | `create()`, `store()`, `generateSlotRequirement()` | Without → 403 Forbidden |
| BC-AUTH-11 | `timetable-foundation.slot-requirement.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-12 | `timetable-foundation.slot-requirement.delete` | `destroy()` | Without → 403 Forbidden |
| BC-AUTH-13 | Guest access | All routes | Redirect to `/login` |

### 5.12 Business Logic — Requirement Groups & Subgroups

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Class Subject Requirement tab loads via `TimetableFoundationController@timetableRequirement()` at `GET /timetable-foundation/timetable-requirement?tab=class-subject-requirement` | Tab pane renders with class dropdown, section dropdown, subject filter, and data grids for both Requirement Groups and Subgroups |
| BC-BIZ-02 | Filter Requirement Groups by class_id | Grid filtered to show only groups belonging to the selected class |
| BC-BIZ-03 | Filter Requirement Groups by section_id | Grid filtered to show only groups for the selected section (or NULL = all sections) |
| BC-BIZ-04 | Requirement Group composite unique key | No two groups can share the same `(class_id, section_id, subject_study_format_id)` combination; uniqueness enforced at DB level |
| BC-BIZ-05 | Requirement Group code uniqueness | Each group must have a unique `code`; enforced at DB level by `uq_clsReqGroups_code` |
| BC-BIZ-06 | Requirement Subgroup composite unique key | No two subgroups can share the same `(class_id, section_id, subject_study_format_id)` combination; uniqueness enforced at DB level |
| BC-BIZ-07 | Requirement Subgroup code uniqueness | Each subgroup must have a unique `code`; enforced at DB level by `uq_subgroup_code` |
| BC-BIZ-08 | Subgroup editable fields limited | Only `name`, `description`, `is_shared_across_sections`, `is_shared_across_classes`, and `is_active` are editable via `update()`; all other fields are system-populated |
| BC-BIZ-09 | ajaxToggleSharing — mode=none sets both flags false | Setting mode to `none` sets `is_shared_across_sections=false` AND `is_shared_across_classes=false` |
| BC-BIZ-10 | ajaxToggleSharing — mode=sections sets sections flag | Setting mode to `sections` sets `is_shared_across_sections=true` and `is_shared_across_classes=false` |
| BC-BIZ-11 | ajaxToggleSharing — mode=classes sets classes flag | Setting mode to `classes` sets `is_shared_across_classes=true` and `is_shared_across_sections=false` |
| BC-BIZ-12 | ajaxToggleSharing — modes are mutually exclusive | Only one mode (none/sections/classes) can be active at a time; setting one clears the other; enforced by controller logic |
| BC-BIZ-13 | getSectionsByClass returns sections with capacity data | AJAX `GET /class-subject-subgroup/{class}/get/sections` returns JSON with `class` info and `sections[]` array containing `id`, `name`, `code`, `display_name`, `available_seats`, `capacity`, `current_students`, `class_section_id` |
| BC-BIZ-14 | getSectionsByClass returns 404 for inactive/non-existent class | If class not found or inactive, JSON `{success: false, message: "Class not found or inactive"}` with 404 status |
| BC-BIZ-15 | Subgroup store validates members array (min:1) | `create()` validates `members` as `required|array|min:1`; at least one member required |
| BC-BIZ-16 | Subgroup store creates ClassSubgroupMember records | For each member in `members` array, a `ClassSubgroupMember` record is created with `class_subgroup_id`, `class_id`, `section_id`, `is_primary` |
| BC-BIZ-17 | Subgroup store uses DB transaction | `create()` wraps subgroup + members creation in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()` |
| BC-BIZ-18 | Subgroup store auto-updates student_count | `updateStudentCount()` called after member creation to compute and update `student_count` from member count |
| BC-BIZ-19 | generateClassSubgroups only processes non-MAJOR types | Generation targets subject types `['MIN', 'OPT', 'ELE', 'ADD']` only; MAJOR subject types are excluded |
| BC-BIZ-20 | generateClassSubgroups uses configurable thresholds | Uses `minimum_student_required_for_class_subgroup` (default 10) and `maximum_student_required_for_class_subgroup` (default 25) from `tt_configs` |
| BC-BIZ-21 | generateClassSubgroups returns creation/update/skip counts | JSON response includes `newly_created`, `updated`, `skipped`, `total_processed`, and breakdown by subgroup type |
| BC-BIZ-22 | generateClassSubgroups respects mode — skip existing | If a subgroup already exists for a class group, it skips creation (or updates if config changed) |
| BC-BIZ-23 | Empty state — no subgroups exist | Subgroup grid shows "No records found" when no subgroups exist |
| BC-BIZ-24 | Empty state — no requirement groups exist | Requirement Groups grid shows "No records found" when no groups exist |
| BC-BIZ-25 | Screen loads via `TimetableFoundationController@timetableRequirement()` at `GET /timetable-foundation/timetable-requirement` with `tab=class-subject-requirement` | Navigating to the URL with appropriate permissions loads the Timetable Requirement page; the Class Subject Requirement tab pane is rendered and populated with data |

### 5.13 Business Logic — Slot Requirements

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-26 | Slot Requirements tab loads via `TimetableFoundationController@timetableRequirement()` at `GET /timetable-foundation/timetable-requirement?tab=slot-requirements` | Tab pane renders with academic term dropdown, timetable type dropdown, class/section filters, and Slot Requirements grid with columns for total/teaching/exam/free slots |
| BC-BIZ-27 | Slot Requirement unique combination | Only one record per `(timetable_type_id, class_timetable_type_id, class_id, section_id)`; enforced by `uq_sa_class_section` unique key |
| BC-BIZ-28 | Slot Requirement — `store()` uses `updateOrCreate` | `store()` calls `SlotRequirement::updateOrCreate()` keyed on unique combination, making it idempotent — creates if not exists, updates if exists |
| BC-BIZ-29 | Slot Requirement — `isValid()` validates slot sum | `$slotRequirement->isValid()` returns `true` when `weekly_total_slots === weekly_teaching_slots + weekly_exam_slots + weekly_free_slots` |
| BC-BIZ-30 | Slot Requirement — `hasTeachingSlots()` | Returns `true` when `weekly_teaching_slots > 0` |
| BC-BIZ-31 | Slot Requirement — `hasExamSlots()` | Returns `true` when `weekly_exam_slots > 0` |
| BC-BIZ-32 | Slot Requirement — `hasFreeSlots()` | Returns `true` when `weekly_free_slots > 0` |
| BC-BIZ-33 | `generateSlotRequirement()` — Pre-step deletes existing records | All existing `tt_slot_requirements` records for the given `academic_term_id + timetable_type_id` are deleted before regeneration |
| BC-BIZ-34 | `generateSlotRequirement()` — STEP 1 processes section-specific rows | Rows with `applies_to_all_sections = 0` from `tt_class_timetable_types_jnt` are processed individually; one record per class+section |
| BC-BIZ-35 | `generateSlotRequirement()` — STEP 2 handles class-level rows | Rows with `applies_to_all_sections = 1` are expanded to all sections via `sch_class_section_jnt` |
| BC-BIZ-36 | `generateSlotRequirement()` — Deduplication via `$handledSections` | Sections already processed in STEP 1 are skipped in STEP 2 to prevent duplicates |
| BC-BIZ-37 | `generateSlotRequirement()` — Slot calculation fallback | If `weekly_teaching_period_count` is not set, slots are computed as `teaching_periods × school_day_count` from the linked period set |
| BC-BIZ-38 | `generateSlotRequirement()` — Auto-computes `weekly_total_slots` | Total is computed as `teaching + exam + free` (sum of all slot types) |
| BC-BIZ-39 | `generateSlotRequirement()` — Redirect back with success message | On completion, redirects back with `->with('success', 'Slot availability generated successfully.')` |
| BC-BIZ-40 | Slot Requirement toggleStatus via AJAX | `toggleStatus()` validates `is_active` as required boolean; saves and returns JSON `{success, is_active, message}` |
| BC-BIZ-41 | Slot Requirement destroy with activity logging | `destroy()` calls `$slotRequirement->delete()` then logs activity with event 'Deleted' |
| BC-BIZ-42 | Slot Requirement uses `$timestamps = false` | The model sets `public $timestamps = false`; `created_at`/`updated_at` are not auto-managed |
| BC-BIZ-43 | Filter Slot Requirements by `academic_term_id` | Grid filtered to show only records for the selected academic term |
| BC-BIZ-44 | Filter Slot Requirements by `timetable_type_id` | Grid filtered to show only records for the selected timetable type |
| BC-BIZ-45 | Filter Slot Requirements by `class_id` | Grid filtered to show only records for the selected class |
| BC-BIZ-46 | Filter Slot Requirements by `section_id` | Grid filtered to show only records for the selected section |
| BC-BIZ-47 | Empty state — no slot requirements exist | Slot Requirements grid shows "No records found" when no slot requirements exist for the selected filters |

### 5.14 Referential Integrity — `tt_class_requirement_groups`

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | class_id | `sch_classes(id)` | RESTRICT |
| BC-REF-02 | section_id | `sch_sections(id)` | RESTRICT |
| BC-REF-03 | subject_type_id | `sch_subject_types(id)` | RESTRICT |
| BC-REF-04 | subject_study_format_id | `sch_subject_study_format_jnt(id)` | RESTRICT |
| BC-REF-05 | required_room_type_id | `sch_rooms_type(id)` | RESTRICT |
| BC-REF-06 | required_room_id | `sch_rooms(id)` | RESTRICT |

### 5.15 Referential Integrity — `tt_class_requirement_subgroups`

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-07 | class_group_id | `sch_class_groups_jnt(id)` | SET NULL |

### 5.16 Referential Integrity — `tt_slot_requirements`

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-08 | academic_term_id | `sch_academic_term(id)` | RESTRICT (InnoDB default) |
| BC-REF-09 | class_id | `sch_classes(id)` | RESTRICT (InnoDB default) |
| BC-REF-10 | section_id | `sch_sections(id)` | RESTRICT (InnoDB default) |
| BC-REF-11 | timetable_type_id | `tt_timetable_types(id)` | RESTRICT (InnoDB default) |
| BC-REF-12 | class_timetable_type_id | `tt_class_timetable_types_jnt(id)` | RESTRICT (InnoDB default) |
| BC-REF-13 | activity_id | `tt_activities(id)` | SET NULL (InnoDB default, nullable FK) |

> **Note:** Downstream tables that reference these entities include `tt_requirement_consolidations` (CASCADE on both `class_requirement_group_id` and `class_requirement_subgroup_id`), `tt_activities` (SET NULL on `class_subgroup_id`), and `tt_timetable_cells` (CASCADE on `class_subgroup_id`).

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Class Subject Requirement Tab Loads With All UI Elements | Tab pane loads with class dropdown, section dropdown, subject filter, requirement groups grid columns (Code, Name, Class, Section, Subject, Type, Status, Action), subgroup grid, and Create button | — | — | ⬜ |
| TC-P02 | Filter Requirement Groups By Class | Select a specific class from dropdown; grid shows only groups belonging to that class | — | — | ⬜ |
| TC-P03 | Filter Requirement Groups By Section | Select a specific section; grid shows only groups for that section (including NULL = all sections) | — | — | ⬜ |
| TC-P04 | Slot Requirements Tab Loads With All UI Elements | Tab pane loads with academic term dropdown, timetable type dropdown, class filter, section filter, filter/reset buttons, and data table with columns (#, Class, Section, Timetable Type, Total, Teaching, Exam, Free, Activity, Status, Action) | — | — | ⬜ |
| TC-P05 | Filter Slot Requirements By Academic Term | Select a specific academic term; grid shows only records for that term | — | — | ⬜ |
| TC-P06 | Filter Slot Requirements By Timetable Type | Select a specific timetable type; grid shows only records for that type | — | — | ⬜ |
| TC-P07 | Filter Slot Requirements By Class | Select a specific class; grid shows only records for that class | — | — | ⬜ |
| TC-P08 | Filter Slot Requirements By Section | Select a specific section; grid shows only records for that section | — | — | ⬜ |
| TC-P09 | Reset Filters On Slot Requirements Tab | Click reset button; all filters cleared; grid shows default (all records for active term/type) | — | — | ⬜ |
| TC-P10 | Create Slot Requirement With Required Fields | Fill academic_term_id, timetable_type_id, class_timetable_type_id, class_id, section_id, weekly_total_slots=8, weekly_teaching_slots=6, weekly_exam_slots=2, weekly_free_slots=0. Submit. Slot requirement created or updated (idempotent) with success message; redirect to tab | — | — | ⬜ |
| TC-P11 | Create Slot Requirement With All Fields | Same as TC-P10 + `daily_slots_distribution_json=[1,1,1,1,1,1,1,1]`. Record saved with daily distribution JSON stored | — | — | ⬜ |
| TC-P12 | View Slot Requirement Show Page | Click View action on a slot requirement; show page displays all fields: academic term, timetable type, class, section, slot counts, activity link, status badge | — | — | ⬜ |
| TC-P13 | Edit Slot Requirement Loads Pre-Filled Data | Click Edit action; edit form loads with existing values for all fields including school days configuration | — | — | ⬜ |
| TC-P14 | Update Slot Requirement Slot Counts | Change `weekly_teaching_slots` from 6 to 5 and `weekly_free_slots` from 0 to 1; submit update. Record updated; redirect to tab with success message | — | — | ⬜ |
| TC-P15 | Generate Slot Requirements From Class Timetable Types | Click "Generate Slot Requirements" button with selected academic term and timetable type. Records created for all class+timetable type combinations; existing records for this term+type are replaced; success message displayed | — | — | ⬜ |
| TC-P16 | Generate Slot Requirements — Section-Specific + Class-Level Expansion | When class timetable types include both section-specific (`applies_to_all_sections=0`) and class-level (`applies_to_all_sections=1`) rows, both types are processed; class-level rows expanded to all sections not already handled | — | — | ⬜ |
| TC-P17 | Toggle Slot Requirement Status Active → Inactive | Click status toggle on an active slot requirement; AJAX POST to `toggle-status`. Record becomes inactive; JSON response `{success: true, is_active: false}` | — | — | ⬜ |
| TC-P18 | Toggle Slot Requirement Status Inactive → Active | Click status toggle on an inactive slot requirement. Record becomes active; JSON response `{success: true, is_active: true}` | — | — | ⬜ |
| TC-P19 | Soft Delete Slot Requirement | Click Delete on a slot requirement. Record soft-deleted (deleted_at set). Redirect to tab with success message | — | — | ⬜ |
| TC-P20 | View Subgroup List Via AJAX | `GET /class-subject-subgroup/list` returns paginated subgroup list (20/page) with class group relations | — | — | ⬜ |
| TC-P21 | Subgroup List Pagination | Create 21+ subgroups; list shows 20 on page 1; page 2 shows remaining records | — | — | ⬜ |
| TC-P22 | getSectionsByClass AJAX Returns Sections | `GET /class-subject-subgroup/1/get/sections` returns JSON with `class` info (id, name, code) and `sections[]` array with capacity data | — | — | ⬜ |
| TC-P23 | ajaxToggleSharing — mode=none | POST `mode=none` to `ajax/toggle-sharing/{id}`. Both `is_shared_across_sections` and `is_shared_across_classes` set to false; JSON `{success: true, mode: "none"}` | — | — | ⬜ |
| TC-P24 | ajaxToggleSharing — mode=sections | POST `mode=sections` to `ajax/toggle-sharing/{id}`. `is_shared_across_sections=true`, `is_shared_across_classes=false`; JSON success | — | — | ⬜ |
| TC-P25 | ajaxToggleSharing — mode=classes | POST `mode=classes` to `ajax/toggle-sharing/{id}`. `is_shared_across_classes=true`, `is_shared_across_sections=false`; JSON success | — | — | ⬜ |
| TC-P26 | generateClassSubgroups — Auto-Generate For Non-MAJOR Types | POST to `class-subject-subgroup/generate` with valid config. Subgroups created for class groups with subject types MIN, OPT, ELE, ADD; JSON response with `newly_created`, `updated`, `skipped` counts; DB transaction commits | — | — | ⬜ |
| TC-P27 | generateClassSubgroups — Skip Existing Unchanged Subgroups | Run generation twice; second run reports skipped count for unchanged subgroups and possibly updated count for changed ones | — | — | ⬜ |
| TC-P28 | getSubgroupStats Returns Statistics | GET to stats endpoint returns JSON with `total_class_groups`, `non_major_class_groups`, `total_subgroups`, `active_subgroups`, `coverage_percentage` | — | — | ⬜ |
| TC-P29 | Slot Requirement — `isValid()` Returns True For Valid Sum | Create a slot requirement where total = teaching + exam + free; call `isValid()` returns true | — | — | ⬜ |
| TC-P30 | Slot Requirement — `hasTeachingSlots()` Returns True | Slot requirement with `weekly_teaching_slots > 0` returns true | — | — | ⬜ |
| TC-P31 | Slot Requirement — `hasExamSlots()` Returns True | Slot requirement with `weekly_exam_slots > 0` returns true | — | — | ⬜ |
| TC-P32 | Slot Requirement — `hasFreeSlots()` Returns True | Slot requirement with `weekly_free_slots > 0` returns true | — | — | ⬜ |
| TC-P33 | Empty State — No Requirement Groups Exist | When no requirement groups exist for applied filters, grid shows "No records found" | — | — | ⬜ |
| TC-P34 | Empty State — No Subgroups Exist | Subgroup grid shows "No records found" when no subgroups exist | — | — | ⬜ |
| TC-P35 | Empty State — No Slot Requirements Exist | When no slot requirements exist for applied filters, grid shows "No records found" | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Slot Requirement `timetable_type_id` | Validation error: "The timetable type id field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Slot Requirement `class_timetable_type_id` | Validation error: "The class timetable type id field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing Slot Requirement `class_id` | Validation error: "The class id field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing Slot Requirement `section_id` | Validation error: "The section id field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing Slot Requirement `weekly_total_slots` | Validation error: "The weekly total slots field is required." | — | — | ⬜ |
| TC-N06 | Required — Missing Slot Requirement `weekly_teaching_slots` | Validation error: "The weekly teaching slots field is required." | — | — | ⬜ |
| TC-N07 | Invalid — Slot Requirement `weekly_total_slots` Negative | Validation error: `weekly_total_slots` must be integer, min:0 | — | — | ⬜ |
| TC-N08 | Invalid — Slot Requirement Non-Existent `timetable_type_id` | Validation error: exists:tt_timetable_types,id | — | — | ⬜ |
| TC-N09 | Invalid — Slot Requirement Non-Existent `class_id` | Validation error: exists:sch_classes,id | — | — | ⬜ |
| TC-N10 | Duplicate — Slot Requirement Unique Combination | Creating a second slot requirement with same (timetable_type_id, class_timetable_type_id, class_id, section_id) overwrites via `updateOrCreate` (idempotent, not an error) | — | — | ⬜ |
| TC-N11 | DB Unique — Slot Requirement Direct Duplicate Insert | Direct DB INSERT of duplicate unique combination throws integrity constraint violation on `uq_sa_class_section` | — | — | ⬜ |
| TC-N12 | Required — Missing Subgroup Create `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N13 | Required — Missing Subgroup Create `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N14 | Required — Missing Subgroup Create `members` array | Validation error: "The members field is required." | — | — | ⬜ |
| TC-N15 | Required — Missing Subgroup Create `class_group_id` | Validation error: "The class group id field is required." | — | — | ⬜ |
| TC-N16 | Invalid — Subgroup Create `code` Duplicate | Validation error on unique:tt_class_requirement_subgroups,code | — | — | ⬜ |
| TC-N17 | Invalid — Subgroup Create `max_students < min_students` | Validation error: `max_students.gte` rule — max must be greater than or equal to min | — | — | ⬜ |
| TC-N18 | Invalid — Subgroup Create `subgroup_type` Not In Allowed Values | Validation error: `in` rule on `SUBGROUP_TYPES` | — | — | ⬜ |
| TC-N19 | Invalid — Subgroup Create Non-Existent `class_group_id` | Validation error: exists:sch_class_groups,id | — | — | ⬜ |
| TC-N20 | Invalid — Subgroup Create Members With Non-Existent `class_id` | Validation error: members.*.class_id exists:sch_classes,id | — | — | ⬜ |
| TC-N21 | Invalid — Subgroup Create `primary_member` Beyond Members Array | If `primary_member` index exceeds members array length, member creation may produce null primary; no validation catch — edge case | — | — | ⬜ |
| TC-N22 | Invalid — ajaxToggleSharing `mode` Not In Allowed Values | Validation error: `in:none,sections,classes` | — | — | ⬜ |
| TC-N23 | Invalid — ajaxToggleSharing Non-Existent Subgroup ID | POST to non-existent ID → 404 Not Found via `findOrFail` | — | — | ⬜ |
| TC-N24 | Invalid — generateSlotRequirement Missing `academic_term_id` | Validation error: "The academic term id field is required." | — | — | ⬜ |
| TC-N25 | Invalid — generateSlotRequirement Non-Existent `academic_term_id` | Validation error: exists:sch_academic_term,id | — | — | ⬜ |
| TC-N26 | generateClassSubgroups — No Non-MAJOR Class Groups Found | If no class groups with non-MAJOR subject types exist, JSON `{success: false, message: "No class groups found with non-MAJOR subject types."}` with 400 status | — | — | ⬜ |
| TC-N27 | getSectionsByClass — Non-Existent Class | `GET /class-subject-subgroup/99999/get/sections` → JSON `{success: false, message: "Class not found or inactive"}` with 404 | — | — | ⬜ |
| TC-N28 | Permission 403 — No `timetable-foundation.class-subgroup.viewAny` | User without viewAny permission → 403 Forbidden on accessing the tab page or list endpoints | — | — | ⬜ |
| TC-N29 | Permission 403 — No `timetable-foundation.class-subgroup.create` | User without create permission → 403 Forbidden on create/store/generate endpoints | — | — | ⬜ |
| TC-N30 | Permission 403 — No `timetable-foundation.class-subgroup.update` | User without update permission → 403 Forbidden on edit, update, toggleStatus, ajaxToggleSharing | — | — | ⬜ |
| TC-N31 | Permission 403 — No `timetable-foundation.class-subgroup.delete` | User without delete permission → 403 Forbidden on destroy | — | — | ⬜ |
| TC-N32 | Permission 403 — No `timetable-foundation.slot-requirement.viewAny` | User without viewAny permission → 403 Forbidden on slot requirements tab | — | — | ⬜ |
| TC-N33 | Permission 403 — No `timetable-foundation.slot-requirement.create` | User without create permission → 403 Forbidden on store and generateSlotRequirement | — | — | ⬜ |
| TC-N34 | Permission 403 — No `timetable-foundation.slot-requirement.update` | User without update permission → 403 Forbidden on edit, update, toggleStatus | — | — | ⬜ |
| TC-N35 | Permission 403 — No `timetable-foundation.slot-requirement.delete` | User without delete permission → 403 Forbidden on destroy | — | — | ⬜ |
| TC-N36 | Guest Access Redirect For All Routes | Unauthenticated user accessing any class-subject-subgroup or slot-requirement route → redirected to `/login` | — | — | ⬜ |
| TC-N37 | View/Edit/Update/Delete Slot Requirement With Invalid ID (404) | 404 Not Found via `findOrFail` for non-existent slot requirement IDs | — | — | ⬜ |
| TC-N38 | View/Edit/Update/Delete Subgroup With Invalid ID (404) | 404 Not Found for non-existent subgroup IDs | — | — | ⬜ |
| TC-N39 | ToggleStatus On Non-Existent Slot Requirement (404) | `POST /slot-requirement/99999/toggle-status` → 404 via implicit model binding | — | — | ⬜ |
| TC-N40 | generateSlotRequirement — Non-Existent timetable_type_id | Validation error: exists:tt_timetable_types,id | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Requirement Group — RESTRICT FK: Cannot Delete Class Referenced By Group | Deleting a `sch_classes` record that has requirement groups fails at DB level (FK RESTRICT) | — | — | ⬜ |
| TC-D02 | A | Requirement Group — RESTRICT FK: Cannot Delete Section Referenced By Group | Deleting a `sch_sections` record referenced by a requirement group fails (FK RESTRICT) | — | — | ⬜ |
| TC-D03 | A | Requirement Group — RESTRICT FK: Cannot Delete Subject Type In Use | Deleting a `sch_subject_types` record used by a requirement group fails (FK RESTRICT) | — | — | ⬜ |
| TC-D04 | A | Requirement Group — RESTRICT FK: Cannot Delete Subject Study Format In Use | Deleting a `sch_subject_study_format_jnt` record used by a requirement group fails (FK RESTRICT) | — | — | ⬜ |
| TC-D05 | B | Requirement Subgroup — SET NULL FK: Deleting Parent Class Group Sets group_id NULL | Deleting a `sch_class_groups_jnt` record referenced by a subgroup sets `class_group_id = NULL` in the subgroup table; subgroup persists with NULL link | — | — | ⬜ |
| TC-D06 | C | Requirement Group — Unique Composite Key Enforced At DB Level | Direct DB INSERT of duplicate (class_id, section_id, subject_study_format_id) combination throws integrity constraint violation on `uq_clsReqGroups_class_section_subjectType` | — | — | ⬜ |
| TC-D07 | C | Requirement Subgroup — Unique Composite Key Enforced At DB Level | Direct DB INSERT of duplicate (class_id, section_id, subject_study_format_id) throws integrity constraint violation on `uq_classGroup_subStdFmt_class_section_subjectType` | — | — | ⬜ |
| TC-D08 | D | Slot Requirement — Unique Key Enforced At DB Level | Direct DB INSERT of duplicate (timetable_type_id, class_timetable_type_id, class_id, section_id) throws integrity constraint violation on `uq_sa_class_section` | — | — | ⬜ |
| TC-D09 | E | generateSlotRequirement — Pre-Step Deletes All Existing Records For Term+Type | Running generation for term T, type TT deletes all existing `tt_slot_requirements` where `academic_term_id=T AND timetable_type_id=TT`; records for other terms/types remain untouched | — | — | ⬜ |
| TC-D10 | E | generateSlotRequirement — STEP 1 Section-Specific Processing | Rows with `applies_to_all_sections=0` create exactly one record per class+section; not expanded to other sections | — | — | ⬜ |
| TC-D11 | E | generateSlotRequirement — STEP 2 Class-Level Expansion | Rows with `applies_to_all_sections=1` expand to all sections of the class via `sch_class_section_jnt` | — | — | ⬜ |
| TC-D12 | E | generateSlotRequirement — Deduplication Prevents Double Processing | Sections already handled in STEP 1 are skipped in STEP 2; `$handledSections` tracker prevents duplicates across both steps | — | — | ⬜ |
| TC-D13 | E | generateSlotRequirement — Fallback Slot Calculation From Period Set | When `weekly_teaching_period_count` is not set on the class timetable type row, slots computed as `teaching_periods × school_day_count` from linked period set and active school days | — | — | ⬜ |
| TC-D14 | F | Requirement Group — Model $casts Verification | `is_active` cast to boolean; `student_count`, `eligible_teacher_count` cast to integer; `created_at`, `updated_at`, `deleted_at` cast to datetime | — | — | ⬜ |
| TC-D15 | G | Requirement Subgroup — Model $casts Verification | `is_shared_across_sections`, `is_shared_across_classes`, `is_active` cast to boolean; `student_count`, `eligible_teacher_count` cast to integer | — | — | ⬜ |
| TC-D16 | H | Slot Requirement — Model $casts Verification | `is_active` cast to boolean; all slot count fields cast to integer; `weekly_total_slots`, `weekly_teaching_slots`, `weekly_exam_slots`, `weekly_free_slots` cast to integer | — | — | ⬜ |
| TC-D17 | I | Slot Requirement — Model `$timestamps = false` | Model has `public $timestamps = false`; `created_at`/`updated_at` not auto-maintained by Eloquent; these columns must be explicitly set or have DB defaults | — | — | ⬜ |
| TC-D18 | J | Controller — try-catch Exception Handling On Subgroup `store()` | `store()` wraps creation in try-catch; on exception → `DB::rollBack()`, `return back()->withInput()->with('error', ...)` | — | — | ⬜ |
| TC-D19 | J | Controller — DB Transaction On Subgroup `store()` | `store()` uses `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()` for subgroup + members creation | — | — | ⬜ |
| TC-D20 | J | Controller — DB Transaction On Subgroup `update()` | `update()` uses `DB::beginTransaction()` / `DB::commit()` for subgroup data update | — | — | ⬜ |
| TC-D21 | J | Controller — try-catch On Subgroup `update()` Exception | On exception → `DB::rollBack()`, logs error via `Log::error()`, returns back with `->with('error', 'Failed to update subgroup. Please try again.')` | — | — | ⬜ |
| TC-D22 | K | Controller — try-catch On generateClassSubgroups | Wrapped in try-catch with `DB::rollBack()`; on exception returns JSON `{success: false, message: "Failed to generate subgroups. Please try again."}` | — | — | ⬜ |
| TC-D23 | L | Controller — `findOrFail` On Subgroup edit/update/show/destroy | Non-existent subgroup ID throws `ModelNotFoundException` → HTTP 404 for edit, update, show, destroy | — | — | ⬜ |
| TC-D24 | L | Controller — `findOrFail` On Slot Requirement edit/update/show/destroy | Non-existent slot requirement ID throws `ModelNotFoundException` → HTTP 404 for edit, update, show, destroy | — | — | ⬜ |
| TC-D25 | M | Controller — `Gate::authorize()` Called Before All Methods | Each public method in both controllers calls `Gate::authorize()` with correct permission string before any business logic | — | — | ⬜ |
| TC-D26 | N | Controller — Activity Logged On Slot Requirement State Changes | `destroy()` calls `activityLog()` with event 'Deleted'; `toggleStatus()` calls `activityLog()` with event 'Toggled' | — | — | ⬜ |
| TC-D27 | O | Policy — ClassSubgroupPolicy Defines All 7 Gates | Policy defines `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`; each delegates to `$user->can('timetable-foundation.class-subgroup.{action}')` | — | — | ⬜ |
| TC-D28 | O | Policy — SlotRequirementPolicy Defines All 7 Gates | Policy defines all 7 gates; each delegates to `$user->can('timetable-foundation.slot-requirement.{action}')` | — | — | ⬜ |
| TC-D29 | P | Routes — Class Subject Subgroup Resource + Custom Routes Registered | Routes: index, create, store, show, edit, update, destroy + trashed, restore, forceDelete, toggleStatus, getSectionsByClass, listSubgroups, ajaxToggleSharing, generateClassSubgroups | — | — | ⬜ |
| TC-D30 | P | Routes — Slot Requirement Resource + Custom Routes Registered | Routes: index, create, store, show, edit, update, destroy + toggleStatus, generateSlotRequirement | — | — | ⬜ |
| TC-D31 | Q | Requirement Group — ClassRelationshipGroup Model belongsTo Relationships | `class()` → belongsTo `SchClass`; `section()` → belongsTo `SchSection`; `subjectStudyFormat()` → belongsTo `SchSubjectStudyFormatJnt`; `classHouseRoom()` → belongsTo `SchRoom` | — | — | ⬜ |
| TC-D32 | R | Requirement Subgroup — ClassRequirementSubgroup Model belongsTo Relationships | `class()` → belongsTo `SchClass`; `section()` → belongsTo `SchSection`; `subjectStudyFormat()` → belongsTo `SubjectStudyFormat`; `classHouseRoom()` → belongsTo `SchRoom` | — | — | ⬜ |
| TC-D33 | S | Slot Requirement — SlotRequirement Model belongsTo Relationships | `timetableType()` → belongsTo `TimetableType`; `classTimetableType()` → belongsTo `ClassTimetableType`; `class()` → belongsTo `SchoolClass`; `section()` → belongsTo `Section`; `academicTerm()` → belongsTo `AcademicTerm` | — | — | ⬜ |
| TC-D34 | T | Slot Requirement — Model $fillable Matches DDL Columns | `$fillable` array contains: timetable_type_id, class_timetable_type_id, class_id, section_id, academic_term_id, activity_id, class_house_room_id, weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots, is_active; `id` and timestamps not fillable | — | — | ⬜ |
| TC-D35 | U | Requirement Group — Model $fillable Matches DDL Columns | `$fillable` contains: code, name, class_group_id, class_id, section_id, subject_id, study_format_id, subject_type_id, subject_study_format_id, class_house_room_id, student_count, eligible_teacher_count, is_active; all 13 writable columns present | — | — | ⬜ |
| TC-D36 | V | Requirement Subgroup — Model $fillable Matches DDL Columns | `$fillable` contains: code, name, class_group_id, class_id, section_id, subject_id, study_format_id, subject_type_id, subject_study_format_id, class_house_room_id, student_count, eligible_teacher_count, is_shared_across_sections, is_shared_across_classes, is_active; all 15 writable columns present | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for all 3 models (mass-assignment protection) | ClassRequirementGroup: 13 fillable columns match DDL; ClassRequirementSubgroup: 15 fillable columns match DDL; SlotRequirement: 12 fillable columns match DDL; `id`/`created_at`/`updated_at`/`deleted_at` not fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/dates on all 3 models | ClassRequirementGroup: `is_active` → boolean, all FK → integer; ClassRequirementSubgroup: `is_shared_across_sections`, `is_shared_across_classes`, `is_active` → boolean; SlotRequirement: `is_active` → boolean, all slot counts → integer | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented on all 3 models | All models use `SoftDeletes`; `deleted_at` column exists; `delete()` sets `deleted_at`; `onlyTrashed()`/`withTrashed()`/`restore()` work | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — Relationships defined per FK | ClassRequirementGroup: 4 belongsTo (class, section, subjectStudyFormat, classHouseRoom); ClassRequirementSubgroup: 4 belongsTo (class, section, subjectStudyFormat, classHouseRoom); SlotRequirement: 5 belongsTo (timetableType, classTimetableType, class, section, academicTerm) | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | ClassSubjectSubgroupController `store()`: try-catch with rollback; `update()`: try-catch with rollback; `generateClassSubgroups()`: try-catch with rollback; SlotRequirementController: minimal try-catch on store/update | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | ClassSubjectSubgroupController `store()`: DB transaction for subgroup + members; `update()`: DB transaction; `generateClassSubgroups()`: DB transaction for all generated subgroups; SlotRequirementController `store()`: no explicit transaction (single `updateOrCreate`) | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | ClassSubjectSubgroupController: every public method calls `Gate::authorize()` with `timetable-foundation.class-subgroup.{action}`; SlotRequirementController: every public method calls `Gate::authorize()` with `timetable-foundation.slot-requirement.{action}` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | SlotRequirementController `destroy()`: `activityLog()` with 'Deleted'; `toggleStatus()`: `activityLog()` with 'Toggled'; ClassSubjectSubgroupController: no explicit activity logging calls found in store/update/destroy methods | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | ClassSubjectSubgroupController `destroy()`: only calls `$subgroup->delete()`; no explicit `is_active=false` before delete (verify in implementation) | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | SlotRequirementController `toggleStatus()`: receives `is_active` boolean from request, sets on model, saves; returns JSON `{success, is_active, message}` | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | Both controllers define `trashed()`, `restore()`, `forceDelete()` custom routes; `restore()` uses `onlyTrashed()->findOrFail($id)`; `forceDelete()` uses `withTrashed()->findOrFail($id)` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — redirect/JSON response after create/update/delete | SlotRequirementController: store/update/destroy → redirect to route with `#slot-requirement` hash; toggleStatus → JSON response; ClassSubjectSubgroupController: store → redirect to show route with success flash; update → redirect to tab with success flash | — | — | ◌ |
| TC-CR13 | CR | P1 | Validation — rules cover all editable fields; unique rules ignore current ID on update | Subgroup store: validates 15 fields including `members` array validation; Subgroup update: validates 5 editable fields; Slot Requirement store: validates 8 fields + daily_slots_distribution; Slot update: validates 5 fields | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all required methods defined; permission strings match route/gate names | ClassSubgroupPolicy: 7 gates, each matching `timetable-foundation.class-subgroup.{action}`; SlotRequirementPolicy: 7 gates, each matching `timetable-foundation.slot-requirement.{action}` | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | class-subject-subgroup: resource + 5 custom routes (trashed, restore, forceDelete, toggleStatus, getSections, ajaxToggleSharing, list, generate); slot-requirement: resource + 2 custom routes (toggleStatus, generate); implicit model binding on `{class_subgroup}`, `{slot_availability}` throws 404 | — | — | ◌ |
| TC-CR16 | CR | P1 | View — Blade `@can` directives on tab/action buttons | Timetable Requirement tab page renders filters, data tables, action buttons for groups/subgroups/slot requirements; create/edit views exist for subgroups and slot requirements | — | — | ◌ |
| TC-CR17 | CR | P1 | View — `isset()`/null-safe checks for relationship variables | null-safe patterns for optional relationships: `$group->section->name ?? '--'`, `$subgroup->classGroup->name ?? '--'`, `$slot->activity->name ?? '--'` | — | — | ◌ |
| TC-CR18 | CR | P1 | Breadcrumb — route registered in `config/breadcrumb.php` and renders correct hierarchy | `timetable-requirement` menu route and CRUD pages for class-subject-subgroup and slot-requirement have breadcrumb configurations | — | — | ◌ |
| TC-CR19 | CR | P1 | Database — unique indexes match request validation rules | `uq_clsReqGroups_code` on `code` matches DDL; `uq_clsReqGroups_class_section_subjectType` on (class_id, section_id, subject_study_format_id) matches DDL; `uq_subgroup_code` on `code` matches DDL; `uq_classGroup_subStdFmt_class_section_subjectType` matches DDL; `uq_sa_class_section` on (timetable_type_id, class_timetable_type_id, class_id, section_id) matches DDL | — | — | ◌ |
| TC-CR20 | CR | P1 | Slot Requirement — Model `isValid()` helper method | `isValid()` returns `$this->weekly_total_slots === ($this->weekly_teaching_slots + $this->weekly_exam_slots + $this->weekly_free_slots)`; used for validation—verify it is called in store/update flow | — | — | ◌ |
| TC-CR21 | CR | P1 | Slot Requirement — Model `$timestamps = false` | Model disables Eloquent timestamp management; `public $timestamps = false;` — confirm `created_at`/`updated_at` are not auto-set; DB defaults handle timestamps | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns (All 3 Models)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassRequirementGroup.php` model | Model found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains: code, name, class_group_id, class_id, section_id, subject_id, study_format_id, subject_type_id, subject_study_format_id, class_house_room_id, student_count, eligible_teacher_count, is_active — 13 columns |
| 3 | Open `ClassRequirementSubgroup.php` model | Model found |
| 4 | Inspect `$fillable` array | Contains: code, name, class_group_id, class_id, section_id, subject_id, study_format_id, subject_type_id, subject_study_format_id, class_house_room_id, student_count, eligible_teacher_count, is_shared_across_sections, is_shared_across_classes, is_active — 15 columns |
| 5 | Open `SlotRequirement.php` model | Model found |
| 6 | Inspect `$fillable` array | Contains: timetable_type_id, class_timetable_type_id, class_id, section_id, academic_term_id, activity_id, class_house_room_id, weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots, is_active — 12 columns |
| 7 | Verify no generated/auto columns are fillable | `id`, `deleted_at`, timestamps not in any `$fillable` array |

#### TC-CR02: Model — `$casts` for All 3 Models

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassRequirementGroup` `$casts` | `is_active` → boolean; all FK and count fields → integer; created_at/updated_at/deleted_at → datetime |
| 2 | Inspect `ClassRequirementSubgroup` `$casts` | `is_shared_across_sections`, `is_shared_across_classes`, `is_active` → boolean; all FK and count fields → integer |
| 3 | Inspect `SlotRequirement` `$casts` | `is_active` → boolean; all slot counts → integer; all FK → integer |
| 4 | Create a record for each model and fetch it | All cast fields return correct PHP types (boolean/integer/Carbon) |

#### TC-CR03: Model — SoftDeletes Trait on All 3 Models

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each model for `use SoftDeletes` | All 3 models import `Illuminate\Database\Eloquent\SoftDeletes` |
| 2 | Verify `deleted_at` column exists in DDL for all 3 tables | All 3 DDLs define `deleted_at` as nullable TIMESTAMP |
| 3 | Soft delete a slot requirement | `deleted_at` set; record excluded from normal queries |
| 4 | Call `withTrashed()` | Record appears in results |
| 5 | Call `onlyTrashed()` | Only soft-deleted records appear |
| 6 | Restore the record | `deleted_at` nullified; record visible in normal queries |

#### TC-CR04: Model — Relationships Defined Per FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassRequirementGroup` relationships | `class()` → belongsTo SchClass; `section()` → belongsTo SchSection; `subjectStudyFormat()` → belongsTo SchSubjectStudyFormatJnt; `classHouseRoom()` → belongsTo SchRoom |
| 2 | Inspect `ClassRequirementSubgroup` relationships | `class()` → belongsTo SchClass; `section()` → belongsTo SchSection; `subjectStudyFormat()` → belongsTo SubjectStudyFormat; `classHouseRoom()` → belongsTo SchRoom |
| 3 | Inspect `SlotRequirement` relationships | `timetableType()` → belongsTo TimetableType; `classTimetableType()` → belongsTo ClassTimetableType; `class()` → belongsTo SchoolClass; `section()` → belongsTo Section; `academicTerm()` → belongsTo AcademicTerm |
| 4 | Verify `scopeActive()` on all models | All 3 models define `scopeActive()` applying `where('is_active', true)` |

#### TC-CR05: Controller — Try-Catch on Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassSubjectSubgroupController@store()` | try-catch wraps subgroup + members creation; catch calls `DB::rollBack()` and returns back with input + error message |
| 2 | Inspect `ClassSubjectSubgroupController@update()` | try-catch wraps update; catch calls `DB::rollBack()`, logs error, returns back with error message |
| 3 | Inspect `ClassSubjectSubgroupController@generateClassSubgroups()` | try-catch wraps batch creation; catch calls `DB::rollBack()` and returns JSON error response |
| 4 | Inspect `SlotRequirementController@store()` | No explicit try-catch; single `updateOrCreate` call |
| 5 | Inspect `SlotRequirementController@update()` | No explicit try-catch; single `update` call |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassSubjectSubgroupController@store()` | `DB::beginTransaction()` before processing; `DB::commit()` after success; `DB::rollBack()` on exception |
| 2 | Inspect `ClassSubjectSubgroupController@update()` | `DB::beginTransaction()` before update; `DB::commit()` after success |
| 3 | Inspect `ClassSubjectSubgroupController@generateClassSubgroups()` | `DB::beginTransaction()` before batch generation; `DB::commit()` after success |
| 4 | Inspect `SlotRequirementController@store()` | No explicit transaction (single `updateOrCreate` operation) |
| 5 | Inspect `SlotRequirementController@destroy()` | No explicit transaction (single `delete()` + activityLog) |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all ClassSubjectSubgroupController methods | `index()` viewAny; `create()` create; `store()` create; `show()` view; `edit()` update; `update()` update; `destroy()` delete; `listSubgroups()` viewAny; `getSectionsByClass()` viewAny; `getSectionsWithClassGroups()` viewAny; `generateClassSubgroups()` create; `getSubgroupStats()` viewAny; `ajaxToggleSharing()` update |
| 2 | Inspect all SlotRequirementController methods | `index()` viewAny; `create()` create; `store()` create; `show()` view; `edit()` update; `update()` update; `destroy()` delete; `toggleStatus()` update; `generateSlotRequirement()` create |

#### TC-CR08: Controller — Activity Logged on State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SlotRequirementController@destroy()` | `activityLog($slotRequirement, 'Deleted', ['message' => 'Slot requirement was deleted.'])` called |
| 2 | Inspect `SlotRequirementController@toggleStatus()` | `activityLog($SlotRequirement, 'Toggled', ['message' => '...', 'is_active' => ...])` called before save |
| 3 | Inspect `ClassSubjectSubgroupController` store/update/destroy | Confirm if activity logging is present or missing |

#### TC-CR09: Controller — `is_active=false` Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassSubjectSubgroupController@destroy()` | Only calls `$subgroup->delete()`; verify if `is_active=false` is set before delete or if this is a gap |
| 2 | Inspect `SlotRequirementController@destroy()` | Calls `$slotRequirement->delete()` directly; no is_active change before delete |

#### TC-CR10: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SlotRequirementController@toggleStatus()` | Receives `is_active` from request; sets `$SlotRequirement->is_active = (bool) $request->input('is_active')`; calls `$SlotRequirement->save()` |
| 2 | Verify response | `response()->json(['success' => true, 'is_active' => $SlotRequirement->is_active, 'message' => flash('status_updated.slot_availability')])` |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassSubjectSubgroupController` trash routes | Trash view (`trashedClassSubgroup`), restore (`restore`), forceDelete (`forceDelete`) routes defined |
| 2 | Inspect `SlotRequirementController` trash routes | No trash/restore/forceDelete routes defined for SlotRequirementController (resource only) |
| 3 | Verify `restore()` uses `onlyTrashed()->findOrFail($id)` | Pattern followed for ClassSubjectSubgroup |
| 4 | Verify `forceDelete()` uses `withTrashed()->findOrFail($id)` | Pattern followed for ClassSubjectSubgroup |

#### TC-CR12: Controller — Redirect/JSON Response After Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SlotRequirementController@store()` success | `redirect()->to(route('timetable-foundation.index') . '#slot-requirement')->with('success', flash('created.slot_requirement'))` |
| 2 | Inspect `SlotRequirementController@update()` success | `redirect()->to(route('timetable-foundation.index') . '#slot-requirement')->with('success', flash('updated.slot_requirement'))` |
| 3 | Inspect `SlotRequirementController@destroy()` success | `redirect()->to(route('timetable-foundation.index') . '#slot-requirement')->with('success', flash('deleted.slot_requirement'))` |
| 4 | Inspect `ClassSubjectSubgroupController@store()` success | `redirect()->route('class-subgroups.show', $subgroup->id)->with('success', 'Subgroup created successfully with assigned members.')` |
| 5 | Inspect `ClassSubjectSubgroupController@update()` success | `redirect()->route('timetable-foundation.menu.timetablePreparation', ['tab' => 'class-subject-requirement'])->with('success', 'Class subgroup updated successfully.')` |
| 6 | Inspect AJAX toggleStatus response | JSON with `success`, `is_active`, `message` |
| 7 | Inspect generateClassSubgroups response | JSON with `success`, `message`, `data` |

#### TC-CR13: Validation — Rules Cover All Editable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `ClassSubjectSubgroupController@store()` rules | 15 fields validated: class_group_id, code, name, description, subgroup_type, min_students, max_students, is_shared_across_sections, is_shared_across_classes, is_active, members (array), members.*.class_id, members.*.section_id, members.*.is_active, primary_member |
| 2 | Inspect `ClassSubjectSubgroupController@update()` rules | 5 fields validated: name, description, is_shared_across_sections, is_shared_across_classes, is_active |
| 3 | Inspect `SlotRequirementController@store()` rules | 8 fields validated: timetable_type_id, class_timetable_type_id, class_id, section_id, weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots + daily_slots_distribution_json |
| 4 | Inspect `SlotRequirementController@update()` rules | 5 fields validated: weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots + daily_slots_distribution_json |

#### TC-CR14: Policy — All Required Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassSubgroupPolicy.php` | Policy found |
| 2 | Inspect each method | `viewAny()`, `view()`, `create()`, `update()`, `delete()`, `restore()`, `forceDelete()` all defined; each returns `$user->can('timetable-foundation.class-subgroup.{action}')` |
| 3 | Open `SlotRequirementPolicy.php` | Policy found |
| 4 | Inspect each method | All 7 gates defined; each returns `$user->can('timetable-foundation.slot-requirement.{action}')` |

#### TC-CR15: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | Route groups found for both class-subject-subgroup and slot-requirement |
| 2 | Verify class-subject-subgroup resource route | `Route::resource('class-subject-subgroup', ClassSubjectSubgroupController::class)->names('class-subgroup')` |
| 3 | Verify class-subject-subgroup custom routes | `trash/view` (GET), `{id}/restore` (GET), `{id}/force-delete` (DELETE), `{class_subgroup}/toggle-status` (POST), `{class}/get/sections` (GET), `ajax/toggle-sharing/{id}` (POST) |
| 4 | Verify slot-requirement resource route | `Route::resource('slot-requirement', SlotRequirementController::class)` |
| 5 | Verify slot-requirement custom routes | `{slot_availability}/toggle-status` (POST), `generate` (POST) |
| 6 | Verify list and stats routes | `class-subject-subgroup/list` (GET), `getSubgroupStats()` (GET) |
| 7 | Verify generateClassSubgroups route | `POST /class-subject-subgroup/generate` |
| 8 | Verify implicit model binding | Route parameter `{class_subgroup}` and `{slot_availability}` trigger ModelNotFoundException for invalid IDs |

#### TC-CR16: View — Blade `@can` Directives on Tab/Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `timetable-requirement` Blade views | Tab structure renders class-subject-requirement and slot-requirements tab panes |
| 2 | Inspect create/edit views for subgroups | Create form with class group selection, code, name, description, members configuration; edit form pre-filled |
| 3 | Inspect create/edit views for slot requirements | Create/edit form with academic term, timetable type, class, section dropdowns and slot count fields |
| 4 | Inspect show views | Detail tables with all field values displayed |

#### TC-CR17: View — `isset()`/Null-Safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect group/subgroup list views | Null-safe access for optional section: `$group->section->name ?? 'All Sections'` |
| 2 | Inspect slot requirement detail views | `$slot->activity->name ?? '--'` for optional activity link |
| 3 | Inspect show views | Conditional display for nullable fields (required_room_type, required_room, activity) |

#### TC-CR18: Breadcrumb — Route Registered in Config File

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `config/breadcrumb.php` | Entries for `timetable-requirement` menu, `class-subject-subgroup` resource, `slot-requirement` resource |
| 2 | Open any class-subject-subgroup view | Breadcrumb renders hierarchy: Home > Timetable Foundation > Timetable Requirement > Class Subject Requirement |
| 3 | Open any slot-requirement view | Breadcrumb renders hierarchy: Home > Timetable Foundation > Timetable Requirement > Slot Requirements |

#### TC-CR19: Database — Unique Indexes Match Request Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify DDL unique keys for `tt_class_requirement_groups` | `uq_clsReqGroups_code` on code; `uq_clsReqGroups_class_section_subjectType` on (class_id, section_id, subject_study_format_id) |
| 2 | Verify DDL unique keys for `tt_class_requirement_subgroups` | `uq_subgroup_code` on code; `uq_classGroup_subStdFmt_class_section_subjectType` on (class_id, section_id, subject_study_format_id) |
| 3 | Verify DDL unique key for `tt_slot_requirements` | `uq_sa_class_section` on (timetable_type_id, class_timetable_type_id, class_id, section_id) |
| 4 | Cross-check controller validation | Subgroup `code` validated `unique:tt_class_requirement_subgroups,code`; Slot requirement unique enforced at DB level (controller uses `updateOrCreate`) |

#### TC-CR20: Slot Requirement — Model `isValid()` and `$timestamps`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SlotRequirement::isValid()` | Returns `$this->weekly_total_slots === ($this->weekly_teaching_slots + $this->weekly_exam_slots + $this->weekly_free_slots)` |
| 2 | Create a slot with valid sum (total=8, teaching=6, exam=2, free=0) | `isValid()` returns true |
| 3 | Create a slot with invalid sum (total=8, teaching=8, exam=0, free=0) | `isValid()` returns false |
| 4 | Inspect `$timestamps` property | `public $timestamps = false;` — Eloquent does not auto-manage created_at/updated_at |

### 7.1 Positive TC Steps

#### TC-P01: Class Subject Requirement Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | Dashboard loaded |
| 2 | Navigate to `GET /timetable-foundation/timetable-requirement?tab=class-subject-requirement` | Page loads with HTTP 200; tab pane visible |
| 3 | Verify dropdowns present | Class dropdown, section dropdown, subject filter dropdown rendered |
| 4 | Verify grid headers present | Requirement Groups grid shows columns: #, Code, Name, Class, Section, Subject, Type, Status, Action |
| 5 | Verify subgroup grid present | Requirement Subgroups grid or table visible |
| 6 | Verify Create button visible | Create / Generate buttons visible for groups/subgroups |

#### TC-P02: Filter Requirement Groups By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 2 classes have requirement groups | Groups exist for Class-1 and Class-2 |
| 2 | Select Class-1 from class dropdown | Page reloads; grid shows only groups belonging to Class-1 |
| 3 | Select Class-2 from class dropdown | Grid shows only groups belonging to Class-2 |

#### TC-P04: Slot Requirements Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/timetable-requirement?tab=slot-requirements` | Page loads with HTTP 200; slot requirements tab active |
| 2 | Verify dropdowns present | Academic term dropdown, timetable type dropdown, class dropdown, section dropdown all rendered |
| 3 | Verify columns present | Grid columns: #, Class, Section, Timetable Type, Total, Teaching, Exam, Free, Activity, Status, Action |
| 4 | Verify Filter and Reset buttons | Filter and Reset buttons visible |
| 5 | Verify Generate button | "Generate Slot Requirements" button visible |

#### TC-P10: Create Slot Requirement With Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure academic term, timetable type, class timetable type, class, and section exist | Seed data prepared |
| 2 | POST to `http://tenant.test/timetable-foundation/slot-requirement` with valid data | Validation passes; `updateOrCreate` creates or updates record |
| 3 | Verify `academic_term_id=1, timetable_type_id=1, class_timetable_type_id=1, class_id=1, section_id=1, weekly_total_slots=8, weekly_teaching_slots=6, weekly_exam_slots=2, weekly_free_slots=0` | Record persisted in `tt_slot_requirements` |
| 4 | Verify redirect | Redirected to `#slot-requirement` with success flash message |

#### TC-P15: Generate Slot Requirements From Class Timetable Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `tt_class_timetable_types_jnt` has rows for academic_term_id=1, timetable_type_id=1 | At least 2 rows with different applies_to_all_sections values |
| 2 | POST to `http://tenant.test/timetable-foundation/slot-requirement/generate` with `academic_term_id=1, timetable_type_id=1` | Generation runs successfully |
| 3 | Verify all existing slot requirements for term=1, type=1 are deleted | Old records removed |
| 4 | Verify new records created for section-specific rows | Each class+section combo from STEP 1 has a record |
| 5 | Verify new records created for class-level rows | Class-level rows expanded to sections; sections already handled in STEP 1 skipped |
| 6 | Verify slot counts computed correctly | Teaching/Exam/Free counts computed from explicit values or period set fallback |
| 7 | Verify redirect back with success | Redirect with `->with('success', 'Slot availability generated successfully.')` |

#### TC-P22: getSectionsByClass AJAX Returns Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure class_id=1 exists with active sections | At least 2 active sections via `sch_class_section_jnt` |
| 2 | GET `http://tenant.test/timetable-foundation/class-subject-subgroup/1/get/sections` | JSON response with `success: true` |
| 3 | Verify response contains `class` object | `class.id`, `class.name`, `class.code` present |
| 4 | Verify response contains `sections` array | Each section has `id`, `name`, `code`, `display_name`, `available_seats`, `capacity`, `current_students`, `class_section_id` |
| 5 | Verify `count` field | `count` equals number of sections returned |

#### TC-P24: ajaxToggleSharing — mode=sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure subgroup with ID 1 exists | Subgroup record present |
| 2 | POST to `http://tenant.test/timetable-foundation/class-subject-subgroup/ajax/toggle-sharing/1` with `mode=sections` | Validation passes; update runs |
| 3 | Verify `is_shared_across_sections=true` | DB shows flag set to 1 |
| 4 | Verify `is_shared_across_classes=false` | DB shows flag set to 0 |
| 5 | Verify JSON response | `{success: true, mode: "sections", message: "Sharing updated to: Sections"}` |

### 7.2 Negative TC Steps

#### TC-N01: Required — Missing Slot Requirement `timetable_type_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `http://tenant.test/timetable-foundation/slot-requirement` without `timetable_type_id` | Validation error: "The timetable type id field is required." |
| 2 | Verify no record created | No new row in `tt_slot_requirements` |

#### TC-N12: Required — Missing Subgroup Create `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `http://tenant.test/timetable-foundation/class-subject-subgroup` without `code` | Validation error: "The code field is required." |
| 2 | Verify no record created | No new row in `tt_class_requirement_subgroups` |

#### TC-N23: Invalid — ajaxToggleSharing Non-Existent Subgroup ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `http://tenant.test/timetable-foundation/class-subject-subgroup/ajax/toggle-sharing/99999` with `mode=none` | HTTP 404 Not Found via `findOrFail` |

#### TC-N26: generateClassSubgroups — No Non-MAJOR Class Groups Found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no class groups with subject types MIN, OPT, ELE, ADD exist | All class groups have MAJOR type only |
| 2 | POST to `http://tenant.test/timetable-foundation/class-subject-subgroup/generate` | JSON response with `success: false, message: "No class groups found with non-MAJOR subject types."` and HTTP 400 |

#### TC-N27: getSectionsByClass — Non-Existent Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `http://tenant.test/timetable-foundation/class-subject-subgroup/99999/get/sections` | JSON `{success: false, message: "Class not found or inactive", sections: []}` with HTTP 404 |

#### TC-N36: Guest Access Redirect For All Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest session) | No authenticated user |
| 2 | Navigate to `GET /timetable-foundation/timetable-requirement?tab=class-subject-requirement` | Redirected to `/login` |
| 3 | Navigate to `GET /timetable-foundation/timetable-requirement?tab=slot-requirements` | Redirected to `/login` |
| 4 | POST to slot-requirement store | Redirected to `/login` or 419 CSRF / 401 unauthorized |

### 7.3 Dependency TC Steps

#### TC-D01: Requirement Group — RESTRICT FK: Cannot Delete Class Referenced By Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a requirement group exists with `class_id=1` | Group record references Class 1 |
| 2 | Attempt to DELETE from `sch_classes` WHERE `id=1` directly in DB | Integrity constraint violation (FK RESTRICT) — class cannot be deleted |
| 3 | Verify class still exists | `sch_classes` record remains |

#### TC-D05: Requirement Subgroup — SET NULL FK: Deleting Parent Class Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a subgroup exists with `class_group_id=1` | Subgroup references `sch_class_groups_jnt` record 1 |
| 2 | DELETE from `sch_class_groups_jnt` WHERE `id=1` | Deletion succeeds (no RESTRICT) |
| 3 | Verify subgroup's `class_group_id` is now NULL | Subgroup persists with `class_group_id = NULL` |

#### TC-D09: generateSlotRequirement — Pre-Step Deletes All Existing Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 slot requirements: one for term=1, type=1 and one for term=1, type=2 | Both records exist in DB |
| 2 | POST generate with `academic_term_id=1, timetable_type_id=1` | Generation runs |
| 3 | Verify records for term=1, type=1 are deleted (replaced) | Old records for this combination removed |
| 4 | Verify records for term=1, type=2 remain untouched | Record for type=2 still exists |

#### TC-D13: generateSlotRequirement — Fallback Slot Calculation From Period Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a `tt_class_timetable_types_jnt` row has `weekly_teaching_period_count=NULL`, `period_set_id=1`, and `tt_period_sets` has `teaching_periods=8` | Period set has 8 teaching periods |
| 2 | Ensure `tt_school_days` has 6 active school day records | School day count = 6 |
| 3 | POST generate with `academic_term_id=1, timetable_type_id=1` | Generation runs |
| 4 | Verify `weekly_teaching_slots` = 8 × 6 = 48 for the generated record | Fallback calculation applied: `teaching_periods × school_day_count` |

#### TC-D34: Slot Requirement — Model $fillable Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SlotRequirement.php` model | Model found |
| 2 | List columns from DDL for `tt_slot_requirements` | id, academic_term_id, timetable_type_id, class_timetable_type_id, class_id, section_id, class_house_room_id, weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots, activity_id, is_active |
| 3 | Verify `$fillable` includes all writable columns | timetable_type_id, class_timetable_type_id, class_id, section_id, academic_term_id, activity_id, class_house_room_id, weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots, is_active — 12 columns |
| 4 | Verify `id`, `created_at`, `updated_at`, `deleted_at` not fillable | Generated/auto columns protected from mass assignment |
