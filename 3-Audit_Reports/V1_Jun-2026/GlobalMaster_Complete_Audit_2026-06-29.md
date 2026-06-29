# Complete Audit — GlobalMaster (GLB) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

| Field | Value |
|-------|-------|
| Module | GlobalMaster |
| Code / Prefix | GLB / `glb_` (+ owns `prm_plans`, `media`, `activity_logs`; consumes `sys_dropdowns`, `sys_activity_logs`) |
| Layer | **CENTRAL** — `global_master_mysql` → `global_db` (real tables) + default `mysql` → `prime_db` (VIEWs of every `glb_*` table) |
| App dir | `/Users/bkwork/Herd/prime_ai/Modules/GlobalMaster` |
| Baseline | `GLB_FRD_Complete_2026-06-29.md` (15 REQ / 34 BR / 3 RPT) |
| Auditor | Technical Auditor (Mode X) |
| Inputs read | 15 controllers, 12 models, 10 FormRequests, ServiceProvider/RouteServiceProvider, module `routes/web.php`+`api.php`, root `routes/web.php`, 17 migrations, `app/Helpers/activityLog.php` |

---

## Executive Summary

GlobalMaster is the platform's central reference-data control room; its data is consumed by every tenant module, and **the entire platform's audit trail is hard-wired to GLB's `ActivityLog` model via the global `activityLog()` helper** — so defects here have outsized blast radius. The worst finding is a **guaranteed runtime fatal**: both `AcademicSessionController` and `SessionBoardSetupController` import `Modules\GlobalMaster\Models\AcademicSession`, **a class that does not exist in this module** (only `Modules\Prime\Models\AcademicSession` exists) — so REQ-GLB-007 (Academic Sessions) and REQ-GLB-013 (Session-Board Hub) 500 on every request. Compounding it: `LanguageController` leaves `create/store/edit/update` **completely ungated** (any authenticated central user can create/edit languages), `DropdownRequest` validates only 2 of 5 fields so dropdown creation writes null `key`/`type`, three routed methods (`getStatesByCountry`, `dropdown.search`, `activity-log.search`) **do not exist**, and the country-deactivation cascade silently omits cities. **Health: 40/100 (P0-capped).** **Deploy gate: NO-GO.**

---

## Health Score

Weighted layer index (pre-cap) ≈ **34/100**; **hard-capped at 40** is not reached — actual weighted sum sits below it, so reported **Health = 34/100**, and the P0 cap (≤40) is independently in force. Either way the module is **not deployable**. Tenancy (Layer 6) and Queue (Layer 10) score Green only because they are **not applicable** to a central, job-less module — not because they are well-built.

---

## Deploy Gate Verdict (Mode G)

**NO-GO.** Blocking items:
1. **BUG-GLB-001 (P0)** — missing `AcademicSession` model → 2 controllers fatal (REQ-GLB-007, REQ-GLB-013).
2. **SEC-GLB-010 (P0)** — `LanguageController` create/store/edit/update unauthenticated-by-permission (BR-GLB-020).

No GLB-specific committed secrets, no cross-tenant path (central module), no queue/Horizon GLB jobs. The platform-level deploy blockers (queue driver vs Horizon, committed `.env-original`, SEC-RTG-001 seeder routes) are out of GLB scope but still gate the platform. **Route-cache risk:** GLB resources are registered up to **3×** (one `prefix('prime')` group + two identical `prefix('global-master')` groups in root `routes/web.php` at lines 416 & 666 + the module's own `routes/web.php`) — name collisions make `route:cache` non-deterministic (see DUP-WEB-001).

---

## P0 Findings

### [BUG-GLB-001] P0 | Missing `AcademicSession` model — Academic-Session and Session-Board screens 500
- Location: `app/Http/Controllers/AcademicSessionController.php:10,25,44,68,83,123,144,151,166,192` and `app/Http/Controllers/SessionBoardSetupController.php:8,22`
- Evidence:
```php
use Modules\GlobalMaster\Models\AcademicSession;   // class does NOT exist in this module
$academicSessions = AcademicSession::paginate(10);  // SessionBoardSetupController.php:22
$academicSession = AcademicSession::create($request->all()); // AcademicSessionController.php:44
```
  `grep -rl "class AcademicSession"` returns only `Modules/Prime/Models/AcademicSession.php` — there is **no** `Modules/GlobalMaster/Models/AcademicSession.php`. Every routed method (`index/create/store/edit/update/destroy/restore/forceDelete/toggleStatus` + the Session-Board hub `index`) throws `Class "...GlobalMaster\Models\AcademicSession" not found`.
- Why it's a risk: REQ-GLB-007 and REQ-GLB-013 are 100% non-functional at runtime; this is the single most dangerous defect and is invisible to "55% complete" status markers.
- Compounding: even if the class existed, `AcademicSessionController` redirects to `route('central.global-master.academic-session.index')`, but the resource is registered under the `prefix('prime')` group (root `web.php:171`) → name `central.prime.academic-session.*`; the `global-master` name likely does not exist → `RouteNotFoundException` on store/update.
- Fix: create `Modules\GlobalMaster\Models\AcademicSession` (table `glb_academic_sessions`, `$connection='global_master_mysql'`, SoftDeletes, fillable `name,short_name,start_date,end_date,is_current`, cast `is_current`→bool + dates) **or** repoint the controllers at `Modules\Prime\Models\AcademicSession`. Reconcile the redirect route names against the registered group.
- Confidence: High
- Systemic?: module-local (table/model name-resolution class — same family as the `activity_logs` vs `sys_activity_logs` drift). Maps BR-GLB-019.

### [SEC-GLB-010] P0 | `LanguageController` create/store/edit/update have NO authorization
- Location: `app/Http/Controllers/LanguageController.php:29-32` (create), `37-41` (store), `55-59` (edit), `64-68` (update)
- Evidence:
```php
public function create() { return view('globalmaster::language.create'); }          // no Gate
public function store(LanguageRequest $request) { Language::create($request->validated()); ... } // no Gate
public function edit($id) { $language = Language::findOrFail($id); ... }              // no Gate
public function update(LanguageRequest $request, Language $language) { $language->update($request->validated()); ... } // no Gate
```
  `LanguageRequest::authorize()` also returns bare `true` (D30) so there is no defense-in-depth. Any authenticated central user (e.g. Support Staff) can create/edit platform languages.
- Why it's a risk: violates BR-GLB-020 (only authorised users may create/edit a language) and NFR-GLB-005 (100% of methods authorise). Reference data is platform-shared.
- Fix: add `Gate::authorize('prime.language.create')` to create/store and `prime.language.update` to edit/update; make `LanguageRequest::authorize()` return `Gate::allows(...)`.
- Confidence: High
- Systemic?: D30 (FormRequest authorize=true) + Layer 5.1. Distinct from existing **SEC-GLB-005** (which covers the `global-master.*` vs `prime.*` prefix mismatch on the destroy/restore/toggle methods).

---

## P1 Findings

### [SEC-GLB-001] P1 | `$request->all()` mass-assignment — 6 controllers (count corrected from 4)
- Location: `CountryController.php:42,79` · `StateController.php:40,77` · `CityController.php:39,76` · `ModuleController.php:40,88` · `PlanController.php:43,84` · `AcademicSessionController.php:44,83`
- Evidence: `Country::create($request->all());` … `$state->update($request->all());` … `$data = $request->all();` (Plan).
- Why it's a risk: D25 mass-assignment; bypasses BR-GLB-022 (persist only validated fields). The matched FormRequests already exist and `validated()` is one token away (District already does it correctly). No privilege fields on these models → P1 not P0.
- Fix: replace every `$request->all()` with `$request->validated()` (Plan's `update()` already needs `$data` post-processing — derive it from `validated()`).
- Confidence: High · Systemic?: D25. **Updates existing SEC-GLB-001** (live count is 6 controllers, not 4).

### [SEC-GLB-012] P1 | `PlanController::planDetails()` AJAX endpoint has no Gate
- Location: `app/Http/Controllers/PlanController.php:239-251` (route `central.*.plan.details`, root `web.php:226,450`)
- Evidence:
```php
public function planDetails(Plan $plan) {
    $allModules = Module::select('id','name','is_core')->get();
    $plan->load(['modules:id,name,is_core','billingCycle:id,name']);
    return response()->json([...]);   // no Gate::authorize
}
```
- Why it's a risk: any authenticated central user reads plan + bundled-module + pricing data (commercially sensitive per FRD §5.6 "Privacy: Internal"). REQ-GLB-010 AC #4 requires the plan-view permission.
- Fix: add `Gate::authorize('prime.plan.view')` at the top of `planDetails()`.
- Confidence: High · Systemic?: Layer 5.1.

### [BUG-GLB-002] P1 | Current academic session is deletable — wrong column + operator-precedence guard
- Location: `app/Http/Controllers/AcademicSessionController.php:124`
- Evidence:
```php
if (!$academicSession->is_active === true) {   // parses as (!$x) === true; AND glb_academic_sessions has NO is_active column
    $academicSession->delete();
```
  The migration (`2025_10_15_094805_create_academic_sessions_table.php`) creates `is_current`, `start_date`, `end_date`, generated `current_flag` — **no `is_active`**. So `$x` is always null → `!null === true` → always deletes, including the current session.
- Why it's a risk: BR-GLB-009 (current/active session must not be removable) is unenforced. (Existing **DEAD-GLB-002** flagged the `!$x === true` operator bug; this finding adds the wrong-column root cause + the BR-009 enforcement gap.)
- Fix: guard on `is_current` (`if (! $academicSession->is_current) { ... }`) after the model exists; block when current.
- Confidence: High · Systemic?: module-local (DATA-GLB-002 missing column).

### [BUG-GLB-003] P1 | Single-current-session enforcement broken at app layer
- Location: `app/Http/Controllers/AcademicSessionController.php:181-217` (toggleStatus)
- Evidence:
```php
AcademicSession::where('id','<>',$academicSession->id)->update(['is_active'=>false]); // wrong column
$academicSession->is_active = $newStatus;   // never sets is_current
```
- Why it's a risk: BR-GLB-007/008 ("exactly one current; setting current clears others") operate on `is_current` + the DB generated `current_flag` unique index — but the controller reads/writes the non-existent `is_active` and never touches `is_current`. The DB uniqueness can't be satisfied/maintained by this code path; "set current" is effectively a no-op (or errors on the missing column).
- Fix: drive the toggle off `is_current`; clear `is_current` on all other rows then set it on the target (the generated `current_flag` + `uq_acadSessions_currentFlag` then guarantee single-current at the DB).
- Confidence: High · Systemic?: module-local.

### [VAL-GLB-001] P1 | `DropdownRequest` validates 2 of 5 fields → dropdown creation writes null key/type
- Location: `app/Http/Requests/DropdownRequest.php:41-56` + `app/Http/Controllers/DropdownController.php:54-67`
- Evidence:
```php
// DropdownRequest rules() — only 'value' and 'is_active'; unique rule keys off un-submitted inputs:
Rule::unique('sys_dropdowns')->where(fn($q)=>$q->where('key', $this->input('table_name').'.'.$this->input('column_name')))
// DropdownController store() reads keys NOT present in validated():
$data = $request->validated();
Dropdown::create(['org_id'=>$data['org_id'], 'key'=>Str::slug($data['key'],'_'), 'type'=>$data['type'], ...]);
```
  `key`, `type`, `org_id` are never validated, so they are absent from `validated()` → `$data['org_id']`/`['key']`/`['type']` are undefined-array-key accesses → rows inserted with null `key`/`type` (or a PHP warning). The stale `table_name`/`column_name` unique rule keys off `null.null`.
- Why it's a risk: REQ-GLB-011 / BR-GLB-026 (slugified key) and BR-GLB-029 (type in allowed set) are unenforced and creation is effectively broken. The commented-out block above (lines 15-38) was the correct rule set.
- Fix: validate `key` (required|string|max:50), `type` (`Rule::in([...allowed types])`), `org_id`; restore the per-key unique rule on `value`.
- Confidence: High · Systemic?: D30 + Layer 7.3.

### [VAL-GLB-002] P1 | `AcademicSessionRequest` missing date validation
- Location: `app/Http/Requests/AcademicSessionRequest.php:17-33`
- Evidence: rules validate only `name` + `short_name`; no `start_date`, `end_date`, no cross-field `before:end_date`, and `is_current` (merged in `prepareForValidation`) is unvalidated.
- Why it's a risk: BR-GLB-010 (start before end) unenforced; invalid date ranges persist. REQ-GLB-007 AC #2.
- Fix: add `start_date` (required|date), `end_date` (required|date|after:start_date), `is_current` (boolean).
- Confidence: High · Systemic?: module-local.

### [BUG-GLB-004] P1 | Country deactivation cascade omits cities (BR-GLB-001)
- Location: `app/Http/Controllers/CountryController.php:180-219` (toggleStatus)
- Evidence: the transaction cascades `State` (line 189) and `District` (line 195) but never `City`. Deactivating a country leaves its cities active under inactive ancestors.
- Why it's a risk: BR-GLB-001 requires the cascade to reach **all** descendants (states → districts → **cities**) in one transaction. Confirms BUG-010 from the BA hint.
- Fix: inside the same transaction, after collecting district ids, `City::whereIn('district_id', $districtIds)->update(['is_active'=>$status]);`.
- Confidence: High · Systemic?: module-local.

### [SEC-GLB-013] P1 | Activity log written before guards/success (BR-GLB-005)
- Location: `StateController.php:197` (before parent-active check at 201) · `AcademicSessionController.php:201` (before `save()` at 204) · several `toggleStatus` paths
- Evidence (State):
```php
activityLog($state,'Toggled',[...]);          // line 197 — logged unconditionally
if (!$countryIsActive && $newStatus) { return ... 'success'=>false ... }  // line 201 — blocked AFTER logging
```
- Why it's a risk: a **blocked** toggle still writes a success audit entry → BR-GLB-005 (log only after guards pass and the action succeeds) violated; audit trail is unreliable.
- Fix: move `activityLog()` to after the guard passes and the `save()` succeeds.
- Confidence: High · Systemic?: module-local pattern across toggles.

### [BUG-GLB-005] P1 | Three routed methods do not exist → 500 on call
- Location: route → missing method:
  - `root web.php:236,460` `get-states/{countryId}` → `StateController::getStatesByCountry` — **method absent** (`grep -c` = 0). Breaks REQ-GLB-002 AC #3 (states-by-country dependent dropdown).
  - `root web.php:269` `dropdown/search` → `DropdownController::search` — **absent**.
  - `root web.php:263` `activity-log/search` → `ActivityLogController::search` — **absent**.
- Why it's a risk: any hit on these endpoints throws; the geography cascading selector (a core onboarding UX) is dead. Confirms RT-004/005/006.
- Fix: implement the three methods (the `GeographySetupController::search` at line 132 is a working template for the two search endpoints).
- Confidence: High · Systemic?: Layer 4.1.

### [BUG-GLB-006] P1 | `LanguageController` imports the wrong `Language` model + mislabeled log/flash
- Location: `app/Http/Controllers/LanguageController.php:9,67,119`
- Evidence:
```php
use Modules\Prime\Models\Language;     // should be Modules\GlobalMaster\Models\Language
...->with('success', 'update.language');           // line 67 — raw string, flash() not called
activityLog($language, 'Stored', [...permanently deleted...]); // line 119 — event mislabeled 'Stored' on forceDelete
```
- Why it's a risk: GLB has its own `Language` model (`app/Models/Language.php`); using Prime's couples the module across boundaries and may bind to a different table/connection. The mislabeled event corrupts the audit trail (BR-GLB-031); the raw flash key shows an untranslated literal.
- Fix: import `Modules\GlobalMaster\Models\Language`; wrap line 67 in `flash('updated.language')`; correct the forceDelete event to `'Deleted'`.
- Confidence: High · Systemic?: module-local (distinct from SEC-GLB-005 prefix mismatch).

---

## P2 Findings

### [BUG-GLB-007] P2 | `DistrictController::forceDelete` uses the deactivate permission (BR-GLB-021)
- Location: `app/Http/Controllers/DistrictController.php:162` — `Gate::authorize('prime.district.delete')` (peers use `…forceDelete`).
- Why: BR-GLB-021 — permanent removal must use the dedicated `remove`/`forceDelete` permission, never `delete`. Fix: `prime.district.forceDelete`. Confidence: High.

### [BUG-GLB-008] P2 | Duplicate `activityLog()` writes per update
- Location: `StateController.php:97-107` **and** `:111`; `ModuleController.php:113-123` **and** `:127`.
- Why: each update writes two audit rows (one structured, one boilerplate) → duplicate/inconsistent audit trail. Fix: remove the second boilerplate call. Confidence: High.

### [VAL-GLB-003] P2 | `ModuleRequest` type + business-rule gaps
- Location: `app/Http/Requests/ModuleRequest.php:23,34`
- Evidence: `is_sub_module => ['nullable','string','max:50']` (should be `boolean`); no rule enforcing **sub-module ⇒ parent_id present** (BR-GLB-012); `Rule::unique('glb_modules')` defaults to the `name` column → name is globally unique, **contradicting BR-GLB-017** (uniqueness is on `(parent_id, name, version)`; a new version must be a new record — the migration's `uq_module_parentId_name_version` already models this).
- Fix: cast `is_sub_module` boolean; add `parent_id required_if:is_sub_module,true`; replace the name-unique rule with a composite unique scoped to `parent_id` + `version`. Confidence: High.

### [PERF-GLB-002] P2 | Unbounded geography loads on list/workspace screens
- Location: `GeographySetupController.php:73-74` (`Country::has('states')->with('states')->get()` + `…with(['states','states.districts'])->get()` every request); `StateController.php:21` (`Country::has('states')->with('states')->get()`); `DistrictController.php:21-23` (full country→state→district tree, unpaginated).
- Why: full reference tree materialised per request; grows with geography. NFR-GLB-001 (always paginate). Fix: paginate / cache (ENH-GLB-008). Confidence: High. (Existing **PERF-GLB-001** already covers the Dropdown index N+1.)

### [SEC-GLB-014] P2 | Search inputs unescaped + no rate limiting (BR-GLB-023/024)
- Location: `GeographySetupController.php:47,54,61,68,142-148`; intended Dropdown/ActivityLog search.
- Why: `LIKE "%{$search}%"` with no `addcslashes` of `%`/`_`; no `throttle` middleware on search/AJAX. BR-GLB-023/024, NFR-GLB-007. Fix: escape LIKE wildcards; add `throttle:60,1`. Confidence: Medium.

### [BUG-GLB-009] P2 | Dropdown `org_id` and ordinal semantics
- Location: `DropdownController.php:57,61-62`
- Evidence: `Dropdown::where('org_id', auth()->user()->id)->max('ordinal')` — `org_id` set to the **user id**; ordinal computed per-org, not per-key (BR-GLB-028 wants sort order within the key group). Also destroy/restore/forceDelete log `'A new module...'` and use `flash('trashed.module')` etc. (copy-paste, lines 115/118/140/143/155/158).
- Fix: stop conflating user id with `org_id`; scope max(ordinal) to the `key`; correct the log/flash strings. Confidence: High.

### [DATA-GLB-001] P2 | Schema/name drift across the three sources
- Location: live migrations vs `0-DDL_Masters/global_db_v4.sql` vs models.
- Evidence: `glb_menu_module_jnt` (migration `2025_12_05_..._create_menu_modules_table.php` + `Module::menus()`) vs **`glb_menu_model_jnt`** (DDL master); `glb_module_plan_jnt` (live, prime_db) vs **`prm_module_plan_jnt`** (V2/DDL); `Dropdown` model → `sys_dropdowns` vs V2 `sys_dropdown_table`.
- Why: DDL master and code disagree → migrations generated from the master would create the wrong table; future schema work is error-prone. Fix: reconcile the master to the live names (live wins). Confidence: High. Systemic?: same drift family as MIG-GLB-001.

### [DATA-GLB-002] P2 | `glb_academic_sessions` lacks `is_active` though code reads/writes it
- Location: migration `2025_10_15_094805_...:19-29`; consumed at `AcademicSessionController.php:124,192,197`.
- Why: column absent (only `is_current` + generated `current_flag`); every `is_active` reference is against a phantom column → root cause of BUG-GLB-002/003. Fix: either add `is_active` or migrate all logic to `is_current` (preferred — the FRD's "current" concept is `is_current`). Confidence: High.

### [MIG-GLB-001] P2 | Dead `activity_logs` migration (table never used)
- Location: `database/migrations/2025_11_02_071024_create_activity_logs_table.php:13` creates table `activity_logs`, but `ActivityLog` model + the `activityLog()` helper target `sys_activity_logs`.
- Why: a superseded migration ships a table no code uses → schema clutter + confusion; also a near-duplicate central migration `database/migrations/2026_02_15_071024_create_activity_logs_table.php` exists. Fix: remove/redirect the dead migration; confirm `sys_activity_logs` is the single audit table. Confidence: High.

### [ARCH-GLB-001] P2 | No service layer + platform-wide audit coupling
- Location: module has **0** `Services/`; all logic in controllers. `app/Helpers/activityLog.php:4` `use Modules\GlobalMaster\Models\ActivityLog;`.
- Why: the global `activityLog()` helper — called by **every module** — hard-imports GLB's `ActivityLog`. If GLB's model is renamed/moved/broken, platform-wide auditing fails (RISK-GLB-008, ARCH-006). The missing-AcademicSession class shows how fragile name-resolution coupling is here. Fix: extract GeographyService/ModulePlanService/DropdownService; consider binding the audit writer behind an interface so the helper does not depend on a specific module's concrete class. Confidence: High.

---

## P3 Findings

### [DEAD-GLB-003] P3 | Repo clutter / dead code
- `Modules/GlobalMaster/Models/Dropdown.php.bkk` backup + a rogue duplicate `Dropdown.php` (uses stale `sys_dropdown_table`); stale `use App\Models\V1\GlobalMaster\{District,State};` imports in `CountryController.php:6-7`; GLB `NotificationController` (`testNotification`/`allNotifications`) is **unrouted** (root `web.php` wires Prime's NotificationController) → dead code, not an auth hole; `GlobalMasterController`/`OrganizationController`/`SessionBoardSetupController` store/update/destroy are empty `{}` stubs (per guardrail, empty bodies are not auth findings). Fix: delete the backup/duplicate/stale imports; remove or route the dead controllers.

### [DATA-GLB-003] P3 | `organization_academic_sessions` naming + reversibility
- `database/migrations/2025_10_18_101401_make_organization_academic_sessions_table.php:13` creates an **un-prefixed** table; `down()` is empty (`//`, irreversible); the single-current unique index is commented out (line 28) so org-session uniqueness is unenforced. `sch_board_organization_jnt` is also a `sch_*` junction defined **inside GLB** (module-boundary smell). Fix: prefix the table, implement `down()`, decide on the uniqueness index, relocate the `sch_*` junction to SchoolSetup.

### [ORM-GLB-001] P3 | Model hygiene
- `Country.php` has no `$casts` (`is_active` returned as `"0"`/`"1"` — truthy-in-Blade hazard); connection inconsistency across geography models (Country: none; District: commented-out; State/City/Board/Module/Language: `global_master_mysql`) — works only because of the prime_db VIEWs; `Media` model is an empty shell. Fix: add `$casts=['is_active'=>'boolean']`; standardise `$connection`.

### Convention (P3)
- **0 of the `glb_*` migrations declare `created_by`** (DBM-001) — creator attribution relies solely on the activity log. Consider adding `created_by` per platform convention (D33/D34).

---

## Layer Health Summary

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | 🟡 Amber | No `created_by` anywhere; `glb_academic_sessions` missing `is_active`; name drift; un-prefixed `organization_academic_sessions`. *(generated `current_flag` is correctly a real STORED column — D36-compliant)* |
| 2 Migration↔Model↔DDL | 🔴 Red | Missing `AcademicSession` model (BUG-GLB-001); dead `activity_logs` migration (MIG-GLB-001); `glb_menu_module_jnt`/`glb_menu_model_jnt` drift (DATA-GLB-001) |
| 3 Model & ORM | 🟡 Amber | Country no casts; connection inconsistency; rogue duplicate Dropdown model (ORM-GLB-001, DEAD-GLB-003) |
| 4 Code Quality | 🔴 Red | Stub controllers; triple-registered routes (DUP-WEB-001); 3 routed-but-missing methods (BUG-GLB-005); copy-paste log labels; `.bkk` backup; no service layer |
| 5 Authorization | 🔴 Red | Language create/edit unauthenticated (SEC-GLB-010, P0); `planDetails` ungated (SEC-GLB-012); prefix mismatch (SEC-GLB-005) |
| 6 Multi-Tenancy | 🟢 Green (N/A) | Central module on `global_master_mysql`+`prime_db` — correctly has **no** `InitializeTenancyByDomain` (guardrail #2). No cross-tenant path |
| 7 Validation/Mass-assign | 🔴 Red | `$request->all()` ×6 (SEC-GLB-001); DropdownRequest broken (VAL-GLB-001); AcademicSession missing date rules (VAL-GLB-002); all 10 FormRequests `authorize(){return true;}` (D30) |
| 8 Data Integrity/Tx | 🔴 Red | Cascade omits cities (BUG-GLB-004); single-current broken (BUG-GLB-003); current session deletable (BUG-GLB-002); module/plan create+attach not transactional |
| 9 Performance | 🟡 Amber | N+1 dropdown index (PERF-GLB-001); unbounded geography loads (PERF-GLB-002); no reference-data caching |
| 10 Queue/Job | 🟢 Green (N/A) | No jobs/schedulers in module |
| 11 Frontend/Blade | 🟡 Amber | Not deep-audited; server-side LIKE search unescaped (SEC-GLB-014). 55 blades — recommend a Layer-11 pass |
| 12 Deployment | 🟡 Amber | Triple route registration → `route:cache` non-determinism; no GLB secrets; central |

---

## STEP 1 Reading-Discipline Output (three-way reconcile + snapshot corrections)

| Item | DDL master (`global_db_v4.sql`) | Live migration | Model | Verdict |
|------|----------------------------------|----------------|-------|---------|
| Menu↔Module junction | `glb_menu_model_jnt` | `glb_menu_module_jnt` | `Module::menus()` → `glb_menu_module_jnt` | **Master is wrong**; live name wins (DATA-GLB-001) |
| Module↔Plan junction | `prm_module_plan_jnt` (V2) | `glb_module_plan_jnt` (prime_db) | `Plan::modules()` → `{primeDb}.glb_module_plan_jnt` | live name `glb_module_plan_jnt` |
| Academic session active flag | — | `is_current` + generated `current_flag` (no `is_active`) | controller reads `is_active` | **column absent** (DATA-GLB-002) |
| Audit table | `sys_activity_logs` | `activity_logs` (dead) + `sys_activity_logs` (central) | `ActivityLog`→`sys_activity_logs` | dead migration (MIG-GLB-001) |
| AcademicSession model | n/a | table exists | **model absent in GLB** | BUG-GLB-001 |
| `glb_languages` timestamps/deleted_at | present | present | present | V2 DBM-002 **stale/resolved** — confirmed live |

**Snapshot corrections vs module-knowledge / BA hints (live wins):**
- BA hint "`ModuleController::show()` uses `prime.module.create` + returns `module.edit` view" is **STALE** — live `ModuleController.php:63-67` uses `prime.module.view` and returns `module.show`. Existing **BUG-PRM-014** is resolved; not re-reported.
- BA hint "zero-auth stub controllers (GlobalMaster/Organization 7 methods each)" — their `store/update/destroy` are empty `{}` (guardrail: not auth holes); their `index/create/edit/show` lack Gate but render generic placeholder views → downgraded to P3 (DEAD-GLB-003), not P0.
- "$request->all() in 12 places" (progress.md) — live count is **6 controllers × 2 = 12 call-sites across store+update**; the controller count is 6.

---

## FRD Gap Summary (Mode B) — REQ → Code/DDL/Test status

| REQ | Feature | DDL | Code | Test | Status | Blocking finding |
|-----|---------|-----|------|------|--------|------------------|
| REQ-GLB-001 | Country | ✅ | ⚠ | unit only | PARTIAL | SEC-GLB-001, BUG-GLB-004 |
| REQ-GLB-002 | State | ✅ | ⚠ | unit only | PARTIAL | SEC-GLB-001, BUG-GLB-005 (getStatesByCountry missing) |
| REQ-GLB-003 | District | ✅ | ✅ (uses validated()) | unit only | PARTIAL | BUG-GLB-007 |
| REQ-GLB-004 | City | ✅ | ⚠ | unit only | PARTIAL | SEC-GLB-001; toggleStatus has no parent check (BR-GLB-002) |
| REQ-GLB-005 | Geography Workspace | n/a | ⚠ | — | PARTIAL | SEC-GLB-014, PERF-GLB-002 |
| REQ-GLB-006 | Board | ✅ | ⚠ | BoardTest | PARTIAL | board CRUD via Prime; trash routes thin |
| REQ-GLB-007 | Academic Session | ✅ (no is_active) | ❌ | — | **BROKEN** | **BUG-GLB-001 (P0)**, BUG-GLB-002/003, VAL-GLB-002 |
| REQ-GLB-008 | Language | ✅ | ❌ auth | — | **BROKEN/INSECURE** | **SEC-GLB-010 (P0)**, BUG-GLB-006 |
| REQ-GLB-009 | Module Registry | ✅ | ⚠ | — | PARTIAL | SEC-GLB-001, VAL-GLB-003, BUG-GLB-008 |
| REQ-GLB-010 | Plan | ✅ (no price_quarterly) | ⚠ | — | PARTIAL | SEC-GLB-001, SEC-GLB-012 |
| REQ-GLB-011 | Dropdown | consumes `sys_dropdowns` | ⚠ | — | PARTIAL | VAL-GLB-001, PERF-GLB-001, BUG-GLB-009 |
| REQ-GLB-012 | Activity Log | ✅ | ⚠ | — | PARTIAL | list works; filters/export pending; stub CRUD (BR-GLB-030 affordance smell) |
| REQ-GLB-013 | Session-Board Hub | n/a | ❌ | — | **BROKEN** | **BUG-GLB-001 (P0)** (uses missing model) |
| REQ-GLB-014 | Translation | ✅ table | ❌ | — | NOT STARTED | no model/controller/views |
| REQ-GLB-015 | Reference API | n/a | ❌ | — | NOT STARTED | empty `globalmasters` apiResource stub |

Tests: 4 **unit** files only (`ArchitectureTest, BoardTest, ControllerAuthTest, ModelStructureTest`); **0 Feature/HTTP/security** tests — none would catch BUG-GLB-001 at the HTTP layer.

---

## Business-Rule Enforcement (Mode C)

| BR | Summary | Status | Location / linked finding |
|----|---------|--------|---------------------------|
| BR-GLB-001 | Country deactivation cascades to cities | **MISSING** | CountryController:180-219 — omits cities → BUG-GLB-004 |
| BR-GLB-002 | No reactivate while parent inactive | PARTIAL | State ✅(line201), District ✅(line198), **City ❌** (no parent check) |
| BR-GLB-003 | No remove while children exist | PARTIAL | FK RESTRICT enforces at DB; controllers lack a friendly pre-check (Country forceDelete has no try/catch → raw 500) |
| BR-GLB-004 | Name unique within parent | ENFORCED | migration `unique(country_id,name)` / `(state_id,name)` + FormRequests |
| BR-GLB-005 | Log only after success | **MISSING** | toggles log before guards → SEC-GLB-013 |
| BR-GLB-006 | Soft-delete lifecycle | ENFORCED | SoftDeletes + trash/restore/forceDelete present |
| BR-GLB-007 | One current session | PARTIAL (DB only) | generated `current_flag`+unique index ✅ at DB; **app never sets is_current** → BUG-GLB-003 |
| BR-GLB-008 | Set current clears others | **MISSING** (app) | BUG-GLB-003 |
| BR-GLB-009 | Current session not removable | **MISSING** | BUG-GLB-002 |
| BR-GLB-010 | Start before end | **MISSING** | VAL-GLB-002 |
| BR-GLB-011 | Plan ≥1 module | ENFORCED | PlanRequest `module_ids` required|array|min:1 |
| BR-GLB-012 | Sub-module needs parent | **MISSING** | VAL-GLB-003 (no parent rule; is_sub_module typed string) |
| BR-GLB-013 | Standard boards seeded | N/V | LanguageSeeder only; no board seeder verified |
| BR-GLB-014 | Affiliated board not removable | PARTIAL | FK RESTRICT only |
| BR-GLB-015 | Currency ISO-3, trial 1–30 | ENFORCED | PlanRequest `currency size:3`, `trial_days min:1 max:30` |
| BR-GLB-016 | Language direction LTR/RTL | ENFORCED | LanguageRequest `Rule::in(['LTR','RTL'])` |
| BR-GLB-017 | Module unique (parent,name,version) | PARTIAL/CONFLICT | migration `uq_module_parentId_name_version` ✅; FormRequest enforces **name-only** unique → VAL-GLB-003 |
| BR-GLB-018 | Permission-availability flags | ENFORCED | ModuleRequest 7 boolean flags |
| BR-GLB-019 | Session record type must exist | **MISSING** | BUG-GLB-001 |
| BR-GLB-020 | Language create/edit needs permission | **MISSING** | SEC-GLB-010 (P0) |
| BR-GLB-021 | Remove uses remove permission | PARTIAL | District forceDelete uses `delete` perm → BUG-GLB-007 |
| BR-GLB-022 | Save only validated fields | **MISSING** (6 ctrl) | SEC-GLB-001 |
| BR-GLB-023 | Sanitise search text | **MISSING** | SEC-GLB-014 |
| BR-GLB-024 | Rate-limit search/lookup | **MISSING** | SEC-GLB-014 |
| BR-GLB-025 | Billing cycle from list | PARTIAL | store uses `billing_cycle_id` exists-rule ✅; update has hardcoded `$cycleMap` (PlanController:87-97) → fragile |
| BR-GLB-026 | Slugify dropdown key | PARTIAL | `Str::slug($data['key'],'_')` ✅ but key unvalidated/undefined → VAL-GLB-001 |
| BR-GLB-027 | Comma values de-duplicated | ENFORCED | `array_unique(array_filter(...explode))` |
| BR-GLB-028 | Maintain sort order in key | **MISSING** | ordinal computed per-org not per-key → BUG-GLB-009 |
| BR-GLB-029 | Dropdown type in allowed set | **MISSING** | type unvalidated → VAL-GLB-001 |
| BR-GLB-030 | Log append-only in UI | PARTIAL | ActivityLog index read-only ✅, but create/edit/update/destroy routes+methods exist (stub) — affordance smell |
| BR-GLB-031 | Log captures actor/event/record/time | ENFORCED | `activityLog()` helper records all; but mislabeled events (BUG-GLB-006) degrade quality |
| BR-GLB-032/033/034 | Translation rules | NOT STARTED | REQ-GLB-014 unbuilt |

---

## Systemic-Pattern Scorecard (Mode D, scoped to GLB)

| Pattern | Present? | Count / detail |
|---------|----------|----------------|
| D17 (fillable/casts vs columns) | **Yes** | `is_active` referenced but absent on `glb_academic_sessions`; Country no casts |
| D24 (permission-prefix chaos/typos) | **Yes** | Language mixes `prime.*` and `global-master.*` (SEC-GLB-005) |
| D25 (`$request->all()`) | **Yes** | 6 controllers / 12 call-sites (SEC-GLB-001) |
| D29 (`->enum()` in migrations) | **No** | `grep '->enum('` on GLB migrations = 0 (global_db tables clean) |
| D30 (FormRequest `authorize(){return true;}`) | **Yes** | **10 / 10** FormRequests |
| D36 (generated columns degraded) | **No (compliant)** | `glb_academic_sessions.current_flag` is a correct `GENERATED ALWAYS … STORED` column |
| Layer 2.5 (cross-DB / missing FK target) | **N/A** | Central; cross-DB handled by the documented "create in global_db → VIEW into prime_db" idiom + DB-qualified pivots |
| Layer 6.2 (initialize leak) | **No** | No `tenancy()->initialize()` in module (central) |
| Layer 10.1 (job tenancy) | **N/A** | No jobs |
| TEN-RTG-001 (module-subscription middleware) | **N/A** | Central module |
| DUP-WEB (route duplication) | **Yes** | GLB resources registered up to 3× (DUP-WEB-001) |

---

## vs Platform Baseline

- **D30:** 10/10 FormRequests return bare `true` (100% vs platform 90%) — slightly worse than the norm.
- **D25:** 6 controllers / 12 sites — GLB is named in the baseline as one of the heaviest `$request->all()` offenders; confirmed.
- **D29:** 0 enums in GLB migrations — **better** than the platform (~476 total).
- **D36:** GLB's one generated column is correct — **better** than the platform (1/19 correct overall).
- **Write controllers with zero authz:** Language create/edit + planDetails are real (not scaffold) — contributes to the platform's 64-controller tally.
- **Tenancy:** N/A (central) — not a Layer-6 risk, unlike most modules.

---

## Recommended Fix Order (unblock-the-most-first)

1. **BUG-GLB-001 (P0)** — create/repoint `AcademicSession` model + fix redirect route names → unblocks REQ-GLB-007 **and** REQ-GLB-013.
2. **SEC-GLB-010 (P0)** — add the 4 missing Gates to LanguageController; also fix BUG-GLB-006 (wrong model import) in the same pass.
3. **SEC-GLB-001 (P1)** — `$request->all()` → `validated()` across the 6 controllers (mechanical).
4. **VAL-GLB-001 (P1)** — restore the real DropdownRequest rules (key/type/org_id) → unbreaks dropdown creation.
5. **BUG-GLB-002/003 + DATA-GLB-002 (P1/P2)** — migrate academic-session logic from phantom `is_active` to `is_current`; enforce BR-GLB-007/008/009.
6. **BUG-GLB-004 (P1)** — extend country cascade to cities.
7. **BUG-GLB-005 (P1)** — implement `getStatesByCountry` + 2 search methods.
8. **SEC-GLB-012 / SEC-GLB-013 / VAL-GLB-002 (P1)** — planDetails gate; log-after-guard; session date rules.
9. **P2 batch** — BUG-GLB-007/008/009, VAL-GLB-003, PERF-GLB-002, SEC-GLB-014, DATA-GLB-001, MIG-GLB-001, route de-duplication.
10. **P3 + tests** — DEAD-GLB-003, DATA-GLB-003, ORM-GLB-001; add Feature/HTTP/security tests (would have caught BUG-GLB-001).

---

## Issue Codes Assigned (this report)

| Code | Sev | Title |
|------|-----|-------|
| BUG-GLB-001 | P0 | Missing AcademicSession model → 2 controllers fatal |
| SEC-GLB-010 | P0 | LanguageController create/edit unauthenticated |
| SEC-GLB-001 *(updated)* | P1 | `$request->all()` — now 6 controllers |
| SEC-GLB-012 | P1 | planDetails AJAX ungated |
| BUG-GLB-002 | P1 | Current session deletable (wrong column + precedence) |
| BUG-GLB-003 | P1 | Single-current enforcement broken at app layer |
| VAL-GLB-001 | P1 | DropdownRequest validates 2/5 fields → null key/type |
| VAL-GLB-002 | P1 | AcademicSessionRequest missing date rules |
| BUG-GLB-004 | P1 | Country cascade omits cities |
| SEC-GLB-013 | P1 | Activity log written before guards |
| BUG-GLB-005 | P1 | 3 routed methods missing (getStatesByCountry, 2× search) |
| BUG-GLB-006 | P1 | LanguageController wrong model import + mislabeled log |
| BUG-GLB-007 | P2 | District forceDelete uses delete permission |
| BUG-GLB-008 | P2 | Duplicate activityLog() in State/Module update |
| VAL-GLB-003 | P2 | ModuleRequest type + BR-012/017 gaps |
| PERF-GLB-002 | P2 | Unbounded geography loads |
| SEC-GLB-014 | P2 | Unescaped LIKE search + no rate limit |
| BUG-GLB-009 | P2 | Dropdown org_id/ordinal semantics + wrong log strings |
| DATA-GLB-001 | P2 | Schema/name drift (3 sources) |
| DATA-GLB-002 | P2 | glb_academic_sessions missing is_active |
| MIG-GLB-001 | P2 | Dead activity_logs migration |
| ARCH-GLB-001 | P2 | No service layer + platform audit coupling |
| DEAD-GLB-003 | P3 | Backup/rogue model, stale imports, unrouted controller |
| DATA-GLB-003 | P3 | Un-prefixed organization_academic_sessions + empty down() |
| ORM-GLB-001 | P3 | Country no casts; connection inconsistency |

**Severity totals (new + updated, de-duplicated):** P0 = **2** · P1 = **10** · P2 = **10** · P3 = **3**. Pre-existing GLB codes referenced (not re-counted): SEC-GLB-005, DEAD-GLB-002, PERF-GLB-001, DUP-WEB-001, BUG-PRM-014 (resolved).
