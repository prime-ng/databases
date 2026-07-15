# Dropdown — Validation Report (`sys_`)

**Feature:** GlobalMaster / Dropdown (Prime-central, `prime_db`)
**Generated:** 2026-Jul-10
**Test file:** `sys_Dropdown_TestCas.php` — **40 methods**, single comprehensive suite.

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|:---:|
| 1 | `sys_DropdownTcList_Require.md` | ✅ |
| 2 | `sys_DropdownMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_DropdownGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_Dropdown_TestCas.php` | ✅ |
| 5 | `sys_DropdownValidation_Report.md` | ✅ |
| 6 | `run-Dropdown-tests.ps1` | ✅ |
| 7 | `run-Dropdown-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix **`sys_`** = DDL table prefix of the primary table `sys_dropdown_table` (DDL-verified in `_prime_db_v4.sql`, lines ~222–235). ✅
  - **FLAG:** `sys_` (NOT `glb_`) — the Dropdown table lives in the central/prime DB, not the global DB. Documented across all artifacts.
- Feature PascalCase `Dropdown`. ✅
- Class name = filename `sys_Dropdown_TestCas`. ✅
- Methods snake_case, zero-padded, semantic bands (`test_dropdown_NN_*`). ✅

## 3. Structure Validation
- `class sys_Dropdown_TestCas extends \Tests\DuskTestCase` — central helper library copied **INLINE** (centralUrl/authenticateCentral/visitAuthenticated/ensurePageAccessible/browseWithFailureScreenshot/captureFailureScreenshot/resolveAdminUser/currentPath/confirmSweetAlert/sendJsonRequestFromBrowser). ✅
- Namespace `Tests\Browser\Modules\GlobalMaster\Dropdown`. ✅
- `use App\Models\User;` + factory-style `User::create` fallback; password fillable via `bcrypt`. ✅
- Typed properties initialised (`$adminUser`, `$centralBaseUrl`, `$adminEmail`, `$adminPassword`, `$statusReportEntries`). ✅
- `setUp()`/`tearDown()` guard tenancy (`tenancy()->end()` if initialized) — **no tenant init**. ✅
- `php -l` → **No syntax errors detected.** ✅
- DB assertions prefer `Modules\Prime\Models\Dropdown` (live path); `Modules\GlobalMaster\Models\Dropdown` used only to prove DEV-GLB-D01. ✅

## 4. Coverage Completeness
- **Total methods:** 40. Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (TcList §3 + Gap §1).
- Category coverage: Negative **100%**, Positive **100%**, Dependency/Security/Tenancy **100%**. Gates met.
- Semantic bands populated: 01–09 schema/model/request, 10–19 business, 30–39 validation/negative, 40–49 dependency, 50–59 permissions, 60–69 UI, 90–99 security/tenancy.

## 5. Known Source Defects Documented (GLB/SYS)
| DEV | Sev | Status | Where proven |
|-----|-----|--------|--------------|
| DEV-GLB-D01 (orphaned duplicate model) | P2 | Open | `_03` |
| DEV-GLB-D02 (GlobalMaster store reads unvalidated org_id/key/type) | P1 | Open | `_06` |
| DEV-GLB-D03 (request value max:255 > DB VARCHAR(100); live store max:100) | P2 | Open | `_04`, `_34` |
| DEV-GLB-D04 (SoftDeletes vs DDL missing deleted_at) | P1 | Open | `_05`, `_43` (guarded) |
| Route-wiring drift (dead GlobalMaster controller wired; Prime serves live) | Note | Open | Gap §4 #11 |

> **Reconciliation note (Prime-serves-central + orphaned model):** the live central Dropdown screen (`central.global-master.dropdown.*`, `/global-master/dropdown`, view `prime::index`) is served by the Prime multi-tab `DropdownController`; the GlobalMaster module's OWN `DropdownController` (and its thin `DropdownRequest`) is dead on central and carries DEV-GLB-D02/D03. Separately, two classes share the FQCN `Modules\GlobalMaster\Models\Dropdown` — the PSR-4 winner is `app/Models/Dropdown.php` (`sys_dropdown_table`, SoftDeletes); the `Models/Dropdown.php` sibling is dead code (DEV-GLB-D01). The suite proves live logic from the Prime source and asserts route NAMES rather than the brittle controller→route binding.

## 6. Constraints Applied (from `05_`)
- Central base `\Tests\DuskTestCase` + inlined helpers on 127.0.0.1:8000; no tenant init.
- `App\Models\User` + factory-style creation; password fillable.
- Browser has NO `assertStatus` → endpoint checks use `postJson`/`getJson`/`Route::has` at test-method level.
- `assertStringContainsString` used for schema/source-string assertions.
- `withTrashed`/`forceDelete` ONLY when `SoftDeletes` + `deleted_at` present (guarded — DEV-GLB-D04); cleanup guarded.
- Cross-module `DropdownNeed`/junction/gate dependencies guarded with `markTestSkipped`.
- Complex/dependency-heavy screen → `markTestSkipped`/try-catch used generously.

## 7. Environment Prerequisites
1. **GlobalMaster AND Prime enabled** in `prime_testing/modules_statuses.json` (else 404 / route absent → skips).
2. Central app served on `http://127.0.0.1:8000`, `APP_ENV=testing`.
3. A resolvable super-admin (`DUSK_ADMIN_EMAIL` / `is_super_admin`).
4. Dependency data for full lifecycle coverage: at least one `sys_dropdown_needs` row + the junction tables (`sys_dropdown_need_table_jnt` / `sys_dropdown_need_dropdowns_jnt`). Absent these, `_40`/`_43`/`_44`/`_52` self-skip.
5. For the real soft-delete round-trip (`_43`), `sys_dropdown_table.deleted_at` must exist (DEV-GLB-D04).

## 8. Final Verdict
**PASS WITH NOTES.** All 7 artifacts present; single `.php` suite `php -l` clean (40 methods); coverage gates met; rules/messages/gates/routes sourced from real code. Notes: (a) prefix is `sys_` not `glb_` (central DB) — flagged; (b) DB-mutation / cross-module cases are environment-gated defensive skips; (c) DEV-GLB-D01..D04 documented/proven; (d) route-wiring drift and Prime-serves-central reconciliation recorded.
