# Business Requirements Document (BRD)
## Module: Payment
### Feature: Webhooks & Reconciliation

---

## 1. Executive Summary
Online payments are asynchronous. A user might close the browser before the success screen loads. To guarantee data integrity, the system relies on Server-to-Server Webhooks (e.g., Razorpay telling our server "Payment Received"). It also requires Reconciliation to match system records against bank statements.

## 2. Business Motive & Rules
- **Idempotency:** A webhook might be sent by Razorpay 3 times due to network delays. The system must process it EXACTLY ONCE to avoid double-crediting a fee invoice.
- **Asynchronous Processing:** Webhooks must return a HTTP 200 immediately to the provider, moving the heavy database processing to a background job.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Inbound Webhooks (`PaymentWebhook`)
- Managed by `WebhookController.php`.
- **Signature Validation:** A middleware (`VerifyWebhookSignature`) strictly validates the cryptographic signature of the incoming request before allowing it into the controller.
- **Storage Strategy:** The controller instantly creates a `PaymentWebhook` record containing:
  - `gateway` (e.g., razorpay)
  - `event_type` (e.g., payment.captured)
  - `idempotency_key` (Extracts Razorpay's entity ID or header to prevent duplicates).
  - `payload` (The raw JSON).
- **Background Dispatch:** Instantly dispatches `ProcessWebhookJob::dispatch($webhook)` and returns a HTTP 200 JSON response `{'status': 'queued'}`.

### FR-02: Payment Reconciliation (`PaymentReconciliation`)
- A system to upload Bank Settlement Reports and match them against internal `Payment` records.
- Identifies mismatches (e.g., System says "Paid", but Bank report shows "Failed/Chargeback").

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Fast & Safe Webhook Receipt
**As a** System Architect,
**I want** webhooks to be stored and queued instantly,
**So that** Razorpay doesn't timeout and retry the webhook, causing unnecessary server load.

**Acceptance Criteria:**
- **Given** Razorpay sends a `payment.captured` POST request, **When** the `WebhookController@razorpay` receives it, **Then** it saves the JSON to the DB, dispatches `ProcessWebhookJob`, and returns a HTTP 200 within 500ms without waiting for the actual invoice logic to process.
