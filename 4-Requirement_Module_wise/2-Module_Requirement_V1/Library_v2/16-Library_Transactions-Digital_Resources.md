# Digital Resources — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the management and distribution of digital library assets (e.g., eBooks, audiobooks, PDF guides, and revision sheets). It allows administrators to upload digital files, link them to parent bibliography records (`lib_books_master`), track licensing periods, and define detailed access restriction policies (such as user role filters or IP address whitelists) stored as structured JSON.

---

## 2. Common Business Use Cases
1. **Uploading an eBook PDF:** Creating a digital entry, uploading a 15MB file, generating a license key, and setting availability to start today.
2. **Restricting access to Staff/Teachers:** Restricting a revision guide PDF so that only users with the `Teacher` role can access it.
3. **Auditing Usage Stats:** Inspecting the download and view tallies to monitor content popularities.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_digital_resources`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `book_id` | `bigint` | No | N/A | FK linking to `lib_books_master.id`. Cascades on delete. |
| `file_name` | `varchar(255)` | No | N/A | Human-readable label for the file. |
| `file_media_id` | `bigint` | Yes | `NULL` | FK linking to `media_files.id` (Laravel Media Library reference). |
| `file_path` | `varchar(500)` | No | N/A | Server path / storage URI of the uploaded file. |
| `file_size_bytes` | `bigint` | Yes | `NULL` | File size stored in bytes. Used for bandwidth audits. |
| `mime_type` | `varchar(100)` | Yes | `NULL` | MIME type format (e.g. `application/pdf`, `audio/mpeg`). |
| `file_format` | `varchar(50)` | Yes | `NULL` | Format extension shorthand (e.g. `pdf`, `epub`, `mp3`). |
| `download_count` | `unsigned int` | No | `0` | Cumulative download count. |
| `view_count` | `unsigned int` | No | `0` | Cumulative web viewer/open count. |
| `license_key` | `varchar(100)` | Yes | `NULL` | Subscription or activation license identifier. |
| `license_type` | `varchar(50)` | Yes | `NULL` | Scoping (e.g., *Single-User*, *Multi-User*, *Site-License*). |
| `license_start_date`| `date` | Yes | `NULL` | The date from which the digital resource is valid. |
| `license_end_date`  | `date` | Yes | `NULL` | The expiration date of the resource license. |
| `access_restriction`| `json` | Yes | `NULL` | JSON structure defining constraints: `{"roles": ["Staff"], "max_downloads": 100}`. |
| `is_active` | `boolean` | No | `1` | Visibility and system state toggle. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation date. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification date. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Book Link** | Dropdown / Search | Yes | Must select an active record from `lib_books_master`. | None |
| **Resource Title / File Name**| Text Input | Yes | String. Max 255 characters. | None |
| **File Attachment** | File Input | Yes (New) | PDF, EPUB, MP3, ZIP formats allowed. Max size: 20MB. | None |
| **License Key** | Text Input | No | String. Max 100 characters. Unique. | None |
| **License Type** | Dropdown | No | Options: `Single-User`, `Multi-User`, `Site-License`. | None |
| **License Start Date** | Date Picker | No | Date format. | None |
| **License End Date** | Date Picker | No | Must be after or equal to **License Start Date**. | None |
| **Access Restriction Roles**| Checkbox List | No | Multi-select system roles (e.g., *Student*, *Teacher*, *Staff*). Saves to JSON. | All roles allowed |
| **Active Status** | Checkbox | No | Boolean toggle. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **File Type and Size Enforcement:** Uploaded files must match approved formats: `pdf`, `epub`, `mp3`, `zip`. Files larger than 20,480 KB (20MB) are rejected during validation.
2. **License Validity Period:** If license limits are provided, current date must fall within the range:
   $$\text{License Active} \iff \text{effective\_from} \le \text{today} \le \text{effective\_to}$$
3. **Role Authorization Logic:** When a user requests to view or download a file, the system reads `access_restriction->roles`. If user's role is not included (and JSON is not null), download is blocked:
   $$\text{Access Granted} \iff (\text{access\_restriction} \text{ is NULL}) \lor (\text{UserRole} \in \text{access\_restriction.roles})$$
4. **Soft Delete Preservation:** Soft-deleting a digital resource marks `deleted_at` in the database, making it immediately inaccessible in the UI, but the physical file is preserved in storage until manually cleaned up by systems administrators.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/transactions` and select the **Digital Resources** tab.

### Scenario A: Happy Path eBook Upload
1. Click **"Add Digital Resource"**.
2. Select Parent Book: *Introduction to Algorithms*.
3. Enter Title: *Lecture Slides & PDF Guide*.
4. Browse and select a valid file `guide.pdf` (Size: 2MB).
5. Enter License Key: `LIC-ALGO-2026`.
6. Select License Type: `Site-License`.
7. Select Access Roles: Check `Student` and `Teacher`.
8. Click **"Save"**.
9. **Expected Result**: File uploads, saves successfully, details appear in listing, and downloads/views count start at `0`.

### Scenario B: Upload File Size Validation Failures
1. Click **"Add Digital Resource"**.
2. Select Book: *Introduction to Algorithms*.
3. Enter Title: *Uncompressed Video Lectures*.
4. Select a file `lecture.mov` (Size: 45MB).
5. Click **"Save"**.
6. **Expected Result**: Validation fails instantly with error message:
   * *"The file attachment must be a file of type: pdf, epub, mp3, zip."*
   * *"The file attachment may not be greater than 20480 kilobytes."*

### Scenario C: Role Restriction Enforcement
1. Log in as a Student.
2. Navigate to the catalog and find *Lecture Slides & PDF Guide* (restricted in Scenario A to Teachers only).
3. Try to click **"Download"** or **"View"**.
4. **Expected Result**: Download request is rejected by server, displaying: *"You do not have permission to access this resource."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Digital Resources Tab)
* **Tab Selector**: `@digital-resources-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@digital-resources-tab')
            ->click('@add-digital-btn')
            ->select('book_id', $this->algoBookMaster->id)
            ->type('file_name', 'Dusk Test PDF')
            ->attach('file_attachment', __DIR__.'/files/test.pdf')
            ->type('license_key', 'DUSK-LIC-1122')
            ->press('@save-btn')
            ->assertSee('saved successfully')
            ->assertSee('Dusk Test PDF');
});
```

### 3. File Restriction Block Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->studentUser)
            ->visit('/student/library/digital-resources')
            ->assertDontSee('Teacher-Only Document');
});
```
