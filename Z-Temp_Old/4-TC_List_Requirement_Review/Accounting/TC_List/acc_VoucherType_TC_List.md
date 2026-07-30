# acc_VoucherType — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Voucher Types

---

## 1. Business Conditions

### 1.1 Database Schema — acc_voucher_types

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | tinyint unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(80) | NOT NULL |
| BC-DB-03 | code | varchar(20) | NOT NULL, UNIQUE (uq_acc_vt_code with deleted_at) |
| BC-DB-04 | voucher_category_id | tinyint unsigned | NOT NULL, FK→acc_voucher_category(id), ON DELETE RESTRICT |
| BC-DB-05 | prefix | varchar(5) | NULLABLE |
| BC-DB-06 | auto_numbering | tinyint(1) | DEFAULT 1 |
| BC-DB-07 | last_number | int | DEFAULT 0 |
| BC-DB-08 | is_system | tinyint(1) | DEFAULT 0 |
| BC-DB-09 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-10 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-11 | created_at | timestamp | NULLABLE |
| BC-DB-12 | updated_at | timestamp | NULLABLE |
| BC-DB-13 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-14 | INDEX idx_acc_vt_category | voucher_category_id | Performance index |
| BC-DB-15 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-16 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison and sorting |
| BC-DB-17 | UNIQUE KEY uq_acc_vt_code | code, deleted_at | Composite unique — allows soft-deleted duplicates |

**DDL-Level Gaps (not enforced at database layer)**

| Gap | Details |
|-----|---------|
| ⚠️ **Model/DDL mismatch** | DDL has `voucher_category_id` (FK→acc_voucher_category), but Model uses `category` (string enum: accounting/inventory/payroll/order). These are incompatible — Model field name does not match DDL column name. |
| No CHECK constraint | `auto_numbering` boolean only at application layer |
| No FK constraint on `created_by` | No FOREIGN KEY → `sys_users(id)` at DB level |

### 1.2 Validation Rules (VoucherTypeRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:80 | "The Voucher Type Name field is required." |
| BC-VAL-02 | code | required, string, max:20, unique:acc_voucher_types,code,ignore current ID,whereNull:deleted_at | "The Voucher Type Code has already been taken." |
| BC-VAL-03 | category | required, in:accounting,inventory,payroll,order | "The Category is invalid." |
| BC-VAL-04 | prefix | nullable, string, max:5 | — |
| BC-VAL-05 | auto_numbering | boolean (nullable) | Default true via `prepareForValidation` |
| BC-VAL-06 | is_system | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-07 | is_active | required, boolean | Default true via `prepareForValidation` |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.voucher-type.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.voucher-type.view` | `show()` (show page) | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.voucher-type.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.voucher-type.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.voucher-type.delete` | `destroy()`, `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Code uniqueness (soft-delete aware) | Duplicate code rejected — unique validation ignores current ID and soft-deleted records |
| BC-BIZ-02 | Category must be valid enum | Only accounting/inventory/payroll/order allowed |
| BC-BIZ-03 | Category uppercased on store/update | `strtoupper()` applied to category — stored as ACCOUNTING, INVENTORY, etc. |
| BC-BIZ-04 | Index redirects to setup-masters tab | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'voucher-types'])` |
| BC-BIZ-05 | Default booleans via prepareForValidation | is_active=true, is_system=false, auto_numbering=true |
| BC-BIZ-06 | System type blocks update | "System voucher types cannot be modified." |
| BC-BIZ-07 | System type blocks delete | "System voucher types cannot be deleted." |
| BC-BIZ-08 | Type with existing vouchers blocks delete | `isDeletable()` checks `!is_system && vouchers()->count() === 0` — error: "Cannot delete voucher type with existing vouchers." |
| BC-BIZ-09 | Soft delete sets is_active=false | Controller sets is_active=false first, then delete() |
| BC-BIZ-10 | Restore sets is_active=true | After restore, is_active is set to true |
| BC-BIZ-11 | Toggle status via AJAX JSON | Returns `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-12 | Trash view paginated 15/page | `VoucherType::onlyTrashed()->orderBy('name')->paginate(15)` |
| BC-BIZ-13 | Force delete permanently removes record | `forceDelete()` removes from DB |
| BC-BIZ-14 | Card-based list with category color coding | Each type as card with left border color per category (journal=blue, receipt=green, payment=red, contra=orange, sales=info, purchase=gray) |
| BC-BIZ-15 | Category badge on card | Badge with category-specific color and formatted name (underscores→spaces) |
| BC-BIZ-16 | System badge on card | `is_system` types show dark "System" badge |
| BC-BIZ-17 | Prefix & numbering display | Shows prefix (or dash) + "Auto" badge if auto_numbering=true |
| BC-BIZ-18 | Empty state message | "No Voucher Types Found" with icon |
| BC-BIZ-19 | Success flash — Stored | "Voucher Type created successfully." |
| BC-BIZ-20 | Success flash — Updated | "Voucher Type updated successfully." |
| BC-BIZ-21 | Success flash — Trashed | "Voucher Type moved to trash." |
| BC-BIZ-22 | Success flash — Restored | "Voucher Type restored successfully." |
| BC-BIZ-23 | Success flash — Force Deleted | "Voucher Type permanently deleted." |
| BC-BIZ-24 | Success flash — Status toggled | JSON `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-25 | Delete confirmation | SweetAlert "Are you sure?" |
| BC-BIZ-26 | Activity log — Stored | On create |
| BC-BIZ-27 | Activity log — Updated | On update |
| BC-BIZ-28 | Activity log — Trashed | On soft delete |
| BC-BIZ-29 | Activity log — Restored | On restore |
| BC-BIZ-30 | Activity log — Deleted | On force delete |
| BC-BIZ-31 | Activity log — Toggled | On status toggle |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Query Criteria | Usage |
|-------|-------------|----------------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active types |
| BC-MOD-02 | `scopeSystem($query)` | `where('is_system', true)` | Filter system types |
| BC-MOD-03 | `scopeByCategory($query, $category)` | `where('category', $category)` | Filter by category |
| BC-MOD-04 | `scopeByCode($query, $code)` | `where('code', $code)` | Find by code |
| BC-MOD-05 | `isSystem(): bool` | Returns `$this->is_system` | Check if system type |
| BC-MOD-06 | `isDeletable(): bool` | `!is_system && vouchers()->count() === 0` | Check if deletable |
| BC-MOD-07 | `categories(): array` | Returns `['accounting','inventory','payroll','order']` | Available categories |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-02 | voucher_category_id | acc_voucher_category (id) | RESTRICT |
| BC-REF-03 | voucher_type_id | acc_vouchers (voucher_type_id) | RESTRICT (on voucher side) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Voucher Type List Page Loads (via Setup Masters Tab) | Tab shows card-based list with Name, Category badge, Code, Prefix, Auto badge, System badge, Status toggle, Actions. Add/Trash/Search visible. | — | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create With Valid Data (accounting category) | Redirect + "created successfully" flash. DB: name, code, category=ACCOUNTING stored. Activity log "Stored". | — | test_create_voucher_type_accounting | ✅ |
| TC-P03 | Create With inventory Category | Category stored as INVENTORY after strtoupper. | — | test_create_voucher_type_inventory | ✅ |
| TC-P04 | Create With payroll Category | Category stored as PAYROLL. | — | test_create_voucher_type_payroll | ✅ |
| TC-P05 | Create With order Category | Category stored as ORDER. | — | test_create_voucher_type_order | ✅ |
| TC-P06 | Create With Prefix | Prefix stored (e.g., "PMT/"). Displayed on card. | — | test_create_with_prefix | ✅ |
| TC-P07 | Create With auto_numbering Disabled | auto_numbering=false stored. "Auto" badge hidden on card. | — | test_create_with_auto_numbering_disabled | ✅ |
| TC-P08 | Create With last_number | last_number stored (e.g., 100). Counter starts from this value. | — | test_create_with_last_number | ✅ |
| TC-P09 | View Voucher Type Details | Name, Code, Category, Prefix, Auto-numbering status, System badge displayed. | — | test_show_page_displays_all_details | ✅ |
| TC-P10 | Edit & Update Voucher Type | Pre-filled data, "updated successfully" flash, redirect. DB updated. | — | test_edit_and_update_voucher_type | ✅ |
| TC-P11 | Toggle Active Status (AJAX) | Click toggle → is_active flips. Toggle back → flips again. | — | test_toggle_active_status | ✅ |
| TC-P12 | Full Lifecycle: Delete → Trash → Restore → Soft Delete → Force Delete | All 5 states verified, DB transitions correct. | — | test_trash_restore_force_delete_lifecycle | ✅ |
| TC-P13 | Category Card Border Colors | Correct left border color per category type. | — | test_category_card_border_colors | ✅ |
| TC-P14 | Category Badge Colors | Correct badge color per category. | — | test_category_badge_colors | ✅ |
| TC-P15 | System Badge Visible | Types with is_system=true show "System" badge. | — | test_system_badge_visible | ✅ |
| TC-P16 | Search Voucher Types | Search by name/code returns matching results. | — | test_search_voucher_types | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Fields | Validation errors: "field is required" for name, code, category | — | test_validation_requires_all_fields | ✅ |
| TC-N02 | Duplicate Code | "already been taken" error | — | test_validation_duplicate_code | ✅ |
| TC-N03 | Invalid Category | "The Category is invalid." — only accounting/inventory/payroll/order allowed | — | test_validation_invalid_category | ✅ |
| TC-N04 | Code Max Length (21 chars) | Validation error (max:20) | — | test_validation_code_max_length | ✅ |
| TC-N05 | Prefix Max Length (6 chars) | Validation error (max:5) | — | test_validation_prefix_max_length | ✅ |
| TC-N06 | Edit — Duplicate Code | "already been taken" on update. Original preserved. | — | test_edit_duplicate_code | ✅ |
| TC-N07 | Update System Type | "System voucher types cannot be modified." Name unchanged. | — | test_cannot_update_system_type | ✅ |
| TC-N08 | Delete System Type | "System voucher types cannot be deleted." Not deleted. | — | test_cannot_delete_system_type | ✅ |
| TC-N09 | Delete Type With Vouchers | "Cannot delete voucher type with existing vouchers." Not deleted. | — | test_cannot_delete_type_with_vouchers | ✅ |
| TC-N10 | View Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N11 | Edit Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N12 | Delete Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N13 | Toggle Invalid ID (404) | HTTP 404 | — | test_invalid_id_toggle_returns_404 | ✅ |
| TC-N14 | Permission 403 — No Voucher Type Permissions | 403 or redirect for user without permissions | — | test_permission_denied_returns_403 | ✅ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N16 | Empty Trash Page | "No Data Found" or empty state message | — | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Inactive Type Removed From Voucher Dropdown | Inactive type excluded from voucher creation dropdown | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D02 | B | Type With Voucher Transactions Blocks Force Delete | vouchers()->count() > 0 prevents force delete | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D03 | C | Soft-Deleted Type Removed From Dropdown | Deleted type excluded from all dropdowns | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D04 | C | FK Restrict — Cannot Delete Voucher Category With Types | FK constraint prevents deleting category when types exist | — | test_dependency_requires_voucher_category_module | ⏸️ |

⏸️ = Skipped — requires Voucher / Voucher Category module setup (cross-module dependency)

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
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-17, BC-MOD-05/06/07 | Schema |
| 02 | test_model_scopes_active_system_byCategory_byCode | BC-MOD-01 to BC-MOD-04 | Schema |
| 03 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 04 | test_create_voucher_type_accounting | TC-P02, BC-VAL-05/06/07, BC-BIZ-03/05/26 | Positive |
| 05 | test_create_voucher_type_inventory | TC-P03 | Positive |
| 06 | test_create_voucher_type_payroll | TC-P04 | Positive |
| 07 | test_create_voucher_type_order | TC-P05 | Positive |
| 08 | test_create_with_prefix | TC-P06, BC-VAL-04 | Positive |
| 09 | test_create_with_auto_numbering_disabled | TC-P07, BC-VAL-05 | Positive |
| 10 | test_create_with_last_number | TC-P08 | Positive |
| 11 | test_show_page_displays_all_details | TC-P09 | Positive |
| 12 | test_edit_and_update_voucher_type | TC-P10, BC-BIZ-27 | Positive |
| 13 | test_toggle_active_status | TC-P11, BC-BIZ-11/31 | Positive |
| 14 | test_trash_restore_force_delete_lifecycle | TC-P12, BC-BIZ-09/10/28/29/30 | Positive |
| 15 | test_category_card_border_colors | TC-P13, BC-BIZ-14 | Positive |
| 16 | test_category_badge_colors | TC-P14, BC-BIZ-15 | Positive |
| 17 | test_system_badge_visible | TC-P15, BC-BIZ-16 | Positive |
| 18 | test_search_voucher_types | TC-P16 | Positive |
| 19 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03 | Negative |
| 20 | test_validation_duplicate_code | TC-N02, BC-VAL-02, BC-BIZ-01 | Negative |
| 21 | test_validation_invalid_category | TC-N03, BC-VAL-03, BC-BIZ-02 | Negative |
| 22 | test_validation_code_max_length | TC-N04, BC-VAL-02 | Negative |
| 23 | test_validation_prefix_max_length | TC-N05, BC-VAL-04 | Negative |
| 24 | test_edit_duplicate_code | TC-N06, BC-VAL-02, BC-BIZ-01 | Negative |
| 25 | test_cannot_update_system_type | TC-N07, BC-BIZ-06 | Negative |
| 26 | test_cannot_delete_system_type | TC-N08, BC-BIZ-07 | Negative |
| 27 | test_cannot_delete_type_with_vouchers | TC-N09, BC-BIZ-08, BC-REF-03 | Negative |
| 28 | test_invalid_id_returns_404 | TC-N10, N11, N12 | Negative |
| 29 | test_invalid_id_toggle_returns_404 | TC-N13 | Negative |
| 30 | test_permission_denied_returns_403 | TC-N14, BC-AUTH-01 to 05 | Negative |
| 31 | test_guest_redirect_to_login | TC-N15 | Negative |
| 32 | test_empty_trash_page | TC-N16 | Negative |
| 33 | test_dependency_requires_voucher_module | TC-D01 to D04 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 16 | 16 | 0 | 0 | **100%** |
| Negative | 16 | 16 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 4 | 0 | 0 | 4 | **0%** |
| **Total** | **44** | **32** | **0** | **12** | **73%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 17 | 17 | 0 | **100%** |
| Validation Rules (BC-VAL) | 7 | 7 | 0 | **100%** |
| Authorization (BC-AUTH) | 5 | 5 | 0 | **100%** |
| Business Logic (BC-BIZ) | 31 | 30 | 1 | **97%** |
| Model Scopes/Helpers (BC-MOD) | 7 | 7 | 0 | **100%** |
| Referential Integrity (BC-REF) | 3 | 1 | 2 | **33%** |
| **Total** | **70** | **67** | **3** | **96%** |

### Coverage Notes
- All 32 positive + negative TCs proposed for V2 coverage
- All BC-DB (17/17), BC-VAL (7/7), BC-AUTH (5/5), BC-MOD (7/7) conditions fully covered
- 30/31 BC-BIZ conditions covered (uncovered: BC-BIZ-25 SweetAlert delete confirmation — pending view implementation)
- 4 dependency TCs (TC-D01 to D04) require Voucher module — marked skipped
- 2 BC-REF conditions (BC-REF-01, BC-REF-03) require cross-module setup — skipped
- ⚠️ **Critical issue**: Model field `category` (string) does not match DDL column `voucher_category_id` (FK integer). The Model and DDL are incompatible.
- V2 tests proposed — not yet implemented

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=voucher-types | accounting.menu.setupMasters | viewAny |
| GET | /accounting/voucher-type/create | accounting.voucher-type.create | create |
| POST | /accounting/voucher-type | accounting.voucher-type.store | create |
| GET | /accounting/voucher-type/{voucher_type} | accounting.voucher-type.show | viewAny |
| GET | /accounting/voucher-type/{voucher_type}/edit | accounting.voucher-type.edit | update |
| PUT/PATCH | /accounting/voucher-type/{voucher_type} | accounting.voucher-type.update | update |
| DELETE | /accounting/voucher-type/{voucher_type} | accounting.voucher-type.destroy | delete |
| GET | /accounting/voucher-type/trash/view | accounting.voucher-type.trashed | viewAny |
| GET | /accounting/voucher-type/{id}/restore | accounting.voucher-type.restore | create |
| DELETE | /accounting/voucher-type/{id}/force-delete | accounting.voucher-type.forceDelete | delete |
| POST | /accounting/voucher-type/{voucher_type}/toggle-status | accounting.voucher-type.toggleStatus | update |

---

## 6. Development Issues Found

### 6.1 Critical — Model/DDL Mismatch

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | VoucherType.php + DDL | Model fillable uses `category` (string enum: accounting/inventory/payroll/order) but DDL column is `voucher_category_id` (TINYINT UNSIGNED, FK→acc_voucher_category). These are incompatible data types. Either the migration or the model is out of sync with the current DDL. | **Critical** | Open |

### 6.2 Validation Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-V01 | VoucherTypeRequest.php | `category` validated as `in:accounting,inventory,payroll,order` (lowercase). Controller calls `strtoupper()` before storage, so DB stores uppercase. Stored values (ACCOUNTING) won't match view badge mapping which expects lowercase (accounting, payment, etc.). Inconsistent case handling. | Medium | Open |

### 6.3 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C02 | VoucherTypeController.php | Index redirects to setup-masters — `index.blade.php` is dead code (never rendered). | Low | Open |

### 6.4 View Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-B01 | _voucher-types.blade.php | View badge mapping uses category names like 'journal', 'receipt', 'payment', 'contra', 'sales', 'purchase', 'debit_note', 'credit_note' — these don't match either the DDL's `voucher_category_id` FK values or the Model's `category` enum (accounting/inventory/payroll/order). Category badges will show default gray for all values. | **High** | Open |

### 6.5 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | migration | `created_by` has no FK constraint to `sys_users`. No referential integrity at DB level. | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | **Critical**: Model `category` field incompatible with DDL `voucher_category_id` FK — cannot work together | Open |
| KN-02 | Category case inconsistency: Model uses lowercase enum, Controller uppercases, View badge mapping uses different values entirely | Open |
| KN-03 | `index.blade.php` is dead code (never rendered) | Open |
| KN-04 | View badge colors mapped to voucher-type-specific values ('journal', 'receipt', etc.) that don't match Model category enum values | Open |
| KN-05 | No FK constraint on `created_by` column | Open |
