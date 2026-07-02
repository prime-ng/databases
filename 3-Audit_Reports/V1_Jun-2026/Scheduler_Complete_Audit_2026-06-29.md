# Complete Audit — Scheduler (SDL) — 2026-06-29
## Mode X: A + B + C + G + scoped D

**Module:** Scheduler | **Code:** SDL | **Prefix:** `schedules.*` (generic tables, no sdl_ prefix — D-SDL-02)
**DB Layer:** prime_db (Central — Platform Admin only)
**Module Path:** `Modules/Scheduler/`
**Auditor:** pa-technical-auditor | **Date:** 2026-06-29
**Sources read:** Live code at `Modules/Scheduler/`, two module migrations, `routes/web.php`, FRD `SDL_FRD_Complete_2026-06-29.md`, module-knowledge `SDL_Scheduler.md`, `AI_Brain/state/decisions.md`, `AI_Brain/lessons/known-issues.md`

---

## Executive Summary

The Scheduler module stores schedule configuration records but is non-functional as a scheduling platform. Three P0 findings block any productive use: (1) zero authorization gates on the sole controller — any authenticated user including tenant school staff can create and view schedules; (2) the execution engine (runSchedule(), Artisan command, ScheduleRun writes) is entirely absent — the module has never dispatched a single job; (3) the update() and destroy() methods are empty, making edit and delete operations silently impossible. Additionally, the RouteServiceProvider incorrectly applies full tenancy middleware to this central-only module's own routes, making the RSP-registered paths unreachable from the central domain and wrong-context from tenant domains (though the parallel central web.php registrations provide working central-domain access). The module is approximately 25% complete and scores **32/100** health (P0-capped at 40). **DEPLOY: NO-GO.**

---

## Health Score

| Layer | Weight | Score | Raw |
|-------|--------|-------|-----|
| 6 — Multi-Tenancy | 15 | Amber (0.5) | 7.5 |
| 5 — Authorization | 14 | **Red (0.0)** | 0 |
| 8 — Data Integrity / Tx | 13 | Amber (0.5) | 6.5 |
| 7 — Validation / Mass-assign | 11 | **Red (0.0)** | 0 |
| 12 — Deployment | 10 | Amber (0.5) | 5 |
| 2 — Migration ↔ Model ↔ DDL | 9 | Amber (0.5) | 4.5 |
| 1 — DDL Schema | 7 | Amber (0.5) | 3.5 |
| 9 — Performance | 7 | Amber (0.5) | 3.5 |
| 10 — Queue / Job / Scheduler | 6 | **Red (0.0)** | 0 |
| 4 — Code Quality | 4 | **Red (0.0)** | 0 |
| 3 — ORM | 2 | Amber (0.5) | 1.0 |
| 11 — Frontend / Blade | 2 | Amber (0.5) | 1.0 |
| **TOTAL** | **100** | | **32** |

**Weighted score: 32/100. P0 cap (max 40) does not further reduce. Health = 32/100.**
Three P0 findings confirm non-deployable state.

---

## Deploy Gate Verdict — NO-GO

| Gate | Status | Evidence |
|------|--------|----------|
| No P0 security hole | **FAIL** | SEC-SDL-001: zero Gate::authorize() across all 7 controller methods |
| No cross-tenant leak | PASS | Central module, no tenant data access attempted |
| No committed secret | PASS | No API keys in codebase |
| Core write operations functional | **FAIL** | BUG-SDL-001: update()/destroy() empty; BUG-SDL-002: execution engine absent |
| Routes resolve without error | Partial | Central web.php routes work; RSP routes dead from central domain (TEN-SDL-001) |
| `tenants:migrate` safe | PASS | Module uses module:migrate (prime_db); no cross-DB FKs |
| SEC-RTG-001 | Not applicable | Scheduler not in routes/tenant.php seeder block |

**Verdict: NO-GO.** Must fix P0 findings before any user testing.

---

## P0 Findings

---

```
[SEC-SDL-001] Severity: P0 | Zero Gate::authorize() in all 7 SchedulerController methods
- Location: Modules/Scheduler/app/Http/Controllers/SchedulerController.php (entire file, lines 1-86)
- Evidence:
    public function index()          { /* no gate */ }
    public function create()         { /* no gate */ }
    public function store(ScheduleRequest $request) { /* no gate */ }
    public function show($id)        { /* no gate */ }
    public function edit($id)        { /* no gate */ }
    public function update(Request $request, $id) { }    // empty + no gate
    public function destroy($id)     { }                 // empty + no gate
- Why it's a risk: Any authenticated user — including a school teacher or school admin authenticated
  on a tenant domain who navigates to the /schedulers/* RSP routes — bypasses all access control.
  The Scheduler FRD explicitly restricts all actions to Platform Admins and Super Admins (BR-SDL-001,
  NFR-SDL-004). No SchedulePolicy exists to compensate. This is not an empty scaffold; index(), create(),
  and store() contain real business logic.
- Fix: Create Modules/Scheduler/app/Policies/SchedulePolicy.php with methods viewAny/view/create/
  update/delete/restore/forceDelete. Register in SchedulerServiceProvider::boot(). Add
  Gate::authorize('scheduler.viewAny') through Gate::authorize('scheduler.forceDelete') to each
  controller method before any business logic. Update ScheduleRequest::authorize() to call
  Gate::allows('scheduler.create') (not return true).
- Confidence: High (read controller line by line; no Gate::allows/can/authorize anywhere in the file)
- Systemic? Systemic D30 (FormRequest bare-true) + 64 controllers platform-wide with zero authz;
  module-local for the policy absence (no SchedulePolicy exists).
```

---

```
[BUG-SDL-001] Severity: P0 | Execution engine entirely absent — module stores schedules but executes nothing
- Location: Modules/Scheduler/app/Services/SchedulerService.php (entire file, 41 lines)
             Modules/Scheduler/app/Providers/SchedulerServiceProvider.php:44-58
- Evidence (SchedulerService.php — only dueSchedules() exists, no runSchedule()):
    public function dueSchedules(): Collection
    {
        return Schedule::query()->where('is_active', true)->get()
            ->filter(fn(Schedule $s) => $this->isDue($s));
    }
    // runSchedule() — DOES NOT EXIST

    (SchedulerServiceProvider.php — command registration commented out entirely):
    protected function registerCommands(): void
    {
        // $this->commands([]);
    }
    protected function registerCommandSchedules(): void
    {
        // $this->app->booted(function () { ... });
    }
- Why it's a risk: Without runSchedule() there is no dispatch path. Without an Artisan command there
  is nothing for the platform scheduler to call. ScheduleRun records are never created — the execution
  history table exists in the schema but has zero writes from anywhere in the codebase. The module's
  stated purpose ("the platform automatically checks all Active Job Schedules once per minute and
  dispatches the associated jobs" — REQ-SDL-008) is completely unimplemented. BRs 020–024 have zero
  enforcement. JobRegistry.get() and SchedulableJob contract are well-designed but unreachable.
- Fix: Implement SchedulerService::runSchedule(Schedule $schedule): void — look up job class from
  JobRegistry, create ScheduleRun with status='running', dispatch job (using tenancy()->initialize()
  for tenant-scoped schedules), update ScheduleRun to success/failed. Create
  Console/Commands/ScheduleDispatchCommand.php, register in registerCommands(), and in
  registerCommandSchedules() register: $schedule->command('scheduler:dispatch')->everyMinute()
  ->withoutOverlapping() (BR-SDL-024).
- Confidence: High (read SchedulerService.php in full; grep for runSchedule across Modules/Scheduler
  returns zero hits; console/ directory does not exist)
- Systemic? Module-local (only SDL); severity elevated because this is the core feature of the module.
```

---

```
[BUG-SDL-002] Severity: P0 | Empty update() and destroy() methods — schedules cannot be edited or deleted
- Location: Modules/Scheduler/app/Http/Controllers/SchedulerController.php:76-85
- Evidence:
    public function update(Request $request, $id)
    {
    }

    public function destroy($id)
    {
    }
- Why it's a risk: Both methods return null (PHP implicit return). Laravel converts null to an
  empty HTTP 200 response with no body. A PUT /scheduler/schedule/{id} request silently returns
  HTTP 200 with no content — the schedule is never updated. A DELETE /scheduler/schedule/{id}
  silently returns HTTP 200 — the schedule is never deleted. Users or API callers receive no error
  signal. These are live routes registered via Route::resource (web.php:304), not dead scaffolds.
  REQ-SDL-003 (Edit) and part of REQ-SDL-004 (Archive) are completely blocked.
- Fix: Implement update() with Gate::authorize, load Schedule by $id, call $request->validated(),
  update the model, recompute next_run_at. Implement destroy() with Gate::authorize, load model,
  call $schedule->delete() (soft-delete, requires adding SoftDeletes — see ORM-SDL-001).
- Confidence: High (read both methods; both have only the method signature and braces, no body)
- Systemic? Module-local; no dead-stub issue on a live route is a known platform pattern (Library,
  CommonChat, BehaviouralAssessment — all have similar stubs behind live routes at P0).
```

---

## P1 Findings

---

```
[TEN-SDL-001] Severity: P1 | RSP applies full tenant middleware stack to a central-only module
- Location: Modules/Scheduler/app/Providers/RouteServiceProvider.php:41-49
- Evidence:
    Route::middleware([
        'web',
        InitializeTenancyByDomain::class,
        PreventAccessFromCentralDomains::class,
        EnsureTenantIsActive::class,
        'auth',
        'verified',
    ])->group(module_path($this->name, '/routes/web.php'));
- Why it's a risk: The Scheduler is a central-only module (prime_db; D-SDL-06 documents this
  explicitly). Applying PreventAccessFromCentralDomains to the module's own routes means those
  routes (/schedulers/*) are BLOCKED from the central domain — the very domain where Platform
  Admins operate. Applying InitializeTenancyByDomain means any request to /schedulers/* from
  a tenant domain will initialize tenant context, then run SchedulerController queries against
  the tenant DB where the 'schedules' table does not exist (it is a prime_db table). So RSP routes
  are dead from central (403 by middleware) and crash from tenant (table-not-found SQL error).
  Note: The parallel registrations in central web.php (lines 301/548/878) provide working
  central-domain access, so the functional impact is limited; but the RSP creates unintended
  access vectors from tenant domains and contradicts D-SDL-06.
- Fix: Replace the RSP middleware group with ['web', 'auth', 'verified'] only — no tenancy
  middleware. Scheduler is central; it should run on the central domain without tenant context.
  Alternatively, consider whether the module's own routes/web.php registration is needed at all
  given the central web.php already registers the same controller (with different path/names).
- Confidence: High (read RSP lines 41-49; confirmed module is prime_db-only from FRD + D-SDL-06)
- Systemic? Inverted D23: D23 found tenant modules MISSING tenancy middleware; this is a central
  module incorrectly ADDING tenant middleware. Module-local.
```

---

```
[BUG-SDL-003] Severity: P1 | trashedSchedule() method missing from controller, registered in all 3 route blocks
- Location: routes/web.php:305, 552, 882 (all three blocks)
             Modules/Scheduler/app/Http/Controllers/SchedulerController.php (entire file)
- Evidence (from routes/web.php:305, repeated at 552 and 882):
    Route::get('schedule/trash', [SchedulerController::class, 'trashedSchedule'])
        ->name('schedule.trashed');

    (SchedulerController.php — method does not exist; confirmed by reading all 86 lines)
- Why it's a risk: Any request to GET /scheduler/schedule/trash throws
  BadMethodCallException: Method [trashedSchedule] does not exist → HTTP 500. The Archive view
  (RPT-SDL-003, REQ-SDL-004) is completely inaccessible. The edit.blade.php and trash.blade.php
  views exist but the latter has wrong content (copy of Dropdown module — confirmed in module-knowledge).
- Fix: Implement trashedSchedule() on SchedulerController: load soft-deleted schedules (requires
  SoftDeletes on Schedule model — see ORM-SDL-001) using Schedule::onlyTrashed()->paginate(15),
  pass to a corrected trash view.
- Confidence: High (read all 86 lines of the controller; no trashedSchedule method defined)
- Systemic? Module-local route gap pattern seen in other modules (Library, Hostel).
```

---

```
[RT-SDL-001] Severity: P1 | Scheduler routes registered three times in central web.php
- Location: routes/web.php:301-308, 548-555, 878-885
- Evidence (identical block at three locations):
    Route::middleware(['auth', 'verified'])->prefix('scheduler')->name('scheduler.')->group(function () {
        Route::resource('schedule', SchedulerController::class);
        Route::get('schedule/trash', [..., 'trashedSchedule'])->name('schedule.trashed');
    });
    // repeated identically at lines 548-555 and 878-885
- Why it's a risk: Laravel registers all three; the last definition wins for route resolution.
  The first two registrations are shadowed. This wastes route-cache space and creates confusion
  for debugging — `php artisan route:list` shows duplicates. If the blocks ever diverge (one gets
  an additional route that the others don't), subtle routing bugs emerge.
- Fix: Remove two of the three identical blocks, leaving only one registration. Also consolidate
  the module's RSP-registered routes (/schedulers/*) with these (/scheduler/schedule/*) — currently
  two separate path sets both pointing at the same controller with different route names.
- Confidence: High (grep routes/web.php for 'prefix.*scheduler' returns lines 301, 548, 878)
- Systemic? Module-local copy-paste error.
```

---

```
[BUG-SDL-004] Severity: P1 | Double validation in store() — ScheduleRequest bypassed by inline validate()
- Location: Modules/Scheduler/app/Http/Controllers/SchedulerController.php:34-42
             Modules/Scheduler/app/Http/Requests/ScheduleRequest.php:13-43
- Evidence (SchedulerController.php:34-42):
    public function store(ScheduleRequest $request)
    {
        $data = $request->validate([          // ← inline validate() AFTER FormRequest already ran
            'name' => 'required|string|max:255',
            'job_key' => 'required|string',
            'cron_expression' => 'required|string',
            'payload' => 'nullable|string',
            'is_active' => 'boolean',
        ]);
- Why it's a risk: FormRequest (injected as ScheduleRequest) runs its rules() before the method body.
  Then $request->validate() runs a SECOND validation with DIFFERENT rules (the FormRequest had
  'max:255' on cron_expression and a $isUpdate branch; the inline validate omits these). The second
  call to validate() effectively re-creates the validation result. Any custom rules added to
  ScheduleRequest in the future (cron-syntax checker, job-key whitelist) will be ignored because
  the inline validate() creates a separate binding that does not consult ScheduleRequest::rules().
  This has confused the intent of FormRequest-based validation and makes the validation contract
  undiscoverable.
- Fix: Remove the inline $request->validate() call entirely. Use $request->validated() to retrieve
  the already-validated data. Add any missing rules directly to ScheduleRequest::rules().
- Confidence: High (read both files; ScheduleRequest rules confirmed at lines 13-43)
- Systemic? Related to D30 (FormRequests undermined); module-local manifestation.
```

---

```
[VAL-SDL-001] Severity: P1 | job_key not validated against JobRegistry — arbitrary strings accepted
- Location: Modules/Scheduler/app/Http/Requests/ScheduleRequest.php:23-26
             Modules/Scheduler/app/Services/JobRegistry.php:17-23
- Evidence (ScheduleRequest.php:23-26):
    'job_key' => [
        $isUpdate ? 'sometimes' : 'required',
        'string',
    ],
    // Missing: Rule::in(array_keys(JobRegistry::all()))
- Why it's a risk: Any arbitrary string can be stored as job_key. When the execution engine
  (BUG-SDL-001) is eventually built, JobRegistry::get($jobKey) returns null for unrecognised
  keys. The FRD requirement (BR-SDL-002) explicitly mandates that unrecognised job types must
  be rejected at validation time with a field-level error, not at execution time. An invalid
  job_key that passes validation becomes a silently-failed schedule (Failed Execution Record) —
  difficult to diagnose.
- Fix: Add 'Rule::in(array_keys(JobRegistry::all()))' to the job_key rules in ScheduleRequest.
  Add custom message: "Please select a valid task type from the catalog."
- Confidence: High (read ScheduleRequest rules array; JobRegistry::all() returns keyed array)
- Systemic? Module-local validation gap.
```

---

```
[VAL-SDL-002] Severity: P1 | cron_expression not validated for syntax — invalid crons silently stored
- Location: Modules/Scheduler/app/Http/Requests/ScheduleRequest.php:28-31
- Evidence:
    'cron_expression' => [
        $isUpdate ? 'sometimes' : 'required',
        'string',
        'max:255',
    ],
    // Missing: ValidCronExpression rule class
- Why it's a risk: Any string (including '99 99 * * *', 'daily', or random text) is accepted as
  a timing pattern. SchedulerService::isDue() catches Throwable and silently returns false for
  invalid crons — so an invalid cron expression causes the schedule to be silently skipped on
  every execution cycle forever. The user receives no feedback that the schedule will never run.
  NFR-SDL-008 requires cron syntax to be validated at save time.
- Fix: Create a ValidCronExpression custom rule class using CronExpression::isValidExpression()
  (the dragonmantank/cron-expression package is already imported — SchedulerService.php:5 uses it).
  Add it to ScheduleRequest cron_expression rules. Add message: "The timing pattern is not a valid
  cron expression."
- Confidence: High (read ScheduleRequest rules; confirmed CronExpression is already a dependency)
- Systemic? Module-local validation gap.
```

---

```
[SEC-SDL-002] Severity: P1 | FormRequest authorize() hardcoded true — no defense-in-depth (D30)
- Location: Modules/Scheduler/app/Http/Requests/ScheduleRequest.php:49-51
- Evidence:
    public function authorize(): bool
    {
        return true;
    }
- Why it's a risk: ScheduleRequest is the only FormRequest for this module. With SEC-SDL-001
  (zero Gate in controller) also open, there is absolutely no authorization protection on the
  create/store path. Fixing SEC-SDL-001 (adding Gate to controller) partially mitigates this,
  but per D30 every FormRequest should implement its own gate check as defense-in-depth. If the
  controller gate is later commented out or removed (a known platform pattern — Vendor SEC-VND-005),
  the FormRequest provides zero fallback.
- Fix: authorize() should return Gate::allows('scheduler.create') (or the appropriate ability
  per the route). This provides defense-in-depth alongside the controller gate.
- Confidence: High (read authorize() method directly)
- Systemic? D30 — 437/485 platform FormRequests (90%) return hardcoded true; systemic norm, but
  escalated here because the controller gate is also absent (SEC-SDL-001).
```

---

```
[ORM-SDL-001] Severity: P1 | Schedule model missing SoftDeletes — archive feature architecturally impossible
- Location: Modules/Scheduler/app/Models/Schedule.php:1-44
- Evidence:
    class Schedule extends Model   // no `use SoftDeletes;` anywhere in the file
    {
        protected $fillable = [
            'name', 'schedule_type', 'tenant_id', 'job_key',
            'payload', 'cron_expression', 'is_active',
        ];
        // $fillable also missing: last_run_at, next_run_at, deleted_at
- Why it's a risk: Without SoftDeletes, Schedule::destroy() would perform a hard-delete. All
  run history (schedule_runs records) would be orphaned (schedule_id FK → RESTRICT → cannot delete).
  REQ-SDL-004 (Archive and Restore), BR-SDL-010, BR-SDL-016 (archived excluded from engine) are
  all technically impossible without deleted_at + SoftDeletes. The migration also lacks the
  deleted_at column (DAT-SDL-001).
- Fix: Add `use Illuminate\Database\Eloquent\SoftDeletes;` to the model. Add deleted_at to the
  schedules migration (requires new addColumnToSchedulesTable migration). Add deleted_at to $fillable
  if needed. The execution engine's dueSchedules() query should filter deleted_at IS NULL.
- Confidence: High (read Schedule.php in full; no SoftDeletes trait; migration confirmed no deleted_at)
- Systemic? Module-local; SoftDeletes missing is platform-wide on newer module scaffolds (D8 says
  "Soft Deletes Everywhere" but many scaffolded modules haven't implemented it).
```

---

```
[PERF-SDL-001] Severity: P1 | index() uses unbounded ->get() — no pagination
- Location: Modules/Scheduler/app/Http/Controllers/SchedulerController.php:18
- Evidence:
    $schedules = Schedule::orderBy('created_at', 'desc')->get();
- Why it's a risk: Loads the entire schedules table into memory on every page load. NFR-SDL-001
  requires pagination at 15 items per page. At current scale (3 jobs in registry) this is harmless,
  but the index view already has a search form that does nothing (the controller ignores request
  parameters) and the schedule count will grow as JobRegistry is expanded to 10+ entries.
- Fix: Replace ->get() with ->paginate(15). Add search filter: add ->when(request('search'), fn($q, $s)
  => $q->where('name', 'like', "%$s%")->orWhere('job_key', 'like', "%$s%")). Add is_active filter:
  ->when(request('status') !== null, fn($q) => $q->where('is_active', request('status'))). Pass
  $schedules->links() to the view for pagination controls.
- Confidence: High (read controller:18; confirmed no paginate call; index.blade.php has search form)
- Systemic? PERF-SDL-001 module-local; unbounded get() is a common platform pattern
  (Complaint/DepartmentSlaController, Dashboard).
```

---

## P2 Findings

---

```
[MIG-SDL-001] Severity: P2 | ENUM in schedules.schedule_type migration violates D29
- Location: Modules/Scheduler/database/migrations/2026_01_02_112016_create_schedules_table.php:16
- Evidence:
    $table->enum('schedule_type', ['prime', 'tenant'])->index();
- Why it's a risk: D29 prohibits ENUM for any "pick from a list" column. schedule_type has two
  values today but the FRD anticipates future scope extensions. Adding a new scope type (e.g.
  'global', 'multi-tenant') would require an ALTER TABLE against the prime_db schedules table and
  a code change. It should be a sys_dropdown_table FK or (if genuinely binary and code-gated)
  a TINYINT(1) boolean. Since prime vs tenant is a meaningful binary distinction used in code
  (isPrime()/isTenant() helpers), a boolean or a two-value constrained string with app-level
  validation may be acceptable short-term.
- Fix: Options: (a) Keep as-is with clear documentation that scope types are code-gated;
  (b) Convert to VARCHAR(50) with app-level validation against SchedulerType::all(); (c) Convert
  to sys_dropdown_table FK (overkill for a 2-value field). Recommended: (b) with D29 exception
  documented for binary code-gated sentinel.
- Confidence: High (read migration:16)
- Systemic? D29 — ~476 ->enum() calls platform-wide; SDL contributes 2.
```

---

```
[MIG-SDL-002] Severity: P2 | ENUM in schedule_runs.status migration violates D29
- Location: Modules/Scheduler/database/migrations/2026_01_02_155143_create_schedule_runs_table.php:18-22
- Evidence:
    $table->enum('status', [
        'running',
        'success',
        'failed',
    ])->index();
- Why it's a risk: Status values are part of FSM-SDL-002. ENUMs lock the value set at DDL level.
  Adding a new status (e.g. 'cancelled', 'timeout', 'queued') requires ALTER TABLE. ScheduleRun
  model has no 'status' cast, so status is returned as a raw string — consistent with the ENUM
  value set today but fragile.
- Fix: Convert to VARCHAR(20) with a custom Rule::in(['running','success','failed']) in any
  FormRequest that writes status, or use sys_dropdown_table FK if status values should be admin-
  configurable. Add 'status' => 'string' cast to ScheduleRun model.
- Confidence: High (read migration:18-22)
- Systemic? D29 systemic.
```

---

```
[DAT-SDL-001] Severity: P2 | Missing columns in both tables — required by FRD, absent from migrations
- Location: Modules/Scheduler/database/migrations/2026_01_02_112016_create_schedules_table.php
             Modules/Scheduler/database/migrations/2026_01_02_155143_create_schedule_runs_table.php
- Evidence (schedules migration — missing columns):
    // No $table->softDeletes()  → deleted_at missing
    // No $table->unsignedBigInteger('created_by')->nullable()  → created_by missing
    // No $table->unsignedInteger('failure_count')->default(0)  → failure_count missing
    (schedule_runs migration — missing columns):
    // No $table->softDeletes()  → deleted_at missing
    // No $table->unsignedBigInteger('created_by')->nullable()  → created_by missing
    // No $table->longText('output')->nullable()  → output missing
    // No $table->tinyInteger('attempt')->unsigned()->default(1)  → attempt missing
- Why it's a risk: failure_count is rendered on every row of index.blade.php:56 — the column
  does not exist in the DB, so Eloquent returns null and the column always displays blank. The
  execution engine needs failure_count to implement BR-SDL-021 (increment on failure). output
  and attempt are needed for REQ-SDL-007 (Run History) expandable error details.
- Fix: Create two new migrations: add_columns_to_schedules_table and
  add_columns_to_schedule_runs_table. Add SoftDeletes, created_by (FK → sys_users.id NULLABLE),
  failure_count to the first; SoftDeletes, created_by, output (LONGTEXT NULL), attempt
  (TINYINT UNSIGNED DEFAULT 1) to the second.
- Confidence: High (read both migrations in full against FRD Section E.1 data dictionary)
- Systemic? Missing columns vs FRD requirement is a D17-adjacent pattern; module-local.
```

---

```
[ORM-SDL-002] Severity: P2 | Schedule.$fillable missing last_run_at and next_run_at columns
- Location: Modules/Scheduler/app/Models/Schedule.php:13-21
- Evidence:
    protected $fillable = [
        'name', 'schedule_type', 'tenant_id', 'job_key',
        'payload', 'cron_expression', 'is_active',
        // last_run_at and next_run_at are in the migration but not here
    ];
    // Migration 2026_01_02_112016: has $table->timestamp('last_run_at')->nullable()
    //                                    $table->timestamp('next_run_at')->nullable()
- Why it's a risk: The execution engine (once built) needs to mass-assign last_run_at and
  next_run_at after each run. Without them in $fillable, Schedule::update(['last_run_at' => now()])
  will silently not write the column (mass-assignment protection blocks it). The developer would
  need to use the Query Builder or $schedule->last_run_at = now(); $schedule->save() pattern.
  Also missing casts: last_run_at and next_run_at should be cast to datetime.
- Fix: Add 'last_run_at', 'next_run_at' to $fillable. Add to $casts:
  'last_run_at' => 'datetime', 'next_run_at' => 'datetime'.
- Confidence: High (read Schedule.php fillable and migration columns side-by-side)
- Systemic? Module-local; follows the D17 pattern (fillable missing column).
```

---

```
[ORM-SDL-003] Severity: P2 | ScheduleRun missing $table, missing ORM relationships on both models
- Location: Modules/Scheduler/app/Models/ScheduleRun.php:1-27
             Modules/Scheduler/app/Models/Schedule.php:1-44
- Evidence:
    class ScheduleRun extends Model   // no $table property; infers 'schedule_runs' by convention
    {
        // No runs() relationship defined on Schedule
        // No schedule() relationship defined on ScheduleRun
    }
- Why it's a risk: The missing $table is low-risk (Laravel convention matches); documented for
  explicitness. The missing relationships are high-risk for the run history feature: REQ-SDL-007
  requires displaying run history per schedule. Without $schedule->runs() the controller would
  need to write raw queries. Without $run->schedule() cascade delete and eager loading are manual.
- Fix: Add `protected $table = 'schedule_runs';` to ScheduleRun. Add `public function runs()` 
  HasMany(ScheduleRun::class) to Schedule. Add `public function schedule()` BelongsTo(Schedule::class)
  to ScheduleRun.
- Confidence: High (read both model files; no relationship methods defined)
- Systemic? Module-local ORM gap.
```

---

```
[DEAD-SDL-001] Severity: P2 | SchedulerService.dueSchedules() is orphaned — no caller, no command
- Location: Modules/Scheduler/app/Services/SchedulerService.php:14-20
             Modules/Scheduler/app/Providers/SchedulerServiceProvider.php:44-58
- Evidence:
    // SchedulerService.php has dueSchedules() and isDue() — both well-implemented
    // No Console/ directory in the module
    // SchedulerServiceProvider::registerCommands(): // $this->commands([]);  // commented
    // SchedulerServiceProvider::registerCommandSchedules(): // entire body commented
- Why it's a risk: dueSchedules() is never called. The cron-safe isDue() method (which correctly
  catches Throwable and returns false for malformed expressions) is the best-implemented piece in
  the module, but it has no caller. The entire service layer is dead weight until the execution
  engine (BUG-SDL-001) is built.
- Fix: Implement BUG-SDL-001 (ScheduleDispatchCommand). The command's handle() should call
  SchedulerService::dueSchedules() then loop, calling runSchedule() on each. This would activate
  both orphaned methods.
- Confidence: High (grep for 'dueSchedules' in Modules/Scheduler returns only the definition
  in SchedulerService.php; no callers)
- Systemic? Module-local dead code; consequence of BUG-SDL-001.
```

---

```
[BUG-SDL-005] Severity: P2 | scope hardcoded to 'prime' in store() — school-level schedules impossible
- Location: Modules/Scheduler/app/Http/Controllers/SchedulerController.php:47
- Evidence:
    Schedule::create([
        ...
        'schedule_type' => 'prime',    // ← hardcoded; ignores form input or SchedulerType constant
        ...
    ]);
- Why it's a risk: The create form does not include a scope selector (create.blade.php confirmed).
  Even if the form were extended to include schedule_type, the controller ignores it. BR-SDL-005
  (school required for school-level scope), BR-SDL-006 (scope/job-type compatibility), and
  BR-SDL-023 (tenancy init for school-level tasks) all depend on schedule_type being dynamic.
  SchedulerType::PRIME / ::TENANT constants exist but are never used in the controller.
- Fix: Add schedule_type field to ScheduleRequest::rules() (Rule::in(['prime','tenant'])). Add
  'schedule_type' to Schedule::$fillable. Add conditional tenant_id validation (required_if:
  schedule_type,tenant). Add scope selector to create.blade.php. Remove the hardcoded 'prime'.
- Confidence: High (read store() method; read create.blade.php — no scope selector field)
- Systemic? Module-local functional gap.
```

---

## P3 Findings

---

```
[ARCH-SDL-001] Severity: P3 | SchedulerType uses PHP class constants, not PHP 8.1+ backed enum
- Location: Modules/Scheduler/app/Enums/SchedulerType.php
- Evidence:
    class SchedulerType   // plain class, not `enum SchedulerType: string`
    {
        public const PRIME = 'prime';
        public const TENANT = 'tenant';
    }
- Why it's a risk: PHP 8.1+ backed enums provide type safety, IDE auto-completion, and can be
  cast natively by Eloquent. The project runs PHP 8.2+. This is a missed opportunity for type
  safety, not a functional defect.
- Fix: Convert to `enum SchedulerType: string { case PRIME = 'prime'; case TENANT = 'tenant'; }`
  Update references from SchedulerType::PRIME to SchedulerType::PRIME->value where needed.
- Confidence: High (read Enums/SchedulerType.php in full)
- Systemic? Module-local; noted in lessons as design debt.
```

---

```
[ARCH-SDL-002] Severity: P3 | JobRegistry has only 3 entries — FRD targets 10+
- Location: Modules/Scheduler/app/Services/JobRegistry.php:17-22
- Evidence:
    return [
        'tenant_test_job' => TenantTestJob::class,
        'prime_test_job'  => PrimeTestJob::class,
        'prime_billing_report_job' => BillingReportJob::class,
    ];
    // FRD Section E.2 plans: ExpireRecommendationsJob, FeeReminderJob, AttendanceSmsJob,
    //   PdfBatchReportJob, DataArchivalJob, TimetableConstraintValidationJob — all planned
- Why it's a risk: Registry is the job catalog for REQ-SDL-009. At 3 entries (two of which are
  test stubs), the catalog cannot support real platform scheduling workloads. Job class imports
  in JobRegistry.php reference `App\Jobs\Prime\BillingReportJob` and two test jobs — these must
  implement SchedulableJob contract (JobRegistry::get() validates this). If the imported job
  classes do not implement SchedulableJob, JobRegistry::get() returns null silently for them.
- Fix: After implementing each planned job class, add entries to JobRegistry::all(). Verify each
  class implements SchedulableJob::description() and ::allowedScheduleTypes(). Target: 10+ entries.
- Confidence: High (read JobRegistry.php:17-22; FRD Section E.2)
- Systemic? Module-local catalog growth debt.
```

---

```
[DEAD-SDL-002] Severity: P3 | Test file asserts broken state — must be inverted after security fix
- Location: Modules/Scheduler/tests/Unit/SchedulerModuleTest.php:65-80
- Evidence:
    test('entire controller has ZERO Gate::authorize calls', function () {
        $source = file_get_contents((new ReflectionClass(SchedulerController::class))->getFileName());
        expect($source)->not->toContain('Gate::authorize');  // ← asserts ABSENCE of Gate calls
    });
    test('update method is empty', function () { ... expect($source)->not->toContain('->update('); });
    test('destroy method is empty', function () { ... expect($source)->not->toContain('->delete()'); });
- Why it's a risk: These tests will PASS as long as the module is broken. They will FAIL once
  the security and stub fixes are applied. If a developer runs the test suite after fixing SEC-SDL-001
  they will see red and may think their fix introduced a regression.
- Fix: After applying SEC-SDL-001 and BUG-SDL-002 fixes, invert all three assertions:
  expect($source)->toContain('Gate::authorize'); etc. Rename the describe block from
  "Zero Auth (Critical)" to "Gate Authorization Coverage". Add positive feature tests
  (HTTP 403 for unauthenticated, 403 for tenant user, 200 for prime admin).
- Confidence: High (read test file lines 62-80)
- Systemic? Module-local documentation artifact; lessons-learned entry in module-knowledge confirms.
```

---

## Layer Health Summary

| Layer | Status | Key Finding |
|-------|--------|-------------|
| 1 DDL Schema | Amber | 2 ENUM columns (D29), INT signed PK, 7 missing columns across 2 tables |
| 2 Migration ↔ Model ↔ DDL | Amber | 7 missing DB columns; last_run_at/next_run_at in migration but not in $fillable |
| 3 ORM | Amber | Casts mostly correct (payload, is_active, datetime); missing relationships on both models |
| 4 Code Quality | **Red** | Empty update() + destroy() (live routes); SchedulerService orphaned; only 2/7 methods have real logic |
| 5 Authorization | **Red** | Zero Gate::authorize() in all 7 methods; no SchedulePolicy; no permission seeder |
| 6 Multi-Tenancy | Amber | Central web.php routes correct; RSP applies wrong middleware (TEN-SDL-001) |
| 7 Validation | **Red** | job_key unvalidated; cron_expression unvalidated; payload JSON unvalidated; scope hardcoded |
| 8 Data Integrity / Tx | Amber | Single-record creates (no transactions needed); SoftDeletes absent breaks archive integrity |
| 9 Performance | Amber | index() uses unbounded get(); small table at present; no eager-load concerns (no relationships) |
| 10 Queue / Job / Scheduler | **Red** | No Artisan command; no runSchedule(); ScheduleRun never written; registerCommandSchedules() commented out |
| 11 Frontend / Blade | Amber | Views use `{{ }}` (XSS-safe); Runs/Toggle buttons have empty action URLs; failure_count column null; edit/trash have wrong content |
| 12 Deployment | Amber | Module migrations run via loadMigrationsFrom (prime_db); views render; route names resolve; no command registered |

---

## STEP 1 Reading-Discipline Output — Three-Way Reconcile

### Schema Baseline Note
No separate DDL file exists for this module in `old_db/2-DDL_Tenant_Consolidated/`. The BA
(lessons-learned 2026-06-29) confirmed the only `Scheduler_ddl_v1.sql` in the DDL folder belongs
to a testing framework table (`tst_schedules`), not this module. FRD Section E.1 (Data Dictionary)
is used as the schema specification baseline.

### Table: `schedules`

| Column | FRD E.1 (spec) | Migration (ships) | Model (Eloquent) | Verdict |
|--------|----------------|-------------------|------------------|---------|
| id | INT UNSIGNED PK | `->increments('id')` (INT signed) | — | MISMATCH: INT signed vs UNSIGNED |
| name | VARCHAR(255) NOT NULL | `->string('name')` | $fillable ✓ | OK |
| schedule_type | sys_dropdown FK (D29) | `->enum('prime','tenant')` | $fillable ✓, no cast | D29 VIOLATION (MIG-SDL-001) |
| tenant_id | VARCHAR(255) NULL | `->string()->nullable()->index()` | $fillable ✓ | OK |
| job_key | VARCHAR(255) NOT NULL | `->string('job_key')` | $fillable ✓ | OK |
| payload | JSON NULL | `->json()->nullable()` | $fillable ✓, cast array ✓ | OK |
| cron_expression | VARCHAR(255) NOT NULL | `->string('cron_expression')` | $fillable ✓ | OK |
| is_active | TINYINT(1) DEFAULT 1 | `->boolean()->default(true)` | $fillable ✓, cast boolean ✓ | OK |
| last_run_at | TIMESTAMP NULL | `->timestamp()->nullable()` | **ABSENT from $fillable** | PARTIAL (ORM-SDL-002) |
| next_run_at | TIMESTAMP NULL | `->timestamp()->nullable()` | **ABSENT from $fillable** | PARTIAL (ORM-SDL-002) |
| failure_count | INT UNSIGNED DEFAULT 0 | **ABSENT** | **ABSENT** | MISSING (DAT-SDL-001) |
| created_by | BIGINT NULL FK→sys_users | **ABSENT** | **ABSENT** | MISSING (DAT-SDL-001) |
| deleted_at | TIMESTAMP NULL | **ABSENT** | **No SoftDeletes** | MISSING (DAT-SDL-001 + ORM-SDL-001) |
| created_at / updated_at | TIMESTAMP | `->timestamps()` | $timestamps default true | OK |

### Table: `schedule_runs`

| Column | FRD E.1 (spec) | Migration (ships) | Model (Eloquent) | Verdict |
|--------|----------------|-------------------|------------------|---------|
| id | INT UNSIGNED PK | `->increments('id')` (INT signed) | — | MISMATCH: INT signed |
| schedule_id | INT UNSIGNED FK→schedules.id | `->unsignedInteger('schedule_id')` + FK RESTRICT | $fillable ✓ | OK |
| tenant_id | VARCHAR(255) NULL | `->string()->nullable()->index()` | $fillable ✓ | OK |
| status | sys_dropdown FK (D29) | `->enum('running','success','failed')` | $fillable ✓, no cast | D29 VIOLATION (MIG-SDL-002) |
| error_message | TEXT NULL | `->text()->nullable()` | $fillable ✓ | OK |
| started_at | TIMESTAMP NOT NULL | `->timestamp('started_at')` | $fillable ✓, cast datetime ✓ | OK |
| finished_at | TIMESTAMP NULL | `->timestamp()->nullable()` | $fillable ✓, cast datetime ✓ | OK |
| duration_ms | INT NULL | `->integer('duration_ms')->nullable()` | $fillable ✓ | OK (no int cast — minor) |
| output | LONGTEXT NULL | **ABSENT** | **ABSENT** | MISSING (DAT-SDL-001) |
| attempt | TINYINT UNSIGNED DEFAULT 1 | **ABSENT** | **ABSENT** | MISSING (DAT-SDL-001) |
| created_by | BIGINT NULL | **ABSENT** | **ABSENT** | MISSING (DAT-SDL-001) |
| deleted_at | TIMESTAMP NULL | **ABSENT** | **No SoftDeletes** | MISSING (DAT-SDL-001 + ORM-SDL-001) |
| created_at / updated_at | TIMESTAMP | `->timestamps()` | $timestamps default true | OK |

### Snapshot Corrections

| Stale snapshot | Live code | Correction |
|----------------|-----------|------------|
| progress.md: "No tenancy middleware in RSP" | RSP line 41-49 has InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive | WRONG middleware on RSP (central module should have none). Snapshot stale. See TEN-SDL-001. |
| known-issues.md systemic note: "Scheduler & EventEngine now FIXED" (D23 reference) | Live RSP has tenancy middleware but it is INCORRECT for a central module | Not "fixed" — changed to wrong middleware. Note should say "RSP middleware present but wrong for central module (TEN-SDL-001)". |
| module-knowledge: D-SDL-06 says "RSP applies only web middleware" | RSP applies full tenant stack | D-SDL-06 documents the DESIRED state (central module, web only). The implementation contradicts D-SDL-06. |
| module-knowledge: Completion ~40% | Live audit: 3 P0 + 9 P1 findings; execution engine absent; update/destroy empty | Corrected to ~25%. |

---

## FRD Gap Summary (Mode B)

| REQ-ID | Feature | Priority | DDL | Screen | Code | Test | Key Gap |
|--------|---------|----------|-----|--------|------|------|---------|
| REQ-SDL-001 | Schedule Dashboard | P0 | Partial (7 missing cols) | Exists | Partial (no auth, no paginate, no filter) | 0 feature tests | Auth + pagination + search + failure_count column |
| REQ-SDL-002 | Create Job Schedule | P0 | Partial | Exists | Partial (double-validation, no scope, no registry/cron validation) | 0 feature tests | Validation completeness, scope handling, Next Run Time compute |
| REQ-SDL-003 | Edit Job Schedule | P0 (FRD) | Partial | Wrong content | NOT STARTED (update() empty) | 0 | Entire feature — update(), edit() view, Next Run Time recompute |
| REQ-SDL-004 | Archive and Restore | P1 | Missing deleted_at | Wrong content (copy-paste) | NOT STARTED | 0 | SoftDeletes, destroy(), restore(), trashedSchedule(), trash view |
| REQ-SDL-005 | Enable / Pause | P1 | OK (is_active exists) | Button with no action URL | NOT STARTED (no toggleStatus(), no route) | 0 | toggleStatus(), PATCH route, AJAX response |
| REQ-SDL-006 | Manual Trigger | P1 | schedule_runs present | No trigger button wired | NOT STARTED (no run(), no route) | 0 | run(), POST route, runSchedule() service call |
| REQ-SDL-007 | Run History | P1 | Missing output/attempt | No runs.blade.php | NOT STARTED (ScheduleRun never written) | 0 | runs view, runs route, runs() controller method, ScheduleRun writes |
| REQ-SDL-008 | Execution Engine | P0 | Partial | N/A (background) | NOT STARTED (runSchedule(), command absent) | 0 | Entire engine: runSchedule(), ScheduleDispatchCommand, withoutOverlapping() |
| REQ-SDL-009 | Job Catalog Mgmt | P2 | N/A (in-code) | Create dropdown reads registry ✓ | Partial (3/10+ jobs registered) | 0 | Expand registry to 10+ entries as job classes are built |

**Coverage totals:** 2 Partial / 7 Not Started or Not-Functional | 0 feature tests for any REQ

---

## Business-Rule Enforcement (Mode C)

| BR-ID | Rule Summary | Type | Enforcement Location | Status | Gap / Evidence |
|-------|-------------|------|---------------------|--------|----------------|
| BR-SDL-001 | Permission gate on all screens | Permission | Gate::authorize in all controller methods | **MISSING** | SEC-SDL-001: zero Gate calls |
| BR-SDL-002 | Job type must be in Job Catalog | Validation | FormRequest Rule::in(JobRegistry::keys()) | **MISSING** | VAL-SDL-001: only 'required','string' |
| BR-SDL-003 | Valid cron expression required | Validation | FormRequest ValidCronExpression rule | **MISSING** | VAL-SDL-002: only 'required','string','max:255' |
| BR-SDL-004 | Payload valid JSON, max 10k chars | Validation | FormRequest ValidJsonString rule | **MISSING** | ScheduleRequest has no JSON/max validation on payload |
| BR-SDL-005 | School required for school-level scope | Validation | FormRequest required_if rule | **MISSING** | BUG-SDL-005: scope hardcoded 'prime' |
| BR-SDL-006 | Scope/job-type compatibility | Validation | FormRequest cross-field check | **MISSING** | Not implemented |
| BR-SDL-007 | Unique schedule name | Validation | FormRequest unique('schedules','name') rule | **MISSING** | Not in ScheduleRequest::rules() |
| BR-SDL-008 | Compute Next Run Time on save | Calculation | SchedulerService::computeNextRunAt() | **MISSING** | Service method does not exist; next_run_at never written |
| BR-SDL-009 | Edit does not cancel in-flight runs | Concurrency | Separate DB write (no lock needed) | N/A | update() is empty; no in-flight runs possible |
| BR-SDL-010 | Archive pauses execution immediately | Workflow | Soft-delete sets deleted_at; engine query filters IS NULL | **MISSING** | ORM-SDL-001: no SoftDeletes; destroy() empty |
| BR-SDL-011 | Only Super Admin can force-delete | Permission | SchedulePolicy::forceDelete() | **MISSING** | No policy exists |
| BR-SDL-012 | Permanent delete cascades to run records | Workflow | Service layer explicit cascade (or DB cascade) | **MISSING** | destroy() empty |
| BR-SDL-013 | Toggle changes only is_active | Workflow | toggleStatus() controller method | **MISSING** | No toggleStatus() method or route |
| BR-SDL-014 | Manual trigger creates Execution Record | Workflow | SchedulerService::runSchedule() | **MISSING** | BUG-SDL-001: runSchedule() absent |
| BR-SDL-015 | Manual trigger bypasses paused state | Workflow | run() bypasses is_active check | **MISSING** | No run() method or route |
| BR-SDL-016 | Archived excluded from list and engine | Workflow | SoftDeletes default scope + engine query filter | **MISSING** | SoftDeletes absent; dueSchedules() has no deleted_at filter |
| BR-SDL-017 | All writes logged to activity trail | Workflow | activityLog() calls in controller / service | **MISSING** | Zero activityLog() calls in Modules/Scheduler |
| BR-SDL-018 | Run history sorted by start_time desc | Validation | Query orderBy('started_at','desc') | **MISSING** | No runs() controller method or view |
| BR-SDL-019 | Run history paginated at 15/page | Validation | ->paginate(15) on runs query | **MISSING** | No runs() controller method |
| BR-SDL-020 | Engine only processes active, non-archived | Workflow | Command query: is_active=true AND deleted_at IS NULL | **MISSING** | BUG-SDL-001: no command; dueSchedules() has no deleted_at filter |
| BR-SDL-021 | Cron due-check semantics | Calculation | SchedulerService::isDue() via CronExpression | **PARTIAL** | isDue() implemented and correct; no caller (DEAD-SDL-001) |
| BR-SDL-022 | Per-schedule failure isolation | Reliability | try/catch per schedule in command loop | **MISSING** | BUG-SDL-001: no command |
| BR-SDL-023 | School context initialization for school tasks | Security/Workflow | tenancy()->initialize($tenant) in runSchedule() | **MISSING** | BUG-SDL-001: runSchedule() absent |
| BR-SDL-024 | Overlap prevention on execution command | Concurrency | ->withoutOverlapping() in registerCommandSchedules() | **MISSING** | BUG-SDL-001: no command; registerCommandSchedules() commented out |

**Enforcement summary:** 1 PARTIAL (BR-SDL-021) | 23 MISSING | 0 ENFORCED

---

## Systemic-Pattern Scorecard (Mode D, scoped to SDL)

| Pattern | SDL Status | Evidence |
|---------|-----------|----------|
| D17: $fillable references missing column | **Present (P2)** | last_run_at, next_run_at in migration; absent from $fillable |
| D24: permission-prefix chaos / typos | **Not applicable** | Zero Gate calls exist to have wrong prefixes |
| D25: $request->all() into models | **Clean** | store() uses $request->validate() result (via $data); no $request->all() |
| D29: ->enum() in migrations | **Present (P2) ×2** | schedules.schedule_type, schedule_runs.status |
| D30: FormRequest authorize() = true | **Present (P1)** | ScheduleRequest.authorize() line 50: return true |
| D36: Generated column degraded in migration | **N/A** | No GENERATED columns in SDL schema |
| D37: Status INT FK vs string mismatch | **N/A** | schedule_runs.status is ENUM; code uses matching strings |
| D38: SoftDeletes/timestamp trait vs DDL mismatch | **Present (P1)** | Models use default $timestamps (OK); SoftDeletes trait absent, deleted_at absent from migration |
| D39: Permissions unseeded → super-admin-only | **Present (P1)** | No permission seeder; no SchedulePolicy; no ability strings defined anywhere in module |
| Layer 2.5: Cross-DB / missing FK targets | **Clean** | schedule_runs.schedule_id → schedules.id (same DB, same migration set); no sys_dropdowns FK |
| Layer 6.2: initialize() without end() | **N/A** | No tenancy()->initialize() calls in SDL |
| Layer 10.1: Jobs without tenancy/retry config | **N/A** | No job classes in SDL |
| TEN-RTG-001: EnsureTenantHasModule missing | **N/A** | Central module; middleware not applicable |

---

## vs Platform Baseline

| Metric | Platform baseline | SDL | Delta |
|--------|-----------------|-----|-------|
| FormRequests with bare-true authorize() | 437/485 (90%) | 1/1 (100%) | At or above norm |
| Write controllers with zero authz | 64 platform-wide | 1/1 (100%) | Worst-case (real logic, not empty stub) |
| ->enum() in tenant migrations | ~476 platform-wide | 2 | Contributes 2 to baseline |
| ->increments('id') signed INT PK | 428/658 | 2/2 (100%) | At baseline |
| $fillable references missing column (D17) | 66 models | 1 model (last_run_at/next_run_at) | Typical |
| D39 unseeded permissions | Feedback, Dashboard confirmed | SDL also | Confirms systemic |
| God controller (>1000 lines) | StudentController 4222 | 86 lines — smallest controller | Clean |
| D25 $request->all() | 24 platform sites | 0 | Clean |
| Execution engine missing | Module-local | SDL core | Unique severity |
| Module health score | Range 18-75 across audited | **32/100** | Severely below norm |

---

## Recommended Fix Order

| Order | Finding | Effort | What it unblocks |
|-------|---------|--------|-----------------|
| 1 | **SEC-SDL-001** — Add SchedulePolicy + Gate::authorize to all 7 methods | 2.0h | All pages require legitimate access; blocks testing until fixed |
| 2 | **SEC-SDL-002** — Fix ScheduleRequest::authorize() | 0.25h | Defense-in-depth; trivial after #1 |
| 3 | **BUG-SDL-002** — Implement update() and destroy() with SoftDeletes (ties to ORM-SDL-001) | 1.5h | Edit and archive features |
| 4 | **ORM-SDL-001 + DAT-SDL-001** — Add SoftDeletes to both models + new migrations for missing columns | 1.0h | Archive/restore, run history columns, failure_count in index |
| 5 | **BUG-SDL-003** — Implement trashedSchedule() + fix trash view | 1.0h | /scheduler/schedule/trash stops returning 500 |
| 6 | **BUG-SDL-001** — Implement SchedulerService::runSchedule() + ScheduleDispatchCommand | 3.0h | Core module purpose — schedules actually execute |
| 7 | **VAL-SDL-001 + VAL-SDL-002** — Add job-key whitelist rule + ValidCronExpression rule | 1.5h | Input integrity before execution engine goes live |
| 8 | **BUG-SDL-004** — Remove inline $request->validate() from store() | 0.25h | Clean validation contract |
| 9 | **PERF-SDL-001** — Replace ->get() with ->paginate(15) + filter support in index() | 0.5h | NFR-SDL-001 compliance |
| 10 | **RT-SDL-001** — Remove 2 of 3 duplicate route blocks from central web.php | 0.25h | Route clarity, cache safety |
| 11 | **TEN-SDL-001** — Fix RSP middleware (remove tenant stack from central module) | 0.25h | RSP routes no longer dead/wrong-context |
| 12 | **BUG-SDL-005** — Scope selection in create form + remove hardcoded 'prime' | 1.0h | School-level schedule creation |
| 13 | **ORM-SDL-002 + ORM-SDL-003** — Add missing fillable/casts/relationships to both models | 0.5h | Execution engine can mass-assign last_run_at; run history ORM path exists |
| 14 | **MIG-SDL-001 + MIG-SDL-002** — Convert ENUM to VARCHAR + validation (D29) | 1.0h | D29 compliance; allows scope/status extension |
| 15 | **D39** — Create permission seeder for scheduler.* abilities | 0.5h | Non-super-admin Platform Admins can access module |
| 16 | **DEAD-SDL-002** — Invert test assertions | 0.5h | Test suite turns green after security fix |
| 17 | **ARCH-SDL-001 + ARCH-SDL-002** — Backed enum + JobRegistry expansion | 2.5h | Type safety + catalog completeness |

**Estimated total: ~17.5 hours across 2 sprints (Sprint 1: #1–#9 security+core, Sprint 2: #10–#17 quality+catalog)**

---

## Positive Findings

- SchedulerService::isDue() correctly catches Throwable for malformed cron expressions (BR-SDL-021 partially enforced) — the best-implemented piece in the module.
- JobRegistry::get() validates that the job class implements SchedulableJob interface before returning — prevents unintentional class dispatch.
- SchedulableJob contract (description(), allowedScheduleTypes()) is well-designed and correctly used in JobRegistry::forUi().
- No $request->all() into models (D25 clean).
- index.blade.php and create.blade.php use only `{{ }}` (escaped output — no XSS risk on rendered model fields).
- The module RSP was clearly intended to be updated correctly (it has the right middleware stack for a TENANT module); the central-vs-tenant classification just means the middleware choice is inverted.

---

## Next Steps

```
Audit complete — Health 32/100 (P0-capped). DEPLOY: NO-GO.
Recommended agent handoffs:
1. Fix P0 findings (SEC-SDL-001, BUG-SDL-001, BUG-SDL-002) → act as pa-backend-developer
2. Schema fixes (DAT-SDL-001 missing columns, MIG-SDL-001/002 ENUMs) → act as pa-db-architect
3. Full completeness score → act as pa-status-analyzer
4. Test coverage plan → act as pa-testing-architect
5. Platform D39 sweep (unseeded permissions across all modules) → re-run Mode D
```
