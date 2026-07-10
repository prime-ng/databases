# prm_Tenant — Test Case List & Business Conditions

**Module:** Prime (PRM) · **Feature/Screen:** Tenant (central tenant CRUD + provisioning workflow)
**DB scope:** CENTRAL (`prime_db`) — this screen *manages* tenants but runs on the central host `http://127.0.0.1:8000`. No tenant init.
**Primary table:** `prm_tenant` (DDL-verified prefix `prm_`) · **Related:** `prm_tenant_domains`, `prm_tenant_plan_jnt`, `prm_tenant_plan_module_jnt`, `prm_tenant_groups`
**Controller:** `Modules\Prime\Http\Controllers\TenantController` · **Request:** `TenantRequest` · **Service (plan):** `TenantPlanAssigner`
**Provisioning job:** `App\Jobs\SetupTenantDatabase` · **Activity sink:** central `sys_central_activity_logs` (`Modules\Prime\Models\ActivityLog`)
**Test file:** `prm_Tenant_TestCas.php` (single comprehensive suite, 50 methods) · **Style:** browser Dusk + source-truth, `extends PrimeDuskTestCase`

> Provisioning (real DB creation, `tenants:migrate`, root user) cannot execute in the runner, so workflow/lifecycle facts are proven via literal-source + live-schema assertions; live-mutation paths are `markTestSkipped`-guarded.

---

## 1. Business Conditions

### BC-DB — Schema (Source: create_tenants_table + add_setup_progress + add_archive_and_rollover migrations; DDL `_prime_db_v4.sql`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `prm_tenant` exists with core columns (id, tenant_group_id, code, short_name, name, city_id, established_date, is_active, data, soft-delete) | DDL-prm_tenant / migration |
| BC-DB-02 | Lifecycle columns present live: setup_status, setup_progress, setup_message, tenant_type, parent_tenant_id, archived_session_id/code, rollover_status/progress/message | Migration |
| BC-DB-03 | `prm_tenant_domains` (domain, db_name, db_host, db_username, db_password, FK→prm_tenant) | DDL |
| BC-DB-04 | `prm_tenant_plan_jnt` (tenant_id, plan_id, is_subscribed, is_trial, status, is_active, generated `current_flag`, unique(current_flag,plan_id)) | DDL |
| BC-DB-05 | `prm_tenant_plan_module_jnt` (module_id, tenant_plan_id, is_active) | DDL |
| BC-DB-06 | `sys_central_activity_logs` central sink columns (subject_type/id, user_id, event, properties json) | Constraint #25 / migration |

### BC-VAL — Validation (Source: `TenantRequest`)
| ID | Condition | Message/Rule | Source |
|----|-----------|--------------|--------|
| BC-VAL-01 | tenant_group_id required·integer·exists prm_tenant_groups | required | Screen-VR-1 |
| BC-VAL-02 | code required·max:20·unique(prm_tenant,code) ignore current | unique | Screen-VR-2 |
| BC-VAL-03 | short_name max:50 unique · name max:150 unique | unique | Screen-VR-3 |
| BC-VAL-04 | domain required·max:20·alpha_dash; full_domain unique(prm_tenant_domains) | "This sub-domain is already taken…" | Screen-VR-4 |
| BC-VAL-05 | city_id / academic_session_id / board_id required·exists in global_master | required | Screen-VR-5 |
| BC-VAL-06 | email `email`, website_url `url`, established_date required `date` | format | Screen-VR-6 |
| BC-VAL-07 | prepareForValidation casts is_active boolean + builds full_domain | — | Screen-VR-7 |
| BC-VAL-08 | assignBoards: board_ids required·array·min:1·exists glb_boards; "Please select at least one board." | required | Screen-VR-8 |

### BC-AUTH — Permissions (Source: `TenantController` gates, `TenantRequest::authorize`)
| ID | Method(s) | Gate | Source |
|----|-----------|------|--------|
| BC-AUTH-01 | index | `prime.tenant.viewAny` | Screen-PM-1 |
| BC-AUTH-02 | create, store | `prime.tenant.create` | Screen-PM-2 |
| BC-AUTH-03 | show, setupProgress, setupStatus, rolloverStatus | `prime.tenant.view` | Screen-PM-3 |
| BC-AUTH-04 | edit, update, completeTenantSetup, startRollover, request/approve/revokeArchiveAccess, resetSetup, updateTenantPlan, assignBoards, tenantModuleToggle, toggleStatus, tenantPlanToggleStatus | `prime.tenant.update` | Screen-PM-4 |
| BC-AUTH-05 | destroy | `prime.tenant.delete` | Screen-PM-5 |
| BC-AUTH-06 | Guest → redirect `/login`; endpoints not public | Auth middleware | Screen-PM-6 |

### BC-BIZ — Business rules (Source: `TenantController`, `Tenant`, `SetupTenantDatabase`, `TenantPlanAssigner`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store() defaults is_active=0, setup_status='pending', progress=0, message='Queued for setup...'; dispatches SetupTenantDatabase; logs `created` | Controller |
| BC-BIZ-02 | Domain persisted as `{domain}.{app.domain}` | Controller |
| BC-BIZ-03 | DB name pattern `<short≤30>_<20-uuid>_<6-session>` | Model |
| BC-BIZ-04 | `live()` scope filters tenant_type='live'; index paginates 10 | Model / Controller |
| BC-BIZ-05 | isProfileComplete = has tenantPlans; canAccess = is_active && profile complete | Model |
| BC-BIZ-06 | computeAllowedModuleIds: TenantPlanModule rows are a blacklist (disabled hidden; default enabled) | Model |
| BC-BIZ-07 | tenantModuleToggle / tenantPlanToggleStatus flip is_active, return JSON, clear module cache | Controller |
| BC-BIZ-08 | updateTenantPlan runs a 5-step DB::transaction (plan→rate→modules→schedules), history-preserving (soft-disable, no delete) — BR-PRM-002..005/015 | Controller / TenantPlanAssigner |
| BC-BIZ-09 | destroy() soft-deletes (is_active=false + delete()) and logs `Trashed` | Controller |

### BC-SM — Provisioning state machine (Source: `SetupTenantDatabase`, `TenantController::resetSetup/startRollover`)
| ID | State → Trigger → Next | Legal? | Source |
|----|------------------------|--------|--------|
| BC-SM-01 | (new) → store → `pending` | legal | Controller store |
| BC-SM-02 | pending → job → creating_database → running_migrations → creating_root_user → adding_organization → `completed` | legal | Job |
| BC-SM-03 | any → job exception → `failed` | legal | Job catch |
| BC-SM-04 | completed/failed → resetSetup → `pending` (re-dispatch, reset=true) | legal | Controller |
| BC-SM-05 | pending/in-progress → resetSetup → **rejected** ("Setup can only be reset when it has failed or already completed.") | illegal | Controller guard |
| BC-SM-06 | non-live tenant → startRollover → **rejected** ("Rollover can only be started for a live tenant.") | illegal | Controller guard |
| BC-SM-07 | tenant_type ∈ {live, archive}; archiveTenants scoped to archive | — | Model/migration |

### BC-REF / BC-INT — FK & integration (Source: migrations, DDL, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | prm_tenant.tenant_group_id FK → prm_tenant_groups ON DELETE RESTRICT; city_id FK → glb_cities RESTRICT | Migration/DDL |
| BC-REF-02 | prm_tenant_domains.tenant_id FK → prm_tenant | DDL |
| BC-INT-01 | updateTenantPlan integrates BillingCycle + Plan + Module (global master) inside a transaction | Controller |
| BC-INT-02 | Each tenant provisioned into its own DB (`createDatabase`) — isolation | Job/Model |

### BC-EDG / BC-CFG
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Length boundaries: code 20, short_name 50, name 150, udise 30, affiliation 60, email 100 | Request |
| BC-EDG-02 | DB-name generator sanitises + truncates short_name to 30 chars; null session → 000000 | Model |
| BC-CFG-01 | full_domain built from `config('app.domain')` | Request/Controller |
| BC-EDG-03 | Consolidated DDL diverges from live schema (data/setup/rollover columns) — DOC-PRM-DDL-001 | DDL vs live |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01 | DDL/mig | Schema + model + request config truth | tables/cols/rules present | test_tenant_01 | ✅ |
| TC-P02 | BC-DB-02 | mig | Lifecycle columns exist live | 10 columns present | test_tenant_02 | ✅ |
| TC-P03 | BC-BIZ | Model | Tenancy contracts + media | interfaces/traits present | test_tenant_03 | ✅ |
| TC-P04 | BC-DB-04/05 | Model | Plan/module model config | tables/fillable | test_tenant_04 | ✅ |
| TC-P05 | BC-DB-06 | Model | Central log sink config | sys_central_activity_logs | test_tenant_05 | ✅ |
| TC-P10 | BC-BIZ-01 | Ctrl | store defaults setup state | pending/0/dispatch/log | test_tenant_10 | ✅ |
| TC-P11 | BC-BIZ-02 | Ctrl | Domain suffix persistence | {domain}.{app.domain} | test_tenant_11 | ✅ |
| TC-P12 | BC-BIZ-03 | Model | DB-name pattern | regex match | test_tenant_12 | ✅ |
| TC-P13 | BC-BIZ-04 | Model | live() scope | filters tenant_type | test_tenant_13 | ✅ |
| TC-P14 | BC-BIZ-05 | Model | profile/access logic | source match | test_tenant_14 | ✅ |
| TC-P16 | BC-BIZ-06 | Model | blacklist module semantics | diff(disabled) | test_tenant_16 | ✅ |
| TC-P25 | BC-BIZ-07 | Ctrl | rolloverStatus JSON shape | status/progress/message | test_tenant_25 | ✅ |
| TC-P26 | BC-BIZ-08 | Ctrl | setupStatus JSON shape | +name | test_tenant_26 | ✅ |
| TC-P36 | BC-VAL-07 | Req | prepareForValidation | boolean + full_domain | test_tenant_36 | ✅ |
| TC-P45 | BC-BIZ-07 | Ctrl | module toggle JSON | enabled/disabled + cache | test_tenant_45 | ✅ |
| TC-P60 | BC-UIX | View | index renders (guarded) | headers visible | test_tenant_60 | ✅ |
| TC-P61 | BC-UIX | View | create form fields (guarded) | 8 fields present | test_tenant_61 | ✅ |
| TC-P62 | BC-UIX | View | mgmt console loads (guarded) | path match | test_tenant_62 | ✅ |
| TC-P64 | BC-BIZ-04 | Ctrl | paginate(10) | source match | test_tenant_64 | ✅ |

### State machine (TC-SM, band 20-29)
| TC ID | BC | Description | Expected | Method | Status |
|-------|----|-------------|----------|--------|--------|
| TC-SM01 | BC-SM-01/02 | Lifecycle states present | 6 states in job + pending | test_tenant_20 | ✅ |
| TC-SM02 | BC-SM-02 | Progress checkpoints monotonic | 2→5→…→100 | test_tenant_21 | ✅ |
| TC-SM03 | BC-SM-04 | reset from failed/completed re-dispatches | reset=true | test_tenant_22 | ✅ |
| TC-SM04 | BC-SM-05 | illegal reset from pending rejected | error message | test_tenant_23 | ✅ |
| TC-SM05 | BC-SM-06 | rollover only for live tenant | isLive guard | test_tenant_24 | ✅ |
| TC-SM06 | BC-SM-07 | tenant_type live/archive | source match | test_tenant_27 | ✅ |

### Negative (TC-N)
| TC ID | BC | Description | Expected | Method | Status |
|-------|----|-------------|----------|--------|--------|
| TC-N30 | BC-AUTH-06 | Guest create → login | redirect /login | test_tenant_30 | ✅ |
| TC-N31 | BC-VAL-01/05 | Required rules present | 9 fields required | test_tenant_31 | ✅ |
| TC-N32 | BC-VAL-02 | unique ignore-on-update | ->ignore($tenantId) | test_tenant_32 | ✅ |
| TC-N33 | BC-VAL-04 | full_domain message/attribute | exact strings | test_tenant_33 | ✅ |
| TC-N34 | BC-VAL-04/06 | domain alpha_dash + formats | rules present | test_tenant_34 | ✅ |
| TC-N38 | BC-VAL | Invalid id → 404 (guarded) | Not Found | test_tenant_38 | ✅ |
| TC-N46 | BC-VAL-08 | assignBoards validation | required/exists/message | test_tenant_46 | ✅ |
| TC-N53 | BC-AUTH-06 | Guest index → login | redirect /login | test_tenant_53 | ✅ |
| TC-N94 | BC-SEC-02 | Guest setup-status blocked | login/403/401 | test_tenant_94 | ✅ |

### Dependency (TC-D) & Permissions/Routes
| TC ID | Sub | BC | Description | Expected | Method | Status |
|-------|-----|----|-------------|----------|--------|--------|
| TC-D40 | C | BC-REF-01 | tenant_group + city FK RESTRICT | migration content | test_tenant_40 | ✅ |
| TC-D41 | C | BC-REF-02 | domain FK → tenant | info_schema (guarded) | test_tenant_41 | ✅ |
| TC-D43 | E/F | BC-INT-01 | updateTenantPlan 5-step txn | transaction steps | test_tenant_43 | ✅ |
| TC-AUTH37 | — | BC-AUTH | authorize action map | store/update/viewAny | test_tenant_37 | ✅ |
| TC-AUTH50 | — | BC-AUTH-01..05 | all methods gated (21) | gate strings + count | test_tenant_50 | ✅ |
| TC-AUTH54 | — | BC-AUTH | routes registered | 21 route names | test_tenant_54 | ✅ |

### Tenancy / Security (TC-T / TC-S, band 90-99)
| TC ID | BC | Description | Expected | Method | Status |
|-------|----|-------------|----------|--------|--------|
| TC-T90 | BC-TEN | central context, no tenant init | !tenancy()->initialized | test_tenant_90 | ✅ |
| TC-T91 | BC-INT-02 | per-tenant isolated DB | createDatabase source | test_tenant_91 | ✅ |
| TC-S93 | BC-SEC-01 | mass-assign validated only | no $request->all() | test_tenant_93 | ✅ |

### Edge (TC-E, band 70-79)
| TC ID | BC | Description | Method | Status |
|-------|----|-------------|--------|--------|
| TC-E70 | BC-EDG-01 | length boundaries | test_tenant_70 | ✅ |
| TC-E71 | BC-EDG-02 | db-name sanitise/truncate | test_tenant_71 | ✅ |
| TC-E73 | BC-EDG-03 | DDL/live divergence | test_tenant_73 | ✅ |

### Known Source Defects (verified against current source)
| ID | Sev | Description | Status in source | Proving test |
|----|-----|-------------|------------------|--------------|
| BUG-PRM-TENANT-001 | P1 (NEW) | Routes `tenant.trashed`/`restore`/`forceDelete` bind to controller methods `trashedTenant`/`restore`/`forceDelete` that **do not exist** → 500 on access | **REPRODUCES** | test_tenant_55 |
| DOC-PRM-DDL-001 | P3 | Consolidated `_prime_db_v4.sql` diverges from live schema (missing `data`, setup/rollover/archive columns; DDL id INT vs migration string PK) | Documented | test_tenant_02 / _73 |
| GAP-PRM-003 | P0 (reported) | SetupTenantDatabase hardcoded root password | **FIXED** — now `Str::password(16)` + emailed | test_tenant_15 |
| BUG-PRM-006 | P1 (reported) | completeTenantSetup/toggleStatus/tenantPlanToggleStatus wrong gate `prime.tenant-group.update` | **FIXED** — all use `prime.tenant.update` | test_tenant_51 |
| BUG-PRM-STUB-001 | P2 (reported) | destroy() empty stub | **FIXED** — soft-deletes + logs `Trashed` | test_tenant_52 |
| MIG-PRM-001 | P1 (reported) | create_tenants down() drops `tenants` not `prm_tenant` | **FIXED** — `Schema::dropIfExists('prm_tenant')` | test_tenant_40 (file read) |
| GAP-PRM-001 | P1 (reported) | GenerateInvoicesCommand missing | **RESOLVED** — file present in Modules/Billing/app/Console/Commands | (referenced) |

---

## 3. Test Method Index

| # | Method | Band | TC Map |
|---|--------|------|--------|
| 1 | test_tenant_01_migration_model_and_request_configuration_are_correct | 01 | TC-P01 |
| 2 | test_tenant_02_prm_tenant_has_setup_and_rollover_lifecycle_columns | 02 | TC-P02 |
| 3 | test_tenant_03_tenant_model_implements_tenancy_contracts_and_media | 03 | TC-P03 |
| 4 | test_tenant_04_plan_and_module_models_configuration | 04 | TC-P04 |
| 5 | test_tenant_05_central_activity_log_sink_configuration | 05 | TC-P05 |
| 6 | test_tenant_10_store_defaults_setup_state_from_source | 10 | TC-P10 |
| 7 | test_tenant_11_store_persists_domain_with_app_domain_suffix | 11 | TC-P11 |
| 8 | test_tenant_12_generate_database_name_pattern | 12 | TC-P12 |
| 9 | test_tenant_13_live_scope_filters_tenant_type | 13 | TC-P13 |
| 10 | test_tenant_14_profile_complete_and_can_access_logic | 14 | TC-P14 |
| 11 | test_tenant_15_setup_job_uses_random_root_password_not_hardcoded | 15 | GAP-PRM-003 |
| 12 | test_tenant_16_compute_allowed_module_ids_blacklist_semantics | 16 | TC-P16 |
| 13 | test_tenant_20_setup_status_lifecycle_states_present_in_job | 20 | TC-SM01 |
| 14 | test_tenant_21_setup_progress_monotonic_values | 21 | TC-SM02 |
| 15 | test_tenant_22_reset_setup_only_allowed_from_failed_or_completed | 22 | TC-SM03 |
| 16 | test_tenant_23_illegal_reset_from_pending_or_inprogress_rejected | 23 | TC-SM04 |
| 17 | test_tenant_24_rollover_only_for_live_tenant | 24 | TC-SM05 |
| 18 | test_tenant_25_rollover_status_json_shape | 25 | TC-P25 |
| 19 | test_tenant_26_setup_status_json_shape | 26 | TC-P26 |
| 20 | test_tenant_27_tenant_type_enum_live_archive | 27 | TC-SM06 |
| 21 | test_tenant_30_guest_create_form_redirects_to_login | 30 | TC-N30 |
| 22 | test_tenant_31_required_field_rules_present | 31 | TC-N31 |
| 23 | test_tenant_32_unique_rules_ignore_current_on_update | 32 | TC-N32 |
| 24 | test_tenant_33_full_domain_unique_message_and_attribute | 33 | TC-N33 |
| 25 | test_tenant_34_domain_alpha_dash_and_format_rules | 34 | TC-N34 |
| 26 | test_tenant_36_prepare_for_validation_builds_full_domain_and_boolean | 36 | TC-P36 |
| 27 | test_tenant_37_authorize_maps_action_to_gate | 37 | TC-AUTH37 |
| 28 | test_tenant_38_invalid_tenant_id_shows_not_found | 38 | TC-N38 |
| 29 | test_tenant_40_tenant_group_and_city_fk_restrict | 40 | TC-D40 |
| 30 | test_tenant_41_domain_fk_references_tenant | 41 | TC-D41 |
| 31 | test_tenant_43_update_tenant_plan_transaction_steps | 43 | TC-D43 |
| 32 | test_tenant_45_tenant_plan_module_toggle_json | 45 | TC-P45 |
| 33 | test_tenant_46_assign_boards_validates_board_ids | 46 | TC-N46 |
| 34 | test_tenant_50_all_controller_methods_have_correct_gate | 50 | TC-AUTH50 |
| 35 | test_tenant_51_no_wrong_tenant_group_gate_bug006_fixed | 51 | BUG-PRM-006 |
| 36 | test_tenant_52_destroy_is_implemented_not_empty_stub | 52 | BUG-PRM-STUB-001 |
| 37 | test_tenant_53_index_requires_authentication | 53 | TC-N53 |
| 38 | test_tenant_54_routes_registered_central_prime_tenant | 54 | TC-AUTH54 |
| 39 | test_tenant_55_trashed_restore_forcedelete_controller_methods_missing_defect | 55 | BUG-PRM-TENANT-001 |
| 40 | test_tenant_60_index_page_loads_for_admin | 60 | TC-P60 |
| 41 | test_tenant_61_create_form_renders_required_fields | 61 | TC-P61 |
| 42 | test_tenant_62_tenant_management_index_loads | 62 | TC-P62 |
| 43 | test_tenant_64_index_paginates_ten_per_page | 64 | TC-P64 |
| 44 | test_tenant_70_code_and_domain_max_length_boundary | 70 | TC-E70 |
| 45 | test_tenant_71_generate_db_name_sanitises_and_truncates | 71 | TC-E71 |
| 46 | test_tenant_73_live_schema_diverges_from_consolidated_ddl | 73 | TC-E73 / DOC-PRM-DDL-001 |
| 47 | test_tenant_90_runs_on_central_context_without_tenant_init | 90 | TC-T90 |
| 48 | test_tenant_91_each_tenant_gets_isolated_database | 91 | TC-T91 |
| 49 | test_tenant_93_mass_assignment_uses_validated_only | 93 | TC-S93 |
| 50 | test_tenant_94_guest_cannot_reach_setup_status_json | 94 | TC-N94 |
