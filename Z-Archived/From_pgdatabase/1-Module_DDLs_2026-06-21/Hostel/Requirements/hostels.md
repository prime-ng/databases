# Hostels (Buildings) — Requirements

## What It Does
Manages hostel/building master records. Each hostel is a building that contains floors, rooms, and beds. Hostels have gender restrictions, capacity tracking, warden assignments, and contact details.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(150) | Required. Display name. |
| `code` | VARCHAR(20) | Nullable. Unique. Short code (BH1, GH1). |
| `type` | ENUM('boys','girls','mixed') | Required. Gender restriction. |
| `gender_strict_enforce` | TINYINT(1) | Default 1. 1 = solver rejects opposite-gender allotment. |
| `warden_id` | INT UNSIGNED FK → sys_users | Nullable. Current chief warden. |
| `principal_warden_id` | INT UNSIGNED FK → sys_users | Nullable. Secondary/acting warden. |
| `total_capacity` | SMALLINT UNSIGNED | Default 0. Recomputed by service. |
| `current_occupancy` | SMALLINT UNSIGNED | Default 0. Maintained synchronously. |
| `total_floors` | TINYINT UNSIGNED | Default 0. Denormalized count. |
| `sick_bay_capacity` | TINYINT UNSIGNED | Default 5. Sick-bay bed capacity. |
| `address` | VARCHAR(500) | Nullable. |
| `contact_phone` | VARCHAR(20) | Nullable. |
| `email` | VARCHAR(150) | Nullable. |
| `visiting_days_json` | JSON | Nullable. |
| `facilities_json` | JSON | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:150 | "The name field is required." / "Name must not exceed 150 characters." |
| `code` | Nullable, string, max:20, unique across all hostels (including soft-deleted) | "The code has already been taken." — checked at application level since DB UNIQUE is nullable and MySQL allows multiple NULLs |
| `type` | Required, enum: boys/girls/mixed | "The selected type is invalid." — validated against exact enum values |
| `gender_strict_enforce` | Required, boolean, default 1 | Must be 0 or 1. If not provided, defaults to 1 (strict enforcement). |
| `warden_id` | Nullable, integer, exists:sys_users,id | "The selected warden is invalid." — must reference an existing user record. If user is deleted, FK constraint sets this to NULL automatically (ON DELETE SET NULL). |
| `principal_warden_id` | Nullable, integer, exists:sys_users,id | Same as warden_id. Must be a different user than warden_id. Application-level check: cannot set principal_warden_id equal to warden_id. |
| `total_capacity` | Read-only (computed) | Never accepted from user input. Recalculated by AllotmentService. |
| `current_occupancy` | Read-only (computed) | Never accepted from user input. Updated synchronously on every allot/vacate/transfer. |
| `total_floors` | Read-only (computed) | Never accepted from user input. Recalculated when floors are created/deleted/restored. |
| `sick_bay_capacity` | Required, integer, min:0, max:999 | Must be 0-999. Defaults to 5 if not provided. Can be 0 if hostel has no sick bay. |
| `address` | Nullable, string, max:500 | Truncated to 500 characters if longer. |
| `contact_phone` | Nullable, string, max:20, regex:/^[0-9+\-\s()]+$/ | Must contain only digits, +, -, spaces, and parentheses. Validated but not required. |
| `email` | Nullable, string, max:150, email format | Must be a valid email format (RFC 5321). Checked by Laravel email validation rule. |
| `visiting_days_json` | Nullable, JSON | Must be valid JSON. Structure expected: `{"days":["monday","wednesday","friday"],"hours":{"start":"10:00","end":"18:00"},"note":"Optional note"}`. If invalid JSON, form is rejected with "The visiting days format is invalid." |
| `facilities_json` | Nullable, JSON | Must be valid JSON. Expected structure: `["WiFi","Hot Water","Generator","Common Room","TV Room","Study Hall","Indoor Games","Gym","Laundry","Canteen","Medical Room","Parking","Security","CCTV","Visitor Waiting Area","Prayer Room","Store Room","Kitchen","Dining Hall","Bathroom","Toilet","Terrace","Garden","Playground"]`. Array of facility name strings. Must not contain duplicate entries. Maximum 50 facilities. Each facility name max 100 chars. Invalid JSON rejected with "The facilities format is invalid." |
| `is_active` | Required, boolean, default 1 | Must be 0 or 1. Automatically set to 0 before soft delete. Cannot be set to 0 if current_occupancy > 0 — rejection message: "Cannot deactivate hostel with active allotments. Vacate all students first." |
| `deleted_at` | Nullable, timestamp | Set automatically by Laravel soft delete trait on delete(). Set to NULL on restore(). |

### Gender Enforcement Rules

**When `type = 'boys'`:**
- AllotmentService checks student.gender against hostel.type before creating allotment
- If student.gender != 'male' AND `gender_strict_enforce = 1`: allotment is rejected with error "Cannot allot female student to boys hostel."
- If `gender_strict_enforce = 0`: allotment proceeds with a warning flag, but is not blocked. Warning message: "Warning: Allotting female student to a boys hostel."

**When `type = 'girls'`:**
- Same logic as boys, reversed genders
- If student.gender != 'female' AND `gender_strict_enforce = 1`: "Cannot allot male student to girls hostel."
- If `gender_strict_enforce = 0`: warning only.

**When `type = 'mixed'`:**
- No gender check performed. All genders allowed.
- `gender_strict_enforce` is ignored when type = mixed (no effect even if set to 1).

**When `type` is changed:**
- Cannot change type from 'boys' to 'girls' (or vice versa) if `current_occupancy > 0`. Error: "Cannot change hostel gender type while students are allotted. Vacate all students first."
- Changing to 'mixed' is always allowed, even with active allotments.

### Capacity & Occupancy Synchronization Rules

**`total_capacity` Recalculation (by AllotmentService):**
- Triggered when: bed is created, bed is force-deleted, bed is restored from trash, bed's is_active changes
- Calculation: `SELECT COUNT(*) FROM hst_beds WHERE room_id IN (SELECT id FROM hst_rooms WHERE hostel_id = X) AND is_active = 1 AND deleted_at IS NULL`
- Executed within same DB transaction as the triggering event
- If recalculation fails, the entire transaction is rolled back

**`current_occupancy` Synchronization:**
- Updated synchronously (not queued) on every allotment state change
- Triggered by: allot() → increment by 1; vacate() → decrement by 1; transfer() → decrement old, increment new; bulkVacate() → decrement by count
- Calculation: `SELECT COUNT(*) FROM hst_allotments WHERE bed_id IN (SELECT id FROM hst_beds WHERE room_id IN (SELECT id FROM hst_rooms WHERE hostel_id = X)) AND is_alloted = 1 AND deleted_at IS NULL`
- Must never go below 0. If calculation yields negative, set to 0 and log error: "Occupancy counter desync detected for hostel ID {id}. Forced to 0."
- Denormalized for dashboard performance — always prefer reading this field over counting allotments

**`total_floors` Recalculation:**
- Triggered when: floor is created, floor is soft-deleted, floor is restored, floor's is_active changes
- Calculation: `SELECT COUNT(*) FROM hst_floors WHERE hostel_id = X AND deleted_at IS NULL`
- Updated synchronously

**Deactivation Guard:**
- `is_active` cannot be set to 0 if `current_occupancy > 0`
- Check performed in controller before toggleStatus() or before soft delete
- Error response: "Cannot deactivate hostel with active allotments. Vacate all students first."
- This validation is also enforced at the service layer (AllotmentService) to prevent race conditions

### Code Uniqueness Rules

- `code` is optional (nullable). Multiple hostels can have NULL code.
- If code is provided, it must be unique across ALL hostels (including soft-deleted).
- Uniqueness is enforced via DB UNIQUE KEY `uq_hst_hostel_code` on `code` column.
- Since MySQL UNIQUE allows multiple NULL values, multiple hostels with NULL code are permitted.
- Code, when provided, should be short and meaningful (e.g., 'BH1' for Boys Hostel 1, 'GH1' for Girls Hostel 1).
- Code cannot be changed to a value that conflicts with an existing code (including soft-deleted records): "The code has already been taken."
- Code can be changed from a value to NULL without restriction.

### Foreign Key Cascade Rules

**`warden_id` (FK → sys_users.id):**
- ON DELETE SET NULL — if the referenced user is deleted, warden_id becomes NULL automatically at DB level
- No application-level cascading needed
- Before setting warden_id, system validates that the user exists and is active
- Error if user not found: "The selected warden is invalid."

**`principal_warden_id` (FK → sys_users.id):**
- ON DELETE SET NULL — same behavior as warden_id
- Application-level check: principal_warden_id cannot equal warden_id. If they are the same, validation error: "Principal warden must be different from primary warden."
- Both warden_id and principal_warden_id can be NULL simultaneously (hostel with no warden assigned)

### Facilities JSON Structure Rules

- Must be a valid JSON array of strings.
- Each string is a facility name, max 100 characters.
- Maximum 50 facilities per hostel.
- Duplicate facility names are not allowed (case-insensitive comparison). Rejection: "Duplicate facilities are not allowed."
- Standard facility names (suggested values for dropdown selection): WiFi, Hot Water, Generator, Common Room, TV Room, Study Hall, Indoor Games, Gym, Laundry, Canteen, Medical Room, Parking, Security, CCTV, Visitor Waiting Area, Prayer Room, Store Room, Kitchen, Dining Hall, Bathroom, Toilet, Terrace, Garden, Playground.
- Custom facility names beyond the standard list are allowed as free-text entries.
- Invalid JSON: "The facilities format is invalid."
- Empty array [] is allowed (means no facilities).

### Visiting Days JSON Structure Rules

- Must be a valid JSON object with optional keys: `days`, `hours`, `note`.
- `days` key: array of lowercase day names. Allowed values: "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday". Duplicate days rejected. At least one day required if days key is present.
- `hours` key: object with `start` and `end` time strings in 24-hour format "HH:MM". Start must be before end. If start >= end, error: "Visiting hours start must be before end."
- `note` key: optional string, max 200 characters.
- Invalid JSON: "The visiting days format is invalid."
- NULL means no visiting hours configured (defaults to school-wide policy).

### Soft Delete & Restore Rules

**Soft Delete (`DELETE /hostel/hostels/{id}` triggered via controller destroy()):**
1. Pre-delete check: current_occupancy must be 0. If > 0, return error: "Cannot delete hostel with active allotments."
2. Pre-delete action: automatically sets `is_active = 0` (deactivated)
3. The hostel record gets `deleted_at` timestamp set
4. The hostel record remains in the database (soft-deleted)
5. Related floors, rooms, beds are NOT automatically soft-deleted (they remain active)
6. An audit log entry is created: action = "delete", entity_type = "hst_hostels", entity_id = {id}
7. An activity log entry is created: message = "A hostel was deactivated and soft-deleted."
8. After successful deletion, redirect to route('hostel.setup.index', ['#hostels']) with flash message flash('trashed.hostel')

**Restore (`GET /hostel/hostels/{id}/restore`):**
1. Only works on soft-deleted records (uses onlyTrashed() query scope)
2. Sets `deleted_at` to NULL
3. Does NOT automatically set `is_active` back to 1 (remains 0 after restore)
4. An audit log entry is created: action = "restore", entity_type = "hst_hostels", entity_id = {id}
5. After successful restore, redirect to route('hostel.hostels.trashed') with flash message flash('restored.hostel')

**Force Delete (`DELETE /hostel/hostels/{id}/force-delete`):**
1. Only available on already soft-deleted records (uses withTrashed() query scope)
2. Pre-delete check: hostel must have 0 floors, 0 rooms, 0 beds. If any exist, return error: "Cannot delete hostel having floors/rooms/beds."
3. The record is permanently removed from the database
4. An audit log entry is created: action = "delete", entity_type = "hst_hostels", entity_id = {id}
5. After successful force delete, redirect to route('hostel.hostels.trashed') with flash message flash('force_deleted.hostel')

**Trash Page (`GET /hostel/hostels/trash/view`):**
- Lists only soft-deleted records (uses onlyTrashed() scope)
- Paginated 15 per page
- Shows columns: Name, Code, Type, Deleted At, Actions (Restore, Force Delete)
- Restore and Force Delete actions are permission-gated

### is_active Toggle Rules

- Route: `POST /hostel/hostels/{hostel}/toggle-status`
- AJAX endpoint accepting JSON or form data
- Toggles `is_active` between 0 and 1
- Pre-toggle check if toggling from 1→0 (deactivating): must verify current_occupancy = 0. If > 0, return JSON error: `{"success": false, "message": "Cannot deactivate hostel with active allotments."}`
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- An audit log entry is created on toggle
- Works on both active and soft-deleted records

### Audit Trail Rules

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to hst_audit_log
- HostelAuditService::log() is called with: entity_type = "hst_hostels", entity_id = {id}, action = {action_type}
- The global activityLog() helper is also called for each mutation
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values

### List View Rules

- Controller: index() method, Gate: 'tenant.hostel.viewAny'
- Pagination: 15 records per page via `->paginate(15)`
- Eager loads: none needed (simple table)
- Default sort: by name ascending
- Columns displayed: Name, Code, Type (badge), Total Capacity, Current Occupancy, Total Floors, Status (active/inactive badge), Actions (View, Edit, Delete buttons)
- Filter: search by name or code (text input, submitted on enter or button click)
- Filter: status (active/inactive/all) via dropdown, auto-submits on change
- All filters preserved across pagination via `->withQueryString()`
- Actions column is permission-gated (if user cannot 'update', Edit button hidden; if cannot 'delete', Delete button hidden)

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel.viewAny` |
| View details | `tenant.hostel.view` |
| Create | `tenant.hostel.create` / `store` |
| Edit/update | `tenant.hostel.update` |
| Soft delete | `tenant.hostel.delete` |
| View trash & restore | `tenant.hostel.restore` |
| Force delete | `tenant.hostel.forceDelete` |
