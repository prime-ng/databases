# Documents — Business Requirements

## What This Screen Does

The Documents screen manages the employee document repository. It allows HR Managers (and employees for their own records) to upload, view, and soft-delete documents associated with a staff member. Documents include appointment letters, increment letters, transfer letters, warning letters, experience certificates, ID proofs, educational certificates, medical certificates, and other miscellaneous files. Files are stored via Spatie MediaLibrary in the `hr_documents` media collection on the employee model.

## When This Screen Is Used

- When HR uploads a scanned copy of an employee's appointment letter during onboarding
- When an employee submits their educational certificates for verification
- When HR needs to download/view an existing document for audit or reference
- When a document expires or becomes obsolete and needs to be removed
- When HR checks for documents expiring soon (30-day expiry notification window)

## Default Data Load

The screen is loaded by `DocumentController::index()` under the Employee → Documents tab. The route `GET /hr-staff/employees/{employee}/documents` displays all active documents for the employee via `EmployeeDocument::where('employee_id', $employee->id)->active()->orderByDesc('created_at')->paginate(20)`. Pagination uses 20 records per page.

## Key Fields at a Glance

**Document Metadata**
- `document_type` — Categorizes the document: appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, or other
- `document_name` — User-friendly label for the document (e.g., "Appointment Letter — 2025")
- `media_id` — Reference to the actual file stored in the system media library

**Tracking Details**
- `issued_date` — Date the document was issued (must be today or earlier)
- `expiry_date` — Date the document expires (must be after issued_date)
- `issued_by` — Name of the issuing institution or person

## Business Rules and Conditions

**Self-Service Document Upload.** An employee can upload documents for their own profile without requiring the `hrs.documents.manage` permission. The controller checks if the authenticated user's employee ID matches the target employee ID. If matched, no gate check is performed. For any other employee, the `hrs.documents.manage` permission is required.

**HR-Only Delete.** Deleting a document always requires the `hrs.documents.manage` gate — employees cannot delete their own documents.

**File Upload Constraints.** Uploaded files must be of type pdf, jpg, jpeg, png, doc, or docx, with a maximum size of 10 MB (10240 KB).

**Document Type Enum.** The `document_type` field is restricted to a fixed set of nine values: appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, other. No free-text entry.

**Soft Delete.** Documents use soft deletes. On destroy, the record's `is_active` is set to `false` and `delete()` is called (soft delete). The file in sys_media remains unaffected.

**Expiry Tracking.** The model provides an `expiringSoon()` scope that filters documents whose `expiry_date` is within the next N days (default 30). This enables proactive notifications for document renewal.

## Workflow Steps

**Uploading a Document**
1. HR Manager (or employee self-service) navigates to Employee → Documents tab
2. System displays the existing documents list (paginated, newest first)
3. User clicks "Upload Document"
4. User selects document type, enters document name, chooses a file, optionally enters issue/expiry dates and issuing authority
5. System validates the file (type, size) and fields, then uploads
6. The file is stored via the employee's `addMedia()` with the `hr_documents` collection; the media ID is saved to the `EmployeeDocument` record
7. System logs activity and redirects with success message

**Deleting a Document**
1. HR Manager clicks delete on a document row
2. System gates the user for `hrs.documents.manage`
3. System sets `is_active` to false, soft-deletes the record, logs activity
4. Redirects back to the documents tab with success message

## Example Scenario

Mr Verma (HR Manager at Sunshine Academy) uploads the appointment letter for new teacher Mrs Patel. He selects document_type = "appointment_letter", document_name = "Appointment Letter — July 2025", uploads the PDF, enters issued_date = "2025-07-01". The file is stored in media library, a new `EmployeeDocument` record is created linked to the employee. Two months later, Mrs Patel uploads her own educational certificates (she passes the self-service check since it's her own employee record).

## Related Screens

- **Employee Profile (SchoolSetup)** — Parent employee record; Documents is a sub-tab
- **Spatie Media Library (sys_media)** — Physical file storage for all uploaded documents

## Requirements

- `DocumentController` handles requests with methods: `index()` (lines 20–34), `store()` (lines 39–72), `destroy()` (lines 77–93)
- `index()` loads `EmployeeDocument::where('employee_id', $employee->id)->active()->orderByDesc('created_at')->paginate(20)`
- `store()` accepts `StoreDocumentRequest`, handles file upload via `$employee->addMedia($request->file('document_file'))->toMediaCollection('hr_documents')`, saves media_id to the record
- `destroy()` sets `is_active = false`, calls `$document->delete()` (soft delete), logs activity, redirects back to index
- Route names: `hr-staff.documents.index` (GET), `hr-staff.documents.store` (POST), `hr-staff.documents.destroy` (DELETE)
- `index()` gate: if not own record, requires `hrs.documents.manage`; `store()` gate: if not own record, requires `hrs.documents.manage`; `destroy()` gate: always requires `hrs.documents.manage`
- Activity logged on create (type 'Created') with message "Employee document uploaded." and on destroy (type 'Trashed') with message "Employee document removed."
- Policy: `DocumentPolicy` — defines `viewAny`, `view` (own or manage), `create` (manage or has employee), `update`, `delete`, `restore`, `forceDelete`
- `StoreDocumentRequest` authorizes via own-record check or `hrs.documents.manage`; validates `document_type` (required, in enum list), `document_name` (required, max:200), `document_file` (required, file, max:10240, mimes:pdf,jpg,jpeg,png,doc,docx), `issued_date` (nullable, date, before_or_equal:today), `expiry_date` (nullable, date, after:issued_date), `issued_by` (nullable, max:150), `remarks` (nullable, max:500)

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.documents.manage` | `index()` (for others), `store()` (for others), `destroy()` | Required for managing other employees' documents |
| Own record (employee viewing own) | `index()`, `store()` | Employee can upload/view own documents without manage permission |
| `hrs.documents.manage` | `destroy()` | Always required — employees cannot delete their own documents |
| Policy | `DocumentPolicy` | Defines viewAny, view, create, update, delete, restore, forceDelete |

## Logic Flow

**Page Load (`index()`).** Route-model-binding loads Employee. Checks if authenticated user is the employee (self-service). If not, gates for `hrs.documents.manage`. Queries active documents for the employee, ordered by created_at DESC, paginated at 20 per page. Renders the document list view.

**Create (`store()`).** Checks self-service condition; gates if not own record. Validates via `StoreDocumentRequest`. If file uploaded, stores via Spatie MediaLibrary `$employee->addMedia()` in `hr_documents` collection; stores returned `media_id` in validated data. Creates `EmployeeDocument` record with `employee_id`, `created_by`, `updated_by`. Activity logged. Redirect back to index.

**Delete (`destroy()`).** Model-binds `EmployeeDocument`. Gates for `hrs.documents.manage`. Sets `is_active = false`, updates `updated_by`, calls `delete()` (soft delete). Activity logged. Redirect back to index.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `document_type` | `required`, `in:appointment_letter,increment_letter,transfer_letter,warning_letter,experience_certificate,id_proof,educational_certificate,medical_certificate,other` | "The selected Document Type is invalid." |
| `document_name` | `required`, `string`, `max:200` | "The Document Name must not exceed 200 characters." |
| `document_file` | `required`, `file`, `max:10240`, `mimes:pdf,jpg,jpeg,png,doc,docx` | "The Document File must be a file of type: pdf, jpg, jpeg, png, doc, docx." |
| `issued_date` | `nullable`, `date`, `before_or_equal:today` | "The Issue Date must be a date before or equal to today." |
| `expiry_date` | `nullable`, `date`, `after:issued_date` | "The Expiry Date must be a date after Issue Date." |
| `issued_by` | `nullable`, `string`, `max:150` | "The Issued By must not exceed 150 characters." |
| `remarks` | `nullable`, `string`, `max:500` | "The Remarks must not exceed 500 characters." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Required document_type missing | "The Document Type field is required." | Validation rule |
| Invalid file type (e.g., .exe) | "The Document File must be a file of type: pdf, jpg, jpeg, png, doc, docx." | Validation rule |
| File too large (>10MB) | "The Document File must not be greater than 10240 kilobytes." | Validation rule |
| Expiry date before issue date | "The Expiry Date must be a date after Issue Date." | Validation rule |
| Issue date in the future | "The Issue Date must be a date before or equal to today." | Validation rule |
| Success — uploaded | "Document uploaded successfully." | Flash success |
| Success — removed | "Document removed successfully." | Flash success |
| Missing permission | "This action is unauthorized." | 403 (Gate) |

## Success Scenarios

**SC-001 — Upload Document.** HR Manager uploads an appointment letter PDF for employee ID 5. Selects document_type = "appointment_letter", document_name = "Appointment Letter", uploads a 500KB PDF, sets issued_date = "2025-07-01". System stores the file in media library, creates `EmployeeDocument` record, logs activity, redirects with success.

**SC-002 — Self-Service Upload.** Employee ID 5 uploads their own educational certificate. The self-service check passes (own record), system uploads the file, creates the record, redirects with success.

**SC-003 — Delete Document.** HR Manager deletes document ID 10 belonging to employee ID 5. System soft-deletes the record (is_active=false), logs activity "Employee document removed.", redirects back with success message.

## Failure Scenarios

**FC-001 — Invalid File Type.** User uploads an .exe file. Validation fails with "The Document File must be a file of type: pdf, jpg, jpeg, png, doc, docx."

**FC-002 — Unauthorized Delete.** Employee ID 5 tries to delete their own document. Gate check for `hrs.documents.manage` fails (employee does not have this permission). Returns 403 "This action is unauthorized."

**FC-003 — Expiry Before Issue.** User sets issued_date = "2025-07-01" and expiry_date = "2025-06-30". Validation fails with "The Expiry Date must be a date after Issue Date."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `Modules\SchoolSetup\Models\Employee` | FK parent | `hrs_employee_documents.employee_id` → `sch_employees.id`, ON DELETE RESTRICT |
| `Modules\Prime\Models\Media` | FK parent | `hrs_employee_documents.media_id` → `sys_media.id`, ON DELETE RESTRICT |
| Spatie MediaLibrary | Service | File stored via `$employee->addMedia()` with `hr_documents` collection |
| Activity Log | Service | `activityLog()` called on create and delete |

**Table:** `hrs_employee_documents`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto Increment |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| document_type | VARCHAR(50) | NOT NULL (enum values: appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, other) |
| document_name | VARCHAR(200) | NOT NULL |
| media_id | INT UNSIGNED | NOT NULL, FK → sys_media.id |
| issued_date | DATE | NULL DEFAULT NULL |
| expiry_date | DATE | NULL DEFAULT NULL |
| issued_by | VARCHAR(150) | NULL DEFAULT NULL |
| remarks | TEXT | NULL DEFAULT NULL |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
