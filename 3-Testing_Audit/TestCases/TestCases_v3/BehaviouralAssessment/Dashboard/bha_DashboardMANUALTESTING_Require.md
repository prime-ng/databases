# Behavioural Assessment — Dashboard — Manual Test Specification

## 1. Feature Information

| Attribute | Value |
|-----------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | Dashboard (`01-Dashboard.md`) |
| URL | `GET /behavioural-assessment` (route `behavioural-assessment.dashboard`) |
| Controller | `BaDashboardController::index()` |
| Blade | `resources/views/pages/dashboard.blade.php` |
| Models read | `BaAssessment`, `BaAssessmentRating`, `BaIncident`, `BaAssessmentPeriod`, `BaComputedScore`, `BaCategory`, `BaRatingLevel` + cross-module `std_students` |
| Validation | None (read-only screen) |
| Migrations | `create_ba_*` (tenant migrations); live prefix `ba_` (DDL doc stale `bha_`, DOC-BA-001) |
| CRUD Type | READ-ONLY dashboard (no create/edit/delete) |
| Soft Delete | N/A on this screen |
| Pagination | None (KPI cards, charts, top-5 lists) |
| Activity Log | None (no mutations) |
| Permission | `tenant.behavioural-assessment.dashboard.viewAny` (enforced), `...view` (declared, unused) |
| Prerequisite | BehaviouralAssessment enabled in `modules_statuses.json`; `APP_ENV=testing`; tenant seeded |

**Widgets rendered:** 4 KPI cards (Total Assessments · Students Assessed · Total Incidents · Open Periods) →
Incident Trend area chart (6 months, positive/negative) → Category Average Scores bar chart (latest locked period) →
Rating Level Distribution donut → Recent Incidents table (last 5) → Students Needing Attention table (bottom 5,
locked period, conditional) → Quick Links row.

---

## 2. Business Conditions (detailed)

- **KPI counts (BC-BIZ-01..04):** `Total Assessments = COUNT(ba_assessments)`; `Students Assessed = COUNT(DISTINCT student_id)` in `ba_assessment_ratings`; `Total Incidents = COUNT(ba_incidents)`; `Open Periods = COUNT(ba_assessment_periods WHERE status='open')`. Rendered via `number_format()`.
- **Latest locked period (BC-BIZ-06 / BC-SM-01):** `SELECT * FROM ba_assessment_periods WHERE status='locked' ORDER BY end_date DESC LIMIT 1`. Drives both the Category Average Scores bar chart and the Students Needing Attention list. When absent, both collections are empty and their cards/charts show empty states.
- **Recent Incidents (BC-BIZ-08):** last 5 rows by `incident_date DESC`; each row shows student name, positive/negative badge, severity badge, category. Empty state text: **"No incidents recorded yet."**
- **Students Needing Attention (BC-BIZ-09 / BC-SM-03):** bottom 5 students by `AVG(numeric_score)` within the latest locked period; the whole card is wrapped in `@if($bottomStudents->isNotEmpty())`.
- **Quick Links (BC-BIZ-10):** Masters `/behavioural-assessment/masters`, Setup `/behavioural-assessment/setup`, Assessments `/behavioural-assessment/assessments-page`, Incidents `/behavioural-assessment/incidents-page`, Reports `/behavioural-assessment/reports-page`.
- **Authorization (BC-AUTH):** `index()` first line is `Gate::authorize('tenant.behavioural-assessment.dashboard.viewAny')`; guests redirect to `/login`; non-super-admin without the permission → 403. (Note constraint #31 — the default root admin is Super Admin and bypasses gates via `Gate::before`; use a stripped limited user for the 403 check.)

### Requirement-vs-implementation divergences (document, do not "fix")
- **DASH-GAP-01:** requirement KPI set = *Active Assessment Period / Assessments Completed % / Incidents This Week / Active Interventions*. Implementation renders a different set (see above). "Assessments Completed" and "Active Interventions" cards do not exist.
- **DASH-GAP-02:** requirement implies interactive drilldowns/filters; implementation ignores all query params server-side (charts are static reads).
- **DASH-GAP-03:** requirement's role-based data visibility (teacher sees only their sections) is not implemented — all viewers get school-wide aggregates.
- **DASH-GAP-04:** `severity` ENUM includes `critical`, but the Recent-Incidents blade only styles major/moderate/minor; a `critical` incident renders the em-dash placeholder for severity.

---

## 3. Manual Test Cases

### MT-01 — Dashboard renders (TC-P01)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as admin (`root@tenant.com`) | Authenticated |
| 2 | Navigate to `/behavioural-assessment` | Dashboard loads (< 2s) |
| 3 | Inspect header | Breadcrumb "Behavioural Assessment Dashboard" |
| 4 | Inspect KPI row | Four cards: Total Assessments, Students Assessed, Total Incidents, Open Periods |

### MT-02 — KPI counts match DB (TC-P02..P05)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | DB check: `SELECT COUNT(*) FROM ba_assessments WHERE deleted_at IS NULL` | value N1 |
| 2 | DB check: `SELECT COUNT(*) FROM ba_incidents WHERE deleted_at IS NULL` | value N2 |
| 3 | DB check: `SELECT COUNT(*) FROM ba_assessment_periods WHERE status='open' AND deleted_at IS NULL` | value N3 |
| 4 | DB check: `SELECT COUNT(DISTINCT student_id) FROM ba_assessment_ratings WHERE deleted_at IS NULL` | value N4 |
| 5 | Reload dashboard | Total Assessments = `number_format(N1)`; Total Incidents = `number_format(N2)`; Open Periods = `number_format(N3)`; Students Assessed = `number_format(N4)` |

### MT-03 — Recent Incidents widget (TC-P06/P07)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Insert an incident with a far-future `incident_date` for a known student | Row persisted (`ba_incidents`) |
| 2 | Reload dashboard | The student appears at the top of Recent Incidents (ordered `incident_date` desc, max 5 rows) |
| 3 | Delete the seeded incident | Cleanup |

### MT-04 — Charts present (TC-P08..P10)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Reload dashboard | Cards "Incident Trend (Last 6 Months)", "Category Average Scores", "Rating Level Distribution" visible |
| 2 | View source | `#chart-incident-trend`, `#chart-category-scores`, `#chart-rating-distribution` containers present |
| 3 | With no data | Chart placeholders render ("No incident data yet" / "No scores computed yet" / "No ratings yet") |

### MT-05 — Latest locked period scoping (TC-P11/P12, BC-SM)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Insert a period with `status='locked'` and a recent `end_date` | Persisted |
| 2 | Reload dashboard | The locked period name appears under the Category Average Scores card |
| 3 | Insert computed scores for that period across students | Students Needing Attention card appears with bottom-5 (ascending avg) |
| 4 | Remove the locked period | Category/attention cards revert to empty states |

### MT-06 — Quick Links (TC-P15/P16)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scroll to Quick Links | 5 buttons: Masters/Setup/Assessments/Incidents/Reports |
| 2 | Hover each | Hrefs = `/behavioural-assessment/{masters,setup,assessments-page,incidents-page,reports-page}` |
| 3 | Recent Incidents header "View All" | Links to `/behavioural-assessment/incidents-page?tab=log` |

### MT-07 — Guest redirect (TC-N01)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies / log out | No session |
| 2 | Visit `/behavioural-assessment` | Redirected to `/login` |

### MT-08 — Permission gate (TC-N02/P14)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a user, strip `is_super_admin`/`super_admin_flag`, sync no roles/permissions | Limited user |
| 2 | Log in as limited user, request `/behavioural-assessment` (Accept: json) | HTTP 403 |
| 3 | Log in as permitted admin | HTTP 200, dashboard renders |

### MT-09 — Input robustness (TC-N03, DASH-GAP-02)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/behavioural-assessment?search=<script>&period_id=abc&status=nonsense` | Renders normally |
| 2 | View source | No `<script>alert...` reflected; junk params ignored |

### MT-10 — Empty / edge states (TC-N04/N05/N06)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On a tenant with no incidents | Recent Incidents shows "No incidents recorded yet." |
| 2 | On a tenant with no locked period + no computed scores | "Students Needing Attention" card is absent |
| 3 | Reload dashboard regardless | KPI row + Quick Links always render (no crash) |

### MT-11 — Stored XSS (TC-SEC-01)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Insert an incident with description `Dashboard XSS <img src=x onerror=alert(1)>` (future date) | Persisted |
| 2 | Reload dashboard | Payload does NOT appear raw in DOM (Blade-escaped); no alert fires |
| 3 | Delete the seeded incident | Cleanup |

### MT-12 — Divergence documentation (TC-G01/G02/G03)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `index()` source | No `hasRole(` scope branch; KPI is school-wide count (DASH-GAP-03) |
| 2 | Inspect blade severity branches | Only major/moderate/minor mapped; `critical` unmapped (DASH-GAP-04) |
| 3 | Inspect blade KPI labels | "Assessments Completed" / "Active Interventions" absent (DASH-GAP-01) |
