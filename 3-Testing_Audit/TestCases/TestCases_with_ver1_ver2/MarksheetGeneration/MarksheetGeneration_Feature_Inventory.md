# MarksheetGeneration (MSH) — Feature Inventory

**Generated:** 2026-Jul-09 · **Mode:** module · **Run folder:** `TestCases/MarksheetGeneration/`

## Registry (module_list.md — Step 0, verified)

| Field | Value |
|-------|-------|
| MODULE_NAME | MarksheetGeneration |
| CODE | MSH |
| PREFIX | `msh_` |
| FOLDER_NAME | MarksheetGeneration |
| DDL_FILE_NAME | `MarksheetGeneration_DDL_` → resolved to `MarksheetGeneration_DDL_v1.sql` |

**Prefix verified against DDL:** every primary table below is `msh_*` (`CREATE TABLE msh_config_templates`, `msh_template_scholastic_components`, `msh_marksheet_schedules`, `msh_student_results`). Confirmed `msh_`.

## Environment / style facts (detected from real source)

- **DB scope:** tenant-side. DDL header `Database: tenant_db`; all 23 tables `msh_*` (no `tenant_id`). Tenancy scaffolding (`initializeTenantContext()` / guarded `tearDown`) required.
- **Test style:** no committed MarksheetGeneration tests exist in `prime_testing/tests/Browser/Modules/` → **fall back to the golden `Class` browser-Dusk pattern** (`extends DuskTestCase`, `namespace Tests\Browser;`). (The module ships Pest Feature/Unit tests inside `prime_ai`, but those are app-repo tests, not the runner sibling.)
- **Activity log:** global helper `activityLog($model, $event, ['message' => ...])`. **Real event strings are `Stored`, `Updated`, `Deleted`, `Toggled`** (module-specific — NOT the Class sample's `Update`/`ToggelStatus`). Each feature must assert the verbatim string from its own controller.
- **Permissions:** `tenant.msh-{entity}.{ability}` with abilities `viewAny|view|create|update|delete|restore|forceDelete`. **D39-MSH:** these are NOT seeded (super-admin-only) — an environment prerequisite, not a test-code fix.
- **CRUD idiom:** modal + AJAX (`.ajax-form`, SweetAlert toasts) on combined tabbed pages; `edit()` redirects to the combined page; entities toggle/trash/restore/force-delete via the `$modalEntities` route loop. `store/update` return JSON when `expectsJson()`.
- **Module enabled prerequisite:** `prime_testing/modules_statuses.json` must have `MarksheetGeneration: true` (currently most modules false → 404). Document in each Validation Report.

## Feature list (5 screens = 5 features; generation order: masters → children → transactional → composite/Dashboard last)

| # | Screen file | Feature (PascalCase) | Primary table | Controller(s) / alias | Prefix | Type | Output folder |
|---|-------------|----------------------|---------------|-----------------------|--------|------|---------------|
| 1 | 02-Configuration-Templates.md | ConfigurationTemplates | `msh_config_templates` | ConfigTemplateController (+ MarksheetTypeController, ClassGroupController, ExamGroupController, IaComponentTypeController); route `configuration.combined` | `msh_` | Composite CRUD (masters + template) | `ConfigurationTemplates/` |
| 2 | 03-Components-and-Weightages.md | ComponentsAndWeightages | `msh_template_scholastic_components` | TemplateScholasticComponentController, TemplateExamWeightageController, TemplateIaComponentController, TemplateCoscholasticComponentController; route `components.combined` | `msh_` | Composite CRUD (template children, weightage=100 rules) | `ComponentsAndWeightages/` |
| 3 | 04-Scheduling-and-Lifecycle.md | SchedulingAndLifecycle | `msh_marksheet_schedules` | MarksheetScheduleController (+ ScheduleClassController, SubjectPracticalConfigController); route `scheduling.combined` + lifecycle routes (precheck/compute/review/publish/lock/unlock/export) | `msh_` | Transactional + state machine (DRAFT→COMPUTED→REVIEWED→PUBLISHED→LOCKED) | `SchedulingAndLifecycle/` |
| 4 | 05-Student-Results-and-Print.md | StudentResultsAndPrint | `msh_student_results` | StudentResultController (+ StudentSubjectResultController, StudentIaMarkController, StudentCoscholasticResultController, StudentAttendanceController, StudentSubjectExamMarkController, ComputationLogController); route `results.combined` + print/pdf/export/withhold/declare | `msh_` | Transactional/results + print/PDF | `StudentResultsAndPrint/` |
| 5 | 01-Dashboard-and-Navigation.md | Dashboard | (aggregates `msh_*`; no own primary table) | MarksheetGenerationController::dashboard/configuration/components/scheduling/results; route `dashboard` + `*.combined` | `msh_` | Report / composite (read-focused) | `Dashboard/` |

**Non-screen docs skipped:** none (all 5 requirement files are screens).

## Audit defects to map as proving tests (from MarksheetGeneration_Complete_Audit_2026-06-29.md — MSH prefixes ONLY)

| Code | Sev | Title | Owning feature |
|------|-----|-------|----------------|
| BUG-MSH-001 | P0 | API layer dead — 5 apiResource routes on controller with no API methods (`routes/api.php`) | Dashboard (MarksheetGenerationController) |
| SEC-MSH-001 | P1 | StudentResultController::create() uses `view` gate instead of `create` | StudentResultsAndPrint |
| SEC-MSH-002 | P1 | StudentResultController::store() uses `update` gate instead of `create` | StudentResultsAndPrint |
| SEC-MSH-003 | P1 | All 19 FormRequests `authorize()` return bare `true` (D30 systemic) | ALL features |
| PERF-MSH-001 | P1 | precheck() N+1 (6 queries/class-section) | SchedulingAndLifecycle |
| BR-MSH-026 | P1 | compute() checks only is_locked, not status FSM (DRAFT/COMPUTED) | SchedulingAndLifecycle |
| BR-MSH-027 | P1 | No concurrent-computation guard (RUNNING log unchecked) | SchedulingAndLifecycle |
| D39-MSH | P1 | MSH permissions never seeded — super-admin-only | ALL features (env prereq) |
| BUG-MSH-003 | P2 | ExamGroupController::edit() has no model binding — redirects instead of edit form | ConfigurationTemplates |
| PERF-MSH-002 | P2 | Schema::hasTable() 3× inside compute loop | SchedulingAndLifecycle |
| PERF-MSH-003 | P2 | Unbounded Student::get()/Subject::get() in results view | StudentResultsAndPrint / Dashboard |
| BR-MSH-050 | P2 | Weightage sum not validated at compute time (count only) | ComponentsAndWeightages / SchedulingAndLifecycle |
| DEP-MSH-001 | P2 | Cross-module import of pending StudentPortal models in precheck() | SchedulingAndLifecycle |
| DOC-MSH-001 | P3 | DDL header says 22 tables, file has 23 | (documentation) |
| DOC-MSH-002 | P3 | DDL uses `sys_dropdown_table`; migration uses `sys_dropdowns` | SchedulingAndLifecycle |
| PERF-MSH-004 | P3 | wipePreviousResults() hard-deletes soft-deletable rows on recompute | StudentResultsAndPrint / SchedulingAndLifecycle |

## DDL / feature gaps flagged during inventory

- **DOC-MSH-001**: DDL header comment says "22 tables" but the file defines **23** `CREATE TABLE` statements (tables 1–23). The `msh_computation_logs` audit table (#23) is the extra one.
- **DOC-MSH-002**: DDL FK comments reference `sys_dropdown_table`; the live migration/table is `sys_dropdowns`. Tests must target `sys_dropdowns`.
- `msh_computation_logs` has **no `deleted_at`** (immutable audit log) — its model must NOT use SoftDeletes; `withTrashed()`/`forceDelete()` will throw. Treat as read-only (index/show only).
- API layer (`routes/api.php`) is dead (BUG-MSH-001) — no API-contract positive tests possible against it; assert the 404/dead behaviour instead.
