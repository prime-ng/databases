# Incident Report — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | IncidentReport (screen `24-Incident-Report.md`) |
| URL | `/behavioural-assessment/reports/incidents` |
| Route name | `behavioural-assessment.reports.incidents` (GET) |
| Controller | `BaReportController::incidents()` |
| View | `behaviouralassessment::reports.incidents` |
| Export route | `behavioural-assessment.reports.export` → `BaReportController::export()` (abort 501) |
| Models | `BaIncident` (ba_incidents), `BaIntervention`, `BaCategory` |
| Backing tables | `ba_incidents`, `ba_incident_intervention_jnt`, `ba_interventions`, `ba_incident_witnesses_jnt`, `ba_categories` |
| Validation | None (GET query filters; no FormRequest) |
| CRUD type | Read-only report (no create/edit/delete) |
| Soft delete | Model uses SoftDeletes; report reads non-trashed rows |
| Pagination | 25 rows/page (Incident Log) — NOT the platform default 10 |
| Activity log | NONE (read-only) |
| Permission | `tenant.behavioural-assessment.reports.view` |
| DB scope | Tenant-side (`tenant_db`) |
| Prerequisite | BehaviouralAssessment enabled in `modules_statuses.json`; `APP_ENV=testing` |

**Real filters (from controller):** From Date (def. start of month), To Date (def. today), Incident Type (positive_reinforcement / negative_incident), Severity (minor/moderate/major/critical), Category.

**Screen zones:** Filters bar → Executive Summary KPI cards (Total / Positive Reinforcements / Negative Incidents / Follow-ups Pending) → Breakdown by Type & Severity → Location Analysis → Incidents by Category → Intervention Usage → Follow-up Tracker → 6-Month Trend → Incident Log (paginated).

---

## 2. Business Conditions (detailed)

**Data-correctness contract**
- `totalCount` = count of `ba_incidents` matching the active filters.
- `positiveCount` = filtered count where `incident_type='positive_reinforcement'`.
- **`negativeCount` = totalCount − positiveCount** (derived — never a separate query; keeps totals internally consistent).
- `typeSeverityBreakdown` / `categoryBreakdown` / `locationBreakdown` = grouped aggregates over the filtered set.
- `interventionUsage` = `DB::table('ba_incident_intervention_jnt')` JOIN `ba_interventions` JOIN `ba_incidents` (date-windowed), grouped by intervention name + type.
- `incidentLog` = `paginate(25)` with `student`, `reportedBy`, `category`, `interventions` eager-loaded (NOT witnesses).

**Known defects / gaps proven by this suite**
- **BUG-BA-011** — Export route is a permanent `abort(501,'Export feature coming soon.')`. The requirement's CSV/Excel/PDF export has no working backing.
- **BUG-BA-013** — *Not applicable here.* The bug (blade reading the non-existent `bha_computed_scores.score`) affects the Student/Class reports; `incidents()` never queries computed scores, so it does not fire on this screen.
- **DEAD-BA-001** — `routes/api.php` `behaviouralassessments` apiResource has no tenancy middleware and is never registered (`RouteServiceProvider::map()` maps only `web.php`).
- **DOC-BA-001** — DDL doc uses `bha_` prefix; live tables are `ba_`.
- **VAL-BA-003** — `export()` authorizes `reports.view` although the policy exposes an `export` ability tied to `reports.export`.
- **RPT-GAP-INC-01** — Screen-24 Class & Section + Student filters are unimplemented.
- **RPT-GAP-INC-02** — Screen-24 charts (weekly line, success-rate donut, top-3 bar) are HTML tables; trend is monthly (6-month), not weekly; no chart canvas.
- **RPT-GAP-INC-03** — Screen-24 export privacy (roll numbers + STUDENT-SHA anonymisation) is unimplemented.
- **RPT-GAP-INC-04** — Screen-24 grid "Witness Count" column is absent (witnesses not eager-loaded).
- **DOC-BA-006** — Screen-24 severity vocabulary (Info/Low/Medium/High) ≠ live ENUM (minor/moderate/major/critical).

---

## 3. Test Cases (step-by-step)

### MT-01 — Report renders for authorized admin
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as tenant admin (`root@tenant.com`) | Dashboard loads |
| 2 | Visit `/behavioural-assessment/reports/incidents` | Page renders; no "Whoops" |
| 3 | Inspect page | Heading "Incident Report", Filters bar, and "Incident Log" grid present |
| DB | `SELECT COUNT(*) FROM ba_incidents` | Value matches the "Total Incidents" KPI within the default window |

### MT-02 — Executive KPI cards
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the report, read the 4 summary cards | Total Incidents / Positive Reinforcements / Negative Incidents / Follow-ups Pending all render |
| 2 | Verify invariant | Positive + Negative = Total (negativeCount is the derived remainder) |

### MT-03 — Seeded data appears in log
| Step | Action | Expected |
|------|--------|----------|
| 1 | Insert 1 positive + 1 negative `ba_incidents` dated today | Rows created |
| 2 | Reload report (default window) | Record count grows by ≥2; empty state hidden |
| 3 | Cleanup | Force-delete the seeded rows |

### MT-04 — Filters
| Step | Action | Expected |
|------|--------|----------|
| 1 | Set Severity = Major, Apply | Page reloads, no 500; grid reflects filter |
| 2 | Set Incident Type = Negative, Apply | Page reloads, no 500 |
| 3 | Set Category = <unknown id> via URL | Empty result set, no 500 |
| 4 | Set From/To to a far-future day | "No incidents found for the selected filters." shown |
| 5 | Click Reset | Filters cleared; URL = `reports/incidents` |

### MT-05 — Pagination
| Step | Action | Expected |
|------|--------|----------|
| 1 | With >25 incidents, scroll the Incident Log | 25 rows per page; pager present |
| 2 | Apply a filter, go to page 2 | Filter preserved across pages (query string retained) |

### MT-06 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out, visit the report URL | Redirect to `/login` |
| 2 | Log in as a non-super-admin without `reports.view` | 403 Forbidden |
| 3 | Restore admin | Report renders |

### MT-07 — Export (BUG-BA-011)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/behavioural-assessment/reports/export` | HTTP 501 "Export feature coming soon." |
| 2 | Read `BaReportController::export()` | `abort(501, ...)` stub; gates `reports.view` (VAL-BA-003) |

### MT-08 — Requirement gaps (documented)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect the filter bar | No Class/Section or Student filter (RPT-GAP-INC-01) |
| 2 | Inspect analytics | Tables, not charts; "6-Month Trend" monthly, no `<canvas>` (RPT-GAP-INC-02) |
| 3 | Inspect Incident Log columns | No "Witness Count" column (RPT-GAP-INC-04) |
| 4 | Inspect Severity dropdown | Options minor/moderate/major/critical — not Info/Low/Medium/High (DOC-BA-006) |

### MT-09 — Tenancy / API deadness
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenant context | `ba_incidents` resolves within the tenant DB |
| 2 | Check `Route::has('behaviouralassessment.index')` | false (DEAD-BA-001 — api resource never registered) |
| 3 | Inspect `routes/api.php` | No tenancy middleware present |

### MT-10 — Output escaping (security smoke)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Render the report | No raw `<script>alert(` in the page source (Blade escapes student/category/intervention text) |
