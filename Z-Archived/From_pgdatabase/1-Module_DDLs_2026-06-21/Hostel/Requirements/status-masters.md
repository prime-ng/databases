# Status Masters (Dynamic Status) — Requirements

## What It Does
Generic master for dynamic status codes across all hostel entity types. Replaces hardcoded ENUMs — statuses are data-driven so new statuses can be added without code changes.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `status_type` | ENUM(Room Status, Bed Status, Repair Status, Room Condition Status, Hostel Allotment Status, Mess Attendance Status, Hostel Complaint Status, Attendance Entry Status, Room Change Request Status, Hostel Leave Approval Status, Bed Maintenance Status, Laundry Ticket Status, Mess Opt-out Request Status, Mess Bill Status, Hostel Fee Status, Room Reservation Status) | Required. |
| `code` | VARCHAR(20) | Required. e.g., 'available', 'occupied'. |
| `name` | VARCHAR(100) | Required. Display name. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Status Types and Their Codes**
| Status Type | Codes |
|---|---|
| Room Status | available, full, maintenance, reserved |
| Bed Status | available, occupied, maintenance, reserved |
| Allotment Status | active, vacated, transferred, waitlisted |
| Attendance Entry | present, absent, leave, home, late, sick_bay |
| Complaint Status | open, in_progress, resolved, escalated, closed |
| Mess Attendance | present, absent, on_leave, opted_out |
| Leave Approval | pending, approved, rejected, returned, cancelled |
| Bed Maintenance | reported, assigned, in_progress, blocked, resolved, closed, cancelled |
| Laundry Ticket | submitted, in_wash, ready, collected, lost, damaged, disputed |
| Room Change Request | pending, approved, rejected |
| Room Reservation | pending, confirmed, expired, converted, cancelled |
| Mess Bill | draft, finalised, disputed, adjusted, settled |
| Mess Opt-out | pending, approved, rejected, active, expired, cancelled |
| Fee Status | draft, pushed, accepted, rejected, revised, settled |

**Unique Constraint**
- (`status_type`, `code`) is unique

## CRUD Operations

**Create** — `GET /hostel/status-masters/create` → form with status_type dropdown | `POST /hostel/status-masters` → validates → saves → redirects with `#status-masters`

**List** — Tab in Hostel Setup | Table columns: Type, Code, Name, Status, Actions | Filtered by status_type

**View** — `GET /hostel/status-masters/{id}` → detail view

**Edit** — `GET /hostel/status-masters/{id}/edit` → pre-filled form | `PUT /hostel/status-masters/{id}` → validates → updates → redirects

**Delete (Soft)** — `DELETE /hostel/status-masters/{id}` → deactivates → soft deletes | System statuses blocked from deletion

**Restore** — `GET /hostel/status-masters/{id}/restore`

**Force Delete** — Only non-system, unreferenced statuses

**Toggle Status** — `POST /hostel/status-masters/{status_master}/toggle-status` → AJAX JSON

**Trash Page** — `GET /hostel/status-masters/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-status-master.viewAny` |
| View details | `tenant.hostel-status-master.view` |
| Create | `tenant.hostel-status-master.create` |
| Edit/update | `tenant.hostel-status-master.update` |
| Soft delete | `tenant.hostel-status-master.delete` |
| View trash & restore | `tenant.hostel-status-master.restore` |
| Force delete | `tenant.hostel-status-master.forceDelete` |
