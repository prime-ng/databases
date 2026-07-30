# acc_CostCenter — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Cost Centers

---

## 1. Business Conditions

### 1.1 Database Schema — acc_cost_centers

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(100) | NOT NULL |
| BC-DB-03 | code | varchar(20) | NULLABLE |
| BC-DB-04 | parent_id | bigint unsigned | NULLABLE, self-FK→acc_cost_centers(id), ON DELETE SET NULL |
| BC-DB-05 | category | varchar(50) | NULLABLE |
| BC-DB-06 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-07 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-08 | created_at | timestamp | NULLABLE |
| BC-DB-09 | updated_at | timestamp | NULLABLE |
| BC-DB-10 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-11 | INDEX idx_acc_cc_parent | parent_id | Performance index |
| BC-DB-12 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-13 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison and sorting |

**DDL-Level Gaps (not enforced at database layer)**

| Gap | Details |
|-----|---------|
| No FK constraint on `created_by` | No FOREIGN KEY → `sys_users(id)` at DB level |
| No UNIQUE constraint on `code` | No uniqueness enforcement at DB level — application only |

### 1.2 Validation Rules (CostCenterRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:100 | "The Cost Center Name field is required." |
| BC-VAL-02 | code | nullable, string, max:20 | — |
| BC-VAL-03 | parent_id | nullable, exists:acc_cost_centers,id | "The Parent Cost Center is invalid." |
| BC-VAL-04 | category | nullable, string, max:50 | — |
| BC-VAL-05 | is_active | required, boolean | Default true via `prepareForValidation` |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.cost-center.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.cost-center.view` | `show()` (show page) | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.cost-center.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.cost-center.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.cost-center.delete` | `destroy()`, `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default is_active | Defaults to true via prepareForValidation |
| BC-BIZ-02 | Index redirects to setup-masters tab | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'cost-centers'])` |
| BC-BIZ-03 | Create form loads parent cost centers | `CostCenter::active()->orderBy('name')->get()` for parent dropdown |
| BC-BIZ-04 | Edit form excludes self from parent dropdown | `where('id', '!=', $costCenter->id)` prevents self-parenting |
| BC-BIZ-05 | Soft delete sets is_active=false | Controller sets is_active=false first, then delete() |
| BC-BIZ-06 | Restore sets is_active=true | After restore, is_active is set to true |
| BC-BIZ-07 | Toggle status via AJAX JSON | Returns `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-08 | Trash view paginated 15/page | `CostCenter::onlyTrashed()->orderBy('name')->paginate(15)` |
| BC-BIZ-09 | Force delete permanently removes record | `forceDelete()` removes from DB |
| BC-BIZ-10 | No system guard on update | CostCenter has no `is_system` field — update always allowed |
| BC-BIZ-11 | No system guard on delete | CostCenter has no `is_system` field — delete always allowed |
| BC-BIZ-12 | No voucher guard on delete | No `isDeletable()` check — delete allowed even if vouchers reference it |
| BC-BIZ-13 | Success flash — Stored | "Cost Center created successfully." |
| BC-BIZ-14 | Success flash — Updated | "Cost Center updated successfully." |
| BC-BIZ-15 | Success flash — Trashed | "Cost Center moved to trash." |
| BC-BIZ-16 | Success flash — Restored | "Cost Center restored successfully." |
| BC-BIZ-17 | Success flash — Force Deleted | "Cost Center permanently deleted." |
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
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active cost centers |
| BC-MOD-02 | `scopeTopLevel($query)` | `whereNull('parent_id')` | Root-level centers (no parent) |
| BC-MOD-03 | `scopeByCategory($query, $category)` | `where('category', $category)` | Filter by category |
| BC-MOD-04 | `childrenRecursive()` | HasMany eager load | Nested children tree |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-02 | parent_id | acc_cost_centers (id) | SET NULL |
| BC-REF-03 | cost_center_id | acc_vouchers (cost_center_id) | RESTRICT (on voucher side) |
| BC-REF-04 | cost_center_id | acc_voucher_items (cost_center_id) | RESTRICT (on voucher item side) |
| BC-REF-05 | cost_center_id | acc_budgets (cost_center_id) | RESTRICT (on budget side) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Cost Center List Page Loads (via Setup Masters Tab) | Tab shows list with Name, Code, Category, Parent hierarchy, Status toggle, Actions. Add/Trash/Search visible. | — | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create With Valid Data | Redirect + "created successfully" flash. DB: name, code, category stored. | — | test_create_cost_center | ✅ |
| TC-P03 | Create With Parent | Stored with parent_id. Rendered as child in hierarchy. | — | test_create_with_parent | ✅ |
| TC-P04 | Create With Category | Category stored (e.g., "Department", "Location", "Project"). | — | test_create_with_category | ✅ |
| TC-P05 | Create Without Code | code=null stored (nullable field). | — | test_create_without_code | ✅ |
| TC-P06 | View Cost Center Details | Name, Code, Category, Parent, Children displayed. | — | test_show_page_displays_all_details | ✅ |
| TC-P07 | Edit & Update Cost Center | Pre-filled data, "updated successfully" flash, redirect. DB updated. | — | test_edit_and_update_cost_center | ✅ |
| TC-P08 | Edit Excludes Self From Parent Dropdown | Self excluded from parent_id options. | — | test_edit_excludes_self_from_parent_dropdown | ✅ |
| TC-P09 | Toggle Active Status (AJAX) | Click toggle → is_active flips. Toggle back → flips again. | — | test_toggle_active_status | ✅ |
| TC-P10 | Full Lifecycle: Delete → Trash → Restore → Soft Delete → Force Delete | All 5 states verified, DB transitions correct. | — | test_trash_restore_force_delete_lifecycle | ✅ |
| TC-P11 | Search Cost Centers | Search by name/code returns matching results. | — | test_search_cost_centers | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Name | Validation error: "The Cost Center Name field is required." | — | test_validation_requires_name | ✅ |
| TC-N02 | Name Max Length (101 chars) | Validation error (max:100) | — | test_validation_name_max_length | ✅ |
| TC-N03 | Code Max Length (21 chars) | Validation error (max:20) | — | test_validation_code_max_length | ✅ |
| TC-N04 | Category Max Length (51 chars) | Validation error (max:50) | — | test_validation_category_max_length | ✅ |
| TC-N05 | Invalid parent_id (non-existent) | "The Parent Cost Center is invalid." error | — | test_validation_invalid_parent_id | ✅ |
| TC-N06 | View Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N07 | Edit Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N08 | Delete Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N09 | Toggle Invalid ID (404) | HTTP 404 | — | test_invalid_id_toggle_returns_404 | ✅ |
| TC-N10 | Permission 403 — No Cost Center Permissions | 403 or redirect for user without permissions | — | test_permission_denied_returns_403 | ✅ |
| TC-N11 | Guest Access Redirect | Redirected to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N12 | Empty Trash Page | "No Data Found" or empty state message | — | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Inactive Center Removed From Voucher Dropdown | Inactive cost center excluded from voucher dropdowns | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D02 | B | Center With Vouchers Can Still Be Deleted | No guard — delete allowed even if vouchers reference it (data integrity gap) | — | test_dependency_requires_voucher_module | ⏸️ |
| TC-D03 | C | Self-Referencing Hierarchy Cycle Protection | parent_id FK SET NULL prevents orphan records | — | test_dependency_hierarchy_cycle | ⏸️ |

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
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-13 | Schema |
| 02 | test_model_scopes_active_topLevel_byCategory | BC-MOD-01 to BC-MOD-03 | Schema |
| 03 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 04 | test_create_cost_center | TC-P02, BC-VAL-05, BC-BIZ-01/20 | Positive |
| 05 | test_create_with_parent | TC-P03, BC-VAL-03, BC-BIZ-03 | Positive |
| 06 | test_create_with_category | TC-P04, BC-VAL-04 | Positive |
| 07 | test_create_without_code | TC-P05, BC-VAL-02 | Positive |
| 08 | test_show_page_displays_all_details | TC-P06 | Positive |
| 09 | test_edit_and_update_cost_center | TC-P07, BC-BIZ-21 | Positive |
| 10 | test_edit_excludes_self_from_parent_dropdown | TC-P08, BC-BIZ-04 | Positive |
| 11 | test_toggle_active_status | TC-P09, BC-BIZ-07/25 | Positive |
| 12 | test_trash_restore_force_delete_lifecycle | TC-P10, BC-BIZ-05/06/22/23/24 | Positive |
| 13 | test_search_cost_centers | TC-P11 | Positive |
| 14 | test_validation_requires_name | TC-N01, BC-VAL-01 | Negative |
| 15 | test_validation_name_max_length | TC-N02, BC-VAL-01 | Negative |
| 16 | test_validation_code_max_length | TC-N03, BC-VAL-02 | Negative |
| 17 | test_validation_category_max_length | TC-N04, BC-VAL-04 | Negative |
| 18 | test_validation_invalid_parent_id | TC-N05, BC-VAL-03 | Negative |
| 19 | test_invalid_id_returns_404 | TC-N06, N07, N08 | Negative |
| 20 | test_invalid_id_toggle_returns_404 | TC-N09 | Negative |
| 21 | test_permission_denied_returns_403 | TC-N10, BC-AUTH-01 to 05 | Negative |
| 22 | test_guest_redirect_to_login | TC-N11 | Negative |
| 23 | test_empty_trash_page | TC-N12 | Negative |
| 24 | test_dependency_requires_voucher_module | TC-D01 to D03 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 11 | 11 | 0 | 0 | **100%** |
| Negative | 12 | 12 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 3 | 0 | 0 | 3 | **0%** |
| **Total** | **34** | **23** | **0** | **11** | **68%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 13 | 13 | 0 | **100%** |
| Validation Rules (BC-VAL) | 5 | 5 | 0 | **100%** |
| Authorization (BC-AUTH) | 5 | 5 | 0 | **100%** |
| Business Logic (BC-BIZ) | 25 | 24 | 1 | **96%** |
| Model Scopes/Helpers (BC-MOD) | 4 | 4 | 0 | **100%** |
| Referential Integrity (BC-REF) | 5 | 1 | 4 | **20%** |
| **Total** | **57** | **52** | **5** | **91%** |

### Coverage Notes
- All 23 positive + negative TCs proposed for V2 coverage
- All BC-DB (13/13), BC-VAL (5/5), BC-AUTH (5/5), BC-MOD (4/4) conditions fully covered
- 24/25 BC-BIZ conditions covered (uncovered: BC-BIZ-19 SweetAlert delete confirmation)
- 3 dependency TCs (TC-D01 to D03) require Voucher module — marked skipped
- 4 BC-REF conditions require cross-module setup — skipped
- ⚠️ No delete guard: cost centers can be deleted even if referenced by vouchers or budgets (potential data integrity gap)
- No `is_system` field — no protection for seeded cost centers
- V2 tests proposed — not yet implemented

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=cost-centers | accounting.menu.setupMasters | viewAny |
| GET | /accounting/cost-center/create | accounting.cost-center.create | create |
| POST | /accounting/cost-center | accounting.cost-center.store | create |
| GET | /accounting/cost-center/{cost_center} | accounting.cost-center.show | viewAny |
| GET | /accounting/cost-center/{cost_center}/edit | accounting.cost-center.edit | update |
| PUT/PATCH | /accounting/cost-center/{cost_center} | accounting.cost-center.update | update |
| DELETE | /accounting/cost-center/{cost_center} | accounting.cost-center.destroy | delete |
| GET | /accounting/cost-center/trash/view | accounting.cost-center.trashed | viewAny |
| GET | /accounting/cost-center/{id}/restore | accounting.cost-center.restore | create |
| DELETE | /accounting/cost-center/{id}/force-delete | accounting.cost-center.forceDelete | delete |
| POST | /accounting/cost-center/{cost_center}/toggle-status | accounting.cost-center.toggleStatus | update |

---

## 6. Development Issues Found

### 6.1 Delete Guard Gap

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-D01 | CostCenterController.php | No `isDeletable()` check — cost center can be deleted even if referenced by vouchers, voucher items, or budgets. No guard against orphaned references. | **High** | Open |
| DEV-D02 | CostCenterController.php | No `isSystem()` guard — no protection for seeded/system cost centers. | Medium | Open |

### 6.2 Validation Gaps

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-V01 | CostCenterRequest.php | `code` nullable — no unique constraint at DB or application level; duplicates possible. | Low | Open |
| DEV-V02 | CostCenterRequest.php | `category` free-text string with no enum restriction; inconsistent values possible. | Low | Open |

### 6.3 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | CostCenterController.php | Index redirects to setup-masters — `index.blade.php` is dead code (never rendered). | Low | Open |

### 6.4 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | migration | `created_by` has no FK constraint to `sys_users`. No referential integrity at DB level. | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | No delete guard — cost centers with voucher/budget references can be deleted (orphaned references) | Open |
| KN-02 | No `is_system` field — no protection for seeded/system cost centers | Open |
| KN-03 | `code` has no unique constraint — duplicates possible | Open |
| KN-04 | `category` is free-text with no enum — inconsistent values | Open |
| KN-05 | `index.blade.php` is dead code (never rendered) | Open |
| KN-06 | No FK constraint on `created_by` column | Open |
