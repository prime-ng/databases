# Incident Report — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (`bha_` file prefix / **live `ba_` tables** — DOC-BA-001)
**Feature / Screen:** IncidentReport (screen file `24-Incident-Report.md`)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaReportController::incidents()`
**Route:** `behavioural-assessment.reports.incidents` → `GET /behavioural-assessment/reports/incidents`
**View:** `behaviouralassessment::reports.incidents`
**Primary table:** `ba_incidents` (+ `ba_incident_intervention_jnt`, `ba_interventions`, `ba_incident_witnesses_jnt`, `ba_categories`)
**Screen type:** Report / dashboard — **LIGHT** read-focused set (render, aggregate correctness, filters, export, permissions, empty-state, tenancy). NOT a CRUD matrix.
**DB scope:** TENANT-side (`tenant_db`) → tenancy scaffolding required.
**Permission:** `tenant.behavioural-assessment.reports.view` (incidents gate); `...reports.viewAny` (hub shell).
**Activity log:** NONE (read-only report — documented absence).
**Pagination:** Incident Log = `paginate(25)` (NOT the platform default 10).
**Test file:** `bha_IncidentReport_TestCas.php` — single comprehensive suite, 38 methods.

---

## 1. Business Conditions

### BC-DB — Schema truth (Source: DDL-ba_incidents / migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_incidents` exists with student_id, reported_by, category_id, criterion_id, incident_date, incident_time, incident_type, severity, description, location, intervention_notes, is_follow_up_required, follow_up_date, follow_up_notes, is_notified, is_active, created_by, updated_by, timestamps, deleted_at | DDL-ba_incidents |
| BC-DB-02 | `incident_type` ENUM = `positive_reinforcement`,`negative_incident` (verbatim) | DDL-ba_incidents |
| BC-DB-03 | `severity` ENUM = `minor`,`moderate`,`major`,`critical` (NULL for positive) | DDL-ba_incidents |
| BC-DB-04 | `location` ENUM = classroom/playground/corridor/lab/transport/canteen/library/other | DDL-ba_incidents |
| BC-DB-05 | `BaIncident` uses `SoftDeletes`; table = `ba_incidents`; relations student/reportedBy/category (BelongsTo), witnesses (HasMany), interventions (BelongsToMany) | Model |
| BC-DB-06 | `ba_incident_intervention_jnt` (id, incident_id, intervention_id, notes) + `ba_interventions` (id, name, intervention_type) exist | DDL |
| BC-DB-07 | `ba_incident_witnesses_jnt` exists (witness linkage) | DDL |

### BC-REF — Referential integrity (Source: DDL FKs)
| ID | FK → referenced | onDelete | Source |
|----|-----------------|----------|--------|
| BC-REF-01 | ba_incidents.student_id → std_students | RESTRICT | DDL-ba_incidents |
| BC-REF-02 | ba_incidents.reported_by → sch_employees | RESTRICT | DDL-ba_incidents |
| BC-REF-03 | ba_incidents.category_id → ba_categories | SET NULL | DDL-ba_incidents |
| BC-REF-04 | ba_incidents.criterion_id → ba_criteria | SET NULL | DDL-ba_incidents |
| BC-REF-05 | ba_incident_intervention_jnt.incident_id → ba_incidents | CASCADE | DDL |
| BC-REF-06 | ba_incident_intervention_jnt.intervention_id → ba_interventions | RESTRICT | DDL |
| BC-REF-07 | ba_incident_witnesses_jnt.incident_id → ba_incidents | CASCADE | DDL |

### BC-AUTH — Permissions (Source: BaReportPolicy + controller gate + Screen-PM)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `incidents()` calls `Gate::authorize('tenant.behavioural-assessment.reports.view')` | Controller |
| BC-AUTH-02 | Guest (no session) → redirect to `/login` | RSP `auth` middleware |
| BC-AUTH-03 | Authenticated non-super-admin without permission → 403 | Gate + constraint #31 |
| BC-AUTH-04 | Policy declares viewAny/view/export → `tenant.behavioural-assessment.reports.{ability}` | BaReportPolicy |
| BC-AUTH-05 | Web route carries InitializeTenancyByDomain + PreventAccessFromCentralDomains + auth + verified | RouteServiceProvider |

### BC-BIZ — Render & data correctness (Source: controller `incidents()` + blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Report renders for authorized admin without 500 | Controller/View |
| BC-BIZ-02 | Executive KPI cards: Total Incidents, Positive Reinforcements, Negative Incidents, Follow-ups Pending | View |
| BC-BIZ-03 | `negativeCount = totalCount - positiveCount` (derived invariant, never a separate query) | Controller |
| BC-BIZ-04 | Analytics widgets render: Type/Severity breakdown, Location Analysis, Incidents by Category, Intervention Usage | View |
| BC-BIZ-05 | Intervention Usage = `DB::table('ba_incident_intervention_jnt')` JOIN ba_interventions JOIN ba_incidents | Controller |
| BC-BIZ-06 | Seeded positive + negative incidents (dated today) surface in the log + record count | Controller/View |
| BC-BIZ-07 | 6-Month Trend + follow-up tracker render when data present | View |

### BC-VAL — Filter handling (Source: controller filter block)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Real filters = incident_type, severity, from_date (def startOfMonth), to_date (def today), category_id | Controller |
| BC-VAL-02 | Unknown category_id → empty result set, no 500 | Controller |
| BC-VAL-03 | Valid severity / incident_type filters render | Controller |
| BC-VAL-04 | Malformed date filter — documents behaviour (graceful or 500 recorded) | Controller |

### BC-EDG — Edge cases & requirement-vs-implementation gaps
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Empty state message `No incidents found for the selected filters.` on a no-result window | View |
| BC-EDG-02 | Incident Log paginates 25/page and preserves the query string (`withQueryString()->links()`) | Controller/View |
| BC-EDG-03 | BUG-BA-011: `reports.export` = `abort(501,'Export feature coming soon.')` | Controller |
| BC-EDG-04 | BUG-BA-013 NOT APPLICABLE — incidents() reads no computed_scores/`score` column | Controller |
| BC-EDG-05 | RPT-GAP-INC-01: Class&Section + Student filters (Screen-24) unimplemented | Screen-24 vs Controller |
| BC-EDG-06 | RPT-GAP-INC-02: charts rendered as tables; trend is monthly not weekly; no chart canvas | Screen-24 vs View |
| BC-EDG-07 | RPT-GAP-INC-03: export privacy (roll-numbers + STUDENT-SHA anonymisation) unimplemented | Screen-24 vs Controller |
| BC-EDG-08 | RPT-GAP-INC-04: grid "Witness Count" column absent (witnesses not eager-loaded) | Screen-24 vs Controller/View |
| BC-EDG-09 | DOC-BA-006: severity vocabulary Info/Low/Medium/High (Screen-24) ≠ live minor/moderate/major/critical | Screen-24 vs DDL/View |

### BC-INT — Cross-module / tenancy / API
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Tenant context initialized; ba_incidents resolves within tenant DB | Constraint A |
| BC-INT-02 | DEAD-BA-001: api.php `behaviouralassessments` apiResource never registered + no tenancy middleware | api.php + RSP (#23) |
| BC-INT-03 | Rendered report output is HTML-escaped (no `<script>alert(`) | View (Blade escaping) |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..05 | DDL | ba_incidents schema + model correct | table/cols/enums/relations pass | `_01` | Ready |
| TC-P02 | Schema | BC-DB-06/07 | DDL | intervention + witness join tables exist | tables/cols present | `_02` | Ready |
| TC-P03 | Route | BC-AUTH-01 | Routes | controller method + routes registered | reports.incidents GET resolves | `_03` | Ready |
| TC-P04 | Render | BC-BIZ-01/02/04 | View | view renders expected sections | all zones present | `_04` | Ready |
| TC-P05 | Config | BC-VAL-01 | Controller | real filter set honoured | 5 filters + defaults + paginate(25) | `_06` | Ready |
| TC-P06 | Render | BC-BIZ-01 | View | renders for authorized admin | no Whoops, headings present | `_10` | Ready |
| TC-P07 | Render | BC-BIZ-02 | View | executive KPI cards render | 4 KPI labels present | `_11` | Ready |
| TC-P08 | Data | BC-BIZ-03 | Controller | negativeCount = total − positive | invariant asserted | `_12` | Ready |
| TC-P09 | Data | BC-BIZ-06 | Ctrl/View | seeded incidents appear in log/count | count grows, no empty state | `_13` | Ready |
| TC-P10 | Render | BC-BIZ-04 | View | analytics widgets render | 4 widgets present | `_14` | Ready |
| TC-P11 | Data | BC-BIZ-05 | Controller | intervention usage junction join | ba_ join asserted | `_15` | Ready |
| TC-P12 | UI | BC-VAL-01 | View | filter form renders fields+options | 5 fields + All* defaults | `_60` | Ready |
| TC-P13 | UI | BC-EDG-01 | View | reset link present | Reset → reports/incidents | `_61` | Ready |
| TC-P14 | UI | BC-EDG-02 | Ctrl/View | pagination 25/page + query string | paginate(25), withQueryString | `_63` | Ready |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Filter | BC-VAL-02 | Controller | unknown category_id | 200/302, no 500 | `_30` | Ready |
| TC-N02 | Filter | BC-VAL-04 | Controller | garbage date filter | documents 200/302/500 | `_31` | Ready |
| TC-N03 | Filter | BC-VAL-03 | Controller | valid severity filter | 200/302 | `_32` | Ready |
| TC-N04 | Filter | BC-VAL-03 | Controller | valid incident_type filter | 200/302 | `_33` | Ready |
| TC-N05 | Auth | BC-AUTH-02 | RSP | guest redirect to login | `/login` | `_50` | Ready |
| TC-N06 | Auth | BC-AUTH-03 | Gate | limited user 403 | 403 | `_51` | Ready |
| TC-N07 | UI | BC-EDG-01 | View | empty state on no-result window | empty message shown | `_62` | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C/D | BC-REF-01..04 | DDL | incident FK RESTRICT/SET NULL | rules match | `_40` | Ready |
| TC-D02 | B/C | BC-REF-05/06 | DDL | intervention junction CASCADE/RESTRICT | rules match | `_41` | Ready |
| TC-D03 | B | BC-REF-07 | DDL | witness junction CASCADE | rule matches | `_42` | Ready |
| TC-D04 | E | BC-AUTH-04 | Policy | policy maps permission strings | 3 abilities present | `_52` | Ready |
| TC-D05 | E | BC-INT-01 | Constraint A | tenant context initialized | tables resolve | `_90` | Ready |
| TC-D06 | E | BC-AUTH-05 | RSP | web routes carry tenancy stack | 3 needles present | `_92` | Ready |

### Security / Tenancy (TC-S / TC-T)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-S01 | XSS | BC-INT-03 | View | rendered report escapes output | no `<script>alert(` | `_93` | Ready |
| TC-T01 | API | BC-INT-02 | api.php/RSP | DEAD-BA-001 api resource dead + no tenancy | unregistered, no middleware | `_91` | Ready |

### Known Source Defects / Gaps (audit-equivalent, with proving tests)
| ID | Description | Proving method | Status |
|----|-------------|----------------|--------|
| BUG-BA-011 | `reports.export` permanent abort(501) stub | `_70` | Confirmed |
| BUG-BA-013 | NOT APPLICABLE to incidents report (no `score`/computed_scores) | `_71` | Documented N/A |
| DEAD-BA-001 | api.php apiResource unregistered + no tenancy middleware | `_91` | Confirmed |
| DOC-BA-001 | DDL prefix `bha_` vs live `ba_` | `_05` | Confirmed |
| VAL-BA-003 | export() gates reports.view, not reports.export (dead policy ability) | `_53` | Confirmed |
| RPT-GAP-INC-01 | Class&Section + Student filters unimplemented | `_72` | Confirmed |
| RPT-GAP-INC-02 | Charts as tables; monthly (not weekly) trend; no canvas | `_73` | Confirmed |
| RPT-GAP-INC-03 | Export privacy anonymisation unimplemented (501 stub) | `_74` | Confirmed |
| RPT-GAP-INC-04 | Grid "Witness Count" column absent | `_75` | Confirmed |
| DOC-BA-006 | Severity vocabulary Info/Low/Medium/High ≠ live minor/moderate/major/critical | `_76` | Confirmed |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_incident_report_01_incidents_schema_and_model_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_incident_report_02_intervention_join_tables_exist | TC-P02 | Schema | 01–09 |
| 3 | test_incident_report_03_report_controller_method_and_routes_are_registered | TC-P03 | Route | 01–09 |
| 4 | test_incident_report_04_incidents_view_renders_expected_sections | TC-P04 | Render | 01–09 |
| 5 | test_incident_report_05_runtime_table_prefix_diverges_from_ddl_doc_ba_001 | DOC-BA-001 | Schema | 01–09 |
| 6 | test_incident_report_06_controller_reads_real_filter_set | TC-P05 | Config | 01–09 |
| 7 | test_incident_report_10_report_renders_for_authorized_admin | TC-P06 | Render | 10–19 |
| 8 | test_incident_report_11_executive_summary_kpi_cards_render | TC-P07 | Render | 10–19 |
| 9 | test_incident_report_12_negative_count_is_total_minus_positive_invariant | TC-P08 | Data | 10–19 |
| 10 | test_incident_report_13_seeded_incidents_appear_in_log_and_counts | TC-P09 | Data | 10–19 |
| 11 | test_incident_report_14_analytics_widgets_render | TC-P10 | Render | 10–19 |
| 12 | test_incident_report_15_intervention_usage_reads_junction_join | TC-P11 | Data | 10–19 |
| 13 | test_incident_report_30_unknown_category_filter_does_not_error | TC-N01 | Filter | 30–39 |
| 14 | test_incident_report_31_garbage_date_filter_does_not_500 | TC-N02 | Filter | 30–39 |
| 15 | test_incident_report_32_valid_severity_filter_renders | TC-N03 | Filter | 30–39 |
| 16 | test_incident_report_33_valid_incident_type_filter_renders | TC-N04 | Filter | 30–39 |
| 17 | test_incident_report_40_incident_fks_restrict_or_set_null_on_delete | TC-D01 | Integration | 40–49 |
| 18 | test_incident_report_41_intervention_junction_cascade_and_restrict | TC-D02 | Integration | 40–49 |
| 19 | test_incident_report_42_witness_junction_cascades_from_incident | TC-D03 | Integration | 40–49 |
| 20 | test_incident_report_50_guest_is_redirected_to_login | TC-N05 | Auth | 50–59 |
| 21 | test_incident_report_51_limited_user_gets_403 | TC-N06 | Auth | 50–59 |
| 22 | test_incident_report_52_policy_maps_to_permission_strings | TC-D04 | Auth | 50–59 |
| 23 | test_incident_report_53_export_gate_diverges_from_policy_val_ba_003 | VAL-BA-003 | Auth | 50–59 |
| 24 | test_incident_report_60_filter_form_renders_real_fields_and_options | TC-P12 | UI | 60–69 |
| 25 | test_incident_report_61_reset_link_present | TC-P13 | UI | 60–69 |
| 26 | test_incident_report_62_empty_state_message_on_no_results | TC-N07 | UI | 60–69 |
| 27 | test_incident_report_63_incident_log_paginates_25_per_page | TC-P14 | UI | 60–69 |
| 28 | test_incident_report_70_export_is_live_abort_501_stub_bug_ba_011 | BUG-BA-011 | Edge | 70–79 |
| 29 | test_incident_report_71_bug_ba_013_not_applicable_to_incidents_report | BUG-BA-013 | Edge | 70–79 |
| 30 | test_incident_report_72_class_and_student_filters_not_implemented_rpt_gap_inc_01 | RPT-GAP-INC-01 | Edge | 70–79 |
| 31 | test_incident_report_73_charts_are_tables_and_trend_is_monthly_rpt_gap_inc_02 | RPT-GAP-INC-02 | Edge | 70–79 |
| 32 | test_incident_report_74_export_privacy_anonymisation_absent_rpt_gap_inc_03 | RPT-GAP-INC-03 | Edge | 70–79 |
| 33 | test_incident_report_75_witness_count_column_absent_rpt_gap_inc_04 | RPT-GAP-INC-04 | Edge | 70–79 |
| 34 | test_incident_report_76_severity_vocabulary_diverges_from_requirement_doc_ba_006 | DOC-BA-006 | Edge | 70–79 |
| 35 | test_incident_report_90_tenant_context_is_initialized | TC-D05 | Tenancy | 90–99 |
| 36 | test_incident_report_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001 | TC-T01 | Tenancy | 90–99 |
| 37 | test_incident_report_92_web_report_routes_carry_full_tenancy_stack | TC-D06 | Tenancy | 90–99 |
| 38 | test_incident_report_93_rendered_report_escapes_output | TC-S01 | Security | 90–99 |
