# StudentPortal (STP) — Mode X Complete Audit
**Date:** 2026-06-30  
**Auditor:** Technical Auditor Agent (Mode X — A+B+C+G+D)  
**Module:** `Modules/StudentPortal/`  
**Prefix:** `lms_*` (7 owned tables) — read-only over 17+ source modules  
**Health Score:** 40/100 (P0-capped)  
**Deploy Gate:** ❌ NO-GO  

---

## Executive Summary

StudentPortal is Prime-AI's student-facing ERP+LMS gateway — a read-only aggregation portal over 17+ source modules, plus ownership of 7 LMS attempt tables. It is architecturally one of the more mature modules: FeePaymentController has strong Razorpay ownership/signature checks, all exam/quiz/quest attempt controllers call `assertAllocation()` before any data load, and the complaint controller properly scopes to the current student. Multiple P0/P1 findings from the BA Phase 2 audit are **CLEARED by live code evidence** (SEC-STP-01, SEC-STP-008, SEC-STP-04, SEC-STP-09, BUG-STP-08).

The single P0 finding is the **platform-wide EnsureTenantHasModule gap** (SEC-PLATFORM-003). The major functional risk is the **authorization model**: zero Laravel policies, no Gate::authorize calls anywhere — access control relies entirely on `role:Student|Parent` middleware + auth-scoped query filters. This is functional but not auditable at the policy level. Additionally, **mobile API routes lack the `role:Student|Parent` check**, meaning any authenticated Sanctum user (teacher, admin, staff) can access all student portal mobile endpoints.

---

## Health Score (40/100 — P0 Capped)

| Layer | Weight | Color | Score | Notes |
|-------|--------|-------|-------|-------|
| L1 Tenant Isolation | 15 | 🔴 Red | 0.0 | SEC-STP-03: EnsureTenantHasModule absent from mapWebRoutes() |
| L2 Authentication | 12 | 🟡 Amber | 0.5 | Web: full stack. Mobile: sanctum only, no role check |
| L3 Authorization | 12 | 🔴 Red | 0.0 | Zero Gate::authorize, zero policies; role+query-scoping only |
| L4 Input Validation | 8 | 🟡 Amber | 0.5 | 5 FormRequests with auth()->check() (not D30 `true`); 5 ENUM columns |
| L5 Data Integrity | 8 | 🟡 Amber | 0.5 | 5 ENUM columns in lms_* tables; no GENERATED column issues |
| L6 Business Logic | 10 | 🟢 Green | 1.0 | Allocation checks, double-submit guards, payment signature verify |
| L7 Output Security | 8 | 🔴 Red | 0.0 | Stored XSS: {!! $q['text'] !!} in exam/quiz views, {!! $hw->description !!} |
| L8 Error/Logging | 5 | 🟢 Green | 1.0 | DB::transaction in payments, Log::error in complaints |
| L9 Performance | 5 | 🟡 Amber | 0.5 | Dashboard aggregates many separate queries; complaints unpaginated |
| L10 Code Quality | 7 | 🟡 Amber | 0.5 | Empty CRUD stubs, GET state change, scheduler off |
| L11 Feature Completeness | 10 | 🟢 Green | 1.0 | Exam/quiz/quest/homework/attendance/fees/results all implemented |
| L12 Gap Analysis | 0 | — | — | Multiple BA P0s cleared; 1 new mobile P1 |

**Raw: P0 present → capped at 40/100. Deploy: NO-GO.**

---

## Deploy Gate Verdict

| Gate | Status | Reason |
|------|--------|--------|
| ❌ Security P0 | BLOCK | SEC-STP-03: EnsureTenantHasModule missing from web routes |
| ⚠️ Security P1 | WARN | SEC-STP-02: Zero policies; SEC-STP-014: Mobile role gap |
| ⚠️ XSS P2 | WARN | Stored XSS in exam/quiz/homework views |
| ✅ Data Safety | PASS | No stale balance_amount; proper ownership scoping on all fee operations |
| ✅ Tenancy (Mobile) | PASS | InitializeTenancyByMobileHeader properly initializes tenant from X-School-Code |
| ✅ Payment Integrity | PASS | Razorpay signature verified; ULID cross-check prevents substitution |

---

## P0 Findings (Critical — Deploy Blockers)

### SEC-STP-03: EnsureTenantHasModule Missing from Web Routes
**Severity:** P0 | **Layer:** Tenant Isolation | **Platform Pattern:** SEC-PLATFORM-003

**Evidence:**
```php
// Modules/StudentPortal/app/Providers/RouteServiceProvider.php:44–55
protected function mapWebRoutes(): void
{
    Route::middleware([
            'web',
            InitializeTenancyByDomain::class,
            PreventAccessFromCentralDomains::class,
            EnsureTenantIsActive::class,
            'auth',
            'verified',
            'role:Student|Parent',
        ])
        ->prefix('student-portal')
        // MISSING: EnsureTenantHasModule::class
```

**Impact:** A student can access the StudentPortal on a tenant whose subscription does not include it. Module-level access control bypassed entirely via direct URL.

**Fix:** Add `\App\Http\Middleware\EnsureTenantHasModule::class` to the middleware array (after EnsureTenantIsActive, before auth).

---

## P1 Findings (Major)

### SEC-STP-02: Zero Authorization Policies — Authorization by Role + Query Scope Only
**Severity:** P1 | **Layer:** Authorization

**Evidence:**
```bash
# grep -rn "Gate::authorize" Modules/StudentPortal/app/Http/Controllers/
# → 0 results

# grep -rn "Gate::policy" Modules/StudentPortal/app/Providers/StudentPortalServiceProvider.php
# → 0 results (no policy registrations at all)
```

**Pattern:** Authorization model relies on:
1. `role:Student|Parent` Spatie middleware at route group level
2. Auth-scoped DB queries (`where('student_id', auth()->user()->student->id)`)

**What this means:** There is no per-object authorization audit trail. A student who belongs to a `Student` role group but whose `student` relationship returns data from another student (e.g., via data corruption or multi-student user mapping bug) has no Gate barrier. There is no policy abstraction to test or audit.

**Note:** In practice, the query-scoping approach is functional and the risk is low for standard flows. However, it fails audit standards and cannot be unit-tested at the policy layer.

**Fix:** Register policies for owned models (ExamAttempt, AttemptCheckpoint, AttemptActivityLog) and add `Gate::authorize` on at least the exam/quiz/quest attempt flow entry points.

---

### SEC-STP-014: Mobile API Routes Lack `role:Student|Parent` Check
**Severity:** P1 | **Layer:** Authentication

**Evidence:**
```php
// routes/api.php (central):42–51
Route::prefix('mobile/v1')->middleware(['mobile.key', 'tenant.mobile', 'auth:sanctum'])->group(function () {
    Route::post('auth/logout', [MobileAuthController::class, 'logout']);
    require base_path('Modules/StudentPortal/routes/mobile_api.php');  // line 30
    // ...
});
```

```php
// No role middleware applied — any Sanctum-authed user can reach:
Route::get('student/dashboard', [MobileStudentController::class, 'dashboard']);
Route::get('student/profile',   [MobileStudentController::class, 'profile']);
Route::get('student/results',   [MobileResultsController::class, 'index']);
// 45+ routes total
```

**Web routes** apply `role:Student|Parent` in the RSP middleware stack. **Mobile routes** are loaded into a central group that has no role check — only `mobile.key` + `tenant.mobile` + `auth:sanctum`.

**Impact:** A teacher, admin, or any staff member with a valid Sanctum token and the school code header can access all 45+ student portal mobile endpoints — dashboard, results, fees, exam attempts, library, etc.

**Fix:** Add `role:Student|Parent` to the mobile group wrapper in `routes/api.php` (or apply it within `mobile_api.php` itself):
```php
Route::middleware(['role:Student|Parent'])->group(function () {
    require base_path('Modules/StudentPortal/routes/mobile_api.php');
});
```

---

## P2 Findings (Significant)

### FE-STP-001: Stored XSS — Rich Content Rendered Unescaped in Exam/Quiz/Homework Views
**Severity:** P2 | **Layer:** Output Security

**Evidence (3 injection points):**
```php
// Modules/StudentPortal/resources/views/online-exam/attempt.blade.php:153
{!! $q['text'] !!}  // question content — no sanitization

// Modules/StudentPortal/resources/views/quiz/result.blade.php:210
{!! $q['explanation'] !!}  // question explanation — no sanitization

// Modules/StudentPortal/resources/views/homework/show.blade.php:69
{!! $hw->description !!}  // homework description — no sanitization

// Modules/StudentPortal/resources/views/my-recommendations/show.blade.php:284,339
{!! $rec->material->content_text !!}  // recommendation content — no sanitization
```

**Source:** `qns_questions_bank.question_content`, `slb_homework.description`, `rec_recommendation_materials.content_text` — all teacher/admin-created content from the admin panel.

**Risk:** Stored XSS requires a compromised or malicious teacher account to inject content into question text or homework descriptions. When a student views the exam/quiz/homework, the JavaScript executes in their browser context. In a K-12 context, student accounts are high-sensitivity targets.

**Note:** `{!! nl2br(e($notification->data['body'])) !!}` in notifications — SAFE (e() escapes before nl2br + unescaped output).

**Fix:** Use a server-side HTML sanitizer (e.g., `HTMLPurifier` or `league/html-to-markdown`) on rich content, or add a Blade helper `sanitize_html()` that strips disallowed tags before rendering with `{!! !!}`.

---

### GAP-STP-012: State Change via HTTP GET (Notification Mark-Read)
**Severity:** P2 | **Layer:** REST Correctness / CSRF Surface

**Evidence:**
```php
// Modules/StudentPortal/routes/web.php:39
Route::get('/notifications/{id}/mark-read', ...)->name('notifications.mark-read');
```

**Impact:** GET requests do not have CSRF protection. A simple `<img src="/student-portal/notifications/123/mark-read">` on any page can trigger this action. Additionally, GET-based state mutations violate HTTP semantics and can be triggered by crawlers, prefetchers, or browser back/forward navigation.

**Fix:** Change to `Route::patch(...)` or `Route::post(...)` and update the view to use a form or AJAX POST.

---

### BUG-STP-001: Complaint Index Unpaginated
**Severity:** P2 | **Layer:** Performance / Data Safety

**Evidence:**
```php
// Modules/StudentPortal/app/Http/Controllers/StudentPortalComplaintController.php:52
$complaints = $query->orderBy('created_at', 'desc')->get();
```

**Impact:** If a student/parent has many complaints (common for longstanding users), the index loads all of them into memory. No pagination. Potential memory exhaustion in high-complaint scenarios.

**Fix:** Replace `->get()` with `->paginate(15)` and pass `$complaints` to the view for pagination links.

---

### DAT-STP-001: 5 ENUM Columns in STP-Owned lms_* Tables (D29 Pattern)
**Severity:** P2 | **Layer:** Data Integrity | **Systemic:** D29

**Evidence:**
```php
// 2026_06_16_112817_create_lms_exam_attempts_table.php
$table->enum('attempt_mode', ['OFFLINE', 'ONLINE'])->default('ONLINE');
$table->enum('status', ['ABSENT', 'CANCELLED', 'EVALUATED', 'EVALUATION_PENDING',
    'IN_PROGRESS', 'NOT_STARTED', 'RESULT_PUBLISHED', 'SUBMITTED'])->default('NOT_STARTED');

// 2026_06_16_112815_create_lms_attempt_activity_logs_table.php
$table->enum('attempt_type', ['EXAM', 'QUEST', 'QUIZ']);

// 2026_06_16_112816_create_lms_attempt_checkpoints_table.php
$table->enum('attempt_type', ['EXAM', 'QUEST', 'QUIZ']);

// 2026_06_16_112823_create_lms_quiz_quest_results_table.php
$table->enum('assessment_type', ['QUEST', 'QUIZ']);

// 2026_06_15_150346_create_lms_quest_allocations_table.php
$table->enum('allocation_type', ['CLASS', 'GROUP', 'SECTION', 'STUDENT']);
```

**Impact:** Adding a new attempt mode, status, or allocation type requires an ALTER TABLE ENUM DDL change on 368+ table tenant databases. D29 platform pattern: preferred fix is `sys_dropdowns` or `VARCHAR` with application-layer validation.

**Fix (D36-compatible):** Migrate to `VARCHAR(30) NOT NULL` + CHECK constraints (MySQL 8.0.16+) + application-layer enum validation.

---

## P3 Findings (Minor)

### DEAD-STP-001: Empty CRUD Stubs in ComplaintController
**Severity:** P3 | **Layer:** Code Quality

```php
// StudentPortalComplaintController.php:250-263
public function edit($id)   { return view('studentportal::edit'); }
public function update(Request $request, $id) {}
public function destroy($id) {}
```

Edit returns a non-existent view stub. Update and destroy are completely empty. The resource route in web.php would expose these empty methods via the route list.

**Fix:** Either remove these from the route resource (use `->only(['index', 'create', 'store', 'show'])`) or implement them.

---

### DEAD-STP-002: Dead api.php Scaffold
**Severity:** P3 | **Layer:** Code Quality

```php
// Modules/StudentPortal/routes/api.php:6–8
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('studentportals', StudentPortalController::class)->names('studentportal');
});
```

The RSP's `mapApiRoutes()` only loads `api.php` with `Route::middleware('api')` — no tenancy middleware. The `apiResource` scaffold has no implementation in `StudentPortalController`. Real API is in `routes/mobile_api.php` loaded centrally.

**Fix:** Delete `api.php` or convert to real API documentation stub.

---

### BUG-STP-002: Scheduler Commented Out in ServiceProvider
**Severity:** P3 | **Layer:** Code Quality

```php
// StudentPortalServiceProvider.php:56–61
protected function registerCommandSchedules(): void
{
    // $this->app->booted(function () {
    //     $schedule = $this->app->make(Schedule::class);
    //     $schedule->command('inspire')->hourly();
    // });
}
```

Same pattern as FIN (BUG-FIN-06). The `TimeoutStaleAttempts` command is registered at line 48 but never scheduled. Stale attempt timeouts must be triggered manually or via external cron.

---

## Three-Way Reconciliation (BA Knowledge vs Phase 2 Audit vs Live Code)

| Code | BA/Phase2 Finding | Live Code Verdict | Action |
|------|-------------------|-------------------|--------|
| SEC-STP-01 | IDOR in proceedPayment — unguarded payment POST | ✅ CLEARED — `proceedPayment()` returns redirect; actual payment in FeePaymentController with ownership check | Remove from known-issues |
| SEC-STP-02 | Zero Gate::authorize calls | ✅ CONFIRMED — 0 results in grep | P1 confirmed |
| SEC-STP-03 | EnsureTenantHasModule missing | ✅ CONFIRMED — not in mapWebRoutes() middleware array | P0 confirmed |
| SEC-STP-04 | Hardcoded ID 104 in complaint create | ✅ CLEARED — ComplaintCategory::parents()->get() used, no hardcoded ID | Remove from known-issues |
| SEC-STP-08 | IDOR in exam attempt() — allocation check missing | ✅ CLEARED — assertAllocation() called at top of all 6 attempt/submit methods | Remove from known-issues |
| SEC-STP-09 | User::all() in complaint controller | ✅ CLEARED — not present in any STP controller | Remove from known-issues |
| BUG-STP-08 | PaymentGateway::all() exposure | ✅ CLEARED — not found; FeePaymentController uses GatewayManager | Remove from known-issues |
| GAP-STP-10 | Complaint index unpaginated | ✅ CONFIRMED as BUG-STP-001 | P2 confirmed |
| GAP-STP-12 | GET for mark-read notification | ✅ CONFIRMED in web.php:39 | P2 confirmed |
| SEC-STP-014 | Mobile routes no role check (NEW) | 🆕 NEW finding from live code | P1 new code |
| FE-STP-001 | XSS in exam views (NEW) | 🆕 NEW finding from live code | P2 new code |

---

## FRD Gap Summary

| Requirement Area | Status | Notes |
|------------------|--------|-------|
| Fee Summary View | ✅ Implemented | `feeSummary()` with scoped FeeInvoice queries |
| Exam Attempt Flow | ✅ Implemented | Full instructions→start→attempt→submit→result chain |
| Quiz/Quest Attempt | ✅ Implemented | Same flow, MobileQuizAttemptController handles both |
| Homework Submission | ✅ Implemented | `homework/{id}/submit` confirmed |
| Parent Result Sharing | ✅ Implemented | Signed URL via mapPublicRoutes() + ParentResultsController |
| Complaint Filing | ✅ Implemented | Complains with student scoping, ticket numbering |
| Complaint Edit/Update | ❌ Missing | Empty stubs — not yet built (DEAD-STP-001) |
| Notification Mark-Read | ⚠️ Partially | Implemented but via GET (GAP-STP-012) |
| Role-based Mobile Access | ❌ Missing | No role:Student|Parent on mobile routes (SEC-STP-014) |

---

## Systemic Pattern Scorecard

| Pattern | ID | Verdict | Evidence |
|---------|-----|---------|----------|
| EnsureTenantHasModule absent | SEC-PLATFORM-003 | ✅ CONFIRMED | mapWebRoutes() confirmed |
| API RSP no tenancy stack | API-RSP-PATTERN | ⚠️ PARTIAL | mapApiRoutes() maps dead scaffold only; mobile via central RSP |
| ENUM columns | D29 | ✅ CONFIRMED | 5 ENUM columns in 5 lms_* tables |
| FormRequest authorize=true | D30 | ❌ NOT PRESENT | STP uses auth()->check() — better than D30 |
| $request->all() | D25 | ❌ NOT PRESENT | STP uses specific validation rules |
| Permission prefix chaos | D24 | N/A | Module has no permission strings (0 Gate::authorize) |

---

## vs Platform Baseline

| Baseline Finding | STP | Notes |
|-----------------|-----|-------|
| SEC-TT-004 / SEC-FIN-34 (API no tenancy) | PARTIAL | mapApiRoutes() maps dead scaffold; mobile tenancy is via central mechanism |
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ Confirmed | Web routes only |
| D29 ENUM columns | ✅ Confirmed | 5 in lms_* tables |
| D30 authorize=true | ❌ Not present | auth()->check() used instead |
| BUG-FIN-06 / BUG-STT-??? (scheduler off) | ✅ Confirmed | TimeoutStaleAttempts unscheduled |

---

## Verified Good (PASS)

| Item | Evidence | Rating |
|------|----------|--------|
| FeePaymentController::initiate() ownership | `abort_if(...invoice->studentAssignment->student_id !== $authStudentId, 403)` | ✅ Strong |
| FeePaymentController::callback() ULID cross-check | `abort_if($payment->payable_id !== $invoice->getKey(), 403)` | ✅ Strong |
| Razorpay signature verification | `$driver->verify([...])` before marking success | ✅ Strong |
| DB::transaction wrapping payment callback | `DB::transaction(fn() => $this->paymentService->markSuccess(...) + $invoice->updatePayment(...))` | ✅ Correct |
| assertAllocation() on all 6+ exam methods | Confirmed in: instructions(), start(), attempt(), submit(), saveAnswer(), checkpoint() | ✅ Strong |
| StudentQuizAttemptController::assertAllocation() | Same pattern at lines 104, 238, 260, 351, 403, 666, 745 | ✅ Strong |
| viewInvoice() ownership check | `FeeInvoice::whereHas('studentAssignment', fn($q) => $q->where('student_id', $studentId))->findOrFail($id)` | ✅ Correct |
| StudentPortalComplaintController scoping | index() + show() filter by `created_by` OR `complainant_user_id` + guardian | ✅ Correct |
| mapPublicRoutes() signed URL pattern | `.middleware('signed')` on shared-results route | ✅ Correct |
| Mobile tenant initialization | InitializeTenancyByMobileHeader validates X-School-Code + calls tenancy()->initialize() | ✅ Correct |
| Notification body output | `{!! nl2br(e($notification->data['body'])) !!}` — e() escapes before unescaped render | ✅ Correct |
| Exam attempt double-submit guard | status check before start; pre-lock + transaction inside submit | ✅ Correct |

---

## Recommended Fix Order

### Sprint 1 — P0 + P1 (Block Deploy)
1. **SEC-STP-03** — Add `EnsureTenantHasModule` to `mapWebRoutes()` in RSP (1 line, 30 min)
2. **SEC-STP-014** — Add `role:Student|Parent` middleware wrapper around STP mobile routes in central `routes/api.php` (1 line, 30 min)

### Sprint 2 — Authorization Uplift (P1)
3. **SEC-STP-02** — Register ExamAttempt + AttemptCheckpoint policies in ServiceProvider; add Gate::authorize in exam/quiz/quest attempt index and start methods (4–6 hours)

### Sprint 3 — Output Security + REST (P2)
4. **FE-STP-001** — Sanitize `$q['text']`, `$hw->description`, `$rec->material->content_text` with HTML purifier before passing to views
5. **GAP-STP-012** — Change `GET notifications/{id}/mark-read` to `PATCH` with CSRF token

### Sprint 4 — Data + Performance (P2)
6. **BUG-STP-001** — Paginate complaint index
7. **DAT-STP-001** — Plan ENUM → VARCHAR migration for 5 lms_* columns (coordinate with LmsExam module)

### Sprint 5 — Cleanup (P3)
8. **DEAD-STP-001** — Remove empty edit/update/destroy from complaint route resource
9. **DEAD-STP-002** — Delete dead api.php scaffold
10. **BUG-STP-002** — Schedule `TimeoutStaleAttempts` in registerCommandSchedules()

---

## Stale BA Knowledge Corrections (for module-knowledge update)

The following findings in `STP_StudentPortal.md` (v1.0, 2026-06-30) are **INCORRECT** and must be cleared:

| Code | BA Claim | Live Code Reality |
|------|----------|-------------------|
| SEC-STP-01 | IDOR in `proceedPayment()` — missing ownership check | `proceedPayment()` redirects to fee-summary with an error; actual payment via FeePaymentController with abort_if() ownership check |
| SEC-STP-008 | IDOR in exam `attempt()` — allocation check missing | `assertAllocation()` is a private method called at the TOP of all 6 exam action methods; SEC-STP-008 is fully mitigated |
| SEC-STP-04 | Hardcoded dropdown ID 104 in ComplaintController::create() | No hardcoded IDs; uses ComplaintCategory::parents()->get() + sys_dropdowns lookups by key/value |
| SEC-STP-09 | User::all() in complaint create view | Not present in controller or view |
| BUG-STP-08 | PaymentGateway::all() exposes all gateways to student | Not found; FeePaymentController uses injected GatewayManager::resolve('razorpay') |

---

*Generated: 2026-06-30 | Technical Auditor Agent (Mode X) | Evidence-based; read-only pass*
