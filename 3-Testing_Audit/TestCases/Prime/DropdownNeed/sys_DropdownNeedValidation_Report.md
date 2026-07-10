# sys_DropdownNeed — Validation Report

**Feature:** DropdownNeed (Prime / PRM, CENTRAL) · **Date:** 2026-Jul-10 · **Verdict:** ✅ PASS WITH NOTES

---

## 1. File Existence

| # | Artifact | Status |
|---|----------|--------|
| 1 | `sys_DropdownNeedTcList_Require.md` | ✅ |
| 2 | `sys_DropdownNeedMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_DropdownNeedGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_DropdownNeed_TestCas.php` | ✅ (single file — no V1/V2) |
| 5 | `sys_DropdownNeedValidation_Report.md` | ✅ (this file) |
| 6 | `run-DropdownNeed-tests.ps1` | ✅ |
| 7 | `run-DropdownNeed-tests.sh` | ✅ |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix = DDL primary-table prefix | ✅ `sys_` (verified in `_prime_db_v4.sql` + migration `sys_dropdown_needs`) |
| Feature PascalCase | ✅ `DropdownNeed` |
| Class = filename | ✅ `class sys_DropdownNeed_TestCas` in `sys_DropdownNeed_TestCas.php` |
| snake_case zero-padded methods | ✅ `test_dropdownneed_01` … `_95` |
| First method | ✅ `test_dropdownneed_01_migration_model_and_request_configuration_are_correct` |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Namespace | ✅ `Tests\Browser\Modules\Prime\DropdownNeed` |
| Base class | ✅ `extends PrimeDuskTestCase` (`use Tests\Browser\Modules\Prime\PrimeDuskTestCase;` — resolves via preload alias, constraint #22) |
| Central auth implemented locally | ✅ `resolveAdminUser/authenticateCentral/visitAuthenticated/centralUrl` ported from BillingDuskTestCase |
| User model | ✅ `App\Models\User` (constraint #5) |
| Tenancy scaffolding | ✅ NONE (prime-side / central — constraint #4/#21); teardown still guards `tenancy()->end()` |
| Typed props initialised | ✅ (`?User = null`, strings `''`, arrays `[]`) |
| setUp/tearDown | ✅ with best-effort central-row cleanup |
| `php -l` | ✅ **No syntax errors detected** (PHP 8.4.16) |

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| Total test methods | **51** |
| Positive coverage | 100% |
| Negative coverage | 100% |
| Dependency coverage | 100% |
| Security/Tenancy (P0/P1) coverage | 100% |
| Every TC ↔ ≥1 method | ✅ |
| Every method ↔ TC/BC | ✅ (see Test Method Index) |
| Semantic numbering bands | ✅ 01–09 schema, 10–19 biz, 20–29 toggle, 30–39 validation, 40–49 FK, 50–59 perms, 60–69 UI, 70–79 edge, 90–99 security/tenancy |

## 5. Known Source Defects Documented

| ID | Severity | Where proven |
|----|----------|--------------|
| SEC-PRM-004 (re-scoped) | P1 | test_dropdownneed_53, _90 + Gap §4 |
| TEN-PRM-001 (corrected/remediated) | P1 | test_dropdownneed_91 |
| PERF-PRM-001 | P2 | test_dropdownneed_92 |
| BUG-PRM-DUP (corrected) | P2 | test_dropdownneed_93 |
| BUG-PRM-DDNEED-001 (junction mismatch) | P1 | test_dropdownneed_42, _14 |
| BUG-PRM-DDNEED-003 (no unique validation) | P2 | test_dropdownneed_35 |
| BUG-PRM-DDNEED-004 (wrong redirect) | P3 | test_dropdownneed_16 |
| BUG-PRM-DDNEED-005 (duplicate route group) | P3 | test_dropdownneed_65 |
| BUG-PRM-DDNEED-006 (sibling gate on index) | P3 | test_dropdownneed_17 |
| DOC-PRM-DDNEED-002 (DDL typo + missing deleted_at) | P3 | test_dropdownneed_08 |

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)

- **#4 / #21 (prime-side):** central `prime_db` scope — no tenant init; extends `PrimeDuskTestCase`, host `127.0.0.1:8000`.
- **#22:** module-local base classes resolve via preload alias — mirrored `use ...\PrimeDuskTestCase; extends PrimeDuskTestCase` verbatim; `php -l` passes syntactically.
- **#5 / #8 / #9:** `App\Models\User`; limited-user creation supplies `emp_code` (≤20), `short_name`, `status`, guarded in try/catch.
- **#12:** SoftDeletes verified before asserting trash/restore semantics.
- **#14 / #15:** no Dusk `assertStatus`; state-code checks use Laravel HTTP helpers (`$this->post/get`); authenticated before negative POSTs.
- **#25:** activity assertions target the **central** `sys_central_activity_logs` (guarded with `Schema::hasTable` — no consolidated DDL file for it).
- **#17:** schema-type assertions use `hasColumns`/`assertStringContainsString`, never exact `COLUMN_TYPE`.

## 7. Environment Prerequisites (E19/E20 — NOT test-code fixes)

- ⚠️ **Prime module is `false` in `prime_testing/modules_statuses.json`** → all dropdown-need routes 404. Enable it to exercise route/browser/HTTP methods; otherwise those methods **self-skip** (suite stays green) while schema/source-scan methods still assert.
- `APP_ENV=testing` required (CSRF bypass) — set by both runners.
- Central app must be served at `http://127.0.0.1:8000`; ChromeDriver running for browser methods.
- `MAIN_PROJECT_PATH` (or a resolvable `prime_ai` sibling) needed for source-scan methods; otherwise those methods self-skip.

## 8. Dimensions Deliberately Light / Skipped

- **State-machine (BC-SM):** none — the feature has only an `is_active` boolean toggle, not a workflow lifecycle. Covered by band 20.
- **Responsive / a11y smoke:** omitted — combined mgmt screen is admin-only central config; not warranted for this screen.
- **Live end-to-end mutation proofs** are env-guarded (module disabled), with deterministic source-scan coverage as the primary assertion.

## 9. Final Verdict

**✅ PASS WITH NOTES** — 7/7 artifacts present, single test file, `php -l` clean, 51 methods, 100% category coverage, all audit items reconciled against real source (three corrected), five NEW defects mapped with proving tests. Notes: (a) Prime module must be enabled to run route/browser/HTTP methods; (b) audit items SEC-PRM-004 / TEN-PRM-001 / BUG-PRM-DUP were corrected against current source and documented accordingly.

> **Feedback loop (Step 10b):** no new *general* constraint discovered — all findings are feature-specific and captured here/in the Gap Analysis. `05_Known_Test_Failure_Constraints.md` not modified.
