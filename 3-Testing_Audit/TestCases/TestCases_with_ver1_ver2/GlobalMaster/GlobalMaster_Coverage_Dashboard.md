# GlobalMaster (GLB) — Coverage Dashboard

**Generated:** 2026-Jul-09 · **Mode:** report (module roll-up) · **Scope:** CENTRAL / prime-side (`global_master_mysql` + `prime_db`)
**Registry:** MODULE=`GlobalMaster` CODE=`GLB` PREFIX(hint)=`glb_` FOLDER=`GlobalMaster` DDL=`_global_db_v4.sql`
**Audit baseline:** `GlobalMaster_Complete_Audit_2026-06-29.md` — Health 34/100, Deploy Gate **NO-GO**.

## Per-feature coverage

| # | Feature | Prefix | Type | V1 | V2 | V2÷V1 | Gate ≥2× | Neg | Pos | Dep | `php -l` | Verdict |
|---|---------|--------|------|----|----|-------|:---:|:---:|:---:|:---:|:---:|---------|
| 1 | Country | `glb_` | CRUD master (geo parent) | 16 | 54 | 3.38× | ✅ | 100% | 100% | 100% | ✅ | PASS WITH NOTES |
| 2 | Language | `glb_` | CRUD master | 18 | 65 | 3.61× | ✅ | 100% | 100% | 100% | ✅ | PASS WITH NOTES |
| 3 | Dropdown | `sys_` | CRUD master | 18 | 79 | 4.39× | ✅ | 100% | 100% | 100% | ✅ | PASS WITH NOTES |
| 4 | SessionBoardSetup | `glb_` | Composite hub (read) | 14 | 41 | 2.93× | ✅ | 100% | 100%* | 100%* | ✅ | PASS WITH NOTES |
| 5 | ActivityLog | `sys_` | Read-only report | 16 | 48 | 3.00× | ✅ | 100% | 100%* | 100%* | ✅ | PASS WITH NOTES |
| — | **TOTAL** | — | — | **82** | **287** | **3.50×** | ✅ | — | — | — | ✅ (10/10) | — |

\* Composite/read-only screens use lighter read-focused depth (no create/edit/delete matrix by design); % is over the applicable case set.

## Style / environment (all features)

- **Central browser Dusk pattern** — `namespace Tests\Browser\Modules\Prime\GlobalMaster`, extend the central base (`PrimeDuskTestCase` / `prm_PrimeDuskTestCase_TestCas`, forces host `http://127.0.0.1:8000`), Billing central helpers (`centralUrl`/`authenticateCentral`/`visitAuthenticated`/`resolveAdminUser`), `App\Models\User`, **no tenant init**. (Constraints A4, E21, E22, B5.)
- **Execution prerequisites (documented, not code-fixes):** `GlobalMaster` **and** `Prime` must be `true` in `prime_testing/modules_statuses.json` (both currently `false` → 404 on all routes, E19); `APP_ENV=testing` (E20); central host reachable at `127.0.0.1:8000`; `MAIN_PROJECT_PATH` for file-content asserts. Env-gated cases self-skip so partial environments stay green; the deterministic schema/model/route/source-shape core runs unconditionally.
- **Cross-tenant isolation = N/A** for every feature (single central DB) — recorded as a deliberate documented skip in each V2 (`test_*_90`/`_92`).

## Open DEV / audit-equivalent defects (proving tests attached)

| Defect | Sev | Feature | Reproduced live? | Proving test(s) |
|--------|-----|---------|------------------|-----------------|
| SEC-GLB-001 | P1 | Country | Yes | store/update `$request->all()`; `default_timezone` validated-not-persisted (V1-17/18) |
| BUG-GLB-004 | P1 | Country | Yes | `toggleStatus` cascade omits Cities (V2 test_42, skips if geo chain absent) |
| BUG-GLB-006a | P1 | Language | Yes (live Prime ctrl) | `forceDelete` logs event `'Stored'` (V1-11, V2-17/24) |
| BUG-GLB-006b | P1 | Language | Yes | `update` flashes literal `'update.language'` (V1-07, V2-13) |
| BUG-GLB-006c | P1 | Language | GLB ctrl only | wrong `Language` model import (documented) |
| SEC-GLB-010 | P0 | Language | **NOT reproduced** | live `central.*` route served by Prime ctrl which gates `prime.language.*` (V2 51–57) |
| SEC-GLB-005 | P1 | Language | **NOT reproduced** on central route | prefix mismatch is in the *module* GLB ctrl, not the live central one (documented) |
| VAL-GLB-001 | P1 | Dropdown | Yes | `DropdownRequest` validates 2 of 5 fields; null key/type accepted (V1-05, V2-30/36) |
| BUG-GLB-005 | P1 | Dropdown | Yes (module ctrl) | `dropdown.search` dead route → {404,405,500} (V1-15, V2-48/49/94) |
| BUG-GLB-009 | P2 | Dropdown | Yes | `org_id` absent/ordinal not key-scoped; mislabeled log strings (V2-45/46/19/92) |
| PERF-GLB-001 | P2 | Dropdown | Documented | index N+1 soft-timing probe (V2-69) |
| BUG-GLB-001 | P0 | SessionBoardSetup | **NOT reproduced** | live ctrl imports `Prime\AcademicSession` (exists) + `GlobalMaster\Board` (exists); GLB AcademicSession absent but unreferenced (V1-07, V2-70) |
| DATA-GLB-002 | P1 | SessionBoardSetup | Yes | view reads `$session->is_active` — no such column → null (V1-05, V2-71/72) |
| BUG-GLB-003 | P1 | SessionBoardSetup | Yes | single-current invariant DB-only; `store()` sets nothing (V1-06, V2-73) |
| BUG-GLB-006 (SBS) | P1 | SessionBoardSetup | Yes | `create/show/edit` return missing views → 500; `store/update/destroy` empty stubs (V2-30–35) |
| DUP-controller (SBS) | P1 | SessionBoardSetup | Yes | dual GlobalMaster+Prime `session-board-setup` binding, divergent gates (V1-08, V2-75) |
| BUG-GLB-ALOG-01 | High(SEC) | ActivityLog | Yes | `search()` ungated → audit enumeration (V1-15, V2-53) |
| BUG-GLB-ALOG-02 | Med | ActivityLog | Yes | index `viewAny`-gated but card `@can('view')` → empty page (V1-16, V2-55) |
| BUG-GLB-ALOG-03 / RISK-GLB-008 | Med(ARCH) | ActivityLog | Yes | divergent audit sinks: central `sys_central_activity_logs` vs tenant `sys_activity_logs` (V1-05, V2-42/43) |
| MIG-GLB-001 | P2 | ActivityLog | Yes | dead `activity_logs` migration; real table `sys_activity_logs` (V2-44) |

## Cross-cutting reconciliation (source-verified, HARD RULE 13 — source wins)

The single most important finding across the module: **the live `central.global-master.*` routes are, for several resources, served by `Modules\Prime\` controllers/models, not the `Modules\GlobalMaster\` ones** (root `web.php` imports Prime controllers inside the `central.` domain group; the GlobalMaster module's own `routes/web.php` `global-master.*` group is a duplicate). This means:
- Several audit defects filed against GlobalMaster controllers (SEC-GLB-010, SEC-GLB-005, BUG-GLB-001) **do not reproduce on the live central route** because the Prime twin behaves differently — while the GlobalMaster twin remains latently broken. Each feature's Gap Analysis records which controller actually serves the route and asserts the *live* behaviour.
- The **central audit table is `sys_central_activity_logs`** (Prime `ActivityLog`, conn `mysql`) when tenancy is uninitialized; `sys_activity_logs` (GlobalMaster tenancy-aware model) is written only in tenant context. Country/Dropdown activity-log assertions therefore target the central sink.
- **DUP-WEB-001 (triple route registration)** makes `route:cache` non-deterministic — a module-wide risk.

This dual-registration ambiguity is a genuine codebase defect family, documented per-feature rather than smoothed over.
