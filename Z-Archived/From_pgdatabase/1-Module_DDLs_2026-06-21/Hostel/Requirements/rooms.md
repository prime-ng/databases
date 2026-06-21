# Rooms — Requirements

## What It Does
Manages rooms within a floor. Each room has a room number, type (reference to hst_room_types), capacity, current occupancy, status (via dynamic status master), and optional amenities. Rooms are the parent container for beds.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `floor_id` | BIGINT UNSIGNED FK → hst_floors | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. Denormalized for query ease. |
| `room_number` | VARCHAR(20) | Required. Unique within floor. |
| `block_code` | VARCHAR(10) | Nullable. Block/wing. |
| `room_type` | TINYINT UNSIGNED FK → hst_room_types | Required. |
| `capacity` | TINYINT UNSIGNED | Required. Max beds. |
| `current_occupancy` | TINYINT UNSIGNED | Default 0. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Required. |
| `windows_facing` | ENUM('north','south','east','west','northeast','northwest','southeast','southwest','internal') | Nullable. |
| `amenities_json` | JSON | Nullable. |
| `accessibility_features_json` | JSON | Nullable. |
| `priority_flags_json` | JSON | Nullable. |
| `notes` | VARCHAR(500) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Capacity**
- `capacity` = max beds the room can hold
- `current_occupancy` maintained synchronously
- Room cannot be deactivated if `current_occupancy` > 0

**Room Type**
- References `hst_room_types.id` — determines base capacity and fee structure

**Unique Constraint**
- (`floor_id`, `room_number`) must be unique

## CRUD Operations

**Create** — `GET /hostel/rooms/create` → form with room type, floor, hostel dropdowns | `POST /hostel/rooms` → validates → saves → audit → redirects to `hostel.setup.index` with `#rooms` hash

**List** — `GET /hostel/rooms` → paginated 15 per page | Columns: Room Number, Floor, Hostel, Type, Capacity, Occupancy, Status, Actions

**View** — `GET /hostel/rooms/{id}` → loads with floor, hostel, room type, status

**Edit** — `GET /hostel/rooms/{id}/edit` → pre-filled form | `PUT /hostel/rooms/{id}` → validates → detects changes → audit → redirects with `#rooms`

**Delete (Soft)** — `DELETE /hostel/rooms/{id}` → deactivates → soft deletes → redirects with `#rooms`

**Restore** — `GET /hostel/rooms/{id}/restore` → restores from trash

**Force Delete** — `DELETE /hostel/rooms/{id}/force-delete` → blocked if beds exist

**Toggle Status** — `POST /hostel/rooms/{room}/toggle-status` → AJAX toggles `is_active` → JSON

**Room Inventory** — `GET /hostel/rooms/{room}/inventory` → inventory/index page scoped to room | `POST /hostel/rooms/{room}/inventory` → stores inventory item | `PUT` / `DELETE` for individual items

**Trash Page** — `GET /hostel/rooms/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-room.viewAny` |
| View details | `tenant.hostel-room.view` |
| Create | `tenant.hostel-room.create` |
| Edit/update | `tenant.hostel-room.update` |
| Soft delete | `tenant.hostel-room.delete` |
| View trash & restore | `tenant.hostel-room.restore` |
| Force delete | `tenant.hostel-room.forceDelete` |
