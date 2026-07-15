# Interventions — Test Case List & Requirements (`bha_InterventionTcList_Require.md`)

**Module:** BehaviouralAssessment (BHA)
**Feature / Screen:** Intervention (masters tab — screen `04-Interventions*`)
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/04-Interventions.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaInterventionController`
**FormRequest:** `Modules\BehaviouralAssessment\Http\Requests\BaInterventionRequest`
**Policy:** `Modules\BehaviouralAssessment\Policies\BaInterventionPolicy`
**Model:** `Modules\BehaviouralAssessment\Models\BaIntervention`
**Primary table:** `ba_interventions` (live `ba_` prefix — the DDL doc uses the stale `bha_`; see DOC-BA-001)
**Junction:** `ba_incident_intervention_jnt` (`intervention_id` → `ba_interventions`, `ON DELETE RESTRICT`)
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant, no `tenant_id` columns)
**CRUD type:** Full CRUD master (create / edit / show / list / toggle-status / soft-delete / trash / restore / force-delete)
**Soft delete:** Yes (`deleted_at`)
**Activity log:** NONE — controller calls no `activityLog()` helper and the model has no logging observer (documented absence)
**Permission prefix:** `tenant.behavioural-assessment.interventions.{viewAny|view|create|update|delete|restore|forceDelete|status}`
**Test file:** `bha_Intervention_TestCas.php` — single comprehensive Dusk suite, **48 test methods**, class `bha_Intervention_TestCas extends DuskTestCase`, namespace `Tests\Browser`.

> This document mirrors the committed test file 1:1. Every method in `bha_Intervention_TestCas.php` appears as exactly one row in §3, and every row maps back to a Business Condition below.

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: `DDL-ba_interventions`)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-DB-01 | Table `ba_interventions` exists with columns `id, name, description, intervention_type, sort_order, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_interventions |
| BC-DB-02 | `name` = `VARCHAR(100)`; `intervention_type` = `ENUM('reward','corrective','counselling')`; `sort_order` = `TINYINT UNSIGNED`; `is_active` = `TINYINT`(boolean cast) | DDL-ba_interventions |
| BC-DB-03 | Soft-delete column `deleted_at` present; model uses the `SoftDeletes` trait | DDL-ba_interventions |
| BC-DB-04 | Migration `2026_06_16_130615_create_ba_interventions_table.php` defines `name`(100), the `intervention_type` enum, `unsignedTinyInteger('sort_order')`, `softDeletes()` | Migration |
| BC-DB-05 | Model config: `getTable()='ba_interventions'`; `$fillable` = name/description/intervention_type/sort_order/is_active/created_by/updated_by; `is_active` cast `boolean`; `incidents()` is `BelongsToMany`; `active()` scope filters `is_active=1` | Model |
| BC-DB-06 | Live runtime table uses `ba_` prefix; the DDL-spec name `bha_interventions` does NOT exist at runtime (**DOC-BA-001** divergence) | Audit-DOC-BA-001 |
| BC-DB-07 | Requirement columns `code` (unique capitalized) and `escalation_level` (Level 1/2/3) are **not** implemented — no such columns (**INT-GAP-01 / INT-GAP-03**) | Audit-INT-GAP-01/03 |

### BC-VAL — Validation rules + error messages (Source: `BaInterventionRequest`)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-VAL-01 | `name` required, `max:100` | Screen-VR-1 / Request |
| BC-VAL-02 | `intervention_type` required, `Rule::in(['reward','corrective','counselling'])` — requirement labels {Supportive,Corrective,Reinforcement} are NOT accepted (**INT-GAP-02**) | Screen-VR-2 / Audit-INT-GAP-02 |
| BC-VAL-03 | `sort_order` required, integer, `min:0`, `max:255`, `Rule::unique('ba_interventions','sort_order')` scoped to `whereNull(deleted_at)` | Screen-VR-3 / Request |
| BC-VAL-04 | Duplicate `sort_order` message is exactly `This sort order is already used by another intervention.` | Request `messages()` |
| BC-VAL-05 | `is_active` defaults to `true` via `prepareForValidation()` when absent | Request |
| BC-VAL-06 | `description` is nullable with no max — requirement says required (max 500) (**VAL-BA-003** divergence) | Audit-VAL-BA-003 |
| BC-VAL-07 | Whitespace-only `name` is trimmed by TrimStrings → fails `required` | Request + framework |

### BC-AUTH — Permissions / authorization (Source: `BaInterventionPolicy` + Controller gates)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-AUTH-01 | Guest is redirected to `/login` on any intervention route | Screen-PM |
| BC-AUTH-02 | User without `...interventions.create` gets 403 on store | Screen-PM / Policy |
| BC-AUTH-03 | User without `...interventions.status` gets 403 on toggle-status | Screen-PM / Policy |
| BC-AUTH-04 | User without `...interventions.delete` gets 403 on destroy | Screen-PM / Policy |
| BC-AUTH-05 | Policy methods `viewAny/view/create/update/delete/restore/forceDelete/status` each map to the `tenant.behavioural-assessment.interventions.{ability}` gate string | Policy |
| BC-AUTH-06 | `BaInterventionRequest::authorize()` returns bare `true`, mitigated by the controller `Gate::authorize` (**SEC-BA-002**) | Audit-SEC-BA-002 |

### BC-BIZ — Business logic (Source: Controller + Screen requirement)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-BIZ-01 | Create persists the row and redirects to `/behavioural-assessment/masters` with success flash | Screen-BR-1 |
| BC-BIZ-02 | On create, `created_by` and `updated_by` are stamped with the acting admin id | Screen-BR-2 |
| BC-BIZ-03 | Update persists changed fields and stamps `updated_by` | Screen-BR-3 |
| BC-BIZ-04 | Show page renders the intervention (name, description, "Intervention Name" label) | Screen-BR-4 |
| BC-BIZ-05 | Masters tab lists interventions | Screen-BR-5 |
| BC-BIZ-06 | Duplicate intervention **names** are accepted — no unique rule on `name` (**BUG-BA-010**); only `sort_order` is unique | Audit-BUG-BA-010 |
| BC-BIZ-07 | Toggle-status endpoint returns JSON `{success, is_active, message}` with messages `Intervention deactivated.` / `Intervention activated.` | Controller |
| BC-BIZ-08 | Masters search filters by name | Screen-BR-6 |
| BC-BIZ-09 | Masters `intervention_type` filter narrows results | Screen-BR-7 |

### BC-SM — State machine (Active ↔ Inactive) (Source: Screen state machine)

| BC ID | Transition | Source |
|-------|-----------|--------|
| BC-SM-01 | Active → (toggleStatus) → Inactive, and Inactive → (toggleStatus) → Active (both legal) | Screen-SM-1/2 |
| BC-SM-02 | An intervention linked to an open incident SHOULD be undeactivatable ("Deactivation Protections") — implementation performs no guard (**DATA-BA-002**) | Audit-DATA-BA-002 |

### BC-REF / BC-INT — Referential integrity & lifecycle (Source: DDL FKs + Model observer)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | `destroy()` sets `is_active=false` then soft-deletes → row hidden from default scope, present in trash | Controller / DDL |
| BC-REF-02 | Restore returns the row to the default scope | Controller |
| BC-REF-03 | Force-delete physically removes the row | Controller |
| BC-REF-04 | Junction FK `ba_incident_intervention_jnt.intervention_id → ba_interventions` is `ON DELETE RESTRICT` (or `NO ACTION`) | DDL |
| BC-INT-01 | An in-use intervention (linked in the junction) is still soft-deletable — BR-BA-030 not enforced (**BUG-BA-005**) | Audit-BUG-BA-005 |
| BC-INT-02 | Model `booted()` deleting-hook detaches junction rows on `isForceDeleting()`, circumventing the DB RESTRICT FK (**INT-OBS-01**) | Audit-INT-OBS-01 |
| BC-REF-06 | Full lifecycle create→toggle→delete→restore→force-delete succeeds end to end | Screen-BR / Controller |

### BC-EDG — Edge cases (Source: Screen edge cases + DDL limits)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-EDG-01 | Invalid id on show/edit/toggle returns 404 | Req-Edge |
| BC-EDG-02 | `sort_order` boundary 255 (TINYINT UNSIGNED max / Rule `max:255`) is accepted when free | DDL-ba_interventions |
| BC-EDG-03 | Duplicate `sort_order` becomes reusable after the holder is soft-deleted (unique scoped `whereNull(deleted_at)`) | Request |

### BC-T / BC-S — Tenancy & security (Source: platform)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-T-01 | Tenant context is initialized for tenant-side intervention tests | Platform |
| BC-T-02 | Cross-tenant direct-ID isolation (second tenant not visible) | Platform |
| BC-S-01 | Stored XSS in `description` is escaped by Blade on show | Security |
| BC-S-02 | Stored XSS in `name` is escaped by Blade on show | Security |

---

## 2. Known Source Defects (audit-equivalent `BUG-BA-###` / gap IDs)

| Defect ID | Description | Proving method |
|-----------|-------------|----------------|
| DOC-BA-001 | DDL doc prefix `bha_` diverges from live `ba_` | `test_intervention_02` |
| BUG-BA-010 | Duplicate intervention names accepted (no unique rule on `name`) | `test_intervention_16` |
| DATA-BA-002 | "Deactivation Protections" not enforced — linked intervention still deactivatable | `test_intervention_21` |
| VAL-BA-003 | Description required (max 500) in requirement, but implementation is nullable/no-max | `test_intervention_39` |
| BUG-BA-005 | BR-BA-030 not enforced — in-use intervention still soft-deletable | `test_intervention_43` |
| INT-GAP-01 | "Intervention Code" (unique capitalized) specced but not implemented (commented-out dead code) | `test_intervention_03` |
| INT-GAP-02 | Requirement type set {Supportive,Corrective,Reinforcement} diverges from impl {reward,corrective,counselling} | `test_intervention_01` / `_32` |
| INT-GAP-03 | "Escalation Level" (Level 1/2/3) specced but not implemented | `test_intervention_03` |
| SEC-BA-002 | `FormRequest::authorize()` returns bare `true` (mitigated by controller Gate) | `test_intervention_92` |
| INT-OBS-01 | Model observer detaches junction rows on force-delete, working around DB RESTRICT | `test_intervention_45` |

---

## 3. Test Case List — one row per test method (48)

**Legend — Category:** `Config`=schema/config truth, `P`=positive, `N`=negative, `D`=dependency, `SM`=state machine, `AUTH`=authorization, `UI`=UI/UX, `EDG`=edge, `T`=tenancy, `S`=security.

| # | TC ID | Test Method | Category | BC | Source | Description → Expected |
|---|-------|-------------|----------|----|--------|------------------------|
| 1 | TC-C01 | `test_intervention_01_migration_model_and_request_configuration_are_correct` | Config | BC-DB-01..05, BC-VAL-01..05 | DDL-ba_interventions | Schema/columns/enum, migration text, FormRequest rule strings, model config & `active()` scope all correct |
| 2 | TC-C02 | `test_intervention_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | Config | BC-DB-06 | Audit-DOC-BA-001 | `ba_interventions` exists; `bha_interventions` does NOT → DOC-BA-001 proven |
| 3 | TC-C03 | `test_intervention_03_code_and_escalation_level_specced_but_not_implemented_int_gap_01_03` | Config | BC-DB-07 | Audit-INT-GAP-01/03 | No `code` / `escalation_level` columns; code rule remains commented-out dead code |
| 4 | TC-P01 | `test_intervention_10_create_persists_and_redirects_with_success_flash` | P | BC-BIZ-01/02 | Screen-BR-1 | Create persists row, redirects to masters, stamps created/updated_by |
| 5 | TC-P02 | `test_intervention_11_is_active_defaults_true_via_prepare_for_validation` | P | BC-VAL-05 | Request | Omitted `is_active` defaults to true |
| 6 | TC-P03 | `test_intervention_12_update_persists_changes` | P | BC-BIZ-03 | Screen-BR-3 | Update persists name/type and stamps `updated_by` |
| 7 | TC-P04 | `test_intervention_13_show_page_renders_intervention` | P | BC-BIZ-04 | Screen-BR-4 | Show page renders name + description + label |
| 8 | TC-P05 | `test_intervention_14_masters_tab_lists_interventions` | P | BC-BIZ-05 | Screen-BR-5 | Masters tab lists the created intervention |
| 9 | TC-P06 | `test_intervention_15_store_stamps_created_and_updated_by` | P | BC-BIZ-02 | Screen-BR-2 | Store stamps both audit columns with admin id |
| 10 | TC-N01 | `test_intervention_16_duplicate_name_is_allowed_bug_ba_010` | N (defect) | BC-BIZ-06 | Audit-BUG-BA-010 | Duplicate name accepted (≥2 co-exist) — BUG-BA-010 |
| 11 | TC-SM01 | `test_intervention_20_active_to_inactive_and_back_transition_succeeds` | SM | BC-SM-01 | Screen-SM-1/2 | Toggle Active→Inactive→Active both succeed (200) |
| 12 | TC-SM02 | `test_intervention_21_deactivation_not_blocked_when_linked_to_incident_data_ba_002` | SM/D (defect) | BC-SM-02 | Audit-DATA-BA-002 | Linked intervention still deactivatable — DATA-BA-002 |
| 13 | TC-N02 | `test_intervention_30_required_fields_are_rejected` | N | BC-VAL-01/02/03 | Request | Empty name/type/sort_order → 422 with per-field errors |
| 14 | TC-N03 | `test_intervention_31_name_max_length_100_is_enforced` | N | BC-VAL-01 | Request | 101-char name → 422 |
| 15 | TC-N04 | `test_intervention_32_intervention_type_must_be_in_allowed_set` | N | BC-VAL-02 | Audit-INT-GAP-02 | Supportive/Reinforcement/symbolic → 422 (only reward/corrective/counselling valid) |
| 16 | TC-N05 | `test_intervention_33_sort_order_required_and_integer` | N | BC-VAL-03 | Request | Non-integer sort_order → 422 |
| 17 | TC-N06 | `test_intervention_34_sort_order_min_0_is_enforced` | N | BC-VAL-03 | Request | `-1` → 422 |
| 18 | TC-N07 | `test_intervention_35_sort_order_max_255_is_enforced` | N | BC-VAL-03 | Request | `256` → 422 |
| 19 | TC-N08 | `test_intervention_36_duplicate_sort_order_is_rejected_scoped_to_non_deleted` | N | BC-VAL-03 | Request | Duplicate active sort_order → 422 |
| 20 | TC-D01 | `test_intervention_37_duplicate_sort_order_allowed_after_soft_delete` | D (B) | BC-EDG-03 | Request | Soft-deleted holder frees the sort_order for reuse |
| 21 | TC-N09 | `test_intervention_38_duplicate_sort_order_error_message_is_exact` | N | BC-VAL-04 | Request | Exact message `This sort order is already used by another intervention.` |
| 22 | TC-N10 | `test_intervention_39_description_is_optional_diverges_from_requirement_val_ba_003` | N (defect) | BC-VAL-06 | Audit-VAL-BA-003 | Omitted description accepted, persists null — VAL-BA-003 |
| 23 | TC-D02 | `test_intervention_40_delete_soft_deletes_sets_inactive_and_moves_to_trash` | D (B) | BC-REF-01 | Controller | destroy sets is_active=false, soft-deletes, appears in trash |
| 24 | TC-D03 | `test_intervention_41_restore_from_trash_returns_to_default_scope` | D (B) | BC-REF-02 | Controller | Restore returns row to default scope |
| 25 | TC-D04 | `test_intervention_42_force_delete_removes_intervention` | D (B) | BC-REF-03 | Controller | Force-delete physically removes row |
| 26 | TC-D05 | `test_intervention_43_in_use_intervention_soft_delete_is_not_blocked_bug_ba_005` | D (C, defect) | BC-INT-01 | Audit-BUG-BA-005 | In-use intervention still soft-deleted — BUG-BA-005 |
| 27 | TC-D06 | `test_intervention_44_junction_fk_to_intervention_is_restrict` | D (C) | BC-REF-04 | DDL | Junction FK is RESTRICT/NO ACTION |
| 28 | TC-D07 | `test_intervention_45_force_delete_detaches_junction_via_observer_int_obs_01` | D (C, defect) | BC-INT-02 | Audit-INT-OBS-01 | Observer detaches junction rows on force-delete — INT-OBS-01 |
| 29 | TC-D08 | `test_intervention_46_full_lifecycle_create_toggle_delete_restore_force_delete` | D (F) | BC-REF-06 | Controller | Full lifecycle end-to-end succeeds |
| 30 | TC-N11 | `test_intervention_50_guest_is_redirected_to_login` | N/AUTH | BC-AUTH-01 | Screen-PM | Guest → redirect to `/login` |
| 31 | TC-N12 | `test_intervention_51_limited_user_without_create_permission_gets_403` | AUTH | BC-AUTH-02 | Policy | Limited user store → 403 |
| 32 | TC-N13 | `test_intervention_52_limited_user_without_status_permission_gets_403_on_toggle` | AUTH | BC-AUTH-03 | Policy | Limited user toggle → 403 |
| 33 | TC-N14 | `test_intervention_53_limited_user_without_delete_permission_gets_403_on_destroy` | AUTH | BC-AUTH-04 | Policy | Limited user destroy → 403 |
| 34 | TC-P07 | `test_intervention_54_policy_methods_map_to_permission_strings` | AUTH | BC-AUTH-05 | Policy | Policy source contains each gate string |
| 35 | TC-P08 | `test_intervention_55_status_toggle_endpoint_updates_is_active_and_returns_json` | P | BC-BIZ-07 | Controller | Toggle returns JSON success + exact messages |
| 36 | TC-P09 | `test_intervention_60_masters_search_filters_by_name` | UI/P | BC-BIZ-08 | Screen-BR-6 | Search finds the intervention by name |
| 37 | TC-P10 | `test_intervention_61_masters_type_filter_narrows_results` | UI/P | BC-BIZ-09 | Screen-BR-7 | Type filter narrows to reward rows |
| 38 | TC-N15 | `test_intervention_62_empty_state_message_when_search_matches_nothing` | UI/N | BC-BIZ-08 | Screen-BR-6 | Non-matching search shows `No interventions found.` |
| 39 | TC-P11 | `test_intervention_63_trash_page_renders` | UI | BC-REF-01 | Controller | Trash page renders a soft-deleted row |
| 40 | TC-P12 | `test_intervention_64_breadcrumb_present_on_create_and_show_pages` | UI | BC-BIZ-04 | Blade | Breadcrumb "Interventions"/"Intervention" present |
| 41 | TC-N16 | `test_intervention_70_invalid_id_returns_404` | EDG/N | BC-EDG-01 | Req-Edge | show/edit/toggle on missing id → 404 |
| 42 | TC-P13 | `test_intervention_71_sort_order_boundary_255_is_accepted` | EDG/P | BC-EDG-02 | DDL | sort_order 255 accepted at boundary |
| 43 | TC-N17 | `test_intervention_72_whitespace_only_name_is_rejected` | EDG/N | BC-VAL-07 | Request | Whitespace name trimmed → required fails (422) |
| 44 | TC-T01 | `test_intervention_90_tenant_context_is_initialized` | T | BC-T-01 | Platform | Tenancy initialized; table present |
| 45 | TC-T02 | `test_intervention_91_cross_tenant_direct_id_isolation` | T | BC-T-02 | Platform | Second tenant present for isolation (skips if single-tenant env) |
| 46 | TC-S01 | `test_intervention_92_form_request_authorize_returns_true_sec_ba_002` | S (defect) | BC-AUTH-06 | Audit-SEC-BA-002 | `authorize()` returns bare true — SEC-BA-002 |
| 47 | TC-S02 | `test_intervention_93_stored_xss_in_description_not_executed_on_show` | S | BC-S-01 | Security | Stored XSS in description escaped on show |
| 48 | TC-S03 | `test_intervention_94_stored_xss_in_name_escaped_on_show` | S | BC-S-02 | Security | Stored XSS in name escaped on show |

---

## 4. Test Method Index (by semantic band)

| Band | Range | Methods | Category |
|------|-------|---------|----------|
| 01–09 | Schema / DDL / model / request config | `_01`, `_02`, `_03` | Config truth (incl. DOC-BA-001, INT-GAP-01/03) |
| 10–19 | Business rules (`BC-BIZ`) | `_10`–`_16` | Create/update/show/list/stamp + BUG-BA-010 |
| 20–29 | State machine (`BC-SM`) | `_20`, `_21` | Active↔Inactive + DATA-BA-002 |
| 30–39 | Validation + messages (`BC-VAL`) | `_30`–`_39` | Required/length/range/enum/duplicate/exact-message + VAL-BA-003 |
| 40–49 | Integration / FK (`BC-INT/REF`) | `_40`–`_46` | Soft-delete/restore/force-delete/RESTRICT/observer/lifecycle + BUG-BA-005, INT-OBS-01 |
| 50–59 | Permissions (`BC-AUTH`) | `_50`–`_55` | Guest/403 x3/policy-map/toggle-json |
| 60–69 | UI/UX | `_60`–`_64` | Search/type-filter/empty-state/trash/breadcrumb |
| 70–79 | Edge cases (`BC-EDG`) | `_70`–`_72` | 404 / boundary-255 / whitespace |
| 90–99 | Tenancy + security | `_90`–`_94` | Tenant-init/isolation/SEC-BA-002/XSS x2 |

**Total methods: 48** — Config 3 · Positive 13 · Negative 17 · Dependency 8 · State-machine 2 · Tenancy 2 · Security 3 (categories overlap where a method proves both a defect and a rule).
