# Module Knowledge — EventEngine (EVT)

> **Status:** SEEDED 2026-06-29 by Business Analyst (pa-business-analyst).
> Seeded from the live tree (`Modules/EventEngine`), three-way reconciled against migrations and DDL.
> **All counts below were verified against the filesystem / source — nothing is assumed.**

---

## Module Facts (verified)

| Fact | Value | Evidence / Note |
|------|-------|-----------------|
| Module name | **EventEngine** | `module.json` → `"name":"EventEngine"`, `"alias":"eventengine"` |
| RBS code | **EVT** | `0-Prime_Ai_Detail/module_list.md` line 17 |
| Registered prefix (per module_list) | **`sys_`** | `module_list.md`: `EventEngine │ EVT │ sys_` |
| **Actual table prefix in code** | **`lms_`** ⚠️ | Models declare `lms_trigger_event`, `lms_action_type`, `lms_rule_engine_configs` — **does NOT match the registered `sys_` prefix** |
| Layer | Tenant (school) | Routes wrapped in `InitializeTenancyByDomain` + `EnsureTenantIsActive` (RouteServiceProvider) |
| Web route prefix / name prefix | `event-engine` / `event-engine.` | `RouteServiceProvider::mapWebRoutes()` |
| Tables declared (in models) | **3** | TriggerEvent, ActionType, RuleEngineConfig |
| **Migrations** | **0** ⚠️ | `database/migrations/` holds only `.gitkeep`; no migration creates the 3 tables anywhere in the repo |
| **DDL entries** | **0** ⚠️ | None of the 3 tables appear in `0-DDL_Masters/tenant_db_v4.sql` |
| Models | **3** | `TriggerEvent.php`, `ActionType.php`, `RuleEngineConfig.php` |
| Controllers | **4** | `EventEngineController` (unified tab UI), `TriggerEventController`, `ActionTypeController`, `RuleEngineConfigController` |
| FormRequests | **3** | `TriggerEventRequest`, `ActionTypeRequest`, `RuleEngineConfigRequest` |
| Policies | **3** (in central `app/Policies/`) | `TriggerEventPolicy`, `ActionTypePolicy`, `RuleEngineConfigPolicy` |
| Services | **0** | No `app/Services/` — there is **no rule-execution / event-dispatch engine code** |
| Views | **17** | `index.blade` (unified tabs) + 5 each (create/edit/show/index/trash) for the 3 entities + `components/layouts/master.blade` |
| Tests | **0** | `tests/Unit` and `tests/Feature` hold only `.gitkeep` |
| Seeder | present but empty | `EventEngineDatabaseSeeder::run()` is a no-op |
| FRD status | **Complete FRD created 2026-06-29** | `EVT_FRD_Complete_2026-06-29.md` |

### Estimated completion: ~30–35% (config CRUD scaffold only)
CRUD screens for the three config entities are built and authorised, but the module has **no schema of record (0 migrations, 0 DDL), no execution engine, and no consumers**. It is a configuration shell, not a working event engine.

---

## DDL / Table Inventory (model-declared; UNMIGRATED)

> ⚠️ These tables are declared only in Eloquent models. No migration or DDL defines them — they will not exist after `migrate`/tenant provisioning. The columns below are inferred from `$fillable` + `$casts` + controller writes + FormRequest rules.

### `lms_trigger_event` (model `TriggerEvent`, soft-deletes)
| Column | Type (inferred) | Notes |
|--------|-----------------|-------|
| id | PK | |
| code | string ≤50, unique (whereNull deleted_at) | business event code |
| name | string ≤100 | |
| description | text nullable | |
| event_logic | JSON (`array` cast) | controller stuffs `{code,name,description}` into it — placeholder, not real logic |
| is_active | boolean | |
| created_at / updated_at / deleted_at | timestamps + soft delete | |

### `lms_action_type` (model `ActionType`, soft-deletes)
| Column | Type | Notes |
|--------|------|-------|
| id | PK | |
| code | string ≤50, unique | |
| name | string ≤100 | |
| description | text nullable | |
| action_logic | JSON (`array` cast) | placeholder `{code,name,description}` |
| required_parameters | JSON (`array` cast) | written from request but **not validated** by `ActionTypeRequest` |
| is_active | boolean | |
| timestamps + deleted_at | | |

### `lms_rule_engine_configs` (model `RuleEngineConfig`, soft-deletes)
| Column | Type | Notes |
|--------|------|-------|
| id | PK | |
| rule_code | string ≤50, unique | |
| rule_name | string ≤100 | |
| description | text nullable | |
| trigger_event_id | FK → lms_trigger_event.id | required |
| applicable_class_group_id | FK → `sch_class_groups_jnt.id` nullable | **cross-module → SchoolSetup** |
| logic_config | JSON (`array` cast) | hardcoded to `{"min_score":"1"}` on store; **not editable / not validated** |
| action_type_id | FK → lms_action_type.id | required |
| is_active | boolean | |
| timestamps + deleted_at | | |

---

## Known Gaps & Open Issues

### P0
- **EVT-G01 — No schema of record.** The 3 tables have **0 migrations and 0 DDL** anywhere in the repo. The module cannot function on a freshly provisioned tenant; every screen 500s on first query.
- **EVT-G02 — Prefix mismatch.** Registered as `sys_` (module_list) but built with `lms_` table names. Naming-convention violation; also makes the module indistinguishable from LMS rule-engine tables.
- **EVT-G03 — No execution engine.** There is no service/listener/job that (a) detects a trigger event firing, (b) evaluates `logic_config`, (c) executes the linked action. The module only stores configuration; nothing consumes it. "Event Engine" is currently a misnomer — it is a Rule-Config CRUD.
- **EVT-G04 — Broken policy binding.** `EventEngineServiceProvider::registerPolicies()` binds `RuleEngineConfig` to `Modules\LmsHomework\Policies\RuleEngineConfigPolicy`, which **does not exist** (LmsHomework has only Homework* policies). The real policy is `App\Policies\RuleEngineConfigPolicy`. Authorising any RuleEngineConfig action risks a class-not-found error.

### P1
- **EVT-G05 — Dead/duplicated list actions.** `TriggerEventController::index()` starts with `abort(404)`; `ActionTypeController::index()` and `RuleEngineConfigController::index()` `return redirect(...)` before any code — all list logic after the first statement is unreachable. The single live list is `EventEngineController::index()` (tabbed). The resource `index` routes are effectively disabled.
- **EVT-G06 — `logic_config` not user-editable.** Rule logic is hardcoded `{"min_score":"1"}` at store and never set on update; `event_logic`/`action_logic` are placeholders echoing code/name/description. The "rule engine" carries no real evaluable logic.
- **EVT-G07 — Stray import.** `TriggerEventRequest` imports `Modules\LmsHomework\Models\TriggerEvent` (unused) — confirms the module was copy-pasted from LmsHomework.
- **EVT-G08 — `destroy()` soft-delete pattern.** Sets `is_active=false` then `delete()`; restore does not flip `is_active` back to true → restored records come back inactive (acceptable, but undocumented).

### P2
- **EVT-G09 — No tests** (0 feature/unit).
- **EVT-G10 — `toggleStatus` ordering.** `activityLog(...,'Toggled')` is written before `save()`; on save failure an inaccurate audit entry has already been emitted.
- **EVT-G11 — API resource stub.** `routes/api.php` exposes `apiResource('eventengines', EventEngineController)` but the controller's `store/update/destroy` are empty bodies.

### Technical Auditor confirmation (Mode X, 2026-06-29) — issue codes assigned
All BA gaps re-verified against live code and given audit codes (full report: `3-Audit_Reports/V1_Jun-2026/EventEngine_Complete_Audit_2026-06-29.md`). **Health 18/100 (P0 cap). Deploy: NO-GO.**

| Audit code | Sev | = BA gap | One-line |
|------------|-----|----------|----------|
| DATA-EVT-001 | P0 | EVT-G01 | 3 tables, 0 migrations + 0 DDL → non-runnable (`SQLSTATE 42S02`) |
| BUG-EVT-001 | P1 | EVT-G04 | RuleEngineConfig policy → non-existent `Modules\LmsHomework\Policies\RuleEngineConfigPolicy`; real is `App\Policies\...`. Latent fatal (dormant under string-ability gates) — `EventEngineServiceProvider.php:13,56` |
| DATA-EVT-002 | P1 | EVT-G02 | Prefix `sys_` (registry) vs `lms_` (code) |
| SEC-EVT-001 | P1 | (9.2) | D30: 3/3 FormRequests `authorize()=true` — mitigated by controller `Gate::authorize` |
| DEAD-EVT-001 | P2 | EVT-G05 | Resource `index()` dead: `TriggerEventController::index():19 abort(404)`; Action/Rule early redirect + unreachable body |
| BUG-EVT-002 | P2 | EVT-G06 | `logic_config` hardcoded `{min_score:'1'}`, omitted on update; logic not authorable (BR-EVT-018 unmet) |
| BUG-EVT-003 | P2 | EVT-G11 | API stub: empty `store/update/destroy`; `show()` → nonexistent `eventengine::show` view (500) |
| VAL-EVT-001 | P2 | (new) | `required_parameters` persisted from raw request, no validation rule — `ActionTypeController.php:64` |
| DEAD-EVT-002 | P3 | EVT-G07 | Stray `use Modules\LmsHomework\Models\TriggerEvent;` — `TriggerEventRequest.php:7` |
| BUG-EVT-004 | P3 | EVT-G10 | `activityLog()` before `save()` in toggle/destroy |
| DATA-EVT-003 | P3 | EVT-G08 | Non-tx two-write destroy; restore leaves record inactive |

**Corrections to earlier snapshots:** **D23/SEC-EVT-002 are STALE** — live `RouteServiceProvider.php:41-48` carries the full tenancy stack; EVT does NOT "run on wrong DB". The real blocker is schema (DATA-EVT-001). `index.blade.php:36,40,44` gates tabs with `@can('tenant.*.viewAny')` (BR-EVT-012 enforced at view level). Permission taxonomy is clean (`tenant.*`, no D24 typos); no `$request->all()` (no D25).

---

## CRITICAL CLARIFICATION — "EventEngine" vs the Accounting event→voucher engine

The brief framed EVT as "the generic config-driven event engine (ModuleEvent / EventVoucherConfig / EventProcessingLog / RemoteEntryService) referenced by Accounting." **That engine is NOT in this module.** Verified:

| Concern | Where it actually lives | Tables | Migrated? |
|---------|------------------------|--------|-----------|
| Generic cross-module event → accounting voucher engine | **`Modules/Accounting`** | `acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log` | **Yes** — `database/migrations/tenant/2026_06_15_1610*` |
| Accounting consumers | `RemoteEntryService`, `ModuleEventController`, `EventVoucherConfigController`; consumed by Transport (`FeeCollectionController`, `StudentAllocationController`), Library (`LibFineController`, `LibMemberController`) | (acc_*) | Yes |
| `Modules/EventEngine` (this module) | LMS-style rule-engine **config CRUD** | `lms_trigger_event`, `lms_action_type`, `lms_rule_engine_configs` | **No** |

So: the **Accounting module owns the real, working event-voucher engine**; modules "subscribe" to it by recording `acc_module_events` and posting via `RemoteEntryService` (see Accounting knowledge). The `EventEngine` module is a separate, unmigrated LMS rule-config scaffold and currently has **no consumers** (`grep` for `EventEngine\\` outside the module = 0 hits).

---

## Cross-Module Dependencies (verified)

**Outbound (EventEngine reads from):**
- **SchoolSetup** — `RuleEngineConfig.applicable_class_group_id` → `SchClassGroupsJnt` (`sch_class_groups_jnt`). A rule may be scoped to a class group.

**Inbound (who consumes EventEngine):** **None.** No other module references `Modules\EventEngine\*`. (The Accounting voucher engine and the Recommendation module's own `RecTriggerEvent`/`RecommendationRule` are independent implementations.)

**Related-but-separate engines (do not conflate):**
- `Modules/Accounting` — acc_* event→voucher engine (the cross-module one).
- `Modules/Recommendation` — `rec_trigger_events`, `rec_recommendation_rules` (its own trigger/rule model).

---

## Design Decisions Made
- **[2026-06-29 | BA]** Documented EVT against its *actual* built behaviour (LMS rule-config CRUD, `lms_` prefix) rather than the `sys_` generic-engine framing, and explicitly separated it from the Accounting acc_* event-voucher engine. FRD scope is the three config entities only; the (absent) execution engine and the Accounting engine are Out of Scope.

## Lessons Learned
- **[2026-06-29 | BA]** EVT module_list says prefix `sys_`, but the code uses `lms_` — always trust the live model `$table` over the registry. The "generic event engine referenced by Accounting" is implemented *inside Accounting* (acc_*), not in `Modules/EventEngine`; the two are unrelated despite the name.
- **[2026-06-29 | BA]** EVT tables have 0 migrations and 0 DDL — a config-CRUD scaffold can be fully coded (controllers/requests/views/policies) yet be non-runnable. Always grep migrations + DDL before asserting completion; "screens exist" ≠ "module works."
- **[2026-06-29 | BA]** EVT was copy-pasted from LmsHomework (stray `Modules\LmsHomework\...` imports and a dangling policy binding) — copy-paste origins leave broken cross-module class references that only fail at runtime.

---

## FRD Summary
- **File:** `4-Requirement_Module_wise/0-FRD_Documents/EVT_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD + RTM + BR/Conditions/Validation + Flows/FSM + Data Dictionary + Dependency Map + NFR/Risk + Prioritization/Estimation + User Stories + Reporting)
- **Date:** 2026-06-29
- **Counts:** REQ = 9 · BR = 18 · Workflows = 3 · Reports (RPT) = 3 · ENH = 7
- **Priority split (REQ):** P0 = 4 · P1 = 3 · P2 = 2

## Pending Next Steps
1. DDL Schema Gap Analysis (DB Architect) — author migrations + DDL for the 3 tables (decide `sys_` vs `lms_` prefix first).
2. Application Code Gap (Technical Auditor, Mode B) — fix EVT-G04 policy binding, EVT-G05 dead index actions, EVT-G06 logic_config.
3. Architecture decision (Enterprise Architect) — should EVT be retired in favour of the Accounting acc_* engine, or built out as a genuine cross-module rule engine? No consumers today.
4. Test Coverage (Testing Architect) — 0 tests currently.

## Version History
- **v1.0 — 2026-06-29 — BA (pa-business-analyst):** Seeded from live code; Complete FRD created. Documented prefix mismatch, missing schema, missing execution engine, broken policy binding, and the EventEngine-vs-Accounting-engine distinction.
- **v1.1 — 2026-06-29 — Technical Auditor (pa-technical-auditor), Mode X:** Re-verified all BA gaps against live code; assigned audit codes (DATA-EVT-001 P0; BUG-EVT-001/002/003/004; DATA-EVT-002/003; DEAD-EVT-001/002; VAL-EVT-001; SEC-EVT-001). Health 18/100 (P0 cap), Deploy NO-GO. Corrected stale D23/SEC-EVT-002 (RSP tenancy is present — module does NOT run on wrong DB; blocker is schema). Confirmed clean D24 taxonomy, no D25, `@can` tab gating. Report: `3-Audit_Reports/V1_Jun-2026/EventEngine_Complete_Audit_2026-06-29.md`.

## Lessons Learned (Technical Auditor)
- **[2026-06-29 | Technical Auditor]** EVT is the textbook "fully coded, zero schema" module: 4 controllers / 3 models / 3 FormRequests / 17 views all present and competent, yet 0 migrations + 0 DDL make every screen 500 on a clean tenant. "Screens exist" ≠ "module runs" — always three-way reconcile (DDL ↔ migration ↔ model) before crediting completion.
- **[2026-06-29 | Technical Auditor]** Snapshot rot cuts both ways: `decisions.md`/`known-issues.md`/`progress.md` all still flagged EVT's RSP as missing tenancy, but the live RSP carries the full stack (fixed since). Live code wins — SEC-EVT-002 marked STALE. A module can be *more* fixed than the brain remembers, not just less.
- **[2026-06-29 | Technical Auditor]** `Gate::policy(Model::class, WrongPolicy::class)` with a non-existent FQCN is a *latent* fatal, not an immediate one: `::class` is a compile-time string with no autoload, and string-ability gates (`Gate::authorize('tenant.x.y')`, spatie) never resolve the model policy — so it lies dormant until someone does `$user->can('update', $model)`. Rate P1 with a P0 escalation condition, not an unconditional P0.
