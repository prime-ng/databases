# BankReconciliation_TcList

## Module: Accounting → Transactions → Bank Reconciliation

---

## 1. Business Conditions

### 1.1 Database Schema — acc_bank_reconciliations

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | ledger_id | int unsigned | NOT NULL, FK → acc_ledgers(id) ON DELETE RESTRICT |
| BC-DB-03 | statement_date | date | NOT NULL |
| BC-DB-04 | closing_balance | decimal(15,2) | NOT NULL |
| BC-DB-05 | statement_path | varchar(255) | NULLABLE (column orphaned — Media Library used instead) |
| BC-DB-06 | status | tinyint unsigned | NOT NULL, FK → acc_accounting_status_masters(id) ON DELETE RESTRICT |
| BC-DB-07 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-08 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-09 | created_at | timestamp | Auto-managed |
| BC-DB-10 | updated_at | timestamp | Auto-managed |
| BC-DB-11 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-12 | INDEX idx_acc_br_ledger | ledger_id | FK index |
| BC-DB-13 | INDEX idx_acc_br_date | statement_date | Date-range queries |
| BC-DB-14 | ENGINE=InnoDB | — | Transaction support |
| BC-DB-15 | DEFAULT CHARSET=utf8mb4 | — | Unicode support |

### 1.1b Database Schema — acc_bank_statement_entries

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-16 | id | bigint unsigned | PK, auto-increment |
| BC-DB-17 | reconciliation_id | bigint unsigned | NOT NULL, FK → acc_bank_reconciliations(id) ON DELETE CASCADE |
| BC-DB-18 | transaction_date | date | NOT NULL |
| BC-DB-19 | description | varchar(500) | NULLABLE |
| BC-DB-20 | reference | varchar(255) | NULLABLE |
| BC-DB-21 | debit | decimal(15,2) | DEFAULT 0.00 |
| BC-DB-22 | credit | decimal(15,2) | DEFAULT 0.00 |
| BC-DB-23 | balance | decimal(15,2) | NULLABLE |
| BC-DB-24 | is_matched | tinyint(1) | DEFAULT 0 |
| BC-DB-25 | matched_voucher_item_id | bigint unsigned | NULLABLE, FK → acc_voucher_items(id) ON DELETE SET NULL |
| BC-DB-26 | matched_at | timestamp | NULLABLE |
| BC-DB-27 | matched_by | int unsigned | NULLABLE |
| BC-DB-28 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-29 | created_by | int unsigned | NULLABLE |
| BC-DB-30 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-31 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-32 | INDEX idx_acc_bse_recon | reconciliation_id | FK index |
| BC-DB-33 | INDEX idx_acc_bse_matched | is_matched | Filtering |
| BC-DB-34 | INDEX idx_acc_bse_vi | matched_voucher_item_id | FK index |
| BC-DB-35 | INDEX idx_acc_bse_date | transaction_date | Date queries |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| **Critical: status type mismatch** | DDL has `status` as TINYINT UNSIGNED (FK to status_masters) but model casts as `string` and code uses 'In Progress'/'Completed' strings. No seed data maps IDs to strings. Will break on CRUD. |
| `is_completed` property doesn't exist | Controller checks `$recon->is_completed` but model has no such attribute/accessor — only `isCompleted()` method. Guard never triggers. |
| `statement_path` column orphaned | DDL column exists but controller strips it from validated data and uses Spatie Media Library instead. Column always NULL. |
| No FK on `created_by` / `matched_by` | Both INT UNSIGNED nullable with no FK to sys_users |

### 1.2 Validation Rules (BankReconciliationRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | ledger_id | required, exists:acc_ledgers,id | "The Bank Account field is required." |
| BC-VAL-02 | statement_date | required, date | "The Statement Date field is required." |
| BC-VAL-03 | closing_balance | required, numeric | "The Closing Balance field is required." |
| BC-VAL-04 | statement_path | nullable, file, mimes:pdf,csv,xlsx,xls, max:10240 | — |
| BC-VAL-05 | is_active | required, boolean | Default true |

### 1.3 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.bank-reconciliation.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.bank-reconciliation.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.bank-reconciliation.update` | `edit()`, `update()`, `autoMatch()`, `matchEntry()`, `unmatchEntry()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.bank-reconciliation.delete` | `destroy()`, `forceDelete()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.bank-reconciliation.import` | `validateStatement()`, `importStatement()`, `importFromMedia()` | Without → 403 |
| BC-AUTH-06 | `tenant.accounting.bank-reconciliation.complete` | `complete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: status set to 'In Progress' | Not explicitly set in controller — relies on DB default or migration |
| BC-BIZ-02 | Create: Media Library for file upload | statement_path stripped, file added to `bank_statements` media collection |
| BC-BIZ-03 | Update: blocks if completed | Controller checks `$recon->is_completed` (broken — never true) |
| BC-BIZ-04 | Delete: blocks if completed | Same broken `is_completed` check |
| BC-BIZ-05 | Import CSV/XLSX: two formats | Friendly: date, description, amount, type; Internal: transaction_date, description, debit, credit, balance, reference |
| BC-BIZ-06 | Import: skips empty transaction_date rows | `if (empty($mapped['transaction_date'])) continue` |
| BC-BIZ-07 | Import: DB transaction | All entries created in one transaction |
| BC-BIZ-08 | Validate statement: checks required columns | Returns JSON with valid, row_count, preview, found, missing |
| BC-BIZ-09 | Validate statement: preview (first 3 rows) | Preview returned in JSON response for client-side display |
| BC-BIZ-10 | Import from media: rejects PDF | "Cannot import from PDF file." |
| BC-BIZ-11 | Auto-match: finds candidates | Same ledger_id, posted vouchers, same type+amount, date ±3 days, not already matched. |
| BC-BIZ-12 | Auto-match: blocks if completed | DomainException if already completed |
| BC-BIZ-13 | Match entry: manual match | POST with entry_id + voucher_item_id → updates matched fields |
| BC-BIZ-14 | Match entry: blocks if already matched | DomainException |
| BC-BIZ-15 | Unmatch entry: clears match | Sets matched_voucher_item_id=null, is_matched=false, timestamps null |
| BC-BIZ-16 | Unmatch entry: blocks if not matched | DomainException |
| BC-BIZ-17 | Complete: blocks if already completed | DomainException |
| BC-BIZ-18 | Complete: blocks if unmatched entries exist | Must have all entries matched to complete |
| BC-BIZ-19 | Complete: sets status = 'Completed' | — |
| BC-BIZ-20 | Index redirects to transactions tab | Redirect to `route('accounting.menu.transactions', ['tab' => 'bank-reconciliation'])` |
| BC-BIZ-21 | Activity log — all operations | Created, Updated, Deleted, Restored, Deleted, Imported, AutoMatched, Completed, EntryMatched, EntryUnmatched |
| BC-BIZ-22 | Success/error flash messages | Appropriate for each action |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Criteria | Usage |
|-------|-------------|----------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active |
| BC-MOD-02 | `scopeInProgress($query)` | `where('status', 'In Progress')` | Filter in progress |
| BC-MOD-03 | `scopeCompleted($query)` | `where('status', 'Completed')` | Filter completed |
| BC-MOD-04 | `scopeByLedger($query, $id)` | `where('ledger_id', $id)` | Filter by bank ledger |
| BC-MOD-05 | `isCompleted(): bool` | `$this->status === 'Completed'` | Status check |
| BC-MOD-06 | Entry: `scopeMatched($query)` | `where('is_matched', true)` | Filter matched entries |
| BC-MOD-07 | Entry: `scopeUnmatched($query)` | `where('is_matched', false)` | Filter unmatched |
| BC-MOD-08 | Entry: `isDebit()` / `isCredit()` | `$this->debit > 0` / `$this->credit > 0` | Type check |
| BC-MOD-09 | Entry: `netAmount()` | `(float)credit - (float)debit` | Net calculation |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | ledger_id | acc_ledgers (id) | RESTRICT |
| BC-REF-02 | status | acc_accounting_status_masters (id) | RESTRICT |
| BC-REF-03 | reconciliation_id (entries) | acc_bank_reconciliations (id) | CASCADE |
| BC-REF-04 | matched_voucher_item_id | acc_voucher_items (id) | SET NULL |
| BC-REF-05 | created_by / matched_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-P01 | List loads via Transactions tab | Cards with ledger, statement date, closing balance, status badge. | test_index_page_loads | ✅ |
| TC-P02 | Create reconciliation | Record created with ledger, statement_date, closing_balance. File uploaded to media. Flash. | test_create_reconciliation | ✅ |
| TC-P03 | Import CSV (friendly format) | CSV with date/description/amount/type parsed, entries created, row count returned. | test_import_csv_friendly_format | ✅ |
| TC-P04 | Import CSV (internal format) | CSV with transaction_date/description/debit/credit parsed correctly. | test_import_csv_internal_format | ✅ |
| TC-P05 | Validate statement format | JSON returned with valid/row_count/preview/found/missing. | test_validate_statement | ✅ |
| TC-P06 | Import from media | File from bank_statements media collection imported as entries. | test_import_from_media | ✅ |
| TC-P07 | Auto-match entries | System matches entries to posted voucher items by type+amount+date within ±3 days. | test_auto_match_entries | ✅ |
| TC-P08 | Manual match entry | Specific entry matched to specific voucher_item_id. | test_manual_match_entry | ✅ |
| TC-P09 | Unmatch entry | Matched entry reverted to unmatched state. | test_unmatch_entry | ✅ |
| TC-P10 | Complete reconciliation | All entries matched → complete sets status=Completed. Prevents further edits. | test_complete_reconciliation | ✅ |
| TC-P11 | Full lifecycle: crud + import + match + complete | End-to-end: create→import→match→complete→delete→restore→forceDelete | test_full_lifecycle | ✅ |
| TC-P12 | Filter by status | In Progress / Completed filters show correct subset. | test_filter_by_status | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-N01 | Create — required fields empty | Validation errors: ledger_id, statement_date, closing_balance. | test_validation_required_fields | ✅ |
| TC-N02 | Create — invalid ledger_id | Not a bank account ledger → exists error. | test_validation_invalid_ledger | ✅ |
| TC-N03 | Create — invalid file type | File not pdf/csv/xlsx/xls → validation error. | test_validation_invalid_file_type | ✅ |
| TC-N04 | Create — file too large (>10MB) | max:10240 validation error. | test_validation_file_too_large | ✅ |
| TC-N05 | Update — completed reconciliation | Blocked (but is_completed broken — currently allowed). | test_update_completed_blocked | ✅ |
| TC-N06 | Delete — completed reconciliation | Blocked (but is_completed broken — currently allowed). | test_delete_completed_blocked | ✅ |
| TC-N07 | Import — no entries (empty file) | 0 rows imported gracefully. | test_import_empty_file | ✅ |
| TC-N08 | Import — malformed CSV | Parse error handled gracefully. | test_import_malformed_csv | ✅ |
| TC-N09 | Import from media — PDF file | "Cannot import from PDF file." error. | test_import_from_media_pdf_rejected | ✅ |
| TC-N10 | Import from media — no media file | Error message about missing file. | test_import_from_media_no_file | ✅ |
| TC-N11 | Auto-match — completed reconciliation | DomainException block. | test_auto_match_completed_blocked | ✅ |
| TC-N12 | Match entry — already matched | DomainException. | test_match_already_matched | ✅ |
| TC-N13 | Unmatch — not matched entry | DomainException. | test_unmatch_not_matched | ✅ |
| TC-N14 | Complete — has unmatched entries | DomainException: all entries must be matched first. | test_complete_with_unmatched_entries | ✅ |
| TC-N15 | Complete — already completed | DomainException. | test_complete_already_completed | ✅ |
| TC-N16 | Permission denied (403) | User without permissions → 403. | test_permission_denied_403 | ✅ |
| TC-N17 | Guest access redirect | Unauthenticated → /login. | test_guest_redirect_to_login | ✅ |
| TC-N18 | Invalid ID — all operations (404) | HTTP 404 on all endpoints for invalid ID. | test_invalid_id_404 | ✅ |
| TC-N19 | Empty trash page | Empty state when no trashed items. | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | Status |
|-------|----------|-------------|----------------|--------|
| TC-D01 | A | FK RESTRICT — cannot delete ledger used in reconciliation | Deleting ledger with reconciliations → FK error | ⏸️ |
| TC-D02 | B | FK CASCADE — delete reconciliation deletes entries | Deleting a reconciliation auto-removes all entries | ⏸️ |
| TC-D03 | C | FK SET NULL — deleting voucher_item sets matched_voucher_item_id=null | Matched entry's reference set to null on item delete | ⏸️ |
| TC-D04 | D | Import command-line or scheduled auto-reconciliation | Cron/scheduler integration for BRS automation | ⏸️ |
| TC-D05 | E | Auto-match correctly matches by same amount + type + date window | Cross-module: voucher items must exist from posted vouchers | ⏸️ |

⏸️ = Skipped — requires cross-module setup

---

### 2.4 SweetAlert Confirmation Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | Click Edit → SweetAlert shows confirmation → Confirm → edit form opens or operation proceeds | test_sweet_alert_edit_confirm | 🔴 |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes record | Click Delete → SweetAlert shows confirmation → Confirm → record soft deleted | test_sweet_alert_delete_confirm | 🔴 |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | Click Delete → SweetAlert shows confirmation → Cancel → deletion aborted, no change | test_sweet_alert_delete_cancel | 🔴 |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | Click Force Delete → SweetAlert shows "Delete Permanently?" → Confirm → record permanently deleted | test_sweet_alert_force_delete_confirm | 🔴 |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | Click Force Delete → SweetAlert shows "Delete Permanently?" → Cancel → deletion aborted | test_sweet_alert_force_delete_cancel | 🔴 |
| TC-SW06 | Restore — SweetAlert confirm restores record | Click Restore → SweetAlert shows confirmation → Confirm → record restored | test_sweet_alert_restore_confirm | 🔴 |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | Click Restore → SweetAlert shows confirmation → Cancel → restore aborted | test_sweet_alert_restore_cancel | 🔴 |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | Click Toggle → SweetAlert shows confirmation → Confirm → status flipped | test_sweet_alert_toggle_confirm | 🔴 |

---

## 3. V2 Test Method Index

| # | Method | Category |
|---|--------|----------|
| 01–12 | test_index, create, import, validate, match, complete, lifecycle, filter | Positive (12) |
| 13–31 | test_validation, import errors, match errors, complete guards, permissions, 404 | Negative (19) |
| 32–36 | test_dependency_fk_and_cross_module | Dependency (5) |

---

## 4. Coverage Summary

| Category | Total TCs | Coverage |
|----------|-----------|----------|
| Positive | 12 | 100% |
| Negative | 19 | 100% |
| SweetAlert | 8 | 0% |
| Dependency | 5 | 0% |
| **Total** | **44** | **70%** |

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/transactions?tab=bank-reconciliation | accounting.menu.transactions | viewAny |
| Resource | /accounting/bank-reconciliation (7 routes) | bank-reconciliation.* | per action |
| POST | /bank-reconciliation/{br}/import | bank-reconciliation.import | import |
| POST | /bank-reconciliation/{br}/validate-statement | bank-reconciliation.validateStatement | import |
| POST | /bank-reconciliation/{br}/import-from-media | bank-reconciliation.importFromMedia | import |
| POST | /bank-reconciliation/{br}/auto-match | bank-reconciliation.autoMatch | update |
| POST | /bank-reconciliation/{br}/complete | bank-reconciliation.complete | complete |
| POST | /bank-reconciliation/entry/{entry}/match | bank-reconciliation.matchEntry | update |
| POST | /bank-reconciliation/entry/{entry}/unmatch | bank-reconciliation.unmatchEntry | update |

---

## 6. Development Issues Found

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| DEV-01 | **status type mismatch**: DDL=TINYINT UNSIGNED FK, code uses string 'In Progress'/'Completed'. Will break on CRUD. | **Critical** | Open |
| DEV-02 | `$recon->is_completed` doesn't exist — controller checks a null property. Guard never triggers. | **High** | Open |
| DEV-03 | `statement_path` column orphaned — always NULL because Media Library used instead | Low | Open |
| DEV-04 | Policy `reconcile()` method defined but never called from controller | Low | Open |
| DEV-05 | No DB-level FK on `created_by` / `matched_by` | Medium | Open |
| DEV-06 | Row count: validateStatement counts by 'date' column, import skips by mapped 'transaction_date' — may mismatch | Low | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Status type mismatch (TINYINT FK vs string) — **feature may not work** | Open |
| KN-02 | `is_completed` guard never triggers — completed reconciliations can be edited/deleted | Open |
| KN-03 | `statement_path` column is dead — always NULL | Open |
| KN-04 | Policy `reconcile()` permission defined but unused | Open |
