# Bulk Certificate Generation — Requirement Document

## 1. Screen Purpose & Overview

The **Bulk Certificate Generation** tab enables administrators to generate large batches of certificates (such as participation or merit certificates) simultaneously for entire classes, sections, or manually selected groups of students. 

Since rendering hundreds of PDFs is resource-intensive, the screen supports asynchronous processing. Very large runs (>200 certificates) are automatically queued in the background, showing a real-time progress bar and providing a ZIP download link upon completion.

---

## 2. Common Business Use Cases

1. **Annual Merit Certificates**: The school admin selects "Merit Certificate" and Class 9, generating 150 certificates in one command. Since it is below 200, the system processes it synchronously and shows a download button.
2. **Generating Participation Certificates for the School**: The admin generates 600 participation certificates. The system displays a progress bar showing status `Processing (340/600)`, allowing the admin to continue working elsewhere while the job runs in the background.
3. **Handling Batch Errors**: A bulk run fails for 2 students due to missing database fields (e.g. invalid date of birth). The system finishes the other 198 certificates, packages them into a ZIP, and lists the errors for the failed students.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `crt_bulk_jobs`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `certificate_type_id` | `int unsigned` | No | N/A | Foreign key referencing `crt_certificate_types.id` (RESTRICT). |
| `initiated_by` | `int unsigned` | No | N/A | Foreign key referencing `sys_users.id` (RESTRICT) who started it. |
| `filter_json` | `json` | Yes | `NULL` | Stores `{class_id, section_id, student_ids[]}` filter query inputs. |
| `total_count` | `smallint unsigned`| No | `0` | Total number of certificates to be generated. |
| `processed_count` | `smallint unsigned`| No | `0` | Count of successfully generated PDFs. |
| `failed_count` | `smallint unsigned`| No | `0` | Count of failures during processing. |
| `status` | `enum` | No | `'queued'`| Options: `'queued'`, `'processing'`, `'completed'`, `'failed'`. |
| `zip_path` | `varchar(500)`| Yes | `NULL` | Absolute/relative path to the packaged ZIP file. |
| `error_log_json` | `json` | Yes | `NULL` | Array structure: `[{"student_id": 42, "error": "Missing DOB"}]`. |
| `started_at` | `timestamp` | Yes | `NULL` | Job start timestamp. |
| `completed_at` | `timestamp` | Yes | `NULL` | Job completion timestamp. |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Certificate Type** | Dropdown | Yes | Reference active type ID. | None |
| **Target Class** | Dropdown | No | Choice: Active class ID (required if students list is empty). | All Classes |
| **Section** | Dropdown | No | Choice: Active section ID (optional). | All Sections |
| **Specific Students** | Multi-Select | No | Array of active student IDs (required if class selection is empty). | None |

---

## 5. Business Logic & Validation Policies

1. **Queue Threshold Rule (BR-CRT-009)**:
   * During request processing in `BulkGenerationController@generate`: Count the students matching the filter.
   * If total count $\le 200$, run the loop synchronously within the web request, generate the ZIP, and return the file directly.
   * If total count $> 200$, dispatch `BulkGenerateCertificatesJob` to the queue, create a `crt_bulk_jobs` record with status `queued`, and return a redirect to the status interface.
2. **Progress Status Polling**:
   * The status screen triggers an AJAX `GET` request to `/certificate/bulk-generate/{job}/status` every 3 seconds, fetching the counts to update the progress bar: `(processed_count + failed_count) / total_count * 100`.
3. **ZIP Naming Conventions**:
   * The package file must be named: `[CertTypeCode]_[ClassName]_[YYYYMMDD].zip`.
   * Inside the archive, individual certificate PDFs must be named: `[CertificateNo]_[StudentName].pdf`.
4. **Resilient Loop Processing**:
   * A try/catch block inside the loop must capture student-specific exceptions (e.g. database schema errors). If one student fails, increment `failed_count`, log the details in `error_log_json`, and **continue** to the next student record.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/certificate/bulk-generate`.

### Scenario A: Small Batch Synchronous Generation
1. Select Certificate Type: `Merit Certificate` (Code: `ACH`).
2. Select Class: `Grade 5` (contains 30 students).
3. Click **"Generate Certificates"**.
4. **Expected Result**: 
   * Form submits. Screen shows a spinner.
   * After 10 seconds, browser initiates download of `ACH_Grade_5_20260525.zip`.
   * Open the ZIP; verify 30 unique PDFs exist, named like `ACH-2026-000001_Aarav_Mehta.pdf`.

### Scenario B: Large Batch Async Generation
1. Select Certificate Type: `Participation Certificate` (Code: `PAR`).
2. Select Class: `All Classes` (contains 250 students). Click Generate.
3. **Expected Result**:
   * Redirects to the job progress screen `/certificate/bulk-generate/{id}/status`.
   * Progress bar starts at 0% with status `Queued`.
   * The progress bar updates to `Processing` and increments visually.
   * Once it hits 100%, the status updates to `Completed` and displays a download ZIP button.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/bulk-generate`
* **Status Route**: `/certificate/bulk-generate/{id}/status`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/bulk-generate')
            ->select('certificate_type_id', '2') // Merit
            ->select('class_id', '3') // Grade 5
            ->press('Generate Certificates')
            ->assertPathIs('/certificate/bulk-generate') // For synchronous download
            ->assertSee('download started');
});
```

### 3. Queue Dispatch Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    // Select all classes to exceed 200 students
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/bulk-generate')
            ->select('certificate_type_id', '2')
            ->select('class_id', '') // All classes
            ->press('Generate Certificates')
            // Assert redirected to status screen
            ->assertPathContains('/certificate/bulk-generate/')
            ->assertPathContains('/status')
            ->waitForText('Completed', 60) // Wait up to 60s for worker
            ->assertSee('ZIP archive ready');
});
```
