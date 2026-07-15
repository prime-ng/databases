# bha_CategoryPerformance — Manual Testing Guide

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | CategoryPerformance — Category Performance dashboard (screen 23) |
| Screen requirement | `BehaviouralAssessment_v2/23-Category-Performance.md` |
| URL | `GET /behavioural-assessment/reports/categories` (filter `?period_id=`) |
| Route name | `behavioural-assessment.reports.categories` |
| Controller | `BaReportController::categories()` |
| View | `behaviouralassessment::reports.categories` (breadcrumb title "Category Performance") |
| Models | `BaComputedScore` (`ba_computed_scores`), `BaCategory`, `BaAssessmentPeriod`, `BaAssessmentRating`, `BaClassCategoryJnt`, `SchoolClass` |
| Primary read table | `ba_computed_scores` (live `ba_` prefix; DDL doc stale `bha_` — DOC-BA-001) |
| Validation | None (read-only report; filters are query-string) |
| Migration | `database/migrations/tenant/2026_06_16_130619_create_ba_computed_scores_table.php` |
| CRUD type | Read-only report / analytics dashboard (no create/edit/delete) |
| Soft delete | `ba_computed_scores` uses `SoftDeletes` (source rows), but this screen only reads |
| Pagination | None on the category grid (school-wide aggregate) |
| Activity log | None (read-only controller) |
| Permission prefix | `tenant.behavioural-assessment.reports.{viewAny\|view\|export}` |
| DB scope | TENANT-side (tenant init required) |

> **CRITICAL — screen 23 vs implementation:** the requirement describes an *advanced statistical dashboard*
> (Standard-Deviation bell curves, gender/boarding demographic splits, an academic-correlation matrix, and an
> SD>1.20 "High Grading Dispersal" warning). **None of this is built.** The `categories()` route runs only a flat
> per-category `AVG/MIN/MAX` aggregate — and that aggregate references a non-existent `score` column, so the page
> **returns HTTP 500 every time** (BUG-BA-013). Screens 23 and 17 share this single implementation (DOC-BA-002).

### Environment prerequisites
- `BehaviouralAssessment` **enabled** in `prime_testing/modules_statuses.json` (else 404 on all routes).
- `prime_ai` cloned alongside `prime_testing`; `MAIN_PROJECT_PATH` set (see TEST_SETUP.md).
- `APP_ENV=testing` (CSRF bypass for Dusk); admin `root@tenant.com` / `password`.
- Tenant reachable at `DUSK_TENANT_URL` (e.g. `http://test.localhost:8000`).

---

## 2. Business Conditions (with expected behaviour)

- **BUG-BA-013 (P1):** `categories()` builds `selectRaw('category_id, AVG(score) as avg_score, MIN(score) ..., MAX(score) ..., COUNT(DISTINCT student_id) ...')` on `ba_computed_scores`. The real column is `numeric_score`; there is no `score`. MySQL rejects with `SQLSTATE[42S22] Unknown column 'score'` → **500**. Fix = rename `score` → `numeric_score` in the three aggregates. When fixed, the page renders 200 and `_12` must flip to expect 200.
- **BUG-BA-011 (P2):** `GET /behavioural-assessment/reports/export` → `abort(501, 'Export feature coming soon.')`. Screen-23's "export to PDF for the annual developmental journal" is unavailable.
- **DEAD-BA-001 (P2):** `routes/api.php` declares `Route::middleware(['auth:sanctum'])->apiResource('behaviouralassessments', ...)` with no tenancy bootstrapper; `RouteServiceProvider::map()` maps only `web.php`, so the resource is never registered.
- **VAL-BA-003 (P3):** `export()` calls `Gate::authorize('tenant.behavioural-assessment.reports.view')` while `BaReportPolicy::export()` checks `reports.export` — the stronger export permission is dead.
- **DOC-BA-001 (P3):** DDL doc uses `bha_`; runtime tables are `ba_`.
- **DOC-BA-002 (P3):** screens 23 (Category-Performance) and 17 (Category-Summary) resolve to one `categories()` route/view titled "Category Performance". No distinct `categoryPerformance()` method or route exists.
- **RPT-GAP-11 (P2):** only a `period_id` filter exists; no Class / Section filter (screen-23 workflow selects Class "Grade 8").
- **RPT-GAP-12 (P2):** no "Calculate Statistics" control; no streamed PDF/CSV export.
- **RPT-GAP-21 (P2):** no Standard-Deviation / dispersion / bell-curve widget. `categories()` never computes a std deviation.
- **RPT-GAP-22 (P2):** no gender-wise or boarding-vs-day-scholar demographic split.
- **RPT-GAP-23 (P2):** no academic-correlation matrix (behaviour avg vs GPA).
- **RPT-GAP-24 (P2):** no SD>1.20 "High Grading Dispersal Detected" warning banner.
- **BC-EDG-09 (contrast):** `byClass()` (Class Analysis report) *does* compute a per-category `std_dev` in memory via `sqrt(...)` — the statistic screen-23 wants exists, just not on this route.

---

## 3. Test Cases (Step / Action / Expected)

### TC-N02 — Category Performance page HARD-500s (BUG-BA-013) — `_12`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as admin with `reports.view`; ensure `ba_computed_scores` has ≥1 row | Authenticated |
| 2 | GET `/behavioural-assessment/reports/categories` | HTTP **500** (Unknown column `score`) |
| 3 | DB check | `SELECT AVG(score) FROM ba_computed_scores` → SQL error 1054; `SELECT AVG(numeric_score) ...` → succeeds |
| 4 | When BUG-BA-013 is fixed | Page returns **200** and renders the school-wide grid; flip `_12` to expect 200 |

### TC-N01 — DB-level proof of the broken aggregate — `_11`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed one `ba_computed_scores` row (`numeric_score=4.25`) | Row persists |
| 2 | Run `AVG(score)` grouped by `category_id` | `QueryException` referencing unknown column `score` |
| 3 | Run identical query with `AVG(numeric_score)` | Succeeds (control) |
| 4 | Force-delete the seeded row | Clean state |

### TC-N10 — Export is a live 501 stub (BUG-BA-011) — `_70`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/behavioural-assessment/reports/export` as admin | HTTP **501** "Export feature coming soon." |

### TC-N08 / TC-N09 — Authorization — `_50`, `_51`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/reports/categories` as guest (no cookies) | Redirect to `/login` |
| 2 | Log in as a fresh non-super-admin user with no roles/permissions | Authenticated |
| 3 | XHR GET `/reports/categories` | HTTP **403** (gate fires before the broken query) |

### TC-G03 — Screens 23 & 17 share one implementation (DOC-BA-002) — `_73`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Route::has('behavioural-assessment.reports.categories')` | true |
| 2 | `Route::has(...category-performance)` / `...category-summary)` | false / false |
| 3 | `method_exists(BaReportController, 'categoryPerformance')` | false |
| 4 | Read `categories.blade.php` | Titled "Category Performance" (screen-23 label) |

### TC-G04..G07 — Statistical widgets not implemented — `_74`–`_77`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Grep `categories()` body + `categories.blade.php` for `std_dev` / `STDDEV` / "Standard Deviation" / "Dispersion" / "Bell Curve" | none present (RPT-GAP-21) |
| 2 | Grep for `gender` / `boarding` | none present (RPT-GAP-22) |
| 3 | Grep for `correlation` / `gpa` | none present (RPT-GAP-23) |
| 4 | Grep for `1.20` / "High Grading Dispersal" / "Polarized Grading" | none present (RPT-GAP-24) |
| 5 | Grep `byClass()` body | contains `std_dev` + `sqrt(` — the statistic exists elsewhere (contrast, `_78`) |

### TC-P01 — Schema truth — `_01`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Schema::hasColumns('ba_computed_scores', [...])` | true for all listed columns |
| 2 | `Schema::hasColumn(..., 'numeric_score')` / `..., 'score')` | true / **false** |
| 3 | Model `getFillable()` | contains `numeric_score`, not `score`; `SoftDeletes` used |
