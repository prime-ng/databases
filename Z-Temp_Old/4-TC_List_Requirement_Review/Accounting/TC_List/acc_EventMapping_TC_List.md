# acc_EventMapping — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Event Mapping

---

## 1. Business Conditions

### 1.1 Database Schema

#### acc_module_events (Event Registry)

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | module_code | varchar(30) | NOT NULL, UPPER_SNAKE_CASE |
| BC-DB-03 | event_code | varchar(60) | NOT NULL, UPPER_SNAKE_CASE, unique per module (with deleted_at) |
| BC-DB-04 | event_name | varchar(150) | NOT NULL |
| BC-DB-05 | description | text | NULLABLE |
| BC-DB-06 | source_model | varchar(100) | NOT NULL |
| BC-DB-07 | is_system | tinyint(1) | DEFAULT 1 (seeded, protected) |
| BC-DB-08 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-09 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-10 | created_at | timestamp | NULLABLE |
| BC-DB-11 | updated_at | timestamp | NULLABLE |
| BC-DB-12 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-13 | UNIQUE KEY uq_acc_me_code | module_code, event_code, deleted_at | Composite unique — soft-delete aware |
| BC-DB-14 | INDEX idx_acc_me_module | module_code | Performance |
| BC-DB-15 | INDEX idx_acc_me_active | is_active | Performance |
| BC-DB-16 | INDEX idx_acc_me_source_model | source_model | Performance |
| BC-DB-17 | ENGINE=InnoDB | — | Transaction support |
| BC-DB-18 | DEFAULT CHARSET=utf8mb4 | — | Unicode support |

#### acc_event_voucher_configs (Voucher Mapping)

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-19 | id | bigint unsigned | PK, auto-increment |
| BC-DB-20 | module_event_id | bigint unsigned | NOT NULL, FK→acc_module_events(id), ON DELETE RESTRICT |
| BC-DB-21 | voucher_type_id | tinyint unsigned | NOT NULL, FK→acc_voucher_types(id), ON DELETE RESTRICT |
| BC-DB-22 | cost_center_id | bigint unsigned | NULLABLE, FK→acc_cost_centers(id), ON DELETE SET NULL |
| BC-DB-23 | is_auto_post | tinyint(1) | DEFAULT 0 |
| BC-DB-24 | requires_approval | tinyint(1) | DEFAULT 0 |
| BC-DB-25 | narration_template | varchar(500) | NULLABLE, supports placeholders |
| BC-DB-26 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-27 | created_by | int unsigned | NULLABLE |
| BC-DB-28 | created_at | timestamp | NULLABLE |
| BC-DB-29 | updated_at | timestamp | NULLABLE |
| BC-DB-30 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-31 | UNIQUE KEY uq_acc_evc_event | module_event_id, deleted_at | One active config per event |
| BC-DB-32 | ENGINE=InnoDB | — | Transaction support |

#### acc_event_voucher_line_templates (Ledger Lines per Config)

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-33 | id | bigint unsigned | PK, auto-increment |
| BC-DB-34 | event_voucher_config_id | bigint unsigned | NOT NULL, FK→acc_event_voucher_configs(id) |
| BC-DB-35 | sequence | tinyint unsigned | DEFAULT 1 |
| BC-DB-36 | entry_type | enum('debit','credit') | NOT NULL |
| BC-DB-37 | ledger_resolver | enum('fixed','student_ledger','vendor_ledger','employee_ledger') | NOT NULL, DEFAULT 'fixed' |
| BC-DB-38 | ledger_id | int unsigned | NULLABLE, FK→acc_ledgers(id), required when resolver=fixed |
| BC-DB-39 | amount_resolver | enum('from_source','fixed_amount','from_payload') | NOT NULL, DEFAULT 'from_source' |
| BC-DB-40 | source_amount_field | varchar(100) | NULLABLE, required when resolver=from_source |
| BC-DB-41 | fixed_amount | decimal(15,2) | NULLABLE, required when resolver=fixed_amount |
| BC-DB-42 | narration | varchar(500) | NULLABLE |
| BC-DB-43 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-44 | created_by | int unsigned | NULLABLE |
| BC-DB-45 | created_at | timestamp | NULLABLE |
| BC-DB-46 | updated_at | timestamp | NULLABLE |
| BC-DB-47 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-48 | ENGINE=InnoDB | — | Transaction support |

**DDL-Level Gaps**

| Gap | Details |
|-----|---------|
| No FK constraint on `created_by` (all 3 tables) | No FOREIGN KEY → `sys_users(id)` at DB level |

### 1.2 Validation Rules

#### ModuleEventRequest

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | module_code | required, string, max:30, regex:/^[A-Z_]+$/ | "Module code must be UPPER_SNAKE_CASE (e.g. LIBRARY, STUDENT_FEE)." |
| BC-VAL-02 | event_code | required, string, max:60, regex:/^[A-Z0-9_]+$/, unique:acc_module_events,event_code ignore current ID whereNull:deleted_at | "Event code must be UPPER_SNAKE_CASE with digits allowed." / "This event code already exists." |
| BC-VAL-03 | event_name | required, string, max:150 | "The Event Name field is required." |
| BC-VAL-04 | source_model | required, string, max:100 | "The Source Model field is required." |
| BC-VAL-05 | description | nullable, string | — |
| BC-VAL-06 | is_active | boolean (nullable) | Default true |

#### EventVoucherConfigRequest

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-07 | voucher_type_id | required, integer, exists:acc_voucher_types,id | "Please select a voucher type." |
| BC-VAL-08 | cost_center_id | nullable, integer, exists:acc_cost_centers,id | — |
| BC-VAL-09 | is_auto_post | boolean (nullable) | — |
| BC-VAL-10 | requires_approval | boolean (nullable) | — |
| BC-VAL-11 | narration_template | nullable, string, max:500 | — |
| BC-VAL-12 | lines | required, array, min:2 | "You must add at least 2 lines (one debit, one credit)." |
| BC-VAL-13 | lines.*.entry_type | required, in:debit,credit | "Each line must have an entry type (debit or credit)." |
| BC-VAL-14 | lines.*.ledger_resolver | required, in:fixed,student_ledger,vendor_ledger,employee_ledger | "Each line must have a ledger resolver." |
| BC-VAL-15 | lines.*.ledger_id | nullable, integer, exists:acc_ledgers,id, required_if:lines.*.ledger_resolver,fixed | "A ledger must be selected when resolver is set to Fixed." |
| BC-VAL-16 | lines.*.amount_resolver | required, in:from_source,fixed_amount,from_payload | "Each line must have an amount resolver." |
| BC-VAL-17 | lines.*.source_amount_field | nullable, string, max:100, required_if:lines.*.amount_resolver,from_source | "Source amount field is required when resolver is set to From Source." |
| BC-VAL-18 | lines.*.fixed_amount | nullable, numeric, min:0, required_if:lines.*.amount_resolver,fixed_amount | "Fixed amount is required when resolver is set to Fixed Amount." |
| BC-VAL-19 | lines.*.narration | nullable, string, max:500 | — |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.module-event.viewAny` | `index()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.module-event.create` | `create()`, `store()` | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.module-event.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.module-event.delete` | `destroy()`, `restore()`, `forceDelete()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.event-voucher-config.create` | `config.create`, `config.store` | Without → 403 |
| BC-AUTH-06 | `tenant.accounting.event-voucher-config.update` | `config.edit`, `config.update` | Without → 403 |
| BC-AUTH-07 | `tenant.accounting.event-voucher-config.delete` | `config.destroy` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | System event protection | `is_system=1` → edit returns 403, delete returns 403, force-delete returns 403 |
| BC-BIZ-02 | System events can be toggled | Even system events can be deactivated/activated via toggle |
| BC-BIZ-03 | Custom event creation sets is_system=0 | Controller forces `is_system=0` on store |
| BC-BIZ-04 | Index redirects to setup-masters | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'event-mapping'])` |
| BC-BIZ-05 | Module code must be UPPER_SNAKE_CASE | Regex validation: only uppercase letters and underscores |
| BC-BIZ-06 | Event code must be UPPER_SNAKE_CASE | Regex validation: only uppercase letters, digits, underscores |
| BC-BIZ-07 | Event code unique per module | Composite unique (module_code + event_code + deleted_at) |
| BC-BIZ-08 | Config requires min 2 lines | At least 2 line templates (one debit, one credit) |
| BC-BIZ-09 | Fixed ledger resolver requires ledger_id | `required_if:lines.*.ledger_resolver,fixed` |
| BC-BIZ-10 | From-source amount resolver requires source field | `required_if:lines.*.amount_resolver,from_source` |
| BC-BIZ-11 | Fixed amount resolver requires amount | `required_if:lines.*.amount_resolver,fixed_amount` |
| BC-BIZ-12 | Config stored in DB transaction | Config + line templates created atomically |
| BC-BIZ-13 | Config update replaces all lines | Old lines soft-deleted, new lines created |
| BC-BIZ-14 | resolveVoucherStatus logic | `requires_approval=true` → draft; `is_auto_post=true` → posted; else → draft |
| BC-BIZ-15 | Config soft-delete | Only config deleted; line templates cascade via FK |
| BC-BIZ-16 | Soft delete sets is_active=false | ModuleEvent: is_active=false before delete |
| BC-BIZ-17 | Restore sets is_active=true | ModuleEvent: is_active=true after restore |
| BC-BIZ-18 | Toggle status via AJAX JSON | Returns `{success: true, is_active, message}` |
| BC-BIZ-19 | List grouped by module_code | Badge header per module, cards sorted under module |
| BC-BIZ-20 | Config status badges | "Configured" (green) with voucher type + auto-post/approval badges; "Not Configured" (gray) |
| BC-BIZ-21 | System badge on system events | Lock icon + "System" badge for is_system=1 |
| BC-BIZ-22 | Edit/Delete only for custom events | Action buttons hidden for system events |
| BC-BIZ-23 | Config actions visible with permission | "Configure" / "Edit Config" / "Remove Config" buttons gated by perms |
| BC-BIZ-24 | Activity log on all operations | Created/Updated/Trashed/Restored/Deleted/Toggled/Configured/Removed |
| BC-BIZ-25 | Empty state | "No Events Found" with migration hint |
| BC-BIZ-26 | Success flash — Event stored | "Event created successfully." |
| BC-BIZ-27 | Success flash — Event updated | "Event updated successfully." |
| BC-BIZ-28 | Success flash — Event trashed | "Event moved to trash." |
| BC-BIZ-29 | Success flash — Event restored | "Event restored successfully." |
| BC-BIZ-30 | Success flash — Event force deleted | "Event permanently deleted." |
| BC-BIZ-31 | Success flash — Config saved | "Voucher config for [event_name] saved successfully." |
| BC-BIZ-32 | Success flash — Config updated | "Voucher config for [event_name] updated successfully." |
| BC-BIZ-33 | Success flash — Config removed | "Voucher config for [event_name] removed." |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Query Criteria | Usage |
|-------|-------------|----------------|-------|
| BC-MOD-01 | ModuleEvent::scopeActive | `where('is_active', true)` | Filter active events |
| BC-MOD-02 | ModuleEvent::scopeByModule($code) | `where('module_code', $code)` | Filter by module |
| BC-MOD-03 | ModuleEvent::scopeSystem | `where('is_system', true)` | Filter system events |
| BC-MOD-04 | ModuleEvent::isConfigured(): bool | `$this->config()->exists()` | Check if mapped |
| BC-MOD-05 | ModuleEvent::isDeletable(): bool | `!$this->is_system` | Only custom deletable |
| BC-MOD-06 | Config::resolveVoucherStatus(): string | `requires_approval?draft: (is_auto_post?posted:draft)` | Determine voucher state |
| BC-MOD-07 | LineTemplate::isDebit() / isCredit() | `$this->entry_type === 'debit'/'credit'` | Entry type check |
| BC-MOD-08 | LineTemplate::usesFixedLedger() / usesDynamicLedger() | `ledger_resolver === 'fixed'` / `!== 'fixed'` | Ledger resolution check |
| BC-MOD-09 | LineTemplate::usesFixedAmount() | `amount_resolver === 'fixed_amount'` | Amount resolution check |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by (all 3) | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-02 | module_event_id | acc_event_voucher_configs | RESTRICT |
| BC-REF-03 | voucher_type_id | acc_voucher_types | RESTRICT |
| BC-REF-04 | cost_center_id | acc_cost_centers | SET NULL |
| BC-REF-05 | event_voucher_config_id | acc_event_voucher_line_templates | CASCADE |

---

## 2. Test Case List

### 2.1 Positive Test Cases — Module Events

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Event List Page Loads (via Setup Masters Tab) | Tab shows module-grouped list with Event name, Source table, Config status badge (Configured/Not Configured), System badge, Status toggle, Actions. | — | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create Custom Event | Redirect + "Event created successfully" flash. DB: is_system=0, created_by set. | — | test_create_custom_event | ✅ |
| TC-P03 | View System Events Listed | System events visible in list with lock icon + "System" badge. No Edit/Delete actions shown. | — | test_system_events_displayed_with_badge | ✅ |
| TC-P04 | Toggle Event Active Status (AJAX) | Click toggle → is_active flips. Works for system events too. | — | test_toggle_active_status | ✅ |
| TC-P05 | Edit Custom Event | Pre-filled form, "Event updated successfully" flash. DB updated. | — | test_edit_custom_event | ✅ |
| TC-P06 | Soft Delete Custom Event | is_active=false, deleted_at set. Redirect + "Event moved to trash." | — | test_soft_delete_custom_event | ✅ |
| TC-P07 | Restore Custom Event | deleted_at cleared, is_active=true. | — | test_restore_custom_event | ✅ |
| TC-P08 | Force Delete Custom Event | Permanently removed from DB. | — | test_force_delete_custom_event | ✅ |
| TC-P09 | Search Events | Search by event_name, event_code, module_code returns results. | — | test_search_events | ✅ |

### 2.2 Positive Test Cases — Voucher Config

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P10 | Configure Event (Create Config) | Config + 2 line templates stored in transaction. "Voucher config saved" flash. Card shows "Configured" with voucher type. | — | test_create_voucher_config_min_2_lines | ✅ |
| TC-P11 | Create Config With 3 Lines | 3 line templates stored with sequential sequence (1, 2, 3). | — | test_create_config_with_multiple_lines | ✅ |
| TC-P12 | Create Config With Auto-Post | is_auto_post=true. resolveVoucherStatus returns 'posted'. "Auto-Post" badge visible. | — | test_create_config_auto_post | ✅ |
| TC-P13 | Create Config With Approval | requires_approval=true. resolveVoucherStatus returns 'draft'. "Approval" badge visible. | — | test_create_config_requires_approval | ✅ |
| TC-P14 | Create Config With Both Auto-Post + Approval | requires_approval overrides → resolveVoucherStatus returns 'draft'. | — | test_create_config_approval_overrides_auto_post | ✅ |
| TC-P15 | Create Config With Cost Center | cost_center_id set. Linked in voucher creation. | — | test_create_config_with_cost_center | ✅ |
| TC-P16 | Create Config With Narration Template | narration_template stored with placeholders: {student_name}, {amount}, etc. | — | test_create_config_with_narration_template | ✅ |
| TC-P17 | Create Config With Fixed Ledger | ledger_resolver=fixed, ledger_id required and stored. | — | test_create_config_fixed_ledger | ✅ |
| TC-P18 | Create Config With Dynamic Ledger Resolver | ledger_resolver=student_ledger/vendor_ledger/employee_ledger, ledger_id null. | — | test_create_config_dynamic_ledger | ✅ |
| TC-P19 | Create Config With From-Source Amount | amount_resolver=from_source, source_amount_field stored. | — | test_create_config_amount_from_source | ✅ |
| TC-P20 | Create Config With Fixed Amount | amount_resolver=fixed_amount, fixed_amount stored. | — | test_create_config_fixed_amount | ✅ |
| TC-P21 | Edit Config (Update) | Old lines soft-deleted, new lines created. "Config updated" flash. | — | test_edit_voucher_config_replaces_lines | ✅ |
| TC-P22 | Remove Config (Soft Delete) | Config soft-deleted. Event reverts to "Not Configured" badge. | — | test_remove_voucher_config | ✅ |

### 2.3 Negative Test Cases

| TC ID | Type | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|------|-------------|----------------|---------|---------|--------|
| TC-N01 | ModuleEvent | Required — Empty Fields | Errors: module_code, event_code, event_name, source_model | — | test_validation_requires_all_fields | ✅ |
| TC-N02 | ModuleEvent | Lowercase module_code | Regex error: must be UPPER_SNAKE_CASE | — | test_validation_lowercase_module_code | ✅ |
| TC-N03 | ModuleEvent | Lowercase event_code | Regex error: must be UPPER_SNAKE_CASE | — | test_validation_lowercase_event_code | ✅ |
| TC-N04 | ModuleEvent | Module code with spaces | Regex error — only A-Z and underscore | — | test_validation_module_code_format | ✅ |
| TC-N05 | ModuleEvent | Duplicate event_code | "This event code already exists." | — | test_validation_duplicate_event_code | ✅ |
| TC-N06 | ModuleEvent | Event code max length (61 chars) | max:60 error | — | test_validation_event_code_max_length | ✅ |
| TC-N07 | ModuleEvent | Edit system event → 403 | 403 Forbidden | — | test_edit_system_event_returns_403 | ✅ |
| TC-N08 | ModuleEvent | Delete system event → 403 | 403 Forbidden | — | test_delete_system_event_returns_403 | ✅ |
| TC-N09 | ModuleEvent | Force delete system event → 403 | 403 Forbidden | — | test_force_delete_system_event_returns_403 | ✅ |
| TC-N10 | ModuleEvent | View invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N11 | ModuleEvent | Permission 403 — No module-event perms | 403 | — | test_permission_denied_returns_403 | ✅ |
| TC-N12 | Config | Empty lines array | "You must add at least 2 lines" | — | test_config_validation_empty_lines | ✅ |
| TC-N13 | Config | Single line (min:2) | "You must add at least 2 lines" | — | test_config_validation_single_line | ✅ |
| TC-N14 | Config | Invalid voucher_type_id | "The selected voucher type is invalid." | — | test_config_validation_invalid_voucher_type | ✅ |
| TC-N15 | Config | Fixed resolver without ledger_id | "A ledger must be selected when resolver is set to Fixed." | — | test_config_validation_fixed_resolver_no_ledger | ✅ |
| TC-N16 | Config | From-source resolver without source_field | "Source amount field is required when resolver is set to From Source." | — | test_config_validation_from_source_no_field | ✅ |
| TC-N17 | Config | Fixed amount resolver without amount | "Fixed amount is required when resolver is set to Fixed Amount." | — | test_config_validation_fixed_amount_no_value | ✅ |
| TC-N18 | Config | Invalid entry_type (not debit/credit) | "Each line must have an entry type (debit or credit)." | — | test_config_validation_invalid_entry_type | ✅ |
| TC-N19 | Config | Invalid ledger_resolver | "Each line must have a ledger resolver." | — | test_config_validation_invalid_ledger_resolver | ✅ |
| TC-N20 | Config | Permission 403 — No event-voucher-config perms | 403 on configure/edit/remove | — | test_config_permission_denied_returns_403 | ✅ |
| TC-N21 | Both | Guest Access Redirect | Redirect to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N22 | Both | Empty Trash Page | "No Data Found" or empty state | — | test_empty_trash_page | ✅ |

### 2.4 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | FK Restrict — Event With Config Cannot Be Deleted | FK constraint on module_event_id prevents event deletion when config exists | — | test_dependency_fk_event_with_config | ⏸️ |
| TC-D02 | B | FK Restrict — Voucher Type Deletion Blocked By Config | FK constraint on voucher_type_id prevents deleting type used by a config | — | test_dependency_fk_voucher_type_in_config | ⏸️ |
| TC-D03 | C | Config Line References Ledger — Ledger Deletion Blocked | FK on ledger_id prevents deleting ledger used in a line template | — | test_dependency_fk_ledger_in_line_template | ⏸️ |

⏸️ = Skipped — requires cross-table FK setup

---

### 2.4 SweetAlert Confirmation Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | Click Edit → SweetAlert shows confirmation → Confirm → edit form opens or operation proceeds | — | test_sweet_alert_edit_confirm | 🔴 |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes record | Click Delete → SweetAlert shows confirmation → Confirm → record soft deleted | — | test_sweet_alert_delete_confirm | 🔴 |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | Click Delete → SweetAlert shows confirmation → Cancel → deletion aborted, no change | — | test_sweet_alert_delete_cancel | 🔴 |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | Click Force Delete → SweetAlert shows "Delete Permanently?" → Confirm → record permanently deleted | — | test_sweet_alert_force_delete_confirm | 🔴 |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | Click Force Delete → SweetAlert shows "Delete Permanently?" → Cancel → deletion aborted | — | test_sweet_alert_force_delete_cancel | 🔴 |
| TC-SW06 | Restore — SweetAlert confirm restores record | Click Restore → SweetAlert shows confirmation → Confirm → record restored | — | test_sweet_alert_restore_confirm | 🔴 |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | Click Restore → SweetAlert shows confirmation → Cancel → restore aborted | — | test_sweet_alert_restore_cancel | 🔴 |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | Click Toggle → SweetAlert shows confirmation → Confirm → status flipped | — | test_sweet_alert_toggle_confirm | 🔴 |

---

## 3. V2 Test Method Index (Proposed)

| # | Method | TC / BC Map | Category |
|---|--------|-------------|----------|
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-48 | Schema |
| 02 | test_model_scopes_and_helpers | BC-MOD-01 to BC-MOD-09 | Schema |
| 03 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 04 | test_create_custom_event | TC-P02, BC-VAL-01/02/03/04/06, BC-BIZ-03 | Positive |
| 05 | test_system_events_displayed_with_badge | TC-P03, BC-BIZ-21 | Positive |
| 06 | test_toggle_active_status | TC-P04, BC-BIZ-02/18 | Positive |
| 07 | test_edit_custom_event | TC-P05, BC-BIZ-27 | Positive |
| 08 | test_soft_delete_custom_event | TC-P06, BC-BIZ-16/28 | Positive |
| 09 | test_restore_custom_event | TC-P07, BC-BIZ-17/29 | Positive |
| 10 | test_force_delete_custom_event | TC-P08, BC-BIZ-30 | Positive |
| 11 | test_search_events | TC-P09 | Positive |
| 12 | test_create_voucher_config_min_2_lines | TC-P10, BC-VAL-07/12, BC-BIZ-08/12/31 | Positive |
| 13 | test_create_config_with_multiple_lines | TC-P11 | Positive |
| 14 | test_create_config_auto_post | TC-P12, BC-VAL-09, BC-BIZ-14 | Positive |
| 15 | test_create_config_requires_approval | TC-P13, BC-VAL-10, BC-BIZ-14 | Positive |
| 16 | test_create_config_approval_overrides_auto_post | TC-P14, BC-BIZ-14 | Positive |
| 17 | test_create_config_with_cost_center | TC-P15, BC-VAL-08 | Positive |
| 18 | test_create_config_with_narration_template | TC-P16, BC-VAL-11 | Positive |
| 19 | test_create_config_fixed_ledger | TC-P17, BC-VAL-14/15 | Positive |
| 20 | test_create_config_dynamic_ledger | TC-P18, BC-VAL-14 | Positive |
| 21 | test_create_config_amount_from_source | TC-P19, BC-VAL-16/17 | Positive |
| 22 | test_create_config_fixed_amount | TC-P20, BC-VAL-18 | Positive |
| 23 | test_edit_voucher_config_replaces_lines | TC-P21, BC-BIZ-13/32 | Positive |
| 24 | test_remove_voucher_config | TC-P22, BC-BIZ-15/33 | Positive |
| 25 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03/04 | Negative |
| 26 | test_validation_lowercase_module_code | TC-N02, BC-VAL-01, BC-BIZ-05 | Negative |
| 27 | test_validation_lowercase_event_code | TC-N03, BC-VAL-02, BC-BIZ-06 | Negative |
| 28 | test_validation_module_code_format | TC-N04, BC-VAL-01 | Negative |
| 29 | test_validation_duplicate_event_code | TC-N05, BC-VAL-02, BC-BIZ-07 | Negative |
| 30 | test_validation_event_code_max_length | TC-N06, BC-VAL-02 | Negative |
| 31 | test_edit_system_event_returns_403 | TC-N07, BC-BIZ-01 | Negative |
| 32 | test_delete_system_event_returns_403 | TC-N08, BC-BIZ-01 | Negative |
| 33 | test_force_delete_system_event_returns_403 | TC-N09, BC-BIZ-01 | Negative |
| 34 | test_invalid_id_returns_404 | TC-N10 | Negative |
| 35 | test_permission_denied_returns_403 | TC-N11, BC-AUTH-01/02/03/04 | Negative |
| 36 | test_config_validation_empty_lines | TC-N12, BC-VAL-12 | Negative |
| 37 | test_config_validation_single_line | TC-N13, BC-VAL-12 | Negative |
| 38 | test_config_validation_invalid_voucher_type | TC-N14, BC-VAL-07 | Negative |
| 39 | test_config_validation_fixed_resolver_no_ledger | TC-N15, BC-VAL-15, BC-BIZ-09 | Negative |
| 40 | test_config_validation_from_source_no_field | TC-N16, BC-VAL-17, BC-BIZ-10 | Negative |
| 41 | test_config_validation_fixed_amount_no_value | TC-N17, BC-VAL-18, BC-BIZ-11 | Negative |
| 42 | test_config_validation_invalid_entry_type | TC-N18, BC-VAL-13 | Negative |
| 43 | test_config_validation_invalid_ledger_resolver | TC-N19, BC-VAL-14 | Negative |
| 44 | test_config_permission_denied_returns_403 | TC-N20, BC-AUTH-05/06/07 | Negative |
| 45 | test_guest_redirect_to_login | TC-N21 | Negative |
| 46 | test_empty_trash_page | TC-N22 | Negative |
| 47 | test_dependency_fk_constraints | TC-D01 to D03 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive — ModuleEvent | 9 | 9 | 0 | 0 | **100%** |
| Positive — VoucherConfig | 13 | 13 | 0 | 0 | **100%** |
| Negative | 22 | 22 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 3 | 0 | 0 | 3 | **0%** |
| **Total** | **55** | **44** | **0** | **11** | **80%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 48 | 48 | 0 | **100%** |
| Validation Rules (BC-VAL) | 19 | 19 | 0 | **100%** |
| Authorization (BC-AUTH) | 7 | 7 | 0 | **100%** |
| Business Logic (BC-BIZ) | 33 | 32 | 1 | **97%** |
| Model Scopes/Helpers (BC-MOD) | 9 | 9 | 0 | **100%** |
| Referential Integrity (BC-REF) | 5 | 2 | 3 | **40%** |
| **Total** | **121** | **117** | **4** | **97%** |

### Coverage Notes
- All 44 positive + negative TCs proposed for V2 coverage
- All BC-DB (48/48), BC-VAL (19/19), BC-AUTH (7/7), BC-MOD (9/9) fully covered
- 32/33 BC-BIZ conditions covered (uncovered: SweetAlert confirmation — pending view)
- 3 dependency TCs (TC-D01 to D03) require cross-table FK constraint testing
- 3 BC-REF conditions require other module setup — skipped

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=event-mapping | setupMasters | viewAny |
| GET | /accounting/event-mapping | event-mapping.index | viewAny |
| POST | /accounting/event-mapping/{moduleEvent}/toggle-status | event-mapping.toggleStatus | update |
| GET | /accounting/event-mapping/create | event-mapping.create | create |
| POST | /accounting/event-mapping | event-mapping.store | create |
| GET | /accounting/event-mapping/trashed | event-mapping.trashed | delete |
| POST | /accounting/event-mapping/{id}/restore | event-mapping.restore | delete |
| DELETE | /accounting/event-mapping/{id}/force-delete | event-mapping.force-delete | delete |
| GET | /accounting/event-mapping/{moduleEvent}/edit | event-mapping.edit | update |
| PUT | /accounting/event-mapping/{moduleEvent} | event-mapping.update | update |
| DELETE | /accounting/event-mapping/{moduleEvent} | event-mapping.destroy | delete |
| GET | /accounting/event-mapping/{moduleEvent}/config/create | event-mapping.config.create | config.create |
| POST | /accounting/event-mapping/{moduleEvent}/config | event-mapping.config.store | config.create |
| GET | /accounting/event-mapping/{moduleEvent}/config/{config}/edit | event-mapping.config.edit | config.update |
| PUT | /accounting/event-mapping/{moduleEvent}/config/{config} | event-mapping.config.update | config.update |
| DELETE | /accounting/event-mapping/{moduleEvent}/config/{config} | event-mapping.config.destroy | config.delete |

---

## 6. Development Issues Found

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-01 | ModuleEventPolicy::delete() | Policy correctly checks is_system, but controller destroy() aborts with 403 independently (redundant check). Controller edit()/update() also abort with 403. Could centralize in policy. | Low | Open |
| DEV-02 | EventVoucherConfigController | Config update calls `lineTemplates()->delete()` which soft-deletes each line template — no hard delete. Over time, many soft-deleted orphan line templates accumulate. | Low | Open |
| DEV-03 | migration (all 3 tables) | `created_by` has no FK constraint to `sys_users` in any of the 3 tables. | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Dual abort (controller + policy) on system event protection — redundant | Open |
| KN-02 | Config update soft-deletes old line templates instead of hard-deleting — orphan accumulation | Open |
| KN-03 | No FK constraint on `created_by` across all 3 event-mapping tables | Open |
