# MarksheetGeneration (MSH) — Feature Inventory

**Generated:** 2026-Jul-10 · **Mode:** module → report · **Run folder:** `TestCases/MarksheetGeneration/`
**Convention:** ONE comprehensive Dusk file per screen (`{prefix}_{Feature}_TestCas.php`) — no V1/V2 split.

## Registry (module_list.md — Step 0, verified)

| Field | Value |
|-------|-------|
| MODULE_NAME | MarksheetGeneration |
| CODE | MSH |
| PREFIX | `msh_` |
| FOLDER_NAME | MarksheetGeneration |
| DDL_FILE_NAME | `MarksheetGeneration_DDL_` → resolved `MarksheetGeneration_DDL_v1.sql` |
| Requirement folder | `MarksheetGeneration_V2/` (capital V2 — glob-resolved) |

**Prefix verified against DDL `CREATE TABLE`:** `msh_config_templates`, `msh_template_scholastic_components`, `msh_marksheet_schedules`, `msh_student_results` — all `msh_*`. Confirmed `msh_`.

## Environment / style facts (detected from real source)

- **DB scope:** tenant-side. DDL header `Database: tenant_db`; all 23 tables `msh_*` (no `tenant_id`). Tenancy scaffolding (`initializeTenantContext()` + guarded `tearDown`) emitted in every suite.
- **Test style:** browser Dusk (`namespace Tests\Browser; extends DuskTestCase`). No committed `prime_testing/tests/Browser/Modules/` MSH sibling → mirror golden `Class` reference. (A prior `tests/Created_by_Brijesh/MarksheetGeneration/` run existed under the OLD V1/V2 convention; used only as a content precedent and merged into single files.)
- **Activity-log events (verbatim from real controllers):** `Stored`, `Updated`, `Deleted`, `Toggled`, `Restored`; lifecycle `Reviewed`, `Published`, `Locked`, `Unlocked`; compute uses `ComputeDispatched`; StudentResult uses `Withheld`, `Declared`. (NOT the Class sample `Update`/`ToggelStatus`.)
- **Permissions:** `tenant.msh-{entity}.{ability}` (viewAny|view|create|update|delete|restore|forceDelete + lifecycle review|publish|lock|unlock|export + result print|export|withhold|declare). **D39-MSH:** never seeded → super-admin-only (environment prerequisite, not a code fix).
- **CRUD idiom:** modal + AJAX (SweetAlert toasts) on the 4 combined tabbed pages (`configuration`/`components`/`scheduling`/`results` combined routes); `$modalEntities` loop supplies toggleStatus/trashed/restore/forceDelete; `store/update` return JSON on `expectsJson()`; modal-entity `edit()` redirects to the combined page.
- **Module-enabled prerequisite:** `prime_testing/modules_statuses.json` must set `MarksheetGeneration: true` (most modules false → 404) and `APP_ENV=testing`. Documented in every Validation Report.

## Feature list (5 screens = 5 features)

**Generation order:** masters → children → transactional → composite (Dashboard) last.

| # | Screen file | Feature (PascalCase) | Primary table | Controller(s) / route | Type | Test methods | Output folder |
|---|-------------|----------------------|---------------|-----------------------|------|-------------:|---------------|
| 1 | 02-Configuration-Templates.md | ConfigurationTemplates | `msh_config_templates` | ConfigTemplate + MarksheetType + ClassGroup + ExamGroup + IaComponentType Controllers; `configuration.combined` | Composite CRUD (masters + template) | 52 | `ConfigurationTemplates/` |
| 2 | 03-Components-and-Weightages.md | ComponentsAndWeightages | `msh_template_scholastic_components` | TemplateScholastic/Exam-Weightage/Ia/Coscholastic Component Controllers; `components.combined` | Composite CRUD (template children) | 51 | `ComponentsAndWeightages/` |
| 3 | 04-Scheduling-and-Lifecycle.md | SchedulingAndLifecycle | `msh_marksheet_schedules` | MarksheetSchedule + ScheduleClass + SubjectPracticalConfig + ComputationLog Controllers; `scheduling.combined` + lifecycle routes | Transactional + state machine | 57 | `SchedulingAndLifecycle/` |
| 4 | 05-Student-Results-and-Print.md | StudentResultsAndPrint | `msh_student_results` | StudentResult + StudentSubjectResult + StudentIaMark + StudentCoscholasticResult + StudentAttendance + StudentSubjectExamMark Controllers; `results.combined` + print/pdf/export/withhold/declare | Transactional / results + print | 57 | `StudentResultsAndPrint/` |
| 5 | 01-Dashboard-and-Navigation.md | Dashboard | (aggregates `msh_*`; no own table) | MarksheetGenerationController dashboard/configuration/components/scheduling/results; `dashboard` + `*.combined` | Composite / read-focused | 44 | `Dashboard/` |
| | | | | | **Total** | **261** | |

**Non-screen docs skipped:** none — all 5 requirement files are screens.

## Artifact completeness

Each feature folder contains exactly the 7-artifact set (TcList, MANUALTESTING, GAPANALYSIS, ONE `_TestCas.php`, Validation_Report, `.ps1`, `.sh`). All 5 PHP suites pass `php -l`. Exactly ONE `.php` per feature (no V1/V2 pair) — verified.

## Audit defects mapped (MSH prefixes ONLY — from MarksheetGeneration_Complete_Audit_2026-06-29.md)

| Code | Sev | Owning feature | Proving test(s) |
|------|-----|----------------|-----------------|
| BUG-MSH-001 | P0 | Dashboard | `test_dashboard_58/59/72` (dead API — Route::has false, method_exists false, getJson ∈ {401,403,404,405,500}) |
| SEC-MSH-001 | P1 | StudentResultsAndPrint | `test_51` (create() uses `.view` not `.create`, source-asserted L32) |
| SEC-MSH-002 | P1 | StudentResultsAndPrint | `test_52` (store() uses `.update` not `.create`, L43) |
| SEC-MSH-003 | P1 | ALL (D30 systemic, 19 FormRequests) | per-feature `authorize()==true` proofs |
| PERF-MSH-001 | P1 | SchedulingAndLifecycle | `test_74` (precheck N+1) |
| BR-MSH-026 | P1 | SchedulingAndLifecycle | `test_29` (compute guards is_locked only, not FSM) |
| BR-MSH-027 | P1 | SchedulingAndLifecycle | `test_71` (no concurrent-computation guard) |
| D39-MSH | P1 | ALL (env prereq) | documented in each Validation Report |
| BUG-MSH-003 | P2 | ConfigurationTemplates | ExamGroupController::edit() no model binding → redirect |
| PERF-MSH-002 | P2 | SchedulingAndLifecycle | `test_73` (Schema::hasTable 3× in compute loop) |
| PERF-MSH-003 | P2 | Dashboard / StudentResultsAndPrint | `test_dashboard_46` (unbounded Student/Subject get) |
| BR-MSH-050 | P2 | ComponentsAndWeightages / SchedulingAndLifecycle | `test_16/17/18` (config-side), `test_72` (compute-side) |
| DEP-MSH-001 | P2 | SchedulingAndLifecycle | `test_44` (StudentPortal pending import, guarded) |
| DOC-MSH-001 | P3 | (documentation) | DDL header says 22 tables; file has 23 |
| DOC-MSH-002 | P3 | (documentation) | **RE-CHARACTERIZED — see gaps below** |
| PERF-MSH-004 | P3 | StudentResultsAndPrint / SchedulingAndLifecycle | `test_45` (wipePreviousResults hard-deletes soft-deletable rows) |

## Discovered findings (verify-in-source, proven by tests)

| Code | Owning feature | Finding |
|------|----------------|---------|
| BUG-MSH-101 | SchedulingAndLifecycle | `ScheduleClass` model missing `SoftDeletes` though `msh_schedule_class_jnt` has `deleted_at` — `withTrashed()`/`forceDelete()` would throw. |
| DEV-MSH-C03 | ComponentsAndWeightages | Sum-breaking scholastic update surfaces as HTTP 500, not 422. |
| DEV-MSH-C04 | ComponentsAndWeightages | `grading_scale` has no `in:` enum validation. |
| REVIEW-GATE-GAP | SchedulingAndLifecycle | `tenant.msh-marksheet-schedule.review` gate has no matching Policy ability. |
| DOC-MSH-003 | SchedulingAndLifecycle | BRD says unlock reverts to Draft/Reviewed; `unlock()` reverts to COMPUTED. Tests assert impl (COMPUTED). |

## DDL / documentation gaps flagged

- **DOC-MSH-001 (confirmed):** DDL header comment says "22 tables"; the file defines **23** `CREATE TABLE` statements (`msh_computation_logs` #23 is the extra). Header is stale.
- **DOC-MSH-002 (RE-CHARACTERIZED — audit was inaccurate):** the audit claimed migration `2026_06_15_145407_rename_sys_dropdown_table_to_sys_dropdowns.php` renamed the table to `sys_dropdowns`. **The migration is a filename-vs-body no-op:** its body is `Schema::rename('sys_dropdown_table', 'sys_dropdown_table')` under an always-false guard, and its own docblock states "Ensures the tenant table is named `sys_dropdown_table`". The **real runtime table is `sys_dropdown_table`** — confirmed by the msh FK (`->on('sys_dropdown_table')`), `MarksheetScheduleRequest` (`exists:sys_dropdown_table,id`), `Dropdown::$table = 'sys_dropdown_table'`, and `MarksheetComputationService`. **All suites assert `sys_dropdown_table`.** The prior Brijesh precedent (which asserted `sys_dropdowns`) would have false-failed on `test_01`.
- **`msh_computation_logs` has no `deleted_at`** (immutable audit) → its model must NOT use SoftDeletes; treated as read-only (index/show).
- **No per-module migrations:** `Modules/MarksheetGeneration/database/migrations/` holds only `.gitkeep`; the 23 real tenant migrations live in `prime_ai/database/migrations/tenant/`. `test_01` schema truth uses `Schema::hasTable/hasColumns` + the consolidated DDL + FormRequest files (not a module-local `MIGRATION_FILE`). Captured as a new general constraint in `05_`.
- **API layer dead (BUG-MSH-001):** `routes/api.php` `apiResource` targets `MarksheetGenerationController`, which lacks index/store/show/update/destroy → tests assert the dead-API behaviour, never a live contract.
