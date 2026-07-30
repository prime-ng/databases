# TallyMapping_TcList

## Module: Accounting → Assets & Integration → Tally Mappings

---

## 1. Business Conditions

### 1.1 Database Schema — acc_tally_ledger_mappings

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | tenant_id | int unsigned | NOT NULL, FK → tenants (CASCADE) |
| BC-DB-03 | tally_ledger_name | varchar(100) | NOT NULL |
| BC-DB-04 | ledger_id | bigint unsigned | FK → acc_ledgers (SET NULL) |
| BC-DB-05 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-06 | mapping_details | json | NULLABLE |
| BC-DB-07 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-08 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-09 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-10 | ENGINE=InnoDB | — | Transaction support |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| No FK on `created_by` | INT UNSIGNED with no FK to sys_users |
| No UNIQUE constraint on tally_ledger_name | Unique per tenant at app layer |
| `ledger_id` FK SET NULL | Allows ledger to be deleted without blocking mapping |
| `mapping_details` | JSON type — no schema enforcement |

### 1.2 Validation Rules (TallyLedgerMappingRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | tally_ledger_name | required, string, max:100 |
| BC-VAL-02 | ledger_id | nullable, exists:acc_ledgers,id |
| BC-VAL-03 | mapping_details | nullable, json |
| BC-VAL-04 | is_active | required, boolean |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.accounting.tally-mapping.viewAny` | `index()`, `show()`, `trashed()` |
| BC-AUTH-02 | `tenant.accounting.tally-mapping.create` | `create()`, `store()`, `restore()` |
| BC-AUTH-03 | `tenant.accounting.tally-mapping.update` | `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-04 | `tenant.accounting.tally-mapping.delete` | `destroy()`, `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: valid data | Mapping created linking Tally ledger name → accounting ledger |
| BC-BIZ-02 | Delete: soft delete | Sets is_active=false then delete() |
| BC-BIZ-03 | Restore: sets is_active=true | After restore, sets is_active=true |
| BC-BIZ-04 | Toggle status (AJAX) | POST → flips is_active → JSON |
| BC-BIZ-05 | Index redirects to assets-integration tab | Redirect to `accounting.menu.assetsIntegration` with `tally-mappings` tab |
| BC-BIZ-06 | Success/error/activity flash messages | Appropriate messages for all CRUD actions |
| BC-BIZ-07 | mapping_details JSON | Flexible storage for extra mapping configuration |

### 1.5 Model

| BC ID | Property | Details |
|-------|----------|---------|
| BC-MOD-01 | SoftDeletes trait | Enabled |
| BC-MOD-02 | Table | acc_tally_ledger_mappings |
| BC-MOD-03 | Fillable | tenant_id, tally_ledger_name, ledger_id, is_active, mapping_details |
| BC-MOD-04 | Casts | mapping_details → array (JSON) |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | tenant_id | tenants | CASCADE |
| BC-REF-02 | ledger_id | acc_ledgers | SET NULL |
| BC-REF-03 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-P01 | List loads via Assets & Integration tab | test_index_page_loads |
| TC-P02 | Create — with ledger and mapping_details | test_create_with_ledger_and_details |
| TC-P03 | Create — without ledger (unmapped) | test_create_without_ledger |
| TC-P04 | Edit — change mapped ledger | test_edit_change_ledger |
| TC-P05 | Edit — update mapping_details JSON | test_edit_update_mapping_details |
| TC-P06 | Toggle active status (AJAX) | test_toggle_active_status |
| TC-P07 | Lifecycle: delete→trash→restore→force delete | test_trash_restore_force_delete |
| TC-P08 | Search by tally_ledger_name | test_search_by_tally_name |

### 2.2 Negative (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-N01 | Create — required fields empty | test_validation_required_fields |
| TC-N02 | Create — invalid ledger_id | test_validation_invalid_ledger |
| TC-N03 | Create — invalid JSON in mapping_details | test_validation_invalid_json |
| TC-N04 | Edit — duplicate tally_ledger_name | test_edit_duplicate_tally_name |
| TC-N05 | Permission denied (403) | test_permission_denied_403 |
| TC-N06 | Guest redirect | test_guest_redirect_to_login |
| TC-N07 | Invalid ID (404) all operations | test_invalid_id_404 |
| TC-N08 | Empty trash page | test_empty_trash_page |

### 2.3 Dependency (2)

| TC ID | Description | Status |
|-------|-------------|--------|
| TC-D01 | FK CASCADE — deleting tenant removes all its tally mappings | ⏸️ |
| TC-D02 | FK SET NULL — deleting ledger sets ledger_id=NULL in mapping | ⏸️ |

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
| Negative | 8 | 8 | 0 | 100% |
| SweetAlert | 8 | 0 | 8 | 0% |
| Dependency | 2 | 0 | 2 | 0% |
| **Total** | **26** | **16** | **10** | **62%** |

---

## 4. Route Reference

| Method | URI | Name |
|--------|-----|------|
| Resource | /accounting/tally-mapping (7 routes) | tally-mapping.* |
| GET | /tally-mapping/trash/view | tally-mapping.trashed |
| GET | /tally-mapping/{id}/restore | tally-mapping.restore |
| DELETE | /tally-mapping/{id}/force-delete | tally-mapping.forceDelete |
| POST | /tally-mapping/{id}/toggle-status | tally-mapping.toggleStatus |

---

## 5. Development Issues

| ID | Issue | Severity |
|----|-------|----------|
| DEV-01 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | **High** |
| DEV-02 | No DB-level FK on `created_by` | Medium |
| DEV-03 | No DB-level unique constraint on tally_ledger_name (enforced only in app) | Medium |
