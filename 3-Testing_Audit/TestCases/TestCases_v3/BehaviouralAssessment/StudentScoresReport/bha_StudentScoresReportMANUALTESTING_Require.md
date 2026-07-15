# Student Scores Report — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | StudentScoresReport (screen 16 — `16-Student-Scores-Report.md`) |
| Type | Report — read-focused (LIGHT); no CRUD matrix |
| Primary URL (hub) | `/behavioural-assessment/reports` (`reports.index`) |
| Tab UI URL | `/behavioural-assessment/reports-page?tab=student-scores` (`reports-page`) |
| Scores grid URL | `/behavioural-assessment/reports/class/{classSection}` (`reports.class` → `byClass`) |
| Per-student URL | `/behavioural-assessment/reports/student/{student}` (`reports.student`) |
| Export URL | `/behavioural-assessment/reports/export` (`reports.export` — **abort(501) stub**) |
| Controller | `BaReportController` (+ alias `BaDashboardController::reportsPage`) |
| Models | `BaComputedScore` (`ba_computed_scores`), `BaAssessment` (`ba_assessments`) |
| Validation | None (report; GET filters only: `period_id`, `class_section_id`, `student` route param) |
| Migrations | `database/migrations/tenant/2026_06_16_130619_create_ba_computed_scores_table.php` |
| Soft delete | Yes (`ba_computed_scores.deleted_at`) — report reads active rows |
| Pagination | Student-Scores tab: 20/page (`ss_page`); Incident report: 25/page |
| Activity log | **None** — read-only report controller |
| Permissions | `tenant.behavioural-assessment.reports.{viewAny\|view\|export}`; tab shell `reports-page.{viewAny\|view}` |
| DB scope | TENANT-side (tenant_db) → tenancy scaffolding required |

**Environment prerequisites:** the `BehaviouralAssessment` module must be enabled in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). Run under `APP_ENV=testing`. Tenant reachable at `DUSK_TENANT_URL` (`http://test.localhost:8000`); admin `root@tenant.com` / `password`.

---

## 2. Business Conditions (detailed)

**Live schema truth (`ba_computed_scores`).** Category score is `numeric_score DECIMAL(5,2)`, overall is `overall_score DECIMAL(5,2)`; unique `(student_id, category_id, period_id)`; soft-deleted; FKs to `std_students`/`ba_categories`/`ba_assessment_periods` all `ON DELETE RESTRICT`. **There is no bare `score` column.**

**Data-correctness defect (BUG-BA-013).** `BaReportController::byClass()` (the Student Scores drill grid) and `categories()` aggregate with `$scores->avg('score')`, `->min('score')`, `->max('score')`, and read `$cs->score` in `by-class.blade`. Because `BaComputedScore` has neither a `score` column nor a `score` accessor, every aggregate resolves to null → each student's `overall_score` renders as `0.00`, the class average is null, and **every student is wrongly flagged "at risk" (< 2.50)**. `BaReportController::student()` uses the correct `avg('numeric_score')`, so the per-student report is unaffected — this pinpoints the bug to `byClass`/`categories`.

**Export defect (BUG-BA-011).** `export()` runs `Gate::authorize('tenant.behavioural-assessment.reports.view')` then `abort(501, 'Export feature coming soon.')`. An authorized user therefore receives **HTTP 501**. The screen-16 requirement's "export to CSV" is unimplemented (no `fputcsv`/`StreamedResponse`).

**Dead API (DEAD-BA-001).** `Modules/BehaviouralAssessment/routes/api.php` declares `Route::middleware(['auth:sanctum'])->apiResource('behaviouralassessments', ...)` with **no tenancy bootstrapper**; the `RouteServiceProvider::map()` only groups `routes/web.php`, so the api resource is **never registered** (constraint #23). `Route::has('behaviouralassessment.index')` is false.

**Permission divergences.** The tab-nav in `pages/reports.blade.php` gates the "Student Scores" tab on `reports.viewAny`, while `reportsPage()` gates on `reports-page.viewAny` (SEC-BA-003). `export()` gates on `reports.view` although `BaReportPolicy` declares an `export` ability bound to `reports.export` (VAL-BA-003 — dead policy method).

**Requirement-vs-implementation grid gap (RPT-GAP-01).** Screen-16 specifies a per-student grid with Roll No, Admission No, dynamic per-category average columns, Grading Teacher, Status, color-coded badges, and a "grades not yet approved" draft banner. `by-class.blade` instead renders a "Class Analysis Report" (Student Ranking by overall, Category-Wise Class Performance, At-Risk, Incident Breakdown) — none of the named columns/banner are present.

---

## 3. Manual Test Cases

### MT-01 — Reports Hub renders (TC-P05 · `_10`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as admin; visit `/behavioural-assessment/reports` | Page loads (no `/login` bounce) |
| 2 | Observe stat cards | "Students Rated" and hub cards visible |
| 3 | DB check | `SELECT COUNT(*) FROM ba_computed_scores` — value ≥ 0, no error |

### MT-02 — Student-Scores tab + filters (TC-P06 · `_11`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/behavioural-assessment/reports-page?tab=student-scores` | Tab pane `#student-scores-pane` active |
| 2 | Inspect filter bar | `period_id` and `class_section_id` selects present |
| 3 | Select a Period + Class, submit | Filter chips appear; table filtered; URL keeps `tab=student-scores` |

### MT-03 — By-class scores grid (TC-P07 · `_12`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/behavioural-assessment/reports/class/{id}` for a real class-section | "Class-Section:" selector + either "Student Ranking"/"Class Average Score" grid or "No score data available" |
| 2 | Note overall scores | **Observe BUG-BA-013:** overall scores show `0.00` and all students flagged at-risk even when `ba_computed_scores` rows exist |

### MT-04 — Per-student report reads numeric_score (TC-P08/P09 · `_13`,`_15`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/behavioural-assessment/reports/student/{id}` | Renders; no "Whoops" server error |
| 2 | Source check `BaReportController::student()` | Uses `avg('numeric_score')` (correct) |

### MT-05 — Invalid ids → 404 (TC-N01/N02 · `_30`,`_31`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/reports/student/987654321` | HTTP 404 |
| 2 | GET `/reports/class/987654321` | HTTP 404 |

### MT-06 — Filter degradation (TC-N03/N04 · `_32`,`_33`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/reports/class/{real}?period_id=987654321` | 200/302 — no 500 |
| 2 | GET `/reports-page?tab=student-scores&period_id=…&class_section_id=…` (unknown) | 200/302 — no 500; empty state or filtered grid |

### MT-07 — Authorization (TC-N05..N08 · `_50`–`_53`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logged out → visit `/reports` | Redirect to `/login` |
| 2 | Limited (non-super-admin, no perms) → GET `/reports` | HTTP 403 |
| 3 | Limited → GET `/reports/class/{id}` | HTTP 403 (gate before findOrFail) |
| 4 | Limited → GET `/reports/student/{id}` | HTTP 403 |

### MT-08 — Export 501 stub (TC-DEF01 · `_70`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Authorized admin → GET `/behavioural-assessment/reports/export` | **HTTP 501** "Export feature coming soon." (BUG-BA-011) |

### MT-09 — Data-correctness bug (TC-DEF04 · `_14`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | DB check | `SHOW COLUMNS FROM ba_computed_scores` — has `numeric_score`, **no `score`** |
| 2 | Seed a computed score with `numeric_score=4.50` | Row persists |
| 3 | Read model `->score` | `null` (no attribute) while `->numeric_score` = `4.50` |
| 4 | Source check | `byClass()` uses `avg('score')` (defective); `student()` uses `avg('numeric_score')` |

### MT-10 — Dead API + tenancy (TC-DEF02 · `_91`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `Route::has('behaviouralassessment.index')` | `false` (never registered) |
| 2 | Source `routes/api.php` | Has `auth:sanctum`, no `InitializeTenancyByDomain` |
| 3 | Source `RouteServiceProvider::map()` | Groups only `routes/web.php` |

### MT-11 — Requirement gaps (TC-DEF05/DEF06 · `_71`,`_72`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Source `by-class.blade.php` | No "Roll No" / "Admission No" / draft-approval banner |
| 2 | Source `BaReportController` | `export()` = `abort(501)`; no `fputcsv`/`StreamedResponse` |

### MT-12 — Permission divergences (TC-DEF07/DEF08 · `_55`,`_56`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Source `BaDashboardController::reportsPage()` | Gate `reports-page.viewAny` |
| 2 | Source `pages/reports.blade.php` tab-nav | Gate `reports.viewAny` (divergent — SEC-BA-003) |
| 3 | Source `export()` | Gates `reports.view` only (not `reports.export`) though Policy declares `export` (VAL-BA-003) |

### MT-13 — Empty states + escaping (TC-U01/U02/N09 · `_60`,`_61`,`_93`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | By-class with no scores in period | "No score data available" banner (or zero grid) |
| 2 | Tab with no reviewed assessments | "No reviewed assessments yet" |
| 3 | View rendered report source | No live `<script>alert(` — Blade escapes output |

### MT-14 — FK integrity + tenancy stack (TC-D01/P13/P14 · `_40`,`_92`,`_90`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `information_schema.REFERENTIAL_CONSTRAINTS` for `ba_computed_scores` | RESTRICT / NO ACTION to student/category/period |
| 2 | Source `RouteServiceProvider` | Web routes carry `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified` |
| 3 | Runtime | `tenancy()->initialized` true; `ba_computed_scores` resolves in tenant DB |
