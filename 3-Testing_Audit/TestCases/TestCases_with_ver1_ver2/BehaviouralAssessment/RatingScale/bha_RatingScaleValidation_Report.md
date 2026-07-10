# RatingScale — Validation Report

**Feature:** BehaviouralAssessment › RatingScale · **Generated:** 2026-Jul-09 · **Mode:** feature (real generation)

## 1. File Existence
| # | File | Present |
|---|------|---------|
| 1 | `bha_RatingScaleTcList_Require.md` | ✅ |
| 2 | `bha_RatingScaleMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_RatingScaleGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_RatingScaleV1_TestCas.php` | ✅ |
| 5 | `bha_RatingScaleV2_TestCas.php` | ✅ |
| 6 | `bha_RatingScaleValidation_Report.md` | ✅ |
| 7 | `run-RatingScale-tests.ps1` | ✅ |
| 8 | `run-RatingScale-tests.sh` | ✅ |

## 2. Naming Conventions
- File prefix `bha_` — per DDL doc `CREATE TABLE bha_rating_scales` + caller instruction + module Feature Inventory. ✅
- **Prefix caveat (`DOC-BA-001`, audit-confirmed):** live migrations/models/DB use `ba_rating_scales` / `ba_rating_levels`. All PHP schema assertions target the real `ba_` tables (verified). The `bha_` in file names is a labelling choice; it does not appear in any executable assertion. ✅ documented, not a defect in the artifacts.
- Feature folder PascalCase `RatingScale`. ✅
- Class = filename (`bha_RatingScaleV1_TestCas`, `bha_RatingScaleV2_TestCas`). ✅
- snake_case, zero-padded, banded methods (`test_rating_scale_NN_*`). ✅

## 3. Structure Validation
- `extends DuskTestCase`, `namespace Tests\Browser;`. ✅
- `setUp()`/`tearDown()` with tenant init via `Modules\Prime\Models\Domain` + guarded `tenancy()->end()`. ✅ (matches `05_` A1–A3)
- Typed properties initialised (`?User $adminUser = null`, strings `''`). ✅ (`05_` U2/13)
- `php -l`: **V1 clean, V2 clean** (both "No syntax errors detected"). ✅

## 4. Coverage Completeness
- **V1 = 16 methods · V2 = 47 methods · ratio 2.94× (≥ 2× gate met).** ✅
- Every TC-ID maps to ≥1 V2 method; every V2 method maps to a TC/BC (see TcList §3 + Gap §1). ✅
- Coverage: Positive 100%, Negative 100% (Full 93%), Dependency 100%, Tenancy 100%, Security 100%. ✅
- `BC-SM` present (active↔inactive, trash lifecycle); every transition has a TC. ✅
- Coverage-Score + Cross-Reference Findings (8) tables present in Gap Analysis. ✅

## 5. Known Source Defects Documented (audit-equivalent)
| ID | Where documented | Proving test |
|----|------------------|--------------|
| BUG-BA-009 (multiple defaults) | TcList §1, Gap #6/#8, Manual TC-N20 | V2 `test_..._13` |
| VAL-BA-002 (level value no range check) | TcList, Gap #8, Manual TC-N23 | V2 `test_..._38` |
| DATA-BA-003 (soft-delete unique collision) | TcList, Gap #11, Manual TC-D05 | V2 `test_..._39` |
| SEC-BA-002 (authorize() bare true) | TcList, Gap #10, Manual TC-S03 | V2 `test_..._52` |
| DATA-BA-001 (deactivate no usage guard) | TcList, Gap #7, Manual TC-N21 | V2 `test_..._26` + `_27` |
| DOC-BA-001 (bha_ doc vs ba_ live) | This report §2, Gap #11 | V2 `test_..._01` |
| UIX-BA-RS-01 (grade_type UI vs `descriptive`) — **verify in source** | Gap #1 | V2 `test_..._33` |
| AUTH-BA-RS-01 (gate uses permission string, policy unused) — **verify in source** | Gap #3 | V2 `test_..._52` |

All bug-proving tests assert the **current (defective) behaviour** so they pass today and will flag the fix when applied.

## 6. Constraints obeyed (`05_Known_Test_Failure_Constraints.md`)
- A1–A4: browser-Dusk tenant scaffolding mirrors the committed sibling; tenant resolved via `Modules\Prime\Models\Domain`; guarded teardown; tenant-side confirmed from DDL header. ✅
- B5/B6: uses `Modules\SchoolSetup\Models\User` (the model the sibling and `BaRatingScalePolicy` type-hint) and resolves the existing admin rather than a factory — matches the nearest same-module sibling (`RatingScaleCrudTest`). ✅
- B7/B8/B9: limited-user helper mass-assigns `password` (fillable), sets `user_type='EMPLOYEE'`, `prefered_language` from `glb_languages`, `emp_code` ≤ 20 (`substr(...,0,20)`), guarded by `markTestSkipped`. ✅
- C11/C12: `forceDelete()` wrapped in `try/catch (Throwable)`; `withTrashed/onlyTrashed/forceDelete` only on `SoftDeletes` models. ✅
- C13: typed props initialised. ✅
- D14: no `$browser->assertStatus()`; browser flows use path/see/`.alert-danger`; toggle JSON via `executeAsyncScript`; DB status codes avoided (findOrFail proven via detail-absence). ✅
- D16: browse closures pass outer vars via `use`. ✅
- D17/D18: schema types not asserted by exact `COLUMN_TYPE`; enum/`grade_type` values case-exact against source. ✅

## 7. Environment Prerequisites (E)
- **E19 — module must be ENABLED:** `prime_testing/modules_statuses.json` currently has `"BehaviouralAssessment": false`. **All routes return 404 until enabled.** Flip to `true` before running the runners. (Environment prerequisite, not a test-code fix.)
- **E20 — `APP_ENV=testing`:** both runners set it (bypasses CSRF/419).
- Requires `prime_ai` cloned alongside `prime_testing` with `MAIN_PROJECT_PATH` set; a seeded tenant + admin user (`root@tenant.com`) and at least one `glb_languages` row.

## 8. Enhanced dimensions
- Included: Tenancy (`90`), Security XSS (`91`) + IDOR/404 (`92`), permission/guest (`50/51/53`), FormRequest-config assertions (`04`), state-machine (`20–22`).
- Deliberately skipped: responsive-viewport smoke and console-error (`TC-A`) smoke — the committed sibling omits screenshot/console helpers and the base class auto-routing was not exercised to keep the suite aligned with the module's real style. Non-functional timing not added (soft-value only).

## 9. Source facts that shaped / limited assertions
1. **DDL doc vs live prefix** — used `ba_` tables in code; `bha_` only in file names (`DOC-BA-001`).
2. **Committed sibling had wrong expected strings** (`'Rating Scale updated successfully.'`, `'Level added successfully'`, `'Add Level'`, `.status-switch`, and a non-existent migration path `2026_04_11_000001`). This suite uses the **real** controller strings (`'Rating scale updated successfully.'`, `'Level added.'`), the real button label `Add`, selector `.status-toggle[data-id]`, and the real migration path `2026_06_16_130616`.
3. **No activity log** for RatingScale CRUD — no activity-log assertions were invented.
4. **No `messages()`** in the FormRequest — negative tests assert `.alert-danger` + no-insert rather than fragile default message text.
5. **`is_default` uniqueness / min-max levels / usage guards** are **not implemented** in source — asserted as documented gaps (bugs), not as passing business rules.

---

## Final Verdict: **PASS WITH NOTES**

All 8 artifacts generated; both PHP files `php -l` clean; V2/V1 = 2.94× (≥2×); coverage targets met; audit defects captured with proving tests. **Notes:** (a) file prefix `bha_` retained per instruction while live tables are `ba_` (`DOC-BA-001`); (b) module must be enabled in `modules_statuses.json` (E19) before execution — tests not run per instruction; (c) two new cross-reference candidates (UIX-BA-RS-01, AUTH-BA-RS-01) reported as *verify in source*.
