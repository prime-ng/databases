# TallyExport_TcList

## Module: Accounting → Assets & Integration → Tally Export

---

## 1. Business Conditions

### 1.1 Database Schema — acc_tally_export_logs

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | export_type | varchar(50) | NOT NULL |
| BC-DB-03 | status | varchar(20) | NOT NULL, DEFAULT 'pending' |
| BC-DB-04 | total_vouchers | int | DEFAULT 0 |
| BC-DB-05 | successful_vouchers | int | DEFAULT 0 |
| BC-DB-06 | failed_vouchers | int | DEFAULT 0 |
| BC-DB-07 | xml_content | longtext | NULLABLE |
| BC-DB-08 | error_message | text | NULLABLE |
| BC-DB-09 | exported_by | int unsigned | NOT NULL, FK → sys_users (no DB FK) |
| BC-DB-10 | exported_at | timestamp | NULLABLE |
| BC-DB-11 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-12 | ENGINE=InnoDB | — | Transaction support |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| No FK on `exported_by` | INT UNSIGNED with no FK to sys_users |
| No CHECK constraint | status enum values enforced only in app layer |
| No status ENUM | status as varchar(20) instead of enum |

### 1.2 Validation Rules (TallyExportRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | export_type | required, string, in:vouchers,ledgers,stock |
| BC-VAL-02 | from_date | required, date, before:to_date |
| BC-VAL-03 | to_date | required, date, after:from_date |
| BC-VAL-04 | voucher_type_ids | nullable, array |
| BC-VAL-05 | voucher_type_ids.* | exists:acc_voucher_types,id |
| BC-VAL-06 | ledger_ids | nullable, array |
| BC-VAL-07 | ledger_ids.* | exists:acc_ledgers,id |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.accounting.tally-export.viewAny` | `index()`, `show()` |
| BC-AUTH-02 | `tenant.accounting.tally-export.create` | `create()`, `store()` |
| BC-AUTH-03 | `tenant.accounting.tally-export.update` | `edit()`, `update()` |
| BC-AUTH-04 | `tenant.accounting.tally-export.delete` | `destroy()`, `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Export: vouchers type | Generates XML for vouchers in date range, optionally filtered by type |
| BC-BIZ-02 | Export: ledgers type | Generates XML for ledgers in date range |
| BC-BIZ-03 | Export: stock type | Generates XML for stock items |
| BC-BIZ-04 | Export: date range validation | from_date must be before to_date |
| BC-BIZ-05 | Export: log created | TallyExportLog created with status=processing → completed/failed |
| BC-BIZ-06 | Export: large dataset | Should handle pagination/chunking (not yet implemented — risk) |
| BC-BIZ-07 | Show: XML content | Shows the generated XML in a formatted view |
| BC-BIZ-08 | Index redirects to assets-integration tab | Redirect to `accounting.menu.assetsIntegration` with `tally-export` tab |
| BC-BIZ-09 | Success/error flash messages | Appropriate messages for export start/completion/failure |

### 1.5 Model

| BC ID | Property | Details |
|-------|----------|---------|
| BC-MOD-01 | Table | acc_tally_export_logs |
| BC-MOD-02 | Fillable | export_type, status, total_vouchers, successful_vouchers, failed_vouchers, xml_content, error_message, exported_by, exported_at |
| BC-MOD-03 | Tally Export Service | XML generation logic (voucher/ledger/stock exporters) |

### 1.6 Export Types

| BC ID | Type | Content Generated |
|-------|------|-------------------|
| BC-EXP-01 | vouchers | TALLYXML with VOUCHER entries in date range, filtered by voucher_type_ids |
| BC-EXP-02 | ledgers | TALLYXML with LEDGER entries |
| BC-EXP-03 | stock | TALLYXML with STOCK entries |

---

## 2. Test Case List

### 2.1 Positive (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-P01 | List loads via Assets & Integration tab | test_index_page_loads |
| TC-P02 | Export — vouchers (full range, no filter) | test_export_vouchers_all |
| TC-P03 | Export — vouchers filtered by voucher_type_ids | test_export_vouchers_by_type |
| TC-P04 | Export — ledgers | test_export_ledgers |
| TC-P05 | Export — stock | test_export_stock |
| TC-P06 | Show — view export log with XML | test_show_export_log |
| TC-P07 | Export log status progression | test_export_status_progression |
| TC-P08 | Search export logs by type/date/status | test_search_export_logs |

### 2.2 Negative (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-N01 | Create — required fields empty | test_validation_required_fields |
| TC-N02 | Create — from_date after to_date | test_validation_date_order |
| TC-N03 | Create — invalid export_type | test_validation_invalid_type |
| TC-N04 | Create — invalid voucher_type_ids | test_validation_invalid_voucher_type |
| TC-N05 | Create — invalid ledger_ids | test_validation_invalid_ledger |
| TC-N06 | Delete — export log with completed status | test_delete_completed_log |
| TC-N07 | Permission denied (403) | test_permission_denied_403 |
| TC-N08 | Guest redirect | test_guest_redirect_to_login |

### 2.3 Dependency (1)

| TC ID | Description | Status |
|-------|-------------|--------|
| TC-D01 | Large dataset — verify no timeout/chunking | ⏸️ |

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
| Dependency | 1 | 0 | 1 | 0% |
| **Total** | **25** | **16** | **9** | **64%** |

---

## 4. Route Reference

| Method | URI | Name |
|--------|-----|------|
| Resource | /accounting/tally-export (7 routes) | tally-export.* |
| GET | /tally-export/trash/view | tally-export.trashed |
| GET | /tally-export/{id}/restore | tally-export.restore |
| DELETE | /tally-export/{id}/force-delete | tally-export.forceDelete |
| POST | /tally-export/{id}/toggle-status | tally-export.toggleStatus |

---

## 5. Development Issues

| ID | Issue | Severity |
|----|-------|----------|
| DEV-01 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | **High** |
| DEV-02 | No DB-level FK on `exported_by` | Medium |
| DEV-03 | Large export datasets may cause timeout — no chunking/pagination in XML generation | **High** |
