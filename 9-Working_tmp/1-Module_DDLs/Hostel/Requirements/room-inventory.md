# Room Inventory — Requirements

## What It Does
Item-level inventory tracking per room. Records furniture and equipment items (chair, table, fan, AC, cupboard), their condition, damage reports, repair status, and responsible student for chargeable damages.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `room_id` | BIGINT UNSIGNED FK → hst_rooms | Required. |
| `item_name` | VARCHAR(150) | Required. |
| `quantity` | TINYINT UNSIGNED | Default 1. |
| `room_condition` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `last_inspected_at` | DATE | Nullable. |
| `damage_description` | TEXT | Nullable. |
| `estimated_repair_cost` | DECIMAL(10,2) | Nullable. |
| `repair_status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `responsible_student_id` | INT UNSIGNED FK → std_students | Nullable. |
| `charge_pushed_to_fee` | TINYINT(1) | Default 0. |
| `photo_media_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Item Condition**
good → fair → poor (from Room Condition Status type)
Items flagged as damaged can trigger maintenance

**Damage Charging**
- If chargeable, the fee demand is pushed via hst_fee_demands
- `charge_pushed_to_fee = 1` prevents double-charging
- Room-level damage is split equally among occupants

## CRUD Operations

**Create** — `POST /hostel/room-inventory` → validates → saves

**List** — `GET /hostel/room-inventory` → paginated | Tab in Facility Mgmt | Columns: Room, Item, Qty, Condition, Repair Status, Actions | Filtered by room, condition

**View** — `GET /hostel/room-inventory/{id}` → detail

**Edit** — `GET /hostel/room-inventory/{id}/edit` | `PUT`

**Get Students (AJAX)** — `GET /hostel/room-inventory/get-students` → JSON

**Delete (Soft)** — `DELETE /hostel/room-inventory/{id}`

**Toggle Status** — `POST /hostel/room-inventory/{inventory}/toggle-status` → JSON

**Restore / Force Delete** — Standard

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-room-inventory.viewAny` |
| Create | `tenant.hostel-room-inventory.create` |
| Edit | `tenant.hostel-room-inventory.update` |
| Delete | `tenant.hostel-room-inventory.delete` |
