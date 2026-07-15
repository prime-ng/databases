# Student Report — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | StudentReport (per-student consolidated behavioural dossier) |
| Requirement file | `BehaviouralAssessment_v2/20-Student-Report.md` |
| URL | `GET /behavioural-assessment/reports/student/{student}` (route `behavioural-assessment.reports.student`) |
| Controller | `BaReportController::student(int $student)` |
| View | `behaviouralassessment::reports.student` (`resources/views/reports/student.blade.php`) |
| Models | `BaComputedScore` (`ba_computed_scores`), `BaIncident` (`ba_incidents`), `BaStudentRemark` (`ba_student_remarks`), `BaAssessmentRating`, `BaAssessment`, `BaAssessmentPeriod`, `BaCategory` |
| Validation | None (read-only report; only route-model binding via `findOrFail`) |
| Permissions | `tenant.behavioural-assessment.reports.view` (screen); `...reports.viewAny` (Hub) |
| CRUD Type | Read-only (report) |
| Soft Delete | Backing tables use `SoftDeletes`; the report reads active rows |
| Pagination | None (single-student dossier) |
| Activity Log | None (documented absence — read-only controller) |
| DB scope | TENANT-side (tenant_db) |
| Prerequisites | BehaviouralAssessment enabled in `modules_statuses.json`; `APP_ENV=testing`; a seeded tenant with at least one `std_students` row |

---

## 2. Business Conditions (detailed)

**Overall Score & Class Rank (correct path).** The controller computes the overall KPI as
`$categoryScores->avg('numeric_score')` and the class rank via `AVG(numeric_score)` grouped by student —
both read the live `ba_computed_scores.numeric_score` column and are correct.

**Category-Wise Scores grid (BUG-BA-013 — split firing).** The blade renders each category row using
`$cs->score` (`student.blade.php` lines 149, 162, 197) — but `ba_computed_scores` has **no `score` column**
(the model has no such accessor). Every per-category Score, `%`, and Performance-Bar therefore renders
`0.00 / 0%`, and the collapsible category header badge (`$categoryScores[$catId]?->score`) is suppressed.
This is a *partial* firing: the overall KPI badge is correct, the per-category grid is broken.

**Grade Lockdown Rule (RPT-GAP-STU-01 — not implemented).** Screen-20 requires that Draft/Submitted grades
are hidden from the parent-facing report and replaced by
`"Grading for this period is in progress. Averages will be visible once finalized by HOD."`, with a staff
`"Show Drafts"` toggle. The controller selects `->latest()` assessment with **no status filter**, and the
blade renders scores unconditionally — none of the lockdown behaviour exists.

**Download PDF (RPT-GAP-STU-02 / BUG-BA-011 — not implemented).** Screen-20 places a "Download PDF" button
in the identity header. `student.blade` has no such button, and the only export route
(`reports.export`) is a permanent `abort(501, 'Export feature coming soon.')` stub.

**Incident Timeline.** `ba_incidents` rows in the period window (`whereBetween(incident_date,[start,end])`),
split into positive (`positive_reinforcement`) and negative (`negative_incident`) with severity badges.

**Teacher Remarks (Narrative).** `ba_student_remarks.remark_text` for the student + latest assessment.

---

## 3. Test Cases (step-by-step)

### TC-P07 — Report renders for an authorized admin (Method `_10`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as admin (has `reports.view`) | Session established |
| 2 | Visit `/behavioural-assessment/reports/student/{validId}` | HTTP 200, no redirect to `/login` |
| 3 | Inspect page source | Contains "Student Overview"; no "Whoops" server error |
| DB | `SELECT COUNT(*) FROM ba_computed_scores WHERE student_id={id}` | ≥ 0 (rows drive the grid) |

### TC-P08 — Overall & Class Rank use `numeric_score` (Method `_11`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaReportController::student()` body | Contains `avg('numeric_score')` and `AVG(numeric_score)` |
| 2 | Confirm absence of the broken aggregate | Does NOT contain `avg('score')` in the student() body |

### TC-P09 — KPI badges render (Method `_12`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit the student report | Page shows "Overall Score", "Positive Incidents", "Negative Incidents", and a "/ 5.00" scale |

### TC-N01 — Invalid student id → 404 (Method `_30`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticated GET `/reports/student/987654321` | HTTP 404 (`findOrFail`) |

### TC-N02 — Unknown period filter graceful (Method `_31`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/reports/student/{id}?period_id=987654321` | HTTP 200/302; `find()` → null; no 500 |

### TC-N03 — Guest redirect (Method `_50`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies, visit the student report URL | Redirected to `/login` |

### TC-N04 — Limited user 403 (Method `_51`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create non-super-admin user, strip roles/permissions | User has no `reports.view` |
| 2 | `loginAs()` and fetch the student report | HTTP 403 (gate blocks before `findOrFail`) |

### TC-D01/D02/D03 — FK on-delete rules (Methods `_40`–`_42`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `information_schema.REFERENTIAL_CONSTRAINTS` for `ba_computed_scores` | student/category/period → RESTRICT |
| 2 | …for `ba_incidents` | student/reporter → RESTRICT; category/criterion → SET NULL |
| 3 | …for `ba_student_remarks` | assessment → CASCADE; student → RESTRICT |

### BUG-BA-013 — Category grid reads non-existent `score` (Method `_70`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Schema::hasColumn('ba_computed_scores','score')` | FALSE |
| 2 | Seed a computed score with `numeric_score=4.50`, refresh, read `->score` | `numeric_score`="4.50", `->score` = NULL |
| 3 | Read `student.blade.php` | Contains `$cs->score` and `$categoryScores[$catId]?->score` |
| Impact | Every per-category Score/%/bar renders `0.00`; overall KPI stays correct |

### BUG-BA-011 — Export is a live 501 stub (Method `_71`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticated GET `/behavioural-assessment/reports/export` | HTTP 501 "Export feature coming soon." |
| 2 | Read `export()` body | Contains `abort(501` |

### RPT-GAP-STU-01 — Grade Lockdown not implemented (Method `_72`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `student()` body | Uses `->latest()`; NO `where('status','locked')` filter |
| 2 | Read `student.blade` | No "Grading for this period is in progress"; no "Show Drafts" toggle |

### RPT-GAP-STU-02 — Download PDF button absent (Method `_73`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `student.blade` | No "Download PDF" text; no `reports.export` action wiring |

### VAL-BA-003 — export gate weaker than Policy (Method `_53`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `export()` body | Authorizes `reports.view`, NOT `reports.export` |
| 2 | Read `BaReportPolicy` | Declares an `export` ability on `reports.export` (unused / dead) |

### DEAD-BA-001 — API dead + no tenancy (Method `_91`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Route::has('behaviouralassessment.index')` | FALSE (never registered) |
| 2 | Read `routes/api.php` | No `InitializeTenancyByDomain` middleware |
| 3 | Read `RouteServiceProvider` | `map()` never loads `routes/api.php` |

### TC-N05 — Output escaping (Method `_93`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Render the report and inspect source | No literal `<script>alert(` (Blade auto-escapes) |
