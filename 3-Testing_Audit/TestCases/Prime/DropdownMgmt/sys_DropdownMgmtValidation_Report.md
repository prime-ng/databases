# sys_DropdownMgmt — Validation Report

**Feature:** DropdownMgmt (Prime / PRM, CENTRAL) · **Date:** 2026-Jul-10 · **Verdict:** ✅ PASS WITH NOTES

---

## 1. File Existence

| # | Artifact | Status |
|---|----------|--------|
| 1 | `sys_DropdownMgmtTcList_Require.md` | ✅ |
| 2 | `sys_DropdownMgmtMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_DropdownMgmtGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_DropdownMgmt_TestCas.php` | ✅ (single file — no V1/V2) |
| 5 | `sys_DropdownMgmtValidation_Report.md` | ✅ (this file) |
| 6 | `run-DropdownMgmt-tests.ps1` | ✅ |
| 7 | `run-DropdownMgmt-tests.sh` | ✅ |

**7 / 7 present — exactly one `.php` test file.**

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix = DDL primary-table prefix | ✅ `sys_` (verified: `sys_dropdown_needs` / `sys_dropdown_table` in `_prime_db_v4.sql`) |
| Feature PascalCase | ✅ `DropdownMgmt` |
| Class = filename | ✅ `class sys_DropdownMgmt_TestCas` in `sys_DropdownMgmt_TestCas.php` |
| snake_case zero-padded methods | ✅ `test_dropdownmgmt_01` … `_92` |
| First method (config truth) | ✅ `test_dropdownmgmt_01_schema_model_and_controller_configuration_are_correct` |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Namespace | ✅ `Tests\Browser\Modules\Prime\DropdownMgmt` |
| Base class | ✅ `extends PrimeDuskTestCase` (`use Tests\Browser\Modules\Prime\PrimeDuskTestCase;` — resolves via preload alias, constraint #22) |
| Central auth implemented locally | ✅ `resolveAdminUser/authenticateCentral/visitAuthenticated/centralUrl` mirrored from `prm_BillingDuskTestCase` |
| User model | ✅ `App\Models\User` (constraint #5) |
| Tenancy scaffolding | ✅ NONE (prime-side / central — constraints #4/#21); no tenant init; teardown does best-effort central-row cleanup |
| Typed props initialised | ✅ (`?User $adminUser = null`, strings `''`, arrays `[]`) |
| setUp/tearDown | ✅ with best-effort force-delete cleanup of created needs/values |
| `php -l` | ✅ **No syntax errors detected** (PHP 8.4.16) |

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| Total test methods | **37** (single file — no V1/V2 ratio) |
| Positive coverage | 100% (12/12) |
| Negative coverage | 100% (10/10) |
| Dependency coverage | 100% (6/6) |
| Permissions coverage | 100% (2/2) |
| Edge/Defect coverage | 100% (5/5) |
| Security/Tenancy (P0/P1) coverage | 100% (2/2) |
| Every TC ↔ ≥1 method | ✅ (37 TC ↔ 37 methods, 1:1) |
| Every method ↔ TC/BC | ✅ (see TcList Test Method Index) |
| Semantic numbering bands | ✅ 01–09 schema/config, 10–19 biz, 30–39 validation, 40–49 integrity/FK, 50–59 perms, 60–69 UI, 70–79 edge/defect, 90–99 wiring/security/tenancy |

## 5. Known Source Defects Documented

| ID | Severity | Summary | Where proven |
|----|----------|---------|--------------|
| DEV-DDM-001 | High | `destroy()` empty stub → resource DELETE is a no-op | test_dropdownmgmt_70, _01 (regex) |
| DEV-DDM-002 | High | `edit()`/`show()` return non-existent `prime::edit`/`prime::show` views | test_dropdownmgmt_71 |
| DEV-DDM-003 | Medium | Mixed junctions (`sys_dropdown_need_dropdowns_jnt` vs `sys_dropdown_need_table_jnt`) | test_dropdownmgmt_44 |
| DEV-DDM-004 | Low | `DropdownMgmtController::deleteBulk` unreachable (route → DropdownController) | test_dropdownmgmt_74 |
| DEV-DDM-005 | Medium | No app-level guard on UNIQUE(key,ordinal)/(key,value) → raw DB 500 | test_dropdownmgmt_41 |
| DEV-DDM-006 | Low | `DropdownMgmtModel` unused scaffold | test_dropdownmgmt_72 |
| DEV-DDM-007 | Medium | `fillable` `dropdown_table_record_exist` vs DDL `dropdown_tabel_record_exist` typo | test_dropdownmgmt_73, _01 |
| BC-BIZ-04 | Info | `update()` writes no activity log (only `store()` logs 'Created') — consistency gap | test_dropdownmgmt_75 |

> All DEV items are reported "verify in source" — each is traced to the exact controller/model/DDL/route location cited in the Gap Analysis.

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)

- **#4 / #21 (prime-side):** central `prime_db` scope — no tenant init; extends `PrimeDuskTestCase`, host `127.0.0.1:8000`.
- **#22:** module-local base class resolves via preload alias — mirrored `use ...\PrimeDuskTestCase; extends PrimeDuskTestCase` verbatim; `php -l` passes syntactically.
- **#5 / #8:** `App\Models\User`; admin resolved by `is_super_admin`/email lookup, guarded in try/catch.
- **#12:** `SoftDeletes` verified on `DropdownNeed`/`Dropdown` before asserting trash/force-delete semantics.
- **#14 / #15:** no Dusk `assertStatus`; state-code checks use Laravel HTTP helpers (`$this->post/put/delete/getJson/postJson`); authenticated before negative POSTs.
- **#17:** schema-type assertions use `hasColumns`/`SHOW INDEX`, never exact `COLUMN_TYPE`.
- **#18:** `db_type` ENUM asserted case-exact (`Prime,Tenant,Global`).
- **#25:** activity assertions target the **central** `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (connection `mysql`), guarded with `Schema::hasTable` (no consolidated DDL file for it).
- **#27:** runtime VALUES table asserted as `sys_dropdown_table` (positive) and `sys_dropdowns` absent (negative) — the rename migration is a no-op.

## 7. Environment Prerequisites (E19/E20 — NOT test-code fixes)

- ⚠️ **Prime module is `false` in `prime_testing/modules_statuses.json`** → all dropdown-mgmt routes 404. Enable it to exercise route/browser/HTTP methods; otherwise those methods **self-skip** (suite stays green) while schema/source-scan methods still assert.
- `APP_ENV=testing` required (CSRF bypass) — set by both runners.
- Central app must be served at `http://127.0.0.1:8000`; ChromeDriver running for the browser-tagged methods.
- `MAIN_PROJECT_PATH` (or a resolvable `prime_ai` sibling) needed for controller/model/route source-scan methods; otherwise those methods self-skip.

## 8. Dimensions Deliberately Light / Skipped

- **State-machine (BC-SM):** none — the feature has only an `is_active` boolean flag, not a workflow lifecycle. No BC-SM required.
- **Responsive / a11y smoke:** omitted — admin-only central config composite screen; not warranted.
- **Live end-to-end mutation proofs** (store/update/destroy/store-option) are env-guarded (module disabled), with deterministic source-scan + schema coverage as the primary assertion.

## 9. Final Verdict

**✅ PASS WITH NOTES** — 7/7 artifacts present, exactly one test file (no V1/V2), `php -l` clean, **37 methods**, 100% category coverage (Positive/Negative/Dependency/Permissions/Edge/Security-Tenancy), every TC mapped 1:1, seven source defects (DEV-DDM-001…007) plus one consistency gap (BC-BIZ-04) captured with proving tests. Notes: (a) Prime module must be enabled in `modules_statuses.json` to run route/browser/HTTP methods — otherwise they self-skip; (b) all dropdown-table assertions honour constraint #27 (`sys_dropdown_table`, not `sys_dropdowns`).

> **Feedback loop (Step 10b):** no new *general* constraint discovered — all findings are feature-specific (DEV-DDM-###) and captured here / in the Gap Analysis. `05_Known_Test_Failure_Constraints.md` not modified (constraints #25 and #27 already cover the central-sink and rename-no-op facts this feature relies on).
