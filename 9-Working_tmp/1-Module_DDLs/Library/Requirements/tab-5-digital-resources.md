# Library Tab 5: Digital Resources

This tab manages digital assets associated with books — e-books, audiobooks, supplementary PDFs, and other digital media. Each digital resource is linked to a book master record and has its own access tracking and license management.

---

## How It Works

When the librarian opens this tab, they see a list of all digital resources. Each entry shows the linked book title, file name, file format, file size, download count, view count, and license information. The librarian can search by book title, file name, or format.

**Adding a Digital Resource:** The librarian selects a book from the catalog, then uploads a file or enters a file path. They set the file name, select the file from the media manager, and enter metadata: mime type, file format, and license details.

License details include: license type (Perpetual, Subscription, Limited), license start and end dates, and access restrictions (JSON format specifying which member segments, classes, or roles can access the resource).

**Managing Access:** The librarian can set access restrictions per digital resource. For example, a resource might be available only to students in grades 9-12, or only to teachers. Restrictions are stored as JSON and evaluated at access time.

**Tracking Usage:** The system automatically tracks downloads and views. Each time a member accesses a digital resource, the `download_count` or `view_count` increments. Tags can be added to resources for finer categorization.

**License Expiry:** When a license is approaching expiry (within 30 days), the system shows a warning on the dashboard and the digital resources list. Expired licenses prevent new downloads but preserve existing access logs.

---

## Important Business Rules

- A digital resource must be linked to an existing book master record. It cannot exist independently.
- File uploads go through the media manager. Supported formats: PDF, EPUB, MP3, MP4, HTML. Maximum file size: 100 MB per file. Larger files must be hosted externally and linked by URL.
- License types determine behaviour: Perpetual = no expiry, Subscription = expires on license_end_date, Limited = expires after a set number of downloads.
- Access restrictions are evaluated at the time of download/view. If a member does not meet the restrictions, they see "This resource is not available to you."
- When a license expires, the resource remains in the catalog but shows "License Expired" and cannot be downloaded.
- Tags are user-defined and specific to digital resources — they do not overlap with book keywords.
- Usage statistics (downloads, views) can be reset by an administrator only. This is audited.

---

## Database Columns & Behavior

### `lib_digital_resources`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| book_id | BIGINT UNSIGNED | `lib_books_master.id` | No | — | Linked book record |
| file_name | VARCHAR(255) | No | No | — | Display file name |
| file_media_id | BIGINT UNSIGNED | Media manager | Yes | NULL | Media file reference |
| file_path | VARCHAR(500) | No | Yes | NULL | External URL if not uploaded |
| file_size_bytes | BIGINT UNSIGNED | No | Yes | NULL | File size |
| mime_type | VARCHAR(100) | No | Yes | NULL | MIME type |
| file_format | VARCHAR(50) | No | Yes | NULL | Format label |
| download_count | INT UNSIGNED | No | No | 0 | Lifetime download count |
| view_count | INT UNSIGNED | No | No | 0 | Lifetime view count |
| license_key | VARCHAR(255) | No | Yes | NULL | License identifier |
| license_type | ENUM | No | No | 'Perpetual' | Perpetual, Subscription, Limited |
| license_start_date | DATE | No | Yes | NULL | License validity start |
| license_end_date | DATE | No | Yes | NULL | License validity end |
| access_restriction | JSON | No | Yes | NULL | Access control rules |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_digital_resource_tags`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| digital_resource_id | BIGINT UNSIGNED | `lib_digital_resources.id` | No | — | Parent resource |
| tag_name | VARCHAR(100) | No | No | — | Tag text |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |

---

## Deep Analysis

### Business Workflows & State Machines

**Digital Resource Lifecycle:**
```
UPLOAD → ACTIVE → (license expiring) → EXPIRY WARNING → EXPIRED
                      ↓
               DEACTIVATED (manually)
```

**Access Evaluation Flow:**
```
Member requests download → Check is_active → Check license not expired
  → Check access_restriction JSON → If allowed: increment download_count, serve file
  → If denied: show "not available" message
```

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Upload file | Max 100 MB | "File exceeds maximum upload size of 100 MB" |
| File format | Must be in allowed list | "Unsupported file format. Allowed: PDF, EPUB, MP3, MP4, HTML" |
| Link to book | Book must exist and be active | "Selected book is not available" |
| License end date | Must be after start date | "License end date must be after start date" |
| Access restriction | Valid JSON format | "Invalid access restriction format" |

**Edge Cases:**
- If the linked book is deactivated, its digital resources are hidden but not deleted.
- License expiry checks run daily via a scheduled job. Resources expiring within 30 days trigger dashboard warnings.
- If a file is replaced (re-uploaded), the old file is archived and the new one takes its place. Download count does not reset.

### Integration Points

| Module | Table(s) | Purpose |
|--------|----------|---------|
| Book Master | `lib_books_master` | Parent catalog record |
| Media Manager | media files table | File storage and delivery |
| Member | `lib_members` | Access restriction evaluation |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View digital resources | Librarian, Teacher, Admin | `tenant.library.digital.view` |
| Upload resource | Librarian, Admin | `tenant.library.digital.create` |
| Edit resource metadata | Librarian, Admin | `tenant.library.digital.update` |
| Set access restrictions | Admin only | `tenant.library.digital.restrict` |
| Delete resource | Admin only | `tenant.library.digital.delete` |
| Reset usage stats | Admin only | `tenant.library.digital.resetStats` |
| Download resource (staff) | Librarian, Teacher, Admin | `tenant.library.digital.download` |
| Download resource (student) | Student (if access allows) | Via portal permission |
