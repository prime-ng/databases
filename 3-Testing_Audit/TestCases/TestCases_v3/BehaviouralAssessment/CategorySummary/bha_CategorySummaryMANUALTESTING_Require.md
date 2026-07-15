# bha_CategorySummary — Manual Testing Guide

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | CategorySummary — Category Summary Report |
| Requirement | `BehaviouralAssessment_v2/17-Category-Summary.md` |
| URL | `GET /behavioural-assessment/reports/categories` (route `behavioural-assessment.reports.categories`) |
| Filter params | `?period_id=<id>` (query-string only) |
| Controller | `BaReportController::categories()` |
| View | `behaviouralassessment::reports.categories` (breadcrumb "Category Performance") |
| Models (read) | `BaComputedScore` (`ba_computed_scores`), `BaCategory`, `BaClassCategoryJnt`, `ba_criteria`, `ba_rating_levels`, `SchoolClass` |
| Validation | none (read-only report) |
| Migrations | `2026_06_16_130619_create_ba_computed_scores_table.php` |
| CRUD type | **Report (read-only)** — no create/edit/delete |
| Soft delete | `ba_computed_scores` uses `SoftDeletes` (`deleted_at`) |
| Pagination | none on this screen (aggregated grid) |
| Activity log | none (read-only controller — documented absence) |
| Permissions | `tenant.behavioural-assessment.reports.{viewAny\|view\|export}` (this screen → `reports.view`) |
| DB scope | TENANT-side (tenant init required) |

> **CRITICAL — current broken behaviour (BUG-BA-013):** the Category Summary page **does not render**. `categories()`
> aggregates `AVG(score)/MIN(score)/MAX(score)` over `ba_computed_scores`, but the real column is `numeric_score`
> — there is no `score` column — so MySQL rejects the query (`Unknown column 'score'`) and the page returns
> **HTTP 500** every time it is opened. Manual test steps below assert this current state; when the controller is
> fixed (rename `score`→`numeric_score`), the render steps flip from "500" to the described grid.

---

## 2. Business Conditions (detail)

**BC-BIZ-02/03 — Category aggregation (BROKEN).**
`categories()` runs, in raw SQL:
```
SELECT category_id, AVG(score) AS avg_score, MIN(score) AS min_score,
       MAX(score) AS max_score, COUNT(DISTINCT student_id) AS student_count
FROM ba_computed_scores [WHERE period_id = ?] GROUP BY category_id
```
`score` is not a column of `ba_computed_scores` → `SQLSTATE[42S22]: 1054 Unknown column 'score'` → 500.
**Fix:** replace `score` with `numeric_score` (proven correct in test `_11`). Contrast: `student()` already uses
`avg('numeric_score')` and works.

**BC-BIZ-04 — Bottom-10 criteria (correct but unreachable).**
The criteria block aggregates `AVG(ba_rating_levels.numeric_value)` — a real column — but the request never gets
there because `$categoryAverages` errors first.

**BC-BIZ-05 — Anonymized report.** No student names/roll/admission numbers; only `student_count` + averages.

**BC-AUTH — Gates.** `categories()` and `export()` both `Gate::authorize('tenant.behavioural-assessment.reports.view')`.
Guest → `/login`. Non-super-admin without `reports.view` → 403 (fires before the broken query).

**BC-EDG — Requirement gaps.** Requirement filters (Class, Section), per-category columns (Top/Lowest Criterion,
Cohort Distribution), and PDF/CSV export are all **not implemented**; only a period filter and a Category/Polarity/
Students/Avg/Min/Max/Performance/Status grid + Bottom-10 + Class-applicability map exist. Export route is a live
`abort(501)` stub (BUG-BA-011). Screens 17 (Category-Summary) and 23 (Category-Performance) share one implementation.

---

## 3. Manual Test Cases

### TC-M01 — Schema truth (`_01`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `ba_computed_scores` columns | `numeric_score` present; **no** `score` column |
| 2 | `SELECT COUNT(*) FROM information_schema.columns WHERE table_name='ba_computed_scores' AND column_name='score'` | `0` |
| 3 | Model `BaComputedScore` fillable | includes `numeric_score`, excludes `score`; uses `SoftDeletes` |

### TC-M02 — BUG-BA-013 at the DB layer (`_11`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a computed score with `numeric_score=4.25` | row created |
| 2 | Run `SELECT AVG(score) FROM ba_computed_scores GROUP BY category_id` | **Error 1054 Unknown column 'score'** |
| 3 | Run `SELECT AVG(numeric_score) FROM ba_computed_scores GROUP BY category_id` | succeeds (proves one-word fix) |
| 4 | Clean up seed | row force-deleted |

### TC-M03 — BUG-BA-013 at the route (`_12`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as admin (has `reports.view`) | authenticated |
| 2 | Visit `/behavioural-assessment/reports/categories` | **HTTP 500** (Whoops / Unknown column 'score') |
| 3 | (If module disabled) | 404 → test SKIPPED, documented as env prerequisite |

### TC-M04 — Source confirmation (`_13`, `_15`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `categories()` body | contains `AVG(score)`, `MIN(score)`, `MAX(score)`; not `numeric_score` |
| 2 | Read `student()` body | contains `avg('numeric_score')` (correct — bug is category/class-specific) |

### TC-M05 — Anonymization (`_17`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `categories.blade.php` | no student name / roll_no / admission_no; renders `student_count` |

### TC-M06 — Reports Hub render + link (`_10`, `_62`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/behavioural-assessment/reports` as admin | Hub renders; card "Category & Criteria Performance" visible |
| 2 | Inspect page source | link to `reports/categories` present |

### TC-M07 — Permissions (`_50`, `_51`, `_52`, `_53`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit categories route as guest | redirect `/login` |
| 2 | Create non-super-admin without `reports.view`; GET categories via XHR | **403** |
| 3 | Read `BaReportPolicy` | maps `viewAny/view/export` → `reports.{ability}` |
| 4 | Read `export()` body | authorizes `reports.view`, NOT `reports.export` (VAL-BA-003) |

### TC-M08 — Filters (`_30`, `_31`, `_61`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Run category aggregate with a period filter | still errors on `score` (bug is unconditional) |
| 2 | GET categories with `?period_id=987654321` | 500 (or 404/302 if disabled) |
| 3 | Read view | only `name="period_id"` filter present |

### TC-M09 — Export stub (BUG-BA-011) (`_70`, `_72`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/behavioural-assessment/reports/export` as admin | **HTTP 501** "Export feature coming soon." |
| 2 | Read controller | no `StreamedResponse` / `fputcsv` — PDF/CSV export unimplemented (RPT-GAP-12) |

### TC-M10 — Requirement gaps (`_71`, `_73`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read view for Class/Section filters | absent (RPT-GAP-11) |
| 2 | Confirm route `reports.categories` exists once; view titled "Category Performance" | screens 17 & 23 share one impl (DOC-BA-002) |

### TC-M11 — FK & dependencies (`_40`, `_41`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `ba_computed_scores` FKs | `std_students`, `ba_categories`, `ba_assessment_periods` all RESTRICT |
| 2 | Confirm dependency tables exist | `ba_criteria`, `ba_rating_levels`, `ba_class_category_jnt` present |

### TC-M12 — Tenancy & API deadness (`_90`, `_91`, `_92`, `_93`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenant context initialized | table resolves inside tenant DB |
| 2 | `Route::has('behaviouralassessment.index')` | **false** (DEAD-BA-001) |
| 3 | Read `routes/api.php` | `auth:sanctum`, no `InitializeTenancyByDomain` |
| 4 | Read `RouteServiceProvider` | web routes carry full tenancy stack; api.php never loaded |
| 5 | Read view | category name printed with `{{ }}` (escaped), never `{!! !!}` |
