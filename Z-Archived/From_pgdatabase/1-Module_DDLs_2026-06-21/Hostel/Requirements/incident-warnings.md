# Incident Warnings — Requirements

## What It Does
Warning-letter audit trail per incident. Tracks escalating warning levels (verbal → written → final → show cause) with letter content, signer, delivery method, and parent acknowledgment.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `incident_id` | BIGINT UNSIGNED FK → hst_incidents | Required. ON DELETE CASCADE. |
| `student_id` | INT UNSIGNED FK → std_students | Required. Denormalized. |
| `warning_level` | ENUM(verbal, first_written, second_written, final_written, suspension, expulsion) | Required. |
| `letter_template_code` | VARCHAR(50) | Nullable. |
| `letter_subject` | VARCHAR(255) | Required. |
| `letter_body` | TEXT | Required. |
| `letter_media_id` | INT UNSIGNED FK → sys_media | Nullable. PDF output. |
| `signed_by` | INT UNSIGNED FK → sys_users | Required. |
| `signed_at` | TIMESTAMP | Required. |
| `delivered_at` | TIMESTAMP | Nullable. |
| `delivery_method` | ENUM(email, sms, letter, portal, in_person) | Default 'email'. |
| `parent_acknowledged_at` | TIMESTAMP | Nullable. |
| `acknowledgment_method` | ENUM(email_reply, signed_copy, portal_click, phone, none) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Warning Levels**
| Level | Consequence |
|---|---|
| Verbal | Counselling recorded in system |
| First Written | Parent informed |
| Second Written | Parent meeting |
| Final Written | Suspension risk |
| Suspension | Temporary removal from hostel |
| Expulsion | Permanent removal |

- Warning must be linked to at least one incident
- Multiple incidents can be referenced
- Warning letters are printable

## CRUD Operations

**Create** — `POST /hostel/incident-warnings` → creates warning linked to incident

**List** — Tab in Safety & Incidents | Paginated | Columns: Student, Level, Incident, Signed By, Date, Actions

**View** — `GET /hostel/incident-warnings/{id}` → full detail with letter content

**Print** — `GET /hostel/incident-warnings/{id}/print` → PDF output

**Edit** — `GET /hostel/incident-warnings/{id}/edit` | `PUT`

**Delete (Soft)** — `DELETE /hostel/incident-warnings/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-incident-warning.viewAny` |
| Create | `tenant.hostel-incident-warning.create` |
| Edit | `tenant.hostel-incident-warning.update` |
| Delete | `tenant.hostel-incident-warning.delete` |
