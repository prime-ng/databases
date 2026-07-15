# MarksheetGeneration — Dashboard & Navigation — Test Case List (TcList)

- **Module:** MarksheetGeneration (`MSH`)
- **Screen / Feature:** Dashboard & Navigation (composite / read-focused)
- **Prefix:** `msh_` — verified against DDL `CREATE TABLE msh_*` (composite screen; **owns no primary table**, aggregates the module's `msh_*` tables)
- **Screen file:** `MarksheetGeneration_V2/01-Dashboard-and-Navigation.md`
- **Controller:** `MarksheetGenerationController@dashboard|configuration|components|scheduling|results`
- **Test file:** `msh_Dashboard_TestCas.php` (class `msh_Dashboard_TestCas`, **one** file — no V1/V2 split)
- **DB scope:** tenant-side (`tenant_db`) → tenancy scaffolding required
- **Type:** Read-focused composite dashboard — **NO create/edit/delete matrix**

---

## 1. Business Conditions

### BC-DB — Aggregation tables (Source: `DDL-msh`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_marksheet_types` exists (Marksheet Types count) | DDL-msh_marksheet_types |
| BC-DB-02 | `msh_config_templates` exists (Config Templates count) | DDL-msh_config_templates |
| BC-DB-03 | `msh_marksheet_schedules` exists (Schedules count) | DDL-msh_marksheet_schedules |
| BC-DB-04 | `msh_student_results` exists (Student Results count) | DDL-msh_student_results |
| BC-DB-05 | `msh_schedule_class_jnt` exists (Schedule Classes count) | DDL-msh_schedule_class_jnt |
| BC-DB-06 | `msh_subject_practical_configs` exists (Practical Configs count) | DDL-msh_subject_practical_configs |
| BC-DB-07 | `msh_student_subject_results`, `msh_student_ia_marks`, `msh_student_coscholastic_results` exist (detail counts) | DDL-msh |
| BC-DB-08 | Models resolve to their DDL table names (e.g. `ScheduleClass` → `msh_schedule_class_jnt`) | Model + DDL |

### BC-BIZ — Aggregation & render rules (Source: `Screen-FR`, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `dashboard()` computes 12 stat counts (total + active for types/templates/schedules; totals for results/schedule-classes/practicals + 3 detail) | Controller L40-53; Screen-FR-01 |
| BC-BIZ-02 | Six primary stat widgets render: Marksheet Types, Config Templates, Schedules, Student Results, Schedule Classes, Practical Configs | dashboard.blade; Screen-FR-01 |
| BC-BIZ-03 | Each metric shows an "Active vs Inactive" breakdown row | dashboard.blade L42-89; Screen-FR-01 |
| BC-BIZ-04 | Recent Schedules capped at 5 (`->take(5)`), eager-loads `configTemplate` | Controller L55-58; Screen-FR-03 |
| BC-BIZ-05 | Recent Results capped at 5 (`->take(5)`), eager-loads `student, classSection.class, classSection.section` | Controller L60-63; Screen-FR-03 |
| BC-BIZ-06 | Three recent-activity tabs render: Overview, Recent Schedules, Recent Results; Overview active by default | dashboard.blade L92-117; Screen-FR-03 |
| BC-BIZ-07 | Module header + "Live" indicator + today-date badge render | dashboard.blade L11-30 |
| BC-BIZ-08 | Dashboard + 4 combined routes registered under `marksheet-generation.` prefix | web.php L33-41 |

### BC-AUTH — Permission gates (Source: `Screen-PM`, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `dashboard()` → `Gate::authorize('tenant.msh-dashboard.view')` | Controller L38 |
| BC-AUTH-02 | `configuration()` → `Gate::authorize('tenant.msh-configuration.view')` | Controller L70 |
| BC-AUTH-03 | `components()` → `Gate::authorize('tenant.msh-components.view')` | Controller L97 |
| BC-AUTH-04 | `scheduling()` → `Gate::authorize('tenant.msh-scheduling.view')` | Controller L121 |
| BC-AUTH-05 | `results()` → `Gate::authorize('tenant.msh-results.view')` | Controller L149 |
| BC-AUTH-06 | Guest is redirected to `/login` (auth + verified middleware) | web.php L30; RouteServiceProvider |
| BC-AUTH-07 | D39-MSH: msh gates are unseeded → super-admin only; a limited user is denied | Audit-D39-MSH |

### BC-INT — Cross-module integration (Source: `Screen-IP`, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Recent Results eager-loads cross-module `Student` (StudentProfile) + `ClassSection` (SchoolSetup) | Controller L60 |
| BC-INT-02 | 4-pillar navigation targets the four combined pages (Configuration/Components/Scheduling/Results) | dashboard.blade L118-155; Screen-FR-02 |

### BC-EDG — Edge / boundary (Source: Controller, Blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Recent Schedules empty-state: "No schedules created yet." | dashboard.blade L196-204 |
| BC-EDG-02 | Recent Results empty-state: "No results recorded yet." | dashboard.blade L239-247 |
| BC-EDG-03 | All aggregate counts are non-negative integers even on an empty tenant | Controller L40-53 |

### Known Source Defects (audit-owned; proving tests)
| ID | Sev | Description | Source | Proving method(s) |
|----|-----|-------------|--------|-------------------|
| BUG-MSH-001 | P0 | `routes/api.php` `apiResource('marksheetgenerations', ...)` is DEAD — `RouteServiceProvider::map()` maps only web routes AND the controller defines none of index/store/show/update/destroy | api.php L7; RouteServiceProvider L20-22; Controller | `test_..._58`, `test_..._59`, `test_..._72` |
| PERF-MSH-003 | P2 | `results()` eager-loads `Student::where('is_active',1)->get()` + `Subject::orderBy('name')->get()` with no pagination | Controller L241-242 | `test_..._46` |
| D39-MSH | P1 | `tenant.msh-*.view` gates unseeded → super-admin only (env prereq) | Audit-D39-MSH | `test_..._52..56` (denial), grant helper (positive determinism) |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Render | BC-BIZ-02 | Screen-FR-01 | Dashboard renders for admin | Header + path resolve | `test_dashboard_10` | ✅ |
| TC-P02 | Widgets | BC-BIZ-02 | Screen-FR-01 | Six stat cards render | 6 labels visible | `test_dashboard_11` | ✅ |
| TC-P03 | Aggregation | BC-BIZ-01 | Screen-FR-01 | Stat values match DB counts | Results count shown | `test_dashboard_12` | ✅ |
| TC-P04 | Breakdown | BC-BIZ-03 | Screen-FR-01 | Active/Inactive breakdown row | "Active"/"Inactive" present | `test_dashboard_13` | ✅ |
| TC-P05 | Tabs | BC-BIZ-06 | Screen-FR-03 | Three recent-activity tabs | Overview/Schedules/Results | `test_dashboard_14` | ✅ |
| TC-P06 | Nav | BC-INT-02 | Screen-FR-02 | 4-pillar links target combined routes | 4 hrefs present | `test_dashboard_40` | ✅ |
| TC-P07 | Nav | BC-BIZ-08 | Screen-FR-02 | Configuration combined resolves | Path resolves, not login | `test_dashboard_41` | ✅ |
| TC-P08 | Nav | BC-BIZ-08 | Screen-FR-02 | Components combined resolves | Path resolves | `test_dashboard_42` | ✅ |
| TC-P09 | Nav | BC-BIZ-08 | Screen-FR-02 | Scheduling combined resolves | Path resolves | `test_dashboard_43` | ✅ |
| TC-P10 | Nav | BC-BIZ-08 | Screen-FR-02 | Results combined resolves | Path resolves | `test_dashboard_44` | ✅ |
| TC-P11 | Tab data | BC-EDG-01 | Screen-FR-03 | Recent Schedules table/empty | Table or empty-state | `test_dashboard_62` | ✅ |
| TC-P12 | Tab data | BC-EDG-02 | Screen-FR-03 | Recent Results table/empty | Table or empty-state | `test_dashboard_63` | ✅ |
| TC-P13 | Header | BC-BIZ-07 | dashboard.blade | Date badge shows today | Current year shown | `test_dashboard_17` | ✅ |
| TC-P14 | Header | BC-BIZ-07 | dashboard.blade | Header + Live indicator | Both visible | `test_dashboard_18` | ✅ |
| TC-P15 | Cap | BC-BIZ-04 | Controller | Recent schedules ≤ 5 | `take(5)` in source | `test_dashboard_15` | ✅ |
| TC-P16 | Cap | BC-BIZ-05 | Controller | Recent results ≤ 5 + eager | eager-load in source | `test_dashboard_16` | ✅ |
| TC-P17 | UX | BC-BIZ-06 | dashboard.blade | Overview tab active by default | `#pane-overview.active` | `test_dashboard_61` | ✅ |
| TC-P18 | UX | BC-BIZ-07 | dashboard.blade | Breadcrumb renders | `ol.breadcrumb` + "Dashboard" | `test_dashboard_60` | ✅ |
| TC-P19 | UX | BC-INT-02 | dashboard.blade | Scheduling CTA present | `SCHEDULING_PATH` in source | `test_dashboard_64` | ✅ |
| TC-P20 | UX | BC-INT-02 | dashboard.blade | Results CTA present | `RESULTS_PATH` in source | `test_dashboard_65` | ✅ |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Guest | BC-AUTH-06 | web.php | Guest → login (dashboard) | Redirect to `/login` | `test_dashboard_50` | ✅ |
| TC-N02 | Guest | BC-AUTH-06 | web.php | Guest → login (4 combined pages) | Redirect each | `test_dashboard_51` | ✅ |
| TC-N03 | Perm | BC-AUTH-07 | Audit-D39 | Deny dashboard w/o permission | 403/denied | `test_dashboard_52` | ✅ |
| TC-N04 | Perm | BC-AUTH-07 | Audit-D39 | Deny configuration w/o permission | 403/denied | `test_dashboard_53` | ✅ |
| TC-N05 | Perm | BC-AUTH-07 | Audit-D39 | Deny components w/o permission | 403/denied | `test_dashboard_54` | ✅ |
| TC-N06 | Perm | BC-AUTH-07 | Audit-D39 | Deny scheduling w/o permission | 403/denied | `test_dashboard_55` | ✅ |
| TC-N07 | Perm | BC-AUTH-07 | Audit-D39 | Deny results w/o permission | 403/denied | `test_dashboard_56` | ✅ |
| TC-N08 | Dead API | BUG-MSH-001 | api.php | apiResource names not registered | `Route::has()===false` | `test_dashboard_58` | ✅ |
| TC-N09 | Dead API | BUG-MSH-001 | Controller | Controller lacks REST methods | `method_exists()===false` | `test_dashboard_59` | ✅ |
| TC-N10 | Dead API | BUG-MSH-001 | api.php | API probe returns dead status | status ∈ {401,403,404,405,500} | `test_dashboard_72` | ✅ |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected Result | Test Method | Status |
|-------|-----|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | — | BC-EDG-03 | Controller | Aggregate counts non-negative ints | 9 counts ≥ 0 | `test_dashboard_47` | ✅ |
| TC-D02 | E | BC-INT-01 | Controller | Recent results eager-load cross-module | relations loaded (defensive skip) | `test_dashboard_45` | ✅ |
| TC-D03 | E | PERF-MSH-003 | Controller | Results page unbounded load renders | source proof + page resolves | `test_dashboard_46` | ✅ |

### Tenancy / Security / Smoke (TC-T / TC-A / TC-RSP)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | BC-DB | DDL-msh | Counts scoped to current tenant | tenancy initialized, counts ≥ 0 | `test_dashboard_90` | ✅ |
| TC-A01 | Console | BC-BIZ-02 | dashboard.blade | No SEVERE console errors (dashboard) | empty severe log | `test_dashboard_91` | ✅ |
| TC-A02 | Console | BC-BIZ-08 | pages/* | No SEVERE console errors (combined) | empty severe log | `test_dashboard_93` | ✅ |
| TC-RSP01 | Responsive | BC-BIZ-02 | dashboard.blade | Dashboard renders at mobile viewport | header visible @390px | `test_dashboard_92` | ✅ |
| TC-EDG01 | Edge | BC-EDG-01 | dashboard.blade | Schedules empty-state/table branch | coherent branch | `test_dashboard_70` | ✅ |
| TC-EDG02 | Edge | BC-EDG-02 | dashboard.blade | Results empty-state/table branch | coherent branch | `test_dashboard_71` | ✅ |

---

## 3. Test Method Index (44 methods, one file)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_dashboard_01_routes_views_and_aggregation_wiring_are_correct` | BC-DB/BIZ/AUTH | Config truth | 01-09 |
| 2 | `test_dashboard_02_all_aggregated_msh_tables_exist` | BC-DB-01..07 | Schema | 01-09 |
| 3 | `test_dashboard_03_dashboard_and_combined_routes_registered` | BC-BIZ-08 | Wiring | 01-09 |
| 4 | `test_dashboard_04_dashboard_and_page_views_exist` | BC-DB-08 | Wiring | 01-09 |
| 5 | `test_dashboard_10_dashboard_renders_for_admin` | TC-P01 | Render | 10-19 |
| 6 | `test_dashboard_11_six_primary_stat_cards_render` | TC-P02 | Widgets | 10-19 |
| 7 | `test_dashboard_12_primary_stat_values_match_db_counts` | TC-P03 | Aggregation | 10-19 |
| 8 | `test_dashboard_13_secondary_active_inactive_breakdown_renders` | TC-P04 | Breakdown | 10-19 |
| 9 | `test_dashboard_14_three_recent_activity_tabs_present` | TC-P05 | Tabs | 10-19 |
| 10 | `test_dashboard_15_recent_schedules_limited_to_five` | TC-P15 | Cap | 10-19 |
| 11 | `test_dashboard_16_recent_results_limited_to_five` | TC-P16 | Cap | 10-19 |
| 12 | `test_dashboard_17_date_badge_shows_today` | TC-P13 | Header | 10-19 |
| 13 | `test_dashboard_18_module_header_and_live_indicator_render` | TC-P14 | Header | 10-19 |
| 14 | `test_dashboard_40_four_pillar_nav_links_target_combined_routes` | TC-P06 | Nav | 40-49 |
| 15 | `test_dashboard_41_configuration_combined_resolves` | TC-P07 | Nav | 40-49 |
| 16 | `test_dashboard_42_components_combined_resolves` | TC-P08 | Nav | 40-49 |
| 17 | `test_dashboard_43_scheduling_combined_resolves` | TC-P09 | Nav | 40-49 |
| 18 | `test_dashboard_44_results_combined_resolves` | TC-P10 | Nav | 40-49 |
| 19 | `test_dashboard_45_recent_results_eager_load_cross_module` | TC-D02 | Integration | 40-49 |
| 20 | `test_dashboard_46_results_page_unbounded_load_renders` | TC-D03 / PERF-MSH-003 | Integration/Perf | 40-49 |
| 21 | `test_dashboard_47_dashboard_counts_are_non_negative` | TC-D01 | Aggregation | 40-49 |
| 22 | `test_dashboard_50_guest_redirected_to_login_on_dashboard` | TC-N01 | Guest | 50-59 |
| 23 | `test_dashboard_51_guest_redirected_to_login_on_combined_pages` | TC-N02 | Guest | 50-59 |
| 24 | `test_dashboard_52_dashboard_gate_denies_user_without_permission` | TC-N03 | Perm | 50-59 |
| 25 | `test_dashboard_53_configuration_gate_denies_without_permission` | TC-N04 | Perm | 50-59 |
| 26 | `test_dashboard_54_components_gate_denies_without_permission` | TC-N05 | Perm | 50-59 |
| 27 | `test_dashboard_55_scheduling_gate_denies_without_permission` | TC-N06 | Perm | 50-59 |
| 28 | `test_dashboard_56_results_gate_denies_without_permission` | TC-N07 | Perm | 50-59 |
| 29 | `test_dashboard_57_gate_strings_present_in_controller` | BC-AUTH-01..05 | Perm | 50-59 |
| 30 | `test_dashboard_58_api_resource_routes_not_registered` | TC-N08 / BUG-MSH-001 | Dead API | 50-59 |
| 31 | `test_dashboard_59_controller_missing_rest_methods` | TC-N09 / BUG-MSH-001 | Dead API | 50-59 |
| 32 | `test_dashboard_60_breadcrumb_renders` | TC-P18 | UX | 60-69 |
| 33 | `test_dashboard_61_overview_tab_active_by_default` | TC-P17 | UX | 60-69 |
| 34 | `test_dashboard_62_recent_schedules_tab_table_or_empty` | TC-P11 | Tab data | 60-69 |
| 35 | `test_dashboard_63_recent_results_tab_table_or_empty` | TC-P12 | Tab data | 60-69 |
| 36 | `test_dashboard_64_view_all_schedules_link_targets_scheduling` | TC-P19 | UX | 60-69 |
| 37 | `test_dashboard_65_view_all_results_link_targets_results` | TC-P20 | UX | 60-69 |
| 38 | `test_dashboard_70_schedules_empty_state_branch` | TC-EDG01 | Edge | 70-79 |
| 39 | `test_dashboard_71_results_empty_state_branch` | TC-EDG02 | Edge | 70-79 |
| 40 | `test_dashboard_72_api_getjson_returns_dead_status` | TC-N10 / BUG-MSH-001 | Dead API | 70-79 |
| 41 | `test_dashboard_90_counts_scoped_to_current_tenant` | TC-T01 | Tenancy | 90-99 |
| 42 | `test_dashboard_91_no_severe_console_errors_on_dashboard` | TC-A01 | Console | 90-99 |
| 43 | `test_dashboard_92_dashboard_renders_at_mobile_viewport` | TC-RSP01 | Responsive | 90-99 |
| 44 | `test_dashboard_93_combined_pages_no_severe_console_errors` | TC-A02 | Console | 90-99 |
