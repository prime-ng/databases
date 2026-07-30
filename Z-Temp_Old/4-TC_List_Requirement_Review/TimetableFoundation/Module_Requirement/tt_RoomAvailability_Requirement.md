# Room Availability — Business Requirements

## What This Screen Does

Room Availability is the central registry that governs **which rooms are available for timetable scheduling, under what conditions, and for which activity types**. It sits under the Resource Availability tab (Page 3 of the Timetable Foundation workflow) alongside Teacher Availability and Slot Requirements, providing full CRUD — Create, Read, Update, soft Delete, Restore, and Force Delete — plus status toggling, automated generation from room master data, and a ratio computation engine that assesses supply–demand balance per room type.

The feature comprises two database tables:

- **`tt_room_availabilities`** — The header record per room, defining the room's category count, assignment capability, overall availability status (Available / Unavailable / Partially Available / Assigned), per-activity-type assignment flags (lecture, practical, exam, activity, sports), timetable time window, capacity and max limit, and the optional class-house-room designation.
- **`tt_room_availability_details`** — Per-period granularity records that track the availability of each room on each day and period, with assigned class/section/subject context when a room is occupied during a specific slot.

The system uses these records during timetable generation to prevent double-booking, match rooms to activities based on required room types and assignment flags, and compute scoring metrics (eligible room count, room availability score) that influence the solver's placement decisions.

---

## When This Screen Is Used

- **Initial timetable setup** — At the start of a new academic term, the administrator runs the "Generate" action to create RoomAvailability records for all active rooms, seeded from the `sch_rooms` master data. This populates availability defaults, assignment flags, and class-house-room designations derived from `sch_class_section_jnt`.

- **Adjusting per-room availability** — When a room becomes temporarily or permanently unavailable (e.g., a lab is closed for renovation, a classroom is converted to a staff room), the administrator edits the room's availability record to set `can_be_assigned = false` or change `overall_availability_status`.

- **Configuring activity-type permissions** — A multi-purpose hall may be flagged as available for activities and exams but not for lectures or practicals. The administrator toggles the five boolean assignment flags (`can_be_assigned_for_lecture`, `can_be_assigned_for_practical`, `can_be_assigned_for_exam`, `can_be_assigned_for_activity`, `can_be_assigned_for_sports`) per room.

- **Defining per-period slot assignments** — For rooms that follow a fixed schedule (e.g., Computer Lab reserved for Class 10A on Monday Periods 3–4), the administrator creates availability detail records that mark specific periods as "Assigned" with the target class, section, and subject study format.

- **Assessing room supply–demand balance** — The administrator runs the "Generate Room Availability Ratio" action to compute a per-room-type ratio of supply (active rooms × total periods per week) against demand (sum of required weekly periods per room type), producing a status of Balanced, Tight, or Overloaded for each room.

- **Auditing and recovery** — When room schedules need to be reviewed or corrected, the administrator views trashed records and can restore or permanently delete them.

---

## Default Data Load

The `RoomAvailabilityController@index` method is called when the user navigates to the Room Availability list. Because `index()` contains only a `Gate::authorize` call followed by a redirect, the actual data load happens inside `TimetableFoundationController@resourceAvailability` (route `timetable-foundation.menu.resourceAvailability`), which renders the full multi-tab Resource Availability page with `tab=room-availability` as the active tab.

RoomAvailability records are loaded via the controller's `show()` or the list view embedded in the resource-availability page, with eager-loaded relationships:

| Relationship | Model | Foreign Key |
|-------------|-------|-------------|
| `room` | `Modules\SchoolSetup\Models\Room` | `room_id` |
| `room.building` | Nested via Room | `sch_rooms.building_id` |
| `details` | `RoomAvailabilityDetail` | `room_availability_id` |
| `activity` | `Modules\TimetableFoundation\Models\Activity` | `activity_id` |

The standalone index/trash views paginate at 10 records per page using `latest('deleted_at')` ordering.

---

## Key Fields at a Glance

### Room Identity and Type Classification

These fields define which physical room the availability record belongs to and how it is categorised.

- **Room** — FK to `sch_rooms(id)`. The physical room (e.g., "Science Lab A", "Classroom 101", "Sports Hall"). A single room may have multiple availability records if it is used for different subject study formats or class–section combinations.
- **Rooms Type** — FK to `sch_rooms_type(id)`. The type classification (e.g., Regular Classroom, Science Lab, Computer Lab, Music Room, Sports Hall). Used for matching activities that require a specific room type.
- **Total Rooms in Category** — A computed count of how many rooms share the same `rooms_type_id`. Used by the ratio computation engine to calculate supply.

### Assignment and Status Flags

- **Can Be Assigned** — Boolean. Master switch that determines whether the room is available for any timetable assignment. Default `true`. When `false`, the room is effectively blocked from all scheduling.
- **Overall Availability Status** — ENUM: `Available`, `Unavailable`, `Partially Available`, `Assigned`. Reflects the high-level state of the room. The `generateRoomAvailabilityRatio` method updates this to `Balanced`, `Tight`, or `Overloaded` based on supply–demand computation.
- **Available for Full Timetable Duration** — Boolean. Indicates whether the room is available for the entire timetable cycle (all days, all periods). Default `true`. When `false`, per-period detail records govern actual availability.

### Class-House Room Designation

- **Is Class House Room** — Boolean. Indicates whether the room has been designated as a class-specific house room (i.e., a room permanently assigned to a specific class-section via `sch_class_section_jnt.class_house_room_id`). Populated automatically during generation.
- **House Room Class ID** — FK to `sch_classes(id)`. The class for which this room serves as the house room. Only set when `is_class_house_room = true`.
- **House Room Section ID** — FK to `sch_sections(id)`. The section for which this room serves as the house room. Only set when `is_class_house_room = true`.
- **Class ID / Section ID** — Additional nullable FKs to `sch_classes` and `sch_sections`. These capture the broader class–section association of the availability record, distinct from the house-room designation.

### Subject & Activity Context

- **Subject Study Format ID** — FK to `sch_subject_study_format_jnt(id)`. Links the availability record to a specific subject study format (e.g., theory, practical, tutorial). Part of the unique key `uq_ra_class_wise`.
- **Activity ID** — Nullable FK to `tt_activities(id)`. Associates the room availability with a specific activity when relevant.

### Capacity and Limits

- **Capacity** — Unsigned integer. The maximum number of students or occupants the room can accommodate for a single session. Used by the solver to match room capacity against class size.
- **Max Limit** — Unsigned integer. The absolute ceiling on occupancy, which may exceed functional capacity for exceptional circumstances (e.g., exam seating).

### Per-Activity-Type Assignment Flags

Five boolean flags that independently control which activity types the room can host:

| Flag | Default | Purpose |
|------|---------|---------|
| `can_be_assigned_for_lecture` | `true` | Regular lectures and theory classes |
| `can_be_assigned_for_practical` | `true` | Lab sessions, hands-on practicals |
| `can_be_assigned_for_exam` | `true` | Examination duty |
| `can_be_assigned_for_activity` | `true` | Co-curricular activities |
| `can_be_assigned_for_sports` | `true` | Sports and physical education |

### Timetable Time Window

- **Timetable Start Time** — TIME. The earliest time at which the room can be scheduled (e.g., `08:00`).
- **Timetable End Time** — TIME. The latest time at which the room can be scheduled (e.g., `16:00`). Must be after `timetable_start_time`.

### Per-Period Detail Fields (`tt_room_availability_details`)

- **Day Number / Day Name** — The day of the week (1–7 numeric, and human-readable name like "Monday").
- **Period Number** — The specific period slot within that day.
- **Availability for Period** — ENUM: `Available`, `Unavailable`, `Assigned`. Defines the state of the room for this specific day+period combination.
- **Assigned Class / Section / Subject Study Format** — When `availability_for_period = 'Assigned'`, these fields capture which class, section, and study format has been assigned to this slot.
- **Room Available From Date** — Nullable date. If set, the room becomes available from this date onwards (for phased availability scenarios).
- **Activity ID** — Nullable FK to `tt_activities(id)`. Links the detail record to a specific activity when relevant.

---

## Business Rules and Conditions

**Unique Composite Key per Class-Section-Format** — The `uq_ra_class_wise` unique index on `(room_id, rooms_type_id, class_id, section_id, subject_study_format_id)` ensures that a room cannot have duplicate availability entries for the same combination of class, section, and subject study format. This prevents conflicting availability definitions for the same usage context.

**Class-House-Room Logic (CHECK Constraint)** — The `chk_class_house_logic` constraint enforces that when `is_class_house_room = true`, both `house_room_class_id` and `house_room_section_id` must be non-null. When `is_class_house_room = false`, both must be null. This is enforced at the database level via `DB::statement("ALTER TABLE ... ADD CONSTRAINT chk_class_house_logic ...")`.

**Unique Detail Record per Assignment** — The `uq_ra_class_wise` unique index on `tt_room_availability_details` on `(room_availability_id, assigned_class_id, assigned_section_id, assigned_subject_study_format_id)` ensures that within a given room availability header, the same class–section–study-format combination cannot be assigned more than once.

**Generation Is Idempotent** — The `generate()` method in `RoomAvailabilityService` uses `updateOrCreate` keyed on `room_id`, making it safe to run multiple times. It does not delete existing records; it updates them if the room already has an availability record, or creates one if not. Existing per-period detail records are not affected by generation.

**Assignment Flag Inheritance from Room Master** — During generation, the five `can_be_assigned_for_*` flags are seeded from the corresponding `can_host_*` columns on `sch_rooms`. For example, if a room has `can_host_practical = false` in the rooms table, the generated availability record will also have `can_be_assigned_for_practical = false`.

**Class-House-Room Auto-Detection** — The generation service queries `sch_class_section_jnt` for rows where `class_house_room_id` is not null, groups by `(class_house_room_id, class_id)`, and sets `is_class_house_room = true` along with `house_room_class_id` and `house_room_section_id`. If a room has no such junction record, it is not treated as a class house room.

**Soft Delete with Deactivation** — The `destroy()` method sets `is_active = false` on the model, calls `save()`, and then calls `delete()` (SoftDeletes). This ensures the record is immediately excluded from active use before being soft-deleted. The `restore()` method also restores `is_active = true`.

**Ratio Computation Supply–Demand Model** — The `generateRoomAvailabilityRatio` method computes:
- **Supply** = `activeRoomsOfType × totalPeriodsPerWeek` (where `totalPeriodsPerWeek` is derived from `SlotRequirement` count or falls back to `workingDays × 8`)
- **Demand** = Sum of `required_weekly_periods` from activities that specify a `required_room_type_id`
- **Ratio** = `supply / demand` (clamped to 1.00 if demand is 0)
- **Status assignment**: `Ratio ≥ 1.2` → `Balanced`, `Ratio ≥ 1.0` → `Tight`, otherwise → `Overloaded`

**Activity Eligibility Scoring** — The `RoomAvailabilityService@updateEligibleRoomCount` method filters active, full-timetable-available rooms by required room type, specific room ID, and study format flags (practical subjects need practical-capable rooms). It then assigns an availability score of 0, 20, 50, 75, or 100 based on the eligible count (0, 1, 2–3, 4–7, 8+).

---

## Workflow Steps

### Creating a Room Availability Record (Manual)

1. The administrator navigates to Timetable Foundation → Resource Availability → Room Availability tab and clicks the Create button.
2. The `create()` method loads all active rooms (`Room::where('is_active', true)->orderBy('name')`) for the room dropdown.
3. The user selects a room and fills in capacity, max limit, overall status, timetable time window, and assignment flags.
4. The user clicks "Create". POST goes to `timetable-foundation.room-availability.store`.
5. The controller validates input (room_id required, capacity/max_limit optional integers ≥ 1, start/end time format `H:i` with end after start, boolean flags).
6. The record is created via `RoomAvailability::create(...)` with boolean flags converted via `$request->boolean()`.
7. An activity log entry is recorded with action "Created".
8. The user is redirected to the Resource Availability page with a success flash message.

### Editing a Room Availability Record

1. The user clicks Edit on any row. The `edit()` method loads the record with all active rooms.
2. The user modifies any field and clicks "Update". PUT goes to `timetable-foundation.room-availability.update`.
3. The same validation rules apply as for create.
4. The model is updated, activity is logged as "Updated", and the user is redirected with a success flash.

### Viewing a Room Availability Record

1. The user clicks View (eye icon) on any row.
2. The `show()` method loads the record with eager-loaded `room.building` and `details` relationships.
3. A read-only detail page is rendered showing all fields including per-period details.

### Soft Deleting a Room Availability Record

1. The user clicks Delete on a row. The `destroy()` method is called.
2. The controller sets `is_active = false`, saves, then calls `$roomAvailability->delete()`.
3. An activity log entry is recorded with action "Trashed".
4. The user is redirected with a success flash message.

### Restoring a Trashed Record

1. The user navigates to the Trash view (route `timetable-foundation.room-availability.trashed`).
2. The `trashedRoomAvailability()` method loads paginated soft-deleted records with `room.building` relationship.
3. The user clicks Restore on a trashed record. The `restore($id)` method restores it and sets `is_active = true`.
4. Activity is logged as "Restored". The user is redirected back to the trash list.

### Force Deleting a Record

1. From the Trash view, the user triggers force delete on a record.
2. The `forceDelete($id)` method uses `withTrashed()->findOrFail($id)` and calls `forceDelete()`.
3. The record is permanently removed. Activity is logged as "Deleted".

### Generating Room Availability from Room Master

1. The user clicks "Generate" on the Room Availability page.
2. POST goes to `timetable-foundation.room-availability.generate`.
3. The `RoomAvailabilityService@generate()` method iterates all active rooms, queries room-type counts and class-house-room data from `sch_class_section_jnt`, and calls `updateOrCreate` for each room.
4. A success message is displayed indicating how many rooms were processed. On error, an exception is logged and the error message is shown.

### Computing Room Availability Ratio

1. The user clicks "Generate Ratio" on the Room Availability page.
2. POST goes to `timetable-foundation.room-availability.generateRatio`.
3. The controller computes total periods per week (from SlotRequirement count or working days × 8), groups activity demand by required room type, groups active rooms by room type, and iterates each active RoomAvailability to update its `overall_availability_status` (Balanced / Tight / Overloaded).
4. A success message shows how many rooms were updated.

### Toggling Status via AJAX

1. The user clicks the status toggle switch on a list row.
2. POST goes to `timetable-foundation.room-availability.toggleStatus`.
3. The `toggleStatus()` method validates `is_active` as required boolean, saves, and returns JSON `{ success, is_active, message }`.

---

## Example Scenario

Sunrise International School has the following room inventory for the 2025–26 academic year:

**Room Inventory (from `sch_rooms`):**

| Room | Type | Capacity | Can Host Practical? | Can Host Sports? |
|------|------|----------|---------------------|------------------|
| Classroom 101 | Regular Classroom | 40 | No | No |
| Classroom 102 | Regular Classroom | 40 | No | No |
| Science Lab A | Science Lab | 30 | Yes | No |
| Computer Lab | Computer Lab | 25 | Yes | No |
| Music Room | Music Room | 20 | No | No |
| Sports Hall | Sports Hall | 100 | No | Yes |
| AV Hall | Auditorium | 200 | No | No |

**Step 1: Generate Room Availability**

The administrator runs the Generate action. The system creates seven `tt_room_availabilities` records (one per room) with:
- `total_rooms_in_category`: Regular Classroom = 2, Science Lab = 1, Computer Lab = 1, Music Room = 1, Sports Hall = 1, Auditorium = 1
- `can_be_assigned_for_lecture`: true for all except Sports Hall
- `can_be_assigned_for_practical`: true only for Science Lab A and Computer Lab
- `can_be_assigned_for_sports`: true only for Sports Hall
- `can_be_assigned`: true for all
- `is_class_house_room`: true for Classroom 101 (designated as Class 10A's house room via `sch_class_section_jnt`)
- `house_room_class_id`: 10, `house_room_section_id`: 1

**Step 2: Block Unavailable Slots**

The administrator edits Science Lab A's availability to mark it as unavailable on Thursday Periods 5–6 (exam duty). This creates a `tt_room_availability_detail` record for day=4, period=5 with `availability_for_period = 'Unavailable'`, and another for period=6.

**Step 3: Assign Fixed Slots**

The Computer Lab is assigned to Class 9B for practicals on Monday Periods 3–4. The administrator creates detail records with `availability_for_period = 'Assigned'`, `assigned_class_id = 9`, `assigned_section_id = 2`, `assigned_subject_study_format_id = <practical_format_id>`.

**Step 4: Compute Ratio**

The administrator runs Generate Ratio. The system finds:
- Regular Classroom demand = 20 periods/week (from activities), supply = 2 × 40 = 80, ratio = 4.0 → Balanced
- Science Lab demand = 25 periods/week, supply = 1 × 40 = 40, ratio = 1.6 → Balanced
- Computer Lab demand = 30 periods/week, supply = 1 × 40 = 40, ratio = 1.33 → Balanced
- Sports Hall demand = 5 periods/week (PE activities), supply = 1 × 40 = 40, ratio = 8.0 → Balanced
- AV Hall demand = 0, supply = 1 × 40 = 40, ratio = 1.00 → Tight

All rooms show as Balanced or Tight. The administrator is satisfied and proceeds to timetable generation.

---

## Related Screens

- **Teacher Availability** — Sibling tab on the Resource Availability page that manages per-teacher availability records and slot generation.
- **Slot Requirements** — The third tab on the Resource Availability page, where per-activity slot requirements (room type, preferred room, periods required) are defined.
- **Activity Management** — Activities reference `required_room_type_id` and `required_room_id` which are consumed by the room availability system to compute eligibility and scoring.
- **Working Day Calendar** — The period grid and day definitions from the working day calendar determine the day/period structure against which room availability details are defined.
- **Room Master (School Setup)** — The `sch_rooms` table provides the canonical list of rooms, their types, capacities, and capability flags that seed the availability records.
- **Smart Timetable Solver** — The solver's `RoomAllocationPass` consumes availability data to prevent double-booking and match rooms to activities.

---

## Requirements

- The `RoomAvailabilityController` (293 lines, `Modules/TimetableFoundation/Http/Controllers/RoomAvailabilityController.php`) implements the following public methods: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashedRoomAvailability()`, `restore()`, `forceDelete()`, `toggleStatus()`, `generate()`, and `generateRoomAvailabilityRatio()`. Each write method logs an activity record via the `activityLog()` helper.
- The `index()` method authorises via `Gate::authorize('timetable-foundation.room-availability.viewAny')` and immediately redirects to `timetable-foundation.menu.resourceAvailability`. The Room Availability list is actually rendered by `TimetableFoundationController@resourceAvailability` when the `tab=room-availability` parameter is present.
- The `create()` method authorises via `Gate::authorize('timetable-foundation.room-availability.create')` and loads `Room::where('is_active', true)->orderBy('name')->get()` for the room selector.
- The `store()` and `update()` methods authorise via `create`/`update` gates respectively, perform inline validation (no separate Form Request class), convert boolean flags via `$request->boolean()`, set default values for optional fields (`overall_status` defaults to `'available'`, `timetable_start_time` and `timetable_end_time` default to `null`), and redirect to `timetable-foundation.menu.resourceAvailability` on success.
- The `show()` method authorises via `timetable-foundation.room-availability.view` and loads the record with `room.building` and `details` relationships eager-loaded.
- The `destroy()` method performs a soft delete: it sets `is_active = false`, calls `save()`, then calls `$roomAvailability->delete()` (SoftDeletes). An activity log entry records the trashing.
- The `trashedRoomAvailability()` method loads `RoomAvailability::onlyTrashed()->with(['room.building'])->latest('deleted_at')->paginate(10)` and renders the trash view.
- The `restore($id)` method uses `RoomAvailability::onlyTrashed()->findOrFail($id)`, calls `restore()`, sets `is_active = true`, calls `save()`, and redirects to the trash list.
- The `forceDelete($id)` method uses `RoomAvailability::withTrashed()->findOrFail($id)`, calls `forceDelete()`, and redirects to the trash list.
- The `toggleStatus()` method validates a single `is_active` boolean via `$request->validate(['is_active' => 'required|boolean'])`, saves the new status, and returns a JSON response with `success`, `is_active`, and `message` fields. It enforces the `timetable-foundation.room-availability.update` gate.
- The `generate()` method authorises via `timetable-foundation.room-availability.generate`, delegates to `$this->roomAvailabilityService->generate()`, logs success/error messages, and redirects back.
- The `generateRoomAvailabilityRatio()` method authorises via `timetable-foundation.room-availability.generate`, computes total periods per week, aggregates demand by room type from `Activity` and supply by room type from `RoomAvailability`, iterates all active `RoomAvailability` records to update their `overall_availability_status` (Balanced / Tight / Overloaded), and redirects back with a count of rooms updated.
- The `RoomAvailabilityService` (143 lines, `Modules/TimetableFoundation/Services/RoomAvailabilityService.php`) provides three methods:
  - `generate(): int` — Idempotent generation for all active rooms using `updateOrCreate`, seeding assignment flags from `sch_rooms` capability flags, detecting class-house-room designations from `sch_class_section_jnt`.
  - `updateEligibleRoomCount(Activity $activity): void` — Counts eligible rooms for a given activity based on room type, specific room ID, and study-format capability flags; computes and stores an availability score (0/20/50/75/100).
  - `updateEligibleRoomCountForTerm(int $academicTermId): int` — Batch-updates eligibility for all active activities in a term.
- The `RoomAvailability` model (`Modules/TimetableFoundation/Models/RoomAvailability.php`, 135 lines) uses `SoftDeletes`, maps to `tt_room_availabilities`, declares 21 fillable fields, casts booleans and integers, and defines relationships: `room()`, `roomType()`, `houseRoomClass()`, `houseRoomSection()`, `activity()`, and `details()`. It provides `scopeActive()` and `scopeAssignable()` scopes.
- The `RoomAvailabilityDetail` model (`Modules/TimetableFoundation/Models/RoomAvailabilityDetail.php`, 129 lines) has `$timestamps = false`, maps to `tt_room_availability_details`, declares 12 fillable fields, and defines relationships: `roomAvailability()`, `room()`, `roomType()`, `assignedClass()`, `assignedSection()`, `assignedSubjectStudyFormat()`, and `activity()`. It provides `scopeActive()`, `scopeForDay()`, `scopeForPeriod()`, and `scopeAvailable()` scopes.
- Routes are registered in `routes/web.php` (lines 232–240): a `Route::resource('room-availability', RoomAvailabilityController::class)` plus six custom routes: `room-availability/generate-ratio` (POST), `room-availability/trash/view` (GET), `room-availability/{id}/restore` (GET), `room-availability/{id}/force-delete` (DELETE), `room-availability/{room_availability}/toggle-status` (POST), and `room-availability/generate` (POST). The route prefix and name prefix `timetable-foundation.` are applied by the RouteServiceProvider.
- The controller injects `RoomAvailabilityService` via constructor injection: `public function __construct(private readonly RoomAvailabilityService $roomAvailabilityService) {}`.
- The `store()` and `update()` methods use inline `$request->validate()` rather than a dedicated Form Request class — this is an architectural deviation from the project convention of using Form Requests for validation.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.room-availability.viewAny` | `index()` | Required to view the Room Availability tab |
| `timetable-foundation.room-availability.view` | `show()` | Required to view a single record's details |
| `timetable-foundation.room-availability.create` | `create()`, `store()` | Required to show the create form and persist a new record |
| `timetable-foundation.room-availability.update` | `edit()`, `update()`, `toggleStatus()` | Required to edit a record or toggle active status |
| `timetable-foundation.room-availability.delete` | `destroy()` | Required to soft-delete a record |
| `timetable-foundation.room-availability.restore` | `trashedRoomAvailability()`, `restore()` | Required to view trashed records and restore them |
| `timetable-foundation.room-availability.forceDelete` | `forceDelete()` | Required to permanently delete a record |
| `timetable-foundation.room-availability.generate` | `generate()`, `generateRoomAvailabilityRatio()` | Required to run generation and ratio computation |

**Note:** No dedicated Policy class exists; gates are enforced via `Gate::authorize()` calls directly in the controller with permission strings matching the `timetable-foundation.room-availability.*` pattern.

---

## Logic Flow

### 1. Page Load (Resource Availability Tab)

1. The user navigates to Timetable Foundation → Resource Availability.
2. `TimetableFoundationController@resourceAvailability()` runs (gated by `timetable-foundation.viewAny`).
3. The view renders with three tabs: Room Availability, Teacher Availability, Slot Requirements.
4. When `tab=room-availability`, the Room Availability pane loads with the list of records (fetched via the embedded controller logic or AJAX).
5. Each row displays room name, type, status, capacity, assignment flags, and action buttons (View, Edit, Delete).

### 2. Create (Manual)

1. User clicks Create → `create()` gates, loads active rooms, renders form.
2. User fills in room, capacity, limits, status, time window, assignment flags.
3. POST to `store()` → validates, creates via `RoomAvailability::create(...)`, logs activity, redirects back.

### 3. Edit/Update

1. User clicks Edit → `edit()` gates, loads record and room list, renders form.
2. User modifies fields → PUT to `update()` → validates, updates via model `update()`, logs changes, redirects.

### 4. Display/Show

1. User clicks View → `show()` gates, loads record with eager-loaded relationships, renders read-only detail page.

### 5. Generate from Room Master

1. User clicks Generate → POST to `generate()` → gates, calls service.
2. Service queries `Room::where('is_active', true)`, groups by room type, fetches class-house-room data from `sch_class_section_jnt`.
3. For each room: `updateOrCreate(['room_id' => $room->id], [...])` with assignment flags derived from room's capability columns.
4. Success/error flash returned.

### 6. Generate Ratio

1. User clicks Generate Ratio → POST to `generateRoomAvailabilityRatio()` → gates.
2. Total periods per week computed: `SlotRequirement::where('is_active', true)->count()` or fallback `workingDays × 8`.
3. Demand by type: `Activity::where('is_active', true)->whereNotNull('required_room_type_id')` → grouped SUM of `required_weekly_periods`.
4. Supply by type: `RoomAvailability::where('is_active', true)->where('can_be_assigned', true)` → grouped COUNT.
5. Per-room update: ratio = supply / demand, status = Balanced|Tight|Overloaded.
6. Success flash with count of updated rooms.

### 7. Status Toggle (AJAX)

1. User clicks status switch → POST to `toggleStatus()` → gates, validates `is_active`, saves, returns JSON.

### 8. Soft Delete

1. User triggers delete → `destroy()` gates → sets `is_active = false`, `save()`, `delete()` (SoftDeletes), logs, redirects.

### 9. Restore

1. User navigates to Trash → `trashedRoomAvailability()` gates, loads paginated trashed records.
2. User clicks Restore → `restore($id)` → `onlyTrashed()->findOrFail($id)`, `restore()`, sets `is_active = true`, logs, redirects.

### 10. Force Delete

1. From Trash view → user triggers force delete → `forceDelete($id)` → `withTrashed()->findOrFail($id)`, `forceDelete()`, logs, redirects.

---

## Validate Before Save

Validation is performed inline in the `store()` and `update()` methods of `RoomAvailabilityController` (no dedicated Form Request class).

| Field | Rule(s) | Notes |
|-------|---------|-------|
| `room_id` | `required`, `integer`, `exists:sch_rooms,id` | Must reference an existing room |
| `capacity` | `nullable`, `integer`, `min:1` | Optional, must be ≥ 1 if provided |
| `max_limit` | `nullable`, `integer`, `min:1` | Optional, must be ≥ 1 if provided |
| `overall_status` | `nullable`, `string`, `max:50` | Optional, defaults to `'available'` in controller |
| `available_for_full_timetable` | `nullable`, `boolean` | Converted via `$request->boolean()` |
| `can_be_assigned_for_lecture` | `nullable`, `boolean` | Converted via `$request->boolean()` |
| `can_be_assigned_for_practical` | `nullable`, `boolean` | Converted via `$request->boolean()` |
| `can_be_assigned_for_exam` | `nullable`, `boolean` | Converted via `$request->boolean()` |
| `can_be_assigned_for_activity` | `nullable`, `boolean` | Converted via `$request->boolean()` |
| `can_be_assigned_for_sports` | `nullable`, `boolean` | Converted via `$request->boolean()` |
| `timetable_start_time` | `nullable`, `date_format:H:i` | Must be in 24-hour format (e.g., `08:00`) |
| `timetable_end_time` | `nullable`, `date_format:H:i`, `after:timetable_start_time` | Must be after start time |
| `is_active` | `nullable` | Converted via `$request->boolean()` |

**Database-level constraints (not validated in controller):**

| Constraint | Type | Enforcement |
|------------|------|-------------|
| `uq_ra_class_wise` | UNIQUE KEY | `(room_id, rooms_type_id, class_id, section_id, subject_study_format_id)` — duplicate combination rejected |
| `chk_class_house_logic` | CHECK | `(is_class_house_room=1 AND house_room_class_id IS NOT NULL AND house_room_section_id IS NOT NULL) OR (is_class_house_room=0)` |
| `uq_ra_class_wise` (details) | UNIQUE KEY | `(room_availability_id, assigned_class_id, assigned_section_id, assigned_subject_study_format_id)` |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing required field `room_id` | "The room id field is required." | Validation rule |
| Invalid `room_id` (non-existent) | "The selected room id is invalid." | Validation rule (exists) |
| `capacity` less than 1 | "The capacity must be at least 1." | Validation rule (min) |
| `timetable_end_time` before `timetable_start_time` | "The timetable end time must be a date after timetable start time." | Validation rule (after) |
| `timetable_start_time` invalid format | "The timetable start time does not match the format H:i." | Validation rule (date_format) |
| Database exception during create | Generic redirect back with error from exception message | Controller catch block |
| Database exception during update | Generic redirect back with error from exception message | Controller catch block |
| Duplicate unique key violation | SQL integrity constraint violation — propagates as exception message | Database level (no explicit catch in controller) |
| Generation failure | "Generation failed: <exception message>" | Controller catch block |
| `toggleStatus` validation failure | Standard JSON validation error for `is_active` | Validation rule (AJAX 422) |
| `toggleStatus` save failure | JSON `{ success: false, is_active: ..., message: flash('status_switch_failed.room-availability') }` | Controller check (AJAX 422) |
| Unauthorised access (any gate) | `AuthorizationException` → 403 HTTP response | Laravel gate |
| Success — created | Flash message from `flash('created.room_availability')` | Success flash |
| Success — updated | Flash message from `flash('updated.room_availability')` | Success flash |
| Success — trashed | Flash message from `flash('trashed.room_availability')` | Success flash |
| Success — restored | Flash message from `flash('restored.room_availability')` | Success flash |
| Success — force deleted | Flash message from `flash('force_deleted.room_availability')` | Success flash |
| Success — generation | "Room availability generated successfully. N room(s) processed." | Success flash |
| Success — ratio computed | "Room availability ratio computed. N room(s) updated." | Success flash |
| Success — status toggled | JSON `{ success: true, is_active: ..., message: flash('status_updated.room_availability') }` | AJAX success response |

---

## Success Scenarios

**SC-001 — Generate Room Availability for a New Academic Year**

Sunrise School has 25 active rooms in `sch_rooms`. The administrator runs Generate. The `RoomAvailabilityService` creates 25 `tt_room_availabilities` records with default flags inherited from each room's capability columns. Two rooms are identified as class-house rooms (Classroom 101 for Class 10A, Classroom 102 for Class 9B) based on `sch_class_section_jnt` data. The system logs "Room availability generated" with `rooms_processed = 25` and `class_house_rooms = 2`. The administrator sees: "Room availability generated successfully. 25 room(s) processed."

**SC-002 — Create a Manual Room Availability Record**

The administrator creates a record for the new AV Hall (room_id = 26). Sets capacity to 200, max_limit to 250, status to "Available", all assignment flags to true, timetable window 08:00–17:00. The system validates, creates the record, logs activity "Room availability was created successfully.", and redirects with success flash.

**SC-003 — Toggle a Room's Active Status via AJAX**

The administrator clicks the status switch to deactivate the Music Room (temporarily closed). The `toggleStatus()` method receives `is_active=0`, validates, sets `is_active=false`, logs "Toggled" with status, and returns `{ success: true, is_active: false, message: "Status updated." }`. The UI updates without page reload.

**SC-004 — Compute Room Availability Ratio**

The administrator runs Generate Ratio. The system computes 8 regular classrooms with a supply of 320 periods/week and demand of 300 → ratio 1.07 → `Tight`. The Science Lab has supply of 40 and demand of 45 → ratio 0.89 → `Overloaded`. A message shows "Room availability ratio computed. 25 room(s) updated." The administrator reviews the `overall_availability_status` column to identify constrained rooms.

**SC-005 — Soft Delete and Restore**

The administrator deletes the Music Room record (temporarily removed from the schedule). `destroy()` sets `is_active=false`, soft-deletes. The record appears in the Trash view. Later, the administrator restores it. `restore()` reinstates the record with `is_active=true`. The Music Room reappears in the main list with its previous configuration intact.

---

## Failure Scenarios

**FC-001 — Missing Required Room ID**

The administrator attempts to create an availability record without selecting a room. The `room_id` field fails the `required` rule: "The room id field is required." The form is re-displayed with the error.

**FC-002 — Timetable End Time Before Start Time**

The administrator enters `timetable_start_time = 14:00` and `timetable_end_time = 08:00`. The `after:timetable_start_time` rule rejects the submission: "The timetable end time must be a date after timetable start time."

**FC-003 — Capacity Set to Zero**

The administrator enters `capacity = 0`. The `min:1` rule rejects: "The capacity must be at least 1."

**FC-004 — Duplicate Unique Key Violation**

The administrator creates two availability records for the same room, same room type, same class, same section, and same subject study format. The second submission violates the `uq_ra_class_wise` unique index. MySQL throws an integrity constraint violation, which propagates as a SQL exception (not explicitly caught in the controller).

**FC-005 — Generation Fails Due to Database Error**

During generation, a database connection failure occurs. The exception is caught by the try-catch in `generate()`, logged with `\Log::error('Room availability generation failed: ' . $e->getMessage())`, and the user sees: "Generation failed: <error message>."

**FC-006 — Unauthorised Access to Create**

A user without `timetable-foundation.room-availability.create` permission attempts to access the create form. `Gate::authorize()` throws `AuthorizationException`, resulting in a 403 HTTP response.

**FC-007 — Invalid Time Format**

The administrator enters `timetable_start_time = "25:00"` (invalid hour). The `date_format:H:i` rule rejects: "The timetable start time does not match the format H:i."

---

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_rooms` | FK parent (RESTRICT) | `room_id` FK references `sch_rooms(id)` via `fk_room_availability_room`. A room availability record cannot exist without a parent room. On DELETE RESTRICT — a room with availability records cannot be deleted. |
| `sch_rooms_type` | FK parent (RESTRICT) | `rooms_type_id` FK references `sch_rooms_type(id)` via `fk_room_availability_room_type`. |
| `sch_classes` | FK parent (RESTRICT) | `class_id` and `assigned_class_id` FKs reference `sch_classes(id)`. Used for class-house-room and per-period assignment context. |
| `sch_sections` | FK parent (RESTRICT) | `section_id` and `assigned_section_id` FKs reference `sch_sections(id)`. |
| `sch_subject_study_format_jnt` | FK parent (RESTRICT) | `subject_study_format_id` and `assigned_subject_study_format_id` FKs reference `sch_subject_study_format_jnt(id)` via `fk_room_availability_subject_study_format`. |
| `tt_activities` | FK parent (SET NULL) | `activity_id` FK references `tt_activities(id)` via `fk_room_availability_activity`. Nullable; SET NULL on activity delete. |
| `sch_class_section_jnt` | Service dependency | Queried during generation to detect class-house-room designations via `class_house_room_id`. |
| `tt_slot_requirements` | Service dependency | Used in ratio computation to derive total periods per week. |
| `tt_working_days` | Service dependency | Fallback for total periods per week calculation when SlotRequirement has no records. |
| `activityLog()` helper | Service dependency | Called on every state-changing action (store, update, destroy, restore, forceDelete, toggleStatus) to record audit entries. |
| Modules\SchoolSetup\Models\Room | Model dependency | Room master model used in create/edit forms and generation logic. |
| Modules\SchoolSetup\Models\RoomType | Model dependency | Room type model used for relationship mapping. |

### Table: `tt_room_availabilities`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `room_id` | INT UNSIGNED | NOT NULL. FK → `sch_rooms(id)` (RESTRICT) |
| `rooms_type_id` | INT UNSIGNED | NOT NULL. FK → `sch_rooms_type(id)` (RESTRICT) |
| `total_rooms_in_category` | SMALLINT UNSIGNED | NOT NULL. Count of rooms sharing the same type |
| `can_be_assigned` | BOOLEAN | DEFAULT TRUE. Master assignment switch |
| `overall_availability_status` | ENUM('Assigned','Available','Partially Available','Unavailable') | DEFAULT 'Available'. Also updated to 'Balanced'/'Tight'/'Overloaded' by ratio engine |
| `available_for_full_timetable_duration` | BOOLEAN | DEFAULT TRUE |
| `is_class_house_room` | BOOLEAN | DEFAULT FALSE |
| `house_room_class_id` | INT UNSIGNED | NULLABLE. FK → `sch_classes(id)` |
| `house_room_section_id` | INT UNSIGNED | NULLABLE. FK → `sch_sections(id)` |
| `class_id` | INT UNSIGNED | NULLABLE. FK → `sch_classes(id)` |
| `section_id` | INT UNSIGNED | NULLABLE. FK → `sch_sections(id)` |
| `subject_study_format_id` | INT UNSIGNED | NULLABLE. FK → `sch_subject_study_format_jnt(id)` |
| `activity_id` | INT UNSIGNED | NULLABLE. FK → `tt_activities(id)` (SET NULL) |
| `capacity` | INT UNSIGNED | NULLABLE. Maximum occupancy |
| `max_limit` | INT UNSIGNED | NULLABLE. Absolute ceiling |
| `can_be_assigned_for_lecture` | BOOLEAN | DEFAULT TRUE |
| `can_be_assigned_for_practical` | BOOLEAN | DEFAULT TRUE |
| `can_be_assigned_for_exam` | BOOLEAN | DEFAULT TRUE |
| `can_be_assigned_for_activity` | BOOLEAN | DEFAULT TRUE |
| `can_be_assigned_for_sports` | BOOLEAN | DEFAULT TRUE |
| `timetable_start_time` | TIME | NOT NULL |
| `timetable_end_time` | TIME | NOT NULL |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| `deleted_at` | TIMESTAMP | NULLABLE. From SoftDeletes trait |

**Unique Keys:**
- `uq_ra_class_wise` — on `(room_id, rooms_type_id, class_id, section_id, subject_study_format_id)`

**Check Constraints:**
- `chk_class_house_logic` — `(is_class_house_room = 1 AND house_room_class_id IS NOT NULL AND house_room_section_id IS NOT NULL) OR (is_class_house_room = 0)`

### Table: `tt_room_availability_details`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `room_availability_id` | INT UNSIGNED | NOT NULL. FK → `tt_room_availabilities(id)` (RESTRICT) |
| `room_id` | INT UNSIGNED | NOT NULL. FK → `sch_rooms(id)` |
| `room_type_id` | INT UNSIGNED | NOT NULL. FK → `sch_rooms_type(id)` |
| `day_number` | TINYINT UNSIGNED | NOT NULL. 1–7 |
| `day_name` | VARCHAR(10) | NOT NULL. e.g., "Monday" |
| `period_number` | TINYINT UNSIGNED | NOT NULL. 1-based period index |
| `availability_for_period` | ENUM('Assigned','Available','Unavailable') | DEFAULT 'Available' |
| `assigned_class_id` | INT UNSIGNED | NOT NULL. FK → `sch_classes(id)` |
| `assigned_section_id` | INT UNSIGNED | NULLABLE. FK → `sch_sections(id)` |
| `assigned_subject_study_format_id` | INT UNSIGNED | NOT NULL. FK → `sch_subject_study_format_jnt(id)` |
| `room_available_from_date` | DATE | NULLABLE |
| `activity_id` | INT UNSIGNED | NULLABLE. FK → `tt_activities(id)` |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| *(no timestamps)* | — | Model has `$timestamps = false` |

**Unique Keys:**
- `uq_ra_class_wise` — on `(room_availability_id, assigned_class_id, assigned_section_id, assigned_subject_study_format_id)`
