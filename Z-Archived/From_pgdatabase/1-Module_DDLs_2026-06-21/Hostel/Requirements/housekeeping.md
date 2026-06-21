# Housekeeping — Requirements

## What It Does
Daily housekeeping service log per room or common area. Tracks cleaning tasks (daily cleaning, deep cleaning, linen change, pest control, sanitization) with staff assignments, quality ratings, and verification.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `room_id` | BIGINT UNSIGNED FK → hst_rooms | Nullable. NULL = common area. |
| `area_description` | VARCHAR(150) | Nullable. For common areas. |
| `service_date` | DATE | Required. |
| `service_type` | ENUM(daily_cleaning, deep_cleaning, linen_change, pest_control, sanitization, garbage_disposal, other) | Required. |
| `cleaned_by` | VARCHAR(150) | Required. Staff name. |
| `cleaned_by_user_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `verified_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `quality_rating` | TINYINT UNSIGNED | Nullable. 1-5. |
| `issues_found` | TEXT | Nullable. |
| `is_re_cleaning_required` | TINYINT(1) | Default 0. |
| `photo_media_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

- Housekeeping logs per room or common area (corridor, mess, lobby)
- Quality rating 1-5 for supervisory inspection
- Re-cleaning flagged if `is_re_cleaning_required = 1`

## CRUD Operations

**Create** — `POST /hostel/housekeeping` → validates → saves

**List** — `GET /hostel/housekeeping` → paginated | Tab in Facility Mgmt | Columns: Date, Room/Area, Service Type, Cleaned By, Quality, Actions | Filtered by date range, service type

**View** — `GET /hostel/housekeeping/{id}` → detail

**Edit** — `GET /hostel/housekeeping/{id}/edit` | `PUT`

**Delete (Soft)** — `DELETE /hostel/housekeeping/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-housekeeping.viewAny` |
| Create | `tenant.hostel-housekeeping.create` |
| Edit | `tenant.hostel-housekeeping.update` |
| Delete | `tenant.hostel-housekeeping.delete` |
