# FixedAsset_TcList

## Module: Accounting → Assets & Integration → Fixed Assets

---

## 1. Business Conditions

### 1.1 Database Schema — acc_fixed_assets

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | asset_category_id | bigint unsigned | FK → acc_asset_categories (RESTRICT) |
| BC-DB-03 | name | varchar(200) | NOT NULL |
| BC-DB-04 | asset_code | varchar(50) | NOT NULL, UNIQUE (asset_code, deleted_at) |
| BC-DB-05 | purchase_date | date | NOT NULL |
| BC-DB-06 | purchase_cost | decimal(15,2) | NOT NULL, DEFAULT 0.00 |
| BC-DB-07 | salvage_value | decimal(15,2) | DEFAULT 0.00 |
| BC-DB-08 | current_book_value | decimal(15,2) | NOT NULL, DEFAULT 0.00 |
| BC-DB-09 | depreciation_method | enum('SLM','WDV') | NOT NULL |
| BC-DB-10 | depreciation_rate | decimal(5,2) | NOT NULL |
| BC-DB-11 | useful_life_years | int | NULLABLE |
| BC-DB-12 | purchase_description | text | NULLABLE |
| BC-DB-13 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-14 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-15 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-16 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-17 | ENGINE=InnoDB | — | Transaction support |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| No FK on `created_by` | INT UNSIGNED with no FK to sys_users |
| No CHECK constraint | purchase_cost >= 0, salvage_value >= 0, depreciation_rate 0-100 only at app layer |
| Unique index on `asset_code` | composite with deleted_at — unique soft-delete enforcement |

### 1.2 Validation Rules (FixedAssetRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | asset_category_id | required, exists:acc_asset_categories,id |
| BC-VAL-02 | name | required, string, max:200 |
| BC-VAL-03 | asset_code | required, string, max:50, unique (acc_fixed_assets, ignore current, whereNull:deleted_at) |
| BC-VAL-04 | purchase_date | required, date, before or equal:today |
| BC-VAL-05 | purchase_cost | required, numeric, min:0, max:9999999999999.99 |
| BC-VAL-06 | salvage_value | required, numeric, min:0 |
| BC-VAL-07 | depreciation_method | required, in:SLM,WDV |
| BC-VAL-08 | depreciation_rate | required, numeric, min:0.01, max:100 |
| BC-VAL-09 | useful_life_years | nullable, integer, min:1 |
| BC-VAL-10 | purchase_description | nullable, string |
| BC-VAL-11 | is_active | required, boolean |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.accounting.fixed-asset.viewAny` | `index()`, `show()`, `trashed()` |
| BC-AUTH-02 | `tenant.accounting.fixed-asset.create` | `create()`, `store()`, `restore()` |
| BC-AUTH-03 | `tenant.accounting.fixed-asset.update` | `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-04 | `tenant.accounting.fixed-asset.delete` | `destroy()`, `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: initial values | `current_book_value = purchase_cost` on creation |
| BC-BIZ-02 | Delete: blocks if depreciation exists | `isDeletable()` returns false if depreciation entries reference this asset |
| BC-BIZ-03 | Delete: soft delete + is_active=false | Sets is_active=false then delete() |
| BC-BIZ-04 | Restore: sets is_active=true | After restore, sets is_active=true |
| BC-BIZ-05 | Toggle status (AJAX) | POST → flips is_active → JSON |
| BC-BIZ-06 | Index redirects to assets-integration tab | Redirect to `accounting.menu.assetsIntegration` with `fixed-assets` tab |
| BC-BIZ-07 | Success/error/activity flash messages | Appropriate messages for all CRUD actions |

### 1.5 Model Helpers

| BC ID | Helper | Logic |
|-------|--------|-------|
| BC-MOD-01 | `isSLM(): bool` | `depreciation_method === 'SLM'` |
| BC-MOD-02 | `isWDV(): bool` | `depreciation_method === 'WDV'` |
| BC-MOD-03 | `isDeletable(): bool` | `$this->depreciationEntries()->count() === 0` |
| BC-MOD-04 | `category(): BelongsTo` | AssetCategory with trashed |
| BC-MOD-05 | `depreciationEntries(): HasMany` | DepreciationEntry |

### 1.6 Relationships

| BC ID | Related Model | Type | Foreign Key |
|-------|--------------|------|-------------|
| BC-REL-01 | AssetCategory | BelongsTo | asset_category_id |
| BC-REL-02 | DepreciationEntry | HasMany | asset_id |

### 1.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | asset_category_id | acc_asset_categories | RESTRICT |
| BC-REF-02 | asset_id (depreciation_entries) | acc_fixed_assets | RESTRICT |
| BC-REF-03 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive (10)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-P01 | List loads via Assets & Integration tab | test_index_page_loads |
| TC-P02 | Create — SLM with full data | test_create_slm_asset |
| TC-P03 | Create — WDV with full data | test_create_wdv_asset |
| TC-P04 | Create — current_book_value = purchase_cost | test_initial_book_value_equals_cost |
| TC-P05 | Create — salvage_value = 0 | test_create_with_zero_salvage |
| TC-P06 | Edit — update cost/rate/method | test_edit_update_fields |
| TC-P07 | Toggle active status (AJAX) | test_toggle_active_status |
| TC-P08 | Show — view asset details | test_show_asset_details |
| TC-P09 | Lifecycle: delete→trash→restore→force delete | test_trash_restore_force_delete |
| TC-P10 | Search by name/code/category | test_search_assets |

### 2.2 Negative (16)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-N01 | Create — required fields empty | test_validation_required_fields |
| TC-N02 | Create — duplicate asset_code | test_validation_duplicate_code |
| TC-N03 | Create — purchase_date in future | test_validation_future_date |
| TC-N04 | Create — purchase_cost negative | test_validation_negative_cost |
| TC-N05 | Create — purchase_cost zero | test_validation_zero_cost |
| TC-N06 | Create — salvage_value negative | test_validation_negative_salvage |
| TC-N07 | Create — invalid depreciation method | test_validation_invalid_method |
| TC-N08 | Create — rate = 0 | test_validation_rate_zero |
| TC-N09 | Create — rate > 100 | test_validation_rate_over_100 |
| TC-N10 | Create — non-existent category_id | test_validation_invalid_category |
| TC-N11 | Edit — duplicate code on update | test_edit_duplicate_code |
| TC-N12 | Delete — asset with depreciation entries | test_cannot_delete_with_depreciation |
| TC-N13 | Permission denied (403) | test_permission_denied_403 |
| TC-N14 | Guest redirect | test_guest_redirect_to_login |
| TC-N15 | Invalid ID (404) all operations | test_invalid_id_404 |
| TC-N16 | Empty trash page | test_empty_trash_page |

### 2.3 Dependency (2)

| TC ID | Description | Status |
|-------|-------------|--------|
| TC-D01 | FK RESTRICT — cannot delete category if assets reference it | ⏸️ |
| TC-D02 | FK RESTRICT — cannot delete asset if depreciation entries exist | ⏸️ |

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
| Positive | 10 | 10 | 0 | 100% |
| Negative | 16 | 16 | 0 | 100% |
| SweetAlert | 8 | 0 | 8 | 0% |
| Dependency | 2 | 0 | 2 | 0% |
| **Total** | **36** | **26** | **10** | **72%** |

---

## 4. Route Reference

| Method | URI | Name |
|--------|-----|------|
| Resource | /accounting/fixed-asset (7 routes) | fixed-asset.* |
| GET | /fixed-asset/trash/view | fixed-asset.trashed |
| GET | /fixed-asset/{id}/restore | fixed-asset.restore |
| DELETE | /fixed-asset/{id}/force-delete | fixed-asset.forceDelete |
| POST | /fixed-asset/{id}/toggle-status | fixed-asset.toggleStatus |

---

## 5. Development Issues

| ID | Issue | Severity |
|----|-------|----------|
| DEV-01 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | **High** |
| DEV-02 | No DB-level FK on `created_by` | Medium |
