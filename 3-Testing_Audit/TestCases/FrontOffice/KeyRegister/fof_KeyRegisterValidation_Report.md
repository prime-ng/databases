# FrontOffice :: KeyRegister — Validation Report

> Artifact 4 of 5. QA gate/verdict for the KeyRegister test artifact set.

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `fof_KeyRegisterTcList_Require.md` | ✅ |
| 2 | `fof_KeyRegisterGAPANALYSIS_Require.md` | ✅ |
| 3 | `fof_KeyRegister_TestCas.php` | ✅ |
| 4 | `fof_KeyRegisterValidation_Report.md` | ✅ (this file) |
| 5 | `run-KeyRegister-tests.php` | ✅ (single cross-platform runner — no .ps1/.sh) |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix matches DDL primary table | ✅ `fof_` verified vs `CREATE TABLE fof_key_register` |
| Feature PascalCase | ✅ `KeyRegister` |
| Class = filename | ✅ `class fof_KeyRegister_TestCas` |
| snake_case zero-padded methods | ✅ `test_keyregister_NN_*` |
| Semantic numbering bands | ✅ 01-09 schema, 10-19 biz, 20-29 SM, 30-39 val, 40-49 FK, 50-59 auth, 60-69 UI, 70-79 edge, 90-99 sec/DEV |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| `extends DuskTestCase` | ✅ |
| `namespace Tests\Browser;` | ✅ |
| setUp/tearDown with tenancy init/end | ✅ (`initializeTenantContextForTests()` / guarded `tenancy()->end()`) |
| Typed props initialised (`= null`) | ✅ `?User $adminUser = null` etc. |
| `php -l` clean | ✅ "No syntax errors detected" |
| ONE test style (no browse()+actingAs mix) | ✅ browser Dusk only |
| Private helper library mirrored verbatim from sibling | ✅ (FrontOffice\PhoneDiary) + `activityLogged()`/`purgeKey()`/`readClassSource()` added |

## 4. Coverage Completeness

- **Total test methods: 53.**
- Positive 21/21 (100%), Negative 11/11 (100%), Dependency 4/4 (100%), Permissions 5/5 (100%), State-machine 6 testable transitions + 2 documented source gaps, DEV proving 8/8.
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see Method Index in TcList §4).
- DDL coverage gates: G43 (duplicate — app-level test_35 + DB-level test_36), G44 (NOT-NULL negatives test_02 + nullable positives test_03), G45 (over-length + exact-n test_30/31/32), G46 (full alignment matrix test_01, soft-delete column & trait asserted independently), G47 (all CRUD via verified `KeyRegister` model), G48 (status/created_by/updated_by tested as auto-behaviour, never form inputs).
- Tenancy 100% on the tenant-side scaffolding (init/end every test).

## 5. Known Source Defects Documented

| ID | Where documented | Proving test |
|----|------------------|--------------|
| DEV-FOF-KR-001 (P1 create broken — key_type) | TcList §6, Gap §5, checks 8/13 | test_91, test_92, test_02 |
| DEV-FOF-KR-002 (P2 Blade location/description) | TcList §6, Gap check 4 | test_91, test_92 |
| DEV-FOF-KR-003 (P2 issue no issued_to) | TcList §6, Gap | test_26 |
| DEV-FOF-KR-004 (P2 app-unique, no DB unique) | TcList §6, Gap check 12 | test_01, test_36 |
| DEV-FOF-KR-005 (P2 store no activity log) | TcList §6, Gap | test_93 |
| DEV-FOF-KR-006 (P3 Overdue/Lost unreachable) | TcList §6, Gap check 7 | test_14 + doc |
| DEV-FOF-KR-007 (P3 keys/overdue API unregistered) | Gap check 2 | routes scan |
| DEV-FOF-KR-008 (P3 doc permission mismatch) | TcList BC-AUTH-08, Gap check 10 | — |
| SEC-FOF-003 (P1 authorize() true) | TcList §6 | test_94 |
| DAT-FOF-004 (REMEDIATED — issue row-lock) | TcList §6, Gap | test_95 |

## 6. Environment Prerequisites (must hold before the suite can run green)

1. **FrontOffice is DISABLED (`false`) in `prime_testing/modules_statuses.json`** (constraint #19). All `/front-office/*` routes 404 until it is enabled. This is an ENV prerequisite, not a code fix — MUST be enabled before running. When disabled, browser-flow tests that mutate through the controller (issue/return/update/destroy/store) will not persist; the suite's model-level assertions (schema, scopes, ENUM, casts, DDL coverage) still run.
2. **`APP_ENV=testing`** for Dusk CSRF bypass (#20) — the runner sets it.
3. **Copy `fof_KeyRegister_TestCas.php` into `prime_testing/tests/Browser/`** before invoking the runner (the runner filters on the class name).
4. **Valid tenant domain** reachable at `DUSK_TENANT_URL` (resolved via `Modules\Prime\Models\Domain`); ChromeDriver aligned with the installed Chrome (#41 — treated as infra, never asserted).
5. **Route cache**: run `php artisan route:clear` if `/front-office/keys` routes appear stale.
6. `sys_activity_logs` and `glb_languages` present in the tenant DB (used by activity assertions and limited-user creation). `sys_media` not required by KeyRegister (no media FK).
7. Validation failures may surface as **500 vs 422** and the broken create as **500** — all such assertions use tolerant status sets ({302,422,419,500}); never a brittle exact 422 (#41).

## 7. Enhanced Dimensions

| Dimension | Included? | Note |
|-----------|-----------|------|
| Security (stored XSS, authorize probe) | ✅ | test_90, test_94 |
| State-machine (legal + illegal transitions) | ✅ | test_20–25 |
| Tenancy scaffolding | ✅ | init/end each test |
| Cross-tenant IDOR | ⏭ Skipped | single-tenant runner; recorded as a follow-up (module is P1/P2, not P0) |
| Accessibility / console-error smoke | ⏭ Skipped | lighter FOF scope; can be added later |
| Responsive smoke | ⏭ Skipped | not required for this workflow screen |

## 8. Final Verdict

**PASS WITH NOTES.**

- All 5 artifacts present with exact names; `php -l` clean; 53 methods; coverage gates met (Negative 100%, Positive 100%, Dependency 100%).
- Notes: (a) The suite proves a **P1 create-flow defect (DEV-FOF-KR-001)** — creating a key via the UI is impossible because `key_type` (NOT NULL, no default) is never validated or set. (b) FrontOffice must be **enabled** in `modules_statuses.json` before an end-to-end Dusk run; until then browser-mutation tests will `markTestSkipped`/not persist while all model/DDL assertions still execute. (c) Activity events for issue/return are the literal lowercase strings `key_issued`/`key_returned`, not the module past-tense convention — asserted verbatim.
