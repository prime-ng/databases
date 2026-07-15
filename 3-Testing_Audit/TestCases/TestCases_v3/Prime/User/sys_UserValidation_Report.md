# Prime → User (PRM) — Validation Report (`sys_UserValidation_Report.md`)

## 1. File Existence Summary
| # | Artifact | Status |
|---|----------|--------|
| 1 | `sys_UserTcList_Require.md` | ✅ |
| 2 | `sys_UserMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_UserGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_User_TestCas.php` | ✅ |
| 5 | `sys_UserValidation_Report.md` | ✅ (this file) |
| 6 | `run-User-tests.ps1` | ✅ |
| 7 | `run-User-tests.sh` | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix matches DDL primary table | ✅ `sys_` = `sys_users` prefix (`_prime_db_v4.sql`). Registry maps PRM → `prm_`; per the table-prefix rule the primary table `sys_users` governs → `sys_` (recorded discrepancy) |
| Feature PascalCase | ✅ `User` |
| Class name = filename | ✅ `sys_User_TestCas` |
| snake_case, banded methods | ✅ `test_user_NN_*` |
| Single test file (no V1/V2) | ✅ exactly one `.php`, no V1/V2 split |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| Namespace | ✅ `Tests\Browser\Modules\Prime\User` |
| Base class | ✅ `extends PrimeDuskTestCase` (`use Tests\Browser\Modules\Prime\PrimeDuskTestCase`) — short alias via preload.php (Constraint #22) |
| Central auth helpers local | ✅ `authenticateCentral/visitAuthenticated/resolveAdminUser/currentPath/ensurePageAccessible/centralUrl` defined in-file |
| setUp/tearDown | ✅ parent setUp locks host; screenshots cleaned once; typed props initialised |
| Typed properties initialised | ✅ (`?User $adminUser = null`, strings `= ''`) — no "accessed before initialization" (Constraint #13) |
| `php -l` | ✅ No syntax errors detected |
| No tenant scaffolding | ✅ Central scope; `mysql` connection asserted; no `initializeTenantContext()` / `DUSK_TENANT_URL` |
| User model | ✅ `use App\Models\User;` (runner-bound to `sys_users`) — Constraint B/#5 |

## 4. Coverage Completeness
- **Total methods:** 44 (verified by `grep -c 'public function test_'`)
- **Positive:** 100% · **Negative:** 100% · **Dependency:** 100% · **Permissions:** 100% · **Security:** 100%
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §3 method index and Gap §1 mapping).
- Semantic bands used: 01-09 (config/schema/routes/gates), 10-19 (business), 30-39 (validation + activity log), 40-49 (FK/lifecycle), 50-59 (authz), 60-69 (UI), 70-79 (edge), 90-99 (security). **No 20-29 band** — feature has no state machine (BC-SM documented N/A: only `is_active` on/off + soft-delete).
- Single comprehensive file; coverage is met by the band/gate matrix, **not** a V1/V2 method-count ratio.

## 5. Known Source Defects Documented
| ID | Sev | Status | Where |
|----|-----|--------|-------|
| SEC-PRM-003 | P0 | **REMEDIATED** (update excludes is_super_admin; separate promote gate) | test_user_12, test_user_90; TcList §1; Gap §5 |
| BUG-PRM-002 | P0 | **REMEDIATED** (`$fillable` excludes is_super_admin & super_admin_flag) | test_user_01, test_user_91 |
| BUG-PRM-010 | P1 | **REMEDIATED** (usersByRole filters by `$role`) | test_user_14 |
| GAP-PRM-004 | P1 | **REMEDIATED** (store emails LoginMail to new user) | test_user_10 |
| FILL-PRM-001 | P3 | **RESIDUAL** (`remember_token` still fillable) | test_user_01 |
| BUG-PRM-009 | P2 | **RESIDUAL** (usersByRole `rand()` stub stats) | test_user_15 |
| BUG-PRM-N01 | P1 | **OPEN** (usersByRole omits totalTenants/activeTenants) | test_user_16 |
| BUG-PRM-N02 | P2 | **OPEN** (2FA field-name mismatch) | test_user_31 |
| BUG-PRM-N03 | P2 | **OPEN** (image rule key vs `user_img` upload key) | test_user_32 |
| BUG-PRM-N04 | P3 | **OPEN** (media collection mismatch) | Gap §4/§5 (documented) |

## 6. Constraints applied (from `05_Known_Test_Failure_Constraints.md`)
- **B / #5** `App\Models\User` used (runner-bound to `sys_users`) — matches the sibling; `password` fillable via factory/mass-assignment.
- **#8/#9** `sys_users` columns emp_code / prefered_language / user_type respected; `emp_code` unique suffix `'U' . substr(uniqid(), -8)` ≤ 20 chars.
- **#21** Prime/central features run on `http://127.0.0.1:8000` via `PrimeDuskTestCase` — applied; no tenant URL.
- **#22** Module-local base class resolves via preload.php short alias — mirrored `extends PrimeDuskTestCase`.
- **#24** Central WEB routes registered in app-level `routes/web.php` (not module stub) — `Route::has('central.prime.user.*')` (13 routes).
- **#25** Central activity sink `sys_central_activity_logs` — asserted with `Schema::hasTable` fail-soft guard + model `$fillable`, not a DDL `assertStringContainsString`.
- **#12** `withTrashed/forceDelete` only where the model uses SoftDeletes — Prime `User` does (asserted in test_user_01); functional forceDelete wrapped in `try/catch` (Constraint #11 media-table guard).
- **#14** Dusk has no `assertStatus()` — status/route via `Route::has`, browser flows via path/`assertSee`/`ensurePageAccessible`.
- **#17** Schema type/EXTRA asserted with `stripos(..., 'GENERATED')` and length equality, not exact `COLUMN_TYPE` string.

## 7. Environment prerequisites (not test-code fixes)
- Prime module **enabled** in `prime_testing/modules_statuses.json` (else 404 → browser tests self-fail via `ensurePageAccessible`; Constraint E19).
- Host `http://127.0.0.1:8000`; `APP_ENV=testing` (bypasses CSRF/419; Constraint E20). The runners set `APP_ENV=testing`.
- Super-admin user resolvable (`DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`) for privileged browser flows; central DB reachable on the `mysql` connection for functional/DB assertions.
- A seeded super-admin row for the generated-column and trigger checks (test_user_44/45 self-skip if absent).

## 8. Final Verdict
**PASS WITH NOTES.**
- 44-method single-file suite, `php -l` clean, 100% category coverage, all BC/TC traced, exactly one `.php` (no V1/V2).
- Notes: (1) SEC-PRM-003, BUG-PRM-002, BUG-PRM-010, GAP-PRM-004 are **remediated** in current source — the suite asserts the remediated state and fails loudly on regression, per the HARD RULE "prove current behaviour". (2) FILL-PRM-001, BUG-PRM-009, BUG-PRM-N01/N02/N03/N04 are live/residual defects with proving tests. (3) Functional and browser methods self-skip / fail-soft in partial environments by design; config-truth (schema/route/model/source) assertions remain hard and environment-independent.
