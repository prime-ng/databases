# Digital Resources — Business Requirements

## What This Screen Does

The Digital Resources screen manages e-books, PDFs, and other digital media files acquired by the library. Each digital resource is linked to a Book Master record (physical or digital title) and stores the actual file with its metadata, license terms, concurrent access limits, and user-type download permissions. The screen also supports tagging for searchability and tracks download and view counters. File uploads are limited to 100 MB and stored in the configured library media storage folder. License types (e.g., Subscription, Perpetual, Demo) define the access model, and the `license_count` field controls how many concurrent users can access the resource simultaneously — NULL means unlimited, a numeric value caps concurrent access.

---

## When This Screen Is Used

- When adding a new e-book or digital document to the library after purchase
- When uploading a PDF, EPUB, or other digital file and associating it with an existing book record
- When setting access rules (which user types can view/download)
- When configuring license terms including validity dates and concurrent access limits
- When updating license keys or renewing expired licenses
- When viewing download and view statistics for any digital resource
- When tagging resources to improve search and discovery in the staff portal

## Default Data Load

The Digital Resources screen opens as a tab pane within the Library Acquisition hub page (`library.acquisitionIndex`). When the `digital-resources` tab is active, the private query helper loads all records with their related book and media eager-loaded, ordered by latest first, and paginated at 15 per page with a unique paginator name (`resources_page`). Filters support search by file name, license key, or book title, plus dropdowns for book, file format, license type, license validity status (has license / within license period), and active status.

---

---

## Key Fields at a Glance

**File and Book Information**
Every digital resource must have a `file_name` (required, max 255 chars) and a `book_id` linking it to an existing Book Master record. The system stores the uploaded file at the `file_path` location, records the `file_size_bytes` (BIGINT UNSIGNED), `mime_type` (e.g., application/pdf), and `file_format` (e.g., PDF, EPUB, MP3). An optional `file_media_id` can reference the `sys_media` table if the file is managed centrally.

**License and Access Control**
The `license_key` is an optional unique identifier for the purchased license. `license_type` describes the licensing model (Subscription, Perpetual, Demo). `license_start_date` and `license_end_date` define the validity window. `license_count` controls concurrent access — when set to a positive integer, only that many members can access the resource simultaneously; when NULL, access is unlimited. Three boolean flags (`can_student_download`, `can_teacher_download`, `can_staff_download`) control download permissions per user type.

**Tracking and Status**
`download_count` and `view_count` are integer counters incremented via dedicated AJAX endpoints. The `status` field is an FK to `lib_library_status_masters.id` referencing `Digital Resource Status` types (Available, License Consumed, License Expired). `is_active` toggles visibility in the staff portal.

---

## Business Rules and Conditions

**File Upload Limits**
The uploaded file must not exceed 102,400 KB (100 MB). On create, the file is required. On update, the file is optional — if not provided, the existing file remains unchanged. When a new file is uploaded during update, the old file is deleted from disk.

**License Key Uniqueness**
The `license_key` field must be unique across all digital resources, excluding the current record on update. The FormRequest enforces this via `Rule::unique('lib_digital_resources', 'license_key')->ignore($id)`.

**Concurrent Access Control**
If `license_count` IS NOT NULL, the number of simultaneous accesses is limited to that value. If `license_count` IS NULL, concurrent access is unlimited. The FormRequest normalizes empty/zero license_count to NULL on input.

**Download Permission by User Type**
Three boolean flags control which user types can download: `can_student_download`, `can_teacher_download`, `can_staff_download`. These are enforced at the time of request approval by the `LibDigitalAccessRequestController`. The controller maps `user.user_type` (student, teacher/faculty, staff/employee) to the corresponding flag.

**Tag Management**
Tags are managed via a separate child table `lib_digital_resource_tags` (not a JSON column). On store and update, tags are provided as a JSON array string and converted to individual `LibDigitalResourceTag` records. On update with no tags provided, all existing tags are deleted. On force delete, tags are explicitly cleaned up before the parent record is removed.

**Soft Delete and File Cleanup**
On soft delete (`destroy()`), the physical file is deleted from disk before the database record is soft-deleted. On force delete, the file is also deleted along with all related tags, then the record is permanently removed.

---

## Workflow Steps

1. Navigate to Library → Acquisition hub and select the Digital Resources tab
2. Click "Add Digital Resource" to open the create form
3. Select a book from the Book Master dropdown (required)
4. Upload the digital file (required on create, max 100 MB)
5. Enter file name, optionally set MIME type and format (auto-detected from upload)
6. Configure license details: key, type, start/end dates, and concurrent access count
7. Set download permissions per user type (student, teacher, staff)
8. Add tags as comma-separated or JSON array for searchability
9. Select the digital resource status from the status master
10. Toggle active/inactive as needed
11. Click Save — system stores the record, associates tags, and logs activity
12. Edit or delete existing resources via the table action buttons
13. Use the trash tab to restore or permanently delete (with file cleanup)

---

## Example Scenario

The library purchases 50 concurrent licenses for a mathematics e-book "Advanced Calculus" from a publisher. The librarian creates a Book Master record for the title, then goes to Digital Resources to upload the PDF file. They set `license_count` to 50, `license_type` to "Concurrent", and set `license_start_date` and `license_end_date` for the one-year validity period. They enable download for teachers and staff but disable student download to comply with the publisher's license terms. After saving, students can view the e-book online but only teachers can download it. When the 51st member tries to access it, the system checks the active transaction count against `license_count` and blocks the access.

---

## Related Screens

- **Book Master (lib-books-master)** — Parent record that every digital resource must reference
- **Digital Resource Tags (lib-digital-resource-tags)** — Child tags for search and categorization
- **Digital Resource Access Restrictions** — Fine-grained access rules based on role/designation/department/user
- **Digital Access Requests** — Member-facing request workflow for accessing digital resources
- **Digital Access Transactions** — Active access sessions with download/view tracking
- **Library Acquisition Hub** — Parent hub containing the Digital Resources tab

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibDigitalResourceController`
**Model:** `Modules\Library\Models\LibDigitalResource` (table: `lib_digital_resources`)
**Request:** `LibDigitalResourceRequest`
**Policy:** None — uses `Gate::authorize()` with string permissions
**Route:** Resource route `Route::resource('lib-digital-resources', LibDigitalResourceController::class)` under module prefix, plus `trashed`, `restore`, `forceDelete`, `toggleStatus`, `incrementDownload`, `incrementView`

Key controller methods:
- `index()` — Redirects to acquisition hub with tab=digital-resources
- `create()` — Returns creation form with authors, books, and media files
- `store(LibDigitalResourceRequest)` — Validates, uploads file to configured storage folder, creates record with file metadata, creates tags from JSON array, logs activity
- `show($id)` — Shows resource details with eager-loaded book and media
- `edit($id)` — Returns edit form with existing data
- `update(LibDigitalResourceRequest, $id)` — Optionally replaces file (deletes old), updates record, syncs tags, logs changes
- `destroy($id)` — Deletes physical file, soft-deletes record, logs activity
- `trashed()` — Lists soft-deleted resources with book eager-loaded, paginated 15
- `restore($id)` — Restores from trash, logs activity
- `forceDelete($id)` — Deletes file, removes tags, force-deletes record, logs activity
- `toggleStatus($id)` — Toggles `is_active` boolean via AJAX, permission: `tenant.lib-digital-resources.update`
- `incrementDownload($id)` — Increments `download_count` via AJAX, permission: `tenant.lib-digital-resources.view`
- `incrementView($id)` — Increments `view_count` via AJAX, permission: `tenant.lib-digital-resources.view`

---

## Who Can Access

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-digital-resources.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-digital-resources.*` | Full CRUD + file management |
| Librarian | `tenant.lib-digital-resources.viewAny`, `.view`, `.create`, `.update` | View, add, edit resources |
| Library Assistant | `tenant.lib-digital-resources.viewAny`, `.view` | Read-only access |

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to the Library Acquisition hub and selects the Digital Resources tab. The system loads a paginated list of all digital resources sorted by most recent. Each row shows the file name, linked book title, file format, license type, validity dates, download/view counts, and status. The user can search by file name, book title, or license key, and filter by format, license type, or active status. To add a new resource, the user clicks "Add Digital Resource" and fills out the form — selecting the parent book, uploading the file (the system validates size and stores it), setting license terms and download permissions. On save, the file is stored, the record is created, and any tags are saved. Edit allows replacing the file or updating metadata. Delete moves the record to trash (with the file deleted). Restore brings it back. Permanent delete removes the file, tags, and record completely.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | book_id | Required, exists:lib_books_master,id | Please select a book. |
| 2 | file_name | Required, string, max:255 | File name is required. |
| 3 | file | Required on POST, file, max:102400 | Please upload a file. / File size cannot exceed 100MB. |
| 4 | file_media_id | Nullable, exists:sys_media,id | Invalid media file. |
| 5 | file_path | Nullable, string, max:500 | Invalid file path. |
| 6 | file_size_bytes | Nullable, integer, min:0 | File size must be a number. / File size cannot be negative. |
| 7 | mime_type | Nullable, string, max:100 | MIME type must not exceed 100 characters. |
| 8 | file_format | Nullable, string, max:50 | File format must not exceed 50 characters. |
| 9 | license_key | Nullable, string, max:100, unique | This license key is already in use. |
| 10 | license_type | Nullable, string, max:50 | License type must not exceed 50 characters. |
| 11 | license_start_date | Nullable, date | Invalid start date. |
| 12 | license_end_date | Nullable, date, after_or_equal:license_start_date | License end date must be after or equal to start date. |
| 13 | license_count | Nullable, integer, min:0 | Invalid license count. |
| 14 | can_student_download | Boolean | Invalid value. |
| 15 | can_teacher_download | Boolean | Invalid value. |
| 16 | can_staff_download | Boolean | Invalid value. |
| 17 | status | Required, exists:lib_library_status_masters,id | Invalid status. |
| 18 | tags | Nullable, json | Invalid tags format. |
| 19 | is_active | Boolean | Invalid value. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| File upload fails | Failed to create/update digital resource: [error message] | 422 (redirect with flash) |
| License key duplicate | This license key is already in use. | 422 |
| Resource not found | No query results for model [LibDigitalResource] | 404 |
| AJAX toggle fails | Failed to update status. | 500 |
| Force delete exception | Failed to permanently delete digital resource: [error message] | 422 (redirect with flash) |

---

## Success Scenarios

**SC-001: Create a new digital resource with file upload**
1. User selects a book, uploads a PDF, enters file name, sets license type to "Perpetual", enables teacher download only, adds tags "textbook" and "mathematics"
2. System validates input, stores file at configured path, creates record with auto-detected mime_type (application/pdf) and file_format (PDF)
3. Tags are created in `lib_digital_resource_tags`
4. Success flash: "Digital resource created successfully."
5. Resource appears in the list with correct metadata

**SC-002: Update digital resource with file replacement**
1. User edits an existing resource, uploads a new EPUB file to replace the old PDF
2. System deletes the old PDF from disk, stores the new EPUB, updates file metadata
3. All existing tags are retained
4. Success flash: "Digital resource updated successfully."

**SC-003: Toggle status via AJAX**
1. User clicks status switch on an active resource
2. AJAX request toggles `is_active` from 1 to 0
3. Response: `{ success: true, status: false }`
4. Table row updates without page reload

---

## Failure Scenarios

**FC-001: File exceeds maximum size**
1. User tries to upload a 150 MB video file
2. FormRequest rejects with "File size cannot exceed 100MB."
3. Form re-displays with validation error

**FC-002: Force delete with active access transactions**
1. User navigates to trash and clicks force-delete on a resource that has dependent transactions
2. Database throws foreign key constraint violation
3. Exception caught by try-catch block
4. Error flash: "Failed to permanently delete digital resource: [DB error]"
5. Resource remains in trash

**FC-003: Duplicate license key**
1. User enters a license_key that already exists in the database
2. FormRequest's unique rule fails with "This license key is already in use."

---

## Field-Level Business Logic (from Lib_Conditions.md Section 4.4)

### file_name — VARCHAR(255) NOT NULL
- **Required:** Yes. Original file name (e.g., "Chapter 1 - Introduction.pdf").
- **Search:** FULLTEXT indexed for fast keyword search.
- **Display:** Shown in listing and detail views.

### file_media_id — BIGINT UNSIGNED DEFAULT NULL
- FK to `sys_media.id`. File stored in system media library.
- **Required:** No. NULL if file is externally hosted (URL-based).
- **FK:** `ON DELETE SET NULL` — if media record is deleted, this becomes NULL (file is not lost).
- **Purpose:** Central media management for file store/retrieve.

### file_path — VARCHAR(500) NOT NULL
- Storage path or URL where file is located.
- **Required:** Yes.
- **Example:** `digital-resources/filename.pdf` or external URL.
- **Storage folder:** Configured via `library_media_storage_folder` setting (default: `digital-resources`).

### file_size_bytes — BIGINT UNSIGNED NOT NULL
- File size in bytes. Auto-set at upload time.
- **Display:** Formatted in views as KB/MB/GB (e.g., "2.5 MB").
- **Type:** BIGINT (up to ~9.22 exabytes).

### mime_type — VARCHAR(100) NULL
- MIME type (e.g., `application/pdf`, `audio/mpeg`). Auto-detected at upload.
- **Purpose:** Determines how the file viewer renders/previews the file.

### file_format — VARCHAR(50) NULL
- File format extension (e.g., `PDF`, `EPUB`, `MP3`, `MP4`). Auto-detected.
- **Purpose:** Format-based filtering and display.

### can_student_download — TINYINT(1) NOT NULL DEFAULT 1
- **1 (ON):** Student can see the resource AND download it.
- **0 (OFF):** Resource is hidden from student listings entirely (not just download blocked).
- **Business Rule:** Only applies to users with Student role.
- **Student Portal:** Checked in `StudentLibraryController` — if OFF, resource removed from student listing.

### can_teacher_download — TINYINT(1) NOT NULL DEFAULT 1
- **1 (ON):** Teacher can download.
- **0 (OFF):** Hidden from teacher listing.

### can_staff_download — TINYINT(1) NOT NULL DEFAULT 1
- **1 (ON):** Staff can download.
- **0 (OFF):** Hidden from staff listing.

### download_count — INT UNSIGNED NOT NULL DEFAULT 0
- Total download count. Incremented by +1 on each download.
- **Auto-increment:** Server-side `incrementDownload()` endpoint.
- **Display:** Shown in admin/user card — "X downloads".
- **Usage:** Popularity analysis, trending resource identification.

### view_count — INT UNSIGNED NOT NULL DEFAULT 0
- Total view count (without download). Incremented when file is viewed in browser.
- **Auto-increment:** `incrementView()` called when file opens in browser viewer.
- **Display:** Shown in admin/user card — "X views".

### license_key — VARCHAR(100) NULL
- License identifier/key provided by publisher/vendor.
- **Optional:** Only required for licensed resources.
- **Business Rule:** Tracking field only. Uniqueness enforced at app level (`unique` validation in FormRequest). Actual access control is through `license_count` (concurrent) and access approval system.
- **Display:** Admin-side tracking.

### license_type — VARCHAR(50) NULL
- License model type (e.g., `Single User`, `Concurrent`, `Site License`).
- **Single User:** Only one user can access at a time.
- **Concurrent:** `license_count` number of users can access simultaneously.
- **Site License:** Entire institution gets unlimited access.
- **Display:** Shown in resource detail views.

### license_start_date — DATE NULL
- License validity start date.
- **NULL:** No start restriction — license valid from beginning.
- **Set:** If today's date < start_date → resource hidden (scopeWithinLicense filter).
- **Business Rule:** License period ke bahar resource automatically hidden.

### license_end_date — DATE NULL
- License validity end date.
- **NULL:** License never expires.
- **Set:** If today's date > end_date → resource expired → hidden.
- **Validation:** end_date >= start_date.
- **Index:** Composite index `idx_lib_digitalRes_licensePeriod(start_date, end_date)` for fast expiry queries.

### license_count — SMALLINT UNSIGNED NULL DEFAULT NULL
- Concurrent license count. **NULL means unlimited.**
- **NULL (unlimited):** No limit — any number of users can access simultaneously.
- **Number (e.g., 5):** Maximum 5 concurrent users. 6th gets "Concurrent license limit reached" error.
- **Enforcement Logic:**
  ```
  if (license_count === null) → ALLOW (unlimited)
  count active access transactions for this resource
  if (active_count >= license_count) → BLOCK "Concurrent license limit reached"
  ```
- **Active transaction check:** Count where `status=Active` AND `revoked_at IS NULL` AND (`access_expires_at IS NULL` OR `access_expires_at > NOW()`).
- **Display:** "Unlimited" (NULL) or "X Concurrent" (when set).

### status — SMALLINT UNSIGNED NOT NULL
- FK to `lib_library_status_masters.id`.
- **Required:** Yes. Every resource must have a status master.
- **Possible values (Digital Resource Status):** `Available`, `License_Consumed`, `License_Expired`.
- **FK:** RESTRICT.
- **Business Rule:** Only **"Available"** status resources are shown to students. License_Consumed / License_Expired = hidden from student listing (uses `getIdByCode('Digital Resource Status', 'Available')`).

### is_active — TINYINT(1) NOT NULL DEFAULT 1
- **1 (ON):** Visible in all listings (subject to other checks).
- **0 (OFF):** Hidden from all listings. Retained for audit purposes (not soft-deleted).

---

## 5-Layer Access Control Model

The digital resource access system uses a **multi-layered approach**:

| Layer | Check | Where Enforced |
|-------|-------|----------------|
| **1. License Validity** | Is `license_start_date ≤ today ≤ license_end_date`? | `scopeWithinLicense()` query scope |
| **2. Concurrent Limit** | If `license_count IS NOT NULL`, are active accesses < `license_count`? | Access transaction check in controller/service |
| **3. Download Permission** | Does user's role allow download? (student/teacher/staff) | `can_student_download` / `can_teacher_download` / `can_staff_download` in Student Portal |
| **4. Access Restrictions** | Is the user, their role, designation, or department explicitly allowed? | `lib_digital_resource_access_restrictions` table (4 dimensions — OR logic) |
| **5. Resource Status** | Is the resource status = `Available`? | Controller query filter (`getIdByCode('Digital Resource Status', 'Available')`) |

---

## Concurrent License Flow Algorithm

1. User requests access to a digital resource.
2. System checks `license_count`:
   - If **NULL** → allow access immediately (unlimited).
   - If **N** → count active access transactions for this resource.
3. If `active_count < N` → create a new access transaction → allow access.
4. If `active_count ≥ N` → block with "Concurrent license limit reached" error.
5. When user closes/returns → access transaction is closed (frees a slot).

---

## Student Portal Integration

- **`index()`:** Lists only resources where `is_active=1` AND `status=Available` (via `getIdByCode`) AND `can_student_download=1` AND within license period AND pass access restrictions. Books without any qualifying digital resources are hidden entirely.
- **`downloadResource()`:** Checks `can_student_download` + access restrictions + concurrent `license_count` limit (counts active access transactions). Blocks if `active_count >= license_count`.
- **`viewResource()`:** Same checks as download + concurrent license limit. Increments `view_count`.

---

## Access Flow Diagram (Student Portal View)

```
┌─ Resource visible? ─────────────────────────┐
│                                              │
│  Step 1: is_active = 1?                      │
│    ├─ NO  → HIDDEN                           │
│    └─ YES → Continue                         │
│                                              │
│  Step 2: status = Available?                 │
│    ├─ NO  → HIDDEN (License_Consumed/Expired)│
│    └─ YES → Continue                         │
│                                              │
│  Step 3: License valid?                      │
│    ├─ start_date > today → HIDDEN            │
│    ├─ end_date < today → HIDDEN (expired)    │
│    └─ Pass → Continue                        │
│                                              │
│  Step 4: Role check (student/teacher/staff)  │
│    ├─ can_student_download=0 → HIDDEN        │
│    ├─ can_teacher_download=0  → HIDDEN       │
│    ├─ can_staff_download=0   → HIDDEN        │
│    └─ Allowed → Continue                     │
│                                              │
│  Step 5: License count check                 │
│    ├─ license_count=NULL → ALLOW (unlimited) │
│    ├─ active_count < license_count → ALLOW   │
│    └─ active_count >= license_count → BLOCK  │
│                                              │
└── SHOW RESOURCE ─────────────────────────────┘
```

---

## Publication Status Rules

- Resources with status `Available` are visible to students in the Student Portal.
- Resources with status `License_Consumed` or `License_Expired` are hidden from student listings.
- `can_student_download=0` hides the resource from student listings entirely (not just blocks download).
- `is_active=0` hides from all listings globally.

---

## Indexes

| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_lib_digitalRes_book` | `book_id` | Fast book-based lookups |
| `idx_lib_digitalRes_licensePeriod` | `license_start_date`, `license_end_date` | License expiry/validity queries |
| `idx_lib_digitalRes_active` | `is_active` | Active resource filtering |
| `ft_lib_digitalRes_search` | FULLTEXT(`file_name`) | File name search |

## FK Constraints

| FK | Parent Table | On Delete |
|----|-------------|-----------|
| `fk_lib_digitalRes_bookId` | `lib_books_master(id)` | RESTRICT |
| `fk_lib_digitalRes_fileMediaId` | `sys_media(id)` | SET NULL |
| `fk_lib_digitalRes_status` | `lib_library_status_masters(id)` | RESTRICT |

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_digital_resources | Main digital resource table |
| Table | lib_digital_resource_tags | Child tags with FK to lib_digital_resources.id (CASCADE delete) |
| Table | lib_books_master | Parent book record (FK: book_id) |
| Table | lib_library_status_masters | Status lookup (Digital Resource Status) |
| Table | sys_media | File media reference (optional FK: file_media_id) |
| Table | lib_digital_resource_access_restrictions | Access control rules referencing digital_resource_id |
| Table | lib_digital_access_transactions | Active access sessions referencing digital_resource_id |
| Module | Library Book Master | Parent module |
| Module | Library Acquisition Hub | Parent hub containing the Digital Resources tab |
