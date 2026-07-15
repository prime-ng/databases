# prm_SalesPlanAndModuleMgmt — Test Case List & Business Conditions

**Module:** Prime (PRM) · **Feature/Screen:** Sales Plan & Module Mgmt (composite read-only dashboard)
**Primary table:** `prm_plans` (prefix `prm_`) · **DB scope:** CENTRAL (`prime_db`, connection `mysql`) — NO tenant init · **Host:** `http://127.0.0.1:8000`
**Controller:** `Modules\Prime\Http\Controllers\SalesPlanAndModuleMgmtController` (uses `Request`, no FormRequest)
**Route (verified):** `Route::resource('sales-plan-mgmt', ...)` under `->prefix('prime')->name('prime.')` → names `prime.sales-plan-mgmt.{index,create,store,show,edit,update,destroy}`, index URI `prime/sales-plan-mgmt`.
**Models:** `GlobalMaster\Plan` (`prm_plans`), `Billing\BillingCycle` (`prm_billing_cycles`), `GlobalMaster\Module` (`glb_modules`).
**Activity log:** none — controller writes nothing (no `activityLog()` calls; the would-be sink is central `sys_central_activity_logs`).
**Single test file:** `prm_SalesPlanAndModuleMgmt_TestCas.php` — 35 methods.

> **Screen character (verified in source):** `index()` aggregates three paginated catalogues (Billing Cycles, Modules, Plans) with a shared `search`+`status` filter and per-tab page params. The write half of the resource controller is **non-functional**: `store()/update()/destroy()` are empty stubs and `create()/show()/edit()` return non-existent views. Real writes for the three catalogues live in other controllers. Tests therefore assert **read/composite behaviour + configuration truth + documented defects (current behaviour)**.

---

## 1. Business Conditions

### BC-DB — Schema (Source: DDL `_prime_db_v4.sql`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `prm_plans` exists; PK `id` INT unsigned AI | DDL-prm_plans |
| BC-DB-02 | `prm_plans.plan_code` varchar(20) NOT NULL | DDL-prm_plans |
| BC-DB-03 | `prm_plans.version` int unsigned default 0 | DDL-prm_plans |
| BC-DB-04 | `prm_plans` UNIQUE(`plan_code`,`version`) = `uq_plans_planCode_version` | DDL-prm_plans |
| BC-DB-05 | `prm_plans.billing_cycle_id` SMALLINT NOT NULL | DDL-prm_plans |
| BC-DB-06 | `prm_plans.currency` char(3) default 'INR'; `trial_days` int unsigned default 0 | DDL-prm_plans |
| BC-DB-07 | `prm_plans` soft-deletes (`deleted_at`) + timestamps | DDL-prm_plans |
| BC-DB-08 | `prm_plans` has `price_monthly`, `price_quarterly`, `price_yearly` decimal(12,2) | DDL-prm_plans |
| BC-DB-09 | `prm_billing_cycles` exists; PK `id` SMALLINT unsigned; UNIQUE(`short_name`) | DDL-prm_billing_cycles |
| BC-DB-10 | `prm_billing_cycles` columns: short_name, name, months_count, description, is_recurring, is_active | DDL-prm_billing_cycles |
| BC-DB-11 | `prm_module_plan_jnt` (DDL) is the plan↔module pivot | DDL-prm_module_plan_jnt |
| BC-DB-12 | `glb_modules` backs the Modules tab | Module model |
| BC-DB-13 | Models back expected tables (Plan→prm_plans, BillingCycle→prm_billing_cycles, Module→glb_modules) | Models |

### BC-REF — Referential integrity (Source: DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `prm_plans.billing_cycle_id` → `prm_billing_cycles.id` **ON DELETE RESTRICT** (`fk_plans_billingCycleId`) | DDL-prm_plans |

### BC-BIZ — Composite index behaviour (Source: controller + index.blade.php)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index renders 3 tabs; Billing Cycle default active | Screen-BR / index.blade |
| BC-BIZ-02 | Billing tab lists `prm_billing_cycles` (Short Name/Name/Months/…) | index.blade |
| BC-BIZ-03 | Modules tab lists `glb_modules` (Name/Version/Menus) | index.blade |
| BC-BIZ-04 | Plans tab lists `prm_plans` (Name/Version/Billing Cycle/Trial) | index.blade |
| BC-BIZ-05 | Each plan exposes a detail modal `#planDetail-{id}` listing its modules | index.blade |
| BC-BIZ-06 | Each tab paginates 10/page with distinct params `billing_page`/`modules_page`/`plans_page` | Controller |

### BC-VAL — Filters / negative (Source: controller index() query guards)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | Search box + status select present on the pane | index.blade |
| BC-VAL-02 | `search` filters each catalogue (LIKE name/desc/…); page still renders | Controller |
| BC-VAL-03 | `status=1`/`status=0` filter honoured (`in_array(..., ['0','1'])`) | Controller |
| BC-VAL-04 | Out-of-range `status` value is ignored (guard), no error | Controller |
| BC-VAL-05 | No-match search shows tab empty-state ("Not/No Data Found") | index.blade |

### BC-AUTH — Permissions (Source: controller Gate::authorize + Policy + view)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` gated by `prime.sale-plan-module-mgmt.viewAny` | Controller |
| BC-AUTH-02 | create/store→`.create`; show→`.view`; edit/update→`.update`; destroy→`.delete` | Controller |
| BC-AUTH-03 | View tabs gated by `prime.billing-cycle/module/plan.viewAny` (DIFFERENT vocabulary) | index.blade |
| BC-AUTH-04 | Policy exists but type-hints `TenantPlan`; abilities are `prime.sale-plan-module-mgmt.*` | Policy |
| BC-AUTH-05 | Guest redirected to `/login` (auth+verified middleware) | routes/web.php:107 |
| BC-AUTH-06 | Authorized super-admin reaches the index (not 403) | Controller |

### BC-INT — Integration / cross-layer defects (Source: DDL vs code)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `store()` persists nothing (empty stub) — DEV-PRM-SPM-001 | Controller store() |
| BC-INT-02 | `update()`/`destroy()` persist nothing (empty stubs) — DEV-PRM-SPM-001 | Controller |
| BC-INT-03 | POST to store creates no `prm_plans` row (behavioural) | Controller |
| BC-INT-04 | `create()/show()/edit()` return non-existent views `prime::create/show/edit` — DEV-PRM-SPM-002 | Controller |
| BC-INT-05 | Pivot name mismatch: DDL `prm_module_plan_jnt` vs code `glb_module_plan_jnt` — DEV-PRM-SPM-005 | DDL vs Plan/Module |
| BC-INT-06 | `Plan $fillable` omits `price_quarterly` (present in DDL) — DEV-PRM-SPM-006 | DDL vs Plan model |
| BC-INT-07 | `BillingCycle` uses SoftDeletes+timestamps but DDL `prm_billing_cycles` declares none — DEV-PRM-SPM-007 | DDL vs BillingCycle |
| BC-INT-08 | `GenerateInvoicesCommand` IS registered + exists — GAP-PRM-001 REFUTED | PrimeServiceProvider |

### BC-CFG / BC-EDG — Config & UI
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Primary source files present (controller/policy/view/models) | Read-set |
| BC-CFG-02 | Runs in central scope on 127.0.0.1 with no tenant context | PrimeDuskTestCase |
| BC-EDG-01 | Breadcrumb title "Sales Plan & Module Mgmt" renders | index.blade |
| BC-EDG-02 | Billing pane active/shown by default | index.blade |
| BC-EDG-03 | Clicking Plans tab reveals plans pane | index.blade |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB-01..12, BC-REF-01, BC-AUTH-01..02 | DDL/routes | Schema+route+gate config truth | tables/routes/gates present | `_01` | Ready |
| TC-P02 | Config | BC-CFG-01 | Read-set | Primary source files present | files non-empty | `_02` | Ready |
| TC-P03 | Config | BC-DB-13 | Models | Models back expected tables | table names match | `_03` | Ready |
| TC-P04 | Render | BC-BIZ-01 | index.blade | Index renders 3 tabs | tabs present | `_10` | Ready |
| TC-P05 | Render | BC-BIZ-02 | index.blade | Billing tab lists cycles | headers present | `_11` | Ready |
| TC-P06 | Render | BC-BIZ-03 | index.blade | Modules tab lists modules | pane+Menus present | `_12` | Ready |
| TC-P07 | Render | BC-BIZ-04 | index.blade | Plans tab lists plans | pane+columns present | `_13` | Ready |
| TC-P08 | Render | BC-BIZ-05 | index.blade | Plan detail modal markup | modal+modules loop | `_14` | Ready |
| TC-P09 | Config | BC-BIZ-06 | Controller | Distinct pagination params | 3 named pages, 10/pp | `_15` | Ready |
| TC-P10 | Filter | BC-VAL-01 | index.blade | Search+status controls present | inputs present | `_30` | Ready |
| TC-P11 | Filter | BC-VAL-02 | Controller | Search applies, page renders | value echoed, 200 | `_31` | Ready |
| TC-P12 | Filter | BC-VAL-03 | Controller | status 1/0 honoured | both render | `_32` | Ready |
| TC-P13 | Auth | BC-AUTH-06 | Controller | Admin reaches index | not 403 | `_55` | Ready |
| TC-P14 | UI | BC-EDG-01 | index.blade | Breadcrumb title | text visible | `_60` | Ready |
| TC-P15 | UI | BC-EDG-02 | index.blade | Billing pane default active | visible | `_61` | Ready |
| TC-P16 | UI | BC-EDG-03 | index.blade | Plans tab click shows pane | pane visible | `_62` | Ready |
| TC-P17 | Config | BC-INT-08 | Provider | GenerateInvoicesCommand registered (GAP-PRM-001 refuted) | present | `_48` | Ready |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N01 | Filter | BC-VAL-04 | Controller | Invalid status value ignored | no error, stays on index | `_33` | Ready |
| TC-N02 | Filter | BC-VAL-05 | index.blade | No-match search empty-state | "Not/No Data Found" | `_34` | Ready |
| TC-N03 | Auth | BC-AUTH-05 | routes | Guest redirected to /login | /login path | `_54` | Ready |
| TC-N04 | Security | TC-S-01 | index.blade | Search XSS not reflected unescaped | payload absent | `_91` | Ready |
| TC-N05 | Security | TC-S-02 | routes/stub | Guest DELETE blocked, no row change | 30x/40x + count same | `_92` | Ready |

### Dependency / Integration (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C | BC-REF-01 | DDL | Plan→billing-cycle FK RESTRICT | constraint present | `_44` | Ready |
| TC-D02 | E | BC-INT-01 | Controller | store() non-functional stub | no write tokens | `_40` | Ready |
| TC-D03 | E | BC-INT-02 | Controller | update/destroy stubs | no write tokens | `_41` | Ready |
| TC-D04 | B | BC-INT-03 | Controller | POST store creates no row | count unchanged | `_42` | Ready |
| TC-D05 | E | BC-INT-04 | Controller | create/show/edit missing views | views absent | `_43` | Ready |
| TC-D06 | E | BC-INT-05 | DDL/models | pivot name mismatch | glb vs prm | `_45` | Ready |
| TC-D07 | E | BC-INT-06 | DDL/model | fillable omits price_quarterly | not fillable | `_46` | Ready |
| TC-D08 | E | BC-INT-07 | DDL/model | BillingCycle soft-delete/ts gap | ddl lacks deleted_at | `_47` | Ready |

### Permissions (TC-AUTH)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-AU01 | BC-AUTH-01 | Controller | index gated by viewAny | gate string present | `_50` | Ready |
| TC-AU02 | BC-AUTH-02 | Controller | resource gates map to verbs | 4 gates present | `_51` | Ready |
| TC-AU03 | BC-AUTH-03 | index.blade | view tab gates differ (DEV-003) | 3 tab gates, no controller gate in view | `_52` | Ready |
| TC-AU04 | BC-AUTH-04 | Policy | policy type-hints TenantPlan (DEV-004) | import present | `_53` | Ready |

### Central scope (TC-T)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-T01 | BC-CFG-02 | PrimeDuskTestCase | central scope, no tenancy | host 127.0.0.1, tenancy not init | `_90` | Ready |

---

## 3. Known Source Defects (DEV-###)
| ID | Sev | Summary | Proving method |
|----|-----|---------|----------------|
| DEV-PRM-SPM-001 | P1 | `store()/update()/destroy()` empty stubs — no persistence | `_40`,`_41`,`_42` |
| DEV-PRM-SPM-002 | P1 | `create()/show()/edit()` return non-existent views | `_43` |
| DEV-PRM-SPM-003 | P2 | controller gate `prime.sale-plan-module-mgmt.*` vs view tab gates `prime.billing-cycle/module/plan.*` | `_52` |
| DEV-PRM-SPM-004 | P2 | Policy type-hints `TenantPlan` (prm_tenant_plan_jnt), never bound (dead) | `_53` |
| DEV-PRM-SPM-005 | P2 | pivot DDL `prm_module_plan_jnt` vs code `glb_module_plan_jnt` | `_45` |
| DEV-PRM-SPM-006 | P3 | `Plan $fillable` omits `price_quarterly` | `_46` |
| DEV-PRM-SPM-007 | P2 | `BillingCycle` SoftDeletes+timestamps vs DDL columns absent | `_47` |
| GAP-PRM-001 | P1 | **REFUTED** — GenerateInvoicesCommand exists + registered (REQ-PRM-005 wiring present) | `_48` |

---

## 4. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_salesplanandmodulemgmt_01_schema_route_and_gate_configuration_are_correct` | TC-P01 | Config | 01-09 |
| 2 | `test_salesplanandmodulemgmt_02_primary_source_files_present` | TC-P02 | Config | 01-09 |
| 3 | `test_salesplanandmodulemgmt_03_models_back_expected_tables` | TC-P03 | Config | 01-09 |
| 4 | `test_salesplanandmodulemgmt_10_index_renders_three_tabs` | TC-P04 | Biz | 10-19 |
| 5 | `test_salesplanandmodulemgmt_11_billing_tab_lists_cycles` | TC-P05 | Biz | 10-19 |
| 6 | `test_salesplanandmodulemgmt_12_modules_tab_lists_modules` | TC-P06 | Biz | 10-19 |
| 7 | `test_salesplanandmodulemgmt_13_plans_tab_lists_plans` | TC-P07 | Biz | 10-19 |
| 8 | `test_salesplanandmodulemgmt_14_plan_detail_modal_markup_present` | TC-P08 | Biz | 10-19 |
| 9 | `test_salesplanandmodulemgmt_15_index_uses_distinct_pagination_params` | TC-P09 | Biz | 10-19 |
| 10 | `test_salesplanandmodulemgmt_30_search_and_status_controls_present` | TC-P10 | Val | 30-39 |
| 11 | `test_salesplanandmodulemgmt_31_search_filter_applies_without_error` | TC-P11 | Val | 30-39 |
| 12 | `test_salesplanandmodulemgmt_32_status_filter_active_and_inactive` | TC-P12 | Val | 30-39 |
| 13 | `test_salesplanandmodulemgmt_33_invalid_status_value_is_ignored` | TC-N01 | Val | 30-39 |
| 14 | `test_salesplanandmodulemgmt_34_no_match_search_shows_empty_state` | TC-N02 | Val | 30-39 |
| 15 | `test_salesplanandmodulemgmt_40_store_is_a_nonfunctional_stub` | TC-D02 | Int/DEV | 40-49 |
| 16 | `test_salesplanandmodulemgmt_41_update_and_destroy_are_nonfunctional_stubs` | TC-D03 | Int/DEV | 40-49 |
| 17 | `test_salesplanandmodulemgmt_42_store_post_creates_no_plan_row` | TC-D04 | Int/DEV | 40-49 |
| 18 | `test_salesplanandmodulemgmt_43_create_show_edit_reference_missing_views` | TC-D05 | Int/DEV | 40-49 |
| 19 | `test_salesplanandmodulemgmt_44_plan_billing_cycle_fk_is_restrict` | TC-D01 | Ref | 40-49 |
| 20 | `test_salesplanandmodulemgmt_45_module_plan_pivot_name_mismatch` | TC-D06 | Int/DEV | 40-49 |
| 21 | `test_salesplanandmodulemgmt_46_plan_fillable_omits_price_quarterly` | TC-D07 | Int/DEV | 40-49 |
| 22 | `test_salesplanandmodulemgmt_47_billing_cycle_softdelete_timestamp_gap` | TC-D08 | Int/DEV | 40-49 |
| 23 | `test_salesplanandmodulemgmt_48_generate_invoices_command_is_registered` | TC-P17 | Int | 40-49 |
| 24 | `test_salesplanandmodulemgmt_50_index_is_gated_by_view_any` | TC-AU01 | Auth | 50-59 |
| 25 | `test_salesplanandmodulemgmt_51_resource_gates_map_to_verbs` | TC-AU02 | Auth | 50-59 |
| 26 | `test_salesplanandmodulemgmt_52_view_tab_gates_differ_from_controller_gate` | TC-AU03 | Auth/DEV | 50-59 |
| 27 | `test_salesplanandmodulemgmt_53_policy_type_hints_tenant_plan_not_plan` | TC-AU04 | Auth/DEV | 50-59 |
| 28 | `test_salesplanandmodulemgmt_54_guest_is_redirected_to_login` | TC-N03 | Auth | 50-59 |
| 29 | `test_salesplanandmodulemgmt_55_authorized_admin_reaches_index` | TC-P13 | Auth | 50-59 |
| 30 | `test_salesplanandmodulemgmt_60_breadcrumb_title_present` | TC-P14 | UI | 60-69 |
| 31 | `test_salesplanandmodulemgmt_61_billing_pane_active_by_default` | TC-P15 | UI | 60-69 |
| 32 | `test_salesplanandmodulemgmt_62_plans_tab_click_shows_plans_pane` | TC-P16 | UI | 60-69 |
| 33 | `test_salesplanandmodulemgmt_90_runs_in_central_scope_without_tenancy` | TC-T01 | Tenancy | 90-99 |
| 34 | `test_salesplanandmodulemgmt_91_search_input_is_not_reflected_unescaped` | TC-N04 | Security | 90-99 |
| 35 | `test_salesplanandmodulemgmt_92_guest_delete_is_blocked` | TC-N05 | Security | 90-99 |
