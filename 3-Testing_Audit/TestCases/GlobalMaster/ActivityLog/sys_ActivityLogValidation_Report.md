# Activity Log — Validation Report (`sys_`)

**Feature:** GlobalMaster / Activity Log (Prime-central, `prime_db`) — **READ-ONLY** central audit-sink viewer
**Generated:** 2026-Jul-10
**Test file:** `sys_ActivityLog_TestCas.php` — 23 methods, single comprehensive read-focused suite.

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|:---:|
| 1 | `sys_ActivityLogTcList_Require.md` | ✅ |
| 2 | `sys_ActivityLogMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_ActivityLogGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_ActivityLog_TestCas.php` | ✅ (single `.php` — no V1/V2) |
| 5 | `sys_ActivityLogValidation_Report.md` | ✅ |
| 6 | `run-ActivityLog-tests.ps1` | ✅ |
| 7 | `run-ActivityLog-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `sys_` = table prefix of the primary table `sys_central_activity_logs` (derived from `Modules\Prime\Models\ActivityLog::$table`). **Flagged: NOT `glb_`** — the module is GlobalMaster but the central sink table is `sys_`-prefixed. ✅
- **No-DDL gap flagged:** `sys_central_activity_logs` has no consolidated DDL in `_prime_db_v4.sql`; column-truth is derived from the model `$fillable` + the analogous tenant `activity_logs` migration (DEV-GLB-A01). ✅
- Feature PascalCase `ActivityLog`; class name = filename `sys_ActivityLog_TestCas`. ✅
- Methods snake_case, zero-padded, semantic bands (`test_activitylog_NN_*`). ✅

## 3. Structure Validation
- `class sys_ActivityLog_TestCas extends \Tests\DuskTestCase` — self-contained; central helper library inlined (`centralUrl` `http://127.0.0.1:8000`, `authenticateCentral`, `visitAuthenticated`, `ensurePageAccessible`, `browseWithFailureScreenshot`, `captureFailureScreenshot`, `resolveAdminUser`, `currentPath`). ✅
- Namespace `Tests\Browser\Modules\GlobalMaster\ActivityLog`. ✅
- `use App\Models\User;` + `Modules\Prime\Models\ActivityLog` for seeding/DB truth; NO tenant scaffolding (central `prime_db`). ✅
- Typed properties initialised in `setUp()` (`$adminUser`, `$limitedUser`, `$centralBaseUrl`, `$adminEmail`, `$adminPassword`). ✅
- `setUp()`/`tearDown()` guard that tenancy is **not** initialised; suite never inits a tenant. ✅
- Seeded rows cleaned up in `try/finally` via `DB::table('sys_central_activity_logs')->where('id',$id)->delete()`. ✅
- **NO SoftDeletes calls** (`withTrashed`/`onlyTrashed`) on `ActivityLog` — the model has no `deleted_at`. ✅
- `php -l` → **No syntax errors detected.** ✅
- Single comprehensive `.php` file (no V1/V2). ✅

## 4. Coverage Completeness
- **Total methods:** 23. Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (TcList §3 + Gap §1).
- Read-focused categories: Render **100%**, Search (subject/event/user/all) **100%**, Pagination **100%**, Permissions **100%**, Empty-state **100%**, Integration **100%**, Tenancy **100%**.
- Semantic bands: 01–09 config/model, 10–19 business + integration, 30–39 negative/security, 50–59 permissions/reconciliation, 60–69 UI/search, 70–79 cross-reference, 90–99 tenancy.
- **Deliberately excluded:** create/edit/delete matrix — the write controller methods are gated non-functional stubs (DEV-GLB-A02).

## 5. Known Source Defects Documented
| DEV | Sev | Status | Description | Where proven |
|-----|-----|--------|-------------|--------------|
| DEV-GLB-A01 | P2 | **Open** | `sys_central_activity_logs` has no consolidated DDL; prefix `sys_` (not `glb_`) | `_01`, `_02`, `_03` (Schema::hasTable guard) |
| DEV-GLB-A02 | P3 | **Open** | Write methods are gated stubs; two controllers (Prime live `paginate(20)` vs GlobalMaster dead `paginate(10)`) | `_51`, `_52` |
| DEV-GLB-A03 | P2 | **Open (cross-ref)** | Sink receives event `'Stored'` from Language `forceDelete` (wrong event) — defect owned by the Language feature | `_70` |

## 6. Constraints Applied (from `05_`)
- Central self-contained base (`extends \Tests\DuskTestCase`) on `127.0.0.1:8000`; no tenant init.
- GlobalMaster **and** Prime must be enabled in `modules_statuses.json` (else 404); central migration must have created `sys_central_activity_logs`.
- `APP_ENV=testing` (set by the runners).
- Browser has **no** `assertStatus` — status/redirect asserted by inspecting `currentPath()` / body text; no JSON endpoint is called (the `search()` AJAX method has no registered route, documented).
- `App\Models\User` + factory for the limited user (password fillable); typed props initialised; guarded cleanup.
- `ActivityLog` has NO SoftDeletes — `withTrashed`/`onlyTrashed` are never called.
- DB/render methods `markTestSkipped()` when the table is absent (DEV-GLB-A01) — partial environments stay green.

## 7. Environment Prerequisites
1. **GlobalMaster and Prime enabled** in `prime_testing/modules_statuses.json` (else 404).
2. Central app served on `http://127.0.0.1:8000`, `APP_ENV=testing`.
3. A resolvable super-admin (`DUSK_ADMIN_EMAIL` / `is_super_admin`).
4. `sys_central_activity_logs` table exists (central migration run). Absent → DB/render tests self-skip.

## 8. Final Verdict
**PASS WITH NOTES.** All 7 artifacts present; single suite `php -l` clean; read-focused coverage complete (render / search all-4-types / pagination / permissions / empty-state / central-sink integration); NO create/edit/delete matrix by design. Notes: (a) prefix is `sys_` not `glb_` and the table has no consolidated DDL (DEV-GLB-A01); (b) write methods are gated stubs and two controllers coexist (DEV-GLB-A02); (c) a wrong-event data-integrity slip is surfaced but owned by the Language feature (DEV-GLB-A03); (d) viewAny 403 is defensively self-skipping under the super-admin `Gate::before` bypass.
