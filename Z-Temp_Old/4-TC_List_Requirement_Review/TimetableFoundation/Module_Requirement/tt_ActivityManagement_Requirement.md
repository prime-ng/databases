# Activity Management — Business Requirements

## What This Screen Does

Activity Management is the core of timetable preparation within the Timetable Foundation module. An activity represents a single teaching assignment — a specific subject taught to a defined class–section combination for a particular study format (lecture, lab, tutorial, practical, etc.) with a prescribed number of weekly periods and associated constraints.

Activities form the bridge between curriculum requirements (what needs to be taught) and timetable generation (when and where it is scheduled). Each activity encapsulates the subject and study format, the target class group or subgroup, the required weekly periods and duration, teacher assignments with roles, scheduling constraints (consecutive, spread, room type, preferred or avoided periods), priority and difficulty scores that drive solver behaviour, and sub-activity decomposition for merged classes or section-sharing scenarios.

Activities can be generated in batch from RequirementConsolidation records, created individually, split into sub-activities for granular planning, assigned to teachers, and prioritised to influence automated scheduling.

---

## When This Screen Is Used

- **Curriculum coordinators** define class–subject–format combinations and trigger batch generation of activities from requirement consolidation data at the start of an academic term
- **Academic heads / timetable administrators** manually create activities for subjects that need individual handling, assign teachers to activities, set priority scores, manage sub-activity structures for merged classes, and configure scheduling constraints
- **Teachers** view their assigned activities and the associated period-level detail rows
- **Administrators** review the activity list filtered by class, section, subject, teacher, or status during timetable preparation
- **Batch regeneration** when requirement data changes — the existing activities are truncated and regenerated from scratch

---

## Default Data Load

The screen loads via `ActivityController@index()` (line 38) which calls `Gate::authorize('timetable-foundation.activity.viewAny')` and immediately redirects to `timetable-foundation.menu.timetablePreparation?tab=activity`. The activity list is rendered inside the Timetable Preparation tab group, not as a standalone page.

No shared dropdowns are loaded by the `index()` redirect itself — the tabbed view in `timetablePreparation` loads the necessary filter dropdowns (academic term, class, section, subject, status). The activity grid is paginated with a default page size and uses standard Laravel pagination.

---

## Key Fields at a Glance

**Identity and Tracking**
- **code** — Machine-readable unique identifier generated from the source requirement (e.g. `ACT-CG-MTH10A-LEC-T1-TT1` for a class-group requirement, `ACT-SAC-...` for shared-across-classes). Used as the natural key for `updateOrCreate` during batch generation.
- **name** — Human-readable activity name, typically the class-group or subject name from the source requirement.
- **status** — Lifecycle state: `DRAFT`, `ACTIVE`, `LOCKED`, or `ARCHIVED`. Controls what operations are permitted (LOCKED prevents delete and disable).
- **is_active** — Soft toggle; inactive activities are excluded from solver processing.

**Target Assignment**
- **class_group_id** — FK to `sch_class_groups_jnt`. Set when the activity originates from a ClassSubjectGroup requirement. Mutually exclusive with `class_subgroup_id`.
- **class_subgroup_id** — FK to `tt_class_requirement_subgroups`. Set when the activity originates from a ClassRequirementSubgroup (optional/shared subjects). Mutually exclusive with `class_group_id`.
- **class_id** — The target class. Always required.
- **section_id** — The target section (nullable for shared-across-classes activities).
- **have_sub_activity** — Whether the activity is decomposed into sub-activities. Always `true` for shared-across-classes and shared-across-sections activities.

**Scheduling Load**
- **required_weekly_periods** — Total periods required per week.
- **duration_periods** — Consecutive periods consumed by a single instance (1 for lectures, 2 for labs).
- **weekly_periods** — Number of instances per week.
- **total_periods** — Generated column: `duration_periods × weekly_periods` (read-only).
- **allow_consecutive, max_consecutive, min_gap_periods, spread_evenly** — Scheduling hints for the solver.
- **preferred_periods_json, avoid_periods_json** — User-selected preferred or avoided time slots (saved as JSON).

**Resource Availability Scores**
- **eligible_teacher_count, min_teacher_availability_score, max_teacher_availability_score** — Captured from teacher profiles during batch generation.
- **teacher_availability_score, room_availability_score** — Percentage scores computed during generation.
- **difficulty_score_calculated** — Auto-calculated from a weighted formula combining difficulty, teacher availability, room availability, and constraint count.
- **constraint_count** — Number of GLOBAL constraints affecting this activity.

**Room Requirements**
- **requires_room** — Whether this activity needs a room.
- **compulsory_specific_room_type, required_room_type_id** — Mandatory room type.
- **required_room_id** — Specific mandatory room.
- **preferred_room_type_id, preferred_room_ids** — Soft room preferences (JSON array).

**Priority and Solver Hints**
- **priority** — User-set scheduling priority 0–100 (higher = placed first by solver).
- **difficulty_score** — Algorithmic difficulty 0–100 (higher = harder to schedule).
- **split_allowed** — Whether instances can be placed on non-consecutive days.
- **is_compulsory** — Whether the activity must appear on the timetable.

---

## Business Rules and Conditions

**Identity and Uniqueness**
- Every activity MUST have a unique `code` enforced at the DB level by `uq_activity_code`.
- An activity MUST target exactly one of `class_group_id` or `class_subgroup_id` — never both, never neither. This is enforced by controller-level validation in `store()` and `update()`.
- Activity `code` follows a convention determined by the generation source: `ACT-CG-*` for class-group requirements, `ACT-SG-*` for non-shared subgroup requirements, `ACT-SAC-*` for shared-across-classes, `ACT-SAS-*` for shared-across-sections.

**Status Transitions**
- `DRAFT` → `ACTIVE` (activate). `ACTIVE` → `LOCKED` (lock). `LOCKED` → `ACTIVE` (unlock). `ACTIVE` / `ARCHIVED` → trashed via soft delete. `ARCHIVED` is set by `destroy()`.
- Activities with `status = 'LOCKED'` CANNOT be deleted, force-deleted, or toggled inactive. The controller returns error messages for each.

**Period and Scheduling Constraints**
- `total_periods` is a MySQL `GENERATED ALWAYS AS (duration_periods * weekly_periods) STORED` column — read-only at the database level.
- `allow_consecutive`, `max_consecutive`, `min_gap_periods`, `spread_evenly`, `preferred_periods_json`, and `avoid_periods_json` are hints to the solver — they influence but do not guarantee placement.
- For lab/practical study formats (`name IN ('lab','practical','workshop')`), `allow_consecutive` is automatically set to `true` during generation.
- `split_allowed = true` permits the solver to place weekly instances on non-consecutive days.

**Room Constraints**
- If `requires_room = true`, the solver MUST assign a room to every period instance.
- If `compulsory_specific_room_type = true`, the solver MUST use a room matching `required_room_type_id`.
- `preferred_room_ids` (JSON array) is a soft preference — the solver attempts these rooms first.
- When `required_room_id` is set, that specific room MUST be used for all instances.

**Teacher Assignment**
- An activity MAY have zero, one, or multiple teachers via `tt_activity_teachers`.
- A teacher cannot be assigned to the same activity more than once (enforced by unique constraint `(activity_id, teacher_id)` and duplicate validation in the controller).
- Each teacher assignment has a role (`assignment_role_id` FK to `tt_teacher_assignment_roles`) determining the teacher's function (Primary Instructor, Assistant, Lab Assistant, etc.).
- When `is_required = true` on the teacher pivot, the solver MUST allocate at least one period instance to that teacher.
- During batch generation, eligible teachers are automatically assigned from `TeacherAvailability` filtered by class and subject_study_format, with `is_required = false`.

**Priority and Difficulty**
- `priority` (0–100) is the user-set scheduling priority — higher values are scheduled first.
- `difficulty_score` (0–100) is set manually or derived from requirement data. Higher scores indicate harder-to-place activities.
- `difficulty_score_calculated` is derived from a weighted formula during batch generation.
- The `schedulingScore()` helper on the model computes `(difficulty_score × 2) + constraint_count - min_teacher_availability_score - room_availability_score` for solver evaluation order.

**Sub-Activity Rules**
- When `have_sub_activity = true`, period-level detail rows are created at the sub-activity level (`sub_activity_id IS NOT NULL`).
- When `have_sub_activity = false`, detail rows attach directly to the activity (`sub_activity_id IS NULL`).
- Shared-across-classes and shared-across-sections activities ALWAYS set `have_sub_activity = true` and create one sub-activity per constituent class/section.
- `same_day_as_parent` on a sub-activity means the solver must place it on the same calendar day as the parent activity's primary instance.
- `consecutive_with_previous` on a sub-activity means the solver must place it immediately following the previous sibling sub-activity (by ordinal).

**Deletion and Lifecycle**
- Soft delete (`destroy`) sets `is_active = false` and `status = 'ARCHIVED'`, soft-deletes teacher pivot records, then soft-deletes the activity itself.
- Force delete (`forceDelete`) permanently removes the record but is BLOCKED for LOCKED activities.
- Restore (`restore`) sets `is_active = true` and `status = 'ACTIVE'`.
- `trashedActivity()` lists only soft-deleted (trashed) records.

---

## Workflow Steps

**Manual Activity Creation**
1. Admin navigates to Timetable Preparation → Activity tab.
2. Clicks Create Activity.
3. Fills in: code (auto-suggested or manual), name, academic session, timetable type, target (Class Group OR Class Subgroup — mutually exclusive), duration periods, weekly periods, priority, difficulty score, flags (split_allowed, is_compulsory, requires_room), room preferences, and teacher assignments.
4. Submits: the controller validates via inline `$request->validate()`, enforces exactly-one-target rule, checks for duplicate teacher IDs, then creates the Activity and teacher pivot records inside a DB transaction.
5. Redirects to the Timetable Preparation → Activity tab with a success flash message.

**Batch Generation**
1. Admin navigates to the Requirement Consolidation section and clicks Generate Activities.
2. The server sets `set_time_limit(300)` (5-minute max), disables foreign key checks, truncates `tt_activities`, `tt_sub_activities`, and `tt_activity_teachers`.
3. Reads all active RequirementConsolidation records with their relationships.
4. Processes in three steps: class-group requirements (regular subjects) → shared subgroups (shared-across-classes first, then shared-across-sections) → non-shared subgroup requirements.
5. For each activity: calculates teacher availability score, room availability score, difficulty score, and difficulty_score_calculated using the weighted formula; assigns eligible teachers via `assignTeacherToActivity()`.
6. For shared subgroups: groups by subject+format, determines room capacity, splits into multiple activities if student count exceeds room capacity, and creates sub-activities per original class/section.
7. Commits transaction, logs success with counts (Created, Consolidated, Skipped), redirects with success message.
8. On exception: rolls back, logs error, returns error message.

**Sub-Activity and Detail Planning**
1. Admin selects an activity with `have_sub_activity = true` → views sub-activities and their per-period detail rows.
2. Can seed detail rows (idempotent — creates period_number 1..N missing rows via `SubActivityDetailSeeder`).
3. Can create individual detail rows with teacher, room, time slot via the POST endpoint.
4. Can update detail rows to assign or change teacher/room/time slot.
5. Can soft-delete detail rows.
6. Assignment status (`UNASSIGNED` → `TEACHER_ASSIGNED` → `ROOM_ASSIGNED` → `FULLY_ASSIGNED`) auto-recomputes on each mutation via `recomputeStatus()`.

**Priority Management**
1. Admin views the activity list showing current priority score and badge.
2. Admin can use the `ajaxUpdatePriority` endpoint (POST) to modify priority inline.
3. Priority influences solver behaviour: higher-priority activities are placed first.

---

## Example Scenario

A school is setting up its timetable for Term 1 (academic term ID 5). The curriculum team has entered requirement consolidation records. An academic head navigates to Timetable Preparation → Activity tab and clicks "Generate Activities".

The batch generation runs:
- Class 10-A has Maths (Lecture, 5 periods/week) as a class-group requirement. The system creates activity `ACT-CG-MTH10A-LEC-T5-TT1` with `name = "Mathematics — Class 10A — Lecture"`, `difficulty_score_calculated = 45`, and automatically assigns two eligible teachers (one Primary, one Assistant).
- Class 10 (Sections A, B, C) all take Physical Education together — a shared-across-sections subgroup. The system detects 180 students across 3 sections. Room capacity is 60. `calculateGroupsNeeded(180, 60)` returns 3. The system creates 3 parent activities (`ACT-SAS-...-G1`, `-G2`, `-G3`), each with 3 sub-activities (one per section), distributing students proportionally.
- A non-shared optional subject (French, subgroup code `FR-OPT`) creates activity `ACT-SG-FR-OPT-T5-TT1` with `class_subgroup_id` set.

After generation, the academic head reviews the 47 created activities, adjusts priority for a few (setting Maths to priority 90), assigns a specific teacher to Physics Lab, and locks the core timetable activities. The solver is now ready to run.

---

## Related Screens

- **Requirement Consolidation** — Source data for batch generation; activities are derived from RequirementConsolidation records
- **Teacher Availability** — Provides eligible teacher lists per class+subject_study_format for automatic teacher assignment during generation
- **Timetable Preparation** — Parent tab group; the activity list is rendered as a sub-tab within this screen
- **Timetable Generation** — Consumes activities as input for automated scheduling; solver uses priority, difficulty, and constraint data
- **Activity Priority Configuration** — Dedicated bulk priority recalculation interface
- **Period Sets / Period Config** — Defines the period slots available for scheduling; referenced by preferred/avoid period selections

---

## Requirements

- `ActivityController` (1853 lines, `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php`) handles the full CRUD lifecycle plus batch generation. Key methods:
  - `index()` (line 38) — Redirects to `timetable-foundation.menu.timetablePreparation?tab=activity`; enforces `timetable-foundation.activity.viewAny`
  - `create()` (line 45) — Shows create form; enforces `timetable-foundation.activity.create`
  - `store()` (line 1028) — Validates via inline `$request->validate()`, enforces exactly-one-target (`class_group_jnt_id` xor `class_subgroup_id`), checks no duplicate teacher IDs, creates Activity + teacher pivots inside `DB::transaction()`. References `academic_session_id` (FK to `global_master_mysql.glb_academic_sessions`). Redirects to timetable preparation tab.
  - `show($id)` (line 1199) — Loads activity with all relationships (`academicTerm`, `timetableType`, `class`, `section`, `subject`, `studyFormat`, `subjectStudyFormat`, `subjectType`, `requiredRoomType`, `preferredRoomType`, `teachers.teacher.user`, `teachers.assignmentRole`, `subActivities`, `activityPriority`); enforces `timetable-foundation.activity.view`
  - `edit(int $id)` (line 1217) — Shows edit form; enforces `timetable-foundation.activity.update`
  - `update(Request, int $id)` (line 1225) — Validates with `Rule::unique(...)->ignore($activity->id)`, enforces exactly-one-target, checks duplicate teachers, updates Activity and re-syncs teacher pivots inside `DB::transaction()`; enforces `timetable-foundation.activity.update`
  - `destroy($id)` (line 1412) — Guards against LOCKED status, then inside a transaction: sets `is_active = false` and `status = 'ARCHIVED'`, soft-deletes teacher pivots, soft-deletes the activity, logs activity; enforces `timetable-foundation.activity.delete`
  - `trashedActivity()` (line 1463) — Lists only soft-deleted activities (`onlyTrashed()`, 10 per page); enforces `timetable-foundation.activity.restore`
  - `forceDelete($id)` (line 1476) — Blocks LOCKED status, calls `forceDelete()`; enforces `timetable-foundation.activity.forceDelete`
  - `restore($id)` (line 1502) — Calls `restore()`, sets `is_active = true` and `status = 'ACTIVE'`; enforces `timetable-foundation.activity.restore`
  - `toggleStatus(Request, Activity $activity)` (line 1526) — Validates `is_active` required boolean; blocks disabling LOCKED activities (returns JSON 403); saves and returns JSON response; enforces `timetable-foundation.activity.update`
  - `generateActivities()` (line 52) — Enforces `timetable-foundation.activity.generate`; sets `set_time_limit(300)`; disables FK checks, truncates `tt_activities`, `tt_sub_activities`, `tt_activity_teachers`; processes class-group requirements, shared-across-classes consolidation, shared-across-sections consolidation, and non-shared subgroup requirements inside a DB transaction; uses `getRoomCapacity()`, `calculateGroupsNeeded()`, `assignTeacherToActivity()`, `isLabOrPractical()` helpers
  - Routes exist for `ajaxUpdatePriority()`, `generateAllActivities()`, and `getBatchGenerationProgress()` but these methods are **not yet implemented** in the controller (code gap — routes registered, methods missing)

- `SubActivityDetailController` (155 lines, `Modules/TimetableFoundation/app/Http/Controllers/SubActivityDetailController.php`) handles per-period plan rows:
  - `index(SubActivity $subActivity)` — Loads detail rows with teacher/room relationships; enforces `timetable-foundation.sub-activity-detail.viewAny`
  - `seed(Request, SubActivity $subActivity, SubActivityDetailSeeder $seeder)` — Idempotent seeding; validates optional `count` parameter; enforces `timetable-foundation.sub-activity-detail.create`
  - `store(Request, SubActivity $subActivity)` — Creates single detail row with `period_number`, `assigned_teacher_id`, `assigned_room_id`, `assigned_time_slot`; calls `recomputeStatus()->save()`; enforces `timetable-foundation.sub-activity-detail.create`
  - `update(Request, SubActivityDetail $subActivityDetail)` — Patches only keys present in request; calls `recomputeStatus()->save()`; enforces `timetable-foundation.sub-activity-detail.update`
  - `destroy(SubActivityDetail $subActivityDetail)` — Soft-deletes; enforces `timetable-foundation.sub-activity-detail.delete`

- Validation is done inline in each controller method (no Form Request classes).
- `SubActivityDetailSeeder` service provides idempotent seeding: `seedForSubActivity()` and `seedForActivity()` ensure rows `period_number = 1..N` exist.
- `Activity` model (`Modules/TimetableFoundation/app/Models/Activity.php`, 313 lines) uses `SoftDeletes`, table `tt_activities`. `$fillable` covers 48 columns. `$casts` for booleans, integers, arrays (JSON), decimals, datetimes. Relationships: `academicTerm`, `timetableType`, `classGroup`, `classSubgroup`, `class`, `section`, `subject`, `studyFormat`, `subjectStudyFormat`, `subjectType`, `requiredRoomType`, `requiredRoom`, `preferredRoomType`, `teachers`/`activityTeachers`, `subActivities`, `activityPriority`, `details`, `directDetails`, `parallelGroups`.
- Scopes: `active`, `forTerm`, `schedulable` (status=ACTIVE + is_active + is_compulsory), `byDifficulty`.
- Generated code pattern via `updateOrCreate('code' => ...)` during batch generation. Four code prefixes: `ACT-CG-`, `ACT-SG-`, `ACT-SAC-`, `ACT-SAS-`.
- All write operations log activity via `activityLog()` helper.
- Delete behavior: soft delete. `destroy()` cascades to teacher pivots (soft-delete). Hard truncation during batch generation. `forceDelete()` blocked for LOCKED.
- Policy: `ActivityPolicy` (`Modules/TimetableFoundation/app/Policies/ActivityPolicy.php`, 44 lines). Methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`. Each checks the corresponding `timetable-foundation.activity.*` permission.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.activity.viewAny` | `index()` | View activity list (redirects to tab) |
| `timetable-foundation.activity.view` | `show()` | View single activity detail |
| `timetable-foundation.activity.create` | `create()`, `store()` | Create new activities |
| `timetable-foundation.activity.update` | `edit()`, `update()`, `toggleStatus()` | Update activities and toggle status |
| `timetable-foundation.activity.delete` | `destroy()` | Soft-delete activities |
| `timetable-foundation.activity.restore` | `restore()`, `trashedActivity()` | Restore and view trash |
| `timetable-foundation.activity.forceDelete` | `forceDelete()` | Permanently delete |
| `timetable-foundation.activity.generate` | `generateActivities()`, `generateAllActivities()` | Batch generation |
| `timetable-foundation.sub-activity-detail.viewAny` | `SubActivityDetailController@index` | View detail rows |
| `timetable-foundation.sub-activity-detail.create` | `store()`, `seed()` | Create/seed detail rows |
| `timetable-foundation.sub-activity-detail.update` | `update()` | Update detail rows |
| `timetable-foundation.sub-activity-detail.delete` | `destroy()` | Delete detail rows |
| **Policy** | `ActivityPolicy` | 7 methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |

Unauthorised access returns 403 via `Gate::authorize()`. Guest access redirects to login.

---

## Logic Flow

**1. Page Load (Activity List)**
- `GET /timetable-foundation/activity` → `ActivityController@index()` → Gate check `viewAny` → Redirects to `timetable-foundation.menu.timetablePreparation?tab=activity` → Tab view renders the activity grid with filters.

**2. Create Activity**
- `GET /timetable-foundation/activity/create` → `ActivityController@create()` → Gate check `create` → Returns create form view.
- `POST /timetable-foundation/activity` → `ActivityController@store()` → Gate check `create` → Validates (code unique, name max 200, academic_session_id exists in global db, class_group_jnt_id xor class_subgroup_id, duration/periods min 1, priority/difficulty min 1 max 100, teachers array with exists checks) → Controller-level check: exactly one target rule error if both or neither → Duplicate teacher ID check → `DB::transaction()`: `Activity::create()` sets `status = 'ACTIVE'`, `created_by = auth()->id()`, then `updateOrCreate` teacher pivots → Redirects with `flash('created.activity')`.

**3. View Activity Detail**
- `GET /timetable-foundation/activity/{activity}` → `ActivityController@show($id)` → Gate check `view` → Loads activity with 11+ relationships → Renders show view.

**4. Edit / Update Activity**
- `GET /timetable-foundation/activity/{activity}/edit` → `ActivityController@edit()` → Gate check `update` → Returns edit form.
- `PATCH /timetable-foundation/activity/{activity}` → `ActivityController@update()` → Gate check `update` → `findOrFail($id)` → Validates (code unique ignoring current ID via `Rule::unique()->ignore()`, same rules as store) → Exactly-one-target check → Duplicate teacher check → `DB::transaction()`: `$activity->update()` then `$activity->teachers()->delete()` then recreate teacher pivots via `updateOrCreate` → Redirects with `flash('updated.activity')`.

**5. Batch Generation**
- `POST /timetable-foundation/requirements/generate-activities/all` → `ActivityController@generateActivities()` → Gate check `generate` → `set_time_limit(300)` → Disable FK checks → Truncate `tt_activities`, `tt_sub_activities`, `tt_activity_teachers` → Enable FK checks → `DB::beginTransaction()` → Load active RequirementConsolidation records with relationships → Split into `classGroupReqs` (where class_requirement_group_id set) and `classSubgroupReqs` (where class_requirement_subgroup_id set) → Count GLOBAL constraints → **Step 1**: For each classGroupReq, calculate scores (teachersCount from TeacherAvailability, teacherAvailabilityScore = min(100, count×20), roomsCount, roomAvailabilityScore = min(100, count×25), difficultyScore = max(0, min(100, 100-priority)), difficultyScoreCalculated via weighted formula), then `updateOrCreate` on code with all constraint fields, restore if soft-deleted, call `assignTeacherToActivity()` → **Step 2a** (Shared Across Classes): Filter subgroups with `is_shared_across_classes`, deduplicate against Step 1 processed subjects, group by subject+format+type, for groups > 1 calculate room capacity via `getRoomCapacity(null)`, `calculateGroupsNeeded()`, create N parent activities with `have_sub_activity = true` and sub-activities per class → **Step 2b** (Shared Across Sections): Same logic but class-specific room capacity, prefix `ACT-SAS-` → **Step 3** (Non-Shared): For remaining classSubgroupReqs, create activity with code `ACT-SG-{subgroup.code}-...` → Commit transaction → Log success with counts → On exception: rollback, log error.

**6. Delete Activity**
- `DELETE /timetable-foundation/activity/{activity}` → `ActivityController@destroy($id)` → Gate check `delete` → `findOrFail($id)` → Guard: if status === 'LOCKED', redirect back with `flash('locked_activity_delete_not_allowed')` → `DB::transaction()`: set `is_active = false`, `status = 'ARCHIVED'`, soft-delete teacher pivots, soft-delete activity, log activity → Redirect with `flash('deleted.activity')`.

**7. Toggle Status**
- `POST /timetable-foundation/activity/{activity}/toggle-status` → `ActivityController@toggleStatus()` → Gate check `update` → Validate `is_active` required boolean → Guard: if LOCKED and trying to disable, return JSON 403 → Set `is_active`, save → Return JSON success/error.

**8. Restore / Force Delete**
- `GET /timetable-foundation/activity/{id}/restore` → `ActivityController@restore()` → Gate check `restore` → `onlyTrashed()->findOrFail($id)` → Restore → Set `is_active = true`, `status = 'ACTIVE'` → Log → Redirect.
- `DELETE /timetable-foundation/activity/{id}/force-delete` → `ActivityController@forceDelete()` → Gate check `forceDelete` → `withTrashed()->findOrFail($id)` → Guard: if LOCKED, redirect with error → `forceDelete()` → Log → Redirect.

**9. Sub-Activity Detail Endpoints (JSON)**
- `GET /sub-activity/{subActivity}/details` → Load detail rows ordered by period_number with teacher/room.
- `POST /sub-activity/{subActivity}/details/seed` → Idempotent seed via `SubActivityDetailSeeder::seedForSubActivity()`. Count override validated nullable integer min:1 max:255.
- `POST /sub-activity/{subActivity}/details` → Create row with `period_number` required, teacher/room/time optional. `recomputeStatus()` after create.
- `PATCH /sub-activity-detail/{subActivityDetail}` → Patch only present fields. `recomputeStatus()` after update.
- `DELETE /sub-activity-detail/{subActivityDetail}` → Soft delete.

---

## Validate Before Save

### Activity (store / update)

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | required, string, max:50, unique:tt_activities,code (store) / `Rule::unique(...)->ignore($activity->id)` (update) | — (Laravel default unique) |
| `name` | required, string, max:200 | — |
| `description` | nullable, string, max:500 | — |
| `academic_session_id` | required, exists:global_master_mysql.glb_academic_sessions,id | — |
| `class_group_jnt_id` | nullable, exists:sch_class_groups_jnt,id | — |
| `class_subgroup_id` | nullable, exists:tt_class_requirement_subgroups,id | — |
| `duration_periods` | required, integer, min:1 | — |
| `weekly_periods` | required, integer, min:1 | — |
| `priority` | nullable, integer, min:1, max:100 | — |
| `difficulty_score` | nullable, integer, min:1, max:100 | — |
| `split_allowed` | sometimes | — |
| `is_compulsory` | sometimes | — |
| `requires_room` | sometimes | — |
| `preferred_room_type_id` | nullable, exists:sch_rooms_type,id | — |
| `is_active` | sometimes | — |
| `teachers` | nullable, array | — |
| `teachers.*.teacher_id` | required_with:teachers.*.assignment_role_id, exists:sch_teachers,id | — |
| `teachers.*.assignment_role_id` | required_with:teachers.*.teacher_id, exists:tt_teacher_assignment_roles,id | — |
| `teachers.*.ordinal` | nullable, integer, min:1 | — |
| `teachers.*.is_required` | sometimes | — |

**Controller-level checks (store / update)**
| Check | Condition | Error Message |
|-------|-----------|---------------|
| Exactly one target | Must set exactly one of `class_group_jnt_id` or `class_subgroup_id` | "Select either a Class Group or a Class Subgroup (not both)." |
| Duplicate teachers | `teachersInput->pluck('teacher_id')->duplicates()` non-empty | "A teacher cannot be assigned more than once." |

### Sub-Activity Detail

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `count` (seed) | nullable, integer, min:1, max:255 | — |
| `period_number` (store) | required, integer, min:1, max:255 | — |
| `assigned_teacher_id` (store/update) | nullable, integer, exists:sch_teachers,id | — |
| `assigned_room_id` (store/update) | nullable, integer, exists:sch_rooms,id | — |
| `assigned_time_slot` (store/update) | nullable, string, max:50 | — |
| `is_active` (update) | nullable, boolean | — |

### toggleStatus

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `is_active` | required, boolean | — |

> **Note:** The `store()` and `update()` methods reference `academic_session_id` (validated against `global_master_mysql.glb_academic_sessions.id`) and `class_group_jnt_id` as column names in the validated data, but the DDL has `academic_term_id` and `class_group_id`. The model's `$fillable` uses `academic_term_id` and `class_group_id`. This is a code ↔ DDL discrepancy — the input field names on the form do not match the model columns they map to.

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing required field (any) | Laravel default validation message | Validation rule |
| Code uniqueness violation (store) | "The code has already been taken." | Validation rule (unique) |
| Code uniqueness violation (update) | "The code has already been taken." | Validation rule (`Rule::unique()->ignore()`) |
| Both or neither target specified | "Select either a Class Group or a Class Subgroup (not both)." | Controller check (redirect back with error) |
| Duplicate teacher in request | "A teacher cannot be assigned more than once." | Controller check (redirect back with error) |
| Destroy LOCKED activity | `flash('locked_activity_delete_not_allowed')` | Controller guard (redirect back with error) |
| Force-delete LOCKED activity | `flash('locked_activity_force_delete_not_allowed')` | Controller guard (redirect back with error) |
| Toggle LOCKED activity to inactive | `flash('locked_activity_disable_not_allowed')` — returns JSON 403 | Controller guard (JSON response) |
| Toggle save failure | `flash('status_switch_failed.activity')` — returns JSON 422 | Controller check (JSON response) |
| Activity not found | 404 via `findOrFail($id)` | Model not found |
| Gate authorization failure | 403 | `Gate::authorize()` |
| No active timetable type (batch generation) | "No active timetable type found. Please create one first." | Controller check (redirect back with error) |

---

## Success Scenarios

**SC-001 — Activity Created Successfully**
Admin fills the create form with code `ACT-MTH10A-LEC`, name "Mathematics — Class 10A — Lecture", target Class 10 Section A, Maths subject, Lecture format, 5 weekly periods, priority 80, one teacher with Primary role. System creates the activity record with `status = 'ACTIVE'`, `is_active = true`, teacher pivot record, and redirects to the activity tab with `flash('created.activity')`.

**SC-002 — Activity Updated Successfully**
Admin edits activity `ACT-MTH10A-LEC`, changes `weekly_periods` from 5 to 4, changes teacher assignment. System updates the activity record, deletes old teacher pivots, creates new ones inside a transaction, and redirects with `flash('updated.activity')`.

**SC-003 — Batch Generation Completes**
Admin clicks Generate Activities for Term 1. System processes 30 class-group requirements, 2 shared-across-classes groups (Music across 3 classes → 1 activity with sub-activities, PE across 3 sections → 3 activities with 3 sub-activities each), and 5 non-shared subgroup requirements. System commits, shows success message: "Created: 35, Consolidated: 4, Skipped: 0".

**SC-004 — Activity Soft-Deleted Successfully**
Admin deletes activity `ACT-FR-OPT` (status ACTIVE). System sets `is_active = false`, `status = 'ARCHIVED'`, soft-deletes teacher pivots, soft-deletes activity, logs, and redirects with `flash('deleted.activity')`. Activity appears in trash view.

**SC-005 — Activity Restored Successfully**
Admin restores activity from trash. System calls `restore()`, sets `is_active = true` and `status = 'ACTIVE'`, logs, and redirects with `flash('restored.activity')`.

**SC-006 — Sub-Activity Detail Seeded Idempotently**
Admin seeds a sub-activity with `required_weekly_periods = 5`. System creates 5 detail rows (period_number 1 through 5). Admin seeds again — system skips existing rows, returns `created_count = 0`.

---

## Failure Scenarios

**FC-001 — Create with Both Targets Fails**
Admin sets both Class Group and Class Subgroup on create form. System rejects with "Select either a Class Group or a Class Subgroup (not both)." and returns to form with error.

**FC-002 — Create with Duplicate Teacher Fails**
Admin assigns the same teacher twice to an activity. System rejects with "A teacher cannot be assigned more than once." and returns to form with error.

**FC-003 — Delete LOCKED Activity Fails**
Admin attempts to delete an activity with `status = 'LOCKED'`. System rejects with `flash('locked_activity_delete_not_allowed')` and redirects back.

**FC-004 — Force-Delete LOCKED Activity Fails**
Admin attempts to force-delete a LOCKED activity. System rejects with `flash('locked_activity_force_delete_not_allowed')` and redirects back.

**FC-005 — Toggle LOCKED Activity to Inactive Fails**
Admin attempts to disable a LOCKED activity via `toggleStatus()`. System returns JSON 403 with `flash('locked_activity_disable_not_allowed')`.

**FC-006 — Batch Generation Without Timetable Type Fails**
Admin triggers generation when no active timetable type exists. System redirects back with "No active timetable type found. Please create one first."

**FC-007 — Unauthorized Access**
User without `timetable-foundation.activity.create` gate accesses create form. System returns 403. Guest user is redirected to login.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_academic_term` | FK parent (RESTRICT) | `tt_activities.academic_term_id` → `sch_academic_term.id` (via `fk_activity_session`) |
| `tt_timetable_types` | FK parent | `tt_activities.timetable_type_id` → `tt_timetable_types.id` |
| `sch_class_groups_jnt` | FK parent (SET NULL) | `tt_activities.class_group_id` → `sch_class_groups_jnt.id` (via `fk_activity_class_group`) |
| `tt_class_requirement_subgroups` | FK parent (SET NULL) | `tt_activities.class_subgroup_id` → `tt_class_requirement_subgroups.id` (via `fk_activity_subgroup`) |
| `sch_classes` | FK parent | `tt_activities.class_id` |
| `sch_sections` | FK parent (SET NULL) | `tt_activities.section_id` |
| `sch_subjects` | FK parent (SET NULL) | `tt_activities.subject_id` (via `fk_activity_subject`) |
| `sch_study_formats` | FK parent (SET NULL) | `tt_activities.study_format_id` / `subject_study_format_id` (via `fk_activity_study_format`) |
| `sch_subject_types` | FK parent | `tt_activities.subject_type_id` |
| `sch_rooms_type` | FK parent (SET NULL) | `tt_activities.required_room_type_id`, `preferred_room_type_id` |
| `sch_rooms` | FK parent (SET NULL) | `tt_activities.required_room_id` |
| `sys_users` | FK parent (SET NULL) | `tt_activities.created_by` (via `fk_activity_created_by`) |
| `tt_sub_activities` | FK child (CASCADE) | `tt_sub_activities.parent_activity_id` → `tt_activities.id`. Deleted when parent is deleted (CASCADE) |
| `tt_sub_activity_details` | FK child (CASCADE) | `tt_sub_activity_details.activity_id` → `tt_activities.id`. Deleted when parent is deleted (CASCADE) |
| `tt_activity_teachers` | FK child (CASCADE) | `tt_activity_teachers.activity_id` → `tt_activities.id`. Deleted when parent is deleted (CASCADE). Also FK to `sch_teachers` (CASCADE), `tt_teacher_assignment_roles` (RESTRICT) |
| `tt_activity_priorities` | FK child (CASCADE) | `tt_activity_priorities.activity_id` → `tt_activities.id`. Deleted when parent is deleted |
| `RequirementConsolidation` | Service dependency | Source data for `generateActivities()` batch generation |
| `TeacherAvailability` | Service dependency | Provides eligible teacher lists for assignment during generation |
| `SubActivityDetailSeeder` | Service dependency | Provides idempotent seeding logic for detail rows |
| `Constraint` (SmartTimetable) | Service dependency | GLOBAL constraint count used in difficulty score calculation |
| `activityLog()` | Audit dependency | All state-changing operations log via `activityLog()` helper |
| `ParallelGroup` | Cross-module consumer | `tt_parallel_group_activity` pivot — parallel group membership blocks certain operations |

**Table: `tt_activities`**

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PRIMARY KEY, Auto-increment |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE (`uq_activity_code`) |
| `name` | VARCHAR(200) | NOT NULL |
| `academic_term_id` | INT UNSIGNED | NOT NULL, FK → `sch_academic_term.id` (RESTRICT) |
| `timetable_type_id` | INT UNSIGNED | NOT NULL, FK → `tt_timetable_types.id` |
| `class_group_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt.id` (SET NULL) |
| `class_subgroup_id` | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups.id` (SET NULL) |
| `have_sub_activity` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `class_id` | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| `section_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_sections.id` |
| `subject_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_subjects.id` (SET NULL) |
| `study_format_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_study_formats.id` (SET NULL) |
| `subject_type_id` | INT UNSIGNED | NOT NULL, FK → `sch_subject_types.id` |
| `subject_study_format_id` | INT UNSIGNED | NOT NULL, FK → `sch_study_formats.id` |
| `required_weekly_periods` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `min_periods_per_week` | TINYINT UNSIGNED | DEFAULT NULL |
| `max_periods_per_week` | TINYINT UNSIGNED | DEFAULT NULL |
| `max_per_day` | TINYINT UNSIGNED | DEFAULT NULL |
| `min_per_day` | TINYINT UNSIGNED | DEFAULT NULL |
| `min_gap_periods` | TINYINT UNSIGNED | DEFAULT NULL |
| `allow_consecutive` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `max_consecutive` | TINYINT UNSIGNED | DEFAULT 2 |
| `preferred_periods_json` | JSON | DEFAULT NULL |
| `avoid_periods_json` | JSON | DEFAULT NULL |
| `spread_evenly` | TINYINT(1) | DEFAULT 1 |
| `eligible_teacher_count` | INT UNSIGNED | DEFAULT NULL |
| `min_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| `max_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | DEFAULT 1 |
| `duration_periods` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `weekly_periods` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `total_periods` | SMALLINT UNSIGNED | GENERATED ALWAYS AS (`duration_periods` * `weekly_periods`) STORED |
| `split_allowed` | TINYINT(1) | DEFAULT 0 |
| `is_compulsory` | TINYINT(1) | DEFAULT 1 |
| `priority` | TINYINT UNSIGNED | DEFAULT 50 |
| `difficulty_score` | TINYINT UNSIGNED | DEFAULT 50 |
| `compulsory_specific_room_type` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `required_room_type_id` | INT UNSIGNED | NOT NULL, FK → `sch_rooms_type.id` |
| `required_room_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms.id` |
| `requires_room` | TINYINT(1) | DEFAULT 1 |
| `preferred_room_type_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms_type.id` (SET NULL) |
| `preferred_room_ids` | JSON | DEFAULT NULL |
| `difficulty_score_calculated` | TINYINT UNSIGNED | DEFAULT 50 |
| `teacher_availability_score` | TINYINT UNSIGNED | DEFAULT 100 |
| `room_availability_score` | TINYINT UNSIGNED | DEFAULT 100 |
| `constraint_count` | SMALLINT UNSIGNED | DEFAULT 0 |
| `preferred_time_slots_json` | JSON | DEFAULT NULL |
| `avoid_time_slots_json` | JSON | DEFAULT NULL |
| `status` | ENUM('DRAFT','ACTIVE','LOCKED','ARCHIVED') | NOT NULL, DEFAULT 'ACTIVE' |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_by` | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id` (SET NULL) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | DEFAULT NULL |

Indexes: UNIQUE `code` (`uq_activity_code`), INDEX `idx_activity_difficulty` (`difficulty_score`, `constraint_count`), INDEX `idx_activity_session` (`academic_term_id`), INDEX `idx_activity_class_group` (`class_group_id`), INDEX `idx_activity_subgroup` (`class_subgroup_id`), INDEX `idx_activity_subject` (`subject_id`), INDEX `idx_activity_status` (`status`), INDEX `idx_activity_generation` (`academic_term_id`, `difficulty_score`, `status`, `is_active`).

> **Note:** The controller's `store()` and `update()` methods validate `academic_session_id` against `global_master_mysql.glb_academic_sessions` and use field name `class_group_jnt_id`, while the DDL defines `academic_term_id` (FK to `sch_academic_term`) and `class_group_id` (FK to `sch_class_groups_jnt`). This is a documented code‑vs‑DDL discrepancy. The model's `$fillable` matches the DDL column names (`academic_term_id`, `class_group_id`).

> **Note:** Three routes (`ajaxUpdatePriority`, `generateAllActivities`, `getBatchGenerationProgress`) are registered in `web.php` but the corresponding controller methods are not implemented. These are planned features with no current behaviour. See GAP-005.
