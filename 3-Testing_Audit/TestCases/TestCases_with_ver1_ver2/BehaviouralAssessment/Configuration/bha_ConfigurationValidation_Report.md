# Configuration — Validation Report

**Feature:** BehaviouralAssessment › Configuration · **Generated:** 2026-Jul-09 · **Mode:** feature (real generation)

## 1. File Existence
| # | File | Present |
|---|------|---------|
| 1 | `bha_ConfigurationTcList_Require.md` | ✅ |
| 2 | `bha_ConfigurationMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_ConfigurationGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_ConfigurationV1_TestCas.php` | ✅ |
| 5 | `bha_ConfigurationV2_TestCas.php` | ✅ |
| 6 | `bha_ConfigurationValidation_Report.md` | ✅ |
| 7 | `run-Configuration-tests.ps1` | ✅ |
| 8 | `run-Configuration-tests.sh` | ✅ |

## 2. Naming Conventions
- File prefix `bha_` — per DDL doc `CREATE TABLE bha_config` + caller instruction + module Feature Inventory. ✅
- **Prefix caveat (`DOC-BA-001`, audit-confirmed):** live migration/model/DB use `ba_config`. All PHP schema assertions target the real `ba_config` table (verified). The `bha_` in file names is a labelling choice; it does not appear in any executable assertion. ✅ documented, not a defect.
- Feature folder PascalCase `Configuration` (app alias for controller `BaConfigController` / route `configs`). ✅
- Class = filename (`bha_ConfigurationV1_TestCas`, `bha_ConfigurationV2_TestCas`). ✅
- snake_case, zero-padded, banded methods (`test_config_NN_*`). ✅

## 3. Structure Validation
- `extends DuskTestCase`, `namespace Tests\Browser;`. ✅
- `setUp()`/`tearDown()` with tenant init via `Modules\Prime\Models\Domain` + guarded `tenancy()->end()`. ✅ (matches `05_` A1–A3)
- Typed properties initialised (`?User $adminUser = null`, `?int $createdScaleId = null`, strings `''`). ✅ (`05_` U2/13)
- `php -l`: **V1 clean, V2 clean** (both "No syntax errors detected"). ✅

## 4. Coverage Completeness
- **V1 = 15 methods · V2 = 47 methods · ratio 3.13× (≥ 2× gate met).** ✅
- Every TC-ID maps to ≥1 V2 method; every V2 method maps to a TC/BC (see TcList §3 + Gap §1). ✅
- Coverage: Positive 100%, Negative 100%, Dependency 100%, Config 100%, Tenancy 100%, Security 100%. ✅
- `BC-SM` present (active↔inactive, trash lifecycle) + `BC-CFG` emphasised (default-scale binding, aggregation, thresholds); every transition has a TC. ✅
- Coverage-Score + Cross-Reference Findings (7) tables present in Gap Analysis. ✅

## 5. Known Source Defects Documented (audit-equivalent)
| ID | Where documented | Proving test |
|----|------------------|--------------|
| SEC-BA-001 / BUG-BA-003 (threshold never consumed) | TcList §1, Gap #11, Manual TC-N42 | V2 `test_..._83` |
| DATA-BA-001 (mid-session scale switch not guarded) | TcList §1, Gap #7, Manual TC-N41 | V2 `test_..._82` |
| SEC-BA-002 (authorize() bare true) | TcList §1, Gap #10, Manual TC-N40 | V1 `test_..._15` + V2 `test_..._52` |
| DATA-BA-003 (soft-delete unique session collision) | TcList §1, Gap #11, Manual TC-D10 | V2 `test_..._43` |
| DOC-BA-001 (bha_ doc vs ba_ live) | This report §2, Gap #11 | V1/V2 `test_..._01` |
| CFG-BA-CFG-01 (weightage_percent unused) — **verify in source** | Gap #11, Manual TC-N43 | V2 `test_..._84` |
| REQ-BA-CFG-01 (screen fields absent) — **verify in source** | Gap #8, Manual TC-N44 | V2 `test_..._85` |
| AUTH-BA-CFG-01 (gate uses permission string, policy unused) — **verify in source** | Gap #3 | V2 `test_..._52` |

All bug-proving tests assert the **current (defective) behaviour** so they pass today and will flag the fix when applied.

## 6. Constraints obeyed (`05_Known_Test_Failure_Constraints.md`)
- A1–A4: browser-Dusk tenant scaffolding mirrors the committed sibling; tenant resolved via `Modules\Prime\Models\Domain`; guarded teardown; tenant-side confirmed from DDL header (`Database: tenant_db`). ✅
- B5/B6: uses `Modules\SchoolSetup\Models\User` (the model the sibling and `BaConfigPolicy` type-hint) and resolves the existing admin rather than a factory. ✅
- B7/B8/B9: limited-user helper mass-assigns `password` (fillable), sets `user_type='EMPLOYEE'`, `prefered_language` from `glb_languages`, `emp_code` ≤ 20 (`substr(...,0,20)`), guarded by `markTestSkipped`. ✅
- C11/C12: `forceDelete()` wrapped in `try/catch (Throwable)`; `withTrashed/onlyTrashed/forceDelete` only on `SoftDeletes` model (`BaConfig`). ✅
- C13: typed props initialised. ✅
- D14: no `$browser->assertStatus()`; browser flows use path/see/`.alert-danger`; toggle JSON via `executeAsyncScript`; FK/DB rejections asserted via caught `QueryException`/`Throwable` 23000. ✅
- D15/D16: browse closures pass outer vars via `use`; auth established before any state-changing flow. ✅
- D17/D18: schema types not asserted by exact `COLUMN_TYPE`; enum values (`aggregation_method`, `parent_notification_threshold`) case-exact against source; respected column limits (weightage 5–20, SMALLINT session range). ✅

## 7. Environment Prerequisites (E)
- **E19 — module must be ENABLED:** `prime_testing/modules_statuses.json` currently has `"BehaviouralAssessment": false`. **All routes return 404 until enabled.** Flip to `true` before running the runners. (Environment prerequisite, not a test-code fix.)
- **E20 — `APP_ENV=testing`:** both runners set it (bypasses CSRF/419).
- Requires `prime_ai` cloned alongside `prime_testing` with `MAIN_PROJECT_PATH` set; a seeded tenant + admin user (`root@tenant.com`), at least one **active academic session** in `sch_org_academic_sessions_jnt` **without an existing config** (each config consumes a unique session slot), at least one **active rating scale**, and one `glb_languages` row.

## 8. Enhanced dimensions
- Included: Tenancy (`90`), Security IDOR/404 (`91`), permission/guest (`50/51/53`), FormRequest-config assertions (`04`), state-machine (`20–22`), Integration/config-consumption via service source scan (`16/80/81/84`), requirement-divergence proofs (`85`).
- Deliberately skipped: stored-XSS smoke — the config form has no free-text field (all inputs are enums, numeric, or FK selects), so there is no reflected-text surface to attack. Responsive-viewport and console-error (`TC-A`) smoke omitted to stay aligned with the module's committed style. Non-functional timing not added (soft-value only).

## 9. Source facts that shaped / limited assertions
1. **DDL doc vs live prefix** — used `ba_config` in code; `bha_` only in file names (`DOC-BA-001`).
2. **Real controller flash strings used verbatim** — `Configuration created successfully.` / `Configuration updated successfully.` / `Configuration moved to trash.` / toggle JSON `Configuration activated./deactivated.` (from `BaConfigController`).
3. **One config per session (unique)** — direct-create helpers pick a **free** active session id (`freeSessionIdOrSkip`) so parallel tests don't collide, and `markTestSkipped` when every session is already configured — a robust skip, never a false-fail.
4. **No `messages()` for most fields** — negative tests assert `.alert-danger` + no-insert; only the unique-session message is asserted verbatim.
5. **Requirement vs implementation diverge** — the screen's "Approval Workflow" and "Incident Escalation Threshold (default 3)" fields do **not** exist on `ba_config`; the shipped fields are `aggregation_method` + `parent_notification_threshold` + `weightage_percent` + `is_result_integration_enabled`. Asserted as documented divergence, not as passing rules.
6. **Config-driven behaviour** lives in `BehaviouralScoreService` (read path) — scale binding + aggregation asserted by source scan (no seeded assessment/rating data required for this feature suite).

---

## Final Verdict: **PASS WITH NOTES**

All 8 artifacts generated; both PHP files `php -l` clean; V2/V1 = 3.13× (≥2×); coverage targets met; audit defects captured with proving tests (SEC-BA-001, DATA-BA-001, SEC-BA-002, DATA-BA-003, DOC-BA-001) plus three verify-in-source candidates (CFG-BA-CFG-01, REQ-BA-CFG-01, AUTH-BA-CFG-01). **Notes:** (a) file prefix `bha_` retained per instruction while the live table is `ba_config` (`DOC-BA-001`); (b) module must be enabled in `modules_statuses.json` (E19) and a free active academic session must exist before execution — tests not run per instruction; (c) the config screen has no free-text field, so XSS smoke is intentionally omitted.
