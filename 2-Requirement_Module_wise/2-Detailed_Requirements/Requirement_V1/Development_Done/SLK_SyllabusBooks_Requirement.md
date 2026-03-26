# SyllabusBooks Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** SLK | **Module Path:** `Modules/SyllabusBooks`
**Module Type:** Prime (Central) | **Database:** tenant_{uuid} (shared slb_* prefix)
**Table Prefix:** `slb_*` (shared with Syllabus module) | **Processing Mode:** FULL
**RBS Reference:** Module H — Academics Management (Syllabus Books sections)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

SyllabusBooks is the **national/central textbook catalog module** for the Prime-AI platform. It manages the master registry of textbooks and publications used across all schools — NCERT books, CBSE-recommended titles, state board publications, and supplementary reference materials. Schools (tenants) then assign specific books to their class-subject combinations for each academic session.

The module bridges two concerns:
1. **Central catalog management** — Super-Admin or Platform Manager creates and maintains the national book registry
2. **Tenant assignment** — Each tenant school assigns books from the catalog to their class/subject/session combinations

### 1.2 Architecture Note — Shared Table Prefix

SyllabusBooks uses the `slb_*` table prefix, which it shares with the Syllabus module. This is intentional because books are tightly linked to lesson content (`slb_lessons.bok_books_id`). The `slb_books`, `slb_book_authors`, `slb_book_author_jnt`, and `slb_book_class_subject_jnt` tables live in the `tenant_{uuid}` database but the book catalog itself is considered central reference data.

### 1.3 Module Position in the Platform

```
Platform Layer         Module                 Database
──────────────────────────────────────────────────────
Central (Prime)        SyllabusBooks (SLK)    tenant_{uuid}
                                               slb_books
                                               slb_book_authors
                                               slb_book_author_jnt
                                               slb_book_class_subject_jnt
Tenant (Per-School)    Syllabus (SLB)         slb_lessons.bok_books_id → slb_books
```

### 1.4 Module Characteristics

| Attribute          | Value                                                  |
|--------------------|--------------------------------------------------------|
| Laravel Module     | `nwidart/laravel-modules` v12, name `SyllabusBooks`    |
| Namespace          | `Modules\SyllabusBooks`                                |
| Module Code        | SLK                                                    |
| Domain             | Central + Tenant interaction                           |
| DB Connection      | `tenant_mysql` (tenant_{uuid}) for assignments         |
| Table Prefix       | `slb_*` (shared with Syllabus module)                  |
| Auth               | Not implemented (critical gap)                         |
| Frontend           | Bootstrap 5 + AdminLTE 4                               |
| Completion Status  | ~55%                                                   |
| Controllers        | 4                                                      |
| Models             | 6 (in SyllabusBooks), plus shared models in Syllabus   |
| Services           | 0                                                      |
| FormRequests       | 3                                                      |
| Tests              | 0                                                      |

### 1.5 Sub-Modules / Feature Areas

1. Book Authors — Author master with qualifications and bio
2. Book Catalog — Full book registry with ISBN, publisher, edition, language, cover image
3. Book-Author Junction — Multi-author support with roles (Primary, Co-Author, Editor, Contributor)
4. Book-Class-Subject Assignment — Link books to class/subject/session per tenant
5. Book-Topic Mapping — Map book pages/sections to syllabus topics

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Full CRUD for book authors (name, qualification, bio)
- Full CRUD for books (ISBN, title, subtitle, edition, publisher, year, language, cover image, tags)
- Book-author many-to-many with role assignment
- Book assignment to class/subject/academic session per tenant
- Book-topic mapping: which book covers which syllabus topics
- Toggle active/inactive on books and assignments
- Soft delete lifecycle for books, authors, and mappings
- Media file association for book cover images (via `qns_media_store`)
- NCERT and CBSE-recommended flags on books

### 2.2 Out of Scope

- Full-text book content storage or digital book rendering
- Lesson content management (handled in `Syllabus` module)
- E-commerce or purchasing of books
- Library management and physical book inventory (handled in `Library` module)
- Student-facing book access or reading progress tracking

### 2.3 RBS Reference Mapping

| RBS Section | RBS Feature | SyllabusBooks Coverage |
|-------------|-------------|------------------------|
| H1.2 — Curriculum Mapping | F.H1.2.1 (Map Subjects to Class) | `slb_book_class_subject_jnt` links books to class/subject |
| H2.1 — Lesson Plans | F.H2.1.1 (Attach Reference Materials) | `slb_lessons.bok_books_id` links to book catalog |
| H2.2 — Digital Content | F.H2.2.1.1 (Upload Content) | Book cover images via media |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Access Level |
|-------|-------------|--------------|
| Super Admin | Prime-AI platform operator | Full CRUD on book catalog (central) |
| Platform Manager | Manages national curriculum content | Full CRUD on books and authors |
| School Admin | Tenant administrator | Assign books to class/subject/session; view catalog |
| Academic Coordinator | Manages curriculum for the school | Assign books; create topic mappings |
| Teacher | Can view assigned books | Read-only |
| Student | Can view their class books | Read-only via portal |

### 3.2 Permission Naming Convention

| Permission | Description |
|-----------|-------------|
| `system-config.books.viewAny` | View book catalog (central) |
| `system-config.books.create` | Create new book |
| `system-config.books.update` | Edit book |
| `system-config.books.delete` | Soft-delete book |
| `tenant.book-assignment.create` | Assign book to class/subject |
| `tenant.book-assignment.delete` | Remove assignment |
| `tenant.book-topic-mapping.create` | Map book to topic |

---

## 4. Functional Requirements

### 4.1 Book Author Management (FR-SLK-01)

**FR-SLK-01.1 — Create Author**
- Fields: name (required, unique), qualification (text), bio (long text)
- Author name must be unique across the system

**FR-SLK-01.2 — Author Lifecycle**
- Soft delete support (deleted_at column on `slb_book_authors`)
- Edit qualification and bio details
- Listing shows active authors; trash view shows deleted authors

**FR-SLK-01.3 — Author in Book**
- An author can be linked to multiple books
- A book can have multiple authors

### 4.2 Book Catalog Management (FR-SLK-02)

**FR-SLK-02.1 — Create Book**
- Fields: isbn (unique, nullable), title (required), subtitle, description, edition, publication_year, publisher_name, language (FK to sys_dropdown_table), total_pages, cover_image_media_id (FK to qns_media_store), tags (JSON), is_ncert (flag), is_cbse_recommended (flag)
- UUID auto-assigned (BINARY 16) on creation

**FR-SLK-02.2 — ISBN Uniqueness**
- ISBN field is UNIQUE in the database — the system must prevent duplicate ISBN entries
- ISBN is nullable (some books may not have an ISBN, e.g., old publications)

**FR-SLK-02.3 — Book Cover Image**
- Cover image uploaded via `qns_media_store` polymorphic media table
- Image stored as media ID reference; actual file stored in application storage

**FR-SLK-02.4 — Book Flags**
- `is_ncert`: flag for NCERT (National Council of Educational Research and Training) publications
- `is_cbse_recommended`: flag for CBSE board recommended books
- These flags support filtering for government-mandated vs supplementary materials

**FR-SLK-02.5 — Book Language**
- Language field references `sys_dropdown_table` (values: English, Hindi, Sanskrit, etc.)
- Required field — every book must have a language designation

**FR-SLK-02.6 — Book Tags**
- JSON array of additional search/discovery tags
- Used for full-text search and categorization

**FR-SLK-02.7 — Book Soft Delete Lifecycle**
- Delete moves to trash; restore recovers from trash; force-delete permanently removes
- Active books cannot be force-deleted if they have active assignments (`slb_book_class_subject_jnt`)

### 4.3 Book-Author Association (FR-SLK-03)

**FR-SLK-03.1 — Link Authors to Book**
- Junction: `slb_book_author_jnt` with composite PK (book_id, author_id)
- Author roles: PRIMARY, CO_AUTHOR, EDITOR, CONTRIBUTOR
- `ordinal` field controls display order of authors on book detail page

**FR-SLK-03.2 — Author Management on Book Form**
- When creating/editing a book, authors can be added/removed inline
- The junction is managed via the BookController

### 4.4 Book-Class-Subject Assignment (FR-SLK-04)

**FR-SLK-04.1 — Assign Book to Class**
- Link a book to class + subject + academic_session per tenant school
- Fields: book_id, class_id, subject_id, academic_session_id, is_primary (primary textbook flag), is_mandatory, remarks
- UNIQUE constraint on (book_id, class_id, subject_id, academic_session_id) — no duplicate assignments

**FR-SLK-04.2 — Primary vs Reference Books**
- `is_primary = 1`: the main prescribed textbook for the class-subject
- `is_primary = 0`: supplementary or reference book
- A class-subject-session can have multiple reference books but should have one primary book

**FR-SLK-04.3 — Mandatory Flag**
- `is_mandatory`: indicates the book is required for all students
- Used for school fee calculation and book distribution

**FR-SLK-04.4 — Assignment Lifecycle**
- Assignments support `is_active` toggle and soft delete
- Inactive assignments are hidden from teacher and student views

### 4.5 Book-Topic Mapping (FR-SLK-05)

**FR-SLK-05.1 — Map Book to Topics**
- Link specific book to specific topics in the syllabus hierarchy
- `BookTopicMapping` model manages `slb_book_topic_mapping_jnt` table (inferred from model name)
- Allows schools to annotate which chapter/section of a book covers which syllabus topic

**FR-SLK-05.2 — Mapping Lifecycle**
- Full CRUD: create mapping, edit, soft-delete (to Trash), restore, force-delete
- Managed via `BookTopicMappingController`
- Activity logs recorded on delete, restore, force-delete operations

**FR-SLK-05.3 — Toggle Mapping Status**
- `is_active` toggle on each mapping for temporary deactivation without deletion

---

## 5. Data Model

### 5.1 Primary Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `slb_book_authors` | Author master | name (unique), qualification, bio |
| `slb_books` | Book catalog | uuid, isbn (unique), title, edition, publisher_name, publication_year, language (FK sys_dropdown), is_ncert, is_cbse_recommended, tags JSON, cover_image_media_id |
| `slb_book_author_jnt` | Book ↔ Author M:N | book_id, author_id, author_role ENUM, ordinal |
| `slb_book_class_subject_jnt` | Book ↔ Class/Subject/Session | book_id, class_id, subject_id, academic_session_id, is_primary, is_mandatory |
| `slb_book_topic_mapping_jnt` | Book ↔ Topic | book_id, topic_id (inferred; managed by BookTopicMapping model) |

### 5.2 Relationships

```
slb_books (N) ──── (N) slb_book_authors [via slb_book_author_jnt]
slb_books (N) ──── (N) sch_classes + sch_subjects [via slb_book_class_subject_jnt]
slb_books (N) ──── (N) slb_topics [via BookTopicMapping]
slb_lessons (N) ──── (1) slb_books [slb_lessons.bok_books_id]
```

### 5.3 Models

| Model | Table | Notes |
|-------|-------|-------|
| `BokBook` | `slb_books` | Main book model in SyllabusBooks namespace |
| `BookAuthors` | `slb_book_authors` | Author master |
| `BookAuthorJnt` | `slb_book_author_jnt` | Junction model |
| `BookClassSubject` | `slb_book_class_subject_jnt` | Assignment junction |
| `BookTopicMapping` | `slb_book_topic_mapping_jnt` | Topic mapping (supports SoftDeletes) |
| `MediaFiles` | `qns_media_store` | Media reference model for cover images |
| `Book` (in Syllabus module) | `slb_books` | Cross-module reference model |
| `AuthorBook` (in Syllabus module) | `slb_book_author_jnt` | Cross-module reference model |

### 5.4 External FK Dependencies

| Column | References |
|--------|------------|
| `slb_books.language` | `sys_dropdown_table.id` |
| `slb_books.cover_image_media_id` | `qns_media_store.id` |
| `slb_book_class_subject_jnt.class_id` | `sch_classes.id` |
| `slb_book_class_subject_jnt.subject_id` | `sch_subjects.id` |
| `slb_book_class_subject_jnt.academic_session_id` | `sch_org_academic_sessions_jnt.id` |
| `slb_lessons.bok_books_id` | `slb_books.id` |

---

## 6. Controller & Route Inventory

### 6.1 Controllers

| Controller | Methods | Auth | Status |
|-----------|---------|------|--------|
| `SyllabusBooksController` | index, create, store (empty), show, edit, update (empty), destroy (empty) | NONE | Empty stub — store/update/destroy not implemented |
| `AuthorController` | Full CRUD + lifecycle (inferred from model) | Unknown | Status unclear |
| `BookController` | Full CRUD + book-author management | Unknown | Partially implemented |
| `BookTopicMappingController` | index, create, store, edit, update, destroy, trashedBookTopicMapping, restore, forceDelete, toggleStatus | ZERO AUTH | All methods lack any Gate or auth checks |

### 6.2 Route Notes

- Routes are registered for `syllabus-books` prefix
- `BookTopicMappingController` routes include full CRUD + trash/restore/force-delete
- `SyllabusBooksController` is registered but its `store`, `update`, `destroy` methods are empty stubs

---

## 7. Form Request Validation Rules

### 7.1 BookTopicMappingRequest
- `book_id`: required, integer, exists:slb_books,id
- `topic_id`: required, integer, exists:slb_topics,id

### 7.2 BookRequest (inferred from BookController usage)
- `title`: required, string, max:100
- `isbn`: nullable, string, max:20, unique:slb_books,isbn
- `publisher_name`: nullable, string, max:150
- `publication_year`: nullable, year
- `language`: required, exists:sys_dropdown_table,id
- `is_ncert`: boolean
- `is_cbse_recommended`: boolean
- `edition`: nullable, string, max:50
- `tags`: nullable, array

### 7.3 AuthorRequest (inferred)
- `name`: required, string, max:150, unique:slb_book_authors,name
- `qualification`: nullable, string, max:200
- `bio`: nullable, text

---

## 8. Business Rules

**BR-SLK-01:** A book's ISBN must be globally unique. The system must validate uniqueness on both create and update, excluding the current record on update.

**BR-SLK-02:** A book cannot be force-deleted if it has active lesson references (`slb_lessons.bok_books_id`). The system must check for lesson dependencies before permanent deletion.

**BR-SLK-03:** A book cannot be force-deleted if it has active class-subject assignments (`slb_book_class_subject_jnt`). Soft-delete only when assignments exist.

**BR-SLK-04:** Each class-subject-session combination can have only ONE primary book (`is_primary = 1`). Assigning a new primary book should automatically demote the existing primary to non-primary, or raise a validation error.

**BR-SLK-05:** Author names must be unique (UNIQUE KEY on `slb_book_authors.name`).

**BR-SLK-06:** `slb_book_author_jnt` uses composite PK (book_id, author_id) — the same author cannot be listed twice on the same book.

**BR-SLK-07:** Book-topic mappings support full soft delete lifecycle. Restoring a mapping restores its `is_active = 1` state.

**BR-SLK-08:** The `author_role` in `slb_book_author_jnt` must be one of: PRIMARY, CO_AUTHOR, EDITOR, CONTRIBUTOR.

---

## 9. Permission & Authorization Model

### 9.1 Current State — CRITICAL GAP

- **SyllabusBooksController**: NO authentication checks
- **BookTopicMappingController**: ZERO authentication on ALL 10 methods
- **AuthorController**: Auth status unknown
- **BookController**: Auth status unknown

The entire SyllabusBooks module currently has no enforced access control.

### 9.2 Required Permissions (Target State)

| Controller | Method | Required Permission |
|-----------|--------|-------------------|
| BookController | index | `syllabus-books.book.viewAny` |
| BookController | store | `syllabus-books.book.create` |
| BookController | update | `syllabus-books.book.update` |
| BookController | destroy | `syllabus-books.book.delete` |
| AuthorController | index | `syllabus-books.author.viewAny` |
| AuthorController | store | `syllabus-books.author.create` |
| BookTopicMappingController | index | `syllabus-books.book-topic-mapping.viewAny` |
| BookTopicMappingController | store | `syllabus-books.book-topic-mapping.create` |
| BookTopicMappingController | destroy | `syllabus-books.book-topic-mapping.delete` |

---

## 10. Tests Inventory

### 10.1 Current State

**Zero tests exist** for the SyllabusBooks module.

### 10.2 Required Tests (Target)

| Test Class | Type | Priority | Key Scenarios |
|-----------|------|----------|--------------|
| `BookCatalogTest` | Feature | HIGH | CRUD, ISBN uniqueness, auth enforcement |
| `BookTopicMappingTest` | Feature | HIGH | Auth required (currently missing), unique mapping |
| `BookAssignmentTest` | Feature | MEDIUM | Class/subject assignment, primary book rule |
| `BookAuthorTest` | Feature | MEDIUM | Author name uniqueness, junction management |
| `BookDeletionConstraintTest` | Unit | HIGH | Cannot delete book with active lesson references |

---

## 11. Known Issues & Technical Debt

### 11.1 Critical Security Gaps

**ISSUE-SLK-01 [CRITICAL]:** `BookTopicMappingController` has ZERO authentication on ALL 10 methods. Any user (even unauthenticated) can create, edit, delete, and restore book-topic mappings via direct URL access.

**ISSUE-SLK-02 [CRITICAL]:** `SyllabusBooksController` has no authentication checks and three empty stub methods (`store`, `update`, `destroy`). The controller is effectively non-functional.

### 11.2 Functionality Issues

**ISSUE-SLK-03 [HIGH]:** `SyllabusBooksController::store()`, `update()`, and `destroy()` are empty — all book creation, editing, and deletion via this controller are silently no-ops.

**ISSUE-SLK-04 [HIGH]:** `BookTopicMappingController::index()` references undefined variable `$bookTopicMappings` — calling the index method will throw a PHP `Undefined variable` error.

**ISSUE-SLK-05 [MEDIUM]:** No service layer. All business logic is directly in controllers.

**ISSUE-SLK-06 [MEDIUM]:** `BookClassSubject` model exists in both the `SyllabusBooks` namespace and the `Syllabus` namespace (duplicated). This creates ambiguity in which model to use for assignments.

### 11.3 Missing Functionality

**ISSUE-SLK-07 [MEDIUM]:** No API endpoint for book search/lookup. Other modules (LessonController uses `getBooks()` to fetch books by class/subject) query books directly without going through a dedicated SyllabusBooks API.

**ISSUE-SLK-08 [LOW]:** `AuthorController` implementation is unclear — no code was visible for inspection but the model exists.

---

## 12. API Endpoints

No dedicated REST API endpoints currently exist for SyllabusBooks. Book lookup is done via web routes consumed by LessonController's AJAX call.

### 12.1 Key AJAX Endpoints Used by Other Modules

| Method | Route | Consumer | Description |
|--------|-------|---------|-------------|
| GET | `/syllabus/get/books?class_id=&subject_id=` | LessonController | Fetch books for class/subject selection |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- Book catalog listing with pagination (10 per page) should respond within 300ms
- Book-topic mapping creation must validate topic existence within 100ms

### 13.2 Data Integrity

- UUID on `slb_books` for cross-system tracking (BINARY 16)
- ISBN uniqueness enforced at database level (UNIQUE KEY)
- Cascade rules: author force-delete should be blocked if author has book associations

### 13.3 Media Handling

- Cover image upload should use the platform's standard media handling via `qns_media_store`
- Cover images should be resized to standard dimensions (e.g., 400×600) on upload

---

## 14. Integration Points

| Module | Integration Type | Description |
|--------|-----------------|-------------|
| `Syllabus` | FK consumer + shared table prefix | `slb_lessons.bok_books_id` references `slb_books.id`; shared `slb_*` table namespace |
| `SchoolSetup` | FK dependency | `sch_classes`, `sch_subjects` referenced by `slb_book_class_subject_jnt` |
| `GlobalMaster` | Dropdown values | `sys_dropdown_table` provides language options for books |
| `QuestionBank` | Consumer | Question Bank references books (`slb_questions_bank.book_id`) |
| `Library` | Conceptual overlap | Library module manages physical book inventory; SyllabusBooks manages curriculum books — no direct FK |
| `Auth` | RBAC | Spatie permissions should gate all SLK operations |

---

## 15. Pending Work & Gap Analysis

### 15.1 Completion Status: ~55%

| Feature Area | Status | Gap Description |
|-------------|--------|-----------------|
| Book Author CRUD | 70% | Auth unknown; basic CRUD likely present |
| Book Catalog CRUD | 60% | Auth unknown; cover image upload incomplete |
| Book-Author Junction | 65% | Basic implementation present |
| Book-Class Assignment | 60% | BookClassSubject model exists; controller/UI incomplete |
| Book-Topic Mapping | 50% | Controller present but has critical bugs (undefined variable, zero auth) |
| SyllabusBooksController | 20% | index works; store/update/destroy are empty stubs |
| Service Layer | 0% | No services |
| Tests | 0% | Zero tests |
| Book Search API | 0% | No dedicated search endpoint |
| Primary Book Enforcement | 0% | No business rule implementation for unique primary per class/subject/session |

### 15.2 Priority Remediation Items

1. **[P0]** Add `Gate::authorize()` to ALL methods in `BookTopicMappingController`
2. **[P0]** Fix `BookTopicMappingController::index()` — undefined `$bookTopicMappings` variable
3. **[P0]** Implement `SyllabusBooksController::store()`, `update()`, `destroy()`
4. **[P1]** Add authentication to all remaining SyllabusBooks controllers
5. **[P1]** Implement primary book uniqueness rule (only one `is_primary = 1` per class/subject/session)
6. **[P1]** Implement referential integrity check before force-delete of books
7. **[P2]** Build book cover image upload flow
8. **[P2]** Write Feature tests for all controllers
9. **[P2]** Resolve duplication of `BookClassSubject` model between namespaces
10. **[P3]** Create dedicated book search API endpoint for cross-module consumption
