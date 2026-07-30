# hrs_Documents_TcList

## Module: HrStaff → Employee → Documents

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Employee → Documents |
| Feature | Documents |
| URL(s) | `GET /hr-staff/employees/{employee}/documents` (index) |
| | `POST /hr-staff/employees/{employee}/documents` (store) |
| | `DELETE /hr-staff/documents/{document}` (destroy) |
| Controller | `Modules\HrStaff\Http\Controllers\DocumentController` — `index()` lines 20-34, `store()` lines 39-72, `destroy()` lines 77-93 |
| Model(s) | `Modules\HrStaff\Models\EmployeeDocument` (table: `hrs_employee_documents`) |
| Validation (Create) | `Modules\HrStaff\Http\Requests\StoreDocumentRequest` |
| Policy | `Modules\HrStaff\Policies\DocumentPolicy` |
| Permissions | `hrs.documents.manage` (self-service exception for own records on index/store) |
| Pagination | 20 records per page via standard pagination |
| Soft Deletes | Yes — `SoftDeletes` trait on `EmployeeDocument` |

---

## 2. Pre-conditions

- User must be logged in; employees can upload/view their own documents without `hrs.documents.manage`
- At least one employee record must exist in `sch_employees`
- A test PDF file (<10MB) and a test .exe file should be prepared for upload testing
- Spatie MediaLibrary must be configured and the `hr_documents` media collection must exist on the Employee model
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

`DocumentController::index()` loads the employee via route-model-binding, gates for `hrs.documents.manage` if not own record, then queries active documents ordered by created_at DESC paginated at 20 per page.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Documents Grid | `index()` | `EmployeeDocument::where('employee_id', $id)->active()->orderByDesc('created_at')->paginate(20)` | None | 20/page |

---

## 4. Test Data Strategy

- Create 5-10 `EmployeeDocument` records directly in DB for pagination testing (create 21+ records to test pagination overflow)
- Use Spatie MediaLibrary to add a test media record referenced by `media_id`
- Prepare sample files: valid PDF (1MB), valid JPG (500KB), invalid .exe file, oversized file (>10MB)
- Pre-test cleanup: truncate `hrs_employee_documents` and clear media library test entries

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_employee_documents`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees.id |
| BC-DB-03 | document_type | VARCHAR(50) | NOT NULL (appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, other) |
| BC-DB-04 | document_name | VARCHAR(200) | NOT NULL |
| BC-DB-05 | media_id | INT UNSIGNED | NOT NULL, FK → sys_media.id |
| BC-DB-06 | issued_date | DATE | NULL DEFAULT NULL |
| BC-DB-07 | expiry_date | DATE | NULL DEFAULT NULL |
| BC-DB-08 | issued_by | VARCHAR(150) | NULL DEFAULT NULL |
| BC-DB-09 | remarks | TEXT | NULL DEFAULT NULL |
| BC-DB-10 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-11 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-12 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-13 | created_at | TIMESTAMP | NULL |
| BC-DB-14 | updated_at | TIMESTAMP | NULL |
| BC-DB-15 | deleted_at | TIMESTAMP | NULL |

### 5.2 Validation Rules — StoreDocumentRequest

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | document_type | required, in:appointment_letter,increment_letter,transfer_letter,warning_letter,experience_certificate,id_proof,educational_certificate,medical_certificate,other | The Document Type field is required. / The selected Document Type is invalid. |
| BC-VAL-02 | document_name | required, string, max:200 | The Document Name field is required. / The Document Name must not exceed 200 characters. |
| BC-VAL-03 | document_file | required, file, max:10240, mimes:pdf,jpg,jpeg,png,doc,docx | The Document File field is required. / The Document File must not be greater than 10240 kilobytes. / The Document File must be a file of type: pdf, jpg, jpeg, png, doc, docx. |
| BC-VAL-04 | issued_date | nullable, date, before_or_equal:today | The Issue Date must be a date before or equal to today. |
| BC-VAL-05 | expiry_date | nullable, date, after:issued_date | The Expiry Date must be a date after Issue Date. |
| BC-VAL-06 | issued_by | nullable, string, max:150 | The Issued By must not exceed 150 characters. |
| BC-VAL-07 | remarks | nullable, string, max:500 | The Remarks must not exceed 500 characters. |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.documents.manage` (granted) | User can view, upload, and delete documents for any employee |
| BC-AUTH-02 | Own record (no `hrs.documents.manage`) | User can view and upload documents for themselves; cannot delete |
| BC-AUTH-03 | `hrs.documents.manage` (denied, not own) | Index returns 403; Store returns 403 |
| BC-AUTH-04 | `hrs.documents.manage` (denied) | Destroy returns 403 |
| BC-AUTH-05 | Guest (not logged in) | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Documents index loads | Grid displays active documents for employee, ordered by created_at DESC, paginated at 20 |
| BC-BIZ-02 | Upload valid document file | File stored in `hr_documents` media collection; `EmployeeDocument` record created with media_id, employee_id, created_by, updated_by |
| BC-BIZ-03 | Upload with issued_date set | Date validated as before_or_equal:today |
| BC-BIZ-04 | Upload with expiry_date set | Date validated as after:issued_date |
| BC-BIZ-05 | Delete a document (HR Manager) | Record soft-deleted (is_active=false, deleted_at set); file in media remains |
| BC-BIZ-06 | Employee self-service upload | Gate skipped when uploading to own employee record |
| BC-BIZ-07 | Employee self-service view | Gate skipped when viewing own documents |
| BC-BIZ-08 | Employee tries to delete own document | Gate requires `hrs.documents.manage` — returns 403 |
| BC-BIZ-09 | Empty documents list | Grid displays empty state message |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `hrs_employee_documents.employee_id` | `sch_employees` | RESTRICT |
| BC-REF-02 | `hrs_employee_documents.media_id` | `sys_media` | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load documents index for employee with existing documents | Document list displayed, paginated at 20 per page, newest first | — | — | ⬜ |
| TC-P02 | Load documents index for employee with no documents | Empty state displayed | — | — | ⬜ |
| TC-P03 | Upload a PDF document with all fields | File uploaded to media library; EmployeeDocument record created; redirect with success message | — | — | ⬜ |
| TC-P04 | Upload a JPG document | File uploaded successfully | — | — | ⬜ |
| TC-P05 | Upload a PNG document | File uploaded successfully | — | — | ⬜ |
| TC-P06 | Upload a DOC document | File uploaded successfully | — | — | ⬜ |
| TC-P07 | Upload a DOCX document | File uploaded successfully | — | — | ⬜ |
| TC-P08 | Upload document with issued_date set to today | Validation passes; document created with issued_date = today | — | — | ⬜ |
| TC-P09 | Upload document with both issued_date and expiry_date (expiry after issue) | Validation passes; dates stored correctly | — | — | ⬜ |
| TC-P10 | Employee self-service: upload own document | Gate skipped; document uploaded successfully | — | — | ⬜ |
| TC-P11 | Employee self-service: view own documents list | Gate skipped; documents displayed | — | — | ⬜ |
| TC-P12 | HR Manager deletes a document | Document soft-deleted; is_active=false; redirect with success message | — | — | ⬜ |
| TC-P13 | Pagination: create 21+ documents and navigate to page 2 | Page 1 shows 20 records; page 2 shows remaining records | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Upload without required `document_type` | Validation error: "The Document Type field is required." | — | — | ⬜ |
| TC-N02 | Upload with invalid `document_type` ("unknown") | Validation error: "The selected Document Type is invalid." | — | — | ⬜ |
| TC-N03 | Upload without `document_name` | Validation error: "The Document Name field is required." | — | — | ⬜ |
| TC-N04 | Upload without file (`document_file`) | Validation error: "The Document File field is required." | — | — | ⬜ |
| TC-N05 | Upload with invalid file type (.exe) | Validation error: "The Document File must be a file of type: pdf, jpg, jpeg, png, doc, docx." | — | — | ⬜ |
| TC-N06 | Upload with file larger than 10MB | Validation error: "The Document File must not be greater than 10240 kilobytes." | — | — | ⬜ |
| TC-N07 | Upload with `issued_date` in the future | Validation error: "The Issue Date must be a date before or equal to today." | — | — | ⬜ |
| TC-N08 | Upload with `expiry_date` before `issued_date` | Validation error: "The Expiry Date must be a date after Issue Date." | — | — | ⬜ |
| TC-N09 | Upload with `document_name` exceeding 200 characters | Validation error: "The Document Name must not exceed 200 characters." | — | — | ⬜ |
| TC-N10 | Upload with `remarks` exceeding 500 characters | Validation error: "The Remarks must not exceed 500 characters." | — | — | ⬜ |
| TC-N11 | Delete document without `hrs.documents.manage` permission | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N12 | Employee tries to delete own document (no manage permission) | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N13 | View another employee's documents without `hrs.documents.manage` | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N14 | Upload to another employee without `hrs.documents.manage` | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N15 | Guest user attempts to access documents | Redirect to /login | — | — | ⬜ |
| TC-N16 | Delete non-existent document | 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Activity logged on document upload | `activityLog()` called with type 'Created', message 'Employee document uploaded.', employee_id and document_type in properties | — | — | ⬜ |
| TC-D02 | A | Activity logged on document delete | `activityLog()` called with type 'Trashed', message 'Employee document removed.', employee_id in properties | — | — | ⬜ |
| TC-D03 | B | File stored via Spatie MediaLibrary | File uploaded to `hr_documents` collection on Employee; media_id in EmployeeDocument matches media record | — | — | ⬜ |
| TC-D04 | C | EmployeeDocument SoftDeletes | `delete()` sets `deleted_at`; `is_active` set to false before delete | — | — | ⬜ |
| TC-D05 | D | document_type string values | Must match exactly: appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, other | — | — | ⬜ |
| TC-D06 | E | FK constraint: employee_id → sch_employees.id | Cannot create document with non-existent employee_id | — | — | ⬜ |
| TC-D07 | E | FK constraint: media_id → sys_media.id | Cannot create document with non-existent media_id | — | — | ⬜ |
| TC-D08 | F | Gate `hrs.documents.manage` enforced on destroy | `Gate::authorize('hrs.documents.manage')` called in destroy() | — | — | ⬜ |
| TC-D09 | G | Self-service logic in index() | `auth()->user()?->employee?->id === $employee->id` check gates only for non-own records | — | — | ⬜ |
| TC-D10 | G | Self-service logic in store() (controller) | Same own-record check before gate | — | — | ⬜ |
| TC-D11 | H | `expiringSoon()` scope | Scope filters documents with expiry_date within next 30 days | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns | All writable DDL columns present | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` | `issued_date` => date, `expiry_date` => date, `is_active` => boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` trait | Trait imported; `deleted_at` column in table | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `employee()` BelongsTo; `media()` BelongsTo | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `Gate::authorize()` on every restricted method | `index()` gates if not own; `store()` gates if not own; `destroy()` gates always | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activity logged on all state changes | `activityLog()` called in `store()` and `destroy()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `is_active=false` before soft delete | `destroy()` sets `is_active = false` before `$document->delete()` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — redirect success response | Store redirects with 'success' => 'Document uploaded successfully.'; Destroy redirects with 'success' => 'Document removed successfully.' | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — validation rules cover all fields | `StoreDocumentRequest` has rules for document_type, document_name, document_file, issued_date, expiry_date, issued_by, remarks | — | — | ◌ |
| TC-CR10 | CR | P1 | Policy — `DocumentPolicy` methods defined | viewAny, view, create, update, delete, restore, forceDelete with correct permissions | — | — | ◌ |
| TC-CR11 | CR | P1 | Routes — all routes registered | `hr-staff.documents.index`, `.store`, `.destroy` resolve | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model $fillable matches DDL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `EmployeeDocument.php` $fillable | Contains: employee_id, document_type, document_name, media_id, issued_date, expiry_date, issued_by, remarks, is_active, created_by, updated_by |

#### TC-CR02: Model $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect $casts | `issued_date` => 'date', `expiry_date` => 'date', `is_active` => 'boolean' |

#### TC-CR03: Model SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model imports | `use SoftDeletes;` present |
| 2 | Check DDL `hrs_employee_documents` | `deleted_at` TIMESTAMP NULL column exists |

#### TC-CR04: Model relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model | `employee()` BelongsTo, `media()` BelongsTo defined |

#### TC-CR05: Controller Gate::authorize()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DocumentController.php | `index()` line 25 gates if not own; `store()` line 43 gates if not own; `destroy()` line 79 gates for `hrs.documents.manage` |

#### TC-CR06: Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() line 64 | `activityLog($document, 'Created', ...)` present |
| 2 | Inspect destroy() line 86 | `activityLog($document, 'Trashed', ...)` present |

#### TC-CR07: is_active=false before soft delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() line 83 | `$document->update(['is_active' => false, 'updated_by' => auth()->id()])` before `$document->delete()` |

#### TC-CR08: Success responses
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() line 70-71 | `redirect()->route(..., 'Document uploaded successfully.')` |
| 2 | Inspect destroy() line 91-92 | `redirect()->route(..., 'Document removed successfully.')` |

#### TC-CR09: Request validation rules
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StoreDocumentRequest.php` rules() | All fields have validation rules as per specification |

#### TC-CR10: Policy methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `DocumentPolicy.php` | viewAny, view, create, update, delete, restore, forceDelete defined; create also allows own employee |

#### TC-CR11: Routes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --name=hr-staff.documents` | 3 routes: index (GET), store (POST), destroy (DELETE) |

### 7.1 Positive TC Steps

#### TC-P01: Load documents index with existing documents
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert 3 EmployeeDocument records for employee 5 with different document_types | Records exist |
| 2 | Navigate to GET `/hr-staff/employees/5/documents` | Page loads with 3 documents in grid, sorted newest first |
| 3 | Verify columns | document_name, document_type, issued_date, expiry_date displayed |

#### TC-P02: Load documents index with no documents
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure employee 5 has no documents | 0 records |
| 2 | Navigate to GET `/hr-staff/employees/5/documents` | Page loads with empty state message (no documents) |

#### TC-P03: Upload PDF document with all fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/employees/5/documents` with document_type="appointment_letter", document_name="Appointment Letter", document_file=test.pdf (1MB), issued_date="2025-07-01", expiry_date=null, issued_by="Principal" | Redirect to index with success message "Document uploaded successfully." |
| 2 | Verify DB record | `hrs_employee_documents` has record with employee_id=5, document_type="appointment_letter", media_id != null |
| 3 | Check media library | File stored in `hr_documents` collection for employee 5 |

#### TC-P04: Upload JPG
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_file=photo.jpg (500KB) | Success |

#### TC-P05: Upload PNG
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_file=photo.png | Success |

#### TC-P06: Upload DOC
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_file=doc.doc | Success |

#### TC-P07: Upload DOCX
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_file=doc.docx | Success |

#### TC-P08: Upload with issued_date = today
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with issued_date="2026-07-21" (today) | Success; issued_date saved as today |

#### TC-P09: Upload with issued_date and expiry_date
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with issued_date="2025-01-01", expiry_date="2026-01-01" | Success; both dates saved |

#### TC-P10: Employee self-service upload
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee whose employee_id = 5 (own record) | Authenticated |
| 2 | POST `/hr-staff/employees/5/documents` with valid data | Success — gate skipped |

#### TC-P11: Employee self-service view
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee 5 | Authenticated |
| 2 | GET `/hr-staff/employees/5/documents` | Page loads — gate skipped |

#### TC-P12: HR Manager deletes a document
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `hrs.documents.manage` | Authenticated |
| 2 | DELETE `/hr-staff/documents/1` | Record soft-deleted; redirect with "Document removed successfully." |
| 3 | Verify DB | `is_active` = false, `deleted_at` set |

#### TC-P13: Pagination
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 21 documents for employee 5 | 21 records exist |
| 2 | GET `/hr-staff/employees/5/documents?page=1` | 20 records shown |
| 3 | GET `/hr-staff/employees/5/documents?page=2` | 1 record shown |

### 7.2 Negative TC Steps

#### TC-N01: Missing document_type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without document_type | Validation error: "The Document Type field is required." |

#### TC-N02: Invalid document_type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_type="unknown" | Validation error: "The selected Document Type is invalid." |

#### TC-N03: Missing document_name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without document_name | Validation error: "The Document Name field is required." |

#### TC-N04: Missing file
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without document_file | Validation error: "The Document File field is required." |

#### TC-N05: Invalid file type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_file=malware.exe | Validation error: "The Document File must be a file of type: pdf, jpg, jpeg, png, doc, docx." |

#### TC-N06: Oversized file
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_file=large.pdf (11MB) | Validation error: "The Document File must not be greater than 10240 kilobytes." |

#### TC-N07: Future issued_date
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with issued_date="2099-01-01" | Validation error: "The Issue Date must be a date before or equal to today." |

#### TC-N08: Expiry before issue
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with issued_date="2025-12-31", expiry_date="2025-01-01" | Validation error: "The Expiry Date must be a date after Issue Date." |

#### TC-N09: document_name too long
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with document_name of 201 characters | Validation error: "The Document Name must not exceed 200 characters." |

#### TC-N10: remarks too long
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with remarks of 501 characters | Validation error: "The Remarks must not exceed 500 characters." |

#### TC-N11: Delete without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `hrs.documents.manage` | Authenticated |
| 2 | DELETE `/hr-staff/documents/1` | 403 "This action is unauthorized." |

#### TC-N12: Employee delete own document
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee 5 (own record, no manage permission) | Authenticated |
| 2 | DELETE `/hr-staff/documents/1` (document belongs to employee 5) | 403 "This action is unauthorized." |

#### TC-N13: View another's docs without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee 5, navigate to employee 6's documents GET `/hr-staff/employees/6/documents` | 403 "This action is unauthorized." |

#### TC-N14: Upload to another without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee 5, POST to `/hr-staff/employees/6/documents` | 403 "This action is unauthorized." |

#### TC-N15: Guest access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, GET `/hr-staff/employees/5/documents` | Redirect to /login |

#### TC-N16: Delete non-existent document
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/hr-staff/documents/99999` | 404 |

### 7.3 Dependency TC Steps

#### TC-D01: Activity logged on upload
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload document for employee 5 | Success |
| 2 | Check activity log | Entry: type 'Created', message 'Employee document uploaded.', employee_id=5, document_type |

#### TC-D02: Activity logged on delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete document ID 1 | Success |
| 2 | Check activity log | Entry: type 'Trashed', message 'Employee document removed.', employee_id set |

#### TC-D03: MediaLibrary file storage
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload document PDF | File stored via Spatie MediaLibrary |
| 2 | Query `sys_media` for the media_id | Record exists with correct collection_name = 'hr_documents' |

#### TC-D04: SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a document | `deleted_at` populated; record excluded from normal queries |

#### TC-D05: document_type values
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt direct DB insert with document_type='invalid' | DB error or constraint violation |

#### TC-D06: FK employee_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert with employee_id=99999 | FK violation error |

#### TC-D07: FK media_id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Direct DB insert with media_id=99999 | FK violation error |

#### TC-D08: Gate on destroy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review | `Gate::authorize('hrs.documents.manage')` in destroy() |

#### TC-D09: Self-service logic in index()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review index() | Own-record check `auth()->user()?->employee?->id === $employee->id` before gating |

#### TC-D10: Self-service logic in store()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review store() | Same own-record check before gate |

#### TC-D11: expiringSoon() scope
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review EmployeeDocument model | Scope `expiringSoon(int $days = 30)` filters documents with expiry_date between now and now+30 days |
