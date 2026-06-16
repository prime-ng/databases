# Warden Duty Roster — Requirements

## What It Does
Daily shift-based duty roster for wardens. Tracks who is on duty when, shift types (morning/afternoon/evening/night/full_day/on_call), and emergency cover assignments.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `floor_id` | BIGINT UNSIGNED FK → hst_floors | Nullable. NULL = hostel-wide. |
| `user_id` | INT UNSIGNED FK → sys_users | Required. Warden on duty. |
| `duty_date` | DATE | Required. |
| `shift` | ENUM(morning, afternoon, evening, night, full_day, on_call) | Required. |
| `start_time` | TIME | Nullable. |
| `end_time` | TIME | Nullable. |
| `is_emergency_cover` | TINYINT(1) | Default 0. |
| `replaces_user_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `acknowledged_at` | TIMESTAMP | Nullable. |
| `notes` | VARCHAR(500) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`hostel_id`, `duty_date`, `shift`, `user_id`) — same warden cannot be assigned the same shift twice

**Shift Types**
| Shift | Timing |
|---|---|
| Morning | 6 AM – 2 PM |
| Afternoon | 2 PM – 6 PM |
| Evening | 6 PM – 10 PM |
| Night | 10 PM – 6 AM |
| Full Day | 24 hours |
| On Call | As needed |

**Business Rules**
- Past rosters are read-only
- Emergency cover tracks which warden is being replaced

## CRUD Operations

**Create** — `GET /hostel/warden-duty/create` → form | `POST /hostel/warden-duty` → validates → saves → redirects

**List** — `GET /hostel/warden-duty` → paginated table or calendar view

**View** — `GET /hostel/warden-duty/{id}` → detail

**Edit** — `GET /hostel/warden-duty/{id}/edit` | `PUT` → updates

**Get Wardens** — `GET /hostel/warden-duty/get-wardens` → AJAX returns wardens for a hostel → JSON

**Delete (Soft)** — `DELETE /hostel/warden-duty/{id}`

**Restore / Force Delete** — Standard trash patterns

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-duty-roster.viewAny` |
| View details | `tenant.hostel-duty-roster.view` |
| Create | `tenant.hostel-duty-roster.create` |
| Edit/update | `tenant.hostel-duty-roster.update` |
| Soft delete | `tenant.hostel-duty-roster.delete` |
| Restore | `tenant.hostel-duty-roster.restore` |
| Force delete | `tenant.hostel-duty-roster.forceDelete` |
