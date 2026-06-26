# Certificate Requests — Requirement Document

## 1. Screen Purpose & Overview

The **Certificate Requests** screen provides a central interface for managing the workflow of student or parent certificate applications. 

Requests progress through a 6-stage finite state machine (`pending → under_review → approved/rejected → generated → issued`). From here, clerks and administrators track and process submissions, evaluate supporting documents, add remarks, and trigger certificate PDF generation upon approval.

---

## 2. Common Business Use Cases

1. **Submitting a Request**: A parent logs into the Parent Portal and requests a Character Certificate for their child, attaching a scanned copy of an achievement card as justification.
2. **Reviewing and Approving**: An administrative clerk opens a pending Bonafide request, changes its status to "Under Review" while verifying enrollment, and then clicks "Approve," which automatically triggers PDF generation.
3. **Rejecting with Cause**: The Principal rejects a request because the purpose is invalid or details are missing, providing a mandatory explanation which is emailed to the parent.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `crt_requests`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `request_no` | `varchar(30)` | No | N/A | Unique human-readable request identifier. Format: `REQ-YYYY-000001`. |
| `certificate_type_id` | `int unsigned` | No | N/A | Foreign key referencing `crt_certificate_types.id` (ON DELETE RESTRICT). |
| `requester_type` | `enum` | No | N/A | Options: `'student'`, `'parent'`, `'staff'`, `'admin'`. |
| `requester_id` | `int unsigned` | No | N/A | Polymorphic ID. Maps to `sys_users.id` who submitted the request. |
| `beneficiary_student_id`| `int unsigned` | Yes | `NULL` | Foreign key referencing `std_students.id` (RESTRICT). |
| `purpose` | `text` | No | N/A | Stated justification from the applicant. |
| `required_by_date` | `date` | Yes | `NULL` | Target date when the applicant needs the certificate. |
| `supporting_doc_media_id`| `int unsigned` | Yes | `NULL` | Foreign key referencing `sys_media.id` (SET NULL) for file uploads. |
| `status` | `enum` | No | `'pending'`| Workflow state: `'pending'`, `'under_review'`, `'approved'`, `'rejected'`, `'generated'`, `'issued'`. |
| `approved_by` | `int unsigned` | Yes | `NULL` | Foreign key referencing `sys_users.id` (SET NULL) who approved/rejected. |
| `approved_at` | `timestamp` | Yes | `NULL` | Date of approval/rejection. |
| `approval_remarks` | `text` | Yes | `NULL` | Optional comments added by the approver. |
| `rejection_reason` | `text` | Yes | `NULL` | Mandatory reason string provided when request status is set to rejected. |
| Standard audit cols | | | | Includes `deleted_at`. |

**Indexes**:
- Composite index: `idx_crt_req_student_type_status (beneficiary_student_id, certificate_type_id, status)` for duplicate pending checks.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Certificate Type** | Dropdown | Yes | Active certificate type ID. | None |
| **Student** | Dropdown / Search | Yes | Active student ID (for portal users, locked to self or ward). | Self / Ward |
| **Purpose** | Text Area | Yes | String. Max: 1000 characters. | None |
| **Date Needed By** | Date Picker | No | Date. Must be today or a future date. | None |
| **Supporting Document** | File Input | No | File. Allowed: PDF, JPEG, PNG. Max size: 5 MB. | None |
| **Approval Remarks** | Text Area | No | String. Max: 500 characters. Shown only to admin during review. | None |
| **Rejection Reason** | Text Area | Yes (if rejecting) | String. Max: 2000 characters. Required on rejection. | None |

---

## 5. Business Logic & Validation Policies

1. **Auto-Approval Bypass**:
   * When a request is stored: check `crt_certificate_types.requires_approval` for the type. If false, status is immediately updated to `'approved'`, and `CertificateGenerationService::generateFromRequest()` is triggered synchronously in the background.
2. **Duplicate Request Prevention**:
   * Custom Rule: Before saving a request, check if a row exists in `crt_requests` for the same `beneficiary_student_id` and `certificate_type_id` where status is in `('pending', 'under_review', 'approved')`. If exists, fail with: *"A pending or approved request already exists for this certificate type."*
3. **Rejection Constraint**:
   * Validated in `RejectCertificateRequestRequest`: If the action is `/reject`, `rejection_reason` must not be null. Fail validation if empty.
4. **Notifications**:
   * Firing events: `CertificateRequestApproved` or `CertificateRequestRejected` triggers emails/SMS alerts to the requester detailing the change in state.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Parent or Student.
* Navigate to `/portal/certificate/requests/create` (or as clerk at `/certificate/requests/create`).

### Scenario A: Parent Submits Request
1. Select Certificate Type: `Bonafide Certificate`.
2. Select Student: (Ward's name).
3. Enter Purpose: `Passport Application proof`.
4. Upload Supporting Doc: `aadhaar.pdf` (under 5MB).
5. Click **"Submit Request"**.
6. **Expected Result**: 
   * Form redirects to portal list. Alert shows: *"Request submitted successfully."*
   * Request row appears with status `Pending` and request number format `REQ-2026-000001`.

### Scenario B: Clerk Rejects Request
1. Log in as Clerk/Principal. Navigate to `/certificate/requests`.
2. Locate the pending `REQ-2026-000001` and click **"Review"**.
3. Click the **"Reject"** button.
4. Click Submit without writing anything in the rejection text field.
5. **Expected Result**: Rejection fails, highlighting the field with error: *"The rejection reason field is required."*
6. Enter Rejection Reason: `Incorrect document attached.` Click Submit.
7. **Expected Result**: Request status updates to `Rejected` and changes color to red. Rejection email is dispatched.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/requests`
* **Detail/Review Route**: `/certificate/requests/{id}`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->parentUser)
            ->visit('/portal/certificate/requests/create')
            ->select('certificate_type_id', '1') // Bonafide
            ->type('purpose', 'Passport Application')
            ->attach('file', __DIR__.'/files/dummy_doc.pdf')
            ->press('Submit Request')
            ->assertPathIs('/portal/certificate/my-certificates')
            ->assertSee('submitted successfully');
});
```

### 3. Duplicate Blocked Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    // Attempt duplicate submit while another is pending
    $browser->loginAs($this->parentUser)
            ->visit('/portal/certificate/requests/create')
            ->select('certificate_type_id', '1')
            ->type('purpose', 'Another passport application')
            ->press('Submit Request')
            ->assertSee('already exists');
});
```
