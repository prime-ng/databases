# ClassAnalysis — Test Case List & Business Conditions (TcList)

**Module:** BehaviouralAssessment  · **Feature/Screen:** ClassAnalysis (Class-Section Behaviour Analysis)
**Screen file:** `BehaviouralAssessment_v2/21-Class-Analysis*.md`  · **Screen type:** Report / visualization — **LIGHT (read-focused)**
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController::byClass()`
**Route:** `GET /behavioural-assessment/reports/class/{classSection}` → `behavioural-assessment.reports.class`
**View:** `behaviouralassessment::reports.by-class` (`resources/views/reports/by-class.blade.php`)
**Primary table:** `ba_computed_scores` (live `ba_` prefix; DDL doc says stale `bha_` — see DOC-BA-001)
**File prefix:** `bha_` (filename convention) — test bodies assert the live `ba_` tables.
**Permission prefix:** `tenant.behavioural-assessment.reports.{viewAny|view|export}`
**Activity log:** NONE (read-only report controller — documented absence).
**DB scope:** TENANT-side (tenant_db; tenancy init required).

> **Scope note (per approved inventory):** this is a report/visualization screen. The artifact set is a
> read-focused matrix — render, chart/visualization data correctness vs `ba_computed_scores`, class/section +
> period filters, export, permissions, empty state. It is **not** a CRUD matrix (no create/edit/delete).

---

## 1. Business Conditions

### BC-DB — schema / data model (`ba_computed_scores`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `ba_computed_scores` exists with `id, student_id, category_id, period_id, numeric_score, grade, overall_score, overall_grade, computed_at, is_active, created_by, updated_by, created_at, updated_at, deleted_at`. | DDL-ba_computed_scores |
| BC-DB-02 | The score columns are `numeric_score` (decimal 5,2) and `overall_score` (decimal 5,2). **There is NO bare `score` column.** | DDL-ba_computed_scores |
| BC-DB-03 | Unique key `uq_ba_score` on `(student_id, category_id, period_id)`; soft-deletes present. | DDL-ba_computed_scores |
| BC-DB-04 | Model `BaComputedScore` binds table `ba_computed_scores`, uses `SoftDeletes`, and has `student()/category()/period()` BelongsTo relations. | Model |
| BC-DB-05 | Runtime prefix is `ba_`; the DDL-doc name `bha_computed_scores` must NOT exist (DOC-BA-001). | Audit-DOC-BA-001 |

### BC-BIZ — render + chart/visualization data correctness
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | The report renders for an authorized admin without a 500 (grid or documented empty state). | Screen-BR / view |
| BC-BIZ-02 | Class-Section selector + Period filter render inside `#byClassForm`. | view |
| BC-BIZ-03 | Category-Wise Class Performance table renders class avg/min/max/std-dev per top-level category. | view / byClass() |
| BC-BIZ-04 | Student Ranking table ranks students by overall score; at-risk (< 2.50) rows flagged. | view / byClass() |
| BC-BIZ-05 | **BUG-BA-013:** `byClass()` and `by-class.blade` aggregate a non-existent `score` column (`avg/min/max/pluck('score')`, `$cs->score`). Live column is `numeric_score`. Every overall score → 0.00, every category stat → 0.00, every student flagged at-risk regardless of real score. | Audit-BUG-BA-013 |
| BC-BIZ-06 | Contrast: `student()` (per-student path) correctly reads `numeric_score` — proving the defect is `byClass()`-specific. | BaReportController |

### BC-VAL — invalid input / filter handling
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Unknown `classSection` id → 404 (findOrFail). | byClass() |
| BC-VAL-02 | Non-numeric `classSection` id → 404. | Route model binding |
| BC-VAL-03 | Unknown `period_id` filter degrades gracefully (find() → null), no 500. | byClass() |

### BC-AUTH — authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Guest hitting the report is redirected to `/login`. | middleware |
| BC-AUTH-02 | `byClass()` gates on `tenant.behavioural-assessment.reports.view`; a non-super-admin without it → 403. | byClass() / Policy |
| BC-AUTH-03 | `BaReportPolicy` declares `reports.{viewAny,view,export}` ability strings. | Policy |
| BC-AUTH-04 | **VAL-BA-003:** `export()` authorizes `reports.view` though the Policy exposes an `export` ability on `reports.export` (dead policy method / weaker gate). | Audit-VAL-BA-003 |

### BC-INT / BC-REF — integration & FK dependency
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_computed_scores` FKs → `std_students`, `ba_categories`, `ba_assessment_periods` are RESTRICT/NO ACTION. | DDL / information_schema |
| BC-INT-01 | `byClass()` scopes students to `class_section_id` + `is_active`, and renders only top-level (`parent_id IS NULL`) categories. | byClass() |

### BC-EDG — edge cases / requirement gaps
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Empty state ("No score data available") shows when a class-section/period has no scores. | view |
| BC-EDG-02 | **BUG-BA-011:** `reports/export` is a live `abort(501)` stub for authorized users. | Audit-BUG-BA-011 |
| BC-EDG-03 | **CA-GAP-01:** no working class-analysis CSV export exists — only the 501 stub. | Screen-BR vs controller |
| BC-EDG-04 | **BUG-BA-013 consequence:** category std-dev computed over the null `score` column collapses to 0.00, discarding a real numeric_score spread. | byClass() |

### BC-CFG / Tenancy / Security
| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-01 | Tenant context must be initialized; `ba_computed_scores` resolves within the tenant DB. | tenancy |
| BC-SEC-02 | **DEAD-BA-001:** `routes/api.php` `behaviouralassessments` apiResource uses `auth:sanctum` with NO tenancy middleware AND is never registered (RSP maps only web.php). | Audit-DEAD-BA-001 |
| BC-SEC-03 | Rendered report output is HTML-escaped by Blade (no unescaped `<script>`). | view |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/04 | DDL/Model | Schema + model config truth | Columns/relations/soft-delete correct | `test_class_analysis_01` | Automated |
| TC-P02 | BC-DB-05 | Audit | Runtime `ba_` prefix; `bha_` absent | Divergence proven | `test_class_analysis_02` | Automated |
| TC-P03 | BC-BIZ-01 | Route | byClass route + method registered | Registered | `test_class_analysis_03` | Automated |
| TC-P04 | BC-BIZ-02/03/04 | view | View declares selectors + sections + empty state | All present | `test_class_analysis_04` | Automated |
| TC-P05 | BC-BIZ-01 | view | Report renders for admin (grid or empty state) | No 500 | `test_class_analysis_10` | Automated |
| TC-P06 | BC-BIZ-02 | view | Class-Section + Period filters render | Both present | `test_class_analysis_11` | Automated |
| TC-P07 | BC-VAL-03 | byClass | Period filter narrows without error | 200/302 | `test_class_analysis_12` | Automated |
| TC-P08 | BC-REF-01 | information_schema | Computed-score FKs RESTRICT | RESTRICT/NO ACTION | `test_class_analysis_40` | Automated |
| TC-P09 | BC-INT-01 | byClass | Active-student + top-level-category scoping | Confirmed | `test_class_analysis_41` | Automated |
| TC-P10 | BC-AUTH-03 | Policy | Policy maps permission strings | All 3 present | `test_class_analysis_52` | Automated |
| TC-P11 | BC-EDG-01 | view | Empty state / grid renders | Shown | `test_class_analysis_60` | Automated |
| TC-P12 | BC-BIZ-01 | view | Back-link to Reports Hub | Present | `test_class_analysis_61` | Automated |
| TC-P13 | BC-BIZ-04 | view | At-risk threshold documented | "2.50"/"At Risk" | `test_class_analysis_62` | Automated |
| TC-P14 | BC-SEC-01 | tenancy | Tenant context initialized | Initialized | `test_class_analysis_90` | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | byClass | Unknown class-section id | 404 | `test_class_analysis_30` | Automated |
| TC-N02 | BC-VAL-02 | binding | Non-numeric class-section id | 404 | `test_class_analysis_31` | Automated |
| TC-N03 | BC-VAL-03 | byClass | Unknown period_id filter | 200/302, no 500 | `test_class_analysis_13` | Automated |
| TC-N04 | BC-AUTH-01 | middleware | Guest redirected to login | `/login` | `test_class_analysis_50` | Automated |
| TC-N05 | BC-AUTH-02 | byClass | Limited user blocked | 403 | `test_class_analysis_51` | Automated |
| TC-N06 | BC-SEC-03 | view | Output escaped | No `<script>alert(` | `test_class_analysis_92` | Automated |

### Defect-proving / Dependency (TC-D)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D01 | BC-DB-02/BC-BIZ-05 | Audit-BUG-BA-013 | Model has no `score` attribute | `->score` null while numeric_score set | `test_class_analysis_14` | Automated (bug) |
| TC-D02 | BC-BIZ-05 | Audit-BUG-BA-013 | Class-level `avg('score')` yields 0.00 for a 4.50 student; wrongly at-risk | Proven deterministically | `test_class_analysis_15` | Automated (bug) |
| TC-D03 | BC-BIZ-05/06 | Audit-BUG-BA-013 | Controller `byClass()` aggregates `score`; `student()` uses `numeric_score` | Contrast proven | `test_class_analysis_16` | Automated (bug) |
| TC-D04 | BC-BIZ-05 | Audit-BUG-BA-013 | `by-class.blade` reads `->score < 2.5` | Source proven | `test_class_analysis_17` | Automated (bug) |
| TC-D05 | BC-EDG-04 | Audit-BUG-BA-013 | Std-dev collapses to 0.00 over null `score` | Real spread discarded | `test_class_analysis_72` | Automated (bug) |
| TC-D06 | BC-EDG-02 | Audit-BUG-BA-011 | Export = live `abort(501)` | 501 | `test_class_analysis_70` | Automated (bug) |
| TC-D07 | BC-EDG-03 | CA-GAP-01 | No CSV export implemented | Only 501 stub | `test_class_analysis_71` | Automated (gap) |
| TC-D08 | BC-AUTH-04 | Audit-VAL-BA-003 | export() gate ≠ policy export ability | Divergence proven | `test_class_analysis_53` | Automated (bug) |
| TC-D09 | BC-SEC-02 | Audit-DEAD-BA-001 | API resource lacks tenancy + unregistered | Proven | `test_class_analysis_91` | Automated (bug) |

---

## 3. Test Method Index
| # | Method | TC Map | Band |
|---|--------|--------|------|
| 1 | test_class_analysis_01_computed_scores_schema_and_model_are_correct | TC-P01 | 01–09 Schema |
| 2 | test_class_analysis_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001 | TC-P02 | 01–09 |
| 3 | test_class_analysis_03_byclass_route_and_controller_method_are_registered | TC-P03 | 01–09 |
| 4 | test_class_analysis_04_by_class_view_declares_expected_sections | TC-P04 | 01–09 |
| 5 | test_class_analysis_10_report_renders_for_authorized_admin | TC-P05 | 10–19 BIZ |
| 6 | test_class_analysis_11_class_section_and_period_filters_render | TC-P06 | 10–19 |
| 7 | test_class_analysis_12_period_filter_narrows_without_error | TC-P07 | 10–19 |
| 8 | test_class_analysis_13_unknown_period_filter_degrades_gracefully | TC-N03 | 10–19 |
| 9 | test_class_analysis_14_computed_score_has_no_score_attribute_bug_ba_013 | TC-D01 | 10–19 (bug) |
| 10 | test_class_analysis_15_class_level_aggregation_on_score_yields_zero_bug_ba_013 | TC-D02 | 10–19 (bug) |
| 11 | test_class_analysis_16_controller_byclass_aggregates_nonexistent_score_bug_ba_013 | TC-D03 | 10–19 (bug) |
| 12 | test_class_analysis_17_by_class_blade_reads_nonexistent_score_bug_ba_013 | TC-D04 | 10–19 (bug) |
| 13 | test_class_analysis_30_invalid_class_section_id_returns_404 | TC-N01 | 30–39 VAL |
| 14 | test_class_analysis_31_non_numeric_class_section_id_returns_404 | TC-N02 | 30–39 |
| 15 | test_class_analysis_40_computed_scores_fks_restrict_on_delete | TC-P08 | 40–49 INT |
| 16 | test_class_analysis_41_byclass_selects_active_students_and_top_level_categories | TC-P09 | 40–49 |
| 17 | test_class_analysis_50_guest_is_redirected_to_login | TC-N04 | 50–59 AUTH |
| 18 | test_class_analysis_51_limited_user_gets_403_on_class_report | TC-N05 | 50–59 |
| 19 | test_class_analysis_52_policy_maps_to_permission_strings | TC-P10 | 50–59 |
| 20 | test_class_analysis_53_export_gate_diverges_from_policy_val_ba_003 | TC-D08 | 50–59 (bug) |
| 21 | test_class_analysis_60_empty_state_when_no_scores | TC-P11 | 60–69 UIX |
| 22 | test_class_analysis_61_report_links_back_to_reports_hub | TC-P12 | 60–69 |
| 23 | test_class_analysis_62_at_risk_threshold_is_documented | TC-P13 | 60–69 |
| 24 | test_class_analysis_70_export_is_live_abort_501_stub_bug_ba_011 | TC-D06 | 70–79 (bug) |
| 25 | test_class_analysis_71_class_analysis_export_unimplemented_ca_gap_01 | TC-D07 | 70–79 (gap) |
| 26 | test_class_analysis_72_std_dev_collapses_to_zero_from_broken_score_bug_ba_013 | TC-D05 | 70–79 (bug) |
| 27 | test_class_analysis_90_tenant_context_is_initialized | TC-P14 | 90–99 Tenancy |
| 28 | test_class_analysis_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001 | TC-D09 | 90–99 (bug) |
| 29 | test_class_analysis_92_rendered_report_escapes_output | TC-N06 | 90–99 Security |

## 4. Known Source Defects
| ID | Description | Proving test |
|----|-------------|-------------|
| BUG-BA-013 | `byClass()`/`by-class.blade` aggregate non-existent `score` column (live = `numeric_score`); class scores/stats collapse to 0.00, everyone at-risk. | `_14`,`_15`,`_16`,`_17`,`_72` |
| BUG-BA-011 | `reports/export` = live `abort(501)` stub. | `_70` |
| DEAD-BA-001 | api.php resource has no tenancy middleware and is never registered. | `_91` |
| DOC-BA-001 | DDL doc prefix `bha_` diverges from live `ba_`. | `_02` |
| VAL-BA-003 | `export()` gates on `reports.view`, not the policy's `reports.export`. | `_53` |
| CA-GAP-01 | Requirement class-analysis CSV export unimplemented (only 501 stub). | `_71` |
