# Complete Audit — LmsExam (EXM) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** LmsExam | **Code:** EXM | **Prefix:** `lms_` (exam-owned tables = `lms_exam*`) | **Type:** Tenant
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/LmsExam`
**Baseline (B/C):** `EXM_FRD_Complete_2026-06-29.md` (19 REQ / 36 BR / 6 RPT) — REQ/BR/RPT IDs reused, never renumbered.
**Auditor:** Technical Auditor (read-only) | All findings carry `file:line` + verbatim evidence + confidence.

---

## Executive Summary
Scope: full 12-layer deep scan + FRD gap (B) + business-rule enforcement (C) + deploy gate (G) + module-scoped systemic sweep (D). The single worst finding is **SEC-EXM-005 — `GrievanceReviewController` has ZERO authorization on a published-mark-mutating workflow** (`resolve()` rewrites `lms_exam_results.total_marks_obtained`/`percentage` for any student, reachable by any authenticated user). With its FormRequest `authorize()` also hard-coded `true`, the grievance pipeline has **no authorization at any layer**. Overall health is **capped at 40/100** (one confirmed P0). Authorization is otherwise strong on the 12 CRUD controllers (143 `tenant.*` gate calls, one clean prefix, no `tennat.` typos), but a **policy-registration overwrite bug silently disables ~12 model policies** and the entire advanced-reports hub is gated by the wrong (homework) permission. **DEPLOY: NO-GO.**

Positives confirmed against live code (correcting stale snapshots): zero `dd()`/debug statements, zero hard-coded secrets, zero `$request->all()` mass-assignment, all 11 owned tables have migrations, scheduled publish runs correctly under `tenants:run`, and the shared-DDL "phantom column / missing comma" anomalies do **not** ship in the live migrations (the migrations are correct; only the StudentAttempt DDL `.sql` spec is broken).

---

## Health Score
Weighted layer index ≈ **59.5/100**, **capped to 40/100** because a P0 (SEC-EXM-005) is present. Per rubric: "a single cross-tenant/auth/data-integrity blocker means not healthy, period."

| Layer (weight) | Score | Note |
|---|---|---|
| 6 Tenancy (15) | Green 1.0 | Full tenancy stack on RSP; `tenants:run` schedule; DB-per-tenant. SEC-EXM-007 reassessed as non-issue. |
| 5 Authorization (14) | **Red 0.0** | P0 grievance zero-auth; policy-overwrite (12 dead); wrong report permission; no license guard. |
| 8 Data Integrity (13) | Amber 0.5 | Grievance recompute incomplete (BUG-EXM-004); txn used but no rank/grade recompute or lock. |
| 7 Validation/Mass-assign (11) | Amber 0.5 | All 12 FormRequest `authorize()` = true (D30); rules present; no `$request->all()`. |
| 12 Deployment (10) | Green 1.0 | No secrets, no route closures, schedule tenant-wrapped. |
| 2 Mig↔Model↔DDL (9) | Amber 0.5 | `created_by` gaps; D29 ENUMs; dead command queries renamed column. Migrations present+correct. |
| 1 DDL Schema (7) | Amber 0.5 | 6 ENUMs (D29); `created_by` on only 2 of 11 owned tables. |
| 9 Performance (7) | Amber 0.5 | PERF-LMS-002 unbounded index queries; God controllers; no service layer. |
| 10 Queue/Job (6) | Green 1.0 | No jobs; scheduled command tenant-aware. |
| 4 Code Quality (4) | Amber 0.5 | LmsExamController 3767 lines, PaperSetQuestionController 1465; dead command. |
| 3 ORM (2) | Amber 0.5 | Duplicate `casts` key; created_by relations only on Exam. |
| 11 Frontend (2) | Green 1.0 | No unescaped user output / secrets found in views (not exhaustively audited). |

---

## Deploy Gate Verdict (Mode G): **NO-GO**
Blocking items:
1. **SEC-EXM-005 (P0)** — unauthenticated-by-authorization mutation of published marks. A breach of NFR-EXM-008 (defense-in-depth) and the "marks-mutating actions must verify authorisation" security NFR.

Non-blocking but release-gating (P1): SEC-EXM-008 (D30), SEC-EXM-009 (policy overwrite), SEC-EXM-010 (wrong report permission), SEC-EXM-011 (no module-license guard / REQ-EXM-019), BUG-EXM-003 (route→500), BUG-EXM-004 (stale grade/rank after grievance).
Layers 6/10/12 clear; no committed secrets; no route closures in module routes; no `sys_roles`/`sys_dropdowns` cross-DB FK in owned migrations.

---

## P0 Findings

```
[SEC-EXM-005] Severity: P0 | GrievanceReviewController — ZERO authorization on a published-mark-mutating workflow
- Location: app/Http/Controllers/GrievanceReviewController.php  (index:21, store:69, show:101, resolve:117, toggleStatus:187)
- Evidence:
    class GrievanceReviewController extends Controller {        // 0 Gate::authorize across the whole file
        public function resolve(GrievanceRequest $request, int $id) {
            $grievance = ExamGrievance::with('examResult')->findOrFail($id);
            ...
            $result->update(['total_marks_obtained' => $newMarks, 'percentage' => $newPct]);
            $updatePayload['marks_changed'] = true; ...
- Why it's a risk: Every sibling controller carries 10–27 Gate::authorize calls; this one carries 0 (verified
    `gates=0`). resolve() rewrites a PUBLISHED student's marks/percentage with no permission check, and
    GrievanceRequest::authorize() also returns true (SEC-EXM-008) — so there is NO authorization at any layer.
    Any authenticated tenant user (incl. a student) can read every grievance (show/index), file grievances for
    any student (store), and resolve/reject + revise published marks for any student. Violates BR-EXM-034 intent
    and NFR-EXM-008. (Confirms & extends the 2026-04 SEC-EXM-005 which cited only show()/resolve().)
- Fix: Add Gate::authorize('tenant.re-evaluation-requests.viewAny'|'.view'|'.update') to index/show/store/resolve/
    toggleStatus, and tie GrievanceRequest::authorize() to the same gate. Register ReEvaluationRequestsPolicy to
    a dedicated model (see SEC-EXM-009) rather than Exam::class.
- Confidence: High
- Systemic? : Instance of D30 (auth-by-controller-only) collapsing because the controller has no gate either.
```

---

## P1 Findings

```
[SEC-EXM-008] Severity: P1 | All 12 FormRequest authorize() hard-coded `return true` (D30)
- Location: app/Http/Requests/*.php (all 12: ExamAllocation, ExamBlueprint, ExamPaper, ExamPaperSet, Exam,
    ExamScope, ExamStatusEvent, ExamStudentGroupMember, ExamStudentGroup, ExamType, Grievance:9, PaperSetQuestion)
- Evidence:
    public function authorize() { return true; }
    // GrievanceRequest.php:11 → return true; // "Authorization is handled in controller or via gate"
- Why it's a risk: Defense-in-depth (NFR-EXM-008 "request AND controller layer") collapses to controller gates
    only. For 11 of 12 the controller gate compensates; for GrievanceRequest the controller has NO gate → the
    request layer is the only possible guard and it is disabled → escalates to the P0 above.
- Fix: Each authorize() returns Gate::allows('tenant.<entity>.<action>') matching its route. Keep controller gates.
- Confidence: High   | Systemic? : D30 (platform 437/485 = 90%). EXM is typical, not an outlier.
- Note: subsumes the earlier SEC-EXM-006 (PaperSetQuestionRequest specifically).
```

```
[SEC-EXM-009] Severity: P1 | Policy-registration overwrite — ~12 model policies silently dead; Scope/Blueprint unregistered
- Location: app/Providers/LmsExamServiceProvider.php:87–108 (registerPolicies)
- Evidence:
    Gate::policy(Exam::class, ExamPolicy::class);               // line 88
    Gate::policy(Exam::class, LmsExamReportPolicy::class);      // 96
    Gate::policy(Exam::class, OnlineAssessmentPolicy::class);   // 97 ... (13 total mapped to Exam::class)
    Gate::policy(Exam::class, LmsActivityDashboardPolicy::class); // 107  ← only this LAST one survives
- Why it's a risk: Laravel keeps ONE policy per model. Exam::class is registered 13×, so ExamPolicy and ~11
    report/assessment/grievance policies are overwritten → dead. ExamScopePolicy, ExamBlueprintPolicy and
    AnswerSheetOnlineExam are not registered at all. Any `$user->can(..., $exam)` resolves against
    LmsActivityDashboardPolicy regardless of intent. Also lines 41–42 import non-existent classes
    `HwSubmissionTrackerPolicy`/`HwPerformanceAnalysisPolicy` (actual files: Homework*Policy) — would fatal if
    ever invoked. Controllers happen to use permission-STRING gates (`tenant.*`), so functional impact is masked
    today, but the model-policy authorization layer is non-functional.
- Fix: Map each policy to its own model/ability (introduce distinct policy targets or use ability-based Gates);
    register ExamScopePolicy/ExamBlueprintPolicy; fix the two Hw* import names.
- Confidence: High   | Systemic? : module-local design defect.
```

```
[SEC-EXM-010] Severity: P1 | Advanced-reports hub gated by a single WRONG (homework) permission; per-report exam gates absent
- Location: app/Http/Controllers/ExamAdvancedReportController.php:38 (798-line controller, 6 reports)
- Evidence:
    Gate::authorize('tenant.hw-submission-tracker.view');   // the only gate in the whole controller
- Why it's a risk: RPT-EXM-001 (Exam Result Ledger), 002 (Student History), 003 (Subject Comparison), 004 (LMS
    Activity) are all guarded by a HOMEWORK permission, not an exam-report permission. A user granted homework-
    tracker view but not exam-report view sees ranked exam results; a user with exam-report perms but not the
    homework perm is wrongly denied. The intended model policies (ExamResultReportPolicy, StudentExamHistory,
    ExamSubjectComparison, LmsActivityDashboard) are dead via SEC-EXM-009.
- Fix: Add per-report gates (`tenant.exam-result-report.view`, etc.); register the matching policies.
- Confidence: High   | Systemic? : compounds SEC-EXM-009.
```

```
[SEC-EXM-011] Severity: P1 | No module-license guard (REQ-EXM-019 / NFR-EXM-009 NOT DONE)
- Location: app/Providers/RouteServiceProvider.php:41–48 (mapWebRoutes middleware stack)
- Evidence:
    Route::middleware(['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class,
        EnsureTenantIsActive::class, 'auth', 'verified'])->prefix('lms-exam')...   // no hasModule:EXM
- Why it's a risk: A school not subscribed to the Examination module can reach every LmsExam screen (REQ-EXM-019
    fails AC-1/AC-2). Tenancy + active-tenant checks exist, but no subscription/licensing gate.
- Fix: Add an `EnsureTenantHasModule:EXM` (hasModule:EXM) middleware to the route group.
- Confidence: High   | Systemic? : platform pattern (license guard missing across modules).
```

```
[BUG-EXM-003] Severity: P1 | ExamStudentGroupMemberController::toggleStatus() missing → route returns 500 (CONFIRMED STILL PRESENT)
- Location: routes/web.php:171  →  app/Http/Controllers/ExamStudentGroupMemberController.php (no such method)
- Evidence:
    Route::post('/exam-group-member/{exam_group_member}/toggle-status',
        [ExamStudentGroupMemberController::class, 'toggleStatus'])->name('exam-group-member.toggleStatus');
    // controller defines trashed():353, restore():367, forceDelete():404 — NO toggleStatus()
- Why it's a risk: POST to the registered route throws "method does not exist" (500). Open since 2026-04-02.
    (Route line moved 130→171 since the original report; defect unchanged.)
- Fix: Implement toggleStatus() (mirror the sibling controllers' toggle pattern) or remove the route.
- Confidence: High   | Systemic? : module-local (route↔method coverage, Layer 4.1).
```

```
[BUG-EXM-004] Severity: P1 | Grievance resolve recomputes only marks+percentage — grade/division/rank go stale (BR-EXM-031/033/034 PARTIAL)
- Location: app/Http/Controllers/GrievanceReviewController.php:142–159
- Evidence:
    $result->update(['total_marks_obtained' => $newMarks, 'percentage' => $newPct]);
    // grade_obtained, division, rank_in_class, result_status NOT recomputed
- Why it's a risk: BR-EXM-031 (grade/division from scheme), BR-EXM-033 (class rank), BR-EXM-034 ("grievance mark
    change recomputes the result") require a full recompute. After a grievance raises a student's marks, the
    published grade/division/rank remain at pre-revision values → inconsistent report cards downstream
    (MarksheetGeneration/HPC read lms_exam_results). Marksheet/rank for the whole class can be wrong.
- Fix: On marks_changed, re-derive grade/division from the grading scheme and recompute class rank for the paper
    (excluding Absent/Withheld, BR-EXM-033); ideally in a shared ResultComputationService.
- Confidence: High   | Systemic? : module-local; ties to absent service layer (RISK-EXM-005).
```

```
[PERF-LMS-002] Severity: P1 | Unbounded dashboard queries + God controllers (CONFIRMED STILL PRESENT)
- Location: app/Http/Controllers/LmsExamController.php (index dashboard stats ~148–180; file = 3767 lines);
    PaperSetQuestionController.php = 1465 lines; no domain service layer (11 services are *UsageCheck guards + ExamQueryService).
- Evidence:
    ClassSection::with(['class','section'])->where('is_active',1)->get();   // unbounded
    // multiple ->get()/->count() aggregates built per index request
- Why it's a risk: O(tenant-size) loads on a hot page (NFR-EXM-001 <2s P95, NFR-EXM-011 paginate reference data);
    3767-line controller is unmaintainable and holds business logic that belongs in services (RISK-EXM-005).
- Fix: Paginate/cache reference loads; extract ExamService/ExamPaperService/ResultComputationService.
- Confidence: High   | Systemic? : God-object backlog (LmsExamController is a platform top-3 offender).
```

---

## P2 Findings

```
[DATA-EXM-001] Severity: P2 | created_by missing on 5 config tables + models (audit-trail gap, NFR-EXM-006)
- Location: app/Models/{ExamType,ExamStatusEvent,ExamScope,ExamBlueprint,ExamStudentGroup}.php (no created_by);
    DDL LmsExam_DDL_v6.sql (created_by present on only 2 of 11 owned tables).
- Evidence: grep created_by → present in Exam.php (fillable:39 + boot auto-set:73 + creator():161) only; the 5
    config models show no created_by; owned DDL `grep -c created_by` = 2.
- Why it's a risk: create/update audit trail (who created an exam type/status/scope/blueprint/group) is absent,
    failing NFR-EXM-006 "all create/update/delete record who and when".
- Fix: Additive migration adding `created_by INT UNSIGNED NULL` FK → sys_users on the 5 tables; add to fillable +
    a creating() hook (mirror Exam.php).
- Confidence: High   | Systemic? : platform (382 tenant tables miss created_by).
```

```
[SCH-EXM-001] Severity: P2 | ENUM columns in owned DDL instead of dropdown FK (D29)
- Location: LmsExam_DDL_v6.sql:37 event_type, :114 result_published, :146 mode, :172 offline_entry_mode, :290 allocation_type
- Evidence:
    `allocation_type` ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT') NOT NULL,
    `result_published` ENUM('IMMEDIATE','SCHEDULED','MANUAL') NOT NULL DEFAULT 'MANUAL',
- Why it's a risk: D29 — multi-value pick-lists should be `_id` FK → sys_dropdown_table for extensibility/i18n.
    Code-gated binary state is the only sanctioned ENUM exception; these are multi-value.
- Fix: Per D29, migrate to dropdown FKs (or accept as code-gated state machines and document the exception).
- Confidence: High   | Systemic? : D29 (~476 enum calls platform-wide). EXM is low-volume.
```

```
[DAT-EXM-002] Severity: P2 | Shared-runtime DDL anomalies — DDL SPEC broken, live migrations CORRECT (attribute to StudentAttempt owner)
- Location: StudentAttempt_DDL_v4.sql — attemp_activity_event_types (PK line) and lms_offline_exam_upload_detail (uq/idx)
- Evidence (DDL spec, would fail to CREATE):
    PRIMARY KEY (`id`)            -- missing comma
    UNIQUE KEY `uq_event_code` (`code`),
    -- offline_exam_upload_detail: UNIQUE KEY uq_exme_attempt (`attempt_id`) + KEY idx_exme_is_active (`is_active`)
    --   but the table has neither column (real col: offline_exam_upload_id; no is_active in the spec's list)
  Live migration (CORRECT — corrects the BA snapshot which implied a live defect):
    2026_06_16_112825_..._offline_exam_upload_detail: $table->unique('offline_exam_upload_id','uq_exme_attempt');
        is_active column IS present (line 29) → index valid;
    2026_06_16_112813_..._attemp_activity_event_types: proper unique('code')+index('name')+index('is_active').
- Why it's a risk: The runtime is SAFE because provisioning uses migrations, not the raw .sql. Risk only if anyone
    provisions a tenant from StudentAttempt_DDL_v4.sql directly (it errors / builds phantom indexes). Also the
    table name is misspelled `attemp_` and the migration adds an `lms_` prefix (`lms_attemp_activity_event_types`)
    while the DDL names it `attemp_activity_event_types` → DDL↔migration name divergence.
- Fix: Owner (StudentAttempt engine) should fix the .sql spec to match the shipped migrations; reconcile the table
    name/spelling. EXM only consumes these tables.
- Confidence: High   | Systemic? : DDL-spec hygiene; ownership = StudentAttempt, NOT LmsExam.
```

```
[DEAD-EXM-003] Severity: P2 | ReleaseScheduledExamResults command is dead AND broken (queries renamed column)
- Location: app/Console/ReleaseScheduledExamResults.php (imported in ServiceProvider:49 but NOT in registerCommands:115)
- Evidence:
    protected $signature = 'tenant:exam:release-scheduled-results';
    Exam::query()->where('show_result_type','SCHEDULED')...   // show_result_type is COMMENTED OUT in DDL:169
    // live column is `result_published`; registerCommands() only registers PublishScheduledResults
- Why it's a risk: A second, divergent scheduled-publish implementation that is never registered (dead) and would
    throw "Unknown column show_result_type" if it ever were. Duplicates the live `lms-exam:publish-results`
    (correctly scheduled via `tenants:run` in the provider). Confusing maintenance trap (which is canonical?).
- Fix: Delete ReleaseScheduledExamResults (and its stale import) or reconcile it onto `result_published` and
    consolidate to one command.
- Confidence: High   | Systemic? : module-local dead/divergent code.
```

---

## P3 Findings
- **Duplicate `casts` key** — `app/Models/Exam.php` defines `'scheduled_result_at' => 'datetime'` twice (:50 and :56); second silently overwrites. Harmless, clean up.
- **Misspelled shared table** — `attemp_activity_event_types` (missing 't') persists into the live migration name `lms_attemp_activity_event_types`. Cosmetic; owned by StudentAttempt.

---

## Layer Health Summary (12-row)
| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema | Amber | D29 ENUMs (SCH-EXM-001); created_by on 2/11 owned tables |
| 2 | Mig↔Model↔DDL | Amber | created_by gap (DATA-EXM-001); dead cmd queries renamed col; migrations present & correct |
| 3 | Model/ORM | Amber | Duplicate casts key; created_by only on Exam |
| 4 | Code Quality | Amber | God controllers 3767/1465; dead command (DEAD-EXM-003); no service layer |
| 5 | **Authorization** | **Red** | **SEC-EXM-005 P0**; policy-overwrite (SEC-EXM-009); wrong report perm (SEC-EXM-010); no license guard (SEC-EXM-011) |
| 6 | Tenancy | Green | Full RSP stack; `tenants:run` schedule; DB-per-tenant; SEC-EXM-007 reassessed = non-issue |
| 7 | Validation/Mass-assign | Amber | D30 all 12 authorize()=true (SEC-EXM-008); no `$request->all()`; rules present |
| 8 | Data Integrity/Tx | Amber | Grievance recompute incomplete (BUG-EXM-004); txn present, no rank/grade recompute |
| 9 | Performance | Amber | PERF-LMS-002 unbounded queries; God controllers |
| 10 | Queue/Job | Green | No jobs; scheduled publish tenant-aware |
| 11 | Frontend | Green | No secrets/raw user output found in views (not exhaustive) |
| 12 | Deployment | Green | No secrets, no module route closures, schedule wrapped |

---

## STEP 1 Reading-Discipline Output — three-way reconcile (DDL v6 ↔ migration ↔ model)
| Owned table | DDL v6 | Migration | Model | Verdict |
|---|---|---|---|---|
| lms_exam_types | yes (no created_by) | 112702 | ExamType (no created_by) | created_by gap (DATA-EXM-001) |
| lms_exam_status_events | yes (event_type ENUM) | 112700 | ExamStatusEvent | D29 ENUM; created_by gap |
| lms_exam_student_groups | yes (exam_id commented) | 112701 | ExamStudentGroup | created_by gap |
| lms_exam_student_group_members | yes | 112703 | ExamStudentGroupMember | OK; controller toggleStatus missing (BUG-EXM-003) |
| lms_exams | yes (result_published ENUM, scheduled_result_at) | 112704 | Exam (created_by + boot) | OK; dup casts key (P3) |
| lms_exam_papers | yes (mode/offline_entry_mode ENUM, show_result_type commented) | 112705 | ExamPaper | D29 ENUMs |
| lms_exam_paper_sets | yes | 112707 | ExamPaperSet | OK |
| lms_exam_scopes | yes | 112708 | ExamScope | created_by gap |
| lms_exam_blueprints | yes | 112706 | ExamBlueprint | created_by gap |
| lms_paper_set_questions | yes | 112710 | PaperSetQuestion | OK |
| lms_exam_allocations | yes (allocation_type ENUM, class_id NOT NULL) | 112709 | ExamAllocation | D29 ENUM |
| **Shared (StudentAttempt-owned)** | DDL spec broken (DAT-EXM-002) | **migrations correct** | OfflineExamUploadMark/Detail in EXM; ExamResult/ExamGrievance in StudentPortal | runtime safe; .sql spec needs owner fix |

Snapshot corrections vs module-knowledge: (1) shared-DDL anomalies are **DDL-spec-only — live migrations are correct** (BA file implied a live defect); (2) `ExamStudentGroupMemberController::toggleStatus()` is **still missing** (BA "DONE" for REQ-009 is true for CRUD but this route is broken); (3) zero debug / zero secrets / zero `$request->all()` re-confirmed live.

---

## FRD Gap Summary (Mode B) — REQ → Code/DDL/Test
| REQ | Feature | Code | DDL/Mig | Test | Gap |
|---|---|---|---|---|---|
| 001 | Exam Type | DONE | yes | **none** | created_by gap (DATA-EXM-001) |
| 002 | Status/Lifecycle | DONE | yes | none | — |
| 003 | Exam Creation | DONE | yes | none | (BR-003/004 enforced) |
| 004 | Paper Definition | DONE | yes | none | D29 ENUMs |
| 005 | Blueprint | DONE | yes | none | policy unregistered (SEC-EXM-009); authorize()=true |
| 006 | Scope | DONE | yes | none | policy unregistered; authorize()=true |
| 007 | Paper Set | DONE | yes | none | — |
| 008 | Question Assignment | DONE (fat ctrl 1465) | yes | none | no service extraction |
| 009 | Student Groups | DONE (CRUD) | yes | none | **toggleStatus route→500 (BUG-EXM-003)** |
| 010 | Allocation | DONE | yes | none | — |
| 011 | Online Attempt | PARTIAL | shared (mig OK) | none | player owned by StudentPortal (by design) |
| 012 | Offline Upload | DONE | shared (mig OK) | none | — |
| 013 | Evaluation | DONE | shared | none | — |
| 014 | Result Compute/Publish | PARTIAL | shared; ExamResult model in StudentPortal | none | scheduled publish OK (`tenants:run`) |
| 015 | Grievance | **PARTIAL — SEC-EXM-005 P0 + BUG-EXM-004** | shared | none | zero auth; recompute incomplete |
| 016 | Assessment Dashboard | DONE | n/a | none | — |
| 017 | Live Monitoring | DONE (read-only) | shared | none | — |
| 018 | Advanced Reports | DONE | n/a | none | wrong permission (SEC-EXM-010) |
| 019 | Module License Guard | **NOT DONE** | n/a | none | no hasModule:EXM (SEC-EXM-011) |

Test coverage: **0 tests** (only `.gitkeep` in tests/Unit + tests/Feature) for a P0-security, marks-mutating module — major gap (Testing Architect handoff).

---

## Business-Rule Enforcement (Mode C)
| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| 001 ExamType code unique | Validation | ExamTypeRequest rules | ENFORCED (authorize=true → SEC-EXM-008) | |
| 002 status entity-kind | Validation | ExamStatusEventRequest | ENFORCED | |
| 003 one exam/session+class+type | Validation | ExamRequest | ENFORCED | |
| 004 end ≥ start | Validation | ExamRequest | ENFORCED | |
| 005 paper code unique | Validation | ExamPaperRequest | ENFORCED | |
| 006 AI⇒proctored | Validation | ExamPaperRequest | ENFORCED (verify rule) | |
| 009 section name unique | Validation | ExamBlueprintRequest | ENFORCED | |
| 010 blueprint/scope students refused | Permission | controller `tenant.exam-blueprint/scope.*` gates | **PARTIAL** | gate active but policy dead (SEC-EXM-009), authorize=true (SEC-EXM-008) |
| 012 set code unique | Validation | ExamPaperSetRequest | ENFORCED | |
| 014 question once per set | Validation | PaperSetQuestionRequest + UNIQUE(set,question) | ENFORCED | |
| 017/018 group/member unique | Validation | requests + UNIQUE | ENFORCED | |
| 019 alloc end>start | Validation | ExamAllocationRequest | ENFORCED | |
| 020 target fields by type | Validation | ExamAllocationRequest | ENFORCED (verify conditional) | |
| 021 exam FSM | Workflow | status master | ENFORCED (config-driven) | |
| 023 ≤1 attempt/student/paper | Concurrency | UNIQUE(paper,student) | ENFORCED (DB) | |
| 027 marks ≤ total | Validation | offline upload validation | ENFORCED (verify) | |
| 029 absent excluded | Workflow | result compute | ENFORCED (verify) | |
| 031 grade/division from scheme | Calculation | result compute / grievance | **PARTIAL** | grievance path skips it → BUG-EXM-004 |
| 032 award ≤ question max | Validation | evaluation | ENFORCED (verify) | |
| 033 rank excl Absent/Withheld | Calculation | result compute | **PARTIAL** | not recomputed on grievance → BUG-EXM-004 |
| 034 post-publish change Admin/grievance + recompute | Workflow | GrievanceReviewController::resolve | **MISSING (auth) / PARTIAL (recompute)** | SEC-EXM-005 + BUG-EXM-004 |
| 035 no publish with pending marks | Workflow | publish path | ENFORCED (verify) | |
| 036 mode-scoped dashboards | Workflow | dashboards | ENFORCED | |

Most validation BRs are enforced in FormRequest `rules()`, but every one is undermined by `authorize()=true` (SEC-EXM-008) — rules still run (authorize only gates access), so validation holds; the gap is purely authorization. Workflow BR-034 is the critical failure (P0 auth + partial recompute).

---

## Systemic-Pattern Scorecard (Mode D, scoped to EXM)
| Pattern | Present? | Count / Evidence | vs baseline |
|---|---|---|---|
| D17 model field ∉ DB | No (owned) | Exam fillable matches; dead cmd uses removed `show_result_type` (DEAD-EXM-003) | below norm |
| D24 permission-prefix chaos/typos | **No** | 143 gate calls, single `tenant.` prefix, no `tennat.` | cleaner than norm |
| D25 `$request->all()` mass-assign | **No** | 0 sites | below 24-site norm |
| D29 ENUM in DDL/migration | Yes | 6 owned-DDL ENUMs (SCH-EXM-001) | low volume |
| D30 FormRequest authorize()=true | **Yes** | 12/12 (SEC-EXM-008) | matches 90% norm |
| Layer 2.5 cross-DB/missing-FK (sys_roles/sys_dropdowns) | No (owned) | all 11 owned tables have migrations | clean |
| Layer 3.3 privilege fields in fillable | **No** | no is_super_admin/password/role_id in EXM models | clean |
| Layer 6.2 initialize() w/o end() | Borderline | dead `ReleaseScheduledExamResults` uses initialize()+end() (balanced) but is dead code | low risk |
| Layer 10.1 jobs w/o tenancy/retry | n/a | 0 jobs; schedule via `tenants:run` | clean |
| TEN-RTG-001 module-subscription middleware | **Yes (missing)** | no hasModule:EXM (SEC-EXM-011) | matches platform gap |
| Policy-overwrite (Gate::policy same model) | **Yes** | 13× Exam::class (SEC-EXM-009) | module-specific |

---

## vs Platform Baseline
- D30 12/12 — exactly the 90% platform norm; not an outlier, but the grievance instance escalates to P0.
- D25 0 sites, D24 single clean prefix, no privilege fillable, no committed secrets, no route closures — **EXM is cleaner than the platform norm** on mass-assignment, prefix hygiene, and deployment safety.
- God objects: LmsExamController 3767 lines remains a platform top-3 controller (after StudentController 4222).
- The policy-overwrite bug and the wrong-report-permission are module-specific defects not seen as a named platform pattern.

---

## Recommended Fix Order (unblock-the-most-first)
1. **SEC-EXM-005 (P0, deploy blocker)** — add Gate::authorize to all 5 GrievanceReviewController methods + tie GrievanceRequest::authorize() to the gate. *(act as Developer)*
2. **SEC-EXM-009 (P1)** — fix policy registration (one policy per model/ability; register Scope/Blueprint; fix Hw* imports) — this also unblocks correct enforcement of BR-EXM-010 and the report policies.
3. **SEC-EXM-010 (P1)** — per-report exam gates on ExamAdvancedReportController.
4. **SEC-EXM-011 (P1)** — add hasModule:EXM middleware (closes REQ-EXM-019).
5. **BUG-EXM-003 (P1)** — implement/remove group-member toggleStatus route (kills a 500).
6. **BUG-EXM-004 (P1)** — full result recompute (grade/division/rank) on grievance mark change. *(act as Developer; ideally extract ResultComputationService)*
7. **SEC-EXM-008 (P1)** — tie all 12 authorize() to gates (defense-in-depth). *(act as Developer)*
8. **DATA-EXM-001 / SCH-EXM-001 (P2)** — additive created_by migration; D29 ENUM decision. *(act as DB Architect)*
9. **DAT-EXM-002 (P2)** — coordinate StudentAttempt DDL-spec fix with its owner (no EXM code change).
10. **DEAD-EXM-003 / P3** — delete dead command + dup casts key.
11. **Tests** — Pest coverage for BR-003/004/005/014/019/023/027/032/035 + grievance auth + recompute. *(act as Testing Architect)*

---

### Issue Index (codes assigned this audit)
SEC-EXM-005 (P0, confirmed+extended), SEC-EXM-008 (P1, new — supersedes SEC-EXM-006 scope), SEC-EXM-009 (P1, new), SEC-EXM-010 (P1, new), SEC-EXM-011 (P1, new), BUG-EXM-003 (P1, confirmed still present), BUG-EXM-004 (P1, new), PERF-LMS-002 (P1, confirmed), DATA-EXM-001 (P2, new), SCH-EXM-001 (P2, new), DAT-EXM-002 (P2, new — StudentAttempt-owned), DEAD-EXM-003 (P2, new). SEC-EXM-007 (ExamQueryService scoping) **reassessed as non-issue** under database-per-tenant (connection-swapped; no tenant_id column to scope).

**Totals (de-duplicated):** P0 = 1 · P1 = 7 · P2 = 4 · P3 = 2. Health 40/100 (P0 cap). **DEPLOY: NO-GO.**
</content>
</invoke>
