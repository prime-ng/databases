# Role & Permission (PRM) — Test Case List & Requirements

- **Module:** Prime (PRM) — **CENTRAL / prime_db** (no tenant init)
- **Feature / Screen:** RolePermission
- **Primary table:** `sys_roles` (DDL-verified prefix `sys_`)
- **Controller:** `Modules\Prime\Http\Controllers\RolePermissionController`
- **FormRequest:** `Modules\Prime\Http\Requests\RolePermissionRequest`
- **Models:** `Modules\Prime\Models\Role` (extends Spatie Role), `Permission`
- **Routes:** `central.prime.role-permission.*` (`routes/web.php:156-165`)
- **Activity sink:** `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog`
- **Test file:** `sys_RolePermission_TestCas.php` (47 methods, single file)
- **Host:** `http://127.0.0.1:8000`

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-_prime_db_v4.sql:65-118`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_roles(id, name, short_name, description, guard_name, is_system, is_active, created_at, updated_at)` | DDL-sys_roles |
| BC-DB-02 | `sys_roles` unique keys `(name,guard_name)` and `(short_name,guard_name)` | DDL-sys_roles |
| BC-DB-03 | `sys_roles` has **NO `deleted_at`** — no soft delete at the schema level | DDL-sys_roles |
| BC-DB-04 | `sys_permissions(id, short_name, name, guard_name, is_active, ...)` unique `(name,guard_name)` | DDL-sys_permissions |
| BC-DB-05 | `sys_role_has_permissions_jnt(permission_id, role_id)` composite PK; both FKs `ON DELETE CASCADE` | DDL-sys_role_has_permissions_jnt |
| BC-DB-06 | Central activity sink `sys_central_activity_logs(subject_type, subject_id, user_id, event, properties, ...)` | Constraint #25 / ActivityLog model |

### BC-VAL — Validation (Source: `RolePermissionRequest.php`)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `name` required, string, `Rule::unique('sys_roles')->ignore(id)` | Req-rules:40-44 |
| BC-VAL-02 | `short_name` required, string, `max:20`, unique on `sys_roles` | Req-rules:45-50 |
| BC-VAL-03 | `description` nullable, string, `max:255` | Req-rules:51 |
| BC-VAL-04 | `is_system` boolean (checkbox normalised in `prepareForValidation`) | Req-rules:52,58-64 |
| BC-VAL-05 | `permissions` required array; `permissions.*` string, `exists:sys_permissions,name` | Req-rules:53-54 |
| BC-VAL-06 | `updateRolePermission`: `permission` required string `exists:permissions,name` **(wrong table — DEV-PRM-012)**, `enabled` required boolean | Controller:276-279 |
| BC-VAL-07 | `updatePermissions`: `permissions` required array; `permissions.*` string `exists:permissions,name` **(wrong table — DEV-PRM-012)** | Controller:300-303 |

### BC-AUTH — Authorization (Source: Controller `Gate::authorize` per method)
| ID | Action | Gate | Source |
|----|--------|------|--------|
| BC-AUTH-01 | index | `prime.role-permission.viewAny` | Controller:23 |
| BC-AUTH-02 | create | `prime.role-permission.create` | Controller:38 |
| BC-AUTH-03 | store | `prime.role-permission.create` | Controller:60 |
| BC-AUTH-04 | getRolesByOrganization | `prime.role-permission.viewAny` | Controller:83 |
| BC-AUTH-05 | show | `prime.role-permission.view` | Controller:102 |
| BC-AUTH-06 | edit | `prime.role-permission.update` | Controller:130 |
| BC-AUTH-07 | update | `prime.role-permission.update` | Controller:175 |
| BC-AUTH-08 | destroy | `prime.role-permission.delete` | Controller:227 |
| BC-AUTH-09 | trashedRolePermission | `prime.role-permission.restore` | Controller:243 |
| BC-AUTH-10 | restore | `prime.role-permission.restore` | Controller:251 |
| BC-AUTH-11 | forceDelete | `prime.role-permission.forceDelete` | Controller:259 |
| BC-AUTH-12 | updateRolePermission | `prime.role-permission.update` | Controller:275 |
| BC-AUTH-13 | updatePermissions | `prime.role-permission.update` | Controller:299 |
| BC-AUTH-14 | **getPermissions** | `prime.role-permission.view` — **SEC-PRM-001 REMEDIATED** (gate now present) | Controller:313 |

### BC-BIZ — Business logic / activity events (Source: Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store() creates role, `syncPermissions()`, logs event **`'Stored'`** | Controller:61-73 |
| BC-BIZ-02 | update() diffs original vs changes, logs **`'Updated'`** with changed attributes | Controller:180-217 |
| BC-BIZ-03 | destroy() `$role->delete()` (**permanent** — no soft delete) logs **`'Toggled'`** (mislabel — DEV-PRM-010) | Controller:229-234 |
| BC-BIZ-04 | forceDelete() calls `$role->delete()` (not `forceDelete()`); logs **`'Deleted'`** (DEV-PRM-011) | Controller:261-266 |
| BC-BIZ-05 | trashed()/restore() are stub redirects: "Soft deletes are not enabled for roles." | Controller:241-255 |
| BC-BIZ-06 | getRolesByOrganization() scopes roles by `organization_id`, `Organization::findOrFail` | Controller:81-92 |
| BC-BIZ-07 | show() builds structured permission tree + lists users via `User::role($role->name)` | Controller:100-123 |

### BC-REF — Route / FK contract
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | All 12 named routes `central.prime.role-permission.*` registered | routes/web.php:156-165 |
| BC-REF-02 | `getPermissions` + `updatePermissions` routes registered **UNNAMED** | routes/web.php:163-164 |
| BC-REF-03 | Pivot FK cascade: deleting a role removes its `sys_role_has_permissions_jnt` rows | DDL FK |

### BC-EDG / BC-CFG — Edge & config
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Role model has **no SoftDeletes trait** → `delete()` is permanent | Role.php |
| BC-EDG-02 | `is_system` checkbox 'on'/absent normalised to boolean | Req:58-64 |
| BC-EDG-03 | `name`/`short_name` are not trimmed/sanitised in rules (relies on global middleware) | Req:40-50 |
| BC-CFG-01 | Feature is central: Role uses `mysql` connection; host must be `127.0.0.1` | Role.php:9 / PrimeDuskTestCase |

> **BC-SM:** N/A — RolePermission has no status/workflow lifecycle (`is_active`/`is_system` are flags, not a state machine).

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..06 | DDL | Tables/columns/model/request config correct | All truths hold | test_01 | ✅ |
| TC-P02 | Auth-config | BC-AUTH-01..14 | Controller | Every action has its exact gate | Gates present | test_02 | ✅ |
| TC-P03 | Routes | BC-REF-01 | routes | Named routes registered | Route::has true | test_03 | ✅ |
| TC-P04 | Routes | BC-REF-02 | routes | Custom endpoints unnamed but present | Documented | test_04 | ✅ |
| TC-P05 | Activity | BC-DB-06 | Constraint#25 | Central activity sink present | Columns exist | test_05 | ✅ |
| TC-P06 | Index | BC-BIZ | Controller | Index loads with roles/permissions | Page renders | test_10 | ✅ |
| TC-P07 | Create | BC-VAL | view | Create form fields render | Fields present | test_11 | ✅ |
| TC-P08 | Store | BC-BIZ-01 | Controller | Role created + permissions synced | Pivot rows added | test_12 | ✅ |
| TC-P09 | Activity | BC-BIZ-01 | Controller | store logs `'Stored'` | Literal event | test_13 | ✅ |
| TC-P10 | Activity | BC-BIZ-02 | Controller | update logs `'Updated'` | Literal event | test_14 | ✅ |
| TC-P11 | Org scope | BC-BIZ-06 | Controller | getRolesByOrganization scopes | org filter | test_18 | ✅ |
| TC-P12 | Pivot | BC-DB-05 | DDL | Pivot uses `sys_role_has_permissions_jnt` | Table/cols | test_40 | ✅ |
| TC-P13 | Relation | BC-BIZ-07 | Controller | show lists users with role | binding present | test_43 | ✅ |
| TC-P14 | UI | BC-BIZ | view | Breadcrumb shows "Roles" | Text present | test_60 | ✅ |
| TC-P15 | UI | BC-REF-01 | view | Create form posts to store route | action correct | test_61 | ✅ |
| TC-P16 | Central | BC-CFG-01 | Role | Central connection / 127.0.0.1 | mysql / host | test_93 | ✅ |

### Negative (`TC-N`)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N01 | Required | BC-VAL-01/02/05 | Req | name/short_name/permissions required | rules present | test_30 | ✅ |
| TC-N02 | Unique | BC-VAL-01 | Req | Duplicate name rejected | unique rule | test_31 | ✅ |
| TC-N03 | Length | BC-VAL-02 | Req | short_name max:20 | rule present | test_32 | ✅ |
| TC-N04 | Length | BC-VAL-03 | Req | description max:255 | rule present | test_33 | ✅ |
| TC-N05 | Exists | BC-VAL-05 | Req | permissions exist in sys_permissions | rule present | test_34 | ✅ |
| TC-N06 | Validation | BC-VAL-06 | Controller | updateRolePermission validates permission/enabled | rules present | test_35 | ✅ |
| TC-N07 | Validation | BC-VAL-07 | Controller | updatePermissions requires array | rule present | test_36 | ✅ |
| TC-N08 | 404 | BC-REF | routes | Invalid role id → not found/forbidden | 403/404/302 | test_37 | ✅ |
| TC-N09 | XSS | BC-EDG-03 | Req | name payload stored raw (Blade escapes on render) | escaped at view | test_38 | ✅ |
| TC-N10 | Guest | BC-AUTH | middleware | Guest redirected to login | 302/401/403 | test_50 | ✅ |
| TC-N11 | AuthZ | BC-AUTH-01 | Controller | index requires viewAny | gate present | test_51 | ✅ |
| TC-N12 | AuthZ | BC-AUTH-03 | Controller | store requires create | gate present | test_52 | ✅ |
| TC-N13 | AuthZ | BC-AUTH-07 | Controller | update requires update | gate present | test_53 | ✅ |
| TC-N14 | AuthZ | BC-AUTH-08 | Controller | destroy requires delete | gate present | test_54 | ✅ |
| TC-N15 | AuthZ | BC-AUTH-11 | Controller | forceDelete requires forceDelete | gate present | test_55 | ✅ |
| TC-N16 | AuthZ | BC-AUTH-14 | Controller | getPermissions requires view (SEC-PRM-001) | gate present | test_56 | ✅ |
| TC-N17 | AuthZ | BC-AUTH | Req | FormRequest authorize maps actions→gates | gates present | test_57 | ✅ |
| TC-N18 | Whitespace | BC-EDG-03 | Req | name has no rule-level sanitiser (documented gap) | no sanitiser | test_71 | ✅ |
| TC-N19 | Unique | BC-VAL-02 | Req | duplicate short_name rejected | unique rule | test_72 | ✅ |
| TC-N20 | AuthN | BC-AUTH | middleware | unauth store blocked | 302/401/419/422 | test_94 | ✅ |

### Dependency (`TC-D`)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | B | BC-BIZ-03/EDG-01 | Controller/Role | destroy permanently deletes (no trashed copy) + logs `'Toggled'` | row gone | test_15 | ✅ |
| TC-D02 | B | BC-BIZ-04 | Controller | forceDelete uses plain delete() + logs `'Deleted'` | delete()/no forceDelete | test_16 | ✅ |
| TC-D03 | B | BC-BIZ-05 | Controller | trashed/restore are no-op redirects | notice string | test_17 | ✅ |
| TC-D04 | C | BC-REF-03 | DDL | Deleting role cascades pivot rows | 0 pivot rows | test_41 | ✅ |
| TC-D05 | E | BC-BIZ-07 | Permission | Permission belongs to Menu | BelongsTo | test_42 | ✅ |
| TC-D06 | G | BC-EDG-02 | Req | is_system checkbox cast to boolean | normaliser present | test_70 | ✅ |

### Security (`TC-S`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S01 | BC-AUTH-14 | Controller | **SEC-PRM-001** getPermissions gated (config + functional non-priv 403) | denied | test_90 | ✅ |
| TC-S02 | BC-DB-01 | Role | Role fillable guards mass assignment | id not fillable | test_91 | ✅ |
| TC-S03 | BC-AUTH-14 | Controller | IDOR: getPermissions uses route-model binding | binding present | test_92 | ✅ |
| TC-S04 | BC-VAL-06/07 | Controller | **DEV-PRM-012** inline endpoints hit wrong `permissions` table | wrong table | test_73 | ✅ |
| TC-S05 | BC-AUTH | middleware | State-changing endpoints require auth | blocked | test_94 | ✅ |

### Config-truth extras
| TC ID | BC | Description | Method | Status |
|-------|----|-------------|--------|--------|
| TC-C01 | DEP-PRM-001 | Controller uses Prime FormRequest, not SchoolSetup | test_02b | ✅ |
| TC-C02 | BC-REF-02 | getPermissions/updatePermissions unnamed | test_04 | ✅ |

---

## 3. Known Source Defects (audit-equivalent)

| ID | Sev | Description | Status in current source | Proving test |
|----|-----|-------------|--------------------------|--------------|
| SEC-PRM-001 | P0 | `getPermissions()` had zero Gate — any authenticated user could enumerate any role's permissions (BR-PRM-020 FAIL) | **REMEDIATED** — `Gate::authorize('prime.role-permission.view')` present at Controller:313 | test_02, test_56, test_90 |
| DEP-PRM-001 | P3 | Controller depended on cross-module SchoolSetup FormRequest | **NOT REPRODUCED** — controller imports `Modules\Prime\Http\Requests\RolePermissionRequest` (Controller:11); both requests are near-identical | test_02b |
| DEV-PRM-010 | P3 | `destroy()` logs activity event literal `'Toggled'` (should be a delete event) | Present | test_15 |
| DEV-PRM-011 | P2 | `forceDelete()` calls `$role->delete()`; `sys_roles` has no `deleted_at` and Role lacks SoftDeletes ⇒ "force delete" == permanent delete; `trashed()/restore()` are stub redirects | Present (internally consistent but route semantics misleading) | test_16, test_17, test_01 |
| DEV-PRM-012 | P2 | `updateRolePermission()`/`updatePermissions()` validate `exists:permissions,name` (literal `permissions` table) while the real table is `sys_permissions` ⇒ rule cannot match | Present | test_35, test_73 |

---

## 4. Test Method Index

| # | Method | TC Map | Band |
|---|--------|--------|------|
| 1 | test_rolepermission_01_migration_model_and_request_configuration_are_correct | TC-P01 | 01-09 |
| 2 | test_rolepermission_02_controller_gate_authorization_is_present_on_every_action | TC-P02/TC-S01 | 01-09 |
| 3 | test_rolepermission_02b_controller_uses_prime_form_request_not_schoolsetup | TC-C01 | 01-09 |
| 4 | test_rolepermission_03_all_named_routes_are_registered | TC-P03 | 01-09 |
| 5 | test_rolepermission_04_permission_endpoints_registered_but_unnamed | TC-P04/TC-C02 | 01-09 |
| 6 | test_rolepermission_05_central_activity_sink_present | TC-P05 | 01-09 |
| 7 | test_rolepermission_10_index_page_loads_with_roles_and_permissions | TC-P06 | 10-19 |
| 8 | test_rolepermission_11_create_form_renders_expected_fields | TC-P07 | 10-19 |
| 9 | test_rolepermission_12_store_creates_role_and_syncs_permissions | TC-P08 | 10-19 |
| 10 | test_rolepermission_13_store_writes_stored_activity_event | TC-P09 | 10-19 |
| 11 | test_rolepermission_14_update_logs_updated_event | TC-P10 | 10-19 |
| 12 | test_rolepermission_15_destroy_permanently_deletes_and_logs_toggled | TC-D01 | 10-19 |
| 13 | test_rolepermission_16_force_delete_method_uses_plain_delete | TC-D02 | 10-19 |
| 14 | test_rolepermission_17_trashed_and_restore_are_noop_redirects | TC-D03 | 10-19 |
| 15 | test_rolepermission_18_get_roles_by_organization_scopes_by_org | TC-P11 | 10-19 |
| 16 | test_rolepermission_30_store_requires_name_short_name_and_permissions | TC-N01 | 30-39 |
| 17 | test_rolepermission_31_duplicate_name_rejected_unique_sys_roles | TC-N02 | 30-39 |
| 18 | test_rolepermission_32_short_name_max_20_enforced | TC-N03 | 30-39 |
| 19 | test_rolepermission_33_description_max_255 | TC-N04 | 30-39 |
| 20 | test_rolepermission_34_permissions_must_exist_in_sys_permissions | TC-N05 | 30-39 |
| 21 | test_rolepermission_35_update_role_permission_endpoint_validation | TC-N06/TC-S04 | 30-39 |
| 22 | test_rolepermission_36_update_permissions_endpoint_requires_array | TC-N07 | 30-39 |
| 23 | test_rolepermission_37_invalid_role_id_returns_404 | TC-N08 | 30-39 |
| 24 | test_rolepermission_38_xss_in_name_is_stored_raw_and_escaped_on_render | TC-N09 | 30-39 |
| 25 | test_rolepermission_40_pivot_uses_sys_role_has_permissions_jnt | TC-P12 | 40-49 |
| 26 | test_rolepermission_41_deleting_role_cascades_pivot_rows | TC-D04 | 40-49 |
| 27 | test_rolepermission_42_permission_belongs_to_menu_relation | TC-D05 | 40-49 |
| 28 | test_rolepermission_43_show_lists_users_with_role | TC-P13 | 40-49 |
| 29 | test_rolepermission_50_guest_is_redirected_to_login | TC-N10 | 50-59 |
| 30 | test_rolepermission_51_index_requires_view_any_gate | TC-N11 | 50-59 |
| 31 | test_rolepermission_52_store_requires_create_gate | TC-N12 | 50-59 |
| 32 | test_rolepermission_53_update_requires_update_gate | TC-N13 | 50-59 |
| 33 | test_rolepermission_54_destroy_requires_delete_gate | TC-N14 | 50-59 |
| 34 | test_rolepermission_55_force_delete_requires_force_delete_gate | TC-N15 | 50-59 |
| 35 | test_rolepermission_56_get_permissions_requires_view_gate | TC-N16/TC-S01 | 50-59 |
| 36 | test_rolepermission_57_form_request_authorize_maps_actions_to_gates | TC-N17 | 50-59 |
| 37 | test_rolepermission_60_breadcrumb_shows_roles_and_permissions | TC-P14 | 60-69 |
| 38 | test_rolepermission_61_create_page_posts_to_store_route | TC-P15 | 60-69 |
| 39 | test_rolepermission_70_is_system_checkbox_casts_to_boolean | TC-D06 | 70-79 |
| 40 | test_rolepermission_71_whitespace_only_name_is_not_pre_trimmed | TC-N18 | 70-79 |
| 41 | test_rolepermission_72_duplicate_short_name_rejected | TC-N19 | 70-79 |
| 42 | test_rolepermission_73_inline_endpoints_reference_wrong_permissions_table | TC-S04 | 70-79 |
| 43 | test_rolepermission_90_sec_prm_001_get_permissions_is_gated | TC-S01 | 90-99 |
| 44 | test_rolepermission_91_role_fillable_guards_mass_assignment | TC-S02 | 90-99 |
| 45 | test_rolepermission_92_idor_get_permissions_denied_cross_role | TC-S03 | 90-99 |
| 46 | test_rolepermission_93_feature_is_central_scope_no_tenant_init | TC-P16 | 90-99 |
| 47 | test_rolepermission_94_state_changing_endpoints_require_auth | TC-N20/TC-S05 | 90-99 |
