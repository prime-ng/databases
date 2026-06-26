# Document Management System (DMS) — Requirement Document

## 1. Screen Purpose & Overview

The **Document Management System (DMS)** screen provides a repository for storing and verifying student-submitted files (such as birth certificates, previous school TCs, caste certificates, Aadhaar cards). 

Administrative clerks and verifiers list uploaded files, view document previews inline, and record approval or rejection states, which directly feed into cross-module eligibility checks for certificate requests.

---

## 2. Common Business Use Cases

1. **Clerk Uploading Birth Certificate**: A clerk receives a physical birth certificate for a newly admitted student, scans it, uploads it to the DMS tab under the student profile, and selects category "DOB Proof."
2. **Reviewing and Approving Aadhaar**: The registrar reviews an Aadhaar card submitted by a student, confirms details match the database, and marks the status as "Verified."
3. **Rejecting a Previous TC Copy**: The administrator rejects an uploaded copy of a previous school's TC because it is blurry, entering remarks: `File is unreadable; please upload a clear scan.`

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `crt_student_documents`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `student_id` | `int unsigned` | No | N/A | Foreign key referencing `std_students.id` (RESTRICT). |
| `document_category_id`| `int unsigned` | No | N/A | Foreign key referencing `sys_dropdown_table.id` (RESTRICT). |
| `document_name` | `varchar(255)`| No | N/A | Human-readable document title. |
| `document_date` | `date` | Yes | `NULL` | Issue date written on the face of the document. |
| `media_id` | `int unsigned` | No | N/A | Foreign key referencing `sys_media.id` (RESTRICT) for physical files. |
| `verification_status` | `enum` | No | `'pending'`| Workflow: `'pending'`, `'verified'`, `'rejected'`. |
| `verification_remarks`| `text` | Yes | `NULL` | Required comments explaining rejections. |
| `verified_by` | `int unsigned` | Yes | `NULL` | Foreign key referencing `sys_users.id` (SET NULL) who verified it. |
| `verified_at` | `timestamp` | Yes | `NULL` | Date verification status changed. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Student** | Dropdown / Search | Yes | References active student ID. | None |
| **Category** | Dropdown | Yes | Reference category row ID in `sys_dropdown_table`. | None |
| **Document Title** | Text Input | Yes | String. Max: 255 characters. | None |
| **Document Issue Date** | Date Picker | No | Date. Must not be a future date. | None |
| **Drag & Drop File** | File Input | Yes | PDF, JPEG, PNG. Max: 5 MB (5120 KB). | None |
| **Verification Status** | Radio group | Yes | Choice: Verified, Rejected. | Pending |
| **Verification Remarks**| Text Area | Yes (if rejecting) | String. Max: 2000 characters. | None |

---

## 5. Business Logic & Validation Policies

1. **MIME & Sizing Restriction**:
   * Validated in `DocumentUploadRequest`: File upload rule `file|mimes:pdf,jpeg,png|max:5120`. Any violation returns: *"The document file must be a PDF, JPEG, or PNG and not exceed 5 megabytes."*
2. **Rejection Remarks Rule (BR-CRT-008)**:
   * Validated in `VerifyDocumentRequest`: If `verification_status = 'rejected'`, `verification_remarks` is mandatory. Failure returns: *"The verification remarks field is required when the document is rejected."*
3. **Block on Eligibility Check**:
   * If a certificate request or system process (e.g. TC generation) requires a verified background document (like a Previous School TC), the check fails if no record in `crt_student_documents` has `verification_status = 'verified'` for that student and category. Records flagged as `'rejected'` or `'pending'` are ignored.
4. **Polymorphic Media Link**:
   * Physical files are saved in `sys_media` where `model_type = 'StudentDocument'`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator/Registrar.
* Navigate to `/certificate/documents`.

### Scenario A: Happy Path Document Upload
1. Search and select student `Aarav Mehta`.
2. Drag and drop file `birth_certificate.pdf` (size 2MB).
3. Select Category: `DOB Proof`.
4. Enter Document Title: `Aarav Birth Certificate`. Click **"Upload Document"**.
5. **Expected Result**: 
   * Page reloads. Toast displays: *"Document uploaded successfully."*
   * Row appears in listing with status `Pending` (yellow badge).

### Scenario B: Document Rejection Validation
1. Click **"View"** on `Aarav Birth Certificate` row.
2. Review the PDF file using the inline browser preview.
3. Click the **"Verify/Reject"** action button.
4. Select Status: **"Rejected"**. Do NOT enter remarks. Click Submit.
5. **Expected Result**: Reject fails, highlighting the remarks field: *"The verification remarks field is required when the document is rejected."*
6. Type remarks: `Name misspelled on document.` Click Submit.
7. **Expected Result**: Row status updates to `Rejected` (red badge).

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/documents`
* **Upload Modal/Form Selector**: `#document-upload-form`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/documents')
            ->select('student_id', '1') // Aarav Mehta
            ->select('document_category_id', '3') // DOB dropdown id
            ->type('document_name', 'Student DOB Certificate')
            ->attach('file', __DIR__.'/files/birth_cert.pdf')
            ->press('Upload Document')
            ->assertPathIs('/certificate/documents')
            ->assertSee('uploaded successfully');
});
```

### 3. File Size Exceeded Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/documents')
            ->select('student_id', '1')
            ->select('document_category_id', '3')
            ->type('document_name', 'Oversized Birth Certificate')
            ->attach('file', __DIR__.'/files/oversized_10mb.pdf') // 10MB file
            ->press('Upload Document')
            ->assertSee('must not exceed 5 megabytes');
});
```
