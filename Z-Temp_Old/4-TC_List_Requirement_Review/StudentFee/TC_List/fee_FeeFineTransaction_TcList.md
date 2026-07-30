# fee_FeeFineTransaction_TcList

## Module: StudentFee → Fine Management → Fee Fine Transactions

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Tab Group | Fine Management |
| Feature | Fee Fine Transactions |
| URL(s) | `/student-fee/fine-management` (tab), `/student-fee/fee-fine-transaction` (index), `/student-fee/fee-fine-transaction/create` (create), `/student-fee/fee-fine-transaction` (store), `/student-fee/fee-fine-transaction/{id}` (show), `/student-fee/fee-fine-transaction/{id}/edit` (edit), `/student-fee/fee-fine-transaction/{id}` (update), `/student-fee/fee-fine-transaction/{id}` (destroy), `/student-fee/fee-fine-transaction/{id}/waive` (waive), `/student-fee/fee-fine-transaction/trash/view` (trashed) |
| Controller | `Modules\StudentFee\Http\Controllers\FeeFineTransactionController` |
| Model(s) | `Modules\StudentFee\Models\FeeFineTransaction` (table: `fee_fine_transactions`) |
| Service | `Modules\StudentFee\Services\FeeFineService` |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeFineTransactionRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeFineTransactionRequest` |
| Validation (Waive) | `Modules\StudentFee\Http\Requests\WaiveFeeFineTransactionRequest` |
| Permissions | `tenant.fee-fine-transaction.view`, `tenant.fee-fine-transaction.create`, `tenant.fee-fine-transaction.update`, `tenant.fee-fine-transaction.delete` |
| Soft Deletes | Yes (model uses BaseModel with SoftDeletes, but no restore/forceDelete routes) |
| Activity Log | Events: `Created`, `Updated`, `Deleted`, `Waived` |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-fine-transaction.{view,create,update,delete}`
- At least one active student in `std_students` with `is_active=true`
- At least one unpaid/non-cancelled invoice in `fee_invoices`
- At least one active `FeeFineRule` record
- Tenant context must be initialized

---

## 3. Default Data Load

When the page loads via `StudentFeeManagementController@fineManagement()` (GET `/student-fee/fine-management`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Fine Rules | `FeeFineRule::paginate(10)` | All rules | None | 10/page |
| Fine Transactions | `FeeFineTransaction::with(['student.user','invoice','fineRule'])->latest('fine_date')->paginate(15)` | Latest first | search(student name), waived status | 15/page |

For create form load:
| Data | Source | Query |
|------|--------|-------|
| Students | `Student::with('user')->where('is_active', true)->get()` | All active students |
| Invoices | `FeeInvoice::with(['studentAssignment.student.user'])->whereNotIn('status', [Paid, Cancelled])->latest('invoice_date')->get()` | Unpaid/non-cancelled |
| Fine Rules | `FeeFineRule::where('is_active', true)->orderBy('rule_name')->get()` | All active rules |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Pre-test data**: Create one active student, one unpaid invoice, one active fine rule
- **Waive test data**: Create a non-waived fine transaction with known fine_amount
- **Dynamic validation**: `WaiveFeeFineTransactionRequest` sets `max:{fine_amount}` dynamically for waived_amount

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_fine_transactions`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | student_id | INT UNSIGNED FK | NOT NULL → std_students RESTRICT |
| BC-DB-03 | invoice_id | INT UNSIGNED FK | NOT NULL → fee_invoices RESTRICT |
| BC-DB-04 | fine_rule_id | INT UNSIGNED FK | NOT NULL → fee_fine_rules RESTRICT |
| BC-DB-05 | fine_date | DATE | NOT NULL |
| BC-DB-06 | days_late | INT | NOT NULL |
| BC-DB-07 | fine_amount | DECIMAL(10,2) | NOT NULL |
| BC-DB-08 | waived | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-09 | waived_amount | DECIMAL(10,2) | NULLABLE (NULL = full waiver) |
| BC-DB-10 | waived_by | INT UNSIGNED FK | NULLABLE → sys_users SET NULL |
| BC-DB-11 | waiver_reason | TEXT | NULLABLE |
| BC-DB-12 | waived_at | TIMESTAMP | NULLABLE |

### 5.2 Validation Rules — `StoreFeeFineTransactionRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | student_id | required, integer, exists:std_students,id | — |
| BC-VAL-02 | invoice_id | required, integer, exists:fee_invoices,id | — |
| BC-VAL-03 | fine_rule_id | required, integer, exists:fee_fine_rules,id | — |
| BC-VAL-04 | fine_date | required, date | — |
| BC-VAL-05 | days_late | required, integer, min:0 | — |
| BC-VAL-06 | fine_amount | required, numeric, min:0 | — |

### 5.3 Validation Rules — `WaiveFeeFineTransactionRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-W01 | waiver_reason | nullable, string, max:500 | — |
| BC-VAL-W02 | waived_amount | nullable, numeric, min:0, max:{fine_amount} | Dynamic max set to transaction's fine_amount |

### 5.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.fee-fine-transaction.view | index(), show() | Without → 403 |
| BC-AUTH-02 | tenant.fee-fine-transaction.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.fee-fine-transaction.update | edit(), update(), waive() | Without → 403 |
| BC-AUTH-04 | tenant.fee-fine-transaction.delete | destroy() | Without → 403 |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create transaction | Record created via FeeFineService with waived=false |
| BC-BIZ-02 | Update non-waived transaction | Update allowed; full waiver check blocks if waived=true |
| BC-BIZ-03 | Update waived transaction | Error: "Cannot edit a waived fine transaction." |
| BC-BIZ-04 | Waive non-waived transaction | waived=true, waived_by, waiver_reason, waived_at set |
| BC-BIZ-05 | Waive already waived transaction | Error: "This fine has already been waived." |
| BC-BIZ-06 | Partial waiver | waived_amount set to partial value; effective fine = fine_amount - waived_amount |
| BC-BIZ-07 | Full waiver | waived_amount=null; waived=true; getEffectiveFine() = 0 |
| BC-BIZ-08 | getEffectiveFine not waived | Returns full fine_amount |
| BC-BIZ-09 | getEffectiveFine partial waiver | Returns fine_amount - waived_amount (min 0) |
| BC-BIZ-10 | getEffectiveFine full waiver | Returns 0.00 |
| BC-BIZ-11 | Soft delete | Transaction moved to trash |
| BC-BIZ-12 | Waive amount exceeds fine | Validation fails dynamically: max:{fine_amount} |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | student_id | std_students (id) | RESTRICT |
| BC-REF-02 | invoice_id | fee_invoices (id) | RESTRICT |
| BC-REF-03 | fine_rule_id | fee_fine_rules (id) | RESTRICT |
| BC-REF-04 | waived_by | sys_users (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Create Fine Transaction | Transaction created with student, invoice, fine rule, 10 days late, ₹250 fine_amount | — | — | ⬜ |
| TC-P02 | Show Fine Transaction Details | Page loads with student name, invoice no, rule name, days late, fine amount, waived status | — | — | ⬜ |
| TC-P03 | Edit Fine Transaction (not waived) | fine_rule_id, fine_date, days_late, fine_amount updated | — | — | ⬜ |
| TC-P04 | Full Waive Fine Transaction | waived=true, waived_amount=null, waived_by, waiver_reason, waived_at set | — | — | ⬜ |
| TC-P05 | Partial Waive Fine Transaction | waived=true, waived_amount=200 (for ₹500 fine), effective fine = ₹300 | — | — | ⬜ |
| TC-P06 | Delete Fine Transaction | Transaction soft-deleted | — | — | ⬜ |
| TC-P07 | Create From Manual Entry With Valid Data | Service creates record with waived=false | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `student_id` | Validation error: "The student id field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing `invoice_id` | Validation error: "The invoice id field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `fine_rule_id` | Validation error: "The fine rule id field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `fine_date` | Validation error: "The fine date field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `days_late` | Validation error: "The days late field is required." | — | — | ⬜ |
| TC-N06 | Required — Missing `fine_amount` | Validation error: "The fine amount field is required." | — | — | ⬜ |
| TC-N07 | Invalid — Non-existent `student_id` | Validation error: "The selected student id is invalid." | — | — | ⬜ |
| TC-N08 | Invalid — Non-existent `invoice_id` | Validation error: "The selected invoice id is invalid." | — | — | ⬜ |
| TC-N09 | Invalid — `days_late` negative | Validation fails on min:0 | — | — | ⬜ |
| TC-N10 | Invalid — `fine_amount` negative | Validation fails on min:0 | — | — | ⬜ |
| TC-N11 | Business — Edit waived transaction | Error: "Cannot edit a waived fine transaction." | — | — | ⬜ |
| TC-N12 | Business — Waive already waived transaction | Error: "This fine has already been waived." | — | — | ⬜ |
| TC-N13 | Business — Waive amount exceeds fine_amount | Validation error on max rule | — | — | ⬜ |
| TC-N14 | Permission 403 — No transaction permissions | 403 Forbidden on all endpoints | — | — | ⬜ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create → FeeFineService::record() called | Service creates FeeFineTransaction with waived=false | — | — | ⬜ |
| TC-D02 | B | Waive via FeeFineService::waive() | Calls $transaction->waive() with user ID, reason, amount | — | — | ⬜ |
| TC-D03 | C | Service waive throws DomainException if already waived | Exception: "This fine has already been waived." | — | — | ⬜ |
| TC-D04 | D | Activity Logged After Create | activityLog() with event 'Created' | — | — | ⬜ |
| TC-D05 | E | Activity Logged After Update | activityLog() with event 'Updated' | — | — | ⬜ |
| TC-D06 | F | Activity Logged After Delete | activityLog() with event 'Deleted' | — | — | ⬜ |
| TC-D07 | G | Activity Logged After Waive | activityLog() with event 'Waived' | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — FeeFineService DI via constructor | `__construct(private readonly FeeFineService $fineService)` | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Gate::authorize() before each action | All methods call authorize before logic | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog after each CRUD+Waive | All state-changing methods log activity | — | — | ◌ |
| TC-CR04 | CR | P1 | WaiveFeeFineTransactionRequest — Dynamic max rule | `max:{fine_amount}` computed from transaction | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P04: Full Waive Fine Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a fine transaction with fine_amount=500 | Transaction exists with ID=X, waived=false |
| 2 | Navigate to waive form for transaction X | Waive form loads |
| 3 | Leave waived_amount empty (full waiver) | Empty |
| 4 | Enter waiver_reason: "Financial hardship" | Field filled |
| 5 | Click "Waive" | PUT to waive() route |
| 6 | Check response | Flash: "Fine waived successfully." |
| 7 | DB check: `SELECT waived, waived_amount, waived_by, waiver_reason, waived_at FROM fee_fine_transactions WHERE id=X` | waived=1, waived_amount=NULL, waiver_reason set, waived_at not null |

### TC-N11: Edit Waived Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and fully waive a fine transaction | waived=true |
| 2 | Navigate to edit page for that transaction | Edit form |
| 3 | Change fine_amount and submit | PUT to update() |
| 4 | Check response | Error: "Cannot edit a waived fine transaction." |

---

## 8. Known Issues

- `trashed()` method in controller simply redirects to `fineManagement` — no actual trash view
- No `restore` or `forceDelete` routes defined for fine transactions
- `UpdateFeeFineTransactionRequest` does not include `student_id` or `invoice_id` in rules (only fine_rule_id, fine_date, days_late, fine_amount)

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/fee-fine-transaction` | `student-fee.fee-fine-transaction.index` | `index` |
| GET | `/student-fee/fee-fine-transaction/create` | `student-fee.fee-fine-transaction.create` | `create` |
| POST | `/student-fee/fee-fine-transaction` | `student-fee.fee-fine-transaction.store` | `store` |
| GET | `/student-fee/fee-fine-transaction/{id}` | `student-fee.fee-fine-transaction.show` | `show` |
| GET | `/student-fee/fee-fine-transaction/{id}/edit` | `student-fee.fee-fine-transaction.edit` | `edit` |
| PUT/PATCH | `/student-fee/fee-fine-transaction/{id}` | `student-fee.fee-fine-transaction.update` | `update` |
| DELETE | `/student-fee/fee-fine-transaction/{id}` | `student-fee.fee-fine-transaction.destroy` | `destroy` |
| PUT | `/student-fee/fee-fine-transaction/{id}/waive` | `student-fee.fee-fine-transaction.waive` | `waive` |
| GET | `/student-fee/fee-fine-transaction/trash/view` | `student-fee.fee-fine-transaction.trashed` | `trashed` |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
