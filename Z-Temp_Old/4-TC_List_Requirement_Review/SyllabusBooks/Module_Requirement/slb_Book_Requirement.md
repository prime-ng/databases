# slb_Book — Business Requirements

## What This Screen Does

The Book Master is the central CRUD feature of the Syllabus Books module. It manages the complete lifecycle of book records — from initial creation with metadata, cover image, and ebook file uploads, to associating authors (with roles), class-subject mappings, book files (multiple format support), and chapters. It provides a rich list view as a tab under `/syllabus-books?tab=book` with 10 search/filter dimensions, inline status toggling, permission-gated actions, pagination, and a trash management view.

Each book record captures extensive metadata including ISBN, title, subtitle, description, edition, publication year, publisher, total pages, language, tags, cover image, ebook PDF, and multiple boolean flags (NCERT, CBSE recommended, downloadable, active). Books are linked to authors via `slb_book_author_jnt`, to class-subject mappings via `slb_book_class_subject_jnt`, and have their own file and chapter sub-features.

---

## When This Screen Is Used

- **New Book Entry** when a new syllabus book needs to be added to the system with full metadata and format files
- **Book Update** when book details, author assignments, class-subject mappings, or files need modification
- **Book Deactivation** when a book should no longer be active while preserving its historical associations
- **Book Cleanup** when a book record needs permanent removal (force delete) — blocked if referenced by chapters or other records
- **Trash Recovery** when a mistakenly deleted book needs restoration
- **Subject Mapping** when associating books with specific class-subject combinations per academic session

## Default Data Load

This screen is accessed via the route prefix `/syllabus-books/books` and is served by `BookController`. The master tab view loads inside the Syllabus Books tabbed layout. The index loads with:
- All active and inactive books ordered by `created_at DESC`
- With loaded relationships: authors, language
- With counts: files, chapters, classSubjects (prescriptions)
- Pagination (10 records per page, `books_page` param)
- 10 filter dimensions: search (title/subtitle/description), ISBN, publisher, author, language, publication year, is_ncert, is_cbse_recommended, is_downloadable, status
- Create form loads: language dropdown (`sys_dropdown_table`), active authors, active classes, active subjects, current academic session, and an AJAX endpoint (`getSubjectsByClass`) for cascading class→subject selection

---

## Key Fields at a Glance

**`title`** (VARCHAR 100, NOT NULL): The book's title. Required, max 100 characters.

**`subtitle`** (VARCHAR 255, NULLABLE): Optional subtitle.

**`isbn`** (VARCHAR 20, UNIQUE, NULLABLE): International Standard Book Number. Unique across all books, optional.

**`edition`** (VARCHAR 50, NULLABLE): Book edition identifier.

**`publication_year`** (YEAR, NULLABLE): Year of publication, validated between 1900 and current year.

**`publisher_name`** (VARCHAR 150, NULLABLE): Publisher name.

**`total_pages`** (UINT, NULLABLE): Total page count, min 1.

**`description`** (VARCHAR 512, NULLABLE): Free-text description.

**`language`** (UINT, NOT NULL): FK to `sys_dropdown_table`. Required.

**`tags`** (JSON, NULLABLE): Comma-separated tags converted to JSON array.

**`cover_image_media_id`** (UINT, NULLABLE): FK to media library. Upload: image, max 2MB, types jpg/jpeg/png/webp.

**`ebook_file`** (via media library): PDF upload, max 50MB.

**`is_ncert`** / **`is_cbse_recommended`** / **`is_downloadable`** / **`is_active`** (BOOLEAN DEFAULT 0/0/0/1): Boolean flags forced via `prepareForValidation`.

**`uuid`** (BINARY 16, UNIQUE): Auto-generated UUID on create.

---

## Business Rules and Conditions

**Transactional Store**
Book creation runs in a database transaction. The book, author pivots, class-subject pivots, cover image, ebook, and book files are all created within the same transaction. If any step fails (e.g., file upload error), the entire operation is rolled back, media is cleaned up, and the user is redirected with an error.

**Author Assignment with Role Validation**
Authors are assigned with a required role: PRIMARY, CO_AUTHOR, EDITOR, or CONTRIBUTOR. Duplicate author_id + role combinations within the same book are rejected with a ValidationException "Duplicate author with same role found."

**Class-Subject Mapping with Session**
Each book can be mapped to multiple class-subject combinations per academic session. The mapping includes `is_primary`, `is_mandatory`, and `is_active` flags. The `is_primary` flag cascades (only one primary per book across all mappings).

**ISBN Uniqueness**
ISBN is unique across all books. On store, a manual check is performed before creation (custom error message). On update, the unique rule ignores the current record.

**File Management**
Books support two types of file attachments:
1. Cover image (single, via `InteractsWithMedia` collection `'image'`)
2. Ebook file (single, via `InteractsWithMedia` collection `'ebook'`)
3. Book files (multiple, via `slb_book_files` table with format, size, edition, and boolean flags)

**Soft Delete with Active Flag**
Destroy sets `is_active = false` and soft-deletes the record. Restore recovers the record. Force delete removes pivots and media before permanent deletion.

**Activity Logging**
Every CRUD operation logs an activity entry: Created, Updated, Trashed, Restored, Deleted (force delete), Toggled (status).

**AJAX Subject Cascade**
The `getSubjectsByClass` endpoint returns active subjects for a selected class, enabling cascading dropdowns in the create/edit form.

---

## Workflow Steps

**Creating a Book**
The user navigates to the Book tab and clicks "Add Book". The create form loads with all metadata fields, dropdowns (language, authors, classes, subjects), dynamic author rows (with role selection), dynamic class-subject rows (with cascade), dynamic book file rows, and file uploads for cover image and ebook.

The user fills in the title (required), language (required), optional fields, selects/creates author assignments, maps class-subject combinations, uploads files, and submits. The entire operation runs in a transaction. On success, the user is redirected to the book list with a success flash.

**Viewing a Book**
The show page displays all book metadata, the cover image (or placeholder), related authors with roles, class-subject mappings, book files with download links, and chapters (if any).

**Editing a Book**
The edit form pre-fills all fields with existing values, loads existing authors with roles, class-subject rows, book files, and shows the current cover image/ebook preview. The user can modify any field, add/remove authors, change class-subject mappings, delete flagged book files, or upload new files. On submit, author pivots and class-subject pivots are deleted and re-inserted. Book files are managed individually (delete flagged, update flags, attach new).

**Deleting a Book**
Soft-deletes the record with `is_active=false`. The book disappears from the active list and appears in the trash view.

**Restoring a Book**
Restores the soft-deleted record. The book reappears in the active list (with `is_active` still false).

**Force Deleting a Book**
Permanently removes the book after cleaning up author pivots, class-subject pivots, ebook media, and book file media. Blocked by FK constraint if referenced by chapters or other records.

---

## Example Scenario

The curriculum coordinator wants to add the NCERT Mathematics textbook for Class 9.

They navigate to the Syllabus Books module, click the Book tab, and click "Add Book". They fill in:
- Title: "Mathematics Textbook for Class IX"
- ISBN: "978-81-7450-634-8"
- Publisher: "NCERT"
- Publication Year: 2023
- Language: "English"
- Tags: "ncert, mathematics, class-9"
- Check "NCERT" and "CBSE Recommended" flags
- Cover image: upload the book cover (JPEG, 500KB)
- Ebook: upload the PDF (15MB)

They add author "R.K. Gupta" as PRIMARY and "S. Sharma" as CO_AUTHOR. They map the book to Class "9", Subject "Mathematics", Academic Session "2025-26", with is_primary=true and is_mandatory=true.

They save. The system creates the book record, attaches the cover and ebook via media library, inserts author pivot rows, inserts the class-subject mapping, and redirects to the book list with a success message.

---

## Related Screens

- **Author Tab** — Authors are managed independently and selected within the book form
- **Chapters** — Chapters are managed as a sub-feature of books
- **Book Files** — Additional format files managed per book
- **Book Trash** — Dedicated view for managing soft-deleted book records
- **Syllabus Books Dashboard** — The main tabbed interface hosting all tabs

---

## Requirements

- The system MUST expose a full RESTful resource controller for books with 13 routes (resource + trash, restore, force delete, toggle status, AJAX subjects endpoint).
- The system MUST route all book endpoints under `/syllabus-books/books`.
- The system MUST wrap all routes with `module:SYLLABUS_BOOKS` middleware.
- The system MUST authorize each action via `Gate::authorize()` with 7 distinct permission gates.
- The system MUST validate input via `BookRequest` with 30+ validation rules covering metadata, booleans, arrays (authors, class_subjects, book_files), and file uploads.
- The system MUST enforce ISBN uniqueness with a manual check on store and a unique rule (ignore self) on update.
- The system MUST reject duplicate author_id + role combinations within the same book.
- The system MUST run store and update operations in database transactions.
- The system MUST support cover image upload (jpg/jpeg/png/webp, max 2MB) and ebook PDF upload (max 50MB) via media library.
- The system MUST support multiple book files per book (max 20, formats: PDF/EPUB/JPG/PNG/DOCX/MOBI/OTHER).
- The system MUST enforce the `is_primary` cascade (only one primary book file per book).
- The system MUST support soft deletes and a full trash lifecycle (restore, force delete).
- The system MUST block force delete when the book is referenced by other records (FK 23000).
- The system MUST support AJAX endpoint for fetching subjects by class ID.
- The system MUST log activity entries for every CRUD operation.
- The system MUST paginate the active book list (10 per page) and trash view (10 per page).
- The system MUST provide 10 filter dimensions on the index view.
- The system MUST display cover images (or a placeholder) in the list and show views.
- The system MUST display action buttons (View, Edit, Delete) permission-gated per row.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | All `tenant.book.*` permissions | Full CRUD + Trash + Toggle |
| Curriculum Coordinator | `tenant.book.viewAny`, `tenant.book.create`, `tenant.book.update`, `tenant.book.view` | Create, Edit, View, Toggle |
| Academic Admin | `tenant.book.viewAny`, `tenant.book.view` | View only |
| Teacher | No explicit permission | No access |
| Guest (unauthenticated) | None | Redirected to `/login` |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user clicks the Book tab. Module check, auth check (tenant.book.viewAny), paginated list loads with 10 filters.
2. The user can search by title/subtitle/description, filter by ISBN, publisher, author, language, year, NCERT/CBSE/downloadable flags, and status.
3. Each row shows cover thumbnail, title, authors (max 3 +more), ISBN, publisher, language badge, year, flags, counts, status toggle, and action buttons.
4. Clicking "Add Book" opens the create form with all metadata fields, dynamic author/class-subject/file rows, and file uploads.
5. Submit runs BookRequest validation, then a transaction creates the book, pivots, and media attachments.
6. Success redirects to the list with a flash message. Failure rolls back the transaction.
7. View, Edit, Delete, Trash, Restore, Force Delete, and Toggle follow the same pattern as the Author feature.

---

## Validate Before Save (Multiple Conditions)

1. **Title Required** — Error: "The title field is required."
2. **Title Max Length** — Error: "The title must not be greater than 100 characters."
3. **ISBN Unique** — Error: "The isbn has already been taken."
4. **ISBN Max Length** — Error: "The isbn must not be greater than 50 characters."
5. **Publication Year Range** — Must be between 1900 and current year.
6. **Total Pages Min** — Must be at least 1.
7. **Language Required** — Error: "The language field is required."
8. **Language Invalid FK** — Error: "The selected language is invalid."
9. **Cover Image MIME** — Must be jpg, jpeg, png, or webp. Max 2MB.
10. **Ebook MIME** — Must be PDF. Max 50MB.
11. **Duplicate Author+Role** — Error: "Duplicate author with same role found."
12. **Author ID Invalid FK** — Error: "The selected authors.0.author_id is invalid."
13. **Class ID Required** — Error: "The class_subjects.0.class_id field is required."
14. **Book Files Max 20** — Error: "The book files must not be greater than 20."
15. **Tags Max 50 Chars Each** — Error: "The tags.0 must not be greater than 50 characters."

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| title empty | "The title field is required." | 422 |
| duplicate isbn | "The isbn has already been taken." | Redirect with error |
| publication_year > current | "The publication year must not be greater than [current]." | 422 |
| cover image > 2MB | "The cover image media id must not be greater than 2048 kilobytes." | 422 |
| ebook > 50MB | "The ebook file must not be greater than 51200 kilobytes." | 422 |
| duplicate author+role | "Duplicate author with same role found." | 422 |
| unauthorized | "This action is unauthorized." | 403 |
| module disabled | 404 Not Found | 404 |
| guest access | Redirect to /login | 302 |

---

## Success Scenarios

**SC-001: Create a Book with Full Metadata and Files**
1. Admin creates a book with title, ISBN, publisher, language, cover image, ebook, 2 authors, 2 class-subject mappings, and 3 book files.
2. System runs transaction: creates book, inserts author pivots, class-subject pivots, attaches cover/ebook, creates book files.
3. Redirects to book list with success. All data correctly stored.

**SC-002: Update Book with Replaced Cover and New Authors**
1. Admin edits an existing book, uploads a new cover image, changes author assignments, and modifies class-subject mappings.
2. System deletes old author/class-subject pivots, inserts new ones, replaces cover image in media library.
3. Redirects with success. Changes reflected immediately.

---

## Failure Scenarios

**FC-001: Duplicate ISBN Rejected**
1. Admin creates a book with ISBN "978-81-7450-634-8".
2. Admin attempts to create another book with same ISBN.
3. Manual check detects duplicate. Redirects back with error "The isbn has already been taken."

**FC-002: Book Store Transaction Failure on File Upload**
1. Admin fills all fields, adds author/class-subject data, but the ebook file upload fails (server error).
2. Transaction rolls back. Media cleanup removes any partial uploads. Book record is force-deleted.
3. User sees error: "Failed to upload ebook file. Please try again."

**FC-003: Force Delete Blocked by Referenced Chapters**
1. Book has 5 chapters linked. Admin attempts force delete.
2. FK constraint blocks deletion (23000). User sees error flash.

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Primary Table | `slb_books` | `id` PK AI, `uuid` BINARY(16) UNIQUE, `isbn` VARCHAR(20) UNIQUE, `title` VARCHAR(100), `subtitle`, `description`, `edition`, `publication_year` YEAR, `publisher_name`, `total_pages`, `tags` JSON, flags BOOLEAN, `language` FK→`sys_dropdown_table`, `cover_image_media_id` FK→`media_files`, timestamps, soft deletes |
| Pivot Table | `slb_book_author_jnt` | `book_id` FK, `author_id` FK, `author_role` ENUM, `ordinal` TINYINT |
| Pivot Table | `slb_book_class_subject_jnt` | `book_id` FK, `class_id` FK→`sch_classes`, `subject_id` FK→`sch_subjects`, `academic_session_id`, flags |
| Related Table | `slb_book_files` | `id`, `book_id` FK, `media_id` FK, `file_format`, `file_size_kb`, flags |
| Related Table | `slb_book_chapters` | `id`, `book_id` FK, `chapter_no`, `title`, `description`, `page_start`, `page_end` |
| Module Dependency | SyllabusBooks Module | Core module |
| Module Dependency | User & Permission Module | Auth and gates |
| Module Dependency | Syllabus Module | Provides `sch_classes`, `sch_subjects`, `sch_academic_sessions` |
| Module Dependency | System Configuration | Provides `sys_dropdown_table` for language |
| Module Dependency | Media Library | File uploads for cover image, ebook, and book files |
| Module Dependency | Activity Log Module | Activity logging |
