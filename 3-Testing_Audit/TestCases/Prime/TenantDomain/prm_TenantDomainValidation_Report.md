# Tenant Domain — Validation Report (`prm_TenantDomainValidation_Report.md`)

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | prm_TenantDomainTcList_Require.md | ✅ |
| 2 | prm_TenantDomainMANUALTESTING_Require.md | ✅ |
| 3 | prm_TenantDomainGAPANALYSIS_Require.md | ✅ |
| 4 | prm_TenantDomain_TestCas.php | ✅ (single file, no V1/V2) |
| 5 | prm_TenantDomainValidation_Report.md | ✅ (this file) |
| 6 | run-TenantDomain-tests.ps1 | ✅ |
| 7 | run-TenantDomain-tests.sh | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix `prm_` matches DDL primary table `prm_tenant_domains` | ✅ (DDL `_prime_db_v4.sql:386`) |
| Feature PascalCase `TenantDomain` | ✅ |
| Class = filename `prm_TenantDomain_TestCas` | ✅ |
| snake_case methods `test_tenantdomain_NN_*` | ✅ |
| Semantic numbering bands (01-09 config, 10-19 biz, 20-29 SM, 30-39 val, 40-49 FK, 50-59 auth, 60-69 UI, 70-79 edge, 90-99 security) | ✅ |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| Namespace `Tests\Browser\Modules\Prime\TenantDomain` | ✅ |
| Extends `PrimeDuskTestCase` (central base, host-guarded 127.0.0.1) | ✅ (constraint E21/E22) |
| Central auth helpers implemented locally (from BillingDuskTestCase) | ✅ |
| `setUp()`/`tearDown()` present; typed props initialised (`?User $adminUser = null`) | ✅ |
| NO tenant scaffolding (central prime_db feature) | ✅ (constraint A4) |
| Uses `App\Models\User` | ✅ (constraint B5) |
| `php -l` | ✅ **No syntax errors detected** |
| Total method count | **47** |

## 4. Coverage Completeness
| Category | Coverage % |
|----------|-----------|
| Positive | 100% |
| State-machine | 100% |
| Negative | **100%** |
| Dependency | 100% |
| Permissions | 100% |
| Security | 100% |
| Edge | 100% |

- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 index).
- Gate targets met: Negative 100% ✅, Positive ≥90% ✅, Dependency ≥90% ✅. Tenancy-isolation gate **N/A** (central single-DB).

## 5. Known Source Defects Documented
| ID | Where | Proving test |
|----|-------|--------------|
| BUG-PRM-001 (remediated/not reproducible) | TcList §4, Gap §5 | test_15, test_01 |
| BUG-PRM-002 (hard delete) | TcList §4, Gap §4-5 | test_01, test_14 |
| BUG-PRM-003 (max vs column) | Gap §4-5 | test_39 |
| BUG-PRM-004 (encrypted overflow) | Gap §4-5 | test_71 |

> **IMPORTANT DISCREPANCY (BUG-PRM-001):** The orchestration brief and audit note stated `db_password` is stored PLAINTEXT because `Modules\Prime\Models\Domain` has "no `$casts`, no encrypted cast." The **current source contradicts this** — `Domain::casts()` returns `['db_password' => 'encrypted']` (Domain.php:16-21). Per HARD RULE 1/7 (read the real source; never assert against it; trust source, note discrepancy), the tests assert the **actual** behaviour: the encryption control is present and works (ciphertext at rest, decrypts on read). BR-PRM-006 = **PASS**, not FAIL. The brief's `test_01` instruction to assert "NO encrypted cast" was **not** followed because it would be a false assertion against verified source.

## 6. Environment Prerequisites
- **Prime module must be ENABLED** in `prime_testing/modules_statuses.json` (else all routes 404 — constraint E19).
- Prime/central tests **must run on `http://127.0.0.1:8000`** (constraint E21; enforced by `PrimeDuskTestCase::setUp()`).
- `APP_ENV=testing` (CSRF bypass — constraint E20); runners set it.
- Requires at least one `prm_tenant` row (dependent tests `markTestSkipped` otherwise).
- `sys_central_activity_logs` table present for activity assertions (fail-soft guarded — constraint 25).
- A valid `glb_languages` id for provisioning the limited permission-test user (constraint B10; skipped if absent).

## 7. Constraints Applied
- A4 (prime-side, no tenant init), B5 (`App\Models\User`), C12 (no `withTrashed`/`SoftDeletes` assumptions — model has no trait), C13 (typed props initialised), D14 (no Dusk `assertStatus`/`post` — used in-page fetch helper + JSON status), E19/E20/E21/E22, 25 (`sys_central_activity_logs` sink, fail-soft `Schema::hasTable`).

## 8. Final Verdict
**PASS WITH NOTES.**
- All 7 artifacts present; `php -l` clean; 47 methods; 100% coverage across categories; every TC ↔ method traced.
- **Notes:** (1) BUG-PRM-001 as briefed is **not reproducible** — encryption is present; tests prove the working control and document the stale brief. (2) Two genuine new defects found and mapped: **BUG-PRM-002** (hard delete — P1) and **BUG-PRM-003/004** (schema/validation/cast size mismatches — P2). (3) Suite not executed here (no `execute` flag) — static validation only.
