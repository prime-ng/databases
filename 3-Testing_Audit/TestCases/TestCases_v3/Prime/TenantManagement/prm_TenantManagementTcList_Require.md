# prm_TenantManagement — Test Case List & Business Conditions

**Module:** Prime (PRM) · **Feature/Screen:** TenantManagement · **Prefix:** `prm_` (DDL-verified: `prm_tenant`, `prm_tenant_groups`)
**Screen type:** READ / COMPOSITE dashboard (single `index()` action) — lists Tenant Groups + Tenants with computed stats; delegates all mutations to the Tenant / TenantGroup screens.
**Route:** `central.prime.tenant-management.index` → `GET /prime/tenant-management` (central domain, middleware `auth`, `verified`)
**Controller:** `Modules\Prime\Http\Controllers\TenantManagementController@index`
**Models:** `Modules\Prime\Models\Tenant` (`prm_tenant`), `Modules\Prime\Models\TenantGroup` (`prm_tenant_groups`)
**DB scope:** CENTRAL (`prime_db`) — no tenant context. **Activity log:** none (read-only action; controller writes no log).
**Test file:** `prm_TenantManagement_TestCas.php` (24 methods, single comprehensive suite)

---

## 1. Business Conditions

### BC-DB — Schema (DDL + runtime migrations)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `prm_tenant` PK `id`, FK `tenant_group_id`→`prm_tenant_groups` (ON DELETE RESTRICT), FK `city_id`→`glb_cities` (RESTRICT), `UNIQUE uq_tenant_code(code)`, soft-delete `deleted_at` | DDL-prm_tenant |
| BC-DB-02 | `prm_tenant_groups` PK `id`, FK `city_id`→`glb_cities` (RESTRICT), `UNIQUE uq_tenantGroups_shortName(short_name)`, soft-delete `deleted_at` | DDL-prm_tenant_groups |
| BC-DB-03 | Runtime `prm_tenant` also has `setup_status`, `setup_progress`, `setup_message` (migration 2026_03_21) and `tenant_type`, `parent_tenant_id`, `rollover_*`, `archived_*` (migration 2026_07_02) — **absent from consolidated `_prime_db_v4.sql`** | DDL-vs-Migration |
| BC-DB-04 | `Tenant::$table='prm_tenant'`, casts `is_active=>boolean`, uses `SoftDeletes` | Model-Tenant |
| BC-DB-05 | `TenantGroup::$table='prm_tenant_groups'`, fillable `[code,short_name,name,address_1,address_2,city_id,pincode,website_url,email,is_active]`, casts `is_active=>boolean`, `city_id=>integer`, uses `SoftDeletes` | Model-TenantGroup |

### BC-BIZ — Business logic / render behaviour
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `index()` lists only LIVE tenants — `Tenant::live()` scopes `tenant_type='live'` | Controller index() |
| BC-BIZ-02 | Tenant groups list carries `withCount('liveTenants')` + eager `city.district.state`, paginated 10/page under `tenant-group_page`, fragment `#tenant-group` | Controller index() |
| BC-BIZ-03 | Tenants list carries `modules_count` (count of plans having modules), paginated 10/page under `tenant_page`, fragment `#tenant` | Controller index() |
| BC-BIZ-04 | Dashboard stats (`tenantGroupStats`, `tenantStats`) are **query-derived** (`computeTenantGroupStats`/`computeTenantStats`) — NOT fabricated (no `rand()`) | Controller + Audit-BUG-PRM-009 |
| BC-BIZ-05 | Page shows two tabs: Tenant Group (default active) + Tenant; breadcrumb "Tenant & Subscription Mgmt" | View index.blade |
| BC-BIZ-06 | Tenant row status switch only editable when `isProfileComplete() && modules_count>0`, else read-only "Inactive" badge | View _tenantTab |

### BC-AUTH — Permissions
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` requires `Gate::authorize('prime.tenant.viewAny')` | Controller index() / Screen-PM-1 |
| BC-AUTH-02 | Guest (unauthenticated) → redirect to `/login` (`auth`,`verified` middleware) | Req-Middleware |
| BC-AUTH-03 | Tenant Group tab shown only if `prime.tenant-group.viewAny`; Tenant tab only if `prime.tenant.viewAny` | View index.blade (nav-tab permission) |
| BC-AUTH-04 | Column-level gates: `prime.tenant.{view,update,delete}`, `prime.tenant-group.{view,update,delete}` toggle Status/Action columns & buttons | View partials |
| BC-AUTH-05 | **DEFECT** `TenantManagementPolicy::viewAny` checks `prime.tenant-management.viewAny` — a DIFFERENT permission than the controller enforces, and the policy is never invoked (orphaned) | Cross-Ref-10 |

### BC-REF — Referential integrity (informational; mutations delegated)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `prm_tenant.tenant_group_id` → `prm_tenant_groups.id` ON DELETE RESTRICT | DDL |
| BC-REF-02 | `prm_tenant.city_id` / `prm_tenant_groups.city_id` → `glb_cities.id` ON DELETE RESTRICT | DDL |

### BC-EDG — Edge / defects (this screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Search box + two filter dropdowns are **non-functional stubs** (dummy options, no `name`, form has no action, controller reads no request) | Cross-Ref Blade↔Controller |
| BC-EDG-02 | Export button present but has no handler (bare `<button>`) | View _tenantTab |
| BC-EDG-03 | Tenant "Address" cell prints raw numeric `city_id` instead of city name | View _tenantTab |
| BC-EDG-04 | Empty-state row uses `colspan="5"` while the table can render 6–7 columns | View partials |
| BC-EDG-05 | Empty listing shows "Not Found Data" via `@forelse` | View partials |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..05, BC-AUTH-01 | DDL/Model/Route | Route + models + policy + schema config truth | All config matches source | `test_..._01` | Automated |
| TC-P02 | BC-BIZ-05 | Screen-Render | Page renders with breadcrumb + card | "Tenant & Subscription Mgmt" visible | `test_..._10` | Automated |
| TC-P03 | BC-BIZ-05 | Screen-Render | Both tabs present | tenant-group & tenant tabs/panes present | `test_..._11` | Automated |
| TC-P04 | BC-BIZ-05 | Screen-Render | Tenant-group is default active pane | `#tenant-group-pane` visible | `test_..._12` | Automated |
| TC-P05 | BC-BIZ-05 | Screen-Render | Switch to Tenant tab reveals pane | `#tenant-pane` visible + table present | `test_..._13` | Automated |
| TC-P06 | BC-BIZ-04 | Audit-BUG-PRM-009 | Stats query-derived, not fabricated | No `rand()`; `withCount` present | `test_..._14` | Automated |
| TC-P07 | BC-BIZ-03 | Screen-Render | Tenant dashboard/table renders | `#tenant-pane table.js-sortable` present | `test_..._15` | Automated |
| TC-P08 | BC-AUTH-01 | Screen-PM-1 | Authorised admin can view | Reaches index, page accessible | `test_..._51` | Automated |
| TC-P09 | BC-AUTH-01 | Screen-PM-1 | Gate string is `prime.tenant.viewAny` | Controller source matches | `test_..._52` | Automated |
| TC-P10 | BC-BIZ-05 | Screen-Render | Group action buttons present | Add/View-Trash links present | `test_..._54` | Automated |
| TC-P11 | BC-BIZ-03 | Screen-Render | Tenant column headers | Tenant/Domain/Details/Contact/Address | `test_..._60` | Automated |
| TC-P12 | BC-BIZ-02 | Screen-Render | Tenant-group column headers | Tenant Group/Contact/Address | `test_..._61` | Automated |
| TC-P13 | BC-BIZ-02/03 | Controller | Scoped pagination params | `tenant_page`/`tenant-group_page` | `test_..._62` | Automated |

### Negative / Defect (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-AUTH-02 | Req-Middleware | Guest redirected to login | Lands on `/login` | `test_..._50` | Automated |
| TC-N02 | BC-EDG-05 | Screen-EmptyState | Empty-state defined for both tables | "Not Found Data" + `@forelse` | `test_..._63` | Automated |
| TC-N03 | BC-EDG-01 | Cross-Ref | Search/filter are non-functional stubs | No `name`, controller reads no request | `test_..._64` | Automated |
| TC-N04 | BC-EDG-02 | Screen-Search | Export button has no handler | No id/handler on button | `test_..._65` | Automated |
| TC-N05 | BC-EDG-03 | Cross-Ref | Address prints raw city_id | Source prints `$tenant->city_id` | `test_..._71` | Automated |
| TC-N06 | BC-EDG-04 | Cross-Ref | Empty-state colspan too small | `colspan="5"` vs 6–7 cols | `test_..._72` | Automated |

### Dependency / Cross-cutting (TC-D) & Security (TC-S)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D01 | BC-AUTH-05 | Cross-Ref-10 | Policy permission mismatch + unwired | Controller≠policy permission; policy orphaned | `test_..._53` | Automated |
| TC-D02 | BC-BIZ-01 | Req-Route | No create/edit/delete routes on this screen | Only `.index` exists; mutations delegated | `test_..._70` | Automated |
| TC-D03 | BC-DB-03 | DDL-drift | Runtime columns exceed consolidated DDL | Model declares tenant_type/setup_status | `test_..._80` | Automated |
| TC-S01 | — | Constraint-E21 | Central-only, no tenant context | Host 127.0.0.1, tenancy not initialised | `test_..._91` | Automated |
| TC-S02 | BC-BIZ-05 | Screen-Smoke | Clean happy-path load | Body present, no error banners; console captured | `test_..._90` | Automated |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_tenantmanagement_01_route_model_policy_and_schema_configuration_are_correct | TC-P01 | Config truth | 01–09 |
| 2 | test_tenantmanagement_10_index_renders_with_breadcrumb_and_management_card | TC-P02 | Render | 10–19 |
| 3 | test_tenantmanagement_11_both_tenant_group_and_tenant_tabs_are_present | TC-P03 | Render | 10–19 |
| 4 | test_tenantmanagement_12_tenant_group_pane_is_the_default_active_tab | TC-P04 | Render | 10–19 |
| 5 | test_tenantmanagement_13_switching_to_tenant_tab_reveals_tenant_pane | TC-P05 | Render | 10–19 |
| 6 | test_tenantmanagement_14_tenant_group_dashboard_stats_render_from_real_data_not_fabricated | TC-P06 | Render/Defect | 10–19 |
| 7 | test_tenantmanagement_15_tenant_dashboard_section_renders | TC-P07 | Render | 10–19 |
| 8 | test_tenantmanagement_50_guest_is_redirected_to_login | TC-N01 | Auth | 50–59 |
| 9 | test_tenantmanagement_51_authorized_admin_can_view_the_dashboard | TC-P08 | Auth | 50–59 |
| 10 | test_tenantmanagement_52_index_is_gated_by_prime_tenant_viewany_permission | TC-P09 | Auth | 50–59 |
| 11 | test_tenantmanagement_53_dedicated_policy_permission_is_mismatched_and_unwired | TC-D01 | Auth/Defect | 50–59 |
| 12 | test_tenantmanagement_54_tenant_group_action_buttons_are_present | TC-P10 | Render | 50–59 |
| 13 | test_tenantmanagement_60_tenant_table_renders_expected_column_headers | TC-P11 | UI/UX | 60–69 |
| 14 | test_tenantmanagement_61_tenant_group_table_renders_expected_column_headers | TC-P12 | UI/UX | 60–69 |
| 15 | test_tenantmanagement_62_pagination_uses_scoped_page_parameters | TC-P13 | UI/UX | 60–69 |
| 16 | test_tenantmanagement_63_empty_state_message_is_defined_for_both_tables | TC-N02 | UI/UX | 60–69 |
| 17 | test_tenantmanagement_64_search_and_filter_controls_are_nonfunctional_stubs | TC-N03 | UI/UX/Defect | 60–69 |
| 18 | test_tenantmanagement_65_export_button_present_without_handler | TC-N04 | UI/UX/Defect | 60–69 |
| 19 | test_tenantmanagement_70_screen_exposes_no_create_edit_delete_routes | TC-D02 | Edge/Delegation | 70–79 |
| 20 | test_tenantmanagement_71_tenant_address_column_renders_raw_city_id | TC-N05 | Edge/Defect | 70–79 |
| 21 | test_tenantmanagement_72_empty_state_colspan_does_not_span_all_columns | TC-N06 | Edge/Defect | 70–79 |
| 22 | test_tenantmanagement_80_runtime_tenant_columns_exceed_consolidated_ddl | TC-D03 | Config/Drift | 80–89 |
| 23 | test_tenantmanagement_90_happy_path_load_is_clean | TC-S02 | Smoke | 90–99 |
| 24 | test_tenantmanagement_91_feature_is_central_and_requires_no_tenant_context | TC-S01 | Central scope | 90–99 |

---

## 4. Known / Discovered Source Defects (verify-in-source candidates)
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| BUG-PRM-TM-001 | P2 | `TenantManagementPolicy::viewAny` enforces `prime.tenant-management.viewAny` but the controller authorises `prime.tenant.viewAny`; the policy is never invoked → orphaned policy + permission | `test_..._53` |
| BUG-PRM-TM-002 | P2 | Search box + two filter dropdowns are non-functional stubs (dummy options, no `name`, form has no action, controller reads no request input) | `test_..._64` |
| BUG-PRM-TM-002b | P3 | Export button present with no handler | `test_..._65` |
| BUG-PRM-TM-003 | P3 | Tenant Address column renders raw numeric `city_id` instead of the city name | `test_..._71` |
| BUG-PRM-TM-004 | P3 | Empty-state row `colspan="5"` does not span 6–7 rendered columns | `test_..._72` |
| BUG-PRM-TM-005 | P3 (doc) | Consolidated `_prime_db_v4.sql` lacks `tenant_type`, `setup_status`, `rollover_*` columns that the model/controller depend on (added by central migrations) | `test_..._80` |
| BUG-PRM-009 | — (N/A) | Verified **not applicable** here: dashboard stats are query-derived, not `rand()`-fabricated | `test_..._14` |
