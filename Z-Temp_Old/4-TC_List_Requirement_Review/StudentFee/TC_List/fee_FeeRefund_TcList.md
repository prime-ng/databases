# fee_FeeRefund_TcList

## Module: StudentFee → Fee Refund

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Feature | Fee Refund |
| URL(s) | `/student-fee/fee-refund` (index), `/student-fee/fee-refund/create` (create), `/student-fee/fee-refund` (store), `/student-fee/fee-refund/{id}` (show), `/student-fee/fee-refund/{id}/edit` (edit), `/student-fee/fee-refund/{id}` (update), `/student-fee/fee-refund/{id}` (destroy), `/student-fee/fee-refund/{fee_refund}/approve` (approve), `/student-fee/fee-refund/{fee_refund}/reject` (reject), `/student-fee/fee-refund/{fee_refund}/process` (process) |
| Controller | `Modules\StudentFee\Http\Controllers\FeeRefundController` |
| Model(s) | `Modules\StudentFee\Models\FeeRefund` (table: `fee_refunds`) |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeRefundRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeRefundRequest` |
| Permissions | `tenant.fee-refund.viewAny`, `tenant.fee-refund.create`, `tenant.fee-refund.view`, `tenant.fee-refund.update`, `tenant.fee-refund.delete`, `tenant.fee-refund.approve`, `tenant.fee-refund.reject`, `tenant.fee-refund.process` |
| Soft Deletes | Yes (`SoftDeletes` trait) |
| Activity Log | Events: `Created`, `Updated`, `Deleted`, `Approved`, `Rejected`, `Processed` |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-refund.{viewAny,create,view,update,delete,approve,reject,process}`
- At least one successful `FeeTransaction` record exists (status = Success)
- The invoice linked to the transaction must be paid
- Tenant context must be initialized

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Refunds (index) | `FeeRefund::with(['originalTransaction','student.user'])->latest()` | Latest first | None | 15/page |
| Transactions (create) | `FeeTransaction::with(['student.user','invoice'])->where('status', 'Success')->orderBy('payment_date','desc')` | Only successful | None | None |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Refund no**: Auto-generated as RFD-YEAR-XXXXX — verify format on create
- **Seed data**: Create a successful transaction with paid invoice for refund tests
- **Pre-test cleanup**: Delete created refund records by ID

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_refunds`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | refund_no | VARCHAR(50) | NOT NULL, UNIQUE, format: RFD-YEAR-XXXXX |
| BC-DB-03 | original_transaction_id | INT UNSIGNED FK | NOT NULL → fee_transactions RESTRICT |
| BC-DB-04 | student_id | INT UNSIGNED FK | NOT NULL → std_students RESTRICT |
| BC-DB-05 | refund_date | DATE | NOT NULL |
| BC-DB-06 | refund_amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | refund_mode | ENUM('Cash','Cheque','Bank Transfer','Original Mode') | NOT NULL |
| BC-DB-08 | refund_reference | VARCHAR(100) | NULLABLE |
| BC-DB-09 | refund_reason | TEXT | NOT NULL |
| BC-DB-10 | approved_by | INT UNSIGNED FK NULL | → sys_users SET NULL |
| BC-DB-11 | approved_at | TIMESTAMP | NULLABLE |
| BC-DB-12 | status | ENUM('Pending','Approved','Processed','Rejected') | NOT NULL DEFAULT 'Pending' |
| BC-DB-13 | rejection_reason | TEXT | NULLABLE |
| BC-DB-14 | processed_by | INT UNSIGNED FK NULL | → sys_users SET NULL |
| BC-DB-15 | processed_at | TIMESTAMP | NULLABLE |
| BC-DB-16 | created_by | INT UNSIGNED FK NULL | → sys_users SET NULL |
| BC-DB-17 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-18 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | original_transaction_id | required, integer, exists:fee_transactions,id (where status=Success) | — |
| BC-VAL-02 | student_id | required, integer, exists:std_students,id | — |
| BC-VAL-03 | refund_date | required, date | — |
| BC-VAL-04 | refund_amount | required, numeric, min:0.01 | — |
| BC-VAL-05 | refund_mode | required, string, max:50 | — |
| BC-VAL-06 | refund_reference | nullable, string, max:100 | — |
| BC-VAL-07 | refund_reason | required, string, max:500 | — |
| BC-VAL-08 | rejection_reason (reject) | required, string, max:500 | — |
| BC-VAL-09 | refund_amount <= original amount (after) | — | "Refund amount cannot exceed the original transaction amount." |
| BC-VAL-10 | Original invoice must be paid (after) | — | "The original invoice must be paid before creating a refund." |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.fee-refund.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.fee-refund.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.fee-refund.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.fee-refund.update | edit(), update() | Without → 403 |
| BC-AUTH-05 | tenant.fee-refund.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.fee-refund.approve | approve() | Without → 403 |
| BC-AUTH-07 | tenant.fee-refund.reject | reject() | Without → 403 |
| BC-AUTH-08 | tenant.fee-refund.process | process() | Without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create refund | refund_no = RFD-YEAR-XXXXX, status=Pending, created_by=current user |
| BC-BIZ-02 | Approve pending refund | status=Approved, approved_by, approved_at set |
| BC-BIZ-03 | Approve non-pending refund | Error: "Only pending refunds can be approved." |
| BC-BIZ-04 | Reject pending refund | status=Rejected, rejection_reason set |
| BC-BIZ-05 | Reject non-pending refund | Error: "Only pending refunds can be rejected." |
| BC-BIZ-06 | Process approved refund | status=Processed, processed_by, processed_at set; original transaction marked Refunded |
| BC-BIZ-07 | Process non-approved refund | Error: "Only approved refunds can be processed." |
| BC-BIZ-08 | Edit pending refund | All fields allowed to update |
| BC-BIZ-09 | Edit non-pending refund | Error: "Only pending refunds can be edited." / "Only pending refunds can be updated." |
| BC-BIZ-10 | Delete pending refund | Soft-deleted |
| BC-BIZ-11 | Delete non-pending refund | Error: "Only pending refunds can be deleted." |
| BC-BIZ-12 | Generate refund number | Uses DB transaction with lockForUpdate(), increments max ID |
| BC-BIZ-13 | Amount > original transaction | Validation error: "Refund amount cannot exceed the original transaction amount." |
| BC-BIZ-14 | Invoice not paid | Validation error: "The original invoice must be paid before creating a refund." |
| BC-BIZ-15 | Process updates refund_reference | Optional field updated if provided |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | original_transaction_id | fee_transactions (id) | RESTRICT |
| BC-REF-02 | student_id | std_students (id) | RESTRICT |
| BC-REF-03 | approved_by | sys_users (id) | SET NULL |
| BC-REF-04 | processed_by | sys_users (id) | SET NULL |
| BC-REF-05 | created_by | sys_users (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Create Refund Request | Refund created with status=Pending, refund_no=RFD-2026-XXXXX | — | — | ⬜ |
| TC-P02 | Show Refund Details | Page loads with transaction, student, invoice, audit trail | — | — | ⬜ |
| TC-P03 | Edit Pending Refund | All fields updated successfully | — | — | ⬜ |
| TC-P04 | Approve Pending Refund | status=Approved, approved_by, approved_at set | — | — | ⬜ |
| TC-P05 | Reject Pending Refund With Reason | status=Rejected, rejection_reason stored | — | — | ⬜ |
| TC-P06 | Process Approved Refund | status=Processed, original transaction marked Refunded | — | — | ⬜ |
| TC-P07 | Full Lifecycle: Create → Approve → Process | All transitions succeed; transaction status updated | — | — | ⬜ |
| TC-P08 | Create With All Refund Modes | Cash, Cheque, Bank Transfer, Original Mode all accepted | — | — | ⬜ |
| TC-P09 | Delete Pending Refund | Refund soft-deleted | — | — | ⬜ |
| TC-P10 | Generate Refund Number Format | Format: RFD-2026-00001 (year-5 digit zero-padded) | — | — | ⬜ |
| TC-P11 | Process With Updated Reference | refund_reference updated during process | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `original_transaction_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing `refund_amount` | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing `refund_mode` | Validation error | — | — | ⬜ |
| TC-N04 | Required — Missing `refund_reason` | Validation error | — | — | ⬜ |
| TC-N05 | Amount exceeds original transaction | Error: "Refund amount cannot exceed the original transaction amount." | — | — | ⬜ |
| TC-N06 | Invoice not paid | Error: "The original invoice must be paid before creating a refund." | — | — | ⬜ |
| TC-N07 | Approve non-Pending (Approved) | Error: "Only pending refunds can be approved." | — | — | ⬜ |
| TC-N08 | Reject non-Pending (Approved) | Error: "Only pending refunds can be rejected." | — | — | ⬜ |
| TC-N09 | Reject without rejection_reason | Validation: "The rejection reason field is required." | — | — | ⬜ |
| TC-N10 | Process non-Approved (Pending) | Error: "Only approved refunds can be processed." | — | — | ⬜ |
| TC-N11 | Edit non-Pending | Error: "Only pending refunds can be edited." | — | — | ⬜ |
| TC-N12 | Delete non-Pending | Error: "Only pending refunds can be deleted." | — | — | ⬜ |
| TC-N13 | Transaction not found | 404 on findOrFail | — | — | ⬜ |
| TC-N14 | Permission 403 — No refund permissions | 403 Forbidden | — | — | ⬜ |
| TC-N15 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create → refund_no auto-generated | Format RFD-YEAR-XXXXX with incrementing ID | — | — | ⬜ |
| TC-D02 | B | Approve → approved_by and approved_at set | Both fields populated | — | — | ⬜ |
| TC-D03 | C | Process → originalTransaction.markRefunded() called | Original transaction status changed to Refunded | — | — | ⬜ |
| TC-D04 | D | Process → processed_by and processed_at set | Both fields populated | — | — | ⬜ |
| TC-D05 | E | Soft delete → deleted_at set | Record hidden from index | — | — | ⬜ |
| TC-D06 | F | Activity Logged After All State Changes | Created, Updated, Deleted, Approved, Rejected, Processed all logged | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — refund no generation uses DB transaction with lockForUpdate | `DB::transaction()` with `lockForUpdate()` | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — isPending() check before edit/update/delete/approve/reject | All non-approved states guard against invalid transitions | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — Gate::authorize() before all actions | Distinct permissions for each workflow action | — | — | ◌ |
| TC-CR04 | CR | P1 | StoreFeeRefundRequest — after validation for amount and invoice checks | `withValidator()` callback validates amount <= original and invoice paid | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P07: Full Lifecycle — Create → Approve → Process

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Refund create page | Form loads with successful transactions |
| 2 | Select original transaction (amount=50000) | Transaction selected |
| 3 | Enter refund_amount=35000, refund_mode="Bank Transfer", refund_reason="Withdrawal" | Fields filled |
| 4 | Click "Save" | Refund created; refund_no = RFD-2026-XXXXX; status=Pending |
| 5 | Navigate to refund show page | Details displayed |
| 6 | Click "Approve" | POST to approve(); status=Approved; approved_by set |
| 7 | Verify approved_by and approved_at | Both fields not null |
| 8 | Click "Process" | POST to process(); status=Processed; processed_by set |
| 9 | Check original transaction status | Transaction status updated to 'Refunded' |

### TC-N05: Amount Exceeds Original Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create refund form | Form loads |
| 2 | Select original transaction with amount=50000 | Transaction selected |
| 3 | Enter refund_amount=60000 (exceeds 50000) | Field filled |
| 4 | Click "Save" | Validation fails |
| 5 | Check error | "Refund amount cannot exceed the original transaction amount." |

---

## 8. Known Issues

- Approve/Reject/Process routes use explicit route model binding (`FeeRefund $feeRefund`) while edit/update/destroy use manual `findOrFail($id)`
- `UpdateFeeRefundRequest` includes `status` and `rejection_reason` in rules but controller only sets these via dedicated approve/reject/process methods

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/fee-refund` | `student-fee.fee-refund.index` | `index` |
| GET | `/student-fee/fee-refund/create` | `student-fee.fee-refund.create` | `create` |
| POST | `/student-fee/fee-refund` | `student-fee.fee-refund.store` | `store` |
| GET | `/student-fee/fee-refund/{id}` | `student-fee.fee-refund.show` | `show` |
| GET | `/student-fee/fee-refund/{id}/edit` | `student-fee.fee-refund.edit` | `edit` |
| PUT/PATCH | `/student-fee/fee-refund/{id}` | `student-fee.fee-refund.update` | `update` |
| DELETE | `/student-fee/fee-refund/{id}` | `student-fee.fee-refund.destroy` | `destroy` |
| POST | `/student-fee/fee-refund/{fee_refund}/approve` | `student-fee.fee-refund.approve` | `approve` |
| POST | `/student-fee/fee-refund/{fee_refund}/reject` | `student-fee.fee-refund.reject` | `reject` |
| POST | `/student-fee/fee-refund/{fee_refund}/process` | `student-fee.fee-refund.process` | `process` |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
