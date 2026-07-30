# tts_view_timetables_TcList

## Module: StandardTimetable → Views → View Timetables

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StandardTimetable |
| Tab Group | Views |
| Feature | View Timetables (Class View / Teacher View / Room View) |
| URL(s) | `GET /standard-timetable/class-view/{timetableId}/{classGroupId}`, `GET /standard-timetable/teacher-view/{timetableId}/{teacherId}`, `GET /standard-timetable/room-view/{timetableId}/{roomId}` |
| Controller | `Modules\StandardTimetable\Http\Controllers\StandardTimetableController` — `classView()` lines 715-737, `teacherView()` lines 739-759, `roomView()` lines 761-783 |
| Model(s) | `Modules\TimetableFoundation\Models\Timetable` (table: `tt_timetables`), `Modules\TimetableFoundation\Models\TimetableCell` (table: `tt_timetable_cells`) |
| Validation | None (read-only views — ID route parameters only) |
| Policy | `Modules\StandardTimetable\Policies\StandardTimetablePolicy` — `viewClass()`, `viewTeacher()`, `viewRoom()` methods |
| Permissions | `standard-timetable.viewClass`, `standard-timetable.viewTeacher`, `standard-timetable.viewRoom` |
| Pagination | None (all cells loaded and rendered in grid) |
| Soft Deletes | Yes (`Timetable` and `TimetableCell` use `SoftDeletes` trait; DDL shows `deleted_at` column) |
| Read-Only | Yes — no create/update/delete UI elements |

---

## 2. Pre-conditions

- Required permissions: `standard-timetable.viewClass` (class view), `standard-timetable.viewTeacher` (teacher view), `standard-timetable.viewRoom` (room view)
- Required seed data: At least one MANUAL `Timetable` with `TimetableCell` records; at least one `ClassSection`, `Teacher`, `Room`; active `SchoolDay` and `Period` records
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

Each view loads the timetable info and cells filtered by the respective entity (class group, teacher, room). School days and periods are loaded from the timetable's period set.

| View | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Class View | classView() | `TimetableCell::with(activity.subject, activity.studyFormat, teachers.user, room)->where('timetable_id',$id)->where('class_group_id',$classGroupId)->where('is_active',true)` | timetable_id, class_group_id, is_active | None (all rows) |
| Teacher View | teacherView() | `TimetableCell::where('timetable_id',$id)->where('is_active',true)->whereHas('teachers', fn=>where('teacher_id',$teacherId))->with(activity.subject, activity.classGroup.class, activity.classGroup.section, room)` | timetable_id, teacher_id, is_active | None |
| Room View | roomView() | `TimetableCell::where('timetable_id',$id)->where('room_id',$roomId)->where('is_active',true)->with(activity.subject, activity.classGroup.class, activity.classGroup.section, teachers.user)` | timetable_id, room_id, is_active | None |
| Shared (all views) | classView/teacherView/roomView | `SchoolDay::where('is_school_day',true)->where('is_active',true)->orderBy('ordinal')`, `periodSet->periods()->orderBy('period_ord')` | is_school_day, is_active | None |

---

## 4. Test Data Strategy

- Create a MANUAL `Timetable` with multiple cells across different days, periods, class groups, teachers, and rooms
- Assign each cell to a specific `class_group_id`, `teacher_id` (via `tt_timetable_cell_teachers`), and `room_id`
- Use consistent test entity IDs (e.g., class_group_id=1, teacher_id=1, room_id=1)
- Pre-test cleanup: Delete created cells and timetables by ID after tests
- Verify the grid renders correct number of rows (days) × columns (periods) for each view
- Verify cells appear only in the correct view (teacher view shows only their cells, etc.)

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_timetables` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(200) | NOT NULL |
| BC-DB-04 | generation_method | ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') | NOT NULL DEFAULT 'MANUAL' |
| BC-DB-05 | status | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | NOT NULL DEFAULT 'DRAFT' |
| BC-DB-06 | period_set_id | INT UNSIGNED | NOT NULL, FK → `tt_period_sets.id`, ON DELETE RESTRICT |

### 5.2 Database Schema — `tt_timetable_cells` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-07 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-08 | timetable_id | INT UNSIGNED | NOT NULL, FK → `tt_timetables.id`, ON DELETE CASCADE |
| BC-DB-09 | day_of_week | TINYINT UNSIGNED | NOT NULL |
| BC-DB-10 | period_ord | TINYINT UNSIGNED | NOT NULL |
| BC-DB-11 | class_group_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt.id`, ON DELETE CASCADE |
| BC-DB-12 | activity_id | INT UNSIGNED | DEFAULT NULL, FK → `tt_activities.id`, ON DELETE SET NULL |
| BC-DB-13 | room_id | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms.id`, ON DELETE SET NULL |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |

### 5.3 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | standard-timetable.viewClass | classView() | Without → 403 |
| BC-AUTH-02 | standard-timetable.viewTeacher | teacherView() | Without → 403 |
| BC-AUTH-03 | standard-timetable.viewRoom | roomView() | Without → 403 |
| BC-AUTH-04 | Guest access | All three views | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Class view loads with timetable info | Timetable name, type, term displayed; cells grouped by `day_of_week-period_ord` composite key |
| BC-BIZ-02 | Class view shows only cells for that class_group_id | Only cells with matching `class_group_id` appear in grid |
| BC-BIZ-03 | Teacher view shows only cells where teacher is assigned | Only cells with matching teacher_id in `tt_timetable_cell_teachers` appear; filtered via `whereHas('teachers')` |
| BC-BIZ-04 | Room view shows only cells assigned to that room | Only cells with matching `room_id` appear in grid |
| BC-BIZ-05 | Empty timetable (no cells) — empty grid | All day×period slots show as empty; no data rows |
| BC-BIZ-06 | Cell data rendered correctly | Each cell shows subject name, study format, teacher names, room name |
| BC-BIZ-07 | School days displayed correctly | Days ordered by `ordinal` where `is_school_day=true` and `is_active=true` |
| BC-BIZ-08 | Periods displayed correctly | Periods ordered by `period_ord` from the timetable's period set |
| BC-BIZ-09 | Non-existent timetable → 404 | `findOrFail` on Timetable returns 404 |
| BC-BIZ-10 | Non-existent classGroup/teacher/room → 404 | `findOrFail` on respective model returns 404 |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | timetable_id (tt_timetable_cells) | tt_timetables (id) | CASCADE |
| BC-REF-02 | class_group_id (tt_timetable_cells) | sch_class_groups_jnt (id) | CASCADE |
| BC-REF-03 | activity_id (tt_timetable_cells) | tt_activities (id) | SET NULL |
| BC-REF-04 | room_id (tt_timetable_cells) | sch_rooms (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Display & Filter Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Class view loads with timetable info header | Timetable name, type, term displayed at top of page | — | — | ⬜ |
| TC-P02 | Class view shows cells grouped by day-period | Cells correctly positioned in grid by day_of_week × period_ord | — | — | ⬜ |
| TC-P03 | Class view shows only cells for the selected class group | Cells with other class_group_id not visible in this view | — | — | ⬜ |
| TC-P04 | Teacher view loads with timetable info header | Timetable name, type, term and teacher name displayed | — | — | ⬜ |
| TC-P05 | Teacher view shows only cells where teacher is assigned | Only cells with this teacher in cell_teachers appear | — | — | ⬜ |
| TC-P06 | Room view loads with timetable info header | Timetable name, type, term and room name displayed | — | — | ⬜ |
| TC-P07 | Room view shows only cells assigned to that room | Only cells with matching room_id appear | — | — | ⬜ |
| TC-P08 | Cell displays subject name | Cell shows the activity's subject name | — | — | ⬜ |
| TC-P09 | Cell displays study format | Cell shows the activity's study format (e.g., "Lecture", "Lab") | — | — | ⬜ |
| TC-P10 | Cell displays assigned teacher(s) | Teacher names from cell_teachers displayed in cell | — | — | ⬜ |
| TC-P11 | Cell displays room name | Room name from cell's room_id displayed in cell | — | — | ⬜ |
| TC-P12 | Teacher view shows class/section for each cell | Cell shows which class and section it belongs to | — | — | ⬜ |
| TC-P13 | Room view shows class/section for each cell | Cell shows which class and section it belongs to | — | — | ⬜ |
| TC-P14 | School days displayed correctly in grid header | Days ordered by ordinal; only school days shown | — | — | ⬜ |
| TC-P15 | Periods displayed correctly in grid sidebar | Periods ordered by period_ord; all periods from period set shown | — | — | ⬜ |
| TC-P16 | Empty timetable — all slots empty | Grid cells are empty; no activity data displayed | — | — | ⬜ |
| TC-P17 | Multiple cells on same day but different periods | All cells displayed in correct period columns | — | — | ⬜ |
| TC-P18 | Multiple teachers assigned to same cell | Both teacher names shown in the cell | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Non-existent timetable ID in class view | 404 | — | — | ⬜ |
| TC-N02 | Non-existent timetable ID in teacher view | 404 | — | — | ⬜ |
| TC-N03 | Non-existent timetable ID in room view | 404 | — | — | ⬜ |
| TC-N04 | Non-existent classGroup ID in class view | 404 | — | — | ⬜ |
| TC-N05 | Non-existent teacher ID in teacher view | 404 | — | — | ⬜ |
| TC-N06 | Non-existent room ID in room view | 404 | — | — | ⬜ |
| TC-N07 | No permission (standard-timetable.viewClass) | 403 on GET class-view | — | — | ⬜ |
| TC-N08 | No permission (standard-timetable.viewTeacher) | 403 on GET teacher-view | — | — | ⬜ |
| TC-N09 | No permission (standard-timetable.viewRoom) | 403 on GET room-view | — | — | ⬜ |
| TC-N10 | Guest access to class view | Redirect to /login | — | — | ⬜ |
| TC-N11 | Guest access to teacher view | Redirect to /login | — | — | ⬜ |
| TC-N12 | Guest access to room view | Redirect to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | FK CASCADE — delete timetable cascades to cells | Timetable deleted → all cells deleted → all views return 404 for that timetable | — | — | ⬜ |
| TC-D02 | B | FK SET NULL — delete activity referenced by cell | Activity deleted → cell's activity_id = NULL → cell shows empty in view | — | — | ⬜ |
| TC-D03 | C | FK SET NULL — delete room referenced by cell | Room deleted → cell's room_id = NULL → cell shows no room in view | — | — | ⬜ |
| TC-D04 | D | FK CASCADE — delete class_group cascades cell | Class group deleted → cell's class_group_id cascade → cell removed → class view no longer shows it | — | — | ⬜ |
| TC-D05 | E | Timetable findOrFail — soft-deleted timetable | Soft-deleted timetable returns 404 on all three views | — | — | ⬜ |
| TC-D06 | F | Gate coverage — viewClass on classView | `Gate::authorize('standard-timetable.viewClass')` called in classView() | — | — | ⬜ |
| TC-D07 | G | Gate coverage — viewTeacher on teacherView | `Gate::authorize('standard-timetable.viewTeacher')` called in teacherView() | — | — | ⬜ |
| TC-D08 | H | Gate coverage — viewRoom on roomView | `Gate::authorize('standard-timetable.viewRoom')` called in roomView() | — | — | ⬜ |
| TC-D09 | I | Only active cells shown (is_active=true) | Cells with is_active=0 are excluded from all three views | — | — | ⬜ |
| TC-D10 | J | Teacher view — teacher assigned via cell_teachers junction | Teacher view uses `whereHas('teachers', fn=>where('teacher_id',$id))` to find cells | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — Gate::authorize() on All Three View Methods | `classView()`, `teacherView()`, `roomView()` each call their respective gate (`viewClass`, `viewTeacher`, `viewRoom`) at the top | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — Timetable findOrFail With Eager Loading | Each method calls `Timetable::with(['timetableType','academicTerm'])->findOrFail($id)` to load timetable info | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — Eager Loading of Cell Relationships | Cells loaded with relationships (activity.subject, activity.studyFormat, teachers.user, room, etc.) to avoid N+1 queries | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Data Grouped by day_of_week-period_ord | Cells grouped via `->groupBy(fn($c) => $c->day_of_week . '-' . $c->period_ord)` for grid rendering | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Active School Days and Periods Loaded | `SchoolDay::where('is_school_day',true)->where('is_active',true)->orderBy('ordinal')` and `$timetable->periodSet?->periods()->orderBy('period_ord')` | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Policy — viewClass, viewTeacher, viewRoom Methods Defined | StandardTimetablePolicy has three methods each returning the corresponding permission string | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Routes — All Three GET Routes Registered | `web.php` defines `GET class-view/{timetableId}/{classGroupId}`, `GET teacher-view/{timetableId}/{teacherId}`, `GET room-view/{timetableId}/{roomId}` | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | View — Blade @can Directives on Tab Buttons | View pages wrapped in `@can('standard-timetable.viewClass')` etc.; tabs hidden without permission | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship access uses `isset()` or `?->` null-safe operator; no errors when relations are null | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | View — Breadcrumb Config for View Routes | Routes registered in `config/breadcrumb.php` showing correct hierarchy | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — Gate::authorize() on All Three View Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetableController.php` | File found |
| 2 | Inspect `classView()` line 715 | First logic line: `Gate::authorize('standard-timetable.viewClass')` |
| 3 | Inspect `teacherView()` line 739 | First logic line: `Gate::authorize('standard-timetable.viewTeacher')` |
| 4 | Inspect `roomView()` line 761 | First logic line: `Gate::authorize('standard-timetable.viewRoom')` |

#### TC-CR02: Controller — Timetable findOrFail With Eager Loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `classView()` | `Timetable::with(['timetableType','academicTerm'])->findOrFail($timetableId)` |
| 2 | Inspect `teacherView()` | Same eager loading pattern |
| 3 | Inspect `roomView()` | Same eager loading pattern |

#### TC-CR03: Controller — Eager Loading of Cell Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `classView()` | Cells loaded with: `activity.subject`, `activity.studyFormat`, `teachers.user`, `room` |
| 2 | Inspect `teacherView()` | Cells loaded with: `activity.subject`, `activity.classGroup.class`, `activity.classGroup.section`, `room` |
| 3 | Inspect `roomView()` | Cells loaded with: `activity.subject`, `activity.classGroup.class`, `activity.classGroup.section`, `teachers.user` |

#### TC-CR04: Controller — Data Grouped by day_of_week-period_ord

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `classView()` | `->groupBy(fn($c) => $c->day_of_week . '-' . $c->period_ord)` |
| 2 | Inspect `teacherView()` | Same grouping pattern |
| 3 | Inspect `roomView()` | Same grouping pattern |

#### TC-CR05: Controller — Active School Days and Periods Loaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `classView()` days query | `SchoolDay::where('is_school_day',true)->where('is_active',true)->orderBy('ordinal')` |
| 2 | Inspect `classView()` periods query | `$timetable->periodSet?->periods()->orderBy('period_ord')` (null-safe for missing period set) |
| 3 | Verify same pattern in teacherView and roomView | All three views load days and periods identically |

#### TC-CR06: Policy — viewClass, viewTeacher, viewRoom Methods Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetablePolicy.php` | File found |
| 2 | Verify `viewClass()` | Method returns `$user->can('standard-timetable.viewClass')` |
| 3 | Verify `viewTeacher()` | Method returns `$user->can('standard-timetable.viewTeacher')` |
| 4 | Verify `viewRoom()` | Method returns `$user->can('standard-timetable.viewRoom')` |

#### TC-CR07: Routes — All Three GET Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php` in routes | Routes file found |
| 2 | Verify class-view | `Route::get('class-view/{timetableId}/{classGroupId}', ...)` registered |
| 3 | Verify teacher-view | `Route::get('teacher-view/{timetableId}/{teacherId}', ...)` registered |
| 4 | Verify room-view | `Route::get('room-view/{timetableId}/{roomId}', ...)` registered |

#### TC-CR08: View — Blade @can Directives on Tab Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index.blade.php` | View file found in `resources/views/` |
| 2 | Scan for tab/link to class-view | Wrapped in `@can('standard-timetable.viewClass')` |
| 3 | Scan for tab/link to teacher-view | Wrapped in `@can('standard-timetable.viewTeacher')` |
| 4 | Scan for tab/link to room-view | Wrapped in `@can('standard-timetable.viewRoom')` |

#### TC-CR09: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open each view file (`class-view.blade.php`, `teacher-view.blade.php`, `room-view.blade.php`) | Files found in `resources/views/views/` |
| 2 | Scan for relationship access patterns | All use `isset()` or `?->` null-safe operator |
| 3 | Create record with null relationship | View renders without undefined index/property error |

#### TC-CR10: View — Breadcrumb Config for View Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration |
| 2 | Verify keys for view routes | Keys for classView, teacherView, roomView exist with correct URL mappings |
| 3 | Load each view | Breadcrumb trail shows correct hierarchy |

### 7.1 Positive TC Steps

#### TC-P01: Class View Loads With Timetable Info Header

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with name="Class TT A", type="Regular", term="Term 1" | Timetable exists with ID=X |
| 2 | Create classSection with class="Class 10", section="A" | ClassSection exists with ID=Y |
| 3 | Navigate to `GET /standard-timetable/class-view/{X}/{Y}` | Page loads |
| 4 | Check page header | Timetable name "Class TT A" visible |
| 5 | Check timetable type and term | "Regular" and "Term 1" displayed |

---

#### TC-P02: Class View Shows Cells Grouped by Day-Period

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 3 school days (ordinals 1-3) and 4 periods (period_ord 1-4) | Grid is 3×4 |
| 2 | Create cells: day=1/period=1, day=1/period=3, day=2/period=2 for class group Y | 3 cells exist |
| 3 | Load class-view | Cells appear at correct grid positions: (1,1), (1,3), (2,2); other slots empty |

---

#### TC-P03: Class View Shows Only Cells for the Selected Class Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 2 class groups: CG-A and CG-B | Both exist |
| 2 | Create cell for CG-A at (day=1, period=1) and cell for CG-B at (day=1, period=2) | Both cells exist |
| 3 | Load class-view/{timetableId}/{CG-A.id} | Only CG-A cell visible at (1,1); CG-B cell at (1,2) not shown |
| 4 | Load class-view/{timetableId}/{CG-B.id} | Only CG-B cell visible at (1,2) |

---

#### TC-P04: Teacher View Loads With Timetable Info Header

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable and teacher "Mr. Sharma" | Both exist |
| 2 | Navigate to teacher-view/{timetableId}/{teacherId} | Page loads with timetable info and teacher name "Mr. Sharma" |

---

#### TC-P05: Teacher View Shows Only Cells Where Teacher Is Assigned

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 2 teachers: T-A and T-B, each assigned to different cells | Cells exist |
| 2 | Load teacher-view/{timetableId}/{T-A.id} | Only T-A's cells shown |
| 3 | Load teacher-view/{timetableId}/{T-B.id} | Only T-B's cells shown |
| 4 | Verify T-A cell not in T-B view and vice versa | Correct filtering |

---

#### TC-P06: Room View Loads With Timetable Info Header

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable and room "Lab 101" | Both exist |
| 2 | Navigate to room-view/{timetableId}/{roomId} | Page loads with timetable info and room name "Lab 101" |

---

#### TC-P07: Room View Shows Only Cells Assigned to That Room

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 2 rooms: R-A and R-B, each assigned to different cells | Cells exist |
| 2 | Load room-view/{timetableId}/{R-A.id} | Only R-A's cells shown |
| 3 | Load room-view/{timetableId}/{R-B.id} | Only R-B's cells shown |

---

#### TC-P08 to TC-P11: Cell Data Rendering

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P08 | Create cell with activity having subject="Mathematics" | Load class-view | Cell shows "Mathematics" |
| TC-P09 | Create cell with activity having studyFormat="Lecture" | Load class-view | Cell shows "Lecture" |
| TC-P10 | Create cell with teacher assigned name="Ms. Gupta" | Load class-view | Cell shows "Ms. Gupta" |
| TC-P11 | Create cell with room name="Physics Lab" | Load class-view | Cell shows "Physics Lab" |

---

#### TC-P12: Teacher View Shows Class/Section for Each Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell for teacher T-A with classGroup having class="Class 10", section="B" | Cell exists |
| 2 | Load teacher-view/{timetableId}/{T-A.id} | Cell shows "Class 10 - B" |

---

#### TC-P13: Room View Shows Class/Section for Each Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell for room R-A with classGroup having class="Class 9", section="C" | Cell exists |
| 2 | Load room-view/{timetableId}/{R-A.id} | Cell shows "Class 9 - C" |

---

#### TC-P14: School Days Displayed Correctly in Grid Header

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 school days with ordinals 1-5, is_school_day=true, names Mon-Fri | Days exist |
| 2 | Load any view | Grid headers show Mon, Tue, Wed, Thu, Fri in ordinal order |

---

#### TC-P15: Periods Displayed Correctly in Grid Sidebar

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create period set with 6 periods, period_ord 1-6, with names/start times | Periods exist |
| 2 | Load any view | Grid sidebar shows periods 1-6 in order |

---

#### TC-P16: Empty Timetable — All Slots Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with no cells | 0 cells exist |
| 2 | Load class-view, teacher-view, room-view | Grid renders with correct dimensions but all cells show as empty/slot available |

---

#### TC-P17: Multiple Cells on Same Day but Different Periods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 2 cells for same class group, same day (day=1), different periods (period=2, period=4) | Both cells exist |
| 2 | Load class-view | Cell at (1,2) and cell at (1,4) both visible; (1,1), (1,3), (1,5+ ) empty |

---

#### TC-P18: Multiple Teachers Assigned to Same Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell with 2 teachers assigned: "Mr. Verma" and "Ms. Kapoor" | Cell exists |
| 2 | Load class-view | Cell shows both "Mr. Verma" and "Ms. Kapoor" |

### 7.2 Negative TC Steps

#### TC-N01 to TC-N06: Non-Existent IDs

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N01 | GET /standard-timetable/class-view/99999/1 | 404 | Timetable not found |
| TC-N02 | GET /standard-timetable/teacher-view/99999/1 | 404 | Timetable not found |
| TC-N03 | GET /standard-timetable/room-view/99999/1 | 404 | Timetable not found |
| TC-N04 | GET /standard-timetable/class-view/1/99999 (class group) | 404 | ClassSection not found |
| TC-N05 | GET /standard-timetable/teacher-view/1/99999 (teacher) | 404 | Teacher not found |
| TC-N06 | GET /standard-timetable/room-view/1/99999 (room) | 404 | Room not found |

---

#### TC-N07 to TC-N09: No Permission

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N07 | Login as user without standard-timetable.viewClass → GET class-view | 403 | Forbidden |
| TC-N08 | Login as user without standard-timetable.viewTeacher → GET teacher-view | 403 | Forbidden |
| TC-N09 | Login as user without standard-timetable.viewRoom → GET room-view | 403 | Forbidden |

---

#### TC-N10 to TC-N12: Guest Access

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-N10 | Logout → GET /standard-timetable/class-view/{id}/{cgId} | Redirect to /login |
| TC-N11 | Logout → GET /standard-timetable/teacher-view/{id}/{teacherId} | Redirect to /login |
| TC-N12 | Logout → GET /standard-timetable/room-view/{id}/{roomId} | Redirect to /login |

### 7.3 Dependency TC Steps

#### TC-D01: FK CASCADE — Delete Timetable Cascades to Cells

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with 2 cells | Timetable and cells exist |
| 2 | Delete the timetable (forceDelete) | Timetable removed via delete |
| 3 | Check cells for that timetable_id | Cells also cascade-deleted (fk_cell_timetable CASCADE) |

#### TC-D02: FK SET NULL — Delete Activity Referenced by Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create activity and cell referencing it | activity_id is set |
| 2 | Delete the activity | Activity deleted |
| 3 | Check cell's activity_id | NULL (SET NULL on fk_cell_activity) |

#### TC-D03: FK SET NULL — Delete Room Referenced by Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create room and cell referencing it | room_id is set |
| 2 | Delete the room | Room deleted |
| 3 | Check cell's room_id | NULL (SET NULL on fk_cell_room) |

#### TC-D04: FK CASCADE — Delete Class Group Cascades Cell

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create class group and cell referencing it | class_group_id is set |
| 2 | Delete the class group | Class group deleted |
| 3 | Check cells | Cells with that class_group_id also cascade-deleted (fk_cell_class_group CASCADE) |

#### TC-D05: Timetable findOrFail — Soft-Deleted Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and soft-delete a timetable | deleted_at is set |
| 2 | GET class-view/{timetableId}/{classGroupId} | 404 |
| 3 | GET teacher-view/{timetableId}/{teacherId} | 404 |
| 4 | GET room-view/{timetableId}/{roomId} | 404 |

#### TC-D06 to TC-D08: Gate Coverage on All Three View Methods

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-D06 | Inspect `classView()` | Gate check present | `Gate::authorize('standard-timetable.viewClass')` |
| TC-D07 | Inspect `teacherView()` | Gate check present | `Gate::authorize('standard-timetable.viewTeacher')` |
| TC-D08 | Inspect `roomView()` | Gate check present | `Gate::authorize('standard-timetable.viewRoom')` |

#### TC-D09: Only Active Cells Shown (is_active=true)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 cells for same class group: one is_active=1, one is_active=0 | Both exist |
| 2 | Load class-view | Only is_active=1 cell visible; is_active=0 cell excluded |

#### TC-D10: Teacher View — Teacher Assigned via Cell_Teachers Junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cell with teacher T-A via tt_timetable_cell_teachers | Junction record exists |
| 2 | Load teacher-view/{timetableId}/{T-A.id} | Cell visible |
| 3 | Remove teacher assignment from cell | Junction record deleted |
| 4 | Reload teacher-view | Cell no longer visible |
