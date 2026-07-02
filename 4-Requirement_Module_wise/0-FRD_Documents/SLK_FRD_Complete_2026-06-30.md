# SyllabusBooks (SLK) — Complete Analysis Pack
**Date:** 2026-06-30 | **Agent:** Business Analyst (Complete Analysis Pack Mode)
**Module:** SyllabusBooks | **Code:** SLK | **Prefix:** `slb_*` / `bok_*`
**FRD Reference:** `SLK_FRD_2026-06-30.md` (all REQ-/BR-/RPT-/ENH- IDs originate there — not re-numbered here)

---

## Table of Contents

1. [FRD Reference](#frd-reference)
2. [Requirements Traceability Matrix (RTM)](#rtm)
3. [Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog](#brs)
4. [Process Flows + FSM Catalog](#flows)
5. [Data Dictionary + Cross-Module Dependency Map](#data)
6. [NFR Catalog + Risk Register](#nfr-risk)
7. [Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks](#plan)
8. [User Stories + Acceptance Criteria + Reporting & KPI Spec](#stories)
9. [Feature Specification (Screen-Level Detail)](#screens)
10. [Module Knowledge Update](#knowledge)

---

<a name="frd-reference"></a>
## Section 1 — FRD Reference

The Functional Requirements Document for SyllabusBooks is the single source of truth for all IDs used in this pack.

**FRD File:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/SLK_FRD_2026-06-30.md`

**FRD Totals (Section 10.4):**

| Artifact | Total | P0 | P1 | P2 |
|---|---|---|---|---|
| REQ- (Requirements) | 12 | 4 | 7 | 1 |
| BR- (Business Rules) | 21 | 11 | 7 | 3 |
| RPT- (Reports) | 4 | 0 | 3 | 1 |
| ENH- (Enhancements) | 6 | 0 | 4 | 2 |

---

<a name="rtm"></a>
## Section 2 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR Refs | Key Screen(s) | Workflow | Report(s) | Code Status | Critical Gap |
|---|---|---|---|---|---|---|---|
| REQ-SLK-001 | Book Author Management | BR-001, BR-005, BR-020, BR-021 | Author list, Author create/edit, Author trash | — | — | PARTIAL | `index()` queries wrong model; `store()` missing gate; `store()`/`update()` missing activity log |
| REQ-SLK-002 | Book Catalog Management | BR-002, BR-003, BR-004, BR-020, BR-021 | Book list, Book create/edit/show/trash | WF-1 | — | PARTIAL | Cross-layer AcademicSession; cover image wrong store; ISBN uniqueness missing from FormRequest |
| REQ-SLK-003 | Book-Class-Subject Assignment | BR-006, BR-009, BR-020, BR-021 | Book create/edit (assignment section) | WF-1 | RPT-001 | PARTIAL | Primary-book uniqueness not enforced; tenant session model not used |
| REQ-SLK-004 | Book Chapter Index | BR-010, BR-020, BR-021 | Book show (Chapters tab), Chapter management | — | — | SUBSTANTIAL | None critical; bulk-import route may need verification |
| REQ-SLK-005 | Book Files & Downloads | BR-018, BR-020, BR-021 | Book show (Files tab), File management | WF-3 | RPT-002 | SUBSTANTIAL | Settings integration for format/size limits not confirmed; download trigger mechanism not confirmed |
| REQ-SLK-006 | Book-Topic Mapping | BR-010, BR-020, BR-021 | Topic Mapping list/create/edit/trash | — | — | BROKEN | `bok_book_topic_mapping` table not in deployed schema; `index()` throws undefined variable |
| REQ-SLK-007 | Study Notes Management | BR-011, BR-012, BR-013, BR-014, BR-019, BR-020, BR-021 | Notes list, Note create/edit/show/trash | WF-2 | RPT-003 | PARTIAL | Approval FSM transitions not confirmed; notifications not confirmed; Settings-based upload gate not confirmed |
| REQ-SLK-008 | Note Ratings | BR-015, BR-016, BR-021 | Note list (rating stars), Note ratings tab | — | — | PARTIAL | Upsert logic (update vs insert on second rating) not confirmed |
| REQ-SLK-009 | Download Audit Log | BR-017, BR-021 | Note Downloads tab, Book File Downloads tab | WF-3 | RPT-002 | SUBSTANTIAL | Auto-trigger from download action not verified; no dedicated filter-only report screen |
| REQ-SLK-010 | Module Configuration | BR-012, BR-013, BR-014, BR-018, BR-019, BR-021 | Settings / Config edit view | — | — | SUBSTANTIAL | Settings values used by controllers not verified (format/size checks) |
| REQ-SLK-011 | Dashboard / Master Index | BR-021 | Dashboard index (tabbed) | — | — | PARTIAL | `SyllabusBooksController::index()` has no Gate::authorize; AcademicSession cross-layer in index() |
| REQ-SLK-012 | Class Book List Report | BR-021 | Book List PDF screen (proposed) | — | RPT-001 | NOT STARTED | No PDF generation route or view exists |

---

<a name="brs"></a>
## Section 3 — Business Rules Register + Requirement Conditions + Validation & Edge-Case Catalog

### 3.1 Business Rules Register (Standalone — reuses BR-SLK-NNN from FRD §4)

| BR-ID | Rule | Type | Trigger | Enforcement Point | Priority |
|---|---|---|---|---|---|
| BR-SLK-001 | Author name unique per school catalog | Validation | Author create/edit | FormRequest (missing) + DB UNIQUE | P0 |
| BR-SLK-002 | ISBN unique per school catalog (when provided) | Validation | Book create/edit | FormRequest (missing) + DB UNIQUE | P0 |
| BR-SLK-003 | Book not permanently removable if active lesson references exist | Workflow | Book force-delete | BookController::forceDelete() — not yet implemented | P0 |
| BR-SLK-004 | Book not permanently removable if active question-bank references exist | Workflow | Book force-delete | BookController::forceDelete() — not yet implemented | P0 |
| BR-SLK-005 | Author not permanently removable while active book associations exist | Workflow | Author force-delete | AuthorController::forceDelete() — currently cascades | P1 |
| BR-SLK-006 | One primary textbook per class-subject-session; new primary demotes existing | Calculation / Concurrency | Assignment create/edit | BookService (missing) | P0 |
| BR-SLK-007 | Author role must be one of four ENUM values | Validation | Book create/edit | BookRequest (implemented) + DB ENUM | P0 |
| BR-SLK-008 | Duplicate author-role pair not allowed in same book | Validation | Book create/edit | BookController inline check (partial) | P1 |
| BR-SLK-009 | Academic session must come from school's own session list | Validation | Assignment create/edit | BookRequest (cross-layer — broken) | P0 |
| BR-SLK-010 | Page range: start ≤ end; end ≤ total_pages | Validation | Topic mapping create/edit | BookTopicMappingRequest (partial) | P1 |
| BR-SLK-011 | Note must be linked to exactly one class-subject | Validation | Note create | NoteRequest (status not confirmed) | P0 |
| BR-SLK-012 | Student cannot upload notes when setting is disabled | Permission | Note create (student) | NoteController gate (not confirmed) | P0 |
| BR-SLK-013 | Student note starts in Pending Approval when setting enabled | Workflow | Note create (student) | NoteController::store() (not confirmed) | P0 |
| BR-SLK-014 | Teacher note auto-approved when approval setting disabled | Workflow | Note create (teacher) | NoteController::store() (not confirmed) | P0 |
| BR-SLK-015 | One rating per student per note (upsert) | Concurrency | Note rating submit | NoteRatingController (not confirmed) | P2 |
| BR-SLK-016 | Rater identity not shown in public rating display | Permission | Note list / rating view | View layer (not confirmed) | P2 |
| BR-SLK-017 | Download records created automatically; not editable | Workflow | File download event | BookFileController / NoteDownloadController (not confirmed) | P1 |
| BR-SLK-018 | Book file uploads conform to Settings format/size | Validation | Book file upload | BookFileRequest (partially; Settings integration not confirmed) | P1 |
| BR-SLK-019 | Note file uploads conform to Settings format/size | Validation | Note file upload | NoteRequest (partially; Settings integration not confirmed) | P0 |
| BR-SLK-020 | Activity log on all CRUD mutations | Workflow | Every mutation | activityLog() helper — missing on store()/update() in Book + Author controllers | P0 |
| BR-SLK-021 | Tenant data isolation — all data per-school | Permission | Every request | Tenancy architecture (database-per-tenant) — implemented | P0 |

### 3.2 Requirement Conditions Catalog

> This catalog is also saved independently at: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/SyllabusBooks_Conditions.md`

| Condition ID | Entity / Field | Condition | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-SLK-001 | Author.name | Must be unique within school catalog | Validation | Create/Edit | Return "Author name already exists" error; do not save |
| BR-SLK-002 | Book.isbn | Must be unique when provided | Validation | Create/Edit | Return "ISBN already in use" error; do not save |
| BR-SLK-003 | Book (deletion) | Must have zero active lesson references | Workflow | Force-delete | Return "Book is in use by N lesson plans; cannot be permanently deleted" |
| BR-SLK-004 | Book (deletion) | Must have zero active question-bank references | Workflow | Force-delete | Return "Book is referenced by N questions; cannot be permanently deleted" |
| BR-SLK-005 | Author (deletion) | Must have zero active book-author links | Workflow | Force-delete | Block with error OR cascade after confirmation — school policy |
| BR-SLK-006 | Book-Class Assignment.is_primary | At most one primary per class-subject-session | Concurrency | Create/Edit with is_primary=true | Demote existing primary to false before inserting new primary |
| BR-SLK-007 | BookAuthorJunction.author_role | Must be PRIMARY, CO_AUTHOR, EDITOR, or CONTRIBUTOR | Validation | Create/Edit | Return "Invalid author role" validation error |
| BR-SLK-008 | BookAuthorJunction (author_id, role) | No duplicate (book, author, role) combination | Validation | Create/Edit | Return "This author is already assigned with this role" |
| BR-SLK-009 | Assignment.academic_session_id | Must reference tenant-scoped session | Validation | Create/Edit | Return "Invalid session" error; use OrganizationAcademicSession model |
| BR-SLK-010a | TopicMapping.page_start, page_end | page_start ≤ page_end | Validation | Create/Edit | Return "End page must be greater than or equal to start page" |
| BR-SLK-010b | TopicMapping.page_end | page_end ≤ book.total_pages (when total_pages known) | Validation | Create/Edit | Return "End page exceeds book's total pages" |
| BR-SLK-011 | Note.class_id, subject_id | Both class and subject are required | Validation | Create | Return "Class and subject are required" |
| BR-SLK-012 | Note (student upload) | Allow-student-uploads setting must be enabled | Permission | Create | Return 403 / hide upload button |
| BR-SLK-013 | Note.status (student) | Starts as Pending Approval when require-approval enabled | Workflow | Create | Auto-set status = 'pending_approval'; trigger teacher notification |
| BR-SLK-014 | Note.status (teacher) | Auto-approved when teacher-approval-required disabled | Workflow | Create | Auto-set status = 'approved' |
| BR-SLK-015 | NoteRating (user_id, note_id) | One rating per user per note | Concurrency | Rating submit | Upsert: update existing rating if present |
| BR-SLK-016 | NoteRating display | Individual rater identity is hidden | Permission | Any view | Show average + count; never show rater name |
| BR-SLK-017 | DownloadLog | Read-only; auto-created | Workflow | File download | System creates; no user can create/edit/delete manually |
| BR-SLK-018 | BookFile.file | Format must be in book-settings whitelist; size ≤ book max | Validation | Upload | Return "File format not allowed" or "File too large" error |
| BR-SLK-019 | NoteFile.file | Format must be in notes-settings whitelist; size ≤ note max | Validation | Upload | Return "File format not allowed" or "File too large" error |
| BR-SLK-020 | Any mutation | Activity log entry required | Workflow | Any CRUD action | Write activityLog() entry; if helper fails, log error but do not roll back |
| BR-SLK-021 | Any record | Scoped to current tenant | Permission | Every request | Tenancy middleware; database-per-tenant isolation |

### 3.3 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Author.name (uniqueness) | "R.S. Aggarwal" (new) | "R.S. Aggarwal" (already exists) | 150-char name | Null → required error | Two admins save same name simultaneously | DB UNIQUE constraint catches second; return 422 |
| Book.isbn | "978-0-13-468599-1" | "978-0-13-468599-1" (duplicate) | 20-char ISBN | Null → allowed | Concurrent saves with same ISBN | DB UNIQUE constraint catches; 422 returned |
| Book.title | "Mathematics Class 10" | "" (empty) | Exactly 100 chars | Empty → required error | — | Validation rejects empty |
| Assignment.is_primary | is_primary=1, no existing primary | is_primary=1, existing primary present | One assignment per book | Not provided → defaults to 1 | Two admins assign primaries simultaneously | First commit demotes; second commit finds no prior primary (or race condition — SELECT FOR UPDATE needed) |
| TopicMapping.page_start / page_end | start=5, end=20 | start=25, end=20 | start=1, end=1 (valid) | Null → allowed (optional range) | — | gte:page_start validation error |
| TopicMapping.page_end vs total_pages | end=150, total_pages=200 | end=250, total_pages=200 | end=200, total_pages=200 (valid) | total_pages null → no cap enforced | — | Custom validation in FormRequest |
| Note.file (size) | 5 MB file, limit 10 MB | 12 MB file, limit 10 MB | Exactly 10 MB | No file → required error | — | Upload rejected with "file too large" |
| Note.file (format) | .pdf (whitelist: pdf, docx) | .exe (not in whitelist) | .docx (edge of whitelist) | Null → required error | — | Upload rejected with "format not allowed" |
| Note.status FSM | Pending → Approved | Rejected → Approved (illegal transition) | Draft → Archived (allowed) | — | Two teachers approve same note simultaneously | Both succeed; status = approved (idempotent) |
| NoteRating.rating | 3 (stars) | 6 (out of range) | 1 and 5 (min/max) | Null → required | Two ratings from same user at same time | Upsert — last write wins; no duplicate row |
| BookFile.downloadable | false → download blocked | — | — | Null → defaults from Settings | — | 403 returned with message |

---

<a name="flows"></a>
## Section 4 — Process Flows and FSM Catalog

### 4.1 Process Flows

**Workflow 1: Create Book with Authors and Class Assignment** (from FRD §6)

```
[Librarian / Coordinator]                [System]
       │
       ├─ Opens "Add Book" form
       │
       ├─ Fills basic details, flags,     ────────────────────────────────
       │  authors with roles,             Validates all fields:
       │  class-subject assignments    →  - title required
       │  + cover image                  - ISBN unique (DB + FormRequest)
       │                                 - author IDs exist
       │                                 - author roles valid
       │                                 - no duplicate author-role pair
       │                                 - session is tenant-scoped
       │
       │                                 On failure: return to form with errors
       │
       │                              →  DB::transaction():
       │                                 1. Save cover image to shared media store
       │                                 2. Create book record (UUID auto-set)
       │                                 3. Insert author-junction rows (ordinal = form value)
       │                                 4. Insert class-subject-junction rows
       │                                    - Enforce primary-book uniqueness (demote existing)
       │                                 5. Write activity log entry
       │
       ├─ Receives redirect to book list  Flash success message
       │
       └─ END
```

**Workflow 2: Note Approval (Student Upload)** (from FRD §6)

```
[Student]                    [System]                         [Teacher]
   │
   ├─ Opens note-upload form
   │
   ├─ Fills form; uploads file  ─→ Validate: class + subject required
   │                               file format/size from Settings
   │                               student-uploads-enabled check
   │
   │                            ─→ If require-approval ON:
   │                               - Set status = PENDING_APPROVAL
   │                               - Send notification to Subject Teacher ────────→ [Teacher receives alert]
   │                                                                                │
   │                                                                                ├─ Opens approval queue
   │                                                                                ├─ Reviews note content
   │                                                                                │
   │                                                                    APPROVE ────┤ OR REJECT (enter reason)
   │                                                                                │
   │                            ←─────────────────────────────────────────────────┤
   │   Receives notification         System updates status:
   │   (Approved or Rejected         APPROVED → note visible per visibility scope
   │    with reason)                 REJECTED → note hidden; rejection reason stored
   │
   └─ END
```

**Workflow 3: File Download and Audit Logging** (from FRD §6)

```
[Student / Teacher]                 [System]
   │
   ├─ Clicks "Download" on file
   │
   │                              ─→ Check: user authenticated + has view permission
   │                              ─→ Check: file.downloadable = true
   │                                 If false → return 403 "Not available for download"
   │
   │                              ─→ Serve file from tenant-isolated storage
   │
   │                              ─→ Automatically create DownloadLog entry:
   │                                 - user_id (downloader)
   │                                 - file reference (book_file_id or note_file_id)
   │                                 - ip_address (from request)
   │                                 - user_agent (from request)
   │                                 - downloaded_at (server timestamp)
   │
   ├─ File received in browser
   └─ END
```

### 4.2 FSM Catalog — Study Note Status

**Entity:** Study Note
**Backed by:** `slb_notes.status` (string column, config-driven values per D29)

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|---|---|---|---|---|
| (new) | Student uploads | Student uploads enabled (BR-SLK-012); require-approval enabled (BR-SLK-013) | PENDING_APPROVAL | Notify teacher |
| (new) | Student uploads | Student uploads enabled; require-approval disabled | APPROVED | Note visible immediately |
| (new) | Teacher uploads | Teacher-approval-required disabled (BR-SLK-014) | APPROVED | Note visible immediately |
| (new) | Teacher uploads | Teacher-approval-required enabled | PENDING_APPROVAL | Notify admin |
| DRAFT | Submits for approval | Any uploader | PENDING_APPROVAL | Notify approver |
| DRAFT | Archives | Uploader or admin | ARCHIVED | Removed from student view |
| PENDING_APPROVAL | Teacher/Admin approves | Approver has permission | APPROVED | Note visible per scope; notify uploader |
| PENDING_APPROVAL | Teacher/Admin rejects | Approver has permission + reason entered | REJECTED | Uploader notified with reason |
| APPROVED | Archives | Admin | ARCHIVED | Removed from student view |
| REJECTED | Uploader re-edits + resubmits | — | PENDING_APPROVAL | Re-enter approval queue |
| ARCHIVED | Admin restores | Admin | APPROVED | Note becomes visible again |

**Terminal States:** ARCHIVED (effectively terminal unless restored by admin)
**Illegal Transitions (must be blocked):** REJECTED → APPROVED (without re-submission); APPROVED → PENDING_APPROVAL (except via Archive→restore path); ARCHIVED → PENDING_APPROVAL (must go to APPROVED directly on restore)

---

### 4.3 FSM Catalog — Book Status

**Entity:** Book (`slb_books`)
Simple two-state lifecycle with soft-delete overlay:

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| ACTIVE | Admin soft-deletes | Permission check | TRASHED (soft-deleted) | `is_active = false`; book hidden from assignment dropdowns; activity log |
| TRASHED | Admin restores | Permission check | ACTIVE | `is_active = true`; activity log |
| ACTIVE/TRASHED | Admin force-deletes | No lesson/QBank references (BR-003, BR-004) | PERMANENTLY DELETED | Author-junction + class-junction rows cleaned; activity log |

**Illegal Transitions:** Force-delete when lesson or question-bank references exist (must return error).

---

<a name="data"></a>
## Section 5 — Data Dictionary and Cross-Module Dependency Map

### 5.1 Data Dictionary — Business View

#### Book Authors (`slb_book_authors`)

| Business Field | Technical Column | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|
| Author Name | `name` | VARCHAR(150) | Yes | Unique per tenant | No |
| Qualification | `qualification` | VARCHAR(200) | No | — | No |
| Biography | `bio` | TEXT | No | — | No |
| Active Status | `is_active` | TINYINT(1) | Yes | 0 = Inactive, 1 = Active | No |
| Soft Delete Flag | `deleted_at` | TIMESTAMP | Auto | Null = active | No |

#### Books (`slb_books`)

| Business Field | Technical Column | Type | Required | Notes | PII? |
|---|---|---|---|---|---|
| Unique Identifier | `uuid` | BINARY(16) | Auto | Auto-generated on create | No |
| Title | `title` | VARCHAR(100) | Yes | Indexed | No |
| Subtitle | `subtitle` | VARCHAR(255) | No | — | No |
| ISBN | `isbn` | VARCHAR(20) | No | Unique per tenant | No |
| Publisher | `publisher_name` | VARCHAR(150) | No | Indexed | No |
| Language | `language` | INT UNSIGNED | No | FK → sys_dropdown_table | No |
| Edition | `edition` | VARCHAR(50) | No | — | No |
| Publication Year | `publication_year` | YEAR | No | — | No |
| Total Pages | `total_pages` | INT UNSIGNED | No | Used for page-range validation | No |
| Description | `description` | VARCHAR(512) | No | — | No |
| Tags | `tags` | JSON | No | Array of strings | No |
| Is NCERT | `is_ncert` | TINYINT(1) | No | 0/1 | No |
| Is CBSE Recommended | `is_cbse_recommended` | TINYINT(1) | No | 0/1 | No |
| Cover Image | `cover_image_media_id` | INT UNSIGNED | No | FK → qns_media_store.id | No |

#### Study Notes (`slb_notes`)

| Business Field | Technical Column | Type | Required | Notes | PII? |
|---|---|---|---|---|---|
| Title | `title` | VARCHAR | Yes | — | No |
| Description | `description` | TEXT | No | — | No |
| Note Type | `notes_type` | VARCHAR/ENUM | Yes | Revision Notes, Practice Questions, etc. | No |
| Class | `class_id` | INT | Yes | FK → sch_classes | No |
| Subject | `subject_id` | INT | Yes | FK → sch_subjects | No |
| Status | `status` | VARCHAR | Yes | draft, pending_approval, approved, rejected, archived | No |
| Visibility | `visibility` | VARCHAR/ENUM | Yes | class_only, subject_wide, school_wide | No |
| Downloadable | `is_downloadable` | TINYINT(1) | No | Defaults from Settings | No |
| Rejection Reason | `rejection_reason` | TEXT | Conditional | Required when status = rejected | No |
| Uploader | `created_by` | INT | Auto | FK → sys_users | Internal |

### 5.2 Cross-Module Dependency Map

#### Inbound — SyllabusBooks reads from these modules

| Source Module | Data / Entity Used | Why |
|---|---|---|
| SchoolSetup | Classes (`sch_classes`) | Book-class assignment; note class selection |
| SchoolSetup | Subjects (`sch_subjects`) | Book-subject assignment; note subject selection |
| SchoolSetup | Academic Sessions (`sch_org_academic_sessions_jnt`) | Book-class assignment scoped to school year |
| GlobalMaster | Language Dropdown (`sys_dropdown_table`, key `slb_books.language`) | Language selector on book form |
| Syllabus (SLB) | Topics (`slb_topics`) | Book-topic mapping — topic FK |
| QuestionBank (QNS) | Media Store (`qns_media_store`) | Book cover image storage (DDL FK) |
| Auth System | Spatie permissions + sys_roles | Gate::authorize() on all operations |

#### Outbound — modules that consume SyllabusBooks data

| Target Module | Mechanism | What SyllabusBooks Provides |
|---|---|---|
| Syllabus (SLB) | `slb_lessons.bok_books_id → slb_books.id` | Every lesson is linked to a book from this catalog |
| QuestionBank (QNS) | `qns_questions_bank.book_id → slb_books.id` | Questions can reference their source book |
| Student Portal | REST API (proposed — ENH-SLK-001) | Book list per class/session for student dashboard |
| Parent Portal | REST API + PDF (proposed — ENH-SLK-001) | Printable book list for parent communication |
| Library (LIB) | Conceptual reference only (no FK) | Library tracks physical copies; SLK tracks curriculum prescription |

**Critical Cross-Layer Violation (currently broken):**
`NoteController`, `BookController`, and `SyllabusBooksController` import `Modules\Prime\Models\AcademicSession` which reads from `glb_academic_sessions` on the `global_master_mysql` connection. This must be replaced with `Modules\SchoolSetup\Models\OrganizationAcademicSession` (reads from `sch_org_academic_sessions_jnt` on `tenant_mysql`). [Source: ARCH-SLK-01, confirmed 2026-06-30 by code inspection]

---

<a name="nfr-risk"></a>
## Section 6 — NFR Catalog and Risk Register

### 6.1 NFR Catalog (from FRD §9, expanded with measurable thresholds)

| NFR-ID | Category | Requirement | Acceptance Threshold |
|---|---|---|---|
| NFR-SLK-001 | Performance | Book catalog list (paginated, filtered) | < 300 ms at 1,000 books |
| NFR-SLK-002 | Performance | Dashboard index (6 tab datasets) | < 800 ms under normal load |
| NFR-SLK-003 | Performance | Book-topic mapping list | < 300 ms (currently: crashes) |
| NFR-SLK-004 | Performance | File upload (validate + save + log) | < 3 s for files up to 50 MB |
| NFR-SLK-005 | Performance | Dropdown data (language, class, subject) | Filtered queries only; no Dropdown::all() |
| NFR-SLK-006 | Security | All routes require authorization | 0 routes reachable without Gate::authorize() |
| NFR-SLK-007 | Security | Academic session must be tenant-scoped | 0 cross-layer reads to global_master_mysql from tenant code |
| NFR-SLK-008 | Security | Module-subscription gate at route level | Non-subscriber tenants receive 403 before any data access |
| NFR-SLK-009 | Security | Server-side MIME type validation on file uploads | Extension spoofing returns 422; no executable reaches storage |
| NFR-SLK-010 | Security | Tenant-isolated file storage | Files stored under `storage/app/tenant_{uuid}/` namespace |
| NFR-SLK-011 | Usability | Active tab clearly visually indicated | Tab state preserved across filter submissions |
| NFR-SLK-012 | Usability | Empty-state messages on all list views | No blank pages or unformatted arrays shown to users |
| NFR-SLK-013 | Usability | Human-readable note type labels in dropdown | No code values shown to end users |
| NFR-SLK-014 | Compliance | Activity log on all mutations | 100% of CRUD actions logged (0 unlogged mutations) |
| NFR-SLK-015 | Availability | Module usable during normal school hours | 99.9% uptime during 8 AM–6 PM IST on school days |

### 6.2 Risk Register

| Risk-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---|---|---|---|---|---|---|---|
| RISK-SLK-001 | Cross-layer AcademicSession bug causes wrong sessions loaded or FK violations in production | Architecture | High | High | Replace with OrganizationAcademicSession across all 3 controllers + request | Backend Developer | Booking assignments saving with wrong session IDs |
| RISK-SLK-002 | `bok_book_topic_mapping` table never activated — entire topic mapping feature non-functional | Database | High | Medium | Create and run migration; add to tenant_db DDL | DB Architect | Any visit to topic mapping screen crashes |
| RISK-SLK-003 | Multiple primary books per class-subject-session corrupts book lists for parents | Data Integrity | Medium | High | Implement BookService with SELECT…FOR UPDATE primary-demotion logic | Backend Developer | Parents receive conflicting book lists |
| RISK-SLK-004 | Note approval workflow not enforced — unapproved student notes visible to all | Security | Medium | High | Verify NoteController status assignment + Settings gate; add tests | Backend Developer | Students see unreviewed content |
| RISK-SLK-005 | Permission strings (`tenant.book.*`) too generic — collision risk with other modules | Security | Low | Medium | Namespace to `tenant.syllabus-books.*` (ENH-SLK-006) | Backend Developer | Permission leak between modules detected in gate tests |
| RISK-SLK-006 | Zero test coverage — regressions introduced undetected | Quality | High | Medium | Write 15+ Pest feature tests before next deployment | Test Agent | Any code change could break existing functionality silently |
| RISK-SLK-007 | Cover image FK points to `qns_media_store` but code writes to wrong table — DB constraint violation | Data Integrity | Medium | Medium | Migrate cover image handling to use `qns_media_store` (BUG-SLK-05) | Backend Developer | Cover image saves fail with FK constraint error in production |

---

<a name="plan"></a>
## Section 7 — Prioritization (MoSCoW) and Effort Estimation

### 7.1 MoSCoW Prioritization

#### Must (P0 — Core functionality; module unusable without these)

| ID | Item | Rationale |
|---|---|---|
| ARCH-SLK-01 | Fix cross-layer AcademicSession in BookController, NoteController, SyllabusBooksController, BookRequest | Runtime correctness — assigns books to wrong sessions in production |
| BUG-SLK-01 | Fix undefined `$bookTopicMappings` in BookTopicMappingController::index() | Page crashes on every load |
| DB-SLK-01 | Create and activate `bok_book_topic_mapping` migration | Table does not exist; mapping feature non-functional |
| BUG-SLK-02 | Fix AuthorController::store() missing Gate::authorize | Security bypass possible |
| BUG-SLK-03 | Fix AuthorController::index() querying BokBook instead of BookAuthors | Wrong data displayed — authors list shows books |
| BUG-SLK-04 | Add Gate::authorize to SyllabusBooksController::index() | Dashboard is publicly accessible without auth check |
| BUG-SLK-05 | Fix cover image storage to use qns_media_store | DB FK constraint violation on cover image save |
| GAP-SLK-06 | Add activityLog() to BookController::store() and update() | Audit trail incomplete |
| GAP-SLK-10 | Add activityLog() to AuthorController::store() and update() | Audit trail incomplete |
| BR-SLK-006 | Enforce primary-book uniqueness in assignment logic | Data integrity — multiple primaries corrupt parent book lists |
| REQ-SLK-003 | Tenant-scoped session in all assignment logic | Correctness |
| REQ-SLK-010 | Verify Settings values are actually read by upload/approval logic | Config has no effect if controllers ignore it |

#### Should (P1 — Important; module significantly improved with these)

| ID | Item | Rationale |
|---|---|---|
| GAP-SLK-07 | Add EnsureTenantHasModule middleware | Non-subscribers can access module |
| BR-SLK-003/004 | Pre-deletion check: lesson and question-bank references | Prevents orphaned FKs |
| ENH-SLK-001 | REST API endpoints for book list (Student/Parent Portal) | Portals cannot display books without this |
| ENH-SLK-002 | Book list copy-forward for new academic year | Major time-saver at session start |
| ENH-SLK-005 | Note approval notifications | Users have no feedback without notifications |
| ENH-SLK-006 | Namespace permissions to `tenant.syllabus-books.*` | Security hygiene |
| REQ-SLK-012 | Class Book List PDF report | Requested by parents at session start |
| GAP-SLK-11 | ISBN uniqueness in BookRequest FormRequest | Race-condition protection |

#### Could (P2 — Nice to have; low risk if deferred)

| ID | Item | Rationale |
|---|---|---|
| ENH-SLK-003 | Bulk book import from CSV | Useful for large schools |
| ENH-SLK-004 | Watermarking and PDF protection | Content protection for licensed material |
| REQ-SLK-008 | Note rating display (average-only, anonymous) | Quality signal for study materials |
| GAP-SLK-13 | Filter Dropdown::all() to language key | Performance optimisation |
| GAP-SLK-14 | Set author.ordinal in junction insert | Display-order correctness |

#### Won't (deferred to future release)

| Item | Reason |
|---|---|
| Physical book lending / circulation | Covered by Library module — out of scope |
| Third-party e-reader DRM integration | Complexity high; no school has requested |
| Cross-school book sharing | Violates tenant isolation principle |

### 7.2 Effort Estimation and Sprint Task Breakdown

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| 1 | Fix ARCH-SLK-01: Replace AcademicSession → OrganizationAcademicSession in BookController, NoteController, SyllabusBooksController, BookRequest | Backend | 3 | — | Sprint 1 |
| 2 | Fix BUG-SLK-01: Assign $bookTopicMappings in BookTopicMappingController::index() | Backend | 1 | — | Sprint 1 |
| 3 | Activate bok_book_topic_mapping migration (new .php file with FK to slb_books + slb_topics) | Schema | 2 | — | Sprint 1 |
| 4 | Fix BUG-SLK-02: Add Gate to AuthorController::store() | Backend | 0.5 | — | Sprint 1 |
| 5 | Fix BUG-SLK-03: Fix AuthorController::index() to query BookAuthors not BokBook | Backend | 0.5 | — | Sprint 1 |
| 6 | Fix BUG-SLK-04: Add Gate to SyllabusBooksController::index() | Backend | 0.5 | — | Sprint 1 |
| 7 | Fix BUG-SLK-05: Migrate cover image save to use qns_media_store (add BookService::handleCoverImage) | Backend | 4 | — | Sprint 1 |
| 8 | Create BookService: createBook(), updateBook(), syncAuthors(), syncClassAssignments() (with primary-demotion and tenant-session logic) | Backend | 8 | Task 1 | Sprint 1 |
| 9 | Add activityLog() to BookController::store() and update(); AuthorController::store() and update() | Backend | 1 | — | Sprint 1 |
| 10 | Add EnsureTenantHasModule middleware to syllabus-books route group | Backend | 1 | — | Sprint 1 |
| 11 | Move ISBN uniqueness into BookRequest (unique:slb_books,isbn ignore current ID on update) | Backend | 1 | — | Sprint 1 |
| 12 | Add exists:slb_books,id and exists:slb_topics,id to BookTopicMappingRequest | Backend | 1 | Task 3 | Sprint 1 |
| 13 | Verify NoteController: Settings-gate on student uploads; auto-approval logic; status FSM transitions | Backend | 4 | — | Sprint 2 |
| 14 | Verify NoteRatingController: upsert (update vs insert on second rating) | Backend | 2 | — | Sprint 2 |
| 15 | Verify download logging is auto-triggered on file serve (BookFile, NoteFile) | Backend | 2 | — | Sprint 2 |
| 16 | Implement note approval/rejection notifications (Notification module integration) | Backend + Integration | 4 | — | Sprint 2 |
| 17 | Implement Class Book List PDF report (DomPDF view + route) | Backend + Frontend | 5 | Task 8 | Sprint 2 |
| 18 | Implement REST API endpoints: GET /api/v1/books, GET /api/v1/class-book-list (ENH-SLK-001) | Backend (API) | 4 | Task 8 | Sprint 2 |
| 19 | Implement book list copy-forward (BookAssignmentService::copyForwardSession) | Backend | 3 | Task 8 | Sprint 2 |
| 20 | Namespace all permission strings to tenant.syllabus-books.* | Backend | 2 | — | Sprint 3 |
| 21 | Write Pest feature tests: BookCatalogTest (11 scenarios), BookAuthorTest (4), BookTopicMappingTest (6) | Testing | 8 | Tasks 1–12 | Sprint 2–3 |
| 22 | Write Pest feature tests: NoteApprovalTest (8 scenarios), NoteRatingTest (4) | Testing | 5 | Tasks 13–16 | Sprint 3 |
| 23 | Write unit tests: BookDeletionConstraintTest, PrimaryBookRuleTest | Testing | 3 | Task 8 | Sprint 2 |
| — | **Total Estimated Effort** | — | **~66 h** | — | 3 Sprints |

---

<a name="stories"></a>
## Section 8 — User Stories + Acceptance Criteria + Reporting KPI Spec

### 8.1 User Stories (P0 and P1 requirements)

---

**US-SLK-001** | Priority: P0 | REQ ref: REQ-SLK-001
As a Librarian, I want to register a book author with their name, qualification, and biography so that authors can be linked to books in the catalog.

Acceptance Criteria:
- Scenario: Happy path — create author
  - Given a Librarian with create-author permission is logged in
  - When they submit the author form with a unique name
  - Then the author is saved; the author list shows the new entry with 0 books linked
- Scenario: Duplicate name
  - Given author "NCERT" already exists
  - When a user attempts to create another author named "NCERT"
  - Then a "name already exists" validation error is returned and no author is created
- Scenario: Permission denied
  - Given a Student user
  - When they attempt to POST to the author create route
  - Then they receive a 403 Forbidden response
- Scenario: Empty state
  - Given no authors exist in the catalog
  - When the Librarian visits the author list
  - Then an "No authors registered yet" message is shown instead of an empty table

---

**US-SLK-002** | Priority: P0 | REQ ref: REQ-SLK-002
As a Librarian, I want to create a book entry with ISBN, publisher, authors, and class-subject assignments so that the school has a complete, deduplicated book catalog.

Acceptance Criteria:
- Scenario: Happy path — create book
  - Given a Librarian with create-book permission
  - When they submit the book form with a unique ISBN, one author (Primary), and one class-subject-session assignment
  - Then the book is saved; the book list shows the new entry; the author-junction row exists; the class-assignment row exists
- Scenario: Duplicate ISBN
  - Given a book with ISBN "9780131695993" exists
  - When the user attempts to create another book with the same ISBN
  - Then a "ISBN already in use" validation error is returned
- Scenario: Cross-layer session bug
  - Given the school's academic session is "2025-26" in the tenant DB
  - When the Librarian creates a book with this session
  - Then the assignment saves with the correct tenant session ID (not a global session ID)
- Scenario: Permission denied
  - Given a Teacher user (no create-book permission)
  - When they visit the book-create route
  - Then they receive a 403 Forbidden

---

**US-SLK-003** | Priority: P0 | REQ ref: REQ-SLK-003
As an Academic Coordinator, I want to designate exactly one primary textbook per class-subject-session combination so that parent book lists are accurate and unambiguous.

Acceptance Criteria:
- Scenario: First primary assignment
  - Given no primary book exists for Class 10, Maths, 2025-26
  - When a book is assigned with is_primary = true
  - Then the assignment is saved with is_primary = 1; no other rows are modified
- Scenario: Second primary — demotion
  - Given Book A is the primary for Class 10, Maths, 2025-26
  - When Book B is assigned as primary for the same class-subject-session
  - Then Book A's assignment is demoted to is_primary = 0 and Book B's is saved as is_primary = 1
- Scenario: Permission denied
  - Given a Student user
  - When they attempt to POST a class assignment
  - Then they receive a 403 Forbidden

---

**US-SLK-006** | Priority: P1 | REQ ref: REQ-SLK-006
As an Academic Coordinator, I want to map specific book chapters to syllabus topics so that teachers and students can trace curriculum topics to their source textbook material.

Acceptance Criteria:
- Scenario: Happy path — create mapping
  - Given a valid book (ID exists) and valid topic (ID exists)
  - When a mapping is submitted with page_start=10 and page_end=25
  - Then the mapping is saved; the topic mapping list shows the new entry with book name and topic name
- Scenario: Invalid page range
  - Given a mapping form where page_start=30 and page_end=15
  - When the user submits
  - Then a "End page must be greater than or equal to start page" error is returned
- Scenario: Table does not exist
  - Given the bok_book_topic_mapping migration has NOT been run
  - When the user visits the topic mapping list
  - Then they receive a database error (not a blank page)

---

**US-SLK-007** | Priority: P1 | REQ ref: REQ-SLK-007
As a Teacher, I want to upload a revision notes PDF for my class-subject so that students in my class have access to quality study materials.

Acceptance Criteria:
- Scenario: Teacher auto-approval
  - Given "Teacher Upload Approval — Require Approval" is disabled in Settings
  - When a Teacher uploads a revision notes PDF
  - Then the note status is set to "Approved" immediately; it is visible to students in the configured scope
- Scenario: Student notes — approval required
  - Given "Student Uploads" is enabled and "Require Approval" is on
  - When a Student uploads a note
  - Then the status is set to "Pending Approval"; the Teacher receives a notification
- Scenario: Student uploads disabled
  - Given "Allow Student Uploads" is disabled
  - When a Student visits the note-upload route
  - Then they receive a 403 or see no upload button
- Scenario: Format rejected
  - Given the Notes settings whitelist is [pdf, docx]
  - When a user uploads a .exe file
  - Then a "File format not allowed" error is returned and the note is not saved

---

**US-SLK-012** | Priority: P1 | REQ ref: REQ-SLK-012
As a School Admin, I want to generate a PDF book list for a selected class and academic session so that I can distribute it to parents at the start of the year.

Acceptance Criteria:
- Scenario: Happy path
  - Given books are assigned to Class 10, session 2025-26
  - When Admin selects Class 10 and 2025-26 and clicks Generate PDF
  - Then a PDF is downloaded, grouping books by subject, labelled Primary/Reference and Mandatory/Optional, with title, ISBN, publisher, edition
- Scenario: No books assigned
  - Given no books are assigned to Class 11, session 2025-26
  - When Admin generates the report for that class
  - Then the PDF shows "No books assigned for this class and session" rather than a blank or error page
- Scenario: Permission denied
  - Given a Student user
  - When they attempt to access the book-list PDF route
  - Then they receive a 403

---

### 8.2 Reporting and KPI Spec

| KPI | Definition | Source Data | Target | Cadence |
|---|---|---|---|---|
| Books per Class | Total distinct books assigned per class per academic session | slb_book_class_subject_jnt | Baseline: varies by school | Per session |
| Approved Notes % | (Approved notes / Total notes submitted) × 100 | slb_notes.status | > 80% (quality signal) | Monthly |
| Top 5 Downloaded Books | Book files with highest download count in period | slb_book_downloads | — | Monthly |
| Top 5 Rated Notes | Notes with highest average rating | slb_notes_ratings | — | Monthly |
| Student Upload Rate | Notes submitted by students per month | slb_notes.created_by role | Track trend | Monthly |
| Approval Cycle Time | Average hours from submission to approval decision | slb_notes.created_at vs status change at | < 48 hours | Monthly |

---

<a name="screens"></a>
## Section 9 — Feature Specification (Screen-Level Detail)

### Screen 1: Dashboard / Master Index (`GET /syllabus-books/`)

**Purpose:** Tabbed overview of all module data.
**Layout:** Tabbed (Books | Authors | Notes | Note Downloads | Note Ratings | Book File Downloads)
**Empty State per tab:** "No [books/authors/notes] found matching your filters."
**Permissions:** Any user with `tenant.syllabus-books.book.viewAny` [ENH-SLK-006 proposed name]

**Tab: Books**

| # | Field (Business Label) | Type | Filters / Notes |
|---|---|---|---|
| 1 | Search | Text | Searches title, subtitle, description |
| 2 | ISBN Filter | Text | Partial match |
| 3 | Publisher Filter | Text | Partial match |
| 4 | Language Filter | Dropdown | From language dropdown master |
| 5 | Author Filter | Dropdown | Active authors list |
| 6 | NCERT Flag | Yes/No | Checkbox filter |
| 7 | CBSE Recommended | Yes/No | Checkbox filter |
| 8 | Status Filter | Active / Inactive | |
| — | Book list columns: Title, ISBN, Publisher, Authors, Files count, Chapters count, Classes assigned, Status | — | Actions: View, Edit, Delete, Toggle |

**Tab: Authors**

| # | Field | Type | Notes |
|---|---|---|---|
| 1 | Search | Text | Name, bio |
| 2 | Qualification Filter | Text | Partial match |
| 3 | Status Filter | Active / Inactive | |
| — | Author list: Name, Qualification, Book Count, Status | — | Actions: View, Edit, Delete, Toggle |

**Tab: Notes**

| # | Field | Type | Notes |
|---|---|---|---|
| 1 | Search | Text | Title |
| 2 | Class Filter | Dropdown | |
| 3 | Subject Filter | Dropdown | |
| 4 | Note Type Filter | Dropdown | All 9 types |
| 5 | Status Filter | Dropdown | Draft / Pending / Approved / Rejected / Archived |
| — | Notes list: Title, Type, Class, Subject, Status, Average Rating, Download Count, Uploader | — | Actions: View, Approve, Reject, Edit, Delete |

---

### Screen 2: Book Create / Edit

**Purpose:** Add a new book or edit an existing one.
**Layout:** Three-column form with four sections (Book Details, Authors, Class Assignments, Cover Image)
**Actions:** Save, Cancel
**Permissions:** Create (add), Update (edit)

| # | Field | Required | Validation | Notes |
|---|---|---|---|---|
| 1 | Book Title | Yes | max:100 chars | |
| 2 | Subtitle | No | max:255 | |
| 3 | ISBN | No | max:20; unique in catalog | Show "ISBN taken" if duplicate |
| 4 | Publisher | No | max:150 | |
| 5 | Language | No | From dropdown | |
| 6 | Edition | No | max:50 | |
| 7 | Publication Year | No | 1900–current year | Year picker |
| 8 | Total Pages | No | min:1 | Used for page-range cap |
| 9 | Description | No | max:512 | Textarea |
| 10 | Tags | No | Comma-separated | Stored as JSON |
| 11 | Is NCERT | No | Boolean | Checkbox |
| 12 | Is CBSE Recommended | No | Boolean | Checkbox |
| 13 | Cover Image | No | jpg/jpeg/png/webp; max 2 MB | Thumbnail preview |
| 14 | Authors (repeatable) | No | author_id exists; role valid | Repeatable row: Author dropdown + Role dropdown |
| 15 | Class Assignments (repeatable) | No | class_id, subject_id exist; session tenant-scoped | Repeatable row: Class + Subject + Session + Primary + Mandatory |

---

### Screen 3: Author Create / Edit

**Purpose:** Add or edit a book author.

| # | Field | Required | Validation |
|---|---|---|---|
| 1 | Author Name | Yes | max:150; unique |
| 2 | Qualification | No | max:200 |
| 3 | Biography | No | Textarea |
| 4 | Active Status | No (default: Active) | Toggle |

---

### Screen 4: Note Create

**Purpose:** Upload a study note linked to class, subject, and optionally a book/chapter.

| # | Field | Required | Validation | Notes |
|---|---|---|---|---|
| 1 | Title | Yes | max:255 | |
| 2 | Description | No | Textarea | |
| 3 | Note Type | Yes | Selection | Revision Notes, Practice Questions, Formula Sheet, Mind Map, Flow Chart, Cheat Sheet, Summary, Worksheet, Other |
| 4 | Class | Yes | exists | Cascades to Subject dropdown |
| 5 | Subject | Yes | exists | |
| 6 | Academic Session | Yes | tenant-scoped | Defaults to current session |
| 7 | Linked Book | No | exists:slb_books | Cascades to Chapter dropdown |
| 8 | Linked Chapter | No | exists:slb_book_chapters; belongs to selected book | |
| 9 | Visibility | Yes | Selection | Class Only, Subject Wide, School Wide |
| 10 | Downloadable | No (default from Settings) | Toggle | |
| 11 | Note File | Yes | MIME + size from Settings | Primary document upload |
| 12 | Additional Files | No | Same as above | Optional supporting attachments |

---

### Screen 5: Module Settings / Configuration

**Purpose:** School Admin configures module-wide rules.
**Permissions:** School Admin only.

| Section | Setting | Type | Default |
|---|---|---|---|
| Book Settings | Max File Size (MB) | Numeric | 50 |
| Book Settings | Allowed Formats | Multi-select (PDF, EPUB, JPG, PNG, DOCX, MOBI) | PDF, EPUB |
| Book Settings | Default Downloadable | Toggle | On |
| Notes Settings | Max File Size (MB) | Numeric | 10 |
| Notes Settings | Allowed Formats | Multi-select (PDF, DOCX, JPG, PNG) | PDF, DOCX |
| Notes Settings | Default Downloadable | Toggle | On |
| Student Uploads | Allow Student Uploads | Toggle | Off |
| Student Uploads | Require Approval | Toggle | On |
| Student Uploads | Max Uploads Per Day | Numeric | 5 |
| Student Uploads | Max Per Subject | Numeric | 3 |
| Teacher Upload Approval | Require Approval | Toggle | Off |
| Content Protection | Enable Watermark | Toggle | Off |
| Content Protection | Watermark Text | Free text | — |
| Content Protection | Prevent PDF Print | Toggle | Off |
| Content Protection | Prevent PDF Copy | Toggle | Off |
| Cross-Class Visibility | Allow Cross-Class Sharing | Toggle | Off |

---

<a name="knowledge"></a>
## Section 10 — Module Knowledge Update

> Module knowledge file updated at: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SLK_SyllabusBooks.md`
> The FRD and Complete Pack are added to the knowledge file's FRD Summary and Pending Next Steps.

### FRD Summary Block (to be appended to module knowledge)

**FRD File:** SLK_FRD_2026-06-30.md
**Date:** 2026-06-30
**Counts:** REQ: 12 (P0:4, P1:7, P2:1) | BR: 21 (P0:11, P1:7, P2:3) | RPT: 4 | ENH: 6
**Complete Pack:** SLK_FRD_Complete_2026-06-30.md

### Pending Next Steps (updated)

1. **P0 Bug Fixes (Sprint 1):** Cross-layer AcademicSession fix, BookTopicMapping index() fix, bok_book_topic_mapping migration activation, cover image media store fix, missing gates, missing activity logs — see Sprint task list Section 7.2 Tasks 1–12
2. **BookService creation (Sprint 1):** Core missing service — encapsulates book CRUD, author sync, class assignment with primary-demotion, deletion constraint checks
3. **Note workflow verification (Sprint 2):** Confirm Settings-gate on student uploads, auto-approval vs approval FSM, notification dispatch
4. **REST API for portals (Sprint 2):** ENH-SLK-001 — book list endpoints for Student Portal and Parent Portal
5. **Class Book List PDF (Sprint 2):** RPT-SLK-001 — most urgently requested by schools at session start
6. **Test coverage (Sprint 2–3):** 0 → 80%+ using 23 planned test scenarios (see FRD §12 / Complete Pack §8)

### Version History (addition)

| Version | Date | Agent | Changes |
|---|---|---|---|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed |
| 1.1 | 2026-06-30 | Business Analyst | FRD v1.0 generated (12 REQ, 21 BR, 4 RPT, 6 ENH); Complete Analysis Pack generated; Notes subsystem documented; Settings spec added; Sprint task list produced |
