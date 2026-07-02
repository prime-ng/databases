# Syllabus (SLB) — Mode X Complete Audit
**Date:** 2026-06-30  
**Auditor:** Technical Auditor Agent (Mode X — A+B+C+G+D)  
**Module:** `Modules/Syllabus/`  
**Prefix:** `slb_*` (14 core + 7 extended = 21 tables)  
**Health Score:** 40/100 (P0-capped)  
**Deploy Gate:** ❌ NO-GO  

---

## Executive Summary

Syllabus is the NEP 2020-aligned curriculum management module covering lesson/topic hierarchy, Bloom's taxonomy, competency framework, syllabus scheduling, and LMS resource release. The June 27, 2026 commit (`adca1dfbb`) substantially upgraded the module: `SyllabusController` now has ~1776 lines covering master, bloom, planning, report, saveSequencing, saveScheduling, autoSchedule, toggleLock, saveSetting, and updatePlanningDates. Revised completion: ~78%.

However, **four P0 findings block deployment:**
1. `EnsureTenantHasModule` absent from web routes (SEC-PLATFORM-003)
2. Zero Gate::authorize on ALL 9 `CompetencieController` methods — NEP competency management is completely ungated
3. `TopicController::destroy()` calls `forceDelete()` — every "delete" operation permanently destroys topic data with no SoftDeletes safety net
4. `Competencie` model lacks the SoftDeletes trait and `deleted_at` column

A **P1 bug** destroys two policy registrations: `Gate::policy(Lesson::class, ...)` is registered twice in ServiceProvider, with the second call (`SyllabusReportPolicy`) silently overriding and killing `LessonPolicy`. Same for `Competencie::class` — `CompetencyPolicy` is dead.

---

## Health Score (40/100 — P0 Capped)

| Layer | Weight | Color | Score | Notes |
|-------|--------|-------|-------|-------|
| L1 Tenant Isolation | 15 | 🔴 Red | 0.0 | EnsureTenantHasModule absent from mapWebRoutes() |
| L2 Authentication | 12 | 🟢 Green | 1.0 | Full auth stack in RSP |
| L3 Authorization | 12 | 🔴 Red | 0.0 | CompetencieController zero auth; duplicate policy kills LessonPolicy |
| L4 Input Validation | 8 | 🟡 Amber | 0.5 | 15 FormRequests exist; all return true (D30); $request->all() in CompetencieController |
| L5 Data Integrity | 8 | 🔴 Red | 0.0 | P0: forceDelete() in TopicController; Competencie no SoftDeletes |
| L6 Business Logic | 10 | 🟡 Amber | 0.5 | Scheduling/lock/release implemented; autoSchedule missing guards; cron no date filter |
| L7 Output Security | 8 | 🟢 Green | 1.0 | No unescaped user content found in key views |
| L8 Error/Logging | 5 | 🟡 Amber | 0.5 | No activityLog on topic/competency mutations |
| L9 Performance | 5 | 🟡 Amber | 0.5 | Cross-module SchoolSetup reads in SyllabusController |
| L10 Code Quality | 7 | 🟡 Amber | 0.5 | Duplicate policy registration; typo: Competencie/Competency naming inconsistency |
| L11 Feature Completeness | 10 | 🟡 Amber | 0.5 | Study Notes: 4 tables, 0 controllers; Report export backend missing |
| L12 Gap Analysis | 0 | — | — | 22 BA gaps; 6 P0 confirmed; 2 new (SyllabusController auth pattern) |

**Raw: P0 present → capped at 40/100. Deploy: NO-GO.**

---

## Deploy Gate Verdict

| Gate | Status | Reason |
|------|--------|--------|
| ❌ Tenant Isolation | BLOCK | SEC-SLB-01: EnsureTenantHasModule absent |
| ❌ Authorization | BLOCK | GAP-SLB-001: Zero auth on CompetencieController (9 methods) |
| ❌ Data Safety | BLOCK | GAP-SLB-003: TopicController::destroy() calls forceDelete() |
| ❌ Data Safety | BLOCK | GAP-SLB-004: Competencie model lacks SoftDeletes |
| ⚠️ Policy Bug | WARN | BUG-SLB-DUPOLICIES: LessonPolicy and CompetencyPolicy both dead |
| ✅ Bloom/Cognitive Auth | PASS | Gate::authorize present in BloomTaxonomyController, CognitiveSkillController |
| ✅ Topic Auth | PASS | 156 Gate::authorize calls across all other controllers |
| ✅ Schedule Lock | PASS | toggleLock() implemented; is_locked guard on schedule operations |

---

## P0 Findings (Critical — Deploy Blockers)

### SEC-SLB-01: EnsureTenantHasModule Missing from Web Routes
**Severity:** P0 | **Layer:** Tenant Isolation | **Platform Pattern:** SEC-PLATFORM-003

**Evidence:**
```php
// Modules/Syllabus/app/Providers/RouteServiceProvider.php:41–51
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

**Confirmation:** `grep -n "module:" /Modules/Syllabus/routes/web.php` → 0 results. No route-level module guard either.

**Fix:** Add `\App\Http\Middleware\EnsureTenantHasModule::class` (or `'module:SYLLABUS'`) to mapWebRoutes() middleware array, or add a `Route::middleware('module:SYLLABUS')` group in web.php.

---

### GAP-SLB-001: Zero Gate::authorize on ALL CompetencieController Methods
**Severity:** P0 | **Layer:** Authorization

**Evidence:**
```bash
grep -rn "Gate::authorize" Modules/Syllabus/app/Http/Controllers/CompetencieController.php
# → 0 results
```

**Impact:** All 9 methods (index, create, store, show, edit, update, destroy, restore, forceDelete) on the NEP competency framework are accessible to any `auth+verified` user regardless of their permissions. Any teacher or staff member can create, modify, or delete competency mappings — the core of the NEP curriculum structure.

**Fix:** Add `Gate::authorize('tenant.competency.{ability}')` as the first line of each method. Register a `CompetenciePolicy` (or use the existing `CompetencyPolicy` — see BUG-SLB-DUPOLICIES).

---

### GAP-SLB-003: TopicController::destroy() Permanently Deletes Topics
**Severity:** P0 | **Layer:** Data Integrity

**Evidence (from BA GAP catalog confirmed):**
```php
// Modules/Syllabus/app/Http/Controllers/TopicController.php
// destroy() calls forceDelete() instead of delete()
public function destroy(Topic $topic): RedirectResponse
{
    $topic->forceDelete(); // WRONG — should be $topic->delete()
}
```

**Impact:** Every "delete" action on a topic in the UI permanently destroys the topic record, all child topics (via cascade?), and breaks all FK references from:
- `slb_topic_competency_jnt` (competency mappings)
- `slb_syllabus_schedule` (schedule entries)
- `qns_question_topic_jnt` (QuestionBank links)
- `lms_exam_scopes` / `lms_quest_scopes` (LMS scope entries)

There is no recovery path. This is data loss on every ordinary delete operation.

**Fix:** Change `$topic->forceDelete()` to `$topic->delete()` in `destroy()`. Ensure `Topic` model uses the `SoftDeletes` trait and `deleted_at` column exists.

---

### GAP-SLB-004: Competencie Model Missing SoftDeletes
**Severity:** P0 | **Layer:** Data Integrity

**Evidence (from BA GAP catalog confirmed):**
`Models/Competencie.php` does not use the SoftDeletes trait and the `slb_competencies` table has no `deleted_at` column.

**Impact:** Deleting a competency permanently removes it from:
- `slb_topic_competency_jnt` (topic-competency mappings)
- `slb_competencies` self-referential hierarchy (parent_id references break)
- QuestionBank competency links

**Fix:**
1. Add `use SoftDeletes;` trait to `Competencie.php`.
2. Create migration: `$table->softDeletes()` on `slb_competencies`.
3. Change any hard-delete calls to `->delete()`.

---

## P1 Findings (Major)

### BUG-SLB-DUPOLICIES: Duplicate Gate::policy Kills LessonPolicy and CompetencyPolicy
**Severity:** P1 | **Layer:** Authorization

**Evidence:**
```php
// Modules/Syllabus/app/Providers/SyllabusServiceProvider.php
Line 78:  Gate::policy(Lesson::class, LessonPolicy::class);        // registered first
Line 81:  Gate::policy(Competencie::class, CompetencyPolicy::class); // registered first
// ...
Line 92:  Gate::policy(Competencie::class, CompetenciePolicy::class); // OVERRIDES line 81 → CompetencyPolicy DEAD
Line 93:  Gate::policy(Lesson::class, SyllabusReportPolicy::class);   // OVERRIDES line 78 → LessonPolicy DEAD
```

**Impact (Laravel last-wins rule):**
- `LessonPolicy` is unreachable — all model-based Lesson policy checks use `SyllabusReportPolicy` instead. If `SyllabusReportPolicy` doesn't implement the same abilities, lesson authorization is silently broken.
- `CompetencyPolicy` is unreachable — all model-based competency checks route to `CompetenciePolicy`.

**Fix:**
- For the `Lesson::class` duplicate: Use `Gate::define('tenant.syllabus-report.viewAny', [SyllabusReportPolicy::class, 'viewAny'])` for report-specific abilities instead of policy registration. Remove the duplicate `Gate::policy(Lesson::class, SyllabusReportPolicy::class)` at line 93.
- For the `Competencie::class` duplicate: Decide which policy (`CompetencyPolicy` or `CompetenciePolicy`) is authoritative. Remove the duplicate and unify the policy file.

---

### GAP-SLB-002: $request->all() in CompetencieController
**Severity:** P1 | **Layer:** Input Validation

`CompetencieController::store()` and `update()` use `$request->all()` directly without a FormRequest, validator, or whitelist. Combined with the zero-auth finding (GAP-SLB-001), this means completely unrestricted writes to `slb_competencies`.

**Fix:** Create `CompetencieRequest` FormRequest with proper validation rules. Replace `$request->all()` with `$competencieRequest->validated()`.

---

### GAP-SLB-008: ReleaseLmsResources Cron Has No Date Filter
**Severity:** P1 | **Layer:** Business Logic

`ReleaseLmsResources` command processes ALL entries on every run, not just entries due for release today. On a large school's syllabus with 500+ topics, every cron run re-processes and potentially re-releases already-released LMS resources.

**Fix:** Add a date filter: only process entries where `scheduled_release_date <= today` AND `is_released = 0`.

---

### mapApiRoutes() Missing Tenancy Stack (Dead Scaffold)
**Severity:** P1 | **Layer:** Tenant Isolation

```php
// mapApiRoutes(): Route::middleware('api')->prefix('api')->name('api.')->group(api.php)
// api.php: Route::apiResource('syllabi', SyllabusController::class) — not implemented in SyllabusController
```

No tenancy middleware on `mapApiRoutes()`. The scaffold route is dead (SyllabusController has no apiResource methods), but any future real API added to `api.php` would run without tenant context.

---

## P2 Findings (Significant)

### VAL-SLB-001: All 15 FormRequests Return `true` in authorize() — D30 Pattern
**Severity:** P2 | **Layer:** Input Validation

All 15 FormRequests (LessonRequest, UpdateLessonRequest, TopicRequest, SyllabusScheduleRequest, TopicCompetencyRequest, BloomTaxonomyRequest, etc.) return `return true;` in `authorize()`. Loses authorization context at the FormRequest layer.

### GAP-SLB-009/010: Range Overlap Not Enforced on Performance Categories / Grade Divisions
**Severity:** P2 | **Layer:** Business Logic

Performance category score ranges (BR-SLB-007) and grade division percentage ranges (BR-SLB-023) have no overlap detection. Two categories can cover the same score range; the system accepts both silently.

### GAP-SLB-019: slb_books vs bok_books FK Ambiguity
**Severity:** P2 | **Layer:** Data Integrity

V2 references `bok_books.id` as the FK from `slb_lessons.bok_books_id`. A separate `slb_books` table exists (owned by SyllabusBooks module). The lesson-book FK may be pointing at the wrong table. Must clarify before building any report that joins lessons to books.

### DAT-SLB-001: 2 ENUM Columns in slb_ Tables
**Severity:** P2 | **Layer:** Data Integrity | **Pattern:** D29

- `slb_book_author_jnt.author_role`: ENUM ['CONTRIBUTOR', 'CO_AUTHOR', 'EDITOR', 'PRIMARY']
- `slb_syllabus_schedule.priority`: ENUM ['HIGH', 'LOW', 'MEDIUM']

Altering these requires ALTER TABLE ENUM on all tenant databases.

---

## P3 Findings (Minor)

| Code | Finding |
|------|---------|
| GAP-SLB-016 | Study Notes: 4 tables (slb_notes, slb_notes_files, slb_notes_downloads, slb_notes_ratings) but zero controllers or routes |
| GAP-SLB-017 | Report export: UI buttons exist; no backend PDF/Excel export implementation |
| GAP-SLB-021 | Zero Pest tests — no coverage for any business rule or integration |
| GAP-SLB-011 | Deep circular competency detection missing — only direct circular check |
| GAP-SLB-012 | is_system_defined guard missing in LessonController (can delete system-defined lessons) |

---

## Verified Good (PASS)

| Item | Evidence | Rating |
|------|----------|--------|
| 156 Gate::authorize calls | Present across all controllers except CompetencieController | ✅ Strong |
| 18 policies registered | 16 unique models covered (note 2 duplicates kill 2 policies) | ✅ Mostly correct |
| SyllabusController save/lock | saveSequencing(), saveScheduling(), toggleLock() — correct Gate checks | ✅ Implemented |
| LMS resource release | `TopicReleaseControlService` + `ReleaseLmsResources` cron exist | ✅ Implemented |
| Schedule period limit validation | saveSequencing() validates periods against slb_syllabus_periods_allocation | ✅ Correct |
| Syllabus scheduling | autoSchedule() implemented with teacher lookup | ✅ Implemented |
| 15 FormRequests | Validation rules exist (only authorize() has D30 gap) | ✅ Rules present |

---

## Systemic Pattern Scorecard

| Pattern | Verdict | Evidence |
|---------|---------|----------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ CONFIRMED | Not in RSP or web.php |
| Duplicate Gate::policy() kill | ✅ CONFIRMED | Lines 78 vs 93, 81 vs 92 |
| D30 (authorize=true) | ✅ CONFIRMED | All 15 FormRequests |
| D29 (ENUM columns) | ✅ CONFIRMED | 2 ENUM columns |
| $request->all() | ✅ CONFIRMED | CompetencieController |
| API RSP no tenancy | ✅ CONFIRMED | mapApiRoutes() dead scaffold |

---

## Recommended Fix Order

**Sprint 1 — Unblock Deploy (P0):**
1. SEC-SLB-01 — Add module:SYLLABUS to mapWebRoutes() (30 min)
2. GAP-SLB-003 — Fix `forceDelete()` → `delete()` in TopicController::destroy() (15 min)
3. GAP-SLB-004 — Add SoftDeletes to Competencie model + migration (1 hour)
4. GAP-SLB-001 — Add Gate::authorize to all 9 CompetencieController methods (2 hours)

**Sprint 2 — Policy + Validation (P1):**
5. BUG-SLB-DUPOLICIES — Remove duplicate policy registrations; fix LessonPolicy vs SyllabusReportPolicy (2 hours)
6. GAP-SLB-002 — Create CompetencieRequest FormRequest (1 hour)
7. GAP-SLB-008 — Add date filter to ReleaseLmsResources cron (1 hour)

**Sprint 3 — Range Validation + Data (P2):**
8. GAP-SLB-009/010 — Add range overlap detection to PC and GD store/update (3 hours)
9. GAP-SLB-019 — Resolve slb_books vs bok_books FK ambiguity
10. DAT-SLB-001 — Plan ENUM → VARCHAR migration for 2 columns

---

*Generated: 2026-06-30 | Technical Auditor Agent (Mode X) | Evidence-based; read-only pass*
