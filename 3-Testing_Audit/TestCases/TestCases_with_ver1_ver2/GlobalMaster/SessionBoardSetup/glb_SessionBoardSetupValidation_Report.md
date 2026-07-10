# glb_SessionBoardSetup — Validation Report

**Feature:** GlobalMaster :: Session & Board Setup (composite, read-only, partly-broken hub)
**Generated:** 2026-Jul-09
**DB scope:** CENTRAL / prime-side (`global_master` DB, connection `global_master_mysql`)

---

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | glb_SessionBoardSetupTcList_Require.md | ✅ |
| 2 | glb_SessionBoardSetupMANUALTESTING_Require.md | ✅ |
| 3 | glb_SessionBoardSetupGAPANALYSIS_Require.md | ✅ |
| 4 | glb_SessionBoardSetupV1_TestCas.php | ✅ |
| 5 | glb_SessionBoardSetupV2_TestCas.php | ✅ |
| 6 | glb_SessionBoardSetupValidation_Report.md | ✅ (this file) |
| 7 | run-SessionBoardSetup-tests.ps1 | ✅ |
| 8 | run-SessionBoardSetup-tests.sh | ✅ |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix = DDL primary-table prefix (`glb_`) | ✅ verified against `_global_db_v4.sql` (`glb_academic_sessions`, `glb_boards`) |
| Feature PascalCase (`SessionBoardSetup`) | ✅ |
| PHP class name = filename | ✅ `glb_SessionBoardSetupV1_TestCas`, `glb_SessionBoardSetupV2_TestCas` |
| Test methods snake_case, semantic bands | ✅ `test_sessionboardsetup_NN_*` |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Namespace | ✅ `Tests\Browser\Modules\Prime\GlobalMaster` |
| Base class | ✅ `extends PrimeDuskTestCase` (physical `prm_PrimeDuskTestCase_TestCas`, resolved via preload class_alias) |
| Host discipline | ✅ inherits `primeBaseUrl = http://127.0.0.1:8000`; base fails setUp() off-host (constraint E21) |
| Typed properties initialised | ✅ `?User $adminUser = null`, string props `= ''` |
| setUp/tearDown | ✅ no tenant init (CENTRAL); guarded admin resolve |
| `php -l` | ✅ clean on V1 and V2 |

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| V1 methods | **14** |
| V2 methods | **41** |
| V2 ≥ 2× V1 | ✅ 41 ≥ 28 (ratio 2.93×) |
| Every TC ↔ ≥1 method | ✅ (25 TCs mapped) |
| Every method ↔ TC/BC | ✅ (V2 Method Index) |
| Positive coverage | 100% |
| Negative/Auth coverage | 100% |
| Dependency/Defect coverage | 100% |
| Semantic numbering bands | ✅ 01-09 schema/config, 10-19 biz, 30-39 broken-write, 40-49 integration, 50-59 auth, 60-69 UI, 70-79 defects, 90-99 security/tenancy |

## 5. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)

| Constraint | How applied |
|-----------|-------------|
| A4 prime vs tenant | CENTRAL feature → **no** tenant scaffolding; uses `global_master_mysql` connection |
| B5 `App\Models\User` | ✅ used for admin resolve (runner has it) |
| C12 SoftDeletes guard | ✅ `usesSoftDeletes()` reflection guard before any trait-dependent assumption |
| C13 typed props init | ✅ |
| D14 no `Browser::assertStatus` | ✅ status/registration checked via `Route::has` + source shape; no browser status assertions |
| C17 MySQL8 type variance | ✅ `assertStringContainsString`/substring checks on column types |
| E19 module enabled | ✅ documented prerequisite (below); route-live cases self-skip |
| E20 APP_ENV=testing | ✅ runners set it |
| E21 central host 127.0.0.1 | ✅ extends PrimeDuskTestCase which enforces it |
| E22 preload alias base class | ✅ `use Tests\Browser\Modules\Prime\PrimeDuskTestCase;` mirrors Billing sibling |
| Cross-module defensive skip | ✅ `organizations()` relationship wrapped in try/catch → markTestSkipped |

## 6. Environment Prerequisites (must hold for the browser/route-live cases to execute)

1. **`prime_testing/modules_statuses.json`: `GlobalMaster` AND `Prime` = `true`.** Both are currently `false` → every route 404s; route-live and browser tests self-skip until enabled. (This is an environment prerequisite, NOT a test-code fix.)
2. `APP_ENV=testing` (CSRF bypass; set by both runners).
3. Chrome + ChromeDriver serving the central app at `http://127.0.0.1:8000`.
4. `MAIN_PROJECT_PATH` (or `../prime_ai`) resolvable — source-shape and migration-file assertions read the app checkout; otherwise they self-skip.
5. `global_master_mysql` connection configured in the runner for schema/index introspection.

## 7. Known Source Defects Documented

| ID | Where documented | Proving test |
|----|------------------|--------------|
| BUG-GLB-001 (reconciled — NOT reproduced) | TcList §4, Gap §4 | V1 test_07, V2 test_70 |
| DATA-GLB-002 (phantom is_active) | TcList §4, Manual §2 | V1 test_05, V2 test_71/72 |
| BUG-GLB-003 (single-current DB-only) | TcList §4 | V1 test_06, V2 test_73 |
| BUG-GLB-004 (view route-name mismatch) | TcList §4, Gap §4 | V2 test_74/76 |
| BUG-GLB-005 (dual controller collision) | TcList §4, Gap §4 | V1 test_08, V2 test_75 |
| BUG-GLB-006 (missing views + empty stubs) | TcList §4, Manual §2 | V1 test_09, V2 test_30-35 |

## 8. Deliberately Skipped Dimensions (recorded per prompt)

- **No CRUD matrix** — write surface is non-functional (empty stubs + missing views); proven, not exercised.
- **No state-machine band (20-29)** — no workflow lifecycle; the single-current invariant is a DB constraint, covered under BC-EDG-03.
- **No FormRequest/validation band beyond source** — no FormRequest exists for this screen.
- **Cross-tenant isolation (TC-T)** — N/A for a CENTRAL single-DB feature; documented skip (V2 test_92).

## 9. Final Verdict

**PASS WITH NOTES.**

All 8 artifacts present; naming/structure/coverage gates met; `php -l` clean; V2 = 2.93× V1; all 6 documented defects carry proving tests; BUG-GLB-001 reconciled against live source (audit-predicted 500 does not reproduce — the GlobalMaster controller imports the existing `Modules\Prime\Models\AcademicSession`). **Notes:** live browser/403/route-registration assertions are environment-gated and self-skip until GlobalMaster + Prime are enabled in `modules_statuses.json`; the deterministic schema/model/source-shape core runs independently. This is intentional for a read-only, partly-broken hub in a currently-disabled module.
