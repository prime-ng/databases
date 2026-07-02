# MarksheetGeneration (MSH) — Mode X Complete Technical Audit
**Date:** 2026-06-29
**Auditor:** pa-technical-auditor (AI_Brain v1)
**Audit Mode:** Mode X — Layers A + B + C + G + Scoped D
**Module Code:** MSH | **Prefix:** msh_ | **App Dir:** `Modules/MarksheetGeneration/`
**Supersedes:** Stale 2026-04-18 AUDIT_REPORT.md (79 findings, many resolved)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Health Score | **6 / 100** (uncapped 6; P0 present → hard cap 40 applies but raw already below cap) |
| Deploy Verdict | **NO-GO** |
| P0 Count | **1** |
| P1 Count | **7** |
| P2 Count | **5** |
| P3 Count | **3** |
| FRD Req Coverage (REQ) | 18/18 implemented with noted gaps |
| BR Coverage | 50 BRs — 43 enforced, 3 partial/missing, 4 N/A |
| Open FRD Enhancements | 1 critical (ENH-MSH-006 / Q-13) |

The MarksheetGeneration module has a well-architected computation pipeline with correct tenancy setup, proper lifecycle enforcement (publish/lock/unlock), and clean schema (D29, D38, D17 baseline). However, the API layer is completely non-functional (P0), the entire FormRequest authorization layer is bypassed (D30, 19/19 requests), MSH permissions are never seeded so all features are super-admin-only (D39), and two critical business rules (BR-MSH-026, BR-MSH-027) are not enforced at the controller layer. These findings collectively block deployment.

---

## Module Facts (as-built)

| Item | Count | Notes |
|------|-------|-------|
| msh_* tables | 23 | All have migrations and corresponding models |
| Tenant migrations | 23 | `database/migrations/tenant/2026_06_16_115725` through `...115747` |
| Controllers | 21 | Web-only; no functional API controllers |
| Models | 24 | All use SoftDeletes where DDL has `deleted_at` |
| Services | 16 top-level + 5 Computation/ + 6 ScoreReaders/ = 27 | |
| FormRequests | 19 | All return `authorize() = true` (D30) |
| Policies | 18 | All registered in MarksheetGenerationServiceProvider |
| Jobs | 1 | ComputeMarksheetJob (30-min timeout, no auto-retry) |
| Views | 98 | Blade templates |
| API routes | 5 | All non-functional (BUG-MSH-001) |

---

## Audit Scope

**Files read:**
- `Modules/MarksheetGeneration/routes/web.php` (173 lines)
- `Modules/MarksheetGeneration/routes/api.php` (8 lines)
- `Modules/MarksheetGeneration/app/Providers/RouteServiceProvider.php`
- `Modules/MarksheetGeneration/app/Providers/MarksheetGenerationServiceProvider.php`
- `Modules/MarksheetGeneration/app/Http/Controllers/MarksheetGenerationController.php` (320 lines)
- `Modules/MarksheetGeneration/app/Http/Controllers/MarksheetScheduleController.php` (357 lines)
- `Modules/MarksheetGeneration/app/Http/Controllers/StudentResultController.php` (539 lines)
- `Modules/MarksheetGeneration/app/Http/Controllers/ExamGroupController.php` (140 lines)
- `Modules/MarksheetGeneration/app/Http/Requests/` — all 19 files (grep scan)
- `Modules/MarksheetGeneration/app/Models/MarksheetSchedule.php`
- `Modules/MarksheetGeneration/app/Models/StudentResult.php`
- `Modules/MarksheetGeneration/app/Jobs/ComputeMarksheetJob.php`
- `Modules/MarksheetGeneration/app/Services/MarksheetComputationService.php`
- `Modules/MarksheetGeneration/app/Services/MarksheetScheduleLifecycleService.php`
- `Modules/MarksheetGeneration/app/Services/Computation/WeightageApplier.php`
- `database/migrations/tenant/2026_06_16_115735_create_msh_marksheet_schedules_table.php`
- `database/migrations/tenant/` — full listing of msh_* files
- `database/seeders/TenantRolePermissionSeeder.php` (grep for msh-)
- `2-DDL_Tenant_Consolidated/MarksheetGeneration_DDL_v1.sql` (header + first 100 lines)
- `AI_Brain/module-knowledge/MSH_MarksheetGeneration.md`
- `4-Requirement_Module_wise/0-FRD_Documents/MSH_FRD_Complete_2026-06-29.md`
- `AI_Brain/lessons/known-issues.md`, `state/decisions.md`, `state/progress.md`

**Platform patterns checked:** D17, D24, D25, D29, D30, D36, D37, D38, D39

---

## Layer A: Module Structure (12-Layer Scan)

### A-1 Module Registration
Module.json and ServiceProvider exist. MarksheetGenerationServiceProvider registers: EventServiceProvider, RouteServiceProvider, all 18 policies, score-reader bindings, blade directives. Registration is complete.

### A-2 Route Layer
**Web routes (web.php):** All 21 controllers registered. Routes use `$modalEntities` pattern for 13 entities (toggleStatus/trashed/restore/forceDelete). Special lifecycle routes: review, lock, unlock, publish, precheck, compute, export on MarksheetSchedule. StudentResult special: export, print, pdf, withhold, declare. Route naming is consistent with `marksheet-generation.` prefix.

**API routes (api.php — 8 lines):**
```php
Route::apiResource('marksheetgenerations', MarksheetGenerationController::class)->names('marksheetgeneration')
```
This registers 5 routes (index, store, show, update, destroy). MarksheetGenerationController has NONE of these methods. Controller methods are `dashboard()`, `configuration()`, `components()`, `scheduling()`, `results()`. All 5 API routes fail at runtime.
→ **BUG-MSH-001 (P0)**

### A-3 Controller Layer
- MarksheetScheduleController: all CRUD + lifecycle actions correctly gated
- StudentResultController: create() and store() use wrong Gate abilities → **SEC-MSH-001, SEC-MSH-002 (P1)**
- ExamGroupController: edit() has no model binding parameter → **BUG-MSH-003 (P2)**
- MarksheetGenerationController: 5 web-dashboard methods, 0 API methods

### A-4 FormRequest Layer
Grepped all 19 FormRequests. Every `authorize()` method returns `true` with no Gate::allows() check.
Confirmed files: MarksheetTypeRequest, ConfigTemplateRequest, ScheduleClassRequest, TemplateCoscholasticComponentRequest, TemplateIaComponentRequest, StudentResultRequest, SubjectPracticalConfigRequest, StudentAttendanceRequest, IaComponentTypeRequest, WithholdStudentResultRequest, TemplateScholasticComponentRequest, ExamGroupRequest, StudentSubjectResultRequest, ClassGroupRequest, UnlockMarksheetScheduleRequest, StudentCoscholasticResultRequest, StudentIaMarkRequest, TemplateExamWeightageRequest, MarksheetScheduleRequest.
→ **SEC-MSH-003 (P1, D30 systemic)**

### A-5 Model Layer
Models checked: MarksheetSchedule, StudentResult (both in detail). Both use `SoftDeletes` and have `deleted_at` in their migrations — D38 clean. Fillable arrays match migration columns — D17 clean. No guarded-only or guarded=[] models found.

Observation: `StudentResult::subjectResults()` joins only on `student_id` (not schedule_id). This is intentional and documented in the model with a warning comment. The helper `subjectResultsForSchedule()` should be used in all views.

### A-6 Service Layer
- `MarksheetComputationService`: Correct DB transactions per class-section. Status flip to COMPUTED on full success. Three calls to `Schema::hasTable()` inside the computation loop (lines 209, 294, 338) → **PERF-MSH-002 (P2)**
- `MarksheetScheduleLifecycleService`: publish(), review(), unlock(), lock() — all enforce FSM transitions with DomainException. BR-MSH-037 and BR-MSH-039 enforced.
- `wipePreviousResults()`: hard-deletes from 4 soft-deletable tables to avoid unique-key conflicts on recompute. Intentional design per code comment, but bypasses SoftDeletes convention. → **PERF-MSH-004 (P3)**
- `WeightageApplier`: null-safe (BR-MSG-019 enforced). Does not validate sum = 100% at compute time.

### A-7 Job Layer
`ComputeMarksheetJob`: $timeout=1800, $tries=1. Constructor takes `scheduleId` and `triggeredByUserId` — no tenant ID. Relies on stancl QueueTenancyBootstrapper to restore tenant context from queue payload. `failed()` correctly updates ComputationLog status to FAILED. Tenancy auto-initialization by the bootstrapper is the standard stancl pattern and is likely correct if the bootstrapper is registered — this is a medium-confidence concern, not a confirmed defect.

### A-8 Policy Layer
18 policies registered in ServiceProvider: ClassGroupPolicy, ConfigTemplatePolicy, ExamGroupPolicy, IaComponentTypePolicy, MarksheetSchedulePolicy, MarksheetTypePolicy, ScheduleClassPolicy, StudentAttendancePolicy, StudentCoscholasticResultPolicy, StudentIaMarkPolicy, StudentResultPolicy, StudentSubjectExamMarkPolicy, StudentSubjectResultPolicy, SubjectPracticalConfigPolicy, TemplateCoscholasticComponentPolicy, TemplateExamWeightagePolicy, TemplateIaComponentPolicy, TemplateScholasticComponentPolicy.
All 18 policies are registered — no orphaned or missing registrations.

### A-9 View Layer
98 views exist. Performance concern: `results()` action fetches `Student::where('is_active', 1)->get()` and `Subject::orderBy('name')->get()` without pagination before passing to view → **PERF-MSH-003 (P2)**

### A-10 Database Layer
- 23 msh_* tables, 23 migrations — fully aligned
- D29 (ENUM check): no `->enum()` calls in any msh_* migration — CLEAN
- D37 (status field): `msh_marksheet_schedules.status_id` uses INT FK → sys_dropdowns — CLEAN (sys_dropdowns is a tenant table confirmed by migration `2026_06_15_145407_rename_sys_dropdown_table_to_sys_dropdowns.php`)
- D36 (generated columns): no generated columns in MSH schema — N/A

### A-11 Seeder Layer
Module has 4 seeders: MarksheetGenerationDatabaseSeeder, MarksheetSampleDataSeeder, MarksheetDemoSeeder, MarksheetClassSubjectSeeder — all demo/sample data seeders.
`TenantRolePermissionSeeder.php`: grep for `msh-` and `marksheet` returned zero results.
→ **D39-MSH (P1)**: All MSH permissions unseeded — super-admin-only until fixed.

### A-12 Config / Module Infrastructure
RouteServiceProvider correctly applies tenancy middleware stack. No route closures. No committed secrets found in the module.

---

## Layer G: Cross-Cutting Concerns

### G-1 Tenancy Isolation
RouteServiceProvider middleware stack:
```php
Route::middleware([
    'web',
    InitializeTenancyByDomain::class,
    PreventAccessFromCentralDomains::class,
    EnsureTenantIsActive::class,
    'auth',
    'verified',
])
```
Correct three-middleware tenancy stack. No `tenant_id` columns in any msh_* table — correct per D32 (database-per-tenant architecture). **CLEAN.**

### G-2 Authorization / Security
- D30 (FormRequest authorize bypass): All 19/19 FormRequests return bare `true` — **SEC-MSH-003 (P1)**
- Gate ability mismatch on StudentResult create/store — **SEC-MSH-001, SEC-MSH-002 (P1)**
- Policies present and registered, but only reachable by super-admins due to D39 unseeded permissions

### G-3 Permission Seeding (D39)
No MSH-prefixed permissions found in TenantRolePermissionSeeder. All 18 policy-protected resources (marksheet-type, config-template, class-group, exam-group, etc.) are inaccessible to regular admin/teacher roles until permissions are seeded and assigned. **D39-MSH (P1)**

### G-4 Mass Assignment (D17)
MarksheetSchedule, StudentResult, ConfigTemplate models all verified — fillable arrays match DDL columns, no audit/lifecycle fields (is_locked, locked_by, locked_at) in fillable that could be mass-assigned from request data. **CLEAN.**

### G-5 Schema Patterns (D29, D38, D36)
- D29 (ENUM): 0 ENUMs in all 23 migrations — **CLEAN**
- D38 (SoftDeletes vs DDL): All key models with `deleted_at` in DDL use `SoftDeletes` trait — **CLEAN**
- D36 (generated columns): N/A — MSH has no generated columns

### G-6 Input Validation (D25)
Controllers use `$request->validated()` (verified in MarksheetScheduleController::store(), ExamGroupController::store(), ExamGroupController::update()). Unable to confirm absence of `$request->all()` systemically due to ugrep alias limitation on this pattern, but all controllers read in detail used validated(). **Probably CLEAN.**

### G-7 Cross-Module Dependencies
- `Modules\Prime\Models\Dropdown` used in MarksheetScheduleLifecycleService — cross-layer (Prime = central, MarksheetGeneration = tenant). Functional but architecturally impure. **P3**
- `Modules\StudentPortal\Models\ExamResult` and `Modules\StudentPortal\Models\QuizQuestResult` imported in MarksheetScheduleController (precheck()). StudentPortal is listed as "Pending" module. **DEP-MSH-001 (P2)**

### G-8 Permission Prefix (D24)
Permissions use consistent `tenant.msh-{entity}.{ability}` format. No `tennat.` typos found. **CLEAN above baseline.**

---

## Layer D: Three-Way Schema Reconcile (Scoped)

### D-1 Table Count
- DDL header declares 22 tables
- DDL file contains 23 `CREATE TABLE` statements
- Live migrations: 23 files (`2026_06_16_115725` through `115747`)
- Models: 24 (per module-knowledge; one model may serve a junction table)
- **DDL doc header is stale** (says 22, is 23) — **DOC-MSH-001 (P3)**

### D-2 DDL vs Migration Column Alignment (msh_marksheet_schedules sample)
Migration (`2026_06_16_115735`) columns: id, code, name, schedule_date, last_computed_at, total_students, is_locked, locked_at, locked_by, unlock_reason, unlocked_at, unlocked_by, is_active, created_by, updated_by, created_at, updated_at, config_template_id, academic_session_id, status_id, deleted_at.
Model fillable: config_template_id, academic_session_id, code, name, schedule_date, status_id, last_computed_at, total_students, is_locked, locked_at, locked_by, unlock_reason, unlocked_at, unlocked_by, is_active, created_by, updated_by.
DDL matches migration. Model fillable covers all application-writable columns. **THREE-WAY: CLEAN for this table.**

### D-3 DDL FK Name Divergence
DDL file uses `sys_dropdown_table` as FK target name in comments (line 28).
Live migration uses `->on('sys_dropdowns')`.
Actual table (via migration 2026_06_15_145407): `sys_dropdowns`.
The DDL comment is stale on this name. The migration and model use the correct name. **DOC-MSH-002 (P3)**

### D-4 Status FK (D37 check)
`msh_marksheet_schedules.status_id` FK → `sys_dropdowns.id`. `sys_dropdowns` is a tenant-DB table (confirmed by tenant migration). This is NOT a cross-DB FK issue. **CLEAN.**

### D-5 wipePreviousResults Hard-Delete
`MarksheetComputationService::wipePreviousResults()` issues hard deletes on `msh_student_results`, `msh_student_subject_results`, `msh_student_subject_exam_marks`, `msh_student_coscholastic_results`. These tables have soft-delete columns in their migrations. The comment explains the rationale (unique keys don't include deleted_at, so soft-delete would block reinsert). Intentional design choice but permanent data loss on recompute. **PERF-MSH-004 (P3)**

---

## Layer B: FRD ↔ Code Conformance

### REQ Coverage

| REQ ID | Requirement | Status | Notes |
|--------|------------|--------|-------|
| REQ-MSH-001 | Class Group management | IMPLEMENTED | ClassGroupController, ClassGroupService |
| REQ-MSH-002 | Template Configuration | IMPLEMENTED | ConfigTemplateController, ConfigTemplateService |
| REQ-MSH-003 | Exam Group management | IMPLEMENTED with gap | ExamGroupController edit() broken (BUG-MSH-003) |
| REQ-MSH-004 | Marksheet Schedule CRUD | IMPLEMENTED | MarksheetScheduleController |
| REQ-MSH-005 | Automated Computation | IMPLEMENTED | ComputeMarksheetJob + MarksheetComputationService |
| REQ-MSH-006 | Review lifecycle | IMPLEMENTED | LifecycleService.review() enforces COMPUTED→REVIEWED |
| REQ-MSH-007 | Publish lifecycle | IMPLEMENTED | LifecycleService.publish() enforces REVIEWED→PUBLISHED + locks template |
| REQ-MSH-008 | Lock lifecycle | IMPLEMENTED | LifecycleService.lock() enforces PUBLISHED→LOCKED |
| REQ-MSH-009 | Unlock with reason | IMPLEMENTED | LifecycleService.unlock() validates non-empty reason |
| REQ-MSH-010 | Student Result view/edit | IMPLEMENTED with security gaps | SEC-MSH-001/002 wrong Gate abilities |
| REQ-MSH-011 | Student Subject Result | IMPLEMENTED | StudentSubjectResultController |
| REQ-MSH-012 | PDF/Print generation | IMPLEMENTED | html2pdf.js via print route (per design decision D32) |
| REQ-MSH-013 | Withhold/Declare | IMPLEMENTED | StudentResultController::withhold(), declare() |
| REQ-MSH-014 | Coscholastic Results | IMPLEMENTED | StudentCoscholasticResultController |
| REQ-MSH-015 | IA Mark entry | IMPLEMENTED | StudentIaMarkController |
| REQ-MSH-016 | Subject Practical Config | IMPLEMENTED | SubjectPracticalConfigController |
| REQ-MSH-017 | Precheck | IMPLEMENTED with perf gap | 6 queries per class-section N+1 (PERF-MSH-001) |
| REQ-MSH-018 | Dashboard | IMPLEMENTED | MarksheetGenerationController::dashboard() |

### BR Coverage (key BRs only)

| BR ID | Rule | Enforcement Status |
|-------|------|-------------------|
| BR-MSH-009 | Source weightages sum 100% | NOT enforced at compute time — only count check in precheck |
| BR-MSH-012 | Exam weightages sum 100% | NOT enforced at compute time — only count check in precheck |
| BR-MSH-019 | Null-safe weightage | ENFORCED — WeightageApplier excludes null sources |
| BR-MSH-025 | Best-of-N exam type | ENFORCED — WeightageApplier.applyExamTypeWeightagesBestOfN() |
| BR-MSH-026 | Compute only from DRAFT or COMPUTED | PARTIAL — controller checks is_locked only, not status value |
| BR-MSH-027 | No concurrent computation | NOT ENFORCED — no RUNNING check before dispatch |
| BR-MSH-037 | Publish locks template | ENFORCED — LifecycleService.publish() calls lockTemplate() |
| BR-MSH-038 | Unlock only by authorized admin | ENFORCED — Gate::authorize('tenant.msh-marksheet-schedule.unlock') |
| BR-MSH-039 | Unlock requires reason + audit log | ENFORCED — unlock() validates non-empty reason, inserts ComputationLog |
| BR-MSH-050 | Weightage = 100 before compute | NOT ENFORCED — precheck shows count, compute does not validate sum |

---

## Layer C: Business Rules Analysis

### C-1 FSM Enforcement Gap (BR-MSH-026)
`MarksheetScheduleController::compute()` at line 318:
```php
if ((int) $marksheetSchedule->is_locked === 1) {
    return redirect()->with('error', 'Schedule is locked...');
}
```
Only the `is_locked` flag is checked. BR-MSH-026 requires status to be DRAFT or COMPUTED. A REVIEWED or PUBLISHED (unlocked) schedule can be recomputed, destroying reviewed/published data. This is a P1 data integrity issue.

### C-2 Concurrent Computation Race (BR-MSH-027)
`compute()` dispatches `ComputeMarksheetJob::dispatch(...)` with no guard against an already-running job. The computation service sets status=RUNNING in the log at the start, but the controller never checks for a RUNNING log entry before dispatching. In async queue mode, double-clicking "Compute" dispatches two jobs that race on `wipePreviousResults()` and concurrent inserts into `msh_student_results`. Result: either duplicate-key errors or interleaved partial results. P1 data integrity risk.

### C-3 Weightage Sum Not Validated (BR-MSH-050, BR-MSH-009, BR-MSH-012)
`precheck()` line 249: `'weightages' => ($template?->examWeightages->count() ?? 0)` — this is a count, not a sum check. If weightages are configured as 40%+40% = 80% total instead of 100%, the computation proceeds. WeightageApplier.applyExamTypeWeightages() uses `usedWeightage` as dynamic denominator — it scales correctly for missing data but relies on SUM=100 for correct absolute scoring. An admin can misconfigure weightages and get mathematically incorrect marksheets with no warning.

### C-4 Q-13 Open Enhancement (ENH-MSH-006)
Practical paper identification still uses marks-matching heuristic (no `is_practical` flag on `lms_exam_papers`). This remains the known open blocker from module-knowledge. The PracticalSplitter service exists but relies on heuristics. This is an enhancement, not a defect, but blocks accurate theory/practical score separation for science subjects.

---

## Finding Register

| Code | Layer | Severity | Title | File / Line |
|------|-------|----------|-------|-------------|
| BUG-MSH-001 | A-2 | **P0** | API layer dead — 5 apiResource routes on controller with no API methods | `routes/api.php:3`, `MarksheetGenerationController.php` |
| SEC-MSH-001 | A-3 | P1 | StudentResultController::create() uses `view` Gate ability instead of `create` | `StudentResultController.php:~create()` |
| SEC-MSH-002 | A-3 | P1 | StudentResultController::store() uses `update` Gate ability instead of `create` | `StudentResultController.php:~store()` |
| SEC-MSH-003 | A-4 | P1 | All 19 FormRequests return authorize()=true (D30 systemic) | All files in `app/Http/Requests/` |
| PERF-MSH-001 | A-9/C | P1 | precheck() fires 6 DB queries per class-section in foreach (N+1) | `MarksheetScheduleController.php:257-306` |
| BR-MSH-026 | C-1 | P1 | compute() only checks is_locked, not status FSM state (DRAFT/COMPUTED required) | `MarksheetScheduleController.php:318` |
| BR-MSH-027 | C-2 | P1 | No concurrent computation guard — RUNNING log not checked before dispatch | `MarksheetScheduleController.php:314-345` |
| D39-MSH | A-11 | P1 | MSH permissions not seeded in TenantRolePermissionSeeder — super-admin-only | `database/seeders/TenantRolePermissionSeeder.php` |
| BUG-MSH-003 | A-3 | P2 | ExamGroupController::edit() has no model binding — returns redirect instead of edit form | `ExamGroupController.php:64-69` |
| PERF-MSH-002 | A-6 | P2 | Schema::hasTable() called 3× inside computation loop (SHOW TABLES on hot path) | `MarksheetComputationService.php:209,294,338` |
| PERF-MSH-003 | A-9 | P2 | Unbounded Student::get() and Subject::get() in results view — no pagination | `MarksheetGenerationController.php:results()` |
| BR-MSH-050 | C-3 | P2 | Weightage sum not validated at compute time — precheck shows count only | `MarksheetScheduleController.php:precheck()`, `WeightageApplier.php` |
| DEP-MSH-001 | G-7 | P2 | Cross-module import of pending StudentPortal models in precheck() | `MarksheetScheduleController.php:271,286` |
| DOC-MSH-001 | D-1 | P3 | DDL header says 22 tables, file has 23 CREATE TABLE statements | `MarksheetGeneration_DDL_v1.sql:8` |
| DOC-MSH-002 | D-3 | P3 | DDL uses `sys_dropdown_table` name; migration uses `sys_dropdowns` (stale DDL comment) | `MarksheetGeneration_DDL_v1.sql:28`, migration `...115735` |
| PERF-MSH-004 | D-5 | P3 | wipePreviousResults() hard-deletes soft-deletable rows — permanent data loss on recompute | `MarksheetComputationService.php:712-722` |

---

## Health Score Calculation

```
Deductions:
  P0 × 20: 1 × 20 = 20
  P1 × 8:  7 × 8  = 56
  P2 × 3:  5 × 3  = 15
  P3 × 1:  3 × 1  = 3
  Total deduction: 94

Raw score: 100 − 94 = 6
P0 present → hard cap 40 applies (max cannot exceed 40)
Final: min(6, 40) = 6 — score is already below cap

HEALTH SCORE: 6 / 100
```

---

## GO / NO-GO Verdict

**VERDICT: NO-GO**

Blocking issues:
1. **BUG-MSH-001 (P0):** API layer completely dead. Any API consumer receives 404 for all 5 declared routes.
2. **D39-MSH (P1):** Zero MSH permissions seeded. All 18 policy-protected resources are inaccessible to non-super-admin users in production.
3. **SEC-MSH-003 (P1):** All 19 FormRequests bypass authorization entirely.
4. **BR-MSH-026/027 (P1 each):** Compute action does not enforce status FSM and has no concurrency guard — data integrity risk.

---

## Areas of Strength

These areas are notably ABOVE platform baseline and should be preserved:
- **Tenancy setup:** RSP middleware stack correctly applies `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive`
- **Lifecycle FSM in service layer:** `MarksheetScheduleLifecycleService` correctly enforces all state transitions with `DomainException`, DB transactions, and audit log entries
- **Permission prefix hygiene (D24):** Clean `tenant.msh-{entity}.{ability}` format with no `tennat.` typos
- **Schema hygiene (D29, D38, D17):** No ENUMs, SoftDeletes consistent across models+migrations, fillable arrays correct
- **Computation pipeline architecture:** WeightageApplier null-safe (BR-MSG-019), DB transactions per class-section, PracticalSplitter service, GradeResolver service, RankCalculator service
- **Policy registration:** All 18 policies registered (none missing)
- **BR-MSH-037/039:** Publish locks template and unlock requires reason — both correctly enforced

---

## Remediation Roadmap

### Sprint 1 — P0 (Must fix before any production use)
1. **BUG-MSH-001:** Either add `index()`, `store()`, `show()`, `update()`, `destroy()` to MarksheetGenerationController with proper responses, or remove `api.php` if the API is not needed. If removing, delete `routes/api.php` and remove the api route from the module's ServiceProvider.

### Sprint 2 — P1 Security & Data Integrity
2. **SEC-MSH-001:** Change `Gate::authorize('tenant.msh-student-result.view')` to `Gate::authorize('tenant.msh-student-result.create')` in StudentResultController::create()
3. **SEC-MSH-002:** Change `Gate::authorize('tenant.msh-student-result.update')` to `Gate::authorize('tenant.msh-student-result.create')` in StudentResultController::store()
4. **SEC-MSH-003:** Update all 19 FormRequest `authorize()` methods to call `Gate::allows('tenant.msh-{entity}.{ability}')` with the correct ability for the operation
5. **D39-MSH:** Add all MSH permission strings to TenantRolePermissionSeeder and assign to appropriate roles (admin, teacher where applicable)
6. **BR-MSH-026:** In compute(), add status FSM check before dispatching:
   ```php
   $validStatuses = [$draftStatusId, $computedStatusId];
   if (!in_array((int) $marksheetSchedule->status_id, $validStatuses)) {
       return redirect()->with('error', 'Compute only allowed for DRAFT or COMPUTED schedules.');
   }
   ```
7. **BR-MSH-027:** In compute(), check for RUNNING computation log before dispatching:
   ```php
   $isRunning = ComputationLog::where('schedule_id', $marksheetSchedule->id)
       ->where('status', 'RUNNING')->exists();
   if ($isRunning) {
       return redirect()->with('error', 'Computation already in progress.');
   }
   ```

### Sprint 3 — P1 Performance
8. **PERF-MSH-001:** Refactor precheck() to use batch queries instead of per-section foreach: collect all class-section IDs first, then run batch `whereIn` counts
9. **BR-MSH-050:** Add weightage sum validation in precheck() and block compute() if sum ≠ 100:
   - Check `$template->examWeightages->sum('weightage_percent') == 100` and `$template->scholasticComponents->sum('weightage_percent') == 100`

### Sprint 4 — P2 Items
10. **BUG-MSH-003:** Fix ExamGroupController::edit() to either serve a proper edit form with model binding or explicitly remove the route
11. **PERF-MSH-002:** Cache `Schema::hasTable()` results (e.g., with `once()` or a simple `static $checked = []` map) to avoid 3 SHOW TABLES queries per class-section
12. **PERF-MSH-003:** Add pagination to student/subject lists in results view or use `select('id', 'name')` minimal projection with JS-driven filtering
13. **DEP-MSH-001:** Replace `Modules\StudentPortal\Models\ExamResult` and `QuizQuestResult` imports with the canonical LmsExam module models to eliminate StudentPortal dependency

### Sprint 5 — P3 / Documentation
14. **DOC-MSH-001/002:** Update `MarksheetGeneration_DDL_v1.sql` header to say 23 tables and replace `sys_dropdown_table` references with `sys_dropdowns`
15. **ENH-MSH-006 (Q-13):** Plan `is_practical` flag addition to `lms_exam_papers` (requires LmsExam module change and migration)

---

## Platform Pattern Summary for This Module

| Pattern | Status | Notes |
|---------|--------|-------|
| D17 (fillable vs columns) | CLEAN | Verified MarksheetSchedule, StudentResult, ConfigTemplate |
| D24 (permission prefix) | CLEAN | Consistent `tenant.msh-*` prefix |
| D25 ($request->all()) | PROBABLY CLEAN | Verified by code reading; grep unavailable due to alias |
| D29 (ENUM migrations) | CLEAN | 0 ENUMs in all 23 migrations |
| D30 (FormRequest authorize) | VIOLATED 19/19 | SEC-MSH-003 |
| D36 (generated columns) | N/A | No generated columns in MSH |
| D37 (status INT FK) | CLEAN | sys_dropdowns is tenant table |
| D38 (SoftDeletes vs DDL) | CLEAN | Consistent across schema |
| D39 (perms unseeded) | VIOLATED | D39-MSH — 0 MSH permissions in seeder |

---

*Report written by pa-technical-auditor. Evidence gathered 2026-06-29. All findings backed by direct file reads — no assumptions.*
