# Warden Assignments — Requirements

## What It Does
Maps staff members (sys_users) to hostels/floors as wardens with defined scope (chief/block/floor/assistant), effective dates, and assignment history.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `floor_id` | BIGINT UNSIGNED FK → hst_floors | Nullable. NULL = hostel-level. |
| `user_id` | INT UNSIGNED FK → sys_users | Required. |
| `assignment_type` | ENUM(chief, block, floor, assistant) | Required. |
| `effective_from` | DATE | Required. |
| `effective_to` | DATE | Nullable. NULL = ongoing. |
| `remarks` | VARCHAR(300) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Scopes**
- chief = full hostel access
- block = block-level access
- floor = floor-level access (specific floors via `warden.scope` middleware)
- assistant = limited assistant access

**Business Rules**
- A staff member can be assigned to multiple hostels/floors
- Ended assignments are archived (effective_to set)
- `warden.scope` middleware limits data access to assigned floors only

## CRUD Operations

**Create** — `GET /hostel/warden-assignments/create` → form with user, hostel, floor selectors | `POST /hostel/warden-assignments` → validates → saves → redirects to `hostel.setup.index` with `#wardens`

**List** — Tab in Hostel Setup | Columns: Warden Name, Hostel, Floor, Type, Effective Dates, Status, Actions

**View** — `GET /hostel/warden-assignments/{id}` → detail

**Edit** — `GET /hostel/warden-assignments/{id}/edit` | `PUT` → updates

**End Assignment** — `POST /hostel/warden-assignments/{warden}/end` → sets `effective_to` to today → audit

**Delete (Soft)** — `DELETE /hostel/warden-assignments/{id}`

**Restore** — `GET /hostel/warden-assignments/{id}/restore`

**Force Delete** — `DELETE /hostel/warden-assignments/{id}/force-delete`

**Toggle Status** — `POST /hostel/warden-assignments/{warden}/toggle-status` → AJAX JSON

**Trash Page** — `GET /hostel/warden-assignments/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-warden.viewAny` |
| View details | `tenant.hostel-warden.view` |
| Create | `tenant.hostel-warden.create` |
| Edit/update | `tenant.hostel-warden.update` |
| Soft delete | `tenant.hostel-warden.delete` |
| View trash & restore | `tenant.hostel-warden.restore` |
| Force delete | `tenant.hostel-warden.forceDelete` |
