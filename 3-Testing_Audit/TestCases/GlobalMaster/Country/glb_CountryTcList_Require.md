# Country (GlobalMaster / CENTRAL) — Test-Case & Business-Case List

- **Module**: GlobalMaster (prime-side / CENTRAL)
- **Feature / Screen**: Country
- **Primary table**: `glb_countries` (DDL-verified prefix = `glb_`)
- **Model**: `Modules\GlobalMaster\Models\Country` (connection `global_master_mysql`, SoftDeletes)
- **Controller**: `Modules\GlobalMaster\Http\Controllers\CountryController`
- **Request**: `Modules\GlobalMaster\Http\Requests\CountryRequest`
- **Policy**: `Modules\GlobalMaster\Policies\CountryPolicy`
- **Browser host**: `http://127.0.0.1:8000` (NOT test.localhost; no tenancy init)
- **Test class**: `glb_Country_TestCas` (single comprehensive file — no V1/V2)
- **Generated**: 2026-07-10

Every Business-Case (BC) and Test-Case (TC) carries a **Source** tag:
`SRC-CTRL` (controller), `SRC-REQ` (request), `SRC-MODEL` (model), `SRC-POLICY` (policy),
`SRC-MIG` (migration), `SRC-DDL` (`_global_db_v4.sql`), `SRC-VIEW` (blade), `SRC-ACTION` (action component).

---

## 1. Routes & endpoints (verified)

| Route name | Verb | Path | Gate | Source |
| --- | --- | --- | --- | --- |
| `central.global-master.country.index` | GET | `/global-master/country` | `prime.country.viewAny` | SRC-CTRL |
| `central.global-master.country.create` | GET | `/global-master/country/create` | `prime.country.create` | SRC-CTRL |
| `central.global-master.country.store` | POST | `/global-master/country` | `prime.country.create` | SRC-CTRL |
| `central.global-master.country.show` | GET | `/global-master/country/{country}` | `prime.country.view` | SRC-CTRL |
| `central.global-master.country.edit` | GET | `/global-master/country/{country}/edit` | `prime.country.update` | SRC-CTRL |
| `central.global-master.country.update` | PUT | `/global-master/country/{country}` | `prime.country.update` | SRC-CTRL |
| `central.global-master.country.destroy` | DELETE | `/global-master/country/{country}` | `prime.country.delete` | SRC-CTRL |
| `central.global-master.country.trashed` | GET | `/global-master/country/trash/view` | `prime.country.restore` | SRC-CTRL |
| `central.global-master.country.restore` | GET | `/global-master/country/{id}/restore` | `prime.country.restore` | SRC-CTRL |
| `central.global-master.country.forceDelete` | DELETE | `/global-master/country/{id}/force-delete` | `prime.country.forceDelete` | SRC-CTRL |
| `central.global-master.country.toggleStatus` | POST | `/global-master/country/{country}/toggle-status` | `prime.country.update` | SRC-CTRL |

Routes are mirrored under `central.prime.country.*` (`/prime/country`).
`store/update/destroy` redirect to `route('central.global-master.location-setup.index').'#country'`;
`restore/forceDelete` redirect to `central.global-master.country.trashed`. (SRC-CTRL)

## 2. Field / validation contract (SRC-REQ + SRC-DDL)

| Field | Request rule | DB column | DDL constraint |
| --- | --- | --- | --- |
| `name` | required, string, max:50, unique(glb_countries) ignore-on-update | varchar(50) NOT NULL | `uq_glb_countries_name` |
| `short_name` | required, string, max:10 | varchar(10) NOT NULL | `uq_glb_countries_shortName` |
| `global_code` | nullable, string, max:10 | varchar(10) NULL | `uq_glb_countries_globalCode` |
| `currency_code` | nullable, string, max:8 | varchar(8) NULL | — |
| `default_timezone` | nullable, string, max:64 | **absent** | — (DEV-GLB-C02 dead rule) |
| `is_active` | required, boolean (`'on'`→bool) | tinyint(1) NOT NULL DEFAULT 1 | — |

Activity-log events written via `activityLog()` → `sys_central_activity_logs` (SRC-CTRL):
store → **Stored**, update → **Updated**, destroy → **Trashed**, restore → **Restored**,
forceDelete → **Deleted**, toggleStatus → **Toggled**.

---

## 3. Business Cases (BC)

| BC ID | Business Case | Source |
| --- | --- | --- |
| BC-01 | An admin can view the list of countries (active-first, 10/page). | SRC-CTRL, SRC-VIEW |
| BC-02 | An admin can create a country; a `Stored` activity event is recorded. | SRC-CTRL, SRC-REQ |
| BC-03 | An admin can update a country; an `Updated` event with `performed_by` is recorded. | SRC-CTRL |
| BC-04 | An admin can soft-delete (trash) a country; it is deactivated + a `Trashed` event recorded. | SRC-CTRL, SRC-MODEL |
| BC-05 | An admin can restore a trashed country (`Restored` event); children are NOT resurrected. | SRC-CTRL |
| BC-06 | An admin can permanently force-delete a trashed country (`Deleted` event). | SRC-CTRL |
| BC-07 | An admin can toggle country status; status cascades to child states + districts (`Toggled`). | SRC-CTRL |
| BC-08 | Country name must be unique; duplicate names are rejected with a friendly error. | SRC-REQ, SRC-DDL |
| BC-09 | Field lengths are bounded (name 50 / short 10 / global 10 / currency 8). | SRC-REQ, SRC-DDL |
| BC-10 | Only permitted users may view/create/update/delete/restore/force-delete/toggle. | SRC-POLICY |
| BC-11 | Guests are redirected to `/login`; JSON endpoints reject unauthenticated callers. | SRC-CTRL |
| BC-12 | Stored/reflected user input is HTML-escaped; no XSS execution. | SRC-VIEW |
| BC-13 | Force-deleting a country that still has child states is blocked (FK RESTRICT). | SRC-DDL |
| BC-14 | Model exposes only intended fillable columns (mass-assignment guard). | SRC-MODEL |

---

## 4. Test-Case list (TC ↔ method)

### 4.1 Config / structural truth (band 01-09)
| TC ID | Title | Method | Source |
| --- | --- | --- | --- |
| TC-01 | `glb_countries` table/view exists | `test_country_01_glb_countries_table_exists` | SRC-DDL, SRC-MIG |
| TC-02 | Columns + int types match DDL | `test_country_02_columns_and_types_match_ddl` | SRC-DDL |
| TC-03 | `deleted_at` present (SoftDeletes) | `test_country_03_soft_delete_column_present` | SRC-MIG |
| TC-04 | Migration declares softDeletes + timestamps | `test_country_04_migration_declares_softdeletes_and_timestamps` | SRC-MIG |
| TC-05 | Migration declares unique keys + column sizes | `test_country_05_migration_declares_unique_keys` | SRC-MIG |
| TC-06 | Request rule strings are exact | `test_country_06_request_rule_strings_are_exact` | SRC-REQ |
| TC-07 | Request authorizes + normalizes checkbox | `test_country_07_request_authorizes_and_normalizes_checkbox` | SRC-REQ |
| TC-08 | Model table/fillable/SoftDeletes/connection | `test_country_08_model_table_fillable_and_softdeletes` | SRC-MODEL |
| TC-09 | `states()` HasMany + policy gate strings | `test_country_09_model_relationship_and_policy_gates` | SRC-MODEL, SRC-POLICY |

### 4.2 Business flows (band 10-17)
| TC ID | Title | Method | BC | Source |
| --- | --- | --- | --- | --- |
| TC-10 | Index loads | `test_country_10_index_loads` | BC-01 | SRC-CTRL |
| TC-11 | Create page loads | `test_country_11_create_page_loads` | BC-02 | SRC-VIEW |
| TC-12 | Create persists + logs `Stored` | `test_country_12_create_flow_persists_and_logs_stored` | BC-02 | SRC-CTRL |
| TC-13 | Update persists + logs `Updated` | `test_country_13_update_flow_persists_and_logs_updated` | BC-03 | SRC-CTRL |
| TC-14 | Show page loads | `test_country_14_show_page_loads` | BC-01 | SRC-VIEW |
| TC-15 | Edit page prefilled | `test_country_15_edit_page_prefilled` | BC-03 | SRC-VIEW |
| TC-16 | Toggle cascades to states + districts (DEV-GLB-C03) | `test_country_16_toggle_status_cascades_to_children` | BC-07 | SRC-CTRL |
| TC-17 | Activity log records payload/`performed_by` | `test_country_17_activity_log_records_performed_by` | BC-03 | SRC-CTRL |

### 4.3 Validation / negative (band 30-39)
| TC ID | Title | Method | BC | Source |
| --- | --- | --- | --- | --- |
| TC-30 | Required fields enforced | `test_country_30_create_requires_required_fields` | BC-09 | SRC-REQ |
| TC-31 | name max 50 | `test_country_31_name_max_length_enforced` | BC-09 | SRC-REQ |
| TC-32 | short_name max 10 | `test_country_32_short_name_max_length_enforced` | BC-09 | SRC-REQ |
| TC-33 | global_code max 10 | `test_country_33_global_code_max_length_enforced` | BC-09 | SRC-REQ |
| TC-34 | currency_code max 8 | `test_country_34_currency_code_max_length_enforced` | BC-09 | SRC-REQ |
| TC-35 | Duplicate name rejected | `test_country_35_duplicate_name_rejected` | BC-08 | SRC-REQ |
| TC-36 | Duplicate short_name → DB error (DEV-GLB-C01) | `test_country_36_duplicate_short_name_raises_db_error` | BC-08 | SRC-REQ, SRC-DDL |
| TC-37 | XSS name escaped, not executed | `test_country_37_xss_name_is_escaped_not_executed` | BC-12 | SRC-VIEW |
| TC-38 | Whitespace-only name rejected | `test_country_38_whitespace_only_name_rejected` | BC-09 | SRC-REQ |
| TC-39 | Invalid id on edit → 404 | `test_country_39_invalid_id_edit_returns_404` | BC-11 | SRC-CTRL |

### 4.4 FK / dependency / lifecycle (band 40-45)
| TC ID | Title | Method | BC | Source |
| --- | --- | --- | --- | --- |
| TC-40 | Soft-delete → restore → force-delete lifecycle | `test_country_40_soft_delete_restore_force_delete_lifecycle` | BC-04..06 | SRC-CTRL |
| TC-41 | Child states block force-delete (FK RESTRICT) | `test_country_41_states_fk_restrict_blocks_force_delete` | BC-13 | SRC-DDL |
| TC-42 | Restore does not recover children | `test_country_42_restore_does_not_recover_children` | BC-05 | SRC-CTRL |
| TC-43 | `default_timezone` dead rule (DEV-GLB-C02) | `test_country_43_default_timezone_is_a_dead_rule` | — | SRC-REQ, SRC-MODEL |
| TC-44 | Soft-delete sets deleted_at + deactivates | `test_country_44_soft_delete_sets_deleted_at_and_deactivates` | BC-04 | SRC-CTRL, SRC-MODEL |
| TC-45 | Force-delete removes the row | `test_country_45_force_delete_permanently_removes_row` | BC-06 | SRC-MODEL |

### 4.5 Permissions (band 50-52)
| TC ID | Title | Method | BC | Source |
| --- | --- | --- | --- | --- |
| TC-50 | Guest redirected to `/login` | `test_country_50_guest_redirected_to_login` | BC-11 | SRC-CTRL |
| TC-51 | Limited user → 403 on index | `test_country_51_limited_user_forbidden_403` | BC-10 | SRC-POLICY |
| TC-52 | Limited user → edit button hidden | `test_country_52_limited_user_action_buttons_hidden` | BC-10 | SRC-VIEW |

### 4.6 UI (band 60-63)
| TC ID | Title | Method | BC | Source |
| --- | --- | --- | --- | --- |
| TC-60 | Index paginates 10/page | `test_country_60_index_paginates_ten_per_page` | BC-01 | SRC-CTRL, SRC-VIEW |
| TC-61 | Index orders active-first | `test_country_61_index_orders_active_first` | BC-01 | SRC-CTRL |
| TC-62 | Trash page loads | `test_country_62_trash_page_loads` | BC-05 | SRC-VIEW |
| TC-63 | Index lists seeded country | `test_country_63_index_lists_seeded_country` | BC-01 | SRC-VIEW |

### 4.7 Security pack (band 90-95)
| TC ID | Title | Method | BC | Source |
| --- | --- | --- | --- | --- |
| TC-90 | Stored XSS escaped on show | `test_country_90_stored_xss_name_escaped_on_show` | BC-12 | SRC-VIEW |
| TC-91 | Reflected XSS (old()) escaped | `test_country_91_reflected_xss_short_name_escaped` | BC-12 | SRC-VIEW |
| TC-92 | IDOR cross-id → 404 | `test_country_92_idor_cross_id_returns_404` | BC-11 | SRC-CTRL |
| TC-93 | Mass-assignment guard | `test_country_93_mass_assignment_guard_blocks_non_fillable` | BC-14 | SRC-MODEL |
| TC-94 | Guest toggle JSON unauthorized | `test_country_94_guest_toggle_json_is_unauthorized` | BC-11 | SRC-CTRL |
| TC-95 | Limited user toggle JSON → 403 | `test_country_95_limited_user_toggle_json_forbidden` | BC-10 | SRC-POLICY |

**Total: 46 test methods across 7 semantic bands.**
