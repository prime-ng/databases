# tt_ActivityManagement_TcList

## Module: TimetableFoundation → Timetable Preparation → Activity Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Timetable Preparation |
| Feature | Activity Management |
| URL(s) | `GET` `/timetable-foundation/activity` (index — redirects to timetable preparation tab), `GET` `/timetable-foundation/activity/create` (create form), `POST` `/timetable-foundation/activity` (store), `GET` `/timetable-foundation/activity/{activity}` (show), `GET` `/timetable-foundation/activity/{activity}/edit` (edit form), `PATCH` `/timetable-foundation/activity/{activity}` (update), `DELETE` `/timetable-foundation/activity/{activity}` (destroy), `GET` `/timetable-foundation/activity/trash/view` (trashed list), `GET` `/timetable-foundation/activity/{id}/restore` (restore), `DELETE` `/timetable-foundation/activity/{id}/force-delete` (forceDelete), `POST` `/timetable-foundation/activity/{activity}/toggle-status` (toggleStatus), `POST` `/timetable-foundation/activity/{activity}/update-priority` (ajaxUpdatePriority), `POST` `/timetable-foundation/requirements/generate-activities/all` (generateActivities), `POST` `/timetable-foundation/class-group-requirements/generate-all` (generateAllActivities), `GET` `/timetable-foundation/class-group-requirements/generation-progress` (getBatchGenerationProgress), `GET` `/timetable-foundation/sub-activity/{subActivity}/details` (SubActivityDetail index), `POST` `/timetable-foundation/sub-activity/{subActivity}/details/seed` (SubActivityDetail seed), `POST` `/timetable-foundation/sub-activity/{subActivity}/details` (SubActivityDetail store), `PATCH` `/timetable-foundation/sub-activity-detail/{subActivityDetail}` (SubActivityDetail update), `DELETE` `/timetable-foundation/sub-activity-detail/{subActivityDetail}` (SubActivityDetail destroy) |
| Controller(s) | `Modules\TimetableFoundation\Http\Controllers\ActivityController` (1853 lines); `Modules\TimetableFoundation\Http\Controllers\SubActivityDetailController` (155 lines) |
| Model(s) | `Modules\TimetableFoundation\Models\Activity` (table: `tt_activities`), `Modules\TimetableFoundation\Models\SubActivity` (table: `tt_sub_activities`), `Modules\TimetableFoundation\Models\SubActivityDetail` (table: `tt_sub_activity_details`), `Modules\TimetableFoundation\Models\ActivityTeacher` (table: `tt_activity_teachers`), `Modules\TimetableFoundation\Models\ActivityPriority` (table: `tt_activity_priorities`) |
| Validation (Create) | Inline `$request->validate()` in `ActivityController@store()` — no dedicated Form Request |
| Validation (Update) | Inline `$request->validate()` in `ActivityController@update()` — `Rule::unique()->ignore()` for code |
| Validation (SubActivityDetail) | Inline `$request->validate()` in `SubActivityDetailController@store()` and `@update()` |
| Policy | No dedicated ActivityPolicy found — gates use `Gate::authorize('timetable-foundation.activity.*')` directly |
| Permissions | `timetable-foundation.activity.viewAny`, `timetable-foundation.activity.view`, `timetable-foundation.activity.create`, `timetable-foundation.activity.update`, `timetable-foundation.activity.delete`, `timetable-foundation.activity.restore`, `timetable-foundation.activity.forceDelete`, `timetable-foundation.activity.generate`, `timetable-foundation.sub-activity-detail.viewAny`, `timetable-foundation.sub-activity-detail.create`, `timetable-foundation.sub-activity-detail.update`, `timetable-foundation.sub-activity-detail.delete` |
| Pagination | Activity list redirected to timetable preparation tab (no pagination on main list — `paginate()` in `index()` redirects away). Trash view: 10 records per page via `paginate(10)` |
| Soft Deletes | Yes — all 5 models use `SoftDeletes` trait |
| Data Source | Activity records can be manually created or batch-generated from `RequirementConsolidation` records |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions: `timetable-foundation.activity.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.generate`, `timetable-foundation.sub-activity-detail.viewAny`, `.create`, `.update`, `.delete`
- Required seed data:
  - At least one active `AcademicTerm` record in `sch_academic_term` (FK parent — RESTRICT)
  - At least one active `TimetableType` record in `tt_timetable_types`
  - At least one `Class` (`sch_classes`) and `Section` (`sch_sections`) with class-section junction
  - At least one `Subject` (`sch_subjects`), `StudyFormat` (`sch_study_formats`), `SubjectType` (`sch_subject_types`), `SubjectStudyFormat` junction
  - At least one `Room` (`sch_rooms`) and `RoomType` (`sch_rooms_type`) for room-related tests
  - At least one `Teacher` (`sch_teachers`) and `TeacherAssignmentRole` (`tt_teacher_assignment_roles`) for teacher assignment tests
  - For batch generation: `RequirementConsolidation` records with linked class groups/subgroups
  - For sub-activity seeding: At least one activity with `have_sub_activity = true`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For generation tests: At least one active `OrganizationAcademicSession` marked `is_current`

---

## 3. Default Data Load

The Activity Management screen loads via the **Timetable Preparation** tab. `ActivityController@index()` redirects to `timetable-foundation.menu.timetablePreparation?tab=activity`. The main tab page is rendered by `TimetableFoundationController` which passes activity data alongside other tab data.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Activity List | `timetablePreparation()` (via `TimetableFoundationController`) | `Activity::with('subject','class','section','teachers','activityPriority')->orderBy('name')` | `status`, `academic_term_id`, `class_id`, `section_id`, `subject_id`, `is_active`, search | None (all records) |
| Shared dropdowns | `timetablePreparation()` | Classes, Sections, Subjects, AcademicTerms, StudyFormats, TimetableTypes, TeacherAssignmentRoles | `is_active` | None |
| Trashed Activities | `trashedActivity()` | `Activity::onlyTrashed()->orderBy('name')` | None | 10/page (`paginate(10)`) |
| Sub-Activity Details | `SubActivityDetailController@index()` | `$subActivity->details()->with('teacher:id,name', 'room:id,name')` | Specific `subActivity` (implicit binding) | None |

---

## 4. Test Data Strategy

- **Unique identifier:** Use `now()->format('YmdHis')` as a suffix for activity code to avoid `uq_activity_code` collisions (e.g., `ACT-TC-20260718123456`)
- **Consistent references:** Use a known academic term ID, timetable type ID, class ID, section ID, subject ID, and study format ID across all manual-creation tests
- **Pre-test cleanup:** Delete created activities by code prefix before and after tests. Use `forceDelete()` on test-created records after each test to avoid unique constraint violations
- **Batch generation test data:** Create at least 3 `RequirementConsolidation` records — one class-group based, one shared-across-classes subgroup, and one non-shared subgroup — to verify all three generation paths
- **Pagination overflow for trash:** Create 11+ soft-deleted activities to verify `paginate(10)` limit on the trash view
- **Cross-module data:** Ensure `AcademicTerm`, `TimetableType`, `TeacherAvailability`, and `RoomAvailability` records exist before testing batch generation
- **Status transitions:** Create one activity in each status (DRAFT, ACTIVE, LOCKED, ARCHIVED) to test lifecycle restrictions
- **Sub-activity test pairs:** Create one activity with `have_sub_activity=true` and one with `have_sub_activity=false` for detail-row testing
- **Cascade test:** Create an activity with 2 sub-activities, 2 teachers, 1 priority record, and 4 detail rows to test cascade delete behavior

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_activities`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE (`uq_activity_code`) |
| BC-DB-03 | name | VARCHAR(200) | NOT NULL |
| BC-DB-04 | academic_term_id | INT UNSIGNED | NOT NULL, FK → `sch_academic_term(id)` ON DELETE RESTRICT |
| BC-DB-05 | timetable_type_id | INT UNSIGNED | NOT NULL |
| BC-DB-06 | class_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt(id)` ON DELETE SET NULL |
| BC-DB-07 | class_subgroup_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups(id)` ON DELETE SET NULL |
| BC-DB-08 | have_sub_activity | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | class_id | INT UNSIGNED | NOT NULL |
| BC-DB-10 | section_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-11 | subject_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_subjects(id)` ON DELETE SET NULL |
| BC-DB-12 | study_format_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_study_formats(id)` ON DELETE SET NULL |
| BC-DB-13 | subject_type_id | INT UNSIGNED | NOT NULL |
| BC-DB-14 | subject_study_format_id | INT UNSIGNED | NOT NULL |
| BC-DB-15 | required_weekly_periods | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-16 | min_periods_per_week | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-17 | max_periods_per_week | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-18 | max_per_day | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-19 | min_per_day | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-20 | min_gap_periods | TINYINT UNSIGNED | DEFAULT NULL |
| BC-DB-21 | allow_consecutive | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-22 | max_consecutive | TINYINT UNSIGNED | DEFAULT 2 |
| BC-DB-23 | preferred_periods_json | JSON | DEFAULT NULL |
| BC-DB-24 | avoid_periods_json | JSON | DEFAULT NULL |
| BC-DB-25 | spread_evenly | TINYINT(1) | DEFAULT 1 |
| BC-DB-26 | eligible_teacher_count | INT UNSIGNED | DEFAULT NULL |
| BC-DB-27 | min_teacher_availability_score | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-28 | max_teacher_availability_score | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| BC-DB-29 | duration_periods | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-30 | weekly_periods | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-31 | total_periods | SMALLINT UNSIGNED | GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED |
| BC-DB-32 | split_allowed | TINYINT(1) | DEFAULT 0 |
| BC-DB-33 | is_compulsory | TINYINT(1) | DEFAULT 1 |
| BC-DB-34 | priority | TINYINT UNSIGNED | DEFAULT 50 |
| BC-DB-35 | difficulty_score | TINYINT UNSIGNED | DEFAULT 50 |
| BC-DB-36 | compulsory_specific_room_type | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-37 | required_room_type_id | INT UNSIGNED | NOT NULL |
| BC-DB-38 | required_room_id | INT UNSIGNED | DEFAULT NULL |
| BC-DB-39 | requires_room | TINYINT(1) | DEFAULT 1 |
| BC-DB-40 | preferred_room_type_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms_type(id)` ON DELETE SET NULL |
| BC-DB-41 | preferred_room_ids | JSON | DEFAULT NULL |
| BC-DB-42 | difficulty_score_calculated | TINYINT UNSIGNED | DEFAULT 50 |
| BC-DB-43 | teacher_availability_score | TINYINT UNSIGNED | DEFAULT 100 |
| BC-DB-44 | room_availability_score | TINYINT UNSIGNED | DEFAULT 100 |
| BC-DB-45 | constraint_count | SMALLINT UNSIGNED | DEFAULT 0 |
| BC-DB-46 | preferred_time_slots_json | JSON | DEFAULT NULL |
| BC-DB-47 | avoid_time_slots_json | JSON | DEFAULT NULL |
| BC-DB-48 | status | ENUM('DRAFT','ACTIVE','LOCKED','ARCHIVED') | NOT NULL, DEFAULT 'ACTIVE' |
| BC-DB-49 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-50 | created_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users(id)` ON DELETE SET NULL |
| BC-DB-51 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-52 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-53 | deleted_at | TIMESTAMP | NULLABLE |
| BC-DB-54 | **INDEX** | — | `idx_activity_difficulty` on (`difficulty_score`, `constraint_count`) |
| BC-DB-55 | **INDEX** | — | `idx_activity_session` on (`academic_term_id`) |
| BC-DB-56 | **INDEX** | — | `idx_activity_class_group` on (`class_group_id`) |
| BC-DB-57 | **INDEX** | — | `idx_activity_subgroup` on (`class_subgroup_id`) |
| BC-DB-58 | **INDEX** | — | `idx_activity_subject` on (`subject_id`) |
| BC-DB-59 | **INDEX** | — | `idx_activity_status` on (`status`) |
| BC-DB-60 | **INDEX** | — | `idx_activity_generation` on (`academic_term_id`, `difficulty_score`, `status`, `is_active`) |
| BC-DB-61 | **UNIQUE KEY** | — | `uq_activity_code` on (`code`) |

### 5.2 Database Schema — `tt_sub_activities`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-62 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-63 | parent_activity_id | INT UNSIGNED | NOT NULL, FK → `tt_activities(id)` ON DELETE CASCADE |
| BC-DB-64 | class_requirement_subgroup_id | INT UNSIGNED | NOT NULL, FK → `tt_class_requirement_subgroups(id)` (no ON DELETE specified) |
| BC-DB-65 | ordinal | TINYINT UNSIGNED | NOT NULL |
| BC-DB-66 | class_id | INT UNSIGNED | NOT NULL |
| BC-DB-67 | section_id | INT UNSIGNED | NOT NULL |
| BC-DB-68 | duration_periods | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-69 | same_day_as_parent | TINYINT(1) | DEFAULT 0 |
| BC-DB-70 | consecutive_with_previous | TINYINT(1) | DEFAULT 0 |
| BC-DB-71 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-72 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-73 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-74 | deleted_at | TIMESTAMP | NULLABLE |
| BC-DB-75 | **UNIQUE KEY** | — | `uq_subact_parent_ord` on (`parent_activity_id`, `ordinal`) |
| BC-DB-76 | **INDEX** | — | `idx_subact_parent` on (`parent_activity_id`) |

### 5.3 Database Schema — `tt_sub_activity_details`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-77 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-78 | sub_activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_sub_activities(id)` ON DELETE CASCADE |
| BC-DB-79 | activity_id | INT UNSIGNED | NOT NULL, FK → `tt_activities(id)` ON DELETE CASCADE |
| BC-DB-80 | period_number | TINYINT UNSIGNED | NOT NULL |
| BC-DB-81 | assigned_teacher_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_teacher_profile(id)` ON DELETE SET NULL |
| BC-DB-82 | assigned_room_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms(id)` ON DELETE SET NULL |
| BC-DB-83 | assigned_time_slot | VARCHAR(50) | DEFAULT NULL |
| BC-DB-84 | assignment_status | ENUM('UNASSIGNED','TEACHER_ASSIGNED','ROOM_ASSIGNED','FULLY_ASSIGNED') | NOT NULL, DEFAULT 'UNASSIGNED' |
| BC-DB-85 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-86 | **UNIQUE KEY** | — | `uq_subact_detail` on (`sub_activity_id`, `period_number`) |
| BC-DB-87 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (model default, not in DDL) |
| BC-DB-88 | created_by | INT UNSIGNED | (model fillable, not in DDL — FK may exist at runtime) |
| BC-DB-89 | updated_at | TIMESTAMP | (model SoftDeletes, not in DDL) |
| BC-DB-90 | deleted_at | TIMESTAMP | NULLABLE (model SoftDeletes, not in DDL) |

### 5.4 Database Schema — `tt_activity_teachers`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-91 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-92 | activity_id | INT UNSIGNED | NOT NULL, FK → `tt_activities(id)` ON DELETE CASCADE |
| BC-DB-93 | teacher_id | INT UNSIGNED | NOT NULL, FK → `sch_teachers(id)` ON DELETE CASCADE |
| BC-DB-94 | assignment_role_id | TINYINT UNSIGNED | NOT NULL, FK → `tt_teacher_assignment_roles(id)` ON DELETE RESTRICT |
| BC-DB-95 | is_required | TINYINT(1) | DEFAULT 1 |
| BC-DB-96 | ordinal | TINYINT UNSIGNED | DEFAULT 1 |
| BC-DB-97 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-98 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-99 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-100 | deleted_at | TIMESTAMP | NULLABLE |
| BC-DB-101 | **UNIQUE KEY** | — | `uq_at_activity_teacher` on (`activity_id`, `teacher_id`) |
| BC-DB-102 | **INDEX** | — | `idx_at_teacher` on (`teacher_id`) |

### 5.5 Database Schema — `tt_activity_priorities`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-103 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-104 | activity_id | INT UNSIGNED | NOT NULL, FK → `tt_activities(id)` (no ON DELETE specified in DDL — model cascades via `hasOne`) |
| BC-DB-105 | priority_score | DECIMAL(5,2) | NOT NULL, 0.00–100.00 |
| BC-DB-106 | priority_reason | TEXT | DEFAULT NULL |
| BC-DB-107 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-108 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-109 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-110 | deleted_at | TIMESTAMP | NULLABLE |
| BC-DB-111 | **UNIQUE KEY** | — | `uq_activity_priority` on (`activity_id`) |

### 5.6 Validation Rules — ActivityController@store() (Manual Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:50, unique:tt_activities,code | "The code has already been taken." |
| BC-VAL-02 | name | required, string, max:200 | "The name field is required." |
| BC-VAL-03 | description | nullable, string, max:500 | — |
| BC-VAL-04 | academic_session_id | required, exists:global_master_mysql.glb_academic_sessions,id | "The selected academic session is invalid." |
| BC-VAL-05 | class_group_jnt_id | nullable, exists:sch_class_groups_jnt,id | "The selected class group is invalid." |
| BC-VAL-06 | class_subgroup_id | nullable, exists:tt_class_requirement_subgroups,id | "The selected class subgroup is invalid." |
| BC-VAL-07 | duration_periods | required, integer, min:1 | "The duration periods field is required." |
| BC-VAL-08 | weekly_periods | required, integer, min:1 | "The weekly periods field is required." |
| BC-VAL-09 | priority | nullable, integer, min:1, max:100 | — |
| BC-VAL-10 | difficulty_score | nullable, integer, min:1, max:100 | — |
| BC-VAL-11 | split_allowed | sometimes (boolean) | — |
| BC-VAL-12 | is_compulsory | sometimes (boolean) | — |
| BC-VAL-13 | requires_room | sometimes (boolean) | — |
| BC-VAL-14 | preferred_room_type_id | nullable, exists:sch_rooms_type,id | "The selected preferred room type is invalid." |
| BC-VAL-15 | is_active | sometimes (boolean) | — |
| BC-VAL-16 | teachers | nullable, array | — |
| BC-VAL-17 | teachers.*.teacher_id | required_with:teachers.*.assignment_role_id, exists:sch_teachers,id | "The selected teacher is invalid." |
| BC-VAL-18 | teachers.*.assignment_role_id | required_with:teachers.*.teacher_id, exists:tt_teacher_assignment_roles,id | "The selected assignment role is invalid." |
| BC-VAL-19 | teachers.*.ordinal | nullable, integer, min:1 | — |
| BC-VAL-20 | teachers.*.is_required | sometimes (boolean) | — |
| BC-VAL-21 | **Controller check:** Mutually exclusive target | Exactly one of `class_group_jnt_id` or `class_subgroup_id` must be set (not both, not neither) | "Select either a Class Group or a Class Subgroup (not both)." |
| BC-VAL-22 | **Controller check:** Duplicate teacher | No duplicate `teacher_id` values in `teachers` array | "A teacher cannot be assigned more than once." |

### 5.7 Validation Rules — `ActivityController@update()` (Manual Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | code | required, string, max:50, `Rule::unique('tt_activities','code')->ignore($activity->id)` | "The code has already been taken." |
| BC-VAL-U02 | name | required, string, max:200 | "The name field is required." |
| BC-VAL-U03 | academic_session_id | required, exists:global_master_mysql.glb_academic_sessions,id | "The selected academic session is invalid." |
| BC-VAL-U04 | class_group_jnt_id | nullable, exists:sch_class_groups_jnt,id | "The selected class group is invalid." |
| BC-VAL-U05 | class_subgroup_id | nullable, exists:tt_class_requirement_subgroups,id | "The selected class subgroup is invalid." |
| BC-VAL-U06 | duration_periods | required, integer, min:1 | — |
| BC-VAL-U07 | weekly_periods | required, integer, min:1 | — |
| BC-VAL-U08 | priority | nullable, integer, min:1, max:100 | — |
| BC-VAL-U09 | difficulty_score | nullable, integer, min:1, max:100 | — |
| BC-VAL-U10 | split_allowed | sometimes (boolean) | — |
| BC-VAL-U11 | is_compulsory | sometimes (boolean) | — |
| BC-VAL-U12 | requires_room | sometimes (boolean) | — |
| BC-VAL-U13 | preferred_room_type_id | nullable, exists:sch_rooms_type,id | "The selected preferred room type is invalid." |
| BC-VAL-U14 | is_active | sometimes (boolean) | — |
| BC-VAL-U15 | teachers | nullable, array | — |
| BC-VAL-U16 | teachers.*.teacher_id | required_with:teachers.*.assignment_role_id, exists:sch_teachers,id | "The selected teacher is invalid." |
| BC-VAL-U17 | teachers.*.assignment_role_id | required_with:teachers.*.teacher_id, exists:tt_teacher_assignment_roles,id | "The selected assignment role is invalid." |
| BC-VAL-U18 | teachers.*.ordinal | nullable, integer, min:1 | — |
| BC-VAL-U19 | teachers.*.is_required | sometimes (boolean) | — |
| BC-VAL-U20 | **Controller check:** Mutually exclusive target | Exactly one of `class_group_jnt_id` or `class_subgroup_id` | "Select either a Class Group or a Class Subgroup (not both)." |
| BC-VAL-U21 | **Controller check:** Duplicate teacher | No duplicate `teacher_id` values | "The same teacher cannot be assigned more than once to an activity." |

### 5.8 Validation Rules — `SubActivityDetailController`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-D01 | count (seed) | nullable, integer, min:1, max:255 | — |
| BC-VAL-D02 | period_number (store) | required, integer, min:1, max:255 | "The period number field is required." |
| BC-VAL-D03 | assigned_teacher_id (store) | nullable, integer, exists:sch_teachers,id | "The selected assigned teacher is invalid." |
| BC-VAL-D04 | assigned_room_id (store) | nullable, integer, exists:sch_rooms,id | "The selected assigned room is invalid." |
| BC-VAL-D05 | assigned_time_slot (store) | nullable, string, max:50 | — |
| BC-VAL-D06 | assigned_teacher_id (update) | nullable, integer, exists:sch_teachers,id | "The selected assigned teacher is invalid." |
| BC-VAL-D07 | assigned_room_id (update) | nullable, integer, exists:sch_rooms,id | "The selected assigned room is invalid." |
| BC-VAL-D08 | assigned_time_slot (update) | nullable, string, max:50 | — |
| BC-VAL-D09 | is_active (update) | nullable, boolean | — |

### 5.9 Authorization

| BC ID | Permission | Controller Method(s) | Behavior |
|-------|-----------|----------------------|----------|
| BC-AUTH-01 | `timetable-foundation.activity.viewAny` | `index()` | Without → 403 Forbidden |
| BC-AUTH-02 | `timetable-foundation.activity.view` | `show()` | Without → 403 Forbidden |
| BC-AUTH-03 | `timetable-foundation.activity.create` | `create()`, `store()` | Without → 403 Forbidden |
| BC-AUTH-04 | `timetable-foundation.activity.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 Forbidden |
| BC-AUTH-05 | `timetable-foundation.activity.delete` | `destroy()` | Without → 403 Forbidden |
| BC-AUTH-06 | `timetable-foundation.activity.restore` | `trashedActivity()`, `restore()` | Without → 403 Forbidden |
| BC-AUTH-07 | `timetable-foundation.activity.forceDelete` | `forceDelete()` | Without → 403 Forbidden |
| BC-AUTH-08 | `timetable-foundation.activity.generate` | `generateActivities()`, `generateAllActivities()` | Without → 403 Forbidden |
| BC-AUTH-09 | `timetable-foundation.sub-activity-detail.viewAny` | `SubActivityDetailController@index()` | Without → 403 Forbidden |
| BC-AUTH-10 | `timetable-foundation.sub-activity-detail.create` | `SubActivityDetailController@store()`, `@seed()` | Without → 403 Forbidden |
| BC-AUTH-11 | `timetable-foundation.sub-activity-detail.update` | `SubActivityDetailController@update()` | Without → 403 Forbidden |
| BC-AUTH-12 | `timetable-foundation.sub-activity-detail.delete` | `SubActivityDetailController@destroy()` | Without → 403 Forbidden |
| BC-AUTH-13 | Guest access | All routes | Redirect to `/login` |

### 5.10 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Activity tab loads via `timetablePreparation()` at `GET /timetable-foundation/menu/timetablePreparation?tab=activity` | Activity list rendered with all activities; filter dropdowns for status, term, class, section, subject present; create button visible; each row shows code, name, class, section, subject, format, weekly periods, status badge, priority badge, action buttons |
| BC-BIZ-02 | Filter by `status` on timetable preparation tab | Activities grid filtered to show only activities matching the selected status |
| BC-BIZ-03 | Filter by `academic_term_id` | Activities filtered to show only those belonging to the selected term |
| BC-BIZ-04 | Filter by `class_id` | Activities filtered to show only those for the selected class |
| BC-BIZ-05 | Filter by `section_id` | Activities filtered to show only those for the selected section |
| BC-BIZ-06 | Filter by `subject_id` | Activities filtered to show only those for the selected subject |
| BC-BIZ-07 | Filter by `is_active` | Activities filtered to show active (1) or inactive (0); default shows all |
| BC-BIZ-08 | Search by activity name or code | Activities filtered to show only those whose `name` or `code` contains the search string |
| BC-BIZ-09 | Create activity — mutually exclusive target | Controller validates that exactly one of `class_group_jnt_id` or `class_subgroup_id` is present; rejects both-null and both-set |
| BC-BIZ-10 | Create activity — duplicate teacher validation | Controller checks `teachers.*.teacher_id` for duplicates; rejects if same teacher appears more than once |
| BC-BIZ-11 | Create activity — DB transaction | `store()` wraps activity + teacher-pivot creation in `DB::transaction()`; if any step fails, no partial data persists |
| BC-BIZ-12 | Create activity — code uppercased | Controller calls `strtoupper()` on the submitted code before saving |
| BC-BIZ-13 | Update activity — code unique ignores own ID | `Rule::unique('tt_activities','code')->ignore($activity->id)` allows keeping the same code on update |
| BC-BIZ-14 | Update activity — teacher re-sync | `update()` soft-deletes existing teacher pivots (`$activity->teachers()->delete()`) then recreates from input |
| BC-BIZ-15 | Destroy LOCKED activity is blocked | `destroy()` checks `$activity->status === 'LOCKED'` and returns redirect back with error message "locked_activity_delete_not_allowed" |
| BC-BIZ-16 | Destroy sets status to ARCHIVED and is_active=false | `destroy()` sets `is_active=false`, `status='ARCHIVED'`, then soft-deletes teacher pivots, then soft-deletes the activity |
| BC-BIZ-17 | Restore sets is_active=true and status=ACTIVE | `restore()` calls `$activity->restore()`, then sets `is_active=true`, `status='ACTIVE'` |
| BC-BIZ-18 | Force delete LOCKED activity is blocked | `forceDelete()` checks `$activity->status === 'LOCKED'` and returns redirect back with error message |
| BC-BIZ-19 | Toggle status on LOCKED → inactive is blocked | `toggleStatus()` returns JSON `{success:false, message:...}` with HTTP 403 if status is LOCKED and `is_active` set to false |
| BC-BIZ-20 | Toggle status returns JSON response | `toggleStatus()` accepts `is_active` (boolean), saves, returns `{success, is_active, message}` |
| BC-BIZ-21 | `ajaxUpdatePriority` updates activity priority | POST to `/activity/{activity}/update-priority` updates the `priority` field directly on the activity record |
| BC-BIZ-22 | Batch generation — truncates existing records | `generateActivities()` truncates `tt_activities`, `tt_sub_activities`, `tt_activity_teachers` (FK checks disabled) before regenerating |
| BC-BIZ-23 | Batch generation — three processing steps | 1. Class-group requirements → `ACT-CG-*` codes; 2. Consolidation: shared-across-classes (`ACT-SAC-*`) then shared-across-sections (`ACT-SAS-*`); 3. Non-shared subgroups → `ACT-SG-*` codes |
| BC-BIZ-24 | Batch generation — score calculation | `teacherAvailabilityScore` = min(100, teachersCount × 20); `roomAvailabilityScore` = min(100, roomsCount × 25); `difficultyScoreCalculated` = weighted formula (difficulty × 0.4 + teacherScore × 0.3 + roomScore × 0.2 + constraint × 0.1) |
| BC-BIZ-25 | Batch generation — capacity-based splitting | If `combinedStudentCount > roomCapacity`, creates multiple activities with `-G{N}` suffix; each group gets proportional sub-activities |
| BC-BIZ-26 | Batch generation — deduplication protection | Multiple checks skip already-processed subjects: `processedSubjectKeys`, `processedSubgroupIds`, activity-exists queries for `ACT-SAC-*`/`ACT-SAS-*` patterns |
| BC-BIZ-27 | Batch generation — teacher assignment | `assignTeacherToActivity()` queries `TeacherAvailability` by class + subject_study_format; assigns all eligible teachers with PRIMARY role if `is_primary_subject=true`, else ASSISTANT; `is_required=false` for batch-generated assignments |
| BC-BIZ-28 | Batch generation — `isLabOrPractical` auto-sets consecutive | If study format name is 'lab', 'practical', or 'workshop', `allow_consecutive` is set to `true` |
| BC-BIZ-29 | Batch generation — transaction with rollback | All generation wrapped in `DB::beginTransaction()`/`commit()`; on exception, `rollBack()` is called, error is logged, and user is redirected with error message |
| BC-BIZ-30 | Empty state — no activities exist | List shows "No records found" message |
| BC-BIZ-31 | Empty state — no trashed activities | Trash view shows appropriate empty state message |
| BC-BIZ-32 | Sub-activity detail seed is idempotent | `seed()` only creates missing `(sub_activity_id, period_number)` rows; existing rows are skipped; returns count of newly created rows |
| BC-BIZ-33 | Sub-activity detail `recomputeStatus()` | After each create/update, `assignment_status` auto-computes: UNASSIGNED → TEACHER_ASSIGNED (teacher only) → ROOM_ASSIGNED (room only) → FULLY_ASSIGNED (teacher + room + time_slot) |
| BC-BIZ-34 | Sub-activity detail update only touches present fields | `update()` only fills keys that were present in request — absent keys are not overwritten to avoid wiping stored data |
| BC-BIZ-35 | `total_periods` is a GENERATED STORED column | Column auto-computes as `duration_periods * weekly_periods` at DB level; must not be written via Eloquent |
| BC-BIZ-36 | `scopeByDifficulty` orders by difficulty DESC, priority DESC | `Activity::byDifficulty()` applies `orderByDesc('difficulty_score')->orderByDesc('priority')` |

### 5.11 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_term_id | `sch_academic_term(id)` | RESTRICT |
| BC-REF-02 | class_group_id | `sch_class_groups_jnt(id)` | SET NULL |
| BC-REF-03 | class_subgroup_id | `tt_class_requirement_subgroups(id)` | SET NULL |
| BC-REF-04 | subject_id | `sch_subjects(id)` | SET NULL |
| BC-REF-05 | study_format_id | `sch_study_formats(id)` | SET NULL |
| BC-REF-06 | preferred_room_type_id | `sch_rooms_type(id)` | SET NULL |
| BC-REF-07 | created_by | `sys_users(id)` | SET NULL |
| BC-REF-08 | parent_activity_id (sub_activities) | `tt_activities(id)` | CASCADE |
| BC-REF-09 | sub_activity_id (sub_activity_details) | `tt_sub_activities(id)` | CASCADE |
| BC-REF-10 | activity_id (sub_activity_details) | `tt_activities(id)` | CASCADE |
| BC-REF-11 | assigned_teacher_id (sub_activity_details) | `sch_teacher_profile(id)` | SET NULL |
| BC-REF-12 | assigned_room_id (sub_activity_details) | `sch_rooms(id)` | SET NULL |
| BC-REF-13 | activity_id (activity_teachers) | `tt_activities(id)` | CASCADE |
| BC-REF-14 | teacher_id (activity_teachers) | `sch_teachers(id)` | CASCADE |
| BC-REF-15 | assignment_role_id (activity_teachers) | `tt_teacher_assignment_roles(id)` | RESTRICT |
| BC-REF-16 | activity_id (activity_priorities) | `tt_activities(id)` | CASCADE (model-level — `hasOne` cascade, DDL has no explicit ON DELETE) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Activity Tab Loads With All UI Elements | Tab pane loads with activity list grid, filter dropdowns (status, term, class, section, subject), search input, create button; table columns: Code, Name, Class, Section, Subject, Format, Weekly Periods, Status, Priority, Action; badges rendered correctly for status/priority | — | — | ⬜ |
| TC-P02 | Filter Activities By Status | Select status "DRAFT" from filter; grid shows only draft activities. Select "ACTIVE"; grid shows only active activities | — | — | ⬜ |
| TC-P03 | Filter Activities By Academic Term | Select a specific term from dropdown; grid shows only activities belonging to that term | — | — | ⬜ |
| TC-P04 | Filter Activities By Class | Select a specific class; grid shows only activities for that class | — | — | ⬜ |
| TC-P05 | Filter Activities By Section | Select a specific section; grid shows only activities for that section | — | — | ⬜ |
| TC-P06 | Filter Activities By Subject | Select a specific subject; grid shows only activities for that subject | — | — | ⬜ |
| TC-P07 | Search Activities By Name | Type an activity name fragment; grid shows only activities whose name contains the string | — | — | ⬜ |
| TC-P08 | Search Activities By Code | Type an activity code fragment; grid shows only activities whose code contains the string | — | — | ⬜ |
| TC-P09 | Reset Filters Clears All Filters | Click reset button; all filters cleared; grid shows default unfiltered list | — | — | ⬜ |
| TC-P10 | Create Activity With Required Fields Only (Class Group Target) | Fill code, name, academic session, class_group_jnt_id, duration_periods=1, weekly_periods=5. Submit. Activity created with status 'ACTIVE', is_active=true. Redirect to timetable preparation tab with success message | — | — | ⬜ |
| TC-P11 | Create Activity With Class Subgroup Target | Fill all required fields using `class_subgroup_id` instead of `class_group_jnt_id`. Activity created successfully targeting the subgroup | — | — | ⬜ |
| TC-P12 | Create Activity With All Optional Fields | Fill code, name, session, class group, duration_periods=2, weekly_periods=3, priority=80, difficulty_score=60, split_allowed=true, is_compulsory=true, requires_room=true, preferred_room_type_id set, is_active=true. Activity created with all values persisted correctly | — | — | ⬜ |
| TC-P13 | Create Activity With `split_allowed=false`, `is_compulsory=false` | Set flags to OFF. Activity created with `split_allowed=0`, `is_compulsory=0` | — | — | ⬜ |
| TC-P14 | Create Activity With `requires_room=false` | Set requires_room to OFF. Activity created with `requires_room=0`; solver will not assign a room | — | — | ⬜ |
| TC-P15 | Create Activity With priority=100, difficulty_score=100 | Max values accepted; priority and difficulty stored correctly | — | — | ⬜ |
| TC-P16 | Create Activity With Teacher Assignments | Include `teachers` array with 2 teachers: Teacher A (role=PRIMARY, ordinal=1, is_required=true), Teacher B (role=ASSISTANT, ordinal=2, is_required=false). Both pivot records created in `tt_activity_teachers` | — | — | ⬜ |
| TC-P17 | Create Activity Duplicate Code Rejected By Validation | Submit second activity with same code. Validation error: "The code has already been taken." | — | — | ⬜ |
| TC-P18 | View Activity Details Page | Click View on an activity; show page loads with all fields: code, name, description, academic term, timetable type, class/section, subject/format/type, weekly periods, duration, total periods (computed), priority, difficulty, flags (split, compulsory, room), room preferences, teacher assignments (names + roles), status badge, active badge, sub-activities list, priority score | — | — | ⬜ |
| TC-P19 | Edit Activity Loads Pre-Filled Data | Click Edit; edit form loads with all existing values pre-filled including code, name, session, target, periods, priority, difficulty, flags, room type, teachers | — | — | ⬜ |
| TC-P20 | Update Activity Code And Name | Change code and name; submit. Activity updated; redirect with success message; `Rule::unique()->ignore($activity->id)` allows keeping same code | — | — | ⬜ |
| TC-P21 | Update Activity — Reassign Teachers | Change teacher list from [Teacher A] to [Teacher B, Teacher C]. Old teacher pivot soft-deleted; new pivots created | — | — | ⬜ |
| TC-P22 | Update Activity — Change weekly_periods from 5 to 4 | Weekly periods updated; `total_periods` generated column auto-recomputes to match (if duration=1, total becomes 4) | — | — | ⬜ |
| TC-P23 | Toggle Status Active → Inactive | Click status toggle on active activity; AJAX POST with `is_active=0`; JSON response `{success: true, is_active: false, message: "..."}`; UI updates | — | — | ⬜ |
| TC-P24 | Toggle Status Inactive → Active | Click status toggle on inactive activity; JSON `{success: true, is_active: true, message: "..."}` | — | — | ⬜ |
| TC-P25 | Ajax Update Priority | POST to `/activity/{activity}/update-priority` with new priority value. Activity priority field updated in DB | — | — | ⬜ |
| TC-P26 | Soft Delete Active Activity | Click Delete on an ACTIVE activity. `is_active` set to false, `status` set to 'ARCHIVED', teacher pivots soft-deleted, activity soft-deleted. Record appears in trash view. Redirect with success message | — | — | ⬜ |
| TC-P27 | View Trashed Activities List | Navigate to trash view; all soft-deleted activities listed with code, name, deleted_at timestamp, is_active=false, status=ARCHIVED; Restore and Force Delete buttons present | — | — | ⬜ |
| TC-P28 | Restore Soft-Deleted Activity | Click Restore on a trashed activity. `deleted_at` nullified; `is_active` set to true; `status` set to 'ACTIVE'. Redirect to trash view with success message | — | — | ⬜ |
| TC-P29 | Force Delete Activity | Click Force Delete on a trashed activity. Activity permanently removed from DB. Redirect to trash view with success message | — | — | ⬜ |
| TC-P30 | Force Delete Restores `is_active` And `status` | After restore, verify `is_active=1` and `status='ACTIVE'` in DB | — | — | ⬜ |
| TC-P31 | Trash View Pagination | Create 11+ soft-deleted activities; trash view shows 10 per page; page 2 shows remaining records | — | — | ⬜ |
| TC-P32 | Full Lifecycle: Create → View → Edit → Toggle → Delete → Restore → Force Delete | Each step in sequence succeeds; data transitions correctly at each stage | — | — | ⬜ |
| TC-P33 | Empty State — No Activities Exist | When no activities exist, list shows "No records found" | — | — | ⬜ |
| TC-P34 | Empty State — No Trashed Activities | When no trashed activities exist, trash view shows empty state message | — | — | ⬜ |
| TC-P35 | Batch Generation — Class Group Requirements | POST to `/requirements/generate-activities/all` with class-group RequirementConsolidation records. Activities created with `ACT-CG-*` codes, scores calculated, teachers assigned. Redirect with success message showing counts | — | — | ⬜ |
| TC-P36 | Batch Generation — Shared Across Classes Consolidation | Multiple subgroups with `is_shared_across_classes=true` for same subject. Single activity created with `ACT-SAC-*` code and sub-activities per class | — | — | ⬜ |
| TC-P37 | Batch Generation — Shared Across Sections Consolidation | Multiple subgroups with `is_shared_across_sections=true` for same class+subject. Single activity created with `ACT-SAS-*` code and sub-activities per section | — | — | ⬜ |
| TC-P38 | Batch Generation — Capacity-Based Splitting (Multiple Groups) | Subgroups with total students > room capacity. Multiple activities created with `-G1`, `-G2`, etc. suffixes; sub-activities distributed proportionally | — | — | ⬜ |
| TC-P39 | Batch Generation — Non-Shared Subgroup Activities | Subgroups with both sharing flags false. Each gets standalone `ACT-SG-*` activity | — | — | ⬜ |
| TC-P40 | Batch Generation — Deduplication Avoidance | Running batch generation twice creates only one set of activities (truncate + regenerate). No duplicate `ACT-CG-*` entries | — | — | ⬜ |
| TC-P41 | Batch Generation — Auto `allow_consecutive` For Lab/Practical | Study format name 'lab' triggers `allow_consecutive=true` on generated activity | — | — | ⬜ |
| TC-P42 | Sub-Activity Detail — List All Detail Rows | GET `/sub-activity/{subActivity}/details` returns JSON with `sub_activity_id`, `activity_id`, `count`, `details` array with teacher/room relations | — | — | ⬜ |
| TC-P43 | Sub-Activity Detail — Idempotent Seed | POST `/sub-activity/{subActivity}/details/seed` without `count` parameter. Missing period_number rows created; existing rows untouched. Returns JSON with `created_count` | — | — | ⬜ |
| TC-P44 | Sub-Activity Detail — Seed With Count Override | POST `/sub-activity/{subActivity}/details/seed` with `count=8`. Ensures rows 1..8 exist for the sub-activity | — | — | ⬜ |
| TC-P45 | Sub-Activity Detail — Create Single Detail Row | POST to `/sub-activity/{subActivity}/details` with period_number=1, assigned_teacher_id, assigned_room_id. Row created with auto-computed `assignment_status='FULLY_ASSIGNED'` (teacher + room + no slot still → ROOM_ASSIGNED). Returns JSON 201 | — | — | ⬜ |
| TC-P46 | Sub-Activity Detail — Update Assignment Fields | PATCH `/sub-activity-detail/{detail}` with `assigned_teacher_id`. Only that field updated; existing data preserved. Status auto-recomputed | — | — | ⬜ |
| TC-P47 | Sub-Activity Detail — Soft Delete Row | DELETE `/sub-activity-detail/{detail}`. Row soft-deleted; JSON `{success: true, id}` returned | — | — | ⬜ |
| TC-P48 | Sub-Activity Detail — `recomputeStatus()` Full Chain | Create detail with no assignments → UNASSIGNED. Set teacher → TEACHER_ASSIGNED. Set room only → ROOM_ASSIGNED. Set teacher+room+slot → FULLY_ASSIGNED | — | — | ⬜ |
| TC-P49 | Activity — Parallel Groups Relation Exists | `$activity->parallelGroups()` returns BelongsToMany relation; `isInParallelGroup()` returns boolean; `getParallelGroupActivities()` returns related activity IDs | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing `name` | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `academic_session_id` | Validation error: "The academic session field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `duration_periods` | Validation error: "The duration periods field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `weekly_periods` | Validation error: "The weekly periods field is required." | — | — | ⬜ |
| TC-N06 | Invalid — Both `class_group_jnt_id` And `class_subgroup_id` Set | Provide both target IDs. Controller error: "Select either a Class Group or a Class Subgroup (not both)." | — | — | ⬜ |
| TC-N07 | Invalid — Neither `class_group_jnt_id` Nor `class_subgroup_id` Set | Leave both target fields empty. Controller error: "Select either a Class Group or a Class Subgroup (not both)." | — | — | ⬜ |
| TC-N08 | Invalid — Duplicate `code` On Create | Submit with existing code. Validation error: "The code has already been taken." | — | — | ⬜ |
| TC-N09 | Invalid — `code` Exceeds 50 Characters | Enter 51-character code. Validation error on max:50 | — | — | ⬜ |
| TC-N10 | Invalid — `name` Exceeds 200 Characters | Enter 201-character name. Validation error on max:200 | — | — | ⬜ |
| TC-N11 | Invalid — `description` Exceeds 500 Characters | Enter 501-character description. Validation error on max:500 | — | — | ⬜ |
| TC-N12 | Invalid — `duration_periods` < 1 | Enter 0. Validation error min:1 | — | — | ⬜ |
| TC-N13 | Invalid — `weekly_periods` < 1 | Enter 0. Validation error min:1 | — | — | ⬜ |
| TC-N14 | Invalid — `priority` < 1 | Enter 0. Validation error min:1 | — | — | ⬜ |
| TC-N15 | Invalid — `priority` > 100 | Enter 101. Validation error max:100 | — | — | ⬜ |
| TC-N16 | Invalid — `difficulty_score` < 1 | Enter 0. Validation error min:1 | — | — | ⬜ |
| TC-N17 | Invalid — `difficulty_score` > 100 | Enter 101. Validation error max:100 | — | — | ⬜ |
| TC-N18 | Invalid — Non-Existent `academic_session_id` | Enter 99999. Validation error: "The selected academic session is invalid." | — | — | ⬜ |
| TC-N19 | Invalid — Non-Existent `class_group_jnt_id` | Enter 99999. Validation error: "The selected class group is invalid." | — | — | ⬜ |
| TC-N20 | Invalid — Non-Existent `class_subgroup_id` | Enter 99999. Validation error: "The selected class subgroup is invalid." | — | — | ⬜ |
| TC-N21 | Invalid — Non-Existent `preferred_room_type_id` | Enter 99999. Validation error: "The selected preferred room type is invalid." | — | — | ⬜ |
| TC-N22 | Invalid — Duplicate Teacher In Teachers Array | Submit `teachers[0].teacher_id=1`, `teachers[1].teacher_id=1`. Controller error: "A teacher cannot be assigned more than once." | — | — | ⬜ |
| TC-N23 | Invalid — Teacher `teacher_id` Without `assignment_role_id` | Submit teacher entry with teacher_id but no assignment_role_id. `required_with` validation error | — | — | ⬜ |
| TC-N24 | Invalid — `assignment_role_id` Without `teacher_id` | Submit teacher entry with role but no teacher_id. `required_with` validation error | — | — | ⬜ |
| TC-N25 | Invalid — Non-Existent `teacher_id` In Teachers Array | Enter 99999. Validation error: "The selected teacher is invalid." | — | — | ⬜ |
| TC-N26 | Invalid — Non-Existent `assignment_role_id` | Enter 99999. Validation error: "The selected assignment role is invalid." | — | — | ⬜ |
| TC-N27 | Update — Duplicate code With Own ID Ignored | Update activity keeping same code. Succeeds (unique rule ignores own ID) | — | — | ⬜ |
| TC-N28 | Update — Duplicate code With Another Activity's Code | Change code to match another existing activity. Validation error: "The code has already been taken." | — | — | ⬜ |
| TC-N29 | Destroy LOCKED Activity Blocked | Set status to LOCKED; attempt delete. Redirect back with error "locked_activity_delete_not_allowed" — no delete performed | — | — | ⬜ |
| TC-N30 | Force Delete LOCKED Activity Blocked | Set status to LOCKED; attempt force delete. Redirect back with error message — no force delete performed | — | — | ⬜ |
| TC-N31 | Toggle Status LOCKED → Inactive Blocked | Set status to LOCKED, is_active=true; POST toggle-status with `is_active=false`. JSON 403 `{success: false, message: "..."}` — status not changed | — | — | ⬜ |
| TC-N32 | Toggle Status LOCKED → Active Allowed | Set status to LOCKED, is_active=true; POST toggle-status with `is_active=true`. Succeeds (no-op, same value) | — | — | ⬜ |
| TC-N33 | Batch Generation — No Active Timetable Type | No `TimetableType` with `is_active=true`. Redirect back with error: "No active timetable type found. Please create one first." | — | — | ⬜ |
| TC-N34 | Permission 403 — No `timetable-foundation.activity.viewAny` | User without viewAny → 403 on index route | — | — | ⬜ |
| TC-N35 | Permission 403 — No `timetable-foundation.activity.create` | User without create → 403 on create form and store | — | — | ⬜ |
| TC-N36 | Permission 403 — No `timetable-foundation.activity.update` | User without update → 403 on edit, update, toggleStatus | — | — | ⬜ |
| TC-N37 | Permission 403 — No `timetable-foundation.activity.delete` | User without delete → 403 on destroy | — | — | ⬜ |
| TC-N38 | Permission 403 — No `timetable-foundation.activity.restore` | User without restore → 403 on trash view and restore | — | — | ⬜ |
| TC-N39 | Permission 403 — No `timetable-foundation.activity.forceDelete` | User without forceDelete → 403 on forceDelete | — | — | ⬜ |
| TC-N40 | Permission 403 — No `timetable-foundation.activity.generate` | User without generate → 403 on generateActivities, generateAllActivities | — | — | ⬜ |
| TC-N41 | Guest Access Redirect | Unauthenticated user accessing any activity route → redirected to `/login` | — | — | ⬜ |
| TC-N42 | View Non-Existent Activity (404) | `GET /timetable-foundation/activity/99999` → 404 via `findOrFail` | — | — | ⬜ |
| TC-N43 | Edit Non-Existent Activity (404) | `GET /timetable-foundation/activity/99999/edit` → 404 | — | — | ⬜ |
| TC-N44 | Update Non-Existent Activity (404) | `PATCH /timetable-foundation/activity/99999` → 404 | — | — | ⬜ |
| TC-N45 | Delete Non-Existent Activity (404) | `DELETE /timetable-foundation/activity/99999` → 404 | — | — | ⬜ |
| TC-N46 | Restore Non-Existent Activity (404) | `GET /timetable-foundation/activity/99999/restore` → 404 | — | — | ⬜ |
| TC-N47 | Force Delete Non-Existent Activity (404) | `DELETE /timetable-foundation/activity/99999/force-delete` → 404 | — | — | ⬜ |
| TC-N48 | Toggle Status Non-Existent Activity (404) | `POST /timetable-foundation/activity/99999/toggle-status` → 404 | — | — | ⬜ |
| TC-N49 | Ajax Update Priority Non-Existent Activity (404) | `POST /timetable-foundation/activity/99999/update-priority` → 404 | — | — | ⬜ |
| TC-N50 | Sub-Activity Detail — Store With Non-Existent SubActivity | `POST /sub-activity/99999/details` → 404 via implicit model binding | — | — | ⬜ |
| TC-N51 | Sub-Activity Detail — Seed With Non-Existent SubActivity | `POST /sub-activity/99999/details/seed` → 404 | — | — | ⬜ |
| TC-N52 | Sub-Activity Detail — Update Non-Existent Detail | `PATCH /sub-activity-detail/99999` → 404 | — | — | ⬜ |
| TC-N53 | Sub-Activity Detail — Delete Non-Existent Detail | `DELETE /sub-activity-detail/99999` → 404 | — | — | ⬜ |
| TC-N54 | Sub-Activity Detail — Invalid `period_number` < 1 | Enter 0. Validation error min:1 | — | — | ⬜ |
| TC-N55 | Sub-Activity Detail — Invalid `period_number` > 255 | Enter 300. Validation error max:255 | — | — | ⬜ |
| TC-N56 | Sub-Activity Detail — Invalid `assigned_teacher_id` Non-Existent | Enter 99999. Validation error: "The selected assigned teacher is invalid." | — | — | ⬜ |
| TC-N57 | Sub-Activity Detail — Invalid `assigned_room_id` Non-Existent | Enter 99999. Validation error: "The selected assigned room is invalid." | — | — | ⬜ |
| TC-N58 | Sub-Activity Detail — `assigned_time_slot` Exceeds 50 Characters | Enter 51-char string. Validation error max:50 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Cascade Delete: Activity → SubActivities (CASCADE) | Deleting an activity with sub-activities cascades: hard delete (forceDelete) also force-deletes sub-activities; soft delete soft-deletes sub-activities (model-level cascading or FK CASCADE on hard delete) | — | — | ⬜ |
| TC-D02 | B | Cascade Delete: Activity → ActivityTeachers (CASCADE) | FK `fk_at_activity` ON DELETE CASCADE: deleting parent activity removes all teacher pivot records | — | — | ⬜ |
| TC-D03 | C | Cascade Delete: SubActivity → SubActivityDetails (CASCADE) | FK `fk_subact_detail_subact` ON DELETE CASCADE: deleting a sub-activity removes its detail rows | — | — | ⬜ |
| TC-D04 | D | Cascade Delete: Activity → SubActivityDetails (CASCADE) | FK `fk_subact_detail_activity` ON DELETE CASCADE: deleting parent activity cascades to detail rows | — | — | ⬜ |
| TC-D05 | E | Set Null: Delete Class Group Referenced By Activity | FK `fk_activity_class_group` ON DELETE SET NULL: deleting a `sch_class_groups_jnt` record sets `class_group_id=null` on activity | — | — | ⬜ |
| TC-D06 | F | Set Null: Delete Subject Referenced By Activity | FK `fk_activity_subject` ON DELETE SET NULL: deleting a subject sets `subject_id=null` on activity | — | — | ⬜ |
| TC-D07 | G | Set Null: Delete Study Format Referenced By Activity | FK `fk_activity_study_format` ON DELETE SET NULL: deleting a study format sets `study_format_id=null` | — | — | ⬜ |
| TC-D08 | H | Set Null: Delete Created-By User | FK `fk_activity_created_by` ON DELETE SET NULL: deleting user who created activity sets `created_by=null` | — | — | ⬜ |
| TC-D09 | I | Set Null: Delete Room Referenced By SubActivityDetail | FK `fk_subact_detail_room` ON DELETE SET NULL: deleting a room sets `assigned_room_id=null` on detail rows | — | — | ⬜ |
| TC-D10 | J | Set Null: Delete Teacher Profile Referenced By SubActivityDetail | FK `fk_subact_detail_teacher` ON DELETE SET NULL: deleting teacher profile sets `assigned_teacher_id=null` | — | — | ⬜ |
| TC-D11 | K | Restrict: Delete Academic Term Referenced By Activity | FK `fk_activity_session` ON DELETE RESTRICT: deleting academic term that has activities fails with FK constraint violation | — | — | ⬜ |
| TC-D12 | L | Restrict: Delete Teacher Assignment Role Referenced By ActivityTeacher | FK `fk_at_role` ON DELETE RESTRICT: deleting a role that is assigned to an activity teacher fails | — | — | ⬜ |
| TC-D13 | M | DB Enforced — Unique `uq_activity_code` | Direct DB insert of second activity with same `code` causes integrity constraint violation | — | — | ⬜ |
| TC-D14 | N | DB Enforced — Unique `uq_subact_parent_ord` | Direct DB insert of second sub-activity with same `parent_activity_id` + `ordinal` causes integrity violation | — | — | ⬜ |
| TC-D15 | O | DB Enforced — Unique `uq_at_activity_teacher` | Direct DB insert of duplicate (activity_id, teacher_id) causes integrity violation | — | — | ⬜ |
| TC-D16 | P | DB Enforced — Unique `uq_activity_priority` | Direct DB insert of second priority record for same activity causes integrity violation | — | — | ⬜ |
| TC-D17 | Q | `total_periods` Is Generated Column — Cannot Be Written | Attempting to mass-assign `total_periods` via Eloquent `create()` is ignored (not in `$fillable`); value always computed as `duration_periods * weekly_periods` | — | — | ⬜ |
| TC-D18 | R | Activity model — `$casts` Verification | `have_sub_activity`, `allow_consecutive`, `spread_evenly`, `split_allowed`, `is_compulsory`, `requires_room`, `compulsory_specific_room_type`, `is_active` → boolean; `preferred_periods_json`, `avoid_periods_json`, `preferred_room_ids` → array; `priority`, `difficulty_score` → integer | — | — | ⬜ |
| TC-D19 | S | Activity model — `$fillable` Matches DDL Columns | `$fillable` contains 53 writable columns; `id`, `total_periods`, `created_at`, `updated_at`, `deleted_at` are NOT fillable | — | — | ⬜ |
| TC-D20 | T | Activity model — SoftDeletes Trait | `delete()` sets `deleted_at`; `restore()` nullifies; `withTrashed()` includes soft-deleted; `onlyTrashed()` filters to deleted only | — | — | ⬜ |
| TC-D21 | U | Activity model — belongsTo Relationships | 12 `belongsTo` relationships defined: academicTerm, timetableType, classGroup, classSubgroup, class, section, subject, studyFormat, subjectStudyFormat, subjectType, requiredRoomType, requiredRoom, preferredRoomType; each loads correct parent model | — | — | ⬜ |
| TC-D22 | V | Activity model — hasMany Relationships | `teachers()` → hasMany ActivityTeacher; `subActivities()` → hasMany SubActivity (ordered by ordinal); `details()` → hasMany SubActivityDetail (ordered by period_number); `directDetails()` → same but whereNull('sub_activity_id') | — | — | ⬜ |
| TC-D23 | W | Activity model — hasOne ActivityPriority | `activityPriority()` returns single ActivityPriority record; 1:1 relationship enforced by `uq_activity_priority` unique key | — | — | ⬜ |
| TC-D24 | X | Activity model — `scopeByDifficulty()` | `Activity::byDifficulty()` emits `ORDER BY difficulty_score DESC, priority DESC` | — | — | ⬜ |
| TC-D25 | Y | Activity model — `schedulingScore()` Helper | Returns `(difficulty_score × 2) + constraint_count - min_teacher_availability_score - room_availability_score` | — | — | ⬜ |
| TC-D26 | Z | Activity model — `statusBadgeClass()` and `statusLabel()` | `statusBadgeClass('ACTIVE')` returns 'bg-success'; `statusLabel('ACTIVE')` returns 'Active'. Handles DRAFT, ACTIVE, LOCKED, ARCHIVED plus extra statuses (PENDING, INACTIVE, SCHEDULED, COMPLETED) with fallback | — | — | ⬜ |
| TC-D27 | AA | SubActivity model — belongsTo Relationships | `parentActivity()` → Activity; `class()` → SchoolClass; `section()` → Section; `classRequirementSubgroup()` → ClassRequirementSubgroup | — | — | ⬜ |
| TC-D28 | AB | SubActivity model — hasMany Details | `details()` → hasMany SubActivityDetail (ordered by period_number); each detail has `(sub_activity_id, period_number)` uniqueness | — | — | ⬜ |
| TC-D29 | AC | SubActivityDetail model — `recomputeStatus()` Logic | UNASSIGNED (no fields) → TEACHER_ASSIGNED (teacher only) → ROOM_ASSIGNED (room only, no teacher) → FULLY_ASSIGNED (teacher + room + time_slot) | — | — | ⬜ |
| TC-D30 | AD | ActivityTeacher model — belongsTo Relationships | `activity()` → Activity; `teacher()` → Teacher; `assignmentRole()` → TeacherAssignmentRole; `isPrimary()` returns true when role has `is_primary_instructor=true` | — | — | ⬜ |
| TC-D31 | AE | ActivityPriority model — Priority Level Helpers | `isHighPriority()` returns true when score ≥ 75; `isMediumPriority()` when 50–74.99; `isLowPriority()` when < 50; `priorityLevel()` returns 'High'/'Medium'/'Low'; `priorityBadgeClass()` returns 'bg-danger'/'bg-warning'/'bg-info' accordingly | — | — | ⬜ |
| TC-D32 | AF | Integration — Controller `findOrFail` Returns 404 For Invalid IDs | All seven activity methods + five sub-activity-detail methods throw `ModelNotFoundException` → HTTP 404 when ID does not exist | — | — | ⬜ |
| TC-D33 | AG | Integration — Controller `Gate::authorize()` Before All Methods | Every controller action calls `Gate::authorize()` with matching permission before executing logic; without permission → 403 | — | — | ⬜ |
| TC-D34 | AH | Integration — Activity Logged After CRUD | `activityLog()` called on store ('Stored'), update ('Updated'), destroy ('Trashed'), restore ('Restored'), forceDelete ('Deleted'), toggleStatus ('Toggled') | — | — | ⬜ |
| TC-D35 | AI | Integration — `store()` DB Transaction Rollback On Exception | If any exception occurs during store, `DB::transaction()` rolls back; no partial data persists | — | — | ⬜ |
| TC-D36 | AJ | Integration — `update()` DB Transaction Rollback On Exception | Same rollback behavior on update; teacher re-sync + activity update are atomic | — | — | ⬜ |
| TC-D37 | AK | Integration — `destroy()` DB Transaction Rollback | Deactivate → teacher delete → activity delete wrapped in transaction; any failure rolls all back | — | — | ⬜ |
| TC-D38 | AL | Integration — `generateActivities()` Transaction Rollback On Exception | On any exception during batch generation, `DB::rollBack()` called; truncation happens BEFORE transaction (DDL), so activities are still cleared on failure | — | — | ⬜ |
| TC-D39 | AM | Integration — Index Redirect | `GET /timetable-foundation/activity` redirects (302) to `GET /timetable-foundation/menu/timetablePreparation?tab=activity` | — | — | ⬜ |
| TC-D40 | AN | Unit — `assignTeacherToActivity()` Skips When No Eligible Teachers | If `TeacherAvailability` query returns empty, method returns void without creating any `ActivityTeacher` records | — | — | ⬜ |
| TC-D41 | AO | Unit — `isLabOrPractical()` Returns True For Lab/Practical/Workshop | StudyFormat name matching 'lab', 'practical', or 'workshop' (case-insensitive) returns true; others return false | — | — | ⬜ |
| TC-D42 | AP | Unit — `getRoomCapacity()` Fallback Chain | 1. Class-specific room → 2. Room type average → 3. Global median → 4. Default 50 | — | — | ⬜ |
| TC-D43 | AQ | Unit — `calculateGroupsNeeded()` | students ≤ capacity → 1; students ≤ capacity × 2 → 2; else → 3 | — | — | ⬜ |
| TC-D44 | AR | Integration — SubActivityDetail Update Only Touches Present Fields | PATCH with only `assigned_teacher_id` does not clear `assigned_room_id` or `assigned_time_slot` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Activity model — `$fillable` matches DDL columns (mass-assignment protection) | `$fillable` array contains 53 writable columns from `tt_activities`; `id`, `total_periods` (generated), `created_at`, `updated_at`, `deleted_at` NOT fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Activity model — `$casts` for booleans/integers/decimals/dates | All TINYINT(1) flags → boolean; JSON columns → array; integer columns → integer; availability scores → decimal:2; timestamps → datetime | — | — | ◌ |
| TC-CR03 | CR | P1 | Activity model — SoftDeletes trait correctly implemented | `use SoftDeletes;` in model; `delete()` sets `deleted_at`; `restore()` nullifies; `forceDelete()` permanently removes | — | — | ◌ |
| TC-CR04 | CR | P1 | Activity model — relationships defined (belongsTo/hasMany/hasOne per FK) | 12 belongsTo (academicTerm, timetableType, classGroup, classSubgroup, class, section, subject, studyFormat, subjectStudyFormat, subjectType, requiredRoomType, preferredRoomType), 3 hasMany (teachers, subActivities, details), 1 hasOne (activityPriority), 1 belongsToMany (parallelGroups) | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — try-catch exception handling on all write methods | `generateActivities()` uses try-catch with rollback; `store()`, `update()`, `destroy()` use `DB::transaction()` with automatic rollback; `toggleStatus()` has save check returning JSON error on failure | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | `store()`, `update()`, `destroy()` use `DB::transaction()`; `generateActivities()` uses explicit `beginTransaction`/`commit`/`rollBack` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Every controller action checks its permission before processing; `generateActivities()` and `generateAllActivities()` use `timetable-foundation.activity.generate` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called in `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()` with appropriate event name and context | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false`, `status=ARCHIVED` before soft delete; restore sets `is_active=true`, `status=ACTIVE` | `destroy()` sets both flags before `delete()`; `restore()` sets both back after `restore()` | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` actually flips `is_active` | `toggleStatus()` receives boolean `is_active`, sets `$activity->is_active`, saves, returns JSON with new value | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedActivity()` uses `onlyTrashed()->orderBy('name')->paginate(10)`; `restore($id)` uses `onlyTrashed()->findOrFail($id)`; `forceDelete($id)` uses `withTrashed()->findOrFail($id)` with LOCKED guard | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — redirect/JSON response after create/update/delete | `store()`/`update()`/`destroy()` → redirect to timetable preparation tab with success flash; `toggleStatus()` → JSON `{success, is_active, message}`; `restore()`/`forceDelete()` → redirect to trash view; SubActivityDetail endpoints → JSON `{success, ...}` | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — validation rules cover all fields; unique rules ignore current ID on update | `store()` validates 20+ fields inline; `update()` uses `Rule::unique('tt_activities','code')->ignore($activity->id)`; controller checks mutually exclusive target and duplicate teachers | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — permission strings match route/gate names | No dedicated ActivityPolicy; gates use string-based `Gate::authorize('timetable-foundation.activity.*')` directly in controller; sub-activity-detail uses `timetable-foundation.sub-activity-detail.*` | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | Resource route for `activity` + custom routes for trash/restore/forceDelete/toggleStatus/update-priority/generate/generate-all/generation-progress; SubActivityDetail routes for index/seed/store/update/destroy; implicit model binding on `{activity}`, `{subActivity}`, `{subActivityDetail}` throws 404 | — | — | ◌ |
| TC-CR16 | CR | P1 | Database — unique indexes match validation rules | `uq_activity_code` matches unique code validation; `uq_subact_parent_ord` matches nature of unique ordinal per parent; `uq_at_activity_teacher` prevents duplicate teacher assignments; `uq_activity_priority` ensures 1:1 priority per activity | — | — | ◌ |
| TC-CR17 | CR | P1 | SubActivityDetail model — `recomputeStatus()` auto-calculates assignment status | After any mutation, `assignment_status` is recomputed: UNASSIGNED when none set; TEACHER_ASSIGNED when teacher only; ROOM_ASSIGNED when room only; FULLY_ASSIGNED when teacher+room+slot | — | — | ◌ |
| TC-CR18 | CR | P1 | SubActivityDetail model — only present fields updated in PATCH | `update()` loops only `$request->has($field)` keys; absent fields not overwritten, preserving stored data | — | — | ◌ |
| TC-CR19 | CR | P1 | SubActivityDetail Seeder — idempotent seeding | `seedForSubActivity()` checks existing `(sub_activity_id, period_number)` before insert; uses `DB::table(...)->insert()` for bulk efficiency | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Activity Model — `$fillable` Matches DDL Columns (Mass-Assignment Protection)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Activity.php` model | Model found in `Modules/TimetableFoundation/Models/` |
| 2 | Inspect `$fillable` array | Contains all 53 writable columns from DDL: code through created_by |
| 3 | Verify `total_periods` NOT in `$fillable` | Generated column omitted |
| 4 | Verify all foreign key columns are fillable | academic_term_id, timetable_type_id, class_group_id, etc. all present |

#### TC-CR02: Activity Model — `$casts` for Booleans/Integers/Decimals/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `$casts` property | all TINYINT(1) flags cast to boolean; JSON columns to array; integers to integer; availability scores to decimal:2 |
| 2 | Create activity and fetch it | All cast fields return correct PHP types |

#### TC-CR03: Activity Model — SoftDeletes Trait Correctly Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model for `use SoftDeletes` | Trait present |
| 2 | Soft delete an activity | `deleted_at` set; record excluded from normal queries |
| 3 | Query with `onlyTrashed()` | Only soft-deleted records appear |
| 4 | Restore | `deleted_at` nullified; record visible again |

#### TC-CR04: Activity Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `academicTerm()` | `belongsTo(AcademicTerm::class, 'academic_term_id')` |
| 2 | Inspect `timetableType()` | `belongsTo(TimetableType::class, 'timetable_type_id')` |
| 3 | Inspect `teachers()` | `hasMany(ActivityTeacher::class, 'activity_id')` |
| 4 | Inspect `subActivities()` | `hasMany(SubActivity::class, 'parent_activity_id')->orderBy('ordinal')` |
| 5 | Inspect `activityPriority()` | `hasOne(ActivityPriority::class, 'activity_id')` |
| 6 | Inspect `details()` | `hasMany(SubActivityDetail::class, 'activity_id')->orderBy('period_number')` |
| 7 | Inspect `directDetails()` | Same as details but `whereNull('sub_activity_id')` |
| 8 | Inspect `parallelGroups()` | `belongsToMany(ParallelGroup::class, 'tt_parallel_group_activity', ...)` |

#### TC-CR05: Controller — Try-Catch Exception Handling on All Write Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `generateActivities()` | Try-catch wraps all logic; catch calls `DB::rollBack()`, logs error, returns redirect back with error message |
| 2 | Inspect `store()` | `DB::transaction()` provides automatic rollback |
| 3 | Inspect `update()` | Same transaction pattern |
| 4 | Inspect `destroy()` | Same transaction pattern |
| 5 | Inspect `toggleStatus()` | Save check returns JSON error on failure; no transaction (single field update) |

#### TC-CR06: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | `DB::transaction(function() use (...) { ... })` wraps activity create + teacher pivot creation |
| 2 | Inspect `update()` | `DB::transaction()` wraps activity update + teacher delete + recreate |
| 3 | Inspect `destroy()` | `DB::transaction()` wraps deactivate + teacher delete + activity delete |
| 4 | Inspect `generateActivities()` | Explicit `DB::beginTransaction()` + `DB::commit()` / `DB::rollBack()` |

#### TC-CR07: Controller — `Gate::authorize()` on Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `index()` | `Gate::authorize('timetable-foundation.activity.viewAny')` |
| 2 | Inspect `create()` | `Gate::authorize('timetable-foundation.activity.create')` |
| 3 | Inspect `store()` | `Gate::authorize('timetable-foundation.activity.create')` |
| 4 | Inspect `show()` | `Gate::authorize('timetable-foundation.activity.view')` |
| 5 | Inspect `edit()` | `Gate::authorize('timetable-foundation.activity.update')` |
| 6 | Inspect `update()` | `Gate::authorize('timetable-foundation.activity.update')` |
| 7 | Inspect `destroy()` | `Gate::authorize('timetable-foundation.activity.delete')` |
| 8 | Inspect `trashedActivity()` | `Gate::authorize('timetable-foundation.activity.restore')` |
| 9 | Inspect `restore()` | `Gate::authorize('timetable-foundation.activity.restore')` |
| 10 | Inspect `forceDelete()` | `Gate::authorize('timetable-foundation.activity.forceDelete')` |
| 11 | Inspect `toggleStatus()` | `Gate::authorize('timetable-foundation.activity.update')` |
| 12 | Inspect `generateActivities()` | `Gate::authorize('timetable-foundation.activity.generate')` |
| 13 | Inspect SubActivityDetailController methods | Each has matching `Gate::authorize('timetable-foundation.sub-activity-detail.*')` |

#### TC-CR08: Controller — Activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | `activityLog($activity, 'Stored', ...)` with message and auth()->id() |
| 2 | Inspect `update()` | `activityLog($activity, 'Updated', ...)` |
| 3 | Inspect `destroy()` | `activityLog($activity, 'Trashed', ['message' => 'Activity was archived, deactivated, and moved to trash.'])` |
| 4 | Inspect `restore()` | `activityLog($activity, 'Restored', ['message' => 'Activity was restored successfully.'])` |
| 5 | Inspect `forceDelete()` | `activityLog($activity, 'Deleted', ['message' => 'Activity was permanently deleted.'])` |
| 6 | Inspect `toggleStatus()` | `activityLog($activity, 'Toggled', ['message' => 'Activity status was updated.', 'is_active' => ...])` |

#### TC-CR09: Controller — `is_active=false`, `status=ARCHIVED` Before Soft Delete; Restore Sets Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `$activity->update(['is_active' => false, 'status' => 'ARCHIVED'])` called before `$activity->delete()` |
| 2 | Inspect `restore()` | `$activity->restore()` then `$activity->is_active = true; $activity->status = 'ACTIVE'; $activity->save()` |
| 3 | Create, delete, restore an activity | After restore: `is_active=1`, `status='ACTIVE'`, `deleted_at=null` |

#### TC-CR10: Controller — `toggleStatus()` Flips `is_active`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` | Receives `is_active` boolean; sets `$activity->is_active = $request->boolean('is_active')`; saves |
| 2 | Verify LOCKED guard | If status is LOCKED and `is_active=false`, returns JSON 403 with `success=false` |
| 3 | Verify success response | Returns `response()->json(['success' => true, 'is_active' => ..., 'message' => flash(...)])` |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedActivity()` | `Activity::onlyTrashed()->orderBy('name')->paginate(10)` |
| 2 | Inspect `restore($id)` | `Activity::onlyTrashed()->findOrFail($id)` → restore → reactivate |
| 3 | Inspect `forceDelete($id)` | `Activity::withTrashed()->findOrFail($id)` → LOCKED guard → forceDelete |

#### TC-CR12: Controller — Redirect/JSON Response After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` success | `redirect()->route('timetable-foundation.menu.timetablePreparation', ['tab' => 'activity'])->with('success', flash('created.activity'))` |
| 2 | Inspect `update()` success | Same redirect with `flash('updated.activity')` |
| 3 | Inspect `destroy()` success | Same redirect with `flash('deleted.activity')` |
| 4 | Inspect `toggleStatus()` | JSON `{success, is_active, message}` |
| 5 | Inspect `restore()` success | `redirect()->route('timetable-foundation.activity.trashed')->with('success', flash('restored.activity'))` |
| 6 | Inspect SubActivityDetail JSON | All endpoints return JSON `{success: true, ...}` with HTTP 201 for store |

#### TC-CR13: Controller — Validation Rules Cover All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ActivityController.php` | Controller found |
| 2 | Inspect `store()` validate block | All identity, academic, target, load, heuristic, flag, room, status, teacher fields validated |
| 3 | Inspect `update()` validate block | Same fields + `Rule::unique()->ignore($activity->id)` for code |
| 4 | Verify mutual exclusion check | Controller checks exactly one of class_group_jnt_id/class_subgroup_id |
| 5 | Verify duplicate teacher check | Controller checks `$teachersInput->pluck('teacher_id')->duplicates()` |

#### TC-CR14: Policy — Permission Strings Match Gate Names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Gate::authorize()` calls | All use `'timetable-foundation.activity.{action}'` pattern matching expected permission names |
| 2 | Inspect SubActivityDetailController | Uses `'timetable-foundation.sub-activity-detail.{action}'` pattern |

#### TC-CR15: Routes — Resource + Custom Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | Route group for timetable-foundation found |
| 2 | Verify activity resource | `Route::resource('activity', ActivityController::class)` with all 7 resource methods |
| 3 | Verify custom routes | `trash/view` (GET), `{id}/restore` (GET), `{id}/force-delete` (DELETE), `{activity}/toggle-status` (POST), `{activity}/update-priority` (POST), `requirements/generate-activities/all` (POST), `class-group-requirements/generate-all` (POST), `class-group-requirements/generation-progress` (GET) |
| 4 | Verify sub-activity-detail routes | Nested under `sub-activity/{subActivity}/details` + direct `sub-activity-detail/{subActivityDetail}` |
| 5 | Verify implicit model binding | `{activity}`, `{subActivity}`, `{subActivityDetail}` auto-resolve; invalid IDs → 404 |

#### TC-CR16: Database — Unique Indexes Match Validation Rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `uq_activity_code` in DDL | UNIQUE KEY on `code` matches validation `unique:tt_activities,code` |
| 2 | Verify `uq_subact_parent_ord` | UNIQUE KEY on `(parent_activity_id, ordinal)` matches nature of ordered sub-activities |
| 3 | Verify `uq_at_activity_teacher` | UNIQUE KEY on `(activity_id, teacher_id)` matches "same teacher cannot be assigned more than once" |
| 4 | Verify `uq_activity_priority` | UNIQUE KEY on `activity_id` enforces 1:1 priority per activity |

#### TC-CR17: SubActivityDetail Model — `recomputeStatus()` Auto-Calculates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create detail row with no assignments | `assignment_status = 'UNASSIGNED'` |
| 2 | Set `assigned_teacher_id` only | Status becomes `TEACHER_ASSIGNED` |
| 3 | Set `assigned_room_id` only | Status becomes `ROOM_ASSIGNED` |
| 4 | Set `assigned_teacher_id + assigned_room_id + assigned_time_slot` | Status becomes `FULLY_ASSIGNED` |

#### TC-CR18: SubActivityDetail Controller — Only Present Fields Updated in PATCH

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `update()` | `foreach(['assigned_teacher_id','assigned_room_id','assigned_time_slot','is_active'])` — only fills keys where `$request->has($field)` |
| 2 | PATCH with only `assigned_teacher_id` | `assigned_room_id` and `assigned_time_slot` preserved unchanged |

#### TC-CR19: SubActivityDetail Seeder — Idempotent Seeding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `SubActivityDetailSeeder::seedForSubActivity()` | Queries existing `(sub_activity_id, period_number)` combinations; skips existing; inserts only missing |
| 2 | Run seed twice | First run creates N rows; second run creates 0 new rows |

---

### 7.1 Positive TC Steps

#### TC-P10: Create Activity With Required Fields Only (Class Group Target)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with all activity permissions | Dashboard loads |
| 2 | Navigate to Timetable Preparation → Activity tab | Tab pane visible |
| 3 | Click "Create Activity" button | Navigate to `GET /timetable-foundation/activity/create` (or modal opens) |
| 4 | Enter `code="ACT-TC-20260718001"` | Code field filled |
| 5 | Enter `name="Test Activity 001"` | Name field filled |
| 6 | Select a valid `academic_session_id` from dropdown | Session selected |
| 7 | Select a valid `class_group_jnt_id` from dropdown | Class group selected |
| 8 | Enter `duration_periods=1` | Duration field filled |
| 9 | Enter `weekly_periods=5` | Weekly periods filled |
| 10 | Click "Save" or "Create" button | POST to `/timetable-foundation/activity` |
| 11 | Verify redirect | Redirected to `GET /timetable-foundation/menu/timetablePreparation?tab=activity` with success flash message |
| 12 | Verify DB record | `SELECT * FROM tt_activities WHERE code='ACT-TC-20260718001'` exists with `status='ACTIVE'`, `is_active=1` |

#### TC-P11: Create Activity With Class Subgroup Target

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter code, name, session, duration, weekly periods | Basic fields filled |
| 3 | Select a valid `class_subgroup_id` instead of class_group_jnt_id | Subgroup selected |
| 4 | Leave `class_group_jnt_id` empty | No group selected |
| 5 | Submit | Activity created with `class_subgroup_id` set, `class_group_id=null` |

#### TC-P12: Create Activity With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter code="ACT-TC-FULL-001", name="Full Test" | Identity filled |
| 3 | Select session, class group, duration=2, weekly=3 | Academic + load filled |
| 4 | Set priority=80, difficulty_score=60 | Heuristics filled |
| 5 | Toggle split_allowed=ON, is_compulsory=ON, requires_room=ON | Flags set |
| 6 | Select preferred_room_type_id from dropdown | Room preference set |
| 7 | Toggle is_active=ON | Active flag set |
| 8 | Submit | Activity created with all values persisted correctly in DB |

#### TC-P16: Create Activity With Teacher Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill activity basic fields | Required fields set |
| 3 | In the teachers section, add Teacher A with role=PRIMARY (ordinal=1, is_required=true) | Teacher A added |
| 4 | Add Teacher B with role=ASSISTANT (ordinal=2, is_required=false) | Teacher B added |
| 5 | Submit | Activity created; two `tt_activity_teachers` records exist with correct role IDs, ordinals, and is_required values |

#### TC-P20: Update Activity Code And Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to activity list | Activities displayed |
| 2 | Click Edit on activity "ACT-TC-001" | Edit form loads with pre-filled values |
| 3 | Change code to "ACT-TC-001-UPD", name to "Updated Activity" | Fields modified |
| 4 | Submit update | PATCH to `/timetable-foundation/activity/{id}` |
| 5 | Verify redirect | Redirect to activity tab with success message |
| 6 | Verify DB: code='ACT-TC-001-UPD', name='Updated Activity' | Updated correctly |

#### TC-P25: Ajax Update Priority

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an activity exists with priority=50 | Activity with default priority |
| 2 | POST to `/timetable-foundation/activity/{activity}/update-priority` with `priority=85` | Request accepted |
| 3 | Verify DB: `priority=85` for that activity | Priority updated |
| 4 | Verify activity list shows updated priority badge | Badge reflects new value |

#### TC-P26: Soft Delete Active Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an active activity exists (status=ACTIVE, is_active=1) | Activity exists |
| 2 | Click Delete action for that activity | DELETE to `/timetable-foundation/activity/{id}` |
| 3 | Verify `is_active=0`, `status='ARCHIVED'` in DB | Flags updated |
| 4 | Verify teacher pivots soft-deleted | `tt_activity_teachers` records have `deleted_at` set |
| 5 | Verify `deleted_at` set on activity | Activity soft-deleted |
| 6 | Verify redirect to activity tab with success message | Flash: `deleted.activity` |

#### TC-P28: Restore Soft-Deleted Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view: `GET /timetable-foundation/activity/trash/view` | Trashed activities listed |
| 2 | Click Restore for a trashed activity | GET to `/timetable-foundation/activity/{id}/restore` |
| 3 | Verify redirect back to trash view | Success flash `restored.activity` |
| 4 | Verify DB: `deleted_at=null`, `is_active=1`, `status='ACTIVE'` | Activity fully restored and reactivated |

#### TC-P35: Batch Generation — Class Group Requirements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure RequirementConsolidation records exist with class_requirement_group_id set, academic_term_id set | Requirements exist |
| 2 | Ensure active TimetableType exists | TimetableType with is_active=1 |
| 3 | POST to `/timetable-foundation/requirements/generate-activities/all` | Generation triggered |
| 4 | Wait for completion | Redirect back with success message: "Activities generated successfully. Created: N, Consolidated: M, Total in DB: T, Skipped: S" |
| 5 | Verify activities created in DB | Activities with code pattern `ACT-CG-*` exist |
| 6 | Verify scores calculated | `teacher_availability_score`, `room_availability_score`, `difficulty_score_calculated` populated |
| 7 | Verify teachers assigned | `tt_activity_teachers` records created for eligible teachers |

#### TC-P36: Batch Generation — Shared Across Classes Consolidation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create subgroups with `is_shared_across_classes=true` for same subject across multiple classes | Subgroups exist |
| 2 | POST to generate-activities | Shared-across-classes activity created with `ACT-SAC-*` code |
| 3 | Verify sub-activities created per class | `tt_sub_activities` records exist, one per original class, linked to the parent activity |

#### TC-P43: Sub-Activity Detail — Idempotent Seed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a sub-activity exists with no detail rows | Empty details |
| 2 | POST `/sub-activity/{subActivity}/details/seed` without `count` | Rows 1..N created where N = parent activity's `required_weekly_periods` |
| 3 | Verify JSON response | `{success: true, created_count: N, sub_activity_id: ...}` |
| 4 | POST the same seed request again | `created_count: 0` (no new rows — idempotent) |

#### TC-P45: Sub-Activity Detail — Create Single Detail Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a sub-activity exists | Sub-activity in DB |
| 2 | POST `/sub-activity/{subActivity}/details` with period_number=1, assigned_teacher_id=valid, assigned_room_id=valid | Row created with HTTP 201 |
| 3 | Verify JSON response | `{success: true, detail: {period_number: 1, assignment_status: "ROOM_ASSIGNED", ...}}` |
| 4 | Verify DB: `assignment_status` auto-computed | Status = ROOM_ASSIGNED (room set, teacher set, but no time_slot) |

#### TC-P48: Sub-Activity Detail — `recomputeStatus()` Full Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create detail row with no assignments | `assignment_status = 'UNASSIGNED'` |
| 2 | PATCH with only `assigned_teacher_id` | Status changes to `TEACHER_ASSIGNED` |
| 3 | PATCH with only `assigned_room_id` (teacher cleared) | Status changes to `ROOM_ASSIGNED` |
| 4 | PATCH with teacher + room + time_slot all set | Status changes to `FULLY_ASSIGNED` |

---

### 7.2 Negative TC Steps

#### TC-N06: Invalid — Both `class_group_jnt_id` And `class_subgroup_id` Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill required fields (code, name, session, duration, weekly) | Basic fields filled |
| 3 | Select both a class_group_jnt_id and a class_subgroup_id | Both targets selected |
| 4 | Submit | Form returns with error: "Select either a Class Group or a Class Subgroup (not both)." |
| 5 | Verify no activity created | No new record in tt_activities |

#### TC-N07: Invalid — Neither `class_group_jnt_id` Nor `class_subgroup_id` Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill required fields except targets | Basic fields filled |
| 3 | Leave both class_group_jnt_id and class_subgroup_id empty | No target selected |
| 4 | Submit | Same error: "Select either a Class Group or a Class Subgroup (not both)." |

#### TC-N08: Invalid — Duplicate `code` On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create activity with code="DUP-TEST" | First activity created |
| 2 | Open create form | New form |
| 3 | Enter code="DUP-TEST" (same code) | Duplicate code |
| 4 | Fill other required fields | Fields filled |
| 5 | Submit | Validation error: "The code has already been taken." |

#### TC-N22: Invalid — Duplicate Teacher In Teachers Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill basic activity fields | Required fields set |
| 3 | Add Teacher A (teacher_id=1) twice in teachers array | Same teacher listed twice |
| 4 | Submit | Controller error: "A teacher cannot be assigned more than once." |

#### TC-N29: Destroy LOCKED Activity Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually set an activity's `status='LOCKED'` via DB | Activity locked |
| 2 | Attempt to delete the LOCKED activity via UI/API | Redirect back with error `flash('locked_activity_delete_not_allowed')` |
| 3 | Verify DB: `deleted_at` still null | Record not deleted |

#### TC-N31: Toggle Status LOCKED → Inactive Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set activity `status='LOCKED'`, `is_active=1` | Activity locked and active |
| 2 | POST to `/timetable-foundation/activity/{activity}/toggle-status` with `is_active=0` | JSON 403 response: `{success: false, is_active: true, message: flash('locked_activity_disable_not_allowed')}` |
| 3 | Verify DB: `is_active` still 1 | Status unaffected |

#### TC-N33: Batch Generation — No Active Timetable Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set all TimetableType records to `is_active=0` | No active type |
| 2 | POST to `/timetable-foundation/requirements/generate-activities/all` | Redirect back with error: "No active timetable type found. Please create one first." |
| 3 | Verify no activities created | `tt_activities` empty or unchanged |

#### TC-N34 to TC-N40: Permission Tests

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N34 | Login as user WITHOUT `timetable-foundation.activity.viewAny` → access index | 403 Forbidden |
| TC-N35 | User WITHOUT `timetable-foundation.activity.create` → access create/store | 403 Forbidden |
| TC-N36 | User WITHOUT `timetable-foundation.activity.update` → access edit/update/toggleStatus | 403 Forbidden |
| TC-N37 | User WITHOUT `timetable-foundation.activity.delete` → access destroy | 403 Forbidden |
| TC-N38 | User WITHOUT `timetable-foundation.activity.restore` → access trash/restore | 403 Forbidden |
| TC-N39 | User WITHOUT `timetable-foundation.activity.forceDelete` → access forceDelete | 403 Forbidden |
| TC-N40 | User WITHOUT `timetable-foundation.activity.generate` → access generateActivities | 403 Forbidden |

#### TC-N41: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (unauthenticated) | Guest session |
| 2 | Try accessing any activity route (index, create, etc.) | Redirected to `/login` |

#### TC-N42 to TC-N49: Non-Existent IDs (404)

| TC ID | Step 1: Action | Step 2: Expected Result |
|-------|----------------|-------------------------|
| TC-N42 | `GET /timetable-foundation/activity/99999` | 404 Not Found |
| TC-N43 | `GET /timetable-foundation/activity/99999/edit` | 404 Not Found |
| TC-N44 | `PATCH /timetable-foundation/activity/99999` with valid data | 404 Not Found |
| TC-N45 | `DELETE /timetable-foundation/activity/99999` | 404 Not Found |
| TC-N46 | `GET /timetable-foundation/activity/99999/restore` | 404 Not Found |
| TC-N47 | `DELETE /timetable-foundation/activity/99999/force-delete` | 404 Not Found |
| TC-N48 | `POST /timetable-foundation/activity/99999/toggle-status` | 404 Not Found |
| TC-N49 | `POST /timetable-foundation/activity/99999/update-priority` | 404 Not Found |

---

### 7.3 Dependency TC Steps

#### TC-D01: Cascade Delete — Activity → SubActivities (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an activity with 2 sub-activities | Activity + sub-activities exist |
| 2 | Force delete the parent activity | `$activity->forceDelete()` permanently removes parent |
| 3 | Query sub-activities (including trashed) | Sub-activities also permanently removed (FK CASCADE) |
| 4 | Create another activity with sub-activities | New data created |
| 5 | Soft delete the parent activity | Activity soft-deleted; sub-activities also soft-deleted (model events or FK CASCADE on hard delete only) |
| 6 | Verify sub-activities still soft-deleted | `tt_sub_activities` shows `deleted_at` for child records |

#### TC-D11: Restrict — Delete Academic Term Referenced By Activity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an academic term with existing activities | Term has `tt_activities` records |
| 2 | Attempt to delete that academic term directly via DB | FK constraint violation: `fk_activity_session` RESTRICT prevents deletion |
| 3 | Delete the activities first | Activities removed |
| 4 | Retry deleting the academic term | Deletion succeeds (no referencing activities left) |

#### TC-D13: DB Enforced — Unique `uq_activity_code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create activity with code="UNIQUE-TEST" | Activity exists |
| 2 | Direct DB insert: `INSERT INTO tt_activities(code, name, ...) VALUES('UNIQUE-TEST', 'Duplicate', ...)` | Integrity constraint violation: Duplicate entry 'UNIQUE-TEST' for key 'uq_activity_code' |

#### TC-D18: Activity Model — `$casts` Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch an activity from DB | All boolean fields return `true`/`false` (not 0/1) |
| 2 | Check `have_sub_activity` | Returns boolean |
| 3 | Check `allow_consecutive` | Returns boolean |
| 4 | Check `preferred_periods_json` | Returns array (decoded from JSON), null if DB value null |
| 5 | Check `priority` | Returns integer |

#### TC-D24: Activity Model — `scopeByDifficulty()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create activities with different difficulty scores and priorities | Multiple activities exist |
| 2 | Call `Activity::byDifficulty()->get()` | Results ordered by `difficulty_score DESC`, then `priority DESC` |

#### TC-D31: ActivityPriority Model — Priority Level Helpers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ActivityPriority with `priority_score=80` | `isHighPriority()` returns true; `priorityLevel()` returns 'High'; `priorityBadgeClass()` returns 'bg-danger' |
| 2 | Create ActivityPriority with `priority_score=65` | `isMediumPriority()` returns true; `priorityLevel()` returns 'Medium'; `priorityBadgeClass()` returns 'bg-warning' |
| 3 | Create ActivityPriority with `priority_score=30` | `isLowPriority()` returns true; `priorityLevel()` returns 'Low'; `priorityBadgeClass()` returns 'bg-info' |

#### TC-D44: SubActivityDetail Update Only Touches Present Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a detail row with teacher_id=1, room_id=2, time_slot="MON-P1" | All three fields populated; status = FULLY_ASSIGNED |
| 2 | PATCH with only `{assigned_teacher_id: 5}` | Only teacher field updated to 5; room_id remains 2; time_slot remains "MON-P1" |
| 3 | Verify `assigned_room_id` unchanged | Still 2 (not wiped to null) |
| 4 | Verify status recomputed | Changes to ROOM_ASSIGNED (teacher updated, but room still set, slot still set → ROOM_ASSIGNED because recomputeStatus checks absence — room presence keeps it ROOM_ASSIGNED despite new teacher) |
