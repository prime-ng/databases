# Student Scores Report — Validation Report

**Feature:** StudentScoresReport (screen 16) · **Module:** BehaviouralAssessment · **Generated:** 2026-Jul-14

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `bha_StudentScoresReportTcList_Require.md` | ✅ |
| 2 | `bha_StudentScoresReportMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_StudentScoresReportGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_StudentScoresReport_TestCas.php` | ✅ (single comprehensive file — no V1/V2) |
| 5 | `bha_StudentScoresReportValidation_Report.md` | ✅ (this file) |
| 6 | `run-StudentScoresReport-tests.ps1` | ✅ |
| 7 | `run-StudentScoresReport-tests.sh` | ✅ |

All 7 artifacts written under `TestCases/BehaviouralAssessment/StudentScoresReport/` only.

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Filename prefix `bha_` | ✅ (per verified caller rule — filename `bha_`, bodies assert live `ba_`) |
| Bodies assert live tables `ba_computed_scores`/`ba_assessments` | ✅ (asserting `bha_*` would false-fail — DOC-BA-001) |
| Feature PascalCase | ✅ `StudentScoresReport` |
| Class = filename (no `.php`) | ✅ `class bha_StudentScoresReport_TestCas` |
| snake_case, banded methods | ✅ `test_student_scores_report_NN_*` |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| `namespace Tests\Browser;` | ✅ |
| `extends DuskTestCase` (browser Dusk — mirrors committed sibling RatingScale) | ✅ |
| `setUp()`/`tearDown()` with tenant init + guarded `tenancy()->end()` | ✅ |
| Typed properties initialised (`?User $adminUser = null`, strings `= ''`) | ✅ |
| Reflection-based app-repo source resolution (constraints #29/#32) | ✅ |
| `php -l` | ✅ **No syntax errors detected** |

## 4. Coverage Completeness

- **Total test methods:** 33 (single file).
- **Bands:** 01–09 schema/route (4) · 10–19 render+data (6) · 30–39 negative (4) · 40–49 dependency (2) · 50–59 auth (7) · 60–69 UI/UX (3) · 70–79 edge/gaps (3) · 90–99 tenancy/API/security (4).
- **Category coverage (Full+Partial):** Positive 100%, Negative 100%, Dependency+State 100%, Defect-proving 100%, UI/UX 100%. No V1/V2 ratio applies (read-focused report screen; coverage-gated).
- **Traceability:** every TC-ID → ≥1 method; every method → a TC/BC (see TcList §3 Test Method Index and Gap Analysis §1).
- **Report scope:** no CRUD matrix by design (no create/edit/delete on a report screen).

## 5. Known Source Defects Documented

| ID | Where proven | Where documented |
|----|--------------|------------------|
| BUG-BA-011 (export 501 stub) | `_70` | TcList §4, MANUALTESTING §2, GapAnalysis §4/§5 |
| DEAD-BA-001 (dead API, no tenancy, unregistered) | `_91` | same |
| DOC-BA-001 (DDL `bha_` vs live `ba_`) | `_02` | same |
| **BUG-BA-013 (NEW — by-class reads non-existent `score` column → 0.00 scores)** | `_14` (+ `_15` contrast) | same |
| SEC-BA-003 (NEW — tab-nav vs controller gate key divergence) | `_55` | same |
| VAL-BA-003 (NEW — export gate ≠ policy `export` ability) | `_56` | same |
| RPT-GAP-01 (grid columns/banner unimplemented) | `_71` | same |
| RPT-GAP-02 (CSV export unimplemented) | `_72` | same |

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)

- A1/A2/A3/A4 — tenant-side scaffolding; `Modules\Prime\Models\Domain` resolution; guarded teardown; tenant DB scope (`ba_` prefix).
- B5/B7/B8/B9 — `App\Models\User` + factory; `password` fillable; `user_type='EMPLOYEE'` + short `emp_code` set defensively; unique suffix < 20 chars.
- C11/C13 — `forceDelete()` wrapped in try/catch; all typed props initialised.
- D14/D15/D17/D18 — status codes via browser `fetch` (Dusk has no `assertStatus`); authenticated before negatives; `SHOW COLUMNS`/`information_schema` with `assertStringContainsString`; ENUM/DECIMAL asserted case-sensitively.
- E19/E20 — **module must be enabled** in `modules_statuses.json` (env prerequisite, not a code fix); `APP_ENV=testing` set by runners.
- #23 — API resource asserted via `Route::has(...)` (unregistered) rather than assuming registration.
- #29/#31/#32 — source-text proofs resolved via `ReflectionClass(BaComputedScore)`; authorization negatives use a stripped non-super-admin user (Gate::before bypass avoided).

## 7. Environment Prerequisites

1. `BehaviouralAssessment: true` in `prime_testing/modules_statuses.json` (currently `false` → 404 everywhere).
2. `prime_ai` reachable alongside runner; `MAIN_PROJECT_PATH` set.
3. Tenant at `DUSK_TENANT_URL` (`http://test.localhost:8000`); admin `root@tenant.com`/`password`.
4. Source-text tests fail-soft (`markTestSkipped`) if the `prime_ai` repo is not readable from the runner.

## 8. Final Verdict

**PASS WITH NOTES.**

- All 7 artifacts present; single `_TestCas.php`; `php -l` clean; 33 methods; coverage gates met.
- Notes: (a) several methods fail-soft skip without a class-section/student row or an unreadable app repo — expected in partial environments; (b) this suite proves 8 defects, including the **new BUG-BA-013** data-correctness bug on the exact "scores vs computed_scores" path the screen exists for — the by-class scores grid is currently non-functional (all scores 0.00). Tests assert current (buggy) behaviour so they pass today and will flip if the source is fixed.
