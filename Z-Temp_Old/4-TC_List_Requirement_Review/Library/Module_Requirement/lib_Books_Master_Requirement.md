# Lib Books Master — Business Requirements

## What This Screen Does

The Books Master screen is the central cataloging interface for the entire library system. Every book title — whether physical, digital, audio, or reference-only — is defined here with its bibliographic metadata, classification, and media assets. The screen captures core book information (title, ISBN, edition, publication year), links the book to its publisher, resource type, language, authors, categories, genres, keywords, and curricular subjects. A cover image can be uploaded or fetched from a URL, and extensive analytical fields (lexile level, reading age, awards, series, ratings, curricular relevance score, AI-generated summary and tags) allow deep catalog enrichment.

The screen supports multiple acquisition workflows: manual single-book entry, automated ISBN lookup via OpenLibrary or Google Books services, and bulk Excel/CSV import with validation. Quick-create modals for authors, publishers, and categories allow catalogers to add missing reference data on the fly without leaving the form. Books are surfaced in the Acquisition hub as the primary tab alongside purchases and copies.

---

## When This Screen Is Used

- When adding new book titles to the library catalog during initial setup or ongoing acquisition
- When editing existing book metadata (title, ISBN, classification, cover image)
- When importing multiple books at once from a publisher spreadsheet
- When looking up book details automatically by scanning or typing an ISBN
- When viewing a book's complete details including author list, categories, genres, curriculum mappings, and approved reviews
- When deactivating, soft-deleting, or restoring book titles

## Default Data Load

The Books Master screen opens as the first tab (`tab=books`) within the Library Acquisition hub page (`library.acquisitionIndex`). The controller's `index()` method redirects to the hub. Shared reference dropdowns (publishers, resource types, authors, categories, genres, keywords, subjects, classes, languages) are fetched as active records for create/edit forms. The paginated list supports search by title, ISBN, or author name, filtering by publisher and status, with 15 rows per page.

---

## Key Fields at a Glance

**Core Identity**
Every book must have a title (VARCHAR(500)). A subtitle, edition information, ISBN (unique VARCHAR(20)), ISSN, and DOI are captured for complete bibliographic identification. The publication year (SMALLINT) and page count (INT, must be > 0 if provided) define the physical publication details.

**Relational Mapping**
The book is linked to a publisher (FK to `lib_publishers.id`), a resource type (FK to `lib_resource_types.id` — determines Physical/Digital/Audio), and a language (FK to `sys_dropdown_table.id`). Authors are linked through the `lib_book_author_jnt` junction table with author order and a primary author flag. Categories, genres, and keywords are linked through their respective junction tables. Subject-class mappings via `lib_book_subject_jnt` tie the book to the academic curriculum.

**Cover Image**
A cover image can be uploaded directly (file upload, max 2MB, jpeg/png/jpg/gif/webp) or fetched from a URL. The system uses Spatie Media Library to store the image and links it via `cover_image_media_id` (FK to `sys_media.id`). On edit, the previous cover is replaced.

**Analytics and Enrichment**
The book carries analytical fields including lexile reading level, recommended reading age range, awards (JSON array), series name and position, popularity rank (MEDIUMINT, was TINYINT), academic rating (DECIMAL 3.2), student rating (DECIMAL 3.2), rating count, curricular relevance score, AI-generated summary, tags (JSON), and key concepts (JSON). The `is_available` boolean is a cached value updated by a trigger whenever a copy's status changes.

---

## Business Rules and Conditions

**ISBN Uniqueness**
The ISBN field must be unique across all book records. The FormRequest applies `unique:lib_books_master,isbn` on create and `unique:lib_books_master,isbn,{id}` on update (ignoring the current record). The controller's `validateImportFile` method also checks for duplicate ISBNs and titles during bulk import.

**Resource Type Consistency on Purchase**
When a book appears in a purchase order, the purchase's `resource_type_id` must match the book's own `resource_type_id`. The `StoreLibBookPurchaseRequest` validates this via an after-validation hook to prevent mismatches.

**Reference-Only Restriction**
If `is_reference_only = 1`, the book cannot be borrowed — it is for in-library use only. This flag is checked during the issue workflow.

**Cover Image Management**
The store method handles cover images: if a file is uploaded via `cover_image`, it is added to the Spatie Media collection. If a URL is provided via `cover_image_url`, the system attempts to download it. On edit, the previous cover collection is cleared before adding the new one. URL download failures are silently logged without blocking the save.

**Composite Subject Mapping**
Subject-class assignments are stored via `lib_book_subject_jnt`. On create and update, existing subject junctions are deleted and rebuilt from the `subject_ids` and `class_ids` arrays, creating cross-product entries (each subject × each class).

**Availability Sync**
The `is_available` flag on `lib_books_master` is updated by the static `syncBookAvailability()` method. It checks whether any active copy for the book has a status of "Available". This is called after copy create, update, delete, restore, forceDelete, toggleStatus, markLost, markDamaged, and status change operations.

**Book Import Workflow**
The import process is two-step: (1) `validateImportFile` validates the uploaded Excel/CSV against business rules (title required, publisher required, language must exist in dropdowns, resource type required, duplicate title/ISBN checks). If validation fails, a downloadable error text file is returned. If passes, the file path is stored in session. (2) `startImport` reads the validated file from session, executes the `BookMasterImport`, and returns JSON with created/skipped/error counts.

---

## Workflow Steps

1. Navigate to Library → Acquisition hub → Books tab
2. View the paginated list with search and publisher/status filters
3. Click "Add Book" to open the create form with publisher, resource type, language dropdowns
4. Enter title, ISBN (optional — triggers lookup), select authors (multi-select), categories, genres, keywords
5. Use quick-create modals for authors, publishers, or categories if they don't exist
6. Upload or paste URL for cover image, fill edition, page count, analytical fields
7. Set reference-only flag and active status, then save
8. Edit a book to update any field — ISBN uniqueness is preserved, cover can be replaced
9. Import multiple books via the two-step validate-then-import flow
10. View details with all relationships and approved reviews
11. Delete sends to trash; force-delete handles child copies, junction tables, and FK constraints

---

## Example Scenario

A new batch of 50 NCERT Science textbooks arrives at the school library. The librarian searches for each book's ISBN using the ISBN lookup service, which auto-fills title, author, publisher, and description from Google Books. They add any missing authors on the fly using the quick-create modal. They assign each book to the "Science" category, "Textbook" genre, and link them to Class 9 Physics subject. For one book, they paste a cover image URL from the publisher's website. After creating all 50 books, they navigate to the Book Purchases tab to record the acquisition and auto-generate copies.

---

## Related Screens

- Book Purchases — acquisition records that consume book master entries
- Book Copies — individual copies created from book master records
- Book Reviews — approved ratings and reviews shown on the detail page
- Curricular Alignment — maps books to academic years, classes, and subjects
- Library Masters Hub — authors, publishers, categories, genres, keywords configuration

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibBookMasterController`
**Model:** `Modules\Library\Models\LibBookMaster` (table: `lib_books_master`, uses `SoftDeletes` + `InteractsWithMedia`)
**Service:** `Modules\Library\Services\IsbnLookupService` (OpenLibrary + Google Books)
**Requests:** `LibBookMasterRequest` (validates all bibliographic and relationship fields)
**Policy:** Named permission string `tenant.lib-books-master.*`
**Route:** Resource route `Route::resource('lib-books-master', LibBookMasterController::class)` with extras: `trashed`, `restore`, `forceDelete`, `toggleStatus`, `lookupIsbn`, `quickCreateAuthor`, `quickCreatePublisher`, `quickCreateCategory`, `validateImport`, `startImport`

Key controller methods:
- `index()` — Redirects to hub tab `library.acquisitionIndex` with `tab=books`
- `create()` — Returns create view with all reference dropdowns
- `store(LibBookMasterRequest)` — Creates book, handles cover image (file or URL), syncs authors/categories/genres/keywords/subject-junctions; calls `activityLog`
- `show($id)` — Loads with publisher, resourceType, coverImage, language, authors (ordered), categories, genres, keywords, subjectJunctions, approved reviews
- `update(LibBookMasterRequest, $id)` — Updates book, replaces cover, re-syncs all relations; captures changes for activityLog
- `destroy($id)` — Soft-deletes; calls activityLog
- `trashed()` — Lists soft-deleted books with publisher and resourceType
- `restore($id)` — Restores from trash
- `forceDelete($id)` — In transaction: deletes copies with their transactions, detaches all junctions, force-deletes book; catches FK exception
- `toggleStatus($id)` — Toggles `is_active` via AJAX
- `lookupIsbn(Request)` — Validates and proxies to IsbnLookupService
- `quickCreateAuthor/Publisher/Category(Request)` — First-or-create AJAX endpoints
- `validateImportFile(Request)` — Validates Excel/CSV, returns error file or stores file in session
- `startImport(Request)` — Executes BookMasterImport, returns JSON stats

**ActivityLog Events:** Stored, Updated (with changes array), Trashed, Restored, Deleted

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|-------------|
| Super Admin | `tenant.lib-books-master.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-books-master.*` | Full CRUD + import + ISBN lookup + quick-create |
| Librarian | `tenant.lib-books-master.viewAny`, `.view`, `.create`, `.update` | Add and edit books |
| Library Assistant | `tenant.lib-books-master.viewAny`, `.view` | Read-only catalog viewing |

---

## How This Screen Works — Logic Flow (Non-Technical)

The user opens the Library Acquisition page and sees the Books tab by default. A paginated table lists all book titles with their ISBN, authors, publisher, and available copies count. Clicking "Add Book" opens a comprehensive form with dropdowns populated from related master data tables. The user fills in the title and other details; when they enter an ISBN, they can click a button to auto-fill the rest from an online book database. Authors, categories, and publishers have "quick add" links that open a small popup to create missing entries on the spot. A cover image can be uploaded from the computer or pasted as a URL. After saving, the book appears in the list and is ready for copy creation through purchases. The system also supports importing hundreds of books at once from a spreadsheet — it first validates every row and reports errors, then only imports the clean data on confirmation.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|-------|------|---------------|
| 1 | title | Required, String, Max:500 | Book title is required. |
| 2 | isbn | Nullable, String, Max:20, Unique (ignore self on update) | This ISBN already exists in the database. |
| 3 | publisher_id | Required, Exists:lib_publishers,id | Publisher is required. |
| 4 | language | Required, Exists:sys_dropdown_table,id | Language is required. |
| 5 | resource_type_id | Required, Exists:lib_resource_types,id | Resource type is required. |
| 6 | page_count | Nullable, Integer, Min:1 | Page count must be at least 1. |
| 7 | publication_year | Nullable, Integer, Min:1000, Max:current_year+1 | Publication year must be a valid year. |
| 8 | cover_image | Nullable, Image, Mimes:jpeg,png,jpg,gif,webp, Max:2048 | Cover must be an image file (jpeg, png, jpg, gif, webp) not exceeding 2MB. |
| 9 | author_ids.* | Nullable, Exists:lib_authors,id | Invalid author selected. |
| 10 | category_ids.* | Nullable, Exists:lib_categories,id | Invalid category selected. |
| 11 | genre_ids.* | Nullable, Exists:lib_genres,id | Invalid genre selected. |
| 12 | keyword_ids.* | Nullable, Exists:lib_keywords,id | Invalid keyword selected. |
| 13 | subject_ids.* | Nullable, Exists:sch_subjects,id | Invalid subject selected. |
| 14 | academic_rating | Nullable, Numeric, Min:0, Max:9.99 | Academic rating must be a number between 0 and 9.99. |
| 15 | student_rating | Nullable, Numeric, Min:0, Max:9.99 | Student rating must be a number between 0 and 9.99. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Model not found | No query results for model | 404 |
| ISBN lookup fails | No results found for ISBN / Error communicating with provider | 404 (JSON) |
| Quick-create author fails | Failed to create author | 500 (JSON) |
| Import file not found | No validated file found | 400 (JSON) |
| Import execution error | Import failed: [detail] | 500 (JSON) |
| Force delete — FK constraint | Cannot delete this book: it is referenced by other records. Remove all dependencies first. | 422 (redirect) |
| Store exception | Failed to create book: [detail] | 422 (redirect) |

---

## Success Scenarios

**SC-001: Create a book with ISBN lookup, quick-create author, and cover image**
1. Librarian clicks "Add Book", enters ISBN "978-0-13-468233-1"
2. Clicks "Lookup ISBN" — system auto-fills title, author, publisher, description, and cover URL
3. The author is not in the system — librarian clicks "Quick Create", types the name, and the author is created via AJAX
4. Librarian selects categories and genres, uploads a cover image, sets active
5. System creates the book record, syncs author pivot (with is_primary=true for first author), categories, genres, keywords
6. Flash success: "Book created successfully."

**SC-002: Import 20 books from Excel with validation**
1. Librarian downloads template, fills 20 rows, uploads the file
2. System validates each row — 18 pass, 2 fail (one missing title, one duplicate ISBN)
3. System returns a downloadable error report for the 2 failed rows
4. Librarian fixes the errors, uploads again — all 20 pass
5. Librarian confirms import — system creates all 20 books in the database
6. JSON response: status=completed, created=20, skipped=0, errors=[]

---

## Failure Scenarios

**FC-001: ISBN lookup returns no results**
1. Librarian enters an invalid ISBN and clicks "Lookup ISBN"
2. IsbnLookupService queries OpenLibrary and Google Books — both return no results
3. System returns JSON `{success: false, message: "No results found for ISBN: [value]"}` with 404
4. Librarian manually fills in the book details

**FC-002: Force delete book with active transactions**
1. Librarian navigates to Trash, clicks force-delete on a book that has issued copies
2. DB transaction begins — controller attempts to delete copies, but transactions FK constraint blocks it
3. QueryException with code 23000 is caught
4. Transaction rolls back, flash error: "Cannot delete this book: it is referenced by other records. Remove all dependencies first."
5. Book remains in trash

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | lib_books_master | Primary book catalog table with all bibliographic + analytical columns; uses soft-deletes, FULLTEXT index on title/subtitle/summary |
| Table | lib_book_author_jnt | Junction: FK to lib_books_master.id (CASCADE), lib_authors.id (CASCADE), author_order, is_primary |
| Table | lib_book_category_jnt | Junction: FK to lib_books_master.id (CASCADE), lib_categories.id (CASCADE) |
| Table | lib_book_genre_jnt | Junction: FK to lib_books_master.id (CASCADE), lib_genres.id (CASCADE) |
| Table | lib_book_keyword_jnt | Junction: FK to lib_books_master.id (CASCADE), lib_keywords.id (CASCADE) |
| Table | lib_book_subject_jnt | Junction: FK to lib_books_master.id (CASCADE), sch_classes.id, sch_subjects.id |
| Table | lib_book_copies | FK to lib_books_master.id — individual copies created from this master |
| Table | lib_publishers | FK reference for publisher_id |
| Table | lib_resource_types | FK reference for resource_type_id |
| Table | lib_authors | FK reference via junction |
| Table | lib_categories | FK reference via junction |
| Table | sys_dropdown_table | FK reference for language field |
| Table | sys_media | FK reference for cover_image_media_id (Spatie Media Library) |
| Module | Library Book Purchases | Acquires books and creates copies |
| Module | Library Book Copies | Individual copy management |
| Module | Library Masters (Authors, Publishers, Categories, Genres) | Reference data consumed by book master |

---

## Detailed Field Descriptions (from Lib_Conditions.md Section 4.1)

### Core Identity Fields

**`title`** — VARCHAR(500) NOT NULL
- **Required:** Yes. Every book must have a title, the primary identifier in all search results, dropdowns, and cards.
- **Length Limit:** Maximum 500 characters. Long titles are truncated with `Str::limit()` in views.
- **Search Behavior:** Included in FULLTEXT index (alongside `subtitle` and `summary`) for advanced relevance-based search. Also supports LIKE search for partial matches.
- **Duplicate Handling:** Multiple books can share the same title (e.g., different editions). Distinguish by `isbn` or `edition`.

**`subtitle`** — VARCHAR(500) NULL
- **Required:** No. Optional additional title context.
- **Usage:** Displayed alongside the main title in show views and search results.
- **Search Behavior:** Included in FULLTEXT index alongside `title` and `summary`.

**`edition`** — VARCHAR(50) NULL
- **Required:** No. Helps distinguish between different versions of the same book.
- **Display:** Shown in parentheses after the title in search results and book details (e.g., "Introduction to Algorithms (2nd)").
- **Business Rule:** When the same `isbn` is updated/revised, a new record should be created with the new edition value.

**`isbn`** — VARCHAR(20) UNIQUE
- **Required:** No. Books with an ISBN get special handling (auto-lookup, unique identification).
- **Uniqueness:** Strictly enforced — no two books can share the same ISBN. On create, validated via `Rule::unique('lib_books_master', 'isbn')`. On update, the current record's ID is ignored for the unique check.
- **Auto-Lookup:** When an ISBN is entered, the system calls `IsbnLookupService` (OpenLibrary + Google Books) to auto-fill `title`, `author(s)`, `publisher`, `publication_year`, and other metadata. The user can override these suggestions.
- **Search:** Books are searchable by ISBN via LIKE query.

**`issn`** — VARCHAR(20) NULL
- **Required:** No. Applicable only for serial publications (journals, magazines, newspapers).
- **Business Rule:** If a book has an `issn`, it is typically a serial publication and should have the appropriate `resource_type_id` assigned.

**`doi`** — VARCHAR(100) NULL
- **Required:** No. Used for academic/research publications to provide a persistent link.
- **Usage:** Displayed in book details as a clickable link for DOI resolution (e.g., `https://doi.org/{doi}`).

**`publication_year`** — SMALLINT UNSIGNED NULL
- **Required:** No. Expected range: 1000 to current year. SMALLINT UNSIGNED allows values 0–65535.
- **Display:** Shown in book search results and details as a filterable criterion (e.g., filter by "Published after 2010").
- **Search:** Indexed (`idx_lib_book_year`) for efficient sorting and filtering by publication year.

**`publisher_id`** — INT UNSIGNED NOT NULL
- **Required:** Yes. Every book must be linked to a valid publisher from `lib_publishers`.
- **Dropdown Filter:** Only active publishers (`is_active = 1`) appear in the create/edit form dropdown.
- **FK Constraint:** `ON DELETE RESTRICT` — a publisher cannot be deleted if books reference it.
- **Inactive Restriction:** If a publisher is deactivated (`is_active = 0`), existing books still retain the reference, but the publisher cannot be selected for new books.

**`language`** — INT UNSIGNED NOT NULL
- **Required:** Yes. FK to `sys_dropdown_table.id`. Every book must be assigned a language.
- **Dropdown:** The language selection comes from the system dropdown table. Only active dropdown values are shown.
- **Business Rule:** The language determines locale for sorting and may influence reading recommendations. Books assigned "Other" should have their specific language noted in the `summary` field.
- **Seed Data Required:** Common languages: English, Hindi, Sanskrit, French, German, Spanish, Arabic, Urdu, Bengali, Tamil, Telugu, Marathi, Gujarati, Kannada, Malayalam, Punjabi, Oriya, Assamese, Nepali, Chinese, Japanese, Russian, Portuguese, Italian, Dutch, Other.

**`page_count`** — INT CHECK (page_count > 0) NULL
- **Required:** No. Optional physical book metric.
- **Validation:** Must be greater than 0 (enforced by MySQL CHECK constraint and `integer|min:1` in FormRequest).
- **Display:** Shown in book details. Used in reading analytics (e.g., pages read per day) and `reading_behavior_analytics` calculations.

**`summary`** — TEXT NULL
- **Required:** No. An optional description of the book's content.
- **Search Behavior:** Included in FULLTEXT index alongside `title` and `subtitle` for comprehensive content search.
- **Display:** Shown in book detail view and search result snippets (truncated).

**`table_of_contents`** — TEXT NULL
- **Required:** No. Stores the book's chapter/section listing.
- **Usage:** Displayed in the book's detail/show page to help users understand the book's structure before borrowing.

### Media & Classification

**`cover_image_media_id`** — INT UNSIGNED NULL
- **Required:** No. FK to `sys_media.id`. Managed via the central media module (Spatie Media Library).
- **Deletion Behavior:** `ON DELETE SET NULL` — if the media record is deleted, the book's cover becomes null rather than causing an error.
- **Display:** The cover image appears in search results (thumbnails), book detail pages (full size), and student portal cards.

**`resource_type_id`** — SMALLINT UNSIGNED NOT NULL
- **Required:** Yes. FK to `lib_resource_types.id`. Every book must be categorized into a resource type.
- **Borrowing Behavior:** The `is_borrowable` flag on the resource type determines whether this book can be issued. Even if `is_reference_only = 0`, a book with `resource_type.is_borrowable = 0` cannot be borrowed.
- **Physical/Digital Flag:** The `is_physical` / `is_digital` flags on the resource type dictate which additional fields are relevant (e.g., `page_count` only for physical, `file_format` only for digital).
- **Dropdown Filter:** Only active resource types are shown in the create/edit form.

**`is_reference_only`** — TINYINT(1) NOT NULL DEFAULT 0
- **Default:** 0 (borrowable).
- **Business Rule:** When set to 1, the book cannot be issued to any library member. It is restricted to in-library reading only.
- **Enforcement Points (4 locations):**
  - `LibTransactionController::store()` — checks `$copy->book->is_reference_only` before creating an issue transaction. If true, aborts with error.
  - `LibPhysicalBookRequestController::store()` — checks `$book->is_reference_only` before creating a reservation/request. If true, aborts with error.
  - `StaffLibraryController` — checks before allowing borrowing in the staff portal.
  - `StudentLibraryController::renewBook()` / `reservePhysical()` — blocks renewal/reservation for reference-only books.

### Reading & Awards

**`lexile_level`** — VARCHAR(20) NULL
- **Required:** No. Indicates the reading difficulty/complexity level of the book.
- **Usage:** Used by the recommendation engine to suggest age-appropriate books. Teachers/librarians can filter books by lexile level for students.

**`reading_age_range`** — VARCHAR(20) NULL
- **Required:** No. Specifies the target age group for the book's content.
- **Usage:** Displayed in book details and used in student-facing search filters. Helps students find books appropriate for their age.

**`awards_json`** — JSON NULL
- **Required:** No. Stores an array of award names (e.g., `["Booker Prize 2020", "National Book Award"]`).
- **Display:** Awards are shown as badges or a bulleted list in the book's detail/show page. Books with awards may get priority placement in featured sections.
- **JSON Handling:** Input is comma-separated string → exploded to array → JSON-encoded for storage. Model casts: `'awards_json' => 'array'`.

### Series Information

**`series_name`** — VARCHAR(200) NULL
- **Required:** No. Groups books that belong to a series (e.g., "Harry Potter", "The Lord of the Rings").
- **Business Rule:** When a user views a book that is part of a series, the system should display "Other books in this series" section, linking to other books with the same `series_name`, ordered by `series_position`.

**`series_position`** — TINYINT UNSIGNED NULL
- **Required:** No. Must be specified if `series_name` is provided. Indicates the book's order (1st, 2nd, 3rd, etc.).
- **Business Rule:** When `series_position` is set alongside `series_name`, the series order must be consistent. If two books have the same `series_name` and `series_position`, the system should treat it as an error or duplication.

### Ratings & Analytics

**`popularity_rank`** — MEDIUMINT UNSIGNED NULL
- **Required:** No. Auto-calculated by backend analytics commands (`CalculatePopularityTrends`).
- **Calculation Basis:** Based on borrow frequency, reservation count, search count, and digital resource access count over a rolling time window.
- **Usage:** Powers the "Most Popular Books" widget on the dashboard and student portal. Higher rank = more popular.
- **Auto-Update:** Updated nightly via scheduled command. Not manually editable.

**`academic_rating`** — DECIMAL(3,2) NULL
- **Required:** No. Range: 0.00 to 9.99. Faculty members can rate books for academic value.
- **Calculated:** Average of all faculty ratings for this book, recalculated via DB trigger on insert/update/delete of ratings.
- **Distinct from `student_rating`:** Faculty-specific rating, separate from the student rating. Both displayed alongside each other.

**`student_rating`** — DECIMAL(3,2) NULL
- **Required:** No. Range: 0.00 to 9.99.
- **Calculated:** Average of all student ratings for this book, auto-recalculated by DB trigger when a new rating is added or an existing one is deleted.

**`rating_count`** — INT DEFAULT 0
- **Default:** 0. Incremented/decremented by DB triggers as ratings are added or removed.
- **Usage:** Displayed alongside `student_rating` to give context to the average (e.g., "4.5/5 (120 ratings)" carries more weight than "4.5/5 (3 ratings)").

**`curricular_relevance_score`** — DECIMAL(5,2) NOT NULL DEFAULT 0.00
- **Default:** 0.00. Range: 0.00 to 99.99.
- **Calculated:** Auto-generated by analytics comparing the book's subjects, categories, keywords, and description against the school's curriculum subjects and topics.
- **Usage:** Powers the "Curriculum-Aligned Books" section. Books with higher scores are shown first in subject-specific searches.

### AI & Extended Fields

**`tags_json`** — JSON NULL
- **Required:** No. Stores an array of AI-generated tags (e.g., `["machine-learning", "algorithms", "python"]`).
- **Auto-Generated:** Tags are extracted by an AI service analyzing the book's title, summary, and content. They power the recommendation engine and advanced search filtering.
- **Manual Override:** Users cannot directly edit `tags_json`. Tag management is done through `lib_keywords` junction tables.
- **JSON Handling:** Input is comma-separated string → exploded to array → JSON-encoded for storage. Model casts: `'tags_json' => 'array'`.

**`ai_summary`** — TEXT NULL
- **Required:** No. An automatically generated summary created by processing the book's description, reviews, and content.
- **Usage:** Displayed in book details as an alternative to the manually entered `summary`. If both exist, the AI summary may be shown alongside for richer context.
- **Regeneration:** Can be regenerated on demand by an admin command that reprocesses the book's metadata.

**`key_concepts_json`** — JSON NULL
- **Required:** No. Stores an array of key topics/concepts (e.g., `["binary search", "dynamic programming", "graph theory"]`).
- **Auto-Extracted:** Extracted by AI analysis. Concepts link the book to curriculum topics for relevance scoring.
- **Usage:** Powers the "Related Books" and "Concept Explorer" features. Students can click a concept to find all books covering that concept.
- **JSON Handling:** Input is comma-separated string → exploded to array → JSON-encoded for storage. Model casts: `'key_concepts_json' => 'array'`.

### Status Fields

**`is_available`** — TINYINT(1) NOT NULL DEFAULT 1
- **Default:** 1. Indicates whether at least one active, borrowable copy exists in the library.
- **Auto-Sync Mechanism (CRITICAL):** This is a **cached field** — it does NOT track real-time availability by itself. Instead, it is automatically updated by:
  - **DB Triggers:** The `update_book_availability_{on_insert/update/delete}` triggers recalculate `is_available` whenever a row in `lib_book_copies` is inserted, updated (status change), or deleted. Logic: `EXISTS (SELECT 1 FROM lib_book_copies WHERE book_id = <book_id> AND status = 'Available' AND is_active = 1 AND deleted_at IS NULL)`.
  - **PHP Model Events:** `LibBookMaster::syncBookAvailability($bookId)` is called from `LibBookCopy` model boot events (created, updated, deleted, restored, forceDeleted) as a fallback when triggers may not fire (e.g., bulk operations).
- **Display:**
  - **Index/List Views:** Shown as a colored badge — green "Available" if 1, red "Unavailable" if 0.
  - **Show/Detail View:** Same badge display, prominently placed near the book title.
  - **Create/Edit Forms:** A toggle/checkbox exists, but manual changes may be overwritten by auto-sync mechanisms. The toggle is primarily for initial seed data or exceptional manual overrides (e.g., marking a book unavailable for physical audit).
- **Business Rule:** `is_available = 0` does NOT block the creation of new copies — it reflects the CURRENT state. After adding a new copy with "Available" status, triggers automatically flip `is_available` back to 1.

**`is_active`** — TINYINT(1) NOT NULL DEFAULT 1
- **Default:** 1. When set to 0, the book is hidden from end-user search, student portal, and selection dropdowns. It remains visible in admin CRUD views for reference.
- **Business Rule:** Inactivating a book does NOT affect existing copies, transactions, or reservations — those continue to function normally. The book simply becomes unselectable for new operations.
- **Soft Delete vs Inactive:** Soft-delete (`deleted_at`) permanently hides the book even from admin views, while `is_active = 0` only hides it from end users. Prefer `is_active = 0` for temporary removals.

**`deleted_at`** — TIMESTAMP NULL
- **Behavior:** When set, the book is considered deleted. It disappears from all search results, dropdowns, and counts. Linked child records (copies, transactions) are not affected.
- **Restore:** A soft-deleted book can be restored, which restores its visibility and availability.
- **Force Delete:** Blocked by FK constraints from child tables (copies, transactions, reservations, digital resources, etc.). Attempting force-delete throws a `QueryException` with code '23000'.

---

## JSON/Array Field Handling Pattern

For `awards_json`, `tags_json`, `key_concepts_json` fields on `lib_books_master`:

| Layer | Behavior |
|-------|----------|
| **User Input (Frontend)** | Comma-separated string: `"Award 1, Award 2, Award 3"` |
| **FormRequest Validation** | `nullable\|string` — validates as plain string |
| **Controller (store/update)** | `explode(',', $string)` → `array_map('trim', ...)` → stores as PHP array |
| **Model `$casts`** | `'awards_json' => 'array'` — Eloquent JSON-encodes for storage |
| **Database** | JSON column: `["Award 1","Award 2","Award 3"]` |
