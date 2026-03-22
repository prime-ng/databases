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
