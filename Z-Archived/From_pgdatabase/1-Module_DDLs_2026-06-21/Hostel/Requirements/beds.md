# Beds — Requirements

## What It Does
Manages individual beds within a room. Each bed has a label, bed type (lower bunk/upper bunk/single), status (available/occupied/maintenance), and condition (good/fair/poor). Beds are the smallest unit of allotment.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `room_id` | BIGINT UNSIGNED FK → hst_rooms | Required. |
| `bed_label` | VARCHAR(20) | Required. Unique within room. |
| `bed_type` | TINYINT UNSIGNED FK → hst_bed_types | Default 1. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Required. |
| `bed_condition` | INT UNSIGNED FK → hst_dynamic_status_masters | Required. |
| `notes` | VARCHAR(255) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`room_id`, `bed_label`) must be unique

**Statuses (from hst_dynamic_status_masters)**
- available, occupied, maintenance, reserved

**Condition Statuses**
- good, fair, poor (from Bed Condition Status type)

**Bunk Beds**
- Lower Bunk and Upper Bunk are separate bed records in the same room
- Each has independent status

## CRUD Operations

**Create** — `GET /hostel/beds/create` → form with room, bed type, status, condition dropdowns | `POST /hostel/beds` → validates → saves → audit → redirects to `hostel.setup.index` with `#beds` hash

**List** — `GET /hostel/beds` → paginated 15 rows | Columns: Bed Label, Room, Floor, Hostel, Type, Status, Condition, Actions

**View** — `GET /hostel/beds/{id}` → loads with room, bed type, status, condition

**Edit** — `GET /hostel/beds/{id}/edit` → pre-filled form | `PUT /hostel/beds/{id}` → validates → detects changes → audit → redirects with `#beds`

**Delete (Soft)** — `DELETE /hostel/beds/{id}` → deactivates → soft deletes → audit → redirects with `#beds`

**Restore** — `GET /hostel/beds/{id}/restore` → restores → redirects to `hostel.beds.trashed`

**Force Delete** — `DELETE /hostel/beds/{id}/force-delete` → only for soft-deleted records

**Toggle Maintenance** — `POST /hostel/beds/{bed}/toggle-maintenance` → validates `status_id` → updates bed status → JSON response

**Toggle Status** — `POST /hostel/beds/{bed}/toggle-status` → AJAX toggles `is_active` → JSON

**Toggle Bed Status** — `POST /hostel/beds/{bed}/toggle-bed-status` → toggles between "available" and "maintenance" dynamic statuses → JSON

**Trash Page** — `GET /hostel/beds/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-bed.viewAny` |
| View details | `tenant.hostel-bed.view` |
| Create | `tenant.hostel-bed.create` |
| Edit/update | `tenant.hostel-bed.update` |
| Soft delete | `tenant.hostel-bed.delete` |
| View trash & restore | `tenant.hostel-bed.restore` |
| Force delete | `tenant.hostel-bed.forceDelete` |
