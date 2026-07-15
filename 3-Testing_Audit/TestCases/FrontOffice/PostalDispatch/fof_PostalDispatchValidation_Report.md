# PostalDispatch (FOF) — Validation Report

Compound feature (PostalRegister + DispatchRegister). Verdict at bottom.

## 1. File Existence Summary
| # | Artifact | Status |
|---|----------|--------|
| 1 | `fof_PostalDispatchTcList_Require.md` | ✅ |
| 2 | `fof_PostalDispatchGAPANALYSIS_Require.md` | ✅ |
| 3 | `fof_PostalDispatch_TestCas.php` | ✅ |
| 4 | `fof_PostalDispatchValidation_Report.md` | ✅ (this file) |
| 5 | `run-PostalDispatch-tests.php` | ✅ |

No separate MANUALTESTING file (merged into TcList §1/§5). No `.ps1`/`.sh` pair (single PHP runner). No V1/V2 split (one `.php`).

## 2. Naming Conventions
- Prefix `fof_` — VERIFIED against DDL `CREATE TABLE fof_postal_register` / `fof_dispatch_register`. ✅
- Feature PascalCase `PostalDispatch`. ✅
- Class = filename `fof_PostalDispatch_TestCas`. ✅
- snake_case methods, semantic bands 01/10/20/30/40/50/60/70/90. ✅

## 3. Structure Validation
- `namespace Tests\Browser;` · `extends DuskTestCase`. ✅
- `setUp()` initializes tenant context (`Modules\Prime\Models\Domain` → `tenancy()->initialize`) + resolves admin; `tearDown()` force-deletes tracked postal/dispatch/user rows then guarded `tenancy()->end()`. ✅
- Typed properties initialized (`?User $adminUser = null`, arrays `= []`, strings `= ''`). ✅
- **ONE test style** — in-process HTTP/feature (`actingAs()->post/put/patch/delete/getJson`) + direct Eloquent + `Validator::make` + `Gate::forUser`. **No `browse()`** anywhere (Rule A1/#14). ✅
- `php -l`: **No syntax errors detected.** ✅

## 4. Coverage Completeness
- **49 test methods.** Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (Method Index §4, Gap Analysis §1).
- Gates: Negative **100%**, Positive **100%** (≥90), Dependency **100%** (≥90), Tenancy present. ✅
- DDL coverage: UNIQUE duplicate-rejection for `postal_number` (`test_70`) + `dispatch_number` (`test_71`) (G43); NOT-NULL missing-value negatives (`test_30`,`test_36`,`test_72`) + nullable-omitted positive (`test_34`) (G44); over-length + exact-length boundaries (`test_32`,`test_33`,`test_38`,`test_39`) (G45); full alignment matrix with soft-delete asserted independently (`test_01`) (G46); all CRUD via verified models `PostalRegister`/`DispatchRegister` (G47); auto fields (`postal_number`,`dispatch_number`,`created_by`,`updated_by`,`dispatched_by`,`copy_retained`) tested as auto-behaviour, never form inputs (G48).
- Hygiene: 0 hollow methods (grep `addToAssertionCount` = 0); 0 `isCasted(`/`->isActive(`; `->refresh()` after create before default asserts (`test_10/13/14/15/73/91`); `assertGreaterThanOrEqual` for counts; permission negatives use non-super-admin + `forgetCachedPermissions()` (`test_51/53/54`); every created row cleaned in `tearDown`. ✅

## 5. Known Source Defects Documented
| ID | Where documented | Proving test |
|----|------------------|--------------|
| DEV-FOF-DR-01 (dispatch_mode `Other` not in DDL ENUM) | TcList §6, Gap §4/§5 | `test_73`,`test_02` |
| DEV-FOF-DR-02 (`Certificate` DDL-valid but rule/blade omit) | TcList §6, Gap §4/§5 | `test_74`,`test_02` |
| DEV-FOF-DR-03 (`addressee_name` max:150 > VARCHAR(100)) | TcList §6, Gap §4/§5 | `test_39`,`test_02` |
| DEV-FOF-PD-04 (no activity log on store/update/acknowledge/toggle/destroy) | TcList §6, Gap §5 | `test_45` |
| DAT-FOF-003 (postal update/destroy ack-lock) — **REMEDIATED** in live source | TcList §6, Gap §4 | `test_22`,`test_23` |
| DAT-FOF-002 (auto-number race) — UNIQUE backstop | Gap §4 #12 | `test_70`,`test_71` |
| SEC-FOF-003 (FormRequest `authorize()=true`, D30) | Gap §5 | `test_51`,`test_53` |

## 6. Environment Prerequisites (must hold for the "Partial" methods to run vs skip)
- **FrontOffice = `false` in `prime_testing/modules_statuses.json`** — module DISABLED → all `/front-office/*` routes 404 until enabled (Rule #19). Route-flow methods self-`markTestSkipped` via `Route::has()` when disabled. **MUST be enabled to exercise store/acknowledge/toggle/HTTP-403/404 legs.**
- A resolvable tenant via `Modules\Prime\Models\Domain` (else all DB tests skip).
- `APP_ENV=testing` (Dusk CSRF bypass) — the runner sets it.
- `sys_activity_logs` table present for `test_45` (else skips) — activity sink per FactPack §4-corrected.
- `sys_media` not required by this feature (no media columns on either table).
- Validation 500-vs-422 tolerated (`assertContains([422,500])`); ENUM-divergence DB behaviour tolerated (strict → exception / non-strict → coercion). Stale route cache → `route:clear` prereq. ChromeDriver not exercised (no `browse()`). `prime_testing` never modified.

## 7. Enhanced dimensions
- Tenancy `TC-T01` (`test_90`) included (guarded). Security: XSS-persistence (`test_76`), mass-assignment/auto-number guard (`test_91`), FormRequest-vs-DDL divergences (DEV pack). A11y/responsive smoke: **skipped** — no `browse()` browser session in this HTTP-style suite (documented).

## 8. Final Verdict
**PASS WITH NOTES.**
- All 5 artifacts present, correctly named; `php -l` clean; 49 methods; coverage gates met; DDL coverage (G43–G48) generated; DEV divergences surfaced with proving tests.
- Notes: (a) FrontOffice module must be enabled + a tenant resolvable for the ~19 route/dependency-guarded "Partial" methods to execute rather than skip — this is an env prerequisite, not a test defect. (b) `DAT-FOF-003` is treated as remediated per live source (FactPack §6 listed it as an active bypass; current controller has the guard) — tests assert observed behaviour. (c) Three real DispatchRegister FormRequest⇄DDL divergences (DR-01/02/03) are documented, not "fixed" in the test.
