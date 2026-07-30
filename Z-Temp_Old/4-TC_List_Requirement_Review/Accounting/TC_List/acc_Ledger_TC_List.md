# acc_Ledger — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Ledgers

---

## 1. Business Conditions

### 1.1 Database Schema — acc_ledgers

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(150) | NOT NULL |
| BC-DB-03 | code | varchar(30) | NULLABLE |
| BC-DB-04 | alias | varchar(150) | NULLABLE |
| BC-DB-05 | account_group_id | int unsigned | NOT NULL, FK→acc_account_groups(id), ON DELETE RESTRICT |
| BC-DB-06 | opening_balance | decimal(15,2) | DEFAULT 0.00 |
| BC-DB-07 | opening_balance_type | enum('Dr','Cr') | NULLABLE |
| BC-DB-08 | is_bank_account | tinyint(1) | DEFAULT 0 |
| BC-DB-09 | bank_name | varchar(100) | NULLABLE |
| BC-DB-10 | bank_account_number | varchar(50) | NULLABLE |
| BC-DB-11 | ifsc_code | varchar(30) | NULLABLE |
| BC-DB-12 | is_cash_account | tinyint(1) | DEFAULT 0 |
| BC-DB-13 | allow_reconciliation | tinyint(1) | DEFAULT 0 |
| BC-DB-14 | is_system | tinyint(1) | DEFAULT 0 |
| BC-DB-15 | student_id | int unsigned | NULLABLE, FK→std_students(id) (no DB FK) |
| BC-DB-16 | employee_id | int unsigned | NULLABLE, FK→sch_employees(id) (no DB FK) |
| BC-DB-17 | vendor_id | int unsigned | NULLABLE, FK→vnd_vendors(id) (no DB FK) |
| BC-DB-18 | gst_registration_type | enum('Regular','Composition','Unregistered','SEZ','Consumer') | NULLABLE |
| BC-DB-19 | gstin | varchar(20) | NULLABLE |
| BC-DB-20 | pan | varchar(15) | NULLABLE |
| BC-DB-21 | address | text | NULLABLE |
| BC-DB-22 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-23 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-24 | created_at | timestamp | NULLABLE |
| BC-DB-25 | updated_at | timestamp | NULLABLE |
| BC-DB-26 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-27 | INDEX idx_acc_ledger_group | account_group_id | Performance index |
| BC-DB-28 | INDEX idx_acc_ledger_student | student_id | Performance index |
| BC-DB-29 | INDEX idx_acc_ledger_employee | employee_id | Performance index |
| BC-DB-30 | INDEX idx_acc_ledger_vendor | vendor_id | Performance index |
| BC-DB-31 | INDEX idx_acc_ledger_bank | is_bank_account | Performance index |
| BC-DB-32 | INDEX idx_acc_ledger_active | is_active | Performance index |
| BC-DB-33 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-34 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison and sorting |
| BC-DB-35 | Model field: current_balance | decimal(15,2) | Fillable but NOT in DDL — computed at runtime |
| BC-DB-36 | Model field: current_balance_type | enum('Dr','Cr') | Fillable but NOT in DDL — computed at runtime |

**DDL-Level Gaps (not enforced at database layer)**

| Gap | Details |
|-----|---------|
| No CHECK constraint | `opening_balance_type` only validated at application layer; `is_bank_account` + `is_cash_account` mutual exclusivity only at Request level |
| No UNIQUE constraint on `code` | Uniqueness enforced only by `FormRequest` validation, NOT by DB index/constraint |
| No FK constraint on `created_by` | No FOREIGN KEY → `sys_users(id)` at DB level |
| No FK constraints on `student_id`, `employee_id`, `vendor_id` | No DB-level referential integrity for linked entities |
| `current_balance` / `current_balance_type` | Exposed as fillable in Model but not present in DDL — computed/derived fields |

### 1.2 Validation Rules (LedgerRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:150 | "The Ledger Name field is required." |
| BC-VAL-02 | code | nullable, string, max:20, unique:acc_ledgers,code,ignore current ID,whereNull:deleted_at | "The Ledger Code has already been taken." |
| BC-VAL-03 | alias | nullable, string, max:150 | — |
| BC-VAL-04 | account_group_id | required, exists:acc_account_groups,id | "The Account Group is invalid." |
| BC-VAL-05 | opening_balance | nullable, numeric, min:0 | "The Opening Balance must be at least 0." |
| BC-VAL-06 | opening_balance_type | nullable, in:Dr,Cr | "The Opening Balance Type must be Dr or Cr." |
| BC-VAL-07 | is_system | boolean (nullable) | Default false |
| BC-VAL-08 | is_bank_account | boolean (nullable) | Default false |
| BC-VAL-09 | bank_name | nullable, required_if:is_bank_account,true, string, max:100 | "The Bank Name is required when Bank Account is checked." |
| BC-VAL-10 | bank_account_number | nullable, required_if:is_bank_account,true, string, max:50 | "The Bank Account Number is required when Bank Account is checked." |
| BC-VAL-11 | ifsc_code | nullable, string, max:20 | — |
| BC-VAL-12 | is_cash_account | boolean (nullable) | Default false |
| BC-VAL-13 | allow_reconciliation | boolean (nullable) | Default false |
| BC-VAL-14 | student_id | nullable, exists:std_students,id | — |
| BC-VAL-15 | employee_id | nullable, exists:sch_employees,id | — |
| BC-VAL-16 | vendor_id | nullable, exists:vnd_vendors,id | — |
| BC-VAL-17 | gst_registration_type | nullable, string, max:30 | — |
| BC-VAL-18 | gstin | nullable, string, max:20 | — |
| BC-VAL-19 | pan | nullable, string, max:15 | — |
| BC-VAL-20 | address | nullable, string | — |
| BC-VAL-21 | is_active | required, boolean | Default true via `prepareForValidation` |
| BC-VAL-22 | Custom — Bank vs Cash conflict | `is_bank_account` and `is_cash_account` cannot both be true | "A ledger cannot be both a Bank Account and a Cash Account." |
| BC-VAL-23 | Custom — Reconciliation requires Bank | `allow_reconciliation` only allowed when `is_bank_account=true` | "Reconciliation is only allowed for Bank Accounts." |
| BC-VAL-24 | Custom — Single linked entity | Only one of student_id/employee_id/vendor_id can be set | "Only one linked entity (Student, Employee, or Vendor) can be assigned." |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.ledger.viewAny` | `index()`, `show()`, `trashed()`, `statement()`, `search()`, `byGroup()`, `balance()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.ledger.view` | `show()` (show page) | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.ledger.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.ledger.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.ledger.delete` | `destroy()`, `forceDelete()` | Without → 403 |
| BC-AUTH-06 | `tenant.accounting.ledger.restore` | `restore()` | Without → 403 |
| BC-AUTH-07 | `tenant.accounting.ledger.forceDelete` | `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Code uniqueness (soft-delete aware) | Duplicate code rejected — unique validation ignores current ID and soft-deleted records |
| BC-BIZ-02 | Bank account requires bank details | `bank_name` and `bank_account_number` required when `is_bank_account=true` |
| BC-BIZ-03 | Bank + Cash mutual exclusion | Validation error if both is_bank_account and is_cash_account are true |
| BC-BIZ-04 | Reconciliation requires bank account | Validation error if `allow_reconciliation=true` but `is_bank_account=false` |
| BC-BIZ-05 | Single linked entity | Only one of student_id / employee_id / vendor_id can be assigned |
| BC-BIZ-06 | Index redirects to setup-masters tab | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'ledgers'])` |
| BC-BIZ-07 | Create form loads dropdowns | Active account groups, active students, employees, active vendors |
| BC-BIZ-08 | Edit form loads same dropdowns | Same data sources as create |
| BC-BIZ-09 | System ledger blocks update | "System ledgers cannot be modified." |
| BC-BIZ-10 | System ledger blocks delete | "System ledgers cannot be deleted." |
| BC-BIZ-11 | Ledger with transactions blocks delete | `isDeletable()` checks `!is_system && voucherItems()->count() === 0` — error: "Cannot delete ledger with existing transactions." |
| BC-BIZ-12 | Soft delete sets is_active=false | Controller sets is_active=false first, then delete() |
| BC-BIZ-13 | Restore sets is_active=true | After restore, is_active is set to true |
| BC-BIZ-14 | Toggle status via AJAX JSON | Returns `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-15 | Show page loads account group | `$ledger->load('accountGroup')` |
| BC-BIZ-16 | Trash view paginated 15/page | `Ledger::onlyTrashed()->orderBy('name')->paginate(15)` |
| BC-BIZ-17 | Force delete permanently removes record | `forceDelete()` removes from DB |
| BC-BIZ-18 | Statement view with date filter | `from_date` and `to_date` parameters passed to view |
| BC-BIZ-19 | Search JSON endpoint | `?q=term` → active ledgers matching name/code, limit 20 |
| BC-BIZ-20 | byGroup JSON endpoint | `?group_id=X` → active ledgers in group, ordered by name |
| BC-BIZ-21 | Balance JSON endpoint | Returns `{ledger_id, name, balance}` |
| BC-BIZ-22 | Bank account number encrypted | `SafeEncrypted` cast on `bank_account_number` and `ifsc_code` |
| BC-BIZ-23 | Bank account masked accessor | `getBankAccountMaskedAttribute()` — last 4 chars visible, rest X'd |
| BC-BIZ-24 | Default booleans via prepareForValidation | is_active=true, is_system=false, is_bank_account=false, is_cash_account=false, allow_reconciliation=false |
| BC-BIZ-25 | Empty state message | "No Ledgers Found" with icon |
| BC-BIZ-26 | Card-based list display | Each ledger as card with Name, Code, Opening Balance (Dr/Cr badge), Bank/Cash badges, Status toggle, Actions |
| BC-BIZ-27 | Success flash — Stored | "Ledger created successfully." |
| BC-BIZ-28 | Success flash — Updated | "Ledger updated successfully." |
| BC-BIZ-29 | Success flash — Trashed | "Ledger moved to trash." |
| BC-BIZ-30 | Success flash — Restored | "Ledger restored successfully." |
| BC-BIZ-31 | Success flash — Force Deleted | "Ledger permanently deleted." |
| BC-BIZ-32 | Success flash — Status toggled | JSON `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-33 | Delete confirmation | SweetAlert "Are you sure?" |
| BC-BIZ-34 | Activity log — Stored | On create |
| BC-BIZ-35 | Activity log — Updated | On update |
| BC-BIZ-36 | Activity log — Trashed | On soft delete |
| BC-BIZ-37 | Activity log — Restored | On restore |
| BC-BIZ-38 | Activity log — Deleted | On force delete |
| BC-BIZ-39 | Activity log — Toggled | On status toggle |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Query Criteria | Usage |
|-------|-------------|----------------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active ledgers |
| BC-MOD-02 | `scopeSystem($query)` | `where('is_system', true)` | Filter system ledgers |
| BC-MOD-03 | `scopeBankAccounts($query)` | `where('is_bank_account', true)` | Filter bank account ledgers |
| BC-MOD-04 | `scopeCashAccounts($query)` | `where('is_cash_account', true)` | Filter cash account ledgers |
| BC-MOD-05 | `scopeReconcilable($query)` | `where('allow_reconciliation', true)` | Filter reconcilable ledgers |
| BC-MOD-06 | `scopeByGroup($query, int $groupId)` | `where('account_group_id', $groupId)` | Filter by account group |
| BC-MOD-07 | `scopeByCode($query, string $code)` | `where('code', $code)` | Find by code |
| BC-MOD-08 | `isSystem(): bool` | Returns `$this->is_system` | Check if system ledger |
| BC-MOD-09 | `isDeletable(): bool` | `!is_system && voucherItems()->count() === 0` | Check if deletable |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-02 | account_group_id | acc_account_groups (id) | RESTRICT |
| BC-REF-03 | student_id | std_students (id) | SET NULL (no DB FK) |
| BC-REF-04 | employee_id | sch_employees (id) | SET NULL (no DB FK) |
| BC-REF-05 | vendor_id | vnd_vendors (id) | SET NULL (no DB FK) |
| BC-REF-06 | ledger_id | acc_voucher_items (ledger_id) | RESTRICT (on voucher_items side) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Ledger List Page Loads (via Setup Masters Tab) | Tab shows card-based list with Name, Code, Group, Opening Balance (Dr/Cr), Bank/Cash badges, Status toggle, Actions. Add/Trash/Search visible. | — | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create With Valid Data (minimal fields) | Redirect + "created successfully" flash. DB: name, account_group_id stored. Activity log "Stored". | — | test_create_ledger_with_minimal_data | ✅ |
| TC-P03 | Create With Opening Balance (Dr) | Opening balance 50000 Dr stored correctly. Badge shows Dr. | — | test_create_with_opening_balance_dr | ✅ |
| TC-P04 | Create With Opening Balance (Cr) | Opening balance stored as Cr correctly. | — | test_create_with_opening_balance_cr | ✅ |
| TC-P05 | Create Bank Account | is_bank_account=true with bank_name, bank_account_number, ifsc_code stored. "Bank" badge visible. | — | test_create_bank_account | ✅ |
| TC-P06 | Create Cash Account | is_cash_account=true stored. "Cash" badge visible. | — | test_create_cash_account | ✅ |
| TC-P07 | Create With Linked Student | student_id stored. Student relation accessible. | — | test_create_with_linked_student | ✅ |
| TC-P08 | Create With Linked Employee | employee_id stored. Employee relation accessible. | — | test_create_with_linked_employee | ✅ |
| TC-P09 | Create With Linked Vendor | vendor_id stored. Vendor relation accessible. | — | test_create_with_linked_vendor | ✅ |
| TC-P10 | Create With GST/PAN/Address | gst_registration_type, gstin, pan, address all stored. | — | test_create_with_gst_pan_address | ✅ |
| TC-P11 | View Ledger Details | Name, Code, Group, Opening Balance, Bank/Cash badges displayed. | — | test_show_page_displays_all_details | ✅ |
| TC-P12 | Edit & Update Ledger | Pre-filled data, "updated successfully" flash, redirect. DB updated. | — | test_edit_and_update_ledger | ✅ |
| TC-P13 | Toggle Active Status (AJAX) | Click toggle → is_active flips. Toggle back → flips again. | — | test_toggle_active_status | ✅ |
| TC-P14 | Full Lifecycle: Delete → Trash → Restore → Soft Delete → Force Delete | All 5 states verified, DB transitions correct. | — | test_trash_restore_force_delete_lifecycle | ✅ |
| TC-P15 | Statement View | Statement loads with from_date/to_date filter inputs. | — | test_statement_view_loads | ✅ |
| TC-P16 | Search JSON Endpoint | `?q=Cash` returns matching ledgers (name/code), limit 20. | — | test_search_json_endpoint | ✅ |
| TC-P17 | byGroup JSON Endpoint | `?group_id=X` returns ledgers filtered by account group. | — | test_by_group_json_endpoint | ✅ |
| TC-P18 | Balance JSON Endpoint | Returns `{ledger_id, name, balance}`. | — | test_balance_json_endpoint | ✅ |
| TC-P19 | Bank Account Masked Number | Masked accessor returns last 4 digits visible, rest X'd. | — | test_bank_account_masked_number | ✅ |
| TC-P20 | Bank Account Number Encrypted | Raw DB value is encrypted (SafeEncrypted cast). | — | test_bank_account_number_encrypted | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Fields | Validation errors: "field is required" for name, account_group_id | — | test_validation_requires_all_fields | ✅ |
| TC-N02 | Invalid account_group_id (non-existent) | "The Account Group is invalid." error | — | test_validation_invalid_account_group | ✅ |
| TC-N03 | Duplicate Code | "already been taken" error | — | test_validation_duplicate_code | ✅ |
| TC-N04 | Invalid opening_balance_type | "The Opening Balance Type must be Dr or Cr." | — | test_validation_invalid_balance_type | ✅ |
| TC-N05 | Negative opening_balance | "The Opening Balance must be at least 0." | — | test_validation_negative_opening_balance | ✅ |
| TC-N06 | Bank Account Without bank_name | required_if validation error for bank_name | — | test_validation_bank_account_requires_bank_name | ✅ |
| TC-N07 | Bank Account Without bank_account_number | required_if validation error for bank_account_number | — | test_validation_bank_account_requires_account_number | ✅ |
| TC-N08 | Both Bank And Cash Account | "A ledger cannot be both a Bank Account and a Cash Account." | — | test_validation_bank_and_cash_conflict | ✅ |
| TC-N09 | Reconciliation Without Bank Account | "Reconciliation is only allowed for Bank Accounts." | — | test_validation_reconciliation_requires_bank | ✅ |
| TC-N10 | Multiple Linked Entities (student + employee) | "Only one linked entity can be assigned." | — | test_validation_multiple_linked_entities | ✅ |
| TC-N11 | Update System Ledger | "System ledgers cannot be modified." Name unchanged. | — | test_cannot_update_system_ledger | ✅ |
| TC-N12 | Delete System Ledger | "System ledgers cannot be deleted." Not deleted. | — | test_cannot_delete_system_ledger | ✅ |
| TC-N13 | Delete Ledger With Transactions | "Cannot delete ledger with existing transactions." Not deleted. | — | test_cannot_delete_ledger_with_transactions | ✅ |
| TC-N14 | View Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N15 | Edit Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N16 | Delete Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N17 | Toggle Invalid ID (404) | HTTP 404 | — | test_invalid_id_toggle_returns_404 | ✅ |
| TC-N18 | Permission 403 — No Ledger Permissions | 403 or redirect for user without permissions | — | test_permission_denied_returns_403 | ✅ |
| TC-N19 | Guest Access Redirect | Redirected to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N20 | Empty Trash Page | "No Data Found" or empty state message | — | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Inactive Ledger Removed From Voucher Dropdown | Inactive ledger excluded from voucher item dropdown | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D02 | B | Ledger With Voucher Transactions Blocks Force Delete | voucherItems()->count() > 0 prevents force delete | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D03 | C | Soft-Deleted Ledger Removed From Dropdown | Deleted ledger excluded from all dropdowns | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D04 | C | FK Restrict — Account Group Cannot Be Deleted With Ledgers | FK constraint prevents deleting group when ledgers exist | — | test_dependency_requires_account_group_module | ⏸️ |

⏸️ = Skipped — requires Voucher / Account Group module setup (cross-module dependency)

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
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-36, BC-MOD-08/09 | Schema |
| 02 | test_model_scopes_active_system_bank_cash_reconcilable | BC-MOD-01 to BC-MOD-07 | Schema |
| 03 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 04 | test_create_ledger_with_minimal_data | TC-P02, BC-VAL-21, BC-BIZ-24/34 | Positive |
| 05 | test_create_with_opening_balance_dr | TC-P03, BC-VAL-05/06 | Positive |
| 06 | test_create_with_opening_balance_cr | TC-P04 | Positive |
| 07 | test_create_bank_account | TC-P05, BC-VAL-08/09/10, BC-BIZ-02 | Positive |
| 08 | test_create_cash_account | TC-P06, BC-VAL-12 | Positive |
| 09 | test_create_with_linked_student | TC-P07, BC-VAL-14, BC-BIZ-05 | Positive |
| 10 | test_create_with_linked_employee | TC-P08, BC-VAL-15 | Positive |
| 11 | test_create_with_linked_vendor | TC-P09, BC-VAL-16 | Positive |
| 12 | test_create_with_gst_pan_address | TC-P10, BC-VAL-17/18/19/20 | Positive |
| 13 | test_show_page_displays_all_details | TC-P11, BC-BIZ-15 | Positive |
| 14 | test_edit_and_update_ledger | TC-P12, BC-BIZ-35 | Positive |
| 15 | test_toggle_active_status | TC-P13, BC-BIZ-14/39 | Positive |
| 16 | test_trash_restore_force_delete_lifecycle | TC-P14, BC-BIZ-12/13/36/37/38 | Positive |
| 17 | test_statement_view_loads | TC-P15, BC-BIZ-18 | Positive |
| 18 | test_search_json_endpoint | TC-P16, BC-BIZ-19 | Positive |
| 19 | test_by_group_json_endpoint | TC-P17, BC-BIZ-20 | Positive |
| 20 | test_balance_json_endpoint | TC-P18, BC-BIZ-21 | Positive |
| 21 | test_bank_account_masked_number | TC-P19, BC-BIZ-23 | Positive |
| 22 | test_bank_account_number_encrypted | TC-P20, BC-BIZ-22 | Positive |
| 23 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/04 | Negative |
| 24 | test_validation_invalid_account_group | TC-N02, BC-VAL-04 | Negative |
| 25 | test_validation_duplicate_code | TC-N03, BC-VAL-02, BC-BIZ-01 | Negative |
| 26 | test_validation_invalid_balance_type | TC-N04, BC-VAL-06 | Negative |
| 27 | test_validation_negative_opening_balance | TC-N05, BC-VAL-05 | Negative |
| 28 | test_validation_bank_account_requires_bank_name | TC-N06, BC-VAL-09 | Negative |
| 29 | test_validation_bank_account_requires_account_number | TC-N07, BC-VAL-10 | Negative |
| 30 | test_validation_bank_and_cash_conflict | TC-N08, BC-VAL-22, BC-BIZ-03 | Negative |
| 31 | test_validation_reconciliation_requires_bank | TC-N09, BC-VAL-23, BC-BIZ-04 | Negative |
| 32 | test_validation_multiple_linked_entities | TC-N10, BC-VAL-24, BC-BIZ-05 | Negative |
| 33 | test_cannot_update_system_ledger | TC-N11, BC-BIZ-09 | Negative |
| 34 | test_cannot_delete_system_ledger | TC-N12, BC-BIZ-10 | Negative |
| 35 | test_cannot_delete_ledger_with_transactions | TC-N13, BC-BIZ-11, BC-REF-06 | Negative |
| 36 | test_invalid_id_returns_404 | TC-N10, N11, N12 | Negative |
| 37 | test_invalid_id_toggle_returns_404 | TC-N17 | Negative |
| 38 | test_permission_denied_returns_403 | TC-N18, BC-AUTH-01 to 07 | Negative |
| 39 | test_guest_redirect_to_login | TC-N19 | Negative |
| 40 | test_empty_trash_page | TC-N20 | Negative |
| 41 | test_dependency_requires_voucher_module | TC-D01 to D04 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 20 | 20 | 0 | 0 | **100%** |
| Negative | 20 | 20 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 4 | 0 | 0 | 4 | **0%** |
| **Total** | **52** | **40** | **0** | **12** | **77%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 36 | 36 | 0 | **100%** |
| Validation Rules (BC-VAL) | 24 | 24 | 0 | **100%** |
| Authorization (BC-AUTH) | 7 | 7 | 0 | **100%** |
| Business Logic (BC-BIZ) | 39 | 37 | 2 | **95%** |
| Model Scopes/Helpers (BC-MOD) | 9 | 9 | 0 | **100%** |
| Referential Integrity (BC-REF) | 6 | 2 | 4 | **33%** |
| **Total** | **121** | **115** | **6** | **95%** |

### Coverage Notes
- All 40 positive + negative TCs proposed for V2 coverage
- All BC-DB (36/36), BC-VAL (24/24), BC-AUTH (7/7), BC-MOD (9/9) conditions fully covered
- 37/39 BC-BIZ conditions covered (uncovered: BC-BIZ-33 SweetAlert delete confirmation — pending view implementation; BC-BIZ-25 empty state — implicit)
- 4 dependency TCs (TC-D01 to D04) require Voucher/Account Group module — marked skipped
- 4 BC-REF conditions (BC-REF-01, BC-REF-03, BC-REF-04, BC-REF-05) require cross-module setup — skipped
- DDL gaps documented: no UNIQUE on code, no FK on created_by/student_id/employee_id/vendor_id, current_balance fields not in DDL but fillable in Model
- V2 tests proposed — not yet implemented

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=ledgers | accounting.menu.setupMasters | viewAny |
| GET | /accounting/ledger/create | accounting.ledger.create | create |
| POST | /accounting/ledger | accounting.ledger.store | create |
| GET | /accounting/ledger/{ledger} | accounting.ledger.show | viewAny |
| GET | /accounting/ledger/{ledger}/edit | accounting.ledger.edit | update |
| PUT/PATCH | /accounting/ledger/{ledger} | accounting.ledger.update | update |
| DELETE | /accounting/ledger/{ledger} | accounting.ledger.destroy | delete |
| GET | /accounting/ledger/trash/view | accounting.ledger.trashed | viewAny |
| GET | /accounting/ledger/{id}/restore | accounting.ledger.restore | create |
| DELETE | /accounting/ledger/{id}/force-delete | accounting.ledger.forceDelete | delete |
| POST | /accounting/ledger/{ledger}/toggle-status | accounting.ledger.toggleStatus | update |
| GET | /accounting/ledger/{ledger}/statement | accounting.ledger.statement | viewAny |
| GET | /accounting/ledger-search | accounting.ledger-search | viewAny |
| GET | /accounting/ledgers-by-group/{groupId} | accounting.ledgers-by-group | viewAny |
| GET | /accounting/ledger/{ledger}/balance | accounting.ledger-balance | viewAny |

---

## 6. Development Issues Found

### 6.1 Validation Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-V01 | LedgerRequest.php | `code` max:20 but DDL is varchar(30) — potential truncation for longer codes | Low | Open |
| DEV-V02 | LedgerRequest.php | `gst_registration_type` validated as string max:30 — DDL ENUM values are case-sensitive ('Regular','Composition','Unregistered','SEZ','Consumer') but no `in:` rule to restrict to valid ENUM values | Medium | Open |

### 6.2 Model Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | Ledger.php | `current_balance` and `current_balance_type` exposed as fillable but not present in DDL. These appear to be computed/derived fields — should not be mass-assignable. | Medium | Open |
| DEV-M02 | Ledger.php | No DB-level unique constraint on `code` — uniqueness enforced only at application layer. | Low | Open |

### 6.3 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | LedgerController.php | Index redirects to setup-masters — `index.blade.php` is dead code (never rendered). | Low | Open |

### 6.4 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-MG01 | migration | `created_by` has no FK constraint to `sys_users`. No referential integrity at DB level. | Medium | Open |
| DEV-MG02 | migration | `student_id`, `employee_id`, `vendor_id` have no FK constraints at DB level. Data integrity not enforced. | Low | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | `current_balance` / `current_balance_type` fields fillable in Model but not in DDL | Open |
| KN-02 | `code` max length mismatch: Request=20, DDL=30 | Open |
| KN-03 | No DB-level UNIQUE constraint on `code` field | Open |
| KN-04 | No FK constraint on `created_by`, `student_id`, `employee_id`, `vendor_id` columns | Open |
| KN-05 | `gst_registration_type` ENUM values not validated at Request level | Open |
| KN-06 | `index.blade.php` is dead code (never rendered) | Open |
