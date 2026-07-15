# Reports Hub — Manual Testing Guide (`bha_ReportsHub`)

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | ReportsHub (Reports landing hub) |
| URL | `/behavioural-assessment/reports` |
| Controller | `BaReportController@index` (+ student/byClass/period/categories/incidents/export) |
| View | `behaviouralassessment::reports.index` (breadcrumb "Reports") |
| Models (aggregated) | BaAssessment, BaAssessmentRating, BaIncident, BaAssessmentPeriod, BaComputedScore |
| Live tables | `ba_assessments`, `ba_assessment_ratings`, `ba_incidents`, `ba_assessment_periods`, `ba_computed_scores` |
| CRUD type | **None** — read-only navigation/dashboard hub |
| Soft delete | N/A (no mutation) |
| Pagination | N/A on hub (sub-report `incidents` paginates 25) |
| Activity log | **None** — read-only screen performs no mutation |
| Index gate | `tenant.behavioural-assessment.reports.viewAny` |
| Sub-report gate | `tenant.behavioural-assessment.reports.view` |
| Export gate | `tenant.behavioural-assessment.reports.export` (unreachable useful path — 501 stub) |

**Environment prerequisites:** BehaviouralAssessment must be **enabled** in `prime_testing/modules_statuses.json` (else 404 on all routes); `APP_ENV=testing`; tenant domain reachable at `DUSK_TENANT_URL`; admin `root@tenant.com` / `password`.

---

## 2. Business Conditions (detailed)

**Hub composition (index.blade.php).** The hub is a stat-card dashboard, not the requirement's split filter panel. It shows four count cards (Total Assessments with Submitted/Locked sub-line, Students Rated, Total Incidents, Open Periods), an "Available Reports" grid of navigation cards (Teacher Assessment Progress, Incident Log & Interventions, Category & Criteria Performance, Class-Section Analysis, Student Behaviour Summary, Data Tables & Audit Trail), and a sidebar (Assessment Workflow Status bars, Incident Trend last-6-months table, Recent Assessment Periods list).

**Authorization flow.** `index()` calls `Gate::authorize('tenant.behavioural-assessment.reports.viewAny')`. Each sub-report (`student`, `byClass`, `period`, `categories`, `incidents`, `export`) calls `Gate::authorize('tenant.behavioural-assessment.reports.view')`. String abilities resolve via Spatie permission gates; `Gate::before` grants Super Admin everything (so negative auth tests MUST use a stripped non-super-admin user).

**BUG-BA-011.** `export()` unconditionally `abort(501, 'Export feature coming soon.')` after the view gate. The requirement makes CSV/Excel export the hub's core purpose — it does not exist.

**DEAD-BA-001.** `routes/api.php` declares `Route::middleware(['auth:sanctum'])->prefix('v1')->apiResource('behaviouralassessments', ...)` with **no** tenancy middleware; `RouteServiceProvider::map()` only maps `routes/web.php`, so the api resource is never registered.

**HUB-GAP-01/02/03.** No filter panel (Academic Session / Assessment Period / Class / Section / Format radio), no "Generate Preview" / "Export Report" buttons, no >1000-row async-queue banner, no "Data last synced" freshness label — all specified by the requirement, none present.

---

## 3. Manual Test Cases

### MT-01 — Hub renders (TC-P03/04/05/06 · `_10`–`_13`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as admin; visit `/behavioural-assessment/reports` | Page loads (HTTP 200), URL path `/behavioural-assessment/reports` |
| 2 | Inspect breadcrumb + heading | See "Reports" breadcrumb and "Available Reports" section |
| 3 | Inspect summary cards | See "Total Assessments", "Students Rated", "Total Incidents", "Open Periods" |
| 4 | Inspect sidebar | See "Assessment Workflow Status", "Incident Trend", "Recent Assessment Periods" |
| 5 | Inspect report cards | See "Incident Log & Interventions", "Category & Criteria Performance" |
| DB | `SELECT COUNT(*) FROM ba_assessments;` and `ba_incidents` | Card counts match table counts |

### MT-02 — Report links present + targets authorized (TC-P07–P11 · `_40`–`_44`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the hub, view page source | Contains `/behavioural-assessment/reports/incidents`, `/reports/categories`, `/reports-page`, `tab=student-scores` |
| 2 | Click "Incident Log & Interventions" | Incident report renders, breadcrumb "Incident Report" |
| 3 | Click "Category & Criteria Performance" | Category report renders, breadcrumb "Category Performance" |
| 4 | Select a period in "Teacher Assessment Progress" (if periods exist) | Period report renders, breadcrumb "Teacher Progress Report" |
| 5 | Click "Data Tables & Audit Trail" | Legacy `reports-page` renders (200) |
| Route | `php artisan route:list --name=reports` | `reports.student`, `reports.class`, `reports.period`, `reports.categories`, `reports.incidents`, `reports.export`, `reports.index` all listed |

### MT-03 — Permission gating (TC-N01–N05 · `_50`–`_54`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out; visit `/behavioural-assessment/reports` | Redirected to `/login` |
| 2 | Log in as a user WITHOUT `reports.viewAny`; GET the hub | 403 Forbidden |
| 3 | Same user GET `/reports/incidents` | 403 Forbidden |
| 4 | Same user GET `/reports/export` | 403 (gated before the 501 stub) |
| 5 | Inspect `BaReportPolicy` | viewAny/view/export methods reference the three `reports.*` permission strings |

### MT-04 — Edge & defects (TC-N06–N09 · `_45`,`_46`,`_70`,`_71`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | As admin GET `/reports/student/987654321` (and `/class/…`, `/period/…`) | 404 Not Found (findOrFail) |
| 2 | As admin GET `/reports/export` | **501** "Export feature coming soon." (BUG-BA-011) |
| 3 | `php artisan route:list --name=behaviouralassessment` | api resource NOT listed (DEAD-BA-001) |
| 4 | Inspect `routes/api.php` | `auth:sanctum` present, no `InitializeTenancyByDomain` (DEAD-BA-001) |

### MT-05 — UI / empty-state / security (TC-P12/P13, TC-N12 · `_60`,`_61`,`_92`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On hub, inspect Incident Trend | Header renders; when no incidents in last 6 months → "No incident data for this period." else a Month/Total/+/- table |
| 2 | Visit incidents & categories reports | Breadcrumbs "Incident Report" / "Category Performance" render |
| 3 | GET `/reports/incidents?incident_type=<script>alert(1)</script>` | Page renders with the script tag escaped (no alert) |

### MT-06 — Requirement gaps (TC-N10/N11 · `_80`,`_81`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the hub, search for "Generate Preview" / "Export Report" / "Excel (.xlsx)" | NONE present (HUB-GAP-01) |
| 2 | Search for "Data last synced" | Not present (HUB-GAP-02) |

### MT-07 — Tenancy (TC-P14/TC-D01 · `_90`,`_91`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenant context initialized | `tenancy()->initialized` true; `ba_*` tables resolve in tenant DB |
| 2 | Cross-tenant direct-id isolation | With a second tenant, its data is invisible; otherwise skipped |
