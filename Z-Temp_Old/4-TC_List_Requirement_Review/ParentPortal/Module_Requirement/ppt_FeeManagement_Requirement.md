# Fee Management — Parent Portal (Summary, History, Invoice, Receipt, Online Payment)

## What This Screen Does

The Fee Management feature in the Parent Portal gives parents a comprehensive view of their active child's school fee accounts — invoices outstanding, payment history, invoice details, and receipts — along with the ability to pay invoices online via Razorpay and download PDF invoice and receipt documents. This is a combined feature spanning fee summary (dashboard-like overview), payment history, individual invoice and receipt viewing, and online payment initiation with callback verification.

---

## When This Screen Is Used

- **Monthly Fee Check:** A parent checks which invoices are due for the current month and their total outstanding balance.
- **Making a Payment:** A parent selects an unpaid invoice and pays it online via UPI, Card, or NetBanking through Razorpay.
- **Downloading Invoice/Receipt:** A parent downloads an official PDF invoice for their records, or downloads a payment receipt after a successful transaction.
- **Reviewing Payment History:** A parent views all past transactions (successful and failed) to reconcile payments made during the academic year.

---

## Default Data Load

### Fee Summary (`index`)

When the parent opens the Fee screen, the system loads:

1. **All Fee Student Assignments** — Active assignments for the child's current academic session, with fee structure, invoices, installments, and transactions eager-loaded.
2. **Invoices** — Flat-mapped from all assignments, sorted by `due_date` ascending. Each invoice shows total amount, paid amount, balance amount, due date, status, and overdue indicator.
3. **Totals** — Computed aggregates: `totalAmount`, `paidAmount`, `balanceAmount`, `overdueCount`.
4. **Recent Transactions** — All successful transactions across all invoices, sorted by `payment_date` descending (limited to recent items on the summary page).

### Payment History (`history`)

- All transactions (Success + Failed) for the child across all active assignments, sorted by `payment_date` descending.
- Grouped into `successTxns`, `failedTxns`, and `byMonth` (for monthly aggregation).
- Statistics: `totalPaid`, `txnCount`.

### Invoice Detail (`invoice`)

- Single invoice with fee structure, installment, successful transactions (with collector info), and fine transactions.
- IDOR guard verifies the invoice belongs to the active child.

### Receipt Detail (`receipt`)

- Single receipt with transaction, invoice, installment, and collector info.
- IDOR guard traces receipt through transaction → invoice → student assignment → student.

---

## Key Fields at a Glance

**Invoice Number** — A unique identifier for the fee invoice (e.g., "INV-2026-0001"). Displayed prominently at the top of the invoice detail page.

**Fee Heads** — Breakdown of the total amount by fee head (Tuition, Transport, Library, etc.), each with its own amount. Loaded through `feeStructure.details.head`.

**Installment Name** — The term installment this invoice belongs to (e.g., "Term 1", "Quarter 2").

**Due Date** — The date by which the invoice must be paid. Overdue invoices are flagged with a red badge and counted in `overdueCount`.

**Amount Summary** — Total Amount, Paid Amount, and Balance Amount displayed as a summary card at the top of the fee page.

**Payment Status Badges:**
- **Paid** (green): Invoice with zero balance
- **Unpaid** (blue): Invoice with balance equal to total
- **Partial** (amber): Invoice with balance between 0 and total
- **Overdue** (red): Invoice past due with balance > 0

**Transaction Reference** — Razorpay payment ID for online payments, shown on the history page and receipt.

---

## Business Rules and Conditions

**IDOR Guard — Child Ownership Verification (BR-PPT-002, BR-PPT-012)**
Every fee endpoint that accesses a specific invoice or receipt verifies that the resource belongs to the active child. The `invoice()` method checks `$invoice->studentAssignment->student_id === $child->id`. The `receipt()` method traces back through `receipt → transaction → invoice → studentAssignment → student_id`. Both return HTTP 403 if the check fails.

**Payment Initiation — Razorpay Order (FRD Ref: REQ-PPT-005)**
The `initiate()` method verifies child ownership, then delegates to `PaymentService::initiate()` to create a Razorpay order. The response includes the `payment_ulid` and Razorpay `checkout` data. If the invoice does not belong to the child, HTTP 403 is returned.

**Payment Callback — Signature Verification (BR-PPT-018)**
The `callback()` method validates four required fields: `payment_ulid`, `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature`. It then:
1. Verifies child ownership of the invoice
2. Validates the ULID matches the invoice (prevents ULID substitution)
3. Checks invoice is not already paid (idempotency)
4. Verifies Razorpay signature via `RazorpayGateway::verify()`
5. Validates `gateway_order_id` matches the initiated payment
6. Validates the payment amount matches the invoice balance
7. Locks both payment and invoice rows (`lockForUpdate`)
8. Marks payment success and records the gateway transaction

If any verification fails, the payment is marked as Failed with a descriptive reason, and an appropriate HTTP error (422) is returned.

**Invoice Already Paid Guard**
If the invoice's `isPaid()` returns true, the callback returns a 422 with message "Invoice already paid."

**PDF Generation — DomPDF**
Both `downloadInvoice()` and receipt generation use DomPDF (`Barryvdh\DomPDF\Facade\Pdf`) with A4 portrait paper. The invoice PDF uses a Blade template (`parentportal::fees.invoice-pdf`) with school organization details loaded from `Organization::first()`.

**Payment History Filtering**
The `history()` method queries only `Success` and `Failed` status transactions. The fee summary `index()` only loads `Success` transactions. The invoice detail page only loads `Success` transactions for the invoice.

---

## Workflow Steps

**Viewing Fee Summary**
The parent navigates to Fees from the sidebar. `ParentFeeController::index()` resolves the active child, loads all assignments with invoices, computes totals, and renders the summary view. The parent sees their total outstanding, a list of invoices sorted by due date, and recent successful transactions.

**Viewing Invoice Detail**
The parent clicks an invoice to open `ParentFeeController::invoice($invoice)`. The system loads the full invoice with structure, installment, and successful transactions. The IDOR guard verifies the invoice belongs to the active child before any data is displayed.

**Downloading Invoice PDF**
The parent clicks "Download Invoice" on the invoice detail page. `ParentFeeController::downloadInvoice($invoice)` verifies ownership, loads the invoice with all relationships plus the school organization, generates a DomPDF, and returns it as a downloadable PDF file named `Invoice-{invoice_no}.pdf`.

**Paying an Invoice (Online)**
The parent clicks "Pay Now" on an unpaid invoice. A POST request is sent to `ParentFeePaymentController::initiate()`. If ownership is verified, a Razorpay order is created, and the response returns Razorpay checkout data. The parent completes payment in the Razorpay hosted checkout (UPI/Card/NetBanking/Wallet). After payment, the Razorpay callback fires a POST to `callback()`, which verifies the signature, checks idempotency, and updates the invoice status to Paid. The invoice detail page then shows the new balance (zero) and status (Paid).

**Viewing Payment History**
The parent navigates to the "Payment History" sub-tab. `ParentFeeController::history()` loads all Success + Failed transactions, sorts by payment date descending, and groups by month. The parent sees a chronological list with amounts, payment modes, and status badges.

**Viewing Receipt**
The parent clicks a receipt link from the history page or invoice detail. `ParentFeeController::receipt($receipt)` loads the receipt with its transaction chain, verifies ownership via the trace chain, and renders the receipt detail.

---

## Example Scenario

**Scenario: Monthly Fee Payment**

Ms. Iyer logs into the Parent Portal to check her daughter Kavya's fee status for the current term. On the Fee Summary page, she sees:
- **Total Outstanding:** ₹12,500
- **Total Paid:** ₹25,000
- **Overdue:** 1 invoice

She scrolls to the invoice list:
1. **Term 1 Tuition** — ₹15,000 — Due: 15 Apr 2026 — Paid ✅
2. **Term 1 Transport** — ₹5,000 — Due: 15 Apr 2026 — Paid ✅
3. **Term 1 Library Fee** — ₹2,500 — Due: 15 Apr 2026 — Overdue 🔴
4. **Term 2 Tuition** — ₹15,000 — Due: 15 Jul 2026 — Unpaid

She clicks Invoice #3 (Library Fee), sees the breakdown, and clicks "Pay Now." Razorpay opens with UPI options. She pays ₹2,500 via Google Pay. Razorpay redirects back, and the system processes the callback. The invoice now shows as Paid. She downloads the receipt as a PDF.

---

## Related Screens

- **Parent Dashboard** (fee summary widget with total outstanding and next due date)
- **Invoice Detail** (click-through from fee summary)
- **Payment History** (sub-tab under Fees)
- **Receipt Detail** (click-through from history or invoice)
- **StudentFee Module** (admin side — fee structure, invoice management)

---

## Business Conditions

### 5.1 Database Schema — `fin_fee_invoices` (Read + Status Update)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | fee_student_assignment_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-03 | invoice_no | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-04 | total_amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-05 | paid_amount | DECIMAL(12,2) | NOT NULL, DEFAULT 0 |
| BC-DB-06 | balance_amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | due_date | DATE | NOT NULL |
| BC-DB-08 | status | ENUM | NOT NULL (e.g., Unpaid, Paid, Overdue) |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Database Schema — `fin_transactions` (Read-Only in Portal)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-11 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-12 | invoice_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-13 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-14 | amount | DECIMAL(12,2) | NOT NULL |
| BC-DB-15 | payment_date | DATETIME | NOT NULL |
| BC-DB-16 | payment_mode | VARCHAR(50) | NOT NULL |
| BC-DB-17 | payment_reference | VARCHAR(100) | NULL (Razorpay payment_id) |
| BC-DB-18 | status | ENUM | NOT NULL (Success, Failed, Pending) |
| BC-DB-19 | collected_by | INT UNSIGNED FK | NOT NULL (who recorded) |
| BC-DB-20 | receipt_generated | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-21 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.3 Authorization

| BC ID | Rule | Behavior |
|-------|------|----------|
| BC-AUTH-01 | Parent authenticated | Unauthenticated → redirect to login |
| BC-AUTH-02 | Child ownership (summary) | `resolveChild()` ensures fee data scoped to active child |
| BC-AUTH-03 | Invoice ownership (IDOR) | `$invoice->studentAssignment->student_id === $child->id` → 403 |
| BC-AUTH-04 | Receipt ownership (IDOR trace) | Three-level FK trace → 403 if mismatch |
| BC-AUTH-05 | Payment initiation ownership | Same invoice ownership check → 403 |
| BC-AUTH-06 | Payment callback ownership | Same check + ULID binding → 403 |
| BC-AUTH-07 | Already paid guard | `isPaid()` check → 422 "Invoice already paid" |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Fee summary load | Loads all assignments + invoices for child's current session |
| BC-BIZ-02 | Total computation | `sum(total_amount)`, `sum(paid_amount)`, `sum(balance_amount)` |
| BC-BIZ-03 | Overdue detection | `$invoice->isOverdue()` — balance > 0 AND due_date < now() |
| BC-BIZ-04 | History load | Only Success + Failed transactions (Pending excluded) |
| BC-BIZ-05 | History by month | `$successTxns->groupBy(fn($t) => $t->payment_date->format('M Y'))` |
| BC-BIZ-06 | Invoice transaction filter | Only Success transactions shown on invoice detail |
| BC-BIZ-07 | Payment initiation | Delegates to `PaymentService::initiate($invoice, 'razorpay')` |
| BC-BIZ-08 | Payment callback validates 4 fields | `payment_ulid`, `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature` — all required |
| BC-BIZ-09 | ULID substitution prevention | `$payment->payable_type === FeeInvoice::class && $payment->payable_id === $invoice->getKey()` |
| BC-BIZ-10 | Razorpay signature verification | `RazorpayGateway::verify([...])` — 422 on failure |
| BC-BIZ-11 | Order ID mismatch | If `$payment->gateway_order_id !== $request->razorpay_order_id` → 422 |
| BC-BIZ-12 | Amount mismatch | If `$payment->amount !== $invoice->getBalanceAmount()` → 422 |
| BC-BIZ-13 | Row locking for transaction | `Payment::lockForUpdate()` and `FeeInvoice::lockForUpdate()` |
| BC-BIZ-14 | Payment status check | `$payment->status !== STATUS_PENDING` → 422 |
| BC-BIZ-15 | Invoice PDF download | DomPDF A4 portrait, school letterhead, named `Invoice-{no}.pdf` |
| BC-BIZ-16 | Activity logging | All actions logged: Viewed, Downloaded, PaymentInitiated, PaymentFailed, Paid |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | fee_student_assignment_id | fin_fee_student_assignments | RESTRICT |
| BC-REF-02 | invoice_id | fin_fee_invoices | RESTRICT |
| BC-REF-03 | student_id | std_students | RESTRICT |
| BC-REF-04 | collected_by | sys_users | RESTRICT |

---

## Validation Rules

### Payment Callback Validation (`ParentFeePaymentController::callback()`)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | payment_ulid | required, string | — |
| BC-VAL-02 | razorpay_payment_id | required, string | — |
| BC-VAL-03 | razorpay_order_id | required, string | — |
| BC-VAL-04 | razorpay_signature | required, string | — |

### Payment Initiation

| BC ID | Condition | Error Message |
|-------|-----------|---------------|
| BC-VAL-05 | Invoice ownership mismatch | HTTP 403 |
| BC-VAL-06 | Initiation service throws exception | `$e->getMessage()` returned with 422 |

### Invoice/Receipt Access

| BC ID | Condition | Error Message |
|-------|-----------|---------------|
| BC-VAL-07 | Invoice not found | 404 (model binding) |
| BC-VAL-08 | Invoice ownership mismatch | HTTP 403 |
| BC-VAL-09 | Receipt ownership mismatch | HTTP 403 |

---

## V1/V2 Gaps

| Gap | Type | Description | Impact |
|-----|------|-------------|--------|
| ParentChildPolicy MISSING | P0 Security | No formal policy — relies on manual ownership checks in each method | Low — checks are explicit and thorough |
| Fee payment idempotency unverified | P0 Security | PaymentService `recordGatewayPayment()` idempotency mechanism not verified in code; callback relies on `isPaid()` guard + unique constraint on payment_reference | Medium — webhook replay protection may be incomplete |
| No is_fee_payer gate in controller | P1 Gap | FRD says non-fee-payer parents see summary only (Pay button hidden). Controller does not check `is_fee_payer` flag — view must handle this | Medium — view-layer enforcement needed |
| No SMS receipt on payment success | P2 Enhancement | FRD promises SMS receipt within 1 minute; not implemented in callback | Missing notification step |
| Non-fee-payer parent Pay button visibility | P1 Gap | Must be checked in view layer | May show Pay button incorrectly |
| Receipt PDF download not implemented | P2 Gap | `ParentFeeController` has `receipt()` (view) but no `downloadReceipt()` method | Only invoice PDF download exists |
| Callback Razorpay webhook behind auth middleware | P0 Security Issue (SEC-004) | Webhook endpoint requires auth — Razorpay cannot authenticate | Online payments fail in production |

---

## Module Integration

| Integration | Direction | Details |
|-------------|-----------|---------|
| StudentFee | Read + Write | `FeeInvoice`, `FeeReceipt`, `FeeStudentAssignment`, `FeeTransaction` |
| Payment module | Read + Write | `Payment`, `GatewayManager`, `PaymentService`, `RazorpayGateway` |
| ParentContextService | Read | Child resolution |
| DomPDF | Read (PDF) | Invoice and receipt PDF generation |
| SchoolSetup | Read | `Organization` model for school letterhead |
| sys_activity_logs | Write | Audit log |
| Razorpay (external) | API | Order creation + signature verification |

---

## Known Limitations

- No ability to pay multiple invoices at once (one invoice per transaction)
- No payment via cheque/DD/cash from portal (online only)
- No refund or dispute handling from portal
- Receipt PDF download endpoint not implemented (view-only)
- SMS receipt notification not implemented
- Non-fee-payer enforcement is view-layer only

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-23 | AI | Initial requirement doc from live code audit + FRD analysis |

---

*End of ppt_FeeManagement_Requirement.md*
