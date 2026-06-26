# Business Requirements Document (BRD)
## Module: Payment
### Feature: Transactions, Offline Payments & Refunds

---

## 1. Executive Summary
Once gateways are configured, the system processes the actual money movement. This involves initiating Online Payments, recording Offline Payments (Cash/Cheque), and managing Refunds for failed or cancelled transactions.

## 2. Business Motive & Rules
- **Omni-Channel Payments:** The system must record money regardless of whether it was paid online via Razorpay or handed in cash at the Front Desk.
- **Refund Control:** Refunds cannot be arbitrary. They must be linked to a specific successful `Payment` record to ensure accounting integrity.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Core Payments (`Payment`)
- Managed by `PaymentController.php`.
- Serves as the central ledger for all inbound transactions.
- Links to the source module (e.g., `payable_type` = 'FeeInvoice', `payable_id` = 104).
- Records the `amount`, `currency`, `gateway_id`, and `transaction_reference`.
- **Status Machine:** Transitions through statuses like `PENDING`, `AUTHORIZED`, `CAPTURED`, `FAILED`.

### FR-02: Offline Payments (`OfflinePaymentRecord`)
- Allows front-desk staff to record manual payments.
- Must capture `payment_mode` (CASH, CHEQUE, DD, NEFT).
- For Cheque/DD, must record `instrument_number`, `bank_name`, and `instrument_date`.
- Bypasses the Payment Gateway logic but links to the core `Payment` table for unified ledger reporting.

### FR-03: Refunds (`PaymentRefund`)
- Managed by `RefundController.php`.
- Initiates a refund request against a `CAPTURED` payment.
- Stores `refund_amount`, `reason`, and the `gateway_refund_id` (provided by Razorpay upon successful refund API call).
- Status tracking: `PENDING_APPROVAL`, `PROCESSING`, `SUCCESS`, `FAILED`.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Recording a Cheque Payment
**As an** Accounts Cashier,
**I want to** record a fee payment made via a physical Cheque,
**So that** the student's fee invoice is marked as paid without using an online gateway.

**Acceptance Criteria:**
- **Given** I am clearing an invoice, **When** I select "Offline Payment" and enter "Cheque", the bank name, and the cheque number, **Then** an `OfflinePaymentRecord` is created and the parent `Payment` ledger is updated to `CAPTURED`.
