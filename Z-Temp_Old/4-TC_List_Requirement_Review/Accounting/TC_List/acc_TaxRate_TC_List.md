# acc_TaxRate — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Tax Rates

---

## 1. Business Conditions

### 1.1 Database Schema — acc_tax_rates

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(100) | NOT NULL |
| BC-DB-03 | rate | decimal(5,2) | NOT NULL |
| BC-DB-04 | type | enum('CGST','SGST','IGST','Cess') | NOT NULL |
| BC-DB-05 | hsn_sac_code | varchar(20) | NULLABLE |
| BC-DB-06 | is_interstate | tinyint(1) | DEFAULT 0 |
| BC-DB-07 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-08 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-09 | created_at | timestamp | NULLABLE |
| BC-DB-10 | updated_at | timestamp | NULLABLE |
| BC-DB-11 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-12 | INDEX idx_acc_tax_type | type | Performance index |
| BC-DB-13 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-14 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison and sorting |

**DDL-Level Gaps (not enforced at database layer)**

| Gap | Details |
|-----|---------|
| No FK constraint on `created_by` | No FOREIGN KEY → `sys_users(id)` at DB level |
| No CHECK constraint on `rate` (min/max) | `rate` must be 0-100 only at application layer — DB allows any DECIMAL(5,2) |

### 1.2 Validation Rules (TaxRateRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:100 | "The Tax Rate Name field is required." |
| BC-VAL-02 | rate | required, numeric, min:0, max:100 | "The Rate (%) must be between 0 and 100." |
| BC-VAL-03 | type | required, in:CGST,SGST,IGST,Cess | "The Tax Type is invalid." |
| BC-VAL-04 | hsn_sac_code | nullable, string, max:20 | — |
| BC-VAL-05 | is_interstate | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-06 | is_active | required, boolean | Default true via `prepareForValidation` |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.tax-rate.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.tax-rate.view` | `show()` (show page) | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.tax-rate.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.tax-rate.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.tax-rate.delete` | `destroy()`, `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Rate must be between 0 and 100 | Validation rejects rate < 0 or > 100 |
| BC-BIZ-02 | Tax type must be valid enum | Only CGST/SGST/IGST/Cess allowed |
| BC-BIZ-03 | Default is_interstate | Defaults to false via prepareForValidation |
| BC-BIZ-04 | Default is_active | Defaults to true via prepareForValidation |
| BC-BIZ-05 | Index redirects to setup-masters tab | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'tax-rates'])` |
| BC-BIZ-06 | Soft delete sets is_active=false | Controller sets is_active=false first, then delete() |
| BC-BIZ-07 | Restore sets is_active=true | After restore, is_active is set to true |
| BC-BIZ-08 | Toggle status via AJAX JSON | Returns `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-09 | Trash view paginated 15/page | `TaxRate::onlyTrashed()->orderBy('name')->paginate(15)` |
| BC-BIZ-10 | Force delete permanently removes record | `forceDelete()` removes from DB |
| BC-BIZ-11 | No system guard on update | Tax rates have no `is_system` field — update always allowed |
| BC-BIZ-12 | No system guard on delete | Tax rates have no `is_system` field — delete always allowed (no voucher check either) |
| BC-BIZ-13 | Success flash — Stored | "Tax Rate created successfully." |
| BC-BIZ-14 | Success flash — Updated | "Tax Rate updated successfully." |
| BC-BIZ-15 | Success flash — Trashed | "Tax Rate moved to trash." |
| BC-BIZ-16 | Success flash — Restored | "Tax Rate restored successfully." |
| BC-BIZ-17 | Success flash — Force Deleted | "Tax Rate permanently deleted." |
| BC-BIZ-18 | Success flash — Status toggled | JSON `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-19 | Delete confirmation | SweetAlert "Are you sure?" |
| BC-BIZ-20 | Activity log — Stored | On create |
| BC-BIZ-21 | Activity log — Updated | On update |
| BC-BIZ-22 | Activity log — Trashed | On soft delete |
| BC-BIZ-23 | Activity log — Restored | On restore |
| BC-BIZ-24 | Activity log — Deleted | On force delete |
| BC-BIZ-25 | Activity log — Toggled | On status toggle |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Query Criteria | Usage |
|-------|-------------|----------------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active tax rates |
| BC-MOD-02 | `scopeByType($query, $type)` | `where('type', $type)` | Filter by tax type |
| BC-MOD-03 | `scopeInterstate($query)` | `where('is_interstate', true)` | Interstate (IGST applicable) |
| BC-MOD-04 | `scopeIntrastate($query)` | `where('is_interstate', false)` | Intrastate (CGST+SGST applicable) |
| BC-MOD-05 | `TYPES` constant | `['CGST', 'SGST', 'IGST', 'Cess']` | Available tax types |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Tax Rate List Page Loads (via Setup Masters Tab) | Tab shows list with Name, Rate %, Tax Type, HSN/SAC, Interstate flag, Status toggle, Actions. Add/Trash/Search visible. | — | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create CGST Type | Redirect + "created successfully" flash. DB: name, rate, type=CGST stored. | — | test_create_cgst_type | ✅ |
| TC-P03 | Create SGST Type | type=SGST stored correctly. | — | test_create_sgst_type | ✅ |
| TC-P04 | Create IGST Type (Interstate) | type=IGST, is_interstate=true stored. | — | test_create_igst_interstate | ✅ |
| TC-P05 | Create Cess Type | type=Cess stored correctly. | — | test_create_cess_type | ✅ |
| TC-P06 | Create With HSN/SAC Code | hsn_sac_code stored (e.g., "9983"). | — | test_create_with_hsn_sac_code | ✅ |
| TC-P07 | Create With Rate as Decimal | rate=9.00 stored with 2 decimal precision. | — | test_create_with_decimal_rate | ✅ |
| TC-P08 | Create With is_interstate=false | is_interstate=0 stored (intrastate). | — | test_create_intrastate | ✅ |
| TC-P09 | View Tax Rate Details | Name, Rate %, Tax Type badge, HSN/SAC, Interstate badge displayed. | — | test_show_page_displays_all_details | ✅ |
| TC-P10 | Edit & Update Tax Rate | Pre-filled data, "updated successfully" flash, redirect. DB updated. | — | test_edit_and_update_tax_rate | ✅ |
| TC-P11 | Toggle Active Status (AJAX) | Click toggle → is_active flips. Toggle back → flips again. | — | test_toggle_active_status | ✅ |
| TC-P12 | Full Lifecycle: Delete → Trash → Restore → Soft Delete → Force Delete | All 5 states verified, DB transitions correct. | — | test_trash_restore_force_delete_lifecycle | ✅ |
| TC-P13 | Search Tax Rates | Search by name returns matching results. | — | test_search_tax_rates | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Fields | Validation errors: "field is required" for name, rate, type | — | test_validation_requires_all_fields | ✅ |
| TC-N02 | Invalid Tax Type | "The Tax Type is invalid." — only CGST/SGST/IGST/Cess allowed | — | test_validation_invalid_tax_type | ✅ |
| TC-N03 | Rate Above 100 | "The Rate (%) must be between 0 and 100." | — | test_validation_rate_above_100 | ✅ |
| TC-N04 | Negative Rate | "The Rate (%) must be between 0 and 100." | — | test_validation_negative_rate | ✅ |
| TC-N05 | Non-Numeric Rate | "The Rate (%) must be a number." | — | test_validation_rate_non_numeric | ✅ |
| TC-N06 | Name Max Length (101 chars) | Validation error (max:100) | — | test_validation_name_max_length | ✅ |
| TC-N07 | HSN/SAC Max Length (21 chars) | Validation error (max:20) | — | test_validation_hsn_max_length | ✅ |
| TC-N08 | View Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N09 | Edit Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N10 | Delete Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N11 | Toggle Invalid ID (404) | HTTP 404 | — | test_invalid_id_toggle_returns_404 | ✅ |
| TC-N12 | Permission 403 — No Tax Rate Permissions | 403 or redirect for user without permissions | — | test_permission_denied_returns_403 | ✅ |
| TC-N13 | Guest Access Redirect | Redirected to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N14 | Empty Trash Page | "No Data Found" or empty state message | — | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | B | Tax Rate Referenced in Voucher Items | Tax rate used in voucher item tax calculations | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D02 | C | Soft-Deleted Tax Rate Removed From Dropdown | Deleted rate excluded from voucher tax dropdowns | — | test_dependency_requires_voucher_module | ⏸️ |

⏸️ = Skipped — requires Voucher module setup (cross-module dependency)

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
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-14 | Schema |
| 02 | test_model_scopes_active_byType_interstate_intrastate | BC-MOD-01 to BC-MOD-04 | Schema |
| 03 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 04 | test_create_cgst_type | TC-P02, BC-VAL-03 | Positive |
| 05 | test_create_sgst_type | TC-P03 | Positive |
| 06 | test_create_igst_interstate | TC-P04, BC-VAL-05, BC-BIZ-03 | Positive |
| 07 | test_create_cess_type | TC-P05 | Positive |
| 08 | test_create_with_hsn_sac_code | TC-P06, BC-VAL-04 | Positive |
| 09 | test_create_with_decimal_rate | TC-P07, BC-VAL-02 | Positive |
| 10 | test_create_intrastate | TC-P08 | Positive |
| 11 | test_show_page_displays_all_details | TC-P09 | Positive |
| 12 | test_edit_and_update_tax_rate | TC-P10, BC-BIZ-21 | Positive |
| 13 | test_toggle_active_status | TC-P11, BC-BIZ-08/25 | Positive |
| 14 | test_trash_restore_force_delete_lifecycle | TC-P12, BC-BIZ-06/07/22/23/24 | Positive |
| 15 | test_search_tax_rates | TC-P13 | Positive |
| 16 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03 | Negative |
| 17 | test_validation_invalid_tax_type | TC-N02, BC-VAL-03, BC-BIZ-02 | Negative |
| 18 | test_validation_rate_above_100 | TC-N03, BC-VAL-02, BC-BIZ-01 | Negative |
| 19 | test_validation_negative_rate | TC-N04, BC-VAL-02 | Negative |
| 20 | test_validation_rate_non_numeric | TC-N05, BC-VAL-02 | Negative |
| 21 | test_validation_name_max_length | TC-N06, BC-VAL-01 | Negative |
| 22 | test_validation_hsn_max_length | TC-N07, BC-VAL-04 | Negative |
| 23 | test_invalid_id_returns_404 | TC-N08, N09, N10 | Negative |
| 24 | test_invalid_id_toggle_returns_404 | TC-N11 | Negative |
| 25 | test_permission_denied_returns_403 | TC-N12, BC-AUTH-01 to 05 | Negative |
| 26 | test_guest_redirect_to_login | TC-N13 | Negative |
| 27 | test_empty_trash_page | TC-N14 | Negative |
| 28 | test_dependency_requires_voucher_module | TC-D01, D02 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 13 | 13 | 0 | 0 | **100%** |
| Negative | 14 | 14 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 2 | 0 | 0 | 2 | **0%** |
| **Total** | **37** | **27** | **0** | **10** | **73%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 14 | 14 | 0 | **100%** |
| Validation Rules (BC-VAL) | 6 | 6 | 0 | **100%** |
| Authorization (BC-AUTH) | 5 | 5 | 0 | **100%** |
| Business Logic (BC-BIZ) | 25 | 24 | 1 | **96%** |
| Model Scopes/Helpers (BC-MOD) | 5 | 5 | 0 | **100%** |
| Referential Integrity (BC-REF) | 1 | 0 | 1 | **0%** |
| **Total** | **56** | **54** | **2** | **96%** |

### Coverage Notes
- All 27 positive + negative TCs proposed for V2 coverage
- All BC-DB (14/14), BC-VAL (6/6), BC-AUTH (5/5), BC-MOD (5/5) conditions fully covered
- 24/25 BC-BIZ conditions covered (uncovered: BC-BIZ-19 SweetAlert delete confirmation — pending view implementation)
- 2 dependency TCs (TC-D01, TC-D02) require Voucher module — marked skipped
- BC-REF-01 (created_by FK) requires cross-module setup — skipped
- No `is_system` field on TaxRate — no system guard exists; update/delete always allowed
- No `isDeletable()` check — delete always allowed regardless of voucher references (potential data integrity gap)
- V2 tests proposed — not yet implemented

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=tax-rates | accounting.menu.setupMasters | viewAny |
| GET | /accounting/tax-rate/create | accounting.tax-rate.create | create |
| POST | /accounting/tax-rate | accounting.tax-rate.store | create |
| GET | /accounting/tax-rate/{tax_rate} | accounting.tax-rate.show | viewAny |
| GET | /accounting/tax-rate/{tax_rate}/edit | accounting.tax-rate.edit | update |
| PUT/PATCH | /accounting/tax-rate/{tax_rate} | accounting.tax-rate.update | update |
| DELETE | /accounting/tax-rate/{tax_rate} | accounting.tax-rate.destroy | delete |
| GET | /accounting/tax-rate/trash/view | accounting.tax-rate.trashed | viewAny |
| GET | /accounting/tax-rate/{id}/restore | accounting.tax-rate.restore | create |
| DELETE | /accounting/tax-rate/{id}/force-delete | accounting.tax-rate.forceDelete | delete |
| POST | /accounting/tax-rate/{tax_rate}/toggle-status | accounting.tax-rate.toggleStatus | update |

---

## 6. Development Issues Found

### 6.1 Delete Guard Gap

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-D01 | TaxRateController.php | No `isDeletable()` check on destroy — a tax rate can be deleted even if referenced by existing vouchers. No guard against orphaned references. | **High** | Open |
| DEV-D02 | TaxRateController.php | No `isSystem()` guard — TaxRate has no `is_system` field. All tax rates are deletable. No protection for seeded system tax rates. | Medium | Open |

### 6.2 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | TaxRateController.php | Index redirects to setup-masters — `index.blade.php` is dead code (never rendered). | Low | Open |

### 6.3 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | migration | `created_by` has no FK constraint to `sys_users`. No referential integrity at DB level. | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | No delete guard — tax rates with voucher references can be deleted (orphaned references) | Open |
| KN-02 | No `is_system` field — no protection for seeded/tax rates | Open |
| KN-03 | `index.blade.php` is dead code (never rendered) | Open |
| KN-04 | No FK constraint on `created_by` column | Open |
