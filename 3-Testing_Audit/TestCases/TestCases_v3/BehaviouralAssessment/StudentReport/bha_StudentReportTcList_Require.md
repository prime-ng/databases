# Student Report — Test Case List & Business Conditions

**Module:** BehaviouralAssessment · **Feature/Screen:** StudentReport (`20-Student-Report.md`)
**Controller:** `BaReportController::student(int $student)` → view `behaviouralassessment::reports.student`
**Route:** `behavioural-assessment.reports.student` → `GET /behavioural-assessment/reports/student/{student}`
**Depth:** LIGHT (report / read-focused — no CRUD matrix)
**File prefix:** `bha_` (filename) · **Live tables asserted:** `ba_computed_scores`, `ba_incidents`, `ba_student_remarks`, `ba_assessment_ratings`, `ba_assessments`, `ba_assessment_periods`, `ba_categories`
**DB scope:** TENANT-side (tenant_db) · **Test style:** browser Dusk (`extends DuskTestCase`)
**Test file:** `bha_StudentReport_TestCas.php` (single comprehensive suite, 33 methods)

---

## 1. Business Conditions

### BC-DB (schema / DDL truth)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_computed_scores` exists with `numeric_score DECIMAL(5,2) NOT NULL`, `overall_score`, `grade`, `computed_at`, `is_active`, soft-delete; unique `(student_id, category_id, period_id)`. | DDL-ba_computed_scores |
| BC-DB-02 | `ba_computed_scores` has **NO** bare `score` column — the report reads `numeric_score`. | DDL-ba_computed_scores / DOC-BA-001 |
| BC-DB-03 | `ba_incidents` exists with `incident_type ENUM('positive_reinforcement','negative_incident')`, `severity ENUM('minor','moderate','major','critical')`, `incident_date`, `location`, soft-delete. | DDL-ba_incidents |
| BC-DB-04 | `ba_student_remarks` exists with `remark_text TEXT NOT NULL`, unique `(assessment_id, student_id)`, soft-delete. | DDL-ba_student_remarks |
| BC-DB-05 | Live runtime prefix is `ba_`; the DDL-doc `bha_*` tables do NOT exist at runtime. | DOC-BA-001 |

### BC-BIZ (business logic / data correctness)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `student()` computes `$overallScore = $categoryScores->avg('numeric_score')` — overall KPI badge uses the REAL column. | Controller student():85 |
| BC-BIZ-02 | Class Rank is computed via `AVG(numeric_score)` grouped by student, ordered desc — the REAL column. | Controller student():121-129 |
| BC-BIZ-03 | The report renders four zones: Student Overview, Overall-Score KPI badges, Category-Wise Scores grid, Incident Summary timeline. | Screen-20 §Key Widgets |
| BC-BIZ-04 | Incident Summary reads `ba_incidents` in the period window (`whereBetween(incident_date,[period.start,period.end])`) and splits positive/negative by `incident_type`. | Controller student():108-118 |
| BC-BIZ-05 | Narrative "Teacher Remarks" section renders `remark_text` from `ba_student_remarks` for the student + latest assessment. | Controller student():102-105 / Screen-20 §Narrative |
| BC-BIZ-06 | Period filter: `request('period_id')` → `find()`; when absent, the latest period (by `created_at`) is used. | Controller student():71-74 |

### BC-AUTH (authorization)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `student()` gates on `tenant.behavioural-assessment.reports.view`. | Controller student():68 |
| BC-AUTH-02 | Reports Hub / index gates on `tenant.behavioural-assessment.reports.viewAny`. | Controller index():29 |
| BC-AUTH-03 | Guest (unauthenticated) is redirected to `/login`. | Screen-PM / middleware |
| BC-AUTH-04 | `BaReportPolicy` maps `viewAny`/`view`/`export` to `tenant.behavioural-assessment.reports.{ability}`. | BaReportPolicy |

### BC-REF (FK integrity / on-delete)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_computed_scores` → `std_students` / `ba_categories` / `ba_assessment_periods` all **RESTRICT** on delete. | DDL-ba_computed_scores |
| BC-REF-02 | `ba_incidents` → `std_students` **RESTRICT**, `sch_employees` **RESTRICT**, `ba_categories` **SET NULL**, `ba_criteria` **SET NULL**. | DDL-ba_incidents |
| BC-REF-03 | `ba_student_remarks` → `ba_assessments` **CASCADE**, `std_students` **RESTRICT**. | DDL-ba_student_remarks |

### BC-EDG (edge cases / requirement gaps)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Unknown `{student}` route id → 404 (`findOrFail`). | Controller student():69 |
| BC-EDG-02 | Unknown `period_id` filter degrades gracefully (`find()` → null), no 500. | Controller student():72-73 |
| BC-EDG-03 | Empty state "No behavioural data found" renders when categoryScores + ratings + incidents are all empty. | student.blade §Empty State |
| BC-EDG-04 | **BUG-BA-013 (split firing):** `student.blade` Category-Wise grid reads `$cs->score` (non-existent column) → per-category Score/%/bar render `0.00`, while controller overall/rank use `numeric_score` correctly. | student.blade:149,162,197 vs Controller:85 |
| BC-EDG-05 | **RPT-GAP-STU-01:** Screen-20 "Grade Lockdown Rule" (hide Draft/Submitted grades + "Grading … in progress" message + staff "Show Drafts" toggle) is NOT implemented. | Screen-20 §Business Rules vs Controller/blade |
| BC-EDG-06 | **RPT-GAP-STU-02 / BUG-BA-011:** Screen-20 "Download PDF" button is absent from `student.blade`; the only export route aborts 501. | Screen-20 §Identity Header vs Controller export():476-480 |
| BC-EDG-07 | **VAL-BA-003:** `export()` authorizes `reports.view` although `BaReportPolicy` exposes an `export` ability on `reports.export`. | Controller export():478 vs BaReportPolicy |

### BC-INT / Tenancy / Security
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Tenant context is initialized; `ba_*` tables resolve within the tenant DB. | Constraint #A |
| BC-INT-02 | **DEAD-BA-001:** `routes/api.php` apiResource has no tenancy middleware and is never registered (RSP maps only web.php). | api.php / RSP · Constraint #23 |
| BC-INT-03 | Web report routes carry the full tenancy middleware stack (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `auth`). | RouteServiceProvider |
| BC-SEC-01 | Rendered report output is HTML-escaped by Blade (stored-XSS smoke). | Security pack |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|-----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Schema | BC-DB-01/02 | DDL | computed_scores schema+model correct; no `score` col | Passes | test_..._01 | Automated |
| TC-P02 | Schema | BC-DB-03 | DDL | incidents schema+model + ENUM values correct | Passes | test_..._02 | Automated |
| TC-P03 | Schema | BC-DB-04 | DDL | student_remarks schema+model correct | Passes | test_..._03 | Automated |
| TC-P04 | Config | BC-AUTH-01 | Route | student() method + reports.student route registered | Passes | test_..._04 | Automated |
| TC-P05 | Render | BC-BIZ-03 | Screen-20 | student.blade renders the four documented zones | Passes | test_..._05 | Automated |
| TC-P06 | Schema | BC-DB-05 | DOC-BA-001 | runtime prefix `ba_` (not `bha_`) | Passes | test_..._06 | Automated |
| TC-P07 | Render | BC-BIZ-03 | Screen-20 | report renders for authorized admin (no 500/login) | Passes | test_..._10 | Automated |
| TC-P08 | Data | BC-BIZ-01/02 | Controller | controller overall+rank use `numeric_score` | Passes | test_..._11 | Automated |
| TC-P09 | Render | BC-BIZ-03 | Screen-20 | KPI badges (Overall, +/- incidents, /5.00) render | Passes | test_..._12 | Automated |
| TC-P10 | Data | BC-BIZ-02 | Controller | class-rank aggregation renders without 500 | Passes | test_..._13 | Automated |
| TC-P11 | Data | BC-BIZ-04 | Controller | incident timeline reads ba_incidents + type split | Passes | test_..._14 | Automated |
| TC-P12 | Data | BC-BIZ-05 | Controller | teacher-remarks section reads ba_student_remarks | Passes | test_..._15 | Automated |
| TC-P13 | Filter | BC-BIZ-06 | Controller | valid period_id filter renders | Passes | test_..._32 | Automated |
| TC-P14 | UI | BC-EDG-03 | blade | empty-state message present | Passes | test_..._60 | Automated |
| TC-P15 | UI | BC-BIZ-06 | blade | period selector renders (Latest Period default) | Passes | test_..._61 | Automated |
| TC-P16 | UI | Screen-20 | blade | "All Reports" back link present | Passes | test_..._62 | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|-----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Invalid ID | BC-EDG-01 | Controller | unknown student id → 404 | 404 | test_..._30 | Automated |
| TC-N02 | Filter | BC-EDG-02 | Controller | unknown period_id → graceful (200/302) | No 500 | test_..._31 | Automated |
| TC-N03 | Guest | BC-AUTH-03 | middleware | guest → redirected to /login | Redirect | test_..._50 | Automated |
| TC-N04 | 403 | BC-AUTH-01 | Controller | limited user → 403 on student report | 403 | test_..._51 | Automated |
| TC-N05 | Security | BC-SEC-01 | Security | rendered report escapes output | No `<script>` | test_..._93 | Automated |

### Dependency (TC-D)
| TC ID | Sub-cat | BC | Source | Description | Expected Result | Test Method | Status |
|-------|---------|-----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | C | BC-REF-01 | DDL | computed_scores FKs RESTRICT | RESTRICT/NO ACTION | test_..._40 | Automated |
| TC-D02 | C/D | BC-REF-02 | DDL | incidents FKs RESTRICT (student/reporter) + SET NULL (category/criterion) | Correct rules | test_..._41 | Automated |
| TC-D03 | B/C | BC-REF-03 | DDL | student_remarks FK CASCADE (assessment) + RESTRICT (student) | Correct rules | test_..._42 | Automated |
| TC-D04 | E | BC-INT-01 | Tenancy | tenant context initialized; ba_* resolves | Passes | test_..._90 | Automated |

### Permissions / Policy (TC-S / TC-AUTH)
| TC ID | BC | Source | Description | Expected Result | Test Method | Status |
|-------|-----|--------|-------------|-----------------|-------------|--------|
| TC-S01 | BC-AUTH-04 | Policy | Policy maps abilities to permission strings | Passes | test_..._52 | Automated |
| TC-S02 | BC-EDG-07 | VAL-BA-003 | export() gate diverges from Policy (`reports.view` vs `reports.export`) | Proven | test_..._53 | Automated |

### Known Source Defects (audit-equivalent) proved by this suite
| ID | Description | Proving Method |
|----|-------------|----------------|
| BUG-BA-013 | student.blade Category-Wise grid reads non-existent `score` column (split firing; overall KPI correct) | test_..._11, test_..._70 |
| BUG-BA-011 | reports/export is a live abort(501) stub — Download PDF has no backing | test_..._71 |
| RPT-GAP-STU-01 | Grade Lockdown Rule (draft-hiding + Show Drafts toggle + lockdown message) not implemented | test_..._72 |
| RPT-GAP-STU-02 | Download PDF button absent from student.blade | test_..._73 |
| VAL-BA-003 | export() authorizes weaker `reports.view` vs Policy's `reports.export` ability | test_..._53 |
| DEAD-BA-001 | api.php apiResource has no tenancy + never registered | test_..._91 |
| DOC-BA-001 | DDL-doc prefix `bha_` diverges from live `ba_` | test_..._06 |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_student_report_01_computed_scores_schema_and_model_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_student_report_02_incidents_schema_and_model_are_correct | TC-P02 | Schema | 01–09 |
| 3 | test_student_report_03_student_remarks_schema_and_model_are_correct | TC-P03 | Schema | 01–09 |
| 4 | test_student_report_04_report_controller_method_and_route_are_registered | TC-P04 | Config | 01–09 |
| 5 | test_student_report_05_student_view_renders_expected_sections | TC-P05 | Render | 01–09 |
| 6 | test_student_report_06_runtime_table_prefix_diverges_from_ddl_doc_ba_001 | TC-P06 | Schema | 01–09 |
| 7 | test_student_report_10_student_report_renders_for_authorized_admin | TC-P07 | Render | 10–19 |
| 8 | test_student_report_11_controller_reads_numeric_score_for_overall_and_rank | TC-P08 / BUG-BA-013 | Data | 10–19 |
| 9 | test_student_report_12_kpi_badges_render_score_and_incident_counts | TC-P09 | Render | 10–19 |
| 10 | test_student_report_13_class_rank_uses_numeric_score_and_renders_or_hides | TC-P10 | Data | 10–19 |
| 11 | test_student_report_14_incident_timeline_reads_ba_incidents | TC-P11 | Data | 10–19 |
| 12 | test_student_report_15_teacher_remarks_section_reads_student_remarks | TC-P12 | Data | 10–19 |
| 13 | test_student_report_30_invalid_student_id_returns_404 | TC-N01 | Negative | 30–39 |
| 14 | test_student_report_31_unknown_period_filter_does_not_error | TC-N02 | Negative | 30–39 |
| 15 | test_student_report_32_period_selector_accepts_valid_filter | TC-P13 | Filter | 30–39 |
| 16 | test_student_report_40_computed_scores_fks_restrict_on_delete | TC-D01 | Dependency | 40–49 |
| 17 | test_student_report_41_incident_fks_restrict_or_set_null_on_delete | TC-D02 | Dependency | 40–49 |
| 18 | test_student_report_42_student_remark_fks_cascade_and_restrict | TC-D03 | Dependency | 40–49 |
| 19 | test_student_report_50_guest_is_redirected_to_login | TC-N03 | Permission | 50–59 |
| 20 | test_student_report_51_limited_user_gets_403_on_student_report | TC-N04 | Permission | 50–59 |
| 21 | test_student_report_52_policy_maps_to_permission_strings | TC-S01 | Permission | 50–59 |
| 22 | test_student_report_53_export_gate_diverges_from_policy_val_ba_003 | TC-S02 / VAL-BA-003 | Permission | 50–59 |
| 23 | test_student_report_60_empty_state_message_present | TC-P14 | UI/UX | 60–69 |
| 24 | test_student_report_61_period_selector_renders | TC-P15 | UI/UX | 60–69 |
| 25 | test_student_report_62_all_reports_back_link_present | TC-P16 | UI/UX | 60–69 |
| 26 | test_student_report_70_category_grid_reads_nonexistent_score_column_bug_ba_013 | BUG-BA-013 | Edge | 70–79 |
| 27 | test_student_report_71_export_is_live_abort_501_stub_bug_ba_011 | BUG-BA-011 | Edge | 70–79 |
| 28 | test_student_report_72_grade_lockdown_rule_not_implemented_rpt_gap_stu_01 | RPT-GAP-STU-01 | Edge | 70–79 |
| 29 | test_student_report_73_download_pdf_button_absent_rpt_gap_stu_02 | RPT-GAP-STU-02 | Edge | 70–79 |
| 30 | test_student_report_90_tenant_context_is_initialized | TC-D04 | Tenancy | 90–99 |
| 31 | test_student_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001 | DEAD-BA-001 | Tenancy | 90–99 |
| 32 | test_student_report_92_web_report_routes_carry_full_tenancy_stack | BC-INT-03 | Tenancy | 90–99 |
| 33 | test_student_report_93_rendered_report_escapes_output | TC-N05 | Security | 90–99 |
