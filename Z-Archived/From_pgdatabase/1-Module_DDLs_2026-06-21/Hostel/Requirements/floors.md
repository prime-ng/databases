# Floors — Requirements

## What It Does
Manages floors within a hostel building. Each floor belongs to one hostel and has a floor number, display name, optional block/wing code, and optional incharge. Floors are the level at which warden scoping occurs.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `floor_number` | TINYINT | Required. 0 = Ground Floor. |
| `display_name` | VARCHAR(100) | Nullable. |
| `block_code` | VARCHAR(10) | Nullable. Block/wing label. |
| `floor_incharge_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED | Nullable. |
| `updated_by` | INT UNSIGNED | Nullable. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Hierarchy**
- Floor belongs to exactly one hostel
- Unique constraint on (`hostel_id`, `floor_number`, `block_code`)
- Floor number 0 = Ground Floor, negative = basement

**Status**
- A floor cannot be deactivated if it has active rooms
- Before soft delete, floor is auto-deactivated

## CRUD Operations

**Create** — `GET /hostel/floors/create` → form | `POST /hostel/floors` → validates → saves → audit → redirects to `hostel.setup.index` with `#floors` hash

**List** — `GET /hostel/floors` → paginated 15 per page | Columns: Hostel, Floor Number, Display Name, Block, Incharge, Status, Actions

**View** — `GET /hostel/floors/{id}` → loads with hostel and incharge relations

**Edit** — `GET /hostel/floors/{id}/edit` → pre-filled form | `PUT /hostel/floors/{id}` → validates → detects changes → audit → redirects with `#floors`

**Delete (Soft)** — `DELETE /hostel/floors/{id}` → sets `is_active = false` → soft deletes → redirects with `#floors`

**Restore** — `GET /hostel/floors/{id}/restore` → restores → redirects to trash page

**Force Delete** — `DELETE /hostel/floors/{id}/force-delete` → blocked if rooms exist

**Toggle Status** — `POST /hostel/floors/{floor}/toggle-status` → AJAX toggles `is_active` → JSON response

**Trash Page** — `GET /hostel/floors/trash/view` → lists soft-deleted records

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-floor.viewAny` |
| View details | `tenant.hostel-floor.view` |
| Create | `tenant.hostel-floor.create` |
| Edit/update | `tenant.hostel-floor.update` |
| Soft delete | `tenant.hostel-floor.delete` |
| View trash & restore | `tenant.hostel-floor.restore` |
| Force delete | `tenant.hostel-floor.forceDelete` |
