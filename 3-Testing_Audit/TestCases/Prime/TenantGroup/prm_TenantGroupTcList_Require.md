# Tenant Group — Test Case List & Business Conditions (`prm_TenantGroupTcList_Require.md`)

- **Module:** Prime (PRM) — **DB scope: CENTRAL (`prime_db`)**, no tenant init. Host `http://127.0.0.1:8000`.
- **Feature / Screen:** TenantGroup
- **Primary table (DDL-verified prefix `prm_`):** `prm_tenant_groups`
- **Controller:** `Modules\Prime\Http\Controllers\TenantGroupController`
- **Request:** `Modules\Prime\Http\Requests\TenantGroupRequest`
- **Model:** `Modules\Prime\Models\TenantGroup` (SoftDeletes)
- **Activity sink (constraint #25):** `Modules\Prime\Models\ActivityLog` → `sys_central_activity_logs` (connection `mysql`)
- **Test file:** `prm_TenantGroup_TestCas.php` (single comprehensive suite — no V1/V2)

---

## 1. Business Conditions

### BC-DB (DDL — `prm_tenant_groups`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK AUTO_INCREMENT | DDL-prm_tenant_groups |
| BC-DB-02 | `code` VARCHAR(20) NOT NULL | DDL-prm_tenant_groups |
| BC-DB-03 | `short_name` VARCHAR(50) NOT NULL, UNIQUE `uq_tenantGroups_shortName` | DDL-prm_tenant_groups |
| BC-DB-04 | `name` VARCHAR(150) NOT NULL (no DB unique index) | DDL-prm_tenant_groups |
| BC-DB-05 | `address_1`,`address_2` VARCHAR(200) NULL | DDL-prm_tenant_groups |
| BC-DB-06 | `city_id` INT UNSIGNED NOT NULL, FK → `glb_cities(id)` ON DELETE RESTRICT | DDL-prm_tenant_groups |
| BC-DB-07 | `pincode` VARCHAR(10) NULL | DDL-prm_tenant_groups |
| BC-DB-08 | `website_url` VARCHAR(150) NULL | DDL-prm_tenant_groups |
| BC-DB-09 | `email` VARCHAR(100) NULL | DDL-prm_tenant_groups |
| BC-DB-10 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL-prm_tenant_groups |
| BC-DB-11 | `deleted_at` timestamp NULL — soft delete | DDL-prm_tenant_groups |

### BC-VAL (TenantGroupRequest::rules)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `code` required, string, max:20 | Request |
| BC-VAL-02 | `short_name` required, string, max:50, unique(prm_tenant_groups.short_name) ignore self | Request |
| BC-VAL-03 | `name` required, string, max:150, unique(prm_tenant_groups.name) ignore self | Request |
| BC-VAL-04 | `address_1`/`address_2` nullable, string, max:200 | Request |
| BC-VAL-05 | `city_id` required, exists:glb_cities,id | Request |
| BC-VAL-06 | `pincode` nullable, string, max:10 | Request |
| BC-VAL-07 | `website_url` nullable, url, max:150 | Request |
| BC-VAL-08 | `email` nullable, email, max:100 | Request |
| BC-VAL-09 | `is_active` boolean; `prepareForValidation` coerces checkbox `'on'`→true, absent→false | Request |

### BC-AUTH (Gate strings — TenantGroupController)
| ID | Gate | Methods | Source |
|----|------|---------|--------|
| BC-AUTH-01 | `prime.tenant-group.viewAny` | index | Controller |
| BC-AUTH-02 | `prime.tenant-group.create` | create, store | Controller + Request::authorize |
| BC-AUTH-03 | `prime.tenant-group.view` | show | Controller |
| BC-AUTH-04 | `prime.tenant-group.update` | edit, update, toggleStatus | Controller + Request::authorize |
| BC-AUTH-05 | `prime.tenant-group.delete` | destroy | Controller |
| BC-AUTH-06 | `prime.tenant-group.restore` | trashedTenantGroup, restore | Controller |
| BC-AUTH-07 | `prime.tenant-group.forceDelete` | forceDelete | Controller |
| BC-AUTH-08 | Super admin bypass requires `is_super_admin` **AND** `super_admin_flag` (or role `Super Admin`) | AppServiceProvider::boot Gate::before |

### BC-BIZ (Controller/Model — behaviour + activity events, LITERAL strings)
| ID | Behaviour | Event string | Source |
|----|-----------|--------------|--------|
| BC-BIZ-01 | store → `TenantGroup::create($request->validated())`, sends mail (if email), notifies super admins, logs, redirects to tenant-management `#tanent-group` | `created` | Controller::store |
| BC-BIZ-02 | destroy → sets `is_active=false`, soft-deletes, logs | `Trashed` | Controller::destroy |
| BC-BIZ-03 | restore → `restore()`, logs | `Restored` | Controller::restore |
| BC-BIZ-04 | forceDelete → permanent delete, logs | `Deleted` | Controller::forceDelete |
| BC-BIZ-05 | toggleStatus → validates `is_active` boolean, flips flag, returns JSON `{success,is_active,message}`, logs | `Toggled` | Controller::toggleStatus |
| BC-BIZ-06 | update → `$tenantGroup->update($request->validated())`, redirects; **writes NO activity log** | *(none)* | Controller::update |

### BC-REF / BC-INT (FK / cross-entity)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `city_id` → `glb_cities(id)` ON DELETE RESTRICT | DDL |
| BC-INT-01 | `prm_tenant.tenant_group_id` → `prm_tenant_groups(id)` ON DELETE RESTRICT (child tenants block parent force-delete) | DDL fk_tenant_tenantGroupId |
| BC-INT-02 | Model relationships: `city()` belongsTo, `tenants()` hasMany, `liveTenants()` hasMany filtered `tenant_type='live'` | Model |

### BC-EDG (edges)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Boundary max lengths (code=20, short_name=50, name=150, pincode=10) accepted | DDL/Request |
| BC-EDG-02 | Nullable optional fields accept empty strings | Request |
| BC-EDG-03 | Checkbox coercion (`on`→true, absent→false) | Request::prepareForValidation |

> **Tenancy note:** Prime is a single central DB; there is **no per-tenant isolation dimension** for this feature. `TC-T` (cross-tenant) is intentionally **N/A** and recorded as such in the Validation Report.

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB/VAL/AUTH | DDL/Request/Ctrl | Config truth (schema, model, request, gates, activity sink) | All asserts pass | test_01 | Automated |
| TC-P02 | BC-DB-03 | DDL | short_name unique index present; name has none | Index confirmed | test_02 | Automated |
| TC-P10 | BC-BIZ-01 | Ctrl | store creates + logs `created` | Row + activity | test_10 | Automated |
| TC-P11 | BC-BIZ-02 | Ctrl | destroy soft-deletes + is_active=false + logs `Trashed` | deleted_at set | test_11 | Automated |
| TC-P12 | BC-BIZ-03 | Ctrl | restore + logs `Restored` | deleted_at null | test_12 | Automated |
| TC-P13 | BC-BIZ-04 | Ctrl | forceDelete + logs `Deleted` | row gone | test_13 | Automated |
| TC-P14 | BC-BIZ-05 | Ctrl | toggleStatus JSON + logs `Toggled` | is_active flipped | test_14 | Automated |
| TC-P15 | BC-BIZ-06 | Ctrl | update persists validated fields only (**D25-PRM-002 proof**) | injected fields ignored | test_15 | Automated |
| TC-P16 | BC-BIZ-06 | Ctrl | update writes no activity log (**D25-PRM-003**) | log count unchanged | test_16 | Automated |
| TC-P17 | BC-BIZ-01 | Ctrl | store redirect + success flash | 302 → tenant-management | test_17 | Automated |
| TC-P18 | BC-AUTH-08 | Provider | super admin passes all gates | allows all | test_53 | Automated |
| TC-P19 | UI | create.blade | create page renders all fields | fields present | test_60 | Automated |
| TC-P20 | UI | edit.blade | edit page pre-fills values | inputs prefilled | test_61 | Automated |
| TC-P21 | UI | trash.blade | trash page accessible | body present | test_62 | Automated |
| TC-P22 | BC-EDG-01 | DDL/Req | boundary max lengths accepted | 302 no errors | test_70 | Automated |
| TC-P23 | BC-EDG-02 | Req | nullable fields accept empty | 302 no errors | test_71 | Automated |
| TC-P24 | BC-EDG-03 | Req | checkbox coercion on/absent | true/false persisted | test_72 | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | Req | code required | 422 code | test_30 | Automated |
| TC-N02 | BC-VAL-01 | Req | code > 20 | 422 code | test_31 | Automated |
| TC-N03 | BC-VAL-02 | Req | short_name required | 422 short_name | test_32 | Automated |
| TC-N04 | BC-VAL-02 | Req | short_name > 50 | 422 short_name | test_33 | Automated |
| TC-N05 | BC-VAL-02 | Req | duplicate short_name | 422 short_name | test_34 | Automated |
| TC-N06 | BC-VAL-03 | Req | name required | 422 name | test_35 | Automated |
| TC-N07 | BC-VAL-03 | Req | name > 150 | 422 name | test_36 | Automated |
| TC-N08 | BC-VAL-03 | Req | duplicate name | 422 name | test_37 | Automated |
| TC-N09 | BC-VAL-05 | Req | city_id required | 422 city_id | test_38 | Automated |
| TC-N10 | BC-VAL-05 | Req | city_id not in glb_cities | 422 city_id | test_39 | Automated |
| TC-N11 | BC-VAL-06/07/08 | Req | bad website_url/email/pincode/url-length | 422 field | test_40 | Automated |
| TC-N12 | BC-VAL-02 | Req | update keeps own short_name (ignore self) | 302 no errors | test_41 | Automated |
| TC-N13 | BC-AUTH | Ctrl | limited user forbidden on gated GET endpoints | 403/404 | test_51 | Automated |
| TC-N14 | BC-AUTH-02 | Req/Ctrl | limited user cannot store | 403, not persisted | test_52 | Automated |
| TC-N15 | findOrFail | Ctrl | unknown id 404 on show/edit | 404 | test_90 | Automated |
| TC-S01 | BC-AUTH | middleware | guest redirected to /login | 302 /login | test_50 | Automated |
| TC-S02 | XSS | Blade | stored XSS in name escaped on render | no raw `<script>` | test_91 | Automated |
| TC-S03 | BC-BIZ-05 | Ctrl | toggleStatus rejects non-boolean | 422 is_active | test_92 | Automated |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | F | BC-BIZ-* | Ctrl | full lifecycle create→edit→toggle→delete→restore→forceDelete | each step 302/200 | test_42 | Automated |
| TC-D02 | B | BC-DB-11 | DDL | soft delete preserves row; excluded by default query | withTrashed finds it | test_43 | Automated |
| TC-D03 | C | BC-INT-01 | DDL | FK RESTRICT blocks force-delete while a tenant references group | QueryException | test_44 | Automated (defensive) |
| TC-D04 | E | BC-INT-02 | Model | tenants() relationship returns children | count ≥ 1 | test_45 | Automated (defensive) |

### Known Source Defects (D25-PRM-###)
| ID | Sev | Description | Status | Proving test |
|----|-----|-------------|--------|--------------|
| D25-PRM-002 | P2 | Alleged: `update()` uses `$request->all()` vs `store()` `validated()`. **NOT REPRODUCED** — current source (line 99) uses `$request->validated()`; test proves mass-assignment safety on update. | Not reproduced / documented | test_15 |
| D25-PRM-003 | P3 | `update()` performs **no** `activityLog()` while every other mutating action does. | Confirmed (proven) | test_16 |
| D25-PRM-004 | P2 | `index.blade.php` renders **cities** (`$cities`, city columns/switch) instead of tenant groups — wrong/placeholder listing view. | Confirmed (source read) | — (documented in Gap Analysis) |
| D25-PRM-005 | P4 | Redirect anchor inconsistency: `store` → `#tanent-group` (typo), `destroy`/`update` mix `#tanent-group`/`#tenant-group`. | Confirmed | — |
| D25-PRM-006 | P3 | `name` uniqueness enforced only in FormRequest; DDL has no unique index on `name` (race-prone). | Confirmed | test_02 (documents) |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_tenantgroup_01_migration_model_and_request_configuration_are_correct | TC-P01 | Config | 01–09 |
| 2 | test_tenantgroup_02_short_name_has_unique_index_but_name_does_not | TC-P02 | Config/DDL | 01–09 |
| 3 | test_tenantgroup_10_store_creates_group_and_logs_created_event | TC-P10 | BC-BIZ | 10–19 |
| 4 | test_tenantgroup_11_destroy_soft_deletes_and_logs_trashed_event | TC-P11 | BC-BIZ | 10–19 |
| 5 | test_tenantgroup_12_restore_recovers_row_and_logs_restored_event | TC-P12 | BC-BIZ | 10–19 |
| 6 | test_tenantgroup_13_force_delete_removes_permanently_and_logs_deleted_event | TC-P13 | BC-BIZ | 10–19 |
| 7 | test_tenantgroup_14_toggle_status_updates_flag_returns_json_and_logs_toggled | TC-P14 | BC-BIZ | 10–19 |
| 8 | test_tenantgroup_15_update_persists_validated_fields_only_defect_d25_prm_002 | TC-P15 / D25-PRM-002 | BC-BIZ | 10–19 |
| 9 | test_tenantgroup_16_update_does_not_write_activity_log_defect_d25_prm_003 | TC-P16 / D25-PRM-003 | BC-BIZ | 10–19 |
| 10 | test_tenantgroup_17_store_redirects_to_tenant_management_with_success_flash | TC-P17 | BC-BIZ | 10–19 |
| 11 | test_tenantgroup_30_store_rejects_missing_code | TC-N01 | BC-VAL | 30–39 |
| 12 | test_tenantgroup_31_store_rejects_code_over_20_chars | TC-N02 | BC-VAL | 30–39 |
| 13 | test_tenantgroup_32_store_rejects_missing_short_name | TC-N03 | BC-VAL | 30–39 |
| 14 | test_tenantgroup_33_store_rejects_short_name_over_50_chars | TC-N04 | BC-VAL | 30–39 |
| 15 | test_tenantgroup_34_store_rejects_duplicate_short_name | TC-N05 | BC-VAL | 30–39 |
| 16 | test_tenantgroup_35_store_rejects_missing_name | TC-N06 | BC-VAL | 30–39 |
| 17 | test_tenantgroup_36_store_rejects_name_over_150_chars | TC-N07 | BC-VAL | 30–39 |
| 18 | test_tenantgroup_37_store_rejects_duplicate_name | TC-N08 | BC-VAL | 30–39 |
| 19 | test_tenantgroup_38_store_rejects_missing_city_id | TC-N09 | BC-VAL | 30–39 |
| 20 | test_tenantgroup_39_store_rejects_nonexistent_city_id | TC-N10 | BC-VAL | 30–39 |
| 21 | test_tenantgroup_40_store_rejects_bad_optional_field_formats | TC-N11 | BC-VAL | 30–39 |
| 22 | test_tenantgroup_41_update_allows_keeping_own_short_name | TC-N12 | BC-VAL | 30–39 |
| 23 | test_tenantgroup_42_full_lifecycle_flow | TC-D01 | BC-INT/lifecycle | 40–49 |
| 24 | test_tenantgroup_43_soft_delete_preserves_row_in_database | TC-D02 | BC-DB | 40–49 |
| 25 | test_tenantgroup_44_force_delete_is_restricted_while_a_tenant_references_it | TC-D03 | BC-INT | 40–49 |
| 26 | test_tenantgroup_45_tenants_relationship_returns_children | TC-D04 | BC-INT | 40–49 |
| 27 | test_tenantgroup_50_guest_is_redirected_from_index_to_login | TC-S01 | BC-AUTH | 50–59 |
| 28 | test_tenantgroup_51_limited_user_is_forbidden_on_gated_endpoints | TC-N13 | BC-AUTH | 50–59 |
| 29 | test_tenantgroup_52_limited_user_cannot_store | TC-N14 | BC-AUTH | 50–59 |
| 30 | test_tenantgroup_53_super_admin_passes_all_gates | TC-P18 | BC-AUTH | 50–59 |
| 31 | test_tenantgroup_60_create_page_renders_all_form_fields | TC-P19 | UI | 60–69 |
| 32 | test_tenantgroup_61_edit_page_prefills_existing_values | TC-P20 | UI | 60–69 |
| 33 | test_tenantgroup_62_trash_page_is_accessible | TC-P21 | UI | 60–69 |
| 34 | test_tenantgroup_70_store_accepts_boundary_max_lengths | TC-P22 | BC-EDG | 70–79 |
| 35 | test_tenantgroup_71_store_accepts_null_optional_fields | TC-P23 | BC-EDG | 70–79 |
| 36 | test_tenantgroup_72_is_active_checkbox_is_coerced_to_boolean | TC-P24 | BC-EDG | 70–79 |
| 37 | test_tenantgroup_90_unknown_id_returns_404_on_show_and_edit | TC-N15 | TC-S | 90–99 |
| 38 | test_tenantgroup_91_stored_xss_in_name_is_escaped_on_edit_page | TC-S02 | TC-S | 90–99 |
| 39 | test_tenantgroup_92_toggle_status_rejects_non_boolean_payload | TC-S03 | TC-S | 90–99 |
