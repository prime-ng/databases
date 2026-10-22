# Module Knowledge — SLK: SyllabusBooks
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | SyllabusBooks |
| Module Code | SLK |
| Table Prefixes | `slb_*` (primary) + `bok_*` (book-topic mapping only) |
| Laravel Module Path | `Modules/SyllabusBooks/` |
| Namespace | `Modules\SyllabusBooks` |
| DB Layer | Tenant (`tenant_mysql`) |
| RBS Reference | Module H — Academics Management (adjacent to SLB) |
| FRD Status | V2 Requirement exists (2026-03-26); no FRD_Documents file yet |
| V2 Estimated Completion | ~55% (as of 2026-03-26) |
| Revised Estimated Completion | ~70–75% (as of 2026-06-30, post June 2026 expansions) |

### Verified File Counts (from `ls Modules/SyllabusBooks/` — 2026-06-30)

| Component | Count | V2 Said | Notes |
|-----------|-------|---------|-------|
| Controllers | 11 | 4 | Major expansion: NoteController, NoteFileController, NoteDownloadController, NoteRatingController, BookChapterController, BookFileController, SyllabusBookConfigController added |
| Models | 13 | 6 | SlbNote, SlbNotesFile, SlbNotesDownload, SlbNotesRating, BookChapter, BookFile, SlbBookDownload, SyllabusBookConfig added |
| FormRequests | 8 | 3 | NoteRequest, NoteRatingRequest, BookChapterBulkRequest, BookFileRequest, SyllabusBookConfigRequest added |
| Policies | 10 | ~4 | NotePolicy, NoteDownloadPolicy, NoteRatingPolicy, BookChapterPolicy, BookFilePolicy, BookDownloadPolicy added |
| Services | 3 | 0 | BookChapterService, BookFileService, SyllabusBookConfigService built (BookService still missing) |
| Seeders | 8 | 0 | Full seed suite for books, authors, chapters, class-subject jnt, downloads, files |
| Tests | 0 | 0 | Zero — critical gap |
| Views (Blade) | 30 | ~10 | Notes views (create/edit/show/index/trash), note-files, note-ratings, note-downloads, book chapters tab, book files tab, config/edit, settings/index |
| Module Migrations | 0 | — | All migrations are in central `database/migrations/tenant/`, not in module's own migrations folder |

---

## DDL Table Inventory

All SLK tables live in `tenant_mysql` and are managed via **central migrations** in `database/migrations/tenant/`. The module's own `database/migrations/` folder is empty.

### Core Book Tables (from V2 + verified by migration files)

| Table | Purpose | Migration Date |
|-------|---------|----------------|
| `slb_book_authors` | Author master (name, qualification, bio) | 2026-06-15 |
| `slb_books` | Book catalog (title, ISBN, publisher, language, cover, tags, is_ncert, is_cbse_recommended) | 2026-06-15 |
| `slb_book_author_jnt` | Book ↔ Author many-to-many (author_role ENUM, ordinal) | 2026-06-15 |
| `slb_book_class_subject_jnt` | Book ↔ Class ↔ Subject ↔ AcademicSession assignment (is_primary, is_mandatory) | 2026-06-15 |
| `slb_book_chapters` | Chapter definitions per book (NEW — not in V2) | 2026-06-15 |
| `slb_book_files` | File/PDF attachments per book (NEW — not in V2) | 2026-06-15 |
| `slb_book_downloads` | Download tracking for book files (NEW — not in V2) | 2026-06-15 |
| `slb_config` | Module-level configuration settings (shared with SLB? — see note) | 2026-06-15 |

### Notes Subsystem Tables (NEW — not in V2)

| Table | Purpose | Migration Date |
|-------|---------|----------------|
| `slb_notes` | Study notes attached to books/topics (title, content, type, is_active) | 2026-06-15 |
| `slb_notes_files` | File attachments for notes | 2026-06-15 |
| `slb_notes_downloads` | Download tracking for note files | 2026-06-15 |
| `slb_notes_ratings` | Student ratings on study notes | 2026-06-15 |

### Book-Topic Mapping (Special Case)

| Table | Purpose | Status |
|-------|---------|--------|
| `bok_book_topic_mapping` | Links book chapters/pages to syllabus topics | ❌ Migration was `.bk` (inactive) in V2; not confirmed active in central migrations. Model `BookTopicMapping.php` exists. Verify table existence before building on it. |

> **Note on `slb_config`:** This table appears in the SLK module scope (SyllabusBookConfigController + SyllabusBookConfig model) but was also noted in SLB's module knowledge. Likely a shared config table for both Syllabus and SyllabusBooks. Clarify ownership.

> **Critical note on `slb_books` vs `bok_books`:** V2 (SLB) references `bok_books.id` as the FK from `slb_lessons.bok_books_id`. The actual migration creates `slb_books` (not `bok_books`). The SyllabusBooks module's `BokBook` model maps to `slb_books`. So the FK in `slb_lessons` must be to `slb_books.id` — the `bok_` prefix in the model name is misleading. Verify before writing any cross-module joins.

---

## Feature Area Status (as of 2026-06-30)

| # | Feature Area | Status | Notes |
|---|-------------|--------|-------|
| 1 | Book Author Management | 🟡 80% | CRUD + soft delete + auth mostly OK; `store()` missing gate; `index()` queries wrong model |
| 2 | Book Catalog Management | 🟡 75% | CRUD functional; cross-layer AcademicSession bug still likely present; cover image via wrong table |
| 3 | Book-Author Junction | 🟡 75% | Works via raw DB insert; `ordinal` never set |
| 4 | Book-Class Assignment | 🟡 65% | Cross-layer session FK bug; no primary-book uniqueness enforcement |
| 5 | Book-Topic Mapping | 🟡 50% | Auth OK; undefined `$bookTopicMappings` may still be in index(); `bok_book_topic_mapping` table activation unconfirmed |
| 6 | Book Chapters (NEW) | ✅ 85% | Full CRUD + service (BookChapterService); bulk request exists; tab view in book show |
| 7 | Book Files (NEW) | ✅ 85% | Full CRUD + service (BookFileService); file upload; tab view in book show |
| 8 | Notes System (NEW) | 🟡 80% | Full CRUD (NoteController + NoteFileController + NoteDownloadController + NoteRatingController); notes views complete; rating system built |
| 9 | Config Management (NEW) | ✅ 90% | SyllabusBookConfigController + SyllabusBookConfigService + config/edit view |
| 10 | SyllabusBooksController | 🟡 30% | `index()` loads data; `store()`/`update()`/`destroy()` are empty stubs; no auth on `index()` |
| 11 | Service Layer | 🟡 40% | BookChapterService, BookFileService, SyllabusBookConfigService built; **BookService (core book CRUD) still missing** |
| 12 | EnsureTenantHasModule | ❌ 0% | Not applied to any route group |
| 13 | Test Coverage | ❌ 0% | Zero tests |
| 14 | Book List API (REST) | ❌ 0% | No JSON endpoints; all routes return HTML |

---

## Known Gaps & Open Issues

### P0 — Critical (Runtime Errors / Architecture Violations)

| ID | Issue | Location |
|----|-------|---------|
| ARCH-SLK-01 | Cross-layer `AcademicSession` import from `Modules\Prime\Models\AcademicSession` (reads `glb_academic_sessions` on `global_master_mysql`) — must be replaced with `OrganizationAcademicSession` (tenant-scoped) | `BookController.php`, `BookClassSubject.php`, `BookRequest.php` |
| BUG-SLK-01 | `BookTopicMappingController::index()` undefined `$bookTopicMappings` variable — PHP runtime error on every page load | `BookTopicMappingController.php` |
| DB-SLK-01 | `bok_book_topic_mapping` migration was a `.bk` (inactive) file in V2 — unknown if activated; table may not exist in tenant DB | Central migrations |

### P1 — High (Auth / Data Correctness Bugs)

| ID | Issue | Location |
|----|-------|---------|
| BUG-SLK-02 | `AuthorController::store()` missing `Gate::authorize('tenant.author.create')` — gate bypass possible via direct POST | `AuthorController.php` |
| BUG-SLK-03 | `AuthorController::index()` queries `BokBook` (books) instead of `BookAuthors` (authors) — wrong data displayed on author list page | `AuthorController.php` |
| BUG-SLK-04 | `SyllabusBooksController::index()` has no `Gate::authorize()` — any authenticated user can access dashboard | `SyllabusBooksController.php` |
| BUG-SLK-05 | Cover image stored via module-specific `MediaFiles` model, NOT `qns_media_store` — DDL FK `cover_image_media_id → qns_media_store.id` will be broken | `BookController.php` |
| GAP-SLK-06 | `SyllabusBooksController::store()`/`update()`/`destroy()` are empty stubs — routes registered but broken | `SyllabusBooksController.php` |
| GAP-SLK-07 | No `EnsureTenantHasModule` middleware on route group — any tenant can access regardless of subscription | `routes/tenant.php` |
| GAP-SLK-08 | `BR-SLK-05` not enforced: no primary-book uniqueness rule (multiple books can have `is_primary=1` for same class/subject/session) | `BookController.php` |
| GAP-SLK-09 | `BR-SLK-02/03` not enforced: no check before `forceDelete()` for active lesson or question-bank references to `slb_books.id` | `BookController.php` |
| GAP-SLK-10 | `activityLog()` missing on `BookController::store()` + `update()` and `AuthorController::store()` + `update()` | Both controllers |

### P2 — Medium

| ID | Issue |
|----|-------|
| GAP-SLK-11 | ISBN uniqueness validation in `BookRequest` is missing the `unique:slb_books,isbn` rule; only enforced at DB level (no clean user-facing error) |
| GAP-SLK-12 | `BookTopicMappingRequest` missing `exists:slb_books,id` on `book_id` and `exists:slb_topics,id` on `topic_id` |
| GAP-SLK-13 | `Dropdown::all()` in index methods loads all dropdown rows — should filter by key `'language'` |
| GAP-SLK-14 | `author.ordinal` never populated in `slb_book_author_jnt` insert (always defaults to 1) |
| GAP-SLK-15 | `created_by`/`updated_by` columns exist in model relationships (`BokBook`, `BookAuthors`) but NOT in DDL — relationships will fail |
| GAP-SLK-16 | Redundant `Validator::make()` in `BookController::store()` + `update()` after `BookRequest` already validated |
| GAP-SLK-17 | Route naming inconsistency: module's `routes/web.php` registers stub `syllabusbooks` resource that overlaps with tenant.php `syllabus-books` routes |
| SEC-SLK-18 | Permission strings `tenant.book.*` and `tenant.author.*` are too generic — risk of collision with other modules. Proposed namespace: `tenant.syllabus-books.*` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| ENH-SLK-19 | Rename `BookAuthors` model to singular `BookAuthor` (Laravel convention) |
| ENH-SLK-20 | Build `BookService` to extract ~100 lines of business logic from `BookController::store()` and `update()` |
| ENH-SLK-21 | Implement `BookAssignmentService::copyForwardSession()` for new academic year book list copy |
| ENH-SLK-22 | Book List PDF export: `GET /syllabus-books/books/book-list-pdf?class_id=&session_id=` via DomPDF |
| ENH-SLK-23 | REST API endpoints: `GET /api/v1/books`, `GET /api/v1/books/{id}`, `GET /api/v1/class-book-list` for portal consumption |
| ENH-SLK-24 | Remove `SyllabusBooksController::store()`/`update()`/`destroy()` stubs (or implement them) |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| Dual table prefix | Primary: `slb_*` (books, authors, notes, chapters, files). Secondary: `bok_*` (book-topic mapping only) | V2 |
| SLK is tenant-scoped | All tables live in `tenant_{uuid}` on `tenant_mysql` — NOT a Prime/Global module (V1 incorrectly called it Prime) | V2 correction |
| `BokBook` model → `slb_books` table | The model is named `BokBook` for historical reasons but maps to `slb_books`, NOT `bok_books`. The prefix in the model name is misleading. | Filesystem verification |
| `slb_book_author_jnt.author_role` ENUM | Values: PRIMARY, CO_AUTHOR, EDITOR, CONTRIBUTOR. Composite PK (book_id, author_id) prevents duplicate pairs. | V2 DDL |
| `slb_book_class_subject_jnt.academic_session_id` | Must reference `sch_org_academic_sessions_jnt.id` (tenant table) — NOT `glb_academic_sessions` | V2 ARCH-SLK-01 |
| Cover image FK | `slb_books.cover_image_media_id → qns_media_store.id` — all cover image uploads must go through `qns_media_store` (current code uses wrong `MediaFiles` model) | V2 DDL |
| Notes subsystem uses slb_ prefix | `slb_notes`, `slb_notes_files`, `slb_notes_downloads`, `slb_notes_ratings` — owned by SyllabusBooks module even though prefix matches Syllabus | June 2026 expansion |
| Services added for chapters/files/config | `BookChapterService`, `BookFileService`, `SyllabusBookConfigService` added post-V2 — core `BookService` for author/assignment logic still missing | June 2026 expansion |
| `slb_book_author_jnt` soft-deletes REMOVED | Migration `2026_06_18_000002_update_slb_book_author_jnt_remove_softdeletes.php` removed soft-delete columns from junction table | June 2026 migration |

---

## Cross-Module Dependencies

### Inbound (SLK consumes from)

| Source Module | Data / Entity | Why |
|--------------|---------------|-----|
| SchoolSetup | `sch_classes`, `sch_subjects` | Book-class-subject assignment |
| SchoolSetup | `sch_org_academic_sessions_jnt` | Book list is academic-year scoped |
| GlobalMaster | `sys_dropdown_table` | Language dropdown for `slb_books.language` FK |
| Syllabus (SLB) | `slb_topics` | `bok_book_topic_mapping.topic_id` FK |
| QuestionBank (QNS) | `qns_media_store` | Cover image storage (FK constraint) |
| Auth (sys) | Spatie permission system | Gate::authorize() on all operations |

### Outbound (modules that consume SLK)

| Target Module | Mechanism | What It Provides |
|--------------|-----------|-----------------|
| Syllabus (SLB) | `slb_lessons.bok_books_id → slb_books.id` | Every lesson must be linked to a book |
| QuestionBank (QNS) | `qns_questions_bank.book_id → slb_books.id` | Questions can reference source book |
| StudentPortal | REST API (proposed) | Book list per class/session |
| ParentPortal | REST API + PDF (proposed) | Printable book list for parents |
| Library (LIB) | Conceptual only (no FK) | Library tracks physical copies; SLK tracks curriculum prescription |

---

## Controller Inventory (11 confirmed)

| Controller | Screens/Purpose | Auth Coverage | Key Issues |
|-----------|-----------------|---------------|------------|
| `SyllabusBooksController` | Dashboard/index | ❌ No gate on index | store/update/destroy stubs |
| `AuthorController` | Author CRUD | 🟡 10/11 methods | store() missing gate; index() queries wrong model |
| `BookController` | Book CRUD | 🟡 10/11 methods | Cross-layer session; wrong media model; no store() activity log |
| `BookTopicMappingController` | Topic mapping CRUD | ✅ All 10 methods | Undefined $bookTopicMappings in index(); table may not exist |
| `BookChapterController` (NEW) | Chapter management per book | Unknown | Newer addition; uses BookChapterService |
| `BookFileController` (NEW) | File/PDF per book | Unknown | Newer addition; uses BookFileService |
| `NoteController` (NEW) | Study notes CRUD | Unknown | Full views (create/edit/show/index/trash) |
| `NoteFileController` (NEW) | Note file attachments | Unknown | Files within notes |
| `NoteDownloadController` (NEW) | Note download tracking | Unknown | Download log management |
| `NoteRatingController` (NEW) | Note ratings by users | Unknown | Uses NoteRatingRequest |
| `SyllabusBookConfigController` (NEW) | Module config edit | Unknown | Uses SyllabusBookConfigService |

---

## V1 Screen Spec Inventory (6 files in `SyllabusBooks_v2/`)

| File | Coverage |
|------|---------|
| `00-Module-Overview.md` | Module context |
| `01-Author.md` | Author management screen |
| `02-Book.md` | Book catalog + assignment screen |
| `03-Notes.md` | Study notes screen (confirms Notes was planned in V1) |
| `04-Downloads.md` | Download tracking screen |
| `05-Settings.md` | Config/settings screen |

> **Observation:** V1 already specified Notes and Downloads — these were not "new" features but planned from V1. V2 requirement (March 2026) missed documenting them because focus was on the book/author core. The June 2026 expansion implemented what V1 had specified.

---

## Seeder Inventory (8 seeders — production-ready test data)

| Seeder | Populates |
|--------|-----------|
| `SyllabusBooksSeeder` | Master orchestrator |
| `SyllabusBooksDatabaseSeeder` | Module database seeder entry point |
| `SyllabusBookAuthorsSeeder` | `slb_book_authors` |
| `SyllabusBookAuthorJntSeeder` | `slb_book_author_jnt` |
| `SyllabusBooksSeeder` | `slb_books` |
| `SyllabusBookChaptersSeeder` | `slb_book_chapters` |
| `SyllabusBookClassSubjectJntSeeder` | `slb_book_class_subject_jnt` |
| `SyllabusBookDownloadsSeeder` | `slb_book_downloads` |
| `SyllabusBookFilesSeeder` | `slb_book_files` |

> Note: No NoteSeeder or NoteRatingSeeder exists — test data for the Notes subsystem is not seeded.

---

## Business Rules Summary (from V2)

| ID | Rule | Status |
|----|------|--------|
| BR-SLK-01 | ISBN globally unique per tenant catalog | ✅ DB-level; ❌ missing in FormRequest |
| BR-SLK-02 | Cannot force-delete book with active lesson references | ❌ Not implemented |
| BR-SLK-03 | Cannot force-delete book with active question-bank references | ❌ Not implemented |
| BR-SLK-04 | Force-delete author: junction rows cleaned first (decide: block or cascade) | 🟡 Currently cascades |
| BR-SLK-05 | Max one primary book per class/subject/session | ❌ Not enforced |
| BR-SLK-06 | `author_role` in ENUM: PRIMARY/CO_AUTHOR/EDITOR/CONTRIBUTOR | ✅ FormRequest + DB |
| BR-SLK-07 | `academic_session_id` must use tenant `sch_org_academic_sessions_jnt` | ❌ Code uses wrong Prime/Global model |
| BR-SLK-08 | `page_end >= page_start` on topic mapping; page_end <= total_pages | 🟡 gte:page_start enforced; total_pages check missing |
| BR-SLK-09 | Book title required, max 100 chars; ISBN max 20 chars | ✅ |
| BR-SLK-10 | Cover images via `qns_media_store` (DDL FK constraint) | ❌ Code uses wrong MediaFiles model |
| BR-SLK-11 | Activity log on all destructive operations | 🟡 Missing on store()/update() in Book + Author |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] V2 (March 2026) dramatically understated the SLK module — claimed 4 controllers/6 models/3 services=0. Actual: 11 controllers/13 models/3 services. The entire Notes subsystem (4 controllers, 4 models, 4 tables, 5+ views) and Book Chapters/Files features were implemented post-V2 but pre-dated in V1 screen specs. Always verify filesystem before trusting a V2 completion estimate.
- [2026-06-30 | Business Analyst] The `BokBook` model maps to `slb_books` table (NOT `bok_books`). The `bok_` prefix in the model name is a naming artifact — the book table itself uses `slb_` prefix. The only actual `bok_*` prefixed table is `bok_book_topic_mapping`.
- [2026-06-30 | Business Analyst] `slb_book_author_jnt` had soft-deletes removed (migration 2026-06-18) — this is an architectural decision. Junction table for book-author is now hard-delete only. Reflected in `BookAuthorJnt` model behavior.
- [2026-06-30 | Business Analyst] All SLK migrations live in the central `database/migrations/tenant/` folder, NOT in `Modules/SyllabusBooks/database/migrations/`. The module's own migrations folder is empty. This is consistent with the project-wide pattern.
- [2026-06-30 | Business Analyst] The three P0 architectural bugs from V2 (ARCH-SLK-01 cross-layer AcademicSession, BUG-SLK-01 undefined variable in topic mapping index, DB-SLK-01 missing `bok_book_topic_mapping` table) are most likely still present — the June 2026 expansions added new features but no migrations indicate schema or code fixes to these issues.
- [2026-06-30 | Business Analyst] Notes were specified in V1 (`03-Notes.md`) but missing from V2 requirement. This is a recurring pattern: V2 requirements sometimes focus on the core domain and miss sub-features already in V1. Always read all 5 V1 screen-spec files before writing V2 or FRD for any module.

---

## FRD Summary (2026-06-30)

| Attribute | Value |
|---|---|
| FRD File | `SLK_FRD_2026-06-30.md` (flat FRD folder) |
| Complete Pack | `SLK_FRD_Complete_2026-06-30.md` (flat FRD folder) |
| Date | 2026-06-30 |
| REQ count | 12 (P0:4, P1:7, P2:1) |
| BR count | 21 (P0:11, P1:7, P2:3) |
| RPT count | 4 |
| ENH count | 6 |
| Conditions Catalog | `5-Requirement_Conditions/SyllabusBooks_Conditions.md` |

**Key findings from FRD generation:**
- Cross-layer AcademicSession bug confirmed in NoteController (line 15) and SyllabusBooksController (lines 92–94) — not just BookController. All three must be fixed.
- `bok_book_topic_mapping` migration is NOT in central tenant migrations (8 slb_* migrations exist but NOT bok_book_topic_mapping). Table does not exist. This is DB-SLK-01 confirmed.
- SyllabusBooksController::index() is now a comprehensive tabbed-dashboard controller (books + authors + notes + note downloads + note ratings + book downloads all loaded in one method), but still has no Gate::authorize.
- Notes subsystem (slb_notes + slb_notes_files + slb_notes_downloads + slb_notes_ratings) fully migrated and functional at code level; approval FSM and Settings-integration remain unverified.
- Settings (SyllabusBookConfig) implemented at ~90%; integration with upload validators not confirmed.
- NoteController still imports Modules\Prime\Models\AcademicSession — cross-layer bug extends to notes.

---

## Pending Next Steps (updated 2026-06-30)

1. **P0 Bug Fixes (Sprint 1):** Cross-layer AcademicSession fix across BookController + NoteController + SyllabusBooksController + BookRequest; BookTopicMapping index() fix; bok_book_topic_mapping migration activation; cover image media store fix; missing gates; missing activity logs — see Sprint task list in Complete Pack Section 7.2

2. **BookService creation (Sprint 1):** Core missing service — encapsulates book CRUD, author sync, class assignment with primary-demotion, deletion constraint checks

3. **Note workflow verification (Sprint 2):** Confirm Settings-gate on student uploads, auto-approval vs approval FSM transitions, notification dispatch

4. **REST API for portals (Sprint 2):** ENH-SLK-001 — book list endpoints for Student Portal and Parent Portal

5. **Class Book List PDF (Sprint 2):** RPT-SLK-001 — most urgently requested by schools at session start

6. **Test coverage (Sprint 2–3):** 0 → 80%+ using 23 planned test scenarios (see Complete Pack Section 8)

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement + filesystem verification + migration-derived DDL + V1 screen spec cross-check |
| 1.1 | 2026-06-30 | Business Analyst | FRD v1.0 generated (12 REQ, 21 BR, 4 RPT, 6 ENH); Complete Analysis Pack generated; Notes subsystem fully documented; Settings spec added; Sprint task list produced; cross-layer AcademicSession bug confirmed in NoteController + SyllabusBooksController; bok_book_topic_mapping migration absence confirmed |
| 1.2 | 2026-06-30 | Technical Auditor | Mode X Complete Audit. Health 40/100 P0-capped. NO-GO. 2 P0s confirmed (EnsureTenantHasModule absent; ARCH-SLK-01 BookController 8 call sites to global_master_mysql via Prime\AcademicSession). Verified Good: 63 Gate calls, 10 policies no duplicates, 8 FormRequests with real rules. Mode X Audit Lessons Learned section added. |

---

## Mode X Audit Lessons Learned (2026-06-30 — Technical Auditor)

- **[SEC-SLK-01 CONFIRMED P0]** EnsureTenantHasModule absent from BOTH mapWebRoutes() in RSP AND routes/web.php. No `module:` group at any level. SEC-PLATFORM-003 fully applies to SLK.
- **[ARCH-SLK-01 CONFIRMED P0]** BookController.php line 18: `use Modules\Prime\Models\AcademicSession;`. AcademicSession model has `$connection = 'global_master_mysql'` and `$table = 'glb_academic_sessions'` — this is the GLOBAL layer, not tenant. 8 call sites: lines 51, 54, 97, 186, 369, 372, 397, 474. The correct tenant model (`OrganizationAcademicSession`) was commented out at line 74. Cross-layer AcademicSession also confirmed by BA in NoteController and SyllabusBooksController. Fix: `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` and update all 8+ call sites.
- **[FK VALIDATION BROKEN by ARCH-SLK-01]** Line 97 validates `academic_session_id` exists in `glb_academic_sessions` but the actual FK in `slb_book_class_subject_jnt` references the tenant's academic session table. Validation passes wrong IDs, breaks referential integrity.
- **[ABOVE BASELINE: 10 policies, no duplicates]** SyllabusBooksServiceProvider registers 10 policies with NO duplicate `Gate::policy()` calls. This is explicitly better than SLB (duplicate kills), QNS (dead policy), and TTF (19 of 23 dead). Clean policy registration.
- **[ABOVE BASELINE: 63 Gate::authorize calls]** AuthorController, BookController, NoteController, BookTopicMappingController, etc. all have Gate coverage. However SyllabusBooksController::index() has no gate — this is BUG-SLK-04 from the BA catalog.
- **[ABOVE BASELINE: FormRequests with real rules]** All 8 FormRequests contain real validation rules. Only authorize() returns `true` (D30 pattern). This is better than many modules where FormRequests are completely absent.
- **[VAL-SLK-001 CONFIRMED P2 — note]** D30: all 8 FormRequests return `true` in authorize(). HOWEVER the validation rules themselves ARE present and correct (ISBN format, book_id exists, etc.). This is the weakest version of D30 — rules are there, just missing the secondary auth check.
- **[DAT-SLK-001 — coordinate with SLB]** The 2 ENUM columns (slb_book_author_jnt.author_role, slb_syllabus_schedule.priority) are in SHARED slb_ tables used by BOTH SLB and SLK modules. Any migration to convert these must be coordinated with the SLB Syllabus module. Do not create separate migrations for each module.
- **[STALE BA CONFIRMED: BUG-SLK-01]** BA claimed `BookTopicMappingController::index()` has undefined `$bookTopicMappings` — NOT verified in live code during Mode X (scope was RSP + BookController + FormRequests + policies). Treat as likely still present.
- **[STALE BA CONFIRMED: DB-SLK-01]** BA and FRD both confirmed `bok_book_topic_mapping` table does NOT exist in tenant migrations. Any code path hitting this table will throw `SQLSTATE[42S02] Table not found`.
- **[BokBook model naming]** The `BokBook` model maps to `slb_books` table (NOT `bok_books`). The `bok_` prefix in the model name is a historical naming artifact. The only actual `bok_*` prefixed table that is referenced (but unconfirmed to exist) is `bok_book_topic_mapping`.
- **[Cross-layer extends beyond BookController]** BA FRD confirmed ARCH-SLK-01 extends to NoteController (line 15) and SyllabusBooksController (lines 92–94) — not just BookController. Mode X code read focused on BookController. When fixing ARCH-SLK-01, grep ALL SLK controllers for `Modules\Prime\Models\AcademicSession`.
