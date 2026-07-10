# BehaviouralAssessment › Category — Test Case List & Business Conditions

**Module:** BehaviouralAssessment · **Feature:** Category (+ child Criteria) · **Prefix:** `bha_` (filenames) / `ba_` (live tables)
**Screen requirement:** `2-Module_Requirement_V1/BehaviouralAssessment_v2/03-Categories.md`
**Primary tables:** `ba_categories` (+ child `ba_criteria`) · **DB scope:** tenant-side
**Controller:** `BaCategoryController` · **FormRequest:** `BaCategoryRequest` · **Policy:** `BaCategoryPolicy`
**Test style:** browser Dusk (`extends DuskTestCase`) — mirrors committed sibling `CategoryCrudTest.php` + `RatingScale` artifacts.

> **PREFIX / DOC-BA-001:** the consolidated DDL doc names tables `bha_*`, but the running app uses `ba_*`. Artifact filenames + PHP class names use `bha_`; every schema/FK assertion targets the real `ba_categories` / `ba_criteria`. Each suite includes the proving test `assertTrue(Schema::hasTable('ba_categories'))` + `assertFalse(Schema::hasTable('bha_categories'))`.

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: DDL / live migration `2026_06_16_130614` + `_130620`)
| BC | Fact | Source |
|----|------|--------|
| BC-DB-01 | `ba_categories` has id, parent_id, name, description, polarity, weight, sort_order, is_active, created_by, updated_by, timestamps, deleted_at | DDL-ba_categories |
| BC-DB-02 | `polarity` ENUM order is `['negative','positive']`; `weight` DECIMAL(5,2) default 100.00; `sort_order` UNSIGNED TINYINT (0–255); `is_active` boolean default true | DDL-ba_categories |
| BC-DB-03 | `ba_criteria` has id, category_id, name, description, weight, sort_order, is_active, created_by, updated_by, timestamps, deleted_at | DDL-ba_criteria |
| BC-DB-04 | NOT NULL: name, polarity, sort_order, created_by, updated_by (weight has default; parent_id, description nullable) | DDL-ba_categories |
| BC-DB-05 | `parent_id` + `description` are nullable | DDL-ba_categories |
| BC-DB-06 | Model `$fillable` = parent_id, name, description, polarity, weight, sort_order, is_active, created_by, updated_by; casts weight `decimal:2`, sort_order/parent_id `integer`, is_active `boolean` | Model BaCategory |
| BC-DB-07 | Both models use `SoftDeletes` | Model BaCategory/BaCriterion |

### BC-VAL — Validation rules + messages (Source: `BaCategoryRequest`)
| BC | Rule | Message / behaviour | Source |
|----|------|---------------------|--------|
| BC-VAL-01 | `name` required, string, max:100 | Laravel default | Screen-VR-1 / Request:23 |
| BC-VAL-02 | `polarity` required, `Rule::in(['positive','negative'])` | Laravel default | Screen-VR / Request:25 |
| BC-VAL-03 | `parent_id` nullable, `exists:ba_categories,id` | Laravel default | Request:24 |
| BC-VAL-04 | `weight` required, numeric, min:0, max:100 | Laravel default | Request:26 |
| BC-VAL-05 | `sort_order` required, integer, min:0, max:255 | Laravel default | Request:27-37 |
| BC-VAL-06 | `sort_order` unique per (parent_id) among non-deleted rows | "This sort order is already used for another category at the same level." | Screen-BR / Request:32-37,56 |
| BC-VAL-07 | `description` nullable string; `is_active` nullable boolean | — | Request:38-39 |
| BC-VAL-08 | prepareForValidation: parent_id → int|null; weight default 100.00; is_active default true | — | Request:43-51 |
| BC-VAL-09 | Criterion (inline in controller): name required max:150; weight nullable numeric min:0; sort_order nullable integer min:0 | Laravel default | Controller@storeCriterion:148-153 |

### BC-AUTH — Permission gates (Source: `BaCategoryController` Gate::authorize + `BaCategoryPolicy`)
| BC | Gate | Method | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `tenant.behavioural-assessment.categories.viewAny` | index/trashed | Screen-PM / Controller:21,90 |
| BC-AUTH-02 | `…categories.create` | create/store | Controller:27,35 |
| BC-AUTH-03 | `…categories.view` | show | Controller:48 |
| BC-AUTH-04 | `…categories.update` | edit/update/reorder/storeCriterion/updateCriterion | Controller:56,65,137,147,171 |
| BC-AUTH-05 | `…categories.delete` | destroy/destroyCriterion | Controller:76,192 |
| BC-AUTH-06 | `…categories.status` | toggleStatus | Controller:122 |
| BC-AUTH-07 | `…categories.restore` / `…forceDelete` | restore / forceDelete | Controller:100,111 |
| BC-AUTH-08 | web routes behind `InitializeTenancyByDomain → … → auth → verified`; guest → `/login` | RouteServiceProvider | Audit §5 |

### BC-BIZ — Business logic / behaviour (Source: Controller / Blade / Screen)
| BC | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | store() creates category, sets created_by/updated_by=auth id; flash "Category created successfully." | Controller:33-43 |
| BC-BIZ-02 | update() flash "Category updated successfully." | Controller:63-71 |
| BC-BIZ-03 | destroy() sets is_active=false, then soft-deletes; flash "Category moved to trash." | Controller:74-86 |
| BC-BIZ-04 | restore() flash "Category restored successfully."; forceDelete() flash "Category permanently deleted." | Controller:98-118 |
| BC-BIZ-05 | storeCriterion() flash "Criterion added." (default weight 1.00, sort_order 0) | Controller:145-167 |
| BC-BIZ-06 | updateCriterion() flash "Criterion updated."; destroyCriterion() flash "Criterion removed." | Controller:169-196 |
| BC-BIZ-07 | reorder() sets sort_order = array index for each id in `order[]`; JSON {success:true} | Controller:135-143 |
| BC-BIZ-08 | masters() lists categories with `withCount('criteria')`, paginated `cat_page` (15/pg); search by name; polarity filter | DashboardController:158-166 |
| BC-BIZ-09 | show page ("Category Details") renders identity + Associated Criteria grid; empty → "No criteria configured for this category." | Blade show |

### BC-SM — Status & soft-delete lifecycle (Source: Controller + status-switch component)
| BC | State → Trigger → Next state | Source |
|----|------------------------------|--------|
| BC-SM-01 | Active → toggle-status → Inactive (and back) via `.status-toggle` → `categories/{category}/toggle-status`; JSON message 'Category activated.' / 'Category deactivated.' | Screen-SM / Controller:120-133 |
| BC-SM-02 | Present → destroy → Trashed (is_active forced false first) | Controller:74-86 |
| BC-SM-03 | Trashed → restore → Present | Controller:98-107 |
| BC-SM-04 | Trashed → forceDelete → Gone (DB cascade removes `ba_criteria` rows) | Controller:109-118 / FK cascadeOnDelete |

### BC-REF / BC-INT — Referential integrity (Source: DDL FKs / relationships)
| BC | Relationship / FK | onDelete | Source |
|----|-------------------|----------|--------|
| BC-REF-01 | `ba_criteria.category_id` → `ba_categories.id` | CASCADE (hard delete) | DDL-ba_criteria FK |
| BC-REF-02 | `ba_categories.parent_id` → `ba_categories.id` (self-ref) | SET NULL (nullOnDelete) | DDL-ba_categories FK |
| BC-REF-03 | `BaCategory::criteria()` HasMany; `BaCriterion::category()` BelongsTo | — | Models |
| BC-INT-01 | `BaCriterion::ratings()` → `ba_assessment_ratings.criterion_id` (cross-screen: Ratings/09) | — | Model / Screen-IP-3 |
| BC-INT-02 | Category consumed by Class-Mapping (05) + Ratings grid (09); inactive categories hidden there | Screen-BR / Screen-IP |

### BC-AUTO — Cross-module auto-updates
| BC | Fact | Source |
|----|------|--------|
| BC-AUTO-01 | No model observers/events on BaCategory/BaCriterion (no auto-cascade on soft-delete) — see BUG-BA-006 | Models (none) / Audit-BUG-BA-006 |

### BC-EDG — Edge / boundary
| BC | Fact | Source |
|----|------|--------|
| BC-EDG-01 | `sort_order` may be reused after a soft-delete — no DB unique index; FormRequest unique is `deleted_at`-scoped (DATA-BA-003 mitigated for categories) | Audit-DATA-BA-003 / migration |
| BC-EDG-02 | `weight` DECIMAL(5,2) boundaries 0.00 / 100.00 persist | DDL |
| BC-EDG-03 | `description` TEXT accepts long content | DDL |
| BC-EDG-04 | No self-parent / cycle guard — FormRequest only checks `exists` (permissive) | Request:24 |

### BC-CFG — Tenancy / configuration
| BC | Fact | Source |
|----|------|--------|
| BC-CFG-01 | Tenant-per-database; no `tenant_id` column on `ba_categories`; requires initialized tenant | DDL header "Database: tenant_db" |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Schema | BC-DB-01/02/06/07 | DDL | ba_categories schema+model+casts; DOC-BA-001 | Columns/casts/relations correct; `ba_` exists, `bha_` not | 01 | 01 | Ready |
| TC-P02 | Schema | BC-DB-03, BC-REF-01 | DDL | ba_criteria schema + FK cascade + model | Columns/FK/relations correct | 02 | 02 | Ready |
| TC-P03 | Schema | BC-DB-06 | Model | fillable + relationships + scopes | active/positive scopes filter | — | 03 | Ready |
| TC-P04 | Schema | BC-DB-05 | DDL | nullable parent_id/description accept null | Saves with nulls | 04 | 06 | Ready |
| TC-P10 | CRUD | BC-BIZ-01 | Controller | create page loads + sections | Category Identity/Configuration/Save Category | 10 | — | Ready |
| TC-P11 | CRUD | BC-BIZ-01 | Controller | create submission persists | Row saved, polarity correct | 11 | 10 | Ready |
| TC-P12 | CRUD | BC-VAL-08 | Request | is_active defaults true | is_active=true | — | 11 | Ready |
| TC-P13 | CRUD | BC-BIZ-09 | Blade | show page displays data | Category Details + Associated Criteria | 12 | 12 | Ready |
| TC-P14 | CRUD | BC-BIZ-02 | Controller | edit update + flash | "Category updated successfully." | 13 | 13 | Ready |
| TC-P15 | Criteria | BC-BIZ-05 | Controller | add criterion persists | "Criterion added." + row | 16 | 14 | Ready |
| TC-P16 | Criteria | BC-BIZ-06 | Controller | update criterion persists | Name updated | — | 15 | Ready |
| TC-P17 | Criteria | BC-BIZ-06 | Controller | remove criterion soft-deletes | Trashed, hidden from default scope | — | 16 | Ready |
| TC-P18 | Reorder | BC-BIZ-07 | Controller | reorder endpoint updates sort_order | JSON success; sort_order=index | 22 | 17 | Ready |
| TC-P19 | Hierarchy | BC-REF-02/03 | Model | child belongs to parent | parent/children resolve | — | 18 | Ready |
| TC-P20 | UI | BC-BIZ-08 | Blade | masters list shows category | Row visible | — | 60 | Ready |
| TC-P21 | UI | BC-BIZ-08 | Controller | search by name filters | Only match shown | — | 61 | Ready |
| TC-P22 | UI | BC-BIZ-08 | Controller | polarity filter narrows list | Negative-only shown | — | 62 | Ready |
| TC-P23 | UI | BC-BIZ-03 | Blade | trash page lists soft-deleted | Deleted At + name | 20 | 63 | Ready |
| TC-P24 | UI | BC-BIZ-08 | Blade | masters breadcrumb same-tab nav | No new window | 21 | — | Ready |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-SM01 | BC-SM-01 | Controller | toggle active→inactive (UI) | is_active flips false | 14 | 20 |
| TC-SM02 | BC-SM-01 | Controller | toggle endpoint JSON payload | {success, message} | — | 21 |
| TC-SM03 | BC-SM-02 | Controller | destroy deactivates then soft-deletes | Trashed + inactive | — | 22 |
| TC-SM04 | BC-SM-03 | Controller | restore from trash | Present again | 15 | 23 |
| TC-SM05 | BC-SM-04 | FK | force-delete cascades criteria | Criteria rows gone | 15 | 24 |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-DB-04 | DDL | DB rejects missing required (name/polarity/sort_order[/created_by/updated_by]) | 23000/NOT NULL | 03 | 05 | Ready |
| TC-N02 | BC-VAL-* | Request | rules() literal strings present | Rules verified | — | 04 | Ready |
| TC-N30 | BC-VAL-01 | Request | required fields block insert (empty form) | alert-danger, no row | — | 30 | Ready |
| TC-N31 | BC-VAL-01 | Request | name > max:100 rejected | alert-danger, no row | — | 31 | Ready |
| TC-N32 | BC-VAL-02 | Request | invalid polarity rejected | alert-danger, no row | 18 | 32 | Ready |
| TC-N33 | BC-VAL-04 | Request | weight > 100 rejected | alert-danger, no row | — | 33 | Ready |
| TC-N34 | BC-VAL-04 | Request | negative weight rejected | alert-danger, no row | — | 34 | Ready |
| TC-N35 | BC-VAL-05 | Request | sort_order > 255 rejected | alert-danger, no row | — | 35 | Ready |
| TC-N36 | BC-VAL-06 | Request | duplicate sort_order same level rejected + message | "…already used…at the same level." | 17 | 36 | Ready |
| TC-N37 | BC-VAL-03 | Request | nonexistent parent_id rejected | alert-danger, no row | — | 38 | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | F | BC-SM-02/03 | Controller | soft-delete → restore → force-delete lifecycle | Each transition holds | 15 | 22/23/24 | Ready |
| TC-D02 | B | BC-SM-03 | Controller | restore brings back | Present | 15 | 23 | Ready |
| TC-D03 | B | BC-REF-01 | FK | force-delete cascades criteria | Child rows removed | — | 24 | Ready |
| TC-D04 | G | BC-EDG-01 | Audit-DATA-BA-003 | sort_order reuse after soft-delete (mitigated) | Second create succeeds | — | 37 | Ready |
| TC-D05 | E | BC-REF-03 | Model | criterion belongs to category | Resolves to parent | — | 40 | Ready |
| TC-D06 | D | BC-REF-02 | FK | parent delete nullifies child.parent_id | SET NULL | — | 41 | Ready |
| TC-D07 | E | BC-REF-02 | Model | child ↔ parent hierarchy | belongs/children | — | 18 | Ready |
| TC-D08 | E | BC-INT-01 | Model | criterion.ratings() relationship (defensive) | HasMany + FK column | — | 42 | Ready |
| TC-D09 | F | BC-BIZ (BUG-BA-006) | Audit | soft-delete does NOT cascade to criteria | Criterion stays active | — | 70 | Ready |
| TC-D10 | C | BC-BIZ (BUG-BA-004) | Audit | criterion with ratings still deletable | Deletes with no guard | — | 71 | Ready |
| TC-D11 | G | BC-EDG-02 | DDL | weight boundary 0.00/100.00 persist | Persisted | — | 72 | Ready |
| TC-D12 | G | BC-EDG-03 | DDL | long description accepted | Persisted | — | 73 | Ready |
| TC-D13 | G | BC-EDG-04 | Request | self-parent not blocked (edge) | parent_id=id persists | — | 74 | Ready |

### Auth / Tenancy / Security (TC-S / TC-T)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-S01 | BC-AUTH-08 | Routes | guest → /login on create | redirect | 19 | 50 |
| TC-S02 | BC-AUTH-08 | Routes | guest → /login on masters | redirect | — | 51 |
| TC-S03 | BC-AUTH | Audit-SEC-BA-002 | FormRequest authorize() bare true | true + controller gate present | — | 52 |
| TC-S04 | BC-AUTH-02 | Controller | limited user blocked on create | 403 / no form | — | 53 |
| TC-S05 | BC-EDG-05 | Blade | stored XSS in name escaped on show | Script not executed | — | 91 |
| TC-S06 | BC-AUTH-03 | Controller | invalid id → no detail (findOrFail 404) | Detail not rendered | — | 92 |
| TC-T01 | BC-CFG-01 | DDL | runs inside initialized tenant; no tenant_id | Asserted | — | 90 |

### Known Source Defects (module IDs — proven with tests)
| ID | Sev | Defect | Proving test |
|----|-----|--------|--------------|
| DOC-BA-001 | Doc | DDL doc prefix `bha_` vs live `ba_` | V2 test_01 / test_02 (assertFalse bha_*) |
| BUG-BA-006 | P2 | Category soft-delete does NOT cascade to criteria (BR-BA-005) | V2 test_70 |
| BUG-BA-004 | P2 | Criterion with ratings still deletable (BR-BA-006) | V2 test_71 |
| SEC-BA-002 | P1 | FormRequest `authorize()` returns bare true | V2 test_52 |
| DATA-BA-003 | P2 | Soft-delete + UNIQUE recreate — **mitigated** for categories (no DB unique; deleted_at-scoped rule) | V2 test_37 |
| BUG-BA-012 | P3 | reorder() N+1 (one UPDATE per row) — functional | V2 test_17 |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_category_01_schema_and_model_configuration_are_correct | TC-P01, DOC-BA-001 | Schema | 01–09 |
| 2 | test_category_02_criteria_schema_fk_and_model | TC-P02, DOC-BA-001 | Schema | 01–09 |
| 3 | test_category_03_model_fillable_relationships_and_scopes | TC-P03 | Schema | 01–09 |
| 4 | test_category_04_form_request_rules_contain_expected_constraints | TC-N02 | Validation-config | 01–09 |
| 5 | test_category_05_db_rejects_each_missing_required_field | TC-N01 | Schema/NOT NULL | 01–09 |
| 6 | test_category_06_nullable_fields_accept_null | TC-P04 | Schema | 01–09 |
| 7 | test_category_10_create_valid_persists_row | TC-P11 | Business | 10–19 |
| 8 | test_category_11_is_active_defaults_true_when_absent | TC-P12 | Business | 10–19 |
| 9 | test_category_12_show_page_renders_category_and_criteria | TC-P13 | Business | 10–19 |
| 10 | test_category_13_edit_update_persists_and_flashes | TC-P14 | Business | 10–19 |
| 11 | test_category_14_add_criterion_persists | TC-P15 | Business | 10–19 |
| 12 | test_category_15_update_criterion_persists | TC-P16 | Business | 10–19 |
| 13 | test_category_16_remove_criterion_soft_deletes | TC-P17 | Business | 10–19 |
| 14 | test_category_17_reorder_endpoint_updates_sort_order | TC-P18, BUG-BA-012 | Business | 10–19 |
| 15 | test_category_18_child_category_belongs_to_parent | TC-D07/P19 | Business | 10–19 |
| 16 | test_category_20_toggle_status_active_inactive_cycle | TC-SM01 | State-machine | 20–29 |
| 17 | test_category_21_toggle_status_endpoint_returns_json_payload | TC-SM02 | State-machine | 20–29 |
| 18 | test_category_22_destroy_deactivates_then_soft_deletes | TC-SM03 | State-machine | 20–29 |
| 19 | test_category_23_restore_brings_back_from_trash | TC-SM04/D02 | State-machine | 20–29 |
| 20 | test_category_24_force_delete_cascades_criteria | TC-SM05/D03 | State-machine | 20–29 |
| 21 | test_category_30_required_fields_show_errors_and_block_insert | TC-N30 | Validation | 30–39 |
| 22 | test_category_31_name_exceeding_max_is_rejected | TC-N31 | Validation | 30–39 |
| 23 | test_category_32_polarity_out_of_enum_is_rejected | TC-N32 | Validation | 30–39 |
| 24 | test_category_33_weight_over_max_is_rejected | TC-N33 | Validation | 30–39 |
| 25 | test_category_34_negative_weight_is_rejected | TC-N34 | Validation | 30–39 |
| 26 | test_category_35_sort_order_over_max_is_rejected | TC-N35 | Validation | 30–39 |
| 27 | test_category_36_duplicate_sort_order_same_level_is_rejected | TC-N36 | Validation | 30–39 |
| 28 | test_category_37_sort_order_reused_after_soft_delete_data_ba_003_mitigated | TC-D04, DATA-BA-003 | Edge/Validation | 30–39 |
| 29 | test_category_38_nonexistent_parent_id_is_rejected | TC-N37 | Validation | 30–39 |
| 30 | test_category_40_criterion_belongs_to_its_category | TC-D05 | Integration/FK | 40–49 |
| 31 | test_category_41_parent_delete_nullifies_child_parent_id | TC-D06 | Integration/FK | 40–49 |
| 32 | test_category_42_criterion_ratings_relationship_is_defined | TC-D08 | Integration/FK | 40–49 |
| 33 | test_category_50_guest_redirected_to_login_on_create | TC-S01 | Permissions | 50–59 |
| 34 | test_category_51_guest_redirected_to_login_on_index | TC-S02 | Permissions | 50–59 |
| 35 | test_category_52_form_request_authorize_returns_true_sec_ba_002 | TC-S03, SEC-BA-002 | Permissions | 50–59 |
| 36 | test_category_53_user_without_permission_is_forbidden | TC-S04 | Permissions | 50–59 |
| 37 | test_category_60_masters_list_shows_created_category | TC-P20 | UI/UX | 60–69 |
| 38 | test_category_61_search_by_name_filters_list | TC-P21 | UI/UX | 60–69 |
| 39 | test_category_62_polarity_filter_narrows_list | TC-P22 | UI/UX | 60–69 |
| 40 | test_category_63_trash_page_lists_soft_deleted_category | TC-P23 | UI/UX | 60–69 |
| 41 | test_category_70_soft_delete_does_not_cascade_to_criteria_bug_ba_006 | TC-D09, BUG-BA-006 | Edge/Audit | 70–79 |
| 42 | test_category_71_criterion_with_ratings_still_deletable_bug_ba_004 | TC-D10, BUG-BA-004 | Edge/Audit | 70–79 |
| 43 | test_category_72_weight_boundary_values_persist | TC-D11 | Edge | 70–79 |
| 44 | test_category_73_long_description_is_accepted | TC-D12 | Edge | 70–79 |
| 45 | test_category_74_self_parent_is_not_blocked_at_model_layer | TC-D13 | Edge | 70–79 |
| 46 | test_category_90_runs_inside_initialized_tenant | TC-T01 | Tenancy | 90–99 |
| 47 | test_category_91_stored_xss_in_name_is_escaped_on_show | TC-S05 | Security | 90–99 |
| 48 | test_category_92_invalid_id_does_not_render_detail | TC-S06 | Security | 90–99 |

**V1 methods:** 17 · **V2 methods:** 48 · **Ratio:** 2.82× (≥ 2× gate met).
