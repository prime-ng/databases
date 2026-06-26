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

### Record Type Discrimination

- Every record must be classified as either a "License" or an "Audit" — the type determines which set of fields are applicable.

### License Records

- A license number, license type (Basic, State, or Central), issue date, and expiry date are all required for license records. If the license number is missing, the system shows: *"License number is required for license records."*
- The expiry date must still be in the future at the time of entry.
- A supporting document (PDF, JPEG, or PNG) may optionally be uploaded, up to 10 MB in size.

### Audit Records

- An audit date, auditor name, and audit score are all required for audit records.
- The audit score must be a whole number between 1 and 10. If outside this range, the system shows: *"Audit score must be between 1 and 10."*

### No Deletion of Records

- FSSAI records are never deleted from the database. Instead, old or superseded records are simply marked as inactive.

### License vs. Audit Records

- When the record type is "License", only the license-related fields should be filled in (license number, license type, issue date, expiry date, document). Audit fields should be left empty.
- When the record type is "Audit", only the audit-related fields should be filled in (audit date, auditor name, audit score, remarks, corrective actions, next audit date). License fields should be left empty.
- If someone fills in fields that belong to the other type (for example, entering an audit score on a license record), the system shows a warning but does not prevent saving.

### FSSAI Expiry Alert

- Two alert levels are shown:
  - **60-day warning:** A warning badge appears on the list and detail pages.
  - **30-day critical alert:** A critical badge appears and a notification is sent.
- These alert windows are wider than those for supplier licenses (60/30 days instead of 30/7 days) to allow more time for renewal of the school's own licenses.
- The system checks for expiring licenses automatically every night.

### Audit Score Classification

- Audit scores range from 1 to 10.
- **Score less than 5:** "Needs Improvement" — shown with a red badge.
- **Score 5 to 7:** "Satisfactory" — shown with a yellow badge.
- **Score 8 or above:** "Compliant" — shown with a green badge.

### File Upload

- License documents are uploaded through the system and stored as media files.
- Accepted formats: PDF, JPEG, and PNG.
- Maximum file size: 10 MB.
- If the upload fails, the system shows: *"Failed to upload license document. Please try again."*

### List View

- The list shows all FSSAI records (both licenses and audits) in a single table.
- Columns shown: Record Type (with coloured badge), License Number or Auditor Name, Issue Date or Audit Date, Expiry Date (with alert badge), Score (for audits), Status, and Action buttons.
- Record types are shown with different badge colours: **Blue** for License, **Purple** for Audit.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.fssai-record.*` |
