# Incident Types — Requirements

## What It Does
Master list of incident types. Replaces the free-text `incident_type` VARCHAR in hst_incidents. Each type has a default severity, auto-escalation rules, and parent notification requirements.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(50) | Required. Unique. |
| `name` | VARCHAR(150) | Required. |
| `description` | VARCHAR(500) | Nullable. |
| `default_severity` | ENUM(Minor, Moderate, Serious) | Default 'Moderate'. |
| `auto_escalate_threshold` | TINYINT UNSIGNED | Nullable. N incidents in 30 days. |
| `requires_warning_letter` | TINYINT(1) | Default 0. |
| `requires_parent_notification` | TINYINT(1) | Default 1. |
| `is_system` | TINYINT(1) | Default 0. Cannot be deleted. |
| `display_order` | TINYINT UNSIGNED | Default 100. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Seeded Types**
| Code | Severity | Warning | Parent Notify |
|---|---|---|---|
| fighting | Moderate | Yes | Yes |
| bullying | Moderate | Yes | Yes |
| theft | Serious | Yes | Yes |
| rule_violation | Minor | No | No |
| property_damage | Moderate | Yes | Yes |
| ragging | Serious | Yes | Yes |
| substance_abuse | Serious | Yes | Yes |
| unauthorized_absence | Minor | No | Yes |
| misconduct | Moderate | Yes | Yes |

- System types (`is_system = 1`) cannot be deleted
- Code must be unique

## CRUD Operations

**Create** — `GET /hostel/incident-types/create` → form | `POST /hostel/incident-types` → validates → saves → redirects

**List** — Tab in Safety & Incidents | Paginated | Columns: Code, Name, Severity, System, Actions

**View** — `GET /hostel/incident-types/{id}` → detail

**Edit** — `GET /hostel/incident-types/{id}/edit` | `PUT`

**Delete (Soft)** — `DELETE /hostel/incident-types/{id}` → system types blocked

**Restore / Force Delete** — Standard

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-incident-type.viewAny` |
| Create | `tenant.hostel-incident-type.create` |
| Edit | `tenant.hostel-incident-type.update` |
| Delete | `tenant.hostel-incident-type.delete` |
