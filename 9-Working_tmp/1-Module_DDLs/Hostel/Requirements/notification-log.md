# Notification Log — Requirements

## What It Does
Records every notification dispatched by the hostel module — parent alerts, student alerts, warden alerts, SLA breaches, escalations, reminders. Tracks delivery status from queued through sent/delivered/read/failed with retry logic.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `entity_type` | VARCHAR(100) | Required. Origin entity (hst_incidents, hst_leave_passes, etc.). |
| `entity_id` | BIGINT UNSIGNED | Required. |
| `notification_type` | ENUM(parent_alert, student_alert, warden_alert, principal_alert, vendor_alert, sla_breach, escalation, reminder, other) | Required. |
| `channel` | ENUM(email, sms, push, whatsapp, portal, phone_call, in_person) | Required. |
| `recipient_user_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `recipient_phone` | VARCHAR(20) | Nullable. |
| `recipient_email` | VARCHAR(150) | Nullable. |
| `recipient_name` | VARCHAR(150) | Nullable. |
| `subject` | VARCHAR(255) | Nullable. |
| `body` | TEXT | Nullable. |
| `template_code` | VARCHAR(50) | Nullable. |
| `status` | ENUM(queued, sent, delivered, read, failed, bounced, retrying) | Default 'queued'. |
| `sent_at` | TIMESTAMP | Nullable. |
| `delivered_at` | TIMESTAMP | Nullable. |
| `read_at` | TIMESTAMP | Nullable. |
| `failure_reason` | VARCHAR(500) | Nullable. |
| `retry_count` | TINYINT UNSIGNED | Default 0. |
| `external_message_id` | VARCHAR(100) | Nullable. Vendor traceability. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Notification Triggers

| Event | Channel | Recipient |
|---|---|---|
| Unexplained absence | SMS/Push | Parent |
| Leave pass approved | SMS/Push | Parent |
| Sick bay admission | SMS/Push | Parent |
| Sick bay discharge | SMS/Push | Parent |
| Incident (moderate/serious) | SMS/Push | Parent |
| Late return from leave | SMS/Push | Parent |
| Overdue movement return | SMS/Push | Parent |
| Complaint resolved | Portal | Student |
| Attendance below threshold | Push | Warden |

## CRUD Operations

**List** — `GET /hostel/notification-log` → paginated table | Tab in Facility Mgmt | Columns: Timestamp, Entity, Type, Channel, Recipient, Status, Actions | Filtered by entity type, channel, status, date range

**View** — `GET /hostel/notification-log/{id}` → full detail with delivery timeline and external message ID

No create, edit, or delete — notification log is system-written, append-only.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-notification-log.viewAny` |
| View details | `tenant.hostel-notification-log.view` |
