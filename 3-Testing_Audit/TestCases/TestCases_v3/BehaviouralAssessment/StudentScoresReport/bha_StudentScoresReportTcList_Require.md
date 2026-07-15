# Student Scores Report — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (BHA) · **Feature/Screen:** StudentScoresReport (screen 16 — `16-Student-Scores-Report.md`)
**Type:** Report (read-focused, LIGHT depth) · **DB scope:** TENANT-side (`tenant_db`, database-per-tenant)
**Primary table:** `ba_computed_scores` (live `ba_` prefix; DDL doc uses stale `bha_` — DOC-BA-001)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController` (`index`, `student`, `byClass`, `period`, `categories`, `incidents`, `export`)
**UI alias surface:** `BaDashboardController::reportsPage()` → `reports-page?tab=student-scores` → `pages/partials/reports/_student-scores.blade.php`
**Permission prefix:** `tenant.behavioural-assessment.reports.{viewAny|view|export}` (+ `reports-page.{viewAny|view}` gate the tab shell)
**Test file:** `bha_StudentScoresReport_TestCas.php` (single comprehensive Dusk suite — 33 methods) · **Activity log:** none (read-only)

> **Filename-prefix vs asserted-table rule (obey exactly):** the artifact FILENAME prefix is `bha_`; every test body ASSERTS the LIVE `ba_` tables (`ba_computed_scores`, `ba_assessments`). Asserting `bha_*` false-fails. Confirmed by audit DOC-BA-001.

---

## 1. Business Conditions

### BC-DB — schema (Source: `DDL-ba_computed_scores`, live migration `2026_06_16_130619`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_computed_scores` exists with columns id, student_id, category_id, period_id, numeric_score, grade, overall_score, overall_grade, computed_at, is_active, created_by, updated_by, timestamps, deleted_at | DDL-ba_computed_scores |
| BC-DB-02 | Category score column is **`numeric_score`** DECIMAL(5,2); overall is `overall_score` DECIMAL(5,2). There is **NO** bare `score` column | DDL-ba_computed_scores |
| BC-DB-03 | Unique key `uq_ba_score (student_id, category_id, period_id)` | DDL-ba_computed_scores |
| BC-DB-04 | `SoftDeletes` (`deleted_at`); model uses the trait | Model BaComputedScore |
| BC-DB-05 | FKs student_id→std_students, category_id→ba_categories, period_id→ba_assessment_periods, all **ON DELETE RESTRICT** | DDL-ba_computed_scores |
| BC-DB-06 | Runtime table is `ba_computed_scores`; `bha_computed_scores` must NOT exist | Audit-DOC-BA-001 |

### BC-BIZ — business rules / render (Source: `Screen-BR`, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Reports Hub (`reports.index`) renders for an authorized user | Controller::index / Screen-BR-1 |
| BC-BIZ-02 | Student-Scores tab (`reports-page?tab=student-scores`) renders period + class/section filters and a data grid | _student-scores.blade / Screen-BR-Filters |
| BC-BIZ-03 | Per-section student-scores grid (`reports.class`/byClass) renders per-student overall + category performance from `ba_computed_scores`, or an empty state | Controller::byClass / Screen-BR-Grid |
| BC-BIZ-04 | Per-student report (`reports.student`) reads `ba_computed_scores.numeric_score` and renders category scores | Controller::student / Screen-BR-Overall |
| BC-BIZ-05 | Student name in the grid links to the individual Student Report (`reports.student`) | by-class.blade / Screen-WF-6 |

### BC-SM — state / status semantics (Source: `Screen-Status`, DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-SM-01 | Assessment status enum = `draft, submitted, reviewed, locked`. The Student-Scores tab lists only `reviewed`/`locked` rows | DDL-ba_assessments / _student-scores.blade |
| BC-SM-02 | Requirement calls status `Draft/Submitted/Approved(Locked)`; "Approved" has no enum value (terminology gap) | Screen-Status vs DDL |

### BC-AUTH — permissions (Source: `Screen-PM`, Policy, Controller gates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` gates `tenant.behavioural-assessment.reports.viewAny` | Controller::index |
| BC-AUTH-02 | `byClass()`/`student()`/`export()` gate `tenant.behavioural-assessment.reports.view` | Controller |
| BC-AUTH-03 | Guest → redirect `/login` | RSP `auth` middleware |
| BC-AUTH-04 | `BaReportPolicy` maps viewAny/view/export → `reports.{viewAny|view|export}` | Policy BaReportPolicy |
| BC-AUTH-05 | Tab shell `reportsPage()` gates `reports-page.viewAny`, but the tab-nav visibility gates `reports.viewAny` (divergent keys) | BaDashboardController vs reports.blade — SEC-BA-003 |
| BC-AUTH-06 | `export()` gates `reports.view` though the Policy exposes an unused `export` ability on `reports.export` | Controller vs Policy — VAL-BA-003 |

### BC-INT — integration / cross-module (Source: DDL FKs, controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Grid depends on cross-module `std_students` (RESTRICT) and `ba_categories`/`ba_assessment_periods` | DDL FKs |
| BC-INT-02 | Student-Scores tab reads `ba_assessments` (with rating/remark counts), NOT `ba_computed_scores` | _student-scores.blade |
| BC-INT-03 | Module `routes/api.php` apiResource `behaviouralassessments` has no tenancy middleware AND is never registered (RSP maps only web.php) | api.php / RSP — DEAD-BA-001 |

### BC-EDG — edge / boundary (Source: Screen, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Unknown student/class-section id → 404 (findOrFail) | Controller |
| BC-EDG-02 | Unknown `period_id` filter → graceful degrade (find() → null), not 500 | Controller |
| BC-EDG-03 | `reports/export` is a live `abort(501)` stub for authorized users | Controller::export — BUG-BA-011 |

### BC-DEF — proven source defects (Source: Audit + this run)
| ID | Condition | Source |
|----|-----------|--------|
| BUG-BA-011 | Report export is a permanent `abort(501)` stub on a live route | Audit-BUG-BA-011 |
| DEAD-BA-001 | API resource controller behind sanctum with no tenancy; route never registered | Audit-DEAD-BA-001 |
| DOC-BA-001 | DDL doc prefix `bha_` diverges from live `ba_` | Audit-DOC-BA-001 |
| **BUG-BA-013** | **NEW** — `byClass()`/`categories()` + `by-class.blade` aggregate on a non-existent `score` column (live is `numeric_score`) → every overall score renders 0.00 and every student flagged at-risk; `student()` correctly uses `numeric_score` | This run (source + runtime) |
| RPT-GAP-01 | Screen-16 grid columns (Roll No, Admission No, per-student category columns, Grading Teacher, Status, draft banner) unimplemented in `by-class.blade` | Screen-16 vs by-class.blade |
| RPT-GAP-02 | Screen-16 CSV export unimplemented — only the 501 stub exists | Screen-16 vs Controller |
| SEC-BA-003 | Tab-nav vs `reportsPage()` gate on divergent permission keys | reports.blade vs BaDashboardController |
| VAL-BA-003 | `export()` gates `reports.view` while Policy exposes `reports.export` | Controller vs Policy |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..05 | DDL | computed_scores schema + model config correct | table/cols/unique/softdelete/relations pass | `_01` | Ready |
| TC-P02 | BC-DB-06 | Audit | live `ba_` prefix; `bha_` absent | ba exists, bha absent | `_02` | Ready |
| TC-P03 | BC-BIZ-01..04 | Controller | controller methods + report routes registered | 7 methods + 8 routes present | `_03` | Ready |
| TC-P04 | BC-BIZ-02/03 | Blade | report views + tab partial exist with grid markers | render markers present | `_04` | Ready |
| TC-P05 | BC-BIZ-01 | Screen-BR-1 | Reports Hub renders for admin | "Students Rated" seen, no login bounce | `_10` | Ready |
| TC-P06 | BC-BIZ-02 | Screen-Filters | Student-Scores tab renders period+class filters | pane + both selects present | `_11` | Ready |
| TC-P07 | BC-BIZ-03 | Screen-Grid | by-class scores grid renders or empty state | grid or "No score data available" | `_12` | Ready |
| TC-P08 | BC-BIZ-04 | Screen-Overall | student report renders, reads numeric_score | no server error | `_13` | Ready |
| TC-P09 | BC-BIZ-04 | Controller | student() uses numeric_score (contrast to bug) | `avg('numeric_score')` present | `_15` | Ready |
| TC-P10 | BC-SM-01 | Blade | tab reads reviewed/locked assessments | `assessmentScores` present | `_41` | Ready |
| TC-P11 | BC-AUTH-04 | Policy | policy maps to reports.{viewAny,view,export} | all 3 strings present | `_54` | Ready |
| TC-P12 | BC-BIZ-05 | Screen-WF-6 | hub links to student-scores tab | `tab=student-scores` in source | `_62` | Ready |
| TC-P13 | BC-AUTH-03/RSP | RSP | web report routes carry full tenancy+auth stack | all middleware present | `_92` | Ready |
| TC-P14 | BC-DB-06 | Audit | tenant context initialized; table resolves | tenancy initialized | `_90` | Ready |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-EDG-01 | Controller | unknown student id | HTTP 404 | `_30` | Ready |
| TC-N02 | BC-EDG-01 | Controller | unknown class-section id | HTTP 404 | `_31` | Ready |
| TC-N03 | BC-EDG-02 | Controller | unknown period_id filter (by-class) | 200/302, not 500 | `_32` | Ready |
| TC-N04 | BC-EDG-02 | Blade | filter params on tab (unknown ids) | 200/302, not 500 | `_33` | Ready |
| TC-N05 | BC-AUTH-03 | RSP | guest hits reports hub | redirect `/login` | `_50` | Ready |
| TC-N06 | BC-AUTH-01 | Controller | limited user → reports hub | HTTP 403 | `_51` | Ready |
| TC-N07 | BC-AUTH-02 | Controller | limited user → by-class report | HTTP 403 | `_52` | Ready |
| TC-N08 | BC-AUTH-02 | Controller | limited user → student report | HTTP 403 | `_53` | Ready |
| TC-N09 | BC-DEF (XSS) | Security | rendered report escapes output | no live `<script>alert(` | `_93` | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C | BC-DB-05/BC-INT-01 | DDL | FKs RESTRICT on delete | RESTRICT/NO ACTION | `_40` | Ready |
| TC-D02 | E | BC-INT-02 | Blade | tab reads ba_assessments not computed_scores | `assessmentScores` present | `_41` | Ready |
| TC-D03 | E | BC-INT-03 | api.php/RSP | API resource dead + no tenancy | route absent, no tenancy mw | `_91` | Ready |

### State / Status (TC-SM)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-SM01 | BC-SM-01 | DDL/Blade | only reviewed/locked appear in the tab | `whereIn(['reviewed','locked'])` semantics | `_41` | Ready |

### Defect-proving (TC-DEF)
| TC ID | Defect | Source | Description | Expected | Method | Status |
|-------|--------|--------|-------------|----------|--------|--------|
| TC-DEF01 | BUG-BA-011 | Audit | export authorized → 501 stub | HTTP 501 | `_70` | Ready |
| TC-DEF02 | DEAD-BA-001 | Audit/#23 | api resource unregistered + no tenancy | route absent, no `InitializeTenancyByDomain` | `_91` | Ready |
| TC-DEF03 | DOC-BA-001 | Audit | live ba_ vs stale bha_ | bha absent | `_02` | Ready |
| TC-DEF04 | **BUG-BA-013** | This run | by-class reads non-existent `score` column | `score` col absent, `->score` null, source `avg('score')` | `_14` | Ready |
| TC-DEF05 | RPT-GAP-01 | Screen-16 | grid columns unimplemented | Roll/Admission/banner absent in view | `_71` | Ready |
| TC-DEF06 | RPT-GAP-02 | Screen-16 | CSV export unimplemented | abort(501), no fputcsv/StreamedResponse | `_72` | Ready |
| TC-DEF07 | SEC-BA-003 | Source | tab-nav vs controller gate keys diverge | both distinct strings present | `_55` | Ready |
| TC-DEF08 | VAL-BA-003 | Source | export gate ≠ policy export ability | export gates reports.view only | `_56` | Ready |

### UI/UX (TC-U)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-U01 | BC-BIZ-03 | Screen | by-class empty state | empty banner or grid | `_60` | Ready |
| TC-U02 | BC-BIZ-02 | Screen | tab empty state message | "No reviewed assessments yet" | `_61` | Ready |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `_01_computed_scores_schema_and_model_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` | TC-P02/TC-DEF03 | Schema | 01–09 |
| 3 | `_03_report_controller_methods_and_routes_are_registered` | TC-P03 | Schema/Route | 01–09 |
| 4 | `_04_report_views_and_tab_partial_exist` | TC-P04 | Schema/View | 01–09 |
| 5 | `_10_reports_hub_renders_for_authorized_admin` | TC-P05 | Render | 10–19 |
| 6 | `_11_student_scores_tab_renders_with_filters` | TC-P06 | Render | 10–19 |
| 7 | `_12_by_class_scores_grid_renders_or_shows_empty_state` | TC-P07 | Render | 10–19 |
| 8 | `_13_student_report_renders_and_reads_computed_scores` | TC-P08 | Render | 10–19 |
| 9 | `_14_by_class_report_reads_nonexistent_score_column_bug_ba_013` | TC-DEF04 | Data | 10–19 |
| 10 | `_15_student_report_correctly_reads_numeric_score` | TC-P09 | Data | 10–19 |
| 11 | `_30_invalid_student_id_returns_404` | TC-N01 | Negative | 30–39 |
| 12 | `_31_invalid_class_section_id_returns_404` | TC-N02 | Negative | 30–39 |
| 13 | `_32_unknown_period_filter_does_not_error` | TC-N03 | Negative | 30–39 |
| 14 | `_33_student_scores_tab_accepts_filter_params` | TC-N04 | Negative | 30–39 |
| 15 | `_40_computed_scores_fks_restrict_on_delete` | TC-D01 | Dependency | 40–49 |
| 16 | `_41_student_scores_tab_reads_assessments_not_computed_scores` | TC-D02/TC-SM01/TC-P10 | Dependency | 40–49 |
| 17 | `_50_guest_is_redirected_to_login` | TC-N05 | Auth | 50–59 |
| 18 | `_51_limited_user_gets_403_on_reports_hub` | TC-N06 | Auth | 50–59 |
| 19 | `_52_limited_user_gets_403_on_by_class_report` | TC-N07 | Auth | 50–59 |
| 20 | `_53_limited_user_gets_403_on_student_report` | TC-N08 | Auth | 50–59 |
| 21 | `_54_policy_maps_to_permission_strings` | TC-P11 | Auth | 50–59 |
| 22 | `_55_reports_page_gate_key_diverges_from_tab_nav_sec_ba_003` | TC-DEF07 | Auth | 50–59 |
| 23 | `_56_export_gate_diverges_from_policy_val_ba_003` | TC-DEF08 | Auth | 50–59 |
| 24 | `_60_by_class_empty_state_when_no_scores` | TC-U01 | UI/UX | 60–69 |
| 25 | `_61_student_scores_tab_empty_state_message` | TC-U02 | UI/UX | 60–69 |
| 26 | `_62_reports_hub_links_to_student_scores_tab` | TC-P12 | UI/UX | 60–69 |
| 27 | `_70_export_is_live_abort_501_stub_bug_ba_011` | TC-DEF01 | Edge | 70–79 |
| 28 | `_71_requirement_grid_columns_are_not_implemented_rpt_gap_01` | TC-DEF05 | Edge | 70–79 |
| 29 | `_72_csv_export_unimplemented_only_dead_501_route_rpt_gap_02` | TC-DEF06 | Edge | 70–79 |
| 30 | `_90_tenant_context_is_initialized` | TC-P14 | Tenancy | 90–99 |
| 31 | `_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001` | TC-DEF02/TC-D03 | Tenancy/API | 90–99 |
| 32 | `_92_web_report_routes_carry_full_tenancy_stack` | TC-P13 | Tenancy | 90–99 |
| 33 | `_93_rendered_report_escapes_output` | TC-N09 | Security | 90–99 |

**Totals:** 33 methods · 14 Positive · 9 Negative · 3 Dependency · 1 State · 8 Defect-proving · 2 UI/UX (methods reused across categories).

---

## 4. Known Source Defects (audit-equivalent)

| ID | Severity | Summary | Proving method |
|----|----------|---------|----------------|
| BUG-BA-011 | P2 | `reports/export` live `abort(501)` stub | `_70` |
| DEAD-BA-001 | P2 | API resource dead + no tenancy; route never registered | `_91` |
| DOC-BA-001 | Doc | DDL prefix `bha_` vs live `ba_` | `_02` |
| **BUG-BA-013** | **P2 (data-correctness)** | by-class/categories aggregate a non-existent `score` column → scores render 0.00, all students at-risk | `_14` (`_15` contrast) |
| RPT-GAP-01 | Gap | screen-16 grid columns/banner unimplemented | `_71` |
| RPT-GAP-02 | Gap | screen-16 CSV export unimplemented | `_72` |
| SEC-BA-003 | P3 | tab-nav vs controller gate key divergence | `_55` |
| VAL-BA-003 | P3 | export gate ≠ policy `export` ability | `_56` |
