# Complete Audit — EventEngine (EVT) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** EventEngine | **Code:** EVT | **Live table prefix:** `lms_` (registry says `sys_` — code wins; see DATA-EVT-002)
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/EventEngine`
**Baseline (B/C):** `4-Requirement_Module_wise/0-FRD_Documents/EVT_FRD_Complete_2026-06-29.md` (REQ-EVT-001…009, BR-EVT-001…018, RPT-EVT-001…003 — reused, not renumbered)
**Auditor:** Technical Auditor (pa-technical-auditor) | Read-only.

---

## Executive Summary

`Modules/EventEngine` is a **configuration-CRUD scaffold** for three entities — Trigger Events, Action Types, Rule Configurations — surfaced as one tabbed screen. The CRUD code itself is competently written (consistent `tenant.` Gate strings, SoftDeletes, eager-loading, full activity logging, full tenancy middleware stack on the RSP). **But the module is non-runnable:** its three tables (`lms_trigger_event`, `lms_action_type`, `lms_rule_engine_configs`) have **zero migrations and zero DDL** anywhere in the repo — every screen and every validation rule 500s on a freshly provisioned tenant (DATA-EVT-001, P0). It is also a **misnomer**: there is no event-detection or rule-execution engine, it has **zero consumers**, and it is unrelated to the real working event→voucher engine that lives in the **Accounting** module (`acc_*`). **Worst finding:** DATA-EVT-001 (no schema of record). **Health: 18/100 (P0 cap applied → max 40). DEPLOY: NO-GO.**

---

## Health Score

Weighted layer index ≈ 0.40 of 100 raw; **hard-capped at 40** by the presence of a P0 (DATA-EVT-001). Reported **Health = 18/100** — the module cannot run on a clean tenant, so the weighted credit it earns for clean tenancy/ORM/perf is academic until the schema exists.

| | |
|---|---|
| P0 | 1 |
| P1 | 3 |
| P2 | 4 |
| P3 | 3 |
| P0 cap applied? | **Yes** (capped at 40; reported 18) |

---

## Deploy Gate Verdict (Mode G)

### 🔴 NO-GO

| Blocker | Code | Why |
|---------|------|-----|
| 3 model-declared tables have NO migration and NO DDL | **DATA-EVT-001** | `migrate` / tenant provisioning never creates `lms_trigger_event`, `lms_action_type`, `lms_rule_engine_configs`. First query on any screen → `SQLSTATE 42S02 Base table or view not found`. |

Secondary gate notes (not independent blockers, but must be addressed):
- Broken policy binding (BUG-EVT-001) will fatal **if** model-policy authorization is ever exercised.
- Module-subscription / tenancy middleware: **PASS** — RSP carries the full stack (`InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive` + `auth` + `verified`). D23 is RESOLVED for this module (corrects stale `decisions.md:263` and `known-issues.md:902 SEC-EVT-002`).
- No committed secrets, no jobs, no route closures, no `env()` in routes for this module.

---

## P0 Findings

### [DATA-EVT-001] Severity: P0 | The three tables have no schema of record (unmigrated, no DDL) → module non-runnable
- **Location:** `Modules/EventEngine/database/migrations/` (only `.gitkeep`); models `app/Models/TriggerEvent.php:16`, `ActionType.php:14`, `RuleEngineConfig.php:17`.
- **Evidence:**
    - `ls Modules/EventEngine/database/migrations/` → only `.gitkeep` (0 migrations).
    - `ls database/migrations/tenant/ | grep -iE 'trigger_event|action_type|rule_engine'` → only `create_rec_trigger_events_table.php` (Recommendation's table, **not** EVT's).
    - `grep 'lms_trigger_event\|lms_action_type\|lms_rule_engine_configs' 0-DDL_Masters/tenant_db_v4.sql` → **0 hits**.
    - Models bind `protected $table = 'lms_trigger_event'` / `'lms_action_type'` / `'lms_rule_engine_configs'` — tables that are never created.
- **Why it's a risk:** On a freshly provisioned tenant the tables do not exist. `EventEngineController::index()` (the only live screen, `routes/web.php:9`) immediately runs `TriggerEvent::where('is_active','1')->get()` → `SQLSTATE 42S02`. Every CRUD path, and every `exists:`/`unique:` validation rule in the three FormRequests, also references these non-existent tables and 500s. The module is 0% runnable. Per the severity rubric this is the canonical "module cannot deploy or run" P0.
- **Fix:** DB Architect to author tenant migrations + DDL for all three tables (with `created_by`, `is_active`, `softDeletes()`, and DB-level **unique** indexes on `code`/`rule_code` and FK indexes on `trigger_event_id`, `action_type_id`, `applicable_class_group_id`). Resolve the prefix question (DATA-EVT-002) **before** authoring. This is the precondition for every other finding to matter.
- **Confidence:** High
- **Systemic?:** Module-local schema gap (cf. Layer 2.5 missing-FK-target pattern, but here the *whole* table set is missing). Maps to FRD RISK-EVT-001 / ENH-EVT-004.

---

## P1 Findings

### [BUG-EVT-001] Severity: P1 | RuleEngineConfig policy bound to a non-existent class (`Modules\LmsHomework\Policies\RuleEngineConfigPolicy`)
- **Location:** `app/Providers/EventEngineServiceProvider.php:13` (import) and `:56` (`Gate::policy(...)`).
- **Evidence:**
    ```php
    use Modules\LmsHomework\Policies\RuleEngineConfigPolicy;   // :13 — class does NOT exist
    ...
    Gate::policy(RuleEngineConfig::class, RuleEngineConfigPolicy::class);  // :56 → resolves to the LmsHomework FQCN
    ```
    Verified: `Modules/LmsHomework/app/Policies/` contains only `Homework*` policies (no `RuleEngineConfigPolicy`). The real, working class is `app/Policies/RuleEngineConfigPolicy.php:9` (`namespace App\Policies`), which correctly checks `tenant.rule-engine-config.*` permissions. The sibling bindings on `:54`/`:55` correctly point at `App\Policies\TriggerEventPolicy` / `ActionTypePolicy`.
- **Why it's a risk:** `RuleEngineConfigPolicy::class` resolves at compile time to a string and is stored without autoload, so the misbinding is **dormant** today — the controllers authorize via string abilities (`Gate::authorize('tenant.rule-engine-config.create')`, spatie permissions), which never resolve the model policy. The moment any code does model-based authorization on a `RuleEngineConfig` (e.g. `$user->can('update', $ruleEngineConfig)` or `$this->authorize('view', $model)`), Laravel resolves the bound class and throws `Class "Modules\LmsHomework\Policies\RuleEngineConfigPolicy" not found` (fatal 500).
- **Fix:** Change the import on `:13` to `use App\Policies\RuleEngineConfigPolicy;`.
- **Confidence:** High
- **Systemic?:** Module-local; a copy-paste-from-LmsHomework artifact (see also DEAD-EVT-002). **P0 if** any model-policy authorization path is introduced/used; **P1** while all gates are string-ability based. Maps to FRD RISK-EVT-002 / EVT-G04.

### [DATA-EVT-002] Severity: P1 | Table-prefix divergence: registry `sys_` vs code `lms_`
- **Location:** `module_list.md` line 17 (`EventEngine │ EVT │ sys_`) vs models `TriggerEvent.php:16` / `ActionType.php:14` / `RuleEngineConfig.php:17` (all `lms_*`).
- **Evidence:** Registry registers prefix `sys_`; live `$table` values are `lms_trigger_event`, `lms_action_type`, `lms_rule_engine_configs`.
- **Why it's a risk:** (1) A migration authored to the registry (`sys_*`) would not match the models, perpetuating DATA-EVT-001. (2) `lms_` collides with the LMS module family (LmsExam/Quiz/Quests/Homework) — the tables are indistinguishable from LMS tables and reinforce the copy-paste origin. (3) Convention violation: a generic config engine should not sit under an LMS prefix.
- **Fix:** Architecture decision (EA) to pick the canonical prefix, then author migrations + update `$table`, FormRequest `unique:`/`exists:` table names, and the registry to agree. **Resolve before DATA-EVT-001 migration is written.**
- **Confidence:** High
- **Systemic?:** Module-local naming; maps to FRD EVT-G02 / ENH-EVT-005.

### [SEC-EVT-001] Severity: P1 (systemic, mitigated) | All 3 FormRequests `authorize()` return hardcoded `true` (D30)
- **Location:** `TriggerEventRequest.php:11-14`, `ActionTypeRequest.php:10-13`, `RuleEngineConfigRequest.php:13-16`.
- **Evidence:** `public function authorize(): bool { return true; }` in all three.
- **Why it's a risk:** Removes the request-layer authorization gate (defense-in-depth). **Mitigated here:** every consuming controller action calls `Gate::authorize('tenant.<entity>.<action>')` before mutating, so there is no *currently-exploitable* hole (unlike the D30→P0 escalation case where the controller is also ungated). Still the platform-systemic pattern (437/485 = 90% baseline).
- **Fix:** Return `Gate::allows('tenant.<entity>.<action>')` matching the route; keep the controller gates too.
- **Confidence:** High
- **Systemic?:** D30 (platform-wide). EVT contributes 3 sites; not an outlier.

---

## P2 Findings

### [DEAD-EVT-001] Severity: P2 | Resource `index()` actions are dead/unreachable (abort 404 / early redirect + unreachable body)
- **Location:** `TriggerEventController.php:17-37`, `ActionTypeController.php:17-36`, `RuleEngineConfigController.php:20-54`.
- **Evidence:**
    ```php
    // TriggerEventController::index()
    abort(404);                                                   // :19
    return redirect()->route('event-engine.index', ...);          // :20 — unreachable
    Gate::authorize('tenant.trigger-event.viewAny'); ... paginate; // :21+ — all dead
    ```
    `ActionTypeController::index():19` and `RuleEngineConfigController::index():22` `return redirect(...)` on the first line; the entire list query below is unreachable.
- **Why it's a risk:** `Route::resource('trigger-events', …)` (`routes/web.php:11`) maps `trigger-events.index` → this method, so the live route returns **HTTP 404** while the sibling action/rule routes silently redirect — inconsistent behaviour and ~50 lines of unreachable code per controller. The real list is the tabbed `EventEngineController::index()`.
- **Fix:** Either drop `index` from the three `Route::resource(...)` calls (`->except(['index'])`) or make all three consistently `return redirect()->route('event-engine.index', ['active_tab' => …])` and delete the unreachable bodies.
- **Confidence:** High · **Systemic?:** Module-local (FRD EVT-G05).

### [BUG-EVT-002] Severity: P2 | Rule/event/action logic payloads are hardcoded placeholders, never authored (BR-EVT-018 unmet)
- **Location:** `RuleEngineConfigController.php:87-89` (store); `update():145-153` omits `logic_config` entirely; `TriggerEventController.php:60-64` & `ActionTypeController.php:59-63`.
- **Evidence:**
    ```php
    'logic_config' => json_encode(['min_score' => '1']),   // store — fixed, not user input
    ```
    `event_logic`/`action_logic` are filled by echoing `{code,name,description}` back into JSON, not real evaluable logic. On rule **update**, `logic_config` is not set at all.
- **Why it's a risk:** The "rule engine" carries no real evaluable condition; administrators cannot author thresholds/parameters. Combined with the absent execution engine, the rules are inert configuration. Functional gap, not a security one.
- **Fix:** Build the rule-logic authoring UI + validation (FRD ENH-EVT-003); validate and persist `logic_config` on store and update.
- **Confidence:** High · **Systemic?:** Module-local (FRD BR-EVT-018 / EVT-G06).

### [BUG-EVT-003] Severity: P2 | API resource is an unimplemented stub
- **Location:** `routes/api.php:6-8` (`apiResource('eventengines', EventEngineController)`); `EventEngineController.php:110,131,136` (`store/update/destroy` empty bodies), `:115-118` (`show` returns `view('eventengine::show')`).
- **Evidence:** `store(Request $request) {}`, `update(Request $request, $id) {}`, `destroy($id) {}` — empty. `show()` returns a Blade view `eventengine::show` that **does not exist** (no `resources/views/show.blade.php` at module root; verified `ls` → no such file) → 500 for a JSON API.
- **Why it's a risk:** Authenticated callers hitting `api/v1/eventengines` get empty 200s (write paths) or a view-not-found 500 (`show`). It is behind `auth:sanctum`, so not an unauth hole, but it advertises a non-functional contract.
- **Fix:** Implement the API handlers (return JSON, authorize) or remove the `apiResource` route (FRD ENH-EVT-007 / EVT-G11).
- **Confidence:** High · **Systemic?:** Module-local.

### [VAL-EVT-001] Severity: P2 | `required_parameters` persisted from raw request without validation
- **Location:** `ActionTypeController.php:64` writes `'required_parameters' => $request->required_parameters`; `ActionTypeRequest.php:25-36` `rules()` has **no** `required_parameters` rule.
- **Evidence:** Field is `$fillable` + `array` cast on the model but is never in `ActionTypeRequest::rules()`; arbitrary client JSON is accepted into it.
- **Why it's a risk:** Unvalidated structured input is persisted (no shape/type enforcement). Low blast radius (internal config, no privilege field, no `$request->all()`), so P2 not P1.
- **Fix:** Add `'required_parameters' => 'nullable|array'` (+ element rules) to `ActionTypeRequest`.
- **Confidence:** High · **Systemic?:** Module-local.

---

## P3 Findings

### [DEAD-EVT-002] Severity: P3 | Stray `Modules\LmsHomework\Models\TriggerEvent` import (copy-paste origin)
- **Location:** `app/Http/Requests/TriggerEventRequest.php:7` — `use Modules\LmsHomework\Models\TriggerEvent;` (unused; the FormRequest references no model class). Confirms the module was copy-pasted from LmsHomework (same origin as BUG-EVT-001).
- **Fix:** Remove the unused import. · **Confidence:** High.

### [BUG-EVT-004] Severity: P3 | `activityLog()` emitted before `save()` in toggle/destroy → inaccurate audit on save failure
- **Location:** `TriggerEventController.php:227` (log) before `:232` (`save()`); `ActionTypeController.php:228` before `:233`; `RuleEngineConfigController.php:252` before `:256`.
- **Evidence:** `activityLog($model, 'Toggled', …)` runs, then `if ($model->save())`. If `save()` fails, an audit entry claiming success was already written.
- **Fix:** Move `activityLog(...)` after a successful `save()`. · **Confidence:** High (FRD EVT-G10).

### [DATA-EVT-003] Severity: P3 | `destroy()` two-write (set inactive + soft-delete) not transactional; restore leaves record inactive
- **Location:** e.g. `TriggerEventController.php:151-153` (`is_active=false; save(); delete();`); `restore()` does not flip `is_active` back.
- **Evidence:** Two writes without `DB::transaction`; `restore()` (`:179-193`) only `->restore()`. Per BR-EVT-016 this is the *intended* behaviour for Rules (restore inactive), but it is undocumented for Trigger Events/Action Types.
- **Why it's low:** Single-row config writes; partial-write window is tiny and harmless. Document the "restore comes back inactive" behaviour. · **Confidence:** High (FRD EVT-G08).

---

## Layer Health Summary (Mode A)

| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema Integrity | 🔴 Red | No DDL exists for any of the 3 tables (DATA-EVT-001) |
| 2 | Migration ↔ Model ↔ DDL | 🔴 Red | 0 migrations; 3 orphan models bound to non-existent tables (DATA-EVT-001) |
| 3 | Model & ORM Correctness | 🟢 Green | Casts correct (`array`/`boolean`), relationships valid, SoftDeletes consistent |
| 4 | Code Quality & Dead Code | 🟠 Amber | Dead `index()` actions, stray import, placeholder logic, stub API |
| 5 | Authorization & Access | 🟠 Amber | Clean `tenant.` gate strings on all CRUD (no D24 typos); but broken policy binding (BUG-EVT-001); `EventEngineController::index` has no controller gate (mitigated by `@can` tabs) |
| 6 | Multi-Tenancy Isolation | 🟢 Green | Full RSP stack; per-tenant DB isolation; no `initialize()` leaks; **D23 RESOLVED** (corrects stale SEC-EVT-002) |
| 7 | Input Validation / Mass-assign | 🟠 Amber | D30 `authorize()=true` ×3 (gated by controllers); `required_parameters` unvalidated; **no** `$request->all()` (clean) |
| 8 | Data Integrity / Tx / Concurrency | 🔴 Red | No schema = no DB unique index / FK enforcement (uniqueness is app-only, race-prone); non-tx two-write destroy |
| 9 | Performance & Query Efficiency | 🟢 Green | `paginate(10)` per tab, rule list eager-loads `triggerEvent/actionType/classGroup`, small config tables |
| 10 | Queue / Job / Scheduler | 🟢 Green | No jobs/schedules — correct for a config CRUD (N/A) |
| 11 | Frontend / Blade / Output Safety | 🟢 Green | No raw `{!! $userField !!}`; tabs gated with `@can` |
| 12 | Deployment & Operational Readiness | 🔴 Red | Module non-runnable on fresh tenant (DATA-EVT-001 = deploy blocker); no secrets/closures otherwise |

---

## STEP 1 Reading-Discipline Output (three-way reconcile + snapshot corrections)

**Three-way schema reconcile (DDL ↔ migration ↔ model):**

| Table (model `$table`) | DDL (`tenant_db_v4.sql`) | Tenant migration | Eloquent model | Verdict |
|---|---|---|---|---|
| `lms_trigger_event` | ❌ absent | ❌ none | ✅ `TriggerEvent.php` | Orphan model — **no schema** (DATA-EVT-001) |
| `lms_action_type` | ❌ absent | ❌ none | ✅ `ActionType.php` | Orphan model — **no schema** |
| `lms_rule_engine_configs` | ❌ absent | ❌ none | ✅ `RuleEngineConfig.php` | Orphan model — **no schema** |

All three sources disagree in the worst way: only the model exists. `$fillable`/`$casts` cannot be reconciled against columns because no columns are defined anywhere — D17-style checks are N/A until migrations exist.

**Snapshot corrections (module-knowledge / decisions / known-issues were stale):**
- **D23 / SEC-EVT-002 are STALE.** `decisions.md:263` and `known-issues.md:902` claim EventEngine's RSP lacks tenancy middleware. **Live code disproves this:** `app/Providers/RouteServiceProvider.php:41-48` applies `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive` + `auth` + `verified`. D23 is RESOLVED for EVT (matches the auditor baseline note). SEC-EVT-002 should be marked RESOLVED.
- `progress.md:113` ("EventEngineController zero auth … runs on wrong DB … isset() vs filled() filter bug") is partly stale: tenancy is fixed; the filter uses `filled()` not `isset()`. The "EventEngineController zero controller-gate" point stands but is mitigated by `@can` tabs in `index.blade`.
- Module-knowledge file EVT_EventEngine.md counts (3 models, 4 controllers, 3 requests, 17 views, 0 migrations, 0 DDL, 0 tests, 0 consumers) **all re-verified accurate** against the live tree.

---

## FRD Gap Summary (Mode B) — REQ → DDL / Code / Test

| REQ | Feature | DDL | Code | Test | Status | Blocking finding |
|-----|---------|-----|------|------|--------|------------------|
| REQ-EVT-001 | Manage Trigger Events | ❌ none | ✅ full CRUD | ❌ 0 | **PARTIAL** (non-runnable) | DATA-EVT-001 |
| REQ-EVT-002 | Manage Action Types | ❌ none | ✅ full CRUD | ❌ 0 | **PARTIAL** | DATA-EVT-001; VAL-EVT-001 |
| REQ-EVT-003 | Manage Rule Configurations | ❌ none | ✅ full CRUD | ❌ 0 | **PARTIAL** | DATA-EVT-001; BUG-EVT-001; BUG-EVT-002 |
| REQ-EVT-004 | Unified tabbed screen | n/a | ✅ `index.blade` + `@can` tabs | ❌ 0 | **DONE** (runtime-blocked) | DEAD-EVT-001 (resource index dead) |
| REQ-EVT-005 | Activate / Deactivate | n/a | ✅ `toggleStatus` ×3 | ❌ 0 | **DONE** | BUG-EVT-004 (audit ordering) |
| REQ-EVT-006 | Trash / Restore / Delete | n/a | ✅ SoftDeletes + force | ❌ 0 | **DONE** | DATA-EVT-003 |
| REQ-EVT-007 | Activity logging | n/a | ✅ `activityLog` everywhere | ❌ 0 | **DONE** | BUG-EVT-004 |
| REQ-EVT-008 | Configurable rule logic | ❌ none | ❌ hardcoded | ❌ 0 | **NOT STARTED** | BUG-EVT-002 |
| REQ-EVT-009 | Programmatic API | n/a | ❌ empty stubs | ❌ 0 | **NOT STARTED** | BUG-EVT-003 |

**Reports (RPT-EVT-001…003):** all **Not built** (0/3) — confirmed; no report/export controller or view exists in the module. Activity-log data exists to support RPT-EVT-003 but no report surfaces it.
**Tests:** 0 (Mode B Step 5) — `tests/Unit` and `tests/Feature` hold only `.gitkeep`; no `tests/Browser/Modules/EventEngine/`.

**Net:** every P0 REQ (001-004) is code-present but **runtime-blocked by DATA-EVT-001**; all validation `exists:`/`unique:` rules themselves 500 because they query the missing `lms_*` tables.

---

## Business-Rule Enforcement (Mode C) — BR-EVT-001…018

| BR | Type | Enforcement location | Status | Note / link |
|----|------|----------------------|--------|-------------|
| BR-EVT-001 | Validation | `TriggerEventRequest.php:26-29` `Rule::unique(...)->whereNull('deleted_at')` | **ENFORCED** (app-only; no DB index — DATA-EVT-001) |
| BR-EVT-002 | Validation | `TriggerEventRequest.php:22-35` `required\|max:50/100` | **ENFORCED** |
| BR-EVT-003 | Validation | `ActionTypeRequest.php:26-32` unique ignore-self | **ENFORCED** |
| BR-EVT-004 | Validation | `ActionTypeRequest.php:33` `required\|max:100/50` | **ENFORCED** |
| BR-EVT-005 | Validation | `RuleEngineConfigRequest.php:27,29` `required\|exists:` | **ENFORCED** (queries missing tables — DATA-EVT-001) |
| BR-EVT-006 | Workflow | `ActionTypeController.php:65`, `RuleEngineConfigController.php:91` `?? true` | **PARTIAL** — `TriggerEventController::store` (`:56-65`) never sets `is_active`, relying on a DB default that does not exist (DATA-EVT-001) |
| BR-EVT-007 | Workflow | `RuleEngineConfigController.php:63-64,125-126` filter `is_active=1` | **ENFORCED** |
| BR-EVT-008 | Validation | `RuleEngineConfigRequest.php:28` `nullable\|exists:sch_class_groups_jnt,id` | **ENFORCED** |
| BR-EVT-009 | Validation | `RuleEngineConfigRequest.php:34-41` unique ignore-self on PUT/PATCH | **ENFORCED** |
| BR-EVT-010 | Workflow | `EventEngineController.php:49,70,96` distinct page names | **ENFORCED** |
| BR-EVT-011 | Workflow | `EventEngineController.php:39-43,60-63,81-84` search code/name/desc | **ENFORCED** |
| BR-EVT-012 | Permission | `index.blade.php:36,40,44` `@can('tenant.*.viewAny')` | **ENFORCED** (view-level; controller `index` itself ungated) |
| BR-EVT-013 | Workflow | `toggleStatus` ×3 | **ENFORCED** (audit-ordering nit BUG-EVT-004) |
| BR-EVT-014 | Workflow | SoftDeletes + `trashed()` views | **ENFORCED** |
| BR-EVT-015 | Permission | `forceDelete()` `Gate::authorize('...forceDelete')` ×3 | **ENFORCED** |
| BR-EVT-016 | Workflow | `RuleEngineConfigController.php:173-175` set inactive then delete | **ENFORCED** |
| BR-EVT-017 | Workflow | `activityLog(...)` on every mutation | **ENFORCED** (ordering nit BUG-EVT-004) |
| BR-EVT-018 | Validation | — | **MISSING** → BUG-EVT-002 (logic hardcoded) |

> **Caveat:** every "ENFORCED" validation rule above is moot at runtime — `unique:`/`exists:` against `lms_*` tables 500 until DATA-EVT-001 is fixed. Enforcement is *coded correctly* but *not executable*.

---

## Systemic-Pattern Scorecard (Mode D, scoped to EVT)

| Pattern | Present? | Count | vs baseline | Note |
|---------|----------|-------|-------------|------|
| D17 fillable ↔ column mismatch | N/A | — | — | No columns exist to compare (DATA-EVT-001) |
| D24 permission-prefix chaos/typos | **No** | 0 | better than norm | All gates use consistent `tenant.<entity>.<action>` — clean |
| D25 `$request->all()` mass-assign | **No** | 0 | better (baseline 24) | Controllers use explicit field arrays |
| D29 `->enum()` in migrations | N/A | 0 | — | 0 migrations |
| D30 `authorize(){return true;}` | **Yes** | 3/3 | typical (90% norm) | SEC-EVT-001; mitigated by controller gates |
| D36 GENERATED column degraded | N/A | — | — | No migrations |
| Layer 2.5 cross-DB / missing-FK target | **Yes (severe)** | 3 tables | worse | Entire table set missing, not just an FK (DATA-EVT-001); cross-module FK → `sch_class_groups_jnt` is same-tenant, fine |
| Layer 6.2 `initialize()` without `end()` | **No** | 0 | clean | No `tenancy()->initialize()` in module |
| Layer 10.1 job tenancy/retry | N/A | 0 jobs | — | No jobs |
| TEN-RTG-001 module-subscription / tenancy middleware | **Correct** | — | clean | Full RSP stack present (D23 resolved) |

**Read:** EVT is *cleaner than the platform norm* on the mass-assignment and permission-prefix patterns, but is dominated by a single catastrophic schema gap.

---

## EventEngine vs the Accounting event→voucher engine (do NOT conflate)

Verified distinction (the brief's "generic config-driven event engine referenced by Accounting" is **not** this module):

| Concern | Lives in | Tables | Migrated? | Consumers |
|---------|----------|--------|-----------|-----------|
| Real cross-module event → accounting voucher engine | **`Modules/Accounting`** | `acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log` | **Yes** (tenant migrations 2026-06-15) | Transport, Library via `RemoteEntryService` |
| `Modules/EventEngine` (this audit) | here | `lms_trigger_event`, `lms_action_type`, `lms_rule_engine_configs` | **No** | **None** — `grep 'Modules\EventEngine\' outside module` → only its own 3 `App\Policies` classes; 0 functional consumers |
| Recommendation trigger/rules | `Modules/Recommendation` | `rec_trigger_events`, `rec_recommendation_rules` | Yes | its own engine |

EVT is a standalone, unmigrated LMS-style rule-config scaffold with no event-detection/execution engine and no subscribers. Its future (build out vs. retire/merge into Accounting's engine) is an open architecture decision (FRD RISK-EVT-004).

---

## vs Platform Baseline

| Metric | Platform | EVT | Read |
|--------|----------|-----|------|
| FormRequests `authorize()=true` (D30) | 90% | 3/3 | typical |
| `$request->all()` mass-assign (D25) | 24 sites | 0 | better |
| Permission-prefix typos (D24) | ~50 sites | 0 | better (clean `tenant.` taxonomy) |
| `->enum()` migrations (D29) | ~476 | 0 (no migrations) | n/a |
| Tenancy middleware on RSP | 5 central modules lack it (correct) | present (correct) | healthy |
| Schema present for declared models | norm: present | **0/3 tables** | **far worse — unique to EVT** |
| Tests | sparse | 0 | typical-low |

EVT's code-quality hygiene is *above* the platform norm; its **schema completeness is the worst-case** — fully coded yet non-runnable.

---

## Recommended Fix Order (unblock-the-most-first)

1. **DATA-EVT-002 (decide prefix)** → then **DATA-EVT-001 (author migrations + DDL + DB unique/FK indexes)** — *the* unblock; nothing else runs without it. → **DB Architect / EA**
2. **BUG-EVT-001** — repoint `RuleEngineConfigPolicy` import to `App\Policies\…` (one line; removes a latent fatal). → **Developer**
3. **DEAD-EVT-001 + DEAD-EVT-002** — remove dead resource `index()` bodies (`->except(['index'])` or consistent redirect) and the stray LmsHomework import. → **Developer**
4. **VAL-EVT-001** — validate `required_parameters`. **BUG-EVT-004** — move `activityLog` after `save()`. → **Developer**
5. **Tests** — Pest feature tests for CRUD + permissions + toggle/trash (0 today). → **Testing Architect**
6. **BUG-EVT-002 / BUG-EVT-003** — rule-logic authoring UI + finish-or-remove the API stub (FRD ENH-EVT-003/007). → **Full-stack**
7. **Architecture call** — build out the execution engine (ENH-EVT-001/002) or retire EVT in favour of the Accounting `acc_*` engine. → **Enterprise Architect**

---

## Next Steps
Audit complete — **Health 18/100 (capped: P0 present). DEPLOY: NO-GO.**
1. Fix P0/P1 → `act as Developer` (BUG-EVT-001, DEAD-EVT-001/002, VAL-EVT-001)
2. Author schema/DDL → `act as DB Architect` (DATA-EVT-001 after DATA-EVT-002 prefix decision)
3. Completeness score → `act as Status_Analyzer`
4. Test coverage (0 today) → `act as Testing Architect`
5. Retire-vs-build-out architecture decision → `act as Enterprise Architect`
