# Known Issues, Gotchas & Hard-Won Fixes

> Add entries here whenever you hit a non-obvious bug, a tricky tenancy issue, or a pattern
> that burned time to figure out. Future work should check this file first.

---

## Format
```
### [SHORT TITLE]
- **Module/Area:** ...
- **Symptom:** What went wrong / what error appeared
- **Root Cause:** Why it happened
- **Fix:** Exact solution applied
- **Prevention:** How to avoid in the future
```

---

## Platform-Wide Systemic Patterns (verified 2026-06-27 — read before any module audit)

> These are NOT per-module bugs — they are platform-wide patterns confirmed by a full-codebase
> survey. The Technical Auditor uses these as the baseline: a module exhibiting one of these is
> *typical*, not exceptional. Do NOT re-discover these from scratch per module — reference this
> section and quantify the specific module against the baseline. Full detectors live in
> `AI_Brain/agents/technical-auditor.md` (Platform Baseline + Mode D). Linked decisions in
> `AI_Brain/state/decisions.md`.

| Pattern | Baseline count | Severity | Decision |
|---------|----------------|----------|----------|
| FormRequest `authorize(){ return true; }` | **437 / 485 (90%)** | P1 (P0 where controller also ungated) | D30 |
| Live `create/update($request->all())` (mass-assign) | **24 sites** (GlobalMaster, Library, Syllabus heaviest) | P1 (P0 if model has privilege fields) | D25 |
| Write controllers with zero authorization primitive | **64** (some are empty scaffolds — confirm body) | P0/P1 | — |
| `->enum()` in tenant migrations (should be `sys_dropdown_table` FK) | **~476** (hst 28, sch 22, tt 20, tpt 19) | P2 | D29 |
| `->increments('id')` INT(11) signed PK | **428 / 658 tables** | P1 (FK typing + 2.1B-row cap) | — |
| Tenant FKs → `sys_dropdowns` (central-only table) | **52** | P0 (cross-DB FK, impossible in MySQL) | — |
| Tenant FKs → `sys_roles` (NO create migration exists) | **17** | P0 (`tenants:migrate` fails errno 150/1824) | — |
| `$fillable` lists a column the migration lacks (D17) | **66 models** | P1 (`SQLSTATE 42S22 Unknown column`) | D17 |
| `is_super_admin`/`super_admin_flag`/`password` in `$fillable` | `SchoolSetup/app/Models/User.php` | P0 (priv-esc via `$request->all()`) | — |
| Permission-prefix chaos + typos (`tennat.`, `schoolsetup` vs `school-setup`) | ~50 sites | P1 (silent auth deny/pass) | D24 |
| `tenancy()->initialize()` without `->end()` (context leak) | `Prime/DropdownNeedController.php:479,641` (P0); SchoolSetup console cmds (P1) | P0/P1 | — |
| Jobs touching tenant tables without tenancy re-init | Vendor, Inventory, FrontOffice, Hostel jobs | P0/P1 | — |
| Queue driver (`database`) vs Horizon (`redis`) mismatch | platform-wide | P0 (jobs stuck) | DEPLOY-HRZ-01 |
| Committed `.env-original` with live `APP_KEY` | repo root | P0 (rotate) | DEPLOY-ENV-02 |
| Seeder routes outside auth (SEC-RTG-001) | `routes/tenant.php:318+` | P0 | SEC-RTG-001 |
| Worst eager-load ratio (with:get) | **Hpc 0.04**, QuestionBank 0.43, LmsQuiz 0.48 | P1 (N+1) | — |
| God objects | `StudentController.php` 4222, `LmsExamController.php` 3767, `PrimeSolver.php` 4447 | P1 | — |

**Resolved since first survey:** D22 (module-owned routes/policies) RESOLVED; D23 (RSP tenancy) —
Scheduler & EventEngine now FIXED (verify SystemConfig/GlobalMaster only).

---

## Tenancy Issues

### Tenant DB Not Initialized on Queued Jobs
- **Module/Area:** All modules using queued jobs
- **Symptom:** Queued jobs fail with "Table not found" or query runs on wrong database
- **Root Cause:** Tenancy context is not automatically passed to queued jobs
- **Fix:** Use `TenancyAwareJob` or manually call `tenancy()->initialize($tenant)` inside the job's `handle()` method. Pass `$tenant->id` as a constructor argument.
- **Prevention:** Always implement `ShouldBeUniqueUntilProcessing` or pass tenant ID explicitly when dispatching jobs from tenant context.

### Cache Collision Between Tenants
- **Module/Area:** Any feature using Laravel Cache
- **Symptom:** One school sees another school's cached data
- **Root Cause:** Cache keys not prefixed with tenant ID
- **Fix:** Always prefix cache keys with `tenant()->id` or use `Cache::tags([tenant()->id])`
- **Prevention:** Never use bare string cache keys in tenant-scoped code. Always prefix.

### `InitializeTenancyByDomain` Fails on API Routes
- **Module/Area:** API routes in tenant modules
- **Symptom:** 404 or tenancy not initialized error on API calls
- **Root Cause:** API routes not wrapped in `tenancy` middleware group
- **Fix:** Ensure tenant API routes are in `routes/tenant.php` and use the `tenancy` middleware group
- **Prevention:** Check middleware groups in route files before adding new API routes.

---

## Module Issues

### Module Migration Not Running
- **Module/Area:** Any new module
- **Symptom:** Tables not created after `php artisan migrate`
- **Root Cause:** Tenant migrations must be in `database/migrations/tenant/` or use `php artisan module:make-migration --tenant`
- **Fix:** Move migration file to correct path, re-run `php artisan tenants:migrate`
- **Prevention:** Always use `--tenant` flag when creating migrations for tenant-scoped modules.

### Service Not Found in Container
- **Module/Area:** Any module
- **Symptom:** `BindingResolutionException` when controller tries to inject a service
- **Root Cause:** Service not registered in module's `ServiceProvider`
- **Fix:** Add `$this->app->singleton(EntityService::class)` to the module's `ServiceProvider::register()`
- **Prevention:** Use constructor injection only; register all services in the module provider.

---

## Database Issues

### Soft Delete + Unique Constraint Conflicts
- **Module/Area:** Any table with soft deletes and unique columns
- **Symptom:** Can't re-create a record with the same unique value after soft delete
- **Root Cause:** `deleted_at` is NULL for active records, but unique constraints don't account for soft-deleted rows
- **Fix:** Use composite unique: `->unique(['column', 'deleted_at'])` or use a `is_active` workaround
- **Prevention:** When adding unique constraints on tables with soft deletes, always make the index partial or composite.

---

## Testing Specific

### First DB Feature Test Run is Very Slow (~50s)
- **Area:** All Feature tests using `RefreshDatabase`
- **Symptom:** First test in the Feature suite takes 50-55s, subsequent tests are ~2s
- **Root Cause:** On the first run, SQLite in-memory DB is cold — Laravel runs ALL module migrations (29 modules × multiple migrations). This is one-time per test session.
- **Fix:** This is normal and expected. No action needed.
- **Prevention:** If speed becomes an issue, consider `--parallel` flag or splitting test suites.

### Spatie MediaLibrary PHP 8.4 Deprecation in Unit Tests
- **Area:** Any model using `InteractsWithMedia` (Student, etc.)
- **Symptom:** `DEPR` warning on first test that instantiates the model — `registerMediaConversions(): Implicitly marking parameter $media as nullable is deprecated`
- **Root Cause:** Spatie MediaLibrary code hasn't been updated for PHP 8.4 strict nullable types
- **Fix (in model):** Change `public function registerMediaConversions(Media $media = null)` → `public function registerMediaConversions(?Media $media = null)`
- **Prevention:** Only affects models with `InteractsWithMedia`. Unit tests still pass — it's a warning not a failure.

### Two Identical Setting Models
- **Area:** Setting model
- **Symptom:** `Modules\Prime\Models\Setting` and `Modules\SystemConfig\Models\Setting` are identical — same table `sys_settings`, same code
- **Root Cause:** Likely copy-paste during module split. Controllers use `SystemConfig\Models\Setting`.
- **Fix:** Consolidate to one model (pending decision). For now, write tests against `Modules\Prime\Models\Setting` (the one listed in the task).

### Setting HTTP Feature Tests Cannot Be Written Yet
- **Area:** Setting (HTTP layer)
- **Symptom:** `Modules/SystemConfig/routes/web.php` is empty — no setting routes registered
- **Root Cause:** Routes not defined yet
- **Fix:** Define routes first, then HTTP tests can be added.

## Library Module

### Library Code Built But Not Wired Into Tenancy
- **Module/Area:** `Modules/Library/` — all controllers, models, services
- **Symptom:** Library features are inaccessible in tenant context despite 26 controllers, 35 models, 9 services, 140 views, and 36 tenant migrations being built
- **Root Cause:** Library routes only registered via module's own `RouteServiceProvider` (maps `routes/web.php` with standard `web` middleware), not through `routes/tenant.php` with tenancy middleware. Only 1 route exists: `Route::resource('libraries', LibraryController::class)`.
- **Fix needed:** Register all Library routes in `routes/tenant.php` under `auth` + `verified` + tenant middleware group. Use `lib_` table prefix. Verify all models use correct table names.
- **Prevention:** All new tenant modules must have routes registered in `routes/tenant.php`, not just in their module-level `routes/web.php`.
- **Discovered:** 2026-03-14 codebase audit after module merge.

## SmartTimetable Specific

### TimetableSolution::remove() Used Wrong Placement Key
- **Module/Area:** `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php`
- **Symptom:** After calling `remove($activity, $slot)`, `isPlaced($instanceKey)` still returned `true`. The activity appeared placed even after removal, causing the parallel group backtrack guard to incorrectly skip activities.
- **Root Cause:** `place()` stored placements using key `$activity->instance_id ?? $activity->id` (e.g. `'101-1'`), but `remove()` looked up by `$activity->id` (integer `101`). The keys never matched, so `unset()` silently did nothing.
- **Fix:** Changed `remove()` to use `$activityId = $activity->instance_id ?? $activity->id` as the lookup key — identical to `place()`.
- **Prevention:** Whenever two methods maintain a shared keyed array, extract the key derivation to a single private method (e.g. `getActivityKey($activity)`) so key logic cannot diverge.
- **Discovered via:** Unit test `it('returns false after placement is removed via remove()')` in `TimetableSolutionIsPlacedTest.php` (2026-03-14).

---

## LMS Modules (deep-audited 2026-03-14)

### BUG-LMS-001: `dd($e)` in LmsExamController::store() — Exposes Stack Traces in Prod
- **Module/Area:** `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` line 565
- **Symptom:** Any exam creation error dumps raw PHP exception to browser
- **Root Cause:** `dd($e)` left in catch block; also prevents `DB::rollBack()` from executing
- **Fix:** Remove `dd($e)`, use `Log::error($e)` + `DB::rollBack()` + `return back()`

### BUG-LMS-002: ExamBlueprintController + ExamScopeController — All Gate Calls Commented Out
- **Module/Area:** `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php`, `ExamScopeController.php`
- **Symptom:** Any authenticated user can CRUD exam blueprints and scopes
- **Fix:** Uncomment all `Gate::authorize()` calls

### BUG-LMS-003: LmsHomeworkController::HoemworkData() — Missing $request Parameter
- **Module/Area:** `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` line 49
- **Symptom:** Fatal `Undefined variable $request` on every homework listing page load
- **Root Cause:** Method declared with no params but uses `$request->class`, `$request->subject_id`
- **Fix:** Add `Request $request` parameter to method signature

### BUG-LMS-004: HomeworkSubmissionController::review() — No Auth or Validation
- **Module/Area:** `Modules/LmsHomework/app/Http/Controllers/HomeworkSubmissionController.php` line 285
- **Symptom:** Any authenticated user can overwrite student grades and teacher feedback
- **Fix:** Add `Gate::authorize()` and input validation

### BUG-LMS-005: LmsQuizController + LmsQuestController — Gate Commented Out in index()
- **Module/Area:** `LmsQuizController.php` line 34, `LmsQuestController.php` line 35
- **Symptom:** All quizzes/quests visible to any authenticated user
- **Fix:** Uncomment the `Gate::authorize()` calls

### SEC-LMS-001: No EnsureTenantHasModule Middleware on Any LMS Route Group
- **Module/Area:** `routes/tenant.php` lines 478, 591, 646, 704
- **Symptom:** Schools without LMS module in their plan can access all LMS features
- **Fix:** Add `EnsureTenantHasModule` middleware to all 4 LMS route groups

### PERF-LMS-001: 12 Unbounded Queries in LmsExamController::index()
- **Module/Area:** `LmsExamController.php` lines 60–67
- **Symptom:** Full-table scans on Student, QuestionBank, etc. on every page load
- **Fix:** Move dropdown data to AJAX endpoints; cache reference data

## StudentFee Specific (deep-audited 2026-03-14)

### BUG-FEE-001: FeeConcessionController Imported But Does Not Exist
- **Module/Area:** `routes/tenant.php` line 47
- **Symptom:** Fatal class-not-found error when routes are cached (`php artisan route:cache`)
- **Fix:** Remove dead import or create the missing controller

### SEC-FEE-001: Seeder Route Exposed in Production
- **Module/Area:** `routes/tenant.php` line 307 — `GET /student-fee/seeder`
- **Symptom:** Any authenticated user can create fake students/teachers/fee data via `StudentFeeController::seederFunction()`
- **Fix:** Remove route entirely or gate with `abort_unless(app()->isLocal(), 403)`

### SEC-FEE-002: Permission Prefix Mismatch on 3 Controllers
- **Module/Area:** `FeeHeadMasterController`, `FeeGroupMasterController`, `FeeStructureMasterController`
- **Symptom:** Authorization silently broken — uses `student-fee.*` prefix but RBAC registers `studentfee.*`
- **Fix:** Standardize all Gate calls to `studentfee.*` (no hyphen)

### SEC-FEE-003: StudentFeeManagementController — Zero Auth on All 8 View Methods
- **Module/Area:** `Modules/StudentFee/app/Http/Controllers/StudentFeeManagementController.php`
- **Symptom:** Any authenticated user can see full financial dashboard, all fee data
- **Fix:** Add `Gate::authorize()` to all view methods

### PERF-FEE-001: N+1 in Bulk Invoice + Assignment Generation
- **Module/Area:** `FeeInvoiceController::generateFeeInvoice()`, `FeeStudentAssignmentController::generateStudentAssignment()`
- **Symptom:** 1000+ queries for 500 students — 1 query per student per operation
- **Fix:** Pre-load all existing records into collections; batch insert/update

## HPC PDF / DomPDF Rendering (discovered during PDF fix session 2026-03-14)

### PDF-001: `display:inline` on `<table>` Causes Hard Crash
- **Module/Area:** HPC PDF templates (`*_pdf.blade.php`)
- **Symptom:** DomPDF fatal: *"Min/max width is undefined for table rows"* — entire PDF fails to render
- **Root Cause:** `<table style="display:inline;">` — DomPDF's table layout engine requires block or table display modes; inline mode corrupts internal width calculations
- **Fix:** Remove `display:inline;` from any `<table>` style. Use `<td style="text-align:right;">` on the parent cell instead
- **Prevention:** Never apply `display:inline` or `display:inline-block` to `<table>` elements in DomPDF templates

### PDF-002: Nested `<table>` Without HTML `width` Attribute Causes Hard Crash
- **Module/Area:** HPC PDF templates
- **Symptom:** DomPDF fatal: *"Min/max width is undefined for table rows"* when a `<table>` is inside a `<td>` cell
- **Root Cause:** CSS-only `style="width:100%"` is insufficient — DomPDF requires the HTML `width` attribute for layout calculation on nested tables. Without it, the width is undefined and table row rendering crashes.
- **Fix:** Always add `width="100%"` as an HTML attribute on every `<table>`: `<table width="100%" style="...">`
- **Prevention:** In DomPDF: EVERY `<table>` element (especially those nested inside `<td>`) needs `width="100%"` as an HTML attribute, not just in CSS

### PDF-003: `</div>` Instead of `</td>` Inside `<table><tr>` Causes Hard Crash
- **Module/Area:** HPC PDF templates (fourth_pdf Fix 1)
- **Symptom:** DomPDF fatal: *"Parent table not found for table cell"* — entire PDF fails to render
- **Root Cause:** A closing `</div>` tag inside `<table><tr>...</tr></table>` where `</td>` was expected. DomPDF's HTML parser is strict about table structure — mismatched closing tags cause the internal table cell registry to lose track of context.
- **Fix:** Always verify closing tags in multi-column table structures; change `</div>` → `</td>` at the exact location
- **Prevention:** In complex two-column `<table>` layouts, always check that each `<td>` opened in a `<tr>` is closed with `</td>` not `</div>` before the next `<td>` or `</tr>`

### PDF-004: Unclosed `<div>` Page-Container in `@foreach` Loop — All Pages Nest
- **Module/Area:** HPC PDF templates (fourth_pdf Fix 2)
- **Symptom:** DomPDF renders all pages nested inside each other — first page's content fills the entire PDF; subsequent pages appear as overflow artifacts
- **Root Cause:** `<div class="page-container">` opened once per `@foreach($sortedParts as $part)` iteration but `</div>` to close it was never written before `@endforeach`. DomPDF parses the resulting deeply nested `<div>` tree as one huge block.
- **Fix:** Add `</div>{{-- close page-container --}}` immediately before `@endforeach`
- **Prevention:** Any `<div>` opened inside a `@foreach` loop MUST be closed before `@endforeach`. Use `{{-- open page-container --}}` and `{{-- close page-container --}}` comments to make the open/close pair visible during review.

### PDF-005: Duplicate `@if` Page Block Outside Page-Container — Page Renders Twice
- **Module/Area:** HPC PDF templates (fourth_pdf Fix 3)
- **Symptom:** One page in the PDF renders twice in a row; content appears duplicated
- **Root Cause:** An old `@if($part->page_no == N)` block remained outside the page-container loop as an unindented leftover (copy-paste artifact). The block inside the loop renders the page once; the orphan block renders it a second time outside any proper page wrapper.
- **Fix:** Delete the unindented orphan block entirely; keep only the properly indented version inside the `@foreach` page-container
- **Prevention:** Before adding page-specific content blocks, search the entire file for other `@if($part->page_no == N)` occurrences to ensure no duplicates exist

### PDF-006: HTTP Image URLs Blocked by DomPDF — Student Photo Blank
- **Module/Area:** HPC PDF templates (all four PDFs, Fix 9 / Fix 6)
- **Symptom:** Student photo box renders blank/empty; no error thrown
- **Root Cause:** `getFirstMediaUrl()` returns an HTTP URL (e.g., `https://schoolname.prime-ai.com/storage/...`). DomPDF has `isRemoteEnabled = false` by default — HTTP URLs for images are silently ignored.
- **Fix:** Use `getFirstMedia()->getPath()` to get the filesystem path, read file contents via `file_get_contents()`, and encode as base64 data URI: `data:image/jpeg;base64,...`
- **Prevention:** NEVER pass `getFirstMediaUrl()` / `tenant_asset()` / `asset()` HTTP URLs to `<img src>` in DomPDF templates. Always convert to base64 data URIs via filesystem path. Also add `file_exists()` guard before reading.

### PDF-007: `overflow:hidden` on Divs Silently Ignored or Clips Content
- **Module/Area:** HPC PDF templates (Fix 6/Fix 5)
- **Symptom:** Section borders/border-radius don't clip inner content as expected; or inner content is clipped in unexpected ways that make the layout look broken
- **Root Cause:** DomPDF does not implement CSS `overflow:hidden` reliably on block elements. It is either silently ignored or partially applied in ways that differ from browser behavior.
- **Fix:** Remove all `overflow:hidden` from `<div>` styles in DomPDF templates. Use explicit padding/margin instead of relying on overflow clipping for layout.
- **Prevention:** Never use `overflow:hidden` in DomPDF PDF templates. It is a browser-only layout property.

### PDF-008: `display:inline-block` on `<div>` Silently Ignored
- **Module/Area:** HPC PDF templates (fourth_pdf Fix 8 — 20 occurrences)
- **Symptom:** Divs that should appear side-by-side stack vertically instead; layout looks like everything is full-width
- **Root Cause:** DomPDF does not support `display:inline-block` on `<div>` (block) elements. The property is silently ignored, and the elements render as `display:block`.
- **Fix:** Replace `display:inline-block` divs with `<table width="100%"><tr><td>` layout. Or use `<span>` (which DomPDF does render inline).
- **Prevention:** In DomPDF, `display:inline-block` on `<div>` does not work. Use `<table>` for all side-by-side layouts per D13 pattern.

### PDF-009: `<ol>` / `<ul>` Inside `<td>` Cells — Unreliable Rendering
- **Module/Area:** HPC PDF templates (fourth_pdf Fix 7 — 6 occurrences)
- **Symptom:** List items disappear, bullets/numbers not shown, or items overflow out of the cell
- **Root Cause:** DomPDF has inconsistent `<ol>/<ul>` support when lists are nested inside `<td>` table cells. The list indentation and marker rendering are unreliable.
- **Fix:** Replace `<ol>/<ul>` inside `<td>` with explicit numbered `<div>` pattern: `<div style="...">{{ $idx + 1 }}. {{ $item }}</div>` per item, or a `<table width="100%">` with a number cell and content cell per row.
- **Prevention:** Avoid `<ol>/<ul>` anywhere inside `<table><td>` in DomPDF templates. Use manual numbering with divs or inner tables instead.

### PDF-010: `page-break-inside:avoid` on Containers Taller than One Page
- **Module/Area:** HPC PDF templates (Fix 10 in third_pdf, Fix 9 in fourth_pdf)
- **Symptom:** Page breaks occur in unexpected places despite `page-break-inside:avoid`; large sections get split mid-content
- **Root Cause:** DomPDF honors `page-break-inside:avoid` only if the element fits on the remaining page. If the container is taller than one page height, DomPDF overrides the rule and breaks wherever it can.
- **Fix:** Remove `page-break-inside:avoid` from large section containers (activity domains, section blocks). Use it only on small atomic units (individual rows, small tables). Add `<div style="page-break-inside:avoid;">` wrappers around specific sub-elements (question tables, grid rows) that should not be split.
- **Prevention:** `page-break-inside:avoid` is not absolute in DomPDF. Only apply to containers that fit within a single page. For large sections, structure content into smaller pageable units.

---

## Hpc Specific (deep-audited 2026-03-14, updated 2026-03-14)

### SEC-HPC-001: HpcController — Zero Authorization on 13/15 Methods (CRITICAL) [UPDATED 2026-03-16]
- **Module/Area:** `Modules/Hpc/app/Http/Controllers/HpcController.php` (~2390 lines)
- **Symptom:** Any authenticated user can view any student's HPC form, save evaluations for any student, generate/download any student's PDF report, download ZIP archives. Only `index()` has `Gate::any()`. New `sendReportEmail()` added 2026-03-16 **does have** `Gate::authorize('tenant.hpc.viewAny')`.
- **Affected methods (still missing auth):** `hpcTemplates`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `hpc_form`, `formStore`, `generateReportPdf`, `viewPdfPage`, `generateSingleStudentPdf`, `downloadZip`
- **Methods with auth:** `index()` (Gate::any), `sendReportEmail()` (Gate::authorize) — 2/15 covered
- **Fix:** Add `Gate::authorize('tenant.hpc.view|create|update|delete')` to remaining 13 public methods

### SEC-HPC-002: 10 Controllers Missing Gate on store/update — FormRequest authorize() Returns true
- **Module/Area:** CircularGoalsController, HpcParametersController, HpcPerformanceDescriptorController, KnowledgeGraphValidationController, LearningActivitiesController, LearningOutcomesController, QuestionMappingController, StudentHpcEvaluationController, SyllabusCoverageSnapshotController, TopicEquivalencyController
- **Symptom:** store() and update() have no Gate::authorize(). Controller comments say "Authorization is handled in the request class" — but 7 of 14 FormRequests have hardcoded `return true`. Only HpcParametersRequest, HpcPerformanceDescriptorRequest, LearningActivitiesRequest, LearningOutcomesRequest, StudentHpcEvaluationRequest, TopicEquivalencyRequest have real Gate logic.
- **Fix:** Add Gate::authorize() to store/update in all controllers; also fix the 7 FormRequests that return true (CircularGoalsRequest, HpcTemplatePartsRequest, HpcTemplateRubricsRequest, HpcTemplateSectionsRequest, HpcTemplatesRequest, KnowledgeGraphValidationRequest, QuestionMappingRequest, SyllabusCoverageSnapshotRequest)

### SEC-HPC-003: No EnsureTenantHasModule Middleware on HPC Routes
- **Module/Area:** `routes/tenant.php` line 2498 — HPC route group
- **Symptom:** Any authenticated tenant user can access HPC features even if tenant's plan excludes HPC module
- **Fix:** Add `EnsureTenantHasModule::class.':HPC'` to HPC route group middleware

### SEC-HPC-004: Module web.php/api.php Register Routes Outside Tenancy Middleware
- **Module/Area:** `Modules/Hpc/routes/web.php`, `Modules/Hpc/routes/api.php`
- **Symptom:** `Route::resource('hpcs', HpcController::class)` accessible on central domain, completely bypassing tenancy isolation (no InitializeTenancyByDomain, no PreventAccessFromCentralDomains, no EnsureTenantIsActive)
- **Fix:** Remove or empty these scaffold route files; all HPC routes must be in `routes/tenant.php` only

### BUG-HPC-001: 4 Template Controller Class Imports Missing in tenant.php (UPDATED)
- **Module/Area:** `routes/tenant.php` — HpcTemplatesController, HpcTemplatePartsController, HpcTemplateSectionsController, HpcTemplateRubricsController
- **Symptom:** Routes for `hpc-templates`, `hpc-template-parts`, `hpc-template-sections`, `hpc-template-rubrics` ARE registered (lines 2667-2708) but the controller classes are NOT imported via `use` statements. All routes will 500 (class not found) when accessed.
- **Fix:** Add `use Modules\Hpc\Http\Controllers\{HpcTemplatesController, HpcTemplatePartsController, HpcTemplateSectionsController, HpcTemplateRubricsController};` to tenant.php imports

### BUG-HPC-003: Garbled Permission String in HpcTemplatesController::show()
- **Module/Area:** `Modules/Hpc/app/Http/Controllers/HpcTemplatesController.php` line 97
- **Symptom:** Permission `tenant.hpc-templates.viHpcTemplatesRequest ew` always throws 403
- **Fix:** Correct to `tenant.hpc-templates.view`

### BUG-HPC-004: Global AcademicSession Used in Tenant Controllers (Cross-Layer)
- **Module/Area:** `StudentHpcEvaluationController`, `SyllabusCoverageSnapshotController`, `HpcController`
- **Symptom:** `Modules\Prime\Models\AcademicSession` imported and queried in tenant context — data leaks from global/prime DB. Also `App\Models\User` imported in StudentHpcEvaluationController for assessor dropdown.
- **Fix:** Use `OrganizationAcademicSession` or tenant-side session model; use tenant-scoped staff/employee model instead of central User

### BUG-HPC-005: 3 Routes Point to Non-Existent HpcController Methods
- **Module/Area:** `routes/tenant.php` lines 2508-2510
- **Symptom:** `GET /hpc/hpc-second-form` → `hpcSecondForm`, `GET /hpc/hpc-thred-form` → `hpcThredForm`, `GET /hpc/hpc-four-form` → `hpcFourthForm` — none of these methods exist. All return 500 (BadMethodCallException).
- **Fix:** Either add these methods to HpcController or remove the dead routes

### BUG-HPC-006: HpcTemplates Model Uses Uppercase Class Refs — Breaks on Linux
- **Module/Area:** `Modules/Hpc/app/Models/HpcTemplates.php`
- **Symptom:** Relationships reference `HPCTemplateSections`, `HPCTemplateRubrics`, `HPCTemplateRubricItems` (uppercase HPC) but actual class files use `HpcTemplateSections`, `HpcTemplateRubrics`, `HpcTemplateRubricItems`. Works on macOS (case-insensitive) but **will break on Linux deployment** (case-sensitive filesystem).
- **Fix:** Change all uppercase references to correct case: `HpcTemplateSections`, `HpcTemplateRubrics`, `HpcTemplateRubricItems`

### BUG-HPC-007: StudentHpcSnapshot Imports Wrong Student Model
- **Module/Area:** `Modules/Hpc/app/Models/StudentHpcSnapshot.php`
- **Symptom:** Imports `Modules\SchoolSetup\Models\Student` — SchoolSetup does NOT have a Student model. Should be `Modules\StudentProfile\Models\Student`.
- **Fix:** Change import to `Modules\StudentProfile\Models\Student`

### BUG-HPC-008: Orphan Import in tenant.php — LearningActivityController (Singular)
- **Module/Area:** `routes/tenant.php` line 19
- **Symptom:** `use Modules\Hpc\Http\Controllers\LearningActivityController` — file does not exist (plural `LearningActivitiesController` exists separately). May cause fatal autoload error on route:cache.
- **Fix:** Remove the orphan import line

### BUG-HPC-009: All trash/view Routes Shadowed by Resource show Route
- **Module/Area:** All 10 resource controllers in HPC
- **Symptom:** `GET /hpc/{resource}/trash/view` is registered AFTER `Route::resource()`. The resource `show` route (`GET {resource}/{id}`) matches `trash` as the `{id}` parameter first, making trash routes unreachable.
- **Fix:** Register trash/trashed routes BEFORE `Route::resource()`, or exclude `show` from resource

### BUG-HPC-010: Duplicate Table Name Prefixes on 2 Models
- **Module/Area:** `HpcLevels` (table `hpc_hpc_levels`), `StudentHpcSnapshot` (table `hpc_student_hpc_snapshot`)
- **Symptom:** Redundant `hpc_` in table names. Not a runtime error but violates naming convention.
- **Fix:** Rename tables via additive migration if data exists, or fix directly if empty

### PERF-HPC-001: generateReportPdf() Per-Student Loop Queries
- **Module/Area:** `HpcController::generateReportPdf()`
- **Symptom:** Loops over student IDs loading each student individually; attendance/sibling queries repeat per student without batching. Slow for bulk PDF generation.
- **Fix:** Pre-load all students and attendance data before loop; batch queries

### PERF-HPC-002: 15× Duplicated index() Query Block Across All Controllers
- **Module/Area:** All 15 HPC controllers
- **Symptom:** Every controller's `index()` contains near-identical ~70-line block querying 10+ models to populate the shared tabbed index page. Fires ~15 queries per request for data the active tab may not display.
- **Fix:** Extract shared tab data loading to a service or base controller; lazy-load tab data via AJAX

### BUG-HPC-011: 18/26 Models Missing created_by from $fillable
- **Module/Area:** All HPC models except LearningOutcomes
- **Symptom:** `created_by` column cannot be mass-assigned. Models with `createdBy()` relationship never actually set the FK.
- **Fix:** Add `created_by` to $fillable on all models; set it in controller/service before save

### BUG-HPC-012: LearningOutcomesController Imports Prime\Dropdown (Cross-Layer)
- **Module/Area:** `Modules/Hpc/app/Http/Controllers/LearningOutcomesController.php`
- **Symptom:** `Modules\Prime\Models\Dropdown` imported — Central/Prime model used in tenant context

### BUG-HPC-013: ZIP Files Never Cleaned Up — Storage Bloat (added 2026-03-15)
- **Module/Area:** `HpcController::generateReportPdf()` + `downloadZip()`
- **Symptom:** Each bulk PDF generation creates a ZIP in `storage/app/public/hpc-reports/zip/`. Files are never deleted (`deleteFileAfterSend(false)`). Over time, storage fills up.
- **Fix:** Either use `deleteFileAfterSend(true)` on `downloadZip()`, or add a scheduled job to prune ZIPs older than 24h. Also consider cleaning individual PDFs after ZIP creation.

### BUG-HPC-014: Individual PDF URLs Still Use tenant_asset() (added 2026-03-15)
- **Module/Area:** `HpcController::generateReportPdf()` line 1528
- **Symptom:** `$pdfUrl = tenant_asset("storage/hpc-reports/pdf/{$filename}")` — `tenant_asset()` returns HTTP URLs. While the primary flow now uses ZIP download, the `pdf_urls` array in the JSON response still contains tenant_asset() URLs. These may not resolve correctly in all deployment configs.
- **Fix:** Replace with a route-based download endpoint similar to `downloadZip()`, or remove individual URLs since ZIP is now the primary delivery method.
- **Fix:** Use tenant-side dropdown data or query via `tenancy()->central(fn() => ...)`

### BUG-HPC-015: Permission Typo — `topic-equivalency-snapsho.viewAny` (added 2026-03-16)
- **Module/Area:** `TopicEquivalencyController` or `AppServiceProvider` Gate registration
- **Symptom:** Permission string `topic-equivalency-snapsho.viewAny` is truncated — should be `topic-equivalency-snapshot.viewAny`. Gate always denies.
- **Fix:** Correct permission string to `topic-equivalency-snapshot.viewAny`

### HPC Post-Sprint Status (2026-03-17) — 37 Tasks Completed

**RESOLVED (was OPEN, now FIXED):**
- SEC-HPC-001: ✅ FIXED — All 15 HpcController methods now have Gate::authorize()
- SEC-HPC-002: ✅ FIXED — All 14 FormRequests have Gate::allows() (zero return true)
- SEC-HPC-003: ✅ FIXED — EnsureTenantHasModule::class.':Hpc' on route group
- SEC-HPC-004: ✅ FIXED — Module web.php/api.php emptied (zero Route:: calls)
- BUG-HPC-001: ✅ FIXED — 4 template controller imports added to tenant.php
- BUG-HPC-003: ✅ FIXED — Garbled permission string corrected
- BUG-HPC-004: ✅ FIXED — Cross-layer AcademicSession replaced with OrganizationAcademicSession
- BUG-HPC-005: ✅ FIXED — 3 dead routes removed
- BUG-HPC-006: ✅ FIXED — Case-sensitivity (HPC→Hpc) in HpcTemplates model
- BUG-HPC-007: ✅ FIXED — Wrong Student import (SchoolSetup→StudentProfile)
- BUG-HPC-008: ✅ FIXED — Orphan LearningActivityController import removed
- BUG-HPC-009: ✅ FIXED — All 14 resource trash routes reordered before Route::resource()
- BUG-HPC-010: ✅ FIXED — Table renames: hpc_hpc_levels→hpc_levels, hpc_student_hpc_snapshot→hpc_student_snapshot
- BUG-HPC-011: ✅ FIXED — created_by added to all 32 models
- BUG-HPC-012: ✅ FIXED — Cross-layer Dropdown replaced with DB::table('sys_dropdowns')
- BUG-HPC-013: ✅ FIXED — deleteFileAfterSend(true) on ZIP download
- BUG-HPC-014: ✅ FIXED — tenant_asset() replaced with Storage::disk('public')->url()
- BUG-HPC-015: ✅ FIXED — Permission typo fixed in HpcIndexDataTrait
- PERF-HPC-001: ✅ FIXED — Batch pre-loading in generateReportPdf() (~160 queries → ~5)
- PERF-HPC-002: ✅ FIXED — HpcIndexDataTrait extracts shared query (15 controllers)
- formStore() mass assignment: ✅ FIXED — $request->except() replaces $request->all()

**NEW since last audit:**
- 10 services created (was 2)
- 6 new controllers: StudentHpcFormController, ParentHpcFormController, PeerHpcFormController, HpcAttendanceController, HpcActivityAssessmentController, StudentGoalsController, HpcCreditConfigController
- 6 new models: StudentFormSubmission, ParentFormToken, PeerAssignment, PeerResponse, HpcReportComment, HpcCreditConfig
- 20 new migrations (15 Schema-2 + 5 feature tables)
- 55 Pest tests across 7 files
- Approval workflow: 6-state machine (draft→submitted→under_review→final→published→archived)
- Role-based section locking: owner_role ENUM on rubric items
- Student, Parent, Peer data collection portals

### HPC Incremental Update (2026-03-21)

**Developer changes since 2026-03-17 (~30 commits):**

**Architecture change — SendHpcReportEmail Job rewritten:**
- **Before:** Job generated PDF via HpcReportService::buildPdf(), attached PDF to email, 300s timeout
- **After:** Job sends signed URL link (Crypt::encryptString for student_id), no PDF generation in Job, 120s timeout
- **Impact:** HpcReportService::buildPdf/minifyHtml no longer called from Job. The P2_26 refactor (Job→Service) was superseded by this developer rewrite.
- **Note:** `route('hpc.hpc-form.view')` used for the link — verify this route exists and accepts encrypted student_id param

**PDF blade pages redesigned (all 4 templates):**
- first_pdf page 1: already had clean layout; page 2: hybrid background image approach
- second_pdf page 1: redesigned to formal layout matching PDF; page 2: hybrid background image
- third_pdf page 1: redesigned to formal layout; page 2: redesigned with 4-section layout
- fourth_pdf page 1: redesigned + all subsequent pages had significant DomPDF fixes (~4661 line changes)

**Seeder fixes (HPCTemplateSeeder):**
- seedPage1Second, seedPage1Third, seedPage1Fourth: all 6 rubric grouping fixes applied (UDISE+Teacher combined, Student Name split, Mother/Father split, Rural/Urban split)
- Grade checkboxes now explicit ri() calls (not foreach loop) for templates 2/3/4

**Student-list view changes:**
- "Generate Report" button now triggers bulk email (not PDF generation)
- Individual download button removed
- Button icon changed from PDF to envelope

**No new issues introduced.** All auth/validation checks remain intact.

## Recommendation Specific (deep-audited 2026-03-14)

### SEC-REC-001: Wrong Gate Permission on 8/9 StudentRecommendation Write Routes
- **Module/Area:** `Modules/Recommendation/app/Http/Controllers/StudentRecommendationController.php`
- **Symptom:** All destructive actions use `tenant.student-recommendation.create` instead of matching permission
- **Fix:** Use correct permission per action (view, update, delete, restore, forceDelete)

### BUG-REC-001: Broken Validation — `exists:users` Should Be `exists:sys_users`
- **Module/Area:** `StudentRecommendationController::update()` lines 154, 169
- **Symptom:** Update always throws validation error — `users` table doesn't exist in tenant DB
- **Fix:** Change to `exists:sys_users,id`

### BUG-REC-002: Table Name Mismatch in complexity_level Validation
- **Module/Area:** `RecommendationMaterialController` store vs update
- **Symptom:** One of `slb_complexity_levels` (store) vs `slb_complexity_level` (update) will throw
- **Fix:** Verify actual table name in DDL, standardize both

---

## Critical Production Bugs (from Engineering Audit 2026-03-12)

### BUG-002: Policy Overwriting — Authorization Silently Broken for Multiple Models
- **Module/Area:** `app/Providers/AppServiceProvider.php`
- **Symptom:** QuestionBank, Vehicle, Section CRUD operations bypass authorization — wrong policy enforced
- **Root Cause:** `Gate::policy()` called multiple times for same model — only LAST registration wins. `QuestionBank::class` registered 3 times, `Vehicle::class` registered 5 times.
- **Fix:** Audit AppServiceProvider for duplicate `Gate::policy()` calls and remove duplicates. Copy-paste errors: `BookAuthors::class` mapped to `CircularGoalsPolicy`, `BokBook::class` mapped to `HpcParametersPolicy`.
- **Prevention:** Each model class should appear exactly once in Gate::policy() registration.

### BUG-004: Tenant Migration Pipeline Commented Out
- **Module/Area:** `app/Providers/TenancyServiceProvider.php`
- **Symptom:** New tenants created with empty database — no tables, no root user, onboarding broken
- **Root Cause:** `MigrateDatabase`, `CreateRootUser`, `AddOrganizationDetails`, `SeedDatabase` all commented out in TenantCreated event
- **Fix:** Uncomment at minimum `MigrateDatabase` and `CreateRootUser`
- **Prevention:** Never comment out the migration pipeline without explicit rollback plan.

### SEC-004: Payment Webhook Behind Auth Middleware — Razorpay Always Fails
- **Module/Area:** `routes/tenant.php` line 295, Payment module
- **Symptom:** All Razorpay payment callbacks fail with 401/redirect — invoices never marked as paid
- **Root Cause:** Webhook route inside `auth` + `verified` middleware group. Server-to-server webhooks cannot authenticate as Laravel users.
- **Fix:** Move `Route::post('/payment/webhook/{gateway}', ...)` OUTSIDE the auth middleware group. Signature verification in the controller is sufficient protection.
- **Prevention:** Webhook routes must ALWAYS be unauthenticated (protected by signature verification, not session auth).

### SEC-011: env() in Route File Breaks After Config Cache
- **Module/Area:** `routes/web.php` line 62
- **Symptom:** After running `php artisan config:cache`, ALL central admin routes stop working (domain group fails to register)
- **Root Cause:** `Route::domain(env('APP_DOMAIN'))` — `env()` returns null after config caching
- **Fix:** Change to `config('app.domain')` and ensure APP_DOMAIN is mapped in `config/app.php`
- **Prevention:** Never use `env()` outside config files. This breaks all routes after production config cache.

### SEC-002: is_super_admin in User $fillable — Privilege Escalation Risk
- **Module/Area:** `app/Models/User.php`
- **Symptom:** Any controller using `$request->all()` could allow a user to set `is_super_admin=1`
- **Root Cause:** `is_super_admin`, `super_admin_flag`, `remember_token` included in `$fillable`
- **Fix:** Remove these sensitive fields from `$fillable`; set via explicit assignment only
- **Prevention:** Audit `$fillable` arrays — privilege-related fields should never be mass-assignable.

### PERF-001: Zero Application-Level Caching
- **Module/Area:** All controllers system-wide
- **Symptom:** Slow page loads; dropdown data (queried 16+ times per request in ComplaintController), settings, academic sessions all re-queried from DB on every request
- **Root Cause:** No `Cache::remember()` calls anywhere in controllers or services
- **Fix:** Cache dropdowns (1h TTL), academic sessions, room types, settings, study formats. Use `Cache::remember('key_'.tenancy()->tenant->id, 3600, fn() => ...)`
- **Prevention:** Any reference data that changes rarely should be cached. Always prefix cache keys with tenant ID.

---

## SmartTimetable — Parallel Periods

### FETSolver: Parallel Non-Anchor Must Be Skipped, Not Blocked
- **Module/Area:** SmartTimetable / FETSolver parallel period logic
- **Symptom:** Non-anchor activities fail to place because their anchor hasn't been placed yet in the ordering
- **Root Cause:** `orderActivitiesByDifficulty()` boosts all parallel members before non-parallel activities, but within a group, non-anchors may appear before the anchor's current weekly instance
- **Fix:** In `backtrack()`, when a non-anchor member is encountered and its anchor has NOT yet been placed in context, skip it with `return $this->backtrack($activities, $index + 1, $solution, $context)` — do NOT return false. The anchor's placement logic will handle placing siblings.
- **Prevention:** Always check `findActivitySlotInContext($anchorId, $context)` before attempting to force-place a non-anchor sibling.

### FETSolver: Sibling classKey Must Come From Sibling Activity, Not Anchor
- **Module/Area:** SmartTimetable / FETSolver `placeParallelGroup` equivalent logic
- **Symptom:** Sibling placed in wrong class slot (overwriting a different class's timetable)
- **Root Cause:** Using anchor's `classKey` for all siblings instead of each sibling's own `getClassKey()`
- **Fix:** Always call `$this->getClassKey($siblingInstance)` to get the sibling's own class-section key before constructing the `Slot`.

---

## SmartTimetable — Post-P01–P21 Audit (2026-03-17)

> 15 commits since 2026-03-15. All 21 execution prompts (P01–P21) implemented by Tarun.
> 150 files changed, 11,556 insertions. 4 new controllers, 4 new services, 77+ constraint classes, 212 seeded constraint types, 10 views, API routes, SoftDeletes on 40+ models.

### BUG-TT-001: TimetableApiController — Zero Gate Authorization on All 6 Methods (CRITICAL)
- **Module/Area:** `Modules/SmartTimetable/app/Http/Controllers/Api/TimetableApiController.php`
- **Symptom:** Any authenticated API user (including students) can view any timetable, trigger generation, and poll run status. `auth:sanctum` only confirms valid token, no permission check.
- **Affected methods:** `show`, `byClass`, `byTeacher`, `byRoom`, `generate`, `status`
- **Fix:** Add `Gate::authorize()` to each method (`smart-timetable.timetable.view` for reads, `smart-timetable.timetable.generate` for generate).

### SEC-TT-001: Cross-Tenant Data Leakage in TimetableApiController
- **Module/Area:** `TimetableApiController` — `show()`, `byClass()`, `byTeacher()`, `byRoom()`, `status()`
- **Symptom:** `Timetable::findOrFail($id)` and `GenerationRun::findOrFail($runId)` fetch by raw ID with no tenant scope. If models lack global tenant scope, Tenant A can read Tenant B's timetable.
- **Fix:** Verify models have tenant global scope. If not, add explicit `where('tenant_id', tenant()->id)`.

### SEC-TT-002: No EnsureTenantHasModule on Any SmartTimetable Route
- **Module/Area:** `routes/tenant.php` line 1771, `Modules/SmartTimetable/routes/web.php`, `routes/api.php`
- **Symptom:** Any authenticated tenant user can access SmartTimetable features even without module license.
- **Fix:** Add `module:SMART_TIMETABLE` middleware to all route groups.

### SEC-TT-003: SmartTimetableController store()/update() Are No-Op Stubs on Live POST Routes
- **Module/Area:** `SmartTimetableController.php` lines 912–915, 940
- **Symptom:** `POST /smart-timetable/smart-timetable-management` passes Gate auth then returns empty 200.
- **Fix:** Either `abort(501)` in stubs or exclude from resource registration.

### BUG-TT-002: FETConstraintBridge Passes Bare Context — All DB Constraints Silently Pass (CRITICAL)
- **Module/Area:** `app/Services/Generator/FETConstraintBridge.php` lines 43–46
- **Symptom:** Context is `(object)['occupied' => []]` — missing `teacherOccupied`, `periods`, `days`, `activitiesById`. All teacher/class constraints null-coalesce to `[]` and return `true`. Bridge provides zero real enforcement.
- **Fix:** Bridge must receive the live generation context from `FETSolver::createConstraintContext()` or reconstruct it from `TimetableSolution`.

### BUG-TT-003: Gap/Span Constraints Mix period_id with period_index — Wrong Calculations (CRITICAL)
- **Module/Area:** `TeacherMaxGapsPerDayConstraint`, `TeacherMaxSpanPerDayConstraint`, `TeacherMaxGapsPerWeekConstraint`, `ClassMaxContinuousConstraint`, `ClassMaxSpanConstraint`
- **Symptom:** `$context->teacherOccupied[$tid][$dayId]` is keyed by period_id (e.g. 100, 101). Constraints append `$slot->startIndex` (0–9) and sort the combined array. Gap/span counts wildly wrong.
- **Fix:** Store period_index (not period_id) as the key, or build a `periodId → periodIndex` lookup from `$context->periods`.

### BUG-TT-004: SubstitutionService `now()->parse($date)` Throws BadMethodCallException
- **Module/Area:** `app/Services/SubstitutionService.php` line 32 and others
- **Symptom:** `now()->parse()` is not a valid Carbon method. All substitution workflows crash immediately.
- **Fix:** Replace with `\Carbon\Carbon::parse($date)`.

### BUG-TT-005: SubstitutionService Queries Have No timetable_id Scope
- **Module/Area:** `SubstitutionService.php` — `reportAbsence()`, `findSubstitutes()`, `autoAssign()`, `getDashboard()`
- **Symptom:** `TimetableCell::where('is_active', true)` queries match cells across ALL timetables in tenant (drafts, archived, current).
- **Fix:** Accept `$timetableId` parameter and add `->where('timetable_id', $timetableId)` to every query.

### BUG-TT-006: GenerateTimetableJob — No Tenant Context Initialization
- **Module/Area:** `app/Jobs/GenerateTimetableJob.php`
- **Symptom:** If queue worker runs in central context, all tenant model queries hit wrong DB. Generation silently fails or corrupts data.
- **Fix:** Add `tenancy()->initialize($tenant)` in `handle()`. Serialize tenant ID in constructor.

### BUG-TT-007: ConstraintManager Cache Key Missing Teacher State — Stale Results
- **Module/Area:** `app/Services/Constraints/ConstraintManager.php` line 244
- **Symptom:** Cache key is `"{type}-{classKey}-{dayId}-{startIndex}-{activityId}"`. Does not include `teacherOccupied` state. Same slot+activity cached as `true` (teacher free) then returned stale after teacher is occupied.
- **Fix:** Clear cache after every placement, or make caching opt-in for stateless constraints only.

### BUG-TT-008: ConstraintEvaluator Calls Instance Method as Static
- **Module/Area:** `app/Services/Constraints/ConstraintEvaluator.php` line 99
- **Symptom:** `ConstraintFactory::createFromDatabase($m->constraint)` — but `createFromDatabase()` is an instance method. Will throw `BadMethodCallException` when group evaluation triggers.
- **Fix:** Make `createFromDatabase()` static or inject `ConstraintFactory` instance.

### BUG-TT-009: FETSolver::getClassKeyForActivityId Accesses Unset Property — Inter-Activity Checks Pass
- **Module/Area:** `app/Services/Generator/FETSolver.php` line 349
- **Symptom:** `$this->activities` is never set (local var in `solve()`). Always `null`, so `$this->activities ?? []` = `[]`. All inter-activity constraints (SAME_TIME, SAME_DAY, NOT_OVERLAPPING) silently pass.
- **Fix:** Store activities as `$this->activitiesById` map in `solve()` before generation loop.

### BUG-TT-010: GenericSoftConstraint::buildActivityContext Is a Stub
- **Module/Area:** `app/Services/Constraints/Soft/GenericSoftConstraint.php` lines 67–73
- **Symptom:** Returns only `['ACTIVITY' => [$activity->id]]` — missing TEACHER/CLASS/SECTION keys. All target-type filtering falls through to GLOBAL. Every soft constraint applies to every activity.
- **Fix:** Copy full `buildActivityContext()` from `GenericHardConstraint` or extract to shared trait.

### BUG-TT-011: SubstitutionService $candidates Scoping Bug
- **Module/Area:** `SubstitutionService.php` line 57
- **Symptom:** `$candidates` defined inside `foreach` loop. If multiple cells, `$candidates` holds only last iteration's value. `recommendations_generated` count is wrong.
- **Fix:** Track running total inside loop.

### BUG-TT-012: SubstitutionService Department Scoring Always Applies
- **Module/Area:** `SubstitutionService.php` lines 136–140
- **Symptom:** Awards 10 points for "Department match" but only checks `$teacher->department_id` is truthy — never compares to cell's activity department. Every teacher with any department gets the bonus.
- **Fix:** Compare `$teacher->department_id` with the activity's owning department.

### PERF-TT-001: SubstitutionService — Teacher::all() Unbounded + N+1 on Capabilities
- **Module/Area:** `SubstitutionService.php` line 72, lines 113–118
- **Symptom:** Fetches ALL active teachers. Then `$teacher->capabilities` triggers lazy load per teacher (classic N+1).
- **Fix:** Add `'capabilities'` to `with()` call. Scope by subject if known.

### PERF-TT-002: AnalyticsController — 3 Uncached Service Calls Per Page Load
- **Module/Area:** `AnalyticsController::index()` lines 27–31
- **Symptom:** `getWorkloadReport()`, `getUtilizationReport()`, `getViolationReport()` run on every page load with no caching.
- **Fix:** Cache each result by `timetable_id` with 5-min TTL.

### PERF-TT-003: AnalyticsService — Missing teachers.user Eager Load (N+1)
- **Module/Area:** `AnalyticsService::getConflictReport()` line 183
- **Symptom:** Eager loads `['teachers', 'activity']` but accesses `$teacher->user->name` in loop — one query per teacher per cell.
- **Fix:** Change to `->with(['teachers.user', 'activity'])`.

### CODE-TT-001: Legacy HardConstraint/SoftConstraint Interfaces Orphaned
- **Module/Area:** `Constraints/Hard/HardConstraint.php`, `Constraints/Soft/SoftConstraint.php`
- **Symptom:** Old interfaces with different signatures. No constraint implements them (all use `TimetableConstraint`). Confusing for developers — could cause fatal if implemented.
- **Fix:** Delete both files or add `@deprecated` docblocks.

### CODE-TT-002: ConstraintManager and ConstraintEvaluator Duplicate Functionality
- **Module/Area:** Both provide `checkHard/checkHardConstraints`, `scoreSoft/evaluateSoftConstraints`, `getViolations`
- **Symptom:** `FETSolver` uses `ConstraintManager`. `ConstraintEvaluator` (with group evaluation logic) is never called during generation.
- **Fix:** Unify into single engine. Move `evaluateGroups()` into `ConstraintManager` or delete `ConstraintEvaluator`.

### CODE-TT-003: Dead Faker Import in SmartTimetableController
- **Module/Area:** `SmartTimetableController.php` line 8
- **Fix:** Remove `use Faker\Factory as Faker;`.

---

## SmartTimetable Constraint System
- **Module/Area:** SmartTimetable / Constraint models
- **Symptom:** Any query on `ConstraintCategory` or `ConstraintScope` throws "Table tt_constraint_categories doesn't exist" or "tt_constraint_scopes doesn't exist"
- **Root Cause:** Models declared separate tables but the migration created a single shared table `tt_constraint_category_scope` with a `type` ENUM('CATEGORY','SCOPE')
- **Fix (2026-03-12):** Both models updated to use `tt_constraint_category_scope` with `addGlobalScope` filtering by `type`. Use `ConstraintCategoryScope` for direct access to the combined table.
- **Prevention:** When a migration creates a combined/polymorphic table, update ALL models that reference it before writing queries. Always cross-check `$table` against actual migration file.

### Constraint Model Column Names Differ from DB Columns
- **Module/Area:** SmartTimetable / `Constraint` model vs `tt_constraints` migration
- **Symptom:** Mass assignment silently fails; queries return null for date fields; `scopeForTerm()` queries wrong column
- **Root Cause:** Model was written with different names than the migration: `academic_term_id` vs `academic_session_id`, `effective_from_date` vs `effective_from`, `effective_to_date` vs `effective_to`, `applicable_days_json` vs `applies_to_days_json`, `target_type_id` vs `target_type`
- **Fix (2026-03-12):** Model fillable/casts/scopes all updated to use actual DB column names. Alias columns added via migration 2026_03_12_100002 for backward compat.
- **Prevention:** Always verify `$fillable` against the actual migration before writing new constraints. Use `php artisan db:show --table=tt_constraints` to inspect live columns.

### ConstraintType Model References Columns That Didn't Exist Yet
- **Module/Area:** SmartTimetable / `ConstraintType` model vs `tt_constraint_types` migration
- **Symptom:** Queries using `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `scopeHardCapable()`, `scopeSoftCapable()` fail with "Unknown column" error
- **Root Cause:** Model was written ahead of migrations — `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `applicable_target_types`, `constraint_level` not in original migration
- **Fix (2026-03-12):** Migration `2026_03_12_100001` adds all missing columns additively. Old `is_hard_constraint`/`param_schema` kept for rollback safety.
- **Prevention:** Run `php artisan tenants:migrate` after any model column addition before using those columns in queries.
- **Prevention:** In parallel group logic, each activity gets its own `Slot` with its own `classKey`; only `dayId` and `startIndex` are shared from the anchor.

---

## Deep Audit — "100% Complete" Modules (audited 2026-03-15 against `prime_ai_shailesh` / `Brijesh_HPC`)

> All modules previously marked 100% were deep-audited. **None** are truly 100%.
> Total new issues found: **200+** across 15 modules.
> Issue codes: SEC (security), BUG (bug), PERF (performance), QUAL (code quality), TEN (tenancy)

### CRITICAL — Platform-Wide (affects ALL modules)

- **SEC-PLATFORM-001:** Only 1 `EnsureTenantHasModule` usage in entire 2715-line tenant.php. ALL tenant modules are accessible without subscription.
- **SEC-PLATFORM-002:** `env('APP_DOMAIN')` in `routes/web.php:62` — ALL central routes 404 after `config:cache`.
- **SEC-PLATFORM-003:** Central route groups duplicated 2-3 times in `routes/web.php` — double registrations.
- **SEC-PLATFORM-004:** `is_super_admin` in `$fillable` on BOTH User models (`app/Models/User.php` + `Modules/Prime/app/Models/User.php`) — privilege escalation via any user update form.
- **SEC-PLATFORM-005:** `$request->all()` used instead of `$request->validated()` in 20+ controllers despite having FormRequests — mass assignment bypass.
- **SEC-PLATFORM-006:** Route names hardcoded as `central-127.0.0.1.*` — breaks on any non-localhost deployment.

### CRITICAL — Secret Leaks

- **SEC-QNS-002:** OpenAI + Gemini API keys hardcoded in `QuestionBank/AIQuestionGeneratorController.php:54-57` — REVOKE IMMEDIATELY.
- **SEC-PAY-001:** Razorpay test keys hardcoded in `Payment/PaymentController copy.php:28-29` — revoke + delete file.

### SchoolSetup (was 100% → revised to ~80%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-SCH-008 | CRITICAL | `UserController::update()` allows setting `is_super_admin` via request |
| SEC-SCH-005 | HIGH | `RolePermissionController::destroy()` doesn't actually delete — calls `save()` instead |
| SEC-SCH-006 | HIGH | `RoomTypeController::destroy()` typo `'tennat.room-type.delete'` — Gate always denies |
| BUG-SCH-001 | HIGH | `SectionController::index()` PHP concat bug: `'teachers' . 'classSections'` → crash |
| BUG-SCH-010 | HIGH | Route `teacher/assign-subjects/{user_id}` → `assignSubjects()` method doesn't exist |
| SEC-SCH-016 | HIGH | `OrganizationAcademicSessionController` — 6 empty stubs + 3 methods no auth |
| BUG-SCH-004-007 | MED | 5 stub controllers: SchoolSetupController, ClassSubjectManagement, InfrasetupController, OrganizationAcademicSession, UserRolePrm |
| SEC-SCH-009-017 | MED | 15+ unprotected methods across SubjectClassMapping, SubjectGroup, EmployeeProfile, etc. |
| PERF-SCH-002 | MED | `SchoolClassController::index()` fires 9+ paginated queries in one request |
| QUAL-SCH-005 | MED | Inconsistent permission naming: `school-setup.*` vs `tenant.*` vs `prime.*` vs `schoolsetup.*` |

### Transport (was 100% → revised to ~82%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-TPT-002-004 | CRITICAL | `FeeMasterController`, `FeeCollectionController`, `TptStudentFineDetailController` — ZERO auth on ALL methods |
| SEC-TPT-010 | CRITICAL | `AttendanceDeviceController` — ALL Gate calls use `'tested.*'` instead of `'tenant.*'` — completely broken |
| BUG-TPT-001 | HIGH | `TptDailyVehicleInspectionController::updateStatus()` — `$request` undefined → runtime crash |
| BUG-TPT-002 | HIGH | `TripController::destroy()` — double-delete race condition, stop details never cleaned |
| BUG-TPT-003 | HIGH | `TripMgmtController::tripStopNew()/tripBordUnbord()` — undefined `$q` variable |
| BUG-TPT-004-005 | MED | `TripController::index()` and `LiveTripController::index()` — empty, return nothing |
| BUG-TPT-006-007 | MED | Wrong permission strings: `transport.trip.create` (missing tenant.), `tenant.routescheduler.create` (missing _) |
| BUG-TPT-009 | MED | `DriverRouteVehicleController::store()` — 10-year loop generating 7300+ queries |
| BUG-TPT-010 | MED | `TripMgmtController::tripStopTimeline()` — writes to DB on GET request |
| SEC-TPT-021 | MED | Central `AcademicSession` queried without `tenancy()->central()` |
| QUAL-TPT-001-005 | LOW | 5 controllers with stub CRUD methods |

### Notification (was 100% → revised to ~55%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-NTF-006 | CRITICAL | ALL routes commented out in web.php — module completely inaccessible via web |
| SEC-NTF-002-003 | HIGH | `$request->all()` in TemplateController store/update — mass assignment bypass |
| BUG-NTF-004-005 | MED | Stub target types and users — empty arrays passed to views |
| BUG-NTF-006 | MED | Duplicate `$threads` assignment overwrites paginated data |
| PERF-NTF-001 | MED | Same 5-8 queries duplicated across 7 controllers' `index()` methods |

### Complaint (was 100% → revised to ~70%)

| Code | Severity | Issue |
|------|----------|-------|
| BUG-CMP-001 | CRITICAL | `dd($e->getMessage())` in `ComplaintController::store()` catch — exposes stack traces |
| BUG-CMP-002 | CRITICAL | `dd('FILTER HIT', request()->all())` in `filter()` — method completely broken |
| BUG-CMP-003 | HIGH | 3 fully stub controllers: ComplaintAction, ComplaintDashboard, AiInsight |
| SEC-CMP-001-003 | HIGH | `show()`, `edit()`, `store()`, `update()` have no authorization |
| SEC-CMP-006 | HIGH | `ComplaintReportController` — zero auth on all methods |
| BUG-CMP-005 | MED | `MedicalCheckController::create()` uses placeholder dropdown keys — empty forms |

### Vendor (was 100% → revised to ~60%)

| Code | Severity | Issue |
|------|----------|-------|
| BUG-VND-001 | CRITICAL | 6 of 7 controllers NOT registered in web.php — unreachable code |
| SEC-VND-001 | CRITICAL | `VendorController::index()` auth commented out — all vendor data exposed |
| SEC-VND-002 | CRITICAL | `VendorInvoiceController` — ZERO auth on ALL 14 methods (including invoice gen, bulk email) |
| SEC-VND-003 | HIGH | `VendorInvoiceController::store()` — zero input validation on financial operations |

### Payment (was 100% → revised to ~45%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-PAY-001 | CRITICAL | Hardcoded Razorpay keys in `PaymentController copy.php` — credential leak |
| SEC-PAY-004 | HIGH | Webhook stores raw payload BEFORE signature verification |
| SEC-PAY-008 | HIGH | Webhook behind `auth:sanctum` — Razorpay callbacks always fail 401 |
| SEC-PAY-005-006 | HIGH | `PaymentGatewayController` + `PaymentCallbackController` — empty stubs, zero auth |
| BUG-PAY-001 | HIGH | Duplicate `PaymentController copy.php` with class name collision |

### Syllabus (was 100% → revised to ~78%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-SYL-001 | CRITICAL | `CompetencieController` — ZERO auth on all 8 methods |
| SEC-SYL-002 | CRITICAL | `$request->all()` mass assignment in CompetencieController store/update |
| SEC-SYL-003 | CRITICAL | `TopicController` — ZERO auth on all 14 methods |
| BUG-SYL-001 | HIGH | `SyllabusController` is a fully empty stub — routes broken |
| BUG-SYL-002 | MED | `TopicController::destroy()` uses forceDelete instead of soft delete |
| PERF-SYL-001 | MED | `LessonController::index()` fires 10+ unbounded queries, `Competencie::all()` called twice |

### SyllabusBooks (was 100% → revised to ~65%)

| Code | Severity | Issue |
|------|----------|-------|
| BUG-BOK-001 | HIGH | `SyllabusBooksController` — fully empty stub, routes broken |
| SEC-BOK-004 | HIGH | `BookTopicMappingController` — ZERO auth on all 9 methods |
| BUG-BOK-002 | HIGH | `BookTopicMappingController::index()` — undefined `$bookTopicMappings` → crash |
| TEN-BOK-001 | MED | Central `AcademicSession` queried without tenant context in 8 locations |

### QuestionBank (was 100% → revised to ~75%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-QNS-002 | CRITICAL | OpenAI + Gemini API keys hardcoded in source — REVOKE IMMEDIATELY |
| SEC-QNS-001 | HIGH | `AIQuestionGeneratorController` — ZERO auth on all methods |
| BUG-QNS-001 | HIGH | `generateQuestions()` always returns demo data — real AI integration unreachable (dead code after early return) |

### StudentProfile (was 100% → revised to ~80%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-STD-001 | CRITICAL | `createStudentLogin()` allows setting `is_super_admin` — privilege escalation |
| SEC-STD-002 | HIGH | `AttendanceController` — ZERO auth on all methods |
| SEC-STD-004 | HIGH | `StudentProfileController` — fully empty stub |
| SEC-STD-003 | MED | `StudentReportController::index()` — no auth |

### Prime (was 100% → revised to ~80%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-PRM-002 | CRITICAL | `is_super_admin` in `$fillable` + explicitly included in `UserController::update()` `$request->only()` |
| SEC-PRM-003 | HIGH | `$request->all()` in 5 controllers despite FormRequests (Tenant, TenantGroup, Board, AcademicSession, Menu) |
| SEC-PRM-004 | HIGH | Wrong permission on `TenantController@edit` — uses `tenant-group.update` instead of `tenant.update` |
| SEC-PRM-007 | HIGH | `RolePermissionController::destroy()` calls `save()` not `delete()` — role never removed |
| BUG-PRM-002-011 | MED | 8 controllers with stub methods (Tenant, TenantManagement, SalesPlan, UserRolePrm, SessionBoard, ActivityLog, Menu, Setting) |
| BUG-PRM-012 | MED | `AcademicSessionController::destroy()` — deletion condition logically inverted |

### GlobalMaster (was 100% → revised to ~82%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-GLB-001 | HIGH | `$request->all()` in 4 controllers despite FormRequests |
| SEC-GLB-002 | HIGH | `GlobalMasterController` — ZERO auth on all 7 stub methods |
| BUG-PRM-014 | MED | `ModuleController::show()` uses wrong permission (`create` instead of `view`) |

### Billing (was 100% → revised to ~70%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-BIL-001 | HIGH | `BillingManagementController::store()` — no auth on invoice generation |
| SEC-BIL-002 | HIGH | `toggleStatus()` — no auth on payment reconciliation |
| SEC-BIL-005 | HIGH | `Tenancy::initialize()` without try/finally — cross-tenant context leak risk |
| BUG-BIL-001-004 | MED | 4 controllers with stub CRUD methods |
| BUG-BIL-005 | MED | `printData()` calls `->isNotEmpty()` on a float — runtime crash |

### SystemConfig (was 100% → revised to ~75%)

| Code | Severity | Issue |
|------|----------|-------|
| SEC-SYS-001 | HIGH | MenuController — 5 methods (trashedMenu, restore, forceDelete, destroy, toggleStatus) have ZERO auth |
| BUG-SYS-001 | MED | `create()` is empty stub |

---

## Deep Audit — 2026-04-02 (8-agent parallel scan, all 37 modules)

> This section captures NEW findings not already documented above.
> Priority: P0 = production-fatal or data-leak, P1 = security/auth bypass, P2 = performance/validation, P3 = dead code/cleanup.
> Verified against `prime_ai` repo, branch current. Route/policy issues updated 2026-04-02 post-migration (see D22) — now verified against `prime_ai_shailesh`.

### P0 — FATAL / PRODUCTION-BREAKING

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-RTG-001 | Routing | **14 seeder routes with NO auth at all** — any unauthenticated visitor can wipe and reseed entire tenant DB | `tenant.php:207–224` (post-migration; line numbers updated 2026-04-02) |
| SEC-RTG-004 | Routing | ~~StandardTimetableController imported but file doesn't exist~~ | ✅ **RESOLVED 2026-04-02** — `use` statement commented out in post-migration tenant.php; routes → module web.php |
| SEC-RTG-005 | Routing | ~~7 HPC controllers used in routes without `use` imports~~ | ✅ **RESOLVED 2026-04-02** — HPC routes moved to `Modules/Hpc/routes/web.php` which has proper imports |
| BUG-PAY-001 | Payment | **Webhook behind auth middleware** — all Razorpay/PayU callbacks return 401, payments never reconcile | `tenant.php:327` |
| BUG-CMP-001 | Complaint | **4 routes point to non-existent ComplaintController methods** (trashed/restore/forceDelete/toggleStatus) → 500 | `tenant.php:1279–1295` |
| BUG-CMP-002 | Complaint | **2 routes point to non-existent ComplaintActionController methods** (restore/forceDelete) → 500 | `tenant.php:1312–1318` |
| BUG-VND-002 | Vendor | **VendorPaymentController missing create/store/show** — 3 resource routes → 500 | `VendorPaymentController.php` |
| BUG-TT-004 | SmartTimetable | **generateForClassSection method missing** — route → 500 | `tenant.php:1899` |
| BUG-TT-005 | TimetableFoundation | **generateAllActivities + getBatchGenerationProgress missing** — 2 routes → 500 | `TF/routes/web.php:88–89` |
| BUG-EXM-TOGGLE | LmsExam | **ExamStudentGroupMemberController::toggleStatus() missing** — route → 500 | `LmsExam/routes/web.php:112` |
| BUG-QST-TOPICS | LmsQuests | **QuestScopeController::getTopics() missing** — quest scope UI topic dropdown broken | `LmsQuests/routes/web.php:22` |
| BUG-SCH-ROUTES | SchoolSetup | **3 missing methods**: trashedClassSubgroup, assignSubjects, StudyFormatController methods | `SchoolSetup/routes/web.php` |
| BUG-TT-006 | SmartTimetable | **SubstitutionService::reportAbsence — $candidates undefined** when teacher has no cells → crash | `SubstitutionService.php:57` |
| BUG-TT-007 | SmartTimetable | **now()->parse($date) wrong API** — silently returns today's date instead of actual date | `SubstitutionService.php:32,67,206,289` |

### P0 — DATA LEAK / PRIVILEGE ESCALATION

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-STP-003 | StudentPortal | **IDOR in proceedPayment()** — payable_id accepted raw, any student pays another's invoice | `StudentPortalController.php:285–308` |
| SEC-SCH-001 | SchoolSetup | **is_super_admin writable via UserController update** — admin can promote any user | `UserController.php:136` |
| SEC-STP-001 | StudentProfile | **is_super_admin writable in student login creation** | `StudentController.php:391,412` |
| SEC-PRM-001 | Prime | **is_super_admin + remember_token in User $fillable** — mass-assignable | `app/Models/User.php:48,53` |
| SEC-PRM-007 | Prime | **UserController::update() explicitly passes is_super_admin** | `UserController.php:144` |
| SEC-NOT-005 | Notification | **Tenant::all() inside tenant context** — cross-tenant data leak | `TemplateController.php:382,445` |
| SEC-SYS-010 | SystemConfig | **MenuSyncController::sync() auth check commented out** — any user truncates all tenant menus | `MenuSyncController.php:57–63` |
| SEC-RTG-003 | Routing | **HPC PDF view page accessible without auth** — student data exposed | `tenant.php:2530–2532` |
| SEC-STP-006 | StudentPortal | **User::get() exposes full user roster** in complaint form | `StudentPortalComplaintController.php:35` |
| SEC-PAY-005 | Payment | **payable_type accepts arbitrary class name** — no allowlist validation | `PaymentController.php:47` |

### P1 — SECURITY / AUTH BYPASS

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| TEN-RTG-001 | ALL | **EnsureTenantHasModule applied to only 1 of 26 module groups** — any tenant accesses Enterprise features | `tenant.php` |
| SEC-NOT-003 | Notification | **ALL tenant controllers use `prime.*` Gate prefix** — all checks return 403 for tenants | All Notification controllers |
| SEC-REC-001 | Recommendation | **Gate::any() without `\|\| abort(403)`** — auth checks don't block access | `RecommendationController.php:25,50` |
| SEC-REC-002 | Recommendation | **StudentRecommendationController uses `.create` permission for delete/restore/forceDelete** | `StudentRecommendationController.php:200–330` |
| SEC-BIL-001 | Billing | **No try/catch on DB transaction in payment processing** — failure corrupts invoice state | `InvoicingPaymentController.php:52–105` |
| SEC-BIL-002 | Billing | **Same: consolidatedStore() no try/catch** — partial payment corruption | `InvoicingPaymentController.php:158–253` |
| SEC-TPT-003 | Transport | **`tested.*` permission typo** — AttendanceDeviceController completely inaccessible | All methods except update() |
| SEC-TPT-004 | Transport | **updateLastSeen() has no auth at all** — publicly accessible | `AttendanceDeviceController.php:261` |
| SEC-TPT-005 | Transport | **Driver Aadhaar/PAN stored plaintext** — India IT Act violation | `DriverHelper model $fillable:['id_no']` |
| SEC-STP-002 | StudentProfile | **Gate facade not imported in AttendanceController** — all Gate calls throw fatal | `AttendanceController.php` |
| SEC-EVT-002 | EventEngine | **No tenancy middleware in RSP** — runs on wrong database | `EventEngine/RSP.php` |
| SEC-SCH-003 | Scheduler | **No tenancy middleware in RSP** — runs on wrong database | `Scheduler/RSP.php` |
| SEC-TT-002 | SmartTimetable | **ParallelGroupController routes bypass tenancy stack** | `SmartTimetable/RSP.php:38` |
| SEC-DSH-002 | Dashboard | **Zero authorization on entire controller** — any user sees all school data | `DashboardController.php` |
| SEC-BOK-001 | SyllabusBooks | **Only routed controller has zero auth** — SyllabusBooksController | `SyllabusBooksController.php` |
| SEC-BOK-004 | SyllabusBooks | **Cross-layer: BookController queries Prime\AcademicSession from tenant context** | `BookController.php:20` |
| SEC-QB-001 | QuestionBank | **AIQuestionGeneratorController — zero authorization on entire controller** | `AIQuestionGeneratorController.php` |
| SEC-GLB-005 | GlobalMaster | **LanguageController uses `global-master.*` permission prefix** — mismatch with seeded permissions | `LanguageController.php:75–131` |
| DEAD-GLB-002 | GlobalMaster | **AcademicSessionController::destroy() condition logically inverted** — `!$x === true` | `AcademicSessionController.php:124` |
| DUP-WEB-001 | Routing | **global-master, billing, system-config routes registered 3 times in web.php** | `web.php:88/398/647` |
| SEC-ACC-005 | Accounting | **ExpenseClaimController race condition** — claim number via `count() + 1` | `ExpenseClaimController.php:29` |
| SEC-HR-001 | HrStaff | **Arbitrary column override via field_name in payroll** — `$detail->{$fieldName}` | `PayrollController.php:93` |
| SEC-CAF-001 | Cafeteria | **Student IDOR in apiIndex()** — student_id from query string unverified | `OrderController.php:73` |
| DATA-ACC-002 | Accounting | **`acc_ledgers.current_balance`/`current_balance_type` written by model+VoucherService+RemoteEntryService but ABSENT from DDL** — every post/cancel throws `SQLSTATE 42S22` under schema-of-record (0 migrations) | `Ledger.php:42`, `VoucherService.php:104-110`, `RemoteEntryService.php:191` |
| DATA-ACC-001 | Accounting | **`status` is `INT UNSIGNED` FK→`acc_accounting_status_masters` in DDL (5 tables) but code uses string literals + `string` cast** — status writes/filters break | `Voucher.php:50`, `VoucherService.php:69`, `ReportService.php:31`, DDL:234/252 |
| BUG-ACC-003 | Accounting | **Expense-claim approval + depreciation 500** — services look up VoucherType code `'JRN'` but seeder creates `'JNL'` → `firstOrFail()` ModelNotFound (uncaught) | `ExpenseClaimService.php:32`, `DepreciationService.php:32`, `AccountingSeeder.php:358` |
| BUG-ACC-004 | Accounting | **Approving a voucher removes it from all financial reports** — `approve()` sets status='approved' but ReportService filters status='posted' only | `VoucherController.php:189`, `ReportService.php:31,65,104` |
| BUG-ACC-005 | Accounting | **Cancel reverses ledger directly with NO reversal voucher (BR-ACC-020) + no locked-year guard on post/cancel/approve/destroy (BR-016/022)** | `VoucherService.php:73-93`, `VoucherController.php:115-130` |
| BUG-ACC-006 | Accounting | **Event engine has no duplicate-event guard (BR-ACC-043)** — same source event processed twice → duplicate vouchers | `RemoteEntryService.php:36-96` |
| SEC-ACC-007 | Accounting | **RemoteEntryService re-throws after logging Failed** — propagates to caller, can roll back/block source module (NFR-ACC-006/BR-044) | `RemoteEntryService.php:94` |
| SEC-ACC-006 | Accounting | **Expense-claim edit/submit IDOR** — gate uses string ability, no instance/ownership check (BR-ACC-041) | `ExpenseClaimController.php:90-148` |
| BUG-ACC-007 | Accounting | **Financial-year lock skips draft-voucher pre-check (BR-ACC-009)** | `FinancialYearController.php:91-100` |
| DATA-ACC-004 | Accounting | **Depreciation not idempotent (BR-ACC-039) + no SLM salvage floor (BR-ACC-038)** — re-run duplicates entries & double-depreciates | `DepreciationService.php:15-62` |

### P2 — PERFORMANCE / VALIDATION

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| PERF-TT-001 | SmartTimetable | **index() fires 14+ unbounded queries** including full Activity table scan | `SmartTimetableController.php:109–235` |
| PERF-TT-012 | TimetableFoundation | **generateActivities runs 400+ updateOrCreate in web request** | `ActivityController.php:212–240` |
| PERF-TT-013 | TimetableFoundation | **ClassWorkingDayController — up to 10,000 upserts in single request** | `ClassWorkingDayController.php:468` |
| PERF-GLB-001 | GlobalMaster | **N+1 in DropdownController::index()** — loops paginated keys firing query per row | `DropdownController.php:28–33` |
| PERF-LIB-004 | Library | **User::all() in 20+ controller methods** — full table scan every form load | Multiple files |
| PERF-DSH-005 | Dashboard | **40+ queries per dashboard load** via Schema::getColumnListing introspection | `DashboardController.php` |
| PERF-HPC-004 | Hpc | **15 queries per tab load** via HpcIndexDataTrait on every index() | `HpcIndexDataTrait.php:50–128` |
| PERF-ACC-006 | Accounting | **Dashboard fires 6 unbounded query chains + 12-query monthly loop** | `AccDashboardController.php:47–99` |
| VAL-STP-002 | StudentProfile | **storeBulkAttendance validation fully commented out** | `AttendanceController.php:302–307` |
| STUB-BOK-001 | SyllabusBooks | **Only routed controller has empty store/update/destroy** — routes do nothing | `SyllabusBooksController.php` |
| STUB-REC-001 | Recommendation | **RecommendationController store/update/destroy empty** — registered routes no-op | `RecommendationController.php` |
| SEC-QB-003 | QuestionBank | **generateQuestions() permanently returns demo data** — real AI path unreachable | `AIQuestionGeneratorController.php:218` |
| BUG-CMP-013 | Complaint | **Dropdown queries use `dummy_table_name` key** — always return empty collections | `ComplaintController.php:93–97` |
| SEC-FEE-001 | StudentFee | **14 seeder methods (~1,200 lines) in production controller** | `StudentFeeController.php:92–1374` |
| BUG-ACC-001 | Accounting | **matchEntry/unmatchEntry route wildcard mismatch** — 500 error | `BankReconciliationController.php:133` |
| BUG-ACC-002 | Accounting | **runDepreciation missing {fixed_asset} in route URI** — 500 error | `web.php:112` |
| BUG-ACC-008 | Accounting | **Bank recon completes on "no unmatched", not zero-difference vs closing_balance (BR-034); no override (BR-035)** | `ReconciliationService.php:154-164` |
| VAL-ACC-001 | Accounting | **17/17 FormRequests `authorize(){return true;}` (D30)** — controllers gate, so defense-in-depth gap | `app/Http/Requests/*.php` |
| BUG-ACC-009 | Accounting | **Expense-claim reject reason discarded** — `reject($claim,$reason)` ignores `$reason`, never persisted (BR-041) | `ExpenseClaimService.php:79-85` |
| BUG-ACC-010 | Accounting | **Budget approval workflow (WF4) + 90% over-budget alert (BR-030) not implemented** | `BudgetController.php` |
| DATA-ACC-003 | Accounting | **`acc_vouchers.source_module` is BIGINT FK→`acc_voucher_modules` in DDL but cast/validated/written as string** | `Voucher.php:51`, `VoucherRequest.php:28`, `RemoteEntryService.php:155` |
| PERF-ACC-007 | Accounting | **Bank auto-match has no narration-keyword/confidence score (BR-033 partial)** | `ReconciliationService.php:88-128` |
| ARCH-ACC-001 | Accounting | **Two divergent ledger-posting paths** — VoucherService raw `DB::raw` vs RemoteEntryService `increment/decrement` | `VoucherService.php:99-112`, `RemoteEntryService.php:182-196` |
| DEAD-ACC-001 | Accounting | **AccountingController REST stub returns `[]` on all 5 methods** — wired via api.php apiResource | `AccountingController.php:9-32` |

### P3 — DEAD CODE / CLEANUP

| Code | Module | Issue |
|------|--------|-------|
| DEAD-EXM-001 | LmsExam | `dd($e)` at store():577 — renders DB::rollBack() unreachable |
| DEAD-SCH-001 | SchoolSetup | 5 backup controller files in production directory |
| DEAD-TT-001 | SmartTimetable | 8 unused imports (Faker, Hash, Role, etc.) in 3,501-line controller |
| DEAD-TT-002 | SmartTimetable | createConstraintManager() — all 12 constraints commented out, never called |
| DEAD-LIB-009–013 | Library | 5 commented-out dd() calls across controllers |
| DEAD-NOT-010–011 | Notification | 2 commented-out dd() calls |
| DEAD-TPT-001 | Transport | TransportController.php-old backup file |
| DEAD-STP-014 | StudentPortal | 7 scaffolded CRUD stubs never routed |
| DEAD-PRM-001–005 | Prime | 5 commented-out code blocks across controllers |
| DEAD-FEE-001 | StudentFee | 14 seeder methods (~1,200 lines) should be Laravel Seeders |
| SEC-SCH-008 | SchoolSetup | `rand()` returns fake student/class counts as real dashboard data |

### Previously Documented — Status Update (2026-04-02)

| Old Code | Status | Notes |
|----------|--------|-------|
| BUG-LMS-001 | **STILL PRESENT** | dd($e) in LmsExamController::store() at line 577 |
| BUG-LMS-002 | **FIXED** | Gate calls active in ExamBlueprint/Scope controllers; only toggleStatus() missing Gate |
| BUG-LMS-003 | **FIXED** | HomeworkData() now has `Request $request` parameter |
| BUG-LMS-004 | **FIXED** | review() now has Gate::authorize; NEW: show() missing auth (SEC-HWK-002) |
| BUG-LMS-005 | **PARTIAL** | LmsQuiz Gate active; LmsQuests Gate still commented out |
| SEC-LMS-001 | **STILL PRESENT** | Zero EnsureTenantHasModule on any LMS route group |
| PERF-LMS-001 | **STILL PRESENT** | 9+ unbounded queries in LmsExamController::index() |
| SEC-QB-002 | **FIXED** | API keys now use env() — no hardcoded keys found |
| SEC-HPC-001–015 | **MOSTLY FIXED** | 21 HPC bugs fixed in sprint; see HPC Post-Sprint section above |
| BUG-HPC-001 | **REGRESSED** | Now 7 missing imports (was 4 fixed); 3 new controllers added without imports |

---

## Deep Audit — 2026-04-09 (Phase 2, post count-only re-audit)

> Focused re-audit of modules that **changed** between 2026-04-02 and 2026-04-09, or needed verification of prior regression status.
> Six parallel Explore agents audited: StudentPortal, Inventory, LmsExam/Quiz/Homework/Quests, StudentProfile Leave, Admission+Vendor, Hpc.
> New codes start from existing numbering per module.

### P0 — FATAL / PRODUCTION-BREAKING (Phase 2)

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-STP-007 | StudentPortal | **IDOR in proceedPayment() STILL UNPATCHED** — `$request->payable_id` passed to PaymentService without verifying FeeInvoice belongs to auth()->user()->student->id. Any student can pay another student's invoice. | `StudentPortalController.php:427–450` |
| SEC-EXM-005 | LmsExam | **GrievanceReviewController::show() + resolve() — ZERO authorization.** Any authenticated user can read/resolve any exam grievance across students. | `GrievanceReviewController.php:68,85` |
| SEC-HWK-003 | LmsHomework | **HomeworkSubmissionController::show() — ZERO authorization (IDOR unchanged from 2026-04-02).** Any student can view any submission by guessing ID. | `HomeworkSubmissionController.php:225–229` |
| BUG-HPC-016 | Hpc | **`generateReportPdf()` REGRESSED — NO `Gate::authorize()` call.** Inconsistent with 13 sibling methods (all of which have auth per the 2026-03-17 sprint). Any authenticated user can generate PDF reports for any student. | `HpcController.php:1232` |
| BUG-VND-002 | Vendor | **VendorPaymentController STILL missing create/store/edit methods** — `Route::resource('vendor-payments', ...)` registered in Vendor module web.php but controller only implements `index/update/destroy/show`. POST `vendor-payments/create` and GET `vendor-payments/{id}/edit` return 500. Unpatched since 2026-04-02. | `Vendor/routes/web.php:62` + `VendorPaymentController.php` |
| BUG-EXM-003 | LmsExam | **`ExamStudentGroupMemberController::toggleStatus()` STILL missing** → route at `LmsExam/routes/web.php:130` returns 500. Unpatched since 2026-04-02. | `LmsExam/routes/web.php:130` |

### P0 — DATA LEAK / PRIVILEGE ESCALATION (Phase 2)

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-STP-008 | StudentPortal | **IDOR in StudentExamAttemptController::attempt($id)** — no allocation check. Student can access ANY exam paper's attempt page via direct URL. Allocation check exists in `instructions()` but NOT in `attempt()` flow. | `StudentExamAttemptController.php:230–244` |
| SEC-STP-009 | StudentPortal | **User::all() exposes full user roster** in complaint form — `$users = User::select('id','name')->get()` loads every tenant user (admins/staff/students) and renders in dropdown. | `StudentPortalComplaintController.php:41` |
| SEC-STD-005 | StudentProfile | **Leave subsystem has NO tenancy scoping** — `LeaveApplication`, `LeaveApplicationRemark` extend plain `Model`, no `BelongsToTenant` trait, no `addGlobalScope`. If global tenancy middleware fails, cross-tenant data leak. | `Modules/StudentProfile/app/Models/Leave*.php` |
| SEC-INV-001 | Inventory | **ALL 18 FormRequests have `authorize()` → `return true`** — extends systemic D25 pattern. Financial requests (StorePurchaseOrderRequest, StoreGrnRequest, StoreStockIssueRequest, StoreStockAdjustmentRequest, StoreQuotationRequest, StoreRateContractRequest, StorePurchaseRequisitionRequest, StoreIssueRequestRequest) rely solely on controller Gate checks — no defense in depth. | `Inventory/app/Http/Requests/*.php` (all 18) |
| SEC-EXM-006 | LmsExam | **PaperSetQuestionRequest::authorize() = true** — mitigated by controller Gate checks but no defense in depth. | `PaperSetQuestionRequest.php:13` |
| SEC-EXM-007 | LmsExam | **ExamQueryService — no explicit tenant scoping** on 381-line query builder. Relies on implicit global scopes; unverified. Used by new GrievanceReviewController + PaperSetQuestionController. | `ExamQueryService.php:26+` |

### P1 — SECURITY / AUTH BYPASS (Phase 2)

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-QZT-002 | LmsQuests | **`LmsQuestController::index()` Gate STILL commented out** — `// Gate::authorize('tenant.quest.viewAny');` left from 2026-03-14 audit. BUG-LMS-005 remains PARTIAL. | `LmsQuestController.php` (index method) |
| SEC-VND-005 | Vendor | **`VendorController::index()` Gate::authorize STILL commented** — 2026-04-02 finding unpatched. Tab-based index page bypasses authorization. | `VendorController.php:26` |
| SEC-VND-006 | Vendor | **Gate prefix MISMATCH STILL present**: VndUsageLogController uses `vendor.usageLog.*`; VendorPaymentController uses `vendor.vendor.viewAny`. Other Vendor controllers use `tenant.vendor-*`. Policies under `tenant.*` never match these calls → silent 403s. | `VndUsageLogController.php:21`, `VendorPaymentController.php:25` |
| SEC-STP-010 | StudentPortal | **`StartAttemptRequest::authorize()` returns bare `auth()->check()`** — no ownership check against assessment_id. Controller compensates via AllocationService but FormRequest is a no-op safety net. | `StartAttemptRequest.php:11–14` |
| SEC-INV-002 | Inventory | **`GrnController::reject()` uses `inventory.grn.accept` permission** instead of dedicated `inventory.grn.reject`. Accept/reject roles conflated. | `GrnController.php:154` |
| SEC-STD-006 | StudentProfile | **`LeaveService::respondToInfoRequest()` / `respondToDocRequest()`** — validate `remark_id` against the passed `$application` object but DO NOT re-check `$application->student_id === auth()->user()->student_id`. If any future controller passes an attacker-supplied application, IDOR. | `LeaveService.php` |
| SEC-STD-007 | StudentProfile | **`applied_by` + `reviewed_by` in LeaveApplication `$fillable`** — both FK to sys_users with no role gate. A student could mass-assign `reviewed_by` to themselves. | `LeaveApplication.php` |

### P1 — DEAD CODE / UNFINISHED FEATURES (Phase 2)

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| DEAD-STD-001 | StudentProfile | **Leave subsystem is FULLY DEAD CODE.** 4 models + LeaveService exist with real business logic, but **no LeaveController, zero routes registered** in `Modules/StudentProfile/routes/web.php`. Feature is floating — unreachable from UI/API. Phase 1 models+service count is misleading. | `Modules/StudentProfile/app/Models/Leave*.php`, `LeaveService.php` |
| DEAD-STP-001 | StudentPortal | **`ParentResultsController::show()` + `generateLink()` — controller exists but NO routes registered**. Dead code for signed-URL result viewing. | `ParentResultsController.php:21–103` |
| DEAD-STP-002 | StudentPortal | **`StudentPortalController` has 7 empty CRUD stub methods** (index, create, store, show, edit, update, destroy) at lines 711–759 — not routed. Scaffolding leftover. (Previously DEAD-STP-014.) | `StudentPortalController.php:711–759` |
| DEAD-STP-003 | StudentPortal | **`StudentPortalComplaintController::show/edit/update/destroy` are stubs** — `Route::resource('complaint', ...)` registered but show() returns hardcoded view, edit/update/destroy are empty. | `StudentPortalComplaintController.php:204–225` |
| DEAD-STP-004 | StudentPortal | **Commented `// dd($statusId);`** left in production code. | `StudentPortalComplaintController.php:137` |
| DEAD-INV-001 | Inventory | **`InventoryController` is a scaffold stub** extending wrong base class (`App\Http\Controllers\Controller` instead of `Routing\Controller`), empty store/update bodies. Not routed. Delete. | `InventoryController.php` |
| DEAD-INV-002 | Inventory | **Several route handlers build full eager-loaded queries then discard them** (e.g. `PurchaseOrderController::index()` at lines 22–32 — builds `$pos` query, then `return redirect()->route('inventory.procurement')`). Dead queries burning DB cycles. Same pattern in UomController::index. | `PurchaseOrderController.php:22–32` |
| DEAD-EXM-002 | LmsExam | **BUG-LMS-001 / DEAD-EXM-001 (`dd($e)` at LmsExamController.php:577)** — verified FIXED in 2026-04-09 re-read. Remove from open list. | — |
| BUG-HWK-001 | LmsHomework | **`show()` wraps `$request->all()` check before inline `$request->validate()`** (non-standard validation pattern — validation is reachable but confusing). | `StudentHomeworkController.php:179–198` |

### P2 — PERFORMANCE / VALIDATION (Phase 2)

| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| PERF-STP-001 | StudentPortal | **`StudentPortalController::dashboard()` fires 5+ separate DB queries without pagination/eager-loading**. `HomeworkSubmission::pluck() + Homework::whereNotIn()` is explicit N+1. Raw LMS-result query loads all 6 results then filters in PHP. | `StudentPortalController.php:39–260` |
| PERF-STP-002 | StudentPortal | **`StudentExamAttemptController::loadExamQuestions()` N+1** — for each question, queries `qns_question_options` inside `map()` callback. Needs `with('options')`. | `StudentExamAttemptController.php:54–107` |
| PERF-INV-001 | Inventory | **`StockEntryController`** — `StockItem::active()->orderBy('name')->get()` and `Godown::active()->orderBy('name')->get()` unbounded. Scales O(n) with tenant size. | `StockEntryController.php:35–36` |
| PERF-INV-002 | Inventory | **`UomController::indexConversions()`** — unbounded `UnitOfMeasure::active()->get()` for dropdown. | `UomController.php:106` |
| VAL-STP-001 | StudentPortal | **9 of 14 controllers have NO FormRequest injection** — StudentPortalController, StudentGrievanceController, StudentExamAttemptController, StudentQuizAttemptController, StudentQuestAttemptController, StudentTimetableController, StudentTeachersController, StudentLmsController, NotificationController. 5 FormRequests for 14 controllers = major validation gap. | 9 files |
| VAL-INV-001 | Inventory | **`StoreGrnRequest` allows `qty_accepted`/`qty_rejected` in store rules** (lines 34–35) — these are QC-only fields set during `inspect()`. Store payload can override QC decisions. | `StoreGrnRequest.php:34–35` |
| VAL-STD-001 | StudentProfile | **No validation of `total_days` in `LeaveService::createAndSubmit()`** — calculated as `diffInDays() + 1` but never re-verified on approve. DB tampering could bypass leave quota. | `LeaveService.php` |
| VAL-STD-002 | StudentProfile | **No overlap check on half-day leave** — two applications for same date with `is_half_day=true` can both be approved (no DB constraint, no service guard). Attendance fraud vector. | `LeaveService.php` |
| BUG-STD-001 | StudentProfile | **`LeaveService::markAttendanceOnApproval()` is a STUB** with comment "To be implemented". On approval, attendance never flips to Leave — manual intervention required. | `LeaveService.php:239` |
| BUG-STP-001 | StudentPortal | **`ExamAttempt::$fillable` includes `created_by`** — should be auto-set from `auth()->id()`, not mass-assignable. Same issue on `ExamGrievance::$fillable` (includes `created_by` AND `reviewer_id`). | `ExamAttempt.php:23–42`, `ExamGrievance.php:16–31` |
| BUG-ADM-003 | Admission | **`AdmissionPipelineService` still references `$application->cycle_id`** — 2026-04-08 commit renamed `cycle_id → admission_cycle_id` in models/controllers but missed this service line. | `AdmissionPipelineService.php:73` |
| PERF-LMS-002 | LmsExam | **PERF-LMS-001 CONFIRMED STILL PRESENT** — 9+ unbounded queries in `LmsExamController::index()` ($examDashboardStats array, lines 148–180). | `LmsExamController.php:148–180` |
| VAL-STD-003 | StudentProfile | **`LeaveApplicationDocument` MediaCollection has no `maxUploadSize`** — Spatie default ~100MB; disk-exhaustion DoS vector. | `LeaveApplicationDocument.php` |

### Phase 2 — Resolved / Status Updates

| Code | Status | Notes |
|------|--------|-------|
| BUG-LMS-001 / DEAD-EXM-001 | **FIXED** | `dd($e)` removed from LmsExamController (verified 2026-04-09) |
| BUG-QST-TOPICS | **FIXED** | `QuestScopeController::getTopics()` method now exists at LmsQuests/routes/web.php:32 |
| BUG-EXM-TOGGLE | **STILL PRESENT** | `ExamStudentGroupMemberController::toggleStatus()` missing → 500 at `LmsExam/routes/web.php:130` |
| BUG-LMS-005 | **STILL PARTIAL** | LmsQuiz Gate active; LmsQuests `LmsQuestController::index()` Gate STILL commented (SEC-QZT-002) |
| SEC-RTG-005 | **PARTIALLY RESOLVED** | HPC controllers ARE imported in `Modules/Hpc/routes/web.php`, but BUG-HPC-016 shows one method (`generateReportPdf`) missing Gate::authorize. Route-layer class-not-found risk gone; method-layer auth bypass remains. |
| SEC-HPC-001 through 005 | **STILL FIXED** (except BUG-HPC-016 regression on generateReportPdf) | 2026-03-17 sprint fixes hold for 13/14 HpcController methods and all 14 FormRequests. |
| SEC-STP-003 | **STILL UNPATCHED** | proceedPayment IDOR unchanged since 2026-04-02. Now tracked as SEC-STP-007. |
| Admission — "no Gate::authorize()" | **FIXED** | All 15 Admission controllers now have explicit `Gate::authorize()` calls. Service-layer-only auth replaced with defense-in-depth. |
| Vendor — BUG-VND-002 | **STILL UNPATCHED** | VendorPaymentController create/store/edit methods still missing. |
| Inventory — 14 services | **VERIFIED REAL** | All 14 services (Asset, Godown, GrnPosting, InventoryReport, PurchaseOrder, PurchaseRequisition, Quotation, RateContract, ReorderAlert, StockAdjustment, StockGroup, StockIssue, StockLedger, StockValuation) contain real logic, not stubs. GrnPostingService uses DB::transaction + StockLedgerService. PurchaseOrderService has generatePoNumber, convertFromPR, convertFromQuotation, requiresApproval. |


---

### Phase 2 — New Module Audit (2026-06-21)

#### P0 — CRITICAL SECURITY (New Modules Phase 2)
| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-PPT-001 | ParentPortal | **Gate::define permanently overwrites `tenant.hpc.view`** in `reportCardPdf()` — replaces the gate for the entire PHP-FPM worker lifetime, so any subsequent admin gate check silently passes for all users. | `Modules/ParentPortal/app/Http/Controllers/ParentResultController.php:156` |
| SEC-PPT-002 | ParentPortal | **Zero FormRequest files — all 28 controllers use plain `Request`** with no `authorize()` method, meaning policy enforcement relies entirely on inconsistent ad-hoc `abort_unless` calls. | `Modules/ParentPortal/app/Http/Controllers/` (all 28 controllers) |
| SEC-PPT-003 | ParentPortal | **PTM `book()` has no class/section scope guard** — `POST /ptm/slot/{slot}/book` resolves any `PtmSlot` via route-model binding with no check that the slot belongs to the authenticated child's class section. | `Modules/ParentPortal/app/Http/Controllers/ParentPtmController.php:99` |
| SEC-PPT-004 | ParentPortal | **Complaint `store()` writes unvalidated `target_table_name`, `target_selected_id`, `target_name`, `target_code`** directly to DB — these four fields bypass the `$request->validate()` block and are passed raw into `Complaint::create()`. | `Modules/ParentPortal/app/Http/Controllers/ParentComplaintController.php:142-145` |
| SEC-SCH-017 | SchoolSetup | **`OrganizationAcademicSessionController` has zero Gate::authorize** — `setActiveSession()` switches the org-wide active academic session with no authorization check beyond `auth` middleware. | `Modules/SchoolSetup/app/Http/Controllers/OrganizationAcademicSessionController.php:223` |
| SEC-FBK-001 | Feedback | **Zero authorization checks in 9 of 10 controllers** — `FbkCycleController`, `FbkTemplateController`, `FbkResponseController`, `FbkCycleFeedbackTypeController`, `FbkMenuController`, `FbkCategoryController`, `FbkTargetTypeController`, `FbkRelationshipTypeController`, `FbkDashboardController` expose all mutation routes to any authenticated tenant user. | `Modules/Feedback/app/Http/Controllers/FbkCycleController.php:40`, `FbkTemplateController.php:40`, `FbkResponseController.php:79`, et al. |
| SEC-FBK-002 | Feedback | **Eligibility bypass on response submit** — `FbkResponseController` injects `FbkEligibilityService` (line 23) but never calls `$this->eligibilityService->isEligible()` in `saveDraft()` or `submit()`. Any authenticated user can submit feedback for any target/cycle they are ineligible for. | `Modules/Feedback/app/Http/Controllers/FbkResponseController.php:23,68,79` |

#### P1 — SECURITY / BUGS (New Modules Phase 2)
| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-PPT-005 | ParentPortal | **Event `rsvp()` does not verify the event targets the child's class/section** — `index()` filters by class/section but `rsvp()` performs no scope check, allowing cross-class RSVP. | `Modules/ParentPortal/app/Http/Controllers/ParentEventController.php:89-150` |
| SEC-PPT-006 | ParentPortal | **ConsentForm `sign()` does not verify the form targets the child's class/section** — binds any `ConsentForm` without checking `class_id`/`section_id` against the child's enrollment. | `Modules/ParentPortal/app/Http/Controllers/ParentConsentFormController.php:79-128` |
| SEC-DSH-006 | Dashboard | **No role-level authorization in any of 26 controllers** — routes are behind `auth+verified` middleware only; `/dashboard/superadmin` and `/dashboard/accounts` reachable by any authenticated user. | `Modules/Dashboard/routes/web.php:34` and all controllers |
| SEC-DSH-007 | Dashboard | **`SuperAdminDashboardController` renders platform-sensitive data (tenant list, billing, error logs, security audit) with no role check** — `index()` at line 14 calls `loadTenants()`, `loadErrorLog()`, `loadSecurity()` without `$this->authorize`. | `Modules/Dashboard/app/Http/Controllers/SuperAdmin/SuperAdminDashboardController.php:14` |
| SEC-SCH-018 | SchoolSetup | **`EmployeeReportController` has no Gate::authorize on `index()`** — loads all employee attendance, leave balances, separation data, and HR analytics with no fine-grained permission check. | `Modules/SchoolSetup/app/Http/Controllers/EmployeeReportController.php:28` |
| SEC-SCH-019 | SchoolSetup | **`RolePermissionController::index()` has Gate::authorize commented out** — live check uses `Gate::any()` with a different permission set, creating a bypass path. | `Modules/SchoolSetup/app/Http/Controllers/RolePermissionController.php:24` |
| SEC-SCH-020 | SchoolSetup | **All 31 FormRequest `authorize()` methods return bare `true`** — no FormRequest performs user capability checks; authorization is 100% controller-layer only, and several controllers skip it. | `Modules/SchoolSetup/app/Http/Requests/` (all 31 files) |
| SEC-LIB-010 | Library | **`StaffLibraryController` has zero Gate::authorize() calls** across all 5 write methods (`requestDigitalAccess`, `reservePhysical`, `renewBook`, `cancelRequest`, `submitReview`). Any authenticated user can reserve/cancel/review for other members' IDs. | `Modules/Library/app/Http/Controllers/StaffLibraryController.php:324,360,409,495,690` |
| SEC-LIB-011 | Library | **All 27 FormRequest `authorize()` methods return bare `true`** — provides zero protection for controllers that skip Gate (e.g., StaffLibraryController). | `Modules/Library/app/Http/Requests/` (all 27 files) |
| SEC-HST-001 | Hostel | **`HostelDisciplineReportController` has no Gate::authorize** — `index`, `searchStudents`, `ajaxHistory` expose all student discipline histories to any authenticated user. | `Modules/Hostel/app/Http/Controllers/HostelDisciplineReportController.php:21-69` |
| SEC-HST-002 | Hostel | **`HostelMedicalReportController` has no Gate::authorize** — `index` and `showAdmission` expose sick-bay admissions, diagnosis, and treatment notes to any authenticated user. | `Modules/Hostel/app/Http/Controllers/HostelMedicalReportController.php:19-44` |
| SEC-HST-003 | Hostel | **5 additional report controllers lack Gate::authorize** — `HostelMaintenanceReportController`, `HostelMessReportController`, `HostelLaundryReportController`, `HostelReservationReportController`, `HostelWardenReportController` serve financial/operational reports with no role guard. | `Modules/Hostel/app/Http/Controllers/HostelMaintenanceReportController.php` et al. |
| SEC-CCH-001 | CommonChat | **`ChatAjaxController` has no Gate authorization on any of 13 methods** — `createConversation` (line 327) does not verify the user is allowed to create chats; participant membership checked ad-hoc in some but not all methods. | `Modules/CommonChat/app/Http/Controllers/ChatAjaxController.php:30,147,327,379,397,416,431,446` |
| SEC-BEH-001 | BehaviouralAssessment | **All 5 FormRequest `authorize()` methods return bare `true`** — `BaRatingScaleRequest`, `BaInterventionRequest`, `BaCategoryRequest`, `BaConfigRequest`, `BaAssessmentPeriodRequest` grant unconditional access. | `Modules/BehaviouralAssessment/app/Http/Requests/BaRatingScaleRequest.php:14` et al. |
| SEC-BEH-002 | BehaviouralAssessment | **No auth middleware on web routes** — `web.php` has zero `auth`, `tenancy`, or `middleware` declarations; Gate::authorize() in controllers is the only protection layer. | `Modules/BehaviouralAssessment/routes/web.php:1-120` |
| SEC-PTM-001 | Ptm | **No permission gate checks in `PtmManagementController` AJAX endpoints** (`getEventTeachers:338`, `getEventStudents:398`, `getTeacherSlots:376`) or `PtmCombinedViewController` (`setup:52`, `bookings:170`) — any authenticated user can access sensitive PTM data. | `Modules/Ptm/app/Http/Controllers/PtmManagementController.php:338,376,398`, `PtmCombinedViewController.php:52,170` |
| SEC-PTM-002 | Ptm | **All 18 FormRequest `authorize()` methods return bare `true`** — every Store* and Update* request grants unconditional access. | `Modules/Ptm/app/Http/Requests/StorePtmAssignmentRequest.php:12` et al. (18 files) |
| SEC-MSG-001 | MarksheetGeneration | **`StudentResultController::store()` uses wrong Gate ability** — calls `Gate::authorize('tenant.msh-student-result.update')` on store, so a user with only update permission can create records. | `Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php:37` |
| SEC-MSG-002 | MarksheetGeneration | **`StudentResultController::create()` uses wrong Gate ability** — calls `Gate::authorize('tenant.msh-student-result.view')`, allowing view-only users to reach the create form. | `Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php:26` |
| SEC-MSG-003 | MarksheetGeneration | **All 19 FormRequest `authorize()` methods return bare `true`** — single layer of defense with no fallback if a controller check is ever missed. | `Modules/MarksheetGeneration/app/Http/Requests/*.php:12` (all 19 files) |
| BUG-PPT-001 | ParentPortal | **4 API controllers are `abort(501)` stubs** wired to live routes — `ParentAttendanceApiController`, `ParentDashboardApiController`, `ParentLeaveApiController`, `ParentSessionApiController` all return HTTP 501 in production. | `Modules/ParentPortal/app/Http/Controllers/Api/ParentAttendanceApiController.php:12` et al. |
| BUG-PPT-002 | ParentPortal | **`ParentPortalController` has empty `store()`, `update()`, `destroy()`** — scaffold stub never implemented. | `Modules/ParentPortal/app/Http/Controllers/ParentPortalController.php:29,50,55` |
| BUG-PPT-003 | ParentPortal | **`ParentComplaintController::show()` calls `$this->context->resolveChild()` and `Auth::user()` twice** — redundant session reads; second pair overwrites the first with identical values, indicating incomplete refactoring. | `Modules/ParentPortal/app/Http/Controllers/ParentComplaintController.php:192,228` |
| BUG-DSH-006 | Dashboard | **`Route::apiResource('dashboards', DashboardController::class)` registers 7 REST methods but `DashboardController` only implements `index()`** — `POST /v1/dashboards`, `PUT /v1/dashboards/{id}`, `DELETE /v1/dashboards/{id}` all throw `BadMethodCallException`. | `Modules/Dashboard/routes/api.php:5`, `DashboardController.php:16` |
| BUG-SCH-017 | SchoolSetup | **`EmployeeProfileController` is missing 5 routed methods** — `addProfile()`, `addTeacherProfile()`, `updateDocuments()`, `generateQrCode()`, `toggleProfileStatus()` all throw fatal 500 errors. | `Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php` (routes/web.php:121-125) |
| BUG-SCH-018 | SchoolSetup | **`OrganizationAcademicSessionController` missing 3 routed methods** — `trashedOrganizationAcademicSessionController()`, `restore()`, `forceDelete()` all 500. | `Modules/SchoolSetup/app/Http/Controllers/OrganizationAcademicSessionController.php` (routes/web.php:227-230) |
| BUG-SCH-019 | SchoolSetup | **`ClassGroupController` missing `listSubgroups()` and `getSubgroupStats()`** — routes at web.php:211-212 will fatal-error. | `Modules/SchoolSetup/app/Http/Controllers/ClassGroupController.php` (routes/web.php:211-212) |
| BUG-SCH-020 | SchoolSetup | **`RolePermissionController` missing `trashedRolePermissions()`** — `GET /role-permission/trash/view` returns fatal error. | `Modules/SchoolSetup/app/Http/Controllers/RolePermissionController.php` (routes/web.php:132) |
| BUG-SCH-021 | SchoolSetup | **`TeacherController` missing `assignSubjects()`** — `GET /teacher/assign-subjects/{user_id}` fatals. | `Modules/SchoolSetup/app/Http/Controllers/TeacherController.php` (routes/web.php:217) |
| BUG-SCH-022 | SchoolSetup | **`SubjectStudyFormatController` missing `subjectView()`** — `GET /subject-study-format/trash/views/{id}` will 500. | `Modules/SchoolSetup/app/Http/Controllers/SubjectStudyFormatController.php` (routes/web.php:269) |
| BUG-SCH-023 | SchoolSetup | **`ClassSubjectManagementController::store()`, `update()`, `destroy()` all have completely empty bodies** — resource routes POST/PUT/DELETE silently do nothing. | `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectManagementController.php:29-59` |
| BUG-SCH-024 | SchoolSetup | **`SchoolSetupController::store()`, `update()`, `destroy()`, and 4 other methods are empty stubs** — resource routes for school-setup silently do nothing. | `Modules/SchoolSetup/app/Http/Controllers/SchoolSetupController.php:29-80` |
| BUG-LIB-010 | Library | **9 routed methods completely missing from controllers** — `LibFineReportController` missing `export()` and `refresh()`; `LibReportPrintController` missing all 5 print methods; `LibFineController` missing `testAccounting()`; `LibReservationController` missing `cancelPage()`. Every route throws 500. | `Modules/Library/routes/web.php:226,234,335-350` et al. |
| BUG-LIB-011 | Library | **`LibraryController::store()`, `update()`, `destroy()` are empty stubs** — `POST/PUT/DELETE /v1/libraries` silently return null/204. | `Modules/Library/app/Http/Controllers/LibraryController.php:879,900,905` |
| BUG-HST-001 | Hostel | **`VisitorLogController::storeMedia` and `::destroyMedia` do not exist** but are wired to live routes — throws fatal error on any call. | `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` (routes/web.php:358-359) |
| BUG-HST-002 | Hostel | **`MessOptOutController::approve` and `::reject` do not exist** but routes are registered — Approve/Reject in the mess opt-out UI throws 500. | `Modules/Hostel/app/Http/Controllers/MessOptOutController.php` (routes/web.php:457-458) |
| BUG-HST-003 | Hostel | **`MessBillController::publish` does not exist** — route web.php:469 calls the missing method; publishing a mess bill throws 500. | `Modules/Hostel/app/Http/Controllers/MessBillController.php` (routes/web.php:469) |
| BUG-HST-004 | Hostel | **`RoomReservationController::confirm` and `::cancel` do not exist** — both transition-action routes (web.php:477-478) reference non-existent methods. | `Modules/Hostel/app/Http/Controllers/RoomReservationController.php` (routes/web.php:477-478) |
| BUG-HST-005 | Hostel | **`AuditLogController::destroy` is commented out** but `Route::resource('audit-logs', ...)` auto-generates a DELETE route — `BadMethodCallException` on any DELETE request. | `Modules/Hostel/app/Http/Controllers/AuditLogController.php:110-117` (routes/web.php:532) |
| BUG-CCH-001 | CommonChat | **`CommonChatController::store()`, `update()`, `destroy()` are empty stubs** wired to live `apiResource` routes — mutations silently return null. | `Modules/CommonChat/app/Http/Controllers/CommonChatController.php:29,50,55` |
| BUG-BEH-001 | BehaviouralAssessment | **`BehaviouralAssessmentController::store()`, `update()`, `destroy()` all have empty bodies** — API `apiResource` route silently accepts and discards all write calls. | `Modules/BehaviouralAssessment/app/Http/Controllers/BehaviouralAssessmentController.php:29,50,55` |
| BUG-BEH-002 | BehaviouralAssessment | **`BaReportController::export()` is a permanent stub** — body immediately calls `abort(501)`. Route GET `/reports/export` is live and accessible, returning HTTP 501 to authorized users. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaReportController.php:475-479` |
| BUG-MSG-001 | MarksheetGeneration | **Entire API layer broken** — `api.php` registers `Route::apiResource('marksheetgenerations', MarksheetGenerationController::class)` but `MarksheetGenerationController` has zero apiResource methods; every API call returns 404/MethodNotAllowed. | `Modules/MarksheetGeneration/routes/api.php:7`, `MarksheetGenerationController.php` |
| BUG-MSG-002 | MarksheetGeneration | **`StudentSubjectResultController::destroy()` is missing** but resource route registers all 7 methods — `DELETE /student-subject-result/{id}` throws MethodNotAllowed/500. | `Modules/MarksheetGeneration/routes/web.php:149` |
| BUG-MSG-003 | MarksheetGeneration | **`ExamGroupController::edit()` missing model binding parameter** — declared as `public function edit()` with no `ExamGroup $examGroup` parameter; route model binding fails and the edit form is unusable. | `Modules/MarksheetGeneration/app/Http/Controllers/ExamGroupController.php:64` |
| BUG-MSG-004 | MarksheetGeneration | **`StudentResultController::printStudentMarksheet()` is an empty unreachable stub** — empty body, no route points to it, coexists confusingly with the real `print()` method. | `Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php:162-165` |
| BUG-FBK-001 | Feedback | **Entire `api.php` is silently dead** — `RouteServiceProvider::map()` only calls `mapWebRoutes()` and `mapAdminWebRoutes()`; `mapApiRoutes()` does not exist. All API endpoints return 404. | `Modules/Feedback/app/Providers/RouteServiceProvider.php:20-24`, `routes/api.php` |
| BUG-FBK-002 | Feedback | **`FbkSummaryController` imported in `api.php` but the class file does not exist** — when api.php is eventually registered, this will throw a fatal class-not-found error. | `Modules/Feedback/routes/api.php:7` |

#### P2 — PERFORMANCE / VALIDATION / DEAD CODE (New Modules Phase 2)
| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| PERF-PPT-001 | ParentPortal | **`updateNotificationPreferences()` issues one `UserPreference::updateOrCreate()` query per channel** inside a `foreach (ChannelMaster::all())` loop — N+1 with no batch upsert. | `Modules/ParentPortal/app/Http/Controllers/ParentAccountController.php:186-193` |
| PERF-PPT-002 | ParentPortal | **`ParentLeaveController::index()` fires 5 separate `COUNT(*)` queries** for status counts instead of a single `groupBy('status')->count()`. | `Modules/ParentPortal/app/Http/Controllers/ParentLeaveController.php:52-58` |
| PERF-PPT-003 | ParentPortal | **`ParentComplaintController::show()` fires 3 individual `DB::table` queries** for status/severity/priority labels instead of a single `whereIn` lookup. | `Modules/ParentPortal/app/Http/Controllers/ParentComplaintController.php:211-221` |
| PERF-DSH-001 | Dashboard | **`BaseDashboardController::safeCount()` calls `Schema::getColumnListing($table)` on every invocation with no caching** — `DashboardController::index()` alone calls `safeCount` 24 times, firing 24 schema-introspection queries per page load in addition to 24 count queries. | `Modules/Dashboard/app/Http/Controllers/BaseDashboardController.php:27,46` |
| PERF-DSH-002 | Dashboard | **`FrontDeskDashboardController::index()` performs two separate full-table scans on `fof_visitors`** — visitors with purpose and chart aggregation queries issued independently instead of merged. | `Modules/Dashboard/app/Http/Controllers/FrontDesk/FrontDeskDashboardController.php:27,41` |
| PERF-SCH-001 | SchoolSetup | **`ClassGroupController::generateClassGroups()` N+1** — iterates `SchClassGroupsJnt::all()` and accesses `subjectStudyFormat->subject->name` and `subjectStudyFormat->studyFormat->code` with no eager loading; the `with()` call is commented out. | `Modules/SchoolSetup/app/Http/Controllers/ClassGroupController.php:239-265` |
| PERF-LIB-010 | Library | **N+1 INSERT in `bulkStore()` loops** — `LibInventoryAuditDetailController::bulkStore()` calls `LibInventoryAuditDetail::create()` inside a foreach; `LibFineSlabConfigController::bulkStore()` does the same with 3 creates per iteration. | `Modules/Library/app/Http/Controllers/LibInventoryAuditDetailController.php:469-470`, `LibFineSlabConfigController.php:317-391` |
| PERF-HST-001 | Hostel | **N+1 in `HostelOccupancyReportService::getFloorPlan()`** — double foreach over floors → rooms executes 2 raw DB queries per room; 10 floors × 20 rooms = 400+ queries per page. | `Modules/Hostel/app/Services/HostelOccupancyReportService.php:117-140` |
| PERF-HST-002 | Hostel | **`HostelAttendanceReportController::index()` fires 13 unconditional service calls** on every page hit, loading full paginated datasets for all tabs regardless of active tab. | `Modules/Hostel/app/Http/Controllers/HostelAttendanceReportController.php:43-60` |
| PERF-CCH-001 | CommonChat | **N+1 in `messages()` — `receipts()` called twice per message** — `$message->receipts()->whereNotNull('read_at')->count()` and `$message->receipts()->count()` fired separately; 50 messages = 100 extra queries. | `Modules/CommonChat/app/Http/Controllers/ChatAjaxController.php:110-111`, `Mobile/MobileChatMessageController.php:38-39` |
| PERF-CCH-002 | CommonChat | **N+1 in `conversations()` — participants and count queried per row** — `$conversation->participants()->...->first()` plus `$conversation->activeParticipants()->count()` inside a `->through()` loop for every conversation. | `Modules/CommonChat/app/Http/Controllers/ChatAjaxController.php:47,69`, `Mobile/MobileChatController.php:39,63` |
| PERF-CCH-003 | CommonChat | **`ChatSettings::first()` called on every `sendMessage` with no caching** — queried twice in `sendMessage()` (lines 166 and 220) and again in `ChatService::canInitiateDm()` with no memoization. | `Modules/CommonChat/app/Http/Controllers/ChatAjaxController.php:166,220`, `ChatService.php:51` |
| PERF-BEH-001 | BehaviouralAssessment | **N+1 in `BaIncidentController::show()`** — `foreach ($incident->witnesses)` issues one `Student::find()` or `Employee::with('user')->find()` per witness row; no eager loading on the pivot. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php:308-313` |
| PERF-BEH-002 | BehaviouralAssessment | **N+1 in `ratingDetailMapQuery`** — `BaAssessmentRating` eager-loads `criterion` but NOT `criterion.category`; the `->map()` closure triggers a lazy `BaCategory` load per rating row. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaDashboardController.php:260-270` |
| PERF-BEH-003 | BehaviouralAssessment | **`BaAssessmentController::bulkRate()` issues `updateOrCreate()` per rating in a nested foreach** — N students × M criteria = 2×N×M queries; 30 students × 10 criteria = 600 queries per submit. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php:296-317` |
| PERF-BEH-004 | BehaviouralAssessment | **`assessmentsPage()` fires two separate queries for the same table** — `allPeriods` and `openPeriods` could be fetched once and partitioned in PHP. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaDashboardController.php:151-152` |
| PERF-PTM-001 | Ptm | **`PtmManagementController::index()` fires 14+ uncached queries on every page load** — 8 separate `onlyTrashed()->count()` queries plus 6+ unbounded `::all()`/`get()` dropdown calls. | `Modules/Ptm/app/Http/Controllers/PtmManagementController.php:40-72` |
| PERF-PTM-002 | Ptm | **N+1 in `PtmBlockoutService::notifyAffectedBookings()`** — `confirmedBookings` eager-loaded with `student.guardians` but foreach at line 99 fires a fresh `$student->guardians()->...->get()` per booking, discarding the eager-loaded collection. | `Modules/Ptm/app/Services/PtmBlockoutService.php:99,108` |
| PERF-PTM-003 | Ptm | **`PtmSlotService::syncSlotStatusForBlockout()` fires one DB query per slot** — calls `isSlotBlockedByBlockout()` per slot in a loop, each executing a fresh `PtmBlockout::active()->...->exists()` query; 40 slots = 40 blockout queries. | `Modules/Ptm/app/Services/PtmSlotService.php:351-370,317` |
| PERF-PTM-004 | Ptm | **`PtmCombinedViewController::setup()` duplicates 5 unbounded `::all()`/`get()` lookups** already computed in `sharedData()` with no caching between methods. | `Modules/Ptm/app/Http/Controllers/PtmCombinedViewController.php:37-45` |
| PERF-MSG-001 | MarksheetGeneration | **`precheck()` fires 6 raw `DB::table` queries per class inside a foreach** — 20-class schedule = 120+ sequential queries per page load. | `Modules/MarksheetGeneration/app/Http/Controllers/MarksheetScheduleController.php:251-297` |
| PERF-MSG-002 | MarksheetGeneration | **`dashboard()` fires 12 separate model `::count()` queries** — all could be collapsed to 1-2 queries or cached. | `Modules/MarksheetGeneration/app/Http/Controllers/MarksheetGenerationController.php:40-51` |
| PERF-MSG-003 | MarksheetGeneration | **`StudentSubjectResultController::create()` and `edit()` call `Student::orderBy('id')->get()` with no limit** — full students table loaded on every render; memory exhaustion risk at scale. | `Modules/MarksheetGeneration/app/Http/Controllers/StudentSubjectResultController.php:31,69` |
| PERF-FBK-001 | Feedback | **N+1 in `FbkSummaryService::batchRecomputeForCycle()`** — `FbkCycleFeedbackType` records fetched once, then `FbkResponse::where('cycle_feedback_type_id', $cft->id)->get()` fired per CFT inside foreach; 20 feedback types = 21 queries. | `Modules/Feedback/app/Services/FbkSummaryService.php:63-70` |
| VAL-PPT-001 | ParentPortal | **All 28 controllers use plain `Illuminate\Http\Request`** — zero FormRequest classes exist; no reusable, testable, or enforceable authorization layer. | `Modules/ParentPortal/app/Http/Requests/` (directory empty) |
| VAL-PPT-002 | ParentPortal | **`ParentComplaintController::store()` does not validate `target_table_name`, `target_selected_id`, `target_name`, `target_code`** — no allowlist, no type check, no referential integrity validation. | `Modules/ParentPortal/app/Http/Controllers/ParentComplaintController.php:63-73,142-145` |
| VAL-SCH-001 | SchoolSetup | **`AnnualLeaveSessionController::store()` and `update()` use plain `Request` with inline `$request->validate()`** — no dedicated FormRequest for annual leave sessions. | `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php:44,86` |
| VAL-SCH-002 | SchoolSetup | **`EmployeeLeaveApplicationController::store()` and `update()` use plain `Request`** — 500+ line store method with scattered inline validation; no dedicated FormRequest. | `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php:88,608` |
| VAL-LIB-001 | Library | **`LibInventoryAuditController::update()` accepts `$request->details` array with no validation** — arbitrary status strings, null `copy_id` values, and invalid FKs are passed directly to DB operations. | `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php:581-720` |
| VAL-LIB-002 | Library | **`LibCurricularAlignmentController::store()` and `update()` use plain `Request`** — no `LibCurricularAlignmentRequest` class exists; no cross-field uniqueness or business rule constraints. | `Modules/Library/app/Http/Controllers/LibCurricularAlignmentController.php:49,103` |
| VAL-HST-001 | Hostel | **`BedTypeController`, `RoomTypeController`, `HstDynamicStatusMasterController` use plain `Request` with inline `$request->validate()`** — no dedicated FormRequest classes despite other CRUD controllers in the module having them. | `Modules/Hostel/app/Http/Controllers/BedTypeController.php:32,52`, `RoomTypeController.php:32,52`, `HstDynamicStatusMasterController.php:49,88` |
| VAL-CCH-001 | CommonChat | **`ChatAjaxController::createConversation` uses inline `$request->validate()`** — no FormRequest; missing structured validation for the mobile parity path. | `Modules/CommonChat/app/Http/Controllers/ChatAjaxController.php:332,347` |
| VAL-BEH-001 | BehaviouralAssessment | **`BaIncidentController::store()` and `update()` use inline `$request->validate()`** — 18+ rules duplicated verbatim in both methods; no `BaIncidentRequest` FormRequest. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php:52-72,159-179` |
| VAL-BEH-002 | BehaviouralAssessment | **`BaAssessmentController::store()` and `bulkRate()` define their own ad-hoc validation rules** — no `BaAssessmentRequest` FormRequest; no shared contract. | `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php:49,54-58,279,288-293` |
| VAL-PTM-001 | Ptm | **`PtmSlotBookingController::cancel()` and `reschedule()` use inline `$request->validate()`** — inconsistent with the module's 18-FormRequest convention; no FormRequest for these actions. | `Modules/Ptm/app/Http/Controllers/PtmSlotBookingController.php:241,260` |
| VAL-MSG-001 | MarksheetGeneration | **`StudentSubjectResultController` has no FormRequest coverage for `destroy()`** and no soft-delete/restore/forceDelete methods despite being a full CRUD resource. | `Modules/MarksheetGeneration/app/Http/Controllers/StudentSubjectResultController.php` |
| VAL-FBK-001 | Feedback | **`submit()` and `saveDraft()` accept unvalidated answer payloads** — `$request->input('answers', [])` passed directly to `FbkResponseService` with no validation on answer structure, question IDs, or rating bounds. | `Modules/Feedback/app/Http/Controllers/FbkResponseController.php:68,79,111-140` |
| VAL-FBK-002 | Feedback | **9 store/update controller methods use plain `Request`** — `FbkCycleController`, `FbkTemplateController`, `FbkCycleFeedbackTypeController`, `FbkCategoryController`, `FbkTargetTypeController`, `FbkRelationshipTypeController` all type-hint `Illuminate\Http\Request`; some have no visible `validate()` call at all. | `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php:30,50`, `FbkTargetTypeController.php:30,49` et al. |
| DEAD-PPT-001 | ParentPortal | **`ParentPortalController` scaffold stub unreferenced by any route** — empty `store()`, `update()`, `destroy()` bodies; risks accidental routing. | `Modules/ParentPortal/app/Http/Controllers/ParentPortalController.php:1-60` |
| DEAD-DSH-001 | Dashboard | **8 controllers serve entirely hardcoded dummy data** — `AccountsDashboardController`, `InventoryDashboardController`, `LibraryDashboardController`, `PrincipalDashboardController`, `TeacherDashboardController`, `SuperAdminDashboardController`, `ManagementDashboardController`, `TransportDashboardController` all return static PHP arrays with fabricated student names, balances, and counts. | `Modules/Dashboard/app/Http/Controllers/Accounts/AccountsDashboardController.php:57`, `Principal/PrincipalDashboardController.php:28` et al. |
| DEAD-SCH-001 | SchoolSetup | **Commented-out debug `dd()` and `print_r()` calls left in production controllers** — `EmployeeProfileController:352`, `ClassGroupController:263,265,419`, `SubjectController:37`, `OrganizationGroupController:151`, `ClassSubjectGroupController:494`. | `Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php:352` et al. |
| DEAD-SCH-002 | SchoolSetup | **5 backup/versioned controller files in the Controllers directory** — `ClassGroupController_02_02_2026.php`, `ClassGroupController_06_02_2026.php`, `ClassGroupJntController_09_02_2026.php`, `StudentController_20_11_2025.php`, `StudentController_backup_04_12_2025.php`, `StudentController.bk` — contain stale debug calls and should not exist in production source. | `Modules/SchoolSetup/app/Http/Controllers/ClassGroupController_02_02_2026.php` et al. |
| DEAD-SCH-003 | SchoolSetup | **A Blade view file (`competency.blade.php`) stored inside `app/Http/Controllers/`** — not registered in any route; dead code in the wrong directory. | `Modules/SchoolSetup/app/Http/Controllers/competency.blade.php` |
| DEAD-LIB-001 | Library | **Commented-out `dd()` debug statements in production controllers** — `LibAuthorController::store()` has `// dd($request->validated())` with Hindi comment (line 62); `MasterDashboardController::index()` has `// dd($dashboardData); // DEBUG - Check karo data aa raha hai ya nahi` (line 26). | `Modules/Library/app/Http/Controllers/LibAuthorController.php:62`, `MasterDashboardController.php:26` |
| DEAD-LIB-002 | Library | **`LibInventoryAuditController` contains ~260 lines of commented-out alternate implementations** across `create()`, `store()`, `update()` — makes the 1,154-line file ambiguous about which logic is active. | `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php:347,454,507,541,722` |
| DEAD-HST-001 | Hostel | **`AuditLogController` has 50+ lines of commented-out code** — `create`, `store`, `edit`, `update`, `toggleStatus` methods fully implemented inside block comments (lines 20-140), hiding the live bug (missing `destroy`). | `Modules/Hostel/app/Http/Controllers/AuditLogController.php:20-140` |
| DEAD-CCH-001 | CommonChat | **3 controllers with no route registrations** — `ChatModerationController`, `ChatPersonalizationController`, `MobileChatPersonalizationController`, `MobileChatParticipantController` are never registered in web.php, api.php, or mobile_api.php. | `Modules/CommonChat/app/Http/Controllers/ChatModerationController.php` et al. |
| DEAD-BEH-001 | BehaviouralAssessment | **`BehaviouralAssessmentController` is a module-scaffold stub** — `index()`, `create()`, `show()`, `edit()` return generic blade views that likely do not exist; `store()`, `update()`, `destroy()` empty; entire controller is dead weight behind a live API route. | `Modules/BehaviouralAssessment/app/Http/Controllers/BehaviouralAssessmentController.php:13-57` |
| DEAD-PTM-001 | Ptm | **`PtmCombinedViewController::scheduling()` is an orphaned method with no route** — `web.php` routes `combined.scheduling` to `PtmManagementController::index`, not to `CombinedViewController`; the method at line 109 is unreachable dead code. | `Modules/Ptm/app/Http/Controllers/PtmCombinedViewController.php:109` |
| DEAD-MSG-001 | MarksheetGeneration | **`StudentResultController::printStudentMarksheet()` is an empty unreachable method** — empty body, no route points to it (route uses `print` → real `print()` at line 177); dead code that will silently return null if ever reached. | `Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php:162-165` |
| DEAD-FBK-001 | Feedback | **`FbkEligibilityService` injected but never called** — declared in constructor (line 23), never referenced elsewhere in the file; instantiated on every request for no effect while the eligibility gate it provides is completely bypassed. | `Modules/Feedback/app/Http/Controllers/FbkResponseController.php:23` |

---

## Deep Audit — Complaint Module (2026-06-23, all 5 layers)

> Full re-audit of Complaint module after context reset. Prior codes BUG-CMP-001/002 were registered twice (March and April 2026) for conflicting issues — see notes below. New codes start from safe offsets.
> Prior open: BUG-CMP-001–003 (partial fixes), BUG-CMP-005, BUG-CMP-013, SEC-CMP-001–003 (partial), SEC-CMP-006.

### Complaint — Layer 1: DDL Schema

| Code | Severity | Issue | DDL File:Line |
|------|----------|-------|---------------|
| SCH-CMP-001 | P1 | `KEY idx_cmp_status (status)` — column `status` does not exist; should be `status_id` | `Complaint_ddl_v2.sql:~160` |
| SCH-CMP-002 | P0 | `fk_cmp_medical_check FOREIGN KEY (is_medical_check_required) REFERENCES cmp_medical_checks(id)` — `is_medical_check_required` is TINYINT(1) boolean, cannot FK to INT PK. DDL will fail on CREATE TABLE. | `Complaint_ddl_v2.sql:~177` |
| SCH-CMP-003 | P0 | `fk_med_result FOREIGN KEY (result) REFERENCES sys_dropdown_table(id)` — `result` is VARCHAR(20), FK references INT id. Type mismatch, DDL will error. | `Complaint_ddl_v2.sql:~226` |
| SCH-CMP-004 | P1 | Column name mismatch: code uses `expected_resolution_hours`, `escalation_hours_l1`–`l5` on `cmp_complaint_categories`; DDL defines `default_expected_resolution_hours`, `default_escalation_hours_l1`–`l5`. All category escalation queries return null. | DDL vs `ComplaintCategoryController.php`, `DepartmentSlaRequest.php` |
| SCH-CMP-005 | P2 | Missing audit/soft-delete columns: `cmp_complaint_categories`, `cmp_department_sla`, `cmp_complaint_actions`, `cmp_ai_insights` missing `created_by`/`updated_by`; `cmp_medical_checks` missing `updated_at` and `deleted_at`; `cmp_complaint_actions` missing `deleted_at`. | `Complaint_ddl_v2.sql` |
| SCH-CMP-006 | P1 | DDL FK constraints reference `sys_dropdown_table`; all application code queries `sys_dropdowns`. Table name mismatch throughout. | DDL vs all Complaint controllers |
| SCH-CMP-007 | P0 | No tenant migration files exist in `Modules/Complaint/database/migrations/`. Tables cannot be created for new tenants. | `Modules/Complaint/database/migrations/` (empty) |

### Complaint — Layer 2: Code Quality / Bugs

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| BUG-CMP-014 | P0 | `ComplaintActionController::restore()` and `forceDelete()` methods do not exist. Routes `GET complaint-actions/{id}/restore` and `DELETE complaint-actions/{id}/force-delete` throw 500. | `routes/web.php:141–149` |
| BUG-CMP-015 | P1 | `GET complaints/manage` (no `{id}` segment) registered AFTER `Route::resource('complaints', ...)` — Laravel matches resource `show` route first with `manage` as `{complaint}`. `Complaint::findOrFail('manage')` → 404. Manage view permanently unreachable. | `routes/web.php:104,127–130` |
| BUG-CMP-016 | P1 | ComplaintController missing 4 methods: `trashed()`, `restore()`, `forceDelete()`, `toggleStatus()`. All 4 are registered routes — each returns 500. | `routes/web.php:107–125` |
| BUG-CMP-017 | P1 | `routes/api.php` registers web `ComplaintController` as `apiResource`. This controller renders Blade views. All 7 REST API routes return HTML. | `routes/api.php` |
| BUG-CMP-018 | P2 | `Complaint::targetable()` uses `morphTo('targetable', 'target_table_name', ...)` — table name as morph type key is non-standard. Laravel morphs resolve by model class name (or registered alias), not table name. Runtime resolution always fails. | `Modules/Complaint/app/Models/Complaint.php` |
| DEAD-CMP-001 | P0 | `AiInsightController` is a complete stub: `show()`/`store()`/`update()` are empty `{}`, `forceDelete()` missing. All 4 are wired to live routes. Zero Gate::authorize. | `AiInsightController.php` |
| DEAD-CMP-002 | P2 | `ComplaintDashboardController` is a complete stub. Route is commented out in web.php — currently harmless. | `ComplaintDashboardController.php` |
| DEAD-CMP-003 | P2 | Commented-out `dd($request->all())` debug code in `MedicalCheckController::store()`. | `MedicalCheckController.php:71–76` |
| DEAD-CMP-004 | P2 | `ComplaintReportController::baseParetoQuery()` private method defined but never called — `getParetoReport()` uses an inline query instead. | `ComplaintReportController.php` |
| DEAD-CMP-005 | P2 | `ComplaintController::getFilteredDashboardData()` private method declared but never called. | `ComplaintController.php` |
| DEAD-CMP-006 | P2 | `aiRiskSentimentReport` appears twice in `compact()` call — duplicate variable reference, indicates incomplete refactor. | `ComplaintReportController.php:88–89` |

### Complaint — Layer 3: Security

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| SEC-CMP-007 | P0 | `ComplaintController::store()` has NO `Gate::authorize()`. Any authenticated tenant user can create a complaint. `create()` is gated but `store()` (lines 209–430) is not. Prior SEC-CMP-001–003 noted this partially; still unresolved. | `ComplaintController.php:209` |
| SEC-CMP-008 | P0 | `DocumentRequestController` — zero `Gate::authorize` on all 3 methods (index, show, update). Any authenticated user can list, view, and update parent document request status. | `DocumentRequestController.php` |
| SEC-CMP-009 | P1 | Cross-module hard dependency: `DocumentRequestController` imports `Modules\ParentPortal\Models\ParentDocumentRequest`. Complaint module must not depend on ParentPortal. Breaks module isolation. | `DocumentRequestController.php:1` |
| SEC-CMP-010 | P1 | `ComplaintMobileController` — zero `Gate::authorize` on 7 of 9 methods: `dashboard()`, `index()`, `show()`, `categories()`, `subcategories()`, `dropdowns()`, `users()`. Any `auth:sanctum` user sees all complaint data. | `Mobile/ComplaintMobileController.php` |
| SEC-CMP-011 | P1 | `ComplaintActionController` uses wrong Gate permission prefix `complaint.complaint.*` (e.g. `complaint.complaint.view`) instead of `tenant.complaint-action.*`. All Gate checks silently mismatch seeded permissions — effective authorization is zero on all methods that have Gate calls. | `ComplaintActionController.php` |
| SEC-CMP-012 | P1 | Cross-layer imports: `Modules\Prime\Models\Dropdown` used in `ComplaintController`, `ComplaintReportController`, `ComplaintMobileController`; `Modules\GlobalMaster\Models\Dropdown` in `ComplaintCategoryController`; `App\Models\User` in `MedicalCheckController`, `DepartmentSlaController`. Central models queried from tenant context violate tenancy isolation. | Multiple controllers |
| SEC-CMP-013 | P2 | `ComplaintController::getTableColumns($table)` has no `Gate::authorize`. Any authenticated user can enumerate the schema of allowed tables. | `ComplaintController.php` getTableColumns() |
| SEC-CMP-014 | P2 | Mobile API RSP applies only `['api', InitializeTenancyByDomain, PreventAccessFromCentralDomains]` — missing `EnsureTenantIsActive`. Deactivated tenants' users can still access the mobile API. | `Modules/Complaint/app/Providers/RouteServiceProvider.php` |

### Complaint — Layer 4: Performance

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| PERF-CMP-001 | P2 | N+1: `getComplaintsWithEscalation()` fires `DB::table('sys_dropdowns')->where('id', $complaint->status_id)->value('value')` inside `.map()` — 1 query per complaint. | `ComplaintController.php` getComplaintsWithEscalation() |
| PERF-CMP-002 | P2 | `index()` fires 15+ queries per request: `DepartmentSla::all()`, `ComplaintCategory::all()`, two unbounded `User::get()`, `Role::all()`, `Department::all()`, `Designation::all()`. All uncached. | `ComplaintController.php` index() |
| PERF-CMP-003 | P2 | `getComplaintActionsData()` calls `User::orderBy('name')->get(['id','name'])` twice — duplicate identical query. | `ComplaintController.php` getComplaintActionsData() |
| PERF-CMP-004 | P2 | `DepartmentSlaController::create()` and `edit()` each fire 7 unbounded queries: `Vehicle::all()`, `Vendor::all()`, `User::all()`, `Role::all()`, `Department::all()`, `Designation::all()`, `EntityGroup::all()`. | `DepartmentSlaController.php` |
| PERF-CMP-005 | P2 | N+1: `getComplainantHotspotReport()` fires 3 additional `DB::table` queries per hotspot row inside `.map()`. 20 rows = 60 extra queries. | `ComplaintReportController.php` getComplainantHotspotReport() |
| PERF-CMP-006 | P2 | `DB::select('SHOW TABLES')` and `DB::getSchemaBuilder()->getColumnListing($table)` called in `create()`, `edit()`, and `getTableData()` — schema introspection on every request, uncached. | `ComplaintController.php` |
| PERF-CMP-007 | P2 | `MedicalCheckController::create()` and `edit()` call `Complaint::all()` and `User::all()` — unbounded. | `MedicalCheckController.php` |
| PERF-CMP-008 | P2 | `ComplaintMobileController::show()`: `Role::orderBy->get()->map(fn => $role->users()->count())` — N+1 per role. | `Mobile/ComplaintMobileController.php` show() |

### Complaint — Layer 5: Deployment

| Code | Severity | Issue |
|------|----------|-------|
| DEPLOY-CMP-01 | P0 | No migration files. Tenant creation cannot provision Complaint tables. Manual DDL also blocked by SCH-CMP-002 and SCH-CMP-003. |
| DEPLOY-CMP-02 | P1 | `routes/api.php` maps web `ComplaintController` as `apiResource`. All API routes return HTML. Should use `ComplaintMobileController` or a dedicated API controller. |

### Status Updates for Prior CMP Codes (2026-06-23)

| Old Code | Status |
|----------|--------|
| BUG-CMP-001 (Mar 2026 — `dd()` in store catch) | Unverified in this audit — check `grep -n "dd(" ComplaintController.php` |
| BUG-CMP-001 (Apr 2026 — 4 missing ComplaintController methods) | **CONFIRMED STILL PRESENT** → tracked as BUG-CMP-016 |
| BUG-CMP-002 (Mar 2026 — `dd('FILTER HIT')` in filter()) | Unverified — filter() still routed via `/dashboard-data` |
| BUG-CMP-002 (Apr 2026 — 2 missing ComplaintActionController methods) | **CONFIRMED STILL PRESENT** → tracked as BUG-CMP-014 |
| BUG-CMP-003 (3 stub controllers) | **PARTIALLY FIXED**: ComplaintAction partially implemented. AiInsight still full stub (P0). ComplaintDashboard still stub (route commented). |
| SEC-CMP-001–003 (show/edit/store/update no Gate) | **PARTIALLY FIXED**: show/edit/update now have Gate. store() STILL MISSING Gate → SEC-CMP-007. |
| SEC-CMP-006 (ComplaintReportController zero auth) | **CONFIRMED STILL PRESENT** → all report methods still unguarded. |
| BUG-CMP-005 / BUG-CMP-013 (dummy_table_name dropdown keys) | **CONFIRMED STILL PRESENT** in MedicalCheckController. |

---

## Mode B+C Audit — Complaint Module (2026-06-27)

> FRD-Driven Gap Analysis + Business Rule Enforcement.
> Prior codes: SCH-CMP-007 | BUG-CMP-018 | SEC-CMP-014 | PERF-CMP-008 | DEAD-CMP-006 | DEPLOY-CMP-02.
> Full report: `6-Dev_Gap_Analysis_Status/Deep_Analysis/2026-06-27/Complaint_Technical_Audit_2026-06-27.md`

### Complaint — Validation Issues (VAL-CMP-*)

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| VAL-CMP-001 | P1 | `default_escalation_hours_l1` validated as `integer` only — not required `gt:default_expected_resolution_hours`. L1 can be ≤ expected hours, violating BR-CMP-002. Same gap in `DepartmentSlaRequest` for `dept_escalation_hours_l1` (BR-CMP-005). | `ComplaintCategoryRequest.php:69`, `DepartmentSlaRequest.php:63` |
| VAL-CMP-002 | P2 | For anonymous complaints, `complainant_name` defaults to `'Anonymous'` when not provided — does not require a real name from the operator. BR-CMP-008 requires a name to be explicitly provided. | `ComplaintController.php:235` |
| VAL-CMP-003 | P1 | `store()` and `update()` accept `severity_level_id` and `priority_score_id` from `$request` — staff can override category defaults. BR-CMP-009 requires auto-assignment from category only. | `ComplaintController.php:260,360` |
| VAL-CMP-004 | P0 | No conditional validation that `resolution_summary` and `actual_resolved_at` are required when `status_id` = Resolved. Both fields are `nullable`. A complaint can be marked Resolved with no summary and no date, violating BR-CMP-012. | `ComplaintController.php:586,589` |
| VAL-CMP-005 | P0 | No status-transition FSM. `status_id` accepted as `nullable|integer` with no transition gate. Any status → any status (e.g., Open → Closed, Resolved → Open without formal reopen). Violates BR-CMP-014. | `ComplaintController.php:582` |
| VAL-CMP-006 | P1 | `MedicalCheckController.store()` does not verify `complaint->is_medical_check_required = true` before allowing medical check creation. Any complaint can receive a medical check, violating BR-CMP-017. | `MedicalCheckController.php:68` |

### Complaint — Bug Issues (BUG-CMP-019 to 025)

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| BUG-CMP-019 | P0 | `resolution_due_at` never calculated or stored during complaint creation. `Complaint::create()` in `store()` has no `resolution_due_at` field. Edit-form calculates display value but does not persist. Violates BR-CMP-010 — every ticket has no SLA deadline. | `ComplaintController.php:339` |
| BUG-CMP-020 | P2 | `logAction()` inserts timeline entries using `'created_at' => now()`. DDL column for timeline time is `action_timestamp`. Using the wrong column violates DDL design intent (BR-CMP-016 partial). | `ComplaintController.php:1257` |
| BUG-CMP-021 | P1 | `ComplaintReportController::getSlaViolationReport()` → `excludeRejectedAndClosed()` excludes 'Rejected' and 'Closed' but not 'Resolved'. Resolved complaints appear in the SLA Violation Report, violating BR-CMP-020. | `ComplaintReportController.php:200` |
| BUG-CMP-022 | P0 | No `reopen()` method exists in any Complaint controller. REQ-CMP-012 (Complaint Reopening) entirely unimplemented. BR-CMP-022 (reopen only from Resolved) and BR-CMP-023 (clear resolution fields + log reason) are both missing. | Feature absent |
| BUG-CMP-023 | P0 | No scheduled escalation job. `Modules/Complaint/app/Jobs/` is empty. `current_escalation_level` on `cmp_complaints` never auto-updated. REQ-CMP-013 and BR-CMP-024 entirely unimplemented. | Jobs/ empty |
| BUG-CMP-024 | P1 | Complaint creation notification sent to `User::role('Super Admin')` not School Admin. FRD Step 1 specifies School Admin. Notification class `StudentPortalComplaintRegistered` imported from `App\Notifications\` (cross-layer dependency). | `ComplaintController.php:384` |
| BUG-CMP-025 | P1 | `update()` logs the assignment action but sends no notification to the assigned user or role. REQ-CMP-004 AC4 requires notification on assignment. | `ComplaintController.php:692` |

### Complaint — Security Issues (SEC-CMP-015 to 016)

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| SEC-CMP-015 | P0 | Private notes (`is_private_note = true`) stored correctly but `ComplaintController.show()` loads complaint actions without filtering by `is_private_note` based on role. All authenticated roles receive private notes. BR-CMP-015 requires enforcement at query layer, not view layer. | `ComplaintController.php:442` |
| SEC-CMP-016 | P1 | Anonymous complaint masking (BR-CMP-021) not enforced at query layer. `show()` and `index()` return `complainant_name` and `complainant_contact` regardless of `is_anonymous` flag or requesting user's role. Any staff member sees anonymous complainant identity. | `ComplaintController.php:442,35` |

### Status Updates — Prior CMP Codes (2026-06-27)

| Code | Status |
|------|--------|
| BUG-CMP-019 (resolution_due_at) | NEW — OPEN |
| SEC-CMP-007 (store() no Gate) | **STILL PRESENT** — confirmed again |
| DEAD-CMP-001 (AiInsightController stub) | **STILL PRESENT** — all methods still empty |
| BUG-CMP-016 (4 missing ComplaintController methods: trashed/restore/forceDelete/toggleStatus) | **UNVERIFIED** in this audit — routes were not re-checked |
| ComplaintCategoryRequest / DepartmentSlaRequest `authorize() { return true; }` | **OPEN** — both requests bypass auth |

### Complaint (CMP) — Mode A Deep Audit (2026-06-29)
> Full report: `3-Audit_Reports/V1_Jun-2026/Complaint_Technical_Audit_2026-06-29.md`. Health 35/100 (P0 cap).

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| BUG-CMP-020 | **P0 (raised from P2)** | `cmp_complaint_actions` has `action_timestamp`, NO `created_at`. `logAction()` inserts `'created_at'=>now()` inside `store()`'s transaction → `Unknown column` → rollback → **no complaint can be created**. `buildComplaintActionsQuery()->latest()` orders by missing `created_at` → timeline list also errors. | `ComplaintController.php:1257,986` ; migration `...create_cmp_complaint_actions_table.php:18` |
| ORM-CMP-001 | P0 | `ComplaintAction` model declares neither `public $timestamps=false` nor `const CREATED_AT` → Eloquent writes/reads absent created_at/updated_at. Root cause of BUG-CMP-020. | `Models/ComplaintAction.php` |
| FE-CMP-001 | P1 | Stored XSS — `{!! $complaint->description !!}` renders user-supplied complaint text raw (reachable from portal submission). | `views/complaint/complaint/show.blade.php:160` ; `edit.blade.php:150` |
| SEC-CMP-017 | P1 | `DocumentRequestController::update()` mutates ParentPortal document-request status/fee/file with NO Gate/policy. | `DocumentRequestController.php:69` |
| PERF-CMP-009 | P1 | Unbounded `User::all()` / `Complaint::all()` loaded into dropdowns per form render. | `DepartmentSlaController.php:43,77` ; `MedicalCheckController.php:58,124` |
| JOB-CMP-001 | P1 | No scheduled escalation job exists (REQ-CMP-013 inert); AI listener `ProcessComplaintAIInsights` is not `ShouldQueue` and fires inside store()'s transaction. | `app/Jobs/` (absent) ; `Listeners/ProcessComplaintAIInsights.php:8` |
| DEAD-CMP-007 | P2 | D30 — `ComplaintCategoryRequest` + `DepartmentSlaRequest` `authorize(){return true;}`; core store/update have no FormRequest. | `Requests/ComplaintCategoryRequest.php`, `DepartmentSlaRequest.php` |

**Re-confirmed OPEN (2026-06-29):** BUG-CMP-019 (resolution_due_at never persisted, `ComplaintController.php:339-379`), SEC-CMP-007 (store() no gate, `:211`), SEC-CMP-015 (private notes not query-filtered, `:969`), SEC-CMP-016 (now PARTIAL — masked in show blade but view-layer only / not role-aware), VAL-CMP-004 (resolve w/o note+timestamp, `:585-589`), VAL-CMP-005 (no status FSM, `:582`), BUG-CMP-024 (notif to `User::role('Super Admin')`, `:384`).

**FIXED since 2026-06-27:** CT-03/CT-04 (`dd($e)` removed), CT-05/06/07 (hardcoded ids → real dropdown lookups; 124/3 remain only as `??` fallbacks), CT-12 (`destroy()` implemented), D23 tenancy stack present, D24 prefixes clean (`tenant.`).

---

## Mode A Deep-Audit Batch — INV · FOF · CAF · HST · LIB (2026-06-29)

> 5 parallel `pa-technical-auditor` Mode A audits, consolidated by the orchestrator. Per-module full
> reports in `3-Audit_Reports/V1_Jun-2026/{Module}_Technical_Audit_2026-06-29.md`; per-module gaps also
> appended to each `AI_Brain/module-knowledge/{CODE}_*.md`. **62 new issue codes** (no collisions).

### Roll-up

| Module | Health | P0 | P1 | P2 | P3 | New codes |
|--------|--------|----|----|----|----|-----------|
| Inventory (INV) | 38/100 (P0 cap) | 1 | 5 | 3 | 1 | 10 |
| Hostel (HST) | 39/100 (P0 cap) | 1 | 6 | 5 | 1 | 13 |
| Library (LIB) | 40/100 (P0 cap) | 1 | 5 | 2 | 1 | 9 |
| FrontOffice (FOF) | 41/100 | 0 | 9 | 6 | 3 | 18 |
| Cafeteria (CAF) | 62/100 | 0 | 4 | 5 | 3 | 12 |
| **Total** | — | **3** | **29** | **21** | **9** | **62** |

### Cross-Module Systemic Patterns (the high-value synthesis)

1. **Concurrency: read-modify-write on counters/balances with NO `lockForUpdate`/atomic op (Layer 8) — pervasive.**
   LIB checkout-eligibility (DAT-LIB-001), CAF order-cancel double-refund (DAT-CAF-001), HST bed allotment + occupancy (DAT-HST-001/002), INV stock decrement + numbering (DAT-INV-003/004), FOF register numbering + key/gate-pass (DAT-FOF-002/004). Same defect class across all 5 modules → races (double-allot, oversell, double-refund, duplicate numbers).
2. **D30 — every module's FormRequests `authorize(){return true;}`.** FOF 10/10, CAF 19/19, HST 35/38, INV 19, LIB present. Consistent with the 90% platform baseline; defense-in-depth absent module-wide (SEC-FOF-003, SEC-CAF-003, SEC-HST-004, SEC-INV-001*, …).
3. **Scheduler/Job tenancy (Layer 10) — commands scheduled in CENTRAL context without `tenants:run`; jobs without tenancy re-init.** CAF `caf:*` (JOB-CAF-001), HST `hst:escalate-complaints` (JOB-HST-001), FOF `fof:flag-overstay` unscheduled (JOB-FOF-002) + ATT-sync job no context (JOB-FOF-001), INV ReorderAlertJob (JOB-INV-001). Per-tenant automation silently never runs.
4. **★ CANDIDATE NEW D-PATTERN — MySQL `GENERATED ALWAYS` columns from the DDL were emitted as inert plain columns in the Laravel migrations.** HST `gen_active_bed_id`/`gen_active_student_id` (DAT-HST-001, the allotment-uniqueness P0) and `hst_mess_bills.total_amount` (MIG-HST-001); INV `variance_qty` (MIG-INV-001). The generated expression is dropped → UNIQUE-on-generated enforces nothing / NOT-NULL inserts fail / computed totals are wrong. **Recommend registering as a platform D-pattern and sweeping all modules (Mode D).**
5. **Notification/NTF delivery stubbed — alerts computed but never sent.** HST parent alerts are a `Log::info` stub with 0 listeners (BUG-HST-006), CAF reorder/FSSAI/low-balance `dispatch()` commented out (BUG-CAF-002), FOF circular distribution is a status-flip with no NTF (BUG-FOF-002).
6. **D29 ENUM in migrations persists.** HST ~35 (MIG-HST-002), CAF ~15 (SCH-CAF-001), INV entry_type (MIG-INV-001).
7. **Process note:** dated module-knowledge snapshots were stale on "0 migrations" for INV (28 exist), CAF (22 exist), and on FOF facts (overstay command exists). Live-code verification corrected each — keep auditing against live code, not snapshots.

### Inventory (INV)
| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| DAT-INV-001 | P0 | Approved stock adjustments never post to ledger (posting loop commented out / FIXME) → balances silently corrupt | `StockAdjustmentService.php:138-163` |
| DAT-INV-002 | P1 | `adjustment` entry-type sign contradiction (postEntry− vs recalculate+) + transfers leave no transfer_in row → recalculate corrupts balances | `StockLedgerService.php:59,92-102,154-161` |
| DAT-INV-003 | P1 | Negative-stock guard reads balance unlocked outside the transaction → TOCTOU oversell; `max(0,…)` clamps the loss | `StockLedgerService.php:63-65,116-123` |
| BUG-INV-001 | P1 | `Events/`+`Listeners/` at module root (outside PSR-4 `app/`) → not autoloaded; `assets.dispose` 500+rollback, nightly `inventory:maintenance-overdue` fatals | `Events/`,`Listeners/`; `app/Providers/EventServiceProvider.php:14-21` |
| JOB-INV-001 | P1 | `ReorderAlertJob` reads/writes tenant tables with no tenancy re-init | `app/Jobs/ReorderAlertJob.php:25-67` |
| DEPLOY-INV-01 | P1 | Closure route breaks `php artisan route:cache` app-wide | `routes/web.php:216` |
| MIG-INV-001 | P2 | `entry_type` hard ENUM (D29) + `variance_qty` plain-writable though DDL intended GENERATED | `…create_inv_stock_entries_table.php:17` |
| PERF-INV-003 | P2 | ~10 unbounded `->get()` over growing ledger tables in report builders | `InventoryReportService.php:36,60,82,…` |
| DAT-INV-004 | P2 | GRN/ADJ/SI/IR numbers + asset tags via `COUNT(*)+1`, no lock/unique → duplicates | `GrnPostingService.php:26-32,223-233`; `StockAdjustmentService.php:232-238` |
| DEAD-INV-003 | P3 | `prs.import` route → "coming soon" stub + orphan duplicate `Events/AssetDisposed.php` | `PurchaseRequisitionController.php:158`; `routes/web.php:113` |

### Hostel (HST)
| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| DAT-HST-001 | P0 | Allotment STORED-generated UNIQUE columns (`gen_active_bed_id`/`gen_active_student_id`) written as inert plain cols → UNIQUE all-NULL, BR-HST-001/002 unenforced; zero `lockForUpdate` → concurrent double-allotment | `…create_hst_allotments_table.php:23-24,44-45`; `AllotmentService.php` |
| MIG-HST-001 | P1 | `hst_mess_bills.total_amount` plain NOT-NULL (not GENERATED per D34/BR-HST-025); omitted from `$fillable` → `MessBill::create()` fails (1364) | `…create_hst_mess_bills_table.php:29`; `MessBill.php:16-46` |
| JOB-HST-001 | P1 | `hst:escalate-complaints` scheduled as bare central command (no `tenants:run`) → SLA escalation never runs per tenant | `HostelServiceProvider.php:150-160`; `EscalateComplaintsCommand.php` |
| BUG-HST-006 | P1 | `SendHstNotificationJob::handle()` is a `Log::info` stub; 0 listeners → all parent alerts (BR-HST-008/017/031/049) undelivered | `Jobs/SendHstNotificationJob.php:40-46` |
| PERF-HST-003 | P1 | `Schema::hasTable()` used as runtime feature-flags (per request/tenant) | `HostelFeeService.php:108,211,225`; `LeavePassService.php:209,260`; `HstAttendanceService.php:145` |
| SEC-HST-004 | P1 | 35/38 FormRequests `authorize()` return bare `true` (D30) | `app/Http/Requests/` |
| DAT-HST-002 | P1 | Non-atomic room/hostel occupancy counters, no lock → drift + missed `full` flip (BR-HST-010) | `AllotmentService.php` create/transfer/vacate |
| VAL-HST-002 | P2 | BR-HST-015 fee-structure check is a soft log, not a hard block | `HostelFeeService::validateFeeStructureExists()` |
| ORM-HST-001 | P2 | Duplicate model→table binding: `BedType`+`HstBedType` → `hst_bed_types`, both live | `BedType.php:13`; `HstBedType.php:14` |
| MIG-HST-002 | P2 | D29 — 29 hst migrations use `->enum()` (~35 calls) | `…create_hst_allotments_table.php:21` et al. |
| TEN-HST-001 | P2 | API route group has no tenancy/auth middleware (latent; api.php empty) | `RouteServiceProvider.php:46` |
| BUG-HST-007 | P2 | `forwardToStudentFee()` hardcoded `return null` → fee demands never pushed (REQ-HST-019 stub) | `HostelFeeService::forwardToStudentFee()` |
| DEAD-HST-002 | P3 | Commented-out Gate in `AuditLogController` | `AuditLogController.php:112` |

### Library (LIB)
| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| BUG-LIB-012 | P0 | `dd($e);` in the live `update()` catch block (fires above `DB::rollBack()`) | `LibBookMasterController.php:481` |
| SEC-LIB-012 | P1 | Fine **waiver** gated by the generic `tenant.lib-fines.update` (same as pay) → any Librarian can waive (BR-LIB-048 Supervisor-only) | `LibFineController.php:339,321` |
| SEC-LIB-013 | P1 | `$transaction->update($request->all())` mass-assignment into `lib_transactions` (D25; fillable exposes member_id/status/dates) | `LibTransactionController.php:314` |
| BUG-LIB-013 | P1 | Fine payment decrements balance by `$payment->amount`, but column is `amount_paid` → NULL decrement, `outstanding_fines` never reduced (BR-LIB-047) | `LibFinePaymentController.php:46-47` |
| DAT-LIB-001 | P1 | Checkout eligibility is unlocked read-modify-write, no transaction → double-issue/over-limit race (BR-LIB-019/021) | `LibTransactionController.php:94-224` |
| VAL-LIB-003 | P1 | Payment not validated vs outstanding balance; no auto-settle (BR-LIB-044/046) | `LibFinePaymentRequest.php:14-23`; `LibFinePaymentController.php:36-58` |
| DAT-LIB-002 | P2 | Unlocked fine settlement; two divergent payment paths | `LibFine.php:143,176`; `LibFineController.php:196-261` |
| SEC-LIB-014 | P2 | Library routes lack module-subscription gate (`tenant.module:Library`) | `RouteServiceProvider.php:41-50` |
| DEAD-LIB-014 | P3 | Unused Vendor import in 18 controllers | `app/Http/Controllers/` |

### FrontOffice (FOF)
| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| DAT-FOF-001 | P1 | Certificate `issue()` has no fee-clearance check for TC/Migration (BR-FOF-005); no `CertificateIssuanceService` | `CertificateRequestController.php:210-238` |
| BUG-FOF-002 | P1 | Circular `distribute()` only flips status — no recipient resolution / per-recipient log / NTF (BR-FOF-018) | `Services/CircularService.php:93-110` |
| SEC-FOF-001 | P1 | Govt-inspection retention guard bypassed: controller calls a permission-string gate so `VisitorPolicy::delete/forceDelete` never runs (BR-FOF-007) | `VisitorController.php:112,169` |
| JOB-FOF-001 | P1 | `EarlyDepartureAttSyncJob` no tenant context + no `$timeout`; queries tenant model/ATT on worker → silent no-op (BR-FOF-013) | `Jobs/EarlyDepartureAttSyncJob.php:26-77` |
| JOB-FOF-002 | P1 | `fof:flag-overstay` exists but is never scheduled and not `tenants:run`-wrapped (BR-FOF-002 never fires) | `FlagOverstayCommand.php`; `FrontOfficeServiceProvider.php:74` |
| VAL-FOF-001 | P1 | Appointment double-booking unchecked (BR-FOF-017) | `AppointmentController.php:62-81`; `AppointmentRequest.php:18-36` |
| SEC-FOF-002 | P1 | Anonymous feedback stores respondent id (BR-FOF-010) | `FeedbackController.php:260-267` |
| BUG-FOF-001 | P1 | `toggleStatus(): JsonResponse` return type unimported → live 500 | `CertificateRequestController.php:151`; `ComplaintController.php:142` |
| SEC-FOF-003 | P1 | All 10 FormRequests `authorize(){return true;}` (D30) | `app/Http/Requests/*.php` |
| DAT-FOF-002 | P2 | Unlocked read-modify-write register numbering across 8 generators (BR-FOF-016) | services + controllers (8 sites) |
| DAT-FOF-003 | P2 | Postal `update()` bypasses acknowledgement-lock (BR-FOF-009) | `PostalRegisterController.php:150-162` |
| DAT-FOF-004 | P2 | Key/gate-pass issue lack row locks (BR-FOF-012/004) | `KeyRegisterController.php:106-130`; `Services/GatePassService.php:20-48` |
| BUG-FOF-003 | P2 | Complaint `escalate` doesn't create a CMP record (BR-FOF-020) | `ComplaintController.php:180-199` |
| SEC-FOF-004 | P2 | Aadhaar stored unencrypted / no masking (BR-FOF-015) | `Models/Visitor.php:20-50` |
| PERF-FOF-001 | P2 | Unbounded `->get()` lists + full student preload | `CertificateRequestController.php:35,43,106`; `KeyRegisterController.php:38-45` |
| DEAD-FOF-001 | P3 | Commented-out feedback expiry guards | `FeedbackController.php:178-180,250-254` |
| BUG-FOF-004 | P3 | Register-number formats deviate from BR-FOF-016 | Complaint/Cert number generators |
| ORM-FOF-001 | P3 | `updated_by => 0` (non-existent user) in background paths | `EarlyDepartureAttSyncJob`; `VisitorService::flagOverstay` |

### Cafeteria (CAF)
| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| SEC-CAF-002 | P1 | Write-side IDOR — sanctum API accepts arbitrary `student_id` (order/scan/dietary-profile) with no ownership check → debit another student's wallet / overwrite another child's medical profile (extends SEC-CAF-001) | `OrderController.php:83-93`; `MealAttendanceController.php:24`; `DietaryProfileController.php:112` |
| SEC-CAF-003 | P1 | All 19 FormRequests `authorize(){return true;}` (D30) | `app/Http/Requests/*` |
| DAT-CAF-001 | P1 | Order-cancel double-refund race — status guard has no `lockForUpdate`/conditional re-check → concurrent cancels credit wallet twice | `OrderService.php:116-139` |
| JOB-CAF-001 | P1 | `caf:*` commands scheduled in central context without `tenants:run` → query `caf_*` against central DB → automation dead | `CafeteriaServiceProvider.php:111-117` |
| BUG-CAF-001 | P2 | Dietary-conflict (BR-CAF-002) not enforced in order/POS | `OrderService.php:29`; `PosService.php:44` |
| BUG-CAF-002 | P2 | NTF dispatch stubbed (commented) — reorder/FSSAI/low-balance alerts (BR-CAF-007/014/017) never fire | `StockService.php:60,136`; `MealCardService.php:101-104` |
| VAL-CAF-001 | P2 | BR-CAF-020 unenforced — multiple open POS sessions/day | `PosService.php:23-29` |
| SCH-CAF-001 | P2 | D29 — ~15 ENUM columns in CAF DDL | `Cafeteria_DDL_v1.sql` |
| FE-CAF-001 | P2 | `json_encode()` chart payloads without `JSON_HEX_*` (embed staff names) | `reports-page/index.blade.php:123-283`; `pages/dashboard.blade.php:276` |
| DEAD-CAF-001 | P3 | Duplicate dead `CafeteriaServiceProvider` at module root | `Modules/Cafeteria/Providers/CafeteriaServiceProvider.php` |
| DAT-CAF-002 | P3 | Wallet balance columns in `$fillable` (latent ledger bypass; no current sink) | `MealCard.php:19-22` |
| BUG-CAF-003 | P3 | Order cutoff silently skipped when `meal_start_time` NULL | `OrderService.php:212-216` |

> `SEC-INV-001` (FormRequests authorize true; now 19) and `SEC-INV-002` (reject uses `grn.accept`) were re-confirmed by the INV audit, not re-registered.

---

## Mode D Sweep — D36 GENERATED-Column Degradation (2026-06-29)

> Full report: `3-Audit_Reports/V1_Jun-2026/ModeD_Sweep_GeneratedColumns_2026-06-29.md` · Pattern: `state/decisions.md` D36.
> **Platform fact:** of ~19 DDL `GENERATED ALWAYS` columns, only **`sys_users.super_admin_flag`** is correctly generated in the live migrations; only 2 of ~700 tenant migrations use `storedAs/virtualAs`. Already-registered instances: DAT-HST-001, MIG-HST-001, MIG-INV-001. New instances below.

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| MIG-PTM-001 | P1 | `ptm_slot_bookings.active_booking_key` (DDL `GENERATED…CASE WHEN status='CONFIRMED' THEN student_id`) shipped as plain column → UNIQUE all-NULL, double-confirmed-booking not blocked | `migrations/tenant/...create_ptm_slot_bookings_table.php` ; `Sch_PTM_DDL_v3.sql:353` |
| MIG-FIN-001 | P1 | `fee_invoices.balance_amount` (DDL `GENERATED…total_amount-paid_amount`) shipped plain → invoice balance wrong/driftable (financial) | `migrations/tenant/...create_fee_invoices_table.php` ; `StudentFee_DDL_v4.sql:321` |
| MIG-VND-001 | P1 | `vnd_invoices.balance_due` (DDL `GENERATED…net_payable-amount_paid`) shipped plain → AP balance wrong (financial) | `migrations/tenant/...create_vnd_invoices_table.php` ; `Vendor_DDL_v2.1.sql:193` |
| MIG-SCC-001 | P1 | `sch_academic_term.current_flag` + `sch_org_academic_sessions_jnt.current_flag` (DDL GENERATED) shipped plain → ">1 current term/session" possible (unique-active broken) | `migrations/tenant/...create_sch_academic_term_table.php`, `...create_sch_org_academic_sessions_jnt_table.php` |
| MIG-STD-001 | P1 | `std_student_academic_sessions.current_flag` (DDL `GENERATED…IF(is_current=1,student_id,NULL)`) shipped plain → >1 current session per student | `migrations/tenant/...create_std_student_academic_sessions_table.php` ; `StudentProfile_DDL_v1.6.sql:222` |
| MIG-TT-001 | P2 | Timetable derived columns shipped plain: `tt_period_set.total_periods`, `tt_room_availability.available_for_full_timetable_duration`, TIMESTAMPDIFF `duration_minutes` | `migrations/tenant/...create_tt_period_set_table.php`, `...create_tt_room_availability_table.php` ; `Timetable_DDL_v7.8.sql:420,1096` |

**Tracked under D36, module code to confirm before coding:** EmployeeSetup `sch_employees_profile.active_flag`, `sch_employee_shift_assignments.active_flag`, `sch_teacher_capabilities.active_flag` (unique-active, P1) and `sch_employee_leave_balance.available_balance` (DDL `GENERATED…opening+carry-used`, leave-balance integrity / D26, P1).
**Absent entirely (flag when module ships):** CommonChat `cht_*.dm_pair_hash`; Timetable `tt_*.no_of_days_not_available`.
**Excluded (name-collision false positives, verified plain in own DDL):** 10× `total_amount` (acc_/caf_/inv_/tpt_/fee_), 4× `duration_minutes` (lms_/slb_ user-input).

### Transport (TPT) — Mode A Deep Audit (2026-06-29)
> Full report: `3-Audit_Reports/V1_Jun-2026/Transport_Technical_Audit_2026-06-29.md`. Health 38/100 (P0 cap). Verified vs LIVE code.

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| BUG-TPT-011 | P0 | `dd($e)` in the live bulk trip-update catch block — halts request + dumps stack | `TripController.php:587` |
| FE-TPT-001 | P1 | Hardcoded Google Maps API key shipped to browser (committed secret) in 3 views | `pickup_point/create.blade.php:165`, `edit.blade.php:171`, `pickup_point.blade.php:94` |
| VAL-TPT-001 | P1 | All 19 FormRequests `authorize(){return true;}` (D30) | `app/Http/Requests/*.php` |
| PERF-TPT-001 | P1 | God controllers (Mobile 1984 / Report 1054 / Trip 800) + eager tab loads + unbounded `::all()`; 0 service classes for 30 controllers | `Mobile/MobileTransportController.php`; tab controllers |
| MIG-TPT-001 | P2 | `tpt_trip.status` is free-text `string(20)` not a dropdown FK; trip FSM compares string literals; `is_active` missing on `tpt_trip` (DB-03/10..13) | `migrations/tenant/...create_tpt_trip_table.php:24` |
| DEAD-TPT-002 | P2 | Orphan `TransportController.php-old` committed (prior dead route ref) | `app/Http/Controllers/TransportController.php-old` |

**Re-confirmed OPEN (2026-06-29):** SEC-TPT-004 (`updateLastSeen()` ungated + force-sets `is_active=true`, `AttendanceDeviceController` ~:261); SEC-TPT-005 (Aadhaar/licence plaintext — `DriverHelper` `$casts` has no `encrypted`, `id_no:31`/`license_no:36`); TEN-RTG-001 (Transport among 25/26 module groups with no `EnsureTenantHasModule` — RSP stack lacks it).

**FIXED since 2026-06-25 snapshot (verified live):** SEC-TPT-003 / SEC-TPT-010 (`tested.` gate typo on `AttendanceDeviceController` → now `tenant.attendance-device.*` on all 10 gated methods); capacity enforcement IMPLEMENTED (`StudentAllocationController:137`, BR-TPT-001 100% block); allocation atomic (`DB::transaction` at `:74,488`, BR-TPT-009); D29 baseline "tpt 19 enums" wrong → **0 enums** in tpt migrations (status is VARCHAR, MIG-TPT-001). D36 N/A (no GENERATED columns in TPT).

---

## Complete Audit — Admission (ADM) — 2026-06-29 (Mode X)

Full report: `3-Audit_Reports/V1_Jun-2026/Admission_Complete_Audit_2026-06-29.md`. Health 40/100 (P0 cap). DEPLOY: NO-GO. Strong tenancy + per-controller authz; defects are module-local logic + unbuilt automation.

| Code | Sev | Issue | Location |
|------|-----|-------|----------|
| BUG-ADM-004 | P0 | App FSM transitions to `'Under Review'`/`'Selected'` — neither is in `adm_applications.status` ENUM; `'Selected'` is the required pre-state for `Enrolled` → enrolment pipeline (REQ-ADM-015) cannot complete | `AdmissionPipelineService.php:18-28,96,120`; migration `...083610...:59`; `EnrollmentService.php:155` |
| DATA-ADM-001 | P1 | Seat over-allotment guard (BR-ADM-013) absent; cited `MeritListService::allotSeat()` does not exist; `seats_allotted` never incremented; no lock | `AllotmentController.php:60-74` |
| BUG-ADM-005 | P1 | `admission_no` never generated at offer/allotment; offer-letter PDF prints NULL admission no | `AllotmentController.php:60-74,150-159` |
| SEC-ADM-001 | P1 | Aadhar/PII plaintext (no `encrypted` cast); copied plaintext to `std_students.aadhar_id` (NFR-ADM-005/010) | `Application.php:59,103-114`; `EnrollmentService.php:103` |
| BUG-ADM-006 | P1 | Merit scoring wrong: interview computed but excluded from composite; weights hardcoded 0.40+0.40+0.30; criteria_json ignored; no cutoff→Rejected / seat→Waitlist (BR-010c/010d) | `MeritListService.php:56-103` |
| BUG-ADM-007 | P1 | TC fee-clearance gate (BR-ADM-004) is a stub — logs warning and issues anyway; no fin_invoices check | `TransferCertificateService.php:38-44` |
| JOB-ADM-001 | P1 | Waitlist auto-promotion/offer-expiry unbuilt (REQ-ADM-013/BR-014); no Jobs/Console; decline doesn't free seat | module-wide |
| VAL-ADM-001 | P1 | Age eligibility (BR-ADM-001) not enforced; `age_rules_json` never read | `StoreApplicationRequest.php:31`, `StoreEnquiryRequest.php:21` |
| VAL-ADM-002 | P1 | Aadhar service-layer uniqueness (BR-ADM-012) not implemented | application create path |
| SEC-ADM-003 | P1 | D30 — 24/24 FormRequests `authorize(){return true;}` (downgraded: controllers do gate) | `app/Http/Requests/*.php` |
| DATA-ADM-002 | P2 | Number generators + enrolment lack row locks (race / double-enrol) | `Application.php:19-38`; `EnrollmentService.php:61-65,185-204` |
| SEC-ADM-002 | P2 | TC PDF to `Storage::disk('local')`, un-prefixed path (cross-tenant risk); media_id never persisted | `TransferCertificateService.php:65-66` |
| DATA-ADM-003 | P2 | 29 `->enum()` columns in ADM migrations (D29) | adm migrations |
| BUG-ADM-008 | P2 | Notifications entirely unimplemented; EventServiceProvider `$listen=[]` (RISK-ADM-005; BR-018b/022 cannot fire) | module-wide; `EventServiceProvider.php:14` |
| DEAD-ADM-001 | P2 | Stub `AdmissionController` apiResource (empty store/update/destroy) on live auth route | `AdmissionController.php:29,50,55`; `api.php:6-8` |
| PERF-ADM-001 | P2 | `lockForUpdate` on compute step (read-only) instead of the allotment path | `MeritListService.php:46-49` |

**RESOLVED since prior snapshot (verified live 2026-06-29):** BUG-ADM-003 — `AdmissionPipelineService` now uses `$application->admission_cycle_id` (`:74`); old `cycle_id` reference gone.
**Snapshot CORRECTION:** "ADM has 0 migrations" is WRONG — 20 ADM tenant migrations exist (`database/migrations/tenant/2026_06_16_0836*_create_adm_*_table.php`). Cross-DB FK / INT-PK / D24 / D25 / 6.2-leak all CLEAN in ADM (better than platform norm).

## Complete Audit — BehaviouralAssessment (BA) — 2026-06-29 (Mode X: A+B+C+G + scoped D)
Report: `3-Audit_Reports/V1_Jun-2026/BehaviouralAssessment_Complete_Audit_2026-06-29.md`. Health **57/100 (Amber)**, Deploy **GO (conditional)**, **no P0**. New codes use the `*-BA-*` prefix (prior partial audit used `*-BEH-*`; same defects cross-referenced, not double-counted). Strengths (better than platform norm): web RSP carries full tenancy+auth+verified stack; every controller method `Gate::authorize`d with a uniform `tenant.behavioural-assessment.*` prefix (no D24/D25/6.2/D17/cross-DB-FK). DDL has no GENERATED columns → D36 N/A. Worst area = workflow/data-integrity, not security.

**CORRECTION to prior snapshot:** `SEC-BEH-002` ("no auth middleware on web routes") is a **FALSE POSITIVE** — auth/tenancy live in `Modules/BehaviouralAssessment/app/Providers/RouteServiceProvider.php:24-31` (`web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified`), not in `web.php`. Web routes ARE protected. Retire SEC-BEH-002.

| Code | Severity | Issue | Location |
|------|----------|-------|----------|
| BUG-BA-001 | P1 (P0 if integration on) | Ratings editable after submit/approve/lock; `bulkRate`/`autoSave` only block `status==='locked'` which is never set; period `lock()` doesn't cascade to assessments → published scores diverge from audit trail (BR-BA-026/012/019) | `BaAssessmentController.php:285,452`; `BaAssessment.php:86-89`; `BaAssessmentPeriodController.php:147-161` |
| BUG-BA-002 | P1 | Period FSM violated — `lock()` allows open→locked, `unlock()` locked→closed (FRD: locked terminal); no `close()` action exists so open→closed (BR-BA-012) is unreachable | `BaAssessmentPeriodController.php:147-177` |
| SEC-BA-001 | P1 | Severe-incident parent notification (REQ-BA-015/BR-BA-013, P0 req) ENTIRELY ABSENT — zero `Notification`/event/`dispatch` in module; `is_notified` never set; `parent_notification_threshold` is dead config (ENH-BA-004) | `BaIncidentController.php:74-133`; module-wide |
| DATA-BA-001 | P1 | BR-BA-029 not enforced — `rating_scale_id` freely updatable after ratings exist (corrupts score interpretation) | `BaConfigController.php:65-74`; `BaConfigRequest.php:25-33` |
| VAL-BA-001 | P1 | No FormRequests for BaAssessment/BaIncident/BaClassCategory; 20-rule block copy-pasted across incident store/update (= VAL-BEH-001/002) | `BaAssessmentController.php:55,289,456`; `BaIncidentController.php:52,159`; `BaClassCategoryController.php:20` |
| SEC-BA-002 | P1 (systemic D30) | All 5 FormRequest `authorize()` return bare `true` — mitigated by controller gates (defense-in-depth gap, not open hole) (= SEC-BEH-001) | `app/Http/Requests/*Request.php:12-15` |
| BUG-BA-004 | P2 | BR-BA-006 not enforced — criterion with ratings can be soft-deleted | `BaCategoryController.php:190-196` |
| BUG-BA-005 | P2 | BR-BA-030 not enforced — in-use intervention can be soft-deleted | `BaInterventionController.php:69-81` |
| BUG-BA-006 | P2 | BR-BA-005 — category soft-delete does not cascade to criteria | `BaCategoryController.php:74-86` |
| BUG-BA-007 | P2 | BR-BA-009 permissive default missing — unmapped class → empty grid (`whereIn([])`) | `BaAssessmentController.php:115-121,379-381` |
| BUG-BA-008 | P2 | Follow-up notes overwritten not appended (REQ-BA-012) | `BaIncidentController.php:340-345` |
| BUG-BA-009 | P2 | BR-BA-028 not enforced — multiple `is_default` scales possible | `BaRatingScaleController.php:31-64` |
| VAL-BA-002 | P2 | Level `numeric_value` not range-checked vs scale [min,max] (BR-BA-003); duplicate student witness 500s (no `distinct`, uses `create()` not `firstOrCreate`) | `BaRatingScaleController.php:132-150`; `BaIncidentController.php:68,107-116` |
| DATA-BA-002 | P2 | Score recompute synchronous in approve() request; no queued job (ENH-BA-003/RISK-BA-003) | `BaAssessmentController.php:413`; `BehaviouralScoreService.php:24-76` |
| DATA-BA-003 | P2 | Soft-delete + UNIQUE without `deleted_at` (uq_ba_assessment/_rating/_score/_witness) → recreate-after-delete 500 | BA create migrations |
| DATA-BA-004 | P2 | Incident create not wrapped in DB::transaction (incident+jnts+4 audit logs) | `BaIncidentController.php:74-129` |
| MIG-BA-001 | P2 (D29) | 11 ENUM columns in migrations (match DDL; FSM enums defensible, location/severity are dropdown candidates) | BA create migrations |
| DEAD-BA-001 | P2 | Empty scaffold `BehaviouralAssessmentController` behind live `auth:sanctum` apiResource with NO tenancy middleware (= BUG-BEH-001/DEAD-BEH-001) | `BehaviouralAssessmentController.php:29,50,55`; `api.php:6-8` |
| BUG-BA-011 | P2 | `BaReportController::export()` permanent `abort(501)` on live route (= BUG-BEH-002) | `BaReportController.php:475-479` |
| VAL-BA-003 | P3 | BR-BA-010 boundary: `after_or_equal` allows start==end (FRD: start<end) | `BaAssessmentPeriodRequest.php:23` |
| SEC-BA-003 | P3 | `status` settable directly via `BaAssessmentPeriodRequest` (back-door around lock/unlock FSM) | `BaAssessmentPeriodRequest.php:25` |
| DOC-BA-001 | P3 | DDL doc `BehaviouralAssess_DDL_v2.sql` stale `bha_` vs live `ba_` (structures match) — regenerate (RISK-BA-001) | `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` |

**Mode C tally:** 30 BR → 15 ENFORCED · 6 PARTIAL · 9 MISSING (missing: BR-005,006,009,012,013,025,028,029,030). **Tests: 0** (RISK-BA-002). PERF-BEH-001..004 re-confirmed (referenced as PERF-BA-001..004).

## Certificate (CRT) — Technical Audit Mode X (2026-06-29)

> Report: `3-Audit_Reports/V1_Jun-2026/Certificate_Complete_Audit_2026-06-29.md`. **Health 66/100, no P0 (uncapped). P0=0 · P1=6 · P2=6 · P3=5.** Well-gated, full tenancy stack, correct serial `lockForUpdate`; undermined by a wrong-table/column cluster in integration paths. **0 in-module Pest tests** (Dusk ~45 only) — a single seeded feature test would have caught BUG-CRT-001..004 (RISK-CRT-004).

| Code | Sev | Issue | Location |
|------|-----|-------|----------|
| BUG-CRT-001 | P1 | TC fee gate hits non-existent `fin_fee_invoices`/`payment_status`/`net_payable`/`student_id` (table is `fee_invoices`, linkage `student_assignment_id`, col `status='Paid'`, amt `balance_amount`) → `generateTC()` always throws; REQ-CRT-005 dead; BR-CRT-001 override never built | `CertificateGenerationService.php:91-94` |
| BUG-CRT-002 | P1 | `generateTC()` joins `std_students.class_id/section_id` (absent), reads `date_of_birth` (col `dob`), queries `std_profiles` (table is `std_student_profiles`) | `CertificateGenerationService.php:119-146` |
| BUG-CRT-003 | P1 | ID-card sheet gen repeats same wrong joins (`class_id/section_id`,`std_profiles`,`date_of_birth`) → REQ-CRT-008 generate throws | `IdCardGenerationService.php:82-94` |
| BUG-CRT-004 | P1 | DMS upload inserts `media_id=>0` into NOT NULL FK→sys_media → 23000 FK violation; REQ-CRT-009 store() fails for every doc | `StudentDocumentController.php:65-81`; migration `...083600:30-31` |
| VAL-CRT-001 | P1 | BR-CRT-023 not enforced — TC leaving date/reason nullable + silent defaults (`today()`/`'Transfer'`) | `ApproveCertificateRequestRequest.php:18-22`; `CertificateRequestController.php:144-154` |
| SEC-CRT-001 | P1 | Keyed verify API (REQ-CRT-007 AC4/BR-CRT-027) = empty scaffold `CertificateController`; apiResource returns Blade views | `CertificateController.php`; `api.php:6` |
| BUG-CRT-005 | P2 | restore/forceDelete always 403 on Issued/Request/Template (policies lack those abilities, no `before()`); fail-closed | `Certificate{Issued,Request,Template}Policy.php`; controllers `:150,161 / :202,213 / :297,308` |
| DATA-CRT-001 | P2 | {{father_name}}/{{mother_name}}/{{blood_group}} always blank (`std_student_profiles` lacks cols); {{nationality}}/{{religion}} emit raw FK ids; BR-CRT-007 unenforced | `CertificateGenerationService.php:262,280-284` |
| SEC-CRT-002 | P2 | No `EnsureTenantHasModule` (TEN-RTG-001) — off-plan tenants can access CRT | `RouteServiceProvider.php:28-44` |
| DEAD-CRT-001 | P2 | Dead scaffold `CertificateController` (missing views, empty writers) | `CertificateController.php` |
| PERF-CRT-001 | P2 | BR-CRT-033 overdue-request highlight not implemented (RPT-CRT-002 partial) | `CertificateReportController.php` |
| SCH-CRT-001 | P2 (D29) | ~10 ENUM cols (status/category/card_*/recipient_type) | crt create migrations |
| VAL-CRT-002 / DAT-CRT-002 / SCH-CRT-002 / JOB-CRT-001 / BUG-CRT-006 | P3 | D30 10/10 (gated); serial first-of-year race; INT PK; bulk `tries=1`; merge `academic_year` precedence smell | (see report) |

**Mode C tally:** 34 BR → 26 ENFORCED · 2 PARTIAL (BR-007,028) · 5 MISSING/BROKEN (BR-001,023,027,033 + BR-008 reachable-only) · 1 N/A (BR-034, portal). **Cleaner than baseline:** 0 `$request->all()`, 0 D17, 0 prefix typos, 0 cross-DB FK, 0 initialize leaks, job tenancy correct.
**FALSE POSITIVES corrected:** `sys_dropdowns` & `sys_activity_logs` exist in tenant_db (verified); RISK-CRT-005 mitigated by `suffix_storage_path=true`.

---
## CommonChat (COM / cht_) — Technical Auditor Mode X — 2026-06-29
Source: 3-Audit_Reports/V1_Jun-2026/CommonChat_Complete_Audit_2026-06-29.md

### P0
- **MIG-COM-001** — `cht_permission_config` declares 2 FKs to `sys_roles` (migration `2026_06_16_100703...:32,:36`); `sys_roles` has NO create migration anywhere → `tenants:migrate` fails errno 150/1824. Deploy blocker. (Layer 2.5 systemic; +2 to the platform `sys_roles` FK count.)

### P1
- **SEC-COM-001** — Attachments stored on `public` disk + served via `Storage::disk('public')->url()` (`ChatAjaxController.php:479,506,508`); no auth/membership gate → confidential files world-readable by URL (violates NFR-COM-006/REQ-COM-007).
- **JOB-COM-001** — `chat:purge-old-messages` scheduled in CENTRAL context (`CommonChatServiceProvider.php:82`), no `tenants:run`/tenancy init → retention purge never runs per-tenant (REQ-COM-020 non-functional). No withoutOverlapping/onOneServer.
- **BUG-COM-001** — `ChatService::deleteMessage:365` hardcodes `hasAnyRole(['super-admin','principal'])`; inconsistent with policy `tenant.chat.moderate` and `canInitiateDm` short_names → admin moderation/delete fails for valid moderators.
- **BUG-COM-002** — `createGroup:224` `count(memberIds) >= maxMembers` off-by-one; blocks below the configured cap (BR-COM-010). GAP-COM-008.
- **DAT-COM-001** — `cht_messages.body` is VARCHAR(2000) but StoreMessageRequest/AJAX/BR-COM-016 allow 5000 chars → 2001–5000-char messages truncate/SQLSTATE 22001.
- **VAL-COM-001** — Reply integrity unenforced: `parent_message_id` only `exists:cht_messages,id`; no same-conversation check (BR-COM-018) and no depth-1 check (BR-COM-019). Cross-conversation reply + content leak possible.
- **BUG-COM-003** — PII `Log::debug` of user ids/names/roles on every user search (`ChatController.php:210,218,227`).
- **BUG-COM-004** — Moderation/audit writes to `sys_activity_logs` (+SHA-256 body hash) not implemented (REQ-COM-019/BR-COM-037/038). GAP-COM-003.
- **BUG-COM-005** — Notification (NTF) integration absent; `EventServiceProvider $listen=[]` (REQ-COM-012). GAP-COM-004.
- **BUG-COM-006** — Seeder uses role display-names, service uses short_name, deleteMessage uses hyphen slugs → permission resolution inconsistent. GAP-COM-005.

### P2
- **DATA-COM-002** — `cht_messages.message_type` ENUM default `'text'` invalid vs members `Attachment/System/Text`. GAP-COM-006.
- **SEC-COM-002** — `is_deactivated_by_admin` not enforced in send/receive (REQ-COM-022/BR-COM-040). GAP-COM-010.
- **VAL-COM-002** — permission-config uniqueness (BR-COM-036) not validated at request layer (DB index only → 500 on dup).
- **SEC-COM-003** — `ChatAjaxController` bypasses Policy gates (only abort_unless+participant firstOrFail); announcement post-restriction (BR-COM-014) not enforced on AJAX/service path.
- **PERF-COM-001** — message search `LIKE %term%`, no FULLTEXT (GAP-COM-012).
- **SCH-COM-001** — D29: 3 ENUMs (conversation_type, participant role, message_type).
- **TEST-COM-001** — zero tests (GAP-COM-001).

### P3
- **DEAD-COM-001** — `CommonChatController` scaffold stub (empty store/update/destroy; returns nonexistent create/edit/show views); `api.php commonchats` group has no tenancy middleware. GAP-COM-011.
- Notes: `$request->all()` into service (4 sites, filtered, P3); `is_deactivated_by_admin` in personalization fillable (latent); `increments('id')` on 2 cht tables.

### Good patterns (not findings)
- All 5 FormRequests delegate `authorize()` to policies (not bare `true` — beats D30 norm).
- `dm_pair_hash` VIRTUAL generated col + UNIQUE correctly emitted (beats D36 norm).
- Web RSP + mobile (`tenant.mobile`) carry full tenancy stack; `{!! nl2br(e($body)) !!}` escapes safely.

---

## Billing (BIL) — Technical Audit (Mode X) — 2026-06-29

Report: `3-Audit_Reports/V1_Jun-2026/Billing_Complete_Audit_2026-06-29.md`. Central/prime_db module. Health **37/100 (P0 cap), DEPLOY: NO-GO**. Schema authority = `prime_db_v4.sql` (0 migrations). NEW codes (existing SEC-BIL-001/002/005, BUG-BIL-005 reused — see report).

| Code | Severity | Issue | File:Line |
|------|----------|-------|-----------|
| MIG-BIL-001 | P0 | SoftDeletes + default timestamps on every model, but `prm_billing_cycles`/`bil_*` tables have no `deleted_at` (cycles: no timestamps either; audit_logs: no `updated_at`) → all CRUD throws Unknown column on DDL-fresh DB | Models *.php:12-16 vs prime_db_v4.sql:405,545,603,623 |
| DATA-BIL-001 | P0 | Audit-log model/relations/6 inserts use `tenant_invoicing_id`; DDL col is `tenant_invoice_id`; also no `updated_at` | InvoicingAuditLog.php:17,32 ; inserts InvoicingPaymentController:79,221 + BillingManagementController:500,564,795,923 |
| DATA-BIL-002 | P0 | BilTenantInvoice `$fillable` phantom `invoice_amount` (not in DDL) + 8 duplicated fields | BilTenantInvoice.php:20-69 |
| SEC-BIL-001/002 | P0 | Payment `store()`/`consolidatedStore()` open DB transaction with no rollback; consolidatedStore early-returns inside open tx | InvoicingPaymentController.php:52,100,158,164,247 |
| SEC-BIL-005 | P1 | `Tenancy::initialize()/end()` without try/finally inside generation tx (context-leak risk) | BillingManagementController.php:670-674 |
| SEC-BIL-010 | P1 | 9 routed methods no Gate::authorize incl. a note-edit WRITE (auth'd users only, not anon) | InvoicingPaymentController:108,257,307 ; InvoicingAuditLogController:78,87,101,113 ; SubscriptionController:92,105 |
| SEC-BIL-011 | P1 | Raw `$request->all()` stored in audit `event_info` (BR-BIL-022 violation) | InvoicingPaymentController.php:94 |
| BUG-BIL-010 | P1 | Invoice status taken from request, not derived from cumulative paid (BR-BIL-023) | InvoicingPaymentController.php:75 |
| BUG-BIL-011 | P1 | generateInvoiceForOrganization returns bool false but store() reads $result['status']/['message'] | BillingManagementController.php:646 vs 612-617 |
| BUG-BIL-015 | P1 | Invoice number `count()+1` race, no lock (BR-BIL-006) | BillingManagementController.php:660-662 |
| BUG-BIL-005 | P2 | Consolidated print: getCollection() on Collection + isNotEmpty() on float → fatal (RPT-BIL-003) | BillingManagementController.php:171-173 |
| BUG-BIL-013 | P2 | Broken route billing-management.view → @view (no method) | routes/web.php:332 |
| BUG-BIL-014 | P2 | Central billing route block registered 3× | routes/web.php:312,559,889+ |
| DATA-BIL-003 | P2 | Missing created_by/is_active; email-schedule no FK on invoice_id; modules_jnt FK→glb_modules VIEW | prime_db_v4.sql:594,636 |
| VAL-BIL-001 | P2 | ConsolidatedPaymentRequest no array rules; both payment FormRequests authorize()=true (D30) | ConsolidatedPaymentRequest.php:9 ; StoreInvoicePaymentRequest.php:12 |
| JOB-BIL-001 | P2 | SendInvoiceEmailJob no tries/backoff/timeout/failed(); auth()->id() null on worker | SendInvoiceEmailJob.php:17-52 |
| PERF-BIL-001 | P2 | Sync ZIP + temp PDFs never unlinked; index Tenant::get()+User::get() unbounded | BillingManagementController.php:489-525,118 ; SubscriptionController.php:74-84 |
| DEAD-BIL-001 | P2 | Dead policies (last-wins reg) + imports of non-existent App\Models\ConsolidatedPayment/PaymentReconciliation | BillingServiceProvider.php:64-70 |

### Good patterns / refuted (not findings)
- Auth NOT bypassed: Spatie/super-admin `Gate::before` at `app/Providers/AppServiceProvider.php:65-74` resolves dotted abilities; policies are dead but harmless.
- Invoice generation IS atomic (`DB::transaction` closure, BillingManagementController:636) and BR-007/009/010/011/012 formulas match the FRD exactly.
- BillingCycleRequest is a clean FormRequest (beats D30 norm).

---

## Complete Audit — HPC (Mode X) — 2026-06-29

> Technical Auditor read-only Mode X (A+B+C+G + scoped D) against `HPC_FRD_Complete_2026-06-29.md`.
> Report: `3-Audit_Reports/V1_Jun-2026/Hpc_Complete_Audit_2026-06-29.md`. Health 40/100 (P0-capped). **Deploy: NO-GO.**
> New codes continue the existing HPC series (prior max: BUG-HPC-016, SEC-HPC-004, PERF-HPC-004).

| Code | Severity | Issue | Location |
|------|----------|-------|----------|
| BUG-HPC-016 | P0 | **CONFIRMED OPEN** — `generateReportPdf()` has no `Gate::authorize()`; any authenticated user generates/distributes any student's confidential card. Sibling `generateSingleStudentPdf()` (line 2290) gates correctly. | `Modules/Hpc/app/Http/Controllers/HpcController.php:1255` |
| DAT-HPC-001 | P0 | `hpc_reports.status` ENUM = 4 PascalCase values (`Archived,Draft,Final,Published`) but model FSM writes 6 lowercase states (`submitted,under_review,…`); default `'Draft'` is not a `TRANSITIONS` key → workflow aborts 422 / MySQL rejects out-of-enum writes. Breaks "Built" REQ-HPC-013. D29+D17. (BA: GAP-DB-003) | migration `…create_hpc_reports_table.php:17`; `HpcReport.php:24-48`; `HpcWorkflowService.php:16-129` |
| MIG-HPC-001 | P0 | `hpc_reports` migration missing 9 columns the model/workflow write: `submitted_at, reviewed_by, reviewed_at, review_comments, published_by, published_at, student_sections_complete, parent_sections_complete, created_by` → every workflow `update()` throws `42S22 Unknown column`. D17. (BA: GAP-DB-003) | migration `…create_hpc_reports_table.php` vs `HpcReport.php:50-69` |
| DAT-HPC-002 | P0 | 5 model-backed tables do not exist (no migration): `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_student_form_submissions`, `hpc_student_hpc_snapshot`. Live-routed student/parent/peer services hit them → `42S02 table not found`. D17. (BA: GAP-DB-004b/c/d, 005, 006) | `ParentHpcFormService`, `PeerAssignmentService`, `StudentHpcFormService` |
| SEC-HPC-002 | P1 | **STILL OPEN** — public `GET /hpc/hpc-view/{id?}` decrypts an encrypted student-id and serves the card with no access-code / no expiry check (REQ-HPC-014.4 unmet). Confidential child data, unauthenticated, indefinite. | `routes/web.php:16-18` → `HpcController::viewPdfPage()` line 1998 |
| QUAL-HPC-001 | P1 | `HpcController` = 2,611 lines (Layer 4.4 >2000 = urgent decompose); BUG-HPC-016 is a direct symptom. | `HpcController.php` |
| SEC-HPC-003 | P2 | **REGRESSED** (was marked FIXED) — `EnsureTenantHasModule:Hpc` middleware exists but is NOT applied in the module RSP/web.php; tenant without HPC entitlement can access all features (NFR-HPC-04). | `Modules/Hpc/app/Providers/RouteServiceProvider.php:41-47`; `routes/web.php:21` |
| VAL-HPC-001 | P2 | BR-HPC-009 50-student bulk cap NOT enforced (`generateReportPdf` validates only `min:1`); unbounded synchronous PDF gen → timeout/OOM. Module-knowledge claim of inline enforcement was stale. | `HpcController.php:1257-1261` |
| DEAD-HPC-001 | P2/P3 | Orphan tables `hpc_curriculum_change_request`, `hpc_lesson_version_control` migrated with ENUMs (D29), no model/controller/route (REQ-HPC-019 Not Built). | migrations `2026_06_16_132249`, `2026_06_16_132300` |

### Good patterns / refuted (not findings) — HPC
- **Tenancy clean (Layer 6):** module `RouteServiceProvider` applies `InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive`; `SendHpcReportEmail` re-inits tenancy and ends in `finally` (baseline "good template").
- **D25 clean:** the 4 `$request->all()` hits are safe `->paginate()->appends()`; `formStore` uses `$request->except()`.
- **D30 clean:** the 4 template FormRequests carry real conditional `Gate` logic (not bare `return true`).
- **D24 clean:** all gates use `tenant.hpc*` consistently; no typos/dup prefixes.
- **BR-HPC-011 enforced:** `downloadZip()` sanitizes filename `[A-Za-z0-9_\-.]` + gates `tenant.hpc.viewAny` (SEC-HPC-006 effectively mitigated; strip-vs-reject deviation is P3).
- **SEC-HPC-002/003 numbering note:** the `module-knowledge/HPC_Hpc.md` SEC-HPC-001..006 local numbering diverges from this registry's SEC-HPC-001..004; this audit uses the **registry** numbering.

---

## Documentation (DOC) — Complete (Mode X) Audit, 2026-06-29

> Central module. Report: `3-Audit_Reports/V1_Jun-2026/Documentation_Complete_Audit_2026-06-29.md`.
> Health 40/100 (P0-capped). Deploy NO-GO. 1 P0 · 7 P1 · 5 P2 · 2 P3. (No prior DOC-* codes existed.)

### [SEC-DOC-001] Stored XSS — unsanitised article HTML rendered raw (P0)
- **Module/Area:** Documentation reader/show + content store
- **Symptom:** Summernote `content` stored verbatim and emitted via `{!! $article->content !!}` (main-doc/index.blade.php:97, article/show.blade.php:128) and base64→`atob`→`innerHTML` (footer.blade.php:239); `mews/purifier` not installed.
- **Root Cause:** No sanitisation at save (DocumentationArticleController.php:65; ValidateArticleRequest 'content'=>'required|string') nor at render.
- **Fix:** Install/clean with purifier at save + safe render; stop base64→innerHTML; restrict Summernote tags.
- **Prevention:** Any rich-text field needs sanitise-at-save AND safe render. Maps REQ-DOC-012/BR-DOC-014.

### [DATA-DOC-001] Reader orderBy('sort_order') on doc_articles — column absent (P1)
- **Symptom:** mainDoc (DocumentationController.php:90) + getArticlesByCategory (:117) → SQL 42S22, reader 500.
- **Root Cause:** Migration creates no sort_order on doc_articles; column also (wrongly) in Article::$fillable (D17).
- **Fix:** Add doc_articles.sort_order migration (or drop orderBy + fillable entry).

### [BUG-DOC-001] store() gates on ungranted '.store' ability — non-super-admins locked out of create (P1)
- **Symptom:** Article/Category `store()` 403 for App Maintenance/Content Author roles.
- **Root Cause:** `prime.documentation-*.store` not in `config/permissionslist.php $crud` → never flattened/seeded; Gate::before bypasses Super Admin only.
- **Fix:** Change both store() gates to `.create`. (BR-DOC-022)
- **Prevention:** Verify Gate strings against `$crud` vocabulary, not just seeder role groups.

### [BUG-DOC-002] Article create form posts categories[] but handler reads category_ids (P1)
- **Symptom:** Category selection silently lost on article create (edit works).
- **Fix:** Rename create.blade.php:84 field to `category_ids[]` (+ old('categories') refs). (BR-DOC-020)

### [SEC-DOC-002] Category@index missing Gate (P1) · [SEC-DOC-003] both uploadImage() missing Gate (P1)
- DocumentationCategoryController@index:18-41 and both uploadImage() (article:91, category:80) lack Gate::authorize; reachable by any authenticated central user. Fix: add `.viewAny`/`.create` gates. (BR-DOC-016)

### [VAL-DOC-001] Image upload max:20048 (~20MB) + SVG allowed (P1)
- Both uploadImage() use `image|max:20048`, no mime allowlist (SVG = XSS). Fix: `mimes:jpg,jpeg,png,gif,webp|max:2048`. (BR-DOC-015)

### [SEC-DOC-004] Both FormRequests authorize() return bare true (P1, systemic D30)
- ValidateArticleRequest:12, ValidateCategoryRequest:11. Fix: return matching Gate::allows().

### P2/P3
- **DATA-DOC-002 (P2)** Category::$fillable omits sort_order (column exists, validated → dropped). BR-DOC-019.
- **DEAD-DOC-001 (P2)** DocumentationController@store/update/destroy no-op stubs + create/show/edit point at missing views; exposed by module `documentations` resource (routes/web.php:7, api.php:7). REQ-DOC-015/BR-DOC-024.
- **BUG-DOC-003 (P2)** reader visibility honours only `public` (safe-hidden; client/developer/internal unsupported). BR-DOC-017.
- **DAT-DOC-003 (P2)** store/update multi-write without DB::transaction.
- **PERF-DOC-001 (P2)** getArticlesByCategory unpaginated + uncached category tree.
- **ORM-DOC-001 (P3)** models lack $connection. **BUG-DOC-004 (P3)** created_by set in FormRequest::prepareForValidation (not a spoof).

---

## Dashboard (DSH) — Complete Audit additions (2026-06-29, Technical Auditor, Mode X)

> No P0 (read-only, fails closed, no cross-tenant leak). Health 65/100 (Amber). Deploy: GO platform / NO-GO feature.
> New codes this pass: BUG-DSH-007, SEC-DSH-008, SEC-DSH-009, DATA-DSH-001, DATA-DSH-002. Existing codes confirmed (not duplicated): PERF-DSH-001/005, BUG-DSH-006, DEAD-DSH-001.
> Reconciliation of stale entries: SEC-DSH-006/007 ("no authorization in any controller") are PARTIALLY SUPERSEDED — the live controllers now carry Gate/role checks; residual risk moved to the mis-wiring findings below. SEC-DSH-002 (main dashboard ungated) is by FRD design (landing for all staff) — downgrade.

| Code | Sev | Issue | Evidence |
|------|-----|-------|----------|
| BUG-DSH-007 | P1 | **Role-name drift — 4 of 7 role dashboards gate on Spatie roles no seeder creates → permanent 403 for everyone, incl. the real platform operator.** Checks `hasRole('Accounts')`/`'Transport'`/`'Management'`/`'SuperAdmin')`; canonical seeded roles (database/seeders/TenantRolePermissionSeeder.php:20-74) are `Accountant`, `Super Admin` (with space), and no `Transport`/`Management`. `abort_unless(hasRole())` is a direct role check so the AppServiceProvider Gate::before super-admin bypass does NOT apply. | `Accounts/AccountsDashboardController.php:16`, `Transport/TransportDashboardController.php:16`, `Management/ManagementDashboardController.php:17`, `SuperAdmin/SuperAdminDashboardController.php:16` |
| SEC-DSH-008 | P1 | **Foundational-Setup detail pages have NO authorization** — `schoolProfile()`/`sessionBoard()`/`billing()` lack `Gate::authorize` (only `index()` has it). Any authenticated+verified tenant user can read the school's plan, trial flag, invoices, and next bill (Confidential per FRD). | `FoundationalSetup/FoundationalSetupDashboardController.php:56,109,164` (vs gated :18); routes `Dashboard/routes/web.php:43-48` |
| SEC-DSH-009 | P1 | **`tenant.dashboard.viewAny` permission never seeded** → all 15 area hubs inaccessible to non-super-admin staff. Referenced by 16 controllers, defined by 0 seeders (grep across database/, Modules/*/database/, app/). config/permission.php:104 register_permission_check_method=true. | hub controllers e.g. `Finance/FinanceDashboardController.php:17`; seeding: none |
| DATA-DSH-001 | P2 | **Resilient reads swallow exceptions with zero logging** — `safeCount`/`safeSum` catch `\Exception`→return 0, no Log. 129 call-sites. Broken/renamed source table shows believable 0 forever (RISK-DSH-004). | `BaseDashboardController.php:31-33,50-52` |
| DATA-DSH-002 | P2 | **No academic-session/year scoping on any aggregation** → cross-session over-counting on multi-year tenants (students, LMS counts, KPIs). | `DashboardController.php:31-55` and all hub counts |

**Reading-discipline catch (false positive avoided):** Dashboard queries `prm_tenant_plan_billing_schedules` (plural) which matches the LIVE migration `Modules/Prime/database/migrations/2025_12_02_051744_*` and model `Prime/app/Models/TenantPlanBillingSchedule.php:15`. The DDL master `0-DDL_Masters/prime_db_v4.sql` has the SINGULAR `prm_tenant_plan_billing_schedule` — the DDL master is stale; the Dashboard code is correct. Flag the DDL-master drift to DB Architect (not a DSH bug).

---

## EventEngine (EVT) — Complete Audit additions (2026-06-29, Technical Auditor, Mode X)

> Module is a **non-runnable config-CRUD scaffold**: code is competent but its 3 tables have 0 migrations + 0 DDL. Health 18/100 (P0 cap). Deploy: **NO-GO**.
> New codes this pass: DATA-EVT-001/002/003, BUG-EVT-001/002/003/004, DEAD-EVT-001/002, VAL-EVT-001, SEC-EVT-001.
> **Reconciliation:** **SEC-EVT-002 ("No tenancy middleware in RSP") is RESOLVED / STALE** — live `RouteServiceProvider.php:41-48` carries the full stack (InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + auth + verified). D23 is RESOLVED for EVT. Same correction applies to `progress.md` "runs on wrong DB". Did NOT reuse SEC-EVT-002.

| Code | Sev | Issue | Evidence |
|------|-----|-------|----------|
| DATA-EVT-001 | P0 | **3 model tables have NO migration and NO DDL anywhere** → module non-runnable; every screen + every `unique:`/`exists:` rule 500s on a clean tenant (`SQLSTATE 42S02`). | `database/migrations/` only `.gitkeep`; `grep lms_trigger_event\|lms_action_type\|lms_rule_engine_configs tenant_db_v4.sql`=0; models `TriggerEvent.php:16`, `ActionType.php:14`, `RuleEngineConfig.php:17` |
| BUG-EVT-001 | P1 | **RuleEngineConfig policy bound to non-existent `Modules\LmsHomework\Policies\RuleEngineConfigPolicy`** (LmsHomework has only Homework* policies). Real class is `App\Policies\RuleEngineConfigPolicy`. Latent fatal: dormant while gates are string-ability based; Class-not-found 500 the moment model-policy authz is used. | `EventEngineServiceProvider.php:13,56` |
| DATA-EVT-002 | P1 | **Prefix divergence:** registry `module_list.md:17` says `sys_`; code uses `lms_*`. Must decide before authoring migrations (DATA-EVT-001). | models vs `module_list.md` |
| SEC-EVT-001 | P1 | **D30: all 3 FormRequests `authorize(){return true;}`** — mitigated (every controller action has a `Gate::authorize('tenant.*')`). | `TriggerEventRequest.php:11`, `ActionTypeRequest.php:10`, `RuleEngineConfigRequest.php:13` |
| DEAD-EVT-001 | P2 | **Resource `index()` actions dead/unreachable** — `TriggerEventController::index():19` `abort(404)` then unreachable redirect+query; Action/Rule `index()` early-return redirect with unreachable body. `trigger-events.index` route returns 404 (inconsistent with siblings). | `TriggerEventController.php:17-37`, `ActionTypeController.php:17-36`, `RuleEngineConfigController.php:20-54` |
| BUG-EVT-002 | P2 | **`logic_config` hardcoded `{min_score:'1'}`, never editable** (omitted on update); `event_logic`/`action_logic` echo code/name/description. BR-EVT-018 unmet. | `RuleEngineConfigController.php:87-89,145-153` |
| BUG-EVT-003 | P2 | **API resource stub** — `apiResource('eventengines')` → `store/update/destroy` empty bodies; `show()` returns nonexistent `eventengine::show` view (500). | `routes/api.php:6-8`, `EventEngineController.php:110,131,136,115-118` |
| VAL-EVT-001 | P2 | **`required_parameters` persisted from raw request, no validation rule** (field absent from `ActionTypeRequest::rules()`). | `ActionTypeController.php:64`, `ActionTypeRequest.php:25-36` |
| DEAD-EVT-002 | P3 | **Stray unused `use Modules\LmsHomework\Models\TriggerEvent;`** — copy-paste origin (same as BUG-EVT-001). | `TriggerEventRequest.php:7` |
| BUG-EVT-004 | P3 | **`activityLog()` emitted before `save()`** in toggle/destroy → false-success audit on save failure. | `TriggerEventController.php:227`, `ActionTypeController.php:228`, `RuleEngineConfigController.php:252` |
| DATA-EVT-003 | P3 | **Non-transactional two-write destroy** (set inactive + soft-delete); `restore()` leaves record inactive (intended for Rules per BR-016, undocumented for others). | `TriggerEventController.php:151-153,179-193` |

---

## Feedback (FBK) — Complete Audit additions (2026-06-29, Technical Auditor, Mode X)

> No P0 (full tenancy stack, no cross-tenant leak, no module-owned deploy blocker). Health 54/100 (Amber).
> Deploy: GO platform-safety / NO-GO feature-readiness (P1 functional blockers). Report:
> `3-Audit_Reports/V1_Jun-2026/Feedback_Complete_Audit_2026-06-29.md`.
> New codes this pass: BUG-FBK-003/004/005/006, SEC-FBK-003/004/005, VAL-FBK-003, DEAD-FBK-002, JOB-FBK-001, ORM-FBK-001.
> **Reconciliation (live tree updated 2026-06-27, after the 2026-06-21 audit):** SEC-FBK-001 ("0 authz in 9 ctrls")
> REMEDIATED — all 9 admin controllers now carry `can:tenant.feedback.viewAny`. SEC-FBK-002 / DEAD-FBK-001
> ("eligibility service never called") REMEDIATED — now called at FbkResponseController.php:71,88. VAL-FBK-002
> OUTDATED — every store/update now validates inline (downgraded P3). "0 tests" (FRD Q5) CORRECTED — 9 Browser
> test files exist (~6,230 LOC); Pest unit/feature still empty. BUG-FBK-001/002, PERF-FBK-001, VAL-FBK-001 CONFIRMED.

| Code | Sev | Issue | Evidence |
|------|-----|-------|----------|
| BUG-FBK-003 | P1 | **Eligibility + auto-population broken** — `FbkEligibilityService` matches on `$relationship->context_required`, but the attribute is `context_required_id` (dropdown FK). match() always hits default → isEligible()=false (every submit 403) and resolveEligibleTargets()=[] (0 targets). v2-string vs v3-FK service drift. | `FbkEligibilityService.php:82,102`; `FbkRelationshipType.php:25,46`; mig `2026_04_09_100002_*:19` |
| SEC-FBK-004 | P1 | **`tenant.feedback.*` / `tenant.consent-forms.*` permissions never seeded** → with Gate::before super-admin bypass, whole module is super-admin-only; Admin/Principal/Teacher get 403. RISK-FBK-003. Same pattern as SEC-DSH-009. | controllers e.g. `FbkCycleController.php:21`, `FbkMenuController.php:29`; seeding: 0 rows in `database/seeders/TenantRolePermissionSeeder.php`, `Prime/.../RolePermissionSeeder.php` |
| SEC-FBK-005 | P1 | **Peer/NEP anonymity not locked at config** — `FbkAnonymityService::enforceAnonymityRules()` never called; admin can save a peer relationship/flow with anonymity OFF (BR-007/008). Mitigant: CFT defaults anonymous=true; no target-facing read path yet. | `FbkRelationshipTypeController.php:37-79`; `FbkCycleFeedbackTypeController.php:66-153`; `FbkAnonymityService.php:77` |
| BUG-FBK-004 | P1 | **Reverse scoring (BR-013) never applied** — computeOverallRating uses raw getNumericValue()*weight; FbkAnswer doesn't snapshot `is_reverse_scored`/invert. Aggregates wrong for reverse items. | `FbkResponseService.php:166-190`; `FbkAnswer.php:60-67`; syncAnswers `:136-150` |
| SEC-FBK-003 | P1 | **Coarse authorization** — single `can:tenant.feedback.viewAny` gates all mutations (store/update/destroy/activate/publish/forceDelete). View grant = full manage. 0 Fbk Policy classes. | `FbkCycleController.php:21`, `FbkTemplateController.php:22`, `FbkCategoryController.php:19`, et al. |
| VAL-FBK-003 | P2 | **BR-020/021/022 unenforced** — no check exactly one respondent/target identity; `student_academic_session_id` from request never matched to cycle session. | `FbkResponseController.php:123-152` |
| DEAD-FBK-002 | P2 | **FbkAnonymityService injected but never invoked** — entire anonymity/k-anon layer is dead; BR-008/009/010 unenforced if a target view is added. Replaces resolved DEAD-FBK-001. | `FbkResponseController.php:24`; `FbkAnonymityService.php` (no callers) |
| BUG-FBK-005 | P2 | **Submitted response can be overwritten** — submit() updateOrCreate on natural key with no guard that status≠Submitted → repeat POST rewrites answers/rating (violates BR-016). | `FbkResponseService.php:71-95` |
| JOB-FBK-001 | P2 | **No scheduled cycle transitions** (BR-015 date-driven / ENH-002). registerCommandSchedules() empty; cycles never auto-activate/close. RISK-FBK-004. | `FeedbackServiceProvider.php:56-62` |
| ORM-FBK-001 | P3 | FbkResponse/FbkSummary declare BOTH `$fillable` and `$guarded`; `$guarded` ignored when `$fillable` set (redundant/misleading; `_uq` cols already protected). | `FbkResponse.php:19-68`; `FbkSummary.php:14-61` |
| BUG-FBK-006 | P3 | Cycle window boundary — date-cast start/end + `now()->between()` closes a cycle from 00:00 of end_date (excludes final day). | `FbkCycle.php:94-98` |

**Positive (beats platform baseline):** D36 generated dedup columns correct — 13 `_uq` cols `GENERATED ALWAYS … VIRTUAL`
+ `uq_fbk_r_dedup`/`uq_fbk_s_dedup` UNIQUE (mig 100009:41-47,64; 100011:27-32,53), vs platform 1/19. D29-clean (0 enum).

<!-- ===== GlobalMaster (GLB) Mode-X Complete Audit — 2026-06-29 | Technical Auditor ===== -->
| Code | Sev | Issue | Location |
|------|-----|-------|----------|
| BUG-GLB-001 | P0 | **Missing `AcademicSession` model** — `AcademicSessionController` + `SessionBoardSetupController` import `Modules\GlobalMaster\Models\AcademicSession` (class absent; only `Modules\Prime\Models\AcademicSession` exists) → every academic-session route AND the session-board hub 500. Breaks REQ-GLB-007/013, BR-GLB-019. | `AcademicSessionController.php:10`; `SessionBoardSetupController.php:8,22` |
| SEC-GLB-010 | P0 | **LanguageController create/store/edit/update have NO `Gate::authorize`** — any authenticated central user can create/edit platform languages (BR-GLB-020); FormRequest authorize() also `true`. Distinct from SEC-GLB-005 (prefix mismatch). | `LanguageController.php:29-32,37-41,55-59,64-68` |
| SEC-GLB-012 | P1 | **`PlanController::planDetails()` AJAX ungated** — any auth user reads plan+module pricing (FRD §5.6 Internal; REQ-GLB-010 AC4). | `PlanController.php:239-251` |
| BUG-GLB-002 | P1 | **Current academic session deletable** — `if (!$session->is_active === true)` operator-precedence bug AND `glb_academic_sessions` has no `is_active` column → always deletes (BR-GLB-009). Extends DEAD-GLB-002 with root cause. | `AcademicSessionController.php:124` |
| BUG-GLB-003 | P1 | **Single-current-session broken at app layer** — toggleStatus writes phantom `is_active`, never sets `is_current`; BR-GLB-007/008 rely on DB generated `current_flag` the app never populates. | `AcademicSessionController.php:181-217` |
| VAL-GLB-001 | P1 | **DropdownRequest validates only `value`+`is_active`** — `key/type/org_id` unvalidated; store() reads them from `validated()` (undefined keys) → rows saved with null key/type; stale `table_name.column_name` unique rule keys off null. Breaks BR-GLB-026/029. | `DropdownRequest.php:41-56`; `DropdownController.php:54-67` |
| VAL-GLB-002 | P1 | **AcademicSessionRequest missing `start_date`/`end_date` + cross-field** (BR-GLB-010); `is_current` unvalidated. | `AcademicSessionRequest.php:17-33` |
| BUG-GLB-004 | P1 | **Country deactivation cascade omits cities** — only states+districts cascade; cities stay active under inactive country (BR-GLB-001). | `CountryController.php:180-219` |
| SEC-GLB-013 | P1 | **Activity log written before guards/success** — State toggle logs at :197 before parent-active check at :201; AcademicSession toggle logs before save → blocked toggles log as success (BR-GLB-005). | `StateController.php:197`; `AcademicSessionController.php:201` |
| BUG-GLB-005 | P1 | **3 routed methods do not exist** → 500: `StateController::getStatesByCountry` (route get-states/{countryId}), `DropdownController::search`, `ActivityLogController::search`. Breaks REQ-GLB-002 dependent dropdown. | root `web.php:236,263,269` |
| BUG-GLB-006 | P1 | **LanguageController imports wrong `Language` model** (`Modules\Prime\Models\Language`); forceDelete logs event `'Stored'`; update returns raw `'update.language'` not `flash()`. | `LanguageController.php:9,67,119` |
| BUG-GLB-007 | P2 | District `forceDelete` uses `prime.district.delete` instead of `…forceDelete` (BR-GLB-021). | `DistrictController.php:162` |
| BUG-GLB-008 | P2 | Duplicate `activityLog()` per update → double audit rows. | `StateController.php:97-111`; `ModuleController.php:113-127` |
| VAL-GLB-003 | P2 | `ModuleRequest`: `is_sub_module` typed string (should bool); no sub-module⇒parent rule (BR-GLB-012); name-only unique contradicts composite `(parent,name,version)` (BR-GLB-017). | `ModuleRequest.php:23,34` |
| PERF-GLB-002 | P2 | Unbounded geography loads (`Country::has('states')->with(...)->get()`) on workspace/state/district screens (NFR-GLB-001). | `GeographySetupController.php:73-74`; `StateController.php:21`; `DistrictController.php:21-23` |
| SEC-GLB-014 | P2 | LIKE search wildcards unescaped + no rate limiting on search/AJAX (BR-GLB-023/024). | `GeographySetupController.php:47,142-148` |
| BUG-GLB-009 | P2 | Dropdown `org_id` set to `auth()->user()->id`; ordinal per-org not per-key (BR-GLB-028); destroy/restore log strings say "module". | `DropdownController.php:57,61,115` |
| DATA-GLB-001 | P2 | Schema/name drift: `glb_menu_module_jnt` (live) vs `glb_menu_model_jnt` (DDL master); `glb_module_plan_jnt` (live) vs `prm_module_plan_jnt` (V2); Dropdown→`sys_dropdowns` vs V2 `sys_dropdown_table`. | migrations vs `global_db_v4.sql` |
| DATA-GLB-002 | P2 | `glb_academic_sessions` lacks `is_active` though 3 controller paths read/write it (root cause of BUG-GLB-002/003). | `2025_10_15_094805_create_academic_sessions_table.php` |
| MIG-GLB-001 | P2 | Dead `activity_logs` migration creates a table no code uses (model targets `sys_activity_logs`). | `2025_11_02_071024_create_activity_logs_table.php:13` |
| ARCH-GLB-001 | P2 | No service layer; global `activityLog()` helper hard-imports GLB `ActivityLog` → platform-wide audit blast radius (RISK-GLB-008). | `app/Helpers/activityLog.php:4` |
| DEAD-GLB-003 | P3 | `Dropdown.php.bkk` backup + rogue duplicate `Dropdown.php`; stale `App\Models\V1\GlobalMaster\{District,State}` imports; GLB `NotificationController` unrouted (Prime's is wired). | `Models/Dropdown.php(.bkk)`; `CountryController.php:6-7` |
| DATA-GLB-003 | P3 | Un-prefixed `organization_academic_sessions` table; empty `down()`; single-current unique index commented out; `sch_board_organization_jnt` defined inside GLB. | `2025_10_18_101401_make_organization_academic_sessions_table.php` |
| ORM-GLB-001 | P3 | `Country` model no `$casts` (`is_active` not bool); `$connection` inconsistent across geography models (works only via prime_db VIEWs). | `Models/Country.php`; `Models/District.php` |

**GLB Mode-X totals:** P0=2 · P1=10 · P2=10 · P3=3. **Positive vs baseline:** D29-clean (0 enum in migrations); `glb_academic_sessions.current_flag` is a correct `GENERATED ALWAYS … STORED` column (D36-compliant). Central module — Layer 6 tenancy correctly N/A. Report: `3-Audit_Reports/V1_Jun-2026/GlobalMaster_Complete_Audit_2026-06-29.md`.

---

### HrStaff (HRS) — Mode X Complete Audit (2026-06-29, Technical Auditor)

Health **40/100 (P0-capped; uncapped ≈63)**. Module is genuinely ~85% built and ABOVE platform norms on the
high-risk layers: tenancy stack correct (no D23), **0 `$request->all()`**, **0 debug**, **0 `Schema::`
introspection**, **0 `initialize()` leaks**, all PKs `bigIncrements` (not INT), encryption casts applied,
and salary/payslip/leave endpoints have proper ownership checks (**no IDOR**). 33 DDL = 33 migrations = 33
models, **no drift** (BA's "no drift" verified live). Issue codes namespaced **HRS** (the `PAY` token is owned
by the Payment module — `SEC-PAY-001..008` already exist; never reused).

- **DATA-HRS-001 (P0):** `LeaveService::initializeBalances()` runs unconditional `LeaveBalance::withTrashed()
  ->where('academic_year_id',$y)->forceDelete()` before recreating → permanent loss of accrued `used_days`/
  `carry_forward`/adjustments + orphaned `hrs_leave_balance_adjustments` FK; violates BR-HRS-023. Live route.
- **BUG-HRS-001 (P1):** `EventServiceProvider $listen=[]` + `$shouldDiscoverEvents=true` but **no `app/Listeners/`
  dir exists** → PayrollApproved/PayrollLocked/LeaveApproved/Rejected/AppraisalFinalized fire into nothing →
  Accounting Journal Voucher (REQ-HRS-029) never created; leave/payslip notifications never sent.
- **BUG-HRS-002 (P1):** PF computed from hardcoded `min(gross*0.50,15000)` approximation, not actual Basic
  component → wrong statutory PF/ECR (BR-PAY-004); applicability from `applicable_flag` not basic≤15k (BR-HRS-012).
- **BUG-HRS-003 (P1):** `PayrollComputationService::computeRun()` catches per-employee "no assignment"
  DomainException and continues → run reaches `computed` with employees silently skipped (BR-PAY-002 not enforced).
- **BUG-HRS-004 (P1):** `Form16Controller::generateAll()` is a no-op stub (logs + "queued", produces nothing);
  no April-15 guard (BR-PAY-009); REQ-HRS-038 non-functional on a live route.
- **SEC-HRS-001 (P1):** payslip PDFs NOT password-protected (`PayslipService::generate` outputs plain DomPDF) —
  NFR-HRS-007/REQ-HRS-031; raw `$media->getPath()` download (not signed, NFR-006) though behind auth+ownership.
- **PERF-HRS-001 / JOB-HRS-001 (P1):** bulk payslip/Form16/email run synchronously in-request; **no `app/Jobs/`**
  layer (NFR-HRS-004); will time out at 200-500 staff. Blocked by platform DEPLOY-HRZ-01 (queue=db vs Horizon=redis).
- **VAL-HRS-001 (P1):** leave apply skips BR-HRS-005 (medical cert), BR-HRS-006 (gender), BR-HRS-007 (min service);
  `calculateDays()` called without `applicableTo` (holiday applicability ignored).
- **P2:** DATA-HRS-002 overlap predicate misses enclosing-range leave (BR-HRS-002); VAL-HRS-002 `SalaryAssignment
  ::update()` bypasses service so CTC band (BR-HRS-011)/single-active not re-checked; DATA-HRS-003 missing
  `lockForUpdate` on leave balance + single-active assignment (concurrency); SEC-HRS-002 27/27 FormRequests
  `authorize(){return true}` (D30); MIG-HRS-001 27 `->enum()` over 20 migrations (D29) + `applicable_to` casing
  drift `['All','Non-Teaching','Teaching']` vs lowercase; SEC-HRS-003 perms use `hrs.*`/`pay.*` not `tenant.*`
  (D24) + dead unused `tenant.hrs-*` set in config/permissionslist.php; SEC-HRS-004 FRD actor roles "HR Manager"/
  "Payroll Manager" not in HrsPermissionSeeder role map (D39-adjacent — only Principal/VP/Accountant/Teacher/Staff
  mapped); TEN-HRS-001 RSP lacks `EnsureTenantHasModule` (TEN-RTG-001 pattern).
- **Verified ENFORCED:** BR-PAY-010 LWP formula `(gross/working)*lop` ✅; BR-PAY-003 lock immutability (service
  guard `guardEditable` + override `abort_if isLocked`) ✅; BR-HRS-015 encryption (`bank_account_number` &
  PAN/`reference_number` cast `encrypted`) ✅; BR-PAY-001 one-run-per-month (DB unique `uq_pay_run_month_type`) ✅;
  BR-HRS-008 cancel-restore ✅; BR-HRS-024 remarks required (FormRequest `min:5`) ✅; BR-HRS-013 ESI gross≤21k ✅.
- **Lesson (reusable):** a module-local `EventServiceProvider` with `$shouldDiscoverEvents=true` but no
  `app/Listeners/` directory silently has NO listeners — events dispatch and vanish. Grep `app/Listeners/`
  existence before clearing any event-driven integration (Accounting/Notification) as "wired".
- **Architecture (Enterprise Architect, unchanged):** dual leave engine `hrs_leave_*` vs SCE `sch_employee_leave_*`
  (RISK-HRS-001). Tests: 0 (`tests/` has only `.gitkeep`, RISK-HRS-007).

Deploy: **NO-GO** (DATA-HRS-001 + inherited platform P0s).
Report: `3-Audit_Reports/V1_Jun-2026/HrStaff_Complete_Audit_2026-06-29.md`.

---

## LmsExam (EXM) — Mode X Complete Audit (2026-06-29, Technical Auditor)
> Report: `3-Audit_Reports/V1_Jun-2026/LmsExam_Complete_Audit_2026-06-29.md`. Health 40/100 (P0-capped). Deploy: NO-GO.

### P0
| Code | Issue | File:Line |
|------|-------|-----------|
| SEC-EXM-005 (confirmed+extended) | **GrievanceReviewController ZERO Gate on ALL 5 methods** (index/store/show/resolve/toggleStatus). resolve() rewrites published `lms_exam_results.total_marks_obtained`/`percentage` for any student; GrievanceRequest::authorize()=true → no auth at any layer. Sibling controllers have 10–27 gates. | `GrievanceReviewController.php:21,69,101,117,187` |

### P1
| Code | Issue | File:Line |
|------|-------|-----------|
| SEC-EXM-008 (supersedes SEC-EXM-006 scope) | All 12 FormRequest `authorize()` return hardcoded true (D30). | `app/Http/Requests/*.php` (12) |
| SEC-EXM-009 | **Policy-overwrite:** `Gate::policy(Exam::class, …)` registered 13× → only LmsActivityDashboardPolicy survives; ExamPolicy + ~11 report/assessment policies dead. ExamScopePolicy/ExamBlueprintPolicy/AnswerSheetOnlineExam unregistered. Imports `HwSubmissionTrackerPolicy`/`HwPerformanceAnalysisPolicy` reference non-existent classes (files are Homework*Policy). | `LmsExamServiceProvider.php:87–108,41–42` |
| SEC-EXM-010 | Advanced-reports hub (6 reports, 798 lines) gated by single WRONG permission `tenant.hw-submission-tracker.view`; no per-exam-report gates; model policies dead via SEC-EXM-009. | `ExamAdvancedReportController.php:38` |
| SEC-EXM-011 | No module-license guard (hasModule:EXM) → REQ-EXM-019/NFR-009 fails; unsubscribed schools reach all screens. | `RouteServiceProvider.php:41–48` |
| BUG-EXM-003 (still present) | `ExamStudentGroupMemberController::toggleStatus()` missing → route returns 500. Open since 2026-04-02 (route now line 171). | `routes/web.php:171` |
| BUG-EXM-004 | Grievance resolve recomputes only marks+percentage; grade/division/rank NOT recomputed → stale published results (BR-EXM-031/033/034 partial). | `GrievanceReviewController.php:142–159` |
| PERF-LMS-002 (still present) | Unbounded dashboard queries in index + God controllers (LmsExamController 3767, PaperSetQuestionController 1465; no domain service layer). | `LmsExamController.php:~148–180` |

### P2
| Code | Issue | File:Line |
|------|-------|-----------|
| DATA-EXM-001 | created_by missing on 5 config tables+models (ExamType/ExamStatusEvent/ExamScope/ExamBlueprint/ExamStudentGroup); owned DDL has created_by on only 2 of 11 tables. NFR-EXM-006. | `app/Models/*`, `LmsExam_DDL_v6.sql` |
| SCH-EXM-001 | 6 ENUM columns in owned DDL (D29) — event_type, result_published, mode, offline_entry_mode, allocation_type. | `LmsExam_DDL_v6.sql:37,114,146,172,290` |
| DAT-EXM-002 (StudentAttempt-owned) | DDL spec anomalies — `attemp_activity_event_types` missing comma before UNIQUE KEY + misspelled name; `lms_offline_exam_upload_detail` uq/idx reference phantom `attempt_id`/`is_active`. **CORRECTION: live migrations ship CORRECTLY** (real cols/indexes); risk only if provisioning from raw .sql. Attribute fix to StudentAttempt DDL owner. | `StudentAttempt_DDL_v4.sql` |
| DEAD-EXM-003 | `ReleaseScheduledExamResults` console command imported (SP:49) but never registered (dead) AND queries removed/commented column `show_result_type` → would error; duplicates live `lms-exam:publish-results`. | `app/Console/ReleaseScheduledExamResults.php` |

### Reassessed / cleared
- **SEC-EXM-007** (ExamQueryService "no explicit tenant scoping") → **non-issue** under database-per-tenant: the connection is swapped per tenant, there is no tenant_id column to scope. No action.
- EXM is ABOVE platform baseline: D24 single clean `tenant.` prefix (no `tennat.`), D25 0 `$request->all()` sites, no privilege fields in fillable, no committed secrets, no module route closures, zero debug statements.

---

## LmsHomework (HMW) — Mode X Complete Audit (Technical Auditor, 2026-06-29)
Health **60/100 (Amber)**, **no P0**, **DEPLOY: GO** (no cross-tenant write hole / committed secret / migration blocker). Strengths over platform baseline: **0** `$request->all()` (D25), **0** bare-`true` FormRequests (D30), `DB::transaction`+`lockForUpdate` on submission uniqueness (BR-024). New codes (no prior `HMW`-prefixed entries; historical `HWK`/`LMS` codes referenced a since-removed `StudentHomeworkController`):

**P1**
- **BUG-HMW-001** — `LmsHomeworkController::publish()` (`:886-921`) computes `$isReleased/$releasedAt/$statusId` for the scheduled/on-topic branch but the `updateOrCreate` payload **hardcodes** `is_released=true, released_at=now(), status_id=ASSIGNED` → ON_SCHEDULED_DATE / ON_TOPIC_COMPLETE homework released immediately. Breaks REQ-HMW-003, BR-011/012 (DDL spec v5:309-311).
- **SEC-HMW-001** — Permission-string mismatch (A-AUTH-1): FormRequests check `tenant.homework.create` / `tenant.homework-submission.create` / `grade-homework`, but controller+5 policies+views use `tenant.home-work.*`. Grep found the FormRequest strings defined **nowhere** → `can()` fails closed for non-super-admins (or defense-in-depth fully bypassed under a super-admin gate). `HomeworkRequest:23-26`, `HomeworkSubmissionRequest:19-23`, `HomeworkReviewRequest:17`. (D24 family.) **P0 if** perms truly undefined in prod (blocks legit create/grade).
- **BUG-HMW-002** — Late submission not hard-blocked when effective `allow_late_submission=0` (A-FN-1, BR-028). `HomeworkSubmissionController::store():153-194` flags `is_late` but never rejects.
- **BUG-HMW-003** — Every `NotificationTarget::create` is commented out (A-FN-2): `LmsHomeworkController:1495-1510,1602-1609,1664-1669,1710-1715,2326-2331`; `HomeworkSubmissionController:492-497`. Notifications written with no recipients → never delivered (REQ-HMW-020/BR-045).
- **BUG-HMW-004** — `SyllabusScheduleObserver:30-47` queries dropdown key `'homework_status'` value `RELEASED`/`PENDING`, but HMW uses key `lms_homework.status_id` values DRAFT/PUBLISHED/ARCHIVED → on-topic auto-release never fires (A-FN-3).
- **BUG-HMW-005** — `UpdateHomeworkStatus` (`:30-49`, scheduled `routes/console.php:51`) has **no per-tenant `tenancy()->initialize()`** (unlike `ReleaseScheduledHomework` which loops `Tenant::all()`) AND reads `ASSIGNMENT_STATUS_ALT` (`lms_homework.homework_assignment_status`) where no statuses are seeded → overdue marking runs on central DB and resolves null status. Doubly dead (BR-041). Layer 6.2 + 10.2.

**P2**
- **VAL-HMW-001** — `assignmentsGrade():1401-1404` + `saveCheck():1904-1910` validate `marks_obtained` min:0 with **no max** → marks can exceed homework max (BR-031 partial; only `HomeworkReviewRequest` caps max).
- **BUG-HMW-006** — `store():425`/`update():614` call `syncAssignments()` unconditionally → IMMEDIATE homework auto-publishes at creation (BR-005 "new=Draft" / BR-007 "publish only from Draft" undermined).
- **DATA-HMW-001** — migration `...122811_create_lms_homework_table.php:26` sets `release_condition` ENUM **default `ON_TOPIC_COMPLETE`** (the dead path); should be `IMMEDIATE`.
- **PERF-HMW-001** — `index():70-71` unbounded `Topic::get()` + `Student::get()` on the hub render.
- **TEN-HMW-001** — `routes/api.php:6-8` `apiResource('lmshomeworks', LmsHomeworkController)` runs under `api`+`auth:sanctum` with **no tenancy init** and points at view-returning web controller methods → non-functional cross-DB surface (A-CODE-3).
- **SCH-DDL-001** — DDL v5 not runnable: typo `realease_condition` (`:66`), dangling FK `fk_hw_release_cond`/`fk_hwa_release_cond`→`release_condition_id` (nonexistent, `:92,174`), `sys_dropdown_table` vs migration `sys_dropdowns`, `hw_attachment_media_id Json UNSIGNED` (`:54`). Migrations authoritative; emit DDL v6.
- **BUG-HMW-007** — `assignmentsIndex():1359` `Dropdown::where('type','homework_assignment_status')` queries wrong column → status filter always empty (should be `where('key', ASSIGNMENT_STATUS)`).

**P3** — DEAD-HMW-001 dead Rule-Engine imports in `Homework.php:9-11`; DEAD-HMW-002 unrouted `seedTestData()` fixture `LmsHomeworkController:2160`; ORM-HMW-001 three policies bound to `Homework::class` (last wins) `LmsHomeworkServiceProvider:59,62,63`; DEAD-HMW-003 duplicated `calculateIsLateForSubmission()` in both controllers; DATA-HMW-002 `is_resubmission_requested` unsignedInteger NOT NULL no default vs boolean cast.

**Lesson (reusable):** a console command with a `tenant:` signature is NOT automatically per-tenant — if `handle()` lacks `Tenant::all()->each(... tenancy()->initialize/run ...)` it runs once in CENTRAL context against tenant tables (finds nothing / errors). Within one module, `ReleaseScheduledHomework` does this correctly while `UpdateHomeworkStatus` does not (BUG-HMW-005). Always read `handle()` before treating a scheduled `tenant:*` command as working.

Report: `3-Audit_Reports/V1_Jun-2026/LmsHomework_Complete_Audit_2026-06-29.md`.
