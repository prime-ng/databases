# ppt_FeeManagement_TcList

## Module: ParentPortal → Fees → Fee Management (Summary, History, Invoice, Receipt, Online Payment)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | ParentPortal |
| Tab Group | Fees |
| Feature | Fee Management — Summary, History, Invoice, Receipt, Online Payment |
| Controller(s) | `Modules\ParentPortal\Http\Controllers\ParentFeeController`<br>`Modules\ParentPortal\Http\Controllers\ParentFeePaymentController` |
| Model(s) | `Modules\StudentFee\Models\FeeInvoice`, `Modules\StudentFee\Models\FeeReceipt`, `Modules\StudentFee\Models\FeeStudentAssignment`, `Modules\Payment\Models\Payment`, `Modules\SchoolSetup\Models\Organization` |
| FormRequest(s) | None — validation is inline in `callback()` |
| Policy / Permissions | No explicit policy — IDOR guards are inline ownership checks |
| Soft Deletes | Yes — `FeeInvoice`, `FeeReceipt`, `FeeStudentAssignment` |
| Activity Log | `activityLog()` with actions: Viewed, Downloaded, PaymentInitiated, PaymentFailed, Paid |
| View(s) | `parentportal::fees.index`, `parentportal::fees.history`, `parentportal::fees.invoice`, `parentportal::fees.receipt`, `parentportal::fees.invoice-pdf` |
| PDF Service | `Barryvdh\DomPDF\Facade\Pdf` (A4 portrait) |
| Payment Gateway | Razorpay via `Modules\Payment\Services\GatewayManager` |

### URLs

| Method | URI | Name |
|--------|-----|------|
| GET | `/parent-portal/fees` | `parent-portal.fees.index` |
| GET | `/parent-portal/fees/history` | `parent-portal.fees.history` |
| GET | `/parent-portal/fees/invoice/{invoice}` | `parent-portal.fees.invoice` |
| GET | `/parent-portal/fees/receipt/{receipt}` | `parent-portal.fees.receipt` |
| GET | `/parent-portal/fees/invoice/{invoice}/download` | `parent-portal.fees.invoice.download` |
| POST | `/parent-portal/fees/invoice/{invoice}/pay/initiate` | `parent-portal.fees.invoice.pay.initiate` |
| POST | `/parent-portal/fees/invoice/{invoice}/pay/callback` | `parent-portal.fees.invoice.pay.callback` |

---

## 2. Pre-conditions

- Parent must be authenticated and logged into a tenant (school)
- Parent must have at least one linked child with `can_access_parent_portal = 1`
- Tenant must have `StudentFee` module active
- For fee data: FeeStudentAssignment records must exist for the child's current academic session
- For online payment: Razorpay must be configured in the Payment module
- For PDF generation: `storage/app/public/` must be writable
- Dusk environment: `DUSK_TENANT_URL`, `DUSK_GUARDIAN_EMAIL`, `DUSK_GUARDIAN_PASSWORD`, Razorpay test keys

---

## 3. Default Data Load

### Fee Summary (`index`)

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Assignments | `FeeStudentAssignment` | `where('student_id', $child->id)->where('is_active', true)->when(session, where academic_session_id)->with(feeStructure.details.head, invoices.installment, invoices.transactions)` | Active, current session | None |
| Invoices | Flat-mapped from assignments | `$assignments->flatMap(fn($a) => $a->invoices)->sortBy('due_date')` | All invoices | None |
| Totals | Computed | `sum(total_amount)`, `sum(paid_amount)`, `sum(balance_amount)` | — | None |
| Recent Transactions | Flat-mapped from invoices | `->filter(fn($t) => $t->status === 'Success')->sortByDesc('payment_date')` | Success only | None |

### Payment History (`history`)

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Assignments with transactions | `FeeStudentAssignment` | `with(invoices.transactions => whereIn(Success, Failed)->with(gatewayLog, collector))` | Active, Success+Failed | None |
| Transactions | Flat-mapped | `->sortByDesc('payment_date')` | All | None |
| Statistics | Computed | `successTxns`, `failedTxns`, `totalPaid`, `txnCount`, `byMonth` | — | None |

### Invoice Detail (`invoice`)

| Data | Source | Query |
|------|--------|-------|
| Invoice | `FeeInvoice` | `->load(studentAssignment.student, studentAssignment.feeStructure, installment, transactions.collector, fineTransactions)` |
| Transactions | `$invoice->transactions()` | `->where('status', 'Success')->orderByDesc('payment_date')->get()` |

---

## 4. Test Data Strategy

- Create FeeStudentAssignment records for the child in the current academic session
- Create FeeInvoice records with varying statuses (Unpaid, Paid, Overdue, Partial)
- Create FeeTransaction records with varying statuses (Success, Failed, Pending)
- Create FeeReceipt records linked to successful transactions
- For Razorpay tests use Razorpay test mode with test API keys
- Test IDOR: Create invoices for other children and attempt to access
- Test callback with invalid signatures, mismatched order IDs, and already-paid invoices
- Pre-test cleanup: Soft-delete test invoices, transactions, and receipts

---

## 5. Business Conditions

### 5.1 Database Schema — `fin_fee_invoices` (Read + Write on Payment)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | fee_student_assignment_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-03 | invoice_no | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-04 | total_amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-05 | paid_amount | DECIMAL(12,2) | NOT NULL DEFAULT 0 |
| BC-DB-06 | balance_amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | due_date | DATE | NOT NULL |
| BC-DB-08 | status | VARCHAR(50) | NOT NULL (enum in code) |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL |

### 5.2 Database Schema — `fin_transactions` (Read + Write on Payment)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-11 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-12 | invoice_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-13 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-14 | amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-15 | payment_date | DATETIME | NOT NULL |
| BC-DB-16 | payment_mode | VARCHAR(50) | NOT NULL |
| BC-DB-17 | payment_reference | VARCHAR(100) | NULL (unique for idempotency) |
| BC-DB-18 | status | ENUM(Success,Failed,Pending) | NOT NULL |
| BC-DB-19 | receipt_generated | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-20 | deleted_at | TIMESTAMP | NULL |

### 5.3 Authorization

| BC ID | Rule | Expected Behavior |
|-------|------|-------------------|
| BC-AUTH-01 | Guest access | Redirect to login |
| BC-AUTH-02 | No linked children | `resolveChild()` throws/redirects |
| BC-AUTH-03 | Invoice owner mismatch | HTTP 403 |
| BC-AUTH-04 | Receipt owner mismatch (trace through 3 FKs) | HTTP 403 |
| BC-AUTH-05 | Pay initiate — wrong child invoice | HTTP 403 |
| BC-AUTH-06 | Pay callback — wrong child invoice | HTTP 403 |
| BC-AUTH-07 | Pay callback — ULID does not match invoice | HTTP 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Fee summary load | Invoices sorted by due_date; totals computed |
| BC-BIZ-02 | Overdue detection | `isOverdue()` returns true if balance > 0 and due past |
| BC-BIZ-03 | History — only Success + Failed | Pending transactions excluded from history |
| BC-BIZ-04 | History — grouped by month | `byMonth` collection has month buckets |
| BC-BIZ-05 | Invoice detail — only Success transactions | Failed/Pending transactions excluded |
| BC-BIZ-06 | Invoice PDF download | DomPDF A4 portrait, School letterhead, named `Invoice-{no}.pdf` |
| BC-BIZ-07 | Payment initiate | Calls `PaymentService::initiate()` → returns checkout data |
| BC-BIZ-08 | Payment callback — signature verified | `RazorpayGateway::verify()` must pass |
| BC-BIZ-09 | Payment callback — already paid | 422 with "Invoice already paid." |
| BC-BIZ-10 | Payment callback — order ID mismatch | 422 "Returned order ID does not match" |
| BC-BIZ-11 | Payment callback — amount mismatch | 422 "Paid amount does not match invoice balance" |
| BC-BIZ-12 | Payment callback — row locking | `lockForUpdate()` on both Payment and FeeInvoice |
| BC-BIZ-13 | Payment callback — status check | Payment must be STATUS_PENDING → 422 if not |
| BC-BIZ-14 | Receipt detail — loads with trace chain | Transaction → Invoice → StudentAssignment → Student verified |
| BC-BIZ-15 | Activity logging | 6 different activity types logged across all endpoints |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | fee_student_assignment_id | fin_fee_student_assignments | RESTRICT |
| BC-REF-02 | invoice_id | fin_fee_invoices | RESTRICT |
| BC-REF-03 | student_id | std_students | RESTRICT |
| BC-REF-04 | collected_by | sys_users | RESTRICT |

---

## 6. Test Scenarios

| TC ID | Scenario | Description | Priority |
|-------|----------|-------------|----------|
| TC-FEE-001 | Fee summary loads correctly | Invoices, totals, recent transactions | P0 |
| TC-FEE-002 | Overdue invoice detection | Balance > 0 and due past = flagged overdue | P0 |
| TC-FEE-003 | Payment history load | Success + Failed transactions, grouped by month | P0 |
| TC-FEE-004 | Invoice detail — correct child | Full invoice rendering with successful transactions | P0 |
| TC-FEE-005 | Invoice detail — wrong child (IDOR) | 403 response | P0 |
| TC-FEE-006 | Receipt detail — correct child | Receipt rendering with trace chain | P1 |
| TC-FEE-007 | Receipt detail — wrong child (IDOR) | 403 response | P0 |
| TC-FEE-008 | Invoice PDF download | DomPDF generated and downloaded | P0 |
| TC-FEE-009 | Invoice PDF — wrong child (IDOR) | 403 response | P0 |
| TC-FEE-010 | Payment initiate — success | Razorpay order created, checkout data returned | P0 |
| TC-FEE-011 | Payment initiate — wrong child | 403 response | P0 |
| TC-FEE-012 | Payment callback — signature verified | Invoice status updated to Paid | P0 |
| TC-FEE-013 | Payment callback — invalid signature | 422, payment marked as Failed | P0 |
| TC-FEE-014 | Payment callback — already paid | 422 "Invoice already paid" | P1 |
| TC-FEE-015 | Payment callback — order ID mismatch | 422 | P1 |
| TC-FEE-016 | Payment callback — amount mismatch | 422 | P1 |
| TC-FEE-017 | Payment callback — ULID substitution | 403 | P1 |
| TC-FEE-018 | Activity logging — all 6 actions | Audit log entries for each action | P1 |
| TC-FEE-019 | Empty fee data (no invoices) | Graceful empty state | P2 |

---

## 7. Test Cases

| TC ID | Test Case | Steps | Expected Result |
|-------|-----------|-------|-----------------|
| TC-FEE-001-01 | Fee summary totals correct | 1. Create 2 invoices: ₹10,000 total, ₹5,000 paid, ₹5,000 balance<br>2. Navigate to `/parent-portal/fees` | Total: 10,000, Paid: 5,000, Balance: 5,000 |
| TC-FEE-001-02 | Invoices sorted by due date | 1. Create invoices with due dates 15-Jul, 10-Jul, 20-Jul<br>2. Check invoice list order | 10-Jul first, 15-Jul second, 20-Jul third |
| TC-FEE-002-01 | Overdue invoice flagged | 1. Create invoice due 5 days ago, balance > 0<br>2. Check fee summary | Overdue count = 1; invoice has overdue badge |
| TC-FEE-002-02 | Non-overdue not flagged | 1. Create invoice due 5 days from now<br>2. Check fee summary | Overdue count = 0 |
| TC-FEE-003-01 | Payment history shows Success and Failed | 1. Create 1 Success, 1 Failed transaction<br>2. Navigate to `/parent-portal/fees/history` | Both transactions visible; badges indicate status |
| TC-FEE-003-02 | Payment history excludes Pending | 1. Create 1 Pending transaction<br>2. Navigate to history | Pending transaction not shown |
| TC-FEE-003-03 | Payment history grouped by month | 1. Create transactions in June and July 2026<br>2. Check grouping | Two month groups visible |
| TC-FEE-003-04 | History totals computed | 1. Create 2 Success transactions: ₹5,000 + ₹3,000<br>2. Check total paid | Total paid = ₹8,000 |
| TC-FEE-004-01 | Invoice detail renders | 1. Create invoice with fee head details<br>2. Navigate to invoice detail | Invoice number, fee heads, amounts, transactions visible |
| TC-FEE-004-02 | Invoice detail — only Success txns | 1. Create 1 Success, 1 Failed transaction for invoice<br>2. View invoice detail | Only Success transaction shown |
| TC-FEE-005-01 | Invoice detail — wrong child | 1. Create invoice for child B<br>2. Access as parent of child A | HTTP 403 |
| TC-FEE-006-01 | Receipt detail renders | 1. Create receipt with trace chain<br>2. Navigate to receipt detail | Transaction ID, amount, payment date visible |
| TC-FEE-007-01 | Receipt — wrong child | 1. Create receipt for child B<br>2. Access as parent of child A | HTTP 403 |
| TC-FEE-008-01 | Invoice PDF download | 1. Create invoice for child<br>2. Click download | PDF file `Invoice-{no}.pdf` downloaded |
| TC-FEE-008-02 | Invoice PDF contains school letterhead | 1. Create Organization record<br>2. Download invoice PDF | PDF contains org name, logo |
| TC-FEE-009-01 | Invoice PDF — wrong child | 1. Create invoice for child B<br>2. Attempt download as parent of child A | HTTP 403 |
| TC-FEE-010-01 | Payment initiate returns checkout data | 1. Create unpaid invoice for child<br>2. POST to initiate endpoint | JSON with `success: true`, `payment_ulid`, `checkout` data |
| TC-FEE-011-01 | Payment initiate — wrong child | 1. Create invoice for child B<br>2. Initiate payment as parent of child A | HTTP 403 |
| TC-FEE-012-01 | Payment callback — full successful flow | 1. Initiate payment → get ulid + checkout<br>2. POST callback with valid razorpay params | Invoice status = Paid; new_balance = 0 |
| TC-FEE-012-02 | Payment callback — transaction created | 1. Complete successful payment<br>2. Check fin_transactions | Transaction created with status=Success, payment_reference set |
| TC-FEE-013-01 | Payment callback — invalid signature | 1. POST callback with fake signature<br>2. Observe response | JSON 422 with "Payment signature verification failed" |
| TC-FEE-013-02 | Payment marked Failed on invalid sig | 1. POST callback with fake signature<br>2. Check payment status | Payment status = Failed; reason logged |
| TC-FEE-014-01 | Payment callback — invoice already paid | 1. Pay invoice completely<br>2. POST callback again with same params | 422 "Invoice already paid." |
| TC-FEE-015-01 | Payment callback — order ID mismatch | 1. POST callback with wrong order_id<br>2. Observe response | 422 "Returned order ID does not match" |
| TC-FEE-016-01 | Payment callback — amount mismatch | 1. POST callback with wrong amount<br>2. Observe response | 422 "Paid amount does not match invoice balance" |
| TC-FEE-017-01 | Payment callback — ULID substitution | 1. Get payment_ulid from different invoice<br>2. POST callback with substituted ULID | HTTP 403 |
| TC-FEE-018-01 | Activity log — fee index view | 1. Navigate to fees index<br>2. Check sys_activity_logs | "Viewed fee summary" entry |
| TC-FEE-018-02 | Activity log — payment history view | 1. Navigate to payment history<br>2. Check sys_activity_logs | "Viewed payment history" entry |
| TC-FEE-018-03 | Activity log — invoice view | 1. View invoice detail<br>2. Check sys_activity_logs | "Viewed invoice" entry |
| TC-FEE-018-04 | Activity log — receipt view | 1. View receipt detail<br>2. Check sys_activity_logs | "Viewed receipt" entry |
| TC-FEE-018-05 | Activity log — invoice download | 1. Download invoice PDF<br>2. Check sys_activity_logs | "Downloaded invoice PDF" entry |
| TC-FEE-018-06 | Activity log — payment initiated | 1. Initiate payment<br>2. Check sys_activity_logs | "Initiated fee payment" entry with invoice_id and amount |
| TC-FEE-018-07 | Activity log — payment failed | 1. POST callback with invalid signature<br>2. Check sys_activity_logs | "Fee payment failed" entry with reason |
| TC-FEE-018-08 | Activity log — payment success | 1. Complete successful payment<br>2. Check sys_activity_logs | "Paid invoice" entry with invoice_id and amount |
| TC-FEE-019-01 | No invoices — empty state | 1. No fee data for child<br>2. Navigate to fees index | Shows empty state message, no crash |

---

## 8. Known Issues

| # | Issue | Severity | Status | Notes |
|---|-------|----------|--------|-------|
| 1 | ParentChildPolicy MISSING — no formal global ownership policy | P0 | ⬜ Open | CRITICAL: IDOR prevention relies on manual inline checks |
| 2 | Fee payment idempotency unverified — `recordGatewayPayment()` mechanism not confirmed | P0 | ⬜ Open | Webhook replay protection may be incomplete |
| 3 | No `is_fee_payer` gate in controllers — view-layer only | P1 | ⬜ Open | Non-fee-payer parents may see Pay button if view is wrong |
| 4 | Callback webhook behind auth middleware (SEC-004) | P0 | ⬜ Open | Razorpay webhook cannot authenticate — payments fail in production |
| 5 | No SMS receipt on payment success | P2 | ⬜ Open | FRD promises SMS dispatch in 1 min |
| 6 | Receipt PDF download not implemented (view-only) | P2 | ◌ Known | `downloadReceipt()` method does not exist |
| 7 | No partial payment support — one invoice = one transaction | P2 | ◌ Known | System designed for full invoice payment |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|--------|-----|------|-------------------|------------|
| GET | `/parent-portal/fees` | `parent-portal.fees.index` | ParentFeeController@index | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/fees/history` | `parent-portal.fees.history` | ParentFeeController@history | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/fees/invoice/{invoice}` | `parent-portal.fees.invoice` | ParentFeeController@invoice | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/fees/receipt/{receipt}` | `parent-portal.fees.receipt` | ParentFeeController@receipt | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/fees/invoice/{invoice}/download` | `parent-portal.fees.invoice.download` | ParentFeeController@downloadInvoice | web, auth, tenant, verified, ParentPortalMiddleware |
| POST | `/parent-portal/fees/invoice/{invoice}/pay/initiate` | `parent-portal.fees.invoice.pay.initiate` | ParentFeePaymentController@initiate | web, auth, tenant, verified, ParentPortalMiddleware |
| POST | `/parent-portal/fees/invoice/{invoice}/pay/callback` | `parent-portal.fees.invoice.pay.callback` | ParentFeePaymentController@callback | web, auth, tenant, verified, ParentPortalMiddleware |

---

## 10. Execution Status

| TC ID | Test Case | Status (⬜/🟨/🟩/🟥) | Tester | Date | Remarks |
|-------|-----------|----------------------|--------|------|---------|
| TC-FEE-001-01 | Fee summary totals correct | ⬜ | — | — | — |
| TC-FEE-001-02 | Invoices sorted by due date | ⬜ | — | — | — |
| TC-FEE-002-01 | Overdue invoice flagged | ⬜ | — | — | — |
| TC-FEE-002-02 | Non-overdue not flagged | ⬜ | — | — | — |
| TC-FEE-003-01 | Payment history shows Success and Failed | ⬜ | — | — | — |
| TC-FEE-003-02 | Payment history excludes Pending | ⬜ | — | — | — |
| TC-FEE-003-03 | Payment history grouped by month | ⬜ | — | — | — |
| TC-FEE-003-04 | History totals computed | ⬜ | — | — | — |
| TC-FEE-004-01 | Invoice detail renders | ⬜ | — | — | — |
| TC-FEE-004-02 | Invoice detail — only Success txns | ⬜ | — | — | — |
| TC-FEE-005-01 | Invoice detail — wrong child | ⬜ | — | — | — |
| TC-FEE-006-01 | Receipt detail renders | ⬜ | — | — | — |
| TC-FEE-007-01 | Receipt — wrong child | ⬜ | — | — | — |
| TC-FEE-008-01 | Invoice PDF download | ⬜ | — | — | — |
| TC-FEE-008-02 | Invoice PDF contains school letterhead | ⬜ | — | — | — |
| TC-FEE-009-01 | Invoice PDF — wrong child | ⬜ | — | — | — |
| TC-FEE-010-01 | Payment initiate returns checkout data | ⬜ | — | — | — |
| TC-FEE-011-01 | Payment initiate — wrong child | ⬜ | — | — | — |
| TC-FEE-012-01 | Payment callback — full successful flow | ⬜ | — | — | — |
| TC-FEE-012-02 | Payment callback — transaction created | ⬜ | — | — | — |
| TC-FEE-013-01 | Payment callback — invalid signature | ⬜ | — | — | — |
| TC-FEE-013-02 | Payment marked Failed on invalid sig | ⬜ | — | — | — |
| TC-FEE-014-01 | Payment callback — invoice already paid | ⬜ | — | — | — |
| TC-FEE-015-01 | Payment callback — order ID mismatch | ⬜ | — | — | — |
| TC-FEE-016-01 | Payment callback — amount mismatch | ⬜ | — | — | — |
| TC-FEE-017-01 | Payment callback — ULID substitution | ⬜ | — | — | — |
| TC-FEE-018-01 | Activity log — fee index view | ⬜ | — | — | — |
| TC-FEE-018-02 | Activity log — payment history view | ⬜ | — | — | — |
| TC-FEE-018-03 | Activity log — invoice view | ⬜ | — | — | — |
| TC-FEE-018-04 | Activity log — receipt view | ⬜ | — | — | — |
| TC-FEE-018-05 | Activity log — invoice download | ⬜ | — | — | — |
| TC-FEE-018-06 | Activity log — payment initiated | ⬜ | — | — | — |
| TC-FEE-018-07 | Activity log — payment failed | ⬜ | — | — | — |
| TC-FEE-018-08 | Activity log — payment success | ⬜ | — | — | — |
| TC-FEE-019-01 | No invoices — empty state | ⬜ | — | — | — |

---

*End of ppt_FeeManagement_TcList.md*
