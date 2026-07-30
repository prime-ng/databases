# AssetCategory_TcList

## Module: Accounting → Assets & Integration → Asset Categories

---

## 1. Business Conditions

### 1.1 Database Schema — acc_asset_categories

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(100) | NOT NULL |
| BC-DB-03 | code | varchar(20) | NOT NULL, UNIQUE (code, deleted_at) |
| BC-DB-04 | depreciation_method | enum('SLM','WDV') | NOT NULL |
| BC-DB-05 | depreciation_rate | decimal(5,2) | NOT NULL |
| BC-DB-06 | useful_life_years | int | NULLABLE |
| BC-DB-07 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-08 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-09 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-10 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-11 | ENGINE=InnoDB | — | Transaction support |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| **Missing ledger columns** | `depreciation_expense_ledger_id` and `accumulated_depreciation_ledger_id` used by DepreciationService but absent from DDL. Will crash with DomainException on depreciation run. |
| No FK on `created_by` | INT UNSIGNED with no FK to sys_users |
| No CHECK constraint | depreciation_rate 0-100 only at application layer |

### 1.2 Validation Rules (AssetCategoryRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | name | required, string, max:100 |
| BC-VAL-02 | code | required, string, max:20, unique (acc_asset_categories, ignore current, whereNull:deleted_at) |
| BC-VAL-03 | depreciation_method | required, in:SLM,WDV |
| BC-VAL-04 | depreciation_rate | required, numeric, min:0, max:100 |
| BC-VAL-05 | useful_life_years | nullable, integer, min:1 |
| BC-VAL-06 | is_active | required, boolean |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.accounting.asset-category.viewAny` | `index()`, `show()`, `trashed()` |
| BC-AUTH-02 | `tenant.accounting.asset-category.create` | `create()`, `store()`, `restore()` |
| BC-AUTH-03 | `tenant.accounting.asset-category.update` | `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-04 | `tenant.accounting.asset-category.delete` | `destroy()`, `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: valid data | Category created with SLM/WDV, rate, unique code |
| BC-BIZ-02 | Delete: blocks if assets exist | `isDeletable()` returns false if fixed assets reference this category → error flash |
| BC-BIZ-03 | Delete: soft delete + is_active=false | Sets is_active=false then delete() |
| BC-BIZ-04 | Restore: sets is_active=true | After restore, sets is_active=true |
| BC-BIZ-05 | Toggle status (AJAX) | POST → flips is_active → JSON |
| BC-BIZ-06 | Index redirects to assets-integration tab | Redirect to `route('accounting.menu.assetsIntegration', ['tab' => 'asset-categories'])` |
| BC-BIZ-07 | Success/error/activity flash messages | Appropriate messages for all CRUD actions |

### 1.5 Model Helpers

| BC ID | Helper | Logic |
|-------|--------|-------|
| BC-MOD-01 | `isSLM(): bool` | `depreciation_method === 'SLM'` |
| BC-MOD-02 | `isWDV(): bool` | `depreciation_method === 'WDV'` |
| BC-MOD-03 | `isDeletable(): bool` | `$this->fixedAssets()->count() === 0` |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | asset_category_id (fixed_assets) | acc_asset_categories (id) | RESTRICT |
| BC-REF-02 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-P01 | List loads via Assets & Integration tab | test_index_page_loads |
| TC-P02 | Create — SLM with valid data | test_create_slm_category |
| TC-P03 | Create — WDV with valid data | test_create_wdv_category |
| TC-P04 | Create — with useful_life_years | test_create_with_useful_life |
| TC-P05 | Edit — update name/rate/method | test_edit_update_fields |
| TC-P06 | Toggle active status (AJAX) | test_toggle_active_status |
| TC-P07 | Lifecycle: delete→trash→restore→force delete | test_trash_restore_force_delete |
| TC-P08 | Search by name | test_search_categories |

### 2.2 Negative (12)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-N01 | Create — required fields empty | test_validation_required_fields |
| TC-N02 | Create — duplicate code | test_validation_duplicate_code |
| TC-N03 | Create — invalid depreciation method | test_validation_invalid_method |
| TC-N04 | Create — rate > 100 | test_validation_rate_over_100 |
| TC-N05 | Create — rate negative | test_validation_rate_negative |
| TC-N06 | Create — name max length 101 | test_validation_name_max_length |
| TC-N07 | Edit — duplicate code on update | test_edit_duplicate_code |
| TC-N08 | Delete — category with fixed assets | test_cannot_delete_with_assets |
| TC-N09 | Permission denied (403) | test_permission_denied_403 |
| TC-N10 | Guest redirect | test_guest_redirect_to_login |
| TC-N11 | Invalid ID (404) all operations | test_invalid_id_404 |
| TC-N12 | Empty trash page | test_empty_trash_page |

### 2.3 Dependency (2)

| TC ID | Description | Status |
|-------|-------------|--------|
| TC-D01 | FK RESTRICT — cannot delete category with fixed assets | ⏸️ |
| TC-D02 | Depreciation uses category ledger IDs | ⏸️ |

---

### 2.4 SweetAlert Confirmation Test Cases

| TC ID | Description | V2 Test | Status |
|-------|-------------|---------|--------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | test_sweet_alert_edit_confirm | 🔴 |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes record | test_sweet_alert_delete_confirm | 🔴 |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | test_sweet_alert_delete_cancel | 🔴 |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | test_sweet_alert_force_delete_confirm | 🔴 |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | test_sweet_alert_force_delete_cancel | 🔴 |
| TC-SW06 | Restore — SweetAlert confirm restores record | test_sweet_alert_restore_confirm | 🔴 |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | test_sweet_alert_restore_cancel | 🔴 |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | test_sweet_alert_toggle_confirm | 🔴 |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 8 | 8 | 0 | 100% |
| Negative | 12 | 12 | 0 | 100% |
| SweetAlert | 8 | 0 | 8 | 0% |
| Dependency | 2 | 0 | 2 | 0% |
| **Total** | **30** | **20** | **10** | **67%** |

---

## 4. Route Reference

| Method | URI | Name |
|--------|-----|------|
| Resource | /accounting/asset-category (7 routes) | asset-category.* |
| GET | /asset-category/trash/view | asset-category.trashed |
| GET | /asset-category/{id}/restore | asset-category.restore |
| DELETE | /asset-category/{id}/force-delete | asset-category.forceDelete |
| POST | /asset-category/{id}/toggle-status | asset-category.toggleStatus |

---

## 5. Development Issues

| ID | Issue | Severity |
|----|-------|----------|
| DEV-01 | `depreciation_expense_ledger_id` and `accumulated_depreciation_ledger_id` columns missing from DDL — DepreciationService will crash | **Critical** |
| DEV-02 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | **High** |
| DEV-03 | No DB-level FK on `created_by` | Medium |
