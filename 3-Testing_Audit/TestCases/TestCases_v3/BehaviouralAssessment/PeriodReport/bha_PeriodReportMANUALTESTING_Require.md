# bha_PeriodReport — Manual Testing Guide

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | PeriodReport ("Teacher Progress Report") |
| URL | `/behavioural-assessment/reports/period/{period}` |
| Route name | `behavioural-assessment.reports.period` |
| Controller | `BaReportController@period(int $period)` |
| Related routes | `reports.index` (hub), `reports.export` (501 stub) |
| Models (read) | `BaAssessmentPeriod`, `BaAssessment`, `BaAssessmentRating`, `BaStudentRemark` |
| Models NOT read | `BaComputedScore` (see scope note — BUG-BA-013 not applicable) |
| Validation | Route `int $period` → `findOrFail` (404); no FormRequest (read-only) |
| Migrations (tenant) | `..._130612_create_ba_assessment_periods_table.php`, `..._130617_create_ba_assessments_table.php` |
| CRUD type | Read-only report (no create/edit/delete) |
| Soft delete | Underlying tables use `SoftDeletes`; report itself mutates nothing |
| Pagination | None (single-period aggregation) |
| Activity log | NONE (documented absence for read-only reports) |
| Permission | `tenant.behavioural-assessment.reports.view` (gate before findOrFail) |
| Prerequisite | BehaviouralAssessment enabled in `modules_statuses.json`; `APP_ENV=testing` |

---

## 2. Business Conditions (detailed)

### Aggregation the screen performs (`period()`)
1. `findOrFail($period)` on `ba_assessment_periods` (with `academicSession`). Unknown id → 404.
2. **Workflow status counts** — `ba_assessments WHERE period_id = ? GROUP BY status` → `{draft, submitted, reviewed, locked}` counts; `totalAssessments = sum`.
3. **Teacher-wise progress** — group assessments by `teacher_id`:
   - `submitted` = count of status ∈ {submitted, reviewed, locked}
   - `status` = `ALL_SUBMITTED` (submitted == total) / `PARTIAL` (submitted > 0) / `PENDING` (0)
   - `last_activity` = max `updated_at`
4. **Rating-grid completion** — `ba_assessment_ratings` filled cells per assessment (`rating_level_id NOT NULL`).
5. **Remarks completion** — `ba_student_remarks` count per assessment; with-remarks vs without-remarks.
6. **Deadline** — `daysRemaining = now()->diffInDays(period.deadline)`; overdue if negative.

> **The screen reads NO computed scores.** BUG-BA-013 (`AVG(score)` on a non-existent column) is confined to
> `byClass()`/`categories()`. `period()` is unaffected — verified in automated test `_14`.

### State machines surfaced (read-only)
- **Assessment FSM:** `draft → submitted → reviewed → locked` (surfaced as the workflow breakdown + legend).
- **Period lifecycle:** `open / closed / locked` (surfaced as the period status badge).
- The report triggers **no** transitions.

### Known defects to observe
- **BUG-BA-011** — `reports/export` returns HTTP **501** ("Export feature coming soon.").
- **DEAD-BA-001** — `routes/api.php` apiResource has no tenancy middleware and is never registered.
- **VAL-BA-003** — `export()` gates on `reports.view`, not the Policy's `reports.export` ability.
- **RPT-GAP-PRD-01/02/03** — the specified multi-period comparison grid, delta formula, and export are unimplemented.
- **UI-BA-PRD-01** — the period-selector dropdown does not actually switch periods.

---

## 3. Manual Test Cases

### TC-M01 — Period report renders for a valid period
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as admin (`root@tenant.com`) | Dashboard loads |
| 2 | `SELECT id FROM ba_assessment_periods LIMIT 1` → note `P` | A period id exists |
| 3 | Visit `/behavioural-assessment/reports/period/P` | Page renders, breadcrumb "Teacher Progress Report" |
| 4 | Observe | Period overview cards (Period, Deadline, Total Assessments, Period Status) render |
| 5 | Observe "Assessment Workflow Status" | Four cards Draft/Submitted/Reviewed/Locked render with percentages |
| 6 | Observe "Teacher-Wise Progress" | Table of teachers OR "No assessments found for this period." |

### TC-M02 — Workflow counts reflect data
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SELECT status, COUNT(*) FROM ba_assessments WHERE period_id = P GROUP BY status` | Note counts |
| 2 | Compare with the four workflow cards on the report | Card counts match the SQL counts |
| 3 | `SELECT COUNT(DISTINCT teacher_id) FROM ba_assessments WHERE period_id = P` | Note teacher count |
| 4 | Count rows in the Teacher-Wise Progress table | Matches distinct teachers |

### TC-M03 — computed_scores is NOT used (contrast)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open `BaReportController@period()` source | No `AVG(score)`, no `numeric_score`, no `BaComputedScore` reference |
| 2 | `SHOW COLUMNS FROM ba_computed_scores LIKE 'score'` | Empty — the `score` column does not exist |
| 3 | Conclusion | BUG-BA-013 does not affect the Period Report |

### TC-M04 — Invalid period id → 404
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/behavioural-assessment/reports/period/987654321` | HTTP 404 (findOrFail) |
| 2 | Visit `/behavioural-assessment/reports/period/not-a-number` | Not a valid report (404/400/500) |

### TC-M05 — Guest & limited-user authorization
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log out; visit `/behavioural-assessment/reports/period/P` | Redirect to `/login` |
| 2 | Log in as a non-super-admin without `reports.view`; visit same URL | HTTP 403 (before findOrFail) |
| 3 | `SELECT` on `BaReportPolicy` | `viewAny/view/export` map to `tenant.behavioural-assessment.reports.{ability}` |

### TC-M06 — Period selector is non-functional (UI-BA-PRD-01)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On the report, open the "Assessment Period" dropdown | Options for all periods listed |
| 2 | Select a DIFFERENT period | Form auto-submits `?period=<id>` to the same URL |
| 3 | Observe the URL and the report | URL path segment `{period}` unchanged → SAME period still shown (filter does nothing) |

### TC-M07 — Export is a 501 stub (BUG-BA-011)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/behavioural-assessment/reports/export` as admin | HTTP **501** "Export feature coming soon." |
| 2 | Open `export()` source | `Gate::authorize('...reports.view'); abort(501, ...)` — no CSV/stream writer |

### TC-M08 — Requirement comparison grid missing (RPT-GAP-PRD-01/02)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Compare screen-18 spec grid (Roll No / Period-N averages / Score Delta / Trend) with the rendered report | None of these columns exist |
| 2 | Look for a "Compare Periods" multi-select filter | Absent — only a single-period dropdown |
| 3 | Open `period()` source | No delta / previous-period / trend logic |

### TC-M09 — FK integrity
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `information_schema.REFERENTIAL_CONSTRAINTS` for `ba_assessments` | `period_id`, `teacher_id`, `class_section_id` FKs are RESTRICT |
| 2 | Attempt to delete a referenced period at DB level | Blocked by RESTRICT |

### TC-M10 — Tenancy & dead API
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm tenant context; `SHOW TABLES LIKE 'ba_assessment_periods'` | Resolves within the tenant DB |
| 2 | Check `Route::has('behaviouralassessment.index')` | `false` — API resource never registered (DEAD-BA-001) |
| 3 | Open `routes/api.php` | `auth:sanctum` guard, NO `InitializeTenancyByDomain` |
