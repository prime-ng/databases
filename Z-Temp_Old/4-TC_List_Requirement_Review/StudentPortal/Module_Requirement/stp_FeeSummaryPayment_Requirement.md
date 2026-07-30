# STP — Fee Summary & Payment

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F004 / STP-F005 / STP-F006 |
| **Feature Name** | Fee Summary, Invoice View, Payment Integration |
| **REQ ID(s)** | REQ-STP-004 (Invoice View), REQ-STP-005 (Payment), REQ-STP-006 (Fee Summary) |
| **BR ID(s)** | BR-STP-001, BR-STP-002, BR-STP-003, BR-STP-006, BR-STP-007, BR-STP-008, BR-STP-010 |
| **Controllers** | `StudentPortalController` (feeSummary, viewInvoice, payDueAmount, proceedPayment), `FeePaymentController` (initiate, callback) |
| **Routes** | GET `/fee-summary`, GET `/view-invoice/{invoice}`, GET `/pay-due-amount/pay-now/{invoice}`, POST `/pay-due-amount/proceed-payment`, POST `/fee/invoice/{invoice}/pay/initiate`, POST `/fee/invoice/{invoice}/pay/callback` |
| **Views** | `studentportal::fee.summary`, `studentportal::academic-information.invoice` |
| **Table Prefix** | `fee_*`, `pay_*` (reads from StudentFee + Payment modules) |
| **DB Layer** | Tenant |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Feature Overview

Provides students with a complete fee management interface: a summary of their fee structure and invoice status, detailed invoice view, and online payment via Razorpay. The payment flow uses the Payment module's `PaymentService` and `GatewayManager` with Razorpay as the primary gateway.

**Critical Security Gap (SEC-STP-01):** The legacy `proceedPayment()` method in `StudentPortalController` has NO ownership check before creating a Razorpay order. The new `FeePaymentController` methods (`initiate`, `callback`) DO have ownership checks.

---

## 3. Functional Requirements

### 3.1 Fee Summary Overview (REQ-STP-006)
- Displays fee structure breakdown showing fee heads (Admission Fee, Tuition Fee, Lab Fee, etc.) with assigned amount, paid amount, and remaining balance.
- Lists all invoices for the student's current fee assignment, showing: invoice ID, total amount, paid amount, balance, due date, status.
- Links to "View Details" (invoice view) and "Pay Now" for unpaid/partially-paid invoices.

### 3.2 Invoice View (REQ-STP-004)
- Displays a printable invoice showing: school information, student information, invoice details, itemized fees, payment logs.
- Ownership guard: `FeeInvoice::whereHas('studentAssignment', fn($q) => $q->where('student_id', $studentId))->findOrFail($id)`.
- Accessible via `/view-invoice/{invoice}`.

### 3.3 Payment Flow (REQ-STP-005)

#### 3.3.1 Initiate Payment
- `POST /fee/invoice/{invoice}/pay/initiate` → `FeePaymentController@initiate`
- Ownership check: `$invoice->studentAssignment->student_id !== $authStudentId` → 403.
- Invoice status check: isPaid → 422, DRAFT/CANCELLED → 422, balance ≤ 0 → 422.
- Calls `PaymentService::initiate($invoice, 'razorpay')` to create Razorpay order.
- Returns JSON: `{ success: true, payment_ulid, checkout: { key, amount, currency, order_id, description, prefill } }`.

#### 3.3.2 Callback / Verification
- `POST /fee/invoice/{invoice}/pay/callback` → `FeePaymentController@callback`
- Validates `payment_ulid`, `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature`.
- Ownership check re-verified.
- ULID validation: `$payment->payable_type === FeeInvoice::class && $payment->payable_id === $invoice->getKey()`.
- Double-payment guard: `$invoice->isPaid()` → 422.
- Signature verification via `RazorpayGateway::verify()`.
- Amount mismatch guard: `$payment->amount !== $invoice->getBalanceAmount()` → 422.
- DB transaction with `lockForUpdate` to prevent race conditions.
- On success: marks payment success, records fee transaction via `FeeInvoiceService::recordGatewayPayment()`.
- Returns JSON: `{ success: true, new_balance, new_status }`.

### 3.4 Legacy Routes (Replaced)
- `payDueAmount($id)` → redirects to fee-summary with error: "Fee payments can only be processed through the Parent Portal."
- `proceedPayment(Request)` → redirects to fee-summary with error (same message).

---

## 4. Non-Functional Requirements

| NFR-ID | Requirement | Threshold |
|--------|------------|-----------|
| NFR-STP-006 | IDOR prevention | Ownership check before each operation |
| NFR-STP-011 | PCI DSS compliance | No card data stored; Razorpay tokenization |
| NFR-STP-008 | Error handling | No stack traces; student-friendly messages |
| — | Payment attempt rate limit | Max 3 attempts per 5 minutes per user (FRD BR-STP-010) — **not verified in controller** |

---

## 5. Business Rules

| Rule ID | Description | Enforcement |
|---------|-------------|-------------|
| BR-STP-001 | Data belongs to authenticated student | `auth()->user()->student` scoping |
| BR-STP-002 | Invoice ownership via fee assignment chain | `$invoice->studentAssignment->student_id` check |
| BR-STP-003 | Server-side ownership check before Razorpay order | `abort_if(mismatch, 403)` in `initiate()` |
| BR-STP-006 | Invoice must be Published, Partially Paid, or Overdue to pay | `abort_if(isPaid, ...)` + `abort_if(DRAFT/CANCELLED, ...)` |
| BR-STP-007 | Payment amount: 1 ≤ amount ≤ remaining balance | Amount mismatch guard in `callback()` (amount vs balance) |
| BR-STP-008 | Gateway must be Active | `PaymentService` resolves active gateway |
| BR-STP-010 | Max 3 payment attempts per 5 minutes | **Not explicitly enforced in controller** — gap |
| — | Double-payment prevention | `isPaid()` check + `lockForUpdate` transaction |
| — | Payment ULID must match invoice | `$payment->payable_id !== $invoice->getKey()` → 403 |
| — | Payment must be PENDING status | `lockForUpdate` → `$payment->status !== PENDING` → 422 |

---

## 6. User Interface / UX

- **Fee Summary Page**: Tabular layout with fee structure breakdown + invoices list. "Pay Now" buttons for actionable invoices.
- **Invoice View**: Printable layout with school logo, student details, line items, totals, payment history.
- **Payment Initiation**: Clicking "Pay Now" opens a Razorpay checkout overlay modal.
- **Payment Callback**: After Razorpay completion, frontend sends verification data to server.
- **Error States**: Invalid invoice → 404; already paid → 422 message; ownership mismatch → 403.

---

## 7. Data Dictionary

| Variable | Source | Type | Description |
|----------|--------|------|-------------|
| `assignment` | `$student->currentFeeAssignemnt` | Model | Current fee assignment with structure + invoices |
| `latestInvoice` | `$assignment->invoices->sortByDesc('id')->first()` | Model | Most recent invoice |
| `allInvoices` | `$assignment->invoices->sortByDesc('id')` | Collection | All invoices (or empty) |
| `feeInvoice` | `FeeInvoice::whereHas('studentAssignment', ...)` | Model | Single invoice with ownership check |
| `payment_ulid` | `PaymentService::initiate()` | string | Unique payment reference |
| `checkout` | `PaymentService::initiate()` | array | Razorpay checkout options |

---

## 8. API / Controller Specifications

### `StudentPortalController@feeSummary()`
| Aspect | Detail |
|--------|--------|
| **Method** | `GET /fee-summary` |
| **Auth** | Web `auth` |
| **Load** | `student.currentFeeAssignemnt.feeStructure.details.head`, `student.currentFeeAssignemnt.invoices` |
| **Empty State** | If no assignment, `$assignment = null`; views handle null |

### `StudentPortalController@viewInvoice($id)`
| Aspect | Detail |
|--------|--------|
| **Method** | `GET /view-invoice/{invoice}` |
| **Ownership** | `whereHas('studentAssignment', fn => where('student_id', $studentId))` |
| **Not Found** | `findOrFail($id)` — returns 404 if not own invoice |

### `FeePaymentController@initiate(Request, FeeInvoice $invoice)`
| Aspect | Detail |
|--------|--------|
| **Method** | `POST /fee/invoice/{invoice}/pay/initiate` |
| **Ownership** | `$invoice->studentAssignment->student_id !== $authStudentId` → 403 |
| **Status Guard** | isPaid → 422; DRAFT/CANCELLED → 422; balance ≤ 0 → 422 |
| **Response** | JSON `{ success, payment_ulid, checkout }` or `{ success: false, error }` with 422 |

### `FeePaymentController@callback(Request, FeeInvoice $invoice)`
| Aspect | Detail |
|--------|--------|
| **Method** | `POST /fee/invoice/{invoice}/pay/callback` |
| **Validation** | `payment_ulid` (required, string), `razorpay_payment_id` (required), `razorpay_order_id` (required), `razorpay_signature` (required) |
| **Ownership** | Same as initiate |
| **ULID Guard** | `$payment->payable_id !== $invoice->getKey()` → 403 |
| **Amount Guard** | `$payment->amount !== $invoice->getBalanceAmount()` → 422 |
| **Signature** | Verified via `RazorpayGateway::verify()` |
| **Transaction** | `lockForUpdate`, `markSuccess`, `recordGatewayPayment` |
| **Response** | JSON `{ success, new_balance, new_status }` |

---

## 9. Validation Rules

### FeePaymentController@initiate
| Field | Rule | Error |
|-------|------|-------|
| Invoice ownership | `$invoice->studentAssignment->student_id === $authStudentId` | 403 Forbidden |
| Invoice status | Not isPaid, not DRAFT, not CANCELLED | 422 with message |
| Balance | `getBalanceAmount() > 0` | 422 |
| Gateway | `'razorpay'` | 422 if inactive |

### FeePaymentController@callback
| Field | Rule | Error |
|-------|------|-------|
| `payment_ulid` | required, string | 422 validation |
| `razorpay_payment_id` | required, string | 422 validation |
| `razorpay_order_id` | required, string | 422 validation |
| `razorpay_signature` | required, string | 422 validation |
| Payment ownership | `payable_id === invoice.id && payable_type === FeeInvoice` | 403 |
| Already paid | `!$invoice->isPaid()` | 422 |
| Amount | `(float) $payment->amount === (float) $invoice->getBalanceAmount()` | 422 |
| Payment status | `$payment->status === PENDING` | 422 |
| Signature | `$driver->verify(...)` | 422 |

---

## 10. Error Handling & Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Student has no fee assignment | Fee summary shows empty state; no invoices |
| Student views own invoice | Invoice rendered with full details |
| Student views another student's invoice | 404 Not Found (ownership guard in `viewInvoice`) |
| Student initiates payment on paid invoice | 422: "Invoice is already paid." |
| Student initiates payment on draft invoice | 422: "This invoice cannot be paid." |
| Student initiates payment on zero-balance invoice | 422: "Invoice has no remaining balance." |
| Student tries to pay another student's invoice via initiate | 403 Forbidden |
| Payment callback with mismatched payment_ulid | 403: ULID doesn't belong to invoice |
| Payment callback with already paid invoice | 422: "Invoice already paid." |
| Signature verification fails | Payment marked failed; 422 with message |
| Amount mismatch between payment and invoice balance | 422: "Paid amount does not match invoice balance." |
| Payment status not PENDING (race condition) | 422: "Payment is not in pending state." |
| Razorpay order ID mismatch | 422: "Returned order ID does not match the initiated payment." |
| Concurrent payments on same invoice | Second transaction hits `lockForUpdate` and sees PENDING check fail |
| PHP silent file drop (not applicable here) | N/A — no file uploads |

---

## 11. Security & Compliance

| Concern | Status | Detail |
|---------|--------|--------|
| **IDOR — viewInvoice** | ✅ | `whereHas('studentAssignment')` ownership chain |
| **IDOR — initiate** | ✅ | `$invoice->studentAssignment->student_id !== $authStudentId` |
| **IDOR — callback** | ✅ | Same + ULID validation |
| **IDOR — proceedPayment (legacy)** | ❌ **CRITICAL** | No ownership check — **redirects with error, does not process** |
| **IDOR — payDueAmount (legacy)** | ❌ | Same pattern — **redirects** |
| **Rate Limiting** | ⚠️ | BR-STP-010 (3/5min) not explicitly enforced |
| **PCI DSS** | ✅ | No card data stored; Razorpay handles tokenization |
| **Double Payment** | ✅ | isPaid() guard + lockForUpdate transaction |
| **Signature Verification** | ✅ | Server-side Razorpay signature verification |

---

## 12. Integration Points

| Module | Integration | Direction |
|--------|-------------|-----------|
| StudentFee (FIN) | `fee_invoices`, `fee_assignments`, `fee_structure_details` | STP ← FIN |
| Payment | `PaymentService`, `GatewayManager`, `RazorpayGateway`, `pay_payments` | STP ← Payment |
| StudentProfile (STD) | `std_students` — student identity | STP ← STD |
| StudentFee (FIN) | `FeeInvoiceService::recordGatewayPayment()` | STP → FIN |

---

## 13. Performance Considerations

- Fee summary loads entire invoice collection (no pagination) — acceptable for typical school year (1–12 invoices).
- `PaymentService::initiate()` makes an HTTP call to Razorpay API — network latency adds ~500ms–2s.
- `lockForUpdate` in callback transaction ensures consistency but reduces concurrency.
- No caching on fee summary.

---

## 14. Dependencies & Pre-requisites

| Dependency | Type | Status |
|-----------|------|--------|
| Razorpay merchant account configured | External | Required |
| Payment module installed and active | Module | Required |
| StudentFee (FIN) module installed | Module | Required |
| Razorpay API keys in .env | Config | Required |
| Fee invoice records with Published status | Data | Required for payment flow |
| Student has currentFeeAssignemnt relation | Data | Required for fee summary |

---

## 15. Known Gaps & Issues

| Gap ID | Description | Severity | Status |
|--------|-------------|----------|--------|
| **SEC-STP-01** | **IDOR in `proceedPayment()`** — legacy method has no ownership check before Razorpay order. Currently redirects with error, but if ever re-enabled, is vulnerable. | **Critical** | 🟡 Mitigated (redirect only) |
| **SEC-STP-13** | `viewInvoice()` ownership guard may theoretically fail if `whereHas('studentAssignment')` chain breaks | Medium | 🟡 Open |
| — | BR-STP-010 (max 3 attempts per 5 min) not enforced | Medium | ⬜ Open |
| — | `currentFeeAssignemnt` typo in relationship name (`Assignemnt` instead of `Assignment`) | Low | ⬜ Cosmetic |
| — | `proceedPayment()` and `payDueAmount()` are dead routes — redirected to parent portal message | Low | ⬜ Tech debt |
| — | No idempotency key on initiate — duplicate clicks may create multiple Razorpay orders | Low | ⬜ Open |

---

## 16. Traceability Matrix

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-004, REQ-STP-005, REQ-STP-006 |
| Business Rules | BR-STP-001, BR-STP-002, BR-STP-003, BR-STP-006, BR-STP-007, BR-STP-008, BR-STP-010 |
| Controller Methods | `feeSummary`, `viewInvoice`, `payDueAmount`, `proceedPayment`, `initiate`, `callback` |
| Routes | `/fee-summary`, `/view-invoice/{invoice}`, `/pay-due-amount/pay-now/{invoice}`, `/pay-due-amount/proceed-payment`, `/fee/invoice/{invoice}/pay/initiate`, `/fee/invoice/{invoice}/pay/callback` |
| Views | `studentportal::fee.summary`, `studentportal::academic-information.invoice` |
| Input Docs | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/finance/fee_summary.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/finance/payment_integration.md` |
