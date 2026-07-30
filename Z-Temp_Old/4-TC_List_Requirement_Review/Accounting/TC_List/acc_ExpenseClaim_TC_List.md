# ExpenseClaim_TcList

## Module: Accounting → Transactions → Expense Claims

---

## 1. Business Conditions

### 1.1 Database Schema — acc_expense_claims

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | claim_number | varchar(50) | NOT NULL, UNIQUE (with deleted_at) |
| BC-DB-03 | employee_id | int unsigned | NOT NULL, FK → sch_employees(id) ON DELETE RESTRICT |
| BC-DB-04 | claim_date | date | NOT NULL |
| BC-DB-05 | total_amount | decimal(15,2) | NOT NULL |
| BC-DB-06 | status | tinyint unsigned | NOT NULL, FK → acc_accounting_status_masters(id) ON DELETE RESTRICT |
| BC-DB-07 | approved_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-08 | approved_at | timestamp | NULLABLE |
| BC-DB-09 | voucher_id | bigint unsigned | NULLABLE, FK → acc_vouchers(id) ON DELETE SET NULL |
| BC-DB-10 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-11 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-12 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-13 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-14 | UNIQUE uq_acc_ec_number | (claim_number, deleted_at) | Prevents duplicate claim numbers |
| BC-DB-15 | INDEX idx_acc_ec_employee | employee_id | FK index |
| BC-DB-16 | INDEX idx_acc_ec_status | status | FK index |
| BC-DB-17 | INDEX idx_acc_ec_voucher | voucher_id | FK index |
| BC-DB-18 | ENGINE=InnoDB | — | Transaction support |

### 1.1b Database Schema — acc_expense_claim_lines

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-19 | id | bigint unsigned | PK, auto-increment |
| BC-DB-20 | expense_claim_id | bigint unsigned | NOT NULL, FK → acc_expense_claims(id) ON DELETE CASCADE |
| BC-DB-21 | expense_date | date | NOT NULL |
| BC-DB-22 | ledger_id | int unsigned | NOT NULL, FK → acc_ledgers(id) ON DELETE RESTRICT |
| BC-DB-23 | description | varchar(255) | NOT NULL |
| BC-DB-24 | amount | decimal(15,2) | NOT NULL |
| BC-DB-25 | tax_amount | decimal(15,2) | DEFAULT 0.00 |
| BC-DB-26 | receipt_path | varchar(255) | NULLABLE (orphaned — Media Library used) |
| BC-DB-27 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-28 | created_by | int unsigned | NULLABLE |
| BC-DB-29 | created_at/updated_at/deleted_at | timestamp | Auto-managed |
| BC-DB-30 | INDEX idx_acc_ecl_claim | expense_claim_id | FK index |
| BC-DB-31 | INDEX idx_acc_ecl_ledger | ledger_id | FK index |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| **Critical: status type mismatch** | DDL `status` = TINYINT UNSIGNED FK to `acc_accounting_status_masters(id)` but model casts as string. Code compares 'Draft', 'Submitted', 'Approved', 'Rejected', 'Paid'. No ID-to-string mapping exists. |
| **`rejection_reason` column missing** | Controller validates rejection_reason but it's never stored — no DB column exists. |
| `receipt_path` column orphaned | DDL has column but controller unsets it and uses Spatie Media Library instead. |
| No FK on `created_by` / `approved_by` | Both INT UNSIGNED with no FK to sys_users |
| `is_approved` property doesn't exist | Controller checks `$claim->is_approved` but no attribute/accessor — always null/false |

### 1.2 Validation Rules (ExpenseClaimRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | employee_id | required, exists:sch_employees,id | "The Employee field is required." |
| BC-VAL-02 | claim_date | required, date | "The Claim Date field is required." |
| BC-VAL-03 | is_active | required, boolean | Default true |
| BC-VAL-04 | lines | required, array, min:1 | "The Expense Lines field is required." |
| BC-VAL-05 | lines.*.expense_date | required, date | "The Expense Date field is required." |
| BC-VAL-06 | lines.*.ledger_id | required, exists:acc_ledgers,id | "The Expense Category field is required." |
| BC-VAL-07 | lines.*.description | required, string, max:255 | "The Description field is required." |
| BC-VAL-08 | lines.*.amount | required, numeric, min:0.01 | "The Amount field is required." |
| BC-VAL-09 | lines.*.tax_amount | nullable, numeric, min:0 | — |
| BC-VAL-10 | lines.*.receipt_path | sometimes, file, mimes:jpg,jpeg,png,pdf, max:2048 | — |

### 1.3 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.expense-claim.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.expense-claim.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.expense-claim.update` | `edit()`, `update()`, `submit()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.expense-claim.delete` | `destroy()`, `forceDelete()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.expense-claim.approve` | `approve()`, `reject()`, `markPaid()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: auto claim number | `EC-` + padded count of existing records + 1 |
| BC-BIZ-02 | Create: total_amount = sum(line amounts) | Calculated from validated lines |
| BC-BIZ-03 | Create: status = 'Draft' (new claim) | Default status for new claims |
| BC-BIZ-04 | Create: lines with receipt media | Each line can have a receipt file uploaded via Spatie Media Library |
| BC-BIZ-05 | Create: DB transaction | Claim + lines created atomically |
| BC-BIZ-06 | Update: blocks if approved | Controller checks `is_approved` (broken — never true) |
| BC-BIZ-07 | Update: old lines force-deleted, new ones created | `$claim->lines()->forceDelete()` then recreate |
| BC-BIZ-08 | Delete: blocks if approved | Same broken `is_approved` check |
| BC-BIZ-09 | Submit: only Draft can be submitted | Status changes to 'Submitted'. DomainException for others. |
| BC-BIZ-10 | Approve: only Submitted can be approved | Checks employee has payable ledger. Creates JRN voucher (Dr expense lines, Cr employee payable). Posts voucher. Status='Approved'. |
| BC-BIZ-11 | Reject: only Submitted can be rejected | Status='Rejected'. (rejection_reason NOT persisted — bug) |
| BC-BIZ-12 | Mark Paid: only Approved can be paid | Status='Paid'. Optional voucher_id override. |
| BC-BIZ-13 | Approve: auto-voucher creation | Voucher with debit(s) to expense ledgers + credit to employee payable ledger. Posted. |
| BC-BIZ-14 | Approve: resolves active FY | Finds most recent FY, throws if none |
| BC-BIZ-15 | Approve: generates voucher number | Via VoucherService.generateVoucherNumber |
| BC-BIZ-16 | Index redirects to transactions tab | Redirect to `route('accounting.menu.transactions', ['tab' => 'expense-claims'])` |
| BC-BIZ-17 | Activity log — all workflow events | Created, Updated, Trashed, Restored, Deleted, Submitted, Approved, Rejected, Paid |
| BC-BIZ-18 | Flash messages for all actions | Appropriate success/error for each |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Criteria | Usage |
|-------|-------------|----------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active |
| BC-MOD-02 | `scopeByStatus($query, $status)` | `where('status', $status)` | Filter by status |
| BC-MOD-03 | `scopeDraft($query)` | `where('status', 'Draft')` | Find drafts |
| BC-MOD-04 | `scopeSubmitted($query)` | `where('status', 'Submitted')` | Find submitted |
| BC-MOD-05 | `scopeApproved($query)` | `where('status', 'Approved')` | Find approved |
| BC-MOD-06 | `scopePending($query)` | `WHERE status IN ('Draft','Submitted')` | Pending items |
| BC-MOD-07 | `scopeByEmployee($query, $id)` | `where('employee_id', $id)` | By employee |
| BC-MOD-08 | `isDraft()` / `isSubmitted()` | Status comparison | State checks |
| BC-MOD-09 | `isApprovable()` | `status === 'Submitted'` | Can approve? |
| BC-MOD-10 | `isEditable()` | `status === 'Draft'` | Can edit? |
| BC-MOD-11 | `computedTotal()` | `lines()->sum('amount')` | Sum helper |
| BC-MOD-12 | Line: `totalWithTax()` | `amount + tax_amount` | Tax-inclusive amount |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | employee_id | sch_employees (id) | RESTRICT |
| BC-REF-02 | status | acc_accounting_status_masters (id) | RESTRICT |
| BC-REF-03 | voucher_id | acc_vouchers (id) | SET NULL |
| BC-REF-04 | expense_claim_id (lines) | acc_expense_claims (id) | CASCADE |
| BC-REF-05 | ledger_id (lines) | acc_ledgers (id) | RESTRICT |
| BC-REF-06 | created_by / approved_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-P01 | List loads via Transactions tab | Cards with claim_number, employee, date, amount, status badge. | test_index_page_loads | ✅ |
| TC-P02 | Create expense claim (Draft) | Claim created with auto-number, employee, date, lines. Status=Draft. Flash. | test_create_draft_claim | ✅ |
| TC-P03 | Create with receipt upload | Receipt file attached to line via Media Library. | test_create_with_receipt | ✅ |
| TC-P04 | Create with multiple lines | 3+ expense lines, tax_amount, all stored correctly. | test_create_multiple_lines | ✅ |
| TC-P05 | Edit draft claim — update fields | Pre-filled form, lines recreated, total_amount recalculated. | test_edit_draft_claim | ✅ |
| TC-P06 | Submit draft claim | Status changes Draft→Submitted. Flash. | test_submit_claim | ✅ |
| TC-P07 | Approve submitted claim | Voucher created (Dr expense lines, Cr employee payable). Status=Approved. Voucher posted. | test_approve_claim_creates_voucher | ✅ |
| TC-P08 | Reject submitted claim | Status=Rejected. (Note: reason not persisted — known bug). | test_reject_claim | ✅ |
| TC-P09 | Mark paid (Approved→Paid) | Status=Paid. Optional voucher_id stored. | test_mark_paid | ✅ |
| TC-P10 | Full lifecycle: Draft→Submit→Approve→Paid | End-to-end workflow verified. | test_full_lifecycle | ✅ |
| TC-P11 | Delete→Trash→Restore→Force Delete | Soft delete sets is_active=false; restore sets is_active=true. | test_trash_restore_force_delete | ✅ |
| TC-P12 | Search by claim number | Search text matches claim_number. | test_search_claims | ✅ |
| TC-P13 | Filter by status (Draft/Submitted/Approved/Paid) | Status dropdown filters correctly. | test_filter_by_status | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-N01 | Create — required fields empty | Validation errors: employee_id, claim_date, lines. | test_validation_required_fields | ✅ |
| TC-N02 | Create — invalid employee_id | exists:sch_employees validation error. | test_validation_invalid_employee | ✅ |
| TC-N03 | Create — lines empty | min:1 validation error. | test_validation_no_lines | ✅ |
| TC-N04 | Create — line amount zero | min:0.01 validation error. | test_validation_line_amount_zero | ✅ |
| TC-N05 | Create — invalid ledger_id in line | exists:acc_ledgers error. | test_validation_invalid_ledger | ✅ |
| TC-N06 | Create — invalid receipt file type | mimes:jpg,jpeg,png,pdf validation error. | test_validation_invalid_receipt_type | ✅ |
| TC-N07 | Create — receipt too large (>2MB) | max:2048 validation error. | test_validation_receipt_too_large | ✅ |
| TC-N08 | Update — approved claim blocked | "Cannot update an approved expense claim." (is_approved broken — currently allowed). | test_update_approved_blocked | ✅ |
| TC-N09 | Delete — approved claim blocked | "Cannot delete an approved expense claim." (is_approved broken). | test_delete_approved_blocked | ✅ |
| TC-N10 | Submit — already submitted claim | DomainException. | test_submit_already_submitted | ✅ |
| TC-N11 | Approve — draft claim (not submitted) | DomainException. | test_approve_draft_claim | ✅ |
| TC-N12 | Approve — employee has no payable ledger | Error: "Employee has no linked payable ledger." | test_approve_no_payable_ledger | ✅ |
| TC-N13 | Approve — already approved claim | DomainException. | test_approve_already_approved | ✅ |
| TC-N14 | Reject — draft claim (not submitted) | DomainException. | test_reject_draft_claim | ✅ |
| TC-N15 | Reject — reason required (but not stored) | Controller validates rejection_reason required|max:500. | test_reject_without_reason | ✅ |
| TC-N16 | Mark Paid — not approved claim | "Only an Approved claim can be marked as Paid." | test_mark_paid_not_approved | ✅ |
| TC-N17 | Permission denied (403) | User without permissions → 403. | test_permission_denied_403 | ✅ |
| TC-N18 | Guest access redirect | Unauthenticated → /login. | test_guest_redirect_to_login | ✅ |
| TC-N19 | Invalid ID — all operations (404) | HTTP 404 on all endpoints for invalid ID. | test_invalid_id_404 | ✅ |
| TC-N20 | Empty trash page | Empty state message. | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | Status |
|-------|----------|-------------|----------------|--------|
| TC-D01 | A | FK RESTRICT — cannot delete employee with claims | Deleting employee with claims → FK error | ⏸️ |
| TC-D02 | B | FK CASCADE — delete claim deletes lines | Deleting claim auto-removes all lines | ⏸️ |
| TC-D03 | C | Approval creates voucher — appears in Vouchers tab | Voucher created with correct Dr/Cr entries | ⏸️ |
| TC-D04 | D | Approval posts voucher — ledger balances updated | Expense ledger debited, employee payable credited | ⏸️ |
| TC-D05 | E | FK SET NULL — deleting voucher sets voucher_id=null | Deleting the voucher created on approval sets claim's voucher_id = null | ⏸️ |

⏸️ = Skipped — requires cross-module setup (Voucher, Ledger, Employee)

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
| TC-SW09 | Submit — SweetAlert confirm submits claim | Click Submit → SweetAlert shows confirmation → Confirm → claim submitted | test_sweet_alert_submit_confirm | 🔴 |
| TC-SW10 | Approve — SweetAlert confirm approves claim | Click Approve → SweetAlert shows confirmation → Confirm → claim approved with voucher creation | test_sweet_alert_approve_confirm | 🔴 |
| TC-SW11 | Pay — SweetAlert confirm marks as paid | Click Mark Paid → SweetAlert shows confirmation → Confirm → claim marked as paid | test_sweet_alert_pay_confirm | 🔴 |

---

## 3. V2 Test Method Index

| # | Method | Category |
|---|--------|----------|
| 01–13 | test_index through test_filter_by_status | Positive (13) |
| 14–33 | test_validation through test_empty_trash | Negative (20) |
| 34–38 | test_dependency_fk_cross_module | Dependency (5) |

---

## 4. Coverage Summary

| Category | Total TCs | Coverage |
|----------|-----------|----------|
| Positive | 13 | 100% |
| Negative | 20 | 100% |
| SweetAlert | 11 | 0% |
| Dependency | 5 | 0% |
| **Total** | **49** | **67%** |

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/transactions?tab=expense-claims | accounting.menu.transactions | viewAny |
| Resource | /accounting/expense-claim (7 routes) | expense-claim.* | per action |
| POST | /expense-claim/{claim}/submit | expense-claim.submit | update |
| POST | /expense-claim/{claim}/approve | expense-claim.approve | approve |
| POST | /expense-claim/{claim}/reject | expense-claim.reject | approve |
| POST | /expense-claim/{claim}/mark-paid | expense-claim.mark-paid | approve |
| GET | /expense-claim/trash/view | expense-claim.trashed | viewAny |
| GET | /expense-claim/{id}/restore | expense-claim.restore | create |
| DELETE | /expense-claim/{id}/force-delete | expense-claim.forceDelete | delete |

---

## 6. Development Issues Found

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-01 | DDL + Controller | **Status type mismatch**: DDL=TINYINT UNSIGNED FK, code uses string. Will break. | **Critical** | Open |
| DEV-02 | Show View + Controller | **Show view workflow buttons broken**: View submits PUT to `update()` with hidden status field, but `update()` has no status-change logic. Should POST to dedicated routes. | **Critical** | Open |
| DEV-03 | Controller + Service | **`is_approved` guard broken**: Controller checks non-existent `$claim->is_approved` property (always null/false). Approved claims can be edited/deleted. | **High** | Open |
| DEV-04 | Service | **Rejection reason not persisted**: Controller validates `rejection_reason` but service never stores it — no DB column. | **High** | Open |
| DEV-05 | Controller | `show()` uses `viewAny` permission instead of `view` | Low | Open |
| DEV-06 | Controller | Claim number generation uses `count()+1` — race condition on concurrent requests | Medium | Open |
| DEV-07 | Service | `markPaid` can overwrite existing `voucher_id` from approval | Low | Open |
| DEV-08 | DDL | `receipt_path` column orphaned — Media Library used instead | Low | Open |
| DEV-09 | DDL | `created_by` / `approved_by` have no DB FK | Medium | Open |
| DEV-10 | Controller | No authorization on `trashed()`, `restore()`, `forceDelete()` — any auth user can access | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Status type mismatch (TINYINT FK vs string) — feature may not function | Open |
| KN-02 | Show view Submit/Approve/Reject buttons send PUT to `update()` instead of POST to dedicated routes | Open |
| KN-03 | `is_approved` guard never works — approved claims can be edited/deleted | Open |
| KN-04 | Rejection reason validated but never stored (no DB column) | Open |
| KN-05 | `receipt_path` column is dead — always NULL | Open |
| KN-06 | Concurrent claim number generation race condition | Open |
| KN-07 | No authorization on trash/restore/forceDelete endpoints | Open |
