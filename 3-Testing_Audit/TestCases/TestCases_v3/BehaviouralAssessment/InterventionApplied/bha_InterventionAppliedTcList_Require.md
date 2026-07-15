# Interventions Applied — Requirements & Test-Case List

**Module:** BehaviouralAssessment  •  **Feature / Screen:** InterventionApplied (screen `14-Interventions-Applied`)
**Primary table:** `ba_incident_intervention_jnt` (live `ba_` prefix; DDL doc uses stale `bha_` — see DOC-BA-001)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController` (junction managed inside the incident flow) + read-only tab via `BaDashboardController::incidentsPage()`
**Test file:** `bha_InterventionApplied_TestCas.php` — single comprehensive Dusk suite, **48 test methods**
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant, no `tenant_id` columns) → tenancy scaffolding required.

> This document is a 1:1 mirror of the existing, `php -l`-clean 48-method test file. Every row maps to exactly one test method; every method appears exactly once.

---

## 1. Business Conditions

### BC-DB — Schema / persistence facts
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-DB-01 | `ba_incident_intervention_jnt` exists with columns `id, incident_id, intervention_id, notes, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_incident_intervention_jnt |
| BC-DB-02 | `incident_id` / `intervention_id` are `bigint`; `notes` `varchar(500)`; `is_active` `tinyint` | DDL-ba_incident_intervention_jnt |
| BC-DB-03 | UNIQUE index `uq_ba_inc_int` over `(incident_id, intervention_id)` prevents duplicate links | DDL-migration |
| BC-DB-04 | Migration `create_ba_incident_intervention_jnt_table` constrains `ba_incidents` cascadeOnDelete + `ba_interventions`, `notes(500)`, `softDeletes()` | Migration file |
| BC-DB-05 | Model `BaIncidentInterventionJnt`: table `ba_incident_intervention_jnt`; fillable `[incident_id, intervention_id, notes, is_active, created_by, updated_by]`; `is_active` cast boolean; `incident()`/`intervention()` are `BelongsTo` | Model |
| BC-DB-06 | `created_by`/`updated_by` stamped from `auth()->id()` server-side on link | Controller |
| BC-DB-07 | Runtime table uses `ba_` prefix; `bha_incident_intervention_jnt` must NOT exist at runtime (DOC-BA-001) | Audit-DOC-BA-001 |
| BC-DB-08 | `deleted_at` column exists (migration `softDeletes()`) but the model does NOT use the `SoftDeletes` trait → `->delete()` is a HARD delete (DATA-BA-IA-01) | Audit-DATA-BA-IA-01 |

### BC-VAL — Validation rules (`addIntervention()` inline + `BaIncidentRequest`)
| BC ID | Condition | Error surface | Source |
|-------|-----------|---------------|--------|
| BC-VAL-01 | `intervention_id` is required | 422 `errors.intervention_id` | Controller/FormRequest |
| BC-VAL-02 | `intervention_id` must exist in `ba_interventions,id` | 422 `errors.intervention_id` | FormRequest `exists:ba_interventions,id` |
| BC-VAL-03 | `intervention_id` must be integer | 422 `errors.intervention_id` | Controller inline rules |
| BC-VAL-04 | `notes` max 500 chars | 422 `errors.notes` | Controller inline rules |
| BC-VAL-05 | Bulk `interventions.*` items must exist in `ba_interventions,id` | 422 `errors.interventions.0` | BaIncidentRequest |
| BC-VAL-06 | Bulk `interventions[]` must be `distinct` | 422 | BaIncidentRequest `array\|distinct` |

### BC-AUTH — Permissions / authorization
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-AUTH-01 | Guest visiting the tab is redirected to `/login` | Middleware |
| BC-AUTH-02 | `addIntervention` requires `tenant.behavioural-assessment.incidents.update` → limited user 403 | Controller `Gate::authorize` |
| BC-AUTH-03 | `removeIntervention` requires `incidents.update` → limited user 403 | Controller `Gate::authorize` |
| BC-AUTH-04 | Standalone tab requires `tenant.behavioural-assessment.incidents-page.viewAny` → limited user 403 | Route/middleware |
| BC-AUTH-05 | `BaIncidentPolicy` maps `viewAny/view/create/update/delete/restore/forceDelete/status` to `tenant.behavioural-assessment.incidents.*` strings | Policy |
| BC-AUTH-06 | `addIntervention`/`removeIntervention` both guard the SAME `incidents.update` gate (no dedicated junction permission) | Controller |

### BC-BIZ — Business rules
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-BIZ-01 | `addIntervention()` links a pair and persists (`is_active=1` default), redirects back with success | Screen-BR, Controller |
| BC-BIZ-02 | Supplied `notes` persist verbatim | Controller |
| BC-BIZ-03 | Incident `store()` bulk-attaches the selected `interventions[]` to the junction | Controller |
| BC-BIZ-04 | Incident `update()` re-syncs interventions (forceDelete + recreate) | Controller |
| BC-BIZ-05 | Standalone tab lists the applied intervention (by `name`) | Blade view |
| BC-BIZ-06 | `addIntervention` is idempotent (`firstOrCreate` on the pair) — no duplicate | Controller |
| BC-BIZ-07 | `notes` optional — omitted persists as `null` | Controller |
| BC-BIZ-08 | `removeIntervention()->delete()` hard-deletes the junction row | Controller / DATA-BA-IA-01 |
| BC-BIZ-09 | Full lifecycle add → list → remove works end-to-end | Controller + Blade |
| BC-BIZ-10 | `firstOrCreate` preserves ORIGINAL notes; a second add does NOT overwrite | Controller |
| BC-BIZ-11 | Tab search filters by student; intervention-type filter narrows; empty state message; info alert; `ia_page` paginator | Blade / BaDashboardController |

### BC-REF — Referential integrity
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | `intervention_id` FK is `RESTRICT`/`NO ACTION` on delete | DDL-migration |
| BC-REF-02 | `incident_id` FK is `CASCADE` on delete | DDL-migration |
| BC-REF-03 | Force-deleting an incident cascades → junction rows removed | DB behaviour |
| BC-REF-04 | Soft-deleting an incident does NOT cascade → junction rows survive | Eloquent SoftDeletes vs DB FK |
| BC-REF-05 | Duplicate `(incident_id, intervention_id)` violates `uq_ba_inc_int` | DDL-migration |

### BC-EDG — Edge cases
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-EDG-01 | `addIntervention` on a non-existent incident → 404 (`findOrFail`) | Controller |
| BC-EDG-02 | `removeIntervention` on a non-existent incident → 404 (route-model binding) | Controller |
| BC-EDG-03 | `removeIntervention` with an unknown junction id → no-op, still redirects; genuine row untouched | Controller |
| BC-EDG-04 | `notes` boundary: 500 chars accepted, 501 rejected | Controller |

### BC-INT — Tenancy / integration
| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-INT-01 | Tenant context initialized; junction table visible in tenant DB | stancl/tenancy |
| BC-INT-02 | Cross-tenant direct-ID isolation (second tenant domain resolvable) | Domain model |
| BC-INT-03 | `BaIntervention::booted()` observer detaches junction rows on forceDelete, bypassing DB RESTRICT (INT-OBS-01) | Model observer |

### Known Source Defects (audit-equivalent `*-BA-*`)
| Defect ID | Description | Proving test |
|-----------|-------------|--------------|
| DOC-BA-001 | DDL doc prefix `bha_` diverges from live `ba_` runtime table | test_ia_02 |
| DATA-BA-IA-01 | Migration adds `softDeletes()` (`deleted_at`) but model has NO `SoftDeletes` trait — column is dead; `->delete()` hard-deletes | test_ia_03, test_ia_46 |
| VAL-BA-IA-01 | Screen 14 specs an intervention lifecycle (Status / Scheduled Date / Assigned-To / Completion Date / Progress Notes 1000) — none implemented; junction only has `notes(500)` + `is_active` | test_ia_20 |
| INFO-BA-IA-02 | `is_active` soft enable/disable column exists but no endpoint toggles it | test_ia_21 |
| SEC-BA-002 | `BaIncidentRequest::authorize()` returns bare `true` (mitigated by controller `Gate::authorize`) | test_ia_94 |
| INT-OBS-01 | `BaIntervention` `booted()` detaches junction rows on forceDelete, working around the DB RESTRICT FK | test_ia_44 |

---

## 2. Test Case List

### Configuration / Schema Truth (Band 01–09)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-C01 | Config | BC-DB-01..06 | DDL/Migration/Model | Migration, model, request configuration are correct | Table/columns/index/fillable/casts/relationships all match | test_ia_01_migration_model_and_request_configuration_are_correct | Ready |
| TC-C02 | Config/Defect | BC-DB-07 | DOC-BA-001 | Runtime prefix `ba_` present; `bha_` absent | `ba_` table exists, `bha_` does not; model binds `ba_` | test_ia_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001 | Ready |
| TC-C03 | Config/Defect | BC-DB-08 | DATA-BA-IA-01 | `deleted_at` present but model lacks `SoftDeletes` → hard delete | `->delete()` physically removes the row | test_ia_03_soft_delete_column_present_but_model_lacks_trait_data_ba_ia_01 | Ready |

### Positive (Band 10–19, 46–47, 74)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Positive | BC-BIZ-01, BC-DB-06 | Controller | addIntervention links + persists with success flash | Row created, `is_active=1`, `created_by`/`updated_by` = admin | test_ia_10_add_intervention_links_and_persists_with_success_flash | Ready |
| TC-P02 | Positive | BC-BIZ-02 | Controller | addIntervention persists notes | Notes stored verbatim | test_ia_11_add_intervention_persists_notes | Ready |
| TC-P03 | Positive | BC-BIZ-03 | Controller | Incident store bulk-attaches interventions | Selected intervention linked | test_ia_12_incident_store_bulk_attaches_interventions | Ready |
| TC-P04 | Positive | BC-BIZ-04 | Controller | Incident update re-syncs interventions | New intervention linked | test_ia_13_incident_update_resyncs_interventions | Ready |
| TC-P05 | Positive | BC-BIZ-05 | Blade | Standalone tab lists applied interventions | Intervention name visible | test_ia_14_standalone_tab_lists_applied_interventions | Ready |
| TC-P06 | Positive | BC-BIZ-06 | Controller | addIntervention idempotent — no duplicate | Exactly 1 row for the pair | test_ia_15_add_intervention_is_idempotent_no_duplicate | Ready |
| TC-P07 | Positive | BC-BIZ-07 | Controller | notes optional — link without notes | Success; `notes` null | test_ia_16_add_intervention_notes_optional_null | Ready |
| TC-P08 | Positive | BC-DB-06 | Controller | created_by/updated_by stamped from auth | Both = admin id | test_ia_17_created_by_updated_by_stamped_from_auth | Ready |
| TC-P09 | Positive | BC-BIZ-08 | Controller/DATA-BA-IA-01 | removeIntervention hard-deletes the junction row | Row physically gone | test_ia_46_remove_intervention_hard_deletes_the_junction_row | Ready |
| TC-P10 | Positive | BC-BIZ-09 | Controller+Blade | Full lifecycle add → list → remove | All three steps succeed | test_ia_47_full_lifecycle_add_list_remove | Ready |
| TC-P11 | Positive | BC-BIZ-10 | Controller | addIntervention does not overwrite existing notes | Original notes preserved | test_ia_74_add_intervention_does_not_overwrite_existing_notes | Ready |

### Requirement-Gap (Band 20–29)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-G01 | Negative/Defect | VAL-BA-IA-01 | Screen-14 | Specced lifecycle columns absent | `status/scheduled_date/assigned_to/completion_date/progress_notes` do not exist; notes is 500 | test_ia_20_lifecycle_status_columns_specced_but_not_implemented_val_ba_ia_01 | Ready |
| TC-G02 | Negative/Defect | INFO-BA-IA-02 | Routes | `is_active` present but no toggle endpoint | add+remove routes exist, no `interventions.toggle` | test_ia_21_is_active_flag_present_but_no_toggle_endpoint_info_ba_ia_02 | Ready |

### Negative — Validation (Band 30–39)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Negative | BC-VAL-01 | Controller | intervention_id required | 422 `errors.intervention_id` | test_ia_30_add_intervention_requires_intervention_id | Ready |
| TC-N02 | Negative | BC-VAL-02 | FormRequest | intervention_id must exist | 422 `errors.intervention_id` | test_ia_31_add_intervention_id_must_exist_in_interventions | Ready |
| TC-N03 | Negative | BC-VAL-03 | Controller | intervention_id must be integer | 422 `errors.intervention_id` | test_ia_32_add_intervention_id_must_be_integer | Ready |
| TC-N04 | Negative | BC-VAL-04 | Controller | notes max 500 enforced | 422 `errors.notes` | test_ia_33_add_intervention_notes_max_500_is_enforced | Ready |
| TC-N05 | Negative | BC-VAL-05 | BaIncidentRequest | interventions.* items must exist | 422 `interventions.*` | test_ia_34_incident_request_interventions_items_must_exist | Ready |
| TC-N06 | Negative | BC-VAL-06 | BaIncidentRequest | interventions[] must be distinct | 422 | test_ia_35_incident_request_interventions_must_be_distinct | Ready |

### Dependency — FK / Referential (Band 40–49)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | Dependency | BC-REF-01 | DDL | intervention FK is RESTRICT | DELETE_RULE ∈ {RESTRICT, NO ACTION} | test_ia_40_junction_fk_to_intervention_is_restrict | Ready |
| TC-D02 | Dependency | BC-REF-02 | DDL | incident FK is CASCADE | DELETE_RULE = CASCADE | test_ia_41_junction_fk_to_incident_is_cascade | Ready |
| TC-D03 | Dependency | BC-REF-03 | DB | Force-deleting incident cascades | Junction rows removed | test_ia_42_deleting_incident_cascades_and_removes_junction_rows | Ready |
| TC-D04 | Dependency | BC-REF-04 | Eloquent | Soft-deleting incident does not cascade | Junction rows survive | test_ia_43_soft_deleting_incident_does_not_remove_junction_rows | Ready |
| TC-D05 | Dependency/Defect | BC-INT-03 | INT-OBS-01 | RESTRICT blocks raw delete of referenced intervention | Raw delete throws | test_ia_44_restrict_blocks_raw_delete_of_referenced_intervention_int_obs_01 | Ready |
| TC-D06 | Dependency | BC-REF-05 | DDL | Unique pair enforced at DB | Duplicate insert throws | test_ia_45_unique_incident_intervention_pair_enforced_at_db | Ready |

### Authorization (Band 50–59)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-A01 | Auth | BC-AUTH-01 | Middleware | Guest redirected to login | Path contains `/login` | test_ia_50_guest_is_redirected_to_login | Ready |
| TC-A02 | Auth | BC-AUTH-02 | Gate | Limited user 403 on add | 403 | test_ia_51_limited_user_without_update_gets_403_on_add | Ready |
| TC-A03 | Auth | BC-AUTH-03 | Gate | Limited user 403 on remove | 403 | test_ia_52_limited_user_without_update_gets_403_on_remove | Ready |
| TC-A04 | Auth | BC-AUTH-04 | Route | Limited user 403 on tab | 403 | test_ia_53_limited_user_without_page_permission_gets_403_on_tab | Ready |
| TC-A05 | Auth | BC-AUTH-05 | Policy | Policy maps to permission strings | All 8 abilities present | test_ia_54_incident_policy_methods_map_to_permission_strings | Ready |
| TC-A06 | Auth | BC-AUTH-06 | Controller | add & remove guarded by incidents.update gate | Both methods + gate string present | test_ia_55_add_and_remove_are_guarded_by_incidents_update_gate | Ready |

### UI / UX (Band 60–69)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-U01 | UI | BC-BIZ-11 | Blade | Tab search filters by student | Intervention name visible after search | test_ia_60_tab_search_filters_by_student | Ready |
| TC-U02 | UI | BC-BIZ-11 | Blade | Intervention-type filter narrows results | Intervention name visible with filter | test_ia_61_tab_intervention_type_filter_narrows_results | Ready |
| TC-U03 | UI | BC-BIZ-11 | Blade | Empty state message when no matches | "No interventions applied yet." shown | test_ia_62_empty_state_message_when_no_matches | Ready |
| TC-U04 | UI | BC-BIZ-11 | Blade | Info alert present | "Interventions are applied from within individual incident records." | test_ia_63_tab_info_alert_present | Ready |
| TC-U05 | UI | BC-BIZ-11 | BaDashboardController | Tab paginates with `ia_page` | Second page renders without error | test_ia_64_tab_paginates_with_ia_page_parameter | Ready |

### Edge Cases (Band 70–79)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-E01 | Edge | BC-EDG-01 | Controller | add on invalid incident → 404 | 404 | test_ia_70_add_intervention_on_invalid_incident_returns_404 | Ready |
| TC-E02 | Edge | BC-EDG-02 | Controller | remove on invalid incident → 404 | 404 | test_ia_71_remove_intervention_on_invalid_incident_returns_404 | Ready |
| TC-E03 | Edge | BC-EDG-03 | Controller | remove with unknown jnt id → no-op | Redirect; genuine row untouched | test_ia_72_remove_intervention_with_unknown_jnt_id_is_noop_success | Ready |
| TC-E04 | Edge | BC-EDG-04 | Controller | notes boundary 500 accepted / 501 rejected | 200/302 then 422 | test_ia_73_notes_boundary_500_accepted_501_rejected | Ready |

### Tenancy + Security (Band 90–99)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | BC-INT-01 | tenancy | Tenant context initialized | `tenancy()->initialized` true; table present | test_ia_90_tenant_context_is_initialized | Ready |
| TC-T02 | Tenancy | BC-INT-02 | Domain | Cross-tenant direct-ID isolation | Second tenant resolvable (or skip) | test_ia_91_cross_tenant_direct_id_isolation | Ready |
| TC-S01 | Security | BC-DB-06 | Controller | created_by cannot be spoofed via payload | created_by from auth; id auto-increment | test_ia_92_created_by_cannot_be_spoofed_via_payload | Ready |
| TC-S02 | Security | BC-VAL | Blade | Stored XSS in notes escaped on tab | Raw `<img onerror>` not in page source | test_ia_93_stored_xss_in_notes_escaped_on_tab | Ready |
| TC-S03 | Security/Defect | SEC-BA-002 | FormRequest | authorize() returns bare true | Regex confirms `return true;` | test_ia_94_incident_form_request_authorize_returns_true_sec_ba_002 | Ready |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_ia_01_migration_model_and_request_configuration_are_correct | TC-C01 | Config | 01–09 |
| 2 | test_ia_02_runtime_table_prefix_diverges_from_ddl_doc_ba_001 | TC-C02 | Config/Defect | 01–09 |
| 3 | test_ia_03_soft_delete_column_present_but_model_lacks_trait_data_ba_ia_01 | TC-C03 | Config/Defect | 01–09 |
| 4 | test_ia_10_add_intervention_links_and_persists_with_success_flash | TC-P01 | Positive | 10–19 |
| 5 | test_ia_11_add_intervention_persists_notes | TC-P02 | Positive | 10–19 |
| 6 | test_ia_12_incident_store_bulk_attaches_interventions | TC-P03 | Positive | 10–19 |
| 7 | test_ia_13_incident_update_resyncs_interventions | TC-P04 | Positive | 10–19 |
| 8 | test_ia_14_standalone_tab_lists_applied_interventions | TC-P05 | Positive | 10–19 |
| 9 | test_ia_15_add_intervention_is_idempotent_no_duplicate | TC-P06 | Positive | 10–19 |
| 10 | test_ia_16_add_intervention_notes_optional_null | TC-P07 | Positive | 10–19 |
| 11 | test_ia_17_created_by_updated_by_stamped_from_auth | TC-P08 | Positive | 10–19 |
| 12 | test_ia_20_lifecycle_status_columns_specced_but_not_implemented_val_ba_ia_01 | TC-G01 | Negative/Defect | 20–29 |
| 13 | test_ia_21_is_active_flag_present_but_no_toggle_endpoint_info_ba_ia_02 | TC-G02 | Negative/Defect | 20–29 |
| 14 | test_ia_30_add_intervention_requires_intervention_id | TC-N01 | Negative | 30–39 |
| 15 | test_ia_31_add_intervention_id_must_exist_in_interventions | TC-N02 | Negative | 30–39 |
| 16 | test_ia_32_add_intervention_id_must_be_integer | TC-N03 | Negative | 30–39 |
| 17 | test_ia_33_add_intervention_notes_max_500_is_enforced | TC-N04 | Negative | 30–39 |
| 18 | test_ia_34_incident_request_interventions_items_must_exist | TC-N05 | Negative | 30–39 |
| 19 | test_ia_35_incident_request_interventions_must_be_distinct | TC-N06 | Negative | 30–39 |
| 20 | test_ia_40_junction_fk_to_intervention_is_restrict | TC-D01 | Dependency | 40–49 |
| 21 | test_ia_41_junction_fk_to_incident_is_cascade | TC-D02 | Dependency | 40–49 |
| 22 | test_ia_42_deleting_incident_cascades_and_removes_junction_rows | TC-D03 | Dependency | 40–49 |
| 23 | test_ia_43_soft_deleting_incident_does_not_remove_junction_rows | TC-D04 | Dependency | 40–49 |
| 24 | test_ia_44_restrict_blocks_raw_delete_of_referenced_intervention_int_obs_01 | TC-D05 | Dependency/Defect | 40–49 |
| 25 | test_ia_45_unique_incident_intervention_pair_enforced_at_db | TC-D06 | Dependency | 40–49 |
| 26 | test_ia_46_remove_intervention_hard_deletes_the_junction_row | TC-P09 | Positive | 40–49 |
| 27 | test_ia_47_full_lifecycle_add_list_remove | TC-P10 | Positive | 40–49 |
| 28 | test_ia_50_guest_is_redirected_to_login | TC-A01 | Auth | 50–59 |
| 29 | test_ia_51_limited_user_without_update_gets_403_on_add | TC-A02 | Auth | 50–59 |
| 30 | test_ia_52_limited_user_without_update_gets_403_on_remove | TC-A03 | Auth | 50–59 |
| 31 | test_ia_53_limited_user_without_page_permission_gets_403_on_tab | TC-A04 | Auth | 50–59 |
| 32 | test_ia_54_incident_policy_methods_map_to_permission_strings | TC-A05 | Auth | 50–59 |
| 33 | test_ia_55_add_and_remove_are_guarded_by_incidents_update_gate | TC-A06 | Auth | 50–59 |
| 34 | test_ia_60_tab_search_filters_by_student | TC-U01 | UI | 60–69 |
| 35 | test_ia_61_tab_intervention_type_filter_narrows_results | TC-U02 | UI | 60–69 |
| 36 | test_ia_62_empty_state_message_when_no_matches | TC-U03 | UI | 60–69 |
| 37 | test_ia_63_tab_info_alert_present | TC-U04 | UI | 60–69 |
| 38 | test_ia_64_tab_paginates_with_ia_page_parameter | TC-U05 | UI | 60–69 |
| 39 | test_ia_70_add_intervention_on_invalid_incident_returns_404 | TC-E01 | Edge | 70–79 |
| 40 | test_ia_71_remove_intervention_on_invalid_incident_returns_404 | TC-E02 | Edge | 70–79 |
| 41 | test_ia_72_remove_intervention_with_unknown_jnt_id_is_noop_success | TC-E03 | Edge | 70–79 |
| 42 | test_ia_73_notes_boundary_500_accepted_501_rejected | TC-E04 | Edge | 70–79 |
| 43 | test_ia_74_add_intervention_does_not_overwrite_existing_notes | TC-P11 | Positive | 70–79 |
| 44 | test_ia_90_tenant_context_is_initialized | TC-T01 | Tenancy | 90–99 |
| 45 | test_ia_91_cross_tenant_direct_id_isolation | TC-T02 | Tenancy | 90–99 |
| 46 | test_ia_92_created_by_cannot_be_spoofed_via_payload | TC-S01 | Security | 90–99 |
| 47 | test_ia_93_stored_xss_in_notes_escaped_on_tab | TC-S02 | Security | 90–99 |
| 48 | test_ia_94_incident_form_request_authorize_returns_true_sec_ba_002 | TC-S03 | Security/Defect | 90–99 |

**Total: 48 test methods.**
