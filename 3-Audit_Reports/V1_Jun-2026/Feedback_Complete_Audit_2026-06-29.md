## Complete Audit — Feedback (FBK) — 2026-06-29      (Mode X: A+B+C+G + scoped D)

**Module:** Feedback | **Code:** FBK | **Prefix:** `fbk_` | **Layer:** Tenant (per-school)
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/Feedback`
**Baseline FRD:** `4-Requirement_Module_wise/0-FRD_Documents/FBK_FRD_Complete_2026-06-29.md` (REQ/BR/RPT IDs reused, never renumbered)
**Auditor:** Technical Auditor (read-only) | **Mode:** X (Complete)

---

### Executive Summary

The Feedback module is **structurally sound and tenant-safe** (full tenancy stack on every route, ENUM-free v3 schema, correctly-emitted `GENERATED` dedup columns + unique indexes — better than the platform D36 norm), but it is **functionally non-operational for end users today** because of three independent P1 defects: (1) the core **eligibility/target-population engine reads a non-existent attribute** (`$relationship->context_required` vs the real `context_required_id`) so every submission is blocked and auto-population yields zero targets; (2) the **`tenant.feedback.*` permission is never seeded**, so the entire admin surface is reachable only by super-admins (Gate::before bypass) — intended roles get 403; and (3) **reverse-scoring (BR-013) is silently ignored** in rating computation. The worst finding overall is the combination of these — the spine "configure → populate → submit → score" does not produce correct results. **No P0** (no exploitable security hole, no cross-tenant leak, no deploy-blocker introduced by this module), so health is **not capped**: **Health 54/100 (Amber)**. **Deploy: GO (platform-safety) / NO-GO (feature-readiness).**

> **Important reconciliation:** the live controllers were updated **2026-06-27 19:12**, *after* the prior Phase-2 audit (2026-06-21). Two of that audit's P0s are now **REMEDIATED** in live code: SEC-FBK-001 (all 9 admin controllers now carry `can:tenant.feedback.viewAny`) and SEC-FBK-002 / DEAD-FBK-001 (eligibility service is now actually called in `submit()`/`saveDraft()`). The residual authorization risk has shifted to *unseeded permissions* and *coarse-grained gating* (new codes below). Module-knowledge "0 tests" is also corrected: **9 Browser test files exist** (`tests/Browser/Modules/Feedback/*`, ~6,230 LOC); Pest unit/feature dirs hold only `.gitkeep`.

---

### Health Score

| | |
|---|---|
| Weighted index | **54 / 100** |
| P0 cap applied? | No (0 P0) |
| Band | **Amber** |

Layer weights × score (Green 1.0 / Amber 0.5 / Red 0.0): Tenancy 15×1.0; Authz 14×0.0; DataInt 13×0.5; Validation 11×0.5; Deploy 10×0.5; Mig↔Model↔DDL 9×0.5; DDL 7×1.0; Perf 7×0.5; Queue/Job 6×0.5; CodeQual 4×0.5; ORM 2×0.5; Frontend 2×0.5 = **54**.

---

### Deploy Gate Verdict (Mode G)

**GO for platform safety / NO-GO for feature readiness.**

- **No module-owned P0:** no committed secret, no cross-tenant path, no route closure, no `env()` outside config, no `tenancy()->initialize()` leak, no job-tenancy gap (module has zero jobs). RouteServiceProvider applies the full stack (`InitializeTenancyByDomain` → `PreventAccessFromCentralDomains` → `EnsureTenantIsActive` → `auth` → `verified`) to both web and admin route groups.
- **Blocking for release (P1 functional):**
  1. **SEC-FBK-004** — `tenant.feedback.*` / `tenant.consent-forms.*` permissions unseeded → module usable only by super-admin.
  2. **BUG-FBK-003** — eligibility + auto-population broken → no end-user can submit; no targets created.
  3. **BUG-FBK-004** — reverse-scored questions corrupt aggregate ratings.
- **Platform-wide P0s that gate the whole app (NOT Feedback-owned, do not re-register):** queue(`database`)↔Horizon(`redis`) mismatch (DEPLOY-HRZ-01), committed `.env-original` APP_KEY (DEPLOY-ENV-02), seeder routes outside auth (SEC-RTG-001). These still block deployment platform-wide.
- **Latent module trap:** `routes/api.php` imports `FbkSummaryController` (class does not exist). It is dead today (BUG-FBK-001), but registering it later throws a fatal class-not-found (BUG-FBK-002).

---

### P0 Findings

**None.** No exploitable security hole, data-loss/corruption path, cross-tenant leak, or module-owned deploy blocker was found.

---

### P1 Findings

```
[BUG-FBK-003] Severity: P1 | Eligibility & target auto-population read a non-existent attribute → spine broken
- Location: Modules/Feedback/app/Services/FbkEligibilityService.php:82, :102
- Evidence:
    return match ($relationship->context_required) {   // line 82
        'None' => true, 'Class_Section' => ..., default => false,
    };
    // resolveEligibleTargets, line 102:
    return match ($relationship->context_required) { 'Class_Section', ... default => [] };
  FbkRelationshipType has NO `context_required` attribute — the column/fillable is `context_required_id`
  (FbkRelationshipType.php:25) with relation contextRequired() (:46), and the migration column is
  `context_required_id` (2026_04_09_100002_create_fbk_relationship_types_table.php:19).
- Why it's a risk: `$relationship->context_required` resolves to NULL → match() always hits `default`.
  isEligible() returns false → FbkResponseController::submit()/saveDraft() abort 403 for every respondent.
  resolveEligibleTargets() returns [] → populateTargets() creates 0 cycle targets. REQ-008/009/010 do not work.
  Root cause: the service was written against the v2 string-ENUM schema; the shipped schema is v3 dropdown-FK.
- Fix: resolve the dropdown value first — `$relationship->contextRequired?->value` (eager-load it), or add a
  `getContextRequiredAttribute()` accessor that returns `$this->contextRequired?->value`. Apply the same to any
  string compare against `linked_entity_table` (the resolveTableKey() fallback already covers that one).
- Confidence: High
- Systemic?: Local v2→v3 drift (sibling of D29). Three-way reconcile (DDL v3 ↔ migration ↔ model) all agree on
  `context_required_id`; only the service diverges.
```
```
[SEC-FBK-004] Severity: P1 | tenant.feedback.* / tenant.consent-forms.* permissions are never seeded
- Location: every Fbk admin controller constructor, e.g. FbkCycleController.php:21, FbkMenuController.php:29,
    FbkTemplateController.php:22, FbkCategoryController.php:19, FbkTargetTypeController.php:19,
    FbkRelationshipTypeController.php:21, FbkCycleFeedbackTypeController.php:23, FbkDashboardController.php:19;
    ConsentFormController.php:21,50,59,78,87,97,129,148,157,176,214,238
- Evidence:
    $this->middleware('can:tenant.feedback.viewAny');     // gate string
  grep for the permission row in database/seeders/TenantRolePermissionSeeder.php,
  Modules/Prime/database/seeders/RolePermissionSeeder.php, and all Modules/*/database/seeders → 0 definitions.
  AppServiceProvider.php:65-67 has `Gate::before(... if ($user->is_super_admin && $user->super_admin_flag) return true)`.
- Why it's a risk: with the permission undefined, `can:tenant.feedback.viewAny` denies everyone EXCEPT super-admins
  (via Gate::before). Admin/Principal/Teacher/Staff — the intended actors (FRD §2) — receive 403 on the whole module.
  Matches RISK-FBK-003 / FRD Q4. Same pattern as SEC-DSH-009 (Dashboard, 2026-06-29).
- Fix: add a Feedback permission seeder (or rows in TenantRolePermissionSeeder) defining the
  `tenant.feedback.*` and `tenant.consent-forms.*` abilities and mapping them to Admin/Principal/Communication roles.
- Confidence: High
- Systemic?: Cross-module "permission referenced, never seeded" pattern (see decisions append).
```
```
[SEC-FBK-005] Severity: P1 | Child-safety peer/NEP anonymity is NOT locked at configuration
- Location: FbkRelationshipTypeController.php:37-57,59-79 (store/update); FbkCycleFeedbackTypeController.php:66-109,114-153
- Evidence:
    // FbkAnonymityService::enforceAnonymityRules() exists (FbkAnonymityService.php:77) and would force
    // is_anonymous_to_target=true for peer relationships — but it is NEVER called anywhere.
    // Relationship store/update persist default_anonymous_to_target / is_peer_relationship straight from request.
- Why it's a risk: BR-FBK-007/008 require peer & NEP-2020-peer feedback to be permanently anonymous regardless of
  admin settings. An admin can save a peer relationship/flow with anonymity OFF. The only hardcoded protection
  (FbkAnonymityService::canTargetSeeRespondentIdentity) is also never invoked (see DEAD-FBK-002), so if a target-facing
  summary view is added the minor-protection guarantee is absent. RISK-FBK-001.
- Mitigant (why P1 not P0): FbkCycleFeedbackTypeController defaults is_anonymous_to_target=true
  (store :87, update :133) and there is currently NO target-facing read path, so no live de-anonymisation exists yet.
- Fix: call $anonymityService->enforceAnonymityRules($cft) on CFT create/update, and force
  default_anonymous_to_target=true when is_peer_relationship||nep_2020_mandated on relationship-type save.
- Confidence: High
- Systemic?: Module-local (child-safety).
```
```
[BUG-FBK-004] Severity: P1 | Reverse scoring (BR-FBK-013) is never applied to ratings
- Location: FbkResponseService.php:166-190 (computeOverallRating); FbkAnswer.php:60-67 (getNumericValue); :15-27 (fillable)
- Evidence:
    $weightedSum = $answers->sum(fn ($a) => ($a->getNumericValue() ?? 0) * (float) $a->weight_snapshot);
  getNumericValue() returns the raw rating_value; there is no inversion. FbkAnswer does NOT snapshot
  `is_reverse_scored` (syncAnswers, FbkResponseService.php:136-150, snapshots only question_type/category/weight).
- Why it's a risk: BR-013 requires reverse-scored answers to be inverted (scale_max+1 − raw) before aggregation.
  A "Teacher was rude (1=never)" item is counted as-is → overall_rating and every summary average are wrong.
- Fix: snapshot is_reverse_scored + scale_max onto the answer at submit; in getNumericValue()/computeOverallRating
  invert reverse-scored numeric answers using the template's rating_scale_max before weighting.
- Confidence: High
- Systemic?: Module-local calculation defect.
```
```
[SEC-FBK-003] Severity: P1 | Coarse-grained authorization — one view permission gates all mutations
- Location: FbkCycleController.php:21, FbkTemplateController.php:22, FbkCycleFeedbackTypeController.php:23,
    FbkCategoryController.php:19, FbkTargetTypeController.php:19, FbkRelationshipTypeController.php:21, FbkMenuController.php:29
- Evidence:
    $this->middleware('can:tenant.feedback.viewAny');   // applied to the WHOLE controller
  This single ability guards index/show AND store/update/destroy/activate/close/publish/cancel/forceDelete.
- Why it's a risk: any role granted read access to Feedback can also create/activate/publish/destroy cycles and
  permanently delete templates/setup masters. No separation of view vs manage vs publish (FRD §2.2 matrix expects
  publish to be Admin-only, withdraw respondent-only, etc.). 0 dedicated Fbk* Policy classes exist.
- Fix: replace blanket viewAny with per-action abilities (feedback.cycle.create/publish/delete, …) or dedicated
  Policies registered in FeedbackServiceProvider::registerPolicies() (currently only maps ParentPortal\ConsentForm).
- Confidence: High
- Systemic?: D24-adjacent (permission taxonomy). Module-local.
```
```
[VAL-FBK-001] Severity: P1 | Unvalidated answer payload mass-assigned into fbk_answers  (CONFIRMED, still open)
- Location: FbkResponseController.php:77,94 (answers from request) → FbkResponseService.php:136-150 (syncAnswers)
- Evidence:
    $answers = $request->input('answers', []);
    $response->answers()->updateOrCreate(['question_id'=>$questionId],
        array_merge($payload, [...snapshots...]));   // $payload is raw user input
- Why it's a risk: no validation of answer structure, question ownership (a question_id from another template),
  rating bounds (rating_value can exceed scale_max, or be negative), or option codes. Raw array merged into the
  FbkAnswer fillable (D25-style mass assignment) — corrupts aggregates and bypasses required-question rules.
- Fix: validate `answers` as a keyed array (exists:fbk_questions,id scoped to the template; numeric rating within
  1..scale_max; option in template options). Enforce "all required answered" before submit.
- Confidence: High
- Systemic?: D25 family.
```

---

### P2 Findings

```
[BUG-FBK-001] P2 | routes/api.php is never registered — RouteServiceProvider::map() calls only mapWebRoutes()+
  mapAdminWebRoutes() (RouteServiceProvider.php:20-24). All /v1 endpoints 404. (CONFIRMED still.) Feature-missing, not harmful.
[BUG-FBK-002] P2 (latent) | api.php imports Modules\Feedback\Http\Controllers\FbkSummaryController (routes/api.php:7) —
  class file does not exist. Registering api.php later → fatal class-not-found. Remove/replace before wiring the API.
[PERF-FBK-001] P2 | N+1 in FbkSummaryService::batchRecomputeForCycle() (FbkSummaryService.php:61-70) — one
  FbkResponse query per CFT inside the loop. (CONFIRMED.) Eager-load responses grouped by cft, or chunk once.
[DEAD-FBK-002] P2 | FbkAnonymityService injected into FbkResponseController (:24) but NEVER invoked; the entire
  anonymity/k-anonymity layer (canTargetSeeRespondentIdentity/canTargetViewSummary/stripRespondentIdentity/
  enforceAnonymityRules) is dead code — no read path calls it. Means BR-008/009/010 are unenforced if a
  target-facing summary screen is added. Cross-ref SEC-FBK-005. (Note: replaces stale DEAD-FBK-001, which is now RESOLVED.)
[BUG-FBK-005] P2 | A Submitted response can be silently overwritten — FbkResponseService::submit() (:71) uses
  updateOrCreate on the natural key with no guard that the existing row is not already 'Submitted'. A repeat POST
  re-writes answers + overall_rating, violating BR-FBK-016 ("Submitted cannot be edited, only withdrawn").
[VAL-FBK-003] P2 | BR-FBK-020/021/022 not enforced — no server-side check that exactly one respondent identity and
  one target identity are populated per kind; student_academic_session_id is taken from request and never matched to
  the cycle's academic session. buildResponseData() (FbkResponseController.php:123-152) passes input straight through.
[JOB-FBK-001] P2 | No scheduled cycle transitions (BR-FBK-015 date-driven part / ENH-FBK-002). FeedbackServiceProvider::
  registerCommandSchedules() is empty (:56-62), no console commands registered; Active cycles past end_date never
  auto-close and Draft cycles never auto-activate — manual-only. RISK-FBK-004.
```

---

### P3 Findings

```
[ORM-FBK-001] P3 | FbkResponse (:19-68) and FbkSummary (:14-61) declare BOTH $fillable AND $guarded. Laravel ignores
  $guarded when $fillable is present; the generated `_uq` columns are already protected by absence from $fillable, so
  the $guarded block is misleading/redundant. Drop it (or document intent).
[BUG-FBK-006] P3 | Cycle open-window boundary — FbkCycle casts start_date/end_date as 'date' (00:00:00) and isOpen()
  uses now()->between(start,end) (FbkCycle.php:94-98). A cycle "ending today" is closed from 00:00 of end_date,
  excluding the final day. Use end-of-day for end_date (or whereDate, as scopeOpen() already does at :84-89).
[VAL-FBK-002] P3 (downgraded) | Admin controllers type-hint plain Illuminate\Http\Request rather than FormRequests.
  Reconciliation: the prior "some have no validate() at all" is now OUTDATED — every store/update carries an inline
  $request->validate([...]). Residual: no FormRequest authorize() defense-in-depth (D30); hygiene only.
```

---

### Layer Health Summary

| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema Integrity | 🟢 Green | ENUM-free v3; generated `_uq` cols + `uq_fbk_r_dedup`/`uq_fbk_s_dedup` correctly emitted; FK indexes present |
| 2 | Migration↔Model↔DDL | 🟡 Amber | 3-way reconcile clean on columns, BUT service reads `context_required` not `context_required_id` (BUG-FBK-003) |
| 3 | Model & ORM | 🟡 Amber | casts good; redundant `$fillable`+`$guarded` (ORM-FBK-001) |
| 4 | Code Quality / Dead Code | 🟡 Amber | dead anonymity layer (DEAD-FBK-002), dead api.php (BUG-FBK-001/002) |
| 5 | Authorization | 🔴 Red | unseeded perms (SEC-FBK-004), coarse gating (SEC-FBK-003), peer-lock not enforced (SEC-FBK-005), 0 Fbk policies |
| 6 | Multi-Tenancy | 🟢 Green | full stack on every route; no `initialize()` leak; no jobs; no bare cache keys |
| 7 | Validation / Mass-assign | 🟡 Amber | admin CRUD validated; answer payload unvalidated (VAL-FBK-001); BR-020/21/22 unchecked (VAL-FBK-003) |
| 8 | Data Integrity / Tx | 🟡 Amber | transactions present; DB dedup unique enforced (good); reverse-scoring wrong (BUG-FBK-004); submitted overwrite (BUG-FBK-005) |
| 9 | Performance | 🟡 Amber | N+1 batch recompute (PERF-FBK-001); list controllers paginate + eager-load |
| 10 | Queue / Job / Scheduler | 🟡 Amber | no jobs; required scheduled transitions absent (JOB-FBK-001); notifications unwired (ENH-FBK-001) |
| 11 | Frontend / Output Safety | 🟡 Amber | not deeply audited; consent views use Gate checks; no obvious unescaped user output spotted |
| 12 | Deployment | 🟡 Amber | no module P0; latent api.php fatal (BUG-FBK-002); platform P0s still gate the app |

---

### STEP 1 Reading-Discipline Output (three-way reconcile + snapshot corrections)

**Three-way reconcile (DDL v3 ↔ migration ↔ model) — sample of load-bearing columns:**

| Concern | DDL v3 intent | Migration (live) | Model | Verdict |
|---------|---------------|-------------------|-------|---------|
| Relationship context | dropdown FK | `context_required_id` (mig 100002:19) | `context_required_id` + `contextRequired()` (FbkRelationshipType:25,46) | ✅ agree; **service diverges** (BUG-FBK-003) |
| Dropdown table name | `sys_dropdown_table` (doc) | FK comments say `sys_dropdown_table` | code uses `Dropdown` → `sys_dropdowns` (Prime/Dropdown.php:13); validation `exists:sys_dropdowns,id` | ✅ live code consistent on `sys_dropdowns`; the `sys_dropdown_table` name in DDL/FRD comments is a doc alias, not a live table |
| Response dedup | 7 generated `_uq` + UNIQUE | raw CREATE TABLE, `GENERATED ALWAYS AS COALESCE(...) VIRTUAL` ×7 + `uq_fbk_r_dedup` (mig 100009:41-47,64) | `$guarded` lists the 7 `_uq` cols (FbkResponse:60-68) | ✅ correct — **beats platform D36 norm** (1/19) |
| Summary dedup | 6 generated `_uq` + UNIQUE | `...VIRTUAL` ×6 + `uq_fbk_s_dedup` (mig 100011:27-32,53) | `$guarded` (FbkSummary:54-61) | ✅ correct |

**Snapshot corrections (live code wins over module-knowledge/FRD hints):**
- **"0 tests"** (FRD Q5 / module-knowledge) → **CORRECTED**: 9 Browser test files exist (`tests/Browser/Modules/Feedback/*`, ~6,230 LOC). Pest unit/feature dirs are empty (`.gitkeep`).
- **SEC-FBK-001 "zero authz in 9 controllers"** (2026-06-21) → **REMEDIATED 2026-06-27**: all 9 admin controllers carry `can:tenant.feedback.viewAny`. Residual risk re-coded as SEC-FBK-003/004.
- **SEC-FBK-002 / DEAD-FBK-001 "eligibility service never called"** → **REMEDIATED**: now invoked at FbkResponseController.php:71,88. (But eligibility logic itself is broken — BUG-FBK-003.)
- **VAL-FBK-002 "some have no validate() at all"** → **OUTDATED**: every store/update now validates inline (downgraded to P3 hygiene).

---

### FRD Gap Summary (Mode B)  — REQ → DDL / Code / Test

| REQ | Feature | DDL | Code | Test | Gap / status |
|-----|---------|-----|------|------|--------------|
| REQ-FBK-001 | Target Types | ✅ | ✅ gated CRUD | 🟡 Browser only | OK (auth via unseeded perm) |
| REQ-FBK-002 | Relationship Types | ✅ | ✅ | 🟡 Browser | peer-anonymity lock missing (SEC-FBK-005) |
| REQ-FBK-003 | Categories | ✅ | ✅ | 🟡 Browser | OK |
| REQ-FBK-004 | Templates (lock/version) | ✅ | ✅ activate locks; clone unlocks | 🟡 Browser | BR-018 ENFORCED |
| REQ-FBK-005 | Questions | ✅ | ✅ lock-guarded | 🟡 Browser | OK |
| REQ-FBK-006 | Cycle FSM | ✅ | ✅ transitions guarded | 🟡 Browser | date-driven transitions MISSING (JOB-FBK-001); notification MISSING |
| REQ-FBK-007 | Cycle flows | ✅ | ✅ Draft-only guard | 🟡 Browser | OK |
| REQ-FBK-008 | Target population | ✅ | ⚠ **broken** | 🟡 Browser | BUG-FBK-003 → 0 targets created |
| REQ-FBK-009 | Eligibility | ✅ | ⚠ **broken** | — | BUG-FBK-003; parent/teacher/transport/hostel contexts unhandled |
| REQ-FBK-010 | Response submit | ✅ | ⚠ blocked + unvalidated | 🟡 Browser | BUG-FBK-003 blocks; VAL-FBK-001; overwrite BUG-FBK-005 |
| REQ-FBK-011 | Anonymity / k-anon | ✅ | ⚠ service not wired | — | DEAD-FBK-002 / SEC-FBK-005 |
| REQ-FBK-012 | Summary / publish | ✅ | ✅ recompute inline; ⚠ reverse-score wrong | 🟡 Browser | BUG-FBK-004; publish ignores threshold (BR-009) |
| REQ-FBK-013 | Consent authoring | ✅ (PPT) | ✅ gated | — | A1 boundary (EA); perms unseeded |
| REQ-FBK-014 | Consent responses | ✅ (PPT) | ✅ | — | A1 boundary |
| REQ-FBK-015 | Dashboard/analytics | n/a | ✅ gated | 🟡 Browser | admin-only; OK |

**Notifications (REQ-006/010/012 = Notification:Yes):** EventServiceProvider empty (no listeners), no events dispatched, no Notification wiring → **MISSING** (ENH-FBK-001).

---

### Business-Rule Enforcement (Mode C)

| BR | Rule (short) | Type | Where | Status | Link |
|----|--------------|------|-------|--------|------|
| BR-FBK-001 | Submit only when cycle Active & in window | Workflow | FbkCycle::isOpen() in submit/saveDraft/isEligible | **ENFORCED** | — |
| BR-FBK-002 | Eligibility by required context | Validation | FbkEligibilityService::isEligible | **MISSING (broken)** | BUG-FBK-003 |
| BR-FBK-003 | Student rates from own identity | Permission | respondent_user_id=auth; via eligibility | **PARTIAL** | BUG-FBK-003 |
| BR-FBK-004 | Parent must be portal guardian | Permission | — | **MISSING** | no parent branch in isEligible |
| BR-FBK-005 | Teacher must teach target | Permission | sharesSubject() | **PARTIAL** | gated by BUG-FBK-003 |
| BR-FBK-006 | Peer ≠ self, same section | Validation | isEligible peer block (:66-79) | **PARTIAL** | self-exclusion OK; section gated by BUG-FBK-003 |
| BR-FBK-007 | Peer defaults anonymous | Workflow | CFT default true (:87,133) | **PARTIAL** | relationship default not forced (SEC-FBK-005) |
| BR-FBK-008 | Peer/NEP never expose identity | Permission | canTargetSeeRespondentIdentity (hardcoded) | **PARTIAL (not wired)** | DEAD-FBK-002 / SEC-FBK-005 |
| BR-FBK-009 | k-anon threshold before summary | Workflow | canTargetViewSummary / meetsVisibilityThreshold | **PARTIAL (not wired)** | publish toggle ignores threshold |
| BR-FBK-010 | Target reads strip identity | Permission | stripRespondentIdentity | **MISSING (not called)** | DEAD-FBK-002 |
| BR-FBK-011 | Admin full visibility | Permission | admin analytics + Gate::before | **ENFORCED** | — |
| BR-FBK-012 | Server-side rating by method | Calculation | computeOverallRating | **ENFORCED** | — |
| BR-FBK-013 | Reverse-score inversion | Calculation | computeOverallRating / getNumericValue | **MISSING** | BUG-FBK-004 |
| BR-FBK-014 | Only numeric types averaged | Calculation | whereNotNull(rating_value) + getNumericValue | **ENFORCED** | — |
| BR-FBK-015 | Cycle FSM legal transitions | Workflow | FbkCycleService (activate/close/publish/cancel) | **ENFORCED** (manual); date-driven **MISSING** | JOB-FBK-001 |
| BR-FBK-016 | Response FSM; submitted immutable | Workflow | submit/withdraw | **PARTIAL** | overwrite gap BUG-FBK-005 |
| BR-FBK-017 | Withdraw before close & if allowed | Workflow | canBeWithdrawn() | **ENFORCED** | — |
| BR-FBK-018 | Template lock on first activation | Workflow | activateCycle locks; edits abort_if locked | **ENFORCED** | — |
| BR-FBK-019 | Recompute summary+counters on submit/withdraw | Workflow | FbkResponseService::submit(:98-101)/withdraw(:122-125) | **ENFORCED** (inline) | resolves FRD Q3 |
| BR-FBK-020 | Exactly one respondent identity | Validation | — | **MISSING** | VAL-FBK-003 |
| BR-FBK-021 | Exactly one target identity | Validation | — | **MISSING** | VAL-FBK-003 |
| BR-FBK-022 | Cycle session = respondent session | Validation | — | **MISSING** | VAL-FBK-003 |
| BR-FBK-023 | One response per pairing | Concurrency | updateOrCreate + DB `uq_fbk_r_dedup` | **ENFORCED** (DB-level) | no row lock, but unique index protects |

Enforced 9 / Partial 7 / Missing 7. The four child-safety rules (008/009/010/011) are the priority: 011 enforced; 008/009/010 exist as code but are unwired.

---

### Systemic-Pattern Scorecard (Mode D, scoped to FBK)

| Pattern | Present in FBK? | Count / note |
|---------|-----------------|--------------|
| D17 — `$fillable` lists missing column | No | fillable matches migrations |
| D24 — permission-prefix chaos/typos | Partial | consistent `tenant.feedback.*` prefix, but coarse (SEC-FBK-003) + unseeded (SEC-FBK-004) |
| D25 — `$request->all()` mass-assign | Partial | no literal `$request->all()` into a model; but raw `answers` payload merged into FbkAnswer (VAL-FBK-001) |
| D29 — `->enum()` / ENUM in migrations | **No** | 0 enum() in any fbk migration — fully dropdown-FK (compliant) |
| D30 — FormRequest `authorize(){return true;}` | Low | only 1 FormRequest (StoreConsentFormRequest); rest inline-validate |
| D36 — generated cols degraded in migration | **No (good)** | 13 `_uq` cols correctly `GENERATED ALWAYS … VIRTUAL` + 2 dedup UNIQUE indexes |
| Layer 2.5 — cross-DB / missing-FK target | No | FK targets (sys_users, sch_*, std_*, tt_*, sys_dropdowns) resolved; no sys_roles FK |
| Layer 6.2 — `initialize()` without `end()` | No | module uses no manual tenancy init |
| Layer 10.1 — jobs without tenancy/retry | n/a | module has 0 jobs |
| TEN-RTG / RSP tenancy middleware (D23) | No | full stack present (RouteServiceProvider.php:28-35,44-54) |
| Unseeded-permission → super-admin-only | **Yes** | SEC-FBK-004 (same as SEC-DSH-009) |

---

### vs Platform Baseline

- **Better than baseline:** D36 generated columns (13/13 correct vs platform 1/19); D29 (0 enum vs ~476 platform); tenancy stack complete; transactions used in every multi-write service path.
- **At/near baseline:** unseeded-permission-string pattern (shared with Dashboard); coarse authorization; 1 dead API surface.
- **Module-specific (not baseline):** the v2→v3 string-vs-FK service drift (BUG-FBK-003) and unwired anonymity layer (DEAD-FBK-002/SEC-FBK-005) are local, not platform patterns.

---

### Recommended Fix Order (unblock-the-most-first)

1. **SEC-FBK-004** — seed `tenant.feedback.*` / `tenant.consent-forms.*` and map to roles. *Without this nothing is usable.* → DB Architect / Developer.
2. **BUG-FBK-003** — fix eligibility/population to read `contextRequired?->value`; add the missing parent/teacher/transport/hostel context branches. *Unblocks the entire submit spine.* → Developer.
3. **BUG-FBK-004** — apply reverse scoring (snapshot `is_reverse_scored`+`scale_max`; invert in compute). *Correctness of every rating.* → Developer.
4. **SEC-FBK-005 + DEAD-FBK-002** — wire FbkAnonymityService (enforce peer lock at config; strip identity / threshold on any target-facing read). *Child-safety before any target view ships.* → Developer.
5. **VAL-FBK-001 + VAL-FBK-003** — validate the answers payload and BR-020/021/022 identity/session invariants. → Developer.
6. **SEC-FBK-003** — split coarse `viewAny` into per-action abilities / Policies. → Developer.
7. **BUG-FBK-005, JOB-FBK-001, PERF-FBK-001, BUG-FBK-001/002, ENH-FBK-001** — overwrite guard, scheduled transitions, N+1, dead API cleanup, notifications. → Developer / Integration.
8. **Tests** — add Pest unit/feature tests for FSMs, dedup, scoring (incl. reverse), eligibility, anonymity. → Testing Architect.

---

*Mode X complete. One health score (54/100, Amber, no P0 cap). Deploy: GO platform-safety / NO-GO feature-readiness. Issue codes assigned once; cross-referenced across sections. Prior 2026-06-21 codes reconciled against the 2026-06-27 live tree (SEC-FBK-001/002, DEAD-FBK-001 remediated).*
