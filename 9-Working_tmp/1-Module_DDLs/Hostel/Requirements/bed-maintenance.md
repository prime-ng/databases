# Bed & Room Maintenance — Requirements

## What It Does
Bed/room maintenance ticket lifecycle. Tracks reported issues from reporting through resolution, with severity levels, assignment, cost estimation, bed blocking, and before/after photo documentation.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `bed_id` | BIGINT UNSIGNED FK → hst_beds | Nullable. |
| `room_id` | BIGINT UNSIGNED FK → hst_rooms | Required. Denormalized. |
| `reported_by` | INT UNSIGNED FK → sys_users | Required. |
| `reported_at` | TIMESTAMP | Required. |
| `issue_description` | TEXT | Required. |
| `severity` | ENUM(low, medium, high, urgent) | Default 'medium'. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `assigned_to` | INT UNSIGNED FK → sys_users | Nullable. |
| `assigned_at` | TIMESTAMP | Nullable. |
| `resolution_action` | TEXT | Nullable. |
| `resolved_at` | TIMESTAMP | Nullable. |
| `cost_estimated` | DECIMAL(10,2) | Nullable. |
| `cost_actual` | DECIMAL(10,2) | Nullable. |
| `is_bed_blocked` | TINYINT(1) | Default 0. |
| `before_photo_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `after_photo_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Reported → Assigned → In Progress → Resolved / Cancelled

**Severity Levels**
| Severity | Response SLA | Example |
|---|---|---|
| Low | 7 days | Cosmetic issue |
| Medium | 3 days | Leaking tap |
| High | 24 hours | Broken window |
| Urgent | Immediate | Exposed wiring |

**Bed Blocking**
- If safety risk, bed is blocked from new allotments (`is_bed_blocked = 1`)
- Blocked status remains until maintenance is resolved

## CRUD Operations

**Create** — `GET /hostel/bed-maintenance/create` → form | `POST /hostel/bed-maintenance` → validates → saves → redirects

**List** — `GET /hostel/bed-maintenance` → paginated table | Tab in Facility Mgmt | Columns: Room, Issue, Severity, Status, Assigned To, Actions | Filtered by severity, status

**View** — `GET /hostel/bed-maintenance/{id}` → full detail

**Complete** — `POST /hostel/bed-maintenance/{bedMaintenance}/complete` → sets resolution, resolved_at, cost_actual → redirects

**Edit** — `GET /hostel/bed-maintenance/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/bed-maintenance/{id}`

**Restore** — `GET /hostel/bed-maintenance/{id}/restore`

**Force Delete** — `DELETE /hostel/bed-maintenance/{id}/force-delete`

**Trash Page** — `GET /hostel/bed-maintenance/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-bed-maintenance.viewAny` |
| View details | `tenant.hostel-bed-maintenance.view` |
| Create | `tenant.hostel-bed-maintenance.create` |
| Edit/update | `tenant.hostel-bed-maintenance.update` |
| Complete | `tenant.hostel-bed-maintenance.complete` |
| Soft delete | `tenant.hostel-bed-maintenance.delete` |
| Restore | `tenant.hostel-bed-maintenance.restore` |
| Force delete | `tenant.hostel-bed-maintenance.forceDelete` |
