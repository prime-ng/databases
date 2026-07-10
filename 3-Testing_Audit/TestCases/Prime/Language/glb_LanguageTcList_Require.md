# Language (PRM / GlobalMaster) — Test Case List & Business Conditions

- **Module:** Prime (PRM) — CENTRAL DB scope (no tenant init). Host `http://127.0.0.1:8000`.
- **Feature / Screen:** Language (`central.global-master.language.*`, path `/global-master/language`).
- **Primary table:** `glb_languages` (prefix **`glb_`** — flagged: registry PREFIX for the Prime module is `prm_`; the feature's primary table prefix is `glb_`, and the file prefix follows the DDL table prefix rule → `glb_`).
- **Controller:** `Modules\Prime\Http\Controllers\LanguageController`.
- **Model:** `Modules\Prime\Models\Language` — `$connection='global_master_mysql'`, `$table='glb_languages'`, `SoftDeletes`, fillable `[code,name,native_name,direction,is_active]`.
- **FormRequest:** `Modules\GlobalMaster\Http\Requests\LanguageRequest`.
- **Policy:** `Modules\GlobalMaster\Policies\LanguagePolicy` (exists but not wired to the string gates; the controller uses `Gate::authorize('prime.language.*')` which resolve via Spatie permissions + super-admin `Gate::before`).
- **Activity sink:** central `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (constraint #25).
- **CRUD type:** page-based (create/edit/show/trash blades — NOT modal). Pagination 11/page (trash 10/page). Green toast + SweetAlert conventions.

> **VIEW note (constraint #10):** in `prime_db`, `glb_languages` is a VIEW (`CREATE VIEW glb_languages AS SELECT * FROM global_master.glb_languages`). The **model bypasses the view** by using the `global_master_mysql` connection, so **writes DO succeed against the base table** — the screen is fully writable. The consolidated DDL `_global_db_v4.sql` is stale (omits `deleted_at`/timestamps/`name` unique); the real migration `2025_11_10_061519_create_languages_table.php` adds them. Languages are GLOBAL (shared across all tenants; referenced by `sys_users.prefered_language`).

---

## 1. Business Conditions

### BC-DB (schema — DDL/migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `glb_languages.id` INT UNSIGNED PK auto-increment | DDL-glb_languages |
| BC-DB-02 | `code` VARCHAR(10) NOT NULL, UNIQUE | DDL-glb_languages / Migration |
| BC-DB-03 | `name` VARCHAR(50) NOT NULL, UNIQUE (migration adds unique; DDL omits it) | Migration |
| BC-DB-04 | `native_name` VARCHAR(50) NULLABLE | DDL-glb_languages |
| BC-DB-05 | `direction` ENUM('LTR','RTL') DEFAULT 'LTR' | DDL-glb_languages |
| BC-DB-06 | `is_active` TINYINT(1) DEFAULT 1 | DDL-glb_languages |
| BC-DB-07 | `deleted_at`,`created_at`,`updated_at` present via migration (NOT in consolidated DDL) | Migration |
| BC-DB-08 | Base table lives in `global_master`; `prime_db.glb_languages` is a VIEW mirror | Migration / _prime_db_v4.sql:54 |

### BC-VAL (validation — LanguageRequest)
| ID | Rule | Message/Behaviour | Source |
|----|------|-------------------|--------|
| BC-VAL-01 | `code` required, string, max:10, unique(ignore self) | Laravel default messages | Screen-VR-1 / Request |
| BC-VAL-02 | `name` required, string, max:50, unique(ignore self) | Laravel default messages | Screen-VR-2 / Request |
| BC-VAL-03 | `native_name` nullable, string, max:50 | — | Request |
| BC-VAL-04 | `direction` required, in:['LTR','RTL'] (case-sensitive) | Laravel default | Request |
| BC-VAL-05 | `is_active` required boolean; `prepareForValidation` maps checkbox 'on'/null→true/false | — | Request |

### BC-AUTH (permission gates — controller)
| ID | Gate | Method(s) | Source |
|----|------|-----------|--------|
| BC-AUTH-01 | `prime.language.viewAny` | index | Screen-PM-1 / Controller |
| BC-AUTH-02 | `prime.language.create` | create, store | Controller |
| BC-AUTH-03 | `prime.language.view` | show | Controller |
| BC-AUTH-04 | `prime.language.update` | edit, update, toggleStatus | Controller |
| BC-AUTH-05 | `prime.language.delete` | destroy | Controller |
| BC-AUTH-06 | `prime.language.restore` | trashedLanguage, restore | Controller |
| BC-AUTH-07 | `prime.language.forceDelete` | forceDelete | Controller |
| BC-AUTH-08 | Super-admin `Gate::before` (is_super_admin && super_admin_flag) bypasses all | AppServiceProvider:64 |

### BC-BIZ (business logic / activity events)
| ID | Rule | Source |
|----|------|--------|
| BC-BIZ-01 | `store()` creates a language via validated data; redirects to index with `flash('created.language')` | Controller |
| BC-BIZ-02 | `destroy()` sets `is_active=false`, soft-deletes, logs event **`Trashed`** | Controller |
| BC-BIZ-03 | `restore()` clears `deleted_at`, logs **`Restored`** (does NOT reset `is_active`) | Controller |
| BC-BIZ-04 | `forceDelete()` permanently removes, logs event **`Stored`** (mislabeled — DEV-LANG-003) | Controller |
| BC-BIZ-05 | `toggleStatus()` sets `is_active` from request, logs **`Toggled`**, returns JSON `{success,is_active,message}` | Controller |
| BC-BIZ-06 | `update()` success flash uses raw unresolved key `'update.language'` (DEV-LANG-004) | Controller |
| BC-BIZ-07 | `store()`/`update()` write NO activity log (DEV-LANG-005 audit gap) | Controller |
| BC-BIZ-08 | index paginates 11/page; trash paginates 10/page | Controller |

### BC-SM (state machine — is_active + soft-delete lifecycle)
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | Active → toggle(0) → Inactive | Screen-SM-1 |
| BC-SM-02 | Inactive → toggle(1) → Active | Screen-SM-2 |
| BC-SM-03 | Active → destroy → Trashed+Inactive | Controller |
| BC-SM-04 | Trashed → restore → Active-list but stays Inactive (DEV-LANG-007) | Controller |
| BC-SM-05 | Trashed → forceDelete → Removed | Controller |

### BC-REF / BC-INT (referential / integration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `sys_users.prefered_language` → `glb_languages.id` (constraint #10) | _tenant_db / #10 |
| BC-INT-01 | Languages are global; a change is visible to every tenant through the prime_db view | Migration |

### BC-EDG (edge / boundary — documented defects)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | prime_db `glb_languages` is a VIEW; writes route via `global_master_mysql` (DEV-LANG-009) | Model / Migration |
| BC-EDG-02 | Consolidated DDL stale vs migration (DOC-LANG-008) | DDL vs Migration |
| BC-EDG-03 | `global-master` route group (incl. language) registered twice in `routes/web.php` (DEV-LANG-002) | web.php:424,569 |
| BC-EDG-04 | `update()` calls `Gate::authorize('prime.language.update')` twice (DEV-LANG-006) | Controller:72,74 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-* | DDL/Migration | Schema/model/request config correct | All asserts pass | test_language_01 | Ready |
| TC-P02 | BC-AUTH | web.php | Routes registered under central.global-master.language.* | Route::has true | test_language_02 | Ready |
| TC-P03 | BC-BIZ | Controller | Gates + activity events wired | Strings present | test_language_03 | Ready |
| TC-P10 | BC-BIZ-08 | Controller | Index lists with pagination | Table renders | test_language_10 | Ready |
| TC-P11 | BC-BIZ-01 | Controller | Create persists + redirects | Row in DB | test_language_11 | Ready |
| TC-P12 | BC-BIZ | Controller | Update persists | native_name changed | test_language_12 | Ready |
| TC-P13 | BC-BIZ-02 | Controller | Destroy soft-deletes+inactive+log Trashed | deleted_at set | test_language_13 | Ready |
| TC-P14 | BC-SM-03 | Controller | Trashed appears in trash view | Present | test_language_14 | Ready |
| TC-P15 | BC-BIZ-03 | Controller | Restore + log Restored | deleted_at null | test_language_15 | Ready |
| TC-P16 | BC-BIZ-04 | Controller | Force delete + log Stored | Row removed | test_language_16 | Ready |
| TC-P17 | BC-BIZ-05 | Controller | Toggle status JSON + log Toggled | is_active flipped | test_language_17 | Ready |
| TC-P36 | BC-VAL-03 | Request | native_name optional | nullable rule | test_language_36 | Ready |
| TC-P37 | BC-VAL-01/02 | Request | Update ignores self on unique | Update succeeds | test_language_37 | Ready |
| TC-P60 | UI | index.blade | Search control present | input present | test_language_60 | Ready |
| TC-P61 | UI | index.blade | Status filter options | Active/Inactive | test_language_61 | Ready |
| TC-P62 | UI | index.blade | Empty state message | "Not Data Found" | test_language_62 | Ready |
| TC-P63 | UI | index.blade | Breadcrumb title | Language Management | test_language_63 | Ready |
| TC-P64 | BC-AUTH | index.blade | Action/Status columns for admin | Columns render | test_language_64 | Ready |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N18 | BC-BIZ-06 | Controller | update() flash unresolved | 'update.language' literal | test_language_18 | Ready |
| TC-N19 | BC-BIZ-07 | Controller | store/update no activity log | Absent | test_language_19 | Ready |
| TC-N30 | BC-VAL-01/02/04 | Request | Required fields | Errors | test_language_30 | Ready |
| TC-N31 | BC-VAL-01 | Request | Duplicate code | Rejected | test_language_31 | Ready |
| TC-N32 | BC-VAL-02 | Request | Duplicate name | Rejected | test_language_32 | Ready |
| TC-N33 | BC-VAL-01 | Request | code max:10 | Rejected | test_language_33 | Ready |
| TC-N34 | BC-VAL-02 | Request | name max:50 | Rejected | test_language_34 | Ready |
| TC-N35 | BC-VAL-04 | Request | direction in LTR/RTL | Only 2 options | test_language_35 | Ready |
| TC-N50 | BC-AUTH | middleware | Guest redirect to /login | /login | test_language_50 | Ready |
| TC-N51 | BC-AUTH-01 | Controller | index viewAny gate | Gate present + admin passes | test_language_51 | Ready |
| TC-N52 | BC-AUTH-02 | Controller | create gate (create+store) | ≥2 occurrences | test_language_52 | Ready |
| TC-N53 | BC-AUTH-04 | Controller | update gate | Present | test_language_53 | Ready |
| TC-N54 | BC-AUTH-05 | Controller | delete gate | Present | test_language_54 | Ready |
| TC-N55 | BC-AUTH-04 | Controller | toggle uses update gate (no status gate) | Confirmed | test_language_55 | Ready |
| TC-N56 | BC-AUTH-06/07 | Controller | restore/forceDelete gates | Present | test_language_56 | Ready |

### State-Machine (TC-S) + Security (TC-S9x) + Dependency (TC-D) + Edge (TC-E) + Tenancy (TC-T)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S20 | BC-SM-01 | Controller | Active→Inactive toggle | is_active=0 | test_language_20 | Ready |
| TC-S21 | BC-SM-02 | Controller | Inactive→Active toggle | is_active=1 | test_language_21 | Ready |
| TC-S22 | BC-SM-04 | Controller | Restore keeps inactive | is_active=0 | test_language_22 | Ready |
| TC-D40 | BC-REF-01 | #10 | Referenced by sys_users | FK column present | test_language_40 | Guarded |
| TC-D41 | BC-EDG | #10 | Force delete referenced constrained | Blocked/observed | test_language_41 | Guarded |
| TC-D42 | BC-INT-01 | Migration | Global shared view | View exists | test_language_42 | Guarded |
| TC-E70 | BC-EDG-01 | Model | prime_db view / write path | Connection=global_master | test_language_70 | Ready |
| TC-E71 | BC-EDG-02 | DDL | DDL stale vs migration | Drift documented | test_language_71 | Ready |
| TC-E72 | BC-EDG-03 | web.php | Duplicate route group | ≥2 occurrences | test_language_72 | Ready |
| TC-E73 | BC-EDG-04 | Controller | Double authorize | ≥2 occurrences | test_language_73 | Ready |
| TC-E74 | BC-VAL-04 | Request/DDL | ENUM case match | No lowercase variants | test_language_74 | Ready |
| TC-T90 | BC-EDG-01 | Model | Write→global_master, read→view | Row on both | test_language_90 | Ready |
| TC-S91 | Security | Blade | Stored XSS escaped | Payload escaped | test_language_91 | Ready |
| TC-S92 | Security | RMB | Invalid id 404 | 404/Not Found | test_language_92 | Ready |
| TC-S93 | Security | middleware | Guest cannot toggle | No success:true | test_language_93 | Ready |

### Known Source Defects (DEV-###)
| ID | Description | Proving test |
|----|-------------|--------------|
| DEV-LANG-002 | `global-master` route group (incl. language) registered twice in routes/web.php | test_language_72 |
| DEV-LANG-003 | `forceDelete()` logs event `'Stored'` (should be ForceDeleted/Deleted) | test_language_16 |
| DEV-LANG-004 | `update()` success flash uses unresolved raw key `'update.language'` | test_language_18 |
| DEV-LANG-005 | `store()`/`update()` write no activity log (audit-trail gap) | test_language_19 |
| DEV-LANG-006 | `update()` duplicates `Gate::authorize('prime.language.update')` | test_language_73 |
| DEV-LANG-007 | `restore()` leaves language inactive (is_active not reset) | test_language_22 |
| DOC-LANG-008 | Consolidated DDL `_global_db_v4.sql` stale vs real migration | test_language_71 |
| DEV-LANG-009 | prime_db `glb_languages` is a VIEW; model writes via global_master_mysql connection | test_language_70/90 |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_language_01_schema_model_and_request_configuration_are_correct | TC-P01 | Config | 01-09 |
| 2 | test_language_02_routes_are_registered_under_central_global_master | TC-P02 | Config | 01-09 |
| 3 | test_language_03_controller_gates_and_activity_events_are_wired | TC-P03 | Config | 01-09 |
| 4 | test_language_10_index_lists_languages_with_pagination | TC-P10 | BIZ | 10-19 |
| 5 | test_language_11_create_language_persists_row_and_redirects | TC-P11 | BIZ | 10-19 |
| 6 | test_language_12_update_language_persists_changes | TC-P12 | BIZ | 10-19 |
| 7 | test_language_13_destroy_soft_deletes_sets_inactive_and_logs_trashed | TC-P13 | BIZ | 10-19 |
| 8 | test_language_14_trashed_language_appears_in_trash_view | TC-P14 | BIZ | 10-19 |
| 9 | test_language_15_restore_language_and_logs_restored | TC-P15 | BIZ | 10-19 |
| 10 | test_language_16_force_delete_removes_row_and_logs_stored_event | TC-P16 | BIZ | 10-19 |
| 11 | test_language_17_toggle_status_updates_is_active_returns_json_and_logs_toggled | TC-P17 | BIZ | 10-19 |
| 12 | test_language_18_update_success_message_is_unresolved_flash_key | TC-N18 | BIZ/DEV | 10-19 |
| 13 | test_language_19_store_and_update_do_not_write_activity_log | TC-N19 | BIZ/DEV | 10-19 |
| 14 | test_language_20_active_to_inactive_transition | TC-S20 | SM | 20-29 |
| 15 | test_language_21_inactive_to_active_transition | TC-S21 | SM | 20-29 |
| 16 | test_language_22_soft_delete_then_restore_keeps_language_inactive | TC-S22 | SM/DEV | 20-29 |
| 17 | test_language_30_create_requires_name_code_direction | TC-N30 | VAL | 30-39 |
| 18 | test_language_31_duplicate_code_is_rejected | TC-N31 | VAL | 30-39 |
| 19 | test_language_32_duplicate_name_is_rejected | TC-N32 | VAL | 30-39 |
| 20 | test_language_33_code_max_length_enforced | TC-N33 | VAL | 30-39 |
| 21 | test_language_34_name_max_length_enforced | TC-N34 | VAL | 30-39 |
| 22 | test_language_35_direction_enum_only_allows_ltr_or_rtl | TC-N35 | VAL | 30-39 |
| 23 | test_language_36_native_name_is_optional_in_rules | TC-P36 | VAL | 30-39 |
| 24 | test_language_37_update_ignores_self_on_unique_rules | TC-P37 | VAL | 30-39 |
| 25 | test_language_40_language_referenced_by_sys_users_prefered_language | TC-D40 | INT | 40-49 |
| 26 | test_language_41_force_delete_of_referenced_language_is_constrained | TC-D41 | INT | 40-49 |
| 27 | test_language_42_language_is_global_shared_across_tenants | TC-D42 | INT | 40-49 |
| 28 | test_language_50_guest_is_redirected_to_login | TC-N50 | AUTH | 50-59 |
| 29 | test_language_51_index_requires_view_any_permission | TC-N51 | AUTH | 50-59 |
| 30 | test_language_52_create_requires_create_permission | TC-N52 | AUTH | 50-59 |
| 31 | test_language_53_edit_update_requires_update_permission | TC-N53 | AUTH | 50-59 |
| 32 | test_language_54_destroy_requires_delete_permission | TC-N54 | AUTH | 50-59 |
| 33 | test_language_55_toggle_status_uses_update_permission | TC-N55 | AUTH | 50-59 |
| 34 | test_language_56_restore_and_force_delete_require_permissions | TC-N56 | AUTH | 50-59 |
| 35 | test_language_60_search_control_present | TC-P60 | UIX | 60-69 |
| 36 | test_language_61_status_filter_options_present | TC-P61 | UIX | 60-69 |
| 37 | test_language_62_empty_state_message | TC-P62 | UIX | 60-69 |
| 38 | test_language_63_breadcrumb_shows_language_management | TC-P63 | UIX | 60-69 |
| 39 | test_language_64_action_and_status_columns_render_for_admin | TC-P64 | UIX | 60-69 |
| 40 | test_language_70_prime_db_glb_languages_is_a_view | TC-E70 | EDG | 70-79 |
| 41 | test_language_71_consolidated_ddl_is_stale_versus_migration | TC-E71 | EDG | 70-79 |
| 42 | test_language_72_global_master_group_registered_twice | TC-E72 | EDG | 70-79 |
| 43 | test_language_73_update_authorizes_twice | TC-E73 | EDG | 70-79 |
| 44 | test_language_74_direction_enum_case_matches_ddl_and_request | TC-E74 | EDG | 70-79 |
| 45 | test_language_90_writes_target_global_master_not_prime_view | TC-T90 | Tenancy | 90-99 |
| 46 | test_language_91_stored_xss_in_name_is_escaped_on_index | TC-S91 | Security | 90-99 |
| 47 | test_language_92_invalid_language_id_returns_404 | TC-S92 | Security | 90-99 |
| 48 | test_language_93_guest_cannot_reach_toggle_status | TC-S93 | Security | 90-99 |

**Total: 48 test methods.**
