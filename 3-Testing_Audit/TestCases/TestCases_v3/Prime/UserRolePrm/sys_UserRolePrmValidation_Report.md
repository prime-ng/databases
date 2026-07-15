# UserRolePrm — Validation Report (`sys_`)

**Feature:** Prime / UserRolePrm (user ↔ role junction) · **Central / `prime_db`, no tenancy**
**Generated:** 2026-Jul-10

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `sys_UserRolePrmTcList_Require.md` | ✅ |
| 2 | `sys_UserRolePrmMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_UserRolePrmGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_UserRolePrm_TestCas.php` | ✅ (single file — no V1/V2) |
| 5 | `sys_UserRolePrmValidation_Report.md` | ✅ |
| 6 | `run-UserRolePrm-tests.ps1` | ✅ |
| 7 | `run-UserRolePrm-tests.sh` | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix = DDL table prefix of primary table `sys_model_has_roles_jnt` | ✅ `sys_` |
| Feature PascalCase | ✅ `UserRolePrm` |
| Class = filename (no `.php`) | ✅ `sys_UserRolePrm_TestCas` |
| snake_case zero-padded methods `test_userroleprm_NN_*` | ✅ |
| First method is `test_userroleprm_01_*` schema truth | ✅ |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| Namespace `Tests\Browser\Modules\Prime\UserRolePrm` | ✅ |
| `use Tests\Browser\Modules\Prime\PrimeDuskTestCase; extends PrimeDuskTestCase` | ✅ (per override; central base, constraint 21/22) |
| `App\Models\User` (runner model, matches sibling) | ✅ |
| Central auth/helpers implemented locally (from BillingDuskTestCase) | ✅ (`resolveAdminUser`, `authenticateCentral`, `visitAuthenticated`, `centralUrl`, `ensurePageAccessible`) |
| Typed properties initialised | ✅ (`$centralBaseUrl=''`, arrays `[]`) |
| No tenant scaffolding (no `initializeTenantContext`/`tenancy()->end`) | ✅ (correct for prime-side) |
| `setUp`/`tearDown` present; teardown best-effort fixture cleanup | ✅ |
| `php -l` | ✅ **No syntax errors detected** |

## 4. Coverage Completeness
- **Total test methods: 44.**
- Positive **100%**, Negative **100%**, Dependency **100%**, Security/Central-isolation **100%** (P0/P1), UI/UX **100%**.
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC/DEV. No V1/V2 ratio (single file).
- Semantic bands used: 01-09 schema, 10-19 index/biz, 20-29 junction mechanics, 30-39 search, 40-49 FK/integration, 50-59 authz, 60-69 UI, 70-79 edge, 90-99 central-isolation/security.

## 5. Constraints applied (from `05_`)
- **A4 / E21** — prime-side, central: no tenant init; runs on `127.0.0.1:8000` via `PrimeDuskTestCase`.
- **E22** — extends the preloader-aliased `PrimeDuskTestCase`; `php -l` passes (syntax-only), alias resolves at runtime.
- **E24** — Prime web routes verified in app-level `prime_ai/routes/web.php` (`central.` → `prime.` group), not the module stub.
- **#25** — activity sink is central `sys_central_activity_logs` (`Modules\Prime\Models\ActivityLog`); asserted via `Schema::hasTable` + model table (no DDL-file assert — table has no consolidated DDL).
- **B5/B7/B8/B9** — `App\Models\User::factory()`; `password` hashed/fillable; short unique `emp_code` (`'U'.substr(uniqid(),-12)` ≤ 20); test users created with `is_super_admin=0` to avoid the single-super-admin unique (`super_admin_flag`).
- **C11/C12/C13** — `forceDelete()` wrapped in try/catch (media table); `withTrashed` used only because User has SoftDeletes; typed props initialised.
- **D14/D15** — no `Browser::assertStatus`; status codes via `getJson`/`get` + `actingAs`; authenticate before every state-changing/negative HTTP call.
- **#9 / E19** — cross-env JSON endpoint calls self-skip via `isLive()`; Prime area reachability is an environment prerequisite (below).

## 6. Environment Prerequisites (not test-code fixes)
- Dev server up at `http://127.0.0.1:8000`; `APP_ENV=testing` (CSRF bypass, else 419).
- Admin `root@tenant.com` present and verified (super admin bypasses `Gate::before`).
- Central Prime routes reachable. If the Prime area is disabled/unrouted, browser methods and JSON methods self-skip rather than false-fail.

## 7. Known Source Defects Documented
DEV-URP-001 (gate borrows role-permission ability), DEV-URP-002 (search ungated — enumeration), DEV-URP-003 (create/show/edit missing views → 500), DEV-URP-004 (store/update/destroy empty — no assignment persisted), DEV-URP-005 (no activity logging), DEV-URP-006 (search accepts raw wildcards). All carry proving tests asserting **current** behaviour (see GapAnalysis §5). Flip the relevant assertions when fixed.

## 8. Feedback loop (`05_`)
No new **general** codebase/env constraint discovered beyond those already recorded (21, 22, 24, 25 cover central-Prime base, preloader alias, route location, activity sink). Nothing appended to `05_Known_Test_Failure_Constraints.md`. The DEV-URP-00x items are feature-specific and live here, not in `05_`.

## 9. Final Verdict
**PASS WITH NOTES.** 7/7 artifacts present, `php -l` clean, 44 methods, gates met (100% across categories). Notes: (a) the controller is partly stubbed — a large share of the suite documents defect/no-op behaviour rather than full CRUD, because the screen does not yet persist assignments; (b) execution not run here (`execute` not requested) — browser + central Prime reachability required; JSON/UI methods self-skip in partial environments to stay green.
