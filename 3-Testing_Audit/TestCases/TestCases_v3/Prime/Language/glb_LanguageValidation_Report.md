# Language (PRM / GlobalMaster) — Validation Report

## 1. File Existence Summary
| # | File | Status |
|---|------|--------|
| 1 | glb_LanguageTcList_Require.md | Present |
| 2 | glb_LanguageMANUALTESTING_Require.md | Present |
| 3 | glb_LanguageGAPANALYSIS_Require.md | Present |
| 4 | glb_Language_TestCas.php | Present (single file — no V1/V2) |
| 5 | glb_LanguageValidation_Report.md | Present (this file) |
| 6 | run-Language-tests.ps1 | Present |
| 7 | run-Language-tests.sh | Present |

## 2. Naming Conventions
- Prefix `glb_` = DDL table prefix of the primary table `glb_languages` (verified in `_global_db_v4.sql` and the migration). **FLAG:** the module registry PREFIX for Prime is `prm_`; the DDL-table-prefix rule (authoritative) yields `glb_` for this feature. File prefix follows the table rule → `glb_`.
- Feature folder `Language` (PascalCase). Class `glb_Language_TestCas` = filename. Methods snake_case, zero-padded, semantic bands (01-09 config, 10-19 biz, 20-29 SM, 30-39 val, 40-49 int, 50-59 auth, 60-69 uix, 70-79 edge, 90-99 tenancy/security).

## 3. Structure Validation
- Namespace `Tests\Browser\Modules\Prime\Language`. `use Tests\Browser\Modules\Prime\PrimeDuskTestCase;` + `extends PrimeDuskTestCase` (resolves via `preload.php` alias — constraint #22).
- Central scope: no tenant scaffolding; central auth helpers (`resolveAdminUser`, `authenticateCentral`, `visitAuthenticated`, `centralUrl`, `ensurePageAccessible`, screenshot helpers) implemented locally, modeled on `prm_BillingDuskTestCase_TestCas`.
- Typed properties initialised (`?User $adminUser = null`, arrays/strings defaulted). `setUp()`/`tearDown()` present; tearDown cleans test-created rows (no tenancy end needed — central).
- `App\Models\User` (constraint #5). Host guard inherited from `PrimeDuskTestCase` (127.0.0.1 — constraint #21).
- **`php -l`: PASS — "No syntax errors detected".**

## 4. Coverage Completeness
- **Total methods: 48.** Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 + GapAnalysis §1).
- Coverage: Positive 100%, Negative 100% (perm-negatives structural), Dependency 100% (defensive), State-Machine 100%, Edge/Security/Tenancy 100%. No V1/V2 ratio applied.

## 5. Constraints applied (from 05_)
- #21 central host 127.0.0.1 (inherited guard). #22 base-class alias via preloader. #25 central activity sink `sys_central_activity_logs` (fail-soft `Schema::hasTable` guard). #10 glb_languages VIEW + FK to `sys_users.prefered_language`. #5/#7 `App\Models\User`. #12 SoftDeletes verified before trashed/restore assertions. #14 no Dusk `assertStatus` — status checks use page-source/path/JSON-from-browser fetch. #17 MySQL 8 type variance tolerated (SHOW INDEX, hasColumn). #19 module-enabled prerequisite (below).

## 6. Environment Prerequisites
- Prime + GlobalMaster modules **enabled** in `prime_testing/modules_statuses.json` (else all routes 404 — constraint #19). NOT a test-code fix.
- Run on `http://127.0.0.1:8000` with `APP_ENV=testing`; a super-admin user with `is_super_admin=1 && super_admin_flag=1` (or seeded `prime.language.*` permissions).
- Writes land in the shared `global_master.glb_languages` base table; tests use unique code/name and self-clean in tearDown.

## 7. Known Source Defects Documented
DEV-LANG-002 (duplicate route group), DEV-LANG-003 (forceDelete logs `Stored`), DEV-LANG-004 (update flash `'update.language'` unresolved), DEV-LANG-005 (no activity log on store/update), DEV-LANG-006 (double authorize in update), DEV-LANG-007 (restore leaves inactive), DOC-LANG-008 (stale consolidated DDL), DEV-LANG-009 (prime_db VIEW / global_master write path). Each has a proving test.

## 8. VIEW Limitation Note
The special "VIEW blocks writes" concern (constraint #10) does **NOT** materialise as a write block: the Model targets `global_master_mysql` directly, so store/update/destroy/restore/forceDelete/toggle all operate on the real base table (which the migration equips with softDeletes + timestamps). The prime_db `glb_languages` view is a read mirror. Therefore the matrix is **full CRUD**, not read-only. The genuine VIEW-related risks — global sharing across tenants and the `sys_users.prefered_language` FK on force-delete — are captured as BC-REF-01/BC-INT-01/BC-EDG-01 with defensive tests (40/41/42/70/90).

## 9. Final Verdict
**PASS WITH NOTES.** Artifacts complete, `php -l` clean, sourced from real code (routes/gates/events/selectors verbatim). Notes: (a) prefix `glb_` differs from registry `prm_` by the table-prefix rule; (b) real route names are `central.global-master.language.*` not the anticipated `central.prime.language.*`; (c) 8 documented source defects; (d) permission-negative and FK tests are structural/env-guarded pending seeded central permissions.
