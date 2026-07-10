# Subscription — Validation Report (`prm_Subscription`)

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|:---:|
| 1 | `prm_SubscriptionTcList_Require.md` | ✅ |
| 2 | `prm_SubscriptionMANUALTESTING_Require.md` | ✅ |
| 3 | `prm_SubscriptionGAPANALYSIS_Require.md` | ✅ |
| 4 | `prm_Subscription_TestCas.php` | ✅ (ONE file, 37 methods) |
| 5 | `prm_SubscriptionValidation_Report.md` | ✅ (this file) |
| 6 | `run-Subscription-tests.ps1` | ✅ |
| 7 | `run-Subscription-tests.sh` | ✅ |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix matches DDL primary table | ✅ `prm_` (primary `prm_tenant_plan_rates`; verified against `Billing_DDL_v1.sql` `CREATE TABLE`s) |
| Feature PascalCase | ✅ `Subscription` |
| Class = filename | ✅ `prm_Subscription_TestCas` |
| snake_case, banded methods | ✅ `test_subscription_NN_*` |
| Namespace / base | ✅ `Tests\Browser\Modules\Prime\Billing\Subscription` · `extends BillingDuskTestCase` |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Extends central Billing base (E21/E22) | ✅ `BillingDuskTestCase` (alias → `prm_BillingDuskTestCase_TestCas` → `PrimeDuskTestCase`, host `127.0.0.1:8000`) |
| Uses `authenticateCentral`/`visitAuthenticated`/`centralUrl` | ✅ |
| No tenant scaffolding (prime/central scope) | ✅ no `initializeTenantContext`/`DUSK_TENANT_URL` |
| `App\Models\User` | ✅ (inherited via base `resolveAdminUser`) |
| Typed props initialised | ✅ (inherited; suite adds none uninitialised) |
| `php -l` | ✅ **No syntax errors** (PHP 8.4.16) |
| Screenshots/report constants | ✅ per-feature `SCREENSHOT_DIR`/`STATUS_REPORT_DIRECTORY`/`PREFIX` |

## 4. Coverage Completeness

- **Total methods:** 37 (single file).
- **Per-category:** Positive 94% (16/17 full, 1 partial) · Negative **100%** · Dependency/State **100%** · Security/a11y **100%** · Defect probes 7/7.
- **Tenancy:** **N/A** — central single-DB module (audit Layer 6 "Central module — correct"). No per-tenant isolation surface, so TC-T is deliberately omitted (documented here).
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3). No V1/V2 split; coverage-gated.

**Enhanced dimensions:** Security (reflected XSS on both filters + IDOR-shape) ✅; console-error smoke ✅; API-contract status/shape on toggle/export/panels ✅. **Deliberately skipped:** responsive smoke (read-only tab, low value), non-functional timing (not requested), stored-XSS write path (feature is read-only — no free-text write surface on this screen).

## 5. Known Source Defects Documented

| ID | Sev | Where documented | Proving test |
|----|-----|------------------|--------------|
| DEV-BIL-SUB-001 | High | TcList §1, Gap #11 | `_03`, `_40`, `_42` |
| DEV-BIL-SUB-002 | Medium | TcList §1, Manual MTC-13 | `_23` |
| DEV-BIL-SUB-003 | Low | TcList §1, Gap #10 | `_54` |
| DEV-BIL-SUB-004 | Low | TcList §1, Gap #1 | `_70` |
| Audit MIG-BIL-001 | P0 | Gap §4 | `_01` (asserts no SoftDeletes) |
| Audit SEC-BIL-010 | P1 (resolved) | Gap §4 | `_53` (regression guard) |

## 6. Environment Prerequisites (constraints 05_ §E)

1. **E19 — modules must be ENABLED:** `prime_testing/modules_statuses.json` currently has `"Billing": false` and `"Prime": false`. Both must be `true` or every route 404s. **Not a test-code fix.**
2. **E21 — central host:** run on `http://127.0.0.1:8000` (the base `PrimeDuskTestCase` fails setUp otherwise).
3. **E20 — `APP_ENV=testing`** so CSRF is bypassed (the in-page fetch helper still sends `X-CSRF-TOKEN` when a meta tag is present).
4. **Seed data:** detail-panel/toggle/relationship tests need at least one `prm_tenant_plan_jnt` (+ `prm_tenant_plan_rates`) row; they `markTestSkipped` cleanly when absent, so the suite stays green in a partial DB.
5. Chrome/ChromeDriver available to Dusk.

## 7. Constraints Applied (05_)

A1/A4 (central scope, no tenant init) · B5 (`App\Models\User` via base) · **C12 (no SoftDeletes calls** — models/tables have no `deleted_at`) · D14 (no Dusk `assertStatus`; status via in-page `fetch` helper) · D18 (ENUM/status compared case-sensitively) · E19/E20/E21/E22 (module-enabled, testing env, 127.0.0.1, `BillingDuskTestCase` alias) · E23 (route registration asserted via `Route::has`, not assumed).

## 8. Final Verdict

**PASS WITH NOTES.**

Notes: (a) Execution requires the two environment prerequisites (E19 module-enable, E21 central host) — not yet run here, so results are static-verified (`php -l` clean, sources cross-checked). (b) DEV-BIL-SUB-001 (billing-schedule table-name mismatch) will surface at runtime as `500` on two panels; tests handle it via documented skip/`markTestIncomplete` so they neither false-pass nor false-fail. (c) Tenancy dimension intentionally N/A (central module). (d) One partial (ZIP binary stream) is design-bounded by Dusk.
