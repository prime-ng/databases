# Email & SMS Communication — Requirements

## What It Does
Bulk email and SMS communication tools for the front office. Features reusable email templates with `{{placeholder}}` substitution, bulk send audit logging, and per-recipient SMS delivery tracking with multi-unit SMS support.

## Database Fields

### fof_email_templates

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(100) | Required. |
| `subject` | VARCHAR(300) | Required. May contain `{{placeholders}}`. |
| `body` | LONGTEXT | Required. HTML with `{{placeholder}}` support. |
| `module` | VARCHAR(50) | Nullable. Source module. |
| `is_active` | BOOLEAN | Default true. |

### fof_communication_logs

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `template_id` | BIGINT UNSIGNED FK → `fof_email_templates` | Nullable. NULL for ad-hoc. |
| `channel` | ENUM('Email','SMS') | Required. |
| `subject` | VARCHAR(300) | Nullable. NULL for SMS. |
| `body` | TEXT | Required. Message body. |
| `recipient_group` | VARCHAR(100) | Required. e.g., 'All_Parents'. |
| `total_recipients` | INT UNSIGNED | Default 0. |
| `sent_count` | INT UNSIGNED | Default 0. |
| `failed_count` | INT UNSIGNED | Default 0. |
| `sent_at` | TIMESTAMP | Nullable. |

### fof_sms_logs

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `communication_log_id` | BIGINT UNSIGNED FK → `fof_communication_logs` | Required. |
| `recipient_user_id` | INT UNSIGNED FK → `sys_users` | Required. |
| `mobile_number` | VARCHAR(15) | Required. |
| `message` | TEXT | Required. |
| `sms_units` | TINYINT UNSIGNED | Default 1. Multi-unit if >160 chars. |
| `status` | ENUM('Queued','Sent','Delivered','Failed') | Default 'Queued'. |
| `sent_at` | TIMESTAMP | Nullable. |
| `delivered_at` | TIMESTAMP | Nullable. |
| `gateway_response` | TEXT | Nullable. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-011 | SMS units calculated as `ceil(strlen(message) / 160)`; max 4 units (640 chars) | Custom validation rule with warning in `SendBulkSmsRequest` |

**Email Template Placeholders**
- `{{student_name}}`, `{{parent_name}}`, `{{class}}`, `{{section}}`, `{{school_name}}`, `{{academic_year}}`, `{{date}}`, `{{circular_number}}`, `{{cert_number}}`
- Placeholders replaced at send time based on recipient context

**Bulk Send Flow**
1. User selects recipient group (All_Parents, Class_5_Parents, All_Staff, etc.)
2. Optionally selects a template (pre-fills subject and body)
3. Preview and confirm
4. System resolves recipient list from the selected group
5. Creates `fof_communication_log` entry
6. Dispatches NTF jobs per recipient (email/SMS via NTF module)
7. Per-recipient delivery tracked in `fof_sms_logs` (for SMS)

**SMS Multi-Unit Handling**
- Messages > 160 characters consume multiple SMS units
- Displayed prominently in compose UI with live counter
- `sms_units` stored per recipient for billing/audit

## CRUD Operations

**Email Compose & Send**
- `POST /front-office/communication/email/send` — validates subject, body, recipient_group; accepts optional template_id
- Template picker pre-fills subject + body

**SMS Compose & Send**
- `POST /front-office/communication/sms/send` — validates message (max 640 chars), recipient_group; shows live unit counter

**Template Management**
- `GET /front-office/communication/email/templates` — list templates
- CRUD for email templates (inline or dedicated pages)

**Logs**
- `GET /front-office/communication/email/logs` — bulk send audit with send/failed counts
- `GET /front-office/communication/sms/logs` — per-recipient delivery status with drill-down

## Permissions

| Operation | Permission Key |
|---|---|
| Send emails | `frontoffice.communication.email` |
| Send SMS | `frontoffice.communication.sms` |
