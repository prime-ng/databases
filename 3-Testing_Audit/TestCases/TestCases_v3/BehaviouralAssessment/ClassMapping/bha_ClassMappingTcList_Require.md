# Behavioural Assessment — Class-Mapping — Test Case List & Requirements

**Screen requirement** : `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/05-Class-Mapping.md`
**Screen title / tab**  : `Class-Mapping` (setup page tab `class-mapping`, app alias `class-categories`)
**DB scope**            : TENANT-side (`tenant_db`, database-per-tenant, no `tenant_id` columns)
**Runtime table**       : `ba_class_category_jnt` (live `ba_` prefix — DDL doc uses the stale `bha_` name; see DOC-BA-001). Artifact filenames keep the `bha_` convention.
**Controller**          : `Modules\BehaviouralAssessment\Http\Controllers\BaClassCategoryController` (`store` / `toggleStatus` / `destroy`)
**FormRequest**         : `Modules\BehaviouralAssessment\Http\Requests\BaClassCategoryRequest`
**Listing controller**  : `BaDashboardController::setup()` → `/behavioural-assessment/setup?tab=class-mapping`
**Model**               : `Modules\BehaviouralAssessment\Models\BaClassCategoryJnt`
**Permission prefix**   : `tenant.behavioural-assessment.class-categories.{viewAny|view|create|update|delete|restore|forceDelete|status}` (viewing the tab additionally needs `tenant.behavioural-assessment.setup.viewAny`)
**Activity log**        : NONE — controller calls no `activityLog()` helper and the model has no observer (documented absence, proven in test _93)
**Test file**           : `bha_ClassMapping_TestCas.php` — ONE comprehensive Dusk suite, **44 methods** (no V1/V2 split)

---

## 1. Business Conditions

### BC-DB — Schema / model / migration truth

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-DB-1 | Table `ba_class_category_jnt` exists with columns `id, class_id, category_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_class_category_jnt |
| BC-DB-2 | `is_active` is TINYINT (cast to boolean); `class_id` / `category_id` are INT | DDL-ba_class_category_jnt |
| BC-DB-3 | Migration creates the table with unique `uq_ba_class_cat(class_id, category_id)`, FK `fk_ba_cc_class_id` → `sch_classes`, FK → `ba_categories`, and `softDeletes()` | Migration `2026_06_16_130618_create_ba_class_category_jnt_table` |
| BC-DB-4 | Model binds table `ba_class_category_jnt`, fillable `[class_id, category_id, is_active, created_by, updated_by]`, `is_active` cast boolean, `schoolClass()` & `category()` are BelongsTo | Model `BaClassCategoryJnt` |
| BC-DB-5 | Runtime prefix is `ba_`, NOT the DDL-doc `bha_` (DOC-BA-001) | Audit-DOC-BA-001 |
| BC-DB-6 | Model omits the `SoftDeletes` trait although the migration adds `deleted_at` (DATA-BA-CM-01) | Audit-DATA-BA-CM-01 |

### BC-BIZ — Business rules

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-BIZ-1 | `store()` creates a mapping and redirects with success flash "Category mapped to class successfully." | Controller `store`, Screen-BR |
| BC-BIZ-2 | `store()` defaults `is_active = true` and stamps `created_by` / `updated_by` = acting admin | Controller `store` |
| BC-BIZ-3 | `toggleStatus()` flips `is_active` and returns JSON `{success, is_active, message}` ("Mapping activated." / "Mapping deactivated.") | Controller `toggleStatus` |
| BC-BIZ-4 | `destroy()` removes the mapping and redirects back | Controller `destroy` |
| BC-BIZ-5 | The setup tab lists each mapping's class name + category name and a delete control | Blade `_class-mapping.blade.php` |
| BC-BIZ-6 | A category may be mapped to many classes, and a class may hold many categories; only the exact `(class_id, category_id)` pair is unique | Screen-BR, FormRequest unique rule |

### BC-SM — State machine (`is_active`)

| ID | State | Trigger | Next State | Source |
|----|-------|---------|-----------|--------|
| BC-SM-1 | Active | `toggleStatus()` | Inactive | Controller `toggleStatus` |
| BC-SM-2 | Inactive | `toggleStatus()` | Active | Controller `toggleStatus` |
| BC-SM-3 | (any) | `toggleStatus()` | `updated_by` stamped to acting admin | Controller `toggleStatus` |

### BC-VAL — Validation & error messages

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-VAL-1 | `class_id` required, integer, `exists:sch_classes,id` | FormRequest `rules()` |
| BC-VAL-2 | `category_id` required, integer, `exists:ba_categories,id` | FormRequest `rules()` |
| BC-VAL-3 | `(class_id, category_id)` unique via `Rule::unique('ba_class_category_jnt','category_id')->where(class_id)->whereNull('deleted_at')`; message "This category is already mapped to the selected class." | FormRequest `rules()`/`messages()` |
| BC-VAL-4 | Same category on a different class is allowed; different category on same class is allowed (scope = class_id + category_id) | FormRequest unique scope |
| BC-VAL-5 | Whitespace-only / null / non-integer values are rejected 422 | FormRequest `rules()` |

### BC-AUTH — Permissions

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-AUTH-1 | Guest is redirected to `/login` | Middleware |
| BC-AUTH-2 | `store` requires `...class-categories.create` (403 otherwise) | Controller Gate / Policy |
| BC-AUTH-3 | `toggleStatus` requires `...class-categories.status` (403 otherwise) | Controller Gate / Policy |
| BC-AUTH-4 | `destroy` requires `...class-categories.delete` (403 otherwise) | Controller Gate / Policy |
| BC-AUTH-5 | Setup tab requires `...setup.viewAny` (403 / redirect otherwise) | `BaDashboardController::setup` |
| BC-AUTH-6 | Policy maps all 8 abilities to the `tenant.behavioural-assessment.class-categories.*` gate strings | Policy `BaClassCategoryPolicy` |

### BC-REF / BC-INT — FK integrity

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-REF-1 | `class_id` FK → `sch_classes` is `ON DELETE CASCADE` | Migration |
| BC-REF-2 | `category_id` FK → `ba_categories` is `ON DELETE CASCADE` | Migration |
| BC-REF-3 | DB unique index `uq_ba_class_cat` covers `(class_id, category_id)` and does NOT scope `deleted_at` (diverges from request rule — VAL-BA-CM-02) | Migration / Audit-VAL-BA-CM-02 |

### BC-EDG — Edge cases

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-EDG-1 | `toggleStatus` / `destroy` on a non-existent id return 404 | Route-model binding |
| BC-EDG-2 | Client-supplied `is_active` / `created_by` / `updated_by` are ignored (mass-assignment safety) | Controller `store` |
| BC-EDG-3 | `destroy()` HARD-deletes (no SoftDeletes trait); `deleted_at` is never populated (DATA-BA-CM-01) | Audit-DATA-BA-CM-01 |

### BC-SEC / BC-AUTO / TC-T — Security, audit, tenancy

| ID | Business Condition | Source |
|----|--------------------|--------|
| BC-SEC-1 | FormRequest `authorize()` returns bare `true` (mitigated by controller Gate) — SEC-BA-002 | Audit-SEC-BA-002 |
| BC-AUTO-1 | NO activity log is written for mapping mutations (documented absence) | Controller / Model |
| BC-CFG-1 | FormRequest carries a non-POST (PUT/PATCH) rules branch, but no `update` route exists — dead branch (CM-GAP-03) | Audit-CM-GAP-03 |
| TC-T-1 | Tenant context is initialized; runtime table exists inside the tenant DB | stancl/tenancy |
| TC-T-2 | Cross-tenant direct-ID isolation is exercisable when a second tenant domain exists | stancl/tenancy |

---

## 2. Test Case List (mirrors the 44 methods in `bha_ClassMapping_TestCas.php`, 1:1)

### Positive / Business-rule cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Positive | BC-BIZ-1/2 | Controller `store` | Store creates mapping & redirects with success | Not 422; row exists; `is_active=true` | `test_class_mapping_10_store_creates_mapping_and_redirects_with_success` | ✅ |
| TC-P02 | Positive | BC-BIZ-2 | Controller `store` | Store stamps `created_by`/`updated_by` = admin | Both equal acting admin id | `test_class_mapping_11_store_stamps_created_and_updated_by_admin` | ✅ |
| TC-P03 | Positive | BC-BIZ-3 / BC-SM-1/2 | Controller `toggleStatus` | Toggle flips `is_active` & returns JSON | 200; `success=true`; message "Mapping deactivated."/"Mapping activated." | `test_class_mapping_12_toggle_status_flips_is_active_and_returns_json` | ✅ |
| TC-P04 | Positive | BC-BIZ-4 | Controller `destroy` | Destroy removes mapping & redirects | 200/302; row gone | `test_class_mapping_13_destroy_removes_mapping_and_redirects` | ✅ |
| TC-P05 | Positive | BC-BIZ-5 | Blade partial | Setup tab lists class + category names | Both names visible | `test_class_mapping_14_setup_tab_lists_mapping_class_and_category` | ✅ |
| TC-P06 | Positive | BC-BIZ-1 | Blade form | Browser form add shows success flash | Sees "Category mapped to class successfully."; row persisted | `test_class_mapping_15_browser_form_add_mapping_shows_success_flash` | ✅ |
| TC-P07 | Positive | BC-AUTH-4 / BC-BIZ-5 | Blade partial | Delete control rendered for permitted user | Page source contains `class-categories/{id}` | `test_class_mapping_16_delete_control_is_rendered_for_permitted_user` | ✅ |
| TC-P08 | Positive | BC-BIZ-1..4 | Controller | Full lifecycle create → toggle → destroy | Create OK; toggle off; row gone | `test_class_mapping_44_full_lifecycle_create_toggle_destroy` | ✅ |
| TC-P09 | Positive | BC-BIZ-5 | Blade partial | Setup tab renders form + table headers | Sees Add Mapping / Class / Category / Polarity | `test_class_mapping_60_setup_tab_renders_form_and_table_headers` | ✅ |
| TC-P10 | Positive | BC-BIZ-5 | Blade partial | Mapping row shows polarity badge | Sees ucfirst(polarity) | `test_class_mapping_61_mapping_row_shows_polarity_badge` | ✅ |
| TC-P11 | Positive | BC-BIZ-5 | Blade partial | Empty-state message defined in view | View contains "No class-category mappings yet." | `test_class_mapping_62_empty_state_message_is_defined_in_view` | ✅ |

### State-machine cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-SM01 | State-Machine | BC-SM-1/2 | Controller `toggleStatus` | Active↔Inactive round-trip | Off then back On | `test_class_mapping_20_active_to_inactive_and_back_transition_succeeds` | ✅ |
| TC-SM02 | State-Machine | BC-SM-3 | Controller `toggleStatus` | Toggle stamps `updated_by` | `updated_by` = admin id | `test_class_mapping_21_toggle_stamps_updated_by` | ✅ |

### Negative / validation cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Negative | BC-VAL-1/2 | FormRequest | Required fields rejected | 422; errors `class_id` & `category_id` | `test_class_mapping_30_required_fields_are_rejected` | ✅ |
| TC-N02 | Negative | BC-VAL-1 | FormRequest | `class_id` must exist in `sch_classes` | 422; error `class_id` | `test_class_mapping_31_class_id_must_exist_in_sch_classes` | ✅ |
| TC-N03 | Negative | BC-VAL-2 | FormRequest | `category_id` must exist in `ba_categories` | 422; error `category_id` | `test_class_mapping_32_category_id_must_exist_in_ba_categories` | ✅ |
| TC-N04 | Negative | BC-VAL-1 | FormRequest | `class_id` must be integer | 422; error `class_id` | `test_class_mapping_33_class_id_must_be_integer` | ✅ |
| TC-N05 | Negative | BC-VAL-2 | FormRequest | `category_id` must be integer | 422; error `category_id` | `test_class_mapping_34_category_id_must_be_integer` | ✅ |
| TC-N06 | Negative | BC-VAL-3 | FormRequest | Duplicate pair rejected w/ message | 422; custom message present | `test_class_mapping_35_duplicate_mapping_is_rejected_with_message` | ✅ |
| TC-N07 | Negative | BC-VAL-4 | FormRequest scope | Same category, different class allowed | Not 422 | `test_class_mapping_36_same_category_different_class_is_allowed` | ✅ |
| TC-N08 | Negative | BC-VAL-4 | FormRequest scope | Different category, same class allowed | Not 422 | `test_class_mapping_37_different_category_same_class_is_allowed` | ✅ |
| TC-N09 | Negative | BC-VAL-5 / BC-EDG | FormRequest | Whitespace-only `class_id` rejected | 422; error `class_id` | `test_class_mapping_38_whitespace_class_id_is_rejected` | ✅ |
| TC-N10 | Negative | BC-VAL-5 / BC-EDG | FormRequest | Null `category_id` rejected | 422; error `category_id` | `test_class_mapping_73_null_category_id_is_rejected` | ✅ |

### Dependency / FK / integrity cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | Dependency (FK) | BC-REF-1 | Migration | `class_id` FK ON DELETE CASCADE | DELETE_RULE contains CASCADE | `test_class_mapping_40_class_id_fk_is_cascade_on_delete` | ✅ |
| TC-D02 | Dependency (FK) | BC-REF-2 | Migration | `category_id` FK ON DELETE CASCADE | DELETE_RULE contains CASCADE | `test_class_mapping_41_category_id_fk_is_cascade_on_delete` | ✅ |
| TC-D03 | Dependency (index) | BC-REF-3 | Migration | Unique index enforces pair; no `deleted_at` in key (VAL-BA-CM-02) | UNIQUE `uq_ba_class_cat`; key = class_id+category_id | `test_class_mapping_42_unique_index_enforces_class_category_pair_val_ba_cm_02` | ✅ |
| TC-D04 | Dependency (data) | BC-EDG-3 | Controller `destroy` | Hard delete despite `deleted_at` column (DATA-BA-CM-01) | Row physically gone; no soft remnant | `test_class_mapping_43_destroy_hard_deletes_despite_deleted_at_column_data_ba_cm_01` | ✅ |

### Permission / authorization cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-A01 | Auth | BC-AUTH-1 | Middleware | Guest redirected to login | Path contains `/login` | `test_class_mapping_50_guest_is_redirected_to_login` | ✅ |
| TC-A02 | Auth | BC-AUTH-2 | Gate/Policy | Limited user (no create) → 403 on store | 403 | `test_class_mapping_51_limited_user_without_create_gets_403_on_store` | ✅ |
| TC-A03 | Auth | BC-AUTH-3 | Gate/Policy | Limited user (no status) → 403 on toggle | 403 | `test_class_mapping_52_limited_user_without_status_gets_403_on_toggle` | ✅ |
| TC-A04 | Auth | BC-AUTH-4 | Gate/Policy | Limited user (no delete) → 403 on destroy | 403 | `test_class_mapping_53_limited_user_without_delete_gets_403_on_destroy` | ✅ |
| TC-A05 | Auth | BC-AUTH-6 | Policy | Policy methods map to gate strings | All 8 abilities present in policy | `test_class_mapping_54_policy_methods_map_to_permission_strings` | ✅ |
| TC-A06 | Auth | BC-AUTH-5 | `setup()` | Setup tab requires `setup.viewAny` | 403 / 302 for limited user | `test_class_mapping_55_setup_tab_requires_setup_viewany_permission` | ✅ |

### Edge / security / mass-assignment cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-E01 | Edge | BC-EDG-1 | Route binding | Toggle invalid id → 404 | 404 | `test_class_mapping_70_toggle_invalid_id_returns_404` | ✅ |
| TC-E02 | Edge | BC-EDG-1 | Route binding | Destroy invalid id → 404 | 404 | `test_class_mapping_71_destroy_invalid_id_returns_404` | ✅ |
| TC-E03 | Edge / Security | BC-EDG-2 | Controller `store` | Client `is_active`/auditor overrides ignored | `is_active=true`; `created_by`=admin | `test_class_mapping_72_store_ignores_client_supplied_is_active_and_auditors` | ✅ |

### Schema / config-truth cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-C01 | Config-truth | BC-DB-1..4 | DDL/Model/Request | Migration, model & request configuration correct | Table/columns/fillable/casts/relations/rule strings verified | `test_class_mapping_01_migration_model_and_request_configuration_are_correct` | ✅ |
| TC-C02 | Config-truth | BC-DB-5 | Audit-DOC-BA-001 | Runtime prefix `ba_` diverges from DDL `bha_` | `ba_` table exists; `bha_` does not; model binds `ba_` | `test_class_mapping_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | ✅ |
| TC-C03 | Config-truth | BC-DB-6 | Audit-DATA-BA-CM-01 | Model omits SoftDeletes despite migration `softDeletes()` | `deleted_at` exists; trait absent | `test_class_mapping_03_model_omits_softdeletes_despite_migration_softdeletes_data_ba_cm_01` | ✅ |

### Tenancy / security-pack cases

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | TC-T-1 | tenancy | Tenant context initialized | `tenancy()->initialized` true; table exists | `test_class_mapping_90_tenant_context_is_initialized` | ✅ |
| TC-T02 | Tenancy | TC-T-2 | tenancy | Cross-tenant direct-ID isolation | Second tenant resolvable, else skip | `test_class_mapping_91_cross_tenant_direct_id_isolation` | ✅ |
| TC-S01 | Security | BC-SEC-1 | Audit-SEC-BA-002 | FormRequest `authorize()` returns bare true | Regex match confirms bare `return true;` | `test_class_mapping_92_form_request_authorize_returns_true_sec_ba_002` | ✅ |
| TC-S02 | Security / Audit | BC-AUTO-1 | Controller/Model | No activity log written for mutations | No `activityLog`; count unchanged | `test_class_mapping_93_no_activity_log_written_for_mapping_mutations` | ✅ |
| TC-S03 | Config-gap | BC-CFG-1 | Audit-CM-GAP-03 | Dead non-POST branch; no update route | `store`/`destroy` routes exist; `update` route absent | `test_class_mapping_94_form_request_has_dead_non_post_branch_cm_gap_03` | ✅ |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_class_mapping_01_migration_model_and_request_configuration_are_correct` | TC-C01 | Config-truth | 01–09 |
| 2 | `test_class_mapping_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | TC-C02 | Config-truth (DOC-BA-001) | 01–09 |
| 3 | `test_class_mapping_03_model_omits_softdeletes_despite_migration_softdeletes_data_ba_cm_01` | TC-C03 | Config-truth (DATA-BA-CM-01) | 01–09 |
| 4 | `test_class_mapping_10_store_creates_mapping_and_redirects_with_success` | TC-P01 | Business rule | 10–19 |
| 5 | `test_class_mapping_11_store_stamps_created_and_updated_by_admin` | TC-P02 | Business rule | 10–19 |
| 6 | `test_class_mapping_12_toggle_status_flips_is_active_and_returns_json` | TC-P03 | Business rule / SM | 10–19 |
| 7 | `test_class_mapping_13_destroy_removes_mapping_and_redirects` | TC-P04 | Business rule | 10–19 |
| 8 | `test_class_mapping_14_setup_tab_lists_mapping_class_and_category` | TC-P05 | Business rule / UI | 10–19 |
| 9 | `test_class_mapping_15_browser_form_add_mapping_shows_success_flash` | TC-P06 | Business rule / UI | 10–19 |
| 10 | `test_class_mapping_16_delete_control_is_rendered_for_permitted_user` | TC-P07 | Auth / UI | 10–19 |
| 11 | `test_class_mapping_20_active_to_inactive_and_back_transition_succeeds` | TC-SM01 | State machine | 20–29 |
| 12 | `test_class_mapping_21_toggle_stamps_updated_by` | TC-SM02 | State machine | 20–29 |
| 13 | `test_class_mapping_30_required_fields_are_rejected` | TC-N01 | Validation | 30–39 |
| 14 | `test_class_mapping_31_class_id_must_exist_in_sch_classes` | TC-N02 | Validation | 30–39 |
| 15 | `test_class_mapping_32_category_id_must_exist_in_ba_categories` | TC-N03 | Validation | 30–39 |
| 16 | `test_class_mapping_33_class_id_must_be_integer` | TC-N04 | Validation | 30–39 |
| 17 | `test_class_mapping_34_category_id_must_be_integer` | TC-N05 | Validation | 30–39 |
| 18 | `test_class_mapping_35_duplicate_mapping_is_rejected_with_message` | TC-N06 | Validation | 30–39 |
| 19 | `test_class_mapping_36_same_category_different_class_is_allowed` | TC-N07 | Validation / Business rule | 30–39 |
| 20 | `test_class_mapping_37_different_category_same_class_is_allowed` | TC-N08 | Validation / Business rule | 30–39 |
| 21 | `test_class_mapping_38_whitespace_class_id_is_rejected` | TC-N09 | Validation / Edge | 30–39 |
| 22 | `test_class_mapping_40_class_id_fk_is_cascade_on_delete` | TC-D01 | Dependency (FK) | 40–49 |
| 23 | `test_class_mapping_41_category_id_fk_is_cascade_on_delete` | TC-D02 | Dependency (FK) | 40–49 |
| 24 | `test_class_mapping_42_unique_index_enforces_class_category_pair_val_ba_cm_02` | TC-D03 | Dependency (index, VAL-BA-CM-02) | 40–49 |
| 25 | `test_class_mapping_43_destroy_hard_deletes_despite_deleted_at_column_data_ba_cm_01` | TC-D04 | Dependency (DATA-BA-CM-01) | 40–49 |
| 26 | `test_class_mapping_44_full_lifecycle_create_toggle_destroy` | TC-P08 | Business rule / lifecycle | 40–49 |
| 27 | `test_class_mapping_50_guest_is_redirected_to_login` | TC-A01 | Auth | 50–59 |
| 28 | `test_class_mapping_51_limited_user_without_create_gets_403_on_store` | TC-A02 | Auth | 50–59 |
| 29 | `test_class_mapping_52_limited_user_without_status_gets_403_on_toggle` | TC-A03 | Auth | 50–59 |
| 30 | `test_class_mapping_53_limited_user_without_delete_gets_403_on_destroy` | TC-A04 | Auth | 50–59 |
| 31 | `test_class_mapping_54_policy_methods_map_to_permission_strings` | TC-A05 | Auth | 50–59 |
| 32 | `test_class_mapping_55_setup_tab_requires_setup_viewany_permission` | TC-A06 | Auth | 50–59 |
| 33 | `test_class_mapping_60_setup_tab_renders_form_and_table_headers` | TC-P09 | UI/UX | 60–69 |
| 34 | `test_class_mapping_61_mapping_row_shows_polarity_badge` | TC-P10 | UI/UX | 60–69 |
| 35 | `test_class_mapping_62_empty_state_message_is_defined_in_view` | TC-P11 | UI/UX | 60–69 |
| 36 | `test_class_mapping_70_toggle_invalid_id_returns_404` | TC-E01 | Edge | 70–79 |
| 37 | `test_class_mapping_71_destroy_invalid_id_returns_404` | TC-E02 | Edge | 70–79 |
| 38 | `test_class_mapping_72_store_ignores_client_supplied_is_active_and_auditors` | TC-E03 | Edge / Security | 70–79 |
| 39 | `test_class_mapping_73_null_category_id_is_rejected` | TC-N10 | Validation / Edge | 70–79 |
| 40 | `test_class_mapping_90_tenant_context_is_initialized` | TC-T01 | Tenancy | 90–99 |
| 41 | `test_class_mapping_91_cross_tenant_direct_id_isolation` | TC-T02 | Tenancy | 90–99 |
| 42 | `test_class_mapping_92_form_request_authorize_returns_true_sec_ba_002` | TC-S01 | Security (SEC-BA-002) | 90–99 |
| 43 | `test_class_mapping_93_no_activity_log_written_for_mapping_mutations` | TC-S02 | Security / Audit | 90–99 |
| 44 | `test_class_mapping_94_form_request_has_dead_non_post_branch_cm_gap_03` | TC-S03 | Config-gap (CM-GAP-03) | 90–99 |

**Total: 44 test methods** across bands 01–99.

---

## 4. Known Source Defects (audit-equivalent `BUG-BA-*` / doc / gap)

| ID | Description | Proven by |
|----|-------------|-----------|
| DOC-BA-001 | DDL/registry spec prefix `bha_` diverges from the live runtime `ba_` table name | `test_..._02` |
| DATA-BA-CM-01 | Model `BaClassCategoryJnt` omits the `SoftDeletes` trait though the migration adds `softDeletes()`; `destroy()` HARD-deletes and `deleted_at` is never used; Policy `restore()`/`forceDelete()` are dead (no routes, no trait) | `test_..._03`, `test_..._43` |
| VAL-BA-CM-02 | DB unique index `uq_ba_class_cat(class_id, category_id)` has no `deleted_at` scope while the FormRequest unique rule does — divergent scopes (harmless only because of the hard delete) | `test_..._42` |
| SEC-BA-002 | FormRequest `authorize()` returns bare `true` (mitigated by the controller Gate) | `test_..._92` |
| CM-GAP-03 | FormRequest carries a non-POST (PUT/PATCH) rules branch, but no `update` route exists for class-categories — dead branch | `test_..._94` |
