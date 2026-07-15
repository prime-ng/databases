# ClassAnalysis — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | ClassAnalysis (Class-Section Behaviour Analysis) — LIGHT report |
| URL | `/behavioural-assessment/reports/class/{classSection}` (`?period_id=` optional) |
| Route name | `behavioural-assessment.reports.class` |
| Controller | `BaReportController::byClass()` |
| View | `behaviouralassessment::reports.by-class` |
| Primary table | `ba_computed_scores` (live `ba_`; DDL doc `bha_` — DOC-BA-001) |
| Related tables | `std_students`, `sch_class_sections`, `ba_categories`, `ba_assessment_periods`, `ba_assessments`, `ba_incidents` |
| Validation | None (GET report; route-model binding `findOrFail`) |
| CRUD type | Read-only report/visualization |
| Soft delete | `ba_computed_scores` uses SoftDeletes (data source only) |
| Pagination | None (in-memory Collections) |
| Activity log | None (read-only) |
| Permissions | `tenant.behavioural-assessment.reports.{viewAny,view,export}` |
| Export | `reports/export` → `abort(501)` stub (BUG-BA-011) |

### Environment prerequisites
- BehaviouralAssessment **enabled** in `prime_testing/modules_statuses.json` (else 404 on all routes).
- `APP_ENV=testing`; tenant reachable at `DUSK_TENANT_URL` (`http://test.localhost:8000`).
- Admin `root@tenant.com` / `password`; at least one `sch_class_sections`, `std_students`, `ba_categories`, `ba_assessment_periods` row for full-data cases (tests skip gracefully otherwise).

## 2. Business Conditions (detailed)

- **BUG-BA-013 (data-correctness, class-level):** `byClass()` builds per-student overall as
  `round((float) $scores->avg('score'), 2)` and per-category `avg/min/max('score')`, `pluck('score')` for std-dev.
  `ba_computed_scores` has **no `score` column** (only `numeric_score`, `overall_score`). Reading a non-existent
  Eloquent attribute yields `null`, so `avg('score')` → `null` → `round((float) null, 2)` = **0.00**. Result:
  every student's overall renders `0.00`, every category avg/min/max/std-dev = `0.00`, and **every student is
  flagged at-risk** (`0.00 < 2.50`). The blade at-risk "low categories" filter (`$cs->score < 2.5`) is likewise
  always-true. The sibling `student()` path correctly uses `numeric_score`, so the defect is `byClass()`-specific.
- **BUG-BA-011:** `export()` is `abort(501, 'Export feature coming soon.')` on a live authorized route.
- **DEAD-BA-001:** `routes/api.php` = `Route::middleware(['auth:sanctum'])->prefix('v1')->apiResource(...)` — no
  tenancy bootstrapper — and `RouteServiceProvider::map()` maps only web routes, so the resource is never registered.
- **VAL-BA-003:** `export()` authorizes `reports.view` while `BaReportPolicy::export()` checks `reports.export`.

## 3. Manual Test Cases

### MT-01 — Render for authorized admin (`_10`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/behavioural-assessment/reports/class/{id}` | Page loads, not bounced to `/login` |
| 2 | Inspect page | Shows "Class Average Score" grid OR "No score data available" empty state; no "Whoops" |

### MT-02 — Filters render (`_11`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the report, inspect the selector bar | "Class-Section:" and "Period:" labels visible |
| 2 | Inspect DOM | `#classSectionSelect`, `select[name="period_id"]`, form `#byClassForm` present |

### MT-03 — Period filter (`_12`, `_13`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Append `?period_id={real}` | 200/302, narrowed data, no 500 |
| 2 | Append `?period_id=987654321` (unknown) | 200/302 (find() → null), no 500 |

### MT-04 — BUG-BA-013 class-level score correctness (`_14`,`_15`,`_16`,`_17`,`_72`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SELECT` on `ba_computed_scores` columns | `numeric_score` exists; **no `score` column** |
| 2 | Seed a computed score `numeric_score=4.50`; read model `->score` | `null` (BUG-BA-013 basis) |
| 3 | Compute `collect(rows)->avg('score')` vs `->avg('numeric_score')` | `avg('score')` = null → 0.00; `avg('numeric_score')` = 4.50 |
| 4 | Inspect `BaReportController::byClass()` body | contains `avg('score')`/`min('score')`/`max('score')`/`pluck('score')`, NOT `numeric_score` |
| 5 | Inspect `student()` body | contains `avg('numeric_score')` (contrast — correct) |
| 6 | Inspect `by-class.blade.php` | at-risk filter `->score < 2.5` (always true) |
| 7 | Seed 1.00 + 5.00 scores; compute std-dev over `score` | 0.00 (real numeric_score spread discarded) |

### MT-05 — Invalid ids (`_30`,`_31`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `.../reports/class/987654321` | 404 (findOrFail) |
| 2 | Visit `.../reports/class/not-a-number` | 404 |

### MT-06 — FK dependency (`_40`,`_41`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `information_schema` FK rules for `ba_computed_scores` | `std_students`/`ba_categories`/`ba_assessment_periods` = RESTRICT/NO ACTION |
| 2 | Inspect `byClass()` | students scoped by `class_section_id` + `is_active`; only `parent_id IS NULL` categories |

### MT-07 — Permissions (`_50`,`_51`,`_52`,`_53`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit report | Redirect to `/login` |
| 2 | Login as non-super-admin without `reports.view` | 403 on the report |
| 3 | Inspect `BaReportPolicy` | declares `reports.viewAny/view/export` |
| 4 | Inspect `export()` gate vs Policy | export() uses `reports.view`, Policy declares unused `reports.export` (VAL-BA-003) |

### MT-08 — UI/UX (`_60`,`_61`,`_62`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit report with unlikely period | Empty state or grid renders |
| 2 | Inspect | "All Reports" back-link to Reports Hub present |
| 3 | Inspect | At-risk threshold "2.50" / "At Risk" documented |

### MT-09 — Export / gaps (`_70`,`_71`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/behavioural-assessment/reports/export` as admin | HTTP 501 "Export feature coming soon." |
| 2 | Inspect controller | no `StreamedResponse`/`fputcsv` — CSV export unimplemented (CA-GAP-01) |

### MT-10 — Tenancy / API / security (`_90`,`_91`,`_92`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenancy initialized; `ba_computed_scores` resolves in tenant DB | true |
| 2 | `Route::has('behaviouralassessment.index')` | false; api.php has `auth:sanctum`, no `InitializeTenancyByDomain` (DEAD-BA-001) |
| 3 | Inspect rendered report source | no unescaped `<script>alert(` |
