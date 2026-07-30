# acc_AccountGroup — Test Case List & Business Conditions

## Module: Accounting → Setup Masters → Account Groups (Chart of Accounts)

---

## 1. Business Conditions

### 1.1 Database Schema — acc_account_groups

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(100) | NOT NULL |
| BC-DB-03 | code | varchar(30) | NOT NULL, UNIQUE (uq_acc_ag_code) |
| BC-DB-04 | alias | varchar(100) | NULLABLE |
| BC-DB-05 | parent_id | int unsigned | NULLABLE, self-FK→acc_account_groups(id), ON DELETE SET NULL |
| BC-DB-06 | nature | enum('Asset','Liability','Equity','Income','Expense') | NOT NULL |
| BC-DB-07 | affects_gross_profit | tinyint(1) | DEFAULT 0 |
| BC-DB-08 | is_system | tinyint(1) | DEFAULT 0 |
| BC-DB-09 | is_subledger | tinyint(1) | DEFAULT 0 |
| BC-DB-10 | ordinal | smallint | DEFAULT 0 |
| BC-DB-11 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-12 | created_by | int unsigned | NULLABLE, FK→sys_users (no DB FK) |
| BC-DB-13 | created_at | timestamp | NULLABLE |
| BC-DB-14 | updated_at | timestamp | NULLABLE |
| BC-DB-15 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-16 | INDEX idx_acc_ag_parent | parent_id | Performance index for hierarchy queries |
| BC-DB-17 | INDEX idx_acc_ag_nature | nature | Performance index for nature filter |
| BC-DB-18 | INDEX idx_acc_ag_system | is_system | Performance index for system group filter |
| BC-DB-19 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-20 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison and sorting |

**DDL-Level Gaps (not enforced at database layer)**

| Gap | Details |
|-----|---------|
| No CHECK constraint | `nature` restricted to 5 ENUM values at DB level, but Request validation only allows 4 (missing `Equity`) |
| No FK constraint on `created_by` | `created_by` column nullable INT UNSIGNED but no FOREIGN KEY → `sys_users(id)` at DB level |

### 1.2 Validation Rules (AccountGroupRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:100 | "The Group Name field is required." |
| BC-VAL-02 | code | required, string, max:20, unique:acc_account_groups,code,ignore current ID,whereNull:deleted_at | "The Group Code has already been taken." |
| BC-VAL-03 | alias | nullable, string, max:100 | — |
| BC-VAL-04 | parent_id | nullable, exists:acc_account_groups,id | "The Parent Group is invalid." |
| BC-VAL-05 | nature | required, in:asset,liability,income,expense — ⚠️ DDL includes 'Equity' but Request enum missing it | "The Account Nature is invalid." |
| BC-VAL-06 | affects_gross_profit | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-07 | is_system | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-08 | is_subledger | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-09 | ordinal | nullable, integer, min:0 | "The ordinal must be at least 0." |
| BC-VAL-10 | is_active | required, boolean | Default true via `prepareForValidation` |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.account-group.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.account-group.view` | `show()` (show page) | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.account-group.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.account-group.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.account-group.delete` | `destroy()`, `forceDelete()` | Without → 403 |
| BC-AUTH-06 | `tenant.accounting.account-group.restore` | `restore()` | Without → 403 |
| BC-AUTH-07 | `tenant.accounting.account-group.forceDelete` | `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Code uniqueness (soft-delete aware) | Duplicate code rejected — unique validation ignores current ID and soft-deleted records |
| BC-BIZ-02 | Parent group must exist | Validation rejects invalid parent_id |
| BC-BIZ-03 | Default booleans via prepareForValidation | is_active=true, affects_gross_profit=false, is_system=false, is_subledger=false |
| BC-BIZ-04 | Index redirects to setup-masters tab | Redirect to `route('accounting.menu.setupMasters', ['tab' => 'account-groups'])` |
| BC-BIZ-05 | Create form loads parent groups | `AccountGroup::active()->orderBy('ordinal')->get(['id', 'name', 'code'])` — only active groups shown as parents |
| BC-BIZ-06 | Edit form excludes self from parent dropdown | `where('id', '!=', $accountGroup->id)` to prevent self-parenting |
| BC-BIZ-07 | System group blocks update | "System account groups cannot be modified." |
| BC-BIZ-08 | System group blocks delete | "System account groups cannot be deleted." |
| BC-BIZ-09 | Group with ledgers blocks delete | `isDeletable()` checks `!is_system && ledgers()->count() === 0` — error: "Cannot delete group with existing ledgers." |
| BC-BIZ-10 | Soft delete sets is_active=false | Controller sets is_active=false first, then delete() |
| BC-BIZ-11 | Restore sets is_active=true | After restore, is_active is set to true |
| BC-BIZ-12 | Toggle status via AJAX JSON | Returns `{success: true, is_active: new_value, message: "Status updated."}` |
| BC-BIZ-13 | Show page loads parent, childrenRecursive, ledgers | `$accountGroup->load(['parent', 'children', 'ledgers'])` |
| BC-BIZ-14 | Tree view rendering | Groups rendered recursively via `_account-group-node` partial — children sorted by ordinal, indented by depth |
| BC-BIZ-15 | System badge on tree | `is_system` groups show a dark "System" badge next to name |
| BC-BIZ-16 | Nature badge colors | asset=blue, liability=orange, income=green, expense=red; default=gray for out-of-range natures |
| BC-BIZ-17 | Sub-Groups count column | Shows count of childrenRecursive, or "—" if none |
| BC-BIZ-18 | Empty state message | "No Account Groups Found" with icon |
| BC-BIZ-19 | Success flash — Stored | "Account Group created successfully." |
| BC-BIZ-20 | Success flash — Updated | "Account Group updated successfully." |
| BC-BIZ-21 | Success flash — Trashed | "Account Group moved to trash." |
| BC-BIZ-22 | Success flash — Restored | "Account Group restored successfully." |
| BC-BIZ-23 | Success flash — Force Deleted | "Account Group permanently deleted." |
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
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active groups |
| BC-MOD-02 | `scopeSystem($query)` | `where('is_system', true)` | Filter system groups |
| BC-MOD-03 | `scopeTopLevel($query)` | `whereNull('parent_id')` | Root-level groups (no parent) |
| BC-MOD-04 | `scopeByNature($query, $nature)` | `where('nature', $nature)` | Filter by account nature |
| BC-MOD-05 | `isSystem(): bool` | Returns `$this->is_system` | Check if system group |
| BC-MOD-06 | `isDeletable(): bool` | `!is_system && ledgers()->count() === 0` | Check if deletable |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | created_by | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-02 | parent_id | acc_account_groups (id) | SET NULL |
| BC-REF-03 | account_group_id | acc_ledgers (id) | RESTRICT (on ledger side) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Account Group List Page Loads (via Setup Masters Tab) | Tab shows tree table with Name, Code, Nature badge, Sub-Groups count, Status toggle, Actions. Add/Trash/Search visible. | — | test_index_page_loads_via_setup_masters_tab | ✅ |
| TC-P02 | Create With Valid Data (all fields) | Redirect + "created successfully" flash. DB: name, code, nature stored. Activity log "Stored". | — | test_create_account_group_with_valid_data | ✅ |
| TC-P03 | Create With Parent Group | Group stored with parent_id. Rendered as child in tree. | — | test_create_with_parent_group | ✅ |
| TC-P04 | Create With Alias | Alias stored correctly. | — | test_create_with_alias | ✅ |
| TC-P05 | Create With Ordinal | Ordinal stored for ordering. | — | test_create_with_ordinal | ✅ |
| TC-P06 | View Account Group Details | Name, Code, Nature, Parent, Children tree, Linked Ledgers displayed. | — | test_show_page_displays_all_details | ✅ |
| TC-P07 | Edit & Update Group | Pre-filled data, "updated successfully" flash, redirect. DB updated. | — | test_edit_and_update_group | ✅ |
| TC-P08 | Toggle Active Status (AJAX) | Click toggle → is_active flips. Toggle back → flips again. | — | test_toggle_active_status | ✅ |
| TC-P09 | Full Lifecycle: Delete → Trash → Restore → Soft Delete → Force Delete | All 5 states verified, DB transitions correct. | — | test_trash_restore_force_delete_lifecycle | ✅ |
| TC-P10 | Tree Rendering — Nested Children | Parent row bold, children indented with arrow icon, sorted by ordinal. | — | test_tree_rendering_nested_children | ✅ |
| TC-P11 | System Badge Visible | Groups with is_system=true show "System" badge next to name. | — | test_system_badge_visible_on_tree | ✅ |
| TC-P12 | Nature Badge Colors | Matching badge class per nature type. | — | test_nature_badge_colors | ✅ |
| TC-P13 | Search Account Groups | Search by name/code returns matching results. | — | test_search_account_groups | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Fields | Validation errors: "field is required" for name, code, nature | — | test_validation_requires_all_fields | ✅ |
| TC-N02 | Duplicate Code | "already been taken" error | — | test_validation_duplicate_code | ✅ |
| TC-N03 | Invalid Nature Value | "The Account Nature is invalid." — only asset/liability/income/expense allowed | — | test_validation_invalid_nature | ✅ |
| TC-N04 | Invalid Parent ID (non-existent) | "The Parent Group is invalid." error | — | test_validation_invalid_parent_id | ✅ |
| TC-N05 | Self-Referencing Parent ID on Edit | Edit form excludes self from parent dropdown (prevents self-parenting) | — | test_edit_excludes_self_from_parent_dropdown | ✅ |
| TC-N06 | Negative Ordinal | "The ordinal must be at least 0." error | — | test_validation_negative_ordinal | ✅ |
| TC-N07 | Update System Group | "System account groups cannot be modified." Name unchanged. | — | test_cannot_update_system_group | ✅ |
| TC-N08 | Delete System Group | "System account groups cannot be deleted." Not deleted. | — | test_cannot_delete_system_group | ✅ |
| TC-N09 | Delete Group With Ledgers | "Cannot delete group with existing ledgers." Not deleted. | — | test_cannot_delete_group_with_ledgers | ✅ |
| TC-N10 | View Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N11 | Edit Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N12 | Delete Invalid ID (404) | HTTP 404 | — | test_invalid_id_returns_404 | ✅ |
| TC-N13 | Toggle Invalid ID (404) | HTTP 404 | — | test_invalid_id_toggle_returns_404 | ✅ |
| TC-N14 | Permission 403 — No Account Group Permissions | 403 or redirect for user without permissions | — | test_permission_denied_returns_403 | ✅ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | test_guest_redirect_to_login | ✅ |
| TC-N16 | Empty Trash Page | "No Data Found" or empty state message | — | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Inactive Group Removed From Ledger Dropdown | Inactive group excluded from account_group_id dropdown | — | test_dependency_requires_ledger_module | ⏸️ |
| TC-D02 | B | System Group Cannot Be Referenced as Parent on Create | System groups still selectable as parent (no system filter on parent dropdown) | — | test_dependency_requires_ledger_module | ⏸️ |
| TC-D03 | C | Soft-Deleted Group Removed From Ledger Dropdown | Deleted group excluded from ledger dropdowns | — | test_dependency_requires_ledger_module | ⏸️ |
| TC-D04 | C | FK Restrict — Cannot Delete Group When Ledger References It | FK constraint prevents delete | — | test_dependency_requires_ledger_module | ⏸️ |
| TC-D05 | C | Self-Referencing Hierarchy Cycle (DB level) | parent_id FK SET NULL prevents orphan records | — | test_dependency_hierarchy_cycle | ⏸️ |

⏸️ = Skipped — requires Ledger module setup (cross-module dependency)

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
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-20, BC-MOD-05/06 | Schema |
| 02 | test_model_scopes_active_system_topLevel_byNature | BC-MOD-01 to BC-MOD-04 | Schema |
| 03 | test_index_page_loads_via_setup_masters_tab | TC-P01 | Positive |
| 04 | test_create_account_group_with_valid_data | TC-P02, BC-VAL-06/07/08/10, BC-BIZ-03/26 | Positive |
| 05 | test_create_with_parent_group | TC-P03, BC-VAL-04 | Positive |
| 06 | test_create_with_alias | TC-P04, BC-VAL-03 | Positive |
| 07 | test_create_with_ordinal | TC-P05, BC-VAL-09 | Positive |
| 08 | test_show_page_displays_all_details | TC-P06, BC-BIZ-13 | Positive |
| 09 | test_edit_and_update_group | TC-P07, BC-BIZ-27 | Positive |
| 10 | test_toggle_active_status | TC-P08, BC-BIZ-12/31 | Positive |
| 11 | test_trash_restore_force_delete_lifecycle | TC-P09, BC-BIZ-10/11/28/29/30 | Positive |
| 12 | test_tree_rendering_nested_children | TC-P10, BC-BIZ-14 | Positive |
| 13 | test_system_badge_visible_on_tree | TC-P11, BC-BIZ-15 | Positive |
| 14 | test_nature_badge_colors | TC-P12, BC-BIZ-16 | Positive |
| 15 | test_search_account_groups | TC-P13 | Positive |
| 16 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/05 | Negative |
| 17 | test_validation_duplicate_code | TC-N02, BC-VAL-02, BC-BIZ-01 | Negative |
| 18 | test_validation_invalid_nature | TC-N03, BC-VAL-05 | Negative |
| 19 | test_validation_invalid_parent_id | TC-N04, BC-VAL-04 | Negative |
| 20 | test_edit_excludes_self_from_parent_dropdown | TC-N05, BC-BIZ-06 | Negative |
| 21 | test_validation_negative_ordinal | TC-N06, BC-VAL-09 | Negative |
| 22 | test_cannot_update_system_group | TC-N07, BC-BIZ-07 | Negative |
| 23 | test_cannot_delete_system_group | TC-N08, BC-BIZ-08 | Negative |
| 24 | test_cannot_delete_group_with_ledgers | TC-N09, BC-BIZ-09, BC-REF-03 | Negative |
| 25 | test_invalid_id_returns_404 | TC-N10, N11, N12 | Negative |
| 26 | test_invalid_id_toggle_returns_404 | TC-N13 | Negative |
| 27 | test_permission_denied_returns_403 | TC-N14, BC-AUTH-01 to 07 | Negative |
| 28 | test_guest_redirect_to_login | TC-N15 | Negative |
| 29 | test_empty_trash_page | TC-N16 | Negative |
| 30 | test_dependency_requires_ledger_module | TC-D01 to D05 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 13 | 13 | 0 | 0 | **100%** |
| Negative | 16 | 16 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 5 | 0 | 0 | 5 | **0%** |
| **Total** | **42** | **29** | **0** | **13** | **69%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 20 | 20 | 0 | **100%** |
| Validation Rules (BC-VAL) | 10 | 10 | 0 | **100%** |
| Authorization (BC-AUTH) | 7 | 7 | 0 | **100%** |
| Business Logic (BC-BIZ) | 31 | 30 | 1 | **97%** |
| Model Scopes/Helpers (BC-MOD) | 6 | 6 | 0 | **100%** |
| Referential Integrity (BC-REF) | 3 | 1 | 2 | **33%** |
| **Total** | **77** | **74** | **3** | **96%** |

### Coverage Notes
- All 29 positive + negative TCs proposed for V2 coverage
- All BC-DB (20/20), BC-VAL (10/10), BC-AUTH (7/7), BC-MOD (6/6) conditions fully covered
- 30/31 BC-BIZ conditions covered (uncovered: BC-BIZ-25 SweetAlert delete confirmation — pending view implementation)
- 5 dependency TCs (TC-D01 to D05) require Ledger module and are marked skipped
- 2 BC-REF conditions (BC-REF-01, BC-REF-03) require cross-module setup — skipped
- DDL gaps documented: Request validation missing `Equity` nature from allowed values (DDL includes 5, Request only 4)
- V2 tests proposed — not yet implemented

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/setup-masters?tab=account-groups | accounting.menu.setupMasters | viewAny |
| GET | /accounting/account-group/create | accounting.account-group.create | create |
| POST | /accounting/account-group | accounting.account-group.store | create |
| GET | /accounting/account-group/{account_group} | accounting.account-group.show | viewAny |
| GET | /accounting/account-group/{account_group}/edit | accounting.account-group.edit | update |
| PUT/PATCH | /accounting/account-group/{account_group} | accounting.account-group.update | update |
| DELETE | /accounting/account-group/{account_group} | accounting.account-group.destroy | delete |
| GET | /accounting/account-group/trash/view | accounting.account-group.trashed | viewAny |
| GET | /accounting/account-group/{id}/restore | accounting.account-group.restore | create |
| DELETE | /accounting/account-group/{id}/force-delete | accounting.account-group.forceDelete | delete |
| POST | /accounting/account-group/{account_group}/toggle-status | accounting.account-group.toggleStatus | update |

---

## 6. Development Issues Found

### 6.1 Validation Gap

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-V01 | AccountGroupRequest.php | Request `nature` validation (`in:asset,liability,income,expense`) excludes DDL ENUM value `Equity`. Groups with nature=Equity cannot be created/edited via the form. | **High** | Open |

### 6.2 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | AccountGroupController.php | Index action redirects to setup-masters — `index.blade.php` is dead code (never rendered). | Low | Open |
| DEV-C02 | AccountGroupController.php | No search logic in controller — search handled entirely via query params on setup-masters view. | Low | Open |

### 6.3 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | migration | `created_by` has no FK constraint to `sys_users`. No referential integrity at DB level. | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | `nature` validation missing `Equity` — DDL supports 5 natures, Request only 4 | Open |
| KN-02 | `index.blade.php` is dead code (never rendered) | Open |
| KN-03 | No search action in controller — handled by view query params | Low |
| KN-04 | No FK constraint on `created_by` column | Open |
