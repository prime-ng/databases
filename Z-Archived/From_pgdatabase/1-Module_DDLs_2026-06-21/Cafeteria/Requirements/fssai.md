# FSSAI — Requirements

## Parent Tab: Stock & Compliance

## What It Does
FSSAI license and hygiene audit compliance records. Tracks the school's own FSSAI licenses (Basic/State/Central) and periodic hygiene audit scores with corrective actions.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `record_type` | ENUM('License','Audit') | Required. Discriminator. |
| `license_number` | VARCHAR(50) | Nullable. For License records. |
| `license_type` | ENUM('Basic','State','Central') | Nullable. For License records. |
| `issue_date` | DATE | Nullable. |
| `expiry_date` | DATE | Nullable. Alert 60/30 days before. |
| `licensed_entity_name` | VARCHAR(150) | Nullable. |
| `fssai_document_media_id` | INT UNSIGNED FK → sys_media | Nullable. License document upload. |
| `audit_date` | DATE | Nullable. For Audit records. |
| `auditor_name` | VARCHAR(100) | Nullable. |
| `audit_score` | TINYINT UNSIGNED | Nullable. Score 1–10. |
| `audit_remarks` | TEXT | Nullable. |
| `corrective_actions` | TEXT | Nullable. |
| `next_audit_date` | DATE | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `record_type` | Required, enum: License/Audit | |
| `license_number` | Required if record_type = 'License' | "License number is required for license records." |
| `license_type` | Required if record_type = 'License' | |
| `issue_date` | Required if record_type = 'License' | |
| `expiry_date` | Required if record_type = 'License' | Must be a future date at time of entry. |
| `fssai_document_media_id` | Nullable, exists:sys_media,id | |
| `audit_date` | Required if record_type = 'Audit' | |
| `auditor_name` | Required if record_type = 'Audit' | |
| `audit_score` | Required if record_type = 'Audit', integer, min:1, max:10 | "Audit score must be between 1 and 10." |

### No Soft Delete

- No `deleted_at`. Compliance records — never soft-deleted.
- Superseded records deactivated via `is_active = 0`.

### License vs Audit Discrimination

- `record_type = 'License'`: license fields relevant, audit fields should be NULL.
- `record_type = 'Audit'`: audit fields relevant, license fields should be NULL.
- Cross-populated fields: soft warning (not blocked).

### FSSAI Expiry Alert (BR-CAF-014)

- Two-tier: 60-day warning, 30-day critical + notification.
- More conservative than supplier (60/30 vs 30/7).
- Checked daily by `SendFssaiAlertsCommand` cron.

### Audit Score Classification

- Score 1–10 (validated at application level).
- Score < 5: "Needs Improvement" badge (red).
- Score 5–7: "Satisfactory" badge (yellow).
- Score >= 8: "Compliant" badge (green).

### File Upload

- Via Spatie Media Library (`fssai_document_media_id`).
- Formats: PDF, JPEG, PNG. Max 10 MB.
- Upload failure: "Failed to upload license document. Please try again."

### List View

- Controller: FssaiController@index. Gate: `tenant.cafeteria.fssai-record.viewAny`.
- Columns: Record Type (badge), License Number / Auditor Name, Issue Date / Audit Date, Expiry Date (alert badge), Score (for audits), Status, Actions.
- Two record types shown in same table, differentiated by badge color (blue=License, purple=Audit).

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.fssai-record.*` |
