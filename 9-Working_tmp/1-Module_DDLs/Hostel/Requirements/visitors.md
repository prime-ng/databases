# Visitor Log (Gate Operations) — Requirements

## What It Does
Hostel visitor register. Tracks every visitor entering the hostel — name, contact, purpose, host student, check-in/out times, ID proof, and photos. Enforces visiting hours and provides security audit trail.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `visitor_name` | VARCHAR(150) | Required. |
| `relationship` | ENUM(parent, guardian, sibling, relative, other) | Required. |
| `visitor_phone` | VARCHAR(20) | Nullable. |
| `id_proof_type` | VARCHAR(50) | Nullable. |
| `id_proof_number_masked` | VARCHAR(30) | Nullable. Last 4 digits only. |
| `visit_date` | DATE | Required. |
| `in_time` | TIME | Required. |
| `out_time` | TIME | Nullable. |
| `purpose` | VARCHAR(300) | Nullable. |
| `allowed_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `is_outside_visiting_hours` | TINYINT(1) | Default 0. |
| `override_reason` | VARCHAR(300) | Nullable. |
| `visitor_photo_media_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `signed_register_media_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

**Child Table: hst_visitor_media**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `visitor_log_id` | BIGINT UNSIGNED FK → hst_visitor_log | Required. ON DELETE CASCADE. |
| `media_id` | INT UNSIGNED FK → sys_media | Required. |
| `media_type` | ENUM(selfie, id_proof_scan, signature, other) | Default 'selfie'. |
| `captured_at` | TIMESTAMP | Nullable. |
| `device_id` | VARCHAR(100) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |

## Business Rules

**Visiting Hours**
- Default: 8 AM – 7 PM (configurable per hostel)
- Visitors outside hours are flagged with `is_outside_visiting_hours` and must have `override_reason`

**Check-Out**
- Visitors still checked in after visiting hours are flagged
- A visitor can have only one active visit at a time

## CRUD Operations

**Create** — `GET /hostel/visitors/create` → form | `POST /hostel/visitors` → validates → saves → redirects

**List** — `GET /hostel/visitors` → paginated table | Tab in Daily Operations | Columns: Visitor Name, Student, In Time, Out Time, Purpose, Actions

**View** — `GET /hostel/visitors/{id}` → full detail with media attachments

**Checkout** — `POST /hostel/visitors/{visitor}/checkout` → sets `out_time` to now → redirects

**Store Media** — `POST /hostel/visitors/{visitor}/media` → attaches photo/scan to visitor record

**Destroy Media** — `DELETE /hostel/visitors/{visitor}/media/{media}` → removes media attachment

**Edit** — `GET /hostel/visitors/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/visitors/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-visitor-log.viewAny` |
| View details | `tenant.hostel-visitor-log.view` |
| Create | `tenant.hostel-visitor-log.create` |
| Edit/update | `tenant.hostel-visitor-log.update` |
| Soft delete | `tenant.hostel-visitor-log.delete` |
| Restore | `tenant.hostel-visitor-log.restore` |
| Force delete | `tenant.hostel-visitor-log.forceDelete` |
| Checkout | `tenant.hostel-visitor-log.checkout` |
