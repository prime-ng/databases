# Complete Audit — SmartTimetable (STT) — 2026-06-30
**Mode X: A + B + C + G + scoped D**
**Auditor:** Technical Auditor Agent (pa-technical-auditor) | **Agent Version:** Enhanced Maximum-Detail Edition
**Module:** SmartTimetable | **Code:** STT | **Prefix:** tt_* (shared with TTF, STA)
**FRD:** STT_FRD_Complete_2026-06-30.md | **DDL:** Timetable_DDL_v7.8.sql
**Sources:** Live code scan `/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable/` · 49 tenant migrations · 62 models · 17 web controllers · 1 API controller · 13 FormRequests · 86 constraint classes · 177 Blade views · AI_Brain module-knowledge v1.0 (2026-06-30)

---

## Executive Summary

SmartTimetable is a complex, FET-inspired CSP timetable generation engine (10-stage pipeline, 86 constraint classes, 3 God objects) in an advanced but unstable state of implementation. Three new P0 blockers were confirmed in this audit: **(1)** the API route group (`routes/api.php`) is loaded with only `auth:sanctum` middleware — **all 7 API endpoints execute in the central DB context** with no tenant isolation; **(2)** `tt_parallel_groups` and `tt_parallel_group_activity` have **no tenant migration** — `tenants:migrate` silently skips them, causing SQLSTATE[42S02] crashes on every parallel-period scheduling operation; **(3)** `GenerateTimetableJob::handle()` has **no tenancy re-initialization** and no `QueueTenancyBootstrapper` is registered in TenancyServiceProvider — generation jobs query tenant models against whichever DB the queue worker has open. The pre-existing platform P0 (SEC-PLATFORM-003: `EnsureTenantHasModule` absent) is confirmed for both route groups. Together these make the module unsafe for production.

**Health: 40/100 (P0-capped) | DEPLOY: NO-GO**

---

## Health Score

| Layer | Weight | Score | Status | Key Finding |
|-------|-------:|------:|:------:|------------|
| 6 — Tenancy | 15 | 0.0 | 🔴 Red | SEC-TT-004: API routes missing all tenancy middleware (P0) |
| 5 — Authorization | 14 | 7.0 | 🟡 Amber | SEC-TT-005: `tenant.*` prefix split in TtGenerationStrategyController |
| 8 — Data Integrity | 13 | 13.0 | 🟢 Green | TimetableStorageService uses lockForUpdate; DB::transaction in 9 files |
| 7 — Validation | 11 | 5.5 | 🟡 Amber | VAL-TT-003: 13/13 FormRequests authorize() returns true (D30) |
| 12 — Deployment | 10 | 0.0 | 🔴 Red | Route closure at web.php:52 breaks route:cache; 3 P0s block deploy |
| 2 — Migration↔Model | 9 | 0.0 | 🔴 Red | DAT-TT-001: No migration for tt_parallel_groups + 21 phantom models |
| 1 — DDL Schema | 7 | 7.0 | 🟢 Green | Zero ->enum() in migrations; DDL v7.8 exists |
| 9 — Performance | 7 | 3.5 | 🟡 Amber | Schema::getColumnListing() per dashboard request; AcademicTerm::all() |
| 10 — Queue/Job | 6 | 0.0 | 🔴 Red | JOB-TT-001: GenerateTimetableJob — no tenancy init; no bootstrapper |
| 4 — Code Quality | 4 | 2.0 | 🟡 Amber | 3,520-line God controller; route closure; dead imports |
| 3 — ORM | 2 | 1.0 | 🟡 Amber | ORM-TT-002: 12 active models missing boolean casts |
| 11 — Frontend | 2 | 1.0 | 🟡 Amber | FE-TT-001: json_encode without JSON_HEX flags on user-derived strings |
| **Total** | **100** | **40** | | |

> **P0 cap applied.** Raw weighted score = 40; cap = 40. Score matches — cap is binding.

---

## Deploy Gate Verdict

**🚫 NO-GO — 4 blocking P0 issues**

| Blocker | Code | Condition to clear |
|---------|------|--------------------|
| API routes run in central DB (no tenant isolation) | SEC-TT-004 | Add `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive` to `mapApiRoutes()` |
| tt_parallel_groups has no migration — crashes on use | DAT-TT-001 | Create and run tenant migration for both `tt_parallel_groups` and `tt_parallel_group_activity` |
| GenerateTimetableJob runs in wrong DB context | JOB-TT-001 | Implement `TenantAware` interface or explicit `tenancy()->initialize()` in `handle()`; register `QueueTenancyBootstrapper` |
| EnsureTenantHasModule absent from all routes | SEC-PLATFORM-003 | Add `EnsureTenantHasModule::class.':smart-timetable'` to both route groups |
| Route closure breaks route:cache | DEAD-TT-004 | Convert closure to named controller method |

---

## P0 Findings

---

```
[SEC-TT-004] Severity: P0 | API Routes Missing All Tenancy Middleware
- Location: Modules/SmartTimetable/app/Providers/RouteServiceProvider.php:57
- Evidence:
    protected function mapApiRoutes(): void
    {
        Route::middleware('api')->prefix('api')->name('api.')->group(module_path($this->name, '/routes/api.php'));
    }
- Why it's a risk: All 7 API endpoints in routes/api.php (generate, status, show, byClass, byTeacher,
  byRoom + the SmartTimetableController apiResource) execute without InitializeTenancyByDomain,
  PreventAccessFromCentralDomains, or EnsureTenantIsActive. In stancl/tenancy domain-based routing,
  these endpoints run in the central prime_db context — queries to tt_* models return empty or hit the
  wrong database, and generation jobs dispatched from the API may record into the central DB.
- Fix: Apply the full tenancy stack in mapApiRoutes():
    Route::middleware(['api', InitializeTenancyByDomain::class,
        PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class])
    This is the same pattern confirmed P0 in the TimetableFoundation audit (SEC-TTF-004, 2026-06-30).
- Confidence: High
- Systemic: Platform pattern — API RSP tenancy gap (same as TTF); links to SEC-TTF-004.
```

---

```
[DAT-TT-001] Severity: P0 | tt_parallel_groups and tt_parallel_group_activity Have No Migration
- Location: Modules/SmartTimetable/app/Models/ParallelGroup.php:? (bound to 'tt_parallel_groups')
            Modules/SmartTimetable/app/Models/ParallelGroupActivity.php (bound to 'tt_parallel_group_activity')
- Evidence:
    # All 49 tenant migrations searched — zero matches:
    grep -rl "parallel_group|tt_parallel" database/migrations/tenant/   → (no output)
    grep -rl "parallel_group|tt_parallel" database/migrations/          → (no output)
    # ParallelGroupController routes are live:
    Route::prefix('smart-timetable/parallel-group')->...->group(function () {
        Route::post('/', [ParallelGroupController::class, 'store']);        // line 24
        Route::post('/{parallelGroup}/add-activities', ...)->name('add-activities'); // line 29
        ...
    });
- Why it's a risk: On every fresh tenant provisioning, tenants:migrate skips these tables entirely.
  Any request to /smart-timetable/parallel-group (store, update, autoDetect, addActivities, setAnchor,
  removeActivity) throws SQLSTATE[42S02]: Table 'tenant_db.tt_parallel_groups' doesn't exist.
  The parallel period scheduling feature (D14, ~85% code-complete) is entirely broken at the DB layer.
  The module-knowledge flag "(GAP-DB-001)" for tt_parallel_group_activity confirms this gap was known;
  tt_parallel_groups itself was believed DDL-backed — this audit shows both have no migration.
- Fix: Create two tenant migrations:
    (1) create_tt_parallel_groups_table.php — columns: id, name, anchor_activity_id FK, is_active,
        created_by, deleted_at, timestamps. Match the DDL v7.8 spec.
    (2) create_tt_parallel_group_activity_table.php — columns: id, parallel_group_id FK,
        activity_id FK, is_anchor TINYINT(1) DEFAULT 0. Compound PK (parallel_group_id, activity_id).
- Confidence: High (verified: no migration files exist anywhere in the project for these tables)
- Systemic: Module-local; D36 category (code-ready feature with missing DB foundation)
```

---

```
[JOB-TT-001] Severity: P0 | GenerateTimetableJob Runs Without Tenancy Context
- Location: Modules/SmartTimetable/app/Jobs/GenerateTimetableJob.php (entire handle() method)
            app/Providers/TenancyServiceProvider.php (no QueueTenancyBootstrapper registered)
- Evidence:
    public function handle(): void
    {
        $run = GenerationRun::findOrFail($this->runId);         // queries tt_generation_runs
        ...
        $activities = Activity::where('is_active', true)        // queries tt_activities
            ->where('academic_term_id', $academicTermId) ...
        $days = SchoolDay::schoolDays()->get();                  // queries tt_school_days
        $rooms = Room::with('roomType')...->get();              // queries sch_rooms
    }
    # TenancyServiceProvider: grep -n "QueueTenancyBootstrapper|JobTenancyBootstrapper" → (no output)
- Why it's a risk: Without QueueTenancyBootstrapper or explicit tenancy()->initialize() in handle(),
  queue workers process this job in whatever DB context they happen to have open — typically the
  central prime_db. This means GenerationRun::findOrFail() throws ModelNotFoundException (no
  tt_generation_runs in prime_db) or, worse, if central DB has the same table shape, it silently
  writes generation results to the wrong database. Dispatched from TimetableApiController:116 and
  TimetableGenerationController. The job has tries=1, timeout=600 (good), but the DB context
  is wrong from the first line.
- Fix: Two-step: (1) Register QueueTenancyBootstrapper in TenancyServiceProvider. (2) In the job
    constructor accept a $tenantId parameter; at the top of handle() call
    tenancy()->initialize(Tenant::find($this->tenantId)) before any DB query, with a matching
    tenancy()->end() in a finally block. Safe pattern: $tenant->run(fn() => ...job body...).
    Update all dispatch() call sites to pass the current tenant ID.
- Confidence: High
- Systemic: Platform pattern — "Jobs touching tenant tables without tenancy re-init"
  (known-issues.md baseline; same pattern as Vendor/Inventory/FrontOffice/Hostel jobs)
```

---

```
[SEC-PLATFORM-003 — STT instance] Severity: P0 | EnsureTenantHasModule Absent from All Route Groups
- Location: Modules/SmartTimetable/routes/web.php:21, :36
- Evidence:
    // Group 1 (parallel-group):
    Route::prefix('smart-timetable/parallel-group')->middleware(['web', 'auth'])->group(...)
    // Group 2 (main):
    Route::middleware(['web', 'auth', 'verified'])->prefix('smart-timetable')->group(...)
    // Neither group includes EnsureTenantHasModule
- Why it's a risk: Any authenticated tenant user can access all SmartTimetable routes regardless of
  their school's subscription plan. A school on a Basic plan without the SmartTimetable module can
  run the generation engine, view analytics, and manage constraints without a license.
- Fix: Add EnsureTenantHasModule::class.':smart-timetable' to both middleware stacks. Verify the
  slug 'smart-timetable' matches glb_modules.slug for this module.
- Confidence: High
- Systemic: SEC-PLATFORM-003 (confirmed 13/13 modules on 2026-06-30)
```

---

## P1 Findings

---

```
[VAL-TT-003] Severity: P1 | All 13 FormRequests Return Hardcoded authorize() = true (D30)
- Location: Modules/SmartTimetable/app/Http/Requests/ (all 13 files)
- Evidence:
    # All 13 FormRequests confirmed:
    ConstraintCategoryScopeRequest.php: authorize() returns true
    UpdateConstraintRequest.php: authorize() returns true
    StoreTeacherUnavailableRequest.php: authorize() returns true
    StoreParallelGroupRequest.php: authorize() returns true
    ... (13/13 total)
- Why it's a risk: FormRequest authorize() is the second authorization layer (defense-in-depth).
  With it always returning true, the only gate is the controller's Gate::authorize() call. For
  controllers that DO have Gate::authorize (most STT controllers), this is P1 (systemic, acceptable
  under D30 baseline). For any controller that later loses its Gate::authorize call, the FormRequest
  provides zero backup.
- Fix: Each FormRequest::authorize() should return Gate::allows('smart-timetable.{entity}.{action}')
  matching the route it serves. This is defense-in-depth — keep controller gates too.
- Confidence: High (verified all 13 files)
- Systemic: D30 — platform-wide (437/485 = 90% baseline). STT = 13/13 = 100%, slightly above norm.
```

---

```
[DEAD-TT-004] Severity: P1 | Route Closure in routes/web.php Breaks route:cache
- Location: Modules/SmartTimetable/routes/web.php:52-57
- Evidence:
    Route::get('generate/generate-prime', function () {
        return redirect()
            ->route('smart-timetable.timetable.timetableGeneration')
            ->with('error', 'Please use the Generate with FET form to submit this action.');
    })->name('smart-timetable-management.generate-prime.get');
- Why it's a risk: php artisan route:cache fails when any route uses a closure callback —
  closures are not serializable. Since all modules share the same route cache, this one closure
  blocks route caching for the entire application, forcing every request to re-parse all 8,000+
  route definitions. On a production server this is a significant performance regression.
- Fix: Extract the redirect logic to a named controller method, e.g.
    Route::get('generate/generate-prime', [TimetableGenerationController::class, 'redirectGeneratePrime'])
    ->name('smart-timetable-management.generate-prime.get');
- Confidence: High
- Systemic: Platform pattern — known route closure issue (routes/api.php:9, routes/web.php:996, etc.)
```

---

```
[SEC-TT-005] Severity: P1 | Permission Prefix Split — tenant.* vs smart-timetable.* (D24)
- Location: Modules/SmartTimetable/app/Http/Controllers/TtGenerationStrategyController.php
            Modules/SmartTimetable/app/Policies/TimetableGenerationStrategyPolicy.php
- Evidence:
    # TtGenerationStrategyController:
    Gate::authorize('tenant.timetable-generation-strategy.create');    // :28
    Gate::authorize('tenant.timetable-generation-strategy.update');    // :109
    Gate::authorize('smart-timetable.generation-strategy.restore');    // :245  ← different prefix!
    # Policy uses tenant.* for all 6 methods (correct for the policy)
    # Rest of STT module:
    Gate::authorize('smart-timetable.timetable.update');               // 139 uses
    Gate::authorize('smart-timetable.parallel-group.create');          // 3 uses
    # Prefix distribution: smart-timetable=139, tenant=17, timetable-foundation=1
- Why it's a risk: The module uses two different permission prefixes for what should be one
  module's permission namespace. The rogue 'smart-timetable.generation-strategy.restore' at line
  245 is likely a copy-paste error from a different pattern — the Policy method checks
  tenant.timetable-generation-strategy.restore, so the controller call at :245 will always pass
  (no matching permission → Gate returns false and silently allows or denies depending on
  fallback). Also, permission seeding must cover both prefixes, creating maintenance overhead.
- Fix: Standardize ALL TtGenerationStrategyController gate calls to use the tenant.* prefix
  that the Policy uses, OR migrate the entire module to smart-timetable.* and update the Policy.
  Remove the mismatched 'smart-timetable.generation-strategy.restore' call at :245 — it likely
  allows the action unconditionally if the permission doesn't exist.
- Confidence: High
- Systemic: D24 — permission-prefix chaos; STT has a within-module split vs the typical cross-module
  variant.
```

---

```
[PERF-TT-017] Severity: P1 | Schema::getColumnListing() Called Per Dashboard Request
- Location: Modules/SmartTimetable/app/Http/Controllers/TimetableMenuController.php:53
- Evidence:
    $safeCount = function (string $table, array $where = []) {
        ...
        if (in_array('deleted_at', \Illuminate\Support\Facades\Schema::getColumnListing($table))) {
            $q->whereNull('deleted_at');
        }
        ...
    };
    $stats = [
        'timetables' => $safeCount('tt_timetables'),
        'published'  => $safeCount('tt_timetables', ...),
        'cells'      => $safeCount('tt_timetable_cells'),
        ...
    ];
- Why it's a risk: Each Schema::getColumnListing() call hits information_schema per tenant, per
  request. The dashboard calls safeCount() for at least 4 tables, so ≥4 information_schema queries
  fire on every dashboard page load. On a busy school during the day (many concurrent users), this
  degrades DB performance significantly. The column listing never changes at runtime.
- Fix: The softDeletes() columns are known at deploy time. Replace the dynamic check with a
  hardcoded constant or config array: const SOFT_DELETE_TABLES = ['tt_timetables', 'tt_timetable_cells', ...].
  Then $safeCount checks the constant instead of hitting information_schema.
- Confidence: High
- Systemic: Module-local (same pattern as Hostel HostelFeeService:108,211,225 — platform known)
```

---

```
[PERF-TT-018] Severity: P1 | AcademicTerm::all() Unbounded in ConstraintController (4 Methods)
- Location: Modules/SmartTimetable/app/Http/Controllers/ConstraintController.php:42, 59, 115, 245
- Evidence:
    'academicTerms' => AcademicTerm::all(),        // :42 (create form)
    $academicTerms = AcademicTerm::all();            // :59 (store response)
    $academicTerms = AcademicTerm::all();            // :115 (edit form)
    'academicTerms' => AcademicTerm::all(),          // :245 (index)
- Why it's a risk: A school with 5+ academic years has 15–30+ academic terms. ::all() loads every
  term including historical ones on every constraint page request. As the school accumulates years
  this grows unboundedly. A school from 2015 with 3 terms per year has 33 rows; not catastrophic,
  but it should be a scoped query (current year + adjacent).
- Fix: Replace AcademicTerm::all() with AcademicTerm::where('is_active', 1)->orderByDesc('start_date')
  ->limit(10)->get(), or cache the active term list per tenant for 60 minutes.
- Confidence: High
- Systemic: Module-local
```

---

## P2 Findings

---

```
[FE-TT-001] Severity: P2 | json_encode of User-Derived Strings Without JSON_HEX Flags
- Location: Modules/SmartTimetable/resources/views/smart-timetable/reports.blade.php:214, :254
- Evidence:
    labels: {!! json_encode($teacherLoads->pluck('name')->values()) !!},   // :214 — teacher names
    labels: {!! json_encode($roomUtilization->pluck('name')->values()) !!}, // :254 — room names
    series: {!! $donutValues !!},                  // generation-history/_list.blade.php:378
    labels: {!! $donutLabels !!},                  // :380
- Why it's a risk: Teacher names and room names are user-entered strings. If a teacher name
  contains </script><script>alert(1)</script>, json_encode without JSON_HEX_TAG renders it as raw
  HTML-breaking JavaScript in the chart data block. This is an XSS vector for any school admin
  who can create teacher records.
- Fix: Use Blade's @json directive (which applies JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_QUOT|JSON_HEX_AMP
  automatically), or replace with:
    labels: {!! json_encode($teacherLoads->pluck('name')->values(),
        JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_QUOT|JSON_HEX_AMP) !!}
- Confidence: High
- Systemic: Module-local; same fix applies to all {!! json_encode($userDerivedCollection...) !!}
  instances in STT (4 chart blocks in reports.blade.php, 6 more in _list.blade.php)
```

---

```
[FE-TT-002] Severity: P2 | {!! $cti['detail_html'] !!} Unescaped in Conflict View
- Location: Modules/SmartTimetable/resources/views/preview/partials/_class-conflicts.blade.php:220
- Evidence:
    <div class="cls-cc-reason">
        {!! $cti['detail_html'] !!}
    </div>
- Why it's a risk: $cti['detail_html'] is not found in any service or controller within STT or
  TTF app code (no grep hits). Its origin is unclear — it may be generated by a service computing
  conflict descriptions, or it may be partially user-derived (e.g., teacher/subject names). If
  it contains any user-entered strings without prior escaping, this is an XSS vector.
- Fix: Trace $cti['detail_html'] to its source. If it is server-generated with no user strings,
  document this explicitly. If it includes any user-derived content (teacher names, room names,
  subject names), sanitize via e($userString) before concatenation and switch to {{ $cti['detail_html'] }}.
- Confidence: Medium (source not confirmed — XSS if user data; safe if fully server-constructed)
- Systemic: Module-local
```

---

```
[ORM-TT-002] Severity: P2 | 12 Active Models Missing Boolean Casts for is_* Fields
- Location: Modules/SmartTimetable/app/Models/ — 12 files:
  Constraint.php, ConstraintCategoryScope.php, RoomUnavailable.php, TeacherUnavailable.php,
  TeacherAvailabilityDetail.php, PriorityConfig.php, ApprovalLevel.php, ImpactAnalysisDetail.php,
  ImpactAnalysisSession.php, MlModel.php, PatternResult.php, TrainingData.php
- Evidence (example — Constraint.php has no $casts block):
    class Constraint extends Model {
        protected $fillable = ['name', 'is_hard', 'is_active', 'weight', ...];
        // No protected $casts = [...] block
    }
- Why it's a risk: Without boolean casts, $constraint->is_hard returns the string "0" or "1"
  from MySQL. In Blade, {{ $constraint->is_hard ? 'Hard' : 'Soft' }} evaluates "0" as truthy —
  every constraint appears as Hard regardless of DB value. Conditional logic on is_* fields
  throughout 177 views and services is silently wrong.
- Fix: Add protected $casts = ['is_hard' => 'boolean', 'is_active' => 'boolean', ...] to each
  of the 12 models. Phantom/ML models (MlModel, TrainingData, etc.) are lower priority since they
  have no backing table — fix the 8 active-use models first.
- Confidence: High
- Systemic: Platform-wide pattern (D3 — missing casts); STT has 12 of 62 models affected.
```

---

```
[MIG-TT-002] Severity: P2 | 21 Phantom Models Bound to Tables With No Migration
- Location: Modules/SmartTimetable/app/Models/ — 21 classes
- Evidence:
    Models with no tenant migration (comm -23 model_tables vs migration_tables):
    ApprovalDecision, ApprovalLevel, ApprovalNotification, ApprovalRequest, ApprovalWorkflow,
    BatchOperation, BatchOperationItem, ConflictResolutionOption, ConflictResolutionSession,
    EscalationLog, EscalationRule, FeatureImportance, GenerationQueue, ImpactAnalysisDetail,
    ImpactAnalysisSession, MlModel, OptimizationIteration, OptimizationMove, OptimizationRun,
    PatternResult, PredictionLog, RevalidationSchedule, RevalidationTrigger, TrainingData,
    VersionComparison, VersionComparisonDetail, WhatIfScenario
    (27 unique orphan tables; 21 match the known phantom-model list; 6 are additional orphans)
- Why it's a risk: If any route or service accidentally touches one of these models (e.g., a
  GenerationQueue::create() for queued generation, or ApprovalRequest for workflow), it throws
  SQLSTATE[42S02] on every tenant. The WhatIfScenario, VersionComparison, and ML models are
  explicitly mentioned in routes and views in some places.
- Fix (two options): (a) Delete all 21 phantom model files + any referencing code (preferred for
  non-ML models per module-knowledge recommendation); (b) Create migrations for models that
  represent planned-but-needed features. GenerationQueue and ApprovalRequest are candidates for
  option (b); the ML models are candidates for option (a) (deferred to ML phase).
- Confidence: High (search confirmed: no migration files for any of these table names)
- Systemic: Module-local; same root cause as DAT-TT-001
```

---

```
[PERF-TT-019] Severity: P2 | AnalyticsController::computeTeacherWorkload() Without Pagination
- Location: Modules/SmartTimetable/app/Http/Controllers/AnalyticsController.php (index method)
- Evidence:
    # Shell: grep -rl "public function index" ... | while read f; do
    #   grep -qE '->get()' "$f" && ! grep -qE 'paginate(' "$f" && echo "NO-PAGINATE: $f"
    # → NO-PAGINATE index: AnalyticsController.php
    Gate::authorize('smart-timetable.report.viewAny');   // auth present — not a security issue
- Why it's a risk: For a large school with 100+ teachers, computing and returning all workload
  records unpaginated loads the full tt_teacher_workloads table per timetable in one pass.
  In a 6-section-per-class, 12-grade school this can be 150–200 teacher rows per generation run.
  The analytics view is likely rendered as a table — paginating at 25–50 rows keeps response time
  acceptable as the school grows.
- Fix: Add ->paginate(25) to the teacher workload and room utilization queries in AnalyticsController.
  Pass $page parameter from the view. If the view uses charts (not a data table), pre-aggregate
  totals instead of fetching all rows.
- Confidence: Medium (size estimate is approximate; depends on school structure)
- Systemic: Module-local
```

---

## Layer Health Summary

| # | Layer | Status | Score | Key Finding |
|---|-------|:------:|------:|------------|
| 1 | DDL Schema | 🟢 Green | 7/7 | Zero ENUM in 49 migrations; DDL v7.8 present |
| 2 | Migration↔Model | 🔴 Red | 0/9 | DAT-TT-001: No migration for tt_parallel_groups; 21+ phantom models |
| 3 | ORM Correctness | 🟡 Amber | 1/2 | ORM-TT-002: 12 models missing boolean casts |
| 4 | Code Quality | 🟡 Amber | 2/4 | SmartTimetableController 3,520 lines (P1 pre-existing); DEAD-TT-004 route closure |
| 5 | Authorization | 🟡 Amber | 7/14 | SEC-TT-005 prefix split; 2/14 policies (12 missing); most controllers DO have Gate::authorize |
| 6 | Multi-Tenancy | 🔴 Red | 0/15 | SEC-TT-004 API routes missing all tenancy middleware |
| 7 | Validation | 🟡 Amber | 5.5/11 | VAL-TT-003 (D30 systemic); 11+ missing FormRequests in key controllers |
| 8 | Data Integrity | 🟢 Green | 13/13 | TimetableStorageService uses lockForUpdate; DB::transaction in 9 files |
| 9 | Performance | 🟡 Amber | 3.5/7 | PERF-TT-017 Schema:: introspection per request; PERF-TT-018 AcademicTerm::all() |
| 10 | Queue/Job | 🔴 Red | 0/6 | JOB-TT-001: GenerateTimetableJob — no tenancy, no bootstrapper |
| 11 | Frontend | 🟡 Amber | 1/2 | FE-TT-001 json_encode XSS; FE-TT-002 unescaped detail_html |
| 12 | Deployment | 🔴 Red | 0/10 | 4 P0s block deploy; DEAD-TT-004 closure breaks route:cache |

---

## STEP 1 Reading-Discipline Output (Three-Way Reconcile)

> Schema (DDL v7.8) ↔ Migration ↔ Model — key tables reconciled

| Table | DDL v7.8 | Migration | Model $table | Status |
|-------|:--------:|:---------:|:------------:|--------|
| tt_constraints | ✅ | ✅ (creates 'tt_constraints') | ✅ Constraint.php | MATCH |
| tt_generation_strategies | ✅ | ✅ | ✅ TtGenerationStrategy.php | MATCH |
| tt_generation_runs | ✅ | ✅ | ✅ GenerationRun.php | MATCH |
| tt_timetable_cells | ✅ | ✅ | ✅ (alias to TTF) | MATCH |
| tt_parallel_groups | ✅ | ❌ NO MIGRATION | ✅ ParallelGroup.php | **P0 GAP** |
| tt_parallel_group_activity | ❌ (DDL gap, migration-only spec) | ❌ NO MIGRATION | ✅ ParallelGroupActivity.php | **P0 GAP** |
| tt_teacher_absences | ✅ | ✅ | ✅ TeacherAbsences.php | MATCH |
| tt_analytics_daily_snapshots | ❌ | ✅ migration-only | ✅ AnalyticsDailySnapshot.php | DDL gap only (P2) |
| tt_approval_workflows | ❌ | ❌ | ✅ ApprovalWorkflow.php | Phantom model |
| 21 phantom models | ❌ | ❌ | ✅ PHP classes | **MIG-TT-002** |

**Snapshot corrections:** Module-knowledge v1.0 (seeded 2026-06-30) correctly flags `tt_parallel_group_activity` as migration-only (GAP-DB-001) but incorrectly implies `tt_parallel_groups` is DDL-backed (no migration confirmed). Knowledge file needs correction.

---

## FRD Gap Summary (Mode B)

> FRD: STT_FRD_Complete_2026-06-30.md | 17 REQs, 26 BRs

| REQ ID | Requirement | DDL | Controller | FormRequest | Test | Overall Status |
|--------|------------|:---:|:----------:|:-----------:|:----:|:-------------:|
| REQ-STT-001 | Foundation Masters Setup | ✅ (TTF) | ✅ (TTF) | ✅ (TTF) | — | ✅ TTF scope |
| REQ-STT-002 | Requirement Definition | ✅ (TTF) | ✅ (TTF) | ✅ (TTF) | — | ✅ TTF scope |
| REQ-STT-003 | Constraint Engine Config | ✅ | ✅ | ❌ missing StoreTimetableConstraintRequest | — | 🟡 75% |
| REQ-STT-004 | Teacher/Room Availability | ✅ (TTF) | ✅ (TTF) | ✅ (TTF) | — | ✅ TTF scope |
| REQ-STT-005 | Activity Management | ✅ (TTF) | ✅ (TTF) | 🟡 partial | ✅ 1 unit test | 🟡 90% |
| REQ-STT-006 | Parallel Period Groups | ❌ **NO MIGRATION** | ✅ CRUD exists | ❌ missing | — | 🔴 DB CRASH |
| REQ-STT-007 | Generation Strategy Config | ✅ | ✅ | ❌ activation FR missing | — | 🟡 75% |
| REQ-STT-008 | Timetable Creation & Validation | ✅ | 🟡 inline validation | ❌ missing | — | 🟡 65% |
| REQ-STT-009 | Automated Generation Engine | ✅ | 🟡 constraint bridge broken | ❌ missing | ✅ 1 unit test | 🔴 55% — P0 bugs |
| REQ-STT-010 | Generation Monitoring | ✅ | ✅ | — | ✅ | ✅ 90% |
| REQ-STT-011 | Approval Workflow | 🟡 FSM partial | ❌ UI not built | ❌ | — | 🔴 30% |
| REQ-STT-012 | Publishing & Versioning | ✅ | 🟡 partial | ❌ | — | 🟡 50% |
| REQ-STT-013 | Post-Generation Analytics | ✅ | ✅ (auth present) | — | — | ✅ 85% |
| REQ-STT-014 | Manual Refinement | ✅ | ✅ (auth present) | ❌ missing | — | 🟡 65% |
| REQ-STT-015 | Substitution Management | ✅ (partial) | ✅ (auth present) | ❌ missing | — | 🟡 65% |
| REQ-STT-016 | Standard Timetable Views | N/A (STA module) | ❌ **0% not built** | ❌ | — | 🔴 0% |
| REQ-STT-017 | REST API | ✅ | 🟡 no rate limiting, API tenancy P0 | — | — | 🔴 API broken (P0) |

**Critical gaps for immediate action:**
- REQ-STT-006: Parallel groups crash — fix DAT-TT-001 first
- REQ-STT-009: Constraint bridge (BUG-STT-05) — generation ignores DB constraints
- REQ-STT-011: Approval UI, zero authorization on approval action — 0% done
- REQ-STT-016: StandardTimetable is a separate module (STA) — not STT responsibility
- REQ-STT-017: API broken at tenancy level (SEC-TT-004)

---

## Business-Rule Enforcement (Mode C)

> 26 BRs from STT_FRD_Complete_2026-06-30.md, Section 3

| BR-ID | Rule Summary | Type | Location | Status | Finding |
|-------|-------------|------|----------|:------:|---------|
| BR-STT-001 | Pre-gen prereqs (shift, days, period set, TT type) | Prerequisite | ValidationService | ✅ ENFORCED | — |
| BR-STT-002 | Period duration auto-calc (GENERATED STORED) | Calculation | DDL + migration | ✅ ENFORCED | — |
| BR-STT-003 | No overlapping TT types for same shift | Validation | Application-level check | 🟡 PARTIAL | CHECK constraint or UniqueRule missing |
| BR-STT-004 | Class calendar override beats school calendar | Priority | Generation engine | ✅ ENFORCED | — |
| BR-STT-005 | Requirement Consolidation XOR (group OR subgroup) | Data Integrity | DDL CHECK + application | ✅ ENFORCED | — |
| BR-STT-006 | Hard constraint violations cause failure | Hard Constraint | PrimeSolver backtracking | 🟡 PARTIAL | BUG-STT-05 (constraint bridge broken) — only inline constraints enforced |
| BR-STT-007 | Constraint scope hierarchy Global>Class>Teacher>Room>Activity | Hierarchy | ConstraintEvaluator | ✅ ENFORCED | — |
| BR-STT-008 | Per-instance Hard flag overrides type default | Override | ConstraintManager | ✅ ENFORCED | — |
| BR-STT-009 | Unavailability creates display + constraint records | Automation | TeacherUnavailableController | 🟡 PARTIAL | Dual-record creation not confirmed verified |
| BR-STT-010 | Teacher availability records exist pre-generation | Prerequisite | ValidationService | ✅ ENFORCED | — |
| BR-STT-011 | Teacher readiness flags auto-computed | Calculation | GENERATED STORED columns | ✅ ENFORCED | — |
| BR-STT-012 | Activity total_periods = duration × weekly_periods (GENERATED) | Calculation | DDL + migration | ✅ ENFORCED | — |
| BR-STT-013 | Activity with sub-activities needs ≥1 sub-activity | Prerequisite | ValidationService | 🟡 PARTIAL | Check not fully confirmed |
| BR-STT-014 | Difficulty-first activity placement | Algorithm | ActivityScoreService (6 factors) | ✅ ENFORCED | — |
| BR-STT-015 | Parallel anchor defines shared slot | Algorithm | ParallelPeriodConstraint | ✅ ENFORCED | BUT: db crash (DAT-TT-001) makes this unreachable |
| BR-STT-016 | Parallel group retries if anchor can't place | Algorithm | PrimeSolver backtracking | ✅ ENFORCED | Same caveat as BR-015 |
| BR-STT-017 | Max 50k iterations, 25s/run, 600s job timeout | Limits | PrimeSolver + GenerateTimetableJob | ✅ ENFORCED | — |
| BR-STT-018 | Generation must be async; web thread must not wait | Architecture | GenerateTimetableJob dispatch | 🟡 PARTIAL | Sync path present in controller; BR-018 not exclusively enforced |
| BR-STT-019 | FSM: Draft→Generating→Generated→Approved→Published→Archived | FSM | TimetablePublishController | 🟡 PARTIAL | Approval step incomplete (REQ-011) |
| BR-STT-020 | Hard violations require override reason before approval | Approval | Approval UI | ❌ MISSING | UI not built; no authorization on approval |
| BR-STT-021 | Only Published timetable visible to teachers/students | Permission | StandardTimetable / API | ❌ MISSING | StandardTimetable (REQ-016) not built; API tenancy broken |
| BR-STT-022 | Published immutable to swap/move; substitutions only | Immutability | RefinementController | 🟡 PARTIAL | Check exists; no FormRequest validation layer |
| BR-STT-023 | All cell modifications logged with type, user, timestamp | Audit | ChangeLog model | ✅ ENFORCED | — |
| BR-STT-024 | Substitute assigned without removing original teacher | Substitution | SubstitutionService | ✅ ENFORCED | — |
| BR-STT-025 | Candidate scoring: subject(40)+pattern(25)+availability(20)+workload(15) | Substitution | SubstitutionService | ✅ ENFORCED | — |
| BR-STT-026 | Pattern updated via running exponential average on completion | Substitution | SubstitutionService.completeSubstitution() | ✅ ENFORCED | — |

**BR Summary:** 16 ENFORCED | 7 PARTIAL | 2 MISSING (BR-020, BR-021)

---

## Systemic-Pattern Scorecard (Mode D, STT-scoped)

| Pattern | ID | Present in STT? | Count | vs Baseline | Finding Code |
|---------|----:|:--------------:|------:|------------|-------------|
| `EnsureTenantHasModule` absent | SEC-PLATFORM-003 | ✅ Yes | 2 of 2 route groups | 13/13 modules (norm) | Reference SEC-PLATFORM-003 |
| `Gate::authorize()` absent from write methods | — | 🟡 Partial | Most controllers have it; 0 confirmed ungated write routes | 64 platform-wide ungated | Clean |
| `FormRequest authorize(){return true;}` | D30 | ✅ Yes | 13/13 (100%) | 90% platform baseline | VAL-TT-003 |
| `->enum()` in tenant migrations | D29 | ✅ Clean | 0 of 49 migrations | Platform ~476 | **Better than baseline** |
| `$request->all()` into models | D25 | ✅ Clean | 0 occurrences | 24 platform sites | **Better than baseline** |
| Privilege fields in `$fillable` | — | ✅ Clean | None found in STT models | SchoolSetup P0 confirmed | Clean |
| `tenancy()->initialize()` without `->end()` | L6.2 | ✅ Clean | 0 occurrences in STT code | Platform 2 P0 sites | Clean |
| Job tenancy re-init missing | L10.1 | ✅ Yes | 1 job (GenerateTimetableJob) | Vendor, Inv, FO, Hostel | JOB-TT-001 |
| Cross-DB FK to sys_dropdowns/sys_roles | L2.5 | Not verified for this audit | — | 52/17 platform sites | Verify per FK in migrations |
| DDL GENERATED columns absent in migrations | D36 | 🟡 Partial | total_periods (Activity), available_for_full_timetable_duration (TeacherAvailability) — both in TTF migrations, STT reads them | D36 platform-wide | TTF scope issue |
| Queue driver vs Horizon mismatch | DEPLOY-HRZ-01 | ✅ Yes | Job dispatched to default (database) queue | Platform-wide P0 | Inherited platform issue |
| EnsureTenantHasModule module subscription middleware | TEN-RTG-001 | ✅ Yes | 2 groups missing | 13/13 | SEC-PLATFORM-003 |

**STT systemic scorecard vs baseline:**
- ✅ Better than platform on: D29 (0 enums vs 476), D25 (0 mass-assign vs 24), L6.2 (no init leak)
- ≈ Matches platform on: D30 (100% vs 90%), SEC-PLATFORM-003 (expected 13/13)
- ❌ New STT-specific patterns: API tenancy gap, parallel-group no-migration, JOB tenancy, prefix split

---

## vs Platform Baseline

| Metric | STT | Platform Baseline | Delta |
|--------|-----|-------------------|-------|
| FormRequests returning bare true (D30) | 13/13 (100%) | 437/485 (90%) | ↑ worse |
| Write controllers with zero authz | ~0 (most gated) | 64 | ✅ better |
| ->enum() in tenant migrations (D29) | **0** | ~476 | ✅ far better |
| $request->all() into models (D25) | **0** | 24 sites | ✅ better |
| Eager load ratio (with:get) | 162:326 = 0.50 | Hpc worst 0.04; STT 0.47 (prior) | ≈ on baseline |
| God controller (largest file) | 3,520 lines | 4,222 max (Student) | 2nd tier |
| Jobs without tenancy init | 1 / 1 | Several | ≈ pattern present |
| P0 findings | **4** | varies | Priority: fix before deploy |
| Test coverage | ~5% (3 unit tests) | Most modules ~0% | At baseline |
| Policies registered | 2 / 14 needed | Varies | Below average |

---

## Recommended Fix Order

```
Priority 1 — Unblock Deploy (P0 first)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. SEC-TT-004: Add tenancy middleware stack to mapApiRoutes() in RSP.php
2. DAT-TT-001: Create migrations for tt_parallel_groups + tt_parallel_group_activity.
3. JOB-TT-001: Register QueueTenancyBootstrapper; add tenancy init in GenerateTimetableJob::handle().
4. SEC-PLATFORM-003: Add EnsureTenantHasModule::class.':smart-timetable' to both route groups.

Priority 2 — Pre-Release P1
━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. DEAD-TT-004: Convert routes/web.php:52 closure to a named controller method.
6. SEC-TT-005: Standardize permission prefix — migrate TtGenerationStrategyController to smart-timetable.*
              OR keep tenant.* but document it as intentional; remove the one mismatched smart-timetable.*
              call at line 245.
7. BUG-STT-05 (pre-existing): Fix PrimeConstraintBridge context initialization to wire DB constraints
              into PrimeSolver — this makes BR-STT-006 fully ENFORCED.
8. BUG-TT-004 (pre-existing): Add generateForClassSection() method to TimetableGenerationController.
9. PERF-TT-017: Replace Schema::getColumnListing() with hardcoded column constant in TimetableMenuController.
10. PERF-TT-018: Replace AcademicTerm::all() with scoped+cached query in ConstraintController.
11. VAL-TT-003: Implement Gate::allows() in each FormRequest::authorize() (at minimum for the 5
               most security-sensitive requests: StoreTimetable, GenerateWithPrime, StoreConstraint,
               RefinementSwap, SubstitutionReport).

Priority 3 — Quality Sprint (P2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
12. ORM-TT-002: Add boolean/array casts to 12 active models missing them.
13. FE-TT-001: Replace json_encode without HEX flags with @json() in reports.blade.php and _list.blade.php.
14. FE-TT-002: Trace $cti['detail_html'] source; sanitize if user-derived.
15. MIG-TT-002: Audit 21 phantom models — delete non-ML phantoms; create migrations for needed ones
               (GenerationQueue, ApprovalRequest are candidates).
16. PERF-TT-019: Add pagination to AnalyticsController workload/room utilization queries.
17. REQ-STT-011: Build Timetable Approval UI (approval/reject buttons + Gate::authorize on action).
18. BR-STT-020: Add hard-violation override-reason form before approval submission.

Priority 4 — Backlog (P3)
━━━━━━━━━━━━━━━━━━━━━━━━━
19. TimetablePageController 1,450 lines → extract into TimetableViewerController (view) +
    TimetableConfigController (config).
20. Add 10 test files targeting: generation pipeline, constraint enforcement, FSM transitions,
    substitution flow, API auth. Target: ≥60% line coverage on Services/Generator/.
21. BR-STT-021: StandardTimetable views (REQ-016) — STA module scope; track separately.
```

---

## P3 Notes

- `TimetablePageController` is 1,450 lines (P2-borderline at >500 line threshold). Contains mixed page routing, config forms, and view rendering. Decompose in a later sprint.
- SmartTimetableController 3,520 lines (pre-existing DEAD-TT-001/DEAD-TT-002 context) — extracting TimetableConfigController and TimetableMasterController (per original design) would reduce it to ~1,500 lines.
- `Faker\Factory` import in SmartTimetableController (pre-existing DEAD-TT-001) — still present, still unused.
- `iCal export` scaffolded only in TimetableApiController::exportIcal() — not implemented.
- `activityLog()` helper usage needs systematic confirmation across all state-changing controllers.

---

## Deliverables Status

- **A** ✅ Audit report — this file
- **B** → See below (known-issues.md update)
- **C** → Progress.md: STT completion revised to ~65% (was 58%) due to auth improvements confirmed; health 40/100 P0-capped
- **D** → No new D-pattern emerged (all findings match existing D17/D24/D25/D29/D30/D36/SEC-PLATFORM patterns)
- **E** → Module-knowledge STT_SmartTimetable.md: update parallel-group migration status from "DDL-backed" to "NO MIGRATION (DAT-TT-001 P0)"; add Layers 5/6/10 confirmed findings
- **F** → Next steps (see below)

---

## Next Steps

```
Audit complete — Health 40/100 (P0-capped). DEPLOY: NO-GO.

1. Fix P0 issues (SEC-TT-004, DAT-TT-001, JOB-TT-001, SEC-PLATFORM-003)
   → act as Developer (pa-developer or pa-backend-developer)
2. Fix parallel-group DDL + migration gaps
   → act as DB Architect (pa-db-architect)
3. Fix constraint bridge (BUG-STT-05) to enforce DB constraints in generation
   → act as Developer
4. Build Approval Workflow UI (REQ-STT-011, BR-020)
   → act as Frontend Developer (pa-frontend-developer)
5. Re-score completeness after P0 fixes
   → act as Status Analyzer
6. Write generation pipeline tests
   → act as Test Agent (pa-test-agent)
7. Platform-wide API RSP tenancy sweep (same issue likely in other modules)
   → /agent technical-auditor → Mode F (Layer 6 only) across all module RSPs
```
