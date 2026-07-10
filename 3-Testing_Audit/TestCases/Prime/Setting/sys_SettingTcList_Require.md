# Setting (Prime / System Config) — Test Case List & Business Conditions

- **Module:** Prime (PRM) — **central** (`prime_db`), no tenancy.
- **Screen:** System Config → Setting (`central.system-config.setting.*`)
- **Primary table:** `sys_settings` (DDL-verified prefix `sys_`; module registry says `prm_` — file prefix follows the DDL table prefix → **`sys_`**).
- **Controller:** `Modules\Prime\Http\Controllers\SettingController` (uses `Modules\SystemConfig\Models\Setting`).
- **Model:** `Modules\SystemConfig\Models\Setting` (canonical); `Modules\Prime\Models\Setting` (`@deprecated`, same table).
- **Test file:** `sys_Setting_TestCas.php` — one comprehensive Dusk suite (37 methods), `extends PrimeDuskTestCase`, host `http://127.0.0.1:8000`.
- **CRUD reality:** READ + single-field **update** only. Create/Store/Show/Destroy are non-functional stubs (see DEV defects). No soft-delete, no activity logging.

> No `Prime_v1` requirement screen file exists for this module, so the **application source is the primary requirement source** for this feature.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-sys_settings`, `_prime_db_v4.sql:166`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_settings.id` INT UNSIGNED PK auto-increment | DDL-sys_settings |
| BC-DB-02 | `description` VARCHAR(255) NULL | DDL-sys_settings |
| BC-DB-03 | `key` VARCHAR(100) NOT NULL | DDL-sys_settings |
| BC-DB-04 | `value` VARCHAR(255) NULL | DDL-sys_settings |
| BC-DB-05 | `type` VARCHAR(50) NULL | DDL-sys_settings |
| BC-DB-06 | `is_public` TINYINT(1) NOT NULL DEFAULT 0 | DDL-sys_settings |
| BC-DB-07 | Timestamps `created_at`/`updated_at` present; **no** `deleted_at` (no soft-delete) | DDL-sys_settings |
| BC-DB-08 | UNIQUE KEY `uq_settings_key` on `key` | DDL-sys_settings |

### BC-VAL — Validation (Source: `SettingController::update()` inline validate)
| ID | Rule | Message | Source |
|----|------|---------|--------|
| BC-VAL-01 | `value` required | default Laravel `required` | Ctrl-update |
| BC-VAL-02 | `key` required, string, `exists:sys_settings,key` | default `exists` | Ctrl-update |
| BC-VAL-03 | Valid update sets `value`, saves, redirects to index with `success` flash | — | Ctrl-update |

### BC-AUTH — Permissions (Source: `SettingController` `Gate::authorize`, `index.blade.php @can`)
| ID | Method | Gate | Source |
|----|--------|------|--------|
| BC-AUTH-01 | index | `prime.setting.viewAny` | Ctrl:17 |
| BC-AUTH-02 | create/store | `prime.setting.create` | Ctrl:32,42 |
| BC-AUTH-03 | show | `prime.setting.view` | Ctrl:52 |
| BC-AUTH-04 | edit/update | `prime.setting.update` | Ctrl:62,73 |
| BC-AUTH-05 | destroy | `prime.setting.delete` | Ctrl:93 |
| BC-AUTH-06 | **search — NO gate (DEV-001)** | *(none)* | Ctrl:98 |
| BC-AUTH-07 | Index view `@can('prime.setting.viewAny')` wraps content; `@can('prime.setting.update')` wraps Action column | Blade | index.blade:5,59,74 |
| BC-AUTH-08 | Routes behind `auth`,`verified` middleware → guest redirected to `/login` | routes/web.php:292 |
| BC-AUTH-09 | Super Admin bypass via `is_super_admin && super_admin_flag` or role `Super Admin` | AppServiceProvider:64 |

### BC-BIZ — Business logic (Source: Controller / Model / Views)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `setKeyAttribute` mutator `Str::snake()`s the key on write | Model:26 |
| BC-BIZ-02 | `getDisplayKeyAttribute` humanises key (`default_language`→`Default Language`) | Model:31 |
| BC-BIZ-03 | update finds by `key`, sets `value`, `save()`, redirect `central.system-config.setting.index` + success flash | Ctrl:80-85 |
| BC-BIZ-04 | **No activity logging** anywhere in the controller | Ctrl (whole) |
| BC-BIZ-05 | index paginates 10/page | Ctrl:22 |
| BC-BIZ-06 | index renders table (Key/Value/Types/Is Public) + search controls | index.blade |
| BC-BIZ-07 | Breadcrumb title = "System Config" | index.blade:3 |
| BC-BIZ-08 | Search input wires `setting.search` (data-search-url) + `setting.index` (data-redirect-url) | index.blade:24-25 |
| BC-BIZ-09 | Empty state renders "No Setting Data Found" | index.blade:85 |
| BC-BIZ-10 | Edit form: value input + hidden `key`; breadcrumb "Edit Setting"; `default_language` uses language selector | edit.blade |
| BC-BIZ-11 | search() returns JSON `{key,description}` matching `key` OR `description` LIKE `%term%`, ordered by key, limit 10 | Ctrl:98-114 |
| BC-BIZ-12 | search() with empty string returns `[]` (short-circuit) | Ctrl:102 |

### BC-INT / BC-REF — Integration / referential (Source: DDL + models)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Both `Prime\Models\Setting` and `SystemConfig\Models\Setting` map `sys_settings` with identical fillable | Models |
| BC-INT-02 | Duplicate `key` insert violates unique index | DDL-uq_settings_key |
| BC-REF-01 | `sys_settings` declares no outbound FKs | DDL-sys_settings |

### BC-EDG — Edge (Source: Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `edit($id)` uses `findOrFail` → 404 on unknown id | Ctrl:64 |

### BC-CFG — Configuration
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | `is_public` defaults 0 when unspecified | DDL-sys_settings |
| BC-CFG-02 | `default_language` key triggers language selector branch in edit view | edit.blade:33 |

### State machine (BC-SM)
> **N/A** — Setting has no status/workflow lifecycle. Band 20–29 intentionally empty.

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..08 | DDL | Table/columns/unique/no-softdelete correct | All asserts pass | `test_setting_01` | ✅ |
| TC-P02 | Config | BC-CFG-01 | DDL | `is_public` defaults 0 | 0 persisted | `test_setting_03` | ✅ |
| TC-P03 | Biz | BC-BIZ-01 | Model | Key mutator snake_cases | `my_test_key` | `test_setting_10` | ✅ |
| TC-P04 | Biz | BC-BIZ-02 | Model | displayKey accessor | "Default Language" | `test_setting_11` | ✅ |
| TC-P05 | Biz | BC-BIZ-03,VAL-03 | Ctrl | Update persists value + redirects | value saved, → index | `test_setting_12` | ✅ |
| TC-P06 | Biz | BC-BIZ-05 | Ctrl | Paginates 10/page | `paginate(10)` | `test_setting_14` | ✅ |
| TC-P07 | Int | BC-INT-01 | Models | Model parity | same table+fillable | `test_setting_40` | ✅ |
| TC-P08 | UI | BC-BIZ-06 | Blade | Index renders table + search | present | `test_setting_60` | ✅ |
| TC-P09 | UI | BC-BIZ-07 | Blade | Breadcrumb System Config | visible | `test_setting_61` | ✅ |
| TC-P10 | UI | BC-BIZ-08 | Blade | Search wiring urls | both routes present | `test_setting_62` | ✅ |
| TC-P11 | UI | BC-BIZ-10 | Blade | Edit form renders | value+key present | `test_setting_64` | ✅ |
| TC-P12 | Biz | BC-BIZ-11 | Ctrl | Search returns matching JSON | fragment matches | `test_setting_65` | ✅ |
| TC-P13 | Biz | BC-BIZ-12 | Ctrl | Empty search → `[]` | exact `[]` | `test_setting_66` | ✅ |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Val | BC-VAL-01 | Ctrl | Missing value | error on `value`, unchanged | `test_setting_30` | ✅ |
| TC-N02 | Val | BC-VAL-02 | Ctrl | Missing key | error on `key` | `test_setting_31` | ✅ |
| TC-N03 | Val | BC-VAL-02 | Ctrl | Non-existent key | error on `key` | `test_setting_32` | ✅ |
| TC-N04 | Val | BC-VAL-01 | Ctrl | Empty-string value | error on `value` | `test_setting_33` | ✅ |
| TC-N05 | Edg | BC-EDG-01 | Ctrl | Edit unknown id | 404 | `test_setting_70` | ✅ |
| TC-N06 | Auth | BC-AUTH-08 | routes | Guest → login | `/login` | `test_setting_53` | ✅ |
| TC-N07 | Auth | BC-AUTH-01 | Ctrl | Limited user index | 403 | `test_setting_54` | ✅ |
| TC-N08 | Sec | TC-S01 | Ctrl/Blade | XSS stored raw, escaped out | no live script tag | `test_setting_91` | ✅ |
| TC-N09 | Sec | TC-S02 | Ctrl | Injection-shaped search | 200, array | `test_setting_92` | ✅ |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C/G | BC-INT-02 | DDL | Duplicate key rejected | throws | `test_setting_42` | ✅ |
| TC-D02 | E | BC-REF-01 | DDL | No FK dependencies | empty | `test_setting_41` | ✅ |
| TC-D03 | E | BC-INT-01 | Models | Prime↔SystemConfig parity | equal | `test_setting_40` | ✅ |

### Permissions / config truth (TC-A/AUTH)
| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-AUTH01 | BC-AUTH-01..05 | Ctrl | Gate strings present on RESTful methods | `test_setting_50` | ✅ |
| TC-AUTH02 | BC-AUTH-07 | Blade | `@can` gates in index view | `test_setting_52` | ✅ |
| TC-VAL-CFG | BC-VAL-01,02 | Ctrl | Inline validate rules declared | `test_setting_02` | ✅ |

### Known Source Defects (DEV-###) — proving tests
| DEV | Description | Source | Proving method | Status |
|-----|-------------|--------|----------------|--------|
| DEV-001 | `search()` has **no** `Gate::authorize` → **BR-PRM-022 FAILS** (search not permission-gated) | Ctrl:98-114 | `test_setting_51` | ✅ proven |
| DEV-002 | `store()` returns `$request` — create is a no-op (no persistence) | Ctrl:40-45 | `test_setting_71` | ✅ proven |
| DEV-003 | `destroy()` empty — delete is a no-op | Ctrl:91-95 | `test_setting_72` | ✅ proven |
| DEV-004 | `create()` returns `view('prime::create')` — view missing → 500 | Ctrl:30-35 | `test_setting_73` | ✅ proven |
| DEV-005 | `show()` returns `view('prime::show')` — view missing → 500 | Ctrl:50-55 | `test_setting_74` | ✅ proven |
| DEV-006 | `edit.blade.php` reads `$setting->organization_id` — column absent from `sys_settings` | edit.blade:29 | `test_setting_75` | ✅ proven |
| DEV-007 | `index()` calls `Setting::all()` twice as dead code before `paginate()` | Ctrl:19-22 | `test_setting_76` | ✅ proven |
| DEV-008 | No activity logging on update (no audit trail) | Ctrl | `test_setting_13` | ✅ proven |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_setting_01_schema_model_and_route_configuration_are_correct` | TC-P01 | Schema | 01 |
| 2 | `test_setting_02_controller_declares_inline_update_validation_rules` | TC-VAL-CFG | Config | 01 |
| 3 | `test_setting_03_is_public_defaults_to_zero_and_type_is_nullable` | TC-P02 | Config | 01 |
| 4 | `test_setting_10_key_mutator_snake_cases_on_write` | TC-P03 | Biz | 10 |
| 5 | `test_setting_11_display_key_accessor_humanises_key` | TC-P04 | Biz | 10 |
| 6 | `test_setting_12_update_persists_new_value_and_redirects_to_index` | TC-P05 | Biz | 10 |
| 7 | `test_setting_13_update_writes_no_activity_log_entry` | DEV-008 | Biz | 10 |
| 8 | `test_setting_14_index_paginates_ten_per_page` | TC-P06 | Biz | 10 |
| 9 | `test_setting_30_update_rejects_missing_value` | TC-N01 | Val | 30 |
| 10 | `test_setting_31_update_rejects_missing_key` | TC-N02 | Val | 30 |
| 11 | `test_setting_32_update_rejects_non_existent_key` | TC-N03 | Val | 30 |
| 12 | `test_setting_33_update_rejects_empty_string_value` | TC-N04 | Val | 30 |
| 13 | `test_setting_40_prime_and_systemconfig_models_map_same_table` | TC-P07/TC-D03 | Int | 40 |
| 14 | `test_setting_41_settings_table_has_no_foreign_keys` | TC-D02 | Ref | 40 |
| 15 | `test_setting_42_duplicate_key_insert_is_rejected_by_unique_index` | TC-D01 | Int | 40 |
| 16 | `test_setting_50_restful_methods_declare_permission_gates` | TC-AUTH01 | Auth | 50 |
| 17 | `test_setting_51_search_endpoint_is_ungated_defect_dev001` | DEV-001 | Auth | 50 |
| 18 | `test_setting_52_index_view_gates_content_and_action_column` | TC-AUTH02 | Auth | 50 |
| 19 | `test_setting_53_guest_is_redirected_to_login` | TC-N06 | Auth | 50 |
| 20 | `test_setting_54_limited_user_receives_403_on_index` | TC-N07 | Auth | 50 |
| 21 | `test_setting_60_index_renders_table_and_search_controls` | TC-P08 | UI | 60 |
| 22 | `test_setting_61_index_shows_system_config_breadcrumb` | TC-P09 | UI | 60 |
| 23 | `test_setting_62_search_input_wires_search_and_redirect_urls` | TC-P10 | UI | 60 |
| 24 | `test_setting_63_index_shows_empty_state_message_markup` | BC-BIZ-09 | UI | 60 |
| 25 | `test_setting_64_edit_form_renders_value_input_and_hidden_key` | TC-P11 | UI | 60 |
| 26 | `test_setting_65_search_endpoint_returns_matching_json` | TC-P12 | UI | 60 |
| 27 | `test_setting_66_search_with_empty_term_returns_empty_array` | TC-P13 | UI | 60 |
| 28 | `test_setting_70_edit_non_existent_id_returns_404` | TC-N05 | Edg | 70 |
| 29 | `test_setting_71_store_is_a_noop_defect_dev002` | DEV-002 | Edg | 70 |
| 30 | `test_setting_72_destroy_is_a_noop_defect_dev003` | DEV-003 | Edg | 70 |
| 31 | `test_setting_73_create_view_is_missing_defect_dev004` | DEV-004 | Edg | 70 |
| 32 | `test_setting_74_show_view_is_missing_defect_dev005` | DEV-005 | Edg | 70 |
| 33 | `test_setting_75_organization_id_column_absent_defect_dev006` | DEV-006 | Edg | 70 |
| 34 | `test_setting_76_index_contains_dead_setting_all_calls_defect_dev007` | DEV-007 | Edg | 70 |
| 35 | `test_setting_90_feature_is_central_scope_no_tenant_isolation` | TC-T00 | Tenancy | 90 |
| 36 | `test_setting_91_value_field_stores_xss_payload_verbatim_and_view_escapes` | TC-N08 | Sec | 90 |
| 37 | `test_setting_92_search_handles_injection_shaped_input_safely` | TC-N09 | Sec | 90 |
