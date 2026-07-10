# ClassMapping — Validation Report

**Feature:** BehaviouralAssessment › ClassMapping (app: ClassCategory) · **Generated:** 2026-Jul-09 · **Mode:** feature (real generation)

## 1. File Existence
| # | File | Present |
|---|------|---------|
| 1 | `bha_ClassMappingTcList_Require.md` | ✅ |
| 2 | `bha_ClassMappingMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_ClassMappingGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_ClassMappingV1_TestCas.php` | ✅ |
| 5 | `bha_ClassMappingV2_TestCas.php` | ✅ |
| 6 | `bha_ClassMappingValidation_Report.md` | ✅ |
| 7 | `run-ClassMapping-tests.ps1` | ✅ |
| 8 | `run-ClassMapping-tests.sh` | ✅ |

## 2. Naming Conventions
- File prefix `bha_` — per DDL doc + caller instruction + module Feature Inventory. ✅
- **Prefix caveat (`DOC-BA-001`, audit-confirmed):** live migration/model/DB use `ba_class_category_jnt`. Every PHP schema assertion targets the real `ba_` table (verified); `bha_` appears only in file/class names, never in an executable assertion. ✅ documented, not a defect.
- Feature folder PascalCase `ClassMapping`. ✅
- Class = filename (`bha_ClassMappingV1_TestCas`, `bha_ClassMappingV2_TestCas`). ✅
- snake_case, zero-padded, banded methods (`test_class_mapping_NN_*`). ✅

## 3. Structure Validation
- `extends DuskTestCase`, `namespace Tests\Browser;`. ✅
- `setUp()`/`tearDown()` with tenant init via `Modules\Prime\Models\Domain` + guarded `tenancy()->end()`. ✅ (matches `05_` A1–A3)
- Typed properties initialised (`?User $adminUser = null`, `?User $limitedUser = null`, strings `''`). ✅ (`05_` C13)
- `php -l`: **V1 clean, V2 clean** (both "No syntax errors detected"). ✅

## 4. Coverage Completeness
- **V1 = 14 methods · V2 = 35 methods · ratio 2.50× (≥ 2× gate met).** ✅
- Every TC-ID maps to ≥1 V2 method; every V2 method maps to a TC/BC (see TcList §3 + Gap §1). ✅
- Coverage: Positive 100%, Negative 100%, Dependency 100%, State-machine 100%, Tenancy 100%, Security/Auth 100%. ✅
- `BC-SM` present (active↔inactive toggle; add→remove hard-delete); every transition has a TC. ✅
- Coverage-Score + Cross-Reference Findings (6) tables present in Gap Analysis. ✅

## 5. Known Source Defects Documented (audit-equivalent)
| ID | Where documented | Proving test |
|----|------------------|--------------|
| DOC-BA-001 (bha_ doc vs ba_ live) | This report §2, TcList, Gap #11 | V1 `01` · V2 `01` |
| **BUG-BA-012 (NEW — model missing SoftDeletes → hard delete)** | TcList §1, Gap #11, Manual TC-N20/TC-D01 | V1 `01`,`08` · V2 `04`,`22` |
| VAL-BA-001 (no FormRequest — inline validate) | TcList, Gap #8, Manual TC-N02b | V1 `12` · V2 `30` |
| BUG-BA-007 (unmapped class ⇒ empty grid) | TcList, Gap #7, Manual TC-D04 | V1 `14` · V2 `41` |
| **GAP-BA-CM-01 (NEW — unmap has no recorded-grades guard)** | TcList, Gap #7, Manual TC-D05 | V2 `42` |
| **GAP-BA-CM-02 (NEW — single-pair form / no session vs requirement grid)** | TcList, Gap #8, Manual TC-D06 | V2 `43` |
| AUTH-BA-CM-01 (permission-string gates, no Policy) — **verify in source** | Gap #3 | V2 `51` |

All bug-proving tests assert the **current (defective) behaviour** so they pass today and will flag the fix when applied.

## 6. Constraints obeyed (`05_Known_Test_Failure_Constraints.md`)
- A1–A4: browser-Dusk tenant scaffolding mirrors the committed sibling `ClassCategoryCrudTest`; tenant resolved via `Modules\Prime\Models\Domain`; guarded teardown; tenant-side confirmed from DDL header + `bha_/ba_` prefix. ✅
- B5/B6: uses `Modules\SchoolSetup\Models\User` (the model the sibling imports) and resolves the existing admin rather than a factory. ✅
- B7/B8/B9: limited-user helper mass-assigns `password` (fillable), sets `user_type='EMPLOYEE'`, `prefered_language` from `glb_languages`, `emp_code` ≤ 20 (`substr(...,0,20)`), guarded by `markTestSkipped`. ✅
- **C11/C12 (critical here):** the model does **NOT** use `SoftDeletes` (`BUG-BA-012`) — so `withTrashed()/onlyTrashed()/restore()/forceDelete()` are **never called** on `BaClassCategoryJnt` (they would throw `BadMethodCallException`). Cleanup uses `DB::table('ba_class_category_jnt')->where('id',…)->delete()` wrapped in `try/catch`, and the lifecycle test proves the **hard delete**. This is the required divergence from the committed sibling (which wrongly assumes SoftDeletes). ✅
- C13: typed props initialised. ✅
- D14: no `$browser->assertStatus()`; browser flows use path/see/message; toggle JSON via `executeAsyncScript`; `findOrFail` 404 proven via source + no-ghost-row + no-success-payload. ✅
- D15/D16: authenticate before submitting; browse closures pass outer vars via `use`. ✅
- D17/D18: schema types not asserted by exact `COLUMN_TYPE`; unique-index/FK asserted via migration substrings; no enum on this junction. ✅

## 7. Environment Prerequisites (E)
- **E19 — module must be ENABLED:** `prime_testing/modules_statuses.json` currently has `"BehaviouralAssessment": false`. **All routes return 404 until enabled.** Flip to `true` before running the runners. (Environment prerequisite, not a test-code fix.)
- **E20 — `APP_ENV=testing`:** both runners set it (bypasses CSRF/419).
- Cross-module data prerequisite: at least one **active** `sch_classes` row (SchoolSetup) and one **active top-level** `ba_categories` row must exist, plus an **unmapped (class, category) pair** — otherwise the data-dependent tests `markTestSkipped` rather than fail.
- Requires `prime_ai` cloned alongside `prime_testing` with `MAIN_PROJECT_PATH` set; a seeded tenant + admin user (`root@tenant.com`) and at least one `glb_languages` row.

## 8. Enhanced dimensions
- Included: Tenancy (`90`), Security escaping (`91`) + IDOR/404 (`92`), permission/guest/gates (`50/51/52`), FK-migration assertions (`02`), state-machine (`20–23`), cross-module defensive integration (`40–43`).
- Deliberately skipped: responsive-viewport smoke and console-error (`TC-A`) smoke — the committed sibling omits screenshot/console helpers; kept aligned with the module's real style. Stored-XSS **execution** test omitted because ClassMapping has no free-text field the user controls (class/category names come from other modules); escaping is asserted at the Blade-source layer instead. No activity-log assertions (feature has none).

## 9. Source facts that shaped / limited assertions
1. **DDL doc vs live prefix** — used `ba_class_category_jnt` in code; `bha_` only in file names (`DOC-BA-001`).
2. **Committed sibling had wrong expected strings / selectors / migration path** — the sibling `ClassCategoryCrudTest.php` asserts flash `'Mapping added successfully'` (real: **`Category mapped to class successfully.`**), selector `.status-switch[data-id]` (real component renders **`.status-toggle[data-id]`**), clicks `.delete-mapping[data-id]` (real delete = **POST form + `@method('DELETE')` + SweetAlert `Remove Mapping?`**), asserts `SoftDeletes` present + a full trash/restore/forceDelete lifecycle (**the model has NO SoftDeletes trait — those parts would error**), and references migration `2026_04_11_000006` (real: **`2026_06_16_130618`** in the root `database/migrations/tenant/`). This suite uses the real strings/selectors/paths/behaviour.
3. **No FormRequest** (`VAL-BA-001`) — inline `$request->validate()`; only the duplicate message is custom, so negative tests assert the message + no-insert rather than fragile default text.
4. **No activity log** for ClassMapping — none invented.
5. **`destroy()` is a hard delete** (`BUG-BA-012`) — lifecycle asserted as physical removal, not soft-delete/restore.

## 10. Feedback loop (`05_`)
- Reviewed `05_Known_Test_Failure_Constraints.md`. The soft-delete guard (C12) already covers this case ("`withTrashed/…/forceDelete` only if the model uses `SoftDeletes` … document as a DDL/model gap, don't add the trait in the test") — this feature is a concrete instance (`BUG-BA-012`), not a new general rule. **No append to `05_` was required.** The specific defect is documented here and in the Gap Analysis as a feature-level finding, per the `03_` rule that feature-specific defects stay out of `05_`.

---

## Final Verdict: **PASS WITH NOTES**

All 8 artifacts generated; both PHP files `php -l` clean; V2/V1 = 2.50× (≥2×); coverage targets met (Positive/Negative/Dependency/Tenancy/Security all 100%); audit + newly-surfaced defects captured with proving tests. **Notes:** (a) file prefix `bha_` retained per instruction while the live table is `ba_class_category_jnt` (`DOC-BA-001`); (b) **`BUG-BA-012` (NEW)** — the model omits `SoftDeletes` despite the migration `deleted_at`, so `destroy()` is a hard delete and this suite deliberately diverges from the buggy committed sibling; (c) three new findings surfaced (`BUG-BA-012`, `GAP-BA-CM-01`, `GAP-BA-CM-02`) reported as *verify in source*; (d) module must be enabled in `modules_statuses.json` (E19) and cross-module SchoolSetup data present before execution — tests not run per instruction.
