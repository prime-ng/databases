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
| `EnsureTenantHasModule` middleware absent from route groups | **13/13 modules confirmed** (2026-06-30 BA audit); only 1 usage in entire tenant.php | P0 (any school can access modules not in their plan) | SEC-PLATFORM-001 |
| `Gate::authorize()` absent or dead — policies exist but are never called | **13/13 modules** (2026-06-30); 64 controllers with zero auth primitive in earlier survey | P0 — authorization is a no-op even where policy classes exist | — |
| FormRequest `authorize(){ return true; }` | **437 / 485 (90%)**; SLB alone: 15/15 FormRequests (2026-06-30) | P1 (P0 where controller also ungated) | D30 |
| Zero test coverage | Most modules (BHA, VND, TTS, TTP, SLB, SLK, TMP and others have 0 tests) | P1 — no regression safety net | — |
| PII stored in plaintext | VND confirmed: PAN card + bank account numbers unencrypted in tenant_db (2026-06-30) | P0 — DPDPA / regulatory violation | — |
| Cross-layer `AcademicSession` import | SLK confirmed: 3 controllers import `Modules\Prime\Models\AcademicSession` (prime_db) instead of tenant `OrganizationAcademicSession` (tenant_db) — returns wrong school's data (2026-06-30) | P0 — cross-tenant data isolation breach | — |
| `is_super_admin`/`super_admin_flag`/`password` in `$fillable` | `SchoolSetup/User.php` + `StudentProfile/User.php` (SCH + STD confirmed 2026-06-30) | P0 (priv-esc via `$request->all()`) | — |
| Duplicate `Gate::policy()` registration silently kills valid policies | QNS: `QuestionBankPolicy` dead — overwritten by duplicate. TTF: 19 of 23 policies unregistered (2026-06-30) | P0 — auth silently passes for affected resources | — |
| Live `create/update($request->all())` (mass-assign) | **24 sites** (GlobalMaster, Library, Syllabus heaviest) | P1 (P0 if model has privilege fields) | D25 |
| `->enum()` in tenant migrations (should be `sys_dropdown_table` FK) | **~476** (hst 28, sch 22, tt 20, tpt 19) | P2 | D29 |
| `->increments('id')` INT(11) signed PK | **428 / 658 tables** | P1 (FK typing + 2.1B-row cap) | — |
| Tenant FKs → `sys_dropdowns` (central-only table) | **52** | P0 (cross-DB FK, impossible in MySQL) | — |
| Tenant FKs → `sys_roles` (NO create migration exists) | **17** | P0 (`tenants:migrate` fails errno 150/1824) | — |
| `$fillable` lists a column the migration lacks (D17) | **66 models** | P1 (`SQLSTATE 42S22 Unknown column`) | D17 |
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

### SEC-PLATFORM-003: `EnsureTenantHasModule` Missing from All Route Groups (13/13 confirmed 2026-06-30)
- **Module/Area:** All tenant-scoped modules — confirmed across SCH, STT, TTS, TTF, STP, FIN, STD, SLK, SLB, QNS, TMP, SYS, VND on 2026-06-30
- **Symptom:** A school on a Basic plan (e.g., without LMS) can navigate directly to `/question-bank/`, `/syllabus/`, etc. and access features their subscription does not include
- **Root Cause:** Only 1 usage of `EnsureTenantHasModule` exists across the entire `routes/tenant.php` (8,315 route lines across all modules). Module `RouteServiceProvider`s load `Modules/{Module}/routes/web.php` with `auth` + tenant middleware but do NOT add `EnsureTenantHasModule`.
- **Fix:** Add `EnsureTenantHasModule:'{module_slug}'` to each module's route group middleware in `Modules/{Module}/routes/web.php`. Module slug must match the `glb_modules.slug` value for that module.
- **Prevention:** The `10-new-feature-checklist.md` must be updated to require `EnsureTenantHasModule` in the middleware stack for every new tenant route group. Add to the Technical Auditor's Layer 4 (Auth Middleware) checklist.

### SEC-PLATFORM-007: Cross-Layer `AcademicSession` Import — Wrong DB Layer (confirmed SLK 2026-06-30)
- **Module/Area:** SyllabusBooks (3 controllers confirmed); may affect other modules — audit all tenant controllers
- **Symptom:** Academic session data is pulled from `prime_db` instead of the current school's `tenant_db` — could return another school's session, return empty for new tenants, or throw a "table not found" error when the prime context is not initialized
- **Root Cause:** Controllers import `Modules\Prime\Models\AcademicSession` (resolves to prime_db's `prm_academic_sessions`) instead of `Modules\SchoolSetup\Models\OrganizationAcademicSession` (resolves to tenant_db's `sch_organization_academic_sessions`). Because the tenant DB has no `prm_academic_sessions` table, the query either crosses to prime context (context leak) or fails silently.
- **Fix:** Replace all `use Modules\Prime\Models\AcademicSession;` imports in tenant-scoped controllers with `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` (or the appropriate tenant model). Run `grep -r "Modules\\\\Prime\\\\Models\\\\AcademicSession" Modules/` to find all occurrences.
- **Prevention:** Never import Prime-layer models in tenant-scoped controllers or services. The cross-module dependency map for any tenant module must list only tenant-db models from `SchoolSetup`, `StudentProfile`, etc. — never from `Prime`, `Billing`, or `GlobalMaster`.

### SEC-PLATFORM-008: Duplicate `Gate::policy()` Registration Silently Kills Valid Policies (confirmed QNS + TTF 2026-06-30)
- **Module/Area:** QuestionBank (QuestionBankPolicy dead), TimetableFoundation (19 of 23 policies unregistered); may affect other modules
- **Symptom:** `Gate::authorize('tenant.question-bank.create')` passes unconditionally (or uses wrong policy) even though `QuestionBankPolicy` is correctly written. No error thrown — silent security bypass.
- **Root Cause:** When two `Gate::policy(Model::class, PolicyClass::class)` calls register the same Model, the second overwrites the first. If a module's `ServiceProvider::registerPolicies()` registers `Question::class → QuestionBankPolicy` and another place (AppServiceProvider, a duplicate in the same boot()) registers `Question::class → SomeOtherPolicy` (or re-registers with a typo), the last registration wins silently. In TTF's case, 19 policies were registered in AppServiceProvider (which was later cleaned to comments) and the module ServiceProvider was never updated to re-register them, leaving 19 of 23 dead.
- **Fix (QNS):** Audit `Modules/QuestionBank/app/Providers/QuestionBankServiceProvider.php::registerPolicies()` and `app/Providers/AppServiceProvider.php` for any duplicate `Gate::policy(Question::class, ...)` call. Remove the duplicate; keep only the module-level registration.
- **Fix (TTF):** Add all 23 `Gate::policy(...)` calls back into `Modules/TimetableFoundation/app/Providers/TimetableFoundationServiceProvider.php::registerPolicies()` — the AppServiceProvider migration (D22) removed them but the module provider was not populated.
- **Detection:** For any module: `grep -r "Gate::policy" Modules/{Module}/ app/Providers/` — if the same Model appears more than once, the last one wins. If a policy exists in `app/Policies/` or `Modules/{Module}/app/Policies/` but is NOT in any `Gate::policy()` call, it is dead.
- **Prevention:** After every D22-style routes/policies migration, verify that every Policy class in `Modules/{Module}/app/Policies/` has exactly one corresponding `Gate::policy()` call in that module's `ServiceProvider::registerPolicies()`. Add this as a Technical Auditor Layer 6 (Policy Registration) check.

### SEC-VND-010: PII (PAN + Bank Account Numbers) Stored in Plaintext (confirmed VND 2026-06-30)
- **Module/Area:** `Modules/Vendor/` — vendor financial details (PAN card numbers, bank account numbers, IFSC codes stored in plain `VARCHAR` columns in tenant_db)
- **Symptom:** A database dump, SQL injection, or insider threat exposes vendor PAN and bank account data in cleartext
- **Root Cause:** Financial PII fields were designed as plain `VARCHAR` without encryption at rest. No `$casts` or `Encrypted::` cast applied. No field-level encryption service wired.
- **Fix:** Apply Laravel's `Illuminate\Database\Eloquent\Casts\Encrypted` cast to PAN, bank account, and IFSC fields in the Vendor model. Add a migration to encrypt existing plaintext values (one-time data migration job). Store ONLY the last 4 digits of the bank account for display.
- **Prevention:** Any field classified as "Confidential" or "Sensitive (PII)" in the Data Dictionary must use `Encrypted` cast in the model. Add a PII field audit step to the Technical Auditor's Layer 8 (Data Security) checklist. Reference the Data Dictionary privacy classification: Public / Internal / Confidential / Sensitive (PII).

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
- **Fix:** Verify actual table name in DDL, standardize both — confirmed singular `slb_complexity_level` is correct (migration verified 2026-06-30)

### BUG-REC-003: StudentRecommendation::create() fails at runtime — missing `created_at` column
- **Module/Area:** `Modules/Recommendation/database/migrations/tenant/2026_06_16_130101_create_rec_student_recommendations_table.php` + `StudentRecommendation.php`
- **Severity:** P0
- **Symptom:** Migration uses custom `assigned_at` timestamp and does NOT call `$table->timestamps()`. Model leaves default `$timestamps = true`. Eloquent writes `created_at` to a non-existent column on every `create()` call → `SQLSTATE[42S22]: Column not found: rec_student_recommendations.created_at`. The entire recommendation engine is non-functional: every quiz result publish that triggers a matching rule results in a rolled-back transaction.
- **Fix (migration):** Add `$table->timestamp('created_at')->useCurrent()->after('assigned_at')` via new migration.
- **Alternative fix (model):** Set `const CREATED_AT = 'assigned_at';` in `StudentRecommendation` model.

### BUG-REC-004: media_id INT FK column used as JSON array — type collision
- **Module/Area:** `Modules/Recommendation/database/migrations/tenant/2026_06_16_130058_create_rec_recommendation_materials_table.php` + `RecommendationMaterial.php` + `RecommendationMaterialController.php`
- **Severity:** P1
- **Symptom:** Migration declares `media_id` as `unsignedInteger` with FK to `qns_media_store`. Model casts `'media_id' => 'array'`. Controller stores `['media_id' => $attachments]` where `$attachments` is an array of file-metadata objects. Eloquent JSON-encodes the array; MySQL receives a string for an INT FK column. Strict mode: error 1366. Without strict mode: coerced to 0, FK integrity violation. All file attachment saves fail.
- **Fix:** Change migration column to `$table->json('media_id')->nullable()`, remove FK constraint to `qns_media_store`. Update DDL.

### MIG-REC-001: `difficulty_band` absent from rec_recommendation_rules migration — engine filtering disabled
- **Module/Area:** `Modules/Recommendation/database/migrations/tenant/2026_06_16_130100_create_rec_recommendation_rules_table.php` + `RecommendationEngineService.php:117` + `RecommendationRule.php` + `StoreRecommendationRuleRequest.php`
- **Severity:** P1
- **Symptom:** `difficulty_band` is in `$fillable`, validated in FormRequest, and read by the engine (`$rule->difficulty_band`). Column does not exist in migration → always null → `if ($rule->difficulty_band && ...)` never fires → difficulty-band filter is permanently disabled. Rules configured for EASY/MODERATE/HARD students fire for all students regardless.
- **Fix:** Add migration: `$table->string('difficulty_band', 10)->nullable()->after('max_score_pct')` (or sys_dropdown FK per D29).

### D39-REC-001: No REC permissions seeded in any seeder
- **Module/Area:** `Modules/Recommendation/database/seeders/`
- **Severity:** P1 (D39 pattern)
- **Symptom:** No `Permission::create()` calls in any REC seeder. No central seeder references `tenant.recommendation.*` permissions. All 18 FormRequest `authorize()` calls return false for non-super-admin users in fresh tenants. All CRUD screens return 403.
- **Fix:** Create `Modules/Recommendation/database/seeders/RolePermissionSeeder.php` seeding all 33 REC permission strings (see audit report for full list). Call from `RecommendationDatabaseSeeder::run()`.

### ORM-REC-001: TriggerEventPolicy not registered; RecAssessmentTypePolicy missing
- **Module/Area:** `Modules/Recommendation/app/Providers/RecommendationServiceProvider.php`
- **Severity:** P1
- **Symptom:** `TriggerEventPolicy.php` exists but is not imported or registered in `registerPolicies()`. `RecAssessmentTypePolicy.php` does not exist. Trigger-event management and assessment-type management are super-admin-only by default.
- **Fix:** Add `RecTriggerEvent::class => TriggerEventPolicy::class` to `registerPolicies()`. Create `RecAssessmentTypePolicy` and register it.

### XSS-REC-001: Seven unescaped {!! !!} outputs on user-controlled description/content fields
- **Module/Area:** `Modules/Recommendation/resources/views/` — 5 show.blade.php files
- **Severity:** P2
- **Symptom:** `description` and `content_text` fields output via `{!! $model->description !!}`. Admin users can inject HTML/JS that executes when other admin users view the show page. Stored XSS.
- **Files:** `dynamic-purposes/show.blade.php:40`, `recommendation-modes/show.blade.php:40`, `material-bundles/show.blade.php:42`, `assessment-types/show.blade.php:40`, `dynamic-material-type/show.blade.php:40`, `recommendation-materials/show.blade.php:132,137`
- **Fix:** Sanitize on save (HTMLPurifier) or replace `{!! !!}` with `{{ }}` if HTML formatting not needed.

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

#### PPT Phase 3 Mode X Audit — New Findings (2026-06-29)
| Code | Module | Issue | File:Line |
|------|--------|-------|-----------|
| SEC-PPT-007 | ParentPortal | **`ConsentFormPolicy` is dead code: never registered and wrong type** — `ParentPortalServiceProvider` has no `registerPolicies()`; `ConsentFormPolicy` checks admin Spatie permissions (`tenant.consent-forms.viewAny` etc.) rather than parent-context IDOR prevention; `ParentConsentFormController` never calls `$this->authorize()`. Admin consent form operations have no policy enforcement. | `Modules/ParentPortal/app/Policies/ConsentFormPolicy.php`, `Providers/ParentPortalServiceProvider.php` |
| SEC-PPT-008 | ParentPortal | **`session('tenant_id') ?? 1` hardcoded fallback in PTM notification creation** — `ParentPtmController::book()` uses `session('tenant_id') ?? 1` when creating the booking notification, falling back silently to tenant_id=1 for any school that is not the first tenant; silently assigns cross-tenant notification ownership. | `Modules/ParentPortal/app/Http/Controllers/ParentPtmController.php:~185` |
| VAL-PPT-003 | ParentPortal | **`StoreParentLeaveRequest` uses `after_or_equal:today` for `from_date`** — BR-PPT-004 requires `from_date >= tomorrow` to prevent retroactive leave applications; the rule `after_or_equal:today` allows same-day applications, violating the business rule. Fix: change to `'after:today'`. | `Modules/ParentPortal/app/Http/Requests/StoreParentLeaveRequest.php:17` |
| MIG-PPT-001 | ParentPortal | **D29: 7 ENUM columns across 4 ppt_* migrations** — `ppt_parent_sessions.device_type`, `ppt_consent_forms.status`, `ppt_consent_form_responses.response`, `ppt_document_requests.document_type`, `ppt_document_requests.urgency`, `ppt_document_requests.status`, `ppt_event_rsvps.rsvp_status` all use `->enum()` instead of FK to `sys_dropdown_options`. Adding new values requires a new migration. | `database/migrations/tenant/2026_06_16_105224-105228` |

#### PPT Phase 3 Mode X Audit — Resolved/Stale Prior Findings (2026-06-29)
The following entries from the Phase 2 audit (2026-06-21) are confirmed resolved or stale as of Mode X audit:
- **SEC-PPT-001 (FIXED)**: `Gate::define()` overwrite in `reportCardPdf()` no longer present; delegation pattern with bypass flag used instead.
- **SEC-PPT-002 (STALE)**: "Zero FormRequests" was incorrect — 22 FormRequests confirmed present in the module.
- **SEC-PPT-004 (FIXED)**: Complaint target-field injection remediated; fields explicitly set to null with code comment.
- **VAL-PPT-001 (STALE)**: Same as SEC-PPT-002 — 22 FormRequests confirmed.
- **VAL-PPT-002 (FIXED)**: Same fix as SEC-PPT-004.

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

---

## MarksheetGeneration (MSH) — Mode X Complete Audit (2026-06-29, Technical Auditor)

Health **6/100 (P0-capped; raw 6 already below cap)**. Deploy: **NO-GO**. 1×P0, 7×P1, 5×P2, 3×P3.

**P0**
- **BUG-MSH-001** — `routes/api.php` registers `apiResource('marksheetgenerations', MarksheetGenerationController::class)` (5 routes). `MarksheetGenerationController` has ZERO apiResource methods (`index/store/show/update/destroy`). All 5 routes return 404 or runtime error. API layer entirely dead.

**P1**
- **SEC-MSH-001** — `StudentResultController::create()` gates with `tenant.msh-student-result.view` (should be `.create`). Users without create permission can reach the create form.
- **SEC-MSH-002** — `StudentResultController::store()` gates with `tenant.msh-student-result.update` (should be `.create`). Users with update-only can create new records; users with create-only get 403 on submit.
- **SEC-MSH-003** — All **19/19** FormRequests in `app/Http/Requests/` return `authorize() = true` with no Gate check (D30 platform-wide pattern). Authorization fully bypassed at the FormRequest layer for every mutation.
- **PERF-MSH-001** — `MarksheetScheduleController::precheck()` fires **6 DB queries per class-section** in a foreach (StudentAcademicSession count, ClassRequirementGroup count, ExamResult join count, HomeworkSubmission join count, QuizQuestResult join count, StudentIaMark count). For 20 class-sections: 120+ queries. No batching. (**Confirmed re-discovery of BUG-MSG-001 from 2026-06-21 deep audit.**)
- **BR-MSH-026** — `compute()` (line 318) checks `is_locked === 1` only. BR-MSH-026 requires status to be DRAFT or COMPUTED before compute. A REVIEWED or PUBLISHED (unlocked) schedule can be recomputed, destroying reviewed data.
- **BR-MSH-027** — `compute()` dispatches `ComputeMarksheetJob::dispatch()` with no check for an existing RUNNING computation log. Concurrent double-submission triggers race condition on `wipePreviousResults()` and result inserts.
- **D39-MSH** — Zero MSH permissions (`msh-*`) found in `TenantRolePermissionSeeder`. All 18 policy-protected MSH resources are inaccessible to non-super-admin users.

**P2**
- **BUG-MSH-003** — `ExamGroupController::edit()` has no model binding parameter (signature `public function edit()`) and returns a redirect to the combined config page. The edit URL resolves but delivers no edit form. (**Confirmed re-discovery of BUG-MSG-003 from 2026-06-21 deep audit.**)
- **PERF-MSH-002** — `MarksheetComputationService` lines 209, 294, 338 call `Schema::hasTable()` inside `computeForClassSection()`. Each issues a `SHOW TABLES LIKE '...'` query. For 20 class-sections: 60 schema queries per computation run.
- **PERF-MSH-003** — `MarksheetGenerationController::results()` fetches `Student::where('is_active',1)->get()` and `Subject::orderBy('name')->get()` without pagination.
- **BR-MSH-050** — Weightage sum (must = 100) not validated at compute time. `precheck()` shows COUNT of weightage rows, not their sum. `compute()` dispatches without sum validation. `WeightageApplier` is null-safe but does not enforce 100% constraint.
- **DEP-MSH-001** — `MarksheetScheduleController::precheck()` imports `Modules\StudentPortal\Models\ExamResult` and `Modules\StudentPortal\Models\QuizQuestResult`. StudentPortal is a Pending module — tight coupling to an incomplete module.

**Strengths (above baseline):** Tenancy middleware stack correct (InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive). LifecycleService enforces all FSM transitions (COMPUTED→REVIEWED→PUBLISHED→LOCKED) with DomainException, DB transactions, and audit logs. BR-MSH-037 (publish locks template) and BR-MSH-039 (unlock requires reason) correctly enforced. D24 clean permission prefix. D29 clean (0 ENUMs). D38 clean (SoftDeletes consistent). D17 clean (fillable correct). 18/18 policies registered. sys_dropdowns FK is tenant-table (not cross-DB).

Report: `3-Audit_Reports/V1_Jun-2026/MarksheetGeneration_Complete_Audit_2026-06-29.md`

---

## Phase 3 — LmsQuiz Module Complete Audit (Mode X, 2026-06-29)

> Full Mode X audit (A+B+C+G+scoped D). 23 findings across 6 layers. Report: `3-Audit_Reports/V1_Jun-2026/LmsQuiz_Complete_Audit_2026-06-29.md`

**P0**
- **SEC-QUZ-003** — `RouteServiceProvider::mapApiRoutes()` applies only `['api']` middleware. No `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, or `EnsureTenantIsActive`. API routes (`GET /api/v1/lmsquizzes` etc.) run without tenant context — queries hit default (central) DB. Tenancy isolation broken on all API endpoints. `routes/api.php` + `RouteServiceProvider.php mapApiRoutes()`.

**P1**
- **SEC-QUZ-002** — `LmsQuizServiceProvider::registerPolicies()` calls `Gate::policy(Quiz::class, QuizPolicy::class)` at line 65 then overwrites it with `Gate::policy(Quiz::class, LmsQuizReportPolicy::class)` at line 68. `QuizPolicy` is dead. Policy-based auth for Quiz model routes to the report policy. Current controllers use string gates (unaffected), but policy-instance auth (`authorize('update', $quiz)`) silently uses wrong policy.
- **SEC-QUZ-004** — `LmsQuizReportController::getDependencies()` has NO Gate::authorize call. Returns subjects, sections, students, lessons, and topics to any authenticated user. Single gate at `index()` does not cover this AJAX endpoint.
- **BUG-QUZ-001** — `QuizAllocationController::publishHiddenRecommendations()` queries `->where('a.allocation_id', $allocationId)`. Column `allocation_id` does not exist on `lms_quiz_quest_attempts`. Real column is `quiz_allocation_id`. Recommendation publish always returns empty student list — nothing is ever published. Fix: `'a.quiz_allocation_id'`.
- **BUG-QUZ-002** — `RemedialQuizGenerationService::createAllocation()` stores `$student->user_id` as `target_id` for STUDENT type. `QuizAllocation::getTargetNameAttribute()` for STUDENT does `Student::find($this->target_id)` (std_students.id). `user_id` is sys_users.id — identity mismatch. Fix: `$student->id`.
- **BUG-QUZ-003** — `RemedialQuizGenerationService::fetchQuestionsByConfig()` when `only_unused_questions=true` calls `$query->select('question_bank_id')->from('qns_question_usage_log')`. Overwrites the QuestionBank query's SELECT and FROM — returns usage-log rows, not filtered questions. Fix: `$query->whereNotIn('id', $usedIds)`.
- **BUG-QUZ-005** — `RouteServiceProvider::mapWebRoutes()` middleware omits `EnsureTenantHasModule`. Schools without LmsQuiz licence can access all quiz screens.
- **BUG-QUZ-006** — `LmsQuizController::store()` and `update()` not wrapped in `DB::transaction()`. Quiz creation + activityLog calls are non-atomic. `forceDelete()` IS transactional — inconsistency.
- **BUG-QUZ-007** — `QuizAllocationController::index()` has `abort(404)` as first statement (line 31). Gate check at line 32 is dead code. Quiz allocation list route permanently 404.

**P2**
- **SEC-QUZ-001** — All 5 FormRequests return `authorize():true` (D30 platform pattern). Compensating control: controllers use string Gate::authorize.
- **SEC-QUZ-005** — `summary/student_result.blade.php` lines 143, 168, 170, 181 use `{!! !!}` on question text, option text, and explanation from DB. Teacher-entered `<script>` executes in student browsers. Stored XSS.
- **BUG-QUZ-004** — Route prefix typo `lms-quize` (extra 'e') throughout `RouteServiceProvider.php` (lines 49-50) and all 87 route lines in `routes/web.php`. Self-consistent within module but all named routes are misspelled.
- **BUG-QUZ-008** — `AssessmentTypeController::index()` `abort(404)` before gate (lines 25-26). Standalone assessment-type list always 404.
- **BUG-QUZ-009** — `DifficultyDistributionConfigController::index()` `abort(404)` before gate (lines 33-34). Standalone difficulty config list always 404.
- **BUG-QUZ-010** — `QuizQuestionController::index()` `abort(404)` before gate (lines 42-43). Standalone quiz-question list always 404. (4 of 6 controllers have abort(404) pattern in index().)
- **DAT-QUZ-001** — 4 ENUM columns across 3 tables (D29): `lms_quiz_allocations.allocation_type`, `lms_quiz_quest_attempts.assessment_type`, `lms_quiz_quest_attempts.status`, `lms_quiz_quest_results.assessment_type`.

**P3**
- **DAT-QUZ-002** — `Quiz::$fillable` contains `is_system_generated` twice (lines 33 and 62). No runtime impact.
- **DAT-QUZ-003** — `lesson_id` in `lms_quizzes` has no FK constraint in DDL spec or migration. Both consistently omit it (possible cross-schema reason). Deleted lessons leave orphan quiz records.
- **DAT-QUZ-004** — No permission seeder for LmsQuiz. `LmsQuizDatabaseSeeder` runs only demo data seeders. All `tenant.quiz.*` and sibling permissions unregistered in Spatie (D39). Non-super-admin users locked out.
- **ARCH-QUZ-001** — `Quiz.php` imports `Modules\StudentPortal\Models\QuizQuestAttempt` and `Modules\StudentPortal\Models\QuizQuestResult`. Hard dependency on StudentPortal module.
- **ARCH-QUZ-002** — Route duplication on difficulty-distribution-config show (resource + explicit both register same path).
- **ARCH-QUZ-003** — `LmsQuizController::index()` fires 8+ separate COUNT queries per page load with no cache.
- **PERF-QUZ-001** — `LmsQuizReportController::index()` loads all active students unbounded (`Student::where('is_active',1)->get()`).

**Strengths:** Gate coverage on all 6 LmsQuizController CRUD methods (BUG-LMS-005 FIXED confirmed). `QuizAllocationController::store()` and `RemedialQuizGenerationService::generate()` are transactional. D25 clean (all controllers use `$request->validated()`). Soft-delete consistent across all 9 tables. UUID BINARY(16) correctly generated in model boot(). QuizQuestion unique constraint enforces BR-QUZ-011 at DB level.

**Health Score: 40/100 (P0 cap) — NO-GO**

---

## LmsQuests (QST) — Mode X Complete Audit (Technical Auditor, 2026-06-29)

Health **38/100 (P0-capped; uncapped ≈51)**. Deploy **NO-GO**. 4×P0, 15×P1, 8×P2. 0 tests.

### P0

| Code | Issue | File:Line |
|------|-------|-----------|
| SEC-QST-001 | **Hub viewAny Gate commented out** — `// Gate::authorize('tenant.quest.viewAny');` in `LmsQuestController::index()` — any authenticated user reaches the full Quest hub, analytics dashboard, and all tabs with no authorization check. | `LmsQuestController.php:71` |
| BUG-QST-001 | **Missing `use Illuminate\Support\Facades\DB` in LmsQuestController** — `forceDelete()` calls `DB::beginTransaction()/commit()/rollBack()` but the facade is not imported in the 42-line import block; every permanent quest deletion throws `Class "DB" not found`; cascade deletes of child records left in inconsistent state. | `LmsQuestController.php:786` |
| BUG-QST-002 | **Undefined `$quest` in QuestQuestionController::store()** — `$quest->id` referenced at line 985 before `$quest` is assigned anywhere in the method; `POST quest-question` route throws `Undefined variable $quest` fatal error on every call. | `QuestQuestionController.php:985` |
| MIG-QST-001 | **`lms_quest_scopes.topic_id` NOT NULL in migration** — `$table->unsignedInteger('topic_id')` (no `->nullable()`); alter migration `2026_06_18_100000` does not add nullable; `QuestScopeRequest` validates `topic_id` as optional; any scope inserted without topic_id throws `SQLSTATE[23000]: 1048 Column 'topic_id' cannot be null`. | `2026_06_16_115421_create_lms_quest_scopes_table.php:25` |

### P1

| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-QST-ROUTE | Trash GET routes for `quest-scope`, `quest-question`, `quest-allocation` registered AFTER their `Route::resource()` — resource `show` `GET {model}` captures literal string "trash" → trash views permanently unreachable via named route. Quest itself is correctly ordered (trash before resource). | `routes/web.php:36-37,48-49,56-57` |
| SEC-QST-002 | No `EnsureTenantHasModule` on any LmsQuests route — module not plan-gated; any active tenant accesses quest features regardless of subscription. Systemic pattern (SEC-LMS-001). | `RouteServiceProvider.php` |
| SEC-QST-003 | `saveAnswerGrade()` — no `Gate::authorize()`; any authenticated user can POST arbitrary marks for any student's quest answer (grading data-integrity bypass). | `LmsQuestController.php:1114` |
| SEC-QST-004 | `getSubjectsByClass()` — no `Gate::authorize()`; AJAX endpoint exposes class/subject associations to any authenticated user. | `LmsQuestController.php:506` |
| SEC-QST-005 | Four QuestQuestionController AJAX endpoints have no `Gate::authorize()`: `getSections()`, `getSubjectGroups()`, `getLessons()`, `getTopics()` — exposes school structural data. | `QuestQuestionController.php:130,154,165,194` |
| SEC-QST-007 | Two QuestAllocationController AJAX endpoints have no `Gate::authorize()`: `getTargetOptions()`, `getQuests()`. | `QuestAllocationController.php:652,720` |
| TEN-QST-001 | `Modules\Prime\Models\AcademicSession` imported and used in both `LmsQuestController` and `Quest` model (tenant context). Migration FK references `global_db.glb_academic_sessions`; `Prime::AcademicSession` resolves to `prime_db` — cross-layer DB mismatch in quest code generation and academic hierarchy. | `LmsQuestController.php:29`, `Quest.php:15`, `2026_06_15_150344_create_lms_quests_table.php:46` |
| BUG-QST-003 | Undefined `$usageTypeId` captured in `search()` closure when `$onlyUnused=true` — assignment commented out; original intent (filter by usage type ID) dead code; PHP 8.2 emits undefined-variable warning on closure capture. | `QuestQuestionController.php:311-323` |
| BUG-QST-004 | `bulkStore()` double-parses `questions_data`: first parse (lines 543-555) and `$ordinalMap` discarded after pre-auth checks; second parse (lines 599-614) restarts from scratch with different structure. Pre-auth business rules at lines 556-584 use different data than insertion uses. | `QuestQuestionController.php:539-754` |
| BUG-QST-005 | `addQuestions()` legacy endpoint: no `Gate::authorize()`, no DB transaction, no duplicate `QuestionUsageLog` prevention. | `QuestQuestionController.php:1454` |
| BUG-QST-006 | Duplicate quest code generation: `Quest::boot()` `creating` hook generates code model-side AND `LmsQuestController::store()/update()` generate and assign `quest_code` before create/update — controller path overwrites model-generated code; both paths use cross-layer `AcademicSession::find()` (TEN-QST-001). | `LmsQuestController.php:574-586,664-675`, `Quest.php:104` |
| BUG-QST-POL | `QuestPolicy` defines `view()` four times (lines 22, 29, 37, 45) and `update()` twice (lines 53, 69) — PHP fatal `Cannot redeclare QuestPolicy::view()` when the class is first instantiated. Currently latent (controllers use string Gate), becomes P0 on any model-based auth call. `LmsQuestsServiceProvider` imports and registers the class. | `QuestPolicy.php:22,29,37,45,53,69` |
| MIG-QST-002 | Alter migration `down()` references non-existent FK `fk_quest_lesson` and column `lesson_id` on `lms_quests` (never created); `migrate:rollback` on this migration fails. | `2026_06_18_100000_update_lms_quests_and_scopes.php:31-38` |
| PERF-QST-001 | Dashboard `score_distribution` calls `->get(['percentage'])` on `QuizQuestResult` — fetches ALL result rows to PHP then bins in foreach; should use MySQL `SUM(CASE WHEN percentage BETWEEN x AND y THEN 1 ELSE 0 END)`. | `LmsQuestController.php:425-446` |
| D30-QST | All 4 FormRequests return `authorize(){return true;}` (platform baseline 90%; not independently blocking). | `app/Http/Requests/Quest*.php` |

### P2

| Code | Issue | File:Line |
|------|-------|-----------|
| SCH-QST-001 | `allocation_type` stored as ENUM (D29): `['CLASS','GROUP','SECTION','STUDENT']`; should be `sys_dropdowns` FK. | `2026_06_15_150346_create_lms_quest_allocations_table.php:16` |
| PHANTOM-QST-001 | `show_result_immediately` in `Quest::$fillable` and `$casts` but no migration column; silently ignored on write, null on read. | `Quest.php:49,70` |
| PHANTOM-QST-002 | `pending` in `QuestRequest` rules and `prepareForValidation` (annotated "ONLY NEW COLUMN") but no backing DB column and not in `$fillable`. | `QuestRequest.php:57,78` |
| PERF-QST-002 | `ClassSection::find($request->class_section_id)` called ~8 times per dashboard load (once per metric) with no memoization. | `LmsQuestController.php:dashboardStats` |
| BUG-QST-010 | `QuestAllocation::target()` morphTo uses `target_table_name` as morph type column; morphMap registered in ServiceProvider covers CLASS/GROUP/STUDENT but NOT `sch_class_section_jnt` (stored for SECTION) — `$allocation->target` returns null for SECTION allocations. | `QuestAllocation.php:94`, `LmsQuestsServiceProvider.php:46-51` |
| BUG-QST-011 | `QuestAllocationRequest::getTargetTable()` returns `'sch_sections'` for SECTION; `Rule::exists` validates raw section_id; controller overwrites `target_id` with junction ID — validation and stored value are inconsistent. | `QuestAllocationRequest.php:300-303` |
| BUG-QST-012 | FK naming inconsistency: `QuestAllocation::attempts()` uses `quest_allocation_id`; `publishHiddenRecommendations()` queries `lms_quiz_quest_attempts.allocation_id` — one is wrong; `attempts()` relation may always return empty. | `QuestAllocation.php:64`, `QuestAllocationController.php:575` |
| N+1-QST-001 | `Quest::getStatisticsAttribute()` and `Quest::getSummaryAttribute()` fire 3-5 queries each per call; dangerous if iterated over a quest list. | `Quest.php:465,624` |

### Strengths

- Usage-guard pattern (5 `*UsageCheckService`) applied consistently to all 4 CRUD controllers.
- `QuestAllocationController` is the best-structured controller: full DB transactions, Gate checks, usage-guard, and error logging throughout.
- Recommendation hook correctly fires: `QuizQuestResultPublished::dispatch()` at `LmsQuestController:1097`.
- D25 clean (0 `$request->all()` into models; all creation paths use `$request->validated()`).
- D24 clean (`tenant.*` prefix only; no prefix variants).
- D17 clean (`activityLog()` in all mutating paths).
- D38 clean (SoftDeletes on all 4 models and migrations).
- MorphMap registration in ServiceProvider correctly resolves CLASS/GROUP/STUDENT polymorphic targets.

### Lessons

- [2026-06-29 | QST] `Gate::policy(Model::class, PolicyClass::class)` does NOT autoload the policy class — PHP defers until instantiation. Duplicate method definitions in a policy are invisible until model-based auth is triggered. Audit `*Policy.php` for duplicate method names as a standard three-way check step.
- [2026-06-29 | QST] When auditing a morphMap (`Relation::morphMap([...])`), verify ALL possible values of the polymorphic type column (including those written by helper `getTargetTable()` methods) are registered. A missing entry silently returns null from `$model->target`.
- [2026-06-29 | QST] Three-way reconcile (DDL ↔ migration ↔ model) is the most reliable method for catching NOT NULL column mismatches treated as optional by the application. MIG-QST-001 (`topic_id`) is a concrete example.

Report: `3-Audit_Reports/V1_Jun-2026/LmsQuests_Complete_Audit_2026-06-29.md`.

---

### Payment (PAY) — Mode X Complete Audit (2026-06-29, Technical Auditor)

Health **40/100 (P0-capped; uncapped ≈19)**. Deploy: **NO-GO**. Pre-existing issues SEC-PAY-001/004/008, BUG-PAY-001 are **RESOLVED** in the refactored codebase. The architecture is sound (ULID IDs, encrypted credentials, HMAC webhook middleware, polymorphic Payable interface, append-only audit log, 6 gateway drivers) but implementation gaps in routing, authorization, tenancy, and transactional integrity block every core flow.

#### P0
| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-PAY-002 | **Dead PaymentHistory model** — `ptm_payment_histories` dropped by migration 100102; `PaymentHistory.php` still references it → `SQLSTATE[42S02]` on any touch | `Modules/Payment/app/Models/PaymentHistory.php:12` |
| BUG-PAY-003 | **RefundController has zero routes** — `store()` and `index()` built but unreachable from any HTTP client | `routes/web.php`, `routes/api.php` |
| BUG-PAY-004 | **apiResource mismatch** — `Route::apiResource('payments', PaymentController::class)` generates `index/store/update/destroy` (500 each — methods absent); controller methods `initiate/callback/cancel` never routed | `routes/api.php:7` |
| SEC-PAY-009 | **No PaymentPolicy class** — `$this->authorize('initiate', $payable)` in `PaymentController::initiate()` throws `PolicyNotRegisteredException` on every payment attempt; no Policies/ dir exists | `PaymentController.php` (initiate) |
| TEN-PAY-001 | **API routes missing tenancy middleware** — `mapApiRoutes()` applies only `middleware('api')`; no `InitializeTenancyByDomain`, no `EnsureTenantIsActive`; all `/api/v1/payments/*` requests hit central DB | `Providers/RouteServiceProvider.php` (mapApiRoutes) |
| DAT-PAY-001 | **No DB::transaction in `PaymentService::initiate()`** — Payment record created before gateway API call; orphan 'initiated' record persists on gateway failure; directly violates REQ-PAY-002 AC2 | `Services/PaymentService.php` (initiate) |

#### P1
| Code | Issue | File:Line |
|------|-------|-----------|
| SEC-PAY-010 | **`cancel()` zero authorization** — no Gate/policy check; any authenticated user can cancel any payment by ULID when routes are wired (IDOR) | `PaymentController.php` (cancel) |
| SEC-PAY-011 | **D39: `payment.gateway.*` permissions never seeded** — `PaymentDatabaseSeeder` is a stub; no seeder defines `payment.gateway.{viewAny,create,update,delete,...}`; Finance Admin / Bursar effectively locked out; also D24 (prefix not `tenant.*`) | `PaymentGatewayController.php`, `database/seeders/` |
| SEC-PAY-012 | **Razorpay handler never posts callback for verification** — `handler()` in checkout blade redirects to fee-summary without posting `razorpay_payment_id/order_id/signature` to server; server-side success confirmation depends entirely on webhook delivery (REQ-PAY-002 AC3 partial) | `resources/views/razorpay/process-payment.blade.php:21–24` |
| TEN-PAY-002 | **No `EnsureTenantHasModule` on any route group** — any tenant accesses payment features regardless of plan | `Providers/RouteServiceProvider.php` |
| DAT-PAY-002 | **Over-refund possible** — `RefundService::initiate()` checks `amount > payment->amount` only; sum of prior successful refunds not subtracted → total refunds can exceed original amount; also missing `lockForUpdate`; BR-PAY-009 violated | `Services/RefundService.php` (initiate) |
| MIG-PAY-001 | **D17: `OfflinePaymentRecord.$fillable` has `'method'`; migration column is `'mode'`** — any create call throws `SQLSTATE[42S22]: Unknown column 'method'`; also missing `bank_name`, `cheque_date`, `clearance_status`, `receipt_number` from fillable | `Models/OfflinePaymentRecord.php` vs migration 100106 |
| BUG-PAY-005 | **`priority` not in `PaymentGateway.$fillable`** — `PaymentGatewayController::store/update` set `priority` explicitly but Eloquent silently drops it; gateway ordering permanently lost | `Models/PaymentGateway.php`, `Controllers/PaymentGatewayController.php` |
| BUG-PAY-006 | **`callback()` passes `$request->all()` to `$driver->verify()`** — unvalidated raw input used for payment confirmation path | `Controllers/PaymentController.php` (callback) |
| BUG-PAY-007 | **`getAvailableDrivers()` hardcoded to Razorpay** — BillDesk, CCAvenue, Paytm, PhonePe, Offline fully implemented but not selectable in admin UI; violates REQ-PAY-013 | `Controllers/PaymentGatewayController.php` (getAvailableDrivers) |
| BUG-PAY-008 | **ReconciliationController and routes absent** — `PaymentReconciliation` model + `ptm_payment_reconciliations` table exist; no controller, no routes; REQ-PAY-009 not met | `Modules/Payment/` (no ReconciliationController.php) |
| JOB-PAY-001 | **`ProcessWebhookJob` queries tenant tables without explicit tenancy re-init** — `handle()` queries `PaymentGateway` + `Payment` (both tenant tables); relies on `QueueTenancyBootstrapper` being registered; P0 if bootstrapper absent | `Jobs/ProcessWebhookJob.php` (handle) |

#### P2
| Code | Issue | File:Line |
|------|-------|-----------|
| DAT-PAY-003 | **D29: 6 ENUM columns across 5 migrations** — `ptm_payment_gateways.type`, `ptm_payments.status`, `ptm_payment_refunds.status`, `ptm_offline_payment_records.mode`, `ptm_offline_payment_records.clearance_status`, `ptm_payment_reconciliations.status` | Migrations 100101, 100102, 100103, 100106, 100107 |
| BUG-PAY-009 | **D17: `PaymentWebhook.$fillable` has `payment_id`; migration has no such column** — relationship `payment()` always null; explicit set throws 42S22 | `Models/PaymentWebhook.php` vs migration 100105 |
| BUG-PAY-010 | **`failure_reason` column exists but not in `Payment.$fillable`; `markFailed()` never writes it** — all payment failure reasons are permanently lost | `Models/Payment.php`, `Services/PaymentService.php` (markFailed) |
| BUG-PAY-011 | **Missing views: refund management, webhook log admin, payment detail, receipt download** — 4 functional areas have backend logic but no UI; REQ-PAY-007/008/011/012 UI gaps | `resources/views/` |
| PERF-PAY-001 | **`GatewayManager::resolve()` queries DB on every call** — no `Cache::remember()`; also `InitiatePaymentRequest::rules()` queries active gateways on every request | `Services/GatewayManager.php` (resolve) |
| DEAD-PAY-001 | **`EventServiceProvider.$listen=[]` + `$shouldDiscoverEvents=true` but no `app/Listeners/` dir** — 8 events (PaymentSucceeded, PaymentFailed, RefundSucceeded, etc.) fire into void; fee invoice never marked paid, no receipt, no accounting voucher, no notification | `Providers/EventServiceProvider.php` |

#### P3
| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-PAY-012 | **`OfflineGateway::initiate()` never writes to `ptm_offline_payment_records`** — returns synthetic reference but write path missing | `app/Gateways/OfflineGateway.php` (initiate) |
| DEAD-PAY-002 | **`PaymentHistoryModelTest.php` tests dead model** — will throw `Table not found` on any DB touch | `tests/Unit/PaymentHistoryModelTest.php` |

#### Verified Good
- Webhook HMAC-SHA256: `VerifyWebhookSignature` middleware reads raw body before JSON decode; `hash_equals()` timing-safe ✓
- Credential encryption: `PaymentGateway.credentials` cast `encrypted:array`; column is TEXT (not JSON) since encrypted blob is not valid JSON ✓
- ULID public identifiers: `ptm_payments.ulid` + `ptm_payment_refunds.ulid` prevent ID enumeration ✓
- Audit log immutability: `PaymentAuditLog` has `$timestamps=false`, no SoftDeletes, append-only via AuditService ✓
- Webhook route correctly outside `auth` middleware (SEC-PAY-008 resolved) ✓
- Store-then-queue webhook pattern: HTTP 200 returned immediately, processing async ✓

Report: `3-Audit_Reports/V1_Jun-2026/Payment_Complete_Audit_2026-06-29.md`.

---

## Notification Module (NTF) — Mode X Audit 2026-06-29

> Full report: `3-Audit_Reports/V1_Jun-2026/Notification_Complete_Audit_2026-06-29.md`
> Health: **34/100 | NO-GO | 8 P0 findings**

### P0

| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-NTF-003 | **ALL 12 controllers use `prime.*` Gate prefix instead of `tenant.*`** — every NTF action is unauthorized for tenant users; includes `NotificationManageController`, `ProviderMasterController`, `ChannelMasterController`, all others | All controllers in `Modules/Notification/app/Http/Controllers/` |
| BUG-NTF-005 | **`ProcessNotificationJob::dispatch($notification)` commented out** — notifications can never be triggered from the UI | `NotificationManageController.php:579` |
| BUG-NTF-011 | **`canBeProcessed()` method absent from Notification model** — called at controller:556 → PHP Fatal on any `process()` request | `Notification.php` model + `NotificationManageController.php:556` |
| ARCH-NTF-001 | **`ProcessNotificationJob` class does not exist** — entire delivery pipeline has no execution vehicle; no `app/Jobs/` directory in Notification module | `Modules/Notification/` (missing) |
| TEN-NTF-001 | **`Tenant::all()` / `Tenant::get()` in 5 controllers (7 call sites)** — uses `Modules\Prime\Models\Tenant` from tenant DB context; queries `prime_db.tenants`; exposes full tenant list to school users | `NotificationManageController:243`, `TemplateController:288/382/445`, `ResolvedRecipientController:285`, `NotificationThreadController:283`, `UserPreferenceController:218` |
| SEC-NTF-001 | **Provider API credentials stored as plaintext** — `api_key_encrypted` and `api_secret_encrypted` in `$fillable` but no `encrypted` cast in `$casts`; BR-NTF-011 violated | `ProviderMaster.php` ($casts) |
| MIG-NTF-001 | **`ntf_delivery_logs.provider_id` NOT NULL but `logDelivery()` passes nullable `$providerId`** — every delivery log INSERT fails with errno 1048 when no provider (e.g., in-app delivery) | `NotificationService.php:logDelivery()` + migration `2026_06_16_111148` |
| MIG-NTF-002 | **`ntf_delivery_logs.resolved_user_id` NOT NULL but service passes `$payload['user_id'] ?? null`** — INSERT fails when user_id absent in payload | `NotificationService.php:logDelivery()` + migration `2026_06_16_111148` |

### P1

| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-NTF-004 | **store()/update() use `$request->field` not `$request->validated()`** — FormRequest validation result bypassed | `NotificationManageController.php:274,371` |
| BUG-NTF-007 | **`create()` and `edit()` have no Gate::authorize()** — any authenticated user can access | `NotificationManageController.php:228,337` |
| BUG-NTF-009 | **`getRouteKeyName()` returns `'notification_uuid'` but controllers use `findOrFail($id)` with integer** — route model binding conflict | `Notification.php:92` |
| BUG-NTF-010 | **`resolvedRecipients()` and `logs()` relationships commented out** | `Notification.php:154,178` |
| TEN-NTF-002 | **`Modules\GlobalMaster\Models\Dropdown` imported in Notification and NotificationDeliveryLog models** — status/priority relationships query `global_db` from tenant context | `Notification.php`, `NotificationDeliveryLog.php` |
| TEN-NTF-003 | **`Dropdown::query()` (GlobalMaster) in `NotificationService::logDelivery()`** — cross-DB lookup from tenant service layer | `NotificationService.php:204` |
| VAL-NTF-001 | **6 of 11 FormRequests return bare `true` in `authorize()`** (D30 pattern) — NotificationTargetRequest, NotificationThreadMemberRequest, NotificationThreadRequest, ProviderMasterRequest, ScheduleAuditRequest, UserPreferenceRequest | `Modules/Notification/app/Http/Requests/` |
| VAL-NTF-002 | **4 FormRequests use `prime.*` prefix in `authorize()`** — same wrong-prefix bug as controllers | NotificationRequest, DeliveryQueueRequest, TemplateRequest, ResolvedRecipientRequest |
| JOB-NTF-001 | **`ProcessSystemNotification` listener (ShouldQueue) has no tenancy re-initialization** — queued execution calls `NotificationService::trigger()` without tenant DB context | `Listeners/ProcessSystemNotification.php:handle()` |
| ARCH-NTF-002 | **`RecipientResolutionService` does not exist** — CLASS/SECTION/GROUP targets cannot be expanded; opt-out enforcement (BR-NTF-002) impossible | `Modules/Notification/app/Services/` (missing) |
| ARCH-NTF-003 | **Notification inbox absent** — no inbox views or API endpoints; REQ-NTF-030/031/032 not started | `resources/views/` |
| ARCH-NTF-004 | **`notifications:process-due` artisan command does not exist** — scheduled/recurring notifications cannot fire | `Modules/Notification/app/Console/` (missing) |

### P2

| Code | Issue | File:Line |
|------|-------|-----------|
| ORM-NTF-001 | **`scopeReadyToDispatch()` incorrectly includes `DRAFT` in whereIn** — DRAFT must never be queued (BR-NTF-001) | `Notification.php` |
| VAL-NTF-003 | **`exists:tenants,id` validation rule in NotificationRequest** — `tenants` is in `prime_db`; cross-DB `exists:` rule fails in tenant context | `NotificationRequest.php` |
| PERF-NTF-001 | **`NotificationManageController::index()` god-method 8+ queries** — no pagination, no tabbed AJAX | `NotificationManageController.php:index()` |
| PERF-NTF-002 | **`Schema::hasColumn()` in `destroy()` hot path** — expensive schema introspection on every delete | `NotificationManageController.php:428` |
| PERF-NTF-003 | **`NotificationTemplate::all()` unbounded query in `create()`/`edit()`** | `NotificationManageController.php:230` |
| DDL-NTF-001 | **`dlt_template_id VARCHAR(50)` missing from `ntf_templates`** — DLT compliance (BR-NTF-010, REQ-NTF-011) blocked | Migration `2026_06_16_111140` |
| DDL-NTF-002 | **`deleted_at` missing from `ntf_user_devices`** — cannot soft-delete stale device tokens | Migration `2026_06_16_111138` |
| DDL-NTF-003 | **FK references `sys_user` (singular); should be `sys_users` (plural)** | `ntf_user_devices`, `ntf_resolved_recipients` migrations |
| DAT-NTF-001 | **15 ENUM columns across 10 of 15 NTF migrations** (D29 pattern) | 10 migrations |
| IMPL-NTF-001 | **SMS delivery is stub only** — `switch/default` branch; no MSG91/Twilio adapter | `NotificationService.php:dispatchToChannel()` |
| IMPL-NTF-002 | **Push (FCM) delivery not implemented** — device token model exists; dispatch not wired | `NotificationService.php` |
| IMPL-NTF-003 | **WhatsApp delivery not implemented** | `NotificationService.php` |
| IMPL-NTF-004 | **`logDelivery()` early-returns on null $resolvedRecipientId** — delivery not logged for most trigger paths | `NotificationService.php:200` |

### P3

| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-NTF-012 | **Circular fallback check validates only self-reference (depth 1); BR-NTF-013 requires depth-5 traversal** | `ChannelMasterController.php:411` |
| DEAD-NTF-001 | **`use Modules\Notification\Models\Template;` stale import in Notification model** — unused; template() uses NotificationTemplate::class | `Notification.php` |
| CODE-NTF-001 | **0 tests for any NTF functionality** | `tests/Feature/`, `tests/Unit/` |

### Verified Good

- Web RSP tenancy middleware stack: InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + auth + verified ✓
- `InAppSystemNotification` delivery: fully functional end-to-end ✓
- `sendEmail()` call: active (previously commented out; now fixed) ✓
- `ScheduleAuditController` and routes: both present and active ✓
- `SystemNotificationTriggered` event + `ProcessSystemNotification` listener wiring: correct ✓
- `ntf_channel_master` unique constraint: added 2026-06-24 ✓
- `sys_dropdowns` FK in tenant tables: confirmed tenant table (D-MSH-009) — no cross-DB FK ✓
- Template render `{{key}}` / `{{ key }}` both supported ✓
- Worker locking schema in `ntf_delivery_queue`: supports horizontal scaling ✓

Report: `3-Audit_Reports/V1_Jun-2026/Notification_Complete_Audit_2026-06-29.md`.

---

### Prime (PRM) — Mode X Complete Audit (2026-06-29)

**Central module on prime_db (prm_* + sys_* + bil_*). Health: 40/100 (P0-capped; uncapped ≈ 87). Deploy: NO-GO.**

#### P0
| Code | Issue | File:Line |
|------|-------|-----------|
| BUG-PRM-001 | **`prm_tenant_domains.db_password` stored in plaintext** — Domain model has no `encrypted` cast; TenantDomainController::store() passes raw password via `Domain::create($validated)` | `app/Models/Domain.php`, `TenantDomainController.php:73` |
| SEC-PRM-001 | **`RolePermissionController::getPermissions()` has zero Gate authorization** — any authenticated user enumerates all role permissions as JSON; violates BR-PRM-020 | `Http/Controllers/RolePermissionController.php:311-315` |
| SEC-PRM-003 | **`UserController::update()` explicitly passes `is_super_admin` via `$request->only()`** — any admin can elevate any account to Super Admin via PUT request; violates BR-PRM-007 | `Http/Controllers/UserController.php:144` |
| GAP-PRM-003 | **`SetupTenantDatabase` creates root tenant user with `Hash::make('password')`** — every provisioned school has the same predictable root password; no email sent; violates BR-PRM-009 | `app/Jobs/SetupTenantDatabase.php:82` |

#### P1
| Code | Issue | File:Line |
|------|-------|-----------|
| TEN-PRM-001 | **`tenancy()->initialize($tenant)` without `->end()` at two sites** — DropdownNeedController::getMigrationTables() (line 479) and ::getTableColumns() (line 641) leak tenant DB context | `Http/Controllers/DropdownNeedController.php:479, 641` |
| BUG-PRM-006 | **Wrong gate on three TenantController methods** — `completeTenantSetup()`, `toggleStatus()`, `tenantPlanToggleStatus()` all use `prime.tenant-group.update` instead of `prime.tenant.update`; violates BR-PRM-013 | `Http/Controllers/TenantController.php:211, 634, 661` |
| SEC-PRM-002 | **Three debug/test routes accessible in production** — `testEmail()`, `sendTestEmail()` (hardcoded to yopmail), `testNotification()` registered without `App::isLocal()` guard; violates BR-PRM-018 | `EmailController.php`, `NotificationController.php:86` |
| GAP-PRM-001 | **`GenerateInvoicesCommand` does not exist** — `registerCommands()` empty; billing schedule → invoice pipeline non-functional; BR-PRM-016/017 cannot be met | `Providers/PrimeServiceProvider.php` |
| BUG-PRM-010 | **`UserController::usersByRole()` ignores `$role` parameter** — returns `User::paginate(10)` (all users); violates AC-007-04 | `Http/Controllers/UserController.php:50` |
| SEC-PRM-004 | **`DropdownNeedController::filterOptions()` AJAX endpoint has no Gate** | `Http/Controllers/DropdownNeedController.php` |
| BUG-PRM-011 | **PrimeServiceProvider double-registers AcademicSession** — `SessionBoardSetupPolicy` overwrites `AcademicSessionPolicy` (last `Gate::policy()` wins); AcademicSessionPolicy dead | `Providers/PrimeServiceProvider.php` |
| GAP-PRM-004 | **New platform user does not receive login credentials by email** — `UserCreatedNotification` goes to super admins; `LoginMail` unused in store(); violates BR-PRM-019 | `Http/Controllers/UserController.php:98` |
| MIG-PRM-001 | **`create_tenants_table.php` down() calls `dropIfExists('tenants')`** — table is `prm_tenant`; rollback is a no-op or destroys wrong table | `database/migrations/2025_10_10_000010_create_tenants_table.php:61` |

#### P2
| Code | Issue | File:Line |
|------|-------|-----------|
| D30-PRM | **All 7 FormRequests return bare `true` in `authorize()`** — 100% rate (platform baseline 90%) | `Http/Requests/` (all 7 files) |
| D25-PRM | **3 D25 sites** — AcademicSessionController::store/update() and TenantGroupController::update() use `$request->all()` with FormRequest injected | `AcademicSessionController.php:42,80`, `TenantGroupController.php:99` |
| BUG-PRM-009 | **UserController::index() stub data** — `$totalRoles=100`, `rand()` for student/class counts | `Http/Controllers/UserController.php:30-36` |
| BUG-PRM-STUB | **TenantController::destroy() is empty stub wired to live route** — DELETE silently does nothing | `Http/Controllers/TenantController.php:620` |
| FILL-PRM-001 | **`super_admin_flag` (STORED generated column) in User `$fillable`** — writing it via Eloquent triggers MySQL 3105 error | `app/Models/User.php` |
| BUG-PRM-007 | **Stale duplicate model** — `Modules/Prime/Models/DropdownNeed.php` outside `app/Models/`; not autoloaded | `Modules/Prime/Models/DropdownNeed.php` |
| PERF-PRM | **Raw `SHOW TABLES`/`SHOW COLUMNS FROM` in AJAX hot path** (DropdownNeedController); **`Menu::find()` in while-loop in Navbar** — N+1 and no caching | `DropdownNeedController.php:479,641`, `Navbar.php` |

#### Verified Good (PRM)
- `DB::transaction()` wraps 5-step plan assignment in TenantPlanAssigner — atomic ✓
- `TenantController::store/update/updateTenantPlan()` use `$request->validated()` ✓
- `TenantController::resetSetup()` exists and re-dispatches SetupTenantDatabase — GAP-PRM-002 RESOLVED ✓
- RolePermissionController::destroy() calls `$role->delete()` — BUG-PRM-008 RESOLVED ✓
- All `$tenant->run()` and `tenancy()->central()` usages auto-revert — SAFE ✓
- Tenant model implements TenantWithDatabase + HasDatabase + HasDomains — BR-PRM-010 PASS ✓
- SetupTenantDatabase `$tries=1` — BR-PRM-008 PASS ✓
- MySQL triggers prevent super-admin deletion/demotion at DB level ✓
- D24 CLEAN (all permissions use `prime.*` prefix) ✓
- D36 CORRECT (super_admin_flag UNIQUE constraint active) ✓
- D38 CLEAN (sys_roles + prm_billing_cycles both have deleted_at in migrations) ✓

Report: `3-Audit_Reports/V1_Jun-2026/Prime_Complete_Audit_2026-06-29.md`.

---

## PTM — Parent-Teacher Meeting (Mode X Audit 2026-06-29)

**Health: 38/100 — NO-GO | 5 P0, 19 P1, 5 P2, 3 P3**
**Report:** `3-Audit_Reports/V1_Jun-2026/PTM_Complete_Audit_2026-06-29.md`

### P0 — Critical Blockers

| ID | Finding | Location |
|----|---------|----------|
| SEC-PTM-001 | **6 AJAX endpoints in PtmManagementController have ZERO Gate::authorize.** Any authenticated tenant user can query all teacher lists, student lists, teacher slot schedules, and event scheduling data. Routes: `ptm/ajax/class-teachers`, `ptm/ajax/assignment-teachers`, `ptm/ajax/eligible-additional-teachers`, `ptm/ajax/event-teachers`, `ptm/ajax/teacher-slots`, `ptm/ajax/event-students`. | `PtmManagementController.php` lines 227, 277, 312, 338, 376, 398 |
| DAT-PTM-001 | **D36: `ptm_slot_bookings.active_booking_key` is a plain `unsignedInteger` column** (not VIRTUAL GENERATED as D35 mandates). Column is absent from `$fillable` and never assigned in service — all rows permanently have `NULL`. MySQL UNIQUE treats two NULLs as distinct, so `uq_ptmBooking_event_teacher_studentActive` and `uq_ptmBooking_slot_studentActive` enforce **nothing**. BR-PTM-005 (1 confirmed booking per student/teacher/event) has zero DB-level enforcement. | Migration `2026_06_16_094315` line 23; `PtmSlotBooking.php`; `PtmSlotBookingService.php` |
| DAT-PTM-002 | **No lockForUpdate() in `PtmSlotBookingService::create()`.** Read-check-write pattern with no pessimistic lock: two concurrent booking requests both pass capacity and uniqueness checks, both insert, overbooking the slot and creating duplicate CONFIRMED bookings for the same student+teacher+event. | `PtmSlotBookingService.php` lines 70–115 |
| DAT-PTM-003 | **`PtmSlotService::generateFromAssignment()` calls `PtmSlot::where()->forceDelete()` at entry.** `ptm_slot_bookings.slot_id` FK has `onDelete('cascade')`. Republishing an assignment permanently hard-deletes all booking records for that assignment with no warning, soft-delete, or audit trail. | `PtmSlotService.php` line 43; migration FK line 30 |
| DAT-PTM-004 | **`PtmAssignmentService::delete()` calls `slots()->forceDelete()`.** FK cascade then hard-deletes all `ptm_slot_bookings` records. BR-PTM-013 (protect assignment with active bookings) not implemented: no confirmed-booking guard before `forceDelete()`. Admin soft-delete of an assignment silently annihilates all booking history. | `PtmAssignmentService.php` lines 191–204 |

### P1 — High

| ID | Finding | Location |
|----|---------|----------|
| BUG-PTM-001 | All 9 entity trash routes shadowed by resource `show` route (BUG-HPC-009 pattern). All trash/restore/forceDelete routes permanently unreachable for all 9 entities. | `routes/web.php` — all 9 resource groups |
| SEC-PTM-002 | All 18 FormRequests return `authorize()=true` (D30). | All 18 Request files |
| SEC-PTM-003 | `PtmCombinedViewController::setup()` and `bookings()` have no Gate::authorize. Any authenticated tenant user sees all PTM setup data and all bookings. | `PtmCombinedViewController.php` lines 53, 170 |
| TEN-PTM-001 | `session('tenant_id') ?? 1` in `Notification::create()` — 4 occurrences across `PtmSlotBookingService` (create, cancel) and `PtmAssignmentService` (create, update). Session is unreliable; fallback `?? 1` creates notifications on tenant 1. | `PtmSlotBookingService.php` lines 120, 176; `PtmAssignmentService.php` lines 71, 171 |
| TEN-PTM-002 | API routes registered with only `'api'` middleware — no tenancy stack (no InitializeTenancyByDomain, no EnsureTenantIsActive). | `RouteServiceProvider.php` lines 45–53 |
| VAL-PTM-001 | `cancel()` reads `$request->input()` without FormRequest; `reschedule()` uses inline `$request->validate()`. | `PtmSlotBookingController.php` lines 178, 205 |
| D17-PTM-001 | `PtmSlotBooking.$fillable` includes `'updated_by'` but `ptm_slot_bookings` migration has no `updated_by` column. Any update with `updated_by` throws QueryException. | `PtmSlotBooking.php` line 33; migration `2026_06_16_094315` |
| D39-PTM-001 | All PTM permissions absent from `TenantRolePermissionSeeder`. Regular staff roles cannot access any PTM feature on fresh tenants. | `database/seeders/TenantRolePermissionSeeder.php` |
| BR-PTM-013 | Assignment delete does not check for confirmed bookings (see also DAT-PTM-004). | `PtmAssignmentService.php` line 191 |
| BR-PTM-015 | Unpublish soft-deletes slots without checking or cancelling confirmed bookings; parents not notified. | `PtmAssignmentService.php` lines 235–246 |
| PERF-PTM-001 | Management dashboard: 14+ queries per load including 8 separate `onlyTrashed()->count()` calls + unbounded `AcademicTerm::all()`, `Section::all()`. | `PtmManagementController.php` |
| PERF-PTM-002 | `PtmBlockoutService::notifyAffectedBookings()`: re-queries guardians per booking (N+1). | `PtmBlockoutService.php` |
| PERF-PTM-003 | `PtmSlotService::syncSlotStatusForBlockout()`: one `isSlotBlockedByBlockout()` EXISTS query per slot (N+1). | `PtmSlotService.php` lines 353–380 |
| PAY-PTM-001 | 7 payment tables created in migrations (2026-06-18 batch), zero models/controllers/services. Payment workflow entirely unimplemented. | `database/migrations/tenant/` 8 payment files |
| PARENT-PTM-001 | REQ-PTM-010 (parent self-booking) not implemented. No parent-portal routes or views. | FRD Section 3.2 REQ-PTM-010 |
| TEST-PTM-001 | 0 test files. | `Modules/Ptm/` |
| JOB-PTM-001 | `Notification::create()` runs synchronously inside `DB::transaction()` in 4 service methods. | `PtmSlotBookingService.php`, `PtmAssignmentService.php` |
| DEAD-PTM-001 | `PtmCombinedViewController::scheduling()` has no route. Route `combined.scheduling` → `PtmManagementController::index()`. 55-line method is dead code. | `PtmCombinedViewController.php` lines 109–163 |

### P2 — Medium

| ID | Finding |
|----|---------|
| D29-PTM-001 | `ptm_events.default_meeting_mode` ENUM (D29 violation) |
| D29-PTM-002 | `ptm_slots.status` ENUM (D29 violation) |
| D29-PTM-003 | `ptm_slot_bookings.status` ENUM (D29 violation) |
| PERF-PTM-006 | `PtmAssignmentController::create/edit()`: `PtmEventClassSection::with()->get()` unbounded |
| ARCH-PTM-001 | `PtmServiceProvider::loadMigrationsFrom()` points to empty module migrations dir |

### Verified Good (PTM)
- Full tenancy middleware stack on web routes (InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + auth + verified) ✓
- 9 policies registered via Gate::policy() in PtmServiceProvider ✓
- Three-level parameter fallback (Assignment → BatchTemplate → Event) correctly implemented in PtmSlotService ✓
- Both static (buffer=0) and dynamic (buffer>0) slot generation modes correct ✓
- Blockout overlap detection: `start_time < slotEnd AND end_time > slotStart` correct ✓
- Reschedule = atomic cancel + rebook in single transaction ✓
- All CRUD controllers use `$request->validated()` — D25 clean ✓
- Activity logging consistent across all mutation operations ✓
- `{!! !!}` in Blade views exclusively for pagination `->links()` — XSS clean ✓
- SoftDeletes on all 9 models; DDL has `softDeletes()` — D38 clean ✓
- `PtmBatchTemplate.$table = 'ptm_batches_template'` matches migration ✓
- No `$request->all()` usage — D25 clean ✓
- Permission prefix consistent `tenant.ptm_*` — D24 clean ✓

---

## QuestionBank (QNS) — Mode X Audit 2026-06-29

### P0 — Critical Blockers

| ID | Severity | Finding | Evidence |
|----|----------|---------|---------|
| SEC-QNS-003 | P0 | Duplicate `Gate::policy(QuestionBank::class, ...)` in QuestionBankServiceProvider lines 69 + 75 — `QuestionBankPolicy` is dead; all `tenant.question-bank.*` Gate checks dispatch to `AiQuestionGeneratorPolicy` (PRM-D-001 pattern) | `QuestionBankServiceProvider.php:69,75` |
| BUG-QNS-002 | P0 | Routes `GET /get-ai-providers` and `GET /ai-provider-status/{id}` map to `getAIProviders()` and `checkProviderStatus()` — neither method exists in AIQuestionGeneratorController → HTTP 500 | `routes/web.php:108-109` |
| BUG-QNS-003 | P0 | `reviewApprove()` writes `status='PUBLISHED'` directly, bypassing the mandated `APPROVED` intermediate state — FSM violation; BR-QNS-008 violated; APPROVED state unreachable via UI | `QuestionBankController.php:2690` |
| SEC-QNS-004 | P0 | API routes in `RouteServiceProvider::mapApiRoutes()` apply only `'api'` middleware — no tenancy stack (no InitializeTenancyByDomain, no PreventAccessFromCentralDomains, no EnsureTenantIsActive) | `RouteServiceProvider.php:60-62` |

Note: BUG-QNS-001 (demo data early return) and SEC-QNS-002 (API keys — now partially fixed, keys moved from hardcoded to env()) are pre-existing entries.

### P1 — High Priority

| ID | Finding | Evidence |
|----|---------|---------|
| MIG-QNS-001 | `qns_question_statistics.discrimination_index`, `.guessing_factor`, `.avg_time_taken_seconds` are NOT NULL in migration but `QuestionStatisticsService` correctly writes null per D31 spec → MySQL SQLSTATE 1048 runtime error on statistics write for new/non-MCQ/no-telemetry questions | `2026_06_16_114247_create_qns_question_statistics_table.php:17-21` |
| ORM-QNS-001 | `QuestionBank::scopeApproved()` references column `ques_reviewed_status` which does not exist (column is `status`) — scope silently returns 0 rows; assessment builders receive empty question pools | `QuestionBank.php:210` |
| BUG-QNS-004 | 6 AJAX cascade endpoints in AIQuestionGeneratorController (`getSections`, `getSubjectGroups`, `getSubjects`, `getLessons`, `getTopics`, `downloadCSV`) have no `Gate::authorize()` — correction: SEC-QNS-001 claim of "ZERO auth on ALL methods" is inaccurate; `index()`, `generateQuestions()`, `saveQuestions()` are correctly gated | `AIQuestionGeneratorController.php:84,105,126,149,175,960` |
| D39-QNS-001 | No permission seeder for any `tenant.question-bank.*` ability — module is super-admin-only; no non-SA user can access any feature | No seeder found in `database/seeders/` or `Modules/QuestionBank/database/seeders/` |
| SEC-QNS-006 | `env('CHATGPT_API_KEY')` and `env('GEMINI_API_KEY')` direct in controller — returns null after `config:cache`; AI silently fails in cached-config production | `AIQuestionGeneratorController.php:531,578` |

### P2 — Medium Priority

| ID | Finding |
|----|---------|
| D29-QNS-001 | 6 ENUM columns in `qns_questions_bank`: `content_format`, `media_location_for_question`, `media_location_for_teacher_explanation`, `ques_owner`, `availability`, `status` |
| D29-QNS-002 | 1 ENUM column in `qns_question_media_jnt`: `media_purpose` |
| ORM-QNS-002 | `QuestionBank::questionMediaStores()` uses `hasMany(QuestionMediaStore::class, 'id')` with `'id'` as FK — wrong; relationship should use `belongsToMany` through `qns_question_media_jnt` |
| D30-QNS-001 | All 6 FormRequests return `Auth::check()` — no resource-level authorization (D30 pattern) |

### Verified Good (QNS)
- Full tenancy middleware on web routes (InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + auth + verified) ✓
- D24 clean — all Gate calls use `tenant.` prefix (no `tennat.` or other typos) ✓
- D25 clean — no `$request->all()` into models found ✓
- D36 clean — no `storedAs`/`virtualAs` columns in any of 13 QNS migrations ✓
- D37 clean — status stored as ENUM string; review_status_id uses FK correctly ✓
- D38 clean — SoftDeletes/timestamps match DDL on all 13 tables ✓
- D31 Formula Contract: QuestionStatisticsService fully implements all 9 spec sections including Kelley D-index (27% rule), MCQ guessing factor, outlier-guarded time metrics — code-verified ✓
- UUID binary pattern: BINARY(16) with `Str::uuid()->getBytes()` in creating hook + multi-fallback hex accessor ✓
- Version snapshot pattern: clean-slate update + JSON snapshot in DB::transaction in QuestionBankController::update() ✓
- `reviewReject()` enforces `comment=required` validation ✓
- `index()`, `generateQuestions()`, `saveQuestions()` in AIQuestionGeneratorController are correctly gated ✓

---

## Scheduler (SDL) — Mode X Complete Audit (2026-06-29)

### P0 — Critical (Must fix before any use)

| ID | Severity | Finding | Evidence |
|----|----------|---------|---------|
| SEC-SDL-001 | P0 | Zero `Gate::authorize()` across all 7 SchedulerController methods (index, create, store, show, edit, update, destroy) — any authenticated user including tenant school staff can attempt to access all schedule management pages; no SchedulePolicy exists anywhere | `SchedulerController.php:1-86` (entire file; no Gate import) |
| BUG-SDL-001 | P0 | Execution engine entirely absent: `SchedulerService::runSchedule()` does not exist, no Artisan command (Console/ directory absent), `registerCommands()` and `registerCommandSchedules()` fully commented out in SchedulerServiceProvider — module stores schedule records but executes nothing | `SchedulerService.php:14-41` (only dueSchedules/isDue); `SchedulerServiceProvider.php:44-58` (all commented) |
| BUG-SDL-002 | P0 | `update()` and `destroy()` methods have empty bodies — PUT /scheduler/schedule/{id} silently returns HTTP 200 with no update; DELETE silently returns HTTP 200 with no delete | `SchedulerController.php:76-78` (update), `SchedulerController.php:83-85` (destroy) |

### P1 — High Priority

| ID | Finding | Evidence |
|----|---------|---------|
| TEN-SDL-001 | Module RSP applies full tenant middleware stack (InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive) to a central-only (prime_db) module — PreventAccessFromCentralDomains blocks the central domain where Platform Admins operate, making /schedulers/* routes inaccessible from the correct domain; from tenant domains, controller queries crash (schedules table absent in tenant_db) | `RouteServiceProvider.php:41-48` |
| BUG-SDL-003 | `trashedSchedule()` method does not exist in SchedulerController but is registered as a route in all 3 central web.php blocks — any access to GET /scheduler/schedule/trash throws BadMethodCallException → HTTP 500 | `routes/web.php:305,552,882`; `SchedulerController.php:1-86` (no method) |
| RT-SDL-001 | Scheduler routes registered THREE TIMES in central web.php (lines 301, 548, 878) — identical resource + trash blocks; last registration wins, first two are shadowed | `routes/web.php:301-308`, `548-555`, `878-885` |
| BUG-SDL-004 | Double validation in store(): ScheduleRequest FormRequest runs its rules first, then store() body calls `$request->validate()` again with DIFFERENT inline rules — any custom rules added to ScheduleRequest (cron validator, job-key whitelist) will be bypassed by the inline re-validation | `SchedulerController.php:34-42`; `ScheduleRequest.php:13-43` |
| VAL-SDL-001 | `job_key` only validates as 'string' — not validated against `JobRegistry::all()` keys; arbitrary strings silently accepted and stored (BR-SDL-002 violated) | `ScheduleRequest.php:23-26`; `JobRegistry.php:17-23` |
| VAL-SDL-002 | `cron_expression` only validates as 'string','max:255' — no cron syntax validation; invalid expressions stored and silently skipped at isDue() (dragonmantank/cron-expression is already a project dependency) | `ScheduleRequest.php:28-31` |
| SEC-SDL-002 | `ScheduleRequest::authorize()` returns hardcoded `true` (D30) — both controller gate and FormRequest gate are absent simultaneously | `ScheduleRequest.php:49-51` |
| ORM-SDL-001 | `Schedule` model has no `SoftDeletes` trait and `schedules` migration has no `deleted_at` — archive/restore feature (REQ-SDL-004, BR-SDL-010, BR-SDL-016) is architecturally impossible; forceDelete would conflict with RESTRICT FK from schedule_runs | `Schedule.php:1-44`; migration:1-30 (no softDeletes()) |
| PERF-SDL-001 | `index()` uses unbounded `Schedule::orderBy()->get()` — no pagination; NFR-SDL-001 requires 15/page | `SchedulerController.php:18` |

### P2 — Medium Priority

| ID | Finding |
|----|---------|
| MIG-SDL-001 | `schedules.schedule_type` is `->enum('prime','tenant')` in migration (D29 violation) |
| MIG-SDL-002 | `schedule_runs.status` is `->enum('running','success','failed')` in migration (D29 violation) |
| DAT-SDL-001 | Missing columns in both tables — schedules: deleted_at, created_by, failure_count (failure_count referenced in index.blade.php:56 → always null/blank); schedule_runs: deleted_at, created_by, output, attempt |
| ORM-SDL-002 | `Schedule.$fillable` missing last_run_at and next_run_at — both exist in migration and are needed by the execution engine; also missing datetime casts |
| ORM-SDL-003 | `ScheduleRun` missing explicit `$table` (infers correctly by convention); both models missing ORM relationships (Schedule.runs() HasMany; ScheduleRun.schedule() BelongsTo) |
| DEAD-SDL-001 | `SchedulerService.dueSchedules()` is never called anywhere — entire service layer orphaned until BUG-SDL-001 is fixed |
| BUG-SDL-005 | `store()` hardcodes `schedule_type => 'prime'` — school-level (tenant-scoped) schedules cannot be created; create.blade.php has no scope selector |

### P3

| ID | Finding |
|----|---------|
| ARCH-SDL-001 | `SchedulerType` uses PHP class constants, not PHP 8.1+ backed enum (project runs PHP 8.2+) |
| ARCH-SDL-002 | JobRegistry has 3 entries; FRD target is 10+ |
| DEAD-SDL-002 | 16 tests in SchedulerModuleTest.php intentionally assert broken state (zero Gate, empty stubs) — will FAIL after security fix; must be inverted |

### Verified Good (SDL)
- Central web.php route names: `route('central.scheduler.schedule.index')` IS valid — outer `Route::domain()->name("central.")` group at web.php:67 prefixes all inner route names; views and store() redirect are correct ✓
- D25 clean — no `$request->all()` into models; store() uses validated() result ✓
- D36 N/A — no generated columns in SDL schema ✓
- SchedulerService::isDue() correctly catches Throwable for malformed cron; well-implemented ✓
- JobRegistry::get() validates SchedulableJob interface compliance before returning ✓
- SchedulableJob contract (description(), allowedScheduleTypes()) well-designed ✓
- Views use `{{ }}` only (XSS-safe); no unescaped output ✓

---

## SchoolSetup (SCH) — Mode X Complete Audit (2026-06-30)

### P0 — Critical (Must fix before any use)

| ID | Severity | Finding | Evidence |
|----|----------|---------|---------|
| SEC-SCH-001 | P0 | `is_super_admin`, `super_admin_flag`, `password`, `user_type` all in `User.$fillable` — any user with school-setup.user.update permission can self-promote to platform super-admin via crafted PUT (Gate::before() bypass at AppServiceProvider:65-67); `password` is also mass-assignable | `Modules/SchoolSetup/app/Models/User.php:59,67-70` |
| SEC-SCH-002 | P0 | `EnsureTenantHasModule` absent from SchoolSetup RSP middleware stack — all 56+ controllers are accessible to tenants without a SchoolSetup license (subscription bypass) | `Modules/SchoolSetup/app/Providers/RouteServiceProvider.php:40-48` |
| BUG-SCH-012 | P0 | `sch_entity_group_members` table migration missing — `EntityGroupMember` model exists (`$table='sch_entity_group_members'`) but no `create_entity_group_members_table` migration was ever written; any entity-group-member CRUD throws `SQLSTATE[42S02]` | `database/migrations/tenant/` (only `2026_06_15_145412_create_entity_groups_table.php` exists for entity groups); `Modules/SchoolSetup/app/Models/EntityGroupMember.php` |
| FE-SCH-001 | P0 | XSS: `{!! old('name', $user->name) !!}` in user/edit.blade.php renders user-controlled name unescaped into an HTML attribute — a crafted name can inject arbitrary JavaScript into any admin session | `Modules/SchoolSetup/resources/views/user/edit.blade.php:38` |
| DAT-SCH-001 | P0 | D36: `sch_org_academic_sessions_jnt.current_flag` is a plain `boolean()->default(false)` with NO unique constraint — multiple sessions can have `current_flag=true` simultaneously; BR-SCH-009 ("exactly one current session") is unenforced at the DB level | `database/migrations/tenant/2026_06_15_145404_create_sch_org_academic_sessions_jnt_table.php:31` |
| BUG-SCH-017 | P0 | `EmployeeProfileController` has 5 live-routed methods that do not exist: `addProfile`, `addTeacherProfile`, `updateDocuments`, `generateQrCode`, `toggleProfileStatus` — every call throws `BadMethodCallException` → HTTP 500; employee onboarding steps 2+ are completely broken | `Modules/SchoolSetup/routes/web.php:117-121`; `Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php` (methods absent) |

### P1 — High Priority

| ID | Finding | Evidence |
|----|---------|---------|
| TEN-SCH-001 | D41: `session('tenant_id')` used in 6 locations across 3 controllers for notification/audit inserts — unreliable outside HTTP request lifecycle (queued jobs, artisan commands, concurrent requests); can write records to wrong tenant | `EmployeeSeparationController.php:54,210`; `EmployeeLeaveApplicationController.php:466,953,1028`; `EmployeeLeaveApprovalController.php:384` |
| TEN-SCH-002 | `tenancy()->initialize($tenant)` called with no matching `tenancy()->end()` in two console commands — context leaks into subsequent Artisan calls in same process; dangling tenant DB connection | `Modules/SchoolSetup/app/Console/Commands/ProcessLeaveAccrual.php:40`; `ProcessDailyAttendance.php:46` |
| SEC-SCH-020 | D30: All 26 FormRequests return bare `authorize(){ return true; }` — zero FormRequest-level ownership or permission checks across the entire module | All 26 files in `Modules/SchoolSetup/app/Http/Requests/` |
| SEC-SCH-018 | `EmployeeReportController::index()` has no `Gate::authorize()` — HR analytics (attendance, leave balance, separation history) accessible to any authenticated user | `Modules/SchoolSetup/app/Http/Controllers/EmployeeReportController.php:28` |
| BUG-SCH-011 | D38: `sch_designations` migration has no `softDeletes()` but `Designation` model uses the `SoftDeletes` trait — `$designation->delete()` throws `SQLSTATE[42S22] Unknown column 'deleted_at'` | `database/migrations/tenant/2026_06_15_145912_create_sch_designations_table.php`; `Modules/SchoolSetup/app/Models/Designation.php:7` |
| BUG-SCH-013 | `UserController::index()` uses `rand(1000,2000)` and `rand(10,30)` for student/class counts in production; `Gate::authorize` block commented out on lines 30-32 | `Modules/SchoolSetup/app/Http/Controllers/UserController.php:30-35` |
| BUG-SCH-023 | `ClassSubjectManagementController::store()`, `update()`, `destroy()` are completely empty — all state-changing operations silently do nothing; routes are live with no auth | `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectManagementController.php:29,52,59` |
| DAT-SCH-002 | D36: `sch_employee_leave_balance.available_balance` is a plain `decimal(5,2)` — DDL spec declares it as `GENERATED ALWAYS AS (opening_balance + carry_forward - total_used) STORED`; `ProcessLeaveAccrual` increments `opening_balance` without updating `available_balance`, causing balance drift | `database/migrations/tenant/2026_06_16_104157_create_sch_employee_leave_balance_table.php:21`; `ProcessLeaveAccrual.php` |
| ORM-SCH-001 | `EmployeeBankDetail` stores `account_number`, `ifsc_code`, `iban` as plaintext VARCHAR — no `encrypted` cast in `$casts`; BR-SCH-039 requires encryption of employee bank details | `Modules/SchoolSetup/app/Models/EmployeeBankDetail.php:17-34` |
| PERF-SCH-003 | `Role::all()` called in 15+ controller request paths without caching (UserController, EmployeeProfileController, LeaveApprovalPolicyController, etc.) and `Department::all()` / `Subject::all()` with no bounds | 15+ controllers; representative: `EmployeeProfileController.php:312,718`; `UserController.php:37,51` |
| MIG-SCH-001 | D38 + D29 combined: `sch_designations` missing `softDeletes()` (see BUG-SCH-011); 11 ENUM columns across 4 migrations violate D29 (sch_employees: 5 ENUMs including 8-value `employment_status` FSM; sch_employee_leave_applications: 9-value `status` FSM; sch_holidays: 8-value `holiday_type`; sch_staff_leave_config: 2 ENUMs) | `2026_06_15_150600_create_sch_employees_table.php`; `2026_06_16_104201_create_sch_employee_leave_applications_table.php`; `2026_06_16_104147_create_sch_holidays_table.php`; `2026_06_16_104159_create_sch_staff_leave_config_table.php` |

### Verified Good (SCH)
- `sch_academic_term.current_flag`: nullable boolean + UNIQUE constraint on column — functional pattern (one non-NULL true per session) ✓
- `sch_employees_profile.active_flag`: nullable boolean + UNIQUE on (employee_id, role_id, active_flag) — functional pattern ✓
- `DB::transaction()` used consistently in EmployeeLeaveApplicationController (multi-table writes) ✓
- `with()` eager loading used in EmployeeProfileController::show() — no N+1 on main profile load ✓
- Cross-DB FKs correctly target correct global_db tables; index created on FK columns ✓ (constraint enforcement is the gap — DDL-SCH-01 P2)
- Module uses module-owned migrations (loadMigrationsFrom) — correct for prime_db module ✓

---

## TimetableFoundation (TTF) — Mode X Complete Audit (2026-06-30)

Full report: `3-Audit_Reports/TimetableFoundation_Complete_Audit_2026-06-30.md`
Health score: **39 / 100 (P0-capped)**. Deploy gate: **NO-GO**.
BA P0 refuted: `Config::scopeByStatus()` does NOT exist in current code — Config correctly uses `is_active`. FRD AC-002.6 "current bug: fails" annotation does not match live code.

### P0 — Critical

| ID | Finding | Evidence |
|----|---------|---------|
| SEC-PLATFORM-003 (TTF) | `EnsureTenantHasModule` absent from RSP web middleware — all 138+ routes accessible without subscription | `Modules/TimetableFoundation/app/Providers/RouteServiceProvider.php` |
| SEC-TTF-004 | API routes have only `['auth:sanctum']` — no tenancy middleware; apiResource runs without tenant DB context | `Modules/TimetableFoundation/routes/api.php` |
| SEC-PLATFORM-008 (TTF) | 19 of 23 policy classes completely unregistered in ServiceProvider; duplicate `Gate::policy(SchoolShift::class, ...)` call at line 66-67 silently kills `TimingProfilePolicy` | `Modules/TimetableFoundation/app/Providers/TimetableFoundationServiceProvider.php` |
| TEN-TT-001 | `Modules\Prime\Models\AcademicSession` (prime_db) imported and queried in 6 controllers + 3 models in tenant context — returns wrong school's session data | `TimetableFoundationController.php:51,910`; `ActivityController.php:11,60`; `WorkingDayController.php:9,53+`; `ClassWorkingDayController.php:9,464,581`; `RequirementConsolidationController.php:10,41`; `TimetableController.php:9,34,156`; `Models/Timetable.php:13,88`; `Models/ClassWorkingDay.php:7,71`; `Models/ClassModeRule.php:8,110` |
| ARCH-TT-001 | `TtGenerationStrategyController` (SmartTimetable) and `ClassSubjectGroupController` (SchoolSetup) wired into TTF route file — if either module is disabled, entire TTF route file fails to load (500 on all 138 routes) | `Modules/TimetableFoundation/routes/web.php:29-30,304,313` |

### P1 — High Priority

| ID | Finding | Evidence |
|----|---------|---------|
| ORM-TT-001 | `TeacherAvailablity` model class name typo (missing 'i') — any correctly-spelled import fails with class-not-found | `Modules/TimetableFoundation/app/Models/TeacherAvailablity.php` |
| BUG-TT-013 | `TeacherAvailabilityController::store()` is a live stub — only runs Gate check, returns nothing; POST /teacher-availability silently discards submissions | `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php:39-41` |
| PERF-TT-014 | `TimetableFoundationController` God controller: 2561 lines; mixed Pre-Req dashboard + Config + page routing + SmartTimetable model imports | `Modules/TimetableFoundation/app/Http/Controllers/TimetableFoundationController.php` |
| PERF-TT-015 | `ActivityController` God controller: 1853 lines; imports 5 SmartTimetable models + cross-layer AcademicSession | `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php` |
| PERF-TT-016 | `RequirementConsolidationController`: 1219 lines; inline 80-line DB::transaction bodies | `Modules/TimetableFoundation/app/Http/Controllers/RequirementConsolidationController.php` |
| VAL-TT-001 | All 4 FormRequests return `authorize(){ return true; }` (D30) — zero FormRequest-level ownership checks | `app/Http/Requests/TimingProfileRequest.php:32`; `AcademicTermRequest.php:17`; `SchoolTimingProfileRequest.php:45`; `ConfigRequest.php:13` |
| VAL-TT-002 | 22 of 27 controllers have no FormRequest at all — no centralized validation contract | All remaining controllers |
| ARCH-TT-002 | SmartTimetable models bidirectionally imported in TTF (TTF is supposed to be foundation; STT is the consumer) — `GenerationRun`, `TtGenerationStrategy`, `ParallelGroup`, `ClassGroupJnt`, `ClassGroupRequirement`, `ClassSubgroup`, `Constraint` | `Models/Timetable.php:15-16`; `Models/Activity.php:27`; `Models/TimetableCell.php:15`; `ActivityController.php:20-24`; `ClassSubjectSubgroupController.php:14-15`; `TimetableFoundationController.php:20,46-47` |

### P2

| ID | Finding | Evidence |
|----|---------|---------|
| MIG-TT-001 (UPDATED) | D36: `tt_room_availability.available_for_full_timetable_duration` is a plain `boolean()->default(true)` in migration but specified as STORED generated column in DDL v7.8; writes to this column succeed silently, value does not auto-update on date change. NOTE: `tt_period_set.total_periods` is plain in both migration AND DDL — consistent, not a defect (remove from prior MIG-TT-001 scope). `duration_minutes` in `tt_period_config` IS correctly GENERATED. | `database/migrations/tenant/2026_06_16_152638_create_tt_room_availability_table.php:19` |
| BUG-TT-015 | Column name typo `competancy_level` (missing 'e') entrenched in migration + model + DDL; should be `competency_level` | `database/migrations/tenant/2026_06_16_152641_create_tt_teacher_availability_table.php:31`; `app/Models/TeacherAvailablity.php` fillable |
| D29-TTF-001 | 28 `->enum()` declarations across 20 tt_ migration files (D29 ban) — highest risk: `tt_timetable.status` (5-value FSM), `tt_timetable.generation_method` (3-value), `tt_teacher_availability.competancy_level` | All 20 files; see audit report for full list |
| TEST-TT-001 | Test suite (6 files) strips all tenancy middleware in `beforeEach`; only tests unauthenticated redirects — cannot detect any tenancy, authorization, or business-rule defect | `Modules/TimetableFoundation/tests/Feature/RouteAuthenticationTest.php:17-21` |

### P3

| ID | Finding | Evidence |
|----|---------|---------|
| BUG-TT-016 | `TeacherAvailabilityController::edit()` calls `view('timetablefoundation::edit')` — wrong view name (should be `timetablefoundation::teacher-availability.edit`) | `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php` |
| DEAD-TT-003 | `BackfillSubActivityDetails` console command exists but is not scheduled | `Modules/TimetableFoundation/` Console/Commands |

### Verified Good (TTF)
- `Config` model has NO `scopeByStatus()` — BA-documented P0 refuted; `ConfigController` correctly uses `is_active` inline filter; `ConfigRequest` uses `$request->validated()` ✓
- `DB::transaction()` used consistently across multi-write operations (WorkingDayController, ClassWorkingDayController, PeriodConfigController, RequirementConsolidationController, TimetableTypeController) ✓
- `tt_teacher_availabilities.available_for_full_timetable_duration` and `no_of_days_not_available` correctly implemented as STORED generated columns via `DB::statement()` in migration ✓
- `tt_period_config.duration_minutes` correctly GENERATED (TIMESTAMPDIFF) ✓
- `tt_activities.total_periods` correctly GENERATED (duration_periods * weekly_periods) ✓
- ConfigController uses `Gate::authorize()` on all state-changing methods ✓
- No `env()` calls in TTF controllers ✓

---

## StandardTimetable (TTS) Specific

> Audit date: 2026-06-30 | Mode X Complete Technical Audit | Health Score: 30/100 (P0-capped)
> Report: `3-Audit_Reports/StandardTimetable_Complete_Audit_2026-06-30.md`

### SEC-TTS-001: Blanket viewAny Gate on All 6 Controller Methods Including Destructive Endpoints (P0)
- **Module/Area:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php` — lines 33, 85, 175, 272, 322, 375
- **Symptom:** `placeCell`, `removeCell`, `createTimetable`, `deleteTimetable` — all write/delete methods — use `Gate::authorize('standard-timetable.viewAny')`. A read-only user granted `viewAny` can delete timetables. No `StandardTimetablePolicy` class exists. The permission string `standard-timetable.viewAny` is never seeded. For non-super-admin roles the gate resolves to deny (undefined permission) — module entirely unusable.
- **Root Cause:** D39 systemic pattern (permissions unreferenced → super-admin only). Copy of initial scaffold never replaced with granular per-ability gates.
- **Fix:** (1) Create `Modules/StandardTimetable/app/Policies/StandardTimetablePolicy.php` with abilities `viewAny`, `viewClass`, `viewTeacher`, `viewRoom`, `manualPlace`, `publish`, `export`. (2) Register via `Gate::policy(Timetable::class, StandardTimetablePolicy::class)` in `StandardTimetableServiceProvider::registerPolicies()`. (3) Implement seeder to insert 7 permissions into `sys_permissions`. (4) Replace `Gate::authorize('standard-timetable.viewAny')` in destructive methods with correct ability name (`manualPlace` for place/remove/create/delete).
- **Prevention:** Every new module must have policy + seeder implemented before any route is registered. The 10-new-feature-checklist must require these as non-optional. Technical Auditor Layer 4 and Layer 6 both check for this.

### TEN-TTS-001: AcademicSession Cross-Layer FK Violation on createTimetable (P0)
- **Module/Area:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:13` (import) and `:346` (call)
- **Symptom:** `createTimetable()` stores the return value of `AcademicSession::current()->first()->id` (from `global_master_mysql`, table `glb_academic_sessions`) into `tt_timetables.academic_session_id`. That column has a hard FK to `sch_org_academic_sessions_jnt(id)` in the tenant DB. IDs from the global DB almost never match tenant rows — every `createTimetable()` call throws `errno: 1452 Cannot add or update a child row: a foreign key constraint fails` for most tenants.
- **Root Cause:** SEC-PLATFORM-007 pattern: developer imported `Modules\Prime\Models\AcademicSession` (global_master_mysql) instead of the tenant-scoped session model. The `Timetable` model's `academicSession()` relation also targets the wrong model, so any eager-load of `academicSession` in tenant context queries the wrong DB.
- **Fix:** Replace `use Modules\Prime\Models\AcademicSession;` with `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` in the controller. Fix the `Timetable` model relation (`Modules\TimetableFoundation\Models\Timetable`) to reference `OrganizationAcademicSession` instead of `AcademicSession`. Run: `grep -r "Modules\\\\Prime\\\\Models\\\\AcademicSession" Modules/StandardTimetable/ Modules/TimetableFoundation/` to find all occurrences.
- **Prevention:** Never import Prime-layer models in tenant-scoped controllers. Cross-module dependency map for any tenant module must list only tenant-db models (SchoolSetup, StudentProfile, etc.) — never Prime, Billing, or GlobalMaster. Add this as a required import audit step in Technical Auditor Layer 1.

### BUG-TTS-001: Wrong Column in Conflict Teacher Filter — Teacher Conflicts Silent (P1, pre-registered)
- **Module/Area:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:420` and `:442`
- **Symptom:** `checkConflicts()` calls `$cell->teachers->whereIn('id', $teacherIds)`. The `teachers` relation returns `TimetableCellTeacher` pivot records; the FK holding the teacher reference is `teacher_id`, not `id`. `$conflictTeachers` is always empty when the pivot record's `id != teacher_id`. The `whereHas()` query (which correctly uses `teacher_id`) identifies the conflicting cell; the post-load filter (which uses `id`) fails to extract the teacher name. Result: TEACHER_CONFLICT and TEACHER_CROSS_TT messages are built with empty teacher name arrays.
- **Root Cause:** Subtle Eloquent collection filtering error: `whereIn('id', ...)` on a pivot model filters by the pivot's own PK, not by the FK column pointing to the teacher.
- **Fix:** Change both occurrences to `->whereIn('teacher_id', $teacherIds)`.
- **Prevention:** When filtering Eloquent collections built from pivot models, always confirm the column name on the pivot model, not the related model. Write a regression unit test `ConflictDetectionTest` that asserts the teacher name is correctly returned in the conflict details JSON.

### BUG-TTS-002: removeCell() Deletes Wrong Cell in Multi-Class Timetables (P1)
- **Module/Area:** `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php:280-283`
- **Symptom:** `removeCell()` builds a lookup without `class_group_id`. In a timetable with multiple class groups, multiple cells can share the same `(timetable_id, day_of_week, period_ord)` — one per class group. `.first()` returns an arbitrary cell, potentially from a different class group than the caller intended. The wrong cell is silently deleted.
- **Root Cause:** Incomplete lookup key: the unique constraint on `tt_timetable_cells` is `(timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id)`. The query omits `class_group_id`.
- **Fix:** Add `->where('class_group_id', $validated['class_group_id'])` to the chain at line 283. Also add `class_group_id` to the `removeCell` validation rules (currently absent from `$request->validate([...])`).
- **Prevention:** Any query that is expected to retrieve a unique row must include ALL columns that form the table's unique constraint. When adding new unique indexes, audit all controller lookups for completeness.

### MIG-TTS-003: Table Name Drift Between Migration and DDL (P2)
- **Module/Area:** `database/migrations/tenant/2026_06_16_152633_create_tt_conflict_detection_table.php`
- **Symptom:** Migration creates table `tt_conflict_detections` (plural). Canonical DDL (`Timetable_DDL_v7.8.sql`) defines `tt_conflict_detection` (singular). Any TTF model referencing `tt_conflict_detection` throws "Table not found" on a migrated database because the actual table has a different name.
- **Root Cause:** Naming inconsistency between the developer who wrote the migration and the DDL author.
- **Fix:** Create a corrective migration: `Schema::rename('tt_conflict_detections', 'tt_conflict_detection')`. Update the TTF model `protected $table = 'tt_conflict_detection'`.
- **Prevention:** All new migration names must be verified against the canonical DDL document before merging. The DDL document is the source of truth.

### TTS Systemic Pattern Summary (confirmed 2026-06-30)
| Pattern | TTS State |
|---------|-----------|
| SEC-PLATFORM-003 (EnsureTenantHasModule absent) | Confirmed — all 6 routes |
| SEC-PLATFORM-007 (cross-layer AcademicSession) | Confirmed — new FK violation variant |
| D39 (permissions unreferenced) | Confirmed — 6/6 methods |
| D29 (ENUM columns) | Confirmed — 3 migrations, 6 ENUMs |
| Zero test coverage | Confirmed — 0 tests |
| activityLog() absent from mutations | Confirmed — 4 mutating methods |
| Zero service layer | Confirmed — all logic in 513-line controller |
- No live `$request->all()` mass-assignment found in reviewed controllers (D25 clean) ✓

---

## SmartTimetable — Mode X Complete Audit (2026-06-30)

> Audit: Mode X (A+B+C+G+scoped D) | Health: 40/100 (P0-capped) | DEPLOY: NO-GO
> Full report: `3-Audit_Reports/SmartTimetable_Complete_Audit_2026-06-30.md`

### SEC-TT-004: API Routes Missing All Tenancy Middleware (P0)
- **Module/Area:** `Modules/SmartTimetable/app/Providers/RouteServiceProvider.php:57`
- **Symptom:** All 7 API endpoints (generate, status, show, byClass, byTeacher, byRoom + apiResource) execute in the central prime_db context — no tenant isolation. Any API call returns empty data or corrupts the central DB.
- **Root Cause:** `mapApiRoutes()` only applies `Route::middleware('api')` — no `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, or `EnsureTenantIsActive`. This mirrors the TTF pattern (SEC-TTF-004).
- **Fix:** Add the full tenancy stack to `mapApiRoutes()`: `Route::middleware(['api', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class])`.
- **Prevention:** Every module RSP must include the tenancy stack in `mapApiRoutes()` — add this as an auditor Layer 6 checklist item for all new modules.

### DAT-TT-001: tt_parallel_groups + tt_parallel_group_activity Have NO Migration (P0)
- **Module/Area:** `Modules/SmartTimetable/app/Models/ParallelGroup.php`, `ParallelGroupActivity.php`; `Modules/SmartTimetable/routes/web.php` (live parallel-group CRUD routes)
- **Symptom:** Confirmed search: zero tenant migration files mention "parallel_group" or "tt_parallel" anywhere. On fresh tenant provision, `tenants:migrate` skips these tables. Any request to `/smart-timetable/parallel-group/*` throws `SQLSTATE[42S02]: Table 'tenant_db.tt_parallel_groups' doesn't exist`.
- **Root Cause:** Module-knowledge v1.0 incorrectly classified `tt_parallel_groups` as "DDL-backed" and `tt_parallel_group_activity` as "migration-only (GAP-DB-001)". In reality BOTH have no migration. Code was implemented but the migration was never committed.
- **Fix:** Create two tenant migrations: (1) `create_tt_parallel_groups_table.php` — id, name, anchor_activity_id FK, is_active, created_by, deleted_at, timestamps. (2) `create_tt_parallel_group_activity_table.php` — id, parallel_group_id FK, activity_id FK, is_anchor TINYINT(1) DEFAULT 0. Compound PK.
- **Prevention:** Every new model must have its migration committed before the corresponding controller routes are registered. Add a "migration exists" gate to the Technical Auditor Layer 2 checklist.

### JOB-TT-001: GenerateTimetableJob Runs Without Tenancy Context (P0)
- **Module/Area:** `Modules/SmartTimetable/app/Jobs/GenerateTimetableJob.php` (entire handle() method); `app/Providers/TenancyServiceProvider.php` (no QueueTenancyBootstrapper)
- **Symptom:** `handle()` immediately calls `GenerationRun::findOrFail($this->runId)`, `Activity::where(...)`, `SchoolDay::schoolDays()->get()`, `Room::where(...)` with no tenancy init. `QueueTenancyBootstrapper` is absent from TenancyServiceProvider. Queue workers process the job in the wrong DB context — queries either throw "table not found" or write results to prime_db.
- **Root Cause:** No explicit `tenancy()->initialize()` and no automatic bootstrapper registered. Identical pattern to Vendor/Inventory/FrontOffice/Hostel jobs (platform baseline).
- **Fix:** (1) Register `QueueTenancyBootstrapper` in `TenancyServiceProvider::bootstrappers()`. (2) Add `protected int $tenantId;` to job constructor accepting the current tenant ID. (3) At start of `handle()`: `tenancy()->initialize(Tenant::find($this->tenantId))`. (4) Wrap in `finally { tenancy()->end(); }`. OR use `$tenant->run(fn() => ...job body...)`. (5) Update all dispatch() call sites to pass `tenant()->id`.
- **Prevention:** Any job referencing a tenant-prefixed model must implement the `TenantAware` interface or perform explicit tenancy init. QueueTenancyBootstrapper should be platform-standard.

### SEC-TT-005: Permission Prefix Split — tenant.* vs smart-timetable.* (P1)
- **Module/Area:** `Modules/SmartTimetable/app/Http/Controllers/TtGenerationStrategyController.php` — lines 28, 41, 93, 109, 125, 196, 231, 265, 285, 320 (tenant.*); line 245 (smart-timetable.*)
- **Symptom:** 16 gate calls use `tenant.timetable-generation-strategy.*`; 1 call at line 245 uses `smart-timetable.generation-strategy.restore`. The Policy checks `tenant.*` for restore, so the controller call at :245 maps to a non-existent permission — silently allows or denies depending on Gate fallback.
- **Root Cause:** Copy-paste error during refactor. Two prefixes in use for one module's resource.
- **Fix:** Standardize all TtGenerationStrategyController calls to use `tenant.timetable-generation-strategy.*` (matching the Policy), OR migrate entire module to `smart-timetable.*` and update the Policy. Remove the mismatched call at :245.
- **Prevention:** D24 fix — permission seeder should declare a single prefix per module. Technical Auditor Layer 5.4 detects this pattern.

### DEAD-TT-004: Route Closure in routes/web.php Breaks route:cache (P1)
- **Module/Area:** `Modules/SmartTimetable/routes/web.php:52-57`
- **Symptom:** `php artisan route:cache` fails — closures are not serializable. Blocks route caching for the entire application.
- **Root Cause:** A redirect fallback for GET /generate/generate-prime was implemented as an inline closure instead of a named controller method.
- **Fix:** Extract to `TimetableGenerationController::redirectGeneratePrime()` and wire: `Route::get('generate/generate-prime', [TimetableGenerationController::class, 'redirectGeneratePrime'])`.
- **Prevention:** Never use closure routes in production modules. Technical Auditor Layer 12.4 detects this pattern.

### PERF-TT-017: Schema::getColumnListing() Called Per Dashboard Request (P1)
- **Module/Area:** `Modules/SmartTimetable/app/Http/Controllers/TimetableMenuController.php:53`
- **Symptom:** `safeCount()` helper calls `Schema::getColumnListing($table)` on every dashboard page load for ≥4 tables — ≥4 information_schema hits per request per tenant.
- **Root Cause:** Column listing used as runtime softdelete detection instead of hardcoded.
- **Fix:** Replace with a constant: `const SOFT_DELETE_TABLES = ['tt_timetables', 'tt_timetable_cells', ...]`.
- **Prevention:** Never call Schema:: introspection in request hot paths. Cache or constant-fold at deploy time.

### PERF-TT-018: AcademicTerm::all() Unbounded in ConstraintController (P1)
- **Module/Area:** `Modules/SmartTimetable/app/Http/Controllers/ConstraintController.php:42, 59, 115, 245`
- **Symptom:** Loads all academic terms (potentially decades of history) on every constraint form view.
- **Fix:** Replace with `AcademicTerm::where('is_active', 1)->orderByDesc('start_date')->limit(10)->get()`.

### FE-TT-001: json_encode of Teacher/Room Names Without JSON_HEX Flags (P2)
- **Module/Area:** `Modules/SmartTimetable/resources/views/smart-timetable/reports.blade.php:214, :254`; `pages/partials/generation-history/_list.blade.php:378-416`
- **Symptom:** `{!! json_encode($teacherLoads->pluck('name')->values()) !!}` embeds user-entered teacher names as raw JSON in chart labels. A teacher name containing `</script><script>alert(1)</script>` injects JavaScript.
- **Fix:** Use `@json($variable)` (Blade helper applies all JSON_HEX flags) or add `JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_QUOT|JSON_HEX_AMP` flags to json_encode.

### FE-TT-002: {!! $cti['detail_html'] !!} Unescaped in Conflict View (P2)
- **Module/Area:** `Modules/SmartTimetable/resources/views/preview/partials/_class-conflicts.blade.php:220`
- **Symptom:** Unescaped HTML in conflict detail rendering. Source of `$cti['detail_html']` not found in app code — origin unclear.
- **Fix:** Trace origin; if user-derived, sanitize before assignment and switch to `{{ $cti['detail_html'] }}`.

### ORM-TT-002: 12 Active Models Missing Boolean Casts for is_* Fields (P2)
- **Module/Area:** `Modules/SmartTimetable/app/Models/` — Constraint.php, ConstraintCategoryScope.php, RoomUnavailable.php, TeacherUnavailable.php, TeacherAvailabilityDetail.php, PriorityConfig.php, ApprovalLevel.php, and 5 others
- **Symptom:** `$constraint->is_hard` returns string "0" which is truthy in Blade — conditional display always shows "Hard". Logic on is_* fields is silently wrong.
- **Fix:** Add `protected $casts = ['is_hard' => 'boolean', 'is_active' => 'boolean']` to each affected model.

### MIG-TT-002: 21 Phantom Models With No Migration (P2)
- **Module/Area:** `Modules/SmartTimetable/app/Models/` — ApprovalWorkflow, ApprovalRequest, ApprovalDecision, BatchOperation, EscalationLog, GenerationQueue, ImpactAnalysis*, MlModel, Optimization*, PatternResult, PredictionLog, RevalidationSchedule/Trigger, TrainingData, VersionComparison*, WhatIfScenario
- **Symptom:** Accidental reference to any of these models throws SQLSTATE[42S02]. No migration exists for any of them.
- **Fix:** Delete non-ML phantoms (ApprovalDecision/Level/Notification/Request/Workflow, BatchOperation/Item, EscalationLog/Rule, ConflictResolution*, Impact*, Revalidation*, WhatIfScenario, VersionComparison*); create migrations for GenerationQueue and ApprovalRequest if those features are planned.

### PERF-TT-019: AnalyticsController index() Without Pagination (P2)
- **Module/Area:** `Modules/SmartTimetable/app/Http/Controllers/AnalyticsController.php`
- **Symptom:** Teacher workload and room utilization queries fetch all records with ->get(), no paginate(). Unbounded growth as school accumulates years.
- **Fix:** Add `->paginate(25)` to workload/utilization queries; pass page from view.

### STT Mode X Systemic Pattern Summary (confirmed 2026-06-30)
| Pattern | STT State |
|---------|-----------|
| SEC-PLATFORM-003 (EnsureTenantHasModule absent) | Confirmed — both route groups |
| API RSP missing tenancy middleware | Confirmed — NEW P0 (SEC-TT-004) |
| No migration for core tables | Confirmed — tt_parallel_groups P0 (DAT-TT-001) |
| Job tenancy missing | Confirmed — GenerateTimetableJob (JOB-TT-001) |
| D30 (FormRequest authorize=true) | Confirmed — 13/13 (VAL-TT-003) |
| D29 (ENUM in migrations) | CLEAN — 0 of 49 migrations |
| D25 ($request->all() mass-assign) | CLEAN — 0 occurrences |
| D24 (permission prefix split) | Confirmed — tenant.* vs smart-timetable.* (SEC-TT-005) |
| Route closure breaking route:cache | Confirmed — web.php:52 (DEAD-TT-004) |
| Schema:: introspection in hot path | Confirmed — dashboard (PERF-TT-017) |
| json_encode without HEX flags (XSS P2) | Confirmed — reports.blade.php (FE-TT-001) |

---

## StudentFee (FIN) — Mode X Complete Audit (2026-06-30)

### SEC-FIN-01: Seeder Route Exposed in Production (P0)
- **Module/Area:** `Modules/StudentFee/routes/web.php:22`, `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php:91`
- **Symptom:** `GET /student-fee/seeder` registered under `auth`+`verified` middleware with no role check. Any authenticated tenant user can trigger it. `seederFunction()` body has all calls commented out now (returns "SEEDING DONE"), but 14 seeder methods remain in the controller — uncommenting one line writes test data to production.
- **Root Cause:** Seeder route was never removed after local development.
- **Fix:** Remove `Route::get('/seeder', ...)` from `web.php:22`. Remove `seederFunction()` and all `seeder*()` methods from `StudentFeeController`. Remove dev-only imports.
- **Prevention:** No seeder controller method should ever exist in a production module. Seeders belong in `Database/Seeders/`, not controllers.

### SEC-FIN-02: `Faker\Factory` Imported in Production Controller (P0)
- **Module/Area:** `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php:7`
- **Symptom:** `use Faker\Factory as Faker;` in production class. `faker/faker` is a `require-dev` dependency — `composer install --no-dev` causes `Class "Faker\Factory" not found` on class load, crashing any route resolved by this controller.
- **Fix:** Remove `use Faker\Factory as Faker;` and the 12 other dev-only imports from the controller.
- **Prevention:** Never import `faker/*`, `phpunit/*`, or other dev-only packages in production controllers.

### SEC-FIN-03: `EnsureTenantHasModule` Missing from Web Route Group (P0)
- **Module/Area:** `Modules/StudentFee/app/Providers/RouteServiceProvider.php:41–51`
- **Symptom:** Any authenticated tenant user can access all fee routes regardless of whether the tenant has the StudentFee module licensed.
- **Fix:** Add `\App\Http\Middleware\EnsureTenantHasModule::class.':StudentFee'` to `mapWebRoutes()` middleware array.
- **Prevention:** Every module RSP `mapWebRoutes()` must include `EnsureTenantHasModule::class.':ModuleName'`. This is SEC-PLATFORM-003.

### SEC-FIN-34: API Routes Missing All Tenancy Middleware (P0)
- **Module/Area:** `Modules/StudentFee/app/Providers/RouteServiceProvider.php:61`, `Modules/StudentFee/routes/api.php`
- **Symptom:** `mapApiRoutes()` applies only `'api'` middleware. Inner `api.php` adds `auth:sanctum`. NO tenancy middleware in chain. API requests get no tenant DB connection — Eloquent runs against central DB or throws.
- **Root Cause:** Same systemic pattern as SEC-TT-004, SEC-TTF-004. Module RSP API methods universally miss tenancy stack.
- **Fix:** Add tenancy middleware to `mapApiRoutes()`: `InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class`.
- **Prevention:** Any module with `routes/api.php` must verify `mapApiRoutes()` includes full tenancy stack. Platform-wide audit needed.

### BUG-FIN-05: `balance_amount` Stale in DB from Creation (P1)
- **Module/Area:** `database/migrations/tenant/2026_06_16_092641_create_fee_invoices_table.php:25`, `Modules/StudentFee/app/Models/FeeInvoice.php:144–158`, `Modules/StudentFee/app/Http/Controllers/FeeInvoiceController.php:59–73`
- **Symptom:** `fee_invoices.balance_amount` is `DECIMAL(12,2)` with no default. Store() never sets it → defaults to `0` (MySQL permissive) not `total_amount`. `updatePayment()` updates `paid_amount` and `status` but not `balance_amount` → stays at `0` forever. Dashboard `->orderByDesc('balance_amount')` returns wrong sort. All BI/raw SQL queries on `balance_amount` are wrong.
- **Root Cause:** V2 documented `balance_amount` as a GENERATED STORED column. Migration creates it as plain DECIMAL. PHP helper `getBalanceAmount()` computes correctly at runtime but DB column is orphaned.
- **Fix (Option A):** Add to `updatePayment()`: `'balance_amount' => $this->total_amount - $newPaid`. Set correct initial value in all create paths.
- **Fix (Option B — preferred):** Migrate to `GENERATED ALWAYS AS (total_amount - paid_amount) STORED` column (D36 pattern).
- **Prevention:** When V2 says GENERATED, verify with `grep -n "storedAs\|virtualAs\|->storedAs\|GENERATED ALWAYS"` in the migration before trusting.

### BUG-FIN-06: `ApplyFines` Scheduler Commented Out (P1)
- **Module/Area:** `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php:105–111`
- **Symptom:** Fine calculation never runs automatically. `action_on_expiry` rules never trigger. Schools lose fine revenue silently.
- **Fix:** Uncomment and configure: `$schedule->command('fee:apply-fines')->dailyAt('00:30')->withoutOverlapping()`.
- **Prevention:** Any `registerCommandSchedules()` with only commented code is a production gap. Technical Auditor L10 must verify schedule body is non-empty.

### BUG-FIN-07: `FeeHeadMasterPolicy` Dead — Overridden by `StudentFeeManagementPolicy` (P1)
- **Module/Area:** `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php:75, 89`
- **Symptom:** `Gate::policy(FeeHeadMaster::class, FeeHeadMasterPolicy::class)` at line 75 then immediately overridden by `Gate::policy(FeeHeadMaster::class, StudentFeeManagementPolicy::class)` at line 89. Laravel last-wins: `FeeHeadMasterPolicy` is unreachable.
- **Root Cause:** `StudentFeeManagementPolicy` uses `FeeHeadMaster::class` as a virtual model key for hub dashboard authorization — reuses the same model class, creating a collision.
- **Fix:** Use `Gate::define('tenant.student-fee-management.viewAny', [StudentFeeManagementPolicy::class, 'viewAny'])` instead of a duplicate policy binding. Keep `FeeHeadMasterPolicy` as the sole `FeeHeadMaster::class` policy.
- **Prevention:** Never register the same model class twice in `Gate::policy()`. Grep for duplicate model registrations in all ServiceProvider::registerPolicies() methods.

### BUG-FIN-08: `fee-transaction.store` Routes to Wrong Controller (P1)
- **Module/Area:** `Modules/StudentFee/routes/web.php:141`
- **Symptom:** Named route `fee-transaction.store` calls `FeeInvoiceController::store()` (creates invoice) instead of a payment-recording action. Any form POSTing to `fee-transaction.store` creates a duplicate invoice.
- **Fix:** Remove line 141. Payment recording is `fee-invoice.recordPayment` (line 142). If a dedicated `fee-transaction.store` is needed, implement `FeeTransactionController::store()`.

### BUG-FIN-35: `invoice_no` Has No UNIQUE Constraint + Race in `generateInvoiceNumber()` (P1)
- **Module/Area:** `database/migrations/tenant/2026_06_16_092641_create_fee_invoices_table.php`, `Modules/StudentFee/app/Http/Controllers/FeeInvoiceController.php:477–480`
- **Symptom:** `generateInvoiceNumber()` uses `max('id')` which is a TOCTOU race — two concurrent invoice creations get identical `max` values → same `invoice_no`. No UNIQUE constraint on `fee_invoices.invoice_no` to catch the collision → two rows with identical invoice numbers. Financial audit risk.
- **Fix:** (1) Add migration: `$table->unique('invoice_no', 'uq_fee_invoices_invoice_no')`. (2) Wrap `generateInvoiceNumber()` in `DB::transaction()` with `lockForUpdate()`.
- **Prevention:** All financial reference number generators must use DB-level uniqueness. invoice_no, transaction_no, receipt_no all need UNIQUE indexes.

### PERF-FIN-001: Bulk Invoice Generation Synchronous + N+1 in Loop (P1)
- **Module/Area:** `Modules/StudentFee/app/Http/Controllers/FeeInvoiceController.php:391–474`
- **Symptom:** `generateFeeInvoice()` loads all assignments into memory with `.get()`, then fires N+1 EXISTS queries + N INSERTs + N max('id') queries + N notification dispatches inside a foreach. 30s timeout at ~200 students.
- **Fix:** Queue a `GenerateFeeInvoicesJob`. Pre-load existing invoice assignment IDs with a single `->whereIn('student_assignment_id', ...)->pluck()` before the loop.
- **Prevention:** Any bulk financial operation over >50 records must use a queued job. GAP-FIN-15 was already identified by BA; this audit adds N+1 evidence.

### DEAD-FIN-36: Route Closures at web.php:94,107 Break `route:cache` (P2)
- **Module/Area:** `Modules/StudentFee/routes/web.php:94, 107`
- **Symptom:** `fn() => redirect()->route(...)` closures in route file prevent `php artisan route:cache`. The named routes `fee-student-concession.trashed` and `fee-fine-transaction.trashed` may resolve as null or cause cache error.
- **Fix:** Convert to controller methods: `[FeeStudentConcessionController::class, 'trashed']`.
- **Prevention:** Never use closure routes in production modules. Same as DEAD-TT-004. Platform-wide grep: `grep -rn "fn() =>" Modules/*/routes/web.php`.

### VAL-FIN-001: All 36 FormRequests Return `true` from `authorize()` (D30, P2)
- **Module/Area:** All files in `Modules/StudentFee/app/Http/Requests/`
- **Symptom:** D30 platform-wide pattern. FormRequest-level ownership checks are absent. Controllers compensate with `Gate::authorize()` (all present), so runtime security is maintained, but FormRequest auth layer is dead.
- **Fix:** For payment-critical requests (RecordFeeInvoicePaymentRequest, CancelFeeInvoiceRequest), implement meaningful `authorize()` with auth check. For others, at minimum `return auth()->check()`.

### DAT-FIN-001: 16 ENUM Columns in fee_ Migrations (D29, P2)
- **Module/Area:** Multiple `fee_*` migrations created 2026-06-16
- **Symptom:** 16 ENUM columns across: `fee_head_master.frequency`, `fee_fine_rules` (4 ENUMs), `fee_invoices.status`, `fee_transactions.payment_mode`, `.status`, `fee_concession_types.discount_type`, `.applicable_on`, `fee_scholarship_applications.status`, etc.
- **Fix:** Convert to `VARCHAR(50)` with `CHECK` constraints or app-level constants. Priority: `fee_invoices.status` (most queried).
- **Prevention:** D29 pattern — no new ENUMs in any migration.

### FIN Mode X Systemic Pattern Summary (confirmed 2026-06-30)
| Pattern | FIN State |
|---------|-----------|
| SEC-PLATFORM-003 (EnsureTenantHasModule absent) | Confirmed — SEC-FIN-03 |
| API RSP missing tenancy middleware | Confirmed — NEW P0 (SEC-FIN-34) |
| D30 (FormRequest authorize=true) | Confirmed — 36/36 (VAL-FIN-001) |
| D29 (ENUM in migrations) | Confirmed — 16 ENUMs (DAT-FIN-001) |
| D25 ($request->all() mass-assign) | CLEAN — all controllers use FormRequests |
| D24 (permission prefix split) | CLEAN — consistent `tenant.fee-*.*` across all 15 controllers |
| Seeder route in production | Confirmed — ONLY module with this (SEC-FIN-01) |
| Faker import in production | Confirmed — dev dependency risk (SEC-FIN-02) |
| Route closure breaking route:cache | Confirmed — web.php:94, :107 (DEAD-FIN-36) |
| Policy override (duplicate Gate::policy) | Confirmed — FeeHeadMasterPolicy dead (BUG-FIN-07) |
| balance_amount stale (DB integrity) | Confirmed — 0 from creation (BUG-FIN-05) |
| invoice_no UNIQUE constraint absent | Confirmed — race + no constraint (BUG-FIN-35) |
| Gate::authorize coverage | EXCELLENT — 100% of methods in all 15 controllers |
| AcademicSession cross-layer import | Confirmed — 5 models (ARCH-FIN-001) |

---

## StudentPortal (STP) — Mode X Complete Audit (2026-06-30)

> Report: `3-Audit_Reports/StudentPortal_Complete_Audit_2026-06-30.md`
> Health: **40/100 (P0-capped)** | Deploy: **NO-GO**
> Key: Multiple BA Phase 2 P0s CLEARED by live code evidence (SEC-STP-01, SEC-STP-008, SEC-STP-04, SEC-STP-09, BUG-STP-08).

### SEC-STP-03: EnsureTenantHasModule Missing from mapWebRoutes() (P0)
- **Module/Area:** `Modules/StudentPortal/app/Providers/RouteServiceProvider.php:44–55`
- **Symptom:** A student can access the StudentPortal on a tenant that does not have a StudentPortal subscription. Module-level access control bypassed.
- **Root Cause:** Platform-wide gap SEC-PLATFORM-003 — not added to RSP middleware chain.
- **Fix:** Add `\App\Http\Middleware\EnsureTenantHasModule::class` after `EnsureTenantIsActive::class` in mapWebRoutes().
- **Prevention:** All module RSPs must include EnsureTenantHasModule in mapWebRoutes(). Audit all 24 tenant module RSPs.

### SEC-STP-014: Mobile API Routes Lack role:Student|Parent Check (P1)
- **Module/Area:** `routes/api.php:26–30` (central)
- **Symptom:** Mobile routes loaded in `Route::middleware(['mobile.key', 'tenant.mobile', 'auth:sanctum'])` group — no `role:Student|Parent`. Any Sanctum-authenticated user (teacher, admin, staff) can call all 45+ student portal mobile endpoints.
- **Root Cause:** Web routes apply `role:Student|Parent` in the module RSP. Mobile routes are loaded centrally with no role constraint.
- **Fix:** Wrap STP mobile routes require with `Route::middleware(['role:Student|Parent'])->group(fn() => require ...)` in central `routes/api.php`.
- **Prevention:** All portal mobile routes (StudentPortal, ParentPortal) must have role-scoped middleware. Audit other `mobile_api.php` files for the same gap.

### SEC-STP-02: Zero Gate::authorize / Zero Policies (P1)
- **Module/Area:** All 37 STP controllers (`Modules/StudentPortal/app/Http/Controllers/`)
- **Symptom:** grep returns 0 results for Gate::authorize across all STP controllers. ServiceProvider has zero Gate::policy() registrations. Authorization is entirely: (1) `role:Student|Parent` middleware at web route group level, (2) auth-scoped DB queries (`where('student_id', auth()->user()->student->id)`).
- **Root Cause:** Design choice: portal is student-scoped, data is filtered at query time.
- **Impact:** No per-object authorization audit trail. Cannot unit-test authorization at policy layer.
- **Fix:** Register policies for ExamAttempt + AttemptCheckpoint; add Gate::authorize in exam/quiz/quest attempt entry points (instructions, start).
- **Prevention:** At minimum, every module with user-owned resources should have at least one registered policy with a viewAny ability.

### FE-STP-001: Stored XSS in Exam/Quiz/Homework Views (P2)
- **Module/Area:** `online-exam/attempt.blade.php:153`, `online-exam/result.blade.php:209`, `quiz/result.blade.php:210`, `homework/show.blade.php:69`, `my-recommendations/show.blade.php:284,339`
- **Symptom:** `{!! $q['text'] !!}`, `{!! $q['explanation'] !!}`, `{!! $hw->description !!}`, `{!! $rec->material->content_text !!}` — all rendered without any sanitization.
- **Root Cause:** Rich content from admin-created question bank / homework / recommendations is rendered raw for HTML formatting (bold, formulas, etc.).
- **Impact:** Malicious teacher account can inject JavaScript that executes on student browsers during exam attempts.
- **Safe pattern (already used):** `{!! nl2br(e($notification->data['body'])) !!}` — correct: e() escapes, then nl2br adds safe <br>, then output raw.
- **Fix:** Use HTMLPurifier or `strip_tags($content, '<strong><em><sub><sup><code><b><i><br><span><u>')` on rich content before rendering.
- **Prevention:** Any `{!! ... !!}` on DB content must pass through a sanitizer. Never raw-render teacher/admin text content directly.

### GAP-STP-012: Notification Mark-Read via HTTP GET (P2)
- **Module/Area:** `Modules/StudentPortal/routes/web.php:39`
- **Symptom:** `Route::get('/notifications/{id}/mark-read', ...)` — state mutation via GET. No CSRF protection on GET routes. Can be triggered by `<img src=...>` injection.
- **Fix:** Change to `Route::patch(...)` and update view to POST/PATCH.

### BUG-STP-001: Complaint Index Unpaginated (P2)
- **Module/Area:** `Modules/StudentPortal/app/Http/Controllers/StudentPortalComplaintController.php:52`
- **Symptom:** `$complaints = $query->orderBy('created_at', 'desc')->get()` — loads all complaints without pagination. Memory risk for high-complaint users.
- **Fix:** Replace with `->paginate(15)`.

### DAT-STP-001: 5 ENUM Columns in lms_* Tables (P2 — D29)
- **Module/Area:** migrations for lms_exam_attempts, lms_attempt_activity_logs, lms_attempt_checkpoints, lms_quiz_quest_results, lms_quest_allocations
- **Symptom:** `attempt_mode`, `status`, `attempt_type` (×2), `assessment_type`, `allocation_type` — 5 ENUM columns across 5 tables owned by STP.
- **Fix:** Migrate to VARCHAR(30) NOT NULL + CHECK constraints (MySQL 8.0.16+).

### STP Mode X Stale BA Knowledge Summary (CLEARED findings)
| BA Code | Claimed | Live Code Reality | Verdict |
|---------|---------|-------------------|---------|
| SEC-STP-01 | IDOR in proceedPayment() | Method just redirects to fee-summary; actual payment in FeePaymentController with abort_if ownership check | ✅ CLEARED |
| SEC-STP-008 | IDOR in attempt() — no allocation check | assertAllocation() called at top of ALL 6+ exam action methods (instructions, start, attempt, submit, saveAnswer, checkpoint) | ✅ CLEARED |
| SEC-STP-04 | Hardcoded dropdown ID 104 in complaint create | ComplaintCategory::parents()->get() used; no hardcoded IDs anywhere | ✅ CLEARED |
| SEC-STP-09 | User::all() in complaint controller | Not present; complaint form uses category-only data | ✅ CLEARED |
| BUG-STP-08 | PaymentGateway::all() exposes all gateways | Not found; FeePaymentController uses GatewayManager::resolve('razorpay') | ✅ CLEARED |

### STP Mode X Systemic Pattern Summary
| Pattern | Verdict |
|---------|---------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ Confirmed |
| API RSP no tenancy | PARTIAL — mapApiRoutes() maps dead scaffold; mobile tenancy via custom InitializeTenancyByMobileHeader |
| D29 ENUM columns | ✅ Confirmed (5 columns, 5 tables) |
| D30 authorize()=true | ❌ Not present (STP uses auth()->check()) |
| D25 $request->all() | ❌ Not present |
| Zero policies (SEC-STP-02) | ✅ Confirmed |
| Mobile role gap (SEC-STP-014) | 🆕 New finding |

## StudentProfile (STD) — Mode X Complete Audit (2026-06-30, Technical Auditor)
Health **40/100 (P0-capped; uncapped ≈62)**. Deploy: **NO-GO**. Report: `3-Audit_Reports/StudentProfile_Complete_Audit_2026-06-30.md`.
- **Completion revised:** ~20% (2026-04-09 Phase 2) → **~75%** (2026-06-30 Mode X). Major additions since April: StdLeaveController now exists with full leave workflow routes; Guardian, Medical, Leave Type, Attendance all functional.
- **EnsureTenantHasModule CONFIRMED PRESENT** — `module:STUDENT` alias applied at `Modules/StudentProfile/routes/web.php:12` wrapping ALL routes. STD is the ONLY tenant module using route-file-level coverage instead of RSP-level. SEC-PLATFORM-003 does NOT apply to STD. This is correct architecture.
- **P0×1:** SEC-STD-01 — `is_super_admin` accepted in createStudentLogin() validation (`'is_super_admin'=>'nullable'` at line 610) and in User::create() (line 631) — toggle rendered as UI switch in `_student-login.blade.php:124`. Any school admin can escalate any user to platform super-admin. **Fix:** Remove from validation + User::create + view.
- **P1×6:** SEC-STD-02 — 4 Gate checks use wrong prefix `school-setup.student.*` (lines 1090, 1212, 1316, 1892) — permission does not exist → 403 for everyone; SEC-STD-03 — Aadhar ID plaintext, no `encrypted` cast (DPDPA 2023 violation); GAP-STD-06 — StdLeaveController Gate::authorize commented on index() (line 25) and review() (line 250) — any module:STUDENT user can view/approve ALL leave requests; AUD-STD-04 — activityLog commented on delete/restore/forceDelete (lines 3852, 3916, 3979); GAP-STD-08 — only 2 policies registered (StudentPolicy, AttendancePolicy) — 5 missing (Guardian, MedicalIncident, StudentDocument, LeaveApplication, LeaveType); GAP-STD-05 — zero FormRequests for student create/update routes.
- **P2×4:** BUG-STD-11 current_flag plain INT not GENERATED STORED (UNIQUE enforcement broken); DDL-STD-12 SoftDeletes missing from 4 tables (std_student_attendance, std_student_documents, std_health_profiles, std_vaccination_records); ARCH-STD-13 Student model imports 3 downstream module models (FeeStudentAssignment, StudentPayLog, ExamAttempt) — reversed coupling; PERF-STD-10 synchronous Excel export.
- **STALE CORRECTIONS from 2026-04-09 Phase 2:** "Gate facade not imported in AttendanceController — all Gate calls fatal" — CLEARED (Gate::authorize present on all 6 methods). "Leave subsystem DEAD CODE" — CLEARED (StdLeaveController exists). "module web.php registers only stub controller" — CLEARED.
- **ABOVE BASELINE:** Only module with confirmed EnsureTenantHasModule; AttendanceController and StudentLeaveTypeController fully authorized; MedicalIncidentController activityLog correct; Spatie MediaLibrary with image conversions.

### STD Systemic Pattern Summary
| Pattern | Verdict |
|---------|---------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ PRESENT (route-level via module:STUDENT — unique pattern) |
| API RSP no tenancy | ✅ Confirmed (dead scaffold) |
| D30 authorize()=true | ⚠️ PARTIAL (1 FormRequest returns true; most use inline validate) |
| D25 $request->all() | ✅ Confirmed (multiple student create/update methods) |
| is_super_admin privilege escalation | ✅ Confirmed (SEC-STD-01 P0) |

## Syllabus (SLB) — Mode X Complete Audit (2026-06-30, Technical Auditor)
Health **40/100 (P0-capped)**. Deploy: **NO-GO**. Report: `3-Audit_Reports/Syllabus_Complete_Audit_2026-06-30.md`.
- **Completion revised:** ~55% → **~78%** (2026-06-30 Mode X). June 27, 2026 commit (`adca1dfbb`) added full SyllabusController (~1776 lines) covering master/bloom/planning/report/saveSequencing/saveScheduling/autoSchedule/toggleLock/saveSetting. LMS resource release cron implemented.
- **P0×4:** SEC-SLB-01 — EnsureTenantHasModule absent from mapWebRoutes() AND from routes/web.php; GAP-SLB-001 — CompetencieController has ZERO Gate::authorize on ALL 9 methods — NEP competency framework completely ungated; GAP-SLB-003 — TopicController::destroy() calls `forceDelete()` not `delete()` — permanent data loss on every UI-triggered topic delete; GAP-SLB-004 — Competencie model lacks SoftDeletes + slb_competencies has no deleted_at column.
- **P1×4:** BUG-SLB-DUPOLICIES — Duplicate Gate::policy kills LessonPolicy (line 78 overwritten at line 93) AND CompetencyPolicy (line 81 overwritten at line 92) — both are unreachable dead policies. GAP-SLB-002 — CompetencieController uses `$request->all()` directly. GAP-SLB-008 — ReleaseLmsResources cron no date filter — re-processes all entries every run. API RSP missing tenancy stack.
- **P2×4:** VAL-SLB-001 — all 15 FormRequests return `true` in authorize() (D30); GAP-SLB-009/010 — no range overlap detection for performance categories / grade divisions; GAP-SLB-019 — slb_books vs bok_books FK ambiguity; DAT-SLB-001 — 2 ENUM columns (D29).
- **ABOVE BASELINE:** 156 Gate::authorize calls across 14 of 15 controllers; SyllabusController gate-guarded at all write paths; toggleLock() implemented; only 2 ENUMs (below platform average).

### SLB Systemic Pattern Summary
| Pattern | Verdict |
|---------|---------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ Confirmed |
| Duplicate Gate::policy() kill | ✅ Confirmed (LessonPolicy + CompetencyPolicy both dead) |
| D30 authorize()=true | ✅ Confirmed (all 15 FormRequests) |
| D29 ENUM columns | ✅ Confirmed (2 columns) |
| D25 $request->all() | ✅ Confirmed (CompetencieController) |
| API RSP no tenancy | ✅ Confirmed (dead scaffold) |

## SyllabusBooks (SLK) — Mode X Complete Audit (2026-06-30, Technical Auditor)
Health **40/100 (P0-capped)**. Deploy: **NO-GO**. Report: `3-Audit_Reports/SyllabusBooks_Complete_Audit_2026-06-30.md`.
- **Completion revised:** ~55% → **~72%** (2026-06-30 Mode X). 11 controllers, 13 models, 8 FormRequests with real validation rules, 10 policies (NO duplicates). June 2026 additions: NoteController, NoteFileController, BookChapterController, BookFileController, BookChapterService, BookFileService, download tracking models and policies.
- **P0×2:** SEC-SLK-01 — EnsureTenantHasModule absent from mapWebRoutes() AND routes/web.php; ARCH-SLK-01 — BookController.php line 18 imports `Modules\Prime\Models\AcademicSession` which uses `$connection = 'global_master_mysql'` and `$table = 'glb_academic_sessions'`. Tenant module querying global DB: returns sessions from global pool not school's own `sch_organization_academic_sessions`. 8 call sites (lines 51, 54, 97, 186, 369, 372, 397, 474). Correct model was commented out at line 74. **Fix:** `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` — replace all 8 call sites.
- **P1×1:** API RSP missing tenancy stack (dead scaffold).
- **P2×3:** VAL-SLK-001 — all 8 FormRequests return `true` in authorize() (D30 — note: validation rules ARE present, only authorize() is bare-true); DAT-SLK-001 — 2 ENUM columns shared with SLB (coordinate migration); GAP-SLK-001 — slb_books vs bok_books canonical table ambiguity.
- **ABOVE BASELINE:** 63 Gate::authorize calls; 10 policies registered with NO duplicates (unlike QNS/TTF/SLB); 8 FormRequests have real validation rules (only authorize() has D30 gap); BookChapterService + BookFileService proper abstractions.

### SLK Systemic Pattern Summary
| Pattern | Verdict |
|---------|---------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ Confirmed |
| Cross-layer AcademicSession import | ✅ Confirmed (ARCH-SLK-01 — BookController, 8 call sites) |
| D30 authorize()=true | ✅ Confirmed (all 8 FormRequests — rules present, only authorize() bare-true) |
| D29 ENUM columns | ✅ Confirmed (2 columns, shared with SLB) |
| Duplicate Gate::policy() kill | ❌ NOT present (10 policies, no duplicates) |
| D25 $request->all() | ❌ NOT present (FormRequests used consistently) |
| API RSP no tenancy | ✅ Confirmed (dead scaffold) |

## SystemConfig (SYS) — Mode X Complete Audit (2026-06-30, Technical Auditor)
Health **40/100 (P0-capped)**. Deploy: **NO-GO**. Report: `3-Audit_Reports/SYS_SystemConfig_Complete_Audit_2026-06-30.md`.
- **Module type:** Central-only (prime domain / Super Admin only). EnsureTenantHasModule: N/A. No tenant scoping needed.
- **Completion revised:** ~40% (V2 estimate) → **~65-70%** (2026-06-30 Mode X). 11 controllers, 8 models, 4 FormRequests, 2 policies, 2 services, 1 job, 2 notifications.
- **P0×5:**
  - **SEC-SYS-02 [CONFIRMED]** — MenuSyncController::sync() auth check is COMMENTED OUT (lines 74-79). Any auth+verified user can truncate `glb_menu_module_jnt`, forceDelete ALL tenant menus, and rebuild — platform-wide menu wipe.
  - **SEC-SYS-28 [NEW]** — BackupController has ZERO Gate::authorize on all 6 methods incl. `download()`. Any auth+verified user can download complete DB backup ZIP files from local storage. Active data breach vector.
  - **SEC-SYS-29 [NEW]** — BackupScheduleController has ZERO Gate::authorize on all 6 methods. Any auth+verified user can create/modify/delete backup schedules (resource abuse + backup sabotage).
  - **SEC-SYS-30 [NEW]** — TenantDropdownController::getColumns() has NO Gate::authorize AND SQL injection: `DB::connection('tenant')->select("SHOW COLUMNS FROM {$request->table_name}")` — user-controlled table name in raw SQL string.
  - **ARCH-SYS-05 [CONFIRMED]** — Duplicate `Setting` model: `Modules\Prime\Models\Setting` + `Modules\SystemConfig\Models\Setting` both map to `sys_settings`.
- **SEC-SYS-01 DOWNGRADED to P2:** SystemConfigController 7 stubs, zero Gate — but ONLY `dashboard` (index) is routed; returns stub view. Other 6 CRUD methods are unrouted dead scaffold. Low exploitability.
- **P1×8:**
  - SEC-SYS-03: MenuController::create() and destroy() empty stubs, no Gate
  - BUG-SYS-04: MenuController::update() line 127 uses `$request->all()` — immutable `code` field can be overwritten
  - BUG-SYS-08: MenuPolicy all 7 methods use `prime.menu.*`; controller uses `system-config.menu.*` — policy is dead code
  - BUG-SYS-16: MenuController::forceDelete() no Gate::authorize — any auth+verified user can permanently delete menu items
  - SEC-SYS-22: SettingController uses `tenant.setting.*` prefix (wrong for central module)
  - PERM-SYS-01: 5 controllers use `tenant.*` prefix — correct prefix is `system-config.*`
  - ARCH-SYS-06: TenantDropdownController::create() calls `DB::connection('tenant')` in central context (no tenant initialized) → SHOW TABLES throws, caught silently, form shows empty table list
  - AUD-SYS-01: SettingController line 67 `activityLog('updated', $setting, ...)` — wrong arg order; should be `activityLog($setting, 'updated', ...)`
- **STALE CLEARED (BA P1s):**
  - BUG-SYS-06 (SettingController wrong table in validation): CLEARED — update() correctly validates only `value` field
  - BUG-SYS-07 (store() returns raw $request): CLEARED — no store() method exists; only index/edit/update implemented
- **ABOVE BASELINE:** RunBackupJob correctly implements ShouldQueue, active-backup guard, 500MB disk check, failed() handler. MenuController CRUD (index/store/edit/update/updateMenu) all have correct `system-config.menu.*` Gate calls. TenantLocationController fully gated (20+ CRUD methods). TenantDropdownController CRUD methods (except getColumns) have Gate.

### SYS Systemic Pattern Summary
| Pattern | Verdict |
|---------|---------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | N/A — central module |
| D30 authorize()=true | ✅ Confirmed (3/4 FormRequests) |
| D29 ENUM columns | ❌ Not present (sys_settings uses key-value, 0 ENUMs) |
| PERM-SYS-01 Permission prefix chaos | ✅ Confirmed (5 controllers using `tenant.*` instead of `system-config.*`) |
| ARCH-SLK-01 Cross-layer model import | N/A |
| Duplicate Gate::policy() kill | ❌ Not applicable (MenuPolicy dead for different reason — prefix mismatch, not duplicate registration) |
| activityLog wrong arg order | ✅ Confirmed (SettingController line 67) |

## Template (TMP) — Mode X Complete Audit (2026-06-30, Technical Auditor)
Health **40/100 (P0-capped)**. Deploy: **NO-GO**. Report: `3-Audit_Reports/TMP_Template_Complete_Audit_2026-06-30.md`.

Cross-cutting platform rendering engine: consumed by MarksheetGeneration (MSH), StudentProfile (STD), StudentFee (FIN), LmsExam (EXM), Certificate (CRT). Stateless singleton via `TemplateEngine::render()`. Renders HTML using `@{{varName}}` placeholders, loop blocks, and legacy marker translation.

### P0 Findings
- **SEC-PLATFORM-003 [CONFIRMED]** — EnsureTenantHasModule absent from mapWebRoutes() middleware stack. Any active tenant can access Template routes regardless of module subscription.
- **GAP-TMP-02 [CONFIRMED P0]** — `TemplateEngine::resolveTemplate()` 6-step fallback queries `ta.class_id` and `ta.academic_session_id` only. **No `ta.class_group_id` at any of the 6 fallback steps.** Assignments scoped to class groups are silently skipped → `TemplateNotFoundException` for all group-level assignments. Schools using group-level template assignments get silent failures.
- **BUG-TMP-03 [CONFIRMED P0]** — `tmp_template_variables` migration (2026_06_16_082736) has **NO `value_type` column**. Engine `resolveVariables()` line 237 casts `$var->value_type ?? 'text'` — always 'text'. `formatVariableValue()` branch for `image` (→ `<img>` tag) and `html` (→ trusted pass-through) are **unreachable**. All variables silently render as text. Confirmed by exhaustive grep across all tenant migrations — no subsequent migration adds this column.

### P1 Findings (7)
- **SEC-TMP-01** — `getTables()` line 227 and `getColumns()` line 247: raw user input in backtick-quoted SQL (`"SHOW TABLES FROM \`{$dbName}\`"`, `"SHOW COLUMNS FROM \`{$dbName}\`.\`{$tableName}\`"`). SQL injection via backtick escape.
- **SEC-TMP-02** — `getDatabases()` line 209: `DB::select('SHOW DATABASES')` returns ALL databases visible to the MySQL user (prime_db, global_db, all tenant_* DBs). Cross-tenant schema enumeration for any School Admin. Also called unconditionally on every `create()` / `edit()` load.
- **SEC-TMP-03 [NEW]** — `TemplateController::uploadImage()` (line 408): validates file type/size but has **no Gate::authorize** call. Any authenticated user can upload image files.
- **BUG-TMP-04 [NEW]** — `UpdateTemplateRequest` includes `code` field with `unique:tmp_templates,code,{id}` — update() passes `$validated['code']` to the update array. Template code is documented as immutable after creation (BR-TMP-003) but is updatable via API.
- **GAP-TMP-05 [CONFIRMED]** — `TemplatePurposeController::update()` (lines 91–99): no `is_system` guard. A system purpose can have its name/description/is_active overwritten. `destroy()` and `forceDelete()` do check `is_system` correctly.
- **BUG-TMP-05 [CONFIRMED]** — `TemplateController::forceDelete()` (line 463): calls `$template->forceDelete()` with no check for active `TemplateAssignment` records. BR-017 (cannot delete assigned template) not enforced.
- **API-TMP-01** — API RSP `mapApiRoutes()`: `Route::middleware(['auth:sanctum'])->prefix('v1')` only — no tenancy middleware (InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive). Cross-tenant API access possible.

### Cleared (BA Findings)
- **GAP-TMP-07 CLEARED** — `config/template.php` EXISTS in `config/` with 3 DataProvider registrations: `MARKSHEET_PRINT`, `STUDENT_ID_CARD`, `TRANSPORT_STAFF_ID_CARD`. Facade + provider system is fully wired.
- **GAP-TMP-10 CLEARED** — `StoreTemplateVariableRequest` uses `Rule::unique('tmp_template_variables')->where('template_type_id', $this->input('template_type_id'))` — compound unique constraint correctly enforced in validation.

### Above Baseline
- 5 policies registered in TemplateServiceProvider — **NO duplicate Gate::policy() kills** (unlike EXM, TTF, SLB, QUZ)
- All 5 controllers use **consistent `tenant.template.*` prefix** (no split like SYS, STT, TTF)
- `TemplateAssignmentController::store()/update()` uses `DB::beginTransaction` with try/catch/rollback and user-friendly duplicate detection
- `TemplateTypeController::destroy()` checks `$templateType->templates()->exists()` and `forceDelete()` checks `->withTrashed()->exists()` before proceeding
- TemplateEngine correctly uses `e()` (HTML escape) for text variables and trusted pass-through only for 'html' type

### Systemic Pattern Scorecard
| Pattern | TMP Verdict |
|---------|------------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ CONFIRMED — absent from mapWebRoutes() |
| D30 (authorize()=true FormRequests) | ✅ CONFIRMED — 10/10 (100%) |
| D29 (ENUM columns) | ❌ NOT PRESENT — 0 ENUM columns |
| API RSP no tenancy | ✅ CONFIRMED — api.php routes no tenancy stack |
| Cross-layer model import | ❌ NOT PRESENT — TemplateAssignmentController imports MarksheetGeneration\Models\ClassGroup but this is a same-DB tenant-layer import, not cross-layer |
| Duplicate Gate::policy() kill | ❌ NOT PRESENT — 5 policies, no duplicates |
| activityLog wrong arg order | Not checked (no activityLog calls found) |

---

## VND (Vendor) — Mode X Complete Audit 2026-06-30
**Health: 35/100 (P0-capped) — NO-GO**
**Report:** `3-Audit_Reports/Vendor_Complete_Audit_2026-06-30.md`

### P0 Findings (4)
- **SEC-PLATFORM-003** — EnsureTenantHasModule absent from RSP mapWebRoutes(). Module accessible regardless of tenant subscription. (Platform-wide P0)
- **SEC-VND-010 [CONFIRMED]** — `pan_number`, `bank_account_no`, `gst_number`, `upi_id` in plain VARCHAR columns in `vnd_vendors` migration; no `encrypted` cast on Vendor model. DPDPA 2023 regulatory violation.
- **MIG-VND-002 [NEW]** — `vnd_invoices.balance_due` is `$table->decimal('balance_due', 12, 2)` (plain) in `2026_06_15_151252_create_vnd_invoices_table.php:36`. DDL spec (Vendor_DDL_v2.1.sql:193) says `GENERATED ALWAYS AS (net_payable - amount_paid) STORED`. Not in `$fillable` → controller writes silently dropped. DB column always stale/0. Same D36 pattern as BUG-FIN-05.
- **DAT-VND-001 [NEW]** — Concurrent payment race condition: `VendorInvoiceController::store()`, `VendorPaymentController::update()`, and `destroy()` all read `invoice->amount_paid`, compute new total, write back — with NO `lockForUpdate()`. Concurrent writes overwrite each other; payment silently lost from ledger.

### P1 Findings (8)
- **JOB-VND-001 [NEW]** — `SendVendorInvoiceEmailJob`: (a) no `$tries`/`$timeout`/`$backoff`; (b) no `tenancy()->initialize()` → queries return null in central context; (c) sends to `Auth::user()->email` (admin), not vendor email; (d) temp PDFs leak on `Mail::send()` exception.
- **BUG-VND-003 [NEW]** — `generateMultiple()` failure masking: `generateInvoice()` catches ALL exceptions internally (never rethrows). Outer try/catch in `generateMultiple()` never fires → all failed invoices appear in `$success` array.
- **BUG-VND-004 [NEW]** — `VendorPaymentController::destroy()` calls `DB::beginTransaction()` with NO try/catch. Exception leaves transaction open.
- **BUG-VND-005 [NEW]** — `routes/web.php:36` registers `vendor-usage-log.toggleStatus` → `VndUsageLogController::toggleStatus()` — method does not exist → 500.
- **SEC-VND-011 [NEW]** — `VndUsageLogController::store()/update()` no FormRequest; `qty_used` accepts negative values (corrupts invoice billing sum); no existence check on `vendor_id`/`agreement_item_id` → IDOR.
- **ORM-VND-001 [NEW]** — `VndAgreement` model lines 11–12 directly imports `Modules\Transport\Models\Vehicle` and `Modules\Transport\Models\DriverHelper`. Vendor crashes class-not-found if Transport module is disabled.
- **BUG-VND-008 [CONFIRMED]** — `generateInvoice()` line 381: `'INV-' . now()->format('YmdHis') . rand(100,999)` — 1-in-900 collision in batch loop (same vendor, same second).
- **PERF-VND-001 [NEW]** — `VendorDashboardController` lines 166–189: N+1 — one `VndPayment::whereHas()` per vendor in `$vendors->map(...)` loop.

### P2 Findings (key)
- **BUG-VND-016 [CONFIRMED]** — `pdfMultiple()` temp PDFs at `storage/app/{random}.pdf` never unlinked after ZIP close.
- **D29 [CONFIRMED]** — 4 ENUM columns: `vnd_agreements.status`, `vnd_agreements.billing_cycle`, `vnd_agreement_items_jnt.billing_model`, `vnd_payments.status`.
- **D30 [CONFIRMED]** — 3/3 FormRequests return `authorize(){return true;}`.
- **Layer 2.5 [CONFIRMED]** — 4 cross-DB FKs → `sys_dropdowns`: `vnd_vendors.vendor_type_id`, `vnd_invoices.status`, `vnd_payments.payment_mode`, `vnd_agreement_items_jnt.related_entity_type`.

### Stale BA Findings — CLEARED
- SEC-VND-001/005 — Gate commented — **CLEARED**: `Gate::any([7 permissions]) || abort(403)` in VendorController::index()
- SEC-VND-002 — zero auth on VendorInvoiceController — **CLEARED**: all 14+ methods gated
- SEC-VND-006 — prefix mismatch — **CLEARED**: consistent `tenant.vendor-payment.*`
- GAP-VND-05 — VendorDashboardController unregistered — **CLEARED**: `web.php:66`
- GAP-VND-24 — VendorReportController dead — **CLEARED**: `web.php:73`

### Above Baseline
- 7 policies registered, **zero duplicate Gate::policy() kills** (unlike EXM 13×, TTF 19×)
- All 8 controllers have Gate coverage (100%) — best authorization posture of any audited module

### Systemic Pattern Scorecard
| Pattern | VND Verdict |
|---------|------------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ CONFIRMED — absent |
| D30 (authorize()=true FormRequests) | ✅ CONFIRMED — 3/3 |
| D29 (ENUM columns) | ✅ CONFIRMED — 4 columns |
| D25 ($request->all() into models) | ❌ NOT PRESENT |
| D36 (GENERATED columns as plain in migration) | ✅ CONFIRMED — balance_due |
| Layer 2.5 (cross-DB FKs → sys_dropdowns) | ✅ CONFIRMED — 4 FKs |
| Layer 10.1 (Job missing tenancy/retry) | ✅ CONFIRMED — SendVendorInvoiceEmailJob |
| PII plaintext | ✅ CONFIRMED — 4 fields (pan_number, bank_account_no, gst_number, upi_id) |
| Duplicate Gate::policy() kill | ❌ NOT PRESENT — 7 policies, all unique |
