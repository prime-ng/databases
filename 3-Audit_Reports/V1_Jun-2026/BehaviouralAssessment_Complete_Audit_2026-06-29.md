## Complete Audit — BehaviouralAssessment (BA / doc-code BHA) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** BehaviouralAssessment · **Code:** BA · **Live table prefix:** `ba_` (16 tables) · **Layer:** Tenant (database-per-tenant)
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/BehaviouralAssessment`
**Baseline (B/C):** `4-Requirement_Module_wise/0-FRD_Documents/BHA_FRD_Complete_2026-06-29.md` (18 REQ · 30 BR · 10 RPT · 4 ENH — IDs reused, never renumbered)
**Auditor:** Technical Auditor (AI_Brain) · read-only · evidence-based

> **Issue codes:** this report assigns new `*-BA-*` codes per the task. Where a prior partial audit already filed a `*-BEH-*` code in `lessons/known-issues.md`, the BA code references it (same defect, not double-counted).

---

### Executive Summary
The module is functionally broad (16 models/migrations, 12 controllers, 17 policies, 65 views, 1 score service) and — contrary to the prior `SEC-BEH-002` entry — its **web surface is correctly protected**: the module `RouteServiceProvider` applies the full `web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified` stack and **every controller method calls `Gate::authorize(...)` with a consistent `tenant.behavioural-assessment.*` prefix** (no D24 typos, no D25 `$request->all()`, no `initialize()` leaks). The worst findings are not security holes but **workflow / data-integrity gaps**: the ratings grid is editable after submit/approve and after a period is locked (the period-lock never cascades to assessments, and `bulkRate`/`autoSave` only block `status==='locked'` which no code ever sets), so finalised behavioural scores can silently diverge from the audit trail; and the **severe-incident parent notification (REQ-BA-015 / BR-BA-013, a P0 FRD requirement) is entirely absent** — there is no `Notification`, event, or `dispatch` anywhere in the module and `is_notified` is never set on create. **No hard P0** (no committed secret, no cross-tenant path, no migration blocker), so health is **not** capped. **Health: 57/100 (Amber). Deploy: GO (conditional)** — no technical blocker, but the safeguarding-notification gap and the lock-enforcement gap should be fixed before go-live for a CCE-compliance, result-contributing module.

### Audit Mode(s) Run
Mode X = A (12-layer) + B (FRD gap, 18 REQ) + C (BR enforcement, 30 BR) + G (deploy gate) + scoped D (systemic detectors for this module). One unified report.

### Health Score
Weighted index = **57 / 100 (Amber)**. No P0 → no 40-cap applied.
Layer scores: L6 Tenancy Green(15) · L5 Authz Amber(7) · L8 Data-Integrity Red(0) · L7 Validation Amber(5.5) · L12 Deploy Green(10) · L2 Mig↔Model↔DDL Amber(4.5) · L1 DDL Amber(3.5) · L9 Perf Amber(3.5) · L10 Queue/Job Amber(3) · L4 Code-Quality Amber(2) · L3 ORM Green(2) · L11 Frontend Amber(1).

### Deploy Gate Verdict — **GO (conditional)**
No NO-GO triggers: no committed secret in the module, no cross-tenant path (all FKs target tenant `ba_/sch_/std_` tables; no `sys_dropdowns`/`sys_roles` FK), no migration/deploy blocker, no route closures, no `env()` misuse, web routes fully gated. **Conditions before go-live:** fix the lock/read-only enforcement (BUG-BA-001), wire severe-incident parent notification (SEC-BA-001), and enforce active-scale lock (DATA-BA-001). The `auth:sanctum` API resource (DEAD-BA-001) and `export` 501 stub (BUG-BA-011) are dead/unfinished but harmless.

---

### P0 Findings
**None.** (Stated explicitly so the absence is on the record. The lock-enforcement defect was considered for P0 because it can silently corrupt published behavioural scores, but result-integration defaults OFF and the path is behind auth, so it is filed P1 with a P0-conditional note.)

---

### P1 Findings

```
[BUG-BA-001] Severity: P1 (P0 if result-integration enabled) | Ratings remain editable after submit/approve/lock — period lock never freezes assessments
- Location: app/Http/Controllers/BaAssessmentController.php:285 (bulkRate), :452 (autoSave)
            app/Models/BaAssessment.php:86-89 (isLocked)
            app/Http/Controllers/BaAssessmentPeriodController.php:147-161 (lock)
- Evidence:
    // bulkRate / autoSave guard is ONLY:
    if ($item->isLocked()) { return back()->with('error', 'This assessment is locked...'); }
    // isLocked():  return $this->status === 'locked';
    // ...but NO code path ever sets an assessment to 'locked'. period lock() sets the PERIOD
    //    status to 'locked' and does NOT cascade to ba_assessments.status.
- Why it's a risk: A teacher can keep editing ratings on a SUBMITTED or REVIEWED (approved) assessment,
    and on assessments whose PERIOD is closed/locked or whose deadline has passed — none of those states
    are checked. After approval the scores are cached (ba_computed_scores) but later raw edits are NOT
    recomputed, so the cached/published behavioural score silently diverges from the ratings and from the
    immutable audit trail. Violates BR-BA-026, BR-BA-012, BR-BA-019 and FSM-1/FSM-2.
- Fix: In bulkRate/autoSave/submit, reject when assessment.status != 'draft' OR period.status in
    ('closed','locked') OR now() > period.deadline. Make period lock() set all its reviewed assessments
    to 'locked' (cascade). Add an FSM guard helper (e.g. BaAssessment::isEditable()).
- Confidence: High
- Systemic? : module-local (FSM/lock-enforcement); parallels D-class state-machine gaps
```

```
[BUG-BA-002] Severity: P1 | Period lifecycle FSM violated — illegal transitions allowed, open→closed unreachable
- Location: app/Http/Controllers/BaAssessmentPeriodController.php:147-161 (lock), :163-177 (unlock)
- Evidence:
    public function lock(...)   { if ($item->status === 'locked') {return ...;} $item->update(['status'=>'locked']); }
    public function unlock(...) { if ($item->status !== 'locked') {return ...;} $item->update(['status'=>'closed']); }
    // No close() action anywhere; no route 'assessment-periods/{period}/close'.
- Why it's a risk: FRD FSM-2 (§15) requires open→closed→locked with locked TERMINAL. Code allows
    open→locked directly (skips closed) and locked→closed (reopen a terminal state). There is NO close()
    transition at all, so BR-BA-012 "closing a period blocks new assessments while drafts stay editable"
    is unreachable — a period can only ever be open or jump straight to locked. The FormRequest also lets
    `status` (open/closed/locked) be set directly on period edit, a back-door around the FSM.
- Fix: Add close() (open→closed) and reopen() (closed→open); restrict lock() to closed→locked; make
    locked terminal (remove unlock or gate it as an admin override with audit). Drop `status` from
    BaAssessmentPeriodRequest::rules() so lifecycle changes only via dedicated actions.
- Confidence: High
- Systemic? : module-local
```

```
[SEC-BA-001 / BUG-BA-003] Severity: P1 | Severe-incident parent notification (REQ-BA-015 / BR-BA-013, P0 requirement) entirely absent
- Location: app/Http/Controllers/BaIncidentController.php:74-133 (store) — and module-wide
- Evidence:
    grep -rn "Notification|notify|dispatch|event(" app/  →  ZERO hits (excluding the config
    'parent_notification_threshold' / 'is_notified' column names). store() never reads
    ba_config.parent_notification_threshold, never compares severity, never notifies, never sets is_notified.
- Why it's a risk: For a school safeguarding feature, a critical/major incident is supposed to alert the
    parent. Nothing fires — not even inline. ba_config.parent_notification_threshold is dead config;
    is_notified stays 0. Confirms ENH-BA-004 (EventServiceProvider.$listen = []) and RISK-BA-004.
- Fix: On incident create, if incident_type=='negative_incident' and severity >= config threshold, dispatch
    a queued notification via the Notification module and set is_notified. Prefer an IncidentCreated event +
    listener (ENH-BA-004) over inline so it also covers the API path.
- Confidence: High
- Systemic? : links ENH-BA-004 (events unwired)
```

```
[DATA-BA-001] Severity: P1 | BR-BA-029 not enforced — active rating scale can be switched mid-session after ratings exist
- Location: app/Http/Controllers/BaConfigController.php:65-74 (update); app/Http/Requests/BaConfigRequest.php:25-33
- Evidence:
    $config->update($request->validated() + ['updated_by' => auth()->id()]);
    // rating_scale_id is freely updatable; no check that any ba_assessment_ratings exist for the session.
- Why it's a risk: FRD BR-BA-029 / NFR-BA-010 / RISK-BA-006: changing the scale after ratings are recorded
    re-bases every numeric_value and inversion (max+1−raw), silently corrupting score interpretation for
    already-rated students.
- Fix: In update(), if any rating exists for the config's academic_session_id, reject changes to
    rating_scale_id (lock the dropdown in the view too).
- Confidence: High
- Systemic? : module-local (data-integrity)
```

```
[VAL-BA-001] Severity: P1 | Core write paths lack FormRequests (BaAssessment, BaIncident, BaClassCategory)
- Location: BaAssessmentController.php:55,289,456 (inline validate); BaIncidentController.php:52,159 (18+ rules duplicated verbatim across store/update); BaClassCategoryController.php:20
- Evidence:
    $request->validate([... 'severity' => ['nullable','required_if:incident_type,negative_incident',...] ...]);
    // identical 20-rule block copy-pasted in store() and update(); no BaIncidentRequest/BaAssessmentRequest/BaClassCategoryRequest.
- Why it's a risk: No shared validation contract for the highest-volume entry paths; rules drift between
    store/update; the incident immutability + severity-required logic lives in two places. (= VAL-BEH-001/002.)
- Fix: Extract BaAssessmentRequest, BaIncidentRequest, BaClassCategoryRequest (FRD §17 tasks 2-4).
- Confidence: High
- Systemic? : module-local (mirrors platform FormRequest sparseness)
```

```
[SEC-BA-002] Severity: P1 (systemic) | All 5 FormRequests authorize() return bare true (D30)
- Location: app/Http/Requests/{BaRatingScale,BaCategory,BaAssessmentPeriod,BaConfig,BaIntervention}Request.php:12-15
- Evidence:  public function authorize(): bool { return true; }
- Why it's a risk: D30 platform pattern (437/485). Here it is mitigated — every consuming controller action
    has its own Gate::authorize — so it is a defense-in-depth gap, NOT an open hole. (= SEC-BEH-001.)
- Fix: Return Gate::allows('tenant.behavioural-assessment.<entity>.<action>') matching the route; keep the
    controller gate too.
- Confidence: High
- Systemic? : D30
```

---

### P2 Findings

```
[BUG-BA-004] Severity: P2 | BR-BA-006 not enforced — a criterion with ratings can still be deleted
- Location: app/Http/Controllers/BaCategoryController.php:190-196 (destroyCriterion)
- Evidence: BaCriterion::where('category_id',$category)->findOrFail($criterion)->delete();  // no ratings check
- Why it's a risk: FRD says a criterion that already has ratings must be deactivated, not deleted. Soft-delete
    bypasses the DB RESTRICT FK, orphaning ratings from a deleted criterion.
- Fix: Block delete when BaAssessmentRating::where('criterion_id',$id)->exists(); deactivate instead.
- Confidence: High | Systemic?: module-local
```

```
[BUG-BA-005] Severity: P2 | BR-BA-030 not enforced — an intervention linked to incidents can still be deleted
- Location: app/Http/Controllers/BaInterventionController.php:69-81 (destroy)
- Evidence: soft-delete with no check against ba_incident_intervention_jnt.
- Fix: Block when BaIncidentInterventionJnt::where('intervention_id',$id)->exists(); deactivate instead.
- Confidence: High | Systemic?: module-local
```

```
[BUG-BA-006] Severity: P2 | BR-BA-005 — category soft-delete does not cascade to its criteria
- Location: app/Http/Controllers/BaCategoryController.php:74-86 (destroy)
- Evidence: soft-deletes the category only; the migration CASCADE is a hard-delete FK, not a soft-delete cascade.
- Why it's a risk: criteria of a "deleted" category remain active and surface in the ratings grid.
- Fix: In destroy(), soft-delete child criteria in the same transaction.
- Confidence: High | Systemic?: module-local
```

```
[BUG-BA-007] Severity: P2 | BR-BA-009 permissive default missing — a class with no mapping shows an EMPTY grid
- Location: app/Http/Controllers/BaAssessmentController.php:115-121 (show), :379-381 (reviewShow)
- Evidence: $categoryIds = BaClassCategoryJnt::where('class_id',$classId)->pluck('category_id');
           $criteria = BaCriterion::whereIn('category_id',$categoryIds)...  // empty mapping → whereIn([]) → no criteria
- Why it's a risk: FRD BR-BA-009 requires "no mapping ⇒ all active categories apply". Instead teachers of an
    unmapped class get a blank grid and cannot rate anyone.
- Fix: If the mapping is empty, fall back to all active categories.
- Confidence: High | Systemic?: module-local
```

```
[BUG-BA-008] Severity: P2 | Follow-up notes overwritten, not appended (REQ-BA-012 acceptance)
- Location: app/Http/Controllers/BaIncidentController.php:340-345 (followUp)
- Evidence: $incident->update(['follow_up_notes' => $validated['follow_up_notes'], ...]);  // replaces prior notes
- Why it's a risk: FRD requires follow-up notes be appended (each addition timestamped). History is lost.
- Fix: Append (concatenate with a timestamp header) instead of overwrite.
- Confidence: High | Systemic?: module-local
```

```
[BUG-BA-009] Severity: P2 | BR-BA-028 not enforced — multiple rating scales can be is_default=true
- Location: app/Http/Controllers/BaRatingScaleController.php:31-45 (store), 60-64 (update)
- Evidence: $ratingScale->update($request->validated()+...);  // is_default saved as-is; no logic unsets other defaults
- Why it's a risk: BehaviouralScoreService:49 falls back to BaRatingScale::where('is_default',true)->first() —
    ambiguous if several are default. FRD BR-BA-028: exactly one default at a time.
- Fix: In a transaction, when setting is_default=true, set all other scales is_default=false.
- Confidence: Medium-High | Systemic?: module-local
```

```
[VAL-BA-002] Severity: P2 | BR-BA-003 level value not range-checked; duplicate student witness 500s
- Location: BaRatingScaleController.php:132-150 (storeLevel) — 'numeric_value' => ['required','numeric'] only;
            BaIncidentController.php:68-69,107-116 (store) — witness_student_ids.* has no 'distinct' and uses
            BaIncidentWitnessJnt::create() (not firstOrCreate, unlike the staff branch).
- Why it's a risk: a level value outside the scale's [min,max] is accepted (BR-BA-003). A student selected
    twice as witness hits the uq_ba_witness unique index → unhandled QueryException (500) instead of a clean
    reject (BR-BA-027). Inconsistent with the staff branch which uses firstOrCreate.
- Fix: validate numeric_value between scale.min_rating and max_rating; add 'distinct' + use firstOrCreate for
    student witnesses.
- Confidence: High | Systemic?: module-local
```

```
[DATA-BA-002] Severity: P2 | Behavioural score recompute is synchronous in-request (timeout risk)
- Location: app/Http/Controllers/BaAssessmentController.php:413 (approve → computeForPeriod);
            app/Services/BehaviouralScoreService.php:24-76
- Evidence: $scoreService->computeForPeriod($item->period_id, $item->class_section_id);  // runs in the approve request
- Why it's a risk: FRD NFR-BA-003 / RISK-BA-003 / ENH-BA-003: a class-section recompute is bounded, but there is
    no queued ComputeSchoolScoresJob and no manual school-wide recompute path; large recompute would block the request.
- Fix: Build a queued ComputeSchoolScoresJob (with $tenant->id + tenancy re-init, $tries/$backoff/$timeout) and
    dispatch from approve(); keep synchronous only for single class-section.
- Confidence: High | Systemic?: links ENH-BA-003; Layer 10 (no Jobs/ dir)
```

```
[DATA-BA-003] Severity: P2 | Soft-delete + UNIQUE without deleted_at → recreate-after-delete throws 500
- Location: migrations create_ba_assessments(uq_ba_assessment), create_ba_assessment_ratings(uq_ba_rating),
            create_ba_computed_scores(uq_ba_score), create_ba_incident_witnesses_jnt(uq_ba_witness)
- Evidence: $table->unique(['teacher_id','class_section_id','period_id'],'uq_ba_assessment'); // no deleted_at
           BaAssessment::firstOrCreate(...) ignores trashed rows → INSERT → duplicate-key on the still-present soft-deleted row.
- Why it's a risk: after soft-deleting an assessment/score, re-creating the same combo hits the live unique index
    (the trashed row is physically present) → SQLSTATE 23000.
- Fix: include deleted_at in the unique index (or a generated active-key column), or restore-instead-of-create.
- Confidence: Medium-High | Systemic?: Layer 8.4 platform pattern
```

```
[DATA-BA-004] Severity: P2 | Incident create not wrapped in a transaction
- Location: app/Http/Controllers/BaIncidentController.php:74-129 (store)
- Evidence: BaIncident::create() then loops of BaIncidentInterventionJnt / BaIncidentWitnessJnt::create() then 4× BaAuditLog::log() — no DB::transaction.
- Why it's a risk: a mid-loop failure (e.g. the duplicate-witness 500 in VAL-BA-002) leaves a partial incident +
    partial witnesses/interventions + partial audit rows.
- Fix: wrap store() (and update()) in DB::transaction().
- Confidence: High | Systemic?: module-local
```

```
[MIG-BA-001] Severity: P2 (systemic D29) | 11 ENUM columns in tenant migrations
- Location: create_ba_{assessment_periods:20, interventions:18, config:18-19, assessments:16, categories:18, audit_log:16, incident_witnesses_jnt:16, incidents:18-21} migrations
- Evidence: $table->enum('location',['canteen','classroom','corridor','lab','library','other','playground','transport'])...
- Why it's a risk: D29 — open/semi-open value sets should be sys_dropdown_table FKs. DDL doc and migration AGREE
    (both ENUM), so no DDL↔migration divergence. FSM enums (status, polarity, witness_type, entity_type) are
    code-gated and defensible; `location` and `severity` are the realistic dropdown candidates.
- Fix: migrate location/severity to sys_dropdown_table FKs at next schema rev; leave FSM enums.
- Confidence: High | Systemic?: D29
```

```
[DEAD-BA-001] Severity: P2 | API resource controller is an empty scaffold behind a live sanctum route with NO tenancy middleware
- Location: app/Http/Controllers/BehaviouralAssessmentController.php:29,50,55 (empty store/update/destroy);
            :13,21,34,42 (index/create/show/edit return behaviouralassessment::{index,create,show,edit} — only index.blade.php exists);
            routes/api.php:6-8 (Route::middleware(['auth:sanctum'])->apiResource(...), no InitializeTenancyByDomain)
- Evidence: public function store(Request $request) {}   // silently accepts and discards writes
- Why it's a risk: live API silently no-ops on write; create/show/edit point at non-existent views (500); the
    route has no tenancy bootstrapper (latent cross-context if a body were added). (= BUG-BEH-001 / DEAD-BEH-001.)
- Fix: delete the scaffold controller + api.php resource, or implement with tenancy middleware + real bodies.
- Confidence: High | Systemic?: module-local
```

```
[BUG-BA-011] Severity: P2 | Report export is a permanent abort(501) stub on a live route
- Location: app/Http/Controllers/BaReportController.php:475-479 (export)
- Evidence: public function export(): never { Gate::authorize(...); abort(501, 'Export feature coming soon.'); }
- Why it's a risk: GET /reports/export is routed; authorized users get HTTP 501. CSV/Excel export promised by
    RPT-BA-001..009 / NFR-BA-011 is unimplemented. (= BUG-BEH-002.)
- Fix: implement streamed export or remove the route until built.
- Confidence: High | Systemic?: module-local
```

```
[PERF-BA-001..004] Severity: P2 | Known N+1 / redundant-query hotspots (re-confirmed)
- BaIncidentController.php:316-322 (show) — per-witness Student::find()/Employee::with('user')->find() (= PERF-BEH-001)
- BaDashboardController.php (rating map) — eager-loads criterion but not criterion.category (= PERF-BEH-002)
- BaAssessmentController.php:296-317 (bulkRate) — updateOrCreate per cell, N×M queries (= PERF-BEH-003)
- BaDashboardController.php (assessmentsPage) — allPeriods + openPeriods two queries on one table (= PERF-BEH-004)
- Fix: eager-load witnesses' subjects in bulk; add ->with('criterion.category'); batch upsert(); partition periods in PHP.
- Confidence: High (per prior audit) | Systemic?: Layer 9
```

---

### P3 Findings
- **[VAL-BA-003]** BR-BA-010 boundary: period uses `end_date >= start_date` (`after_or_equal`) but FRD says start **<** end — start==end is wrongly accepted. `BaAssessmentPeriodRequest.php:23`.
- **[BUG-BA-012]** `BaCategoryController::reorder()` runs one UPDATE per item in a loop (`:138-140`) — batch it.
- **[SEC-BA-003]** `status` (open/closed/locked) is accepted in `BaAssessmentPeriodRequest::rules()` — an admin can set period status directly via edit, bypassing the lock/unlock FSM actions. Drop it from the request.
- **[DOC-BA-001]** DDL doc `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` still uses the stale `bha_` prefix vs the live `ba_` (16 migrations + 16 models). Structures match column-for-column; only the prefix differs. Regenerate/retire the doc (RISK-BA-001 / NFR-BA-012). **Confirms the task's flagged divergence: code wins, prefix is `ba_`.**

---

### Layer Health Summary
| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema Integrity | 🟡 Amber | 11 ENUMs (D29); otherwise conventional, no GENERATED cols (D36 N/A) |
| 2 | Migration↔Model↔DDL | 🟡 Amber | live `ba_` consistent; DDL doc stale `bha_` (DOC-BA-001); soft-delete unique gap (DATA-BA-003) |
| 3 | Model & ORM | 🟢 Green | casts present (is_*→bool, *_at→datetime, attachments_json→array), relations sound; audit `$timestamps=false` |
| 4 | Code Quality | 🟡 Amber | scaffold API stub (DEAD-BA-001), export 501 (BUG-BA-011); controllers <500 lines |
| 5 | Authorization | 🟡 Amber | every method Gate::authorize, consistent prefix, 17 policies registered; but D30 (SEC-BA-002) |
| 6 | Multi-Tenancy | 🟢 Green | RSP full tenancy+auth+verified stack; no `$request->all()`, no initialize() leak; api.php stub lacks tenancy (dead) |
| 7 | Validation/Mass-assign | 🟡 Amber | missing FormRequests (VAL-BA-001); level range + witness distinct (VAL-BA-002) |
| 8 | Data Integrity/Tx | 🔴 Red | lock not enforced (BUG-BA-001), scale-lock missing (DATA-BA-001), no incident tx (DATA-BA-004) |
| 9 | Performance | 🟡 Amber | N+1s (PERF-BA-001..004), synchronous recompute (DATA-BA-002) |
| 10 | Queue/Job | 🟡 Amber | 0 jobs; recompute should be queued (ENH-BA-003) |
| 11 | Frontend/Blade | 🟡 Amber | not deep-audited; chart/output safety to verify |
| 12 | Deployment | 🟢 Green | no secrets, no route closures, no env() misuse in module |

---

### FRD Gap Summary (Mode B) — REQ coverage vs FRD
| REQ | Feature | DDL | Code | Test | Gap |
|-----|---------|-----|------|------|-----|
| REQ-BA-001 | Rating Scale & Levels | ✅ | ✅ | ❌ | BR-BA-028 one-default not enforced (BUG-BA-009); level range not validated (VAL-BA-002) |
| REQ-BA-002 | Categories & Criteria | ✅ | ✅ | ❌ | criterion-delete guard (BUG-BA-004); category soft-delete cascade (BUG-BA-006) |
| REQ-BA-003 | Interventions master | ✅ | ✅ | ❌ | in-use delete guard (BUG-BA-005) |
| REQ-BA-004 | Class–Category mapping | ✅ | ✅ | ❌ | no FormRequest (VAL-BA-001); permissive default missing (BUG-BA-007) |
| REQ-BA-005 | Assessment Periods | ✅ | ⚠️ | ❌ | FSM broken: no close(), illegal lock/unlock (BUG-BA-002) |
| REQ-BA-006 | Module Configuration | ✅ | ⚠️ | ❌ | scale-lock BR-BA-029 missing (DATA-BA-001); auto-create-on-first-access not verified |
| REQ-BA-007 | My Assessments hub | ✅ | ✅ | ❌ | teacher-scope relies on Employee lookup; OK |
| REQ-BA-008 | Ratings grid entry | ✅ | ⚠️ | ❌ | read-only/lock not enforced (BUG-BA-001); no FormRequest (VAL-BA-001) |
| REQ-BA-009 | Student Remarks | ✅ | ✅ | ❌ | read-only-after-submit not enforced (rides BUG-BA-001) |
| REQ-BA-010 | Review/Approve/Lock | ✅ | ⚠️ | ❌ | submit/approve/send-back present; assessment never reaches 'locked' (BUG-BA-001); auto-publish-when-workflow-disabled (BR-BA-025) NOT implemented |
| REQ-BA-011 | Score computation | n/a | ✅ | ❌ | synchronous (DATA-BA-002); formula correct (inversion + weighted avg verified) |
| REQ-BA-012 | Incident logging | ✅ | ⚠️ | ❌ | immutability ENFORCED; follow-up overwrite bug (BUG-BA-008); no tx (DATA-BA-004); no FormRequest |
| REQ-BA-013 | Incident witnesses | ✅ | ⚠️ | ❌ | duplicate-student 500 (VAL-BA-002) |
| REQ-BA-014 | Interventions applied | ✅ | ✅ | ❌ | add/remove present |
| REQ-BA-015 | Severe-incident notification | n/a | ❌ | ❌ | **NOT IMPLEMENTED (SEC-BA-001)** |
| REQ-BA-016 | Result integration (pull) | ✅ | ✅ | ❌ | getBulkScores present + gated; consumer untested |
| REQ-BA-017 | Immutable audit trail | ✅ | ✅ | ❌ | inline writes via BaAuditLog::log; immutable ($timestamps=false, no delete path); no Observer (coverage depends on controllers calling log) |
| REQ-BA-018 | Dashboard & analytics | n/a | ✅ | ❌ | N+1s (PERF-BA-002/004) |

**Tests: 0 across all 18 REQ** (`tests/` only `.gitkeep`) — RISK-BA-002.

---

### Business-Rule Enforcement (Mode C)
| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| BR-BA-001 inversion | Calc | BehaviouralScoreService:101-103 | ✅ ENFORCED | (max+1)−raw verified |
| BR-BA-002 min<max | Valid | BaRatingScaleRequest:27 `gt:min_rating` | ✅ ENFORCED | |
| BR-BA-003 level in range / unique pos | Valid | storeLevel:137 | ⚠️ PARTIAL | range NOT checked (VAL-BA-002); pos uniqueness DB-only |
| BR-BA-004 category polarity required | Valid | BaCategoryRequest:25 | ✅ ENFORCED | |
| BR-BA-005 category delete cascades criteria | WF | BaCategoryController:74 | ❌ MISSING | BUG-BA-006 |
| BR-BA-006 criterion-with-ratings no delete | WF | destroyCriterion:190 | ❌ MISSING | BUG-BA-004 |
| BR-BA-007 intervention valid type | Valid | BaInterventionRequest | ✅ ENFORCED | |
| BR-BA-008 class-category unique | Valid | BaClassCategoryController:26 | ✅ ENFORCED | |
| BR-BA-009 permissive default | WF | BaAssessmentController:115 | ❌ MISSING | BUG-BA-007 |
| BR-BA-010 start<end; deadline≥end | Valid | BaAssessmentPeriodRequest:22-23 | ⚠️ PARTIAL | allows start==end (VAL-BA-003) |
| BR-BA-011 period belongs to session | Valid | BaAssessmentPeriodRequest:20 | ✅ ENFORCED | |
| BR-BA-012 close blocks new / lock blocks all | WF | period lock/unlock | ❌ MISSING | BUG-BA-002 (no close); BUG-BA-001 (lock not enforced) |
| BR-BA-013 severe-incident notify | WF/Notif | — | ❌ MISSING | SEC-BA-001 |
| BR-BA-014 integration gate | WF | BehaviouralScoreService:45 / getBulkScores | ✅ ENFORCED | |
| BR-BA-015 weightage 5–20 | Valid | BaConfigRequest:30 `min:5 max:20` | ✅ ENFORCED | |
| BR-BA-016 one config/session | Valid | BaConfigRequest:25-29 Rule::unique | ✅ ENFORCED | |
| BR-BA-017 teacher sees only own | Perm | policies + Employee lookup | ⚠️ PARTIAL | scope via Employee::where(user_id); verify policy denies cross-teacher (no per-row ownership check seen in bulkRate) |
| BR-BA-018 one assessment/teacher×class×period | Valid/Conc | uq_ba_assessment + firstOrCreate | ✅ ENFORCED | (soft-delete edge: DATA-BA-003) |
| BR-BA-019 one rating/student/criterion; overwrite | Valid | updateOrCreate uq_ba_rating | ✅ ENFORCED | |
| BR-BA-020 unrated allowed in draft | Valid | rating_level_id nullable | ✅ ENFORCED | |
| BR-BA-021 multi-teacher average | Calc | BehaviouralScoreService:93-108 | ✅ ENFORCED | groupBy criterion, ->average() |
| BR-BA-022 one remark/student/assessment | Valid | updateOrCreate uq | ✅ ENFORCED | read-only-after-submit not enforced (BUG-BA-001) |
| BR-BA-023 submit/approve/send-back transitions | WF | BaAssessmentController:339,399,425 | ✅ ENFORCED | status guards present; send-back requires remarks? remarks NOT validated as required (minor) |
| BR-BA-024 every change → audit | WF | BaAuditLog::log inline | ⚠️ PARTIAL | covered for status/rating/incident edits via controllers; no Observer → any non-controller write is unaudited |
| BR-BA-025 auto-publish when workflow disabled | WF | — | ❌ MISSING | no config flag/branch; submit always → submitted |
| BR-BA-026 read-only when submitted/locked/past-deadline | WF/Conc | bulkRate/autoSave:285,452 | ❌ MISSING | BUG-BA-001 |
| BR-BA-027 witness unique + real ref | Valid | uq_ba_witness; exists: rules | ⚠️ PARTIAL | unique via DB but store() can 500 on dup student (VAL-BA-002) |
| BR-BA-028 one default scale | Valid | BaRatingScaleController | ❌ MISSING | BUG-BA-009 |
| BR-BA-029 scale immutable after ratings | WF | BaConfigController:65 | ❌ MISSING | DATA-BA-001 |
| BR-BA-030 in-use intervention no delete | WF | BaInterventionController:69 | ❌ MISSING | BUG-BA-005 |

**Tally:** 30 BR → **15 ENFORCED · 6 PARTIAL · 9 MISSING.** Incident immutability (INC-2) ENFORCED (BaIncidentController.php:181-195); INC-1 severity-required ENFORCED (`required_if`).

---

### Systemic-Pattern Scorecard (Mode D, scoped to BA)
| Pattern | Present? | Count / Evidence | vs baseline |
|---------|----------|------------------|-------------|
| D17 fillable vs columns | No | models reconcile with migrations; no phantom column found | better than norm (66 models affected) |
| D24 permission-prefix chaos/typos | No | uniform `tenant.behavioural-assessment.*`; no `tennat.`/dupes | clean |
| D25 `$request->all()` into models | No | uses validated()/explicit arrays everywhere | better (24 sites elsewhere) |
| D29 ENUM in migrations | **Yes** | 11 columns (MIG-BA-001) | typical |
| D30 FormRequest authorize() true | **Yes** | 5/5 (SEC-BA-002) | typical (90% norm) |
| D36 GENERATED→plain | No (N/A) | DDL has zero GENERATED columns | not applicable |
| Layer 2.5 cross-DB/missing FK | No | all FKs → tenant ba_/sch_/std_; no sys_dropdowns/sys_roles FK | clean |
| Layer 6.2 initialize() leak | No | none in module | clean |
| Layer 10.1 job tenancy/retry | N/A | 0 jobs (gap: recompute should be a tenancy-aware job) | — |
| TEN-RTG-001 subscription/tenancy middleware | No (web) | RSP has EnsureTenantIsActive + full stack; api.php stub lacks it | web clean |

---

### vs Platform Baseline
BA is **above average on the high-blast-radius layers** (tenancy, mass-assignment, permission taxonomy — all clean, unlike the platform norms) and **typical on the systemic FormRequest/ENUM patterns**. Its distinctive weakness is **workflow/data-integrity** (FSM + lock enforcement + missing notification), not security. The prior `SEC-BEH-002` ("no auth middleware on web routes") is a **false positive** — auth/tenancy live in the module `RouteServiceProvider`, not `web.php`; corrected here.

### Recommended Fix Order
1. **BUG-BA-001** — enforce read-only on submitted/reviewed/locked/past-deadline and cascade period-lock to assessments (protects published scores + audit integrity). *(P1, P0-if-integration-on)*
2. **SEC-BA-001** — wire severe-incident parent notification (safeguarding, REQ-BA-015). *(P1)*
3. **DATA-BA-001** — lock active scale once ratings exist (BR-BA-029). *(P1)*
4. **BUG-BA-002** — fix period FSM (add close(), restrict lock(), make locked terminal). *(P1)*
5. **VAL-BA-001** — add BaAssessmentRequest / BaIncidentRequest / BaClassCategoryRequest; **SEC-BA-002** make authorize() gate. *(P1)*
6. P2 batch: BUG-BA-004/005/006/007/008/009, VAL-BA-002, DATA-BA-002/003/004, DEAD-BA-001, BUG-BA-011.
7. **Tests** — 0 today; cover inversion, weighted-avg, FSM, immutability, lock-enforcement (RISK-BA-002).
8. DB Architect: regenerate DDL doc to `ba_` (DOC-BA-001); migrate location/severity ENUMs to dropdowns (MIG-BA-001).

---

### Next Steps
Audit complete — Health **57/100 (Amber)**, Deploy **GO (conditional)**, no P0.
1. Fix P1 issues → `act as Developer` (start BUG-BA-001, SEC-BA-001, DATA-BA-001, BUG-BA-002).
2. Regenerate DDL doc to `ba_` + dropdown migration → `act as DB Architect`.
3. Completeness score → `act as Status_Analyzer`.
4. Test coverage (0 today) → `act as Testing Architect`.
