# tts_DragAndDropGrid_TcList

## Module: StandardTimetable → Manual Placement → Drag-and-Drop Grid & Conflict Checking

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | StandardTimetable / Manual Placement / Drag-and-Drop Grid & Conflict Checking |
| URL(s) | `GET manual-placement` (named `menu.manualPlacement`), `POST place-cell` (named `placeCell`), `POST remove-cell` (named `removeCell`) |
| Controller | `Modules\StandardTimetable\Http\Controllers\StandardTimetableController` — `manualPlacement()` lines 88–173 (page load), `placeCell()` lines 178–292 (AJAX place), `removeCell()` lines 297–357 (AJAX remove), `checkConflicts()` lines 462–574 (private conflict engine) |
| Model(s) | `Modules\TimetableFoundation\Models\TimetableCell` (table: `tt_timetable_cells`); `Modules\TimetableFoundation\Models\Timetable` (table: `tt_timetables`); `Modules\TimetableFoundation\Models\Activity` (table: `tt_activities`) |
| Validation (Place) | `Modules\StandardTimetable\Http\Requests\PlaceCellRequest` |
| Validation (Remove) | `Modules\StandardTimetable\Http\Requests\RemoveCellRequest` |
| Service | `Modules\StandardTimetable\Services\ManualTimetableService` — `placeCell()` line 13, `removeCell()` line 65, `checkConflicts()` line 118, `persistConflicts()` line 195 |
| Policy | `Modules\StandardTimetable\Policies\StandardTimetablePolicy` — `manualPlace(User $user)` method |
| Permissions | `standard-timetable.manualPlace` (required for all three controller methods + both Form Requests) |
| Pagination | None — grid renders all days × periods for the selected class-section in one view |
| Soft Deletes | Yes — `TimetableCell` uses `SoftDeletes` trait; DDL confirms `deleted_at` column |
| Data Source | Activities originate from `tt_activities` (TimetableFoundation module); timetables from `tt_timetables`; placements are stored directly in `tt_timetable_cells` |

---

## 2. Pre-conditions

- Authenticated user with `standard-timetable.manualPlace` permission granted.
- At least one active class-section exists in `sch_class_sections_jnt` with `is_active = true`.
- At least one active manual timetable (`tt_timetables.generation_method = 'MANUAL'`, `is_active = true`) exists, OR the user can create one via the "New Timetable" modal.
- At least one activity exists in `tt_activities` linked to the selected class-section's `class_id` and `section_id`, with `is_active = true`.
- School days (`tt_school_days`) with `is_school_day = true` and `is_active = true` are configured.
- A period set (`tt_period_sets`) with at least one default set has periods configured via `tt_period_set_periods_jnt`.
- At least one academic term exists in `sch_academic_term`.
- Dusk environment variables configured:
  - `DUSK_TENANT_URL` — the tenant URL for testing.
  - `DUSK_ADMIN_EMAIL` — email of a user with `standard-timetable.manualPlace` permission.
  - `DUSK_ADMIN_PASSWORD` — corresponding password.

---

## 3. Default Data Load

The screen is loaded by `manualPlacement()` under `GET manual-placement`. When no query parameters are provided, the first active class-section is selected by default and no timetable is selected — no activities or cells load until both a class-section and a timetable are chosen.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Class-sections | `manualPlacement()` | `ClassSection::with(['class','section'])->where('is_active',true)->orderBy('ordinal')` | `is_active = true` | None |
| School days | `manualPlacement()` | `SchoolDay::where('is_school_day',true)->where('is_active',true)->orderBy('ordinal')` | `is_school_day = true`, `is_active = true` | None |
| Period sets + periods | `manualPlacement()` | `PeriodSet::where('is_active',true)->orderBy('name')` then `periods()` on default/first set | `is_active = true` | None |
| Timetable types | `manualPlacement()` | `TimetableType::where('is_active',true)->orderBy('ordinal')` | `is_active = true` | None |
| Academic terms | `manualPlacement()` | `AcademicTerm::orderByDesc('is_current')->orderBy('term_start_date')` | None | None |
| Manual timetables | `manualPlacement()` | `Timetable::where('generation_method','MANUAL')->where('is_active',true)->withCount('cells')->with(['timetableType','academicTerm','createdBy'])->orderByDesc('created_at')` | `generation_method = 'MANUAL'`, `is_active = true` | None |
| Activities | `manualPlacement()` | `Activity::with(['subject','studyFormat','subjectType','teachers.teacher.user','teachers.assignmentRole'])->where('class_id',$cs->class_id)->where('section_id',$cs->section_id)->where('is_active',true)->orderBy('subject_id')` | `class_id` + `section_id` from selected CS, `is_active = true` | None |
| Existing cells | `manualPlacement()` | `TimetableCell::with(['activity.subject','activity.studyFormat','activity.requiredRoomType','teachers.user'])->where('timetable_id',$ttId)->whereHas('activity',fn=>class_id+section_id)->get()->keyBy("dow-period_ord")` | `timetable_id` from query param | None |
| Rooms | `manualPlacement()` | `Room::with('roomType')->where('is_active',true)->orderBy('name')` | `is_active = true` | None |

> **Data Source:** Activities and timetables originate from the TimetableFoundation module's `tt_activities` and `tt_timetables` tables. Cells are stored directly in `tt_timetable_cells`.

---

## 4. Test Data Strategy

- **Test data creation:** Use direct DB inserts via `DB::table()` or factory methods to create the prerequisite records: a manual timetable, activities with teachers, school days, a period set with periods, and academic terms. Use the UI's "New Timetable" modal for testing the creation flow.
- **Consistent date ranges:** Use a fixed academic term with `term_start_date = '2026-04-01'` and `term_end_date = '2026-09-30'` for all tests. Set `is_current = true` on this term to enable cross-timetable conflict checks.
- **Pre-test cleanup:** Truncate `tt_timetable_cells` and `tt_timetable_cell_teachers` before each test. If testing cross-timetable conflicts, create two distinct manual timetables with non-overlapping cell placements for the setup.
- **Pagination:** Not applicable — the grid is an all-in-one view with no pagination.
- **Cross-module data needed:** At least one class-section with `is_active = true` from SchoolSetup. At least one active subject with a study format. At least one teacher with an assignment role. For conflict tests, create a cell in `tt_timetable_cells` with a known teacher/room before attempting placement.

---

## 5. Business Conditions

### 5.1 Database Schema — tt_timetable_cells

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, AUTO_INCREMENT, NOT NULL |
| BC-DB-02 | timetable_id | INT UNSIGNED | NOT NULL, FK → `tt_timetables.id` ON DELETE CASCADE |
| BC-DB-03 | generation_run_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_generation_runs.id` ON DELETE SET NULL |
| BC-DB-04 | day_of_week | TINYINT UNSIGNED | NOT NULL |
| BC-DB-05 | period_ord | TINYINT UNSIGNED | NOT NULL |
| BC-DB-06 | cell_date | DATE | DEFAULT NULL |
| BC-DB-07 | class_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt.id` ON DELETE CASCADE |
| BC-DB-08 | class_subgroup_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups.id` ON DELETE CASCADE |
| BC-DB-09 | activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_activities.id` ON DELETE SET NULL |
| BC-DB-10 | sub_activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_sub_activities.id` ON DELETE SET NULL |
| BC-DB-11 | room_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms.id` ON DELETE SET NULL |
| BC-DB-12 | source | ENUM('AUTO','MANUAL','SWAP','LOCK') | NOT NULL, DEFAULT 'AUTO' |
| BC-DB-13 | is_locked | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-14 | locked_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id` ON DELETE SET NULL |
| BC-DB-15 | locked_at | TIMESTAMP | NULL |
| BC-DB-16 | has_conflict | TINYINT(1) | DEFAULT 0 |
| BC-DB-17 | conflict_details_json | JSON | DEFAULT NULL |
| BC-DB-18 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-19 | created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-20 | updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-21 | deleted_at | TIMESTAMP | NULL |
| BC-DB-22 | **UNIQUE KEY** | `uq_cell_tt_day_period_group` | (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`) |
| BC-DB-23 | **CHECK** | `chk_cell_target` | (`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL) |

### 5.2 Database Schema — tt_timetable_cell_teachers

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-24 | id | INT UNSIGNED | PK, AUTO_INCREMENT, NOT NULL |
| BC-DB-25 | cell_id | INT UNSIGNED | NOT NULL, FK → `tt_timetable_cells.id` ON DELETE CASCADE |
| BC-DB-26 | teacher_id | INT UNSIGNED | NOT NULL, FK → `sch_teachers.id` ON DELETE CASCADE |
| BC-DB-27 | assignment_role_id | TINYINT UNSIGNED | NOT NULL, FK → `tt_teacher_assignment_roles.id` ON DELETE RESTRICT |
| BC-DB-28 | is_substitute | TINYINT(1) | DEFAULT 0 |
| BC-DB-29 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-30 | created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-31 | updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-32 | deleted_at | TIMESTAMP | NULL |
| BC-DB-33 | **UNIQUE KEY** | `uq_cct_cell_teacher` | (`cell_id`, `teacher_id`) |

### 5.3 Validation Rules — PlaceCellRequest

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | timetable_id | `required`, `integer`, `exists:tt_timetables,id` | Default Laravel validation error |
| BC-VAL-02 | activity_id | `required`, `integer`, `exists:tt_activities,id` scoped by `class_group_id` | Default Laravel validation error |
| BC-VAL-03 | day_of_week | `required`, `integer`, `min:1`, `max:7` | Default Laravel validation error |
| BC-VAL-04 | period_ord | `required`, `integer`, `min:1` | Default Laravel validation error |
| BC-VAL-05 | class_group_id | `required`, `integer` | Default Laravel validation error |

### 5.4 Validation Rules — RemoveCellRequest

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-06 | timetable_id | `required`, `integer`, `exists:tt_timetables,id` | Default Laravel validation error |
| BC-VAL-07 | day_of_week | `required`, `integer`, `min:1`, `max:7` | Default Laravel validation error |
| BC-VAL-08 | period_ord | `required`, `integer`, `min:1` | Default Laravel validation error |
| BC-VAL-09 | class_group_id | `required`, `integer` | Default Laravel validation error |

### 5.5 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `standard-timetable.manualPlace` | User granted this permission can access `manualPlacement()`, `placeCell()`, and `removeCell()` |
| BC-AUTH-02 | Missing `standard-timetable.manualPlace` | Backend returns HTTP 403 Forbidden on all three methods |
| BC-AUTH-03 | Guest access (unauthenticated) | Redirect to `/login` for GET request; 403/401 for AJAX POST |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with no `timetable_id` query param | Timetable list table is shown; no grid, no activities, no cells |
| BC-BIZ-02 | Page loads with `timetable_id` and `class_section_id` | Grid, activities sidebar, and existing cells are all loaded |
| BC-BIZ-03 | Class-section selector changes | Page reloads with new `class_section_id`; activities update for new class-section |
| BC-BIZ-04 | Timetable selector changes | Page reloads with new `timetable_id`; existing cells for that timetable are loaded |
| BC-BIZ-05 | No manual timetables exist | Empty state message "No manual timetables yet" shown with "New Timetable" button |
| BC-BIZ-06 | No activities exist for selected class-section | Empty state message "No activities. Generate them first." shown in sidebar |
| BC-BIZ-07 | Activity sidebar renders each activity | Subject name, format badge, type badge, teacher name, weekly_needed, placed_count, remaining, progress bar shown |
| BC-BIZ-08 | Activity with `remaining > 0` | Badge shows `placed_count/weekly_needed` in primary/warning color; card is draggable |
| BC-BIZ-09 | Activity with `remaining <= 0 && weekly_needed > 0` | Badge shows `placed_count/weekly_needed` in green; card shows green overlay checkmark; `draggable = false` |
| BC-BIZ-10 | Activity `weekly_needed = 0` | Badge shows `0/0` in primary colour; remaining computed as 0 |
| BC-BIZ-11 | Place activity on empty cell (no conflicts) | Cell created with `source = 'MANUAL'`, `has_conflict = false`; teachers pivots inserted; JSON returns success with activity counts |
| BC-BIZ-12 | Place activity with TEACHER_CONFLICT | Cell created with `has_conflict = true`; conflict entry type `TEACHER_CONFLICT` in `conflict_details_json`; placement succeeds |
| BC-BIZ-13 | Place activity with TEACHER_CROSS_TT | Cell created with `has_conflict = true`; conflict entry type `TEACHER_CROSS_TT`; placement succeeds |
| BC-BIZ-14 | Place activity with ROOM_CONFLICT | Cell created with `has_conflict = true`; conflict entry type `ROOM_CONFLICT`; placement succeeds |
| BC-BIZ-15 | Place activity with ROOM_CROSS_TT | Cell created with `has_conflict = true`; conflict entry type `ROOM_CROSS_TT`; placement succeeds |
| BC-BIZ-16 | Place activity overwrites existing cell (CLASS_DOUBLE_BOOKING) | Cell updated via `updateOrCreate`; old teacher pivots deleted, new ones inserted; conflict entry type `CLASS_DOUBLE_BOOKING` |
| BC-BIZ-17 | Place activity with multiple conflicts simultaneously | All conflict types detected; `conflict_details_json` contains array of all conflict objects; `has_conflict = true` |
| BC-BIZ-18 | Place cell response returns updated activity counts | JSON includes `placed_count`, `weekly_needed`, `remaining`, `is_fully_placed` after placement |
| BC-BIZ-19 | Remove cell that exists and is not locked | Teacher pivots deleted; cell soft-deleted; JSON returns `"Cell cleared."` with updated counts |
| BC-BIZ-20 | Remove cell that does not exist | JSON returns `success: true` with `"Cell cleared."` message; no error |
| BC-BIZ-21 | Remove cell updates activity sidebar counts | Response returns `activity_id`, `placed_count`, `weekly_needed`, `remaining` for the affected activity |
| BC-BIZ-22 | Activity search/filter in sidebar | Typing in search input filters activity cards by subject name, format, teacher name |
| BC-BIZ-23 | Break period cell renders greyed out | Period with `periodType.is_break = true` shows `tt-break-cell` class with coffee icon; no droppable behaviour |
| BC-BIZ-24 | Cell with `has_conflict = true` renders with conflict style | Cell table td gets `tt-conflict-cell` class (red background `#fef2f2`) |
| BC-BIZ-25 | Cell with no conflict renders filled style | Cell table td gets `tt-filled-cell` class (green background `#ecfdf5`) |
| BC-BIZ-26 | Empty droppable cell renders empty style | Cell table td gets `tt-empty-cell` class (white background) |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|-----------------|----------------|
| BC-REF-01 | tt_timetable_cells.timetable_id | tt_timetables.id | CASCADE |
| BC-REF-02 | tt_timetable_cells.generation_run_id | tt_generation_runs.id | SET NULL |
| BC-REF-03 | tt_timetable_cells.class_group_id | sch_class_groups_jnt.id | CASCADE |
| BC-REF-04 | tt_timetable_cells.class_subgroup_id | tt_class_requirement_subgroups.id | CASCADE |
| BC-REF-05 | tt_timetable_cells.activity_id | tt_activities.id | SET NULL |
| BC-REF-06 | tt_timetable_cells.sub_activity_id | tt_sub_activities.id | SET NULL |
| BC-REF-07 | tt_timetable_cells.room_id | sch_rooms.id | SET NULL |
| BC-REF-08 | tt_timetable_cells.locked_by | sys_users.id | SET NULL |
| BC-REF-09 | tt_timetable_cell_teachers.cell_id | tt_timetable_cells.id | CASCADE |
| BC-REF-10 | tt_timetable_cell_teachers.teacher_id | sch_teachers.id | CASCADE |
| BC-REF-11 | tt_timetable_cell_teachers.assignment_role_id | tt_teacher_assignment_roles.id | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Manual Placement page loads with no timetable selected | Timetable list table is shown; class-section selector populated; no grid, no activities sidebar, no cells displayed | — | — | ⬜ |
| TC-P02 | Manual Placement page loads with timetable_id and class_section_id | Grid renders days × periods; activities sidebar populated with activity cards; existing cells shown with correct cell styles | — | — | ⬜ |
| TC-P03 | Class-section selector changes and reloads page | Page URL updates with `class_section_id`; activities update for the new class-section | — | — | ⬜ |
| TC-P04 | Timetable selector changes and reloads grid | Page URL updates with `timetable_id`; existing cells for new timetable are loaded in grid | — | — | ⬜ |
| TC-P05 | Activity sidebar renders subject name, format, type, teacher, counts | Each activity card displays subject name, format badge, type badge, teacher name, `placed_count/weekly_needed` badge, progress bar | — | — | ⬜ |
| TC-P06 | Activity with zero placements shows primary-coloured badge | Badge shows `0/N` with `bg-primary` CSS class; progress bar width = 0% | — | — | ⬜ |
| TC-P07 | Activity with partial placements shows warning-coloured badge | Badge shows `placed_count/weekly_needed` with `bg-warning text-dark` CSS class; progress bar width = `(placed/weekly)*100%` | — | — | ⬜ |
| TC-P08 | Activity becomes `is_fully_placed` when remaining = 0 | Badge shows `N/N` with `bg-success` CSS class; progress bar 100% green; `fully-placed` overlay checkmark; `draggable = false` | — | — | ⬜ |
| TC-P09 | Place activity on empty cell — no conflicts | Cell created: `source = 'MANUAL'`, `has_conflict = false`; teacher pivot records inserted; JSON `success: true`, `message: "Activity placed successfully."`; sidebar counts update | — | — | ⬜ |
| TC-P10 | Place activity on empty cell — TEACHER_CONFLICT detected | Cell created with `has_conflict = true`; `conflict_details_json` contains `TEACHER_CONFLICT` entry; JSON `success: true`, `message: "Placed with conflicts: ..."` | — | — | ⬜ |
| TC-P11 | Place activity on empty cell — TEACHER_CROSS_TT detected | Cell created with `has_conflict = true`; `conflict_details_json` contains `TEACHER_CROSS_TT` entry with conflicting timetable name | — | — | ⬜ |
| TC-P12 | Place activity on empty cell — ROOM_CONFLICT detected | Cell created with `has_conflict = true`; `conflict_details_json` contains `ROOM_CONFLICT` entry with room name | — | — | ⬜ |
| TC-P13 | Place activity on empty cell — ROOM_CROSS_TT detected | Cell created with `has_conflict = true`; `conflict_details_json` contains `ROOM_CROSS_TT` entry with occupying timetable name | — | — | ⬜ |
| TC-P14 | Place activity on cell already holding a different activity — CLASS_DOUBLE_BOOKING | Cell updated via `updateOrCreate`; old teacher pivots replaced with new ones; `conflict_details_json` contains `CLASS_DOUBLE_BOOKING` entry | — | — | ⬜ |
| TC-P15 | Place activity with multiple simultaneous conflicts | All applicable conflict types detected and stored in `conflict_details_json` array; `has_conflict = true` | — | — | ⬜ |
| TC-P16 | Place activity on same cell again (same activity re-dropped) | `updateOrCreate` runs; no change to activity_id; teacher pivots re-inserted (no-op effect); `has_conflict` recalculated | — | — | ⬜ |
| TC-P17 | Remove cell that exists and is not locked | Teacher pivot records deleted; cell soft-deleted (`deleted_at` set); JSON `success: true`, `message: "Cell cleared."`; sidebar counts updated | — | — | ⬜ |
| TC-P18 | Remove cell updates activity sidebar counts | Response returns `activity_id`, `placed_count`, `weekly_needed`, `remaining`; frontend updates the activity card badge and progress bar | — | — | ⬜ |
| TC-P19 | Activity count progression from 0 to fully-placed after repeated placements | After placing enough times to reach `weekly_needed`, the activity card shows green badge, checkmark overlay, and `draggable = false` | — | — | ⬜ |
| TC-P20 | Grid cell renders with correct CSS class based on state | Empty cell → `tt-empty-cell`; Filled cell (no conflict) → `tt-filled-cell`; Filled cell (conflict) → `tt-conflict-cell`; Break period → `tt-break-cell` | — | — | ⬜ |
| TC-P21 | Break period cells display icon and are not droppable | Break period cells show mug-hot icon; no drag-over events fire; no `droppable-cell` class present | — | — | ⬜ |
| TC-P22 | Activity search/filter in sidebar | Typing a subject name filters activity cards; unmatched cards hidden; matched cards visible | — | — | ⬜ |
| TC-P23 | Remove cell for activity that was already fully-placed causes `is_fully_placed` to revert to false | After removal, remaining > 0; activity card draggable becomes true; checkmark overlay removed; badge colour changes from green to warning/primary | — | — | ⬜ |
| TC-P24 | Place cell with `class_subgroup_id` present | Cell created with both `class_group_id` and `class_subgroup_id` set; UNIQUE KEY constraint satisfied; no CHECK violation | — | — | ⬜ |
| TC-P25 | Create new timetable via modal and redirect to grid | Modal submits POST `create-timetable`; on success, page reloads with new `timetable_id`; grid loads with the new empty timetable | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Place activity on a published timetable | HTTP 422: `{"success": false, "message": "Published timetables are immutable."}`; no cell created | — | — | ⬜ |
| TC-N02 | Place activity on a break period | HTTP 422: `{"success": false, "message": "Cannot place an activity in a break period."}`; no cell created | — | — | ⬜ |
| TC-N03 | Remove cell from a published timetable | HTTP 422: `{"success": false, "message": "Published timetables are immutable."}`; cell not removed | — | — | ⬜ |
| TC-N04 | Remove cell that is locked | HTTP 422: `{"success": false, "message": "Cell is locked."}`; cell not removed | — | — | ⬜ |
| TC-N05 | Access manual placement page without permission | HTTP 403 Forbidden; page not rendered | — | — | ⬜ |
| TC-N06 | Send POST `place-cell` without `standard-timetable.manualPlace` permission | HTTP 403 Forbidden; cell not created | — | — | ⬜ |
| TC-N07 | Send POST `remove-cell` without `standard-timetable.manualPlace` permission | HTTP 403 Forbidden; cell not removed | — | — | ⬜ |
| TC-N08 | Guest (unauthenticated) attempts to access `GET manual-placement` | Redirected to `/login` | — | — | ⬜ |
| TC-N09 | Guest sends POST to `place-cell` | Redirected to `/login` or 401; no cell created | — | — | ⬜ |
| TC-N10 | Submit `place-cell` with non-existent `timetable_id` | HTTP 422 validation error: `timetable_id` does not exist | — | — | ⬜ |
| TC-N11 | Submit `place-cell` with non-existent `activity_id` | HTTP 422 validation error: `activity_id` does not exist | — | — | ⬜ |
| TC-N12 | Submit `place-cell` with `activity_id` not belonging to the submitted `class_group_id` | HTTP 422 validation error: `activity_id` does not match scoped exists rule | — | — | ⬜ |
| TC-N13 | Submit `place-cell` with `day_of_week` = 0 | HTTP 422 validation error: `day_of_week` must be at least 1 | — | — | ⬜ |
| TC-N14 | Submit `place-cell` with `day_of_week` = 8 | HTTP 422 validation error: `day_of_week` must be at most 7 | — | — | ⬜ |
| TC-N15 | Submit `place-cell` with `period_ord` = 0 | HTTP 422 validation error: `period_ord` must be at least 1 | — | — | ⬜ |
| TC-N16 | Submit `place-cell` missing required field `activity_id` | HTTP 422 validation error: `activity_id` is required | — | — | ⬜ |
| TC-N17 | Submit `place-cell` missing required field `timetable_id` | HTTP 422 validation error: `timetable_id` is required | — | — | ⬜ |
| TC-N18 | Submit `place-cell` missing required field `day_of_week` | HTTP 422 validation error: `day_of_week` is required | — | — | ⬜ |
| TC-N19 | Submit `place-cell` missing required field `period_ord` | HTTP 422 validation error: `period_ord` is required | — | — | ⬜ |
| TC-N20 | Submit `place-cell` missing required field `class_group_id` | HTTP 422 validation error: `class_group_id` is required | — | — | ⬜ |
| TC-N21 | Submit `remove-cell` with non-existent `timetable_id` | HTTP 422 validation error: `timetable_id` does not exist | — | — | ⬜ |
| TC-N22 | Submit `remove-cell` missing required field `day_of_week` | HTTP 422 validation error: `day_of_week` is required | — | — | ⬜ |
| TC-N23 | Submit `remove-cell` with `day_of_week` = 8 | HTTP 422 validation error: `day_of_week` must be at most 7 | — | — | ⬜ |
| TC-N24 | Remove cell that does not exist (no cell at given coordinates) | JSON `success: true`, `message: "Cell cleared."`; no error thrown — the method handles missing cell gracefully by treating it as a successful no-op | — | — | ⬜ |
| TC-N25 | Submit `remove-cell` missing required field `class_group_id` | HTTP 422 validation error: `class_group_id` is required | — | — | ⬜ |
| TC-N26 | DB exception during place-cell (e.g., FK constraint violation) | Transaction rolls back; HTTP 500: `{"success": false, "message": "Failed to place cell: {detail}"}`; no partial data written | — | — | ⬜ |
| TC-N27 | DB exception during remove-cell | Transaction rolls back; HTTP 500: `{"success": false, "message": "Failed to remove cell."}`; cell and teacher pivots unchanged | — | — | ⬜ |
| TC-N28 | Submit `place-cell` with non-integer `activity_id` (string) | HTTP 422 validation error: `activity_id` must be an integer | — | — | ⬜ |
| TC-N29 | Submit `place-cell` with non-integer `day_of_week` (string) | HTTP 422 validation error: `day_of_week` must be an integer | — | — | ⬜ |
| TC-N30 | No class-sections exist with `is_active = true` | Class-section selector empty; no activities load; grid cannot render | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Place and remove cell — verify activity log entries | `placeCell` logs `activityLog($cell, 'Placed', ...)`; `removeCell` logs `activityLog($cell, 'Removed', ...)`; log entries appear in the activity log table | — | — | ⬜ |
| TC-D02 | B | Remove cell — verify `tt_timetable_cell_teachers` records are cascade deleted | After cell removal, query `tt_timetable_cell_teachers WHERE cell_id = X` returns zero rows | — | — | ⬜ |
| TC-D03 | B | Delete timetable — verify cells cascade deleted | When a timetable is force-deleted via `deleteTimetable`, all its `tt_timetable_cells` rows are cascade deleted (DDL: ON DELETE CASCADE) | — | — | ⬜ |
| TC-D04 | C | Delete activity referenced by a cell — verify activity_id set to NULL | When the activity in `tt_activities` is deleted, the cell's `activity_id` becomes NULL (DDL: ON DELETE SET NULL); cell remains but shows no activity | — | — | ⬜ |
| TC-D05 | D | Delete teacher referenced by `tt_timetable_cell_teachers` — verify pivot rows cascade deleted | When a teacher is deleted from `sch_teachers`, all associated `tt_timetable_cell_teachers` rows are cascade deleted (DDL: ON DELETE CASCADE) | — | — | ⬜ |
| TC-D06 | E | Delete assignment role referenced by `tt_timetable_cell_teachers` — verify RESTRICT | When `tt_teacher_assignment_roles.id` is referenced, DELETE on the role row is RESTRICTED; the role cannot be deleted while pivot records exist | — | — | ⬜ |
| TC-D07 | F | Unique key `uq_cell_tt_day_period_group` prevents duplicate placement | Inserting a cell with duplicate (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`) causes a DB constraint violation; the code uses `updateOrCreate` which updates the existing row instead | — | — | ⬜ |
| TC-D08 | G | Unique key `uq_cct_cell_teacher` prevents duplicate teacher assignment per cell | Inserting a duplicate (`cell_id`, `teacher_id`) in `tt_timetable_cell_teachers` causes a DB constraint violation; the code deletes all pivots before re-inserting, so no duplicates occur | — | — | ⬜ |
| TC-D09 | H | TT cell CHECK constraint `chk_cell_target` enforces XOR of class_group_id/class_subgroup_id | Inserting a row with both NULL or both NOT NULL violates the CHECK constraint; controller sets `class_group_id` from activity and `class_subgroup_id` separately to satisfy the constraint | — | — | ⬜ |
| TC-D10 | I | Verify `Activity` model's `teachers` relationship is eager-loaded for placement | `placeCell()` loads `activity.teachers.teacher.user` and uses the collection to insert pivot rows; if the relationship is not loaded, the `foreach` over teachers would silently produce zero pivots | — | — | ⬜ |
| TC-D11 | J | Verify `TimetableCell` `activity` relationship loads subject name for grid rendering | The grid view calls `$cell->activity?->subject?->name` via eager-loaded `activity.subject`; if the relationship fails, the cell would render "Activity" as fallback | — | — | ⬜ |
| TC-D12 | K | Conflict persistence — `ManualTimetableService::persistConflicts()` creates `ConflictDetection` record | When service's `placeCell` is called with conflicts, a `tt_conflict_detections` row is created with `detection_type = 'REAL_TIME'`, `conflict_count`, `hard_conflicts`, `soft_conflicts`, and `conflicts_json` | — | — | ⬜ |
| TC-D13 | L | Timetable `findOrFail` returns 404 for non-existent ID | Submitting `place-cell` or `remove-cell` with a `timetable_id` that passes `exists` validation but is deleted between validation and `findOrFail` would throw ModelNotFoundException → 500 | — | — | ⬜ |
| TC-D14 | M | Activity `findOrFail` returns 404 for non-existent ID | Same as D13 but for the Activity lookup in `placeCell()` | — | — | ⬜ |
| TC-D15 | N | Cross-timetable conflict check only considers current academic terms | `TEACHER_CROSS_TT` query filters timetables whose `academic_term_id` is in the set of current terms (`is_current = true`); timetables in non-current terms are excluded | — | — | ⬜ |
| TC-D16 | O | Cross-timetable conflict check only active timetables and cells | Both `TEACHER_CROSS_TT` and `ROOM_CROSS_TT` queries filter `is_active = true` on both timetable and cell | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `TimetableCell` `$fillable` matches DDL columns | The `$fillable` array includes `timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`, `activity_id`, `room_id`, `source`, `is_locked`, `has_conflict`, `conflict_details_json`, `is_active`; no extra columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `TimetableCell` `$casts` for booleans/integers/dates | `is_locked`, `has_conflict`, `is_active` cast to `boolean`; `day_of_week`, `period_ord` cast to `integer`; `deleted_at` cast to `datetime` | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `TimetableCell` has `SoftDeletes` trait | `TimetableCell` model uses `SoftDeletes`; `deleted_at` column exists in DDL; `$cell->delete()` performs soft delete | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — Relationships defined on `TimetableCell` | `belongsTo(Timetable::class)`, `belongsTo(Activity::class)`, `belongsToMany(Teacher::class)` via `tt_timetable_cell_teachers`, `belongsTo(Room::class)` | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `placeCell()` and `removeCell()` have try-catch with rollback | Both methods wrap write operations in `DB::beginTransaction()` / `try-catch` / `DB::rollBack()` on exception | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — `placeCell()` and `removeCell()` use DB transactions | All write operations (cell save, teacher pivot delete/insert, activity log) are inside a single transaction | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on all three methods | `manualPlacement()` checks `standard-timetable.manualPlace`; `placeCell()` checks `standard-timetable.manualPlace`; `removeCell()` checks `standard-timetable.manualPlace` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Activity logged on all state changes | `placeCell()` calls `activityLog($cell, 'Placed', ...)`; `removeCell()` calls `activityLog($cell, 'Removed', ...)` | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — `PlaceCellRequest` validation rules cover all fields | `timetable_id` required+integer+exists; `activity_id` required+integer+exists scoped; `day_of_week` min:1 max:7; `period_ord` min:1; `class_group_id` required+integer | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — `PlaceCellRequest.authorize()` checks `standard-timetable.manualPlace` | The `authorize()` method returns `auth()->user()->can('standard-timetable.manualPlace')`; 403 on failure | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — `RemoveCellRequest` validation rules cover all fields | `timetable_id` required+integer+exists; `day_of_week` min:1 max:7; `period_ord` min:1; `class_group_id` required+integer | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — `RemoveCellRequest.authorize()` checks `standard-timetable.manualPlace` | The `authorize()` method returns `auth()->user()->can('standard-timetable.manualPlace')`; 403 on failure | — | — | ◌ |
| TC-CR13 | CR | P1 | Policy — `StandardTimetablePolicy` has `manualPlace()` method | Policy defines `manualPlace(User $user)` delegating to `$user->can('standard-timetable.manualPlace')` | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — All three drag-and-drop routes registered in `web.php` | `GET manual-placement`, `POST place-cell`, `POST remove-cell` are registered with correct controller method binding | — | — | ◌ |
| TC-CR15 | CR | P1 | View — Blade `@can` directives on tab/action buttons | Manual Placement menu page shows the "Edit" and "New" buttons only if user can access; grid remove buttons rendered for all placed cells | — | — | ◌ |
| TC-CR16 | CR | P1 | View — Null-safe checks for relationship variables | Activity card uses `$activity->subject?->name`, `$activity->studyFormat?->name`; cell uses `$cell->activity?->subject?->name`, `$cell->teachers->first()?->user?->name` | — | — | ◌ |
| TC-CR17 | CR | P1 | JSON response consistency — all three endpoints return `success` boolean | `manualPlacement()` returns view; `placeCell()` returns `success`, `cell_id`, `has_conflict`, `conflicts`, `activity`; `removeCell()` returns `success`, `message`, `activity_id`, counts | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — TimetableCell `$fillable` matches DDL columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/TimetableFoundation/Models/TimetableCell.php` | File exists |
| 2 | Read the `$fillable` property | Array contains: `timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`, `activity_id`, `sub_activity_id`, `room_id`, `source`, `is_locked`, `has_conflict`, `conflict_details_json`, `is_active` |
| 3 | Cross-check against DDL `tt_timetable_cells` columns | Every writable column in the DDL is listed in `$fillable`; columns like `id`, `created_at`, `updated_at`, `deleted_at`, `locked_by`, `locked_at` are excluded from `$fillable` |

#### TC-CR02: Model — TimetableCell `$casts` for booleans/integers/dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read the `$casts` property in `TimetableCell.php` | `is_locked => 'boolean'`, `has_conflict => 'boolean'`, `is_active => 'boolean'`, `day_of_week => 'integer'`, `period_ord => 'integer'`, `deleted_at => 'datetime'` are present |

#### TC-CR03: Model — TimetableCell has `SoftDeletes` trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read the `use` statements at the top of `TimetableCell.php` | `use SoftDeletes;` or `use Illuminate\Database\Eloquent\SoftDeletes;` is present |
| 2 | Check DDL `tt_timetable_cells` | `deleted_at` column exists as `TIMESTAMP NULL` |

#### TC-CR04: Model — Relationships defined on TimetableCell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read `TimetableCell.php` | `belongsTo(Timetable::class)` defined as `timetable()` |
| 2 | Read `TimetableCell.php` | `belongsTo(Activity::class)` defined as `activity()` |
| 3 | Read `TimetableCell.php` | `belongsTo(Room::class)` defined as `room()` |
| 4 | Read `TimetableCell.php` | Relationship to teachers via `tt_timetable_cell_teachers` pivot defined |

#### TC-CR05: Controller — try-catch with rollback on placeCell and removeCell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetableController.php` and locate `placeCell()` lines 178–292 | The `DB::beginTransaction()` at line 212 is followed by a `try` block containing writes, and a `catch (\Exception $e)` block at line 252 calling `DB::rollBack()` |
| 2 | Locate `removeCell()` lines 297–357 | The `DB::beginTransaction()` at line 324 is followed by a `try` block, and a `catch (\Exception $e)` block at line 335 calling `DB::rollBack()` |

#### TC-CR06: Controller — DB transactions on multi-step writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `placeCell()` transaction scope | Cell create/update, teacher pivot delete, teacher pivot insert, and activity log are all inside the same `DB::beginTransaction()` / `DB::commit()` block |
| 2 | Verify `removeCell()` transaction scope | Teacher pivot delete, cell soft-delete, and activity log are all inside the same `DB::beginTransaction()` / `DB::commit()` block |

#### TC-CR07: Controller — Gate::authorize() on all three methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `manualPlacement()` | Line 90: `Gate::authorize('standard-timetable.manualPlace')` |
| 2 | Check `placeCell()` | Line 180: `Gate::authorize('standard-timetable.manualPlace')` |
| 3 | Check `removeCell()` | Line 299: `Gate::authorize('standard-timetable.manualPlace')` |

#### TC-CR08: Controller — Activity logged on all state changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `placeCell()` after commit | Line 246: `activityLog($cell, 'Placed', [...])` is called inside the transaction before commit |
| 2 | Check `removeCell()` after delete | Line 329: `activityLog($cell, 'Removed', [...])` is called inside the transaction before commit |

#### TC-CR09: Request — PlaceCellRequest validation rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PlaceCellRequest.php` | `rules()` returns array with `timetable_id`, `activity_id`, `day_of_week`, `period_ord`, `class_group_id` |
| 2 | Verify rule types | `timetable_id` has `required\|integer\|exists:tt_timetables,id`; `activity_id` has `required\|integer\|Rule::exists('tt_activities','id')->where(class_group_id)`; `day_of_week` has `required\|integer\|min:1\|max:7`; `period_ord` has `required\|integer\|min:1`; `class_group_id` has `required\|integer` |

#### TC-CR10: Request — PlaceCellRequest.authorize() checks permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PlaceCellRequest.php` | `authorize()` returns `auth()->user()->can('standard-timetable.manualPlace')` |

#### TC-CR11: Request — RemoveCellRequest validation rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RemoveCellRequest.php` | `rules()` returns array with `timetable_id`, `day_of_week`, `period_ord`, `class_group_id` as required fields with same constraints as PlaceCellRequest (minus `activity_id`) |

#### TC-CR12: Request — RemoveCellRequest.authorize() checks permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RemoveCellRequest.php` | `authorize()` returns `auth()->user()->can('standard-timetable.manualPlace')` |

#### TC-CR13: Policy — StandardTimetablePolicy has manualPlace method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetablePolicy.php` | `manualPlace(User $user)` method exists returning `$user->can('standard-timetable.manualPlace')` |

#### TC-CR14: Routes — All three routes registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` in StandardTimetable module | `Route::get('manual-placement', ...)` named `menu.manualPlacement` |
| 2 | | `Route::post('place-cell', ...)` named `placeCell` |
| 3 | | `Route::post('remove-cell', ...)` named `removeCell` |

#### TC-CR15: View — Blade permission checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `manual-placement.blade.php` | The "New" timetable button is not wrapped in `@can` but relies on route gating; the "Edit" link navigates to the placement page route |

#### TC-CR16: View — Null-safe relationship checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `manual-placement.blade.php` for `?->` | Activity cards use `$activity->subject?->name`, `$activity->studyFormat?->name`, `$activity->teachers->first()?->teacher?->user?->name`; grid cells use `$cell->activity?->subject?->name` |

#### TC-CR17: JSON response consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `placeCell()` return | Returns `JsonResponse` with `success`, `cell_id`, `has_conflict`, `conflicts`, `activity`, `message` keys |
| 2 | Check `removeCell()` return | Returns `JsonResponse` with `success`, `message`, `activity_id`, `placed_count`, `weekly_needed`, `remaining` keys |

---

### 7.1 Positive TC Steps

#### TC-P01: Manual Placement page loads with no timetable selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as a user with `standard-timetable.manualPlace` permission | Dashboard or home page loads |
| 2 | Navigate to `GET /standard-timetable/manual-placement` | Page loads successfully with HTTP 200 |
| 3 | Observe the class-section dropdown | Dropdown is populated with active class-sections; the first one is selected |
| 4 | Observe the timetable dropdown | Dropdown shows "-- Select or Create --" option; no timetable is selected |
| 5 | Observe the grid area | Grid is NOT displayed; instead, the timetable list table is shown |
| 6 | Observe the timetable list | If timetables exist, they are shown in a table with Name, Type, Term, Cells, Status, Created By, Created, Action columns; if none exist, the empty state "No manual timetables yet" is shown with a "New Timetable" button |

#### TC-P02: Manual Placement page loads with timetable_id and class_section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a manual timetable with `generation_method = 'MANUAL'` for an active academic term and timetable type | Timetable is created and visible in the dropdown |
| 2 | Ensure at least one activity exists for the first class-section with `is_active = true` and a teacher assigned | Activity is active |
| 3 | Navigate to `GET /standard-timetable/manual-placement?class_section_id={cs_id}&timetable_id={tt_id}` | Page loads with HTTP 200 |
| 4 | Observe the class-section dropdown | The selected class-section is pre-selected |
| 5 | Observe the timetable dropdown | The selected timetable is pre-selected |
| 6 | Observe the grid area | The day × period grid is displayed as a table with day rows and period columns |
| 7 | Observe the activities sidebar | Activity cards are shown in the sidebar with subject name, format badge, type badge, teacher name, `placed_count/weekly_needed` badge, and progress bar |
| 8 | Observe the placed count badge | The badge in the top controls shows `X / Y placed` where X = existing cell count and Y = days × periods |

#### TC-P03: Class-section selector changes and reloads page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On the manual placement page, select a different class-section from the dropdown | The form auto-submits (via `onchange="this.form.submit()"`) |
| 2 | Wait for page reload | URL now contains `?class_section_id={new_id}` (and existing `timetable_id` if previously set) |
| 3 | Verify activities sidebar | Activity cards now reflect the newly selected class-section's class and section |

#### TC-P04: Timetable selector changes and reloads grid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On the manual placement page with a class-section selected, choose a timetable from the dropdown | The form auto-submits (via `onchange="this.form.submit()"`) |
| 2 | Wait for page reload | URL now contains `?timetable_id={selected_id}` (and existing `class_section_id`) |
| 3 | Verify grid cells | Existing placed cells for the selected timetable are shown in the grid with correct positions |

#### TC-P05: Activity sidebar renders subject name, format, type, teacher, counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load the manual placement page with a timetable and class-section that has activities | Activities sidebar is visible on the left |
| 2 | Inspect any activity card that has a teacher assigned | Card shows: bold subject name at top, format badge (`bg-info`), type badge (`bg-light border`), teacher name with user icon, `placed_count/weekly_needed` badge, and a thin progress bar at bottom |

#### TC-P06: Activity with zero placements shows primary-coloured badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an activity that has never been placed in the selected timetable (placed_count = 0) | The badge in the top-right of the card shows `0/N` with `bg-primary` CSS class |
| 2 | Observe the progress bar | Progress bar width is 0% (not visible) |

#### TC-P07: Activity with partial placements shows warning-coloured badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity in the grid once | The activity card badge now shows `1/N` |
| 2 | Observe badge colour | The badge has `bg-warning text-dark` CSS class |
| 3 | Observe the progress bar | The progress bar is visible at `(1/weekly_needed * 100)%` width with `bg-primary` class |

#### TC-P08: Activity becomes is_fully_placed when remaining = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity repeatedly until `placed_count = weekly_needed` | After the final successful placement, the activity card badge shows `N/N` with `bg-success` class |
| 2 | Observe the progress bar | Progress bar is at 100% width with `bg-success` class |
| 3 | Observe the overlay | A green checkmark overlay appears in the top-right corner of the card |
| 4 | Verify drag state | The card is no longer draggable (`draggable = false`) |

#### TC-P09: Place activity on empty cell — no conflicts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a cell at (day_of_week=1, period_ord=2) is empty for timetable_id=10, class_group_id=5 | Cell is empty in the grid |
| 2 | Drag activity with id=42 (Mathematics, teacher Mr. Kumar teacher_id=12) onto this cell | Drop action fires POST to `place-cell` |
| 3 | Check database `tt_timetable_cells` | Row exists with `timetable_id=10`, `day_of_week=1`, `period_ord=2`, `class_group_id=5`, `activity_id=42`, `source='MANUAL'`, `is_locked=0`, `has_conflict=0`, `conflict_details_json=NULL`, `is_active=1` |
| 4 | Check database `tt_timetable_cell_teachers` | Row exists with `cell_id=X`, `teacher_id=12`, `assignment_role_id=1`, `is_substitute=0` |
| 5 | Verify JSON response | `{"success":true, "cell_id":201, "has_conflict":false, "conflicts":[], "activity":{...}, "message":"Activity placed successfully."}` |
| 6 | Verify frontend update | Cell in grid now shows subject name "Mathematics", teacher name "Mr. Kumar"; cell has `tt-filled-cell` CSS class |

#### TC-P10: Place activity on empty cell — TEACHER_CONFLICT detected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Ensure teacher_id=12 is already assigned to a different cell at (day_of_week=1, period_ord=2) in the same timetable | Pre-existing cell `C1` at same slot with a different activity but same teacher |
| 2 | Drag activity_id=42 (which also uses teacher_id=12) onto (day_of_week=1, period_ord=2) in the same timetable | POST to `place-cell` |
| 3 | Verify `has_conflict=true` in response | `"has_conflict":true` |
| 4 | Verify conflict_details_json | Array contains entry with `"type":"TEACHER_CONFLICT"`, `"teacher_id":12`, `"message":"Mr. Kumar is already teaching ..."` |
| 5 | Verify cell is still created | `tt_timetable_cells` row exists |

#### TC-P11: Place activity on empty cell — TEACHER_CROSS_TT detected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Ensure teacher_id=15 is assigned to a cell at (day_of_week=3, period_ord=3) in timetable_id=7 (a different, active timetable in a current academic term) | Pre-existing cell in another timetable |
| 2 | Drag activity_id=55 (which uses teacher_id=15) onto (day_of_week=3, period_ord=3) in timetable_id=10 | POST to `place-cell` |
| 3 | Verify `has_conflict=true` | `"has_conflict":true` |
| 4 | Verify conflict type | `"type":"TEACHER_CROSS_TT"` with message that includes the conflicting timetable's name |
| 5 | Verify cell is created successfully | Cell exists in timetable_id=10 |

#### TC-P12: Place activity on empty cell — ROOM_CONFLICT detected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Activity requires `required_room_id=25`. Create another cell in the same timetable at (day_of_week=2, period_ord=4) with `room_id=25` | Room conflict pre-condition met |
| 2 | Drag the activity onto (day_of_week=2, period_ord=4) | POST to `place-cell` |
| 3 | Verify conflict | `"type":"ROOM_CONFLICT"` with `"room_id":25` and message including the room name |
| 4 | Verify cell created | Cell row exists |

#### TC-P13: Place activity on empty cell — ROOM_CROSS_TT detected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Activity requires `required_room_id=30`. Create a cell in a different active timetable at (day_of_week=4, period_ord=1) with `room_id=30` | Cross-timetable room conflict pre-condition met |
| 2 | Drag the activity onto (day_of_week=4, period_ord=1) | POST to `place-cell` |
| 3 | Verify conflict | `"type":"ROOM_CROSS_TT"` with message including the occupying timetable's name |
| 4 | Verify cell created | Cell row exists |

#### TC-P14: Place activity on cell already holding a different activity — CLASS_DOUBLE_BOOKING

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Cell at (day_of_week=1, period_ord=1) for class_group_id=5 already holds activity_id=44 (English) | Cell exists |
| 2 | Drag activity_id=42 (Mathematics) onto the same cell at (day_of_week=1, period_ord=1) for the same class_group_id=5 | POST to `place-cell` |
| 3 | Verify conflict | `"type":"CLASS_DOUBLE_BOOKING"` with `"message":"This class already has 'English' at this slot — it will be replaced."` |
| 4 | Verify `updateOrCreate` behaviour | The same cell record now shows `activity_id=42` (Mathematics replaces English) |
| 5 | Verify teacher pivots | Old English teacher pivots deleted; new Mathematics teacher pivots inserted |

#### TC-P15: Place activity with multiple simultaneous conflicts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Create conditions for BOTH a teacher conflict AND a room conflict at the same slot (teacher_id=12 already teaching at same slot; room_id=25 already booked at same slot) | Multiple conflict conditions |
| 2 | Drag the conflicting activity onto the slot | POST to `place-cell` |
| 3 | Verify `conflicts` array | Array contains two or more entries with different type values (e.g., `TEACHER_CONFLICT` and `ROOM_CONFLICT`) |
| 4 | Verify `has_conflict=true` | `"has_conflict":true` |
| 5 | Verify cell is still created | Cell row exists |

#### TC-P16: Place activity on same cell again (same activity re-dropped)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Activity 42 is already placed at (day_of_week=1, period_ord=2) | Cell exists with activity_id=42 |
| 2 | Drag the same activity 42 onto the same cell | POST to `place-cell` |
| 3 | Verify `updateOrCreate` | Cell record is updated (no visible change to activity_id); teacher pivots are re-inserted (delete + insert) |
| 4 | Check unique key constraint | No duplicate key violation because `updateOrCreate` matched on composite key |

#### TC-P17: Remove cell that exists and is not locked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Ensure a cell exists at (day_of_week=1, period_ord=2) with `is_locked=0` in timetable_id=10 | Cell is removable |
| 2 | Click the remove button (X) on this cell or trigger removal via frontend | POST to `remove-cell` with `timetable_id=10`, `day_of_week=1`, `period_ord=2`, `class_group_id=5` |
| 3 | Check database `tt_timetable_cells` | The cell's `deleted_at` is now set (soft deleted) |
| 4 | Check database `tt_timetable_cell_teachers` | Rows with `cell_id=X` are deleted (cascade) |
| 5 | Verify JSON response | `{"success":true, "message":"Cell cleared.", "activity_id":42, "placed_count":N, "weekly_needed":M, "remaining":K}` |
| 6 | Verify frontend | Grid cell is now empty with `tt-empty-cell` class |

#### TC-P18: Remove cell updates activity sidebar counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current `placed_count` for an activity in the sidebar = 3 | Activity shows `3/6` badge |
| 2 | Remove one placed cell of that activity | POST to `remove-cell` |
| 3 | Observe the JSON response | `"activity_id":42, "placed_count":2, "weekly_needed":6, "remaining":4` |
| 4 | Observe frontend sidebar | The activity card badge now shows `2/6`; progress bar width decreased |

#### TC-P19: Activity count progression from 0 to fully-placed after repeated placements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Start with an activity that has `weekly_needed=3` and no placements | Badge shows `0/3` in primary colour; progress bar 0% |
| 2 | Place the activity on Monday Period 1 | Badge shows `1/3` in warning colour; progress bar ~33% |
| 3 | Place the same activity on Tuesday Period 1 | Badge shows `2/3` in warning colour; progress bar ~66% |
| 4 | Place the same activity on Wednesday Period 1 | Badge shows `3/3` in green `bg-success`; progress bar 100%; checkmark overlay appears; card is no longer draggable |

#### TC-P20: Grid cell renders with correct CSS class based on state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Observe an empty cell (no activity placed) | Cell `td` has `tt-empty-cell` class (white background) |
| 2 | Place an activity with no conflicts | Cell `td` now has `tt-filled-cell` class (green background `#ecfdf5`) |
| 3 | Place an activity that causes a conflict | Cell `td` now has `tt-conflict-cell` class (red background `#fef2f2`) |
| 4 | Observe a break period cell | Cell `td` has `tt-break-cell` class (grey background `#e2e8f0`, mug-hot icon) |

#### TC-P21: Break period cells display icon and are not droppable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate a period in the grid whose `periodType.is_break = true` | The cell contains `<i class="fa-solid fa-mug-hot"></i>` |
| 2 | Verify the cell does NOT have class `droppable-cell` | No `droppable-cell`, `ondragover`, `ondrop` attributes |

#### TC-P22: Activity search/filter in sidebar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Type "Math" into the search input above the activity list | Only activities whose `data-search` contains "math" remain visible; all others are hidden (`display: none`) |
| 2 | Clear the search input | All activities become visible again |

#### TC-P23: Remove cell for fully-placed activity causes reversion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fully place an activity (weekly_needed=2, placed_count=2) | Card shows green badge, checkmark, not draggable |
| 2 | Remove one of its cells | Card badge now shows `1/2` in warning colour; checkmark removed; card becomes draggable again |

#### TC-P24: Place cell with class_subgroup_id present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure the activity has `class_subgroup_id` set to a non-null value | Activity has both `class_group_id` and `class_subgroup_id` |
| 2 | Place the activity on an empty cell | Cell created with both `class_group_id` and `class_subgroup_id` set |
| 3 | Verify `chk_cell_target` CHECK constraint | Constraint satisfied because `class_group_id IS NOT NULL AND class_subgroup_id IS NULL` is false BUT the other branch `(class_group_id IS NULL AND class_subgroup_id IS NOT NULL)` — this would fail CHECK if both are NOT NULL. Need to confirm actual DDL CHECK behaviour |

> **Note:** The DDL CHECK constraint `chk_cell_target` requires exactly one of `class_group_id` or `class_subgroup_id` to be non-null (XOR). If the code sets both values, it would violate this CHECK constraint. This indicates a potential code↔DDL discrepancy that needs verification.

#### TC-P25: Create new timetable via modal and redirect to grid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "New Timetable" button | Modal `#createTimetableModal` opens with Name, Academic Term, and Timetable Type fields |
| 2 | Enter "Test Timetable" as name, select a term and type | Fields populated |
| 3 | Click "Create & Start" | POST to `create-timetable` |
| 4 | Verify JSON response | `{"success":true, "timetable":{"id":25, ...}, "message":"Timetable 'Test Timetable' created."}` |
| 5 | Verify page redirect | Page reloads with `?timetable_id=25` in URL; grid loads with the new empty timetable |

---

### 7.2 Negative TC Steps

#### TC-N01: Place activity on a published timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Set `tt_timetables.status = 'PUBLISHED'` for timetable_id=10 | Timetable is published |
| 2 | Drag any activity onto any cell in timetable_id=10 | POST to `place-cell` |
| 3 | Verify response | HTTP 422: `{"success":false, "message":"Published timetables are immutable."}` |
| 4 | Verify database | No new cell created in `tt_timetable_cells` for timetable_id=10 |

#### TC-N02: Place activity on a break period

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Period at `period_ord=4` in the selected period set has `period_type_id` pointing to a type with `is_break=1` | Break period exists |
| 2 | Drag any activity onto the break period cell in the grid | POST to `place-cell` |
| 3 | Verify response | HTTP 422: `{"success":false, "message":"Cannot place an activity in a break period."}` |
| 4 | Verify database | No cell created at (timetable_id, day_of_week=any, period_ord=4) for this activity |

#### TC-N03: Remove cell from a published timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: timetable_id=10 has `status='PUBLISHED'` and a cell exists at (day_of_week=1, period_ord=2) | Published timetable with a cell |
| 2 | Attempt to remove the cell | POST to `remove-cell` |
| 3 | Verify response | HTTP 422: `{"success":false, "message":"Published timetables are immutable."}` |
| 4 | Verify database | Cell still exists in `tt_timetable_cells` with `deleted_at = NULL` |

#### TC-N04: Remove cell that is locked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Cell at (day_of_week=2, period_ord=3) has `is_locked=1` | Cell is locked |
| 2 | Attempt to remove the locked cell | POST to `remove-cell` |
| 3 | Verify response | HTTP 422: `{"success":false, "message":"Cell is locked."}` |
| 4 | Verify database | Cell still exists with `deleted_at = NULL` |

#### TC-N05: Access manual placement page without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as a user who does NOT have `standard-timetable.manualPlace` permission | User is authenticated but lacks the gate |
| 2 | Navigate to `GET /standard-timetable/manual-placement` | HTTP 403 Forbidden; page content not rendered |

#### TC-N06: Send POST place-cell without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | As a user without `standard-timetable.manualPlace`, send POST to `place-cell` with valid data | HTTP 403 Forbidden (from `PlaceCellRequest::authorize()` or `Gate::authorize()`) |

#### TC-N07: Send POST remove-cell without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | As a user without `standard-timetable.manualPlace`, send POST to `remove-cell` with valid data | HTTP 403 Forbidden |

#### TC-N08: Guest attempts to access manual placement page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out or open a private/incognito browser window | Not authenticated |
| 2 | Navigate to `GET /standard-timetable/manual-placement` | Redirected to `/login` |

#### TC-N09: Guest sends POST to place-cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | As an unauthenticated user, send POST to `place-cell` with valid data | Redirected to `/login` (web route with auth middleware) or 401 |

#### TC-N10: Submit place-cell with non-existent timetable_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `timetable_id=99999` (non-existent) | HTTP 422: validation error for `timetable_id` field ("The selected timetable_id is invalid.") |

#### TC-N11: Submit place-cell with non-existent activity_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `activity_id=99999` (non-existent) | HTTP 422: validation error for `activity_id` field |

#### TC-N12: Submit place-cell with activity_id not belonging to the class_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `class_group_id=5` and `activity_id=100` where activity 100 has `class_group_id=10` | HTTP 422: validation error — the `exists` rule is scoped by `class_group_id`, so the activity is not found |

#### TC-N13: Submit place-cell with day_of_week = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `day_of_week=0` | HTTP 422: `day_of_week` must be at least 1 |

#### TC-N14: Submit place-cell with day_of_week = 8

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `day_of_week=8` | HTTP 422: `day_of_week` must be at most 7 |

#### TC-N15: Submit place-cell with period_ord = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `period_ord=0` | HTTP 422: `period_ord` must be at least 1 |

#### TC-N16: Submit place-cell missing activity_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with all fields except `activity_id` | HTTP 422: `activity_id` is required |

#### TC-N17: Submit place-cell missing timetable_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with all fields except `timetable_id` | HTTP 422: `timetable_id` is required |

#### TC-N18: Submit place-cell missing day_of_week

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with all fields except `day_of_week` | HTTP 422: `day_of_week` is required |

#### TC-N19: Submit place-cell missing period_ord

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with all fields except `period_ord` | HTTP 422: `period_ord` is required |

#### TC-N20: Submit place-cell missing class_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with all fields except `class_group_id` | HTTP 422: `class_group_id` is required |

#### TC-N21: Submit remove-cell with non-existent timetable_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `remove-cell` with `timetable_id=99999` | HTTP 422: validation error for `timetable_id` |

#### TC-N22: Submit remove-cell missing day_of_week

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `remove-cell` with all fields except `day_of_week` | HTTP 422: `day_of_week` is required |

#### TC-N23: Submit remove-cell with day_of_week = 8

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `remove-cell` with `day_of_week=8` | HTTP 422: `day_of_week` must be at most 7 |

#### TC-N24: Remove cell that does not exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a coordinate (day_of_week, period_ord, class_group_id) that has NO cell in the timetable | No cell exists at those coordinates |
| 2 | Send POST to `remove-cell` with those coordinates and a valid timetable_id | HTTP 200: `{"success":true, "message":"Cell cleared."}` (graceful no-op) |

#### TC-N25: Submit remove-cell missing class_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `remove-cell` with all fields except `class_group_id` | HTTP 422: `class_group_id` is required |

#### TC-N26: DB exception during place-cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate a DB failure (e.g., violate FK constraint manually or mock a failure) during `placeCell` | Transaction catches exception; `DB::rollBack()` called |
| 2 | Verify response | HTTP 500: `{"success":false, "message":"Failed to place cell: {detail}"}` |
| 3 | Verify no partial data | No cell created in `tt_timetable_cells`; no orphan teacher pivots inserted |

#### TC-N27: DB exception during remove-cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate a DB failure during `removeCell` | Transaction rolls back |
| 2 | Verify response | HTTP 500: `{"success":false, "message":"Failed to remove cell."}` |
| 3 | Verify no partial data | Cell still exists with `deleted_at = NULL`; teacher pivots still exist |

#### TC-N28: Submit place-cell with non-integer activity_id (string)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `activity_id="abc"` | HTTP 422: validation error — `activity_id` must be an integer |

#### TC-N29: Submit place-cell with non-integer day_of_week (string)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `place-cell` with `day_of_week="mon"` | HTTP 422: validation error — `day_of_week` must be an integer |

#### TC-N30: No class-sections exist with is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `sch_class_sections_jnt` has no active records (`is_active = 0` for all) | No class-sections to select |
| 2 | Navigate to `GET manual-placement` | Page loads but class-section dropdown is empty; no grid or activities can be loaded because `selectedClassSection` will be null |

---

### 7.3 Dependency TC Steps

#### TC-D01: Place and remove cell — verify activity log entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity on an empty cell | POST to `place-cell` succeeds |
| 2 | Query the activity log table (or check `activityLog()` call) | An entry exists with `type='Placed'`, message containing the activity name, day, and period |
| 3 | Remove the same cell | POST to `remove-cell` succeeds |
| 4 | Query the activity log table | An entry exists with `type='Removed'`, message "Activity removed from cell." |

#### TC-D02: Remove cell — verify cell_teachers cascade delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity on a cell (activity has 2 teachers) | Two rows inserted into `tt_timetable_cell_teachers` with `cell_id=X` |
| 2 | Note the `cell_id` from the placed cell | cell_id = X |
| 3 | Remove the cell | POST to `remove-cell` succeeds |
| 4 | Query `SELECT COUNT(*) FROM tt_timetable_cell_teachers WHERE cell_id = X` | Count = 0 (cascade deleted when cell was soft-deleted — actually the code explicitly deletes them before soft-delete; the cascade is a safety net) |

#### TC-D03: Delete timetable — verify cells cascade deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a timetable with a few placed cells | Cells exist in `tt_timetable_cells` for this timetable_id |
| 2 | Delete the timetable via `deleteTimetable` endpoint | Timetable force-deleted; cells force-deleted |
| 3 | Query `SELECT COUNT(*) FROM tt_timetable_cells WHERE timetable_id = X` | Count = 0 (CASCADE from ON DELETE CASCADE FK) |

#### TC-D04: Delete activity — verify activity_id set to NULL in cells

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity (activity_id=42) in a cell | Cell has `activity_id=42` |
| 2 | Delete the activity from `tt_activities` (soft or hard delete) | Activity removed |
| 3 | Query the cell again | `activity_id = NULL` (ON DELETE SET NULL) |

#### TC-D05: Delete teacher — verify pivot rows cascade deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity with teacher_id=12 | Pivot row exists in `tt_timetable_cell_teachers` with `teacher_id=12` |
| 2 | Delete the teacher from `sch_teachers` where `id=12` | Teacher deleted |
| 3 | Query `tt_timetable_cell_teachers WHERE teacher_id=12` | No rows returned (ON DELETE CASCADE) |

#### TC-D06: Delete assignment role — verify RESTRICT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to DELETE a row from `tt_teacher_assignment_roles` that is referenced by at least one `tt_timetable_cell_teachers` row | DB constraint violation: "Cannot delete or update a parent row: a foreign key constraint fails" (ON DELETE RESTRICT) |

#### TC-D07: Unique key prevents duplicate composite key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a cell manually with (timetable_id=10, day_of_week=1, period_ord=2, class_group_id=5, class_subgroup_id=NULL) | Insert succeeds |
| 2 | Attempt to insert another cell with the identical composite key values | `Integrity constraint violation: Duplicate entry` error from the `uq_cell_tt_day_period_group` unique key |

#### TC-D08: Unique key prevents duplicate teacher per cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a pivot row in `tt_timetable_cell_teachers` with (cell_id=201, teacher_id=12) | Insert succeeds |
| 2 | Attempt to insert another row with (cell_id=201, teacher_id=12) | `Integrity constraint violation: Duplicate entry` from `uq_cct_cell_teacher`; the code avoids this by deleting before re-inserting |

#### TC-D09: CHECK constraint chk_cell_target enforcement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to insert a cell with both `class_group_id=NULL` AND `class_subgroup_id=NULL` | CHECK constraint violation: neither is set |
| 2 | Attempt to insert a cell with both `class_group_id=5` AND `class_subgroup_id=10` | CHECK constraint May fail if DDL requires XOR. Verify against actual DDL behaviour |

> **Note:** The DDL CHECK constraint `chk_cell_target` specifies: `(class_group_id IS NOT NULL AND class_subgroup_id IS NULL) OR (class_group_id IS NULL AND class_subgroup_id IS NOT NULL)`. This enforces that exactly one of the two must be non-null (XOR). If the controller's `updateOrCreate` sets both values simultaneously, the constraint will be violated.

#### TC-D10: Activity teachers relationship eager-loaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Place an activity that has teachers | The `activity` model is loaded with `->with(['teachers.teacher.user'])` before placement |
| 2 | Verify that `$activity->teachers` is a populated Collection (not requiring lazy load) | The `foreach ($activity->teachers as $at)` loop executes with the pre-loaded relationship data |

#### TC-D11: Cell activity relationship loaded for grid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load the manual placement page with a timetable that has cells | Cells are eager-loaded via `TimetableCell::with(['activity.subject', ...])` |
| 2 | Verify `$cell->activity?->subject?->name` renders correctly in the grid | Each filled cell shows the subject name |

#### TC-D12: Conflict persistence via ManualTimetableService

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `ManualTimetableService::placeCell()` with data that will produce conflicts (bypass controller) | Internal `persistConflicts()` runs |
| 2 | Query `tt_conflict_detections` | A row exists with `detection_type='REAL_TIME'`, `timetable_id=X`, `conflict_count=N`, `hard_conflicts=H`, `soft_conflicts=N`, `conflicts_json` containing the conflict array |

> **Note:** The controller's `placeCell()` does NOT call `persistConflicts()`. Only the `ManualTimetableService::placeCell()` method does. This test is relevant for the service layer, not the controller.

#### TC-D13: Timetable findOrFail returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit a request to `place-cell` or `remove-cell` with a `timetable_id` that exists in validation but is deleted just before `findOrFail` | `ModelNotFoundException` would be thrown, resulting in a 500 error (unless a global exception handler catches it) |

#### TC-D14: Activity findOrFail returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit a `place-cell` request with an `activity_id` that exists in validation but is deleted before `findOrFail` | `ModelNotFoundException` thrown → HTTP 500 |

#### TC-D15: Cross-timetable check only current terms

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Create a teacher conflict in a timetable that belongs to a non-current academic term (`is_current=0`) | Teacher has a cell at same slot in a non-current term's timetable |
| 2 | Place the same teacher in a different timetable at the same slot | No `TEACHER_CROSS_TT` conflict is generated because the conflicting timetable is in a non-current term |

#### TC-D16: Cross-timetable checks only active timetables and cells

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Create a teacher conflict in a timetable with `is_active=0` or a cell with `is_active=0` | Teacher has a cell in an inactive timetable/cell at same slot |
| 2 | Place the same teacher at the same slot | No `TEACHER_CROSS_TT` conflict generated (the query filters `is_active=true`) |
