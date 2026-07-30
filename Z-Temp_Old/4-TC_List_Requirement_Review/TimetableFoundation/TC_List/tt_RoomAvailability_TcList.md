# tt_room_availabilities_TcList

## Module: TimetableFoundation → Resource Availability → Room Availability

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Resource Availability |
| Feature | Room Availability (includes Room Availability list and Room Ratio sub-tab) |
| URL(s) | `GET /timetable-foundation/resource-availability?tab=room-availability` (tab page load via `TimetableFoundationController@resourceAvailability`) |
| | **Room Availability Resource:** `GET|POST /timetable-foundation/room-availability` (index/store), `GET /timetable-foundation/room-availability/create` (create), `GET /timetable-foundation/room-availability/{id}` (show), `GET|PUT|PATCH /timetable-foundation/room-availability/{id}/edit` (edit/update), `DELETE /timetable-foundation/room-availability/{id}` (destroy) |
| | **Trash / Restore:** `GET /timetable-foundation/room-availability/trash/view` (trashedRoomAvailability), `GET /timetable-foundation/room-availability/{id}/restore` (restore), `DELETE /timetable-foundation/room-availability/{id}/force-delete` (forceDelete) |
| | **AJAX / Special:** `POST /timetable-foundation/room-availability/{room_availability}/toggle-status` (toggleStatus), `POST /timetable-foundation/room-availability/generate` (generate), `POST /timetable-foundation/room-availability/generate-ratio` (generateRoomAvailabilityRatio) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\RoomAvailabilityController` (293 lines, 11 methods); Tab page loaded via `TimetableFoundationController@resourceAvailability()` |
| Model(s) | `Modules\TimetableFoundation\Models\RoomAvailability` (table: `tt_room_availabilities`), `Modules\TimetableFoundation\Models\RoomAvailabilityDetail` (table: `tt_room_availability_details`) |
| Validation | Inline `$request->validate()` — no Form Request classes |
| Policy | `Modules\TimetableFoundation\Policies\RoomAvailabilityPolicy` |
| Permissions | `timetable-foundation.room-availability.{viewAny,view,create,update,delete,restore,forceDelete,generate}` |
| Pagination | Trash view: 10 records per page (`trashedRoomAvailability()`); main list is not paginated (uses `->get()`) |
| Soft Deletes | Yes — `RoomAvailability` uses `SoftDeletes` trait; `RoomAvailabilityDetail` does NOT use `SoftDeletes` and has `$timestamps = false` |
| Activity Log | `Created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions (full set): `timetable-foundation.room-availability.{viewAny,view,create,update,delete,restore,forceDelete,generate}`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Required seed data: At least 2 active Rooms (`sch_rooms` with `is_active = true`), at least 1 active Room Type (`sch_rooms_type`), at least 1 active Building (`sch_buildings`)
- For House Room tests: At least one `sch_class_section_jnt` record with a non-null `class_house_room_id` pointing to an active room
- For Generate Ratio tests: At least one active Activity (`tt_activities`) with `required_room_type_id` set and `required_weekly_periods > 0`, and at least one active `SlotRequirement` record (or alternatively active Working Days to compute `totalPeriodsPerWeek`)
- For Room Availability Detail tests: At least one active SchoolClass, one active Section, one active SubjectStudyFormat (`sch_subject_study_format_jnt`)

---

## 3. Default Data Load

When the `resource-availability` tab page loads via `TimetableFoundationController@resourceAvailability()` (`GET /timetable-foundation/resource-availability`), the Room Availability sub-tab grid loads data from the same controller method along with shared filter dropdowns:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared dropdowns | `TimetableFoundationController@resourceAvailability()` | `Room::where('is_active', true)->orderBy('name')` (filterRooms), `Building::where('is_active', true)->orderBy('name')` (filterBuildings) | `is_active` | None |
| Room Availability Grid | `TimetableFoundationController@resourceAvailability()` | `RoomAvailability::with(['room.building', 'details'])` | `ra_room_id`, `ra_building_id` | None (uses `->get()`) |

> **Data Source:** Room Availability records are generated from active `sch_rooms` via the `generate()` endpoint and the `RoomAvailabilityService::generate()` method using `updateOrCreate`. They are not directly created by end users in normal flow — the create/edit forms exist but are secondary to the generate workflow.

---

## 4. Test Data Strategy

- **Test data creation**: Primary method is the "Generate from Rooms" endpoint (`POST /timetable-foundation/room-availability/generate`). Direct CRUD forms also available for manual create/edit.
- **Unique suffix**: Not applicable (records keyed by `room_id`; name uniqueness not enforced).
- **Date/time values**: Use valid `H:i` format for timetable start/end times (e.g., `08:00`, `14:30`); end time must be after start time.
- **Pre-test cleanup**: Generate first to create baseline records; delete created records by ID after each test.
- **Pagination overflow**: For trash view, create 12 records (12 active rooms) to test the 10/page pagination limit.
- **Cross-module data**: Ensure `sch_rooms` has at least 2 active rooms with distinct buildings; ensure `sch_rooms_type` has at least 1 active record; for ratio generation test, ensure `tt_activities` has records with `required_room_type_id` and `required_weekly_periods` populated.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_room_availabilities`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | room_id | INT unsigned | NOT NULL, FK → `sch_rooms.id` |
| BC-DB-03 | rooms_type_id | INT unsigned | NOT NULL, FK → `sch_rooms_type.id` |
| BC-DB-04 | total_rooms_in_category | SMALLINT unsigned | NOT NULL |
| BC-DB-05 | can_be_assigned | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | overall_availability_status | ENUM('Available','Unavailable','Partially Available','Assigned') | NOT NULL DEFAULT 'Available' |
| BC-DB-07 | available_for_full_timetable_duration | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | is_class_house_room | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-09 | house_room_class_id | INT unsigned | DEFAULT NULL, FK → `sch_classes.id` |
| BC-DB-10 | house_room_section_id | INT unsigned | DEFAULT NULL, FK → `sch_sections.id` |
| BC-DB-11 | class_id | INT unsigned | DEFAULT NULL, FK → `sch_classes.id` |
| BC-DB-12 | section_id | INT unsigned | DEFAULT NULL, FK → `sch_sections.id` |
| BC-DB-13 | subject_study_format_id | INT unsigned | DEFAULT NULL, FK → `sch_subject_study_format_jnt.id` |
| BC-DB-14 | activity_id | INT unsigned | DEFAULT NULL, FK → `tt_activities.id` |
| BC-DB-15 | capacity | INT unsigned | DEFAULT NULL |
| BC-DB-16 | max_limit | INT unsigned | DEFAULT NULL |
| BC-DB-17 | can_be_assigned_for_lecture | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-18 | can_be_assigned_for_practical | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-19 | can_be_assigned_for_exam | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-20 | can_be_assigned_for_activity | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-21 | can_be_assigned_for_sports | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-22 | timetable_start_time | time | NOT NULL |
| BC-DB-23 | timetable_end_time | time | NOT NULL |
| BC-DB-24 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-25 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-26 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-27 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-28 | UNIQUE KEY `uq_ra_class_wise` | (room_id, rooms_type_id, class_id, section_id, subject_study_format_id) | Composite unique |
| BC-DB-29 | CHECK `chk_class_house_logic` | CHECK constraint | `(is_class_house_room = 1 AND house_room_class_id IS NOT NULL AND house_room_section_id IS NOT NULL) OR (is_class_house_room = 0)` |

### 5.2 Database Schema — `tt_room_availability_details`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-30 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-31 | room_availability_id | INT unsigned | NOT NULL, FK → `tt_room_availabilities.id` |
| BC-DB-32 | room_id | INT unsigned | NOT NULL, FK → `sch_rooms.id` |
| BC-DB-33 | room_type_id | INT unsigned | NOT NULL, FK → `sch_rooms_type.id` |
| BC-DB-34 | day_number | TINYINT UNSIGNED | NOT NULL (1-7) |
| BC-DB-35 | day_name | VARCHAR(10) | NOT NULL |
| BC-DB-36 | period_number | TINYINT UNSIGNED | NOT NULL (1-8) |
| BC-DB-37 | availability_for_period | ENUM('Available','Unavailable','Assigned') | NOT NULL DEFAULT 'Available' |
| BC-DB-38 | assigned_class_id | INT unsigned | NOT NULL, FK → `sch_classes.id` |
| BC-DB-39 | assigned_section_id | INT unsigned | DEFAULT NULL, FK → `sch_sections.id` |
| BC-DB-40 | assigned_subject_study_format_id | INT unsigned | NOT NULL, FK → `sch_subject_study_format_jnt.id` |
| BC-DB-41 | room_available_from_date | DATE | DEFAULT NULL |
| BC-DB-42 | activity_id | INT unsigned | DEFAULT NULL, FK → `tt_activities.id` |
| BC-DB-43 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-44 | UNIQUE KEY `uq_ra_class_wise_details` | (room_availability_id, assigned_class_id, assigned_section_id, assigned_subject_study_format_id) | Composite unique |

> **Note:** `RoomAvailabilityDetail` model has `public $timestamps = false;` and does NOT use `SoftDeletes`.

### 5.3 Validation Rules — RoomAvailabilityController (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | room_id | required, integer, exists:sch_rooms,id | Default Laravel messages |
| BC-VAL-02 | capacity | nullable, integer, min:1 | Default Laravel messages |
| BC-VAL-03 | max_limit | nullable, integer, min:1 | Default Laravel messages |
| BC-VAL-04 | overall_status | nullable, string, max:50 | Default Laravel messages |
| BC-VAL-05 | available_for_full_timetable | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-06 | can_be_assigned_for_lecture | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-07 | can_be_assigned_for_practical | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-08 | can_be_assigned_for_exam | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-09 | can_be_assigned_for_activity | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-10 | can_be_assigned_for_sports | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-11 | timetable_start_time | nullable, date_format:H:i | Default Laravel messages |
| BC-VAL-12 | timetable_end_time | nullable, date_format:H:i, after:timetable_start_time | Default Laravel messages (end must be after start) |
| BC-VAL-13 | is_active | nullable | Normalized via `$request->boolean()` |

> **Note:** The creation controller passes field `overall_status` to `create()` but the model `$fillable` defines `overall_availability_status` — the value is silently filtered by mass-assignment protection. The DB default `'Available'` is used instead.

### 5.4 Validation Rules — RoomAvailabilityController (Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-U01 | room_id | required, integer, exists:sch_rooms,id | Default Laravel messages |
| BC-VAL-U02 | capacity | nullable, integer, min:1 | Default Laravel messages |
| BC-VAL-U03 | max_limit | nullable, integer, min:1 | Default Laravel messages |
| BC-VAL-U04 | overall_status | nullable, string, max:50 | Default Laravel messages |
| BC-VAL-U05 | available_for_full_timetable | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U06 | can_be_assigned_for_lecture | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U07 | can_be_assigned_for_practical | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U08 | can_be_assigned_for_exam | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U09 | can_be_assigned_for_activity | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U10 | can_be_assigned_for_sports | nullable, boolean | Normalized via `$request->boolean()` |
| BC-VAL-U11 | timetable_start_time | nullable, date_format:H:i | Default Laravel messages |
| BC-VAL-U12 | timetable_end_time | nullable, date_format:H:i, after:timetable_start_time | Default Laravel messages |
| BC-VAL-U13 | is_active | nullable | Normalized via `$request->boolean()` |

### 5.5 Validation Rules — ToggleStatus Endpoint

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-14 | is_active | required, boolean | Default Laravel messages |

### 5.6 Authorization

| BC ID | Permission | Controller Methods | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | timetable-foundation.room-availability.viewAny | index() | Without → 403 |
| BC-AUTH-02 | timetable-foundation.room-availability.view | show() | Without → 403 |
| BC-AUTH-03 | timetable-foundation.room-availability.create | create(), store() | Without → 403 |
| BC-AUTH-04 | timetable-foundation.room-availability.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | timetable-foundation.room-availability.delete | destroy() | Without → 403 |
| BC-AUTH-06 | timetable-foundation.room-availability.restore | trashedRoomAvailability(), restore() | Without → 403 |
| BC-AUTH-07 | timetable-foundation.room-availability.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | timetable-foundation.room-availability.generate | generate(), generateRoomAvailabilityRatio() | Without → 403 |
| BC-AUTH-09 | Guest access | All routes | Redirect to `/login` |

### 5.7 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Tab loads via TimetableFoundationController@resourceAvailability() at GET /timetable-foundation/resource-availability with tab=room-availability | Navigating to `GET /timetable-foundation/resource-availability?tab=room-availability` loads the page with the Room Availability tab active; filters (ra_room_id, ra_building_id) applied if present |
| BC-BIZ-02 | Room Availability grid loads with empty state | When no records exist, displays "No room availability records found. Click 'Generate from Rooms' to create them." |
| BC-BIZ-03 | Generate from Rooms creates records | `generate()` calls `RoomAvailabilityService::generate()` which iterates all active rooms and creates/updates RoomAvailability via `updateOrCreate(['room_id' => $room->id], ...)` |
| BC-BIZ-04 | Generate from Rooms auto-sets house room class/section | Service checks `sch_class_section_jnt.class_house_room_id`; if room is designated as class house room, sets `is_class_house_room = 1`, `house_room_class_id`, `house_room_section_id` |
| BC-BIZ-05 | Generate from Rooms sets capacity/max_limit from sch_rooms | `capacity` and `max_limit` are copied from the `sch_rooms` record |
| BC-BIZ-06 | Generate from Rooms auto-sets assignment flags | `can_be_assigned_for_lecture`, `can_be_assigned_for_practical`, `can_be_assigned_for_exam`, `can_be_assigned_for_activity`, `can_be_assigned_for_sports` copied from `sch_rooms` `can_host_*` fields |
| BC-BIZ-07 | Generate from Rooms is idempotent | `updateOrCreate` ensures running generate multiple times does not create duplicates; existing records are updated in place |
| BC-BIZ-08 | Generate Room Availability Ratio computes supply/demand | `generateRoomAvailabilityRatio()` counts `SlotRequirement` for total periods/week, sums `Activity.required_weekly_periods` by room type, computes ratio = (active rooms × periods) / demand, sets `overall_availability_status` as 'Balanced' (≥1.2), 'Tight' (≥1.0), or 'Overloaded' (<1.0) |
| BC-BIZ-09 | Generate Ratio — fallback periods per week | If no `SlotRequirement` exists, uses max(1, working_days_count × 8) as total periods per week |
| BC-BIZ-10 | ToggleStatus flips is_active | AJAX `toggleStatus()` validates `is_active` as required boolean, saves the new value, and returns JSON `{success, is_active, message}` |
| BC-BIZ-11 | Destroy deactivates before soft-delete | `destroy()` sets `is_active = false`, saves, then calls `delete()` |
| BC-BIZ-12 | Restore re-activates | `restore()` nullifies `deleted_at` via `restore()`, then sets `is_active = true` |
| BC-BIZ-13 | Force-delete removes permanently | `forceDelete()` removes the record from DB permanently; activity logged as 'Deleted' |
| BC-BIZ-14 | View shows with room and building details | `show()` eager-loads `room.building` and `details` relationships |
| BC-BIZ-15 | Room filter by building | `ra_building_id` filter applies `whereHas('room', fn($q) => $q->where('building_id', $ra_building_id))` |
| BC-BIZ-16 | Room filter by room ID | `ra_room_id` filter applies `where('room_id', $ra_room_id)` |

### 5.8 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | room_id (tt_room_availabilities) | sch_rooms (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-02 | rooms_type_id (tt_room_availabilities) | sch_rooms_type (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-03 | house_room_class_id (tt_room_availabilities) | sch_classes (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-04 | house_room_section_id (tt_room_availabilities) | sch_sections (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-05 | subject_study_format_id (tt_room_availabilities) | sch_subject_study_format_jnt (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-06 | activity_id (tt_room_availabilities) | tt_activities (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-07 | room_availability_id (tt_room_availability_details) | tt_room_availabilities (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-08 | room_id (tt_room_availability_details) | sch_rooms (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-09 | room_type_id (tt_room_availability_details) | sch_rooms_type (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-10 | assigned_class_id (tt_room_availability_details) | sch_classes (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-11 | assigned_section_id (tt_room_availability_details) | sch_sections (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-12 | assigned_subject_study_format_id (tt_room_availability_details) | sch_subject_study_format_jnt (id) | RESTRICT (no explicit ON DELETE) |
| BC-REF-13 | activity_id (tt_room_availability_details) | tt_activities (id) | RESTRICT (no explicit ON DELETE) |

> **Note:** The DDL does not specify `ON DELETE` actions for any FK constraints. InnoDB defaults to `RESTRICT` (prevents deletion of parent record when child references exist).

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Room Availability Tab Loads With All UI Elements | Page loads with room-availability tab active; grid showing existing room availability records; Generate from Rooms button visible; Building filter dropdown and Room filter dropdown rendered; table columns: #, Room, Building, Overall Status, House Room, Active, Action | — | — | ⬜ |
| TC-P02 | Create Room Availability With All Required Fields | Room availability created with room_id; capacity defaults to 0; max_limit defaults to 0; overall_status saved as DB default 'Available'; redirect to tab with success flash message `created.room_availability` | — | — | ⬜ |
| TC-P03 | Create Room Availability With Capacity And Max Limit | Record created with capacity=30, max_limit=35; values stored correctly in DB | — | — | ⬜ |
| TC-P04 | Create Room Availability With All Assignment Flags Enabled | All 6 switches (available_for_full_timetable, can_be_assigned_for_lecture/practical/exam/activity/sports) set to checked; all flags stored as `1` (true) | — | — | ⬜ |
| TC-P05 | Create Room Availability With Assignment Flags Disabled | All assignment switches unchecked; all flags stored as `0` (false) | — | — | ⬜ |
| TC-P06 | Create Room Availability With Timetable Start/End Times | Record created with timetable_start_time=08:00 and timetable_end_time=14:30; times stored correctly in `H:i` format | — | — | ⬜ |
| TC-P07 | Edit Room Availability Loads Pre-Filled Data | Edit form shows existing room availability data; room_id, capacity, max_limit, overall_status, times, and all assignment flags populated correctly from existing record | — | — | ⬜ |
| TC-P08 | Update Room Availability Capacity And Flags | Room availability updated with new capacity=40, max_limit=45, can_be_assigned_for_practical=true; redirect with success flash `updated.room_availability` | — | — | ⬜ |
| TC-P09 | Show Room Availability Displays All Fields | Show page renders Room, Capacity, Max Limit, Overall Status, Timetable Start/End, Available for Full Timetable, 5 assignment flags (each Yes/No badge), Status (Active/Inactive), Created and Updated timestamps | — | — | ⬜ |
| TC-P10 | Toggle Room Availability Active Status via AJAX | `toggleStatus()` flips `is_active`; JSON response with `success=true` and new `is_active` value | — | — | ⬜ |
| TC-P11 | Soft Delete Room Availability | `destroy()` sets `is_active=false`, saves, then soft-deletes record; redirect with success flash `trashed.room_availability`; activity logged as 'Trashed' | — | — | ⬜ |
| TC-P12 | Restore Room Availability From Trash | `restore()` nullifies `deleted_at`, sets `is_active=true`; record reappears in active list; redirect with success flash `restored.room_availability`; activity logged as 'Restored' | — | — | ⬜ |
| TC-P13 | Force Delete Room Availability Permanently | `forceDelete()` removes record from DB permanently; redirect with success flash `force_deleted.room_availability`; activity logged as 'Deleted' | — | — | ⬜ |
| TC-P14 | Trash List Shows Deleted Records | `trashedRoomAvailability()` returns only soft-deleted records ordered by `latest('deleted_at')` at 10 per page; each record shows Room name, Capacity, Max Limit, Overall Status, Timetable Start/End times | — | — | ⬜ |
| TC-P15 | Generate From Rooms Creates Baseline Records | `generate()` creates RoomAvailability records for all active rooms; records include room_id, rooms_type_id, total_rooms_in_category, capacity, max_limit, and assignment flags copied from `sch_rooms`; success message: "Room availability generated successfully. N room(s) processed." | — | — | ⬜ |
| TC-P16 | Generate From Rooms Re-Processes Existing Records (Idempotent) | Running generate twice produces same record count; existing records updated (not duplicated); `updateOrCreate` ensures idempotency | — | — | ⬜ |
| TC-P17 | Generate From Rooms Detects Class House Rooms | If a room is designated as `class_house_room_id` in `sch_class_section_jnt`, the generated record has `is_class_house_room=1`, `house_room_class_id` and `house_room_section_id` populated | — | — | ⬜ |
| TC-P18 | Generate Room Availability Ratio Computes Balanced Status | When `total_supply / total_demand >= 1.2`, `overall_availability_status` is set to 'Balanced'; success message: "Room availability ratio computed. N room(s) updated." | — | — | ⬜ |
| TC-P19 | Generate Room Availability Ratio Computes Tight Status | When ratio >= 1.0 and < 1.2, status is set to 'Tight' | — | — | ⬜ |
| TC-P20 | Generate Room Availability Ratio Computes Overloaded Status | When ratio < 1.0, status is set to 'Overloaded' | — | — | ⬜ |
| TC-P21 | Filter Room Availability By Building | Selecting a building in `ra_building_id` filter and submitting filters grid to only rooms in that building | — | — | ⬜ |
| TC-P22 | Filter Room Availability By Room | Selecting a specific room in `ra_room_id` filter and submitting filters grid to show only that room | — | — | ⬜ |
| TC-P23 | Reset Filters Clears Building And Room Filters | Clicking reset link clears `ra_building_id` and `ra_room_id`; all records displayed | — | — | ⬜ |
| TC-P24 | Empty State When No Room Availability Records | Navigate before running generate; grid shows "No room availability records found. Click 'Generate from Rooms' to create them." with Generate button visible | — | — | ⬜ |
| TC-P25 | Full Lifecycle: Generate → Edit → Toggle → Delete → Trash → Restore → Force Delete | Generate creates record; edit updates capacity; toggle deactivates; delete soft-deletes; trash shows it; restore returns it; force-delete removes permanently; activity logged at each step | — | — | ⬜ |
| TC-P26 | Generate Ratio With No Activities | If no Activity with `required_room_type_id` exists, demand is 0; all ratios default to 1.00; all statuses set to 'Balanced' | — | — | ⬜ |
| TC-P27 | Generate From Rooms With Non-Assignable Flag | If a sch_rooms record has `is_active=false`, the generate creates RoomAvailability with `overall_status` set to 'Unavailable' (via service) and `is_active=false` | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `room_id` | Validation error: "The room id field is required." | — | — | ⬜ |
| TC-N02 | Invalid FK — `room_id` Non-Existent | Validation error on `exists:sch_rooms,id` | — | — | ⬜ |
| TC-N03 | Invalid — `capacity` Set to Negative | Validation error on integer or min:1 | — | — | ⬜ |
| TC-N04 | Invalid — `max_limit` Set to Zero | Validation error on min:1 (zero is less than 1) | — | — | ⬜ |
| TC-N05 | Invalid — `timetable_end_time` Before `timetable_start_time` | Validation error: "The timetable end time must be a date after timetable start time." | — | — | ⬜ |
| TC-N06 | Invalid — `timetable_start_time` Wrong Format | Validation error on `date_format:H:i` (e.g., "25:00" or "08:60" or "8 AM") | — | — | ⬜ |
| TC-N07 | Invalid — `overall_status` Exceeds 50 Characters | Validation error on `max:50` | — | — | ⬜ |
| TC-N08 | ToggleStatus — Missing `is_active` | Validation error: "The is active field is required." | — | — | ⬜ |
| TC-N09 | ToggleStatus — `is_active` Not Boolean | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N10 | Permission 403 — No viewAny Permission | 403 Forbidden on `GET /timetable-foundation/room-availability` for user without `timetable-foundation.room-availability.viewAny` | — | — | ⬜ |
| TC-N11 | Permission 403 — No create Permission | 403 Forbidden on `GET /timetable-foundation/room-availability/create` and `POST /timetable-foundation/room-availability` for user without create | — | — | ⬜ |
| TC-N12 | Permission 403 — No update Permission | 403 Forbidden on `GET /timetable-foundation/room-availability/{id}/edit`, `PUT /timetable-foundation/room-availability/{id}`, and `POST .../toggle-status` for user without update | — | — | ⬜ |
| TC-N13 | Permission 403 — No delete Permission | 403 Forbidden on `DELETE /timetable-foundation/room-availability/{id}` for user without delete | — | — | ⬜ |
| TC-N14 | Permission 403 — No restore Permission | 403 Forbidden on `GET /timetable-foundation/room-availability/trash/view` and `GET .../{id}/restore` for user without restore | — | — | ⬜ |
| TC-N15 | Permission 403 — No forceDelete Permission | 403 Forbidden on `DELETE /timetable-foundation/room-availability/{id}/force-delete` for user without forceDelete | — | — | ⬜ |
| TC-N16 | Permission 403 — No generate Permission | 403 Forbidden on `POST /timetable-foundation/room-availability/generate` and `POST .../generate-ratio` for user without generate | — | — | ⬜ |
| TC-N17 | Guest Access Redirect For All Routes | Redirect to `/login` for all room-availability routes when unauthenticated | — | — | ⬜ |
| TC-N18 | Edit/Show/Delete With Invalid ID (404) | `findOrFail` throws `ModelNotFoundException` → HTTP 404 for non-existent ID on edit, show, update, destroy, restore, forceDelete | — | — | ⬜ |
| TC-N19 | Restore Non-Trashed Record (Not Soft-Deleted) | `onlyTrashed()->findOrFail()` throws 404 for active (non-deleted) records | — | — | ⬜ |
| TC-N20 | Generate Ratio With Zero Demand | When no Activities or SlotRequirements exist, ratio defaults to 1.00; all statuses set to 'Balanced'; no error thrown | — | — | ⬜ |
| TC-N21 | Generate From Rooms With Zero Active Rooms | If no `sch_rooms` have `is_active=true`, `RoomAvailabilityService::generate()` processes 0 rooms; message: "Room availability generated successfully. 0 room(s) processed." | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Room Availability — Soft Delete Sets is_active=false Before Delete | `destroy()` sets `is_active=false`, saves, then `delete()`; `restore()` sets `is_active=true` after restoring | — | — | ⬜ |
| TC-D02 | A | Room Availability — Restore Re-Activates | `restore()` calls `restore()` on the SoftDeletes trait then sets `is_active=true`; record returns to active list | — | — | ⬜ |
| TC-D03 | B | Generate Service — Idempotent updateOrCreate | `RoomAvailabilityService::generate()` uses `updateOrCreate(['room_id' => $room->id], ...)`; running multiple times does not duplicate, only updates | — | — | ⬜ |
| TC-D04 | C | Generate — Class House Room Detection | Service queries `sch_class_section_jnt` for rooms designated as `class_house_room_id`; correctly sets `is_class_house_room`, `house_room_class_id`, `house_room_section_id` | — | — | ⬜ |
| TC-D05 | D | Generate — Assignment Flags Copied From sch_rooms | Service reads `sch_rooms.can_host_lecture/practical/exam/activity/sports` and maps to `can_be_assigned_for_*` fields; defaults used where `sch_rooms` fields are null | — | — | ⬜ |
| TC-D06 | E | Generate Ratio — Fallback Total Periods | When `SlotRequirement` count is 0, uses `max(1, active WorkingDays count × 8)` as denominator | — | — | ⬜ |
| TC-D07 | F | FK RESTRICT — Prevent Room Deletion When Referenced | Room with a RoomAvailability record cannot be force-deleted from `sch_rooms`; FK constraint violation thrown | — | — | ⬜ |
| TC-D08 | G | FK RESTRICT — Prevent Room Type Deletion When Referenced | `rooms_type_id` reference in `tt_room_availabilities` blocks deletion of parent `sch_rooms_type` row | — | — | ⬜ |
| TC-D09 | H | Activity Logged On All State Changes | `Created` (store), `Updated` (update), `Trashed` (destroy), `Restored` (restore), `Deleted` (forceDelete), `Toggled` (toggleStatus) each call `activityLog()` | — | — | ⬜ |
| TC-D10 | I | Model — RoomAvailability $casts Verification | `room_id`, `rooms_type_id`, `capacity`, `max_limit`, `house_room_class_id`, `house_room_section_id`, `activity_id` cast to integer; `can_be_assigned`, `available_for_full_timetable_duration`, `is_class_house_room`, `can_be_assigned_for_lecture/practical/exam/activity/sports`, `is_active` cast to boolean; `created_at`, `updated_at`, `deleted_at` cast to datetime | — | — | ⬜ |
| TC-D11 | J | Model — RoomAvailabilityDetail $casts and No Timestamps | `room_availability_id`, `room_id`, `room_type_id`, `day_number`, `period_number`, `assigned_class_id`, `assigned_section_id`, `assigned_subject_study_format_id`, `activity_id` cast to integer; `availability_for_period` cast to string; `room_available_from_date` cast to date; `is_active` cast to boolean; model has `$timestamps = false` (no created_at/updated_at) | — | — | ⬜ |
| TC-D12 | K | Model — RoomAvailability Relationships | `room()` belongsTo Room; `roomType()` belongsTo RoomType; `houseRoomClass()` belongsTo SchoolClass; `houseRoomSection()` belongsTo Section; `activity()` belongsTo Activity; `details()` hasMany RoomAvailabilityDetail; `scopeActive()` and `scopeAssignable()` defined | — | — | ⬜ |
| TC-D13 | L | Model — RoomAvailabilityDetail Relationships | `roomAvailability()` belongsTo RoomAvailability; `room()` belongsTo Room; `roomType()` belongsTo RoomType; `assignedClass()` belongsTo SchoolClass; `assignedSection()` belongsTo Section; `assignedSubjectStudyFormat()` belongsTo StudyFormat; `activity()` belongsTo Activity; scopes: `active()`, `forDay()`, `forPeriod()`, `available()` | — | — | ⬜ |
| TC-D14 | M | Controller — findOrFail Returns 404 For Invalid IDs | All findOrFail calls (`show`, `edit`, `update`, `destroy`, `restore`, `forceDelete`) throw `ModelNotFoundException` → HTTP 404 for non-existent IDs | — | — | ⬜ |
| TC-D15 | N | Controller — Gate::authorize() Called Before All Methods | Each controller method calls `Gate::authorize()` with correct permission string before any logic; without permission → 403 Forbidden | — | — | ⬜ |
| TC-D16 | O | Unique Constraint — DDL `uq_ra_class_wise` | DB unique key on `(room_id, rooms_type_id, class_id, section_id, subject_study_format_id)` prevents duplicate combinations; duplicate insert throws integrity constraint violation | — | — | ⬜ |
| TC-D17 | P | Generate — Service Handles Empty House Room Data Gracefully | If `sch_class_section_jnt` has no rows or no `class_house_room_id` values, `$houseRoomData` is empty; all rooms get `is_class_house_room=0` | — | — | ⬜ |
| TC-D18 | Q | Generate Ratio — Error Handling | If `generateRoomAvailabilityRatio()` encounters exception during processing, error is logged via `\Log::error()`, but method does not catch exceptions (no try-catch wrapper); any unhandled exception returns 500 | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — RoomAvailability $fillable Matches DDL Columns | `$fillable` includes: room_id, rooms_type_id, total_rooms_in_category, can_be_assigned, overall_availability_status, available_for_full_timetable_duration, is_class_house_room, house_room_class_id, house_room_section_id, activity_id, capacity, max_limit, can_be_assigned_for_lecture/practical/exam/activity/sports, timetable_start_time, timetable_end_time, is_active, created_by | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — RoomAvailabilityDetail $fillable Matches DDL Columns | `$fillable` includes: room_availability_id, room_id, room_type_id, day_number, day_name, period_number, availability_for_period, assigned_class_id, assigned_section_id, assigned_subject_study_format_id, room_available_from_date, activity_id, is_active | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — RoomAvailability $casts Correct | Booleans: can_be_assigned, available_for_full_timetable_duration, is_class_house_room, can_be_assigned_for_*, is_active; Integers: room_id, rooms_type_id, total_rooms_in_category, house_room_class_id, house_room_section_id, activity_id, capacity, max_limit; String: overall_availability_status; Datetime: created_at, updated_at, deleted_at | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — RoomAvailabilityDetail $casts and Timestamps Correct | Booleans: is_active; Integers: room_availability_id, room_id, room_type_id, day_number, period_number, assigned_class_id, assigned_section_id, assigned_subject_study_format_id, activity_id; String: availability_for_period; Date: room_available_from_date; `$timestamps = false` | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — SoftDeletes Trait on RoomAvailability | RoomAvailability uses `SoftDeletes`; `deleted_at` column present; `onlyTrashed()`, `withTrashed()`, `restore()` work | — | — | ◌ |
| TC-CR06 | CR | P1 | Model — RoomAvailabilityDetail Has No SoftDeletes | RoomAvailabilityDetail model does NOT use SoftDeletes trait; no `deleted_at` column | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — Relationships Defined Per FK | RoomAvailability: 6 belongsTo (room, roomType, houseRoomClass, houseRoomSection, activity) + 1 hasMany (details); RoomAvailabilityDetail: 7 belongsTo (roomAvailability, room, roomType, assignedClass, assignedSection, assignedSubjectStudyFormat, activity) | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Try-Catch on Write Methods | store(), update(), destroy() have no try-catch; generate() has try-catch catching \Exception and logging error; toggleStatus() has implicit fallback JSON error response; generateRoomAvailabilityRatio() has no try-catch | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — DB Transactions on Multi-Step Writes | All write methods use single Eloquent operations; no explicit `DB::transaction()` wrapping used | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — Gate::authorize() on Every Method | All 11 controller methods call `Gate::authorize()` with correct permission string; no unauthenticated write access | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — Activity Logged on All State Changes | store(): 'Created'; update(): 'Updated'; destroy(): 'Trashed'; restore(): 'Restored'; forceDelete(): 'Deleted'; toggleStatus(): 'Toggled' — each with descriptive message | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — is_active=false Before Soft Delete | `destroy()` sets `is_active=false`, calls `save()`, then calls `delete()` | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — Restore Sets is_active=true | `restore()` calls `restore()` on SoftDeletes, then sets `is_active=true` and `save()` | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — toggleStatus() Flips is_active via AJAX | Validates `is_active` as required boolean; saves new value; returns JSON `{success, is_active, message}`; activity logged as 'Toggled' | — | — | ◌ |
| TC-CR15 | CR | P1 | Controller — Trash/Restore/ForceDelete Flow | `trashedRoomAvailability()` uses `onlyTrashed()` with `latest('deleted_at')->paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail()` then restore + reactivate; `forceDelete()` uses `withTrashed()->findOrFail()` then `forceDelete()` | — | — | ◌ |
| TC-CR16 | CR | P1 | Controller — Flash Success Response After CRUD Operations | All CRUD methods redirect with `->with('success', flash('...'))`; toggleStatus returns JSON; generate returns string-based success message | — | — | ◌ |
| TC-CR17 | CR | P1 | Controller — Generate Method Uses Service Layer | `generate()` calls `RoomAvailabilityService::generate()` and returns count in success message; wrapped in try-catch | — | — | ◌ |
| TC-CR18 | CR | P1 | Policy — RoomAvailabilityPolicy Defines All Required Gates | viewAny, view, create, update, delete, restore, forceDelete methods defined; each delegates to `$user->can()` | — | — | ◌ |
| TC-CR19 | CR | P1 | Routes — Resource + Custom Routes Registered | Resourceful (index/create/store/show/edit/update/destroy) + trashed, restore, forceDelete, toggleStatus, generate, generateRatio — 11 total routes mapped to correct controller methods; model binding on toggleStatus uses `Route::model` binding | — | — | ◌ |
| TC-CR20 | CR | P1 | View — Route::has() Guards on Tab/Action Buttons | _list.blade.php: `@if(Route::has('timetable-foundation.room-availability.generate'))`, `@if(Route::has('...show'))`, `@if(Route::has('...edit'))` guard button visibility | — | — | ◌ |
| TC-CR21 | CR | P1 | View — Null-Safe Checks for Relationship Variables | `$ra->room?->name ?? '—'`, `$ra->room?->building?->name ?? '—'`, `$roomAvailability->capacity ?? 0`, `$roomAvailability->overall_status ?? 'N/A'` — null coalescing in list, show, edit, and trash views | — | — | ◌ |
| TC-CR22 | CR | P1 | Validation — All Fields Covered; No Unique Rules on Update | Create validation covers all 13 fields; update validation same as create; no `unique` rule on any field (uniqueness enforced at DB level via composite unique key `uq_ra_class_wise`) | — | — | ◌ |
| TC-CR23 | CR | P1 | Database — Unique Index Matches DDL | Composite UNIQUE KEY `uq_ra_class_wise` on `(room_id, rooms_type_id, class_id, section_id, subject_study_format_id)` in both DDL and migration | — | — | ◌ |
| TC-CR24 | CR | P1 | Database — CHECK Constraint on is_class_house_room Logic | DDL defines `chk_class_house_logic`: `(is_class_house_room = 1 AND house_room_class_id IS NOT NULL AND house_room_section_id IS NOT NULL) OR (is_class_house_room = 0)` | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

#### TC-CR01: RoomAvailability $fillable Matches DDL Columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/TimetableFoundation/Models/RoomAvailability.php` | File exists |
| 2 | Compare `$fillable` array against `tt_room_availabilities` DDL columns | All non-PK, non-timestamp columns listed; `overall_availability_status` present (not `overall_status`); no extra columns beyond DDL |

#### TC-CR02: RoomAvailabilityDetail $fillable Matches DDL Columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/TimetableFoundation/Models/RoomAvailabilityDetail.php` | File exists |
| 2 | Compare `$fillable` array against `tt_room_availability_details` DDL columns | All non-PK columns listed; no extra columns |

#### TC-CR03: RoomAvailability $casts Correct
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open RoomAvailability model `$casts` property | Boolean casts for all `TINYINT(1)` flags; integer casts for FK/INT columns; datetime casts for timestamps |

#### TC-CR04: RoomAvailabilityDetail $casts and Timestamps Correct
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open RoomAvailabilityDetail model | `$timestamps = false` set; `$casts` covers all columns appropriately |

#### TC-CR05: SoftDeletes Trait on RoomAvailability
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect RoomAvailability model `use` statements | `SoftDeletes` imported and used |
| 2 | Check migration for `deleted_at` column | `deleted_at` TIMESTAMP NULLABLE present in `tt_room_availabilities` |

#### TC-CR06: RoomAvailabilityDetail No SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect RoomAvailabilityDetail model `use` statements | `SoftDeletes` NOT present |
| 2 | Check DDL for `tt_room_availability_details` | No `deleted_at` column |

#### TC-CR07: Relationships Defined Per FK
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect RoomAvailability model relationships | `room()`, `roomType()`, `houseRoomClass()`, `houseRoomSection()`, `activity()`, `details()` all defined as BelongsTo/HasMany |
| 2 | Inspect RoomAvailabilityDetail model relationships | `roomAvailability()`, `room()`, `roomType()`, `assignedClass()`, `assignedSection()`, `assignedSubjectStudyFormat()`, `activity()` all defined as BelongsTo |

#### TC-CR08: Try-Catch on Write Methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` method | No try-catch wrapper |
| 2 | Inspect `update()` method | No try-catch wrapper |
| 3 | Inspect `destroy()` method | No try-catch wrapper |
| 4 | Inspect `generate()` method | Try-catch present, error logged via `\Log::error()`, user redirected with error message |
| 5 | Inspect `toggleStatus()` method | Has implicit error path (returns JSON 422 on save failure) |

#### TC-CR09: DB Transactions on Multi-Step Writes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all write methods (store, update, destroy, generate, generateRoomAvailabilityRatio) | No `DB::transaction()` or `DB::beginTransaction()` calls found |

#### TC-CR10: Gate::authorize() on Every Method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each controller method's first lines | `Gate::authorize('timetable-foundation.room-availability.*')` called before any logic in all 11 methods |

#### TC-CR11: Activity Logged on All State Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | `activityLog($roomAvailability, 'Created', ...)` called after create |
| 2 | Inspect `update()` | `activityLog($roomAvailability, 'Updated', ...)` called after update |
| 3 | Inspect `destroy()` | `activityLog($roomAvailability, 'Trashed', ...)` called after delete |
| 4 | Inspect `restore()` | `activityLog($roomAvailability, 'Restored', ...)` called after restore |
| 5 | Inspect `forceDelete()` | `activityLog($roomAvailability, 'Deleted', ...)` called after forceDelete |
| 6 | Inspect `toggleStatus()` | `activityLog($roomAvailability, 'Toggled', ...)` called before save |

#### TC-CR12: is_active=false Before Soft Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` | `$roomAvailability->is_active = false; $roomAvailability->save(); $roomAvailability->delete();` in sequence |

#### TC-CR13: Restore Sets is_active=true
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `restore()` | `$roomAvailability->restore(); $roomAvailability->is_active = true; $roomAvailability->save();` in sequence |

#### TC-CR14: toggleStatus() Flips is_active via AJAX
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `toggleStatus()` | Validates `is_active` as required boolean; saves; returns JSON `{success, is_active, message}` on success; returns 422 JSON on failure |

#### TC-CR15: Trash/Restore/ForceDelete Flow
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `trashedRoomAvailability()` | Uses `onlyTrashed()` with `latest('deleted_at')->paginate(10)` |
| 2 | Inspect `restore()` | Uses `onlyTrashed()->findOrFail($id)` |
| 3 | Inspect `forceDelete()` | Uses `withTrashed()->findOrFail($id)` then `forceDelete()` |

#### TC-CR16: Flash Success Response After CRUD Operations
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect redirects in store, update, destroy, restore, forceDelete | All return `redirect()->route(...)->with('success', flash('...'))` |
| 2 | Inspect toggleStatus | Returns `response()->json([...])` |
| 3 | Inspect generate | Returns `redirect()->back()->with('success', "Room availability generated successfully. ...")` |

#### TC-CR17: Generate Method Uses Service Layer
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `generate()` | Calls `$this->roomAvailabilityService->generate()`, wraps in try-catch, returns count in message |

#### TC-CR18: Policy Defines All Required Gates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `RoomAvailabilityPolicy` | Methods: viewAny, view, create, update, delete, restore, forceDelete — each delegating to `$user->can()` |

#### TC-CR19: Routes Registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `routes/web.php` | Resource route `Route::resource('room-availability', ...)` + custom routes: trashed, restore, forceDelete, toggleStatus, generate, generateRatio — 11 total |
| 2 | Verify each maps to correct controller method | Route::resource maps index/create/store/show/edit/update/destroy; custom routes map trashedRoomAvailability, restore, forceDelete, toggleStatus, generate, generateRoomAvailabilityRatio |

#### TC-CR20: Route::has() Guards on Buttons
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `_list.blade.php` | `@if(Route::has('...generate'))`, `@if(Route::has('...show'))`, `@if(Route::has('...edit'))` wrap respective buttons |

#### TC-CR21: Null-Safe Checks for Relationship Variables
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect list, show, edit, trash views | All relationship access uses `?->` null-safe operator or `??` null coalescing (e.g., `$ra->room?->name ?? '—'`, `$roomAvailability->capacity ?? 0`) |

#### TC-CR22: Validation Covers All Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` validation rules | 13 fields validated: room_id, capacity, max_limit, overall_status, available_for_full_timetable, can_be_assigned_for_*, timetable_start_time, timetable_end_time, is_active |
| 2 | Inspect `update()` validation rules | Same rules as create; no `unique:...` ignore rules needed (no unique validation on individual fields) |

#### TC-CR23: Unique Index Matches DDL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare migration unique key vs DDL `uq_ra_class_wise` | Both define `UNIQUE KEY` on `(room_id, rooms_type_id, class_id, section_id, subject_study_format_id)` |

#### TC-CR24: CHECK Constraint on is_class_house_room Logic
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect DDL for `chk_class_house_logic` | CHECK constraint: `(is_class_house_room = 1 AND house_room_class_id IS NOT NULL AND house_room_section_id IS NOT NULL) OR (is_class_house_room = 0)` |
| 2 | Verify insert violating constraint | Insert with `is_class_house_room=1` but `house_room_class_id=NULL` fails with constraint violation |

---

### 7.1 Positive TC Steps

#### TC-P01: Room Availability Tab Loads With All UI Elements
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/resource-availability?tab=room-availability` | Page loads; Room Availability tab is active; tab label "Room Availability" with door-open icon visible |
| 3 | Observe grid table | Table with columns: #, Room, Building, Overall Status, House Room, Active, Action |
| 4 | Observe Generate button | "Generate from Rooms" button visible in header |
| 5 | Observe filter dropdowns | Building filter and Room filter dropdowns visible in search bar |
| 6 | Observe action buttons per row | View (eye icon) and Edit (pencil icon) buttons visible for each record |

#### TC-P02: Create Room Availability With Required Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/room-availability/create` | Create form loads with Room dropdown |
| 2 | Select a room from dropdown | Room selected |
| 3 | Leave capacity, max_limit, overall_status, times, assignment flags at defaults | All optional fields use defaults |
| 4 | Click "Add Room Availability" submit button | Form submitted to `POST /timetable-foundation/room-availability` |
| 5 | Observe redirect | Redirected to `GET /timetable-foundation/resource-availability` tab with success flash message `created.room_availability` |
| 6 | Verify DB record | `tt_room_availabilities` has new row with `room_id` set, `capacity=0`, `max_limit=0`, `overall_availability_status='Available'` (DB default) |

#### TC-P03: Create Room Availability With Capacity And Max Limit
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create form loads |
| 2 | Select room, enter capacity=30, max_limit=35 | Values entered |
| 3 | Submit form | Record created with capacity=30, max_limit=35 |

#### TC-P04: Create With All Assignment Flags Enabled
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create form loads |
| 2 | Select room; check all 6 switches (available_for_full_timetable, can_be_assigned_for_lecture/practical/exam/activity/sports) | All switches ON |
| 3 | Submit form | Record created; all 6 flags stored as `1` (true) |

#### TC-P06: Create With Timetable Start/End Times
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create form loads |
| 2 | Select room; enter timetable_start_time=08:00, timetable_end_time=14:30 | Times entered in `time` input fields |
| 3 | Submit form | Record created with times stored as 08:00:00 and 14:30:00 |

#### TC-P07: Edit Room Availability Loads Pre-Filled Data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure RoomAvailability record exists with known values | Record present |
| 2 | Navigate to `GET /timetable-foundation/room-availability/{id}/edit` | Edit form loads |
| 3 | Observe form fields | Room dropdown pre-selected; capacity, max_limit, overall_status, times, and all assignment switches match existing record values |

#### TC-P08: Update Room Availability
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit form for existing record | Edit form loads |
| 2 | Change capacity to 40, max_limit to 45, enable can_be_assigned_for_practical | Values updated |
| 3 | Click "Update Room Availability" | `PUT /timetable-foundation/room-availability/{id}` called |
| 4 | Observe redirect | Redirected to resource-availability tab; success flash `updated.room_availability` |
| 5 | Verify DB | Record updated with capacity=40, max_limit=45, can_be_assigned_for_practical=1 |

#### TC-P09: Show Room Availability Displays All Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/room-availability/{id}` | Show page renders |
| 2 | Observe fields | Room, Capacity, Max Limit, Overall Status, Timetable Start/End, Available for Full Timetable (Yes/No badge), 5 assignment flags (Yes/No badges), Status (Active/Inactive badge), Created and Updated timestamps all displayed |

#### TC-P10: Toggle Room Availability Active Status via AJAX
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure RoomAvailability record exists with `is_active=true` | Record active |
| 2 | Send `POST /timetable-foundation/room-availability/{id}/toggle-status` with body `is_active=false` | AJAX request |
| 3 | Observe response | JSON `{"success": true, "is_active": false, "message": "..."}` |
| 4 | Verify DB | `is_active` = 0 |
| 5 | Send toggle again with `is_active=true` | JSON `{"success": true, "is_active": true, ...}`; DB updated |

#### TC-P11: Soft Delete Room Availability
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure RoomAvailability record exists with `is_active=true` | Record active |
| 2 | Send `DELETE /timetable-foundation/room-availability/{id}` | Request sent |
| 3 | Observe redirect | Redirected to resource-availability tab; success flash `trashed.room_availability` |
| 4 | Verify DB | Record: `is_active=0`, `deleted_at` is non-null (timestamp set) |

#### TC-P12: Restore Room Availability From Trash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure record is soft-deleted (deleted_at set) | Record trashed |
| 2 | Navigate to `GET /timetable-foundation/room-availability/trash/view` | Trash list shows the deleted record |
| 3 | Send `GET /timetable-foundation/room-availability/{id}/restore` | Request sent |
| 4 | Observe redirect | Redirected to trash page; success flash `restored.room_availability` |
| 5 | Verify DB | Record: `deleted_at=null`, `is_active=1` |

#### TC-P13: Force Delete Room Availability Permanently
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure record is soft-deleted | Record trashed |
| 2 | Send `DELETE /timetable-foundation/room-availability/{id}/force-delete` | Request sent |
| 3 | Observe redirect | Redirected to trash page; success flash `force_deleted.room_availability` |
| 4 | Verify DB | Record permanently removed from `tt_room_availabilities` |

#### TC-P14: Trash List Shows Deleted Records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 1 soft-deleted RoomAvailability record | Record trashed |
| 2 | Navigate to `GET /timetable-foundation/room-availability/trash/view` | Trash page loads |
| 3 | Observe table | Columns: Room, Capacity, Max Limit, Overall Status, Timetable Start/End, Action with restore/force-delete buttons |
| 4 | Verify only trashed records shown | No active records in trash list |

#### TC-P15: Generate From Rooms Creates Baseline Records
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 3 active rooms exist in `sch_rooms` with distinct room types | Rooms present |
| 2 | Ensure NO RoomAvailability records exist (truncate or start clean) | No existing records |
| 3 | Send `POST /timetable-foundation/room-availability/generate` with CSRF token | Request sent |
| 4 | Observe redirect | Redirected back with success: "Room availability generated successfully. 3 room(s) processed." |
| 5 | Query DB | 3 RoomAvailability records created, one per active room; `room_id`, `rooms_type_id`, `total_rooms_in_category`, `capacity`, `can_be_assigned_for_*` filled from `sch_rooms` data |

#### TC-P16: Generate From Rooms Is Idempotent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run generate (TC-P15) first time | 3 records created |
| 2 | Run generate second time | "3 room(s) processed." |
| 3 | Query DB | Still exactly 3 records (no duplicates); `updated_at` updated |

#### TC-P17: Generate Detects Class House Rooms
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create `sch_class_section_jnt` record with `class_house_room_id` pointing to an active room | Junction record created |
| 2 | Run generate | RoomAvailability for that room has `is_class_house_room=1`, `house_room_class_id` and `house_room_section_id` populated from junction data |

#### TC-P18: Generate Ratio Computes Balanced Status
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Activity records with low `required_weekly_periods` relative to available rooms | Low demand |
| 2 | Create SlotRequirement records (e.g., 40 periods/week) | Supplies set |
| 3 | Run `POST /timetable-foundation/room-availability/generate-ratio` | Ratio >= 1.2; statuses set to 'Balanced' |
| 4 | Observe redirect | "Room availability ratio computed. N room(s) updated." |

#### TC-P21: Filter By Building
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure rooms exist in at least 2 different buildings | Rooms in Building A and Building B |
| 2 | Navigate to tab with `ra_building_id` set to Building A's ID | Grid shows only rooms in Building A |
| 3 | Navigate to tab with `ra_building_id` set to Building B's ID | Grid shows only rooms in Building B |

#### TC-P22: Filter By Room
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 2 RoomAvailability records exist | Records present |
| 2 | Navigate to tab with `ra_room_id` set to one room's ID | Grid shows only that specific room's record |

#### TC-P24: Empty State Display
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no RoomAvailability records exist (before running generate) | No records |
| 2 | Navigate to `GET /timetable-foundation/resource-availability?tab=room-availability` | Grid shows: "No room availability records found. Click 'Generate from Rooms' to create them." |

#### TC-P25: Full Lifecycle Test
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run generate to create a record | Record created |
| 2 | Navigate to edit, change capacity to 50, save | Updated successfully |
| 3 | Toggle status to inactive via AJAX | is_active flipped to false |
| 4 | Delete the record | Soft-deleted, is_active=false |
| 5 | Navigate to trash view | Record visible in trash |
| 6 | Restore the record | Record restored, is_active=true |
| 7 | Force-delete the record | Record permanently removed |

---

### 7.2 Negative TC Steps

#### TC-N01: Missing Required room_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `POST /timetable-foundation/room-availability` without `room_id` field | Validation error: "The room id field is required." |

#### TC-N02: Non-Existent room_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit `POST /timetable-foundation/room-availability` with `room_id=99999` (non-existent) | Validation error on `exists:sch_rooms,id` |

#### TC-N05: timetable_end_time Before timetable_start_time
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with `timetable_start_time=14:00` and `timetable_end_time=08:00` | Validation error: "The timetable end time must be a date after timetable start time." |

#### TC-N06: Invalid Time Format
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with `timetable_start_time=25:00` | Validation error on `date_format:H:i` |

#### TC-N18: Edit/Show/Delete With Invalid ID (404)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/room-availability/99999/edit` | HTTP 404 error |
| 2 | Navigate to `GET /timetable-foundation/room-availability/99999` | HTTP 404 error |
| 3 | Submit `DELETE /timetable-foundation/room-availability/99999` | HTTP 404 error |

#### TC-N19: Restore Non-Trashed Record
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/room-availability/{id}/restore` where record is active (not soft-deleted) | HTTP 404 (onlyTrashed findOrFail fails) |

#### TC-N10: No viewAny Permission → 403
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `timetable-foundation.room-availability.viewAny` | User has other permissions |
| 2 | Navigate to `GET /timetable-foundation/room-availability` | HTTP 403 Forbidden |

#### TC-N17: Guest Redirect
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout or use unauthenticated session | Not logged in |
| 2 | Navigate to any room-availability route (e.g., `GET /timetable-foundation/room-availability`) | Redirected to `/login` |

---

### 7.3 Dependency TC Steps

#### TC-D01: Soft Delete Deactivates Before Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Capture RoomAvailability record with `is_active=true` | Record active |
| 2 | Execute `DELETE /timetable-foundation/room-availability/{id}` | Request processed |
| 3 | Query DB directly (withTrashed) | `is_active=0`, `deleted_at` is non-null |

#### TC-D02: Restore Re-Activates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure record is soft-deleted with `is_active=false` | Record trashed |
| 2 | Execute `GET /timetable-foundation/room-availability/{id}/restore` | Restore processed |
| 3 | Query DB | `deleted_at=NULL`, `is_active=1` |

#### TC-D07: FK RESTRICT — Prevent Room Deletion
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure RoomAvailability record references `sch_rooms.id = X` | Reference exists |
| 2 | Attempt to delete room X from `sch_rooms` directly | FK constraint violation error (cannot delete parent row) |

#### TC-D10: Model $casts Verification
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query RoomAvailability record and access `can_be_assigned`, `is_active`, `is_class_house_room` | Values returned as boolean (true/false), not integer (0/1) |
| 2 | Access `room_id`, `capacity` | Values returned as integer |
| 3 | Access `created_at` | Returned as Carbon/datetime instance |

#### TC-D14: findOrFail Returns 404
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call show/edit/update/destroy/restore/forceDelete with `id=99999` | Each throws `ModelNotFoundException` → HTTP 404 response |

#### TC-D15: Gate::authorize() Called on All Methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review each of the 11 controller methods | Each has `Gate::authorize('timetable-foundation.room-availability.*')` as first statement inside method body |
