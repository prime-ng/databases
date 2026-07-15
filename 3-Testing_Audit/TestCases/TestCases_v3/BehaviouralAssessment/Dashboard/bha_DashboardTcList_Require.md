# Behavioural Assessment — Dashboard — Test Case List & Business Conditions

**Module:** BehaviouralAssessment · **Feature/Screen:** Dashboard (`01-Dashboard.md`)
**Type:** Dashboard / read-only analytics · **Depth:** LIGHT (read-focused, no CRUD matrix)
**Route:** `GET /behavioural-assessment` → name `behavioural-assessment.dashboard`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaDashboardController::index()`
**Policy:** `BaDashboardPolicy` (`viewAny`, `view`) · **Permission:** `tenant.behavioural-assessment.dashboard.{viewAny|view}`
**FormRequest:** NONE (read-only) · **Activity log:** NONE (aggregate reads only)
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant)
**Test file:** `bha_Dashboard_TestCas.php` (single comprehensive suite, 37 methods)

> **PREFIX NOTE (DOC-BA-001):** live tables use the `ba_` prefix (migrations/models); only the stale DDL doc
> `BehaviouralAssess_DDL_v2.sql` uses `bha_`. The **filename** keeps `bha_`; every **assertion** targets `ba_` tables.

---

## 1. Business Conditions

### BC-DB — Schema / aggregate source truth
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-DB-01 | `ba_assessments`, `ba_assessment_ratings`, `ba_incidents`, `ba_assessment_periods`, `ba_computed_scores`, `ba_categories`, `ba_rating_levels` all exist | DDL-ba_* |
| BC-DB-02 | Live prefix is `ba_`; `bha_assessments` / `bha_incidents` do NOT exist at runtime | Audit-DOC-BA-001 |
| BC-DB-03 | `ba_incidents.incident_type` ENUM = `negative_incident,positive_reinforcement`; `severity` ENUM = `critical,major,minor,moderate` (nullable) | DDL-ba_incidents |
| BC-DB-04 | `ba_assessment_periods.status` ENUM = `open,locked,closed` | DDL-ba_assessment_periods |
| BC-DB-05 | `ba_computed_scores` has `period_id`, `category_id` (FK→`ba_categories`), `student_id` (FK→`std_students`), `numeric_score`, `grade` | DDL-ba_computed_scores |
| BC-DB-06 | `ba_categories` has `parent_id`, `is_active`, `sort_order`, `polarity`, `name` | DDL-ba_categories |

### BC-AUTH — Authorization
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-AUTH-01 | `index()` calls `Gate::authorize('tenant.behavioural-assessment.dashboard.viewAny')` | Controller:39 |
| BC-AUTH-02 | Guest (no session) is redirected to `/login` | RouteSP middleware `auth` |
| BC-AUTH-03 | Authenticated non-super-admin lacking `dashboard.viewAny` gets HTTP 403 | Policy + Constraint #31 |
| BC-AUTH-04 | `BaDashboardPolicy` declares `viewAny` and `view` → matching permission strings | Policy:11-19 |
| BC-AUTH-05 | Permitted admin receives HTTP 200 for the dashboard | Controller/route |

### BC-BIZ — Widget / aggregate behaviour
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-BIZ-01 | KPI "Total Assessments" = `BaAssessment::count()` | Controller:42 / Screen-BR |
| BC-BIZ-02 | KPI "Students Assessed" = distinct `student_id` in `ba_assessment_ratings` | Controller:43 |
| BC-BIZ-03 | KPI "Total Incidents" = `BaIncident::count()` | Controller:44 |
| BC-BIZ-04 | KPI "Open Periods" = periods where `status='open'` | Controller:45 |
| BC-BIZ-05 | Incident Trend aggregates last 6 months, split positive vs negative by `incident_type` | Controller:48-57 |
| BC-BIZ-06 | Category Average Scores use the **latest LOCKED period** (`status='locked'` ordered by `end_date` desc) | Controller:64-67 |
| BC-BIZ-07 | Rating Level Distribution = count of `ba_assessment_ratings` joined to `ba_rating_levels` | Controller:90-95 |
| BC-BIZ-08 | Recent Incidents = last 5 by `incident_date` desc | Controller:101-104 |
| BC-BIZ-09 | Students Needing Attention = bottom 5 `student_id` by avg `numeric_score` for the latest locked period | Controller:107-135 |
| BC-BIZ-10 | Quick Links render for Masters, Setup, Assessments, Incidents, Reports with correct route URLs | Blade:179-193 |
| BC-BIZ-11 | KPI values rendered via `number_format(...)` | Blade:9-12 |
| BC-BIZ-12 | Breadcrumb title = "Behavioural Assessment Dashboard" | Blade:3 |

### BC-SM — Period status scoping (state-dependent widget)
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-SM-01 | When a `locked` period exists, its `name` is surfaced under the Category Average Scores card | Blade:36-38 |
| BC-SM-02 | When NO locked period exists, category/bottom collections are empty and the page still renders | Controller:68/107 |
| BC-SM-03 | "Students Needing Attention" card is shown only when `bottomStudents` is non-empty (locked period WITH computed scores) | Blade:118 |

### BC-INT — Cross-module integration
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-INT-01 | Bottom-student names resolve from cross-module `std_students` (`first_name,last_name,admission_no`) | Controller:117-119 |
| BC-INT-02 | `ba_computed_scores.category_id` FK → `ba_categories` for category-name resolution | DDL / Controller:122 |
| BC-INT-03 | Incident seeding requires cross-module `std_students` + `sch_employees` rows | DDL-ba_incidents FKs |

### BC-EDG / BC-GAP — Edge cases & requirement divergences
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-EDG-01 | Dashboard renders with zero locked period / zero data without error | Controller |
| DASH-GAP-01 | Implemented KPIs differ from requirement ("Assessments Completed %", "Active Interventions" NOT implemented) | Screen §Key Widgets vs Blade |
| DASH-GAP-02 | No server-side filters; unexpected query params are ignored (no reflected injection) | Controller `index()` |
| DASH-GAP-03 | Role-based data scoping (Admin school-wide vs Teacher section-only) NOT implemented | Screen §Business Rules vs Controller |
| DASH-GAP-04 | `severity` ENUM allows `critical`, but Recent-Incidents blade maps only major/moderate/minor | DDL vs Blade:94-101 |

### BC-SEC / BC-T — Security & tenancy
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-T-01 | Tenant context initialized; aggregate tables resolve inside the current tenant DB | Constraint A |
| BC-T-02 | Cross-tenant isolation (defensive — second tenant required) | Constraint A |
| BC-SEC-01 | Stored XSS in `ba_incidents.description` is escaped everywhere it surfaces on the dashboard | Blade escaping |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Render | BC-BIZ-12 | Blade:3 | Dashboard renders with breadcrumb + KPI labels | Page shows title + 4 KPI labels | `test_dashboard_10_*` | ✅ |
| TC-P02 | KPI | BC-BIZ-01 | Controller:42 | Total Assessments KPI matches live count | `number_format(count)` visible | `test_dashboard_11_*` | ✅ |
| TC-P03 | KPI | BC-BIZ-03 | Controller:44 | Total Incidents KPI matches live count (seeded +1) | Formatted count visible | `test_dashboard_12_*` | ✅ |
| TC-P04 | KPI | BC-BIZ-04 | Controller:45 | Open Periods KPI matches open-status count | Formatted count visible | `test_dashboard_13_*` | ✅ |
| TC-P05 | KPI | BC-BIZ-02 | Controller:43 | Students Assessed KPI matches distinct rating students | Formatted count visible | `test_dashboard_14_*` | ✅ |
| TC-P06 | Widget | BC-BIZ-08 | Controller:101 | Seeded future-dated incident appears in Recent Incidents | Student surfaces in grid | `test_dashboard_15_*` | ✅ |
| TC-P07 | Widget | BC-BIZ-08 | Controller:101-104 | Recent incidents ordered desc + capped at 5 | Source has orderByDesc+limit(5) | `test_dashboard_16_*` | ✅ |
| TC-P08 | Chart | BC-BIZ-07 | Blade:53 | Rating distribution chart container present | `#chart-rating-distribution` in DOM | `test_dashboard_17_*` | ✅ |
| TC-P09 | Chart | BC-BIZ-06 | Blade:35 | Category scores chart container present | `#chart-category-scores` in DOM | `test_dashboard_18_*` | ✅ |
| TC-P10 | Chart | BC-BIZ-05 | Blade:23 | Incident trend chart container present | `#chart-incident-trend` in DOM | `test_dashboard_19_*` | ✅ |
| TC-P11 | SM | BC-SM-01 | Controller:64 | Category scores use latest LOCKED period; name surfaced | Locked period name visible | `test_dashboard_20_*` | ✅ |
| TC-P12 | SM | BC-BIZ-09 | Controller:107 | Bottom students derived from latest locked scores | Source asserts ordering+std_students+limit(5) | `test_dashboard_21_*` | ✅ |
| TC-P13 | Aggregate | BC-BIZ-05 | Controller:48 | Trend splits positive vs negative over 6 months | Source has both incident_type filters + subMonths(6) | `test_dashboard_40_*` | ✅ |
| TC-P14 | Perm | BC-AUTH-05 | Controller | Permitted admin gets 200 | Status 200 | `test_dashboard_53_*` | ✅ |
| TC-P15 | UI | BC-BIZ-10 | Blade:179 | Quick Links render with correct route URLs | 5 links + URLs present | `test_dashboard_60_*` | ✅ |
| TC-P16 | UI | BC-BIZ-08 | Blade:64 | "View All" link targets incidents page | URL present | `test_dashboard_61_*` | ✅ |
| TC-P17 | UI | BC-BIZ-11 | Blade:9-12 | KPI values are number_format-ed | Source asserts number_format | `test_dashboard_72_*` | ✅ |

### Negative / robustness (TC-N)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Auth | BC-AUTH-02 | Middleware | Guest redirected to login | Path contains `/login` | `test_dashboard_50_*` | ✅ |
| TC-N02 | Auth | BC-AUTH-03 | Policy | Limited user (no viewAny) gets 403 | Status 403 | `test_dashboard_51_*` | ✅ |
| TC-N03 | Input | DASH-GAP-02 | Controller | Junk query params ignored, no reflected script | Renders, no `<script>alert` | `test_dashboard_30_*` | ✅ |
| TC-N04 | Edge | BC-EDG-01 | Controller | Renders without locked period (no crash) | KPI row + Quick Links visible | `test_dashboard_70_*` | ✅ |
| TC-N05 | Empty | BC-BIZ-08 | Blade:67 | Empty incidents shows placeholder (data-conditional) | "No incidents recorded yet." | `test_dashboard_62_*` | ✅ |
| TC-N06 | Empty | BC-SM-03 | Blade:118 | Attention card hidden without locked scores | `assertDontSee` card | `test_dashboard_63_*` | ✅ |
| TC-SEC-01 | Security | BC-SEC-01 | Blade | Stored XSS in incident description escaped | Raw payload absent from DOM | `test_dashboard_93_*` | ✅ |

### Dependency / Integration (TC-D)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 (E) | Cross-module | BC-INT-02 | DDL | computed_score.category_id FK → ba_categories | FK metadata / column present | `test_dashboard_41_*` | ✅ |
| TC-D02 (E) | Cross-module | BC-INT-01 | Controller:117 | Bottom students join std_students (defensive) | std_students + columns present | `test_dashboard_42_*` | ✅ |

### Config / Schema truth (TC-C)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-C01 | Schema | BC-DB-01/03/04/05/06 | DDL | Aggregate tables + columns exist | All present | `test_dashboard_01_*` | ✅ |
| TC-C02 | Schema | BC-DB-02 | Audit | `ba_` live, `bha_` absent (DOC-BA-001) | bha_* absent | `test_dashboard_02_*` | ✅ |
| TC-C03 | Route | BC-AUTH-01 | Routes | Route registered + controller index + GET / uri | Route::has true | `test_dashboard_03_*` | ✅ |
| TC-C04 | Policy | BC-AUTH-04 | Policy | Policy maps viewAny/view to gate strings | Strings present | `test_dashboard_04_*` | ✅ |
| TC-C05 | Gate | BC-AUTH-01 | Controller | Controller enforces Gate::authorize string | String present | `test_dashboard_52_*` | ✅ |
| TC-C06 | Enum | BC-DB-04 | DDL | Period status ENUM valid set | open/locked/closed | `test_dashboard_22_*` | ✅ |

### Gap-proving (TC-G)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-G01 | Gap | DASH-GAP-03 | Screen vs Controller | No role-based scope branch in index() | `hasRole(` absent, school-wide count present | `test_dashboard_31_*` | ✅ |
| TC-G02 | Gap | DASH-GAP-04 | DDL vs Blade | severity `critical` unmapped in blade | critical absent from blade branches | `test_dashboard_71_*` | ✅ |
| TC-G03 | Gap | DASH-GAP-01 | Screen vs Blade | Implemented KPIs diverge from requirement | requirement KPIs absent | `test_dashboard_92_*` | ✅ |

### Tenancy (TC-T)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | BC-T-01 | Constraint A | Tenant context initialized | tenancy()->initialized true | `test_dashboard_90_*` | ✅ |
| TC-T02 | Tenancy | BC-T-02 | Constraint A | Cross-tenant isolation (defensive) | Skips if single tenant | `test_dashboard_91_*` | ✅ |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_dashboard_01_aggregate_source_tables_and_columns_exist` | TC-C01 | Schema | 01–09 |
| 2 | `test_dashboard_02_runtime_ba_prefix_diverges_from_ddl_spec_doc_ba_001` | TC-C02 | Schema | 01–09 |
| 3 | `test_dashboard_03_dashboard_route_is_registered_and_controller_has_index` | TC-C03 | Route | 01–09 |
| 4 | `test_dashboard_04_policy_maps_abilities_to_permission_strings` | TC-C04 | Policy | 01–09 |
| 5 | `test_dashboard_10_index_renders_with_breadcrumb_and_kpi_labels` | TC-P01 | Render | 10–19 |
| 6 | `test_dashboard_11_total_assessments_kpi_matches_ba_assessments_count` | TC-P02 | KPI | 10–19 |
| 7 | `test_dashboard_12_total_incidents_kpi_matches_ba_incidents_count` | TC-P03 | KPI | 10–19 |
| 8 | `test_dashboard_13_open_periods_kpi_matches_open_status_count` | TC-P04 | KPI | 10–19 |
| 9 | `test_dashboard_14_students_assessed_kpi_matches_distinct_rating_students` | TC-P05 | KPI | 10–19 |
| 10 | `test_dashboard_15_seeded_incident_appears_in_recent_incidents` | TC-P06 | Widget | 10–19 |
| 11 | `test_dashboard_16_recent_incidents_limited_to_five_ordered_desc` | TC-P07 | Widget | 10–19 |
| 12 | `test_dashboard_17_rating_distribution_chart_container_present` | TC-P08 | Chart | 10–19 |
| 13 | `test_dashboard_18_category_scores_chart_container_present` | TC-P09 | Chart | 10–19 |
| 14 | `test_dashboard_19_incident_trend_chart_container_present` | TC-P10 | Chart | 10–19 |
| 15 | `test_dashboard_20_category_scores_use_latest_locked_period` | TC-P11 | SM | 20–29 |
| 16 | `test_dashboard_21_students_needing_attention_from_latest_locked_period` | TC-P12 | SM | 20–29 |
| 17 | `test_dashboard_22_period_status_enum_values_are_valid` | TC-C06 | Enum | 20–29 |
| 18 | `test_dashboard_30_unexpected_query_params_are_ignored_no_server_filter_dash_gap_02` | TC-N03 | Input | 30–39 |
| 19 | `test_dashboard_31_no_role_based_scope_filter_implemented_dash_gap_03` | TC-G01 | Gap | 30–39 |
| 20 | `test_dashboard_40_incident_trend_splits_positive_and_negative` | TC-P13 | Aggregate | 40–49 |
| 21 | `test_dashboard_41_computed_score_category_relationship_resolves` | TC-D01 | Cross-module | 40–49 |
| 22 | `test_dashboard_42_bottom_students_join_std_students_defensive` | TC-D02 | Cross-module | 40–49 |
| 23 | `test_dashboard_50_guest_is_redirected_to_login` | TC-N01 | Auth | 50–59 |
| 24 | `test_dashboard_51_limited_user_without_view_permission_gets_403` | TC-N02 | Auth | 50–59 |
| 25 | `test_dashboard_52_controller_enforces_gate_authorize_string` | TC-C05 | Gate | 50–59 |
| 26 | `test_dashboard_53_admin_with_permission_can_view_dashboard` | TC-P14 | Perm | 50–59 |
| 27 | `test_dashboard_60_quick_links_render_with_correct_routes` | TC-P15 | UI | 60–69 |
| 28 | `test_dashboard_61_recent_incidents_view_all_links_to_incidents_page` | TC-P16 | UI | 60–69 |
| 29 | `test_dashboard_62_empty_recent_incidents_shows_placeholder_when_no_data` | TC-N05 | Empty | 60–69 |
| 30 | `test_dashboard_63_students_needing_attention_hidden_without_locked_scores` | TC-N06 | Empty | 60–69 |
| 31 | `test_dashboard_70_renders_without_locked_period_no_crash` | TC-N04 | Edge | 70–79 |
| 32 | `test_dashboard_71_severity_enum_has_critical_but_blade_maps_only_three_dash_gap_04` | TC-G02 | Gap | 70–79 |
| 33 | `test_dashboard_72_kpi_values_are_number_formatted` | TC-P17 | UI | 70–79 |
| 34 | `test_dashboard_90_tenant_context_is_initialized` | TC-T01 | Tenancy | 90–99 |
| 35 | `test_dashboard_91_cross_tenant_direct_isolation_defensive` | TC-T02 | Tenancy | 90–99 |
| 36 | `test_dashboard_92_implemented_kpis_diverge_from_requirement_dash_gap_01` | TC-G03 | Gap | 90–99 |
| 37 | `test_dashboard_93_stored_xss_in_incident_description_not_executed_on_dashboard` | TC-SEC-01 | Security | 90–99 |

---

## 4. Known Source Defects (audit-equivalent) touching this screen

| ID | Severity | Description | Proving method |
|----|----------|-------------|----------------|
| DOC-BA-001 | Doc | DDL doc prefix `bha_` diverges from live `ba_` | `test_dashboard_02_*` |
| DASH-GAP-01 | P3 (feature) | Implemented KPIs differ from the requirement's KPI set | `test_dashboard_92_*` |
| DASH-GAP-02 | P3 (feature) | No server-side filters on the dashboard | `test_dashboard_30_*` |
| DASH-GAP-03 | P2 (feature) | Requirement's role-based data scoping not implemented (school-wide for all viewers) | `test_dashboard_31_*` |
| DASH-GAP-04 | P3 (feature) | `severity='critical'` unmapped in Recent-Incidents blade (renders em-dash) | `test_dashboard_71_*` |
| PERF-BA-002 | P2 | Rating-map eager-loads criterion but not criterion.category (documented, not on index() path) | Gap Analysis |
