# SLK — Syllabus Books
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** SLK | **Laravel Module:** `SyllabusBooks` | **Table Prefix:** `slb_*` / `bok_*`
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x | **Tenancy:** stancl/tenancy v3.9 | **Modules:** nwidart/laravel-modules v12

---

## 1. Executive Summary

SyllabusBooks (SLK) manages the curriculum book catalog for K-12 schools on the Prime-AI platform. It provides a central registry of textbooks and reference publications, allows schools to assign books to class-subject-session combinations, maps book chapters to syllabus topics, and supports the full lifecycle (create, edit, soft delete, restore, force delete) for books and authors.

**Current completion: ~55%.** The core author and book CRUD is functional (BookController and AuthorController are implemented with auth guards). However, the module carries three critical architectural and security issues that must be resolved before production:

1. **`SyllabusBooksController` is a dead stub** — `store()`, `update()`, `destroy()` return nothing; all book creation and editing flows through `BookController` instead, making the dashboard controller unusable for write operations.
2. **`BookTopicMappingController::index()` references undefined `$bookTopicMappings`** — the index page throws a PHP undefined variable error on every load.
3. **Cross-layer boundary violation** — `BookController`, `BookClassSubject` model, and `BookController::update()` all import `Modules\Prime\Models\AcademicSession`, which resolves to `glb_academic_sessions` on the `global_master_mysql` connection. A tenant module must not reach into the central Prime/Global layer for session data; the FK `slb_book_class_subject_jnt.academic_session_id` already points to `sch_org_academic_sessions_jnt` in the tenant DB, and all session lookups must use the tenant-scoped `OrganizationAcademicSession` model.

Additional gaps: no `EnsureTenantHasModule` middleware, no service layer, zero test coverage, module-specific `MediaFiles` model instead of shared `sys_media`, and a naming inconsistency between the `BokBook` model class and its `slb_books` table.

**V2 target: production-ready SLK at 100%.** All gaps below are classified by priority (P0–P3).

---

## 2. Module Overview

### 2.1 Purpose

SyllabusBooks bridges two concerns:
- **Book Catalog** — Maintain the master registry of textbooks, reference books, and supplementary publications used across a school's curriculum (NCERT, CBSE-recommended, state board, commercial publishers).
- **Curriculum Assignment** — Assign specific books from the catalog to class + subject + academic session per tenant, distinguishing primary textbooks from reference books, and flagging mandatory vs optional copies.
- **Topic Mapping** — Link specific book chapters/pages to syllabus topics in the `slb_topics` hierarchy, enabling lesson-level traceability from content to source material.

### 2.2 Architecture Position

```
Layer              Model / Table                       Connection
────────────────────────────────────────────────────────────────────────
Tenant DB          slb_book_authors                    tenant_mysql
                   slb_books                           tenant_mysql
                   slb_book_author_jnt                 tenant_mysql
                   slb_book_class_subject_jnt          tenant_mysql
                   bok_book_topic_mapping              tenant_mysql
────────────────────────────────────────────────────────────────────────
Cross-ref (OK)     sch_classes, sch_subjects           tenant_mysql
                   sch_org_academic_sessions_jnt       tenant_mysql
                   slb_topics (Syllabus module)        tenant_mysql
                   sys_dropdown_table                  tenant_mysql
Cross-ref (WRONG)  glb_academic_sessions (PRIME layer) global_master_mysql  ← REMOVE
```

### 2.3 Module Characteristics

| Attribute           | Value                                                         |
|---------------------|---------------------------------------------------------------|
| Laravel Module      | `SyllabusBooks` (nwidart v12)                                 |
| Namespace           | `Modules\SyllabusBooks`                                       |
| Module Code         | SLK                                                           |
| DB Connection       | `tenant_mysql` (tenant_{uuid}) for all tables                 |
| Primary Prefix      | `slb_*` (shared with Syllabus module for books/authors)       |
| Secondary Prefix    | `bok_*` (book-topic mapping table only)                       |
| Auth Guard          | `tenant.` permission prefix via Spatie + Gate::authorize()    |
| Frontend            | Bootstrap 5 + AdminLTE 4                                      |
| Completion Status   | ~55%                                                          |
| Controllers         | 4 (SyllabusBooksController stub + 3 functional)               |
| Models              | 6 in SyllabusBooks namespace                                  |
| Services            | 0 (none — all logic inline in controllers)                    |
| FormRequests        | 3 (BookRequest, AuthorRequest, BookTopicMappingRequest)        |
| Tests               | 0                                                             |

### 2.4 Sub-Feature Areas

| # | Feature Area              | Status |
|---|---------------------------|--------|
| 1 | Book Author Management    | 🟡 Partial (auth ok; store/update missing activityLog; model naming) |
| 2 | Book Catalog Management   | 🟡 Partial (CRUD functional; AcademicSession cross-layer; media inconsistency) |
| 3 | Book-Author Junction      | 🟡 Partial (sync via raw DB insert; no ordinal support in UI) |
| 4 | Book-Class Assignment     | 🟡 Partial (inline raw inserts; cross-layer session FK) |
| 5 | Book-Topic Mapping        | ❌ Broken (undefined variable in index; bok_ table not in DDL v2) |
| 6 | SyllabusBooksController   | ❌ Stub (store/update/destroy empty) |
| 7 | Service Layer             | ❌ Not started |
| 8 | EnsureTenantHasModule     | ❌ Not applied |
| 9 | Test Coverage             | ❌ Zero tests |

---

## 3. Stakeholders & Roles

### 3.1 Primary Actors

| Actor                | Description                                     | Scope                              |
|----------------------|-------------------------------------------------|------------------------------------|
| Super Admin          | Platform operator                               | Full CRUD on all book data         |
| Platform Manager     | Manages national curriculum content             | Full CRUD on books and authors     |
| School Admin         | Tenant administrator                            | Assign books; view catalog         |
| Academic Coordinator | Manages school curriculum                       | Assign books; create topic maps    |
| Teacher              | Consumes assigned book list                     | Read-only                          |
| Student / Parent     | Views class book list (via portal)              | Read-only (via portal layer)       |

### 3.2 Permission Naming — Current vs Proposed

| Controller        | Current Permission String            | Proposed Standard (V2)                           |
|-------------------|--------------------------------------|--------------------------------------------------|
| BookController    | `tenant.book.viewAny`                | `tenant.syllabus-books.book.viewAny`             |
| BookController    | `tenant.book.create`                 | `tenant.syllabus-books.book.create`              |
| BookController    | `tenant.book.update`                 | `tenant.syllabus-books.book.update`              |
| BookController    | `tenant.book.delete`                 | `tenant.syllabus-books.book.delete`              |
| BookController    | `tenant.book.restore`                | `tenant.syllabus-books.book.restore`             |
| BookController    | `tenant.book.forceDelete`            | `tenant.syllabus-books.book.forceDelete`         |
| AuthorController  | `tenant.author.viewAny`              | `tenant.syllabus-books.author.viewAny`           |
| AuthorController  | `tenant.author.create`               | `tenant.syllabus-books.author.create`            |
| AuthorController  | `tenant.author.update`               | `tenant.syllabus-books.author.update`            |
| AuthorController  | `tenant.author.delete`               | `tenant.syllabus-books.author.delete`            |
| AuthorController  | `tenant.author.restore`              | `tenant.syllabus-books.author.restore`           |
| BookTopicMapping  | Policy-based (via Gate::authorize)   | `tenant.syllabus-books.book-topic-mapping.*`     |

> V2 must namespace all permissions under `tenant.syllabus-books.*` to avoid collisions with other modules that may also have generic `tenant.book.*` or `tenant.author.*` strings.

---

## 4. Functional Requirements

### FR-SLK-01: Book Author Management
**Status:** 🟡 Partial

**FR-SLK-01.1 — Create Author** ✅
- Fields: `name` (required, unique, max 150), `qualification` (nullable, max 200), `bio` (nullable, text)
- `Gate::authorize('tenant.author.create')` enforced in `create()` method
- `AuthorRequest` FormRequest validates all fields
- Author name uniqueness enforced at DB level (`UNIQUE KEY uq_author_name`)

**FR-SLK-01.2 — Edit Author** ✅
- `Gate::authorize('tenant.author.update')` enforced in `edit()` and (via AuthorRequest) `update()`
- Returns redirect to `syllabus-books.index` on success

**FR-SLK-01.3 — Delete Author (Soft)** ✅
- Sets `is_active = false` before `delete()` (soft delete via SoftDeletes trait)
- `Gate::authorize('tenant.author.delete')` enforced
- Activity log written via `activityLog()` helper

**FR-SLK-01.4 — Restore Author** ✅
- `BookAuthors::withTrashed()->findOrFail($id)->restore()`
- `Gate::authorize('tenant.author.restore')` enforced
- Activity log written on restore

**FR-SLK-01.5 — Force Delete Author** ✅
- Wrapped in `DB::transaction()`
- Cleans up `slb_book_author_jnt` rows before `forceDelete()`
- `Gate::authorize('tenant.author.forceDelete')` enforced
- Activity log written

**FR-SLK-01.6 — Toggle Author Status** ✅
- Returns JSON `{success, is_active, message}`
- `Gate::authorize('tenant.author.update')` enforced

**FR-SLK-01.7 — View Trashed Authors** ✅
- `BookAuthors::onlyTrashed()->paginate(10)` via `trashedAuthor()` method

**Gaps in FR-SLK-01:**
- 🟡 `store()` has NO `Gate::authorize` call — only `create()` has it. The gate can be bypassed by POSTing directly to the store route.
- 🟡 `store()` and `update()` do not write activity logs (unlike `destroy()` and `restore()` which do).
- ❌ `AuthorController::index()` loads `BokBook::query()` (book data) not author data — the index is rendering books, not authors. This is a copy-paste logic error.
- 📐 Proposed V2: Add `Gate::authorize('tenant.author.create')` to `store()`, add `activityLog()` to `store()` and `update()`, fix `index()` to query `BookAuthors` not `BokBook`.

---

### FR-SLK-02: Book Catalog Management
**Status:** 🟡 Partial

**FR-SLK-02.1 — Create Book** 🟡
- `BookRequest` FormRequest validates all fields including nested `authors[]` and `class_subjects[]` arrays
- `Gate::authorize('tenant.book.create')` enforced in `create()`
- Cover image upload stores to `public` disk via `MediaFiles::create()` (module-specific media model — see gap below)
- UUID auto-generated in `BokBook::booted()` on creating event
- Tags handled as comma-separated string in `prepareForValidation()`, converted to array

**FR-SLK-02.2 — ISBN Uniqueness** 🟡
- DB-level: `UNIQUE KEY uq_book_isbn` on `slb_books.isbn`
- Manual controller-level check at `BookController::store()` line 121 (race condition possible — see gap)
- `BookRequest` does NOT include `unique:slb_books,isbn` rule (gap)

**FR-SLK-02.3 — Book Flags (NCERT / CBSE)** ✅
- `is_ncert` and `is_cbse_recommended` as `TINYINT(1)` with cast to boolean
- `prepareForValidation()` uses `$this->has('is_ncert')` to handle checkbox absence

**FR-SLK-02.4 — Author Attachment on Book Create/Update** 🟡
- Authors inserted via raw `DB::table('slb_book_author_jnt')->insert()`
- Duplicate author detection (same author_id + role) throws `ValidationException`
- On update: full delete-and-re-insert pattern (wipes all existing author links, then re-inserts)
- Ordinal column exists in DDL but is never set in the insert array (always defaults to 1)

**FR-SLK-02.5 — Class-Subject Assignment on Book Create/Update** ❌ (Critical)
- Assignments inserted via raw `DB::table('slb_book_class_subject_jnt')->insert()`
- Uses `AcademicSession::where('is_current', 1)->value('id')` — this queries `glb_academic_sessions` on `global_master_mysql` — WRONG for a tenant module
- `academic_session_id` FK in DDL points to `sch_org_academic_sessions_jnt` (tenant table), but code is reading from the Prime/Global layer
- On update: full delete-and-re-insert for class_subjects (same as authors)

**FR-SLK-02.6 — Edit Book** 🟡
- `Gate::authorize('tenant.book.update')` enforced
- Same cross-layer session issue as store

**FR-SLK-02.7 — Delete / Restore / Force Delete** ✅
- Soft delete sets `is_active = false` before `delete()`
- Force delete cleans author_jnt and class_subject_jnt rows in transaction
- All methods have `Gate::authorize()`
- Activity logs written on all three operations

**FR-SLK-02.8 — Book Cover Image** 🟡
- Uploaded to `public` disk under `books/` subdirectory
- Reference saved via module-specific `MediaFiles` model (table `media_files` or similar) — NOT using shared `sys_media` / `qns_media_store` approach
- DDL defines `cover_image_media_id FK → qns_media_store.id` but code creates a `MediaFiles` record in a different table
- This is an architectural inconsistency: the FK constraint in DDL will fail unless `qns_media_store` is populated

**Gaps in FR-SLK-02:**
- ❌ Cross-layer `AcademicSession` usage must be replaced with `OrganizationAcademicSession` (tenant-scoped)
- ❌ Cover image saved to `MediaFiles` (module table) but DDL FK points to `qns_media_store`
- 🟡 ISBN uniqueness check is inline in controller rather than in `BookRequest` — race condition under concurrent requests
- 🟡 No activity log on `store()` (book creation)
- 🟡 `Dropdown::all()` in `index()` loads all dropdowns — should filter by key `'language'`

---

### FR-SLK-03: Book-Author Junction Management
**Status:** 🟡 Partial

**FR-SLK-03.1 — Multi-author support** ✅
- `slb_book_author_jnt` with composite PK `(book_id, author_id)`
- `author_role` ENUM: `PRIMARY | CO_AUTHOR | EDITOR | CONTRIBUTOR`
- `ordinal` TINYINT for display order

**FR-SLK-03.2 — Author role validation** ✅
- `BookRequest` validates `authors.*.author_role` with `in:PRIMARY,CO_AUTHOR,EDITOR,CONTRIBUTOR`

**FR-SLK-03.3 — Duplicate author guard** ✅
- Controller-level duplicate check (same `author_id + role` key) — throws `ValidationException`
- Also catches DB-level `Duplicate entry` on `slb_book_author_jnt.PRIMARY` constraint

**Gaps in FR-SLK-03:**
- 🟡 `ordinal` is never populated (raw insert always omits it, defaulting to 1)
- 🟡 No standalone Author-Book assignment endpoint — author changes only possible by editing the whole book

---

### FR-SLK-04: Book-Class-Subject Assignment
**Status:** ❌ Cross-layer bug

**FR-SLK-04.1 — Assignment fields** ✅ (schema correct)
- `slb_book_class_subject_jnt`: `book_id`, `class_id`, `subject_id`, `academic_session_id`, `is_primary`, `is_mandatory`, `remarks`, `is_active`
- UNIQUE KEY on `(book_id, class_id, subject_id, academic_session_id)`

**FR-SLK-04.2 — Assignment creation** ❌
- Inline raw insert; `academic_session_id` sourced from `AcademicSession` (Prime/Global layer)
- Must be changed to `OrganizationAcademicSession::where('is_current', 1)->value('id')`

**FR-SLK-04.3 — Primary book rule** ❌
- `is_primary` flag exists in schema but **no enforcement** of "only one primary per class/subject/session"
- A second primary assignment can be inserted silently; the system does not demote the existing primary

**FR-SLK-04.4 — Mandatory flag** ✅ (schema level only)
- `is_mandatory` stored correctly; no business-level enforcement logic yet

**FR-SLK-04.5 — Academic year book list** ❌ Not started
- No "copy book list from previous session" feature
- No "generate book list PDF for parents" feature
- No "compare book list across sessions" feature

**Gaps in FR-SLK-04:**
- ❌ Replace `AcademicSession` (Prime layer) with `OrganizationAcademicSession` (tenant layer)
- ❌ Enforce unique-primary rule: before inserting `is_primary=1`, demote existing primary to `is_primary=0`
- 📐 Propose: `BookAssignmentService` to encapsulate assignment logic and primary-book enforcement
- 📐 Propose: book list copy-forward utility for new academic year setup

---

### FR-SLK-05: Book-Topic Mapping
**Status:** ❌ Broken

**FR-SLK-05.1 — Mapping fields** ✅ (model correct)
- `bok_book_topic_mapping` table (module migration `.bk` file — not yet in `tenant_db_v2.sql`)
- Fields: `book_id`, `topic_id`, `chapter_number`, `chapter_title`, `page_start`, `page_end`, `section_reference`, `remarks`, `is_active`
- Supports `SoftDeletes`

**FR-SLK-05.2 — Controller index broken** ❌
- `BookTopicMappingController::index()` passes `compact('bookTopicMappings', 'books', 'authors')` but `$bookTopicMappings` is never assigned — PHP `Undefined variable` error on every page load

**FR-SLK-05.3 — Gate::authorize present** ✅
- All 10 methods in `BookTopicMappingController` call `Gate::authorize()` (contrary to V1 gap analysis which stated zero auth — this has been partially addressed)
- `index()`, `create()`, `store()`, `edit()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, `toggleStatus()`, `trashedBookTopicMapping()` all have Gate calls

**FR-SLK-05.4 — CRUD operations** 🟡
- `store()`: `BookTopicMapping::create($request->validated())` — correct
- `update()`: `$bookTopicMapping->update($request->validated())` — correct
- `destroy()`: soft delete + activityLog — correct
- `restore()`: restore + activityLog — correct
- `forceDelete()`: hard delete + activityLog — correct

**FR-SLK-05.5 — Missing `bok_book_topic_mapping` DDL in tenant_db_v2.sql** ❌
- The migration file exists as `.bk` (backup, not active) and references `bok_books` and `bok_topics` tables that do not exist
- DDL v2 has no `bok_book_topic_mapping` table
- Model correctly maps to `bok_book_topic_mapping` table
- Topic FK references `Modules\Syllabus\Models\Topic` (which uses `slb_topics` table) — correct cross-module reference

**Gaps in FR-SLK-05:**
- ❌ Fix undefined variable in `index()` — assign `$bookTopicMappings = BookTopicMapping::with(['book','topic'])->paginate(11)`
- ❌ Add `bok_book_topic_mapping` table to `tenant_db_v2.sql` DDL with correct FKs to `slb_books` and `slb_topics`
- ❌ Activate the migration (remove `.bk` extension or create new migration)
- ❌ `BookTopicMappingRequest` missing `exists` rules on `book_id` and `topic_id`
- 📐 Propose: page range validation — `page_end` must be ≤ `book.total_pages` when `total_pages` is set

---

### FR-SLK-06: SyllabusBooksController (Dashboard)
**Status:** ❌ Stub

**FR-SLK-06.1 — Index** 🟡
- `index()` loads `BokBook::paginate(10)` and `BookAuthors::paginate(10)` — functional but has no auth gate
- Renders `syllabusbooks::syllabus-book.index`

**FR-SLK-06.2 — Store / Update / Destroy** ❌
- All three methods are empty (return nothing implicitly)
- These should either be removed (and routing consolidated under BookController) or implemented

**Gaps in FR-SLK-06:**
- 📐 V2 Decision required: deprecate `SyllabusBooksController` as a routing hub (keep only `index()`) and rely entirely on `BookController`, `AuthorController`, `BookTopicMappingController` for all CRUD
- ❌ `index()` has no `Gate::authorize()` call
- ❌ Routes registered in module's `routes/web.php` overlap with `tenant.php` routes — stub routes should be removed

---

### FR-SLK-07: Book Search & Cross-Module API
**Status:** ❌ Not started

**FR-SLK-07.1 — Internal AJAX endpoint** ❌
- `Syllabus/LessonController::getBooks()` queries books for class/subject dropdown in lesson creation
- This is an internal AJAX call on the Syllabus module's web route, not a formal SLK API
- No dedicated `/api/v1/syllabus-books/` REST endpoints exist

**FR-SLK-07.2 — Book search endpoint** ❌
- No endpoint to search books by title, ISBN, or publisher for cross-module consumption
- `BookController::index()` supports search filters but is a web/HTML response, not JSON

**Gaps in FR-SLK-07:**
- 📐 Propose: `GET /api/v1/books?title=&isbn=&class_id=&subject_id=&session_id=` (JSON)
- 📐 Propose: `GET /api/v1/books/{book}` for book detail lookup

---

### FR-SLK-08: EnsureTenantHasModule Middleware
**Status:** ❌ Not applied

- The `syllabus-books` route group in `tenant.php` uses only `['auth', 'verified']` middleware
- No `EnsureTenantHasModule` middleware is applied to gate access by subscription
- A tenant without the SyllabusBooks license can freely access all routes

**Gap:** Add `EnsureTenantHasModule:SyllabusBooks` (or the platform's equivalent middleware) to the route group.

---

## 5. Data Model

### 5.1 Tables — DDL Source: tenant_db_v2.sql

#### `slb_book_authors`
| Column         | Type             | Constraints                    |
|----------------|------------------|--------------------------------|
| id             | INT UNSIGNED AI  | PK                             |
| name           | VARCHAR(150)     | NOT NULL, UNIQUE (uq_author_name) |
| qualification  | VARCHAR(200)     | nullable                       |
| bio            | TEXT             | nullable                       |
| is_active      | TINYINT(1)       | DEFAULT 1                      |
| created_at     | TIMESTAMP        |                                |
| updated_at     | TIMESTAMP        |                                |
| deleted_at     | TIMESTAMP        | nullable (soft delete)         |

> Note: DDL does NOT have `created_by` / `updated_by` columns, but `BookAuthors` model has `createdBy()` and `updatedBy()` relationships. These columns either need to be added to DDL or the relationships removed from the model.

#### `slb_books`
| Column                | Type             | Constraints                                  |
|-----------------------|------------------|----------------------------------------------|
| id                    | INT UNSIGNED AI  | PK                                           |
| uuid                  | BINARY(16)       | NOT NULL, UNIQUE (uq_book_uuid)              |
| isbn                  | VARCHAR(20)      | nullable, UNIQUE (uq_book_isbn)              |
| title                 | VARCHAR(100)     | NOT NULL, KEY idx_book_title                 |
| subtitle              | VARCHAR(255)     | nullable                                     |
| description           | VARCHAR(512)     | nullable                                     |
| edition               | VARCHAR(50)      | nullable                                     |
| publication_year      | YEAR             | nullable, KEY idx_book_year                  |
| publisher_name        | VARCHAR(150)     | nullable, KEY idx_book_publisher             |
| language              | INT UNSIGNED     | FK → sys_dropdown_table.id                   |
| total_pages           | INT UNSIGNED     | nullable                                     |
| cover_image_media_id  | INT UNSIGNED     | nullable, FK → qns_media_store.id            |
| tags                  | JSON             | nullable                                     |
| is_ncert              | TINYINT(1)       | DEFAULT 0                                    |
| is_cbse_recommended   | TINYINT(1)       | DEFAULT 0                                    |
| is_active             | TINYINT(1)       | DEFAULT 1                                    |
| created_at            | TIMESTAMP        |                                              |
| updated_at            | TIMESTAMP        |                                              |
| deleted_at            | TIMESTAMP        | nullable (soft delete)                       |

> Note: DDL does NOT have `created_by` / `updated_by` columns, but `BokBook` model has `createdBy()` / `updatedBy()` relationships. These columns are either missing from DDL or the model relationships are premature.

#### `slb_book_author_jnt`
| Column      | Type             | Constraints                               |
|-------------|------------------|-------------------------------------------|
| book_id     | INT UNSIGNED     | PK part 1, FK → slb_books.id             |
| author_id   | INT UNSIGNED     | PK part 2, FK → slb_book_authors.id      |
| author_role | ENUM             | PRIMARY / CO_AUTHOR / EDITOR / CONTRIBUTOR, DEFAULT 'PRIMARY' |
| ordinal     | TINYINT UNSIGNED | DEFAULT 1                                 |

#### `slb_book_class_subject_jnt`
| Column               | Type         | Constraints                                         |
|----------------------|--------------|-----------------------------------------------------|
| id                   | INT UNSIGNED | PK AI                                               |
| book_id              | INT UNSIGNED | FK → slb_books.id                                   |
| class_id             | INT UNSIGNED | FK → sch_classes.id                                 |
| subject_id           | INT UNSIGNED | FK → sch_subjects.id                                |
| academic_session_id  | INT UNSIGNED | FK → sch_org_academic_sessions_jnt.id               |
| is_primary           | TINYINT(1)   | DEFAULT 1                                           |
| is_mandatory         | TINYINT(1)   | DEFAULT 1                                           |
| remarks              | VARCHAR(255) | nullable                                            |
| is_active            | TINYINT(1)   | DEFAULT 1                                           |
| created_at / updated_at / deleted_at | TIMESTAMP | soft delete |
| UNIQUE KEY | (book_id, class_id, subject_id, academic_session_id) |  |

#### `bok_book_topic_mapping` (📐 Needs DDL addition)
| Column            | Type         | Constraints                     |
|-------------------|--------------|---------------------------------|
| id                | BIGINT AI    | PK                              |
| book_id           | INT UNSIGNED | FK → slb_books.id, RESTRICT     |
| topic_id          | INT UNSIGNED | FK → slb_topics.id, RESTRICT    |
| chapter_number    | VARCHAR(20)  | nullable                        |
| chapter_title     | VARCHAR(255) | nullable                        |
| page_start        | INT UNSIGNED | nullable                        |
| page_end          | INT UNSIGNED | nullable                        |
| section_reference | VARCHAR(100) | nullable                        |
| remarks           | VARCHAR(255) | nullable                        |
| is_active         | TINYINT(1)   | DEFAULT 1                       |
| created_at / updated_at / deleted_at | TIMESTAMP | soft delete |

> This table is defined in the module migration (`.bk` file) but is absent from `tenant_db_v2.sql`. The migration must be activated and the DDL updated.

### 5.2 Models

| Model            | Table                       | Namespace                        | Status  |
|------------------|-----------------------------|----------------------------------|---------|
| `BokBook`        | `slb_books`                 | `Modules\SyllabusBooks\Models`   | ✅ OK (naming mismatch with prefix) |
| `BookAuthors`    | `slb_book_authors`          | `Modules\SyllabusBooks\Models`   | 🟡 Plural name; missing created_by in fillable |
| `BookAuthorJnt`  | `slb_book_author_jnt`       | `Modules\SyllabusBooks\Models`   | 🟡 Used only via raw DB insert |
| `BookClassSubject`| `slb_book_class_subject_jnt`| `Modules\SyllabusBooks\Models`  | ❌ Imports wrong AcademicSession |
| `BookTopicMapping`| `bok_book_topic_mapping`   | `Modules\SyllabusBooks\Models`   | ❌ Table not in DDL v2 |
| `MediaFiles`     | module-specific table       | `Modules\SyllabusBooks\Models`   | ❌ Should use `sys_media` / `qns_media_store` |

### 5.3 Key Relationships

```
slb_books (N) ←─── (N) slb_book_authors      [via slb_book_author_jnt]
slb_books (N) ─────(N) sch_classes            [via slb_book_class_subject_jnt]
slb_books (N) ─────(N) sch_subjects           [via slb_book_class_subject_jnt]
slb_books (N) ─────(N) slb_topics             [via bok_book_topic_mapping]
slb_books (1) ←─── (N) slb_book_class_subject_jnt.academic_session_id → sch_org_academic_sessions_jnt
slb_lessons.bok_books_id ────(N)→(1) slb_books
qns_questions_bank.book_id ──(N)→(1) slb_books
```

### 5.4 External FK Dependencies

| Column                                              | References                              | Layer   |
|-----------------------------------------------------|-----------------------------------------|---------|
| `slb_books.language`                                | `sys_dropdown_table.id`                 | Tenant  |
| `slb_books.cover_image_media_id`                    | `qns_media_store.id`                    | Tenant  |
| `slb_book_class_subject_jnt.class_id`               | `sch_classes.id`                        | Tenant  |
| `slb_book_class_subject_jnt.subject_id`             | `sch_subjects.id`                       | Tenant  |
| `slb_book_class_subject_jnt.academic_session_id`    | `sch_org_academic_sessions_jnt.id`      | Tenant  |
| `bok_book_topic_mapping.book_id`                    | `slb_books.id`                          | Tenant  |
| `bok_book_topic_mapping.topic_id`                   | `slb_topics.id`                         | Tenant  |
| `slb_lessons.bok_books_id`                          | `slb_books.id`                          | Tenant (consumer) |
| `qns_questions_bank.book_id`                        | `slb_books.id`                          | Tenant (consumer) |

---

## 6. API Endpoints & Routes

### 6.1 Current Web Routes (tenant.php)

Route group: `middleware(['auth', 'verified'])`, prefix `syllabus-books`, name prefix `syllabus-books.`

| Method | URI                                         | Controller Method                    | Name                                  |
|--------|---------------------------------------------|--------------------------------------|---------------------------------------|
| GET    | /syllabus-books/                            | SyllabusBooksController@index        | syllabus-books.index                  |
| GET    | /syllabus-books/authors                     | AuthorController@index               | syllabus-books.authors.index          |
| GET    | /syllabus-books/authors/create              | AuthorController@create              | syllabus-books.authors.create         |
| POST   | /syllabus-books/authors                     | AuthorController@store               | syllabus-books.authors.store          |
| GET    | /syllabus-books/authors/{author}            | AuthorController@show                | syllabus-books.authors.show           |
| GET    | /syllabus-books/authors/{author}/edit       | AuthorController@edit                | syllabus-books.authors.edit           |
| PUT    | /syllabus-books/authors/{author}            | AuthorController@update              | syllabus-books.authors.update         |
| DELETE | /syllabus-books/authors/{author}            | AuthorController@destroy             | syllabus-books.authors.destroy        |
| GET    | /syllabus-books/authors/trash/view          | AuthorController@trashedAuthor       | syllabus-books.authors.trashed        |
| GET    | /syllabus-books/authors/{id}/restore        | AuthorController@restore             | syllabus-books.authors.restore        |
| DELETE | /syllabus-books/authors/{id}/force-delete   | AuthorController@forceDelete         | syllabus-books.authors.forceDelete    |
| POST   | /syllabus-books/authors/{author}/toggle-status | AuthorController@toggleStatus     | syllabus-books.authors.toggleStatus   |
| GET    | /syllabus-books/books                       | BookController@index                 | syllabus-books.books.index            |
| GET    | /syllabus-books/books/create                | BookController@create                | syllabus-books.books.create           |
| POST   | /syllabus-books/books                       | BookController@store                 | syllabus-books.books.store            |
| GET    | /syllabus-books/books/{book}                | BookController@show                  | syllabus-books.books.show             |
| GET    | /syllabus-books/books/{book}/edit           | BookController@edit                  | syllabus-books.books.edit             |
| PUT    | /syllabus-books/books/{book}                | BookController@update                | syllabus-books.books.update           |
| DELETE | /syllabus-books/books/{book}                | BookController@destroy               | syllabus-books.books.destroy          |
| GET    | /syllabus-books/books/trash/view            | BookController@trashedBook           | syllabus-books.books.trashed          |
| GET    | /syllabus-books/books/{id}/restore          | BookController@restore               | syllabus-books.books.restore          |
| DELETE | /syllabus-books/books/{id}/force-delete     | BookController@forceDelete           | syllabus-books.books.forceDelete      |
| POST   | /syllabus-books/books/{book}/toggle-status  | BookController@toggleStatus          | syllabus-books.books.toggleStatus     |
| GET    | /syllabus-books/book-topic-mappings         | BookTopicMappingController@index     | syllabus-books.book-topic-mappings.index |
| POST   | /syllabus-books/book-topic-mappings         | BookTopicMappingController@store     | syllabus-books.book-topic-mappings.store |
| GET    | /syllabus-books/book-topic-mappings/create  | BookTopicMappingController@create    | syllabus-books.book-topic-mappings.create |
| GET    | /syllabus-books/book-topic-mappings/{id}/edit | BookTopicMappingController@edit    | syllabus-books.book-topic-mappings.edit |
| PUT    | /syllabus-books/book-topic-mappings/{id}    | BookTopicMappingController@update    | syllabus-books.book-topic-mappings.update |
| DELETE | /syllabus-books/book-topic-mappings/{id}    | BookTopicMappingController@destroy   | syllabus-books.book-topic-mappings.destroy |
| GET    | /syllabus-books/book-topic-mappings/trash/view | BookTopicMappingController@trashedBookTopicMapping | syllabus-books.book-topic-mappings.trashed |
| GET    | /syllabus-books/book-topic-mappings/{id}/restore | BookTopicMappingController@restore | syllabus-books.book-topic-mappings.restore |
| DELETE | /syllabus-books/book-topic-mappings/{id}/force-delete | BookTopicMappingController@forceDelete | syllabus-books.book-topic-mappings.forceDelete |
| POST   | /syllabus-books/book-topic-mappings/{id}/toggle-status | BookTopicMappingController@toggleStatus | syllabus-books.book-topic-mappings.toggleStatus |

### 6.2 Route Issues

| Issue | Priority | Description |
|-------|----------|-------------|
| No `EnsureTenantHasModule` | ❌ P1 | Route group only has `auth` + `verified` — no module license check |
| Stub overlap | 🟡 P3 | Module's own `routes/web.php` registers a stub `syllabusbooks` resource that overlaps with tenant.php |
| Route naming inconsistency | 🟡 P2 | `SyllabusBooksController` registered as `syllabusbooks` in web.php vs `syllabus-books` in tenant.php |

### 6.3 Proposed REST API Endpoints (📐 New in V2)

| Method | URI                                     | Description                                        |
|--------|-----------------------------------------|----------------------------------------------------|
| GET    | /api/v1/books                           | Search books; params: title, isbn, publisher, class_id, subject_id, session_id |
| GET    | /api/v1/books/{id}                      | Book detail with authors and class-subject list    |
| GET    | /api/v1/books/{id}/assignments          | List all class-subject-session assignments for a book |
| GET    | /api/v1/class-book-list?class_id=&session_id= | Book list for a class/session (for student portal / PDF) |

---

## 7. UI Screens

### 7.1 Existing Screens

| Screen | View Path | Controller | Status |
|--------|-----------|------------|--------|
| Dashboard / Index | `syllabusbooks::syllabus-book.index` | SyllabusBooksController@index | 🟡 Loads; no auth gate |
| Author Create | `syllabusbooks::author.create` | AuthorController@create | ✅ |
| Author Edit | `syllabusbooks::author.edit` | AuthorController@edit | ✅ |
| Author Show | `syllabusbooks::author.show` | AuthorController@show | ✅ |
| Author Trash | `syllabusbooks::author.trash` | AuthorController@trashedAuthor | ✅ |
| Book Create | `syllabusbooks::book.create` | BookController@create | 🟡 Cross-layer session |
| Book Edit | `syllabusbooks::book.edit` | BookController@edit | 🟡 Cross-layer session |
| Book Show | `syllabusbooks::book.show` | BookController@show | ✅ |
| Book Trash | `syllabusbooks::book.trash` | BookController@trashedBook | ✅ |
| Topic Mapping Create | `syllabusbooks::book-topic-mapping.create` | BookTopicMappingController@create | 🟡 |
| Topic Mapping Edit | `syllabusbooks::book-topic-mapping.edit` | BookTopicMappingController@edit | 🟡 |
| Topic Mapping Trash | `syllabusbooks::book-topic-mapping.trash` | BookTopicMappingController@trashedBookTopicMapping | 🟡 |
| Topic Mapping Index | `syllabusbooks::syllabus-book.index` | BookTopicMappingController@index | ❌ Undefined variable |

### 7.2 Missing / Proposed Screens (📐 New in V2)

| Screen | Description |
|--------|-------------|
| Book Assignment Manager | Dedicated screen to manage class-subject-session assignments for a book; shows primary/reference/mandatory flags clearly |
| Book List by Class | View all books assigned to a specific class + session; exportable as PDF for parent distribution |
| Topic Mapping Index (fixed) | Fixed `index()` — display all topic mappings with book and topic names, paginated |
| Book Import | Bulk import books from CSV for new academic year setup |

---

## 8. Business Rules

**BR-SLK-01:** An ISBN, when provided, must be globally unique across all books in the tenant's catalog. Validated at DB level (`UNIQUE KEY`) and at application level in `BookRequest` (V2: move uniqueness rule to FormRequest, add `unique:slb_books,isbn,{id}` on update).

**BR-SLK-02:** A book cannot be force-deleted if active lesson references exist (`slb_lessons.bok_books_id`). Check before `forceDelete()` and return error if references are found. (Not yet implemented.)

**BR-SLK-03:** A book cannot be force-deleted if active question-bank references exist (`qns_questions_bank.book_id`). Same pattern as BR-SLK-02. (Not yet implemented.)

**BR-SLK-04:** An author cannot be force-deleted if they have book associations in `slb_book_author_jnt`. Current code deletes junction rows before force-deleting — V2 must decide: block deletion (maintain audit trail) or cascade (current behavior). Recommended: block unless junction rows are also soft-deleted.

**BR-SLK-05:** Each class-subject-session combination may have at most ONE book with `is_primary = 1`. When assigning a new primary book, the service must check for and demote any existing primary assignment for the same class-subject-session tuple. (Not yet implemented.)

**BR-SLK-06:** `author_role` in `slb_book_author_jnt` must be one of: `PRIMARY`, `CO_AUTHOR`, `EDITOR`, `CONTRIBUTOR`. Enforced in `BookRequest` validation and DB ENUM.

**BR-SLK-07:** The `academic_session_id` in `slb_book_class_subject_jnt` must reference a valid tenant-scoped session from `sch_org_academic_sessions_jnt`, NOT from the Prime/Global `glb_academic_sessions` table.

**BR-SLK-08:** Book topic mapping page range must be valid: `page_start` <= `page_end`. When the book has `total_pages` set, `page_end` must not exceed `total_pages`. Partially enforced in `BookTopicMappingRequest` (`page_end` has `gte:page_start`).

**BR-SLK-09:** A book title is required and must not exceed 100 characters (DDL constraint). ISBN, when provided, must not exceed 20 characters.

**BR-SLK-10:** Cover images must be stored via the shared `qns_media_store` table (aligned with the DDL FK constraint). The current `MediaFiles` custom model must be replaced.

**BR-SLK-11:** All destructive operations (delete, restore, force delete, toggle status) must generate an activity log entry via the platform's `activityLog()` helper. Currently `AuthorController::store()` and `update()`, and `BookController::store()`, do not log.

---

## 9. Workflows

### 9.1 Create Book with Authors and Class Assignments (Current)

```
User fills Book Create form
  → POST /syllabus-books/books
  → BookRequest::validate() [FormRequest]
  → BookController::store()
      → Manual Validator::make() for academic_session_id [REDUNDANT — cross-layer]
      → Manual ISBN duplicate check [Race condition risk]
      → DB::transaction()
          → Handle cover image upload → MediaFiles::create() [WRONG — should use qns_media_store]
          → BokBook::create() [UUID auto-generated in booted()]
          → Loop authors → raw DB::table insert [ordinal never set]
          → AcademicSession::where('is_current',1) [WRONG — cross-layer]
          → Loop class_subjects → raw DB::table insert
  → Redirect to books.index
```

### 9.2 Create Book with Authors and Class Assignments (V2 Target)

```
User fills Book Create form
  → POST /syllabus-books/books
  → BookRequest::validate() [include unique ISBN rule + session exists on tenant table]
  → BookController::store()
      → Gate::authorize('tenant.syllabus-books.book.create')
      → BookService::createBook($validated)
          → Handle cover image → sys_media / qns_media_store
          → BokBook::create() [UUID auto-generated]
          → activityLog($book, 'Created', ...)
          → BookService::syncAuthors($book, $authors)
          → BookService::syncClassAssignments($book, $class_subjects, $sessionFallback)
              → Use OrganizationAcademicSession for session fallback
              → Enforce is_primary uniqueness per class/subject/session
  → Redirect to books.index
```

### 9.3 Book Topic Mapping (V2 Target)

```
User selects Book + Topic on mapping form
  → POST /syllabus-books/book-topic-mappings
  → BookTopicMappingRequest::validate()
      [book_id: exists:slb_books,id]
      [topic_id: exists:slb_topics,id]
      [chapter_number: required|integer|min:1]
      [page_end <= book.total_pages if total_pages set]
  → BookTopicMappingController::store()
      → Gate::authorize('create', BookTopicMapping::class)
      → BookTopicMapping::create($validated)
      → activityLog($mapping, 'Created', ...)
  → Redirect to index
```

### 9.4 New Academic Year Book List Setup (📐 Proposed)

```
Admin navigates to Book Assignment Manager
  → Selects "Copy from previous session"
  → System fetches all slb_book_class_subject_jnt for previous session
  → Preview screen shows proposed assignments for new session
  → Admin confirms / modifies
  → BookAssignmentService::copyForwardSession($fromSessionId, $toSessionId)
      → For each assignment: insert with new academic_session_id
      → Skip if already exists (UNIQUE KEY protection)
  → Flash success with count of copied assignments
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Requirement | Target | Current State |
|-------------|--------|---------------|
| Book catalog list (with pagination) | < 300ms | 🟡 `Dropdown::all()` loads all dropdowns (N+1 risk) |
| Book create/update transaction | < 500ms | 🟡 Acceptable for typical author/class counts |
| Book topic mapping index | < 200ms | ❌ Page crashes before executing (undefined variable) |
| Book search (title/ISBN/publisher) | < 300ms | 🟡 LIKE with leading wildcard — index not used on title |
| Cover image upload | < 2 seconds for ≤2MB | 🟡 No resizing on upload |

**P2 fixes:**
- Replace `Dropdown::all()` with `Dropdown::where('key', 'language')->get()` in `index()` methods
- Add full-text index on `slb_books.title` or switch to `LIKE 'search%'` (prefix) instead of `'%search%'`
- Eager-load `authors` on `index()` to prevent per-row N+1 when displaying author count

### 10.2 Security

| Check | Status | Required Action |
|-------|--------|-----------------|
| Gate::authorize on all controllers | 🟡 | Fix `AuthorController::store()` missing gate; fix `SyllabusBooksController::index()` missing gate |
| FormRequest on all mutations | 🟡 | BookRequest: add `unique` ISBN rule; BookTopicMappingRequest: add `exists` rules |
| EnsureTenantHasModule middleware | ❌ | Add to route group |
| ISBN race condition | 🟡 | Move uniqueness to FormRequest (DB-level constraint prevents duplicates but no clean error) |
| File upload type validation | 🟡 | FormRequest validates `mimes:jpg,jpeg,png,webp` — good. Add server-side MIME detection. |
| CSRF protection | ✅ | Standard Laravel forms |
| SQL injection | ✅ | Eloquent ORM + raw inserts use bound parameters |
| Cross-layer data access | ❌ | Replace `Modules\Prime\Models\AcademicSession` with `OrganizationAcademicSession` |

### 10.3 Data Integrity

- UUID on `slb_books` prevents cross-system identifier collisions (BINARY 16)
- All junction tables use composite unique constraints to prevent duplicate mappings
- Soft delete cascade: soft-deleting a book does NOT auto-delete junction rows — this is intentional (assignments preserved for audit)
- Force delete must check for active consumers (lessons, questions) before permanent removal

### 10.4 Media Handling

- Cover images must use `qns_media_store` table (as per DDL FK constraint)
- Images should be stored in tenant-isolated storage paths (`storage/app/tenant_{uuid}/books/`)
- Recommended: server-side image resize to 400×600px on upload (not currently implemented)
- Maximum upload size: 2MB (enforced in `BookRequest`: `max:2048`)

### 10.5 Audit Trail

All CRUD operations must generate entries in `sys_activity_logs` via `activityLog()`:
- ✅ destroy, restore, forceDelete, toggleStatus (BookController, AuthorController, BookTopicMappingController)
- ❌ Missing: `store()` and `update()` in BookController and AuthorController

---

## 11. Dependencies

### 11.1 Upstream (SLK depends on these)

| Module       | Dependency                                          | Type         |
|--------------|-----------------------------------------------------|--------------|
| SchoolSetup  | `sch_classes`, `sch_subjects`, `sch_org_academic_sessions_jnt` | FK, read |
| GlobalMaster | `sys_dropdown_table` (language values)              | FK, read     |
| Syllabus     | `slb_topics` (for topic mapping FK)                 | FK, read     |
| Media (sys)  | `qns_media_store` (book cover images)               | FK, write    |
| Auth (sys)   | Spatie permission system for Gate::authorize()      | Auth         |

### 11.2 Downstream (other modules depend on SLK)

| Module        | Dependency                                          | Type        |
|---------------|-----------------------------------------------------|-------------|
| Syllabus      | `slb_lessons.bok_books_id → slb_books.id`           | FK consumer |
| QuestionBank  | `qns_questions_bank.book_id → slb_books.id`         | FK consumer |
| StudentPortal | Book list display per class/session (proposed)      | Read API    |
| ParentPortal  | Book list display and PDF download (proposed)       | Read API    |
| Library       | Conceptual overlap — Library tracks physical copies; SLK tracks curriculum prescription | None (no FK) |

### 11.3 Critical Cross-Layer Violation to Fix

**Current (wrong):** `Modules\Prime\Models\AcademicSession` → `glb_academic_sessions` on `global_master_mysql`

**Required (correct):** `Modules\SchoolSetup\Models\OrganizationAcademicSession` → `sch_org_academic_sessions_jnt` on `tenant_mysql`

Files to change:
- `BookController.php` — remove `use Modules\Prime\Models\AcademicSession` (lines 20-21), add `use Modules\SchoolSetup\Models\OrganizationAcademicSession`; update all `AcademicSession::` calls to `OrganizationAcademicSession::`
- `BookClassSubject.php` — remove `use Modules\Prime\Models\AcademicSession` (line 10), update `academicSession()` relationship
- `BookRequest.php` — session validation closure uses `AcademicSession::where(...)` — update to `OrganizationAcademicSession`

---

## 12. Test Scenarios

### 12.1 Test Coverage Target: Zero → 80%+

Current: **0 test files** (confirmed by gap analysis and code inspection).

### 12.2 Feature Tests (Priority P0 / P1)

**BookCatalogTest** (`Modules/SyllabusBooks/tests/Feature/BookCatalogTest.php`)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Unauthenticated user visits `/syllabus-books/books` | Redirect to login |
| 2 | Authenticated user without permission calls `books.index` | 403 Forbidden |
| 3 | Authorized user creates book with valid data | 302 redirect; book exists in DB; UUID set |
| 4 | Create book with duplicate ISBN | Validation error `isbn already exists` |
| 5 | Create book with `is_primary=1` for class-subject-session already having a primary | Existing primary demoted; new primary set |
| 6 | Create book with invalid `author_role` | Validation error |
| 7 | Soft delete book | `deleted_at` set; `is_active = 0`; activity log entry |
| 8 | Restore book | `deleted_at` null; activity log entry |
| 9 | Force delete book with active lesson reference | Blocked with error message |
| 10 | Force delete book with no references | Book removed; junction rows cleaned |
| 11 | Toggle book status | `is_active` flipped; JSON response with `success: true` |

**BookAuthorTest** (`Modules/SyllabusBooks/tests/Feature/BookAuthorTest.php`)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Create author with valid data | Author created; activity log |
| 2 | Create author with duplicate name | Validation error |
| 3 | Force delete author with book associations | Blocked with error (or junction cleaned per BR-SLK-04 decision) |
| 4 | `store()` without `create` permission | 403 (tests the missing gate fix) |

**BookTopicMappingTest** (`Modules/SyllabusBooks/tests/Feature/BookTopicMappingTest.php`)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Visit `book-topic-mappings.index` | 200 OK (tests undefined variable fix) |
| 2 | Create mapping with valid chapter/page range | Mapping saved |
| 3 | Create mapping with `page_end < page_start` | Validation error |
| 4 | Create mapping for non-existent book_id | Validation error |
| 5 | Create mapping without permission | 403 |
| 6 | Toggle mapping status | JSON response |

### 12.3 Unit Tests (Priority P2)

**BookDeletionConstraintTest** (`Modules/SyllabusBooks/tests/Unit/BookDeletionConstraintTest.php`)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | `hasLessonReferences($bookId)` with lessons using book | Returns true |
| 2 | `hasLessonReferences($bookId)` with no lessons | Returns false |
| 3 | `hasQuestionBankReferences($bookId)` | Returns correct boolean |

**PrimaryBookRuleTest** (`Modules/SyllabusBooks/tests/Unit/PrimaryBookRuleTest.php`)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Assign primary book when none exists | Inserted with `is_primary=1` |
| 2 | Assign primary book when one exists | Existing demoted to `is_primary=0` |

---

## 13. Glossary

| Term | Definition |
|------|------------|
| NCERT | National Council of Educational Research and Training — Indian government body that publishes standard textbooks |
| CBSE | Central Board of Secondary Education — Indian national school board |
| Primary Textbook | The main prescribed textbook for a class-subject combination (`is_primary = 1`) |
| Reference Book | Supplementary book assigned to a class-subject (`is_primary = 0`) |
| Mandatory Book | A book that all students must purchase/use (`is_mandatory = 1`) |
| Book-Topic Mapping | Link between a specific book chapter/section and a syllabus topic |
| Academic Session | A school year (e.g., 2025-26); in tenant context: `sch_org_academic_sessions_jnt` |
| slb_* prefix | Shared table prefix for Syllabus + SyllabusBooks modules |
| bok_* prefix | Secondary prefix used exclusively for the book-topic mapping table |
| Cross-layer violation | A tenant-scoped module accessing a Prime/Global DB model directly |

---

## 14. Suggestions (V2 Enhancements)

### 14.1 Architecture Improvements

**S-SLK-01 [P0]: Fix Cross-Layer AcademicSession** (Critical)
Replace all `Modules\Prime\Models\AcademicSession` references with `Modules\SchoolSetup\Models\OrganizationAcademicSession` in BookController, BookClassSubject model, and BookRequest. This is a correctness issue — the code is reading from the wrong database in production.

**S-SLK-02 [P1]: Create BookService**
Extract ~100 lines of business logic from `BookController::store()` and `update()` into a `BookService` class:
- `BookService::createBook(array $data, ?UploadedFile $cover): BokBook`
- `BookService::updateBook(BokBook $book, array $data, ?UploadedFile $cover): bool`
- `BookService::syncAuthors(BokBook $book, array $authors): void`
- `BookService::syncClassAssignments(BokBook $book, array $assignments, int $fallbackSessionId): void`
- `BookService::canForceDelete(BokBook $book): bool` (checks lesson + question references)

**S-SLK-03 [P1]: Migrate MediaFiles to qns_media_store**
The current `MediaFiles` model and its migration create a parallel media table. All cover image uploads should use the platform's standard `sys_media` / `qns_media_store` polymorphic approach, with `model_type = 'slb_books'` and `model_id = $book->id`. This aligns with the DDL FK constraint.

**S-SLK-04 [P1]: Namespace Permissions**
Prefix all permission strings with `tenant.syllabus-books.` to prevent collision:
- `tenant.book.viewAny` → `tenant.syllabus-books.book.viewAny`
- `tenant.author.viewAny` → `tenant.syllabus-books.author.viewAny`
Update `BookPolicy`, `AuthorPolicy`, and all `Gate::authorize()` calls.

**S-SLK-05 [P2]: Rename Models to Laravel Convention**
- `BookAuthors` → `BookAuthor` (singular)
- `MediaFiles` → remove (or replace with platform `Media` model)
- Long-term: consider renaming `BokBook` to `Book` (under `Modules\SyllabusBooks` namespace to avoid collision with other Book models in the codebase)

**S-SLK-06 [P2]: Add created_by / updated_by to DDL**
Both `slb_books` and `slb_book_authors` tables have `createdBy()` / `updatedBy()` relationships defined in their models, but the DDL does NOT have these columns. Either:
(a) Add `created_by INT UNSIGNED FK → sys_users.id` and `updated_by INT UNSIGNED FK → sys_users.id` to both tables, OR
(b) Remove the relationships from the models if audit trail is handled by `sys_activity_logs` only.

**S-SLK-07 [P2]: Remove Redundant Validator in BookController**
`BookController::store()` and `update()` call `Validator::make($request->all(), [...])` after `BookRequest` has already validated. Move the `academic_session_id` closure validation into `BookRequest::rules()` (using `OrganizationAcademicSession::where()` after the cross-layer fix). Delete the manual `Validator::make()` call.

**S-SLK-08 [P2]: Enforce Primary Book Rule**
In `BookService::syncClassAssignments()`:
```php
if (!empty($cs['is_primary'])) {
    DB::table('slb_book_class_subject_jnt')
        ->where('class_id', $cs['class_id'])
        ->where('subject_id', $cs['subject_id'])
        ->where('academic_session_id', $sessionId)
        ->where('book_id', '!=', $book->id)
        ->update(['is_primary' => 0]);
}
```

**S-SLK-09 [P3]: Book List Copy-Forward**
Add `BookAssignmentService::copyForwardSession(int $fromSession, int $toSession): int` to support copying all class-subject-book assignments from one academic year to the next, used at the start of each new school year.

**S-SLK-10 [P3]: Book List PDF Export**
Generate a printable/shareable book list for parents: `GET /syllabus-books/books/book-list-pdf?class_id=&session_id=` — sorted by subject, distinguishing primary from reference and mandatory from optional. Use the platform's DomPDF integration.

---

## 15. Appendices

### 15.1 Form Request Summary

**AuthorRequest**
| Field | Rule |
|-------|------|
| name | required, string, max:150, unique:slb_book_authors,name |
| qualification | nullable, string, max:200 |
| bio | nullable, string |
| is_active | nullable, boolean |

**BookRequest** (actual, from code inspection)
| Field | Rule |
|-------|------|
| title | required, string, max:255 |
| subtitle | nullable, string, max:255 |
| isbn | nullable, string, max:50 (MISSING: unique rule) |
| edition | nullable, string, max:50 |
| publication_year | nullable, integer, min:1900, max:current_year |
| publisher_name | nullable, string, max:255 |
| total_pages | nullable, integer, min:1 |
| description | nullable, string |
| language | nullable, integer |
| cover_image_media_id | nullable, image, mimes:jpg,jpeg,png,webp, max:2048 |
| is_ncert | nullable, boolean |
| is_cbse_recommended | nullable, boolean |
| is_active | nullable, boolean |
| tags | nullable, array |
| tags.* | string, max:50 |
| authors | nullable, array |
| authors.*.author_id | required, integer, exists:slb_book_authors,id |
| authors.*.author_role | nullable, string, in:PRIMARY,CO_AUTHOR,EDITOR,CONTRIBUTOR |
| authors.*.ordinal | nullable, integer, min:1 |
| class_subjects | nullable, array |
| class_subjects.*.class_id | required, integer, exists:sch_classes,id |
| class_subjects.*.subject_id | required, integer, exists:sch_subjects,id |
| class_subjects.*.academic_session_id | required, integer (MISSING: exists rule) |
| class_subjects.*.remarks | nullable, string, max:255 |
| class_subjects.*.is_primary | nullable, boolean |
| class_subjects.*.is_mandatory | nullable, boolean |
| class_subjects.*.is_active | nullable, boolean |

**BookTopicMappingRequest** (actual, from code inspection)
| Field | Rule |
|-------|------|
| book_id | required, integer (MISSING: exists:slb_books,id) |
| topic_id | required, integer (MISSING: exists:slb_topics,id) |
| chapter_number | required, integer, min:1 |
| chapter_title | nullable, string, max:255 |
| page_start | nullable, integer, min:1 |
| page_end | nullable, integer, gte:page_start |
| section_reference | nullable, string, max:255 |
| remarks | nullable, string |
| is_active | nullable, boolean |

### 15.2 Controller Method Summary (Actual Code)

| Controller | Method | Gate | ActivityLog | Notes |
|-----------|--------|------|-------------|-------|
| AuthorController | index | ✅ tenant.author.viewAny | ❌ | Queries BokBook, not BookAuthors |
| AuthorController | create | ✅ tenant.author.create | n/a | |
| AuthorController | store | ❌ Missing | ❌ | Gate only on create(), not store() |
| AuthorController | show | ✅ tenant.author.view | n/a | |
| AuthorController | edit | ✅ tenant.author.update | n/a | |
| AuthorController | update | ✅ (via edit gate) | ❌ | |
| AuthorController | destroy | ✅ tenant.author.delete | ✅ | |
| AuthorController | trashedAuthor | ✅ tenant.author.restore | n/a | |
| AuthorController | restore | ✅ tenant.author.restore | ✅ | |
| AuthorController | forceDelete | ✅ tenant.author.forceDelete | ✅ | Cleans junction |
| AuthorController | toggleStatus | ✅ tenant.author.update | ✅ | JSON response |
| BookController | index | ✅ tenant.book.viewAny | n/a | Dropdown::all() (slow) |
| BookController | create | ✅ tenant.book.create | n/a | Cross-layer AcademicSession |
| BookController | store | ✅ (in create, not store) | ❌ | Cross-layer; redundant Validator; race-condition ISBN |
| BookController | show | ✅ tenant.book.view | n/a | |
| BookController | edit | ✅ tenant.book.update | n/a | Cross-layer AcademicSession |
| BookController | update | ✅ (via edit) | ❌ | Cross-layer; redundant Validator |
| BookController | destroy | ✅ tenant.book.delete | ✅ | |
| BookController | trashedBook | ✅ tenant.book.restore | n/a | |
| BookController | restore | ✅ tenant.book.restore | ✅ | |
| BookController | forceDelete | ✅ tenant.book.forceDelete | ✅ | Cleans junctions |
| BookController | toggleStatus | ✅ tenant.book.update | ✅ | JSON response |
| BookTopicMappingController | index | ✅ viewAny | n/a | ❌ Undefined $bookTopicMappings |
| BookTopicMappingController | create | ✅ create | n/a | |
| BookTopicMappingController | store | ✅ create | ❌ | Missing activityLog |
| BookTopicMappingController | edit | ✅ update | n/a | |
| BookTopicMappingController | update | ✅ update | ❌ | Missing activityLog |
| BookTopicMappingController | destroy | ✅ delete | ✅ | |
| BookTopicMappingController | trashedBookTopicMapping | ✅ restore | n/a | |
| BookTopicMappingController | restore | ✅ restore | ✅ | |
| BookTopicMappingController | forceDelete | ✅ forceDelete | ✅ | |
| BookTopicMappingController | toggleStatus | ✅ update | ✅ | JSON response |
| SyllabusBooksController | index | ❌ | n/a | Functional but no auth gate |
| SyllabusBooksController | store | ❌ | n/a | Empty stub |
| SyllabusBooksController | update | ❌ | n/a | Empty stub |
| SyllabusBooksController | destroy | ❌ | n/a | Empty stub |

---

## 16. V1 → V2 Delta

### 16.1 Corrections to V1 Document

| V1 Claim | V2 Finding |
|----------|------------|
| "BookTopicMappingController has ZERO authentication on ALL 10 methods" | INCORRECT — all 10 methods have `Gate::authorize()` calls. V1 was based on stale analysis. The actual issue is the undefined `$bookTopicMappings` variable in `index()`. |
| "AuthorController: Auth status unknown" | CONFIRMED — `AuthorController` has `Gate::authorize()` on most methods, but `store()` is missing it. |
| Table prefix described as `slb_*` throughout | CORRECTED — the book-topic mapping table uses `bok_*` prefix (`bok_book_topic_mapping`), not `slb_*`. The module uses BOTH prefixes. |
| "Module Type: Prime (Central)" | CORRECTED — SLK is a Tenant-scoped module. All tables live in `tenant_{uuid}` on `tenant_mysql`. |
| `slb_book_topic_mapping_jnt` (inferred table name) | CORRECTED — actual table is `bok_book_topic_mapping` (no `_jnt` suffix, uses `bok_` not `slb_` prefix). |
| "`BookClassSubject` model exists in both namespaces" | CORRECTED — only ONE `BookClassSubject` model exists in `Modules\SyllabusBooks\Models`. No duplicate in Syllabus namespace found. |

### 16.2 New Issues Discovered in V2

| Issue | Priority | Description |
|-------|----------|-------------|
| ARCH-SLK-01 | P0 | `BookController`, `BookClassSubject` import `Modules\Prime\Models\AcademicSession` (cross-layer violation) |
| ARCH-SLK-02 | P0 | `BookRequest` session validation closure also uses Prime `AcademicSession` |
| BUG-SLK-01 | P0 | `BookTopicMappingController::index()` — `$bookTopicMappings` undefined variable (runtime error) |
| BUG-SLK-02 | P1 | `AuthorController::index()` — queries `BokBook` (books) instead of `BookAuthors` (authors) — wrong data |
| BUG-SLK-03 | P1 | `BookController::store()` missing `Gate::authorize()` at method level (only `create()` has it) |
| BUG-SLK-04 | P1 | Cover image stored in module-specific `MediaFiles` table, not `qns_media_store` (DDL FK mismatch) |
| DB-SLK-01 | P1 | `created_by`/`updated_by` columns in model relationships not present in DDL |
| DB-SLK-02 | P0 | `bok_book_topic_mapping` table missing from `tenant_db_v2.sql` DDL |
| PERF-SLK-01 | P2 | `Dropdown::all()` in index (loads all dropdown rows, not just language key) |
| AUD-SLK-01 | P2 | Missing `activityLog()` on `store()` and `update()` in BookController and AuthorController |

### 16.3 Priority Fix List (V2 P0 → P3)

| Priority | Issue | File(s) to Change |
|----------|-------|--------------------|
| P0 | Fix cross-layer AcademicSession | BookController.php, BookClassSubject.php, BookRequest.php |
| P0 | Fix undefined `$bookTopicMappings` in index | BookTopicMappingController.php |
| P0 | Add `bok_book_topic_mapping` to tenant_db_v2.sql | tenant_db_v2.sql |
| P0 | Activate book-topic mapping migration | Rename .bk to .php; fix FK references (bok_books → slb_books, bok_topics → slb_topics) |
| P1 | Add `Gate::authorize` to `AuthorController::store()` | AuthorController.php |
| P1 | Fix `AuthorController::index()` querying BokBook instead of BookAuthors | AuthorController.php |
| P1 | Add `Gate::authorize` to `SyllabusBooksController::index()` | SyllabusBooksController.php |
| P1 | Migrate cover image to `qns_media_store` | BookController.php, MediaFiles.php |
| P1 | Add `EnsureTenantHasModule` middleware to route group | routes/tenant.php |
| P1 | Remove redundant `Validator::make()` from BookController | BookController.php |
| P1 | Add `activityLog()` to BookController::store()/update() | BookController.php |
| P1 | Add `activityLog()` to AuthorController::store()/update() | AuthorController.php |
| P2 | Move ISBN uniqueness into BookRequest | BookRequest.php |
| P2 | Add `exists` rules to BookTopicMappingRequest book_id and topic_id | BookTopicMappingRequest.php |
| P2 | Implement primary book uniqueness enforcement (BookService) | New: BookService.php |
| P2 | Add `created_by`/`updated_by` to DDL (or remove model relationships) | tenant_db_v2.sql |
| P2 | Replace `Dropdown::all()` with filtered query | BookController.php, AuthorController.php |
| P2 | Write Feature + Unit tests (zero coverage today) | tests/ directory |
| P3 | Rename `BookAuthors` → `BookAuthor` | BookAuthors.php + all references |
| P3 | Remove stub routes/web.php overlap | Modules/SyllabusBooks/routes/web.php |
| P3 | Implement Book List copy-forward for new academic year | New: BookAssignmentService.php |
| P3 | Implement Book List PDF export | New route + DomPDF view |

