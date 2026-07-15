# Categories & Criteria — Test Case List & Requirements (`bha_CategoryTcList_Require.md`)

**Module:** BehaviouralAssessment  •  **Feature / Screen:** Categories & Criteria (masters tab, screen `03-Categories*`)
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/03-Categories.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaCategoryController`
**FormRequest:** `Modules\BehaviouralAssessment\Http\Requests\BaCategoryRequest` (category header only; the criterion sub-grid is validated inline in the controller)
**Models:** `BaCategory` (`ba_categories`), `BaCriterion` (`ba_criteria`)
**DB scope:** TENANT-side (tenant_db, database-per-tenant, no `tenant_id` columns)
**Runtime tables:** `ba_categories`, `ba_criteria` — live `ba_` prefix (the DDL doc uses the stale `bha_` prefix; artifact filenames keep `bha_`; see DOC-BA-001)
**CRUD type:** CRUD-master Full (create / edit / show / soft-delete / restore / force-delete / toggle-status / reorder + nested criteria)
**Soft delete:** Yes (both tables) • **Activity log:** NONE (controller calls no `activityLog()` helper; no model observer — documented absence)
**Permission prefix:** `tenant.behavioural-assessment.categories.{viewAny|view|create|update|delete|restore|forceDelete|status}`

**Test file (single comprehensive suite):** `bha_Category_TestCas.php` — **55 test methods**, `php -l` clean.
**Generated:** 2026-Jul-11.

---

## 1. Business Conditions

### BC-DB — Schema / DDL / model configuration

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-DB-01 | `ba_categories` exists with columns `id, parent_id, name, description, polarity, weight, sort_order, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_categories |
| BC-DB-02 | Column types: `name` varchar(100), `polarity` enum(`negative`,`positive`), `weight` decimal(5,2) default 100.00, `sort_order` unsignedTinyInteger | DDL-ba_categories / migration |
| BC-DB-03 | `parent_id` self-FK → `ba_categories` `nullOnDelete` (SET NULL) | migration |
| BC-DB-04 | `ba_categories` uses `SoftDeletes`; model fillable, casts (`is_active`→boolean, `sort_order`→integer), relations `parent()/children()/criteria()`, scopes `active()/positive()/negative()` | Model |
| BC-DB-05 | `ba_criteria` exists with columns `id, category_id, name, description, weight, sort_order, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_criteria |
| BC-DB-06 | `ba_criteria.category_id` FK → `ba_categories` `cascadeOnDelete` | migration |
| BC-DB-07 | `ba_criteria` uses `SoftDeletes`; model fillable, relations `category()/ratings()` | Model |
| BC-DB-08 | Runtime prefix is `ba_`, NOT `bha_`; `bha_categories`/`bha_criteria` must NOT exist | Audit-DOC-BA-001 |
| BC-DB-09 | No `code` column on `ba_categories`/`ba_criteria` (requirement's Category/Criteria Code not implemented) | Audit-CAT-GAP-01 |
| BC-DB-10 | No `max_score` column on `ba_criteria` (requirement's Max Score not implemented) | Audit-CAT-GAP-02 |

### BC-VAL — Validation rules + messages

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-VAL-01 | `name` = required, string, max:100 | FormRequest `rules()` |
| BC-VAL-02 | `parent_id` = nullable, exists:ba_categories,id | FormRequest |
| BC-VAL-03 | `polarity` = required, `Rule::in(['positive','negative'])` | FormRequest |
| BC-VAL-04 | `weight` = required, numeric, min:0, max:100 (defaults to 100.00 via `prepareForValidation` when omitted) | FormRequest |
| BC-VAL-05 | `sort_order` = required, integer, min:0, max:255, `Rule::unique('ba_categories','sort_order')` scoped by `parent_id` | FormRequest |
| BC-VAL-06 | `sort_order.unique` custom message = `This sort order is already used for another category at the same level.` | FormRequest `messages()` |
| BC-VAL-07 | Criterion `name` = required, max:150 (inline in controller) | Controller `storeCriterion` |
| BC-VAL-08 | Whitespace-only `name` collapses to empty (TrimStrings) → required fails | Middleware + FormRequest |

### BC-AUTH — Permissions / authorization

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-AUTH-01 | Policy `BaCategoryPolicy` maps abilities `viewAny/view/create/update/delete/restore/forceDelete/status` to `tenant.behavioural-assessment.categories.{ability}` gate strings | Policy |
| BC-AUTH-02 | Guest (no session) is redirected to `/login` | auth middleware |
| BC-AUTH-03 | Limited (non-super-admin, unpermissioned) user → 403 on store (create permission) | Controller Gate |
| BC-AUTH-04 | Limited user → 403 on toggle-status (status permission) | Controller Gate |
| BC-AUTH-05 | Limited user → 403 on destroy (delete permission) | Controller Gate |
| BC-AUTH-06 | `BaCategoryRequest::authorize()` returns bare `true` (gate enforced only by controller) | Audit-SEC-BA-002 |

### BC-BIZ — Business rules / behaviour

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-BIZ-01 | Store persists category; `is_active` defaults true; `created_by`/`updated_by` = current user; redirect to `/behavioural-assessment/masters` with success flash | Controller `store` |
| BC-BIZ-02 | Omitted `weight` defaults to 100.00 | FormRequest `prepareForValidation` |
| BC-BIZ-03 | Update persists changed fields; `updated_by` = current user | Controller `update` |
| BC-BIZ-04 | Nested criterion store persists; `weight` cast decimal(2); `is_active` default true; `created_by` set | Controller `storeCriterion` |
| BC-BIZ-05 | Criterion `weight` defaults 1.00, `sort_order` defaults 0 when omitted | Controller |
| BC-BIZ-06 | Update & delete criterion endpoints work; delete is a soft-delete | Controller |
| BC-BIZ-07 | Show page renders category name, criteria and the `Category Identity` heading | Blade `show` |
| BC-BIZ-08 | Masters tab lists categories (with criteria) | Blade masters |
| BC-BIZ-09 | Self-referencing parent/child persists; `children()`/`parent()` relations resolve | Model |
| BC-BIZ-10 | Duplicate category `name` is ACCEPTED (no unique rule on name) | Audit-CAT-GAP-07 |
| BC-BIZ-11 | Sum of active criteria weightage is NOT enforced to 100% | Audit-CAT-GAP-03 |
| BC-BIZ-12 | `toggle-status` returns JSON `{success:true, is_active, message}` with `Category activated./deactivated.` | Controller `toggleStatus` |
| BC-BIZ-13 | `reorder` renumbers `sort_order` sequentially (0,1,…) and returns JSON `{success:true}` | Controller `reorder` |

### BC-SM — State machine (Active ↔ Inactive)

| BC ID | Transition | Source |
|-------|-----------|--------|
| BC-SM-01 | Active → (toggleStatus) → Inactive | Screen-SM-1 / Controller |
| BC-SM-02 | Inactive → (toggleStatus) → Active | Screen-SM-2 / Controller |
| BC-SM-03 | Deactivation is NOT blocked when criteria are attached (no guard; criteria `is_active` unchanged in grid) | Screen-SM / Controller (DATA-BA) |

### BC-REF / BC-INT — FK integrity & lifecycle

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | `destroy` soft-deletes, sets `is_active=false`, moves to trash | Controller `destroy` |
| BC-REF-02 | `restore` returns category to the default scope | Controller `restore` |
| BC-REF-03 | Force-delete removes the category and cascade-deletes its criteria (FK ON DELETE CASCADE) | migration |
| BC-REF-04 | Force-deleting a parent nulls children `parent_id` (FK ON DELETE SET NULL) | migration |
| BC-REF-05 | `destroyCriterion` blocks delete when ratings recorded (`Cannot delete this criterion because ratings have been recorded against it. Deactivate it instead.`); soft-deletes otherwise (`Criterion removed.`) | Controller `destroyCriterion` |
| BC-REF-06 | `destroy` has NO ratings/usage guard — a category with criteria is soft-deleted unconditionally | Audit-CAT-GAP-05 |
| BC-REF-07 | Full lifecycle create → toggle → delete → restore → force-delete is consistent | lifecycle |

### BC-EDG — Edge cases

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-EDG-01 | Invalid id → 404 on show/edit/toggle | route-model binding |
| BC-EDG-02 | Whitespace-only `name` rejected | TrimStrings |
| BC-EDG-03 | Criterion `weight` > 100 is ACCEPTED (endpoint has no max rule) | Audit-CAT-GAP-09 |
| BC-EDG-04 | Duplicate criterion `name` within a category is ACCEPTED (no unique rule) | Audit-CAT-GAP-08 |
| BC-EDG-05 | Active category with zero criteria is ACCEPTED (no minimum-criterion rule) | Audit-CAT-GAP-04 |

### BC-UIX — UI / UX

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-UIX-01 | Masters search filters by name | Blade/Controller |
| BC-UIX-02 | Masters polarity filter narrows results | Controller |
| BC-UIX-03 | Empty search shows `No categories found.` | Blade |
| BC-UIX-04 | Trash page renders trashed categories | Blade trash |
| BC-UIX-05 | Breadcrumb present: `Categories` on create, `Categories & Criteria` on show | Blade |

### BC-TEN / BC-SEC — Tenancy isolation & security

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-TEN-01 | Tenant context is initialized for tenant-side category operations | tenancy |
| BC-TEN-02 | Cross-tenant direct-ID isolation is provable (defensive; skipped when only one tenant) | security |
| BC-SEC-01 | `authorize()` returns bare `true` (SEC-BA-002) | Audit-SEC-BA-002 |
| BC-SEC-02 | Stored XSS in `name`/`description` is escaped (not executed) on the show page | Blade escaping |

---

## 2. Test Case List (one row per test method — mirrors `bha_Category_TestCas.php` 1:1)

**Legend:** Category — Positive (P), Negative (N), Dependency (D), State-Machine (SM), Tenancy (T), Security (S), Config/Schema (C).

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-C01 | C | BC-DB-01/02/03/04, BC-VAL-01..06 | DDL-ba_categories / FormRequest / Model | Migration, model, casts, scopes, FormRequest rule strings all correct | Schema/model/request truth holds | `test_category_01_migration_model_and_request_configuration_are_correct` | ✅ |
| TC-C02 | C | BC-DB-08 | Audit-DOC-BA-001 | Runtime prefix `ba_` present; `bha_*` absent; model binds `ba_*` | DOC-BA-001 divergence proven | `test_category_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | ✅ |
| TC-C03 | C | BC-DB-05/06/07 | DDL-ba_criteria / migration / Model | `ba_criteria` schema, FK cascade, model config correct | Criteria schema/model truth holds | `test_category_03_criteria_table_and_model_configuration_are_correct` | ✅ |
| TC-C04 | C | BC-DB-09/10 | Audit-CAT-GAP-01/02 | No `code`/`max_score` columns; commented `code` rule present | Gaps proven; no columns exist | `test_category_04_requirement_code_and_max_score_fields_are_not_implemented_cat_gap_01_02` | ✅ |
| TC-P10 | P | BC-BIZ-01 | Controller store | Create persists and redirects with success flash | Row created, defaults + audit cols set, redirect to masters | `test_category_10_create_persists_and_redirects_with_success_flash` | ✅ |
| TC-P11 | P | BC-BIZ-02, BC-VAL-04 | FormRequest | Omitted weight defaults to 100.00 | Not 422; weight = 100.00 | `test_category_11_weight_defaults_to_100_via_prepare_for_validation` | ✅ |
| TC-P12 | P | BC-BIZ-03 | Controller update | Update persists changes | Fields updated; `updated_by` set | `test_category_12_update_persists_changes` | ✅ |
| TC-P13 | P | BC-BIZ-04 | Controller storeCriterion | Nested criterion store persists | Criterion created; weight cast; audit col set | `test_category_13_store_criterion_via_nested_endpoint_persists` | ✅ |
| TC-P14 | P | BC-BIZ-05 | Controller | Criterion weight/sort_order default when omitted | weight=1.00, sort_order=0 | `test_category_14_criterion_weight_and_sort_order_default_when_omitted` | ✅ |
| TC-P15 | P | BC-BIZ-06 | Controller | Update & delete criterion endpoints work | Rename persists; soft-delete removes | `test_category_15_update_and_delete_criterion_endpoints_work` | ✅ |
| TC-P15b | P | BC-BIZ-07 | Blade show | Show page renders category and criteria | Sees name, criterion, `Category Identity` | `test_category_15b_show_page_renders_category_and_criteria` | ✅ |
| TC-P16 | P | BC-BIZ-08 | Blade masters | Masters tab lists categories with criteria | Category name visible | `test_category_16_masters_tab_lists_categories_with_criteria_count` | ✅ |
| TC-P17 | P | BC-BIZ-09 | Model | Parent/child self-reference persists | `parent_id` set; relations resolve | `test_category_17_parent_child_self_reference_persists` | ✅ |
| TC-N18 | N | BC-BIZ-10 | Audit-CAT-GAP-07 | Duplicate category name allowed | Not 422; ≥2 rows co-exist | `test_category_18_duplicate_category_name_is_allowed_cat_gap_07` | ✅ |
| TC-N19 | N | BC-BIZ-11 | Audit-CAT-GAP-03 | Criteria weightage sum not enforced to 100 | Sum 80 accepted | `test_category_19_criteria_weightage_sum_not_enforced_to_100_cat_gap_03` | ✅ |
| TC-SM20 | SM | BC-SM-01/02 | Screen-SM | Active↔Inactive transition succeeds | Toggle flips `is_active` both ways | `test_category_20_active_to_inactive_and_back_transition_succeeds` | ✅ |
| TC-SM21 | SM | BC-SM-03 | Controller | Deactivation not blocked when criteria referenced | Deactivated; criteria `is_active` unchanged | `test_category_21_deactivation_not_blocked_when_criteria_referenced_data_ba` | ✅ |
| TC-N30 | N | BC-VAL-01/03/04/05 | FormRequest | Required fields rejected | 422 with errors for name/polarity/weight/sort_order | `test_category_30_required_fields_are_rejected` | ✅ |
| TC-N31 | N | BC-VAL-01 | FormRequest | `name` max:100 enforced | 422 name error at 101 chars | `test_category_31_name_max_length_100_is_enforced` | ✅ |
| TC-N32 | N | BC-VAL-03 | FormRequest | `polarity` must be in allowed set | 422 polarity error for `neutral` | `test_category_32_polarity_must_be_in_allowed_set` | ✅ |
| TC-N33 | N | BC-VAL-04 | FormRequest | `weight` numeric/min:0/max:100 | 422 for 150, -1, `abc` | `test_category_33_weight_must_be_numeric_min_0_max_100` | ✅ |
| TC-N34 | N | BC-VAL-05 | FormRequest | `sort_order` integer/min:0/max:255 | 422 for 300 and -1 | `test_category_34_sort_order_must_be_integer_min_0_max_255` | ✅ |
| TC-N35 | N | BC-VAL-05 | FormRequest | Duplicate `sort_order` same parent rejected | 422 sort_order error | `test_category_35_duplicate_sort_order_same_parent_level_is_rejected` | ✅ |
| TC-P36 | P | BC-VAL-05 | FormRequest | Same `sort_order` allowed under a different parent | Not 422 (unique scoped by parent_id) | `test_category_36_same_sort_order_allowed_under_different_parent_level` | ✅ |
| TC-N37 | N | BC-VAL-06 | FormRequest messages | `sort_order.unique` message exact | Exact custom message returned | `test_category_37_sort_order_unique_message_is_exact` | ✅ |
| TC-N38 | N | BC-VAL-02 | FormRequest | `parent_id` must exist | 422 parent_id error for non-existent id | `test_category_38_parent_id_must_exist_in_ba_categories` | ✅ |
| TC-N39 | N | BC-VAL-07 | Controller | Criterion name required and capped at 150 | 422 for empty and 151-char name | `test_category_39_store_criterion_name_is_required_and_capped_at_150` | ✅ |
| TC-D40 | D | BC-REF-01 | Controller destroy | Delete soft-deletes, sets inactive, moves to trash | Hidden from default scope; trashed & inactive | `test_category_40_delete_soft_deletes_sets_inactive_and_moves_to_trash` | ✅ |
| TC-D41 | D | BC-REF-02 | Controller restore | Restore reactivates visibility | Returns to default scope | `test_category_41_restore_from_trash_reactivates_visibility` | ✅ |
| TC-D42 | D | BC-REF-03 | migration | Force-delete removes category and cascades criteria | Both physically removed | `test_category_42_force_delete_removes_category_and_cascades_criteria` | ✅ |
| TC-D43 | D | BC-REF-04 | migration | Force-deleting parent nulls children | Child `parent_id` = null | `test_category_43_force_deleting_parent_sets_null_on_children` | ✅ |
| TC-D44 | D | BC-REF-05 | Controller destroyCriterion | Criterion delete blocked when rated, allowed otherwise | Unrated soft-deleted; guard string present | `test_category_44_criterion_delete_is_blocked_when_ratings_recorded_and_allowed_otherwise` | ✅ |
| TC-D45 | D | BC-REF-06 | Audit-CAT-GAP-05 | Category soft-delete not blocked when criteria present | Soft-deleted unconditionally | `test_category_45_category_soft_delete_not_blocked_when_criteria_present_cat_gap_05` | ✅ |
| TC-D46 | D | BC-REF-07 | lifecycle | Full lifecycle create/toggle/delete/restore/force-delete | Each stage consistent | `test_category_46_full_lifecycle_create_toggle_delete_restore_force_delete` | ✅ |
| TC-N50 | N | BC-AUTH-02 | auth middleware | Guest redirected to login | Path contains `/login` | `test_category_50_guest_is_redirected_to_login` | ✅ |
| TC-N51 | N | BC-AUTH-03 | Controller Gate | Limited user without create permission → 403 | 403 on store | `test_category_51_limited_user_without_create_permission_gets_403` | ✅ |
| TC-N52 | N | BC-AUTH-04 | Controller Gate | Limited user without status permission → 403 | 403 on toggle | `test_category_52_limited_user_without_status_permission_gets_403_on_toggle` | ✅ |
| TC-N53 | N | BC-AUTH-05 | Controller Gate | Limited user without delete permission → 403 | 403 on destroy | `test_category_53_limited_user_without_delete_permission_gets_403_on_destroy` | ✅ |
| TC-P54 | P | BC-AUTH-01 | Policy | Policy methods map to permission strings | All 8 gate strings present | `test_category_54_policy_methods_map_to_permission_strings` | ✅ |
| TC-P55 | P | BC-BIZ-12 | Controller toggleStatus | Toggle endpoint updates `is_active` and returns JSON | `success`, `is_active`, exact messages | `test_category_55_status_toggle_endpoint_updates_is_active_and_returns_json` | ✅ |
| TC-P56 | P | BC-BIZ-13 | Controller reorder | Reorder endpoint updates `sort_order` | JSON success; sort_order 0,1 applied | `test_category_56_reorder_endpoint_updates_sort_order` | ✅ |
| TC-P60 | P | BC-UIX-01 | Blade/Controller | Masters search filters by name | Matching category visible | `test_category_60_masters_search_filters_by_name` | ✅ |
| TC-P61 | P | BC-UIX-02 | Controller | Polarity filter narrows results | Negative category visible under filter | `test_category_61_masters_polarity_filter_narrows_results` | ✅ |
| TC-P62 | P | BC-UIX-03 | Blade | Empty-state message when no match | Sees `No categories found.` | `test_category_62_empty_state_message_when_search_matches_nothing` | ✅ |
| TC-P63 | P | BC-UIX-04 | Blade trash | Trash page renders | Trashed category visible | `test_category_63_trash_page_renders` | ✅ |
| TC-P64 | P | BC-UIX-05 | Blade | Breadcrumb present on create and show | Sees `Categories` / `Categories & Criteria` | `test_category_64_breadcrumb_present_on_create_and_show_pages` | ✅ |
| TC-N70 | N | BC-EDG-01 | route binding | Invalid id returns 404 | 404 on show/edit/toggle | `test_category_70_invalid_id_returns_404` | ✅ |
| TC-N71 | N | BC-EDG-02 | TrimStrings | Whitespace-only name rejected | 422 name error | `test_category_71_whitespace_only_name_is_rejected` | ✅ |
| TC-N72 | N | BC-EDG-03 | Audit-CAT-GAP-09 | Criterion weight > 100 accepted | 250 persists (no max) | `test_category_72_criterion_weight_over_100_is_accepted_cat_gap_09` | ✅ |
| TC-N73 | N | BC-EDG-04 | Audit-CAT-GAP-08 | Duplicate criterion name within category accepted | ≥2 same-name criteria | `test_category_73_duplicate_criterion_name_within_category_is_allowed_cat_gap_08` | ✅ |
| TC-N74 | N | BC-EDG-05 | Audit-CAT-GAP-04 | Active category without any criterion accepted | Active, 0 criteria | `test_category_74_active_category_without_any_criterion_is_allowed_cat_gap_04` | ✅ |
| TC-T90 | T | BC-TEN-01 | tenancy | Tenant context initialized | Tenancy initialized; table present | `test_category_90_tenant_context_is_initialized` | ✅ |
| TC-T91 | T | BC-TEN-02 | security | Cross-tenant direct-ID isolation | Second tenant proven or skipped | `test_category_91_cross_tenant_direct_id_isolation` | ✅ |
| TC-S92 | S | BC-SEC-01 | Audit-SEC-BA-002 | FormRequest authorize returns true | Regex match on `return true` | `test_category_92_form_request_authorize_returns_true_sec_ba_002` | ✅ |
| TC-S93 | S | BC-SEC-02 | Blade escaping | Stored XSS in name/description not executed on show | Escaped payloads absent from source | `test_category_93_stored_xss_in_name_and_description_not_executed_on_show` | ✅ |

**Totals:** 55 test cases ↔ 55 test methods (1:1). Positive 19 · Negative 21 · Dependency 7 · State-Machine 2 · Tenancy 2 · Security 2 · Config/Schema 4 (the two SM rows also assert positive transition behaviour).

---

## 3. Test Method Index (band map)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_category_01_...configuration_are_correct` | TC-C01 | Schema/Config | 01–09 |
| 2 | `test_category_02_..._doc_ba_001` | TC-C02 | Schema/Config | 01–09 |
| 3 | `test_category_03_criteria_table_and_model_configuration_are_correct` | TC-C03 | Schema/Config | 01–09 |
| 4 | `test_category_04_..._cat_gap_01_02` | TC-C04 | Schema/Config | 01–09 |
| 5 | `test_category_10_create_persists_and_redirects_with_success_flash` | TC-P10 | Business | 10–19 |
| 6 | `test_category_11_weight_defaults_to_100_via_prepare_for_validation` | TC-P11 | Business | 10–19 |
| 7 | `test_category_12_update_persists_changes` | TC-P12 | Business | 10–19 |
| 8 | `test_category_13_store_criterion_via_nested_endpoint_persists` | TC-P13 | Business | 10–19 |
| 9 | `test_category_14_criterion_weight_and_sort_order_default_when_omitted` | TC-P14 | Business | 10–19 |
| 10 | `test_category_15_update_and_delete_criterion_endpoints_work` | TC-P15 | Business | 10–19 |
| 11 | `test_category_15b_show_page_renders_category_and_criteria` | TC-P15b | Business | 10–19 |
| 12 | `test_category_16_masters_tab_lists_categories_with_criteria_count` | TC-P16 | Business | 10–19 |
| 13 | `test_category_17_parent_child_self_reference_persists` | TC-P17 | Business | 10–19 |
| 14 | `test_category_18_duplicate_category_name_is_allowed_cat_gap_07` | TC-N18 | Business/Gap | 10–19 |
| 15 | `test_category_19_criteria_weightage_sum_not_enforced_to_100_cat_gap_03` | TC-N19 | Business/Gap | 10–19 |
| 16 | `test_category_20_active_to_inactive_and_back_transition_succeeds` | TC-SM20 | State-Machine | 20–29 |
| 17 | `test_category_21_deactivation_not_blocked_when_criteria_referenced_data_ba` | TC-SM21 | State-Machine | 20–29 |
| 18 | `test_category_30_required_fields_are_rejected` | TC-N30 | Validation | 30–39 |
| 19 | `test_category_31_name_max_length_100_is_enforced` | TC-N31 | Validation | 30–39 |
| 20 | `test_category_32_polarity_must_be_in_allowed_set` | TC-N32 | Validation | 30–39 |
| 21 | `test_category_33_weight_must_be_numeric_min_0_max_100` | TC-N33 | Validation | 30–39 |
| 22 | `test_category_34_sort_order_must_be_integer_min_0_max_255` | TC-N34 | Validation | 30–39 |
| 23 | `test_category_35_duplicate_sort_order_same_parent_level_is_rejected` | TC-N35 | Validation | 30–39 |
| 24 | `test_category_36_same_sort_order_allowed_under_different_parent_level` | TC-P36 | Validation | 30–39 |
| 25 | `test_category_37_sort_order_unique_message_is_exact` | TC-N37 | Validation | 30–39 |
| 26 | `test_category_38_parent_id_must_exist_in_ba_categories` | TC-N38 | Validation | 30–39 |
| 27 | `test_category_39_store_criterion_name_is_required_and_capped_at_150` | TC-N39 | Validation | 30–39 |
| 28 | `test_category_40_delete_soft_deletes_sets_inactive_and_moves_to_trash` | TC-D40 | Integration/FK | 40–49 |
| 29 | `test_category_41_restore_from_trash_reactivates_visibility` | TC-D41 | Integration/FK | 40–49 |
| 30 | `test_category_42_force_delete_removes_category_and_cascades_criteria` | TC-D42 | Integration/FK | 40–49 |
| 31 | `test_category_43_force_deleting_parent_sets_null_on_children` | TC-D43 | Integration/FK | 40–49 |
| 32 | `test_category_44_criterion_delete_is_blocked_when_ratings_recorded_and_allowed_otherwise` | TC-D44 | Integration/FK | 40–49 |
| 33 | `test_category_45_category_soft_delete_not_blocked_when_criteria_present_cat_gap_05` | TC-D45 | Integration/Gap | 40–49 |
| 34 | `test_category_46_full_lifecycle_create_toggle_delete_restore_force_delete` | TC-D46 | Integration/FK | 40–49 |
| 35 | `test_category_50_guest_is_redirected_to_login` | TC-N50 | Permissions | 50–59 |
| 36 | `test_category_51_limited_user_without_create_permission_gets_403` | TC-N51 | Permissions | 50–59 |
| 37 | `test_category_52_limited_user_without_status_permission_gets_403_on_toggle` | TC-N52 | Permissions | 50–59 |
| 38 | `test_category_53_limited_user_without_delete_permission_gets_403_on_destroy` | TC-N53 | Permissions | 50–59 |
| 39 | `test_category_54_policy_methods_map_to_permission_strings` | TC-P54 | Permissions | 50–59 |
| 40 | `test_category_55_status_toggle_endpoint_updates_is_active_and_returns_json` | TC-P55 | Permissions/API | 50–59 |
| 41 | `test_category_56_reorder_endpoint_updates_sort_order` | TC-P56 | Permissions/API | 50–59 |
| 42 | `test_category_60_masters_search_filters_by_name` | TC-P60 | UI/UX | 60–69 |
| 43 | `test_category_61_masters_polarity_filter_narrows_results` | TC-P61 | UI/UX | 60–69 |
| 44 | `test_category_62_empty_state_message_when_search_matches_nothing` | TC-P62 | UI/UX | 60–69 |
| 45 | `test_category_63_trash_page_renders` | TC-P63 | UI/UX | 60–69 |
| 46 | `test_category_64_breadcrumb_present_on_create_and_show_pages` | TC-P64 | UI/UX | 60–69 |
| 47 | `test_category_70_invalid_id_returns_404` | TC-N70 | Edge | 70–79 |
| 48 | `test_category_71_whitespace_only_name_is_rejected` | TC-N71 | Edge | 70–79 |
| 49 | `test_category_72_criterion_weight_over_100_is_accepted_cat_gap_09` | TC-N72 | Edge/Gap | 70–79 |
| 50 | `test_category_73_duplicate_criterion_name_within_category_is_allowed_cat_gap_08` | TC-N73 | Edge/Gap | 70–79 |
| 51 | `test_category_74_active_category_without_any_criterion_is_allowed_cat_gap_04` | TC-N74 | Edge/Gap | 70–79 |
| 52 | `test_category_90_tenant_context_is_initialized` | TC-T90 | Tenancy | 90–99 |
| 53 | `test_category_91_cross_tenant_direct_id_isolation` | TC-T91 | Tenancy | 90–99 |
| 54 | `test_category_92_form_request_authorize_returns_true_sec_ba_002` | TC-S92 | Security | 90–99 |
| 55 | `test_category_93_stored_xss_in_name_and_description_not_executed_on_show` | TC-S93 | Security | 90–99 |

---

## 4. Known Source Defects (audit-equivalent `CAT-GAP-*` / `DOC-BA-*` / `SEC-BA-*`)

| ID | Description | Proving test |
|----|-------------|--------------|
| DOC-BA-001 | DDL doc prefix `bha_` diverges from live runtime `ba_` | `test_category_02` |
| SEC-BA-002 | `BaCategoryRequest::authorize()` returns bare `true` (mitigated by controller Gate) | `test_category_92` |
| CAT-GAP-01 | Required unique Category/Criteria `code` not implemented (no column; rule commented) | `test_category_04` |
| CAT-GAP-02 | Required per-criterion `max_score` not implemented (no column) | `test_category_04` |
| CAT-GAP-03 | Sum of active criteria weightage not enforced to 100% | `test_category_19` |
| CAT-GAP-04 | Active category may have zero active criteria | `test_category_74` |
| CAT-GAP-05 | `destroy()` has no ratings guard — category soft-deleted unconditionally | `test_category_45` |
| CAT-GAP-07 | Category `name` uniqueness not enforced | `test_category_18` |
| CAT-GAP-08 | Criterion `name` uniqueness within a category not enforced | `test_category_73` |
| CAT-GAP-09 | Criterion `weight` has no max (values > 100 accepted) | `test_category_72` |
