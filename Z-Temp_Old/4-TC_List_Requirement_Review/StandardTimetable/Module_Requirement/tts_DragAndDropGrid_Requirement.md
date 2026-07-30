# Drag-and-Drop Grid & Conflict Checking — Business Requirements

## What This Screen Does

The drag-and-drop grid is the core interactive component of the Standard Timetable module. It provides a visual day‑×‑period grid where timetable administrators can manually place curriculum activities from a sidebar onto specific slots, and remove them as needed. The backend enforces a five‑rule conflict engine that checks for scheduling clashes both within the same timetable and across all other active timetables in the school, flagging every conflict without blocking the placement so the planner can see and resolve issues iteratively.

The screen is designed as a manual refinement tool — it complements the auto‑generation engine by letting human planners adjust, replace, and fine‑tune the timetable before publishing.

## When This Screen Is Used

- **Initial timetable refinement** — after the smart generator produces a draft timetable, the planner opens the drag‑and‑drop grid to review and manually adjust placements before publishing.
- **Curriculum or staffing changes** — when subjects, teacher assignments, or room allocations change mid‑term, the planner re‑opens the grid to move or replace activities.
- **Building timetables from scratch** — for schools that do not use auto‑generation, the grid is the primary interface for building a manual timetable cell by cell.
- **Cross‑timetable conflict resolution** — when a teacher or room is double‑booked across multiple class timetables, the grid surfaces all five conflict types in real time so the planner can decide which timetable to adjust.
- **Pre‑publishing sanity check** — before publishing, the planner scans the grid for any remaining conflict warnings (badges) and resolves them.

## Default Data Load

The screen is loaded by the `manualPlacement()` method (lines 88–173) in `StandardTimetableController`, served under the `GET manual-placement` route (named `menu.manualPlacement`). The view receives the full set of shared dropdowns and collections; no pagination is used because the grid must render all days × periods for the selected class-section.

| Data | Source Method | Query | Filters |
|------|--------------|-------|---------|
| Class‑sections | `manualPlacement()` | `ClassSection::with(['class','section'])->where('is_active',true)->orderBy('ordinal')` | `is_active = true` |
| School days | `manualPlacement()` | `SchoolDay::where('is_school_day',true)->where('is_active',true)->orderBy('ordinal')` | `is_school_day = true`, `is_active = true` |
| Period sets + periods | `manualPlacement()` | `PeriodSet::where('is_active',true)->orderBy('name')` then `periods()` relation on the default set | `is_active = true`; default set = `is_default = true` or first active |
| Timetable types | `manualPlacement()` | `TimetableType::where('is_active',true)->orderBy('ordinal')` | `is_active = true` |
| Academic terms | `manualPlacement()` | `AcademicTerm::orderByDesc('is_current')->orderBy('term_start_date')` | None |
| Manual timetables | `manualPlacement()` | `Timetable::where('generation_method','MANUAL')->where('is_active',true)->withCount('cells')->with(['timetableType','academicTerm','createdBy'])->orderByDesc('created_at')` | `generation_method = 'MANUAL'`, `is_active = true` |
| Activities | `manualPlacement()` | `Activity::with(['subject','studyFormat','subjectType','teachers.teacher.user','teachers.assignmentRole'])->where('class_id',$cs->class_id)->where('section_id',$cs->section_id)->where('is_active',true)->orderBy('subject_id')` | `class_id` + `section_id` from selected class‑section, `is_active = true` |
| Existing placed cells | `manualPlacement()` | `TimetableCell::with(['activity.subject','activity.studyFormat','activity.requiredRoomType','teachers.user'])->where('timetable_id',$ttId)->whereHas('activity',fn=>class_id+section_id)->get()->keyBy("day_of_week-period_ord")` | `timetable_id` from query param; activity belongs to selected class‑section |
| Rooms | `manualPlacement()` | `Room::with('roomType')->where('is_active',true)->orderBy('name')` | `is_active = true` |

Selected class‑section defaults to the first active class‑section when no `class_section_id` query parameter is provided. Selected timetable defaults to none (no activities or existing cells are loaded until both a class‑section and a timetable are chosen).

## Key Fields at a Glance

**Activity Sidebar Tracking**

- **`weekly_needed`** — the number of periods this activity requires per week, sourced from `activity.required_weekly_periods` (fallback to `activity.weekly_periods`, default 0).
- **`placed_count`** — how many times this activity is currently placed in `tt_timetable_cells` for the selected timetable.
- **`remaining`** — calculated as `max(0, weekly_needed - placed_count)`, drives the `is_fully_placed` flag.
- **`is_fully_placed`** — set to `true` when `remaining <= 0 && weekly_needed > 0`; the UI should visually distinguish fully‑placed activities.

**Grid Cell Coordinates**

- **`day_of_week`** — integer 1–7 representing the school day (1 = Monday, as ordered in `sch_school_days`).
- **`period_ord`** — integer representing the period sequence within the day (1‑based, from the period set's defined periods).
- **`class_group_id`** — the class group the cell targets, sourced from the activity's `class_group_id`.

**Cell State Flags**

- **`is_locked`** — boolean; locked cells cannot be removed via `removeCell` until unlocked through the lock/unlock endpoints. Manual placement always creates cells with `is_locked = false`.
- **`source`** — enum (`AUTO`, `MANUAL`, `SWAP`, `LOCK`); manual placements set this to `'MANUAL'`.
- **`has_conflict`** — boolean flag set to `true` when the conflict engine finds any clash for this placement.
- **`conflict_details_json`** — JSON array of conflict objects. Each object contains `type`, `message`, and identifiers (`teacher_id`, `room_id`, `conflicting_cell_id`) as applicable.

**Teacher Assignment per Cell**

- **`tt_timetable_cell_teachers`** — pivot records that link a cell to one or more teachers. Each record stores the `assignment_role_id` (e.g., primary instructor, assistant) and an `is_substitute` flag. Manual placement always inserts with `is_substitute = false`.

## Business Rules and Conditions

**Published Timetable Immutability**

Both `placeCell` and `removeCell` reject any modification to a timetable whose `status` is `'PUBLISHED'`. The system MUST return HTTP 422 with the message "Published timetables are immutable." No cell placement, removal, or modification is permitted on a published timetable.

**Break Period Protection**

Periods whose associated `periodType` has `is_break = true` are blocked from receiving any activity. If a user drops an activity onto a break period, the system MUST return HTTP 422 with "Cannot place an activity in a break period."

**Intra‑Timetable Teacher Conflict (`TEACHER_CONFLICT`)**

When an activity is placed, the system MUST check whether any of the activity's assigned teachers are already teaching a different subject in another cell of the **same timetable** at the same `day_of_week` and `period_ord`. If found, a `TEACHER_CONFLICT` entry is added to the conflict list.

**Cross‑Timetable Teacher Conflict (`TEACHER_CROSS_TT`)**

The system MUST also check all other active timetables that belong to current academic terms. If the teacher is already assigned to the same `day_of_week` and `period_ord` in any other active timetable, a `TEACHER_CROSS_TT` entry is added. The message names the conflicting timetable (e.g., "Mr. Verma is busy in '9-A Term 1 Published' teaching Social Studies").

**Intra‑Timetable Room Conflict (`ROOM_CONFLICT`)**

If the activity specifies a required room (`required_room_id`), the system MUST check whether that room is already assigned to another cell in the same timetable at the same `day_of_week` and `period_ord`. If found, a `ROOM_CONFLICT` entry is added.

**Cross‑Timetable Room Conflict (`ROOM_CROSS_TT`)**

The system MUST also check all other active timetables. If the required room is already occupied at the same slot in another active timetable, a `ROOM_CROSS_TT` entry is added and the message names the occupying timetable.

**Class Double‑Booking Replacement (`CLASS_DOUBLE_BOOKING`)**

If the target cell coordinate (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`) already holds a different activity (different `activity_id`), the system flags `CLASS_DOUBLE_BOOKING` with the message "This class already has '{subject}' at this slot — it will be replaced." The new activity **replaces** the old one: the `updateOrCreate` call overwrites the cell record, and the old teacher pivot records are deleted before the new ones are inserted.

**Locked Cell Protection**

Cells with `is_locked = true` cannot be removed. The `removeCell` method MUST return HTTP 422 with "Cell is locked." Locked cells can only be removed after an explicit unlock operation (via `unlock-cell` endpoint).

**Conflict Tolerance (Soft Enforcement)**

Conflicts do **not** block placement. The cell is always created or updated regardless of conflicts. The `has_conflict` flag is set to `true` and the full conflict array is stored in `conflict_details_json`. The UI is expected to surface these as warning badges. This design lets the planner see all issues at once and decide which to resolve, rather than being blocked on the first clash.

**Sidebar Count Tracking**

Every `placeCell` response returns the activity's updated `placed_count`, `weekly_needed`, `remaining`, and `is_fully_placed` so the frontend can update the sidebar without an additional API call. Every `removeCell` response returns the same updated counts for the affected activity.

## Workflow Steps

**Placing an Activity on the Grid**

1. The user selects a class‑section from the dropdown. The page auto‑loads the activities belonging to that class‑section and, if a timetable is also selected, any existing placed cells.
2. The user selects or creates a manual timetable from the timetable selector.
3. The activity sidebar displays each activity with its subject name, teacher names, `weekly_needed` count, and `remaining` count.
4. The user drags an activity from the sidebar onto a cell in the day‑×‑period grid — either an empty cell or one that already has a different activity.
5. The frontend sends a POST request to `place-cell` with `timetable_id`, `activity_id`, `day_of_week`, `period_ord`, and `class_group_id`.
6. The backend validates the request via `PlaceCellRequest`, confirms the timetable is not published, checks that the target period is not a break period, and runs the five conflict checks via `$this->checkConflicts()`.
7. The cell is created or updated via `TimetableCell::updateOrCreate()` on the composite key. The `source` is set to `'MANUAL'`, `has_conflict` is set based on conflict results, and `conflict_details_json` stores the full conflict array.
8. All existing `tt_timetable_cell_teachers` records for that cell are deleted. New pivot records are inserted from the activity's `teachers` collection (one row per teacher, with `assignment_role_id` and `is_substitute = false`).
9. An activity log entry is created.
10. The transaction commits. The response returns `cell_id`, the conflicts array, and the updated sidebar counts for the activity (`placed_count`, `remaining`, `is_fully_placed`).
11. If conflicts exist, the frontend shows warning badges (e.g., a yellow triangle) on the cell and lists the conflict messages.

**Removing an Activity from the Grid**

1. The user triggers removal on an existing cell (e.g., a delete icon or context‑menu action).
2. The frontend sends a POST request to `remove-cell` with `timetable_id`, `day_of_week`, `period_ord`, and `class_group_id`.
3. The backend validates via `RemoveCellRequest`, confirms the timetable is not published, and checks the cell is not locked.
4. If the cell exists, the teacher pivot records are deleted, then the cell is soft‑deleted via `$cell->delete()`.
5. An activity log entry is created.
6. The transaction commits. The response returns the updated counts (`placed_count`, `weekly_needed`, `remaining`) for the activity that was in the removed cell.
7. The frontend clears the cell from the grid and updates the activity sidebar.

## Example Scenario

Mrs. Sharma, the timetable coordinator at Sunshine Academy, is building the Class 10‑A timetable for Term 1. She opens the Manual Placement screen, selects "Class 10, Section A" from the class‑section dropdown, and creates a new manual timetable named "10‑A Term 1 Manual."

The sidebar shows six subjects:
- Mathematics — Teacher: Mr. Kumar (weekly_needed: 6, placed: 0)
- Science — Teacher: Mrs. Patel (weekly_needed: 5, placed: 0)
- English — Teacher: Ms. Singh (weekly_needed: 4, placed: 0)
- Hindi — Teacher: Mr. Gupta (weekly_needed: 3, placed: 0)
- Social Studies — Teacher: Mr. Reddy (weekly_needed: 3, placed: 0)
- Physical Education — Teacher: Coach Ali (weekly_needed: 2, placed: 0)

Mrs. Sharma drags Mathematics onto Monday Period 1. The backend places it with no conflicts. The response shows `placed_count: 1, remaining: 5`. She continues placing Mathematics across the week until all six periods are filled.

When she drags Science onto Monday Period 1 (where Mathematics already sits), the system returns a `CLASS_DOUBLE_BOOKING` conflict: "This class already has 'Mathematics' at this slot — it will be replaced." Science overwrites Mathematics. Mrs. Sharma sees the warning badge, notes it, and then moves Mathematics to Monday Period 2 instead.

Later, she drags English onto Wednesday Period 3. The assigned teacher, Ms. Singh, is already teaching Class 9‑A at the same slot in an already‑published timetable. The system returns a `TEACHER_CROSS_TT` conflict: "Ms. Singh is busy in '9‑A Term 1 Published' teaching Hindi." The placement succeeds with a warning. Mrs. Sharma makes a note to discuss the clash with the principal.

After placing all activities, she reviews the grid. Three cells show conflict badges. She resolves two by moving activities to different periods and leaves one `ROOM_CROSS_TT` — the Chemistry Lab conflict — for the principal's approval. She then publishes the timetable.

## Related Screens

- **Timetable Index** — lists all timetables with status badges; the "Manual Placement" action button on each draft timetable navigates to the drag‑and‑drop grid pre‑selected for that timetable.
- **Class View** — read‑only timetable display filtered by class‑group, used for verifying placement after manual adjustments.
- **Teacher View** — read‑only timetable display filtered by teacher, used for verifying teacher workload and spotting conflicts from the teacher's perspective.
- **Room View** — read‑only timetable display filtered by room, used for verifying room utilisation.
- **Smart Timetable Generator** — the auto‑generation engine whose output feeds into the drag‑and‑drop grid for manual refinement.
- **Publishing Workflow** — the set of operations (submit‑for‑approval, approve, publish) that transition a timetable from `DRAFT` to `PUBLISHED`, after which the grid becomes read‑only.

## Requirements

- **Controller:** `Modules\StandardTimetable\Http\Controllers\StandardTimetableController`
  - `manualPlacement()` (lines 88–173) — loads all dropdowns, activities, and existing cells for the grid view; gated by `Gate::authorize('standard-timetable.manualPlace')`.
  - `placeCell()` (lines 178–292) — AJAX endpoint that receives validated data from `PlaceCellRequest`, checks publication status (422), blocks break periods (422), runs `$this->checkConflicts()`, performs `TimetableCell::updateOrCreate()` on composite key `(timetable_id, day_of_week, period_ord, class_group_id)`, deletes and re‑inserts `tt_timetable_cell_teachers`, logs activity, commits transaction, returns JSON with cell ID, conflicts, and placement counts.
  - `removeCell()` (lines 297–357) — AJAX endpoint that receives validated data from `RemoveCellRequest`, checks publication status (422), checks `is_locked` (422), deletes pivot teachers, soft‑deletes the cell, logs activity, returns JSON with updated placement counts.
  - `checkConflicts()` (lines 462–574) — private method that accepts `timetableId`, `Activity`, `dayOfWeek`, `periodOrd` and returns an array of conflict objects. Checks five conflict types via `TimetableCell` queries against the DDL. Does **not** call the `ManualTimetableService` version (the controller has its own inline implementation).
- **Service:** `Modules\StandardTimetable\Services\ManualTimetableService`
  - `placeCell()` (line 13) — parallel implementation used by the SmartTimetable module; same `updateOrCreate` logic plus calls `persistConflicts()`.
  - `removeCell()` (line 65) — parallel implementation used by other modules.
  - `checkConflicts()` (line 118) — parallel conflict engine (omits `ROOM_CROSS_TT` check that the controller version has); also used by SmartTimetable.
  - `persistConflicts()` (line 195) — writes a `ConflictDetection` record with `detection_type = 'REAL_TIME'` and conflict summary counts.
- **Form Requests:**
  - `PlaceCellRequest` — validates `timetable_id` (required, integer, exists in `tt_timetables.id`), `activity_id` (required, integer, exists in `tt_activities.id` scoped by `class_group_id`), `day_of_week` (required, integer, min:1, max:7), `period_ord` (required, integer, min:1), `class_group_id` (required, integer). Authorizes via `standard-timetable.manualPlace`.
  - `RemoveCellRequest` — validates `timetable_id` (required, integer, exists in `tt_timetables.id`), `day_of_week` (required, integer, min:1, max:7), `period_ord` (required, integer, min:1), `class_group_id` (required, integer). Authorizes via `standard-timetable.manualPlace`.
- **Routes** (all in `Modules/StandardTimetable/routes/web.php`):
  - `GET manual-placement` → `manualPlacement` (name: `menu.manualPlacement`)
  - `POST place-cell` → `placeCell` (name: `placeCell`)
  - `POST remove-cell` → `removeCell` (name: `removeCell`)
- **Policy:** `StandardTimetablePolicy`
  - `manualPlace(User $user)` — checks `$user->can('standard-timetable.manualPlace')`. All three drag‑and‑drop methods gate on this permission.
- **Activity logging:** Every `placeCell` call logs via `activityLog($cell, 'Placed', ['message' => "Activity '{$name}' placed at day {$day}, period {$period}."])`. Every `removeCell` call logs via `activityLog($cell, 'Removed', ['message' => 'Activity removed from cell.'])`.
- **Soft deletes:** `TimetableCell` model uses `SoftDeletes`; DDL confirms `deleted_at` column. Cells are soft‑deleted on removal.
- **Database transactions:** Both `placeCell` and `removeCell` wrap all write operations (cell save + teacher pivot delete/insert + activity log) in `DB::beginTransaction` / `DB::commit` / `DB::rollBack`.
- **JSON responses:** All three endpoints return `JsonResponse`. `placeCell` and `removeCell` return `success: true/false` with appropriate HTTP status codes (200 for success, 422 for business rule violations, 500 for exceptions).

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `standard-timetable.manualPlace` | `manualPlacement()`, `placeCell()`, `removeCell()` | Required for all drag‑and‑drop operations; checked via `Gate::authorize()` in the controller AND via `authorize()` method in both `PlaceCellRequest` and `RemoveCellRequest` |
| `StandardTimetablePolicy::manualPlace()` | Policy method | Delegates to the same `standard-timetable.manualPlace` permission string |

## Logic Flow

**Page Load**

1. User navigates to `GET manual-placement` route.
2. `manualPlacement()` calls `Gate::authorize('standard-timetable.manualPlace')`.
3. Load class‑sections → filter `is_active = true` → order by `ordinal`.
4. Load school days → filter `is_school_day = true` and `is_active = true` → order by `ordinal`.
5. Load period sets → filter `is_active = true` → identify default set (`is_default = true`) or first active set → load its periods via `periods()` relation → order by `period_ord`.
6. Load timetable types → filter `is_active = true` → order by `ordinal`.
7. Load academic terms → order by `is_current DESC` then `term_start_date ASC`.
8. Load manual timetables → filter `generation_method = 'MANUAL'` and `is_active = true` → with cell counts, timetable type, academic term, created by → order by `created_at DESC`.
9. Determine selected class‑section from query param `class_section_id`, or default to first active class‑section.
10. If class‑section is selected, load its activities (with `subject`, `studyFormat`, `subjectType`, `teachers.teacher.user`, `teachers.assignmentRole`) → filter `class_id` + `section_id` + `is_active = true` → order by `subject_id`.
11. If a `timetable_id` query param is also given, load existing cells for that timetable → filter by activity's class/section → eager load `activity.subject`, `activity.studyFormat`, `activity.requiredRoomType`, `teachers.user` → key by `"day_of_week-period_ord"`.
12. Load rooms → filter `is_active = true` → order by `name`.
13. Render `standardtimetable::pages.manual-placement` view with all collections.

**Placing a Cell (AJAX — `POST place-cell`)**

1. Frontend sends POST with `timetable_id`, `activity_id`, `day_of_week`, `period_ord`, `class_group_id`.
2. `PlaceCellRequest::authorize()` checks `standard-timetable.manualPlace` permission (403 on failure).
3. `PlaceCellRequest::rules()` validates field types and existence (422 on failure).
4. `placeCell()` loads the `Timetable` via `findOrFail`. If `status === 'PUBLISHED'`, returns 422 with "Published timetables are immutable."
5. Loads the period from the timetable's period set at the given `period_ord`. If `period->periodType->is_break` is true, returns 422 with "Cannot place an activity in a break period."
6. Loads the `Activity` (with `subject`, `studyFormat`, `subjectType`, `teachers.teacher.user`, `teachers.assignmentRole`, `requiredRoomType`).
7. Calls `$this->checkConflicts($timetableId, $activity, $dayOfWeek, $periodOrd)` to get the conflict array.
8. `DB::beginTransaction()`.
9. `TimetableCell::updateOrCreate()` on composite key `['timetable_id', 'day_of_week', 'period_ord', 'class_group_id']` with values for `activity_id`, `class_subgroup_id`, `room_id` (from activity's `required_room_id`), `source = 'MANUAL'`, `is_locked = false`, `has_conflict`, `conflict_details_json`, `is_active = true`.
10. Delete all rows from `tt_timetable_cell_teachers WHERE cell_id = $cell->id`.
11. Insert one row per activity teacher into `tt_timetable_cell_teachers` with `cell_id`, `teacher_id`, `assignment_role_id`, `is_substitute = false`.
12. `activityLog($cell, 'Placed', ...)`.
13. `DB::commit()`.
14. Count placed occurrences of this activity in this timetable.
15. Compute `weekly_needed`, `remaining`, `is_fully_placed`.
16. Return JSON with `cell_id`, `has_conflict`, `conflicts` array, `activity` object, and `message`.

**Removing a Cell (AJAX — `POST remove-cell`)**

1. Frontend sends POST with `timetable_id`, `day_of_week`, `period_ord`, `class_group_id`.
2. `RemoveCellRequest::authorize()` checks `standard-timetable.manualPlace` (403 on failure).
3. `RemoveCellRequest::rules()` validates field types (422 on failure).
4. `removeCell()` loads the `Timetable` via `findOrFail`. If `status === 'PUBLISHED'`, returns 422 with "Published timetables are immutable."
5. Locates the cell by the composite key. If the cell exists and `is_locked === true`, returns 422 with "Cell is locked."
6. Records the `activity_id` from the cell for later count computation.
7. `DB::beginTransaction()`.
8. Delete all rows from `tt_timetable_cell_teachers WHERE cell_id = $cell->id`.
9. `$cell->delete()` (soft delete).
10. `activityLog($cell, 'Removed', ...)`.
11. `DB::commit()`.
12. If an activity was in the cell, compute updated placed count.
13. Return JSON with `activity_id`, `placed_count`, `weekly_needed`, `remaining`.

**Conflict Detection (internal — `checkConflicts()`, lines 462–574)**

1. Extract `teacher_id` values from `$activity->teachers` collection.
2. **TEACHER_CONFLICT:** Query `TimetableCell` where same `timetable_id`, `day_of_week`, `period_ord`, and `has` teachers with matching IDs. For each matching teacher, push conflict with `type = 'TEACHER_CONFLICT'` and the teacher's name + conflicting subject.
3. **TEACHER_CROSS_TT:** Query `TimetableCell` where different `timetable_id`, same `day_of_week` + `period_ord`, `is_active = true`, timetable is active AND belongs to a current academic term, and `has` teachers with matching IDs. For each match, push conflict with `type = 'TEACHER_CROSS_TT'` and the teacher's name + conflicting timetable name.
4. **ROOM_CONFLICT:** If `$activity->required_room_id` is set, query same timetable same slot with matching `room_id`. If found, push conflict with `type = 'ROOM_CONFLICT'` and the room name.
5. **ROOM_CROSS_TT:** Query different timetable, same slot, same `room_id`, timetable is active. If found, push conflict with `type = 'ROOM_CROSS_TT'` and the room name + occupying timetable name.
6. **CLASS_DOUBLE_BOOKING:** Query same timetable, same slot, same `class_group_id` but different `activity_id`. If found, push conflict with `type = 'CLASS_DOUBLE_BOOKING'` and the existing subject name.
7. Return the conflict array (may be empty, may contain multiple entries).

## Validate Before Save

**PlaceCellRequest**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `timetable_id` | `required`, `integer`, `exists:tt_timetables,id` | Default Laravel validation message |
| `activity_id` | `required`, `integer`, `exists:tt_activities,id` (scoped by `class_group_id`) | Default Laravel validation message |
| `day_of_week` | `required`, `integer`, `min:1`, `max:7` | Default Laravel validation message |
| `period_ord` | `required`, `integer`, `min:1` | Default Laravel validation message |
| `class_group_id` | `required`, `integer` | Default Laravel validation message |
| **Published timetable (controller check)** | `$timetable->status === 'PUBLISHED'` | "Published timetables are immutable." |
| **Break period (controller check)** | `$period->periodType->is_break === true` | "Cannot place an activity in a break period." |

**RemoveCellRequest**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `timetable_id` | `required`, `integer`, `exists:tt_timetables,id` | Default Laravel validation message |
| `day_of_week` | `required`, `integer`, `min:1`, `max:7` | Default Laravel validation message |
| `period_ord` | `required`, `integer`, `min:1` | Default Laravel validation message |
| `class_group_id` | `required`, `integer` | Default Laravel validation message |
| **Published timetable (controller check)** | `$timetable->status === 'PUBLISHED'` | "Published timetables are immutable." |
| **Locked cell (controller check)** | `$cell->is_locked === true` | "Cell is locked." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Published timetable: place attempt | "Published timetables are immutable." | Controller check (422 JSON) |
| Published timetable: remove attempt | "Published timetables are immutable." | Controller check (422 JSON) |
| Break period drop attempt | "Cannot place an activity in a break period." | Controller check (422 JSON) |
| Removal of locked cell | "Cell is locked." | Controller check (422 JSON) |
| DB exception during `placeCell` | "Failed to place cell: {exception message}" | Controller catch (500 JSON) |
| DB exception during `removeCell` | "Failed to remove cell." | Controller catch (500 JSON) |
| Activity placed with conflicts | "Placed with conflicts: {comma‑separated conflict messages}" | Success with warnings (200 JSON) |
| Activity placed without conflicts | "Activity placed successfully." | Success (200 JSON) |
| Cell cleared | "Cell cleared." | Success (200 JSON) |
| Validation failure in `PlaceCellRequest` | Default Laravel JSON validation error per field | Validation error (422 JSON) |
| Validation failure in `RemoveCellRequest` | Default Laravel JSON validation error per field | Validation error (422 JSON) |
| Gate authorization failure (missing permission) | 403 Forbidden (Laravel default) | Authorization (403) |

## Success Scenarios

**SC-001 — Successful Activity Placement Without Conflicts**

The user drags Mathematics (activity_id: 42) onto Monday (day_of_week: 1), Period 2 (period_ord: 2) for class_group_id: 5 in timetable_id: 10. The backend validates, runs all five conflict checks, finds none, and creates a cell with `has_conflict = false` and `conflict_details_json = null`. Teachers Mr. Kumar (teacher_id: 12) and Ms. Rao (teacher_id: 18) are inserted into `tt_timetable_cell_teachers` with `assignment_role_id: 1` and `is_substitute: false`. The activity log records "Activity 'Mathematics' placed at day 1, period 2." The JSON response is:

```json
{"success": true, "cell_id": 201, "has_conflict": false, "conflicts": [],
 "activity": {"id": 42, "subject": "Mathematics", "weekly_needed": 6,
              "placed_count": 3, "remaining": 3, "is_fully_placed": false},
 "message": "Activity placed successfully."}
```

**SC-002 — Successful Activity Removal**

The user removes the activity from Monday Period 2 (cell_id: 201). The backend validates the timetable is not published and the cell is not locked. The teacher pivot records are deleted, and the cell is soft‑deleted. The activity log records "Activity removed from cell." The JSON response is:

```json
{"success": true, "message": "Cell cleared.", "activity_id": 42,
 "placed_count": 2, "weekly_needed": 6, "remaining": 4}
```

The sidebar now shows Mathematics with `placed_count: 2, remaining: 4`.

**SC-003 — Placement With Cross‑Timetable Conflict Warning**

Ms. Singh (teacher_id: 15) is assigned to English (activity_id: 55) for Class 10‑A. She is already placed in the published Timetable ID 7 for Class 9‑A at Wednesday Period 3. The user drags English onto Wednesday Period 3 for Class 10‑A. The backend places the cell but sets `has_conflict = true` and stores a `TEACHER_CROSS_TT` entry in `conflict_details_json`. The JSON response includes:

```json
{"success": true, "cell_id": 205, "has_conflict": true,
 "conflicts": [{"type": "TEACHER_CROSS_TT",
   "message": "Ms. Singh is busy in '9‑A Term 1 Published' teaching Hindi",
   "teacher_id": 15, "conflicting_cell_id": 180}],
 "message": "Placed with conflicts: Ms. Singh is busy in '9‑A Term 1 Published' teaching Hindi."}
```

The cell shows a conflict warning badge in the UI.

**SC-004 — Activity Replaced via Class Double‑Booking**

A cell at Monday Period 1 for class_group_id: 5 currently holds English (activity_id: 44). The user drops Mathematics (activity_id: 42) onto the same cell. The backend identifies a `CLASS_DOUBLE_BOOKING` conflict but proceeds with `updateOrCreate`. The old English teacher pivot records (teacher_id: 15, Ms. Singh) are deleted and the new Mathematics teachers (teacher_id: 12 and 18) are inserted. The response includes the conflict warning and the activity object now shows Mathematics's counts.

## Failure Scenarios

**FC-001 — Placement on a Published Timetable**

The user attempts to drag an activity onto a cell in a timetable whose status is `PUBLISHED`. The backend returns HTTP 422: `{"success": false, "message": "Published timetables are immutable."}` The cell is not created, and no teachers are assigned.

**FC-002 — Placement on a Break Period**

Period 4 (period_ord: 4) in the selected period set has `periodType.is_break = true`. The user drops any activity onto Wednesday Period 4. The backend returns HTTP 422: `{"success": false, "message": "Cannot place an activity in a break period."}`

**FC-003 — Removal of a Locked Cell**

The cell at Monday Period 1 has `is_locked = true` (locked via the `lock-cell` endpoint by a coordinator). The user attempts to remove the activity from this cell. The backend returns HTTP 422: `{"success": false, "message": "Cell is locked."}` The soft delete is not performed.

**FC-004 — Removal From a Published Timetable**

The user attempts to remove a cell from a timetable with status `PUBLISHED`. The backend returns HTTP 422: `{"success": false, "message": "Published timetables are immutable."}`

**FC-005 — Missing Permission**

A user who does not hold the `standard-timetable.manualPlace` permission navigates to the manual‑placement page or sends an AJAX request to `place-cell` or `remove-cell`. The backend returns HTTP 403 Forbidden (from either `Gate::authorize()` in the controller or `authorize()` in the Form Request).

**FC-006 — Invalid Activity ID for the Class Group**

An activity_id of 999 is submitted, but this activity does not belong to the submitted `class_group_id` (or does not exist at all). The `PlaceCellRequest` validation rule `exists:tt_activities,id` scoped by `class_group_id` fails, and the response contains a validation error for the `activity_id` field (422 JSON).

**FC-007 — Database Failure During Placement**

A foreign key constraint violation or deadlock occurs inside the transaction (e.g., the timetable_id references a non‑existent parent). The `catch` block triggers `DB::rollBack()` and returns HTTP 500: `{"success": false, "message": "Failed to place cell: {exception detail}"}` The teacher pivot tables are not modified.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_timetables` | FK parent | `timetable_id` FK → `tt_timetables.id` ON DELETE CASCADE |
| `tt_generation_runs` | FK parent | `generation_run_id` FK → `tt_generation_runs.id` ON DELETE SET NULL |
| `sch_class_groups_jnt` | FK parent | `class_group_id` FK → `sch_class_groups_jnt.id` ON DELETE CASCADE |
| `tt_class_requirement_subgroups` | FK parent | `class_subgroup_id` FK → `tt_class_requirement_subgroups.id` ON DELETE CASCADE |
| `tt_activities` | FK parent | `activity_id` FK → `tt_activities.id` ON DELETE SET NULL |
| `tt_sub_activities` | FK parent | `sub_activity_id` FK → `tt_sub_activities.id` ON DELETE SET NULL |
| `sch_rooms` | FK parent | `room_id` FK → `sch_rooms.id` ON DELETE SET NULL |
| `sys_users` | FK parent | `locked_by` FK → `sys_users.id` ON DELETE SET NULL |
| `sch_teachers` | FK parent (via cell_teachers) | `teacher_id` FK → `sch_teachers.id` ON DELETE CASCADE |
| `tt_teacher_assignment_roles` | FK parent (via cell_teachers) | `assignment_role_id` FK → `tt_teacher_assignment_roles.id` ON DELETE RESTRICT |
| `tt_timetable_cell_teachers` | FK child | `cell_id` FK → `tt_timetable_cells.id` ON DELETE CASCADE |
| `tt_change_logs` | FK child | `cell_id` FK → `tt_timetable_cells.id` ON DELETE SET NULL |
| `tt_substitution_logs` | FK child | `cell_id` FK → `tt_timetable_cells.id` ON DELETE CASCADE |
| `tt_conflict_detections` | Child (service) | Created by `ManualTimetableService::persistConflicts()` with `detection_type = 'REAL_TIME'` |
| `Modules\StandardTimetable\Services\ManualTimetableService` | Service | Provides parallel `placeCell`/`removeCell`/`checkConflicts`/`persistConflicts` used by the SmartTimetable module |
| `activityLog()` helper | Helper | Logs all placement and removal actions with performed‑by attribution |

---

**Table: `tt_timetable_cells`**

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT |
| timetable_id | INT UNSIGNED | NOT NULL, FK → `tt_timetables.id` ON DELETE CASCADE |
| generation_run_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_generation_runs.id` ON DELETE SET NULL |
| day_of_week | TINYINT UNSIGNED | NOT NULL |
| period_ord | TINYINT UNSIGNED | NOT NULL |
| cell_date | DATE | DEFAULT NULL |
| class_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt.id` ON DELETE CASCADE |
| class_subgroup_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups.id` ON DELETE CASCADE |
| activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_activities.id` ON DELETE SET NULL |
| sub_activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_sub_activities.id` ON DELETE SET NULL |
| room_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms.id` ON DELETE SET NULL |
| source | ENUM('AUTO','MANUAL','SWAP','LOCK') | NOT NULL, DEFAULT 'AUTO' |
| is_locked | TINYINT(1) | NOT NULL, DEFAULT 0 |
| locked_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id` ON DELETE SET NULL |
| locked_at | TIMESTAMP | NULL |
| has_conflict | TINYINT(1) | DEFAULT 0 |
| conflict_details_json | JSON | DEFAULT NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| deleted_at | TIMESTAMP | NULL |
| **UNIQUE KEY** | `uq_cell_tt_day_period_group` | (`timetable_id`, `day_of_week`, `period_ord`, `class_group_id`, `class_subgroup_id`) |
| **CHECK** | `chk_cell_target` | (`class_group_id` IS NOT NULL AND `class_subgroup_id` IS NULL) OR (`class_group_id` IS NULL AND `class_subgroup_id` IS NOT NULL) |

---

**Table: `tt_timetable_cell_teachers`**

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT |
| cell_id | INT UNSIGNED | NOT NULL, FK → `tt_timetable_cells.id` ON DELETE CASCADE |
| teacher_id | INT UNSIGNED | NOT NULL, FK → `sch_teachers.id` ON DELETE CASCADE |
| assignment_role_id | TINYINT UNSIGNED | NOT NULL, FK → `tt_teacher_assignment_roles.id` ON DELETE RESTRICT |
| is_substitute | TINYINT(1) | DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| deleted_at | TIMESTAMP | NULL |
| **UNIQUE KEY** | `uq_cct_cell_teacher` | (`cell_id`, `teacher_id`) |
