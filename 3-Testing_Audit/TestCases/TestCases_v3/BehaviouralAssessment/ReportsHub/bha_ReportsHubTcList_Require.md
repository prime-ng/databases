# Reports Hub — Test Case List & Business Conditions (`bha_ReportsHub`)

**Module:** BehaviouralAssessment  **Feature/Screen:** ReportsHub (Reports landing hub)
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/15-Reports-Hub.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController`
**Index route:** `behavioural-assessment.reports.index` → `GET /behavioural-assessment/reports`
**View:** `behaviouralassessment::reports.index` (breadcrumb title **"Reports"**)
**Screen type:** REPORT / navigation hub — **LIGHT depth** (render + links + permission gating + empty-state; NOT a CRUD matrix)
**DB scope:** TENANT-side (tenant_db) → tenancy scaffolding required
**Prefix note:** filename prefix `bha_`; **live tables asserted are `ba_`** (`ba_assessments`, `ba_assessment_periods`, `ba_incidents`, `ba_assessment_ratings`, `ba_computed_scores`) — DDL doc uses stale `bha_` (DOC-BA-001).

---

## 1. Business Conditions

### BC-DB (schema — live `ba_` tables the hub aggregates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_assessments` exists (Total Assessments + workflow status counts) | DDL-ba_assessments |
| BC-DB-02 | `ba_assessment_periods` exists with `status` column (Open Periods, Recent Periods) | DDL-ba_assessment_periods |
| BC-DB-03 | `ba_incidents` exists with `incident_date`,`incident_type` (Total Incidents, Incident Trend) | DDL-ba_incidents |
| BC-DB-04 | `ba_assessment_ratings` exists (Students Rated distinct count) | DDL-ba_assessment_ratings |
| BC-DB-05 | `ba_computed_scores` exists (data source for downstream reports) | DDL-ba_computed_scores |
| BC-DB-06 | Live runtime prefix is `ba_`, not the DDL-doc `bha_` | Audit-DOC-BA-001 |

### BC-AUTH (permission gates ↔ controller methods)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` authorizes `tenant.behavioural-assessment.reports.viewAny` | BaReportController:29 |
| BC-AUTH-02 | `student()/byClass()/period()/categories()/incidents()/export()` authorize `tenant.behavioural-assessment.reports.view` | BaReportController:68,147,237,346,417,478 |
| BC-AUTH-03 | `BaReportPolicy` maps viewAny/view/export → the three `reports.*` permission strings | BaReportPolicy:13,18,23 |
| BC-AUTH-04 | Guest (unauthenticated) is redirected to `/login` (web+auth middleware group) | RouteServiceProvider:24-31 |
| BC-AUTH-05 | Legacy `reports-page` target authorizes `tenant.behavioural-assessment.reports-page.viewAny` | BaDashboardController:479 |

### BC-BIZ (hub render composition)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Hub renders breadcrumb "Reports" + "Available Reports" section | reports/index.blade.php:3,81 |
| BC-BIZ-02 | Four summary stat cards render: Total Assessments, Students Rated, Total Incidents, Open Periods | index.blade.php:17-67 |
| BC-BIZ-03 | Sidebar renders: Assessment Workflow Status, Incident Trend, Recent Assessment Periods | index.blade.php:236,260,291 |
| BC-BIZ-04 | Report cards link to incidents, categories, period, reports-page | index.blade.php:117,140,103,207 |
| BC-BIZ-05 | Incident Trend shows empty-state "No incident data for this period." when trend is empty | index.blade.php:262-263 |

### BC-INT (integration — links to the 9 report screens the hub fronts)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Hub links to `reports.incidents`; target renders "Incident Report" | index.blade.php:117 / incidents.blade.php:3 |
| BC-INT-02 | Hub links to `reports.categories`; target renders "Category Performance" | index.blade.php:140 / categories.blade.php:3 |
| BC-INT-03 | Hub links to `reports.period/{id}`; target renders "Teacher Progress Report" (when period exists) | index.blade.php:103,304 / period.blade.php:3 |
| BC-INT-04 | Hub links to `reports-page` (legacy Data Tables & Audit Trail) + `reports-page?tab=student-scores` | index.blade.php:171,194,207 |
| BC-INT-05 | Parameterised `reports.student` / `reports.class` routes are registered targets | web.php:106,107 |

### BC-EDG (edge / boundary)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Missing-id student/class/period reports return 404 (`findOrFail`) | BaReportController:69,148,347 |
| BC-EDG-02 | `reports.export` never returns a success status (always aborts 501) | BaReportController:476-480 |

### BC-CFG (requirement-vs-implementation configuration gaps)
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | HUB-GAP-01/03: requirement filter panel (Session/Period/Class/Section/Format radio/Generate Preview/Export Report/async-queue banner) is ABSENT | Screen-§KeyFields, Screen-§BusinessRules vs index.blade.php |
| BC-CFG-02 | HUB-GAP-02: requirement "Data last synced" freshness label is ABSENT | Screen-§DataFreshness vs index.blade.php |

### BC-SEC (security)
| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-01 | Reflected filter input (query params) is escaped by Blade (no reflected XSS) | incidents.blade.php |

### Known Source Defects (audit-equivalent `BUG-BA` / `DEAD-BA`)
| ID | Defect | Source |
|----|--------|--------|
| BUG-BA-011 | `reports.export` is a live `abort(501,'Export feature coming soon.')` stub — no CSV/Excel export engine despite the requirement making it a core feature | BaReportController:476-480 |
| DEAD-BA-001 | Module `routes/api.php` apiResource (`behaviouralassessments`) has **no tenancy middleware** (only `auth:sanctum`) AND is not registered by `RouteServiceProvider::map()` (web-only) → dead route | routes/api.php:6-8 / RouteServiceProvider:22-35 |
| DOC-BA-001 | DDL doc prefix `bha_` diverges from live `ba_` | Audit-DOC-BA-001 |

---

## 2. Test Case List

### Positive (render / links / integration)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB-01..05, BC-AUTH-01/02 | DDL/Controller | Backing tables + report routes + gate strings correct | 5 tables exist, 8 routes registered, gates present | `_01` | Automated |
| TC-P02 | Config | BC-DB-06 | Audit-DOC-BA-001 | Runtime prefix `ba_` not `bha_` | ba_ exists, bha_ absent | `_02` | Automated |
| TC-P03 | Render | BC-BIZ-01 | Screen | Hub renders with "Reports" breadcrumb | breadcrumb + "Available Reports" seen | `_10` | Automated |
| TC-P04 | Render | BC-BIZ-02 | Screen | Four summary stat cards present | all four labels seen | `_11` | Automated |
| TC-P05 | Render | BC-BIZ-03 | Screen | Sidebar status/trend/recent periods render | three headers seen | `_12` | Automated |
| TC-P06 | Render | BC-BIZ-04 | Screen | Available Reports cards render | incidents+categories cards seen | `_13` | Automated |
| TC-P07 | Link | BC-INT-01 | Screen-IP-1 | Incident report link present + target authorized | link in source, target shows "Incident Report" | `_40` | Automated |
| TC-P08 | Link | BC-INT-02 | Screen-IP-2 | Category report link present + target authorized | link in source, target shows "Category Performance" | `_41` | Automated |
| TC-P09 | Link | BC-INT-03 | Screen-IP-3 | Period report target renders when period exists | link present, target shows "Teacher Progress Report" | `_42` | Automated |
| TC-P10 | Link | BC-INT-04, BC-AUTH-05 | Screen-IP-4 | reports-page legacy link present + target renders | link in source, target 200/302 | `_43` | Automated |
| TC-P11 | Link | BC-INT-05 | Screen-IP-5 | student/class report routes registered + student-scores tab exposed | routes registered, tab entry present | `_44` | Automated |
| TC-P12 | UI | BC-BIZ-05 | Screen | Incident Trend section + empty-state correct | header + (empty msg OR trend table) | `_60` | Automated |
| TC-P13 | UI | BC-BIZ-01 | Screen | Breadcrumbs present on linked sub-reports | Incident Report + Category Performance seen | `_61` | Automated |
| TC-P14 | Tenancy | BC-DB-01..03 | 05-A4 | Tenant context initialized + tables resolve | tenancy()->initialized true | `_90` | Automated |

### Negative (permissions / edge / defects)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Auth | BC-AUTH-04 | Route | Guest redirected to login | path contains `/login` | `_50` | Automated |
| TC-N02 | Auth | BC-AUTH-01 | Controller:29 | Limited user (no reports.viewAny) → 403 on hub | 403 | `_51` | Automated |
| TC-N03 | Auth | BC-AUTH-02 | Controller:237 | Limited user (no reports.view) → 403 on incidents report | 403 | `_52` | Automated |
| TC-N04 | Auth | BC-AUTH-03 | BaReportPolicy | Policy methods map to permission strings | 3 strings present | `_53` | Automated |
| TC-N05 | Auth | BC-AUTH-02 | Controller:478 | Limited user gated (403) before export 501 | 403 (not 501) | `_54` | Automated |
| TC-N06 | Edge | BC-EDG-01 | Controller | Missing id → 404 on student/class/period | 404 x3 | `_70` | Automated |
| TC-N07 | Edge | BC-EDG-02 / BUG-BA-011 | Controller:476 | Export never returns success | ≥500, exactly 501 | `_71` | Automated |
| TC-N08 | Defect | BUG-BA-011 | Controller:476 | Export is a live 501 stub | 501 | `_45` | Automated |
| TC-N09 | Defect | DEAD-BA-001 | api.php/RSP | API apiResource unregistered + no tenancy middleware | Route::has false; no `InitializeTenancyByDomain` | `_46` | Automated |
| TC-N10 | Gap | BC-CFG-01 | Screen vs impl | Requirement filter panel + export controls absent | no Generate Preview/Export Report/Format radio | `_80` | Automated |
| TC-N11 | Gap | BC-CFG-02 | Screen vs impl | "Data last synced" label absent | not present | `_81` | Automated |
| TC-N12 | Security | BC-SEC-01 | incidents.blade | Reflected filter input escaped | raw `<script>` absent | `_92` | Automated |

### Dependency / Tenancy
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | Tenancy-E | BC-DB | 05-A4 | Cross-tenant direct-id isolation (defensive) | second tenant present or skip | `_91` | Automated |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_reports_hub_01_backing_schema_and_route_configuration_are_correct` | TC-P01 | Config | 01–09 |
| 2 | `test_reports_hub_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | TC-P02 | Config | 01–09 |
| 3 | `test_reports_hub_10_index_renders_with_reports_breadcrumb` | TC-P03 | Render | 10–19 |
| 4 | `test_reports_hub_11_summary_stat_cards_are_present` | TC-P04 | Render | 10–19 |
| 5 | `test_reports_hub_12_sidebar_status_trend_and_recent_periods_render` | TC-P05 | Render | 10–19 |
| 6 | `test_reports_hub_13_available_reports_section_lists_report_cards` | TC-P06 | Render | 10–19 |
| 7 | `test_reports_hub_40_incident_report_link_present_and_target_authorized` | TC-P07 | Link | 40–49 |
| 8 | `test_reports_hub_41_category_report_link_present_and_target_authorized` | TC-P08 | Link | 40–49 |
| 9 | `test_reports_hub_42_period_report_target_renders_when_period_exists` | TC-P09 | Link | 40–49 |
| 10 | `test_reports_hub_43_reports_page_legacy_link_present_and_target_renders` | TC-P10 | Link | 40–49 |
| 11 | `test_reports_hub_44_student_and_class_report_routes_are_registered` | TC-P11 | Link | 40–49 |
| 12 | `test_reports_hub_45_export_route_is_a_live_501_stub_bug_ba_011` | TC-N08 | Defect | 40–49 |
| 13 | `test_reports_hub_46_api_resource_route_lacks_tenancy_and_is_dead_dead_ba_001` | TC-N09 | Defect | 40–49 |
| 14 | `test_reports_hub_50_guest_is_redirected_to_login` | TC-N01 | Auth | 50–59 |
| 15 | `test_reports_hub_51_limited_user_without_reports_viewany_gets_403_on_hub` | TC-N02 | Auth | 50–59 |
| 16 | `test_reports_hub_52_limited_user_without_reports_view_gets_403_on_incidents` | TC-N03 | Auth | 50–59 |
| 17 | `test_reports_hub_53_report_policy_methods_map_to_permission_strings` | TC-N04 | Auth | 50–59 |
| 18 | `test_reports_hub_54_export_gate_enforced_for_limited_user` | TC-N05 | Auth | 50–59 |
| 19 | `test_reports_hub_60_incident_trend_section_and_empty_state_are_correct` | TC-P12 | UI | 60–69 |
| 20 | `test_reports_hub_61_breadcrumb_present_on_linked_sub_reports` | TC-P13 | UI | 60–69 |
| 21 | `test_reports_hub_70_invalid_ids_return_404_on_parameterised_reports` | TC-N06 | Edge | 70–79 |
| 22 | `test_reports_hub_71_export_never_returns_a_success_status` | TC-N07 | Edge | 70–79 |
| 23 | `test_reports_hub_80_requirement_filter_panel_and_export_controls_absent_hub_gap_01` | TC-N10 | Gap | 80–89 |
| 24 | `test_reports_hub_81_data_last_synced_timestamp_absent_hub_gap_02` | TC-N11 | Gap | 80–89 |
| 25 | `test_reports_hub_90_tenant_context_is_initialized_and_backing_tables_resolve` | TC-P14 | Tenancy | 90–99 |
| 26 | `test_reports_hub_91_cross_tenant_direct_id_isolation` | TC-D01 | Tenancy | 90–99 |
| 27 | `test_reports_hub_92_reflected_input_in_report_filters_is_escaped` | TC-N12 | Security | 90–99 |

**Total: 27 methods** (light read-focused report screen).
