# acc_FinancialYear — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Financial Year

---

## 1. Business Conditions

### 1.1 Database Schema — acc_financial_years

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | tinyint unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(50) | NOT NULL |
| BC-DB-03 | start_date | date | NOT NULL |
| BC-DB-04 | end_date | date | NOT NULL |
| BC-DB-05 | is_locked | tinyint(1) | DEFAULT 0 |
| BC-DB-06 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-07 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-08 | created_at | timestamp | NULLABLE |
| BC-DB-09 | updated_at | timestamp | NULLABLE |
| BC-DB-10 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-11 | INDEX idx_acc_fy_active | is_active | Performance index |
| BC-DB-12 | INDEX idx_acc_fy_dates | start_date, end_date | Composite index for date range queries |
| BC-DB-13 | id — TINYINT UNSIGNED | — | Max 255 records; auto-increment rolls over at 255 |
| BC-DB-14 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-15 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison and sorting |
| BC-DB-16 | start_date / end_date type = DATE (not DATETIME/TIMESTAMP) | — | No time component stored — pure date only |

**DDL-Level Gaps (not enforced at database layer)**

| Gap | Details |
|-----|---------|
| No CHECK constraint | `end_date > start_date` validated only at application layer (FormRequest), NOT at DB level |
| No UNIQUE constraint on `name` | Uniqueness enforced only by `FormRequest` validation, NOT by DB index/constraint |
| No FK constraint on `created_by` | `created_by` column nullable INT UNSIGNED but no FOREIGN KEY → `sys_users(id)` at DB level |

### 1.2 Validation Rules (FinancialYearRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:50, unique:acc_financial_years,name,ignore current ID,whereNull:deleted_at | "The Financial Year Name has already been taken." |
| BC-VAL-02 | start_date | required, date | "The Start Date field is required." |
| BC-VAL-03 | end_date | required, date, after:start_date | "The End Date must be a date after Start Date." |
| BC-VAL-04 | is_locked | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-05 | is_active | required, boolean | Default true via `prepareForValidation` |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.financial-year.viewAny` | `index()`, `show()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.financial-year.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.financial-year.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.financial-year.delete` | `destroy()`, `forceDelete()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.financial-year.lock` | `lock()`, `unlock()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Name uniqueness (soft-delete aware) | Duplicate name rejected — unique validation ignores current ID and soft-deleted records |
| BC-BIZ-02 | End date after start date | Validation rejects end_date <= start_date |
| BC-BIZ-03 | Default is_locked | Defaults to false |
| BC-BIZ-04 | Default is_active | Defaults to true |
| BC-BIZ-05 | prepareForValidation normalizes booleans | Missing values defaulted to false/true |
| BC-BIZ-06 | Auto end_date calculation | `Carbon::parse(start_date)->addYear()->subDay()` |
| BC-BIZ-07 | Auto name generation (frontend JS) | `{startYear}-{endYearShort}` e.g., "2025-26" |
| BC-BIZ-08 | Locked FY blocks update | "Cannot update a locked Financial Year." |
| BC-BIZ-09 | Locked FY blocks delete | "Cannot delete a locked Financial Year." |
| BC-BIZ-10 | FY with vouchers blocks delete | "Cannot delete Financial Year with existing vouchers." |
| BC-BIZ-11 | Lock toggles is_locked ON | is_locked=true, flash: "Financial Year locked successfully." |
| BC-BIZ-12 | Unlock toggles is_locked OFF | is_locked=false, flash: "Financial Year unlocked." |
| BC-BIZ-13 | Soft delete sets is_active=false | Controller sets is_active=false first, then delete() |
| BC-BIZ-14 | Index redirects to setup-masters tab | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'financial-years'])` |
| BC-BIZ-15 | Create view auto-calculates via JS | Frontend JS auto-fills end_date when start_date changes |
| BC-BIZ-16 | Edit view no auto-calculate | Both date fields editable — no auto-calc JS |
| BC-BIZ-17 | Success flash — Stored | "Financial Year created successfully." |
| BC-BIZ-18 | Success flash — Updated | "Financial Year updated successfully." |
| BC-BIZ-19 | Success flash — Trashed | "Financial Year moved to trash." |
| BC-BIZ-20 | Success flash — Restored | "Financial Year restored successfully." |
| BC-BIZ-21 | Success flash — Force Deleted | "Financial Year permanently deleted." |
| BC-BIZ-22 | Success flash — Status toggled | JSON `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-23 | Delete confirmation | SweetAlert "Are you sure?" |
| BC-BIZ-24 | Restore confirmation | SweetAlert confirmation |
| BC-BIZ-25 | Force delete confirmation | SweetAlert "Delete Permanently?" |
| BC-BIZ-26 | Activity log — Stored | On create |
| BC-BIZ-27 | Activity log — Updated | On update |
| BC-BIZ-28 | Activity log — Trashed | On soft delete |
| BC-BIZ-29 | Activity log — Restored | On restore |
| BC-BIZ-30 | Activity log — Deleted | On force delete |
| BC-BIZ-31 | Activity log — Toggled | On status toggle |
| BC-BIZ-32 | Activity log — Locked | On lock |
| BC-BIZ-33 | Activity log — Unlocked | On unlock |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Query Criteria | Usage |
|-------|-------------|----------------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active FYs |
| BC-MOD-02 | `scopeLocked($query)` | `where('is_locked', true)` | Filter locked FYs |
| BC-MOD-03 | `scopeUnlocked($query)` | `where('is_locked', false)` | Filter unlocked FYs |
| BC-MOD-04 | `scopeCurrent($query)` | `where('start_date', '<=', now())->where('end_date', '>=', now())` | Find current FY |
| BC-MOD-05 | `isLocked(): bool` | Returns `$this->is_locked` | Check if locked |
| BC-MOD-06 | `containsDate($date): bool` | `$date >= start_date && $date <= end_date` | Date within FY |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-02 | financial_year_id | acc_vouchers (id) | RESTRICT |
| BC-REF-03 | financial_year_id | acc_budgets (id) | RESTRICT |
| BC-REF-04 | financial_year_id | acc_depreciation_entries (id) | RESTRICT |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Financial Year List Page Loads (via Setup Masters Tab) | Tab shows cards/table with Name, Start Date, End Date, Status, Actions. Add/Trash/Search visible. | test_financial_year_index_page_loads_via_setup_masters_tab | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create With Valid Data (auto-calc end_date + defaults) | Redirect + "created successfully" flash. DB: is_locked=0, is_active=1. Activity log "Stored". | test_financial_year_is_created_successfully | test_create_financial_year_with_valid_data | ✅ |
| TC-P03 | Create With Manual end_date (no auto-calc) | Custom dates stored correctly. | — | test_create_with_manual_end_date | ✅ |
| TC-P04 | View Financial Year Details | Name, dates (d M Y format), "Open" and "Active" badges shown. | test_financial_year_show_page_displays_all_details | test_show_page_displays_all_details | ✅ |
| TC-P05 | Edit & Update Name | Pre-filled data, "updated successfully" flash, redirect. DB updated. | test_financial_year_can_be_updated | test_edit_and_update_name | ✅ |
| TC-P06 | Lock Financial Year | Edit form → check is_locked → Update → FY locked. Show page shows "Locked". | — | test_lock_financial_year | ✅ |
| TC-P07 | Unlock Financial Year | Direct JS POST → FY unlocked. Show page shows "Open". | — | test_unlock_financial_year | ✅ |
| TC-P08 | Toggle Active Status (AJAX) | Click toggle → is_active flips. Toggle back → flips again. | — | test_toggle_active_status | ✅ |
| TC-P09 | Full Lifecycle: Delete → Trash → Restore → Soft Delete → Force Delete | All 5 states verified, DB transitions correct. | test_financial_year_trash_restore_and_force_delete | test_trash_restore_force_delete_lifecycle | ✅ |
| TC-P10 | Search & Filter Financial Years | Search by name returns matching results. | — | test_search_financial_years | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Fields | Validation errors: "field is required" for name, start_date, end_date | test_create_validation_requires_all_fields | test_validation_requires_all_fields | ✅ |
| TC-N02 | End Date Before Start Date | "must be a date after" error | test_create_validation_end_date_must_be_after_start_date | test_validation_end_date_before_start_date | ✅ |
| TC-N03 | End Date Equal To Start Date | "must be a date after" error | — | test_validation_end_date_equals_start_date | ✅ |
| TC-N04 | Duplicate Name | "already been taken" error | test_create_validation_duplicate_name_is_rejected | test_validation_duplicate_name | ✅ |
| TC-N05 | Name Max Length (51 chars) | Validation error (max:50) | — | test_validation_name_max_length | ✅ |
| TC-N06 | Edit — Duplicate Name | "already been taken" on update. Original preserved. | — | test_edit_duplicate_name | ✅ |
| TC-N07 | Update Locked FY | "Cannot update a locked Financial Year." Name unchanged. | test_cannot_update_locked_financial_year | test_cannot_update_locked_financial_year | ✅ |
| TC-N08 | Delete Locked FY | FY not deleted (deleted_at NULL) | test_cannot_delete_locked_financial_year | test_cannot_delete_locked_financial_year | ✅ |
| TC-N09 | Delete FY With Vouchers | "Cannot delete Financial Year with existing vouchers." Not deleted. | — | test_cannot_delete_fy_with_vouchers | ✅ |
| TC-N10 | View Invalid ID (404) | HTTP 404 | test_invalid_financial_year_id_returns_404 | test_invalid_id_returns_404 | ✅ |
| TC-N11 | Edit Invalid ID (404) | HTTP 404 | test_invalid_financial_year_id_returns_404 | test_invalid_id_returns_404 | ✅ |
| TC-N12 | Delete Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N13 | Toggle/Lock/Unlock Invalid ID (404) | HTTP 404 for all three endpoints | — | test_invalid_id_lock_unlock_toggle_returns_404 | ✅ |
| TC-N14 | Permission 403 — No FY Permissions | 403 or redirect for user without permissions | — | test_permission_denied_returns_403 | ✅ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N16 | Empty Trash Page | "No Data Found" or empty state message | — | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Inactive FY Removed From Voucher Dropdown | Inactive FY excluded from dropdown if scopeActive used | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D02 | B | Locked FY Blocks Voucher Edit | Voucher edit blocked when referencing FY is locked | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D03 | C | Soft-Deleted FY Removed From Dropdown | Deleted FY excluded from voucher dropdowns | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D04 | C | FK Restrict — Force Delete With Referencing Records | FK constraint prevents force delete when vouchers exist | — | test_dependency_requires_voucher_module | ⏸️ |

⏸️ = Skipped — requires Voucher/Budget module setup (cross-module dependency)

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
| TC-SW09 | Lock — SweetAlert confirm locks FY | Click Lock → SweetAlert shows confirmation → Confirm → FY locked (is_locked=true) | — | test_sweet_alert_lock_confirm | 🔴 |
| TC-SW10 | Unlock — SweetAlert confirm unlocks FY | Click Unlock → SweetAlert shows confirmation → Confirm → FY unlocked (is_locked=false) | — | test_sweet_alert_unlock_confirm | 🔴 |

---

## 3. V2 Test Method Index

| # | Method | TC / BC Map | Category |
|---|--------|-------------|----------|
| 01 | test_migration_model_indexes_and_relationships | TC-DB-01, BC-DB-01 to BC-DB-16, BC-MOD-05/06 | Schema |
| 02 | test_model_scopes_active_locked_unlocked_current | BC-MOD-01 to BC-MOD-04 | Schema |
| 03 | test_frontend_auto_calculation_on_create_page | BC-BIZ-07, BC-BIZ-15 | Positive |
| 04 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 05 | test_create_financial_year_with_valid_data | TC-P02, BC-VAL-04/05, BC-BIZ-03/04/26 | Positive |
| 06 | test_create_with_manual_end_date | TC-P03 | Positive |
| 07 | test_show_page_displays_all_details | TC-P04 | Positive |
| 08 | test_edit_and_update_name | TC-P05, BC-BIZ-27 | Positive |
| 09 | test_lock_financial_year | TC-P06, BC-BIZ-11, BC-BIZ-32 | Positive |
| 10 | test_unlock_financial_year | TC-P07, BC-BIZ-12, BC-BIZ-33 | Positive |
| 11 | test_toggle_active_status | TC-P08, BC-BIZ-22, BC-BIZ-31 | Positive |
| 12 | test_trash_restore_force_delete_lifecycle | TC-P09, BC-BIZ-13/28/29/30 | Positive |
| 13 | test_sweetalert_delete_confirmation_appears | BC-BIZ-23 | Positive |
| 14 | test_search_financial_years | TC-P10 | Positive |
| 15 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03 | Negative |
| 16 | test_validation_end_date_before_start_date | TC-N02, BC-VAL-03 | Negative |
| 17 | test_validation_end_date_equals_start_date | TC-N03, BC-VAL-03 | Negative |
| 18 | test_validation_duplicate_name | TC-N04, BC-VAL-01, BC-BIZ-01 | Negative |
| 19 | test_validation_name_max_length | TC-N05, BC-VAL-01 | Negative |
| 20 | test_edit_duplicate_name | TC-N06, BC-VAL-01, BC-BIZ-01 | Negative |
| 21 | test_cannot_update_locked_financial_year | TC-N07, BC-BIZ-08 | Negative |
| 22 | test_cannot_delete_locked_financial_year | TC-N08, BC-BIZ-09 | Negative |
| 23 | test_cannot_delete_fy_with_vouchers | TC-N09, BC-BIZ-10, BC-REF-02 | Negative |
| 24 | test_invalid_id_returns_404 | TC-N10, N11, N12 | Negative |
| 25 | test_invalid_id_lock_unlock_toggle_returns_404 | TC-N13 | Negative |
| 26 | test_permission_denied_returns_403 | TC-N14, BC-AUTH-01 to 05 | Negative |
| 27 | test_guest_redirect_to_login | TC-N15 | Negative |
| 28 | test_empty_trash_page | TC-N16 | Negative |
| 29 | test_dependency_requires_voucher_module | TC-D01 to D04 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 10 | 10 | 0 | 0 | **100%** |
| Negative | 16 | 16 | 0 | 0 | **100%** |
| SweetAlert | 10 | 0 | 0 | 10 | **0%** |
| Dependency | 4 | 0 | 0 | 4 | **0%** |
| **Total** | **40** | **26** | **0** | **14** | **65%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 16 | 16 | 0 | **100%** |
| Validation Rules (BC-VAL) | 5 | 5 | 0 | **100%** |
| Authorization (BC-AUTH) | 5 | 5 | 0 | **100%** |
| Business Logic (BC-BIZ) | 33 | 31 | 2 | **94%** |
| Model Scopes/Helpers (BC-MOD) | 6 | 6 | 0 | **100%** |
| Referential Integrity (BC-REF) | 4 | 1 | 3 | **25%** |
| **Total** | **69** | **64** | **5** | **93%** |

### Coverage Notes
- All 26 positive + negative TCs are fully covered by V2 tests
- All BC-DB (16/16), BC-VAL (5/5), BC-AUTH (5/5), BC-MOD (6/6) conditions fully covered
- 31/33 BC-BIZ conditions covered (uncovered: BC-BIZ-05 prepareForValidation — implicit via defaults, BC-BIZ-24 restore confirmation — SweetAlert may not be implemented)
- 4 dependency TCs (TC-D01 to TC-D04) require Voucher module and are marked skipped
- 3 BC-REF conditions (BC-REF-01, BC-REF-03, BC-REF-04) require cross-module setup — skipped
- New DDL conditions added (BC-DB-13 to BC-DB-16): TINYINT UNSIGNED limit, ENGINE=InnoDB, utf8mb4 charset, DATE type columns
- DDL gaps documented: no CHECK constraint (end_date > start_date), no UNIQUE on name, no FK on created_by — all enforced only at application layer
- New V2 tests added: model scopes/helpers, frontend auto-calc JS, database indexes, activity log events, SweetAlert delete confirmation, DDL condition assertions
- V1 tests cover 9 out of 30 TCs (30% coverage)

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=financial-years | accounting.menu.setupMasters | viewAny |
| GET | /accounting/financial-year/create | accounting.financial-year.create | create |
| POST | /accounting/financial-year | accounting.financial-year.store | create |
| GET | /accounting/financial-year/{financial_year} | accounting.financial-year.show | viewAny |
| GET | /accounting/financial-year/{financial_year}/edit | accounting.financial-year.edit | update |
| PUT/PATCH | /accounting/financial-year/{financial_year} | accounting.financial-year.update | update |
| DELETE | /accounting/financial-year/{financial_year} | accounting.financial-year.destroy | delete |
| GET | /accounting/financial-year/trash/view | accounting.financial-year.trash | restore |
| GET | /accounting/financial-year/{id}/restore | accounting.financial-year.restore | create |
| DELETE | /accounting/financial-year/{id}/force-delete | accounting.financial-year.forceDelete | delete |
| POST | /accounting/financial-year/{id}/toggle-status | accounting.financial-year.toggleStatus | update |
| POST | /accounting/financial-year/{id}/lock | accounting.financial-year.lock | lock |
| POST | /accounting/financial-year/{id}/unlock | accounting.financial-year.unlock | lock |

---

## 6. Development Issues Found

### 6.1 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | FinancialYearController.php | Lock/Unlock actions only accessible via direct POST (no UI buttons on show page). Users can't perform these actions from the show view. | Medium | Open |
| DEV-C02 | FinancialYearController.php | Permission prefix mismatch: controller uses `tenant.accounting.financial-year.*`, policy checks `accounting.financial-year.*` (no `tenant.` prefix). | **High** | Open |

### 6.2 Policy Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-P01 | FinancialYearPolicy.php | All permission names lack `tenant.` prefix while controller gates use `tenant.` prefix. If no gate bridging exists, all policy methods are bypassed. | **High** | Open |

### 6.3 View Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-B01 | show.blade.php | No Lock/Unlock buttons on show page. Only "Back to List" and "Edit" buttons present. | **Critical** | Open |
| DEV-B02 | index.blade.php | Dead code — never rendered because controller redirects to setup-masters. Actual listing rendered by `_financial-years.blade.php` partial. | Low | Open |
| DEV-B03 | index vs partial | Status filter mismatch: index uses Open/Locked (is_locked), tab partial uses Active/Inactive (is_active). Inconsistent UX. | Medium | Open |

### 6.4 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | migration | No UNIQUE constraint on `name` at DB level. Uniqueness enforced only at application layer. | Low | Open |
| DEV-M02 | migration | `created_by` has no FK constraint to `sys_users`. No referential integrity at DB level. | Medium | Open |

### 6.5 Test File Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-T01 | V1 test | Lock/Unlock test visits show page and presses "Lock"/"Unlock" buttons that don't exist. Test will always fail. | **Critical** | Fixed in V2 |
| DEV-T02 | V1 test | Dead constants `TOGGLE_BASE` and `TRASH_PATH` defined but never used. | Low | Fixed in V2 |
| DEV-T03 | V1 test | `pageContains()` uses loose `str_contains()` instead of specific flash message assertions. | Medium | Fixed in V2 |
| DEV-T04 | V1 test | No `finally` block cleanup — failed tests leave orphan records. | Medium | Fixed in V2 |
| DEV-T05 | V1 test | `auth()->id() ?? 1` hardcoded fallback ID 1 is fragile in multi-tenant. | Low | Fixed in V2 |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Lock/Unlock buttons missing from show page — only accessible via edit form checkbox (lock) or direct POST (unlock) | Open |
| KN-02 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | Open |
| KN-03 | `index.blade.php` is dead code (never rendered) | Open |
| KN-04 | Search status filter columns inconsistent between index (is_locked) and tab partial (is_active) | Open |
| KN-05 | No DB-level UNIQUE constraint on `name` field | Open |
| KN-06 | No FK constraint on `created_by` column | Open |
