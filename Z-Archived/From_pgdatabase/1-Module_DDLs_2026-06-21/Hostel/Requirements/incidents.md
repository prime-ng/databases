# Incidents — Requirements

## What It Does
Discipline incident register. Records incidents involving students with severity levels, evidence (media), escalation workflow, parent notification, and warning letter generation.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `incident_date` | DATE | Required. |
| `incident_time` | TIME | Nullable. |
| `incident_type` | VARCHAR(100) | Required. Free-text (back-compat). |
| `incident_type_id` | BIGINT UNSIGNED FK → hst_incident_types | Nullable. Preferred. |
| `description` | TEXT | Required. |
| `severity` | ENUM(minor, moderate, serious) | Required. |
| `action_taken` | TEXT | Nullable. |
| `reported_by` | INT UNSIGNED FK → sys_users | Required. |
| `is_escalated` | TINYINT(1) | Default 0. |
| `escalated_at` | TIMESTAMP | Nullable. |
| `warning_letter_sent` | TINYINT(1) | Default 0. |
| `parent_notified` | TINYINT(1) | Default 0. |
| `is_auto_generated` | TINYINT(1) | Default 0. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

**Child Table: hst_incident_media**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `incident_id` | BIGINT UNSIGNED FK → hst_incidents | Required. ON DELETE CASCADE. |
| `media_id` | INT UNSIGNED FK → sys_media | Required. |
| `media_type` | VARCHAR(50) | Nullable. |

## Business Rules

**Severity Levels**
| Level | Parent Notify |
|---|---|
| Minor | No |
| Moderate | Yes |
| Serious | Yes + immediate call |

**Lifecycle**
Reported → Investigating → Escalated → Resolved / Closed

- Parent notification sent for moderate and serious incidents
- Warning letters generated for repeat or serious offenses
- Escalation is automatic via scheduled job (not manual)

## CRUD Operations

**Create** — `GET /hostel/incidents/create` → form | `POST /hostel/incidents` → validates → saves → redirects

**List** — `GET /hostel/incidents` → paginated | Tab in Safety & Incidents | Columns: Date, Student, Type, Severity, Status, Actions | Filtered by severity, type, date range

**View** — `GET /hostel/incidents/{id}` → full detail with media, warnings

**Escalate** — `POST /hostel/incidents/{incident}/escalate` → sets `is_escalated`, `escalated_at` → redirects

**Notify Parent** — `POST /hostel/incidents/{incident}/notify-parent` → triggers parent notification

**Print Warning Letter** — `GET /hostel/incidents/{incident}/warning-letter` → renders printable warning letter

**Store Media** — `POST /hostel/incidents/{incident}/media` → attaches photo/document

**Destroy Media** — `DELETE /hostel/incidents/{incident}/media/{media}` → removes attachment

**Edit** — `GET /hostel/incidents/{id}/edit` | `PUT`

**Delete (Soft)** — `DELETE /hostel/incidents/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-incident.viewAny` |
| View details | `tenant.hostel-incident.view` |
| Create | `tenant.hostel-incident.create` |
| Edit/update | `tenant.hostel-incident.update` |
| Escalate | `tenant.hostel-incident.escalate` |
| Notify parent | `tenant.hostel-incident.notify` |
| Soft delete | `tenant.hostel-incident.delete` |
| Restore | `tenant.hostel-incident.restore` |
| Force delete | `tenant.hostel-incident.forceDelete` |
