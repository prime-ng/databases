# MarksheetGeneration — Dashboard & Navigation — Test Case List (Requirements)

**Module:** MarksheetGeneration &nbsp;·&nbsp; **Feature/Screen:** Dashboard & Navigation (composite / read-focused)
**Prefix:** `msh_` &nbsp;·&nbsp; **DB scope:** tenant-side (`msh_*`, `tenant_db`)
**Screen file:** `MarksheetGeneration_V2/01-Dashboard-and-Navigation.md`
**Controller:** `MarksheetGenerationController` (`dashboard`, `configuration`, `components`, `scheduling`, `results`)
**URL prefix:** `/marksheet-generation` &nbsp;·&nbsp; **Route name prefix:** `marksheet-generation.`
**Test style:** browser Dusk (`extends DuskTestCase`, `namespace Tests\Browser;`)
**Artifacts:** V1 = 17 methods · V2 = 44 methods (≥ 2× gate met)

> Read-focused screen: render / navigation / aggregation / permissions / empty-state / console / responsive. **No create/edit/delete matrix** — the dashboard is read-only and does not mutate `msh_*`.

---

## 1. Business Conditions

### BC-DB — Tables the dashboard aggregates (Source: `DDL-msh_*`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_marksheet_types` exists (MarksheetType::count) | DDL-msh_marksheet_types |
| BC-DB-02 | `msh_config_templates` exists (ConfigTemplate::count) | DDL-msh_config_templates |
| BC-DB-03 | `msh_marksheet_schedules` exists (MarksheetSchedule::count) | DDL-msh_marksheet_schedules |
| BC-DB-04 | `msh_student_results` exists (StudentResult::count) | DDL-msh_student_results |
| BC-DB-05 | `msh_schedule_class_jnt` exists (ScheduleClass::count) | DDL-msh_schedule_class_jnt |
| BC-DB-06 | `msh_subject_practical_configs` exists (SubjectPracticalConfig::count) | DDL-msh_subject_practical_configs |
| BC-DB-07 | `msh_student_subject_results` / `msh_student_ia_marks` / `msh_student_coscholastic_results` exist | DDL-msh_* |

### BC-AUTH — Permission gates (Source: Controller `Gate::authorize` + Screen-PM)
| ID | Condition | Gate string | Source |
|----|-----------|-------------|--------|
| BC-AUTH-01 | Dashboard requires the dashboard view gate | `tenant.msh-dashboard.view` | Controller:38 |
| BC-AUTH-02 | Configuration combined requires its gate | `tenant.msh-configuration.view` | Controller:70 |
| BC-AUTH-03 | Components combined requires its gate | `tenant.msh-components.view` | Controller:97 |
| BC-AUTH-04 | Scheduling combined requires its gate | `tenant.msh-scheduling.view` | Controller:121 |
| BC-AUTH-05 | Results combined requires its gate | `tenant.msh-results.view` | Controller:149 |
| BC-AUTH-06 | Guest is redirected to `/login` (auth+verified middleware) | RouteServiceProvider:33 | web.php:31 |
| BC-AUTH-07 | msh permissions are unseeded (super-admin-only) — must be granted | Audit-D39-MSH | Audit |

### BC-BIZ — Aggregation & recent activity (Source: Controller `dashboard()` + Screen-FR)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | 12 live counts computed (6 total + 3 active + 3 detail totals) | Controller:40-53 / Screen-FR-01 |
| BC-BIZ-02 | 6 primary stat cards render (Types, Templates, Schedules, Results, Schedule Classes, Practical Configs) | dashboard.blade:34-39 / Screen-FR-01 |
| BC-BIZ-03 | Active/Inactive breakdown shown for Types, Templates, Schedules | dashboard.blade:42-89 |
| BC-BIZ-04 | Recent Schedules = latest 5, with configTemplate | Controller:55-58 / Screen-FR-03 |
| BC-BIZ-05 | Recent Results = latest 5, eager-loads student + classSection.class/section | Controller:60-63 / Screen-FR-03 |
| BC-BIZ-06 | Three tabs: Overview / Recent Schedules / Recent Results | dashboard.blade:92-111 |
| BC-BIZ-07 | Today-date badge rendered | dashboard.blade:27 |

### BC-INT — Cross-module integration (Source: Controller + DDL FKs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Recent Results read StudentProfile `Student` (relation) | Controller:60 / DDL FK std_students |
| BC-INT-02 | Recent Results read SchoolSetup `ClassSection`→`SchoolClass`/`Section` | Controller:60 / DDL FK sch_* |
| BC-INT-03 | Combined pages read across LmsExam ExamType + SchoolSetup Subject/Class | Controller:83-133 |

### BC-EDG — Edge / empty-state (Source: dashboard.blade branches)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Zero schedules → "No schedules created yet." | dashboard.blade:196-204 |
| BC-EDG-02 | Zero results → "No results recorded yet." | dashboard.blade:239-247 |

### BC-UIX — Render / navigation / non-functional (Source: dashboard.blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-UIX-01 | Breadcrumb (Marksheet Generation → Dashboard) renders | dashboard.blade:3-6 |
| BC-UIX-02 | 4-pillar nav cards link to configuration/components/scheduling/results combined | dashboard.blade:120-153 |
| BC-UIX-03 | Overview pane active by default | dashboard.blade:117 |
| BC-UIX-04 | No SEVERE console errors on happy path | Enhanced dimension (a11y/console smoke) |
| BC-UIX-05 | Renders at mobile viewport | Enhanced dimension (responsive smoke) |

### Known Source Defects (audit-equivalent `BUG-MSH-###` / `Dxx`)
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| **BUG-MSH-001** | **P0** | `routes/api.php` declares `apiResource('marksheetgenerations', MarksheetGenerationController::class)` (index/store/show/update/destroy) but (a) the controller defines NONE of those methods and (b) `RouteServiceProvider::map()` only calls `mapWebRoutes()` — the module `api.php` is never loaded, so the routes are unregistered. API layer is dead. | V1 test_13; V2 test_58, test_59, test_72 |
| **PERF-MSH-003** | P2 | `results()` eager-loads `Student::where('is_active',1)->orderBy('id')->get()` and `Subject::orderBy('name')->get()` with **no pagination** (Controller:241-242) — unbounded. | V1 test_11; V2 test_46 |
| **D39-MSH** | P1 | MSH permissions unseeded → gates effectively super-admin-only (env prereq). Tests grant the 5 msh view gates explicitly to the admin. | V2 test_52–56 (denial) + grant helper |

---

## 2. Test Case List

### Positive (render / aggregation / navigation)
| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 |
|-------|----------|----|--------|-------------|-----------------|----|----|
| TC-P01 | Render | BC-BIZ-02, BC-UIX-01 | dashboard.blade | Dashboard renders for admin with breadcrumb | 200, module header + `ol.breadcrumb` visible | test_03 | test_10, test_60 |
| TC-P02 | Render | BC-BIZ-02 | dashboard.blade:34-39 | Six primary stat cards render | All 6 labels visible | test_04 | test_11 |
| TC-P03 | Aggregation | BC-BIZ-01 | Controller:40-53 | Stat values match live DB counts | Results total = `StudentResult::count()` | test_05 | test_12, test_47 |
| TC-P04 | Render | BC-BIZ-03 | dashboard.blade:42-89 | Active/Inactive breakdown renders | "Active"/"Inactive" shown | — | test_13 |
| TC-P05 | Render | BC-BIZ-06 | dashboard.blade:92-111 | Three recent-activity tabs present | Overview/Recent Schedules/Recent Results | test_06 | test_14 |
| TC-P06 | Navigation | BC-UIX-02 | dashboard.blade:120-153 | 4-pillar nav links target combined routes | 4 combined hrefs present | test_07 | test_40 |
| TC-P07 | Navigation | BC-AUTH-02 | web.php:39 | Configuration combined resolves | Path resolves, not login | test_08 | test_41 |
| TC-P08 | Navigation | BC-AUTH-03 | web.php:40 | Components combined resolves | Path resolves, not login | test_09 | test_42 |
| TC-P09 | Navigation | BC-AUTH-04 | web.php:41 | Scheduling combined resolves | Path resolves, not login | test_10 | test_43 |
| TC-P10 | Navigation | BC-AUTH-05 | web.php:42 | Results combined resolves | Path resolves, not login | test_11 | test_44, test_46 |
| TC-P11 | UX | BC-BIZ-04, BC-EDG-01 | dashboard.blade:158-205 | Recent Schedules tab shows table or empty state | One branch renders | test_14 | test_62, test_70 |
| TC-P12 | UX | BC-BIZ-05, BC-EDG-02 | dashboard.blade:207-248 | Recent Results tab shows table or empty state | One branch renders | test_15 | test_63, test_71 |
| TC-P13 | UX | BC-BIZ-07 | dashboard.blade:27 | Today-date badge renders | Current year visible | test_16 | test_17 |
| TC-P14 | Render | BC-BIZ-01 | dashboard.blade:13-24 | Module header + Live indicator render | Header + "Live" | — | test_18 |
| TC-P15 | UX | BC-UIX-03 | dashboard.blade:117 | Overview tab active by default | `#pane-overview.active` | — | test_61 |
| TC-P16 | Navigation | BC-UIX-02 | dashboard.blade:191-243 | View-all / empty CTAs target scheduling & results | CTAs present | — | test_64, test_65 |

### Negative / Auth / Dead-API
| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 |
|-------|----------|----|--------|-------------|-----------------|----|----|
| TC-N01 | Auth | BC-AUTH-06 | web.php:31 | Guest redirected to /login (dashboard) | Path contains `/login` | test_12 | test_50 |
| TC-N02 | Auth | BC-AUTH-06 | web.php:31 | Guest redirected on all 4 combined pages | Path contains `/login` | — | test_51 |
| TC-N03 | Auth | BC-AUTH-01, D39 | Controller:38 | User without dashboard gate denied | 403 / not dashboard | — | test_52 |
| TC-N04 | Auth | BC-AUTH-02, D39 | Controller:70 | User without config gate denied | 403 / not page | — | test_53 |
| TC-N05 | Auth | BC-AUTH-03, D39 | Controller:97 | User without components gate denied | 403 / not page | — | test_54 |
| TC-N06 | Auth | BC-AUTH-04, D39 | Controller:121 | User without scheduling gate denied | 403 / not page | — | test_55 |
| TC-N07 | Auth | BC-AUTH-05, D39 | Controller:149 | User without results gate denied | 403 / not page | — | test_56 |
| TC-N08 | Dead-API | BUG-MSH-001 | api.php:182 | API resource routes not registered | `Route::has('marksheetgeneration.*')` false | test_13 | test_58 |
| TC-N09 | Dead-API | BUG-MSH-001 | Controller | Controller missing REST methods | `method_exists(...)` false for all 5 | test_13 | test_59 |
| TC-N10 | Dead-API | BUG-MSH-001 | api.php | `GET /api/v1/marksheetgenerations` never 200 | status ∈ {401,404,405,500} | test_13 | test_72 |

### Dependency / Integration
| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 |
|-------|----------|----|--------|-------------|-----------------|----|----|
| TC-D01 | Integration (E) | BC-INT-01/02 | Controller:60 | Recent Results eager-load student + classSection | relations loaded (defensive) | — | test_45 |
| TC-D02 | Integration (E) | BC-BIZ-01 | Controller:40-53 | All aggregate counts non-negative ints | ≥ 0 for all 9 models | — | test_47 |
| TC-D03 | Perf (G) | PERF-MSH-003 | Controller:241-242 | Results page unbounded load still renders | source has `->get()`; page renders | test_11 | test_46 |

### Tenancy / Console / Responsive (enhanced)
| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 |
|-------|----------|----|--------|-------------|-----------------|----|----|
| TC-T01 | Tenancy | — | tenancy | Counts scoped to current tenant (smoke) | tenant initialized, counts ≥ 0 | — | test_90 |
| TC-A01 | Console | BC-UIX-04 | Dusk log | No SEVERE console errors (dashboard) | empty severe log | test_17 | test_91 |
| TC-A02 | Console | BC-UIX-04 | Dusk log | No SEVERE console errors (combined) | empty severe log | — | test_93 |
| TC-RSP01 | Responsive | BC-UIX-05 | viewport | Dashboard renders at 390×844 | header visible | — | test_92 |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_dashboard_01_routes_views_and_aggregation_wiring_are_correct | BC-DB/BIZ/AUTH | Wiring | 01-09 |
| 2 | test_dashboard_02_all_aggregated_msh_tables_exist | BC-DB-01..07 | Wiring | 01-09 |
| 3 | test_dashboard_03_dashboard_and_combined_routes_registered | BC-BIZ | Wiring | 01-09 |
| 4 | test_dashboard_04_dashboard_and_page_views_exist | BC-DB | Wiring | 01-09 |
| 5 | test_dashboard_10_dashboard_renders_for_admin | TC-P01 | Render | 10-19 |
| 6 | test_dashboard_11_six_primary_stat_cards_render | TC-P02 | Render | 10-19 |
| 7 | test_dashboard_12_primary_stat_values_match_db_counts | TC-P03 | Aggregation | 10-19 |
| 8 | test_dashboard_13_secondary_active_inactive_breakdown_renders | TC-P04 | Render | 10-19 |
| 9 | test_dashboard_14_three_recent_activity_tabs_present | TC-P05 | Render | 10-19 |
| 10 | test_dashboard_15_recent_schedules_limited_to_five | BC-BIZ-04 | Business | 10-19 |
| 11 | test_dashboard_16_recent_results_limited_to_five | BC-BIZ-05 | Business | 10-19 |
| 12 | test_dashboard_17_date_badge_shows_today | TC-P13 | Render | 10-19 |
| 13 | test_dashboard_18_module_header_and_live_indicator_render | TC-P14 | Render | 10-19 |
| 14 | test_dashboard_40_four_pillar_nav_links_target_combined_routes | TC-P06 | Navigation | 40-49 |
| 15 | test_dashboard_41_configuration_combined_resolves | TC-P07 | Navigation | 40-49 |
| 16 | test_dashboard_42_components_combined_resolves | TC-P08 | Navigation | 40-49 |
| 17 | test_dashboard_43_scheduling_combined_resolves | TC-P09 | Navigation | 40-49 |
| 18 | test_dashboard_44_results_combined_resolves | TC-P10 | Navigation | 40-49 |
| 19 | test_dashboard_45_recent_results_eager_load_cross_module | TC-D01 | Integration | 40-49 |
| 20 | test_dashboard_46_results_page_unbounded_load_renders | TC-D03 / PERF-MSH-003 | Perf | 40-49 |
| 21 | test_dashboard_47_dashboard_counts_are_non_negative | TC-D02 | Integration | 40-49 |
| 22 | test_dashboard_50_guest_redirected_to_login_on_dashboard | TC-N01 | Auth | 50-59 |
| 23 | test_dashboard_51_guest_redirected_to_login_on_combined_pages | TC-N02 | Auth | 50-59 |
| 24 | test_dashboard_52_dashboard_gate_denies_user_without_permission | TC-N03 / D39 | Auth | 50-59 |
| 25 | test_dashboard_53_configuration_gate_denies_without_permission | TC-N04 / D39 | Auth | 50-59 |
| 26 | test_dashboard_54_components_gate_denies_without_permission | TC-N05 / D39 | Auth | 50-59 |
| 27 | test_dashboard_55_scheduling_gate_denies_without_permission | TC-N06 / D39 | Auth | 50-59 |
| 28 | test_dashboard_56_results_gate_denies_without_permission | TC-N07 / D39 | Auth | 50-59 |
| 29 | test_dashboard_57_gate_strings_present_in_controller | BC-AUTH-01..05 | Auth | 50-59 |
| 30 | test_dashboard_58_api_resource_routes_not_registered | TC-N08 / BUG-MSH-001 | Dead-API | 50-59 |
| 31 | test_dashboard_59_controller_missing_rest_methods | TC-N09 / BUG-MSH-001 | Dead-API | 50-59 |
| 32 | test_dashboard_60_breadcrumb_renders | TC-P01 | UI/UX | 60-69 |
| 33 | test_dashboard_61_overview_tab_active_by_default | TC-P15 | UI/UX | 60-69 |
| 34 | test_dashboard_62_recent_schedules_tab_table_or_empty | TC-P11 | UI/UX | 60-69 |
| 35 | test_dashboard_63_recent_results_tab_table_or_empty | TC-P12 | UI/UX | 60-69 |
| 36 | test_dashboard_64_view_all_schedules_link_targets_scheduling | TC-P16 | UI/UX | 60-69 |
| 37 | test_dashboard_65_view_all_results_link_targets_results | TC-P16 | UI/UX | 60-69 |
| 38 | test_dashboard_70_schedules_empty_state_branch | TC-P11 / BC-EDG-01 | Edge | 70-79 |
| 39 | test_dashboard_71_results_empty_state_branch | TC-P12 / BC-EDG-02 | Edge | 70-79 |
| 40 | test_dashboard_72_api_getjson_returns_dead_status | TC-N10 / BUG-MSH-001 | Edge/Dead-API | 70-79 |
| 41 | test_dashboard_90_counts_scoped_to_current_tenant | TC-T01 | Tenancy | 90-99 |
| 42 | test_dashboard_91_no_severe_console_errors_on_dashboard | TC-A01 | Console | 90-99 |
| 43 | test_dashboard_92_dashboard_renders_at_mobile_viewport | TC-RSP01 | Responsive | 90-99 |
| 44 | test_dashboard_93_combined_pages_no_severe_console_errors | TC-A02 | Console | 90-99 |

**V1 = 17 methods · V2 = 44 methods · ratio = 2.59× (≥ 2× gate PASS).**
