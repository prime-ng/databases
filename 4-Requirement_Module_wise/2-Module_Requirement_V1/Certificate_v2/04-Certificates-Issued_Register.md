# Issued Certificates Register — Requirement Document

## 1. Screen Purpose & Overview

The **Issued Certificates Register** tab is a tracking dashboard listing all certificates successfully generated and issued by the institution. 

From this interface, administrators and authorized clerks can search for issued documents by certificate number, recipient name, class, or type. It provides secure download controls (using temporary signed URLs) and a revocation workflow to invalidate active certificates in case of errors or policy changes.

---

## 2. Common Business Use Cases

1. **Retrieving Historic Documents**: An alumnus requests a copy of their Bonafide Certificate issued 3 years ago; the registrar searches by their name, locates the record, and downloads the original PDF.
2. **Revoking a Erroneous Issue**: A clerk mistakenly issues a character certificate with spelling errors. The admin revokes the certificate, entering the reason. The public QR page is instantly updated to show a "REVOKED" status.
3. **Tracking Class Issuance**: A class teacher checks how many students in their section have been issued study certificates in the current session.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `crt_issued_certificates`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `certificate_no` | `varchar(50)` | No | N/A | Unique generated certificate number. Unique DB index. |
| `request_id` | `int unsigned` | Yes | `NULL` | Foreign key referencing `crt_requests.id` (SET NULL). NULL for direct issues. |
| `certificate_type_id` | `int unsigned` | No | N/A | Foreign key referencing `crt_certificate_types.id` (RESTRICT). |
| `template_id` | `int unsigned` | No | N/A | Foreign key referencing `crt_templates.id` (RESTRICT). |
| `recipient_type` | `enum` | No | N/A | Options: `'student'`, `'staff'`. |
| `recipient_id` | `int unsigned` | No | N/A | Polymorphic ID. Maps to student ID or user ID based on `recipient_type`. |
| `issue_date` | `date` | No | N/A | Date when the PDF was created. |
| `validity_date` | `date` | Yes | `NULL` | Optional expiration date. `NULL` means open validity. |
| `verification_hash`| `varchar(64)` | No | N/A | Tamper-evident unique hash. Unique DB index. |
| `file_path` | `varchar(500)`| No | N/A | File storage path under the tenant's isolated directory. |
| `is_revoked` | `tinyint(1)` | No | `0` | Flag marking if the certificate is void. |
| `revoked_at` | `timestamp` | Yes | `NULL` | Timestamp of revocation. |
| `revoked_by` | `int unsigned` | Yes | `NULL` | Foreign key referencing `sys_users.id` (SET NULL) who revoked it. |
| `revocation_reason` | `text` | Yes | `NULL` | Textual cause of revocation. |
| `is_duplicate` | `tinyint(1)` | No | `0` | True if another certificate of this type was already issued to recipient. |
| `issued_by` | `int unsigned` | No | N/A | Foreign key referencing `sys_users.id` (RESTRICT) who generated it. |
| Standard audit cols | | | | Includes `deleted_at`. |

**Indexes**:
- Composite index: `idx_crt_ic_recipient (recipient_type, recipient_id)` for quick lookup of a user's certificates.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Search Bar** | Text Input | No | Matches certificate number, recipient name, or code. | None |
| **Type Filter** | Dropdown | No | Choice: Active certificate types. | All Types |
| **Class/Section Filter** | Dropdown | No | Choice: Classes of the school. | All Classes |
| **Date Range** | Date Picker | No | Start Date and End Date. | None |
| **Revocation Reason** | Text Area | Yes (if revoking) | String. Max: 2000 characters. | None |

---

## 5. Business Logic & Validation Policies

1. **Secure Signed Downloads**:
   * PDFs must not be exposed directly via public web URLs. The download button must request a temporary signed URL via Laravel: `URL::temporarySignedRoute('certificate.issued.download', now()->addMinutes(10), ['cert' => $id])`.
2. **Watermarked Duplicates**:
   * Step 6 of generation check: Query if `crt_issued_certificates` has a record with matching `recipient_id` and `certificate_type_id`. If exists, set `is_duplicate = true`. During PDF render, inject CSS to overlay a translucent watermarked text: `"DUPLICATE COPY"`.
3. **Revocation Side Effects**:
   * When `is_revoked` toggles to `1`, the file is preserved in storage for audit reasons, but further downloads are blocked for portal users. The public verification endpoint instantly flags the query as `'REVOKED'`.
4. **Audit Logging**:
   * Logs download, revocation, and view events in `sys_activity_logs`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Admin/Principal.
* Navigate to `/certificate/issued`.

### Scenario A: Search and Download
1. Enter `BON-2026` in the search bar. Click Search.
2. Locate the row for student `Rahul Sharma`.
3. Click the **"Download"** icon.
4. **Expected Result**: 
   * Browser triggers a PDF download.
   * File displays the certificate with the correct details and signature.
   * Database check: `sys_activity_logs` logs action `certificate_download` for the current user and certificate ID.

### Scenario B: Revoking Certificate
1. Locate `Rahul Sharma`'s row in the Issued Register.
2. Click **"Revoke"**.
3. Leaving the text area blank, click **"Confirm Revocation"**.
4. **Expected Result**: Validation stops the submission: *"The revocation reason field is required."*
5. Type reason: `Issued under incorrect category.` Click Confirm.
6. **Expected Result**:
   * Status badge flips to red: `Revoked`.
   * Open the public verification URL `/verify/{hash}` for this certificate.
   * **Expected Result**: Verification page displays a large red warning: `REVOKED`. Minimal student metadata is still visible for audit tracking (BR-CRT-010).

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/issued`
* **Detail/Download Route**: `/certificate/issued/{id}/download`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/issued')
            ->type('search', 'BON-2026')
            ->press('Search')
            ->assertSee('Rahul Sharma')
            ->click('.download-btn') // Download button class
            // Assert file download exists in local downloads directory
            ->assertPathIs('/certificate/issued');
});
```

### 3. Revocation Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/issued')
            ->click('.revoke-action-btn') // Revoke modal trigger
            ->waitForText('Revocation Reason')
            ->type('revocation_reason', 'Spelling error in father name')
            ->press('Confirm Revoke')
            ->assertSee('Revoked successfully')
            ->assertSeeIn('.status-badge', 'Revoked');
});
```
