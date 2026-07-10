# GlobalMaster :: Language — Test Case List & Requirements (`glb_`)

- Module: **GlobalMaster** (CENTRAL / prime-side)
- Screen: **Language**
- DB scope: CENTRAL, primary table **`glb_languages`** (DDL-verified `glb_` prefix), connection `global_master_mysql`
- Live host: **http://127.0.0.1:8000**
- Live path under test: **`/global-master/language`**
- Test file: `glb_Language_TestCas.php` (ONE comprehensive Dusk file — no V1/V2 split)

---

## HARD RULE 13 — Prime serves the central route (reconciliation)

| Aspect | Reality |
| --- | --- |
| Live route name | `central.global-master.language.*` |
| Live path | `/global-master/language` |
| Live controller | **`Modules\Prime\Http\Controllers\LanguageController`** (view `prime::language.index`, `paginate(11)`) |
| Registration site | app-root `routes/web.php` (imports Prime's `LanguageController` on line 10; `->prefix('global-master')->name('global-master.')` group nested inside `Route::domain(...)->name('central.')`) |
| Module's OWN controller | `Modules\GlobalMaster\Http\Controllers\LanguageController` — wired ONLY in `Modules/GlobalMaster/routes/web.php` under `global-master.language.*` (NO `central.` prefix) ⇒ **DEAD on central** |
| Shared request | `Modules\GlobalMaster\Http\Requests\LanguageRequest` (used by BOTH controllers) |
| Shared model | `Modules\Prime\Models\Language` → `glb_languages`, connection `global_master_mysql` |

**All tests target the LIVE Prime-served path `/global-master/language`.**

---

## Source-of-truth references

| Artifact | Path |
| --- | --- |
| Live controller | `Modules/Prime/app/Http/Controllers/LanguageController.php` |
| Dead duplicate controller | `Modules/GlobalMaster/app/Http/Controllers/LanguageController.php` |
| Shared request | `Modules/GlobalMaster/app/Http/Requests/LanguageRequest.php` |
| Model | `Modules/Prime/app/Models/Language.php` |
| Policy | `Modules/GlobalMaster/app/Policies/LanguagePolicy.php` |
| Migration | `Modules/GlobalMaster/database/migrations/2025_11_10_061519_create_languages_table.php` |
| Views | `Modules/Prime/resources/views/language/*.blade.php` (namespace `prime::language.*`) |
| Activity sink | `Modules/Prime/app/Models/ActivityLog.php` → `sys_central_activity_logs` (connection `mysql`) |
| DDL | `_global_db_v4.sql` — `glb_languages` block (~lines 196-204) |

---

## Field / rule contract (from `LanguageRequest`)

| Field | Rules | UI control |
| --- | --- | --- |
| `code` | required, string, max:10, unique(`glb_languages`,`code`) ignore-on-update | `input[name=code]` |
| `name` | required, string, max:50, unique(`glb_languages`,`name`) ignore-on-update | `input[name=name]` |
| `native_name` | nullable, string, max:50 | `input[name=native_name]` |
| `direction` | required, `Rule::in(['LTR','RTL'])` | `select[name=direction]` |
| `is_active` | required, boolean (`prepareForValidation` maps `'on'`→bool) | `#is_active` checkbox |

`authorize()` returns `true` (gating is done in the controller, not the request).

---

## Gates (LIVE Prime controller — asserted exact)

| Action | Gate |
| --- | --- |
| index | `prime.language.viewAny` |
| show | `prime.language.view` |
| create/store | `prime.language.create` |
| edit/update | `prime.language.update` |
| destroy | `prime.language.delete` |
| trashed/restore | `prime.language.restore` |
| forceDelete | `prime.language.forceDelete` |
| toggleStatus | `prime.language.update` |

---

## Activity events (VERBATIM from live Prime controller)

| Method | Logged event | Notes |
| --- | --- | --- |
| destroy | `Trashed` | soft delete + `is_active=false` |
| restore | `Restored` | |
| forceDelete | **`Stored`** | **DEV-GLB-L02 — SIC / wrong string** |
| toggleStatus | `Toggled` | |
| store / update | *(none)* | no activity written |

Sink: `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog`.

---

## Selectors (verified against `prime::language` views)

| Element | Selector |
| --- | --- |
| Edit link | `a.confirm-action[href$="/language/{id}/edit"]` |
| Delete button | `form.confirm-action-form[action$="/language/{id}"] button[type="submit"]` |
| Restore link | `a.confirm-action-restore[href$="/language/{id}/restore"]` |
| Force-delete button | `form.confirm-action-form-force-delete[action$="/language/{id}/force-delete"] button[type="submit"]` |
| Status switch | `#statusSwitch-{id}` |
| SweetAlert | `.swal2-popup` / `.swal2-confirm` |
| Create submit | `Add Language` |
| Update submit | `Update Language` |
| Validation errors | `.alert.alert-danger` |
| Pagination | `ul.pagination` |

---

## Test case list (40 automated methods)

### Band 01–09 — Schema / Model / Request truth
| TC | Method | Source |
| --- | --- | --- |
| TC-01 | `test_language_01_table_exists` | Migration/Model |
| TC-02 | `test_language_02_soft_deletes_column_exists` (`deleted_at`) | Migration (proves DEV-GLB-L01) |
| TC-03 | `test_language_03_timestamps_columns_exist` | Migration (proves DEV-GLB-L01) |
| TC-04 | `test_language_04_expected_columns_exist` | Migration/DDL |
| TC-05 | `test_language_05_code_column_is_varchar` | DDL/Migration |
| TC-06 | `test_language_06_direction_column_is_enum` (LTR/RTL) | Migration |
| TC-07 | `test_language_07_model_connection_and_table` | Model |
| TC-08 | `test_language_08_model_fillable_matches` | Model |
| TC-09 | `test_language_09_model_uses_soft_deletes` | Model |

### Band 10–19 — Business flows + activity truth
| TC | Method | Source |
| --- | --- | --- |
| TC-10 | `test_language_10_index_loads` | Controller/View |
| TC-11 | `test_language_11_create_page_loads` | View |
| TC-12 | `test_language_12_create_flow_persists` | Controller |
| TC-13 | `test_language_13_update_flow_persists` | Controller |
| TC-14 | `test_language_14_status_toggle_updates_is_active` | Controller |
| TC-15 | `test_language_15_soft_delete_logs_trashed_event` (issued_by) | Controller/ActivityLog |
| TC-16 | `test_language_16_restore_logs_restored_event` | Controller/ActivityLog |
| TC-17 | `test_language_17_force_delete_logs_stored_event_bug` | **DEV-GLB-L02** |
| TC-18 | `test_language_18_toggle_logs_toggled_event` | Controller/ActivityLog |
| TC-19 | `test_language_19_store_logs_nothing` | Controller |

### Band 30–39 — Validation / negative
| TC | Method | Source |
| --- | --- | --- |
| TC-30 | `test_language_30_create_requires_code` | Request |
| TC-31 | `test_language_31_create_requires_name` | Request |
| TC-32 | `test_language_32_create_requires_direction` | Request |
| TC-33 | `test_language_33_code_max_10_rejected` | Request |
| TC-34 | `test_language_34_name_max_50_rejected` | Request |
| TC-35 | `test_language_35_duplicate_code_rejected` | Request |
| TC-36 | `test_language_36_duplicate_name_rejected` | Request |
| TC-37 | `test_language_37_direction_not_in_enum_rejected` | Request |
| TC-38 | `test_language_38_native_name_nullable_persists_blank` | Request |
| TC-39 | `test_language_39_invalid_id_edit_returns_404` | Controller |

### Band 40–49 — Lifecycle
| TC | Method | Source |
| --- | --- | --- |
| TC-40 | `test_language_40_full_lifecycle_delete_restore_force` | Controller |
| TC-41 | `test_language_41_restore_recovers_record` | Controller |

### Band 50–59 — Permissions / access
| TC | Method | Source |
| --- | --- | --- |
| TC-50 | `test_language_50_guest_redirected_to_login` | Middleware |
| TC-51 | `test_language_51_index_requires_authentication_http` | Middleware |
| TC-52 | `test_language_52_gate_prefix_is_prime_language_on_live_route` | Controller (DEV-GLB-L03 context) |

### Band 60–69 — UI
| TC | Method | Source |
| --- | --- | --- |
| TC-60 | `test_language_60_pagination_eleven_per_page` (`paginate(11)`) | Controller/View |
| TC-61 | `test_language_61_trash_page_loads` | Controller/View |

### Band 90–99 — Security
| TC | Method | Source |
| --- | --- | --- |
| TC-90 | `test_language_90_xss_on_name_is_escaped` | View (Blade escaping) |
| TC-91 | `test_language_91_xss_on_native_name_is_escaped` | View (Blade escaping) |
| TC-92 | `test_language_92_idor_show_missing_returns_not_found` | Controller |
| TC-93 | `test_language_93_mass_assignment_guarded` | Model |

---

## GLB defects covered

| ID | Summary | Proving TC |
| --- | --- | --- |
| DEV-GLB-L01 | DDL omits `created_at/updated_at/deleted_at` while migration adds them (DDL divergence, not runtime) | TC-02, TC-03 |
| DEV-GLB-L02 | `forceDelete()` logs event `'Stored'` instead of a delete event | TC-17 |
| DEV-GLB-L03 | Dead duplicate controller mixes gate prefixes & `update()` uses literal `'update.language'` | TC-52 (documented) |
| DEV-GLB-L04 | Two `LanguageController` classes bound to one request + model | Documented (reconciliation) |
