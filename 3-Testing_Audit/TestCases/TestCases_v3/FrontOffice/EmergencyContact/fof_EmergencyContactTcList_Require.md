# FrontOffice ▸ EmergencyContact — Test Case List & Requirements (COMBINED)

> Combined artifact: Feature Information + Business Conditions + Test Case List + Test Method Index + Manual Test Steps (complex flows only) + Known Source Defects.
> One screen = one requirement = one comprehensive Dusk suite (`fof_EmergencyContact_TestCas.php`, 37 methods).

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature / Screen | EmergencyContact (external emergency contact directory) |
| Primary table | `fof_emergency_contacts` (prefix `fof_` — verified vs DDL `CREATE TABLE`) |
| Controller | `Modules\FrontOffice\Http\Controllers\EmergencyContactController` |
| Model | `Modules\FrontOffice\Models\EmergencyContact` (`$table = fof_emergency_contacts`, `SoftDeletes`, `HasFactory`, `scopeActive`) |
| Policy | `Modules\FrontOffice\Policies\EmergencyContactPolicy` (typed against `Modules\SchoolSetup\Models\User`) |
| FormRequest | **NONE** — inline `$request->validate()` in `store()`/`update()` (DEV-FOF-EC-003) |
| Route group | `fof.emergency-contacts.*` under `/front-office/...` (`auth`,`verified` + tenant) |
| Base path | `/front-office/emergency-contacts` (index/create/store/show/edit/update/destroy) |
| Trash/restore | `/front-office/emergency-contacts/trash/view`, `/{id}/restore`, `/{id}/force-delete` |
| Toggle | `POST|PATCH /front-office/emergency-contacts/{contact}/toggle-status` (`toggleStatus`, JSON) |
| Landing after write | `redirect(route('fof.menu.compliance').'?tab=emergency')` (NOT the index route) |
| CRUD type | Simple CRUD + soft-delete lifecycle (no FSM) |
| Soft delete | Yes (`deleted_at`, `SoftDeletes`) |
| Pagination | Trash view `paginate(15)`; index groups by `contact_type` (no paginate) |
| Permissions | `frontoffice.emergency-contact.{view,create,update,delete,restore,forceDelete}` (string Gates) |
| Activity log | Sink `sys_activity_logs` via `activityLog()`. **Only `restore()`='Restored' and `forceDelete()`='Deleted' log; `store`/`update`/`destroy` do NOT (DEV-FOF-EC-002).** |
| DB scope | TENANT-SIDE — tenancy init in `setUp`, guarded end in `tearDown` |
| Test style | Dusk `browse()` + Eloquent DB asserts + in-page fetch (mirrors `Complaint/CmpCategory`) |

### Column contract (`fof_emergency_contacts`)
| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| id | BIGINT UNSIGNED | NO | AI | PK |
| contact_name | VARCHAR(100) | NO | — | required, `max:100` |
| organization | VARCHAR(150) | YES | NULL | **not a form input** (DEV-FOF-EC-004) |
| contact_type | ENUM(9) | NO | — | DDL: Hospital,Police,Fire,Ambulance,Transport,Utility,Parent_Emergency,Government,Other |
| primary_phone | VARCHAR(15) | NO | — | required, `max:15` |
| alternate_phone | VARCHAR(15) | YES | NULL | `max:15` |
| address | VARCHAR(200) | YES | NULL | `max:200` |
| notes | TEXT | YES | NULL | no `max:` |
| sort_order | TINYINT UNSIGNED | NO | 0 | **not a form input** (DEV-FOF-EC-004) |
| is_active | TINYINT(1) | NO | 1 | boolean cast; toggled by `toggleStatus` |
| created_by | BIGINT UNSIGNED | NO | — | set by controller (`auth()->id()`), **no FK** |
| updated_by | BIGINT UNSIGNED | NO | — | set by controller, **no FK** |
| created_at/updated_at | TIMESTAMP | YES | NULL | |
| deleted_at | TIMESTAMP | YES | NULL | soft delete |

**Indexes:** PK(id) + non-unique `idx_fof_ec_type(contact_type)`. **No UNIQUE key → G43 duplicate-rejection is N/A** (documented, asserted in `test_05`).

---

## 2. Business Conditions

### BC-DB (DDL constraints — one testable fact each)
| ID | Condition | Source | TC |
|----|-----------|--------|----|
| BC-DB-01 | `contact_name` NOT NULL, no default → missing rejected | DDL-fof_emergency_contacts | TC-N01 |
| BC-DB-02 | `primary_phone` NOT NULL, no default → missing rejected | DDL | TC-N02 |
| BC-DB-03 | `created_by` NOT NULL, no default → missing rejected | DDL | TC-N03 |
| BC-DB-04 | `contact_type` strict ENUM(9) → invalid rejected | DDL | TC-N04 |
| BC-DB-05 | `contact_name` VARCHAR(100) → over-length rejected/truncated; exactly-100 accepted | DDL | TC-N07 / TC-P08 |
| BC-DB-06 | `primary_phone` VARCHAR(15) → over-length rejected/truncated | DDL | TC-N08 |
| BC-DB-07 | `address` VARCHAR(200) → over-length rejected/truncated | DDL | TC-N09 |
| BC-DB-08 | `organization`,`alternate_phone`,`address`,`notes` nullable → omitted accepted | DDL | TC-P08 |
| BC-DB-09 | `sort_order` DEFAULT 0, `is_active` DEFAULT 1 applied when omitted | DDL | TC-P01 |
| BC-DB-10 | `deleted_at` present AND `SoftDeletes` trait present (independent) | DDL/model | TC-P03 |
| BC-DB-11 | NO UNIQUE key on the table (G43 N/A) | DDL | TC-P05 |
| BC-DB-12 | `created_by`/`updated_by` have NO FK to `sys_users` → orphan id accepted | DDL comment | TC-D01 |

### BC-VAL (validation — inline controller rules)
| ID | Condition | Source | TC |
|----|-----------|--------|----|
| BC-VAL-01 | `contact_name` required, string, max:100 | Controller `store()` | TC-N01/TC-N07 |
| BC-VAL-02 | `contact_type` required, `in:Hospital,Police,Fire,Transport,Ambulance,Other` | Controller | TC-N04/TC-N05 |
| BC-VAL-03 | `primary_phone` required, string, max:15 | Controller | TC-N02/TC-N08 |
| BC-VAL-04 | `alternate_phone` nullable max:15; `address` nullable max:200; `notes` nullable | Controller | TC-P08 |
| BC-VAL-05 | No FormRequest → no `messages()`, no `authorize()` defense-in-depth | Controller (DEV-FOF-EC-003) | TC-P07 |

### BC-AUTH (authorization)
| ID | Condition | Source | TC |
|----|-----------|--------|----|
| BC-AUTH-01 | Every action gated by `frontoffice.emergency-contact.{action}` string Gate | Controller | TC-S01 |
| BC-AUTH-02 | Policy exposes viewAny/view/create/update/delete/restore/forceDelete | Policy | TC-S02 |
| BC-AUTH-03 | Guest → redirect `/login` | routes `auth` mw | TC-S03 |
| BC-AUTH-04 | Non-super-admin without permission → 403 (`forgetCachedPermissions`, #31) | Gate | TC-S04 |

### BC-BIZ (business rules)
| ID | Condition | Source | TC |
|----|-----------|--------|----|
| BC-BIZ-01 | Index lists contacts grouped by `contact_type`, ordered by type then name | Controller `index()` | TC-P02 |
| BC-BIZ-02 | `is_active` defaults true from the create form's hidden+checkbox pair | Controller/Blade | TC-P01/TC-P06 |
| BC-BIZ-03 | `toggleStatus` flips `is_active` and returns JSON `{success,is_active}` | Controller | TC-P06 |
| BC-BIZ-04 | `organization`/`sort_order` fillable but never accepted by the web form | Controller/model (DEV-FOF-EC-004) | TC-P07b |

### BC-AUTO (programmatically-managed, G48 — never form inputs)
| ID | Field | Set by | TC |
|----|-------|--------|----|
| BC-AUTO-01 | `created_by`,`updated_by` | `auth()->id()` in controller | TC-P01 |
| BC-AUTO-02 | `sort_order` | DB default 0 (never sent) | TC-P01/TC-P07b |
| BC-AUTO-03 | `organization` | never sent → NULL | TC-P01/TC-P07b |

### BC-REF (referential / lifecycle)
| ID | Condition | Source | TC |
|----|-----------|--------|----|
| BC-REF-01 | `created_by` has no FK → orphan id accepted | DDL | TC-D01 |
| BC-REF-02 | Soft delete hides row; restore revives; force-delete removes permanently | Controller/model | TC-P04a/b/c |
| BC-REF-03 | `restore()` cannot recover a force-deleted row | model | TC-D02 |

### BC-SM
None — EmergencyContact is a flat CRUD directory (no status workflow). `is_active` is a boolean toggle, not a state machine.

### BC-EDG / BC-S (edge / security)
| ID | Condition | Source | TC |
|----|-----------|--------|----|
| BC-EDG-01 | `notes` TEXT accepts a large body (no `max:`) | DDL/controller | TC-E01 |
| BC-S-01 | Free-text stored verbatim; Blade `{{ }}` escapes on render (no stored sanitisation) | Blade index | TC-S05 |
| BC-S-02 | `toggle-status` on a non-existent id → 404 (never 200) | route RMB | TC-S06 |

---

## 3. Test Case List

### Positive
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-09/BC-AUTO | DDL | Create applies server defaults (sort_order=0, is_active=1, organization NULL, created_by set) | Row persisted with defaults | `_10_create_applies_server_defaults` | Ready |
| TC-P02 | BC-BIZ-01 | Controller | Index groups contacts by contact_type | Grouped collection keyed by type | `_11_index_grouped_by_contact_type` | Ready |
| TC-P03 | BC-DB-10 | DDL/model | `deleted_at` column AND SoftDeletes trait present (independent) | Both true | `_03_soft_delete_column_and_trait_independent` | Ready |
| TC-P04a | BC-REF-02 | Controller | Soft delete hides row & restore revives it | trashed→restored | `_15_soft_delete_then_restore_lifecycle` | Ready |
| TC-P04b | BC-REF-02 | Controller | Force delete removes row permanently | row gone | `_16_force_delete_removes_row` | Ready |
| TC-P05 | BC-DB-11 | DDL | No UNIQUE key present (G43 N/A) | 0 unique non-PK indexes | `_05_no_unique_indexes_present` | Ready |
| TC-P06 | BC-BIZ-03 | Controller | toggle_status flips is_active | boolean flips | `_17_toggle_status_flips_is_active` | Ready |
| TC-P07 | BC-VAL-05 | Controller | No FormRequest; inline validate present | asserted | `_07_no_form_request_inline_validation` | Ready |
| TC-P07b | BC-BIZ-04 | Controller/model | organization & sort_order not web inputs but stay fillable | asserted | `_13_organization_and_sort_order_not_web_inputs` | Ready |
| TC-P08 | BC-DB-05/08 | DDL | Exactly-max lengths + omitted nullables accepted | row persisted | `_39_max_length_boundary_and_nullables_accepted` | Ready |
| TC-P09 | BC-BIZ | Model | scopeActive filters inactive | inactive excluded | `_14_scope_active_filters_inactive` | Ready |
| TC-P10 | BC-BIZ | Controller | Update mutates fields & updated_by | persisted | `_12_update_changes_fields` | Ready |
| TC-P11 | schema | DDL | Full DDL↔live alignment matrix | all columns/types match | `_01_ddl_schema_alignment_matrix` | Ready |
| TC-P12 | model | model | Model table/fillable/casts/scope verified | match | `_02_model_configuration_and_fillable_verified` | Ready |
| TC-P13 | schema | DDL | contact_type ENUM carries all 9 members | present | `_04_contact_type_enum_full_ddl_values` | Ready |
| TC-P14 | routes | routes | All 11 routes registered | registered (or skip if disabled) | `_06_routes_registered` | Ready |
| TC-P15 | UI | Blade | Create page renders real fields | fields present | `_60_create_page_renders` | Env |
| TC-P16 | tenancy | DDL | fof_ table on tenant connection | table present | `_90_tenant_context_active` | Ready |

### Negative
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-01 | DDL | Missing contact_name | rejected / zero-fallback | `_30_missing_contact_name_rejected` | Ready |
| TC-N02 | BC-DB-02 | DDL | Missing primary_phone | rejected | `_31_missing_primary_phone_rejected` | Ready |
| TC-N03 | BC-DB-03 | DDL | Missing created_by | rejected | `_32_missing_created_by_rejected` | Ready |
| TC-N04 | BC-DB-04 | DDL | Invalid contact_type ('NotAnEnumValue') | ENUM rejects | `_33_invalid_contact_type_rejected` | Ready |
| TC-N05 | BC-VAL-02 | Controller | App `in:` list OMITS Utility/Parent_Emergency/Government (DEV-FOF-EC-001) | not in source | `_35_app_validation_omits_extended_enum` | Ready |
| TC-N07 | BC-DB-05 | DDL | Over-length contact_name (105) | rejected/truncated ≤100 | `_36_contact_name_over_length_rejected` | Ready |
| TC-N08 | BC-DB-06 | DDL | Over-length primary_phone (20) | rejected/truncated ≤15 | `_37_primary_phone_over_length_rejected` | Ready |
| TC-N09 | BC-DB-07 | DDL | Over-length address (205) | rejected/truncated ≤200 | `_38_address_over_length_rejected` | Ready |
| TC-N10 | BC-VAL-01 | Blade/UI | Create form without name stays on page | on create page / error | `_61_required_name_ui_rejected` | Env |
| TC-N11 | BC-S-02 | route | toggle-status on non-existent id | 404 (not 200) | `_92_toggle_status_nonexistent_returns_404` | Env |

### Dependency
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D01 | BC-REF-01 | DDL | created_by orphan id accepted (no FK) | persisted | `_40_created_by_has_no_fk` | Ready |
| TC-D02 | BC-REF-03 | model | restore cannot recover force-deleted row | row absent | `_41_restore_does_not_recover_hard_deleted` | Ready |
| TC-D03 | BC-DB-04 | DDL | Extended ENUM members accepted at DB layer (DEV-FOF-EC-001) | persisted | `_34_ddl_extended_enum_accepted_by_db` | Ready |

### Security / Auth / Tenancy
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S01 | BC-AUTH-01 | Controller | All 6 gate abilities enforced | present in source | `_50_controller_gates_present` | Ready |
| TC-S02 | BC-AUTH-02 | Policy | Policy abilities match | methods exist | `_51_policy_abilities_match` | Ready |
| TC-S03 | BC-AUTH-03 | routes | Guest → /login | redirect | `_52_guest_redirected_to_login` | Env |
| TC-S04 | BC-AUTH-04 | Gate | Non-super-admin no perm → 403 | 403/unauthorized | `_53_forbidden_without_permission` | Env |
| TC-S05 | BC-S-01 | Blade | XSS payload stored raw (Blade escapes on output) | stored verbatim | `_91_xss_payload_stored_raw` | Ready |
| TC-E01 | BC-EDG-01 | DDL | notes TEXT accepts large body | persisted | `_70_notes_accepts_large_text` | Ready |

*Status legend:* **Ready** = runs on the tenant DB without the module enabled; **Env** = needs FrontOffice enabled + ChromeDriver (self-skips otherwise, #19).

---

## 4. Test Method Index

| # | Method | TC | Category | Band |
|---|--------|----|----------|------|
| 1 | `_01_ddl_schema_alignment_matrix` | TC-P11 | Schema | 01–09 |
| 2 | `_02_model_configuration_and_fillable_verified` | TC-P12 | Schema | 01–09 |
| 3 | `_03_soft_delete_column_and_trait_independent` | TC-P03 | Schema | 01–09 |
| 4 | `_04_contact_type_enum_full_ddl_values` | TC-P13 | Schema | 01–09 |
| 5 | `_05_no_unique_indexes_present` | TC-P05 | Schema | 01–09 |
| 6 | `_06_routes_registered` | TC-P14 | Schema/routes | 01–09 |
| 7 | `_07_no_form_request_inline_validation` | TC-P07 | Config/DEV | 01–09 |
| 8 | `_10_create_applies_server_defaults` | TC-P01 | BC-BIZ | 10–19 |
| 9 | `_11_index_grouped_by_contact_type` | TC-P02 | BC-BIZ | 10–19 |
| 10 | `_12_update_changes_fields` | TC-P10 | BC-BIZ | 10–19 |
| 11 | `_13_organization_and_sort_order_not_web_inputs` | TC-P07b | BC-AUTO/DEV | 10–19 |
| 12 | `_14_scope_active_filters_inactive` | TC-P09 | BC-BIZ | 10–19 |
| 13 | `_15_soft_delete_then_restore_lifecycle` | TC-P04a | Lifecycle | 10–19 |
| 14 | `_16_force_delete_removes_row` | TC-P04b | Lifecycle | 10–19 |
| 15 | `_17_toggle_status_flips_is_active` | TC-P06 | BC-BIZ | 10–19 |
| 16 | `_30_missing_contact_name_rejected` | TC-N01 | Validation | 30–39 |
| 17 | `_31_missing_primary_phone_rejected` | TC-N02 | Validation | 30–39 |
| 18 | `_32_missing_created_by_rejected` | TC-N03 | Validation | 30–39 |
| 19 | `_33_invalid_contact_type_rejected` | TC-N04 | Validation | 30–39 |
| 20 | `_34_ddl_extended_enum_accepted_by_db` | TC-D03 | Validation/DEV | 30–39 |
| 21 | `_35_app_validation_omits_extended_enum` | TC-N05 | Validation/DEV | 30–39 |
| 22 | `_36_contact_name_over_length_rejected` | TC-N07 | Validation | 30–39 |
| 23 | `_37_primary_phone_over_length_rejected` | TC-N08 | Validation | 30–39 |
| 24 | `_38_address_over_length_rejected` | TC-N09 | Validation | 30–39 |
| 25 | `_39_max_length_boundary_and_nullables_accepted` | TC-P08 | Validation | 30–39 |
| 26 | `_40_created_by_has_no_fk` | TC-D01 | Dependency | 40–49 |
| 27 | `_41_restore_does_not_recover_hard_deleted` | TC-D02 | Dependency | 40–49 |
| 28 | `_50_controller_gates_present` | TC-S01 | Permissions | 50–59 |
| 29 | `_51_policy_abilities_match` | TC-S02 | Permissions | 50–59 |
| 30 | `_52_guest_redirected_to_login` | TC-S03 | Permissions | 50–59 |
| 31 | `_53_forbidden_without_permission` | TC-S04 | Permissions | 50–59 |
| 32 | `_60_create_page_renders` | TC-P15 | UI | 60–69 |
| 33 | `_61_required_name_ui_rejected` | TC-N10 | UI | 60–69 |
| 34 | `_70_notes_accepts_large_text` | TC-E01 | Edge | 70–79 |
| 35 | `_90_tenant_context_active` | TC-P16 | Tenancy | 90–99 |
| 36 | `_91_xss_payload_stored_raw` | TC-S05 | Security | 90–99 |
| 37 | `_92_toggle_status_nonexistent_returns_404` | TC-N11 | Security | 90–99 |

---

## 5. Manual Test Steps (complex flows only)

Simple CRUD/validation cases are fully specified by the Expected column in §3. Only the lifecycle and the DEV-FOF-EC-001 divergence warrant a stepped script.

### MTS-1 — Soft-delete → restore → force-delete lifecycle (+ activity log)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a contact (Add Contact modal on `/front-office/compliance?tab=emergency`) | Success toast "Emergency contact added."; row visible in its type group |
| 2 | `SELECT is_active,deleted_at FROM fof_emergency_contacts WHERE id=:id` | `is_active=1`, `deleted_at IS NULL` |
| 3 | Click Remove (destroy) | Toast "Emergency contact removed."; row disappears |
| 4 | `SELECT deleted_at FROM fof_emergency_contacts WHERE id=:id` | `deleted_at` set (soft-deleted). **No `sys_activity_logs` row for a 'Deleted' event — DEV-FOF-EC-002** |
| 5 | Open trash (`/front-office/emergency-contacts/trash/view`), Restore | Toast "Emergency Contact restored successfully." |
| 6 | `SELECT event,description FROM sys_activity_logs WHERE ... ORDER BY id DESC LIMIT 1` | One row with event **`Restored`**, message "Emergency Contact restored." |
| 7 | Force delete from trash | Toast "…permanently deleted."; `sys_activity_logs` gains an event **`Deleted`** row |
| 8 | `SELECT COUNT(*) FROM fof_emergency_contacts WHERE id=:id` (incl. trashed) | `0` |

### MTS-2 — DEV-FOF-EC-001 contact_type ENUM divergence
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open the create form; inspect the Type `<select>` | Only 6 options: Hospital, Police, Fire, Transport, Ambulance, Other |
| 2 | `INSERT ... SET contact_type='Government'` directly (DB) | Succeeds — DDL ENUM allows it |
| 3 | POST the store form with `contact_type=Government` (e.g. via crafted request) | **Rejected** by `in:` rule — the 3 DDL members Utility/Parent_Emergency/Government are unreachable via the app (DEV-FOF-EC-001) |

---

## 6. Known Source Defects

| ID | Sev | Summary | Proving method |
|----|-----|---------|----------------|
| DEV-FOF-EC-001 | P2 | `contact_type` validation `in:Hospital,Police,Fire,Transport,Ambulance,Other` is a **subset** of the DDL ENUM — Utility/Parent_Emergency/Government are valid DDL values but rejected by controller + absent from the Blade dropdown. | `_34_ddl_extended_enum_accepted_by_db`, `_35_app_validation_omits_extended_enum` |
| DEV-FOF-EC-002 | P2 | `store()`/`update()`/`destroy()` do **not** call `activityLog()` — only `restore()`='Restored' and `forceDelete()`='Deleted' are logged. Create/edit/soft-delete leave no audit trail (diverges from the module's VisitorController convention). | `_15`, `_16` (source-verify the two logged verbs; MTS-1 steps 4/6/7) |
| DEV-FOF-EC-003 | P1 | No FormRequest — inline `$request->validate()` in the controller (SEC-FOF-003 / D30). No `messages()`, no `authorize()` defense-in-depth. | `_07_no_form_request_inline_validation` |
| DEV-FOF-EC-004 | P3 | `organization` (VARCHAR 150) and `sort_order` are `$fillable` but never accepted by `store()`/`update()` → always NULL / 0 from the web UI (dead columns; `idx_fof_ec_type` grouping is by type only). | `_13_organization_and_sort_order_not_web_inputs` |
| SEC-FOF-003 | P1 | (module-wide, FactPack §6) 10 FormRequests use `authorize(){return true;}` — EmergencyContact has no FormRequest at all, the extreme of the same D30 pattern. | `_07` |
