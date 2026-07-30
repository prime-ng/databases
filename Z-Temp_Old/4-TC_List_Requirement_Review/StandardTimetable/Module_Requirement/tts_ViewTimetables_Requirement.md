# View Timetables — Business Requirements

## What This Screen Does

The View Timetables feature provides three read-only perspectives on a published or draft timetable: by class, by teacher, and by room. Each view renders a grid with days of the week as columns and time periods as rows, with the relevant cells populated in their respective slots.

These views are the primary consumption interface for the entire school — teachers check their personal schedule, students see their class timetable, and administrators verify room utilization. All three views are strictly read-only: no cell placement, removal, locking, or publishing actions are available on these screens.

---

## When This Screen Is Used

- **Daily Teacher Check** when a teacher wants to see which classes they are teaching on which day and period
- **Classroom Student Display** when the class teacher prints or projects the weekly schedule for students
- **Room Utilization Review** when the administrator checks which rooms are in use at each period to identify conflicts or free slots
- **Parent-Teacher Meeting Preparation** when the principal reviews the overall schedule to ensure no teacher is double-booked
- **Timetable Verification** when the timetable coordinator cross-checks the published schedule before distributing it

---

## Default Data Load

All three views are loaded via GET routes under the Manual Placement tab group. They are accessed through dedicated URL patterns that include the timetable ID and the respective entity ID.

| View | Route | Controller Method | Lines |
|------|-------|-------------------|-------|
| Class View | `GET class-view/{timetableId}/{classGroupId}` | `classView()` | 715-737 |
| Teacher View | `GET teacher-view/{timetableId}/{teacherId}` | `teacherView()` | 739-759 |
| Room View | `GET room-view/{timetableId}/{roomId}` | `roomView()` | 761-783 |

Class View loads: the timetable with its type and academic term; all cells for the timetable and class group, eager-loaded with `activity.subject`, `activity.studyFormat`, `teachers.user`, and `room`, grouped by `day_of_week-period_ord`; the ClassSection model (class + section names), school days (where `is_school_day = true`), and the periods from the timetable's period set.

Teacher View loads: the timetable; all cells where the `teachers` relationship matches the given teacher ID, eager-loaded with `activity.subject`, `activity.classGroup.class`, `activity.classGroup.section`, and `room`, grouped by day-period; the Teacher model with user details; school days and periods.

Room View loads: the timetable; all cells where `room_id` matches the given ID, eager-loaded with `activity.subject`, `activity.classGroup.class`, `activity.classGroup.section`, and `teachers.user`, grouped by day-period; the Room model with room type; school days and periods.

No pagination applies — all matching cells are loaded in a single query. All views use Blade `table-bordered` tables rendered in a card layout.

---

## Key Fields at a Glance

**Grid Structure**
All three views render a grid with a Period column on the left and one column per school day. Each cell in the grid shows the subject name (bold), the study format label (small text), and for class/room views, the teacher names. The teacher view shows the class-section tag instead of teacher names. If a cell is locked, a "Locked" badge appears. Empty slots show an em-dash (`—`).

**Header Information**
Each view displays a card header with the entity name (class-section for class view, teacher name for teacher view, room name with type for room view) and the timetable name with its type in parentheses.

---

## Business Rules and Conditions

**Read-Only Enforcement**
All three views are strictly read-only. There are no create, edit, delete, or action buttons on these screens. The controller methods load data and pass it to the view — no POST/update operations are gated.

**Cell Query Scoping**
Class View filters cells by `timetable_id` and `class_group_id` and by `is_active = true`. Teacher View filters by `timetable_id` and by the `teachers` relationship (teacher_id match), with `is_active = true`. Room View filters by `timetable_id` and `room_id`, with `is_active = true`. Each view renders only the cells that match its scope — a teacher will not see cells for classes they do not teach.

**Grouping Convention**
All three views group cells using `groupBy(fn($c) => $c->day_of_week . '-' . $c->period_ord)`. This creates a key like `3-5` (day 3, period 5) that is looked up during rendering via `$cells->get($day->ordinal . '-' . $period->period_ord)?->first()`.

**Null-Safe Rendering**
All view templates use `?->` null-safe operators and `?? '—'` fallbacks for relationship properties. If a cell has no activity, no subject, no teacher, or no room, the grid shows `—` instead of breaking.

**Not Implemented — No Print/Export CSS or Buttons**
The views have no print-specific stylesheets, no "Print" button, and no PDF export endpoint. Users cannot generate a printer-friendly or downloadable version of any timetable view.

**Not Implemented — No Timetable Selector on View Pages**
Each view loads a single timetable based on the URL parameter. There is no dropdown or selector on the view page to switch between timetables for the same class/teacher/room without navigating back to the manual placement page.

---

## Workflow Steps

**Viewing a Class Timetable**
1. The user navigates to the Manual Placement page and clicks the "Class View" action on a specific timetable row.
2. Alternatively, the user directly enters `/class-view/{timetableId}/{classGroupId}` in the browser.
3. The system loads the timetable, all cells for the given class group, the class-section details, school days, and periods.
4. The grid renders with the class-section name in the header, days as columns, periods as rows, and subject/format/teacher information in each cell.
5. Locked cells display a "Locked" badge. Empty cells show `—`.

**Viewing a Teacher Timetable**
1. The user navigates to the teacher view URL `/teacher-view/{timetableId}/{teacherId}`.
2. The system loads the timetable, all cells where the teacher_id matches through the pivot table, the teacher's name, school days, and periods.
3. The grid renders with the teacher's name in the header, and each cell shows the subject and the class-section (e.g., "10-A") instead of teacher names.

**Viewing a Room Timetable**
1. The user navigates to the room view URL `/room-view/{timetableId}/{roomId}`.
2. The system loads the timetable, all cells where `room_id` matches, the room details with room type, school days, and periods.
3. The grid renders with the room name and type in the header, each cell showing the subject, class-section, and assigned teacher names.

---

## Example Scenario

It is Monday morning at Cambridge International School. Mrs. Patel (Physics teacher) opens her timetable by visiting `/teacher-view/5/42`, where 5 is the published Term 1 Standard Timetable and 42 is her teacher ID. She sees her entire week: Period 1 on Monday with Class 11-A (Physics Lecture), Period 3 on Wednesday with Class 11-B (Physics Lab), and so on. Each cell shows the class section name. She notices that Wednesday Period 5 is empty — she has a free period. Meanwhile, the principal opens `/class-view/5/12` for Class 10-A and sees their full weekly schedule projected on the smart board during morning assembly.

---

## Related Screens

- **Manual Placement** — The source screen where the timetable is built; users navigate from here to the view pages
- **Copy Timetable** — Creates a working copy that can later be viewed through these same routes
- **Publishing & Approval Workflow** — Only published timetables are typically viewed school-wide; drafts may be viewed by coordinators for review
- **Timetable Dashboard** — The index page listing all timetables with links to their view pages

---

## Requirements

- Controller `StandardTimetableController`:
  - `classView(int $timetableId, int $classGroupId)` lines 715-737: loads timetable + cells for class_group_id, grouped by day-period; eager-loads `activity.subject`, `activity.studyFormat`, `teachers.user`, `room`; gated by `standard-timetable.viewClass`
  - `teacherView(int $timetableId, int $teacherId)` lines 739-759: loads timetable + cells where teachers relationship matches teacher_id, grouped by day-period; eager-loads `activity.subject`, `activity.classGroup.class`, `activity.classGroup.section`, `room`; gated by `standard-timetable.viewTeacher`
  - `roomView(int $timetableId, int $roomId)` lines 761-783: loads timetable + cells where room_id matches, grouped by day-period; eager-loads `activity.subject`, `activity.classGroup.class`, `activity.classGroup.section`, `teachers.user`; gated by `standard-timetable.viewRoom`
- Routes (web.php):
  - `GET class-view/{timetableId}/{classGroupId}` (name: `classView`)
  - `GET teacher-view/{timetableId}/{teacherId}` (name: `teacherView`)
  - `GET room-view/{timetableId}/{roomId}` (name: `roomView`)
- All three views are read-only — no write operations, no POST routes, no form submissions
- Cells filtered with `where('is_active', true)` in all three views
- School days loaded via `SchoolDay::where('is_school_day', true)->where('is_active', true)->orderBy('ordinal')`
- Periods loaded via `$timetable->periodSet?->periods()->orderBy('period_ord')->get() ?? collect()` — nullable period set handled
- Blade views: `class-view.blade.php`, `teacher-view.blade.php`, `room-view.blade.php` — all use `<x-backend.layouts.app>` layout and `<table class="table table-bordered">` rendering
- Null-safe operators (`?->`) used throughout views for relationship access
- FRD gaps: No print CSS/button, no timetable selector on view pages

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `standard-timetable.viewClass` | `classView()` | Grants access to class-wise timetable view |
| `standard-timetable.viewTeacher` | `teacherView()` | Grants access to teacher-wise timetable view |
| `standard-timetable.viewRoom` | `roomView()` | Grants access to room-wise timetable view |
| Policy | `StandardTimetablePolicy` | Separate policy methods: `viewClass()`, `viewTeacher()`, `viewRoom()` — each delegates to the corresponding `can()` check |

---

## Logic Flow

**1. classView**
- Gate: `Gate::authorize('standard-timetable.viewClass')`
- Load timetable: `Timetable::with(['timetableType', 'academicTerm'])->findOrFail($timetableId)`
- Load cells: `TimetableCell::with(['activity.subject', 'activity.studyFormat', 'teachers.user', 'room'])->where('timetable_id', $timetableId)->where('class_group_id', $classGroupId)->where('is_active', true)->get()->groupBy(fn($c) => $c->day_of_week . '-' . $c->period_ord)`
- Load ClassSection: `ClassSection::with(['class', 'section'])->findOrFail($classGroupId)`
- Load days: `SchoolDay::where('is_school_day', true)->where('is_active', true)->orderBy('ordinal')->get()`
- Load periods: `$timetable->periodSet?->periods()->orderBy('period_ord')->get() ?? collect()`
- Return view: `standardtimetable::views.class-view` with compact variables

**2. teacherView**
- Gate: `Gate::authorize('standard-timetable.viewTeacher')`
- Load timetable: `Timetable::with(['timetableType', 'academicTerm'])->findOrFail($timetableId)`
- Load cells: `TimetableCell::where('timetable_id', $timetableId)->where('is_active', true)->whereHas('teachers', fn($q) => $q->where('teacher_id', $teacherId))->with(['activity.subject', 'activity.classGroup.class', 'activity.classGroup.section', 'room'])->get()->groupBy(...)`
- Load teacher: `Teacher::with('user')->findOrFail($teacherId)`
- Load days: same as classView
- Load periods: same as classView
- Return view: `standardtimetable::views.teacher-view`

**3. roomView**
- Gate: `Gate::authorize('standard-timetable.viewRoom')`
- Load timetable: `Timetable::with(['timetableType', 'academicTerm'])->findOrFail($timetableId)`
- Load cells: `TimetableCell::where('timetable_id', $timetableId)->where('room_id', $roomId)->where('is_active', true)->with(['activity.subject', 'activity.classGroup.class', 'activity.classGroup.section', 'teachers.user'])->get()->groupBy(...)`
- Load room: `Room::with('roomType')->findOrFail($roomId)`
- Load days: same as classView
- Load periods: same as classView
- Return view: `standardtimetable::views.room-view`

---

## Validate Before Save

No validation applies — these are read-only GET views. The only implicit validation is model binding via `findOrFail()` which returns 404 if the timetable, class section, teacher, or room does not exist.

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Timetable not found | ModelNotFoundException via `findOrFail()` | 404 |
| ClassGroup not found | ModelNotFoundException via `findOrFail()` | 404 |
| Teacher not found | ModelNotFoundException via `findOrFail()` | 404 |
| Room not found | ModelNotFoundException via `findOrFail()` | 404 |
| Unauthorized: missing viewClass permission | AuthorizationException | 403 |
| Unauthorized: missing viewTeacher permission | AuthorizationException | 403 |
| Unauthorized: missing viewRoom permission | AuthorizationException | 403 |
| Timetable has no period set | `$timetable->periodSet?->periods()` returns null → empty periods collection | Graceful degradation (empty grid) |

---

## Success Scenarios

**SC-001 — Class View Loads Correctly**
A user with `standard-timetable.viewClass` accesses `/class-view/5/12` for timetable "Class 10 Standard" and class group "10-A". The page renders a grid with 6 day columns, 8 period rows, subject/format/teacher data in filled cells, and `—` in empty slots. The header shows "10-A" and the timetable name.

**SC-002 — Teacher View Loads Correctly**
A user with `standard-timetable.viewTeacher` accesses `/teacher-view/5/42` for teacher "Mrs. Patel". The grid shows only cells where Mrs. Patel is assigned through the teachers pivot. Each filled cell displays the subject and class-section (e.g., "11-A Physics Lab"). Empty periods show `—`.

**SC-003 — Room View Loads Correctly**
A user with `standard-timetable.viewRoom` accesses `/room-view/5/8` for "Physics Lab (Room 201)". The grid shows all cells using that room, with subject, class-section, and teacher name in each filled cell.

**SC-004 — Locked Cell Badge Display**
A cell with `is_locked = true` appears in any of the three views. The cell content includes a `Locked` badge (`<span class="badge badge-warning">Locked</span>`).

---

## Failure Scenarios

**FC-001 — Non-Existent Timetable ID**
Access `/class-view/999/12` where timetable ID 999 does not exist. `findOrFail()` returns 404.

**FC-002 — Non-Existent Class Group**
Access `/class-view/5/999` where class group 999 does not exist. `ClassSection::findOrFail()` returns 404.

**FC-003 — Non-Existent Teacher**
Access `/teacher-view/5/999` where teacher 999 does not exist. `Teacher::findOrFail()` returns 404.

**FC-004 — Non-Existent Room**
Access `/room-view/5/999` where room 999 does not exist. `Room::findOrFail()` returns 404.

**FC-005 — Unauthorized Class View**
User without `standard-timetable.viewClass` accesses `/class-view/5/12`. `Gate::authorize()` throws 403.

**FC-006 — Unauthorized Teacher View**
User without `standard-timetable.viewTeacher` accesses `/teacher-view/5/42`. Returns 403.

**FC-007 — Unauthorized Room View**
User without `standard-timetable.viewRoom` accesses `/room-view/5/8`. Returns 403.

**FC-008 — Timetable with No Period Set**
The timetable exists but has no `period_set_id`. The periods collection is empty and the grid renders with no rows — just the day column headers and empty cells.

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_timetables` | Primary table | Timetable record loaded by ID |
| `tt_timetable_cells` | Primary table | Cells filtered by timetable_id + entity scope |
| `tt_timetable_cell_teachers` | Pivot table | Used in teacher view to scope cells by teacher_id |
| `tt_school_days` | Reference | Days loaded (is_school_day = true) |
| `tt_period_set_period_jnt` | Reference | Periods loaded via timetable's period set |
| `sch_class_section` (ClassSection) | Cross-module | Class group details for class view |
| `sch_teachers` (Teacher) | Cross-module | Teacher details for teacher view |
| `sch_rooms` (Room) | Cross-module | Room details for room view |
| `Modules\TimetableFoundation\Models\Timetable` | Model | FQN, table `tt_timetables` |
| `Modules\TimetableFoundation\Models\TimetableCell` | Model | FQN, table `tt_timetable_cells` |
| `Modules\TimetableFoundation\Models\SchoolDay` | Model | FQN, table `tt_school_days` |
| `Modules\SchoolSetup\Models\ClassSection` | Model | FQN, table `sch_class_section` |
| `Modules\SchoolSetup\Models\Teacher` | Model | FQN, table `sch_teachers` |
| `Modules\SchoolSetup\Models\Room` | Model | FQN, table `sch_rooms` |
| `Modules\StandardTimetable\Policies\StandardTimetablePolicy` | Policy | `viewClass()`, `viewTeacher()`, `viewRoom()` |

**Table:** `tt_timetables`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto-increment |
| `code` | VARCHAR(30) | Unique timetable code |
| `name` | VARCHAR(150) | Timetable display name |
| `description` | TEXT | Nullable |
| `academic_session_id` | INT UNSIGNED | Nullable |
| `academic_term_id` | INT UNSIGNED | FK to `sch_academic_term` |
| `timetable_type_id` | INT UNSIGNED | FK to `tt_timetable_type` |
| `period_set_id` | INT UNSIGNED | FK to `tt_period_set`; nullable → empty grid fallback |
| `effective_from` | DATE | Not null |
| `effective_to` | DATE | Nullable |
| `generation_method` | VARCHAR(20) | Default `MANUAL` |
| `version` | INT | Default 1 |
| `parent_timetable_id` | INT UNSIGNED | Nullable, self-referencing FK |
| `status` | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | All statuses are viewable — not restricted to PUBLISHED |
| `published_at` | DATETIME | Nullable |
| `published_by` | INT UNSIGNED | Nullable |
| `is_active` | BOOLEAN | Default TRUE |
| `created_by` | INT UNSIGNED | Nullable |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |
| `deleted_at` | TIMESTAMP | Nullable (SoftDeletes) |

**Table:** `tt_timetable_cells`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto-increment |
| `timetable_id` | INT UNSIGNED | FK to `tt_timetables.id` |
| `day_of_week` | INT UNSIGNED | Not null; used in groupBy key |
| `period_ord` | INT UNSIGNED | Not null; used in groupBy key |
| `class_group_id` | INT UNSIGNED | Filter for class view |
| `activity_id` | INT UNSIGNED | FK to activity; subject name displayed |
| `room_id` | INT UNSIGNED | Nullable; filter for room view |
| `is_locked` | BOOLEAN | Displayed as badge in all views |
| `is_active` | BOOLEAN | Filtered to `true` in all three views |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |
| `deleted_at` | TIMESTAMP | Nullable (SoftDeletes) |

**Table:** `tt_school_days`

| Column | Type | Details |
|--------|------|---------|
| `id` | TINYINT UNSIGNED | PK |
| `name` | VARCHAR(20) | Day name (e.g., Monday) — used as column header |
| `ordinal` | TINYINT UNSIGNED | Ordering; matched to cell's `day_of_week` via `ordinal` |
| `is_school_day` | BOOLEAN | Filtered to `true` |
| `is_active` | BOOLEAN | Filtered to `true` |
