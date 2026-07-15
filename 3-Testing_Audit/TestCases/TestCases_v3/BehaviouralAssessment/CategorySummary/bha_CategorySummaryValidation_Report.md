# bha_CategorySummary — Validation Report

**Feature:** CategorySummary (Category Summary Report) · **Module:** BehaviouralAssessment
**Generated:** 2026-Jul-14 · **Test style:** browser Dusk (`extends DuskTestCase`)

---

## 1. File Existence Summary (7/7)
| # | Artifact | Present |
|---|----------|:-------:|
| 1 | `bha_CategorySummaryTcList_Require.md` | ✅ |
| 2 | `bha_CategorySummaryMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_CategorySummaryGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_CategorySummary_TestCas.php` | ✅ (single file, no V1/V2) |
| 5 | `bha_CategorySummaryValidation_Report.md` | ✅ |
| 6 | `run-CategorySummary-tests.ps1` | ✅ |
| 7 | `run-CategorySummary-tests.sh` | ✅ |

All written under `TestCases/BehaviouralAssessment/CategorySummary/` (reused existing module folder, no dated folder). Nothing written outside `TestCases/`.

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| File prefix matches live DB (`ba_`) while filename uses inventory prefix (`bha_`) | ✅ (per DOC-BA-001 rule) |
| Primary table verified against migration/DDL (`ba_computed_scores`, col `numeric_score`) | ✅ |
| Feature PascalCase (`CategorySummary`) | ✅ |
| Class name = filename (`bha_CategorySummary_TestCas`) | ✅ |
| snake_case, zero-padded, banded methods (`test_category_summary_NN_*`) | ✅ |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| `namespace Tests\Browser;` + `extends DuskTestCase` | ✅ |
| `setUp()`/`tearDown()` with tenant init + guarded `tenancy()->end()` | ✅ |
| Typed properties initialised (`?User $adminUser = null`, string defaults) | ✅ |
| `php -l` clean | ✅ (No syntax errors detected) |
| Rich private helper library mirrored from committed sibling `StudentScoresReport` | ✅ |

## 4. Coverage Completeness
| Metric | Value |
|--------|-------|
| Total test methods | **32** |
| Positive coverage | 100% |
| Negative coverage | 100% |
| Dependency / Security / Tenancy | 100% |
| Requirement-gap coverage | 100% |
| Every TC ↔ ≥1 method / every method ↔ TC/BC | ✅ (Test Method Index in TcList) |
| Semantic numbering bands applied | ✅ (01–09, 10–19, 30–39, 40–49, 50–59, 60–69, 70–79, 90–99) |

Read-only report screen → CRUD/state-machine bands intentionally omitted (recorded in Gap Analysis §2).

## 5. Known Source Defects Documented
| ID | Severity | Where proven |
|----|----------|--------------|
| **BUG-BA-013** (P1, NEW) — Category Summary aggregates raw SQL `AVG/MIN/MAX(score)` on a non-existent column → HARD 500 | P1 | `_11`, `_12`, `_13`, `_14` |
| BUG-BA-011 — export = live `abort(501)` stub | P2 | `_70`, `_72` |
| DEAD-BA-001 — api resource: no tenancy + unregistered | P2 | `_91` |
| RPT-GAP-11 — Class/Section filters unimplemented | P2 | `_71` |
| RPT-GAP-12 — requirement columns + PDF/CSV export unimplemented | P2 | `_72` |
| VAL-BA-003 — export gates `reports.view` not `reports.export` | P3 | `_53` |
| DOC-BA-001 — DDL prefix `bha_` vs live `ba_` | P3 | `_02` |
| DOC-BA-002 — screens 17 & 23 share one implementation | P3 | `_73` |

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)
- A1/A2/A4 — tenant-side feature; `initializeTenantContext()` via `Modules\Prime\Models\Domain`; guarded teardown.
- B5/B8/B9 — `App\Models\User` + factory; `user_type`/`emp_code` set when columns exist; short unique suffix.
- C11/C13 — force-delete wrapped in try/catch; all typed props initialised.
- D14 — status codes via browser `fetch()` (`sendJsonRequestFromBrowser`), not Dusk `assertStatus`.
- C17 — schema types asserted with `assertStringContainsString('decimal'/'tinyint', …)`.
- #29/#32 — app source read via `ReflectionClass(BaComputedScore::class)->getFileName()` (runner `base_path` ≠ app repo); all source reads fail-soft `markTestSkipped`.
- #31 — authorization negative uses a fresh non-super-admin with `is_super_admin`/`super_admin_flag` cleared + roles/permissions synced empty.

## 7. Environment Prerequisites
- **BehaviouralAssessment must be ENABLED** in `prime_testing/modules_statuses.json` (else 404 on all routes; the route-level tests `_12`/`_31`/`_70` graceful-skip). (E19)
- `APP_ENV=testing` for Dusk (CSRF bypass) — set by both runners. (E20)
- Tenant DB reachable at `DUSK_TENANT_URL` with a `Domain` row; admin `root@tenant.com`.

## 8. Note on BUG-BA-013 test expectation
Test `_12` asserts the page currently returns **HTTP 500** — this deliberately encodes the *current broken behaviour*
(HARD RULE 10). When the controller is fixed (`score`→`numeric_score`), `_12`'s expectation must flip to 200 and `_11`
becomes a pure regression guard on the fixed query. The DB-level proof `_11` and source proof `_13` remain valid until the code is changed.

## 9. Final Verdict
**PASS WITH NOTES.**
- All 7 artifacts present; single test file; `php -l` clean; 32 methods; coverage gates met.
- Notes: (1) a real **P1** source defect (BUG-BA-013) is proven and the render test asserts current 500 behaviour; (2) route-level tests graceful-skip if the module is disabled; (3) three requirement-vs-implementation gaps (RPT-GAP-11/12, DOC-BA-002) are documented with proving tests.
