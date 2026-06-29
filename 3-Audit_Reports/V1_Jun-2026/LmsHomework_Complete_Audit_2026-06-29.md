# Complete Audit — LmsHomework (HMW) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

| Field | Value |
|-------|-------|
| Module | LmsHomework |
| Code / Prefix | HMW / `lms_` (homework-owned: `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions`) |
| App dir | `/Users/bkwork/Herd/prime_ai/Modules/LmsHomework` |
| Baseline | `4-Requirement_Module_wise/0-FRD_Documents/HMW_FRD_Complete_2026-06-29.md` (22 REQ · 49 BR · 4 RPT) |
| Auditor | Technical Auditor (pa-technical-auditor, Mode X) |
| Scope | 12-layer deep scan + FRD gap (B) + BR enforcement (C) + deploy gate (G) + scoped systemic-D for the 3 owned tables |

---

## Executive Summary
LmsHomework is a large, broadly-built module (2 controllers, the main one **2,360 lines**; 3 models; 5 policies; 3 FormRequests; 2 scheduled commands) whose **write paths are well-protected** (string `Gate::authorize` on every action, `DB::transaction` + `lockForUpdate` on submission) but whose **release / automation / notification subsystems are silently non-functional**. The worst finding is a cluster of P1 functional defects: `publish()` ignores the chosen release condition and releases every assignment immediately (BUG-HMW-001); the on-topic auto-release observer can never match (BUG-HMW-004); the overdue command runs in **central** context against tenant tables and reads an empty dropdown key (BUG-HMW-005); and **every** `NotificationTarget::create` is commented out so no notification is ever delivered (BUG-HMW-003). There are **no P0s** (no cross-tenant write hole, no committed secret, no migration deploy-blocker), so health is **not** P0-capped. **Health: 60/100 (Amber). DEPLOY: GO** for safety, but the module's headline LMS automation features (scheduled/on-topic release, overdue marking, notifications, late-policy enforcement) do not work end-to-end and should be treated as release-blocking for functionality.

## Health Score
Weighted 12-layer index = **~60/100 (Amber)**. No P0 → no 40-cap applied.
Dominant drags: Layer 10 Queue/Scheduler (Red — overdue command broken), Layer 5 Authorization (Amber — permission-string mismatch), Layer 6 Tenancy (Amber — API + console gaps), Layer 7 Validation (Amber — marks-max + late-policy gaps).

## Deploy Gate Verdict (Mode G) — **GO (no hard blocker)**
| Gate | Result |
|------|--------|
| P0 present? | No |
| Committed secret in module? | No |
| Cross-tenant write path? | No (web stack fully tenancy-gated; API surface non-functional + auth-gated) |
| Migration deploy-blocker? | No — the 3 tenant migrations are valid (DDL spec has dangling FKs but **does not ship**; migrations are authoritative) |
| Route/config-cache safety | Safe — no route closures, no `env()` in module routes |
| Web tenancy stack | Present: `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive` + `auth` + `verified` (`RouteServiceProvider.php:41-51`) |
**Verdict: GO.** Caveat: this is a *can-it-run-safely* GO, not a *features-work* GO. Several P1 functional subsystems are dead (release conditions, overdue, notifications).

---

## P0 Findings
**None.**

---

## P1 Findings

### [BUG-HMW-001] P1 — `publish()` ignores `release_condition`: every assignment is released immediately
- Location: `app/Http/Controllers/LmsHomeworkController.php:886-921`
- Evidence:
```php
$isImmediate = strtoupper($homework->release_condition ?? 'IMMEDIATE') === 'IMMEDIATE';
$isReleased  = $isImmediate ? 1 : 0;
$releasedAt  = $isImmediate ? now() : null;
$statusId    = $isImmediate ? $assignedStatusId : $pendingReleaseStatusId;   // computed…
DB::transaction(function () use (...) {
    foreach ($students as $student) {
        HomeworkAssignment::updateOrCreate([...], [
            'is_released' => true,            // …but hardcoded TRUE
            'released_at' => now(),           // …hardcoded now()
            'status_id'   => $assignedStatusId, // …hardcoded ASSIGNED — $statusId/$isReleased never used
        ]);
```
- Why it's a risk: `$isReleased`, `$releasedAt`, `$statusId` are computed for the scheduled/on-topic branch but never used. `ON_SCHEDULED_DATE` and `ON_TOPIC_COMPLETE` homework are released and set ASSIGNED at publish, instead of `is_released=0 / PENDING_RELEASE` per the DDL spec (`LmsHomework_DDL_v5.sql:309-311`). Defeats REQ-HMW-003 and BR-HMW-011/012.
- Fix: in the `updateOrCreate` payload use `$isReleased`, `$releasedAt`, `$statusId` (not the hardcoded values).
- Confidence: High · Systemic? module-local

### [SEC-HMW-001] P1 — Permission-string mismatch between FormRequests and controller/policy layer (A-AUTH-1)
- Location: `HomeworkRequest.php:23-26`; `HomeworkSubmissionRequest.php:19-23`; `HomeworkReviewRequest.php:17`; vs controllers/views using `tenant.home-work.*`
- Evidence:
```php
// HomeworkRequest::authorize()
return $this->user()->can('tenant.homework.create');          // no hyphen
// HomeworkSubmissionRequest::authorize()
return $this->user()->can('tenant.homework-submission.create'); // 'homework-submission'
// HomeworkReviewRequest::authorize()
return $this->user()?->can('grade-homework') ?? false;          // different namespace
```
Controller + 5 policies + all Blade tabs use `tenant.home-work.*` / `tenant.home-work-submission.*` (e.g. `LmsHomeworkController.php:62,341,381`; `submission/index.blade.php:9`). Grep of all seeders/permission sources found **zero** definitions of `tenant.homework.create`, `tenant.homework-submission.*`, or `grade-homework`.
- Why it's a risk: the two authorization layers guard *different* permission strings. Because the FormRequest strings appear undefined, `can()` returns false for any non-super-admin → the FormRequest **fails closed** and blocks legitimate teachers from create/update/grade (or, if a super-admin `Gate::before` bypasses, the FormRequest gate is simply a no-op and defense-in-depth is gone). Either way the gate is wrong.
- Fix: standardise FormRequest strings to the canonical `tenant.home-work.create|update`, `tenant.home-work-submission.create|update`, and the grade permission used by the controller. Seed the permissions if missing.
- Confidence: High · Systemic? relates to D24 (permission-prefix chaos)
- Escalation: **P0 if** the FormRequest permissions are genuinely undefined in production and no super-admin bypass exists (legitimate users cannot create/grade homework at all).

### [BUG-HMW-002] P1 — Late submission accepted even when late policy = deny (A-FN-1, BR-HMW-028 MISSING)
- Location: `HomeworkSubmissionController.php:153-194` (`store`)
- Evidence:
```php
$effectiveDueDate = $assignment->due_date ?? $homework->due_date;
$isLate = $effectiveDueDate ? now()->gt($effectiveDueDate) : false;
// … submission is created regardless; allow_late_submission is never checked to reject
```
- Why it's a risk: `is_late` is computed and stored, but the effective late policy (`assignment.allow_late_submission ?? homework.allow_late_submission`) is never consulted to *block* a late submission. BR-HMW-028 ("deny when policy = deny") is unenforced. Compliance/academic-integrity gap (RISK-HMW-001).
- Fix: after computing `$isLate`, resolve the effective policy and `throw`/reject when `$isLate && effective allow_late_submission == 0`.
- Confidence: High · Systemic? module-local

### [BUG-HMW-003] P1 — Notifications created but never delivered: every `NotificationTarget::create` is commented out (A-FN-2, BR-HMW-045)
- Location: 5+ sites — `LmsHomeworkController.php:1495-1510, 1602-1609, 1664-1669, 1710-1715, 2326-2331`; `HomeworkSubmissionController.php:492-497`; `ReleaseScheduledHomework.php` (no target block at all, only `Notification::create` at :138)
- Evidence:
```php
$notification = Notification::create([... 'notification_event' => 'HOMEWORK_ASSIGNED', ...]);
// NotificationTarget::create([
//     'notification_id' => $notification->id,
//     'target_table_name' => 'users',
//     'target_selected_id' => $assignment->student?->user_id,
//     'is_active' => true,
// ]);
```
- Why it's a risk: `Notification` rows are written with **no recipient targets**, so no student/parent is ever notified for assigned / due-changed / late-extended / reminder / graded events. REQ-HMW-020 is non-functional end-to-end (RISK-HMW-002).
- Fix: re-enable the `NotificationTarget::create` blocks (respecting guardian `can_receive_notifications`) per ENH-HMW-006.
- Confidence: High · Systemic? module-local

### [BUG-HMW-004] P1 — On-Topic-Completion auto-release observer can never match (A-FN-3, REQ-HMW-016 / ENH-004)
- Location: `app/Observers/SyllabusScheduleObserver.php:30-47`
- Evidence:
```php
$releasedStatusId = Dropdown::where('key', 'homework_status')->where('value', 'RELEASED')->value('id');
...
$homeworks = Homework::where('topic_id', $schedule->topic_id)
    ->where('section_id', $schedule->section_id)
    ->where('release_condition', 'ON_TOPIC_COMPLETE')
    ->whereHas('status', fn($q) => $q->where('value', 'PENDING'))->get();
```
- Why it's a risk: HMW homework statuses are seeded under key `lms_homework.status_id` with values `DRAFT/PUBLISHED/ARCHIVED` (`HomeworkDropdownKeys::HOMEWORK_STATUS`), and there is no `RELEASED`/`PENDING` value and no `homework_status` key. Both the status lookup and the `whereHas('status', 'PENDING')` filter return nothing, so topic-completion release never fires. It also (incorrectly) flips the *homework* status rather than the assignments.
- Fix: use `HomeworkDropdownKeys::HOMEWORK_STATUS`/`ASSIGNMENT_STATUS`; match `PUBLISHED` homework + `PENDING_RELEASE` assignments; release the **assignments** (mirror `ReleaseScheduledHomework`).
- Confidence: High · Systemic? module-local

### [BUG-HMW-005] P1 — Overdue command runs in CENTRAL context and reads an empty dropdown key → overdue marking never works (A-FN-4, BR-HMW-041)
- Location: `app/Console/UpdateHomeworkStatus.php:30-49`; scheduled at `routes/console.php:51`
- Evidence:
```php
// signature: tenant:homework:update-status — no tenancy()->initialize() and no Tenant::all() loop
$overdueStatusId = Dropdown::where('key', HomeworkDropdownKeys::ASSIGNMENT_STATUS_ALT)  // 'lms_homework.homework_assignment_status'
    ->where('value', 'OVERDUE')->value('id');
...
HomeworkAssignment::where('due_date','<',$now)->where('is_released',true)... ->update(['status_id'=>$overdueStatusId]);
```
- Why it's a risk: (a) Unlike `ReleaseScheduledHomework` (which iterates `Tenant::all()` and calls `tenancy()->initialize()`), this command has **no per-tenant tenancy init** — scheduled every minute in central context it queries the tenant table `lms_homework_assignment`, which does not exist centrally. (b) It reads `ASSIGNMENT_STATUS_ALT` (`lms_homework.homework_assignment_status`) but assignment statuses are seeded under `ASSIGNMENT_STATUS` (`lms_homework_assignment.status_id`), so `$overdueStatusId` is null and the command aborts with "OVERDUE not found". Overdue marking is doubly dead.
- Fix: wrap in `Tenant::all()->each(fn($t)=>tenancy()->run(...))` like the release command; resolve status via `HomeworkDropdownKeys::ASSIGNMENT_STATUS`.
- Confidence: High · Systemic? Layer 6.2 (console tenancy) + Layer 10.2 (per-tenant scheduling)

---

## P2 Findings

### [VAL-HMW-001] P2 — Grading paths do not enforce marks ≤ max_marks (BR-HMW-031 PARTIAL)
- Location: `LmsHomeworkController.php:1401-1404` (`assignmentsGrade`) and `:1904-1910` (`saveCheck`)
- Evidence: `'marks_obtained' => 'required|numeric|min:0'` and `'marks_obtained' => 'nullable|numeric|min:0'` — no `max`. Only `HomeworkReviewRequest.php:33-38` caps `max:{$maxMarks}`.
- Why it's a risk: a teacher grading via the assignment-show form or the paper-check workspace can enter marks above the homework maximum; BR-HMW-031 (0 ≤ marks ≤ max) is enforced on only one of three grade paths.
- Fix: add `max:` (resolved from `homework->max_marks`) to both methods.
- Confidence: High · Systemic? module-local

### [BUG-HMW-006] P2 — `store()`/`update()` auto-publish via unconditional `syncAssignments()` (BR-HMW-005/007)
- Location: `LmsHomeworkController.php:425, 614` calling `syncAssignments()` (`:2240-2358`)
- Evidence: `store()` calls `$this->syncAssignments($homework)` unconditionally; `syncAssignments` treats `null` release_condition as `IMMEDIATE`, creates assignments for all students and forces `status_id = PUBLISHED` (`:2349-2356`).
- Why it's a risk: a newly created homework with IMMEDIATE (or null) release is auto-published at creation, contradicting BR-HMW-005 ("new = Draft") and BR-HMW-007 ("publish only from Draft"). `update()` re-runs assignment generation on every edit.
- Fix: keep `store()` Draft-only; generate assignments solely in `publish()` after the Draft→Published guard.
- Confidence: Medium · Systemic? module-local

### [DATA-HMW-001] P2 — Migration default `release_condition = 'ON_TOPIC_COMPLETE'` (the dead path)
- Location: `database/migrations/tenant/2026_06_16_122811_create_lms_homework_table.php:26`
- Evidence: `$table->enum('release_condition', ['IMMEDIATE','ON_SCHEDULED_DATE','ON_TOPIC_COMPLETE'])->default('ON_TOPIC_COMPLETE');`
- Why it's a risk: any insert that omits `release_condition` defaults to the one mode whose listener is dead (BUG-HMW-004) → homework would never release. The form requires the field so the default is rarely hit, but the default is semantically wrong (should be `IMMEDIATE`).
- Fix: change default to `IMMEDIATE`.
- Confidence: High · Systemic? module-local

### [PERF-HMW-001] P2 — `index()` loads entire tenant tables unbounded
- Location: `LmsHomeworkController.php:70-71` (`Topic::get()`, `Student::get()`), `:65-69`
- Evidence: `$topicData = Topic::get(); $studentData = Student::get();` plus `Subject`/`Section`/`SchoolClass::get()` — full-table loads on the hub index.
- Why it's a risk: Topic and Student grow large per tenant; loading all rows on every hub render is wasteful (NFR-HMW-001 < 3s @ 500 users).
- Fix: paginate / lazy-load via the existing AJAX cascading endpoints; drop the unused `$studentData`/`$topicData` eager loads.
- Confidence: Medium · Systemic? module-local

### [TEN-HMW-001] P2 — API routes lack tenancy init and point at a view-returning controller (A-CODE-3)
- Location: `routes/api.php:6-8`; `RouteServiceProvider.php:59-62`
- Evidence: `Route::apiResource('lmshomeworks', LmsHomeworkController::class)` under `middleware('api')` + `auth:sanctum` only — no `InitializeTenancyByDomain`. The bound controller methods (`index`, `store`, …) return Blade views / web redirects, not JSON resources.
- Why it's a risk: the API surface runs in central context against tenant tables and returns HTML; it is effectively non-functional. Low exploit risk (auth-gated, no working write), but it is a latent cross-DB/cross-tenant footgun and dead surface.
- Fix: remove the API resource, or build a real tenancy-gated JSON controller.
- Confidence: High · Systemic? Layer 6 / Layer 4

### [SCH-DDL-001] P2 — DDL v5 spec is internally inconsistent (would fail a literal run) — A-DDL-1/2/3/4
- Location: `2-DDL_Tenant_Consolidated/LmsHomework_DDL_v5.sql:54, 66, 92, 174`
- Evidence: `realease_condition` typo (`:66`); dangling FKs `fk_hw_release_cond`/`fk_hwa_release_cond` reference a non-existent `release_condition_id` column (`:92, :174`); all dropdown FKs target `sys_dropdown_table` while live runtime uses `sys_dropdowns`; `hw_attachment_media_id Json UNSIGNED` (invalid qualifier) (`:54`).
- Why it's a risk: the spec is not runnable and diverges from the shipped migrations. Migrations are authoritative (ENUM `release_condition`, nullable `json`, `sys_dropdowns`, no FK on release_condition), so production is unaffected — but the DDL should be corrected (v6) to match.
- Fix: DB Architect — emit DDL v6: fix typo, drop the dangling FKs, rename `sys_dropdown_table`→`sys_dropdowns`, fix the JSON column type.
- Confidence: High · Systemic? D29 tension (ENUM vs dropdown FK)

### [BUG-HMW-007] P2 — `assignmentsIndex()` status filter queries the wrong column → empty filter
- Location: `LmsHomeworkController.php:1359`
- Evidence: `$statuses = Dropdown::where('type', 'homework_assignment_status')->get();` — `Dropdown` keys statuses by the `key` column (e.g. `lms_homework_assignment.status_id`); `type` holds `'String'`.
- Why it's a risk: the assignments-list status dropdown is always empty; users cannot filter by status on that screen.
- Fix: `Dropdown::where('key', HomeworkDropdownKeys::ASSIGNMENT_STATUS)->get()`.
- Confidence: High · Systemic? module-local

---

## P3 Findings

- **[DEAD-HMW-001] P3 — Dead Rule-Engine imports** in `app/Models/Homework.php:9-11` (`use ...TriggerEvent; ActionType; RuleEngineConfig;`) — those model files do not exist in this module (moved to EventEngine). Also unused `HomeworkRequest`, `Gate`, `Auth` imports (`:17-19`). Harmless unless referenced; remove. (A-CODE-1)
- **[DEAD-HMW-002] P3 — `seedTestData()` dev fixture left in production controller** `LmsHomeworkController.php:2160-2234` (generates random submissions). Gated by `tenant.home-work.update` but **not routed** (absent from `routes/web.php`) → unreachable dead code. Remove. (A-CODE-4)
- **[ORM-HMW-001] P3 — Three policies bound to `Homework::class`** `LmsHomeworkServiceProvider.php:59,62,63` (HomeworkPolicy, HomeworkDashboardPolicy, HomeworkSummaryPolicy) — Laravel keeps only the **last** (HomeworkSummaryPolicy); the other two are dead for model-resolved gates. Impact limited because the controller uses string gates. Use one policy or distinct models. (A-AUTH-2)
- **[DEAD-HMW-003] P3 — Duplicated `calculateIsLateForSubmission()`** defined twice in `LmsHomeworkController.php:2128` and again as an identical private method in `HomeworkSubmissionController.php:518`. Extract to a service.
- **[DATA-HMW-002] P3 — `is_resubmission_requested` is `unsignedInteger NOT NULL` with no default** (`...122813_create_lms_homework_submissions_table.php:21`) while the model casts `boolean`; every insert path currently sets it explicitly, but any future insert that omits it will fail. Add `->default(0)`. (A-DDL-6)

---

## Layer Health Summary
| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema | 🟡 Amber | DDL v5 typo + dangling FKs + `sys_dropdown_table` (SCH-DDL-001); migrations OK |
| 2 | Migration↔Model↔DDL | 🟡 Amber | release_condition ENUM (D29), wrong migration default (DATA-HMW-001), `is_resubmission_requested` no default |
| 3 | Model & ORM | 🟢 Green | casts/relations correct; only dead imports (DEAD-HMW-001) |
| 4 | Code Quality | 🟡 Amber | 2,360-line God controller; dead fixture + duplicated helper |
| 5 | Authorization | 🟡 Amber | controller gates solid, but FormRequest permission mismatch (SEC-HMW-001); 3-policy binding |
| 6 | Multi-Tenancy | 🟡 Amber | web stack correct; API + overdue-command lack tenancy (TEN-HMW-001, BUG-HMW-005) |
| 7 | Validation/Mass-assign | 🟡 Amber | `validated()` everywhere (no D25); but marks-max gap + late-policy not blocked |
| 8 | Data Integrity/Tx | 🟢 Green | `DB::transaction` + `lockForUpdate` on submission uniqueness (BR-024) |
| 9 | Performance | 🟡 Amber | unbounded `Topic::get()`/`Student::get()` on hub index (PERF-HMW-001) |
| 10 | Queue/Scheduler | 🔴 Red | overdue command broken (central context + wrong key); commands scheduled but ineffective |
| 11 | Frontend/Blade | 🟡 Amber | not exhaustively audited; no obvious raw-output XSS observed |
| 12 | Deployment | 🟢 Green | no secrets, no route closures, no `env()` in routes, full web tenancy stack |

## STEP 1 Reading-Discipline Output — Three-Way Reconcile (DDL v5 ↔ migration ↔ model)
| Column | DDL v5 | Migration (ships) | Model | Verdict |
|--------|--------|-------------------|-------|---------|
| release condition | `realease_condition` ENUM (typo) + dangling `release_condition_id` FK | `release_condition` ENUM, **default ON_TOPIC_COMPLETE**, no FK | string (no relation) | Migration authoritative; default wrong (DATA-HMW-001) |
| dropdown FKs | `sys_dropdown_table` | `sys_dropdowns` | `Dropdown` (`sys_dropdowns`) | `sys_dropdowns` authoritative |
| `hw_attachment_media_id` | `Json UNSIGNED` (invalid) | nullable `json` | cast `array` | nullable JSON array |
| `academic_session_id` | `INT UNSIGNED` | `unsignedSmallInteger` | — | minor type divergence vs FK target |
| `is_resubmission_requested` | `INT UNSIGNED NOT NULL` no default | `unsignedInteger` no default | cast `boolean` | latent insert risk (DATA-HMW-002) |
| submissions UNIQUE | `assignment_id` (CHG-1) | `unique('assignment_id','uq_hws_assignment')` | hasOne via `assignment_id` | consistent ✅ |
Snapshot corrections vs module-knowledge: all module-knowledge claims verified against live code — **confirmed accurate**. New live-only facts: (a) the commands ARE scheduled centrally (`routes/console.php:50-51`), but `update-status` lacks per-tenant init; (b) migration `release_condition` default is `ON_TOPIC_COMPLETE`.

## FRD Gap Summary (Mode B)
| REQ | Feature | Code | Test | Status | Note |
|-----|---------|------|------|--------|------|
| REQ-HMW-001 | Create/Manage | ✅ | ⚠ | DONE | validated()+tx; auto-publish side-effect (BUG-HMW-006) |
| REQ-HMW-002 | Publish & Assign | ✅ | partial | DONE | idempotent updateOrCreate ✅ |
| REQ-HMW-003 | Release Conditions | ⚠ | — | **BROKEN** | publish ignores condition (BUG-HMW-001) |
| REQ-HMW-004 | Attachments | ✅ | — | DONE | mimes+max:10240 ✅ |
| REQ-HMW-005 | Clone | ✅ | — | DONE | same-class guard ✅ |
| REQ-HMW-006 | Trash/Restore/Force | ✅ | — | DONE | isDeletable() guard ✅ |
| REQ-HMW-007 | Active Toggle | ✅ | — | DONE | |
| REQ-HMW-008 | Submission | ✅ | — | DONE | lockForUpdate uniqueness ✅ |
| REQ-HMW-009 | Late Detection/Policy | ⚠ | — | **PARTIAL** | late flagged but not blocked (BUG-HMW-002) |
| REQ-HMW-010 | Resubmission | ✅ | — | DONE | |
| REQ-HMW-011 | Grading | ⚠ | — | PARTIAL | marks-max only on review path (VAL-HMW-001) |
| REQ-HMW-012 | Paper Check | ✅ | — | DONE | marks-max gap (VAL-HMW-001) |
| REQ-HMW-013 | Score Publishing | ✅ | — | DONE | |
| REQ-HMW-014 | Assignment Tracking | ✅ | — | DONE | due-override/assign-lock enforced ✅ |
| REQ-HMW-015 | Bulk Download | ✅ | — | DONE | empty-state 404 ✅ |
| REQ-HMW-016 | Scheduled Automation | ⚠ | ✅(1) | **BROKEN** | overdue dead (BUG-HMW-005); on-topic dead (BUG-HMW-004); scheduled-release works |
| REQ-HMW-017 | Analytics Dashboard | ✅ | — | DONE | submission-rate formula matches BR-042 |
| REQ-HMW-018 | Summary Report | ✅ | — | DONE | counts match BR-043 |
| REQ-HMW-019 | Submission Listing | ✅ | — | DONE | graded filter ✅ |
| REQ-HMW-020 | Notifications | ⚠ | — | **BROKEN** | targets commented out (BUG-HMW-003) |
| REQ-HMW-021 | Dropdown Helpers | ✅ | — | DONE | |
| REQ-HMW-022 | Access/Tenant Isolation | ⚠ | — | PARTIAL | perm-string mismatch (SEC-HMW-001) |
Test coverage: **1 feature test** (`HomeworkSchedulingTest`) against 22 REQ — RISK-HMW-006.

## Business-Rule Enforcement (Mode C)
| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| BR-001/002 | Validation | HomeworkRequest:40-91 | ENFORCED | due `after:assign_date` |
| BR-003 | Validation | HomeworkRequest:63-83 | ENFORCED | passing ≤ max via closure |
| BR-005 | Workflow | store():404 | PARTIAL | year auto-set ✅; Draft undermined by BUG-HMW-006 |
| BR-007 | Workflow | publish():845 `isEditable()` | ENFORCED (publish) / PARTIAL | bypassed by store auto-publish (BUG-HMW-006) |
| BR-008/009 | Concurrency | publish():893 updateOrCreate(unique homework+student) | ENFORCED | idempotent |
| BR-011/012 | Workflow | publish():886-921 | **MISSING** | BUG-HMW-001 |
| BR-013 | Validation | HomeworkRequest:96 | ENFORCED | release date ≥ assign |
| BR-014/026 | Validation | both FormRequests mimes/max | ENFORCED | |
| BR-016/017 | Validation | clone():736-752 | ENFORCED | same-class + not-self |
| BR-018 | Workflow | destroy():641 `isDeletable()` | ENFORCED | |
| BR-022/024 | Validation/Concurrency | store():163-167 lockForUpdate + unique | ENFORCED | |
| BR-023/027 | Calculation | store():153-154 | PARTIAL | effective due ✅; effective policy not used to block |
| BR-028 | Validation | — | **MISSING** | BUG-HMW-002 |
| BR-031 | Validation | review (max) / assignmentsGrade,saveCheck (no max) | PARTIAL | VAL-HMW-001 |
| BR-032 | Workflow | review():429-503 graded_by/at + activityLog | ENFORCED | |
| BR-034 | Workflow | review():458 / saveCheck:2069 | ENFORCED | auto-publish score |
| BR-035 | Validation | assignmentUpdateDueDate:1459 | ENFORCED | not earlier |
| BR-036 | Validation | assignmentUpdateAssignDate:1576 | ENFORCED | 403 after release |
| BR-038 | Validation | assignmentUpdateDueDate:1478 | PARTIAL | reason captured only if late allowed; not hard-required |
| BR-040 | Workflow | ReleaseScheduledHomework:52 | ENFORCED | per-tenant loop ✅ |
| BR-041 | Workflow | UpdateHomeworkStatus | **MISSING** | BUG-HMW-005 |
| BR-042/043 | Calculation | index():143 / withCount:201-220 | ENFORCED | formulas match FRD |
| BR-045 | Workflow | Notification::create (many) | PARTIAL | rows created, no targets (BUG-HMW-003) |
| BR-047 | Permission | controller Gate::authorize ✅ / FormRequest mismatch | PARTIAL | SEC-HMW-001 |
| BR-048 | Tenancy | web RSP stack ✅ | ENFORCED | API/console gaps are non-web |
| BR-049 | Workflow | activityLog on CUD/grade/restore | ENFORCED | |

## Systemic-Pattern Scorecard (Mode D, scoped to HMW)
| Pattern | Present? | Count | vs Baseline |
|---------|----------|-------|-------------|
| D17 (fillable→missing column) | No | 0 | fillable matches migrations |
| D24 (permission-prefix chaos/typo) | **Yes** | 3 FormRequests | SEC-HMW-001 |
| D25 (`$request->all()` into model) | No | 0 | uses `validated()` everywhere (better than baseline) |
| D29 (ENUM in migration) | **Yes** | 1 (`release_condition`) | below baseline; status fields correctly use `sys_dropdowns` |
| D30 (FormRequest `authorize(){return true;}`) | No | 0 | all 3 implement real (if mismatched) `can()` checks — better than 90% baseline |
| D36 (GENERATED column degraded) | No | 0 | no generated columns in the 3 tables |
| Layer 2.5 (cross-DB/missing FK target) | No | 0 | FKs target `sys_dropdowns`/sch_/slb_/std_ which exist; `sys_roles` not referenced |
| Layer 6.2 (initialize without end) | **Yes** | 1 | `UpdateHomeworkStatus` never inits (worse — no tenancy at all); `ReleaseScheduledHomework` inits+ends correctly |
| Layer 10.1 (job tenancy) | **Yes** | 1 | overdue command (BUG-HMW-005) |
| TEN-RTG-001 (module-subscription middleware) | n/a | — | web RSP carries full tenancy + EnsureTenantIsActive |

## vs Platform Baseline
Better than norm: **0** `$request->all()` (baseline 24 sites), **0** bare-`true` FormRequests (baseline 90%), proper `lockForUpdate` + transactions (many modules lack these). Worse/typical: a 2,360-line God controller (in line with the StudentController/LmsExamController God-object backlog), 1 ENUM in migration (well below the ~476 platform total), and a permission-prefix mismatch (D24 family).

## Recommended Fix Order
1. **SEC-HMW-001** — align FormRequest permission strings to `tenant.home-work*` (unblocks/secures all create/grade paths). [Developer]
2. **BUG-HMW-001** — use the computed `$isReleased/$releasedAt/$statusId` in `publish()` (restores release conditions). [Developer]
3. **BUG-HMW-005** — add per-tenant tenancy loop + correct dropdown key to `UpdateHomeworkStatus` (restores overdue marking). [Developer]
4. **BUG-HMW-003** — re-enable `NotificationTarget::create` blocks (ENH-006). [Developer]
5. **BUG-HMW-002 / VAL-HMW-001** — hard-block late submissions when policy=deny; add marks-max to the two grade paths. [Developer]
6. **BUG-HMW-004** — fix the on-topic observer key/status (ENH-004). [Developer]
7. **BUG-HMW-006 / DATA-HMW-001** — keep `store()` Draft-only; fix migration default. [Developer/DB Architect]
8. **SCH-DDL-001** — emit DDL v6 matching migrations. [DB Architect]
9. P2/P3 cleanup (PERF-HMW-001, TEN-HMW-001, BUG-HMW-007, dead code).
10. Build a Pest suite covering the 6 P0-priority REQ acceptance criteria. [Testing Architect]

---
*Read-only audit. No application code was modified. Codes registered here (SEC/BUG/VAL/DATA/TEN/PERF/SCH/ORM/DEAD-HMW-NNN) are new; historical `HWK`/`LMS`-prefixed entries in known-issues.md referenced a since-removed `StudentHomeworkController`.*
