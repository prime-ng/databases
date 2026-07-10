# Dropdown (PRM / Prime) — Validation Report

## 1. File Existence Summary
| # | Artifact | Status |
|---|----------|--------|
| 1 | `sys_DropdownTcList_Require.md` | ✅ |
| 2 | `sys_DropdownMANUALTESTING_Require.md` | ✅ |
| 3 | `sys_DropdownGAPANALYSIS_Require.md` | ✅ |
| 4 | `sys_Dropdown_TestCas.php` | ✅ (single file — no V1/V2) |
| 5 | `sys_DropdownValidation_Report.md` | ✅ (this file) |
| 6 | `run-Dropdown-tests.ps1` | ✅ |
| 7 | `run-Dropdown-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `sys_` — **DDL-verified** against `CREATE TABLE sys_dropdown_table` in `_prime_db_v4.sql`. (Registry lists module prefix `prm_`; the primary-table-prefix rule wins → **`sys_`**. Flagged for the caller as requested.)
- Feature PascalCase `Dropdown`. Class name = filename: `class sys_Dropdown_TestCas`. Methods snake_case, zero-padded, semantic bands (`test_dropdown_01..93`), `test_dropdown_01` first.

## 3. Structure Validation
- Namespace `Tests\Browser\Modules\Prime\Dropdown;`.
- `use Tests\Browser\Modules\Prime\PrimeDuskTestCase;` + `extends PrimeDuskTestCase` (mirrors the committed `prm_BillingDuskTestCase_TestCas` sibling; resolves at runtime via `tests/Browser/Modules/preload.php` alias — constraint #22).
- Central auth/helpers (`resolveAdminUser`, `authenticateCentral`, `visitAuthenticated`, `centralUrl`, `ensurePageAccessible`, screenshot helpers) implemented **locally**, adapted from `BillingDuskTestCase`. No tenant scaffolding (constraint #21 — Prime is central, host `127.0.0.1:8000`).
- Typed properties initialised (`?User $adminUser = null`, strings `''`, arrays `[]`) — safe for `tearDown()` (constraint #13).
- `App\Models\User` used (constraint #5). No `assertStatus()` on Browser (constraint #14). Central-DB writes guarded with `markTestSkipped` (constraints #11/#12).
- **`php -l`: PASS** (No syntax errors detected).

## 4. Coverage Completeness
- **Total methods: 41** (single comprehensive suite, no V1/V2 ratio).
- Coverage: Negative **100%**, Positive **92%**, Dependency/Lifecycle **100%**, Edge/Security/Route **100%**. Overall Full = 97.6%.
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §3 index).
- Semantic bands 01–09/10–19/20–29/30–39/40–49/50–59/60–69/70–79/90–99 all populated.

## 5. Known Source Defects Documented
| DEV ID | Where documented | Proving test |
|--------|------------------|--------------|
| DEV-DROPDOWN-001 (DDL missing deleted_at) | TcList, Gap §5 | test_dropdown_04 |
| DEV-DROPDOWN-002 (out-of-scope $dropdown in Trashed log) | TcList, Gap §5 | test_dropdown_13 |
| DEV-DROPDOWN-003 (inconsistent junction tables) | TcList, Gap §5 (#7) | test_dropdown_14 |
| DEV-DROPDOWN-004 (global key uniqueness vs composite) | TcList, Gap §5 (#8) | test_dropdown_73 |
| DEV-DROPDOWN-005 (narrow saveDropdownOption enum) | TcList, Gap §5 (#1) | test_dropdown_34 |
| DEV-DROPDOWN-006 (trashed key+value recreation collision) | TcList, Gap §5 | test_dropdown_72 |
| DEV-DROPDOWN-007 (no activity log on store/update) | TcList, Gap §5 | test_dropdown_12 |
| DEV-DROPDOWN-008 (removed str_slug() → fatal) | TcList, Gap §5 | test_dropdown_15 |

## 6. Environment Prerequisites (constraints E19/E20/E21)
- Prime module **ENABLED** in `prime_testing/modules_statuses.json` (else 404 on all routes).
- Run host **`http://127.0.0.1:8000`** (PrimeDuskTestCase `$this->fail()`s otherwise).
- `APP_ENV=testing` for CSRF bypass on state-changing requests.
- Central DB (`prime_db`) reachable; `sys_central_activity_logs` present (no consolidated DDL — asserted fail-soft).

## 7. Dimensions deliberately limited
- **End-to-end browser create** left partial (needs a seeded `sys_dropdown_needs` row + `canManageDropdownNeed`) — rule/route/model truth is automated instead; see Gap §3.
- **Cross-tenant IDOR** N/A — Dropdown is a central (non-tenant) resource; covered by central-domain route assertions (test_dropdown_90) instead.

## 8. Final Verdict
**PASS WITH NOTES.** All 7 artifacts present with correct names; single test file; `php -l` clean; coverage gates met (Neg 100%, Pos 92%, Dep 100%). Notes: (a) prefix is `sys_` not the registry's `prm_` (correct per DDL); (b) 8 source-defect candidates documented as `DEV-DROPDOWN-00x` with proving tests — reported as "verify in source"; (c) execution not run in this sub-run (`execute` not requested) — runners provided.
