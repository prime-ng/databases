# Tenant Domain — Test Case List & Business Conditions (`prm_TenantDomainTcList_Require.md`)

- **Module:** Prime (PRM) — **CENTRAL / prime_db** (no tenant init)
- **Feature / Screen:** TenantDomain
- **Primary table:** `prm_tenant_domains` (prefix `prm_`, DDL-verified in `_prime_db_v4.sql:386`)
- **Controller:** `Modules\Prime\Http\Controllers\TenantDomainController`
- **Model:** `Modules\Prime\Models\Domain` (extends `Stancl\Tenancy\Database\Models\Domain`)
- **Routes group:** `central.prime.tenant-domain.*` (resource + `toggleStatus`), prefix `/prime/tenant-domain`
- **Host:** `http://127.0.0.1:8000`
- **Test file:** `prm_TenantDomain_TestCas.php` (47 methods)
- **Activity sink:** `sys_central_activity_logs` (central; `activityLog()` routes here when `tenancy()->initialized` is false)

> **DEFECT SUMMARY**
> - **BUG-PRM-001** (brief claim: `db_password` PLAINTEXT / no encrypted cast) — **NOT REPRODUCIBLE / REMEDIATED.** Current `Domain::casts()` returns `['db_password' => 'encrypted']`. The encryption control is present. **BR-PRM-006 = PASS.** Proven by `test_15`. The brief/audit note is stale; discrepancy documented here and in the Gap Analysis.
> - **BUG-PRM-002 (NEW, P1):** `Domain` does **not** use `SoftDeletes`, but the DDL has `deleted_at` and `destroy()` logs a `"soft deleted"` message. `delete()` therefore performs a **HARD delete** — no trash/restore, `deleted_at` never set. Proven by `test_01` + `test_14`.
> - **BUG-PRM-003 (NEW, P2):** Validation `max` exceeds DDL column sizes — `db_name`/`db_username` use `max:255` vs `VARCHAR(100)`; `db_host` `max:255` vs `VARCHAR(200)`. Documented by `test_39`.
> - **BUG-PRM-004 (NEW, P2):** Encrypted `db_password` ciphertext can overflow `db_password VARCHAR(255)` for long plaintext. Documented by `test_71`.

---

## 1. Business Conditions

### BC-DB (schema / DDL) — Source: `DDL-prm_tenant_domains`
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `prm_tenant_domains` exists with columns id, tenant_id, domain, db_name, db_host, db_port, db_username, db_password, is_active, created_at, updated_at, deleted_at | DDL-prm_tenant_domains |
| BC-DB-02 | PK `id` INT UNSIGNED AUTO_INCREMENT | DDL-prm_tenant_domains |
| BC-DB-03 | FK `tenant_id` → `prm_tenant(id)` `ON DELETE RESTRICT` | DDL-prm_tenant_domains |
| BC-DB-04 | `domain` VARCHAR(255) NOT NULL (unique enforced at app layer via `unique:` rule) | DDL + Controller |
| BC-DB-05 | `db_name` VARCHAR(100), `db_host` VARCHAR(200), `db_port` VARCHAR(10) DEFAULT '3306', `db_username` VARCHAR(100), `db_password` VARCHAR(255) | DDL-prm_tenant_domains |
| BC-DB-06 | `is_active` TINYINT(1) DEFAULT 1 | DDL-prm_tenant_domains |
| BC-DB-07 | `deleted_at` column present, BUT model lacks `SoftDeletes` → hard delete (**BUG-PRM-002**) | DDL + Model |

### BC-VAL (validation) — Source: `TenantDomainController::store()/update()/toggleStatus()`
| ID | Rule | Message (Laravel default) | Source |
|----|------|---------------------------|--------|
| BC-VAL-01 | `tenant_id` required, `exists:prm_tenant,id` | "The tenant id field is required." / "The selected tenant id is invalid." | store() |
| BC-VAL-02 | `domain` required, string, max:255, `unique:prm_tenant_domains,domain` | "…required." / "…must not be greater than 255…" / "…has already been taken." | store() |
| BC-VAL-03 | `db_name` required, string, max:255 | "The db name field is required." | store()/update() |
| BC-VAL-04 | `db_host` required, string, max:255 | "The db host field is required." | store()/update() |
| BC-VAL-05 | `db_port` required, string, max:10 | "The db port field is required." / "…greater than 10 characters." | store()/update() |
| BC-VAL-06 | `db_username` required, string, max:255 | "The db username field is required." | store()/update() |
| BC-VAL-07 | `db_password` required (store) / nullable (update), string, max:255 | "The db password field is required." | store()/update() |
| BC-VAL-08 | `is_active` nullable, boolean | — | store()/update() |
| BC-VAL-09 | toggleStatus: `is_active` required, boolean | "The is active field is required." | toggleStatus() |
| BC-VAL-10 | On update, `tenant_id` & `domain` are NOT validated/persisted (immutable) | Controller update() rule list | update() |

### BC-AUTH (permission gates) — Source: `TenantDomainController` `Gate::authorize()`
| ID | Gate | Controller method(s) | Source |
|----|------|----------------------|--------|
| BC-AUTH-01 | `prime.tenant-domain.viewAny` | index | Screen-PM |
| BC-AUTH-02 | `prime.tenant-domain.create` | create, store | Screen-PM |
| BC-AUTH-03 | `prime.tenant-domain.view` | show | Screen-PM |
| BC-AUTH-04 | `prime.tenant-domain.update` | edit, update, toggleStatus | Screen-PM |
| BC-AUTH-05 | `prime.tenant-domain.delete` | destroy | Screen-PM |
| BC-AUTH-06 | Guest (unauthenticated) redirected to `/login` (`auth`,`verified` middleware) | all | routes/web.php:107 |
| BC-AUTH-07 | No `restore` / `forceDelete` gates or routes exist for this feature | routes | routes/web.php:142-143 |

### BC-BIZ (business logic / activity) — Source: Controller / Model
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store(): creates row, wraps in DB transaction, redirects to index with `success` = flash('created.tenant_domain') = "Tenant Domain was created successfully." | store() |
| BC-BIZ-02 | store()/update(): `is_active` forced to `1` if checkbox present else `0` (overrides validated value) | Controller |
| BC-BIZ-03 | update(): if `db_password` blank → unset → existing password kept | update() |
| BC-BIZ-04 | destroy(): logs `deleted` BEFORE delete; HARD delete (no SoftDeletes) | destroy() (**BUG-PRM-002**) |
| BC-BIZ-05 | toggleStatus(): AJAX JSON `{success, is_active, message}`; message = flash('status_updated.tenant_domain') | toggleStatus() |
| BC-BIZ-06 | Activity events use literal lowercase strings: `created`, `updated`, `deleted`; sink = `sys_central_activity_logs`; `user_id` = `Auth::id()` | activityLog() |
| BC-BIZ-07 | index(): paginate 10, `orderBy id desc`, eager-load `tenant`, search by `domain` LIKE or tenant `name` LIKE, `withQueryString` | index() |
| BC-BIZ-08 | create(): tenant dropdown = `Tenant::live()->where('is_active', true)` | create() |
| BC-BIZ-09 | edit view: `tenant` and `domain` rendered read-only (`domain_display`); no editable `tenant_id`/`domain` inputs | edit.blade.php |
| BC-BIZ-10 | `db_password` cast to `encrypted` → stored ciphertext, decrypted on read (**BUG-PRM-001 remediated**) | Model casts() |
| BC-BIZ-11 | Stancl `ConvertsDomainsToLowercase` → `domain` persisted lowercase | BaseDomain concern |

### BC-SM (state machine — is_active toggle) — Source: `Screen-SM` / toggleStatus()
| ID | State | Trigger | Next state | Source |
|----|-------|---------|-----------|--------|
| BC-SM-01 | is_active = 0 | toggleStatus(is_active=1) | is_active = 1 | toggleStatus() |
| BC-SM-02 | is_active = 1 | toggleStatus(is_active=0) | is_active = 0 | toggleStatus() |
| BC-SM-03 | any | toggleStatus(non-boolean) | rejected (422), state unchanged | toggleStatus() |

### BC-REF / BC-INT (referential integrity) — Source: DDL FK
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `tenant_id` → `prm_tenant(id)` ON DELETE RESTRICT (cannot delete tenant while a domain references it) | DDL |
| BC-INT-01 | Domain `belongsTo` Tenant (`Domain::tenant()`); deleting a domain leaves the tenant intact | Model + relationship |

### BC-EDG (edge cases)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Domain stored lowercase regardless of input casing | Screen-EDG / BaseDomain |
| BC-EDG-02 | Long `db_password` (near 255 chars) may overflow VARCHAR(255) once encrypted (**BUG-PRM-004**) | DDL + cast |
| BC-EDG-03 | Whitespace-only `db_username` passes `required` (not trimmed) | Laravel `required` semantics |
| BC-EDG-04 | Validation `max:255` > DDL column size for db_name/host/username (**BUG-PRM-003**) | DDL vs Controller |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Positive | BC-DB-01..07, BC-BIZ-10 | DDL/Model | Schema, casts, routes, gates config truth | All assertions pass | test_01 | Automated |
| TC-P02 | Positive | BC-VAL(all) | Controller | No FormRequest — inline validation | Classes absent | test_02 | Automated |
| TC-P03 | Positive | BC-BIZ-07 | index() | Index renders with search + pagination | Table + search visible | test_10 | Automated |
| TC-P04 | Positive | BC-BIZ-01,06 | store() | Store creates row + logs `created` | Row + log created | test_11 | Automated |
| TC-P05 | Positive | BC-BIZ-06 | update() | Update modifies fields + logs `updated` | db_host changed + log | test_12 | Automated |
| TC-P06 | Positive | BC-BIZ-03 | update() | Blank password kept on update | raw password unchanged | test_13 | Automated |
| TC-P07 | Positive | BC-BIZ-10 | Model | db_password encrypted at rest (BUG-PRM-001 remediated) | ciphertext ≠ plaintext, decrypts | test_15 | Automated |
| TC-P08 | Positive | BC-BIZ-02 | store() | is_active defaults 0 when checkbox absent | is_active=0 | test_16 | Automated |
| TC-P09 | Positive | BC-BIZ-08 | create() | Create form fields present | selects/inputs present | test_17 | Automated |
| TC-P10 | Positive | BC-BIZ-09 | edit.blade | Tenant/domain read-only on edit | no editable inputs | test_18 | Automated |
| TC-P11 | Positive | BC-BIZ-06 | activityLog | Activity records admin as actor | user_id set | test_19 | Automated |
| TC-P12 | Positive | BC-INT-01 | Model | Domain belongsTo tenant | relationship resolves | test_40 | Automated |
| TC-P13 | Positive | BC-BIZ-07 | index() | Search by domain filters | row shown | test_60 | Automated |
| TC-P14 | Positive | BC-BIZ-07 | index() | Breadcrumb + table columns | text present | test_62, test_63 | Automated |

### State-machine (TC-SM)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-SM01 | State | BC-SM-01 | toggleStatus | Activate (0→1) | JSON success, is_active=1, log `updated` | test_20 | Automated |
| TC-SM02 | State | BC-SM-02 | toggleStatus | Deactivate (1→0) | JSON success, is_active=0 | test_21 | Automated |
| TC-SM03 | State | BC-SM-03 | toggleStatus | Non-boolean rejected | 422, state unchanged | test_22 | Automated |
| TC-SM04 | State | BC-BIZ-07 | index() | Inactive domain still listed | domain visible | test_23 | Automated |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Negative | BC-VAL-01 | store() | tenant_id required | 422 errors.tenant_id | test_30 | Automated |
| TC-N02 | Negative | BC-VAL-02 | store() | domain required | 422 errors.domain | test_31 | Automated |
| TC-N03 | Negative | BC-VAL-02 | store() | duplicate domain | 422 errors.domain | test_32 | Automated |
| TC-N04 | Negative | BC-VAL-03..07 | store() | db_name/host/port/username/password required | 422 each | test_33 | Automated |
| TC-N05 | Negative | BC-VAL-02 | store() | domain > 255 chars | 422 errors.domain | test_34 | Automated |
| TC-N06 | Negative | BC-VAL-05 | store() | db_port > 10 chars | 422 errors.db_port | test_35 | Automated |
| TC-N07 | Negative | BC-VAL-01 | store() | non-existent tenant_id | 422 errors.tenant_id | test_36 | Automated |
| TC-N08 | Negative | BC-VAL-03 | update() | db_name required on update | 422 errors.db_name | test_37 | Automated |
| TC-N09 | Negative | BC-VAL-10 | update() | tenant_id/domain immutable | unchanged in DB | test_38 | Automated |
| TC-N10 | Negative | BC-EDG-04 | DDL/Controller | max:255 > VARCHAR(100) (BUG-PRM-003) | db_name not flagged | test_39 | Automated |
| TC-N11 | Negative | BC-AUTH-06 | routes | guest → /login | redirect | test_50 | Automated |
| TC-N12 | Negative | BC-VAL-09 | toggleStatus | is_active required boolean | 422 | test_22 | Automated |
| TC-N13 | Negative | BC-DB-01 | show() | unknown id → 404 | 404 | test_92 | Automated |

### Dependency (TC-D)
| TC ID | Cat (A-G) | BC | Source | Description | Expected | Method | Status |
|-------|-----------|----|--------|-------------|----------|--------|--------|
| TC-D01 | A (inactive display) | BC-BIZ-07 | index | Inactive domain visible in list | shown | test_23 | Automated |
| TC-D02 | B (delete preservation) | BC-BIZ-04, BC-DB-07 | destroy | HARD delete — row gone (BUG-PRM-002) | not in table | test_14 | Automated |
| TC-D03 | C (FK RESTRICT) | BC-REF-01 | DDL | Parent tenant delete blocked | integrity error | test_41 | Automated |
| TC-D04 | E (cross-entity) | BC-INT-01 | Model | Delete domain keeps tenant | tenant exists | test_42 | Automated |

### Permissions (TC-AUTH)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-AU01 | BC-AUTH-01 | index | limited user denied index | 403/redirect | test_51 | Automated |
| TC-AU02 | BC-AUTH-02 | store | limited user denied store | 403/redirect | test_52 | Automated |
| TC-AU03 | BC-AUTH-03 | show | limited user denied show | 403/redirect | test_53 | Automated |
| TC-AU04 | BC-AUTH-04 | update | limited user denied update | 403/redirect | test_54 | Automated |
| TC-AU05 | BC-AUTH-05 | destroy | limited user denied destroy | 403/redirect | test_55 | Automated |
| TC-AU06 | BC-AUTH-04 | toggleStatus | limited user denied toggle | 403/redirect | test_56 | Automated |
| TC-AU07 | BC-AUTH-04/05 | index view | action column visibility | present for admin | test_57 | Automated |

### Security (TC-S)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S01 | BC-EDG | index | reflected XSS in search escaped | no script execution | test_90 | Automated |
| TC-S02 | BC-EDG | index | stored XSS in domain escaped | HTML escaped | test_91 | Automated |
| TC-S03 | BC-DB-01 | show | IDOR/unknown id → 404 | 404 | test_92 | Automated |

### Edge (TC-EDG)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-E01 | BC-EDG-01 | BaseDomain | domain lowercased | stored lowercase | test_70 | Automated |
| TC-E02 | BC-EDG-02 | DDL/cast | long password overflow (BUG-PRM-004) | documented | test_71 | Automated |
| TC-E03 | BC-EDG-03 | Laravel | whitespace username accepted | not flagged | test_72 | Automated |

---

## 3. Test Method Index (by semantic band)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_tenantdomain_01_schema_model_and_configuration_are_correct | TC-P01, BUG-PRM-002 | Config truth | 01-09 |
| 2 | test_tenantdomain_02_no_form_request_uses_inline_validation | TC-P02 | Config truth | 01-09 |
| 3 | test_tenantdomain_10_index_renders_with_search_and_pagination | TC-P03 | BC-BIZ | 10-19 |
| 4 | test_tenantdomain_11_store_creates_domain_and_logs_created_event | TC-P04 | BC-BIZ | 10-19 |
| 5 | test_tenantdomain_12_update_modifies_db_fields_and_logs_updated_event | TC-P05 | BC-BIZ | 10-19 |
| 6 | test_tenantdomain_13_update_keeps_existing_password_when_left_blank | TC-P06 | BC-BIZ | 10-19 |
| 7 | test_tenantdomain_14_destroy_hard_deletes_row_proving_bug_prm_002 | TC-D02 | BC-BIZ/Defect | 10-19 |
| 8 | test_tenantdomain_15_db_password_is_encrypted_at_rest_bug_prm_001_remediated | TC-P07 | BC-BIZ/Security | 10-19 |
| 9 | test_tenantdomain_16_store_is_active_defaults_to_zero_when_checkbox_absent | TC-P08 | BC-BIZ | 10-19 |
| 10 | test_tenantdomain_17_create_form_lists_only_live_active_tenants | TC-P09 | BC-BIZ | 10-19 |
| 11 | test_tenantdomain_18_edit_form_tenant_and_domain_are_read_only | TC-P10 | BC-BIZ | 10-19 |
| 12 | test_tenantdomain_19_activity_log_records_admin_as_actor | TC-P11 | BC-BIZ | 10-19 |
| 13 | test_tenantdomain_20_toggle_status_activates_inactive_domain | TC-SM01 | BC-SM | 20-29 |
| 14 | test_tenantdomain_21_toggle_status_deactivates_active_domain | TC-SM02 | BC-SM | 20-29 |
| 15 | test_tenantdomain_22_toggle_status_requires_boolean_is_active | TC-SM03/TC-N12 | BC-SM/VAL | 20-29 |
| 16 | test_tenantdomain_23_inactive_domain_remains_listed_in_index | TC-SM04/TC-D01 | BC-BIZ | 20-29 |
| 17 | test_tenantdomain_30_store_requires_tenant_id | TC-N01 | BC-VAL | 30-39 |
| 18 | test_tenantdomain_31_store_requires_domain | TC-N02 | BC-VAL | 30-39 |
| 19 | test_tenantdomain_32_store_rejects_duplicate_domain | TC-N03 | BC-VAL | 30-39 |
| 20 | test_tenantdomain_33_store_requires_all_db_connection_fields | TC-N04 | BC-VAL | 30-39 |
| 21 | test_tenantdomain_34_store_rejects_domain_over_255_chars | TC-N05 | BC-VAL | 30-39 |
| 22 | test_tenantdomain_35_store_rejects_db_port_over_10_chars | TC-N06 | BC-VAL | 30-39 |
| 23 | test_tenantdomain_36_store_rejects_non_existent_tenant_id | TC-N07 | BC-VAL | 30-39 |
| 24 | test_tenantdomain_37_update_requires_db_connection_fields | TC-N08 | BC-VAL | 30-39 |
| 25 | test_tenantdomain_38_update_cannot_change_tenant_or_domain | TC-N09 | BC-VAL | 30-39 |
| 26 | test_tenantdomain_39_validation_max_exceeds_ddl_column_size_bug_prm_003 | TC-N10 | Defect | 30-39 |
| 27 | test_tenantdomain_40_domain_belongs_to_tenant_relationship | TC-P12 | BC-INT | 40-49 |
| 28 | test_tenantdomain_41_tenant_fk_restrict_blocks_parent_delete | TC-D03 | BC-REF | 40-49 |
| 29 | test_tenantdomain_42_deleting_domain_does_not_delete_tenant | TC-D04 | BC-INT | 40-49 |
| 30 | test_tenantdomain_50_guest_is_redirected_to_login | TC-N11 | BC-AUTH | 50-59 |
| 31 | test_tenantdomain_51_index_denies_user_without_viewany_permission | TC-AU01 | BC-AUTH | 50-59 |
| 32 | test_tenantdomain_52_store_denies_user_without_create_permission | TC-AU02 | BC-AUTH | 50-59 |
| 33 | test_tenantdomain_53_show_denies_user_without_view_permission | TC-AU03 | BC-AUTH | 50-59 |
| 34 | test_tenantdomain_54_update_denies_user_without_update_permission | TC-AU04 | BC-AUTH | 50-59 |
| 35 | test_tenantdomain_55_destroy_denies_user_without_delete_permission | TC-AU05 | BC-AUTH | 50-59 |
| 36 | test_tenantdomain_56_toggle_status_denies_user_without_update_permission | TC-AU06 | BC-AUTH | 50-59 |
| 37 | test_tenantdomain_57_action_column_hidden_without_permissions | TC-AU07 | BC-AUTH | 50-59 |
| 38 | test_tenantdomain_60_search_by_domain_filters_results | TC-P13 | UI/UX | 60-69 |
| 39 | test_tenantdomain_61_search_with_no_match_shows_empty_state | TC-P13 | UI/UX | 60-69 |
| 40 | test_tenantdomain_62_index_shows_breadcrumb | TC-P14 | UI/UX | 60-69 |
| 41 | test_tenantdomain_63_index_lists_expected_table_columns | TC-P14 | UI/UX | 60-69 |
| 42 | test_tenantdomain_70_domain_is_stored_lowercase | TC-E01 | Edge | 70-79 |
| 43 | test_tenantdomain_71_long_password_encryption_overflow_bug_prm_004 | TC-E02 | Edge/Defect | 70-79 |
| 44 | test_tenantdomain_72_whitespace_only_db_username_behaviour | TC-E03 | Edge | 70-79 |
| 45 | test_tenantdomain_90_reflected_xss_in_search_is_escaped | TC-S01 | Security | 90-99 |
| 46 | test_tenantdomain_91_stored_xss_in_domain_is_escaped_on_render | TC-S02 | Security | 90-99 |
| 47 | test_tenantdomain_92_show_of_missing_id_returns_404 | TC-S03/TC-N13 | Security | 90-99 |

## 4. Known Source Defects
| ID | Severity | Summary | Proving test |
|----|----------|---------|--------------|
| BUG-PRM-001 | P0 (brief) | `db_password` plaintext — **NOT reproducible; remediated** (encrypted cast present) | test_15, test_01 |
| BUG-PRM-002 | P1 | Hard delete despite `deleted_at` + "soft deleted" intent (no `SoftDeletes` trait) | test_01, test_14 |
| BUG-PRM-003 | P2 | Validation `max:255` exceeds DDL column sizes (db_name/host/username) | test_39 |
| BUG-PRM-004 | P2 | Encrypted `db_password` can overflow VARCHAR(255) for long input | test_71 |
