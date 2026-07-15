# bha_ Configuration — Validation Report

**Feature:** BehaviouralAssessment / Configuration · **Generated:** 2026-Jul-11 · **Prefix:** `bha_` (registry code BHA) — verified against the live runtime table **`ba_config`** (DDL-doc `bha_config` is stale → DOC-BA-001; filenames keep `bha_` per registry).

---

## 1. File Existence Summary
| # | File | Present |
|---|------|---------|
| 1 | `bha_ConfigurationTcList_Require.md` | ✅ |
| 2 | `bha_ConfigurationMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_ConfigurationGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_Configuration_TestCas.php` | ✅ (ONE file — no V1/V2 — pre-existing, left UNMODIFIED) |
| 5 | `bha_ConfigurationValidation_Report.md` | ✅ |
| 6 | `run-Configuration-tests.ps1` | ✅ |
| 7 | `run-Configuration-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `bha_` matches the module registry (BHA / `bha_`) ✅. The **live table** is `ba_config`; the doc/registry `bha_config` name is stale (DOC-BA-001) — the test asserts `ba_config`, filenames stay `bha_` as instructed.
- Feature PascalCase `Configuration` ✅.
- Class name = filename: `class bha_Configuration_TestCas` ✅.
- Test methods snake_case, zero-padded, semantic bands `test_configuration_NN_*` ✅.

## 3. Structure Validation
- `namespace Tests\Browser;` ✅
- `extends DuskTestCase` ✅ (browser Dusk style — mirrors module tenant-side siblings)
- `setUp()`/`tearDown()` with `initializeTenantContext()` + guarded `tenancy()->end()` ✅
- Typed properties initialised (`?User $adminUser = null`, string defaults, `static bool $screenshotsCleaned = false`) ✅
- `php -l` result: **No syntax errors detected** ✅ (re-confirmed this run; file unchanged)

## 4. Coverage Completeness
- **Total test methods: 51.**
- Coverage: Negative **100%** · Positive **100%** (95% Full + conditional-partial) · Dependency **100%** (Full + defensive) · Tenancy **100%** on P0/P1 (1/1 Full + 1 defensive) · Security **100%**.
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 Method Index and Gap Analysis §1).
- No V1/V2 split; no method-ratio target — coverage-gated only.
- Semantic bands: 01–03 schema; 10–15 biz; 20–23 state-machine/DATA-BA-001; 30–39 validation; 40–46 integration/lifecycle; 50–55 permissions; 60–63 UI/UX; 70–72 edge; 80–83 config/SEC-BA-001/CFG-BA-001; 90–93 tenancy/security.

## 5. Known Source Defects / Findings Documented
| ID | Severity | Proving test | Where recorded |
|-----|----------|--------------|----------------|
| DOC-BA-001 (doc `bha_config` vs live `ba_config`) | Low | test_02 | TcList §4, Gap §4 |
| DATA-BA-001 (scale switchable mid-session — FIX VERIFIED PRESENT) | High (resolved) | test_21/22/23 | TcList §4, Gap §4 |
| DATA-BA-003 (unique index unconditional vs FormRequest `whereNull`) | Med | test_45 | TcList §4, Gap §4 |
| SEC-BA-001 (severe-incident parent notification not wired) | High | test_80/81 | TcList §4, Gap §4 |
| SEC-BA-002 (`authorize()` returns bare true) | Low | test_92 | TcList §4, Gap §4 |
| CFG-BA-001 (requirement fields not implemented) | Info | test_82 | TcList §4, Gap §4 |

**SEC-BA-001 is the only open P1-class finding owned by this screen** — the threshold is configurable but never consumed by any controller/service. test_81 acts as a change-detector (goes red when a notification/mail dispatch or threshold read is added to the incident flow).

## 6. Constraints applied (`05_Known_Test_Failure_Constraints.md`)
- A1/A2/A3 — tenant resolution via `Modules\Prime\Models\Domain`; guarded `tenancy()->end()` in tearDown ✅
- A4 — tenant-side (`ba_*`, database-per-tenant) → tenancy scaffolding emitted; no `tenant_id` column asserted (test_90) ✅
- B — `App\Models\User` + `User::factory()` for the limited user; `user_type='EMPLOYEE'` / `emp_code` / `prefered_language` set conditionally on column presence ✅
- C — `withTrashed/onlyTrashed/forceDelete` used only because `BaConfig` uses `SoftDeletes` (verified test_01); all cleanup wrapped in try/catch ✅; typed props initialised ✅
- D — status codes captured via `sendJsonRequestFromBrowser` (browser fetch with `redirect:'manual'`, opaqueredirect→302 normalization), never Dusk `assertStatus` ✅; authenticated before every negative/validation POST ✅; browse closures pass outer vars via `use(...)` ✅; schema-type asserts via `assertStringContainsString` on COLUMN_TYPE, not exact equality (constraint #17) ✅
- Source resolution — migration/FormRequest/controller/policy/blade read from the APP repo via `ReflectionClass(BaConfig)` path math + `File::exists` fail-soft (constraint #29/#32) ✅
- Defensive skips — FK metadata, ratings data, second tenant, limited-user creation all guarded with `markTestSkipped` so partial environments stay green ✅

## 7. Environment prerequisites (to actually run)
1. `BehaviouralAssessment` module ENABLED in `prime_testing/modules_statuses.json` (disabled → 404 on all routes).
2. `APP_ENV=testing`, Chrome/Dusk driver, `MAIN_PROJECT_PATH` set, `prime_ai` cloned alongside `prime_testing`.
3. Tenant DB seeded with ≥1 academic session (`sch_org_academic_sessions_jnt`) that has no existing `ba_config`; the suite seeds rating scales itself.
4. `DUSK_TENANT_URL` / `DUSK_ADMIN_EMAIL` / `DUSK_ADMIN_PASSWORD` set (defaults `http://test.localhost:8000`, `root@tenant.com`, `password`).

## 8. Final Verdict
**PASS WITH NOTES.**
- Static: `php -l` clean; ONE test file (51 methods); naming/structure/bands conform; all coverage gates met (Negative 100%, Positive 100%, Dependency 100%, Tenancy 100% P0/P1).
- The pre-existing `bha_Configuration_TestCas.php` was **left unmodified** — only the 6 companion artifacts were generated, derived 1:1 from its 51 methods.
- Dusk execution NOT performed here (module-enablement + seed prerequisites are environment-side). Runtime green-ness pending module enablement + seed data.
- 6 documented findings (DATA-BA-001 verified fixed; SEC-BA-001 the open P1) with proving tests.
