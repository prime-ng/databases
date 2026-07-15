# Reports Hub — Validation Report (`bha_ReportsHub`)

**Feature:** ReportsHub · **Module:** BehaviouralAssessment · **Type:** REPORT/navigation hub (LIGHT) · **Date:** 2026-Jul-14

## 1. File Existence Summary
| # | Artifact | Status |
|---|----------|--------|
| 1 | `bha_ReportsHubTcList_Require.md` | ✅ |
| 2 | `bha_ReportsHubMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_ReportsHubGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_ReportsHub_TestCas.php` | ✅ (single file, no V1/V2) |
| 5 | `bha_ReportsHubValidation_Report.md` | ✅ (this file) |
| 6 | `run-ReportsHub-tests.ps1` | ✅ |
| 7 | `run-ReportsHub-tests.sh` | ✅ |

All 7 written under `TestCases/BehaviouralAssessment/ReportsHub/` only. Nothing written outside `TestCases/`.

## 2. Naming Conventions
- Filename prefix `bha_` (inventory/folder convention); **live tables asserted are `ba_`** per DOC-BA-001 — deliberate and correct.
- Feature PascalCase `ReportsHub`; class name = filename `bha_ReportsHub_TestCas`; namespace `Tests\Browser`.
- Methods snake_case, zero-padded, semantic bands: `test_reports_hub_NN_*`.

## 3. Structure Validation
- Extends `DuskTestCase`; `setUp()` inits tenant context + resolves admin; `tearDown()` guards `tenancy()->end()`.
- Typed properties initialised (`?User $adminUser = null`, string props `= ''`).
- `php -l`: **No syntax errors detected.**
- Mirrors the verified sibling `RatingScale/bha_RatingScale_TestCas.php` (helpers, tenancy scaffolding, `sendJsonRequestFromBrowser`, app-repo reflection resolution).

## 4. Coverage Completeness
- **Total methods: 27** (light read-focused report screen).
- Negative coverage **100%** (guest redirect, 403 on hub/incidents/export, 404 edge, both defects, reflected XSS).
- Positive/render/links **93%** Full (1 defensive partial: `_42` skips without a period row).
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §3 Test Method Index).
- Bands used: 01–09 config, 10–19 render, 40–49 links/defects, 50–59 permissions, 60–69 UI, 70–79 edge, 80–89 requirement-gap, 90–99 tenancy/security.

## 5. Known Source Defects Documented
| ID | Where | Proving test |
|----|-------|--------------|
| BUG-BA-011 (export 501 stub) | TcList §Known Defects, Gap §4 | `_45`, `_71` |
| DEAD-BA-001 (api route no tenancy + unregistered) | TcList §Known Defects, Gap §4 (Check 2) | `_46` |
| DOC-BA-001 (bha_ vs ba_ prefix) | TcList BC-DB-06, Gap §4 | `_02` |
| HUB-GAP-01/02/03 (filter panel / export controls / freshness label absent) | Gap §4 gaps | `_80`, `_81` |

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)
- A1/A2/A3: tenant resolved via `Modules\Prime\Models\Domain`; guarded `tenancy()->end()`.
- A4: tenant-side (`ba_` prefix, tenant_db) → tenancy scaffolding emitted.
- B5/B7/B8/B9: `App\Models\User::factory()` for the limited user; `password` fillable; `user_type`/`emp_code` set conditionally; short unique suffix.
- D14: no Dusk `assertStatus()` — status codes captured via `sendJsonRequestFromBrowser` (fetch). D16: browse closures use `use()`.
- E19: **BehaviouralAssessment must be enabled in `modules_statuses.json`** (env prerequisite — noted in both runners). E20: `APP_ENV=testing` set by runners.
- #29/#32: app-repo source (controller/policy/api.php) resolved via `ReflectionClass(BaAssessment)` → module root; fail-soft when unreadable.
- #31: authorization negatives use a stripped non-super-admin user (`makeLimitedUser` clears `is_super_admin`/`super_admin_flag` + syncs no roles/perms), so `Gate::before` Super-Admin bypass does not mask the 403s.

## 7. Dimensions Deliberately Skipped
- No CRUD/validation-matrix, state-machine, or activity-log assertions — the hub is read-only and takes no input (correct for a LIGHT report screen).
- Responsive/console-error smoke omitted (out of scope for this hub); cross-tenant isolation is defensive (`_91`).

## 8. Final Verdict
**PASS WITH NOTES.**
- Notes: (1) requires the module enabled + a live tenant DB to execute (not run here — `php -l` clean, static route/gate/source facts verified against real source). (2) `_42` self-skips absent a period row; `_91` self-skips with a single tenant. (3) BUG-BA-011 and DEAD-BA-001 are real source defects proven by tests, not test bugs.
