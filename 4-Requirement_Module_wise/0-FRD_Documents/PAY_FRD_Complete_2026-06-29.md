# PAY — Payment Module | Complete Analysis Pack
**Date:** 2026-06-29 | **Agent:** pa-business-analyst | **Mode:** Complete Analysis Pack
**Sources:** Live code audit (Modules/Payment/), Tenant migrations (database/migrations/tenant/), V2 Req doc (PAY_Payment_Requirement.md), V1 screen-spec (Payment_V2/01-Payment-Gateway-Configuration.md)
**Module Knowledge:** `AI_Brain/module-knowledge/PAY_Payment.md`

---

## Table of Contents

- [Section 1: FRD — Functional Requirements Document](#section-1-frd)
  - [1. Module Overview](#1-module-overview)
  - [2. User Roles & Access](#2-user-roles--access)
  - [3. Functional Requirements](#3-functional-requirements)
  - [4. Business Rules Register](#4-business-rules-register)
  - [5. Data Requirements](#5-data-requirements)
  - [6. Workflows](#6-workflows)
  - [7. Reporting & Analytics](#7-reporting--analytics)
  - [8. Future Enhancement Log](#8-future-enhancement-log)
  - [9. Non-Functional Requirements](#9-non-functional-requirements)
  - [10. Gap Analysis Readiness Index](#10-gap-analysis-readiness-index)
- [Section 2: RTM — Requirements Traceability Matrix](#section-2-rtm)
- [Section 3: Business Rules Register + Conditions Catalog + Validation Catalog](#section-3-br--conditions--validation)
- [Section 4: Process Flows + FSM Catalog](#section-4-process-flows--fsm)
- [Section 5: Data Dictionary + Cross-Module Dependency Map](#section-5-data-dictionary--dependency-map)
- [Section 6: NFR Catalog + Risk Register](#section-6-nfr--risk)
- [Section 7: Prioritization + Effort Estimation & Sprint Tasks](#section-7-prioritization--effort)
- [Section 8: User Stories + Acceptance Criteria + Reporting & KPI Spec](#section-8-user-stories--reporting-spec)
- [Section 9: Feature Specification (Screen-by-Screen)](#section-9-feature-specification)

---

# Section 1: FRD

## 1. Module Overview

### 1.1 Purpose

The Payment module enables Indian K-12 school tenants to collect fees and other charges from parents and students through digital payment gateways. It provides a pluggable, gateway-agnostic payment layer that any other module in the platform can use simply by implementing the Payable contract. The module handles the full payment lifecycle from initiation through gateway checkout, webhook confirmation, refund processing, and immutable audit trail.

### 1.2 Business Value

- Schools replace manual cash collection with instant, trackable digital payments, eliminating daily counting errors and reducing accountant workload.
- Multiple gateways (Razorpay, Offline, BillDesk, CCAvenue, Paytm, PhonePe) ensure coverage across UPI, cards, net banking, and bank transfers preferred by different parent demographics.
- Polymorphic architecture means every fee-bearing module (School Fees, Library Fines, Hostel Charges, Cafeteria) plugs into the same payment infrastructure without duplicating gateway logic.
- Immutable audit trail satisfies school finance compliance requirements and supports internal audit, board inspections, and government reporting.

### 1.3 Scope

**In Scope:**
- Gateway configuration and lifecycle management per school tenant
- Online payment initiation for any payable entity (polymorphic)
- Razorpay checkout flow (order creation, hosted checkout, HMAC webhook confirmation)
- Offline payment recording (Cash, Cheque, Demand Draft, Bank Transfer, Manual UPI)
- Refund initiation and lifecycle tracking
- Immutable audit trail for all payment events
- Gateway settlement reconciliation
- Webhook log storage and administration
- Multi-gateway support (Razorpay, BillDesk, CCAvenue, Paytm, PhonePe, Offline)

**Out of Scope:**
- Fee invoice creation (managed by Student Fee module)
- Student account balance ledger (Student Fee module)
- Vendor payment processing (Vendor module)
- Payroll disbursement (HrStaff module)
- Accounting voucher creation (triggered by this module's events; owned by Accounting module)
- Library fine calculation (Library module calculates; Payment module collects)

### 1.4 Terminology

| Business Term | Meaning |
|---------------|---------|
| Payment Gateway | An external service (Razorpay, BillDesk, CCAvenue, Paytm, PhonePe) that processes digital payments on behalf of the school |
| Gateway Configuration | The school's API credentials and settings for a specific payment gateway, stored encrypted |
| Payment Order | A Razorpay construct created before the parent pays; links the payment request to the gateway session |
| Payment Record | The platform's record of a single payment attempt, tracking status from initiation through final outcome |
| Payable | Any school entity that can be paid for — a fee invoice, a library fine, a hostel charge, etc. |
| Refund | Return of all or part of a successful payment amount to the payer |
| Webhook | An HTTP callback sent by the gateway to the school's server when a payment event occurs (captured, failed, refund processed) |
| HMAC Verification | Cryptographic signature check using a shared secret to confirm the webhook came from the real gateway |
| Offline Payment | A payment collected in person (cash, cheque, demand draft) and manually recorded by school staff |
| Reconciliation | Matching the school's internal payment records against the gateway's settlement report to identify discrepancies |
| Audit Log | An append-only, immutable record of every event in a payment's lifecycle |
| Paise | 1/100th of an Indian Rupee; Razorpay API receives amounts in paise |

---

## 2. User Roles & Access

### 2.1 Actors

| Actor | Description |
|-------|-------------|
| School Finance Administrator | Configures payment gateways, monitors all transactions, initiates refunds, manages reconciliation |
| Bursar / Accountant | Views transaction history, records offline payments, tracks refund status, exports reports |
| School Admin (Principal) | Views payment dashboard for financial oversight; no configuration access |
| Parent | Initiates online payment for their child's fee invoices and other charges via parent/student portal |
| Student | Views own payment history and receipts through student portal |
| Gateway Server (Razorpay / BillDesk etc.) | External system; sends HMAC-signed webhook callbacks to the school's webhook endpoint |
| System | Automated processing: queues webhook jobs, fires post-payment events, writes audit log entries |

### 2.2 Role-Feature Matrix

| Feature | Finance Admin | Bursar/Accountant | Principal | Parent | Student | System |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Configure Payment Gateways | Create/Edit/Delete | View only | View only | — | — | — |
| Initiate Online Payment | Yes | Yes | — | Yes (own) | Yes (own) | — |
| Record Offline Payment | Yes | Yes | — | — | — | — |
| View Payment History | All records | All records | Dashboard only | Own records | Own records | — |
| Initiate Refund | Yes | Yes | — | — | — | — |
| View Webhook Logs | Yes | — | — | — | — | — |
| Re-process Failed Webhooks | Yes | — | — | — | — | — |
| View Reconciliation | Yes | Yes | — | — | — | — |
| Create Reconciliation Record | Yes | Yes | — | — | — | — |
| Download Payment Receipt | Yes | Yes | — | Own | Own | — |
| Write Audit Log | — | — | — | — | — | Always |
| Process Webhooks (async) | — | — | — | — | — | Always |

---

## 3. Functional Requirements

### REQ-PAY-001: Payment Gateway Configuration Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION] [DATA_ENTRY]
**Code Status:** Implemented (PaymentGatewayController + 5 gateway CRUD views)

**Description:**
The Finance Administrator shall configure one or more payment gateways for the school. Each gateway stores its display name, machine code, driver class reference, encrypted API credentials, operational mode (live or test), supported module scope, and priority order. Gateways may be deactivated rather than deleted to preserve transaction history referential integrity. Soft-deleted gateways move to a Trash view and may be restored or permanently deleted.

**Actors:** Finance Admin initiates all configuration actions; System logs each action to the activity trail.

**Business Rules:** BR-PAY-001 (code uniqueness), BR-PAY-003 (credential encryption), BR-PAY-010 (driver contract), BR-PAY-002 (only active gateways offered for payment)

**Acceptance Criteria:**
1. When a Finance Admin saves a gateway with valid credentials, the credentials field in the database is an encrypted string, not readable plaintext JSON.
2. When a gateway's Active status is turned off, it no longer appears in the payment method selection for any new payment attempt.
3. When an Admin views the Edit form for a gateway, the credentials fields do not display raw credential values.
4. When a gateway is soft-deleted, all existing payment records that reference it are preserved with full history.
5. When a gateway is restored from Trash, it returns to Active status and becomes available for new payments.
6. When a gateway is permanently deleted, the system blocks the action if any payment records reference it.

**Integration:** Activity log written on every create, update, toggle, trash, restore, and force-delete action.

**Enhancement Notes:** ENH-PAY-002 (test connection button), ENH-PAY-005 (gateway record caching), ENH-PAY-009 (config-driven driver list)

---

### REQ-PAY-002: Online Payment Initiation
**Priority:** Core (P0) | **Tags:** [WORKFLOW] [DATA_ENTRY] [INTEGRATION]
**Code Status:** Implemented (PaymentService.initiate(), PaymentController.initiate()) — route mapping gap (P0)

**Description:**
Any authenticated user with appropriate permission shall initiate a payment for any platform entity that supports the Payable contract (Fee Invoice, Library Fine, Hostel Charge, etc.). The system creates a Payment Record, calls the selected gateway to generate an order or session, and returns gateway-specific checkout data for the client-side checkout flow. The entire sequence — from Payment Record creation through gateway order creation to status update — runs within a single database transaction to prevent orphan records.

**Actors:** Parent or Student initiates payment from portal; Finance Admin or Accountant may initiate on behalf of a parent; System processes the result.

**Business Rules:** BR-PAY-004 (amount in paise conversion for Razorpay), BR-PAY-005 (payment status FSM), BR-PAY-011 (auto-capture), BR-PAY-012 (no card data)

**Acceptance Criteria:**
1. When a valid payment request is submitted with an active gateway, a Payment Record is created with status "Pending", the gateway order is created, and checkout data is returned.
2. When the gateway API call fails, no Payment Record persists in the database (transaction rollback).
3. When a gateway is inactive, the system returns a validation error and blocks initiation.
4. When the payable entity does not implement the Payable contract, the system returns a validation error.
5. When the same payable and amount has an in-flight Payment Record less than 30 minutes old, the system reuses the existing order rather than creating a duplicate.

**Integration:** Reads gateway credentials from Payment Gateway Configuration; writes Payment Record to ptm_payments; fires PaymentInitiated event.

**Enhancement Notes:** ENH-PAY-007 (module licensing enforcement), ENH-PAY-006 (PaymentPolicy for authorization)

---

### REQ-PAY-003: Razorpay Checkout Flow
**Priority:** Core (P0) | **Tags:** [INTEGRATION] [WORKFLOW]
**Code Status:** Implemented (RazorpayGateway, process-payment.blade.php)

**Description:**
When a payment is initiated via Razorpay, the system renders the Razorpay hosted checkout page with the gateway order ID, amount, currency, school name, and payer prefill details. The parent completes card, UPI, or net banking payment on Razorpay's hosted interface. Razorpay's JavaScript SDK handles card data directly — the school server never receives card data.

**Actors:** Parent interacts with Razorpay checkout in browser; System provides checkout parameters.

**Business Rules:** BR-PAY-011 (auto-capture), BR-PAY-012 (no card data), BR-PAY-004 (paise conversion)

**Acceptance Criteria:**
1. When checkout is rendered, the Razorpay key_id (public key only, never the secret) is embedded.
2. When the parent completes payment, the browser submits razorpay_payment_id, razorpay_order_id, and razorpay_signature to the callback endpoint.
3. When the parent cancels in the Razorpay modal, the system records the payment as "Cancelled" and returns the parent to the previous screen with an informative message.
4. When card details are entered, they are transmitted directly to Razorpay — the school server receives only the payment ID after completion.

**Integration:** Calls RazorpayGateway.initiate() which calls Razorpay Orders API; renders payment::razorpay.process-payment view.

---

### REQ-PAY-004: Gateway Callback Verification
**Priority:** Core (P0) | **Tags:** [WORKFLOW, INTEGRATION]
**Code Status:** Implemented (PaymentController.callback() + RazorpayGateway.verify()) — route mapping gap

**Description:**
After the parent completes the Razorpay checkout, Razorpay's JavaScript redirects to the school's callback URL with three fields: razorpay_order_id, razorpay_payment_id, and razorpay_signature. The system verifies the HMAC-SHA256 signature (computed from order_id + "|" + payment_id using the gateway secret) before updating the Payment Record status. A verified callback marks the payment as "Success"; a failed verification marks it "Failed". Note: the authoritative payment confirmation comes from the server-side webhook (REQ-PAY-005), not the client callback, since client payloads can be manipulated.

**Actors:** Razorpay JavaScript SDK submits callback; System verifies signature and updates status.

**Business Rules:** BR-PAY-005 (payment status FSM), BR-PAY-007 (HMAC verification)

**Acceptance Criteria:**
1. When a callback arrives with a valid HMAC signature, the Payment Record status is updated to "Success" and paid_at is set.
2. When a callback arrives with an invalid signature, the Payment Record status is updated to "Failed" and no financial record is marked as paid.
3. When the callback endpoint is not reachable (network error on parent's side), the server-side webhook (REQ-PAY-005) provides the authoritative confirmation within Razorpay's retry window.

**Integration:** Uses RazorpayGateway.verify(); calls PaymentService.markSuccess() or markFailed(); fires PaymentSucceeded or PaymentFailed event.

---

### REQ-PAY-005: Webhook Processing
**Priority:** Core (P0) | **Tags:** [INTEGRATION] [WORKFLOW] [SCHEDULED]
**Code Status:** Implemented (WebhookController + ProcessWebhookJob + VerifyWebhookSignature middleware) — correctly outside auth

**Description:**
The payment gateway server sends HMAC-signed HTTP POST callbacks to a dedicated webhook endpoint when payment events occur (payment captured, payment failed, refund processed). The webhook endpoint accepts requests without user authentication — the only security mechanism is HMAC-SHA256 signature verification against the raw request body. Upon receiving a webhook, the system immediately stores the raw payload to the Webhook Log, dispatches an asynchronous processing job, and returns HTTP 200. The processing job (running in background queue) handles the gateway-specific event logic with up to 3 retry attempts on failure.

**Actors:** Gateway Server sends webhooks; System stores and processes them asynchronously.

**Business Rules:** BR-PAY-007 (HMAC verification), BR-PAY-008 (idempotency), BR-PAY-014 (immediate 200 response), BR-PAY-005 (payment status FSM)

**Acceptance Criteria:**
1. When a valid HMAC-signed webhook for payment.captured arrives, the Payment Record status is updated to "Success" within the asynchronous job, and the downstream PaymentSucceeded event fires.
2. When the same payment.captured webhook arrives twice for an already-successful payment, the second delivery is acknowledged with HTTP 200 and silently ignored (no duplicate processing).
3. When a webhook with an invalid signature arrives, the system returns HTTP 401, the Webhook Log is NOT updated (payload rejected before storage), and no payment status changes.
4. When the webhook processing job fails, it retries up to 3 times with 30-second backoff before recording a permanent failure in the Webhook Log error_message field.
5. The webhook endpoint is reachable by the gateway server without any login session or bearer token — only HMAC signature is checked.
6. When the gateway code in the webhook URL is not configured or inactive, the middleware returns HTTP 400 with a generic error message (no internal details exposed).

**Integration:** Requires webhook URL registered in Razorpay dashboard; connects to ptm_payment_webhooks table; dispatches ProcessWebhookJob to queue; fires PaymentSucceeded/PaymentFailed downstream events.

---

### REQ-PAY-006: Offline Payment Recording
**Priority:** Standard (P1) | **Tags:** [DATA_ENTRY] [WORKFLOW]
**Code Status:** Model implemented (OfflinePaymentRecord), OfflineGateway implemented — write path missing (P1 gap)

**Description:**
School staff (Finance Admin or Bursar) shall record payments collected in person through cash, cheque, demand draft, bank transfer, or manually confirmed UPI. An offline payment creates a Payment Record (like an online payment) linked to the same payable entity, and additionally creates an Offline Payment Record with method-specific details such as cheque number, bank name, or reference number. For cheques, staff can later update the clearance status (Cleared or Bounced). A bounced cheque records the bounce date and triggers a notification to the relevant module.

**Actors:** Finance Admin or Bursar records the offline payment; System creates the linked records.

**Business Rules:** BR-PAY-005 (payment FSM applies to offline too), BR-PAY-013 (immutable audit), BR-PAY-015 (offline refund manual)

**Acceptance Criteria:**
1. When a Bursar records a cash payment for a fee invoice, a Payment Record with status "Success" and an Offline Payment Record with method "Cash" are created together.
2. When a cheque payment is recorded, the system creates the Offline Payment Record with clearance_status "Pending".
3. When staff updates a cheque status to "Bounced", the bounce date is recorded and the related fee invoice status is reverted to unpaid.
4. When a demand draft is recorded, a unique receipt number is generated for the offline record.
5. When an offline payment is viewed, both the Payment Record and the Offline Payment Record details are displayed together.

**Integration:** Reads from the payable entity (fee invoice, etc.); writes to ptm_payments and ptm_offline_payment_records; fires PaymentSucceeded for downstream fee marking.

---

### REQ-PAY-007: Refund Management
**Priority:** Standard (P1) | **Tags:** [WORKFLOW] [DATA_ENTRY]
**Code Status:** Implemented (RefundController, RefundService) — no routes (P0 gap)

**Description:**
Finance Admin or Bursar shall initiate full or partial refunds for payments in "Success" status. The system validates that the refund amount does not exceed the original payment amount minus any prior successful refunds. For online payments, the system calls the gateway's refund API and tracks the gateway-assigned refund ID. For offline payments, the refund is recorded manually with approval notes. When the total refunded amount equals the original payment amount, the Payment Record status changes to "Refunded".

**Actors:** Finance Admin or Bursar initiates refunds; Gateway processes online refunds; System tracks status.

**Business Rules:** BR-PAY-009 (refund amount limit), BR-PAY-005 (payment FSM — refunded state), BR-PAY-006 (refund FSM), BR-PAY-015 (offline refund manual)

**Acceptance Criteria:**
1. When a Finance Admin initiates a refund for a "Success" payment, a Refund Record with status "Pending" is created and the gateway refund API is called.
2. When the gateway returns a refund ID, the Refund Record is updated to status "Processing" with the gateway refund ID stored.
3. When the gateway webhook confirms the refund is processed, the Refund Record status updates to "Success" and refunded_at is set.
4. When the total refunded amount across all refunds equals the original payment amount, the Payment Record status changes to "Refunded".
5. When a staff member attempts a refund greater than the remaining refundable amount, the system blocks the action with a clear error message.
6. When a payment is in "Failed" or "Cancelled" status, the Refund option is not available.
7. When a partial refund is completed (say ₹200 of ₹500), the Payment Record status remains "Success" (not "Refunded").

**Integration:** Calls gateway refund API via GatewayManager; writes to ptm_payment_refunds; updates ptm_payments status on full refund; fires RefundInitiated, RefundSucceeded, RefundFailed events.

**Enhancement Notes:** ENH-PAY-004 (IP allowlisting also applies to refund confirmation webhooks)

---

### REQ-PAY-008: Payment History & Transaction Dashboard
**Priority:** Standard (P1) | **Tags:** [REPORT] [DASHBOARD]
**Code Status:** Partial — dashboard view exists (payment::index); payment-history partial exists; full detail view and dedicated history page missing (P1 gap)

**Description:**
Finance Admin, Bursar, and Principal shall view a paginated transaction history with summary statistics. The dashboard shows summary cards for total collected today, this month, all time, plus counts of pending and failed payments. The transaction list is filterable by gateway, payment status, and date range. Each transaction links to a detail view showing the payable entity, gateway response, audit log timeline, and associated refunds. Parents and students see only their own records through the portal.

**Actors:** Finance Admin / Bursar / Principal view all records; Parents and Students view own records only.

**Business Rules:** BR-PAY-013 (audit log view must be read-only)

**Acceptance Criteria:**
1. When Finance Admin views the payment dashboard, the four summary cards display accurate counts/totals based on current data.
2. When a date range filter is applied, only payments with paid_at or created_at within the range appear.
3. When a status filter is applied, only records with the selected status appear.
4. When a specific payment record is opened, the audit log timeline shows all status changes in chronological order.
5. When a Parent views their payment history, only payments linked to their child's payable entities appear.
6. When a payment history list is exported, the CSV file contains all visible rows in their current filtered state.

**Integration:** Reads from ptm_payments joined with payable entities; reads from ptm_payment_audit_logs for timeline; cross-references ptm_payment_gateways for gateway name display.

---

### REQ-PAY-009: Immutable Audit Trail
**Priority:** Core (P0) | **Tags:** [WORKFLOW]
**Code Status:** Implemented (PaymentAuditLog model + AuditService — append-only, no SoftDeletes)

**Description:**
Every payment lifecycle event shall be recorded to an immutable, append-only audit log. The log captures the event name, from/to status, actor type (user, system, gateway, webhook), actor identity, IP address, user agent, and a contextual payload. The audit log is never edited or deleted. It satisfies school finance compliance requirements and enables forensic investigation of disputed payments.

**Actors:** System automatically writes all log entries; Finance Admin reads the log for investigation.

**Business Rules:** BR-PAY-013 (immutable log), BR-PAY-005 (every status change is logged)

**Acceptance Criteria:**
1. When a payment status changes for any reason, a new audit log entry is written with the from_status, to_status, actor type, and timestamp.
2. When viewing a payment's audit timeline, entries are displayed in chronological order from oldest to newest.
3. When a staff user attempts to edit or delete an audit log entry, the system prevents the action (no edit/delete routes exist for audit logs).
4. When a webhook triggers a status change, the actor_type in the audit log is recorded as "gateway" or "webhook".
5. When an administrative user initiates a status change, the actor_type is "user" with actor_id set to the user's ID.

**Integration:** AuditService is called by PaymentService and RefundService on every status change; reads sys_users for actor_id resolution.

---

### REQ-PAY-010: Gateway Settlement Reconciliation
**Priority:** Standard (P1) | **Tags:** [REPORT] [DATA_ENTRY]
**Code Status:** Model implemented (PaymentReconciliation + computeDiscrepancy()) — no controller or routes

**Description:**
Finance Admin and Bursar shall reconcile the school's internal payment records against the gateway's daily settlement report. For each gateway and date, a Reconciliation Record stores the expected amount (sum of successful payments per school records) and the settled amount (as reported by the gateway's bank statement). The system computes the discrepancy. Records move through four statuses: Pending (awaiting comparison), Matched (amounts agree), Discrepant (difference exists), and Resolved (Finance Admin has acknowledged and closed the discrepancy). Only one reconciliation record exists per gateway per date.

**Actors:** Finance Admin or Bursar creates and resolves reconciliation records.

**Business Rules:** BR-PAY-016 (one reconciliation per gateway per date)

**Acceptance Criteria:**
1. When a reconciliation record is saved with expected_amount and settled_amount, the discrepancy is automatically computed as the difference.
2. When expected_amount equals settled_amount, status is set to "Matched".
3. When a discrepancy exists, status is "Discrepant" and the record requires Finance Admin resolution with notes.
4. When a Finance Admin marks a discrepant record as "Resolved", resolved_by and the resolution notes are saved.
5. When a second reconciliation record is attempted for the same gateway and date, the system rejects it with a validation error.

**Integration:** Reads from ptm_payments (expected_amount calculation); reads from ptm_payment_gateways; writes to ptm_payment_reconciliations.

---

### REQ-PAY-011: Payment Receipt Generation
**Priority:** Enhanced (P2) | **Tags:** [REPORT]
**Code Status:** Not implemented (ENH-PAY-001)

**Description:**
After a payment is confirmed as "Success", the system shall generate a PDF receipt. The receipt includes the school name, school logo, receipt number, payment date, student name, description of what was paid, amount, payment gateway used, and gateway transaction ID. The receipt carries a "PAID" watermark. Parents can download their receipt from the payment history. Finance Admin can download any receipt. If the PDF has not been generated yet when a download is requested, the system generates it on the fly.

**Actors:** System auto-generates receipt on PaymentSucceeded event (queued); Parent and Finance Admin download.

**Acceptance Criteria:**
1. When a payment is confirmed "Success", a PDF receipt is generated and associated with the Payment Record.
2. When a Parent opens their payment history and clicks "Download Receipt" on a "Success" payment, the PDF downloads correctly.
3. When a Finance Admin requests a receipt that was not previously generated, it is generated on the fly.
4. When a payment is in "Failed" status, no receipt download option is available.

**Integration:** Listens to PaymentSucceeded event; uses DomPDF (same pattern as HPC module); stores to sys_media.

---

### REQ-PAY-012: Webhook Log Administration
**Priority:** Enhanced (P2) | **Tags:** [REPORT] [CONFIGURATION]
**Code Status:** Not implemented — model and job exist; no UI

**Description:**
Finance Admin shall view all incoming webhook records from payment gateways. The log shows gateway, event type, processing status, processing time, and error message for failed entries. Admin can expand any record to view the raw JSON payload. For webhook records with processed=false (failed or unprocessed), Admin can trigger a manual re-processing attempt. This capability is critical for operational support when a webhook job fails exhaustively.

**Actors:** Finance Admin views and re-processes webhook logs.

**Acceptance Criteria:**
1. When Admin opens the Webhook Log page, all received webhooks are listed with gateway, event type, status badge, and date.
2. When Admin filters by "unprocessed" status, only failed/pending entries are shown.
3. When Admin clicks "View Payload", the raw JSON webhook payload is displayed in a readable modal.
4. When Admin clicks "Re-process" on a failed webhook, the system dispatches a fresh ProcessWebhookJob for that record.
5. When a webhook has been successfully processed, the re-process button is disabled.

**Integration:** Reads from ptm_payment_webhooks; dispatches ProcessWebhookJob.

---

### REQ-PAY-013: Multi-Gateway UI Exposure
**Priority:** Standard (P1) | **Tags:** [CONFIGURATION] [INTEGRATION]
**Code Status:** 6 gateway drivers implemented — only Razorpay exposed in UI (P1 gap)

**Description:**
The Gateway Configuration form shall offer all implemented gateway drivers as selectable options, not just Razorpay. Finance Admin shall be able to configure BillDesk, CCAvenue, Paytm, and PhonePe gateways in addition to Razorpay and Offline methods. The available driver list is sourced from the platform configuration file, not hardcoded in the controller.

**Actors:** Finance Admin selects from all available gateway drivers.

**Acceptance Criteria:**
1. When Admin opens the Add Gateway form, the Driver dropdown shows all 6 implemented gateway options.
2. When a BillDesk gateway is configured and active, it can be selected during payment initiation.
3. When a non-Razorpay gateway is selected, the system routes the payment through the correct driver implementation.
4. When a new gateway driver class is added to the platform configuration, it automatically appears in the dropdown without code changes.

**Integration:** config/payment.php should list all gateway FQCNs; PaymentGatewayController reads from config.

---

## 4. Business Rules Register

| ID | Rule | Type | Trigger | Enforcement Point |
|----|------|------|---------|------------------|
| BR-PAY-001 | Each gateway code (e.g., "razorpay", "billdesk") must be unique within the school's tenant database — no two gateways may share the same code | Validation | Gateway create / update | Database unique constraint on ptm_payment_gateways.code; FormRequest validation |
| BR-PAY-002 | Only gateways with Active status are available for payment initiation — inactive gateways are hidden from the checkout method selection | Workflow | Payment initiation | GatewayManager.resolve() checks is_active=true; PaymentGatewayRequest validates against active codes only |
| BR-PAY-003 | Gateway API credentials (key_id, key_secret, webhook_secret) must be stored encrypted at rest — they must never appear in database as plaintext, in API responses, in logs, or in error messages | Permission | Gateway save | PaymentGateway model encrypted:array cast; column type TEXT |
| BR-PAY-004 | Amounts are stored in Indian Rupees as decimal values (e.g., ₹500.00). Razorpay API requires amounts in paise (₹500.00 = 50,000 paise). The conversion amount × 100 happens once, in the gateway driver, and never in the service layer | Calculation | Payment initiation via Razorpay | RazorpayGateway.initiate(): (int)($data->amount * 100) |
| BR-PAY-005 | A Payment Record follows a one-directional status lifecycle: Initiated → Pending → Success, Failed, or Cancelled; Success → Refunded (full refund only). No backward transitions are allowed | Workflow | Every status change | PaymentService.markSuccess/markFailed/cancel(); no rollback paths |
| BR-PAY-006 | A Refund Record follows a one-directional status lifecycle: Pending → Processing → Success or Failed. No backward transitions | Workflow | Refund lifecycle | RefundService lifecycle methods |
| BR-PAY-007 | Every inbound webhook must be HMAC-SHA256 verified against the raw request body before any processing or payload parsing occurs — a missing or mismatched signature results in HTTP 401 and no payload is stored | Permission | Webhook receipt | VerifyWebhookSignature middleware; hash_hmac + hash_equals |
| BR-PAY-008 | If a PaymentSucceeded event has already been processed for a given payment (status = "Success"), any subsequent webhook for the same payment is acknowledged with HTTP 200 and silently ignored — no duplicate fee marking, notification, or voucher creation occurs | Concurrency | Duplicate webhook arrival | ProcessWebhookJob checks payment.status before processing; idempotency_key unique constraint on ptm_payment_webhooks |
| BR-PAY-009 | The total of all refund amounts for a single payment must not exceed the original payment amount. Formula: Maximum refundable = original_amount − sum(successful_refunds). Partial refunds are permitted | Calculation / Validation | Refund initiation | RefundService.initiate(): amount > payment.amount check; should also sum prior successful refunds (current gap — amount check is against payment.amount only, not net of prior refunds) |
| BR-PAY-010 | Every gateway driver class must implement PaymentGatewayInterface (initiate, verify, handleWebhook, refund, getWebhookSecret, getSupportedEvents). A driver class not implementing the interface cannot be registered | Validation | Gateway registration | GatewayManager.resolve() instantiates driver; PHP interface enforcement at compile time |
| BR-PAY-011 | Razorpay orders must be created with payment_capture = 1 (automatic capture). Manual capture flow is not supported — the gateway captures payment immediately on customer completion | Workflow | Razorpay order creation | RazorpayGateway.initiate(): 'payment_capture' => 1 |
| BR-PAY-012 | Raw payment card data must never be transmitted to, or stored by, the school's server. Razorpay's hosted checkout handles card data entirely within Razorpay's PCI-DSS environment — the school receives only payment and order IDs | Permission | Any payment flow | Architecture: only checkout.js on client side; no card fields in school forms |
| BR-PAY-013 | The Payment Audit Log is immutable — entries are append-only, no updates, no deletes, and no soft-deletes. Every status change in a payment's lifecycle must produce an audit entry | Permission | Audit log write | PaymentAuditLog model: no SoftDeletes, no update routes; AuditService.log() called on every lifecycle transition |
| BR-PAY-014 | The webhook endpoint must return HTTP 200 immediately upon storing the payload — before the processing job completes. Razorpay retries on non-200 responses with exponential backoff. Slow synchronous processing causes retry storms | Workflow | Webhook receipt | WebhookController stores then dispatches ProcessWebhookJob; returns 200 immediately |
| BR-PAY-015 | Offline payment refunds (cash/cheque/DD) are processed manually outside the system — no gateway API is called. The system records the refund as a Refund Record with status "Success" immediately and notes the manual reference | Workflow | Offline refund initiation | OfflineGateway.refund() returns synthetic refund_id with status='success' immediately |
| BR-PAY-016 | Only one reconciliation record may exist per gateway per date — duplicate records are rejected | Validation | Reconciliation record create | Unique constraint on ptm_payment_reconciliations(gateway_id, date) |

---

## 5. Data Requirements

### 5.1 Payment Gateway Configuration
**Privacy:** Confidential (credentials encrypted; configuration details internal to school Finance staff)

| Business Field | Meaning | Type | Required | Allowed Values |
|----------------|---------|------|----------|---------------|
| Gateway Name | Display label for the gateway | Text (100 chars) | Yes | Free text, e.g., "Razorpay Production" |
| Gateway Code | Unique machine identifier | Text (50 chars) | Yes | Unique per school, e.g., "razorpay" |
| Gateway Type | Whether the gateway processes online or offline payments | Selection | Yes | Online, Offline |
| Driver | Technology class that implements the gateway protocol | Selection | Yes | Razorpay, BillDesk, CCAvenue, Paytm, PhonePe, Offline |
| API Credentials | Key ID, Key Secret, Webhook Secret — stored encrypted | Encrypted JSON | Yes | Set by Finance Admin; never displayed after save |
| Additional Config | Operational mode and other gateway-specific settings | JSON | No | Mode: Live or Test |
| Supported Modules | Scope of which modules may use this gateway | Multi-select | No | Null = all modules |
| Priority Order | Which gateway is offered first when multiple are active | Number (1–100) | Yes | Integer |
| Active | Whether gateway is offered for new payments | Toggle | Yes | Active / Inactive |
| Test Mode | Whether gateway is in sandbox/test mode | Toggle | Yes | On / Off |

### 5.2 Payment Record
**Privacy:** Confidential (financial data; linked to student identity via payable relationship)

| Business Field | Meaning | Type | Required | Allowed Values |
|----------------|---------|------|----------|---------------|
| Payment Reference (ULID) | Public-facing unique payment identifier | ULID | System | Auto-generated |
| Payment For (Payable) | What entity is being paid | Polymorphic reference | Yes | Fee Invoice, Library Fine, Hostel Charge, etc. |
| Gateway Used | Which gateway processed this payment | Reference | Yes | Active gateway |
| Amount | Payment amount in Indian Rupees | Decimal (12,2) | Yes | > 0, ≤ ₹500,000 |
| Currency | Payment currency | Code | Yes | INR only |
| Status | Current lifecycle stage of the payment | Selection | System | Initiated, Pending, Success, Failed, Cancelled, Refunded |
| Gateway Order ID | Order reference from the gateway | Text | System (after initiation) | Gateway-assigned |
| Gateway Payment ID | Transaction ID from gateway after capture | Text | System (after capture) | Gateway-assigned |
| Paid At | Date and time when payment was confirmed as successful | Datetime | System | Set on Status=Success |
| Failure Reason | Human-readable explanation when status=Failed | Text | No | Free text |
| Additional Info | Module-specific contextual data | JSON | No | Free-form |

### 5.3 Payment Refund
**Privacy:** Confidential

| Business Field | Meaning | Type | Required | Allowed Values |
|----------------|---------|------|----------|---------------|
| Refund Reference (ULID) | Public-facing unique refund identifier | ULID | System | Auto-generated |
| Original Payment | The payment being refunded | Reference | Yes | Must be in "Success" status |
| Refund Amount | Amount to be returned to payer | Decimal (12,2) | Yes | > 0 and ≤ remaining refundable |
| Reason | Why the refund is being issued | Text | Yes | Max 500 chars |
| Status | Refund lifecycle stage | Selection | System | Pending, Processing, Success, Failed |
| Gateway Refund ID | Refund transaction ID from gateway | Text | System | Gateway-assigned |
| Refunded At | Date and time refund was confirmed complete | Datetime | System | Set on Status=Success |
| Initiated By | Staff member who initiated the refund | Reference | System | Authenticated user |

### 5.4 Offline Payment Record
**Privacy:** Internal (method and reference details; no card data)

| Business Field | Meaning | Type | Required | Allowed Values |
|----------------|---------|------|----------|---------------|
| Payment | The parent Payment Record this belongs to | Reference | Yes | ptm_payments |
| Collection Method | How the payment was received | Selection | Yes | Cash, Cheque, Bank Transfer, Demand Draft, Manual UPI |
| Reference Number | Cheque number, UTR, DD number, or bank reference | Text | Conditional | Required for Cheque/DD/Bank Transfer |
| Bank Name | Issuing bank name | Text | Conditional | Required for Cheque/DD/Bank Transfer |
| Cheque Date | Date on the cheque | Date | Conditional | Required when method=Cheque |
| Clearance Status | Whether a cheque has cleared or bounced | Selection | Conditional | Pending, Cleared, Bounced (Cheque/DD only) |
| Collected By | Staff member who received the payment | Reference | Yes | Authenticated user |
| Collected At | Date and time of collection | Datetime | Yes | Cannot be future date |
| Receipt Number | System-generated receipt reference | Text | System | Unique |
| Notes | Additional remarks | Text | No | Free text |

### 5.5 Payment Audit Log (Immutable)
**Privacy:** Internal (operational audit data; not shared with parents)

| Business Field | Meaning | Type | PII? |
|----------------|---------|------|------|
| Payment | Which payment this log entry tracks | Reference | No |
| Event | What happened (e.g., "Payment Initiated", "Status Changed", "Webhook Received") | Text | No |
| Previous Status | Status before the event | Text | No |
| New Status | Status after the event | Text | No |
| Actor Type | Who triggered the event (School User, System, Webhook, Gateway) | Selection | No |
| Actor | Which specific user or system component | Reference (nullable) | No |
| Context Data | Gateway payload or contextual details | JSON | Conditional |
| IP Address | Network address of the actor | Text | Yes (Internal) |
| Recorded At | When the log entry was created | Datetime | No |

### 5.6 Reconciliation Record
**Privacy:** Internal (financial reconciliation data)

| Business Field | Meaning | Type | Required |
|----------------|---------|------|----------|
| Gateway | Which gateway's settlements are being reconciled | Reference | Yes |
| Date | Reconciliation date (one per gateway per day) | Date | Yes |
| Expected Amount | Sum of successful payments per school records | Decimal | Yes |
| Settled Amount | Amount confirmed settled per gateway statement | Decimal | Yes |
| Discrepancy | Difference: Expected minus Settled (auto-computed) | Decimal | System |
| Status | Reconciliation state | Selection | System | Pending, Matched, Discrepant, Resolved |
| Bank Statement | Gateway's settlement JSON for reference | JSON | No |
| Resolved By | Staff member who closed a discrepancy | Reference | Conditional |
| Resolution Notes | How the discrepancy was explained/resolved | Text | Conditional |

---

## 6. Workflows

### Workflow 1: Online Payment — Razorpay
**Trigger:** Parent or staff clicks "Pay Now" for a fee invoice or other payable entity
**End States:** Success (payment captured), Failed (gateway rejection), Cancelled (parent abandonment)
**Actors:** Parent | System | Razorpay

**Steps:**
1. Parent selects payment gateway and clicks "Pay Now" on the Fee Invoice page
2. System validates the request: gateway is active, payable entity exists and is in an unpaid state, amount > 0
3. System begins a database transaction: creates a Payment Record with status "Initiated"
4. System calls Razorpay Orders API with amount (in paise), currency, and receipt reference
5. Razorpay returns a gateway order ID; System updates Payment Record status to "Pending" and stores the order ID
6. System renders the Razorpay hosted checkout page with key_id, order_id, amount, and parent prefill details
7. Parent completes card/UPI/net banking payment on Razorpay's hosted checkout
8. Razorpay sends payment.captured webhook to the school's webhook endpoint (server-to-server)
9. System verifies HMAC signature; stores webhook payload; dispatches async processing job
10. Processing job updates Payment Record status to "Success", sets paid_at, and fires PaymentSucceeded event
11. Downstream listeners: fee invoice marked as paid, notification sent to parent, accounting voucher created (planned)

**Exception — Invalid Signature:**
At step 9, if HMAC verification fails: webhook is rejected with HTTP 401, no payload stored, no status change.

**Exception — Gateway API Failure (Step 4):**
Database transaction is rolled back; no Payment Record persists; user sees error message, can retry.

**Exception — Parent Abandonment:**
Parent closes the Razorpay modal; System records status as "Cancelled" via callback with cancellation signal.

**Exception — Webhook Job Failure:**
Job retries up to 3 times with 30-second backoff. If all retries fail, webhook record shows error_message; Finance Admin can trigger manual re-processing from Webhook Log UI.

**Notifications:**
| Step | Recipient | Channel | Message |
|------|-----------|---------|---------|
| 10 — PaymentSucceeded | Parent / Guardian | SMS + Email | "Payment of ₹[amount] for [student name] confirmed. Transaction ID: [gateway_payment_id]" |
| 10 — PaymentSucceeded | School Finance Staff | Email (summary) | Daily digest of payments received |

---

### Workflow 2: Offline Payment Recording
**Trigger:** Finance Admin or Bursar records a physical payment received from parent
**End States:** Payment Record created as "Success" with Offline Record attached
**Actors:** Bursar | System

**Steps:**
1. Bursar opens the "Record Offline Payment" form for the selected payable entity
2. Bursar selects collection method (Cash, Cheque, DD, Bank Transfer, Manual UPI)
3. Bursar enters method-specific details (cheque number, bank, date; or UTR reference for bank transfer)
4. Bursar enters collection date and confirms amount
5. System creates a Payment Record with status "Success" (offline = immediately confirmed)
6. System creates an Offline Payment Record linked to the Payment Record
7. System generates a receipt number and fires PaymentSucceeded event
8. System writes audit log entry with actor_type="user" and the Bursar's identity

**Exception — Cheque Bounce (later event):**
Bursar opens the Offline Payment Record and sets clearance_status to "Bounced". System records bounce date. The system should revert the linked fee invoice to unpaid status and notify the relevant module (planned, currently a gap).

---

### Workflow 3: Refund Processing
**Trigger:** Finance Admin or Bursar initiates a refund from the payment detail view
**End States:** Refund Record in "Success" or "Failed" status
**Actors:** Finance Admin | System | Gateway

**Steps:**
1. Finance Admin opens a payment detail in "Success" status and clicks "Initiate Refund"
2. Admin enters refund amount (≤ remaining refundable balance) and reason
3. System validates: payment is "Success", amount ≤ maximum refundable, reason is provided
4. System creates a Refund Record with status "Pending" within a database transaction
5. System calls the gateway's refund API with amount in paise
6. Gateway returns a refund ID; System updates Refund Record to status "Processing" with gateway refund ID
7. Gateway sends refund.processed webhook; System updates Refund Record to "Success" and sets refunded_at
8. If total refunded equals original amount, Payment Record status changes to "Refunded"
9. System fires RefundSucceeded event; downstream notification sent to parent

**Exception — Refund API Failure:**
If the gateway API call at step 5 fails: Refund Record status is set to "Failed"; the transaction rolls back; Admin sees error message with generic description; detailed error is logged internally only.

**Exception — Webhook Refund Confirmation Not Received:**
Admin can check Webhook Log for the refund event. If not received within 24 hours, Finance Admin contacts the gateway directly. The Refund Record remains in "Processing" status until webhook arrives.

---

### Workflow 4: Webhook Processing (Asynchronous)
**Trigger:** Gateway server sends HTTP POST to school's webhook endpoint
**End States:** Webhook processed (processed=true), Webhook failed exhaustively (processed=false, error_message set)

**Steps:**
1. VerifyWebhookSignature middleware reads raw request body and X-Razorpay-Signature header
2. Middleware computes HMAC-SHA256 of raw body using gateway's webhook_secret
3. If signature matches: decoded payload stored on request attributes; processing continues
4. WebhookController stores the raw payload to Webhook Log with idempotency_key, processed=false
5. System dispatches ProcessWebhookJob to the queue
6. Controller immediately returns HTTP 200 to the gateway server
7. ProcessWebhookJob (running in queue worker) resolves the gateway driver and calls handleWebhook(payload)
8. For Razorpay payment.captured: looks up Payment Record by gateway_order_id; calls PaymentService.markSuccess()
9. For Razorpay payment.failed: looks up Payment Record; calls PaymentService.markFailed()
10. Webhook Log record updated: processed=true, processed_at=now()
11. PaymentSucceeded or PaymentFailed event dispatched

**Exception — Processing Job Failure:**
Job retries up to 3 times with 30-second exponential backoff. On final failure, Webhook Log record updated with error_message; Finance Admin notified to investigate.

---

## 7. Reporting & Analytics

### RPT-PAY-001: Payment Transaction History Report
**Purpose:** Full audit trail of all payment attempts for a school, filterable for daily operations and month-end review
**Audience:** Finance Admin, Bursar
**Frequency:** On-demand; daily operational use
**Contents:** Payment Reference, Payable Entity (description), Gateway, Amount, Currency, Status, Initiated At, Paid At, Gateway Payment ID
**Filters:** Date range, Gateway, Status, Payable Entity Type
**Export:** CSV, PDF
**Rules:** Shows all statuses; Finance Admin sees all tenants' records; Parent/Student see only own records; data is per-school (tenant-isolated)

### RPT-PAY-002: Gateway Settlement Summary
**Purpose:** Aggregate daily/monthly collection totals per gateway for accounting reconciliation
**Audience:** Finance Admin, Principal
**Frequency:** Daily / Monthly close
**Contents:** Date, Gateway, Count of successful transactions, Total amount collected, Count of refunds, Total refunded, Net collected
**Filters:** Date range, Gateway
**Export:** Excel, PDF
**Rules:** Only "Success" status payments count toward collection totals; refunds reduce net collected

### RPT-PAY-003: Refund Summary Report
**Purpose:** Track all refunds issued for a period, supporting student ledger updates
**Audience:** Finance Admin, Bursar
**Frequency:** On-demand; monthly
**Contents:** Refund Reference, Original Payment Reference, Student Name (from payable), Amount Refunded, Reason, Status, Refund Date, Initiated By
**Filters:** Date range, Status, Gateway
**Export:** CSV, PDF
**Rules:** Shows partial refunds separately from full refunds; groups by payment where multiple partial refunds exist

### RPT-PAY-004: Daily Payment Collection Report
**Purpose:** End-of-day cash and digital collection summary for teller reconciliation
**Audience:** Bursar, Finance Admin
**Frequency:** Daily (end of business day)
**Contents:** Collection Method (Cash/Cheque/Online), Count, Total Amount, Individual records with receipt numbers
**Filters:** Date
**Export:** PDF (print-ready), CSV
**Rules:** Offline and online payments reported in separate sections; totals are INR; only "Success" status

### RPT-PAY-005: Webhook Processing Status Report
**Purpose:** Operational health report for gateway webhook delivery — identifies stuck or failed webhooks needing manual intervention
**Audience:** Finance Admin (technical support context)
**Frequency:** On-demand (troubleshooting)
**Contents:** Webhook ID, Gateway, Event Type, Signature Valid, Processed, Processed At, Error Message, Received At
**Filters:** Gateway, Processed (Yes/No/All), Date range
**Export:** CSV
**Rules:** Unprocessed webhooks highlighted; shows error messages for failed jobs; Re-process action available from this view

---

## 8. Future Enhancement Log

| ID | Enhancement | Rationale | Effort Estimate |
|----|-------------|-----------|-----------------|
| ENH-PAY-001 | PDF Receipt Generation — auto-generate DomPDF receipt on PaymentSucceeded event; store to sys_media; download route for parents and staff | Required for parent self-service digital record; reduces accountant workload | 2–3 days |
| ENH-PAY-002 | Gateway Test Connection — "Test Connection" button on gateway edit/show page that creates a ₹1 test order and returns AJAX success/fail | Reduces errors when Finance Admin first configures a gateway | 1 day |
| ENH-PAY-003 | Razorpay Payment Links — generate shareable fee payment links via Razorpay Payment Links API; send via WhatsApp/Email for fee reminders | Useful for defaulters; does not require parent to log in | 2 days |
| ENH-PAY-004 | Webhook IP Allowlisting — validate incoming webhook IP against Razorpay's published IP ranges before HMAC check | Defense-in-depth; reduces brute-force webhook attempts | 0.5 day |
| ENH-PAY-005 | Gateway Record Caching — cache active gateway records (5-minute TTL) in GatewayManager.resolve() to avoid DB query on every payment | Performance: high-traffic schools may initiate hundreds of payments simultaneously | 0.5 day |
| ENH-PAY-006 | PaymentPolicy Class — create dedicated Policy class with viewAny, initiate, refund, viewWebhookLogs permissions to replace inline Gate::authorize calls | Standardizes authorization; enables per-role fine-grained control via DB role assignments | 1 day |
| ENH-PAY-007 | EnsureTenantHasModule Enforcement — add module licensing check to RSP middleware stack so tenants without the Payment module cannot access any payment routes | Billing integrity; prevents unauthorized module use | 0.5 day |
| ENH-PAY-008 | Dead PaymentHistory Model Cleanup — either drop the PaymentHistory.php model (its table is deleted) and update all references, or restore the ptm_payment_histories table if it serves a distinct purpose | P0 correctness issue; model points to non-existent table | 0.5 day |

---

## 9. Non-Functional Requirements

### 9.1 Performance
- The webhook endpoint must return HTTP 200 within 500ms (before the processing job completes). Razorpay times out after 30 seconds; synchronous processing in the controller is forbidden.
- Gateway record lookup should complete within 50ms — implement caching (ENH-PAY-005) for high-traffic schools.
- Payment transaction list queries must use indexes on (payable_type, payable_id), status, and paid_at.
- The audit log table (ptm_payment_audit_logs) uses a bigInt primary key for high-volume append workload without fragmentation.

### 9.2 Security
- Gateway API credentials (key_id, key_secret, webhook_secret) must be stored with Laravel encryption at rest. The database column must be TEXT (not JSON) to hold the encrypted blob.
- Credentials must never appear in API responses, log files, error messages, or activity log data payloads.
- Webhook signature must be verified using `hash_equals()` (timing-safe comparison) against the HMAC-SHA256 of the raw request body.
- Payment card data must never pass through the school's server. Razorpay's hosted checkout is the boundary.
- The webhook endpoint must be outside all session-based authentication middleware. HMAC signature is the sole security layer.
- The webhook endpoint error responses must contain only generic messages — no exception details, stack traces, or internal system information.
- Payment Records and Audit Logs must not be hard-deleteable by any application user. Soft-delete only for Payment Records; no delete for Audit Logs.
- Data is isolated per school tenant — no cross-tenant payment queries are permitted.

### 9.3 Usability
- The Razorpay checkout interface is rendered on Razorpay's hosted page. The school's UI responsibility is to provide accurate prefill (parent name, email, phone) for a smooth checkout experience.
- Gateway configuration errors (wrong credentials) should surface a clear, actionable message to Finance Admin on the gateway test page rather than a generic HTTP 500.
- The Refund form must display the remaining refundable amount so Finance Admin does not have to compute it manually.
- Payment history filtering must be fast and not require page reload (progressive filtering preferred).

---

## 10. Gap Analysis Readiness Index

### 10.1 Coverage Flags

| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|---------|----------|------|:-----------------:|:-------------:|:----------:|:-------------------:|:----------------:|
| REQ-PAY-001 | Gateway Configuration Management | Core P0 | [CONFIGURATION] | ptm_payment_gateways | Yes (done) | No | No | Yes |
| REQ-PAY-002 | Online Payment Initiation | Core P0 | [WORKFLOW][DATA_ENTRY][INTEGRATION] | ptm_payments | Partial | Yes | No | Yes |
| REQ-PAY-003 | Razorpay Checkout Flow | Core P0 | [INTEGRATION][WORKFLOW] | ptm_payments | Yes (done) | No | No | Yes |
| REQ-PAY-004 | Gateway Callback Verification | Core P0 | [WORKFLOW][INTEGRATION] | ptm_payments | No (API only) | Yes | No | Yes |
| REQ-PAY-005 | Webhook Processing | Core P0 | [INTEGRATION][WORKFLOW][SCHEDULED] | ptm_payment_webhooks | Partial | No | No | Yes |
| REQ-PAY-006 | Offline Payment Recording | Standard P1 | [DATA_ENTRY][WORKFLOW] | ptm_offline_payment_records | Yes (needed) | No | Yes | Yes |
| REQ-PAY-007 | Refund Management | Standard P1 | [WORKFLOW][DATA_ENTRY] | ptm_payment_refunds | Yes (needed) | Yes | Yes | Yes |
| REQ-PAY-008 | Payment History & Dashboard | Standard P1 | [REPORT][DASHBOARD] | ptm_payments | Partial | No | No | Yes |
| REQ-PAY-009 | Immutable Audit Trail | Core P0 | [WORKFLOW] | ptm_payment_audit_logs | Partial | No | No | Yes |
| REQ-PAY-010 | Gateway Reconciliation | Standard P1 | [REPORT][DATA_ENTRY] | ptm_payment_reconciliations | Yes (needed) | No | No | Yes |
| REQ-PAY-011 | Payment Receipt Generation | Enhanced P2 | [REPORT] | sys_media | Partial | No | Yes | Yes |
| REQ-PAY-012 | Webhook Log Administration | Enhanced P2 | [REPORT][CONFIGURATION] | ptm_payment_webhooks | Yes (needed) | No | No | Yes |
| REQ-PAY-013 | Multi-Gateway UI Exposure | Standard P1 | [CONFIGURATION][INTEGRATION] | ptm_payment_gateways | Partial | No | No | Yes |

### 10.2 Business Rule Coverage

| BR ID | Rule Summary | FRD Section | Code Implemented? |
|-------|-------------|------------|:-----------------:|
| BR-PAY-001 | Gateway code uniqueness | §4 | Yes |
| BR-PAY-002 | Only active gateways offered | §4 | Yes |
| BR-PAY-003 | Credential encryption | §4 | Yes |
| BR-PAY-004 | Paise conversion for Razorpay | §4 | Yes |
| BR-PAY-005 | Payment status FSM | §4 | Yes |
| BR-PAY-006 | Refund status FSM | §4 | Yes |
| BR-PAY-007 | Webhook HMAC verification | §4 | Yes |
| BR-PAY-008 | Webhook idempotency | §4 | Yes (partial — event-level; not webhook-storage level) |
| BR-PAY-009 | Refund amount limit | §4 | Partial (checks vs payment.amount; gap: does not sum prior refunds) |
| BR-PAY-010 | Gateway driver contract | §4 | Yes |
| BR-PAY-011 | Razorpay auto-capture | §4 | Yes |
| BR-PAY-012 | No card data | §4 | Yes (architectural) |
| BR-PAY-013 | Immutable audit log | §4 | Yes |
| BR-PAY-014 | Immediate 200 response | §4 | Yes |
| BR-PAY-015 | Offline refund manual | §4 | Yes (OfflineGateway) |
| BR-PAY-016 | One reconciliation per gateway/date | §4 | Yes (unique constraint) |

### 10.3 Report Coverage

| RPT ID | Report | Code Status |
|--------|--------|------------|
| RPT-PAY-001 | Payment Transaction History | Partial (basic list view; no export; no full detail page) |
| RPT-PAY-002 | Gateway Settlement Summary | Not started |
| RPT-PAY-003 | Refund Summary Report | Not started |
| RPT-PAY-004 | Daily Payment Collection Report | Not started |
| RPT-PAY-005 | Webhook Processing Status | Not started (model exists; no UI) |

### 10.4 Totals

| Item | Count |
|------|-------|
| Functional Requirements (REQ-PAY-) | 13 |
| — Core P0 | 6 |
| — Standard P1 | 5 |
| — Enhanced P2 | 2 |
| Business Rules (BR-PAY-) | 16 |
| Reports (RPT-PAY-) | 5 |
| Future Enhancements (ENH-PAY-) | 8 |
| Workflows | 4 |
| FSMs (in Section 4) | 2 |
| Actors | 7 |

---

# Section 2: RTM

## Requirements Traceability Matrix

| REQ-ID | Feature | BR refs | Key Screens | Workflow | Reports | Test refs | Code Status | Gap |
|--------|---------|---------|-------------|---------|---------|-----------|------------|-----|
| REQ-PAY-001 | Gateway Configuration | BR-001, BR-003, BR-010 | Gateway List, Create, Edit, Show, Trash | — | — | PaymentGatewayControllerTest, PaymentGatewayModelTest, PaymentGatewayRequestTest | DONE | No Policy class; driver dropdown hardcoded to Razorpay only |
| REQ-PAY-002 | Online Payment Initiation | BR-002, BR-004, BR-005, BR-011, BR-012 | — (API) | Workflow 1 | — | PaymentControllerTest | PARTIAL | apiResource route mismatch; no PaymentPolicy; no idempotency check |
| REQ-PAY-003 | Razorpay Checkout | BR-011, BR-012 | razorpay/process-payment | Workflow 1 | — | PaymentControllerTest | DONE | — |
| REQ-PAY-004 | Callback Verification | BR-005, BR-007 | — (API) | Workflow 1 | — | PaymentControllerTest | PARTIAL | Route mapping gap |
| REQ-PAY-005 | Webhook Processing | BR-007, BR-008, BR-014 | — (API endpoint) | Workflow 4 | RPT-PAY-005 | PaymentEventsTest | DONE | No webhook log UI |
| REQ-PAY-006 | Offline Payment Recording | BR-005, BR-013, BR-015 | Offline recording form (MISSING) | Workflow 2 | RPT-PAY-004 | OfflineGatewayTest | PARTIAL | No write path; no controller; no routes; no views |
| REQ-PAY-007 | Refund Management | BR-005, BR-006, BR-009 | Refund list + form (MISSING) | Workflow 3 | RPT-PAY-003 | — | PARTIAL | RefundController has no routes; no views |
| REQ-PAY-008 | Payment History & Dashboard | BR-013 | index.blade.php (partial) | — | RPT-PAY-001, RPT-PAY-002 | PaymentControllerTest | PARTIAL | No detail page; no export; no history-dedicated page |
| REQ-PAY-009 | Audit Trail | BR-013 | (within payment detail — MISSING) | All workflows | — | AuditServiceTest | DONE | Audit log UI not built |
| REQ-PAY-010 | Reconciliation | BR-016 | Reconciliation form (MISSING) | — | RPT-PAY-002 | — | NOT STARTED | No controller, no routes, no views |
| REQ-PAY-011 | Receipt Generation | — | Download button (MISSING) | Workflow 1 (post-success) | — | — | NOT STARTED | No listener; no DomPDF integration |
| REQ-PAY-012 | Webhook Log Admin | BR-007, BR-014 | Webhook Logs UI (MISSING) | Workflow 4 | RPT-PAY-005 | — | NOT STARTED | No UI; only model + job |
| REQ-PAY-013 | Multi-Gateway UI | BR-010 | Gateway Create/Edit (partial) | — | — | GatewayManagerTest | PARTIAL | Only Razorpay in dropdown |

---

# Section 3: BR + Conditions + Validation

## 3.1 Business Rules Register (standalone)

(Full register in FRD Section 4 above — BR-PAY-001 through BR-PAY-016)

## 3.2 Requirement Conditions Catalog

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-PAY-001 | Gateway Code | Code must be unique within the school | Validation | Gateway create / update | Reject with "This gateway code already exists" |
| BR-PAY-002 | Gateway Status | Only Active gateways may be used for new payments | Workflow | Payment initiation | System throws "Gateway not found or inactive"; initiation blocked |
| BR-PAY-003 | Gateway Credentials | Credentials must be stored encrypted — never plaintext in DB | Permission | Any save to ptm_payment_gateways | Model accessor encrypts before DB write; model decrypts on read |
| BR-PAY-004 | Razorpay Amount | Amount must be multiplied by 100 (convert INR to paise) once, in the gateway driver | Calculation | Razorpay order creation | Driver applies conversion; double-conversion is a defect |
| BR-PAY-005a | Payment Status | Only valid FSM transitions are allowed: Initiated→Pending, Pending→Success/Failed/Cancelled, Success→Refunded | Workflow | Every PaymentService status change | Invalid transition throws RuntimeException; status remains unchanged |
| BR-PAY-005b | Payment Delete | Payment Records may not be hard-deleted | Permission | Any delete attempt | SoftDeletes applies; no forceDelete route exists |
| BR-PAY-006 | Refund Status | Refund status follows Pending→Processing→Success or Failed | Workflow | RefundService lifecycle | Invalid transition rejected |
| BR-PAY-007a | Webhook Signature | HMAC-SHA256 must match before payload is accepted | Permission | Webhook receipt | HTTP 401 returned; no payload stored; no status changed |
| BR-PAY-007b | Webhook Secret | Webhook secret must be configured for the gateway | Permission | Webhook middleware | HTTP 400 "Invalid signature" if secret is empty |
| BR-PAY-008 | Duplicate Webhook | If payment is already "Success", re-delivered payment.captured must be ignored | Concurrency | ProcessWebhookJob processing | Job returns without changing status; PaymentSucceeded NOT re-dispatched |
| BR-PAY-009 | Refund Amount | Refund amount must not exceed original payment amount (current check) and should not exceed remaining refundable (net of prior refunds — gap) | Validation | Refund initiation | InvalidArgumentException; refund creation blocked |
| BR-PAY-013 | Audit Log | Audit log entries must never be updated or deleted | Permission | Any attempt to modify audit log | No update/delete routes exist; model has no SoftDeletes |
| BR-PAY-016 | Reconciliation Uniqueness | One reconciliation record per gateway per date | Validation | Reconciliation create | DB unique constraint violation; user sees validation error |

## 3.3 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|-------------|--------------|-----------------|----------|-------------|-----------------|-------------------|
| Gateway Code | "razorpay" | "razorpay" (duplicate) | 50 chars | Required | Two admins add same code simultaneously | Second save fails with unique constraint violation |
| Payment Amount | ₹500.00 | ₹0, -₹100 | ₹0.01 minimum; ₹500,000 maximum | Required | — | Amounts outside range rejected with validation error |
| Refund Amount | ₹200 on ₹500 payment | ₹600 on ₹500 payment | Equal to original amount (valid full refund) | Required | Two staff initiate same refund simultaneously | PHP check should block; ideally wrapped in SELECT FOR UPDATE |
| Webhook Signature | Correct HMAC-SHA256 | Wrong signature, empty header | Exact match required | Missing header → reject | Replay of old valid signature | Signature matches but idempotency_key uniqueness catches duplicate |
| Cheque Date | 2026-06-15 | 2026-08-01 (future date) | Today | Required for Cheque method | — | Future cheque dates should be warned (configurable, not hard-blocked) |
| Gateway Status toggle | Active→Inactive | — | — | Not nullable | Staff disables gateway while payment in-flight | In-flight payment uses stored gateway_id; gateway status change does not affect existing payments |
| Clearance Status | Pending → Cleared | Cleared → Pending (backward) | — | Nullable until cheque resolved | — | Backward status transitions blocked |
| Payable Interface | FeeInvoice implements Payable | Any model not implementing Payable | — | Null payable_type | — | FormRequest rejects with "payable type does not exist or is not Payable" |

---

# Section 4: Process Flows + FSM

## 4.1 Payment Lifecycle FSM

**Entity:** Payment Record (ptm_payments.status)

| From State | Event / Action | Guard (Condition) | To State | Side Effects |
|-----------|---------------|------------------|----------|-------------|
| — (new) | Payment initiation submitted | Active gateway exists, payable is valid | Initiated | Payment Record created, audit log written |
| Initiated | Gateway order created | Gateway API returns success | Pending | gateway_order_id stored; PaymentInitiated event |
| Initiated | Gateway order creation fails | Gateway API throws exception | — | DB transaction rolled back; no record persists |
| Pending | payment.captured webhook received + valid | HMAC verified; status is Pending or Initiated | Success | paid_at set; PaymentSucceeded event; fee marked paid |
| Pending | payment.failed webhook received | HMAC verified; status is Pending | Failed | failure_reason stored; PaymentFailed event; parent notified |
| Pending | Parent abandons checkout | User closes modal / cancels | Cancelled | PaymentCancelled event |
| Success | Full refund confirmed | Total refunded = original amount | Refunded | Payment Record status = Refunded |
| Success | Duplicate payment.captured | Payment already in Success state | Success | No change; webhook acknowledged and ignored (BR-PAY-008) |

**Terminal States:** Failed, Cancelled, Refunded
**Illegal Transitions (must be blocked):** Success → Failed, Success → Cancelled, Failed → Success, Refunded → Success

**Status master:** Stored as ENUM on ptm_payments.status — fixed values, not config-driven.

---

## 4.2 Refund Lifecycle FSM

**Entity:** Payment Refund Record (ptm_payment_refunds.status)

| From State | Event / Action | Guard (Condition) | To State | Side Effects |
|-----------|---------------|------------------|----------|-------------|
| — (new) | Refund initiated by staff | Payment is "Success"; amount ≤ refundable | Pending | Refund Record created; RefundInitiated event |
| Pending | Gateway refund API called | API returns refund_id | Processing | gateway_refund_id stored |
| Processing | refund.processed webhook received | HMAC verified | Success | refunded_at set; RefundSucceeded event; if full refund, Payment→Refunded |
| Pending / Processing | Gateway API fails | API throws exception | Failed | RefundFailed event; error logged; no automatic retry |
| — | Offline refund requested | Payment method=Offline | Success | Synthetic refund_id created; immediate success (manual process outside system) |

**Terminal States:** Success, Failed
**Illegal Transitions:** Success → Failed, Failed → Success (retry must be a new Refund Record)

---

# Section 5: Data Dictionary + Dependency Map

## 5.1 Data Dictionary — Business View

(Key entities summarised below; full field lists in FRD Section 5)

**ptm_payment_gateways** — Gateway Configuration
Privacy: Confidential (contains encrypted API credentials)

| Business Field | Type | PII? | Notes |
|----------------|------|------|-------|
| Gateway Name | Text | No | Display-only |
| Gateway Code | Text (unique) | No | Machine identifier |
| Gateway Type | Online / Offline | No | |
| Driver | Selection | No | FQCN of driver class |
| API Credentials | Encrypted JSON | No (keys, not personal data) | Never displayed after save |
| Operational Mode | Live / Test | No | Test mode = sandbox |
| Supported Modules | Array (nullable) | No | Null = all modules |
| Priority | Integer | No | Lower = higher priority |

**ptm_payments** — Payment Record
Privacy: Confidential (linked to student identity via payable; financial data)

| Business Field | Type | PII? | Notes |
|----------------|------|------|-------|
| Payment Reference (ULID) | Text | No | Public external ID |
| Payable Type | Text | No | Class name (not displayed) |
| Payable ID | Integer | Yes (indirect) | Links to student's fee invoice / fine |
| Gateway | Reference | No | |
| Amount | Decimal | No | INR |
| Status | Enum | No | FSM states |
| Gateway Order ID | Text | No | |
| Gateway Payment ID | Text | No | Transaction ID |
| Paid At | Datetime | No | |
| Failure Reason | Text | No | |
| Initiated By | Reference | Yes | sys_users.id |

**ptm_payment_audit_logs** — Immutable Audit
Privacy: Internal

| Business Field | Type | PII? | Notes |
|----------------|------|------|-------|
| Payment | Reference | No | |
| Event | Text | No | Event name |
| Previous Status | Text | No | |
| New Status | Text | No | |
| Actor Type | Enum | No | user/system/gateway/webhook |
| Actor ID | Integer | Yes (indirect) | sys_users.id when actor_type=user |
| Context Payload | JSON | Conditional | May contain payment IDs (not card data) |
| IP Address | Text | Yes | School network or user IP |

---

## 5.2 Cross-Module Dependency Map

**Inbound (modules that feed into Payment):**

| Source Module | Data / Entity | Why | Mechanism |
|---------------|--------------|-----|-----------|
| StudentFee | FeeInvoice | Primary payable entity — parent pays fee invoices via Payment | Implements Payable interface; passes payable_type + payable_id |
| Library | LibFine | Library fine payable via payment system | Implements Payable interface (planned) |
| Cafeteria | MealCard | Meal card top-up via payment system | Implements Payable interface (planned) |
| Hostel | HostelFee | Hostel charge payable via payment | Implements Payable interface (future) |
| SchoolSetup / StudentProfile | Student / Guardian | Name, email, phone for checkout prefill | Resolved via payable.getPayableCustomer() |
| sys_users | User | created_by / initiated_by FKs on all payment tables | Direct FK to sys_users.id |

**Outbound (Payment fires into other modules):**

| Target Module | Mechanism | What | Implementation Status |
|---------------|-----------|------|----------------------|
| StudentFee | PaymentSucceeded event → FeeInvoicePaymentListener | Mark fee invoice as paid; update student ledger | NOT BUILT (critical gap) |
| Accounting | PaymentSucceeded event → AccountingVoucherListener | Create receipt voucher in acc_vouchers | NOT BUILT |
| Notification | PaymentSucceeded event → PaymentNotificationListener | Send SMS/email receipt to parent | NOT BUILT |
| Notification | PaymentFailed event → PaymentFailedNotificationListener | Notify parent of failed payment | NOT BUILT |
| sys_activity_logs | activityLog() helper | Gateway CRUD action logging | BUILT (in PaymentGatewayController) |
| sys_media | Receipt PDF storage | Store generated PDF receipt | NOT BUILT |

**External Dependencies:**

| External Service | Purpose | Notes |
|-----------------|---------|-------|
| Razorpay | Primary online payment gateway | razorpay/razorpay PHP SDK; hosted Checkout.js |
| BillDesk | Alternative gateway (enterprise schools) | HMAC-SHA256 pipe-separated form-post |
| CCAvenue | Alternative gateway | AES-128 encrypted form-post |
| Paytm | Alternative gateway | REST token API |
| PhonePe | Alternative gateway | SHA256+salt redirect flow |
| DomPDF (barryvdh/laravel-dompdf) | PDF receipt generation | Already in platform (HPC module) |
| Laravel Queue (Redis/Database) | Async webhook processing | ProcessWebhookJob |

---

# Section 6: NFR + Risk

## 6.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|--------|---------|-------------|---------------------|
| NFR-PAY-001 | Performance | Webhook endpoint must return HTTP 200 before the processing job completes | < 500ms response time; processing job runs async |
| NFR-PAY-002 | Performance | Gateway record lookup must use caching to avoid DB query on every payment | After ENH-PAY-005: max 1 DB read per gateway per 5 minutes |
| NFR-PAY-003 | Performance | Payment history list query must complete within 300ms for up to 10,000 records | Index on (status, paid_at) and (payable_type, payable_id) required |
| NFR-PAY-004 | Security | Gateway credentials never in plaintext in DB, logs, or API responses | Zero credential exposure events; pen test must find 0 plaintext credentials |
| NFR-PAY-005 | Security | Webhook HMAC verification uses timing-safe comparison (hash_equals) | All webhook verification uses hash_equals(); no string comparison |
| NFR-PAY-006 | Security | No card data transits through school's server | Architecture: Razorpay Checkout.js only; school server handles order IDs only |
| NFR-PAY-007 | Security | Webhook endpoint accessible without auth session; security is HMAC only | No 401 from auth middleware; gateway servers can POST without session |
| NFR-PAY-008 | Compliance | PCI-DSS scope is out of school's hands — Razorpay's hosted checkout maintains card data scope | School infrastructure is out of PCI-DSS cardholder data environment |
| NFR-PAY-009 | Scalability | Audit log table (ptm_payment_audit_logs) supports high append volume | bigInt PK; no SoftDeletes overhead; insert-only pattern |
| NFR-PAY-010 | Reliability | Webhook processing retries on failure with exponential backoff | Max 3 retries, 30-second backoff; final failure logs error_message |
| NFR-PAY-011 | Usability | Finance Admin can configure and test a gateway without developer assistance | Gateway create form with inline validation; driver dropdown with labels |
| NFR-PAY-012 | Availability | Payment initiation failure (gateway outage) must not corrupt existing data | DB transaction rollback on gateway API failure; no orphan records |
| NFR-PAY-013 | Compliance | Financial records (Payment Records, Audit Logs) must not be deleteable by application users | No hard-delete routes; only SoftDeletes on Payment Records; Audit Logs have no delete path |
| NFR-PAY-014 | Isolation | All payment data is isolated per school tenant — no cross-tenant queries | Database-per-tenant architecture; no tenant_id column needed |

## 6.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---------|------|---------|:---------:|:------:|-----------|-------|--------------|
| RISK-PAY-001 | EventServiceProvider.$listen is empty — PaymentSucceeded fires into void; fee invoices never marked paid; parents double-charged | Data Integrity | H | H | Implement event listeners before any school goes live with online payments | Developer | Test: confirm FeeInvoice.status changes after PaymentSucceeded |
| RISK-PAY-002 | Dead PaymentHistory model causes "Table not found" errors for any code path that references it | Production Defect | H | H | Remove model or restore table immediately | Developer | Any call to PaymentHistory::all() or PaymentHistory::find() |
| RISK-PAY-003 | RefundController has no routes — refunds cannot be initiated; money cannot be returned to parents | Feature Gap | H | H | Add refund routes to web.php or api.php | Developer | Refund requests from Finance Admin fail with 404 |
| RISK-PAY-004 | No PaymentPolicy — any authenticated user can call payment initiation for any payable entity, potentially for other students' invoices | Security | M | H | Create PaymentPolicy.php with ownership check | Developer | Penetration test or security audit |
| RISK-PAY-005 | BR-PAY-009 gap: refund check uses payment.amount not net of prior refunds — possible over-refund | Financial | M | H | Fix RefundService.initiate() to sum prior successful refunds | Developer | Manual test: initiate two partial refunds that together exceed original |
| RISK-PAY-006 | No EnsureTenantHasModule — all payment routes accessible to tenants without Payment module in their plan | Billing | M | M | Add to RSP middleware stack | Developer | School on basic plan accesses /payment/ routes |
| RISK-PAY-007 | Only Razorpay in gateway dropdown UI — BillDesk/CCAvenue/Paytm/PhonePe drivers are built but invisible | Feature Gap | M | M | Move driver list to config/payment.php | Developer | Finance Admin reports cannot find gateway option |
| RISK-PAY-008 | Gateway credentials migration security — migration 100101 re-encrypts plain-JSON credentials; if migration runs in production with existing plain credentials, encryption happens correctly; if migration runs twice, second run may double-encrypt | Data Integrity | L | H | Migration checks json_last_error before encrypting; idempotency by design | Developer | Verify migrate:status after deployment |
| RISK-PAY-009 | Offline payment write path unimplemented — OfflineGateway creates a synthetic reference but no OfflinePaymentRecord is ever created | Feature Gap | H | M | Build OfflinePaymentRecord creation in payment initiation flow for offline gateway type | Developer | Offline payments show no method/reference record |

---

# Section 7: Prioritization + Effort

## 7.1 MoSCoW Prioritization

**Must (P0 — Core):**
- REQ-PAY-001 Gateway Configuration (DONE)
- REQ-PAY-002 Online Payment Initiation (PARTIAL — route fix needed)
- REQ-PAY-003 Razorpay Checkout (DONE)
- REQ-PAY-004 Callback Verification (PARTIAL — route fix needed)
- REQ-PAY-005 Webhook Processing (DONE — no UI)
- REQ-PAY-009 Audit Trail (DONE — no UI)

**Should (P1 — Standard):**
- REQ-PAY-006 Offline Payment Recording (MODEL done; routes/views MISSING)
- REQ-PAY-007 Refund Management (SERVICE done; routes/views MISSING)
- REQ-PAY-008 Payment History & Dashboard (PARTIAL)
- REQ-PAY-010 Gateway Reconciliation (MODEL done; UI MISSING)
- REQ-PAY-013 Multi-Gateway UI Exposure (PARTIAL — config only change)

**Could (P2 — Enhanced):**
- REQ-PAY-011 PDF Receipt Generation (NOT STARTED)
- REQ-PAY-012 Webhook Log Administration (NOT STARTED)

**Won't (this release):**
- Razorpay Payment Links (ENH-PAY-003)
- Webhook IP allowlisting (ENH-PAY-004)
- Multi-currency support (not in scope for Indian K-12)

## 7.2 RICE Scores (relative ranking for backlog)

| Requirement | Reach | Impact | Confidence | Effort (days) | RICE |
|------------|:-----:|:------:|:----------:|:-------------:|------|
| REQ-PAY-007 Refund routes + views | 80 | 3 | 0.9 | 2 | 108 |
| REQ-PAY-006 Offline payment write path + views | 75 | 3 | 0.9 | 2 | 101 |
| REQ-PAY-002 Fix initiation route mapping | 100 | 3 | 1.0 | 0.5 | 600 |
| GAP Dead PaymentHistory model | 100 | 3 | 1.0 | 0.5 | 600 |
| REQ-PAY-013 Multi-gateway UI (config change) | 40 | 2 | 1.0 | 0.5 | 160 |
| ENH-PAY-006 PaymentPolicy | 100 | 2 | 0.9 | 1 | 180 |
| ENH-PAY-007 EnsureTenantHasModule | 100 | 2 | 1.0 | 0.5 | 400 |
| Event listeners (PaymentSucceeded) | 100 | 3 | 0.8 | 3 | 80 |
| REQ-PAY-008 Full history page + export | 80 | 2 | 0.9 | 3 | 48 |
| REQ-PAY-010 Reconciliation controller + views | 30 | 2 | 0.8 | 3 | 16 |
| REQ-PAY-011 PDF receipt | 60 | 2 | 0.7 | 3 | 28 |

## 7.3 Effort Estimation & Sprint Tasks

**Sprint 1 — P0 Defect Resolution (4 days)**

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|------|------|:----------:|-----------|--------|
| T-001 | Drop or replace PaymentHistory model (dead table — P0) | Backend | 2h | — | S1 |
| T-002 | Fix api.php apiResource mismatch — add named routes for initiate/callback/cancel/show | Backend | 2h | — | S1 |
| T-003 | Add refund routes (store, index) to api.php pointing to RefundController | Backend | 1h | — | S1 |
| T-004 | Create PaymentPolicy.php with viewAny, initiate, refund methods | Backend | 4h | T-001 | S1 |
| T-005 | Add EnsureTenantHasModule to RSP middleware stack (web.php group) | Backend | 1h | — | S1 |
| T-006 | Move gateway driver list to config/payment.php; update getAvailableDrivers() | Backend | 1h | — | S1 |
| T-007 | Fix BR-PAY-009: sum prior successful refunds in RefundService.initiate() | Backend | 2h | — | S1 |
| T-008 | Write tests: route resolution, PaymentPolicy, refund amount validation | Testing | 4h | T-001 to T-007 | S1 |

**Sprint 2 — Event Listeners & Offline Payment Write Path (5 days)**

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|------|------|:----------:|-----------|--------|
| T-009 | Create FeeInvoicePaymentListener for PaymentSucceeded event | Backend | 4h | S1 complete | S2 |
| T-010 | Create PaymentNotificationListener for PaymentSucceeded + PaymentFailed | Backend | 4h | NTF module | S2 |
| T-011 | Create AccountingVoucherListener for PaymentSucceeded | Backend | 4h | Accounting module interface | S2 |
| T-012 | Wire OfflinePaymentRecord creation in PaymentService for offline gateway type | Backend | 3h | — | S2 |
| T-013 | Register all listeners in EventServiceProvider.$listen | Backend | 1h | T-009 to T-011 | S2 |
| T-014 | Write integration tests: PaymentSucceeded triggers fee invoice marked paid | Testing | 4h | T-009 | S2 |

**Sprint 3 — UI Completions (6 days)**

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|------|------|:----------:|-----------|--------|
| T-015 | Build refund management view (list + initiate form) | Frontend | 6h | T-003 | S3 |
| T-016 | Build offline payment recording view | Frontend | 5h | T-012 | S3 |
| T-017 | Build full payment detail page (audit timeline, refunds, gateway data) | Frontend | 6h | T-002 | S3 |
| T-018 | Build dedicated payment history list page with filters and CSV export | Frontend | 5h | — | S3 |
| T-019 | Build webhook log admin UI with re-process action | Frontend | 4h | T-003 | S3 |
| T-020 | Implement gateway reconciliation controller + views | Backend + Frontend | 8h | — | S3 |

**Sprint 4 — Reporting & Receipt (4 days)**

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|------|------|:----------:|-----------|--------|
| T-021 | Implement PDF receipt generation (DomPDF, PaymentReceiptListener) | Backend | 6h | T-013 | S4 |
| T-022 | Build receipt download route + view | Frontend | 3h | T-021 | S4 |
| T-023 | Daily Collection Report (RPT-PAY-004) | Backend + Frontend | 5h | S3 complete | S4 |
| T-024 | Gateway Settlement Summary (RPT-PAY-002) | Backend + Frontend | 4h | T-020 | S4 |
| T-025 | Add gateway record caching (ENH-PAY-005) in GatewayManager | Backend | 2h | — | S4 |

**Total Estimated Effort:** ~88 hours (~11 developer-days across 4 sprints)
*Assumption: DDL migrations already exist (7 tables deployed); policy registration patterns follow established module conventions.*

---

# Section 8: User Stories + Acceptance Criteria + Reporting Spec

## 8.1 User Stories

### US-PAY-001 — Gateway Configuration (REQ-PAY-001)
**Priority:** P0 | **REQ ref:** REQ-PAY-001
As a Finance Administrator, I want to configure a Razorpay payment gateway with API credentials so that parents can pay school fees online using UPI, cards, and net banking.

**Scenario: Happy path — add gateway**
Given I am on the Add Gateway page
When I enter name "Razorpay Production", code "razorpay", select Razorpay driver, enter key_id and key_secret, set mode to "Live", and click Save
Then the gateway appears in the gateway list with Status "Active"
And the credentials are stored encrypted (not readable in the database)
And an activity log entry is created: "A new payment gateway was created"

**Scenario: Duplicate code rejected**
Given a gateway with code "razorpay" already exists
When I try to create another gateway with code "razorpay"
Then I see the validation error "This gateway code already exists"
And no duplicate record is created

**Scenario: Inactive gateway hidden**
Given a gateway with code "billdesk" has is_active = false
When I initiate a new payment and select payment method
Then "billdesk" does not appear in the list of available gateways

**Scenario: Permission denied**
Given I am a Bursar (not Finance Admin)
When I navigate to the Add Gateway page
Then I receive a "403 Forbidden" response

---

### US-PAY-002 — Fee Payment by Parent (REQ-PAY-002 + REQ-PAY-003)
**Priority:** P0 | **REQ ref:** REQ-PAY-002, REQ-PAY-003
As a Parent, I want to pay my child's fee invoice online through the school portal so that I do not need to visit the school in person.

**Scenario: Successful online payment**
Given I am viewing my child's unpaid fee invoice for ₹5,000
When I click "Pay Online", select Razorpay, and complete the Razorpay checkout modal
Then the fee invoice status changes to "Paid"
And I receive an SMS and email confirmation with the transaction ID
And the Payment Record shows status "Success" with the paid_at timestamp

**Scenario: Payment abandonment**
Given I open the Razorpay checkout modal
When I close the modal without completing payment
Then the fee invoice remains unpaid
And the Payment Record shows status "Cancelled"

**Scenario: Gateway API failure**
Given the Razorpay API is unavailable
When I click "Pay Online"
Then I see an error message: "Payment gateway is temporarily unavailable. Please try again."
And no Payment Record exists in the database

**Scenario: Own invoices only**
Given I am logged in as Parent A
When I view payment history
Then I see only payment records for my child's invoices, not other students' records

---

### US-PAY-003 — Webhook Confirmation (REQ-PAY-005)
**Priority:** P0 | **REQ ref:** REQ-PAY-005
As the System, I want to process Razorpay payment.captured webhooks reliably so that fee invoices are marked paid even if the parent closes the browser before the callback completes.

**Scenario: Successful webhook processing**
Given a payment is in "Pending" status
When Razorpay sends a payment.captured webhook with valid HMAC signature
Then the webhook payload is stored immediately
And the processing job is queued
And HTTP 200 is returned to Razorpay within 500ms
And the payment status is updated to "Success" by the queued job
And the PaymentSucceeded event fires

**Scenario: Invalid signature rejected**
Given Razorpay sends a webhook with a tampered body or wrong signature
When the webhook arrives at the endpoint
Then the system returns HTTP 401
And no webhook record is created
And the payment status is unchanged

**Scenario: Duplicate webhook idempotency**
Given payment P001 is already in "Success" status
When a second payment.captured webhook arrives for P001
Then the system returns HTTP 200
And the PaymentSucceeded event is NOT fired again
And no duplicate fee-marking occurs

---

### US-PAY-004 — Refund Initiation (REQ-PAY-007)
**Priority:** P1 | **REQ ref:** REQ-PAY-007
As a Finance Administrator, I want to initiate a partial or full refund for a confirmed payment so that I can return money to a parent when a fee was incorrectly charged.

**Scenario: Full refund**
Given a payment of ₹5,000 is in "Success" status
When I enter refund amount ₹5,000 with reason "Fee revision by management" and click Refund
Then a Refund Record is created with status "Pending"
And Razorpay processes the refund
And when the refund.processed webhook is received, the Refund Record status becomes "Success"
And the Payment Record status changes to "Refunded"

**Scenario: Partial refund — no status change**
Given a payment of ₹5,000 with no prior refunds
When I initiate a partial refund of ₹2,000
Then the Refund Record is created
And the Payment Record status remains "Success" (not "Refunded")

**Scenario: Over-refund blocked**
Given a payment of ₹5,000 with a prior successful refund of ₹3,000
When I attempt a further refund of ₹2,500 (total would be ₹5,500)
Then the system blocks the action with error "Refund amount exceeds remaining balance of ₹2,000"

**Scenario: Non-success payment**
Given a payment in "Failed" status
When I navigate to that payment's detail page
Then the "Initiate Refund" button is not visible

---

### US-PAY-005 — Offline Payment Recording (REQ-PAY-006)
**Priority:** P1 | **REQ ref:** REQ-PAY-006
As a Bursar, I want to record a cheque payment received from a parent so that the fee invoice is marked paid and an official receipt is generated.

**Scenario: Cheque payment recorded**
Given I am on the offline payment recording form for a fee invoice of ₹10,000
When I select "Cheque", enter cheque number, bank name, and cheque date, and submit
Then a Payment Record with status "Success" is created
And an Offline Payment Record with method "Cheque" and clearance_status "Pending" is created
And the fee invoice is marked as paid
And a receipt number is generated

**Scenario: Cheque bounced**
Given a cheque payment has clearance_status "Pending"
When I update the clearance status to "Bounced" and enter the bounce date
Then the bounce date is recorded
And the linked fee invoice status reverts to unpaid

---

## 8.2 Reporting & KPI Specification

### Reporting Spec: RPT-PAY-001 — Payment Transaction History
**Audience:** Finance Admin, Bursar | **Frequency:** On-demand
**Delivery:** Web page (paginated) + CSV/PDF export
**KPIs surfaced:**
- Total amount collected (all time, this month, today) — SUM of ptm_payments.amount WHERE status='success'
- Pending count — COUNT WHERE status='pending' OR status='initiated'
- Failed count — COUNT WHERE status='failed'
**Calculation Notes:** Partial refunds do not reduce the "collected" total — refunds are tracked separately in RPT-PAY-003.

### Reporting Spec: RPT-PAY-002 — Gateway Settlement Summary
**Audience:** Finance Admin | **Frequency:** Daily / monthly close
**Delivery:** Web page + Excel/PDF export
**KPIs surfaced:**
- Net Collected per Gateway = SUM(successful payments) − SUM(successful refunds) grouped by gateway and date
- Settlement Gap = Expected (system) − Settled (gateway statement) — requires reconciliation data from ptm_payment_reconciliations
**Calculation Notes:** Expected amount uses ptm_payments; Settled amount comes from gateway statement entered in reconciliation.

---

# Section 9: Feature Specification

## Screen 1: Payment Management Dashboard
**Route:** GET /payment/
**Access:** Finance Admin, Bursar, Principal
**Table:** ptm_payments, ptm_payment_gateways
**Status:** Partial (basic view exists; summary cards and gateway status panel missing)

**Layout:** AdminLTE card layout, 4 summary cards across top, recent transactions table below, gateway status sidebar

| # | Field (Business Label) | Type | Source |
|---|----------------------|------|--------|
| 1 | Total Collected — Today | Summary card | SUM amount WHERE status='success' AND DATE(paid_at)=today |
| 2 | Total Collected — This Month | Summary card | SUM amount WHERE status='success' AND MONTH |
| 3 | Pending Payments | Summary card | COUNT WHERE status IN ('initiated','pending') |
| 4 | Failed Payments | Summary card | COUNT WHERE status='failed' AND DATE(created_at)=today |
| 5 | Recent Transactions (10 rows) | Table | Latest 10 ptm_payments |
| 6 | Gateway Status (sidebar) | Card per gateway | ptm_payment_gateways active list |

**Actions:** View All Transactions, Manage Gateways, View Refunds, View Webhook Logs
**Empty State:** "No payments recorded yet. Configure a gateway to begin accepting online payments."

---

## Screen 2: Payment Gateway List
**Route:** GET /payment/payment-gateway
**Access:** Finance Admin (full CRUD); Bursar (view only)
**Table:** ptm_payment_gateways
**Status:** Implemented

| # | Field | Display |
|---|-------|---------|
| 1 | Gateway Name | Text |
| 2 | Code | Badge |
| 3 | Driver | Text (class abbreviation) |
| 4 | Type | Online / Offline badge |
| 5 | Mode | Live / Test badge |
| 6 | Priority | Number |
| 7 | Status | Active / Inactive toggle |
| 8 | Actions | Edit, View, Deactivate/Delete |

**Filters:** Status (Active/Inactive), Type (Online/Offline)
**Actions:** Add Gateway, View Trash

---

## Screen 3: Add / Edit Payment Gateway
**Route:** GET /payment/payment-gateway/create | /payment/payment-gateway/{id}/edit
**Access:** Finance Admin only
**Table:** ptm_payment_gateways
**Status:** Implemented (fields: name, code, driver, credentials, extra_config, priority, is_active)

| # | Field | Type | Required | Validation |
|---|-------|------|----------|-----------|
| 1 | Gateway Name | Text | Yes | Max 100 chars |
| 2 | Gateway Code | Text | Yes | Unique; max 50 chars; lowercase alphanumeric + hyphens |
| 3 | Gateway Type | Dropdown | Yes | Online / Offline |
| 4 | Driver | Dropdown | Yes | From config/payment.php |
| 5 | API Key | Text (masked) | Yes | Free text |
| 6 | API Secret | Text (masked) | Yes | Free text |
| 7 | Webhook Secret | Text (masked) | No | Free text |
| 8 | Mode | Radio | Yes | Live / Test |
| 9 | Supported Modules | Multi-select | No | Leave blank for all modules |
| 10 | Priority | Number | Yes | 1–100; 1 = highest priority |
| 11 | Active | Toggle | Yes | Default: Off for new gateways |
| 12 | Test Mode | Toggle | Yes | Default: On for new gateways |

**Actions:** Save, Cancel, Test Connection (ENH-PAY-002)
**Note:** Credentials are write-only on Edit form — existing values are not pre-populated to prevent exposure.

---

## Screen 4: Payment History List
**Route:** GET /payment/history
**Access:** Finance Admin (all), Bursar (all), Parent/Student (own only)
**Table:** ptm_payments
**Status:** Partial (basic partial view exists; full dedicated page missing)

| # | Field | Type | Source |
|---|-------|------|--------|
| 1 | Payment Reference | ULID (truncated) | ptm_payments.ulid |
| 2 | Paid For | Text | payable entity description |
| 3 | Gateway | Text | ptm_payment_gateways.name |
| 4 | Amount | INR decimal | ptm_payments.amount |
| 5 | Status | Badge (colour-coded) | ptm_payments.status |
| 6 | Initiated At | Datetime | ptm_payments.created_at |
| 7 | Paid At | Datetime | ptm_payments.paid_at |
| 8 | Actions | Links | View Detail, Download Receipt (if Success) |

**Filters:** Date Range, Gateway, Status
**Sorting:** Paid At (desc default)
**Pagination:** 20 per page
**Export:** CSV button (applies current filters)

---

## Screen 5: Payment Detail Page
**Route:** GET /payment/{ulid}
**Access:** Finance Admin, Bursar (all); Parent (own)
**Status:** Not implemented

**Layout:** Two-column; left = payment details; right = timeline and related data

| Section | Contents |
|---------|---------|
| Payment Information | Amount, status badge, gateway, paid_at, gateway_payment_id |
| Payable Entity | Type label (Fee Invoice / Library Fine / etc.), description, link to source entity |
| Refunds | List of refunds (amount, status, refunded_at) + Initiate Refund button (if status=Success) |
| Audit Timeline | Chronological list of audit log entries (event, actor, status change, timestamp) |
| Webhook Events | Related webhook records (event_type, processed, received_at) |
| Actions | Download Receipt (if Success), Initiate Refund (if Success), Cancel (if Pending) |

---

## Screen 6: Refund Initiation Form
**Route:** POST /payment/{ulid}/refund (modal or inline form)
**Access:** Finance Admin, Bursar
**Status:** Not implemented (backend done; view missing)

| # | Field | Type | Required | Validation |
|---|-------|------|----------|-----------|
| 1 | Refund Amount | Decimal | Yes | 0.01 ≤ amount ≤ remaining refundable balance (displayed prominently) |
| 2 | Reason | Text area | Yes | Max 500 chars |
| 3 | Confirm | Submit | — | — |

**Display:** "Remaining refundable: ₹[amount]" shown above the amount field.
**Empty State (no eligible payments):** Button hidden when payment is not in "Success" status.

---

## Screen 7: Webhook Log Administration
**Route:** GET /payment/webhook-logs
**Access:** Finance Admin only
**Status:** Not implemented

| # | Column | Source |
|---|--------|--------|
| 1 | ID | ptm_payment_webhooks.id |
| 2 | Gateway | ptm_payment_webhooks.gateway |
| 3 | Event Type | ptm_payment_webhooks.event_type |
| 4 | Signature Valid | Badge |
| 5 | Processed | Badge (green = yes, red = no) |
| 6 | Received At | ptm_payment_webhooks.created_at |
| 7 | Error | ptm_payment_webhooks.error_message (truncated) |
| 8 | Actions | View Payload (modal), Re-process (if processed=false) |

**Filters:** Gateway, Processed (Yes/No/All), Date Range
**Empty State:** "No webhook events received yet."
