# bha_PeriodReport — Test Case List & Business Conditions

**Module:** BehaviouralAssessment · **Feature/Screen:** PeriodReport ("Teacher Progress Report")
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/18-Period-Report.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController@period(int $period)`
**Route:** `GET reports/period/{period}` → `behavioural-assessment.reports.period`
**View:** `resources/views/reports/period.blade.php`
**DB scope:** TENANT-side · **File prefix:** `bha_` (filename convention) · **Live tables:** `ba_` (DOC-BA-001)
**Screen type:** Report — LIGHT / read-focused (render, aggregate correctness, period scoping, permissions, export, empty-state — NOT a CRUD matrix)
**Activity log:** NONE (read-only report controller — documented absence)
**Test file:** `bha_PeriodReport_TestCas.php` (single comprehensive Dusk suite, 32 methods, no V1/V2)

> **Critical scope note — computed_scores is NOT read here.** The module inventory tags PeriodReport as
> "reads computed_scores (LIGHT)", but the implemented `period()` method aggregates **`ba_assessments`,
> `ba_assessment_ratings`, `ba_student_remarks`** only — it never queries `ba_computed_scores` or its
> `score`/`numeric_score` columns. Therefore **BUG-BA-013** (aggregation on the non-existent `score` column
> in `byClass()`/`categories()`) **does NOT affect the Period Report path** — proven as a contrast in `_14`.
> The `score`-column bug lives in the ClassAnalysis / CategoryPerformance screens, not here.

> **Critical requirement gap — the implemented screen is not the specified screen.** Screen-18 specifies a
> **multi-period comparison grid** (Roll No, Student, Period-N averages, Score Delta, per-period incidents,
> Trend Indicator) with Session + Class/Section + multi-period-select filters. The implemented `period()`
> renders a **single-period Teacher Progress report** instead. The comparative analytics (delta formula,
> trend arrows, period multi-select) are unimplemented (RPT-GAP-PRD-01/02, proven in `_71`/`_72`).

---

## 1. Business Conditions

### BC-DB — Schema / column / constraint truth
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_assessment_periods` exists with `id, academic_session_id, academic_term_id, name, start_date, end_date, deadline, status, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-ba_assessment_periods |
| BC-DB-02 | `ba_assessment_periods.status` = `ENUM('open','closed','locked')` default `open` | DDL-ba_assessment_periods |
| BC-DB-03 | `ba_assessments` exists with `id, period_id, teacher_id, class_section_id, status, submitted_at, reviewed_by, reviewed_at, reviewer_remarks, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-ba_assessments |
| BC-DB-04 | `ba_assessments.status` = `ENUM('draft','submitted','reviewed','locked')` default `draft` (FSM) | DDL-ba_assessments |
| BC-DB-05 | `ba_assessments` unique key `uq_ba_assessment (teacher_id, class_section_id, period_id)` | DDL-ba_assessments |
| BC-DB-06 | Both models use `SoftDeletes`; runtime tables carry `ba_` prefix, NOT the DDL-doc `bha_` | Model + DOC-BA-001 |

### BC-VAL — Input / route validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `period()` route param is `int $period`; unknown id → `findOrFail` → 404 | Controller-period |
| BC-VAL-02 | A non-numeric `{period}` segment does not resolve to a valid report | Controller-period |
| BC-VAL-03 | An unknown/absent `?period` query param is ignored (route binds path segment only) | Controller-period |

### BC-AUTH — Permission gates
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `period()` authorizes `tenant.behavioural-assessment.reports.view` before `findOrFail` | Controller-period |
| BC-AUTH-02 | Guest (unauthenticated) → redirect to `/login` | Middleware `auth` |
| BC-AUTH-03 | Authenticated non-super-admin without `reports.view` → 403 | Gate + constraint #31 |
| BC-AUTH-04 | `BaReportPolicy` maps `viewAny/view/export` → `tenant.behavioural-assessment.reports.{ability}` | Policy |
| BC-AUTH-05 | `export()` authorizes `reports.view` though the Policy exposes an `export` ability on `reports.export` (VAL-BA-003) | Controller-export + Policy |

### BC-BIZ — Business logic / aggregation
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `period()` computes assessment workflow status counts (`status → COUNT(*)`) for the period | Controller-period |
| BC-BIZ-02 | Teacher-wise progress: `submitted` = count of status ∈ {submitted, reviewed, locked}; status = ALL_SUBMITTED / PARTIAL / PENDING | Controller-period |
| BC-BIZ-03 | Rating-grid completion computed from `ba_assessment_ratings` (filled cells per assessment) | Controller-period |
| BC-BIZ-04 | Remarks completion computed from `ba_student_remarks` (with/without remarks) | Controller-period |
| BC-BIZ-05 | `daysRemaining` derived from `period->deadline` (overdue / remaining) | Controller-period |
| BC-BIZ-06 | `period()` reads NO computed scores — BUG-BA-013 not applicable to this path | Controller-period (contrast) |

### BC-SM — Workflow statuses surfaced (read-only)
| ID | State set | Trigger (elsewhere) | Surfaced by report | Source |
|----|-----------|---------------------|--------------------|--------|
| BC-SM-01 | Assessment FSM: `draft → submitted → reviewed → locked` | Assessment submit/review/lock (not this screen) | workflow status breakdown + legend | Screen-BR + DDL-ba_assessments |
| BC-SM-02 | Period lifecycle: `open / closed / locked` | Period close/lock (not this screen) | period status badge | DDL-ba_assessment_periods |

> The Period Report **reads** these state machines but triggers no transitions (read-only). No illegal-transition
> negative tests apply; render-correctness of the surfaced status set is asserted instead.

### BC-INT / BC-REF — Integration / FK dependency
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_assessments.period_id` → `ba_assessment_periods.id` ON DELETE RESTRICT | DDL-ba_assessments |
| BC-REF-02 | `ba_assessments.teacher_id` → `sch_employees.id` ON DELETE RESTRICT (cross-module) | DDL-ba_assessments |
| BC-REF-03 | `ba_assessments.class_section_id` → `sch_class_section_jnt.id` ON DELETE RESTRICT (cross-module) | DDL-ba_assessments |
| BC-INT-01 | `period()` eager-loads `teacher (sch_employees)`, `classSection (sch_class_section_jnt)`, `academicSession` — must render without 500 when sparse | Controller-period |

### BC-EDG — Edge cases / requirement-vs-implementation gaps
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `reports/export` is a permanent `abort(501)` stub on a live authorized route (BUG-BA-011) | Controller-export + Audit |
| BC-EDG-02 | Screen-18 multi-period comparison grid (Score Delta / Trend / Compare Periods) is NOT implemented (RPT-GAP-PRD-01) | Screen-BR vs impl |
| BC-EDG-03 | Screen-18 Delta formula + Dynamic Period Mapping business rules have no implementation (RPT-GAP-PRD-02) | Screen-BR vs impl |
| BC-EDG-04 | Screen-18 export (report cards / charts) unimplemented — only the 501 stub (RPT-GAP-PRD-03) | Screen-BR vs impl |
| BC-EDG-05 | Period selector `<select name="period">` auto-submits `?period=<id>` but `period()` binds only the route segment → non-functional filter (UI-BA-PRD-01) | View vs Controller |
| BC-EDG-06 | Empty state: "No assessments found for this period." when no assessments exist | View |

### BC-TEN — Tenancy / API deadness
| ID | Condition | Source |
|----|-----------|--------|
| BC-TEN-01 | Report runs tenant-side; `ba_*` tables resolve inside the tenant DB | Constraint A4 |
| BC-TEN-02 | `routes/api.php` apiResource has NO tenancy middleware AND is never registered (DEAD-BA-001) | api.php + RSP + constraint #23 |
| BC-TEN-03 | Web report routes carry the full tenancy stack (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified`) | RSP |
| BC-TEN-04 | Rendered report output is HTML-escaped by Blade (stored-XSS smoke) | View (Blade `{{ }}`) |

---

## 2. Test Case List

### Positive / render / aggregate (TC-P)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Schema | BC-DB-01..06 | DDL | Period + assessment schema & models correct | Tables/columns/enums/softDeletes match | `test_period_report_01_*` | Automated |
| TC-P02 | Schema | BC-DB-06 | DOC-BA-001 | Runtime `ba_` prefix vs DDL `bha_` | `ba_` exists, `bha_` does not | `test_period_report_02_*` | Automated |
| TC-P03 | Routing | BC-VAL-01, BC-AUTH-01 | Routes | Controller `period()` + routes registered | Methods + routes present | `test_period_report_03_*` | Automated |
| TC-P04 | View | BC-BIZ-01..04 | View | Period view + breadcrumb + selector present | Blade markers found | `test_period_report_04_*` | Automated |
| TC-P05 | Render | BC-AUTH-01 | Controller | Reports hub renders for authorized admin | Not bounced to login | `test_period_report_10_*` | Automated |
| TC-P06 | Render | BC-BIZ-01, BC-BIZ-02 | Controller | Period report renders teacher progress for a real period | Heading renders, no 500 | `test_period_report_11_*` | Automated |
| TC-P07 | Render | BC-BIZ-01, BC-SM-01 | View | Workflow status breakdown renders (draft/submitted/reviewed/locked) | Four labels render | `test_period_report_12_*` | Automated |
| TC-P08 | Render | BC-BIZ-02, BC-EDG-06 | View | Teacher-progress table OR empty state renders | One present | `test_period_report_13_*` | Automated |
| TC-P09 | Data | BC-BIZ-06 | Controller | period() does NOT read computed `score` column (contrast BUG-BA-013) | No score/numeric_score/BaComputedScore in period() | `test_period_report_14_*` | Automated |
| TC-P10 | Data | BC-BIZ-01, BC-BIZ-02 | Controller | Workflow counts reflect seeded assessment statuses | Seeded period renders without error | `test_period_report_15_*` | Automated (guarded) |
| TC-P11 | Data | BC-BIZ-03, BC-BIZ-04 | Controller | Remarks + rating completion read the right tables | Source references confirmed | `test_period_report_16_*` | Automated |
| TC-P12 | SM | BC-SM-01 | Screen-BR + DDL | Report surfaces the documented assessment FSM statuses | Enum + view legend match | `test_period_report_20_*` | Automated |
| TC-P13 | SM | BC-SM-02 | DDL | Period lifecycle badge uses open/closed/locked | Badge map present | `test_period_report_21_*` | Automated |
| TC-P14 | UI | BC-EDG-06 | View | Empty-state message present | "No assessments found for this period" | `test_period_report_60_*` | Automated |
| TC-P15 | UI | BC-BIZ-05 | View | Period selector dropdown renders options + back link | Selector + "All Reports" render | `test_period_report_61_*` | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Invalid id | BC-VAL-01 | Controller | Unknown period id | 404 (findOrFail) | `test_period_report_30_*` | Automated |
| TC-N02 | Invalid id | BC-VAL-02 | Controller | Non-numeric period id | 404/400/500 (not a valid report) | `test_period_report_31_*` | Automated |
| TC-N03 | Guest | BC-AUTH-02 | Middleware | Guest hits period report | Redirect to /login | `test_period_report_50_*` | Automated |
| TC-N04 | AuthZ | BC-AUTH-03 | Gate | Limited user hits period report | 403 before findOrFail | `test_period_report_51_*` | Automated |
| TC-N05 | Security | BC-TEN-04 | View | Rendered report escapes output | No raw `<script>alert(` | `test_period_report_93_*` | Automated |

### Dependency (TC-D)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | C (RESTRICT) | BC-REF-01..03 | DDL | `ba_assessments` FKs RESTRICT on delete | RESTRICT/NO ACTION | `test_period_report_40_*` | Automated |
| TC-D02 | E (cross-module) | BC-INT-01 | Controller | Eager-loads teacher/section/session defensively | 200/302, never 500 | `test_period_report_41_*` | Automated |
| TC-D03 | AuthZ policy | BC-AUTH-04 | Policy | Policy maps to permission strings | All three abilities mapped | `test_period_report_52_*` | Automated |

### Edge / defect-proving (TC-E)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-E01 | BUG-BA-011 | BC-EDG-01 | Audit | Export live abort(501) stub | HTTP 501 | `test_period_report_70_*` | Automated |
| TC-E02 | VAL-BA-003 | BC-AUTH-05 | Controller+Policy | Export gate diverges from policy | reports.view used, reports.export unused | `test_period_report_53_*` | Automated |
| TC-E03 | RPT-GAP-PRD-01 | BC-EDG-02 | Screen-BR | Comparison grid not implemented | No Score Delta / Trend / Compare Periods | `test_period_report_71_*` | Automated |
| TC-E04 | RPT-GAP-PRD-02 | BC-EDG-03 | Screen-BR | Delta + dynamic-mapping rules unimplemented | No previous-period/delta logic | `test_period_report_72_*` | Automated |
| TC-E05 | RPT-GAP-PRD-03 | BC-EDG-04 | Screen-BR | Report export unimplemented (only 501) | abort(501), no CSV writer | `test_period_report_73_*` | Automated |
| TC-E06 | UI-BA-PRD-01 | BC-EDG-05 | View+Controller | Period selector filter non-functional | Selector posts ?period; period() ignores it | `test_period_report_62_*` | Automated |

### Tenancy / API (TC-T)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | BC-TEN-01 | Constraint A4 | Tenant context initialized; tables resolve | initialized + hasTable | `test_period_report_90_*` | Automated |
| TC-T02 | API dead | BC-TEN-02 | DEAD-BA-001 | api resource lacks tenancy & unregistered | not registered + no tenancy middleware | `test_period_report_91_*` | Automated |
| TC-T03 | Tenancy | BC-TEN-03 | RSP | Web routes carry full tenancy stack | All middleware needles present | `test_period_report_92_*` | Automated |

---

## 3. Test Method Index (bands)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_period_report_01_period_and_assessment_schema_and_models_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `test_period_report_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` | TC-P02 | Schema/DOC | 01–09 |
| 3 | `test_period_report_03_report_controller_period_method_and_routes_are_registered` | TC-P03 | Routing | 01–09 |
| 4 | `test_period_report_04_period_view_exists_with_breadcrumb_and_period_selector` | TC-P04 | View | 01–09 |
| 5 | `test_period_report_10_reports_hub_renders_for_authorized_admin` | TC-P05 | Render | 10–19 |
| 6 | `test_period_report_11_period_report_renders_teacher_progress_for_real_period` | TC-P06 | Render | 10–19 |
| 7 | `test_period_report_12_workflow_status_breakdown_renders` | TC-P07 | Render/SM | 10–19 |
| 8 | `test_period_report_13_teacher_progress_table_or_empty_state_renders` | TC-P08 | Render | 10–19 |
| 9 | `test_period_report_14_period_report_does_not_read_computed_score_column_contrast_ba_013` | TC-P09 | Data | 10–19 |
| 10 | `test_period_report_15_workflow_counts_reflect_seeded_assessment_statuses` | TC-P10 | Data | 10–19 |
| 11 | `test_period_report_16_remarks_completion_reads_student_remarks` | TC-P11 | Data | 10–19 |
| 12 | `test_period_report_20_report_surfaces_documented_assessment_fsm_statuses` | TC-P12 | SM | 20–29 |
| 13 | `test_period_report_21_period_lifecycle_badge_uses_open_closed_locked` | TC-P13 | SM | 20–29 |
| 14 | `test_period_report_30_invalid_period_id_returns_404` | TC-N01 | Negative | 30–39 |
| 15 | `test_period_report_31_non_numeric_period_id_is_rejected` | TC-N02 | Negative | 30–39 |
| 16 | `test_period_report_40_assessments_fks_restrict_on_delete` | TC-D01 | Dependency | 40–49 |
| 17 | `test_period_report_41_period_report_eager_loads_cross_module_relations_defensively` | TC-D02 | Dependency | 40–49 |
| 18 | `test_period_report_50_guest_is_redirected_to_login` | TC-N03 | AuthZ | 50–59 |
| 19 | `test_period_report_51_limited_user_gets_403_on_period_report` | TC-N04 | AuthZ | 50–59 |
| 20 | `test_period_report_52_policy_maps_to_permission_strings` | TC-D03 | AuthZ | 50–59 |
| 21 | `test_period_report_53_export_gate_diverges_from_policy_val_ba_003` | TC-E02 | AuthZ/Defect | 50–59 |
| 22 | `test_period_report_60_empty_state_message_for_period_without_assessments` | TC-P14 | UI | 60–69 |
| 23 | `test_period_report_61_period_selector_dropdown_renders_options` | TC-P15 | UI | 60–69 |
| 24 | `test_period_report_62_period_selector_submits_query_but_route_binds_path_segment_ui_ba_prd_01` | TC-E06 | UI/Defect | 60–69 |
| 25 | `test_period_report_70_export_is_live_abort_501_stub_bug_ba_011` | TC-E01 | Edge/Defect | 70–79 |
| 26 | `test_period_report_71_requirement_comparison_grid_is_not_implemented_rpt_gap_prd_01` | TC-E03 | Edge/Gap | 70–79 |
| 27 | `test_period_report_72_delta_and_dynamic_mapping_rules_are_unimplemented_rpt_gap_prd_02` | TC-E04 | Edge/Gap | 70–79 |
| 28 | `test_period_report_73_report_card_export_unimplemented_only_dead_501_route_rpt_gap_prd_03` | TC-E05 | Edge/Gap | 70–79 |
| 29 | `test_period_report_90_tenant_context_is_initialized` | TC-T01 | Tenancy | 90–99 |
| 30 | `test_period_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001` | TC-T02 | Tenancy/Dead | 90–99 |
| 31 | `test_period_report_92_web_report_routes_carry_full_tenancy_stack` | TC-T03 | Tenancy | 90–99 |
| 32 | `test_period_report_93_rendered_report_escapes_output` | TC-N05 | Security | 90–99 |

---

## 4. Known Source Defects (audit + discovered)

| ID | Severity | Description | Proving method |
|----|----------|-------------|----------------|
| BUG-BA-011 | High | `reports/export` = permanent `abort(501)` stub on a live authorized route | `_70` |
| DEAD-BA-001 | Medium | `routes/api.php` apiResource lacks tenancy middleware AND is never registered (RSP maps only web.php) | `_91` |
| DOC-BA-001 | Doc | DDL doc prefix `bha_` diverges from live `ba_` | `_02` |
| VAL-BA-003 | Low | `export()` gates on `reports.view` though Policy exposes an `export` ability on `reports.export` | `_53` |
| RPT-GAP-PRD-01 | High | Screen-18 multi-period comparison grid (Score Delta / Trend / Compare Periods) not implemented; single-period Teacher Progress rendered instead | `_71` |
| RPT-GAP-PRD-02 | Medium | Screen-18 Delta formula + Dynamic Period Mapping business rules unimplemented | `_72` |
| RPT-GAP-PRD-03 | Medium | Screen-18 report-card/chart export unimplemented — only the 501 stub | `_73` |
| UI-BA-PRD-01 | Medium | Period selector auto-submits `?period=<id>` but `period()` binds only the route segment → non-functional period filter | `_62` |
| (contrast) BUG-BA-013 | n/a here | Non-existent `score` column bug does NOT affect `period()` — proven not-applicable | `_14` |
