# bha_CategoryPerformance — Gap Analysis & Coverage

**Feature:** CategoryPerformance (screen 23) · **Controller:** `BaReportController::categories()`
**Test file:** `bha_CategoryPerformance_TestCas.php` · **Methods:** 37 · **`php -l`:** clean
**Screen type:** Read-focused report / analytics dashboard (LIGHT). No CRUD matrix — coverage targets adapted for a report screen.

---

## 1. Manual TC ↔ Dusk method mapping

### Schema / Config / Routing / View
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P01 | `_01_computed_scores_schema_and_model_are_correct` | Full |
| TC-P02 | `_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` | Full |
| TC-P03 | `_03_report_controller_method_and_route_are_registered` | Full |
| TC-P04 | `_04_categories_view_titled_category_performance` | Full |

### Business rules / BUG-BA-013
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P05 | `_10_reports_hub_renders_for_authorized_admin` | Full |
| TC-N01 | `_11_category_aggregate_raw_sql_uses_nonexistent_score_column_bug_ba_013` | Full |
| TC-N02 | `_12_category_performance_page_hard_500s_due_to_bug_ba_013` | Full (route-level; skips if module disabled) |
| TC-N03 | `_13_categories_controller_aggregates_on_score_not_numeric_score_bug_ba_013` | Full |
| TC-N04 | `_14_seeded_score_has_numeric_score_but_no_score_attribute` | Full |
| TC-P06 | `_15_student_report_correctly_reads_numeric_score_contrast` | Full |
| TC-P07 | `_16_criterion_performance_reads_rating_levels_numeric_value` | Full |
| TC-P08 | `_17_dashboard_is_anonymized_no_student_identity_columns` | Full |

### Validation / Filters (negative)
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N05 | `_30_period_filter_does_not_change_the_bug_ba_013_outcome` | Full |
| TC-N06 | `_31_unknown_period_filter_still_reaches_the_bug` | Full |
| TC-N07 | `_32_garbage_query_params_do_not_introduce_a_new_error` | Full |

### Dependency / FK
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-D01 | `_40_computed_scores_fks_restrict_on_delete` | Full (MySQL; skips otherwise) |
| TC-D02 / TC-P12 | `_41_categories_report_dependency_tables_exist` | Full |

### Permissions / Authorization
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N08 | `_50_guest_is_redirected_to_login` | Full |
| TC-N09 | `_51_limited_user_gets_403_on_category_performance` | Full |
| TC-S01 | `_52_policy_maps_to_permission_strings` | Full |
| TC-S02 | `_53_export_gate_diverges_from_policy_val_ba_003` | Full |

### UI/UX
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P10 | `_60_categories_view_declares_an_empty_state` | Full |
| TC-P09 | `_61_categories_view_exposes_only_a_period_filter` | Full |
| TC-P11 | `_62_reports_hub_card_links_to_category_report` | Full |

### Edge / requirement-vs-implementation gaps
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N10 | `_70_export_is_live_abort_501_stub_bug_ba_011` | Full |
| TC-G01 | `_71_requirement_class_and_section_filters_not_implemented_rpt_gap_11` | Full |
| TC-G02 | `_72_requirement_columns_and_pdf_export_not_implemented_rpt_gap_12` | Full |
| TC-G03 | `_73_screen_23_and_17_share_one_implementation_doc_ba_002` | Full |
| TC-G04 | `_74_standard_deviation_dispersion_curve_not_implemented_rpt_gap_21` | Full |
| TC-G05 | `_75_demographic_gender_split_not_implemented_rpt_gap_22` | Full |
| TC-G06 | `_76_academic_correlation_matrix_not_implemented_rpt_gap_23` | Full |
| TC-G07 | `_77_standardization_threshold_warning_not_implemented_rpt_gap_24` | Full |
| TC-P15 / TC-G04 | `_78_std_dev_exists_in_byclass_not_in_categories_contrast` | Full |

### Tenancy / API / Security
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P13 | `_90_tenant_context_is_initialized` | Full |
| TC-T01 | `_91_api_resource_lacks_tenancy_and_is_dead_dead_ba_001` | Full |
| TC-T02 / TC-P14 | `_92_web_report_routes_carry_full_tenancy_stack` | Full |
| TC-S03 | `_93_categories_view_escapes_output` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive (render/schema/config/UI/contrast) | 15 | 15 | 0 | 0 | 100% |
| Negative (bug/filters/auth) | 10 | 10 | 0 | 0 | 100% |
| Dependency (FK/integration) | 2 | 2 | 0 | 0 | 100% |
| Security (policy/XSS/gate) | 3 | 3 | 0 | 0 | 100% |
| Tenancy (context/API/stack) | 2 | 2 | 0 | 0 | 100% |
| Requirement-vs-impl gaps | 7 | 7 | 0 | 0 | 100% |
| **Total** | **37 TC** | **37** | **0** | **0** | **100%** |

Report-screen targets met: Negative 100%, Positive 100%, Dependency 100%, Tenancy 100% (P0/P1). No CRUD matrix applies (read-only screen).

> **Note on route-level tests (`_12`, `_31`, `_32`, `_51`, `_70`):** graceful-skip when the module is disabled
> (`modules_statuses.json`) or the environment redirects to login, per constraint E19. The DB-level proofs
> (`_11`, `_14`, `_30`, `_78`) are environment-independent and carry the definitive BUG-BA-013 / gap evidence.

---

## 3. Cross-Reference Defect Scan (11-check hunt)

| # | Check | Compare | Finding | ID | Proving test |
|---|-------|---------|---------|----|--------------|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | n/a (no FormRequest; read-only) | — | — |
| 2 | Route registration | Blade `route()` / api.php vs RSP + module.json | `api.php` apiResource never registered (RSP maps only web.php) | **DEAD-BA-001** | `_91` |
| 3 | Gate vs Policy | `export()` gate vs `BaReportPolicy::export()` | controller gates `reports.view`; Policy checks `reports.export` (dead) | **VAL-BA-003** | `_53` |
| 4 | Fillable vs DDL | `BaComputedScore::$fillable` vs DDL | consistent — `numeric_score` fillable, no `score` | — | `_01` |
| 5 | Cast vs DDL | model casts vs DDL types | `numeric_score`/`overall_score` DECIMAL, `is_active` tinyint — consistent | — | `_01` |
| 6 | Service delegation | controller vs Service | `categories()` holds query logic inline (no service) — acceptable for a report | — | — |
| 7 | State machine vs impl | requirement transitions vs impl | n/a (no workflow on report) | — | — |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | n/a (query-string filters, no validation) | — | — |
| 9 | Error message vs FormRequest | expected vs `messages()` | n/a | — | — |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy + gates | `viewAny/view/export` map to `tenant.behavioural-assessment.reports.*`; export gate weaker (see #3) | VAL-BA-003 | `_52`, `_53` |
| 11 | Integration FK vs migration | requirement FKs vs migration | `student_id/category_id/period_id` FKs RESTRICT — consistent | — | `_40` |
| — | **Column reference vs DDL** (extra) | controller raw SQL `AVG(score)` vs `ba_computed_scores` columns | **`score` column does not exist → page HARD-500s** | **BUG-BA-013** | `_11`,`_12`,`_13`,`_14` |
| — | **Requirement widget vs impl** (extra) | screen-23 statistical widgets vs `categories()`/view | SD dispersion / gender split / academic correlation / SD>1.20 threshold all absent | **RPT-GAP-21..24** | `_74`–`_78` |
| — | **Requirement filter vs impl** (extra) | screen-23 Class/Section + Calculate-Statistics/export vs impl | only `period_id`; no PDF/CSV | **RPT-GAP-11/12**, **BUG-BA-011** | `_70`,`_71`,`_72` |
| — | **Doc prefix vs runtime** (extra) | DDL `bha_` vs live `ba_` | runtime is `ba_` | **DOC-BA-001** | `_02` |
| — | **Screen collapse** (extra) | screen 23 & 17 vs routes | one shared `categories()` implementation | **DOC-BA-002** | `_73` |

---

## 4. Coverage-Score (requirement coverage by Source-tag)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-23-BR`: anonymity, standardization threshold, statistical widgets) | 5 | 5 | 100% (4 proven as *unimplemented* gaps + 1 anonymity confirmed) |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | n/a (no workflow) |
| Validation Rules (`Screen-VR`) | 0 | 0 | n/a (no validation surface) |
| Integration Points (`Screen-IP`: dependency tables, FKs, API) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: viewAny/view/export + guest + limited) | 5 | 5 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. Screen-23's statistical requirements are covered as **documented
gaps** (each has a proving test asserting current absence, worded to fail-loud if the feature is later built).

---

## 5. Legend
- **Full** — behaviour fully asserted by ≥1 method (DB, route, or source level).
- **Gap test** — proves the requirement is currently *unimplemented*; the assertion is written to break (alerting the team) if/when the feature is added, so the test doubles as an implementation tripwire.
- **BUG-BA-013 is the headline defect** — it makes the entire page 500, so every UI/render assertion for this screen is proven at source level, not by live page render.
