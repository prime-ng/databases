# fee_FeeChequeReconciliation_TcList

## Module: StudentFee → Fee Cheque/DD Reconciliation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Feature | Fee Cheque/DD Reconciliation |
| URL(s) | `/student-fee/fee-cheque` (index), `/student-fee/fee-cheque/create` (create), `/student-fee/fee-cheque` (store), `/student-fee/fee-cheque/{id}` (show), `/student-fee/fee-cheque/{id}/edit` (edit), `/student-fee/fee-cheque/{id}` (update), `/student-fee/fee-cheque/{id}` (destroy), `/student-fee/fee-cheque/{fee_cheque}/deposit` (deposit), `/student-fee/fee-cheque/{fee_cheque}/clear` (clear), `/student-fee/fee-cheque/{fee_cheque}/bounce` (bounce), `/student-fee/fee-cheque/{fee_cheque}/resubmit` (resubmit) |
| Controller | `Modules\StudentFee\Http\Controllers\FeeChequeController` |
| Model(s) | `Modules\StudentFee\Models\FeePaymentReconciliation` (table: `fee_payment_reconciliation`) |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeChequeRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeChequeRequest` |
| Permissions | `tenant.fee-cheque.viewAny`, `tenant.fee-cheque.create`, `tenant.fee-cheque.view`, `tenant.fee-cheque.update`, `tenant.fee-cheque.delete`, `tenant.fee-cheque.deposit`, `tenant.fee-cheque.clear`, `tenant.fee-cheque.bounce`, `tenant.fee-cheque.resubmit` |
| Soft Deletes | No (model extends BaseModel without SoftDeletes) |
| Activity Log | Events: `Created`, `Updated`, `Deleted`, `Deposited`, `Cleared`, `Bounced`, `Resubmitted` |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-cheque.{viewAny,create,view,update,delete,deposit,clear,bounce,resubmit}`
- At least one successful FeeTransaction with payment_mode = 'Cheque' or 'DD'
- Tenant context must be initialized

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Cheques (index) | `FeePaymentReconciliation::with(['transaction.student.user'])->latest()` | Latest first | None | 15/page |
| Transactions (create) | `FeeTransaction::with(['student.user','invoice'])->whereIn('payment_mode',['Cheque','DD'])->where('status','Success')->orderBy('payment_date','desc')` | Cheque/DD only, successful | None | None |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Seed data**: Create a successful Cheque/DD transaction for reconciliation
- **Lifecycle test**: Chain status transitions: Pending Deposit → Deposited → Cleared
- **Bounce test**: Chain: Pending Deposit → Deposited → Bounced → Resubmitted
- **Pre-test cleanup**: Delete created records by ID (no soft deletes)

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_payment_reconciliation`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | transaction_id | INT UNSIGNED FK | NOT NULL, UNIQUE → fee_transactions RESTRICT |
| BC-DB-03 | cheque_no | VARCHAR(50) | NOT NULL |
| BC-DB-04 | bank_name | VARCHAR(100) | NOT NULL |
| BC-DB-05 | cheque_date | DATE | NOT NULL |
| BC-DB-06 | deposit_date | DATE | NULLABLE |
| BC-DB-07 | clearance_date | DATE | NULLABLE |
| BC-DB-08 | bounce_date | DATE | NULLABLE |
| BC-DB-09 | bounce_reason | VARCHAR(255) | NULLABLE |
| BC-DB-10 | bounce_charge | DECIMAL(10,2) | NULLABLE |
| BC-DB-11 | resubmit_date | DATE | NULLABLE |
| BC-DB-12 | status | ENUM('Pending Deposit','Deposited','Cleared','Bounced','Resubmitted') | NOT NULL DEFAULT 'Pending Deposit' |
| BC-DB-13 | remarks | TEXT | NULLABLE |
| BC-DB-14 | updated_by | INT UNSIGNED FK NULL | → sys_users |

### 5.2 Validation Rules

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | transaction_id | required, integer, exists:fee_transactions,id where payment_mode in (Cheque,DD) | — |
| BC-VAL-02 | cheque_no | required, string, max:50 | — |
| BC-VAL-03 | bank_name | required, string, max:100 | — |
| BC-VAL-04 | cheque_date | required, date | — |
| BC-VAL-05 | remarks | nullable, string, max:500 | — |
| BC-VAL-06 | bounce_reason (bounce) | required, string, max:500 | — |
| BC-VAL-07 | bounce_charge (bounce) | nullable, numeric, min:0 | — |
| BC-VAL-DUP | Duplicate active reconciliation | — | "A reconciliation record already exists for this transaction." |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.fee-cheque.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.fee-cheque.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.fee-cheque.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.fee-cheque.update | edit(), update() | Without → 403 |
| BC-AUTH-05 | tenant.fee-cheque.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.fee-cheque.deposit | deposit() | Without → 403 |
| BC-AUTH-07 | tenant.fee-cheque.clear | clear() | Without → 403 |
| BC-AUTH-08 | tenant.fee-cheque.bounce | bounce() | Without → 403 |
| BC-AUTH-09 | tenant.fee-cheque.resubmit | resubmit() | Without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create reconciliation | status=Pending Deposit, updated_by set |
| BC-BIZ-02 | Duplicate transaction (non-Bounced) | Error: "A reconciliation record already exists for this transaction." |
| BC-BIZ-03 | Deposit Pending Deposit | status=Deposited, deposit_date=now |
| BC-BIZ-04 | Deposit non-Pending | Error: "Only pending deposit cheques can be marked as deposited." |
| BC-BIZ-05 | Clear Deposited | status=Cleared, clearance_date=now |
| BC-BIZ-06 | Clear non-Deposited | Error: "Only deposited cheques can be marked as cleared." |
| BC-BIZ-07 | Bounce Deposited | status=Bounced, bounce_date, bounce_reason, bounce_charge; transaction→Failed; invoice→deductPayment |
| BC-BIZ-08 | Bounce non-Deposited | Error: "Only deposited cheques can be marked as bounced." |
| BC-BIZ-09 | Bounce reversal in DB transaction | Transaction and invoice update happen atomically |
| BC-BIZ-10 | Resubmit Bounced | status=Resubmitted, resubmit_date=now |
| BC-BIZ-11 | Resubmit non-Bounced | Error: "Only bounced cheques can be marked as resubmitted." |
| BC-BIZ-12 | Edit Pending Deposit record | All fields updatable |
| BC-BIZ-13 | Edit non-Pending | Error: "Only pending deposit records can be edited." / "Only pending deposit records can be updated." |
| BC-BIZ-14 | Delete Pending Deposit | Record deleted |
| BC-BIZ-15 | Delete non-Pending | Error: "Only pending deposit records can be deleted." |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | transaction_id | fee_transactions (id) | RESTRICT |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Create Reconciliation Record | Record created with status=Pending Deposit, updated_by set | — | — | ⬜ |
| TC-P02 | Deposit Pending Deposit Cheque | status=Deposited, deposit_date=now | — | — | ⬜ |
| TC-P03 | Clear Deposited Cheque | status=Cleared, clearance_date=now | — | — | ⬜ |
| TC-P04 | Full Clearance Lifecycle | Pending Deposit → Deposited → Cleared, all statuses progress | — | — | ⬜ |
| TC-P05 | Bounce Deposited Cheque With Reason | status=Bounced, bounce_date, bounce_reason, bounce_charge set | — | — | ⬜ |
| TC-P06 | Bounce Reverses Transaction and Invoice | Transaction status=Failed, invoice balance restored | — | — | ⬜ |
| TC-P07 | Resubmit Bounced Cheque | status=Resubmitted, resubmit_date=now | — | — | ⬜ |
| TC-P08 | Full Bounce Lifecycle | Pending Deposit → Deposited → Bounced → Resubmitted | — | — | ⬜ |
| TC-P09 | Show Cheque Details | Page loads with transaction, student, invoice, audit trail | — | — | ⬜ |
| TC-P10 | Edit Pending Deposit Record | cheque_no, bank_name, cheque_date, remarks updated | — | — | ⬜ |
| TC-P11 | Delete Pending Deposit Record | Record deleted | — | — | ⬜ |
| TC-P12 | Create With Remarks | Remarks stored correctly | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `transaction_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing `cheque_no` | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing `bank_name` | Validation error | — | — | ⬜ |
| TC-N04 | Required — Missing `cheque_date` | Validation error | — | — | ⬜ |
| TC-N05 | Invalid — transaction not Cheque/DD | Validation error: exists query filtered to Cheque/DD only | — | — | ⬜ |
| TC-N06 | Duplicate — Transaction already has active reconciliation | Error: "A reconciliation record already exists for this transaction." | — | — | ⬜ |
| TC-N07 | Deposit non-Pending (Deposited) | Error: "Only pending deposit cheques can be marked as deposited." | — | — | ⬜ |
| TC-N08 | Clear non-Deposited (Pending) | Error: "Only deposited cheques can be marked as cleared." | — | — | ⬜ |
| TC-N09 | Bounce non-Deposited (Pending) | Error: "Only deposited cheques can be marked as bounced." | — | — | ⬜ |
| TC-N10 | Bounce without bounce_reason | Validation error: "The bounce reason field is required." | — | — | ⬜ |
| TC-N11 | Resubmit non-Bounced (Cleared) | Error: "Only bounced cheques can be marked as resubmitted." | — | — | ⬜ |
| TC-N12 | Edit non-Pending record | Error: "Only pending deposit records can be edited." | — | — | ⬜ |
| TC-N13 | Delete non-Pending record | Error: "Only pending deposit records can be deleted." | — | — | ⬜ |
| TC-N14 | Permission 403 | 403 Forbidden | — | — | ⬜ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create → updated_by set | updated_by = auth()->id() | — | — | ⬜ |
| TC-D02 | B | Deposit → deposit_date=now | deposit_date set to current timestamp | — | — | ⬜ |
| TC-D03 | C | Bounce → DB transaction reverses payment | Transaction status→Failed, invoice→deductPayment called | — | — | ⬜ |
| TC-D04 | D | Bounce → bounce_charge default 0 | bounce_charge = 0 when not provided | — | — | ⬜ |
| TC-D05 | E | Clear → clearance_date=now | clearance_date set to current timestamp | — | — | ⬜ |
| TC-D06 | F | Resubmit → resubmit_date=now | resubmit_date set to current timestamp | — | — | ⬜ |
| TC-D07 | G | Activity Logged After All State Changes | Created, Updated, Deleted, Deposited, Cleared, Bounced, Resubmitted all logged | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Bounce uses DB::transaction() | Bounce wraps reconciliation + transaction + invoice updates atomically | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — status check before all transitions | Each action validates current status matches expected | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — Gate::authorize() with specific permissions | 9 distinct permissions for 9 action methods | — | — | ◌ |
| TC-CR04 | CR | P1 | StoreFeeChequeRequest — duplicate check with withValidator | Existing active (non-Bounced) reconciliation check | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P04: Full Clearance Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Cheque/DD create page | Form loads with Cheque/DD transactions |
| 2 | Select a Cheque transaction, enter cheque_no="CHQ001", bank_name="SBI", cheque_date="2026-01-15" | Fields filled |
| 3 | Click "Save" | Record created; status=Pending Deposit |
| 4 | Click "Deposit" on the record | POST to deposit(); status=Deposited; deposit_date set |
| 5 | Click "Clear" on the record | POST to clear(); status=Cleared; clearance_date set |
| 6 | DB check: `SELECT status, deposit_date, clearance_date FROM fee_payment_reconciliation WHERE id=X` | status='Cleared', both dates set |

### TC-P06: Bounce Reverses Transaction and Invoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and deposit a cheque | status=Deposited |
| 2 | Click "Bounce" | POST to bounce() |
| 3 | Enter bounce_reason="Insufficient funds" and bounce_charge=50 | Fields filled |
| 4 | Click "Submit" | Bounce processed |
| 5 | Check reconciliation status | status=Bounced; bounce_date, bounce_reason, bounce_charge set |
| 6 | Check original transaction | `SELECT status FROM fee_transactions WHERE id=X` → 'Failed' |
| 7 | Check linked invoice | `deductPayment()` called → balance_amount increased |

### TC-N06: Duplicate Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create reconciliation for transaction X | status=Pending Deposit |
| 2 | Try to create another reconciliation for same transaction X | POST to store() |
| 3 | Check response | Error: "A reconciliation record already exists for this transaction." |

---

## 8. Known Issues

- Model uses table name `fee_payment_reconciliation` (singular) while DDL shows `fee_payment_reconciliation` (matching)
- No cascade update on related models when bounce occurs (manual update via DB transaction)
- `updated_by` field is set on create but not on initial status (create sets it, then deposit/clear/bounce/resubmit also set it)

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/fee-cheque` | `student-fee.fee-cheque.index` | `index` |
| GET | `/student-fee/fee-cheque/create` | `student-fee.fee-cheque.create` | `create` |
| POST | `/student-fee/fee-cheque` | `student-fee.fee-cheque.store` | `store` |
| GET | `/student-fee/fee-cheque/{id}` | `student-fee.fee-cheque.show` | `show` |
| GET | `/student-fee/fee-cheque/{id}/edit` | `student-fee.fee-cheque.edit` | `edit` |
| PUT/PATCH | `/student-fee/fee-cheque/{id}` | `student-fee.fee-cheque.update` | `update` |
| DELETE | `/student-fee/fee-cheque/{id}` | `student-fee.fee-cheque.destroy` | `destroy` |
| POST | `/student-fee/fee-cheque/{fee_cheque}/deposit` | `student-fee.fee-cheque.deposit` | `deposit` |
| POST | `/student-fee/fee-cheque/{fee_cheque}/clear` | `student-fee.fee-cheque.clear` | `clear` |
| POST | `/student-fee/fee-cheque/{fee_cheque}/bounce` | `student-fee.fee-cheque.bounce` | `bounce` |
| POST | `/student-fee/fee-cheque/{fee_cheque}/resubmit` | `student-fee.fee-cheque.resubmit` | `resubmit` |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
