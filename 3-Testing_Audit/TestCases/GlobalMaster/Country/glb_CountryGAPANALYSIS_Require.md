# Country (GlobalMaster / CENTRAL) — Gap Analysis

- **Feature**: Country — GlobalMaster module (prime-side / CENTRAL)
- **Test class**: `glb_Country_TestCas` (single file, 46 methods, no V1/V2)
- **DDL-verified table prefix**: `glb_`
- **Generated**: 2026-07-10

Source tags: `SRC-CTRL`, `SRC-REQ`, `SRC-MODEL`, `SRC-POLICY`, `SRC-MIG`, `SRC-DDL`, `SRC-VIEW`, `SRC-ACTION`.

---

## 1. Per-category TC ↔ method mapping

### 1.1 Config / structural (band 01-09) — Source: SRC-MIG, SRC-DDL, SRC-REQ, SRC-MODEL, SRC-POLICY
| TC | Method | Asserts |
| --- | --- | --- |
| TC-01 | `test_country_01_glb_countries_table_exists` | `Schema::hasTable('glb_countries')` |
| TC-02 | `test_country_02_columns_and_types_match_ddl` | 9 columns present; `id`/`is_active` contain `int` |
| TC-03 | `test_country_03_soft_delete_column_present` | `deleted_at` column |
| TC-04 | `test_country_04_migration_declares_softdeletes_and_timestamps` | file contains `softDeletes`, `timestamps`, `global_master_mysql` |
| TC-05 | `test_country_05_migration_declares_unique_keys` | file contains `->unique()`, `name,50`, `short_name,10` |
| TC-06 | `test_country_06_request_rule_strings_are_exact` | `Rule::unique('glb_countries')`, `ignore($countryId)`, `max:50/10/8/64`, `required\|boolean` |
| TC-07 | `test_country_07_request_authorizes_and_normalizes_checkbox` | `return true`, `prepareForValidation`, `=== 'on'` |
| TC-08 | `test_country_08_model_table_fillable_and_softdeletes` | `getTable`, connection, fillable list, SoftDeletes trait |
| TC-09 | `test_country_09_model_relationship_and_policy_gates` | `states()` HasMany; 7 gate strings in policy |

### 1.2 Business (band 10-17) — Source: SRC-CTRL, SRC-VIEW
| TC | Method | Asserts |
| --- | --- | --- |
| TC-10 | `test_country_10_index_loads` | index reachable, sees "Countries", table present |
| TC-11 | `test_country_11_create_page_loads` | 4 inputs present |
| TC-12 | `test_country_12_create_flow_persists_and_logs_stored` | row created, `Stored` logged |
| TC-13 | `test_country_13_update_flow_persists_and_logs_updated` | name updated, `Updated` logged |
| TC-14 | `test_country_14_show_page_loads` | "Country Details" + name |
| TC-15 | `test_country_15_edit_page_prefilled` | inputs prefilled |
| TC-16 | `test_country_16_toggle_status_cascades_to_children` | JSON success; state+district cascade; `Toggled` logged (DEV-GLB-C03) |
| TC-17 | `test_country_17_activity_log_records_performed_by` | activity row + properties payload |

### 1.3 Validation / negative (band 30-39) — Source: SRC-REQ, SRC-DDL, SRC-VIEW
| TC | Method | Asserts |
| --- | --- | --- |
| TC-30 | `test_country_30_create_requires_required_fields` | stays on create, `.alert-danger li` |
| TC-31..34 | name/short/global/currency max-length methods | stays on create, `.alert-danger` |
| TC-35 | `test_country_35_duplicate_name_rejected` | friendly error, single row |
| TC-36 | `test_country_36_duplicate_short_name_raises_db_error` | `QueryException` thrown (DEV-GLB-C01) |
| TC-37 | `test_country_37_xss_name_is_escaped_not_executed` | payload not in raw page source |
| TC-38 | `test_country_38_whitespace_only_name_rejected` | stays on create |
| TC-39 | `test_country_39_invalid_id_edit_returns_404` | `assertNotFound()` |

### 1.4 FK / dependency / lifecycle (band 40-45) — Source: SRC-CTRL, SRC-MODEL, SRC-DDL
| TC | Method | Asserts |
| --- | --- | --- |
| TC-40 | `test_country_40_soft_delete_restore_force_delete_lifecycle` | full trash → restore → force lifecycle |
| TC-41 | `test_country_41_states_fk_restrict_blocks_force_delete` | force-delete blocked by FK |
| TC-42 | `test_country_42_restore_does_not_recover_children` | child `deleted_at` still set |
| TC-43 | `test_country_43_default_timezone_is_a_dead_rule` | no column + not fillable (DEV-GLB-C02) |
| TC-44 | `test_country_44_soft_delete_sets_deleted_at_and_deactivates` | `deleted_at` set, inactive, excluded from scope |
| TC-45 | `test_country_45_force_delete_permanently_removes_row` | row gone |

### 1.5 Permissions (band 50-52) — Source: SRC-POLICY, SRC-VIEW
| TC | Method | Asserts |
| --- | --- | --- |
| TC-50 | `test_country_50_guest_redirected_to_login` | path contains `/login` |
| TC-51 | `test_country_51_limited_user_forbidden_403` | `assertForbidden()` |
| TC-52 | `test_country_52_limited_user_action_buttons_hidden` | edit link `assertMissing` |

### 1.6 UI (band 60-63) — Source: SRC-CTRL, SRC-VIEW
| TC | Method | Asserts |
| --- | --- | --- |
| TC-60 | `test_country_60_index_paginates_ten_per_page` | ≤ 11 tbody rows |
| TC-61 | `test_country_61_index_orders_active_first` | SQL `order by is_active` |
| TC-62 | `test_country_62_trash_page_loads` | trash table present |
| TC-63 | `test_country_63_index_lists_seeded_country` | sees short_name |

### 1.7 Security (band 90-95) — Source: SRC-VIEW, SRC-MODEL, SRC-CTRL, SRC-POLICY
| TC | Method | Asserts |
| --- | --- | --- |
| TC-90 | `test_country_90_stored_xss_name_escaped_on_show` | payload not in raw source |
| TC-91 | `test_country_91_reflected_xss_short_name_escaped` | `<script>` not in raw source |
| TC-92 | `test_country_92_idor_cross_id_returns_404` | `assertNotFound()` |
| TC-93 | `test_country_93_mass_assignment_guard_blocks_non_fillable` | `default_timezone`/`id` not set |
| TC-94 | `test_country_94_guest_toggle_json_is_unauthorized` | status ∈ {401,302,419} |
| TC-95 | `test_country_95_limited_user_toggle_json_forbidden` | `assertForbidden()` |

---

## 2. Coverage Summary

| Category | Requirement | Covered | Coverage |
| --- | --- | --- | --- |
| Negative (validation/errors) | 100% | 11/11 (TC-30..39, TC-36) | **100%** |
| Positive (happy paths) | ≥ 90% | 17/18 flows | **94%** |
| Dependency (FK / cascade / lifecycle) | ≥ 90% | 6/6 (TC-40..45) + TC-16 cascade | **100%** |
| Permissions / Auth | — | 5/5 (TC-50,51,52,94,95) | **100%** |
| Security (XSS/IDOR/mass-assign) | — | 6/6 (TC-90..95) | **100%** |
| Config / structural truth | — | 9/9 (TC-01..09) | **100%** |

Positive coverage note: the only intentionally-not-automated positive path is the mirrored
`/prime/country` alias (identical controller); documented, not duplicated.

---

## 3. Cross-Reference Findings (11-check)

| # | Check | Source | Result | Evidence (method) |
| --- | --- | --- | --- | --- |
| 1 | Table name & prefix (`glb_countries`) | SRC-DDL, SRC-MIG | PASS | TC-01, TC-08 |
| 2 | Column set matches DDL | SRC-DDL | PASS | TC-02 |
| 3 | SoftDeletes column + trait | SRC-MIG, SRC-MODEL | PASS | TC-03, TC-08 |
| 4 | Request rules vs DB constraints | SRC-REQ, SRC-DDL | **GAP — DEV-GLB-C01** | TC-06, TC-36 |
| 5 | Dead validation rule (`default_timezone`) | SRC-REQ, SRC-MODEL | **GAP — DEV-GLB-C02** | TC-43 |
| 6 | Fillable vs mass-assignment | SRC-MODEL | PASS | TC-08, TC-93 |
| 7 | Activity events verbatim (Stored/Updated/Trashed/Restored/Deleted/Toggled) | SRC-CTRL | PASS | TC-12, TC-13, TC-16, TC-17 |
| 8 | Cascade logging completeness | SRC-CTRL | **GAP — DEV-GLB-C03** | TC-16 |
| 9 | Policy gates vs controller gates | SRC-POLICY, SRC-CTRL | PASS | TC-09, TC-51, TC-95 |
| 10 | FK RESTRICT enforcement | SRC-DDL | PASS | TC-41 |
| 11 | Output escaping (XSS) | SRC-VIEW | PASS | TC-37, TC-90, TC-91 |

---

## 4. Source-tagged Coverage-Score table

| Source artifact | Elements | Covered by | Score |
| --- | --- | --- | --- |
| SRC-CTRL (CountryController) | index/create/store/show/edit/update/destroy/trashed/restore/forceDelete/toggleStatus (11) | TC-10..17, 39, 40..45, 50, 92, 94, 95 | 11/11 = **100%** |
| SRC-REQ (CountryRequest) | 6 field rules + authorize + prepareForValidation | TC-06,07,30..38,43 | 8/8 = **100%** (2 defects flagged) |
| SRC-MODEL (Country) | table, connection, fillable, SoftDeletes, states() | TC-08,09,42,44,45,93 | 5/5 = **100%** |
| SRC-POLICY (CountryPolicy) | 7 abilities | TC-09,51,52,95 | 7/7 = **100%** |
| SRC-MIG (migration) | create, softDeletes, timestamps, unique, connection | TC-01,03,04,05 | 5/5 = **100%** |
| SRC-DDL (`_global_db_v4.sql`) | columns, 3 unique keys, FK RESTRICT | TC-02,05,36,41 | 4/4 = **100%** |
| SRC-VIEW (index/create/edit/show/trash) | list, form, prefill, detail, trash, escaping | TC-10,11,14,15,37,52,62,63,90,91 | 5/5 = **100%** |
| SRC-ACTION (action component) | edit/delete/restore/force selectors | TC-13,40,52 | 3/3 = **100%** |

**Weighted coverage score: 100% structural, ≥ 94% positive, 100% negative & dependency.**

---

## 5. Documented defects (DEV-GLB-###) — verify in source

| ID | Sev | Location | Description | Proving test |
| --- | --- | --- | --- | --- |
| DEV-GLB-C01 | High | `CountryRequest::rules()` vs `glb_countries` UNIQUE keys | `short_name`/`global_code` uniqueness not validated; duplicate → raw `QueryException` (500) not a friendly error. | TC-36 |
| DEV-GLB-C02 | Minor | `CountryRequest` `default_timezone` rule | Rule validates a column that does not exist and is not fillable → silently ignored (dead rule). | TC-43 |
| DEV-GLB-C03 | Medium | `CountryController::toggleStatus()` | `is_active` cascades to child states/districts inside a transaction, but only the country gets a `Toggled` activity entry — child changes unlogged. | TC-16 |

---

## 6. Environment gaps (prerequisites, NOT code fixes)

| Gap | Impact | Action |
| --- | --- | --- |
| `GlobalMaster` + `Prime` both `false` in `modules_statuses.json` | All `/global-master/country` routes 404 | Enable both before running |
| `APP_ENV` not `testing` | toggle-status AJAX blocked by CSRF | Export `APP_ENV=testing` (runners do this) |
| Wrong host (`test.localhost`) | Suite fails fast in `setUp()` | Serve on `http://127.0.0.1:8000` |
