# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 04: Fees & Payment Integration

---

## 1. Executive Summary
This is the financial hub for parents. It aggregates data from `StudentFee` and processes transactions via the `Payment` module (e.g., Razorpay).

## 2. Core Components
- `ParentFeeController.php`
- `ParentFeePaymentController.php`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Fee Overview & Ledgers (`ParentFeeController`)
- **Index View:** Lists all invoices assigned to the active child for the current academic session (`FeeStudentAssignment`).
- **Calculations:** Displays `total_amount`, `paid_amount`, `balance_amount`, and explicitly counts `overdue` invoices (where `due_date < now()`).
- **History Tab:** A consolidated view of all `Success` and `Failed` transactions across all years, grouped by month.
- **PDF Generation:** Downloads `FeeInvoice` and `FeeReceipt` PDFs using `Barryvdh\DomPDF`.

### FR-02: Online Payment Processing (`ParentFeePaymentController`)
- **Selection:** Parent selects one or multiple pending invoices.
- **Partial vs Full:** Based on school configuration, allows entering a custom partial amount or enforces paying the full invoice amount.
- **Gateway Handoff:** Invokes `PaymentService::initiate()` from the Payment module to generate a Razorpay Order ID.
- **Callback Handling:** Receives the Razorpay signature, verifies it via `PaymentService::verify()`, and updates the invoice status immediately to reflect the paid amount.

---

## 4. Acceptance Criteria
- **Given** I have a pending invoice of ₹5000, **When** I click 'Pay Now', select Razorpay, and complete the transaction, **Then** I am redirected back to the portal, the invoice balance becomes ₹0, and a downloadable PDF receipt is instantly generated.
