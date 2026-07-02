# SyllabusBooks (SLK) — Mode X Complete Audit
**Date:** 2026-06-30  
**Auditor:** Technical Auditor Agent (Mode X — A+B+C+G+D)  
**Module:** `Modules/SyllabusBooks/`  
**Prefix:** `slb_*` (shared with Syllabus module) + `bok_*` (book-topic mapping only)  
**Health Score:** 40/100 (P0-capped)  
**Deploy Gate:** ❌ NO-GO  

---

## Executive Summary

SyllabusBooks is the book catalog and study notes module. It is architecturally well-structured: 63 Gate::authorize calls across 11 controllers, 10 policies registered, 8 FormRequests with proper validation rules, and comprehensive coverage of book authorship, chapters, files, download tracking, notes, and ratings. The module has been substantially expanded in June 2026 (NoteController, NoteFileController, BookChapterController, BookFileController added) with estimated completion at ~70–75%.

However, **two P0 findings block deployment:**
1. `EnsureTenantHasModule` absent from web routes (SEC-PLATFORM-003)
2. `BookController.php` imports `Modules\Prime\Models\AcademicSession` which uses the `global_master_mysql` connection (`glb_academic_sessions` table) — a cross-layer tenancy violation. A tenant module is querying the global DB layer to obtain academic sessions, returning data shared across ALL tenants.

Additionally, all 8 FormRequests return `return true` in `authorize()` (D30), and 2 ENUM columns exist in shared slb_ tables.

---

## Health Score (40/100 — P0 Capped)

| Layer | Weight | Color | Score | Notes |
|-------|--------|-------|-------|-------|
| L1 Tenant Isolation | 15 | 🔴 Red | 0.0 | EnsureTenantHasModule absent; ARCH-SLK-01 cross-layer AcademicSession import |
| L2 Authentication | 12 | 🟢 Green | 1.0 | Full auth stack in RSP |
| L3 Authorization | 12 | 🟢 Green | 1.0 | 63 Gate::authorize calls; 10 policies registered |
| L4 Input Validation | 8 | 🟡 Amber | 0.5 | 8 FormRequests with rules; all authorize() return true (D30) |
| L5 Data Integrity | 8 | 🟡 Amber | 0.5 | 2 ENUM columns; cross-layer AcademicSession query returns global data |
| L6 Business Logic | 10 | 🟢 Green | 1.0 | Download tracking, ratings, chapter management all implemented |
| L7 Output Security | 8 | 🟢 Green | 1.0 | No unescaped user content found in views |
| L8 Error/Logging | 5 | 🟡 Amber | 0.5 | No activityLog on book/note mutations |
| L9 Performance | 5 | 🟡 Amber | 0.5 | Cross-layer AcademicSession queries on every book index/show |
| L10 Code Quality | 7 | 🟢 Green | 1.0 | Clean controller structure; services for BookChapter, BookFile |
| L11 Feature Completeness | 10 | 🟡 Amber | 0.5 | Notes/books/chapters/files present; slb_books vs bok_books ambiguity unresolved |
| L12 Gap Analysis | 0 | — | — | New finding: ARCH-SLK-01; D30 confirmed |

**Raw: P0 present → capped at 40/100. Deploy: NO-GO.**

---

## Deploy Gate Verdict

| Gate | Status | Reason |
|------|--------|--------|
| ❌ Tenant Isolation | BLOCK | SEC-SLK-01: EnsureTenantHasModule absent from all routes |
| ❌ Cross-Layer | BLOCK | ARCH-SLK-01: BookController queries global_db via Prime\AcademicSession |
| ⚠️ Validation | WARN | All 8 FormRequests return authorize()=true (D30) |
| ✅ Authorization | PASS | 63 Gate::authorize calls; 10 registered policies |
| ✅ Payment Security | PASS | Download tracking uses auth-scoped student resolution |
| ✅ Policy Coverage | PASS | AuthorPolicy, BookPolicy, NotePolicy, BookFilePolicy, etc. all registered |

---

## P0 Findings (Critical — Deploy Blockers)

### SEC-SLK-01: EnsureTenantHasModule Missing from Web Routes
**Severity:** P0 | **Layer:** Tenant Isolation | **Platform Pattern:** SEC-PLATFORM-003

**Evidence:**
```php
// Modules/SyllabusBooks/app/Providers/RouteServiceProvider.php:41–51
protected function mapWebRoutes(): void
{
    Route::middleware([
            'web',
            InitializeTenancyByDomain::class,
            PreventAccessFromCentralDomains::class,
            EnsureTenantIsActive::class,
            'auth',
            'verified',
            // MISSING: EnsureTenantHasModule::class
        ])
```

**Confirmation:** `grep -n "module:" Modules/SyllabusBooks/routes/web.php` → 0 results.

**Fix:** Add `\App\Http\Middleware\EnsureTenantHasModule::class` to mapWebRoutes() middleware, or use `Route::middleware('module:SYLLABUSBOOKS')` group in web.php.

---

### ARCH-SLK-01: Cross-Layer AcademicSession Import — Tenant Module Queries Global DB
**Severity:** P0 | **Layer:** Tenant Isolation

**Evidence:**
```php
// Modules/SyllabusBooks/app/Http/Controllers/BookController.php
Line 18: use Modules\Prime\Models\AcademicSession;

Line 51: $currentSession = AcademicSession::where('is_current', 1)->first();
Line 54: $sessions = AcademicSession::orderBy('start_date', 'desc')->get();
Line 97: if (!AcademicSession::where('id', $value)->exists()) { ... }
Line 186: $currentSessionId = AcademicSession::where('is_current', 1)->value('id');
Line 369: $currentSession = AcademicSession::where('is_current', 1)->first();
Line 372: $sessions = AcademicSession::orderBy('start_date', 'desc')->get();
Line 397: if (!AcademicSession::where('id', $value)->exists()) { ... }
Line 474: $currentSessionId = AcademicSession::where('is_current', 1)->value('id');
```

**Root cause — from `Modules/Prime/app/Models/AcademicSession.php`:**
```php
class AcademicSession extends Model
{
    protected $connection = 'global_master_mysql';   // ← GLOBAL DB, not tenant
    protected $table = 'glb_academic_sessions';      // ← glb_ prefix = global layer
```

**The correct model exists but was commented out:**
```php
// BookController.php:74 (commented):
// $sessions = OrganizationAcademicSession::where('is_current', 1)->get();
```

**Impact (3-layer architecture violation):**
1. **Wrong data returned:** `glb_academic_sessions` contains academic year data shared globally (not tenant-specific). A school gets academic sessions from the global pool, not their own `sch_organization_academic_sessions` records.
2. **Tenancy isolation broken:** The query bypasses the tenant DB connection entirely and hits `global_master_mysql`. In a multi-tenant context, one tenant's book assignment can reference a session belonging to another tenant's academic calendar.
3. **FK validation broken:** Line 97 validates that a submitted `academic_session_id` exists in `glb_academic_sessions`, but the actual FK on `slb_book_class_subject_jnt` references the tenant's academic session table — the validation checks the wrong table.
4. **Layer coupling:** Tenant modules must never import from `Modules\Prime` (central/prime layer). Prime models use `prime_db` or `global_master_mysql`; tenant modules use `tenant_mysql`.

**Fix:**
1. Remove `use Modules\Prime\Models\AcademicSession;` from BookController.
2. Replace with `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` (the tenant-layer model already used by other modules).
3. Replace all `AcademicSession::` calls with `OrganizationAcademicSession::` equivalents (7 lines).
4. Update FK validation to check against `sch_organization_academic_sessions`.

---

## P1 Findings (Major)

### mapApiRoutes() Missing Tenancy Stack (Dead Scaffold)
**Severity:** P1 | **Layer:** Tenant Isolation

```php
// mapApiRoutes(): Route::middleware('api')->prefix('api')->name('api.')->group(api.php)
// api.php: Route::apiResource('syllabusbooks', SyllabusBooksController::class) — not implemented
```

`SyllabusBooksController` exists as a scaffold but has no apiResource methods. No real routes served. However, the middleware-less `mapApiRoutes()` is an architectural risk for any future API additions.

---

## P2 Findings (Significant)

### VAL-SLK-001: All 8 FormRequests Return `true` in authorize() — D30 Pattern
**Severity:** P2 | **Layer:** Input Validation

| FormRequest | authorize() |
|------------|-------------|
| AuthorRequest | return true; |
| BookRequest | return true; |
| BookFileRequest | return true; |
| BookChapterBulkRequest | return true; |
| NoteRequest | return true; |
| NoteRatingRequest | return true; |
| SyllabusBookConfigRequest | return true; |
| BookTopicMappingRequest | return true; |

All 8 FormRequests accept any authenticated+verified user. Gate::authorize in the controller provides actual authorization, but the FormRequest layer adds no secondary authorization check.

### DAT-SLK-001: 2 ENUM Columns in Shared slb_ Tables
**Severity:** P2 | **Layer:** Data Integrity | **Pattern:** D29

- `slb_book_author_jnt.author_role`: ENUM ['CONTRIBUTOR', 'CO_AUTHOR', 'EDITOR', 'PRIMARY'] — used by SyllabusBooks book authorship
- `slb_syllabus_schedule.priority`: ENUM ['HIGH', 'LOW', 'MEDIUM'] — used by Syllabus module scheduling

**Note:** These tables are shared between the SLB and SLK modules. ENUM migration must be coordinated with the Syllabus module team.

### GAP-SLK-001: slb_books vs bok_books Ambiguity
**Severity:** P2 | **Layer:** Data Integrity

V2 references `bok_books` table and `bok_*` prefix. The SyllabusBooks module creates a `slb_books` table (migration `2026_06_15_145817_create_slb_books_table.php`). The BA module knowledge flagged this as unresolved. Book-lesson FK joins may reference the wrong table depending on which path was taken. Must clarify canonical book table before building any cross-module query.

---

## P3 Findings (Minor)

| Code | Finding |
|------|---------|
| DEAD-SLK-001 | `api.php` dead scaffold — SyllabusBooksController has no API methods |
| GAP-SLK-001 | Zero Pest/Feature tests across all 11 controllers |
| PERF-SLK-001 | No activityLog on book creation/update — no audit trail for catalog changes |

---

## Verified Good (PASS)

| Item | Evidence | Rating |
|------|----------|--------|
| 63 Gate::authorize calls | Present across AuthorController, BookController, NoteController, etc. | ✅ Strong |
| 10 policies registered | AuthorPolicy, BookPolicy, BookTopicMappingPolicy, SyllabusBookConfigPolicy, BookFilePolicy, BookChapterPolicy, NotePolicy, NoteDownloadPolicy, NoteRatingPolicy, BookDownloadPolicy | ✅ Complete |
| Download tracking | SlbBookDownload + NoteDownload records created on file access | ✅ Implemented |
| Note ratings flow | NoteRatingController creates/updates rating with student scoping | ✅ Implemented |
| BookChapterService | Proper service abstraction for chapter management | ✅ Clean |
| BookFileService | Proper service abstraction for file management | ✅ Clean |
| 8 FormRequests | Validation rules present (only authorize() is D30) | ✅ Rules present |

---

## Systemic Pattern Scorecard

| Pattern | Verdict | Evidence |
|---------|---------|----------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ CONFIRMED | Not in RSP or web.php |
| Cross-layer AcademicSession import | ✅ CONFIRMED | ARCH-SLK-01: BookController imports Prime\AcademicSession (global_master_mysql) |
| D30 (authorize=true) | ✅ CONFIRMED | All 8 FormRequests |
| D29 (ENUM columns) | ✅ CONFIRMED | 2 ENUM columns in shared slb_ tables |
| D25 ($request->all()) | ❌ Not confirmed | FormRequests used consistently |
| API RSP no tenancy | ✅ CONFIRMED | mapApiRoutes() dead scaffold |

---

## Recommended Fix Order

**Sprint 1 — Unblock Deploy (P0):**
1. **ARCH-SLK-01** — Replace `Modules\Prime\Models\AcademicSession` with `Modules\SchoolSetup\Models\OrganizationAcademicSession` across 7+ lines in BookController (2 hours — high impact, targeted change)
2. **SEC-SLK-01** — Add `module:SYLLABUSBOOKS` to mapWebRoutes() or web.php group (30 min)

**Sprint 2 — Validation (P2):**
3. **VAL-SLK-001** — Update 8 FormRequest authorize() to call `auth()->check()` or real Gate check instead of `return true`
4. **GAP-SLK-001** — Resolve slb_books vs bok_books ambiguity; confirm canonical book table and update any cross-module FK joins

**Sprint 3 — Data (P2):**
5. **DAT-SLK-001** — Plan ENUM → VARCHAR migration for slb_book_author_jnt.author_role (coordinate with SLB Syllabus module for slb_syllabus_schedule.priority)

---

*Generated: 2026-06-30 | Technical Auditor Agent (Mode X) | Evidence-based; read-only pass*
