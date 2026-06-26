# Finance — Payment Integration Requirements

## 1. Functional Overview
Manages online fee payments using Razorpay as the primary payment gateway, including order creation, checkout interfaces, and server-side signature verification.

---

## 2. Payment Integration Flow

### A. Initiate Payment
- Clicking "Pay Now" on an unpaid or partially paid invoice opens the payment screen.
- Clicking "Proceed to Payment":
  - Sends a POST request to `/fee/invoice/{invoice}/pay/initiate`.
  - The server initiates a Razorpay order, generating a unique order ID and payment ULID.
  - Returns the payment ULID and Razorpay checkout options (API key, amount, currency, order ID, description, prefill name/email/contact).

### B. Razorpay Checkout Modal
- Launches the Razorpay checkout overlay.
- Student chooses their payment method (UPI, Netbanking, Cards, Wallets) and completes the transaction.

### C. Signature Verification & Callback
- On success, the frontend sends the response data back to the server:
  - `payment_ulid`
  - `razorpay_payment_id`
  - `razorpay_order_id`
  - `razorpay_signature`
- The server verifies the signature against the API key.
- If verified, the server:
  - Updates the payment status to success.
  - Updates the invoice record with the paid amount and sets the status to Paid or Partially Paid.
  - Returns the updated balance and status to the frontend.

---

## 3. Database References
- **Models**:
  - `Modules\Payment\Models\Payment`
  - `Modules\StudentFee\Models\FeeInvoice`
- **Tables**:
  - `pay_payments`
  - `fee_invoices`
