# SessionBoardSetup — Validation Report (glb_)

- **Screen:** Session & Board Setup (READ-ONLY composite) · **Path:** `/prime/session-board-setup`
- **Test file:** `glb_SessionBoardSetup_TestCas.php`
- **Class:** `Tests\Browser\Modules\GlobalMaster\SessionBoardSetup\glb_SessionBoardSetup_TestCas extends \Tests\DuskTestCase`
- **Method count:** 26 · **`php -l`:** PASS (no syntax errors) · **Single PHP file:** confirmed (no V1/V2)

---

## 1. Environment prerequisites (must hold before running)

| Prereq | Required value | Why |
| --- | --- | --- |
| Modules enabled | **GlobalMaster** AND **Prime** = enabled in `modules_statuses.json` | live controller is Prime; models span both modules |
| `APP_ENV` | `testing` | Dusk central profile |
| Central host | app served at **`http://127.0.0.1:8000`** | `centralBaseUrl` default (override `DUSK_CENTRAL_URL`) |
| Admin creds | `DUSK_ADMIN_EMAIL` / `DUSK_ADMIN_PASSWORD` (default `root@tenant.com` / `password`) | central login |
| DB connection | `global_master_mysql` reachable | both models use it |
| ChromeDriver | running (Dusk) | browser bands |

No tenancy scaffolding is required or initialised — `setUp`/`tearDown` defensively **end** any leaked tenancy context and never init a tenant.

---

## 2. Structural validation

| Check | Result |
| --- | --- |
| Namespace `Tests\Browser\Modules\GlobalMaster\SessionBoardSetup` | PASS |
| Extends `\Tests\DuskTestCase` (self-contained) | PASS |
| Inline helper library present | PASS — `centralUrl`, `authenticateCentral`, `visitAuthenticated`, `ensurePageAccessible`, `browseWithFailureScreenshot`, `captureFailureScreenshot`, `resolveAdminUser`, `currentPath` |
| Typed props initialised in `setUp` | PASS — `$adminUser`, `$centralBaseUrl`, `$adminEmail`, `$adminPassword`, `$statusReportEntries` |
| `INDEX_PATH = '/prime/session-board-setup'` | PASS |
| Uses `App\Models\User` (+ password fillable via `bcrypt`) | PASS |
| DB truth via `Modules\Prime\Models\AcademicSession` + `Modules\GlobalMaster\Models\Board` | PASS |
| No `assertStatus` in browser context (403 via `getJson`) | PASS — `_31` |
| Data-dependent asserts guarded with `markTestSkipped` | PASS — sessions/boards emptiness guards |
| Cleanup guarded (best-effort user purge) | PASS |
| Single `.php` (no V1/V2) | PASS |
| No create/edit/delete matrix (read-only) | PASS — DEV-GLB-S01 |

---

## 3. Semantic-band inventory (26 methods)

| Band | Range | Count | Focus |
| --- | --- | --- | --- |
| Schema / model | 01–07 | 7 | tables, columns, models, unique keys, no-own-table |
| Business | 10–14 | 5 | single-current, start<end, is_active bool, S03, S02 |
| Negative / auth | 30–31 | 2 | guest redirect, 403 |
| Permission | 50–51 | 2 | tabs + panes |
| UI / read | 60–69 | 10 | render, title, both lists, search, status filter, pagination 10/4, page params, empty states, read-only |

---

## 4. Reconciliation / defects documented

| ID | Type | Where recorded |
| --- | --- | --- |
| DEV-GLB-S01 | Read-only resource; write methods are non-functional stubs | `_69`, Gap §5 |
| DEV-GLB-S02 | Dual divergent controllers (Prime live vs GlobalMaster dead) | `_14`, Gap §5 |
| DEV-GLB-S03 | `is_active` referenced on `glb_academic_sessions` (column absent; use `is_current`) | `_13`, Gap §5 |

---

## 5. How to run

```bash
# from prime_testing app root (host must be up on 127.0.0.1:8000)
php artisan dusk --filter=glb_SessionBoardSetup_TestCas
```

or via the bundled runners: `run-SessionBoardSetup-tests.ps1` (Windows) / `run-SessionBoardSetup-tests.sh` (macOS/Linux).

> The `.php` test file must be placed at `tests/Browser/Modules/GlobalMaster/SessionBoardSetup/` inside the `prime_testing` app for the namespace + report-path resolution to work. This artifact folder is the authoring/source-of-record location.

---

## 6. Confirmation summary
- ONE comprehensive, READ-FOCUSED PHP Dusk file — **26 methods** — `php -l` clean.
- Read-only composite served at **`/prime/session-board-setup`** by **Prime** (`SessionBoardSetupController`).
- Prefix **glb_**; backing tables **glb_academic_sessions** + **glb_boards**; screen owns no table.
- Defects/reconciliation **DEV-GLB-S01 / S02 / S03** documented across suite + gap analysis.
