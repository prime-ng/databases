# slb_Book — Test Case List & Business Conditions

**Module:** SyllabusBooks (CODE `SLB`, prefix `slb_`) · **Feature:** Book Master (CRUD + Trash + Toggle Status)
**DB scope:** TENANT-side (`slb_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `slb_books` · **Module URL prefix:** `/syllabus-books`
**Test file:** `slb_Book_TestCas.php`
**Tabs:** Book (second CRUD tab of the Syllabus Books module)

Routes:
- `GET     /syllabus-books?tab=book` — SyllabusBooksController@index (master tabbed view)
- `GET     /syllabus-books/books` — BookController@index (redirects to master tab)
- `GET     /syllabus-books/books/create` — BookController@create
- `POST    /syllabus-books/books` — BookController@store
- `GET     /syllabus-books/books/{book}` — BookController@show
- `GET     /syllabus-books/books/{book}/edit` — BookController@edit
- `PUT     /syllabus-books/books/{book}` — BookController@update
- `DELETE  /syllabus-books/books/{book}` — BookController@destroy
- `GET     /syllabus-books/books/trash/view` — BookController@trashedBook
- `GET     /syllabus-books/books/{id}/restore` — BookController@restore
- `DELETE  /syllabus-books/books/{id}/force-delete` — BookController@forceDelete
- `POST    /syllabus-books/books/{book}/toggle-status` — BookController@toggleStatus
- `GET     /syllabus-books/books/subjects-by-class` — BookController@getSubjectsByClass (AJAX)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `slb_books` exists with columns: id (INT PK AI), uuid (BINARY 16 UNIQUE), isbn (VARCHAR 20 UNIQUE NULLABLE), title (VARCHAR 100 NOT NULL), subtitle (VARCHAR 255 NULLABLE), description (VARCHAR 512 NULLABLE), edition (VARCHAR 50 NULLABLE), publication_year (YEAR NULLABLE), publisher_name (VARCHAR 150 NULLABLE), total_pages (UINT NULLABLE), tags (JSON NULLABLE), is_ncert (BOOLEAN DEFAULT 0), is_cbse_recommended (BOOLEAN DEFAULT 0), is_downloadable (BOOLEAN DEFAULT 0), is_active (BOOLEAN DEFAULT 1), language (UINT FK→sys_dropdown_table NOT NULL), cover_image_media_id (UINT FK→media_files NULLABLE), created_at, updated_at, deleted_at | Migration |
| BC-DB-02 | Unique indexes: `uq_book_uuid` (uuid), `uq_book_isbn` (isbn) | Migration |
| BC-DB-03 | Indexes: `idx_book_title` (title), `idx_book_publisher` (publisher_name), `idx_book_year` (publication_year) | Migration |
| BC-DB-04 | Model `BokBook`: table `slb_books`, SoftDeletes, InteractsWithMedia (collections: 'image' cover single, 'ebook' single) | BokBook.php:17-23 |
| BC-DB-05 | Fillable: 15 fields (uuid, isbn, title, subtitle, description, edition, publication_year, publisher_name, language, total_pages, cover_image_media_id, tags, is_ncert, is_cbse_recommended, is_downloadable, is_active) | BokBook.php:27-35 |
| BC-DB-06 | Casts: tags (array), is_ncert/is_cbse_recommended/is_downloadable/is_active (boolean) | BokBook.php:37-43 |
| BC-DB-07 | Pivot table `slb_book_author_jnt`: book_id FK, author_id FK, author_role ENUM(PRIMARY,CO_AUTHOR,EDITOR,CONTRIBUTOR), ordinal TINYINT, composite PK | Migration |
| BC-DB-08 | Table `slb_book_class_subject_jnt`: book_id FK, class_id FK→sch_classes, subject_id FK→sch_subjects, academic_session_id, remarks, is_active, is_primary, is_mandatory | Migration |
| BC-DB-09 | Table `slb_book_files`: id, book_id FK, media_id, file_format, file_size_kb, label, book_edition, is_primary, is_downloadable, is_active, created_at, updated_at, deleted_at | Migration |
| BC-DB-10 | Table `slb_book_chapters`: id, book_id FK, chapter_no, title, description, page_start, page_end, is_active | Migration |
| BC-DB-11 | Relationships: authors (belongsToMany via pivot), classSubjects (hasMany), files (hasMany), chapters (hasMany), languageRelation (belongsTo Dropdown) | BokBook.php:58-90 |

### BC-VAL — Validation (Source: `BookRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `title` required string max:255 | BookRequest:18 |
| BC-VAL-02 | `subtitle` nullable string max:255 | BookRequest:19 |
| BC-VAL-03 | `isbn` nullable string max:50 unique:slb_books,isbn (ignore self on update) | BookRequest:20 |
| BC-VAL-04 | `edition` nullable string max:50 | BookRequest:21 |
| BC-VAL-05 | `publication_year` nullable integer min:1900 max:current_year | BookRequest:22 |
| BC-VAL-06 | `publisher_name` nullable string max:255 | BookRequest:23 |
| BC-VAL-07 | `total_pages` nullable integer min:1 | BookRequest:24 |
| BC-VAL-08 | `description` nullable string | BookRequest:25 |
| BC-VAL-09 | `language` required integer exists:sys_dropdown_table,id | BookRequest:26 |
| BC-VAL-10 | `cover_image_media_id` nullable image mimes:jpg,jpeg,png,webp max:2048 KB | BookRequest:27 |
| BC-VAL-11 | `ebook_file` nullable file mimes:pdf max:51200 KB (50MB) | BookRequest:28 |
| BC-VAL-12 | `is_ncert` nullable boolean (forced via prepareForValidation) | BookRequest:29 |
| BC-VAL-13 | `is_cbse_recommended` nullable boolean (forced) | BookRequest:30 |
| BC-VAL-14 | `is_downloadable` nullable boolean (forced) | BookRequest:31 |
| BC-VAL-15 | `is_active` nullable boolean (forced) | BookRequest:32 |
| BC-VAL-16 | `tags` nullable array, tags.* string max:50 | BookRequest:33-34 |
| BC-VAL-17 | `authors` nullable array, authors.*.author_id required integer exists:slb_book_authors,id | BookRequest:37-38 |
| BC-VAL-18 | `authors.*.author_role` nullable string in:PRIMARY,CO_AUTHOR,EDITOR,CONTRIBUTOR | BookRequest:39 |
| BC-VAL-19 | `authors.*.ordinal` nullable integer min:1 max:255 | BookRequest:40 |
| BC-VAL-20 | `class_subjects` nullable array, class_subjects.*.class_id required integer exists:sch_classes,id | BookRequest:43-44 |
| BC-VAL-21 | `class_subjects.*.subject_id` required integer exists:sch_subjects,id | BookRequest:45 |
| BC-VAL-22 | `class_subjects.*.academic_session_id` required integer + custom exists validation | BookRequest:46, store:12-16 |
| BC-VAL-23 | `class_subjects.*.remarks` nullable string max:255 | BookRequest:47 |
| BC-VAL-24 | `class_subjects.*.is_primary/is_mandatory/is_active` nullable boolean | BookRequest:48-50 |
| BC-VAL-25 | `book_files` nullable array max:20 | BookRequest:52 |
| BC-VAL-26 | `book_files.*.file` required_with:label, file mimes:pdf,epub,jpg,jpeg,png,docx,mobi max:config | BookRequest:53 |
| BC-VAL-27 | `book_files.*.label` nullable string max:150 | BookRequest:54 |
| BC-VAL-28 | `book_files.*.file_format` nullable in:PDF,EPUB,JPG,PNG,DOCX,MOBI,OTHER | BookRequest:55 |
| BC-VAL-29 | `book_files.*.book_edition` nullable string max:50 | BookRequest:56 |
| BC-VAL-30 | `book_files.*.is_primary/is_downloadable` nullable boolean | BookRequest:57-58 |
| BC-VAL-31 | `book_files_delete` nullable array, book_files_delete.* integer exists:slb_book_files,id | BookRequest:61-62 |
| BC-VAL-32 | Duplicate author with same role in same book → ValidationException "Duplicate author with same role found." | Ctrl store:36-44 |
| BC-VAL-33 | Duplicate isbn in store → manual check before create, returns back with error | Ctrl:22-27 |
| BC-VAL-34 | prepareForValidation: title/subtitle/description/publisher_name UTF-8 sanitized; is_ncert/is_cbse_recommended/is_downloadable/is_active forced boolean; tags comma-split; authors/class_subjects/book_files filtered empty | BookRequest:82-106 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `tenant.book.viewAny` | Ctrl:20 |
| BC-AUTH-02 | create()/store() gate `tenant.book.create` | Ctrl:28,39 |
| BC-AUTH-03 | show() gate `tenant.book.view` | Ctrl:187 |
| BC-AUTH-04 | edit()/update() gate `tenant.book.update` | Ctrl:192,202 |
| BC-AUTH-05 | destroy() gate `tenant.book.delete` | Ctrl:250 |
| BC-AUTH-06 | trashedBook()/restore() gate `tenant.book.restore` | Ctrl:243,258 |
| BC-AUTH-07 | forceDelete() gate `tenant.book.forceDelete` | Ctrl:266 |
| BC-AUTH-08 | toggleStatus() gate `tenant.book.update` | Ctrl:304 |
| BC-AUTH-09 | getSubjectsByClass() gate `tenant.book.viewAny` | Ctrl:175 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to `syllabus-books.index?tab=book` | Ctrl:22-23 |
| BC-BIZ-02 | Master query: filter by search (title/subtitle/description LIKE), isbn, publisher, author_id (whereHas), language_id, publication_year, is_ncert, is_cbse_recommended, is_downloadable, status; ordered by created_at DESC; paginated 10 (`books_page`); withCount files/chapters/classSubjects; load authors/languageRelation | SyllabusBooksCtrl |
| BC-BIZ-03 | create() loads: languages (Dropdown key=slb_books.language), active authors, active classes, active subjects, current academic session | Ctrl:29-36 |
| BC-BIZ-04 | store() runs in DB transaction: creates BokBook, inserts author pivot rows (with duplicate-role check), inserts class-subject pivot rows (with is_primary cascade), attaches cover image and ebook via media library, attaches book files | Ctrl:44-155 |
| BC-BIZ-05 | store() checks ISBN duplicate manually before create | Ctrl:21-27 |
| BC-BIZ-06 | store() on file attachment failure: cleanup (delete media, pivot rows, book), forceDelete, redirect with error | Ctrl:135-151 |
| BC-BIZ-07 | store() logs 'Created' activity; returns JSON or redirect | Ctrl:153-158 |
| BC-BIZ-08 | update() deletes and re-inserts author/class-subject pivots; attaches new cover/ebook; manages book files (delete flagged, update flags, attach new); logs 'Updated' | Ctrl:203-246 |
| BC-BIZ-09 | attachBookFiles(): creates BookFile rows linked to media; handles is_primary cascade (only one primary per book) | Ctrl:314-346 |
| BC-BIZ-10 | deleteBookFiles(): clears media collection for each file, then deletes the BookFile row | Ctrl:348-354 |
| BC-BIZ-11 | destroy(): sets is_active=false, calls delete(), logs 'Trashed' | Ctrl:251-256 |
| BC-BIZ-12 | restore(): withTrashed findOrFail, restore(), logs 'Restored' | Ctrl:259-264 |
| BC-BIZ-13 | forceDelete(): deletes author/class-subject pivots, clears ebook media, forceDelete, logs 'Deleted'; catches FK 23000 | Ctrl:267-284 |
| BC-BIZ-14 | toggleStatus(): flips is_active, logs 'Toggled', returns JSON `{success, is_active, message}` | Ctrl:305-313 |
| BC-BIZ-15 | getSubjectsByClass(): AJAX returns subjects linked to a class via sch_subject_study_format_jnt → sch_class_groups_jnt | Ctrl:176-184 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for show/edit/update/destroy → 404 (findOrFail) | Ctrl |
| BC-EDG-02 | WithTrashed for restore/forceDelete → 404 if not in trash | Ctrl:260,268 |
| BC-EDG-03 | Duplicate isbn on store → manual check, redirect back with error | Ctrl:21-27 |
| BC-EDG-04 | Duplicate isbn on update → unique rule ignores self | BookRequest:20 |
| BC-EDG-05 | Duplicate author_id + author_role in same book → ValidationException | Ctrl:40-43 |
| BC-EDG-06 | publication_year > current_year → rejected (max:current_year) | BookRequest:22 |
| BC-EDG-07 | publication_year < 1900 → rejected (min:1900) | BookRequest:22 |
| BC-EDG-08 | cover_image_media_id > 2MB → rejected (max:2048) | BookRequest:27 |
| BC-EDG-09 | ebook_file > 50MB → rejected (max:51200) | BookRequest:28 |
| BC-EDG-10 | book_files exceeding 20 entries → rejected (max:20) | BookRequest:52 |
| BC-EDG-11 | file in book_files with invalid mime → rejected | BookRequest:53 |
| BC-EDG-12 | Force delete on book referenced by chapters/prescriptions → 23000 caught, error flash | Ctrl:277-280 |
| BC-EDG-13 | title NULL → validation failure (required) | BC-VAL-01 |
| BC-EDG-14 | language invalid FK → validation failure (exists) | BC-VAL-09 |
| BC-EDG-15 | Empty search result → "No Data Found" empty state | View |
| BC-EDG-16 | Soft-deleted book should NOT be visible in active list (onlyTrashed) | Ctrl:243 |
| BC-EDG-17 | total_pages=0 or negative → rejected (min:1) | BC-VAL-07 |
| BC-EDG-18 | tags empty string → converted to empty array by prepareForValidation | BookRequest:96-99 |

---

## 2. Test Case List

### Screen 1: Book Index — List (GET /syllabus-books?tab=book)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P10 | Positive | Ctrl | Book tab renders with filters (search, isbn, publisher, author, language, year, ncert, cbse, downloadable, status) and results table | Page rendered | test_book_10 | Automated |
| TC-BK-P11 | Positive | Ctrl | Search by title/subtitle/description (LIKE) filters results | Filtered | test_book_11 | Automated |
| TC-BK-P12 | Positive | Ctrl | Filter by isbn (exact) narrows results | Filtered | test_book_12 | Automated |
| TC-BK-P13 | Positive | Ctrl | Filter by publisher_name (LIKE) narrows results | Filtered | test_book_13 | Automated |
| TC-BK-P14 | Positive | Ctrl | Filter by author_id (whereHas) narrows results | Filtered | test_book_14 | Automated |
| TC-BK-P15 | Positive | Ctrl | Filter by language_id (exact) narrows results | Filtered | test_book_15 | Automated |
| TC-BK-P16 | Positive | Ctrl | Filter by publication_year (exact) narrows results | Filtered | test_book_16 | Automated |
| TC-BK-P17 | Positive | Ctrl | Filter by is_ncert (0/1) narrows results | Filtered | test_book_17 | Automated |
| TC-BK-P18 | Positive | Ctrl | Filter by is_cbse_recommended (0/1) narrows results | Filtered | test_book_18 | Automated |
| TC-BK-P19 | Positive | Ctrl | Filter by is_downloadable (0/1) narrows results | Filtered | test_book_19 | Automated |
| TC-BK-P20 | Positive | Ctrl | Filter by status (is_active 0/1) narrows results | Filtered | test_book_20 | Automated |
| TC-BK-P21 | Positive | Ctrl | Combined filters work together | Filtered | test_book_21 | Automated |
| TC-BK-P22 | Positive | Ctrl | Reset button clears all filters | Cleared | test_book_22 | Automated |
| TC-BK-P23 | Positive | Ctrl | Paginated (10 per page, `books_page` param), preserve query string | Paginated | test_book_23 | Automated |
| TC-BK-P24 | Positive | View | Table columns: Cover thumb, Title+subtitle, Authors (max 3 +more), ISBN, Publisher, Lang badge, Year, Flags (N/C/D badges), Files count, Chapters count, Prescriptions count, Status toggle, Action | All visible | test_book_24 | Automated |
| TC-BK-P25 | Positive | View | Cover image shown when available, placeholder icon when not | Cover/placeholder | test_book_25 | Automated |
| TC-BK-P26 | Positive | View | Status toggle switch present on every row | Toggle present | test_book_26 | Automated |
| TC-BK-P27 | Positive | View | Action buttons per row: View, Edit, Delete (permission-gated) | 3 buttons | test_book_27 | Automated |
| TC-BK-P28 | Positive | View | Ordered by created_at DESC | Sorted | test_book_28 | Planned |
| TC-BK-P29 | Positive | View | Empty state when no books match filters | "No Data Found" | test_book_29 | Automated |
| TC-BK-P30 | Positive | JSON | AJAX getSubjectsByClass returns subjects for selected class | JSON list | test_book_30 | Automated |

### Screen 2: Create Form (GET /syllabus-books/books/create)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P40 | Positive | View | Create page renders: title, subtitle, isbn, edition, publication_year, publisher_name, total_pages, description, language dropdown, tags, cover image upload, ebook upload, checkbox flags (is_ncert, is_cbse_recommended, is_downloadable, is_active), authors dynamic rows, class_subjects dynamic rows, book_files dynamic rows | All fields visible | test_book_40 | Automated |

### Screen 3: Store (POST /syllabus-books/books)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P50 | Positive | Ctrl | Valid store creates book with basic fields (title, language, is_active) | Created | test_book_50 | Automated |
| TC-BK-P51 | Positive | Ctrl | Store with complete data (all fields + authors + class_subjects + book_files) | Created full | test_book_51 | Automated |
| TC-BK-P52 | Positive | Ctrl | Store with author pivot rows inserted correctly | Pivot inserted | test_book_52 | Automated |
| TC-BK-P53 | Positive | Ctrl | Store with class_subject pivot rows inserted | Pivot inserted | test_book_53 | Automated |
| TC-BK-P54 | Positive | Ctrl | Store with cover image upload → media created | Cover attached | test_book_54 | Automated |
| TC-BK-P55 | Positive | Ctrl | Store with ebook PDF upload → media created | Ebook attached | test_book_55 | Automated |
| TC-BK-P56 | Positive | Ctrl | Store with book_files attached → BookFile rows + media created | Files attached | test_book_56 | Automated |
| TC-BK-P57 | Positive | Ctrl | is_ncert/is_cbse_recommended/is_downloadable/is_active forced boolean by prepareForValidation | Correct booleans | test_book_57 | Automated |
| TC-BK-P58 | Positive | Ctrl | Tags submitted as comma-separated string → stored as JSON array | Tags stored | test_book_58 | Automated |
| TC-BK-P59 | Positive | Ctrl | Store writes 'Created' activity log | Log entry | test_book_59 | Automated |
| TC-BK-P60 | Positive | Ctrl | Store redirects to books index with success flash | Redirect + flash | test_book_60 | Automated |
| TC-BK-P61 | Positive | Ctrl | Nullable fields (subtitle, isbn, edition, etc.) omitted → stored as NULL | NULL stored | test_book_61 | Automated |
| TC-BK-P62 | Positive | Ctrl | UUID auto-generated on create | UUID set | test_book_62 | Planned |
| TC-BK-N70 | Negative | Ctrl | title empty → 422 | 422 | test_book_70 | Automated |
| TC-BK-N71 | Negative | Ctrl | title exceeds 255 chars → 422 | 422 | test_book_71 | Automated |
| TC-BK-N72 | Negative | Ctrl | language empty → 422 | 422 | test_book_72 | Automated |
| TC-BK-N73 | Negative | Ctrl | language invalid FK → 422 | 422 | test_book_73 | Automated |
| TC-BK-N74 | Negative | Ctrl | isbn duplicate → manual check, redirect back with error | Error flash | test_book_74 | Automated |
| TC-BK-N75 | Negative | Ctrl | isbn exceeds 50 chars → 422 | 422 | test_book_75 | Automated |
| TC-BK-N76 | Negative | Ctrl | publication_year > current_year → 422 | 422 | test_book_76 | Automated |
| TC-BK-N77 | Negative | Ctrl | publication_year < 1900 → 422 | 422 | test_book_77 | Automated |
| TC-BK-N78 | Negative | Ctrl | total_pages = 0 → 422 (min:1) | 422 | test_book_78 | Automated |
| TC-BK-N79 | Negative | Ctrl | total_pages negative → 422 | 422 | test_book_79 | Automated |
| TC-BK-N80 | Negative | Ctrl | isbn not provided (nullable) → passes | 200/redirect | test_book_80 | Automated |
| TC-BK-N81 | Negative | Ctrl | cover_image_media_id > 2MB → 422 | 422 | test_book_81 | Automated |
| TC-BK-N82 | Negative | Ctrl | cover_image_media_id invalid mime (e.g. .gif) → 422 | 422 | test_book_82 | Automated |
| TC-BK-N83 | Negative | Ctrl | ebook_file invalid mime (e.g. .doc) → 422 | 422 | test_book_83 | Automated |
| TC-BK-N84 | Negative | Ctrl | ebook_file > 50MB → 422 | 422 | test_book_84 | Automated |
| TC-BK-N85 | Negative | Ctrl | authors.*.author_id empty → 422 | 422 | test_book_85 | Automated |
| TC-BK-N86 | Negative | Ctrl | authors.*.author_id non-existing → 422 | 422 | test_book_86 | Automated |
| TC-BK-N87 | Negative | Ctrl | authors.*.author_role invalid value → 422 (in:PRIMARY,CO_AUTHOR,EDITOR,CONTRIBUTOR) | 422 | test_book_87 | Automated |
| TC-BK-N88 | Negative | Ctrl | Duplicate author_id + same role → ValidationException "Duplicate author with same role found" | Error | test_book_88 | Automated |
| TC-BK-N89 | Negative | Ctrl | class_subjects.*.class_id empty → 422 | 422 | test_book_89 | Automated |
| TC-BK-N90 | Negative | Ctrl | class_subjects.*.subject_id empty → 422 | 422 | test_book_90 | Automated |
| TC-BK-N91 | Negative | Ctrl | class_subjects.*.class_id invalid FK → 422 | 422 | test_book_91 | Automated |
| TC-BK-N92 | Negative | Ctrl | class_subjects.*.academic_session_id empty → 422 | 422 | test_book_92 | Automated |
| TC-BK-N93 | Negative | Ctrl | book_files exceeding 20 entries → 422 (max:20) | 422 | test_book_93 | Automated |
| TC-BK-N94 | Negative | Ctrl | book_files.*.file with invalid mime → 422 | 422 | test_book_94 | Automated |
| TC-BK-N95 | Negative | Ctrl | tags.* string exceeds 50 chars → 422 | 422 | test_book_95 | Automated |

### Screen 4: Show (GET /syllabus-books/books/{book})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P100 | Positive | View | Show page displays: title, subtitle, isbn, edition, publication_year, publisher_name, total_pages, description, language, tags, cover image, is_ncert, is_cbse_recommended, is_downloadable, is_active, created_at, updated_at | All fields shown | test_book_100 | Automated |
| TC-BK-P101 | Positive | View | Show page lists related authors with roles | Authors listed | test_book_101 | Automated |
| TC-BK-P102 | Positive | View | Show page lists class-subject mappings | Class-subject listed | test_book_102 | Automated |
| TC-BK-P103 | Positive | View | Show page lists book files with download/view links | Files listed | test_book_103 | Automated |
| TC-BK-P104 | Positive | View | Show page lists chapters if any | Chapters listed | test_book_104 | Automated |
| TC-BK-P105 | Positive | View | Placeholder shown for missing cover image | Placeholder | test_book_105 | Automated |
| TC-BK-N106 | Negative | Ctrl | Invalid id → 404 | 404 | test_book_106 | Automated |
| TC-BK-N107 | Negative | Ctrl | Soft-deleted id → 404 | 404 | test_book_107 | Automated |

### Screen 5: Edit (GET /syllabus-books/books/{book}/edit)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P110 | Positive | View | Edit page pre-fills all fields with existing values | All pre-filled | test_book_110 | Automated |
| TC-BK-P111 | Positive | View | Edit page loads existing author rows with roles | Authors loaded | test_book_111 | Automated |
| TC-BK-P112 | Positive | View | Edit page loads existing class-subject rows | CS rows loaded | test_book_112 | Automated |
| TC-BK-P113 | Positive | View | Edit page loads existing book files with flags | Files loaded | test_book_113 | Automated |
| TC-BK-P114 | Positive | View | Cover image preview displayed if exists | Preview shown | test_book_114 | Automated |
| TC-BK-N115 | Negative | Ctrl | Invalid id → 404 | 404 | test_book_115 | Automated |

### Screen 6: Update (PUT /syllabus-books/books/{book})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P120 | Positive | Ctrl | Update modifies book fields and logs 'Updated' | Updated + log | test_book_120 | Automated |
| TC-BK-P121 | Positive | Ctrl | Update replaces author pivots (delete old, insert new) | Authors replaced | test_book_121 | Automated |
| TC-BK-P122 | Positive | Ctrl | Update replaces class-subject pivots | CS replaced | test_book_122 | Automated |
| TC-BK-P123 | Positive | Ctrl | Update with new cover image replaces old one | Cover updated | test_book_123 | Automated |
| TC-BK-P124 | Positive | Ctrl | Update with new ebook replaces old one | Ebook updated | test_book_124 | Automated |
| TC-BK-P125 | Positive | Ctrl | Update deletes flagged book_files (book_files_delete) | Files deleted | test_book_125 | Automated |
| TC-BK-P126 | Positive | Ctrl | Update updates book_file flags (is_primary, is_downloadable, is_active) | Flags updated | test_book_126 | Automated |
| TC-BK-P127 | Positive | Ctrl | Update redirects with success flash | Redirect + flash | test_book_127 | Automated |
| TC-BK-P128 | Positive | Ctrl | Is_primary cascade: only one primary file per book | Single primary | test_book_128 | Planned |
| TC-BK-N129 | Negative | Ctrl | Duplicate isbn on update → unique rule catches | 422 | test_book_129 | Automated |
| TC-BK-N130 | Negative | Ctrl | Same validation rules apply on update as create | As create | test_book_130 | Automated |

### Screen 7: Destroy (DELETE /syllabus-books/books/{book})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P140 | Positive | Ctrl | Destroy soft-deletes and sets is_active=false | Soft-deleted | test_book_140 | Automated |
| TC-BK-P141 | Positive | Ctrl | Destroy logs 'Trashed' activity | Log entry | test_book_141 | Automated |
| TC-BK-P142 | Positive | Ctrl | Destroy redirects with success flash | Redirect + flash | test_book_142 | Automated |
| TC-BK-N143 | Negative | Ctrl | Destroy on non-existing id → 404 | 404 | test_book_143 | Automated |

### Screen 8: Trash (GET /syllabus-books/books/trash/view)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P150 | Positive | View | Trash page lists soft-deleted books with all relationships loaded | Listed | test_book_150 | Automated |
| TC-BK-P151 | Positive | View | Each trashed row has Restore and Force Delete action buttons | 2 buttons | test_book_151 | Automated |
| TC-BK-P152 | Positive | View | Trash paginated (10 per page) | Paginated | test_book_152 | Planned |

### Screen 9: Restore (GET /syllabus-books/books/{id}/restore)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P160 | Positive | Ctrl | Restore recovers record, logs 'Restored' | Restored + log | test_book_160 | Automated |
| TC-BK-P161 | Positive | Ctrl | Restore redirects to trashed view with success flash | Redirect + flash | test_book_161 | Automated |
| TC-BK-N162 | Negative | Ctrl | Restore on non-trashed/non-existing id → 404 | 404 | test_book_162 | Automated |

### Screen 10: Force Delete (DELETE /syllabus-books/books/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P170 | Positive | Ctrl | Force delete permanently removes book, deletes pivots, clears media, logs 'Deleted' | Removed + log | test_book_170 | Automated |
| TC-BK-P171 | Positive | Ctrl | Force delete redirects to trashed with success flash | Redirect + flash | test_book_171 | Automated |
| TC-BK-N172 | Negative | Ctrl | Force delete on non-trashed id → 404 | 404 | test_book_172 | Automated |
| TC-BK-N173 | Negative | Ctrl | Force delete on book referenced by other records → 23000 caught, error flash | Error flash | test_book_173 | Planned |

### Screen 11: Toggle Status (POST /syllabus-books/books/{book}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P180 | Positive | Ctrl | Toggle active → inactive | is_active=false | test_book_180 | Automated |
| TC-BK-P181 | Positive | Ctrl | Toggle inactive → active | is_active=true | test_book_181 | Automated |
| TC-BK-P182 | Positive | Ctrl | Toggle returns JSON `{success, is_active, message}` | JSON response | test_book_182 | Automated |
| TC-BK-P183 | Positive | Ctrl | Toggle logs 'Toggled' activity | Log entry | test_book_183 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Security

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-BK-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes, MediaLibrary, unique indexes | All pass | test_book_01 | Automated |
| TC-BK-P02 | Schema | Routes | Resource + extra routes registered (11 total) | All present | test_book_02 | Automated |
| TC-BK-P03 | Schema | Pivot | slb_book_author_jnt exists with FK columns and unique constraint | Present | test_book_03 | Automated |
| TC-BK-P04 | Schema | Pivot | slb_book_class_subject_jnt exists with correct columns | Present | test_book_04 | Automated |
| TC-BK-P05 | Auth | Middleware | Guest redirected to /login | /login | test_book_05 | Automated |
| TC-BK-P06 | Auth | Policy | Policy permission mapping correct for all 7 gates | Mapped | test_book_06 | Automated |
| TC-BK-P07 | Auth | Ctrl | Controller gate authorization present on all methods | Gates present | test_book_07 | Automated |
| TC-BK-N08 | Auth | Ctrl | User without tenant.book.viewAny → 403 on index | 403 | test_book_08 | Automated |
| TC-BK-N09 | Auth | Ctrl | User without tenant.book.create → 403 on create/store | 403 | test_book_09 | Automated |
| TC-BK-N10 | Auth | Ctrl | User without tenant.book.view → 403 on show | 403 | test_book_10 | Automated |
| TC-BK-N11 | Auth | Ctrl | User without tenant.book.update → 403 on edit/update/toggleStatus | 403 | test_book_11 | Automated |
| TC-BK-N12 | Auth | Ctrl | User without tenant.book.delete → 403 on destroy | 403 | test_book_12 | Automated |
| TC-BK-N13 | Auth | Ctrl | User without tenant.book.restore → 403 on trashed/restore | 403 | test_book_13 | Automated |
| TC-BK-N14 | Auth | Ctrl | User without tenant.book.forceDelete → 403 on forceDelete | 403 | test_book_14 | Automated |
| TC-BK-T90 | Tenancy | Tenant | Book records scoped to current tenant | Scoped | test_book_90 | Automated |
| TC-BK-P91 | Security | View | Stored XSS in title/subtitle/description escaped on render | Escaped | test_book_91 | Automated |
| TC-BK-P92 | Security | Ctrl | cover_image_media_id/uploaded_by not spoofable | Ignored | test_book_92 | Planned |

---

## 3. Test Method Index

### File: `slb_Book_TestCas.php` (127 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_book_01_migration_model_and_schema | TC-BK-P01 | Schema | 01-04 |
| 2 | test_book_02_resource_routes_are_registered | TC-BK-P02 | Schema | 01-04 |
| 3 | test_book_03_author_pivot_table_exists | TC-BK-P03 | Schema | 01-04 |
| 4 | test_book_04_class_subject_pivot_table_exists | TC-BK-P04 | Schema | 01-04 |
| 5 | test_book_05_guest_redirected_to_login | TC-BK-P05 | Auth | 05-09 |
| 6 | test_book_06_policy_permission_mapping_is_correct | TC-BK-P06 | Auth | 05-09 |
| 7 | test_book_07_controller_gate_authorization_is_present | TC-BK-P07 | Auth | 05-09 |
| 8 | test_book_08_user_without_viewAny_permission_gets_403 | TC-BK-N08 | Auth | 05-09 |
| 9 | test_book_09_user_without_create_permission_gets_403 | TC-BK-N09 | Auth | 05-09 |
| 10 | test_book_10_user_without_view_permission_gets_403 | TC-BK-N10 | Auth | 05-09 |
| 11 | test_book_11_user_without_update_permission_gets_403 | TC-BK-N11 | Auth | 05-09 |
| 12 | test_book_12_user_without_delete_permission_gets_403 | TC-BK-N12 | Auth | 05-09 |
| 13 | test_book_13_user_without_restore_permission_gets_403 | TC-BK-N13 | Auth | 05-09 |
| 14 | test_book_14_user_without_forceDelete_permission_gets_403 | TC-BK-N14 | Auth | 05-09 |
| 15 | test_book_10_book_tab_renders_with_filters | TC-BK-P10 | List | 10-39 |
| 16 | test_book_11_search_by_title_subtitle_description | TC-BK-P11 | List | 10-39 |
| 17 | test_book_12_filter_by_isbn | TC-BK-P12 | List | 10-39 |
| 18 | test_book_13_filter_by_publisher | TC-BK-P13 | List | 10-39 |
| 19 | test_book_14_filter_by_author_id | TC-BK-P14 | List | 10-39 |
| 20 | test_book_15_filter_by_language_id | TC-BK-P15 | List | 10-39 |
| 21 | test_book_16_filter_by_publication_year | TC-BK-P16 | List | 10-39 |
| 22 | test_book_17_filter_by_is_ncert | TC-BK-P17 | List | 10-39 |
| 23 | test_book_18_filter_by_is_cbse_recommended | TC-BK-P18 | List | 10-39 |
| 24 | test_book_19_filter_by_is_downloadable | TC-BK-P19 | List | 10-39 |
| 25 | test_book_20_filter_by_status | TC-BK-P20 | List | 10-39 |
| 26 | test_book_21_combined_filters | TC-BK-P21 | List | 10-39 |
| 27 | test_book_22_reset_button_clears_filters | TC-BK-P22 | List | 10-39 |
| 28 | test_book_23_pagination_10_per_page | TC-BK-P23 | List | 10-39 |
| 29 | test_book_24_table_displays_all_columns | TC-BK-P24 | List | 10-39 |
| 30 | test_book_25_cover_image_or_placeholder | TC-BK-P25 | List | 10-39 |
| 31 | test_book_26_status_toggle_on_every_row | TC-BK-P26 | List | 10-39 |
| 32 | test_book_27_action_buttons_per_row | TC-BK-P27 | List | 10-39 |
| 33 | test_book_28_ordered_by_created_at_desc | TC-BK-P28 | List | 10-39 |
| 34 | test_book_29_empty_state_when_no_books | TC-BK-P29 | List | 10-39 |
| 35 | test_book_30_ajax_get_subjects_by_class | TC-BK-P30 | List | 10-39 |
| 36 | test_book_40_create_page_renders_all_fields | TC-BK-P40 | Create | 40-49 |
| 37 | test_book_50_store_basic_book | TC-BK-P50 | Store | 50-69 |
| 38 | test_book_51_store_with_complete_data | TC-BK-P51 | Store | 50-69 |
| 39 | test_book_52_store_author_pivot_inserted | TC-BK-P52 | Store | 50-69 |
| 40 | test_book_53_store_class_subject_pivot_inserted | TC-BK-P53 | Store | 50-69 |
| 41 | test_book_54_store_cover_image_uploaded | TC-BK-P54 | Store | 50-69 |
| 42 | test_book_55_store_ebook_uploaded | TC-BK-P55 | Store | 50-69 |
| 43 | test_book_56_store_book_files_attached | TC-BK-P56 | Store | 50-69 |
| 44 | test_book_57_boolean_flags_forced_correctly | TC-BK-P57 | Store | 50-69 |
| 45 | test_book_58_tags_stored_as_json_array | TC-BK-P58 | Store | 50-69 |
| 46 | test_book_59_store_logs_created_activity | TC-BK-P59 | Store | 50-69 |
| 47 | test_book_60_store_redirects_with_success | TC-BK-P60 | Store | 50-69 |
| 48 | test_book_61_nullable_fields_stored_as_null | TC-BK-P61 | Store | 50-69 |
| 49 | test_book_62_uuid_auto_generated | TC-BK-P62 | Store | 50-69 |
| 50 | test_book_70_title_required | TC-BK-N70 | Val | 70-99 |
| 51 | test_book_71_title_max_length | TC-BK-N71 | Val | 70-99 |
| 52 | test_book_72_language_required | TC-BK-N72 | Val | 70-99 |
| 53 | test_book_73_language_invalid_fk | TC-BK-N73 | Val | 70-99 |
| 54 | test_book_74_isbn_duplicate | TC-BK-N74 | Val | 70-99 |
| 55 | test_book_75_isbn_max_length | TC-BK-N75 | Val | 70-99 |
| 56 | test_book_76_publication_year_exceeds_current | TC-BK-N76 | Val | 70-99 |
| 57 | test_book_77_publication_year_below_1900 | TC-BK-N77 | Val | 70-99 |
| 58 | test_book_78_total_pages_zero_rejected | TC-BK-N78 | Val | 70-99 |
| 59 | test_book_79_total_pages_negative | TC-BK-N79 | Val | 70-99 |
| 60 | test_book_80_isbn_nullable_accepted | TC-BK-N80 | Val | 70-99 |
| 61 | test_book_81_cover_image_exceeds_2mb | TC-BK-N81 | Val | 70-99 |
| 62 | test_book_82_cover_image_invalid_mime | TC-BK-N82 | Val | 70-99 |
| 63 | test_book_83_ebook_invalid_mime | TC-BK-N83 | Val | 70-99 |
| 64 | test_book_84_ebook_exceeds_50mb | TC-BK-N84 | Val | 70-99 |
| 65 | test_book_85_author_id_required | TC-BK-N85 | Val | 70-99 |
| 66 | test_book_86_author_id_invalid_fk | TC-BK-N86 | Val | 70-99 |
| 67 | test_book_87_author_role_invalid | TC-BK-N87 | Val | 70-99 |
| 68 | test_book_88_duplicate_author_same_role | TC-BK-N88 | Val | 70-99 |
| 69 | test_book_89_class_id_required | TC-BK-N89 | Val | 70-99 |
| 70 | test_book_90_subject_id_required | TC-BK-N90 | Val | 70-99 |
| 71 | test_book_91_class_id_invalid_fk | TC-BK-N91 | Val | 70-99 |
| 72 | test_book_92_academic_session_required | TC-BK-N92 | Val | 70-99 |
| 73 | test_book_93_book_files_exceeds_20 | TC-BK-N93 | Val | 70-99 |
| 74 | test_book_94_book_files_invalid_mime | TC-BK-N94 | Val | 70-99 |
| 75 | test_book_95_tags_exceeds_50_chars | TC-BK-N95 | Val | 70-99 |
| 76 | test_book_100_show_displays_all_fields | TC-BK-P100 | Show | 100-109 |
| 77 | test_book_101_show_lists_authors_with_roles | TC-BK-P101 | Show | 100-109 |
| 78 | test_book_102_show_lists_class_subject_mappings | TC-BK-P102 | Show | 100-109 |
| 79 | test_book_103_show_lists_book_files | TC-BK-P103 | Show | 100-109 |
| 80 | test_book_104_show_lists_chapters | TC-BK-P104 | Show | 100-109 |
| 81 | test_book_105_show_cover_placeholder | TC-BK-P105 | Show | 100-109 |
| 82 | test_book_106_show_invalid_id_404 | TC-BK-N106 | Show | 100-109 |
| 83 | test_book_107_show_soft_deleted_404 | TC-BK-N107 | Show | 100-109 |
| 84 | test_book_110_edit_prefills_all_fields | TC-BK-P110 | Edit | 110-119 |
| 85 | test_book_111_edit_loads_author_rows | TC-BK-P111 | Edit | 110-119 |
| 86 | test_book_112_edit_loads_class_subject_rows | TC-BK-P112 | Edit | 110-119 |
| 87 | test_book_113_edit_loads_book_files | TC-BK-P113 | Edit | 110-119 |
| 88 | test_book_114_edit_cover_preview | TC-BK-P114 | Edit | 110-119 |
| 89 | test_book_115_edit_invalid_id_404 | TC-BK-N115 | Edit | 110-119 |
| 90 | test_book_120_update_modifies_and_logs | TC-BK-P120 | Update | 120-139 |
| 91 | test_book_121_update_replaces_authors | TC-BK-P121 | Update | 120-139 |
| 92 | test_book_122_update_replaces_class_subjects | TC-BK-P122 | Update | 120-139 |
| 93 | test_book_123_update_cover_image | TC-BK-P123 | Update | 120-139 |
| 94 | test_book_124_update_ebook | TC-BK-P124 | Update | 120-139 |
| 95 | test_book_125_update_deletes_flagged_files | TC-BK-P125 | Update | 120-139 |
| 96 | test_book_126_update_file_flags | TC-BK-P126 | Update | 120-139 |
| 97 | test_book_127_update_redirects_with_success | TC-BK-P127 | Update | 120-139 |
| 98 | test_book_128_is_primary_cascade_single | TC-BK-P128 | Update | 120-139 |
| 99 | test_book_129_duplicate_isbn_on_update | TC-BK-N129 | Update | 120-139 |
| 100 | test_book_130_update_same_validation_as_create | TC-BK-N130 | Update | 120-139 |
| 101 | test_book_140_destroy_soft_deletes | TC-BK-P140 | Destroy | 140-149 |
| 102 | test_book_141_destroy_logs_trashed | TC-BK-P141 | Destroy | 140-149 |
| 103 | test_book_142_destroy_redirects_with_success | TC-BK-P142 | Destroy | 140-149 |
| 104 | test_book_143_destroy_non_existing_404 | TC-BK-N143 | Destroy | 140-149 |
| 105 | test_book_150_trash_lists_soft_deleted | TC-BK-P150 | Trash | 150-159 |
| 106 | test_book_151_trash_has_restore_and_force_delete_buttons | TC-BK-P151 | Trash | 150-159 |
| 107 | test_book_152_trash_paginated | TC-BK-P152 | Trash | 150-159 |
| 108 | test_book_160_restore_recovers_and_logs | TC-BK-P160 | Restore | 160-169 |
| 109 | test_book_161_restore_redirects_with_success | TC-BK-P161 | Restore | 160-169 |
| 110 | test_book_162_restore_non_trashed_404 | TC-BK-N162 | Restore | 160-169 |
| 111 | test_book_170_force_delete_permanently_removes | TC-BK-P170 | ForceDel | 170-179 |
| 112 | test_book_171_force_delete_redirects | TC-BK-P171 | ForceDel | 170-179 |
| 113 | test_book_172_force_delete_non_trashed_404 | TC-BK-N172 | ForceDel | 170-179 |
| 114 | test_book_173_force_delete_referenced_blocked | TC-BK-N173 | ForceDel | 170-179 |
| 115 | test_book_180_toggle_active_to_inactive | TC-BK-P180 | Toggle | 180-189 |
| 116 | test_book_181_toggle_inactive_to_active | TC-BK-P181 | Toggle | 180-189 |
| 117 | test_book_182_toggle_returns_json | TC-BK-P182 | Toggle | 180-189 |
| 118 | test_book_183_toggle_logs_activity | TC-BK-P183 | Toggle | 180-189 |
| 119 | test_book_90_records_are_tenant_scoped | TC-BK-T90 | Tenancy | 90-99 |
| 120 | test_book_91_stored_xss_is_escaped | TC-BK-P91 | Security | 90-99 |
| 121 | test_book_92_media_fields_not_spoofable | TC-BK-P92 | Security | 90-99 |

**Total: 121 methods (114 Automated, 7 Planned).**
