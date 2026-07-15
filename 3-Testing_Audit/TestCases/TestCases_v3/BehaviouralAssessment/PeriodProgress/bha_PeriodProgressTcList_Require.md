# bha_PeriodProgress — Test Case List & Business Conditions

**Module:** BehaviouralAssessment · **Feature/Screen:** PeriodProgress (screen 22 — "Longitudinal Trend Dashboard")
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/22-Period-Progress.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController` — **NO `progress()` method (screen unimplemented)**
**Route:** NONE (no `reports/progress`) · **View:** NONE (no `reports/progress.blade.php`)
**Data source (specified):** `ba_computed_scores` (live `ba_` prefix; DDL doc says `bha_` — DOC-BA-001)
**DB scope:** TENANT-side · **File prefix:** `bha_` (filename convention) · **Live tables:** `ba_`
**Screen type:** Report / data-visualization — LIGHT / read-focused (render, data-source correctness, permissions, export, empty state — NOT a CRUD matrix)
**Activity log:** NONE (read-only report surface — documented absence)
**Test file:** `bha_PeriodProgress_TestCas.php` (single comprehensive Dusk suite, 26 methods, no V1/V2)

> **PRIMARY FINDING — the whole screen is specified-but-unbuilt (RPT-GAP-PROG-01).** Screen-22 specifies a
> standalone longitudinal trend dashboard (trend-line chart, category multi-lines, milestone flags, KPI
> Score-Delta cards, 5-category multi-line limit, continuous interpolation of missing periods). An exhaustive
> source scan proves there is **NO `progress()` controller action, NO `reports/progress` route, and NO
> progress view**. `BaReportController` implements index/student/byClass/period/categories/incidents/export —
> none is a progress/trend action. Proven in `_03`/`_04`/`_05`/`_71`/`_74`.

> **BUG-BA-013 applicability (precise).** Which controller method backs this screen? — **none.** But screen-22
> explicitly queries `ba_computed_scores` per period. Of the two implemented computed-scores aggregations a
> trend screen would reuse, **both are defective on a non-existent `score` column** (live column is
> `numeric_score`): `categories()` runs RAW `AVG(score)` → SQL "Unknown column" **hard 500**; `byClass()` runs
> collection `->avg('score')` → null → **silent 0.00**. The per-student `student()` path is CORRECT
> (`avg('numeric_score')`) — the contrast. So **BUG-BA-013 is APPLICABLE to the screen's specified data path**
> (deterministic proof `_72`, source proof `_73`), though it cannot fire on a live route because no route exists.

---

## 1. Business Conditions

### BC-DB — Schema / column / constraint truth
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_computed_scores` exists with `id, student_id, category_id, period_id, numeric_score, grade, overall_score, overall_grade, computed_at, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-ba_computed_scores |
| BC-DB-02 | Live score column is `numeric_score` (DECIMAL 5,2); there is **no** bare `score` column (BUG-BA-013 root) | DDL + Model |
| BC-DB-03 | Unique key `uq_ba_score (student_id, category_id, period_id)` — one row per student/category/period (trend grain) | DDL-ba_computed_scores |
| BC-DB-04 | FKs → `std_students`, `ba_categories`, `ba_assessment_periods` all `ON DELETE RESTRICT` | DDL-ba_computed_scores |
| BC-DB-05 | `BaComputedScore` uses `SoftDeletes`; runtime table carries `ba_` prefix, NOT the DDL-doc `bha_` (DOC-BA-001) | Model + DOC-BA-001 |
| BC-DB-06 | `period_id` is the chronological X-axis key; `numeric_score` is the Y-axis value for a longitudinal plot | DDL + Screen-Widget-1 |

### BC-AUTH — Permission gates
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Reports hub / computed-scores report paths authorize `tenant.behavioural-assessment.reports.{viewAny\|view}` | Controller-index/student |
| BC-AUTH-02 | Guest (unauthenticated) → redirect to `/login` | Middleware `auth` |
| BC-AUTH-03 | Authenticated non-super-admin without `reports.view` → 403 | Gate + constraint #31 |
| BC-AUTH-04 | `BaReportPolicy` maps `viewAny/view/export` → `tenant.behavioural-assessment.reports.{ability}` | Policy |
| BC-AUTH-05 | `export()` authorizes `reports.view` though the Policy exposes an `export` ability on `reports.export` (VAL-BA-003) | Controller-export + Policy |

### BC-BIZ — Render / data-path presence
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Reports hub renders for an authorized admin without a server error | Controller-index |
| BC-BIZ-02 | Reports hub exposes NO Period Progress / trend link (unbuilt screen not advertised) | index.blade |
| BC-BIZ-03 | Nearest computed-scores surface (per-student report) renders 200/302, never 500 (student() uses numeric_score) | Controller-student |
| BC-BIZ-04 | The specified trend source `ba_computed_scores` exists with the axis keys a longitudinal plot needs | DDL + Screen-Widget-1 |

### BC-SM — State machine
| ID | Condition | Source |
|----|-----------|--------|
| BC-SM-— | N/A — a read-only data-visualization screen has no status lifecycle to transition (documented absence) | Screen-22 |

### BC-INT / BC-REF — Integration / referential
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_computed_scores.student_id` → `std_students.id` (cross-module StudentProfile), RESTRICT | DDL |
| BC-REF-02 | `ba_computed_scores.category_id` → `ba_categories.id`, RESTRICT | DDL |
| BC-REF-03 | `ba_computed_scores.period_id` → `ba_assessment_periods.id`, RESTRICT | DDL |

### BC-EDG — Requirement-vs-implementation gaps & defects
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Screen-22 trend widgets (trend-line chart, milestone flags, Score-Delta KPI) have NO controller/view impl (RPT-GAP-PROG-01) | Screen-Widget-1/2/3 |
| BC-EDG-02 | Screen-22 business rules (max-5 category multi-line, continuous interpolation, Score-Delta %) unimplemented (RPT-GAP-PROG-02) | Screen-BR |
| BC-EDG-03 | The specified `ba_computed_scores` per-period aggregation is BUG-BA-013-defective in the reusable methods (`categories()` hard-500, `byClass()` 0.00) | Controller + BUG-BA-013 |
| BC-EDG-04 | Screen-22 step-9 export ("export progress chart to PDF") maps to `export()` = `abort(501)` stub (BUG-BA-011) | Controller-export |
| BC-EDG-05 | `routes/api.php` apiResource has no tenancy middleware and is never registered (DEAD-BA-001) | api.php + RSP #23 |

---

## 2. Test Case List

### Positive (TC-P) — render / data-source / config truth
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Config | BC-DB-01/02/05 | DDL-ba_computed_scores | Schema + model truth of the trend source | Table/columns/model/soft-delete correct; no `score` column | `_01` | Automated |
| TC-P02 | Config | BC-DB-05 | DOC-BA-001 | Runtime prefix `ba_` vs DDL-doc `bha_` | `ba_computed_scores` exists, `bha_computed_scores` does not | `_02` | Automated |
| TC-P03 | Render | BC-BIZ-01 | Controller-index | Reports hub renders for authorized admin | Not bounced to login | `_10` | Automated |
| TC-P04 | Render | BC-BIZ-03 | Controller-student | Nearest computed-scores surface renders | 200/302, never 500 | `_12` | Automated |
| TC-P05 | Data | BC-BIZ-04/BC-DB-06 | DDL + Screen | Trend source + axis keys present | `ba_computed_scores` has period_id + numeric_score | `_13` | Automated |
| TC-P06 | Integrity | BC-REF-01/02/03 | DDL | Computed-scores FKs RESTRICT | RESTRICT/NO ACTION on all three refs | `_40` | Automated |
| TC-P07 | Integrity | BC-DB-03 | DDL | Unique (student, category, period) key | Unique triple index present | `_41` | Automated |
| TC-P08 | Policy | BC-AUTH-04 | Policy | Policy maps permission strings | viewAny/view/export strings present | `_52` | Automated |
| TC-P09 | Tenancy | BC-DB-05 | Constraint A4 | Tenant context initialized | Tenancy initialized; tables resolve | `_90` | Automated |
| TC-P10 | Tenancy | BC-AUTH | RSP | Web routes carry full tenancy stack | 5 middleware needles present | `_92` | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Missing route | BC-EDG-01 | RPT-GAP-PROG-02 | `/reports/progress` hit | 404 (route not registered) | `_30` | Automated |
| TC-N02 | Invalid id | BC-BIZ-03 | Controller-student | Unknown student id on data path | 404 (findOrFail) | `_31` | Automated |
| TC-N03 | Guest | BC-AUTH-02 | Middleware | Unauthenticated hub access | Redirect to `/login` | `_50` | Automated |
| TC-N04 | Forbidden | BC-AUTH-03 | Gate + #31 | Limited user on computed-scores report | 403 before findOrFail | `_51` | Automated |
| TC-N05 | XSS smoke | BC-AUTH | Security | Rendered report escapes output | No unescaped `<script>alert(` | `_93` | Automated |

### Dependency / Defect (TC-D)
| TC ID | Sub | BC | Source | Description | Expected Result | Test Method | Status |
|-------|-----|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | F | BC-EDG-01 | RPT-GAP-PROG-01 | No progress() controller action | All 4 progress/trend names absent | `_03` | Automated |
| TC-D02 | F | BC-EDG-01 | RPT-GAP-PROG-02 | No progress route registered | 3 candidate route names absent | `_04` | Automated |
| TC-D03 | F | BC-EDG-01 | RPT-GAP-PROG-03 | No progress view / trend widgets | view files absent; 7 widget strings absent | `_05` | Automated |
| TC-D04 | E | BC-BIZ-02 | index.blade | Hub does not link Period Progress | No "Period Progress"/`reports/progress` in hub | `_11` | Automated |
| TC-D05 | G | BC-EDG-04 | BUG-BA-011 | Export = live abort(501) stub | HTTP 501 | `_70` | Automated |
| TC-D06 | G | BC-EDG-01 | RPT-GAP-PROG-01 | Trend widgets unimplemented (source) | no progress/milestone/interpolat in controller | `_71` | Automated |
| TC-D07 | G | BC-EDG-03 | BUG-BA-013 | Deterministic: avg('score') → 0.00 for 4.25 student | brokenAvg null → 0.00; numeric_score = 4.25 | `_72` | Automated |
| TC-D08 | G | BC-EDG-03 | BUG-BA-013 | Source: categories()/byClass() defective; student() correct | AVG(score)/avg('score') present; student uses numeric_score | `_73` | Automated |
| TC-D09 | G | BC-EDG-02 | RPT-GAP-PROG-02 | Multi-line/interpolation/KPI rules unimplemented | no interpolat/max-5/score-delta impl | `_74` | Automated |
| TC-D10 | E | BC-EDG-05 | DEAD-BA-001 | api resource dead + no tenancy | route unregistered; api.php lacks tenancy | `_91` | Automated |
| TC-D11 | C | BC-EDG-05 | VAL-BA-003 | Export gate diverges from policy | export() gates reports.view not reports.export | `_53` | Automated |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `_01_computed_scores_schema_and_model_are_correct` | TC-P01 | Config | 01–09 |
| 2 | `_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` | TC-P02 | Config | 01–09 |
| 3 | `_03_no_progress_controller_action_exists_rpt_gap_prog_01` | TC-D01 | Gap | 01–09 |
| 4 | `_04_no_progress_route_is_registered_rpt_gap_prog_02` | TC-D02 | Gap | 01–09 |
| 5 | `_05_no_progress_view_or_trend_widgets_exist_rpt_gap_prog_03` | TC-D03 | Gap | 01–09 |
| 6 | `_10_reports_hub_renders_for_authorized_admin` | TC-P03 | Render | 10–19 |
| 7 | `_11_reports_hub_does_not_link_a_period_progress_screen` | TC-D04 | Render | 10–19 |
| 8 | `_12_computed_scores_backed_report_renders_as_nearest_surface` | TC-P04 | Render | 10–19 |
| 9 | `_13_requirement_names_computed_scores_as_the_trend_data_source` | TC-P05 | Data | 10–19 |
| 10 | `_30_progress_url_returns_404_because_screen_is_unbuilt` | TC-N01 | Negative | 30–39 |
| 11 | `_31_invalid_student_id_on_data_path_returns_404` | TC-N02 | Negative | 30–39 |
| 12 | `_40_computed_scores_fks_restrict_on_delete` | TC-P06 | Integrity | 40–49 |
| 13 | `_41_computed_scores_uniquely_key_student_category_period` | TC-P07 | Integrity | 40–49 |
| 14 | `_50_guest_is_redirected_to_login` | TC-N03 | Auth | 50–59 |
| 15 | `_51_limited_user_gets_403_on_computed_scores_report` | TC-N04 | Auth | 50–59 |
| 16 | `_52_report_policy_maps_to_permission_strings` | TC-P08 | Auth | 50–59 |
| 17 | `_53_export_gate_diverges_from_policy_val_ba_003` | TC-D11 | Auth | 50–59 |
| 18 | `_70_export_is_live_abort_501_stub_bug_ba_011` | TC-D05 | Edge | 70–79 |
| 19 | `_71_trend_dashboard_widgets_are_unimplemented_rpt_gap_prog_01` | TC-D06 | Edge | 70–79 |
| 20 | `_72_computed_scores_aggregation_on_score_yields_zero_bug_ba_013` | TC-D07 | Edge | 70–79 |
| 21 | `_73_controller_score_aggregation_is_defective_contrast_student_bug_ba_013` | TC-D08 | Edge | 70–79 |
| 22 | `_74_multiline_limit_and_interpolation_rules_unimplemented_rpt_gap_prog_02` | TC-D09 | Edge | 70–79 |
| 23 | `_90_tenant_context_is_initialized` | TC-P09 | Tenancy | 90–99 |
| 24 | `_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001` | TC-D10 | Tenancy | 90–99 |
| 25 | `_92_web_report_routes_carry_full_tenancy_stack` | TC-P10 | Tenancy | 90–99 |
| 26 | `_93_rendered_report_escapes_output` | TC-N05 | Security | 90–99 |

## 4. Known Source Defects (audit-equivalent)
| ID | Description | Proving method |
|----|-------------|----------------|
| RPT-GAP-PROG-01 | Period Progress screen unimplemented — no method/route/view/trend widgets | `_03`,`_04`,`_05`,`_71` |
| RPT-GAP-PROG-02 | Screen-22 business rules (max-5 lines, interpolation, Score-Delta %) unimplemented | `_74` |
| BUG-BA-013 | Specified `ba_computed_scores` aggregation defective on non-existent `score` column (categories() hard-500, byClass() 0.00) | `_72`,`_73` |
| BUG-BA-011 | `reports/export` = permanent `abort(501)` stub (screen-22 step-9 export) | `_70` |
| DEAD-BA-001 | `routes/api.php` apiResource has no tenancy + never registered | `_91` |
| DOC-BA-001 | DDL-doc prefix `bha_` diverges from live `ba_` | `_02` |
| VAL-BA-003 | `export()` gates `reports.view`, not the policy's `reports.export` ability | `_53` |
