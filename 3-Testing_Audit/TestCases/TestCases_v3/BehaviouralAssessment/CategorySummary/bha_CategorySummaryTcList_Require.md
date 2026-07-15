# bha_CategorySummary — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (BHA) · **Feature/Screen:** CategorySummary (Category Summary Report)
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/17-Category-Summary.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController::categories()`
**Route:** `behavioural-assessment.reports.categories` → `GET /behavioural-assessment/reports/categories` (static; filter via `?period_id=`)
**View:** `behaviouralassessment::reports.categories` (breadcrumb title "Category Performance")
**Primary table (read):** `ba_computed_scores` (live `ba_` prefix; DDL doc says stale `bha_` — DOC-BA-001)
**Screen type:** Report — LIGHT, read-focused (render / aggregate correctness / filters / export / permissions / empty state). **NOT a CRUD matrix.**
**DB scope:** TENANT-side (tenant init required). **Activity log:** none (read-only controller).
**Test style:** browser Dusk (`extends DuskTestCase`) — mirrors committed siblings `RatingScale` and `StudentScoresReport`.

> **PREFIX RULE:** filename prefix `bha_`; **all test bodies assert the live `ba_` tables**. Asserting `bha_` false-fails (DOC-BA-001).

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-ba_computed_scores`, migration `2026_06_16_130619_create_ba_computed_scores_table.php`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_computed_scores` exists with columns `id, student_id, category_id, period_id, numeric_score, grade, overall_score, overall_grade, computed_at, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_computed_scores |
| BC-DB-02 | The score column is **`numeric_score` DECIMAL(5,2)**; there is **NO** bare `score` column | DDL-ba_computed_scores |
| BC-DB-03 | Unique key `(student_id, category_id, period_id)`; soft-delete via `deleted_at` | DDL-ba_computed_scores |
| BC-DB-04 | FKs `student_id→std_students`, `category_id→ba_categories`, `period_id→ba_assessment_periods`, all `ON DELETE RESTRICT` | DDL-ba_computed_scores |
| BC-DB-05 | Runtime table is `ba_computed_scores`; stale `bha_computed_scores` must NOT exist | Audit-DOC-BA-001 |

### BC-BIZ — Business rules / render (Source: Screen-17, controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Reports Hub advertises a "Category & Criteria Performance" card linking to `reports.categories` | reports/index.blade |
| BC-BIZ-02 | `categories()` computes **school-wide per-category averages** via raw SQL over `ba_computed_scores`, grouped by `category_id` | Controller `categories()` |
| BC-BIZ-03 | **BUG-BA-013** — the raw aggregate is `AVG(score)/MIN(score)/MAX(score)`, but `score` is not a column → SQLSTATE[42S22] "Unknown column 'score'" → the page **HARD-500s** | Controller `categories()` + DDL |
| BC-BIZ-04 | Bottom-10 criteria block aggregates `ba_rating_levels.numeric_value` (a real column) — unaffected by the bug, but never reached (the category aggregate errors first) | Controller `categories()` |
| BC-BIZ-05 | The report is **anonymized** — no student names/roll/admission numbers; only counts + averages | Screen-17-BR (Anonymized Reporting) |
| BC-BIZ-06 | Contrast: `student()` aggregates `numeric_score` correctly — BUG-BA-013 is `categories()`/`byClass()`-specific | Controller `student()` |

### BC-AUTH — Authorization (Source: `BaReportPolicy`, controller gates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `categories()` authorizes `tenant.behavioural-assessment.reports.view` | Controller |
| BC-AUTH-02 | Guest → redirect `/login` | web middleware `auth` |
| BC-AUTH-03 | Authenticated user lacking `reports.view` → 403 (gate fires before the broken query) | Policy + Gate |
| BC-AUTH-04 | `BaReportPolicy` maps `viewAny/view/export` → `tenant.behavioural-assessment.reports.{ability}` | Policy |
| BC-AUTH-05 | **VAL-BA-003** — `export()` authorizes `reports.view`, not the Policy's `reports.export` ability (dead policy method / weaker gate) | Controller `export()` vs Policy |

### BC-INT / BC-REF — Integration / FK (Source: DDL, controller joins)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `categories()` depends on `ba_categories`, `ba_criteria`, `ba_rating_levels`, `ba_class_category_jnt`, and SchoolSetup classes | Controller `categories()` |
| BC-REF-01 | `ba_computed_scores` FKs are RESTRICT (no cascade delete of scores) | DDL-ba_computed_scores |

### BC-EDG — Edge cases / requirement-vs-implementation gaps (Source: Screen-17 vs impl)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | **BUG-BA-011** — `reports/export` is a live `abort(501)` stub; the requirement's PDF/CSV export is unavailable | Controller `export()` |
| BC-EDG-02 | **RPT-GAP-11** — requirement Class + Section filters are NOT implemented; only a `period_id` filter exists | Screen-17 Filters vs categories.blade |
| BC-EDG-03 | **RPT-GAP-12** — requirement columns Students Count / Category Average / Top Criterion / Lowest Criterion / Cohort Distribution + PDF/CSV export are NOT implemented as specified | Screen-17 grid vs impl |
| BC-EDG-04 | **DOC-BA-002** — requirement screens 17 (Category-Summary) and 23 (Category-Performance) share ONE implementation (`categories()` / `categories.blade`) | Screen-17 & Screen-23 vs routes |
| BC-EDG-05 | Empty state "No computed scores available" is declared in the view but unreachable while BUG-BA-013 stands | categories.blade |

### BC-INT (Tenancy / API) — (Source: routes, RSP, constraint #23)
| ID | Condition | Source |
|----|-----------|--------|
| BC-TEN-01 | Tenant context must be initialized; `ba_computed_scores` resolves inside the tenant DB | Constraint #A4 |
| BC-TEN-02 | **DEAD-BA-001** — `routes/api.php` `behaviouralassessments` apiResource has NO tenancy middleware AND is never registered (RSP::map maps only web.php) | Audit-DEAD-BA-001 + routes/api.php |
| BC-TEN-03 | Web report routes carry the full tenancy stack (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified`) | RouteServiceProvider |
| BC-SEC-01 | Category names are Blade-escaped (`{{ }}`, never `{!! !!}`) | categories.blade |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Schema | BC-DB-01/02/03 | DDL | Schema + model config correct; `numeric_score` present, `score` absent | Asserts pass | `test_category_summary_01_*` | ✅ |
| TC-P02 | Config | BC-DB-05 | Audit | Runtime prefix `ba_`, stale `bha_` absent | Asserts pass | `test_category_summary_02_*` | ✅ |
| TC-P03 | Routing | BC-BIZ-01/02 | Routes | Controller methods + routes registered; categories route is a static GET (no param) | Asserts pass | `test_category_summary_03_*` | ✅ |
| TC-P04 | View | BC-BIZ-01 | Blade | Categories view + Reports-Hub link exist | Asserts pass | `test_category_summary_04_*` | ✅ |
| TC-P05 | Render | BC-BIZ-01 | Blade | Reports Hub renders for authorized admin (card visible) | Card visible | `test_category_summary_10_*` | ✅ |
| TC-P06 | Contrast | BC-BIZ-06 | Controller | `student()` correctly reads `numeric_score` | Source asserts | `test_category_summary_15_*` | ✅ |
| TC-P07 | Correctness | BC-BIZ-04 | Controller/DDL | Bottom-10 criteria reads `ba_rating_levels.numeric_value` | Source + schema assert | `test_category_summary_16_*` | ✅ |
| TC-P08 | Anonymization | BC-BIZ-05 | Screen-17 | View prints no student identity, only `student_count` | Source asserts | `test_category_summary_17_*` | ✅ |
| TC-P09 | UI/filter | BC-EDG (filter) | Blade | View exposes a period filter | `name="period_id"` present | `test_category_summary_61_*` | ✅ |
| TC-P10 | UI/empty | BC-EDG-05 | Blade | View declares empty-state message | present | `test_category_summary_60_*` | ✅ |
| TC-P11 | UI/nav | BC-BIZ-01 | Blade | Reports Hub links to categories report | link present | `test_category_summary_62_*` | ✅ |
| TC-P12 | Dependency | BC-INT-01 | DDL | Dependency tables exist; BaCategory fillable on polarity/parent/sort | Asserts pass | `test_category_summary_41_*` | ✅ |
| TC-P13 | Tenancy | BC-TEN-01 | Constraint | Tenant context initialized; table resolves | Asserts pass | `test_category_summary_90_*` | ✅ |
| TC-P14 | Tenancy | BC-TEN-03 | RSP | Web routes carry full tenancy stack | Asserts pass | `test_category_summary_92_*` | ✅ |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Bug (DB) | BC-BIZ-03 | Controller/DDL | Raw `AVG(score)` on `ba_computed_scores` throws (unknown column); `AVG(numeric_score)` succeeds | QueryException thrown / control passes | `test_category_summary_11_*` | ✅ |
| TC-N02 | Bug (route) | BC-BIZ-03 | Route | Authorized admin opening the page gets HTTP 500 | 500 (skip if disabled) | `test_category_summary_12_*` | ✅ |
| TC-N03 | Bug (source) | BC-BIZ-03 | Controller | `categories()` aggregates `AVG/MIN/MAX(score)`, not `numeric_score` | Source asserts | `test_category_summary_13_*` | ✅ |
| TC-N04 | Bug (data) | BC-DB-02 | Model | Seeded row has `numeric_score` set, `score` attribute null | Asserts pass | `test_category_summary_14_*` | ✅ |
| TC-N05 | Filter | BC-BIZ-03 | Controller | Period filter does not avoid the broken aggregate (still throws) | Throws | `test_category_summary_30_*` | ✅ |
| TC-N06 | Filter | BC-BIZ-03 | Route | Unknown `period_id` still reaches the bug | 500/404/302/0 | `test_category_summary_31_*` | ✅ |
| TC-N07 | Injection | BC-SEC-01 | Route | Garbage/injection-shaped params introduce no new error | documented set | `test_category_summary_32_*` | ✅ |
| TC-N08 | Auth | BC-AUTH-02 | Middleware | Guest redirected to `/login` | `/login` | `test_category_summary_50_*` | ✅ |
| TC-N09 | Auth | BC-AUTH-03 | Policy | Limited user → 403 (before the broken query) | 403 | `test_category_summary_51_*` | ✅ |
| TC-N10 | Bug (export) | BC-EDG-01 | Controller | Export route is a live 501 stub | 501 (skip if disabled) | `test_category_summary_70_*` | ✅ |

### Dependency / Security / Tenancy (TC-D / TC-S / TC-T)
| TC ID | Category (sub) | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------------|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | C (RESTRICT) | BC-REF-01 | DDL | `ba_computed_scores` FKs RESTRICT on delete | RESTRICT/NO ACTION | `test_category_summary_40_*` | ✅ |
| TC-D02 | E (cross-module) | BC-INT-01 | DDL | Report dependency tables exist (defensive) | present | `test_category_summary_41_*` | ✅ |
| TC-S01 | Policy | BC-AUTH-04 | Policy | Policy maps ability strings | present | `test_category_summary_52_*` | ✅ |
| TC-S02 | Gate divergence | BC-AUTH-05 | Controller/Policy | VAL-BA-003: export gates `reports.view` not `reports.export` | Source asserts | `test_category_summary_53_*` | ✅ |
| TC-S03 | XSS | BC-SEC-01 | Blade | Category name escaped `{{ }}`, not raw | Source asserts | `test_category_summary_93_*` | ✅ |
| TC-T01 | API deadness | BC-TEN-02 | Routes/RSP | DEAD-BA-001: api resource unregistered + no tenancy | Asserts pass | `test_category_summary_91_*` | ✅ |
| TC-T02 | Tenancy stack | BC-TEN-03 | RSP | Web routes carry tenancy stack | present | `test_category_summary_92_*` | ✅ |

### Requirement-vs-implementation gap cases (BC-EDG)
| TC ID | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----|--------|-------------|-----------------|-------------|--------|
| TC-G01 | BC-EDG-02 | Screen-17 | RPT-GAP-11: Class + Section filters not implemented | absent | `test_category_summary_71_*` | ✅ |
| TC-G02 | BC-EDG-03 | Screen-17 | RPT-GAP-12: requirement columns + PDF/CSV export not implemented | absent | `test_category_summary_72_*` | ✅ |
| TC-G03 | BC-EDG-04 | Screen-17/23 | DOC-BA-002: screens 17 & 23 share one implementation | shared route/view | `test_category_summary_73_*` | ✅ |

---

## 3. Known / Discovered Source Defects
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| BUG-BA-013 | **P1 (new)** | `categories()` (Category Summary) aggregates raw SQL `AVG(score)/MIN(score)/MAX(score)` on `ba_computed_scores`, which has no `score` column → SQL error → page HARD-500s | `_11`, `_12`, `_13`, `_14` |
| BUG-BA-011 | P2 (audit) | `reports/export` is a permanent `abort(501)` stub on a live route | `_70`, `_72` |
| DEAD-BA-001 | P2 (audit) | api `behaviouralassessments` resource: no tenancy middleware + never registered | `_91` |
| VAL-BA-003 | P3 | `export()` gates `reports.view` though Policy exposes `reports.export` | `_53` |
| DOC-BA-001 | P3 (audit) | DDL doc prefix `bha_` vs live `ba_` | `_02` |
| DOC-BA-002 | P3 (new) | Screens 17 & 23 collapse to one `categories()` implementation | `_73` |
| RPT-GAP-11 | P2 (new) | Class + Section filters unimplemented | `_71` |
| RPT-GAP-12 | P2 (new) | Requirement grid columns + PDF/CSV export unimplemented | `_72` |

---

## 4. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_category_summary_01_computed_scores_schema_and_model_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `test_category_summary_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` | TC-P02 | Config | 01–09 |
| 3 | `test_category_summary_03_report_controller_method_and_route_are_registered` | TC-P03 | Routing | 01–09 |
| 4 | `test_category_summary_04_categories_view_and_hub_link_exist` | TC-P04 | View | 01–09 |
| 5 | `test_category_summary_10_reports_hub_renders_for_authorized_admin` | TC-P05 | Render | 10–19 |
| 6 | `test_category_summary_11_category_aggregate_raw_sql_uses_nonexistent_score_column_bug_ba_013` | TC-N01 | Bug | 10–19 |
| 7 | `test_category_summary_12_category_summary_page_hard_500s_due_to_bug_ba_013` | TC-N02 | Bug | 10–19 |
| 8 | `test_category_summary_13_categories_controller_aggregates_on_score_not_numeric_score_bug_ba_013` | TC-N03 | Bug | 10–19 |
| 9 | `test_category_summary_14_seeded_score_has_numeric_score_but_no_score_attribute` | TC-N04 | Bug | 10–19 |
| 10 | `test_category_summary_15_student_report_correctly_reads_numeric_score_contrast` | TC-P06 | Contrast | 10–19 |
| 11 | `test_category_summary_16_criterion_performance_reads_rating_levels_numeric_value` | TC-P07 | Correctness | 10–19 |
| 12 | `test_category_summary_17_report_is_anonymized_no_student_identity_columns` | TC-P08 | Business rule | 10–19 |
| 13 | `test_category_summary_30_period_filter_does_not_change_the_bug_ba_013_outcome` | TC-N05 | Validation | 30–39 |
| 14 | `test_category_summary_31_unknown_period_filter_still_reaches_the_bug` | TC-N06 | Validation | 30–39 |
| 15 | `test_category_summary_32_garbage_query_params_do_not_introduce_a_new_error` | TC-N07 | Validation | 30–39 |
| 16 | `test_category_summary_40_computed_scores_fks_restrict_on_delete` | TC-D01 | FK | 40–49 |
| 17 | `test_category_summary_41_categories_report_dependency_tables_exist` | TC-D02/TC-P12 | Integration | 40–49 |
| 18 | `test_category_summary_50_guest_is_redirected_to_login` | TC-N08 | Auth | 50–59 |
| 19 | `test_category_summary_51_limited_user_gets_403_on_category_summary` | TC-N09 | Auth | 50–59 |
| 20 | `test_category_summary_52_policy_maps_to_permission_strings` | TC-S01 | Auth | 50–59 |
| 21 | `test_category_summary_53_export_gate_diverges_from_policy_val_ba_003` | TC-S02 | Auth | 50–59 |
| 22 | `test_category_summary_60_categories_view_declares_an_empty_state` | TC-P10 | UI/UX | 60–69 |
| 23 | `test_category_summary_61_categories_view_exposes_only_a_period_filter` | TC-P09 | UI/UX | 60–69 |
| 24 | `test_category_summary_62_reports_hub_card_links_to_category_report` | TC-P11 | UI/UX | 60–69 |
| 25 | `test_category_summary_70_export_is_live_abort_501_stub_bug_ba_011` | TC-N10 | Edge | 70–79 |
| 26 | `test_category_summary_71_requirement_class_and_section_filters_not_implemented_rpt_gap_11` | TC-G01 | Edge/gap | 70–79 |
| 27 | `test_category_summary_72_requirement_columns_and_export_not_implemented_rpt_gap_12` | TC-G02 | Edge/gap | 70–79 |
| 28 | `test_category_summary_73_screen_17_and_23_share_one_implementation_doc_ba_002` | TC-G03 | Edge/gap | 70–79 |
| 29 | `test_category_summary_90_tenant_context_is_initialized` | TC-P13 | Tenancy | 90–99 |
| 30 | `test_category_summary_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001` | TC-T01 | Tenancy/API | 90–99 |
| 31 | `test_category_summary_92_web_report_routes_carry_full_tenancy_stack` | TC-T02/TC-P14 | Tenancy | 90–99 |
| 32 | `test_category_summary_93_categories_view_escapes_output` | TC-S03 | Security | 90–99 |

**Total: 32 test methods.**
