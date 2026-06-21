# Room Types — Requirements

## What It Does
Master list of room types (Single, Double, Triple, Dormitory). Referenced by `hst_rooms.room_type`. Allows dynamic room type definitions without code changes.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | TINYINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(20) | Required. Unique. e.g., 'single', 'double'. |
| `name` | VARCHAR(100) | Required. Display name. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Seeded Data**
| Code | Name | Capacity Implied |
|---|---|---|
| single | Single Occupancy | 1 |
| double | Double Occupancy | 2 |
| triple | Triple Occupancy | 3 |
| dormitory | Dormitory (4+ beds) | 4+ |

**Validation**
- Code must be unique
- Cannot delete if referenced by any room

## CRUD Operations

**Create** — `GET /hostel/room-types/create` → form | `POST /hostel/room-types` → validates → saves → redirects to `hostel.setup.index` with `#room-types`

**List** — Displayed as tab in Hostel Setup page | Columns: Code, Name, Status, Actions

**View** — `GET /hostel/room-types/{id}` → detail view

**Edit** — `GET /hostel/room-types/{id}/edit` → pre-filled form | `PUT /hostel/room-types/{id}` → validates → updates → redirects to setup

**Delete (Soft)** — `DELETE /hostel/room-types/{id}` → deactivates → soft deletes → cannot delete if referenced by rooms

**Restore** — `GET /hostel/room-types/{id}/restore`

**Force Delete** — `DELETE /hostel/room-types/{id}/force-delete` → blocked if rooms reference this type

**Toggle Status** — `POST /hostel/room-types/{room_type}/toggle-status` → AJAX toggles `is_active` → JSON

**Trash Page** — `GET /hostel/room-types/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-room-type.viewAny` |
| View details | `tenant.hostel-room-type.view` |
| Create | `tenant.hostel-room-type.create` |
| Edit/update | `tenant.hostel-room-type.update` |
| Soft delete | `tenant.hostel-room-type.delete` |
| View trash & restore | `tenant.hostel-room-type.restore` |
| Force delete | `tenant.hostel-room-type.forceDelete` |
