# glb_Country — Test Case List & Business Conditions

**Module:** GlobalMaster  **Feature/Screen:** Country  **Prefix:** `glb_` (DDL primary table `glb_countries`)
**DB scope:** CENTRAL / prime-side — `glb_countries` lives in `global_db` (model connection `global_master_mysql`); Prime holds a VIEW. **No tenant init.**
**Test style:** Browser Dusk, central pattern — `namespace Tests\Browser\Modules\Prime\GlobalMaster`, `extends PrimeDuskTestCase` (host `http://127.0.0.1:8000`).
**Primary sources:** `CountryController.php`, `CountryRequest.php`, `Country.php`, `routes/web.php` (name prefix `central.global-master.country.*`, URL prefix `/global-master`), `resources/views/country/*.blade.php`, DDL `_global_db_v4.sql`.

---

## 1. Business Conditions

### BC-DB — Schema (DDL `glb_countries`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK auto-increment | DDL-glb_countries |
| BC-DB-02 | `name` VARCHAR(50) NOT NULL, UNIQUE (`uq_glb_countries_name`) | DDL-glb_countries |
| BC-DB-03 | `short_name` VARCHAR(10) NOT NULL, UNIQUE (`uq_glb_countries_shortName`) | DDL-glb_countries |
| BC-DB-04 | `global_code` VARCHAR(10) NULL, UNIQUE (`uq_glb_countries_globalCode`) | DDL-glb_countries |
| BC-DB-05 | `currency_code` VARCHAR(8) NULL | DDL-glb_countries |
| BC-DB-06 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL-glb_countries |
| BC-DB-07 | `deleted_at` timestamp NULL → SoftDeletes | DDL-glb_countries |
| BC-DB-08 | **No `default_timezone` column** (validated in Request but absent) | DDL-glb_countries |

### BC-VAL — Validation (`CountryRequest`)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `name` required, string, max:50, unique(glb_countries) ignore self | CountryRequest-rules |
| BC-VAL-02 | `short_name` required, string, max:10 (NOT unique in rules — DDL is) | CountryRequest-rules |
| BC-VAL-03 | `global_code` nullable, string, max:10 (NOT unique in rules — DDL is) | CountryRequest-rules |
| BC-VAL-04 | `currency_code` nullable, string, max:8 | CountryRequest-rules |
| BC-VAL-05 | `default_timezone` nullable, string, max:64 — **validated but not fillable/column** | CountryRequest-rules |
| BC-VAL-06 | `is_active` required, boolean | CountryRequest-rules |
| BC-VAL-07 | `prepareForValidation` coerces checkbox `is_active` from `'on'` → true, else false | CountryRequest |
| BC-VAL-08 | `toggleStatus` inline-validates `is_active` required, boolean | Controller-toggleStatus |

### BC-AUTH — Permission gates (Controller `Gate::authorize`)
| ID | Method → Gate | Source |
|----|---------------|--------|
| BC-AUTH-01 | index → `prime.country.viewAny` | Controller-index |
| BC-AUTH-02 | create/store → `prime.country.create` | Controller-create/store |
| BC-AUTH-03 | show → `prime.country.view` | Controller-show |
| BC-AUTH-04 | edit/update/toggleStatus → `prime.country.update` | Controller-edit/update/toggleStatus |
| BC-AUTH-05 | destroy → `prime.country.delete` | Controller-destroy |
| BC-AUTH-06 | trashed/restore → `prime.country.restore` | Controller-restore |
| BC-AUTH-07 | forceDelete → `prime.country.forceDelete` | Controller-forceDelete |
| BC-AUTH-08 | Guest → redirect to `/login` | route middleware `auth` |

### BC-BIZ — Business logic / activity log (verbatim events → `sys_activity_logs`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store logs event **`Stored`** | Controller-store |
| BC-BIZ-02 | update logs event **`Updated`** with structured change set (and a no-change branch) | Controller-update |
| BC-BIZ-03 | destroy sets `is_active=false`, then soft-deletes; logs **`Trashed`** | Controller-destroy |
| BC-BIZ-04 | restore recovers record; logs **`Restored`** | Controller-restore |
| BC-BIZ-05 | forceDelete permanently removes; logs **`Deleted`** | Controller-forceDelete |
| BC-BIZ-06 | toggleStatus flips `is_active`, returns JSON `{success,is_active,message}`; logs **`Toggled`** | Controller-toggleStatus |
| BC-BIZ-07 | index orders `is_active desc`, paginates 10 | Controller-index |
| BC-BIZ-08 | store/update persist via `$request->validated()` (SEC-GLB-001: drops `default_timezone`) | Controller-store/update |

### BC-SM — Status lifecycle (single boolean flag; not a multi-state FSM)
| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | Active → toggleStatus(false) → Inactive (cascades to States, Districts) | Controller-toggleStatus |
| BC-SM-02 | Inactive → toggleStatus(true) → Active (cascades to States, Districts) | Controller-toggleStatus |
| BC-SM-03 | Active/Inactive → destroy → Trashed (soft-deleted + inactive) | Controller-destroy |
| BC-SM-04 | Trashed → restore → Active-recoverable | Controller-restore |
| BC-SM-05 | Trashed → forceDelete → Removed (blocked by FK RESTRICT if referenced) | Controller-forceDelete + DDL FK |

### BC-INT / BC-REF — Integration & referential integrity
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `glb_states.country_id` → `glb_countries.id` **ON DELETE RESTRICT** | DDL-glb_states |
| BC-INT-01 | toggleStatus cascades `is_active` to `glb_states` (where country_id) | Controller-toggleStatus |
| BC-INT-02 | toggleStatus cascades `is_active` to `glb_districts` (via state ids) | Controller-toggleStatus |
| BC-INT-03 | **toggleStatus does NOT cascade to `glb_cities`** — BUG-GLB-004 (BR-GLB-001 requires it) | Controller-toggleStatus vs FRD |
| BC-INT-04 | `Country::states()` HasMany, `organizationGroups()` HasMany | Country-model |

### BC-EDG — Edge/boundary
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `name` at exactly 50 chars accepted; 51 rejected | DDL + Request |
| BC-EDG-02 | `short_name` at exactly 10 chars accepted; 11 rejected | DDL + Request |
| BC-EDG-03 | Whitespace-only `name` rejected (required) | Request |
| BC-EDG-04 | Duplicate `short_name`/`global_code` not caught by Request (DDL unique only) | Cross-ref |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 | Status |
|-------|----------|----|--------|-------------|-----------------|----|----|--------|
| TC-P01 | Config | BC-DB-*, BC-VAL-* | DDL/Request | Schema/model/request config truth | Table, columns, fillable, SoftDeletes correct | 01 | 01,02 | Ready |
| TC-P02 | Render | BC-BIZ-07 | Controller | Index lists countries | Table renders, "Country Management" seen | 02 | 04 | Ready |
| TC-P03 | Render | BC-AUTH-02 | View | Create page renders all fields | name/short_name/global_code/currency_code present | 03 | 04 | Ready |
| TC-P04 | Render | BC-AUTH-04 | View | Edit page prefills values | Inputs equal stored values | — | 05 | Ready |
| TC-P05 | Create | BC-BIZ-01 | Controller | Store persists + logs Stored | Row saved, `Stored` log | 10 | 10 | Ready |
| TC-P06 | Update | BC-BIZ-02 | Controller | Update persists + logs Updated | Change saved, `Updated` log | 11 | 11,12 | Ready |
| TC-P07 | Delete | BC-BIZ-03 | Controller | Destroy deactivates+soft-deletes | `deleted_at` set, `is_active=0`, `Trashed` log | 12 | 13 | Ready |
| TC-P08 | Restore | BC-BIZ-04 | Controller | Restore recovers + logs Restored | `deleted_at` null, `Restored` log | 13 | 14 | Ready |
| TC-P09 | ForceDelete | BC-BIZ-05 | Controller | Force delete removes + logs Deleted | Row gone | 14 | 15 | Ready |
| TC-P10 | Toggle | BC-BIZ-06/SM-01 | Controller | Toggle updates is_active JSON | `{success:true,is_active}`, `Toggled` log | 15 | 16 | Ready |
| TC-P11 | UI | BC-BIZ-07 | Controller | Index paginates 10, orders is_active desc | `paginate(10)` + `orderBy` | — | 60,63 | Ready |
| TC-P12 | UI | BC-EDG | View | Status switch present on rows | `input.status-toggle` present | — | 64 | Ready |

### Negative (TC-N) — target 100%
| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 | Status |
|-------|----------|----|--------|-------------|-----------------|----|----|--------|
| TC-N01 | Validation | BC-VAL-01 | Request | name required | error on `name` | 30 | 30 | Ready |
| TC-N02 | Validation | BC-VAL-01 | Request | name > 50 chars | error on `name` | — | 31 | Ready |
| TC-N03 | Validation | BC-VAL-01 | Request | duplicate name | error on `name` | 31 | 32 | Ready |
| TC-N04 | Validation | BC-VAL-01 | Request | update same name on self allowed | no errors | — | 33 | Ready |
| TC-N05 | Validation | BC-VAL-02 | Request | short_name required | error on `short_name` | — | 34 | Ready |
| TC-N06 | Validation | BC-VAL-02 | Request | short_name > 10 | error on `short_name` | 32 | 35 | Ready |
| TC-N07 | Validation | BC-VAL-03 | Request | global_code > 10 | error on `global_code` | — | 36 | Ready |
| TC-N08 | Validation | BC-VAL-04 | Request | currency_code > 8 | error on `currency_code` | — | 37 | Ready |
| TC-N09 | Validation | BC-VAL-03/04 | Request | null global/currency codes accepted | no errors | — | 38 | Ready |
| TC-N10 | Validation | BC-VAL-08 | Controller | toggle non-boolean is_active | 422 | — | 39 | Ready |
| TC-N11 | Edge | BC-EDG-03 | Request | whitespace-only name | error on `name` | — | 72 | Ready |
| TC-N12 | Security | BC-AUTH-08 | middleware | guest index redirect /login | 302 → /login | 50 | 50 | Ready |
| TC-N13 | Security | BC-AUTH-08 | middleware | guest store redirect /login | 302 → /login | — | 51 | Ready |
| TC-N14 | Security | BC-AUTH-01 | Gate | unauthorized index 403 | 403 | — | 52 | Ready |
| TC-N15 | Security | BC-AUTH-02 | Gate | unauthorized create 403 | 403 | — | 53 | Ready |
| TC-N16 | Security | BC-AUTH-02 | Gate | unauthorized store 403 | 403 | — | 54 | Ready |
| TC-N17 | Security | BC-AUTH-04 | Gate | unauthorized toggle 403 | 403 | — | 55 | Ready |
| TC-N18 | Security | BC-AUTH-07 | Gate | unauthorized forceDelete 403 | 403 | — | 56 | Ready |
| TC-N19 | Security | BC-AUTH-04 | binding | edit invalid id 404 | 404 | — | 93 | Ready |
| TC-N20 | Security | BC-AUTH-03 | binding | show invalid id 404 | 404 | — | 94 | Ready |
| TC-N21 | Security | BC-AUTH-07 | binding | forceDelete invalid id 404 | 404 | — | 95 | Ready |
| TC-N22 | Security | BC-AUTH-08 | middleware | guest toggle rejected | 401/302/419 | — | 96 | Ready |
| TC-N23 | Security | BC-VAL-01 | XSS | XSS in name escaped | no raw `<script>` in DOM | — | 91 | Ready |
| TC-N24 | Security | BC-VAL-02 | XSS | XSS in short_name escaped | escaped output | — | 92 | Ready |
| TC-N25 | Security | BC-BIZ-08 | mass-assign | non-fillable (id/deleted_at) ignored | not persisted | — | 18 | Ready |

### Dependency (TC-D) — sub-cat A–G
| TC ID | Sub | BC | Source | Description | Expected Result | V1 | V2 | Status |
|-------|-----|----|--------|-------------|-----------------|----|----|--------|
| TC-D01 | B | BC-SM-03/04 | Controller | soft-delete then restore round-trip | recovered | 13 | 14 | Ready |
| TC-D02 | B | BC-INT-04 | Controller | soft-delete parent does not soft-delete child states | child intact | — | 44 | Ready |
| TC-D03 | C | BC-REF-01 | DDL FK | force-delete blocked while state references country | blocked (RESTRICT) | — | 43 | Ready |
| TC-D04 | E | BC-INT-01/SM-01 | Controller | toggle cascades to states | state inactive | 40 | 40 | Ready |
| TC-D05 | E | BC-INT-02 | Controller | toggle cascades to districts | district inactive | — | 41 | Ready |
| TC-D06 | E | BC-INT-03 | Controller | **toggle does NOT cascade to cities (BUG-GLB-004)** | city stays active (proving) | — | 42 | Ready |
| TC-D07 | E | BC-INT-04 | Model | states() returns related records | relation works | — | 45 | Ready |
| TC-D08 | G | BC-EDG-01 | DDL | name at 50 boundary | accepted | — | 70 | Ready |
| TC-D09 | G | BC-EDG-02 | DDL | short_name at 10 boundary | accepted | — | 71 | Ready |

### Security / Cross-ref (TC-S)
| TC ID | BC | Source | Description | Expected Result | V2 | Status |
|-------|----|--------|-------------|-----------------|----|--------|
| TC-S01 | BC-VAL-05/BC-DB-08 | Cross-ref | **SEC-GLB-001** default_timezone validated but dropped | column absent, store succeeds | 17 | Ready |
| TC-S02 | BC-EDG-04 | Cross-ref | short_name unique in DDL not in rules | no unique rule (proving) | 73 | Ready |
| TC-S03 | BC-EDG-04 | Cross-ref | global_code unique in DDL not in rules | no unique rule (proving) | 74 | Ready |
| TC-S04 | Central scope | Tenancy | cross-tenant isolation N/A (central) | deliberate skip | 90 | Skipped (documented) |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_country_01_schema_model_and_request_configuration_are_correct | TC-P01 | Config | 01–09 |
| 2 | test_country_02_ddl_declares_unique_indexes_on_name_shortname_globalcode | TC-P01/BC-DB | Config | 01–09 |
| 3 | test_country_03_index_route_is_registered_under_global_master_prefix | BC-AUTH | Config | 01–09 |
| 4 | test_country_04_create_page_renders_all_input_fields | TC-P03 | Render | 01–09 |
| 5 | test_country_05_edit_page_prefills_existing_values | TC-P04 | Render | 01–09 |
| 6 | test_country_10_store_persists_and_logs_stored | TC-P05 | Business | 10–19 |
| 7 | test_country_11_update_logs_updated_with_change_set | TC-P06 | Business | 10–19 |
| 8 | test_country_12_update_with_no_changes_still_logs_updated | TC-P06 | Business | 10–19 |
| 9 | test_country_13_destroy_sets_inactive_then_soft_deletes_and_logs_trashed | TC-P07 | Business | 10–19 |
| 10 | test_country_14_restore_recovers_and_logs_restored | TC-P08/TC-D01 | Business | 10–19 |
| 11 | test_country_15_force_delete_removes_and_logs_deleted | TC-P09 | Business | 10–19 |
| 12 | test_country_16_toggle_status_returns_json_and_logs_toggled | TC-P10 | Business | 10–19 |
| 13 | test_country_17_mass_assignment_drops_default_timezone_SEC_GLB_001 | TC-S01 | Security/BIZ | 10–19 |
| 14 | test_country_18_store_ignores_non_fillable_attributes | TC-N25 | Security | 10–19 |
| 15 | test_country_30_store_requires_name | TC-N01 | Validation | 30–39 |
| 16 | test_country_31_store_enforces_name_max_50 | TC-N02 | Validation | 30–39 |
| 17 | test_country_32_store_rejects_duplicate_name | TC-N03 | Validation | 30–39 |
| 18 | test_country_33_update_allows_same_name_on_self | TC-N04 | Validation | 30–39 |
| 19 | test_country_34_store_requires_short_name | TC-N05 | Validation | 30–39 |
| 20 | test_country_35_store_enforces_short_name_max_10 | TC-N06 | Validation | 30–39 |
| 21 | test_country_36_store_enforces_global_code_max_10 | TC-N07 | Validation | 30–39 |
| 22 | test_country_37_store_enforces_currency_code_max_8 | TC-N08 | Validation | 30–39 |
| 23 | test_country_38_store_accepts_nullable_global_and_currency_codes | TC-N09 | Validation | 30–39 |
| 24 | test_country_39_toggle_status_rejects_non_boolean_is_active | TC-N10 | Validation | 30–39 |
| 25 | test_country_40_toggle_cascades_is_active_to_states | TC-D04 | Integration | 40–49 |
| 26 | test_country_41_toggle_cascades_is_active_to_districts | TC-D05 | Integration | 40–49 |
| 27 | test_country_42_toggle_does_not_cascade_to_cities_BUG_GLB_004 | TC-D06 | Integration | 40–49 |
| 28 | test_country_43_force_delete_is_blocked_while_state_references_country | TC-D03 | Integration/FK | 40–49 |
| 29 | test_country_44_soft_delete_does_not_soft_delete_child_states | TC-D02 | Integration | 40–49 |
| 30 | test_country_45_states_relation_returns_related_records | TC-D07 | Integration | 40–49 |
| 31 | test_country_50_guest_index_redirects_to_login | TC-N12 | Permissions | 50–59 |
| 32 | test_country_51_guest_store_redirects_to_login | TC-N13 | Permissions | 50–59 |
| 33 | test_country_52_unauthorized_user_cannot_view_index | TC-N14 | Permissions | 50–59 |
| 34 | test_country_53_unauthorized_user_cannot_open_create | TC-N15 | Permissions | 50–59 |
| 35 | test_country_54_unauthorized_user_cannot_store | TC-N16 | Permissions | 50–59 |
| 36 | test_country_55_unauthorized_user_cannot_toggle_status | TC-N17 | Permissions | 50–59 |
| 37 | test_country_56_unauthorized_user_cannot_force_delete | TC-N18 | Permissions | 50–59 |
| 38 | test_country_60_index_paginates_ten_per_page | TC-P11 | UI/UX | 60–69 |
| 39 | test_country_61_index_shows_empty_state_marker_when_no_data | TC-P11 | UI/UX | 60–69 |
| 40 | test_country_62_create_page_shows_breadcrumb | TC-P03 | UI/UX | 60–69 |
| 41 | test_country_63_index_orders_active_countries_first | TC-P11 | UI/UX | 60–69 |
| 42 | test_country_64_status_toggle_switch_present_on_index_rows | TC-P12 | UI/UX | 60–69 |
| 43 | test_country_70_name_at_exactly_50_chars_is_accepted | TC-D08 | Edge | 70–79 |
| 44 | test_country_71_short_name_at_exactly_10_chars_is_accepted | TC-D09 | Edge | 70–79 |
| 45 | test_country_72_whitespace_only_name_is_rejected | TC-N11 | Edge | 70–79 |
| 46 | test_country_73_duplicate_short_name_not_guarded_by_request_crossref | TC-S02 | Edge/Cross-ref | 70–79 |
| 47 | test_country_74_global_code_uniqueness_not_guarded_by_request_crossref | TC-S03 | Edge/Cross-ref | 70–79 |
| 48 | test_country_90_cross_tenant_isolation_is_not_applicable_central_scope | TC-S04 | Tenancy | 90–99 |
| 49 | test_country_91_stored_xss_in_name_is_escaped_on_render | TC-N23 | Security | 90–99 |
| 50 | test_country_92_reflected_xss_in_short_name_is_escaped | TC-N24 | Security | 90–99 |
| 51 | test_country_93_edit_invalid_id_returns_404 | TC-N19 | Security | 90–99 |
| 52 | test_country_94_show_invalid_id_returns_404 | TC-N20 | Security | 90–99 |
| 53 | test_country_95_force_delete_invalid_id_returns_404 | TC-N21 | Security | 90–99 |
| 54 | test_country_96_guest_toggle_status_is_rejected | TC-N22 | Security | 90–99 |

**Counts:** V1 = 16 methods, V2 = 54 methods (V2 ≥ 2×V1 = 32 ✅).

---

## 4. Known Source Defects (audit-equivalent)

| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| SEC-GLB-001 | P1 | store/update persist `$request->validated()`, but the Request validates `default_timezone`, a column that does not exist → silently dropped (mass-assignment on the whole validated set). | test_country_17 (+ test_country_18) |
| BUG-GLB-004 | P1 | `toggleStatus` cascades `is_active` to States + Districts but OMITS Cities; BR-GLB-001 requires cities too. | test_country_42 (proves current buggy behaviour) |
| CR-GLB-01 | P3 | `short_name` is UNIQUE in DDL but has no `unique` rule in the Request. | test_country_73 |
| CR-GLB-02 | P3 | `global_code` is UNIQUE in DDL but has no `unique` rule in the Request. | test_country_74 |
| CR-GLB-03 | P3 | `Country` model omits `is_active` boolean cast that State/District/City all declare (minor inconsistency). | noted in Gap Analysis |
