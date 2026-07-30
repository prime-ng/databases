# LedgerMapping_TcList

## Module: Accounting → Assets & Integration → Ledger Mappings

---

## 1. Business Conditions

### 1.1 Database Schema — acc_ledger_mappings

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | mapping_type | varchar(50) | NOT NULL, UNIQUE (mapping_type, deleted_at) |
| BC-DB-03 | mapping_label | varchar(100) | NOT NULL |
| BC-DB-04 | ledger_id | bigint unsigned | FK → acc_ledgers (SET NULL) |
| BC-DB-05 | is_cash_ledger | tinyint(1) | DEFAULT 0 |
| BC-DB-06 | description | text | NULLABLE |
| BC-DB-07 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-08 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-09 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-10 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-11 | ENGINE=InnoDB | — | Transaction support |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| No FK on `created_by` | INT UNSIGNED with no FK to sys_users |
| No UNIQUE constraint on `mapping_type` composite with deleted_at without ledger_id | But app enforces unique mapping_type |
| `ledger_id` FK SET NULL | Allows ledger to be deleted without blocking mapping |

### 1.2 Validation Rules (LedgerMappingRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | mapping_type | required, string, max:50, unique (acc_ledger_mappings, ignore current, whereNull:deleted_at) |
| BC-VAL-02 | mapping_label | required, string, max:100 |
| BC-VAL-03 | ledger_id | nullable, exists:acc_ledgers,id |
| BC-VAL-04 | is_cash_ledger | required, boolean |
| BC-VAL-05 | description | nullable, string |
| BC-VAL-06 | is_active | required, boolean |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.accounting.ledger-mapping.viewAny` | `index()`, `show()`, `trashed()` |
| BC-AUTH-02 | `tenant.accounting.ledger-mapping.create` | `create()`, `store()`, `restore()` |
| BC-AUTH-03 | `tenant.accounting.ledger-mapping.update` | `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-04 | `tenant.accounting.ledger-mapping.delete` | `destroy()`, `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: valid data | Mapping created with unique mapping_type + optional ledger |
| BC-BIZ-02 | Create: mapping_type = system reserved | No system guard visible — all types seem editable |
| BC-BIZ-03 | Delete: soft delete | Sets is_active=false then delete() |
| BC-BIZ-04 | Restore: sets is_active=true | After restore, sets is_active=true |
| BC-BIZ-05 | Toggle status (AJAX) | POST → flips is_active → JSON |
| BC-BIZ-06 | Index redirects to assets-integration tab | Redirect to `accounting.menu.assetsIntegration` with `ledger-mappings` tab |
| BC-BIZ-07 | Success/error/activity flash messages | Appropriate messages for all CRUD actions |
| BC-BIZ-08 | is_cash_ledger flag | Distinguishes cash vs non-cash ledger mapping |

### 1.5 Model

| BC ID | Property | Details |
|-------|----------|---------|
| BC-MOD-01 | SoftDeletes trait | Enabled |
| BC-MOD-02 | Table | acc_ledger_mappings |
| BC-MOD-03 | Fillable | mapping_type, mapping_label, ledger_id, is_cash_ledger, description, is_active |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | ledger_id | acc_ledgers | SET NULL |
| BC-REF-02 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive (9)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-P01 | List loads via Assets & Integration tab | test_index_page_loads |
| TC-P02 | Create — with ledger_id | test_create_with_ledger |
| TC-P03 | Create — with NULL ledger (unmapped) | test_create_without_ledger |
| TC-P04 | Create — is_cash_ledger = true | test_create_cash_ledger_mapping |
| TC-P05 | Edit — change mapped ledger | test_edit_change_ledger |
| TC-P06 | Toggle active status (AJAX) | test_toggle_active_status |
| TC-P07 | Lifecycle: delete→trash→restore→force delete | test_trash_restore_force_delete |
| TC-P08 | Show — view mapping details | test_show_mapping_details |
| TC-P09 | Search by mapping_type/label | test_search_mappings |

### 2.2 Negative (11)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-N01 | Create — required fields empty | test_validation_required_fields |
| TC-N02 | Create — duplicate mapping_type | test_validation_duplicate_type |
| TC-N03 | Create — mapping_type max length 51 | test_validation_type_max_length |
| TC-N04 | Create — invalid ledger_id | test_validation_invalid_ledger |
| TC-N05 | Edit — duplicate mapping_type on update | test_edit_duplicate_type |
| TC-N06 | Delete — mapping in use by system | test_cannot_delete_system_mapping (if guard exists) |
| TC-N07 | Permission denied (403) | test_permission_denied_403 |
| TC-N08 | Guest redirect | test_guest_redirect_to_login |
| TC-N09 | Invalid ID (404) all operations | test_invalid_id_404 |
| TC-N10 | Empty trash page | test_empty_trash_page |
| TC-N11 | is_cash_ledger not boolean | test_validation_invalid_cash_flag |

### 2.3 Dependency (1)

| TC ID | Description | Status |
|-------|-------------|--------|
| TC-D01 | FK SET NULL — deleting ledger sets ledger_id=NULL in mapping | ⏸️ |

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
| Positive | 9 | 9 | 0 | 100% |
| Negative | 11 | 11 | 0 | 100% |
| SweetAlert | 8 | 0 | 8 | 0% |
| Dependency | 1 | 0 | 1 | 0% |
| **Total** | **29** | **20** | **9** | **69%** |

---

## 4. Route Reference

| Method | URI | Name |
|--------|-----|------|
| Resource | /accounting/ledger-mapping (7 routes) | ledger-mapping.* |
| GET | /ledger-mapping/trash/view | ledger-mapping.trashed |
| GET | /ledger-mapping/{id}/restore | ledger-mapping.restore |
| DELETE | /ledger-mapping/{id}/force-delete | ledger-mapping.forceDelete |
| POST | /ledger-mapping/{id}/toggle-status | ledger-mapping.toggleStatus |

---

## 5. Development Issues

| ID | Issue | Severity |
|----|-------|----------|
| DEV-01 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | **High** |
| DEV-02 | No DB-level FK on `created_by` | Medium |
