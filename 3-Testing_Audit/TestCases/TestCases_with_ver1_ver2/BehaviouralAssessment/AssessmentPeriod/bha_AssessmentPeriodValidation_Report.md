# AssessmentPeriod — Validation Report

**Feature:** BehaviouralAssessment › AssessmentPeriod · **Generated:** 2026-Jul-09 · **Mode:** feature (real generation) · **Focus:** WORKFLOW/FSM

## 1. File Existence
| # | File | Present |
|---|------|---------|
| 1 | `bha_AssessmentPeriodTcList_Require.md` | ✅ |
| 2 | `bha_AssessmentPeriodMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_AssessmentPeriodGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_AssessmentPeriodV1_TestCas.php` | ✅ |
| 5 | `bha_AssessmentPeriodV2_TestCas.php` | ✅ |
| 6 | `bha_AssessmentPeriodValidation_Report.md` | ✅ |
| 7 | `run-AssessmentPeriod-tests.ps1` | ✅ |
| 8 | `run-AssessmentPeriod-tests.sh` | ✅ |

## 2. Naming Conventions
- File prefix `bha_` — per DDL doc `CREATE TABLE bha_assessment_periods` + caller instruction + module Feature Inventory. ✅
- **Prefix caveat (`DOC-BA-001`, audit-confirmed):** live migration/model/DB use `ba_assessment_periods`. All PHP schema assertions target the real `ba_` table; the `bha_` appears only in file/class names. DOC-BA-001 proving test asserts `hasTable('ba_assessment_periods')` + `assertFalse(hasTable('bha_assessment_periods'))`. ✅
- Feature folder PascalCase `AssessmentPeriod`. ✅
- Class = filename (`bha_AssessmentPeriodV1_TestCas`, `bha_AssessmentPeriodV2_TestCas`). ✅
- snake_case, zero-padded, banded methods (`test_assessment_period_NN_*`). ✅

## 3. Structure Validation
- `extends DuskTestCase`, `namespace Tests\Browser;`. ✅
- `setUp()`/`tearDown()` with tenant init via `Modules\Prime\Models\Domain` + guarded `tenancy()->end()`. ✅ (matches `05_` A1–A3)
- Typed properties initialised (`?User $adminUser = null`, `?User $limitedUser = null`, strings `''`). ✅ (`05_` U2/13)
- `php -l`: **V1 clean, V2 clean** (both "No syntax errors detected"). ✅

## 4. Coverage Completeness
- **V1 = 16 methods · V2 = 44 methods · ratio 2.75× (≥ 2× gate met).** ✅
- Every TC-ID maps to ≥1 V2 method; every V2 method maps to a TC/BC (see TcList §3 + Gap §1). ✅
- Coverage: Positive 100%, Negative 100%, **State-machine 100%**, Dependency 100%, Tenancy 100%, Security 100%. ✅
- **`BC-SM` band present and central** — every legal transition (store→open, open→locked, locked→closed) has a positive test; every guard (lock-already-locked, unlock-non-locked) has a test; every key illegal transition (closed→locked, open→closed-unreachable, edit back-door closed→open / open→closed, lock-no-freeze) has a proving test. Semantic band 20–29 = state machine. ✅
- Coverage-Score + Cross-Reference Findings (4) tables present in Gap Analysis. ✅

## 5. Known Source Defects Documented (audit-equivalent)
| ID | Where documented | Proving test |
|----|------------------|--------------|
| **BUG-BA-002** (period FSM violated) | TcList §1 BC-SM, Gap #7, Manual TC-SM-03/08/06a/06b | V2 `_25 _26 _27 _28` |
| **BUG-BA-001** (lock doesn't freeze) | TcList BC-SM-10, Gap #7, Manual TC-N24/N25 | V2 `_29` (source, always runs) + `_41` (data, defensive) |
| SEC-BA-002 (authorize() bare true) | TcList BC-AUTH-03, Gap #10, Manual TC-S03 | V2 `_52` |
| VAL-BA-AP-01 (non-overlap rule not enforced) — **new, verify in source** | TcList BC-EDG-02, Gap #8, Manual TC-N26 | V2 `_71` |
| DOC-BA-001 (bha_ doc vs ba_ live) | This report §2, Gap note | V2 `_01`, V1 `_01` |

All bug-proving tests assert the **current (defective) behaviour** so they pass today and will flag the fix when applied. `BUG-BA-002` and `BUG-BA-001` are the two P1 defects the audit's deploy gate is conditional on — both are proven here (FSM band + source scan).

## 6. Constraints obeyed (`05_Known_Test_Failure_Constraints.md`)
- A1–A4: browser-Dusk tenant scaffolding mirrors the committed sibling `AssessmentPeriodCrudTest`; tenant resolved via `Modules\Prime\Models\Domain`; guarded teardown; tenant-side confirmed from DDL header. ✅
- B5/B6: uses `Modules\SchoolSetup\Models\User` (the model the committed sibling uses); resolves the existing admin, not a factory. ✅
- B7/B8/B9: limited-user helper mass-assigns `password` (fillable), sets `user_type='EMPLOYEE'`, `prefered_language` from `glb_languages`, `emp_code` ≤ 20 (`substr(...,0,20)`), guarded by `markTestSkipped`. ✅
- C11/C12: `forceDelete()` wrapped in `try/catch (Throwable)`; child `assessments()->forceDelete()` before parent; `withTrashed/onlyTrashed/forceDelete` only on the `SoftDeletes` model. ✅
- C13: typed props initialised. ✅
- D14: no `$browser->assertStatus()`; browser flows use path/see/`.alert-danger`; lifecycle endpoints (lock/unlock/toggle) driven via authenticated `fetch` (`executeAsyncScript`), DB status verified after; 404 proven via edit-button absence. ✅
- D15/D16: authenticated before every mutating flow; browse closures pass outer vars via `use`. ✅
- D17/D18: schema types not asserted by exact `COLUMN_TYPE`; enum values case-exact against source; migration enum order asserted verbatim (`['closed','locked','open']`). ✅

## 7. Environment Prerequisites (E)
- **E19 — module must be ENABLED:** `prime_testing/modules_statuses.json` currently has `"BehaviouralAssessment": false`. **All routes return 404 until enabled.** Flip to `true` before running the runners. (Environment prerequisite, not a test-code fix.)
- **E20 — `APP_ENV=testing`:** both runners set it (bypasses CSRF/419) — required for the lock/unlock/toggle `POST` fetches.
- Requires `prime_ai` cloned alongside `prime_testing` with `MAIN_PROJECT_PATH` set; a seeded tenant + admin (`root@tenant.com`), at least one `sch_org_academic_sessions_jnt` row (academic session), and — for the two defensive cross-module tests (`40`,`41`) — `sch_employees` + `sch_class_section_jnt` rows and a `glb_languages` row (for `53`). Missing dependencies `markTestSkipped`, keeping the suite green.

## 8. Enhanced dimensions
- Included: **State-machine (20–29, the core band)**, Tenancy (`90`), Security XSS (`91`) + IDOR/404 (`92`), permission/guest (`50/51/53`), FormRequest-config assertions (`04`), FK/RESTRICT guard (`40`), cross-module defensive data proof (`41`).
- Deliberately skipped: responsive-viewport smoke and console-error (`TC-A`) smoke — the committed sibling omits screenshot/console helpers; kept aligned with the module's real style. Non-functional timing not added.

## 9. Source facts that shaped / limited assertions
1. **DDL doc vs live prefix** — used `ba_assessment_periods` in code; `bha_` only in file names (`DOC-BA-001`).
2. **Committed sibling `AssessmentPeriodCrudTest.php` is stale** — this suite deliberately diverges to use the **real** source:
   - Migration path `2026_06_16_130612_create_ba_assessment_periods_table.php` (sibling's `2026_04_11_000007…` does not exist).
   - Real flash `Assessment period updated successfully.` (lowercase "period"; sibling asserts capital "Period").
   - Real create/edit page strings (`Academic Context`, `Period Details`, `Save/Update Assessment Period`); the sibling's `Create Assessment Period` / `Edit Assessment Period` / `Assessment Period Details` strings **do not exist**.
   - `show()` **redirects to edit** — asserted as such, not as a separate detail page.
   - Lock/unlock are **plain form-submit buttons** (`btn-outline-danger`/`btn-outline-warning`) posting to real routes — the sibling's `.lock-btn`/`.unlock-btn`/`.status-switch[data-id]` selectors **do not exist**; this suite drives lock/unlock/toggle via the **real endpoints** (`fetch` POST + DB assertion).
   - Migration enum order is `['closed','locked','open']` (asserted verbatim); the sibling's `['open','closed','locked']` would fail.
3. **No activity log** for period CRUD — no activity-log assertions were invented.
4. **No `messages()`** in the FormRequest — negative tests assert `.alert-danger` + no-insert rather than fragile default message text.
5. **FSM / lock-freeze / non-overlap** are **not correctly implemented** in source — asserted as documented gaps (BUG-BA-002, BUG-BA-001, VAL-BA-AP-01), not as passing business rules.
6. **No append to `05_`** was needed — all failure causes encountered are already covered by existing constraints (A/B/C/D/E). VAL-BA-AP-01 is a feature-specific defect (documented here + Gap), not a general test-harness constraint.

---

## Final Verdict: **PASS WITH NOTES**

All 8 artifacts generated; both PHP files `php -l` clean; V2/V1 = 2.75× (≥2×); coverage targets met with **State-machine at 100%** (every legal + key illegal transition covered). The two conditional-deploy P1 defects — **BUG-BA-002** (FSM violated; `open→closed` unreachable; illegal transitions allowed) and **BUG-BA-001** (period lock never freezes assessments) — are both proven with tests that assert current behaviour. **Notes:** (a) file prefix `bha_` retained per instruction while the live table is `ba_` (`DOC-BA-001`); (b) module must be enabled in `modules_statuses.json` (E19) before execution — tests not run per instruction; (c) one new cross-reference candidate (VAL-BA-AP-01, non-overlap rule) reported as *verify in source*; (d) the committed sibling test is stale on several strings/selectors — this suite corrects them against real source.
