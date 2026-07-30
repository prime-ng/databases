# STP — Fee Summary & Payment: Test Case List

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F004 / STP-F005 / STP-F006 |
| **Feature Name** | Fee Summary, Invoice View, Payment Integration |
| **REQ ID(s)** | REQ-STP-004, REQ-STP-005, REQ-STP-006 |
| **BR ID(s)** | BR-STP-001, BR-STP-002, BR-STP-003, BR-STP-006, BR-STP-007, BR-STP-008, BR-STP-010 |
| **Controllers** | `StudentPortalController`, `FeePaymentController` |
| **Routes** | `/fee-summary`, `/view-invoice/{invoice}`, `/pay-due-amount/*`, `/fee/invoice/{invoice}/pay/*` |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| **Backend** | Laravel 12, PHP 8.2+ |
| **Database** | MySQL 8 (Tenant DB) — requires StudentFee + Payment module tables |
| **Auth** | Authenticated web session (student role) |
| **External** | Razorpay test mode (API keys configured) |
| **Test Data** | Seeded student with fee assignment, multiple invoices in various statuses |

---

## 3. Test Approach

- **Level**: Functional / System / Security
- **Type**: Positive, Negative, Boundary, Security (IDOR), Integration (Razorpay)
- **Method**: Manual + Automated (Pest)
- **Data Setup**: Requires `fee_assignments`, `fee_invoices`, `fee_structure_details` with varied statuses (Published, Partially Paid, Paid, Draft, Cancelled, Overdue)
- **Key Focus Areas**: Fee summary accuracy, invoice ownership, payment initiation guards, callback verification, Razorpay integration, double-payment prevention, race conditions

---

## 4. Test Scope

### In Scope
- Fee summary page rendering with structure breakdown and invoice list
- Invoice view with ownership guard
- Payment initiation — ownership, status, balance guards
- Payment callback — signature verification, ULID validation, amount match
- Double-payment prevention
- Concurrent payment handling
- Legacy route redirects (payDueAmount, proceedPayment)

### Out of Scope
- Razorpay checkout UI testing (third-party)
- Refund processing
- Admin invoice creation/cancellation
- Fee structure configuration

---

## 5. Test Cases

| TC ID | Test Case | Pre-condition | Test Steps | Expected Result | Priority | Automation |
|-------|-----------|---------------|------------|----------------|----------|------------|
| TC-FEE-001 | Verify fee summary page loads with structure + invoices | Student A has fee assignment with 5 structure items and 3 invoices | 1. Login as Student A<br>2. Navigate to `/fee-summary` | Page renders; fee heads listed with amounts; all 3 invoices shown with amounts, dates, status, actions | P1 | Yes |
| TC-FEE-002 | Verify fee structure breakdown accuracy | Assignment has Admission Fee (₹5000), Tuition Fee (₹25000) | 1. Login as Student A<br>2. View fee summary | Each fee head shows correct assigned/paid/balance amounts | P1 | Yes |
| TC-FEE-003 | Verify invoice listing shows correct data | Invoice: ₹10000 total, ₹4000 paid, ₹6000 balance, due 2026-08-15 | 1. Login as Student A<br>2. View fee summary | Invoice row displays correct ID, amount, paid, balance, due date, status | P1 | Yes |
| TC-FEE-004 | Verify "Pay Now" button shown for actionable invoices | Invoice status = Published (unpaid) or Partially Paid | 1. Login as Student A<br>2. View fee summary | Pay Now button visible for unpaid/partially-paid invoices; not shown for Paid/Draft/Cancelled | P1 | Yes |
| TC-FEE-005 | Verify empty state — no fee assignment | Student A has no fee assignment | 1. Login as Student A<br>2. Navigate to `/fee-summary` | Page renders; "No fee assignment" or empty state; no invoices shown | P1 | Yes |
| TC-FEE-006 | Verify viewInvoice — own invoice | Student A owns invoice with ID 101 | 1. Login as Student A<br>2. Navigate to `/view-invoice/101` | Invoice displayed with school info, student details, itemized fees, payment logs | P1 | Yes |
| TC-FEE-007 | Verify viewInvoice — another student's invoice (IDOR) | Student A, invoice 200 belongs to Student B | 1. Login as Student A<br>2. Navigate to `/view-invoice/200` | 404 Not Found response; Student B's data not exposed | P1 | Yes |
| TC-FEE-008 | Verify viewInvoice — non-existent invoice | Invoice ID 9999 does not exist | 1. Login as Student A<br>2. Navigate to `/view-invoice/9999` | 404 Not Found | P2 | Yes |
| TC-FEE-009 | Verify payDueAmount redirects | Any student | 1. Login as Student A<br>2. Navigate to `/pay-due-amount/pay-now/101` | Redirected to `/fee-summary` with error: "Fee payments can only be processed through the Parent Portal." | P2 | Yes |
| TC-FEE-010 | Verify proceedPayment redirects | Any student | 1. Login as Student A<br>2. POST to `/pay-due-amount/proceed-payment` | Redirected to `/fee-summary` with error: same message | P2 | Yes |
| TC-FEE-011 | Verify initiate payment — own unpaid invoice | Student A, Invoice 101, status = Published, balance ₹6000 | 1. Login as Student A<br>2. POST to `/fee/invoice/101/pay/initiate` | 200 JSON: `success: true`, `payment_ulid` returned, `checkout` contains Razorpay params (key, amount, currency, order_id) | P1 | Yes |
| TC-FEE-012 | Verify initiate payment — IDOR (another student's invoice) | Invoice 200 belongs to Student B | 1. Login as Student A<br>2. POST to `/fee/invoice/200/pay/initiate` | 403 Forbidden; Razorpay order not created | P1 | Yes |
| TC-FEE-013 | Verify initiate payment — already paid invoice | Invoice 101 status = Paid | 1. Login as Student A<br>2. POST to `/fee/invoice/101/pay/initiate` | 422: "Invoice is already paid." | P1 | Yes |
| TC-FEE-014 | Verify initiate payment — draft invoice | Invoice 101 status = Draft | 1. Login as Student A<br>2. POST to `/fee/invoice/101/pay/initiate` | 422: "This invoice cannot be paid." | P1 | Yes |
| TC-FEE-015 | Verify initiate payment — cancelled invoice | Invoice 101 status = Cancelled | 1. Login as Student A<br>2. POST to `/fee/invoice/101/pay/initiate` | 422: "This invoice cannot be paid." | P1 | Yes |
| TC-FEE-016 | Verify initiate payment — zero balance invoice | Invoice 101 balance = ₹0 | 1. Login as Student A<br>2. POST to `/fee/invoice/101/pay/initiate` | 422: "Invoice has no remaining balance." | P1 | Yes |
| TC-FEE-017 | Verify initiate payment — student has no auth student record | User has no student linked | 1. Login as user without student<br>2. POST to initiate | 403 Forbidden | P1 | Yes |
| TC-FEE-018 | Verify callback — successful payment | After valid Razorpay payment | 1. Initiate payment<br>2. POST callback with valid `payment_ulid`, `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature` | 200 JSON: `success: true`, `new_balance` = 0 or reduced, `new_status` = Paid/Partially Paid | P1 | Yes |
| TC-FEE-019 | Verify callback — signature verification failure | Invalid `razorpay_signature` | 1. Initiate payment<br>2. POST callback with invalid signature | 422: "Payment signature verification failed."; payment marked failed | P1 | Yes |
| TC-FEE-020 | Verify callback — mismatched payment_ulid | ULID from different payment | 1. Initiate payment for Invoice 101<br>2. POST callback with ULID from Invoice 102's payment | 403 Forbidden | P1 | Yes |
| TC-FEE-021 | Verify callback — already paid invoice | Invoice already marked Paid | 1. Pay Invoice 101<br>2. POST callback again with same data | 422: "Invoice already paid." | P1 | Yes |
| TC-FEE-022 | Verify callback — amount mismatch | Payment amount differs from invoice balance | 1. Initiate payment<br>2. Modify amount in payment record<br>3. POST callback | 422: "Paid amount does not match invoice balance." | P1 | Yes |
| TC-FEE-023 | Verify callback — Razorpay order ID mismatch | `razorpay_order_id` doesn't match `$payment->gateway_order_id` | 1. Initiate payment<br>2. POST callback with wrong order ID | 422: "Returned order ID does not match the initiated payment." | P2 | Yes |
| TC-FEE-024 | Verify callback — payment status not pending | Payment already processed (status = SUCCESS) | 1. Initiate payment<br>2. Manually mark payment success<br>3. POST callback | 422: "Payment is not in pending state." | P2 | Yes |
| TC-FEE-025 | Verify callback — missing required fields | POST without `razorpay_signature` | 1. POST callback with missing field | 422 validation error | P2 | Yes |
| TC-FEE-026 | Verify double-payment prevention — concurrent clicks | Two simultaneous initiate requests for same invoice | 1. Send 2 initiate requests simultaneously | Both succeed (Razorpay deduplication on its side); second callback will fail with "already paid" | P2 | Yes |
| TC-FEE-027 | Verify invoice status after partial payment | Invoice: ₹10000, pay ₹4000 | 1. Initiate ₹4000 payment<br>2. Complete callback successfully | New balance = ₹6000; status = Partially Paid (or Published if not yet changed) | P2 | Yes |
| TC-FEE-028 | Verify invoice status after full payment | Invoice: ₹10000, pay ₹10000 | 1. Initiate ₹10000 payment<br>2. Complete callback successfully | New balance = ₹0; status = Paid | P1 | Yes |
| TC-FEE-029 | Verify activity log — initiate payment | Student A initiates | 1. Login as Student A<br>2. POST initiate | Activity log records 'PaymentInitiated' with invoice_id, payment_ulid, amount | P3 | No |
| TC-FEE-030 | Verify activity log — successful payment | Student A completes payment | 1. Pay invoice successfully | Activity log records 'Paid' with invoice_id, amount, gateway | P3 | No |
| TC-FEE-031 | Verify activity log — failed payment | Signature verification fails | 1. POST callback with invalid signature | Activity log records 'PaymentFailed' with failure_reason | P3 | No |
| TC-FEE-032 | Verify initiate with inactive gateway | Razorpay configured as inactive | 1. Deactivate Razorpay gateway<br>2. POST initiate | 422 error from PaymentService | P2 | Yes |

---

## 6. Regression Impact

| Area | Impact | Suggested Tests |
|------|--------|----------------|
| StudentFee module | Invoice schema/status changes affect all fee flows | Verify fee summary + initiate guards after invoice changes |
| Payment module | PaymentService, GatewayManager changes affect initiate/callback | Verify full payment flow after payment module updates |
| Razorpay integration | API changes or key rotation breaks payments | Verify initiate returns valid checkout params |
| Legacy routes | If proceedPayment is re-activated without ownership check | Critical IDOR vulnerability — must re-test |

---

## 7. Known Gaps & Issues

| Gap ID | Description | Impact on Testing |
|--------|-------------|-------------------|
| SEC-STP-01 | `proceedPayment()` has no ownership check (currently redirects) | TC-FEE-010 covers current redirect behavior; must retest if route is re-activated |
| — | BR-STP-010 (rate limiting) not enforced | Cannot test max-attempt throttle; TC-FEE-026 (concurrent) covers partial concurrency |
| — | `currentFeeAssignemnt` typo may cause null if relationship renamed | TC-FEE-005 covers empty state; rename would widen impact |
| — | No idempotency key | Repeated initiate calls may create multiple Razorpay orders (TC-FEE-026) |
| — | Razorpay test mode required | Full callback flow cannot be tested without test credentials |

---

## 8. Sign-off Criteria

| Criteria | Target |
|----------|--------|
| P1 Test Cases Passed | 100% |
| P2 Test Cases Passed | 100% |
| IDOR tests passed (TC-FEE-007, TC-FEE-012, TC-FEE-020) | All pass |
| Payment flow (TC-FEE-011 → TC-FEE-018) | End-to-end passes |
| Double-payment prevention | Verified |

---

## 9. Appendices

### A. Test Data Requirements
- Student A with fee assignment: 5+ structure items, 3+ invoices (Published, Partially Paid, Paid)
- Student B with separate invoices (for IDOR tests)
- Invoice in Draft and Cancelled status each
- Invoice with zero balance
- User account without linked student record
- Razorpay test API keys in `.env`
- Gateway record with `is_active = true` and `is_active = false`

### B. Related Routes
```
GET  /fee-summary                           → feeSummary()
GET  /view-invoice/{invoice}                → viewInvoice()
GET  /pay-due-amount/pay-now/{invoice}      → payDueAmount() → redirect
POST /pay-due-amount/proceed-payment        → proceedPayment() → redirect
POST /fee/invoice/{invoice}/pay/initiate    → FeePaymentController@initiate
POST /fee/invoice/{invoice}/pay/callback    → FeePaymentController@callback
```

### C. Razorpay Test Cards
| Card | Type | Behaviour |
|------|------|-----------|
| 4111 1111 1111 1111 | Visa | Success |
| 4000 0000 0000 0002 | Visa | Declined |
| 4000 0025 0000 3155 | Visa | 3D Secure |

---

## 10. Traceability

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-004, REQ-STP-005, REQ-STP-006 |
| Business Rules | BR-STP-001, BR-STP-002, BR-STP-003, BR-STP-006, BR-STP-007, BR-STP-008, BR-STP-010 |
| Requirement Doc | `stp_FeeSummaryPayment_Requirement.md` |
| Controllers | `StudentPortalController`, `FeePaymentController` |
| Input Docs | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/finance/fee_summary.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/finance/payment_integration.md` |
