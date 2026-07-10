# Dropdown — Test Case List & Business Conditions (`sys_`)

- **Module:** GlobalMaster (GLB) — **Prime / Central** (`prime_db`)
- **Feature / Screen:** Dropdown (Global Master → Dropdown; multi-tab: dropdown-need / dropdown-list / create-dropdown-jnt)
- **Primary table:** `sys_dropdown_table`
  - **PREFIX FLAG:** the artifact prefix is **`sys_`** (NOT `glb_`). The Dropdown table lives in the **central/prime DB** (`sys_dropdown_table`, DDL-verified), not the global DB — hence `sys_`.
- **Live controller (serves central):** `Modules\Prime\Http\Controllers\DropdownController` (view `prime::index`)
- **Dead controller (GlobalMaster, not live on central):** `Modules\GlobalMaster\Http\Controllers\DropdownController`
- **Active model (both map here):** `Modules\Prime\Models\Dropdown` (preferred) / `Modules\GlobalMaster\Models\Dropdown` (`app/Models`) → `sys_dropdown_table`
- **Orphaned duplicate model:** `Modules\GlobalMaster\Models\Dropdown` at `Models/` (outside `app/`, NOT PSR-4-autoloaded)
- **FormRequest (GlobalMaster, thin):** `Modules\GlobalMaster\Http\Requests\DropdownRequest`
- **Route family:** `central.global-master.dropdown.*` → path `/global-master/dropdown`
- **Test file:** `sys_Dropdown_TestCas.php` (40 methods, single suite)
- **Test style:** Browser Dusk extending `\Tests\DuskTestCase` with the central helper library copied INLINE (127.0.0.1:8000). Endpoint/route checks via `postJson` / `Route::has`; live business logic proven from Prime controller source; DB-mutation cases guarded/defensive.

---

## 1. Business Conditions

### BC-DB (schema — Source: `DDL _prime_db_v4.sql` `sys_dropdown_table`, lines ~222–235)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_dropdown_table` exists with `id, ordinal, key, value, type, additional_info, is_active, created_at, updated_at` | DDL |
| BC-DB-02 | `ordinal TINYINT UNSIGNED NOT NULL` (no default) | DDL |
| BC-DB-03 | `key VARCHAR(160)`, `value VARCHAR(100)` | DDL |
| BC-DB-04 | `type ENUM('String','Integer','Decimal','Date','Datetime','Time','Boolean') DEFAULT 'String'` | DDL |
| BC-DB-05 | `additional_info JSON`, `is_active TINYINT(1) DEFAULT 1` | DDL |
| BC-DB-06 | `UNIQUE (key, ordinal)` + `UNIQUE (key, value)` | DDL |
| BC-DB-07 | **NO `deleted_at` column** in the consolidated DDL (**DEV-GLB-D04**) | DDL vs Model |
| BC-DB-08 | Active model casts: `ordinal=integer`, `is_active=boolean`, `additional_info=array`, `deleted_at=datetime` | Model |
| BC-DB-09 | Active model `$fillable = [ordinal, key, value, type, additional_info, is_active]` — `org_id`/`dropdown_needs_id` NOT fillable | Model |

### BC-VAL (validation — divergent paths)

| ID | Rule | Path / Source |
|----|------|---------------|
| BC-VAL-01 | `key required\|string\|max:160\|unique:sys_dropdown_table,key` | LIVE Prime `store()` |
| BC-VAL-02 | `value required\|string\|max:100` | LIVE Prime `store()` |
| BC-VAL-03 | `type required\|in:String,Integer,Decimal,Date,Datetime,Time,Boolean` | LIVE Prime `store()` |
| BC-VAL-04 | `is_active nullable\|boolean`; `ordinal nullable\|integer\|min:1`; `additional_info nullable\|string` | LIVE Prime `store()` |
| BC-VAL-05 | `toggleStatus` requires `is_active required\|boolean` | LIVE Prime `toggleStatus()` |
| BC-VAL-06 | **DEV-GLB-D03:** GlobalMaster `DropdownRequest` `value max:255` (> DB `VARCHAR(100)`) + `is_active required\|boolean`; unique keyed off `table_name.column_name` | GlobalMaster `DropdownRequest::rules()` |

### BC-AUTH (authorization — Source: Prime `DropdownController` `Gate::authorize`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `prime.dropdown.viewAny/view/create/update/delete/restore/forceDelete` gate each action | Controller |
| BC-AUTH-02 | `toggleStatus` authorizes `prime.dropdown.update` | Controller |
| BC-AUTH-03 | some bulk/map routes authorize `prime.dropdown-need.update` | Controller |
| BC-AUTH-04 | Route group middleware `auth,verified` — guest → `/login`; guest POST rejected | routes |

### BC-BIZ (business logic — Source: LIVE Prime `store()/update()/destroy()/restore()/forceDelete()/toggleStatus()`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Tabbed index screen (`prime::index`) at `/global-master/dropdown` | Controller@index |
| BC-BIZ-02 | `store()` requires a resolvable `dropdown_need_id` (else redirect back / to dropdown-need index) | `create()`/`store()` |
| BC-BIZ-03 | `store()` derives `ordinal = max('ordinal') + 1` when none supplied; creates `DropdownNeedTableJnt` junction | `store()` |
| BC-BIZ-04 | Activity events VERBATIM: `destroy → 'Trashed'`, `restore → 'Restored'`, `toggleStatus → 'Toggled'` (sink `sys_central_activity_logs`) | Controller |
| BC-BIZ-05 | `toggleStatus` returns JSON `{success, is_active, message}` and syncs junction `is_active` | `toggleStatus()` |
| BC-BIZ-06 | `destroy()` sets `is_active=false` + soft-deletes + deactivates junction | `destroy()` |
| BC-BIZ-07 | `forceDelete()` deletes junction FIRST, then the dropdown row | `forceDelete()` |

### BC-INT / BC-REF (integration — Source: models, junction)

| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `Dropdown::dropdownNeeds()` belongsToMany `DropdownNeed` via junction | Model |
| BC-REF-01 | `destroy/restore/forceDelete` touch the junction (`sys_dropdown_need_*_jnt`) | Controller |
| BC-REF-02 | Junction model `DropdownNeedTableJnt` → `sys_dropdown_need_table_jnt`; fillable `dropdown_needs_id, dropdown_table_id, is_active` | Model |

### BC-EDG / defects

| ID | Condition | DEV |
|----|-----------|-----|
| BC-EDG-01 | Orphaned duplicate `Modules\GlobalMaster\Models\Dropdown` (outside `app/`, not autoloaded, no `$table`→`dropdowns`, fillable incl `org_id`) | **DEV-GLB-D01** |
| BC-EDG-02 | GlobalMaster own `store()` reads `org_id/key/type` absent from its own `DropdownRequest::rules()` → undefined-array-key; `org_id` not fillable → dropped | **DEV-GLB-D02** |
| BC-EDG-03 | GlobalMaster `DropdownRequest` `value max:255` > DB `VARCHAR(100)` → 101–255-char values pass then error/truncate; live Prime store is `max:100` | **DEV-GLB-D03** |
| BC-EDG-04 | SoftDeletes on a table whose consolidated DDL lacks `deleted_at` | **DEV-GLB-D04** |
| BC-EDG-05 | Route-wiring drift: `Modules/GlobalMaster/routes/web.php` wires the DEAD GlobalMaster controller while digested truth serves via Prime | Note (reconciliation) |

---

## 2. Test Case List

### Positive (`TC-P`)

| TC ID | BC | Source | Description | Method |
|-------|----|--------|-------------|--------|
| TC-P01 | BC-DB-01..06 | DDL | Table + DDL columns present; prefix `sys_` | `_01` |
| TC-P02 | BC-DB-08/09 | Model | Active model table/fillable/casts/SoftDeletes | `_02` |
| TC-P03 | BC-EDG-01 | Model | Orphaned duplicate model not autoloaded (DEV-GLB-D01) | `_03` |
| TC-P04 | BC-VAL-06 | Request | GlobalMaster request value max:255 (DEV-GLB-D03 seed) | `_04` |
| TC-P05 | BC-DB-07 | Model/DDL | SoftDelete column gap guarded (DEV-GLB-D04) | `_05` |
| TC-P06 | BC-EDG-02 | Controller/Request | GlobalMaster own store broken (DEV-GLB-D02) | `_06` |
| TC-P07 | BC-BIZ-01 | Screen | Tabbed index loads | `_10` |
| TC-P08 | BC-VAL-01..04 | Controller | Live store rules exact | `_11` |
| TC-P09 | BC-BIZ-03 | Controller | Ordinal auto-increment + junction creation | `_12` |
| TC-P10 | BC-BIZ-04 | Controller | Activity events verbatim (Trashed/Restored/Toggled) | `_13` |
| TC-P11 | BC-BIZ-02 | Controller | Create requires dropdown_need_id → redirect | `_14` |
| TC-P12 | BC-BIZ-05 | Controller | toggleStatus JSON contract | `_15` |
| TC-P13 | BC-INT-01 | Model | dropdownNeeds relationship wired | `_40` |
| TC-P14 | BC-REF-01 | Controller | destroy deactivates junction | `_41` |
| TC-P15 | BC-REF-01 | Controller | restore reactivates junction | `_42` |
| TC-P16 | BC-EDG-04 | Controller | Soft-delete lifecycle guarded + forceDelete order | `_43` |
| TC-P17 | BC-REF-02 | Model | Junction model table/fillable | `_44` |
| TC-P18 | BC-AUTH-01 | Provider | Gate abilities defined | `_52` |
| TC-P19 | BC-AUTH | Controller | Controller gate strings present | `_53` |
| TC-P20 | BC-BIZ-01 | Screen | Tabbed index exposes tabs | `_60` |
| TC-P21 | BC-UIX | Controller | List paginates 10/page | `_61` |
| TC-P22 | BC-UIX | Controller | List search filters present | `_62` |
| TC-P23 | BC-UIX | Controller | Empty-state stable | `_63` |
| TC-P24 | BC-AUTH-04 | routes | Index route registered at `/global-master/dropdown` | `_94` |

### Negative (`TC-N`)

| TC ID | BC | Source | Description | Method |
|-------|----|--------|-------------|--------|
| TC-N01 | BC-VAL-01 | Controller | key required | `_30` |
| TC-N02 | BC-VAL-01 | Controller | key max:160 | `_31` |
| TC-N03 | BC-VAL-01 | Controller | key unique(sys_dropdown_table) | `_32` |
| TC-N04 | BC-VAL-02 | Controller | value required | `_33` |
| TC-N05 | BC-VAL-02/06 | Controller/Request | value max:100 vs 255 divergence (DEV-GLB-D03) | `_34` |
| TC-N06 | BC-VAL-03 | Controller | type outside enum rejected | `_35` |
| TC-N07 | BC-BIZ-02 | Controller | store redirects when need absent | `_36` |
| TC-N08 | BC-VAL | Controller | whitespace value not trimmed (documented) | `_37` |
| TC-N09 | BC-INT | Controller | invalid id → findOrFail 404 | `_38` |
| TC-N10 | — | Controller | XSS value stored raw (output-escaped) | `_39` |
| TC-N11 | BC-AUTH-04 | Middleware | guest redirected to /login | `_50` |
| TC-N12 | BC-AUTH-04 | Middleware | guest POST store rejected | `_51` |

### Dependency / Security / Tenancy (`TC-D` / `TC-S` / `TC-T`)

| TC ID | BC | Source | Description | Method |
|-------|----|--------|-------------|--------|
| TC-T01 | BC-AUTH | Base | Central context, no tenant init | `_90` |
| TC-S01 | BC-DB-09 | Model | Mass-assignment guarded (org_id/dropdown_needs_id) | `_91` |
| TC-S02 | BC-INT | Controller | IDOR: non-existent id → findOrFail | `_92` |
| TC-S03 | — | Controller | Injection-shaped search parameter-bound | `_93` |

---

## 3. Test Method Index (40)

| # | Method | Band |
|---|--------|------|
| 1 | `_01_table_and_columns_match_ddl` | 01–09 |
| 2 | `_02_active_model_configuration_is_correct` | 01–09 |
| 3 | `_03_orphaned_duplicate_model_is_not_autoloaded` | 01–09 |
| 4 | `_04_globalmaster_request_value_rule_exceeds_db_length` | 01–09 |
| 5 | `_05_soft_delete_column_gap_is_guarded` | 01–09 |
| 6 | `_06_globalmaster_own_store_is_broken` | 01–09 |
| 7 | `_10_tabbed_index_screen_loads` | 10–19 |
| 8 | `_11_live_store_validation_rules_are_exact` | 10–19 |
| 9 | `_12_store_auto_increments_ordinal_and_creates_junction` | 10–19 |
| 10 | `_13_activity_log_events_are_verbatim` | 10–19 |
| 11 | `_14_create_requires_dropdown_need_id_redirect` | 10–19 |
| 12 | `_15_toggle_status_returns_json_contract` | 10–19 |
| 13 | `_30_store_requires_key` | 30–39 |
| 14 | `_31_store_enforces_key_max_160` | 30–39 |
| 15 | `_32_store_enforces_key_uniqueness` | 30–39 |
| 16 | `_33_store_requires_value` | 30–39 |
| 17 | `_34_value_max_length_diverges_between_paths` | 30–39 |
| 18 | `_35_store_rejects_type_outside_enum` | 30–39 |
| 19 | `_36_store_redirects_when_need_absent` | 30–39 |
| 20 | `_37_whitespace_value_is_not_trimmed_by_rules` | 30–39 |
| 21 | `_38_invalid_id_triggers_not_found` | 30–39 |
| 22 | `_39_xss_value_storage_contract` | 30–39 |
| 23 | `_40_dropdown_needs_relationship_wired` | 40–49 |
| 24 | `_41_destroy_deactivates_junction` | 40–49 |
| 25 | `_42_restore_reactivates_junction` | 40–49 |
| 26 | `_43_soft_delete_lifecycle_guarded` | 40–49 |
| 27 | `_44_junction_model_table` | 40–49 |
| 28 | `_50_guest_redirected_to_login` | 50–59 |
| 29 | `_51_guest_cannot_post_store` | 50–59 |
| 30 | `_52_gate_abilities_defined` | 50–59 |
| 31 | `_53_controller_gate_strings_present` | 50–59 |
| 32 | `_60_tabbed_index_exposes_tabs` | 60–69 |
| 33 | `_61_list_paginates_ten_per_page` | 60–69 |
| 34 | `_62_list_search_filters_present` | 60–69 |
| 35 | `_63_empty_state_is_stable` | 60–69 |
| 36 | `_90_runs_in_central_context_without_tenant` | 90–99 |
| 37 | `_91_mass_assignment_guarded` | 90–99 |
| 38 | `_92_idor_nonexistent_id_not_found` | 90–99 |
| 39 | `_93_search_uses_parameter_binding` | 90–99 |
| 40 | `_94_index_route_registered` | 90–99 |

---

## 4. Known Source Defects (DEV-GLB-###)

| DEV | Sev | Status | Description | Proving method |
|-----|-----|--------|-------------|----------------|
| DEV-GLB-D01 | P2 | Open | Orphaned duplicate model (`/Models/Dropdown.php` outside app/, not autoloaded) | `_03` |
| DEV-GLB-D02 | P1 | Open | GlobalMaster own `store()` reads org_id/key/type absent from its request rules | `_06` |
| DEV-GLB-D03 | P2 | Open | GlobalMaster request `value max:255` > DB `VARCHAR(100)` (live store max:100) | `_04`, `_34` |
| DEV-GLB-D04 | P1 | Open | SoftDeletes vs DDL with no `deleted_at` | `_05`, `_43` |
| Note | — | — | Route file wires the DEAD GlobalMaster controller; live path per digested truth is Prime | Gap §4 |
