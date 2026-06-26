# Employee Documents — Requirements

## What It Does
Central repository for all employee-related documents. Supports 9 document types including appointment letters, increment letters, transfer letters, warning letters, experience certificates, ID proofs, educational certificates, medical certificates, and custom types. Uses Spatie Media Library for file storage. Supports expiry date tracking with automated "expiring soon" scoping.

Features:
- 9 pre-defined document types with type-specific metadata
- File upload via Spatie Media Library (PDF, JPG, JPEG, PNG, DOC, DOCX)
- Expiry date tracking with 30-day expiry warning scope
- Soft-delete with restore
- Type filtering on listing

## Database Fields

**hrs_employee_documents**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `document_type` | ENUM | `appointment_letter`, `increment_letter`, `transfer_letter`, `warning_letter`, `experience_certificate`, `id_proof`, `educational_certificate`, `medical_certificate`, `other`. Required. |
| `document_name` | VARCHAR(200) | Required. Display name for the document. |
| `media_id` | BIGINT UNSIGNED FK → `sys_media` | Nullable. Links to Spatie Media Library upload. |
| `issued_date` | DATE | Date the document was issued. |
| `expiry_date` | DATE | Nullable. For time-limited documents (ID proof, medical). |
| `issued_by` | VARCHAR(150) | Name of the issuing authority. |
| `remarks` | VARCHAR(500) | Optional notes. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Document Type Behavior**
- `appointment_letter`: No expiry. Issued on joining.
- `increment_letter`: No expiry. Issued after increment processing.
- `transfer_letter`: No expiry. Issued on department/school transfer.
- `warning_letter`: No expiry. Issued for disciplinary actions.
- `experience_certificate`: No expiry. Issued on separation.
- `id_proof`: Expiry tracked. E.g., passport, Aadhaar, driving license.
- `educational_certificate`: No expiry. Degree certificates, mark sheets.
- `medical_certificate`: Expiry tracked. Fitness certificates, health reports.
- `other`: Catch-all for custom document types.

**File Upload Rules**
- Max file size: 10MB (enforced by FormRequest)
- Allowed MIME types: `pdf`, `jpg`, `jpeg`, `png`, `doc`, `docx`
- File stored via Spatie Media Library to `sys_media` table
- `media_id` is set after successful upload
- Deleting a document also removes the associated media file

**Expiry Date Validation**
- When provided: `expiry_date` must be after `issued_date`
- Documents expiring within 30 days are flagged by `scopeExpiringSoon(30)`
- No automatic notification — expiry warnings are manual via the listing

**Soft Delete Behavior**
- Document is soft-deleted: `deleted_at` is set
- Associated media file remains in storage (orphaned)
- Restore re-activates the document but the media file must still exist
- Force delete (hard delete) also calls the media library deletion

## CRUD Operations

**List Documents**
- Shows all documents for the employee grouped by document_type
- Each document shows: name, type, issued date, expiry (with warning badge if expiring soon), download link
- Filterable by document_type (optional query parameter)

**Upload Document**
- Multi-file upload supported via JavaScript (drag-and-drop or file picker)
- After upload: media_id is linked, sys_media record created, document record created
- Success response: redirect with success flash

**Delete Document**
- Soft-deletes the document record
- Media file is NOT immediately deleted (retained for potential restore)
- On force delete: media file is also removed via Spatie

## Permissions

| Operation | Permission Key |
|---|---|
| View / manage any document | `hrs.documents.manage` |
| View own documents | Always allowed |
| Upload own documents | Always allowed (policy has createOwn) |
| Delete documents | `hrs.documents.manage` |
