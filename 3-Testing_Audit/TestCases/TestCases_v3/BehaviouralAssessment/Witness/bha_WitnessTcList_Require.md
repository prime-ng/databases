# Behavioural Assessment — Witness — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (`bha_` file prefix; **live tables use `ba_`** — see DOC-BA-001)
**Feature/Screen:** Witness (screen `13-Witnesses*`) — a **nested child of Incident**
**Primary table:** `ba_incident_witnesses_jnt` (junction; polymorphic `witness_type` student|staff) · **Parent:** `ba_incidents`
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Test file:** `bha_Witness_TestCas.php` (single comprehensive suite — no V1/V2) — **40 test methods**
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController` (witnesses have **no** standalone routes — attached/synced inside `store()`/`update()`)
**FormRequest:** `Modules\BehaviouralAssessment\Http\Requests\BaIncidentRequest`
**Primary requirement source:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/13-Witnesses.md`

> **Nested-child note.** A Witness has no screen/route of its own. It is written only through the incident form:
> `witness_student_ids[]` → `witness_type='student'`, `witness_id=std_students.id`; `witness_staff_ids[]` → `witness_type='staff'`, `witness_id=sch_employees.id`. Witnesses inherit the parent incident's `create`/`update` permission gates (no own gate).

---

## 1. Business Conditions

### BC-DB (schema — DDL/migration `ba_incident_witnesses_jnt`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `ba_incident_witnesses_jnt` exists with columns id, incident_id, witness_type, witness_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL-ba_incident_witnesses_jnt |
| BC-DB-02 | `incident_id` BIGINT UNSIGNED; `witness_id` INT/BIGINT; `witness_type` ENUM(`'student'`,`'staff'`) lowercase | DDL / SHOW COLUMNS |
| BC-DB-03 | UNIQUE(`incident_id`,`witness_type`,`witness_id`) — migration `uq_ba_witness` (DDL doc calls it `uq_bha_witness`) | Migration / SHOW INDEX |
| BC-DB-04 | `incident_id` FK → `ba_incidents.id` ON DELETE **CASCADE**; `witness_id` has **no** DB FK (polymorphic) | Migration / information_schema |
| BC-DB-05 | Migration adds `softDeletes()`/`deleted_at`, but model **omits** the `SoftDeletes` trait (dead column) — **DATA-BA-WIT-05** | Migration + Model |
| BC-DB-06 | Model `BaIncidentWitnessJnt`: table `ba_incident_witnesses_jnt`; fillable `[incident_id, witness_id, witness_type, is_active, created_by, updated_by]`; `incident()` BelongsTo | Model |
| BC-DB-07 | Runtime tables use `ba_` prefix; the DDL-doc `bha_*` names do NOT exist at runtime — **DOC-BA-001** | Runtime schema |

### BC-BIZ (business logic — `BaIncidentController` store/update + Model)
| ID | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | `store()` reads `witness_student_ids[]` + `witness_staff_ids[]` and writes rows with `witness_type='student'` / `'staff'` | Controller store() |
| BC-BIZ-02 | `update()` full re-sync: `BaIncidentWitnessJnt::where('incident_id',…)->forceDelete()` then recreate from the arrays | Controller update() |
| BC-BIZ-03 | New witness row defaults `is_active=true`; `created_by`/`updated_by` stamped to actor; timestamps set | Model / Controller |
| BC-BIZ-04 | `BaIncident::witnesses()` is a **HasMany** to `BaIncidentWitnessJnt` | Model |
| BC-BIZ-05 | Staff branch uses `firstOrCreate()` (idempotent); student branch uses plain `create()` — asymmetry (**BUG-BA-WIT-04**) | Controller store() |

### BC-SM (state machine — Audit Lock; requirement "freeze witnesses once incident closed/resolved")
| ID | State → Trigger → Next / Rule | Source |
|----|-------------------------------|--------|
| BC-SM-01 | Requirement: once incident closed/resolved → witness list **frozen** (Audit Lock). **NOT enforced** — `update()` never checks status/lock before re-sync (**BUG-BA-WIT-03**) | Screen-Req / Controller |
| BC-SM-02 | Data proof: a witness is still attachable to a resolved/follow-up-complete incident (**BUG-BA-WIT-03**) | Data layer |

### BC-VAL (validation — `BaIncidentRequest`)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `witness_student_ids` => `['nullable','array']`; `witness_student_ids.*` => `['integer','exists:std_students,id']` | Request |
| BC-VAL-02 | `witness_staff_ids` => `['nullable','array']`; `witness_staff_ids.*` => `['integer','exists:sch_employees,id']` | Request |
| BC-VAL-03 | Both witness arrays optional (an incident may be logged with zero witnesses) | Request |
| BC-VAL-04 | Requirement's per-witness "Witness Statement" (min 10, max 500) is **unimplemented** — no column, no fillable, no rule, no blade field (**DATA-BA-WIT-01**) | Screen-Req vs source |
| BC-VAL-05 | Requirement's "Self-Referential Block" (subject student ≠ own witness) is **not enforced** in FormRequest/controller (**BUG-BA-WIT-02**) | Screen-Req vs source |

### BC-AUTH (authorization — `BaIncidentPolicy` + parent-incident gates)
| ID | Ability → permission | Source |
|----|----------------------|--------|
| BC-AUTH-01 | Witness create governed by incident `create` gate `tenant.behavioural-assessment.incidents.create` (write happens in `store()`) | Policy / Controller |
| BC-AUTH-02 | Witness re-sync governed by incident `update` gate `tenant.behavioural-assessment.incidents.update` (write happens in `update()`) | Policy / Controller |
| BC-AUTH-03 | Policy maps all abilities viewAny/view/create/update/delete/restore/forceDelete/status to `tenant.behavioural-assessment.incidents.*` | Policy |
| BC-AUTH-04 | Guest is redirected to `/login` on the incident create screen | Auth middleware |
| BC-AUTH-05 | Witnesses have **no** standalone routes; only `behavioural-assessment.incidents.store`/`.update` exist | Routes |

### BC-REF / BC-INT (referential integrity & integration)
| ID | FK / integration | Source |
|----|------------------|--------|
| BC-REF-01 | Deleting the parent incident cascade-deletes its witness rows (FK ON DELETE CASCADE) | DDL / data |
| BC-REF-02 | `witness_id` is polymorphic → **no** DB FK; `incident_id` **has** a DB FK | information_schema |
| BC-INT-01 | Witnesses reference `std_students`/`sch_employees` (app-layer integrity only) — cross-module dependency | Request/Model |

### BC-EDG (edge cases)
| ID | Edge | Source |
|----|------|--------|
| BC-EDG-01 | Incident logged with zero witnesses → zero junction rows; `witnesses()` empty | Data |
| BC-EDG-02 | Staff `firstOrCreate` is idempotent (repeat call ≠ duplicate) | Controller pattern |
| BC-EDG-03 | `show()` on a non-existent incident id → 404 (`findOrFail`) | Controller |
| BC-EDG-04 | Duplicate `(incident,type,id)` row rejected by `uq_ba_witness` | DB |

### TC-T / TC-S (tenancy & security)
| ID | Condition | Source |
|----|-----------|--------|
| BC-TEN-01 | Tenant context initialized (database-per-tenant) for all witness data ops | Tenancy |
| BC-TEN-02 | Cross-tenant direct-ID isolation (IDOR) across tenant DBs (defensive; needs 2nd tenant) | Tenancy |
| BC-SEC-01 | Witness stores only enum type + integer id → **no free-text surface**, no stored-XSS vector | Schema |
| BC-SEC-02 | Out-of-enum `witness_type` rejected by DB (defence in depth) | DB (MySQL strict) |

---

## Known Source Defects (audit-equivalent `BUG-BA-*` / `DATA-BA-*` / `DOC-BA-*`)
| ID | Description | Severity | Proving method(s) |
|----|-------------|----------|-------------------|
| DATA-BA-WIT-01 | Requirement's per-witness "Witness Statement" (min 10/max 500) is unimplemented (no column/fillable/rule/blade field) | High | `_33` |
| BUG-BA-WIT-02 | "Self-Referential Block" not enforced — subject student can witness their own incident | High | `_34`, `_35` |
| BUG-BA-WIT-03 | "Audit Lock" not enforced — `update()` re-syncs witnesses regardless of incident status/lock | High | `_20`, `_21` |
| BUG-BA-WIT-04 | `store()` student branch uses plain `create()` (no dedup) vs staff `firstOrCreate()` — duplicate student id 500s on `uq_ba_witness` | Medium | `_44` |
| DATA-BA-WIT-05 | Migration adds `deleted_at` but model omits `SoftDeletes` → dead column; `->delete()` hard-deletes | Medium | `_05` |
| DOC-BA-001 | DDL-doc prefix `bha_` diverges from live `ba_`; index `uq_bha_witness` is `uq_ba_witness` at runtime | Doc | `_02`, `_03` |

---

## 2. Test Case List (one row per method — 1:1 with `bha_Witness_TestCas.php`)

Columns: **TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status**

### Schema / DDL / model / request configuration (Band 01–09)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Config | BC-DB-01/02/06 | DDL/Model | Junction table + columns + model fillable/relationship correct | Table, columns, enum/int types, fillable list, `incident()` BelongsTo all match | `test_witness_01_witness_junction_table_and_model_configuration_are_correct` | Automated |
| TC-P02 | Config/Doc | BC-DB-07 | DOC-BA-001 | Runtime prefix is `ba_`; `bha_*` doc names absent | `ba_*` tables exist; `bha_incident_witnesses_jnt` does not; model binds `ba_` | `test_witness_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | Automated |
| TC-P03 | Config | BC-DB-03/EDG-04 | Migration | UNIQUE(incident_id,witness_type,witness_id) present (by column set, not name) | Composite unique index found | `test_witness_03_unique_key_prevents_duplicate_witness_per_incident` | Automated |
| TC-P04 | Config | BC-DB-02 | DDL | `witness_type` enum is lowercase `student`/`staff` | Enum lists `'student'`/`'staff'`, not capitalised | `test_witness_04_witness_type_enum_is_lowercase_student_staff` | Automated |
| TC-N05 | Config/Defect | BC-DB-05 | DATA-BA-WIT-05 | Model omits SoftDeletes though table has `deleted_at` | `deleted_at` exists; `SoftDeletes` not in `class_uses_recursive` | `test_witness_05_model_omits_softdeletes_though_table_has_deleted_at_data_ba_wit_05` | Automated |

### Business rules (Band 10–19)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P10 | Positive | BC-BIZ-01 | Controller | Student witness persists via junction | Row `(incident,'student',id)` exists | `test_witness_10_student_witness_persists_via_junction` | Automated |
| TC-P11 | Positive | BC-BIZ-01 | Controller | Staff witness persists via junction | Row `(incident,'staff',id)` exists | `test_witness_11_staff_witness_persists_via_junction` | Automated |
| TC-P12 | Positive | BC-BIZ-03 | Model | `is_active` defaults true; audit columns set | `is_active`=true, `created_by`/`updated_by`=actor, `created_at` stamped | `test_witness_12_is_active_defaults_true_and_audit_columns_set` | Automated |
| TC-P13 | Positive | BC-BIZ-01 | Controller store() | `store()` attaches both student & staff witnesses | Source reads both arrays and writes both `witness_type`s | `test_witness_13_controller_store_attaches_both_student_and_staff_witnesses` | Automated |
| TC-P14 | Positive | BC-BIZ-02 | Controller update() | `update()` re-syncs: force-delete then recreate | Source force-deletes then recreates from arrays | `test_witness_14_controller_update_resyncs_witnesses_force_delete_then_recreate` | Automated |
| TC-P15 | Positive | BC-BIZ-04 | Model | `BaIncident::witnesses()` is HasMany | Returns a `HasMany` instance | `test_witness_15_incident_witnesses_relationship_is_hasmany` | Automated |

### State-machine / Audit-Lock (Band 20–29)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N20 | Negative/Defect | BC-SM-01 | BUG-BA-WIT-03 | Audit-lock freeze after close not enforced (source) | `update()` has no `isLocked`/`is_frozen`/`=== 'closed'` guard | `test_witness_20_audit_lock_freeze_after_close_is_not_enforced_bug_ba_wit_03` | Automated |
| TC-N21 | Negative/Defect | BC-SM-02 | BUG-BA-WIT-03 | Witness attachable regardless of incident state (data) | Witness row accepted on resolved incident | `test_witness_21_witness_can_be_attached_regardless_of_incident_state_bug_ba_wit_03` | Automated |

### Validation (Band 30–39)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N30 | Negative | BC-VAL-01 | Request | Student-ids rule requires existing student | Rule `integer` + `exists:std_students,id` + nullable array present | `test_witness_30_student_witness_ids_rule_requires_existing_student` | Automated |
| TC-N31 | Negative | BC-VAL-02 | Request | Staff-ids rule requires existing employee | Rule `integer` + `exists:sch_employees,id` + nullable array present | `test_witness_31_staff_witness_ids_rule_requires_existing_employee` | Automated |
| TC-N32 | Negative | BC-VAL-03 | Request | Witness arrays optional/nullable | `witness_student_ids` declared `nullable, array` | `test_witness_32_witness_arrays_are_optional_nullable` | Automated |
| TC-N33 | Negative/Defect | BC-VAL-04 | DATA-BA-WIT-01 | Witness-statement requirement unimplemented | No `statement` column/fillable/rule/blade field | `test_witness_33_witness_statement_requirement_is_unimplemented_data_ba_wit_01` | Automated |
| TC-N34 | Negative/Defect | BC-VAL-05 | BUG-BA-WIT-02 | Self-referential block not enforced (source) | No `different:student_id`/subject-exclusion in request/store | `test_witness_34_self_referential_block_is_not_enforced_bug_ba_wit_02` | Automated |
| TC-N35 | Negative/Defect | BC-VAL-05 | BUG-BA-WIT-02 | Subject student addable as own witness (data) | Subject student persisted as witness of own incident | `test_witness_35_subject_student_can_be_added_as_own_witness_at_data_layer_bug_ba_wit_02` | Automated |

### Integration / FK dependency & lifecycle (Band 40–49)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D40 | Dependency (B) | BC-REF-01 | DDL/data | Deleting incident cascades to witnesses | Witness rows removed with parent | `test_witness_40_deleting_incident_cascades_to_witnesses` | Automated |
| TC-D41 | Dependency (B) | BC-REF-01 | DDL | `witness→incident` FK is CASCADE | `DELETE_RULE` contains CASCADE | `test_witness_41_witness_incident_fk_is_cascade` | Automated |
| TC-D42 | Dependency | BC-REF-02 | information_schema | `witness_id` has no DB FK (polymorphic); `incident_id` does | `witness_id` absent / `incident_id` present in FK columns | `test_witness_42_witness_id_has_no_db_foreign_key_polymorphic` | Automated |
| TC-N43 | Negative/EDG | BC-EDG-04 | DB | Unique constraint rejects a duplicate witness row | 2nd identical row throws; exactly 1 row remains | `test_witness_43_unique_constraint_rejects_a_duplicate_witness_row` | Automated |
| TC-N44 | Negative/Defect | BC-BIZ-05 | BUG-BA-WIT-04 | Student loop lacks dedup (asymmetry with staff) | Staff `firstOrCreate` + student plain `create`, no `array_unique` | `test_witness_44_store_student_loop_lacks_dedup_asymmetry_with_staff_bug_ba_wit_04` | Automated |
| TC-D45 | Dependency (F) | BC-REF-01 | data | Full lifecycle: attach two types then cascade-delete | Both attached (2 rows) then 0 after incident force-delete | `test_witness_45_full_lifecycle_attach_two_types_then_cascade_delete` | Automated |

### Permissions / authorization (Band 50–59)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N50 | Negative | BC-AUTH-04 | Auth | Guest redirected to login on incident create | Path contains `/login` | `test_witness_50_guest_is_redirected_to_login_on_incident_create` | Automated |
| TC-N51 | Negative | BC-AUTH-01 | Policy | Limited user w/o create permission → 403 on store | HTTP 403 | `test_witness_51_limited_user_without_create_permission_gets_403_on_incident_store` | Automated |
| TC-N52 | Negative | BC-AUTH-02 | Policy | Limited user w/o update permission → 403 on update | HTTP 403 | `test_witness_52_limited_user_without_update_permission_gets_403_on_incident_update` | Automated |
| TC-P53 | Positive | BC-AUTH-03 | Policy | Policy maps all abilities to permission strings | Each ability's `tenant.behavioural-assessment.incidents.*` present | `test_witness_53_incident_policy_maps_to_permission_strings` | Automated |
| TC-P54 | Positive | BC-AUTH-05 | Routes | Witnesses have no standalone routes | Witness route names absent; incidents.store/update exist | `test_witness_54_witnesses_have_no_standalone_routes` | Automated |

### UI/UX (blade selectors, source-verified) (Band 60–69)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P60 | Positive | BC-BIZ-01 | Blade create | Create blade renders witness checkbox arrays | `witness_student_ids[]`/`witness_staff_ids[]` + id markers present | `test_witness_60_create_blade_renders_witness_checkbox_arrays` | Automated |
| TC-P61 | Positive | BC-BIZ-02 | Blade edit | Edit blade pre-checks existing witnesses | `old('witness_student_ids',$witnessStudentIds)` etc. present | `test_witness_61_edit_blade_prechecks_existing_witnesses` | Automated |
| TC-S62 | Security | BC-SEC-01 | Blade show | Show blade renders witnesses escaped (no raw echo) | Escaped `{{ }}` names; no `{!! !!}`; empty-state text present | `test_witness_62_show_blade_renders_witnesses_escaped` | Automated |

### Edge cases (Band 70–79)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D70 | Edge | BC-EDG-01 | data | Incident with no witnesses has zero junction rows | Count 0; relationship empty | `test_witness_70_incident_with_no_witnesses_has_zero_junction_rows` | Automated |
| TC-D71 | Edge | BC-EDG-02 | Controller pattern | Staff `firstOrCreate` idempotent at data layer | Repeat call keeps exactly 1 row | `test_witness_71_staff_firstorcreate_is_idempotent_at_data_layer` | Automated |
| TC-N72 | Negative/Edge | BC-EDG-03 | Controller | `show()` on invalid incident id → 404 | HTTP 404 | `test_witness_72_show_on_invalid_incident_id_returns_404` | Automated |

### Tenancy isolation + security pack (Band 90–99)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T90 | Tenancy | BC-TEN-01 | Tenancy | Tenant context is initialized | `tenancy()->initialized` true; junction table present | `test_witness_90_tenant_context_is_initialized` | Automated |
| TC-T91 | Tenancy | BC-TEN-02 | Tenancy | Cross-tenant direct-ID isolation (defensive) | 2nd tenant present or skip | `test_witness_91_cross_tenant_direct_id_isolation` | Automated |
| TC-S92 | Security | BC-SEC-01 | Schema | `witness_id` stored as integer; no free-text surface | `witness_id` int; `witness_type` in {student,staff} | `test_witness_92_witness_id_is_stored_as_integer_no_free_text_surface` | Automated |
| TC-S93 | Security | BC-SEC-02 | DB | `witness_type` enum rejects arbitrary value | Out-of-enum insert throws | `test_witness_93_witness_type_enum_rejects_arbitrary_value` | Automated |

---

## 3. Test Method Index (40 methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_witness_01_witness_junction_table_and_model_configuration_are_correct` | TC-P01 | Config | 01–09 |
| 2 | `test_witness_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | TC-P02 | Config/Doc | 01–09 |
| 3 | `test_witness_03_unique_key_prevents_duplicate_witness_per_incident` | TC-P03 | Config | 01–09 |
| 4 | `test_witness_04_witness_type_enum_is_lowercase_student_staff` | TC-P04 | Config | 01–09 |
| 5 | `test_witness_05_model_omits_softdeletes_though_table_has_deleted_at_data_ba_wit_05` | TC-N05 | Config/Defect | 01–09 |
| 6 | `test_witness_10_student_witness_persists_via_junction` | TC-P10 | Positive | 10–19 |
| 7 | `test_witness_11_staff_witness_persists_via_junction` | TC-P11 | Positive | 10–19 |
| 8 | `test_witness_12_is_active_defaults_true_and_audit_columns_set` | TC-P12 | Positive | 10–19 |
| 9 | `test_witness_13_controller_store_attaches_both_student_and_staff_witnesses` | TC-P13 | Positive | 10–19 |
| 10 | `test_witness_14_controller_update_resyncs_witnesses_force_delete_then_recreate` | TC-P14 | Positive | 10–19 |
| 11 | `test_witness_15_incident_witnesses_relationship_is_hasmany` | TC-P15 | Positive | 10–19 |
| 12 | `test_witness_20_audit_lock_freeze_after_close_is_not_enforced_bug_ba_wit_03` | TC-N20 | State/Defect | 20–29 |
| 13 | `test_witness_21_witness_can_be_attached_regardless_of_incident_state_bug_ba_wit_03` | TC-N21 | State/Defect | 20–29 |
| 14 | `test_witness_30_student_witness_ids_rule_requires_existing_student` | TC-N30 | Validation | 30–39 |
| 15 | `test_witness_31_staff_witness_ids_rule_requires_existing_employee` | TC-N31 | Validation | 30–39 |
| 16 | `test_witness_32_witness_arrays_are_optional_nullable` | TC-N32 | Validation | 30–39 |
| 17 | `test_witness_33_witness_statement_requirement_is_unimplemented_data_ba_wit_01` | TC-N33 | Validation/Defect | 30–39 |
| 18 | `test_witness_34_self_referential_block_is_not_enforced_bug_ba_wit_02` | TC-N34 | Validation/Defect | 30–39 |
| 19 | `test_witness_35_subject_student_can_be_added_as_own_witness_at_data_layer_bug_ba_wit_02` | TC-N35 | Validation/Defect | 30–39 |
| 20 | `test_witness_40_deleting_incident_cascades_to_witnesses` | TC-D40 | Dependency | 40–49 |
| 21 | `test_witness_41_witness_incident_fk_is_cascade` | TC-D41 | Dependency | 40–49 |
| 22 | `test_witness_42_witness_id_has_no_db_foreign_key_polymorphic` | TC-D42 | Dependency | 40–49 |
| 23 | `test_witness_43_unique_constraint_rejects_a_duplicate_witness_row` | TC-N43 | Negative/EDG | 40–49 |
| 24 | `test_witness_44_store_student_loop_lacks_dedup_asymmetry_with_staff_bug_ba_wit_04` | TC-N44 | Negative/Defect | 40–49 |
| 25 | `test_witness_45_full_lifecycle_attach_two_types_then_cascade_delete` | TC-D45 | Dependency | 40–49 |
| 26 | `test_witness_50_guest_is_redirected_to_login_on_incident_create` | TC-N50 | Auth | 50–59 |
| 27 | `test_witness_51_limited_user_without_create_permission_gets_403_on_incident_store` | TC-N51 | Auth | 50–59 |
| 28 | `test_witness_52_limited_user_without_update_permission_gets_403_on_incident_update` | TC-N52 | Auth | 50–59 |
| 29 | `test_witness_53_incident_policy_maps_to_permission_strings` | TC-P53 | Auth | 50–59 |
| 30 | `test_witness_54_witnesses_have_no_standalone_routes` | TC-P54 | Auth | 50–59 |
| 31 | `test_witness_60_create_blade_renders_witness_checkbox_arrays` | TC-P60 | UI/UX | 60–69 |
| 32 | `test_witness_61_edit_blade_prechecks_existing_witnesses` | TC-P61 | UI/UX | 60–69 |
| 33 | `test_witness_62_show_blade_renders_witnesses_escaped` | TC-S62 | UI/Security | 60–69 |
| 34 | `test_witness_70_incident_with_no_witnesses_has_zero_junction_rows` | TC-D70 | Edge | 70–79 |
| 35 | `test_witness_71_staff_firstorcreate_is_idempotent_at_data_layer` | TC-D71 | Edge | 70–79 |
| 36 | `test_witness_72_show_on_invalid_incident_id_returns_404` | TC-N72 | Edge | 70–79 |
| 37 | `test_witness_90_tenant_context_is_initialized` | TC-T90 | Tenancy | 90–99 |
| 38 | `test_witness_91_cross_tenant_direct_id_isolation` | TC-T91 | Tenancy | 90–99 |
| 39 | `test_witness_92_witness_id_is_stored_as_integer_no_free_text_surface` | TC-S92 | Security | 90–99 |
| 40 | `test_witness_93_witness_type_enum_rejects_arbitrary_value` | TC-S93 | Security | 90–99 |

**Totals:** 40 methods — Config 5 · Positive/Business 11 · Validation 6 · State/Defect 2 · Dependency 6 · Auth 5 · UI 2 · Edge 3 · Tenancy 2 · Security 3 (overlaps by band above). Defect-proving methods: 8 (across DATA-BA-WIT-01/05, BUG-BA-WIT-02/03/04, DOC-BA-001).
