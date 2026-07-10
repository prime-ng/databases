# Academic Session — Validation Report

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `glb_AcademicSessionTcList_Require.md` | ✅ |
| 2 | `glb_AcademicSessionMANUALTESTING_Require.md` | ✅ |
| 3 | `glb_AcademicSessionGAPANALYSIS_Require.md` | ✅ |
| 4 | `glb_AcademicSession_TestCas.php` | ✅ (single file, no V1/V2) |
| 5 | `glb_AcademicSessionValidation_Report.md` | ✅ (this file) |
| 6 | `run-AcademicSession-tests.ps1` | ✅ |
| 7 | `run-AcademicSession-tests.sh` | ✅ |

## 2. Naming Conventions
- **Prefix `glb_`** — verified against DDL `_global_db_v4.sql`: `CREATE TABLE glb_academic_sessions`. ⚠ **Registry-vs-DDL flag:** the module registry lists Prime prefix `prm_`; this feature's primary table is `glb_academic_sessions` (shared `global_master` DB), so the file prefix correctly follows the DDL table rule (HARD RULE 4), not the module code.
- Feature PascalCase `AcademicSession`. Class name = filename `glb_AcademicSession_TestCas`.
- Methods snake_case, zero-padded, semantic bands (`test_academicsession_NN_*`).

## 3. Structure Validation
- `namespace Tests\Browser\Modules\Prime\AcademicSession;`
- `extends PrimeDuskTestCase` (preloader alias of `prm_PrimeDuskTestCase_TestCas` — constraint #22).
- Central auth/navigation helpers implemented locally (adapted from `BillingDuskTestCase`): `centralUrl`, `authenticateCentral`, `visitAuthenticated`, `browseCentral`, `ensurePageAccessible`, `resolveAdminUser`, screenshot helpers.
- Typed properties initialised (`?User $adminUser = null`, strings `= ''`).
- `setUp()`/`tearDown()` present; **no tenant scaffolding** (central scope); `tearDown` guards `tenancy()->initialized` and purges created rows.
- **`php -l`: PASS** (No syntax errors detected).
- Method count: **35**.

## 4. Coverage Completeness
- Positive 100%, Negative/Validation 100%, Dependency/State/Security 100% (see Gap Analysis). Tenancy N/A (central feature) — central-context invariant covered by `_90`; central activity sink by `_91`.
- Every TC-ID maps to ≥1 method; every method maps to a TC/BC. No V1/V2 ratio.

## 5. Constraints applied (from `05_Known_Test_Failure_Constraints.md`)
- **#21** Prime/central runs on `http://127.0.0.1:8000`; extends the module central base, not tenant scaffolding.
- **#22** filename↔classname mismatch resolves via preload alias; `php -l` is syntax-only.
- **#25** activity assertions target the **central** sink `sys_central_activity_logs` (connection `mysql`), asserted via `Schema::hasTable` + model `$fillable` (no consolidated DDL for it).
- **#14** Dusk cannot `assertStatus`/`post`; validation probes use the Laravel HTTP kernel (`actingAs()->post()->assertSessionHasErrors`), wrapped fail-soft.
- **#13** all typed props initialised. **#11/#12** force-delete wrapped in try/catch; SoftDeletes verified via `class_uses_recursive`.
- **#5** `App\Models\User` used (matches central siblings).

## 6. Environment prerequisites (E19/E20)
1. **`Prime` must be enabled** in `prime_testing/modules_statuses.json` (currently `false` → `/prime/*` returns 404). Route-dependent tests `markTestSkipped` until enabled.
2. `APP_ENV=testing` (CSRF bypass) — set by the runners.
3. `global_master_mysql` connection configured and `glb_academic_sessions` present, else schema/data tests skip fail-soft.
4. Super-admin user available (or `DUSK_ADMIN_*` creds) for authenticated flows.

## 7. Known Source Defects Documented
| ID | Sev | Where proven |
|----|-----|--------------|
| BUG-PRM-012 | P1 | `_01`, `_36` — dates unvalidated + `validated()` drops NOT NULL date columns |
| BUG-PRM-013 | P1 | `_01`, `_23` — `is_active` referenced but not a column (toggle 500, dead destroy guard) |
| BUG-PRM-011 | P1 | `_55` — model policy unreachable via string gates; `SessionBoardSetupPolicy` orphan; **no double registration** (audit re-characterized) |
| BR-PRM-021 | P2 | `_20`, `_21` — one-current enforced only at DB (unique current_flag) |
| BUG-PRM-014 | P3 | `_70` — update flash hyphen/case inconsistency |
| D25-PRM-001 | audit | **NOT REPRODUCED** — current source uses `$request->validated()`, not `$request->all()`; superseded by BUG-PRM-012 |

## 8. Final Verdict
**PASS WITH NOTES.**
- Artifacts complete (7 files), `php -l` clean, 35 methods, coverage gates met, all six defect items traced to source (five confirmed/re-characterized, one audit item not reproduced).
- Notes: (a) behavioural (runtime) proof of the P1 defects is asserted at source+schema level because the failing paths raise DB errors and the module is currently disabled — extend `_12`/`_23` to drive live endpoints once Prime is enabled and `global_master` seeded; (b) dedicated non-super-admin 403 case deferred pending central permission seeding; (c) prefix `glb_` intentionally diverges from the `prm_` registry hint per the DDL-table rule.
- No new general constraint was appended to `05_` — all findings are feature-specific (documented here and in the Gap Analysis).
