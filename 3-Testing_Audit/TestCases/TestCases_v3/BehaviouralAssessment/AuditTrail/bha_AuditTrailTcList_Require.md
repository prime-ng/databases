# Audit Trail — Test Case List & Business Conditions (`bha_AuditTrailTcList_Require.md`)

**Module:** BehaviouralAssessment  |  **Feature/Screen:** AuditTrail (Reports → Audit Trail)
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/19-Audit-Trail.md`
**Depth:** LIGHT / read-focused — read-only immutable ledger (NOT a CRUD matrix)
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant, `InitializeTenancyByDomain`)
**Runtime table:** `ba_audit_log` (live `ba_` prefix — DDL doc uses stale `bha_`; see DOC-BA-001)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaAuditLogController@index` (single method)
**Route:** `GET /behavioural-assessment/audit-log` → name `behavioural-assessment.audit-log.index` (the ONLY route)
**Permission:** `tenant.behavioural-assessment.audit-log.{viewAny|view}` (Gate::authorize in controller; `BaAuditLogPolicy`)
**Filters (real):** `period_id` (scopeForPeriod), `entity_type` (=), `field_name` (LIKE `%..%`) — order `changed_at DESC, id DESC` — `paginate(30)`
**FormRequest / Activity log:** NONE (read-only; the screen IS the audit sink)
**Test file:** `bha_AuditTrail_TestCas.php` (single comprehensive suite, 30 methods)

---

## 1. Business Conditions

### BC-DB — Schema / table configuration (Source: `DDL-bha_audit_log`, migration `2026_06_16_130613`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_audit_log` exists with columns id, entity_type, entity_id, field_name, old_value, new_value, changed_by, changed_at, is_active, created_by, created_at | DDL-bha_audit_log |
| BC-DB-02 | `entity_type` is `ENUM('assessment','assessment_rating','incident')`; `field_name VARCHAR(50)`; `entity_id BIGINT UNSIGNED`; `is_active TINYINT(1)` | DDL-bha_audit_log |
| BC-DB-03 | Indexes `idx_ba_audit_entity(entity_type,entity_id)`, `idx_ba_audit_changed_by`, `idx_ba_audit_changed_at` exist | migration |
| BC-DB-04 | **Immutable ledger** — NO `updated_at`, NO `deleted_at`; model `$timestamps=false`; model does NOT use `SoftDeletes` | Screen-BR "Immutable Ledger", DDL |
| BC-DB-05 | Model `$table='ba_audit_log'`; fillable = entity_type, entity_id, field_name, old_value, new_value, changed_by, changed_at, is_active, created_by, created_at | Model BaAuditLog |
| BC-DB-06 | Casts: entity_id/changed_by → integer, is_active → boolean, changed_at/created_at → datetime | Model BaAuditLog |
| BC-DB-07 | Entity-type constants ENTITY_ASSESSMENT_RATING/ENTITY_ASSESSMENT/ENTITY_INCIDENT map to enum values | Model BaAuditLog |

### BC-BIZ — Business rules / render (Source: Screen §, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index renders the grid (Changed At, Entity, Record, Context, Field, Old Value, New Value, Changed By) + filter form | View audit-log/index |
| BC-BIZ-02 | Rows list every logged change; `{n} records` counter reflects the filtered total | View / Controller |
| BC-BIZ-03 | Rows ordered `changed_at DESC, id DESC` (newest first) | Controller |
| BC-BIZ-04 | Static `BaAuditLog::log()` inserts an immutable row (changed_by/created_by=auth id, is_active=1) | Model BaAuditLog |
| BC-BIZ-05 | Entity type rendered as a coloured badge (Assessment / Assessment Rating / Incident) | View |
| BC-BIZ-06 | Empty state shows "No audit records found." | View |

### BC-SM — State machine
| ID | Condition | Source |
|----|-----------|--------|
| — | **N/A** — the ledger has no lifecycle/status workflow; rows are insert-only and never transition. | Screen-BR "Immutable Ledger" |

### BC-INT — Integration / polymorphic (Source: Model relationships, scopeForPeriod)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Polymorphic `belongsTo` on `entity_id`: assessmentEntity→BaAssessment, assessmentRatingEntity→BaAssessmentRating, incidentEntity→BaIncident | Model |
| BC-INT-02 | `scopeForPeriod($periodId)` builds a compound subquery across assessments/ratings/incidents in the period and executes without error | Model |
| BC-INT-03 | `period_id` filter dropdown lists active `ba_assessment_periods` | Controller/View |

### BC-AUTH — Authorization (Source: Controller Gate, BaAuditLogPolicy, Screen-PM)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Controller `index()` calls `Gate::authorize('tenant.behavioural-assessment.audit-log.viewAny')` | Controller |
| BC-AUTH-02 | Guest is redirected to `/login` (auth middleware) | RouteServiceProvider |
| BC-AUTH-03 | Non-super-admin without `audit-log.viewAny` gets 403 | Policy + Gate::before (constraint #31) |
| BC-AUTH-04 | `BaAuditLogPolicy::viewAny/view` map to the `audit-log.{viewAny\|view}` permission strings | Policy |

### BC-EDG — Edge / immutability enforcement (Source: routes, Screen-BR)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Only the read-only index route is registered; NO store/update/destroy/create/edit/restore/forceDelete/toggle route | routes/web.php |
| BC-EDG-02 | POST to `/behavioural-assessment/audit-log` is not routable (404/405) | routes |
| BC-EDG-03 | DELETE to `/behavioural-assessment/audit-log` is not routable (404/405) | routes |
| BC-EDG-04 | Out-of-enum `entity_type` filter matches no rows → renders empty state, not an error | Controller `when()` |
| BC-EDG-05 | Applied filter value persists in the form input after search | View `request()` binding |
| BC-EDG-06 | Pagination nav appears when the filtered set exceeds 30 rows; filter persists across page links (`appends`) | Controller paginate(30) + View |

### BC-CFG — Configuration
| ID | Condition | Source |
|----|-----------|--------|
| — | **N/A** — no config-table-driven behaviour for this screen. | — |

### Known / Cross-Reference Source Defects (audit-equivalent `DOC-BA-*`)
| ID | Finding | Proven by |
|----|---------|-----------|
| DOC-BA-001 | DDL doc prefix `bha_audit_log` diverges from live `ba_audit_log` (code wins) | TC-P02 |
| DOC-BA-AUD-001 | Requirement filters (Date-Range, Action-Category dropdown, User autocomplete, Student) are NOT implemented — only period_id/entity_type/field_name exist | TC-N04 |
| DOC-BA-AUD-002 | Requirement promises IP-address capture + an IP column, but `ba_audit_log` has no `ip_address` column and the grid shows none | TC-N05 |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Positive | BC-DB-01/02/03/05/06/07 | DDL/Model | Schema, migration, model, casts, constants correct | All asserts pass | `test_audit_trail_01` | Automated |
| TC-P02 | Positive | BC-DB-05 / DOC-BA-001 | Audit | Live `ba_audit_log`, stale `bha_audit_log` absent | ba_ exists, bha_ absent | `test_audit_trail_02` | Automated |
| TC-P03 | Positive | BC-DB-04 | Screen-BR | Immutable — no updated_at/deleted_at, no SoftDeletes | asserts pass | `test_audit_trail_03` | Automated |
| TC-P04 | Positive | BC-DB-06/BC-INT-01 | Model | Casts + polymorphic relationships configured | belongsTo x3 to right models | `test_audit_trail_04` | Automated |
| TC-P05 | Positive | BC-BIZ-01 | View | Index renders grid + filter controls | headers + selects present | `test_audit_trail_10` | Automated |
| TC-P06 | Positive | BC-BIZ-02 | View | Seeded row appears in listing | old/new value + "records" seen | `test_audit_trail_11` | Automated |
| TC-P07 | Positive | BC-BIZ-02 | Controller | Records counter reflects filtered total | "3 records" | `test_audit_trail_12` | Automated |
| TC-P08 | Positive | BC-BIZ-03 | Controller | Ordering changed_at DESC | newer before older | `test_audit_trail_13` | Automated |
| TC-P09 | Positive | BC-BIZ-04 | Model | Static `log()` inserts immutable row | row persisted | `test_audit_trail_14` | Automated |
| TC-P10 | Positive | BC-BIZ-05 | View | Entity-type badges render per type | labels visible | `test_audit_trail_15` | Automated |
| TC-P11 | Positive | BC-INT-02 | Model | scopeForPeriod query executes + page renders | count int, 200 | `test_audit_trail_40` | Automated (defensive) |
| TC-P12 | Positive | BC-INT-03 | Controller | Period dropdown lists active periods | option present | `test_audit_trail_41` | Automated (defensive) |
| TC-P13 | Positive | BC-AUTH-04 | Policy | Policy maps to permission strings | strings present | `test_audit_trail_52` | Automated |
| TC-P14 | Positive | BC-AUTH-01 | Controller | Controller gates index with viewAny | Gate string present | `test_audit_trail_53` | Automated |
| TC-P15 | Positive | BC-BIZ-02 | View | Entity-type filter narrows results | only match seen | `test_audit_trail_60` | Automated |
| TC-P16 | Positive | BC-BIZ-02 | View | field_name LIKE filter matches | only match seen | `test_audit_trail_61` | Automated |
| TC-P17 | Positive | BC-EDG-05 | View | Filter value persists in input | input value retained | `test_audit_trail_64` | Automated |
| TC-P18 | Positive | BC-EDG-06 | Controller/View | Pagination appears for >30 rows, filter persists | pagination nav + query | `test_audit_trail_63` | Automated (defensive) |
| TC-P19 | Positive | BC-AUTH-02 | tenancy | Tenant context initialized | tenancy()->initialized | `test_audit_trail_90` | Automated |

### Negative (`TC-N`)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Negative | BC-AUTH-02 | RouteSP | Guest redirected to login | `/login` | `test_audit_trail_50` | Automated |
| TC-N02 | Negative | BC-AUTH-03 | Policy | Limited user without viewAny → 403 | 403 | `test_audit_trail_51` | Automated |
| TC-N03 | Negative | BC-EDG-04 | Controller | Invalid entity_type filter → empty, no error | empty state | `test_audit_trail_73` | Automated |
| TC-N04 | Negative | DOC-BA-AUD-001 | Screen-vs-view | Requirement filters not implemented | absent from view | `test_audit_trail_74` | Automated (defect proof) |
| TC-N05 | Negative | DOC-BA-AUD-002 | Screen-vs-schema | No ip_address column / IP column | absent | `test_audit_trail_75` | Automated (defect proof) |
| TC-N06 | Negative | BC-BIZ-06 | View | Empty-state message when no match | "No audit records found." | `test_audit_trail_62` | Automated |
| TC-N07 | Negative | BC-EDG-02 | routes | POST to endpoint rejected | 404/405 | `test_audit_trail_71` | Automated |
| TC-N08 | Negative | BC-EDG-03 | routes | DELETE to endpoint rejected | 404/405 | `test_audit_trail_72` | Automated |
| TC-N09 | Negative | BC-SEC (XSS) | Security | Stored XSS in old/new value escaped | raw payload absent | `test_audit_trail_92` | Automated |

### Dependency / Immutability / Tenancy (`TC-D` / `TC-T`)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | Dependency-B (immutability) | BC-EDG-01 | routes | No mutation routes registered | only index true | `test_audit_trail_70` | Automated |
| TC-D02 | Dependency-E | BC-INT-01 | Model | Polymorphic relations resolve to correct models | class asserts | `test_audit_trail_04` | Automated |
| TC-T01 | Tenancy | BC-AUTH-02 | tenancy | Tenant context initialized | initialized | `test_audit_trail_90` | Automated |
| TC-T02 | Tenancy | Isolation | Domain | Cross-tenant isolation smoke | 2nd tenant or skip | `test_audit_trail_91` | Automated (defensive) |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_audit_trail_01_migration_and_model_configuration_are_correct` | TC-P01 | Schema truth | 01–09 |
| 2 | `test_audit_trail_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` | TC-P02 | Schema / DOC-BA-001 | 01–09 |
| 3 | `test_audit_trail_03_table_is_immutable_no_softdelete_no_updated_at` | TC-P03 | Schema / immutability | 01–09 |
| 4 | `test_audit_trail_04_casts_and_polymorphic_relationships_are_configured` | TC-P04/TC-D02 | Schema / relations | 01–09 |
| 5 | `test_audit_trail_10_index_renders_for_admin_with_grid_and_filters` | TC-P05 | Business / render | 10–19 |
| 6 | `test_audit_trail_11_seeded_row_appears_in_listing` | TC-P06 | Business / listing | 10–19 |
| 7 | `test_audit_trail_12_records_counter_reflects_filtered_total` | TC-P07 | Business / counter | 10–19 |
| 8 | `test_audit_trail_13_ordering_is_changed_at_desc` | TC-P08 | Business / order | 10–19 |
| 9 | `test_audit_trail_14_static_log_helper_inserts_an_immutable_row` | TC-P09 | Business / log() | 10–19 |
| 10 | `test_audit_trail_15_entity_type_badges_render_for_each_type` | TC-P10 | Business / badges | 10–19 |
| 11 | `test_audit_trail_40_period_filter_query_executes_without_error` | TC-P11 | Integration / scope | 40–49 |
| 12 | `test_audit_trail_41_period_dropdown_lists_active_periods` | TC-P12 | Integration | 40–49 |
| 13 | `test_audit_trail_50_guest_is_redirected_to_login` | TC-N01 | Auth | 50–59 |
| 14 | `test_audit_trail_51_limited_user_without_viewany_gets_403` | TC-N02 | Auth | 50–59 |
| 15 | `test_audit_trail_52_policy_maps_to_permission_strings` | TC-P13 | Auth / policy | 50–59 |
| 16 | `test_audit_trail_53_controller_authorizes_viewany_gate` | TC-P14 | Auth / gate | 50–59 |
| 17 | `test_audit_trail_60_entity_type_filter_narrows_results` | TC-P15 | UI/UX filter | 60–69 |
| 18 | `test_audit_trail_61_field_name_filter_like_matches` | TC-P16 | UI/UX filter | 60–69 |
| 19 | `test_audit_trail_62_empty_state_message_when_no_records_match` | TC-N06 | UI/UX empty | 60–69 |
| 20 | `test_audit_trail_63_pagination_present_when_more_than_thirty_rows` | TC-P18 | UI/UX pagination | 60–69 |
| 21 | `test_audit_trail_64_field_filter_value_persists_in_input` | TC-P17 | UI/UX persistence | 60–69 |
| 22 | `test_audit_trail_70_no_mutation_routes_are_registered` | TC-D01 | Edge / immutability | 70–79 |
| 23 | `test_audit_trail_71_post_to_audit_log_is_rejected` | TC-N07 | Edge / immutability | 70–79 |
| 24 | `test_audit_trail_72_delete_to_audit_log_is_rejected` | TC-N08 | Edge / immutability | 70–79 |
| 25 | `test_audit_trail_73_invalid_entity_type_filter_returns_empty_gracefully` | TC-N03 | Edge | 70–79 |
| 26 | `test_audit_trail_74_requirement_filters_not_implemented_doc_ba_aud_001` | TC-N04 | Edge / defect proof | 70–79 |
| 27 | `test_audit_trail_75_no_ip_address_column_or_display_doc_ba_aud_002` | TC-N05 | Edge / defect proof | 70–79 |
| 28 | `test_audit_trail_90_tenant_context_is_initialized` | TC-P19/TC-T01 | Tenancy | 90–99 |
| 29 | `test_audit_trail_91_cross_tenant_direct_isolation_smoke` | TC-T02 | Tenancy | 90–99 |
| 30 | `test_audit_trail_92_stored_xss_in_values_is_escaped_on_index` | TC-N09 | Security | 90–99 |

**Total: 30 methods.**
